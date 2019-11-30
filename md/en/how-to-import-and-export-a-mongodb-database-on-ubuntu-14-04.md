---
author: Anatoliy Dimitrov
date: 2016-04-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-import-and-export-a-mongodb-database-on-ubuntu-14-04
---

# How To Import and Export a MongoDB Database on Ubuntu 14.04

MongoDB is one of the most popular NoSQL database engines. It is famous for being scalable, powerful, reliable and easy to use. In this article we’ll show you how to import and export your MongoDB databases.

We should make clear that by import and export in this article we mean dealing with data in a human-readable format, compatible with other software products. In contrast, the backup and restore operations create or use MongoDB specific binary data, which preserves not only the consistency and integrity of your data but also its specific MongoDB attributes. Thus, for migration its usually preferable to use backup and restore as long as the source and target systems are compatible. Backup, restore, and migration are beyond the scope of this article — refer to [How To Back Up, Restore, and Migrate a MongoDB Database on Ubuntu 14.04](how-to-back-up-restore-and-migrate-a-mongodb-database-on-ubuntu-14-04).

## Prerequisites

Before following this tutorial, please make sure you complete the following prerequisites:

- Ubuntu 14.04 Droplet
- Non-root sudo user. Check out [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) for details.
- MongoDB installed and configured using the article [How to install MongoDB on Ubuntu 14.04](how-to-install-mongodb-on-ubuntu-14-04).

Except otherwise noted, all of the commands that require root privileges in this tutorial should be run as a non-root user with sudo privileges.

## Understanding the Basics

Before continuing further with this article some basic understanding on the matter is needed. If you have experience with popular relational database systems such as MySQL, you may find some similarities when working with MongoDB.

The first thing you should know is that MongoDB uses [json](http://json.org/) and bson (binary json) formats for storing its information. Json is the human readable format which is perfect for exporting and, eventually, importing your data. You can further manage your exported data with any tool which supports json, including a simple text editor.

An example json document looks like this:

Example of json Format

    {"address":[
        {"building":"1007", "street":"Park Ave"},
        {"building":"1008", "street":"New Ave"},
    ]}

Json is very convenient to work with, but it does not support all the data types available in bson. This means that there will be the so called ‘loss of fidelity’ of the information if you use json. That’s why for backup / restore it’s better to use the binary bson which would be able to better restore your MongoDB database.

Second, you don’t have to worry about explicitly creating a MongoDB database. If the database you specify for import doesn’t already exist, it is automatically created. Even better is the case with the collections’ (database tables) structure. In contrast to other database engines, in MongoDB the structure is again automatically created upon the first document (database row) insert.

Third, in MongoDB reading or inserting large amounts of data, such as for the tasks of this article, can be resource intensive and consume much of the CPU, memory, and disk space. This is something critical considering that MongoDB is frequently used for large databases and Big Data. The simplest solution to this problem is to run the exports / backups during the night.

Fourth, information consistency could be problematic if you have a busy MongoDB server where the information changes during the database export process. There is no simple solution to this problem, but at the end of this article, you will see recommendations to further read about replication.

## Importing Information Into MongoDB

To learn how importing information into MongoDB works let’s use a popular sample MongoDB database about restaurants. It’s in .json format and can be downloaded using `wget` like this:

    wget https://raw.githubusercontent.com/mongodb/docs-assets/primer-dataset/primer-dataset.json

Once the download completes you should have a file called `primer-dataset.json` (12 MB size) in the current directory. Let’s import the data from this file into a new database called `newdb` and into a collection called `restaurants`. For importing we’ll use the command `mongoimport` like this:

    sudo mongoimport --db newdb --collection restaurants --file primer-dataset.json

The result should look like this:

Output of mongoimport

    2016-01-17T14:27:04.806-0500 connected to: localhost
    2016-01-17T14:27:07.315-0500 imported 25359 documents

As the above command shows, 25359 documents have been imported. Because we didn’t have a database called `newdb`, MongoDB created it automatically.

Let’s verify the import by connecting to the newly created MongoDB database called `newdb` like this:

    sudo mongo newdb

You are now connected to the newly created `newdb` database instance. Notice that your prompt has changed, indicating that you are connected to the database.

Count the documents in the restaurants collection with the command:

    db.restaurants.count()

The result should show be `25359`, exactly the number of the imported documents. For an even better check you can select the first document from the restaurants collection like this:

    db.restaurants.findOne() 

The result should look like this:

Output of db.restaurants.findOne()

    {
            "_id" : ObjectId("569beb098106480d3ed99926"),
            "address" : {
                    "building" : "1007",
                    "coord" : [
                            -73.856077,
                            40.848447
                    ],
                    "street" : "Morris Park Ave",
                    "zipcode" : "10462"
            },
            "borough" : "Bronx",
            "cuisine" : "Bakery",
            "grades" : [
                    {
                            "date" : ISODate("2014-03-03T00:00:00Z"),
                            "grade" : "A",
                            "score" : 2
                    },
    ...
            ],
            "name" : "Morris Park Bake Shop",
            "restaurant_id" : "30075445"
    }

Such a detailed check could reveal problems with the documents such as their content, encoding, etc. The json format uses `UTF-8` encoding and your exports and imports should be in that encoding. Have this in mind if you edit manually the json files. Otherwise, MongoDB will automatically handle it for you.

To exit the MongoDB prompt, type `exit` at the prompt:

    exit

You will be returned to the normal command line prompt as your non-root user.

## Exporting Information From MongoDB

As we have previously mentioned, by exporting MongoDB information you can acquire a human readable text file with your data. By default, information is exported in json format but you can also export to csv (comma separated value).

To export information from MongoDB, use the command `mongoexport`. It allows you to export a very fine-grained export so that you can specify a database, a collection, a field, and even use a query for the export.

A simple `mongoexport` example would be to export the restaurants collection from the `newdb` database which we have previously imported. It can be done like this:

    sudo mongoexport --db newdb -c restaurants --out newdbexport.json

In the above command, we use `--db` to specify the database, `-c` for the collection and `--out` for the file in which the data will be saved.

The output of a successful `mongoexport` should look like this:

Output of mongoexport

    2016-01-20T03:39:00.143-0500 connected to: localhost
    2016-01-20T03:39:03.145-0500 exported 25359 records

The above output shows that 25359 documents have been imported — the same number as of the imported ones.

In some cases you might need to export only a part of your collection. Considering the structure and content of the restaurants json file, let’s export all the restaurants which satisfy the criteria to be situated in the Bronx borough and to have Chinese cuisine. If we want to get this information directly while connected to MongoDB, connect to the database again:

    sudo mongo newdb

Then, use this query:

    db.restaurants.find( { borough: "Bronx", cuisine: "Chinese" } )

The results are displayed to the terminal. To exit the MongoDB prompt, type `exit` at the prompt:

    exit

If you want to export the data from a sudo command line instead of while connected to the database, make the previous query part of the `mongoexport` command by specifying it for the `-q` argument like this:

    sudo mongoexport --db newdb -c restaurants -q "{ borough: 'Bronx', cuisine: 'Chinese' }" --out Bronx_Chinese_retaurants.json

Note that we are using single quotes inside the double quotes for the query conditions. If you use double quotes or special characters like `$` you will have to escape them with backslash (`\`) in the query.

If the export has been successful, the result should look like this:

Output of mongoexport

    2016-01-20T04:16:28.381-0500 connected to: localhost
    2016-01-20T04:16:28.461-0500 exported 323 records

The above shows that 323 records have been exported, and you can find them in the `Bronx_Chinese_retaurants.json` file which we have specified.

## Conclusion

This article has introduced you to the essentials of importing and exporting information to and from a MongoDB database. You can continue further reading on [How To Back Up, Restore, and Migrate a MongoDB Database on Ubuntu 14.04](how-to-back-up-restore-and-migrate-a-mongodb-database-on-ubuntu-14-04) and [How To Set Up a Scalable MongoDB Database](how-to-set-up-a-scalable-mongodb-database).

Replication is not only useful for scalability, but it’s also important for the current topics. Replication allows you to continue running your MongoDB service uninterrupted from a slave MongoDB server while you are restoring the master one from a failure. Part of the replication is also the [operations log (oplog)](https://docs.mongodb.org/manual/core/replica-set-oplog/), which records all the operations that modify your data. You can use this log, just as you would use the binary log in MySQL, to restore your data after the last backup has taken place. Recall that backups usually take place during the night, and if you decide to restore a backup in the evening you will be missing all the updates since the last backup.
