---
author: serverhermit
date: 2017-09-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-lighttpd-with-mysql-and-php-on-freebsd-11-0
---

# How To Install Lighttpd with MySQL and PHP on FreeBSD 11.0

## Introduction

[Lighttpd](https://www.lighttpd.net) is a lightweight, open-source web server optimized for high speed environments while keeping resource usage low. It is an excellent alternative to the commonly used web servers Nginx and Apache. In this tutorial, you will install and configure Lighttpd on a server running FreeBSD 11.0. You also add MySQL and PHP to your new Lighttpd web server so you can serve web applications as well as static content.

## Prerequisites

To complete this tutorial, you’ll need:

- A server running FreeBSD 11.0.
- A user account configured to run commands with `sudo`. The default **freebsd** account that comes with a Digital Ocean FreeBSD Droplet will be fine for this tutorial. To learn more about configuring FreeBSD, check out the [Getting Started with FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd) tutorial series.

## Step 1 — Installing Lighttpd

There are a couple options for installing Lighttpd, but in this tutorial, you’ll use packages for installation. This method is faster than installing from source or via [Ports](how-to-install-and-manage-ports-on-freebsd-10-1), and software installed with this method is easy to update.

To install Lighttpd with its package, first update the repository information to ensure you have the latest list of available packages:

    sudo pkg update

Next, download and install the `lighttpd` package:

    sudo pkg install lighttpd

Confirm the installation by typing `y`. Lighttpd will install.

With this default configuration, you’ll see this error when you start the server:

    Output(network.c.260) warning: please use server.use-ipv6 only for hostnames, not without server.bind / empty address; your config will break if the kernel default for IPV6_V6ONLY changes

This is because the default Lighttpd configuration isn’t completely configured to support IPv6. To avoid surprises later, edit Lighttpd’s configuration file and disable support for IPv6, since you won’t need it to complete this tutorial. You can enable it in the future if you decide to use it:

    sudo ee /usr/local/etc/lighttpd/lighttpd.conf

Locate this section:

/usr/local/etc/lighttpd/lighttpd.conf

    ...
    ##
    ## Use IPv6?
    ##
    server.use-ipv6 = "enable"
    ...

Change `enable` to `disable`:

/usr/local/etc/lighttpd/lighttpd.conf

    ...
    ...
    server.use-ipv6 = "disable"
    ...

Next, locate this line at the very end of the configuration file:

/usr/local/etc/lighttpd/lighttpd.conf

    ...
    ...
    $SERVER["socket"] == "0.0.0.0:80" { }

Comment it out, as it’s unnecessary when we’re not using IPv6:

/usr/local/etc/lighttpd/lighttpd.conf

    ...
    ...
    #$SERVER["socket"] == "0.0.0.0:80" { }

Then save the file and exit the editor.

Let’s configure MySQL next.

## Step 2 — Installing and Configuring MySQL

MySQL is a database management system that will allow the creation of databases for the PHP applications you plan to host on your Lighttpd web server.

You’ll install MySQL via its package, just like you did for Lighttpd. Then you’ll set up a password for the MySQL **root** user and disable some other testing options. This ensures you’ll have a secure MySQL setup.

Since you already updated the `pkg` repository information in Step 1, you can download and install the MySQL server package quickly:

    sudo pkg install mysql57-server

Confirm the installation by pressing: `y`.

After the installation completes, enable MySQL at system startup:

    sudo sysrc mysql_enable=yes

Then start the `mysql-server` service:

    sudo service mysql-server start

Once the service starts, secure your installation of MySQL by using the `mysql_secure_installation` script. This will remove some dangerous defaults and lock down access to your database system a little bit. Start the interactive script by running:

    sudo mysql_secure_installation

You’ll see the following message:

    OutputSecuring the MySQL server deployment.
    
    Connecting to MySQL server using password in '/root/.mysql_secret'

Next, you will be asked if you want to configure a plugin to validate passwords:

    OutputVALIDATE PASSWORD PLUGIN can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    

**Warning** : Enabling this feature is something of a judgment call. If enabled, passwords which don’t match the specified criteria will be rejected by MySQL with an error. This will cause issues if you use a weak password in conjunction with software which automatically configures MySQL user credentials. It is safe to leave validation disabled, but you should always use strong, unique passwords for database credentials.

Answer `Y` for yes, or anything else to continue without enabling.

If you choose to enable this feature, you’ll be asked to select a level of password validation. Keep in mind that if you enter `2`, for the strongest level, you will receive errors when attempting to set any password which does not contain numbers, upper and lowercase letters, and special characters, or which is based on common dictionary words.

    OutputThere are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:

Next, you’ll be asked if you want to change the password for the **root** user:

    OutputChange the password for root ? ((Press y|Y for Yes, any other key for No) :

Press `Y` to change this password.

If you enabled password validation, you’ll be shown a password strength for the existing root password, and asked you if you want to change that password.

    OutputNew password:
    
    Re-enter new password:
    
    Estimated strength of the password: 100
    Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :

Press `Y` to continue with the new password.

For the rest of the questions, you should press `Y` and hit the Enter key at each prompt. This will remove some anonymous users and the test database, disable remote root logins, and load these new rules so that MySQL immediately respects the changes we have made.

Then restart the `mysql-server` service to ensure that your instance immediately implements the security changes:

    sudo service mysql-server restart

Once the MySQL instance is up and running, we can install and configure PHP.

## Step 3 — Installing and Configuring PHP

PHP is the component of our setup that will process code to display dynamic content. It can run scripts, connect to our MySQL databases to get information, and hand the processed content over to our web server to display.

Once again, use the package system to install PHP, along with the PHP extension `mysqli` which adds MySQL support:

    sudo pkg install php71 php71-mysqli

Lighttpd does not contain native PHP processing like some other web servers, so we’ll use [PHP-FPM](https://php-fpm.org/), which stands for “FastCGI Process Manager”. We’ll configure Lighttpd to use this module to process PHP requests. Before we do that, we need to configure PHP-FPM itself.

Start by editing the PHP-FPM configuration file:

    sudo ee /usr/local/etc/php-fpm.d/www.conf

We’ll configure PHP-FPM to use a Unix socket instead of a network port for communication. This is more secure for services communicating within a single server.

Look for this line in the configuration file:

/usr/local/etc/php-fpm.d/www.conf

    listen = 127.0.0.1:9000

Change this line to use the `php-fpm` socket:

/usr/local/etc/php-fpm.d/www.conf

    listen = /var/run/php-fpm.sock

Now set the owner, group, and permissions for the socket that will be created. Look for this section of the configuration file:

/usr/local/etc/php-fpm.d/www.conf

    ...
    ;listen.owner = www
    ;listen.group = www
    ;listen.mode = 0660
    ...

Uncomment the following section by removing the semicolons at the start of each line, so the section looks like this:

/usr/local/etc/php-fpm.d/www.conf

    ...
    listen.owner = www
    listen.group = www
    listen.mode = 0660
    ...

Save and close the file when you are finished.

Next, create a `php.ini` file that will configure the general behavior of PHP. There are two sample files included: `php.ini-production` and `php.ini-development`. The `php.ini-production` file will be closer to what you’ll want for your server, so copy it to `/usr/local/etc/php.ini`, the location that PHP expects to find its configuration file:

    sudo cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

Open the new `php.ini` file with your text editor:

    sudo ee /usr/local/etc/php.ini

Inside the configuration file, locate the section for the `cgi.fix_pathinfo` behavior. It will be commented out and set to `1` by default:

/usr/local/etc/php.ini

    ...
    ;cgi.fix_pathinfo=1
    ...

Uncomment this line and set the value to `0`. This prevents PHP from trying to execute parts of the path if the file that was passed into process is not found. This could be used by an attacker to execute malicious code.

/usr/local/etc/php.ini

    ...
    cgi.fix_pathinfo=0
    ...

Save the file and exit the editor.

Then enable the `php-fpm` service to start at boot:

    sudo sysrc php_fpm_enable=yes

Then start the service:

    sudo service php-fpm start

Next, let’s configure Lighttpd to serve PHP applications.

## Step 4 — Configuring Lighttpd to Serve PHP Applications

In this step you will configure Lighttpd to use FastCGI and PHP-FPM. This will enable PHP on Lighttpd and give fast and efficient PHP support.

First, enable the FastCGI module. Open the Lighttpd modules configuration file:

    sudo ee /usr/local/etc/lighttpd/modules.conf

Locate the following section:

/usr/local/etc/lighttpd/modules.conf

    ...
    ##
    ## FastCGI (mod_fastcgi)
    ##
    #include "conf.d/fastcgi.conf"
    ...

Uncomment the `include` line by removing the `#` symbol. If you don’t find that line, add it to the end of the file.

/usr/local/etc/lighttpd/modules.conf

    ...
    ##
    ## FastCGI (mod_fastcgi)
    ##
    include "conf.d/fastcgi.conf"
    ...

Save the file and exit the editor.

Next, edit the FastCGI configuration file:

    sudo ee /usr/local/etc/lighttpd/conf.d/fastcgi.conf

This file has several examples, commented out. Add the following configuration lines to the end of the file, which configures Lighttpd to serve PHP files with FastCGI and PHP-FPM:

/usr/local/etc/lighttpd/conf.d/fastcgi.conf

    ...
    fastcgi.server += ( ".php" =>
            ((
                    "socket" => "/var/run/php-fpm.sock",
                    "broken-scriptfilename" => "enable"
            ))
    )
    ...

Next, enable Lighttpd to start at boot. This way Lighttpd will start automatically whenever the web server is restarted:

    sudo sysrc lighttpd_enable=yes

Then start the `lighttpd` service:

    sudo service lighttpd start

Now that PHP is ready to go, let’s make sure everything works.

## Step 5 — Testing the Server Setup

To test the newly configured Lighttpd server, first create the folder `/usr/local/www/data`, which is where Lighttpd will look for web pages to serve.

    sudo mkdir -p /usr/local/www/data

Then create an `info.php` in the `/usr/local/www/data/` folder. This file will test that PHP is working and let you review information about the webserver setup in a web browser:

    sudo ee /usr/local/www/data/info.php

Add this code to the file:

/usr/local/www/data/info.php

    <?php phpinfo(); ?>

Save the file and exit the editor.

Visit `http://your_server_ip/info.php` in your web browser. You’ll see a a page that looks like this:

![The PHP Info page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lighttpd_php_freebsd11/NXq8JIE.png)

This page shows information about your operating system, web server, and how your web server handles PHP files. It also verifies that your web server can serve PHP files correctly.

If you don’t see this page, and instead see **Error 503 Service Not Available** , ensure that the `php-fpm` service started correctly in the previous step.

Once you’ve verified that things are working, remove the `info.php` page, as it exposes information about your server that you should keep private:

    sudo rm /usr/local/www/data/info.php

The web server is now fully configured and ready to go. Place your files in `/usr/local/www/data` to serve them.

## Conclusion

Now that the Lighttpd web server is fully up and running, you can host webpages, documents, and other files on your web server. To make your web server more secure by adding SSL configuration and other security features. For more information on Lighttpd, visit the [Lighttpd forums](https://redmine.lighttpd.net/projects/lighttpd/boards).
