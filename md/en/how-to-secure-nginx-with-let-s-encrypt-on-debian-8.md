---
author: Justin Ellingwood
date: 2016-12-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-8
---

# How To Secure Nginx with Let's Encrypt on Debian 8

## Introduction

Let’s Encrypt is a new Certificate Authority (CA) that provides an easy way to obtain and install free TLS/SSL certificates, thereby enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client, `certbot` (previously called `letsencrypt`), that attempts to automate most (if not all) of the required steps. Currently, the entire process of obtaining and installing a certificate is fully automated only on Apache web servers. However, Let’s Encrypt can be used to easily obtain a free SSL certificate, which can be installed manually, regardless of your choice of web server software.

In this tutorial, we will show you how to use Let’s Encrypt to obtain a free SSL certificate and use it with Nginx on Debian 8. We will also show you how to automatically renew your SSL certificate. If you’re running a different web server, simply follow your web server’s documentation to learn how to use the certificate with your setup.

![Nginx with Let's Encrypt TLS/SSL Certificate and Auto-renewal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/letsencrypt/nginx-letsencrypt.png)

## Prerequisites

Before following this tutorial, you’ll need a few things.

You should have a Debian 8 server with a non-root user who has `sudo` privileges. You can learn how to set up such a user account by following our [initial server setup for Debian 8 tutorial](initial-server-setup-with-debian-8).

If you haven’t installed Nginx on your server yet, do so by following [this guide](how-to-install-nginx-on-debian-8).

You must own or control the registered domain name that you wish to use the certificate with. If you do not already have a registered domain name, you may register one with one of the many domain name registrars out there (e.g. Namecheap, GoDaddy, etc.).

If you haven’t already, be sure to create an **A Record** that points your domain to the public IP address of your server (if you are using DigitalOcean’s DNS, you can follow [this guide](how-to-set-up-a-host-name-with-digitalocean)). This is required because of how Let’s Encrypt validates that you own the domain it is issuing a certificate for. For example, if you want to obtain a certificate for `example.com`, that domain must resolve to your server for the validation process to work. Our setup will use `example.com` and `www.example.com` as the domain names, so **both DNS records are required**.

Once you have all of the prerequisites out of the way, let’s move on to installing the Let’s Encrypt client software.

## Step 1: Install Certbot, the Let’s Encrypt Client

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the `certbot` Let’s Encrypt client on your server.

The `certbot` package was not available when Debian 8 was released. To access the `certbot` package, we will have to enable the Jessie backports repository on our server. This repository can be used to install more recent versions of software than the ones included in the stable repositories.

Add the backports repository to your server by typing:

    echo 'deb http://ftp.debian.org/debian jessie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list

After adding the new repository, update the `apt` package index to download information about the new packages:

    sudo apt-get update

Once the repository is updated, you can install the `certbot` package by targeting the backports repository:

**Note:** When using backports, it is recommended to only install the specific packages you require, rather than using the repository for general updates. Backport packages have fewer compatibility guarantees than the main repositories.

To help avoid accidentally installing or updating packages using this repository, you must explicitly pass the `-t` flag with the repository name to install packages from backports.

    sudo apt-get install certbot -t jessie-backports

The `certbot` client should now be ready to use.

## Step 2: Obtain an SSL Certificate

Let’s Encrypt provides a variety of ways to obtain SSL certificates, through various plugins. Unlike the Apache plugin, which is covered in [a different tutorial](how-to-secure-apache-with-let-s-encrypt-on-debian-8), most of the plugins will only help you with obtaining a certificate which you must manually configure your web server to use. Plugins that only obtain certificates, and don’t install them, are referred to as “authenticators” because they are used to authenticate whether a server should be issued a certificate.

We’ll show you how to use the **Webroot** plugin to obtain an SSL certificate.

### How To Use the Webroot Plugin

The Webroot plugin works by placing a special file in the `/.well-known` directory within your document root, which can be opened (through your web server) by the Let’s Encrypt service for validation. Depending on your configuration, you may need to explicitly allow access to the `/.well-known` directory.

If you haven’t installed Nginx yet, do so by following [this tutorial](how-to-install-nginx-on-debian-8). Continue below when you are finished.

To ensure that the directory is accessible to Let’s Encrypt for validation, let’s make a quick change to our Nginx configuration. By default, it’s located at `/etc/nginx/sites-available/default`. We’ll use `nano` to edit it:

    sudo nano /etc/nginx/sites-available/default

Inside the server block, add this location block:

Add to SSL server block

            location ~ /.well-known {
                    allow all;
            }

You will also want to look up what your document root is set to by searching for the `root` directive, as the path is required to use the Webroot plugin. If you’re using the default configuration file, the root will be `/var/www/html`.

Save and exit.

Check your configuration for syntax errors:

    sudo nginx -t

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If no errors are found, restart Nginx with this command:

    sudo systemctl restart nginx

Now that we know our `webroot-path`, we can use the Webroot plugin to request an SSL certificate with these commands. Here, we are also specifying our domain names with the `-d` option. If you want a single cert to work with multiple domain names (e.g. `example.com` and `www.example.com`), be sure to include all of them. Also, make sure that you replace the highlighted parts with the appropriate webroot path and domain name(s):

    sudo certbot certonly -a webroot --webroot-path=/var/www/html -d example.com -d www.example.com

After `certbot` initializes, you will be prompted to enter your email and agree to the Let’s Encrypt terms of service. Afterwards, the challenge will run. If everything was successful, you should see an output message that looks something like this:

    Output:IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at
       /etc/letsencrypt/live/example.com/fullchain.pem. Your cert
       will expire on 2017-09-05. To obtain a new or tweaked version of
       this certificate in the future, simply run certbot again. To
       non-interactively renew *all* of your certificates, run "certbot
       renew"
     - If you lose your account credentials, you can recover through
       e-mails sent to sammy@example.com.
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le

You will want to note the path and expiration date of your certificate, which was highlighted in the example output.

**Firewall Note:** If you receive an error like `Failed to connect to host for DVSNI challenge`, your server’s firewall may need to be configured to allow TCP traffic on port `80` and `443`.

**Note:** If your domain is routing through a DNS service like CloudFlare, you will need to temporarily disable it until you have obtained the certificate.

### Certificate Files

After obtaining the cert, you will have the following PEM-encoded files:

- **cert.pem:** Your domain’s certificate
- **chain.pem:** The Let’s Encrypt chain certificate
- **fullchain.pem:** `cert.pem` and `chain.pem` combined
- **privkey.pem:** Your certificate’s private key

It’s important that you are aware of the location of the certificate files that were just created, so you can use them in your web server configuration. The files themselves are placed in a subdirectory in `/etc/letsencrypt/archive`. However, Let’s Encrypt creates symbolic links to the most recent certificate files in the `/etc/letsencrypt/live/your_domain_name` directory. Because the links will always point to the most recent certificate files, this is the path that you should use to refer to your certificate files.

You can check that the files exist by running this command (substituting in your domain name):

    sudo ls -l /etc/letsencrypt/live/your_domain_name

The output should be the four previously mentioned certificate files. In a moment, you will configure your web server to use `fullchain.pem` as the certificate file, and `privkey.pem` as the certificate key file.

### Generate Strong Diffie-Hellman Group

To further increase security, you should also generate a strong Diffie-Hellman group. To generate a 2048-bit group, use this command:

    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

This may take a few minutes but when it’s done you will have a strong DH group at `/etc/ssl/certs/dhparam.pem`.

## Step 3: Configure TLS/SSL on Web Server (Nginx)

Now that you have an SSL certificate, you need to configure your Nginx web server to use it.

We will make a few adjustments to our configuration:

1. We will create a configuration snippet containing our SSL key and certificate file locations.
2. We will create a configuration snippet containing strong SSL settings that can be used with any certificates in the future.
3. We will adjust the Nginx server blocks to handle SSL requests and use the two snippets above.

This method of configuring Nginx will allow us to keep clean server blocks and put common configuration segments into reusable modules.

### Create a Configuration Snippet Pointing to the SSL Key and Certificate

First, let’s create a new Nginx configuration snippet in the `/etc/nginx/snippets` directory.

To properly distinguish the purpose of this file, we will name it `ssl-` followed by our domain name, followed by `.conf` on the end:

    sudo nano /etc/nginx/snippets/ssl-example.com.conf

Within this file, we just need to set the `ssl_certificate` directive to our certificate file and the `ssl_certificate_key` to the associated key. In our case, this will look like this:

/etc/nginx/snippets/ssl-example.com.conf

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

When you’ve added those lines, save and close the file.

### Create a Configuration Snippet with Strong Encryption Settings

Next, we will create another snippet that will define some SSL settings. This will set Nginx up with a strong SSL cipher suite and enable some advanced features that will help keep our server secure.

The parameters we will set can be reused in future Nginx configurations, so we will give the file a generic name:

    sudo nano /etc/nginx/snippets/ssl-params.conf

To set up Nginx SSL securely, we will be using the recommendations by [Remy van Elst](https://raymii.org/s/static/About.html) on the [Cipherli.st](https://cipherli.st) site. This site is designed to provide easy-to-consume encryption settings for popular software. You can read more about his decisions regarding the Nginx choices [here](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html).

**Note:** The default suggested settings on [Cipherli.st](https://cipherli.st) offer strong security. Sometimes, this comes at the cost of greater client compatibility. If you need to support older clients, there is an alternative list that can be accessed by clicking the link on the link labeled “Yes, give me a ciphersuite that works with legacy / old software.”

The compatibility list can be used instead of the default suggestions in the configuration below. The choice of which config you use will depend largely on what you need to support.

For our purposes, we can copy the provided settings in their entirety. We just need to make a few small modifications.

First, we will add our preferred DNS resolver for upstream requests. We will use Google’s for this guide. We will also go ahead and set the `ssl_dhparam` setting to point to the Diffie-Hellman file we generated earlier.

Finally, you should take take a moment to read up on [HTTP Strict Transport Security, or HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), and specifically about the [“preload” functionality](https://hstspreload.appspot.com/). Preloading HSTS provides increased security, but can have far reaching consequences if accidentally enabled or enabled incorrectly. In this guide, we will not preload the settings, but you can modify that if you are sure you understand the implications:

/etc/nginx/snippets/ssl-params.conf

    # from https://cipherli.st/
    # and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable preloading HSTS for now. You can use the commented out header line that includes
    # the "preload" directive if you understand the implications.
    #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

Save and close the file when you are finished.

### Adjust the Nginx Configuration to Use SSL

Now that we have our snippets, we can adjust our Nginx configuration to enable SSL.

We will assume in this guide that you are using the `default` server block file in the `/etc/nginx/sites-available` directory. If you are using a different server block file, substitute its name in the below commands.

Before we go any further, let’s back up our current server block file:

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

Now, open the server block file to make adjustments:

    sudo nano /etc/nginx/sites-available/default

Inside, your server block probably begins like this:

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        # SSL configuration
    
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
    
        . . .

We will be modifying this configuration so that unencrypted HTTP requests are automatically redirected to encrypted HTTPS. This offers the best security for our sites. If you want to allow both HTTP and HTTPS traffic, use the alternative configuration that follows.

We will be splitting the configuration into two separate blocks. After the two first `listen` directives, we will add a `server_name` directive, set to your server’s domain name. We will then set up a redirect to the second server block we will be creating. Afterwards, we will close this short block:

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name example.com www.example.com;
        return 301 https://$server_name$request_uri;
    }
    
        # SSL configuration
    
        # listen 443 ssl default_server;
        # listen [::]:443 ssl default_server;
    
        . . .

Next, we need to start a new server block directly below to contain the remaining configuration. We can uncomment the two `listen` directives that use port 443. Afterwards, we just need to include the two snippet files we set up:

**Note:** You may only have **one** `listen` directive that includes the `default_server` modifier for each IP version and port combination. If you have other server blocks enabled for these ports that have `default_server` set, you must remove the modifier from one of the blocks.

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name example.com www.example.com;
        return 301 https://$server_name$request_uri;
    }
    
    server {
    
        # SSL configuration
    
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        include snippets/ssl-example.com.conf;
        include snippets/ssl-params.conf;
    
        . . .

Save and close the file when you are finished.

### (Alternative Configuration) Allow Both HTTP and HTTPS Traffic

If you want or need to allow both encrypted and unencrypted content, you will have to configure Nginx a bit differently. This is generally not recommended if it can be avoided, but in some situations it may be necessary. Basically, we just compress the two separate server blocks into one block and remove the redirect:

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
    
        server_name example.com www.example.com;
        include snippets/ssl-example.com.conf;
        include snippets/ssl-params.conf;
    
        . . .

Save and close the file when you are finished.

## Step 4: Adjust the Firewall

If you have a firewall enabled, you’ll need to adjust the settings to allow for SSL traffic. The required procedure depends on the firewall software you are using. If you do not have a firewall configured currently, feel free to skip forward.

### UFW

If you are using **ufw** , you can see the current setting by typing:

    sudo ufw status

It will probably look like this, meaning that only HTTP traffic is allowed to the web server:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    SSH ALLOW Anywhere
    WWW ALLOW Anywhere
    SSH (v6) ALLOW Anywhere (v6)
    WWW (v6) ALLOW Anywhere (v6)

To additionally let in HTTPS traffic, we can allow the “WWW Full” profile and then delete the redundant “WWW” profile allowance:

    sudo ufw allow 'WWW Full'
    sudo ufw delete allow 'WWW'

Your status should look like this now:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    SSH ALLOW Anywhere
    WWW Full ALLOW Anywhere
    SSH (v6) ALLOW Anywhere (v6)
    WWW Full (v6) ALLOW Anywhere (v6)

HTTPS requests should now be accepted by your server.

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

    sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT

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

## Step 5: Enabling the Changes in Nginx

Now that we’ve made our changes and adjusted our firewall, we can restart Nginx to implement our new changes.

First, we should check to make sure that there are no syntax errors in our files. We can do this by typing:

    sudo nginx -t

If everything is successful, you will get a result that looks like this:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If your output matches the above, your configuration file has no syntax errors. We can safely restart Nginx to implement our changes:

    sudo systemctl restart nginx

The Let’s Encrypt TLS/SSL certificate is now in place and the firewall now allows traffic to port 80 and 443. At this point, you should test that the TLS/SSL certificate works by visiting your domain via HTTPS in a web browser.

You can use the Qualys SSL Labs Report to see how your server configuration scores:

    In a web browser:https://www.ssllabs.com/ssltest/analyze.html?d=example.com

This may take a few minutes to complete. The SSL setup in this guide should report at least an **A** rating.

## Step 6: Set Up Auto Renewal

Let’s Encrypt certificates are valid for 90 days, but it’s recommended that you renew the certificates every 60 days to allow a margin of error. At the time of this writing, automatic renewal is still not available as a feature of the client itself, but you can manually renew your certificates by running the Let’s Encrypt client with the `renew` option.

To trigger the renewal process for all installed domains, run this command:

    sudo certbot renew

Because we recently installed the certificate, the command will only check for the expiration date and print a message informing that the certificate is not due to renewal yet. The output should look similar to this:

    Output:Saving debug log to /var/log/letsencrypt/example.com.log
    
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

If this is your first time using `crontab`, you may be asked to select your preferred text editor. If you have no strong preference, **nano** is an easy choice.

Add the following lines:

    crontab entry30 2 * * * /usr/bin/certbot renew --noninteractive --renew-hook "/bin/systemctl reload nginx" >> /var/log/le-renew.log

Save and exit. This will create a new cron job that will execute the `certbot renew` command every day at 2:30 am, and reload Nginx if a certificate is renewed. The output produced by the command will be piped to a log file located at `/var/log/le-renewal.log`.

**Note:** For more information on how to create and schedule cron jobs, you can check our [How to Use Cron to Automate Tasks in a VPS](how-to-use-cron-to-automate-tasks-on-a-vps) guide.

## Conclusion

That’s it! Your web server is now using a free Let’s Encrypt TLS/SSL certificate to securely serve HTTPS content.
