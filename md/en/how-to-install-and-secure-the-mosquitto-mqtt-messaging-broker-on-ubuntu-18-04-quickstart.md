---
author: Brian Boucheron
date: 2018-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-18-04-quickstart
---

# How to Install and Secure the Mosquitto MQTT Messaging Broker on Ubuntu 18.04 [Quickstart]

## Introduction

[MQTT](http://mqtt.org/) is a machine-to-machine messaging protocol, designed to provide lightweight publish/subscribe communication to “Internet of Things” devices. [Mosquitto](https://mosquitto.org/) is a popular MQTT server (or _broker_, in MQTT parlance) that has great community support and is easy to install and configure.

In this condensed quickstart tutorial we’ll install and configure Mosquitto, and use Let’s Encrypt SSL certificates to secure our MQTT traffic. If you need more in-depth coverage of any of the steps, please review the following tutorials:

- [How To Use Certbot Standalone Mode to Retrieve Let’s Encrypt SSL Certificates](how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates-on-ubuntu-1804)
- [How to Install and Secure the Mosquitto MQTT Messaging Broker](how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-18-04)

## Prerequisites

Before starting this tutorial, you will need:

- An Ubuntu 18.04 server with a non-root, sudo-enabled user and basic firewall set up, as detailed in [this Ubuntu 18.04 server setup tutorial](initial-server-setup-with-ubuntu-18-04)
- A domain name pointed at your server. This tutorial will use the placeholder `mqtt.example.com` throughout
- Port 80 must be unused on your server. If you’re installing Mosquitto on a machine with a web server that occupies this port, you’ll need to use a different method to fetch certificates, such as Certbot’s [_webroot_ mode](https://certbot.eff.org/docs/using.html#webroot).

## Step 1 — Installing the Software

First we will install a custom software repository to get the latest version of Certbot, the Let’s Encrypt client:

    sudo add-apt-repository ppa:certbot/certbot

Press `ENTER` to accept, then install the software packages for Mosquitto and Certbot:

    sudo apt install certbot mosquitto mosquitto-clients

Next we’ll fetch our SSL certificate.

## Step 2 — Downloading an SSL Certificate

Open up port `80` in your firewall:

    sudo ufw allow 80

Then run Certbot to fetch the certificate. Be sure to substitute your server’s domain name here:

    sudo certbot certonly --standalone --preferred-challenges http -d mqtt.example.com

You will be prompted to enter an email address and agree to the terms of service. After doing so, you should see a message telling you the process was successful and where your certificates are stored.

We’ll configure Mosquitto to use these certificates next.

## Step 3 — Configuring Mosquitto

First we’ll create a password file that Mosquitto will use to authenticate connections. Use `mosquitto_passwd` to do this, being sure to substitute your own preferred username:

    sudo mosquitto_passwd -c /etc/mosquitto/passwd your-username

You will be prompted twice for a password.

Now open up a new configuration file for Mosquitto:

    sudo nano /etc/mosquitto/conf.d/default.conf

This will open an empty file. Paste in the following:

/etc/mosquitto/conf.d/default.conf

    allow_anonymous false
    password_file /etc/mosquitto/passwd
    
    listener 1883 localhost
    
    listener 8883
    certfile /etc/letsencrypt/live/mqtt.example.com/cert.pem
    cafile /etc/letsencrypt/live/mqtt.example.com/chain.pem
    keyfile /etc/letsencrypt/live/mqtt.example.com/privkey.pem
    
    listener 8083
    protocol websockets
    certfile /etc/letsencrypt/live/mqtt.example.com/cert.pem
    cafile /etc/letsencrypt/live/mqtt.example.com/chain.pem
    keyfile /etc/letsencrypt/live/mqtt.example.com/privkey.pem

Be sure to substitute the domain name you used in Step 2 for `mqtt.example.com`. Save and close the file when you are finished.

This file does the following:

- Disables anonymous logins
- Uses our password file to enable password authentication
- Sets up a unsecured listener on port 1883 for **localhost** only
- Sets up a secure listener on port `8883`
- Sets up a secure websocket-based listener on port `8083`

Restart Mosquitto to pick up the configuration changes:

    sudo systemctl restart mosquitto

Check to make sure the service is running again:

    sudo systemctl status mosquitto

    Output● mosquitto.service - LSB: mosquitto MQTT v3.1 message broker
       Loaded: loaded (/etc/init.d/mosquitto; generated)
       Active: active (running) since Mon 2018-07-16 15:03:42 UTC; 2min 39s ago
         Docs: man:systemd-sysv-generator(8)
      Process: 6683 ExecStop=/etc/init.d/mosquitto stop (code=exited, status=0/SUCCESS)
      Process: 6699 ExecStart=/etc/init.d/mosquitto start (code=exited, status=0/SUCCESS)
        Tasks: 1 (limit: 1152)
       CGroup: /system.slice/mosquitto.service
               └─6705 /usr/sbin/mosquitto -c /etc/mosquitto/mosquitto.conf

The status should be `active (running)`. If it’s not, check your configuration file and restart again. Some more information may be available in Mosquitto’s log file:

    sudo tail /var/log/mosquitto/mosquitto.log

If all is well, use `ufw` to allow the two new ports through the firewall:

    sudo ufw allow 8883
    sudo ufw allow 8083

Now that Mosquitto is set up, we’ll configure Certbot to restart Mosquitto after renewing our certificates.

## Step 4 — Configuring Certbot Renewals

Certbot will automatically renew our SSL certificates before they expire, but it needs to be told to restart the Mosquitto service after doing so.

Open the Certbot renewal configuration file for your domain name:

    sudo nano /etc/letsencrypt/renewal/mqtt.example.com.conf

Add the following `renew_hook` option on the last line:

/etc/letsencrypt/renewal/mqtt.example.com.conf

    renew_hook = systemctl restart mosquitto

Save and close the file, then run a Certbot dry run to make sure the syntax is ok:

    sudo certbot renew --dry-run

If you see no errors, you’re all set. Let’s test our MQTT server next.

## Step 5 – Testing Mosquitto

We installed some command line MQTT clients in Step 1. We can subscribe to the topic **test** on the localhost listener like so:

    mosquitto_sub -h localhost -t test -u "your-user" -P "your-password"

And we can publish with `mosquitto_pub`:

    mosquitto_pub -h localhost -t test -m "hello world" -u "your-user" -P "your-password"

To subscribe using the secured listener on port 8883, do the following:

    mosquitto_sub -h mqtt.example.com -t test -p 8883 --capath /etc/ssl/certs/ -u "your-username" -P "your-password"

And this is how you publish to the secured listener:

    mosquitto_pub -h mqtt.example.com -t test -m "hello world" -p 8883 --capath /etc/ssl/certs/ -u "your-username" -P "your-password"

Note that we’re using the full hostname instead of `localhost`. Because our SSL certificate is issued for `mqtt.example.com`, if we attempt a secure connection to `localhost` we’ll get an error saying the hostname does not match the certificate hostname.

To test the websocket functionality, we’ll use a public, browser-based MQTT client. [Open the Eclipse Paho javascript client utility in your browser](https://www.eclipse.org/paho/clients/js/utility/) and fill out the connection information as follows:

- **Host** is the domain for your Mosquitto server, `mqtt.example.com`
- **Port** is `8083`
- **ClientId** can be left to the default randomized value
- **Path** can be left to the default value of **/ws**
- **Username** is your Mosquitto username from Step 3
- **Password** is the password you chose in Step 3

The remaining fields can be left to their default values.

After pressing **Connect** , the client will connect to your server. You can publish and subscribe using the **Subscribe** and **Publish Message** panes below the **Connection** pane.

## Conclusion

We’ve now set up and tested a secure, password-protected and SSL-encrypted MQTT server. This can serve as a robust and secure messaging platform for your IoT, home automation, or other projects.
