---
author: Hazel Virdó
date: 2016-11-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04
---

# How To Install MySQL on Ubuntu 16.04

## Introduction

[MySQL](https://www.mysql.com/) is an open-source database management system, commonly installed as part of the popular [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04) (Linux, Apache, MySQL, PHP/Python/Perl) stack. It uses a relational database and SQL (Structured Query Language) to manage its data.

The short version of the installation is simple: update your package index, install the `mysql-server` package, and then run the included security script.

    sudo apt-get update
    sudo apt-get install mysql-server
    mysql_secure_installation

This tutorial will explain how to install MySQL version 5.7 on a Ubuntu 16.04 server. However, if you’re looking to update an existing MySQL installation to version 5.7, you can read [this MySQL 5.7 update guide](how-to-prepare-for-your-mysql-5-7-upgrade) instead.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [this initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

## Step 1 — Installing MySQL

On Ubuntu 16.04, only the latest version of MySQL is included in the APT package repository by default. At the time of writing, that’s MySQL 5.7

To install it, simply update the package index on your server and install the default package with `apt-get`.

    sudo apt-get update
    sudo apt-get install mysql-server

You’ll be prompted to create a root password during the installation. Choose a secure one and make sure you remember it, because you’ll need it later. Next, we’ll finish configuring MySQL.

## Step 2 — Configuring MySQL

For fresh installations, you’ll want to run the included security script. This changes some of the less secure default options for things like remote root logins and sample users. On older versions of MySQL, you needed to initialize the data directory manually as well, but this is done automatically now.

Run the security script.

    mysql_secure_installation

This will prompt you for the root password you created in Step 1. You can press `Y` and then `ENTER` to accept the defaults for all the subsequent questions, with the exception of the one that asks if you’d like to change the root password. You just set it in Step 1, so you don’t have to change it now. For a more detailed walkthrough of these options, you can see [this step of the LAMP installation tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04#step-2-install-mysql).

To initialize the MySQL data directory, you would use `mysql_install_db` for versions before 5.7.6, and `mysqld --initialize` for 5.7.6 and later. However, if you installed MySQL from the Debian distribution, like in Step 1, the data directory was initialized automatically; you don’t have to do anything. If you try running the command anyway, you’ll see the following error:

Output

    2016-03-07T20:11:15.998193Z 0 [ERROR] --initialize specified but the data directory has files in it. Aborting.

Finally, let’s test the MySQL installation.

## Step 3 — Testing MySQL

Regardless of how you installed it, MySQL should have started running automatically. To test this, check its status.

    systemctl status mysql.service

You’ll see output similar to the following:

Output

    ● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: en
       Active: active (running) since Wed 2016-11-23 21:21:25 UTC; 30min ago
     Main PID: 3754 (mysqld)
        Tasks: 28
       Memory: 142.3M
          CPU: 1.994s
       CGroup: /system.slice/mysql.service
               └─3754 /usr/sbin/mysqld

If MySQL isn’t running, you can start it with `sudo systemctl start mysql`.

For an additional check, you can try connecting to the database using the `mysqladmin` tool, which is a client that lets you run administrative commands. For example, this command says to connect to MySQL as **root** (`-u root`), prompt for a password (`-p`), and return the version.

    mysqladmin -p -u root version

You should see output similar to this:

Output

    mysqladmin Ver 8.42 Distrib 5.7.16, for Linux on x86_64
    Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Server version 5.7.16-0ubuntu0.16.04.1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 30 min 54 sec
    
    Threads: 1 Questions: 12 Slow queries: 0 Opens: 115 Flush tables: 1 Open tables: 34 Queries per second avg: 0.006

This means MySQL is up and running.

## Conclusion

You now have a basic MySQL setup installed on your server. Here are a few examples of next steps you can take:

- [Implement some additional security measures](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Relocate the data directory](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
- [Manage your MySQL servers with SaltStack](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
- [Learn more about MySQL commands](a-basic-mysql-tutorial)
