---
author: Mitchell Anicas
date: 2015-04-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-centos-7
---

# How To Create Hot Backups of MySQL Databases with Percona XtraBackup on CentOS 7

## Introduction

A very common challenge encountered when working with active database systems is performing hot backups—that is, creating backups without stopping the database service or making it read-only. Simply copying the data files of an active database will often result in a copy of the database that is internally inconsistent, i.e. it will not be usable or it will be missing transactions that occurred during the copy. On the other hand, stopping the database for scheduled backups renders database-dependent portions of your application to become unavailable. Percona XtraBackup is an open source utility that can be used to circumvent this issue, and create consistent full or incremental backups of running MySQL, MariaDB, and Percona Server databases, also known as hot backups.

As opposed to the _logical backups_ that utilities like mysqldump produce, XtraBackup creates _physical backups_ of the database files—it makes a copy of the data files. Then it applies the transaction log (a.k.a. redo log) to the physical backups, to backfill any active transactions that did not finish during the creation of the backups, resulting in consistent backups of a running database. The resulting database backup can then be backed up to a remote location using [rsync](how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps), a backup system like [Bacula](how-to-install-bacula-server-on-centos-7), or [DigitalOcean backups](understanding-digitalocean-droplet-backups).

This tutorial will show you how to perform a full hot backup of your MySQL or MariaDB databases using Percona XtraBackup on CentOS 7. The process of restoring the database from a backup is also covered. The Ubuntu version of this guide can be found [here](how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-ubuntu-14-04).

## Prerequisites

To follow this tutorial, you must have the following:

- Superuser privileges on an CentOS 7 system
- A running MySQL or MariaDB database
- Access to the admin user (root) of your database

Also, to perform a hot backup of your database, your database system must be using the **InnoDB** storage engine. This is because XtraBackup relies on the transaction log that InnoDB maintains. If your databases are using the MyISAM storage engine, you can still use XtraBackup but the database will be locked for a short period towards the end of the backup.

### Check Storage Engine

If you are unsure of which storage engine your databases use, you can look it up through a variety of methods. One way is to use the MySQL console to select the database in question, then output the status of each table.

First, enter the MySQL console:

    mysql -u root -p

Then enter your MySQL root password.

At the MySQL prompt, select the database that you want to check. Be sure to substitute your own database name here:

    USE database_name;

Then print its table statuses:

    SHOW TABLE STATUS\G;

The engine should be indicated for each row in the database:

    Example Output:...
    ***************************11. row***************************
               Name: wp_users
             Engine: InnoDB
    ...

Once you are done, leave the console:

    exit

Let’s install Percona XtraBackup.

## Install Percona XtraBackup

The easiest way to install Percona XtraBackup is to use yum, as Percona’s repository provides an RPM.

    sudo yum install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm

Then, you can run this command to install XtraBackup:

    sudo yum install percona-xtrabackup

Accept any confirmation prompts to complete the installation.

XtraBackup consists primarily of the XtraBackup program, and the `innobackupex` Perl script, which we will use to create our database backups.

## First Time Preparations

Before using XtraBackup for the first time, we need to prepare system and MySQL user that XtraBackup will use. This section covers the initial preparation.

### System User

Unless you plan on using the system root user, you must perform some basic preparations to ensure that XtraBackup can be executed properly. We will assume that you are logged in as the user that will run XtraBackup, and that it has superuser privileges.

Add your system user to the “mysql” group (substitute in your actual username):

    sudo gpasswd -a username mysql

While we’re at it, let’s create the directory that will be used for storing the backups that XtraBackup creates:

    sudo mkdir -p /data/backups
    sudo chown -R username: /data

The `chown` command ensures that the user will be able to write to the backups directory.

### MySQL User

XtraBackup requires a MySQL user that it will use when creating backups. Let’s create one now.

Enter the MySQL console with this command:

    mysql -u root -p

Supply the MySQL root password.

At the MySQL prompt, create a new MySQL user and assign it a password. In this example, the user is called “bkpuser” and the password is “bkppassword”. Change both of these to something secure:

    CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY 'bkppassword';

Next, grant the new MySQL user reload, lock, and replication privileges to all of the databases:

    GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'bkpuser'@'localhost';
    FLUSH PRIVILEGES;

These are the minimum required privileges that XtraBackup needs to create full backups of databases.

When you are finished, exit the MySQL console:

    exit

Now we’re ready to create a full backup of our databases.

## Perform Full Hot Backup

This section covers the steps that are necessary to create a full hot backup of a MySQL database using XtraBackup. After ensuring that the database file permissions are correct, we will use XtraBackup to **create** a backup, then **prepare** it.

### Update Datadir Permissions

On CentOS 7, MySQL’s data files are stored in `/var/lib/mysql`, which is sometimes referred to as a **datadir**. By default, access to the datadir is restricted to the `mysql` user. XtraBackup requires access to this directory to create its backups, so let’s run a few commands to ensure that the system user we set up earlier—as a member of the mysql group—has the proper permissions:

    sudo chown -R mysql: /var/lib/mysql
    sudo find /var/lib/mysql -type d -exec chmod 775 "{}" \;

These commands ensure that all of the directories in the datadir are accessible to the mysql group, and should be run prior to each backup.

    If you added your user to the mysql group in the same session, you will need to login again for the group membership changes to take effect.

### Create Backup

Now we’re ready to create the backup. With the MySQL database running, use the `innobackupex` utility to do so. Run this command after updating the user and password to match your MySQL user’s login:

    innobackupex --user=bkpuser --password=bkppassword --no-timestamp /data/backups/new_backup

This will create a backup of the database at the location specified, `/data/backups/new_backup`:

    innobackupex outputinnobackupex: Backup created in directory '/data/backups/new_backup'
    150420 13:50:10 innobackupex: Connection to database server closed
    150420 13:50:10 innobackupex: completed OK!

**Alternatively** , you may omit the `--no-timestamp` to have XtraBackup create a backup directory based on the current timestamp, like so:

    innobackupex --user=bkpuser --password=bkppassword /data/backups

This will create a backup of the database in an automatically generated subdirectory, like so:

    innobackupex output — no timestampinnobackupex: Backup created in directory '/data/backups/2015-04-20_13-50-07'
    150420 13:50:10 innobackupex: Connection to database server closed
    150420 13:50:10 innobackupex: completed OK!

Either method that you decide on should output “innobackupex: completed OK!” on the last line of its output. A successful backup will result in a copy of the database datadir, which must be **prepared** before it can be used.

## Prepare Backup

The last step in creating a hot backup with XtraBackup is to **prepare** it. This involves “replaying” the transaction log to apply any uncommitted transaction to the backup. Preparing the backup will make its data consistent, and usable for a restore.

Following our example, we will prepare the backup that was created in `/data/backups/new_backup`. Substitute this with the path to your actual backup:

    innobackupex --apply-log /data/backups/new_backup

Again, you should see “innobackupex: completed OK!” as the last line of output.

Your database backup has been created and is ready to be used to restore your database. Also, if you have a file backup system, such as [Bacula](https://www.digitalocean.com/community/tutorial_series/how-to-use-bacula-on-ubuntu-14-04), this database backup should be included as part of your backup selection.

The next section will cover how to restore your database from the backup we just created.

## Perform Backup Restoration

Restoring a database with XtraBackup requires that the database is stopped, and that its datadir is empty.

Stop the MySQL service with this command:

    sudo systemctl stop mariadb

Then move or delete the contents of the datadir (`/var/lib/mysql`). In our example, we’ll simply move it to a temporary location:

    mkdir /tmp/mysql
    mv /var/lib/mysql/* /tmp/mysql/

Now we can restore the database from our backup, “new\_backup”:

    innobackupex --copy-back /data/backups/new_backup

If it was successful, the last line of output should say “innobackupex: completed OK!”

The restored files in datadir will probably belong to the user you ran the restore process as. Change the ownership back to mysql, so MySQL can read and write the files:

    sudo chown -R mysql: /var/lib/mysql

Now we’re ready to start MySQL:

    sudo systemctl start mariadb

That’s it! Your restored MySQL database should be up and running.

## Conclusion

Now that you are able to create hot backups of your MySQL database using Percona XtraBackup, there are several things that you should consider setting up.

First of all, it is advisable to automate the process so you will have backups created according to a schedule. Second, you should make remote copies of the backups, in case your database server has problems, by using something like [rsync](how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps), a network file backup system like [Bacula](how-to-install-bacula-server-on-centos-7), or [DigitalOcean backups](understanding-digitalocean-droplet-backups). After that, you will want to look into **rotating** your backups (deleting old backups on a schedule) and creating incremental backups (with XtraBackup) to save disk space.

Good luck!
