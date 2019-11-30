---
author: Tati
date: 2016-11-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-organize-your-teamwork-with-onlyoffice-on-ubuntu-14-04
---

# How to Organize Your Teamwork with ONLYOFFICE on Ubuntu 14.04

### An Article from [ONLYOFFICE](http://www.onlyoffice.org)

## Introduction

[ONLYOFFICE](http://www.onlyoffice.org) is a free, open source corporate office suite developed to organize teamwork online. It’s composed of three separate servers:

- The **Document Server** provides users with text, spreadsheet and presentation online editors working within a browser and allowing to co-edit documents in real time, comment and interact using the integrated chat.
- The **Community Server** offers a complete set of tools for document, project, customer relation and email correspondence management.
- The **Mail Server** is used to create mailboxes using your own domain name.

Because ONLYOFFICE has many moving parts and dependencies, in this tutorial we’ll simplify the installation process and avoid dependency errors by deploying ONLYOFFICE using Docker containers.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 14.04 server with 8 GB of RAM and a sudo non-root user, which you can set up by following [the Ubuntu 14.04 initial server setup tutorial](initial-server-setup-with-ubuntu-14-04).

**Note** : The size requirement for an ONLYOFFICE server depends on which ONLYOFFICE components you will use, how many users will work in the web office, and the quantity of documents and mail you plan to store. 8 GB is recommended for all three servers.

- A registered domain name, which you can set up with [this host name tutorial](how-to-set-up-a-host-name-with-digitalocean).
- Docker v.1.10 or later, which you can install by following [step 1 of this Docker tutorial](how-to-install-and-use-docker-compose-on-ubuntu-14-04#step-1-%E2%80%94-installing-docker).

This tutorial will assume some familiarity with SSL, a security technology, and Docker, an open-source project that automates the deployment of applications inside software containers. If you’re not familiar with SSL, [this SSL tutorial](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs) has explanations to get you started. If you’re new to Docker, you can read [this Docker tutorial](how-to-install-and-use-docker-getting-started) for an introduction.

## Step 1 — Setting Up Security

Before installing ONLYOFFICE, we will first make sure access to it will be secured using SSL. To do this, we’ll need a private key (`.key`) and an SSL certificate (`.crt`).

If we use CA-certified certificates, these files are provided by the certificate authority. When [using self-signed certificates](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs#generating-ssl-certificates) we need to generate these files ourselves. The simplest and least expensive way to do it, especially if you have a small team, is to use a self-signed certificate. That’s what we’ll do here.

The ONLYOFFICE configuration directory will be `/app/onlyoffice/CommunityServer/data`. So first, we’ll create a directory to store our self-signed certificates here.

    sudo mkdir -p /app/onlyoffice/CommunityServer/data/certs

Move into the created directory.

    cd /app/onlyoffice/CommunityServer/data/certs

Next, create the server private key.

    sudo openssl genrsa -out onlyoffice.key 2048

Create the certificate signing request (CSR).

    sudo openssl req -new -key onlyoffice.key -out onlyoffice.csr

Here, you will be asked a few questions about your server to add the appropriate information to the certificate.

Once you fill out this information, sign the certificate using the private key and CSR.

    sudo openssl x509 -req -days 365 -in onlyoffice.csr -signkey onlyoffice.key -out onlyoffice.crt

Strengthen the server security by generating stronger DHE parameters, a temporary 2048-bit Diffie-Hellman key.

    sudo openssl dhparam -out dhparam.pem 2048

Now we have a SSL certificate valid for 365 days, and we can move on to installing ONLYOFFICE itself.

## Step 2 — Installing ONLYOFFICE

First, we’ll create an ONLYOFFICE network to allow a group of containers we need to communicate over it and isolate them from others. Use bridge as a `--driver` to manage the network.

    sudo docker network create --driver bridge onlyoffice

The commands we’ll use to start the ONLYOFFICE servers are pretty long, so let’s look at one and break it down. First, run this command to install the ONLYOFFICE Document Server:

    sudo docker run --net onlyoffice -i -t -d --restart=always \
    --name onlyoffice-document-server \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice onlyoffice/documentserver

Here, we launched an ONLYOFFICE container using `docker run --net onlyoffice`, which means it automatically connects to the `onlyoffice` bridge network we just created. `-d` means the container starts detached; `-i` keeps STDIN open (even when the container is detached); `-t` allocates a TTY. To make Docker automatically restart the containers on reboot, we specified the `--restart=always` parameter.

As a rule, all the data inside the Docker containers is stored in specially-designated directories called _data volumes_. Each ONLYOFFICE component has data volumes in particular directories. The Document server uses `/var/log/onlyoffice` for logs and `/var/www/onlyoffice/Data` for certificates.

To get access to these data volumes from outside the container, we mounted the volumes by specifying the `-v` option. Note that the necessary directories will be created automatically, but we will still need to grant the access rights to them once our web office is installed.

Now, install the ONLYOFFICE Mail Server, specifying your domain:

    sudo docker run --net onlyoffice --privileged -i -t -d --restart=always --name onlyoffice-mail-server \
    -p 25:25 -p 143:143 -p 587:587 \
    -v /app/onlyoffice/MailServer/data:/var/vmail \
    -v /app/onlyoffice/MailServer/data/certs:/etc/pki/tls/mailserver \
    -v /app/onlyoffice/MailServer/logs:/var/log \
    -v /app/onlyoffice/MailServer/mysql:/var/lib/mysql \
    -h example.com \
    onlyoffice/mailserver

This is very similar to the previous command with the addition of the `-p` flag to expose a few ports (`25` for SMTP, `143` for IMAP, and `587` for SMA). The data volumes for the Mail Server are:

- `/var/log` for logs
- `/var/lib/mysql` for MySQL database data
- `/var/vmail` for mail storage
- `/etc/pki/tls/mailserver` for certificates

Install the last of the three ONLYOFFICE servers: the Community Server.

    sudo docker run --net onlyoffice -i -t -d --restart=always --name onlyoffice-community-server \
    -p 80:80 -p 5222:5222 -p 443:443 \
    -v /app/onlyoffice/CommunityServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/CommunityServer/mysql:/var/lib/mysql \
    -v /app/onlyoffice/CommunityServer/logs:/var/log/onlyoffice \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/DocumentServerData \
    -e DOCUMENT_SERVER_PORT_80_TCP_ADDR=onlyoffice-document-server \
    -e MAIL_SERVER_DB_HOST=onlyoffice-mail-server \
    onlyoffice/communityserver

The Community Server opens ports `80` for HTTP, `443` for HTTPS, and `5222` for XMPP-compatible instant messaging client (for ONLYOFFICE Talk). The data volumes are:

- `/var/log/onlyoffice` for logs
- `/var/www/onlyoffice/Data` for data
- `/var/lib/mysql` for MySQL database data

Finally, grant access to the created folders:

    sudo chmod -R 755 /app/

Now, all three servers are installed and we can finish setting them up.

## Step 3 — Running and Configuring ONLYOFFICE

To access your new web office, visit `https://example.com` in your favorite browser.

Note that if you’re using a certificate that isn’t signed by one of your browser’s trusted CAs, you may get a warning. You can find a setting to access the page anyway, usually under an option labeled **Advanced** or something similar.

You will be directed to your web office. The initialization process will start. It might take some time, but once the initialization process finished, the welcome page will open. This will allow us to start the ONLYOFFICE initial configuration.

![Installing ONLYOFFICE on Ubuntu 14.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/onlyoffice/agxVWHO.png)

First, select and confirm the password and specify the email address you will use to access your office the next time.

Choose the language for your web office interface. When working in ONLYOFFICE, you will be able to change the language for all the users or for your own account only.

Set the time zone for your area. It’s particularly important for notifications and making the calendar work correctly.

Finally click the **Continue** button to complete the ONLYOFFICE configuration.

The email activation message will be sent to the specified email. Follow the link provided in this message to complete the email activation procedure. There’s one last step, which is to finish configuring the mail server.

## Step 4 — Configuring ONLYOFFICE Mail Server

To finish configuring mail, click the **Mail Server** icon on the welcome page.

![Installing ONLYOFFICE on Ubuntu 14.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/onlyoffice/HEUVTsv.png)

Click the **Set up domain** link.

![Installing ONLYOFFICE on Ubuntu 14.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/onlyoffice/pHVqxpw.png)

Click the **Set up the first domain** link, enter your domain name in the corresponding field, and click the **Next** button.

![Installing ONLYOFFICE on Ubuntu 14.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/onlyoffice/fxIRxgx.png)

Then, create all the required records using the information provided in the ONLYOFFICE wizard instructions:

![Installing ONLYOFFICE on Ubuntu 14.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/onlyoffice/xAy95L7.png)

On DigitalOcean, you can do this in the [control panel](https://cloud.digitalocean.com/networking/domains) in the **Networking** section, under **Domains**.

Once all the records are created, click the **OK** button in your browser. The added domain will be shown on the domain list page.

Your web office is fully set up!

## Conclusion

You’ve set up the ONLYOFFICE Document, Community, and Mail Servers. Now you can invite your teammates to start working. You can:

- Open, create and edit text documents, spreadsheets, and presentations — and co-edit them in real time with your team
- Create a project with milestones, tasks and subtasks and coordinate it using a Gantt chart
- Create a customer database, track potential sales storing all the necessary data in one place
- Connect and manage one or several email accounts
- Create an internal network with blogs, forums, bookmarks, polls, etc. for your community
- Organize your timetable and invite your teammates or any Internet users to events
