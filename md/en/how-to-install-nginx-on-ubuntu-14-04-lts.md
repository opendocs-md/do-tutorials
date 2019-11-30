---
author: Justin Ellingwood
date: 2014-04-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-14-04-lts
---

# How To Install Nginx on Ubuntu 14.04 LTS

## Introduction

Nginx is one of the most popular web servers in the world and is responsible for hosting some of the largest and highest-traffic sites on the internet. It is more resource-friendly than Apache in most cases and can be used as a web server or a reverse proxy.

In this guide, we’ll discuss how to get Nginx installed on your Ubuntu 14.04 server.

## Prerequisites

Before you begin this guide, you should have a regular, non-root user with `sudo` privileges configured on your server. You can learn how to configure a regular user account by following steps 1-4 in our [initial server setup guide for Ubuntu 14.04](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04).

When you have an account available, log in as your non-root user to begin.

## Step One — Install Nginx

We can install Nginx easily because the Ubuntu team provides an Nginx package in its default repositories.

Since this is our first interaction with the `apt` packaging system in this session, we should update our local package index before we begin so that we are using the most up-to-date information. Afterwards, we will install `nginx`:

    sudo apt-get update
    sudo apt-get install nginx

You will probably be prompted for your user’s password. Enter it to confirm that you wish to complete the installation. The appropriate software will be downloaded to your server and then automatically installed.

## Step Two — Check your Web Server

In Ubuntu 14.04, by default, Nginx automatically starts when it is installed.

You can access the default Nginx landing page to confirm that the software is running properly by visiting your server’s domain name or public IP address in your web browser.

If you do not have a domain name set up for your server, you can learn [how to set up a domain with DigitalOcean](https://digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) here.

If you do not have a spare domain name, or have no need for one, you can use your server’s public IP address. If you do not know your server’s IP address, you can get it a few different ways from the command line.

Try typing this at your server’s command prompt:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

You will get back one or two lines. You can try each in your web browser to see if they work.

An alternative is typing this, which should give you your public IP address as seen from another location on the internet:

    curl http://icanhazip.com

When you have your servers IP address or domain, enter it into your browser’s address bar:

    http://server\_domain\_name\_or\_IP

You should see the default Nginx landing page, which should look something like this:

![Nginx default page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1404/default_page.png)

This is the default page included with Nginx to show you that the server is installed correctly.

## Step Three — Manage the Nginx Process

Now that you have your web server up and running, we can go over some basic management commands.

To stop your web server, you can type:

    sudo service nginx stop

To start the web server when it is stopped, type:

    sudo service nginx start

To stop and then start the service again, type:

    sudo service nginx restart

We can make sure that our web server will restart automatically when the server is rebooted by typing:

    sudo update-rc.d nginx defaults

This should already be enabled by default, so you may see a message like this:

    System start/stop links for /etc/init.d/nginx already exist.

This just means that it was already configured correctly and that no action was necessary. Either way, your Nginx service is now configured to start up at boot time.

## Conclusion

Now that you have your web server installed, you have many options for the type of content to serve and the technologies you want to use to create a richer experience.

Learn [how to use Nginx server blocks](https://www.digitalocean.com/community/articles/how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-14-04-lts) here. If you’d like to build out a more complete application stack, check out this article on [how to configure a LEMP stack on Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04).

By Justin Ellingwood
