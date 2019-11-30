---
author: finid
date: 2015-12-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-your-orientdb-databases-on-ubuntu-14-04
---

# How To Back Up Your OrientDB Databases on Ubuntu 14.04

## Introduction

OrientDB is a multi-model, NoSQL database with support for graph and document databases. It is a Java application and can run on any operating system; it’s also fully ACID-complaint with support for multi-master replication.

An OrientDB database can be backed up using a backup script and also via the command line interface, with built-in support for compression of backup files using the ZIP algorithm.

By default, backing up an OrientDB database is a blocking operation — writes to be database are locked until the end of the backup operation, but if the operating system was installed on an LVM partitioning scheme, the backup script can perform a non-blocking backup. LVM is the Linux Logical Volume Manager.

In this article, you’ll learn how to backup your OrientDB database on an Ubuntu 14.04 server.

## Prerequisites

- Ubuntu 14.04 server (see ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04))
- OrientDB installed and configured using [How To Install and Configure OrientDB on Ubuntu 14.04](how-to-install-and-configure-orientdb-on-ubuntu-14-04)

## Step 1 — Backing Up OrientDB Using the Backup Script

OrientDB comes with a backup script located in the `bin` folder of the installation directory. If you installed OrientDB using [How To Install and Configure OrientDB on Ubuntu 14.04](how-to-install-and-configure-orientdb-on-ubuntu-14-04), then the installation directory is `/opt/orientdb`, so the backup script `backup.sh` should be in the `/opt/orientdb/bin`.

For this tutorial, create a `backup` folder under the installation directory to hold the backups. You may also opt to save the backups in the `databases` folder, which is the application’s data directory. For this tutorial, we will use the `backup` folder, so create the `backup` directory:

    sudo mkdir -p /opt/orientdb/backup

The newly-created folder is owned by root, so let’s change the ownership so that it’s owned by the **orientdb** user. Failure to do this will lead to an error when backing up from the command line interface, which you’ll learn how to accomplish in Step 2:

    sudo chown -R orientdb:orientdb /opt/orientdb/backup

With that out of the way, navigate into the `bin` directory:

    cd /opt/orientdb/bin

By default, a database called `GratefulDeadConcerts` exists. Listing of the contents of the `databases` directory will show this default database and any that you have created:

    ls -l /opt/orientdb/databases

For example, the following shows the `GratefulDeadConcerts` database and one called `eck`:

    Outputtotal 8
    drwxr-xr-x 2 orientdb orientdb 4096 Oct 12 18:36 eck
    drwxr-xr-x 2 orientdb orientdb 4096 Oct 4 06:30 GratefulDeadConcerts

In this step, we’ll back up both databases using the backup script. And in both cases, we’ll be performing the operation as the **admin** user, whose password is also **admin**. To perform a default (blocking) backup of the default database, type:

    sudo ./backup.sh plocal:../databases/GratefulDeadConcerts admin admin ../backup/gfdc.zip

For the second database, type:

    sudo ./backup.sh plocal:../databases/eck admin admin ../backup/eck.zip

Verify that the backups were created:

    ls -lh ../backup

The expected output is:

    Outputtotal 236K
    -rw-r--r-- 1 root root 17K Oct 13 08:48 eck.zip
    -rw-r--r-- 1 root root 213K Oct 13 08:47 gfdc.zip

## Step 2 — Backing Up OrientDB from the Console

In this step, we’ll back up one of the databases from the console, or the command line interface. To enter the command line interface, type:

    sudo -u orientdb /opt/orientdb/bin/console.sh

The output should be:

    OutputOrientDB console v.2.1.3 (build UNKNOWN@r; 2015-10-04 10:56:30+0000) www.orientdb.com
    Type 'help' to display all the supported commands.
    Installing extensions for GREMLIN language v.2.6.0
    
    orientdb>

Next, connect to the database. Here we’re connecting using the database’s default user **admin** and its password **admin**.

    connect plocal:/opt/orientdb/databases/eck admin admin

You should see an output like this:

    OutputDisconnecting from the database [null]...OK
    Connecting to database [plocal:/opt/orientdb/databases/eck] with user 'admin'...OK
    orientdb {db=eck}>

Now, perform a blocking backup of the database into the same backup directory that we created in Step 1:

    backup database /opt/orientdb/backup/eckconsole.zip

You should see an output like this:

    OutputBackuping current database to: database /opt/orientdb/backup/eckconsole.zip...
    
    - Compressing file name_id_map.cm...ok size=912b compressedSize=250 ratio=73% elapsed=1ms
    - Compressing file e.pcl...ok size=65.00KB compressedSize=121 ratio=100% elapsed=13ms
    
    ...
    
    
    - Compressing file orids.cpm...ok size=1024b compressedSize=15 ratio=99% elapsed=1ms
    - Compressing file internal.pcl...ok size=129.00KB compressedSize=9115 ratio=94% elapsed=9ms
    Backup executed in 0.33 seconds

Exit the OrientDB database prompt:

    exit

Confirm that the backup is in place:

    ls -lh ../backup

Output should be similar to this:

    Outputtotal 256K
    -rw-r--r-- 1 orientdb orientdb 17K Oct 13 10:39 eckconsole.zip
    -rw-r--r-- 1 orientdb orientdb 17K Oct 13 08:48 eck.zip
    -rw-r--r-- 1 orientdb orientdb 213K Oct 13 08:47 gfdc.zip

## Step 3 —&nbsp;Backing Up OrientDB Automatically

OrientDB has automatic backup capability, but it’s off by default. In this step, we’ll enable it so that the databases are backed up daily. The parameters for automatic backup have to be tweaked in the configuration file, so open it:

    sudo nano /opt/orientdb/config/orientdb-server-config.xml

Scroll to the **handler** element with **class=“com.orientechnologies.orient.server.handler.OAutomaticBackup”**. When enabled, the other default settings set automatic backup to take place at 23:00:00 GMT at 4 hour intervals. With the settings shown below, automatic backup will take place at the same time, but only once daily.

For testing purposes, you can adjust the **firsttime** parameter to your liking:

    /opt/orientdb/config/orientdb-server-config.xml
    <handler class="com.orientechnologies.orient.server.handler.OAutomaticBackup">
    <parameters>
    <parameter value="true" name="enabled"/>
    <parameter value="24h" name="delay"/>
    <parameter value="23:00:00" name="firstTime"/>
    <parameter value="backup" name="target.directory"/>
    <parameter value="${DBNAME}-${DATE:yyyyMMddHHmmss}.zip" name="target.fileName"/>
    <parameter value="9" name="compressionLevel"/>
    <parameter value="1048576" name="bufferSize"/>
    <parameter value="" name="db.include"/>
    <parameter value="" name="db.exclude"/>
    </parameters>
    </handler>

When you’ve finished tweaking the settings, save and close the file. To apply the changes, stop the daemon:

    sudo service orientdb stop

Then restart it:

    sudo service orientdb start

After the set time, verify that it worked by looking in the new `backup` directory:

    ls -lh /opt/orientdb/bin/backup

The output should be similar to this:

    Outputtotal 236K
    -rw-r--r-- 1 orientdb orientdb 17K Oct 13 16:00 eck-20151013160001.zip
    -rw-r--r-- 1 orientdb orientdb 213K Oct 13 16:00 gratefulnotdead-20151013160002.zip

Out of the box, the default database `GratefulDeadConcert` is not backed up by the automatic backup tool, so if you don’t see it listed, that’s a feature.

## Conclusion

You’ve just learned all the non-programmatic steps available for backing up an OrientDB database. For more information on this topic, visit the [official guide](http://orientdb.com/docs/last/Backup-and-Restore.html).
