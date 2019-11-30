---
author: finid
date: 2017-01-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04
---

# How to Create a Cluster of Docker Containers with Docker Swarm and DigitalOcean on Ubuntu 16.04

## Introduction

[Docker Swarm](https://www.docker.com/products/docker-swarm) is the Docker-native solution for deploying a cluster of Docker hosts. You can use it to quickly deploy a cluster of Docker hosts running either on your local machine or on supported cloud platforms.

Before Docker 1.12, setting up and deploying a cluster of Docker hosts required you to use an external key-value store like [etcd](https://coreos.com/etcd/) or [Consul](https://www.consul.io/) for service discovery. With Docker 1.12, however, an external discovery service is no longer necessary, since Docker comes with an in-memory key-value store that works out of the box.

In this tutorial, you’ll learn how to deploy a cluster of Docker machines using the Swarm feature of Docker 1.12 on DigitalOcean. Each Docker node in the cluster will be running Ubuntu 16.04. While you can run a cluster made up of dozens, hundreds, or thousands of Docker hosts, the cluster we’ll be setting up in this tutorial will be made up of a manager node and two worker nodes, for a total of three cluster members. Once you complete this tutorial, you’ll be able to add more nodes to your cluster with ease.

## Prerequisites

For this tutorial, you’ll need:

- A local machine with Docker installed. Your local machine can be running any Linux distribution, or even Windows or macOS. For Windows and macOS, install Docker using the [official installer](https://www.docker.com/products/docker-desktop). If you have Ubuntu 16.04 running on your local machine, but Docker is not installed, see [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04) for instructions.
- A DigitalOcean API token. If you don’t have one, generate it using&nbsp;[this guide](how-to-use-the-digitalocean-api-v2). When you generate a token, be sure that it has read-write scope. That is the default, so if you do not change any option while generating it, it will have read-write capabilities. To make it easier to use on the command line, be sure to assign the token to a variable as given in that article.
- Docker Machine installed on your local computer, which you’ll use to create three hosts. On Windows and macOS, the Docker installation includes Docker Machine. If you’re running Ubuntu 16.04 locally, see [How To Provision and Manage Remote Docker Hosts with Docker Machine on Ubuntu 16.04](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04) for installation instructions.

## Step 1 — Provisioning the Cluster Nodes

We need to create several Docker hosts for our cluster. As a refresher, the following command provisions a single Dockerized host, where `$DOTOKEN` is an environment variable that evaluates to your DigitalOcean API token:

    docker-machine create --driver digitalocean --digitalocean-image ubuntu-16-04-x64 --digitalocean-access-token $DOTOKEN machine-name

Imagine having to do that to set up a cluster made up of at least three nodes, provisioning one host at a time.

We can automate the process of provisioning any number of Docker hosts using this command, combined with some simple Bash scripting. Execute this command on your local machine to create three Docker hosts, named `node-1`, `node-2`, and `node-3`:

    for i in 1 2 3; do docker-machine create --driver digitalocean \
    --digitalocean-image ubuntu-16-04-x64 \
    --digitalocean-access-token $DOTOKEN node-$i; done

After the command has completed successfully, you can verify that all the machines have been created by visiting your DigitalOcean dashboard, or by typing the following command:

    docker-machine ls

The output should be similar to the following, and it should serve as a quick reference for looking up the IP address of the nodes:

    OutputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    node-1 - digitalocean Running tcp://111.111.111.111:2376 v1.12.2   
    node-2 - digitalocean Running tcp://111.111.111.112:2376 v1.12.2   
    node-3 - digitalocean Running tcp://111.111.222.222:2376 v1.12.2

At this point, all three Dockerized hosts have been created, and you have each host’s IP address. They are also all running Docker 1.12.x, but are not yet part of a Docker cluster. In the next steps, we’ll configure the firewall rules that will make the nodes to function as members of a cluster, pick one of the nodes and make it the Docker Swarm manager, and configure the rest as Docker Swarm workers.

## Step 2 — Configuring Firewall Rules to Allow Docker Swarm Traffic

A cluster has to have at least one node that serves as a manager, though for a production setup, three managers are recommended. For this setup, let’s pick the first node and make it the Swarm manager. The other two nodes will be the worker nodes.

Certain network ports must be opened on the nodes that will be be part of a cluster for the cluster to function properly. That entails configuring the firewall to allow traffic through those ports. Because there are three different firewall applications that can be used to accomplish that task, the commands you need to execute on the nodes for each firewall application has been documented in a separate article. Follow [this guide](how-to-configure-the-linux-firewall-for-docker-swarm-on-ubuntu-16-04) and configure the firewalls for each host. Open the proper ports on the manager, then repeat to open the ports on the two client nodes.

After you’ve completed this step, you can initialize the cluster manager.

## Step 3 — Initializing The Cluster Manager

We’ve decided that `node-1` will be our cluster manager, so log in to the node from your local machine:

    docker-machine ssh node-1

The command prompt will change to reflect the fact that you’re now logged into that particular node. To configure the node as the Swarm manager, type the following command:

    docker swarm init --advertise-addr node_ip_address

`node_ip_address` is the IP address of the node. You may get it from the output of `docker-machine ls` or from your DigitalOcean dashboard.

You’ll see output that looks like the following:

    OutputSwarm initialized: current node (a35hhzdzf4g95w0op85tqlow1) is now a manager.
    
    To add a worker to this swarm, run the following command:
    
        docker swarm join \
        --token SWMTKN-1-3k7ighcfs9352hmdfzh31t297fd8tdskg6x6oi8kpzzszznffx-6kovxm3akca2qe3uaxtu07fj3 \
        111.111.111.111:2377
    
    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

Within the output is the ID of the node, which is **a35hhzdzf4g95w0op85tqlow1** in this example, and the instructions on how to add the other nodes to the cluster.

So now you have a Docker Swarm with a manager configured. Let’s add the remaining nodes as workers.

## Step 4 — Adding Nodes to the Cluster

To complete this step, you might want to open another terminal and leave the terminal tab or window you used to log into the Swarm manager alone for now.

First, connect to `node-2` from your local machine:

    docker-machine ssh node-2

Then execute this command, where `your_swarm_token` is the token you received when you created the cluster in the previous step, and `manager_node_ip_address` is the IP of the Swarm manager:

    docker swarm join \
    --token your_swarm_token \
    manager_node_ip_address:2377

After the command has been executed successfully, you’ll see this response:

    OutputThis node joined a swarm as a worker.

Log out of `node-2`, and then repeat this process with `node-3` to add it to your cluster.

You have now added two worker nodes to the cluster. If the firewall rules were configured correctly, you now have a functioning Docker Swarm, with all the nodes synchronized.

## Step 5 — Managing The Cluster

After the manager and worker nodes have been assigned to the cluster, all Docker Swarm management commands have to be executed on the manager nodes. So return to the terminal that you used to add the manager and type in this command to view all members of the cluster:

    docker node ls

The output should be similar to this:

    OutputID HOSTNAME STATUS AVAILABILITY MANAGER STATUS
    2qhg0krj00i4d3as2gpb0iqer node-2 Ready Active        
    6yqh4bjki46p5uvxdw6d53gc0 node-3 Ready Active        
    a35hhzdzf4g95w0op85tqlow1 * node-1 Ready Active Leader

This output shows that we’re dealing with a 3-node Docker Swarm and its nodes — a manager and two workers. To view the other management commands that you can run on the manager node, type:

    docker node --help

For detailed information about the cluster, you may use the following command on the manager or workers (it’s a generic Docker command):

    docker info

The output should be of this sort, and should indicate the status of the cluster ( **active** or **pending** ), the number of nodes in the cluster, and whether the particular node is a manager or worker.

    Output...
    
    Network: bridge host null overlay
    Swarm: active
     NodeID: a35hhzdzf4g95w0op85tqlow1
     Is Manager: true
     ClusterID: f45u0lh7ag4qsl4o56yfbls31
     Managers: 1
     Nodes: 3
     Orchestration:
      Task History Retention Limit: 5
     Raft:
      Snapshot Interval: 10000
      Heartbeat Tick: 1
      Election Tick: 3
     Dispatcher:
      Heartbeat Period: 5 seconds
     CA Configuration:
      Expiry Duration: 3 months
     Node Address: 104.236.239.4
    Runtimes: runc
    Default Runtime: runc
    Security Options: apparmor seccomp
    Kernel Version: 4.4.0-38-generic
    Operating System: Ubuntu 16.04.1 LTS
    OSType: linux
    ...

If you repeat the same command on the worker nodes, the **Is Manager** line should show `false`.

**Tip** : You can add or remove nodes from the cluster at any time. Additionally, a worker node can be promoted to a manager, and manager can be converted to a worker.

Now let’s get a service running on the cluster.

## Step 6 — Running Services in the Docker Swarm

Now that you have a Docker Swarm up and running, let’s run a test container and see how the manager handles it. On a machine running Docker Engine 1.12 or newer, containers are deployed as Services using the `docker service` command. And like the `docker node` command, the `docker service` command can only be executed on a manager node.

So let’s deploy a web server service using the official Nginx container image:

    docker service create -p 80:80 --name webserver nginx

In this command, we’re mapping port `80` in the Nginx container to port `80` on the cluster so that we can access the default Nginx page from anywhere.

To view which services are running on a cluster, type:

    docker service ls

The output should take this form. The **REPLICAS** column shows how many instances of the service are running:

    OutputID NAME REPLICAS IMAGE COMMAND  
    0ymctkanhtc1 webserver 1/1 nginx  

You can determine which nodes the services is running on by using `docker service ps` followed by the service name.

    docker service ps webserver

The output should be similar to the following:

    OutputID NAME IMAGE NODE DESIRED STATE CURRENT STATE ERROR
    39yprxsaaekuif951cl0o4wau webserver.1 nginx node-1 Running Running 7 hours ago   

In this example, the `webserver` service is running on `node-1`. Since that’s a Web server running on the default ports, you can access it by pointing your browser to `http://node-1_ip_address`. Give it a try. You’ll see Nginx’s default page.

With the magic of mesh networking, a service running on a node can be accessed on any other node of the cluster. For example, this Nginx service can also be accessed by pointing your browser to the IP address of any node in the cluster, not just the one it is running on. Give it a try.

Another feature of Docker Swarm is the ability to scale a service, that is, spin up additional instances of a service. Assume that we want to scale the `webserver` service that we started earlier to five instances. To do so, we just type the following command and the system will create four more instances:

    docker service scale webserver=5

And the output of `docker service ps` will show on which nodes the new instances were started:

    OutputID NAME IMAGE NODE DESIRED STATE CURRENT STATE ERROR
    39yprxsaaekuif951cl0o4wau webserver.1 nginx node-1 Running Running 8 hours ago     
    1er2rbrnj6ltanoe47mb653wf webserver.2 nginx node-3 Running Running 14 seconds ago  
    evassgyvruh256ebv5pj3bqcz webserver.3 nginx node-3 Running Running 14 seconds ago  
    d453agrdpgng47klbl6yfjnka webserver.4 nginx node-1 Running Running 18 seconds ago  
    2hsdevx178rg15gqxhzrsnmg6 webserver.5 nginx node-2 Running Running 14 seconds ago

That shows that two of the four new instances were started on `node-3`, one was started on `node-1` and the other started on `node-2`.

Finally, if a service goes down, it’s automatically restarted on the same node or on a different node, if the original node is no longer available.

## Conclusion

You’ve seen how easy it is to set up a Docker Swarm using Docker Engine 1.12 and the new Swarm mode. You’ve also seen how to perform a few management tasks on the cluster. But there’s still more. To view the available Docker Swarm commands, execute the following command on your Swarm manager.

    docker swarm --help

For more information on Docker Swarm, visit the [official documentation page](https://docs.docker.com/engine/swarm/). And be sure to check out other [Docker-related articles](https://www.digitalocean.com/community/tags/docker?type=tutorials) on DigitaloOcean.
