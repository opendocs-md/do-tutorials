---
author: Mark Drake
date: 2019-08-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-connect-to-managed-database-ubuntu-18-04
---

# How To Connect to a Managed Database on Ubuntu 18.04

## Introduction

[Managed databases](understanding-managed-databases) have a number of benefits over self-managed databases, including automated updates, simplified scaling, and high availability. If you’re new to working with managed databases, though, the best way to perform certain tasks — like connecting to the database — may not be self-evident.

In this guide, we will go over how to install client programs for a variety of database management systems (DBMSs), including [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/), and [Redis](https://redis.io/), on an Ubuntu 18.04 server. We’ll also explain how to use these programs to connect to a managed database instance.

**Note:** The instructions outlined in this guide were tested with [DigitalOcean Managed Databases](https://www.digitalocean.com/products/managed-databases/), but they should generally work for managed databases from any cloud provider. If, however, you run into issues connecting to a database provisioned from another provider, you should consult their documentation for help.

## Prerequisites

To follow the instructions detailed in this guide, you will need:

- Access to a server running Ubuntu 18.04. This server should have a non-root user with administrative privileges and a firewall configured with `ufw`. To set this up, follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).
- A managed database instance. This tutorial provides instructions on how to connect to a variety of database management systems, specifically PostgreSQL, MySQL, and Redis. To provision a DigitalOcean Managed Database, review our documentation for the DBMS of your choice:
  - [PostgreSQL](https://www.digitalocean.com/docs/databases/postgresql/how-to/create/)
  - [MySQL](https://www.digitalocean.com/docs/databases/mysql/how-to/create/)
  - [Redis](https://www.digitalocean.com/docs/databases/redis/how-to/create/)

Once you have these in place, jump to whichever section aligns with your DBMS.

## Connecting to a Managed PostgreSQL Database

To connect to a managed PostgreSQL database, you can use `psql`, the standard command line client for Postgres. It’s open-source, maintained by the PostgreSQL Development Group, and is usually included when you download the PostgreSQL server. However, you can install `psql` by itself by installing the `postgresql-client` package with APT.

If you’ve not done so recently, update your server’s package index:

    sudo apt update

Then run the following command to install `psql`:

    sudo apt install postgresql-client

APT will ask you to confirm that you want to install the package. Do so by pressing `ENTER`.

Following that, you can connect to your managed Postgres database without any need for further configuration. For example, you might invoke `psql` with the following flags:

- `-U`, the PostgreSQL user you want to connect as
- `-h`, the managed database’s hostname or IP address
- `-p`, the TCP port on which the managed database is listening for connections
- `-d`, the specific database you want to connect to
- `-v`, short for “variable,” precedes other connection variables, followed by an equal sign (`=`) and the variables’ values. For example, if you want to validate the database’s CA certificate when you connect, you would include `-v sslmode=require` in your command
- `-W`, which tells `psql` to prompt you for the PostgreSQL user’s password. Note that you could precede the `psql` command with `PGPASSWORD=password`, but it’s generally considered more secure to not include passwords on the command line

With these flags included, the `psql` command’s syntax would look like this:

    psql -U user -h host -p port -d database -v variable=value -W

Alternatively, if your managed database provider offers a [uniform resource identifer](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) (URI) for connecting, you might use the following syntax:

    psql postgresql://username:password@host:port/database?option_1=value&option_n=value

**Note:** If you’re connecting to a DigitalOcean Managed Database, you can find all of this connection information in your **Cloud Control Panel**. Click on **Databases** in the left-hand sidebar menu, then click on the database you want to connect to and scroll down to find its **Connection Details** section. From there, you do one of the following:

- Select the **Connection parameters** option and copy the relevant fields individually into the `psql` syntax detailed previously
- Select the **Connection String** option and copy a ready-made connection URI you can paste into the connection URI syntax outlined above
- Select the **Flags** option and copy a ready-to-use `psql` command that you can paste into your terminal to make the connection

With that, you’re ready to begin using with your managed PostgreSQL instance. For more information on how to interact with PostgreSQL, see our guide on [How to Manage an SQL Database](how-to-manage-sql-database-cheat-sheet). You may also find our [Introduction to Queries in PostgreSQL](introduction-to-queries-postgresql) useful.

## Connecting to a Managed MySQL Database

To connect to a managed MySQL database, you can use the official MySQL database client. On Ubuntu, this client is typically installed by downloading the `mysql-client` package through APT. If you’re using the default Ubuntu repositories, though, this will install version 5.7 of the program.

In order to access a DigitalOcean Managed MySQL database, you will need to install version 8.0 or above. To do so, you must first add the MySQL software repository before installing the package.

**Note:** If you don’t need to install the latest version of `mysql-client`, you can just update your server’s package index and install `mysql-client` without adding the MySQL software repository:

    sudo apt update
    sudo apt install mysql-client

If you aren’t sure whether you need the latest version of `mysql-client`, you should consult your cloud provider’s managed databases documentation.

Begin by navigating to [the **MySQL APT Repository** page](https://dev.mysql.com/downloads/repo/apt/) in your web browser. Find the **Download** button in the lower-right corner and click through to the next page. This page will prompt you to log in or sign up for an Oracle web account. You can skip that and instead look for the link that says **No thanks, just start my download**. Right-click the link and select **Copy Link Address** (this option may be worded differently, depending on your browser).

Now you’re ready to download the file. On your server, move to a directory you can write to:

    cd /tmp

Download the file using `curl`, remembering to paste the address you just copied in place of the highlighted portion of the following command. You also need to pass two command line flags to `curl`. `-O` instructs `curl` to output to a file instead of standard output. The `L` flag makes `curl` follow HTTP redirects, which is necessary in this case because the address you copied actually redirects to another location before the file downloads:

    curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb

The file should now be downloaded in your current directory. List the files to make sure:

    ls

You will see the filename listed in the output:

    Outputmysql-apt-config_0.8.13-1_all.deb
    . . .

Now you can add the MySQL APT repository to your system’s repository list. The `dpkg` command is used to install, remove, and inspect `.deb` software packages. The following command includes the `-i` flag, indicating that you’d like to install from the specified file:

    sudo dpkg -i mysql-apt-config*

During the installation, you’ll be presented with a configuration screen where you can specify which version of MySQL you’d prefer, along with an option to install repositories for other MySQL-related tools. The defaults will add the repository information for the latest stable version of MySQL and nothing else. This is what we want, so use the down arrow to navigate to the `Ok` menu option and hit `ENTER`.

![Selecting mysql-apt-config configuration options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pma_managed_db/dpkg_mysql_apt_config_alt2.png)

Following that, the package will finish adding the repository. Refresh your `apt` package cache to make the new software packages available:

    sudo apt update

Next, you can clean up your system a bit and delete the file you downloaded, as you won’t need it in the future:

    rm mysql-apt-config*

**Note:** If you ever need to update the configuration of these repositories, run the following command to select your new options:

    sudo dpkg-reconfigure mysql-apt-config

After selecting your new options, run the following command to refresh your package cache:

    sudo apt update

Now that you’ve added the MySQL repositories, you’re ready to install the actual MySQL client software. Do so with the following `apt` command:

    sudo apt install mysql-client

Once that command finishes, check the software version number to ensure that you have the latest release:

    mysql --version

    Outputmysql Ver 8.0.17-cluster for Linux on x86_64 (MySQL Community Server - GPL)

After you’ve installed the `mysql-client` package, you can access your managed database by running the `mysql` command with the following flags as arguments:

- `-u`, the MySQL user you want to connect as
- `-p`, tells `mysql` to prompt for the user’s password. You could include your password directly in the connection command following the `-p` flag (without a space, as in `-ppassword`) but, for security reasons, this is generally not recommended
- `-h`, the database’s hostname or IP address
- `-P`, the TCP port on which MySQL is listening for connections
- `-D`, the specific database you want to connect to

Using these flags, the `mysql` syntax will look like this:

    mysql -u user -p -h host -P port -D database

Alternatively, if you have a connection URI you can use to connect, you would use a syntax like this:

    mysql mysql://user:password@host:port/database?option_1=value&option_n=value

**Note:** If you’re connecting to a DigitalOcean Managed Database, you can find all of this connection information in your **Cloud Control Panel**. Click on **Databases** in the left-hand sidebar menu, then click on the database you want to connect to and scroll down to find its **Connection Details** section. From there, you do one of the following:

- Select the **Connection parameters** option and copy the relevant fields individually into the `mysql` syntax outlined previously
- Select the **Connection String** option and copy a ready-made connection URI you can paste into the connection string detailed above
- Select the **Flags** option and copy a ready-to-use `mysql` command that you can paste into your terminal to make the connection

With that, you’re ready to begin using with your managed MySQL instance. For more information on how to interact with MySQL, see our guide on [How to Manage an SQL Database](how-to-manage-sql-database-cheat-sheet). You may also find our [Introduction to Queries in MySQL](introduction-to-queries-mysql) useful.

### A Note Regarding Password Authentication in MySQL 8

In MySQL 8.0 and newer, the default authentication plugin is `caching_sha2_password`. As of this writing, though, PHP does not support `caching_sha2_password`. If you plan on using your managed MySQL database with an application that uses PHP, such as WordPress or phpMyAdmin, this may lead to issues when the application attempts to connect to the database.

If you have access to the database’s configuration file, you could add a setting to force it to use a PHP-supported authentication plugin — for example, `mysql_native_password` — by default:

Example MySQL Configuration File

    [mysqld]
    default-authentication-plugin=mysql_native_password

However, some managed database providers — including DigitalOcean — do not make the database configuration file available to end users. In this case, you could connect to the database and run an `ALTER USER` command for any existing MySQL users which need to connect to the database, but can’t do so with the `caching_sha2_password` plugin:

    ALTER USER user IDENTIFIED WITH mysql_native_password BY 'password';

Of course, you can set new users to authenticate with `mysql_native_password` by specifying the plugin in their respective `CREATE USER` statements:

    CREATE USER user IDENTIFIED WITH mysql_native_password BY 'password';

If you’re using a DigitalOcean Managed Database, be aware that if you configure a user to authenticate with a plugin other than `caching_sha2_password` then you won’t be able to see that user’s password in your Cloud Control Panel. For this reason, you should make sure you note down the passwords of any users that authenticate with `mysql_native_password` or other plugins in a secure location.

## Connecting to a Managed Redis Database

When you install Redis locally, it comes with `redis-cli`, the Redis command line interface. You can use `redis-cli` to connect to a remote, managed Redis instance, but it doesn’t natively support TLS/SSL connections. There are ways you can configure `redis-cli` to securely connect to a managed Redis instance (for example, by [configuring a TLS tunnel](how-to-connect-to-managed-redis-over-tls-with-stunnel-and-redis-cli), but there are alternative Redis clients that have built-in TLS support.

For DigitalOcean Managed Redis Databases, we recommend that you install Redli, an open-source, interactive Redis terminal. To do so, navigate to the [**Releases Page**](https://github.com/IBM-Cloud/redli/releases) on the Redli GitHub project and locate the **Assets** table for the latest release. As of this writing, this will be version 0.4.4.

There, find the link for the file ending in `linux_amd64.tar.gz`. This link points to an archive file known as a _tarball_ that, when extracted, will create a few files on your system. Right-click this link and select **Copy link address** (this option may differ depending on your web browser).

On your server, move to a directory you can write to:

    cd /tmp

Then, paste the link into the following `wget` command, replacing the highlighted URL. This command will download the file to your server:

    wget https://github.com/IBM-Cloud/redli/releases/download/v0.4.4/redli_0.4.4_linux_amd64.tar.gz

Once the file has been downloaded to your server, extract the tarball:

    tar xvf redli_0.4.4_linux_amd64.tar.gz

This will create the following files on your server:

    OutputLICENSE.txt
    README.md
    redli

The `redli` file is the Redli [_binary file_](https://en.wikipedia.org/wiki/Binary_file). Move it to the `/usr/local/bin` directory, the location where Ubuntu looks for executable files:

    sudo mv redli /usr/local/bin/

At this point, you can clean up your system a bit and remove the tarball:

    rm redli 0.4.4_linux_amd64.tar.gz

Now you can use Redli to connect to your managed Redis instance. You could do so by running the `redli` command followed by these flags:

- `-h`, the host to connect to. This can either be a hostname or an IP address
- `-a`, the password used to authenticate to the Redis instance
- `-p`, the port to connect to

With these flags included, the `redli` syntax would be as follows. Note that this example also includes the `--tls` option, which allows you to connect to a managed Redis database over TLS/SSL without the need for a tunnel:

    redli --tls -h host -a password -p port

One benefit that Redli has over `redis-cli` is that it understands the `rediss` protocol, which is used to designate a URI pointing to a Redis database. This allows you to use a connection string to access your database:

    redli --tls -u rediss://user:password@host:port

Note that this example includes the `-u` flag, which specifies that the following argument will be a connection URI.

**Note:** If you’re connecting to a DigitalOcean Managed Database, you can find all of this connection information in your **Cloud Control Panel**. Click on **Databases** in the left-hand sidebar menu, then click on the database you want to connect to and scroll down to find the **Connection Details** section. From there, you do one of the following:

- Select the **Connection parameters** option and copy the relevant fields individually into the `redli` syntax detailed previously
- Select the **Connection String** option and copy a ready-made connection URI that you can use with the connection string syntax outlined above
- Select the **Flags** option and copy a ready-to-use `redli` command that you can paste into your terminal to make the connection

Following that, you can begin interacting with your managed Redis instance. For more information on how to work with Redis, see our series or cheat sheets on [How To Manage a Redis Database](https://www.digitalocean.com/community/tutorial_series/how-to-manage-a-redis-database).

## Conclusion

As a relatively new development in cloud services, many practices that are well known for self-managed databases aren’t widely or comprehensively documented for databases managed by cloud providers. One of the most fundamental of these practices, accessing the database, may not be immediately clear to those new to working with managed databases. Our goal for this tutorial is that it helps get you started as you begin using a managed database for storing data.

For more information on working with databases, we encourage you to check out our variety of [database-related content](https://www.digitalocean.com/community/tags/databases?type=tutorials), including tutorials focused directly on [PostgreSQL](https://www.digitalocean.com/community/tags/postgresql?type=tutorials), [MySQL](https://www.digitalocean.com/community/tags/mysql?type=tutorials), and [Redis](https://www.digitalocean.com/community/tags/redis?type=tutorials).

To learn more about DigitalOcean Managed Databases, please see our [Managed Databases product documentation](https://www.digitalocean.com/docs/databases/).
