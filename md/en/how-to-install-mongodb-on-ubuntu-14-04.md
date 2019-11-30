---
author: Mateusz Papiernik
date: 2015-06-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mongodb-on-ubuntu-14-04
---

# How To Install MongoDB on Ubuntu 14.04

## Introduction

MongoDB is a free and open-source NoSQL document database used commonly in modern web applications. This tutorial will help you set up MongoDB on your server for a production application environment.

**Note:** MongoDB can be installed automatically on your Droplet by adding [this script](http://do.co/1C60X0a) to its User Data when launching it. Check out [this tutorial](an-introduction-to-droplet-metadata) to learn more about Droplet User Data.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 14.04 Droplet.

- A sudo non-root user, which you can set up by following this [initial server setup tutorial](initial-server-setup-with-ubuntu-14-04).

## Step 1 — Importing the Public Key

In this step, we will import the MongoDB GPG public key.

MongoDB is already included in Ubuntu package repositories, but the official MongoDB repository provides most up-to-date version and is the recommended way of installing the software. Ubuntu ensures the authenticity of software packages by verifying that they are signed with GPG keys, so we first have to import they key for the official MongoDB repository.

To do so, execute:

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

After successfully importing the key you will see:

Output

    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

## Step 2 — Creating a List File

Next, we have to add the MongoDB repository details so APT will know where to download the packages from.

Issue the following command to create a list file for MongoDB.

    echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list

After adding the repository details, we need to update the packages list.

    sudo apt-get update

## Step 3 — Installing and Verifying MongoDB

Now we can install the MongoDB package itself.

    sudo apt-get install -y mongodb-org

This command will install several packages containing latest stable version of MongoDB along with helpful management tools for the MongoDB server.

After package installation MongoDB will be automatically started. You can check this by running the following command.

    service mongod status

If MongoDB is running, you’ll see an output like this (with a different process ID).

Output

    mongod start/running, process 1611

You can also stop, start, and restart MongoDB using the `service` command (e.g. `service mongod stop`, `service mongod start`).

## Conclusion

You can find more in-depth instructions regarding MongoDB installation and configuration in [these DigitalOcean community articles](https://www.digitalocean.com/community/search?q=mongodb).
