---
author: Hazel Virdó
date: 2016-03-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-14-04
---

# How To Install MySQL on Ubuntu 14.04

## Introduction

[MySQL](https://www.mysql.com/) is an open-source database management system, commonly installed as part of the popular [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04) (Linux, Apache, MySQL, PHP/Python/Perl) stack. It uses a relational database and SQL (Structured Query Language) to manage its data.

The short version of the installation is simple: update your package index, install the `mysql-server` package, and then run the included security and database initialization scripts.

    sudo apt-get update
    sudo apt-get install mysql-server
    sudo mysql_secure_installation
    sudo mysql_install_db

This tutorial will explain how to install MySQL version 5.5, 5.6, or 5.7 on a Ubuntu 14.04 server. If you want more detail on these installation instructions, or if you want to install a specific version of MySQL, read on. However, if you’re looking to update an existing MySQL installation to version 5.7, you can read [this MySQL 5.7 update guide](how-to-prepare-for-your-mysql-5-7-upgrade) instead.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 14.04 Droplet with a [sudo non-root user](initial-server-setup-with-ubuntu-14-04).

## Step 1 — Installing MySQL

There are two ways to install MySQL. You can either use one of the versions included in the APT package repository by default (which are 5.5 and 5.6), or you can install the latest version (currently 5.7) by manually adding MySQL’s repository first.

If you want to install a specific version of MySQL, follow the appropriate section below. To help you decide which version is best for you, you can read [MySQL’s introduction to MySQL 5.5](https://dev.mysql.com/tech-resources/articles/introduction-to-mysql-55.html), then [what’s new in MySQL 5.6](http://dev.mysql.com/tech-resources/articles/whats-new-in-mysql-5.6.html) and [what’s new in MySQL 5.7](http://dev.mysql.com/doc/refman/5.7/en/mysql-nutshell.html).

If you’re not sure, you can just use the `mysql-server` APT package, which just installs the latest version for your Linux distribution. At the time of writing, that’s 5.5, but you can always update to another version later.

To install MySQL this way, update the package index on your server and install the package with `apt-get`.

    sudo apt-get update
    sudo apt-get install mysql-server

You’ll be prompted to create a root password during the installation. Choose a secure one and make sure you remember it, because you’ll need it later. Move on to step two from here.

### Installing MySQL 5.5 or 5.6

If you want to install MySQL 5.5 or 5.6 specifically, the process is still very straightforward. First, update the package index on your server.

    sudo apt-get update

Then, to install MySQL 5.5, install the `mysql-server-5.5` package.

    sudo apt-get install mysql-server-5.5

To install MySQL 5.6, install the `mysql-server-5.6` package instead.

    sudo apt-get install mysql-server-5.6

For both options, you’ll be prompted to create a root password during the installation. Choose a secure one and make sure you remember it, because you’ll need it later.

### Installing MySQL 5.7

If you want to install MySQL 5.7, you’ll need to add the newer APT package repository from [the MySQL APT repository page](http://dev.mysql.com/downloads/repo/apt/). Click **Download** on the bottom right, then copy the link on the next page from **No thanks, just start my download**. Download the `.deb` package to your server.

    wget http://dev.mysql.com/get/mysql-apt-config_0.6.0-1_all.deb

Next, install it using `dpkg`.

    sudo dpkg -i mysql-apt-config_0.6.0-1_all.deb

You’ll see a prompt that asks you which MySQL product you want to configure. The **MySQL Server** option, which is highlighted, should say **mysql-5.7**. If it doesn’t, press `ENTER`, then scroll down to **mysql-5.7** using the arrow keys, and press `ENTER` again.

Once the option says **mysql-5.7** , scroll down on the main menu to **Apply** and press `ENTER` again. Now, update your package index.

    sudo apt-get update

Finally, install the `mysql-server` package, which now contains MySQL 5.7.

    sudo apt-get install mysql-server

You’ll be prompted to create a root password during the installation. Choose a secure one and make sure you remember it, because you’ll need it later.

## Step 2 — Configuring MySQL

First, you’ll want to run the included security script. This changes some of the less secure default options for things like remote root logins and sample users.

    sudo mysql_secure_installation

This will prompt you for the root password you created in step one. You can press `ENTER` to accept the defaults for all the subsequent questions, with the exception of the one that asks if you’d like to change the root password. You just set it in step one, so you don’t have to change it now.

Next, we’ll initialize the MySQL data directory, which is where MySQL stores its data. How you do this depends on which version of MySQL you’re running. You can check your version of MySQL with the following command.

    mysql --version

You’ll see some output like this:

Output

    mysql Ver 14.14 Distrib 5.7.11, for Linux (x86_64) using EditLine wrapper

If you’re using a version of MySQL earlier than 5.7.6, you should initialize the data directory by running `mysql_install_db`.

    sudo mysql_install_db

**Note:** In MySQL 5.6, you might get an error that says **FATAL ERROR: Could not find my-default.cnf**. If you do, copy the `/usr/share/my.cnf` configuration file into the location that `mysql_install_db` expects, then rerun it.

    sudo cp /etc/mysql/my.cnf /usr/share/mysql/my-default.cnf
    sudo mysql_install_db

This is due to some changes made in MySQL 5.6 and a minor error in the APT package.

&nbsp;

The `mysql_install_db` command is deprecated as of MySQL 5.7.6. If you’re using version 5.7.6 or later, you should use `mysqld --initialize` instead.

However, if you installed version 5.7 from the Debian distribution, like in step one, the data directory was initialized automatically, so you don’t have to do anything. If you try running the command anyway, you’ll see the following error:

Output

    2016-03-07T20:11:15.998193Z 0 [ERROR] --initialize specified but the data directory has files in it. Aborting.

## Step 3 — Testing MySQL

Regardless of how you installed it, MySQL should have started running automatically. To test this, check its status.

    service mysql status

You’ll see the following output (with a different PID).

Output

    mysql start/running, process 2689

If MySQL isn’t running, you can start it with `sudo service mysql start`.

For an additional check, you can try connecting to the database using the `mysqladmin` tool, which is a client that lets you run administrative commands. For example, this command says to connect to MySQL as **root** (`-u root`), prompt for a password (`-p`), and return the version.

    mysqladmin -p -u root version

You should see output similar to this:

Output

    mysqladmin Ver 8.42 Distrib 5.5.47, for debian-linux-gnu on x86_64
    Copyright (c) 2000, 2015, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Server version 5.5.47-0ubuntu0.14.04.1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 4 min 15 sec
    
    Threads: 1 Questions: 602 Slow queries: 0 Opens: 189 Flush tables: 1 Open tables: 41 Queries per second avg: 2.360

This means MySQL is up and running.

## Conclusion

You now have a basic MySQL setup installed on your server. Here are a few examples of next steps you can take:

- Implement some [additional security measures](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Create hot backups with Percona XtraBackup](how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-ubuntu-14-04)
- Learn how to use MySQL with [Django applications](how-to-use-mysql-or-mariadb-with-your-django-application-on-ubuntu-14-04) or [Ruby on Rails applications](how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04)
- [Manage your MySQL servers with SaltStack](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
