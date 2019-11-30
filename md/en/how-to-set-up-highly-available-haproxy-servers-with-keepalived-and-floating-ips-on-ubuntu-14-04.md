---
author: Justin Ellingwood
date: 2015-10-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-highly-available-haproxy-servers-with-keepalived-and-floating-ips-on-ubuntu-14-04
---

# How To Set Up Highly Available HAProxy Servers with Keepalived and Floating IPs on Ubuntu 14.04

## Introduction

High availability is a function of system design that allows an application to automatically restart or reroute work to another capable system in the event of a failure. In terms of servers, there are a few different technologies needed to set up a highly available system. There must be a component that can redirect the work and there must be a mechanism to monitor for failure and transition the system if an interruption is detected.

The `keepalived` daemon can be used to monitor services or systems and to automatically failover to a standby if problems occur. In this guide, we will demonstrate how to use `keepalived` to set up high availability for your load balancers. We will configure a [floating IP address](how-to-use-floating-ips-on-digitalocean) that can be moved between two capable load balancers. These will each be configured to split traffic between two backend web servers. If the primary load balancer goes down, the floating IP will be moved to the second load balancer automatically, allowing service to resume.

![High Availability diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high_availability/ha-diagram-animated.gif)

**Note:** [DigitalOcean Load Balancers](an-introduction-to-digitalocean-load-balancers) are a fully-managed, highly available load balancing service. The Load Balancer service can fill the same role as the manual high availability setup described here. Follow our [guide on setting up Load Balancers](how-to-create-your-first-digitalocean-load-balancer) if you wish to evaluate that option.

## Prerequisites

In order to complete this guide, you will need to create four Ubuntu 14.04 servers in your DigitalOcean account. All of the servers must be located within the same datacenter and should have private networking enabled.

On each of these servers, you will need a non-root user configured with `sudo` access. You can follow our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04) to learn how to set up these users.

## Finding Server Network Information

Before we begin the actual configuration of our infrastructure components, it is best to gather some information about each of your servers.

To complete this guide, you will need to have the following information about your servers:

- **web servers** : Private IP address
- **load balancers** Private and Anchor IP addresses

### Finding Private IP Addresses

The easiest way to find your Droplet’s private IP address is to use `curl` to grab the private IP address from the DigitalOcean metadata service. This command should be run from within your Droplets. On each Droplet, type:

    curl 169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address && echo

The correct IP address should be printed in the terminal window:

    Output10.132.20.236

### Finding Anchor IP Addresses

The “anchor IP” is the local private IP address that the floating IP will bind to when attached to a DigitalOcean server. It is simply an alias for the regular `eth0` address, implemented at the hypervisor level.

The easiest, least error-prone way of grabbing this value is straight from the DigitalOcean metadata service. Using `curl`, you can reach out to this endpoint on each of your servers by typing:

    curl 169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address && echo

The anchor IP will be printed on its own line:

    Output10.17.1.18

## Install and Configure the Web Server

After gathering the data above, we can move on to configuring our services.

Note
In this setup, the software selected for the web server layer is fairly interchangeable. This guide will use Nginx because it is generic and rather easy to configure. If you are more comfortable with Apache or a (production-capable) language-specific web server, feel free to use that instead. HAProxy will simply pass client requests to the backend web servers which can handle the requests similarly to how it would handle direct client connections.  

We will start off by setting up our backend web servers. Both of these servers will serve exactly the same content. They will only accept web connections over their private IP addresses. This will help ensure that traffic is directed through one of the two HAProxy servers we will be configuring later.

Setting up web servers behind a load balancer allows us to distribute the request burden among some number identical web servers. As our traffic needs change, we can easily scale to meet the new demands by adding or removing web servers from this tier.

### Installing Nginx

We will be installing Nginx on our web serving machines to provide this functionality.

Start off by logging in with your `sudo` user to the two machines that you wish to use as the web servers. Update the local package index on each of your web servers and install Nginx by typing:

    sudo apt-get update
    sudo apt-get install nginx

### Configure Nginx to Only Allow Requests from the Load Balancers

Next, we will configure our Nginx instances. We want to tell Nginx to only listen for requests on the private IP address of the server. Furthermore, we will only serve requests coming from the private IP addresses of our two load balancers.

To make these changes, open the default Nginx server block file on each of your web servers:

    sudo nano /etc/nginx/sites-available/default

To start, we will modify the `listen` directives. Change the `listen` directive to listen to the current **web server’s private IP address** on port 80. Delete the extra `listen` line. It should look something like this:

/etc/nginx/sites-available/default

    server {
        listen web_server_private_IP:80;
    
        . . .

Afterwards, we will set up two `allow` directives to permit traffic originating from the private IP addresses of our two load balancers. We will follow this up with a `deny all` rule to forbid all other traffic:

/etc/nginx/sites-available/default

    server {
        listen web_server_private_IP:80;
    
        allow load_balancer_1_private_IP;
        allow load_balancer_2_private_IP;
        deny all;
    
        . . .

Save and close the files when you are finished.

Test that the changes that you made represent valid Nginx syntax by typing:

    sudo nginx -t

If no problems were reported, restart the Nginx daemon by typing:

    sudo service nginx restart

### Testing the Changes

To test that your web servers are restricted correctly, you can make requests using `curl` from various locations.

On your web servers themselves, you can try a simple request of the local content by typing:

    curl 127.0.0.1

Because of the restrictions we set in place in our Nginx server block files, this request will actually be denied:

    Outputcurl: (7) Failed to connect to 127.0.0.1 port 80: Connection refused

This is expected and reflects the behavior that we were attempting to implement.

Now, from either of the **load balancers** , we can make a request for either of our web server’s public IP address:

    curl web_server_public_IP

Once again, this should fail. The web servers are not listening on the public interface and furthermore, when using the public IP address, our web servers would not see the allowed private IP addresses in the request from our load balancers:

    Outputcurl: (7) Failed to connect to web_server_public_IP port 80: Connection refused

However, if we modify the call to make the request using the web server’s _private IP address_, it should work correctly:

    curl web_server_private_IP

The default Nginx `index.html` page should be returned:

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    
    . . .

Test this from both load balancers to both web servers. Each request for the private IP address should succeed while each request made to the public addresses should fail.

Once the above behavior is demonstrated, we can move on. Our backend web server configuration is now complete.

## Install and Configure HAProxy

Next, we will set up the HAProxy load balancers. These will each sit in front of our web servers and split requests between the two backend servers. These load balancers are completely redundant. Only one will receive traffic at any given time.

The HAProxy configuration will pass requests to both of the web servers. The load balancers will listen for requests on their anchor IP address. As mentioned earlier, this is the IP address that the floating IP address will bind to when attached to the Droplet. This ensures that only traffic originating from the floating IP address will be forwarded.

### Install HAProxy

The first step we need to take on our load balancers will be to install the `haproxy` package. We can find this in the default Ubuntu repositories. Update the local package index on your load balancers and install HAProxy by typing:

    sudo apt-get update
    sudo apt-get install haproxy

### Configure HAProxy

The first item we need to modify when dealing with HAProxy is the `/etc/default/haproxy` file. Open that file now in your editor:

    sudo nano /etc/default/haproxy

This file determines whether HAProxy will start at boot. Since we want the service to start automatically each time the server powers on, we need to change the value of `ENABLED` to “1”:

/etc/default/haproxy

    # Set ENABLED to 1 if you want the init script to start haproxy.
    ENABLED=1
    # Add extra flags here.
    #EXTRAOPTS="-de -m 16"

Save and close the file after making the above edit.

Next, we can open the main HAProxy configuration file:

    sudo nano /etc/haproxy/haproxy.cfg

The first item that we need to adjust is the mode that HAProxy will be operating in. We want to configure TCP, or layer 4, load balancing. To do this, we need to alter the `mode` line in the `default` section. We should also change the option immediately following that deals with the log:

/etc/haproxy/haproxy.cfg

    . . .
    
    defaults
        log global
        mode tcp
        option tcplog
    
    . . .

At the end of the file, we need to define our front end configuration. This will dictate how HAProxy listens for incoming connections. We will bind HAProxy to the load balancer anchor IP address. This will allow it to listen for traffic originating from the floating IP address. We will call our front end “www” for simplicity. We will also specify a default backend to pass traffic to (which we will be configuring in a moment):

/etc/haproxy/haproxy.cfg

    . . .
    
    defaults
        log global
        mode tcp
        option tcplog
    
    . . .
    
    frontend www
        bind load_balancer_anchor_IP:80
        default_backend nginx_pool

Next, we can configure our backend section. This will specify the downstream locations where HAProxy will pass the traffic it receives. In our case, this will be the private IP addresses of both of the Nginx web servers we configured. We will specify traditional round-robin balancing and will set the mode to “tcp” again:

/etc/haproxy/haproxy.cfg

    . . .
    
    defaults
        log global
        mode tcp
        option tcplog
    
    . . .
    
    frontend www
        bind load_balancer_anchor_IP:80
        default_backend nginx_pool
    
    backend nginx_pool
        balance roundrobin
        mode tcp
        server web1 web_server_1_private_IP:80 check
        server web2 web_server_2_private_IP:80 check

When you are finished making the above changes, save and close the file.

Check that the configuration changes we made represent valid HAProxy syntax by typing:

    sudo haproxy -f /etc/haproxy/haproxy.cfg -c

If no errors were reported, restart your service by typing:

    sudo service haproxy restart

### Testing the Changes

We can make sure our configuration is valid by testing with `curl` again.

From the load balancer servers, try to request the local host, the load balancer’s own public IP address, or the server’s own private IP address:

    curl 127.0.0.1
    curl load_balancer_public_IP
    curl load_balancer_private_IP

These should all fail with messages that look similar to this:

    Outputcurl: (7) Failed to connect to address port 80: Connection refused

However, if you make a request to the load balancer’s _anchor IP address_, it should complete successfully:

    curl load_balancer_anchor_IP

You should see the default Nginx `index.html` page, routed from one of the two backend web servers:

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    
    . . .

If this behavior matches that of your system, then your load balancers are configured correctly.

## Build and Install Keepalived

Our actual service is now up and running. However, our infrastructure is not highly available yet because we have no way of redirecting traffic if our active load balancer experiences problems. In order to rectify this, we will install the `keepalived` daemon on our load balancer servers. This is the component that will provide failover capabilities if our active load balancer becomes unavailable.

There is a version of `keepalived` in Ubuntu’s default repositories, but it is outdated and suffers from a few bugs that would prevent our configuration from working. Instead, we will install the latest version of `keepalived` from source.

Before we begin, we should grab the dependencies we will need to build the software. The `build-essential` meta-package will provide the compilation tools we need, while the `libssl-dev` package contains the SSL development libraries that `keepalived` needs to build against:

    sudo apt-get install build-essential libssl-dev

Once the dependencies are in place, we can download the tarball for `keepalived`. Visit [this page](http://www.keepalived.org/download.html) to find the latest version of the software. Right-click on the latest version and copy the link address. Back on your servers, move to your home directory and use `wget` to grab the link you copied:

    cd ~
    wget http://www.keepalived.org/software/keepalived-1.2.19.tar.gz

Use the `tar` command to expand the archive. Move into the resulting directory:

    tar xzvf keepalived*
    cd keepalived*

Build and install the daemon by typing:

    ./configure
    make
    sudo make install

The daemon should now be installed on both of the load balancer systems.

## Create a Keepalived Upstart Script

The `keepalived` installation moved all of the binaries and supporting files into place on our system. However, one piece that was not included was an Upstart script for our Ubuntu 14.04 systems.

We can create a very simple Upstart script that can handle our `keepalived` service. Open a file called `keepalived.conf` within the `/etc/init` directory to get started:

    sudo nano /etc/init/keepalived.conf

Inside, we can start with a simple description of the functionality `keepalived` provides. We’ll use the description from the included `man` page. Next we will specify the runlevels in which the service should be started and stopped. We want this service to be active in all normal conditions (runlevels 2-5) and stopped for all other runlevels (when reboot, poweroff, or single-user mode is initiated, for instance):

/etc/init/keepalived.conf

    description "load-balancing and high-availability service"
    
    start on runlevel [2345]
    stop on runlevel [!2345]

Because this service is integral to ensuring our web service remains available, we want to restart this service in the event of a failure. We can then specify the actual `exec` line that will start the service. We need to add the `--dont-fork` option so that Upstart can track the `pid` correctly:

/etc/init/keepalived.conf

    description "load-balancing and high-availability service"
    
    start on runlevel [2345]
    stop on runlevel [!2345]
    
    respawn
    
    exec /usr/local/sbin/keepalived --dont-fork

Save and close the files when you are finished.

## Create the Keepalived Configuration File

With our Upstart files in place, we can now move on to configuring `keepalived`.

The service looks for its configuration files in the `/etc/keepalived` directory. Create that directory now on both of your load balancers:

    sudo mkdir -p /etc/keepalived

### Creating the Primary Load Balancer’s Configuration

Next, on the load balancer server that you wish to use as your **primary** server, create the main `keepalived` configuration file. The daemon looks for a file called `keepalived.conf` inside of the `/etc/keepalived` directory:

    sudo nano /etc/keepalived/keepalived.conf

Inside, we will start by defining a health check for our HAProxy service by opening up a `vrrp_script` block. This will allow `keepalived` to monitor our load balancer for failures so that it can signal that the process is down and begin recover measures.

Our check will be very simple. Every two seconds, we will check that a process called `haproxy` is still claiming a `pid`:

Primary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_haproxy {
        script "pidof haproxy"
        interval 2
    }

Next, we will open a block called `vrrp_instance`. This is the main configuration section that defines the way that `keepalived` will implement high availability.

We will start off by telling `keepalived` to communicate with its peers over `eth1`, our private interface. Since we are configuring our primary server, we will set the `state` configuration to “MASTER”. This is the initial value that `keepalived` will use until the daemon can contact its peer and hold an election.

During the election, the `priority` option is used to decide which member is elected. The decision is simply based on which server has the highest number for this setting. We will use “200” for our primary server:

Primary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_nginx {
        script "pidof nginx"
        interval 2
    }
    
    vrrp_instance VI_1 {
        interface eth1
        state MASTER
        priority 200
    
    
    }

Next, we will assign an ID for this cluster group that will be shared by both nodes. We will use “33” for this example. We need to set `unicast_src_ip` to our **primary** load balancer’s private IP address. We will set `unicast_peer` to our **secondary** load balancer’s private IP address:

Primary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_haproxy {
        script "pidof haproxy"
        interval 2
    }
    
    vrrp_instance VI_1 {
        interface eth1
        state MASTER
        priority 200
    
        virtual_router_id 33
        unicast_src_ip primary_private_IP
        unicast_peer {
            secondary_private_IP
        }
    
    
    }

Next, we can set up some simple authentication for our `keepalived` daemons to communicate with one another. This is just a basic measure to ensure that the peer being contacted is legitimate. Create an `authentication` sub-block. Inside, specify password authentication by setting the `auth_type`. For the `auth_pass` parameter, set a shared secret that will be used by both nodes. Unfortunately, only the first eight characters are significant:

Primary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_haproxy {
        script "pidof haproxy"
        interval 2
    }
    
    vrrp_instance VI_1 {
        interface eth1
        state MASTER
        priority 200
    
        virtual_router_id 33
        unicast_src_ip primary_private_IP
        unicast_peer {
            secondary_private_IP
        }
    
        authentication {
            auth_type PASS
            auth_pass password
        }
    
    
    }

Next, we will tell `keepalived` to use the check we created at the top of the file, labeled `chk_haproxy`, to determine the health of the local system. Finally, we will set a `notify_master` script, which is executed whenever this node becomes the “master” of the pair. This script will be responsible for triggering the floating IP address reassignment. We will create this script momentarily:

Primary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_haproxy {
        script "pidof haproxy"
        interval 2
    }
    
    vrrp_instance VI_1 {
        interface eth1
        state MASTER
        priority 200
    
        virtual_router_id 33
        unicast_src_ip primary_private_IP
        unicast_peer {
            secondary_private_IP
        }
    
        authentication {
            auth_type PASS
            auth_pass password
        }
    
        track_script {
            chk_haproxy
        }
    
        notify_master /etc/keepalived/master.sh
    }

Once you’ve set up the information above, save and close the file.

### Creating the Secondary Load Balancer’s Configuration

Next, we will create the companion script on our secondary load balancer. Open a file at `/etc/keepalived/keepalived.conf` on your secondary server:

    sudo nano /etc/keepalived/keepalived.conf

Inside, the script that we will use will be largely equivalent to the primary server’s script. The items that we need to change are:

- `state`: This should be changed to “BACKUP” on the secondary server so that the node initializes to the backup state before elections occur.
- `priority`: This should be set to a lower value than the primary server. We will use the value “100” in this guide.
- `unicast_src_ip`: This should be the private IP address of the **secondary** server.
- `unicast_peer`: This should contain the private IP address of the **primary** server.

When you change those values, the script for the secondary server should look like this:

Secondary server’s /etc/keepalived/keepalived.conf

    vrrp_script chk_haproxy {
        script "pidof haproxy"
        interval 2
    }
    
    vrrp_instance VI_1 {
        interface eth1
        state BACKUP
        priority 100
    
        virtual_router_id 33
        unicast_src_ip secondary_private_IP
        unicast_peer {
            primary_private_IP
        }
    
        authentication {
            auth_type PASS
            auth_pass password
        }
    
        track_script {
            chk_haproxy
        }
    
        notify_master /etc/keepalived/master.sh
    }

Once you’ve entered the script and changed the appropriate values, save and close the file.

## Create the Floating IP Transition Scripts

Next, we need to create a pair of scripts that we can use to reassign the floating IP address to the current Droplet whenever the local `keepalived` instance becomes the master server.

### Download the Floating IP Assignment Script

First, we will download a generic Python script (written by a [DigitalOcean community manager](https://www.digitalocean.com/community/users/asb)) that can be used to reassign a floating IP address to a Droplet using the DigitalOcean API. We should download this file to the `/usr/local/bin` directory:

    cd /usr/local/bin
    sudo curl -LO http://do.co/assign-ip

This script allows you to re-assign an existing floating IP by running:

    python /usr/local/bin/assign-ip floating_ip droplet_ID

This will only work if you have an environmental variable called `DO_TOKEN` set to a valid DigitalOcean API token for your account.

### Create a DigitalOcean API Token

In order to use the script above, we will need to create a DigitalOcean API token in our account.

In the control panel, click on the “API” link at the top. On the right-hand side of the API page, click “Generate new token”:

![DigitalOcean generate API token](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_nginx_1404/generate_api_token.png)

On the next page, select a name for your token and click on the “Generate Token” button:

![DigitalOcean make new token](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_haproxy_1404/make_token.png)

On the API page, your new token will be displayed:

![DigitalOcean token](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_nginx_1404/new_token.png)

Copy the token **now**. For security purposes, there is no way to display this token again later. If you lose this token, you will have to destroy it and create another one.

### Configure a Floating IP for your Infrastructure

Next, we will create and assign a floating IP address to use for our servers.

In the DigitalOcean control panel, click on the “Networking” tab and select the “Floating IPs” navigation item. Select your primary load balancer from the menu for the initial assignment:

![DigitalOcean add floating IP](https://assets.digitalocean.com/site/ControlPanel/fip_assign_to_primary.png)

A new floating IP address will be created in your account and assigned to the Droplet specified:

![DigitalOcean floating IP assigned](https://assets.digitalocean.com/site/ControlPanel/fip_assigned_to_primary.png)

If you visit the floating IP in your web browser, you should see the default Nginx page served from one of the backend web servers:

![DigitalOcean default index.html](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_haproxy_1404/default_index.png)

Copy the floating IP address down. You will need this value in the script below.

### Create the Wrapper Script

Now, we have the items we need to create the wrapper script that will call our `/usr/local/bin/assign-ip` script with the correct credentials.

Create the file now on **both** of your load balancers by typing:

    sudo nano /etc/keepalived/master.sh

Inside, start by assigning and exporting a variable called `DO_TOKEN` that holds the API token you just created. Below that, we can assign a variable called `IP` that holds your floating IP address:

/etc/keepalived/master.sh

    export DO_TOKEN='digitalocean_api_token'
    IP='floating_ip_addr'

Next, we will use `curl` to ask the metadata service for the Droplet ID of the server we’re currently on. This will be assigned to a variable called `ID`. We will also ask whether this Droplet currently has the floating IP address assigned to it. We will store the results of that request in a variable called `HAS_FLOATING_IP`:

/etc/keepalived/master.sh

    export DO_TOKEN='digitalocean_api_token'
    IP='floating_ip_addr'
    ID=$(curl -s http://169.254.169.254/metadata/v1/id)
    HAS_FLOATING_IP=$(curl -s http://169.254.169.254/metadata/v1/floating_ip/ipv4/active)

Now, we can use the variables above to call the `assign-ip` script. We will only call the script if the floating IP is not already associated with our Droplet. This will help minimize API calls and will help prevent conflicting requests to the API in cases where the master status switches between your servers rapidly.

To handle cases where the floating IP already has an event in progress, we will retry the `assign-ip` script a few times. Below, we attempt to run the script 10 times, with a 3 second interval between each call. The loop will end immediately if the floating IP move is successful:

/etc/keepalived/master.sh

    export DO_TOKEN='digitalocean_api_token'
    IP='floating_ip_addr'
    ID=$(curl -s http://169.254.169.254/metadata/v1/id)
    HAS_FLOATING_IP=$(curl -s http://169.254.169.254/metadata/v1/floating_ip/ipv4/active)
    
    if [$HAS_FLOATING_IP = "false"]; then
        n=0
        while [$n -lt 10]
        do
            python /usr/local/bin/assign-ip $IP $ID && break
            n=$((n+1))
            sleep 3
        done
    fi

Save and close the file when you are finished.

Now, we just need to make the script executable so that `keepalived` can call it:

    sudo chmod +x /etc/keepalived/master.sh

## Start Up the Keepalived Service and Test Failover

The `keepalived` daemon and all of its companion scripts should now be completely configured. We can start the service on both of our load balancers by typing:

    sudo start keepalived

The service should start up on each server and contact its peer, authenticating with the shared secret we configured. Each daemon will monitor the local HAProxy process, and will listen to signals from the remote `keepalived` process.

Your primary load balancer, which should have the floating IP address assigned to it currently, will direct requests to each of the backend Nginx servers in turn. There is some simple session stickiness that is usually applied, making it more likely that you will get the same backend when making requests through a web browser.

We can test failover in a simple way by simply turning off HAProxy on our primary load balancer:

    sudo service haproxy stop

If we visit our floating IP address in our browser, we might momentarily get an error indicating the page could not be found:

    http://floating_IP_addr

![DigitalOcean page not available](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_nginx_1404/page_not_available.png)

If we refresh the page a few times, in a moment, our default Nginx page will come back:

![DigitalOcean default index.html](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/keepalived_haproxy_1404/default_index.png)

Our HAProxy service is still down on our primary load balancer, so this indicates that our secondary load balancer has taken over. Using `keepalived`, the secondary server was able to determine that a service interruption had occurred. It then transitioned to the “master” state and claimed the floating IP using the DigitalOcean API.

We can now start HAProxy on the primary load balancer again:

    sudo service haproxy start

The primary load balancer will regain control of the floating IP address in a moment, although this should be rather transparent to the user.

## Visualizing the Transition

In order to visualize the transition between the load balancers better, we can monitor some of our server logs during the transition.

Since information about which proxy server is being used is not returned to the client, the best place to view the logs is from the actual backend web servers. Each of these servers should maintain logs about which clients request assets. From the Nginx service’s perspective, the client is the load balancer that makes requests on behalf of the real client.

### Tail the Logs on the Web Servers

On each of our backend web servers, we can `tail` the `/var/log/nginx/access.log` location. This will show each request made to the server. Since our load balancers split traffic evenly using a round-robin rotation, each backend web server should see about half of the requests made.

The client address is fortunately the very first field in the access log. We can extract the value using a simple `awk` command. Run the following on **both** of your Nginx web servers:

    sudo tail -f /var/log/nginx/access.log | awk '{print $1;}'

These will likely show mostly a single address:

    Output. . .
    
    primary_lb_private_IP
    primary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP

If you reference your server IP addresses, you will notice that these are mostly coming from your primary load balancer. Note that the actual distribution will likely be a bit different due to some simple session stickiness that HAProxy implements.

Keep the `tail` command running on both of your web servers.

### Automate Requests to the Floating IP

Now, on your local machine, we will request the web content at the floating IP address once every 2 seconds. This will allow us to easily see the load balancer change happen. In your local terminal, type the following (we are throwing away the actual response, because this should be the same regardless of which load balancer is being utilized):

    while true; do curl -s -o /dev/null floating_IP; sleep 2; done

On your web servers, you should begin to see new requests come in. Unlike requests made through a web browser, simple `curl` requests do not exhibit the same session stickiness. You should see a more even split of the requests to your backend web servers.

### Interrupt the HAProxy Service on the Primary Load Balancer

Now, we can again shut down the HAProxy service on our primary load balancer:

    sudo service haproxy stop

After a few seconds, on your web servers, you should see the list of IPs transition from the primary load balancer’s private IP address to the secondary load balancer’s private IP address:

    Output. . .
    
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP

All of the new requests are made from your secondary load balancer.

Now, start up the HAProxy instance again on your primary load balancer:

    sudo service haproxy start

You will see the client requests transition back to the primary load balancer’s private IP address within a few seconds:

    Output. . .
    
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    secondary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP
    primary_lb_private_IP

The primary server has regained control of the floating IP address and has resumed its job as the main load balancer for the infrastructure.

## Configure Nginx to Log Actual Client IP Address

As you have seen, the Nginx access logs show that all client requests are from the private IP address of the current load balancer, instead of the actual IP address of the client that originally made the request (i.e. your local machine). It is often useful to log the IP address of the original client, instead of the load balancer server. This is easily achieved by making a few changes to the Nginx configuration on all of your backend web servers.

On both web servers, open the `nginx.conf` file in an editor:

    sudo nano /etc/nginx/nginx.conf

Find the “Logging Settings” section (within the `http` block), and add the following line:

add to /etc/nginx/nginx.conf

    log_format haproxy_log 'ProxyIP: $remote_addr - ClientIP: $http_x_forwarded_for - $remote_user [$time_local] ' '"$request" $status $body_bytes_sent "$http_referer" ' '"$http_user_agent"';

Save and exit. This specifies a new log format called `haproxy_log`, which adds the `$http_x_forwarded_for` value — the IP address of the client that made the original request — to the default access log entries. We also are including `$remote_addr`, which is the IP address of the reverse proxy load balancer (i.e. the active load balancer server).

Next, to put this new log format to use, we need to add a line to our default server block.

On both web servers, open the `default` server configuration:

    sudo nano /etc/nginx/sites-available/default

Within the `server` block (right below the `listen` directive is a good place), add the following line:

add to /etc/nginx/sites-available/default

            access_log /var/log/nginx/access.log haproxy_log;

Save and exit. This tells Nginx to write its access logs using the `haproxy_log` log format that we created above.

On both web servers, restart Nginx to put the changes into effect:

    sudo service nginx restart

Now your Nginx access logs should contain the actual IP addresses of the clients making requests. Verify this by tailing the logs of your app servers, as we did in the previous section. The log entries should look something like this:

    New Nginx access logs:. . .
    ProxyIP: load_balancer_private_IP - ClientIP: local_machine_IP - - [05/Nov/2015:15:05:53 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    . . .

If your logs look good, you’re all set!

## Conclusion

In this guide, we walked through the complete process of setting up a highly available, load balanced infrastructure. This configuration works well because the active HAProxy server can distribute the load to the pool of web servers on the backend. You can easily scale this pool as your demand grows or shrinks.

The floating IP and `keepalived` configuration eliminates the single point of failure at the load balancing layer, allowing your service to continue functioning even when the primary load balancer completely fails. This configuration is fairly flexible and can be adapted to your own application environment by setting up your preferred web stack behind the HAProxy servers.
