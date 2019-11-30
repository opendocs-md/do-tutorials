---
author: Mateusz Papiernik
date: 2017-08-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-caddy-on-centos-7
---

# How To Install WordPress with Caddy on CentOS 7

## Introduction

[WordPress](https://WordPress.org/) is a popular content management system (CMS). It can be used to set up blogs and websites quickly and easily, and almost all of its administration is possible through a web interface.

In most cases, WordPress is installed using a LAMP or LEMP stack (i.e. using either Apache or Nginx as a web server). In this guide, we’ll set up WordPress with [Caddy](https://caddyserver.com/) instead. Caddy is a new web server quickly gaining popularity for its wide array of unique features, like HTTP/2 support and automatic TLS encryption with Let’s Encrypt, a popular free certificate provider.

In this tutorial, you will install and configure WordPress backed by Caddy.

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server set up with [this initial server setup tutorial](initial-server-setup-with-centos-7), including a sudo non-root user.
- MySQL installed by following the [How To Install MySQL on CentOS 7](how-to-install-mysql-on-centos-7) tutorial.
- Caddy installed by following the [How To Host a Website with Caddy on CentOS 7](how-to-host-a-website-with-caddy-on-centos-7) tutorial, including [a domain name configured to point to your Droplet](how-to-set-up-a-host-name-with-digitalocean).

## Step 1 — Installing PHP

In order to run WordPress, you need a web server, a MySQL database, and the PHP scripting language. You already have the Caddy webserver and a MySQL database installed from the prerequisites, so the last requirement is to install PHP.

First, make sure your packages are up to date.

    sudo yum update

Install PHP and the [PHP extensions](http://php.net/manual/en/extensions.php) WordPress depends on, like support for MySQL, `curl`, XML, and multi-byte strings.

    sudo yum install php php-fpm php-mysql php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc

Once the installation finishes, you can verify that PHP was installed correctly by checking the PHP’s version.

    php -v

You’ll see output similar to this, which displays PHP’s version number.

    PHP version outputPHP 5.4.16 (cli) (built: Nov 6 2016 00:29:02)
    Copyright (c) 1997-2013 The PHP Group
    Zend Engine v2.4.0, Copyright (c) 1998-2013 Zend Technologies

Before we can move on, we have to modify the configuration file for PHP service slightly to make it use our unprivileged `caddy` user to run the server. The default configuration on CentOS assumes that Apache is the server of choice.

Open the PHP-FPM configuration file with `vi` or your favorite text editor. Here’s a [short introduction to `vi`](installing-and-using-the-vim-text-editor-on-a-cloud-server#modal-editing) if you’re not familiar with it.

    sudo vi /etc/php-fpm.d/www.conf

Find the fragment that specifies the user account and group.

/etc/php-fpm.d/www.conf

    ; Unix user/group of processes
    ; Note: The user is mandatory. If the group is not set, the default user's group
    ; will be used.
    ; RPM: apache Choosed to be able to access some dir as httpd
    user = apache
    ; RPM: Keep a group allowed to write in log dir.
    group = apache

Change both values to **caddy** as follows:

/etc/php-fpm.d/www.conf

    ; Unix user/group of processes
    ; Note: The user is mandatory. If the group is not set, the default user's group
    ; will be used.
    ; RPM: apache Choosed to be able to access some dir as httpd
    user = caddy
    ; RPM: Keep a group allowed to write in log dir.
    group = caddy

Save and close the file to exit. For Caddy to be able to communicate with PHP, start the PHP service.

    sudo systemctl start php-fpm

All of WordPress’ dependencies are installed, so next, we’ll configure a MySQL database for WordPress to use.

## Step 2 — Creating a MySQL Database and Dedicated User

WordPress uses a MySQL database to store all of its information. In a default MySQL installation, only a **root** administrative account is created. This account shouldn’t be be used because its unlimited privileges to the database server are a security risk. Here, we will create a dedicated MySQL user for WordPress to use and a database that the new user will be allowed to access.

First, log in to the MySQL **root** administrative account.

    mysql -u root -p

You will be prompted for the password you set for the MySQL **root** account during installation.

Create a new database called `wordpress` which will be used for the WordPress website. You can use a different name, but make sure you remember it for additional configuration later.

    CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

Next, create a new user that will be allowed to access this database. Here, we use the username `wordpressuser` for simplicity, but you can choose your own name. Remember to replace `password` with a strong and secure password.

    GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';

**Note:** Bear in mind that the default password policy requires 12 characters, with at least one uppercase letter, one lowercase letter, one number and one special character. If you forget to follow that policy the above command will not create the user but show an error message instead.

Flush privileges to notify the MySQL server of the changes.

    FLUSH PRIVILEGES;

You can now safely exit MySQL.

    EXIT;

WordPress has a dedicated database and user account, so all the system components are set up. The next step is to install WordPress itself.

## Step 3 — Downloading WordPress

Installing WordPress involves downloading the latest release into the web root directory and making sure it’s accessible by the web server, then finishing the installation via WordPress’ graphical interface. In this step, we’ll just download the release, because we’ll need to configure the web server before we can access the GUI.

First, change the current directory to `/var/www`, the web root which stores your website files.

    cd /var/www

Download the latest compressed WordPress release. It’s important to use the latest release because the software is frequently updated with security patches.

    sudo curl -O https://wordpress.org/latest.tar.gz

Extract the compressed archive you just downloaded.

    sudo tar zxf latest.tar.gz

This will automatically create a new directory called `wordpress`. You can now safely remove the downloaded archive, as it’s no longer needed.

    sudo rm latest.tar.gz

The last step is to change the permissions of WordPress files and directories so that all files are writable by Caddy. This will allow WordPress to be automatically updated to newer versions.

    sudo chown -R caddy:caddy wordpress

**Note:** Choosing the right permissions for WordPress files is a matter of preference and administrative practices. Disallowing write access to WordPress files can increase security by making it impossible to exploit some bugs that could lead to compromising WordPress core files, but at the same time, it results in disabling automatic security updates and the ability to install and update plugins through the WordPress web interface.

Next, you need to modify the web server’s configuration to serve your website.

## Step 4 — Configuring Caddy to Serve the WordPress Website

Here, we will modify the `Caddyfile` configuration file to tell Caddy where our WordPress installation is located and under which domain name should it be published to the visitors.

Open the configuration file with `vi` or your favourite text editor

    sudo vi /etc/caddy/Caddyfile

Copy and paste the following configuration into the file. You can remove any example configuration from previous tutorials.

/etc/caddy/Caddyfile

    example.com {
        tls admin@example.com
        root /var/www/wordpress
        gzip
        fastcgi / 127.0.0.1:9000 php
        rewrite {
            if {path} not_match ^\/wp-admin
            to {path} {path}/ /index.php?_url={uri}
        }
    }

This `Caddyfile` is structured as follows:

- The `example.com` in the first line is the domain name under which the site will be available. Replace it with your own domain name.
- The `admin@example.com` after the `tls` directive tells Caddy the e-mail address it should use to request the Let’s Encrypt certificate. If you’ll ever need to recover the certificate, Let’s Encrypt will use this e-mail address in the recovery process.
- The `root` directive tells Caddy where the website files are located. In this example, it’s `/var/www/wordpress`.
- The `gzip` directive tells Caddy to use Gzip compression to make the website faster.
- The `fastcgi` directive configures the PHP handler to support files with a `php` extension
- Using `rewrite` directive enables pretty URLs (called pretty permalinks in WordPress). This configuration is automatically provided by WordPress in the `.htaccess` file if you use Apache, but needs to be configured for Caddy separately.

After changing the configuration file accordingly, save the file and exit.

Restart Caddy to put the new configuration file settings into effect.

    sudo systemctl restart caddy

When Caddy starts, it will automatically obtain an SSL certificate from Let’s Encrypt to serve your site securely using TLS encryption. You can now access your Caddy-hosted WordPress website by navigating to your domain using your web browser. When you do so, you will notice the green lock sign in the address bar meaning the site is being displayed over a secure connection.

You have now installed and configured Caddy and all necessary software to host a WordPress website. The last step is to finish WordPress’ configuration using its graphical interface.

## Step 5 — Configuring WordPress

WordPress has a GUI installation wizard to finish its setup, including connecting to the database and setting up your first website.

When you visit your new WordPress instance in your browser for the first time, you’ll see a list of languages. Choose the language you would like to use. On the next screen, it describe the information it needs about your database. Click **Let’s go!** , and the next page will ask for database connection details. Fill in this form as follows:

- **Database Name** should be `wordpress`, unless you customized it in Step 2.
- **Username** should be **wordpressuser** , unless you customized it in Step 2.
- **Password** should be the password you set for **wordpressuser** in Step 2.
- **Database Host** and **Table Prefix** should be left to their default values.

When you click **Submit** , WordPress will check if the provided details are correct. If you receive an error message, double check that you entered your database details correctly.

Once WordPress successfully connects to your database, you’ll see a message which begins with **All right, sparky! You’ve made it through this part of the installation. WordPress can now communicate with your database.**

Now you can click **Run the install** to begin the installation. After a short time, WordPress will present you with a final screen asking for your website details, such as the website title, the administrator account username, password, and e-mail address. The strong password will be auto-generated for you, but you can choose your own if you’d like.

**Note:** It’s a good security practice not to use a common username like **admin** for the administrative account, as many security exploits rely on standard usernames and passwords. Choose a unique username and a strong password for your main account to help make your site secure.

After clicking **Install WordPress** , you will be directed to the WordPress dashboard. You have now finished the WordPress installation, and you can use WordPress freely to customize your website and write posts and pages.

# Conclusion

You now have a working WordPress installation served using the Caddy web server. Caddy will automatically obtain SSL certificates from Let’s Encrypt, serve your site over a secure connection, and use HTTP/2 and Gzip compression to serve the website faster. You can read more about Caddy’s unique features and configuration directives for the `Caddyfile` in [the official Caddy documentation](https://caddyserver.com/docs).

If you want to use plugins with your new WordPress instance, note that some plugins rely on the Apache web server’s `.htaccess` files. Web servers other than Apache have become common with WordPress, so not many of these `.htaccess`-dependent plugins exist. However, the few that do exist won’t work out of the box with Caddy because it doesn’t use `.htaccess`. This is a good thing to keep in mind if you run into issues with WordPress plugins when using Caddy.

Most plugins that rely on `.htaccess` are caching plugins (for example, W3 Total Cache) which use `.htaccess` to circumvent PHP entirely for processing. Another example is Wordfence, which is a web application firewall module that uses `.htaccess` by default, but it properly supports different configuration models.
