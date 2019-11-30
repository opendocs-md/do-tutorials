---
author: Vadym Kalsin, Erika Heidi
date: 2016-01-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-centos-7
---

# How To Secure Apache with Let's Encrypt on CentOS 7

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is a Certificate Authority (CA) that provides free certificates for [Transport Layer Security (TLS) encryption](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), thereby enabling encrypted HTTPS on web servers. It simplifies the process of creation, validation, signing, installation, and renewal of certificates by providing a software client that automates most of the steps—[Certbot](https://certbot.eff.org/).

In this tutorial, you will use Certbot to set up a TLS/SSL certificate from Let’s Encrypt on a CentOS 7 server running Apache as a web server. Additionally, you will automate the certificate renewal process using a cron job, which you can learn more about by reading [How To Use Cron To Automate Tasks On a VPS](how-to-use-cron-to-automate-tasks-on-a-vps).

## Prerequisites

In order to complete this guide, you will need:

- One CentOS 7 server set up by following [the CentOS 7 initial server setup guide](initial-server-setup-with-centos-7) with a non-root user who has `sudo` privileges.
- A basic firewall configured by following the [Additional Recommended Steps for New CentOS 7 Servers](additional-recommended-steps-for-new-centos-7-servers#configuring-a-basic-firewall) guide.
- Apache installed on the CentOS 7 server with a virtual host configured. You can learn how to set this up by following our tutorial [How To Install the Apache Web Server on CentOS 7](how-to-install-the-apache-web-server-on-centos-7). Be sure that you have a [virtual host file](how-to-install-the-apache-web-server-on-centos-7#step-4-%E2%80%94-setting-up-virtual-hosts-(recommended)) for your domain. This tutorial will use `/etc/httpd/sites-available/example.com.conf` as an example.
- You should own or control the registered domain name that you wish to use the certificate with. If you do not already have a registered domain name, you may purchase one on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.
- A DNS **A Record** that points your domain to the public IP address of your server. You can follow [this introduction to DigitalOcean DNS](an-introduction-to-digitalocean-dns) for details on how to add them with the DigitalOcean platform. DNS A records are required because of how Let’s Encrypt validates that you own the domain it is issuing a certificate for. For example, if you want to obtain a certificate for `example.com`, that domain must resolve to your server for the validation process to work. Our setup will use `example.com` and `www.example.com` as the domain names, both of which will require a valid DNS record.

When you have all of these prerequisites completed, move on to install the Let’s Encrypt client software.

## Step 1 — Installing the Certbot Let’s Encrypt Client

To use Let’s Encrypt to obtain an SSL certificate, you first need to install Certbot and [`mod_ssl`](https://httpd.apache.org/docs/2.4/mod/mod_ssl.html), an Apache module that provides support for SSL v3 encryption.

The `certbot` package is not available through the package manager by default. You will need to enable the [EPEL](https://fedoraproject.org/wiki/EPEL) repository to install Certbot.

To add the CentOS 7 EPEL repository, run the following command:

    sudo yum install epel-release

Now that you have access to the repository, install all of the required packages:

    sudo yum install certbot python2-certbot-apache mod_ssl

During the installation process you will be asked about importing a GPG key. This key will verify the authenticity of the package you are installing. To allow the installation to finish, accept the GPG key by typing `y` and pressing `ENTER` when prompted to do so.

With these services installed, you’re now ready to run Certbot and fetch your certificates.

## Step 2 — Obtaining a Certificate

Now that Certbot is installed, you can use it to request an SSL certificate for your domain.

Using the `certbot` Let’s Encrypt client to generate the SSL Certificate for Apache automates many of the steps in the process. The client will automatically obtain and install a new SSL certificate that is valid for the domains you provide as parameters.

To execute the interactive installation and obtain a certificate that covers only a single domain, run the `certbot` command with:

    sudo certbot --apache -d example.com

This runs `certbot` with the `--apache` plugin and specifies the domain to configure the certificate for with the `-d` flag.

If you want to install a single certificate that is valid for multiple domains or subdomains, you can pass them as additional parameters to the command, tagging each new domain or subdomain with the `-d` flag. The first domain name in the list of parameters will be the **base** domain used by Let’s Encrypt to create the certificate. For this reason, pass the base domain name as first in the list, followed by any additional subdomains or aliases:

    sudo certbot --apache -d example.com -d www.example.com

The base domain in this example is `example.com`.

The `certbot` utility can also prompt you for domain information during the certificate request procedure. To use this functionality, call `certbot` without any domains:

    sudo certbot --apache

The program will present you with a step-by-step guide to customize your certificate options. It will ask you to provide an email address for lost key recovery and notices, and then prompt you to agree to the terms of service. If you did not specify your domains on the command line, you will be prompted for that as well. If your Virtual Host files do not specify the domain they serve explicitly using the `ServerName` directive, you will be asked to choose the virtual host file. In most cases, the default `ssl.conf` file will work.

You will also be able to choose between enabling both `http` and `https` access or forcing all requests to redirect to `https`. For better security, it is recommended to choose the option `2: Redirect` if you do not have any special need to allow unencrypted connections. Select your choice then hit `ENTER`.

    OutputPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):2

When the installation is successfully finished, you will see a message similar to this:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/example.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/example.com/privkey.pem
       Your cert will expire on 2019-08-14. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot again
       with the "certonly" option. To non-interactively renew *all* of
       your certificates, run "certbot renew"
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le
    

The generated certificate files will be available within a subdirectory named after your base domain in the `/etc/letsencrypt/live` directory.

Now that your certificates are downloaded, installed, and loaded, you can check your SSL certificate status to make sure that everything is working.

## Step 3 — Checking your Certificate Status

At this point, you can ensure that Certbot created your SSL certificate correctly by using the [SSL Server Test](https://www.ssllabs.com/ssltest/) from the cloud security company [Qualys](https://www.qualys.com/).

Open the following link in your preferred web browser, replacing `example.com` with your **base** domain:

    https://www.ssllabs.com/ssltest/analyze.html?d=example.com

You will land on a page that immediately begins testing the SSL connection to your server:

![SSL Server Test](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/LE_CentOS7_66505/SSL_Server_Test.png)

Once the test starts running, it may take a few minutes to complete. The status of the test will update in your browser.

When the testing finishes, the page will display a letter grade that rates the security and quality of your server’s configuration. At the time of this writing, default settings will give an **A** rating:

![SSL Report - A](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/LE_CentOS7_66505/SSL_Report_A.png)

For more information about how SSL Labs determines these grades, check out the [SSL Labs Grading post](https://community.qualys.com/docs/DOC-6321-ssl-labs-grading-2018) detailing the updates made to the grading scheme in January, 2018.

Try reloading your website using `https://` and notice your browser’s security indicator. It will now indicate that the site is properly secured, usually with a green lock icon.

With your SSL certificate up and verified, the next step is to set up auto-renewal for your certificate to keep your certificate valid.

## Step 4 — Setting Up Auto Renewal

Let’s Encrypt certificates are valid for 90 days, but it’s recommended that you renew the certificates every 60 days to allow a margin of error. Because of this, it is a best practice to automate this process to periodically check and renew the certificate.

First, let’s examine the command that you will use to renew the certificate. The `certbot` Let’s Encrypt client has a `renew` command that automatically checks the currently installed certificates and tries to renew them if they are less than 30 days away from the expiration date. By using the `--dry-run` option, you can run a simulation of this task to test how `renew` works:

    sudo certbot renew --dry-run

The output should look similar to this:

    OutputSaving debug log to /var/log/letsencrypt/letsencrypt.log
    
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Processing /etc/letsencrypt/renewal/example.com.conf
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Cert not due for renewal, but simulating renewal for dry run
    Plugins selected: Authenticator apache, Installer apache
    Starting new HTTPS connection (1): acme-staging-v02.api.letsencrypt.org
    Renewing an existing certificate
    Performing the following challenges:
    http-01 challenge for example.com
    http-01 challenge for www.example.com
    Waiting for verification...
    Cleaning up challenges
    Resetting dropped connection: acme-staging-v02.api.letsencrypt.org
    
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    new certificate deployed with reload of apache server; fullchain is
    /etc/letsencrypt/live/example.com/fullchain.pem
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ** DRY RUN: simulating 'certbot renew' close to cert expiry
    ** (The test certificates below have not been saved.)
    
    Congratulations, all renewals succeeded. The following certs have been renewed:
      /etc/letsencrypt/live/example.com/fullchain.pem (success)
    ...

Notice that if you created a bundled certificate with multiple domains, only the base domain name will be shown in the output, but the renewal will be valid for all domains included in this certificate.

A practical way to ensure your certificates will not get outdated is to create a [cron job](how-to-use-cron-to-automate-tasks-on-a-vps) that will periodically execute the automatic renewal command for you. Since the renewal first checks for the expiration date and only executes the renewal if the certificate is less than 30 days away from expiration, it is safe to create a cron job that runs every week or even every day.

The [official Certbot documentation](https://certbot.eff.org/lets-encrypt/centosrhel7-apache) recommends running `cron` twice per day. This will ensure that, in case Let’s Encrypt initiates a certificate revocation, there will be no more than half a day before Certbot renews your certificate.

Edit the `crontab` to create a new job that will run the renewal twice per day. To edit the `crontab` for the **root** user, run:

    sudo crontab -e

Your text editor will open the default `crontab` which is an empty text file at this point. This tutorial will use the vi text editor. To learn more about this text editor and its successor _vim_, check out our [Installing and Using the Vim Text Editor on a Cloud Server](installing-and-using-the-vim-text-editor-on-a-cloud-server#managing-documents) tutorial.

Enter insert mode by pressing `i` and add in the following line:

    crontab0 0,12 * * * python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew

When you’re finished, press `ESC` to leave insert mode, then `:wq` and `ENTER` to save and exit the file. This will create a new cron job that will execute at noon and midnight every day. Adding an element of randomness to your cron jobs will ensure that hourly jobs do not all happen at the same minute, causing a server spike; `python -c 'import random; import time; time.sleep(random.random() * 3600)'` will select a random minute within the hour for your renewal tasks.

For more information on how to create and schedule cron jobs, you can check our [How to Use Cron to Automate Tasks in a VPS](how-to-use-cron-to-automate-tasks-on-a-vps) guide. More detailed information about renewal can be found in the [Certbot documentation](https://certbot.eff.org/docs/using.html#renewal).

## Conclusion

In this guide you installed the Let’s Encrypt Certbot client, downloaded SSL certificates for your domain, and set up automatic certificate renewal. If you have any questions about using Certbot, you can check the official [Certbot documentation](https://certbot.eff.org/docs/). We also recommend that you check the official [Let’s Encrypt blog](https://letsencrypt.org/blog/) for important updates from time to time.
