---
author: Janakiram MSV
date: 2017-12-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/webinar-series-building-containerized-applications
---

# Webinar Series: Building Containerized Applications

## Webinar Series

This article supplements a [webinar series on deploying and managing containerized workloads in the cloud](https://go.digitalocean.com/containers-and-microservices-webinars-series). The series covers the essentials of containers, including container lifecycle management, deploying multi-container applications, scaling workloads, and understanding Kubernetes, along with highlighting best practices for running stateful applications.

This tutorial includes the concepts and commands covered in the second session in the series, Building Containerized Applications.

<iframe width="854" height="480" src="//www.youtube.com/embed/bYWLK904fBE?rel=0" frameborder="0" allowfullscreen></iframe>

## Introduction

In the last tutorial, [How to Install and Configure Docker](how-to-install-and-configure-docker), we explored one method for converting [Docker containers](how-to-install-and-configure-docker#step-2-%E2%80%94-launching-containers) into [Docker images](how-to-install-and-configure-docker#step-4-%E2%80%94-building-images). Although the method we used worked, it is not always the optimal way of building images.

In many cases, you’ll want to bring existing code into container images, and you’ll want a repeatable, consistent mechanism for creating Docker images that are in sync with the latest version of your codebase.

A [Dockerfile](https://docs.docker.com/engine/reference/builder/) addresses these requirements by providing a declarative and consistent way of building Docker images.

Additionally, you’ll sometimes want to containerize entire applications which are composed of multiple, heterogeneous containers that are deployed and managed together.

[Docker Compose](https://docs.docker.com/compose/overview/), like a Dockerfile, takes a declarative approach to provide you with a method for defining an entire technology stack, including network and storage requirements. This not only makes it easier to build containerized applications, but it also makes it easier to manage and scale them.

In this tutorial, you will use a sample web application based on [Node.js](https://nodejs.org/) and [MongoDB](https://www.mongodb.com/) to build a Docker image from a Dockerfile, you will create a custom network that allows your Docker containers to communicate, and you will use Docker Compose to launch and scale a containerized application.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 Droplet set up by following this [Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- The latest version of Docker Community Edition installed by following [the first tutorial in this webinar series](how-to-install-and-configure-docker#step-4-%E2%80%94-building-images).

## Step 1 — Building an Image with a Dockerfile

Start by changing to your home directory, then use [Git](https://git-scm.com/) to clone this tutorial’s sample web application from its [official repository on GitHub](https://github.com/janakiramm/todo-app.git).

    cd ~
    git clone https://github.com/janakiramm/todo-app.git

This will copy the sample application into a new directory named `todo-app`.

Switch to `todo-app` and use `ls` to view the directory’s contents.

    cd todo-app
    ls

The new directory contains two subdirectories and two files:

- `app` - the directory where the sample application’s source code is stored
- `compose` - the directory where the Docker Compose configuration file is stored
- `Dockerfile` - a file that contains instructions for building the Docker image
- `README.md` - a file that contains a one-sentence summary of the sample application

Running `cat Dockerfile` shows us the following:

~/todo-app/Dockerfile

    FROM node:slim
    LABEL maintainer = "jani@janakiram.com"
    RUN mkdir -p /usr/src/app
    WORKDIR /usr/src/app
    COPY ./app/ ./
    RUN npm install
    CMD ["node", "app.js"]

Let’s take a look at this file’s contents in more detail:

- `FROM` indicates the base image from which you are building the custom image. In this example, the image is based on `node:slim`, a [public Node.js image](https://hub.docker.com/_/node/) that contains only the minimal packages needed to run `node`. 
- `LABEL` is a key value pair typically used to add descriptive information. In this case, it contains the email address of the maintainer.
- `RUN` executes commands within the container. This includes tasks like creating directories and initializing the container by running basic Linux commands. The first `RUN` command in this file is used to create the directory `/usr/src/app` that holds the source code.
- `WORKDIR` defines the directory where all of the commands are executed. It is typically the directory where the code is copied.
- `COPY` copies the files from the host machine into the container image. In this case, you are copying the entire `app` directory into the image.
- The second `RUN` command executes `npm install` to install the application’s dependencies as defined in `package.json`.
- `CMD` runs the process that will keep the container running. In this example, you will execute `node` with the parameter `app.js`.

Now it’s time to build the image from the `Dockerfile`. Use the `-t` switch to tag the image with the registry username, image name, and an optional tag.

    docker build -t sammy/todo-web .

The output confirms that the image is `Successfully built` and tagged appropriately.

    Output from docker build -tSending build context to Docker daemon 8.238MB
    Step 1/7 : FROM node:slim
     ---> 286b1e0e7d3f
    Step 2/7 : LABEL maintainer = "jani@janakiram.com"
     ---> Using cache
     ---> ab0e049cf6f8
    Step 3/7 : RUN mkdir -p /usr/src/app
     ---> Using cache
     ---> 897176832f4d
    Step 4/7 : WORKDIR /usr/src/app
     ---> Using cache
     ---> 3670f0147bed
    Step 5/7 : COPY ./app/ ./
     ---> Using cache
     ---> e28c7c1be1a0
    Step 6/7 : RUN npm install
     ---> Using cache
     ---> 7ce5b1d0aa65
    Step 7/7 : CMD node app.js
     ---> Using cache
     ---> 2cef2238de24
    Successfully built 2cef2238de24
    Successfully tagged sammy/todo-web:latest

We can verify that the image is created by running the `docker images` command.

    docker images

Here, we can see the size of the image along with the time elapsed since it was created.

    Output from docker imagesREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/todo-web latest 81f5f605d1ca 9 minutes ago 236MB

Since we also need a MongoDB container to run the sample web application, let’s get that to our machine.

    docker pull mongo:latest

The output reports exactly which image was pulled along with the download status.

    Output from docker pulllatest: Pulling from library/mongo
    Digest: sha256:18b239b996e0d10f4ce2b0f64db6f410c17ad337e2cecb6210a3dcf2f732ed82
    Status: Downloaded newer image for mongo:latest

We now have everything we need to run the sample application, so let’s create a custom network that will allow our containers to communicate with each other.

## Step 2 — Creating a Network to Link Containers

If we were to launch the web application and database containers independently through the `docker run` command, they would not be able to find each other.

To see why, view the contents of the web application’s database configuration file.

    cat app/db.js

After importing [Mongoose](http://mongoosejs.com/) — a MongoDB object-modeling library for Node.js — and defining a new [database schema](understanding-sql-and-nosql-databases-and-different-database-models), the web application tries to connect to the database at the hostname, `db`, which doesn’t exist yet.

~/todo-app/app/db.js

    var mongoose = require( 'mongoose' );
    var Schema = mongoose.Schema;
    
    var Todo = new Schema({
        user_id : String,
        content : String,
        updated_at : Date
    });
    
    mongoose.model( 'Todo', Todo );
    
    mongoose.connect( 'mongodb://db/express-todo' );

To ensure that containers belonging to the same application discover each other, we need to launch them on the same network.

Docker provides the ability to create custom networks in addition to the [default networks](https://docs.docker.com/engine/userguide/networking/) created during installation.

You can check your currently available networks with the following command:

    docker network ls

Each network created by Docker is based on a [driver](https://blog.docker.com/2016/12/understanding-docker-networking-drivers-use-cases/). In the following output, we see that the network named `bridge` is based on the driver `bridge`. The `local` scope indicates that the network is available only on this host.

    Output from docker network lsNETWORK ID NAME DRIVER SCOPE
    5029df19d0cf bridge bridge local
    367330960d5c host host local
    f280c1593b89 none null local

We will now create a custom network named `todo_net` for our application and then we will launch containers on that network.

    docker network create todo_net

The output tells us the hash of the network that was created.

    Output from docker network createC09f199809ccb9928dd9a93408612bb99ae08bb5a65833fefd6db2181bfe17ac

Now, list the available networks again.

    docker network ls

Here, we see that `todo_net` is ready for use.

    Output from docker network lsNETWORK ID NAME DRIVER SCOPE
    c51377a045ff bridge bridge local
    2e4106b07544 host host local
    7a8b4801a712 none null local
    bc992f0b2be6 todo_net bridge local

When using the `docker run` command, we can now refer to this network with the `--network` switch. Let’s launch both the web and database containers with specific hostnames. This will ensure that the containers can connect to each other through those hostnames.

First, launch the MongoDB database container.

    docker run -d \
    --name=db \
    --hostname=db \
    --network=todo_net \
    mongo

Taking a closer look at that command, we see:

- The `-d` switch runs the container in [detached mode](https://docs.docker.com/engine/reference/run/#detached--d).
- The `--name` and `--hostname` switches assign a user defined name to the container. The `--hostname` switch also adds an entry to the [DNS service managed by Docker](https://docs.docker.com/engine/userguide/networking/configure-dns/). This helps in resolving the container by host name.
- The `--network` switch instructs Docker Engine to launch the container on a custom network instead of the default bridge network. 

When we see a long string as output from the `docker run` command, we can assume that the container is successfully launched. But, this may not guarantee that the container is actually running.

    Output docker runaa56250f2421c5112cf8e383b68faefea91cd4b6da846cbc56cf3a0f04ff4295

Verify that the `db` container is up and running with the `docker logs` command.

    docker logs db

This prints the container logs to `stdout`. The last line of the log indicates that MongoDB is ready and `waiting for connections`.

    Output from docker logs2017-12-10T02:55:08.284+0000 I CONTROL [initandlisten] MongoDB starting : pid=1 port=27017 dbpath=/data/db 64-bit host=db
    . . . .
    2017-12-10T02:55:08.366+0000 I NETWORK [initandlisten] waiting for connections on port 27017

Now, let’s launch the web container and verify it. This time, we’re also including `--publish=3000:3000` which publishes the host’s port `3000` to the container’s port `3000`.

    docker run -d \
    --name=web \
    --publish=3000:3000 \
    --hostname=web \
    --network=todo_net \
    sammy/todo-web

You’ll receive a long string as output like before.

Let’s also verify that this container is up and running.

    docker logs web

The output confirms that [Express](https://expressjs.com/) — the Node.js framework our test application is based on — is `listening on port 3000`.

    Output from docker logsExpress server listening on port 3000

Verify that the web container is able to talk to the db container with a `ping` command. We do this by running the `docker exec` command in an interactive (`-i`) mode attached to a pseudo-TTY (`-t`).

    docker exec -it web ping db

The command produces standard `ping` output and lets us know that the two containers can communicate with each other.

    Output from docker exec -it web ping dbPING db (172.18.0.2): 56 data bytes
    64 bytes from 172.18.0.2: icmp_seq=0 ttl=64 time=0.210 ms
    64 bytes from 172.18.0.2: icmp_seq=1 ttl=64 time=0.095 ms
    ...

Press `CTRL+C` to stop the `ping` command.

Finally, access the sample application by pointing your web browser to `http://your_server_ip:3000`. You will see a web page with a label that reads **Containers Todo Example** along with a textbox that accepts a todo task as input.

To avoid naming conflicts, you can now stop the containers and clean up the resources with the `docker rm` and `docker network remove` commands.

    docker rm -f db
    docker rm -f web
    docker network remove todo_net

At this point, we have a containerized web application made up of two separate containers. In the next step, we will explore a more robust approach.

## Step 3 — Deploying a Multi-Container Application

Although we were able to launch linked containers, it’s not the most elegant way of dealing with multi-container applications. We need a better way to declare all of the related containers and manage them as one logical unit.

Docker Compose is a framework available to developers to deal with multi-container applications. Like Dockefile, it is a declarative mechanism to define the entire stack. We will now convert our Node.js and MongoDB application into a Docker Compose-based application.

Start by installing Docker Compose.

    sudo apt-get install -y docker-compose 

Let’s examine the `docker-compose.yaml` file located in the sample web application’s `compose` directory.

    cat compose/docker-compose.yaml

The `docker-compose.yaml` file brings everything together. It defines the the MongoDB container in the `db:` block, the Node.js web container in the `web:` block, and the custom network in the `networks:` block.

Note that with the `build: ../.` directive, we are pointing Compose to the `Dockerfile` in the `app` directory. This will instruct Compose to build the image before launching the web container.

~/todo-app/compose/docker-compose.yaml

    version: '2'
    services:
      db:
        image: mongo:latest
        container_name: db
        networks:
          - todonet
      web:
        build: ../.
        networks:
          - todonet
        ports:
         - "3000"
    networks:
      todonet:
        driver: bridge

Now, change to the `compose` directory and launch the application with the `docker-compose up` command. As with `docker run`, the `-d` switch starts the container in detached mode.

    cd compose
    docker-compose up -d

The output reports that Docker Compose created a network called `compose_todonet` and launched both containers on it.

    Output from docker-compose up -dCreating network "compose_todonet" with driver "bridge"
    Creating db
    Creating compose_web_1

Notice that we didn’t provide the explicit host port mapping. This will force Docker Compose to assign a random port to expose the web application on the host. We can find that port by running the following command:

    docker ps

We see that the web application is exposed on host port `32782`.

    Output from docker psCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    6700761c0a1e compose_web "node app.js" 2 minutes ago Up 2 minutes 0.0.0.0:32782->3000/tcp compose_web_1
    ad7656ef5db7 mongo:latest "docker-entrypoint..." 2 minutes ago Up 2 minutes 27017/tcp db

Verify this by navigating your web browser to `http://your_server_ip:32782`. This will bring up the web application just as you saw it at the end of Step 2.

With our multi-container application up and running through Docker Compose, let’s take a look at managing and scaling our application.

## Step 4 — Managing and Scaling the Application

Docker Compose makes it easy to scale stateless web applications. We can launch 10 instances of our `web` container with a single command.

    docker-compose scale web=10

The output lets us watch the instances being created and started in real time.

    Output from docker-compose scaleCreating and starting compose_web_2 ... done
    Creating and starting compose_web_3 ... done
    Creating and starting compose_web_4 ... done
    Creating and starting compose_web_5 ... done
    Creating and starting compose_web_6 ... done
    Creating and starting compose_web_7 ... done
    Creating and starting compose_web_8 ... done
    Creating and starting compose_web_9 ... done
    Creating and starting compose_web_10 ... done

Verify that the web application is scaled to 10 instances by running `docker ps`.

    docker ps

Notice that Docker has assigned a random port to expose each `web` container on the host. Any of these ports can be used to access the application.

    Output from docker psCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    cec405db568d compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32788->3000/tcp compose_web_9
    56adb12640bb compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32791->3000/tcp compose_web_10
    4a1005d1356a compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32790->3000/tcp compose_web_7
    869077de9cb1 compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32785->3000/tcp compose_web_8
    eef86c56d16f compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32783->3000/tcp compose_web_4
    26dbce7f6dab compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32786->3000/tcp compose_web_5
    0b3abd8eee84 compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32784->3000/tcp compose_web_3
    8f867f60d11d compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32789->3000/tcp compose_web_6
    36b817c6110b compose_web "node app.js" About a minute ago Up About a minute 0.0.0.0:32787->3000/tcp compose_web_2
    6700761c0a1e compose_web "node app.js" 7 minutes ago Up 7 minutes 0.0.0.0:32782->3000/tcp compose_web_1
    ad7656ef5db7 mongo:latest "docker-entrypoint..." 7 minutes ago Up 7 minutes 27017/tcp db

You can also scale-in the web container with the same command.

    docker-compose scale web=2

This time, we see the extra instances being removed in real time.

    Output from docker-composeStopping and removing compose_web_3 ... done
    Stopping and removing compose_web_4 ... done
    Stopping and removing compose_web_5 ... done
    Stopping and removing compose_web_6 ... done
    Stopping and removing compose_web_7 ... done
    Stopping and removing compose_web_8 ... done
    Stopping and removing compose_web_9 ... done
    Stopping and removing compose_web_10 ... done

Finally, re-check the instances.

    docker ps

The output confirms that there are only two instances left.

    Output from docker psCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    36b817c6110b compose_web "node app.js" 3 minutes ago Up 3 minutes 0.0.0.0:32787->3000/tcp compose_web_2
    6700761c0a1e compose_web "node app.js" 9 minutes ago Up 9 minutes 0.0.0.0:32782->3000/tcp compose_web_1
    ad7656ef5db7 mongo:latest "docker-entrypoint..." 9 minutes ago Up 9 minutes 27017/tcp db

You can now stop the application, and, just like before, you can also clean up the resources to avoid naming conflicts.

    docker-compose stop
    docker-compose rm -f
    docker network remove compose_todonet

## Conclusion

This tutorial introduced you to Dockerfiles and Docker Compose. We started with a Dockerfile as the declarative mechanism to build images, then we explored the basics of Docker networking. Finally, we scaled and managed multi-container applications with Docker Compose.

To extend your new setup, you can add an [Nginx reverse proxy](understanding-nginx-http-proxying-load-balancing-buffering-and-caching) running inside another container to route requests to one of the available web application containers. Or, you can take advantage of [DigitalOcean’s Block Storage](how-to-use-block-storage-on-digitalocean) and [Load Balancers](an-introduction-to-digitalocean-load-balancers) to bring durability and scalability to the containerized applications.
