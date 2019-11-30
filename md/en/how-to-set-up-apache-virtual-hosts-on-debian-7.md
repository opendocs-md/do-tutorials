---
author: Adam LaGreca
date: 2013-10-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-virtual-hosts-on-debian-7
---

# How To Set Up Apache Virtual Hosts on Debian 7

### What the Red Means

The lines that the user needs to enter or customize will be in red in this tutorial! The rest should mostly be copy-and-pastable.

### Virtual Hosts

Virtual Hosts are used to run more than one domain off of a single IP address. This is especially useful to people who need to run several sites off of one virtual private server-- each will display different information to the visitors, depending on which website the user is accessing.There is no limit to the number of virtual hosts that can be added to a VPS.

## Set Up

The steps in this tutorial require the user to have root privileges. You can see how to set that up in the [Initial Server Setup](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04). Choose whichever username you fancy.

Additionally, you need to have apache already installed and running on your virtual server. If you haven't already done so, use the following command:

    sudo apt-get install apache2

## Step One— Create a New Directory

First, it is necessary to create a directory where we will keep the new website’s information. This location will be your Document Root in the Apache virtual configuration file. By adding a -p to the line of code, the command automatically generates all the parents for the new directory.

You will need to designate an actual DNS approved domain (or an IP address) to test that a virtual host is working. In this tutorial, we will use example.com as a placeholder for a correct domain name.

    sudo mkdir -p /var/www/example.com/public\_html

\*If you want to use an unapproved domain name to test the process, you will find information on how to make it work on your local computer in Step Seven.

## Step Two—Grant Permissions

Now you must grant ownership of the directory to the user, as opposed to just keeping it on the root system.

     sudo chown -R $USER:$USER /var/www/example.com/public\_html 

Additionally, it is important to make sure that everyone will be able to read your new files.

     sudo chmod -R 755 /var/www

Now you are all done with permissions.

## Step Three— Create the Page

Within your configurations directory, create a new file called index.html

    sudo nano /var/www/example.com/public\_html/index.html

It's also useful to add some text to the file, in order to have something to look at when the IP redirects to the virtual host.

    &lthtml\> &lthead\> &lttitle\>www.example.com&lt/title\> &lt/head\> &ltbody\> &lth1\>Success: You Have Set Up a Virtual Host&lt/h1\> &lt/body\> &lt/html\>

Save & Exit.

## Step Four—Create the New Virtual Host File

The next step is to set up the apache configuration. We’re going to work off a duplicate—go ahead and make a copy of the file (naming it after your domain name) in the same directory:

     sudo cp /etc/apache2/sites-available/default /etc/apache2/sites-available/example.com

## Step Five—Turn on Virtual Hosts

Open up the new config file:

     sudo nano /etc/apache2/sites-available/example.com

We are going to set up a virtual host in this file.

To begin, insert a line for the ServerName under the ServerAdmin line.

     ServerName example.com 

The ServerName specifies the domain name that the virtual host uses.

If you want to make your site accessible from more than one name (ie with www in the URL), you can include the alternate names in your virtual host file by adding a ServerAlias Line. The beginning of your virtual host file would then look like this:

    &ltVirtualHost \*:80\> ServerAdmin webmaster@example.com ServerName example.com ServerAlias www.example.com [...]

The next step is to fill in the correct Document Root. For this section, write in the extension of the new directory created in Step One. If the document root is incorrect or absent you will not be able to set up the virtual host.

The section should look like this:

     DocumentRoot /var/www/example.com/public\_html 

You do not need to make any other changes to this file. Save and Exit.

The last step is to activate the host with the built-in apache shortcut:

     sudo a2ensite example.com

## Step Six—Restart Apache

Although there have been a lot of changes to the configuration and the virtual host is set up, none of the changes will take effect until Apache is restarted:

     sudo service apache2 restart

## Optional Step Seven—Setting Up the Local Hosts

If you have pointed your domain name to your virtual private server’s IP address you can skip this step. However, if want to try out your new virtual hosts without having to connect to an actual domain name, you can set up local hosts on your computer alone.

For this step, make sure you are on the computer itself andnot your droplet.

To proceed with this step, you need to know your computer’s administrative password; otherwise, you will be required to use an actual domain name to test the virtual hosts.

If you are on a Mac or Linux, access the root user (`su`) on the computer and open up your hosts file:

    nano /etc/hosts 

If you are on a Windows Computer, you can find the directions to alter the host file on the [Microsoft site](http://support.microsoft.com/kb/923947)

You can add the local hosts details to this file, as seen in the example below. As long as that line is there, directing your browser toward, say, example.com will give you all the virtual host details for the corresponding IP address.

    # Host Database # # localhost is used to configure the loopback interface # when the system is booting. Do not change this entry. ## 127.0.0.1 localhost #Virtual Hosts 12.34.56.789 example.com

However, it may be a good idea to delete these made up addresses out of the local hosts folder when you are done in order to avoid any future confusion.

## Step Eight—RESULTS: See Your Virtual Host in Action

Once you have finished setting up your virtual host you can see how it looks online. Type your ip address into the browser (ie. http://12.34.56.789)

It should look somewhat similar to my handy[screenshot](https://assets.digitalocean.com/tutorial_images/PoO8d.png)

Nice work!

## Creating More Virtual Hosts

To add more virtual hosts simply repeat the process above, being careful to set up a new document root with the appropriate domain name, and then creating and activating the new virtual host file.

### See More

Once you have set up your virtual hosts, you can proceed to [Create a SSL Certificate](https://www.digitalocean.com/community/articles/how-to-create-a-ssl-certificate-on-apache-for-centos-6) for your site or [Install an FTP server](https://www.digitalocean.com/community/articles/how-to-set-up-vsftpd-on-centos-6--2).

By Adam LaGreca
