---
author: Brian Hogan
date: 2017-02-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-debian-8
---

# How to Install MongoDB on Debian 8

## Introduction

[MongoDB](http://mongodb.com) is a free and open-source NoSQL document database used commonly in modern web applications. This tutorial will help you set up MongoDB on your server for use in a production application environment. You’ll install MongoDB and configure firewall rules to restrict access to MongoDB.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 8 server with a sudo non-root user. You can set up a user with these privileges in our [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8) guide.

## Step 1 — Installing MongoDB

MongoDB is already included in Debian’s package repositories, but the official MongoDB repository provides the most up-to-date version and is the recommended way of installing the software. In this step, we will add this official repository to our server.

Debian ensures the authenticity of software packages by verifying that they are signed with GPG keys, so we first have to import they key for the official MongoDB repository.

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6

After successfully importing the key, you will see:

Output

    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

Next, we have to add the MongoDB repository details so `apt` will know where to download the packages from.

Issue the following command to create a list file for MongoDB.

    echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list

After adding the repository details, update the packages list:

    sudo apt-get update

Now install the MongoDB package itself with the following command:

    sudo apt-get install -y mongodb-org

This installs the latest stable version of MongoDB, along with some helpful management tools for the MongoDB server.

Once MongoDB installs, start the service, and ensure it starts when your server reboots:

    sudo systemctl enable mongod.service
    sudo systemctl start mongod

Then use `systemctl` to check that the service has started properly:

    sudo systemctl status mongod

You should see the following output, indicating that the service is running:

Output

    ● mongod.service - High-performance, schema-free document-oriented database
       Loaded: loaded (/lib/systemd/system/mongod.service; enabled)
       Active: active (running) since Tue 2017-02-28 19:51:51 UTC; 7s ago
         Docs: https://docs.mongodb.org/manual
     Main PID: 8958 (mongod)
       CGroup: /system.slice/mongod.service
               └─8958 /usr/bin/mongod --quiet --config /etc/mongod.conf
    
    Feb 28 19:51:51 cart-61037 systemd[1]: Started High-performance, schema-free document-oriented database.

Now that MongoDB is successfully installed, let’s secure it with the software firewall.

## Step 2 — Securing MongoDB with a Firewall

in most cases, MongoDB should be accessed only from certain trusted locations, such as another server hosting an application. To accomplish this task, you can allow access on MongoDB’s default port while specifying the IP address of another server that will be explicitly allowed to connect. We’ll use the iptables firewall to set up this rule, as well as a few other rules to secure the system.

Before we write any rules, install the `iptables-persistent` package so you can save the rules you create. This way the rules will be applied every time you restart your server. Execute this command:

    sudo apt-get install iptables-persistent

**Note** : During the installation, you may be asked if you’d like to keep any existing rules. You can discard the existing rules.

Next, remove any existing rules that may be in place, just in case:

    sudo iptables -F

Then add a rule that allows established connections to continue talking. This way our existing SSH connection won’t be interrupted:

    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

Next, ensure that SSH access is allowed:

    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

If you plan to connect to MongoDB from a remote server, add these rules which will allow access to MongoDB’s default port from your application server:

    sudo iptables -A INPUT -s your_other_server_ip -p tcp --destination-port 27017 -m state --state NEW,ESTABLISHED -j ACCEPT
    sudo iptables -A OUTPUT -d your_other_server_ip -p tcp --source-port 27017 -m state --state ESTABLISHED -j ACCEPT

Next, add these rules which allow traffic on the local loopback device:

    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT

Finally, change the firewall policy to drop all other traffic:

    sudo iptables -P INPUT DROP

**Warning** : Changing the default policy to drop traffic that isn’t explicitly defined in rules will mean that everything is locked down. If you wish to allow additional traffic in the future, you’ll need to add new rules.

In addition, if you accidentally flush your rules, you will be locked out of your server. It’s a good idea to use `sudo iptables -P INPUT ACCEPT` to allow traffic through if you need to adjust your rules in the future. You can then use `sudo iptables -P INPUT DROP` to lock things down once you’re sure things are configured properly again.

Verify that the rules look correct:

    sudo iptables -S

You should see output similar to this:

    Output-P INPUT DROP
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -s your_other_server_ip/32 -p tcp -m tcp --dport 27017 -m state --state NEW,ESTABLISHED -j ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A OUTPUT -d your_other_server_ip/32 -p tcp -m tcp --sport 27017 -m state --state ESTABLISHED -j ACCEPT
    -A OUTPUT -o lo -j ACCEPT

Finally, save the rules:

    netfilter-persistent save

To learn more about these firewall rules, take a look at [How To Set Up a Firewall Using Iptables on Ubuntu 14.04](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04).

## Step 3 — Enabling Access to External Servers (Optional)

Current versions of MongoDB don’t accept external connections by default. If you’ve restricted access to specific IP addresses with the firewall, you can modify MongoDB’s configuration to accept remote connections.

Edit the MongoDB configuration file:

    sudo nano /etc/mongod.conf

Locate this section:

mongod.conf

    # network interfaces
    net:
      port: 27017
      bindIp: 127.0.0.1

Mongo is listening on the local loopback address, so it’ll only accept local connections. Change the `bindIp` value so it includes the IP address of your MongoDB server:

mongod.conf

    # network interfaces
    net:
      port: 27017
      bindIp: 127.0.0.1, your_server_ip

Save the file and exit the editor.

Then restart MongoDB to apply the change:

    sudo systemctl restart mongod

Your remote machine should now be able to connect. However, you may also want to [enable authentication](https://docs.mongodb.com/v3.2/tutorial/enable-authentication/) to secure your database even further.

## Conclusion

You can find more in-depth instructions regarding MongoDB installation and configuration in [these DigitalOcean community articles](https://www.digitalocean.com/community/search?q=mongodb). Be sure to [back up your data](how-to-create-and-use-mongodb-backups-on-ubuntu-14-04) and explore how to [encrypt data in transit](https://docs.mongodb.com/manual/core/security-transport-encryption/).
