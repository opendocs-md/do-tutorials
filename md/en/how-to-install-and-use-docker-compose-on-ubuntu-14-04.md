---
author: Nik van der Ploeg
date: 2015-11-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-14-04
---

# How To Install and Use Docker Compose on Ubuntu 14.04

## Introduction

[Docker](https://docs.docker.com/) is a great tool, but to really take full advantage of its potential it’s best if each component of your application runs in its own container. For complex applications with a lot of components, orchestrating all the containers to start up and shut down together (not to mention talk to each other) can quickly become unwieldy.

The Docker community came up with a popular solution called [Fig](http://www.fig.sh/), which allowed you to use a single YAML file to orchestrate all your Docker containers and configurations. This became so popular that the Docker team eventually decided to make their own version based on the Fig source. They called it _Docker Compose_. In short, it makes dealing with the orchestration processes of Docker containers (such as starting up, shutting down, and setting up intra-container linking and volumes) really easy.

By the end of this article, you will have Docker and Docker Compose installed and have a basic understanding of how Docker Compose works.

## Docker and Docker Compose Concepts

Using Docker Compose requires a combination of a bunch of different Docker concepts in one, so before we get started let’s take a minute to review the various concepts involved. If you’re already familiar with Docker concepts like volumes, links, and port forwarding then you might want to go ahead and skip on to the next section.

### Docker Images

Each Docker container is a local instance of a Docker image. You can think of a Docker image as a complete Linux installation. Usually a minimal installation contains only the bare minimum of packages needed to run the image. These images use the kernel of the host system, but since they are running inside a Docker container and only see their own file system, it’s perfectly possible to run a distribution like CentOS on an Ubuntu host (or vice-versa).

Most Docker images are distributed via the [Docker Hub](https://hub.docker.com/), which is maintained by the Docker team. Most popular open source projects have a corresponding image uploaded to the Docker Registry, which you can use to deploy the software. When possible it’s best to grab “official” images, since they are guaranteed by the Docker team to follow Docker best practices.

### Communication Between Docker Images

Docker containers are isolated from the host machine by default, meaning that by default the host machine has no access to the file system inside the Docker container, nor any means of communicating with it via the network. Needless to say, this makes configuring and working with the image running inside a Docker container difficult by default.

Docker has three primary ways to work around this. The first and most common is to have Docker specify environment variables that will be set inside the Docker container. The code running inside the Docker container will then check the values of these environment variables on startup and use them to configure itself properly.

Another commonly used method is a [Docker data volume](how-to-work-with-docker-data-volumes-on-ubuntu-14-04). Docker volumes come in two flavors — internal and shared.

Specifying an internal volume just means that for a folder you specify for a particular Docker container, the data will be persisted when the container is removed. For example if you wanted to make sure your log files hung around you might specify an internal `/var/log` volume.

A shared volume maps a folder inside a Docker container onto a folder on the host machine. This allows you to easily share files between the Docker container and the host machine, which we’ll explore in the [Docker data volume article](how-to-work-with-docker-data-volumes-on-ubuntu-14-04).

The third way to communicate with a Docker container is via the network. Docker allows communication between different Docker containers via `links`, as well as port forwarding, allowing you to forward ports from inside the Docker container to ports on the host server. For example, you can create a link to allow your WordPress and MariaDB Docker containers to talk to each other and port-forwarding to expose WordPress to the outside world so that users can connect to it.

## Prerequisites

To follow this article, you will need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)

## Step 1 — Installing Docker

First, install Docker if you haven’t already. The quickest way to install Docker is to download and install their installation script (you’ll be prompted for a sudo password).

    wget -qO- https://get.docker.com/ | sh

The above command downloads and executes a small installation script written by the Docker team. If you don’t trust third party scripts or want more details about what the script is doing check out the instructions in the [DigitalOcean Docker tutorial](how-to-install-and-use-docker-getting-started) or Docker’s own [installation documentation](https://docs.docker.com/installation/ubuntulinux/).

Working with Docker is a pain if your user is not configured correctly, so add your user to the `docker` group with the following command.

    sudo usermod -aG docker $(whoami)

Log out and log in from your server to activate your new groups.

**Note:** To learn more about how to use Docker, read the _How to Use Docker_ section of [How To Install and Use Docker: Getting Started](how-to-install-and-use-docker-getting-started#how-to-use-docker).

## Step 2 — Installing Docker Compose

Now that you have Docker installed, let’s go ahead and install Docker Compose. First, install `python-pip` as prerequisite:

    sudo apt-get -y install python-pip

Then you can install Docker Compose:

    sudo pip install docker-compose

## Step 3 — Running a Container with Docker Compose

The public Docker registry, Docker Hub, includes a simple _Hello World_ image. Now that we have Docker Compose installed, let’s test it with this really simple example.

First, create a directory for our YAML file:

    mkdir hello-world

Then change into the directory:

    cd hello-world

Now create the YAML file using your favorite text editor (we will use nano):

    nano docker-compose.yml

Put the following contents into the file, save the file, and exit the text editor:

docker-compose.yml

    my-test:
      image: hello-world

The first line will be used as part of the container name. The second line specifies which image to use to create the container. The image will be downloaded from the official Docker Hub repository.

While still in the `~/hello-world` directory, execute the following command to create the container:

    docker-compose up

The output should start with the following:

    Output of docker-compose upCreating helloworld_my-test_1...
    Attaching to helloworld_my-test_1
    my-test_1 | 
    my-test_1 | Hello from Docker.
    my-test_1 | This message shows that your installation appears to be working correctly.
    my-test_1 | 

The output then explains what Docker is doing:

1. The Docker client contacted the Docker daemon.
2. The Docker daemon pulled the “hello-world” image from the Docker Hub.
3. The Docker daemon created a new container from that image which runs the executable that produces the output you are currently reading.
4. The Docker daemon streamed that output to the Docker client, which sent it to your terminal.

If the process doesn’t exit on its own, press `CTRL-C`.

This simple test does not show one of the main benefits of Docker Compose — being able to bring a group of Docker containers up and down all at the same time. The [How To Install Wordpress and PhpMyAdmin with Docker Compose on Ubuntu 14.04](how-to-install-wordpress-and-phpmyadmin-with-docker-compose-on-ubuntu-14-04) articles show how to use Docker Compose to run three containers as one application group.

## Step 4 —&nbsp;Learning Docker Compose Commands

Let’s go over the commands the `docker-compose` tool supports.

The `docker-compose` command works on a per-directory basis. You can have multiple groups of Docker containers running on one machine — just make one directory for each container and one `docker-compose.yml` file for each container inside its directory.

So far we’ve been running `docker-compose up` on our own and using `CTRL-C` to shut it down. This allows debug messages to be displayed in the terminal window. This isn’t ideal though, when running in production you’ll want to have `docker-compose` act more like a service. One simple way to do this is to just add the `-d` option when you `up` your session:

    docker-compose up -d

`docker-compose` will now fork to the background.

To show your group of Docker containers (both stopped and currently running), use the following command:

    docker-compose ps

For example, the following shows that the `helloworld_my-test_1` container is stopped:

    Output of `docker-compose ps` Name Command State Ports 
    -----------------------------------------------
    helloworld_my-test_1 /hello Exit 0         

A running container will show the `Up` state:

    Output of `docker-compose ps` Name Command State Ports      
    ---------------------------------------------------------------
    nginx_nginx_1 nginx -g daemon off; Up 443/tcp, 80/tcp 

To stop all running Docker containers for an application group, issue the following command in the same directory as the `docker-compose.yml` file used to start the Docker group:

    docker-compose stop

**Note:** `docker-compose kill` is also available if you need to shut things down more forcefully.

In some cases, Docker containers will store their old information in an internal volume. If you want to start from scratch you can use the `rm` command to fully delete all the containers that make up your container group:

    docker-compose rm 

If you try any of these commands from a directory other than the directory that contains a Docker container and `.yml` file, it will complain and not show you your containers:

    Output from wrong directory Can't find a suitable configuration file in this directory or any parent. Are you in the right directory?
    
            Supported filenames: docker-compose.yml, docker-compose.yaml, fig.yml, fig.yaml

## Step 5 —&nbsp;Accessing the Docker Container Filesystem (Optional)

If you need to work on the command prompt inside a container, you can use the `docker exec` command.

The _Hello World!_ example exits after it is run, so we need to start a container that will keep running so we can then use `docker exec` to access the filesystem for the container. Let’s take a look at the [Nginx image](https://hub.docker.com/_/nginx/) from Docker Hub.

Create a new directory for it and change into it:

    mkdir ~/nginx && cd $_

Create a `docker-compose.yml` file in our new directory:

    nano docker-compose.yml

and paste in the following:

~/nginx/docker-compose.yml

    nginx:
      image: nginx

Save the file and exit. We just need to start the Nginx container as a background process with the following command:

    docker-compose up -d

The Nginx image will be downloaded and then the container will be started in the background.

Now we need the `CONTAINER ID` for the container. List of all the containers that are running:

    docker ps

You will see something similar to the following:

    Output of `docker ps`CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    e90e12f70418 nginx "nginx -g 'daemon off" 6 minutes ago Up 5 minutes 80/tcp, 443/tcp nginx_nginx_1

**Note:** Only _running_ containers are listed with the `docker ps` command.

If we wanted to make a change to the filesystem inside this container, we’d take its ID (in this example `e90e12f70418`) and use `docker exec` to start a shell inside the container:

    docker exec -it e90e12f70418 /bin/bash

The `-t` option opens up a terminal, and the `-i` option makes it interactive. The `/bin/bash` options opens a bash shell to the running container. Be sure to use the ID for your container.

You will see a bash prompt for the container similar to:

    root@e90e12f70418:/#

From here, you can work from the command prompt. Keep in mind, however, that unless you are in a directory that is saved as part of a data volume, your changes will disappear as soon as the container is restarted. Another caveat is that most Docker images are created with very minimal Linux installs, so some of the command line utilities and tools you are used to may not be present.

## Conclusion

Great, so that covers the basic concepts of Docker Compose and how to get it installed and running. Check out the [Deploying Wordpress and PHPMyAdmin with Docker Compose on Ubuntu 14.04](how-to-install-wordpress-and-phpmyadmin-with-docker-compose-on-ubuntu-14-04) tutorial for a more complicated example of how to deploy an application with Docker Compose.

For a complete list of configuration options for the `docker-compose.yml` file refer to the [Compose file reference](https://docs.docker.com/compose/compose-file/).
