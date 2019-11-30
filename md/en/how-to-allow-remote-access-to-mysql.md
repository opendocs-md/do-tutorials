---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-allow-remote-access-to-mysql
---

# How To Allow Remote Access to MySQL

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

Many websites and applications start off with their web server and database backend hosted on the same machine. With time, though, a setup like this can become cumbersome and difficult to scale. A common solution is to separate these functions by setting up a remote database, allowing the server and database to grow at their own pace on their own machines.

One of the more common problems that users run into when trying to set up a remote MySQL database is that their MySQL instance is only configured to listen for local connections. This is MySQL’s default setting, but it won’t work for a remote database setup since MySQL must be able to listen for an _external_ IP address where the server can be reached. To enable this, open up your `mysqld.cnf` file:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Navigate to the line that begins with the `bind-address` directive. It will look like this:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    lc-messages-dir = /usr/share/mysql
    skip-external-locking
    #
    # Instead of skip-networking the default is now to listen only on
    # localhost which is more compatible and is not less secure.
    bind-address = 127.0.0.1
    . . .

By default, this value is set to `127.0.0.1`, meaning that the server will only look for local connections. You will need to change this directive to reference an external IP address. For the purposes of troubleshooting, you could set this directive to a wildcard IP address, either `*`, `::`, or `0.0.0.0`:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    lc-messages-dir = /usr/share/mysql
    skip-external-locking
    #
    # Instead of skip-networking the default is now to listen only on
    # localhost which is more compatible and is not less secure.
    bind-address = 0.0.0.0
    . . .

**Note:** If you’re running MySQL 8+, the `bind-address` directive will not be in the `mysqld.cnf` file by default. In this case, add the following highlighted line to the bottom of the file:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    [mysqld]
    pid-file = /var/run/mysqld/mysqld.pid
    socket = /var/run/mysqld/mysqld.sock
    datadir = /var/lib/mysql
    log-error = /var/log/mysql/error.log
    bind-address = 0.0.0.0

After changing this line, save and close the file and then restart the MySQL service:

    sudo systemctl restart mysql

Following this, try accessing your database remotely from another machine:

    mysql -u user -h database_server_ip -p

If you’re able to access your database, it confirms that the `bind-address` directive in your configuration file was the issue. Please note, though, that setting `bind-address` to `0.0.0.0` is insecure as it allows connections to your server from any IP address. On the other hand, if you’re still unable to access the database remotely, then something else may be causing the issue. In either case, you may find it helpful to follow our guide on [How To Set Up a Remote Database to Optimize Site Performance with MySQL on Ubuntu 18.04](how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql-on-ubuntu-18-04) to set up a more secure remote database configuration.
