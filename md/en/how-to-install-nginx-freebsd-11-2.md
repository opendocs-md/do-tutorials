---
author: Mark Drake
date: 2018-11-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-nginx-freebsd-11-2
---

# How to Install Nginx on FreeBSD 11.2

## Introduction

[Nginx](https://www.nginx.com/) is one of the most popular web servers in the world, known for its frequent use as a load balancer and reverse proxy. It’s more resource-friendly than Apache, and many of the largest and most highly trafficked sites on the internet depend on Nginx to serve their content.

In this guide, we will demonstrate how to install Nginx on a FreeBSD 11.2 server.

## Prerequisites

Before beginning this guide, you will need access to a server running FreeBSD. This guide was written specifically with a server running FreeBSD 11.2 in mind, although it should also work on older, supported versions of the operating system.

If you’re new to working with FreeBSD, you may find it helpful to customize this server by following [these instructions](how-to-get-started-with-freebsd).

Additionally, if you plan to set up a domain name for this server, you will need the following:

- A registered domain name that you own and control. If you do not already have a registered domain name, you may register one with one of the many domain name registrars out there (e.g. Namecheap, GoDaddy, etc.).
- A DNS **A Record** that points your domain to the public IP address of your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them.

## Step 1 — Installing Nginx

To begin, we will install Nginx using `pkg`, FreeBSD’s built-in binary package management tool. The following command will update your local copy of the available packages and then install the `nginx` package:

    sudo pkg install nginx

If this is your first time running `pkg`, it will prompt you to confirm that you allow it to bootstrap itself. To do this, press `y` and then `ENTER`. Then, when prompted, confirm that you approve the installation of the `nginx` package by pressing `y` and then `ENTER` once again.

If you are using either the `csh` or `tcsh` shell, make sure to run the `rehash` command. This makes the shell aware of the new applications you installed:

    rehash

**Note:** If you aren’t sure which shell you’re currently using, you can check with the following command:

    echo $SHELL

The output will show the file path of the shell program currently in use:

    Output/bin/tcsh

Nginx is now installed on your server, but it is not yet running. In the next step, we’ll enable Nginx to start running every time the server boots up and start it for this session, as well as walk through the process of securing the server by setting up a firewall with IPFW.

## Step 2 — Enabling the Nginx Service and Setting Up a Firewall with IPFW

In order for FreeBSD to start Nginx as a conventional service, you have to tell FreeBSD that you want to enable it. This will allow you to manage it like any other service, rather than as a standalone application, and will also configure FreeBSD to start it up automatically at boot.

To do this, you first need to know the correct `rc` parameter to set for the `nginx` service. `rc` is a FreeBSD utility that controls the system’s automatic boot processes. Scripts for every service available on the system are located in the `/usr/local/etc/rc.d` directory. These define the parameters that are used to enable each service using the `rcvar` variable. We can see what each service’s `rcvar` is set to by typing:

    grep rcvar /usr/local/etc/rc.d/*

After has been installed, this command will output a listing similar to this:

    Output/usr/local/etc/rc.d/cloudconfig:rcvar="cloudinit_enable"
    /usr/local/etc/rc.d/cloudfinal:rcvar="cloudinit_enable"
    /usr/local/etc/rc.d/cloudinit:rcvar="cloudinit_enable"
    /usr/local/etc/rc.d/cloudinitlocal:rcvar="cloudinit_enable"
    /usr/local/etc/rc.d/nginx:rcvar=nginx_enable
    /usr/local/etc/rc.d/rsyncd:rcvar=rsyncd_enable

The parameter that you need to set for the `nginx` service is highlighted here in this output. The name of the script itself — the last component of the path before the colon — is also helpful to know, as that’s the name that FreeBSD uses to refer to the service.

To enable the `nginx` service you must add its `rcvar` to the `rc.conf` file, which holds the global system configuration information referenced by the startup scripts. Use your preferred editor to open the `/etc/rc.conf` file with `sudo` privileges. Here, we’ll use `ee`:

    sudo ee /etc/rc.conf

At the top of the file, there will be a few `rcvar` parameters already in place. Add the `nginx_enable` `rcvar` parameter below these and set it to `"YES"`:

/etc/rc.conf

    . . .
    sshd_enable="YES"
    nginx_enable="YES"
    
    . . .

While still in the `rc.conf` file, we will add a few more directives to enable and configure an IPFW firewall. [IPFW](https://www.freebsd.org/doc/en/books/handbook/firewalls-ipfw.html) is a stateful firewall written for FreeBSD. It provides a powerful syntax that allows you to customize security rules for most use cases.

Directly below the `nginx_enable` parameter you just added, add the following highlighted lines:

/etc/rc.conf

    . . .
    nginx_enable="YES"
    firewall_enable="YES"
    firewall_type="workstation"
    firewall_myservices="22/tcp 80/tcp"
    firewall_allowservices="any"

Here’s what each of these directives and their settings do:

- `firewall_enable="YES"` — Setting this directive to `"YES"` enables the firewall to start up whenever the server boots.
- `firewall_type="workstation"` — FreeBSD provides several default types of firewalls, each of which have slightly different configurations. By declaring the `workstation` type, the firewall will only protect this server using stateful rules.
- `firewall_myservices="22/tcp 80/tcp"` — The `firewall_myservices` directive is where you can list the TCP ports you want to allow through the firewall. In this example, we’re specifying ports `22` and `80` to allow SSH and HTTP access to the server, respectively.
- `firewall_allowservices="any"` — This allows a machine from any IP address to communicate over the ports specified in the `firewall_myservices` directive.

After adding these lines, save the file and close the editor by pressing `CTRL + C`, typing `exit`, and then pressing `ENTER`.

Then, start the `ipfw` firewall service. Because this is the first time you’re starting the firewall on this server, there’s a chance that doing so will cause your server to stall, making it inaccessible over SSH. The following `nohup` command — which stands for “no hangups” — will start the firewall while preventing stalling and also redirect the standard output and error to a temporary log file:

    sudo nohup service ipfw start >/tmp/ipfw.log 2>&1

If you’re using either the `csh` or `tcsh` shells, though, this redirect will cause `Ambiguous output redirect.` to appear in your output. If you’re using either of these shells, run the following instead to start `ipfw`:

    sudo nohup service ipfw start >&/tmp/ipfw.log

**Note** : In the future, you can manage the `ipfw` firewall as you would any other service. For example, to stop, start, and then restart the service, you would run the following commands:

    sudo service ipfw stop
    sudo service ipfw start
    sudo service ipfw restart

Next, start the `nginx` service

    sudo service nginx start

Then, to test that Nginx is able to serve content correctly, enter your server’s public IP address into the URL bar of your preferred web browser:

    http://your_server_ip

**Note:** If you aren’t sure of your server’s public IP address, you can run the following command which will print your server’s IP address, as seen from another location on the internet:

    curl -4 icanhazip.com

If everything is working correctly, you will see the default Nginx landing page:

![Nginx default page](https://assets.digitalocean.com/freebsd/nginx/nginx_default_page.png)

This shows that Nginx is installed and running correctly and that it’s being allowed through the firewall as expected. There are still a few configuration changes that need to be made, though, in order for it to work with non-default settings or serve content using a domain name.

## Step 3 — Setting Up a Server Block

When using the Nginx web server, _server blocks_ (similar to virtual hosts in Apache) can be used to encapsulate configuration details and host more than one domain from a single server. We will set up a domain called **example.com** , but you should **replace this with your own domain name**. To learn more about setting up a domain name with DigitalOcean, see our [Introduction to DigitalOcean DNS](an-introduction-to-digitalocean-dns).

Nginx on FreeBSD 11.2 has one server block enabled by default that is configured to serve documents out of a directory at `/usr/local/www/nginx`. While this works well for a single site, it can become unwieldy if you are hosting multiple sites. Instead of modifying `/usr/local/www/nginx`, let’s create a directory structure within `/usr/local/www` for our **example.com** site.

Create the directory for **example.com** as follows, using the `-p` flag to create any necessary parent directories:

    sudo mkdir -p /usr/local/www/example.com/html

Next, assign ownership of the directory to the **www** user, the default Nginx runtime user profile:

    sudo chown -R www:www /usr/local/www/example.com

The permissions of your web root should be correct if you haven’t modified your `umask` value, but you can make sure by typing:

    sudo chmod -R 755 /usr/local/www/example.com

Next, create a sample `index.html` page using `ee`:

    sudo ee /usr/local/www/example.com/html/index.html

Inside, add the following sample HTML:

/usr/local/www/example.com/html/index.html

    <html>
        <head>
            <title>Welcome to Example.com!</title>
        </head>
        <body>
            <h1>Success! The example.com server block is working!</h1>
        </body>
    </html>

Save and close the file when you are finished.

In order for Nginx to serve this content, it’s necessary to create a server block with the correct directives. Open the main Nginx configuration file. By default, this is held in the `/usr/local/etc/nginx/` directory:

    sudo ee /usr/local/etc/nginx/nginx.conf

**Note** : Generally, you want to avoid editing the default `nginx.conf` file. However, within this same directory, there’s a file called `nginx.conf-dist`, which is identical to the default `nginx.conf` file. If you ever find that you need to revert with these configuration changes, you can just copy over this file with the following command:

    sudo cp /usr/local/etc/nginx/nginx.conf-dist /usr/local/etc/nginx/nginx.conf

When you first open the file, you’ll see the following at the very top:

/usr/local/etc/nginx/nginx.conf

    #user nobody;
    worker_processes 1;
    
    . . .

Uncomment the `user` directive by removing the pound sign (`#`) and then change the user from **nobody** to **www**. Then update the `worker_processes` directive which allows you to select how many worker processes Nginx will use. The optimal value to enter here isn’t always obvious or easy to find. Setting it to `auto` tells Nginx sets it to one worker per CPU core, which will be sufficient in most cases:

/usr/local/etc/nginx/nginx.conf

    user www;
    worker_processes auto;
    . . .

Then scroll down to the `server` block. With all comments removed, it will look like this:

/usr/local/etc/nginx/nginx.conf

    . . .
        server {
            listen 80;
            server_name localhost;
    
            location / {
                root /usr/local/www/nginx;
                index index.html index.htm;
            }
    
            error_page 500 502 503 504 /50x.html;
    
            location = /50x.html {
                root /usr/local/www/nginx-dist;
            }
        }

Delete this entire server block, including all the commented-out lines, and replace it with the following content:

/usr/local/etc/nginx/nginx.conf

    . . .
        server {
            access_log /var/log/nginx/example.com.access.log;
            error_log /var/log/nginx/example.com.error.log;
            listen 80;
            server_name example.com www.example.com;
    
            location / {
                root /usr/local/www/example.com/html;
                index index.html index.htm;
            }
        }
    . . .

Here’s what the directives in this server block do:

- `access_log`: This directive defines the location of the server’s access logs.
- `error_log`: This defines the file where Nginx will write its error logs.
- `listen`: The `listen` directive declares what port Nginx should listen in on. In this case, we set it to port `80` so it can listen for HTTP traffic.
- `server_name`: Here, point Nginx to your domain name and any aliases you have for it. If you don’t have a domain name, point Nginx to your server’s public IP address.
- `root`: This defines the website document root, which you created earlier in this step.
- `index`: This directive defines the files that will be used as an index, and in which order they should be checked.

All together, with comments removed, the file will look like this:

/usr/local/letc/nginx/nginx.conf

    user www;
    worker_processes 1;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include mime.types;
        default_type application/octet-stream;
        sendfile on;
        keepalive_timeout 65;
    
        server {
            access_log /var/log/nginx/example.com.access.log;
            error_log /var/log/nginx/example.com.error.log;
            listen 80;
            server_name example.com www.example.com;
    
            location / {
                root /usr/local/www/example.com;
                index index.html index.htm;
            }
    
        }
    
    }

Save and close the file when you are finished. Then, test your configuration file for syntax errors by typing:

    sudo nginx -t

If your configuration file has no detectable syntax errors, you’ll see the following output:

    Outputnginx: the configuration file /usr/local/etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /usr/local/etc/nginx/nginx.conf test is successful

If the above command returns with errors, re-open the Nginx configuration file to the location where the error was found and try to fix the problem.

When your configuration checks out correctly, go ahead and reload the `nginx` service to enable your changes:

    sudo service nginx reload

Nginx should now be serving the content you set up in the `index.html` file. Test this by navigating to `http://example.com`, where you should see something like this:

![Nginx first server block](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_server_block_1404/first_block.png)

As a final step, we will go over some commands that will allow you to manage the Nginx service.

## Step 4 — Managing the Nginx Process

Now that you have your web server up and running, let’s review some basic management commands.

To stop your web server, type:

    sudo service nginx stop

To start the web server when it is stopped, type:

    sudo service nginx start

To stop and then start the service again, type:

    sudo service nginx restart

If you are simply making configuration changes, you can reload Nginx without dropping any connections. To do this, type:

    sudo service nginx reload

Lastly, recall how in Step 2 we enabled the `nginx` service by adding the `nginx_enable="YES"` directive to the `rc.conf` file. If you’d like to disable the `nginx` service to keep it from starting up when the server boots, you would need to reopen that file and remove that line.

## Conclusion

You now have a fully functional Nginx web server installed on your machine. From here, you could encrypt your server’s web traffic by enabling HTTPS. To learn how to do this, consult [How To Secure Nginx with Let’s Encrypt on FreeBSD](how-to-secure-nginx-letsencrypt-freebsd). You could also [install and configure MySQL and PHP](how-to-install-an-nginx-mysql-and-php-femp-stack-on-freebsd-10-1) which, along with Nginx, would give you a complete FEMP stack.
