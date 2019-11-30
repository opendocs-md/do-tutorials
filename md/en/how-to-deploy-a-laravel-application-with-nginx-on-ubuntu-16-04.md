---
author: Mateusz Papiernik
date: 2017-06-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-laravel-application-with-nginx-on-ubuntu-16-04
---

# How To Deploy a Laravel Application with Nginx on Ubuntu 16.04

[Laravel](https://laravel.com/) is one of the most popular open-source web application frameworks written in PHP. It aims to help developers build both simple and complex applications by making frequently-used application tasks (like caching and authentication) easier.

In this tutorial, we will deploy a simple Laravel application with a production environment in mind, which requires a few common steps. For example, applications should use a dedicated database user with access limited only to necessary databases. File permissions should guarantee that only necessary directories and files are writable. Application settings should be taken into consideration to make sure no debugging information is being displayed to the end user, which could expose application configuration details.

This tutorial is about deploying an existing application. If instead you’d like to learn about how to use the Laravel framework itself, Laravel’s own [Laravel from Scratch](https://laracasts.com/series/laravel-from-scratch-2017) series is a good place to start.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up with [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- The LEMP stack installed by following the [Linux, Nginx, MySQL, PHP (LEMP stack) on Ubuntu 16.04 tutorial](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04).
- A domain name pointed at your server, as described in [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean). This tutorial will use `example.com` throughout. This is necessary to obtain an SSL certificate for your website, so you can securely serve your application with TLS encryption.

## Step 1 — Installing Package Dependencies

To run Laravel applications, you’ll need some PHP extensions and a PHP dependency manager called [Composer](https://getcomposer.org/) in addition to the basic LEMP stack.

Start by updating the package manager cache.

    sudo apt-get update

The PHP extensions you’ll need are for multi-byte string support and XML support. You can install these extensions, Composer, and `unzip` (which allows Composer to handle zip files) at the same time.

    sudo apt-get install php7.0-mbstring php7.0-xml composer unzip

Now that the package dependencies are installed, we’ll create and configure a MySQL database and dedicated user account for the app.

## Step 2 — Configuring MySQL

Laravel supports a variety of database servers. Because this tutorial uses the LE **M** P stack, MySQL will store data for the application.

In a default installation, MySQL only creates the **root** administrative account. It’s a bad security practice to use the **root** database user within a website because it has unlimited privileges on the database server. Instead, let’s create a dedicated database user for Laravel application to use, as well as a new database that the Laravel user will be allowed to access.

Log into the MySQL `root` administrative account.

    mysql -u root -p

You will be prompted for the password you set for the MySQL **root** account during installation.

Start by creating a new database called `laravel`, which is what we’ll use for the website. You can choose a different name, but make sure to remember it because you’ll need it later.

    CREATE DATABASE laravel DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

Next, create a new user that will be allowed to access this database. Here we use `laraveluser` as the username, but you can customize this too. Remember to replace `password` in the following line with a strong and secure password.

    GRANT ALL ON laravel.* TO 'laraveluser'@'localhost' IDENTIFIED BY 'password';

Flush the privileges to notify the MySQL server of the changes.

    FLUSH PRIVILEGES;

And exit MySQL.

    EXIT;

You have now configured a dedicated database and the user account for Laravel to use. The database components are ready, so next, we’ll set up the demo application.

## Step 3 — Setting Up the Demo Application

The demo `quickstart` application, [distributed by Laravel on GitHub](https://github.com/laravel/quickstart-basic), is a simple task list. It allows you to add and remove to-do items and stores its tasks in the MySQL database.

First, create a directory within the Nginx web root which will hold the application. Because the demo application is named `quickstart`, let’s use `/var/www/html/quickstart`.

    sudo mkdir -p /var/www/html/quickstart

Next, change the ownership of the newly created directory to your user, so that you will be able to work with the files inside without using `sudo`.

    sudo chown sammy:sammy /var/www/html/quickstart

Move to the new directory and clone the demo application using Git.

    cd /var/www/html/quickstart
    git clone https://github.com/laravel/quickstart-basic .

Git will download all of the files from the demo application repository. You’ll see output that looks like this:

    Git outputCloning into '.'...
    remote: Counting objects: 263, done.
    remote: Total 263 (delta 0), reused 0 (delta 0), pack-reused 263
    Receiving objects: 100% (263/263), 92.75 KiB | 0 bytes/s, done.
    Resolving deltas: 100% (72/72), done.
    Checking connectivity... done.

Next, we need to install the project dependencies. Laravel utilizes Composer to handle dependency management, which makes it easy to install the necessary packages in one go.

    composer install

The somewhat lengthy output will show the installation progress for all project dependencies:

    Composer outputLoading composer repositories with package information
    Installing dependencies (including require-dev) from lock file
    . . .
    Generating autoload files
    > php artisan clear-compiled
    > php artisan optimize
    Generating optimized class loader

The app itself is set up, so the next step is configuring the app environment. This involves connecting the application and the database and customizing some settings for production.

## Step 4 — Configuring the Application Environment

In this step, we’ll modify some security-related application settings, allow the application to connect to the database, and prepare the database for usage. These are necessary steps for all LEMP-backed Laravel applications, not just the demo application we’re using here.

Open the Laravel environment configuration file with `nano` or your favorite text editor.

    sudo nano /var/www/html/quickstart/.env

You’ll need to make the following changes to the file. Make sure to update the placeholder variables, like `password` and `example.com`, with the appropriate values.

/var/www/html/quickstart/.env

    APP_ENV=production
    APP_DEBUG=false
    APP_KEY=b809vCwvtawRbsG0BmP1tWgnlXQypSKf
    APP_URL=http://example.com
    
    DB_HOST=127.0.0.1
    DB_DATABASE=laravel
    DB_USERNAME=laraveluser
    DB_PASSWORD=password
    
    . . .

Save the file and exit.

Let’s go through these changes in more detail. There are two configuration blocks here; the first is for application configuration and the second is for database configuration.

In the application configuration section:

- The `APP_ENV` variable denotes the system environment in which the application is run. The default value is `local` which is used for local development environments. For production deployment, it should be changed to `production`, as we’ve done here.  
Changing this variable controls log verbosity, caching settings, and how the errors are displayed (depending on the app). With `local` settings, it’s set up to ease development and debugging, which is convenient while working on an app but shouldn’t be used in a production setup. 

- The `APP_DEBUG` variable complements `APP_ENV` and explicitly enables or disables debugging information and verbose error display. On production setups, this value should be set to `false` to prevent debugging information from being displayed to the users.

- The `APP_URL` variable specifies the IP address or domain name under which the site should be accessible. We used `example.com` domain name here, but you should replace it with your own domain the website should be accessed with.

The database configuration section is a little more straightforward:

- `DB_DATABASE` is the name of the database.
- `DB_USERNAME` is the name of the MySQL user that the app should use.
- `DB_PASSWORD` is the database password for that user.

Next, we have to run [database migrations](https://laravel.com/docs/5.4/migrations), which will populate the newly created database with necessary tables for the demo application to run properly.

    php artisan migrate

Artisan will ask to confirm if we intend to run it in production mode. Answer `y` to the question. It will run necessary database tasks afterwards.

    Artisan output **************************************
    * Application In Production! *
    **************************************
    
     Do you really wish to run this command? [y/N] (yes/no) [no]:
     > y
    
    Migration table created successfully.
    Migrated: 2014_10_12_000000_create_users_table
    Migrated: 2014_10_12_100000_create_password_resets_table
    Migrated: 2015_10_27_141258_create_tasks_table

We now have Laravel fully installed and configured. Next, we need to configure Nginx to serve the application.

## Step 5 — Configuring Nginx

The application directory is owned by our system user, **sammy** , and is readable but not writable by the web server. This is correct for the majority of application files, but there are few directories that need special treatment. Specifically, wherever Laravel stores uploaded media and cached data, the web server must be able not only to access them but also to write files to them.

Let’s change the group ownership of the `storage` and `bootstrap/cache` directories to **www-data**.

    sudo chgrp -R www-data storage bootstrap/cache

Then recursively grant all permissions, including write and execute, to the group.

    sudo chmod -R ug+rwx storage bootstrap/cache

We now have all the demo application files in place with the appropriate permissions. Next, we need to alter the Nginx configuration to make it correctly work with the Laravel installation. First, let’s create a [new server block config file](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) for our application by copying over the default file.

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/example.com

Open the newly created configuration file.

    sudo nano /etc/nginx/sites-enabled/example.com

There are few necessary changes you’ll have to make:

- Removing the `default_server` designation from `listen` directives,
- Updating the web root by changing the `root` directive,
- Updating the the `server_name` directive to correctly point to a domain name for the server,
- Updating the request URI handling by changing the `try_files` directive.

The modified Nginx configuration file will look like this:

/etc/nginx/sites-enabled/example.com

    server {
        listen 80;
        listen [::]:80;
    
        . . .
    
        root /var/www/html/quickstart/public;
        index index.php index.html index.htm index.nginx-debian.html;
    
        server_name example.com www.example.com;
    
        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    
        . . .
    }

Let’s explain these changes in more detail.

The `listen` directive in the default configuration file has the `default_server` option enabled, which specifies that the server block should serve a request if no other server block is suitable. Only one of the enabled server blocks can have this option enabled. Because we left the default server block in place, we’ll remove the `default_server` designation from this second configuration file.

The `root` directive specifies where application files are stored. The Laravel application is stored in `/var/www/html/quickstart`, but only the `/public` subdirectory should be exposed to the internet; all other application files should not be accessible via the browser at all. To comply with these best practices, we set the web root to `/var/www/html/quickstart/public`.

The `server_name` directive specifies the list of domain names the server block will respond to. We used `example.com` and `www.example.com` here, but you should replace those with the domain name you want to use for your website.

We also changed the request URI handling. The default settings tell the web server to find an existing file, then an existing directory, or finally to throw a 404 Not Found error (using the built-in `=404` setting). For Laravel to work properly, all requests must be routed to Laravel itself. This means we remove Nginx’s default 404 error handler and set it to `/index.php?$query_string`, which passes the request query to `index.php` file, a main Laravel application file.

When you’ve made the above changes, you can save and close the file. We have to enable the new configuration file by creating a symbolic link from this file to the `sites-enabled` directory.

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

And finally reload Nginx to take the changes into account.

    sudo systemctl reload nginx

Now that Nginx is configured to serve the demo Laravel application, all the components are set up.

Making sure that your deployment is working at this point is easy. Simply visit `http://example.com` in your favorite browser. You’ll see a page with the simple task app, and you can try adding or removing tasks. All changes that you make will be saved to the database and retained for subsequent visits to the website, which you can verify by closing the browser and opening the site once again.

In the next and final step, we will configure TLS encryption to serve the application over a secure connection.

## Step 6 — Securing your Application with TLS

To complete the production setup it is recommended to serve the application through secure HTTPS using TLS. This will make sure that all communication between the application and its visitors will be encrypted, which is especially important if the application asks for sensitive information such as login or password.

[Let’s Encrypt](https://letsencrypt.org/) is a free certificate authority which makes adding TLS to your website straightforward. To enable HTTPS for the freshly deployed application, we’ll be following the [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04) tutorial with some small modifications to accommodate for this specific Laravel app’s setup.

The only changes will be:

- Using the Laravel application’s location (`/var/www/html/quickstart`) instead of the default web root (`/var/www/html`) when requesting an SSL certificate.
- Modifying the `/etc/nginx/sites-available/example.com` configuration file instead of the default server block file.

Specifically, the command to obtain the certificate will be:

    sudo certbot certonly --webroot --webroot-path=/var/www/html/quickstart -d example.com -d www.example.com

And the final version of the `/etc/nginx/sites-available/example.com` configuration file will look like this

/etc/nginx/sites-enabled/example.com

    server {
            listen 80;
            listen [::]:80;
    
            server_name example.com www.example.com;
            return 301 https://$server_name$request_uri;
    }
    
    server {
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
    
            include snippets/ssl-example.com.conf;
            include snippets/ssl-params.conf;
    
            root /var/www/html/quickstart/public;
    
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
            }
    
            location ~ \.php$ {
                    include snippets/fastcgi-php.conf;
                    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
            }
    
            location ~ /\.ht {
                    deny all;
            }
    
            location ~ /.well-known {
                    allow all;
            }
    }

Make sure to check that there are no syntax errors in the configuration.

    sudo nginx -t

If all changes were successful, you will get a result that looks like this:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If that is the case, you can safely restart Nginx to put the changes in effect.

    sudo systemctl restart nginx

The Let’s Encrypt TLS/SSL certificate will be fully in place and the application will be available through a secure connection. To verify if everything works as expected, simply visit `https://example.com`. You should see the same application form as before, but this time the connection will be fully secured.

## Conclusion

You have now successfully deployed a demo application shipped with Laravel to a production environment using the LEMP stack. With real world applications, the list of configuration tasks may involve more steps and application-specific actions. When in doubt, always refer to the documentation of the application you’re deploying, but you can also find lots of useful information in [the official Laravel documentation](https://laravel.com/docs/).
