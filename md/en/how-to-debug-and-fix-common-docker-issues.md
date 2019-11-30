---
author: Lucero del Alba
date: 2016-10-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-debug-and-fix-common-docker-issues
---

# How to Debug and Fix Common Docker Issues

## Introduction

Docker makes it easy to wrap your applications and services in containers so you can run them anywhere. Unfortunately, problems may arise when building your image and integrating all of the layers that your app needs, especially if you’re new to Docker images and containers. You may encounter typos, issues with runtime libraries and modules, naming collisions, or issues when communicating with other containers.

In this troubleshooting guide aimed at people new to Docker, you’ll troubleshoot problems when building Docker images, resolve naming collisions when running containers, and fix issues that come up when communication between containers.

## Prerequisites

To complete this tutorial, you will need

- Docker installed on a server or your local machine.

To install Docker on a server, you can follow the how-to guides [for CentOS 7](how-to-install-and-use-docker-on-centos-7) or [for Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04).

You can visit [the Docker web site](https://www.docker.com/products/docker) or follow [the official installation documentation](https://docs.docker.com/engine/installation/) to install Docker on your local machine.

## Step 1 — Resolving Problems with the Dockerfile

The most common place you may run into issues is when you’re building your Docker image from a `Dockerfile`. Before we dive in, let’s clarify the difference between images and containers.

- An _image_ is a read-only resource that you create using a configuration file called `Dockerfile`. It’s what you ship and share through [Docker Hub](http://dockerhub.com) or your private registry. 
- A _container_, is a read _and_ write instance that your create out of the image you built.

You can learn more about these concepts in the tutorial [Docker Explained: Using Dockerfiles to automate building of images](docker-explained-using-dockerfiles-to-automate-building-of-images).

When you look at a `Dockerfile`, you can clearly see the step-by-step process Docker uses build the image because each line in the `Dockerfile` corresponds to a step in the process. This generally means that if you got to a certain step, then all of the previous steps completed successfully.

Let’s create a little project to explore some issues you might encounter with a `Dockerfile`. Create a `docker_image` directory in your home directory, and use `nano` or your favorite editor to create a `Dockerfile` in that folder

    mkdir ~/docker_image
    nano ~/docker_image/Dockerfile

Add the following content to this new file:

~/docker\_image/Dockerfile

    # base image
    FROM debian:latest
    
    # install basic apps
    RUN aapt-get install -qy nano

There’s an intentional typo in this code. Can you spot it? Try to build an image from this file to see how Docker handles a bad command. Create the image with the following command:

    docker build -t my_image ~/docker_image

You’ll see this message in your terminal, indicating an error:

    OutputStep 2 : RUN aapt-get install -qy nano
      ---> Running in 085fa10ffcc2
    /bin/sh: 1: aapt-get: not found
    The command '/bin/sh -c aapt-get install -qy nano' returned a non-zero code: 127

The error message at the end means that there was a problem with the command in Step 2. In this case it was our intentional typo: we have `aapt-get` instead of `apt-get`. But that also meant that the previous step executed correctly.

Modify the `Dockerfile` and make the correction:

Dockerfile

    
    # install basic apps
    RUN apt-get install -qy nano

Now run the `docker build` command again:

    docker build -t my_image ~/docker_image

And now you’ll see the following output:

    OutputSending build context to Docker daemon 2.048 kB
    Step 1 : FROM debian:latest
    ---> ddf73f48a05d
    Step 2 : RUN apt-get install -qy nano
    ---> Running in 9679323b942f
    Reading package lists...
    Building dependency tree...
    E: Unable to locate package nano
    The command '/bin/sh -c apt-get install -qy nano' returned a non-zero code: 100

With the typo corrected, the process moved a little faster, since Docker cached the first step rather than redownloading the base image. But as you can see from the output, we have a new error.

The Debian distribution we’ve used as the foundation for our image couldn’t find the text editor `nano`, even though we know it is available on the Debian package repositories. The base image comes with cached metadata, such as repositories and lists of available packages. You may occasionally experience some cache issues when the live repositories you’re pulling data from have changed.

To fix this, modify the Dockerfile to do a cleanup and update of the sources _before_ you install any new packages. Open the configuration file again:

    nano ~/docker_image/Dockerfile

Add the following highlighted line to the file, _above_ the command to install `nano`:

~/docker\_image/Dockerfile

    # base image
    FROM debian:latest
    
    # clean and update sources
    RUN apt-get clean && apt-get update
    
    # install basic apps
    RUN apt-get install -qy nano

Save the file and run the `docker build` command again:

    docker build -t my_image ~/docker_image

This time the process completes successfully.

    OutputSending build context to Docker daemon 2.048 kB
    Step 1 : FROM debian:latest
     ---> a24c3183e910
    Step 2 : RUN apt-get install -qy nano
     ---> Running in 2237d254f172
    Reading package lists...
    Building dependency tree...
    Reading state information...
    Suggested packages:
      spell
    The following NEW packages will be installed:
      nano
    ...
    
     ---> 64ff1d3d71d6
    Removing intermediate container 2237d254f172
    Successfully built 64ff1d3d71d6

Let’s see what happens when we add Python 3 and the PostgreSQL driver to our image. Open the `Dockerfile` again.

    nano ~/docker_image/Dockerfile

And add two new steps to install Python 3 and the Python PostgreSQL driver:

~/docker\_image/Dockerfile

    # base image
    FROM debian:latest
    
    # clean and update sources
    RUN apt-get clean && apt-get update
    
    # install basic apps
    RUN apt-get install -qy nano
    
    # install Python and modules
    RUN apt-get install -qy python3
    RUN apt-get install -qy python3-psycopg2

Save the file, exit the editor, and build the image again:

    docker build -t my_image ~/docker_image

As you can see from the output, the packages install correctly. The process also completes much more quickly because the previous steps were cached.

    OutputSending build context to Docker daemon 2.048 kB
    Step 1 : FROM debian:latest
     ---> ddf73f48a05d
    Step 2 : RUN apt-get clean && apt-get update
     ---> Using cache
     ---> 2c5013476fbf
    Step 3 : RUN apt-get install -qy nano
     ---> Using cache
     ---> 4b77ac535cca
    Step 4 : RUN apt-get install -qy python3
     ---> Running in 93f2d795fefc
    Reading package lists...
    Building dependency tree...
    Reading state information...
    The following extra packages will be installed:
      krb5-locales libgmp10 libgnutls-deb0-28 libgssapi-krb5-2 libhogweed2
      libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 libnettle4
      libp11-kit0 libpq5 libsasl2-2 libsasl2-modules libsasl2-modules-db
      libtasn1-6
    Suggested packages:
      gnutls-bin krb5-doc krb5-user libsasl2-modules-otp libsasl2-modules-ldap
      libsasl2-modules-sql libsasl2-modules-gssapi-mit
      libsasl2-modules-gssapi-heimdal python-psycopg2-doc
    The following NEW packages will be installed:
      krb5-locales libgmp10 libgnutls-deb0-28 libgssapi-krb5-2 libhogweed2
      libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 libnettle4
      libp11-kit0 libpq5 libsasl2-2 libsasl2-modules libsasl2-modules-db
      libtasn1-6 python3-psycopg2
    0 upgraded, 18 newly installed, 0 to remove and 0 not upgraded.
    Need to get 5416 kB of archives.
    After this operation, 10.4 MB of additional disk space will be used.
    
    ...
    
    Processing triggers for libc-bin (2.19-18+deb8u6) ...
     ---> 978e0fa7afa7
    Removing intermediate container d7d4376c9f0d
    Successfully built 978e0fa7afa7

**Note** : Docker caches the build process, so you may run into a situation where you run an update in the build, Docker caches this update, and some time later your base distribution updates its sources again, leaving you with outdated sources, despite doing a cleanup and update in your `Dockerfile`. If you run into issues installing or updating packages inside the container, run `apt-get clean && apt-get update` inside of the container.

Pay close attention to the Docker output to identify where the typos are, and run updates at build time and inside the container to make sure you’re not being hindered by cached package lists.

Syntax errors and caching problems are the most common issues you may encounter when building an image in Docker. Now let’s look at problems that may arise when running containers from those images.

## Step 2 — Resolving Container Naming Issues

As you launch more containers, you will eventually come across name collisions. A naming collision is where you try to create a container that has the same name as a container that already exists on your system. Let’s explore how to properly deal with naming, renaming, and deleting containers in order to avoid collisions.

Let’s launch a container from the image we built on the previous section. We will run an interactive bash interpreter inside this container to test things out. Execute the following command:

    docker run -ti my_image bash

When the container starts, you’ll see a root prompt waiting for instructions:

    

Now that you have a running container, let’s look at what kinds of problems you might run into.

When you run a container the way you just did, without explicitly setting a name, Docker assigns a random name to the container. You can see all of the running containers and their corresponding names by running the `docker ps` command on the Docker host, outside of the running container.

Open a new terminal on the Docker host and run the following command:

    docker ps

This command outputs the list of running containers with their names as show in the following example:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    80a0ca58d6ec my_image "bash" 22 seconds ago Up 28 seconds loving_brahmagupta

The name `loving_brahmagupta` in the preceding output is the name that Docker automatically assigned to the container in the preceding example; yours will have a different name. Letting Docker assign a name to your container is fine in very simple cases, but can present significant problems; when we deploy we need to name containers consistently so we can reference them and automate them easily.

To specify a name for a container we can either use the `--name` argument when we launch the container, or we can rename a running container to something more descriptive.

Run the following command from the Docker host’s terminal:

    docker rename your_container_name python_box

Then list your containers:

    docker ps

You’ll see the `python_box` container in the output, confirming that you successfully renamed the container:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    80a0ca58d6ec my_image "bash" 24 minutes ago Up 24 minutes python_box

To close the container, type `exit` at the prompt in the terminal containing the running container:

    exit

If that’s not an option, you can kill the container from another terminal on the Docker host with the following command:

    docker kill python_box

When you kill the container this way, Docker returns the name of the container that was just killed:

    Outputpython_box

To make sure `python_box` doesn’t exist anymore, list all of the running containers again:

    docker ps

As expected, the container is no longer listed:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES

Now you might think you could launch another container named `python_box`, but let’s see what happens when we try.

We’ll use the `--name` argument this time for setting the container’s name:

    docker run --name python_box -ti my_image bash

    Outputdocker: Error response from daemon: Conflict. The name "/python_box" is already in use by container 80a0ca58d6ecc80b305463aff2a68c4cbe36f7bda15e680651830fc5f9dda772. You have to remove (or rename) that container to be able to reuse that name..
    See 'docker run --help'.

When you build an image and reuse the name of an existing image, the existing image will be overwritten, as you’ve seen already. Containers are a little more complicated because you can’t overwrite a container that already exists.

Docker says `python_box` already exists even though we just killed it and it’s not even listed with `docker ps`. It’s not running, but it’s still available in case you want to start it up again. We stopped it, but we didn’t remove it. The `docker ps` command only shows _running_ containers, not _all_ containers.

To list _all_ of the Docker containers, running and otherwise, pass the `-a` flag (alias for `--all`) to `docker ps`:

    docker ps -a

Now our `python_box` container appears in the output:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    80a0ca58d6ec my_image "bash" 12 minutes ago Exited (137) 6 minutes ago python_box

The container exists with an `Exited (137)` status, which is why we ran into the naming problem when we tried to create a new container with the same name.

When you want to completely remove a container, you use the `docker rm` command. Execute this command in your terminal:

    docker rm python_box

Once again, Docker outputs the name of the container that was just removed:

    Outputpython_box

**Warning** : This command will fail and output an error message if the container is still running, so make sure you stop or kill it first.

Let’s create a new container named `python_box` now that we removed the previous one:

    docker run --name python_box -ti my_image bash

The process completes and we are once again presented with a root shell:

    

Now let’s kill and remove the container so we avoid problems in the future. From another Terminal session on the Docker host, kill the container and remove it with the following command:

    docker kill python_box && docker rm python_box

We chained two commands together, so the output shows the container name twice. The first output verifies we’ve killed the container, and the other confirms that we’ve removed it.

    Outputpython_box
    python_box

Keep `docker ps -a` in mind when experiencing issues with names and make sure that your containers are stopped and removed before you try to recreate them with the same name.

Naming containers makes it easier for you to manage your infrastructure. Names also make it easy to communicate between containers, as you’ll see next.

## Step 3 — Resolving Container Communication Issues

Docker makes it easy to instantiate several containers so you can run different or even redundant services in each one. If a service fails or gets compromised, you can just replace it with a new one while keeping the rest of the infrastructure intact. But you may run into issues making those containers communicate with each other.

Let’s create two containers that communicate so we can explore potential communication issues. We’ll create one container running Python using our existing image, and another container running an instance of PostgreSQL. We’ll use the official PostgreSQL image available from [Docker Hub](http://dockerhub.com) for that container.

Let’s create the PostgreSQL container first. We’ll give this container a name by using the `--name` flag so that we can identify it easily when linking it with other containers. We’ll call it `postgres_box`.

Previously, when we launched a container, it ran in the foreground, taking over our terminal. We want to start the PostgreSQL database container in the background, which we can do with the `--detach` flag.

Finally, instead of running `bash`, we’ll run the `postgres` command which will start the PostgreSQL database server inside of the container.

Execute the following command to launch the container:

    docker run --name postgres_box --detach postgres

Docker will download the image from Docker Hub and create the container. It’ll then return the full ID of the container running in the background:

    OutputUnable to find image 'postgres:latest' locally
    latest: Pulling from library/postgres
    6a5a5368e0c2: Already exists
    193f770cec44: Pull complete
    ...
    484ac0d6f901: Pull complete
    Digest: sha256:924650288891ce2e603c4bbe8491e7fa28d43a3fc792e302222a938ff4e6a349
    Status: Downloaded newer image for postgres:latest
    f6609b9e96cc874be0852e400381db76a19ebfa4bd94fe326477b70b8f0aff65

List the containers to make sure this new container is running:

    docker ps

The output confirms that the `postgres_box` container is running in the background, exposing port `5432`, the PostgreSQL database port:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    7a230b56cd64 postgres_box "/docker-entrypoint.s" Less than a second ago Up 2 seconds 5432/tcp postgres

Now let’s launch the Python container. In order for the programs running inside of the Python container to “see” services in the `postgres_box` container, we need to manually link our Python container to the `postgres_box` container by using the `--link` argument. To create the link, we specify the name of the container, followed by the name of the link. We’ll use the link name to refer to the `postgres_box` container from inside the Python container.

Issue the following command to start the Python container:

    docker run --name python_box --link postgres_box:postgres -ti my_image bash

Now let’s try to connect to PostgreSQL from inside the `python_box` container.

We previously installed `nano` inside of the `python_box` container so let’s use it to create a simple Python script to test the connection to PostgreSQL. In the terminal for the `python_box` container, execute this command:

    nano pg_test.py

Then add the following Python script to the file:

pg\_test.py

    """Test PostgreSQL connection."""
    import psycopg2
    
    conn = psycopg2.connect(user='postgres')
    print(conn)

Save the file and exit the editor. Let’s see what happens when we try to connect to the database from our script. Execute the script in your container:

    python3 pg_test.py

The output we see indicates there’s an issue connecting to the database:

    OutputTraceback (most recent call last):
      File "pg_test.py", line 5, in <module>
        conn = psycopg2.connect(database="test", user="postgres", password="secret")
      File "/usr/lib/python3/dist-packages/psycopg2/ __init__.py", line 164, in connect
        conn = _connect(dsn, connection_factory=connection_factory, async=async)
    psycopg2.OperationalError: could not connect to server: No such file or directory
        Is the server running locally and accepting
        connections on Unix domain socket "/var/run/postgresql/.s.PGSQL.5432"?

We’ve ensured the `postgres_box` container is running and we’ve linked it to the `python_box` container, so then what happened? Well, we never specified the database host when we tried to connect, so Python tries to connect to a database running locally, and that won’t work because the service isn’t running locally, it is running in a different container just as if it was on a different computer.

You can access the linked container using the name you set up when you created the link. In our case, we use `postgres` to reference the `postgres_box` container that’s running our database server. You can verify this by viewing the `/etc/hosts` file within the `python_box` container:

    cat /etc/hosts

You will see all of the available hosts with their names and IP addresses. Our `postgres` server is clearly visible.

    Output127.0.0.1 localhost
    ::1 localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    172.17.0.2 postgres f6609b9e96cc postgres_box
    172.17.0.3 3053f74c8c13

So let’s modify our Python script and add the hostname. Open the file.

    nano pg_test.py

Then specify the host in the connection string:

/pg\_test.py

    """Test PostgreSQL connection."""
    import psycopg2
    
    conn = psycopg2.connect(host='postgres', user='postgres')
    print(conn)

Save the file and then run the script again.

    python3 pg_test.py

This time the script completes without any errors:

    Output<connection object at 0x7f64caec69d8; dsn: 'user=postgres host=7a230b56cd64', closed: 0>

Keep container names in mind when you’re trying to connect to services in other containers, and edit your application credentials to reference the linked names of those containers.

## Conclusion

We just covered the most common issues you may encounter when working with Docker containers, from building images to deploying a network of containers.

Docker has a `--debug` flag which is intended mainly for Docker developers. However, if want to know more about Docker internals, try running Docker commands in debug mode for more verbose output:

    docker -D [command] [arguments]

While containers in software have existed for some time, Docker itself has existed for only three years and can be quite complex. Take your time to get familiar with the terms and [the ecosystem](https://www.digitalocean.com/community/tutorial_series/the-docker-ecosystem), and you’ll see how some concepts that were a bit foreign at first will soon make a lot of sense.
