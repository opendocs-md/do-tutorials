---
author: finid
date: 2015-09-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-and-restore-your-redis-data-on-ubuntu-14-04
---

# How To Back Up and Restore Your Redis Data on Ubuntu 14.04

## Introduction

Redis is an in-memory, key-value cache and store (a database, that is) that can also be persisted (saved permanently) to disk. In this article, you’ll read how to back up a Redis database on an Ubuntu 14.04 server.

Redis data, by default, are saved to disk in a `.rdb` file, which is a point-in-time snapshot of your Redis dataset. The snapshot is made at specified intervals, and so is perfect for your backups.

## Prerequisites

To complete the steps in this tutorial, you’ll need:

- An Ubuntu 14.04 server
- Install Redis. You can follow just the **master** setup from [this Redis setup tutorial](how-to-configure-a-redis-cluster-on-ubuntu-14-04) (although it will work just as well with a master-slave cluster)
- Make sure that your Redis server is running
- If a Redis password was set, which is highly recommended, have it handy. The password is in the Redis configuration file - `/etc/redis/redis.conf`

## Step 1 — Locating the Redis Data Directory

Redis stores its data in a directory on your server, which is what we want to back up. First we need to know where it is.

In Ubuntu and other Linux distributions, the Redis database directory is `/var/lib/redis`. But if you’re managing a server that you inherited and the Redis data location was changed, you can locate it by typing:

    sudo locate *rdb

Alternatively, you may also find it from the `redis-cli` prompt. To do that, type:

    redis-cli

If the Redis server is not running, the response will be:

Output

    Could not connect to Redis at 127.0.0.1:6379: Connection refused
    not connected>

In that case, start Redis and reconnect using the following commands:

    sudo service redis-server start
    
    redis-cli

The shell prompt should now change to:

    127.0.0.1:6379>

While connected to Redis, the next two commands will authenticate to it and get the data directory:

    auth insert-redis-password-here
    
    config get dir

The output of the last command should be your Redis data directory:

Output

    1) "dir"
    2) "/var/lib/redis"

Make note of your Redis directory. If it’s different than the directory shown, make sure you use this directory throughout the tutorial.

You can exit the database command line interface now:

    exit

Check that this is the correct directory:

    ls /var/lib/redis

You should see a `dump.rdb` file. That’s the Redis data. If `appendonly` is also enabled, you will also see an `appendonly.aof` or another `.aof` file, which contains a log of all write operations received by the server.

See [this post about Redis persistence](http://redis.io/topics/persistence) for a discussion of the differences between these two files. Basically, the `.rdb` file is a current snapshot, and the `.aof` file preserves your Redis history. Both are worth backing up.

We’ll start with just the `.rdb` file, and end with an automated backup of both files.

## (Optional) Step 2 — Adding Sample Data

In this section you can create some sample data to store in your Redis database. If you already have data on your server, you can just back up your existing content.

Log in to the database command line interface:

    redis-cli

Authenticate:

    auth insert-redis-password-here

Let’s add some sample data. You should get a response of `OK` after each step.

    SET shapes:triangles "3 sides"
    
    SET shapes:squares "4 sides"

Confirm that the data was added.

    GET shapes:triangles
    
    GET shapes:squares

The output is included below:

Output

    "3 sides"
    
    "4 sides"

To commit these changes to the `/var/lib/redis/dump.rdb` file, save them:

    save

You can exit:

    exit

If you’d like, you can check the contents of the dump file now. It should have your data, albeit in a machine-friendly form:

    sudo cat /var/lib/redis/dump.rdb

/var/lib/redis/dump.rdb

    REDIS0006?shapes:squares4 sidesshapes:triangles3 sides??o????C

## Step 3 — Backing Up the Redis Data

Now that you know where your Redis data are located, it’s time to make the backup. From the official [Redis website](http://redis.io/topics/persistence) comes this quote:

> Redis is very data backup friendly since you can copy RDB files while the database is running: the RDB is never modified once produced, and while it gets produced it uses a temporary name and is renamed into its final destination atomically using rename(2) only when the new snapshot is complete.

So, you can back up or copy the database file while the Redis server is running. Assuming that you’re backing it up to a directory under your home folder, performing that backup is as simple as typing:

    sudo cp /var/lib/redis/dump.rdb /home/sammy/redis-backup-001

**Redis saves content here _periodically_, meaning that you aren’t guaranteed an up-to-the-minute backup if the above command is all you run.** You need to save your data first.

However, if a potentially small amount of data loss is acceptable, just backing up this one file will work.

**Saving the Database State**

To get a much more recent copy of the Redis data, a better route is to access `redis-cli`, the Redis command line.

Authenticate as explained in Step 1.

Then, issue the `save` command like so:

    save

The output should be similar to this:

Output

    OK
    (1.08s)

Exit the database.

Now you may run the `cp` command given above, confident that your backup is fully up to date.

While the `cp` command will provide a one-time backup of the database, the best solution is to set up a cron job that will automate the process, and to use a tool that can perform incremental updates and, if needed, restore the data.

## Step 4 — Configuring Automatic Updates with rdiff-backup and Cron

In this section, we’ll configure an automatic backup that backs up your entire Redis data directory, including both data files.

There are several automated backup tools available. In this tutorial, we’ll use a newer, user-friendly tool called `rdiff-backup`.

`rdiff-backup` a command line backup tool. It’s likely that `rdiff-backup` is not installed on your server, so you’ll first have to install it:

    sudo apt-get install -y rdiff-backup

Now that it’s installed, you can test it by backing up your Redis data to a folder in your home directory. In this example, we assume that your home directory is `/home/sammy`:

Note that the target directory will be created by the script if it does not exist. In other words, you don’t have to create it yourself.

With the **–preserve-numerical-ids** , the ownerships of the source and destination folders will be the same.

    sudo rdiff-backup --preserve-numerical-ids /var/lib/redis /home/sammy/redis

Like the `cp` command earlier, this is a one-time backup. What’s changed is that we’re backing up the entire `/var/lib/redis` directory now, and using `rdiff-backup`.

Now we’ll automate the backup using cron, so that the backup takes place at a set time. To accomplish that, open the system crontab:

    sudo crontab -e

(If you haven’t used crontab before on this server, select your favorite text editor at the prompt.)

At the bottom of the filek append the entry shown below.

crontab

    0 0 * * * rdiff-backup --preserve-numerical-ids --no-file-statistics /var/lib/redis /home/sammy/redis

This Cron entry will perform a Redis backup every day at midnight. The **–no-file-statistics** switch will disable writing to the `file_statistics` file in the `rdiff-backup-data` directory, which will make `rdiff-backup` run more quickly and use up a bit less disk space.

Alternately, you can use this entry to make a daily backup:

    @daily rdiff-backup --preserve-numerical-ids --no-file-statistics /var/lib/redis /home/sammy/redis

For more about Cron in general, read this [article about Cron](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps).

As it stands, the backup will be made once a day, so you can come back tomorrow for the final test. Or, you can temporarily increase the backup frequency to make sure it’s working.

Because the files are owned by the **redis** system user, you can verify that they are in place using this command. (Make sure you wait until the backup has actually triggered):

    ls -l /home/sammy/redis

Your output should look similar to this:

Output

    total 20
    -rw-rw---- 1 redis redis 70 Sep 14 13:13 dump.rdb
    drwx------ 3 root root 12288 Sep 14 13:49 rdiff-backup-data
    -rw-r----- 1 redis redis 119 Sep 14 13:09 redis-staging-ao.aof

You’ll now have daily backups of your Redis data, stored in your home directory on the same server.

## Step 5 — Restoring Redis Database from Backup

Now that you’ve seen how to back up a Redis database, this step will show you how to restore your database from a `dump.rdb` backup file.

Restoring a backup requires you to replace the active Redis database file with the restoration file. **Since this is potentially destructive, we recommend restoring to a fresh Redis server if possible.**

You wouldn’t want to overwrite your live database with a more problematic restoration. However, renaming rather than deleting the current file minimizes risk even if restoring to the same server, which is the tactic this tutorial shows.

### Checking Restoration File Contents

First, check the contents of your `dump.rdb` file. Make sure it has the data you want.

You can check the contents of the dump file directly, although keep in mind it uses Redis-friendly rather than human-friendly formatting:

    sudo cat /home/gilly/redis/dump.rdb

This is for a small database; your output should look somewhat like this:

Output

    REDIS0006?shapes:triangles3 sidesshapes:squares4 sides??!^?\?,?

If your most recent backup doesn’t have the data, you should not continue with the restoration. If the content is there, keep going.

### Optional: Simulating Data Loss

Let’s simulate data loss, which would be a reason to restore from your backup.

Log in to Redis:

    redis-cli

In this sequence of commands we’ll authorize with Redis and delete the `shapes:triangles` entry:

    auth insert-redis-password-here
    
    DEL shapes:triangles

Now let’s make sure the entry was removed:

    GET shapes:triangles

The output should be:

Output

    (nil)

Save and exit:

    save
    
    exit

### Optional: Setting Up New Redis Server

Now, if you plan to restore to a new Redis server, make sure that new Redis server is up and running.

For the purposes of this tutorial we’ll follow just **Step 1** of this [Redis Cluster tutorial](how-to-configure-a-redis-cluster-on-ubuntu-14-04), although you can follow the whole article if you want a more sophisticated setup.

If you follow **Step 2** , where you add a password and enable AOF, make sure you account for that in the restoration process.

Once you’ve verified that Redis is up on the new server by running `redis-benchmark -q -n 1000 -c 10 -P 5`, you can proceed.

### Stopping Redis

Before we can replace the Redis dump file, we need to stop the currently running instance of Redis. **Your database will be offline once you stop Redis.**

    sudo service redis-server stop

The output should be:

Output

    Stopping redis-server: redis-server

Check that it’s actually stopped:

    sudo service redis-server status

Output

    redis-server is not running

Next we’ll rename the current database file.

### Renaming Current dump.rdb

Redis reads its contents from the `dump.rdb` file. Let’s rename the current one, to make way for our restoration file.

    sudo mv /var/lib/redis/dump.rdb /var/lib/redis/dump.rdb.old

Note that you can restore `dump.rdb.old` if you decide the current version was better than your backup file.

### If AOF Is Enabled, Turn It Off

AOF tracks every write operation to the Redis database. Since we’re trying to restore from a point-in-time backup, though, we don’t want Redis to recreate the operations stored in its AOF file.

If you set up your Redis server from the instructions in the [Redis Cluster tutorial](how-to-configure-a-redis-cluster-on-ubuntu-14-04), then AOF is enabled.

You can also list the contents of the `/var/lib/redis/` directory. If you see a `.aof` file there, you have AOF enabled.

Let’s rename the `.aof` file to get it out of the way temporarily. This renames every file that ends with `.aof`, so if you have more than one AOF file you should rename the files individually, and NOT run this command:

    sudo mv /var/lib/redis/*.aof /var/lib/redis/appendonly.aof.old

Edit your Redis configuration file to temporarily turn off AOF:

    sudo nano /etc/redis/redis.conf

In the `AOF` section, look for the `appendonly` directive and change it from `yes` to `no`. That disables it:

/etc/redis/redis.conf

    appendonly no

### Restoring the dump.rdb File

Now we’ll use our restoration file, which should be saved at `/home/sammy/redis/dump.rdb` if you followed the previous steps in this tutorial.

If you are restoring to a new server, now’s the time to upload the file from your backup server to the new server:

    scp /home/sammy/redis/dump.rdb sammy@your_new_redis_server_ip:/home/sammy/dump.rdb

Now, **on the restoration server** , which can be the original Redis server or a new one, you can use `cp` to copy the file to the `/var/lib/redis` folder:

    sudo cp -p /home/sammy/redis/dump.rdb /var/lib/redis

(If you uploaded the file to `/home/sammy/dump.rdb`, use the command `sudo cp -p /home/sammy/dump.rdb /var/lib/redis` instead to copy the file.)

Alternately, if you want to use `rdiff-backup`, run the command shown below. Note this will only work if you are restoring from the folder you set up with `rdiff-backup` originally. With `rdiff-backup`, you have to specify the name of the file in the destination folder:

    sudo rdiff-backup -r now /home/sammy/redis/dump.rdb /var/lib/redis/dump.rdb

Details about the `-r` option are available on the project’s website given at the end of this article.

### Setting Permissions for the dump.rdb File

You probably have the correct permissions already if you’re restoring to the same server where you made the backup.

If you copied the backup file to a new server, you’ll likely have to update the file permissions.

Let’s view the permissions of the `dump.rdb` file in the `/var/lib/redis/` directory.

    ls -la /var/lib/redis/

If you see something like this:

Output

    -rw-r----- 1 sammy sammy 70 Feb 25 15:38 dump.rdb
    -rw-rw---- 1 redis redis 4137 Feb 25 15:36 dump.rdb.old

You’ll want to update the permissions so the file is owned by the **redis** user and group:

    sudo chown redis:redis /var/lib/redis/dump.rdb

Update the file to be writeable by the group as well:

    sudo chmod 660 /var/lib/redis/dump.rdb

Now list the contents of the `/var/lib/redis/` directory again:

    ls -la /var/lib/redis/

Now your restored `dump.rdb` file has the correct permissions:

Output

    -rw-rw---- 1 redis redis 70 Feb 25 15:38 dump.rdb
    -rw-rw---- 1 redis redis 4137 Feb 25 15:36 dump.rdb.old

If your Redis server daemon was running before you restored the file, and now won’t start — it will show a message like `Could not connect to Redis at 127.0.0.1:6379: Connection refused` — check Redis’s logs.

- [How To Find Redis Logs on Ubuntu](how-to-find-redis-logs-on-ubuntu)

If you see a line in the logs like `Fatal error loading the DB: Permission denied. Exiting.`, then you need to check the permissions of the `dump.rdb` file, as explained in this step.

### Starting Redis

Now we need to start the Redis server again.

    sudo service redis-server start

### Checking Database Contents

Let’s see if the restoration worked.

Log in to Redis:

    redis-cli

Check the `shapes:triangles` entry:

    GET shapes:triangles

The output should be:

Output

    "3 sides"

Great! Our restoration worked.

Exit:

    exit

If you’re not using AOF, you’re done! Your restored Redis instance should be back to normal.

### (Optional) Enabling AOF

If you want to resume or start using AOF to track all the writes to your database, follow these instructions. The AOF file has to be recreated from the Redis command line.

Log in to Redis:

    redis-cli

Turn on AOF:

    BGREWRITEAOF

You should get the output:

Output

    Background append only file rewriting started

Run the `info` command. This will generate quite a bit of output:

    info

Scroll to the **Persistence** section, and check that the **aof** entries match what’s shown here. If **aof\_rewrite\_in\_progress** is **0** , then the recreation of the AOF file has completed.

Output

    # Persistence
    
    . . .
    
    aof_enabled:0
    aof_rewrite_in_progress:0
    aof_rewrite_scheduled:0
    aof_last_rewrite_time_sec:0
    aof_current_rewrite_time_sec:-1
    aof_last_bgrewrite_status:ok
    aof_last_write_status:ok

If it’s confirmed that recreation of the AOF file has completed, you may now exit the Redis command line:

    exit

You can list the files in `/var/lib/redis` again:

    ls /var/lib/redis

You should see a live `.aof` file again, such as `appendonly.aof` or `redis-staging-ao.aof`, along with the `dump.rdb` file and other backup files.

Once that’s confirmed, stop the Redis server:

    sudo service redis-server stop

Now, turn on AOF again in the `redis.conf` file:

    sudo nano /etc/redis/redis.conf

Then re-enable AOF by changing the value of `appendonly` to `yes`:

/etc/redis/redis.conf

    appendonly yes

Start Redis:

    sudo service redis-server start

If you’d like to verify the contents of the database one more time, just run through the **Checking Database Contents** section once more.

That’s it! Your restored Redis instance should be back to normal.

## Conclusion

Backing up your Redis data in the manner given in this article is good for when you don’t mind backing up the data to a directory on the same server.

The most secure approach is, of course, to back up to a different machine. You can explore more backup options by reading this article about backups:

- [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps)

You can use many of these backup methods with the same files in the `/var/lib/redis` directory.

Keep an eye out for our future article about Redis migrations and restorations. You may also want to reference the `rdiff-backup` documentation’s examples for how to use `rdiff-backup` effectively:

- [rdiff-backup Examples](http://www.nongnu.org/rdiff-backup/examples.html)
