---
author: finid
date: 2016-01-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-import-and-export-an-orientdb-database-on-ubuntu-14-04
---

# How To Import and Export an OrientDB Database on Ubuntu 14.04

## Introduction

OrientDB is a multi-model, NoSQL database, with support for graph and document databases. It is a Java application and can run on any operating system. It’s also fully ACID-complaint with support for multi-master replication. It is developed by a company of the same name, with an Enterprise and a Community edition.

In this article, we’ll be using the **GratefulDeadConcerts** database to demonstrate how to export and import an OrientDB database. That database comes with every installation of OrientDB, so you don’t have to create a new one.

## Prerequisites

To complete the tutorial, you’ll need the following:

- Ubuntu 14.04 Droplet (see the [initial setup guide](initial-server-setup-with-ubuntu-14-04))

- Latest edition of OrientDB installed using [How To Install and Configure OrientDB on Ubuntu 14.04](how-to-install-and-configure-orientdb-on-ubuntu-14-04)

If you all all those things in place, let’s get started.

## Step 1 — Export an Existing OrientDB Database

To import an OrientDB database, you must first export the DB to be imported. In this step, we’ll export the database that we need to import.

If OrientDB is not running, start it:

    sudo service orientdb start

If you aren’t sure whether or not it is running, you can always check its status:

    sudo service orientdb status

Then connect to the server using the OrientDB console:

    sudo -u orientdb /opt/orientdb/bin/console.sh

The output should be:

    OutputOrientDB console v.2.1.3 (build UNKNOWN@r; 2015-10-04 10:56:30+0000) www.orientdb.com
    Type 'help' to display all the supported commands.
    Installing extensions for GREMLIN language v.2.6.0
    
    orientdb>

Connect to the database that you wish to export. Here we’re connecting to the **GratefulDeadConcerts** database using the database’s default user **admin** and its password **admin** :

    connect plocal:/opt/orientdb/databases/GratefulDeadConcerts admin admin

You should see an output like this:

    OutputConnecting to database [plocal:/opt/orientdb/databases/GratefulDeadConcerts] with user 'admin'...OK
    orientdb {db=GratefulDeadConcerts}>

Alternatively, you can also connect to the database using the remote mode, which allows multiple users to access the same database.

    connect remote:127.0.0.1/GratefulDeadConcerts admin admin

The connection output should be of this sort:

    OutputDisconnecting from the database [null]...OK
    Connecting to database [remote:127.0.0.1/GratefulDeadConcerts] with user 'admin'...OK
    orientdb {db=GratefulDeadConcerts}>

Now, export the database. The `export` command exports the current database to a gzipped, compressed JSON file. In this example, we’re exporting it into OrientDB’s database directory `/opt/orientdb/databases`:

    export database /opt/orientdb/databases/GratefulDeadConcerts.export

The complete export command output for the target database is:

    OutputExporting current database to: database /opt/orientdb/databases/GratefulDeadConcerts.export in GZipped JSON format ...
    
    Started export of database 'GratefulDeadConcerts' to /opt/orientdb/databases/GratefulDeadConcerts.export.gz...
    Exporting database info...OK
    Exporting clusters...OK (15 clusters)
    Exporting schema...OK (14 classes)
    Exporting records...
    - Cluster 'internal' (id=0)...OK (records=3/3)
    - Cluster 'index' (id=1)...OK (records=5/5)
    - Cluster 'manindex' (id=2)...OK (records=1/1)
    - Cluster 'default' (id=3)...OK (records=0/0)
    - Cluster 'orole' (id=4)...OK (records=3/3)
    - Cluster 'ouser' (id=5)...OK (records=3/3)
    - Cluster 'ofunction' (id=6)...OK (records=0/0)
    - Cluster 'oschedule' (id=7)...OK (records=0/0)
    - Cluster 'orids' (id=8)...OK (records=0/0)
    - Cluster 'v' (id=9).............OK (records=809/809)
    - Cluster 'e' (id=10)...OK (records=0/0)
    - Cluster 'followed_by' (id=11).............OK (records=7047/7047)
    - Cluster 'written_by' (id=12).............OK (records=501/501)
    - Cluster 'sung_by' (id=13).............OK (records=501/501)
    - Cluster '_studio' (id=14)...OK (records=0/0)
    
    Done. Exported 8873 of total 8873 records
    
    Exporting index info...
    - Index OUser.name...OK
    - Index dictionary...OK
    - Index ORole.name...OK
    OK (3 indexes)
    Exporting manual indexes content...
    - Exporting index dictionary ...OK (entries=0)
    OK (1 manual indexes)
    
    Database export completed in 60498ms

That completes the export step.

Open another terminal to your Droplet, and list the contents of the database directory:

    ls -lh /opt/orientdb/databases

You should see the original database plus the compressed file for your database export:

    Outputtotal 164K
    drwxr-xr-x 2 orientdb orientdb 4.0K Nov 27 02:36 GratefulDeadConcerts
    -rw-r--r-- 1 orientdb orientdb 158K Nov 27 14:19 GratefulDeadConcerts.export.gz

Back at the terminal with your OrientDB console, you may now disconnect from the current database by typing:

    disconnect

If successfully disconnected, you should get an output similar to:

    OutputDisconnecting from the database [GratefulDeadConcerts]...OK
    orientdb>

Keep the connection to the console open, because you’ll be using it in the next step.

## Step 2 — Import Database

In this step, we’ll import the database we exported in Step 1. By default, importing a database overwrites the existing data in the one it’s being imported into. So, first connect to the target database. In this example, we’ll be connecting to the default database that we used in Step 1.

    connect plocal:/opt/orientdb/databases/GratefulDeadConcerts admin admin

You can also connect using:

    connect remote:127.0.0.1/GratefulDeadConcerts admin admin

Either output should be similar to this:

    OutputConnecting to database [remote:127.0.0.1/GratefulDeadConcerts] with user 'admin'...OK
    orientdb {db=GratefulDeadConcerts}>

With the connection established, let’s import the exported file:

    import database /opt/orientdb/databases/GratefulDeadConcerts.export.gz

Depending on the number of records to be imported, this can take more than a few minutes. So sit back and relax, or reach for that cup of your favorite liquid.

The import output should be (output truncated):

    OutputImporting database database /opt/orientdb/databases/GratefulDeadConcerts.export.gz...
    Started import of database 'remote:127.0.0.1/GratefulDeadConcerts' from /opt/orientdb/databases/GratefulDeadConcerts.export.gz...
    Non merge mode (-merge=false): removing all default non security classes
    
    ...
    
    Done. Imported 8,865 records in 915.51 secs
    
    
    Importing indexes ...
    - Index 'OUser.name'...OK
    - Index 'dictionary'...OK
    - Index 'ORole.name'...OK
    Done. Created 3 indexes.
    Importing manual index entries...
    - Index 'dictionary'...OK (0 entries)
    Done. Imported 1 indexes.
    Rebuild of stale indexes...
    Stale indexes were rebuilt...
    Deleting RID Mapping table...OK
    
    
    Database import completed in 1325943 ms

You can now disconnect from the database:

    disconnect

The exit the OrientDB console and return to your regular shell prompt, type `exit`:

    exit

## Conclusion

You’ve just seen how to export and import an OrientDB database. Note that the import/export feature does not lock the database during the entire process, so it’s possible for it to be receiving writes as the process is taking place. For more information on this topic, see the [official OrientDB export/import guide](http://orientdb.com/docs/last/Export-and-Import.html).
