---
author: Mitchell Anicas
date: 2015-10-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-high-availability-setup-with-corosync-pacemaker-and-floating-ips-on-ubuntu-14-04
---

# How To Create a High Availability Setup with Corosync, Pacemaker, and Floating IPs on Ubuntu 14.04

## Introduction

This tutorial will demonstrate how you can use Corosync and Pacemaker with a Floating IP to create a high availability (HA) server infrastructure on DigitalOcean.

Corosync is an open source program that provides cluster membership and messaging capabilities, often referred to as the **messaging** layer, to client servers. Pacemaker is an open source cluster resource manager (CRM), a system that coordinates resources and services that are managed and made highly available by a cluster. In essence, Corosync enables servers to communicate as a cluster, while Pacemaker provides the ability to control how the cluster behaves.

## Goal

When completed, the HA setup will consist of two Ubuntu 14.04 servers in an active/passive configuration. This will be accomplished by pointing a Floating IP, which is how your users will access your web service, to point to the primary (active) server unless a failure is detected. In the event that Pacemaker detects that the primary server is unavailable, the secondary (passive) server will automatically run a script that will reassign the Floating IP to itself via the DigitalOcean API. Thus, subsequent network traffic to the Floating IP will be directed to your secondary server, which will act as the active server and process the incoming traffic.

This diagram demonstrates the concept of the described setup:

![Active/passive Diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high_availability/ha-diagram-animated.gif)

**Note:** This tutorial only covers setting up active/passive high availability at the gateway level. That is, it includes the Floating IP, and the _load balancer_ servers—Primary and Secondary. Furthermore, for demonstration purposes, instead of configuring reverse-proxy load balancers on each server, we will simply configure them to respond with their respective hostname and public IP address.

To achieve this goal, we will follow these steps:

- Create 2 Droplets that will receive traffic
- Create Floating IP and assign it to one of the Droplets
- Install and configure Corosync
- Install and configure Pacemaker
- Configure Floating IP Reassignment Cluster Resource
- Test failover
- Configure Nginx Cluster Resource

## Prerequisites

In order to automate the Floating IP reassignment, we must use the DigitalOcean API. This means that you need to generate a Personal Access Token (PAT), which is an API token that can be used to authenticate to your DigitalOcean account, with _read_ and _write_ access by following the [How To Generate a Personal Access Token](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token) section of the API tutorial. Your PAT will be used in a script that will be added to both servers in your cluster, so be sure to keep it somewhere safe—as it allows full access to your DigitalOcean account—for reference.

In addition to the API, this tutorial utilizes the following DigitalOcean features:

- [Floating IPs](how-to-use-floating-ips-on-digitalocean)
- [Metadata](an-introduction-to-droplet-metadata)
- [User Data (Cloud-Config scripts)](an-introduction-to-cloud-config-scripting)

Please read the linked tutorials if you want to learn more about them.

## Create Droplets

The first step is to create two Ubuntu Droplets, with Private Networking enabled, in the same datacenter, which will act as the primary and secondary servers described above. In our example setup, we will name them “primary” and “secondary” for easy reference. We will install Nginx on both Droplets and replace their index pages with information that uniquely identifies them. This will allow us a simple way to demonstrate that the HA setup is working. For a real setup, your servers should run the web server or load balancer of your choice, such as Nginx or HAProxy.

Create two Ubuntu 14.04 Droplets, **primary** and **secondary**. If you want to follow the example setup, use this bash script as the user data:

Example User Data

    #!/bin/bash
    
    apt-get -y update
    apt-get -y install nginx
    export HOSTNAME=$(curl -s http://169.254.169.254/metadata/v1/hostname)
    export PUBLIC_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    echo Droplet: $HOSTNAME, IP Address: $PUBLIC_IPV4 > /usr/share/nginx/html/index.html

This user data will install Nginx and replace the contents of `index.html` with the droplet’s hostname and IP address (by referencing the Metadata service). Accessing either Droplet via its public IP address will show a basic webpage with the Droplet hostname and IP address, which will be useful for testing which Droplet the Floating IP is pointing to at any given moment.

## Create a Floating IP

In the DigitalOcean Control Panel, click **Networking** , in the top menu, then **Floating IPs** in the side menu.

![No Floating IPs](https://assets.digitalocean.com/site/ControlPanel/fip_no_floating_ips.png)

Assign a Floating IP to your **primary** Droplet, then click the **Assign Floating IP** button.

After the Floating IP has been assigned, take a note of its IP address. Check that you can reach the Droplet that it was assigned to by visiting the Floating IP address in a web browser.

    http://your_floating_ip

You should see the index page of your primary Droplet.

## Configure DNS (Optional)

If you want to be able to access your HA setup via a domain name, go ahead and create an **A record** in your DNS that points your domain to your Floating IP address. If your domain is using DigitalOcean’s nameservers, follow [step three](how-to-set-up-a-host-name-with-digitalocean#step-three%E2%80%94configure-your-domain) of the How To Set Up a Host Name with DigitalOcean tutorial. Once that propagates, you may access your active server via the domain name.

The example domain name we’ll use is `example.com`. If you don’t have a domain name to use right now, you will use the Floating IP address to access your setup instead.

## Configure Time Synchronization

Whenever you have multiple servers communicating with each other, especially with clustering software, it is important to ensure their clocks are synchronized. We’ll use NTP (Network Time Protocol) to synchronize our servers.

On **both servers** , use this command to open a time zone selector:

    sudo dpkg-reconfigure tzdata

Select your desired time zone. For example, we’ll choose `America/New_York`.

Next, update apt-get:

    sudo apt-get update

Then install the `ntp` package with this command;

    sudo apt-get -y install ntp

Your server clocks should now be synchronized using NTP. To learn more about NTP, check out this tutorial: [Configure Timezones and Network Time Protocol Synchronization](additional-recommended-steps-for-new-ubuntu-14-04-servers#configure-timezones-and-network-time-protocol-synchronization).

## Configure Firewall

Corosync uses UDP transport between ports `5404` and `5406`. If you are running a firewall, ensure that communication on those ports are allowed between the servers.

For example, if you’re using `iptables`, you could allow traffic on these ports and `eth1` (the private network interface) with these commands:

    sudo iptables -A INPUT -i eth1 -p udp -m multiport --dports 5404,5405,5406 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -o eth1 -p udp -m multiport --sports 5404,5405,5406 -m conntrack --ctstate ESTABLISHED -j ACCEPT

It is advisable to use firewall rules that are more restrictive than the provided example.

## Install Corosync and Pacemaker

On **both servers** , install Corosync and Pacemaker using apt-get:

    sudo apt-get install pacemaker

Note that Corosync is installed as a dependency of the Pacemaker package.

Corosync and Pacemaker are now installed but they need to be configured before they will do anything useful.

## Configure Corosync

Corosync must be configured so that our servers can communicate as a cluster.

### Create Cluster Authorization Key

In order to allow nodes to join a cluster, Corosync requires that each node possesses an identical cluster authorization key.

On the **primary** server, install the `haveged` package:

    sudo apt-get install haveged

This software package allows us to easily increase the amount of entropy on our server, which is required by the `corosync-keygen` script.

On the **primary** server, run the `corosync-keygen` script:

    sudo corosync-keygen

This will generate a 128-byte cluster authorization key, and write it to `/etc/corosync/authkey`.

Now that we no longer need the `haveged` package, let’s remove it from the **primary** server:

    sudo apt-get remove --purge haveged
    sudo apt-get clean

On the **primary** server, copy the `authkey` to the secondary server:

    sudo scp /etc/corosync/authkey username@secondary_ip:/tmp

On the **secondary** server, move the `authkey` file to the proper location, and restrict its permissions to root:

    sudo mv /tmp/authkey /etc/corosync
    sudo chown root: /etc/corosync/authkey
    sudo chmod 400 /etc/corosync/authkey

Now both servers should have an identical authorization key in the `/etc/corosync/authkey` file.

### Configure Corosync Cluster

In order to get our desired cluster up and running, we must set up these

On **both servers** , open the `corosync.conf` file for editing in your favorite editor (we’ll use `vi`):

    sudo vi /etc/corosync/corosync.conf

Here is a Corosync configuration file that will allow your servers to communicate as a cluster. Be sure to replace the highlighted parts with the appropriate values. `bindnetaddr` should be set to the private IP address of the server you are currently working on. The two other highlighted items should be set to the indicated server’s private IP address. With the exception of the `bindnetaddr`, the file should be identical on both servers.

Replace the contents of `corosync.conf` with this configuration, with the changes that are specific to your environment:

/etc/corosync/corosync.conf

    totem {
      version: 2
      cluster_name: lbcluster
      transport: udpu
      interface {
        ringnumber: 0
        bindnetaddr: server_private_IP_address
        broadcast: yes
        mcastport: 5405
      }
    }
    
    quorum {
      provider: corosync_votequorum
      two_node: 1
    }
    
    nodelist {
      node {
        ring0_addr: primary_private_IP_address
        name: primary
        nodeid: 1
      }
      node {
        ring0_addr: secondary_private_IP_address
        name: secondary
        nodeid: 2
      }
    }
    
    logging {
      to_logfile: yes
      logfile: /var/log/corosync/corosync.log
      to_syslog: yes
      timestamp: on
    }

The **totem** section (lines 1-11), which refers to the Totem protocol that Corosync uses for cluster membership, specifies how the cluster members should communicate with each other. In our setup, the important settings include `transport: udpu` (specifies unicast mode) and `bindnetaddr` (specifies which network address Corosync should bind to).

The **quorum** section (lines 13-16) specifies that this is a two-node cluster, so only a single node is required for quorum (`two_node: 1`). This is a workaround of the fact that achieving a quorum requires at least three nodes in a cluster. This setting will allow our two-node cluster to elect a coordinator (DC), which is the node that controls the cluster at any given time.

The **nodelist** section (lines 18-29) specifies each node in the cluster, and how each node can be reached. Here, we configure both our primary and secondary nodes, and specify that they can be reached via their respective private IP addresses.

The **logging** section (lines 31-36) specifies that the Corosync logs should be written to `/var/log/corosync/corosync.log`. If you run into any problems with the rest of this tutorial, be sure to look here while you troubleshoot.

Save and exit.

Next, we need to configure Corosync to allow the Pacemaker service.

On **both servers** , create the `pcmk` file in the Corosync service directory with an editor. We’ll use `vi`:

    sudo vi /etc/corosync/service.d/pcmk

Then add the Pacemaker service:

    service {
      name: pacemaker
      ver: 1
    }

Save and exit. This will be included in the Corosync configuration, and allows Pacemaker to use Corosync to communicate with our servers.

By default, the Corosync service is disabled. On **both servers** , change that by editing `/etc/default/corosync`:

    sudo vi /etc/default/corosync

Change the value of `START` to `yes`:

/etc/default/corosync

    START=yes

Save and exit. Now we can start the Corosync service.

On **both** servers, start Corosync with this command:

    sudo service corosync start

Once Corosync is running on both servers, they should be clustered together. We can verify this by running this command:

    sudo corosync-cmapctl | grep members

The output should look something like this, which indicates that the primary (node 1) and secondary (node 2) have joined the cluster:

    corosync-cmapctl output:runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
    runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(primary_private_IP_address)
    runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
    runtime.totem.pg.mrp.srp.members.1.status (str) = joined
    runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
    runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(secondary_private_IP_address)
    runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
    runtime.totem.pg.mrp.srp.members.2.status (str) = joined

Now that you have Corosync set up properly, let’s move onto configuring Pacemaker.

## Start and Configure Pacemaker

Pacemaker, which depends on the messaging capabilities of Corosync, is now ready to be started and to have its basic properties configured.

### Enable and Start Pacemaker

The Pacemaker service requires Corosync to be running, so it is disabled by default.

On **both servers** , enable Pacemaker to start on system boot with this command:

    sudo update-rc.d pacemaker defaults 20 01

With the prior command, we set Pacemaker’s start priority to `20`. It is important to specify a start priority that is higher than Corosync’s (which is `19` by default), so that Pacemaker starts after Corosync.

Now let’s start Pacemaker:

    sudo service pacemaker start

To interact with Pacemaker, we will use the `crm` utility.

Check Pacemaker with `crm`:

    sudo crm status

This should output something like this (if not, wait for 30 seconds, then run the command again):

    crm status:Last updated: Fri Oct 16 14:38:36 2015
    Last change: Fri Oct 16 14:36:01 2015 via crmd on primary
    Stack: corosync
    Current DC: primary (1) - partition with quorum
    Version: 1.1.10-42f2063
    2 Nodes configured
    0 Resources configured
    
    
    Online: [primary secondary]

There are a few things to note about this output. First, **Current DC** (Designated Coordinator) should be set to either `primary (1)` or `secondary (2)`. Second, there should be **2 Nodes configured** and **0 Resources configured**. Third, both nodes should be marked as **online**. If they are marked as **offline** , try waiting 30 seconds and check the status again to see if it corrects itself.

From this point on, you may want to run the interactive CRM monitor in another SSH window (connected to either cluster node). This will give you real-time updates of the status of each node, and where each resource is running:

    sudo crm_mon

The output of this command looks identical to the output of `crm status` except it runs continuously. If you want to quit, press `Ctrl-C`.

### Configure Cluster Properties

Now we’re ready to configure the basic properties of Pacemaker. Note that all Pacemaker (`crm`) commands can be run from either node server, as it automatically synchronizes all cluster-related changes across all member nodes.

For our desired setup, we want to disable STONITH—a mode that many clusters use to remove faulty nodes—because we are setting up a two-node cluster. To do so, run this command on either server:

    sudo crm configure property stonith-enabled=false

We also want to disable quorum-related messages in the logs:

    sudo crm configure property no-quorum-policy=ignore

Again, this setting only applies to 2-node clusters.

If you want to verify your Pacemaker configuration, run this command:

    sudo crm configure show

This will display all of your active Pacemaker settings. Currently, this will only include two nodes, and the STONITH and quorum properties you just set.

## Create Floating IP Reassignment Resource Agent

Now that Pacemaker is running and configured, we need to add resources for it to manage. As mentioned in the introduction, resources are services that the cluster is responsible for making highly available. In Pacemaker, adding a resource requires the use of a **resource agent** , which act as the interface to the service that will be managed. Pacemaker ships with several resource agents for common services, and allows custom resource agents to be added.

In our setup, we want to make sure that the service provided by our web servers, **primary** and **secondary** , is highly available in an active/passive setup, which means that we need a way to ensure that our Floating IP is always pointing to server that is available. To enable this, we need to set up a **resource agent** that each node can run to determine if it owns the Floating IP and, if necessary, run a script to point the Floating IP to itself. We’ll refer to the resource agent as “FloatIP OCF”, and the Floating IP reassignment script as `assign-ip`. Once we have the FloatIP OCF resource agent installed, we can define the resource itself, which we’ll refer to as `FloatIP`.

### Download assign-ip Script

As we just mentioned, we need a script that can reassign which Droplet our Floating IP is pointing to, in case the `FloatIP` resource needs to be moved to a different node. For this purpose, we’ll download a basic Python script that assigns a Floating IP to a given Droplet ID, using the DigitalOcean API.

On **both servers** , download the `assign-ip` Python script:

    sudo curl -L -o /usr/local/bin/assign-ip http://do.co/assign-ip

On **both servers** , make it executable:

    sudo chmod +x /usr/local/bin/assign-ip

Use of the `assign-ip` script requires the following details:

- **Floating IP:** The first argument to the script, the Floating IP that is being assigned
- **Droplet ID:** The second argument to the script, the Droplet ID that the Floating IP should be assigned to
- **DigitalOcean PAT (API token):** Passed in as the environment variable `DO_TOKEN`, your read/write DigitalOcean PAT

Feel free to review the contents of the script before continuing.

So, if you wanted to manually run this script to reassign a Floating IP, you could run it like so: `DO_TOKEN=your_digitalocean_pat /usr/local/bin/assign-ip your_floating_ip droplet_id`. However, this script will be invoked from the FloatIP OCF resource agent in the event that the `FloatIP` resource needs to be moved to a different node.

Let’s install the Float IP Resource Agent next.

### Download FloatIP OCF Resource Agent

Pacemaker allows the addition of OCF resource agents by placing them in a specific directory.

On **both servers** , create the `digitalocean` resource agent provider directory with this command:

    sudo mkdir /usr/lib/ocf/resource.d/digitalocean

On **both servers** , download the FloatIP OCF Resource Agent:

    sudo curl -o /usr/lib/ocf/resource.d/digitalocean/floatip https://gist.githubusercontent.com/thisismitch/b4c91438e56bfe6b7bfb/raw/2dffe2ae52ba2df575baae46338c155adbaef678/floatip-ocf

On **both servers** , make it executable:

    sudo chmod +x /usr/lib/ocf/resource.d/digitalocean/floatip

Feel free to review the contents of the resource agent before continuing. It is a bash script that, if called with the `start` command, will look up the Droplet ID of the node that calls it (via Metadata), and assign the Floating IP to the Droplet ID. Also, it responds to the `status` and `monitor` commands by returning whether the calling Droplet has a Floating IP assigned to it.

It requires the following OCF parameters:

- **do\_token:** : The DigitalOcean API token to use for Floating IP reassignments, i.e. your DigitalOcean Personal Access Token
- **floating\_ip:** : Your Floating IP (address), in case it needs to be reassigned

Now we can use the FloatIP OCF resource agent to define our `FloatIP` resource.

## Add FloatIP Resource

With our FloatIP OCF resource agent installed, we can now configure our `FloatIP` resource.

On either server, create the `FloatIP` resource with this command (be sure to specify the two highlighted parameters with your own information):

    sudo crm configure primitive FloatIP ocf:digitalocean:floatip \
      params do_token=your_digitalocean_personal_access_token \
      floating_ip=your_floating_ip

This creates a primitive resource, which is a generic type of cluster resource, called “FloatIP”, using the FloatIP OCF Resource Agent we created earlier (`ocf:digitalocean:floatip`). Notice that it requires the `do_token` and `floating_ip` to be passed as parameters. These will be used if the Floating IP needs to be reassigned.

If you check the status of your cluster (`sudo crm status` or `sudo crm_mon`), you should see that the `FloatIP` resource is defined and started on one of your nodes:

    crm_mon:...
    2 Nodes configured
    1 Resource configured
    
    Online: [primary secondary]
    
     FloatIP (ocf::digitalocean:floatip): Started primary

Assuming that everything was set up properly, you should now have an active/passive HA setup! As it stands, the Floating IP will get reassigned to an online server if the node that the `FloatIP` is started on goes offline or into `standby` mode. Right now, if the active node— **primary** , in our example output—becomes unavailable, the cluster will instruct the **secondary** node to start the `FloatIP` resource and claim the Floating IP address for itself. Once the reassignment occurs, the Floating IP will direct users to the newly active **secondary** server.

Currently, the failover (Floating IP reassignment) is only triggered if the active host goes offline or is unable to communicate with the cluster. A better version of this setup would specify additional resources that should be managed by Pacemaker. This would allow the cluster to detect failures of specific services, such as load balancer or web server software. Before setting that up, though, we should make sure the basic failover works.

## Test High Availability

It’s important to test that our high availability setup works, so let’s do that now.

Currently, the Floating IP is assigned to the one of your nodes (let’s assume **primary** ). Accessing the Floating IP now, via the IP address or by the domain name that is pointing to it, will simply show the index page of the **primary** server. If you used the example user data script, it will look something like this:

    Floating IP is pointing to primary server:Droplet: primary, IP Address: primary_ip_address

This indicates that the Floating IP is, in fact, assigned to the primary Droplet.

Now, let’s open a new local terminal and use `curl` to access the Floating IP on a 1 second loop. Use this command to do so, but be sure to replace the URL with your domain or Floating IP address:

    while true; do curl floating_IP_address; sleep 1; done

Currently, this will output the same Droplet name and IP address of the primary server. If we cause the primary server to fail, by powering it off or by changing the primary node’s cluster status to `standby`, we will see if the Floating IP gets reassigned to the secondary server.

Let’s reboot the **primary** server now. Do so via the DigitalOcean Control Panel or by running this command on the primary server:

    sudo reboot

After a few moments, the primary server should become unavailable. Pay attention to the output of the `curl` loop that is running in the terminal. You should notice output that looks like this:

    curl loop output:Droplet: primary, IP Address: primary_IP_address
    ...
    curl: (7) Failed to connect to floating_IP_address port 80: Connection refused
    Droplet: secondary, IP Address: secondary_IP_address
    ...

That is, the Floating IP address should be reassigned to point to the IP address of the **secondary** server. That means that your HA setup is working, as a successful automatic failover has occurred.

You may or may not see the `Connection refused` error, which can occur if you try and access the Floating IP between the primary server failure and the Floating IP reassignment completion.

If you check the status of Pacemaker, you should see that the `FloatIP` resource is started on the **secondary** server. Also, the **primary** server should temporarily be marked as `OFFLINE` but will join the `Online` list as soon as it completes its reboot and rejoins the cluster.

## Troubleshooting the Failover (Optional)

Skip this section if your HA setup works as expected. If the failover did not occur as expected, you should review your setup before moving on. In particular, make sure that any references to your own setup, such as node IP addresses, your Floating IP, and your API token.

### Useful Commands for Troubleshooting

Here are some commands that can help you troubleshoot your setup.

As mentioned earlier, the `crm_mon` tool can be very helpful in viewing the real-time status of your nodes and resources:

    sudo crm_mon

Also, you can look at your cluster configuration with this command:

    sudo crm configure show

If the `crm` commands aren’t working at all, you should look at the Corosync logs for clues:

    sudo tail -f /var/log/corosync/corosync.log

### Miscellaneous CRM Commands

These commands can be useful when configuring your cluster.

You can set a node to `standby` mode, which can be used to simulate a node becoming unavailable, with this command:

    sudo crm node standby NodeName

You can change a node’s status from `standby` to `online` with this command:

    sudo crm node online NodeName

You can edit a resource, which allows you to reconfigure it, with this command:

    sudo crm configure edit ResourceName

You can delete a resource, which must be stopped before it is deleted, with these command:

    sudo crm resource stop ResourceName
    sudo crm configure delete ResourceName

Lastly, the `crm` command can be run by itself to access an interactive `crm` prompt:

    crm

We won’t cover the usage of the interactive `crm` prompt, but it can be used to do all of the `crm` configuration we’ve done up to this point.

## Add Nginx Resource (optional)

Now that you are sure that your Floating IP failover works, let’s look into adding a new resource to your cluster. In our example setup, Nginx is the main service that we are making highly available, so let’s work on adding it as a resource that our cluster will manage.

Pacemaker comes with an Nginx resource agent, so we can easily add Nginx as a cluster resource.

Use this command to create a new primitive cluster resource called “Nginx”:

    sudo crm configure primitive Nginx ocf:heartbeat:nginx \
      params httpd="/usr/sbin/nginx" \
      op start timeout="40s" interval="0" \
      op monitor timeout="30s" interval="10s" on-fail="restart" \
      op stop timeout="60s" interval="0"

The specified resource tells the cluster to monitor Nginx every 10 seconds, and to restart it if it becomes unavailable.

Check the status of your cluster resources by using `sudo crm_mon` or `sudo crm status`:

    crm_mon:...
    Online: [primary secondary]
    
     FloatIP (ocf::digitalocean:floatip): Started primary
     Nginx (ocf::heartbeat:nginx): Started secondary

Unfortunately, Pacemaker will decide to start the `Nginx` and `FloatIP` resources on separate nodes because we have not defined any resource constraints. This is a problem because this means that the Floating IP will be pointing to one Droplet, while the Nginx service will only be running on the other Droplet. Accessing the Floating IP will point you to a server that is not running the service that should be highly available.

To resolve this issue, we’ll create a **clone** resource, which specifies that an existing primitive resource should be started on multiple nodes.

Create a clone resource of the `Nginx` resource called “Nginx-clone” with this command:

    sudo crm configure clone Nginx-clone Nginx

The cluster status should now look something like this:

    crm_mon:Online: [primary secondary]
    
    FloatIP (ocf::digitalocean:floatip): Started primary
     Clone Set: Nginx-clone [Nginx]
         Started: [primary secondary]

As you can see, the clone resource, `Nginx-clone`, is now started on both of our nodes.

The last step is to configure a **colocation** restraint, to specify that the `FloatIP` resource should run on a node with an active `Nginx-clone` resource. To create a colocation restraint called “FloatIP-Nginx”, use this command:

    sudo crm configure colocation FloatIP-Nginx inf: FloatIP Nginx-clone

You won’t see any difference in the `crm status` output, but you can see that the colocation resource was created with this command:

    sudo crm configure show

Now, both of your servers should have Nginx running, while only one of them, has the `FloatIP` resource running. Now is a good time to test your HA setup by stopping your Nginx service and by rebooting or powering off your **active** server.

## Conclusion

Congratulations! You now have a basic HA server setup using Corosync, Pacemaker, and a DigitalOcean Floating IP.

The next step is to replace the example Nginx setup with a reverse-proxy load balancer. You can use Nginx or HAProxy for this purpose. Keep in mind that you will want to bind your load balancer to the **anchor IP address** , so that your users can only access your servers via the Floating IP address (and not via the public IP address of each server). This process is detailed in the [How To Create a High Availability HAProxy Setup with Corosync, Pacemaker, and Floating IPs on Ubuntu 14.04](how-to-create-a-high-availability-haproxy-setup-with-corosync-pacemaker-and-floating-ips-on-ubuntu-14-04) tutorial.
