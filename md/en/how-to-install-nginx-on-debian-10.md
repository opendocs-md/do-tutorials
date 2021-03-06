---
author: Kathleen Juell, Erika Heidi
date: 2019-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-10
---

# How to Install Nginx on Debian 10

## Introduction

[Nginx](https://nginx.org/) is one of the most popular web servers in the world and responsible for hosting some of the largest and highest-traffic sites on the internet. It is more resource-friendly than Apache in most cases and can be used as a web server or reverse proxy.

In this guide, we’ll discuss how to install Nginx on your Debian 10 server.

## Prerequisites

Before you begin this guide, you should have a regular, non-root user with sudo privileges configured on your server and an active firewall. You can learn how to set these up by following our [initial server setup guide for Debian 10](initial-server-setup-with-debian-10).

When you have an account available, log in as your non-root user to begin.

## Step 1 – Installing Nginx

Because Nginx is available in Debian’s default repositories, it is possible to install it from these repositories using the `apt` packaging system.

Since this is our first interaction with the `apt` packaging system in this session, let’s first update our local package index so that we have access to the most recent package listings:

    sudo apt update

We can now install `nginx`:

    sudo apt install nginx

When prompted to confirm the installation, hit `Enter` to proceed. After that, `apt` will install Nginx and any required dependencies to your server.

## Step 2 – Adjusting the Firewall

Before testing Nginx, the firewall software needs to be adjusted to allow access to the service.

List the application configurations that `ufw` knows how to work with by typing:

    sudo ufw app list

You should get a listing of the application profiles:

    OutputAvailable applications:
    ...
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
    ...

As you can see, there are three profiles available for Nginx:

- **Nginx Full** : This profile opens both port `80` (normal, unencrypted web traffic) and port `443` (TLS/SSL encrypted traffic)
- **Nginx HTTP** : This profile opens only port `80` (normal, unencrypted web traffic)
- **Nginx HTTPS** : This profile opens only port `443` (TLS/SSL encrypted traffic)

It is recommended that you enable the most restrictive profile that will still allow the traffic you’ve configured. Since we haven’t configured SSL for our server yet in this guide, we will only need to allow traffic for HTTP on port `80`.

You can enable this by typing:

    sudo ufw allow 'Nginx HTTP'

You can verify the change by typing:

    sudo ufw status

You should see HTTP traffic allowed in the displayed output:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

## Step 3 – Checking your Web Server

At the end of the installation process, Debian 10 starts Nginx. The web server should already be up and running.

We can check with the `systemd` init system to make sure the service is running by typing:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Wed 2019-07-03 12:52:54 UTC; 4min 23s ago
         Docs: man:nginx(8)
     Main PID: 3942 (nginx)
        Tasks: 3 (limit: 4719)
       Memory: 6.1M
       CGroup: /system.slice/nginx.service
               ├─3942 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
               ├─3943 nginx: worker process
               └─3944 nginx: worker process

As you can see above, the service appears to have started successfully. However, the best way to test this is to actually request a page from Nginx.

You can access the default Nginx landing page to confirm that the software is running properly by navigating to your server’s IP address. If you do not know your server’s IP address, try typing this at your server’s command prompt:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

You will get back a few lines. You can try each in your web browser to see if they work.

When you have your server’s IP address, enter it into your browser’s address bar:

    http://your_server_ip

You should see the default Nginx landing page:

![Nginx default page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

This page is included with Nginx to show you that the server is running correctly.

## Step 4 – Managing the Nginx Process

Now that you have your web server up and running, let’s review some basic management commands.

To stop your web server, type:

    sudo systemctl stop nginx

To start the web server when it is stopped, type:

    sudo systemctl start nginx

To stop and then start the service again, type:

    sudo systemctl restart nginx

If you are simply making configuration changes, Nginx can often reload without dropping connections. To do this, type:

    sudo systemctl reload nginx

By default, Nginx is configured to start automatically when the server boots. If this is not what you want, you can disable this behavior by typing:

    sudo systemctl disable nginx

To re-enable the service to start up at boot, you can type:

    sudo systemctl enable nginx

## Step 5 – Setting Up Server Blocks

When using the Nginx web server, _server blocks_ (similar to virtual hosts in Apache) can be used to encapsulate configuration details and host more than one domain on a single server. We will set up a domain called **your\_domain**. To learn more about setting up a domain name with DigitalOcean, see our [introduction to DigitalOcean DNS](https://www.digitalocean.com/docs/networking/dns/).

Nginx on Debian 10 has one server block enabled by default that is configured to serve documents out of a directory at `/var/www/html`. While this works well for a single site, it can become unmanageable if you are hosting multiple sites. Instead of modifying `/var/www/html`, let’s create a directory structure within `/var/www` for the **your\_domain** website, leaving `/var/www/html` in place as the default directory to be served if a client request doesn’t match any other sites.

Create the directory for **your\_domain** as follows, using the `-p` flag to create any necessary parent directories:

    sudo mkdir -p /var/www/your_domain/html

Next, assign ownership of the directory with the `$USER` environment variable, which should reference your current system user:

    sudo chown -R $USER:$USER /var/www/your_domain/html

The permissions of your web root should be correct if you haven’t modified your `umask` value, but you can make sure by typing:

    sudo chmod -R 755 /var/www/your_domain

Next, create a sample `index.html` page using `nano` or your favorite editor:

    nano /var/www/your_domain/html/index.html

Inside, add the following sample HTML:

/var/www/your\_domain/html/index.html

    <html>
        <head>
            <title>Welcome to your_domain</title>
        </head>
        <body>
            <h1>Success! Your Nginx server is successfully configured for <em>your_domain</em>. </h1>
    <p>This is a sample page.</p>
        </body>
    </html>

Save and close the file when you are finished.

In order for Nginx to serve this content, we need to create a server block with the correct directives that point to our custom web root. Instead of modifying the default configuration file directly, let’s make a new one at `/etc/nginx/sites-available/your_domain`:

    sudo nano /etc/nginx/sites-available/your_domain

Paste in the following configuration block, which is similar to the default, but updated for our new directory and domain name:

/etc/nginx/sites-available/your\_domain

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/your_domain/html;
            index index.html index.htm index.nginx-debian.html;
    
            server_name your_domain www.your_domain;
    
            location / {
                    try_files $uri $uri/ =404;
            }
    }

Notice that we’ve updated the `root` configuration to our new directory, and the `server_name` to our domain name.

Next, let’s enable this server block by creating a symbolic link to our custom configuration file inside the `sites-enabled` directory, which Nginx reads from during startup:

    sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/

Two server blocks are now enabled and configured to respond to requests based on their `listen` and `server_name` directives (you can read more about how Nginx processes these directives [here](understanding-nginx-server-and-location-block-selection-algorithms)):

- `your_domain`: Will respond to requests for `your_domain` and `www.your_domain`.
- `default`: Will respond to any requests on port `80` that do not match the other two blocks.

To avoid a possible hash bucket memory problem that can arise from adding additional server names to your configuration, it is necessary to adjust a single value in the `/etc/nginx/nginx.conf` file. Open the file:

    sudo nano /etc/nginx/nginx.conf

Find the `server_names_hash_bucket_size` directive and remove the `#` symbol to uncomment the line:

/etc/nginx/nginx.conf

    ...
    http {
        ...
        server_names_hash_bucket_size 64;
        ...
    }
    ...

Save and close the file when you are finished.

Next, test to make sure that there are no syntax errors in any of your Nginx files:

    sudo nginx -t

If there aren’t any problems, you will see the following output:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

Once your configuration test passes, restart Nginx to enable your changes:

    sudo systemctl restart nginx

Nginx should now be serving your domain name. You can test this by navigating to `http://your_domain`, where you should see something like this:

![Nginx server block](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_debian10/nginx_serverblock.png)

## Step 6 – Getting Familiar with Important Nginx Files and Directories

Now that you know how to manage the Nginx service itself, you should take a few minutes to familiarize yourself with a few important directories and files.

### Content

- `/var/www/html`: The actual web content, which by default only consists of the default Nginx page you saw earlier, is served out of the `/var/www/html` directory. This can be changed by altering Nginx configuration files.

### Server Configuration

- `/etc/nginx`: The Nginx configuration directory. All of the Nginx configuration files reside here.
- `/etc/nginx/nginx.conf`: The main Nginx configuration file. This can be modified to make changes to the Nginx global configuration.
- `/etc/nginx/sites-available/`: The directory where per-site server blocks can be stored. Nginx will not use the configuration files found in this directory unless they are linked to the `sites-enabled` directory. Typically, all server block configuration is done in this directory, and then enabled by linking to the other directory.
- `/etc/nginx/sites-enabled/`: The directory where enabled per-site server blocks are stored. Typically, these are created by linking to configuration files found in the `sites-available` directory.
- `/etc/nginx/snippets`: This directory contains configuration fragments that can be included elsewhere in the Nginx configuration. Potentially repeatable configuration segments are good candidates for refactoring into snippets.

### Server Logs

- `/var/log/nginx/access.log`: Every request to your web server is recorded in this log file unless Nginx is configured to do otherwise.
- `/var/log/nginx/error.log`: Any Nginx errors will be recorded in this log.

## Conclusion

Now that you have your web server installed, you have many options for the type of content you can serve and the technologies you can use to create a richer experience for your users.
