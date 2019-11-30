---
author: Arpit Jalan
date: 2014-09-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-discourse-on-ubuntu-14-04
---

# How To Install Discourse on Ubuntu 14.04

 **Warning** : This article is out of date and no longer works. Please read [the updated Discourse article](how-to-install-discourse-on-ubuntu-16-04) instead.

### An Article from [Discourse](http://www.discourse.org/)

## Introduction

[Discourse](http://www.discourse.org/) is an open source discussion platform built for the next decade of the Internet. We’ll walk through all of the steps required to get Discourse running on your DigitalOcean Droplet.

### Prerequisites

Before we get started, there are a few things we need to set up first:

- Ubuntu 14.04 Droplet (64 bit) with a minimum of 2 GB of RAM. If you need help with this part, [this tutorial](how-to-create-your-first-digitalocean-droplet-virtual-server) will get you started.

- You can use an IP address as your domain for testing, but for a production server, you should have a domain that resolves to your Droplet. [This tutorial](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) can help.

- Non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)

- Free account on [Mandrill](https://mandrill.com/) and [get SMTP credentials](http://help.mandrill.com/entries/23744737-Where-do-I-find-my-SMTP-credentials). It wouldn’t hurt to test the validity of these credentials beforehand, although you can use them for the first time with Discourse.

All the commands in this tutorial should be run as a non-root user. If root access is required for the command, it will be preceded by `sudo`. [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to add users and give them sudo access.

## Step 1 — Install Git

In this section we will install [Git](http://git-scm.com/) to download the Discourse source files. Git is an open source distributed version control and source code management system.

Before we get started, it is highly recommend to make sure that your system is up to date. SSH into your Droplet as the root user:

    ssh sammy@your-server-ip

Execute the following commands on your Droplet to update the system:

    sudo apt-get update
    sudo apt-get upgrade

Once that is complete, install Git by running following command:

    sudo apt-get install git

## Step 2 — Install Docker

In this section we will install [Docker](https://www.docker.com/) so that Discourse will have an isolated environment in which to run. Docker is an open source project that can pack, ship, and run any application in a lightweight container. For more introductory information about Docker, please see [this tutorial](how-to-install-and-use-docker-getting-started).

Docker provides a public script to get Docker installed:

    wget -qO- https://get.docker.io/ | sh

You need to add your non-root user to the `docker` group to be able to run a Docker container as this user:

    sudo usermod -aG docker sammy

You also have to log out and log back in as that user to enable the change:

    exit
    su - sammy

## Step 3 — Download Discourse

In this section we will download Discourse.

Create a /var/discourse folder, where all the Discourse-related files will reside:

    sudo mkdir /var/discourse

Clone the [official Discourse Docker Image](https://github.com/discourse/discourse_docker) into this /var/discourse folder:

    sudo git clone https://github.com/discourse/discourse_docker.git /var/discourse

## Step 4 — Configure Discourse

In this section we will configure your initial Discourse settings.

Switch to the /var/discourse directory:

    cd /var/discourse

Copy the samples/standalone.yml file into the `containers` folder as `app.yml`:

    sudo cp samples/standalone.yml containers/app.yml

Edit the Discourse configuration in the `app.yml` file:

    sudo nano containers/app.yml

The configuration file will open in the [nano text editor](http://www.nano-editor.org/).

Locate the env section and update it with your custom email, domain, and SMTP server information, as shown below. The individual lines are explained after the example block:

app.yml

    ...
    env:
      LANG: en_US.UTF-8
      ## TODO: How many concurrent web requests are supported?
      ## With 2GB we recommend 3-4 workers, with 1GB only 2
      #UNICORN_WORKERS: 3
      ##
      ## TODO: List of comma delimited emails that will be made admin and developer
      ## on initial signup example 'user1@example.com,user2@example.com'
      DISCOURSE_DEVELOPER_EMAILS: 'me@example.com'
      ##
      ## TODO: The domain name this Discourse instance will respond to
      DISCOURSE_HOSTNAME: 'discourse.example.com'
      ##
      ## TODO: The mailserver this Discourse instance will use
      DISCOURSE_SMTP_ADDRESS: smtp.mandrillapp.com # (mandatory)
      DISCOURSE_SMTP_PORT: 587 # (optional)
      DISCOURSE_SMTP_USER_NAME: login@example.com # (optional)
      DISCOURSE_SMTP_PASSWORD: 9gM5oAw5pBB50KvjcwAmpQ # (optional)
      ##
      ## The CDN address for this Discourse instance (configured to pull)
      #DISCOURSE_CDN_URL: //discourse-cdn.example.com
      ...
    

Here are the individual lines that need to be changed:

1) **Set Admin Email**

Choose the email address that you want to use for the Discourse admin account. It can be totally unrelated to your Discourse domain and can be any email address you find convenient. Set this email address in the DISCOURSE\_DEVELOPER\_EMAILS line. This email address will be made the Discourse admin by default, once a user registers with that email. You’ll need this email address later when you set up Discourse from its web control panel.

    DISCOURSE_DEVELOPER_EMAILS: 'me@example.com'

Replace [me@example.com](mailto:me@example.com) with your email.

Developer Email setup is required for creating and activating your initial administrator account.

2) **Set Domain**

Set DISCOURSE\_HOSTNAME to discourse.example.com. This means you want your Discourse forum to be available at [http://discourse.example.com/](http://discourse.example.com/). You can use an IP address here instead if you don’t have a domain pointing to your server yet. Only one domain (or IP) can be listed here.

    DISCOURSE_HOSTNAME: 'discourse.example.com'

Replace discourse.example.com with your domain. A hostname is required to access your Discourse instance from the web.

3) **Set Mail Credentials**

We recommend Mandrill for your SMTP mail server. [Get your SMTP credentials from Mandrill](http://help.mandrill.com/entries/23744737-Where-do-I-find-my-SMTP-credentials).

Enter your SMTP credentials in the lines for DISCOURSE\_SMTP\_ADDRESS, DISCOURSE\_SMTP\_PORT, DISCOURSE\_SMTP\_USER\_NAME, and DISCOURSE\_SMTP\_PASSWORD. (Be sure you remove the comment **#** character from the beginnings of these lines as necessary.)

    DISCOURSE_SMTP_ADDRESS: smtp.mandrillapp.com # (mandatory)
    DISCOURSE_SMTP_PORT: 587 # (optional)
    DISCOURSE_SMTP_USER_NAME: login@example.com # (optional)
    DISCOURSE_SMTP_PASSWORD: 9gM5oAw5pBB50KvjcwAmpQ # (optional)

The SMTP settings are required to send mail from your Discourse instance; for example, to send registration emails, password reset emails, reply notifications, etc.

Having trouble setting up mail credentials? See the Discourse [Email Troubleshooting guide](https://meta.discourse.org/t/troubleshooting-email-on-a-new-discourse-install/16326).

Setting up mail credentials is required, or else you will not be able to bootstrap your Discourse instance. The credentials must be correct, or else you will not be able to register users (including the admin user) for the forum.

4) **Optional: Tune Memory Settings (preferred for 1 GB Droplet)**

Also in the env section of the configuration file, set db\_shared\_buffers to **128MB** and UNICORN\_WORKERS to **2** so you have more memory room.

    db_shared_buffers: "128MB"

and

    UNICORN_WORKERS: 2

Tuning these memory settings will optimize Discourse performance on a 1 GB Droplet.

**NOTE:** The above changes are mandatory and should not be skipped, or else you will have a broken Discourse forum.

Save the `app.yml` file, and exit the text editor.

## Step 5 — Bootstrap Discourse

In this section we will bootstrap Discourse.

First, we need to make sure that Docker can access all of the outside resources it needs. Open the Docker settings file `/etc/default/docker`:

    sudo nano /etc/default/docker

Uncomment the DOCKER\_OPTS line so Docker uses Google’s DNS:

/etc/default/docker

    ...
    
    # Use DOCKER_OPTS to modify the daemon startup options.
    DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4"
    
    ...

Restart Docker to apply the new settings:

    sudo service docker restart

**Note:** If you don’t change Docker’s DNS settings before running the bootstrap command, you may get an error like “fatal: unable to access ’[https://github.com/SamSaffron/pups.git/’:](https://github.com/SamSaffron/pups.git/':) Could not resolve host: github.com”.

Now use the bootstrap process to build Discourse and initialize it with all the settings you configured in the previous section. This also starts the Docker container. You must be in the /var/discourse directory:

    cd /var/discourse

Bootstrap Discourse:

    sudo ./launcher bootstrap app

This command will take about 8 minutes to run while it configures your Discourse environment. (Early in this process you will be asked to generate a SSH key; press **Y** to accept.)

After the bootstrap process completes, start Discourse:

    sudo ./launcher start app   

Congratulations! You now have your very own Discourse instance!

## Step 6 — Access Discourse

Visit the domain or IP address (that you set for the Discourse hostname previously) in your web browser to view the default Discourse web page.

![discourse](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/Install_Discourse/1.png)

If you receive a 502 Bad Gateway error, try waiting a minute or two and then refreshing so Discourse can finish starting.

## Step 7 — Sign Up and Create Admin Account

Use the **Sign Up** button at the top right of the page to register a new Discourse account. You should use the email address you provided in the DISCOURSE\_DEVELOPER\_EMAILS setting previously. Once you confirm your account, that account will automatically be granted admin privileges.

![sign_up](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/Install_Discourse/2.png)

Once you sign up and log in, you should see the Staff topics and the [Admin Quick Start Guide](https://github.com/discourse/discourse/blob/master/docs/ADMIN-QUICK-START-GUIDE.md). It contains the next steps for further configuring and customizing your Discourse installation.

You can access the admin dashboard by visting /admin.

![dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/Install_Discourse/3.png)

If you _don’t_ get any email from signing up, and are unable to register a new admin account, please see the Discourse [email troubleshooting checklist](https://meta.discourse.org/t/troubleshooting-email-on-a-new-discourse-install/16326).

If you are still unable to register a new admin account via email, see the [Create Admin Account from Console](https://meta.discourse.org/t/create-admin-account-from-console/17274) walkthrough, but please note that _you will have a broken site_ until you get normal SMTP email working.

That’s it! You can now let users sign up and start managing your Discourse forum.

### Post-Installation Upgrade

To **upgrade Discourse to the latest version** , visit `/admin/upgrade` and follow the instructions.

![upgrade](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/Install_Discourse/4.png)
