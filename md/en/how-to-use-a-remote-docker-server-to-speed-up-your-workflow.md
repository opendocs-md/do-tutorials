---
author: Kamal Nasser
date: 2019-06-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-a-remote-docker-server-to-speed-up-your-workflow
---

# How to Use a Remote Docker Server to Speed Up Your Workflow

## Introduction

Building CPU-intensive images and binaries is a very slow and time-consuming process that can turn your laptop into a space heater at times. Pushing Docker images on a slow connection takes a long time, too. Luckily, there’s an easy fix for these issues. Docker lets you offload all those tasks to a remote server so your local machine doesn’t have to do that hard work.

This feature was introduced in Docker 18.09. It brings support for connecting to a Docker host remotely via SSH. It requires very little configuration on the client, and only needs a regular Docker server without any special config running on a remote machine. Prior to Docker 18.09, you had to use Docker Machine to create a remote Docker server and then configure the local Docker environment to use it. This new method removes that additional complexity.

In this tutorial, you’ll create a Droplet to host the remote Docker server and configure the `docker` command on your local machine to use it.

## Prerequisites

To follow this tutorial, you’ll need:

- A DigitalOcean account. You can [create an account](https://cloud.digitalocean.com/registrations/new) if you don’t have one already.
- [Docker](https://www.docker.com/) installed on your local machine or development server. If you are working with Ubuntu 18.04, follow Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04); otherwise, follow the [official documentation](https://docs.docker.com/install/) for information about installing on other operating systems. Be sure to add your non-root user to the `docker` group, as described in Step 2 of the linked tutorial.

## Step 1 – Creating the Docker Host

To get started, spin up a Droplet with a decent amount of processing power. The CPU Optimized plans are perfect for this purpose, but Standard ones work just as well. If you will be compiling resource-intensive programs, the CPU Optimized plans provide dedicated CPU cores which allow for faster builds. Otherwise, the Standard plans offer a more balanced CPU to RAM ratio.

The [Docker One-click image](https://marketplace.digitalocean.com/apps/docker) takes care of all of the setup for us. [Follow this link](https://cloud.digitalocean.com/droplets/new?size=c-8-16gib&image=docker-18-04) to create a 16GB/8vCPU CPU-Optimized Droplet with Docker from the control panel.

Alternatively, you can use `doctl` to create the Droplet from your local command line. To install it, follow the instructions in the [doctl README file on GitHub](https://github.com/digitalocean/doctl/blob/master/README.md).

The following command creates a new 16GB/8vCPU CPU-Optimized Droplet in the FRA1 region based on the Docker One-click image:

    doctl compute droplet create docker-host \
        --image docker-18-04 \
        --region fra1 \
        --size c-8 \
        --wait \
        --ssh-keys $(doctl compute ssh-key list --format ID --no-header | sed 's/$/,/' | tr -d '\n' | sed 's/,$//')

The `doctl` command uses the `ssh-keys` value to specify which SSH keys it should apply to your new Droplet. We use a subshell to call `doctl compute ssh-key-list` to retrieve the SSH keys associated with your DigitalOcean account, and then parse the results using the `sed` and `tr` commands to format the data in the correct format. This command includes all of your account’s SSH keys, but you can replace the highlighted subcommand with the fingerprint of any key you have in your account.

Once the Droplet is created you’ll see its IP address among other details:

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags Features Volumes
    148681562 docker-host your_server_ip 16384 8 100 fra1 Ubuntu Docker 5:18.09.6~3 on 18.04 active
    

You can learn more about using the `doctl` command in the tutorial [How To Use doctl, the Official DigitalOcean Command-Line Client](how-to-use-doctl-the-official-digitalocean-command-line-client).

When the Droplet is created, you’ll have a ready to use Docker server. For security purposes, create a Linux user to use instead of **root**.

First, connect to the Droplet with SSH as the **root** user:

    ssh root@your_server_ip

Once connected, add a new user. This command adds one named **sammy** :

    adduser sammy

Then add the user to the **docker** group to give it permission to run commands on the Docker host.

    sudo usermod -aG docker sammy

Finally, exit from the remote server by typing `exit`.

Now that the server is ready, let’s configure the local `docker` command to use it.

## Step 2 – Configuring Docker to Use the Remote Host

To use the remote host as your Docker host instead of your local machine, set the `DOCKER_HOST` environment variable to point to the remote host. This variable will instruct the Docker CLI client to connect to the remote server.

    export DOCKER_HOST=ssh://sammy@your_server_ip

Now any Docker command you run will be run on the Droplet. For example, if you start a web server container and expose a port, it will be run on the Droplet and will be accessible through the port you exposed on the Droplet’s IP address.

To verify that you’re accessing the Droplet as the Docker host, run `docker info`.

    docker info

You will see your Droplet’s hostname listed in the `Name` field like so:

    Output…
    Name: docker-host
    …

One thing to keep in mind is that when you run a `docker build` command, the build context (all files and folders accessible from the `Dockerfile`) will be sent to the host and then the build process will run. Depending on the size of the build context and the amount of files, it may take a longer time compared to building the image on a local machine. One solution would be to create a new directory dedicated to the Docker image and copy or link only the files that will be used in the image so that no unneeded files will be uploaded inadvertently.

Once you’ve set the `DOCKER_HOST` variable using `export`, its value will persist for the duration of the shell session. Should you need to use your local Docker server again, you can clear the variable using the following command:

    unset DOCKER_HOST

## Conclusion

You’ve created a remote Docker host and connected to it locally. The next time your laptop’s battery is running low or you need to build a heavy Docker image, use your shiny remote Docker server instead of your local machine.

You might also be interested in learning [how to optimize Docker images for production](how-to-optimize-docker-images-for-production), or [how to optimize them specifically for Kubernetes](building-optimized-containers-for-kubernetes).
