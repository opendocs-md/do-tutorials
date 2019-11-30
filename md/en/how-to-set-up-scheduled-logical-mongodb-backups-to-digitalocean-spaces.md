---
author: Hanif Jetha
date: 2018-05-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-scheduled-logical-mongodb-backups-to-digitalocean-spaces
---

# How To Set Up Scheduled MongoDB Backups to DigitalOcean Spaces

## Introduction

Regular database backups are a crucial step in guarding against unintended data loss events. In general, there are two broad categories of backups: filesystem-level (“physical”) backups and logical backups.

Filesystem-level backups involve snapshotting the underlying data files at a point in time, and allowing the database to cleanly recover using the state captured in the snapshotted files. They are instrumental in backing up large databases quickly, especially when used in tandem with filesystem snapshots, such as [LVM snapshots](http://tldp.org/HOWTO/LVM-HOWTO/snapshots_backup.html), or block storage volume snapshots, such as [DigitalOcean Block Storage Snapshots](an-introduction-to-digitalocean-snapshots).

Logical backups involve using a tool (e.g. `mongodump` or `pg_dump`) to export data from the database into backup files, which are then restored using a corresponding restore tool (e.g. `mongorestore` or `pg_restore`). They offer granular control over what data to back up and restore and backups are often portable across database versions and installations. As logical backup tools read all data being backed up through memory, they can be slow and cause non-trivial additional load for particularly large databases.

Designing an effective backup and recovery strategy often involves trading off performance impact, implementation costs, and data storage costs with recovery speed, data integrity, and backup coverage. The optimal solution will depend on your recovery point and time [objectives](https://en.wikipedia.org/wiki/Recovery_point_objective) and database scale and architecture.

In this guide, we’ll demonstrate how to back up a MongoDB database using `mongodump`, a built-in logical backup tool. We’ll then show how to compress and upload the resulting serialized data backup files to [DigitalOcean Spaces](an-introduction-to-digitalocean-spaces), a highly redundant object store. We’ll also show how to regularly schedule the backup and upload operation using Bash and `cron`, and finally conclude with a sample data recovery scenario.

By the end of this tutorial, you’ll have implemented the framework for an extensible automated backup strategy that will allow you to quickly recover should your application suffer from data loss. For smaller to medium-sized databases, logical backups using `mongodump` give you fine-grained control over what data to back up and recover. Storage of these compressed backup archives in DigitalOcean Spaces ensures that they are readily available in a durable object store, so that your application data is protected and quickly recoverable should a data loss event occur.

**Note:** There may be some performance impact when using the `mongodump` tool, especially on highly loaded databases. You should test this procedure first using a non-production database with simulated load to verify that this method will work in your production deployment.

## Prerequisites

Before you get started with this guide, make sure you have the following prerequisites available to you:

- An Ubuntu 16.04 Droplet with a non-root user that has sudo privileges, as detailed in [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04)
- A running MongoDB 3.2+ installation, as detailed in [How to Install MongoDB on Ubuntu 16.04](how-to-install-mongodb-on-ubuntu-16-04)
- A DigitalOcean Space and set of API credentials, as detailed in [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key). 
- The `s3cmd` command-line file transfer client (2.X) installed as detailed in [**Step 1** of How To Use Logrotate and S3cmd to Archive Logs to Object Storage on Ubuntu 16.04](how-to-use-logrotate-and-s3cmd-to-archive-logs-to-object-storage-on-ubuntu-16-04#step-1-%E2%80%94-installing-s3cmd)
- `s3cmd` configured to access your Space, as detailed in [How To Configure s3cmd 2.x To Manage DigitalOcean Spaces](how-to-configure-s3cmd-2-x-to-manage-digitalocean-spaces)

Once you’ve logged in to your Droplet, have MongoDB up and running, and have created your Space, you’re ready to get started.

## Step 1 — Insert Test Data

If you’re starting from a clean MongoDB installation and haven’t stored any data yet, you should first insert some sample data into a dummy `restaurants` collection for test purposes. If you already have some collections and documents stored in your database, feel free to skip this step and continue on to [Step 2](how-to-set-up-scheduled-logical-mongodb-backups-to-digitalocean-spaces#step-2-%E2%80%94-use-mongodump-to-back-up-mongodb-data).

First, connect to the running database using the MongoDB shell:

    mongo

You’ll see the following Mongo shell prompt:

    MongoDB shell version: 3.2.19
    connecting to: test
    Welcome to the MongoDB shell.
    For interactive help, type "help".
    For more comprehensive documentation, see
        http://docs.mongodb.org/
    Questions? Try the support group
        http://groups.google.com/group/mongodb-user
    Server has startup warnings:
    2018-04-11T20:30:57.320+0000 I CONTROL [initandlisten]
    2018-04-11T20:30:57.320+0000 I CONTROL [initandlisten] ** WARNING: /sys/kernel/mm/transparent_hugepage/defrag is 'always'.
    2018-04-11T20:30:57.320+0000 I CONTROL [initandlisten] ** We suggest setting it to 'never'
    2018-04-11T20:30:57.320+0000 I CONTROL [initandlisten]
    >

By default, the shell connects to the `test` database.

Let’s list the collections present in the `test` database:

    show collections

Since we haven’t inserted anything into the database yet, there are no collections, and we’re brought back to the prompt with no output.

Let’s insert a document into a dummy `restaurants` collection, which will automatically be created (as it doesn’t yet exist):

    db.restaurants.insert({'name': 'Pizzeria Sammy'})

You’ll see the following output:

    OutputWriteResult({ "nInserted" : 1 })

This indicates that the insert operation was successful.

Let’s list collections once again:

    show collections

We now see our newly created `restaurants` collection:

    Outputrestaurants

To exit the MongoDB shell, press `CTRL` + `D`.

Now that we’ve stored some sample data in the database, we’re ready to back it up.

## Step 2 — Use `mongodump` to Back Up MongoDB Data

We’ll now use the built-in `mongodump` utility to back up (or “dump”) an entire MongoDB database to a compressed archive file.

First, let’s create a temporary directory called `backup` to store the archive created by `mongodump`:

    mkdir backup

Now, let’s back up the `test` database in this MongoDB instance to a compressed archive file called `test_dump.gz`. If your instance contains other databases, you can substitute another database name for `test` after the `--db` flag. You also may omit the `--db` flag to back up **all** databases in your MongoDB instance.

**Note:** The following command should be run from the terminal and **not** the Mongo shell.

    mongodump --db test --archive=./backup/test_dump.gz --gzip

Here, we use the `--archive` flag to specify that we’d like to save all the data to a single archive file (whose location is specified by the `archive` parameter) , and the `--gzip` flag to specify that we’d like to compress this file. In addition, you optionally may use the `--collection` or `--query` flags to select a given collection or query to archive. To learn more about these flags, consult the `mongodump` [documentation](https://docs.mongodb.com/manual/reference/program/mongodump/).

After running the dump command, you will see the following output:

    Output2018-04-13T16:29:32.191+0000 writing test.restaurants to archive './backup/test_dump.gz'
    2018-04-13T16:29:32.192+0000 done dumping test.restaurants (1 document)

This indicates that our test data has successfully been dumped.

In the next step, we’ll upload this backup archive to object storage.

## Step 3 — Upload the Backup Archive to DigitalOcean Spaces

To upload this archive to our DigitalOcean Space, we’ll need to use the `s3cmd` tool, which we installed and configured in the [Prerequisites](how-to-set-up-scheduled-mongodb-backups-to-digitalocean-spaces#prerequisites).

We’ll first test our `s3cmd` configuration and attempt to access our backups Space. In this tutorial, we’ll use `mongo-backup-demo` as our Space name, but you should fill in the actual name of your Space:

    s3cmd info s3://mongo-backup-demo/

You’ll see the following output:

    Outputs3://mongo-backup-demo/ (bucket):
       Location: nyc3
       Payer: BucketOwner
       Expiration Rule: none
       Policy: none
       CORS: none
       ACL: 3587522: FULL_CONTROL

Which indicates the connection was successful and `s3cmd` can transfer objects to the Space.

Let’s transfer the archive we created in Step 2 to our Space using the `put` command:

    s3cmd put ./backup/test_dump.gz s3://mongo-backup-demo/

You’ll see some file transfer output:

    Outputupload: './backup/test_dump.gz' -> 's3://mongo-backup-demo/test_dump.gz' [1 of 1]
     297 of 297 100% in 0s 25.28 kB/s done

Once the transfer completes, we’ll verify that the file was successfully transferred to our Space by listing the Space contents:

    s3cmd ls s3://mongo-backup-demo/

You should see the backup archive file:

    Output2018-04-13 20:39 297 s3://mongo-backup-demo/test_dump.gz

At this point you’ve successfully backed up the `test` MongoDB database and transferred the backup archive to your DigitalOcean Space.

In the next section we’ll cover how to script the above procedure using Bash so that we can schedule it using `cron`.

## Step 4 — Create and Test Backup Script

Now that we’ve backed up our MongoDB database to a compressed archive file and transferred this file to our Space, we can combine these manual steps into a single Bash script.

### Create Backup Script

We’ll first write a script combining the `mongodump` and `s3cmd put` commands, and add a few extra bells and whistles, like some logging (using `echo`s).

Open a blank file in your preferred text editor (here we’ll use `nano`):

    nano backup_mongo.sh

Paste in the following code snippets, being sure to update the relevant values to refer to your own Space, database, and file names. We’ll call the file `backup_mongo.sh`, but you may name this file however you’d like. You can also find the full script at the end of this section.

Let’s go through this script piece by piece:

backup\_mongo.sh

    #!/bin/bash
    
    set -e
    ...

Here, `#!/bin/bash` tells the shell to interpret the script as Bash code. `set -e` tells the interpreter to exit immediately if any of the script commands fail.

backup\_mongo.sh

    ...
    
    SPACE_NAME=mongo-backup-demo
    BACKUP_NAME=$(date +%y%m%d_%H%M%S).gz
    DB=test
    
    ...

In this section, we’re setting three variables that we’ll use later on:

- `SPACE_NAME`: The name of the DigitalOcean space to which we’re uploading our backup file
- `BACKUP_NAME`: The backup archive’s name. Here, we set it to a basic date-time string.
- `DB`: Specifies which MongoDB database the script will back up. If you’re backing up the entire MongoDB instance (all databases), this variable won’t be used.

backup\_mongo.sh

    ...
    
    date
    echo "Backing up MongoDB database to DigitalOcean Space: $SPACE_NAME"
    
    echo "Dumping MongoDB $DB database to compressed archive"
    mongodump --db $DB --archive=$HOME/backup/tmp_dump.gz --gzip
    
    echo "Copying compressed archive to DigitalOcean Space: $SPACE_NAME"
    s3cmd put $HOME/backup/tmp_dump.gz s3://$SPACE_NAME/$BACKUP_NAME
    
    ...

We then print the date and time (for logging purposes), and begin the backup by running the `mongodump` command we tested above. We once again save the backup archive to `~/backup/`.

We next use `s3cmd` to copy this archive to the location specified by those two `SPACE_NAME` and `BACKUP_NAME` variables. For example, if our Space name is `mongo-backup-demo` and the current date and time is `2018/04/12 12:42:21`, the backup will be named `180412_124221.gz` and it’ll be saved to the `mongo-backup-demo` Space.

backup\_mongo.sh

    ...
    
    echo "Cleaning up compressed archive"
    rm $HOME/backup/tmp_dump.gz
    
    echo 'Backup complete!'
    

Here we remove the backup archive from the `~/backup` directory as we’ve successfully copied it to our Space, with final output indicating that the backup is complete.

After combining all these code snippets, the full script should look like this:

backup\_mongo.sh

    #!/bin/bash
    
    set -e
    
    SPACE_NAME=mongo-backup-demo
    BACKUP_NAME=$(date +%y%m%d_%H%M%S).gz
    DB=test
    
    date
    echo "Backing up MongoDB database to DigitalOcean Space: $SPACE_NAME"
    
    echo "Dumping MongoDB $DB database to compressed archive"
    mongodump --db $DB --archive=$HOME/backup/tmp_dump.gz --gzip
    
    echo "Copying compressed archive to DigitalOcean Space: $SPACE_NAME"
    s3cmd put $HOME/backup/tmp_dump.gz s3://$SPACE_NAME/$BACKUP_NAME
    
    echo "Cleaning up compressed archive"
    rm $HOME/backup/tmp_dump.gz
    
    echo 'Backup complete!'

Be sure to save this file when you’re done.

Next, we’ll test this script to validate that all the subcommands work.

### Test Backup Script

Let’s quickly run the `backup_mongo.sh` script.

First, make the script executable:

    chmod +x backup_mongo.sh

Now, run the script:

    ./backup_mongo.sh

You will see the following output:

    OutputMon Apr 16 22:20:26 UTC 2018
    Backing up MongoDB database to DigitalOcean Space: mongo-backup-demo
    Dumping MongoDB test database to compressed archive
    2018-04-16T22:20:26.664+0000 writing test.restaurants to archive '/home/sammy/backup/tmp_dump.gz'
    2018-04-16T22:20:26.671+0000 done dumping test.restaurants (1 document)
    Copying compressed archive to DigitalOcean Space: mongo-backup-demo
    upload: '/home/sammy/backup/tmp_dump.gz' -> 's3://mongo-backup-demo/180416_222026.gz' [1 of 1]
     297 of 297 100% in 0s 3.47 kB/s done
    Cleaning up compressed archive
    Backup complete!

We’ve successfully created a backup shell script and can now move on to scheduling it using `cron`.

## Step 5 — Schedule Daily Backups Using Cron

To schedule a nightly run of the backup script, we’ll use `cron`, a job scheduling utility built-in to Unix-like operating systems.

First, we’ll create a directory to store the logs for our backup script. Next, we’ll add the backup script to the crontab (`cron`’s configuration file) so `cron` schedules it to run nightly. Because `cron` supports any regular frequency, you can optionally schedule weekly or monthly backups.

### Create Logging Directory

Let’s create a directory to store our backup script’s log files. These logs will allow us to periodically check up on the backup script to ensure that all is well, and debug should some command fail.

Create a `mongo_backup` subdirectory in `/var/log` (by convention used for logging):

    sudo mkdir /var/log/mongo_backup

Now, make that directory writeable to our Unix user. In this case, our user’s name is **sammy** , but you should use the relevant non-root username with sudo privileges for your server.

    sudo chown sammy:sammy /var/log/mongo_backup

Our Unix user **sammy** can now write to `/var/log/mongo_backup`. Since the cronjob will run as **sammy** , it can now write its log files to this directory.

Let’s create the scheduled cronjob.

### Create Cronjob

To create the cronjob, we’ll edit the file containing the list of scheduled jobs, called the “crontab.” Note that there are multiple crontabs, one per user, and a system-wide crontab at `/etc/crontab`. In this tutorial, we’ll run the backup script as our user **sammy** ; depending on your use case, you may elect to run it from the system-wide crontab.

Open up the crontab for editing:

    crontab -e

You’ll see the following menu allowing you to choose your preferred text editor:

    Outputno crontab for sammy - using an empty one
    
    Select an editor. To change later, run 'select-editor'.
      1. /bin/ed
      2. /bin/nano <---- easiest
      3. /usr/bin/vim.basic
      4. /usr/bin/vim.tiny
    
    Choose 1-4 [2]: no crontab for sammy - using an empty one

Select your preferred editor; to choose `nano` enter `2`. Now, append the following line to the file, following the commented-out section:

crontab -e

    # For more information see the manual pages of crontab(5) and cron(8)
    #
    # m h dom mon dow command
    
    0 2 * * * /home/sammy/mongo_backup.sh >>/var/log/mongo_backup/mongo_backup.log 2>&1
    

Be sure to include a trailing newline at the end of the crontab. Save and close the file.

You’ll see the following output:

    Outputno crontab for sammy - using an empty one
    crontab: installing new crontab

The backup script will now run at 2:00 AM every morning. Both `stdout` and `stderr` (the output and error streams) will be piped and appended to a log file called `mongo_backup.log` in the log directory we created earlier.

You may change `0 2 * * *` (execute nightly at 2:00 AM in cron syntax) to your desired backup frequency and time. To learn more about cron and its syntax, consult our tutorial on [How To Use Cron To Automate Tasks On A VPS](how-to-use-cron-to-automate-tasks-on-a-vps).

We’ll conclude this tutorial with a quick recovery exercise to ensure that our backups are functional.

## Step 6 — Perform a Test Recovery

Any backup strategy should contain a recovery procedure that is routinely tested. Here, we’ll quickly test a restore from the compressed backup file we uploaded to DigitalOcean spaces.

First, we’ll download `test_dump.gz` from our Space to the home directory in our MongoDB Droplet:

    s3cmd get s3://mongo-backup-demo/test_dump.gz

You will see the following output:

    Outputdownload: 's3://mongo-backup-demo/test_dump.gz' -> './test_dump.gz' [1 of 1]
     297 of 297 100% in 0s 1305.79 B/s done

If you began this tutorial with a fresh MongoDB instance, you’ll recall that it only contained the `test` database, which in turn was the only database we backed up.

For demonstration purposes, we’ll now drop this test database so that we can perform a clean restore. If we don’t perform this first step, the restore procedure will encounter the original documents, which it’ll skip. In your particular use case restoring only new documents may be acceptable, but for the purposes of this tutorial we’d like to explicitly test a full restore into an empty database.

Connect to your MongoDB instance using the `mongo` shell:

    mongo

Now, `use` the `test` database, and drop it from the MongoDB instance:

    use test
    db.dropDatabase()

You’ll see the following output confirming the `test` drop:

    Output{ "dropped" : "test", "ok" : 1 }

Now, exit the `mongo` shell and execute the `mongorestore` command:

    mongorestore --gzip --archive=test_dump.gz --db test

Here, we specify that the source backup file is compressed and in “archive file” form (recall that we used the `--archive` and `--gzip` flags when calling `mongodump`), and that we’d like to restore to the `test` database.

You will see the following output:

    Output2018-04-16T23:10:07.317+0000 creating intents for archive
    2018-04-16T23:10:07.453+0000 reading metadata for test.restaurants from archive 'test_dump.gz'
    2018-04-16T23:10:07.497+0000 restoring test.restaurants from archive 'test_dump.gz'
    2018-04-16T23:10:07.541+0000 restoring indexes for collection test.restaurants from metadata
    2018-04-16T23:10:07.541+0000 finished restoring test.restaurants (1 document)
    2018-04-16T23:10:07.541+0000 done

This indicates that the `test` restore succeeded.

To conclude, let’s confirm that our initial `restaurants` data has successfully been restored.

Open up the MongoDB shell and query the `restaurants` collection:

    db.restaurants.find()

You should see the object we saved in the first step of this tutorial:

    Output{ "_id" : ObjectId("5ace7614dbdf8137afe60025"), "name" : "Pizzeria Sammy" }

You’ve now successfully implemented and tested this MongoDB backup strategy.

## Conclusion

In this tutorial, we’ve learned how to implement and test a strategy for nightly logical MongoDB backups.

This guide can be extended or modified in many ways. Here are some quick suggestions:

- Depending on your recovery point objectives (RPOs), you may want to increase or decrease the suggested backup frequency to match your data recovery window.
- Another helpful addition would be an alert function, triggered if a backup script subcommand fails (e.g. this function could send an email to a regularly monitored alert inbox).
- This script does not handle Spaces object deletion. You may want to clean out backups older than, say, 6 months or so.
- You may want to implement a more complex [backup rotation scheme](https://en.wikipedia.org/wiki/Backup_rotation_scheme#Grandfather-father-son), depending on your production use case.

As the `mongodump` procedure involves quickly reading through all the dumped data, this backup method is most suitable for small- to medium-sized databases, particularly for partial backups such as a specific collection or result set. Filesystem-level backups are recommended for larger deployments. To learn more about filesystem-level MongoDB backups, consult this tutorial on [How To Back Up MongoDB Using Droplet Snapshots](how-to-back-up-mongodb-using-droplet-snapshots). To learn more about various methods of backing up a MongoDB database, you can consult the [MongoDB manual](https://docs.mongodb.com/v3.2/core/backups/).

The solution presented in this tutorial leverages `mongodump` for granular control over backup data coverage and DigitalOcean Spaces for cost-effective and durable long-term data storage. To learn more about the `mongodump` backup utility, consult its [reference page](https://docs.mongodb.com/manual/reference/program/mongodump/) in the MongoDB manual. To learn more about DigitalOcean Spaces, you can read [An Introduction To DigitalOcean Spaces](an-introduction-to-digitalocean-spaces).
