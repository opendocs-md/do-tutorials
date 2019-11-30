---
author: Justin Ellingwood
date: 2018-09-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-9
---

# How To Install MariaDB on Debian 9

## Introduction

[MariaDB](https://mariadb.org/) is an open-source database management system, commonly installed in place of MySQL as part of the popular [LAMP](how-to-install-linux-apache-mariadb-php-lamp-stack-debian9) (Linux, Apache, MySQL, PHP/Python/Perl) stack. It uses a relational database and SQL (Structured Query Language) to manage its data. MariaDB was forked from MySQL in 2009 due to licensing concerns.

The short version of the installation is simple: update your package index, install the `mariadb-server` package (which points to MariaDB), and then run the included security script.

    sudo apt update
    sudo apt install mariadb-server
    sudo mysql_secure_installation

This tutorial will explain how to install MariaDB version 10.1 on a Debian 9 server.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 9 server set up by following [this initial server setup guide](initial-server-setup-with-debian-9), including a non- **root** user with `sudo` privileges and a firewall.

## Step 1 — Installing MariaDB

On Debian 9, MariaDB version 10.1 is included in the APT package repositories by default. It is marked as the default MySQL variant by the Debian MySQL/MariaDB packaging team.

To install it, update the package index on your server with `apt`:

    sudo apt update

Then install the package:

    sudo apt install mariadb-server

This will install MariaDB, but will not prompt you to set a password or make any other configuration changes. Because this leaves your installation of MariaDB insecure, we will address this next.

## Step 2 — Configuring MariaDB

For fresh installations, you’ll want to run the included security script. This changes some of the less secure default options for things like remote **root** logins and sample users.

Run the security script:

    sudo mysql_secure_installation

This will take you through a series of prompts where you can make some changes to your MariaDB installation’s security options. The first prompt will ask you to enter the current database **root** password. Since we have not set one up yet, press `ENTER` to indicate “none”.

The next prompt asks you whether you’d like to set up a database **root** password. Type `N` and then press `ENTER`. In Debian, the **root** account for MariaDB is tied closely to automated system maintenance, so we should not change the configured authentication methods for that account. Doing so would make it possible for a package update to break the database system by removing access to the administrative account. Later, we will cover how to optionally set up an additional administrative account for password access if socket authentication is not appropriate for your use case.

From there, you can press `Y` and then `ENTER` to accept the defaults for all the subsequent questions. This will remove some anonymous users and the test database, disable remote **root** logins, and load these new rules so that MariaDB immediately respects the changes you have made.

## Step 3 — (Optional) Adjusting User Authentication and Privileges

In Debian systems running MariaDB 10.1, the **root** MariaDB user is set to authenticate using the `unix_socket` plugin by default rather than with a password. This allows for some greater security and usability in many cases, but it can also complicate things when you need to allow an external program (e.g., phpMyAdmin) administrative rights.

Because the server uses the **root** account for tasks like log rotation and starting and stopping the server, it is best not to change the **root** account’s authentication details. Changing the account credentials in the `/etc/mysql/debian.cnf` may work initially, but package updates could potentially overwrite those changes. Instead of modifying the **root** account, the package maintainers recommend creating a separate administrative account if you need to set up password-based access.

To do so, we will be creating a new account called `admin` with the same capabilities as the **root** account, but configured for password authentication. To do this, open up the MariaDB prompt from your terminal:

    sudo mysql

Now, we can create a new user with **root** privileges and password-based access. Change the username and password to match your preferences:

    GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

Flush the privileges to ensure that they are saved and available in the current session:

    FLUSH PRIVILEGES;

Following this, exit the MariaDB shell:

    exit

Finally, let’s test the MariaDB installation.

## Step 4 — Testing MariaDB

When installed from the default repositories, MariaDB should start running automatically. To test this, check its status.

    sudo systemctl status mariadb

You’ll see output similar to the following:

Output

    ● mariadb.service - MariaDB database server
       Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
       Active: active (running) since Tue 2018-09-04 16:22:47 UTC; 2h 35min ago
      Process: 15596 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSIT
      Process: 15594 ExecStartPost=/etc/mysql/debian-start (code=exited, status=0/SUCCESS)
      Process: 15478 ExecStartPre=/bin/sh -c [! -e /usr/bin/galera_recovery] && VAR= ||   
      Process: 15474 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITI
      Process: 15471 ExecStartPre=/usr/bin/install -m 755 -o mysql -g root -d /var/run/mysql
     Main PID: 15567 (mysqld)
       Status: "Taking your SQL requests now..."
        Tasks: 27 (limit: 4915)
       CGroup: /system.slice/mariadb.service
               └─15567 /usr/sbin/mysqld
    
    Sep 04 16:22:45 deb-mysql1 systemd[1]: Starting MariaDB database server...
    Sep 04 16:22:46 deb-mysql1 mysqld[15567]: 2018-09-04 16:22:46 140183374869056 [Note] /usr/sbin/mysqld (mysqld 10.1.26-MariaDB-0+deb9u1) starting as process 15567 ...
    Sep 04 16:22:47 deb-mysql1 systemd[1]: Started MariaDB database server.

If MariaDB isn’t running, you can start it with `sudo systemctl start mariadb`.

For an additional check, you can try connecting to the database using the `mysqladmin` tool, which is a client that lets you run administrative commands. For example, this command says to connect to MariaDB as **root** and return the version using the Unix socket:

    sudo mysqladmin version

You should see output similar to this:

    Outputmysqladmin Ver 9.1 Distrib 10.1.26-MariaDB, for debian-linux-gnu on x86_64
    Copyright (c) 2000, 2017, Oracle, MariaDB Corporation Ab and others.
    
    Server version 10.1.26-MariaDB-0+deb9u1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 2 hours 44 min 46 sec
    
    Threads: 1 Questions: 36 Slow queries: 0 Opens: 21 Flush tables: 1 Open tables: 15 Queries per second avg: 0.003

If you configured a separate administrative user with password authentication, you could perform the same operation by typing:

    mysqladmin -u admin -p version

This means MariaDB is up and running and that your user is able to authenticate successfully.

## Conclusion

You now have a basic MariaDB setup installed on your server. Here are a few examples of next steps you can take:

- [Implement some additional security measures](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Relocate the data directory](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
