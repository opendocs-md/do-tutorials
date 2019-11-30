---
author: Etel Sverdlov
date: 2012-08-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-load-balancing
---

# How To Set Up Nginx Load Balancing

### About Load Balancing

Loadbalancing is a useful mechanism to distribute incoming traffic around several capable Virtual Private servers.By apportioning the processing mechanism to several machines, redundancy is provided to the application -- ensuring fault tolerance and heightened stability. The Round Robin algorithm for load balancing sends visitors to one of a set of IPs. At its most basic level Round Robin, which is fairly easy to implement, distributes server load without implementing considering more nuanced factors like server response time and the visitors’ geographic region.

## Setup

The steps in this tutorial require the user to have root privileges on your VPS. You can see how to set that up in the [Users Tutorial](https://www.digitalocean.com/community/articles/how-to-add-and-delete-users-on-ubuntu-12-04-and-centos-6).

Prior to setting up nginx loadbalancing, you should have nginx installed on your VPS. You can install it quickly with apt-get:

    sudo apt-get install nginx

## Upstream Module

In order to set up a round robin load balancer, we will need to use the nginx upstream module. We will incorporate the configuration into the nginx settings.

Go ahead and open up your website’s configuration (in my examples I will just work off of the generic default virtual host):

    sudo nano /etc/nginx/sites-available/default

We need to add the load balancing configuration to the file.

First we need to include the upstream module which looks like this:

    upstream backend { server backend1.example.com; server backend2.example.com; server backend3.example.com; }

We should then reference the module further on in the configuration:

     server { location / { proxy\_pass http://backend; } }

Restart nginx:

    sudo service nginx restart

As long as you have all of the virtual private servers in place you should now find that the load balancer will begin to distribute the visitors to the linked servers equally.

## Directives

The previous section covered how to equally distribute load across several virtual servers. However, there are many reasons why this may not be the most efficient way to work with data. There are several directives that we can use to direct site visitors more effectively.

### Weight

One way to begin to allocate users to servers with more precision is to allocate specific weight to certain machines. Nginx allows us to assign a number specifying the proportion of traffic that should be directed to each server.

A load balanced setup that included server weight could look like this:

    upstream backend { server backend1.example.com weight=1; server backend2.example.com weight=2; server backend3.example.com weight=4; }

The default weight is 1. With a weight of 2, backend2.example will be sent twice as much traffic as backend1, and backend3, with a weight of 4, will deal with twice as much traffic as backend2 and four times as much as backend 1.

### Hash

IP hash allows servers to respond to clients according to their IP address, sending visitors back to the same VPS each time they visit (unless that server is down). If a server is known to be inactive, it should be marked as down. All IPs that were supposed to routed to the down server are then directed to an alternate one.

The configuration below provides an example:

    upstream backend { ip\_hash; server backend1.example.com; server backend2.example.com; server backend3.example.com down; }

### Max Fails

According to the default round robin settings, nginx will continue to send data to the virtual private servers, even if the servers are not responding. Max fails can automatically prevent this by rendering unresponsive servers inoperative for a set amount of time.

There are two factors associated with the max fails: max\_fails and fall\_timeout. Max fails refers to the maximum number of failed attempts to connect to a server should occur before it is considered inactive. Fall\_timeout specifies the length of that the server is considered inoperative. Once the time expires, new attempts to reach the server will start up again. The default timeout value is 10 seconds.

A sample configuration might look like this:

    upstream backend { server backend1.example.com max\_fails=3 fail\_timeout=15s; server backend2.example.com weight=2; server backend3.example.com weight=4;

## See More

This has been a short overview of simple Round Robin load balancing. Additionally, there are other ways to speed and optimize a server:

- [How to Configure Nginx as a Front End Proxy for Apache](https://www.digitalocean.com/community/articles/how-to-configure-nginx-as-a-front-end-proxy-for-apache)
- [How to Install and Configure Varnish with Apache on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-install-and-configure-varnish-with-apache-on-ubuntu-12-04--3)
- [How to Install and Use Memcache on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-install-and-use-memcache-on-ubuntu-12-04)

By Etel Sverdlov
