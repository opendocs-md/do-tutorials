---
author: Savic
date: 2019-04-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-top-of-digitalocean-spaces-and-use-it-with-digitalocean-kubernetes
---

# How To Set Up a Private Docker Registry on Top of DigitalOcean Spaces and Use It with DigitalOcean Kubernetes

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

A [Docker registry](https://docs.docker.com/registry/) is a storage and content delivery system for named Docker images, which are the industry standard for containerized applications. A private Docker registry allows you to securely share your images within your team or organization with more flexibility and control when compared to public ones. By hosting your private Docker registry directly in your Kubernetes cluster, you can achieve higher speeds, lower latency, and better availability, all while having control over the registry.

The underlying registry storage is delegated to external drivers. The default storage system is the local filesystem, but you can swap this for a cloud-based storage driver. [DigitalOcean Spaces](https://www.digitalocean.com/products/spaces/) is an S3-compatible object storage designed for developer teams and businesses that want a scalable, simple, and affordable way to store and serve vast amounts of data, and is very suitable for storing Docker images. It has a built-in CDN network, which can greatly reduce latency when frequently accessing images.

In this tutorial, you’ll deploy your private Docker registry to your [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/) cluster using [Helm](https://helm.sh/), backed up by DigitalOcean Spaces for storing data. You’ll create API keys for your designated Space, install the Docker registry to your cluster with custom configuration, configure Kubernetes to properly authenticate with it, and test it by running a sample deployment on the cluster. At the end of this tutorial, you’ll have a secure, private Docker registry installed on your DigitalOcean Kubernetes cluster.

## Prerequisites

Before you begin this tutorial, you’ll need:

- Docker installed on the machine that you’ll access your cluster from. For Ubuntu 18.04 visit [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04). You only need to complete the first step. Otherwise visit Docker’s [website](https://docs.docker.com/install/) for other distributions.

- A DigitalOcean Kubernetes cluster with your connection configuration configured as the `kubectl` default. Instructions on how to configure `kubectl` are shown under the **Connect to your Cluster** step shown when you create your cluster. To learn how to create a Kubernetes cluster on DigitalOcean, see [Kubernetes Quickstart](https://www.digitalocean.com/docs/kubernetes/quickstart/).

- A DigitalOcean Space with API keys (access and secret). To learn how to create a DigitalOcean Space and API keys, see [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key).

- The Helm package manager installed on your local machine, and Tiller installed on your cluster. Complete steps 1 and 2 of the [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager). You only need to complete the first two steps.

- The Nginx Ingress Controller and Cert-Manager installed on the cluster. For a guide on how to do this, see [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes).

- A domain name with two DNS A records pointed to the DigitalOcean Load Balancer used by the Ingress. If you are using DigitalOcean to manage your domain’s DNS records, consult [How to Manage DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/) to create A records. In this tutorial, we’ll refer to the A records as `registry.example.com` and `k8s-test.example.com`.

## Step 1 — Configuring and Installing the Docker Registry

In this step, you will create a configuration file for the registry deployment and install the Docker registry to your cluster with the given config using the Helm package manager.

During the course of this tutorial, you will use a configuration file called `chart_values.yaml` to override some of the default settings for the Docker registry Helm _chart_. Helm calls its packages, charts; these are sets of files that outline a related selection of Kubernetes resources. You’ll edit the settings to specify DigitalOcean Spaces as the underlying storage system and enable HTTPS access by wiring up Let’s Encrypt TLS certificates.

As part of the prerequisite, you would have created the `echo1` and `echo2` services and an `echo_ingress` ingress for testing purposes; you will not need these in this tutorial, so you can now delete them.

Start off by deleting the ingress by running the following command:

    kubectl delete -f echo_ingress.yaml

Then, delete the two test services:

    kubectl delete -f echo1.yaml && kubectl delete -f echo2.yaml

The kubectl `delete` command accepts the file to delete when passed the `-f` parameter.

Create a folder that will serve as your workspace:

    mkdir ~/k8s-registry

Navigate to it by running:

    cd ~/k8s-registry

Now, using your text editor, create your `chart_values.yaml` file:

    nano chart_values.yaml

Add the following lines, ensuring you replace the highlighted lines with your details:

chart\_values.yaml

    ingress:
      enabled: true
      hosts:
        - registry.example.com
      annotations:
        kubernetes.io/ingress.class: nginx
        certmanager.k8s.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/proxy-body-size: "30720m"
      tls:
        - secretName: letsencrypt-prod
          hosts:
            - registry.example.com
    
    storage: s3
    
    secrets:
      htpasswd: ""
      s3:
        accessKey: "your_space_access_key"
        secretKey: "your_space_secret_key"
    
    s3:
      region: your_space_region
      regionEndpoint: your_space_region.digitaloceanspaces.com
      secure: true
      bucket: your_space_name

The first block, `ingress`, configures the Kubernetes Ingress that will be created as a part of the Helm chart deployment. The Ingress object makes outside HTTP/HTTPS routes point to internal services in the cluster, thus allowing communication from the outside. The overridden values are:

- `enabled`: set to `true` to enable the Ingress.
- `hosts`: a list of hosts from which the Ingress will accept traffic.
- `annotations`: a list of metadata that provides further direction to other parts of Kubernetes on how to treat the Ingress. You set the Ingress Controller to `nginx`, the Let’s Encrypt cluster issuer to the production variant (`letsencrypt-prod`), and tell the `nginx` controller to accept files with a max size of 30 GB, which is a sensible limit for even the largest Docker images.
- `tls`: this subcategory configures Let’s Encrypt HTTPS. You populate the `hosts` list that defines from which secure hosts this Ingress will accept HTTPS traffic with our example domain name.

Then, you set the file system storage to `s3` — the other available option would be `filesystem`. Here `s3` indicates using a remote storage system compatible with the industry-standard Amazon S3 API, which DigitalOcean Spaces fulfills.

In the next block, `secrets`, you configure keys for accessing your DigitalOcean Space under the `s3` subcategory. Finally, in the `s3` block, you configure the parameters specifying your Space.

Save and close your file.

Now, if you haven’t already done so, set up your A records to point to the Load Balancer you created as part of the Nginx Ingress Controller installation in the prerequisite tutorial. To see how to set your DNS on DigitalOcean, see [How to Manage DNS Records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/).

Next, ensure your Space isn’t empty. The Docker registry won’t run at all if you don’t have any files in your Space. To get around this, upload a file. Navigate to the Spaces tab, find your Space, click the **Upload File** button, and upload any file you’d like. You could upload the configuration file you just created.

![Empty file uploaded to empty Space](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/registry_spaces_k8s/step2.png)

Before installing anything via Helm, you need to refresh its cache. This will update the latest information about your chart repository. To do this run the following command:

    helm repo update

Now, you’ll deploy the Docker registry chart with this custom configuration via Helm by running:

    helm install stable/docker-registry -f chart_values.yaml --name docker-registry

You’ll see the following output:

    OutputNAME: docker-registry
    ...
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ConfigMap
    NAME DATA AGE
    docker-registry-config 1 1s
    
    ==> v1/Pod(related)
    NAME READY STATUS RESTARTS AGE
    docker-registry-54df68fd64-l26fb 0/1 ContainerCreating 0 1s
    
    ==> v1/Secret
    NAME TYPE DATA AGE
    docker-registry-secret Opaque 3 1s
    
    ==> v1/Service
    NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    docker-registry ClusterIP 10.245.131.143 <none> 5000/TCP 1s
    
    ==> v1beta1/Deployment
    NAME READY UP-TO-DATE AVAILABLE AGE
    docker-registry 0/1 1 0 1s
    
    ==> v1beta1/Ingress
    NAME HOSTS ADDRESS PORTS AGE
    docker-registry registry.example.com 80, 443 1s
    
    
    NOTES:
    1. Get the application URL by running these commands:
      https://registry.example.com/

Helm lists all the resources it created as a result of the Docker registry chart deployment. The registry is now accessible from the domain name you specified earlier.

You’ve configured and deployed a Docker registry on your Kubernetes cluster. Next, you will test the availability of the newly deployed Docker registry.

## Step 2 — Testing Pushing and Pulling

In this step, you’ll test your newly deployed Docker registry by pushing and pulling images to and from it. Currently, the registry is empty. To have something to push, you need to have an image available on the machine you’re working from. Let’s use the `mysql` Docker image.

Start off by pulling `mysql` from the Docker Hub:

    sudo docker pull mysql

Your output will look like this:

    OutputUsing default tag: latest
    latest: Pulling from library/mysql
    27833a3ba0a5: Pull complete
    ...
    e906385f419d: Pull complete
    Digest: sha256:a7cf659a764732a27963429a87eccc8457e6d4af0ee9d5140a3b56e74986eed7
    Status: Downloaded newer image for mysql:latest

You now have the image available locally. To inform Docker where to push it, you’ll need to tag it with the host name, like so:

    sudo docker tag mysql registry.example.com/mysql

Then, push the image to the new registry:

    sudo docker push registry.example.com/mysql

This command will run successfully and indicate that your new registry is properly configured and accepting traffic — including pushing new images. If you see an error, double check your steps against steps 1 and 2.

To test pulling from the registry cleanly, first delete the local `mysql` images with the following command:

    sudo docker rmi registry.example.com/mysql && sudo docker rmi mysql

Then, pull it from the registry:

    sudo docker pull registry.example.com/mysql

This command will take a few seconds to complete. If it runs successfully, that means your registry is working correctly. If it shows an error, double check what you have entered against the previous commands.

You can list Docker images available locally by running the following command:

    sudo docker images

You’ll see output listing the images available on your local machine, along with their ID and date of creation.

Your Docker registry is configured. You’ve pushed an image to it and verified you can pull it down. Now let’s add authentication so only certain people can access the code.

## Step 3 — Adding Account Authentication and Configuring Kubernetes Access

In this step, you’ll set up username and password authentication for the registry using the `htpasswd` utility.

The `htpasswd` utility comes from the Apache webserver, which you can use for creating files that store usernames and passwords for basic authentication of HTTP users. The format of `htpasswd` files is `username:hashed_password` (one per line), which is portable enough to allow other programs to use it as well.

To make `htpasswd` available on the system, you’ll need to install it by running:

    sudo apt install apache2-utils -y

**Note:**  
If you’re running this tutorial from a Mac, you’ll need to use the following command to make `htpasswd` available on your machine:

    docker run --rm -v ${PWD}:/app -it httpd htpasswd -b -c /app/htpasswd_file sammy password

Create it by executing the following command:

    touch htpasswd_file

Add a username and password combination to `htpasswd_file`:

    htpasswd -B htpasswd_file username

Docker requires the password to be hashed using the [_bcrypt_](https://en.wikipedia.org/wiki/Bcrypt) algorithm, which is why we pass the `-B` parameter. The bcrypt algorithm is a password hashing function based on Blowfish block cipher, with a _work factor_ parameter, which specifies how expensive the hash function will be.

Remember to replace `username` with your desired username. When run, `htpasswd` will ask you for the accompanying password and add the combination to `htpasswd_file`. You can repeat this command for as many users as you wish to add.

Now, show the contents of `htpasswd_file` by running the following command:

    cat htpasswd_file

Select and copy the contents shown.

To add authentication to your Docker registry, you’ll need to edit `chart_values.yaml` and add the contents of `htpasswd_file` in the `htpasswd` variable.

Open `chart_values.yaml` for editing:

    nano chart_values.yaml

Find the line that looks like this:

chart\_values.yaml

      htpasswd: ""

Edit it to match the following, replacing `htpasswd\_file\_contents` with the contents you copied from the `htpasswd_file`:

chart\_values.yaml

      htpasswd: |-
        htpasswd_file_contents

Be careful with the indentation, each line of the file contents must have four spaces before it.

Once you’ve added your contents, save and close the file.

To propagate the changes to your cluster, run the following command:

    helm upgrade docker-registry stable/docker-registry -f chart_values.yaml

The output will be similar to that shown when you first deployed your Docker registry:

    OutputRelease "docker-registry" has been upgraded. Happy Helming!
    LAST DEPLOYED: ...
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ConfigMap
    NAME DATA AGE
    docker-registry-config 1 3m8s
    
    ==> v1/Pod(related)
    NAME READY STATUS RESTARTS AGE
    docker-registry-6c5bb7ffbf-ltnjv 1/1 Running 0 3m7s
    
    ==> v1/Secret
    NAME TYPE DATA AGE
    docker-registry-secret Opaque 4 3m8s
    
    ==> v1/Service
    NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    docker-registry ClusterIP 10.245.128.245 <none> 5000/TCP 3m8s
    
    ==> v1beta1/Deployment
    NAME READY UP-TO-DATE AVAILABLE AGE
    docker-registry 1/1 1 1 3m8s
    
    ==> v1beta1/Ingress
    NAME HOSTS ADDRESS PORTS AGE
    docker-registry registry.example.com 159.89.215.50 80, 443 3m8s
    
    
    NOTES:
    1. Get the application URL by running these commands:
      https://registry.example.com/

This command calls Helm and instructs it to upgrade an existing release, in your case `docker-registry`, with its chart defined in `stable/docker-registry` in the chart repository, after applying the `chart_values.yaml` file.

Now, you’ll try pulling an image from the registry again:

    sudo docker pull registry.example.com/mysql

The output will look like the following:

    OutputUsing default tag: latest
    Error response from daemon: Get https://registry.example.com/v2/mysql/manifests/latest: no basic auth credentials

It correctly failed because you provided no credentials. This means that your Docker registry authorizes requests correctly.

To log in to the registry, run the following command:

    sudo docker login registry.example.com

Remember to replace `registry.example.com` with your domain address. It will prompt you for a username and password. If it shows an error, double check what your `htpasswd_file` contains. You must define the username and password combination in the `htpasswd_file`, which you created earlier in this step.

To test the login, you can try to pull again by running the following command:

    sudo docker pull registry.example.com/mysql

The output will look similar to the following:

    OutputUsing default tag: latest
    latest: Pulling from mysql
    Digest: sha256:f2dc118ca6fa4c88cde5889808c486dfe94bccecd01ca626b002a010bb66bcbe
    Status: Image is up to date for registry.example.com/mysql:latest

You’ve now configured Docker and can log in securely. To configure Kubernetes to log in to your registry, run the following command:

    sudo kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/sammy/.docker/config.json --type=kubernetes.io/dockerconfigjson

You will see the following output:

    Outputsecret/regcred created

This command creates a secret in your cluster with the name `regcred`, takes the contents of the JSON file where Docker stores the credentials, and parses it as `dockerconfigjson`, which defines a registry credential in Kubernetes.

You’ve used `htpasswd` to create a login config file, configured the registry to authenticate requests, and created a Kubernetes secret containing the login credentials. Next, you will test the integration between your Kubernetes cluster and registry.

## Step 4 — Testing Kubernetes Integration by Running a Sample Deployment

In this step, you’ll run a sample deployment with an image stored in the in-cluster registry to test the connection between your Kubernetes cluster and registry.

In the last step, you created a secret, called `regcred`, containing login credentials for your private registry. It may contain login credentials for multiple registries, in which case you’ll have to update the Secret accordingly.

You can specify which secret Kubernetes should use when pulling containers in the pod definition by specifying `imagePullSecrets`. This step is necessary when the Docker registry requires authentication.

You’ll now deploy a sample [Hello World image](https://github.com/paulbouwer/hello-kubernetes/blob/master/Dockerfile) from your private Docker registry to your cluster. First, in order to push it, you’ll pull it to your machine by running the following command:

    sudo docker pull paulbouwer/hello-kubernetes:1.5

Then, tag it by running:

    sudo docker tag paulbouwer/hello-kubernetes:1.5 registry.example.com/paulbouwer/hello-kubernetes:1.5

Finally, push it to your registry:

    sudo docker push registry.example.com/paulbouwer/hello-kubernetes:1.5

Delete it from your machine as you no longer need it locally:

    sudo docker rmi registry.example.com/paulbouwer/hello-kubernetes:1.5

Now, you’ll deploy the sample Hello World application. First, create a new file, `hello-world.yaml`, using your text editor:

    nano hello-world.yaml

Next, you’ll define a Service and an Ingress to make the app accessible to outside of the cluster. Add the following lines, replacing the highlighted lines with your domains:

hello-world.yaml

    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: hello-kubernetes-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/rewrite-target: /
    spec:
      rules:
      - host: k8s-test.example.com
        http:
          paths:
          - path: /
            backend:
              serviceName: hello-kubernetes
              servicePort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: hello-kubernetes
    spec:
      type: NodePort
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
            image: registry.example.com/paulbouwer/hello-kubernetes:1.5
            ports:
            - containerPort: 8080
          imagePullSecrets:
          - name: regcred

First, you define the Ingress for the Hello World deployment, which you will route through the Load Balancer that the Nginx Ingress Controller owns. Then, you define a service that can access the pods created in the deployment. In the actual deployment spec, you specify the `image` as the one located in your registry and set `imagePullSecrets` to `regcred`, which you created in the previous step.

Save and close the file. To deploy this to your cluster, run the following command:

    kubectl apply -f hello-world.yaml

You’ll see the following output:

    Outputingress.extensions/hello-kubernetes-ingress created
    service/hello-kubernetes created
    deployment.apps/hello-kubernetes created

You can now navigate to your test domain — the second A record, `k8s-test.example.com` in this tutorial. You will see the Kubernetes **Hello world!** page.

![Hello World page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/registry_spaces_k8s/step5.png)

The Hello World page lists some environment information, like the Linux kernel version and the internal ID of the pod the request was served from. You can also access your Space via the web interface to see the images you’ve worked with in this tutorial.

If you want to delete this Hello World deployment after testing, run the following command:

    kubectl delete -f hello-world.yaml

You’ve created a sample Hello World deployment to test if Kubernetes is properly pulling images from your private registry.

## Conclusion

You have now successfully deployed your own private Docker registry on your DigitalOcean Kubernetes cluster, using DigitalOcean Spaces as the storage layer underneath. There is no limit to how many images you can store, Spaces can extend infinitely, while at the same time providing the same security and robustness. In production, though, you should always strive to optimize your Docker images as much as possible, take a look at the [How To Optimize Docker Images for Production](how-to-optimize-docker-images-for-production) tutorial.
