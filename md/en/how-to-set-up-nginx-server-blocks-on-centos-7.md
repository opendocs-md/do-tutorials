---
author: Josh Barnett
date: 2014-11-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-server-blocks-on-centos-7
---

# How To Set Up Nginx Server Blocks on CentOS 7

## Introduction

Nginx is one of the most popular web servers in the world, and is responsible for hosting some of the largest and highest-traffic sites on the Internet. In most cases, Nginx is lighter and more scalable than Apache, and can be used as a web server or as a reverse proxy.

Nginx uses **server blocks** to manage configurations for an individual site or domain. Server blocks allow one server to host multiple domains or interfaces by using a matching system. This is relevant to anyone looking to host more than one site off of a single VPS.

Each domain that is configured will direct the visitor to a specific directory holding that site’s information, without ever indicating that the same server is also responsible for other sites. This scheme is expandable without any software limit, as long as your server can handle the traffic that all of the sites attract.

In this guide, we will walk through how to set up Nginx server blocks on a CentOS 7 VPS. During this process, you’ll learn how to serve different content to different visitors depending on which domains they are requesting.

## Prerequisites

Before you begin with this guide, there are a few steps that need to be completed first.

You will need access to a CentOS 7 server with a non-root user that has `sudo` privileges. If you haven’t configured this yet, you can run through the [CentOS 7 initial server setup guide](initial-server-setup-with-centos-7) to create this account.

You will also need to have Nginx installed in order to configure server blocks for it. If you want an entire LEMP (Linux, Nginx, MySQL, and PHP) stack on your server, you can follow our guide on [setting up a LEMP stack in CentOS 7](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7). If you only need Nginx, you can install it through Nginx’s `yum` repository:

First, add the Nginx repository to your server’s list of software sources.

    sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm

Now you can use `yum` to download and install Nginx.

    sudo yum install nginx

After these steps are complete, log in as your non-root user account through SSH and continue with the tutorial.

**Note:** The example configuration in this guide will make one server block for `example.com` and another for `example2.com`. These will be referenced throughout the guide, but you should substitute your own domains or values while following along. To learn how to set up your domain names with DigitalOcean, follow [this link](how-to-set-up-a-host-name-with-digitalocean).

If you do not have any real domains to play with, we will show you how to test your server block configuration with dummy values near the end of the tutorial.

## Step One — Create the Directory Structure

First, we need to make a directory structure that will hold the site data to serve to visitors.

Our **document root** (the top-level directory that Nginx looks at to find content to serve) will be set to individual directories in the `/var/www` directory. We will create a directory here for each of the server blocks that we plan on making.

Within each of these directories, we will create an `html` directory that will hold our actual files. This gives us some flexibility in our hosting.

We can make these directories using the `mkdir` command (with a `-p` flag that allows us to create a folder with a nested folder inside of it):

    sudo mkdir -p /var/www/example.com/html
    sudo mkdir -p /var/www/example2.com/html

Remember that the portions in red represent the domain names that we want to serve from our VPS.

### Grant Permissions

We now have the directory structure for our files, but they are owned by our `root` user. If we want our regular user to be able to modify files in our web directories, we can change the ownership with `chown`:

    sudo chown -R $USER:$USER /var/www/example.com/html
    sudo chown -R $USER:$USER /var/www/example2.com/html

The `$USER` variable will take the value of the user you are currently logged in as when you submit the command. By doing this, our regular user now owns the `public_html` subdirectories where we will be storing our content.

We should also modify our permissions a little bit to ensure that read access is permitted to the general web directory, and all of the files and folders inside, so that pages can be served correctly:

    sudo chmod -R 755 /var/www

Your web server should now have the permissions it needs to serve content, and your user should be able to create content within the appropriate folders.

## Step Two — Create Demo Pages for Each Site

Now that we have our directory structure in place, let’s create some content to serve.

Because this is just for demonstration and testing, our pages will be very simple. We are just going to make an `index.html` page for each site that identifies that specific domain.

Let’s start with `example.com`. We can open up an `index.html` file in our editor by typing:

    nano /var/www/example.com/html/index.html

In this file, create a simple HTML document that indicates the site that the page is connected to. For this guide, the file for our first domain will look like this:

    <html>
      <head>
        <title>Welcome to Example.com!</title>
      </head>
      <body>
        <h1>Success! The example.com server block is working!</h1>
      </body>
    </html>

Save and close the file when you are finished.

We can copy this file to use as the template for our second site’s `index.html` by typing:

    cp /var/www/example.com/html/index.html /var/www/example2.com/html/index.html

Now let’s open that file and modify the relevant pieces of information:

    nano /var/www/example2.com/html/index.html

    <html>
      <head>
        <title>Welcome to Example2.com!</title>
      </head>
      <body>
        <h1>Success! The example2.com server block is working!</h1>
      </body>
    </html>

Save and close this file as well. You now have the pages necessary to test the server block configuration.

## Step Three — Create New Server Block Files

Server block files are what specify the configuration of our separate sites and dictate how the Nginx web server will respond to various domain requests.

To begin, we will need to set up the directory that our server blocks will be stored in, as well as the directory that tells Nginx that a server block is ready to serve to visitors. The `sites-available` directory will keep all of our server block files, while the `sites-enabled` directory will hold symbolic links to server blocks that we want to publish. We can make both directories by typing:

    sudo mkdir /etc/nginx/sites-available
    sudo mkdir /etc/nginx/sites-enabled

**Note:** This directory layout was introduced by Debian contributors, but we are including it here for added flexibility with managing our server blocks (as it’s easier to temporarily enable and disable server blocks this way).

Next, we should tell Nginx to look for server blocks in the `sites-enabled` directory. To accomplish this, we will edit Nginx’s main configuration file and add a line declaring an optional directory for additional configuration files:

    sudo nano /etc/nginx/nginx.conf

Add these lines to the end of the `http {}` block:

    include /etc/nginx/sites-enabled/*.conf;
    server_names_hash_bucket_size 64;

The first line instructs Nginx to look for server blocks in the `sites-enabled` directory, while the second line increases the amount of memory that is allocated to parsing domain names (since we are now using multiple domains).

When you are finished making these changes, you can save and close the file. We are now ready to create our first server block file.

### Create the First Server Block File

By default, Nginx contains one server block called `default.conf` which we can use as a template for our own configurations. We can create our first server block config file by copying over the default file:

    sudo cp /etc/nginx/conf.d/default.conf /etc/nginx/sites-available/example.com.conf

Now, open the new file in your text editor with root privileges:

    sudo nano /etc/nginx/sites-available/example.com.conf

**Note:** Due to the configurations that we have outlined, all server block files _must_ end in `.conf`.

Ignoring the commented lines, the file will look similar to this:

    server {
        listen 80;
        server_name localhost;
    
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
    
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }

The first thing that we’re going to have to adjust is the `server_name`, which tells Nginx which requests to point to this server block. We’ll declare the main server name, `example.com`, as well as an additional alias to `www.example.com`, so that both `www.` and non-`www.` requests are served the same content:

    server_name example.com www.example.com;

**Note:** Each Nginx statement must end with a semi-colon (`;`), so check each of your statement lines if you are running into problems later on.

Next, we want to modify the document root, specified by the `root` directive. Point it to the site’s document root that you created:

    root /var/www/example.com/html;

We’ll also want to add a `try_files` command that ends with a 404 error if the desired filename or directory is not found:

    try_files $uri $uri/ =404;

When you are finished, your file will look something like this:

    server {
        listen 80;
    
        server_name example.com www.example.com;
    
        location / {
            root /var/www/example.com/html;
            index index.html index.htm;
            try_files $uri $uri/ =404;
        }
    
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }

That is all we need for a basic configuration, so save and close the file to exit.

### Create the Second Server Block File

Now that we have our first server block file established, we can create our second one by copying that file and adjusting it as needed.

Start by copying it with `cp`:

    sudo cp /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-available/example2.com.conf

Open the new file with root privileges in your text editor:

    sudo nano /etc/nginx/sites-available/example2.com.conf

You now need to modify all of the pieces of information to reference your second domain. When you are finished, your second server block file may look something like this:

    server {
        listen 80;
    
        server_name example2.com www.example2.com;
    
        location / {
            root /var/www/example2.com/html;
            index index.html index.htm;
            try_files $uri $uri/ =404;
        }
    
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    }

When you are finished making these changes, you can save and close the file.

## Step Four — Enable the New Server Block Files

Now that we have created our server block files, we need to enable them so that Nginx knows to serve them to visitors. To do this, we can create a symbolic link for each server block in the `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/example.com.conf /etc/nginx/sites-enabled/example.com.conf
    sudo ln -s /etc/nginx/sites-available/example2.com.conf /etc/nginx/sites-enabled/example2.com.conf

When you are finished, restart Nginx to make these changes take effect:

    sudo systemctl restart nginx

## Step Five — Set Up Local Hosts File (Optional)

If you have been using example domains instead of actual domains to test this procedure, you can still test the functionality of your server blocks by temporarily modifying the `hosts` file on your local computer. This will intercept any requests for the domains that you configured and point them to your VPS server, just as the DNS system would do if you were using registered domains. However, this will only work from your local computer, and is simply useful for testing purposes.

**Note:** Make sure that you are operating on your local computer for these steps and not your VPS server. You will need access to the administrative credentials for that computer.

If you are on a Mac or Linux computer, edit your local `hosts` file with administrative privileges by typing:

    sudo nano /etc/hosts

If you are on a Windows machine, you can find instructions on altering your hosts file [here](http://support.microsoft.com/kb/923947).

The details that you need to add are the public IP address of your VPS followed by the domain that you want to use to reach that VPS:

    127.0.0.1 localhost
    127.0.1.1 guest-desktop
    server_ip_address example.com
    server_ip_address example2.com

This will direct any requests for `example.com` and `example2.com` on our local computer and send them to our server at `server_ip_address`.

## Step Six — Test Your Results

Now that you have your server blocks configured, you can test your setup easily by going to the domains that you configured in your web browser:

    http://example.com

You should see a page that looks like this:

![Success! The example.com server block is working!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/server_blocks_centos7/server_block_success.png)

Likewise, if you visit your other domains, you will see the files that you created for them.

If all of the sites that you configured work well, then you have successfully configured your new Nginx server blocks on the same CentOS server.

If you adjusted your home computer’s `hosts` file, you may want to delete the lines that you added now that you’ve verified that your configuration works. This will prevent your hosts file from being filled with entries that are not actually necessary.

## Conclusion

At this point, you should now have a single CentOS 7 server handling multiple sites with separate domains. You can expand this process by following the steps we outlined above to make additional server blocks later. There is no software limit on the number of domain names Nginx can handle, so feel free to make as many as your server is capable of handling.
