---
author: Florin Dobre
date: 2015-07-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-a-redis-cluster-on-centos-7
---

# How To Configure a Redis Cluster on CentOS 7

## Introduction

Redis is an open source key-value data store, using an in-memory storage model with optional disk writes for persistence. It features transactions, pub/sub, and automatic failover, among other functionality. It is recommended to use Redis with Linux for production environments, but the developers also mention OS X as a platform on which they develop and test. Redis has clients written in most languages, with recommended ones featured on [their website](http://redis.io/clients).

For production environments, replicating your data across at least two nodes is considered the best practice. Redundancy allows for recovery in case of environment failure, which is especially important when the user base of your application grows.

By the end of this guide, we will have set up two Redis Droplets on DigitalOcean, as follows:

- one Droplet for the Redis master server
- one Droplet for the Redis slave server

We will also demonstrate how to switch to the slave server and set it up as a temporary master.

Feel free to set up more than one slave server.

This article focuses on setting up a master-slave Redis cluster; to learn more about Redis in general and its basic usage as a database, see [this usage tutorial](how-to-install-and-use-redis).

## Prerequisites

While this may work on earlier releases and other Linux distributions, we recommend using CentOS 7.

For testing purposes, we will use small instances as there is no real workload to be handled, but production environments may require larger servers.

- CentOS 7
- Two Droplets, of any size you need; one **master** and one or more **slave(s)**
- Access to your machines via SSH with a sudo non-root user as explained in [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7)

## Step 1 — Install Redis

Starting with the Droplet that will host our **master server** , our first step is to install Redis. First we need to enable the EPEL repository on our machine. If you are unfamiliar with it, EPEL is the Extra Packages for Enterprise Linux repo, developed by the Fedora project with the intention of providing quality third-party packages for enterprise users of RHEL-based distros.

    wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

If `wget` is not recognized, try running `yum install wget` before the above command.

Now run:

    sudo rpm -ivh epel-release-7-5.noarch.rpm

And now type in:

    sudo yum -y update

Note that this may take a while to complete. Now you may install Redis on your machine, by running:

    sudo yum install redis -y

Once the installation process has finished, starting the Redis service is done by entering the following command:

    sudo systemctl start redis.service

And checking its status can be done with the following command:

    sudo systemctl status redis.service

Which outputs something similar to:

    Outputredis.service - Redis persistent key-value database
       Loaded: loaded (/usr/lib/systemd/system/redis.service; disabled)
      Drop-In: /etc/systemd/system/redis.service.d
               └─limit.conf
       Active: active (running) since Wed 2015-07-22 02:26:31 EDT; 13s ago
     Main PID: 18995 (redis-server)
       CGroup: /system.slice/redis.service
               └─18995 /usr/bin/redis-server 127.0.0.1:6379

Finally, let’s test our Redis setup by running:

    redis-cli ping

This should print a `PONG` as the response. If this is the case, you now have Redis running on your server, and we can start configuring it. An additional test for our setup can be done by running:

    redis-benchmark -q -n 1000 -c 10 -P 5

The above command is saying that we want `redis-benchmark` to run in quiet mode, with 1000 total requests, 10 parallel connections and pipeline 5 requests. For more information on running benchmarks for Redis, typing `redis-benchmark --help` in your terminal will print useful information with examples.

Let the benchmark run. After it’s finished, you should see output similar to the following:

    OutputPING_INLINE: 166666.67 requests per second
    PING_BULK: 249999.98 requests per second
    SET: 200000.00 requests per second
    GET: 200000.00 requests per second
    INCR: 200000.00 requests per second
    LPUSH: 200000.00 requests per second
    LPOP: 200000.00 requests per second
    SADD: 200000.00 requests per second
    SPOP: 249999.98 requests per second
    LPUSH (needed to benchmark LRANGE): 200000.00 requests per second
    LRANGE_100 (first 100 elements): 35714.29 requests per second
    LRANGE_300 (first 300 elements): 11111.11 requests per second
    LRANGE_500 (first 450 elements): 7194.24 requests per second
    LRANGE_600 (first 600 elements): 5050.50 requests per second
    MSET (10 keys): 100000.00 requests per second

Now repeat this section for the Redis **slave server**. If you are configuring more Droplets, you may set up as many slave servers as necessary.

At this point, Redis is installed and running on our two nodes. If the output of any node is not similar to what is shown above, repeat the setup process carefully and check that all prerequisites are met.

## Step 2 — Configure Redis Master

Now that Redis is up and running on our two-Droplet cluster, we have to edit their configuration files. As we will see, there are minor differences between configuring the master server and the slave.

Let’s first start with our **master**.

Open `/etc/redis.conf` with your favorite text editor:

    sudo vi /etc/redis.conf

Edit the following lines.

Set a sensible value to the keepalive timer for TCP:

/etc/redis.conf

    tcp-keepalive 60

Make the server accessible to anyone on the web by commenting out this line:

/etc/redis.conf

    #bind 127.0.0.1

Given the nature of Redis, and its very high speeds, an attacker may brute force the password without many issues. That is why we recommend uncommenting the `requirepass` line and adding a complex password (or a complex passphrase, preferably):

/etc/redis.conf

    requirepass your_redis_master_password

Depending on your usage scenario, you may change the following line or not. For the purpose of this tutorial, we assume that no key deletion must occur. Uncomment this line and set it as follows:

/etc/redis.conf

    maxmemory-policy noeviction

Finally, we want to make the following changes, required for backing up data. Uncomment and/or set these lines as shown:

/etc/redis.conf

    appendonly yes
    appendfilename "appendonly.aof"

Save your changes.

Restart the Redis service to reload our configuration changes:

    sudo systemctl restart redis.service

Now that we have the master server ready, let’s move on to our slave machine.

## Step 3 — Configure Redis Slave

We need to make some changes that allow our **slave server** to connect to our master instance:

Open `/etc/redis.conf` with your favorite text editor:

    sudo vi /etc/redis.conf

Edit the following lines; some settings will be similar to the master’s.

Make the server accessible to anyone on the web by commenting out this line:

/etc/redis.conf

    #bind 127.0.0.1

The slave server needs a password as well so we can give it commands (such as `INFO`). Uncomment this line and set a server password:

/etc/redis.conf

    requirepass your_redis_slave_password

Uncomment this line and indicate the IP address where the **master server** can be reached, followed by the port set on that machine. By default, the port is 6379:

/etc/redis.conf

    slaveof your_redis_master_ip 6379

Uncomment the `masterauth` line and provide the password/passphrase you set up earlier on the **master server** :

/etc/redis.conf

    masterauth your_redis_master_password

Now save these changes, and exit the file. Next, restart the service like we did on our master server:

    sudo systemctl restart redis.service

This will reinitialize Redis and load our modified files.

Connect to Redis:

    redis-cli -h 127.0.0.1 -p 6379 

Authorize with the **slave server’s password** :

    AUTH your_redis_slave_password

At this point we are running a functional master-slave Redis cluster, with both machines properly configured.

## Step 4 — Verify the Master-Slave Replication

Testing our setup will allow us to better understand the behavior of our Redis Droplets, once we want to start scripting failover behavior. What we want to do now is make sure that our configuration is working correctly, and our master is talking with the slave Redis instances.

First, we connect to Redis via our terminal, on the **master server** :

First connect to the local instance, running by default on port 6379. In case you’ve changed the port, modify the command accordingly.

    redis-cli -h 127.0.0.1 -p 6379

Now authenticate with Redis with the password you set when configuring the master:

    AUTH your_redis_master_password

And you should get an `OK` as a response. Now, you only have to run:

    INFO

You will see everything you need to know about the master Redis server. We are especially interested in the `#Replication` section, which should look like the following output:

    Output. . .
    
    # Replication
    role:master
    connected_slaves:1
    slave0:ip=111.111.111.222,port=6379,state=online,offset=407,lag=1
    master_repl_offset:407
    repl_backlog_active:1
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:2
    repl_backlog_histlen:406
    
    . . .

Notice the `connected_slaves:1` line, which indicates our other instance is talking with the master Droplet. You can also see that we get the slave IP address, along with port, state, and other info.

Let’s now take a look at the `#Replication` section on our slave machine. The process is the same as for our master server. Log in to the Redis instance, issue the `INFO` command, and view the output:

    Output. . .
    
    # Replication
    role:slave
    master_host:111.111.111.111
    master_port:6379
    master_link_status:up
    master_last_io_seconds_ago:3
    master_sync_in_progress:0
    slave_repl_offset:1401
    slave_priority:100
    slave_read_only:1
    connected_slaves:0
    master_repl_offset:0
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0
    
    . . .

We can see that this machine has the role of slave, is communicating with the master Redis server, and has no slaves of its own.

## Step 5 — Switch to the Slave

Building this architecture means that we also want failures to be handled in such a way that we ensure data integrity and as little downtime as possible for our application. Any slave can be promoted to be a master. First, let’s test switching manually.

On a **slave machine** , we should connect to the Redis instance:

    redis-cli -h 127.0.0.1 -p 6379

Now authenticate with Redis with the password you set when configuring the slave

    AUTH your_redis_slave_password

Turn off slave behavior:

    SLAVEOF NO ONE

The response should be `OK`. Now type:

    INFO

Look for the `# Replication` section to find the following output:

    Output. . .
    
    # Replication
    role:master
    connected_slaves:0
    master_repl_offset:1737
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0
    
    . . .

As we expected, the slave has turned into a master, and is now ready to accept connections from other machines (if any). We can use it as a temporary backup while we debug our main master server.

If you have multiple slaves that depended on the initial master, they all have to be pointed towards the newly promoted master.

This can be scripted easily, with the following steps needing to be implemented once a failure is detected:

- From the application, send all requests for Redis to a slave machine
- On that slave, execute the `SLAVEOF NO ONE` command. Starting with Redis version 1.0.0, this command tells the slave to stop replicating data, and start acting as a master server
- On all remaining slaves (if any), running `SLAVEOF hostname port` will instruct them to stop replicating from the old master, discard the now deprecated data completely, and start replicating from the new master. Make sure to replace `hostname` and `port` with the correct values, from your newly promoted master
- After analyzing the issue, you may return to having your initial server as master, if your particular setup requires it

There are many ways of accomplishing the steps explained above. However, it is up to you to implement an adequate solution for your environment, and make sure to test it thoroughly before any actual failures occur.

## Step 6 — Reconnect to the Master

Let’s reconnect to the original master server. On the **slave server** , log in to Redis and execute the following:

    SLAVEOF your_redis_master_ip 6379

If you run the `INFO` command again, you should see we have returned to the original setup.

## Conclusion

We have properly set up an enviroment consisting of two servers, one acting as Redis master, and the other replicating data as a slave. This way, if the master server ever goes offline or loses our data, we know how to switch to one of our slaves for recovery until the issue is taken care of.

Next steps might include scripting the automated failover procedure, or ensuring secure communications between all your Droplets by the use of VPN solutions such as [OpenVPN](how-to-setup-and-configure-an-openvpn-server-on-centos-7). Also, testing procedures and scripts are vital for validating your configurations.

Additionally, you should take precautions when deploying this kind of setup in production environments. The [Redis Documentation](http://redis.io/documentation) page should be studied and you must have a clear understanding of what security model is adequate for your application. We often use Redis as a session store, and the information it contains can be valuable to an attacker. Common practice is to have these machines accessible only via private network, and place them behind multiple layers of security.

This is a simple starting point on which your data store may be built; by no means an exhaustive guide on setting up Redis to use master-slave architecture. If there is anything that you consider this guide should cover, please leave comments below. For more information and help on this topic, the [DigitalOcean Q&A](https://www.digitalocean.com/community/questions) is a good place to start.
