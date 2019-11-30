---
author: Mark Drake
date: 2018-07-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-letsencrypt-freebsd
---

# How To Secure Nginx with Let's Encrypt on FreeBSD

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is a Certificate Authority (CA) that provides an easy way to obtain and install free TLS/SSL certificates, thereby enabling encrypted HTTPS on web servers. It simplifies the process by providing a software client, Certbot, that automates most of the steps.

In this tutorial, we will show you how to use Certbot to obtain a free SSL certificate and use it on a FreeBSD server running Nginx. We will also show you how to automatically renew your SSL certificate.

We will use the default Nginx configuration file in this tutorial instead of a separate server block file. [We generally recommend](technical-recommendations-and-best-practices-for-digitalocean-s-tutorials#web-servers) creating new Nginx server block files for each domain because it helps to avoid some common mistakes and maintains the default files as a fallback configuration as intended.

## Prerequisites

In order to complete this tutorial, you’ll need:

- A FreeBSD server. If you’re new to working with FreeBSD 11, you can follow [this guide](how-to-get-started-with-freebsd-10-1) to help you get started.
- Nginx installed and configured on your server. For directions on how to set this up, see our guide on [How to Install Nginx on FreeBSD 11.2](how-to-install-nginx-freebsd-11-2).
- A registered domain name that you own and control. If you do not already have a registered domain name, you may register one with one of the many domain name registrars out there (e.g. Namecheap, GoDaddy, etc.).
- A DNS **A Record** that points your domain to the public IP address of your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them. This is required because of how Let’s Encrypt validates that you own the domain it’s issuing a certificate for. For example, if you want to obtain a certificate for `example.com`, that domain must resolve to your server for the validation process to work. Our setup will use `example.com` and `www.example.com` as the domain names, so **both DNS records are required**.

Once you’ve completed these prerequisites, let’s move on to installing Certbot, the Let’s Encrypt client software.

## Step 1 — Installing Certbot

The first step to using Let’s Encrypt to obtain an SSL certificate is to install the `certbot` client software on your server. The latest version of Certbot can be installed from source using FreeBSD’s [_ports system_](how-to-install-and-manage-ports-on-freebsd-10-1).

To begin, fetch a compressed snapshot of the ports tree:

    sudo portsnap fetch

It may take a few minutes for this command to complete. When it finishes, extract the snapshot:

    sudo portsnap extract

It may take a while for this command to finish, as well. Once it’s done, navigate to the `py-certbot` directory within the ports tree:

    cd /usr/ports/security/py-certbot

Then use the `make` command with `sudo` privileges to download and compile the Certbot source code:

    sudo make install clean

Next, navigate to the `py-certbot-nginx` directory within the ports tree:

    cd /usr/ports/security/py-certbot-nginx

Run the `make` command again from this directory. This will install the `nginx` plugin for Certbot which we’ll use to obtain the SSL certificates:

    sudo make install clean

During this plugin’s installation, you will see a couple of blue dialog windows pop up that look like this:

![py-certbot-nginx dialog window example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/letsencrypt_freebsd/py-nginx.png)

These give you the option to install documentation for the plugin and its dependencies. For the purposes of this tutorial, you can just press `ENTER` to accept the default options in these windows which will install this documentation.

The `certbot` Let’s Encrypt client is now ready to use. Before obtaining your certificates, though, it’s important to set up a firewall and allow HTTPS traffic through it, if you haven’t already done so.

## Step 2 — Setting Up a Firewall and Allowing HTTPS Access

If you’ve already set up a firewall on your server, you should ensure that it allows HTTPS access (via port `443`). If you haven’t already set up a firewall, you can do so by following the directions outlined in this step.

Open up your `rc.conf` file, which is located in the `/etc/` directory, with your preferred editor. Here we will use `ee`:

    sudo ee /etc/rc.conf

This file is used to inform FreeBSD which services should be started whenever the machine boots up. Near the top of the file, add the following highlighted lines:

/etc/rc.conf

    . . .
    nginx_enable="YES"
    firewall_enable="YES"
    firewall_type="workstation"
    firewall_myservices="22/tcp 80/tcp 443/tcp"
    firewall_allowservices="any"

Here’s what each of these directives and their settings do:

- `firewall_enable="YES"` — This enables the firewall to start up whenever the server boots.
- `firewall_type="workstation"` — FreeBSD provides several default types of firewalls, each of which have slightly different configurations. By declaring the `workstation` type, the firewall will only protect this server using stateful rules.
- `firewall_myservices="22/tcp 80/tcp 443/tcp"` — The `firewall_myservices` directive is where you can list the TCP ports you want to allow through the firewall. In this example, we’re specifying ports `22`, `80`, and `443` to allow SSH, HTTP, and HTTPS access to the server, respectively.
- `firewall_allowservices="any"` — This allows a machine from any IP address to communicate over the ports specified in the `firewall_myservices` directive.

After adding these lines, save the file and close the editor by pressing `CTRL + C`, typing `exit`, and then pressing `ENTER`.

Then, start the `ipfw` firewall service. Because this is the first time you’re starting the firewall on this server, there’s a chance that doing so will cause your server to stall, making it inaccessible over SSH. The following `nohup` command — which stands for “no hangups” — will start the firewall while preventing stalling and also redirect the standard output and error to a temporary log file:

    sudo nohup service ipfw start >/tmp/ipfw.log 2>&1

If you’re using `csh` or `tcsh`, though, this redirect will cause `Ambiguous output redirect.` to appear in your output. In this case, run the following instead to start `ipfw`:

    sudo nohup service ipfw start >&/tmp/ipfw.log

In the future, you can manage the `ipfw` firewall as you would any other service. For example, to stop, start, and then restart the service, you would run the following commands:

    sudo service ipfw stop
    sudo service ipfw start
    sudo service ipfw restart

With a firewall configured, you’re now ready to run Certbot and fetch your certificates.

## Step 3 — Obtaining an SSL Certificate

Certbot provides a variety of ways to obtain SSL certificates through various plugins. The `nginx` plugin will take care of reconfiguring Nginx and reloading the config file:

    sudo certbot --nginx -d example.com -d www.example.com

If this is your first time running `certbot` on this server, the client will prompt you to enter an email address and agree to the Let’s Encrypt terms of service. After doing so, `certbot` will communicate with the Let’s Encrypt server, then run a challenge to verify that you control the domain you’re requesting a certificate for.

If the challenge is successful, Certbot will ask how you’d like to configure your HTTPS settings:

    Output. . .
    Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel): 2

Select your choice then hit `ENTER`. This will update the configuration and reload Nginx to pick up the new settings. `certbot` will wrap up with a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /usr/local/etc/letsencrypt/live/example.com/fullchain.pem
       Your key file has been saved at:
       /usr/local/etc/letsencrypt/live/example.com/privkey.pem
       Your cert will expire on 2018-09-24. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot
       again. To non-interactively renew *all* of your certificates, run
       "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /usr/local/etc/letsencrypt. You should
       make a secure backup of this folder now. This configuration
       directory will also contain certificates and private keys obtained
       by Certbot so making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le

Your certificates are now downloaded, installed, and configured. Try reloading your website using `https://` and notice your browser’s security indicator. It should represent that the site is properly secured, usually with a green lock icon. If you test your server using the [SSL Labs Server Test](https://www.ssllabs.com/ssltest/), it will get an **A** grade.

After confirming that you’re able to reach your site over HTTPS, you can move onto the final step of this tutorial in which you’ll confirm that you can renew your certificates and then configure a process to renew them automatically.

## Step 4 — Verifying Certbot Auto-Renewal

Let’s Encrypt’s certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. This step describes how to automate certificate renewal by setting up a `cron` task. Before setting up this automatic renewal though, it’s important to test that you’re able to renew certificates correctly.

To test the renewal process, you can do a dry run with `certbot`:

    sudo certbot renew --dry-run

If you see no errors, you’re all set to create a new crontab:

    sudo crontab -e 

This will open a new `crontab` file. Add the following content to the new file, which will tell `cron` to run the `certbot renew` command twice every day at noon and midnight. `certbot renew` checks whether any certificates on the system are close to expiring and will attempt to renew them when necessary:

    0 0,12 * * * /usr/local/bin/certbot renew

Note that because you preceded the `crontab -e` command with `sudo`, this operation will be run as **root** , which is necessary because certbot requires superuser privileges to run.

If the automated renewal process ever fails, Let’s Encrypt will send a message to the email you specified, warning you when your certificate is about to expire.

## Conclusion

In this tutorial we’ve installed the Let’s Encrypt client `certbot`, downloaded SSL certificates for our domain, configured Nginx to use these certificates, and set up automatic certificate renewal. If you have further questions about using Certbot, [their documentation](https://certbot.eff.org/docs/) is a good place to start.
