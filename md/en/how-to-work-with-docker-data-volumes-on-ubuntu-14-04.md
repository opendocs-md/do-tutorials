---
author: Nik van der Ploeg
date: 2015-11-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-docker-data-volumes-on-ubuntu-14-04
---

# How To Work with Docker Data Volumes on Ubuntu 14.04

## Introduction

In this article we’re going to run through the concept of Docker data volumes: what they are, why they’re useful, the different types of volumes, how to use them, and when to use each one. We’ll also go through some examples of how to use Docker volumes via the `docker` command line tool.

By the time we reach the end of the article, you should be comfortable creating and using any kind of Docker data volume.

## Prerequisites

To follow this tutorial, you will need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)
- Docker installed with the instructions from **Step 1** of [How To Install and Use Docker Compose on Ubuntu 14.04](how-to-install-and-use-docker-compose-on-ubuntu-14-04)

**Note:** Even though the Prerequisites give instructions for installing Docker on Ubuntu 14.04, the `docker` commands for Docker data volumes in this article should work on other operating system as long as Docker is install.

## Explaining Docker Containers

Working with Docker requires understanding quite a few Docker-specific concepts, and most of the documentation focuses on explaining how to use Docker’s toolset without much explanation of why you’d want to use any of those tools. This can be confusing if you’re new to Docker, so we’ll start by going through some basics and then jump into working with Docker containers. Feel free to skip ahead to the next section if you’ve worked with Docker before and just want to know how to get started with data volumes.

A Docker container is similar to a virtual machine. It basically allows you to run a pre-packaged “Linux box” inside a container. The main difference between a Docker container and a typical virtual machine is that Docker is not quite as isolated from the surrounding environment as a normal virtual machine would be. A Docker container shares the Linux kernel with the host operating system, which means it doesn’t need to “boot” the way a virtual machine would.

Since so much is shared, firing up a Docker container is a quick and cheap operation — in most cases you can bring up a full Docker container (the equivalent of a normal virtual machine) in the same time as it would take to run a normal command line program. This is great because it makes deploying complex systems a much easier and more modular process, but it’s a different paradigm from the usual virtual machine approach and has some unexpected side effects for people coming from the virtualization world.

## Learning the Types of Docker Data Volumes

There are three main use cases for Docker data volumes:

1. To keep data around when a container is removed
2. To share data between the host filesystem and the Docker container
3. To share data with other Docker containers

The third case is a little more advanced, so we won’t go into it in this tutorial, but the first two are quite common.

In the first (and simplest) case you just want the data to hang around even if you remove the container, so it’s often easiest to let Docker manage where the data gets stored.

## Keeping Data Persistent

There’s no way to directly create a “data volume” in Docker, so instead we create a _data volume container_ with a volume attached to it. For any other containers that you then want to connect to this data volume container, use the Docker’s `--volumes-from` option to grab the volume from this container and apply them to the current container. This is a bit unusual at first glance, so let’s run through a quick example of how we could use this approach to make our `byebye` file stick around even if the container is removed.

First, create a new data volume container to store our volume:

    docker create -v /tmp --name datacontainer ubuntu

This created a container named `datacontainer` based off of the `ubuntu` image and in the directory `/tmp`.

Now, if we run a new Ubuntu container with the `--volumes-from` flag and run `bash` again as we did earlier, anything we write to the `/tmp` directory will get saved to the `/tmp` volume of our `datacontainer` container.

First, start the `ubuntu` image:

    docker run -t -i --volumes-from datacontainer ubuntu /bin/bash

The `-t` command line options calls a terminal from inside the container. The `-i` flag makes the connection interactive.

At the bash prompt for the `ubuntu` container, create a file in `/tmp`:

    echo "I'm not going anywhere" > /tmp/hi

Go ahead and type `exit` to return to your host machine’s shell. Now, run the same command again:

    docker run -t -i --volumes-from datacontainer ubuntu /bin/bash

This time the `hi` file is already there:

    cat /tmp/hi

You should see:

    Output of cat /tmp/hiI'm not going anywhere

You can add as many `--volumes-from` flags as you’d like (for example, if you wanted to assemble a container that uses data from multiple data containers). You can also create as many data volume containers as you’d like.

The only caveat to this approach is that you can only choose the mount path inside the container (`/tmp` in our example) when you create the data volume container.

## Sharing Data Between the Host and the Docker Container

The other common use for Docker containers is as a means of sharing files between the host machine and the Docker container. This works differently from the last example. There’s no need to create a “data-only” container first. You can simply run a container of any Docker image and override one of its directories with the contents of a directory on the host system.

As a quick real-world example, let’s say you wanted to use the official Docker Nginx image but you wanted to keep a permanent copy of the Nginx’s log files to analyze later. By default the `nginx` Docker image logs to the `/var/log/nginx` directory, but this is `/var/log/nginx` inside the Docker Nginx container. Normally it’s not reachable from the host filesystem.

Let’s create a folder to store our logs and then run a copy of the Nginx image with a shared volume so that Nginx writes its logs to our host’s filesystem instead of to the `/var/log/nginx` inside the container:

    mkdir ~/nginxlogs

Then start the container:

    docker run -d -v ~/nginxlogs:/var/log/nginx -p 5000:80 -i nginx

This `run` command is a little different from the ones we’ve used so far, so let’s break it down piece by piece:

- `-v ~/nginxlogs:/var/log/nginx` —&nbsp;We set up a volume that links the `/var/log/nginx` directory from inside the Nginx container to the `~/nginxlogs` directory on the host machine. Docker uses a `:` to split the host’s path from the container path, and the host path always comes first. 

- `-d` — Detach the process and run in the background. Otherwise, we would just be watching an empty Nginx prompt and wouldn’t be able to use this terminal until we killed Nginx.

- `-p 5000:80` —&nbsp;Setup a port forward. The Nginx container is listening on port 80 by default, and this maps the Nginx container’s port 80 to port 5000 on the host system. 

If you were paying close attention, you may have also noticed one other difference from the previous `run` commands. Up until now we’ve been specifying a command at the end of all our `run` statements (usually `/bin/bash`) to tell Docker what command to run inside the container. Because the Nginx image is an official Docker image, it follows Docker best practices, and the creator of the image set the image to run the command to start Nginx automagically. We can just drop the usual `/bin/bash` here and let the creators of the image choose what command to run in the container for us.

So, we now have a copy of Nginx running inside a Docker container on our machine, and our host machine’s port 5000 maps directly to that copy of Nginx’s port 80. Let’s use curl to do a quick test request:

    curl localhost:5000

You’ll get a screenful of HTML back from Nginx showing that Nginx is up and running. But more interestingly, if you look in the `~/nginxlogs` folder on the host machine and take a look at the `access.log` file you’ll see a log message from Nginx showing our request:

    cat ~/nginxlogs/access.log

You will see something similar to:

    Output of `cat ~/nginxlogs/access.log`172.17.42.1 - - [23/Oct/2015:05:22:51 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.35.0" "-"

If you make any changes to the `~/nginxlogs` folder, you’ll be able to see them from inside the Docker container in real-time as well.

## Conclusion

That about sums it up! We’ve now covered how to create data volume containers whose volumes we can use as a way to persist data in other containers as well as how to share folders between the host filesystem and a Docker container. This covers all but the most advanced use cases when it comes to Docker data volumes.

If you are using Docker Compose, Docker data volumes can be configured in your `docker-compose.yml` file. Check out [How To Install and Use Docker Compose on Ubuntu 14.04](how-to-install-and-use-docker-compose-on-ubuntu-14-04) for details.

Good luck and happy Dockering!
