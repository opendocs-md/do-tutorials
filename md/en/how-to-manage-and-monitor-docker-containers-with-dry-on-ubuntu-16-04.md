---
author: C.J. Scarlett
date: 2018-04-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-and-monitor-docker-containers-with-dry-on-ubuntu-16-04
---

# How to Manage and Monitor Docker Containers with dry on Ubuntu 16.04

## Introduction

![dry Monitoring GIF](https://i.imgur.com/5uQQNAa.gif)

[dry](https://moncho.github.io/dry/) is a simple but extensive terminal application built to interact with [Docker](the-docker-ecosystem-an-introduction-to-common-components) containers and their images. Using dry removes the repetition involved when executing routine [Docker Engine commands](how-to-install-and-use-docker-on-ubuntu-16-04), and also provides a more visual alternative to the native Docker CLI.

dry has the ability to quickly start and stop containers, safely or forcefully remove remove Docker images, continuously monitor real-time container processes, and access the outputs of Docker’s `info`, `inspect`, `history`, and `log` commands.

Most commands that can be executed through the official Docker Engine CLI are available more readily in dry, with the same behavior and results. dry additionally has Docker Swarm functionality, providing an outlet to monitor and manage multi-host container setups.

In this tutorial, we will install dry and explore some of its most useful features:

- Interacting with Docker containers, images, and networks,
- Monitoring Docker containers, and
- Optionally, interacting with Docker Swarm nodes and services.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up using the [Initial Server Setup for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- Docker installed, as in [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04).
- Several active Docker containers networked together to test dry against.
  - As an example in this tutorial, we’ll use the WordPress and PHPMyAdmin setup (without the optional step for the document root) from [How To Install Wordpress and PhpMyAdmin with Docker Compose on Ubuntu 14.04](how-to-install-wordpress-and-phpmyadmin-with-docker-compose-on-ubuntu-14-04).
  - Alternatively, you can use your own existing container setup.
- Optionally, Docker Machine on your local computer and a Docker setup that uses Docker Swarm. This is necessary if you try dry’s Swarm features in the last step. You can set this up by following [How To Provision and Manage Remote Docker Hosts with Docker Machine on Ubuntu 16.04](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04) and [How to Create a Cluster of Docker Containers with Docker Swarm and DigitalOcean on Ubuntu 16.04](how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04).

## Step 1 — Installing dry

First, we need to install dry on the Docker server. The latest version of the dry binaries are available on [dry’s GitHub release page](https://github.com/moncho/dry/releases).

Download the latest version of the `dry-linux-amd64` binary, which is `v0.9-beta.3` at publication time.

    wget https://github.com/moncho/dry/releases/download/v0.9-beta.3/dry-linux-amd64

Next, move and rename the new binary file from `dry-linux-amd64` to `/usr/local/bin/dry`.

    sudo mv dry-linux-amd64 /usr/local/bin/dry

`/usr/local/bin` is the standard location used to store binaries for programs local to a server. Moving the dry binary to that directory also gives us the ability to invoke dry on the command line from anywhere within the server because that directory is included in the shell’s [`$PATH` environment variable](how-to-read-and-set-environmental-and-shell-variables-on-a-linux-vps).

Change the binary’s permissions with `chmod` to allow you to execute it.

    sudo chmod 755 /usr/local/bin/dry

You can test that `dry` is now accessible and working correctly by running the program with its `-v` option.

    dry -v

This will return the version number and build details:

    Version Details Outputdry version 0.9-beta.2, build d4d7a789

Now that dry is set up, let’s try using it.

## Step 2 — Interacting with Docker Containers

Run dry to bring up its dashboard in your terminal.

    dry

The top of the dashboard has information on the server and Docker software on it, like the Docker version, the Docker Engine API version, whether the server is a Docker Swarm-enabled worker/manager node, and the hostname and resources of the server.

The bottom of the dashboard has a reference for the navigation keys you can use to access different parts of dry:

    Navigation key options[H]:Help [Q]:Quit | [F1]:Sort [F2]:Toggle Show Containers [F5]:Refresh [%]:Filter |
    [m]:Monitor mode [2]:Images [3]:Networks [4]:Nodes [5]:Services | [Enter]:Commands 

At any time, you can use `F5` to refresh dry’s display if there’s an error with its rendering.

This dashboard itself defaults to the `Containers` listing when you first start dry. This view lets you see the general state of your host’s containers.

If you’re using the example Wordpress, MariaDB, and PHPMyAdmin container stack from the prerequisite tutorials, you’ll see those three newly composed containers listed:

![dry Dashboard Image](https://i.imgur.com/Wjd4PWh.png)

Use the up and down arrows on your keyboard to select the Wordpress container, then press `ENTER`.

This will display some information about the container at the top of the screen, like its port mapping, network links, and network container IP address:

    Wordpress Container Statistics Container Name: wordpress_wordpress_1 ID: f67f9914b57e Status: Up 13 minutes
      Image: wordpress Created: About an hour ago
      Command: docker-entrypoint.sh apache2-foreground
      Port mapping: 0.0.0.0:8080->80/tcp
      Network Name: bridge
      IP Address: 172.17.0.3
      Labels 6

When you select a container, the lower center of the screen will also display a new list of selectable options:

- `Fetch logs`, which is the equivalent of the Docker Engine command [`docker logs`](https://docs.docker.com/engine/reference/commandline/logs/). This is useful for debugging and troubleshooting errors within containers.

- `Kill container`, which you can use if a container is unresponsive and not exiting as it should.

- `Remove container`, which you can use to remove unneeded containers cleanly.

**Warning** : The `Kill container` and `Remove Container` options are issued instantly and have **no confirmation prompts** , so be cautious.

- `Inspect container`, which is the equivalent of [`docker container inspect`](https://docs.docker.com/engine/reference/commandline/container_inspect/).

- `Restart`, which stops and restarts a container. much quicker than typing out the Docker Engine commands [to restart](https://docs.docker.com/engine/reference/commandline/restart/) or [query the status](https://docs.docker.com/engine/reference/commandline/ps/) of a container.

- `Show image history`, which lists the commands that were used to build the container’s image. These “layers” are generated during the image build process and result from commands/actions provided in a [_Dockerfile_](docker-explained-using-dockerfiles-to-automate-building-of-images). With this option, we can see how exactly the container has been generated using the base Docker image.

- `Stats + Top`, which includes information like CPU usage, memory consumption, inbound and outbound network traffic, file-system operation, total process ID’s, and total overall container uptime. It also includes a process list, which is functionally identical to the output of [`top`](how-to-monitor-cpu-use-on-digitalocean-droplets#top).

- `Stop`, which stops a container. You can use `F2` to toggle the containers on the `Containers` view to include `currently stopped and active`, and you can restart a stopped container with the `Restart` option after selecting it.

Press the `ESC` key to return to the root `Containers` section of the dashboard. From here, we’ll look at the `Images` section.

## Step 3 — Interacting with Docker Images

From the `Containers` section, press `2` to access the `Images` section of dry.

![Images Section](https://i.imgur.com/18pFgHi.png)

This section provides easier access to the [`docker image inspect` command](https://docs.docker.com/engine/reference/commandline/image_inspect/). dry has some convenient keyboard shortcuts here as well, which you can see in the navigation bar:

- `CTRL+D` for `Remove Dangling`, “dangling volumes” refers to other container volumes that are no longer referenced by any container, and are thereby redundant. Normally in Docker on the command line this operation would involve the `docker volume rm` command and the `dangling=true` flag, plus the target data volumes. 
- `CTRL+E` for `Remove`, which is the equivalent of [`docker rmi`](https://docs.docker.com/engine/reference/commandline/rmi/) , lets you remove images as long as no containers created from that image are still active and running.
- `CTRL+F` for `Force Remove`, which lets you forcefully remove the highlighted image as if using `docker rmi --force`.
- `I` for `History`, which displays the same data as `Show Image History` in the `Containers` section.

So far, we’ve seen the containers and images sections of dry. The last section to explore is networks.

## Step 4 — Interacting with Docker Networks

From the `Images` section, press `3` to access the `Networks` section.

![Docker Networks Dashboard](https://i.imgur.com/rR874kM.png)

This section is ideal for [verifying network links and the network configuration](https://docs.docker.com/engine/reference/commandline/network_inspect/) of Docker containers.

You can [delete a network from Docker](https://docs.docker.com/engine/reference/commandline/network_rm/) with `CTRL+E`, though you can’t remove predefined default Docker networks like `bridge`. As an example, however, you can try deleting `bridge` anyway by selecting it with the arrow keys and pressing `ENTER`. You’ll see a long piece of output like this:

    Output. . .
        "Containers": {
            "34f8295b39b7c3364d9ceafd4e96194f210f22acc41d938761e1340de7010e05": {
                "Name": "wordpress_wordpress_db_1",
                "EndpointID": "68370df8a13b92f3dae2ee72ff769e5bdc00da348ef3e22fa5b8f7e9e979dbd5",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            },
            "e7105685e0e6397fd762949e869095aa4451a26cdacdad7f5e177bde52819c4a": {
                "Name": "wordpress_wordpress_1",
                "EndpointID": "44ea3a133d887c5352b8ccf70c94cda9f05891b2db8b99a95096a19d4a504e16",
                "MacAddress": "02:42:ac:11:00:04",
                "IPv4Address": "172.17.0.4/16",
                "IPv6Address": ""
            },
            "e7d65c76b50ff03fc50fc374be1fa4bf462e9454f8d50c89973e1e5693eef559": {
                "Name": "wordpress_phpmyadmin_1",
                "EndpointID": "7fb1b55dd92034cca1dd65fb0c824e87a9ba7bbc0860cd3ed34744390d670b78",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            }
        },
    . . .

The portion of the output above shows the network IP addresses and MAC addresses of the container links and container `bridge` network. From this, you can verify that all of the containers are members of the `bridge` network and can communicate, which is a basic indication that the container network is valid.

Use `ESC` to close the network output. Now that we’ve looked at the `Containers`, `Images`, and `Networks` sections of dry, let’s move on to dry’s monitoring functionality.

## Step 5 — Monitoring Docker Containers

Press the `M` key for a quick condensed overview of all of your running containers on the current server/host. This screen can be accessed from any of the root sections of dry, like `Containers`, `Images`, and `Networks`.

![Monitor Mode Image](https://i.imgur.com/L7cEJ1L.png)

Portions of this information are listed elsewhere in the program (such as inside the `Stats + Top` container options) but this view provides a central location for information on all containers, which allows you to monitor the entire stack. This is useful when managing larger quantities of containers.

Press `Q` to exit the dashboard. From here, we’ll set up dry with Docker Swarm.

## Step 6 — Installing dry on the Docker Swarm Cluster Manager (Optional)

From your local computer, user `docker-machine` to SSH into your designated cluster manager node. In the prerequisite tutorial for Docker Swarm, this was set as `node-1`.

    docker-machine ssh node-1

To demonstrate another method of installing dry, `curl` the official installation script and run it. If you prefer to avoid the `curl ... | sh` pattern, you can install dry as in Step 1.

    curl -sSf https://moncho.github.io/dry/dryup.sh | sh

The installation script will automatically move the dry binary to `/usr/local/bin`:

    Outputdryup: Moving dry binary to its destination
    dryup: dry binary was copied to /usr/local/bin, now you should 'sudo chmod 755 /usr/local/bin/dry'

Update the permissions on the binary, like we did in Step 1.

    sudo chmod 755 /usr/local/bin/dry

Now try running dry.

    dry

At the top right hand side of the initial `Containers` section, the `Swarm` and `Node role` status lines that were blank in earlier steps are now populated:

    OutputSwarm: active                                                                       
    Node role: manager                                                                     
    Nodes: 3         

You’ll also see two containers with long images names listed. The other three containers are spread out among the other Swarm worker nodes, and were defined by the `webserver` example service from the prerequisite tutorial.

The cluster manager’s dry installation is ready, so let’s see how dry works with Docker Swarm next.

## Step 7 — Interacting with Docker Swarm Nodes (Optional)

From the `Containers` section, press `4` to navigate to the `Nodes` section.

![Dashboard Nodes Section](https://i.imgur.com/9q4uXRr.png)

This section shows some useful metrics for each node, like its role (manager or work), status, and availability. The line at the top of the screen shows resource consumption information.

From here, use the arrow keys to select `node-2`, then press `ENTER`. This will pull up the individual node’s tasks:

![node-2 Tasks Dashboard](https://i.imgur.com/lZeJ9pN.png)

In terms of the `webserver` service, `node-2` holds the first and second of the five networked containers. The tasks in this view shows that the `CURRENT STATE` of the two containers is active, and lists how long they’ve been running. The numbering of your own container names here may vary. It depends upon which worker node the containers are allocated to, which is determined by the [the Docker service command.](https://docs.docker.com/engine/reference/commandline/service_create/)

Return to the `Nodes` section by pressing `ESC` so we can explore some of dry’s keybindings here.

A common task when using Docker Swarm is changing the state, or availability, of certain nodes. Highlight `node-1` again and press `CTRL+A` to see the `Set Availability` prompt.

    OutputChanging node availability, please type one of ('active'|'pause'|'drain')

Type `drain` and confirm it with `ENTER`.

The drain option prevents a node from receiving new directions from the Swarm cluster manager, and is typically used for planned miantenance. Using drain also means the node manager launches a replica on a separate node set to active availability which compensates for the temporary downtime of the drained node.

When you submit the `drain` command, the status message in the top left will confirm the action:

You’ll see in the status message that appears at the top left, a confirmation of this action. This change is reflected in the `AVAILABILITY` column too:

    OutputNode iujfrchorop9mzsjswrclzcmb availability is now drain

You’ll also notice the change reflected in the `AVAILABILITY` column.

To bring `node-2` back up, highlight it again and press `CTRL+A` to bring the `Set Availability` prompt back. This time, type `active` and press `ENTER`.

You’ll see a confirmation message for this action, too:

    OutputDocker daemon: update wrclzcmb availability is now active 

The option we didn’t use, `pause`, temporarily halts all processes within each container found in the node until they are set as `active` again.

In the last step, we’ll interact with Docker Swarm services in dry.

## Step 8 — Interacting with Docker Swarm Services (Optional)

Press `5` to view the `Services` section of dry.

![Dashboard Services Section](https://i.imgur.com/c7DMszC.png)

The prerequisite tutorial set up only one service, `webserver`, which is set to replicate instances (i.e. create new containers) when necessary up to a maximum of five. This view confirms that `5/5` replicas are active, and shows the port mapping that the service is using as well as its distributed tasks.

We can use dry to see much more detail about the service. Press `ENTER` when the `webserver` service is highlighted.

![Dashboard webserver Task Summary](https://i.imgur.com/Vob3wMS.png)

This detailed service view contains a lot of information about the state of the service and its Swarm nodes.

Interestingly, you might notice that there are seven tasks listed here, despite the service being set to five. This is because Docker Swarm created two extra replica tasks earlier from the test in Step 7, when we switched `node-2` into drain mode.

We can use dry to increase the maximum number of replicas, too. Press `ESC` to return to the `Services` section, then enter `CTRL+S` while highlighting the `webserver` service. This will pull up the scaling prompt:

    OutputScale service. Number of replicas?

In context, scaling this service would be useful to meet any demands for additional resources due to growing web traffic. Let’s increase the number of replicas to 8 by entering `8` in the prompt and pressing `ENTER`.

Check for this confirmation message to confirm the action:

    OutputDocker daemon: update v6gbc1ms0pi scaled to 8 replicas

You can see the `Services` view lists `8/8` replicas for the service now.

If you want to remove a service entirely, highlight it and press `CTRL+R` to pull up the service removal prompt:

    OutputAbout to remove the selected service. Do you want to proceed? y/N

You can use this to remove the `webserver` service if you no longer need or want to run it.

Finally, press `Q` to exit the dashboard and quit the program.

## Conclusion

By following this tutorial, you’ve set up dry on a Docker host and a Docker Swarm cluster manager. This tutorial also covered the essentials of dry’s functionality, like interacting with Docker containers, images, and networks as well as Docker Swarm nodes and services.

There is a secondary method of connecting dry to a remote host running Docker, which is using the `-H` option with the remote host’s IP address when running dry. This is useful in situations where you you’re unable or uninterested in installing the dry binary.

From here, try applying dry to your own Docker setups to explore how it can streamline your workflow. You can explore dry’s extra keybindings in [the GitHub README](https://github.com/moncho/dry#dry-keybinds).
