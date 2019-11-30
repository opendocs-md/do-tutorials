---
author: Adam LaGreca
date: 2013-10-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-setup-nginx-server-blocks-on-debian-7
---

# How To Setup Nginx Server Blocks on Debian 7

### Server Blocks

Although nginx prefers the term "Server Blocks"-- these are simply virtual hosts that allow users to run more than one website or domain off of a single VPS. Although we will be using nginx for this tutorial, for the purposes of tradition and easy comparison with Apache we can simply refer to them as virtual hosts.

## 1) Set Up Your VPS

The steps in this tutorial require the user to have root privileges on the virtual private server. You can see how to set that up in the [Initial Server Setup Tutorial](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04) (steps 3 & 4). Furthermore, I will reference "user" throughout this tutorial-- feel free to replace this with any username you fancy.

You need to have nginx already installed on your VPS. If this is not the case, you can download it with this command:

    sudo apt-get install nginx

**\*Notice:** You will need to designate an actual [DNS approved domain](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) or IP address to test that a virtual host is working. Throughout this tutorial, I will simply use "example.com" to indicate when you should insert your correct domain name.

## 2) Create a New Directory

It is necessary to create a directory where you will keep the new website’s information. This location will be your Document Root in the Apache virtual configuration file later on.

By adding a -p to the line of code, the command automatically generates all the parents for the new directory.

    sudo mkdir -p /var/www/example.com/public\_html

## 3) Permissions on your VPS

It is important to remember to grant ownership of the directory to the right user. If you fail to do this, it will remain on the root system. Follow these commands to accomplish this:

    sudo chown -R user:user /var/www/example.com/public\_html

    sudo chmod 755 /var/www

This will not only make sure ownership belongs to the correct user-- the second command also insures that everyone will be able to read your new files.

## 4) Create the Page

This tutorial will use nano to edit configuration files on your VPS. Typically, it is simpler to use than other text editors; however, if you prefer another such as vi, feel free to utilize whichever.

We need to create a new file called index.html within the directory we created earlier.

    sudo nano /var/www/example.com/public\_html/index.html

We can add some text to the file so we will have something to look at when the the site redirects to the virtual host.

    &lthtml&gt &lthead&gt &lttitle\>www.example.com&lt/title&gt &lt/head&gt &ltbody&gt &lth1\>Success: You Have Set Up a Virtual Host&lt/h1&gt &lt/body&gt &lt/html&gt

Save and Exit.

## 5) Create the New Virtual Host File

The next step is to create a new file that contains all of our virtual host information.

Conveniently, nginx provides us with a layout for this file in the sites-available directory (/etc/nginx/sites-available). All you need is to copy the text into a new custom file:

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/example.com

## 6) Virtual Hosts

Open up the new virtual host file— you will see all the information you need to set up virtual host within.

     sudo nano /etc/nginx/sites-available/example.com

You'll need to make a few simple changes:

     server { listen 80; ## listen for ipv4; this line is default and implied #listen [::]:80 default ipv6only=on; ## listen for ipv6 root /var/www/example.com/public\_html; index index.html index.htm; # Make site accessible from http://localhost/ server\_name example.com; }

- Uncomment "listen 80" so that all traffic coming in through that port will be directed toward the site
- Change the root extension to match the directory that we made in Step One. If the document root is incorrect or absent, you will not be able to set up the virtual host
- Change the server name to your DNS approved domain name or, if you don't have one, you can use your IP address

Save and Exit.

Finally, you'll need to activate the host by creating a symbolic link between the sites-available directory and the sites-enabled directory on your cloud server. This is an easy step to skip, so make sure to enter the following command:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

To avoid the "conflicting server name error" and ensure that going to your site displays the correct information, you can delete the default nginx server block:

    sudo rm /etc/nginx/sites-enabled/default

## Step Six—Restart nginx

We’ve made a lot of the changes to the configuration. Restart nginx and make the changes visible.

    sudo service nginx restart

## 7) Let's Go Online

Once you have finished setting up your virtual host, type your domain name or IP address into the browser. It should display a message such as: **Success-- You Have Set Up a Virtual Host**.

Congratulations! Now to add additional virtual hosts on your cloud server, you can simply repeat the process above with a new document root/appropriate domaine name.
