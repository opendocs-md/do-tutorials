---
author: Mitchell Anicas, Albert Valbuena
date: 2019-06-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0
---

# How To Install an Apache, MySQL, and PHP (FAMP) Stack on FreeBSD 12.0

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

A FAMP stack, which is similar to a LAMP stack on Linux, is a group of open source software that is typically installed together to enable a FreeBSD server to host dynamic websites and web apps. FAMP is an acronym that stands for **F** reeBSD (operating system), **A** pache (web server), **M** ySQL (database server), and **P** HP (to process dynamic PHP content).

In this guide, we’ll get a FAMP stack installed on a FreeBSD 12.0 cloud server using `pkg`, the FreeBSD package manager.

## Prerequisites

Before you begin this guide you’ll need the following:

- A [FreeBSD 12.0 Droplet](how-to-get-started-with-freebsd).
- Access to a user with root privileges (or allowed by using sudo) in order to make configuration changes.
- A firewall configured using this tutorial on [Recommended Steps For New FreeBSD 12.0 Servers](recommended-steps-for-new-freebsd-12-0-servers). Ensure you open ports `80` and `443` as part of your setup.
- Familiarity with the CLI (Command Line Interface) is recommended. FreeBSD’s vi editor has almost identical [syntax as vim](installing-and-using-the-vim-text-editor-on-a-cloud-server#modal-editing).

## Step 1 — Installing Apache

The Apache web server is currently the most popular web server in the world, which makes it a great choice for hosting a website.

You can install Apache using FreeBSD’s package manager, `pkg`. A package manager allows you to install most software pain-free from a repository maintained by FreeBSD. You can learn more about [how to use `pkg` here](how-to-manage-packages-on-freebsd-10-1-with-pkg).

To install Apache 2.4 using `pkg`, use this command:

    sudo pkg install apache24

Enter `y` at the confirmation prompt to install Apache and its dependencies.

To enable Apache as a service, add `apache24_enable="YES"` to the `/etc/rc.conf` file. You’ll use the `sysrc` command to do just that:

    sudo sysrc apache24_enable="YES"

Now start Apache:

    sudo service apache24 start

To check that Apache has started you can run the following command:

    sudo service apache24 status

As a result you’ll see something similar to:

    Outputapache24 is running as pid 20815.

You can do a spot check right away to verify that everything went as planned by visiting your server’s public IP address in your web browser. See the note under the next heading to find out what your public IP address is, if you do not have this information already:

    http://your_server_IP_address/

You will see the default FreeBSD Apache web page, which is there for testing purposes. You’ll see: **It Works!** , which indicates that your web server is correctly installed.

### How To find Your Server’s Public IP Address

If you do not know what your server’s public IP address is, there are a number of ways that you can find it. Usually, this is the address you use to connect to your server through SSH.

If you are using DigitalOcean, you may look in the Control Panel for your server’s IP address. You may also use the DigitalOcean Metadata service, from the server itself, with this command: `curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address`.

A more universal way to look up the IP address is to use the `ifconfig` command, on the server itself. The `ifconfig` command will print out information about your network interfaces. In order to narrow down the output to only the server’s public IP address, use this command (note that the highlighted part is the name of the network interface, and may vary):

    ifconfig vtnet0 | grep "inet " | awk '{ print $2; exit }'

You could also use `curl` to contact an outside party, like [icanhazip](https://major.io/icanhazip-com-faq/), to tell you how it sees your server. This is done by asking a specific server what your IP address is:

    curl http://icanhazip.com

Now that you have the public IP address, you may use it in your web browser’s address bar to access your web server.

## Step 2 — Installing MySQL

Now that you have your web server up and running, it is time to install MySQL, the relational database management system. The MySQL server will organize and provide access to databases where your server can store information.

Again, you can use `pkg` to acquire and install your software.

To install MySQL 8.0 using `pkg`, use this command:

    sudo pkg install mysql80-server

Enter `y` at the confirmation prompt to install the MySQL server and client packages.

To enable MySQL server as a service, add `mysql_enable="YES"` to the `/etc/rc.conf` file. You can us the `sysrc` command to do just that:

    sudo sysrc mysql_enable="YES"

Now start the MySQL server with the following command:

    sudo service mysql-server start

You can verify the service is up and running:

    sudo service mysql-server status

You’ll read something similar to the following:

    Outputmysql is running as pid 21587.

Now that your MySQL database is running, you will want to run a simple security script that will remove some dangerous defaults and slightly restrict access to your database system. Start the interactive script by running this command:

    sudo mysql_secure_installation

The prompt will ask you if you want to set a password. Since you just installed MySQL, you most likely won’t have one, so type `Y` and follow the instructions:

     Would you like to setup VALIDATE PASSWORD component?
    
    Press y|Y for Yes, any other key for No: y
    
    There are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 0
    Please set the password for root here.
    
    New password: password
    
    Re-enter new password: password
    
    Estimated strength of the password: 50
    Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) : y

For the rest of the questions, you should hit the `y` key at each prompt to accept the recommended safe values. This will remove some sample users and databases, disable remote root logins, and load these new rules so that MySQL immediately respects the changes you’ve made.

At this point, your database system is now set up and you can move on to installing PHP.

## Step 3 — Installing PHP

PHP is the component of your setup that will process code to display dynamic content. It can run scripts, connect to MySQL databases to get information, and hand the processed content over to the web server to display.

You can once again leverage the `pkg` system to install your components. You’re going to include the `mod_php`, `php-mysql`, and `php-mysqli` package as well.

To install PHP 7.3 with `pkg`, run this command:

    sudo pkg install php73 php73-mysqli mod_php73

Enter `y` at the confirmation prompt. This installs the `php73`, `mod_php73`, and `php73-mysqli` packages.

Now copy the sample PHP configuration file into place with this command:

    sudo cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

Now run the `rehash` command to regenerate the system’s cached information about your installed executable files:

    rehash

Before using PHP, you must configure it to work with Apache.

### Installing PHP Modules (Optional)

To enhance the functionality of PHP, you can optionally install some additional modules.

To see the available options for PHP 7.3 modules and libraries, you can type this:

    pkg search php73

The results will be mostly PHP 7.3 modules that you can install:

    Outputphp73-7.3.5 PHP Scripting Language
    php73-aphpbreakdown-2.2.2 Code-Analyzer for PHP for Compatibility Check-UP
    php73-aphpunit-1.8 Testing framework for unit tests
    php73-bcmath-7.3.5 The bcmath shared extension for php
    php73-brotli-0.6.2 Brotli extension for PHP
    php73-bsdconv-11.5.0 PHP wrapper for bsdconv
    php73-bz2-7.3.5 The bz2 shared extension for php
    php73-calendar-7.3.5 The calendar shared extension for php
    php73-composer-1.8.4 Dependency Manager for PHP
    php73-ctype-7.3.5 The ctype shared extension for php
    php73-curl-7.3.5 The curl shared extension for php
    php73-dba-7.3.5 The dba shared extension for php
    php73-deployer-6.4.3 Deployment tool for PHP
    php73-dom-7.3.5 The dom shared extension for php
    
    ...

To get more information about what each module does, you can either search the internet or you can look at the long description of the package by typing:

    pkg search -f package_name

There will be a lot of output, with one field called **Comment** which will have an explanation of the functionality that the module provides.

For example, to find out what the `php73-calendar` package does, you could type this:

    pkg search -f php73-calendar

Along with a large amount of other information, you’ll find something that looks like this:

    Outputphp73-calendar-7.3.5
    Name : php73-calendar
    Version : 7.3.5
    ...
    Comment : The calendar shared extension for php
    ...

If, after researching, you decide that you would like to install a package, you can do so by using the `pkg install` command.

For example, if you decide that `php73-calendar` is something that you need, you could type:

    sudo pkg install php73-calendar

If you want to install more than one module at a time, you can do that by listing each one, separated by a space, following the `pkg install` command, like this:

    sudo pkg install package1 package2 ...

## Step 4 — Configuring Apache to Use PHP Module

Apache HTTP has a dedicated directory to write configuration files into it for specific modules. You will write one of those configuration files for Apache HTTP to “speak” PHP.

    sudo vi /usr/local/etc/apache24/modules.d/001_mod-php.conf

Add the following lines to that file:

/usr/local/etc/apache24/modules.d/001\_mod-php.conf

    <IfModule dir_module>
        DirectoryIndex index.php index.html
        <FilesMatch "\.php$">
            SetHandler application/x-httpd-php
        </FilesMatch>
        <FilesMatch "\.phps$">
            SetHandler application/x-httpd-php-source
        </FilesMatch>
    </IfModule>

Now check Apache’s HTTP configuration is in good condition:

    sudo apachectl configtest

You’ll see the following output:

    OutputPerforming sanity check on apache24 configuration:
    Syntax OK

Because you’ve made configuration changes in Apache you have to restart the service for those to be applied. Otherwise Apache will still work with the prior configuration.

    sudo apachectl restart

Now you can move on to testing PHP on your system.

## Step 5 — Testing PHP Processing

In order to test that your system is configured properly for PHP, you can create a very basic PHP script.

You’ll call this script `info.php`. In order for Apache to find the file and serve it correctly, it must be saved under a specific directory—`DocumentRoot`—which is where Apache will look for files when a user accesses the web server. The location of `DocumentRoot` is specified in the Apache configuration file that you modified earlier (`/usr/local/etc/apache24/httpd.conf`).

By default, the `DocumentRoot` is set to `/usr/local/www/apache24/data`. You can create the `info.php` file under that location by typing:

    sudo vi /usr/local/www/apache24/data/info.php

This will open a blank file. Insert this PHP code into the file:

/usr/local/www/apache24/data/info.php

    <?php phpinfo(); ?>

Save and exit.

Now you can test whether your web server can correctly display content generated by a PHP script. To try this out, you can visit this page in your web browser:

    http://your_server_IP_address/info.php

You’ll see a PHP FreeBSD testing page.

![FreeBSD info.php](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/FAMP12/FAMP.png)

This page gives you information about your server from the perspective of PHP. It is useful for debugging and to ensure that your settings are being applied correctly.

If this was successful, then your PHP is working as expected.

You should remove this file after this test because it could actually give information about your server to unauthorized users. To do this, you can type this:

    sudo rm /usr/local/www/apache24/data/info.php

You can always recreate this page if you need to access the information again later.

## Conclusion

Now that you have a FAMP stack installed, you have many choices for what to do next. You’ve installed a platform that will allow you to install most kinds of websites and web software on your server.
