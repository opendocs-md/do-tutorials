---
author: Justin Ellingwood
date: 2014-04-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-14-04-lts
---

# How To Set Up Nginx Server Blocks (Virtual Hosts) on Ubuntu 14.04 LTS

## Introduction

When using the Nginx web server, `server blocks` (similar to the virtual hosts in Apache) can be used to encapsulate configuration details and host more than one domain off of a single server.

In this guide, we’ll discuss how to configure server blocks in Nginx on an Ubuntu 14.04 server.

## Prerequisites

We’re going to be using a non-root user with `sudo` privileges throughout this tutorial. If you do not have a user like this configured, you can make one by following steps 1-4 in our [Ubuntu 14.04 initial server setup](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04) guide.

You will also need to have Nginx installed on your server. If you want an entire LEMP (Linux, Nginx, MySQL, and PHP) stack on your server, you can follow our guide on [setting up a LEMP stack in Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04). If you only need Nginx, you can install it by typing:

    sudo apt-get update
    sudo apt-get install nginx

When you have fulfilled these requirements, you can continue on with this guide.

For demonstration purposes, we’re going to set up two domains with our Nginx server. The domain names we’ll use in this guide are `example.com` and `test.com`.

You can find a guide on [how to set up domain names with DigitalOcean](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) here. If you do not have two spare domain names to play with, use dummy names for now and we’ll show you later how to configure your local computer to test your configuration.

## Step One — Set Up New Document Root Directories

By default, Nginx on Ubuntu 14.04 has one server block enabled by default. It is configured to serve documents out of a directory at:

    /usr/share/nginx/html

We won’t use the default since it is easier to work with things in the `/var/www` directory. Ubuntu’s Nginx package does not use `/var/www` as its document root by default due to a [Debian policy about packages utilizing /var/www](http://lintian.debian.org/tags/dir-or-file-in-var-www.html).

Since we are users and not package maintainers, we can tell Nginx that this is where we want our document roots to be. Specifically, we want a directory for each of our sites within the `/var/www` directory and we will have a directory under these called `html` to hold our actual files.

First, we need to create the necessary directories. We can do this with the following command. The `-p` flag tells `mkdir` to create any necessary parent directories along the way:

    sudo mkdir -p /var/www/example.com/html sudo mkdir -p /var/www/test.com/html

Now that you have your directories created, we need to transfer ownership to our regular user. We can use the `$USER` environmental variable to substitute the user account that we are currently signed in on. This will allow us to create files in this directory without allowing our visitors to create content.

    sudo chown -R $USER:$USER /var/www/example.com/html sudo chown -R $USER:$USER /var/www/test.com/html

The permissions of our web roots should be correct already if you have not modified your `umask` value, but we can make sure by typing:

    sudo chmod -R 755 /var/www

Our directory structure is now configured and we can move on.

## Step Two — Create Sample Pages for Each Site

Now that we have our directory structure set up, let’s create a default page for each of our sites so that we will have something to display.

Create an `index.html` file in your first domain:

    nano /var/www/example.com/html/index.html

Inside the file, we’ll create a really basic file that indicates what site we are currently accessing. It will look like this:

    \<html\> \<head\> \<title\>Welcome to Example.com!\</title\> \</head\> \<body\> \<h1\>Success! The example.com server block is working!\</h1\> \</body\> \</html\>

Save and close the file when you are finished.

Since the file for our second site is basically going to be the same, we can copy it over to our second document root like this:

    cp /var/www/example.com/html/index.html /var/www/test.com/html/

Now, we can open the new file in our editor and modify it so that it refers to our second domain:

    nano /var/www/test.com/html/index.html

    \<html\> \<head\> \<title\>Welcome to Test.com!\</title\> \</head\> \<body\> \<h1\>Success! The test.com server block is working!\</h1\> \</body\> \</html\>

Save and close this file when you are finished. You now have some pages to display to visitors of our two domains.

## Step Three — Create Server Block Files for Each Domain

Now that we have the content we wish to serve, we need to actually create the server blocks that will tell Nginx how to do this.

By default, Nginx contains one server block called `default` which we can use as a template for our own configurations. We will begin by designing our first domain’s server block, which we will then copy over for our second domain and make the necessary modifications.

### Create the First Server Block File

As mentioned above, we will create our first server block config file by copying over the default file:

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/example.com

Now, open the new file you created in your text editor with root privileges:

    sudo nano /etc/nginx/sites-available/example.com

Ignoring the commented lines, the file will look similar to this:

    server { listen 80 default\_server; listen [::]:80 default\_server ipv6only=on; root /usr/share/nginx/html; index index.html index.htm; server\_name localhost; location / { try\_files $uri $uri/ =404; } }

First, we need to look at the listen directives. Only one of our server blocks can have the `default_server` specification. This specifies which block should server a request if the `server_name` requested does not match any of the available server blocks.

We are eventually going to disable the default server block configuration, so we can place the `default_server` option in either this server block or in the one for our other site. I’m going to leave the `default_server` option enabled in this server block, but you can choose whichever is best for your situation.

The next thing we’re going to have to adjust is the document root, specified by the `root` directive. Point it to the site’s document root that you created:

    root /var/www/example.com/html;

**Note** : Each Nginx statement _must_ end with a semi-colon (;), so check each of your lines if you are running into problems.

Next, we want to modify the `server_name` to match requests for our first domain. We can additionally add any aliases that we want to match. We will add a `www.example.com` alias to demonstrate:

    server\_name example.com www.example.com;

When you are finished, your file will look something like this:

    server { listen 80 default\_server; listen [::]:80 default\_server ipv6only=on; root /var/www/example.com/html; index index.html index.htm; server\_name example.com www.example.com; location / { try\_files $uri $uri/ =404; } }

That is all we need for a basic configuration. Save and close the file to exit.

### Create the Second Server Block File

Now that we have our initial server block configuration, we can use that as a basis for our second file. Copy it over to create a new file:

    sudo cp /etc/nginx/sites-available/example.com /etc/nginx/sites-available/test.com

Open the new file with root privileges in your editor:

    sudo nano /etc/nginx/sites-available/test.com

In this new file, we’re going to have to look at the `listen` directives again. If you left the `default_server` option enabled in the last file, you’ll have to remove it in this file. Furthermore, you’ll have to get rid of the `ipv6only=on` option, as it can only be specified once per address/port combination:

    listen 80;
    listen [::]:80;

Adjust the document root directive to point to your second domain’s document root:

    root /var/www/test.com/html;

Adjust the `server_name` to match your second domain and any aliases:

    server\_name test.com www.test.com;

Your file should look something like this with these changes:

    server { listen 80; listen [::]:80; root /var/www/test.com/html; index index.html index.htm; server\_name test.com www.test.com; location / { try\_files $uri $uri/ =404; } }

When you are finished, save and close the file.

## Step Four — Enable your Server Blocks and Restart Nginx

You now have your server blocks created, we need to enable them.

We can do this by creating symbolic links from these files to the `sites-enabled` directory, which Nginx reads from during startup.

We can create these links by typing:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/ sudo ln -s /etc/nginx/sites-available/test.com /etc/nginx/sites-enabled/

These files are now in the enabled directory. However, the default server block file we used as a template is also enabled currently and will conflict with our file that has the `default_server` parameter set.

We can disable the default server block file by simply removing the symbolic link. It will still be available for reference in the `sites-available` directory, but it won’t be read by Nginx on startup:

    sudo rm /etc/nginx/sites-enabled/default

We also need to adjust one setting really quickly in the default Nginx configuration file. Open it up by typing:

    sudo nano /etc/nginx/nginx.conf

We just need to uncomment one line. Find and remove the comment from this:

    server_names_hash_bucket_size 64;

Now, we are ready to restart Nginx to enable your changes. You can do that by typing:

    sudo service nginx restart

Nginx should now be serving both of your domain names.

## Step Five — Set Up Local Hosts File (Optional)

If you have not been using domain names that you own and instead have been using dummy values, you can modify your local computer’s configuration to allow you to temporarily test your Nginx server block configuration.

This will not allow other visitors to view your site correctly, but it will give you the ability to reach each site independently and test your configuration. This basically works by intercepting requests that would usually go to DNS to resolve domain names. Instead, we can set the IP addresses we want our local computer to go to when we request the domain names.

Make sure you are operating on your local computer during these steps and not your VPS server. You will need to have root access, be a member of the administrative group, or otherwise be able to edit system files to do this.

If you are on a Mac or Linux computer at home, you can edit the file needed by typing:

    sudo nano /etc/hosts

If you are on Windows, you can [find instructions for altering your hosts file](http://support.microsoft.com/kb/923947) here.

You need your server’s public IP address and the domains you want to route to the server. Assuming that my server’s public IP address is `111.111.111.111`, the lines I would add to my file would look something like this:

    127.0.0.1 localhost 127.0.0.1 guest-desktop 111.111.111.111 example.com111.111.111.111 test.com

This will intercept any requests for `example.com` and `test.com` and send them to your server, which is what we want if we don’t actually own the domains that we are using.

Save and close the file when you are finished.

## Step Six — Test your Results

Now that you are all set up, you should test that your server blocks are functioning correctly. You can do that by visiting the domains in your web browser:

    http://example.com

You should see a page that looks like this:

![Nginx first server block](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_server_block_1404/first_block.png)

If you visit your second domain name, you should see a slightly different site:

    http://test.com

![Nginx second server block](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_server_block_1404/second_block.png)

If both of these sites work, you have successfully configured two independent server blocks with Nginx.

At this point, if you adjusted your `hosts` file on your local computer in order to test, you’ll probably want to remove the lines you added.

If you need domain name access to your server for a public-facing site, you will probably want to purchase a domain name for each of your sites. You can learn how to [set them up to point to your server](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) here.

## Conclusion

You should now have the ability to create server blocks for each domain you wish to host from the same server. There aren’t any real limits on the number of server blocks you can create, so long as your hardware can handle the traffic.

By Justin Ellingwood
