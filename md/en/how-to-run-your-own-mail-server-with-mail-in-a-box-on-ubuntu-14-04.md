---
author: finid
date: 2015-05-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-run-your-own-mail-server-with-mail-in-a-box-on-ubuntu-14-04
---

# How To Run Your Own Mail Server with Mail-in-a-Box on Ubuntu 14.04

## Introduction

[Mail-in-a-Box](https://mailinabox.email/) is an open source software bundle that makes it easy to turn your Ubuntu server into a full-stack email solution for multiple domains.

For securing the server, Mail-in-a-Box makes use of Fail2ban and an SSL certificate (self-signed by default). It auto-configures a UFW firewall with all the required ports open. Its anti-spam and other security features include graylisting, SPF, DKIM, DMARC, opportunistic TLS, strong ciphers, HSTS, and DNSSEC (with DANE TLSA).

Mail-in-a-Box is designed to handle SMTP, IMAP/POP, spam filtering, webmail, and even DNS as part of its all-in-one solution. Since the server itself is handling your DNS, you’ll get an off-the-shelf DNS solution optimized for mail. Basically, this means you’ll get sophisticated DNS records for your email (including SPF and DKIM records) without having to research and set them up manually. You can tweak your DNS settings afterwards as needed, but the defaults should work very well for most users hosting their own mail.

This tutorial shows how to set up Mail-in-a-Box on a DigitalOcean Droplet running Ubuntu 14.04 x86-64.

## Prerequisites

Mail-in-a-Box is very particular about the resources that are available to it. Specifically, it requires:

- An Ubuntu 14.04 x86-64 Droplet
- The server must have at least 768 MB of RAM (1 GB recommended)
- Be sure that the server has been set up along the lines given in [this tutorial](initial-server-setup-with-ubuntu-14-04), including adding a sudo user and disabling password SSH access for the root user (and possibly all users if your SSH keys are set up)
- When setting up the DigitalOcean Droplet, the name should be set to **box.example.com**. Setting the hostname is discussed later in this tutorial
- We’ll go into more detail later, but your domain registrar needs to support setting custom nameservers and glue records so you can host your own DNS on your Droplet; the term _vanity nameservers_ is frequently used
- (Optional) Purchase an [SSL certificate](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority) to use in place of the self-signed one; this is recommended for production environments

On the RAM requirement, the installation script will abort with the following output if the RAM requirement is not met:

    ErrorYour Mail-in-a-Box needs more memory (RAM) to function properly.
    Please provision a machine with at least 768 MB, 1 GB recommended.
    This machine has 513 MB memory

Before embarking on this, be sure that you have an Ubuntu server with 1 GB of RAM.

For this article, we’ll assume that the domain for which you are setting up an email server is **example.com**. You are, of course, expected to replace this with your real domain name.

## Step 1 — Configure Hostname

In this step, you’ll learn how to set the hostname properly, if it is not already set. Then you’ll modify the `/etc/hosts` file to match.

From here on, it is assumed that you’re logged into your DigitalOcean account and also logged into the server as a sudo user via SSH using:

    ssh sammy@your_server_ip

Officially, it is recommended that the hostname of your server be set to `box.example.com`. This should also be the name of the Droplet as it appears on your DigitalOcean dashboard. If the name of the Droplet is set to just the domain name, rename it by clicking on the name of the Droplet, then **Settings \> Rename**.

After setting the name of the Droplet as recommended, verify that it matches what appears in the `/etc/hostname` file by typing the command:

    hostname

The output should read something like this:

    Outputbox.example.com

If the output does not match the name as it appears on your DigitalOcean dashboard, correct it by typing:

    sudo echo "box.example.com" > /etc/hostname

## Step 2 — Modify /etc/hosts File

The `/etc/hosts` file needs to be modified to associate the hostname with the server’s IP address. To edit it, open it with nano or your favorite editor using:

    sudo nano /etc/hosts

Modify the IPv4 addresses, so that they read:

/etc/hosts

    127.0.0.1 localhost.localdomain localhost
    your_server_ip box.example.com box

You can copy the `localhost.localdomain localhost` line exactly. Use your own IP and domain on the second line.

Save and close the file.

## Step 3 — Create Glue Records

While it’s possible to have an external DNS service, like that provided by your domain registrar, handle all DNS resolutions for the server, it’s strongly recommended to delegate DNS responsibilities to the Mail-in-a-Box server.

That means you’ll need to set up _glue records_ when using Mail-in-a-Box. Using glue records makes it easier to securely and correctly set up the server for email. When using this method, it is very important that _all_ DNS responsibilities be delegated to the Mail-in-a-Box server, even if there’s an active website using the target domain.

If you do have an active website at your domain, make sure to set up the appropriate additional DNS records on your Mail-in-a-Box server. Otherwise, your domain won’t resolve to your website. You can copy your existing DNS records to make sure everything works the same.

Setting up glue records (also called _private nameservers_, _vanity nameservers_, and _child nameservers_) has to be accomplished at your domain registrar.

To set up a glue record, the following tasks have to be completed:

1. Set the glue records themselves. This involves creating custom nameserver addresses that associate the server’s fully-qualified hostname, plus the **ns1** and **ns2** prefixes, with its IP address. These should be as follows:

- **ns1.box.example.com your_server_ip**
- **ns2.box.example.com your_server_ip**

1. Transfer DNS responsibilities to the Mail-in-a-Box server.

- **example.com NS ns1.box.example.com**
- **example.com NS ns2.box.example.com**

**Note:** Both tasks must be completed correctly. Otherwise, the server will not be able to function as a mail server. (Alternately, you can set up all the appropriate MX, SPF, DKIM, etc., records on a different nameserver.)

The exact steps involved in this process vary by domain registrar. If the steps given in this article do not match yours, **contact your domain registrar’s tech support team** for assistance.

**Example: Namecheap**

To start, log into your domain registrar’s account. How your domain registrar’s account dashboard looks depends on the domain registrar you’re using. The example uses Namecheap, so the steps and images used in this tutorial are exactly as you’ll find them if you have a Namecheap account. If you’re using a different registrar, call their tech support or go through their knowledgebase to learn how to create a glue record.

After logging in, find a list of the domains that you manage and click on the target domain; that is, the one you’re about to use to set up the mail server.

Look for a menu item that allows you to modify its nameserver address information. On the Namecheap dashboard, that menu item is called **Nameserver Registration** under the **Advanced Options** menu category. You should get an interface that looks like the following:

![Modifying the Nameservers](http://i.imgur.com/HGGLt7q.png)

We’re going to set up two glue records for the server:

- **ns1.box.example.com**
- **ns2.box.example.com**

Since only one custom field is provided, they’ll have to be configured in sequence. As shown in the image below, type **ns1.box** where the number **1** appears, then type the IP address of the Mail-in-a-Box server in the IP Address field (indicated by the number **2** ). Finally, click the **Add Nameservers** button to add the record (number **3** ).

Repeat for the other record, making sure to use **ns2.box** along with the same domain name and IP address.

After both records have been created, look for another menu entry that says **Transfer DNS to Webhost**. You should get a window that looks just like the one shown in the image below. Select the custom DNS option, then type in the first two fields:

- **ns1.box.example.com**
- **ns2.box.example.com**

![Custom DNS](http://i.imgur.com/LmXg3ZW.png)

Click to apply the changes.

**Note:** The custom DNS servers you type here should be the same as the ones you just specified for the Nameserver Registration.

Changes to DNS take some time to propagate. It could take up to 24 hours, but it took only about 15 minutes for the changes made to the test domain to propagate.

You can verify that the DNS changes have been propagated by visiting [whatsmydns.net](https://www.whatsmydns.net). Search for the **A** and **MX** records of the target domain. If they match what you set in this step, then you may proceed to Step 4. Otherwise go through this step again or contact your registrar for assistance.

## Step 4 — Install Mail-in-a-Box

In this step, you’ll run the script to install Mail-in-a-Box on your Droplet. The Mail-in-a-Box installation script installs every package required to run a full-blown email server, so all you need to do is run a simple command and follow the prompts.

Assuming you’re still logged into the server, move to your home directory:

    cd ~

Install Mail-in-a-Box:

    curl -s https://mailinabox.email/bootstrap.sh | sudo bash

The script will prompt you with the introductory message in the following image. Press `ENTER`.

![Mail-in-a-Box Installation](http://i.imgur.com/rwyVRUO.png)

You’ll now be prompted to create the first email address, which you’ll later use to log in to the system. You could enter **[contact@example.com](mailto:contact@example.com)** or another email address at your domain. Accept or modify the suggested email address, and press `ENTER`. After that, you’ll be prompted to specify and confirm a password for the email account.

![Your Email Address](http://i.imgur.com/Y2MHRk0.png)

After the email setup, you’ll be prompted to confirm the hostname of the server. It should match the one you set in Step 1, which in this example is **box.example.com**. Press `ENTER`.

![Hostname](http://i.imgur.com/LGHOcar.png)

Next you’ll be prompted to select your country. Select it by scrolling up or down using the arrows keys. Press `ENTER` after you’ve made the right choice.

![Country Code](http://i.imgur.com/6WxmdC3.png)

At some point, you’ll get this prompt:

    OutputOkay. I'm about to set up contact@example.com for you. This account will also have access to the box's control panel.
    password:

Specify a password for the default email account, which will also be the default web interface admin account.

After installation has completed successfully, you should see some post-installation output that includes:

    Outputmail user added
    added alias hostmaster@box.example.com (=> administrator@box.example.com)
    added alias postmaster@example.com (=> administrator@box.example.com)
    added alias admin@example.com (=> administrator@box.example.com)
    updated DNS: example.com
    web updated
    
    alias added
    added alias admin@box.example.com (=> administrator@box.example.com)
    added alias postmaster@box.example.com (=> administrator@box.example.com)
    
    
    -----------------------------------------------
    
    Your Mail-in-a-Box is running.
    
    Please log in to the control panel for further instructions at:
    
    https://your_server_ip/admin
    
    You will be alerted that the website has an invalid certificate. Check that
    the certificate fingerprint matches:
    
    1F:C1:EE:C7:C6:2C:7C:47:E8:EF:AC:5A:82:C1:21:67:17:8B:0C:5B
    
    Then you can confirm the security exception and continue.

## Step 5 — Log In to Mail-in-a-Box Dashboard

Now you’ll log in to the administrative interface of Mail-in-a-Box and get to know your new email server. To access the admin interface, use the URL provided in the post-installation output. This should be:

- `https://your_server_ip/admin#`

Because HTTPS and a self-signed certificate were used, you will get a security warning in your browser window. You’ll have to create a security exception. How that’s done depends on the browser you’re using.

If you’re using Firefox, for example, you will get a browser window with the familiar warning shown in the next image.

To accept the certificate, click the **I Understand the Risks** button, then on the **Add Exception** button.

![The connection is untrusted in Firefox](http://i.imgur.com/oSERTMV.png)

On the next screen, you may verify that the certificate fingerprint matches the one in the post-installation output, then click the **Confirm Security Exception** button.

![Add Security Exception in Firefox](http://i.imgur.com/jvRbbqX.png)

After the exception has been created, log in using the username and password of the email account created during installation. Note that the username is the complete email address, like `contact@example.com`.

When you log in, a system status check is initiated. Mail-in-a-Box will check that all aspects of the server, including the glue records, have been configured correctly. If true, you should see a sea of green (and some yellowish green) text, except for the part pertaining to SSL certificates, which will be in red. You might also see a message about a reboot, which you can take care of.

**Note:** If there are outputs in red about incorrect DNS MX records for the configured domain, then Step 3 was not completed correctly. Revisit that step or contact your registrar’s tech support team for assistance.

If the only red texts you see are because of SSL certificates, congratulations! You have now successfully set up your own mail server using Mail-in-a-Box.

If you want to revisit this section (for example, after waiting for DNS to propagate), it’s under **System \> Status Checks**.

## Step 6 — Access Webmail & Send Test Email

To access the webmail interface, click on **Mail \> Instructions** from the top navigation bar, and access the URL provided on that page. It should be something like this:

- `https://box.example.com/mail`

Log in with the email address (include the **@example.com** part) and password that you set up earlier.

Mail-in-a-box uses [Roundcube](http://trac.roundcube.net/wiki) as its webmail app. Try sending a test email to an external email address. Then, reply or send a new message to the address managed by your Mail-in-a-Box server.

The outgoing email should be received almost immediately, but because graylisting is in effect on the Mail-in-a-Box server, it will take about 15 minutes before incoming email shows up.

This won’t work if DNS is not set up correctly.

If you can both send and receive test messages, you are now running your own email server. Congratulations!

## (Optional) Step 7 — Install SSL Certificate

Mail-in-a-box generates its own self-signed certificate by default. If you want to use this server in a production environment, we highly recommend installing an official SSL certificate.

First, [purchase your certificate](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority). Or, to learn how to create a free signed SSL certificate, refer to the [How To Set Up Apache with a Free Signed SSL Certificate on a VPS](how-to-set-up-apache-with-a-free-signed-ssl-certificate-on-a-vps) tutorial.

Then, from the Mail-in-a-Box admin dashboard, select **System \> SSL Certificates** from the top navigation menu.

From there, use the **Install Certificate** button next to the appropriate domain or subdomain. Copy and paste your certificate and any chain certificates into the provided text fields. Finally click the **Install** button.

Now you and your users should be able to acces webmail and the admin panel without browser warnings.

## Conclusion

It’s easy to keep adding domains and additional email addresses to your Mail-in-a-Box server. To add a new address at a new or existing domain, just add another email account from **Mail \> Users** in the admin dashboard. If the email address is at a new domain, Mail-in-a-box will automatically add appropriate new settings for it.

If you’re adding a new domain, make sure you set the domain’s nameservers to **ns1.box.example.com** and **ns2.box.example.com** (the same ones we set up earlier for the first domain) at your domain registrar. Your Droplet will handle all of the DNS for the new domain.

To see the current DNS settings, visit **System \> External DNS**. To add your own entries, visit **System \> Custom DNS**.

Mail-in-a-Box also provides functionality beyond the scope of this article. It can serve as a hosted contact and calendar manager courtesy of ownCloud. It can also be used to host static websites.

Further information about Mail-in-a-Box is available at the [project’s home page](https://mailinabox.email/).
