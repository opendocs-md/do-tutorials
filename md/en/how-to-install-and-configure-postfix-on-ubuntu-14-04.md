---
author: Justin Ellingwood
date: 2014-04-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-on-ubuntu-14-04
---

# How To Install and Configure Postfix on Ubuntu 14.04

## Introduction

Postfix is a very popular open source Mail Transfer Agent (MTA) that can be used to route and deliver email on a Linux system. It is estimated that around 25% of public mail servers on the internet run Postfix.

In this guide, we’ll teach you how to get up and running quickly with Postfix on an Ubuntu 14.04 server.

## Prerequisites

In order to follow this guide, you should have a Fully Qualified Domain Name pointed at your Ubuntu 14.04 server. You can find help on [setting up your domain name with DigitalOcean](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) by clicking here.

## Install the Software

The installation process of Postfix on Ubuntu 14.04 is easy because the software is in Ubuntu’s default package repositories.

Since this is our first operation with `apt` in this session, we’re going to update our local package index and then install the Postfix package:

    sudo apt-get update
    sudo apt-get install postfix

You will be asked what type of mail configuration you want to have for your server. For our purposes, we’re going to choose “Internet Site” because the description is the best match for our server.

Next, you will be asked for the Fully Qualified Domain Name (FQDN) for your server. This is your full domain name (like `example.com`). Technically, a FQDN is required to end with a dot, but Postfix does not need this. So we can just enter it like:

    example.com

The software will now be configured using the settings you provided. This takes care of the installation, but we still have to configure other items that we were not prompted for during installation.

## Configure Postfix

We are going to need to change some basic settings in the main Postfix configuration file.

Begin by opening this file with root privileges in your text editor:

    sudo nano /etc/postfix/main.cf

First, we need to find the `myhostname` parameter. During the configuration, the FQDN we selected was added to the `mydestination` parameter, but `myhostname` remained set to `localhost`. We want to point this to our FQDN too:

    myhostname = example.com

If you would like to configuring mail to be forwarded to other domains or wish to deliver to addresses that don’t map 1-to-1 with system accounts, we can remove the `alias_maps` parameter and replace it with `virtual_alias_maps`. We would then need to change the location of the hash to `/etc/postfix/virtual`:

    virtual_alias_maps = hash:/etc/postfix/virtual

As we said above, the `mydestination` parameter has been modified with the FQDN you entered during installation. This parameter holds any domains that this installation of Postfix is going to be responsible for. It is configured for the FQDN and the localhost.

One important parameter to mention is the `mynetworks` parameter. This defines the computers that are able to use this mail server. It should be set to local only (`127.0.0.0/8` and the other representations). Modifying this to allow other hosts to use this is a huge vulnerability that can lead to extreme cases of spam.

To be clear, the line should be set like this. This should be set automatically, but double check the value in your file:

    mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

## Configure Additional Email Addresses

We can configure additional email addresses by creating aliases. These aliases can be used to deliver mail to other user accounts on the system.

If you wish to utilize this functionality, make sure that you configured the `virtual_alias_maps` directive like we demonstrated above. We will use this file to configure our address mappings. Create the file by typing:

    sudo nano /etc/postfix/virtual

In this file, you can specify emails that you wish to create on the left-hand side, and username to deliver the mail to on the right-hand side, like this:

    blah@example.com username1

For our installation, we’re going to create a few email addresses and route them to some user accounts. We can also set up certain addresses to forward to multiple accounts by using a comma-separated list:

    blah@example.com demouser
    dinosaurs@example.com demouser
    roar@example.com root
    contact@example.com demouser,root

Save and close the file when you are finished.

Now, we can implement our mapping by calling this command:

    sudo postmap /etc/postfix/virtual

Now, we can reload our service to read our changes:

    sudo service postfix restart

## Test your Configuration

You can test that your server can receive and route mail correctly by sending mail from your regular email address to one of your user accounts on the server or one of the aliases you set up.

Once you send an email to:

    demouser@your\_server\_domain.com

You should get mail delivered to a file that matches the delivery username in `/var/mail`. For instance, we could read this message by looking at this file:

    nano /var/mail/demouser

This will contain all of the email messages, including the headers, in one big file. If you want to consume your email in a more friendly way, you might want to install a few helper programs:

    sudo apt-get install mailutils

This will give you access to the `mail` program that you can use to check your inbox:

    mail

This will give you an interface to interact with your mail.

## Conclusion

You should now have basic email functionality configured on your server.

It is important to secure your server and make sure that Postfix is not configured as an open relay. Mail servers are heavily targeted by attackers because they can send out massive amounts of spam email, so be sure to set up a firewall and implement other security measures to protect your server. You can learn about some [security options here](https://digitalocean.com/community/articles/an-introduction-to-securing-your-linux-vps).

By Justin Ellingwood
