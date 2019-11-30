---
author: finid
date: 2016-05-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-migrate-redis-data-with-master-slave-replication-on-ubuntu-14-04
---

# How to Migrate Redis Data with Master-Slave Replication on Ubuntu 14.04

## Introduction

Redis is an in-memory, NoSQL, key-value cache and store that can also be persisted to disk. It’s been growing in popularity and it’s being used as a datastore in both big and small projects. For any number of reasons, like transitioning to a more powerful server, sometimes it becomes necessary to migrate that data from one server to another.

Though it’s possible to just copy the database files from the current server to the new one, the recommended method of migrating a Redis database is to use a replication setup in a master-slave fashion. Such a setup is much faster than copying files and involves very little or no downtime.

This article will show how to migrate Redis data from an Ubuntu 14.04 server to a similar server using master-slave replication. This involves setting up a new Redis server, configuring it to be the slave of the current server (i.e. the master), then promoting the slave to master after the migration is completed.

## Prerequisites

To follow this article, you will need one Redis master server with the data you want to export or migrate, and a second new Redis server which will be the slave.

Specifically, these are the prerequisites for the Redis master.

- One Ubuntu 14.04 server with:

And these are the prerequisites for the Redis slave.

- A second Ubuntu 14.04 server with:

Make sure to following the nameserver configuration section in the IPTables tutorial on both servers; without it, `apt` won’t work.

## Step 1 — Updating the Redis Master Firewall

After installing and configuring the Redis slave, what you have are two independent servers that are not communicating because of the firewall rules. In this step, we’ll fix that

The fix involves adding an exception to the TCP rules on the master to allow Redis traffic on port 6379. So, on the master, open the IPTables configuration file for IPv4 rules.

    sudo nano /etc/iptables/rules.v4

Right below the rule that allows SSH traffic, add a rule for Redis that allows traffic on the Redis port _only_ from the slave’s IP address. Make sure to update `your_slave_ip_address` to the IP address of the slave server.

/etc/iptables/rules.v4

    . . .
    # Acceptable TCP traffic
    -A TCP -p tcp --dport 22 -j ACCEPT
    -A TCP -p tcp -s your_slave_ip_address --dport 6379 -j ACCEPT
    . . .

This is being very restrictive and more secure. Otherwise, the server would accept traffic from any host on the Redis port.

Restart IPTables to apply the new rule.

    sudo service iptables-persistent restart

Now that the replication system is up and the firewall on the master has been configured to allow Redis traffic, we can verify that both servers can communicate. That can be done with the instructions given in Step 4 of [this Redis cluster tutorial](how-to-configure-a-redis-cluster-on-ubuntu-14-04).

## Step 2 — Verifying the Data Import

If both servers have established contact, data import from the server to the slave should start automatically. You now only have to verify that it has, and has completed successfully. There are multiple ways of verifying that.

### The Redis Data Directory

One way to verify a successful data import is to look in the Redis data directory. The same files that are on the master should now be on the slave. If you do a long listing of the files in the Redis data directory of the slave server using this command:

    ls -lh /var/lib/redis

You should get an output of this sort:

Output

    
    total 32M
    -rw-r----- 1 redis redis 19M Oct 6 22:53 appendonly.aof
    -rw-rw---- 1 redis redis 13M Oct 6 22:53 dump.rdb

### The Redis Command Line

Another method of verifying data import is from the Redis command line. Enter the command line on the slave server.

    redis-cli

Then authenticate and issue the `info` command

    auth insert-redis-password-here
    
    info

In the output, the number of keys in the **# Keyspace** should be the same on both servers. The output below was taken from the slave server, which was exactly the same as the output on the master server.

Output

    # Keyspace
    db0:keys=26378,expires=0,avg_ttl=0

### Scan the Keys

Yet another method of verifying that the slave now has the same data that’s on the master is to use the `scan` command from the Redis command line. Though the output from that command will not always be the same across both server’s, when issued on the slave, it will at least let you confirm that the slave has the data that you expect to find on it.

An example output from the test server used for this article is shown below. Note that the argument to the `scan` command is just any number and acts as a cursor:

    scan 0

The output should be similar to this:

Output

    1) "17408"
    2) 1) "uid:5358:ip"
        2) "nodebbpostsearch:object:422"
        3) "uid:4163:ip"
        4) "user:15682"
        5) "user:1635"
        6) "nodebbpostsearch:word:HRT"
        7) "uid:6970:ip"
        8) "user:15641"
        9) "tid:10:posts"
       10) "nodebbpostsearch:word:AKL"
       11) "user:4648"
    127.0.0.1:6379>

## Step 3 — Promoting the Slave to Master

Once you’ve confirmed that the slave has all the data, you can promote it to master. This is also covered in [Step 5 of the Redis cluster tutorial](how-to-configure-a-redis-cluster-on-ubuntu-14-04#step-5-%E2%80%94-switch-to-the-slave), but for simplicity, the instructions are here, too.

First, enter the Redis command line on the slave.

    redis-cli

After authenticating, issue the `slaveof no one` command to promote it to master.

    auth your_redis_password
    slaveof no one

You should get this output:

Output

    OK

Then use the `info` command to verify.

    info

The relevant output in the **Replication** section should look like this. In particular, **role:master** line shows that the slave is now the master.

Output

    # Replication
    role:master
    connected_slaves:0
    master_repl_offset:11705
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0

Afterwards, a single entry in the former master’s log file should also confirm that.

/var/log/redis/redis-server.log

    
    14613:M 07 Oct 14:03:44.159 # Connection with slave 192.168.1.8:6379 lost.

And on the new master (formerly the slave), you should see:

/var/log/redis/redis-server.log

    14573:M 07 Oct 14:03:44.150 # Connection with master lost.
    14573:M 07 Oct 14:03:44.150 * Caching the disconnected master state.
    14573:M 07 Oct 14:03:44.151 * Discarding previously cached master state.
    14573:M 07 Oct 14:03:44.151 * MASTER MODE enabled (user request from 'id=4 addr=127.0.0.1:52055 fd=6 name= age=2225 idle=0 flags=N db=0 sub=0 psub=0 multi=-1 qbuf=0 qbuf-free=32768 obl=0 oll=0 omem=0 events=r cmd=slaveof')

At this point, you may now connect the applications to the database, and you may delete or destroy the original master.

## Conclusion

When done correctly, migrating Redis data in this fashion is a straightforward task. The main source of error is typically forgetting to modify the firewall of the master server to allow Redis traffic.

You can learn how to do more with Redis by browsing [more Redis tutorials](https://www.digitalocean.com/community/tags/redis?type=tutorials).
