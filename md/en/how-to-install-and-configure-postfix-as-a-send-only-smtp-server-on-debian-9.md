---
author: finid, Kathleen Juell
date: 2018-09-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-debian-9
---

# How To Install and Configure Postfix as a Send-Only SMTP Server on Debian 9

## Introduction

Postfix is a _mail transfer agent_ (MTA), an application used to send and receive email. In this tutorial, you will install and configure Postfix so that it can be used to send emails by local applications only — that is, those installed on the same server as Postfix.

Why would you want to do that?

If you’re already using a third-party email provider for sending and receiving emails, you do not need to run your own mail server. However, if you manage a cloud server on which you have installed applications that need to send email notifications, running a local, send-only SMTP server is a good alternative to using a third-party email service provider or running a full-blown SMTP server.

In this tutorial, you’ll install and configure Postfix as a send-only SMTP server on Debian 9.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 9 server, set up with the [Debian 9 initial server setup tutorial](initial-server-setup-with-debian-9), and a sudo non-root user.

- A valid domain name, like **example.com** , pointing to your server. You can set that up by following these [guidelines on managing DNS hosting on DigitalOcean](https://www.digitalocean.com/docs/networking/dns/).

Note that your server’s hostname should match your domain or subdomain. You can verify the server’s hostname by typing `hostname` at the command prompt. The output should match the name you gave the server when it was being created.

## Step 1 — Installing Postfix

In this step, you’ll learn how to install Postfix. You will need two packages: `mailutils`, which includes programs necessary for Postfix to function, and `postfix` itself.

First, update the package database:

    sudo apt update

Next, install `mailtuils`:

    sudo apt install mailutils

Finally, install `postfix`:

    sudo apt install postfix

Near the end of the installation process, you will be presented with a window that looks like the one in the image below. The default option is **Internet Site**. That’s the recommended option for this tutorial, so press `TAB`, then `ENTER`.

![Select Internet Site from the menu, then press TAB to select <Ok>, then ENTER](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/postfix-16.04/zJuFrgI.png?1)

After that, you’ll get another window just like the one in the next image. The **System mail name** should be the same as the name you assigned to the server when you were creating it. If it shows a subdomain like `subdomain.example.com`, change it to just `example.com`. When you’ve finished, press `TAB`, then `ENTER`.

![Enter your domain name, then press TAB to select <Ok>, ENTER](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/postfix-16.04/sVEi9SW.png?1)

You now have Postfix installed and are ready to modify its configuration settings.

## Step 2 — Configuring Postfix

In this step, you’ll configure Postfix to process requests to send emails only from the server on which it is running, i.e. from `localhost`.

For that to happen, Postfix needs to be configured to listen only on the _loopback interface_, the virtual network interface that the server uses to communicate internally. To make the change, open the main Postfix configuration file using `nano` or [your favorite text editor](initial-server-setup-with-debian-9#step-six-%E2%80%94-completing-optional-configuration):

    sudo nano /etc/postfix/main.cf

With the file open, scroll down until you see the following section:

/etc/postfix/main.cf

    . . .
    mailbox_size_limit = 0
    recipient_delimiter = +
    inet_interfaces = all
    . . .

Change the line that reads `inet_interfaces = all` to `inet_interfaces = loopback-only`:

/etc/postfix/main.cf

    . . .
    mailbox_size_limit = 0
    recipient_delimiter = +
    inet_interfaces = loopback-only
    . . .

Another directive you’ll need to modify is `mydestination`, which is used to specify the list of domains that are delivered via the `local_transport` mail delivery transport. By default, the values are similar to these:

    /etc/postfix/main.cf. . .
    mydestination = $myhostname, example.com, localhost.com, , localhost
    . . .

The [recommended defaults](http://www.postfix.org/postconf.5.html#mydestination) for this directive are given in the code block below, so modify yours to match:

    /etc/postfix/main.cf. . .
    mydestination = $myhostname, localhost.$your_domain, $your_domain
    . . .
    

Save and close the file.

**Note:** If you’re hosting multiple domains on a single server, the other domains can also be passed to Postfix using the `mydestination` directive. However, to configure Postfix in a manner that scales and that does not present issues for such a setup involves additional configurations that are beyond the scope of this article.

Finally, restart Postfix.

    sudo systemctl restart postfix

## Step 3 — Testing the SMTP Server

In this step, you’ll test whether Postfix can send emails to an external email account using the `mail` command, which is part of the `mailutils` package you installed in Step 1.

To send a test email, type:

    echo "This is the body of the email" | mail -s "This is the subject line" your_email_address

In performing your own test(s), you may use the body and subject line text as-is, or change them to your liking. However, in place of `your_email_address`, use a valid email address. The domain part can be `gmail.com`, `fastmail.com`, `yahoo.com`, or any other email service provider that you use.

Now check the email address where you sent the test message. You should see the message in your Inbox. If not, check your Spam folder.

Note that with this configuration, the address in the **From** field for the test emails you send will be `sammy@example.com`, where **sammy** is your Linux username and the domain is the server’s hostname. If you change your username, the **From** address will also change.

## Step 4 — Forwarding System Mail

The last thing we want to set up is forwarding, so you’ll get emails sent to **root** on the system at your personal, external email address.

To configure Postfix so that system-generated emails will be sent to your email address, you need to edit the `/etc/aliases` file:

    sudo nano /etc/aliases

The full contents of the file on a default installation of Debian 9 are as follows:

/etc/aliases

    mailer-daemon: postmaster
    postmaster: root
    nobody: root
    hostmaster: root
    usenet: root
    news: root
    webmaster: root
    www: root
    ftp: root
    abuse: root
    noc: root
    security: root

The `postmaster: root` setting ensures that system-generated emails are sent to the root user. You want to edit these settings so these emails are rerouted to your email address. To accomplish that, edit the file so that it reads:

/etc/aliases

    mailer-daemon: postmaster
    postmaster: root
    root: your_email_address
    . . .

Replace `your_email_address` with your personal email address. When finished, save and close the file. For the change to take effect, run the following command:

    sudo newaliases

You can test that it works by sending an email to the root account using:

    echo "This is the body of the email" | mail -s "This is the subject line" root

You should receive the email at your email address. If not, check your Spam folder.

## Conclusion

That’s all it takes to set up a send-only email server using Postfix. You may want to take some additional steps to protect your domain from spammers, however.

If you want to receive notifications from your server at a single address, then having emails marked as Spam is less of an issue because you can create a whitelist workaround. However, if you want to send emails to potential site users (such as confirmation emails for a message board sign-up), you should definitely set up SPF records and DKIM so your server’s emails are more likely to be seen as legitimate.

- [How To Use an SPF Record to Prevent Spoofing & Improve E-mail Reliability](how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability)

- [How To Install and Configure DKIM with Postfix on Debian Wheezy](how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy).

If configured correctly, these steps make it difficult to send Spam with an address that appears to originate from your domain. Taking these additional configuration steps will also make it more likely for common mail providers to see emails from your server as legitimate.
