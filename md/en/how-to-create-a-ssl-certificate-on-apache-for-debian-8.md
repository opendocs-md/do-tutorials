---
author: Alvin Wan
date: 2015-06-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-apache-for-debian-8
---

# How To Create a SSL Certificate on Apache for Debian 8

## Introduction

This tutorial walks you through the setup and configuration of an Apache server secured with an SSL certificate. By the end of the tutorial, you will have a server accessible via HTTPS.

SSL is based on the mathematical intractability of resolving a large integer into its also-large prime factors. Using this, we can encrypt information using a private-public key pair. Certificate authorities can issue SSL certificates that verify the authenticity of such a secured connection, and on the same note, a self-signed certificate can be produced without third-party support.

In this tutorial, we will generate a self-signed certificate, make the necessary configurations, and test the results. Self-signed certificates are great for testing, but will result in browser errors for your users, so they’re not recommended for production.

If you’d like to obtain a paid certificate instead, please see [this tutorial](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority).

## Prerequisites

To follow this tutorial, you will need:

- One fresh Debian 8 Droplet
- A sudo non-root user, which you can set up by following Steps 2 and 3 of [this tutorial](initial-server-setup-with-debian-8)
- OpenSSL installed and updated (should be installed by default)

    sudo apt-get update
    sudo apt-get upgrade openssl

You may want a second computer with OpenSSL installed, for testing purposes:

- Another Linux Droplet
- Or, a Unix-based local system (Mac, Ubuntu, Debian, etc.)

## Step 1 — Install Apache

In this step, we will use a built-in _package installer_ called `apt-get`. It simplifies package management drastically and facilitates a clean installation.

In the link specified in the prerequisites, you should have updated `apt-get` and installed the `sudo` package, as unlike other Linux distributions, Debian 8 does not come with `sudo` installed.

Apache will be our HTTPS server. To install it, run the following:

    sudo apt-get install apache2

## Step 2 — Enable the SSL Module

In this section, we will enable SSL on our server.

First, enable the Apache SSL module.

    sudo a2enmod ssl

The default Apache website comes with a useful template for enabling SSL, so we will activate the default website now.

    sudo a2ensite default-ssl

Restart Apache to put these changes into effect.

    sudo service apache2 reload

## Step 3 — Create a Self-Signed SSL Certificate

First, let’s create a new directory where we can store the private key and certificate.

    sudo mkdir /etc/apache2/ssl

Next, we will request a new certificate and sign it.

First, generate a new certificate and a private key to protect it.

- The `days` flag specifies how long the certificate should remain valid. With this example, the certificate will last for one year
- The `keyout` flag specifies the path to our generated key
- The `out` flag specifies the path to our generated certificate

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

Invoking this command will result in a series of prompts.

- **Common Name** : Specify your server’s IP address or hostname. This field matters, since your certificate needs to match the domain (or IP address) for your website
- Fill out all other fields at your own discretion.

Example answers are shown in red below.

    InteractiveYou are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    ——-
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:NYC
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
    Organizational Unit Name (eg, section) []:SSL Certificate Test
    Common Name (e.g. server FQDN or YOUR name) []:example.com               
    Email Address []:test@example.com

Set the file permissions to protect your private key and certificate.

    sudo chmod 600 /etc/apache2/ssl/*

For more information on the three-digit permissions code, see the tutorial on [Linux permissions](linux-permissions-basics-and-how-to-use-umask-on-a-vps).

Your certificate and the private key that protects it are now ready for Apache to use.

## Step 4 — Configure Apache to Use SSL

In this section, we will configure the default Apache virtual host to use the SSL key and certificate. After making this change, our server will begin serving HTTPS instead of HTTP requests for the default site.

Open the server configuration file using `nano` or your favorite text editor.

    sudo nano /etc/apache2/sites-enabled/default-ssl.conf

Locate the section that begins with `<VirtualHost _default_:443>` and make the following changes.

- Add a line with your server name directy below the `ServerAdmin` email line. This can be your domain name or IP address:

/etc/apache2/sites-enabled/default

    ServerAdmin webmaster@localhost
    ServerName example.com:443

- Find the following two lines, and update the paths to match the locations of the certificate and key we generated earlier. If you purchased a certificate or generated your certificate elsewhere, make sure the paths here match the actual locations of your certificate and key:

/etc/apache2/sites-enabled/default

     SSLCertificateFile /etc/apache2/ssl/apache.crt
     SSLCertificateKeyFile /etc/apache2/ssl/apache.key

Once these changes have been made, check that your virtual host configuration file matches the following.

/etc/apache2/sites-enabled/default-ssl

    <IfModule mod_ssl.c>
        <VirtualHost _default_:443>
            ServerAdmin webmaster@localhost
            ServerName example.com:443
            DocumentRoot /var/www/html
    
            . . .
            SSLEngine on
    
            . . .
    
            SSLCertificateFile /etc/apache2/ssl/apache.crt
            SSLCertificateKeyFile /etc/apache2/ssl/apache.key

Save and exit the file.

Restart Apache to apply the changes.

    sudo service apache2 reload

To learn more about configuring Apache virtual hosts in general, see [this article](how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts).

## Step 5 — Test Apache with SSL

In this section, we will test your SSL connection from the command line.

You can run this test from either (1) your local Unix-based system, (2) another Droplet, or (3) the same Droplet. If you run it from an external system you’ll confirm that your site is reachable over the public Internet.

Open a connection via the HTTPS 443 port.

    openssl s_client -connect your_server_ip:443

Scroll to the middle of the output (after the key), and you should find the following:

    Output—-
    SSL handshake has read 3999 bytes and written 444 bytes
    —-
    
    . . .
    
    SSL-Session:
    
    . . .

Of course, the numbers are variable, but this is success. Congratulations!

Press `CTRL+C` to exit.

You can also visit your site in a web browser, using HTTPS in the URL (`https://example.com`). Your browser will warn you that the certificate is self-signed. You should be able to view the certificate and confirm that the details match what you entered in Step 3.

## Conclusion

This concludes our tutorial, leaving you with a working Apache server, configured securely with an SSL certificate. For more information on working with OpenSSL, see [the OpenSSL Essentials article](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs).
