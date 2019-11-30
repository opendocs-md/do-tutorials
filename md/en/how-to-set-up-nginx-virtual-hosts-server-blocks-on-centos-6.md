---
author: Etel Sverdlov
date: 2012-06-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-virtual-hosts-server-blocks-on-centos-6
---

# How To Set Up nginx Virtual Hosts (Server Blocks) on CentOS 6

### About Virtual Hosts

Virtual Hosts are used to run more than one website or domain off of a single virtual private server.Note: according to the nginx website, Virtual Hosts are called Server Blocks on nginx. However, for the sake of easy comparison with Apache, I'll refer to them as virtual hosts throughout this tutorial.

## Intro

Make sure that nginx is installed on your VPS. If it is not, you can quickly install it with 2 steps.

Install the EPEL repository:

     su -c 'rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86\_64/epel-release-6-8.noarch.rpm'

Install nginx

    yum install nginx

## Step One— Create a New Directory

The first step in creating a virtual host is to a create a directory where we will keep the new website’s information.

This location will be your Document Root in the Nginx virtual configuration file later on. By adding a -p to the line of code, the command automatically generates all the parents for the new directory.

    sudo mkdir -p /var/www/example.com/public\_html

You will need to designate an actual DNS approved domain, or an IP address, to test that a virtual host is working. In this tutorial we will use example.com as a placeholder for a correct domain name.

However, should you want to use an unapproved domain name to test the process you will find information on how to make it work on your local computer in Step Six.

## Step Two—Grant Permissions

We need to grant ownership of the directory to the right user, instead of just keeping it on the root system. You can replace the "www" below with the appropriate username.

    sudo chown -R www:www /var/www/example.com/public\_html

Additionally, it is important to make sure that everyone is able to read our new files.

    sudo chmod 755 /var/www

Now you are all done with permissions.

## Step Three— Create the Page

We need to create a new file called index.html within the directory we made earlier.

    sudo vi /var/www/example.com/public\_html/index.html

We can add some text to the file so we will have something to look at when the the site redirects to the virtual host.

    &lthtml&gt &lthead&gt &lttitle\>www.example.com&lt/title&gt &lt/head&gt &ltbody&gt &lth1\>Success: You Have Set Up a Virtual Host&lt/h1&gt &lt/body&gt &lt/html&gt

Save and Exit

## Step Four—Set Up the Virtual Host

The next step is to enter into the nginx configuration file itself.

    sudo vi /etc/nginx/conf.d/virtual.conf

The virtual host file is already almost completely set up on your virtual server. To finish up, simply match the following configuration, modifying the server name and file location as needed:

     # # A virtual host using mix of IP-, name-, and port-based configuration # server { listen 80; # listen \*:80; server\_name example.com; location / { root /var/www/example.com/public\_html/; index index.html index.htm; } } 

Save and exit.

## Step Five—Restart nginx

We’ve made a lot of the changes to the configuration. Restart nginx and make the changes visible.

    /etc/init.d/nginx restart

## Optional Step Six—Setting Up the Local Hosts

If you have been using an actual domain or IP address to test your virtual servers, you do not need to set up local hosts. However, if you are using a generic domain that you do not own, this will guarantee that, on your computer only, you will be able to customize it.

For this step, make sure you are on the computer itself, not your VPS.

To proceed with this step you need to know your computer’s administrative password, otherwise you will be required to use an actual domain name or your IP address to test the virtual hosts.

Assuming that you do have admin access (gained by typing su and entering the correct password) here is how you can set up the local hosts.

On your local computer, type:

    nano /etc/hosts

You can add the local hosts' details to this file, as seen in the example below. As long as line with the IP address and server name is there, directing your browser toward, say, example.com will give you all the virtual host details for the corresponding IP address that you designated.

    # Host Database # # localhost is used to configure the loopback interface # when the system is booting. Do not change this entry. ## 127.0.0.1 localhost #Virtual Hosts 12.34.56.789 www.example.com 

However, it may be a good idea to delete these made up addresses out of the local hosts folder when you are done to avoid any future confusion.

## Step Seven—See Your Virtual Host in Action

Once you have finished setting up your virtual host, you can see how it looks online. Point your browser to your domain name or IP address, and you should see that the page displays, "Success—You Have Set Up a Virtual Host"

## Adding More Virtual Hosts

To create additional virtual hosts, you can just repeat the process above, being careful to set up a new document root with the appropriate new domain name each time. Then just copy and paste the new Virtual Host information into the nginx Config file, as shown below

    # # A virtual host using mix of IP-, name-, and port-based configuration # server { listen 80; # listen \*:80; server\_name example.com; location / { root /var/www/example.com/public\_html/; index index.html index.htm; } } server { listen 80; # listen \*:80; server\_name example.org; location / { root /var/www/example.org/public\_html/; index index.html index.htm; } }

By Etel Sverdlov
