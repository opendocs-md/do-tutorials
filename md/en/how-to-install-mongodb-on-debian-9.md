---
author: Brian Boucheron, Mateusz Papiernik
date: 2018-09-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-debian-9
---

# How to Install MongoDB on Debian 9

## Introduction

[MongoDB](https://www.mongodb.com/) is a free and open-source NoSQL document database used commonly in modern web applications.

In this tutorial you will install MongoDB, manage its service, and optionally enable remote access.

## Prerequisites

To follow this tutorial, you will need one Debian 9 server set up by following this [initial server setup tutorial](initial-server-setup-with-debian-9), including a sudo-enabled non-root user and a firewall.

## Step 1 — Installing MongoDB

Debian 9’s official package repositories include a slightly-out-of-date version of MongoDB, which means we’ll install from the official MongoDB repo instead.

First, we need to add the MongoDB signing key with `apt-key add`. We’ll need to make sure the `curl` command is installed before doing so:

    sudo apt install curl

Next we download the key and pass it to `apt-key add`:

    curl https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -

Next we’ll create a source list for the MongoDB repo, so `apt` knows where to download from. First open the source list file in a text editor:

    sudo nano /etc/apt/sources.list.d/mongodb-org-4.0.list

This will open a new blank file. Paste in the following:

/etc/apt/sources.list.d/mongodb-org-4.0.list

    deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main

Save and close the file, then update your package cache:

    sudo apt update

Install the `mongodb-org` package to install the server and some supporting tools:

    sudo apt-get install mongodb-org

Finally, enable and start the `mongod` service to get your MongoDB database running:

    sudo systemctl enable mongod
    sudo systemctl start mongod

We’ve now installed and started the latest stable version of MongoDB, along with helpful management tools for the MongoDB server.

Next, let’s verify that the server is running and works correctly.

## Step 2 — Checking the Service and Database

We started MongoDB service in the previous step, now let’s verify that it is started and the database is working.

First, check the service’s status:

    sudo systemctl status mongod

You’ll see this output:

    Output● mongod.service - MongoDB Database Server
       Loaded: loaded (/lib/systemd/system/mongod.service; enabled; vendor preset: enabled)
       Active: active (running) since Wed 2018-09-05 16:59:56 UTC; 3s ago
         Docs: https://docs.mongodb.org/manual
     Main PID: 4321 (mongod)
        Tasks: 26
       CGroup: /system.slice/mongod.service
               └─4321 /usr/bin/mongod --config /etc/mongod.conf

According to `systemd`, the MongoDB server is up and running.

We can verify this further by actually connecting to the database server and executing a diagnostic command

Execute this command:

    mongo --eval 'db.runCommand({ connectionStatus: 1 })'

This will output the current database version, the server address and port, and the output of the status command:

    OutputMongoDB shell version v4.0.2
    connecting to: mongodb://127.0.0.1:27017
    MongoDB server version: 4.0.2
    {
        "authInfo" : {
            "authenticatedUsers" : [],
            "authenticatedUserRoles" : []
        },
        "ok" : 1
    }

A value of `1` for the `ok` field in the response indicates that the server is working properly.

Next, we’ll look at how to manage the server instance.

## Step 3 — Managing the MongoDB Service

MongoDB installs as a systemd service, which means that you can manage it using standard `systemd` commands alongside all other system services in Ubuntu.

To verify the status of the service, type:

    sudo systemctl status mongod

You can stop the server anytime by typing:

    sudo systemctl stop mongod

To start the server when it is stopped, type:

    sudo systemctl start mongod

You can also restart the server with a single command:

    sudo systemctl restart mongod

In the previous step we enabled MongoDB to start automatically with the server. If you wish to disable the automatic startup, type:

    sudo systemctl disable mongod

It’s just as easy to enable it again. To do this, use:

    sudo systemctl enable mongod

Next, let’s adjust the firewall settings for our MongoDB installation.

## Step 4 — Adjusting the Firewall (Optional)

Assuming you have followed the [initial server setup tutorial](initial-server-setup-with-debian-9) instructions to enable the firewall on your server, the MongoDB server will be inaccessible from the internet.

If you intend to use the MongoDB server only locally with applications running on the same server, this is the recommended and secure setting. However, if you would like to be able to connect to your MongoDB server from the internet, you have to allow the incoming connections in `ufw`.

To allow access to MongoDB on its default port `27017` from everywhere, you could use `sudo ufw allow 27017`. However, enabling internet access to MongoDB server on a default installation gives anyone unrestricted access to the database server and its data.

In most cases, MongoDB should be accessed only from certain trusted locations, such as another server hosting an application. To accomplish this task, you can allow access on MongoDB’s default port while specifying the IP address of another server that will be explicitly allowed to connect:

    sudo ufw allow from your_other_server_ip/32 to any port 27017  

You can verify the change in firewall settings with `ufw`:

    sudo ufw status

You should see traffic to port `27017` allowed in the output:

Output

    Status: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    27017 ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    27017 (v6) ALLOW Anywhere (v6)

If you have decided to allow only a certain IP address to connect to MongoDB server, the IP address of the allowed location will be listed instead of `Anywhere` in the output.

You can find more advanced firewall settings for restricting access to services in [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands).

Even though the port is open, MongoDB is currently only listening on the local address `127.0.0.1`. To allow remote connections, add your server’s publicly-routable IP address to the `mongod.conf` file.

Open the MongoDB configuration file in your editor:

    sudo nano /etc/mongod.conf

Add your server’s IP address to the `bindIP` value:

/etc/mongod.conf

    . . .
    # network interfaces
    net:
      port: 27017
      bindIp: 127.0.0.1,your_server_ip
    . . .

Be sure to place a comma between the existing IP address and the one you added.

Save the file, exit the editor, and restart MongoDB:

    sudo systemctl restart mongod

MongoDB is now listening for remote connections, but anyone can access it. Follow Part 2 of [How to Install and Secure MongoDB on Ubuntu 16.04](how-to-install-and-secure-mongodb-on-ubuntu-16-04#part-two-securing-mongodb) to add an administrative user and lock things down further.

## Conclusion

You can find more in-depth tutorials on how to configure and use MongoDB in [these DigitalOcean community articles](https://www.digitalocean.com/community/search?q=mongodb). The official [MongoDB documentation](https://docs.mongodb.com/v3.2/) is also a great resource on the possibilities that MongoDB provides.
