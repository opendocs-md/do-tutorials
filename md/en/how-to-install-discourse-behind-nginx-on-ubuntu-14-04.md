---
author: Jonah Aragon
date: 2016-04-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-discourse-behind-nginx-on-ubuntu-14-04
---

# How To Install Discourse Behind Nginx on Ubuntu 14.04

## Introduction

[Discourse](http://www.discourse.org) is an open source community discussion platform built for the modern web.

This tutorial will walk you through the steps of configuring Discourse, moving it behind a reverse proxy with Nginx, and configuring an SSL certificate for it with [Let’s Encrypt](https://letsencrypt.org/). Moving Discourse behind a reserve proxy provides you with the flexibility to run other websites on your Droplet.

## Prerequisites

Before we get started, be sure you have the following:

- Ubuntu 14.04 Droplet (1 GB or bigger)
- Non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)
- Discourse installed using [this tutorial](how-to-install-discourse-on-ubuntu-14-04)
- Fully registered domain. You can purchase one on [Namecheap](https://namecheap.com) or get one for free on [Freenom](http://www.freenom.com/en/index.html).
- Make sure your domain name is configured to point to your Droplet. Check out [this tutorial](how-to-set-up-a-host-name-with-digitalocean) if you need help.

All the commands in this tutorial should be run as a non-root user. If root access is required for the command, it will be preceded by `sudo`.

## Step 1 — Configuring Discourse

Now that you have Discourse installed, we need to configure it to work behind Nginx.

**Warning** : This will incur downtime on your Discourse forum until we configure Nginx. Make sure this is a fresh install of Discourse or have a backup server until configuration is complete.

There’s just one setting we’ll need to change to Discourse so we can move it behind Nginx. Change into the directory that contains the configuration file:

    cd /var/discourse

Then, open the configuration file we need to change:

    sudo nano containers/app.yml

Using the arrow keys, scroll down to the `expose` section (it should be near the top) and change the first port number on this line:

/var/discourse/containers/app.yml

    ...
    ## which TCP/IP ports should this container expose?
    expose:
      - "25654:80" # fwd host port 80 to container port 80 (http)
    ...

This number can be random and shouldn’t be shared with others. You can even block unauthorized access to it [with an iptables firewall rule](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04) if you’d like.

Now save and exit the text editor.

Enable the configuration change by running:

    sudo ./launcher rebuild app

This step might take a while, so please be patient.

You can verify everything is working by visiting your website. Your domain name for Discourse (such as `http://discourse.example.com`) will no longer load the interface in a web browser, but it should be accessible if you use the port just configured for Discourse such as `http:///discourse.example.com:25654` (replace discourse.example.com with your domain name and 25654 with the port you just used in this step).

## Step 2 — Installing and Configuring Nginx

Now that Discourse is installed and configured to work behind Nginx, it is time to install Nginx.

To install Nginx on Ubuntu, simply enter this command and the installation will start:

    sudo apt-get install nginx

Browsing to your old Discourse URL at `http://discourse.example.com` will show the default Nginx webpage:

![Default Nginx landing page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/discouse_behind_nginx/default-webpage.png)

This is fine. We’ll change this to your forum now. First, let’s stop Nginx:

    sudo service nginx stop

Then, delete this default webpage configuration — we won’t need it:

    sudo rm /etc/nginx/sites-enabled/default

Next, we’ll make a new configuration file for our Discourse server, which we’ll name `discourse`.

    sudo nano /etc/nginx/sites-enabled/discourse

Copy and paste in the following configuration. Replace `discourse.example.com` with your domain name and `25654` with the port you just used in the previous step:

/etc/nginx/sites-enabled/discourse

    server {
            listen 80;
            server_name discourse.example.com;
            return 301 https://discourse.example.com$request_uri;
    }
    server {
            listen 443 ssl spdy; 
            server_name discourse.example.com;
            ssl_certificate /etc/letsencrypt/live/discourse.example.com/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/discourse.example.com/privkey.pem;
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
            ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
            ssl_prefer_server_ciphers on;
            location / {
                    proxy_pass http://discourse.example.com:25654/;
                    proxy_read_timeout 90;
                    proxy_redirect http://discourse.example.com:25654/ https://discourse.example.com;
            }
    }

Here’s what this config does:

- The first server block is listening on the `discourse.example.com` domain on port 80, and it redirects all requests to SSL on port 443. This is optional, but it forces SSL on your website for all users.
- The second server block is on port 443 and is passing requests to the web server running on port `25654` (in this case, Discourse). This essentially uses a reverse proxy to send Discourse pages to your users and back over SSL.

You may have noticed we’re referencing some certificates at `/etc/letsencrypt`. In the next step we’ll generate those before restarting Nginx.

## Step 3 — Generating the SSL Certificates

To generate the SSL certificates, we will first install the Let’s Encrypt’s ACME client. This software allows us to generate SSL certificates.

    sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

Then go to the `letsencrypt` directory:

    cd /opt/letsencrypt/

Install the packages required by Let’s Encrypt the first time:

    ./letsencrypt-auto --help

Now we can generate your certificates by running (replace with your email address and domain name):

    ./letsencrypt-auto certonly --standalone --email sammy@example.com --agree-tos -d discourse.example.com

**Note:** Let’s Encrypt will only issue certificates for domain names. You will get an error if you try to use an IP address. If you need a domain name, check out the links in the Prerequisites section.

You should get a response fairly quickly, similar to this:

Let’s Encrypt Output

    IMPORTANT NOTES:
     - If you lose your account credentials, you can recover through
       e-mails sent to sammy@example.com.
     - Congratulations! Your certificate and chain have been saved at
       /etc/letsencrypt/live/discourse.example.com/fullchain.pem. Your
       cert will expire on 2016-04-26. To obtain a new version of the
       certificate in the future, simply run Let's Encrypt again.
     - Your account credentials have been saved in your Let's Encrypt
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Let's
       Encrypt so making regular backups of this folder is ideal.

You’ll notice it said your certificates were saved in `/etc/letsencrypt/live/discourse.example.com`. This means our Nginx config is now valid. You’ll also notice that expiration date isn’t too far away. This is normal with Let’s Encrypt certificates. All you have to do to renew is run that exact same command again, but logging in every 90 days isn’t fun, so we’ll automate it in our next step.

## Step 4 — Automating the Let’s Encrypt Certificate Renewal

Now that we’ve set up our certificates for the first time, we should make sure they renew automatically. Let’s Encrypt certificates are only valid for 90 days, after which they will expire and display a warning to all visitors to your site in the browser. At the time of writing auto-renewal is not built into the client, but we can set up a script to manually renew them.

Refer to the [Set Up Auto Renewal](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04#step-4-%E2%80%94-set-up-auto-renewal) step of [How To Secure Nginx with Let’s Encrypt on Ubuntu 14.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-14-04) for details on setting up a cron job to renew your certificate automatically.

Any output created by this command will be at `/var/log/certificate-renewal.log` for troubleshooting.

## Step 5 — Restarting Nginx

Finally, our configuration should be complete. Restart Nginx by running this command:

    sudo service nginx restart

Now if you browse to `https://discourse.example.com/` your website should be online and secured with Let’s Encrypt, shown as a green lock in most browsers.

## Conclusion

That’s it! You now have a Discourse forum set up behind Nginx, secured with the latest SSL standards with Let’s Encrypt.
