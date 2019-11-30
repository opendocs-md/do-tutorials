---
author: Brian Hogan
date: 2016-12-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-move-an-apache-web-root-to-a-new-location-on-debian-8
---

# How To Move an Apache Web Root to a New Location on Debian 8

## Introduction

On Debian 8, the Apache2 web server stores its documents in `/var/www/html` by default. This directory is located on the root filesystem with the rest of the operating system. You may want to move the document root to another location, such as a separate mounted filesystem. For example, if you serve multiple websites from the same Apache instance, putting each site’s document root on its own volume allows you to scale in response to the needs of a specific site or client.

In this guide, you’ll move the Apache document root to a new location by moving the files and changing Apache’s configuration files.

## Prerequisites

To complete this guide, you will need:

- A Debian 8 server with a non-root user with `sudo` privileges. You can learn more about how to set up a user with these privileges in our [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8) guide.

- An Apache2 web server: If you haven’t already set one up, the Apache section of the in-depth article, [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Debian 8](how-to-install-linux-apache-mysql-php-lamp-stack-on-debian-8), can guide you.

- A new location for your document root: The new document root location is completely configurable based on your needs. If you are moving your document root to a different storage device, you will want to select a location under the device’s mount point.

In this tutorial, we will use the directory `/mnt/volume-nyc1-01`, which points to a Block Storage volume attached to the server. If you’d like to use Block Storage to hold your web pages, complete the tutorial [How To Use Block Storage on DigitalOcean](how-to-use-block-storage-on-digitalocean) to mount your drive before you continue.

## Step 1 — Copying Files to the New Location

On a fresh installation of Apache, the document root is located at `/var/www/html`. If you’re working with an existing server, however, you may have a significantly different setup including multiple document roots in corresponding VirtualHost directives.

You can search for the location of additional document roots using `grep`. Search in the `/etc/apache2/sites-enabled` directory to limit your focus to active sites with the following command:

    grep -R "DocumentRoot" /etc/apache2/sites-enabled

The `-R` flag ensures that `grep` will print both the DocumentRoot and the filename in its output.

The result will look something like the following, although the names and number of results are likely to be different on an existing installation:

    Outputsites-enabled/000-default.conf DocumentRoot /var/www/html

Use the feedback from `grep` to make sure you’re moving the files that you want to move and updating their appropriate configuration files.

Now that you’ve confirmed the location of your document root, copy the files to their new location with `rsync`.

First, install `rsync` with

    sudo apt-get install rsync

Then execute this command to copy the files:

    sudo rsync -av /var/www/html /mnt/volume-nyc1-01

Using the `-a` flag preserves the permissions and other directory properties, while`-v` provides verbose output so you can follow the progress. Learn more about using `rsync` in the tutorial [How To Use Rsync to Sync Local and Remote Directories on a VPS](how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps).

**Note:** Be sure there is no trailing slash on the directory, which may be added if you use tab completion. When there’s a trailing slash, `rsync` will dump the contents of the directory into the mount point instead of transferring it into a containing `html` directory:

The files are now in their new location, but Apache is still looking in the old location, so let’s fix that.

## Step 2 — Updating the Configuration Files

Apache2 makes use of both global and site specific configuration files. For background about the hierarchy of configuration files, take a look at [How To Configure the Apache Web Server on an Ubuntu or Debian VPS](how-to-configure-the-apache-web-server-on-an-ubuntu-or-debian-vps#the-apache-file-hierarchy-in-ubuntu-and-debian).

If you’re working with an existing installation, you should modify the virtual host files you found earlier with the `grep` command. For this example, we’re going to look at the two Virtual Host files that ship with Apache by default, `000-default.conf` and `default-ssl.conf`.

Start by editing the `000-default.conf`file:

    sudo nano /etc/apache2/sites-enabled/000-default.conf

Find the line that begins with `DocumentRoot` and update it with the new location:

/etc/apache2/sites-enabled/000-default.conf

    <VirtualHost *:80>
     ...
            ServerAdmin webmaster@localhost
            DocumentRoot /mnt/volume-nyc1-01/html

Next, look for a `Directory` block that also points to the original path and update it to point to the new path.

On a fresh installation, there are no `Directory` entries in the default site. Add the following code to your configuration file so Apache can serve files from your new location:

/etc/apache2/sites-enabled/000-default.conf

     ...
         ServerAdmin webmaster@localhost
         DocumentRoot /mnt/volume-nyc1-01/html
    
         <Directory />
             Options FollowSymLinks
             AllowOverride None
         </Directory>
         <Directory /mnt/volume-nyc1-01/html/>
             Options Indexes FollowSymLinks MultiViews
             AllowOverride None
             Require all granted
        </Directory>
     ...

The first `Directory` block sets some restrictive default permissions, and the second block configures the options for the new web root in `/mnt/volume-nyc1-01/html/`

**Note:** You should look for other places the original path showed up, and change those to the new location as well. In addition to the `DocumentRoot` and `Directory` settings, you may find things like aliases and rewrites that need updating, too. Wherever you see the original document root’s path in the output of `grep`, you’ll want to update the path to reflect the new location.

After you make the necessary changes, save the file.

Next, we’ll turn our attention to the SSL configuration. On a fresh installation, SSL won’t be configured yet, but you’ll probably want to update the `ssl-default.conf` file to avoid some issues later if you don’t remember that you need to make the change.

**Note:** If SSL is not enabled, then the `ssl-default.conf` file is located only in `/etc/apache2/sites-available.` If you enable SSL with `sudo a2ensite ssl-default`, a symlink is created from the file in `sites-available` to `/etc/apache2/sites-enabled`. In that case, you can edit the file from either directory.

Edit the file:

    sudo nano /etc/apache2/sites-available/ssl-default.conf

Then make the same changes you made previously, by changing the `DocumentRoot` and ensuring the `Directory` rules are configured properly:

 /etc/apache2/sites-available/ssl-default.conf

     ...
    <IfModule mod_ssl.c>
      <VirtualHost _default_:443>
         ServerAdmin webmaster@localhost
         DocumentRoot /mnt/volume-nyc1-01
    
         <Directory />
             Options FollowSymLinks
             AllowOverride None
         </Directory>
         <Directory /mnt/volume-nyc1-01/html/>
             Options Indexes FollowSymLinks MultiViews
             AllowOverride None
             Require all granted
        </Directory>
     ...

Once you’ve finished the configuration changes, ensure the syntax is correct with the following command:

    sudo apachectl configtest

You’ll see output like the following:

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, 
    using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

On a default installation, you’ll see the preceding message, which you can safely ignore. As long as you see `Syntax OK`, restart the web server. Otherwise, track down and fix the problems it reported.

Use the following command to restart Apache:

    sudo systemctl reload apache2

When the server has restarted, visit your affected sites and ensure they’re working as expected. Once you’re comfortable everything is in order, don’t forget to remove the original copy of the data.

## Conclusion

In this tutorial, you changed the Apache document root to a new location. This can help you with basic web server administration, like effectively hosting multiple sites on a single server. It also allows you to take advantage of alternative storage devices such as network block storage, an important step in scaling a web site as its needs change.

If you’re managing a busy or growing web site, you might be interested in learning [how to load test your web server](how-to-use-apache-jmeter-to-perform-load-testing-on-a-web-server) to identify performance bottlenecks before you encounter them in production. You can also learn more about improving the production experience in this comparison of [five ways to improve your production web application server setup](5-ways-to-improve-your-production-web-application-server-setup).
