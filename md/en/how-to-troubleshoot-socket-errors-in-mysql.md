---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-troubleshoot-socket-errors-in-mysql
---

# How To Troubleshoot Socket Errors in MySQL

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

MySQL manages connections to the database server through the use of a _socket file_, a special kind of file that facilitates communications between different processes. The MySQL server’s socket file is named `mysqld.sock` and on Ubuntu systems it’s usually stored in the `/var/run/mysqld/` directory. This file is created by the MySQL service automatically.

Sometimes, changes to your system or your MySQL configuration can result in MySQL being unable to read the socket file, preventing you from gaining access to your databases. The most common socket error looks like this:

    OutputERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)

There are a few reasons why this error may occur, and a few potential ways to resolve it.

One common cause of this error is that the MySQL service is stopped or did not start to begin with, meaning that it was unable to create the socket file in the first place. To find out if this is the reason you’re seeing this error, try starting the service with `systemctl`:

    sudo systemctl start mysql

Then try accessing the MySQL prompt again. If you still receive the socket error, double check the location where your MySQL installation is looking for the socket file. This information can be found in the `mysqld.cnf` file:

    sudo nano /etc/mysql/mysql.conf.d/mysql.cnf

Look for the `socket` parameter in the `[mysqld]` section of this file. It will look like this:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    [mysqld]
    user = mysql
    pid-file = /var/run/mysqld/mysqld.pid
    socket = /var/run/mysqld/mysqld.sock
    port = 3306
    . . .

Close this file, then ensure that the `mysqld.sock` file exists by running an `ls` command on the directory where MySQL expects to find it:

    ls -a /var/run/mysqld/

If the socket file exists, you will see it in this command’s output:

    Output. .. mysqld.pid mysqld.sock mysqld.sock.lock

If the file does not exist, the reason may be that MySQL is trying to create it, but does not have adequate permissions to do so. You can ensure that the correct permissions are in place by changing the directory’s ownership to the **mysql** user and group:

    sudo chown mysql:mysql /var/run/mysqld/

Then ensure that the **mysql** user has the appropriate permissions over the directory. Setting these to `775` will work in most cases:

    sudo chmod -R 755 /var/run/mysqld/

Finally, restart the MySQL service so it can attempt to create the socket file again:

    sudo systemctl restart mysql

Then try accessing the MySQL prompt once again. If you still encounter the socket error, there’s likely a deeper issue with your MySQL instance, in which case you should review the error log to see if it can provide any clues.
