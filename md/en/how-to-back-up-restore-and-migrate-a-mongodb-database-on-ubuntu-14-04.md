---
author: Anatoliy Dimitrov
date: 2016-04-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-restore-and-migrate-a-mongodb-database-on-ubuntu-14-04
---

# How To Back Up, Restore, and Migrate a MongoDB Database on Ubuntu 14.04

MongoDB is one of the most popular NoSQL database engines. It is famous for being scalable, powerful, reliable and easy to use. In this article we’ll show you how to back up, restore, and migrate your MongoDB databases.

Importing and exporting a database means dealing with data in a human-readable format, compatible with other software products. In contrast, the backup and restore operations create or use MongoDB-specific binary data, which preserves not only the consistency and integrity of your data but also its specific MongoDB attributes. Thus, for migration its usually preferable to use backup and restore as long as the source and target systems are compatible.

## Prerequisites

Before following this tutorial, please make sure you complete the following prerequisites:

- Ubuntu 14.04 Droplet
- Non-root sudo user. Check out [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) for details.
- MongoDB installed and configured using the article [How to Install MongoDB on Ubuntu 14.04](how-to-install-mongodb-on-ubuntu-14-04).
- Example MongoDB database imported using the instructions in [How To Import and Export a MongoDB Database on Ubuntu 14.04](how-to-import-and-export-a-mongodb-database-on-ubuntu-14-04)

Except otherwise noted, all of the commands that require root privileges in this tutorial should be run as a non-root user with sudo privileges.

## Understanding the Basics

Before continue further with this article some basic understanding on the matter is needed. If you have experience with popular relational database systems such as MySQL, you may find some similarities when working with MongoDB.

The first thing you should know is that MongoDB uses [json](http://json.org/) and bson (binary json) formats for storing its information. Json is the human-readable format which is perfect for exporting and, eventually, importing your data. You can further manage your exported data with any tool which supports json, including a simple text editor.

An example json document looks like this:

Example of json Format

    {"address":[
        {"building":"1007", "street":"Park Ave"},
        {"building":"1008", "street":"New Ave"},
    ]}

Json is very convenient to work with, but it does not support all the data types available in bson. This means that there will be the so called ‘loss of fidelity’ of the information if you use json. For backing up and restoring, it’s better to use the binary bson.

Second, you don’t have to worry about explicitly creating a MongoDB database. If the database you specify for import doesn’t already exist, it is automatically created. Even better is the case with the collections’ (database tables) structure. In contrast to other database engines, in MongoDB the structure is again automatically created upon the first document (database row) insert.

Third, in MongoDB reading or inserting large amounts of data, such as for the tasks of this article, can be resource intensive and consume much of the CPU, memory, and disk space. This is something critical considering that MongoDB is frequently used for large databases and Big Data. The simplest solution to this problem is to run the exports and backups during the night or during non-peak hours.

Fourth, information consistency could be problematic if you have a busy MongoDB server where the information changes during the database export or backup process. There is no simple solution to this problem, but at the end of this article, you will see recommendations to further read about replication.

While you can use the [import and export functions](how-to-import-and-export-a-mongodb-database-on-ubuntu-14-04) to backup and restore your data, there are better ways to ensure the full integrity of your MongoDB databases. To backup your data you should use the command `mongodump`. For restoring, use `mongorestore`. Let’s see how they work.

## Backing Up a MongoDB Database

Let’s cover backing up your MongoDB database first.

An important argument to `mongodump` is `--db`, which specifies the name of the database which you want to back up. If you don’t specify a database name, `mongodump` backups all of your databases. The second important argument is `--out` which specifies the directory in which the data will be dumped. Let’s take an example with backing up the `newdb` database and storing it in the `/var/backups/mongobackups` directory. Ideally, we’ll have each of our backups in a directory with the current date like `/var/backups/mongobackups/01-20-16` (20th January 2016). First, let’s create that directory `/var/backups/mongobackups` with the command:

    sudo mkdir /var/backups/mongobackups

Then our backup command should look like this:

    sudo mongodump --db newdb --out /var/backups/mongobackups/`date +"%m-%d-%y"`

A successfully executed backup will have an output such as:

Output of mongodump

    2016-01-20T10:11:57.685-0500 writing newdb.restaurants to /var/backups/mongobackups/01-20-16/newdb/restaurants.bson
    2016-01-20T10:11:57.907-0500 writing newdb.restaurants metadata to /var/backups/mongobackups/01-20-16/newdb/restaurants.metadata.json
    2016-01-20T10:11:57.911-0500 done dumping newdb.restaurants (25359 documents)
    2016-01-20T10:11:57.911-0500 writing newdb.system.indexes to /var/backups/mongobackups/01-20-16/newdb/system.indexes.bson

Note that in the above directory path we have used `date +"%m-%d-%y"` which gets the current date automatically. This will allow us to have the backups inside the directory `/var/backups/01-20-16/`. This is especially convenient when we automate the backups.

At this point you have a complete backup of the `newdb` database in the directory `/var/backups/mongobackups/01-20-16/newdb/`. This backup has everything to restore the `newdb` properly and preserve its so called “fidelity”.

As a general rule, you should make regular backups, such as on a daily basis, and preferably during a time when the server is least loaded. Thus, you can set the `mongodump` command as a cron job so that it’s run regularly, e.g. every day at 03:03 AM. To accomplish this open crontab, cron’s editor like this:

    sudo crontab -e

Note that when you run `sudo crontab` you will be editing the cron jobs for the root user. This is recommended because if you set the crons for your user, they might not be executed properly, especially if your sudo profile requires password verification.

Inside the crontab prompt insert the following `mongodump` command:

Crontab window

    3 3 * * * mongodump --out /var/backups/mongobackups/`date +"%m-%d-%y"`

In the above command we are omitting the `--db` argument on purpose because typically you will want to have all of your databases backed up.

Depending on your MongoDB database sizes you may soon run out of disk space with too many backups. That’s why it’s also recommended to clean the old backups regularly or to compress them. For example, to delete all the backups older than 7 days you can use the following bash command:

    find /var/backups/mongobackups/ -mtime +7 -exec rm -rf {} \;

Similarly to the previous `mongodump` command, this one can be also added as a cron job. It should run just before you start the next backup, e.g. at 03:01 AM. For this purpose open again crontab:

    sudo crontab -e

After that insert the following line:

Crontab window

    3 1 * * * find /var/backups/mongobackups/ -mtime +7 -exec rm -rf {} \;

Completing all the tasks in this step will ensure a good backup solution for your MongoDB databases.

## Restoring and Migrating a MongoDB Database

By restoring your MongoDB database from a previous backup (such as one from the previous step) you will be able to have the exact copy of your MongoDB information taken at a certain time, including all the indexes and data types. This is especially useful when you want to migrate your MongoDB databases. For restoring MongoDB we’ll be using the command `mongorestore` which works with the binary backup produced by `mongodump`.

Let’s continue our examples with the `newdb` database and see how we can restore it from the previously taken backup. As arguments we’ll specify first the name of the database with the `--db` argument. Then with `--drop` we’ll make sure that the target database is first dropped so that the backup is restored in a clean database. As a final argument we’ll specify the directory of the last backup `/var/backups/mongobackups/01-20-16/newdb/`. So the whole command will look like this (replace with the date of the backup you wish to restore):

    sudo mongorestore --db newdb --drop /var/backups/mongobackups/01-20-16/newdb/

A successful execution will show the following output:

Output of mongorestore

    2016-01-20T10:44:47.876-0500 building a list of collections to restore from /var/backups/mongobackups/01-20-16/newdb/ dir
    2016-01-20T10:44:47.908-0500 reading metadata file from /var/backups/mongobackups/01-20-16/newdb/restaurants.metadata.json
    2016-01-20T10:44:47.909-0500 restoring newdb.restaurants from file /var/backups/mongobackups/01-20-16/newdb/restaurants.bson
    2016-01-20T10:44:48.591-0500 restoring indexes for collection newdb.restaurants from metadata
    2016-01-20T10:44:48.592-0500 finished restoring newdb.restaurants (25359 documents)
    2016-01-20T10:44:48.592-0500 done

In the above case we are restoring the data on the same server where the backup has been created. If you wish to migrate the data to another server and use the same technique, you should just copy the backup directory, which is `/var/backups/mongobackups/01-20-16/newdb/` in our case, to the other server.

## Conclusion

This article has introduced you to the essentials of managing your MongoDB data in terms of backing up, restoring, and migrating databases. You can continue further reading on [How To Set Up a Scalable MongoDB Database](how-to-set-up-a-scalable-mongodb-database) in which MongoDB replication is explained.

Replication is not only useful for scalability, but it’s also important for the current topics. Replication allows you to continue running your MongoDB service uninterrupted from a slave MongoDB server while you are restoring the master one from a failure. Part of the replication is also the [operations log (oplog)](https://docs.mongodb.org/manual/core/replica-set-oplog/), which records all the operations that modify your data. You can use this log, just as you would use the binary log in MySQL, to restore your data after the last backup has taken place. Recall that backups usually take place during the night, and if you decide to restore a backup in the evening you will be missing all the updates since the last backup.
