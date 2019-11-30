---
author: finid
date: 2016-05-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-centos-7
---

# How To Provision and Manage Remote Docker Hosts with Docker Machine on CentOS 7

## Introduction

Docker Machine is a tool that makes it easy to provision and manage multiple Docker hosts remotely from your personal computer. Such servers are commonly referred to as Dockerized hosts, and as a matter of course, can be used to run Docker containers.

While Docker Machine can be installed on a local or a remote system, the most common approach is to install it on your local computer (native installation or virtual machine) and use it to provision Dockerized remote servers.

Though Docker Machine can be installed on most Linux distribution as well as on Mac OS X and Windows, in this tutorial, we’ll install it on your local machine running CentOS 7 and use it to provision Dockerized DigitalOcean Droplets.

## Prerequisites

To follow this tutorial, you will need the following:

- A local machine running CentOS 7 with Docker installed. (see [How To Install and Use Docker on CentOS 7](how-to-install-and-use-docker-on-centos-7) for instructions)
- A DigitalOcean API token. If you don’t have one, generate it using [this guide](how-to-use-the-digitalocean-api-v2). When you generate a token, be sure that it has read-write scope. That is the default, so if you do not change any option while generating it, it will have read-write capabilities. And to make it easier to use on the command line, be sure to assign the token to a variable as given in that article.

## Step 1 — Installing Docker Machine on Your Local Computer

n this step, we’ll work through the process of installing Docker Machine on your local computer running CentOS 7.

To download and install the binary, type:

    wget https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-$(uname -s)-$(uname -m)

The name of the file should be `docker-machine-Linux-x86_64`. Rename it to `docker-machine` to make it easier to work with:

    mv docker-machine-Linux-x86_64 docker-machine

Make it executable:

    chmod +x docker-machine

Move or copy it to the `usr/local/bin` directory so that it will be available as a system command.

    sudo mv docker-machine /usr/local/bin

Check the version, which will indicate that it’s properly installed:

    docker-machine version

The output should be similar to

    Outputdocker-machine version 0.14.0, build 89b8332

## Step 2 — Installing Additional Docker Machine Scripts

There are three bash scripts in the Docker Machine GitHub repository designed to facilitate the usage of the `docker` and `docker-machine` commands. They provide command completion and bash-prompt customization.

In this step, we’ll install the three scripts on your local machine. They will be downloaded and installed into the `/etc/bash_completion.d` directory.

The first script makes it possible to see the active machine in your bash prompt. This comes in handy when you working with and switching between multiple Dockerized machines. The script is called `docker-machine-prompt.bash`. To download it, type:

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine-prompt.bash -O /etc/bash_completion.d/docker-machine-prompt.bash

To complete the installation of the above file, you’ll have to set a custom value for the `PS1` variable in your `.bashrc` file. So open it using `nano` (PS1 is a special shell variable used to modify the bash command prompt):

    nano ~/.bashrc

Copy and paste the following line at the end of that file:

~/.bashrc

    export PS1='[\u@\h \W$(__docker_machine_ps1 " [%s]")]\$ '

With this modification to your `~/.bashrc` file, when you activate a machine, its name will be inserted into the shell prompt.

Save and close the file.

The second script is called `docker-machine-wrapper.bash`. It adds a `use` subcommand to the `docker-machine` command, making it easy to switch between Dockerized Machines. To download it, type

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine-wrapper.bash -O /etc/bash_completion.d/docker-machine-wrapper.bash

The third script is called `docker-machine.bash`. It adds bash completion for `docker-machine` commands. Download it using:

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine.bash -O /etc/bash_completion.d/docker-machine.bash

To apply the changes you’ve made so far, close, then reopen your terminal. If you’re logged into the machine via SSH, exit the session and log in again. Command completion for the `docker` and `docker-machine` commands should now be working. If it does not work, it’s likely that the `bash-completion` package is not installed. If that’s the case, install it using:

    sudo yum install bash-completion

That should fix it.

## Step 3 — Provisioning a Dockerized Host Using Docker Machine

Now that you have Docker and Docker Machine running on your local machine, you can now provision a Dockerized Droplet on your DigitalOcean account using Docker Machine’s `docker-machine create` command. If you’ve not done so already, assign your DigitalOcean API token to a bash variable using:

    export shell-variable=your-api-token

**NOTE:** This tutorial uses DOTOKEN as the bash variable for the DO API token. The variable name does not have to be DOTOKEN, and it does not have to be in all caps.

To make the variable permanent, put it in your `~/.bashrc` file. This step is optional, but it is necessary if you want to the value to persist across terminal sessions.

    nano ~/.bashrc

Add a line similar to this anywhere:

    ~/.bashrcexport DOTOKEN=your-api-token

To activate the variable in the current terminal session, type:

    source ~/.bashrc

To call the `docker-machine create` command successfully you must specify (at a minimum) the driver, the API token (or the variable that evaluates to it), and a unique name for the remote host. To create your first Dockerized host, type:

    docker-machine create --driver digitalocean --digitalocean-access-token $DOTOKEN machine-name

Partial output as the host is being created follows. In this output, the name of the host is `centos-docker`:

    Output
     ...
    
    Installing Docker...
    Copying certs to the local machine directory...
    Copying certs to the remote machine...
    Setting Docker configuration on the remote daemon...
    Checking connection to Docker...
    Docker i up and running!
    To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env centos-docker

An SSH key pair is created for the new host so that `docker-machine` can access it remotely. The Droplet is provisioned with the desired operating system, and Docker is installed on the system. When the command is complete, your Docker Droplet is up and running.

To see the newly create host from the command line, type:

    docker-machine ls

The output should be similar to this:

    OutputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    centos-docker - digitalocean Running tcp://203.0.113.71:2376 v18.05.0-ce

## Step 4 — Specify the Base OS When Creating a Dockerized Host

This step shows you how to specify a base OS and version for the Dockerized Host being created with the `--digitalocean-image` flag.

For example, to create a Dockerized host using CentOS 7, type:

    docker-machine create --driver digitalocean --digitalocean-image centos-7-x64 --digitalocean-access-token $DOTOKEN machine-name

What if you would like to run Debian 8 on your server? You would type the following command:

    docker-machine create --driver digitalocean --digitalocean-image debian-8-x64 --digitalocean-access-token $DOTOKEN machine-name

By default, the base operating system used when creating a Dockerized host with Docker Machine is _supposed_ to be the latest version (or the latest LTS version for Ubuntu). However, at the time of this publication, the `docker-machine create` command is still using Ubuntu 16.04 LTS as the base operating system, even though Ubuntu 18.04 is the latest LTS edition. So if you need to run Ubuntu 18.04, you’ll have to specify Ubuntu along with the desired version by passing the `--digitalocean-image` flag to the `docker-machine create` command:

    docker-machine create --driver digitalocean --digitalocean-image ubuntu-18-04-x64 --digitalocean-access-token $DOTOKEN machine-name

The base operating system is not the only choice you have. You can also specify the size of the Droplet. By default, it is the smallest Droplet, which has 1 GB of RAM, a single CPU, and a 25 GB SSD.

Find the size of the Droplet you want to use by looking up the corresponding slug in the [DigitalOcean API documentation](https://developers.digitalocean.com/documentation/v2/#sizes/).

For example, to provision a machine with 2 GB of RAM, two CPUs, and a 60 GB SSD, use the slug `s-2vcpu-2gb`:

    docker-machine create --driver digitalocean --digitalocean-size s-2vcpu-2gb --digitalocean-access-token $DOTOKEN machine-name

To see all the flags specific to creating a Docker Machine using the DigitalOcean driver, type:

    docker-machine create --driver digitalocean -h

**Tip:** If you refresh the Droplet page of your DigitalOcean dashboard, you should see the new hosts you created using the `docker-machine` command.

## Step 5 — Executing Other Docker Machine Commands

You’ve seen how to provision a Dockerized host using the `create` subcommand. You also seen how to list the hosts available to Docker Machine using the `ls` subcommand. In this step, you’ll learn about a few more of the other `docker-machine` subcommands.

To obtain detailed information about a Dockerized host, use the `inspect` subcommand, like so:

    docker-machine inspect machine-name

The output should include lines like these. The **Image** line reveals the version of the Linux distribution used:

    Output{
        "ConfigVersion": 3,
        "Driver": {
            "IPAddress": "203.0.113.71",
            "MachineName": "centos-docker",
            "SSHUser": "root",
            "SSHPort": 22,
            ...
            "Image": "centos-7-0-x64",
            "Size": "s-1vcpu-1gb",
            ...
        },
    
    ---
    

To print the connection configuration for a host, type:

    docker-machine config machine-name

The output should be similar to this:

    Output--tlsverify
    --tlscacert="/home/kamit/.docker/machine/certs/ca.pem"
    --tlscert="/home/kamit/.docker/machine/certs/cert.pem"
    --tlskey="/home/kamit/.docker/machine/certs/key.pem"
    -H=tcp://203.0.113.71:2376

The last line in the output of the `docker-machine config` command reveals the IP address of the host, but you can also get that piece of information by typing:

    docker-machine ip machine-name

If you need to power down a remote host, you can use `docker-machine` to stop it:

    docker-machine stop machine-name

Verify that it is stopped.

    docker-machine ls

The status of the host has changed:

    OuputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    centos-docker digitalocean Timeout

To start it again:

    docker-machine start machine-name

Verify that it is started:

    docker-machine ls

You will see that the `STATE` is now set `Running` for the host:

    OuputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    
    centos-docker - digitalocean Running tcp://203.0.113.71:2376 v18.05.0-ce

Finally, if you want to remove a host:

    docker-machine rm machine-name

## Step 6 — Executing Commands on a Dockerized Host via SSH

At this point, you’ve been getting information about your hosts, but you can do more than that. For example, you can execute native Linux commands on a Docker host by using the `ssh` subcommand of `docker-machine` from your local system. This section explains how to perform `ssh` commands via `docker-machine` as well as how to open an SSH session to a Dockerized host.

Assuming that you’ve provisioned a host with CentOS as the operating system, execute the following command from your local system to update the packages on the Docker host:

    docker-machine ssh machine-name yum update

Not sure what kernel your remote Docker host is using? Type the following:

    docker-machine ssh machine-name uname -r

Besides using the `ssh` subcommand to execute commands on the remote Docker host, you can also use it to log into the Dockerized host itself. That’s as easy as typing:

    docker-machine ssh machine-name

Your command prompt will change to reflect the fact that you’re logged into the remote host:

    root@machine-name#

To exit from the remote host, type:

    exit

## Step 7 — Activating a Dockerized Host

Activating a Docker host connects your local Docker client to that system, which makes it possible to run normal `docker` commands on the remote system. To activate a Docker host, type the following command:

    eval $(docker-machine env machine-name)

Alternatively, you can activate it by using this command:

    docker-machine use machine-name

**Tip** When working with multiple Docker hosts, the `docker-machine use` command is the easiest method of switching from one to the other.

After typing any of the above commands, your bash prompt should change to indicate that your Docker client is pointing to the remote Docker host. It will take this form. The name of the host will be at the end of the prompt:

    username@localmachine:~ [machine-name]$

Now any `docker` command you type at this command prompt will be executed on that remote host.

If a host is active on the terminal that the `docker-machine ls` command is run, the asterisk under the **ACTIVE** column shows that it is the active one.

    Output NAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    centos-docker * digitalocean Running tcp://203.0.113.71:2376 v18.05.0-ce

**NOTE:** When a host is active, any `docker` command you type on the terminal you’re using will be executed on the remote host. However, all normal Linux commands are executed on the local computer.

To exit from the remote Docker host, type the following:

    docker-machine use -u

You will be returned to the prompt for your local system.

Now let’s create containers on the remote machine.

## Step 8 — Creating Docker Containers on a Remote Dockerized Host

So far, you have provisioned a Dockerized Droplet on your DigitalOcean account and you’ve activated it — that is, your Docker client is pointing to it. The next logical step is to spin up containers on it. As an example, let’s try running the official Nginx container.

Use `docker-machine use` to select your remote machine:

    docker-machine use machine-name

Now execute this command to run an Nginx container on that machine:

    docker run -d -p 8080:80 --name httpserver nginx

In this command, we’re mapping port `80` in the Nginx container to port `8080` on the Dockerized host so that we can access the default Nginx page from anywhere.

If the command executed successfully, you will be able to access the default Nginx page by pointing your Web browser to `http://docker_machine_ip:8080`.

While the Docker host is still activated (as seen by its name in the prompt), you should be able to list the images on that host:

    docker images

The output should include the Nginx image you just used, plus others you downloaded before:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    nginx latest ae513a47849c 3 weeks ago 109MB

You can also list the active or running containers on the host:

    docker ps

If the Nginx container you ran in this step is the only active container, the output should look like this:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    4284f9d25548 nginx "nginx -g 'daemon of…" 20 minutes ago Up 20 minutes 0.0.0.0:8080->80/tcp httpserver

To exit the prompt for the remote host, type `exit`. This will close the terminal as well:

    exit

**Tip:** If you intend to create containers on a remote host, your Docker client _must_ be pointing to it — that is, it must be the active host in the terminal that you’re using. Otherwise you’ll be creating the container on your local machine. Let your command prompt be your guide.

## Step 9 — Disabling Crash Reporting (Optional)

By default, whenever an attempt to provision a Dockerized host using Docker Machine fails, or Docker Machine crashes, some diagnostic information is sent automatically to a Docker account on Bugsnag. If you’re not comfortable with this, you can disable the reporting by creating an empty file called `no-error-report` under your installations `.docker/machine` directory.

To accomplish that, simply type:

    touch ~/.docker/machine/no-error-report

Check the file for error messages if provisioning fails or Docker Machine crashes.

## Conclusion

This has been an introduction to installing and using Docker Machine to provision multiple Docker Droplets remotely from one local system. Now you should be able to quickly provision as many Dockerized hosts on your DigitalOcean account as you need.

For more on Docker Machines, visit the [official documentation page](https://docs.docker.com/machine/overview/). The three bash scripts downloaded in this tutorial are hosted on [this GitHub page](https://github.com/docker/machine/tree/master/contrib/completion/bash).
