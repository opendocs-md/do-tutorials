---
author: Savic
date: 2019-05-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-cd-pipeline-with-spinnaker-on-digitalocean-kubernetes
---

# How To Set Up a CD Pipeline with Spinnaker on DigitalOcean Kubernetes

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Spinnaker](https://www.spinnaker.io/) is an open-source resource management and continuous delivery application for fast, safe, and repeatable deployments, using a powerful and customizable pipeline system. Spinnaker allows for automated application deployments to many platforms, including [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/). When deploying, you can configure Spinnaker to use built-in [deployment strategies](https://www.spinnaker.io/concepts/#deployment-strategies), such as Highlander and Red/black, with the option of creating your own deployment strategy. It can integrate with other DevOps tools, like Jenkins and TravisCI, and can be configured to monitor GitHub repositories and Docker registries.

Spinnaker is managed by [Halyard](https://www.spinnaker.io/reference/halyard/#halyard), a tool specifically built for configuring and deploying Spinnaker to various platforms. Spinnaker requires [external storage](https://www.spinnaker.io/setup/install/storage/) for persisting your application’s settings and pipelines. It supports different platforms for this task, like [DigitalOcean Spaces](https://www.digitalocean.com/products/spaces/).

In this tutorial, you’ll deploy Spinnaker to DigitalOcean Kubernetes using Halyard, with DigitalOcean Spaces as the underlying back-end storage. You’ll also configure Spinnaker to be available at your desired domain, secured using Let’s Encrypt TLS certificates. Then, you will create a sample application in Spinnaker, create a pipeline, and deploy a `Hello World` app to your Kubernetes cluster. After testing it, you’ll introduce authentication and authorization via GitHub Organizations. By the end, you will have a secured and working Spinnaker deployment in your Kubernetes cluster.

**Note:** This tutorial has been specifically tested with Spinnaker `1.13.5`.

## Prerequisites

- Halyard installed on your local machine, according to the [official instructions](https://www.spinnaker.io/setup/install/halyard/). Please note that using Halyard on Ubuntu versions higher than 16.04 is not supported. In such cases, you can use it [via Docker](https://www.spinnaker.io/setup/install/halyard/#install-halyard-on-docker).

- A DigitalOcean Kubernetes cluster with your connection configured as the `kubectl` default. The cluster must have at least 8GB RAM and 4 CPU cores available for Spinnaker (more will be required in the case of heavier use). Instructions on how to configure `kubectl` are shown under the **Connect to your Cluster** step shown when you create your cluster. To create a Kubernetes cluster on DigitalOcean, see the [Kubernetes Quickstart](https://www.digitalocean.com/docs/kubernetes/quickstart/).

- An Nginx Ingress Controller and cert-manager installed on the cluster. For a guide on how to do this, see [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes).

- A DigitalOcean Space with API keys (access and secret). To create a DigitalOcean Space and API keys, see [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key).

- A domain name with three DNS A records pointed to the DigitalOcean Load Balancer used by the Ingress. If you’re using DigitalOcean to manage your domain’s DNS records, consult [How to Create DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/) to create A records. In this tutorial, we’ll refer to the A records as `spinnaker.example.com`, `spinnaker-api.example.com`, and `hello-world.example.com`.

- A [GitHub](https://github.com/) account, added to a GitHub Organization with admin permissions and public visibility. The account must also be a member of a Team in the Organization. This is required to complete Step 5.

## Step 1 — Adding a Kubernetes Account with Halyard

In this section, you will add a Kubernetes account to Spinnaker via Halyard. An account, in Spinnaker’s terms, is a named credential it uses to access a cloud provider.

As part of the prerequisite, you created the `echo1` and `echo2` services and an `echo_ingress` ingress for testing purposes; you will not need these in this tutorial, so you can now delete them.

Start off by deleting the ingress by running the following command:

    kubectl delete -f echo_ingress.yaml

Then, delete the two test services:

    kubectl delete -f echo1.yaml && kubectl delete -f echo2.yaml

The `kubectl delete` command accepts the file to delete when passed the `-f` parameter.

Next, from your local machine, create a folder that will serve as your workspace:

    mkdir ~/spinnaker-k8s

Navigate to your workspace by running the following command:

    cd ~/spinnaker-k8s

Halyard does not yet know where it should deploy Spinnaker. Enable the Kubernetes provider with this command:

    hal config provider kubernetes enable

You’ll receive the following output:

    Output+ Get current deployment
      Success
    + Edit the kubernetes provider
      Success
    Problems in default.provider.kubernetes:
    - WARNING Provider kubernetes is enabled, but no accounts have been
      configured.
    
    + Successfully enabled kubernetes

Halyard logged all the steps it took to enable the Kubernetes provider, and warned that no accounts are defined yet.

Next, you’ll create a Kubernetes _service account_ for Spinnaker, along with _RBAC_. A service account is a type of account that is scoped to a single namespace. It is used by software, which may perform various tasks in the cluster. RBAC (Role Based Access Control) is a method of regulating access to resources in a Kubernetes cluster. It limits the scope of action of the account to ensure that no important configurations are inadvertently changed on your cluster.

Here, you will grant Spinnaker `cluster-admin` permissions to allow it to control the whole cluster. If you wish to create a more restrictive environment, consult the [official Kubernetes documentation on RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).

First, create the `spinnaker` namespace by running the following command:

    kubectl create ns spinnaker

The output will look like:

    Outputnamespace/spinnaker created

Run the following command to create a service account named `spinnaker-service-account`:

    kubectl create serviceaccount spinnaker-service-account -n spinnaker

You’ve used the `-n` flag to specify that `kubectl` create the service account in the `spinnaker` namespace. The output will be:

    Outputserviceaccount/spinnaker-service-account created

Then, bind it to the `cluster-admin` role:

    kubectl create clusterrolebinding spinnaker-service-account --clusterrole cluster-admin --serviceaccount=spinnaker:spinnaker-service-account

You will see the following output:

    Outputclusterrolebinding.rbac.authorization.k8s.io/spinnaker-service-account created

Halyard uses the local kubectl to access the cluster. You’ll need to configure it to use the newly created service account before deploying Spinnaker. Kubernetes accounts authenticate using usernames and tokens. When a service account is created, Kubernetes makes a new secret and populates it with the account token. To retrieve the token for the `spinnaker-service-account`, you’ll first need to get the name of the secret. You can fetch it into a console variable, named `TOKEN_SECRET`, by running:

    TOKEN_SECRET=$(kubectl get serviceaccount -n spinnaker spinnaker-service-account -o jsonpath='{.secrets[0].name}')

This gets information about the `spinnaker-service-account` from the namespace `spinnaker`, and fetches the name of the first secret it contains by passing in a JSON path.

Fetch the contents of the secret into a variable named `TOKEN` by running:

    TOKEN=$(kubectl get secret -n spinnaker $TOKEN_SECRET -o jsonpath='{.data.token}' | base64 --decode)

You now have the token available in the environment variable `TOKEN`. Next, you’ll need to set credentials for the service account in kubectl:

    kubectl config set-credentials spinnaker-token-user --token $TOKEN

You will see the following output:

    OutputUser "spinnaker-token-user" set.

Then, you’ll need to set the user of the current context to the newly created `spinnaker-token-user` by running the following command:

    kubectl config set-context --current --user spinnaker-token-user

By setting the current user to `spinnaker-token-user`, kubectl is now configured to use the `spinnaker-service-account`, but Halyard does not know anything about that. Add an account to its Kubernetes provider by executing:

    hal config provider kubernetes account add spinnaker-account --provider-version v2

The output will look like this:

    Output+ Get current deployment
      Success
    + Add the spinnaker-account account
      Success
    + Successfully added account spinnaker-account for provider
      kubernetes.

This commmand adds a Kubernetes account to Halyard, named `spinnaker-account`, and marks it as a service account.

Generally, Spinnaker can be deployed in two ways: distributed installation or local installation. _Distributed_ installation is what you’re completing in this tutorial—you’re deploying it to the cloud. _Local_ installation, on the other hand, means that Spinnaker will be downloaded and installed on the machine Halyard runs on. Because you’re deploying Spinnaker to Kubernetes, you’ll need to mark the deployment as `distributed`, like so:

    hal config deploy edit --type distributed --account-name spinnaker-account

Since your Spinnaker deployment will be building images, it is necessary to enable `artifacts` in Spinnaker. You can enable them by running the following command:

    hal config features edit --artifacts true

Here you’ve enabled `artifacts` to allow Spinnaker to store more metadata about the objects it creates.

You’ve added a Kubernetes account to Spinnaker, via Halyard. You enabled the Kubernetes provider, configured RBAC roles, and added the current kubectl config to Spinnaker, thus adding an account to the provider. Now you’ll set up your back-end storage.

## Step 2 — Configuring the Space as the Underlying Storage

In this section, you will configure the Space as the underlying storage for the Spinnaker deployment. Spinnaker will use the Space to store its configuration and pipeline-related data.

To configure S3 storage in Halyard, run the following command:

    hal config storage s3 edit --access-key-id your_space_access_key --secret-access-key --endpoint spaces_endpoint_with_region_prefix --bucket space_name --no-validate

Remember to replace `your_space_access_key` with your Space access key and `spaces_endpoint_with_region_prefix` with the endpoint of your Space. This is usually `region-id.digitaloceanspaces.com`, where `region-id` is the region of your Space. You can replace `space_name` with the name of your Space. The `--no-validate` flag tells Halyard not to validate the settings given right away, because DigitalOcean Spaces validation is not supported.

Once you’ve run this command, Halyard will ask you for your secret access key. Enter it to continue and you’ll then see the following output:

    Output+ Get current deployment
      Success
    + Get persistent store
      Success
    + Edit persistent store
      Success
    + Successfully edited persistent store "s3".

Now that you’ve configured `s3` storage, you’ll ensure that your deployment will use this as its storage by running the following command:

    hal config storage edit --type s3

The output will look like this:

    Output+ Get current deployment
      Success
    + Get persistent storage settings
      Success
    + Edit persistent storage settings
      Success
    + Successfully edited persistent storage.

You’ve set up your Space as the underlying storage that your instance of Spinnaker will use. Now you’ll deploy Spinnaker to your Kubernetes cluster and expose it at your domains using the Nginx Ingress Controller.

## Step 3 — Deploying Spinnaker to Your Cluster

In this section, you will deploy Spinnaker to your cluster using Halyard, and then expose its UI and API components at your domains using an Nginx Ingress. First, you’ll configure your domain URLs: one for Spinnaker’s user interface and one for the API component. Then you’ll pick your desired version of Spinnaker and deploy it using Halyard. Finally you’ll create an ingress and configure it as an Nginx controller.

First, you’ll need to edit Spinnaker’s UI and API URL config values in Halyard and set them to your desired domains. To set the API endpoint to your desired domain, run the following command:

    hal config security api edit --override-base-url https://spinnaker-api.example.com

The output will look like:

    Output+ Get current deployment
      Success
    + Get API security settings
      Success
    + Edit API security settings
      Success
    ...

To set the UI endpoint to your domain, which is where you will access Spinnaker, run:

    hal config security ui edit --override-base-url https://spinnaker.example.com

The output will look like:

    Output+ Get current deployment
      Success
    + Get UI security settings
      Success
    + Edit UI security settings
      Success
    + Successfully updated UI security settings.

Remember to replace `spinnaker-api.example.com` and `spinnaker.example.com` with your domains. These are the domains you have pointed to the Load Balancer that you created during the Nginx Ingress Controller prerequisite.

You’ve created and secured Spinnaker’s Kubernetes account, configured your Space as its underlying storage, and set its UI and API endpoints to your domains. Now you can list the available Spinnaker versions:

    hal version list

Your output will show a list of available versions. At the time of writing this article `1.13.5` was the latest version:

    Output+ Get current deployment
      Success
    + Get Spinnaker version
      Success
    + Get released versions
      Success
    + You are on version "", and the following are available:
     - 1.11.12 (Cobra Kai):
       Changelog: https://gist.GitHub.com/spinnaker-release/29a01fa17afe7c603e510e202a914161
       Published: Fri Apr 05 14:55:40 UTC 2019
       (Requires Halyard >= 1.11)
     - 1.12.9 (Unbreakable):
       Changelog: https://gist.GitHub.com/spinnaker-release/7fa9145349d6beb2f22163977a94629e
       Published: Fri Apr 05 14:11:44 UTC 2019
       (Requires Halyard >= 1.11)
     - 1.13.5 (BirdBox):
       Changelog: https://gist.GitHub.com/spinnaker-release/23af06bc73aa942c90f89b8e8c8bed3e
       Published: Mon Apr 22 14:32:29 UTC 2019
       (Requires Halyard >= 1.17)

To select a version to install, run the following command:

    hal config version edit --version 1.13.5

It is recommended to always select the latest version, unless you encounter some kind of regression.

You will see the following output:

    Output+ Get current deployment
      Success
    + Edit Spinnaker version
      Success
    + Spinnaker has been configured to update/install version "version".
      Deploy this version of Spinnaker with `hal deploy apply`.

You have now fully configured Spinnaker’s deployment. You’ll deploy it with the following command:

    hal deploy apply

This command could take a few minutes to finish.

The final output will look like this:

    Output+ Get current deployment
      Success
    + Prep deployment
      Success
    + Preparation complete... deploying Spinnaker
    + Get current deployment
      Success
    + Apply deployment
      Success
    + Deploy spin-redis
      Success
    + Deploy spin-clouddriver
      Success
    + Deploy spin-front50
      Success
    + Deploy spin-orca
      Success
    + Deploy spin-deck
      Success
    + Deploy spin-echo
      Success
    + Deploy spin-gate
      Success
    + Deploy spin-rosco
      Success
    ...

Halyard is showing you the deployment status of each of Spinnaker’s microservices. Behind the scenes, it calls kubectl to install them.

Kubernetes will take some time—ten minutes on average—to bring all of the containers up, especially for the first time. You can watch the progress by running the following command:

    kubectl get pods -n spinnaker -w

You’ve deployed Spinnaker to your Kubernetes cluster, but it can’t be accessed beyond your cluster.

You’ll be storing the ingress configuration in a file named `spinnaker-ingress.yaml`. Create it using your text editor:

    nano spinnaker-ingress.yaml

Add the following lines:

spinnaker-ingress.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: spinnaker-ingress
      namespace: spinnaker
      annotations:
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    spec:
      tls:
      - hosts:
        - spinnaker-api.example.com
        - spinnaker.example.com
        secretName: spinnaker
      rules:
      - host: spinnaker-api.example.com
        http:
          paths:
          - backend:
              serviceName: spin-gate
              servicePort: 8084
      - host: spinnaker.example.com
        http:
          paths:
          - backend:
              serviceName: spin-deck
              servicePort: 9000

Remember to replace `spinnaker-api.example.com` with your API domain, and `spinnaker.example.com` with your UI domain.

The configuration file defines an ingress called `spinnaker-ingress`. The annotations specify that the controller for this ingress will be the Nginx controller, and that the `letsencrypt-prod` cluster issuer will generate the TLS certificates, defined in the prerequisite tutorial.

Then, it specifies that TLS will secure the UI and API domains. It sets up routing by directing the API domain to the `spin-gate` service (Spinnaker’s API containers), and the UI domain to the `spin-deck` service (Spinnaker’s UI containers) at the appropriate ports `8084` and `9000`.

Save and close the file.

Create the Ingress in Kubernetes by running:

    kubectl create -f spinnaker-ingress.yaml

You’ll see the following output:

    Outputingress.extensions/spinnaker-ingress created

Wait a few minutes for Let’s Encrypt to provision the TLS certificates, and then navigate to your UI domain, `spinnaker.example.com`, in a browser. You will see Spinnaker’s user interface.

![Spinnaker's home page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step3.png)

You’ve deployed Spinnaker to your cluster, exposed the UI and API components at your domains, and tested if it works. Now you’ll create an application in Spinnaker and run a pipeline to deploy the `Hello World` app.

## Step 4 — Creating an Application and Running a Pipeline

In this section, you will use your access to Spinnaker at your domain to create an application with it. You’ll then create and run a pipeline to deploy a `Hello World` app, which can be found at [paulbouwer/hello-kubernetes](https://hub.docker.com/r/paulbouwer/hello-kubernetes/). You’ll access the app afterward.

Navigate to your domain where you have exposed Spinnaker’s UI. In the upper right corner, press on **Actions** , then select **Create Application**. You will see the **New Application** form.

![Creating a new Application in Spinnaker](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step4a.png)

Type in `hello-world` as the name, input your email address, and press **Create**.

When the page loads, navigate to **Pipelines** by clicking the first tab in the top menu. You will see that there are no pipelines defined yet.

![No pipelines defined in Spinnaker](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step4b.png)

Press on **Configure a new pipeline** and a new form will open.

![Creating a new Pipeline in Spinnaker](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step4c.png)

Fill in `Deploy Hello World Application` as your pipeline’s name, and press **Create**.

On the next page, click the **Add Stage** button. As the **Type** , select **Deploy (Manifest)**, which is used for deploying Kubernetes manifests you specify. For the **Stage Name** , type in `Deploy Hello World`. Scroll down, and in the textbox under **Manifest Configuration** , enter the following lines:

Manifest Configuration

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: hello-world-ingress
      namespace: spinnaker
      annotations:
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    spec:
      tls:
      - hosts:
        - hello-world.example.com
        secretName: hello-world
      rules:
      - host: hello-world.example.com
        http:
          paths:
          - backend:
              serviceName: hello-kubernetes
              servicePort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: hello-kubernetes
      namespace: spinnaker
    spec:
      type: ClusterIP
      ports:
      - port: 80
        targetPort: 8080
      selector:
        app: hello-kubernetes
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hello-kubernetes
      namespace: spinnaker
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: hello-kubernetes
      template:
        metadata:
          labels:
            app: hello-kubernetes
        spec:
          containers:
          - name: hello-kubernetes
            image: paulbouwer/hello-kubernetes:1.5
            ports:
            - containerPort: 8080

Remember to replace `hello-world.example.com` with your domain, which is also pointed at your Load Balancer.

In this configuration, you define a `Deployment`, consisting of three replicas of the `paulbouwer/hello-kubernetes:1.5` image. You also define a `Service` to be able to access it and an Ingress to expose the `Service` at your domain.

Press **Save Changes** in the bottom right corner of the screen. When it finishes, navigate back to **Pipelines**. On the right side, select the pipeline you just created and press the **Start Manual Execution** link. When asked to confirm, press **Run**.

This pipeline will take a short time to complete. You will see the progress bar complete when it has successfully finished.

![Successfully ran a Pipeline](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step4d.png)

You can now navigate to the domain you defined in the configuration. You will see the `Hello World` app, which Spinnaker just deployed.

![Hello World App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step4e.png)

You’ve created an application in Spinnaker, ran a pipeline to deploy a `Hello World` app, and accessed it. In the next step, you will secure Spinnaker by enabling GitHub Organizations authorization.

## Step 5 — Enabling Role-Based Access with GitHub Organizations

In this section, you will enable GitHub OAuth authentication and GitHub Organizations authorization. Enabling GitHub OAuth authentication forces Spinnaker users to log in via GitHub, therefore preventing anonymous access. Authorization via GitHub Organizations restricts access only to those in an Organization. A GitHub Organization can contain [Teams](https://help.github.com/en/articles/about-teams) (named groups of members), which you will be able to use to restrict access to resources in Spinnaker even further.

For OAuth authentication to work, you’ll first need to set up the authorization callback URL, which is where the user will be redirected after authorization. This is your API domain ending with `/login`. You need to specify this manually to prevent Spinnaker and other services from guessing. To configure this, run the following command:

    hal config security authn oauth2 edit --pre-established-redirect-uri https://spinnaker-api.example.com/login

You will see this output:

    Output+ Get current deployment
      Success
    + Get authentication settings
      Success
    + Edit oauth2 authentication settings
      Success
    + Successfully edited oauth2 method.

To set up OAuth authentication with GitHub, you’ll need to create an OAuth application for your Organization. To do so, navigate to your Organization on GitHub, go to **Settings** , click on **Developer Settings** , and then select **OAuth Apps** from the left-hand menu. Afterward, click the **New OAuth App** button on the right. You will see the **Register a new OAuth application** form.

![Creating a new OAuth App on GitHub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/spinnakerk8spipeline/step5a.png)

Enter `spinnaker-auth` as the name. For the **Homepage URL** , enter `https://spinnaker.example.com`, and for the **Authorization callback URL** , enter `https://spinnaker-api.example.com/login`. Then, press **Register Application**.

You’ll be redirected to the settings page for your new OAuth app. Note the **Client ID** and **Client Secret** values—you’ll need them for the next command.

With the OAuth app created, you can configure Spinnaker to use the OAuth app by running the following command:

    hal config security authn oauth2 edit --client-id client_id --client-secret client_secret --provider GitHub

Remember to replace `client_id` and `client_secret` with the values shown on the GitHub settings page.

You output will be similar to the following:

    Output+ Get current deployment
      Success
    + Get authentication settings
      Success
    + Edit oauth2 authentication settings
      Success
    Problems in default.security.authn:
    - WARNING An authentication method is fully or partially
      configured, but not enabled. It must be enabled to take effect.
    
    + Successfully edited oauth2 method.

You’ve configured Spinnaker to use the OAuth app. Now, to enable it, execute:

    hal config security authn oauth2 enable

The output will look like:

    Output+ Get current deployment
      Success
    + Edit oauth2 authentication settings
      Success
    + Successfully enabled oauth2

You’ve configured and enabled GitHub OAuth authentication. Now users will be forced to log in via GitHub in order to access Spinnaker. However, right now, everyone who has a GitHub account can log in, which is not what you want. To overcome this, you’ll configure Spinnaker to restrict access to members of your desired Organization.

You’ll need to set this up semi-manually via local config files, because Halyard does not yet have a command for setting this. During deployment, Halyard will use the local config files to override the generated configuration.

Halyard looks for custom configuration under `~/.hal/default/profiles/`. Files named `service-name-*.yml` are picked up by Halyard and used to override the settings of a particular service. The service that you’ll override is called `gate`, and serves as the API gateway for the whole of Spinnaker.

Create a file under `~/.hal/default/profiles/` named `gate-local.yml`:

    nano ~/.hal/default/profiles/gate-local.yml

Add the following lines:

gate-local.yml

    security:
     oauth2:
       providerRequirements:
         type: GitHub
         organization: your_organization_name

Replace `your_organization_name` with the name of your GitHub Organization. Save and close the file.

With this bit of configuration, only members of your GitHub Organization will be able to access Spinnaker.

**Note:** Only those members of your GitHub Organization whose membership is set to **Public** will be able to log in to Spinnaker. This setting can be changed on the member list page of your Organization.

Now, you’ll integrate Spinnaker with an even more particular access-rule solution: GitHub Teams. This will enable you to specify which Team(s) will have access to resources created in Spinnaker, such as applications.

To achieve this, you’ll need to have a GitHub Personal Access Token for an admin account in your Organization. To create one, visit [Personal Access Tokens](https://GitHub.com/settings/tokens) and press the **Generate New Token** button. On the next page, give it a description of your choice and be sure to check the **read:org** scope, located under **admin:org**. When you are done, press **Generate token** and note it down when it appears—you won’t be able to see it again.

To configure GitHub Teams role authorization in Spinnaker, run the following command:

    hal config security authz github edit --accessToken access_token --organization organization_name --baseUrl https://api.github.com

Be sure to replace `access_token` with your personal access token you generated and replace `organization_name` with the name of the Organization.

The output will be:

    Output+ Get current deployment
      Success
    + Get GitHub group membership settings
      Success
    + Edit GitHub group membership settings
      Success
    + Successfully edited GitHub method.

You’ve updated your GitHub group settings. Now, you’ll set the authorization provider to GitHub by running the following command:

    hal config security authz edit --type github

The output will look like:

    Output+ Get current deployment
      Success
    + Get group membership settings
      Success
    + Edit group membership settings
      Success
    + Successfully updated roles.

After updating these settings, enable them by running:

    hal config security authz enable

You’ll see the following output:

    Output+ Get current deployment
      Success
    + Edit authorization settings
      Success
    + Successfully enabled authorization

With all the changes in place, you can now apply the changes to your running Spinnaker deployment. Execute the following command to do this:

    hal deploy apply

Once it has finished, wait for Kubernetes to propagate the changes. This can take quite some time—you can watch the progress by running:

    kubectl get pods -n spinnaker -w

When all the pods’ states become `Running` and availability `1/1`, navigate to your Spinnaker UI domain. You will be redirected to GitHub and asked to log in, if you’re not already. If the account you logged in with is a member of the Organization, you will be redirected back to Spinnaker and logged in. Otherwise, you will be denied access with a message that looks like this:

    {"error":"Unauthorized", "message":"Authentication Failed: User's provider info does not have all required fields.", "status":401, "timestamp":...}

The effect of GitHub Teams integration is that Spinnaker now translates them into _roles_. You can use these [roles](https://www.spinnaker.io/setup/security/authorization/#role-providers) in Spinnaker to incorporate additional restrictions to access for members of particular teams. If you try to add another application, you’ll notice that you can now also specify permissions, which combine the level of access—read only or read and write—with a role, for that application.

You’ve set up GitHub authentication and authorization. You have also configured Spinnaker to restrict access to members of your Organization, learned about roles and permissions, and considered the place of GitHub Teams when integrated with Spinnaker.

## Conclusion

You have successfully configured and deployed Spinnaker to your DigitalOcean Kubernetes cluster. You can now manage and use your cloud resources more easily, from a central place. You can use triggers to automatically start a pipeline; for example, when a new Docker image has been added to the registry. To learn more about Spinnaker’s terms and architecture, visit the [official documentation](https://www.spinnaker.io/guides/user/applications/). If you wish to deploy a private Docker registry to your cluster to hold your images, visit [How To Set Up a Private Docker Registry on Top of DigitalOcean Spaces and Use It with DO Kubernetes](how-to-set-up-a-private-docker-registry-on-top-of-digitalocean-spaces-and-use-it-with-do-kubernetes).
