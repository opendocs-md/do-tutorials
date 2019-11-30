---
author: Mitchell Anicas
date: 2014-05-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-haproxy-as-a-layer-4-load-balancer-for-wordpress-application-servers-on-ubuntu-14-04
---

# How To Use HAProxy As A Layer 4 Load Balancer for WordPress Application Servers on Ubuntu 14.04

## Introduction

In this tutorial, we will teach you how to use HAProxy as a layer 4 load balancer for your WordPress servers–specifically the web application tier. Load balancing the application servers adds redundancy to your setup, which increases reliability in case of server failures or networking issues, and spreads the load across multiple servers for increased read performance. We are assuming that your setup includes a WordPress application server that connects to a separate MySQL database server (see the prerequisites for a tutorial on how to set that up).

Layer 4 load balancing is suitable for your site if you are only running a single web server application. If your environment is more complex (e.g. you want to run WordPress and a static web server on separate servers, with a single entry point), you will need to look into Application Layer (Layer 7) load balancing.

This tutorial is written with WordPress as the example, but its general concepts can be used to load balance other, stateless web applications.

## Prerequisites

Before continuing with this tutorial, you should have completed the tutorial on setting up a WordPress site with a separate database server (or have a similar setup): [How To Set Up a Remote Database to Optimize Site Performance with MySQL](https://www.digitalocean.com/community/articles/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql)

After following that tutorial to set up WordPress on separate web application and database servers, you should have two VPSs. Because we will be dealing with several VPSs, for reference purposes, we will call your two existing VPSs the following:

- **wordpress-1** : Your WordPress web application server
- **mysql-1** : Your MySQL server for WordPress

An abstract view of your environment currently looks something like this:

![WordPress Application and Database Server](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/HAProxy/wordpress_web_server.png)

In addition to your current environment, we will require two additional VPSs during this tutorial. We will call them:

- **wordpress-2** : Your second WordPress web application server
- **haproxy-www** : Your HAProxy server, for load balancing

If you are unfamiliar with basic load-balancing concepts or terminology, like _layer 4 load balancing_ or _backends_ or _ACLs_, here is an article that explains the basics: [An Introduction to HAProxy and Load Balancing Concepts](https://www.digitalocean.com/community/articles/an-introduction-to-haproxy-and-load-balancing-concepts).

## Our Goal

By the end of this tutorial, we want to have an environment that looks like this:

![HAProxy Load Balanced Web Application](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/HAProxy/wordpress_layer4_appbalanced.png)

That is, your users will access your WordPress site by going to your HAProxy Server, which will forward them to your load balanced WordPress Application Servers in a round-robin fashion. Your two (or more, if you wish) will both access your MySQL database.

## Snapshot Your Current Environment

_Optional_: Before continuing with this tutorial, you will want to create snapshots of your current environment. Snapshotting serves two purposes in this tutorial:

1. To revert to a working environment if a mistake is made
2. To do a one-time replication of the original server, eliminating the need to install and configure PHP and Nginx again

**Note:** Beginning in October 2016, snapshots cost $0.05 per gigabyte per month, based on the amount of utilized space within the filesystem.

Take a snapshot of your _wordpress-1_ and _mysql-1_ VPSs.

Now that we have snapshots, we are ready to move on to building out the rest of our environment.

## Create Your Second Web Application Server

Now we need to create a second VPS that will share the load with our original web application server. There are two options for this:

1. Create a new VPS from the snapshot you took of the original VPS, _wordpress-1_
2. Create a new VPS from scratch and manually set it up with the same software and configuration as _wordpress-1_

With either method, be sure to select the _Private Networking_ option if it’s available. Private networking is recommended for all of the VPSs used in this tutorial.

**If you do not have a private networking option, substitute the private IP addresses with your VPSs public IP addresses.** Note that using public IP addresses when you are transmitting sensitive data, such as unencrypted database passwords between your application and database servers, is not good practice because that information will travel over the public internet.

### Option 1: Create New VPS With Snapshot

Create a new VPS called _wordpress-2_, using the snapshot you took of _wordpress-1_.

If you opted for this method, skip over “Option 2” to the “Synchronize Web Application Files” section.

### Option 2: Create New VPS From Scratch

This is an alternative to “Option 1.”

If you want to set up the _wordpress-2_ server from scratch, instead of using a snapshot of _wordpress-1_, make sure that you install the same software. Refer to the [Set Up the Web Server](https://www.digitalocean.com/community/articles/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql#SetUptheWebServer) section of the prerequisite document if you don’t remember how you installed and configured your original WordPress server.

For a quick reference, here is a list of the pertinent software and configuration files that you will need to install or replicate:

Software:

- MySQL Client
- Nginx
- PHP

To install this software, run the following on your _wordpress-2_ server:

    sudo apt-get update
    sudo apt-get install mysql-client
    sudo apt-get install nginx php5-fpm php5-mysql

Configuration Files that need to be edited or created to match your original application server:

- /etc/php5/fpm/php.ini
- /etc/php5/fpm/pool.d/[www.conf](http://www.conf)
- /etc/nginx/sites-available/example.com
- /etc/nginx/sites-enabled/example.com

Don’t forget to restart PHP and Nginx once you are done configuring the software, with these commands:

    sudo service php5-fpm restart
    sudo service nginx restart

After you are done installing and configuring your new application server, we will need to synchronize the WordPress application files.

## Synchronize Web Application Files

Before the application can be load balanced, we need to ensure that the new server’s web application files are synchronized with your original WordPress server. The location of these files is dependent on where you installed WordPress, and a few other files. In addition to the php files that WordPress needs to run, files uploaded and plugins installed through the WordPress interface need to be synchronized as they are uploaded or installed. In the prerequisite document, we installed WordPress in `/var/www/example.com`–we will use this location for all of our examples, but you need to substitute this with your actual WordPress install path.

There are a several ways to synchronize files between servers–NFS or glusterFS are both suitable options. We will use glusterFS to fulfill our synchronization needs because it allows each application server to store its own copy of the application files, while maintaining consistency across the file system. Here is a conceptual diagram of our target shared storage:

![glusterFS Shared Volume](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/HAProxy/wordpress_glusterfs.png)

If you are unfamiliar with any of the glusterFS terminology that is used in this section please refer to [this GlusterFS Tutorial](https://www.digitalocean.com/community/articles/how-to-create-a-redundant-storage-pool-using-glusterfs-on-ubuntu-servers), on which this section is based on.

**Note:** The following subsections jump between _wordpress-1_ and _wordpress-2_ servers frequently. Be sure to run the commands on the proper servers, or you will run into problems!

### Edit Hosts File

**Note:** If you have an internal DNS, and it has records for the private IP addresses of your VPSs, feel free to skip this step and substitute those host names for the rest of the glusterFS setup commands and configuration.

Otherwise, **on wordpress-1 and wordpress-2 VPSs:**

Edit /etc/hosts:

    sudo vi /etc/hosts

Add the following two lines, substituting the highlighted words with your application servers’ IP respective IP addresses:

    wordpress\_1\_private\_IP wordpress-1wordpress\_2\_private\_IP wordpress-2

Save and quit.

### Install GlusterFS and Configure a Replicated Volume

**On _wordpress-1_ and _wordpress-2_ VPSs:**

Use apt-get to install the glusterFS server software:

    sudo apt-get install glusterfs-server

**On wordpress-1** , run the following command to peer with your _wordpress-2_:

    sudo gluster peer probe wordpress-2

**On wordpress-2** , run the following command to peer with _wordpress-1_:

    sudo gluster peer probe wordpress-1

**On wordpress-1 and wordpress-2** , to create the location where glusterFS will store the files it manages, run:

    sudo mkdir /gluster-storage

**On wordpress-1** , to create a replicating glusterFS volume called `volume1`, which will store its data in `/gluster-storage` on both of your application servers, run:

    sudo gluster volume create volume1 replica 2 transport tcp wordpress-1:/gluster-storage wordpress-2:/gluster-storage force

    Expected Output: volume create: volume1: success: please start the volume to access data

**On wordpress-1** again, run the following command to start the glusterFS volume that you just created, `volume1`:

    sudo gluster volume start volume1

    Expected Output: volume start: volume1: success

**On wordpress-1** , if you want to see information about the glusterFS volume you just created and started, run:

    sudo gluster volume info

You should see that you have two glusterFS “bricks”, one for each WordPress server.

Now that we have a glusterFS volume running, let’s mount it so we can use it as a replicating filesystem.

### Mount Shared Storage

Let’s mount the filesystem on wordpress-1 first.

**On wordpress-1** , edit fstab so our shared file system will mount on boot:

    sudo vi /etc/fstab

Add the following line to the end of the file to use `/storage-pool` as our mount point. Feel free to substitute this (here and for the rest of this glusterFS setup):

    wordpress-1:/volume1/storage-pool glusterfs defaults,\_netdev 0 0

Save and Quit.

**On wordpress-1** , you are now able to mount the glusterFS volume to the `/storage_pool` filesystem:

    sudo mkdir /storage-poolsudo mount /storage-pool

That mounts the shared volume, /storage-pool, on your _wordpress-1_ VPS. You can run `df -h` and it should be listed as a mounted filesystem. Next, we will follow a similar process to mount the shared storage on _wordpress-2_.

**On wordpress-2** , edit fstab so our shared file system will mount on boot:

    sudo vi /etc/fstab

Add the following line to the end of the file to use `/storage-pool` as our mount point. If you used a different value, make sure you substitute that in here:

    wordpress-2:/volume1/storage-pool glusterfs defaults,\_netdev 0 0

**On wordpress-2** , you are now able to mount the glusterFS volume to the `/storage_pool` filesystem:

    sudo mkdir /storage-pool
    sudo mount /storage-pool

Now, any files that are created, modified, or deleted in the `/storage-pool` filesystem will be synchronized across both servers, even if one of the servers goes down temporarily.

### Move WordPress Files to Shared Storage

The next step is to move _wordpress-1_’s WordPress files to the shared storage. Please substitute the highlighted words with your own values. `/var/www/example.com` represents where your WordPress files were located (and where Nginx is looking for the files), and `example.com` by itself is simply the directory’s basename.

**On wordpress-1** , run these commands to move your WordPress application files to your shared filesystem, `/storage-pool`:

    sudo mv /var/www/example.com /storage-pool/ sudo chown www-data:www-data /storage-pool/example.com

Next, you will want to create a symbolic link, that points to the WordPress files on the shared filesystem, where your WordPress files were originally stored by running:

    sudo ln -s /storage-pool/example.com /var/www/example.com

Now your WordPress files are located on the shared filesystem, `/storage-pool`, and they are still accessible to Nginx via their original location, `/var/www/example.com`.

### Point New Application Server to Shared Storage

The next step is to create a symbolic link on our new web application server that points to the WordPress files on the shared filesystem.

If you created _wordpress-2_ using the **snapshot option** , run the following commands **on wordpress-2** :

    sudo rm /var/www/example.comsudo ln -s /storage-pool/example.com /var/www/example.com

If you created _wordpress-2 \*_from scratch **, run the following commands \*\*on wordpress-2** :

    sudo mkdir -p /var/wwwsudo ln -s /storage-pool/example.com /var/www/example.com

That’s it for synchronizing the WordPress application files! The next step is giving our new application server, _wordpress-2_, access to the database.

## Create a New Database User

Because MySQL identifies users by username and source host, we need to create a new _wordpressuser_ that can connect from our new application server, _wordpress-2_.

On your database VPS, _mysql-1_, connect to the MySQL console:

    mysql -u root -p

In the following MySQL statements, replace all of the highlighted words with whatever is appropriate for your environment:

- **wordpressuser** : your MySQL WordPress user. Ensure it is the same as the already existing username
- **wordpress_2_private\_IP** :the private IP of your _wordpress-2_ VPS
- **password** : your MySQL WordPress user’s password. Ensure it is the same as the already existing password (and that it’s a good password!)

Run this statement create a MySQL user that can connect from your new WordPress server, _wordpress-2_:

    CREATE USER 'wordpressuser'@'wordpress\_2\_private\_IP' IDENTIFIED BY 'password';

Again, substitute your own values for `wordpressuser`, `wordpress_2_private_IP`, and, if your _database_ isn’t named “wordpress”, make sure to change that as well.

    GRANT SELECT,DELETE,INSERT,UPDATE ON wordpress.\* TO 'wordpressuser'@'wordpress\_2\_private\_IP'; FLUSH PRIVILEGES;

Now your second web application server, _wordpress-2_, can log in to MySQL on your database server, _mysql-1_.

## Not Yet Load Balanced

Note that there are two web application servers that are running but the application isn’t load balanced because each server has to be accessed via their respective Public IP Addresses. We want to be able to access the application via the same URL, such as _[http://example.com/](http://example.com/)_, and have the traffic balanced between the two web application servers. This is where HAProxy comes in.

## Install HAProxy

Create a new VPS with Private Networking. For this tutorial, we will call it _haproxy-www_.

In our **haproxy-www** VPS, let’s install HAProxy with _apt-get_:

    sudo apt-get update
    sudo apt-get install haproxy

We need to enable the HAProxy init script, so HAProxy will start and stop along with your VPS.

    sudo vi /etc/default/haproxy

Change the value of `ENABLED` to `1` to enable the HAProxy init script:

    ENABLED=1

Save and quit. Now HAProxy will start and stop with your VPS. Also, you can now use the `service` command to control your HAProxy. Let’s check to see if it is running:

    user@haproxy-www:/etc/init.d$ sudo service haproxy status
    haproxy not running.

It is not running. That’s fine, because it needs to be configured before we can use it. Let’s configure HAProxy for our environment next.

## HAProxy Configuration

HAProxy’s configuration file is divided into two major sections:

- **Global** : sets process-wide parameters
- **Proxies** : consists of _defaults_, _listen_, _frontend_, and _backend_ parameters

Again, if you are unfamiliar with HAProxy or basic load-balancing concepts and terminology, please refer to this link: [An Introduction to HAProxy and Load Balancing Concepts  
](https://www.digitalocean.com/community/articles/an-introduction-to-haproxy-and-load-balancing-concepts)

### HAProxy Configuration: Global

**All of the HAProxy configuration should be done on your HAProxy VPS, _haproxy-www_.**

First, let’s make a copy of the default _haproxy.cfg_ file:

    cd /etc/haproxy; sudo cp haproxy.cfg haproxy.cfg.orig

Now open haproxy.cfg in a text editor:

    sudo vi /etc/haproxy/haproxy.cfg

You will see that there are two sections already defined: _global_ and _defaults_. First we will make a few changes to some of the default parameters.

Under _defaults_, look for the following lines:

    mode http
    option httplog

Replace the word “http” with “tcp in both instances:

    mode tcp
    option tcplog

Selecting tcp as the mode configures HAProxy to perform layer 4 load balancing. In our case, this means that all of the incoming traffic on a specific IP address and port will be forwarded to the same backend. If you are unfamiliar with this concept, please read the _Types of Load Balancing_ section in our [Intro to HAProxy](https://www.digitalocean.com/community/articles/an-introduction-to-haproxy-and-load-balancing-concepts#TypesofLoadBalancing).

Do not close the config file yet! We will add the proxy configuration next.

### HAProxy Configuration: Proxies

The first thing we want to add is a frontend. For a basic layer 4 load balancing setup, a frontend listens for traffic on a specific IP address and port then forwards incoming traffic to a specified backend.

At the end of the file, let’s add our frontend, _www_. Be sure to replace `haproxy_www_public_IP` with the **public IP** of your haproxy-www VPS:

    frontend www bind haproxy\_www\_public\_IP:80 default\_backend wordpress-backend

Here is an explanation of what each line in the frontend config snippet above means:

- **frontend www** : specifies a frontend named "www”, as we will use it to handle incoming www traffic
- **bind haproxy\_www\_public\_IP:80** : replace `haproxy_www_public_IP` with haproxy-www’s public IP address. This tells HAProxy that this frontend will handle the incoming network traffic on this IP address and port
- **default\_backend wordpress-backend** : this specifies that all of this frontend’s traffic will be forwarded to _wordpress-backend_, which we will define in the next step

After you are finished configuring the frontend, continue adding the backend by adding the following lines. Be sure to replace the highlighted words with the appropriate values:

    backend wordpress-backend balance roundrobin mode tcp server wordpress-1 wordpress\_1\_private\_IP:80 check server wordpress-2 wordpress\_2\_private\_IP:80 check

Here is an explanation of what each line in the backend config snippet above means:

- **backend wordpress-backend** : specifies a backend named “wordpress-backend”
- **balance roundrobin** : specifies that this backend will use the “roundrobin” load balancing algorithm
- **mode tcp** : specifies that this backend will use “tcp” or layer 4 proxying
- **server wordpress-1 …** : specifies a backend server named “wordpress-1”, the private IP (which you must substitute) and port that it is listening on, _80_ in this case. The “check” option makes the load balancer periodically perform a health check on this server
- **server wordpress-2 …** : this specifies a backend server named “wordpress-2”

Now save and quit. HAProxy is now ready to be started, but let’s enable logging first.

## Enabling HAProxy Logging

Enabling logging in HAProxy is very simple. First edit the rsyslog.conf file:

    sudo vi /etc/rsyslog.conf

Then find the following two lines, and uncomment them to enable UDP syslog reception. It should look like the following when you are done:

    $ModLoad imudp
    $UDPServerRun 514
    $UDPServerAddress 127.0.0.1

Now restart rsyslog to enable the new configuration:

    sudo service rsyslog restart

HAProxy logging is is now enabled! The log file will be created at `/var/log/haproxy.log` once HAProxy is started.

## Start HAProxy and PHP/Nginx

**On haproxy-www** , start HAProxy to make your config changes take effect:

    sudo service haproxy restart

Depending on how you set up your new application server, you might need to restart your WordPress application by restarting PHP and Nginx.

**On wordpress-2** , restart PHP and Nginx by running these commands:

    sudo service php5-fpm restart
    sudo service nginx restart

Now WordPress should be running on both of your application servers, and they are load balanced. But there is still one last configuration change to be made.

## Update WordPress Configuration

Now that your WordPress application’s URL has changed, we must update a couple of settings in WordPress.

**On either WordPress server** , edit your wp-config.php. It is located where you installed WordPress (in the tutorial, it was installed in _/var/www/example.com_ but your installation may vary):

    cd /var/www/example.com; sudo vi wp-config.php

Find the line near the top that says `define('DB_NAME', 'wordpress');` and add the following lines above it, substituting the highlighted values,:

    define('WP\_SITEURL', 'http://haproxy\_www\_public\_IP'); define('WP\_HOME', 'http://haproxy\_www\_public\_IP');

Save and quit. Now the WordPress URLs are configured to point to your load balancer instead of only your original WordPress server, which comes into play when you try and access the wp-admin Dashboard.

## Load Balancing Complete!

Your web application servers are now load balanced! Your load balanced WordPress is now accessible to your user via the public IP address or domain name of your load balancer, _haproxy-www_!

## Conclusion

Now the load of your users will be spread between your two WordPress servers. Additionally, if one of your WordPress application servers goes down, your site will still be available because the other WordPress server will be forwarded all of the traffic!

With this setup, remember that your HAProxy load balancer server, _haproxy-www_, and your database server, _mysql-1_, need to be running for your site to work properly.

By Mitchell Anicas
