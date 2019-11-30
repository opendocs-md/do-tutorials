---
author: Mitchell Anicas
date: 2015-12-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04
---

# How To Secure Nginx with Let's Encrypt on Ubuntu 14.04

## Introduction

Let’s Encrypt is a new Certificate Authority (CA) that provides an easy way to obtain and install free TLS/SSL certificates, thereby enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client, Certbot, that attempts to automate most (if not all) of the required steps. Currently, the entire process of obtaining and installing a certificate is fully automated on both Apache and Nginx web servers.

In this tutorial, we will show you how to use Certbot to obtain a free SSL certificate and use it with Nginx on Ubuntu 14.04 LTS. We will also show you how to automatically renew your SSL certificate.

We will use the default Nginx configuration file in this tutorial instead of a separate server block file. [We recommend](technical-recommendations-and-best-practices-for-digitalocean-s-tutorials#web-servers) creating new Nginx server block files for each domain because it helps to avoid some common mistakes and maintains the default files as a fallback configuration as intended. If you want to set up SSL using server blocks instead, you can follow [this Nginx server blocks with Let’s Encrypt tutorial](how-to-set-up-let-s-encrypt-with-nginx-server-blocks-on-ubuntu-16-04).

## Prerequisites

Before following this tutorial, you’ll need a few things.

- An Ubuntu 14.04 server with a non-root user who has `sudo` privileges. You can learn how to set up such a user account by following our [initial server setup for Ubuntu 14.04 tutorial](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04).
- Nginx installed, [How To Install Nginx on Ubuntu 14.04 LTS](how-to-install-nginx-on-ubuntu-14-04-lts)
- You must own or control the registered domain name that you wish to use the certificate with. If you do not already have a registered domain name, you may register one with one of the many domain name registrars out there (e.g. Namecheap, GoDaddy, etc.).
- A DNS **A Record** that points your domain to the public IP address of your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them. This is required because of how Let’s Encrypt validates that you own the domain it is issuing a certificate for. For example, if you want to obtain a certificate for `example.com`, that domain must resolve to your server for the validation process to work. Our setup will use `example.com` and `www.example.com` as the domain names, so **both DNS records are required**.

Once you have all of the prerequisites out of the way, let’s move on to installing Certbot, the Let’s Encrypt client software.

## Step 1 — Installing Certbot

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the `certbot` software on your server. The Certbot developers maintain their own Ubuntu software repository with up-to-date versions of the software. Because Certbot is in such active development it’s worth using this repository to install a newer Certbot than provided by Ubuntu.

First, add the repository:

    sudo add-apt-repository ppa:certbot/certbot

You’ll need to press `ENTER` to accept. Afterwards, update the package list to pick up the new repository’s package information:

    sudo apt-get update

And finally, install Certbot with `apt-get`:

    sudo apt-get install python-certbot-nginx

The `certbot` Let’s Encrypt client is now ready to use.

## Step 2 — Setting up Nginx

Certbot can automatically configure SSL for Nginx, but it needs to be able to find the correct `server` block in your config. It does this by looking for a `server_name` directive that matches the domain you’re requesting a certificate for. If you’re starting out with a fresh Nginx install, you can update the default config file:

    sudo nano /etc/nginx/sites-available/default

Find the existing `server_name` line:

/etc/nginx/sites-available/default

    server_name localhost;

Replace `localhost` with your domain name:

/etc/nginx/sites-available/default

    server_name example.com www.example.com;

Save the file and quit your editor. Verify the syntax of your configuration edits with:

    sudo nginx -t

If that runs with no errors, reload Nginx to load the new configuration:

    sudo service nginx reload

Certbot will now be able to find the correct `server` block and update it. Now we’ll update our firewall to allow HTTPS traffic.

## Step 3 — Obtaining an SSL Certificate

Certbot provides a variety of ways to obtain SSL certificates, through various plugins. The Nginx plugin will take care of reconfiguring Nginx and reloading the config whenever necessary:

    sudo certbot --nginx -d example.com -d www.example.com

This runs `certbot` with the `--nginx` plugin, using `-d` to specify the names we’d like the certificate to be valid for.

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

Select your choice then hit `ENTER`. The configuration will be updated, and Nginx will reload to pick up the new settings. `certbot` will wrap up with a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at
       /etc/letsencrypt/live/example.com/fullchain.pem. Your cert will
       expire on 2017-10-23. To obtain a new or tweaked version of this
       certificate in the future, simply run certbot again with the
       "certonly" option. To non-interactively renew *all* of your
       certificates, run "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le

Your certificates are now downloaded, installed, and configured. Try reloading your website using `https://` and notice your browser’s security indicator. It should represent that the site is properly secured, usually with a green lock icon. If you test your server using the [SSL Labs Server Test](https://www.ssllabs.com/ssltest/), it will get an **A** grade.

## Step 4 — Verifying Certbot Auto-Renewal

Let’s Encrypt’s certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. The `certbot` package we installed takes care of this for us by running ‘certbot renew’ twice a day via a systemd timer. On non-systemd distributions this functionality is provided by a script placed in `/etc/cron.d`. This task runs twice a day and will renew any certificate that’s within thirty days of expiration.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. When necessary, Certbot will renew your certificates and reload Nginx to pick up the changes. If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this tutorial we’ve installed the Let’s Encrypt client `certbot`, downloaded SSL certificates for our domain, configured Nginx to use these certificates, and set up automatic certificate renewal. If you have further questions about using Certbot, [their documentation](https://certbot.eff.org/docs/) is a good place to start.
