---
author: Hathy A
date: 2016-03-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-and-use-mongodb-backups-on-ubuntu-14-04
---

# How to Create and Use MongoDB Backups on Ubuntu 14.04

## Introduction

A lot of modern web application developers today choose to use a NoSQL database in their projects, and MongoDB is often their first choice. If you’re using MongoDB in a production scenario, it is important that you regularly create backups in order to avoid data loss. Fortunately, MongoDB offers simple command line tools to create and use backups. This tutorial will explain how to use those tools.

To understand how backups work without tampering with your existing databases, this tutorial will start by walking you through creating a new database and adding a small amount of data to it. You are then going to create a backup of the database, then delete the database and restore it using the backup.

## Prerequisites

To follow along, you will need:

- One 64-bit Ubuntu 14.04 Droplet with a [sudo non-root user](initial-server-setup-with-ubuntu-14-04)

- MongoDB 3.0.7 installed on your server, which you can do by following [this MongoDB installation guide](how-to-install-mongodb-on-ubuntu-14-04)

## Step 1 — Creating an Example Database

Creating a backup of an empty database isn’t very useful, so in this step, we’ll create an example database and add some data to it.

The easiest way to interact with a MongoDB instance is to use the `mongo` shell. Open it with the `mongo` command.

    mongo

Once you have the MongoDB prompt, create a new database called **myDatabase** using the `use` helper.

    use myDatabase

Output

    switched to db myDatabase

All data in a MongoDB database should belong to a _collection_. However, you don’t have to create a collection explicitly. When you use the `insert` method to write to a non-existent collection, the collection is created automatically before the data is written.

You can use the following code to add three small documents to a collection called **myCollection** using the `insert` method:

    db.myCollection.insert([
        {'name': 'Alice', 'age': 30},
        {'name': 'Bill', 'age': 25},
        {'name': 'Bob', 'age': 35}
    ]);

If the insertion is successful, you’ll see a message which looks like this:

Output of a successful insert() operation

    BulkWriteResult({
        "writeErrors" : [],
        "writeConcernErrors" : [],
        "nInserted" : 3,
        "nUpserted" : 0,
        "nMatched" : 0,
        "nModified" : 0,
        "nRemoved" : 0,
        "upserted" : []
    })

## Step 2 — Checking the Size of the Database

Now that you have a database containing data, you can create a backup for it. However, backups will be large if you have a large database, and in order to avoid the risk of running out of storage space, and consequently slowing down or crashing your server, you should check the size of your database before you create a backup.

You can use the `stats` method and inspect the value of the `dataSize` key to know the size of your database in bytes.

    db.stats().dataSize;

For the current database, the value of `dataSize` will be a small number:

Output of db.stats().datasize

    592

Note that the value of `dataSize` is only a rough estimate of the size of the backup.

## Step 3 — Creating a Backup

To create a backup, you can use a command-line utility called `mongodump`. By default, `mongodump` will create a backup of all the databases present in a MongoDB instance. To create a backup of a specific database, you must use the `-d` option and specify the name of the database. Additionally, to let `mongodump` know where to store the backup, you must use the `-o` option and specify a path.

If you are still inside the `mongo` shell, exit it by pressing `CTRL+D`.

Type in the following command to create a backup of **myDatabase** and store it in `~/backups/first_backup`:

    mongodump -d myDatabase -o ~/backups/first_backup

If the backup creation is successful, you will see the following log messages:

Successful backup creation logs

    2015-11-24T18:11:58.590-0500 writing myDatabase.myCollection to /home/me/backups/first_backup/myDatabase/myCollection.bson
    2015-11-24T18:11:58.591-0500 writing myDatabase.myCollection metadata to /home/me/backups/first_backup/myDatabase/myCollection.metadata.json
    2015-11-24T18:11:58.592-0500 done dumping myDatabase.myCollection (3 documents)
    2015-11-24T18:11:58.592-0500 writing myDatabase.system.indexes to /home/me/backups/first_backup/myDatabase/system.indexes.bson

Note that the backup is not a single file; it’s actually a directory which has the following structure:

Directory structure of a MongoDB backup

    first_backup
    └── myDatabase
        ├── myCollection.bson
        ├── myCollection.metadata.json
        └── system.indexes.bson

## Step 4 — Deleting the Database

To test the backup you created, you can either use a MongoDB instance running on a different server or delete the database on your current server. In this tutorial, we’ll do the latter.

Open the `mongo` shell and connect to **myDatabase**.

    mongo myDatabase

Delete the database using the `dropDatabase` method.

    db.dropDatabase();

If the deletion is successful, you’ll see the following message:

Output of dropDatabase()

    { "dropped" : "myDatabase", "ok" : 1 }

You can now use the `find` method of your collection to see that all the data you inserted earlier is gone.

    db.myCollection.find(); 

There will be no output from this command because there’s no data to display in the database.

## Step 5 — Restoring the Database

To restore a database using a backup created using `mongodump`, you can use another command line utility called `mongorestore`. Before you use it, exit the `mongo` shell by pressing `CTRL+D`.

Using `mongorestore` is very simple. All it needs is the path of the directory containing the backup. Here’s how you can restore your database using the backup stored in `~/backupts/first_backup`:

    mongorestore ~/backups/first_backup/

You’ll see the following log messages if the restore operation is successful:

Successful restore logs

    2015-11-24T18:27:04.250-0500 building a list of dbs and collections to restore from /home/me/backups/first_backup/ dir
    2015-11-24T18:27:04.251-0500 reading metadata file from /home/me/backups/first_backup/myDatabase/myCollection.metadata.json
    2015-11-24T18:27:04.252-0500 restoring myDatabase.myCollection from file /home/me/backups/first_backup/myDatabase/myCollection.bson
    2015-11-24T18:27:04.309-0500 restoring indexes for collection myDatabase.myCollection from metadata
    2015-11-24T18:27:04.310-0500 finished restoring myDatabase.myCollection (3 documents)
    2015-11-24T18:27:04.310-0500 done

To examine the restored data, first, open the `mongo` shell and connect to `myDatabase`.

    mongo myDatabase

Then, call the `find` method on your `collection`.

    db.myCollection.find();

If everything went well, you should now be able to see all the data you inserted earlier.

Output of find()

    { "_id" : ObjectId("5654e76f21299039c2ba8720"), "name" : "Alice", "age" : 30 }
    { "_id" : ObjectId("5654e76f21299039c2ba8721"), "name" : "Bill", "age" : 25 }
    { "_id" : ObjectId("5654e76f21299039c2ba8722"), "name" : "Bob", "age" : 35 }

## Conclusion

In this tutorial, you learned how to use `mongodump` and `mongorestore` to back up and restore a MongoDB database. Note that creating a backup is an expensive operation, and can reduce the performance of your MongoDB instance. Therefore, it is recommended that you create your backups only during off-peak hours.

To learn more about MongoDB backup strategies, you can refer to the [MongoDB 3.0 manual](https://docs.mongodb.org/manual/core/backups/).
