---
author: M. Watson
date: 2017-02-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-let-s-encrypt-certificates-for-multiple-apache-virtual-hosts-on-ubuntu-16-04
---

# How to Set Up Let’s Encrypt Certificates for Multiple Apache Virtual Hosts on Ubuntu 16.04

## **Status:** Deprecated

This article is deprecated and no longer maintained.

### Reason

Due to changes with Certbot, the content in this article has been superseded by our main [Apache and Let’s Encrypt tutorial for Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

### See Instead

This article may still be useful as a reference, but may not work or follow best practices. We strongly recommend using [How To Secure Apache with Let’s Encrypt on Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

## Introduction

SSL certificates are used within web servers to encrypt the traffic between server and client, providing extra security for users accessing your application. Let’s Encrypt provides an easy way to obtain and install trusted certificates for free. This tutorial will show you how to set up TLS/SSL certificates from [Let’s Encrypt](https://letsencrypt.org/) for securing multiple virtual hosts on Apache.

## Prerequisites

In order to complete this guide, you will need:

- One 16.04 server with a non-root sudo user and a firewall, which you can set up by following our [Initial Ubuntu 16.04 server setup tutorial](initial-server-setup-with-ubuntu-16-04) guide
- The Apache web server installed and hosting multiple virtual hosts, each with their own config file, which you can set up by following this [Apache virtual hosts tutorial](how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04).

For the purpose of this guide, we will install Let’s Encrypt certificates for the domains `example.com` and `test.com`. These will be referenced throughout the guide, but you should substitute them with your own domains while following along.

## Step 1 — Installing the Let’s Encrypt Client

Let’s Encrypt certificates are fetched via client software running on your server. The official client is called Certbot, and its developers maintain their own Ubuntu software repository with up-to-date versions. Because Certbot is in such active development it’s worth using this repository to install a newer version than Ubuntu provides by default.

First, add the repository:

    sudo add-apt-repository ppa:certbot/certbot

You’ll need to press `ENTER` to accept. Afterwards, update the package list to pick up the new repository’s package information:

    sudo apt-get update

And finally, install Certbot from the new repository with `apt-get`:

    sudo apt-get install python-certbot-apache

The `certbot` Let’s Encrypt client is now ready to use. Next, we’ll create the certificates.

## Step 2 — Setting Up the Certificates

Generating the SSL certificate for Apache is straightforward. Certbot will automatically obtain and install a new SSL certificate that is valid for the domains provided as parameters.

**Note** : It’s possible to bundle multiple Let’s Encrypt certificates together, even when the domain names are different. However, it’s recommended that you create separate certificates for unique domain names.

As such, you’ll need to follow this step multiple times (once for each virtual host). As a general rule of thumb, only subdomains of a particular domain should be bundled together.

The following command takes a comma-separated list of domain names as parameters after the `-d` flag. The first domain name listed is the base domain used by Certbot to create the certificate. For this reason, we recommend that you pass the bare top-level domain name first, followed by any additional subdomains or aliases.

Start the interactive installation for `example.com` to create a bundled certificate for that domain:

    sudo certbot --apache -d example.com

You will be asked to provide an email address for lost key recovery and notices, and you will be able to choose whether or not to redirect all `http` traffic to `https`, thereby removing `http` access. It’s more secure to force `https`, so you should choose that unless you have a specific need to allow both.

When the installation is finished, you will be able to find the generated certificate files at `/etc/letsencrypt/live`. You can verify the status of your SSL certificate at `https://www.ssllabs.com/ssltest/analyze.html?d=example.com&latest`, and you can now access your website using a `https` prefix. Remember to follow this step again for every domain you’re using.

## Step 3 — Verifying Certbot Auto-Renewal

Let’s Encrypt certificates only last for 90 days. However, the certbot package we installed takes care of this for us by running `certbot renew` twice a day via a systemd timer. On non-systemd distributions this functionality is provided by a cron script placed in `/etc/cron.d`. The task runs twice daily and will renew any certificate that’s within thirty days of expiration.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. When necessary, Certbot will renew your certificates and reload Apache to pick up the changes. If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this guide, we saw how to install free SSL certificates from Let’s Encrypt in order to secure multiple virtual hosts on Apache. We recommend that you check the official [Let’s Encrypt blog](https://letsencrypt.org/blog/) for important updates from time to time, and read [the Certbot documentation](https://certbot.eff.org/docs/) for more details about the Certbot client.
