---
author: Pablo Carranza
date: 2013-11-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-send-only-mail-server-exim-on-ubuntu-12-04
---

# How To Install the Send-Only Mail Server "Exim" on Ubuntu 12.04

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

## Introduction

* * *

Due to the popularity of Gmail, Google Apps, Outlook.com, Yahoo! Mail & a myriad of other providers, many cloud-server users mistakenly fail to install a mail server, initially. However, humans are not the only ones that send electronic mail. If fact, many Linux server applications also need to send email.

## Message Transfer Agent (MTA)

* * *

A Message Transfer Agent, or Mail Transfer Agent, transfers electronic mail messages from one computer to another. An MTA implements both the client (sending) and server (receiving) portions of the Simple Mail Transfer Protocol (SMTP).

Another popular MTA is [Postfix](https://www.digitalocean.com/community/articles/how-to-install-and-setup-postfix-on-ubuntu-12-04); however, users that do not require a full-fledged mail server prefer the Exim send-only mail server because it is lightweight. Thus, Exim is a good choice for WordPress installations or server-monitoring apps that need to send email notifications.

## Prerequisites

* * *

This guide assumes that you have already:

- Set your droplet’s hostname and Fully Qualified Domain Name (FQDN).  

**See** [Setting the Hostname & Fully Qualified Domain Name (FQDN) on Ubuntu 12.04](https://github.com/DigitalOcean-User-Projects/Articles-and-Tutorials/blob/master/set_hostname_fqdn_on_ubuntu_centos.md);

- Created the necessary DNS records.  
 

**See** [How to Set Up a Host Name with DigitalOcean](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean);

- Created an SPF record.  

**See** [How To use an SPF Record to Prevent Spoofing & Improve E-mail Reliability](https://www.digitalocean.com/community/articles/how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability).

### Update Current Software

* * *

First, you want to update the software packages already on your virtual server by executing:

    sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove

## Installation

* * *

To install Exim and its dependencies, execute:

    sudo apt-get -y install exim4

To configure Exim for your environment, execute:

    sudo dpkg-reconfigure exim4-config

Configure everything according to your needs. If you ever need to modify any of your settings, simply re-run the configuration wizard.

### Mail Server Configuration Type

* * *

The first configuration window you encounter will ask you to select the “ **mail server configuration type that best meets your needs**.” If not already highlighted, use the arrow keys on your keyboard to select `internet site; mail is sent and received directly using SMTP`:

![Select the option for internet site](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/exim_ubuntu/img1.png)

Next, tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### Enter FQDN

* * *

The next configuration window will ask that you enter your system’s fully qualified domain name (FQDN) in the **mail name** configuration screen. Type the command below, substituting **hostname** , **yourdomain** & **tld** with your own values:

    hostname.yourdomain.tld

Next, tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### SMTP Listener

* * *

The ensuing configuration window will ask you to decide on which interfaces you would like Exim to “listen.” Enter:

    127.0.0.1

**Note:** DigitalOcean anticipates IPv6 support in the near future, at which time you may want to instruct Exim to listen on both `127.0.0.1; ::1`.

Next, tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### Mail Destinations

* * *

The configuration prompt that follows will ask that you enter all of the destinations for which Exim should accept mail. List your:

- FQDN;
- local hostname;
- `localhost.localdomain`;
- `localhost`

![Enter mail destinations](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/exim_ubuntu/img2.png)

Next, tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### Relay Options

* * *

Advanced configurations beyond the scope of this article allow you to use Exim as a relay mail server. In the next screen, leave the “relay mail” field blank.

Tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

The subsequent screen is a follow-up to the relay-mail-server option. Leave this window blank and tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### DNS Queries

* * *

Select **No** when asked whether to keep DNS queries to a minimum.

Make sure that `<No>` is highlighted and press “Enter”.

### Delivery Method

* * *

In the window that follows, choose whichever mail delivery method you’d like for incoming mail; although the **Maildir format** can make handling individual, locally-delivered mail messages easier:

![Choose the Maildir delivery method](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/exim_ubuntu/img3.png)

Next, tap the “Tab” key (to highlight `<Ok>`) and press “Enter”.

### Configuration File

* * *

In the ensuing prompt, choose the (default) **unsplit** configuration file by selecting “No”.

Make sure that `<No>` is highlighted and press “Enter”.

### Postmaster address

* * *

In the last configuration window, you’ll be asked to specify postmaster mail recipients. Enter the command below, substituting “you”, “yourdomain” & “tld” with your own values:

    root you@yourdomain.tld

**Note:** Make sure that, in addition to root, you enter at least one external email address (choose one that you check frequently).

## Test Your Mail Configuration

* * *

Send a test email to make sure everything is configured correctly by issuing the following command (substituting **[someone@somedomain.tld](mailto:someone@somedomain.tld)** for a valid, external email address):

    echo "This is a test." | mail -s Testing someone@somedomain.tld

**Note:** You may need check the recipient’s SPAM folder, in the event that the SPF record is not configured correctly.

## Additional Resources

* * *

- [Exim Documentation](http://www.exim.org/docs.html)
- [Exim Wiki](http://wiki.exim.org/)
- [Exim4 | Ubuntu 12.04 Server Guide](https://help.ubuntu.com/12.04/serverguide/exim4.html)

As always, if you need help with the steps outlined in this How-To, look to the DigitalOcean Community for assistance by posing your question(s), below.

Submitted by: [Pablo Carranza](https://plus.google.com/107285164064863645881?rel=author)
