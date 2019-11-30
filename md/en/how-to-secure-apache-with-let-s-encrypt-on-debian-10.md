---
author: Kathleen Juell, Mark Drake, Erika Heidi
date: 2019-07-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-debian-10
---

# How To Secure Apache with Let's Encrypt on Debian 10

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is a Certificate Authority (CA) that provides an easy way to obtain and install free [TLS/SSL certificates](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), thereby enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client, [Certbot](https://certbot.eff.org/), that attempts to automate most (if not all) of the required steps. Currently, the entire process of obtaining and installing a certificate is fully automated on both Apache and Nginx.

In this tutorial, you will use Certbot to obtain a free SSL certificate for Apache on Debian 10 and set up your certificate to renew automatically.

This tutorial will use a separate Apache virtual host file instead of the default configuration file. [We recommend](how-to-install-the-apache-web-server-on-debian-10#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)) creating new Apache virtual host files for each domain because it helps to avoid common mistakes and maintains the default files as a fallback configuration.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 10 server set up by following this [initial server setup for Debian 10](initial-server-setup-with-debian-10) tutorial, including a non- **root** user with `sudo` privileges and a firewall.

- A fully registered domain name. This tutorial will use **your\_domain** as an example throughout. You can purchase a domain name on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.

- Both of the following DNS records set up for your server. To set these up, you can follow [these instructions for adding domains](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/) and then [these instructions for creating DNS records](https://www.digitalocean.com/docs/networking/dns/how-to/manage-records/).

- Apache installed by following [How To Install Apache on Debian 10](how-to-install-the-apache-web-server-on-debian-10). Be sure that you have a [virtual host file](how-to-install-the-apache-web-server-on-debian-10#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)) set up for your domain. This tutorial will use `/etc/apache2/sites-available/your_domain.conf` as an example.

## Step 1 — Installing Certbot

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the Certbot software on your server.

As of this writing, Certbot is not available from the Debian software repositories by default. In order to download the software using `apt`, you will need to add the backports repository to your `sources.list` file where `apt` looks for package sources. Backports are packages from Debian’s testing and unstable distributions that are recompiled so they will run without new libraries on stable Debian distributions.

To add the backports repository, open (or create) the `sources.list` file in your `/etc/apt/` directory:

    sudo nano /etc/apt/sources.list

At the bottom of the file, add the following line:

/etc/apt/sources.list.d/sources.list

    . . .
    deb http://mirrors.digitalocean.com/debian buster-backports main
    deb-src http://mirrors.digitalocean.com/debian buster-backports main
    deb http://ftp.debian.org/debian buster-backports main

This includes the `main` packages, which are [Debian Free Software Guidelines (DFSG)](https://www.debian.org/social_contract#guidelines)-compliant, as well as the `non-free` and `contrib` components, which are either not DFSG-compliant themselves or include dependencies in this category.

Save and close the file by pressing `CTRL+X`, `Y`, then `ENTER`, then update your package lists:

    sudo apt update

Then install Certbot with the following command. Note that the `-t` option tells `apt` to search for the package by looking in the backports repository you just added:

    sudo apt install python-certbot-apache -t buster-backports

Certbot is now ready to use, but in order for it to configure SSL for Apache, we need to verify that Apache has been configured correctly.

## Step 2 — Setting Up the SSL Certificate

Certbot needs to be able to find the correct virtual host in your Apache configuration for it to automatically configure SSL. Specifically, it does this by looking for a `ServerName` directive that matches the domain you request a certificate for.

If you followed the [virtual host setup step in the Apache installation tutorial](how-to-install-the-apache-web-server-on-debian-10#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)), you should have a `VirtualHost` block for your domain at `/etc/apache2/sites-available/your_domain.conf` with the `ServerName` directive already set appropriately.

To check, open the virtual host file for your domain using `nano` or your favorite text editor:

    sudo nano /etc/apache2/sites-available/your_domain.conf

Find the existing `ServerName` line. It should look like this, with your own domain name instead of `your_domain`:

/etc/apache2/sites-available/your\_domain.conf

    ...
    ServerName your_domain;
    ...

If it doesn’t already, update the `ServerName` directive to point to your domain name. Then save the file, quit your editor, and verify the syntax of your configuration edits:

    sudo apache2ctl configtest

If there aren’t any syntax errors, you will see this in your output:

    OutputSyntax OK

If you get an error, reopen the virtual host file and check for any typos or missing characters. Once your configuration file’s syntax is correct, reload Apache to load the new configuration:

    sudo systemctl reload apache2

Certbot can now find the correct `VirtualHost` block and update it.

Next, let’s update the firewall to allow HTTPS traffic.

## Step 3 — Allowing HTTPS Through the Firewall

If you have the `ufw` firewall enabled, as recommended by the prerequisite guides, you’ll need to adjust the settings to allow for HTTPS traffic. Luckily, when installed on Debian, `ufw` comes packaged with a few profiles that help to simplify the process of changing firewall rules for HTTP and HTTPS traffic.

You can see the current setting by typing:

    sudo ufw status

If you followed the Step 2 of our guide on [How to Install Apache on Debian 10](how-to-install-the-apache-web-server-on-debian-10#step-2-%E2%80%94-adjusting-the-firewall), the output of this command will look like this, showing that only HTTP traffic is allowed to the web server:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    WWW ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    WWW (v6) ALLOW Anywhere (v6)

To additionally let in HTTPS traffic, allow the “WWW Full” profile and delete the redundant “WWW” profile allowance:

    sudo ufw allow 'WWW Full'
    sudo ufw delete allow 'WWW'

Your status should now look like this:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    WWW Full ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    WWW Full (v6) ALLOW Anywhere (v6)        

Next, let’s run Certbot and fetch our certificates.

## Step 4 — Obtaining an SSL Certificate

Certbot provides a variety of ways to obtain SSL certificates through plugins. The Apache plugin will take care of reconfiguring Apache and reloading the config whenever necessary. To use this plugin, type the following:

    sudo certbot --apache -d your_domain -d www.your_domain

This runs `certbot` with the `--apache` plugin, using `-d` to specify the names for which you’d like the certificate to be valid.

If this is your first time running `certbot`, you will be prompted to enter an email address and agree to the terms of service. Additionally, it will ask if you’re willing to share your email address with the [Electronic Frontier Foundation](https://www.eff.org/), a nonprofit organization that advocates for digital rights and is also the maker of Certbot. Feel free to enter `Y` to share your email address or `N` to decline.

After doing so, `certbot` will communicate with the Let’s Encrypt server, then run a challenge to verify that you control the domain you’re requesting a certificate for.

If that’s successful, `certbot` will ask how you’d like to configure your HTTPS settings:

    OutputPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

Select your choice then hit `ENTER`. The configuration will be updated automatically, and Apache will reload to pick up the new settings. `certbot` will wrap up with a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/your_domain/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/your_domain/privkey.pem
       Your cert will expire on 2019-10-20. To obtain a new or tweaked
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

Let’s Encrypt certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. The `certbot` package we installed takes care of this for us by adding a renew script to `/etc/cron.d`. This script runs twice a day and will automatically renew any certificate that’s within thirty days of expiration.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. When necessary, Certbot will renew your certificates and reload Apache to pick up the changes. If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this tutorial, you installed the Let’s Encrypt client `certbot`, downloaded SSL certificates for your domain, configured Apache to use these certificates, and set up automatic certificate renewal. If you have further questions about using Certbot, [their documentation](https://certbot.eff.org/docs/) is a good place to start.
