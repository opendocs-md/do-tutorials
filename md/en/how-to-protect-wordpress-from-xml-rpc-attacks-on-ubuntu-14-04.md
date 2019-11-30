---
author: Jon Schwenn
date: 2016-02-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-protect-wordpress-from-xml-rpc-attacks-on-ubuntu-14-04
---

# How To Protect WordPress from XML-RPC Attacks on Ubuntu 14.04

## Introduction

WordPress is a popular and powerful CMS (content management system) platform. Its popularity can bring unwanted attention in the form of malicious traffic specially targeted at a WordPress site.

There are many instances where a server that has not been protected or optimized could experience issues or errors after receiving a small amount of malicious traffic. These attacks result in exhaustion of system resources causing services like MySQL to be unresponsive. The most common visual cue of this would be an `Error connecting to database` message. The web console may also display `Out of Memory` errors.

This guide will show you how to protect WordPress from XML-RPC attacks on an Ubuntu 14.04 system.

## Prerequisites

For this guide, you need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)

We assume you already have WordPress installed on an Ubuntu 14.04 Droplet. There are many ways to install WordPress, but here are two common methods:

- [How To Install Wordpress on Ubuntu 14.04](how-to-install-wordpress-on-ubuntu-14-04)
- [One-Click Install WordPress on Ubuntu 14.04 with DigitalOcean](one-click-install-wordpress-on-ubuntu-14-04-with-digitalocean)

All the commands in this tutorial should be run as a non-root user. If root access is required for the command, it will be preceded by `sudo`. [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to add users and give them sudo access.

## What is XML-RPC?

WordPress utilizes [XML-RPC](https://en.wikipedia.org/wiki/XML-RPC) to remotely execute [functions](https://codex.wordpress.org/XML-RPC_WordPress_API). The popular plugin JetPack and the WordPress mobile application are two great examples of how WordPress uses XML-RPC. This same functionality also can be exploited to send thousands of requests to WordPress in a short amount of time. This scenario is effectively a brute force attack.

## Recognizing an XML-RPC Attack

The two main ways to recognize an XML-RPC attack are as follows:

1) Seeing the “Error connecting to database” message when your WordPress site is down  
2) Finding many entries similar to `"POST /xmlrpc.php HTTP/1.0”` in your web server logs

The location of your web server log files depends on what Linux distribution you are running and what web server you are running.

For Apache on Ubuntu 14.04, use this command to search for XML-RPC attacks:

    grep xmlrpc /var/log/apache2/access.log

For Nginx on Ubuntu 14.04, use this command to search for XML-RPC attacks:

    grep xmlrpc /var/log/nginx/access.log

Your WordPress site is receiving XML-RPC attacks if the commands above result in many lines of output, similar to this example:

access.log

    111.222.333.444:80 555.666.777.888 - - [01/Jan/2016:16:33:50 -0500] "POST /xmlrpc.php HTTP/1.0" 200 674 "-" "Mozilla/4.0 (compatible: MSIE 7.0; Windows NT 6.0)"

The rest of this article focuses on three different methods for preventing further XML-RPC attacks.

## Method 1: Installing the Jetpack Plugin

Ideally, you want to prevent XML-RPC attacks before they happen. The [Jetpack](https://wordpress.org/plugins/jetpack/) plugin for WordPress can block the XML-RPC multicall method requests with its _Protect_ function. You will still see XML-RPC entries in your web server logs with Jetpack enabled. However, Jetpack will reduce the load on the database from these malicious log in attempts by nearly 90%.

**Note:** A WordPress.com account is required to activate the Jetpack plugin.

Jetpack installs easily from the WordPress backend. First, log into your WordPress control panel and select **Plugins-\>Add New** in the left menu.

![WordPress Plugins Menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/plugins_menu.png)

Jetpack should be automatically listed on the featured Plugins section of the **Add New** page. If you do not see it, you can search for **Jetpack** using the search box.

![Jetpack Install Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/jetpack_install.png)

Click the **Install Now** button to download, unpack, and install Jetpack. Once it is successfully installed, there will be an **Activate Plugin** link on the page. Click that **Activate Plugin** link. You will be returned to the **Plugins** page and a green header will be at the top that states **Your Jetpack is almost ready!**. Click the **Connect to Wordpress.com** button to complete the activation of Jetpack.

![Connect to Wordpress.com button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/connect.png)

Now, log in with a WordPress.com account. You can also create an account if needed.

![Log into Wordpress.com form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/log_in.png)

After you log into your WordPress.com account, Jetpack will be activated. You will be presented with an option to run **Jump Start** which will automatically enable common features of Jetpack. Click the **Skip** link at this step.

![Jump Start Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/jump_start.png).

The Protect function is automatically enabled, even if you skip the Jump Start process. You can now see a Jetpack dashboard which also displays the Protect function as being Active. White list IP addresses from potentially being blocked by _Protect_ by clicking the gear next to the **Protect** name.

![Jetpack Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/jetpack_dashboard.png)

Enter the IPv4 or IPv6 addresses that you want to white list and click the **Save** button to update the _Protect_ white list.

![Protect Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_xmlrpc/protect.png)

## Method 2: Enabling block-xmlrpc with a2enconf

The `a2enconf block-xmlrpc` feature was added to the DigitalOcean WordPress one-click image in December of 2015. With it, you can block all XML-RPC requests at the web server level.

**Note:** This method is only available on a [DigitalOcean One-Click WordPress Install](one-click-install-wordpress-on-ubuntu-14-04-with-digitalocean) created in December 2015 and later.

To enable the XML-RPC block script, run the following command on your Droplet with the DO WordPress one-click image installed:

    sudo a2enconf block-xmlrpc

Restart Apache to enable the change:

    sudo service apache2 restart

**Warning:** This method will stop anything that utilizes XML-RPC from functioning, including Jetpack or the WordPress mobile app.

## Method 3: Manually Blocking All XML-RPC Traffic

Alternatively, the XML-RPC block can manually be applied to your Apache or Nginx configuration.

For Apache on Ubuntu 14.04, edit the configuration file with the following command:

    sudo nano /etc/apache2/sites-available/000-default.conf

Add the highlighted lines below between the `<VirtualHost>` tags.

Apache VirtualHost Config

    <VirtualHost>
    …    
        <files xmlrpc.php>
          order allow,deny
          deny from all
        </files>
    </VirtualHost>

Save and close this file when you are finished.

Restart the web server to enable the changes:

    sudo service apache2 restart

For Nginx on Ubuntu 14.04, edit the configuration file with the following command (_change the path to reflect your configuration file_):

    sudo nano /etc/nginx/sites-available/example.com

Add the highlighted lines below within the server block:

Nginx Server Block File

    server {
    …
     location /xmlrpc.php {
          deny all;
        }
    }

Save and close this file when you are finished.

Restart the web server to enable the changes:

    sudo service nginx restart

**Warning:** This method will stop anything that utilizes XML-RPC from functioning, including Jetpack or the WordPress mobile app.

## Verifying Attack Mitigation Steps

Whatever method you chose to prevent attacks, you should verify that it is working.

If you enable the Jetpack Protect function, you will see XML-RPC requests continue in your web server logs. The frequency should be lower and Jetpack will reduce the load an attack can place on the database server process. Jetpack will also progressively block the attacking IP addresses.

If you manually block all XML-RPC traffic, your logs will still show attempts, but the resulting error code be something other than 200. For example entries in the Apache `access.log` file may look like:

access.log

    111.222.333.444:80 555.666.777.888 - - [01/Jan/2016:16:33:50 -0500] "POST /xmlrpc.php HTTP/1.0" 500 674 "-" "Mozilla/4.0 (compatible: MSIE 7.0; Windows NT 6.0)"

## Conclusion

By taking steps to mitigate malicious XML-RPC traffic, your WordPress site will consume less system resources. Exhausting system resources is the most common reason why a WordPress site would go offline on a VPS. The methods of preventing XML-RPC attacks mentioned in this article along with will ensure your WordPress site stays online.

To learn more about brute force attacks on WordPress XML-RPC, read [Sucuri.net — Brute Force Amplification Attacks Against WordPress XMLRPC](https://blog.sucuri.net/2015/10/brute-force-amplification-attacks-against-wordpress-xmlrpc.html).
