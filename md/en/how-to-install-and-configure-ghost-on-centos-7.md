---
author: Kevin Isaac
date: 2017-04-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ghost-on-centos-7
---

# How To Install and Configure Ghost on CentOS 7

## Introduction

[Ghost](https://ghost.org/) is a light-weight open-source blogging platform which is easy to use. Ghost is fully customizable, with many themes available.

In this tutorial, you’ll set up Ghost on CentOS 7. You’ll also configure Nginx to proxy requests to Ghost, and keep Ghost running in the background as a system service.

## Prerequisites

To complete this tutorial, you will need:

- One 1GB CentOS 7 server set up by following the [Initial Server Setup with CentOS 7 guide](initial-server-setup-with-centos-7), including a sudo non-root user.
- Node.js installed using the EPEL repository method explained in the tutorial: [How To Install Node.js on a CentOS 7 server](how-to-install-node-js-on-a-centos-7-server).
- Nginx installed on your server, as shown in [How To Install Nginx on CentOS 7](how-to-install-nginx-on-centos-7).

## Step 1 — Installing Ghost

First, we need to install Ghost. We’ll place Ghost in the `/var/www/ghost` directory, which is the recommended installation location.

Download the latest version of Ghost from Ghost’s GitHub repository using `wget`:

    wget https://ghost.org/zip/ghost-latest.zip

To unpack the archive, first install the `unzip` program with the package manager. It’s always a good idea to make sure that the system is up-to-date before installing a new program, so update the packages and install `unzip` with the following commands:

    sudo yum update -y
    sudo yum install unzip -y

The `-y` flag in the preceding commands updates and installs packages automatically without asking for a confirmation from the user.

Once `unzip` is installed, unzip the downloaded package to the `/var/www/ghost` directory. First, create the `/var/www` folder, then unzip the file:

    sudo mkdir /var/www
    sudo unzip -d /var/www/ghost ghost-latest.zip

Switch to the `/var/www/ghost/` directory:

    cd /var/www/ghost/

Then install the Ghost dependencies, but only the ones needed for production. This skips any dependencies which are only needed by people who develop Ghost.

    sudo npm install --production

Ghost is installed once this process completes, but we need to set up Ghost before we can start it.

## Step 2 — Configuring Ghost

Ghost uses a configuration file located at `/var/www/ghost/config.js`. This file doesn’t exist out of the box, but the Ghost installation includes the file `config.example.js`, which we’ll use as a starting point.

Copy the example configuration file to `/var/www/ghost/config.js`. We’ll copy the file instead of moving it so that we have a copy of the original configuration file in case we need to revert your changes.

    sudo cp config.example.js config.js

Open the file for editing:

    sudo vi config.js

We have to change the URL that Ghost uses. If we don’t, the links on the blog will take visitors to [my-ghost-blog.com](http://my-ghost-blog.com). Change the value of the `url` field to your domain name, or to your server’s IP address if you don’t want to use a domain right now.

/var/www/ghost/config.js

    
    ...
    
    config = {
        // ### Production
        // When running Ghost in the wild, use the production environment
        // Configure your URL and mail settings here
        production: {
            url: 'http://your_domain_or_ip_address',
            mail: {},
    ...

The `url` value must be in the form of a URL, like `http://example.com` or `http://11.11.11.11`. If this value is not formatted correctly, Ghost will not start.

Ghost can function without the mail settings; they’re only necessary if you need to support password recovery for Ghost users. We’ll skip configuring this setting in this tutorial.

You can customize Ghost further by following the configuration details at [the official site](http://ghost.org).

Save the file and exit the editor.

While still in the `/var/www/ghost` directory, start Ghost with the following command:

    sudo npm start --production

The output should be similar to the following:

    Output
    > ghost@0.11.7 start /var/www/ghost
    > node index
    
    WARNING: Ghost is attempting to use a direct method to send email.
    It is recommended that you explicitly configure an email service.
    Help and documentation can be found at http://support.ghost.org/mail.
    
    Migrations: Creating tables...
    ...
    
    Ghost is running in production...
    Your blog is now available on http://your_domain_or_ip_address
    Ctrl+C to shut down

Ghost is listening on port `2368`, and it’s not listening on the public network interface, so you won’t be able to access it directly. Let’s set up Nginx in front of Ghost.

## Step 3 — Configuring Nginx to Proxy Requests to Ghost

The next step is to set up Nginx to serve our Ghost blog. This will allow connections on port `80` to connect through to the port that Ghost is running on, so people can access your Ghost blog without adding the `:2368` to the end of the address. It also adds a layer of indirection and sets you up to scale out your blog if it grows.

If Ghost is still running in your terminal, press `CTRL+C` to shut down the Ghost instance before you continue.

Now let’s configure Nginx. Change to the `/etc/nginx` directory first:

    cd /etc/nginx/

If you installed Nginx from the CentOS EPEL repository as shown in the prerequisite tutorial, you will not have the `sites-available` and `sites-enabled` directories, which are used to manage web site configurations. Let’s create them:

    sudo mkdir sites-available
    sudo mkdir sites-enabled

Next, create a new file in `/etc/nginx/sites-available/` called `ghost`:

    sudo vi /etc/nginx/sites-available/ghost

Place the following configuration in the file and change `your_domain_or_ip_address` to your domain name, or your servers IP address if you don’t have a domain:

/etc/nginx/sites-available/ghost

    server {
        listen 80;
        server_name your_domain_or_ip_address;
        location / {
        proxy_set_header HOST $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:2368;
        }
    }

This basic configuration sends all requests for this server to the Ghost blog running on port `2368`, and it sets the appropriate HTTP headers so that when you look at your Ghost logs, you’ll see the original IP address of your visitors. You can learn more about this configuration in [Understanding Nginx HTTP Proxying, Load Balancing, Buffering, and Caching](understanding-nginx-http-proxying-load-balancing-buffering-and-caching).

Save the file, exit the editor, and enable this configuration by creating a symlink for this file in the `/etc/nginx/sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/ghost /etc/nginx/sites-enabled/ghost

Nginx won’t use this new configuration until we modify the default Nginx configuration file and tell it to include the configuration files in the `sites-enabled` folder. In addition, we have to disable the default site. Open up the `nginx.conf` file in your editor:

    sudo vi nginx.conf

Include the following line inside the `http` block to include the configuration files in the `sites-enabled` folder:

/etc/nginx/nginx.conf

    
    http {
    ...
        # Load modular configuration files from the /etc/nginx/conf.d directory.
        # See http://nginx.org/en/docs/ngx_core_module.html#include
        # for more information.
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;

Then completely comment out the `server` block found inside the `http` block:

/etc/nginx/nginx.conf

    ...
    
        # Load modular configuration files from the /etc/nginx/conf.d directory.
        # See http://nginx.org/en/docs/ngx_core_module.html#include
        # for more information.
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
    
    
    # server {
    # listen 80 default_server;
    # listen [::]:80 default_server;
    # server_name _;
    # root /usr/share/nginx/html;
    #
    # # Load configuration files for the default server block.
    # include /etc/nginx/default.d/*.conf;
    #
    # location / {
    # }
    #
    # error_page 404 /404.html;
    # location = /40x.html {
    # }
    #
    # error_page 500 502 503 504 /50x.html;
    # location = /50x.html {
    # }
    ...
    ...

Save the file and exit the editor. Test the configuration to ensure there are no issues:

    sudo nginx -t

You’ll see the following output if everything is correct:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If you see any errors, fix them and retest the configuration.

With a working configuration file, restart Nginx to apply the changes:

    sudo systemctl restart nginx

Before we start Ghost again, let’s create a new user account to run Ghost.

## Step 4 – Running Ghost as a Separate User

To improve security, we’ll run Ghost under a separate user account. This user will only have access to the `/var/www/ghost` directory and its home folder. This way, if Ghost gets compromised, you minimize the potential damage to your system.

Create a new `ghost` user with the following command:

    sudo adduser --shell /bin/bash ghost

Then make this new user the owner of the `/var/www/ghost` directory:

    sudo chown -R ghost:ghost /var/www/ghost/

Now let’s make sure this user can run Ghost. Log in as the `ghost` user:

    sudo su - ghost

Now start Ghost under this user and ensure it runs:

    cd /var/www/ghost
    npm start --production

You should be able to access your blog at `http://your_domain_or_ip_address`. Nginx will send requests to your Ghost instance.

Things are working great, but let’s make sure Ghost continues to run well into the future.

## Step 5 — Running Ghost as a System Service

Currently, Ghost is running in our terminal. If we log off, our blog will shut down. Let’s get Ghost running in the background and make sure it restarts when the system restarts. To do this, we’ll create a `systemd` unit file that specifies how `systemd` should manage Ghost. Press `CTRL+C` to stop Ghost, and log out of the `ghost` user account by pressing `CTRL+D`.

Create a new file to hold the definition of the `systemd` unit file:

    sudo vi /etc/systemd/system/ghost.service

Add the following configuration to the file, which defines the service’s name, the group and user for the service, and information on how it should start:

/etc/systemd/system/ghost.service

    [Unit]
    Description=Ghost
    After=network.target
    
    [Service]
    Type=simple
    
    WorkingDirectory=/var/www/ghost
    User=ghost
    Group=ghost
    
    ExecStart=/usr/bin/npm start --production
    ExecStop=/usr/bin/npm stop --production
    Restart=always
    SyslogIdentifier=Ghost
    
    [Install]
    WantedBy=multi-user.target

If you’re not familiar with `systemd` unit files, take a look at the tutorial [Understanding Systemd Units and Unit Files](understanding-systemd-units-and-unit-files) which should get you up to speed quickly.

Save the file and exit the editor. Then enable and start the service:

    sudo systemctl enable ghost.service
    sudo sytemctl start ghost.service

Once again, visit `http://your_domain_or_ip_address` and you’ll see your blog.

## Conclusion

In this tutorial, you installed Ghost, configured Nginx to proxy requests to Ghost, and ensured that Ghost runs as a system service. There is a lot more you can do with Ghost, though. Take a look at these tutorials to learn more about how to use your new blog:

- [How To Configure and Maintain Ghost from the Command Line](how-to-configure-and-maintain-ghost-from-the-command-line).
- [How To Change Themes and Adjust Settings in Ghost](how-to-change-themes-and-adjust-settings-in-ghost).
