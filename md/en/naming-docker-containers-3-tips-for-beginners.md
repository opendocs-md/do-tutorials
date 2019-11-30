---
author: Melissa Anderson
date: 2016-11-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/naming-docker-containers-3-tips-for-beginners
---

# Naming Docker Containers: 3 Tips for Beginners

## Introduction

When you create a Docker container, it is assigned a universally unique identifier (UUID). These are essential to avoid naming conflicts and promote automation without human intervention. They effectively identify containers to the host and network. However, they take more effort for humans to differentiate between, whether in the 64 character human-readable long display or the more frequently displayed 12 character short form, which might look something like `285c9f0f9d3d`.

To help the humans, Docker also supplies containers with a randomly-generated name from two words, joined by an underscore, e.g. `evil_ptolemy`. This can make it easier to tell one container from another, but the random names don’t give any more insight into the container function than the UUID.

Here are three tips that can make it easier to keep your bearings as you learn to work with containers.

## 1 — Name the container when you run it

By adding `--name=meaningful_name` to the `docker run` command, an `evil_ptolomy` becomes more recognizable in interactive sessions as well as in the output of commands like `docker ps`. There are limitations, however. Since container names must be unique, you cannot use deliberate naming and scale a service beyond one container.

**On the Command Line or in a Dockerfile:**  
`docker run --name=meaningful_name`

For example, if we ran a container based on the `nginx` base image and started it like this:

    docker run --name nginx -d nginx

The name would appear in the list of running containers:

    docker ps

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    08f333ef7216 nginx "nginx -g 'daemon off" 15 seconds ago Up 14 seconds 80/tcp, 443/tcp nginx

While the name appears in the output of `docker ps` and can be used to manage the container, it will not appear in the command prompt of the container if you attach to it or in log files. In order to accomplish that, you’ll also need to assign a hostname.

## 2 — Assign a hostname to the container

The value supplied to the `--hostname` command is set inside `/etc/hostname` and `/etc/hosts` inside the container. Consequently, it appears in command prompt. It plays a role in configuring [container DNS](https://docs.docker.com/engine/userguide/networking/default_network/configure-dns/) and can be helpful while in the learning stages of a multi-container setup. It is not easy to access from outside the container, but it will appear in the container’s log files, and when those files are written to a volume independent of the host, it can make it easier to identify the container.

**CLI and Dockerfile:**  
`docker run --hostname=value` OR `docker run -h value`

While `--name` and `--hostname` are both useful for identification of containers, sometimes, it’s not about naming the container at all. Rather, it’s about having a container clean up after itself without having to remember to do it yourself.

## 3 — Automatically delete containers when they exit

When debugging, it’s helpful that a stopped container persists after it exits. You can retain data like log files and investigate the container’s final state. Sometimes, however, you know when you run the container that you won’t want it around when you’re done. In this case, you can use the `--rm` flag to automatically delete it when it exits. This can make it easier to keep things clean.

Be careful, though! If you’re using Docker volumes, `--rm` will remove any [volumes NOT specified by name](https://docs.docker.com/engine/reference/run/#/clean-up---rm).

**CLI and Dockerfile:**  
`docker run --rm`

This is very useful when you’re building an image and need to attach to a running container. You want to look around, and you don’t want to fill up your disk with containers you don’t intend to use again.

## Conclusion

These three flags for `docker run`, `--name`, `--hostname`, and `--rm` can each, in their own way, make it easier to know what’s what when learning Docker. You can learn more about containers and working with the `docker run` command in the [Working with Docker Containers](working-with-docker-containers) guide.
