---
author: Brian Hogan
date: 2017-01-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-multi-node-deployments-with-rancher-and-docker-machine-on-ubuntu-16-04
---

# How To Manage Multi-Node Deployments with Rancher and Docker Machine on Ubuntu 16.04

## Introduction

Rancher supports [Docker Machine](https://github.com/docker/machine)-based provisioning, which makes it easy to create Docker hosts on cloud providers, or inside your own data center. With Rancher, you can launch compute nodes directly from the Rancher UI, which is a small but critical step in being able to create and manage multi-node — and in the future, multi-cloud — deployments from a single interface.

In this tutorial, you’ll use the [DigitalOcean driver](https://github.com/docker/machine/tree/master/drivers/digitalocean) that’s built into Rancher to create Droplets from the Rancher UI and provision them to run Docker compute hosts which you can monitor, scale, and use to deploy Docker containers.

## Prerequisites

To follow this tutorial, you will need:

- A DigitalOcean Personal Access Token for the API, which you can create by following the instructions in [this tutorial](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token).
- A [GitHub](http://github.com) account, which you’ll use to configure user authentication for Rancher.

## Step 1 — Creating a Droplet to Host Rancher

In order to use Rancher to manage Docker hosts and containers, we need to get Rancher running. We’ll use DigitalOcean’s Docker image and a bit of **User Data** to get up and running quickly.

First, log into your DigitalOcean account and choose **Create Droplet**. Then, under the **Choose an Image** section, select the **One-click Apps** tag. Select the **Docker 18.06.1~ce~3 on 18.04** image.

![Docker image](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/CPDKRVERS.png)

Next, select a **1GB** Droplet and choose a datacenter region for your Droplet.

Then select **User Data** in the **Select additional options** section, and enter the script below in the text box that appears. This script tells the Droplet to fetch the `rancher/server` Docker image and start a Rancher server in a container upon start-up.

    #!/bin/bash
    docker run -d --name rancher-server -p 80:8080 rancher/server

Finally, add your SSH keys, provide a host name for your Droplet, and press the **Create** button. Then wait while your new server is created. Once the server starts, Docker will download a Rancher image and start the Rancher server, which may take a few more minutes.

To double-check that Rancher is running, log in to your new Droplet:

    ssh root@your_ip_address

Once logged in, get a list of running Docker containers:

    docker ps

You’ll see the following, which confirms Rancher is running:

    Outputec5492f1b628 rancher/server "/usr/bin/entry /usr/" 15 seconds ago Up 13 seconds 3306/tcp, 0.0.0.0:80->8080/tcp rancher-server
    

If you don’t see this, wait a few minutes and try again. Once you verify that Rancher is running, you can log out of the machine.

## Step 2 — Configuring Authentication for Rancher

Once your server is up, browse to `http://your_server_ip/` to bring up the Rancher UI. Because the Rancher server is currently open to the internet, it’s a good idea to set up authentication so the public can’t make changes to our environment. Let’s configure Rancher to use Github OAuth-based authentication.

You will see a warning icon next to the **ADMIN** menu item at the top of the screen .

![Access control is not configured](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/Wxi8mXw.png)

If you hover over this link, you’ll see the message **Access Control is not configured**. Choose **Access Control** from the **ADMIN** menu. Github will be selected as the default authentication method, so follow the instructions on the page to register a new application with GitHub.

Once you’ve registered the application, copy the **Client ID** and **Client Secret** from the application page on Github into the respective text fields in the Rancher user interface. Then click **Save**.

Then, under **Test and enable authentication** , click **Authenticate with GitHub** , and click **Authorize application** in the window that pops up. The page will reload and the instructions on setting up OAuth will be replaced by the **Configure Authorization** section. Add any additional users and organizations that should be given access to Rancher. If you make any changes, click the **Save** button.

Next, let’s create an _environment_ to organize our compute hosts.

## Step 3 — Creating an Environment

An environment in Rancher lets us group our hosts into logical sets. Rancher provides an environment called **Default** , but let’s create our own. Click the **Default** link at the top of the screen to reveal the **Environments** menu, then click **Manage Environments**. Click the **Add Environment** button that appears on the page.

Fill in a name and a description for your project. Leave all of the other settings at their defaults and click **Create**. Then use the project selection menu again to select your new environment.

Now let’s launch some hosts in this new environment.

## Step 4 — Launching Rancher Compute Nodes

Once you have secured your Rancher deployment and added a project, select **Hosts** from the **Infrastructure** menu and then click the **Add Host** button.

On the **Add Host** screen, you will see several providers: **Custom** , **Amazon EC2** , **DigitalOcean** , **Azure** , and **Packet**. The **Custom** option lists the steps to manually launch a Rancher compute node on a server with Docker pre-installed. The others are used to launch compute nodes on the respective cloud systems.

Select the **DigitalOcean** option, as shown in the following figure:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/qmd0amx.png)

In the **Access Token** field, place your Personal Access Token for the DigitalOcean API, which you obtained from the prerequisites section. Then press **Next: Configure Droplet**.

A new set of fields will appear on the screen. Fill in the following details:

- **Name** : The name of the server you want to create. In this case, enter `host01`.
- **Quantity** : Leave this at `1`. Increasing this will create multiple hosts and automatically name each one for you.
- **Image** : Select the **Ubuntu 16.04.1 x64** are disabled because they are not compatible with Rancher.
- **Size** : The size of the Droplet. Select the option for a **1GB** Droplet.
- **Region** : The region where your Droplet will be created. Choose one geographically close to you.

Finally, click **Create**. Rancher will use Docker Machine to create the specified Droplet and install Docker on it. Rancher will also run `rancher-agent` on the newly created Droplet, which will in turn register with the Rancher server.

Within a few minutes you’ll see your new host in the Rancher UI. You will also get some basic information about the host such as its IP address, processor clock-speed, memory, and storage.

![Your newly created host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/GURVRo3.png)

You can repeat this step as many times as you need to launch more compute nodes into your deployment. Now let’s explore Rancher’s built-in monitoring, and how to deactive and delete notes.

## Step 5 — Monitoring and Scaling Your Deployment

Once your compute nodes are provisioned, click on the name of one of your hosts to pull up the Monitoring screen, where you can see the CPU utilization and memory consumption of that compute node.

![CPU and memory consumption for your host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/Rk1Uw56.png)

If you see that you are using most of the memory or if your CPU is running continuously hot, you may want to launch more nodes to reduce container density and spread out the load. This is where the `docker-machine` integration is really useful; you can react quickly to load spikes by provisioning more compute nodes right from Rancher’s UI.

Once the spikes abate, you can shut down any additional nodes by visiting the **Hosts** page, locating your host, and clicking the **Deactivate** icon (the box with two vertical lines), as shown in the following figure:

![Deactivating a host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rancher_1604/anwmwoT.png)

You can then subsequently click either **Activate** or **Delete** from the menu to the right of the **Deactivate** button.

## Conclusion

You now know how to launch, monitor, and deactivate compute nodes using Rancher and its integration with native DigitalOcean driver support. From here, you can explore [how to use Rancher as a load balancer](http://docs.rancher.com/rancher/v1.1/en/cattle/adding-load-balancers/).
