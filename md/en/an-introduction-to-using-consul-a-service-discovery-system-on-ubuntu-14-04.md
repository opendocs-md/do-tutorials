---
author: Justin Ellingwood
date: 2014-08-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-using-consul-a-service-discovery-system-on-ubuntu-14-04
---

# An Introduction to Using Consul, a Service Discovery System, on Ubuntu 14.04

## Introduction

**Consul** is a distributed, highly available, datacenter-aware, service discovery and configuration system. It can be used to present services and nodes in a flexible and powerful interface that allows clients to always have an up-to-date view of the infrastructure they are a part of.

Consul provides many different features that are used to provide consistent and available information about your infrastructure. This includes service and node discovery mechanisms, a tagging system, health checks, consensus-based election routines, system-wide key/value storage, and more. By leveraging consul within your organization, you can easily build a sophisticated level of awareness into your applications and services.

In this guide, we will introduce you to some of the basics of using consul. We will cover the general procedures necessary to get consul running on your servers to test it out. In the next guide, we will focus on setting up consul in a production environment.

## Prerequisites and Goals

In this guide, we will be getting familiar with using consul to build out a system of service discovery and configuration for your infrastructure.

For our demonstration, we will be configuring three servers and one client. Servers are used to handle queries and maintain a consistent view of the system. The client is also a member of the system, and can connect to the servers for information about the infrastructure. Clients may also contain services that will be monitored by consul.

For the purposes of this guide, and this series as a whole, we will be configuring 4 computers. The first three will be **consul servers** as described above. The last one will be a **consul agent** that acts as a client and can be used to query information about the system.

For us to implement some of the security mechanisms at a later point, we need to name all of our machines within a single domain. This is so that we can leverage a wildcard SSL certificate in the future.

The details of our machines are here:

| Hostname | IP Address | Role |
| --- | --- | --- |
| server1.example.com | 192.0.2.1 | bootstrap consul server |
| server2.example.com | 192.0.2.2 | consul server |
| server3.example.com | 192.0.2.3 | consul server |
| agent1.example.com | 192.0.2.50 | consul client |

We will be using 64-bit Ubuntu 14.04 servers for this demonstration, but any modern Linux server should work equally well.

## Downloading and Installing Consul

The first step that we need to take is to download and install the consul software on each of our machines. The following steps should be taken on _each_ of the machines listed above. You should be logged in as root.

Before we look into the consul application, we need to get `unzip` to extract the executable. We will also use the `screen` application to allow us to easily have multiple sessions in a single terminal window. This is useful for our introduction, since consul typically takes up the entire screen when not run as a service.

Update the local systems package cache and then install the package using `apt`:

    apt-get update
    apt-get install unzip screen

So we do not forget to do so later, start your screen session now:

    screen

Press enter if you get a copyright message. You will be dropped back into a terminal window, but you are now inside a screen session.

Now, we can go about getting the consul program. The [consul project’s page](http://www.consul.io/downloads.html) provides download links to binary packages for Windows, OS X, and Linux.

Go to the page above and right-click on the operating system and architecture that represents your servers. In this guide, since we are using 64-bit servers, we will use the “amd64” link under “linux”. Select “copy link location” or whatever similar option your browser provides.

In your terminal, move to the `/usr/local/bin` directory, where we will keep the executable. Type `wget` and a space, and then paste the URL that you copied from the site:

    cd /usr/local/bin
    wget https://dl.bintray.com/mitchellh/consul/0.3.0_linux_amd64.zip

Now, we can extract the binary package using the `unzip` command that we installed earlier. We can then remove the zipped file:

    unzip *.zip
    rm *.zip

You should now have the `consul` command available on all of your servers.

## Starting the Bootstrap Server

To begin working with consul, we need to get our consul servers up and running. When configuring this in the recommended multi-server environment, this step will have to be done in stages.

The first thing we need to do is start the consul program on one of our servers in `server` and `bootstrap` mode. The server mode means that the consul will start up as a server instance instead of a client. The bootstrap option is used for the first server. This allows it to designate itself as the “leader” for the cluster without an election (since it will be the only server available).

In the table that specifies our hosts, we designated our `server1` as the bootstrap server. On server1, start the bootstrap instance by typing:

    consul agent -server -bootstrap -data-dir /tmp/consul

The server will start up in the current terminal and log data will be output as events occur. Towards the end of the log data, you will see these lines:

    . . .
    2014/07/07 14:32:15 [ERR] agent: failed to sync remote state: No cluster leader
    2014/07/07 14:32:17 [WARN] raft: Heartbeat timeout reached, starting election
    2014/07/07 14:32:17 [INFO] raft: Node at 192.0.2.1:8300 [Candidate] entering Candidate state
    2014/07/07 14:32:17 [INFO] raft: Election won. Tally: 1
    2014/07/07 14:32:17 [INFO] raft: Node at 192.0.2.1:8300 [Leader] entering Leader state
    2014/07/07 14:32:17 [INFO] consul: cluster leadership acquired
    2014/07/07 14:32:17 [INFO] consul: New leader elected: server1.example.com
    2014/07/07 14:32:17 [INFO] consul: member 'server1.example.com' joined, marking health alive

As you can see, no cluster leader was found since this is the initial node. However, since we enabled the bootstrap option, this server was able to enter the leader state by itself in order to initiate a cluster with a single host.

## Starting the Other Servers

On `server2` and `server3`, we can now start the consul service _without_ the bootstrap option by typing:

    consul agent -server -data-dir /tmp/consul

For these servers, you will also see the log entries. Towards the end, you will see messages like this:

    . . .
    2014/07/07 14:37:25 [ERR] agent: failed to sync remote state: No cluster leader
    2014/07/07 14:37:27 [WARN] raft: EnableSingleNode disabled, and no known peers. Aborting election.
    2014/07/07 14:37:53 [ERR] agent: failed to sync remote state: No cluster leader

This happens because it cannot find a cluster leader and is not enabled to become the leader itself. This state occurs because our second and third server are enabled, but none of our servers are connected with each other yet.

To connect to each other, we need to join these servers to one another. This can be done in any direction, but the easiest is from the our `server1` machine.

Since we are running the consul server in the current terminal window of `server1`, we will have to create another terminal with `screen` in order to do additional work. Create a new terminal window within the existing screen session of `server1` by typing:

    CTRL-A C

This will open a fresh terminal instance while keeping our previous session running. You can step through each of the existing terminal sessions by typing:

    CTRL-A N

Back in your fresh terminal, join the other two instances by referencing their IP addresses like this:

    consul join 192.0.2.2 192.0.2.3

This should instantly join all three servers into the same cluster. You can double check this by typing:

    consul members

    Node Address Status Type Build Protocol
    server1.example.com 192.0.2.1:8301 alive server 0.3.0 2
    server2.example.com 192.0.2.2:8301 alive server 0.3.0 2
    server3.example.com 192.0.2.3:8301 alive server 0.3.0 2

You can get this information from any of the other servers as well by creating a new terminal session in screen as we described above and issuing the same command.

## Removing the Bootstrap Server and Re-Joining as a Regular Server

We have all three of our servers joined in a cluster, but we are not done yet.

Currently, since `server1` was started in bootstrap mode, it has the power to make decisions without consulting the other servers. Since they are supposed to operate as equals and make decisions by quorum, we want to remove this privilege after the cluster has been bootstrapped.

To do this, we need to stop the consul service on `server1`. This will allow the remaining machines to select a new leader. We can then restart the consul service on `server1` without the bootstrap option and rejoin the cluster.

On server1, switch back to the terminal running consul:

    CTRL-A N

Stop the service by typing:

    CTRL-C

Now, restart the service without the bootstrap option:

    consul agent -server -data-dir /tmp/consul

Switch back to your open terminal and rejoin the cluster by connecting with one of the two servers in the cluster:

    CTRL-A N
    consul join 192.0.2.2

You should now have your three servers available in equal standing. They will replicate information to each other and will handle situations where a single server becomes unavailable. Additional servers can now join the cluster as well by simply starting the server without bootstrap and joining the cluster.

## Joining the Cluster as a Client and Serving the Web UI

Now that the server cluster is available, we can go ahead and connect using the client machine.

We are going to put the consul web UI on our client machine so that we can interact with the cluster and monitor its health. To do this, [visit the download page for the web UI](http://www.consul.io/downloads_web_ui.html). Right-click on the download button and select “copy link location” or whatever similar option you have available.

On your client machine, change into your home directory. Type `wget` and a space and then paste the URL you copied from the page:

    cd ~
    wget https://dl.bintray.com/mitchellh/consul/0.3.0_web_ui.zip

When the download is complete, unzip and delete the archive:

    unzip *.zip
    rm *.zip

There will be a directory called `dist` that contains all of the files necessary to render the consul web UI. We just need to specify this directory when we are connecting to the cluster.

To connect to the cluster, we will use a similar call to consul agent that we used for the servers. We will use different flags however.

We will not use the `server` flag, since we want to operate in client mode. By default, each node’s client interface is accessible using the local loopback interface. Since we want to access the web UI remotely, we’ll have to specify the public IP address of the client instead.

We’ll have to point consul to the directory that houses the web UI in order to serve that content. Additionally, we’re going to join the cluster right away by passing the IP address of one of the servers in the cluster. This will allow us to avoid having to join afterwards. We could have done this earlier with the server examples as well.

In the end, our connection command is quite long. It will look like this:

    consul agent -data-dir /tmp/consul -client 192.0.2.50 -ui-dir /home/your_user/dir -join 192.0.2.1

This will connect our client machine to the cluster as a regular, non-server agent. This agent will respond to requests on its public IP address instead of the usual `127.0.0.1` interface. Because of this, you will need to add an additional flag to any consul commands specifying the `rpc-addr`.

For instance, if you want to query the list of members from the client, you’ll have to do so by passing in the alternative interface and port that you selected:

    consul members -rpc-addr=192.0.2.50:8400

    Node Address Status Type Build Protocol
    agent1 192.0.2.50:8301 alive client 0.3.0 2
    server2 192.0.2.2:8301 alive server 0.3.0 2
    server1 192.0.2.1:8301 alive server 0.3.0 2
    server3 192.0.2.3:8301 alive server 0.3.0 2

This may seem like a hassle, but it provides us with the opportunity to access the consul web interface. You can get to the web interface by visiting your client’s IP address, followed by `:8500/ui` in your web browser:

    http://192.0.2.50:8500/ui

The main interface will look like this:

![Consul web UI landing page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/consul_intro/consul_default.png)

You can click through various menus and explore the interface. This provides you with a good way to visualize your cluster and the health of your machines and services.

## Adding Services and Checks

Now, we want to add services to consul, which is the primary use-case for setting this up. You can add services in a number of ways, but the easiest is to create a configuration directory to store your service definitions.

A service is associated with the node that contains the service definition. So if we have a web server, we should install the consul agent on that server and create a service definition file there.

For our purposes, we’ll install Nginx on our client to demonstrate this. Kill the current client session by typing:

    CTRL-C

Install Nginx on the client by typing:

    apt-get install nginx

Now, we can create a configuration directory to store our service definitions:

    mkdir ~/services

Inside this directory, we will create a JSON file that describes our web service. We will call this `web.json`:

    nano ~/services/web.json

Inside this file, we need include a structure for our service definition. Within this structure, we’ll define a sub-structure for a health check of the service in order for us to reliably be able to tell whether its running or not.

The basic outline looks like this:

    {
        "service": {
            . . .
            "check": {
                . . .
            }
        }
    }

For the service, we need to define a name for the service and tell consul what port it should be checking. Additionally, we can give it a list of tags that we can use to arbitrarily categorize the service for our own sorting purposes.

For our example, this looks like this:

    {
        "service": {
            "name": "web server",
            "port": 80,
            "tags": ["nginx", "demonstration"],
            "check": {
                . . .
            }
        }
    }

This is all we need to define the service itself. However, we also want to define a method by which consul can verify the health of the service. This is usually fairly simple and will replicate a normal system administrator’s manual checks.

For our service, we will implement a simple web request with `curl` as the consul project lists in [its own documentation](http://www.consul.io/intro/getting-started/checks.html). We don’t actually need to know what curl is able to retrieve, we only care about whether the command was able to execute without any errors. Because of this, we can throw away any output.

We also need to set the interval at which the check will be run. This is always a compromise between performance and up-to-date information. We’ll use 10 seconds, since we want to know relatively soon if something is wrong:

    {
        "service": {
            "name": "web server",
            "port": 80,
            "tags": ["nginx", "demonstration"],
            "check": {
                "script": "curl localhost:80 > /dev/null 2>&1",
                "interval": "10s"
            }
        }
    }

Save and close the file when you are finished.

Now, we can simply restart the client consul session, and point to this directory as having service definitions:

    consul agent -data-dir /tmp/consul -client 192.0.2.50 -ui-dir /home/your_user/dist -join 192.0.2.1 -config-dir /home/your_user/services

This will restart the node and connect it to the cluster. If you return to the web interface, you should now now see a service:

![Consul intro service](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/consul_intro/service.png)

Back on your client, you can create a new terminal and temporarily stop the web server:

    CTRL-A C
    service nginx stop

When you refresh the web UI, you can see that web service check is now failing, as expected:

![Consul intro failed service](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/consul_intro/failed_service.png)

This shows that our health check is working as expected.

## Conclusion

You should now have a basic idea of how consul works. The demonstration we have provided in this guide is not exactly the best way to handle consul in production, but was used to let you see the useful features of the software quickly.

In the [next guide](how-to-configure-consul-in-a-production-environment-on-ubuntu-14-04), we’ll cover how to use consul in a production environment. We will put all of our configuration details in files for easy reference and create upstart scripts to start the service at boot.
