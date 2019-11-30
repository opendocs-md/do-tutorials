---
author: Janakiram MSV
date: 2018-01-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/webinar-series-getting-started-with-kubernetes
---

# Webinar Series: Getting Started with Kubernetes

This article supplements a [webinar series on deploying and managing containerized workloads in the cloud](https://go.digitalocean.com/containers-and-microservices-webinars-series). The series covers the essentials of containers, including managing container lifecycles, deploying multi-container applications, scaling workloads, and working with Kubernetes. It also highlights best practices for running stateful applications.

This tutorial includes the concepts and commands in the third session of the series, Getting Started with Kubernetes.

<iframe width="854" height="480" src="//www.youtube.com/embed/o0SXHuv2CVw?rel=0" frameborder="0" allowfullscreen></iframe>

## Introduction

In the [previous tutorial in this series](webinar-series-building-containerized-applications), we explored managing multi-container applications with Docker Compose. While the Docker Command Line Interface (CLI) and Docker Compose can deploy and scale containers running on a single machine, [Kubernetes](https://kubernetes.io/) is designed to handle multi-container applications deployed across multiple machines or hosts.

Kubernetes is an open-source container orchestration tool for managing containerized applications. A Kubernetes _cluster_ has two key components: _Master Nodes_ and _Worker Nodes_. A set of Master Nodes act as the control plane that manage the Worker Nodes and deployed applications. The Worker Nodes are the workhorses of a Kubernetes cluster that are responsible for running the containerized applications.

The Master Nodes expose an API through which the command-line tools and rich clients submit a _job_, which contains the definition of an application. Each application consists of one or more _containers_, the storage definitions and the internal and external ports through which they are exposed. The control plane running on Master Nodes schedules the containers in one of the Worker Nodes. When an application is scaled, the control plane launches additional containers on any of the available Worker Nodes.

For a detailed introduction to Kubernetes, refer to the tutorial [An Introduction to Kubernetes](an-introduction-to-kubernetes).

[StackPointCloud](https://stackpoint.io) deploys a Kubernetes cluster in three steps using a web-based interface. It hides the complexity of installing and configuring Kubernetes through a simplified user experience. DigitalOcean is one of StackPoint’s supported cloud platforms. Developers who are not familiar with systems administration and configuration can use StackPoint to install Kubernetes on DigitalOcean quickly. For details on the supported features and pricing, refer to their site.

In this tutorial, you’ll set up and configure Kubernetes on DigitalOcean through StackPoint and deploy a containerized application to your cluster.

## Prerequisites

To follow this tutorial, you will need

- A local machine with the `curl` command installed, which you’ll use to download a command-line tool to manage your Kubernetes cluster. The `curl` command is already installed on macOS and Ubuntu 16.04.
- A DigitalOcean account. In this tutorial, you’ll use StackPoint to connect to your DigitalOcean account and provision three 1GB Droplets.

## Step 1 – Installing Kubernetes

To start the installation of Kubernetes on DigitalOcean, visit [Stackpoint.io](https://stackpoint.io/) and click on the Login button.

![The StackPoint web page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/0ZKPzXu.png)

This takes you to a page where you can choose an identity provider and log in with existing credentials. Choose DigitalOcean from the list and log in with your DigitalOcean username and password.

![Choosing a Provider](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/vGNs8Fb.png)

On the next page, choose DigitalOcean from the list of available cloud platforms.

![Select the DigitalOcean provider](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/PLSX1LC.png)

You can now configure the cluster. Click on the EDIT button to edit the settings for the DigitalOcean provider:

![DigitalOcean provider overview](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/KwGSvAH.png)

This takes you to the Configure Provider screen.

![DigitalOcean provider configuration page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/1UL1uRg.png)

Choose a region of your choice from the **Region** dropdown list. You can leave the other settings at their default values. Click on **Submit** when you are done.

On the next screen, enter a cluster name of your choice and click **Submit**.

![Enter the cluster name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/tjZ7EM4.png)

The cluster installation will now start and you’ll be taken to a page where you can track the cluster’s progress. The installation will take about 15 minutes.

![The status of your cluster](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/LlfpVjS.png)

Once the cluster is configured, we can set up a command-line tool to work with it.

## Step 2 – Configuring the Kubernetes CLI

To talk to the Kubernetes cluster running in DigitalOcean, we need a command line tool in our development machine. We’ll use `kubectl`, the CLI for Kubernetes.

Run the following commands to install `kubectl` from Google’s servers:

    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/darwin/amd64/kubectl

You’ll see this output:

    Output % Total % Received % Xferd Average Speed Time Time Time Current
                                    Dload Upload Total Spent Left Speed
    
    100 63.7M 100 63.7M 0 0 5441k 0 0:00:12 0:00:12 --:--:-- 4644k

The `kubectl` binary was downloaded to your current directory, Let’s change the permissions of the downloaded binary and move it to the `/usr/local/bin` directory so we can run it from anywhere:

    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl

Now let’s point the `kubectl` app at our Kubernetes cluster. For that, we need to download a configuration file from Stackpoint. Return to the cluster status page in your browser. After verifying that the cluster is ready and stable, click on the cluster name as shown in the following figure:

![The cluster name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/h84fVAg.png)

Click on the **kubeconfig** link in the left-hand menu to download the configuration file to your local machine:

![img](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/xwSsvWo.png)

Back in your terminal, set the environment variable `KUBECONFIG` to the path of the downloaded file. Assuming your file downloaded to the `Downloads` folder in your home directory, you’d issue this command:

    export KUBECONFIG=~/Downloads/kubeconfig

With `kubectl` configured, let’s make sure we can communicate with our cluster.

## Step 3 – Verifying the Kubernetes Installation

Now that we have the fully configured cluster along with the client, let’s run a few commands to verify the environment.

Run the following command to get information about the cluster.

    kubectl cluster-info

You’ll see this output:

    OutputKubernetes master is running at https://139.59.17.180:6443
    
    Heapster is running at https://139.59.17.180:6443/api/v1/namespaces/kube-system/services/heapster/proxy
    
    KubeDNS is running at https://139.59.17.180:6443/api/v1/namespaces/kube-system/services/kube-dns/proxy
    
    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

The output confirms that the cluster is working and that the Kubernetes Master Nodes are up and running.

Next, let’s verify the health of all the components running in the Master Nodes. If the cluster is just configured, it may take a while before all the components show a healthy status. These components are a part of the Kubernetes Master Nodes that act as the control plane.

Execute this command:

    kubectl get cs

You’ll see this output:

    OutputNAME STATUS MESSAGE ERROR
    scheduler Healthy ok
    controller-manager Healthy ok
    etcd-0 Healthy {"health": "true"}

Finally, let’s list all the nodes of the running Kubernetes cluster.

    kubectl get nodes

You’ll see output like this:

    OutputNAME STATUS ROLES AGE VERSION
    spc52y2mk3-master-1 Ready master 29m v1.8.5
    spc52y2mk3-worker-1 Ready <none> 22m v1.8.5
    spc52y2mk3-worker-2 Ready <none> 22m v1.8.5

This confirms that the cluster with one Master Node and two Worker Nodes is ready for us to deploy applications. So let’s deploy an application to the cluster.

## Step 4 – Deploying and Accessing an Application

Let’s launch a simple Nginx web server and access its default web page from our local machine. Execute this command to pull the [Nginx image](https://hub.docker.com/_/nginx/) from [Docker Hub](https://hub.docker.com/) and create a deployment called `myweb`:

    kubectl run --image=nginx:latest myweb

This command is similar to the `docker run` command, except that it packages and deploys the container in a Kubernetes-specific artifact called a _Pod_. You’ll learn more about Pods in the next part of this series.

When you execute the command, you’ll see this output:

    Outputdeployment "myweb" created

Now check that the Pod is created with the `nginx` container:

    kubectl get pods

You’ll see this output:

    OutputNAME READY STATUS RESTARTS AGE
    myweb-59d7488cb9-jvnwn 1/1 Running 0 3m

To access the web server running inside the Pod, we need to expose it to the public Internet. We achieve that with the following command:

    kubectl expose pod myweb-59d7488cb9-jvnwn --port=80 --target-port=80 --type=NodePort

    Outputservice "myweb-59d7488cb9-jvnwn" exposed

The Pod is now exposed on every Node of the cluster on an arbitrary port. The `--port` and `--target-port` switches indicate the ports through which the web server becomes available. The switch `--NodePort`ensures that we can use any Node on the cluster to access the application.

To get the NodePort of the `myweb` deployment, run the following command.

    kubectl get svc myweb-59d7488cb9-jvnwn

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    myweb-59d7488cb9-jvnwn NodePort 10.3.0.119 <none> 80:31930/TCP 6m

In this case, the NodePort is port `31930`. Every Worker Node uses this port to respond to HTTP requests. Let’s test it out.

Use the DigitalOcean Console to get the IP address of one of the Worker Nodes.

![Droplets](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webinar_3_kubernetes_stackpoint/w9acP7y.png)

Use the `curl` command to make an HTTP request to one of the nodes on port `31930`.

    curl http://your_worker_1_ip_address:31930/

You’ll see the response containing the Nginx default home page:

    Output<!DOCTYPE html>
    <html>
      <head>
        <title>Welcome to nginx!</title>
    ...
         Commercial support is available at
         <a href="http://nginx.com/">nginx.com</a>.</p>
        <p><em>Thank you for using nginx.</em></p>
      </body>
    </html>

You have successfully deployed a containerized application to your Kubernetes cluster.

## Conclusion

Kubernetes is a popular container management platform. StackPoint makes it easy to install Kubernetes on DigitalOcean.

In the next part of this series, we will explore the building blocks of Kubernetes in more detail.
