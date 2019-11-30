---
author: Vadym Kalsin
date: 2018-08-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-retrieve-let-s-encrypt-ssl-wildcard-certificates-using-cloudflare-validation-on-centos-7
---

# How to Retrieve Let's Encrypt SSL Wildcard Certificates using CloudFlare Validation on CentOS 7

_The author selected [Code.org](https://www.brightfunds.org/organizations/code-org) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is a certificate authority (CA) that provides free certificates for [Transport Layer Security (TLS) encryption](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs). It provides a software client called [Certbot](https://certbot.eff.org/) which simplifies the process of certificate creation, validation, signing, installation, and renewal.

Let’s Encrypt now supports [wildcard certificates](https://en.wikipedia.org/wiki/Wildcard_certificate) which allow you to secure all subdomains of a domain with a single certificate. This will be useful if you want to host multiple services, such as web interfaces, APIs, and other sites using a single server.

To obtain a wildcard certificate from Let’s Encrypt you have to use one of Certbot’s [DNS plugins](https://certbot.eff.org/docs/using.html#dns-plugins), which include:

- certbot-dns-cloudflare
- certbot-dns-route53
- certbot-dns-google
- certbot-dns-digitalocean

The plugin you choose depends on which service hosts your DNS records. In this tutorial you will obtain a wildcard certificate for your domain using [CloudFlare](https://cloudflare.com) validation with Certbot on CentOS 7. You’ll then configure the certificate to renew it when it expires.

## Prerequisites

To complete this tutorial, you’ll need the following:

- One CentOS 7 server set up by following [the CentOS 7 initial server setup guide](initial-server-setup-with-centos-7), including a sudo non-root user and a firewall.
- A fully registered domain name. You can purchase a domain name on [Namecheap](https://namecheap.com/), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.
- A [Cloudflare](https://www.cloudflare.com/) account.
- A DNS record set up for your domain in Cloudflare’s DNS, along with a couple of subdomains configured. You can follow [CloudFlare’s tutorial on setting up a web site](https://support.cloudflare.com/hc/en-us/articles/201720164-Step-2-Create-a-Cloudflare-account-and-add-a-website) to configure this.

## Step 1 — Installing Certbot

The `certbot` package is not available through CentOS’s package manager by default. You will need to enable the [EPEL](https://fedoraproject.org/wiki/EPEL) repository to install Certbot and its plugins.

To add the CentOS 7 EPEL repository, run the following command:

    sudo yum install -y epel-release

Once the installation completes, you can install `certbot`:

    sudo yum install -y certbot

And then install the CloudFlare plugin for Certbot:

    sudo yum install -y python2-cloudflare python2-certbot-dns-cloudflare

If you are using another DNS service, you can find the corresponding plugin using the `yum search` command:

    yum search python2-certbot-dns

You’ve prepared your server to obtain certificates. Now you need to get the API key from CloudFlare.

## Step 2 — Getting the CloudFlare API

In order for Certbot to automatically renew wildcard certificates, you need to provide it with your CloudFlare login and API key.

Log in to your Cloudflare account and navigate to the [Profile page](https://www.cloudflare.com/a/profile).

Click the **View** button in the **Global API Key** line.

![CloudFlare Profile - API Keys](https://i.imgur.com/VDyv79i.png)

For security reasons, you will be asked to re-enter your Cloudflare account password. Enter it and validate the CAPTCHA. Then click the **View** button again. You’ll see your API key:

![CloudFlare Profile - API Keys](https://i.imgur.com/wjqbplX.png)

Copy this key. You will use it in the next step.

Now return to your server to continue the process of obtaining the certificate.

## Step 3 — Configuring Certbot

You have all of the necessary information to tell Certbot how to use Cloudflare, but let’s write it to a configuration file so that Сertbot can use it automatically.

First run the `certbot` command without any parameters to create the initial configuration file:

    sudo certbot

Next create a configuration file in the `/etc/letsencrypt` directory which will contain your CloudFlare email and API key:

    sudo vi /etc/letsencrypt/cloudflareapi.cfg

Add the following into it, replacing the placeholders with your Cloudflare login and API key:

/etc/letsencrypt/cloudflareapi.cfg

    dns_cloudflare_email = your_cloudflare_login
    dns_cloudflare_api_key = your_cloudflare_api_key

Save the file and exit the editor.  
With Cloudflare’s API key, you can do the same things from the command line that you can do from the Cloudflare UI, so in order to protect your account, make the configuration file readable only by its owner so nobody else can obtain your key:

    sudo chmod 600 /etc/letsencrypt/cloudflareapi.cfg

With the configuration files in place, let’s obtain a certificate.

## Step 4 — Obtaining the Certificate

To obtain a certificate, we’ll use the `certbot` command and specify the plugin we want, the credentials file we want to use, and the server we should use to handle the request. By default, Certbot uses Let’s Encrypt’s production servers, which use [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) API version 1, but Certbot uses another protocol for obtaining wildcard certificates, so you need to provide an ACME v2 endpoint.

Run the following command to obtain the wildcard certificate for your domain:

    sudo certbot certonly --cert-name your_domain --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflareapi.cfg --server https://acme-v02.api.letsencrypt.org/directory -d "*.your_domain" -d your_domain

You will be asked to specify the email address that should receive urgent renewal and security notices:

    Output...
    Plugins selected: Authenticator dns-cloudflare, Installer None
    Enter email address (used for urgent renewal and security notices) (Enter 'c' to
    cancel): your email

Then you’ll be asked to agree to the Terms of Service:

    Output-------------------------------------------------------------------------------
    Please read the Terms of Service at
    https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
    agree in order to register with the ACME server at
    https://acme-v02.api.letsencrypt.org/directory
    -------------------------------------------------------------------------------
    (A)gree/(C)ancel: A

Then you’ll be asked to share your email address with the Electronic Frontier  
Foundation:

    Output-------------------------------------------------------------------------------
    Would you be willing to share your email address with the Electronic Frontier
    Foundation, a founding partner of the Let's Encrypt project and the non-profit
    organization that develops Certbot? We'd like to send you email about EFF and
    our work to encrypt the web, protect its users and defend digital rights.
    -------------------------------------------------------------------------------
    (Y)es/(N)o: N
    

Then Certbot will obtain your certificates. You will see the following message:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/your_domain/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/your_domain/privkey.pem
       Your cert will expire on 2018-07-31. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot
       again. To non-interactively renew *all* of your certificates, run
       "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le
    

Now you have your wildcard certificate. Let’s take a look at what Certbot has downloaded for you. Use the `ls` command to see the contents of the directory that holds your keys and certificates:

    sudo ls /etc/letsencrypt/live/your_domain

    Outputcert.pem chain.pem fullchain.pem privkey.pem README

The `README` file contains information about these files:

    $ cat /etc/letsencrypt/live/your_domain/README

You’ll see output like this:

README

    This directory contains your keys and certificates.
    
    `privkey.pem` : the private key for your certificate.
    `fullchain.pem`: the certificate file used in most server software.
    `chain.pem` : used for OCSP stapling in Nginx >=1.3.7.
    `cert.pem` : will break many server configurations, and should not be used
                     without reading further documentation (see link below).
    
    We recommend not moving these files. For more information, see the Certbot
    User Guide at https://certbot.eff.org/docs/using.html#where-are-my-certificates.

From here, you can configure your servers with the wildcard certificate. You’ll usually only need two of these files: `fullchain.pem` and `privkey.pem`.

For example, you can configure several web-based services:

- wwww.example.com
- api.example.com
- mail.example.com

To do this, you will need a web server, such as Apache or Nginx. The installation and configuration of these servers is beyond the scope of this tutorial, but the following guides will walk you through all the necessary steps to configure the servers and apply your certificates.

For Nginx, take a look at these tutorials:

- [How To Install Nginx on CentOS 7](how-to-install-nginx-on-centos-7)
- [How To Set Up Nginx Server Blocks on CentOS 7](how-to-set-up-nginx-server-blocks-on-centos-7)
- [Configure Nginx to Use SSL](how-to-create-a-self-signed-ssl-certificate-for-nginx-on-centos-7#step-3-configure-nginx-to-use-ssl)

For Apache, consult these tutorials:

- [How To Install Apache On CentOS 7](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7#step-one-%E2%80%94-install-apache)
- [How To Set Up Apache Virtual Hosts on CentOS 7](how-to-set-up-apache-virtual-hosts-on-centos-7)
- [How To Create an SSL Certificate on Apache for CentOS 7](how-to-create-an-ssl-certificate-on-apache-for-centos-7)

Now let’s look at renewing the certificates automatically.

## Step 5 — Renewing certificates

Let’s Encrypt issues short-lived certificates which are valid for 90 days. We’ll need to set up a cron task to check for expiring certificates and renew them automatically.

Let’s create a [cron task](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps)  
which will run the renewal check daily.

Use the following command to open the `crontab` file for editing:

    sudo crontab -e

Add the following line to the file to attempt to renew the certificates daily:

crontab

    30 2 * * * certbot renew --noninteractive

- `30 2 * * *` means “run the following command at 2:30 am, every day”. 
- The `certbot renew` command will check all certificates installed on the system and update any that are set to expire in less than thirty days.
- `--noninteractive` tells Certbot not to wait for user input.

You will need to reload your web server after updating your certificates. The `renew` command includes hooks for running commands or scripts before or after a certificate is renewed. You can also configure these hooks in the renewal configuration file for your domain.

For example, to reload your Nginx server, open the renewal configuration file:

    sudo vi /etc/letsencrypt/renewal/your_domain.conf

Then add the following line under the `[renewalparams]` section:

your\_domain.conf’\>/etc/letsencrypt/renewal/your\_domain.conf

    renew_hook = systemctl reload nginx

Now Certbot will automatically restart your web server after installing the updated certificate.

## Conclusion

In this tutorial you’ve installed the Certbot client, obtained your wildcard certificate using DNS validation and enabled automatic renewals. This will allow you to use a single certificate with multiple subdomains of your domain and secure your web services.
