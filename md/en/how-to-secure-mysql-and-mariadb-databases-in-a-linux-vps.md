---
author: Justin Ellingwood
date: 2013-07-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps
---

# How To Secure MySQL and MariaDB Databases in a Linux VPS

## Introduction

There are many implementations of the SQL database language available on Linux and Unix-like systems. MySQL and MariaDB are two popular options for deploying relational databases in server environments.

However, like most software, these tools can be security liabilities if they are configured incorrectly. This tutorial will guide you through some basic steps you can take to secure your MariaDB or MySQL databases, and ensure that they are not an open door into your VPS.

For the sake of simplicity and illustration, we will use the MySQL server on an Ubuntu 12.04 VPS instance. However, these techniques can be applied to other Linux distributions and can be used with MariaDB as well.

## Initial Setup

MySQL gives you an opportunity to take the first step towards security during installation. It will request that you set a root password.

    sudo apt-get install mysql-server

     ?????????????????????????? Configuring mysql-server-5.5 ??????????????????????????? ? While not mandatory, it is highly recommended that you set a password for the ? ? MySQL administrative "root" user. ? ? ? ? If this field is left blank, the password will not be changed. ? ? ? ? New password for the MySQL "root" user: ? ? ? ? \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ ? ? ? ? <ok> ? 
     ? ? 
     ???????????????????????????????????????????????????????????????????????????????????</ok>

You can always set the root password at a later time, but there is no reason to skip this step, so you should secure your administrator account from the very beginning.

Once the installation is complete, we should run a few included scripts. First, we will use the "mysql\_install\_db" script to create a directory layout for our databases.

    sudo mysql\_install\_db

Next, run the script called "mysql\_secure\_installation". This will guide us through some procedures that will remove some defaults that are dangerous to use in a production environment.

    sudo mysql\_secure\_installation

It will first prompt you for the root password you set up during installation. Immediately following, you will be asked a series of questions, beginning with if you'd like to change the root password.

This is another opportunity to change your password to something secure if you have not done so already.

You should answer "Y" (for yes) to all of the remaining questions.

This will remove the ability for anyone to log into MySQL by default, disable logging in remotely with the administrator account, remove some test databases that are insecure, and update the running MySQL instance to reflect these changes.

## Security Considerations

The overarching theme of securing MySQL (and almost any other system) is that access should be granted only when absolutely necessary. Your data safety sometimes comes down to a balance between convenience and security.

In this guide, we will lean on the side of security, although your specific usage of the database software may lead you to pick and choose from these options.

## Security Through the My.cnf File

The main configuration file for MySQL is a file called "my.cnf" that is located in the "/etc/mysql/" directory on Ubuntu and the "/etc/" directory on some other VPS.

We will change some settings in this file to lock down our MySQL instance.

Open the file with root privileges. Change the directory path as needed if you are following this tutorial on a different system:

    sudo nano /etc/mysql/my.cnf

The first setting that we should check is the "bind-address" setting within the "[mysqld]" section. This setting should be set to your local loopback network device, which is "127.0.0.1".

    bind-address = 127.0.0.1

This makes sure that MySQL is not accepting connections from anywhere except for the local machine.

If you need to access this database from another machine, consider connecting through SSH to do your database querying and administration locally and sending the results through the ssh tunnel.

The next hole we will patch is a function that allows access to the underlying filesystem from within MySQL. This can have severe security implications and should be shut off unless you absolutely need it.

In the same section of the file, we will add a directive to disable this ability to load local files:

    local-infile=0

This will disable loading files from the filesystem for users without file level privileges to the database.

If we have enough space and are not operating a huge database, it can be helpful to log additional information to keep an eye on suspicious activity.

Logging too much can create a performance hit, so this is something you need to weigh carefully.

You can set the log variable within the same "[mysqld]" section that we've been adding to.

    log=/var/log/mysql-logfile

Make sure that the MySQL log, error log, and mysql log directory are not world readable:

    sudo ls -l /var/log/mysql\*

    -rw-r----- 1 mysql adm 0 Jul 23 18:06 /var/log/mysql.err -rw-r----- 1 mysql adm 0 Jul 23 18:06 /var/log/mysql.log /var/log/mysql: total 28 -rw-rw---- 1 mysql adm 20694 Jul 23 19:17 error.log

## Securing MySQL From Within

There are a number of steps you can take while using MySQL to improve security.

We will be inputting the commands in this section into the MySQL prompt interface, so we need to log in.

    mysql -u root -p

You will be asked for the root password that you set up earlier.

### Securing Passwords and Host Associations

First, make sure there are no users without a password or a host association in MySQL:

    SELECT User,Host,Password FROM mysql.user;

    +------------------+-----------+-------------------------------------------+ | user | host | password | +------------------+-----------+-------------------------------------------+ | root | localhost | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | demo-user | % | | | root | 127.0.0.1 | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | root | ::1 | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | debian-sys-maint | localhost | \*ECE81E38F064E50419F3074004A8352B6A683390 | +------------------+-----------+-------------------------------------------+ 5 rows in set (0.00 sec)

As you can see, in our example set up, the user "demo-user" has no password and is valid regardless of what host he is on. This is very insecure.

We can set a password for the user with this command. Change "newPassWord" to reflect the password you wish to assign.

    UPDATE mysql.user SET Password=PASSWORD('newPassWord') WHERE User="demo-user";

If we check the User table again, we will see that the demo user now has a password:

    SELECT User,Host,Password FROM mysql.user;

    +------------------+-----------+-------------------------------------------+ | user | host | password | +------------------+-----------+-------------------------------------------+ | root | localhost | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | demo-user | % | \*D8DECEC305209EEFEC43008E1D420E1AA06B19E0 | | root | 127.0.0.1 | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | root | ::1 | \*DE06E242B88EFB1FE4B5083587C260BACB2A6158 | | debian-sys-maint | localhost | \*ECE81E38F064E50419F3074004A8352B6A683390 | +------------------+-----------+-------------------------------------------+ 5 rows in set (0.00 sec)

If you look in the "Host" field, you will see that we still have a "%", which is a wildcard that means any host. This is not what we want. Let's change that to be "localhost":

    UPDATE mysql.user SET Host='localhost' WHERE User="demo-user";

If we check again, we can see that the User table now has the appropriate fields set.

    SELECT User,Host,Password FROM mysql.user;

If our table contains any blank users (it should not at this point since we ran "mysql\_secure\_installation", but we will cover this anyways), we should remove them.

To do this, we can use the following call to delete blank users from the access table:

    DELETE FROM mysql.user WHERE User="";

After we are done modifying the User table, we need to input the following command to implement the new permissions:

    FLUSH PRIVILEGES;

### Implementing Application-Specific Users

Similar to the practice of running processes within Linux as an isolated user, MySQL benefits from the same kind of isolation.

Each application that uses MySQL should have its own user that only has limited privileges and only has access to the databases it needs to run.

When we configure a new application to use MySQL, we should create the databases needed by that application:

    create database testDB;

    Query OK, 1 row affected (0.00 sec)

Next, we should create a user to manage that database, and assign it only the privileges it needs. This will vary by application, and some uses need more open privileges than others.

To create a new user, use the following command:

    CREATE USER 'demo-user'@'localhost' IDENTIFIED BY 'password';

We can grant the new user privileges on the new table with the following command. See the tutorial on [how to create a new user and grant permissions in MySQL](https://www.digitalocean.com/community/articles/how-to-create-a-new-user-and-grant-permissions-in-mysql) to learn more about specific privileges:

    GRANT SELECT,UPDATE,DELETE ON testDB.\* TO 'demo-user'@'localhost';

As an example, if we later need to revoke update privileges from the account, we could use the following command:

    REVOKE UPDATE ON testDB.\* FROM 'demo-user'@'localhost';

If we need all privileges on a certain database, we can specify that with the following:

    GRANT ALL ON testDB.\* TO 'demo-user'@'localhost';

To show the current privileges of a user, we first must implement the privileges we specified using the "flush privileges" command. Then, we can query what grants a user has:

    FLUSH PRIVILEGES; show grants for 'demo-user'@'localhost';

    +------------------------------------------------------------------------------------------------------------------+ | Grants for demo-user@localhost | +------------------------------------------------------------------------------------------------------------------+ | GRANT USAGE ON \*.\* TO 'demo-user'@'localhost' IDENTIFIED BY PASSWORD '\*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19' | | GRANT SELECT, UPDATE, DELETE ON `testDB`.\* TO 'demo-user'@'localhost' | +------------------------------------------------------------------------------------------------------------------+ 2 rows in set (0.00 sec)

Always flush privileges when you are finished making changes.

### Changing the Root User

One additional step that you may want to take is to change the root login name. If an attacker is trying to access the root MySQL login, they will need to perform the additional step of finding the username.

The root login can be changed with the following command:

    rename user 'root'@'localhost' to 'newAdminUser'@'localhost';

We can see the change by using the same query we've been using for the User database:

    select user,host,password from mysql.user;

Again, we must flush privileges for these changes to happen:

    FLUSH PRIVILEGES;

Remember that you will have to log into MySQL as the newly created username from now on when you wish to perform administrative tasks:

    mysql -u newAdminUser -p

## Conclusion

Although this is in no way an exhaustive list of MySQL and MariaDB security practices, it should give you a good introduction to the kinds of decisions you have to make when securing your databases.

More information about configuration and security can be found on the MySQL and MariaDB websites as well as in their respective man pages. The applications you choose to use may also offer security advice.

By Justin Ellingwood
