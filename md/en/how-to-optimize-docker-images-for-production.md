---
author: Adnan Rahić
date: 2019-03-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-optimize-docker-images-for-production
---

# How To Optimize Docker Images for Production

_The author selected [Code.org](https://www.brightfunds.org/organizations/code-org) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

In a production environment, [Docker](https://www.docker.com/) makes it easy to create, deploy, and run applications inside of containers. Containers let developers gather applications and all their core necessities and dependencies into a single package that you can turn into a Docker image and replicate. Docker images are built from [Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/). The Dockerfile is a file where you define what the image will look like, what base operating system it will have, and which commands will run inside of it.

Large Docker images can lengthen the time it takes to build and send images between clusters and cloud providers. If, for example, you have a gigabyte-sized image to push every time one of your developers triggers a build, the throughput you create on your network will add up during the CI/CD process, making your application sluggish and ultimately costing you resources. Because of this, Docker images suited for production should only have the bare necessities installed.

There are several ways to decrease the size of Docker images to optimize for production. First off, these images don’t usually need build tools to run their applications, and so there’s no need to add them at all. By using a [multi-stage build process](https://docs.docker.com/develop/develop-images/multistage-build/), you can use intermediate images to compile and build the code, install dependencies, and package everything into the smallest size possible, then copy over the final version of your application to an empty image without build tools. Additionally, you can use an image with a tiny base, like [Alpine Linux](https://alpinelinux.org/about/). Alpine is a suitable Linux distribution for production because it only has the bare necessities that your application needs to run.

In this tutorial, you’ll optimize Docker images in a few simple steps, making them smaller, faster, and better suited for production. You’ll build images for a sample [Go API](https://github.com/do-community/mux-go-api) in several different Docker containers, starting with Ubuntu and language-specific images, then moving on to the Alpine distribution. You will also use multi-stage builds to optimize your images for production. The end goal of this tutorial is to show the size difference between using default Ubuntu images and optimized counterparts, and to show the advantage of multi-stage builds. After reading through this tutorial, you’ll be able to apply these techniques to your own projects and CI/CD pipelines.

**Note:** This tutorial uses an API written in [Go](https://golang.org/) as an example. This simple API will give you a clear understanding of how you would approach optimizing Go microservices with Docker images. Even though this tutorial uses a Go API, you can apply this process to almost any programming language.

## Prerequisites

Before you start you will need:

- An Ubuntu 18.04 server with a non-root user account with `sudo` privileges. Follow our [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) tutorial for guidance. Although this tutorial was tested on Ubuntu 18.04, you can follow many of the steps on any Linux distribution.

- Docker installed on your server. Please follow Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04) for installation instructions.

## Step 1 — Downloading the Sample Go API

Before optimizing your Docker image, you must first download the [sample API](https://github.com/do-community/mux-go-api) that you will build your Docker images from. Using a simple Go API will showcase all the key steps of building and running an application inside a Docker container. This tutorial uses Go because it’s a compiled language like [C++](https://en.wikipedia.org/wiki/C%2B%2B) or [Java](https://www.java.com/en/), but unlike them, has a very small footprint.

On your server, begin by cloning the sample Go API:

    git clone https://github.com/do-community/mux-go-api.git

Once you have cloned the project, you will have a directory named `mux-go-api` on your server. Move into this directory with `cd`:

    cd mux-go-api

This will be the home directory for your project. You will build your Docker images from this directory. Inside, you will find the source code for an API written in Go in the `api.go` file. Although this API is minimal and has only a few endpoints, it will be appropriate for simulating a production-ready API for the purposes of this tutorial.

Now that you have downloaded the sample Go API, you are ready to build a base Ubuntu Docker image, against which you can compare the later, optimized Docker images.

## Step 2 — Building a Base Ubuntu Image

For your first Docker image, it will be useful to see what it looks like when you start out with a base Ubuntu image. This will package your sample API in an environment similar to the software you’re already running on your Ubuntu server. Inside the image, you will install the various packages and modules you need to run your application. You will find, however, that this process creates a rather heavy Ubuntu image that will affect build time and the code readability of your Dockerfile.

Start by writing a Dockerfile that instructs Docker to create an Ubuntu image, install Go, and run the sample API. Make sure to create the Dockerfile in the directory of the cloned repo. If you cloned to the home directory it should be `$HOME/mux-go-api`.

Make a new file called `Dockerfile.ubuntu`. Open it up in `nano` or your favorite text editor:

    nano ~/mux-go-api/Dockerfile.ubuntu

In this Dockerfile, you’ll define an Ubuntu image and install Golang. Then you’ll proceed to install the needed dependencies and build the binary. Add the following contents to `Dockerfile.ubuntu`:

~/mux-go-api/Dockerfile.ubuntu

    FROM ubuntu:18.04
    
    RUN apt-get update -y \
      && apt-get install -y git gcc make golang-1.10
    
    ENV GOROOT /usr/lib/go-1.10
    ENV PATH $GOROOT/bin:$PATH
    ENV GOPATH /root/go
    ENV APIPATH /root/go/src/api
    
    WORKDIR $APIPATH
    COPY . .
    
    RUN \ 
      go get -d -v \
      && go install -v \
      && go build
    
    EXPOSE 3000
    CMD ["./api"]

Starting from the top, the `FROM` command specifies which base operating system the image will have. Then the `RUN` command installs the Go language during the creation of the image. `ENV` sets the specific environment variables the Go compiler needs in order to work properly. `WORKDIR` specifies the directory where we want to copy over the code, and the `COPY` command takes the code from the directory where `Dockerfile.ubuntu` is and copies it over into the image. The final `RUN` command installs Go dependencies needed for the source code to compile and run the API.

**Note:** Using the `&&` operators to string together `RUN` commands is important in optimizing Dockerfiles, because every `RUN` command will create a new layer, and every new layer increases the size of the final image.

Save and exit the file. Now you can run the `build` command to create a Docker image from the Dockerfile you just made:

    docker build -f Dockerfile.ubuntu -t ubuntu .

The `build` command builds an image from a Dockerfile. The `-f` flag specifies that you want to build from the `Dockerfile.ubuntu` file, while `-t` stands for tag, meaning you’re tagging it with the name `ubuntu`. The final dot represents the current context where `Dockerfile.ubuntu` is located.

This will take a while, so feel free to take a break. Once the build is done, you’ll have an Ubuntu image ready to run your API. But the final size of the image might not be ideal; anything above a few hundred MB for this API would be considered an overly large image.

Run the following command to list all Docker images and find the size of your Ubuntu image:

    docker images

You’ll see output showing the image you just created:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 61b2096f6871 33 seconds ago 636MB
    . . .

As is highlighted in the output, this image has a size of **636MB** for a basic Golang API, a number that may vary slightly from machine to machine. Over multiple builds, this large size will significantly affect deployment times and network throughput.

In this section, you built an Ubuntu image with all the needed Go tools and dependencies to run the API you cloned in Step 1. In the next section, you’ll use a pre-built, language-specific Docker image to simplify your Dockerfile and streamline the build process.

## Step 3 — Building a Language-Specific Base Image

Pre-built images are ordinary base images that users have modified to include situation-specific tools. Users can then push these images to the [Docker Hub](https://hub.docker.com/) image repository, allowing other users to use the shared image instead of having to write their own individual Dockerfiles. This is a common process in production situations, and you can find various pre-built images on Docker Hub for almost any use case. In this step, you’ll build your sample API using a Go-specific image that already has the compiler and dependencies installed.

With pre-built base images already containing the tools you need to build and run your app, you can cut down the build time significantly. Because you’re starting with a base that has all needed tools pre-installed, you can skip adding these to your Dockerfile, making it look a lot cleaner and ultimately decreasing the build time.

Go ahead and create another Dockerfile and name it `Dockerfile.golang`. Open it up in your text editor:

    nano ~/mux-go-api/Dockerfile.golang

This file will be significantly more concise than the previous one because it has all the Go-specific dependencies, tools, and compiler pre-installed.

Now, add the following lines:

~/mux-go-api/Dockerfile.golang

    FROM golang:1.10
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN \
        go get -d -v \
        && go install -v \
        && go build
    
    EXPOSE 3000
    CMD ["./api"]

Starting from the top, you’ll find that the `FROM` statement is now `golang:1.10`. This means Docker will fetch a pre-built Go image from Docker Hub that has all the needed Go tools already installed.

Now, once again, build the Docker image with:

    docker build -f Dockerfile.golang -t golang .

Check the final size of the image with the following command:

    docker images

This will yield output similar to the following:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    golang latest eaee5f524da2 40 seconds ago 744MB
    . . .

Even though the Dockerfile itself is more efficient and the build time is shorter, the total image size actually increased. The pre-built Golang image is around **744MB** , a significant amount.

This is the preferred way to build Docker images. It gives you a base image which the community has approved as the standard to use for the specified language, in this case Go. However, to make an image ready for production, you need to cut away parts that the running application does not need.

Keep in mind that using these heavy images is fine when you are unsure about your needs. Feel free to use them both as throwaway containers as well as the base for building other images. For development or testing purposes, where you don’t need to think about sending images through the network, it’s perfectly fine to use heavy images. But if you want to optimize deployments, then you need to try your best to make your images as tiny as possible.

Now that you have tested a language-specific image, you can move on to the next step, in which you will use the lightweight Alpine Linux distribution as a base image to make your Docker image lighter.

## Step 4 — Building Base Alpine Images

One of the easiest steps to optimize your Docker images is to use smaller base images. [Alpine](https://alpinelinux.org/about/) is a lightweight Linux distribution designed for security and resource efficiency. The Alpine Docker image uses [musl libc](https://www.musl-libc.org/) and [BusyBox](https://busybox.net/about.html) to stay compact, requiring no more than 8MB in a container to run. The tiny size is due to binary packages being thinned out and split, giving you more control over what you install, which keeps the environment as small and efficient as possible.

The process of creating an Alpine image is similar to how you created the Ubuntu image in Step 2. First, create a new file called `Dockerfile.alpine`:

    nano ~/mux-go-api/Dockerfile.alpine

Now add this snippet:

~/mux-go-api/Dockerfile.alpine

    FROM alpine:3.8
    
    RUN apk add --no-cache \
        ca-certificates \
        git \
        gcc \
        musl-dev \
        openssl \
        go
    
    ENV GOPATH /go
    ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
    ENV APIPATH $GOPATH/src/api
    RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" "$APIPATH" && chmod -R 777 "$GOPATH"
    
    WORKDIR $APIPATH
    COPY . .
    
    RUN \
        go get -d -v \
        && go install -v \
        && go build
    
    EXPOSE 3000
    CMD ["./api"]

Here you’re adding the `apk add` command to use Alpine’s package manager to install Go and all libraries it requires. As with the Ubuntu image, you need to set the environment variables as well.

Go ahead and build the image:

    docker build -f Dockerfile.alpine -t alpine .

Once again, check the image size:

    docker images

You will receive output similar to the following:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    alpine latest ee35a601158d 30 seconds ago 426MB
    . . .

The size has gone down to around **426MB**.

The small size of the Alpine base image has reduced the final image size, but there are a few more things you can do to make it even smaller.

Next, try using a pre-built Alpine image for Go. This will make the Dockerfile shorter, and will also cut down the size of the final image. Because the pre-built Alpine image for Go is built with Go compiled from source, its footprint is significantly smaller.

Start by creating a new file called `Dockerfile.golang-alpine`:

    nano ~/mux-go-api/Dockerfile.golang-alpine

Add the following contents to the file:

~/mux-go-api/Dockerfile.golang-alpine

    FROM golang:1.10-alpine3.8
    
    RUN apk add --no-cache --update git
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN go get -d -v \
      && go install -v \
      && go build
    
    EXPOSE 3000
    CMD ["./api"]

The only differences between `Dockerfile.golang-alpine` and `Dockerfile.alpine` are the `FROM` command and the first `RUN` command. Now, the `FROM` command specifies a `golang` image with the `1.10-alpine3.8` tag, and `RUN` only has a command for installing [Git](https://git-scm.com/). You need Git for the `go get` command to work in the second `RUN` command at the bottom of `Dockerfile.golang-alpine`.

Build the image with the following command:

    docker build -f Dockerfile.golang-alpine -t golang-alpine .

Retrieve your list of images:

    docker images

You will receive the following output:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    golang-alpine latest 97103a8b912b 49 seconds ago 288MB

Now the image size is down to around **288MB**.

Even though you’ve managed to cut down the size a lot, there’s one last thing you can do to get the image ready for production. It’s called a multi-stage build. By using multi-stage builds, you can use one image to build the application while using another, lighter image to package the compiled application for production, a process you will run through in the next step.

## Step 5 — Excluding Build Tools with a Multi-Stage Build

Ideally, images that you run in production shouldn’t have any build tools installed or dependencies that are redundant for the production application to run. You can remove these from the final Docker image by using multi-stage builds. This works by building the binary, or in other terms, the compiled Go application, in an intermediate container, then copying it over to an empty container that doesn’t have any unnecessary dependencies.

Start by creating another file called `Dockerfile.multistage`:

    nano ~/mux-go-api/Dockerfile.multistage

What you’ll add here will be familiar. Start out by adding the exact same code as with `Dockerfile.golang-alpine`. But this time, also add a second image where you’ll copy the binary from the first image.

~/mux-go-api/Dockerfile.multistage

    FROM golang:1.10-alpine3.8 AS multistage
    
    RUN apk add --no-cache --update git
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN go get -d -v \
      && go install -v \
      && go build
    
    ##
    
    FROM alpine:3.8
    COPY --from=multistage /go/bin/api /go/bin/
    EXPOSE 3000
    CMD ["/go/bin/api"]

Save and close the file. Here you have two `FROM` commands. The first is identical to `Dockerfile.golang-alpine`, except for having an additional `AS multistage` in the `FROM` command. This will give it a name of `multistage`, which you will then reference in the bottom part of the `Dockerfile.multistage` file. In the second `FROM` command, you’ll take a base `alpine` image and `COPY` over the compiled Go application from the `multistage` image into it. This process will further cut down the size of the final image, making it ready for production.

Run the build with the following command:

    docker build -f Dockerfile.multistage -t prod .

Check the image size now, after using a multi-stage build.

    docker images

You will find two new images instead of only one:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    prod latest 82fc005abc40 38 seconds ago 11.3MB
    <none> <none> d7855c8f8280 38 seconds ago 294MB
    . . .

The `<none>` image is the `multistage` image built with the `FROM golang:1.10-alpine3.8 AS multistage` command. It’s only an intermediary used to build and compile the Go application, while the `prod` image in this context is the final image which only contains the compiled Go application.

From an initial **744MB** , you’ve now shaved down the image size to around **11.3MB**. Keeping track of a tiny image like this and sending it over the network to your production servers will be much easier than with an image of over 700MB, and will save you significant resources in the long run.

## Conclusion

In this tutorial, you optimized Docker images for production using different base Docker images and an intermediate image to compile and build the code. This way, you have packaged your sample API into the smallest size possible. You can use these techniques to improve build and deployment speed of your Docker applications and any CI/CD pipeline you may have.

If you are interested in learning more about building applications with Docker, check out our [How To Build a Node.js Application with Docker](how-to-build-a-node-js-application-with-docker) tutorial. For more conceptual information on optimizing containers, see [Building Optimized Containers for Kubernetes](building-optimized-containers-for-kubernetes).
