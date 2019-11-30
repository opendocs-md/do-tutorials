---
author: Savic
date: 2019-04-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-go-web-application-with-docker-and-nginx-on-ubuntu-18-04
---

# How To Deploy a Go Web Application with Docker and Nginx on Ubuntu 18.04

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Docker](https://www.docker.com/) is the most common containerization software used today. It enables developers to easily package apps along with their environments, which allows for quicker iteration cycles and better resource efficiency, while providing the same desired environment on each run. [Docker Compose](https://docs.docker.com/compose/) is a container orchestration tool that facilitates modern app requirements. It allows you to run multiple interconnected containers at the same time. Instead of manually running containers, orchestration tools give developers the ability to control, scale, and extend a container simultaneously.

The benefits of using Nginx as a front-end web server are its performance, configurability, and TLS termination, which frees the app from completing these tasks. The [`nginx-proxy`](https://github.com/jwilder/nginx-proxy) is an automated system for Docker containers that greatly simplifies the process of configuring Nginx to serve as a reverse proxy. Its [Let’s Encrypt](an-introduction-to-let-s-encrypt) [add-on](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) can accompany the `nginx-proxy` to automate the generation and renewal of certificates for proxied containers.

In this tutorial, you will deploy an example Go web application with [gorilla/mux](https://github.com/gorilla/mux) as the request router and Nginx as the web server, all inside Docker containers, orchestrated by Docker Compose. You’ll use `nginx-proxy` with the Let’s Encrypt add-on as the reverse proxy. At the end of this tutorial, you will have deployed a Go web app accessible at your domain with multiple routes, using Docker and secured with Let’s Encrypt certificates.

## Prerequisites

- An Ubuntu 18.04 server with root privileges, and a secondary, non-root account. You can set this up by following [this initial server setup guide](initial-server-setup-with-ubuntu-18-04). For this tutorial the non-root user is `sammy`.
- Docker installed by following the first two steps of [How To Install Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04).
- Docker Compose installed by following the first step of [How To Install Docker Compose on Ubuntu 18.04](how-to-install-docker-compose-on-ubuntu-18-04). You only need to do the first step.
- A fully registered domain name. This tutorial will use `example.com` throughout. You can get one for free on [Freenom](https://www.freenom.com/en/index.html?lang=en), or use the domain registrar of your choice.
- A DNS “A” record with `example.com` pointing to your server’s public IP address. You can follow [this introduction](https://www.digitalocean.com/docs/networking/dns/quickstart/) to DigitalOcean DNS for details on how to add them.
- An understanding of Docker and its architecture. For an introduction to Docker, see [The Docker Ecosystem: An Introduction to Common Components](the-docker-ecosystem-an-introduction-to-common-components).

## Step 1 — Creating an Example Go Web App

In this step, you will set up your workspace and create a simple Go web app, which you’ll later containerize. The Go app will use the powerful [gorilla/mux](https://github.com/gorilla/mux) request router, chosen for its flexibility and speed.

Start off by logging in as `sammy`:

    ssh sammy@your_server_ip

For this tutorial, you’ll store all data under `~/go-docker`. Run the following command to do this:

    mkdir ~/go-docker

Navigate to it:

    cd ~/go-docker

You’ll store your example Go web app in a file named `main.go`. Create it using your text editor:

    nano main.go

Add the following lines:

main.go

    package main
    
    import (
        "fmt"
        "net/http"
    
        "github.com/gorilla/mux"
    )
    
    func main() {
        r := mux.NewRouter()
    
        r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintf(w, "<h1>This is the homepage. Try /hello and /hello/Sammy\n</h1>")
        })
    
        r.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintf(w, "<h1>Hello from Docker!\n</h1>")
        })
    
        r.HandleFunc("/hello/{name}", func(w http.ResponseWriter, r *http.Request) {
            vars := mux.Vars(r)
            title := vars["name"]
    
            fmt.Fprintf(w, "<h1>Hello, %s!\n</h1>", title)
        })
    
        http.ListenAndServe(":80", r)
    }

You first import `net/http` and `gorilla/mux` packages, which provide HTTP server functionality and routing.

The `gorilla/mux` package implements an easier and more powerful request router and dispatcher, while at the same time maintaining interface compatibility with the standard router. Here, you instantiate a new `mux` router and store it in variable `r`. Then, you define three routes: `/`, `/hello`, and `/hello/{name}`. The first (`/`) serves as the homepage and you include a message for the page. The second (`/hello`) returns a greeting to the visitor. For the third route (`/hello/{name}`) you specify that it should take a name as a parameter and show a greeting message with the name inserted.

At the end of your file, you start the HTTP server with `http.ListenAndServe` and instruct it to listen on port `80`, using the router you configured.

Save and close the file.

Before running your Go app, you first need to compile and pack it for execution inside a Docker container. Go is a [compiled language](how-to-write-your-first-program-in-go#step-2-%E2%80%94-running-a-go-program), so before a program can run, the compiler translates the programming code into executable machine code.

You’ve set up your workspace and created an example Go web app. Next, you will deploy `nginx-proxy` with an automated Let’s Encrypt certificate provision.

## Step 2 — Deploying nginx-proxy with Let’s Encrypt

It’s important that you secure your app with HTTPS. To accomplish this, you’ll deploy `nginx-proxy` via Docker Compose, along with its Let’s Encrypt [add-on](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion). This secures Docker containers proxied using `nginx-proxy`, and takes care of securing your app through HTTPS by automatically handling TLS certificate creation and renewal.

You’ll be storing the Docker Compose configuration for `nginx-proxy` in a file named `nginx-proxy-compose.yaml`. Create it by running:

    nano nginx-proxy-compose.yaml

Add the following lines to the file:

nginx-proxy-compose.yaml

    version: '2'
    
    services:
      nginx-proxy:
        restart: always
        image: jwilder/nginx-proxy
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - "/etc/nginx/vhost.d"
          - "/usr/share/nginx/html"
          - "/var/run/docker.sock:/tmp/docker.sock:ro"
          - "/etc/nginx/certs"
    
      letsencrypt-nginx-proxy-companion:
        restart: always
        image: jrcs/letsencrypt-nginx-proxy-companion
        volumes:
          - "/var/run/docker.sock:/var/run/docker.sock:ro"
        volumes_from:
          - "nginx-proxy"

Here you’re defining two containers: one for `nginx-proxy` and one for its Let’s Encrypt add-on (`letsencrypt-nginx-proxy-companion`). For the proxy, you specify the image `jwilder/nginx-proxy`, expose and map HTTP and HTTPS ports, and finally define volumes that will be accessible to the container for persisting Nginx-related data.

In the second block, you name the image for the Let’s Encrypt add-on configuration. Then, you configure access to Docker’s socket by defining a volume and then the existing volumes from the proxy container to inherit. Both containers have the `restart` property set to `always`, which instructs Docker to always keep them up (in the case of a crash or a system reboot).

Save and close the file.

Deploy the `nginx-proxy` by running:

    docker-compose -f nginx-proxy-compose.yaml up -d

Docker Compose accepts a custom named file via the `-f` flag. The `up` command runs the containers, and the `-d` flag, detached mode, instructs it to run the containers in the background.

Your final output will look like this:

    OutputCreating network "go-docker_default" with the default driver
    Pulling nginx-proxy (jwilder/nginx-proxy:)...
    latest: Pulling from jwilder/nginx-proxy
    a5a6f2f73cd8: Pull complete
    2343eb083a4e: Pull complete
    ...
    Digest: sha256:619f390f49c62ece1f21dfa162fa5748e6ada15742e034fb86127e6f443b40bd
    Status: Downloaded newer image for jwilder/nginx-proxy:latest
    Pulling letsencrypt-nginx-proxy-companion (jrcs/letsencrypt-nginx-proxy-companion:)...
    latest: Pulling from jrcs/letsencrypt-nginx-proxy-companion
    ...
    Creating go-docker_nginx-proxy_1 ... done
    Creating go-docker_letsencrypt-nginx-proxy-companion_1 ... done

You’ve deployed `nginx-proxy` and its Let’s Encrypt companion using Docker Compose. Next, you’ll create a Dockerfile for your Go web app.

## Step 3 — Dockerizing the Go Web App

In this section, you will create a Dockerfile containing instructions on how Docker will create an immutable image for your Go web app. Docker builds an immutable app image—similar to a snapshot of the container—using the instructions found in the Dockerfile. The image’s immutability guarantees the same environment each time a container, based on the particular image, is run.

Create the `Dockerfile` with your text editor:

    nano Dockerfile

Add the following lines:

Dockerfile

    FROM golang:alpine AS build
    RUN apk --no-cache add gcc g++ make git
    WORKDIR /go/src/app
    COPY . .
    RUN go get ./...
    RUN GOOS=linux go build -ldflags="-s -w" -o ./bin/web-app ./main.go
    
    FROM alpine:3.9
    RUN apk --no-cache add ca-certificates
    WORKDIR /usr/bin
    COPY --from=build /go/src/app/bin /go/bin
    EXPOSE 80
    ENTRYPOINT /go/bin/web-app --port 80

This Dockerfile has two stages. The first stage uses the `golang:alpine` base, which contains pre-installed Go on Alpine Linux.

Then you install `gcc`, `g++`, `make`, and `git` as the necessary compilation tools for your Go app. You set the working directory to `/go/src/app`, which is under the default [GOPATH](understanding-the-gopath). You also copy the content of the current directory into the container. The first stage concludes with recursively fetching the packages used from the code and compiling the `main.go` file for release without symbol and debug info (by passing `-ldflags="-s -w"`). When you compile a Go program it keeps a separate part of the binary that would be used for debugging, however, this extra information uses memory, and is not necessary to preserve when deploying to a production environment.

The second stage bases itself on `alpine:3.9` (Alpine Linux 3.9). It installs trusted CA certificates, copies the compiled app binaries from the first stage to the current image, exposes port `80`, and sets the app binary as the image entry point.

Save and close the file.

You’ve created a Dockerfile for your Go app that will fetch its packages, compile it for release, and run it upon container creation. In the next step, you will create the Docker Compose `yaml` file and test the app by running it in Docker.

## Step 4 — Creating and Running the Docker Compose File

Now, you’ll create the Docker Compose config file and write the necessary configuration for running the Docker image you created in the previous step. Then, you will run it and check if it works correctly. In general, the Docker Compose config file specifies the containers, their settings, networks, and volumes that the app requires. You can also specify that these elements can start and stop as one at the same time.

You will be storing the Docker Compose configuration for the Go web app in a file named `go-app-compose.yaml`. Create it by running:

    nano go-app-compose.yaml

Add the following lines to this file:

go-app-compose.yaml

    version: '2'
    services:
      go-web-app:
        restart: always
        build:
          dockerfile: Dockerfile
          context: .
        environment:
          - VIRTUAL_HOST=example.com
          - LETSENCRYPT_HOST=example.com

Remember to replace `example.com` both times with your domain name. Save and close the file.

This Docker Compose configuration contains one container (`go-web-app`), which will be your Go web app. It builds the app using the Dockerfile you’ve created in the previous step, and takes the current directory, which contains the source code, as the context for building. Furthermore, it sets two environment variables: `VIRTUAL_HOST` and `LETSENCRYPT_HOST`. `nginx-proxy` uses `VIRTUAL_HOST` to know from which domain to accept the requests. `LETSENCRYPT_HOST` specifies the domain name for generating TLS certificates, and must be the same as `VIRTUAL_HOST`, unless you specify a wildcard domain.

Now, you’ll run your Go web app in the background via Docker Compose with the following command:

    docker-compose -f go-app-compose.yaml up -d

Your final output will look like the following:

    OutputCreating network "go-docker_default" with the default driver
    Building go-web-app
    Step 1/12 : FROM golang:alpine AS build
     ---> b97a72b8e97d
    ...
    Successfully tagged go-docker_go-web-app:latest
    WARNING: Image for service go-web-app was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
    Creating go-docker_go-web-app_1 ... done

If you review the output presented after running the command, Docker logged every step of building the app image according to the configuration in your Dockerfile.

You can now navigate to `https://example.com/` to see your homepage. At your web app’s home address, you’re seeing the page as a result of the `/` route you defined in the first step.

![This is the homepage. Try /hello and /hello/Sammy](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/godockernginx/step4a.png)

Now navigate to `https://example.com/hello`. You will see the message you defined in your code for the `/hello` route from Step 1.

![Hello from Docker!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/godockernginx/step4b.png)

Finally, try appending a name to your web app’s address to test the other route, like: `https://example.com/hello/Sammy`.

![Hello, Sammy!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/godockernginx/step4c.png)

**Note:** In the case that you receive an error about invalid TLS certificates, wait a few minutes for the Let’s Encrypt add-on to provision the certificates. If you are still getting errors after a short time, double check what you’ve entered against the commands and configuration shown in this step.

You’ve created the Docker Compose file and written configuration for running your Go app inside a container. To finish, you navigated to your domain to check that the `gorilla/mux` router setup is serving requests to your Dockerized Go web app correctly.

## Conclusion

You have now successfully deployed your Go web app with Docker and Nginx on Ubuntu 18.04. With Docker, maintaining applications becomes less of a hassle, because the environment the app is executed in is guaranteed to be the same each time it’s run. The [gorilla/mux](https://github.com/gorilla/mux) package has excellent documentation and offers more sophisticated features, such as naming routes and serving static files. For more control over the Go HTTP server module, such as defining custom timeouts, visit the [official docs](https://golang.org/pkg/net/http/).
