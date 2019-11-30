---
author: Justin Ellingwood
date: 2013-08-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-backup-mysql-databases-on-an-ubuntu-vps
---

# How To Backup MySQL Databases on an Ubuntu VPS

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

### **What is MySQL?**

MySQL is a popular database management solution that uses the SQL querying language to access and manipulate data. It can easily be used to manage the data from websites or applications.

Backups are important with any kind of data, and this is especially relevant when talking about databases. MySQL can be backed up in a few different ways that we will discuss in this article.

For this tutorial, we will be using an Ubuntu 12.04 VPS with MySQL 5.5 installed. Most modern distributions and recent versions of MySQL should operate in a similar manner.

## How to Backup a MySQL Database with mysqldump

One of the most common ways of backing up with MySQL is to use a command called " **mysqldump**".

### **Backing Up**

There is an article on [how to export databases using mysqldump](https://www.digitalocean.com/community/articles/how-to-import-and-export-databases-and-reset-a-root-password-in-mysql) here. The basic syntax of the command is:

    mysqldump -u username -p database\_to\_backup \> backup\_name.sql

### **Restoring**

To restore a database dump created with mysqldump, you simply have to redirect the file into MySQL again.

We need to create a blank database to house the imported data. First, log into MySQL by typing:

    mysql -u username -p

Create a new database which will hold all of the data from the data dump and then exit out of the MySQL prompt:

    CREATE DATABASE database\_name; exit 

Next, we can redirect the dump file into our newly created database by issuing the following command:

    mysql -u username -p database\_name \< backup\_name.sql

Your information should now be restored to the database you've created.

## How to Backup a MySQL Table to a Text File

You can save the data from a table directly into a text file by using the select statement within MySQL.

The general syntax for this operation is:

    SELECT \* INTO OUTFILE 'table\_backup\_file' FROM name\_of\_table;

This operation will save the table data to a file on the MySQL server. It will fail if there is already a file with the name chosen.

**Note: This option only saves table data. If your table structure is complex and must be preserved, it is best to use another method!**

## How to Backup MySQL Information using automysqlbackup

There is a utility program called " **automysqlbackup**" that is available in the Ubuntu repositories.

This utility can be scheduled to automatically perform backups at regular intervals.

To install this program, type the following into the terminal:

    sudo apt-get install automysqlbackup

Run the command by typing:

    sudo automysqlbackup

The main configuration file for automysqlbackup is located at "/etc/default/automysqlbackup". Open it with administrative privileges:

    sudo nano /etc/default/automysqlbackup

You can see that this file, by default, assigns many variables by the MySQL file located at "/etc/mysql/debian.cnf". This contains maintenance login information

From this file, it reads the user, password, and databases that must be backed up.

The default location for backups is "/var/lib/automysqlbackup". Search this directory to see the structure of the backups:

    ls /var/lib/automysqlbackup

    daily monthly weekly

If we look into the daily directory, we can see a subdirectory for each database, inside of which is a gzipped sql dump from when the command was run:

    ls -R /var/lib/automysqlbackup/daily

    .: database\_name information\_schema performance\_schema ./database\_name: database\_name\_2013-08-27\_23h30m.Tuesday.sql.gz ./information\_schema: information\_schema\_2013-08-27\_23h30m.Tuesday.sql.gz ./performance\_schema: performance\_schema\_2013-08-27\_23h30m.Tuesday.sql.gz

Ubuntu installs a cron script with this program that will run it every day. It will organize the files to the appropriate directory.

## How to Backup When Using Replication

It is possible to use MySQL replication to backup data with the above techniques.

Replication is a process of [mirroring the data from one server to another server (master-slave)](https://www.digitalocean.com/community/articles/how-to-set-up-master-slave-replication-in-mysql) or [mirroring changes made to either server to the other (master-master)](https://www.digitalocean.com/community/articles/how-to-set-up-mysql-master-master-replication).

While replication allows for data mirroring, it suffers when you are trying to save a specific point in time. This is because it is constantly replicating the changes of a dynamic system.

To avoid this problem, we can either:

- Disable replication temporarily
- Make the backup machine read-only temporarily

### **Disabling Replication Temporarily**

You can disable replication for the slave temporarily by issuing:

    mysqladmin -u user\_name -p stop-slave

Another option, which doesn't completely stop replication, but puts it on pause, so to speak, can be accomplished by typing:

    mysql -u user\_name -p -e 'STOP SLAVE SQL\_THREAD;'

After replication is halted, you can backup using one of the methods above. This allows you to keep the master MySQL database online while the slave is backed up.

When this is complete, restart replication by typing:

    mysqladmin -u user\_name -p start-slave

### **Making the Backup Machine Read-Only Temporarily**

You can also ensure a consistent set of data within the server by making the data read-only temporarily.

You can perform these steps on either the master or the slave systems.

First, log into MySQL with enough privileges to manipulate the data:

    mysql -u root -p 

Next, we can write all of the cached changes to the disk and set the system read-only by typing:

    FLUSH TABLES WITH READ LOCK; SET GLOBAL read\_only = ON;

Now, perform your backup using mysqldump.

Once the backup is complete, return the system to its original working order by typing:

    SET GLOBAL read\_only = OFF; UNLOCK TABLES;

## A Note About Techniques That Are No Longer Recommended

### **mysqlhotcopy**

MySQL includes a perl script for backing up databases quickly called " **mysqlhotcopy**". This tool can be used to quickly backup a database on a local machine, but it has limitations that make us avoid recommending it.

The most important reason we won't cover mysqlhotcopy's usage here is because it only works for data stored using the "MyISAM" and "Archive" storage engines.

Most users do not change the storage engine for their databases and, starting with MySQL 5.5, the default storage engine is "InnoDB". This type of database cannot be backed up using mysqlhotcopy.

Another limitation of this script is that it can only be run on the same machine that the database storage is kept. This prevents running backups from a remote machine, which can be a major limitation in some circumstances.

### **Copying Table Files**

Another method sometimes suggested is simply copying the table files that MySQL stores its data in.

This approach suffers for one of the same reasons as "mysqlhotcopy".

While it is reasonable to use this technique with storage engines that store their data in files, InnoDB, the new default storage engine, cannot be backed up in this way.

## Conclusion

There are many different methods of performing backups in MySQL. All have their benefits and weaknesses, but some are much easier to implement and more broadly useful than others.

The backup scheme you choose to deploy will depend heavily on your individual needs and resources, as well as your production environment. Whatever method you decide on, be sure to validate your backups and practice restoring the data, so that you can be sure that the process is functioning correctly.

By Justin Ellingwood
