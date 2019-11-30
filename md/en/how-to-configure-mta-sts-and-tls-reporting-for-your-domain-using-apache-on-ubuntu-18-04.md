---
author: Jamie Scaife
date: 2019-09-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-mta-sts-and-tls-reporting-for-your-domain-using-apache-on-ubuntu-18-04
---

# How To Configure MTA-STS and TLS Reporting for Your Domain Using Apache on Ubuntu 18.04

_The author selected [Electronic Frontier Foundation Inc](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Mail Transport Agent Strict Transport Security (MTA-STS)](https://www.hardenize.com/blog/mta-sts) is a new internet standard that allows you to enable strict force-TLS for email sent between supported email providers. It is similar to [HTTP Strict Transport Security (HSTS)](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), where a force-TLS policy is set and then cached for a specified amount of time, reducing the risk of man-in-the-middle or downgrade attacks.

MTA-STS is complemented by SMTP TLS Reporting (TLSRPT), which gives you insight into which emails are successfully delivered over TLS, and which aren’t. TLSRPT is similar to [DMARC reporting](https://dmarc.org/stats/dmarc-reporting/), but for TLS.

The primary reason for implementing MTA-STS for your domain is to ensure that confidential email that is sent to you is transmitted securely over TLS. Other methods for encouraging TLS for email communications, such as STARTTLS, are still susceptible to man-in-the-middle attacks, as the initial connection is unencrypted. MTA-STS helps to ensure that once at least one secure connection has been established, TLS will be used by default from there on, which greatly reduces the risk of these attacks.

An example use case for MTA-STS and TLS Reporting is to help create a secure customer service email system for your business. Customers may send support tickets via email that contain confidential personal information, which needs a secure TLS connection. MTA-STS helps to ensure the security of the connection, and TLSRPT will deliver daily reports identifying any emails that weren’t sent securely—giving crucial insight into any ongoing or previous attacks against your email system.

In this tutorial, you will learn how to configure MTA-STS and TLSRPT for your domain name, and then interpret your first TLS Report. While this tutorial covers the steps for using Apache on Ubuntu 18.04 with a Let’s Encrypt certificate, the MTA-STS/TLSRPT configuration will also work on alternatives, such as Nginx on Debian.

## Prerequisites

Before you begin this guide, you’ll need:

- A domain name already configured for receiving email, using either your own mail server or a hosted mail service, such as [G Suite](https://gsuite.google.com) or [Office 365](https://www.office.com/). This tutorial will use `your-domain` throughout, however this should be substituted with your own domain name. You will be required to set up a subdomain as part of the tutorial, so ensure that you are able to access the DNS settings for your domain.

- One Ubuntu 18.04 server set up by following the [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user.

- An Apache web server set up and configured by following [How to Install the Apache Web Server on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04).

- A configured Certbot client in order to acquire a Let’s Encrypt certificate, by following [How To Secure Apache with Let’s Encrypt on Ubuntu 18.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04).

Once you have these ready, log in to your server as your non-root user to begin.

**Note:** Once you have completed the implementation steps for MTA-STS and TLSRPT, you may have to wait up to 24 hours to receive your first TLS Report. This is because most email providers send reports once per day. You may resume the tutorial from Step 5 once you’ve received your first report.

## Step 1 — Creating an MTA-STS Policy File

MTA-STS is enabled and configured using a plain text configuration file that you host on your website. Supported mail servers will then automatically connect to your website to retrieve the file, which causes MTA-STS to be enabled. In this first step you’ll understand the available options for this file and choose the most appropriate for your file.

Firstly, open a new text file in your home directory so that you have somewhere to write down your desired configuration:

    nano mta-sts.txt

We will first go over an example, and then you will write your own configuration file.

Following is an example of an MTA-STS configuration file:

Example MTA-STS Configuration File

    version: STSv1
    mode: enforce
    mx: mail1.your-domain
    mx: mail2.your-domain
    max_age: 604800

This example configuration file specifies that all email delivered to `mail1.your-domain` and `mail2.your-domain` from supported providers must be delivered over a valid TLS connection. If a valid TLS connection cannot be established with your mail server (for example, if the certificate has expired or is self-signed), the email will not be delivered.

This will make it much more challenging for an attacker to intercept and snoop on/modify your email in a situation like a man-in-the-middle attack. This is because having MTA-STS enabled properly only allows email to be transmitted over a valid TLS connection, which requires a valid TLS certificate. It would be hard for an attacker to acquire such a certificate, as doing so usually requires privileged access to your domain name and/or website.

As shown in the example earlier in this step, the configuration file consists of a number of key/value pairs:

- `version`:

- `mode`:

- `mx`:

- `max_age`:

You can also view the official specification for the key/value pairs in [Section 3.2 of the MTA-STS RFC](https://tools.ietf.org/html/rfc8461#section-3.2).

**Warning:** Enabling MTA-STS in `enforce` mode could unexpectedly cause some email not to be delivered to you. Instead, it is recommended to use `mode: testing` and a low `max_age:` value at first, in order to ensure that everything is working correctly before turning on MTA-STS fully.

Using the example file earlier in the step, as well as the preceding key/value pair examples, write your desired MTA-STS policy file and save it to the file that you created at the start of the step.

The following example file is ideal for testing MTA-STS, as it will not cause any emails to be unexpectedly blocked, and has a `max_age` of only 1 day, meaning that if you decide to disable it, the configuration will expire quickly. Note that some email providers will only send TLSRPT reports if the `max_age` is greater than 1 day, which is why 86401 seconds is a good choice (1 day and 1 second).

Example Test MTA-STS Configuration File

    version: STSv1
    mode: testing
    mx: mail1.your-domain
    mx: mail2.your-domain
    max_age: 86401

In this step you created your desired MTA-STS configuration file and saved it to your home area. In the next step, you will configure an Apache web server to serve the file in the correct format.

## Step 2 — Configuring Apache to Serve Your MTA-STS Policy File

In this step, you’ll configure an Apache virtual host to serve your MTA-STS configuration file, and then add a DNS record to allow the site to be accessed from a subdomain.

In order for your MTA-STS configuration file to be automatically discovered by mail servers, it must be served at exactly the right path: `https://mta-sts.your-domain/.well-known/mta-sts.txt`. You must use the `mta-sts` subdomain over HTTPS and the `/.well-known/mta-sts.txt` path, otherwise your configuration will not work.

This can be achieved by creating a new Apache virtual host for the `mta-sts` subdomain, which will serve the MTA-STS policy file. This step builds upon the base configuration that you’ll have set up in the prerequisite step [How to Install the Apache Web Server on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04).

Firstly, create a directory for your virtual host:

    sudo mkdir /var/www/mta-sts

If you’re hosting multiple different domains on your web server, it is recommended to use a different MTA-STS virtual host for each, for example `/var/www/mta-sts-site1` and `/var/www/mta-sts-site2`.

Next, you need to create the `.well-known` directory, which is where your MTA-STS configuration file will be stored. `.well-known` is a standardized directory for ‘well-known’ files, such as TLS certificate validation files, `security.txt`, and more.

    sudo mkdir /var/www/mta-sts/.well-known

Now you can move the MTA-STS policy file that you created in Step 1 into the web server directory that you just created:

    sudo mv ~/mta-sts.txt /var/www/mta-sts/.well-known/mta-sts.txt

You can check that the file was copied correctly if you wish:

    cat /var/www/mta-sts/.well-known/mta-sts.txt

This will output the contents of the file that you created in Step 1.

In order for Apache to serve the file, you’ll need to configure the new virtual host and enable it. MTA-STS only works over HTTPS, so you’ll use port `443` (HTTPS) exclusively, rather than using port `80` (HTTP) as well.

Firstly, create a new virtual host configuration file:

    sudo nano /etc/apache2/sites-available/mta-sts.conf

Like with the virtual host directory, if you are hosting multiple different domains on the same web server, it is recommended to use a different virtual host name for each.

Then, copy the following sample configuration into the file, and populate the variables where required:

~/etc/apache2/sites-available/mta-sts.conf

    <IfModule mod_ssl.c>
    <VirtualHost your-server-ipv4-address:443 [your-server-ipv6-address]:443>
        ServerName mta-sts.your-domain
        DocumentRoot /var/www/mta-sts
    
        ErrorDocument 403 "403 Forbidden - This site is used to specify the MTA-STS policy for this domain, please see '/.well-known/mta-sts.txt'. If you were not expecting to see this, please use <a href=\"https://your-domain\" rel=\"noopener\">https://your-domain</a> instead."
    
        RewriteEngine On
        RewriteOptions IgnoreInherit
        RewriteRule !^/.well-known/mta-sts.txt - [L,R=403]
    
        SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
        Include /etc/letsencrypt/options-ssl-apache.conf
    </VirtualHost>
    </IfModule>

This configuration will create the `mta-sts` virtual host, which will be served at `mta-sts.your-domain`. It will also redirect all requests, except for those to the `mta-sts.txt` file itself, to a custom `403 Forbidden` error page, with a friendly explanation of what the subdomain site is for. This is to help ensure that any visitors who accidentally come across your MTA-STS site aren’t inadvertently confused.

Currently, a self-signed TLS certificate is used. This is not ideal, as a fully valid/trusted certificate is required for MTA-STS to work correctly. In Step 3, you will acquire a TLS certificate using Let’s Encrypt.

Next, ensure that the required Apache modules are enabled:

    sudo a2enmod rewrite ssl

After that, enable the new virtual host:

    sudo a2ensite mta-sts

Then, run a syntax check of the Apache configuration files, to ensure that there aren’t any unexpected errors:

    sudo apachectl configtest

When the test passes with no errors, you can restart Apache to fully enable the new virtual host:

    sudo service apache2 restart

Now that the Apache virtual host has been set up and configured, you need to create the required DNS record(s) to allow it to be accessed using the fully-qualified domain name `mta-sts.your-domain`.

The way that this is done depends on the DNS hosting provider that you use. However, if you use DigitalOcean as your DNS provider, simply navigate to your project, followed by clicking on your domain.

Finally, add the required DNS records for the `mta-sts` subdomain. If your Droplet only uses IPv4, create an `A` record for `mta-sts`, pointing to your-server-ipv4-address. If you use IPv6 as well, create an `AAAA` record pointing to your-server-ipv6-address.

![A screenshot of the DigitalOcean DNS control panel, showing an example DNS record for mta-sts pointing to an IPv4 address.](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mta-sls/step2.png)

In this step, you created and configured a new Apache virtual host for your MTA-STS subdomain, then added the required DNS record(s) to allow it to be accessed easily. In the next step, you will acquire a trusted Let’s Encrypt certificate for your MTA-STS subdomain.

## Step 3 — Acquiring a Let’s Encrypt Certificate for Your MTA-STS Subdomain

In this step, you’ll acquire a TLS certificate from Let’s Encrypt, to allow your `mta-sts.your-domain` site to be served correctly over HTTPS.

In order to do this, you’ll use `certbot`, which you set up as part of the prerequisite step [How To Secure Apache with Let’s Encrypt on Ubuntu 18.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04).

Firstly, run `certbot` to issue a certificate for your `mta-sts` subdomain using the Apache plugin verification method:

    sudo certbot --apache -d mta-sts.your-domain

This will automatically issue a trusted certificate and install it on your Apache web server. When the Certbot wizard asks about configuring a HTTP -\> HTTPS redirect, select 'No’, as this is not required for MTA-STS.

To finish, test your new virtual host to ensure that it is working correctly. Use a web browser to visit `https://mta-sts.your-domain/.well-known/mta-sts.txt`, or use a command-line tool such as `curl`:

    curl https://mta-sts.your-domain/.well-known/mta-sts.txt

This will output the MTA-STS policy file that you created in Step 1:

    Outputversion: STSv1
    mode: testing
    mx: mail1.your-domain
    mx: mail2.your-domain
    max_age: 86401

If an error occurs, ensure that the virtual host configuration from Step 2 is correct, and that you have added a DNS record for the `mta-sts` subdomain.

In this step, you issued a Let’s Encrypt TLS certificate for your `mta-sts` subdomain, and tested that it’s working. Next, you’ll set some DNS TXT records to fully enable MTA-STS and TLSRPT.

## Step 4 — Configuring the DNS Records Required to Enable MTA-STS and TLSRPT

In this step, you’ll configure two DNS TXT records, which will fully enable the MTA-STS policy that you have already created, and also enable TLS Reporting (TLSRPT).

These DNS records can be configured using any DNS hosting provider, but in this example, DigitalOcean is used as the provider.

Firstly, log on to your DigitalOcean control panel and navigate to your project, followed by clicking on your domain.

You then need to add the following two TXT records:

    _mta-sts.your-domain IN TXT "v=STSv1; id=id-value"
    _smtp._tls.your-domain IN TXT "v=TLSRPTv1; rua=reporting-address"

`id-value` is a string used to identify the version of your MTA-STS policy in place. If you update your policy, you’ll need to also update the `id` value to ensure that the new version is detected by mail providers. It is recommended to use the current date stamp as the `id`, for example `20190811231231` (23:12:31 on 11th Aug 2019).

`reporting-address` is the address where your TLS reports will be sent to. This can be either an email address prefixed with `mailto:`, or a web URI, for example for an API that collects reports. The reporting address doesn’t have to be an address on `your-domain`. You may use a completely different domain if you wish.

For example, the following two sample records are both valid:

    _mta-sts.your-domain IN TXT "v=STSv1; id=20190811231231"
    _smtp._tls.your-domain IN TXT "v=TLSRPTv1; rua=mailto:tls-reports@your-domain"

Adjust the variables as required, and set these DNS TXT records in your DigitalOcean control panel (or whichever DNS provider you’re using):

![A screenshot of the DigitalOcean control panel, showing the _mta-sts DNS TXT record being set.](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mta-sls/step4.png)

![A screenshot of the DigitalOcean control panel, showing the _smtp._tls DNS TXT record being set.](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mta-sls/step4a.png)

Once these DNS records have been set and have propagated, MTA-STS will be enabled with the policy that you created in Step 1, and will begin to receive TLSRPT reports at the address that you specified.

In this step, you configured the DNS records required for MTA-STS to be enabled. Next, you will receive and then interpret your first TLSRPT report.

## Step 5 — Interpreting Your First TLSRPT Report

Now that you’ve enabled MTA-STS and TLSRPT (TLS Reporting) for your domain, you will begin to receive reports from supported email providers. These reports will show the number of emails that were or were not successfully delivered over TLS, and the reasons for any errors.

Different email providers send their reports at different times; for example, Google Mail sends their reports daily at around 10:00 UTC.

Depending on how you configured the TLSRPT DNS record in Step 5, you will either receive your reports via email, or via a web API. This tutorial focuses on the email method, as that is the most common configuration.

If you’ve just completed the rest of this tutorial, wait until you receive your first report, then you can resume.

Your daily TLSRPT report via email will usually have a subject line similar to the following:

    Report Domain: your-domain Submitter: google.com Report-ID: <2019.08.10T00.00.00Z+your-domain@google.com>

This email will have an attachment in `.gz` format, which is a Gzip compressed archive, with a file name similar to the following:

    google.com!your-domain!1565222400!1565308799!001.json.gz

For the rest of this tutorial this file will be referred to as `report.json.gz`.

Save this file to your local machine, and extract it using whichever tool you prefer.

If you’re using a Debian-based Linux system, you will be able to run the `gzip -d` command to decompress the archive:

    gzip -d report.json.gz

This will result in a JSON file called `report.json`.

Next, you can view the report either directly as the raw JSON string, or use your favorite JSON prettifier to put it into a more readable format. In this example, `jq` will be used, but you could also use Python’s `json.tool` if you wish.

**Note:** If you don’t have jq installed, you can install it using `apt install jq`. Or, for other operating systems use the necessary [installation instructions](https://stedolan.github.io/jq/download/) from jq.

    jq . report.json

This will output something similar to the following:

    Prettified report.json{
        "organization-name": "Google Inc.",
        "date-range": {
            "start-datetime": "2019-08-10T00:00:00Z",
            "end-datetime": "2019-08-10T23:59:59Z"
        },
        "contact-info": "smtp-tls-reporting@google.com",
        "report-id": "2019-08-10T00:00:00Z_your-domain",
        "policies": [
            {
                "policy": {
                    "policy-type": "sts",
                    "policy-string": [
                        "version: STSv1",
                        "mode: testing",
                        "mx: mail1.your-domain",
                        "mx: mail2.your-domain",
                        "max_age: 86401"
                    ],
                    "policy-domain": "your-domain"
                },
                "summary": {
                    "total-successful-session-count": 230,
                    "total-failure-session-count": 0
                }
            }
        ]
    }

The report shows the provider that generated the report and the reporting period, as well as the MTA-STS policy that was applied. However, the main section that you’ll be interested in is `summary`, specifically the successful and failed session counts.

This sample report shows that 230 emails were successfully delivered over TLS from the mail provider that generated the report, and 0 email deliveries failed to establish a proper TLS connection.

In the event that there is a failure—for example, if a TLS certificate expires or there is an attacker on the network—the failure mode will be documented in the report. Some examples of failure modes are:

- `starttls-not-supported`: If the receiving mail server doesn’t support STARTTLS.
- `certificate-expired`: If a certificate has expired.
- `certificate-not-trusted`: If a self-signed or other non-trusted certificate is used.

In this final step, you received and then interpreted your first TLSRPT report.

## Conclusion

In this article you set up and configured MTA-STS and TLS Reporting for your domain, and interpreted your first TLSRPT report.

Once MTA-STS has been enabled and working stably for a while, it is recommended to adjust the policy, increasing the `max_age` value, and eventually switching it to `enforce` mode once you are sure that all email from supported providers is being delivered successfully over TLS.

Finally, if you’d like to learn more about the MTA-STS and TLSRPT specifications, you can review the RFCs for both of them:

- [RFC8461 - SMTP MTA Strict Transport Security (MTA-STS)](https://tools.ietf.org/html/rfc8461)

- [RFC8460 - SMTP TLS Reporting](https://tools.ietf.org/html/rfc8460)
