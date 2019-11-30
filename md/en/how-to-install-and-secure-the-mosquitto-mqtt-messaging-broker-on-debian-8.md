---
author: Brian Boucheron
date: 2017-01-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-debian-8
---

# How to Install and Secure the Mosquitto MQTT Messaging Broker on Debian 8

## Introduction

[MQTT](http://mqtt.org/) is a machine-to-machine messaging protocol, designed to provide lightweight publish/subscribe communication to “Internet of Things” devices. It is commonly used for geo-tracking fleets of vehicles, home automation, environmental sensor networks, and utility-scale data collection.

[Mosquitto](https://mosquitto.org/) is a popular MQTT server (or _broker_, in MQTT parlance) that has great community support and is easy to install and configure.

In this tutorial, we’ll install Mosquitto, retrieve SSL certificates from Let’s Encrypt, and set up our broker to use SSL to secure our password-protected MQTT communications.

## Prerequisites

Before starting this tutorial, you will need:

- A Debian 8 server with a non-root, sudo-enabled user as detailed in [this Debian 8 server setup tutorial](initial-server-setup-with-debian-8).
- A basic firewall set up with `ufw`, explained in [How To Set Up a Firewall with UFW on Ubuntu 14.04](how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04). Despite the Ubuntu-centric title, you can follow along in Debian, making sure to `sudo apt-get install ufw` first, as Debian doesn’t include `ufw` by default.
- A domain name pointed at your server, as per [How to Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean). This tutorial will use `mqtt.example.com` throughout.

## Step 1 — Installing Mosquitto

Debian’s `mosquitto` package doesn’t support some of the features we need, so we’ll install from a more up-to-date repository provided by the Mosquitto project. First, download their repository signing key.

    wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key

Then install the key with `apt-key`.

    sudo apt-key add mosquitto-repo.gpg.key

This allows `apt-get` to verify the integrity of any software you install from the new repository.

Now tell `apt-get` where to find the software by adding the repository URL to a file in `/etc/apt/sources.list.d/`.

    sudo nano /etc/apt/sources.list.d/mosquitto.list

This will open up a new, blank file. Paste the following line into the file.

/etc/apt/sources.list.d/mosquitto.list

    deb http://repo.mosquitto.org/debian jessie main

Save and close out of the editor, then update with `apt-get` to pull in the new package information.

    sudo apt-get update

And finally, install the `mosquitto` package and its client software.

    sudo apt-get install mosquitto mosquitto-clients

By default, Debian will start the Mosquitto service after install. Let’s test the default configuration. We’ll use one of the clients we just installed to subscribe to a topic on our broker.

_Topics_ are labels that you publish messages to and subscribe to. They are arranged as a hierarchy, so you could have `sensors/outside/temp` and `sensors/outside/humidity`, for example. How you arrange topics is up to you and your needs. Throughout this tutorial we will use a simple test topic to test our configuration changes.

Log in to your server a second time, so you have two terminals side-by-side. In the new terminal, use `mosquitto_sub` to subscribe to the test topic:

    mosquitto_sub -h localhost -t test

The `-h` flag specifies the hostname of the MQTT server, and `-t` is the topic name. You’ll see no output after hitting `ENTER` because `mosquitto_sub` is waiting for messages to arrive. Switch back to your other terminal and publish a message:

    mosquitto_pub -h localhost -t test -m "hello world"

The options for `mosquitto_pub` are the same as `mosquitto_sub`, though this time we use the additional `-m` option to specify our message. Hit `ENTER`, and you should see **hello world** pop up in the other terminal. You’ve sent your first MQTT message!

Press `CTRL+C` in the second terminal to exit out of `mosquitto_sub`, but keep the connection to the server open. We’ll use it again for another test in Step 5.

Next, we’ll secure our installation with SSL using [Certbot](https://certbot.eff.org/), the new Let’s Encrypt client.

## Step 2 — Installing Certbot for Let’s Encrypt Certificates

Let’s Encrypt is a new service offering free SSL certificates through an automated API. There are many clients that can talk to the API, and Debian includes the official client in their default repository, but it’s a bit out of date and lacks one important feature we need.

Instead, we’ll install the client from Debian’s `backports` repository. This is an official repository that makes newer versions of select software available to already released versions of Debian. We need to add the repository to our APT sources list, just like we did in the previous step.

First, open a new file in `/etc/apt/sources.list.d/`.

    sudo nano /etc/apt/sources.list.d/backports.list

Paste the following line into the file:

/etc/apt/sources.list.d/backports.list

    deb http://mirrors.digitalocean.com/debian jessie-backports main

Save the file, and close out of the editor. Afterwards, update the package information.

    sudo apt-get update

And finally, install the official Let’s Encrypt client, called Certbot, telling APT to use `jessie-backports` as its source:

    sudo apt-get install certbot -t jessie-backports

Now that we have Certbot installed, let’s run it to get our certificate.

## Step 3 — Running Certbot

Certbot needs to answer a cryptographic challenge issued by the Let’s Encrypt API in order to prove we control our domain. It uses ports `80` (HTTP) and/or `443` (HTTPS) to accomplish this. We’ll only use port `80`, so allow incoming traffic on that port.

    sudo ufw allow http

    OutputRule added
    Rule added (v6)

We can now run Certbot to get our certificate. We’ll use the `--standalone` option to tell Certbot to handle the HTTP challenge request on its own, and `--standalone-supported-challenges http-01` limits the communication to port `80`. `-d` specifies the domain you’d like a certificate for, and `certonly` tells Certbot to just retrieve the certificate without doing any other configuration steps.

    sudo certbot certonly --standalone --standalone-supported-challenges http-01 -d mqtt.example.com

When running the command, you will be prompted to enter an email address and agree to the terms of service. After doing so, you will see a message telling you the process was successful and where your certificates are stored.

We’ve got our certificates. Now we need to make sure Certbot renews them automatically when they’re about to expire.

## Step 4 — Setting Up Certbot Automatic Renewals

Let’s Encrypt’s certificates are only valid for ninety days. This is to encourage users to automate their certificate renewal process. We’ll need to set up a command that regularly checks for expiring certificates and renews them automatically.

To run the renewal check daily, we will use [`cron`](how-to-use-cron-to-automate-tasks-on-a-vps), a standard system service for running periodic jobs. We tell `cron` what to do by opening and editing a file called a `crontab`.

    sudo crontab -e

You’ll be prompted to select a text editor. Choose your favorite, and you’ll be presented with the default `crontab` which has some help text in it. Paste in the following line at the end of the file, then save and close it.

crontab

    . . .
    15 3 * * * certbot renew --noninteractive --post-hook "systemctl restart mosquitto"

The `15 3 * * *` part of this line means “run the following command at 3:15 am, every day”. The `renew` command for Certbot will check all certificates installed on the system and update any that are set to expire in less than thirty days. `--noninteractive` tells Certbot not to wait for user input.

`--post-hook "systemctl restart mosquitto"` will restart Mosquitto to pick up the new certificate, but only if the certificate was renewed. This `post-hook` feature is what older versions of the Let’s Encrypt client lacked, and why we installed from backports instead of the default Debian repository. Without it, we’d have to restart Mosquitto every day, even if no certificates were actually updated. Though your MQTT clients should be configured to reconnect automatically, it’s wise to avoid interrupting them daily for no good reason.

Now that automatic certificate renewal is all set, we’ll get back to configuring Mosquitto to be more secure.

## Step 5 — Configuring MQTT Passwords

Let’s configure Mosquitto to use passwords so we can control who can publish messages. Mosquitto includes a utility to generate a special password file called `mosquitto_passwd`. This command will prompt you to enter a password for the specified username, and place the results in `/etc/mosquitto/passwd`.

    sudo mosquitto_passwd -c /etc/mosquitto/passwd sammy

Now create a new configuration file for Mosquitto and tell it to use this password file to require logins for all connections.

    sudo nano /etc/mosquitto/conf.d/default.conf

This should open an empty file. Paste in the following:

/etc/mosquitto/conf.d/default.conf

    allow_anonymous false
    password_file /etc/mosquitto/passwd

`allow_anonymous false` disables all non-authenticated connections, and the `password_file` line tells Mosquitto where to look for user and password information. Save and exit the file.

Now you need to restart Mosquitto and test your changes.

    sudo systemctl restart mosquitto

First, try to publish a message without a password.

    mosquitto_pub -h localhost -t "test" -m "hello world"

The message should be rejected:

    OutputConnection Refused: not authorised.
    Error: The connection was refused.

Before we try again with the password, switch to your second terminal window again, and subscribe to the **test** topic, using the username and password this time:

    mosquitto_sub -h localhost -t test -u "sammy" -P "password"

It should connect and sit, waiting for messages. You can leave this terminal open and connected for the rest of the tutorial, as we’ll periodically send it test messages.

Now publish a message with your other terminal, again using the username and password.

    mosquitto_pub -h localhost -t "test" -m "hello world" -u "sammy" -P "password"

The message should go through as in Step 1. We’ve successfully added password protection to Mosquitto. Unfortunately, we’re sending passwords unencrypted over the internet. We’ll fix that next by adding SSL encryption to Mosquitto.

## Step 6 — Configuring MQTT SSL

To enable SSL encryption, we need to tell Mosquitto where our Let’s Encrypt certificates are stored. Open up the configuration file we previously started.

    sudo nano /etc/mosquitto/conf.d/default.conf

Paste in the following at the end of the file, leaving the two lines we already added:

/etc/mosquitto/conf.d/default.conf

    . . .
    listener 1883 localhost
    
    listener 8883
    certfile /etc/letsencrypt/live/mqtt.example.com/cert.pem
    cafile /etc/letsencrypt/live/mqtt.example.com/chain.pem
    keyfile /etc/letsencrypt/live/mqtt.example.com/privkey.pem

We’re adding two separate `listener` blocks to the config. The first, `listener 1883 localhost`, updates the default MQTT listener on port `1883`, which is what we’ve been connecting to so far. `1883` is the standard unencrypted MQTT port. The `localhost` portion of the line instructs Mosquitto to only bind this port to the localhost interface, so it’s not accessible externally. External requests would have been blocked by our firewall anyway, but it’s good to be explicit.

`listener 8883` sets up an encrypted listener on port `8883`. This is the standard port for MQTT + SSL, often referred to as MQTTS. The next three lines, `certfile`, `cafile`, and `keyfile`, all point Mosquitto to the appropriate Let’s Encrypt files to set up the encrypted connections.

Save and exit the file, then restart Mosquitto to update the settings.

    sudo systemctl restart mosquitto

Update the firewall to allow connections to port `8883`.

    sudo ufw allow 8883

    OutputRule added
    Rule added (v6)

Now test again using `mosquitto_pub`, with a few different options for SSL:

    mosquitto_pub -h mqtt.example.com -t test -m "hello again" -p 8883 --capath /etc/ssl/certs/ -u "sammy" -P "password"

Note that we’re using the full hostname instead of `localhost`. Because our SSL certificate is issued for `mqtt.example.com`, if we attempt a secure connection to `localhost` we’ll get an error saying the hostname does not match the certificate hostname (even though they both point to the same Mosquitto server).

`--capath /etc/ssl/certs/` enables SSL for `mosquitto_pub`, and tells it where to look for root certificates. These are typically installed by your operating system, so the path is different for macOS, Windows, etc. `mosquitto_pub` uses the root certificate to verify that the Mosquitto server’s certificate was properly signed by the Let’s Encrypt certificate authority. It’s important to note that `mosquitto_pub` and `mosquitto_sub` will not attempt an SSL connection without this option (or the similar `--cafile` option), even if you’re connecting to the standard secure port of `8883`.

If all goes well with the test, you’ll see **hello again** show up in the other `mosquitto_sub` terminal. This means your server is fully set up! If you’d like to extend the MQTT protocol to work with websockets, you can follow the final step.

## Step 7 — Configuring MQTT Over Websockets (Optional)

In order to speak MQTT using JavaScript from within web browsers, the protocol was adapted to work over standard websockets. If you don’t need this functionality, you may skip this step.

We need to add one more `listener` block to our Mosqiutto config.

    sudo nano /etc/mosquitto/conf.d/default.conf

At the end of the file, add the following:

/etc/mosquitto/conf.d/default.conf

    . . .
    listener 8083
    protocol websockets
    certfile /etc/letsencrypt/live/mqtt.example.com/cert.pem
    cafile /etc/letsencrypt/live/mqtt.example.com/chain.pem
    keyfile /etc/letsencrypt/live/mqtt.example.com/privkey.pem

This is mostly the same as the previous block, except for the port number and the `protocol websockets` line. There is no official standardized port for MQTT over websockets, but `8083` is the most common.

Save and exit the file, then restart Mosquitto.

    sudo systemctl restart mosquitto

Now, open up port `8083` in the firewall.

    sudo ufw allow 8083

To test this functionality, we’ll use a public, browser-based MQTT client. There are a few out there, but [mqtt-admin](https://hobbyquaker.github.io/mqtt-admin/) is simple and straightforward. [Open mqtt-admin in your browser](https://hobbyquaker.github.io/mqtt-admin/). You’ll see the following:

![mqtt-admin's initial screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mosquitto-debian/SJRJgLX.png)

Fill out the connection information as follows:

- **Protocol** should be **wss** (which stands for **w** eb **s** ocket **s** ecure).
- **Host** should be the domain for your Mosquitto server, `mqtt.example.com`.
- **Port** should be `8083`.
- **User** should be your Mosquitto username; here, we used **sammy**.
- **Password** should be the password you chose.
- **ClientId** can be left to the default value, **mqtt-admin**.

After pressing **Save Settings** , `mqtt-admin` will connect to your Mosquitto server. In the next screen, fill out **Topic** as **test** , enter any message for **Payload** , then press **Publish**. The message will show up in the `mosquitto_sub` terminal.

## Conclusion

We’ve now set up a secure, password-protected MQTT server, with auto-renewing SSL certificates from the Let’s Encrypt service. This will serve as a robust and secure messaging platform for whatever projects you dream up. Some popular software and hardware that works well with the MQTT protocol includes:

- [OwnTracks](http://owntracks.org/), an open-source geo-tracking app you can install on your phone. OwnTracks will periodically report position information to your MQTT server, which you could then store and display on a map, or create alerts and activate IoT hardware based on your location.
- [Node-RED](https://nodered.org/) is a browser-based graphical interface for “wiring together” the Internet of Things. You drag the output of one node to the input of another, and can route information through filters, between various protocols, into databases, and so on. MQTT is very well supported by Node-RED.
- The [ESP8266](https://espressif.com/en/products/hardware/esp8266ex/overview) is an inexpensive wifi microcontroller with MQTT capabilities. You could wire one up to publish temperature data to a topic, or perhaps subscribe to a barometric pressure topic and sound a buzzer when a storm is coming!

These are just a few popular examples from the MQTT ecosystem. There is much more hardware and software out there that speaks the protocol. If you already have a favorite hardware platform, or software language, it probably has MQTT capabilities. Have fun getting your “things” talking to each other!
