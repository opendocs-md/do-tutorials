---
author: finid
date: 2016-05-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
---

# How To Install and Use Docker on Ubuntu 16.04

## Introduction

Docker is an application that makes it simple and easy to run application processes in a container, which are like virtual machines, only more portable, more resource-friendly, and more dependent on the host operating system. For a detailed introduction to the different components of a Docker container, check out [The Docker Ecosystem: An Introduction to Common Components](the-docker-ecosystem-an-introduction-to-common-components).

There are two methods for installing Docker on Ubuntu 16.04. One method involves installing it on an existing installation of the operating system. The other involves spinning up a server with a tool called [Docker Machine](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04) that auto-installs Docker on it.

In this tutorial, you’ll learn how to install and use it on an existing installation of Ubuntu 16.04.

## Prerequisites

To follow this tutorial, you will need the following:

- One Ubuntu 16.04 server set up with a non-root user with sudo privileges and a basic firewall, as explained in the [Initial Setup Guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04)
- An account on [Docker Hub](https://hub.docker.com/) if you wish to create your own images and push them to Docker Hub, as shown in Steps 7 and 8

## Step 1 — Installing Docker

The Docker installation package available in the official Ubuntu 16.04 repository may not be the latest version. To get this latest version, install Docker from the official Docker repository. This section shows you how to do just that.

First, in order to ensure the downloads are valid, add the GPG key for the official Docker repository to your system:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Add the Docker repository to APT sources:

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

Next, update the package database with the Docker packages from the newly added repo:

    sudo apt-get update

Make sure you are about to install from the Docker repo instead of the default Ubuntu 16.04 repo:

    apt-cache policy docker-ce

You should see output similar to the follow:

Output of apt-cache policy docker-ce

    docker-ce:
      Installed: (none)
      Candidate: 18.06.1~ce~3-0~ubuntu
      Version table:
         18.06.1~ce~3-0~ubuntu 500
            500 https://download.docker.com/linux/ubuntu xenial/stable amd64 Packages
    

Notice that `docker-ce` is not installed, but the candidate for installation is from the Docker repository for Ubuntu 16.04 (`xenial`).

Finally, install Docker:

    sudo apt-get install -y docker-ce

Docker should now be installed, the daemon started, and the process enabled to start on boot. Check that it’s running:

    sudo systemctl status docker

The output should be similar to the following, showing that the service is active and running:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-10-18 20:28:23 UTC; 35s ago
         Docs: https://docs.docker.com
     Main PID: 13412 (dockerd)
       CGroup: /system.slice/docker.service
               ├─13412 /usr/bin/dockerd -H fd://
               └─13421 docker-containerd --config /var/run/docker/containerd/containerd.toml

Installing Docker now gives you not just the Docker service (daemon) but also the `docker` command line utility, or the Docker client. We’ll explore how to use the `docker` command later in this tutorial.

## Step 2 — Executing the Docker Command Without Sudo (Optional)

By default, running the `docker` command requires root privileges — that is, you have to prefix the command with `sudo`. It can also be run by a user in the **docker** group, which is automatically created during the installation of Docker. If you attempt to run the `docker` command without prefixing it with `sudo` or without being in the docker group, you’ll get an output like this:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

If you want to avoid typing `sudo` whenever you run the `docker` command, add your username to the `docker` group:

    sudo usermod -aG docker ${USER}

To apply the new group membership, you can log out of the server and back in, or you can type the following:

    su - ${USER}

You will be prompted to enter your user’s password to continue. Afterwards, you can confirm that your user is now added to the `docker` group by typing:

    id -nG

    Outputsammy sudo docker

If you need to add a user to the `docker` group that you’re not logged in as, declare that username explicitly using:

    sudo usermod -aG docker username

The rest of this article assumes you are running the `docker` command as a user in the docker user group. If you choose not to, please prepend the commands with `sudo`.

## Step 3 — Using the Docker Command

With Docker installed and working, now’s the time to become familiar with the command line utility. Using `docker` consists of passing it a chain of options and commands followed by arguments. The syntax takes this form:

    docker [option] [command] [arguments]

To view all available subcommands, type:

    docker

As of Docker 18.06.1, the complete list of available subcommands includes:

    Output
      attach Attach local standard input, output, and error streams to a running container
      build Build an image from a Dockerfile
      commit Create a new image from a container's changes
      cp Copy files/folders between a container and the local filesystem
      create Create a new container
      diff Inspect changes to files or directories on a container's filesystem
      events Get real time events from the server
      exec Run a command in a running container
      export Export a container's filesystem as a tar archive
      history Show the history of an image
      images List images
      import Import the contents from a tarball to create a filesystem image
      info Display system-wide information
      inspect Return low-level information on Docker objects
      kill Kill one or more running containers
      load Load an image from a tar archive or STDIN
      login Log in to a Docker registry
      logout Log out from a Docker registry
      logs Fetch the logs of a container
      pause Pause all processes within one or more containers
      port List port mappings or a specific mapping for the container
      ps List containers
      pull Pull an image or a repository from a registry
      push Push an image or a repository to a registry
      rename Rename a container
      restart Restart one or more containers
      rm Remove one or more containers
      rmi Remove one or more images
      run Run a command in a new container
      save Save one or more images to a tar archive (streamed to STDOUT by default)
      search Search the Docker Hub for images
      start Start one or more stopped containers
      stats Display a live stream of container(s) resource usage statistics
      stop Stop one or more running containers
      tag Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
      top Display the running processes of a container
      unpause Unpause all processes within one or more containers
      update Update configuration of one or more containers
      version Show the Docker version information
      wait Block until one or more containers stop, then print their exit codes

To view the switches available to a specific command, type:

    docker docker-subcommand --help

To view system-wide information about Docker, use:

    docker info

## Step 4 — Working with Docker Images

Docker containers are run from Docker images. By default, it pulls these images from Docker Hub, a Docker registry managed by Docker, the company behind the Docker project. Anybody can build and host their Docker images on Docker Hub, so most applications and Linux distributions you’ll need to run Docker containers have images that are hosted on Docker Hub.

To check whether you can access and download images from Docker Hub, type:

    docker run hello-world

In the output, you should see the following message, which indicates that Docker is working correctly:

    Output...
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    ...

You can search for images available on Docker Hub by using the `docker` command with the `search` subcommand. For example, to search for the Ubuntu image, type:

    docker search ubuntu

The script will crawl Docker Hub and return a listing of all images whose name matches the search string. In this case, the output will be similar to this:

    Output
    NAME DESCRIPTION STARS OFFICIAL AUTOMATED
    ubuntu Ubuntu is a Debian-based Linux operating sys… 8564 [OK]                
    dorowu/ubuntu-desktop-lxde-vnc Ubuntu with openssh-server and NoVNC 230 [OK]
    rastasheep/ubuntu-sshd Dockerized SSH service, built on top of offi… 176 [OK]
    consol/ubuntu-xfce-vnc Ubuntu container with "headless" VNC session… 129 [OK]
    ansible/ubuntu14.04-ansible Ubuntu 14.04 LTS with ansible 95 [OK]
    ubuntu-upstart Upstart is an event-based replacement for th… 91 [OK]                
    neurodebian NeuroDebian provides neuroscience research s… 54 [OK]                
    1and1internet/ubuntu-16-nginx-php-phpmyadmin-mysql-5 ubuntu-16-nginx-php-phpmyadmin-mysql-5 48 [OK]
    ubuntu-debootstrap debootstrap --variant=minbase --components=m… 39 [OK]                
    nuagebec/ubuntu Simple always updated Ubuntu docker images w… 23 [OK]
    tutum/ubuntu Simple Ubuntu docker images with SSH access 18                                      
    i386/ubuntu Ubuntu is a Debian-based Linux operating sys… 14                                      
    1and1internet/ubuntu-16-apache-php-7.0 ubuntu-16-apache-php-7.0 13 [OK]
    ppc64le/ubuntu Ubuntu is a Debian-based Linux operating sys… 12                                      
    eclipse/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 6 [OK]
    1and1internet/ubuntu-16-nginx-php-5.6-wordpress-4 ubuntu-16-nginx-php-5.6-wordpress-4 6 [OK]
    codenvy/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 4 [OK]
    darksheer/ubuntu Base Ubuntu Image -- Updated hourly 4 [OK]
    pivotaldata/ubuntu A quick freshening-up of the base Ubuntu doc… 2                                       
    1and1internet/ubuntu-16-sshd ubuntu-16-sshd 1 [OK]
    smartentry/ubuntu ubuntu with smartentry 1 [OK]
    ossobv/ubuntu Custom ubuntu image from scratch (based on o… 0                                       
    paasmule/bosh-tools-ubuntu Ubuntu based bosh-cli 0 [OK]
    1and1internet/ubuntu-16-healthcheck ubuntu-16-healthcheck 0 [OK]
    pivotaldata/ubuntu-gpdb-dev Ubuntu images for GPDB development 0                                       
    
    

In the **OFFICIAL** column, **OK** indicates an image built and supported by the company behind the project. Once you’ve identified the image that you would like to use, you can download it to your computer using the `pull` subcommand. Try this with the `ubuntu` image, like so:

    docker pull ubuntu

After an image has been downloaded, you may then run a container using the downloaded image with the `run` subcommand. If an image has not been downloaded when `docker` is executed with the `run` subcommand, the Docker client will first download the image, then run a container using it:

    docker run ubuntu

To see the images that have been downloaded to your computer, type:

    docker images

The output should look similar to the following:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest ea4c82dcd15a 16 hours ago 85.8MB
    hello-world latest 4ab4c602aa5e 5 weeks ago 1.84kB

As you’ll see later in this tutorial, images that you use to run containers can be modified and used to generate new images, which may then be uploaded (_pushed_ is the technical term) to Docker Hub or other Docker registries.

## Step 5 — Running a Docker Container

The `hello-world` container you ran in the previous step is an example of a container that runs and exits after emitting a test message. Containers can be much more useful than that, and they can be interactive. After all, they are similar to virtual machines, only more resource-friendly.

As an example, let’s run a container using the latest image of Ubuntu. The combination of the **-i** and **-t** switches gives you interactive shell access into the container:

    docker run -it ubuntu

**Note:** The default behavior for the `run` command is to start a new container. Once you run the preceding the command, you will open up the shell interface of a second `ubuntu` container.

Your command prompt should change to reflect the fact that you’re now working inside the container and should take this form:

    Outputroot@9b0db8a30ad1:/#

**Note:** Remember the container id in the command prompt. In the preceding example, it is `9b0db8a30ad1`. You’ll need that container ID later to identify the container when you want to remove it.

Now you can run any command inside the container. For example, let’s update the package database inside the container. You don’t need to prefix any command with `sudo`, because you’re operating inside the container as the **root** user:

    apt-get update

Then install any application in it. Let’s install Node.js:

    apt-get install -y nodejs

This installs Node.js in the container from the official Ubuntu repository. When the installation finishes, verify that Node.js is installed:

    node -v

You’ll see the version number displayed in your terminal:

    Outputv8.10.0

Any changes you make inside the container only apply to that container.

To exit the container, type `exit` at the prompt.

Let’s look at managing the containers on our system next.

## Step 6 — Managing Docker Containers

After using Docker for a while, you’ll have many active (running) and inactive containers on your computer. To view the **active ones** , use:

    docker ps

You will see output similar to the following:

    OutputCONTAINER ID IMAGE COMMAND CREATED             
    

In this tutorial, you started three containers; one from the `hello-world` image and two from the `ubuntu` image. These containers are no longer running, but they still exist on your system.

To view all containers — active and inactive — run `docker ps` with the `-a` switch:

    docker ps -a

You’ll see output similar to this:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    9b0db8a30ad1 ubuntu "/bin/bash" 21 minutes ago Exited (0) About a minute ago xenodochial_neumann
    d7851eb12e23 ubuntu "/bin/bash" 24 minutes ago Exited (0) 24 minutes ago boring_chebyshev
    d54945b6510b hello-world "/hello" 32 minutes ago Exited (0) 32 minutes ago youthful_roentgen

To view the latest container you created, pass it the `-l` switch:

    docker ps -l

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    9b0db8a30ad1 ubuntu "/bin/bash" 22 minutes ago Exited (127) About a minute ago xenodochial_neumann

To start a stopped container, use `docker start`, followed by the container ID or the container’s name. Let’s start the Ubuntu-based container with the ID of `9b0db8a30ad1`:

    docker start 9b0db8a30ad1 

The container will start, and you can use `docker ps` to see its status:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    9b0db8a30ad1 ubuntu "/bin/bash" 23 minutes ago Up 11 seconds xenodochial_neumann

To stop a running container, use `docker stop`, followed by the container ID or name. This time, we’ll use the name that Docker assigned the container, which is `xenodochial_neumann`:

    docker stop xenodochial_neumann

Once you’ve decided you no longer need a container anymore, remove it with the `docker rm` command, again using either the container ID or the name. Use the `docker ps -a` command to find the container ID or name for the container associated with the `hello-world` image and remove it.

    docker rm youthful_roentgen

You can start a new container and give it a name using the `--name` switch. You can also use the `--rm` switch to create a container that removes itself when it’s stopped. See the `docker run help` command for more information on these options and others.

Containers can be turned into images which you can use to build new containers. Let’s look at how that works.

## Step 7 — Committing Changes in a Container to a Docker Image

When you start up a Docker image, you can create, modify, and delete files just like you can with a virtual machine. The changes that you make will only apply to that container. You can start and stop it, but once you destroy it with the `docker rm` command, the changes will be lost for good.

This section shows you how to save the state of a container as a new Docker image.

After installing Node.js inside the Ubuntu container, you now have a container running off an image, but the container is different from the image you used to create it. But you might want to reuse this Node.js container as the basis for new images later.

To do this, commit the changes to a new Docker image instance using the following command structure:

    docker commit -m "What did you do to the image" -a "Author Name" container-id repository/new_image_name

The **-m** switch is for the commit message that helps you and others know what changes you made, while **-a** is used to specify the author. The `container ID` is the one you noted earlier in the tutorial when you started the interactive Docker session. Unless you created additional repositories on Docker Hub, the repository is usually your Docker Hub username.

For example, for the user **sammy** , with the container ID of `d9b100f2f636`, the command would be:

    docker commit -m "added node.js" -a "sammy" d9b100f2f636 sammy/ubuntu-nodejs

**Note:** When you _commit_ an image, the new image is saved locally, that is, on your computer. Later in this tutorial, you’ll learn how to push an image to a Docker registry like Docker Hub so that it can be assessed and used by you and others.

After that operation is completed, listing the Docker images now on your computer should show the new image, as well as the old one that it was derived from:

    docker images

The output should be similar to this:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/ubuntu-nodejs latest 6a1784a63edf 2 minutes ago 170MB
    ubuntu latest ea4c82dcd15a 17 hours ago 85.8MB
    hello-world latest 4ab4c602aa5e 5 weeks ago 1.84kB

In the above example, **ubuntu-nodejs** is the new image, which was derived from the existing ubuntu image from Docker Hub. The size difference reflects the changes that were made. In this example, the change was that Node.js was installed. Next time you need to run a container using Ubuntu with Node.js pre-installed, you can just use the new image.

You can also build images from a `Dockerfile`, which lets you automate the installation of software in a new image. However, that’s outside the scope of this tutorial.

Now let’s share the new image with others so they can create containers from it.

## Step 8 — Pushing Docker Images to a Docker Repository

The next logical step after creating a new image from an existing image is to share it with a select few of your friends, the whole world on Docker Hub, or another Docker registry that you have access to. To push an image to Docker Hub or any other Docker registry, you must have an account there.

This section shows you how to push a Docker image to Docker Hub. To learn how to create your own private Docker registry, check out [How To Set Up a Private Docker Registry on Ubuntu 14.04](how-to-set-up-a-private-docker-registry-on-ubuntu-14-04).

To push your image, first log into Docker Hub:

    docker login -u docker-registry-username

You’ll be prompted to authenticate using your Docker Hub password. If you specified the correct password, authentication should succeed.

**Note:** If your Docker registry username is different from the local username you used to create the image, you will have to tag your image with your registry username. For the example given in the last step, you would type:

    docker tag sammy/ubuntu-nodejs docker-registry-username/ubuntu-nodejs

Then you can push your own image using:

    docker push docker-registry-username/ubuntu-nodejs

To push the `ubuntu-nodejs` image to the **sammy** repository, the command would be:

    docker push sammy/ubuntu-nodejs

The process may take some time to complete as it uploads the images, but when completed, the output will look like this:

    OutputThe push refers to repository [docker.io/sammy/ubuntu-nodejs]
    1aa927602b6a: Pushed
    76c033092e10: Pushed
    2146d867acf3: Pushed
    ae1f631f14b7: Pushed
    102645f1cf72: Pushed
    latest: digest: sha256:2be90a210910f60f74f433350185feadbbdaca0d050d97181bf593dd85195f06 size: 1362

After pushing an image to a registry, it should be listed on your account’s dashboard, like that shown in the image below.

![New Docker image listing on Docker Hub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_1804/ec2vX3Z.png)

If a push attempt results in the following error, it is likely that you are not logged in:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Log in, then repeat the push attempt.

## Conclusion

In this tutorial, you’ve learned the basics to get you started working with Docker on Ubuntu 16.04. Like most open source projects, Docker is built from a fast-developing codebase, so make a habit of visiting the project’s [blog page](https://blog.docker.com/) for the latest information.

For further exploration, check out the [other Docker tutorials](https://www.digitalocean.com/community/tags/docker?type=tutorials) in the DigitalOcean Community.
