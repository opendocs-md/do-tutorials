---
author: Mitchell Anicas
date: 2015-11-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-high-availability-haproxy-setup-with-corosync-pacemaker-and-floating-ips-on-ubuntu-14-04
---

# How To Create a High Availability HAProxy Setup with Corosync, Pacemaker, and Floating IPs on Ubuntu 14.04

## Introduction

This tutorial will show you how to create a High Availability HAProxy load balancer setup on DigitalOcean, with the support of a Floating IP and the Corosync/Pacemaker cluster stack. The HAProxy load balancers will each be configured to split traffic between two backend application servers. If the primary load balancer goes down, the Floating IP will be moved to the second load balancer automatically, allowing service to resume.

![High Availability HAProxy setup](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high_availability/ha-diagram-animated.gif)

**Note:** [DigitalOcean Load Balancers](an-introduction-to-digitalocean-load-balancers) are a fully-managed, highly available load balancing service. The Load Balancer service can fill the same role as the manual high availability setup described here. Follow our [guide on setting up Load Balancers](how-to-create-your-first-digitalocean-load-balancer) if you wish to evaluate that option.

## Prerequisites

In order to complete this guide, you will need to have completed the [How To Create a High Availability Setup with Corosync, Pacemaker, and Floating IPs on Ubuntu 14.04](how-to-create-a-high-availability-setup-with-corosync-pacemaker-and-floating-ips-on-ubuntu-14-04) tutorial (you should skip the optional **Add Nginx Resource** section). This will leave you with two Droplets, which we’ll refer to as **primary** and **secondary** , with a Floating IP that can transition between them. Collectively, we’ll refer to these servers as **load balancers**. These are the Droplets where we’ll install a load balancer, HAProxy.

You will also need to be able to create two additional Ubuntu 14.04 Droplets in the same datacenter, with Private Networking enabled, to demonstrate that the HA load balancer setup works. These are the servers that will be load balanced by HAProxy. We will refer to these application servers, which we will install Nginx on, as **app-1** and **app-2**. If you already have application servers that you want to load balance, feel free to use those instead.

On each of these servers, you will need a non-root user configured with `sudo` access. You can follow our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04) to learn how to set up these users.

## Create App Droplets

The first step is to create two Ubuntu Droplets, with Private Networking enabled, in the same datacenter as your load balancers, which will act as the **app-1** and **app-2** servers described above. We will install Nginx on both Droplets and replace their index pages with information that uniquely identifies them. This will allow us a simple way to demonstrate that the HA load balancer setup is working. If you already have application servers that you want to load balance, feel free to adapt the appropriate parts of this tutorial to make that work (and skip any parts that are irrelevant to your setup).

If you want to follow the example setup, create two Ubuntu 14.04 Droplets, **app-1** and **app-2** , and use this bash script as the user data:

Example User Data

    #!/bin/bash
    
    apt-get -y update
    apt-get -y install nginx
    export HOSTNAME=$(curl -s http://169.254.169.254/metadata/v1/hostname)
    export PUBLIC_IPV4=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    echo Droplet: $HOSTNAME, IP Address: $PUBLIC_IPV4 > /usr/share/nginx/html/index.html

This user data will install Nginx and replace the contents of index.html with the droplet’s hostname and public IP address (by referencing the Metadata service). Accessing either Droplet will show a basic webpage with the Droplet hostname and public IP address, which will be useful for testing which app server the load balancers are directing traffic to.

## Gather Server Network Information

Before we begin the actual configuration of our infrastructure components, it is best to gather some information about each of your servers.

To complete this guide, you will need to have the following information about your servers:

- **app servers** : Private IP address
- **load balancers** Private and Anchor IP addresses

### Find Private IP Addresses

The easiest way to find your Droplet’s private IP address is to use `curl` to grab the private IP address from the DigitalOcean metadata service. This command should be run from within your Droplets. On each Droplet, type:

    curl 169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address && echo

The correct IP address should be printed in the terminal window:

    Private IP address:10.132.20.236

Perform this step on all four Droplets, and copy the Private IP addresses somewhere that you can easily reference.

### Find Anchor IP Addresses

The **anchor IP** is the local private IP address that the Floating IP will bind to when attached to a DigitalOcean server. It is simply an alias for the regular `eth0` address, implemented at the hypervisor level.

The easiest, least error-prone way of grabbing this value is straight from the DigitalOcean metadata service. Using `curl`, you can reach out to this endpoint on each of your servers by typing:

    curl 169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address && echo

The anchor IP will be printed on its own line:

    Output10.17.1.18

Perform this step on both of your load balancer Droplets, and copy the anchor IP addresses somewhere that you can easily reference.

## Configure App Servers

After gathering the data above, we can move on to configuring our services.

Note
In this setup, the software selected for the web server layer is fairly interchangeable. This guide will use Nginx because it is generic and rather easy to configure. If you are more comfortable with Apache or a (production-capable) language-specific web server, feel free to use that instead. HAProxy will simply pass client requests to the backend web servers which can handle the requests similarly to how it would handle direct client connections.  

We will start off by setting up our backend app servers. Both of these servers will simply serve their name and public IP address; in a real setup, these servers would serve identical content. They will only accept web connections over their private IP addresses. This will help ensure that traffic is directed exclusively through one of the two HAProxy servers we will be configuring later.

Setting up app servers behind a load balancer allows us to distribute the request burden among some number identical app servers. As our traffic needs change, we can easily scale to meet the new demands by adding or removing app servers from this tier.

### Configure Nginx to Only Allow Requests from the Load Balancers

If you’re following the example, and you used the provided **user data** when creating your app servers, your servers will already have Nginx installed. The next step is to make a few configuration changes.

We want to configure Nginx to only listen for requests on the private IP address of the server. Furthermore, we will only serve requests coming from the private IP addresses of our two load balancers. This will force users to access your app servers through your load balancers (which we will configure to be accessible only via the Floating IP address).

To make these changes, open the default Nginx server block file on each of your app servers:

    sudo vi /etc/nginx/sites-available/default

To start, we will modify the `listen` directives. Change the `listen` directive to listen to the current **app server’s private IP address** on port 80. Delete the extra `listen` line. It should look something like this:

/etc/nginx/sites-available/default (1 of 2)

    server {
        listen app_server_private_IP:80;
    
        . . .

Directly below the `listen` directive, we will set up two `allow` directives to permit traffic originating from the private IP addresses of our two load balancers. We will follow this up with a `deny all` rule to forbid all other traffic:

/etc/nginx/sites-available/default (2 of 2)

        allow load_balancer_1_private_IP;
        allow load_balancer_2_private_IP;
        deny all;

Save and close the files when you are finished.

Test that the changes that you made represent valid Nginx syntax by typing:

    sudo nginx -t

If no problems were reported, restart the Nginx daemon by typing:

    sudo service nginx restart

Remember to perform all of these steps (with the appropriate app server private IP addresses) on both app servers.

### Testing the Changes

To test that your app servers are restricted correctly, you can make requests using `curl` from various locations.

On your app servers themselves, you can try a simple request of the local content by typing:

    curl 127.0.0.1

Because of the restrictions we set in place in our Nginx server block files, this request will actually be denied:

    Outputcurl: (7) Failed to connect to 127.0.0.1 port 80: Connection refused

This is expected and reflects the behavior that we were attempting to implement.

Now, from either of the **load balancers** , we can make a request for either of our app server’s public IP address:

    curl web_server_public_IP

Once again, this should fail. The app servers are not listening on the public interface and furthermore, when using the public IP address, our app servers would not see the allowed private IP addresses in the request from our load balancers:

    Outputcurl: (7) Failed to connect to app_server_public_IP port 80: Connection refused

However, if we modify the call to make the request using the app server’s _private IP address_, it should work correctly:

    curl app_server_private_IP

The Nginx `index.html` page should be returned. If you used the example user data, the page should contain the name and public IP address of the app server being accessed:

    app server index.htmlDroplet: app-1, IP Address: 159.203.130.34

Test this from both load balancers to both app servers. Each request for the private IP address should succeed while each request made to the public addresses should fail.

Once the above behavior is demonstrated, we can move on. Our backend app server configuration is now complete.

## Remove Nginx from Load Balancers

By following the prerequisite **HA Setup with Corosync, Pacemaker, and Floating IPs** tutorial, your load balancer servers will have Nginx installed. Because we’re going to use HAProxy as the reverse proxy load balancer, we should delete Nginx and any associated cluster resources.

### Remove Nginx Cluster Resources

If you added an Nginx cluster resource while following the prerequisite tutorial, stop and delete the `Nginx` resource with these commands on **one of your load balancers** :

    sudo crm resource stop Nginx
    sudo crm configure delete Nginx

This should also delete any cluster settings that depend on the `Nginx` resource. For example, if you created a `clone` or `colocation` that references the `Nginx` resource, they will also be deleted.

### Remove Nginx Package

Now we’re ready to uninstall Nginx on **both of the load balancer servers**.

First, stop the Nginx service:

    sudo service nginx stop

Then purge the package with this command:

    sudo apt-get purge nginx

You may also want to delete the Nginx configuration files:

    sudo rm -r /etc/nginx

Now we’re ready to install and configure HAProxy.

## Install and Configure HAProxy

Next, we will set up the HAProxy load balancers. These will each sit in front of our web servers and split requests between the two backend app servers. These load balancers will be completely redundant, in an active-passive configuration; only one will receive traffic at any given time.

The HAProxy configuration will pass requests to both of the web servers. The load balancers will listen for requests on their anchor IP address. As mentioned earlier, this is the IP address that the floating IP address will bind to when attached to the Droplet. This ensures that only traffic originating from the floating IP address will be forwarded.

### Install HAProxy

This section needs to be performed on **both load balancer servers**.

We will install HAProxy 1.6, which is not in the default Ubuntu repositories. However, we can still use a package manager to install HAProxy 1.6 if we use a PPA, with this command:

    sudo add-apt-repository ppa:vbernat/haproxy-1.6

Update the local package index on your load balancers and install HAProxy by typing:

    sudo apt-get update
    sudo apt-get install haproxy

HAProxy is now installed, but we need to configure it now.

### Configure HAProxy

Open the main HAProxy configuration file:

    sudo vi /etc/haproxy/haproxy.cfg

Find the `defaults` section, and add the two following lines under it:

/etc/haproxy/haproxy.cfg (1 of 3)

        option forwardfor
        option http-server-close

The _forwardfor_ option sets HAProxy to add `X-Forwarded-For` headers to each request—which is useful if you want your app servers to know which IP address originally sent a request—and the _http-server-close_ option reduces latency between HAProxy and your users by closing connections but maintaining keep-alives.

Next, at the end of the file, we need to define our frontend configuration. This will dictate how HAProxy listens for incoming connections. We will bind HAProxy to the load balancer anchor IP address. This will allow it to listen for traffic originating from the floating IP address. We will call our frontend “http” for simplicity. We will also specify a default backend, `app_pool`, to pass traffic to (which we will be configuring in a moment):

/etc/haproxy/haproxy.cfg (2 of 3)

    frontend http
        bind load_balancer_anchor_IP:80
        default_backend app_pool

**Note:** The anchor IP is the only part of the HAProxy configuration that should differ between the load balancer servers. That is, be sure to specify the anchor IP of the load balancer server that you are currently working on.

Next, we can define the backend configuration. This will specify the downstream locations where HAProxy will pass the traffic it receives. In our case, this will be the private IP addresses of both of the Nginx app servers we configured:

/etc/haproxy/haproxy.cfg (3 of 3)

    backend app_pool
        server app-1 app_server_1_private_IP:80 check
        server app-2 app_server_2_private_IP:80 check

When you are finished making the above changes, save and exit the file.

Check that the configuration changes we made represent valid HAProxy syntax by typing:

    sudo haproxy -f /etc/haproxy/haproxy.cfg -c

If no errors were reported, restart your service by typing:

    sudo service haproxy restart

Again, be sure to perform all of the steps in this section on both load balancer servers.

### Testing the Changes

We can make sure our configuration is valid by testing with `curl` again.

From the load balancer servers, try to request the local host, the load balancer’s own public IP address, or the server’s own private IP address:

    curl 127.0.0.1
    curl load_balancer_public_IP
    curl load_balancer_private_IP

These should all fail with messages that look similar to this:

    Outputcurl: (7) Failed to connect to IP_address port 80: Connection refused

However, if you make a request to the load balancer’s _anchor IP address_, it should complete successfully:

    curl load_balancer_anchor_IP

You should see the Nginx `index.html` page of one of the app servers:

    app server index.htmlDroplet: app-1, IP Address: app1_IP_address

Perform the same curl request again:

    curl load_balancer_anchor_IP

You should see the `index.html` page of the other app server, because HAProxy uses round-robin load balancing by default:

    app server index.htmlDroplet: app-2, IP Address: app2_IP_address

If this behavior matches that of your system, then your load balancers are configured correctly; you have successfully tested that your load balancer servers are balancing traffic between both backend app servers. Also, your floating IP should already be assigned to one of the load balancer servers, as that was set up in the prerequisite **HA Setup with Corosync, Pacemaker, and Floating IPs** tutorial.

## Download HAProxy OCF Resource Agent

At this point, you have a basic, host-level failover in place but we can improve the setup by adding HAProxy as a cluster resource. Doing so will allow your cluster to ensure that HAProxy is running on the server that your Floating IP is assigned to. If Pacemaker detects that HAProxy isn’t running, it can restart the service or assign the Floating IP to the other node (that should be running HAProxy).

Pacemaker allows the addition of OCF resource agents by placing them in a specific directory.

On **both load balancer servers** , download the HAProxy OCF resource agent with these commands:

    cd /usr/lib/ocf/resource.d/heartbeat
    sudo curl -O https://raw.githubusercontent.com/thisismitch/cluster-agents/master/haproxy

On **both load balancer servers** , make it executable:

    sudo chmod +x haproxy

Feel free to review the contents of the resource before continuing. It is a shell script that can be used to manage the HAProxy service.

Now we can use the HAProxy OCF resource agent to define our `haproxy` cluster resource.

## Add haproxy Resource

With our HAProxy OCF resource agent installed, we can now configure an `haproxy` resource that will allow the cluster to manage HAProxy.

On **either load balancer server** , create the `haproxy` primitive resource with this command:

    sudo crm configure primitive haproxy ocf:heartbeat:haproxy op monitor interval=15s

The specified resource tells the cluster to monitor HAProxy every 15 seconds, and to restart it if it becomes unavailable.

Check the status of your cluster resources by using `sudo crm_mon` or `sudo crm status`:

    crm_mon:...
    Online: [primary secondary]
    
     FloatIP (ocf::digitalocean:floatip): Started primary
     Nginx (ocf::heartbeat:nginx): Started secondary

Unfortunately, Pacemaker might decide to start the `haproxy` and `FloatIP` resources on separate nodes because we have not defined any resource constraints. This is a problem because the Floating IP might be pointing to one Droplet while the HAProxy service is running on the other Droplet. Accessing the Floating IP will point you to a server that is not running the service that should be highly available.

To resolve this issue, we’ll create a **clone** resource, which specifies that an existing primitive resource should be started on multiple nodes.

Create a clone of the `haproxy` resource called “haproxy-clone” with this command:

    sudo crm configure clone haproxy-clone haproxy

The cluster status should now look something like this:

    crm_mon:Online: [primary secondary]
    
    FloatIP (ocf::digitalocean:floatip): Started primary
     Clone Set: haproxy-clone [Nginx]
         Started: [primary secondary]

As you can see, the clone resource, `haproxy-clone`, is now started on both of our nodes.

The last step is to configure a colocation restraint, to specify that the `FloatIP` resource should run on a node with an active `haproxy-clone` resource. To create a colocation restraint called “FloatIP-haproxy”, use this command:

    sudo crm configure colocation FloatIP-haproxy inf: FloatIP haproxy-clone

You won’t see any difference in the crm status output, but you can see that the colocation resource was created with this command:

    sudo crm configure show

Now, both of your servers should have HAProxy running, while only one of them, has the FloatIP resource running.

Try stopping the HAProxy service on either load balancer server:

    sudo service haproxy stop

You will notice that it will start up again sometime within the next 15 seconds.

Next, we’ll test your HA setup by rebooting your active load balancer server (the one that the `FloatIP` resource is currently “started” on).

## Test High Availability of Load Balancers

With your new High Availability HAProxy setup, you will want test that everything works as intended.

In order to visualize the transition between the load balancers better, we can monitor the app server Nginx logs during the transition.

Since information about which proxy server is being used is not returned to the client, the best place to view the logs is from the actual backend web servers. Each of these servers should maintain logs about which clients request assets. From the Nginx service’s perspective, the client is the load balancer that makes requests on behalf of the real client.

### Monitor the Cluster Status

While performing the upcoming tests, you might want to look at the real-time status of the cluster nodes and resources. You can do so with this command, on either load balancer server (as long as it is running):

    sudo crm_mon

The output should look something like this:

    crm_mon output:Last updated: Thu Nov 5 13:51:41 2015
    Last change: Thu Nov 5 13:51:27 2015 via cibadmin on primary
    Stack: corosync
    Current DC: secondary (2) - partition with quorum
    Version: 1.1.10-42f2063
    2 Nodes configured
    3 Resources configured
    
    Online: [primary secondary]
    
    FloatIP (ocf::digitalocean:floatip): Started primary
     Clone Set: haproxy-clone [haproxy]
         Started: [primary secondary]

This will show you which load balancer nodes are online, and which nodes the `FloatIP` and `haproxy` resources are started on.

Note that the node that the `FloatIP` resource is `Started` on, **primary** in the above example, is the load balancer server that the Floating IP is currently assigned to. We will refer to this server as the **active load balancer server**.

### Automate Requests to the Floating IP

On your local machine, we will request the web content at the floating IP address once every 2 seconds. This will allow us to easily see the how the active load balancer is handling incoming traffic. That is, we will see which backend app servers it is sending traffic to. In your local terminal, enter this command:

    while true; do curl floating_IP_address; sleep 2; done

Every two seconds, you should see a response from one of the backend app servers. It will probably alternate between **app-1** and **app-2** because HAProxy’s default balance algorithm, which we haven’t specified, is set to **round-robin**. So, your terminal should show something like this:

    [secondary_label curl loop output:
    Droplet: app-1, IP Address: app_1_IP_address
    Droplet: app-2, IP Address: app_2_IP_address
    ...

Keep this terminal window open so that requests are continually sent to your servers. They will be helpful in our next testing steps.

### Tail the Logs on the Web Servers

On each of our backend app servers, we can `tail` the `/var/log/nginx/access.log` location. This will show each request made to the server. Since our load balancers split traffic evenly using a round-robin rotation, each backend app server should see about half of the requests made.

The client address is the very first field in the access log, so it will be easy to find. Run the following on **both** of your Nginx app servers (in separate terminal windows):

    sudo tail -f /var/log/nginx/access.log

The first field should show private IP address of your active load balancer server, every four seconds (we’ll assume it’s the **primary** load balancer, but it could be the **secondary** one in your case):

    Output. . .
    primary_loadbalancer_IP - - [05/Nov/2015:14:26:37 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    primary_loadbalancer_IP - - [05/Nov/2015:14:26:37 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    . . .

Keep the `tail` command running on both of your app servers.

### Interrupt the HAProxy Service on the Primary Load Balancer

Now, let’s reboot the **primary** load balancer, to make sure that the Floating IP failover works:

    sudo reboot

Now pay attention to the Nginx access logs on both of your app servers. You should notice that, after the Floating IP failover occurs, the access logs show that the app servers are being accessed by a different IP address than before. The logs should indicate that the **secondary** load balancer server is sending the requests:

    Output. . .
    secondary_loadbalancer_IP - - [05/Nov/2015:14:27:37 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    secondary_loadbalancer_IP - - [05/Nov/2015:14:27:37 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    . . .

This shows that the failure of the primary load balancer was detected, and the Floating IP was reassigned to the secondary load balancer successfully.

You may also want to check the output of your local terminal (which is accessing the Floating IP every two seconds) to verify that the secondary load balancer is sending requests to both backend app servers:

    [secondary_label curl loop output:
    Droplet: app-1, IP Address: app_1_IP_address
    Droplet: app-2, IP Address: app_2_IP_address
    ...

You may also try the failover in the other direction, once the other load balancer is online again.

## Configure Nginx to Log Actual Client IP Address

As you have seen, the Nginx access logs show that all client requests are from the private IP address of the current load balancer, instead of the actual IP address of the client that originally made the request (i.e. your local machine). It is often useful to log the IP address of the original requestor, instead of the load balancer server. This is easily achieved by making a few changes to the Nginx configuration on all of your backend app servers.

On both **app servers** , open the `nginx.conf` file in an editor:

    sudo vi /etc/nginx/nginx.conf

Find the “Logging Settings” section (within the `http` block), and add the following line:

add to /etc/nginx/nginx.conf

    log_format haproxy_log 'ProxyIP: $remote_addr - ClientIP: $http_x_forwarded_for - $remote_user [$time_local] ' '"$request" $status $body_bytes_sent "$http_referer" ' '"$http_user_agent"';

Save and exit. This specifies a new log format called `haproxy_log`, which adds the `$http_x_forwarded_for` value—the IP address of the client that made the original request—to the default access log entries. We also are including `$remote_addr`, which is the IP address of the reverse proxy load balancer (i.e. the active load balancer server).

Next, to put this new log format to use, we need to add a line to our default server block.

On **both app servers** , open the `default` server configuration:

    sudo vi /etc/nginx/sites-available/default

Within the `server` block (right below the `listen` directive is a good place), add the following line:

add to /etc/nginx/sites-available/default

            access_log /var/log/nginx/access.log haproxy_log;

Save and exit. This tells Nginx to write its access logs using the `haproxy_log` log format that we recently created.

On **both app servers** , restart Nginx to put the changes into effect:

    sudo service nginx restart

Now your Nginx access logs should contain the actual IP addresses of the clients making requests. Verify this by tailing the logs of your app servers, as we did in the previous section. The log entries should look something like this:

    New Nginx access logs:. . .
    ProxyIP: load_balancer_private_IP - ClientIP: local_machine_IP - - [05/Nov/2015:15:05:53 -0500] "GET / HTTP/1.1" 200 43 "-" "curl/7.43.0"
    . . .

If your logs look good, you’re all set!

## Conclusion

In this guide, we walked through the complete process of setting up a highly available, load balanced infrastructure. This configuration works well because the active HAProxy server can distribute the load to the pool of app servers on the backend. You can easily scale this pool as your demand grows or shrinks.

The Floating IP and Corosync/Pacemaker configuration eliminates the single point of failure at the load balancing layer, allowing your service to continue functioning even when the primary load balancer completely fails. This configuration is fairly flexible and can be adapted to your own application environment by setting up your preferred application stack behind the HAProxy servers.
