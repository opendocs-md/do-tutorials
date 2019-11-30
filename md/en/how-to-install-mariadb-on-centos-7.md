---
author: Melissa Anderson
date: 2016-12-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-centos-7
---

# How To Install MariaDB on CentOS 7

## Introduction

[MariaDB](https://www.MariaDB.com/) is an open-source database management system, commonly installed as part of the popular [LEMP](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7) (Linux, Nginx, MySQL/MariaDB, PHP/Python/Perl) stack. It uses a relational database and SQL (Structured Query Language) to manage its data. MariaDB is a fork of MySQL managed by the original MySQL developers. It’s designed as a replacement for MySQL, uses some commands that reference `mysql`, and is the default package on CentOS 7.

In this tutorial, we will explain how to install the latest version of MariaDB on a CentOS 7 server. If you specifically need MySQL, see the [How to Install MySQL on CentOS 7](how-to-install-mysql-on-centos-7) guide. If you’re wondering about MySQL vs. MariaDB, MariaDB is the preferred package and should work seamlessly in place of MySQL.

## Prerequisites

To follow this tutorial, you will need:

- A CentOS 7 with a non-root user with `sudo` privileges. You can learn more about how to set up a user with these privileges in the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) guide.

## Step 1 — Installing MariaDB

We’ll use Yum to install the MariaDB package, pressing `y` when prompted to confirm that we wish to proceed:

    sudo yum install mariadb-server

Once the installation is complete, we’ll start the daemon with the following command:

    sudo systemctl start mariadb

`systemctl` doesn’t display the outcome of all service management commands, so to be sure we succeeded, we’ll use the following command:

    sudo systemctl status mariadb

If MariaDB has successfully started, the output should contain “Active: active (running)` and the final line should look something like:

    Dec 01 19:06:20 centos-512mb-sfo2-01 systemd[1]: Started MariaDB database server.

Next, let’s take a moment to ensure that MariaDB starts at boot, using the `systemctl enable` command, which will create the necessary symlinks.

    sudo systemctl enable mariadb

    OutputCreated symlink from /etc/systemd/system/multi-user.target.wants/mariadb.service to /usr/lib/systemd/system/mariadb.service.

Next, we’ll turn our attention to securing our installation.

## Step 2 — Securing the MariaDB Server

MariaDB includes a security script to change some of the less secure default options for things like remote root logins and sample users. Use this command to run the security script:

    sudo mysql_secure_installation

The script provides a detailed explanation for every step. The first prompts asks for the root password, which hasn’t been set so we’ll press `ENTER` as it recommends. Next, we’ll be prompted to set that root password, which we’ll do.

Then, we’ll accept all the security suggestions by pressing `Y` and then `ENTER` for the remaining prompts, which will remove anonymous users, disallow remote root login, remove the test database, and reload the privilege tables.

Finally, now that we’ve secured the installation, we’ll verify it’s working.

## Step 3 — Testing the Installation

We can verify our installation and get information about it by connecting with the `mysqladmin` tool, a client that lets you run administrative commands. Use the following command to connect to MariaDB as **root** (`-u root`), prompt for a password (`-p`), and return the version.

    mysqladmin -u root -p version

You should see output similar to this:

Output

    mysqladmin Ver 9.0 Distrib 5.5.50-MariaDB, for Linux on x86_64
    Copyright (c) 2000, 2016, Oracle, MariaDB Corporation Ab and others.
    
    
    Server version 5.5.50-MariaDB
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/lib/mysql/mysql.sock
    Uptime: 4 min 4 sec
    
    
    Threads: 1 Questions: 42 Slow queries: 0 Opens: 1 Flush tables: 2 Open tables: 27 Queries per second avg: 0.172

This indicates the installation has been successful.

## Conclusion

In this tutorial, we’ve installed and secured MariaDB on a CentOS 7 server. To learn more about using MariaDB, this guide to [learning more about MySQL commands](a-basic-mysql-tutorial) can help. You might also consider [implementing some additional security measures](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps).
