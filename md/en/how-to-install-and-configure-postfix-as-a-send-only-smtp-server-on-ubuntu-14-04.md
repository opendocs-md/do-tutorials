---
author: finid
date: 2015-01-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-14-04
---

# How To Install and Configure Postfix as a Send-Only SMTP Server on Ubuntu 14.04

## Introduction

Postfix is an MTA (Mail Transfer Agent), an application used to send and receive email. In this tutorial, we will install and configure Postfix so that it can be used to send emails by local applications only – that is, those installed on the same server that Postfix is installed on.

**Why would you want to do that?**

If you’re already using a third-party email provider for sending and receiving emails, you, of course, do not need to run your own mail server. However, if you manage a cloud server on which you have installed applications that need to send email notifications, running a local, send-only SMTP server is a good alternative to using a 3rd party email service provider or running a full-blown SMTP server.

An example of an application that sends email notifications is OSSEC, which will send email alerts to any configured email address (see [How To Install and Configure OSSEC Security Notifications on Ubuntu 14.04](how-to-install-and-configure-ossec-security-notifications-on-ubuntu-14-04)). Though OSSEC or any other application of its kind can use a third-party email provider’s SMTP server to send email alerts, it can also use a local (send-only) SMTP server.

That’s what you’ll learn how to do in this tutorial: how to install and configure Postfix as a send-only SMTP server.

> **Note:** If your use case is to receive notifications from your server at a single address, emails being marked as spam is not a significant issue, since you can whitelist them.
> 
> If your use case is to send emails to potential site users, such as confirmation emails for message board sign-ups, you should definitely do **Step 5** so your server’s emails are more likely to be seen as legitimate. If you’re still having problems with your server’s emails being marked as spam, you will need to do further troubleshooting on your own.

### Prerequisites

Please complete the following prerequisites.

- Ubuntu 14.04 Droplet
- Go through the [initial setup](initial-server-setup-with-ubuntu-14-04). That means you should have a standard user account with `sudo` privileges
- Have a valid domain name, like **example.com** , pointing to your Droplet
- Your server’s hostname should match this domain or subdomain. You can verify the server’s hostname by typing `hostname` at the command prompt. The output should match the name you gave the Droplet when it was being created, such as **example.com**

If all the prerequisites have been met, you’re now ready for the first step of this tutorial.

## Step 1 — Install Postfix

In this step, you’ll learn how to install Postfix. The most efficient way to install Postfix and other programs needed for testing email is to install the `mailutils` package by typing:

    sudo apt-get install mailutils

Installing mailtuils will also cause Postfix to be installed, as well as a few other programs needed for Postfix to function. After typing that command, you will be presented with output that reads something like:

    The following NEW packages will be installed:
    guile-2.0-libs libgsasl7 libkyotocabinet16 libltdl7 liblzo2-2 libmailutils4 libmysqlclient18 libntlm0 libunistring0 mailutils mailutils-common mysql-common postfix ssl-cert
    
    0 upgraded, 14 newly installed, 0 to remove and 3 not upgraded.
    Need to get 5,481 kB of archives.
    After this operation, 26.9 MB of additional disk space will be used.
    Do you want to continue? [Y/n]

Press ENTER to install them. Near the end of the installation process, you will be presented with a window that looks exactly like the one in the image below. The default option is **Internet Site**. That’s the recommended option for this tutorial, so press TAB, then ENTER.

![Select Internet Site from the menu, then press TAB to select <Ok>, then ENTER](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/postfix_sendonly/1.png)

After that, you’ll get another window just like the one in this next image. The **System mail name** should be the same as the name you assigned to the Droplet when you were creating it. If it shows a subdomain like **mars.example.com** , change it to just **example.com**. When you’re done, Press TAB, then ENTER.

![Enter your domain name, then press TAB to select <Ok>, ENTER](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/postfix_sendonly/2.png)

After installation has completed successfully, proceed to Step 2.

## Step 2 — Configure Postfix

In this step, you’ll read how to configure Postfix to process requests to send emails only from the server on which it is running, that is, from **localhost**. For that to happen, Postfix needs to be configured to listen only on the _loopback interface_, the virtual network interface that the server uses to communicate internally. To make the change, open the main Postfix configuration file using the nano editor.

    sudo nano /etc/postfix/main.cf

With the file open, scroll down until you see the entries shown in this code block.

    mailbox_size_limit = 0
    recipient_delimiter = +
    inet_interfaces = all

Change the line that reads `inet_interfaces = all` to `inet_interfaces = loopback-only`. When you’re done, that same section of the file should now read:

    mailbox_size_limit = 0
    recipient_delimiter = +
    inet_interfaces = loopback-only

In place of `loopback-only` you may also use `localhost`, so that the modified section may also read:

    mailbox_size_limit = 0
    recipient_delimiter = +
    inet_interfaces = localhost

When you’re done editing the file, save and close it (press CTRL+X, followed by pressing Y, then ENTER). After that, restart Postfix by typing:

    sudo service postfix restart

## Step 3 — Test That the SMTP Server Can Send Emails

In this step, you’ll read how to test whether Postfix can send emails to any external email account. You’ll be using the `mail` command, which is part of the `mailutils` package that was installed in Step 1.

To send a test email, type:

    echo "This is the body of the email" | mail -s "This is the subject line" user@example.com

In performing your own test(s), you may use the body and subject line text as-is, or change them to your liking. However, in place of **[user@example.com](mailto:user@example.com)**, use a valid email address, where the domain part can be **gmail.com** , **fastmail.com** , **yahoo.com** , or any other email service provider that you use.

Now check the email address where you sent the test message.

You should see the message in your inbox. If not, check your spam folder.

**Note:** With this configuration, the address in the **From** field for the test emails you send will be **[sammy@example.com](mailto:sammy@example.com)**, where **sammy** is your Linux username and the domain part is the server’s hostname. If you change your username, the **From** address will also change.

## Step 4 — Forward System Mail

The last thing we want to set up is forwarding, so that you’ll get emails sent to **root** on the system at your personal, external email address.

To configure Postfix so that system-generated emails will be sent to your email address, you need to edit the `/etc/aliases` file.

    sudo nano /etc/aliases

The full content of the file on a default installation of Ubuntu 14.04 is shown in this code block:

    # See man 5 aliases for format
    postmaster: root

With that setting, system generated emails are sent to the root user. What you want to do is edit it so that those emails are rerouted to your email address. To accomplish that, edit the file so that it reads:

    # See man 5 aliases for format
    postmaster: root
    root: sammy@example.com

Replace **[sammy@example.com](mailto:sammy@example.com)** with your personal email address. When done, save and close the file. For the change to take effect, run the following command:

    sudo newaliases

You may now test that it works by sending an email to the root account using:

    echo "This is the body of the email" | mail -s "This is the subject line" root

You should receive the email at your email address. If not, check your spam folder.

### (Optional) Step 5 — Protect Your Domain from Spammers

In this step, you’ll be given links to articles to help you protect your domain from being used for spamming. This is an optional but highly recommended step, because if configured correctly, this makes it difficult to send spam with an address that appears to originate from your domain.

Doing these additional configuration steps will also make it more likely for common mail providers to see emails from your server as legitimate, rather than marking them as spam.

- [How To use an SPF Record to Prevent Spoofing & Improve E-mail Reliability](how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability)
- [How To Install and Configure DKIM with Postfix on Debian Wheezy](how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy)
- Also, make sure the PTR record for your server matches the hostname being used by the mail server when it sends messages. At DigitalOcean, you can change your PTR record by changing your Droplet’s name in the control panel

Though the second article was written for Debian Wheezy, the same steps apply for Ubuntu 14.04.
