---
author: Venkat
date: 2013-04-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-http-authentication-with-nginx-on-ubuntu-12-10
---

# How To Set Up HTTP Authentication With Nginx On Ubuntu 12.10

### What the Red Means

The lines that the user needs to enter or customize will be in red in this tutorial! The rest should mostly be copy-and-pastable.

### About Nginx

Nginx (pronounced as 'engine x') is an HTTP and reverse proxy server, as well as a mail proxy server, written by Igor Sysoev that is flexible and lightweight program when compared to apache. The official nginx documentation is [here](http://nginx.org/).

## Prerequisites

As a prerequisite, we are assuming that you have gone through the article on how to set up your VPS and also have installed Nginx on it. If not, you can find the article on setting up the VPS in the [initial server setup article](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04) and you can find more information on [installing nginx](https://www.digitalocean.com/community/articles/how-to-install-nginx-on-ubuntu-12-04-lts-precise-pangolin) in our community.

## Step 1: Apache Utils

We need htpasswd to create and generate an encrypted for the user using Basic Authentication. Install apache2-utils using the command below.

     sudo apt-get install apache2-utils 

## Step 2: Create User and Password

Create a .htpasswd file under your website directory being served by nginx. The following command would create the file and also add the user and an encrypted password to it.

     sudo htpasswd -c /etc/nginx/.htpasswd exampleuser

The tool will prompt you for a password.

     New password: Re-type new password: Adding password for user exampleuser

The structure of the htpasswd file would be like this:

     login:password 

Note that this htpasswd should be accessible by the user-account that is running Nginx.

## Step 3: Update Nginx configuration

Your nginx configuration file for the website should be under /etc/nginx/sites-available/. Add the two entries below under for the domain path that you want to secure.

     auth\_basic "Restricted"; auth\_basic\_user\_file /etc/nginx/.htpasswd; 

The second line is the location of the htpasswd file for your website.

For example, lets say our nginx configuration file is /etc/nginx/sites-available/website\_nginx.conf, open the file using vi or any editor of your choice.

     sudo vi /etc/nginx/sites-available/website\_nginx.conf 

Then add the two lines into the following path:

     server { listen portnumber; server\_name ip\_address; location / { root /var/www/mywebsite.com; index index.html index.htm; auth\_basic "Restricted"; #For Basic Auth auth\_basic\_user\_file /etc/nginx/.htpasswd; #For Basic Auth } } 

## Step 4: Reload Nginx

To reflect the changes on our website reload the nginx configuration and try to access the domain that has been secured using Basic Authentication.

     $ sudo /etc/init.d/nginx reload \* Reloading nginx configuration... 

Now try to access your website or the domain path that you have secured and you will notice a browser prompt that asks you to enter the login and password. Enter the details that you used while creating the .htpasswd file. The prompt does not allow you to access the website till you enter the right credentials.

And voila! You have your website domain path secured using Nginx's Basic Authentication.
