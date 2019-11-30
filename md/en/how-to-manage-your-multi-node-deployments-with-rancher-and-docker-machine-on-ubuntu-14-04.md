---
author: Usman Ismail
date: 2015-04-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-your-multi-node-deployments-with-rancher-and-docker-machine-on-ubuntu-14-04
---

# How To Manage Your Multi-Node Deployments with Rancher and Docker Machine on Ubuntu 14.04

## Introduction

Rancher recently added support for [Docker Machine](https://github.com/docker/machine)-based provisioning. Machine makes it really easy to create Docker hosts on cloud providers or inside your own data center. It creates servers, installs Docker on them, and configures the Docker client to talk to them.

Using the Machine integration in Rancher, we can launch compute nodes directly from the Rancher UI. This is a small but critical step in being able to create and manage multi-node — and in the future, multi-cloud — deployments from a single interface.

The [DigitalOcean Driver](https://github.com/docker/machine/tree/master/drivers/digitalocean) is the first to be integrated by Rancher and this tutorial will show you how to launch Droplets from the Rancher UI and provision them to run Docker compute hosts (which can, in turn, be used to run Docker containers).

## Prerequisites

To follow this tutorial, you will need:

- A DigitalOcean Personal Access Token for the API, which you can create by following the instructions in [this tutorial](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token).

- One 1GB Ubuntu 14.04 Droplet with the Docker 1.6.0 image.

You can find the Docker 1.6.0 image option on the Droplet creation page, in the **Applications** tab under **Select Image**. This Droplet will also requires custom user data. To add this, click **Enable User Data** in the **Available Settings** section, and enter the script below in the text box that appears. This script tells the Droplet to run a Rancher server upon start-up.

    #!/bin/bash
    docker run -d --name rancher-server -p 80:8080 rancher/server

## Step 1 — Configuring Authentication

After about a minute, your host should be ready and you can browse to `http://your_server_ip/` and bring up the Rancher UI. Because the Rancher server is currently open to the Internet, it’s a good idea to set up authentication. In this step, we will set up Github OAuth based authentication.

You will see a warning on the top of the screen which says **Access Control is not configured** followed by a link to **Settings**. Click **Settings** and follow the instructions given there to register a new Application with GitHub, and copy the Client ID and Secret into the respective text fields.

When you finish, click **Authenticate with GitHub** , then **Authorize application** in the window that pops up. Once you do, the page will reload, and the instructions on setting up OAuth will be replaced by the **Configure Authorization** section. Add any additional users and organizations that should be given access to Rancher. If you make any changes, a button that reads **Save authorization configuration** will appear. Click it when you’re done.

Once you save the authorization configuration, the warning in the top should be replaced by your GitHub profile image and a project selection menu (which says **Default** initially). Click **Default** to open the project selection menu, then click **Manage Projects** , and finally **+ Add a project**. Fill in a name for your choice and choose yourself as the owner in the widow that pops up, and click **Create**. Then use the project selection menu again to select it.

All compute nodes we add will be contained in this project. You may create multiple projects to group compute nodes into logical sets.

## Step 2 — Launching Rancher Compute Nodes

In this step, we will launch some Rancher compute nodes.

Once you have secured your Rancher deployment and added a project, click on the **+Add Host** button in order to launch a Rancher compute node.

If this is the first time launching a host, you will see a pop-up screen asking you to confirm the IP address your Rancher server is available on, i.e. where the compute nodes will connect. On DigitalOcean, you can leave the pre-configured IP selected and click **Save**. However, if you had launched your Rancher Server beind a proxy, you will need to update the Rancher Server IP to the IP and port of your proxy server.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_machine/hIX9cr6.png)

In the **Add Host** screen you will see three providers: DigitalOcean, Amazon EC2, and custom. The first two are used to launch compute nodes on the respective cloud systems and the third lists the command used to manually launch a Rancher compute node on a server with Docker pre-installed.

Select the DigitalOcean icon. You will see a screen (shown below) with a number of fields for you to fill out.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_machine/xvzKhPj.png)

Fill in the following details:

- **Server Name** : Anything you like.
- **Description** : Anything you like, optional.
- **Access Token** : Your Personal Access Token for the DigitalOcean API, from the prerequisites section.
- **Image** : The image you want to launch, which should be **ubuntu-14-04-x64**.
- **Size** : The size of the Droplet. In our case, **1gb**.
- **Region** : The region where your Droplet will be created. Choose one geographically close to you.

Finally, hit **Create**. Rancher will use Docker Machine to create the specified Droplet and install Docker on it. Rancher will also run the rancher-agent on the newly created Droplet, which will in turn register with the Rancher server.

Within a few minutes your should see your compute node in the Rancher UI. You will also get some basic information about the nodes such as their IP address, processor clock-speed, memory, and storage. You can repeat this step as many times as you need to launch more compute nodes into your deployment.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_machine/UkDaglV.png)

## Step 3 — Monitoring and Scaling Your Deployment

In this step, we will explore the built-in monitoring for your compute nodes, and show how to deactive and delete notes.

Once your compute nodes are provisioned, click on the name of one of your nodes to pull up the Monitoring screen. Here you will be able to see the CPU utilization and memory consumption of that compute node. If you see that you are using most of the memory or if your CPU is running continuously hot, you may want to launch more nodes to reduce container density.

For example, our compute node below seems to be using 80% of its memory, so we may want to launch more nodes to spread the load. This is where the Machine integration is really useful. Without leaving the Docker UI, you can react quickly to load spikes by provisioning more compute nodes.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_machine/q2xAGbV.png)

Once the spikes abate, you can shut down the nodes by clicking the details icon (the circle with three horizontal lines next to **Host** and the host name, pictured below) and selecting **Deactivate**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_machine/xMFGTYn.png)

You can then subsequently click either **Activate** or **Delete** from the same menu, for deactivated nodes you wish to spin back up or that are no longer needed, respectively.

## Conclusion

Now you’ve learned how to launch, monitor, and terminate compute nodes using the Rancher Docker Machine integration with native DigitalOcean driver support. Enjoy!
