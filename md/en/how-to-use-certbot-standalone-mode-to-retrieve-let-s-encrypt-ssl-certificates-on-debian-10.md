---
author: Brian Boucheron, Kathleen Juell, Hanif Jetha
date: 2019-07-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates-on-debian-10
---

# How To Use Certbot Standalone Mode to Retrieve Let's Encrypt SSL Certificates on Debian 10

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is a service that offers free SSL certificates through an automated API. The most popular Let’s Encrypt client is [EFF](https://www.eff.org/)’s [Certbot](https://certbot.eff.org/) client.

Certbot offers a variety of ways to validate your domain, fetch certificates, and automatically configure [Apache](https://httpd.apache.org/) and [Nginx](https://www.nginx.com/). In this tutorial, we’ll discuss Certbot’s [_standalone_ mode](https://certbot.eff.org/docs/using.html#standalone) and how to use it to secure other types of services, such as a mail server or a message broker like [RabbitMQ](https://www.rabbitmq.com/).

We won’t discuss the details of SSL configuration, but when you are done you will have a valid certificate that is automatically renewed. Additionally, you will be able to automate reloading your service to pick up the renewed certificate.

## Prerequisites

Before starting this tutorial, you will need:

- A Debian 10 server, a non-root user with `sudo` privileges, and a basic firewall, as detailed in [this Debian 10 server setup tutorial](initial-server-setup-with-debian-10).
- A domain name pointed at your server, which you can accomplish by following this [documentation](https://www.digitalocean.com/docs/networking/dns/) on creating DNS records on DigitalOcean. 
- Port `80` **or** `443` must be **unused** on your server. If the service you’re trying to secure is on a machine with a web server that occupies both of those ports, you’ll need to use a different mode such as Certbot’s [_webroot_ mode](https://certbot.eff.org/docs/using.html#webroot) or DNS-based challenge mode.

## Step 1 — Installing Certbot

Debian 10 includes the Certbot client in their default repository, and it should be up-to-date enough for basic use. If you need to do DNS-based challenges or use other newer Certbot features, you should instead install from the `buster-backports` repo as instructed by [the official Certbot documentation](https://certbot.eff.org/lets-encrypt/debianstretch-other).

Update your package list:

    sudo apt update

Use `apt` to install the `certbot` package:

    sudo apt install certbot

You can test your installation by asking `certbot` to output its version number:

    certbot --version

    Outputcertbot 0.31.0

Now that we have Certbot installed, let’s run it to get our certificate.

## Step 2 — Running Certbot

Certbot needs to answer a cryptographic challenge issued by the Let’s Encrypt API in order to prove we control our domain. It uses ports `80` (HTTP) or `443` (HTTPS) to accomplish this. Open up the appropriate port in your firewall:

    sudo ufw allow 80

Substitute `443` above if that’s the port you’re using. `ufw` will output confirmation that your rule was added:

    OutputRule added
    Rule added (v6)

We can now run Certbot to get our certificate. We’ll use the `--standalone` option to tell Certbot to handle the challenge using its own built-in web server. The `--preferred-challenges` option instructs Certbot to use port `80` or port `443`. If you’re using port `80`, you will use the `--preferred-challenges http` option. For port `443`, use `--preferred-challenges tls-sni`. Finally, we’ll use the `-d` flag to specify the domain we’re requesting a certificate for. You can add multiple `-d` options to cover multiple domains in one certificate.

We will use the `--preferred-challenges http` option to demonstrate, but you should use the option that makes sense for your use case. Run the following command with your preferred options to get your certificate:

    sudo certbot certonly --standalone --preferred-challenges http -d your_domain

When running the command, you will be prompted to enter an email address and agree to the terms of service. After doing so, you should see a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/your_domain/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/your_domain/privkey.pem
       Your cert will expire on 2019-08-28. To obtain a new or tweaked
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

We’ve got our certificates. Let’s take a look at what we downloaded and how to use the files with our software.

## Step 3 — Configuring Your Application

Configuring your application for SSL is beyond the scope of this article, as each application has different requirements and configuration options, but let’s take a look at what Certbot has downloaded for us. Use `ls` to list out the directory that holds your keys and certificates:

    sudo ls /etc/letsencrypt/live/your_domain

You will see the following output:

    Outputcert.pem chain.pem fullchain.pem privkey.pem README

The `README` file in this directory has more information about each of these files. Most often you’ll only need two of these files:

- `privkey.pem`: This is the private key for the certificate. This needs to be kept safe and secret, which is why most of the `/etc/letsencrypt` directory has very restrictive permissions and is accessible by only the **root** user. Most software configuration will refer to this as `ssl-certificate-key` or `ssl-certificate-key-file`.
- `fullchain.pem`: This is our certificate, bundled with all intermediate certificates. Most software will use this file for the actual certificate, and will refer to it in their configuration with a name like `ssl-certificate`.

For more information on the other files present, refer to the [Where are my certificates?](https://certbot.eff.org/docs/using.html#where-are-my-certificates) section of the Certbot docs.

Some software will need its certificates in other formats or locations, or with other user permissions. It is best to leave everything in the `letsencrypt` directory, and not change any permissions there (permissions will just be overwritten upon renewal anyway), but sometimes that’s not an option. In that case, you’ll need to write a script to move files and change permissions as needed. This script will need to be run whenever Certbot renews the certificates, which we’ll talk about next.

## Step 4 — Handling Certbot Automatic Renewals

Let’s Encrypt certificates are only valid for ninety days. This is to encourage users to automate the certificate renewal process. The `certbot` package we installed takes care of this for us by adding a renew script to `/etc/cron.d`. This script runs twice a day and will renew any certificate that’s within thirty days of expiring.

With our certificates renewing automatically, we still need a way to run other tasks after a renewal. We need to at least restart or reload our server to pick up the new certificates, and as mentioned in Step 3 we may need to manipulate the certificate files in some way to make them work with the software we’re using. This is the purpose of Certbot’s [`renew_hook`](https://certbot.eff.org/docs/api/hooks.html?highlight=renew_hook#certbot.hooks.renew_hook) option.

To add a `renew_hook`, we need to update Certbot’s renewal config file. Certbot remembers all the details of how you first fetched the certificate, and will run with the same options upon renewal. We just need to add in our hook. Open the config file with your favorite editor:

    sudo nano /etc/letsencrypt/renewal/your_domain.conf

A text file will open with some configuration options. Add your hook on the last line. In this case, we’re using an example that would reload a `rabbitmq` service:

/etc/letsencrypt/renewal/your\_domain.conf

    renew_hook = systemctl reload rabbitmq

Update the command above to whatever you need to run to reload your server or run your custom file munging script. On Debian, you’ll usually use `systemctl` to reload a service.

Save and close the file, then run a Certbot dry run to make sure the syntax is ok:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. Certbot is set to renew when necessary and run any commands needed to get your service using the new files.

## Conclusion

In this tutorial, we’ve installed the Certbot Let’s Encrypt client, downloaded an SSL certificate using standalone mode, and enabled automatic renewals with renew hooks. This should give you a good start on using Let’s Encrypt certificates with services other than your typical web server.

For more information, please refer to [Certbot’s documentation](https://certbot.eff.org/docs/).
