---
author: Jon Schwenn
date: 2016-10-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-connect-to-a-mysql-server-remotely-with-mysql-workbench
---

# How to Connect to a MySQL Server Remotely with MySQL Workbench

## Introduction

Your database server contains tables full of important data. Querying this data graphically on your local computer is the easiest way to interact with your database. But connecting remotely to your database server usually entails configuring MySQL to listen on every interface, restricting access to port `3306` with your firewall, and configuring user and host permissions for authentication. And allowing connections to MySQL directly can be a security concern.

Using tools like [HeidiSQL](http://www.heidisql.com/) for Windows, [Sequel Pro](http://sequelpro.com/) for macOS, or the cross-platform [MySQL Workbench](http://www.mysql.com/products/workbench/), you can connect securely to your database over SSH, bypassing those cumbersome and potentially insecure steps. This brief tutorial will show you how to connect to a remote database using MySQL Workbench.

## Prerequisites

To complete this tutorial, you will need:

- A server running MySQL that is accessible via SSH. For example, you can follow the tutorial [How To Install MySQL on Ubuntu 14.04](how-to-install-mysql-on-ubuntu-14-04) to get up and running quickly.
- MySQL Workbench installed on your local machine, which is available for all major platforms, including Windows, macOS, Ubuntu Linux, RedHat Linux, and Fedora. Visit the [MySQL Workbench Downloads page](http://dev.mysql.com/downloads/workbench/) to download the installer for your operating system.

You will also need the following information about the database server you plan to use:

- The public IP address of the server running MySQL. 
- The server’s SSH Port if configured differently than port `22`.
- A user account with SSH access to the server, with a password or public key.
- The username and password for the MySQL account you wish to use.

## Connecting to the Database Server With SSH

Once you’ve installed MySQL Workbench on your computer, launch the program. Create a new connection by clicking the **+** icon next to **MySQL Connections** in the main window.

You’ll be presented with the **Connect to Database** window, which looks like the follwing figure:

![mac](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mysql_workbench_ssh/G6koxy9.png)

To create the connection, enter the following details:

1. For **Connection Name** , enter any name you’d like that helps you identify the connection you’re making later. This might be something like `database_for_myapp` or something more descriptive.
2. Change the **Connection Method** to **Standard TCP/IP over SSH**.
3. For **SSH Hostname** , enter your MySQL server’s IP address. If your server accepts SSH connections on a different port, enter the IP address, followed by a colon and port number.
4. For **SSH Username** , enter the username you use to log into the server via SSH. 
5. For **SSH Password** , enter the password you use for your SSH user. If you use public keys instead of passwords, select an SSH key for authentication. 
6. For **MySQL Hostname** and **MySQL Server Port** , use the default values.
7. For **Username** , enter the MySQL username. 
8. For **Password** , you can either enter the password or leave it blank. If you do not store the MySQL password in MySQL Workbench, a prompt will request the password each time you attempt to connect to the database.
9. Choose **Test Connection** to ensure your settings are correct. 
10. Choose **OK** to create the connection.

Once you’ve connected to your database, you can view the details of the MySQL instance, including database status, current connections, and database configuration, as well as users and permissions. MySQL Workbench also supports importing and exporting of MySQL dump files so you can quickly back up and restore your database.

You will find your databases listed under the **SCHEMAS** area of the left navigation bar. The dropdown arrow next to each database will allow you to expand and navigate your databases tables and objects. You can easily view table data, write complex queries, and edit data from this area of MySQL Workbench, as shown in the following figure:

![A table query in MySQL Workbench](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mysql_workbench_ssh/t0QrK2T2.png)

To manage your connections, select the **Database** menu and choose the **Connect to Database** option, or press `⌘U` on the Mac or `CTRL+U` on Windows and Linux systems. To connect to a different database, create a new connection using the same process you used for your first connection.

## Conclusion

Using MySQL Workbench to access your remote MySQL database through an SSH tunnel is a simple and secure way to manage your databases from the comfort of your local computer. Using the connection method in this tutorial, you can bypass multiple network and security configuration changes normally required for a remote MySQL connection.
