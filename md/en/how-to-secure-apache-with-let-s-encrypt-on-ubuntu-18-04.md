---
author: Kathleen Juell, Erika Heidi
date: 2018-04-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04
---

# How To Secure Apache with Let's Encrypt on Ubuntu 18.04

## Introduction

Let’s Encrypt is a Certificate Authority (CA) that provides an easy way to obtain and install free [TLS/SSL certificates](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), thereby enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client, Certbot, that attempts to automate most (if not all) of the required steps. Currently, the entire process of obtaining and installing a certificate is fully automated on both Apache and Nginx.

In this tutorial, you will use Certbot to obtain a free SSL certificate for Apache on Ubuntu 18.04 and set up your certificate to renew automatically.

This tutorial will use a separate Apache virtual host file instead of the default configuration file. [We recommend](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)) creating new Apache virtual host files for each domain because it helps to avoid common mistakes and maintains the default files as a fallback configuration.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 18.04 server set up by following this [initial server setup for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) tutorial, including a sudo non-root user and a firewall.

- A fully registered domain name. This tutorial will use **your\_domain** as an example throughout. You can purchase a domain name on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.

- Both of the following DNS records set up for your server. You can follow [this introduction to DigitalOcean DNS](an-introduction-to-digitalocean-dns) for details on how to add them.

- Apache installed by following [How To Install Apache on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04). Be sure that you have a [virtual host file](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-recommended) for your domain. This tutorial will use `/etc/apache2/sites-available/your_domain.conf` as an example.

## Step 1 — Installing Certbot

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the Certbot software on your server.

Certbot is in very active development, so the Certbot packages provided by Ubuntu tend to be outdated. However, the Certbot developers maintain a Ubuntu software repository with up-to-date versions, so we’ll use that repository instead.

First, add the repository:

    sudo add-apt-repository ppa:certbot/certbot

You’ll need to press `ENTER` to accept.

Install Certbot’s Apache package with `apt`:

    sudo apt install python-certbot-apache

Certbot is now ready to use, but in order for it to configure SSL for Apache, we need to verify some of Apache’s configuration.

## Step 2 — Set Up the SSL Certificate

Certbot needs to be able to find the correct virtual host in your Apache configuration for it to automatically configure SSL. Specifically, it does this by looking for a `ServerName` directive that matches the domain you request a certificate for.

If you followed the [virtual host set up step in the Apache installation tutorial](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)), you should have a VirtualHost block for your domain at `/etc/apache2/sites-available/your_domain.com.conf` with the `ServerName` directive already set appropriately.

To check, open the virtual host file for your domain using `nano` or your favorite text editor:

    sudo nano /etc/apache2/sites-available/your_domain.conf

Find the existing `ServerName` line. It should look like this:

/etc/apache2/sites-available/your\_domain.conf

    ...
    ServerName your_domain;
    ...

If it does, exit your editor and move on to the next step.

If it doesn’t, update it to match. Then save the file, quit your editor, and verify the syntax of your configuration edits:

    sudo apache2ctl configtest

If you get an error, reopen the virtual host file and check for any typos or missing characters. Once your configuration file’s syntax is correct, reload Apache to load the new configuration:

    sudo systemctl reload apache2

Certbot can now find the correct VirtualHost block and update it.

Next, let’s update the firewall to allow HTTPS traffic.

## Step 3 — Allowing HTTPS Through the Firewall

If you have the `ufw` firewall enabled, as recommended by the prerequisite guides, you’ll need to adjust the settings to allow for HTTPS traffic. Luckily, Apache registers a few profiles with `ufw` upon installation.

You can see the current setting by typing:

    sudo ufw status

It will probably look like this, meaning that only HTTP traffic is allowed to the web server:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache (v6) ALLOW Anywhere (v6)

To additionally let in HTTPS traffic, allow the Apache Full profile and delete the redundant Apache profile allowance:

    sudo ufw allow 'Apache Full'
    sudo ufw delete allow 'Apache'

Your status should now look like this:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache Full ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache Full (v6) ALLOW Anywhere (v6)        

Next, let’s run Certbot and fetch our certificates.

## Step 4 — Obtaining an SSL Certificate

Certbot provides a variety of ways to obtain SSL certificates through plugins. The Apache plugin will take care of reconfiguring Apache and reloading the config whenever necessary. To use this plugin, type the following:

    sudo certbot --apache -d your_domain -d www.your_domain

This runs `certbot` with the `--apache` plugin, using `-d` to specify the names you’d like the certificate to be valid for.

If this is your first time running `certbot`, you will be prompted to enter an email address and agree to the terms of service. After doing so, `certbot` will communicate with the Let’s Encrypt server, then run a challenge to verify that you control the domain you’re requesting a certificate for.

If that’s successful, `certbot` will ask how you’d like to configure your HTTPS settings:

    OutputPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

Select your choice then hit `ENTER`. The configuration will be updated, and Apache will reload to pick up the new settings. `certbot` will wrap up with a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/your_domain/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/your_domain/privkey.pem
       Your cert will expire on 2018-07-23. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot again
       with the "certonly" option. To non-interactively renew *all* of
       your certificates, run "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le
    

Your certificates are downloaded, installed, and loaded. Try reloading your website using `https://` and notice your browser’s security indicator. It should indicate that the site is properly secured, usually with a green lock icon. If you test your server using the [SSL Labs Server Test](https://www.ssllabs.com/ssltest/), it will get an **A** grade.

Let’s finish by testing the renewal process.

## Step 5 — Verifying Certbot Auto-Renewal

Let’s Encrypt’s certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. The `certbot` package we installed takes care of this for us by adding a renew script to `/etc/cron.d`. This script runs twice a day and will automatically renew any certificate that’s within thirty days of expiration.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. When necessary, Certbot will renew your certificates and reload Apache to pick up the changes. If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this tutorial, you installed the Let’s Encrypt client `certbot`, downloaded SSL certificates for your domain, configured Apache to use these certificates, and set up automatic certificate renewal. If you have further questions about using Certbot, [their documentation](https://certbot.eff.org/docs/) is a good place to start.
