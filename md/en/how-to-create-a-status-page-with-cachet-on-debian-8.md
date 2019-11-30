---
author: Achilleas Pipinellis
date: 2017-06-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-status-page-with-cachet-on-debian-8
---

# How To Create a Status Page with Cachet on Debian 8

## Introduction

[Cachet](https://cachethq.io/) is a self-hosted status page alternative to hosted services such as [StatusPage.io](https://www.statuspage.io/) and [Status.io](https://status.io/). It helps you communicate the uptime and downtime of your applications and share information about any outages.

It is written in PHP, so if you already have a LAMP or LEMP server, it is easy to install. It has a clean interface and is designed to be responsive so it can work on all devices. In this tutorial, we’ll set up a status page with Cachet on Debian. The software stack we’ll use is:

- **Cachet** for the status page itself
- **Composer** to manage Cachet’s PHP dependencies
- **SQLite** as the database to store Cachet’s data
- **Nginx** to serve the status page

Note that Cachet does not monitor your websites or servers for downtime; Cachet records incidents, which can be updated manually via the web interface or with Cachet’s API. If you are looking for monitoring solutions, check out the [Building for Production: Web Applications – Monitoring](building-for-production-web-applications-monitoring "Building for Production: Web Applications - Monitoring") tutorial.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 8 server set up by following the [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8) tutorial, including a sudo non-root user. Cachet will work with 512MB of memory, but 1GB or more will give the best performance.

- A fully qualified domain name (FQDN) with an A record pointing your domain to your server’s IPv4 address. You can purchase a FQDN on [Namecheap](https://namecheap.com) or get one for free on [Freenom](http://www.freenom.com/en/index.html), and you can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to set up DNS records.

- Nginx installed and set up with Let’s Encrypt. You can install Nginx by following this [How To Install Nginx on Debian 8](how-to-install-nginx-on-debian-8) tutorial, then set up Let’s Encrypt by following the first two steps of [How To Secure Nginx with Let’s Encrypt on Debian 8](how-to-secure-nginx-with-let-s-encrypt-on-debian-8). The rest of the steps can be skipped because we will create our own configuration file for Cachet.

- Composer installed by following steps 1 and 2 of [How To Install and Use Composer on Debian 8](how-to-install-and-use-composer-on-debian-8).

- Git installed by following step 1 of [How To Install Git on Debian 8](how-to-install-git-on-debian-8), so you can pull Cachet’s source from GitHub.

- An SMTP server, so Cachet can send emails for incidents to subscribers and password reminders to users created in Cachet’s interface. You can [use Postfix as a Send-Only SMTP Server](how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-16-04), for example, or use a third party provider like [Mailgun](https://www.mailgun.com/).

## Step 1 — Creating the Cachet User

The very first thing to do is create a separate user account to run Cachet. This will have the added benefit of security and isolation.

    sudo useradd --create-home --shell /bin/bash cachet

This command will create a user named **cachet** with a home directory in `/home/cachet`, whose shell will be set to `/bin/bash`. The default is `/bin/sh`, but it doesn’t provide enough information in its prompt. It will be a passwordless user that will have privileges exclusively to the components Cachet will use.

Now that the user is created, let’s install the PHP dependencies.

## Step 2 — Installing PHP Dependencies

Next, we need to install Cachet’s dependencies, which are a number of PHP packges as well as `wget` and `unzip`, which Composer uses to download and decompress PHP libraries.

    sudo apt-get install \
      php5-fpm php5-curl php5-apcu php5-readline \
      php5-mcrypt php5-apcu php5-cli php5-gd php5-sqlite\
      wget unzip

You can learn more about any individual package from [the official PHP Extensions List](http://php.net/manual/en/extensions.php).

Let’s now configure `php-fpm`, the FastCGI Process Manager. Nginx will use this to proxy requests to Cachet.

First, create the file that will host the information for Cachet that `php-fpm` needs. Open `/etc/php5/fpm/pool.d/cachet.conf` with `nano` or your favorite editor.

    sudo nano /etc/php5/fpm/pool.d/cachet.conf

Paste in the following:

/etc/php5/fpm/pool.d/cachet.conf

    [cachet]
    user = cachet
    group = cachet
    listen.owner = www-data
    listen.group = www-data
    listen = /var/run/php5-fpm-cachet.sock
    php_admin_value[disable_functions] = exec,passthru,shell_exec,system
    php_admin_flag[allow_url_fopen] = off
    request_terminate_timeout = 120s
    pm = ondemand
    pm.max_children = 5
    pm.process_idle_timeout = 10s
    pm.max_requests = 500
    chdir = /

Save and close the file.

You can read more about these settings in the article on [How To Host Multiple Websites Securely With Nginx And Php-fpm](how-to-host-multiple-websites-securely-with-nginx-and-php-fpm-on-ubuntu-14-04), but here’s what each line in this file is for:

- `[cachet]` is the name of the pool. Each pool must have a unique name
- `user` and `group` are Linux user and the group under which the new pool will be running. It’s the same as the user we created in Step 1.
- `listen.owner` and `listen.group` define the ownership of the listener, i.e. the socket of the new `php-fpm` pool. Nginx must be able to read this socket, so we’re using theb **www-data** user and group.
- `listen` specifies a unique location of the socket file for each pool.
- `php_admin_value` allows you to set custom PHP configuration values. Here, we’re using it disable functions which can run Linux commands (`exec,passthru,shell_exec,system`).
- `php_admin_flag` is similar to `php_admin_value`, but it is just a switch for boolean values, i.e. `on` and `off`. We’ll disable the PHP function `allow_url_fopen` which allows a PHP script to open remote files and could be used by an attacker.
- The `pm` option allows you to configure the performance of the pool. We’ve set it to `ondemand` which provides a balance to keep memory usage low and is a reasonable default. If you have plenty of memory, then you can set it to `static`. If you have a lot of CPU threads to work with, then `dynamic` might be a better choice.
- The `chdir` option should be `/` which is the root of the filesystem. This shouldn’t be changed unless you use another important option (`chroot`).

Restart `php-fpm` for the changes to take effect.

    sudo systemctl restart php5-fpm

If you haven’t done already, enable the `php-fpm` service so that it starts automatically when the server is rebooted:

    sudo systemctl enable php5-fpm

Now that the general PHP packages are installed, let’s download Cachet.

## Step 3 — Downloading Cachet

Cachet’s source code is hosted on GitHub. That makes it easy to use Git in order to download, install, and — as we’ll see later&nbsp;— upgrade it.

The next few steps should be followed as the **cachet** user, so switch to it.

    sudo su - cachet

Clone Cachet’s source code into a new directory called `www`.

    git clone https://github.com/cachethq/Cachet.git www

Once that’s done, navigate into the new directory where Cachet’s source code lives.

    cd www

From this point on, you have all the history of Cachet’s development, including Git branches and tags. You can see the latest stable release from [Cachet’s releases page](https://github.com/CachetHQ/Cachet/releases), but you can also view the Git tags in this directory.

At publication time, the latest stable version of Cachet was v2.3.11. Use Git to check out that version:

    git checkout v2.3.11

Next, let’s get familiar with Cachet’s configuration file.

## Step 4 — Configuring Cachet

Cachet requires a configuration file called `.env`, which must be present for Cachet to start. In it, you can configure the environment variables that Cachet uses for its setup.

Let’s copy the configuration example that comes with Cachet for a backup.

    cp .env.example .env

There are two bits of configuration we’ll add here: one to configure the database and one to configure a mail server.

For the database, we will use SQLite. It’s easy to configure and doesn’t require installation of any additional server components.

First, create the empty file that will host our database:

    touch ./database/database.sqlite

Next, open `.env` with `nano` or your favorite editor in order to configure the database settings.

    nano .env

Because we’ll be using SQLite, we’ll need to remove a lot of settings. Locate the block of settings that begin with `DB_`:

Original .env

    . . .
    DB_DRIVER=mysql
    DB_HOST=localhost
    DB_DATABASE=cachet
    DB_USERNAME=homestead
    DB_PASSWORD=secret
    DB_PORT=null
    DB_PREFIX=null
    . . .

Delete everything except for the `DB_DRIVER` line, and change it from `mysql` to `sqlite`.

Updated .env

    . . .
    DB_DRIVER=sqlite
    . . .

**Note:**  
You can check [Cachet’s database options](https://github.com/CachetHQ/Cachet/blob/2.4/config/database.php) for all the possible database driver names if you are using another database, like MySQL or PostgreSQL.

Next, you’ll need to fill in your SMTP server details for the `MAIL_*` settings:

.env

    . . .
    MAIL_HOST=smtp.example.com
    MAIL_PORT=25
    MAIL_USERNAME=smtp_username
    MAIL_PASSWORD=smtp_password
    MAIL_ADDRESS=notifications@example.com
    MAIL_NAME="Status Page"
    . . .

Where:

- `MAIL_HOST` should be your mail server’s URL.
- `MAIL_PORT` should be the port which the mail server listens on (usually `25`).
- `MAIL_USERNAME` should be the username for the SMTP account setup (usually the whole email address).
- `MAIL_PASSWORD` should be the password for the SMTP account setup.
- `MAIL_ADDRESS` should be the email address from which the notifications to the subscribers will be sent.
- `MAIL_NAME` is the name that will appear in the emails sent to the subscribers. Note that any values with spaces in them should be contained within double quotes.

You can learn more about Cachet’s mail drivers in [the mail.php source code](https://github.com/CachetHQ/Cachet/blob/v2.3.10/config/mail.php) and [the corresponding mail documentation from Laravel](https://laravel.com/docs/5.2/mail).

After you finish editing the file, save and exit. Next, you need to set up Cachet’s database.

## Step 5 — Migrating the Database

The PHP libraries that Cachet depends on are handled by Composer. First, make sure you are in the right directory.

    cd /home/cachet/www

Then run Composer and install the dependencies, excluding the ones used for development purposes. Depending on the speed of your Internet connection, this may take a moment.

    composer install --no-interaction --no-dev -o --no-scripts

Create the database schema and run the migrations.

    php artisan migrate

**Note:** In the latest stable version (`2.3.11`), [there is a bug](https://github.com/CachetHQ/Cachet/issues/1997) when using SQLite which requires you to run the `migrate` command before anything else.

Type `yes` when asked. You’ll see output like this:

    Output **************************************
    * Application In Production! *
    **************************************
    
     Do you really wish to run this command? (yes/no) [no]:
     > yes
    
    Migration table created successfully.
    Migrated: 2015_01_05_201324_CreateComponentGroupsTable
    ...
    Migrated: 2016_06_02_075012_AlterTableMetricsAddOrderColumn
    Migrated: 2016_06_05_091615_create_cache_table

The next command, `php artisan app:install`, takes a backup of the database, runs the migrations, and automatically generates the application key (i.e. the `APP_KEY` value in `.env`) which Cachet uses for all of its encryption.

**Warning:** Never change the `APP_KEY` value that is in the `.env` file after you have installed and started using Cachet in a production environment. This will result in all of your encrypted/hashed data being lost. Use the `php artisan app:install` command only once. For this reason, it’s a good idea to keep a backup of `.env`.

Complete the installation.

    php artisan app:install

The output will look like this:

    OutputClearing settings cache...
    Settings cache cleared!
    . . .
    Clearing cache...
    Application cache cleared!
    Cache cleared!

As a last proactive step, remove Cachet’s cache to avoid 500 errors.

    rm -rf bootstrap/cache/*

Now that the database is ready, we can configure Cachet’s task queue.

## Step 6 — Configuring the Task Queue

Cachet uses a queue to schedule tasks that need to run asynchronously, such as sending emails. The recommended way is to use [Supervisor](http://supervisord.org/), a process manager which provides a consistent interface through which processes can be monitored and controlled.

First, make sure you log out of the **cachet** user’s session and switch back to your sudo non-root user.

    exit

Install Supervisor.

    sudo apt-get install supervisor

Then create the file that will contain information that Supervisor needs from Cachet. Open `/etc/supervisor/conf.d/cachet.conf`.

    sudo nano /etc/supervisor/conf.d/cachet.conf

This file tells Supervisor how to run and manage its process. You can read more about Supervisor in the article [How To Install and Manage Supervisor on Ubuntu and Debian VPS](how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps).

And add the following contents. Make sure to update Cachet’s directory and username if you’ve used different onces.

/etc/supervisor/conf.d/cachet.conf

    [program:cachet-queue]
    command=php artisan queue:work --daemon --delay=1 --sleep=1 --tries=3
    directory=/home/cachet/www/
    redirect_stderr=true
    autostart=true
    autorestart=true
    user=cachet

Save and close the file, then restart Supervisor.

    sudo systemctl restart supervisor

Enable the Supervisor service so that it starts automatically when the server is rebooted.

    sudo systemctl enable supervisor

The database and task queue are ready; the next component to set up is the web server.

## Step 7 — Configuring Nginx

We will use Nginx as the web server proxy that will talk to `php-fpm`. The prerequisites section has tutorials on how to set up Nginx with a TLS certificate issued by Let’s Encrypt.

Let’s add the Nginx configuration file necessary for Cachet. Open `/etc/nginx/sites-available/cachet.conf` with `nano` or your favorite editor.

    sudo nano /etc/nginx/sites-available/cachet.conf

This is the full text of the file, which you should copy and paste in. Make sure to replace `example.com` with your domain name. The function of each section is described in more detail below.

/etc/nginx/sites-available/cachet.conf

    server {
        server_name example.com;
        listen 80;
        return 301 https://$server_name$request_uri;
    }
    
    server {
        listen 443;
        server_name example.com;
    
        root /home/cachet/www/public;
        index index.php;
    
        ssl on;
        ## Location of the Let's Encrypt certificates
        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
        ## From https://cipherli.st/
        ## and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
        ssl_ecdh_curve secp384r1;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 8.8.8.8 8.8.4.4 valid=300s;
        resolver_timeout 5s;
        ## Disable preloading HSTS for now. You can use the commented out header line that includes
        ## the "preload" directive if you understand the implications.
        #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
        add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        ssl_buffer_size 1400;
    
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
    
        location / {
            try_files $uri /index.php$is_args$args;
        }
    
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm-cachet.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
            fastcgi_keep_conn on;
        }
    }

Here’s what each section of this file does.

The first `server` block redirects all HTTP traffic to HTTPS:

Partial cachet.conf

    server {
        server_name example.com;
        listen 80;
        return 301 https://$server_name$request_uri;
    }
    
    . . .

The second `server` block contains specific information about this setup, like SSL details and `php-fpm` configuration.

The `root` directive tells Nginx where the root directory of Cachet is. Is should point to the `public` directory and since we cloned Cachet in `/home/cachet/www/`, it ultimately becomes `root /home/cachet/www/public;`.

Partial cachet.conf

    . . .
    server {
        listen 443;
        server_name example.com;
    
        root /home/cachet/www/public;
        index index.php;
        . . .
    }

The SSL certificates live inside the Let’s Encrypt directory, which should be named after your domain name:

Partial cachet.conf

    . . .
    server {
        . . .
        ssl on;
        ## Location of the Let's Encrypt certificates
        ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
        . . .
    }

The rest of the SSL options are taken directly from the [Nginx and Let’s Encrypt tutorial](how-to-secure-nginx-with-let-s-encrypt-on-debian-8):

Partial cachet.conf

    . . .
    server {
        . . .
        ## From https://cipherli.st/
        ## and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
        ssl_ecdh_curve secp384r1;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;
        ssl_stapling on;
        ssl_stapling_verify on;
        resolver 8.8.8.8 8.8.4.4 valid=300s;
        resolver_timeout 5s;
        ## Disable preloading HSTS for now. You can use the commented out header line that includes
        ## the "preload" directive if you understand the implications.
        #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
        add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        ssl_buffer_size 1400;
    
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        . . .
    }

The `location ~ \.php$` section tells Nginx how to serve PHP files. The most important part is to point to the Unix socket file that we used when we created `/etc/php5/fpm/pool.d/cachet.conf`. Specifically, that is `/var/run/php5-fpm-cachet.sock`.

Partial cachet.conf

    . . .
    server {
        . . .
        location / {
            try_files $uri /index.php$is_args$args;
        }
    
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm-cachet.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_index index.php;
            fastcgi_keep_conn on;
        }
    }

Save and close the file if you haven’t already.

Now that the Cachet configuration for Nginx is created, create a symlink to the `sites-enabled` directory, because this is where Nginx looks and picks the configuration files to use:

    sudo ln -s /etc/nginx/sites-available/cachet.conf /etc/nginx/sites-enabled/cachet.conf

Restart Nginx for the changes to take effect.

    sudo systemctl restart nginx

And enable the Nginx service so that it starts automatically when the server is rebooted.

    sudo systemctl enable nginx

That’s it! If you now navigate to the domain name in your browser, you’ll see Cachet’s setup page. Let’s walk through it.

## Step 8 — Finishing Cachet’s Initial Setup

The remainder of Cachet’s setup is done through the GUI in your browser. It involves setting the site name and timezone as well as creating the administrator account. There are three steps (setting up the environment, the status page, and the administrator account), and you can always change the configuration later in Cachet’s settings dashboard.

### Environment Setup

The first configuration step is the Environment Setup.

**Note:** The Cachet version we are using [has a bug](https://github.com/CachetHQ/Cachet/issues/2218) where email settings are not shown in the Environment Setup page even, if you have already set them up in `.env`. This will be fixed in version 2.4.

The fields should be filled in as follows:

- **Cache Driver** should be **ACP(u)**.
- **Session Driver** should be **ACP(u)**.
- **Mail Driver** should be **SMTP**.
- **Mail Host** should be your email server address.
- **Mail From Address** should be the email address from which the notifications to the subscribers will be sent.
- **Mail Username** should be the username for the SMTP account setup (usually your whole email address).
- **Mail Password** should be the password for the SMTP account setup.

Click **Next** to go to the next step.

### Status Page Setup

In this section, you set up the site name, site domain, timezone, and language.

**Note:** Cachet has support for many languages, but it is a community-driven project, which means that there may be some untranslated strings in non-English languages. You can view the [list of supported languages](https://crowdin.com/project/cachet), which also includes the percentage of translated content.

The fields should be filled in as follows:

- **Site Name:** The name that will appear in your dashboard.
- **Site Domain:** The FQDN you chose for Cachet.
- **Select your timezone:** Pick a timezone depending on your audience. A good default is to choose UTC.
- **Select your language:** Choose the language that Cachet’s interface will use.
- **Show support for Cachet:** If you select this option, a **Powered by Cachet** message will be shown at the footer of your public dashboard.

Click **Next** to go to the next step.

### Administrator Account Setup

Finally, set up the administrator account. Pick your username, and enter a valid email address and a strong password.

Click **Complete Setup** to save all the changes.

### Complete Setup

On the Complete Setup page, you will be informed that Cachet has been configured successfully. You can now click on the **Go the dashboard** button to log in with your admin credentials and visit Cachet’s dashboard page.

Cachet is now fully set up and functional. The last step covers how to upgrade Cachet in the future.

## Step 9 — Upgrading Cachet

Using Git makes it extremely easy to upgrade when a new version of Cachet comes out. All you need to do is to checkout that relevant tag and then run the database migrations.

**Note:** It is always a good idea to back up Cachet and its database before attempting to upgrade to a new version. For SQLite, you only need to copy the `database/database.sqlite` file.

First, switch to the **cachet** user and move to Cachet’s installation directory.

    sudo su - cachet
    cd /home/cachet/www

You can optionally turn on the maintenance page.

    php artisan down

Fetch the latest Cachet code from GitHub.

    git fetch --all

And list all tags.

    git tag -l

You will see all current tags starting with the letter `v`. You may notice some that are in a beta or Release Candidate (RC) status. Because this a production server, you can ignore those. You can also visit [the Cachet releases page](https://github.com/CachetHQ/Cachet/releases/latest) to see what the latest tag is.

When you find the tag you want to use to upgrade, use Git to check out that tag. For example, if you were to upgrade to version 2.4.0, you would use:

    git checkout v2.4.0

Remove Cachet’s cache before continuing.

    rm -rf bootstrap/cache{,t}/*

Next, upgrade the Composer dependencies, which usually contain bug fixes, performance enhancements, and new features.

    composer install --no-interaction --no-dev -o --no-scripts

Finally, run the migrations.

    php artisan app:update

If you turned on the maintenance page, you can now enable access again.

    php artisan up

The new version of Cachet will be up and running.

## Conclusion

You’ve set up Cachet with SSL backed by SQLite and know how to keep it maintained with Git. You can choose other databases, like MySQL or PostgreSQL. To explore more of Cachet’s options, check out the [official Cachet documentation](https://docs.cachethq.io/v1.0/docs/welcome).
