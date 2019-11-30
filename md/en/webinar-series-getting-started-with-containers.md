---
author: Janakiram MSV
date: 2017-11-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/webinar-series-getting-started-with-containers
---

# Webinar Series: Getting Started with Containers

This article supplements a [webinar series on deploying and managing containerized workloads in the cloud](https://go.digitalocean.com/containers-and-microservices-webinars-series). The series covers the essentials of containers, including container lifecycle management, deploying multi-container applications, scaling workloads, and understanding Kubernetes, along with highlighting best practices for running stateful applications.

This tutorial includes the concepts and commands covered in the first session in the series, Getting Started with Containers.

<iframe width="854" height="480" src="//www.youtube.com/embed/KXp06cdCySc?rel=0" frameborder="0" allowfullscreen></iframe>

## Introduction

Docker is a platform to deploy and manage containerized applications. Containers are popular among developers, administrators, and devops engineers due to the flexibility they offer.

Docker has three essential components:

- Docker Engine
- Docker Tools
- Docker Registry

Docker Engine provides the core capabilities of managing containers. It interfaces with the underlying Linux operating system to expose simple APIs to deal with the lifecycle of containers.

Docker Tools are a set of command-line tools that talk to the API exposed by the Docker Engine. They are used to run the containers, create new images, configure storage and networks, and perform many more operations that impact the lifecycle of a container.

Docker Registry is the place where container images are stored. Each image can have multiple versions identified through unique tags. Users pull existing images from the registry and push new images to it. [Docker Hub](https://hub.docker.com/) is a hosted registry managed by [Docker, Inc.](https://www.docker.com/) It’s also possible to run a registry within your own environments to keep the images closer to the engine.

By the end of this tutorial, you will have installed Docker on a DigitalOcean Droplet, managed containers, worked with images, added persistence, and set up a private registry.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 Droplet set up by following this [Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

- A [Docker Hub account](https://hub.docker.com/). [This overview of Docker Hub](https://docs.docker.com/docker-hub/) will help you get started.

By default, the `docker` command requires root privileges. However, you can execute the command without the `sudo` prefix by running `docker` as a user in the **docker** group.

To configure your Droplet this way, run the command `sudo usermod -aG docker ${USER}`. This will add the current user to the `docker` group. Then, run the command `su - ${USER}` to apply the new group membership.

This tutorial expects that your server is configured to run the `docker` command without the `sudo` prefix.

## Step 1 — Installing Docker

After SSHing into the Droplet, run the following commands to remove any existing docker-related packages that might already be installed and then install Docker from the official repository:

    sudo apt-get remove docker docker-engine docker.io
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce

After installing Docker, verify the installation with the following commands:

    docker info

The above command shows the details of Docker Engine deployed in the environment. The next command verifies that the Docker Tools are properly installed and configured. It should print the version of both Docker Engine and Tools.

    docker version

## Step 2 — Launching Containers

Docker containers are launched from existing images which are stored in the registry. Images in Docker can be stored in private or public repositories. Private repositories require users to authenticate before pulling images. Public images can be accessed by anyone.

To search for an image named `hello-world`, run the command:

    docker search hello-world

There may be multiple images matching the name `hello-world`. Choose the one with the maximum stars, which indicates the popularity of the image.

Check the available images in your local environment with the following command:

    docker images

Since we haven’t launched any containers yet, there will not be any images. We can now download the image and run it locally:

    docker pull hello-world
    docker run hello-world

If we execute the `docker run` command without pulling the image, Docker Engine will first pull the image and then run it. Running the `docker images` command again shows that we have the `hello-world` image available locally.

Let’s launch a more meaningful container: an Apache web server.

    docker run -p 80:80 --name web -d httpd

You may notice additional options passed to the `docker run` command. Here is an explanation of these switches:

- `-p` — This tells Docker Engine to expose the container’s port `80` on the host’s port `80`. Since Apache listens on port `80`, we need to expose it on the host port. 
- `--name` — This switch assigns a name to our running container. If we omit this, Docker Engine will assign a random name.
- `-d` — This option instructs Docker Engine to run the container in detached mode. Without this, the container will be launched in the foreground, blocking access to the shell. By pushing the container into the background, we can continue to use the shell while the container is still running.

To verify that our container is indeed running in the background, try this command:

    docker ps

The output shows that the container named `web` is running with port `80` mapped to the host port `80`.

Now access the web server:

    curl localhost

Let’s stop and remove the running container with the follow commands:

    docker stop web
    docker rm web

Running `docker ps` again confirms that the container is terminated.

## Step 3 — Adding Storage to Containers

Containers are ephemeral, which means that anything stored within a container will be lost when the container is terminated. To persist data beyond the life of a container, we need to attach a volume to the container. Volumes are directories from the host file system.

Start by creating a new directory on the host:

    mkdir htdocs

Now, let’s launch the container with a new switch to mount the `htdocs` directory, pointing it to the Apache web server’s document root:

    docker run -p 80:80 --name web -d -v $PWD/htdocs:/usr/local/apache2/htdocs httpd

The `-v` switch points the `htdocs` directory within the container to the host’s file system. Any changes made to this directory will be visible at both the locations.

Access the directory from the container by running the command:

    docker exec -it web /bin/bash

This command attaches our terminal to the shell of the containers in an interactive mode. You should see that you are now dropped inside the container.

Navigate to the `htdocs` folder and create a simple HTML file. Finally, exit the shell to return to the host:

    cd /usr/local/apache2/htdocs
    echo '<h1>Hello World from Container</h1>' > index.html
    exit

Executing the `curl localhost` command again shows that the web server is returning the page that we created.

We can not only access this file from the host, but we can also modify it:

    cd htdocs
    cat index.html
    echo '<h1>Hello World from Host</h1>' | sudo tee index.html >/dev/null

Running `curl localhost` again confirms that the web server is serving the latest page created from the host.

Terminate the container with the following command. (The `-f` forces Docker to terminate without stopping first.)

    docker rm -f web

## Step 4 — Building Images

Apart from running existing images from the registry, we can create our own images and store them in the registry.

You can create new images from existing containers. The changes made to the container are first committed and then the images are tagged and pushed to the registry.

Let’s launch the `httpd` container again and modify the default document:

    docker run -p 80:80 --name web -d httpd
    docker exec -it web /bin/bash
    cd htdocs
    echo '<h1>Welcome to my Web Application</h1>' > index.html
    exit

The container is now running with a customized `index.html`. You can verify it with `curl localhost`.

Before we commit the changed container, it’s a good idea to stop it. After it is stopped we will run the commit command:

    docker stop web
    docker commit web doweb 

Confirm the creation of the image with the `docker images` command. It shows the `doweb` image that we just created.

To tag and store this image in Docker Hub, run the following commands to push your image to the public registry:

    docker login
    docker tag your_docker_hub_username/doweb
    docker push your_docker_hub_username/doweb

You can verify the new image by searching in Docker Hub from the browser or the command line.

## Step 5 — Launching a Private Registry

It is possible to run the registry in private environments to keep the images more secure. It also reduces the latency between between the Docker Engine and the image repository.

Docker Registry is available as a container that can be launched like any other container. Since the registry holds multiple images, it’s a good idea to attach a storage volume to it.

    docker run -d -p 5000:5000 --restart=always --name registry -v $PWD/registry:/var/lib/registry registry

Notice that the container is launched in the background with port `5000` exposed and the `registry` directory mapped to the host file system. You can verify that the container is running by executing the `docker ps` command.

We can now tag a local image and push it to the private registry. Let’s first pull the `busybox` container from Docker Hub and tag it.

    docker pull busybox
    docker tag busybox localhost:5000/busybox
    docker images

The previous command confirms that the `busybox` container is now tagged with `localhost:5000`, so push the image to the private registry.

    docker push localhost:5000/busybox

With the image pushed to the local registry, let’s try removing it from the environment and pulling it back from the registry.

    docker rmi -f localhost:5000/busybox
    docker images
    docker pull localhost:5000/busybox
    docker images

We went through the full circle of pulling the image, tagging it, pushing it to the local registry, and, finally, pulling it back.

There may be instances where you would want to run the private registry in a dedicated host. Docker Engine running in different machines will talk to the remote registry to pull and push images.

Since the registry is not secured, we need to modify the configuration of Docker Engine to enable access to an insecure registry. To do this, edit the `daemon.json` file located at `/etc/docker/daemon.json`. Create the file if it doesn’t exist.

Add the following entry:

Editing /etc/docker/daemon.json

    {
      "insecure-registries" : ["REMOTE_REGISTRY_HOST:5000"]
    }

Replace `REMOTE_REGISTRY_HOST` with the hostname or IP address of the remote registry. Restart Docker Engine to ensure that the configuration changes are applied.

## Conclusion

This tutorial helped you to get started with Docker. It covered the essential concepts including the installation, container management, image management, storage, and private registry. The upcoming sessions and articles [in this series](https://go.digitalocean.com/containers-and-microservices-webinars-series) will help you go beyond the basics of Docker.
