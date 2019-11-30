---
author: Erika Heidi
date: 2015-12-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-high-availability-setup-with-pacemaker-corosync-and-floating-ips-on-centos-7
---

# How to Create a High Availability Setup with Pacemaker, Corosync and Floating IPs on CentOS 7

## Introduction

Corosync is an open source cluster engine used to implement high availability within applications. Commonly referred to as a **_messaging layer_** , Corosync provides a cluster membership and closed communication model for creating replicated state machines, on top of which cluster resource managers like Pacemaker can run. Corosync can be seen as the underlying system that connects the cluster nodes together, while Pacemaker monitors the cluster and takes action in the event of a failure.

This tutorial will demonstrate how to use Corosync and Pacemaker to create a high availability (HA) infrastructure on DigitalOcean with CentOS 7 servers and Floating IPs. To facilitate the process of setting up and managing the cluster nodes, we are going to use PCS, a command line interface that interacts with both Corosync and Pacemaker.

## Prerequisites

In order to follow this guide, you will need:

- Two CentOS 7 Droplets located in the same datacenter, with [Private Network](how-to-set-up-and-use-digitalocean-private-networking) enabled
- A non-root sudo user, which you can set up by following the [Initial Server Setup](initial-server-setup-with-centos-7) tutorial
- A Personal Access Token to the DigitalOcean API, which you can generate by following the tutorial [How to Use the DigitalOcean API V2](how-to-use-the-digitalocean-api-v2)

When creating these Droplets, use descriptive hostnames to uniquely identify them. For this tutorial, we will refer to these Droplets as **primary** and **secondary**.

When you are ready to move on, make sure you are logged into both of your servers with your `sudo` user.

## Step 1 — Set Up Nginx

To speed things up, we are going to use a simple [shell script](http://do.co/nginx-centos) that installs Nginx and sets up a basic web page containing information about that specific server. This way we can easily identify which server is currently active in our Floating IP setup. The script uses DigitalOcean’s [Metadata service](an-introduction-to-droplet-metadata) to fetch the Droplet’s IP address and hostname.

In order to execute the script, run the following commands on both servers:

    sudo curl -L -o install.sh http://do.co/nginx-centos
    sudo chmod +x install.sh
    sudo ./install.sh

After the script is finished running, accessing either Droplet via its public IP address from a browser should give you a basic web page showing the Droplet’s hostname and IP address.

In order to reduce this tutorial’s complexity, we will be using simple web servers as cluster nodes. In a production environment, the nodes would typically be configured to act as redundant load balancers. For more information about load balancers, check out our [Introduction to HAProxy and Load Balancing Concepts](an-introduction-to-haproxy-and-load-balancing-concepts) guide.

## Step 2 — Create and Assign Floating IP

The first step is to create a Floating IP and assign it to the **primary** server. In the DigitalOcean Control Panel, click **Networking** in the top menu, then **Floating IPs** in the side menu.

You should see a page like this:

![Floating IPs Control Panel](https://assets.digitalocean.com/site/ControlPanel/fip_no_floating_ips.png)

Select your **primary** server and click on the “Assign Floating IP” button. After the Floating IP has been assigned, check that you can reach the **primary** Droplet by accessing the Floating IP address from your browser:

    http://your_floating_ip

You should see the index page of your primary Droplet.

## Step 3 — Create IP Reassignment Script

In this step, we’ll demonstrate how the DigitalOcean API can be used to reassign a Floating IP to another Droplet. Later on, we will configure Pacemaker to execute this script when the cluster detects a failure in one of the nodes.

For our example, we are going to use a basic Python script that takes a Floating IP address and a Droplet ID as arguments in order to assign the Floating IP to the given Droplet. The Droplet’s ID can be fetched from within the Droplet itself using the Metadata service.

Let’s start by downloading the `assign-ip` script and making it executable. Feel free to review the contents of the script before downloading it.

The following two commands should be executed on **both servers** (primary and secondary):

    sudo curl -L -o /usr/local/bin/assign-ip http://do.co/assign-ip
    sudo chmod +x /usr/local/bin/assign-ip

The `assign-ip` script requires the following information in order to be executed:

- **Floating IP** : The first argument to the script, the Floating IP that is being assigned
- **Droplet ID** : The second argument to the script, the Droplet ID that the Floating IP should be assigned to
- **DigitalOcean API Token** : Passed in as the environment variable DO\_TOKEN, your read/write DigitalOcean Personal Access Token

### Testing the IP Reassignment Script

To monitor the IP reassignment taking place, we can use a `curl` command to access the Floating IP address in a loop, with an interval of 1 second between each request.

Open a new local terminal and run the following command, making sure to replace floating\_IP\_address with your actual Floating IP address:

    while true; do curl floating_IP_address; sleep 1; done

This command will keep running in the active terminal until interrupted with a `CTRL+C`. It simply fetches the web page hosted by the server that your Floating IP is currently assigned to. The output should look like this:

    OutputDroplet: primary, IP Address: primary_IP_address
    Droplet: primary, IP Address: primary_IP_address
    Droplet: primary, IP Address: primary_IP_address
    ...

Now, let’s run the `assign-ip` script to reassign the Floating IP to the **secondary** droplet. We will use DigitalOcean’s Metadata service to fetch the current Droplet ID and use it as an argument to the script. Fetching the Droplet’s ID from the Metadata service can be done with:

    curl -s http://169.254.169.254/metadata/v1/id

Where `169.254.169.254` is a static IP address used by the Metadata service, and therefore should not be modified. This information is only available from within the Droplet itself.

Before we can execute the script, we need to set the _DO\_TOKEN_ environment variable containing the DigitalOcean API token. Run the following command from the **secondary** server, and don’t forget to replace your\_api\_token with your read/write Personal Access Token to the DigitalOcean API:

    export DO_TOKEN=your_api_token

Still on the **secondary** server, run the `assign-ip` script replacing floating\_IP\_address with your Floating IP address:

    assign-ip floating_IP_address `curl -s http://169.254.169.254/metadata/v1/id`

    OutputMoving IP address: in-progress

By monitoring the output produced by the `curl` command on your local terminal, you will notice that the Floating IP will change its assigned IP address and start pointing to the **secondary** Droplet after a few seconds:

    OutputDroplet: primary, IP Address: primary_IP_address
    Droplet: primary, IP Address: primary_IP_address
    Droplet: secondary, IP Address: secondary_IP_address

You can also access the Floating IP address from your browser. You should get a page showing the **secondary** Droplet information. This means that the reassignment script worked as expected.

To reassign the Floating IP back to the primary server, repeat the 2-step process but this time from the **primary** Droplet:

    export DO_TOKEN=your_api_token
    assign-ip floating_IP_address `curl -s http://169.254.169.254/metadata/v1/id`

After a few seconds, the Floating IP should be pointing to your primary Droplet again.

## Step 4 — Install Corosync, Pacemaker and PCS

The next step is to get Corosync, Pacemaker and PCS installed on your Droplets. Because Corosync is a dependency to Pacemaker, it’s usually a better idea to simply install Pacemaker and let the system decide which Corosync version should be installed.

Install the software packages on **both servers** :

    sudo yum install pacemaker pcs

The PCS utility creates a new system user during installation, named **_hacluster_** , with a disabled password. We need to define a password for this user on both servers. This will enable PCS to perform tasks such as synchronizing the Corosync configuration on multiple nodes, as well as starting and stopping the cluster.

On **both servers** , run:

    passwd hacluster

You should use the **same password** on both servers. We are going to use this password to configure the cluster in the next step.

The user **_hacluster_** has no interactive shell or home directory associated with its account, which means it’s not possible to log into the server using its credentials.

## Step 5 — Set Up the Cluster

Now that we have Corosync, Pacemaker and PCS installed on both servers, we can set up the cluster.

### Enabling and Starting PCS

To enable and start the PCS daemon, run the following on **both servers** :

    sudo systemctl enable pcsd.service
    sudo systemctl start pcsd.service

### Obtaining the Private Network IP Address for Each Node

For improved network performance and security, the nodes should be connected using the **private network**. The easiest way to obtain the Droplet’s private network IP address is via the Metadata service. On each server, run the following command:

    curl http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address && echo

This command will simply output the private network IP address of the Droplet you’re logged in. You can also find this information on your Droplet’s page at the DigitalOcean Control Panel (under the _Settings_ tab).

Collect the private network IP address from both Droplets for the next steps.

### Authenticating the Cluster Nodes

Authenticate the cluster nodes using the username **_hacluster_** and the same password you defined on step 3. You’ll need to provide the private network IP address for each node. From the **primary** server, run:

    sudo pcs cluster auth primary_private_IP_address secondary_private_IP_address

You should get output like this:

    OutputUsername: hacluster
    Password: 
    primary_private_IP_address: Authorized
    secondary_private_IP_address: Authorized

### Generating the Corosync Configuration

Still on the **primary** server, generate the Corosync configuration file with the following command:

    sudo pcs cluster setup --name webcluster \ 
    primary_private_IP_address secondary_private_IP_address

The output should look similar to this:

    OutputShutting down pacemaker/corosync services...
    Redirecting to /bin/systemctl stop pacemaker.service
    Redirecting to /bin/systemctl stop corosync.service
    Killing any remaining services...
    Removing all cluster configuration files...
    primary_private_IP_address: Succeeded
    secondary_private_IP_address: Succeeded
    Synchronizing pcsd certificates on nodes primary_private_IP_address, secondary_private_IP_address...
    primary_private_IP_address: Success
    secondary_private_IP_address: Success
    
    Restaring pcsd on the nodes in order to reload the certificates...
    primary_private_IP_address: Success
    secondary_private_IP_address: Success

This will generate a new configuration file located at `/etc/corosync/corosync.conf` based on the parameters provided to the `pcs cluster setup` command. We used **webcluster** as the cluster name in this example, but you can use the name of your choice.

### Starting the Cluster

To start the cluster you just set up, run the following command from the **primary** server:

    sudo pcs cluster start --all

    Outputprimary_private_IP_address: Starting Cluster...
    secondary_private_IP_address: Starting Cluster...

You can now confirm that both nodes joined the cluster by running the following command on any of the servers:

    sudo pcs status corosync

    OutputMembership information
    ----------------------
        Nodeid Votes Name
             2 1 secondary_private_IP_address
             1 1 primary_private_IP_address (local)

To get more information about the current status of the cluster, you can run:

    sudo pcs cluster status

The output should be similar to this:

    OutputCluster Status:
     Last updated: Fri Dec 11 11:59:09 2015 Last change: Fri Dec 11 11:59:00 2015 by hacluster via crmd on secondary
     Stack: corosync
     Current DC: secondary (version 1.1.13-a14efad) - partition with quorum
     2 nodes and 0 resources configured
     Online: [primary secondary]
    
    PCSD Status:
      primary (primary_private_IP_address): Online
      secondary (secondary_private_IP_address): Online

Now you can enable the `corosync` and `pacemaker` services to make sure they will start when the system boots. Run the following on **both servers** :

    sudo systemctl enable corosync.service
    sudo systemctl enable pacemaker.service

### Disabling STONITH

STONITH (Shoot The Other Node In The Head) is a fencing technique intended to prevent data corruption caused by faulty nodes in a cluster that are unresponsive but still accessing application data. Because its configuration depends on a number of factors that are out of scope for this guide, we are going to disable STONITH in our cluster setup.

To disable STONITH, run the following command on one of the Droplets, either primary or secondary:

    sudo pcs property set stonith-enabled=false

## Step 6 — Create Floating IP Reassignment Resource Agent

The only thing left to do is to configure the resource agent that will execute the IP reassignment script when a failure is detected in one of the cluster nodes. The resource agent is responsible for creating an interface between the cluster and the resource itself. In our case, the resource is the assign-ip script. The cluster relies on the resource agent to execute the right procedures when given a start, stop or monitor command. There are different types of resource agents, but the most common one is the OCF (Open Cluster Framework) standard.

We will create a new OCF resource agent to manage the **assign-ip** service on both servers.

First, create the directory that will contain the resource agent. The directory name will be used by Pacemaker as an identifier for this custom agent. Run the following on **both servers** :

    sudo mkdir /usr/lib/ocf/resource.d/digitalocean

Next, download the FloatIP resource agent script and place it in the newly created directory, on **both servers** :

    sudo curl -L -o /usr/lib/ocf/resource.d/digitalocean/floatip http://do.co/ocf-floatip

Now make the script executable with the following command on **both servers** :

    sudo chmod +x /usr/lib/ocf/resource.d/digitalocean/floatip

We still need to register the resource agent within the cluster, using the PCS utility. The following command should be executed from **one** of the nodes (don’t forget to replace your\_api\_token with your DigitalOcean API token and floating\_IP\_address with your actual Floating IP address):

    sudo pcs resource create FloatIP ocf:digitalocean:floatip \
        params do_token=your_api_token \
        floating_ip=floating_IP_address 

The resource should now be registered and active in the cluster. You can check the registered resources from any of the nodes with the `pcs status` command:

    sudo pcs status

    Output...
    2 nodes and 1 resource configured
    
    Online: [primary secondary]
    
    Full list of resources:
    
     FloatIP (ocf::digitalocean:floatip): Started primary
    
    ...

## Step 7 — Test Failover

Your cluster should now be ready to handle a node failure. A simple way to test failover is to restart the server that is currently active in your Floating IP setup. If you’ve followed all steps in this tutorial, this should be the **primary** server.

Again, let’s monitor the IP reassignment by using a `curl` command in a loop. From a local terminal, run:

    while true; do curl floating_IP_address; sleep 1; done

From the **primary** server, run a reboot command:

    sudo reboot

After a few moments, the primary server should become unavailable. This will cause the secondary server to take over as the active node. You should see output similar to this in your local terminal running `curl`:

    Output...
    Droplet: primary, IP Address: primary_IP_address
    Droplet: primary, IP Address: primary_IP_address
    curl: (7) Failed connect to floating_IP_address; Connection refused
    Droplet: secondary, IP Address: secondary_IP_address
    Droplet: secondary, IP Address: secondary_IP_address
    …

The “Connection refused” error happens when the request is made right before or at the same time when the IP reassignment is taking place. It may or may not show up in the output.

If you want to point the Floating IP back to the primary node while also testing failover on the secondary node, just repeat the process but this time from the **secondary** Droplet:

    sudo reboot

## Conclusion

In this guide, we saw how Floating IPs can be used together with Corosync, Pacemaker and PCS to create a highly available web server environment on CentOS 7 servers. We used a rather simple infrastructure to demonstrate the usage of Floating IPs, but this setup can be scaled to implement high availability at any level of your application stack.
