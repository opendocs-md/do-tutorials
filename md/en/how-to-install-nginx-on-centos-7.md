---
author: Mitchell Anicas
date: 2014-07-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-7
---

# How To Install Nginx on CentOS 7

### About Nginx

Nginx is a high performance web server software. It is a much more flexible and lightweight program than Apache HTTP Server.

This tutorial will teach you how to install and start Nginx on your CentOS 7 server.

## Prerequisites

The steps in this tutorial require the user to have root privileges. You can see how to set that up by following steps 3 and 4 in the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) tutorial.

## Step One—Add Nginx Repository

To add the CentOS 7 EPEL repository, open terminal and use the following command:

    sudo yum install epel-release

## Step Two—Install Nginx

Now that the Nginx repository is installed on your server, install Nginx using the following `yum` command:

    sudo yum install nginx

After you answer yes to the prompt, Nginx will finish installing on your virtual private server (VPS).

## Step Three—Start Nginx

Nginx does not start on its own. To get Nginx running, type:

    sudo systemctl start nginx

If you are running a firewall, run the following commands to allow HTTP and HTTPS traffic:

    sudo firewall-cmd --permanent --zone=public --add-service=http 
    sudo firewall-cmd --permanent --zone=public --add-service=https
    sudo firewall-cmd --reload

You can do a spot check right away to verify that everything went as planned by visiting your server’s public IP address in your web browser (see the note under the next heading to find out what your public IP address is if you do not have this information already):

    http://server_domain_name_or_IP/

You will see the default CentOS 7 Nginx web page, which is there for informational and testing purposes. It should look something like this:

![CentOS 7 Nginx Default](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_1404/nginx_default.png)

If you see this page, then your web server is now correctly installed.

Before continuing, you will probably want to enable Nginx to start when your system boots. To do so, enter the following command:

    sudo systemctl enable nginx

Congratulations! Nginx is now installed and running!

### How To Find Your Server’s Public IP Address

To find your server’s public IP address, find the network interfaces on your machine by typing:

    ip addr

    1. lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    
    . . .
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    
    . . .

You may see a number of interfaces here depending on the hardware available on your server. The `lo` interface is the local loopback interface, which is not the one we want. In our example above, the `eth0` interface is what we want.

Once you have the interface name, you can run the following command to reveal your server’s public IP address. Substitute the interface name you found above:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

## Server Root and Configuration

If you want to start serving your own pages or application through Nginx, you will want to know the locations of the Nginx configuration files and default server root directory.

### Default Server Root

The default server root directory is `/usr/share/nginx/html`. Files that are placed in there will be served on your web server. This location is specified in the default server block configuration file that ships with Nginx, which is located at `/etc/nginx/conf.d/default.conf`.

### Server Block Configuration

Any additional server blocks, known as Virtual Hosts in Apache, can be added by creating new configuration files in `/etc/nginx/conf.d`. Files that end with `.conf` in that directory will be loaded when Nginx is started.

### Nginx Global Configuration

The main Nginx configuration file is located at `/etc/nginx/nginx.conf`. This is where you can change settings like the user that runs the Nginx daemon processes, and the number of worker processes that get spawned when Nginx is running, among other things.

## See More

Once you have Nginx installed on your cloud server, you can go on to [install a LEMP Stack](https://www.digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7).
