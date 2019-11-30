---
author: Justin Ellingwood
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-nginx-on-a-freebsd-10-1-server
---

# How To Install WordPress with Nginx on a FreeBSD 10.1 Server

## Introduction

WordPress is the most popular content management system (CMS) and blogging platform in the world. Using WordPress, you can quickly configure and customize your website, allowing you to add content and tweak the visual elements easily.

In this guide, we will be installing WordPress on a FreeBSD 10.1 machine using Nginx to serve our content. Nginx is a powerful web server that is efficient at handling a large number of concurrent connections. We will leverage this as the base for the WordPress installation we will be setting up in this guide.

## Prerequisites and Goals

In order to complete this guide, there are some preliminary steps that should be taken in order to get your server ready.

We will be adding the components in this guide to a configured FEMP (FreeBSD, Nginx, MySQL, and PHP) stack. You can learn how to set up Nginx, MySQL, and PHP on your FreeBSD 10.1 server with our guide [here](how-to-install-an-nginx-mysql-and-php-femp-stack-on-freebsd-10-1) here.

Once you have Nginx, MySQL, and PHP installed and configured on your server, you can continue on with this guide. Our goal in this guide is to install the latest version of WordPress on our FreeBSD server.

There is an existing WordPress package that is installable through FreeBSD’s `pkg` command, but it currently relies on PHP version 5.4, which will only be receiving security updates from now on. Its total end of life will be in September of 2015.

To ensure that our site is built on a base that will receive support for a long while, we will be downloading and installing the latest version of WordPress from the project’s site and using PHP version 5.6 to process the dynamic content.

## Install Additional PHP Extensions that WordPress Requires

When we were setting up PHP on our FreeBSD server in the FEMP guide, we installed the `php56` package and the `php56-mysql` package so that our PHP instance could query data from a MySQL database if required.

This represents the minimum configuration required that allows PHP to be used as a base for a variety of different applications. WordPress will use the `php56-mysql` package, but it also requires some additional extensions in order to implement many of its core features.

Luckily, these can be easily installed using the `pkg` command. Download and install the required extensions by typing:

    sudo pkg install php56-xml php56-hash php56-gd php56-curl php56-tokenizer php56-zlib php56-zip

After the installation is complete, if you are using the default `tcsh` shell, initiate a rehash so that the shell can find your new files:

    rehash

All of the packages we’ve installed are PHP extensions. For our PHP-FPM instance to use these new extensions, we’ll have to restart the process:

    sudo service php-fpm restart

After this is complete, we can begin configuring our database.

## Create and Configure a MySQL Database

WordPress requires an SQL-style database in order to store site content and user data. We installed MySQL in our previous guide, so we have the tools we need to create and provide access to such a database.

To begin, you will need to use the `mysql` command to authenticate to your database system as the administrative user:

    mysql -u root -p

You will be prompted for the MySQL root user’s password that you configured in the previous guide (while running the `mysql_secure_installation` script). Once you enter the correct password, you will be dropped into a MySQL prompt.

The fist thing we will do is create a database for our WordPress instance. You can call this whatever you would like, but we will be using the database name `wordpress` for this guide because it is semantic and easy to remember:

    CREATE DATABASE wordpress;

If you run into trouble with the command above, make sure that you have a semicolon (;) at the end of your statement. The SQL querying language requires all statements to end with a semicolon.

After we create our database, our next step is to create a dedicated user that we will use to access the database. It is recommended that you create and utilize a separate MySQL user for every application that stores data within MySQL. This helps minimize the scope of security problems.

For this guide, we will call our new user `wordpressuser` and configure the access restraints so that it is only valid for connections originating from the server itself. We will also set a password for the user:

    CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';

Remember to change the `password` component in the above command to a secure password. You will need to remember this value later on.

We have now created the two MySQL components that our WordPress installation will require. However, they are not yet connected in any way. We need to give our new user access to the WordPress database so that it can set up and manage the data for our site. To do this, type:

    GRANT ALL PRIVILEGES ON wordpress.* TO wordpressuser@localhost;

Our new user now has access to the database we configured. To let the instance of MySQL that is currently running know about these new changes, we should flush the privilege table:

    FLUSH PRIVILEGES;

Finally, we can exit the MySQL prompt to get back to our regular shell environment by typing:

    exit

Now that we have a database and user ready, we can download and configure the actual WordPress files.

## Download and Configure WordPress

We will be downloading the latest version of WordPress from the project’s website to use for our installation. Because of possible security updates, it is very important to always use the most up-to-date version of WordPress.

The WordPress team makes this easy by always packaging the latest version into an archive at `/latest.tar.gz` on their site. We can download this into our home directory using the FreeBSD `fetch` utility:

    cd ~
    fetch http://wordpress.org/latest.tar.gz

Once the file has been downloaded, we can extract the WordPress files and directory structure using the `tar` command:

    tar xzvf latest.tar.gz

The directory that will be created will be called `wordpress`. Delete the `.tar.gz` archive and then move into that directory so that we can begin configuration:

    rm latest.tar.gz
    cd wordpress

Inside, there is a sample configuration file that we can use as a template for our installation. Copy the file over to the `wp-config.php` filename that will be read by WordPress:

    cp wp-config-sample.php wp-config.php

Now, we can open the file for editing so that we can configure the access credentials for the MySQL database and user we set up in the last section:

    vi wp-config.php

Inside, there are three values that you must change in order for WordPress to correctly connect to and utilize your MySQL system. The `DB_NAME` variable defines the name of the MySQL database you created, the `DB_USER` should be set to the user you made, and the `DB_PASSWORD` should be modified to contain the password you selected for that user:

    . . .
    
    /** The name of the database for WordPress */
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    . . .

When you are finished modifying these values, save and close the file.

Next, we can copy the WordPress installation into the `/usr/local/www` directory where we keep our various site files. We will use the `rsync` utility, as it allows us to maintain certain file attributes during the move:

    sudo rsync -avP ~/wordpress /usr/local/www

Next, we need to adjust the owner of our WordPress files so that our web server can make changes where appropriate. Our web user and group are both called `www`:

    sudo chown -R www:www /usr/local/www/wordpress

Now that your WordPress files are in place with the correct configuration, we can modify our Nginx configuration.

## Configure Nginx

In our last guide, we set up Nginx to serve the default Nginx web page and configured it to pass PHP requests to our PHP-FPM instance. This takes us most of the way to the configuration we need for WordPress.

Open the Nginx configuration file with `sudo` privileges to make our changes:

    sudo vi /usr/local/etc/nginx/nginx.conf

If you followed the instructions from the last guide, your file should look similar to this one (we’ve removed the comments below for clarity):

    user www;
    worker_processes 2;
    error_log /var/log/nginx/error.log info;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include mime.types;
        default_type application/octet-stream;
    
        access_log /var/log/nginx/access.log;
    
        sendfile on;
        keepalive_timeout 65;
    
        server {
            listen 80;
            server_name example.com www.example.com;
            root /usr/local/www/nginx;
            index index.php index.html index.htm;
    
            location / {
                try_files $uri/ $uri/ =404;
            }
    
            error_page 500 502 503 504 /50x.html;
            location = /50x.html {
                root /usr/local/www/nginx-dist;
            }
    
            location ~ \.php$ {
                    try_files $uri =404;
                    fastcgi_split_path_info ^(.+\.php)(/.+)$;
                    fastcgi_pass unix:/var/run/php-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME $request_filename;
                    include fastcgi_params;
            }
        }
    }

We will have to make two adjustments in order to ensure that our WordPress will function correctly.

First, we need to adjust the document root since our WordPress files are located in the `/usr/local/www/wordpress` directory:

    server {
    
        . . .
    
        root /usr/local/www/wordpress;
    
        . . .
    
    }

The other change we need to make is to the `try_files` directive within the `location /` block. Currently, the configuration tells Nginx to try to find the request as a file first. If it cannot find a file that matches, it attempts to find a directory that matches the request. If this does not yield any results, Nginx issues a 404 error indicating that the resource could not be found.

We need to modify this so that instead of ending with a 404 error, the request is rewritten to an `index.php` file. The original request and arguments will be passed in as query parameters. We can configure this by modifying the `try_files` directive to look like this:

    server {
    
        . . .
    
        location / {
            try_files $uri $uri/ /index.php?q=$uri&$args;
        }
    
        . . .
    
    }

When you are finished, the configuration file should look something like this:

    user www;
    worker_processes 2;
    error_log /var/log/nginx/error.log info;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include mime.types;
        default_type application/octet-stream;
    
        access_log /var/log/nginx/access.log;
    
        sendfile on;
        keepalive_timeout 65;
    
        server {
            listen 80;
            server_name example.com www.example.com;
            root /usr/local/www/wordpress;
            index index.php index.html index.htm;
    
            location / {
                try_files $uri $uri/ /index.php?q=$uri&$args;
            }
    
            error_page 500 502 503 504 /50x.html;
            location = /50x.html {
                root /usr/local/www/nginx-dist;
            }
    
            location ~ \.php$ {
                    try_files $uri =404;
                    fastcgi_split_path_info ^(.+\.php)(/.+)$;
                    fastcgi_pass unix:/var/run/php-fpm.sock;
                    fastcgi_index index.php;
                    fastcgi_param SCRIPT_FILENAME $request_filename;
                    include fastcgi_params;
            }
        }
    }

When you are finished making the above modifications, save and close the file.

Now, we can restart Nginx in order to implement our new changes. First, double check that our syntax is correct:

    sudo nginx -t

If no errors are found, restart the service:

    sudo service nginx restart

## Completing the Installation Through the Web Interface

Our WordPress installation is now completely configured on the server end. We can complete the rest of the process using a web browser.

In your web browser, visit your server’s domain name or IP address:

    http://example.com

WordPress will first ask you which language you wish to use:

![WordPress select language](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_lemp_wp/choose_language.png)

After making your selection, you will be taken to the initial configuration page to set up your WordPress installation:

![WordPress installation](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_lemp_wp/main_install.png)

Fill out the name for your site and select the username you would like to use to administer the site. You will have to select and confirm a password for your site and fill in an email address where you can be reached. The last option is a choice as to whether to allow search engines to index the site.

When you have made your selections, click on the “Install WordPress” button at the bottom of the page. You will be asked to sign into the site using the credentials you just selected.

Upon logging in, you will be presented with the administration panel for your new WordPress installation:

![WordPress admin interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_lemp_wp/admin_interface.png)

You can use this interface to post new content, modify the appearance of your site, and install and configure plugins to take advantage of additional functionality.

## Conclusion

You now have a fresh WordPress installation up and running backed by Nginx, MySQL, and PHP. WordPress is incredibly powerful, allowing you to display many different kinds of content styled according to your preferences. If you are new to WordPress, you may want to start by looking at optional themes and plugins.
