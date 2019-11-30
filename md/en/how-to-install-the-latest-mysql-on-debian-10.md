---
author: Justin Ellingwood, Brian Boucheron, Hanif Jetha
date: 2019-07-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-latest-mysql-on-debian-10
---

# How To Install the Latest MySQL on Debian 10

## Introduction

[MySQL](https://www.mysql.com/) is a prominent open source database management system used to store and retrieve data for a wide variety of popular applications. MySQL is the **M** in the _LAMP_ stack, a commonly used set of open source software that also includes Linux, the Apache web server, and the PHP programming language.

In Debian 10, MariaDB, a community fork of the MySQL project, is packaged as the default MySQL variant. While MariaDB works well in most cases, if you need features found only in Oracle’s MySQL, you can install and use packages from a repository maintained by the MySQL developers.

To install the latest version of MySQL, we’ll add this repository, install the MySQL software itself, secure the install, and finally we’ll test that MySQL is running and responding to commands.

## Prerequisites

Before starting this tutorial, you will need:

- One Debian 10 server set up by following [this initial server setup guide](initial-server-setup-with-debian-10), including a non- **root** user with `sudo` privileges and a firewall.

## Step 1 — Adding the MySQL Software Repository

The MySQL developers provide a `.deb` package that handles configuring and installing the official MySQL software repositories. Once the repositories are set up, we’ll be able to use Debian’s standard `apt` command to install the software.

Before we do this, we need to install the prerequisite [GnuPG](https://gnupg.org/) package, an open-source implementation of the [OpenPGP standard](https://en.wikipedia.org/wiki/Pretty_Good_Privacy#OpenPGP).

Let’s begin by updating the local package index to reflect the latest upstream changes:

    sudo apt update

Then, install the `gnupg` package:

    sudo apt install gnupg

After confirming the installation, apt will install `gnupg` and its dependencies.

Next, we’ll download the MySQL `.deb` package with `wget` and then install it using the `dpkg` command.

Load [the MySQL download page](https://dev.mysql.com/downloads/repo/apt/) in your web browser. Find the **Download** button in the lower-right corner and click through to the next page. This page will prompt you to log in or sign up for an Oracle web account. We can skip that and instead look for the link that says **No thanks, just start my download**. Right-click the link and select **Copy Link Address** (this option may be worded differently, depending on your browser).

Now we’re going to download the file. On your server, move to a directory you can write to. Download the file using `wget`, remembering to paste the address you just copied in place of the highlighted portion below:

    cd /tmp
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb

The file should now be downloaded in our current directory. List the files to make sure:

    ls

You should see the filename listed:

    Outputmysql-apt-config_0.8.13-1_all.deb
    . . .

Now we’re ready to install:

    sudo dpkg -i mysql-apt-config*

`dpkg` is used to install, remove, and inspect `.deb` software packages. The `-i` flag indicates that we’d like to install from the specified file.

During the installation, you’ll be presented with a configuration screen where you can specify which version of MySQL you’d prefer, along with an option to install repositories for other MySQL-related tools. The defaults will add the repository information for the latest stable version of MySQL and nothing else. This is what we want, so use the down arrow to navigate to the `Ok` menu option and hit `ENTER`.

The package will now finish adding the repository. Refresh your `apt` package cache to make the new software packages available:

    sudo apt update

Now that we’ve added the MySQL repositories, we’re ready to install the actual MySQL server software. If you ever need to update the configuration of these repositories, just run `sudo dpkg-reconfigure mysql-apt-config`, select new options, and then `sudo apt-get update` to refresh your package cache.

## Step 2 — Installing MySQL

Having added the repository and with our package cache freshly updated, we can now use `apt` to install the latest MySQL server package:

    sudo apt install mysql-server

`apt` will look at all available `mysql-server` packages and determine that the MySQL provided package is the newest and best candidate. It will then calculate package dependencies and ask you to approve the installation. Type `y` then `ENTER`. The software will install.

You will be asked to set a **root** password during the configuration phase of the installation. Choose and confirm a secure password to continue. Next, a prompt will appear asking for you to select a default authentication plugin. Read the display to understand the choices. If you are not sure, choosing **Use Strong Password Encryption** is safer.

MySQL should be installed and running now. Let’s check using `systemctl`:

    sudo systemctl status mysql

    ● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2019-07-25 17:20:12 UTC; 3s ago
         Docs: man:mysqld(8)
               http://dev.mysql.com/doc/refman/en/using-systemd.html
      Process: 2673 ExecStartPre=/usr/share/mysql-8.0/mysql-systemd-start pre (code=exited, status=0/SUCCESS)
     Main PID: 2709 (mysqld)
       Status: "Server is operational"
        Tasks: 39 (limit: 4915)
       Memory: 378.4M
       CGroup: /system.slice/mysql.service
               └─2709 /usr/sbin/mysqld
    
    Jul 25 17:20:10 sammy systemd[1]: Starting MySQL Community Server...
    Jul 25 17:20:12 sammy systemd[1]: Started MySQL Community Server.

The `Active: active (running)` line means MySQL is installed and running. Now we’ll make the installation a little more secure.

## Step 3 — Securing MySQL

MySQL comes with a command we can use to perform a few security-related updates on our new install. Let’s run it now:

    mysql_secure_installation

This will ask you for the MySQL **root** password that you set during installation. Type it in and press `ENTER`. Now we’ll answer a series of yes or no prompts. Let’s go through them:

First, we are asked about the **validate password plugin** , a plugin that can automatically enforce certain password strength rules for your MySQL users. Enabling this is a decision you’ll need to make based on your individual security needs. Type `y` and `ENTER` to enable it, or just hit `ENTER` to skip it. If enabled, you will also be prompted to choose a level from 0–2 for how strict the password validation will be. Choose a number and hit `ENTER` to continue.

Next you’ll be asked if you want to change the **root** password. Since we just created the password when we installed MySQL, we can safely skip this. Hit `ENTER` to continue without updating the password.

The rest of the prompts can be answered **yes**. You will be asked about removing the **anonymous** MySQL user, disallowing remote **root** login, removing the **test** database, and reloading privilege tables to ensure the previous changes take effect properly. These are all a good idea. Type `y` and hit `ENTER` for each.

The script will exit after all the prompts are answered. Now our MySQL installation is reasonably secured. Let’s test it again by running a client that connects to the server and returns some information.

## Step 4 – Testing MySQL

`mysqladmin` is a command line administrative client for MySQL. We’ll use it to connect to the server and output some version and status information:

    mysqladmin -u root -p version

The `-u root` portion tells `mysqladmin` to log in as the MySQL **root** user, `-p` instructs the client to ask for a password, and `version` is the actual command we want to run.

The output will let us know what version of the MySQL server is running, its uptime, and some other status information:

    Outputmysqladmin Ver 8.0.17 for Linux on x86_64 (MySQL Community Server - GPL)
    Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Server version 8.0.17
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 3 min 9 sec
    
    Threads: 2 Questions: 10 Slow queries: 0 Opens: 128 Flush tables: 3 Open tables: 48 Queries per second avg: 0.052

This output confirms that you’ve successfully installed and secured the latest MySQL server.

## Conclusion

You’ve now installed the latest stable version of MySQL, which should work for many popular applications.
