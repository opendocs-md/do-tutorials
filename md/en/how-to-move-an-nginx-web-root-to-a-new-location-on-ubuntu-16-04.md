---
author: Melissa Anderson
date: 2016-07-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-move-an-nginx-web-root-to-a-new-location-on-ubuntu-16-04
---

# How To Move an Nginx Web Root to a New Location on Ubuntu 16.04

## Introduction

On Ubuntu, by default, the Nginx web server stores its documents in `/var/www/html`, which is typically located on the root filesystem with the rest of the operating system. Sometimes, though, it’s helpful to move the document root to another location, such as a separate mounted filesystem. For example, if you serve multiple websites from the same Nginx instance, putting each site’s document root on its own volume allows you to scale in response to the needs of a specific site or client.

In this guide, we’ll show you how to move an Nginx document root to a new location.

## Prerequisites

To complete this guide, you will need:

- **An Ubuntu 16.04 server with a non-root user with `sudo` privileges**. You can learn more about how to set up a user with these privileges in our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide.

- **An Nginx web server** : If you haven’t already set one up, the in-depth article, [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04), can guide you.

- **A new location for your document root** : The new document root location is completely configurable based on your needs. If you are moving your document root to a different storage device, you will want to select a location under the device’s mount point. In this example, we will use the `/mnt/volume-nyc1-01` directory. If you are using Block Storage on DigitalOcean, [this guide](how-to-use-block-storage-on-digitalocean) will show you how to mount your drive before continuing with this tutorial.

## Step 1 — Copying Files to the New Location

On a fresh installation of Nginx, the document root is located at `/var/www/html`. If you’re working with an existing server, however, you may have a significantly different setup including multiple document roots in corresponding server block directives.

You can search for the location of additional document roots using `grep`. We’ll search in the `/etc/nginx/sites-enabled` directory to limit our focus to active sites. The `-R` flag ensures that `grep` will print both the line with the `root` directive and the filename in its output:

    grep "root" -R /etc/nginx/sites-enabled

The result will look something like the output below, although the names and number of results are likely to be different on an existing installation:

    Output/etc/nginx/sites-enabled/default: root /var/www/html;
    /etc/nginx/sites-enabled/default: # deny access to .htaccess files, if Apache's document root
    /etc/nginx/sites-enabled/default:# root /var/www/example.com;

Use the feedback from `grep` to make sure you’re copying the files that you want and updating the appropriate configuration files.

Now that we’ve confirmed the location of our document root, we’ll copy the files to their new location with `rsync`. Using the `-a` flag preserves the permissions and other directory properties, while`-v` provides verbose output so you can follow the progress.

**Note:** Be sure there is no trailing slash on the directory, which may be added if you use tab completion. When there’s a trailing slash, `rsync` will dump the contents of the directory into the mount point instead of transferring it into a containing `html` directory:

    sudo rsync -av /var/www/html /mnt/volume-nyc1-01

Now we’re ready to update the configuration.

## Step 2 — Updating the Configuration Files

Nginx makes use of both global and site specific configuration files. For background about the hierarchy of configuration files, take a look at [How To Configure The Nginx Web Server On a Virtual Private Server](how-to-configure-the-nginx-web-server-on-a-virtual-private-server).

If you’re working with an existing installation, you should modify the files you found earlier with the `grep` command. In our example, we’re going to look at the default configuration file called `default`.

Open the file in an editor:

    sudo nano /etc/nginx/sites-enabled/default

Then, find the line that begins with `root` and update it with the new location.

**Note:** You should look for other places the original path showed up and change those to the new location as well. In addition to the root, you may find things like aliases and rewrites that need updating, too.

/etc/nginx/sites-enabled/default

    . . .
           # include snippets/snakeoil.conf;
           root /mnt/volume-nyc1-01/html;
    
    
           # Add index.php to the list if you are using PHP
    
    
           index index.html index.htm index.nginx-debian.html;
           server_name _;
    . . .

When you’ve made all of the necessary changes, save and close the file.

## Step 3 — Restarting Nginx

Once you’ve finished the configuration changes, you can make sure the syntax is correct with this command:

    sudo nginx -t

If everything is in order, it should return:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If the test fails, track down and fix the problems.

Once the test passes, restart Nginx:

    sudo systemctl restart nginx

When the server has restarted, visit your affected sites and ensure they’re working as expected. Once you’re comfortable everything is in order, don’t forget to remove the original copy of the data.

    sudo rm -Rf /var/www/html

## Conclusion

In this tutorial, we covered how to change the Nginx document root to a new location. This can help you with basic web server administration, like effectively managing multiple sites on a single server. It also allows you to take advantage of alternative storage devices such as network block storage, an important step in scaling a web site as its needs change.

If you’re managing a busy or growing web site, you might be interested in learning [how to set up Nginx with HTTP/2](how-to-set-up-nginx-with-http-2-support-on-ubuntu-16-04) to take advantage of its high transfer speed for content. You can also learn more about improving the production experience in this comparison of [five ways to improve your production web application server setup](5-ways-to-improve-your-production-web-application-server-setup).
