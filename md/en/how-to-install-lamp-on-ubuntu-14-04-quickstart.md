---
author: Mitchell Anicas
date: 2016-03-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-lamp-on-ubuntu-14-04-quickstart
---

# How To Install LAMP on Ubuntu 14.04 [Quickstart]

## Introduction

The LAMP stack (Linux, Apache, MySQL, PHP) is a group of open source software that is typically installed together to enable a server to host dynamic PHP websites and web apps. This guide includes the steps to set up a LAMP stack on Ubuntu 14.04, on a single server, so you can quickly get your PHP application up and running.

A more detailed version of this tutorial, with better explanations of each step, can be found [here](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04).

## Step 1: Update apt-get package lists

    sudo apt-get update

## Step 2: Install Apache, MySQL, and PHP packages

    sudo apt-get -y install apache2 mysql-server php5-mysql php5 libapache2-mod-php5 php5-mcrypt

When prompted, set and confirm a new password for the MySQL “root” user:

![Set MySQL root password](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/mysql_password.png)

## Step 3: Create MySQL database directory structure

    sudo mysql_install_db

## Step 4: Run basic MySQL security script

    sudo mysql_secure_installation

At the prompt, enter the password you set for the MySQL root account:

    MySQL root password prompt:Enter current password for root (enter for none):
    OK, successfully used password, moving on...

At the next prompt, if you are happy with your current MySQL root password, type “n” for “no”:

    MySQL root password prompt:Change the root password? [Y/n] n

For the remaining prompts, simply hit the “ENTER” key to accept the default values.

## Step 5: Configure Apache to prioritize PHP files (optional)

Open Apache’s `dir.conf` file in a text editor:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Edit the `DirectoryIndex` directive by moving `index.php` to the first item in the list, so it looks like this:

dir.conf — updated DirectoryIndex

    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm

Save and exit.

Restart Apache to put the change into place:

    sudo service apache2 restart

## Step 6: Test PHP processing (optional)

Create a basic test PHP script in `/var/www/html`:

    echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/info.php

Open the PHP script in a web browser. Replace your\_server\_IP\_address with your server’s public IP address:

    Visit in a web browser:http://your_server_IP_address/info.php

If you see a PHP info page, PHP processing is working:

![Example PHP info page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/phpinfo.png)

Delete the test PHP script:

    sudo rm /var/www/html/info.php

## Related Tutorials

Here are links to more detailed tutorials that are related to this guide:

- [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 14.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04)
- [How To Install Linux, nginx, MySQL, PHP (LEMP) stack on Ubuntu 14.04](how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04)
