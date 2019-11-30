---
author: Pablo Carranza
date: 2013-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-google-s-smtp-server
---

# How To Use Google's SMTP Server

## Introduction

A little-known feature about Gmail and Google Apps email is Google's portable SMTP server. Instead of having to manage your own outgoing mail server on your DigitalOcean VPS, you can simply configure Google's SMTP server settings into whatever script or program you wish to send email from. All you need is either a (i) free Gmail account or (ii) paid Google Apps account.

## Benefits

You have the option of having Google store and index the emails you send via its SMTP server, so all your sent emails will be searchable and backed-up on Google's servers. If you elect to use your Gmail or Google Apps account for your incoming email as well, you'll have all your email in one convenient place. Also, since Google's SMTP server does not use Port 25, you'll reduce the probability that an ISP might block your email or flag it as SPAM.

## Settings

Google's SMTP server requires authentication, so here's how to set it up:

**NOTE:** Before you begin, consider investigating your mail client or application’s security rating, according to Google. If you are using a program that Google does not consider secure, your usage will be blocked unless you enable less secure applications (a security setting that Google does not recommend). For more information see [this link](https://support.google.com/accounts/answer/6010255?hl=en) to determine the best approach for your mail client or application.

1. SMTP server (i.e., outgoing mail): **[smtp.gmail.com](http://smtp.gmail.com)**
2. SMTP username: **Your full Gmail or Google Apps email address** (e.g. [example@gmail.com](mailto:example@gmail.com) or [example@yourdomain.com](mailto:example@yourdomain.com))
3. SMTP password: **Your Gmail or Google Apps email password**
4. SMTP port: **465**
5. SMTP **TLS/SSL required** : **yes**
 In order to store a copy of outgoing emails in your Gmail or Google Apps _Sent_ folder, log into your Gmail or Google Apps email _Settings_ and: 6. Click on the _Forwarding/IMAP_ tab and scroll down to the _IMAP Access_ section: **IMAP must be enabled in order for emails to be properly copied to your sent folder.**

**NOTE:** Google automatically rewrites the _From_ line of any email you send via its SMTP server to the default _Send mail as_ email address in your Gmail or Google Apps email account _Settings_. You need to be aware of this nuance because it affects the presentation of your email, from the point of view of the recipient, and it may also affect the Reply-To setting of some programs.

**Workaround:** In your Google email _Settings_, go to the _Accounts_ tab/section and make "default" an account other than your Gmail/Google Apps account. This will cause Google's SMTP server to re-write the _From_ field with whatever address you enabled as the default _Send mail as_ address.

## Sending Limits

Google limits the amount of mail a user can send, via its portable SMTP server. This limit restricts the number of messages sent per day to 99 emails; and the restriction is automatically removed within 24 hours after the limit was reached.

Article Submitted by: [Pablo Carranza](http://vdevices.com)
