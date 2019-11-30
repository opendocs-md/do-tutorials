---
author: Jon Schwenn
date: 2016-03-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-change-your-php-settings-on-ubuntu-14-04
---

# How To Change Your PHP Settings on Ubuntu 14.04

## Introduction

PHP is a server side scripting language used by many popular CMS and blog platforms like WordPress and Drupal. It is also part of the popular LAMP and LEMP stacks. Updating the PHP configuration settings is a common task when setting up a PHP-based website. Locating the exact PHP configuration file may not be easy. There are multiple installations of PHP running normally on a server, and each one has its own configuration file. Knowing which file to edit and what the current settings are can be a bit of a mystery.

This guide will show how to view the current PHP configuration settings of your web server and how to make updates to the PHP settings.

## Prerequisites

For this guide, you need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up).
- An understanding of editing files on a Linux system. The [Basic Linux Navigation and File Management](basic-linux-navigation-and-file-management#editing-files) tutorial explains how to edit files.
- A web server with PHP installed.

There are many web server configurations with PHP, but here are two common methods:

- [How To Install a LAMP stack on Ubuntu 14.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04)
- [One-Click Install LAMP on Ubuntu 14.04 with DigitalOcean](https://www.digitalocean.com/features/one-click-apps/)

This tutorial is applicable to these DigitalOcean One-click Apps as well:

- LAMP
- LEMP
- [WordPress](one-click-install-wordpress-on-ubuntu-14-04-with-digitalocean)
- [PHPMyAdmin](how-to-use-the-phpmyadmin-one-click-application-image)
- [Magento](how-to-use-the-magento-one-click-install-image)
- [Joomla](how-to-use-the-digitalocean-joomla-one-click-application)
- [Drupal](how-to-use-the-digitalocean-one-click-drupal-image)
- [Mediawiki](how-to-use-the-mediawiki-one-click-application-image)
- [ownCloud](how-to-use-the-owncloud-one-click-install-application)

**Note:** This tutorial assumes you are running Ubuntu 14.04. Editing the `php.ini` file should be the same on other systems, but the file locations might be different.

All the commands in this tutorial should be run as a non-root user. If root access is required for the command, it will be preceded by `sudo`.

## Reviewing the PHP Configuration

You can review the live PHP configuration by placing a page with a `phpinfo` function along with your website files.

To create a file with this command, first change into the directory that contains your website files. For example, the default directory for webpage files for Apache on Ubuntu 14.04 is `/var/www/html/`:

    cd /var/www/html

Then, create the `info.php` file:

    sudo nano /var/www/html/info.php

Paste the following lines into this file and save it:

info.php

    <?php
    phpinfo();
    ?>

**Note:** Some DigitalOcean One-click Apps have an `info.php` file placed in the web root automatically.

When visiting the `info.php` file on your web server (http://[www.example.com](http://www.example.com)/info.php) you will see a page that displays details on the PHP environment, OS version, paths, and values of configuration settings. The file to the right of the **Loaded Configuration File** line shows the proper file to edit in order to update your PHP settings.

![PHP Info Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/php_edit/phpinfo.png)

This page can be used to reveal the current settings your web server is using. For example, using the _Find_ function of your web browser, you can search for the settings named **post\_max\_size** and **upload\_max\_filesize** to see the current settings that restrict file upload sizes.

**Warning:** Since the `info.php` file displays version details of the OS, Web Server, and PHP, this file should be removed when it is not needed to keep the server as secure as possible.

## Modifying the PHP Configuration

The `php.ini` file can be edited to change the settings and configuration of how PHP functions. This section gives a few common examples.

Sometimes a PHP application might need to allow for larger upload files such as uploading themes and plugins on a WordPress site. To allow larger uploads for your PHP application, edit the `php.ini` file with the following command (_Change the path and file to match your Loaded Configuration File. This example shows the path for Apache on Ubuntu 14.04._):

    sudo nano /etc/php5/apache2/php.ini

The default lines that control the file size upload are:

php.ini

    post_max_size = 8M
    upload_max_filesize = 2M

Change these default values to your desired maximum file upload size. For example, if you needed to upload a 30MB file you would changes these lines to:

php.ini

    post_max_size = 30M
    upload_max_filesize = 30M

Other common resource settings include the amount of memory PHP can use as set by `memory_limit`:

php.ini

    memory_limit = 128M

or `max_execution_time`, which defines how many seconds a PHP process can run for:

php.ini

    max_execution_time = 30

When you have the `php.ini` file configured for your needs, save the changes, and exit the text editor.

Restart the web server to enable the changes. For Apache on Ubuntu 14.04, this command will restart the web server:

    sudo service apache2 restart

Refreshing the `info.php` page should now show your updated settings. Remember to remove the `info.php` when you are done changing your PHP configuration.

## Conclusion

Many PHP-based applications require slight changes to the PHP configuration. By using the `phpinfo` function, the exact PHP configuration file and settings are easy to find. Use the method described in this article to make these changes.
