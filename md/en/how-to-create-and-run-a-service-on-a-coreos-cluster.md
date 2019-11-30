---
author: Justin Ellingwood
date: 2014-09-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-and-run-a-service-on-a-coreos-cluster
---

# How To Create and Run a Service on a CoreOS Cluster

## **Status:** Out of Date

This article is no longer current. If you are interested in writing an update for this article, please see [DigitalOcean wants to publish your tech tutorial](https://www.digitalocean.com/community/get-paid-to-write)!

**Reason:** On December 22, 2016, CoreOS announced that it no longer maintains fleet. CoreOS recommends using Kubernetes for all clustering needs.

**See Instead:**  
For guidance using Kubernetes on CoreOS without fleet, see the [Kubernetes on CoreOS Documentation](https://coreos.com/kubernetes/docs/latest/).

## Introduction

One of the major benefits of the CoreOS is the ability to manage services across an entire cluster from a single point. The CoreOS platform provides integrated tools to make this process simple.

In this guide, we will demonstrate a typical work flow for getting services running on your CoreOS clusters. This process will demonstrate some simple, practical ways of interacting with some of CoreOS’s most interesting utilities in order to set up an application.

## Prerequisites and Goals

In order to get started with this guide, you should have a CoreOS cluster with a minimum of three machines configured. You can follow our [guide to bootstrapping a CoreOS cluster](how-to-set-up-a-coreos-cluster-on-digitalocean) here.

For the sake of this guide, our three nodes will be as follows:

- coreos-1
- coreos-2
- coreos-3

These three nodes should be configured using their private network interface for their etcd client address and peer address, as well as the fleet address. These should be configured using the cloud-config file as demonstrated in the guide above.

In this guide, we will be walking through the basic work flow of getting services running on a CoreOS cluster. For demonstration purposes, we will be setting up a simple Apache web server. We will cover setting up a containerized service environment with Docker and then we will create a systemd-style unit file to describe the service and its operational parameters.

Within a companion unit file, we will tell our service to register with etcd, which will allow other services to track its details. We will submit both of our services to fleet, where we can start and manage the services on machines throughout our cluster.

## Connect to a Node and Pass your SSH Agent

The first thing we need to do to get started configuring services is connect to one of our nodes with SSH.

In order for the `fleetctl` tool to work, which we will be using to communicate with neighboring nodes, we need to pass in our SSH agent information while connecting.

Before you connect through SSH, you must start your SSH agent. This will allow you to forward your credentials to the server you are connecting to, allowing you to log in from that machine to other nodes. To start the user agent on your machine, you should type:

    eval $(ssh-agent)

You then can add your private key to the agent’s in memory storage by typing:

    ssh-add

At this point, your SSH agent should be running and it should know about your private SSH key. The next step is to connect to one of the nodes in your cluster and forward your SSH agent information. You can do this by using the `-A` flag:

    ssh -A core@coreos_node_public_IP

Once you are connected to one of your nodes, we can get started building out our service.

## Creating the Docker Container

The first thing that we need to do is create a Docker container that will run our service. You can do this in one of two ways. You can start up a Docker container and manually configure it, or you can create a Dockerfile that describes the steps necessary to build the image you want.

For this guide, we will build an image using the first method because it is more straight forward for those who are new to Docker. Follow this link if you would like to find out more about how to [build a Docker image from a Dockerfile](docker-explained-using-dockerfiles-to-automate-building-of-images). Our goal is to install Apache on an Ubuntu 14.04 base image within Docker.

Before you begin, you will need log in or sign up with the Docker Hub registry. To do this, type:

    docker login

You will be asked to supply a username, password, and email address. If this is your first time doing this, an account will be created using the details you provided and a confirmation email will be sent to the supplied address. If you have already created an account in the past, you will be logged in with the given credentials.

To create the image, the first step is to start a Docker container with the base image we want to use. The command that we will need is:

    docker run -i -t ubuntu:14.04 /bin/bash

The arguments that we used above are:

- **run** : This tells Docker that we want to start up a container with the parameters that follow.
- **-i** : Start the Docker container in interactive mode. This will ensure that STDIN to the container environment will be available, even if it is not attached.
- **-t** : This creates a pseudo-TTY, allowing us terminal access to the container environment.
- **ubuntu:14.04** : This is the repository and image combination that we want to run. In this case, we are running Ubuntu 14.04. The image is kept within the [Ubuntu Docker repository at Docker Hub](https://registry.hub.docker.com/_/ubuntu/).
- **/bin/bash** : This is the command that we want to run in the container. Since we want terminal access, we need to spawn a shell session.

The base image layers will be pulled down from the Docker Hub online Docker registry and a bash session will be started. You will be dropped into the resulting shell session.

From here, we can go ahead with creating our service environment. We want to install the Apache web server, so we should update our local package index and install through `apt`:

    apt-get update
    apt-get install apache2

After the installation is complete, we can edit the default `index.html` file:

    echo "<h1>Running from Docker on CoreOS</h1>" > /var/www/html/index.html

When you are finished, you can exit your bash session in the conventional way:

    exit

Back on your host machine, we need to get the container ID of the Docker container we just left. To do this, we can ask Docker to show the latest process information:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    cb58a2ea1f8f ubuntu:14.04 "/bin/bash" 8 minutes ago Exited (0) 55 seconds ago jovial_perlman

The column that we need is “CONTAINER ID”. In the example above, this would be `cb58a2ea1f8f`. In order to be able to spin up the same container later on with all of the changes that you made, you need to commit the changes to your username’s repository. You will need to select a name for the image as well.

For our purposes, we will pretend that the username is `user_name` but you should substitute this with the Docker Hub account name you logged in with a bit ago. We will call our image `apache`. The command to commit the image changes is:

    docker commit container_ID user_name/apache

This saves the image so that you can recall the current state of the container. You can verify this by typing:

    docker images

    REPOSITORY TAG IMAGE ID CREATED VIRTUAL SIZE
    user_name/apache latest 42a71fb973da 4 seconds ago 247.4 MB
    ubuntu 14.04 c4ff7513909d 3 weeks ago 213 MB

Next, you should publish the image to Docker Hub so that your nodes can pull down and run the image at will. To do this, use the following command format:

    docker push user_name/apache

You now have a container image configured with your Apache instance.

## Creating the Apache Service Unit File

Now that we have a Docker container available, we can begin building our service files.

Fleet manages the service scheduling for the entire CoreOS cluster. It provides a centralized interface to the user, while manipulating each host’s systemd init systems locally to complete the appropriate actions.

The files that define each service’s properties are slightly modified systemd unit files. If you have worked with systemd in the past, you will be very familiar with the syntax.

To start with, create a file called `apache@.service` in your home directory. The `@` indicates that this is a template service file. We will go over what that means in a bit. The CoreOS image comes with the `vim` text editor:

    vim apache@.service

To start the service definition, we will create a `[Unit]` section header and set up some metadata about this unit. We will include a description and specify dependency information. Since our unit will need to be run after both etcd and Docker are available, we need to define that requirement.

We also need to add the other service file that we will be creating as a requirement. This second service file will be responsible for updating etcd with information about our service. Requiring it here will force it into starting when this service is started. We will explain the `%i` in the service name later:

    [Unit]
    Description=Apache web server service
    After=etcd.service
    After=docker.service
    Requires=apache-discovery@%i.service

Next, we need to tell the system what needs to happen when starting or stopping this unit. We do this in the `[Service]` section, since we are configuring a service.

The first thing we want to do is disable the service startup from timing out. Because our services are Docker containers, the first time it is started on each host, the image will have to be pulled down from the Docker Hub servers, potentially causing a longer-than-usual start up time on the first run.

We want to set the `KillMode` to “none” so that systemd will allow our “stop” command to kill the Docker process. If we leave this out, systemd will think that the Docker process failed when we call our stop command.

We will also want to make sure our environment is clean prior to starting our service. This is especially important since we will be referencing our services by name and Docker only allows a single container to be running with each unique name.

We will need to kill any leftover containers with the name we want to use and then remove them. It is at this point that we actually pull down the image from Docker Hub as well. We want to source the `/etc/environment` file as well. This includes variables, such as the public and private IP addresses of the host that is running the service:

    [Unit]
    Description=Apache web server service
    After=etcd.service
    After=docker.service
    Requires=apache-discovery@%i.service
    
    [Service]
    TimeoutStartSec=0
    KillMode=none
    EnvironmentFile=/etc/environment
    ExecStartPre=-/usr/bin/docker kill apache%i
    ExecStartPre=-/usr/bin/docker rm apache%i
    ExecStartPre=/usr/bin/docker pull user_name/apache

The `=-` syntax for the first two `ExecStartPre` lines indicate that those preparation lines can fail and the unit file will still continue. Since those commands only succeed if a container with that name exists, they will fail if no container is found.

You may have noticed the `%i` suffix at the end of the apache container names in the above directives. The service file we are creating is actually a [template unit file](https://github.com/coreos/fleet/blob/master/Documentation/unit-files-and-scheduling.md#template-unit-files). This means that upon running the file, fleet will automatically substitute some information with the appropriate values. Read the information at the provided link to find out more.

In our case, the `%i` will be replaced anywhere it exists within the file with the portion of the service file’s name to the right of the `@` before the `.service` suffix. Our file is simply named `apache@.service` though.

Although we will submit the file to `fleetctl` with `apache@.service`, when we load the file, we will load it as `apache@PORT_NUM.service`, where “PORT\_NUM” will be the port that we want to start this server on. We will be labelling our service based on the port it will be running on so that we can easily differentiate them.

Next, we need to actually start the actual Docker container:

    [Unit]
    Description=Apache web server service
    After=etcd.service
    After=docker.service
    Requires=apache-discovery@%i.service
    
    [Service]
    TimeoutStartSec=0
    KillMode=none
    EnvironmentFile=/etc/environment
    ExecStartPre=-/usr/bin/docker kill apache%i
    ExecStartPre=-/usr/bin/docker rm apache%i
    ExecStartPre=/usr/bin/docker pull user_name/apache
    ExecStart=/usr/bin/docker run --name apache%i -p ${COREOS_PUBLIC_IPV4}:%i:80 user_name/apache /usr/sbin/apache2ctl -D FOREGROUND

We call the conventional `docker run` command and passed it some parameters. We pass it the name in the same format we were using above. We also are going to expose a port from our Docker container to our host machine’s public interface. The host machine’s port number will be taken from the `%i` variable, which is what actually allows us to specify the port.

We will use the `COREOS_PUBLIC_IPV4` variable (taken from the environment file we sourced) to be explicit to the host interface we want to bind. We could leave this out, but it sets us up for easy modification later if we want to change this to a private interface (if we are load balancing, for instance).

We reference the Docker container we uploaded to Docker Hub earlier. Finally, we call the command that will start our Apache service in the container environment. Since Docker containers shut down as soon as the command given to them exits, we want to run our service in the foreground instead of as a daemon. This will allow our container to continue running instead of exiting as soon as it spawns a child process successfully.

Next, we need to specify the command to call when the service needs to be stopped. We will simply stop the container. The container cleanup is done when restarting each time.

We also want to add a section called `[X-Fleet]`. This section is specifically designed to give instructions to fleet as to how to schedule the service. Here, you can add restrictions so that your service must or must not run in certain arrangements in relation to other services or machine states.

We want our service to run only on hosts that are not already running an Apache web server, since this will give us an easy way to create highly available services. We will use a wildcard to catch any of the apache service files that we might have running:

    [Unit]
    Description=Apache web server service
    After=etcd.service
    After=docker.service
    Requires=apache-discovery@%i.service
    
    [Service]
    TimeoutStartSec=0
    KillMode=none
    EnvironmentFile=/etc/environment
    ExecStartPre=-/usr/bin/docker kill apache%i
    ExecStartPre=-/usr/bin/docker rm apache%i
    ExecStartPre=/usr/bin/docker pull user_name/apache
    ExecStart=/usr/bin/docker run --name apache%i -p ${COREOS_PUBLIC_IPV4}:%i:80 user_name/apache /usr/sbin/apache2ctl -D FOREGROUND
    ExecStop=/usr/bin/docker stop apache%i
    
    [X-Fleet]
    X-Conflicts=apache@*.service

With that, we are finished with our Apache server unit file. We will now make a companion service file to register the service with etcd.

## Registering Service States with Etcd

In order to record the current state of the services started on the cluster, we will want to write some entries to etcd. This is known as registering with etcd.

In order to do this, we will start up a minimal companion service that can update etcd as to when the server is available for traffic.

The new service file will be called `apache-discovery@.service`. Open it now:

    vim apache-discovery@.service

We’ll start off with the `[Unit]` section, just as we did before. We will describe the purpose of the service and then we will set up a directive called `BindsTo`.

The `BindsTo` directive identifies a dependency that this service look to for state information. If the listed service is stopped, the unit we are writing now will stop as well. We will use this so that if our web server unit fails unexpectedly, this service will update etcd to reflect that information. This solves potential issue of having stale information in etcd which could be erroneously used by other services:

    [Unit]
    Description=Announce Apache@%i service
    BindsTo=apache@%i.service

For the `[Service]` section, we want to again source the environment file with the host’s IP address information.

For the actual start command, we want to run a simple infinite bash loop. Within the loop, we will use the `etcdctl` command, which is used to modify etcd values, to set a key in the etcd store at `/announce/services/apache%i`. The `%i` will be replaced with the section of the service name we will load between the `@` and the `.service` suffix, which again will be the port number of the Apache service.

The value of this key will be set to the node’s public IP address and the port number. We will also set an expiration time of 60 seconds on the value so that the key will be removed if the service somehow dies. We will then sleep 45 seconds. This will provide an overlap with the expiration so that we are always updating the TTL (time-to-live) value prior to it reaching its timeout.

For the stopping action, we will simply remove the key with the same `etcdctl` utility, marking the service as unavailable:

    [Unit]
    Description=Announce Apache@%i service
    BindsTo=apache@%i.service
    
    [Service]
    EnvironmentFile=/etc/environment
    ExecStart=/bin/sh -c "while true; do etcdctl set /announce/services/apache%i ${COREOS_PUBLIC_IPV4}:%i --ttl 60; sleep 45; done"
    ExecStop=/usr/bin/etcdctl rm /announce/services/apache%i

The last thing we need to do is add a condition to ensure that this service is started on the same host as the web server it is reporting on. This will ensure that if the host goes down, that the etcd information will change appropriately:

    [Unit]
    Description=Announce Apache@%i service
    BindsTo=apache@%i.service
    
    [Service]
    EnvironmentFile=/etc/environment
    ExecStart=/bin/sh -c "while true; do etcdctl set /announce/services/apache%i ${COREOS_PUBLIC_IPV4}:%i --ttl 60; sleep 45; done"
    ExecStop=/usr/bin/etcdctl rm /announce/services/apache%i
    
    [X-Fleet]
    X-ConditionMachineOf=apache@%i.service

You now have your sidekick service that can record the current health status of your Apache server in etcd.

## Working with Unit Files and Fleet

You now have two service templates. We can submit these directly into `fleetctl` so that our cluster knows about them:

    fleetctl submit apache@.service apache-discovery@.service

You should be able to see your new service files by typing:

    fleetctl list-unit-files

    UNIT HASH DSTATE STATE TMACHINE
    apache-discovery@.service 26a893f inactive inactive -
    apache@.service 72bcc95 inactive inactive -

The templates now exist in our cluster-wide init system.

Since we are using templates that depend on being scheduled on specific hosts, we need to load the files next. This will allow us to specify the new name for these files with the port number. This is when `fleetctl` looks at the `[X-Fleet]` section to see what the scheduling requirements are.

Since we are not doing any load balancing, we will just run our web server on port 80. We can load each service by specifying that between the `@` and the `.service` suffix:

    fleetctl load apache@80.service
    fleetctl load apache-discovery@80.service

You should get information about which host in your cluster the service is being loaded on:

    Unit apache@80.service loaded on 41f4cb9a.../10.132.248.119
    Unit apache-discovery@80.service loaded on 41f4cb9a.../10.132.248.119

As you can see, these services have both been loaded on the same machine, which is what we specified. Since our `apache-discovery` service file is bound to our Apache service, we can simply start the later to initiate both of our services:

    fleetctl start apache@80.service

Now, if you ask which units are running on our cluster, we should see the following:

    fleetctl list-units

    UNIT MACHINE ACTIVE SUB
    apache-discovery@80.service 41f4cb9a.../10.132.248.119 active running
    apache@80.service 41f4cb9a.../10.132.248.119 active running

It appears that our web server is up and running. In our service file, we told Docker to bind to the host server’s public IP address, but the IP displayed with `fleetctl` is the private address (because we passed in `$private_ipv4` in the cloud-config when creating this example cluster).

However, we have registered the public IP address and the port number with etcd. To get the value, you can use the `etcdctl` utility to query the values we have set. If you recall, the keys we set were `/announce/services/apachePORT_NUM`. So to get our server’s details, type:

    etcdctl get /announce/services/apache80

    104.131.15.192:80

If we visit this page in our web browser, we should see the very simple page we created:

![CoreOS basic web page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/coreos_basic/web_page.png)

Our service was deployed successfully. Let’s try to load up another instance using a different port. We should expect that the web server and the associated sidekick container will be scheduled on the same host. However, due to our constraint in our Apache service file, we should expect for this host to be _different_ from the one serving our port 80 service.

Let’s load up a service running on port 9999:

    fleetctl load apache@9999.service apache-discovery@9999.service

    Unit apache-discovery@9999.service loaded on 855f79e4.../10.132.248.120
    Unit apache@9999.service loaded on 855f79e4.../10.132.248.120

We can see that both of the new services have been scheduled on the same new host. Start the web server:

    fleetctl start apache@9999.service

Now, we can get the public IP address of this new host:

    etcdctl get /announce/services/apache9999

    104.131.15.193:9999

If we visit the specified address and port number, we should see another web server:

![CoreOS basic web page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/coreos_basic/web_page.png)

We have now deployed two web servers within our cluster.

If you stop a web server, the sidekick container should stop as well:

    fleetctl stop apache@80.service
    fleetctl list-units

    UNIT MACHINE ACTIVE SUB
    apache-discovery@80.service 41f4cb9a.../10.132.248.119 inactive dead
    apache-discovery@9999.service 855f79e4.../10.132.248.120 active running
    apache@80.service 41f4cb9a.../10.132.248.119 inactive dead
    apache@9999.service 855f79e4.../10.132.248.120 active running

You can check that the etcd key was removed as well:

    etcdctl get /announce/services/apache80

    Error: 100: Key not found (/announce/services/apache80) [26693]

This seems to be working exactly as expected.

## Conclusion

By following along with this guide, you should now be familiar with some of the common ways of working with the CoreOS components.

We have created our own Docker container with the service we wanted to run installed inside and we have created a fleet unit file to tell CoreOS how to manage our container. We have implemented a sidekick service to keep our etcd datastore up-to-date with state information about our web server. We have managed our services with fleetctl, scheduling services on different hosts.

In later guides, we will continue to explore some of the areas we briefly touched upon in this article.
