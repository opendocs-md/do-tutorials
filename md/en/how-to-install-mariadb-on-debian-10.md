---
author: Justin Ellingwood, Jamon Camisso
date: 2019-07-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-mariadb-on-debian-10
---

# How To Install MariaDB on Debian 10

## Introduction

[MariaDB](https://mariadb.org/) is an open-source database management system, commonly used as an alternative for the MySQL portion of the popular [LAMP](how-to-install-linux-apache-mariadb-php-lamp-stack-debian10) (Linux, Apache, MySQL, PHP/Python/Perl) stack. It is intended to be a drop-in replacement for MySQL and Debian now only ships with MariaDB packages. If you attempt to install MySQL server related packages, you’ll receive the compatible MariaDB replacement versions instead.

The short version of this installation guide consists of these three steps:

- Update your package index using `apt`
- Install the `mariadb-server` package using `apt`. The package also pulls in related tools to interact with MariaDB
- Run the included `mysql_secure_installation` security script to restrict access to the server

    sudo apt update
    sudo apt install mariadb-server
    sudo mysql_secure_installation

This tutorial will explain how to install MariaDB version 10.3 on a Debian 10 server, and verify that it is running and has a safe initial configuration.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 10 server set up by following [this initial server setup guide](initial-server-setup-with-debian-10), including a non- **root** user with `sudo` privileges and a firewall.

## Step 1 — Installing MariaDB

On Debian 10, MariaDB version 10.3 is included in the APT package repositories by default. It is marked as the default MySQL variant by the Debian MySQL/MariaDB packaging team.

To install it, update the package index on your server with `apt`:

    sudo apt update

Then install the package:

    sudo apt install mariadb-server

These commands will install MariaDB, but will not prompt you to set a password or make any other configuration changes. Because the default configuration leaves your installation of MariaDB insecure, we will use a script that the `mariadb-server` package provides to restrict access to the server and remove unused accounts.

## Step 2 — Configuring MariaDB

For new MariaDB installations, the next step is to run the included security script. This script changes some of the less secure default options. We will use it to block remote **root** logins and to remove unused database users.

Run the security script:

    sudo mysql_secure_installation

This will take you through a series of prompts where you can make some changes to your MariaDB installation’s security options. The first prompt will ask you to enter the current database **root** password. Since we have not set one up yet, press `ENTER` to indicate “none”.

The next prompt asks you whether you’d like to set up a database **root** password. Type `N` and then press `ENTER`. In Debian, the **root** account for MariaDB is tied closely to automated system maintenance, so we should not change the configured authentication methods for that account. Doing so would make it possible for a package update to break the database system by removing access to the administrative account. Later, we will cover how to optionally set up an additional administrative account for password access if socket authentication is not appropriate for your use case.

From there, you can press `Y` and then `ENTER` to accept the defaults for all the subsequent questions. This will remove some anonymous users and the test database, disable remote **root** logins, and load these new rules so that MariaDB immediately respects the changes you have made.

## Step 3 — (Optional) Adjusting User Authentication and Privileges

In Debian systems running MariaDB 10.3, the **root** MariaDB user is set to authenticate using the `unix_socket` plugin by default rather than with a password. This allows for some greater security and usability in many cases, but it can also complicate things when you need to allow an external program (e.g., phpMyAdmin) administrative rights.

Because the server uses the **root** account for tasks like log rotation and starting and stopping the server, it is best not to change the **root** account’s authentication details. Changing credentials in the `/etc/mysql/debian.cnf` configuration file may work initially, but package updates could potentially overwrite those changes. Instead of modifying the **root** account, the package maintainers recommend creating a separate administrative account for password-based access.

To do so, we will create a new account called `admin` with the same capabilities as the **root** account, but configured for password authentication. To do this, open up the MariaDB prompt from your terminal:

    sudo mysql

Now, we will create a new user with **root** privileges and password-based access. Change the username and password to match your preferences:

    MariaDB [(none)]> GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

Flush the privileges to ensure that they are saved and available in the current session:

    MariaDB [(none)]> FLUSH PRIVILEGES;

Following this, exit the MariaDB shell:

    MariaDB [(none)]> exit

Finally, let’s test the MariaDB installation.

## Step 4 — Testing MariaDB

When installed from the default repositories, MariaDB should start running automatically. To test this, check its status.

    sudo systemctl status mariadb

You’ll receive output that is similar to the following:

Output

    ● mariadb.service - MariaDB 10.3.15 database server
       Loaded: loaded (/lib/systemd/system/mariadb.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2019-07-12 20:35:29 UTC; 47min ago
         Docs: man:mysqld(8)
               https://mariadb.com/kb/en/library/systemd/
     Main PID: 2036 (mysqld)
       Status: "Taking your SQL requests now..."
        Tasks: 30 (limit: 2378)
       Memory: 76.1M
       CGroup: /system.slice/mariadb.service
               └─2036 /usr/sbin/mysqld
    
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: Phase 6/7: Checking and upgrading tables
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: Running 'mysqlcheck' with connection arguments: --socket='/var/run/mysqld/mysqld.sock' --host='localhost' --socket='/var/run/mysqld/mysqld.sock' --host='localhost' --socket='/var/run/mysqld/mysqld.sock'
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: # Connecting to localhost...
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: # Disconnecting from localhost...
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: Processing databases
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: information_schema
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: performance_schema
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: Phase 7/7: Running 'FLUSH PRIVILEGES'
    Jul 12 20:35:29 deb-mariadb1 /etc/mysql/debian-start[2074]: OK
    Jul 12 20:35:30 deb-mariadb1 /etc/mysql/debian-start[2132]: Triggering myisam-recover for all MyISAM tables and aria-recover for all Aria tables

If MariaDB isn’t running, you can start it with the command `sudo systemctl start mariadb`.

For an additional check, you can try connecting to the database using the `mysqladmin` tool, which is a client that lets you run administrative commands. For example, this command says to connect to MariaDB as **root** and return the version using the Unix socket:

    sudo mysqladmin version

You should receive output similar to this:

    Outputmysqladmin Ver 9.1 Distrib 10.3.15-MariaDB, for debian-linux-gnu on x86_64
    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
    
    Server version 10.3.15-MariaDB-1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 48 min 14 sec
    
    Threads: 7 Questions: 474 Slow queries: 0 Opens: 177 Flush tables: 1 Open tables: 31 Queries per second avg: 0.163

If you configured a separate administrative user with password authentication, you could perform the same operation by typing:

    mysqladmin -u admin -p version

This means that MariaDB is up and running and that your user is able to authenticate successfully.

## Conclusion

In this guide you installed MariaDB to act as an SQL server. During the installation process you also secured the server. Optionally, you also created a separate user to ensure administrative access to MariaDB across package updates.

Now that you have a running and secure MariaDB server, here some examples of next steps that you can take to work with the server:

- [Import and export databases](how-to-import-and-export-databases-in-mysql-or-mariadb)

You can also incorporate MariaDB into a larger application stack:

- [How To Install Linux, Nginx, MariaDB, PHP (LEMP stack) on Debian 10](how-to-install-linux-nginx-mariadb-php-lemp-stack-on-debian-10)
