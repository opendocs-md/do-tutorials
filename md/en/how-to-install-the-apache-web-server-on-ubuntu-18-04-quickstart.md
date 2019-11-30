---
author: Kathleen Juell
date: 2018-07-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-18-04-quickstart
---

# How To Install the Apache Web Server on Ubuntu 18.04 [Quickstart]

## Introduction

The Apache HTTP server is the most widely-used web server in the world. It provides many powerful features, including dynamically loadable modules, robust media support, and extensive integration with other popular software.

In this guide, we’ll explain how to install an Apache web server on your Ubuntu 18.04 server. For a more detailed version of this tutorial, please refer to [How To Install the Apache Web Server on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04).

## Prerequisites

Before you begin this guide, you should have the following:

- An Ubuntu 18.04 server and a regular, non-root user with sudo privileges. Additionally, you will need to enable a basic firewall to block non-essential ports. You can learn how to configure a regular user account and set up a firewall for your server by following our [initial server setup guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

When you have an account available, log in as your non-root user to begin.

## Step 1 — Installing Apache

Apache is available within Ubuntu’s default software repositories, so you can install it using conventional package management tools.

Update your local package index:

    sudo apt update

Install the `apache2` package:

    sudo apt install apache2

## Step 2 — Adjusting the Firewall

Check the available `ufw` application profiles:

    sudo ufw app list

    OutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Let’s enable the most restrictive profile that will still allow the traffic you’ve configured, permitting traffic on port `80` (normal, unencrypted web traffic):

    sudo ufw allow 'Apache'

Verify the change:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache (v6) ALLOW Anywhere (v6)

## Step 3 — Checking your Web Server

Check with the `systemd` init system to make sure the service is running by typing:

    sudo systemctl status apache2

    Output● apache2.service - The Apache HTTP Server
       Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Tue 2018-04-24 20:14:39 UTC; 9min ago
     Main PID: 2583 (apache2)
        Tasks: 55 (limit: 1153)
       CGroup: /system.slice/apache2.service
               ├─2583 /usr/sbin/apache2 -k start
               ├─2585 /usr/sbin/apache2 -k start
               └─2586 /usr/sbin/apache2 -k start

Access the default Apache landing page to confirm that the software is running properly through your IP address:

    http://your_server_ip

You should see the default Ubuntu 18.04 Apache web page:

![Apache default page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-16/small_apache_default.png)

## Step 4 — Setting Up Virtual Hosts (Recommended)

When using the Apache web server, you can use _virtual hosts_ (similar to server blocks in Nginx) to encapsulate configuration details and host more than one domain from a single server. We will set up a domain called **your\_domain** , but you should **replace this with your own domain name**. To learn more about setting up a domain name with DigitalOcean, see our [introduction to DigitalOcean DNS](an-introduction-to-digitalocean-dns).

Create the directory for `your_domain`:

    sudo mkdir /var/www/your_domain

Assign ownership of the directory:

    sudo chown -R $USER:$USER /var/www/your_domain

The permissions of your web roots should be correct if you haven’t modified your `unmask` value, but you can make sure by typing:

    sudo chmod -R 755 /var/www/your_domain

Create a sample `index.html` page using `nano` or your favorite editor:

    nano /var/www/your_domain/index.html

Inside, add the following sample HTML:

/var/www/your\_domain/index.html

    <html>
        <head>
            <title>Welcome to Your_domain!</title>
        </head>
        <body>
            <h1>Success! The your_domain virtual host is working!</h1>
        </body>
    </html>

Save and close the file when you are finished.

Make a new virtual host file at `/etc/apache2/sites-available/your_domain.conf`:

    sudo nano /etc/apache2/sites-available/your_domain.conf

Paste in the following configuration block, updated for our new directory and domain name:

/etc/apache2/sites-available/your\_domain.conf

    <VirtualHost *:80>
        ServerAdmin webmaster@localhost
        ServerName your_domain
        ServerAlias your_domain
        DocumentRoot /var/www/your_domain
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>

Save and close the file when you are finished.

Enable the file with `a2ensite`:

    sudo a2ensite your_domain.conf

Disable the default site defined in `000-default.conf`:

    sudo a2dissite 000-default.conf

Test for configuration errors:

    sudo apache2ctl configtest

You should see the following output:

    OutputSyntax OK

Restart Apache to implement your changes:

    sudo systemctl restart apache2

Apache should now be serving your domain name. You can test this by navigating to `http://your_domain`, where you should see something like this:

![Apache virtual host example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apache_virtual_hosts_ubuntu/vhost_your_domain.png)

## Conclusion

Now that you have your web server installed, you have many options for the type of content to serve and the technologies you want to use to create a richer experience.

If you’d like to build out a more complete application stack, check out this article on [how to configure a LAMP stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04).
