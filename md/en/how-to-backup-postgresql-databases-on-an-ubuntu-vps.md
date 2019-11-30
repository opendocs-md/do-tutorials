---
author: Justin Ellingwood
date: 2013-08-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-backup-postgresql-databases-on-an-ubuntu-vps
---

# How To Backup PostgreSQL Databases on an Ubuntu VPS

### **What is PostgreSQL?**

PostgreSQL is a modern database management system. It is frequently used to store and manipulate information related to websites and applications.

As with any kind of valuable data, it is important to implement a backup scheme to protect against data loss. This guide will cover some practical ways that you can backup your PostgreSQL data.

We will be using an Ubuntu 12.04 VPS with PostgreSQL 9.1. Most modern distributions and recent versions of PostgreSQL will operate in a similar way.

## How to Back Up a PostgreSQL Database Using pg\_dump

PostgreSQL includes a utility called " **pg\_dump**" that can be used to dump database information into a file for backup purposes.

The pg\_dump utility is run from the Linux command line. The basic syntax of the command is:

    pg\_dump name\_of\_database \> name\_of\_backup\_file

The command must be run by a user with privileges to read all of the database information, so it is run as the superuser most of the time.

For a real-world example, we can log into the "postgres" user and execute the command on the default database, also called "postgres":

    sudo su - postgres pg\_dump postgres \> postgres\_db.bak

This command is actually a PostgreSQL client program, so it can be run from a remote system as long as that system has access to the database.

If you wish to backup a remote system, you can pass the "-h" flag for specifying the remote host, and the "-p" flag to give the remote port:

    pg\_dump -h remote\_host -p remote\_port name\_of\_database \> name\_of\_backup\_file

You can also specify a different user using the "-U" option if necessary. The syntax would be:

    pg\_dump -U user\_name -h remote\_host -p remote\_port name\_of\_database \> name\_of\_backup\_file

Keep in mind that the same authentication requirements exist for pg\_dump as for any other client program. This means that you must ensure that your log in credentials are valid for the systems you are trying to back up.

## How to Restore Data Dumps from pg\_dump with PostgreSQL

To restore a backup created by pg\_dump, you can redirect the file into **psql** standard input:

    psql empty\_database \< backup\_file

**Note: this redirection operation does not create the database in question. This must be done in a separate step prior to running the command.**

For example, we can create a new database called "restored\_database" and then redirect a dump called "database.bak" by issuing these commands:

    createdb -T template0 restored\_database psql restored\_database \< database.bak

The empty database should be created using "template0" as the base.

Another step that must be performed in order to restore correctly is to recreate any users who own or have grant permissions on objects within the database.

For instance, if your database had a table owned by the user "test\_user", you will have to create it on the restoration system prior to importing:

    createuser test\_user psql restored\_database \< database.bak

### **Dealing with Restoration Errors**

By default, PostgreSQL will attempt to continue restoring a database, even when it encounters an error along the way.

In many cases, this is undesirable for obvious reasons. It can be painful to try to sort out what operations are needed to restore the database to its proper state.

We can tell PostgreSQL to stop on any error by typing:

    psql --set ON\_ERROR\_STOP=on restored\_database \< backup\_file

This will cause a PostgreSQL restore operation to halt immediately when an error is encountered.

This will still leave you with a crippled database that hasn't been fully restored, but you can now handle errors as they come up instead of dealing with a list of errors at the end.

A better option in many situations can be the "-1" (the number one) or "--single-transaction" option:

    psql -1 restored\_database \< backup\_file

This option performs all of the restoration details in a single transaction.

The difference between this option and the "ON\_ERROR\_STOP" setting is that this will either succeed completely or not import anything.

This can be a costly trade-off for larger restorations, but in many cases, the benefit of not leaving you with a partially restored database heavily outweighs that cost.

## How to Backup & Restore All Databases in PostgreSQL

To save time, if you would like to backup all of the databases in your system, there is a utility called " **pg\_dumpall**".

They syntax of the command is very similar to the regular pg\_dump command, but it does not specify the database. Instead, the command backs up every available database:

    pg\_dumpall \> backup\_file

You can restore the databases by passing the file to psql, with the default database:

    psql -f backup\_file postgres

## Conclusion

Backups are an essential component in any kind of data storage plan. Fortunately, PostgreSQL gives you the utilities necessary to effectively backup your important information.

As with any kind of backup, it is important to test your backups regularly to ensure the copies that are created can be restored correctly. The backups you create are only useful if they can actually be used to recover your system.

By Justin Ellingwood
