---
author: Mateusz Papiernik
date: 2017-05-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-host-a-website-with-caddy-on-centos-7
---

# How To Host a Website with Caddy on CentOS 7

## Introduction

[Caddy](https://caddyserver.com/) is a new web server created with ease of use in mind. It’s simple enough to be used as a quick development server and robust enough to be used in production environments.

It features an intuitive configuration file, HTTP/2 support, and automatic TLS encryption. HTTP/2 is the new version of the HTTP protocol that makes websites faster by using single connection for transferring multiple files and header compression among other features. TLS is used to serve websites encrypted over a secure connection and, while it has been widely adopted on the Internet, it’s often a hassle to get and install certificates manually.

Caddy integrates closely with [Let’s Encrypt](how-to-secure-nginx-with-let-s-encrypt-on-centos-7), a certificate authority which provides free TLS/SSL certificates and automatically obtains and renews the certificates when needed. In other words, every website that Caddy serves can be automatically served over a secure connection with no additional configuration or action necessary.

In this tutorial, you will install and configure Caddy. After following this tutorial, you will have a simple working website served using HTTP/2 and a secure TLS connection.

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server set up with [this initial server setup tutorial](initial-server-setup-with-centos-7), including a sudo non-root user.
- A domain name configured to point to your server. This is necessary for Caddy to obtain an SSL certificate for the website; without using a proper domain name, the website will not be served securely with TLS encryption. You can learn how to point domains to DigitalOcean Droplets by following the [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) tutorial.
- Optionally, the `nano` text editor installed with `sudo yum install nano`. CentOS comes with the `vi` text editor by default, but `nano` can be more user friendly.

## Step 1 — Installing the Caddy Binaries

The Caddy project provides an installation script that will retrieve and install the Caddy server’s binary files. To execute it, type:

    curl -s https://getcaddy.com | bash

You can view the script by visiting `https://getcaddy.com` in your browser or downloading the file with `wget` or `curl` before you execute it.

During the installation, the script will use `sudo` to gain administrative privileges in order to put Caddy files in system-wide directories, so it might prompt you for a password.

The command output will look like this:

    Caddy installation script outputDownloading Caddy for linux/amd64...
    https://caddyserver.com/download/linux/amd64?plugins=
    Extracting...
    Putting caddy in /usr/local/bin (may require password)
    [sudo] password for sammy:
    Caddy 0.10.2
    Successfully installed

After the script finishes, the Caddy binaries are installed on the server and ready to use. You can verify that Caddy binaries have been put in place by using `which` to check their location.

    which caddy

The command output will say that the Caddy binary can be found in `/usr/local/bin/caddy`.

Caddy does not create any system-wide configuration during installation and does not install itself as a service, which means it won’t start up automatically during boot. In the next few steps, we’ll create the user account to use with Caddy, files Caddy needs to function and install its service file.

## Step 2 — Creating the User and Group for Caddy

While Apache and Nginx, two most popular HTTP servers, create their own unprivileged users during installation from system packages, Caddy doesn’t do that. For security reasons it should not be started using the superuser `root` account either. In this step we will create a dedicaded user named `caddy` which will be solely used for running Caddy and accessing its files.

To create user named `caddy` let’s type:

    sudo adduser -r -d /var/www -s /sbin/nologin caddy

The `-r` switch makes the newly created account a so called system account, the `-d` switch denotes the home directory for this user, in our case it will be `/var/www` which we will create later on. The unprivileged user should not be able to login and access system shell, which we make sure of with `-s` switch setting up a desired shell to `/sbin/nologin`, a system command disallowing system login. The last parameter is the username itself - in our case, `caddy`.

Now, when we have the user for Caddy web server available, we can configure necessary directories for storing Caddy configuration files in the next step.

## Step 3 — Setting Up Necessary Directories

Caddy’s automatic TLS support and unit file (which we’ll install in the next step) expect particular directories and files to exist with specific permissions. We’ll create them all in this step.

First, create a directory that will house the main `Caddyfile`, which is a configuration file that tells Caddy what websites should it serve and how.

    sudo mkdir /etc/caddy

Change the owner of this directory to the **root** user and its group to **www-data** so Caddy can read it.

    sudo chown -R root:caddy /etc/caddy

In this directory, create an empty `Caddyfile` which we’ll edit later.

    sudo touch /etc/caddy/Caddyfile

Create another directory in `/etc/ssl`. Caddy needs this to store the SSL private keys and certificates that it automatically obtains from Let’s Encrypt.

    sudo mkdir /etc/ssl/caddy

Caddy needs to be able to write to this directory when it obtains the certificate, so make the owner the **caddy** user . You can leave the group as **root** , unchanged from the default:

    sudo chown -R caddy:root /etc/ssl/caddy

Then make sure no one else can read those files by removing all the access rights for others.

    sudo chmod 0770 /etc/ssl/caddy

The final directory we need to create is the one where the website itself will be published. We will use `/var/www`, which is customary and also the default path when using other web servers, like Apache or Nginx.

    sudo mkdir /var/www

This directory should be completely owned by **caddy**.

    sudo chown caddy:caddy /var/www

You have now prepared the necessary environment for Caddy to run. In the next step, we will configure Caddy as a system service to ensure it starts with system boot and can be managed with `systemctl`.

## Step 4 — Installing Caddy as a System Service

While Caddy does not install itself as a service, the project provides an official [`systemd` unit file](understanding-systemd-units-and-unit-files). This file does assume the directory structure we set up in the previous step, so make sure your configuration matches.

Download the file from the official Caddy repository. The additional `-o` parameter to the `curl` command will save the file in the `/etc/systemd/system/` directory and make it visible to `systemd`.

    sudo curl -s https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service -o /etc/systemd/system/caddy.service

Before we can move on, we have to modify the file slightly to make it use our unprivileged `caddy` user to run the server.

Let’s open the file with `vi` or your favourite text editor (here’s a [short introduction to `vi`](installing-and-using-the-vim-text-editor-on-a-cloud-server#modal-editing))

    sudo vi /etc/systemd/system/caddy.service

and find the fragment responsible for specifying the user account and group.

/etc/systemd/system/caddy.service

    ; User and group the process will run as.
    User=www-data
    Group=www-data

Change both values to `caddy` as follows:

/etc/systemd/system/caddy.service

    ; User and group the process will run as.
    User=caddy
    Group=caddy

Save and close the file to exit. The service file is now ready to be used with our installation. Make `systemd` aware of the new service file.

    sudo systemctl daemon-reload

Then, enable Caddy to run on boot.

    sudo systemctl enable caddy.service

You can verify that the service has been properly loaded and enabled to start on boot by checking its status.

    sudo systemctl status caddy.service

The output should look as follows:

    Caddy service status output● caddy.service - Caddy HTTP/2 web server
       Loaded: loaded (/etc/systemd/system/caddy.service; enabled; vendor preset: disabled)
       Active: inactive (dead)
         Docs: https://caddyserver.com/docs

Specifically, it says that the service is **loaded** and **enabled** , but it is not yet running. We will not start the server just yet because the configuration is still incomplete.

You have now configured Caddy as a system service which will start automatically on boot without the need to run it manually. Next, we’ll allow web traffic through the firewall.

## Step 5 — Allowing HTTP and HTTPS Connections (optional)

If you have followed [Additional Recommended Steps for New CentOS 7 Servers](additional-recommended-steps-for-new-centos-7-servers) tutorial as well and are using a firewall, we have to manually add firewall rules to pass through the internet traffic to Caddy.

Caddy serves websites using HTTP and HTTPS protocols, so we need to allow access to the appropriate ports in order to make Caddy available from the internet.

    sudo firewall-cmd --permanent --zone=public --add-service=http 
    sudo firewall-cmd --permanent --zone=public --add-service=https
    sudo firewall-cmd --reload

All three commands, when run, will output the following success message:

    firewall-cmd outputsuccess

This will allow Caddy to serve websites to the visitors freely. In the next step, we will create a sample web page and update the `Caddyfile` to serve it in order to test the Caddy installation.

## Step 6 — Creating a Test Web Page and a Caddyfile

Let’s start by creating a very simple HTML page which will display a plain **Hello World!** message. This command will create an `index.html` file in the website directory we created earlier with just the one line of text, `<h1>Hello World!</h1>`, inside.

    echo '<h1>Hello World!</h1>' | sudo tee /var/www/index.html

Next, we’ll fill out the `Caddyfile`. The `Caddyfile`, in its simplest form, consists of one or more _server blocks_ which each define the configuration for a single website. A server block starts with an address definition and is followed by curly braces. Inside the curly braces, you can include configuration directives to apply to that website.

An _address definition_ is specified in the form `protocol://host:port`. Caddy will assume some defaults by itself if you leave some fields blank. For example, if you specify the protocol but not the port, the latter will be automatically derived (i.e. port `80` is assumed for HTTP, and port `443` is assumed for HTTPS). The rules governing the address format are described in-depth in [the official Caddyfile documentation](https://caddyserver.com/docs/caddyfile).

Open the `Caddyfile` you created in Step 2 using `vi` or your favorite text editor.

    sudo vi /etc/caddy/Caddyfile

Paste in the following contents:

/etc/caddy/Caddyfile

    http:// {
        root /var/www
        gzip
    }

Then save the file and exit. Let’s explain what this specific `Caddyfile` does.

Here, we’re using `http://` for the address definition. This tells Caddy it should bind to port `80` and serve all requests using plain HTTP protocol (without TLS encryption), regardless of the domain name used to connect to the server. This will allow you to access the websites Caddy is hosting using your server’s IP address.

Inside the curly braces of our server block, there are two directives:

- The `root` directive tells Caddy where the website files are located. In our example, it’s `/var/www`, where we created the test page.
- The `gzip` directive tells Caddy to use Gzip compression to make the website faster. It does not need additional configuration.

Once the configuration file is ready, start the Caddy service.

    sudo systemctl start caddy

We can now test if the website works. For this you use your server’s public IP address. If you do not know your server’s IP address, you can get it with `curl -4 icanhazip.com`. Once you have it, visit `http://your_server_ip` in your favorite browser to see the **Hello World!** website.

This means your Caddy installation is working correctly. In the next step, you will enable a secure connection to your website with Caddy’s automatic TLS support.

## Step 7 — Configuring Automatic TLS

One of the main features that distinguishes Caddy from other web servers is its ability to automatically request and renew TLS certificates from Let’s Encrypt, a free certificate authority (CA). In addition, setting Caddy up to automatically serve websites over secure connection only requires a one line change in the `Caddyfile`.

Caddy takes care of enabling secure HTTPS connection for all configured server blocks and obtaining necessary certificates automatically, assuming some requirements are met by the server blocks configuration.

In order for TLS to work, the following requirements must be met:

- Caddy must be able to bind itself to port `443` for HTTPS, and the same port must be accessible from the internet.
- The protocol must not be set to HTTP, the port must not be not set to `80`, and TLS must not be explicitly turned off or overridden with other settings (e.g. with the `tls` directive in the server block).
- The hostname must be valid domain name; it must not not empty or set to `localhost` or an IP address. This is necessary because Let’s Encrypt can only issue certificates to valid domain names.
- Caddy must know the email address that can be used for key recovery with Let’s Encrypt.

If you’ve been following this tutorial, the first requirement is already met. However, the current server block address is configured simply as `http://`, defining a plain HTTP scheme with no encryption as well as no domain name. We have also not provided Caddy with an e-mail address which Let’s Encrypt requires when requesting for a certificate. If the address is not supplied in the configuration, Caddy asks for it during startup. However, because Caddy is installed as a system service, it cannot ask questions during startup and in the result it will not start properly at all.

To fix this, open the `Caddyfile` for editing again.

    sudo vi /etc/caddy/Caddyfile

First, replace the address definition of `http://` with your domain. This removes the insecure connection forced by HTTP and provides a domain name for the TLS certificate. Second, provide Caddy with an email address using the `tls` directive inside the server block.

The modified `Caddyfile` should look as follows, with your domain and email address substituted in:

/etc/caddy/Caddyfile

    example.com {
        root /var/www
        gzip
        tls sammy@example.com
    }

Save the file and exit the editor. To apply the changes, restart Caddy.

    sudo systemctl restart caddy

Now direct your browser to `https://example.com` to verify if the changes were applied correctly. If so, you should once again see the **Hello World!** page. This time you can check that the website is served with HTTPS by looking at the URL or for a lock symbol in the URL bar.

## Conclusion

You have now configured Caddy to properly serve your website over a secure TLS connection. It will automatically obtain and renew certificates from Let’s Encrypt, serve your site over a secure connection using the newer HTTP/2 protocol, and reduce loading time by using gzip compression.

This is a simple example to get started with Caddy. You can read more about Caddy’s unique features and configuration directives for the `Caddyfile` in the [official Caddy documentation](https://caddyserver.com/docs).
