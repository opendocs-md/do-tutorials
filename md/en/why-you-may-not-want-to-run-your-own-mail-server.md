---
author: Mitchell Anicas
date: 2014-12-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/why-you-may-not-want-to-run-your-own-mail-server
---

# Why You May Not Want To Run Your Own Mail Server

## Introduction

When setting up a web site or application under your own domain, it is likely that you will also want a mail server to handle the domain’s incoming and outgoing email. While it is possible to run your own mail server, it is often not the best option for a variety of reasons. This guide will cover many of the reasons that you may not want to run your own mail server, and offer a few alternatives.

If you do not want to read the entire article, here is a quick summary: setting up and maintaining your own mail server is complicated and time-consuming, and there are several affordable alternatives—most people will get more value, in the form of saved time, out of using a paid mail service. With that said, read on if you want more details.

## Mail Servers Are Complex

A typical mail server consists of many software components that provide a specific function. Each component must be configured and tuned to work nicely together and provide a fully-functioning mail server. Because they have so many moving parts, mail servers can become complex and difficult to set up.

Here is a list of required components in a mail server:

- Mail Transfer Agent
- Mail Delivery Agent
- IMAP and/or POP3 Server

In addition to the the required components, you will probably want to add these components:

- Spam Filter
- AntiVirus
- Webmail

While some software packages include the functionality of multiple components, the choice of each component is often left up to you. In addition to the software components, mail servers need a domain name, the appropriate DNS records, and an SSL certificate.

Let’s take a look at each component in more detail.

### Mail Transfer Agent

A Mail Transfer Agent (MTA), which handles Simple Mail Transfer Protocol (SMTP) traffic, has two responsibilities:

1. To send mail from your users to an external MTA (another mail server)
2. To receive mail from an external MTA

Examples of MTA software: Postfix, Exim, and Sendmail.

### Mail Delivery Agent

A Mail Delivery Agent (MDA), which is sometimes referred to as the Local Delivery Agent (LDA), retrieves mail from a MTA and places it in the appropriate mail user’s mailbox.

There are a variety of mailbox formats, such as _mbox_ and _Maildir_. Each MDA supports specific mailbox formats. The choice of mailbox format determines how the messages are actually stored on the mail server which, in turn, affects disk usage and mailbox access performance.

Examples of MDA software: Postfix and Dovecot.

### IMAP and/or POP3 Server

IMAP and POP3 are protocols that are used by mail clients, i.e. any software that is used to read email, for mail retrieval. Each protocol has its own intricacies but we will highlight some key differences here.

IMAP is the more complex protocol that allows, among other things, multiple clients to connect to an individual mailbox simultaneously. The email messages are copied to the client, and the original message is left on the mail server.

POP3 is simpler, and moves email messages to the mail client’s computer, typically the user’s local computer, by default.

Examples of software that provide IMAP and/or POP3 server functionality: Courier, Dovecot, Zimbra.

### Spam Filter

The purpose of a spam filter is to reduce the amount of incoming spam, or junk mail, that reaches user’s mailboxes. Spam filters accomplish this by applying spam detection rules–which consider a variety of factors such as the server that sent the message, the message content, and so forth–to incoming mail. If a message’s “spam level” reaches a certain threshold, it is marked and treated as spam.

Spam filters can also be applied to outgoing mail. This can be useful if a user’s mail account is compromised, to reduce the amount of spam that can be sent using your mail server.

SpamAssassin is a popular open source spam filter.

### Antivirus

Antivirus is used to detect viruses, trojans, malware, and other threats in incoming and outgoing mail. ClamAV is a popular open source antivirus engine.

### Webmail

Many users expect their email service to provide webmail access. Webmail, in the context of running a mail server, is basically mail client that can be accessed by users via a web browser–Gmail is probably the most well-known example of this. The webmail component, which requires a web server such as Nginx or Apache, can run on the mail server itself.

Examples of software that provide webmail functionality: Roundcube and Citadel.

## Maintenance is Time-Consuming

Now that you are familiar with the mail server components that you have to install and configure, let’s look at why maintenance can become overly time-consuming. There are the obvious maintenance tasks, such as continuously keeping your antivirus and spam filtering rules, and all of the mail server components up to date, but there are some other things you might have not thought of.

### Staying Off Blacklists

Another challenge with maintaining a mail server is keeping your server off of the various blacklists, also known as DNSBL, blocklists, or blackhole lists. These lists contain the IP addresses of mail servers that were reported to send spam or junk mail (or for having improperly configured DNS records). Many mail servers subscribe to one or more of these blacklists, and filter incoming messages based on whether the mail server that sent the messages is on the list(s). If your mail server gets listed, your outgoing messages may be filtered and discarded before they reach their intended recipients.

If your mail server gets blacklisted, it is often possible to get it unlisted (or removed from the blacklist). You will want to determine the reason for being blacklisted, and resolve the issue. After this, you will want to look up the blacklist removal process for the particular list that your mail server is on, and follow it.

### Troubleshooting is Difficult

Although most people use email every day, it is easy to overlook the fact that it is a complex system can be difficult to troubleshoot. For example, if your sent messages are not being received, where do you start to resolve the issue? The issue could be caused by a misconfiguration in one of the many mail server components, such as a poorly tuned outgoing spam filter, or by an external problem, such as being on a blacklist.

## Easy Alternatives — Mail Services

Now that you know why you probably do not want to run your own mail server, here are some alternatives. These mail services will probably meet your needs, and will allow you and your applications to send and receive email from your own domain.

- [Google Apps](how-to-set-up-gmail-with-your-domain-on-digitalocean)
- [Zoho](how-to-set-up-zoho-mail-with-a-custom-domain-managed-by-digitalocean-dns)
- [FastMail](https://www.fastmail.com/)
- [Gandi](https://www.gandi.net/) (requires that the domain is registered through them)
- [Microsoft Office365](http://products.office.com/en-us/business/compare-office-365-for-business-plans)

This list doesn’t include every mail service; there are many out there, each with their own features and prices. Be sure to choose the one that has the features that you need, at a price that you want.

## Easy Alternatives — Postfix for Outgoing Mail

If you simply need to send outgoing mail from an application on your server, you don’t need to set up a complete mail server. You can set up a simple Mail Transfer Agent (MTA) such as Postfix. A tutorial that covers this can be found here: [How To Install and Setup Postfix on Ubuntu 14.04](how-to-install-and-setup-postfix-on-ubuntu-14-04).

You then can configure your application to use `sendmail`, on your server, as the mail transport for its outgoing messages.

## Not Convinced?

If you really want to run your own mail server, we have a few tutorials on the topic. Here are links to a few different setups:

- [How To Configure a Mail Server Using Postfix, Dovecot, MySQL, and SpamAssasin](how-to-configure-a-mail-server-using-postfix-dovecot-mysql-and-spamassasin)
- [How To Set Up a Postfix E-Mail Server with Dovecot](how-to-set-up-a-postfix-e-mail-server-with-dovecot)
- [How To Install iRedMail On Ubuntu 12.04 x64](how-to-install-iredmail-on-ubuntu-12-04-x64)
- [How To Install Citadel Groupware on an Ubuntu 13.10 VPS](how-to-install-citadel-groupware-on-an-ubuntu-13-10-vps)
- [How To Install the Send-Only Mail Server “Exim” on Ubuntu 12.04](how-to-install-the-send-only-mail-server-exim-on-ubuntu-12-04)
- [VirtualMin](how-to-install-and-utilize-virtualmin-on-a-vps)

Good luck!
