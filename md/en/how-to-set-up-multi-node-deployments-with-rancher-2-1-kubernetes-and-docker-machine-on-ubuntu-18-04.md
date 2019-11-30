---
author: Karl Hughes
date: 2019-01-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-node-deployments-with-rancher-2-1-kubernetes-and-docker-machine-on-ubuntu-18-04
---

# How To Set Up Multi-Node Deployments With Rancher 2.1, Kubernetes, and Docker Machine on Ubuntu 18.04

_The author selected [Code Org](https://www.brightfunds.org/organizations/code-org) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Rancher](https://rancher.com/) is a popular open-source container management platform. Released in early 2018, Rancher 2.X works on [Kubernetes](https://kubernetes.io/) and has incorporated new tools such as multi-cluster management and built-in CI pipelines. In addition to the enhanced security, scalability, and straightforward deployment tools already in Kubernetes, Rancher offers a graphical user interface that makes managing containers easier. Through Rancher’s GUI, users can manage secrets, securely handle roles and permissions, scale nodes and pods, and set up load balancers and volumes without needing a command line tool or complex YAML files.

In this tutorial, you will deploy a multi-node Rancher 2.1 server using Docker Machine on Ubuntu 18.04. By the end, you’ll be able to provision new DigitalOcean Droplets and container pods via the Rancher UI to quickly scale up or down your hosting environment.

## Prerequisites

Before you start this tutorial, [you’ll need a DigitalOcean account](https://cloud.digitalocean.com/registrations/new), in addition to the following:

- A DigitalOcean Personal Access Token, which you can create following the instructions in [this tutorial](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token). This token will allow Rancher to have API access to your DigitalOcean account.

- A fully registered domain name with an A record that points to the IP address of the Droplet you create in Step 1. You can learn how to point domains to DigitalOcean Droplets by reading through DigitalOcean’s [Domains and DNS documentation](https://www.digitalocean.com/docs/networking/dns/). Throughout this tutorial, substitute your domain for `example.com`.

## Step 1 — Creating a Droplet With Docker Installed

To start and configure Rancher, you’ll need to create a new Droplet with Docker installed. To accomplish this, you can use DigitalOcean’s Docker image.

First, log in to your DigitalOcean account and choose **Create Droplet**. Then, under the **Choose an Image** section, select the **Marketplace** tab. Select **Docker 18.06.1~ce~3 on 18.04**.

![Choose the Docker 18.06 image from the One-click Apps menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step1a.png)

Next, select a Droplet no smaller than **2GB** and choose a datacenter region for your Droplet.

Finally, add your SSH keys, provide a host name for your Droplet, and press the **Create** button.

It will take a few minutes for the server to provision and for Docker to download. Once the Droplet deploys successfully, you’re ready to start Rancher in a new Docker container.

## Step 2 — Starting and Configuring Rancher

The Droplet you created in Step 1 will run Rancher in a Docker container. In this step, you will start the Rancher container and ensure it has a [Let’s Encrypt](https://letsencrypt.org/) SSL certificate so that you can securely access the Rancher admin panel. Let’s Encrypt is an automated, open-source certificate authority that allows developers to provision ninety-day SSL certificates for free.

Log in to your new Droplet:

    ssh root@your_server_ip

To make sure Docker is running, enter:

    docker -v

Check that the listed Docker version is what you expect. You can start Rancher with a [Let’s Encrypt certificate already installed](https://rancher.com/docs/rancher/v2.x/en/installation/single-node/#2-choose-an-ssl-option-and-install-rancher) by running the following command:

    docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /host/rancher:/var/lib/rancher rancher/rancher --acme-domain example.com

The `--acme-domain` option installs an SSL certificate from Let’s Encrypt to ensure your Rancher admin is served over HTTPS. This script also instructs the Droplet to fetch the [`rancher/rancher` Docker image](https://hub.docker.com/r/rancher/rancher/) and start a Rancher instance in a container that will restart automatically if it ever goes down accidentally. To ease recovery in the event of data loss, the script mounts a volume on the host machine (at `/host/rancher`) that contains the Rancher data.

To see all the running containers, enter:

    docker ps

You’ll see output similar to the following (with a unique container ID and name):

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    7b2afed0a599 rancher/rancher "entrypoint.sh" 12 seconds ago Up 11 seconds 0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp wizardly_fermat

If the container is not running, you can execute the `docker run` command again.

Before you can access the Rancher admin panel, you’ll need to set your admin password and Rancher server URL. The Rancher admin interface will give you access to all of your running nodes, pods, and secrets, so it is important that you use a strong password for it.

Go to the domain name that points to your new Droplet in your web browser. The first time you visit this address, Rancher will let you set a password:

![Set your Rancher password using the prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step3a.png)

When asked for your **Rancher server URL** , use the domain name pointed at your Droplet.

You have now completed your Rancher server setup, and you will see the Rancher admin home screen:

![The Rancher admin home screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step3b.png)

You’re ready to continue to the Rancher cluster setup.

## Step 3 — Configuring a Cluster With a Single Node

To use Rancher, you’ll need to create a _cluster_ with at least one _node_. A cluster is a group of one or more nodes. [This guide](an-introduction-to-kubernetes) will give you more information about the Kubernetes Architecture. In this tutorial, nodes correspond to Droplets that Rancher will manage. _Pods_ represent a group of running Docker containers within the Droplet. Each node can run many pods. Using the Rancher UI, you can set up clusters and nodes in an underlying Kubernetes environment.

By the end of this step, you will have set up a cluster with a single node ready to run your first pod.

In Rancher, click **Add Cluster** , and select **DigitalOcean** as the **infrastructure provider**.

![Select DigitalOcean from the listed infrastructure providers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step4a.png)

Enter a **Cluster Name** and scroll down to the **Node Pools** section. Enter a **Name Prefix** , leave the **Count** at **1** for now, and check **etcd** , **Control Plane** , and **Worker**.

- **[etcd](https://kubernetes.io/docs/concepts/overview/components/#etcd)** is Kubernetes’ key value storage system for keeping your entire environment’s state. In order to maintain high availability, you should run three or five etcd nodes so that if one goes down your environment will still be manageable.
- **[Control Plane](https://kubernetes.io/docs/concepts/#kubernetes-control-plane)** checks through all of the Kubernetes Objects — such as pods — in your environment and keeps them up to date with the configuration you provide in the Rancher admin interface.
- **[Workers](https://kubernetes.io/docs/concepts/architecture/nodes/)** run the actual workloads and monitoring agents that ensure your containers stay running and networked. Worker nodes are where your pods will run the software you deploy.

![Create a Node Pool with a single Node](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step4b.png)

Before creating the cluster, click **Add Node Template** to configure the specific options for your new node.

Enter your DigitalOcean Personal Access Token in the **Access Token** input box and click **Next: Configure Droplet**.

Next, select the same **Region** and **Droplet Size** as Step 1. For **Image** , be sure to select **Ubuntu 16.04.5 x64** as there’s currently [a compatibility issue with Rancher and Ubuntu 18.04](https://github.com/rancher/rancher/issues/13888). Hit **Create** to save the template.

Finally, click **Create** at the **Add Cluster** page to kick off the provisioning process. It will take a few minutes for Rancher to complete this step, but you will see a new Droplet in your [DigitalOcean Droplets dashboard](https://cloud.digitalocean.com/droplets) when it’s done.

In this step, you’ve created a new cluster and node onto which you will deploy a workload in the next section.

## Step 4 — Deploying a Web Application Workload

Once the new cluster and node are ready, you can deploy your first _pod_ in a _workload_. A [Kubernetes Pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) is the smallest unit of work available to Kubernetes and by extension Rancher. Workloads describe a single group of pods that you deploy together. For example, you may run multiple pods of your webserver in a single workload to ensure that if one pod slows down with a particular request, other instances can handle incoming requests. In this section, you’re going to deploy a [Nginx Hello World image](https://hub.docker.com/r/nginxdemos/hello/) to a single pod.

Hover over **Global** in the header and select **Default**. This will bring you to the **Default** project dashboard. You’ll focus on deploying a single project in this tutorial, but from this dashboard you can also create multiple projects to achieve isolated container hosting environments.

To start configuring your first pod, click **Deploy**.

Enter a **Name** , and put `nginxdemos/hello` in the **Docker Image** field. Next, map port **80** in the container to port **30000** on the host nodes. This will ensure that the pods you deploy are available on each node at port 30000. You can leave **Protocol** set to **TCP** , and the next dropdown as **NodePort**.

**Note:** While this method of running the pod on every node’s port is easier to get started, Rancher also includes [Ingress](https://rancher.com/docs/rancher/v2.x/en/k8s-in-rancher/load-balancers-and-ingress/ingress/) to provide load balancing and SSL termination for production use.

![The input form for deploying a Workload](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step5b.png)

To launch the pod, scroll to the bottom and click **Launch**.

Rancher will take you back to the default project home page, and within a few seconds your pod will be ready. Click the link **30000/tcp** just below the name of the workload and Rancher will open a new tab with information about the running container’s environment.

![Server address, Server name, and other output from the running NGINX container](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step5c.png)

The **Server address** and port you see on this page are those of the internal Docker network, and not the public IP address you see in your browser. This means that Rancher is working and routing traffic from `http://first_node_ip:30000/` to the workload as expected.

At this point, you’ve successfully deployed your first workload of one pod to a single Rancher node. Next, you’ll see how to scale your Rancher environment.

## Step 5 — Scaling Nodes and Pods

Rancher gives you two ways to scale your hosting resources: increasing the number of pods in your workload or increasing the number of nodes in your cluster.

Adding pods to your workload will give your application more running processes. This will allow it to handle more traffic and enable zero-downtime deployments, but each node can handle only a finite number of pods. Once all your nodes have hit their pod limit, you will have to increase the number of nodes if you want to continue scaling up.

Another consideration is that while increasing pods is typically free, you will have to pay for each node you add to your environment. In this step, you will scale up both nodes and pods, and add another node to your Rancher cluster.

**Note:** This part of the tutorial will provision a new DigitalOcean Droplet automatically via the API, so be aware that you will incur extra charges while the second node is running.

Navigate to the cluster home page of your Rancher installation by selecting **Cluster: your-cluster-name** from the top navigation bar. Next click **Nodes** from the top navigation bar.

![Use the top navbar dropdown to select your Cluster](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step6a.png)

This page shows that you currently have one running node in the cluster. To add more nodes, click **Edit Cluster** , and scroll to the **Node Pools** section at the bottom of the page. Click **Add Node Pool** , enter a prefix, and check the **Worker** box. Click **Save** to update the cluster.

![Add a Node Pool as a Worker only](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step6b.png)

Within 2–5 minutes, Rancher will provision a second droplet and indicate the node as **Active** in the cluster’s dashboard. This second node is only a worker, which means it will not run the Rancher etcd or Control Plane containers. This allows the Worker more capacity for running workloads.

**Note:** Having an uneven number of etcd nodes will ensure that they can always reach a quorum (or consensus). If you only have one etcd node, you run the risk of your cluster being unreachable if that one node goes down. In a production environment it is a better practice to run three or five etcd nodes.

When the second node is ready, you will be able to see the workload you deployed in the previous step on this node by navigating to `http://second_node_ip:30000/` in your browser.

Scaling up nodes gives you more Droplets to distribute your workloads on, but you may also want to run more instances of each pod within a workload. To add more pods, return to the **Default** project page, press the arrow to the left of your `hello-world` workload, and click **+** twice to add two more pods.

![Running three Hello World Pods in a Workload](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/multirancher_1804/step6c.png)

Rancher will automatically deploy more pods and distribute the running containers to each node depending on where there is availability.

You can now scale your nodes and pods to suit your application’s requirements.

## Conclusion

You’ve now set up multi-node deployments using Rancher 2.1 on Ubuntu 18.04, and have scaled up to two running nodes and multiple pods within a workload. You can use this strategy to host and scale any kind of Docker container that you need to run in your application and use Rancher’s dashboard and alerts to help you maximize the performance of your workloads and nodes within each cluster.
