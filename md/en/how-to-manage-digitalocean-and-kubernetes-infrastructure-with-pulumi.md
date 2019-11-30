---
author: pulumi
date: 2019-09-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-digitalocean-and-kubernetes-infrastructure-with-pulumi
---

# How to Manage DigitalOcean and Kubernetes Infrastructure with Pulumi

_The author selected the [Diversity in Tech Fund](https://www.brightfunds.org/funds/diversity-in-tech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Pulumi](https://www.pulumi.com/docs) is a tool for creating, deploying, and managing infrastructure using code written in general purpose programming languages. It supports automating all of DigitalOcean’s managed services—such as Droplets, managed databases, DNS records, and Kubernetes clusters—in addition to application configuration. Deployments are performed from an easy-to-use command-line interface that also integrates with a wide variety of popular CI/CD systems.

Pulumi supports multiple languages but in this tutorial you will use [TypeScript](https://www.typescriptlang.org/), a statically typed version of [JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) that uses the [Node.js](https://nodejs.org/) runtime. This means you will get IDE support and compile-time checking that will help to ensure you’ve configured the right resources, used correct slugs, etc., while still being able to access any [NPM](https://www.npmjs.com/) modules for utility tasks.

In this tutorial, you will provision a DigitalOcean [Kubernetes](https://kubernetes.io/) cluster, a load balanced Kubernetes application, and a DigitalOcean DNS domain that makes your application available at a stable domain name of your choosing. This can all be provisioned in 60 lines of infrastructure-as-code and a single `pulumi up` command-line gesture. After this tutorial, you’ll be ready to productively build powerful cloud architectures using Pulumi infrastructure-as-code that leverages the full surface area of DigitalOcean and Kubernetes.

## Prerequisites

To follow this tutorial, you will need:

- A DigitalOcean Account to deploy resources to. If you do not already have one, [register here](https://cloud.digitalocean.com/registrations/new).
- A DigitalOcean API Token to perform automated deployments. [Generate a personal access token here](https://www.digitalocean.com/docs/api/create-personal-access-token/) and keep it handy as you’ll use it in Step 2.
- Because you’ll be creating and using a Kubernetes cluster, you’ll need to [install `kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/). Don’t worry about configuring it further — you’ll do that later.
- You will write your infrastructure-as-code in TypeScript, so you will need Node.js 8 or later. [Download it here](https://nodejs.org/en/download/) or install it [using your system’s package manager](https://nodejs.org/en/download/package-manager/).
- You’ll use Pulumi to deploy infrastructure, so you’ll need to [install the open source Pulumi SDK](https://www.pulumi.com/docs/reference/install/).
- To perform the optional Step 5, you will need a domain name configured to use DigitalOcean nameservers. [This guide](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) explains how to do this for your registrar of choice.

## Step 1 — Scaffolding a New Project

The first step is to create a directory that will store your Pulumi project. This directory will contain the source code for your infrastructure definitions, in addition to metadata files describing the project and its NPM dependencies.

First, create the directory:

    mkdir do-k8s

Next, move in to the newly created directory:

    cd do-k8s

From now on, run commands from your newly created `do-k8s` directory.

Next, create a new Pulumi project. There are different ways to accomplish this, but the easiest way is to use the `pulumi new` command with the `typescript` project template. This command will first prompt you to log in to Pulumi so that your project and deployment state are saved, and will then create a simple TypeScript project in the current directory:

    pulumi new typescript -y

Here you have passed the `-y` option to the `new` command which tells it to accept default project options. For example, the project name is taken from the current directory’s name, and so will be `do-k8s`. If you’d like to use different options for your project name, simply elide the `-y`.

After running the command, list the contents of the directory with `ls`:

    ls

The following files will now be present:

    OutputPulumi.yaml index.ts node_modules
    package-lock.json package.json tsconfig.json

The primary file you’ll be editing is **`index.ts`**. Although this tutorial only uses this single file, you can organize your project any way you see fit using Node.js modules. This tutorial also describes one step at a time, leveraging the fact that Pulumi can detect and incrementally deploy only what has changed. If you prefer, you can just populate the entire program, and deploy it all in one go using `pulumi up`.

Now that you’ve scaffolded your new project, you are ready to add the dependencies needed to follow the tutorial.

## Step 2 — Adding Dependencies

The next step is to install and add dependencies on the DigitalOcean and Kubernetes packages. First, install them using NPM:

    npm install @pulumi/digitalocean @pulumi/kubernetes

This will download the NPM packages, Pulumi plugins, and save them as dependencies.

Next, open the `index.ts` file with your favorite editor. This tutorial will use nano:

    nano index.ts

Replace the contents of your `index.ts` with the following:

index.ts

    import * as digitalocean from "@pulumi/digitalocean";
    import * as kubernetes from "@pulumi/kubernetes";

This makes the full contents of these packages available to your program. If you type `"digitalocean."` using an IDE that understands TypeScript and Node.js, you should see a list of DigitalOcean resources supported by this package, for instance.

Save and close the file after adding the content.

**Note:** We will be using a subset of what’s available in those packages. For complete documentation of resources, properties, and associated APIs, please refer to the relevant API documentation for the [`@pulumi/digitalocean`](https://www.pulumi.com/docs/reference/pkg/nodejs/pulumi/digitalocean/) and [`@pulumi/kubernetes`](https://www.pulumi.com/docs/reference/pkg/nodejs/pulumi/kubernetes/) packages.

Next, you will configure your DigitalOcean token so that Pulumi can provision resources in your account:

    pulumi config set digitalocean:token YOUR_TOKEN_HERE --secret

Notice the `--secret` flag, which uses Pulumi’s encryption service to encrypt your token, ensuring that it is stored in cyphertext. If you prefer, you can use the `DIGITALOCEAN_TOKEN` environment variable instead, but you’ll need to remember to set it every time you update your program, whereas using configuration automatically stores and uses it for your project.

In this step you added the necessary dependencies and configured your API token with Pulumi so that you can provision your Kubernetes cluster.

## Step 3 — Provisioning a Kubernetes Cluster

Now you’re ready to create a DigitalOcean Kubernetes cluster. Get started by reopening the `index.ts` file:

    nano index.ts

Add these lines at the end of your `index.ts` file:

index.ts

    ...
    const cluster = new digitalocean.KubernetesCluster("do-cluster", {
        region: digitalocean.Regions.SFO2,
        version: "latest",
        nodePool: {
            name: "default",
            size: digitalocean.DropletSlugs.DropletS2VPCU2GB,
            nodeCount: 3,
        },
    });
    
    export const kubeconfig = cluster.kubeConfigs[0].rawConfig;

This new code allocates an instance of `digitalocean.KubernetesCluster` and sets a number of properties on it. This includes using the `sfo2` [region slug](https://www.digitalocean.com/docs/platform/availability-matrix/), the `latest` supported version of Kubernetes, the `s-2vcpu-2gb` [Droplet size slug](https://developers.digitalocean.com/documentation/changelog/api-v2/new-size-slugs-for-droplet-plan-changes/), and states your desired count of three Droplet instances. Feel free to change any of these, but be aware that DigitalOcean Kubernetes is only available in certain regions at the time of this writing. You can refer to the [product documentation](https://www.digitalocean.com/docs/kubernetes/overview/) for updated information about region availability.

For a complete list of properties you can configure on your cluster, please refer to the [`KubernetesCluster` API documentation](https://www.pulumi.com/docs/reference/pkg/nodejs/pulumi/digitalocean/#KubernetesCluster).

The final line in that code snippet exports the resulting Kubernetes cluster’s [`kubeconfig` file](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) so that it’s easy to use. Exported variables are printed to the console and also accessible to tools. You will use this momentarily to access our cluster from standard tools like `kubectl`.

Now you’re ready to deploy your cluster. To do so, run `pulumi up`:

    pulumi up

This command takes the program, generates a plan for creating the infrastructure described, and carries out a series of steps to deploy those changes. This works for the initial creation of infrastructure in addition to being able to diff and update your infrastructure when subsequent updates are made. In this case, the output will look something like this:

    OutputPreviewing update (dev):
    
         Type Name Plan
     + pulumi:pulumi:Stack do-k8s-dev create
     + └─ digitalocean:index:KubernetesCluster do-cluster create
    
    Resources:
        + 2 to create
    
    Do you want to perform this update?
      yes
    > no
      details

This says that proceeding with the update will create a single Kubernetes cluster named `do-cluster`. The `yes/no/details` prompt allows us to confirm that this is the desired outcome before any changes are actually made. If you select `details`, a full list of resources and their properties will be shown. Choose `yes` to begin the deployment:

    OutputUpdating (dev):
    
         Type Name Status
     + pulumi:pulumi:Stack do-k8s-dev created
     + └─ digitalocean:index:KubernetesCluster do-cluster created
    
    Outputs:
        kubeconfig: "..."
    
    Resources:
        + 2 created
    
    Duration: 6m5s
    
    Permalink: https://app.pulumi.com/.../do-k8s/dev/updates/1

It takes a few minutes to create the cluster, but then it will be up and running, and the full `kubeconfig` will be printed out to the console. Save the `kubeconfig` to a file:

    pulumi stack output kubeconfig > kubeconfig.yml

And then use it with `kubectl` to perform any Kubernetes command:

    KUBECONFIG=./kubeconfig.yml kubectl get nodes

You will receive output similar to the following:

    OutputNAME STATUS ROLES AGE VERSION
    default-o4sj Ready <none> 4m5s v1.14.2
    default-o4so Ready <none> 4m3s v1.14.2
    default-o4sx Ready <none> 3m37s v1.14.2

At this point you’ve set up infrastructure-as-code and have a repeatable way to bring up and configure new DigitalOcean Kubernetes clusters. In the next step, you will build on top of this to define the Kubernetes infrastructure in code and learn how to deploy and manage them similarly.

## Step 4 — Deploying an Application to Your Cluster

Next, you will describe a Kubernetes application’s configuration using infrastructure-as-code. This will consist of three parts:

1. A `Provider` object, which tells Pulumi to deploy Kubernetes resources to the DigitalOcean cluster, rather than the default of whatever `kubectl` is configured to use.
2. A [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), which is the standard Kubernetes way of deploying a Docker container image that is replicated across any number of Pods.
3. A [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/), which is the standard way to tell Kubernetes to load balance access across a target set of Pods (in this case, the Deployment above).

This is a fairly standard _reference architecture_ for getting up and running with a load balanced service in Kubernetes.

To deploy all three of these, open your `index.ts` file again:

    nano index.ts

Once the file is open, append this code to the end of the file:

index.ts

    ...
    const provider = new kubernetes.Provider("do-k8s", { kubeconfig })
    
    const appLabels = { "app": "app-nginx" };
    const app = new kubernetes.apps.v1.Deployment("do-app-dep", {
        spec: {
            selector: { matchLabels: appLabels },
            replicas: 5,
            template: {
                metadata: { labels: appLabels },
                spec: {
                    containers: [{
                        name: "nginx",
                        image: "nginx",
                    }],
                },
            },
        },
    }, { provider });
    const appService = new kubernetes.core.v1.Service("do-app-svc", {
        spec: {
            type: "LoadBalancer",
            selector: app.spec.template.metadata.labels,
            ports: [{ port: 80 }],
        },
    }, { provider });
    
    export const ingressIp = appService.status.loadBalancer.ingress[0].ip;

This code is similar to standard Kubernetes configuration, and the behavior of objects and their properties is equivalent, except that it’s written in TypeScript alongside your other infrastructure declarations.

Save and close the file after making the changes.

Just like before, run `pulumi up` to preview and then deploy the changes:

    pulumi up

After selecting `yes` to proceed, the CLI will print out detailed status updates, including diagnostics around Pod availability, IP address allocation, and more. This will help you understand why your deployment might be taking time to complete or getting stuck.

The full output will look something like this:

    OutputUpdating (dev):
    
         Type Name Status
         pulumi:pulumi:Stack do-k8s-dev
     + ├─ pulumi:providers:kubernetes do-k8s created
     + ├─ kubernetes:apps:Deployment do-app-dep created
     + └─ kubernetes:core:Service do-app-svc created
    
    Outputs:
      + ingressIp : "157.230.199.202"
    
    Resources:
        + 3 created
        2 unchanged
    
    Duration: 2m52s
    
    Permalink: https://app.pulumi.com/.../do-k8s/dev/updates/2

After this completes, notice that the desired number of Pods are running:

    KUBECONFIG=./kubeconfig.yml kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    do-app-dep-vyf8k78z-758486ff68-5z8hk 1/1 Running 0 1m
    do-app-dep-vyf8k78z-758486ff68-8982s 1/1 Running 0 1m
    do-app-dep-vyf8k78z-758486ff68-94k7b 1/1 Running 0 1m
    do-app-dep-vyf8k78z-758486ff68-cqm4c 1/1 Running 0 1m
    do-app-dep-vyf8k78z-758486ff68-lx2d7 1/1 Running 0 1m

Similar to how the program exports the cluster’s `kubeconfig` file, this program also exports the Kubernetes service’s resulting load balancer’s IP address. Use this to `curl` the endpoint and see that it is up and running:

    curl $(pulumi stack output ingressIp)

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    
    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>
    
    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>

From here, you can easily edit and redeploy your application infrastructure. For example, try changing the `replicas: 5` line to say `replicas: 7`, and then rerun `pulumi up`:

    pulumi up

Notice that it just shows what has changed, and that selecting details displays the precise diff:

    OutputPreviewing update (dev):
    
         Type Name Plan Info
         pulumi:pulumi:Stack do-k8s-dev
     ~ └─ kubernetes:apps:Deployment do-app-dep update [diff: ~spec]
    
    Resources:
        ~ 1 to update
        4 unchanged
    
    Do you want to perform this update? details
      pulumi:pulumi:Stack: (same)
        [urn=urn:pulumi:dev::do-k8s::pulumi:pulumi:Stack::do-k8s-dev]
        ~ kubernetes:apps/v1:Deployment: (update)
            [id=default/do-app-dep-vyf8k78z]
            [urn=urn:pulumi:dev::do-k8s::kubernetes:apps/v1:Deployment::do-app-dep]
            [provider=urn:pulumi:dev::do-k8s::pulumi:providers:kubernetes::do-k8s::80f36105-337f-451f-a191-5835823df9be]
          ~ spec: {
              ~ replicas: 5 => 7
            }

Now you have both a fully functioning Kubernetes cluster and a working application. With your application up and running, you may want to configure a custom domain to use with your application. The next step will guide you through configuring DNS with Pulumi.

## Step 5 — Creating a DNS Domain (Optional)

Although the Kubernetes cluster and application are up and running, the application’s address is dependent upon the whims of automatic IP address assignment by your cluster. As you adjust and redeploy things, this address might change. In this step, you will see how to assign a custom DNS name to the load balancer IP address so that it’s stable even as you subsequently change your infrastructure.

**Note:** To complete this step, ensure you have a domain using DigitalOcean’s DNS nameservers, `ns1.digitalocean.com`, `ns2.digitalocean.com`, and `ns3.digitalocean.com`. Instructions to configure this are available in the Prerequisites section.

To configure DNS, open the `index.ts` file and append the following code to the end of the file:

index.ts

    ...
    const domain = new digitalocean.Domain("do-domain", {
        name: "your_domain",
        ipAddress: ingressIp,
    });

This code creates a new DNS entry with an A record that refers to your Kubernetes service’s IP address. Replace `your_domain` in this snippet with your chosen domain name.

It is common to want additional sub-domains, like `www`, to point at the web application. This is easy to accomplish using a DigitalOcean DNS record. To make this example more interesting, also add a `CNAME` record that points `www.your_domain.com` to `your_domain.com`:

index.ts

    ...
    const cnameRecord = new digitalocean.DnsRecord("do-domain-cname", {
        domain: domain.name,
        type: "CNAME",
        name: "www",
        value: "@",
    });

Save and close the file after making these changes.

Finally, run `pulumi up` to deploy the DNS changes to point at your existing application and cluster:

    OutputUpdating (dev):
    
         Type Name Status
         pulumi:pulumi:Stack do-k8s-dev
     + ├─ digitalocean:index:Domain do-domain created
     + └─ digitalocean:index:DnsRecord do-domain-cname created
    
    Resources:
        + 2 created
        5 unchanged
    
    Duration: 6s
    
    Permalink: https://app.pulumi.com/.../do-k8s/dev/updates/3

After the DNS changes have propagated, you will be able to access your content at your custom domain:

    curl www.your_domain.com

You will receive output similar to the following:

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    
    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>
    
    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>

With that, you have successfully set up a new DigitalOcean Kubernetes cluster, deployed a load balanced Kubernetes application to it, and given that application’s load balancer a stable domain name using DigitalOcean DNS, all in 60 lines of code and a `pulumi up` command.

The next step will guide you through removing the resources if you no longer need them.

## Step 6 — Removing the Resources (Optional)

Before concluding the tutorial, you may want to destroy all of the resources created above. This will ensure you don’t get charged for resources that aren’t being used. If you prefer to keep your application up and running, feel free to skip this step.

Run the following command to destroy the resources. Be careful using this, as it cannot be undone!

    pulumi destroy

Just as with the `up` command, `destroy` displays a preview and prompt before taking action:

    OutputPreviewing destroy (dev):
    
         Type Name Plan
     - pulumi:pulumi:Stack do-k8s-dev delete
     - ├─ digitalocean:index:DnsRecord do-domain-cname delete
     - ├─ digitalocean:index:Domain do-domain delete
     - ├─ kubernetes:core:Service do-app-svc delete
     - ├─ kubernetes:apps:Deployment do-app-dep delete
     - ├─ pulumi:providers:kubernetes do-k8s delete
     - └─ digitalocean:index:KubernetesCluster do-cluster delete
    
    Resources:
        - 7 to delete
    
    Do you want to perform this destroy?
      yes
    > no
      details

Assuming this is what you want, select `yes` and watch the deletions occur:

    OutputDestroying (dev):
    
         Type Name Status
     - pulumi:pulumi:Stack do-k8s-dev deleted
     - ├─ digitalocean:index:DnsRecord do-domain-cname deleted
     - ├─ digitalocean:index:Domain do-domain deleted
     - ├─ kubernetes:core:Service do-app-svc deleted
     - ├─ kubernetes:apps:Deployment do-app-dep deleted
     - ├─ pulumi:providers:kubernetes do-k8s deleted
     - └─ digitalocean:index:KubernetesCluster do-cluster deleted
    
    Resources:
        - 7 deleted
    
    Duration: 7s
    
    Permalink: https://app.pulumi.com/.../do-k8s/dev/updates/4

At this point, nothing remains: the DNS entries are gone and the Kubernetes cluster—along with the application running inside of it—are gone. The permalink is still available, so you can still go back and see the full history of updates for this stack. This could help you recover if the destruction was a mistake, since the service keeps full state history for all resources.

If you’d like to destroy your project in its entirety, remove the stack:

    pulumi stack rm

You will receive output asking you to confirm the deletion by typing in the stack’s name:

    OutputThis will permanently remove the 'dev' stack!
    Please confirm that this is what you'd like to do by typing ("dev"):

Unlike the destroy command, which deletes the cloud infrastructure resources, the removal of a stack erases completely the full history of your stack from Pulumi’s purview.

## Conclusion

In this tutorial, you’ve deployed DigitalOcean infrastructure resources—a Kubernetes cluster and a DNS domain with A and CNAME records—in addition to the Kubernetes application configuration that uses this cluster. You have done so using infrastructure-as-code written in a familiar programming language, TypeScript, that works with existing editors, tools, and libraries, and leverages existing communities and packages. You’ve done it all using a single command line workflow for doing deployments that span your application and infrastructure.

From here, there are a number of next steps you might take:

- [Explore the full set DigitalOcean resources supported by Pulumi.](https://www.pulumi.com/docs/reference/pkg/nodejs/pulumi/digitalocean/)
- [Explore Pulumi’s support for Kubernetes applications, including common architectures.](https://www.pulumi.com/docs/reference/clouds/kubernetes/)
- [Trigger deployments automatically with CI/CD and Git workflow integrations.](https://www.pulumi.com/docs/reference/cd/)
- [Make certain elements of your program configurable](https://www.pulumi.com/docs/reference/config/) like the [example does](https://github.com/do-community/pulumi-kubernetes), to [facilitate larger projects and multi-stack approaches](https://www.pulumi.com/docs/reference/organizing-stacks-projects/) (such as dev, test, staging, production).

The entire sample from this tutorial is [available on GitHub](https://github.com/do-community/pulumi-kubernetes). For extensive details about how to use Pulumi infrastructure-as-code in your own projects today, check out the [Pulumi Documentation](https://www.pulumi.com/docs), [Tutorials](https://www.pulumi.com/docs/reference/tutorials), or [Getting Started](https://www.pulumi.com/docs/quickstart) guides. Pulumi is open source and free to use.
