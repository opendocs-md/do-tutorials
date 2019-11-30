---
author: Erika Heidi
date: 2015-12-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04
---

# How To Secure Apache with Let's Encrypt on Ubuntu 14.04

## Introduction

This tutorial will show you how to set up a TLS/SSL certificate from [Let’s Encrypt](https://letsencrypt.org/) on an Ubuntu 14.04 server running Apache as a web server.

SSL certificates are used within web servers to encrypt the traffic between the server and client, providing extra security for users accessing your application. Let’s Encrypt provides an easy way to obtain and install trusted certificates for free.

## Prerequisites

In order to complete this guide, you will need:

- An Ubuntu 14.04 server with a non-root sudo user, which you can set up by following our [Initial Server Setup](initial-server-setup-with-ubuntu-14-04) guide
- The Apache web server installed with [one or more domain names](how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts) properly configured

When you are ready to move on, log into your server using your sudo-enabled account.

## Step 1 — Download the Let’s Encrypt Client

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the `certbot` software on your server. The Certbot developers maintain their own Ubuntu software repository with up-to-date versions of the software. Because Certbot is in such active development it’s worth using this repository to install a newer Certbot than provided by Ubuntu.

First, add the repository:

    sudo add-apt-repository ppa:certbot/certbot

You’ll need to press `ENTER` to accept. Afterwards, update the package list to pick up the new repository’s package information:

    sudo apt-get update

And finally, install Certbot from the new repository with `apt-get`:

    sudo apt-get install python-certbot-apache

The `certbot` Let’s Encrypt client is now ready to use.

## Step 2 — Set Up the SSL Certificate

Generating the SSL Certificate for Apache using the `certbot` Let’s Encrypt client is quite straightforward. The client will automatically obtain and install a new SSL certificate that is valid for the domains provided as parameters.

To execute the interactive installation and obtain a certificate that covers only a single domain, run the `certbot` command with:

    sudo certbot --apache -d example.com

If you want to install a single certificate that is valid for multiple domains or subdomains, you can pass them as additional parameters to the command. The first domain name in the list of parameters will be the **base** domain used by Let’s Encrypt to create the certificate, and for that reason we recommend that you pass the bare top-level domain name as first in the list, followed by any additional subdomains or aliases:

    sudo certbot --apache -d example.com -d www.example.com

For this example, the **base** domain will be `example.com`.

You will be prompted to provide an email address for lost key recovery and notices, and you will be need to agree to the Let’s Encrypt terms of service. You’ll then be asked to choose between enabling both `http` and `https` access or force all requests to redirect to `https`.

When the installation is finished, you should be able to find the generated certificate files at `/etc/letsencrypt/live`. You can verify the status of your SSL certificate with the following link (don’t forget to replace example.com with your **base** domain):

    https://www.ssllabs.com/ssltest/analyze.html?d=example.com&latest

You should now be able to access your website using a `https` prefix.

## Step 3 — Verifying Certbot Auto-Renewal

Let’s Encrypt certificates only last for 90 days. However, the certbot package we installed takes care of this for us by running `certbot renew` twice a day via a systemd timer. On non-systemd distributions this functionality is provided by a cron script placed in `/etc/cron.d`. The task runs twice daily and will renew any certificate that’s within thirty days of expiration.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. When necessary, Certbot will renew your certificates and reload Apache to pick up the changes. If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this guide, we saw how to install a free SSL certificate from Let’s Encrypt in order to secure a website hosted with Apache. We recommend that you check the official [Let’s Encrypt blog](https://letsencrypt.org/blog/) for important updates from time to time, and read [the Certbot documentation](https://certbot.eff.org/docs/) for more details about the Certbot client.
