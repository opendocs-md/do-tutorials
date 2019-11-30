---
author: Mitchell Anicas
date: 2015-04-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-bacula-web-on-ubuntu-14-04
---

# How To Install Bacula-Web on Ubuntu 14.04

## Introduction

Bacula-Web is a PHP web application that provides an easy way to view summaries and graphs of Bacula backup jobs that have already run. Although it doesn’t allow you to control Bacula in any way, Bacula-Web provides a graphical alternative to viewing jobs from the console. Bacula-Web is especially useful for users who are new to Bacula, as its reports make it easy to understand what Bacula has been operating.

In this tutorial, we will show you how to install Bacula-Web on an Ubuntu 14.04 server that your Bacula server software is running on.

## Prerequisites

To follow this tutorial, you must have the Bacula backup server software installed on an Ubuntu server. Instructions to install Bacula can be found here: [How To Install Bacula Server on Ubuntu 14.04](how-to-install-bacula-server-on-ubuntu-14-04).

This tutorial assumes that your Bacula setup is using MySQL for the catalog. If you are using a different RDBMS, such as PostgreSQL, be sure to make the proper adjustments to this tutorial. You will need to install the appropriate PHP module(s) and make adjustments to the database connection information examples.

Let’s get started.

## Install Nginx and PHP

Bacula-Web is a PHP application, so we need to install PHP and a web server. We’ll use Nginx. If you want to learn more about this particular software setup, check out this [LEMP tutorial](how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04).

Update your apt-get listings:

    sudo apt-get update

Then, install Nginx, PHP-fpm, and a few other packages with apt-get:

    sudo apt-get install nginx apache2-utils php5-fpm php5-mysql php5-gd

Now we are ready to configure PHP and Nginx.

### Configure PHP-FPM

Open the PHP-FPM configuration file in your favorite text editor. We’ll use vi:

    sudo vi /etc/php5/fpm/php.ini

Find the line that specifies `cgi.fix_pathinfo`, uncomment it, and replace its value with `0`. It should look like this when you’re done.

    cgi.fix_pathinfo=0

Now find the `date.timezone` setting, uncomment it, and replace its value with your time zone. We’re in New York, so that’s what we’re setting the value to:

    date.timezone = America/New_York

If you need a list of supported timezones, check out the [PHP documentation](http://php.net/manual/en/timezones.php).

Save and exit.

PHP-FPM is configured properly, so let’s restart it to put the changes into effect:

    sudo service php5-fpm restart

### Configure Nginx

Now it’s time to configure Nginx to serve PHP applications.

First, because we don’t want unauthorized people to access Bacula-Web, let’s create an htpasswd file. Use htpasswd to create an admin user, called “admin” (you should use another name), that can access the Bacula-Web interface:

    sudo htpasswd -c /etc/nginx/htpasswd.users admin

Enter a password at the prompt. Remember this login, as you will need it to access Bacula-Web.

Now open the Nginx default server block configuration file in a text editor. We’ll use vi:

    sudo vi /etc/nginx/sites-available/default

Replace the contents of the file with the following code block. Be sure to substitute the highlighted value of `server_name` with your server’s domain name or IP address:

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
    
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    
        server_name server_domain_name_or_IP;
    
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/htpasswd.users;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/share/nginx/html;
        }
    
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }

Save and exit. This configures Nginx to serve PHP applications, and to use the htpasswd file, that we created earlier, for authentication.

To put the changes into effect, restart Nginx.

    sudo service nginx restart

Now we’re ready to download Bacula-Web.

## Download and Configure Bacula-Web

Change to your home directory, and download the latest Bacula-Web archive. At the time of this writing, `7.0.3` was the latest version:

    cd ~
    wget --content-disposition http://www.bacula-web.org/download.html?file=files/bacula-web.org/downloads/bacula-web-7.0.3.tgz

Now create a new directory, `bacula-web`, change to it, and extract the Bacula-Web archive:

    mkdir bacula-web
    cd bacula-web
    tar xvf ../bacula-web-*.tgz

Before copying the files to our web server’s document root, we should configure it first.

Change to the configuration directory like this:

    cd application/config

Bacula-Web provides a sample configuration. Copy it like this:

    cp config.php.sample config.php

Now edit the configuration file in a text editor. We’ll use vi:

    vi config.php

Find the `// MySQL bacula catalog`, and uncomment the connection details. Also, replace the `password` value with your Bacula database password (which can be found in `/etc/bacula/bacula-dir.conf` in the “dbpassword” setting):

    // MySQL bacula catalog
    $config[0]['label'] = 'Backup Server';
    $config[0]['host'] = 'localhost';
    $config[0]['login'] = 'bacula';
    $config[0]['password'] = 'bacula-db-pass';
    $config[0]['db_name'] = 'bacula';
    $config[0]['db_type'] = 'mysql';
    $config[0]['db_port'] = '3306';

Save and exit.

Bacula-Web is now configured. The last step is to put the application files in the proper place.

## Copy Bacula-Web Application to Document Root

We configured Nginx to use `/usr/share/nginx/html` as the document root. Change to it, and delete the default `index.html`, with these commands:

    cd /usr/share/nginx/html
    sudo rm index.html

Now, move the Bacula-Web files to your current location, the Nginx document root:

    sudo mv ~/bacula-web/* .

Change the ownership of the files to `www-data`, the daemon user that runs Nginx:

    sudo chown -R www-data: *

Now Bacula-Web is fully installed.

## Access Bacula-Web via a Browser

Bacula-Web is now accessible on your server’s domain name or public IP address.

You may want to test that everything is configured properly. Luckily, a Bacula-Web test page is provided. Access it by opening this URL in a web browser (substitute the highlighted part with your server’s information):

    http://server_public_IP/test.php

You should see a table that shows the status of the various components of Bacula-Web. They should all have a green checkmark status, except for the database modules that you don’t need. For example, we’re using MySQL, so we don’t need the other database modules:

![Bacula-Web Test](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bacula-web/test.png)

If everything looks good, you’re ready to use the dashboard. You can access it by clicking on the top-left “Bacula-Web” text, or by visiting your server in a web browser:

    http://server_public_IP/

It should look something like this:

![Bacula-Web Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bacula-web/bacula-web-dashboard.png)

## Conclusion

Now you are ready to use Bacula-Web to easily monitor your various Bacula jobs and statuses.

Have fun!
