---
author: Justin Ellingwood
date: 2014-06-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-laravel-with-an-nginx-web-server-on-ubuntu-14-04
---

# How to Install Laravel with an Nginx Web Server on Ubuntu 14.04

## Introduction

Laravel is a modern, open source PHP framework for web developers. It aims to provide an easy, elegant way for developers to get a fully functional web application running quickly.

In this guide, we will discuss how to install Laravel on Ubuntu 14.04. We will be using Nginx as our web server and will be working with the most recent version of Laravel at the time of this writing, version 4.2.

## Install the Backend Components

The first thing that we need to do to get started with Laravel is install the stack that will support it. We can do this through Ubuntu’s default repositories.

First, we need to update our local package index to make sure we have a fresh list of the available packages. Then we can install the necessary components:

    sudo apt-get update
    sudo apt-get install nginx php5-fpm php5-cli php5-mcrypt git

This will install Nginx as our web server along with the PHP tools needed to actually run the Laravel code. We also install `git` because the `composer` tool, the dependency manager for PHP that we will use to install Laravel, will use it to pull down packages.

## Modify the PHP Configuration

Now that we have our components installed, we can start to configure them. We will start with PHP, which is fairly straight forward.

The first thing that we need to do is open the main PHP configuration file for the PHP-fpm processor that Nginx uses. Open this with sudo privileges in your text editor:

    sudo nano /etc/php5/fpm/php.ini

We only need to modify one value in this file. Search for the `cgi.fix_pathinfo` parameter. This will be commented out and set to “1”. We need to uncomment this and set it to “0”:

    cgi.fix_pathinfo=0

This tells PHP not to try to execute a similar named script if the requested file name cannot be found. This is very important because allowing this type of behavior could allow an attacker to craft a specially designed request to try to trick PHP into executing code that it should not.

When you are finished, save and close the file.

The last piece of PHP administration that we need to do is explicitly enable the MCrypt extension, which Laravel depends on. We can do this by using the `php5enmod` command, which lets us easily enable optional modules:

    sudo php5enmod mcrypt

Now, we can restart the `php5-fpm` service in order to implement the changes that we’ve made:

    sudo service php5-fpm restart

Our PHP is now completely configured and we can move on.

## Configure Nginx and the Web Root

The next item that we should address is the web server. This will actually involve two distinct steps.

The first step is configuring the document root and directory structure that we will use to hold the Laravel files. We are going to place our files in a directory called `/var/www/laravel`.

At this time, only the top-level of this path (`/var`) is created. We can create the entire path in one step by passing the `-p` flag to our `mkdir` command. This instructs the utility to create any necessary parent path elements needed to construct a given path:

    sudo mkdir -p /var/www/laravel

Now that we have a location set aside for the Laravel components, we can move on to editing the Nginx server blocks.

Open the default server block configuration file with sudo privileges:

    sudo nano /etc/nginx/sites-available/default

Upon installation, this file will have quite a few explanatory comments, but the basic structure will look like this:

    server {
            listen 80 default_server;
            listen [::]:80 default_server ipv6only=on;
    
            root /usr/share/nginx/html;
            index index.html index.htm;
    
            server_name localhost;
    
            location / {
                    try_files $uri $uri/ =404;
            }
    }

This provides a good basis for the changes that we will be making.

The first thing we need to change is the location of the document root. Laravel will be installed in the `/var/www/laravel` directory that we created.

However, the base files that are used to drive the app are kept in a subdirectory within this called `public`. This is where we will set our document root. In addition, we will tell Nginx to serve any `index.php` files before looking for their HTML counterparts when requesting a directory location:

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
    
        root /var/www/laravel/public;
        index index.php index.html index.htm;
    
        server_name localhost;
    
        location / {
                try_files $uri $uri/ =404;
        }
    }

Next, we should set the `server_name` directive to reference the actual domain name of our server. If you do not have a domain name, feel free to use your server’s IP address.

We also need to modify the way that Nginx will handle requests. This is done through the `try_files` directive. We want it to try to serve the request as a file first. If it cannot find a file of the correct name, it should attempt to serve the default index file for a directory that matches the request. Failing this, it should pass the request to the `index.php` file as a query parameter.

The changes described above can be implemented like this:

    server {
            listen 80 default_server;
            listen [::]:80 default_server ipv6only=on;
    
            root /var/www/laravel/public;
            index index.php index.html index.htm;
    
            server_name server_domain_or_IP;
    
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
            }
    }

Finally, we need to create a block that handles the actual execution of any PHP files. This will apply to any files that end in `.php`. It will try the file itself and then try to pass it as a parameter to the `index.php` file.

We will set the `fastcgi_*` directives so that the path of requests are correctly split for execution, and make sure that Nginx uses the socket that `php5-fpm` is using for communication and that the `index.php` file is used as the index for these operations.

We will then set the `SCRIPT_FILENAME` parameter so that PHP can locate the requested files correctly. When we are finished, the completed file should look like this:

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
    
        root /var/www/laravel/public;
        index index.php index.html index.htm;
    
        server_name server_domain_or_IP;
    
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    
        location ~ \.php$ {
            try_files $uri /index.php =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }

Save and close the file when you are finished.

Because we modified the `default` server block file, which is already enabled, we simply need to restart Nginx for our configuration changes to be picked up:

    sudo service nginx restart

## Create Swap File (Optional)

Before we go about installing Composer and Laravel, it might be a good idea to enable some swap on your server so that the build completes correctly. This is generally only necessary if you are operating on a server without much memory (like a 512mb Droplet).

Swap space will allow the operating system to temporarily move data from memory onto the disk when the amount of information in memory exceeds the physical memory space available. This will prevent your applications or system from crashing with an out of memory (OOM) exception when doing memory intensive tasks.

We can very easily set up some swap space to let our operating system shuffle some of this to the disk when necessary. As mentioned above, this is probably only necessary if you have less than 1GB of ram available.

First, we can create an empty 1GB file by typing:

    sudo fallocate -l 1G /swapfile

We can format it as swap space by typing:

    sudo mkswap /swapfile

Finally, we can enable this space so that the kernel begins to use it by typing:

    sudo swapon /swapfile

The system will only use this space until the next reboot, but the only time that the server is likely to exceed its available memory is during the build processes, so this shouldn’t be a problem.

## Install Composer and Laravel

Now, we are finally ready to install Composer and Laravel. We will set up Composer first. We will then use this tool to handle the Laravel installation.

Move to a directory where you have write access (like your home directory) and then download and run the installer script from the Composer project:

    cd ~
    curl -sS https://getcomposer.org/installer | php

This will create a file called `composer.phar` in your home directory. This is a PHP archive, and it can be run from the command line.

We want to install it in a globally accessible location though. Also, we want to change the name to `composer` (without the file extension). We can do this in one step by typing:

    sudo mv composer.phar /usr/local/bin/composer

Now that you have Composer installed, we can use it to install Laravel.

Remember, we want to install Laravel into the `/var/www/laravel` directory. To install the latest version of Laravel, you can type:

    sudo composer create-project laravel/laravel /var/www/laravel

At the time of this writing, the latest version is 4.2. In the event that future changes to the project prevent this installation procedure from correctly completing, you can force the version we’re using in this guide by instead typing:

    sudo composer create-project laravel/laravel /var/www/laravel 4.2

Now, the files are all installed within our `/var/www/laravel` directory, but they are entirely owned by our `root` account. The web user needs partial ownership and permissions in order to correctly serve the content.

We can give group ownership of our Laravel directory structure to the web group by typing:

    sudo chown -R :www-data /var/www/laravel

Next, we can change the permissions of the `/var/www/laravel/app/storage` directory to allow the web group write permissions. This is necessary for the application to function correctly:

    sudo chmod -R 775 /var/www/laravel/app/storage

You now have Laravel completely installed and ready to go. You can see the default landing page by visiting your server’s domain or IP address in your web browser:

    http://server_domain_or_IP

![Laravel default landing page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/laravel_nginx_1404/laravel_default.png)

You now have everything you need to start building applications with the Laravel framework.

## Conclusion

You should now have Laravel up and running on your server. Laravel is quite a flexible framework and it includes many tools that can help you build out an application in a structured way.

To learn how to use Laravel to build an application, check out the [Laravel documentation](http://laravel.com/docs).
