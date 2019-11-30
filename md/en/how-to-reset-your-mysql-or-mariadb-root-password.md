---
author: Mateusz Papiernik
date: 2016-12-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-reset-your-mysql-or-mariadb-root-password
---

# How To Reset Your MySQL or MariaDB Root Password

## Introduction

Forgetting passwords happens to the best of us. If you forget or lose the root password to your MySQL or MariaDB database, you can still gain access and reset the password if you have access to the server and a `sudo`-enabled user account.

This tutorial will cover how to reset the root password for older and newer versions of MySQL and MariaDB.

## Prerequisites

To recover your root MySQL/MariaDB password, you will need:

- Access to the Linux server running MySQL or MariaDB with a sudo user.

## Step 1 — Identifying the Database Version

Most modern Linux distributions ship with either MySQL or MariaDB, a popular drop-in replacement which is fully compatible with MySQL. Depending on the database used and its version, you’ll need to use different commands to recover the root password.

You can check your version with the following command:

    mysql --version

You’ll see some output like this with MySQL:

    MySQL outputmysql Ver 14.14 Distrib 5.7.16, for Linux (x86_64) using EditLine wrapper

Or output like this for MariaDB:

    MariaDB outputmysql Ver 15.1 Distrib 5.5.52-MariaDB, for Linux (x86_64) using readline 5.1

Make note of which database and which version you’re running, as you’ll use them later. Next, you need to stop the database so you can access it manually.

## Step 2 — Stopping the Database Server

To change the root password, you have to shut down the database server beforehand.

You can do that for MySQL with:

    sudo systemctl stop mysql

And for MariaDB wtih:

    sudo systemctl stop mariadb

After the database server is stopped, you’ll access it manually to reset the root password.

## Step 3 — Restarting the Database Server Without Permission Checking

If you run MySQL and MariaDB without loading information about user privileges, it will allow you to access the database command line with root privileges without providing a password. This will allow you to gain access to the database without knowing it.

To do this, you need to stop the database from loading the _grant tables_, which store user privilege information. Because this is a bit of a security risk, you should also skip networking as well to prevent other clients from connecting.

Start the database without loading the grant tables or enabling networking:

    sudo mysqld_safe --skip-grant-tables --skip-networking &

The ampersand at the end of this command will make this process run in the background so you can continue to use your terminal.

Now you can connect to the database as the root user, which should not ask for a password.

    mysql -u root

You’ll immediately see a database shell prompt instead.

MySQL prompt

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    mysql>

MariaDB prompt

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    MariaDB [(none)]>

Now that you have root access, you can change the root password.

## Step 4 — Changing the Root Password

One simple way to change the root password for modern versions of MySQL is using the `ALTER USER` command. However, this command won’t work right now because the grant tables aren’t loaded.

Let’s tell the database server to reload the grant tables by issuing the `FLUSH PRIVILEGES` command.

    FLUSH PRIVILEGES;

Now we can actually change the root password.

For **MySQL 5.7.6 and newer** as well as **MariaDB 10.1.20 and newer** , use the following command.

    ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';

For **MySQL 5.7.5 and older** as well as **MariaDB 10.1.20** and older, use:

    SET PASSWORD FOR 'root'@'localhost' = PASSWORD('new_password');

Make sure to replace `new_password` with your new password of choice.

**Note** : If the `ALTER USER` command doesn’t work, it’s usually indicative of a bigger problem. However, you can try `UPDATE ... SET` to reset the root password instead.

    UPDATE mysql.user SET authentication_string = PASSWORD('new_password') WHERE User = 'root' AND Host = 'localhost';

Remember to reload the grant tables after this.

In either case, you should see confirmation that the command has been successfully executed.

    OutputQuery OK, 0 rows affected (0.00 sec)

The password has been changed, so you can now stop the manual instance of the database server and restart it as it was before.

## Step 5 — Restart the Database Server Normally

First, stop the instance of the database server that you started manually in Step 3. This command searches for the PID, or process ID, of MySQL or MariaDB process and sends `SIGTERM` to tell it to exit smoothly after performing clean-up operations. You can learn more in [this Linux process management tutorial](how-to-use-ps-kill-and-nice-to-manage-processes-in-linux).

For MySQL, use:

    sudo kill `cat /var/run/mysqld/mysqld.pid`

For MariaDB, use:

    sudo kill `/var/run/mariadb/mariadb.pid`

Then, restart the service using `systemctl`.

For MySQL, use:

    sudo systemctl start mysql

For MariaDB, use:

    sudo systemctl start mariadb

Now you can confirm that the new password has been applied correctly by running:

    mysql -u root -p

The command should now prompt for the newly assigned password. Enter it, and you should gain access to the database prompt as expected.

## Conclusion

You now have administrative access to the MySQL or MariaDB server restored. Make sure the new root password you choose is strong and secure and keep it in safe place.
