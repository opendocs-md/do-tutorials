---
author: Arpit Jalan
date: 2016-12-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-discourse-on-ubuntu-16-04
---

# How To Install Discourse on Ubuntu 16.04

### An Article from [Discourse](http://www.discourse.org/)

## Introduction

[Discourse](http://www.discourse.org/) is an open-source discussion platform. It can be used as a mailing list, a discussion forum, or a long-form chat room. In this tutorial, we’ll install Discourse in an isolated environment using [Docker](how-to-install-and-use-docker-on-ubuntu-16-04), a containerization application.

## Prerequisites

Before we get started, there are a few things we need to set up first:

- One Ubuntu 16.04 server with at least 2GB of RAM, set up by following this [Initial Server Setup on Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial, including a sudo non-root user and a firewall.
- Docker installed on your server, which you can do by following [Step 1 of the Docker installation tutorial for Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04).
- A domain name that resolves to your server, which you can set up by following [this hostname tutorial](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean).
- An SMTP mail server. If you don’t want to [run your own mail server](why-you-may-not-want-to-run-your-own-mail-server), you can use another service, like a free account on [SparkPost](https://sparkpost.com/). If you use SparkPost, you’ll need to [create an API key](https://support.sparkpost.com/customer/en/portal/articles/1933377-create-api-keys).

**Note** : Discourse requires a swap file if you are using 1 GB of RAM. Although swap is generally recommended for systems utilizing traditional spinning hard drives, using swap with SSDs can cause issues with hardware degradation over time. Due to this consideration, we do not recommend enabling swap on DigitalOcean or any other provider that utilizes SSD storage. Doing so can impact the reliability of the underlying hardware for you and your neighbors. Hence, we recommend a minimum of 2 GB of RAM to run Discourse on a DigitalOcean Droplet. Refer to [How To Add Swap Space on Ubuntu 16.04](how-to-add-swap-space-on-ubuntu-16-04) for details on using swap.

## Step 1 — Downloading Discourse

With all the prerequisites out of the way, you can go straight to installing Discourse.

You will need to be **root** through the rest of the setup and bootstrap process, so first, switch to a root shell.

    sudo -s

Next, create the `/var/discourse` directory, where all the Discourse-related files will reside.

    mkdir /var/discourse

Finally, clone the [official Discourse Docker Image](https://github.com/discourse/discourse_docker) into `/var/discourse`.

    git clone https://github.com/discourse/discourse_docker.git /var/discourse

With the files we need in place, we can move on to configuration and bootstrapping.

## Step 2 — Configuring and Bootstrapping Discourse

Move to the `/var/discourse` directory, where the Discourse files are.

    cd /var/discourse

From here, you can launch the included setup script.

    ./discourse-setup

You will be asked the following questions:

- **Hostname for your Discourse?**

Enter the hostname you’d like to use for Discourse, e.g. `discourse.example.com`, replacing `example.com` with your domain name. You do need to use a domain name because an IP address won’t work when sending email.

- **Email address for admin account?**

Choose the email address that you want to use for the Discourse admin account. It can be totally unrelated to your Discourse domain and can be any email address you find convenient.

Note that this email address will be made the Discourse admin by default when the first user registers with that email. You’ll also need this email address later when you set up Discourse from its web control panel.

- **SMTP server address?**

- **SMTP user name?**

- **SMTP port?**

- **SMTP password?**

Enter your SMTP server details for these questions. If you’re using SparkPost, the SMTP server address will be `smtp.sparkpostmail.com`, the user name will be **SMTP\_Injection** , the port will be `587`, and the password will be the [API key](https://support.sparkpost.com/customer/en/portal/articles/1933377-create-api-keys).

Finally, you will be asked to confirm all the settings you just entered. After you confirm your settings, the script will generate a configuration file called `app.yml` and then the bootstrap process will start.

**Note** : If you need to change or fix these settings after bootstrapping, edit your `/containers/app.yml` file and run `./launcher rebuild app`. Otherwise, your changes will not take effect.

Bootstrapping takes between 2-8 minutes, after which your instance will be running! Let’s move on to creating an administrator account.

## Step 3 — Registering an Admin Account

Visit your Discourse domain in your favorite web browser to view the Discourse web page.

![congratulations](http://i.imgur.com/nmRKhNB.png)

If you receive a 502 Bad Gateway error, try waiting a minute or two and then refreshing; Discourse may not have finished starting yet.

When the page loads, click the blue **Register** button. You’ll see a form entitled **Register Admin Account** with the following fields:

- **Email** : Choose the email address you provided earlier from the pull-down menu.
- **Username** : Choose a username.
- **Password** : Choose a strong password.

Then click the blue **Register** button on the form to submit it. You’ll see a dialog that says **Confirm your Email**. Check your inbox for the confirmation email. If you didn’t receive it, try clicking the **Resend Activation Email** button. If you’re still unable to register a new admin account, please see the Discourse [email troubleshooting checklist](https://meta.discourse.org/t/troubleshooting-email-on-a-new-discourse-install/16326).

After registering your admin account, the setup wizard will launch and guide you through Discourse’s basic configuration. You can walk through it now or click **Maybe Later** to skip.

![wizard](http://i.imgur.com/U8lBkkf.png)

After completing or skipping the setup wizard, you’ll see some topics and the [Admin Quick Start Guide](https://github.com/discourse/discourse/blob/master/docs/ADMIN-QUICK-START-GUIDE.md) (labeled **READ ME FIRST** ), which contains tips for further customizing your Discourse installation.

![homepage](http://i.imgur.com/6n8CGqb.png)

You’re all set! If you need to upgrade Discourse in the future, you can do it from the command line by pulling the latest version of the code from the Git repo and rebuliding the app, like this:

    cd /var/discourse
    git pull
    ./launcher rebuild app

You can also update it in your browser by visiting `http://discourse.example.com/admin/upgrade`, clicking **Upgrade to the Latest Version** , and following the instructions.

![upgrade](http://i.imgur.com/qX5cnoX.png)

## Conclusion

You can now start managing your Discourse forum and let users sign up. Learn more about Discourse’s features on [the Discourse About page](http://www.discourse.org/about/).
