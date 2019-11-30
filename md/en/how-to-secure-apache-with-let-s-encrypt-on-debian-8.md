---
author: Justin Ellingwood
date: 2016-12-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-debian-8
---

# How To Secure Apache with Let's Encrypt on Debian 8

## Introduction

This tutorial will show you how to set up a TLS/SSL certificate from [Let’s Encrypt](https://letsencrypt.org/) on a Debian 8 server running Apache as a web server. We will also cover how to automate the certificate renewal process using a cron job.

SSL certificates are used within web servers to encrypt the traffic between the server and client, providing extra security for users accessing your application. Let’s Encrypt provides an easy way to obtain and install trusted certificates for free.

## Prerequisites

In order to complete this guide, you will need a Debian 8 server with a non-root `sudo` user for administrative tasks. You can set up a user with the appropriate permissions by following our [Debian 8 initial server setup guide](initial-server-setup-with-debian-8).

You must own or control the registered domain name that you wish to use the certificate with. If you do not already have a registered domain name, you may register one with one of the many domain name registrars out there (e.g. Namecheap, GoDaddy, etc.).

If you haven’t already, be sure to create an **A Record** that points your domain to the public IP address of your server (if you are using DigitalOcean’s DNS, you can follow [this guide](how-to-set-up-a-host-name-with-digitalocean)). This is required because of how Let’s Encrypt validates that you own the domain it is issuing a certificate for. For example, if you want to obtain a certificate for `example.com`, that domain must resolve to your server for the validation process to work. Our setup will use `example.com` and `www.example.com` as the domain names, so **both DNS records are required**.

When you are ready to move on, log into your server using your sudo account.

## Step 1: Install Certbot, the Let’s Encrypt Client

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the `certbot` Let’s Encrypt client on your server.

The `certbot` package was not available when Debian 8 was released. To access the `certbot` package, we will have to enable the Jessie backports repository on our server. This repository can be used to install more recent versions of software than the ones included in the stable repositories.

Add the backports repository to your server by typing:

    echo 'deb http://ftp.debian.org/debian jessie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list

After adding the new repository, update the `apt` package index to download information about the new packages:

    sudo apt-get update

Once the repository is updated, you can install the `python-certbot-apache` package, which pulls in `certbot`, by targeting the backports repository:

**Note:** When using backports, it is recommended to only install the specific packages you require, rather than using the repository for general updates. Backport packages have fewer compatibility guarantees than the main repositories.

To help avoid accidentally installing or updating packages using this repository, you must explicitly pass the `-t` flag with the repository name to install packages from backports.

    sudo apt-get install python-certbot-apache -t jessie-backports

The `certbot` client should now be ready to use.

## Step 2: Set Up the Apache ServerName and ServerAlias

It is possible to pass the domains that we wish to secure as arguments when calling the `certbot` utility. However, `certbot` can also read these from the Apache configuration itself. Since it is good practice to always be explicit about the domains your server should respond to, we will set the `ServerName` and `ServerAlias` in the Apache configuration directly.

When we installed the `python-certbot-apache` service, Apache was installed if it wasn’t already present on the system. Open the default Apache Virtual Host file so that we can explicitly set our domain names:

    sudo nano /etc/apache2/sites-available/000-default.conf

Inside, within the Virtual Host block, add or uncomment the `ServerName` directive and set it to your primary domain name. Any alternative domain names that this server should also respond to can be added using a `ServerAlias` directive.

For our example, we are using `example.com` as our canonical name and `www.example.com` as an alias. When we set these directives, it will look like this:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
        . . .
        ServerName example.com
        ServerAlias www.example.com
        . . .
    </VirtualHost>

When you are finished, save and close the file by holding **CTRL** and pressing **X**. Type **Y** and hit **Enter** to save the file.

Check the configuration file to catch any syntax errors that may have been introduced by your changes:

    sudo apache2ctl configtest

Look for this line in the output:

    OutputSyntax OK

If the file passed the syntax test, restart your Apache service to implement your changes:

    sudo systemctl restart apache2

Now that Apache is configured with your domain names, we can use `certbot` to obtain our SSL certificates.

## Step 3: Adjusting the Firewall

If you have a firewall enabled, you’ll need to adjust the settings to allow for SSL traffic. The required procedure depends on the firewall software you are using. If you do not have a firewall configured currently, feel free to skip forward.

### UFW

If you are using **ufw** , you can see the current setting by typing:

    sudo ufw status

It may look like this, meaning that only SSH traffic is allowed to the web server:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    SSH ALLOW Anywhere
    SSH (v6) ALLOW Anywhere (v6)

To additionally let in HTTP and HTTPS traffic, we can allow the “WWW Full” application profile:

    sudo ufw allow 'WWW Full'

Your status should look like this now:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    SSH ALLOW Anywhere
    WWW Full ALLOW Anywhere
    SSH (v6) ALLOW Anywhere (v6)
    WWW Full (v6) ALLOW Anywhere (v6)

HTTP and HTTPS requests should now be accepted by your server.

### IPTables

If you are using `iptables`, you can see the current rules by typing:

    sudo iptables -S

If you have any rules enabled, they will be displayed. An example configuration might look like this:

    Output-P INPUT DROP
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT

The commands needed to open SSL traffic will depend on your current rules. For a basic rule set like the one above, you can add SSL access by typing:

    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT

If we look at the firewall rules again, we should see the new rule:

    sudo iptables -S

    Output-P INPUT DROP
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT

If you are using a program to automatically apply `iptables` rules at boot, you will want to make sure that you update your configuration with the new rule.

## Step 4: Set Up the SSL Certificate

Generating the SSL Certificate for Apache using the Let’s Encrypt client is quite straightforward. The client will automatically obtain and install a new SSL certificate that is valid for the domains in our Apache configuration.

To execute the interactive installation and obtain a certificate for all of the domains defined in your Apache configuration, type:

    sudo certbot --apache

The `certbot` utility will evaluate your Apache configuration to find the domains that should be covered with the requested certificate. You will be able to deselect any defined domains that you do not wish to be covered under the certificate.

You will be presented with a step-by-step guide to customize your certificate options. You will be asked to provide an email address for lost key recovery and notices, and you will be able to choose between enabling both `http` and `https` access or forcing all requests to redirect to `https`. It is usually safest to require `https`, unless you have a specific need for unencrypted `http` traffic.

When the installation is finished, you should be able to find the generated certificate files at `/etc/letsencrypt/live`. You can verify the status of your SSL certificate with the following link (don’t forget to replace example.com with your domain):

    https://www.ssllabs.com/ssltest/analyze.html?d=example.com&latest

The test may take a few minutes to complete. You should now be able to access your website using a `https` prefix.

## Step 5: Set Up Auto Renewal

Let’s Encrypt certificates are valid for 90 days, but it’s recommended that you renew the certificates every 60 days to allow a margin of error. The `certbot` client has a `renew` command that automatically checks the currently installed certificates and tries to renew them if they are less than 30 days away from the expiration date.

To trigger the renewal process for all installed domains, you should run:

    sudo certbot renew

Because we recently installed the certificate, the command will only check for the expiration date and print a message informing that the certificate is not due to renewal yet. The output should look similar to this:

    OutputSaving debug log to /var/log/letsencrypt/letsencrypt.log
    
    -------------------------------------------------------------------------------
    Processing /etc/letsencrypt/renewal/example.com.conf
    -------------------------------------------------------------------------------
    Cert not yet due for renewal
    
    The following certs are not due for renewal yet:
      /etc/letsencrypt/live/example.com/fullchain.pem (skipped)
    No renewals were attempted.

Notice that if you created a bundled certificate with multiple domains, only the base domain name will be shown in the output, but the renewal should be valid for all domains included in this certificate.

A practical way to ensure your certificates won’t get outdated is to create a cron job that will periodically execute the automatic renewal command for you. Since the renewal first checks for the expiration date and only executes the renewal if the certificate is less than 30 days away from expiration, it is safe to create a cron job that runs every week or even every day, for instance.

Let’s edit the crontab to create a new job that will run the renewal command every week. To edit the crontab for the root user, run:

    sudo crontab -e

You may be prompted to select an editor:

    Outputno crontab for root - using an empty one
    
    Select an editor. To change later, run 'select-editor'.
      1. /bin/nano <---- easiest
      2. /usr/bin/vim.basic
      3. /usr/bin/vim.tiny
    
    Choose 1-3 [1]:

Unless you’re more comfortable with `vim`, press **Enter** to use `nano`, the default.

Include the following content at the end of the crontab, all in one line:

    crontab. . .
    30 2 * * 1 /usr/bin/certbot renew >> /var/log/le-renew.log

Save and exit. This will create a new cron job that will execute the `letsencrypt-auto renew` command every Monday at 2:30 am. The output produced by the command will be piped to a log file located at `/var/log/le-renewal.log`.

For more information on how to create and schedule cron jobs, you can check our [How to Use Cron to Automate Tasks in a VPS](how-to-use-cron-to-automate-tasks-on-a-vps) guide.

## Conclusion

In this guide, we saw how to install a free SSL certificate from Let’s Encrypt in order to secure a website hosted with Apache. We recommend that you check the official [Let’s Encrypt blog](https://letsencrypt.org/blog/) for important updates from time to time.
