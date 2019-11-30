---
author: Justin Ellingwood
date: 2016-11-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-redis-replication-on-ubuntu-16-04
---

# How To Configure Redis Replication on Ubuntu 16.04

## Introduction

Redis is an open-source key-value data store, using an in-memory storage model with optional disk writes for persistence. It features transactions, a pub/sub messaging pattern, and automatic failover among other functionality. Redis has clients written in most languages with recommended ones featured on [their website](http://redis.io/clients).

For production environments, replicating your data across at least two nodes is considered the best practice. This allows for recovery in case of environment failure, which is especially important when the user base of your application grows. It also allows you to safely interact with production data without modifying it or affecting performance.

In this guide, we will configure replication between two servers, both running Ubuntu 16.04. This process can be easily adapted for more servers if necessary.

## Prerequisites

In order to complete this guide, you will need access to two Ubuntu 16.04 servers. In line with the terminology that Redis uses, we will refer to the primary servers responsible for accepting write requests as the **master** server and the secondary read-only server as the **slave** server.

You should have a non-root user with `sudo` privileges configured on each of these servers. Additionally, this guide will assume that you have a basic firewall in place. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to fulfill these requirements.

When you are ready to begin, continue with this guide.

## Step 1: Install Redis

To get started, we will install Redis on both the **master** and **slave** servers.

We will install an up-to-date Redis Server package using [Chris Lea’s Redis PPA](https://launchpad.net/%7Echris-lea/+archive/ubuntu/redis-server). Always use caution when enabling third party repositories. In this case, Chris Lea is a well-established packager who maintains many high quality packages.

First, add the PPA to both of your servers:

    sudo apt-add-repository ppa:chris-lea/redis-server

Press `ENTER` to accept the repository.

Next, update the server’s local package index and install the Redis server package by typing:

    sudo apt-get update
    sudo apt-get install redis-server

This will install the Redis server and start the service.

Check that Redis is up and running by typing:

    redis-cli ping

You should receive back the following response:

    OutputPONG

This indicates that Redis is running and is accessible to the local client.

## Step 2: Secure Traffic Between the Two Servers

Before setting up replication, it is important to understand the implications of Redis’s security model. Redis offers no native encryption options and assumes that it has been deployed to a private network of trusted peers.

### If Redis Is Deployed to an Isolated Network…

If your servers are operating in an isolated network, you probably only need to adjust Redis’s configuration file to bind to your isolated network IP address.

Open the Redis configuration file on each computer:

    sudo nano /etc/redis/redis.conf

Find the `bind` line and append the server’s own isolated network IP address:

/etc/redis/redis.conf

    bind 127.0.0.1 isolated_IP_address

Save and close the file. Restart the service by typing:

    sudo systemctl restart redis-server.service

Open up access to the Redis port:

    sudo ufw allow 6379

You should now be able to access one server from the other by provide the alternate server’s IP address to the `redis-cli` command with the `-h` flag:

    redis-cli -h isolated_IP_address ping

    OutputPONG

Redis is now be able to accept connections from your isolated network.

### If Redis Is Not Deployed to an Isolated Network…

For networks that are not isolated or that you do not control, it is imperative that traffic is secured through other means. There are many options to secure traffic between Redis servers, including:

- [Tunneling with stunnel](how-to-encrypt-traffic-to-redis-with-stunnel-on-ubuntu-16-04): You will need an incoming and outgoing tunnel for each server. An example is available towards the bottom of the guide.
- [Tunneling with spiped](how-to-encrypt-traffic-to-redis-with-spiped-on-ubuntu-16-04): You will need to create two systemd unit files per server, one for communicating with the remote server and one for forwarding connections to its own Redis process. Details are included towards the bottom of the guide.
- [Setting up a VPN with PeerVPN](how-to-encrypt-traffic-to-redis-with-peervpn-on-ubuntu-16-04): Both servers will need to be accessible on the VPN.

Using one of the methods above, establish a secure communication method between your Redis master and slave server. You should know the IP address and port that each machine needs to securely connect to the Redis service on its peer.

## Step 3: Configure Redis Master

Now that Redis is up and running on each server and a secure channel of communication has been established, we have to edit their configuration files. Let’s start with the server that will function as the **master**.

Open `/etc/redis/redis.conf` with your favorite text editor:

    sudo nano /etc/redis/redis.conf

Begin by finding the `tcp-keepalive` setting and setting it to 60 seconds as the comments suggest. This will help Redis detect networking or service problems:

/etc/redis/redis.conf

    . . .
    tcp-keepalive 60
    . . .

Find the `requirepass` directive and set it to a strong passphrase. While your Redis traffic should be secure from outside parties, this provides authentication to Redis itself. Since Redis is fast and does not rate limit password attempts, choose a strong, complex passphrase to protect against brute force attempts:

/etc/redis/redis.conf

    requirepass your_redis_master_password

Finally, there are a few optional settings you may wish to adjust depending on your usage scenario.

If you do not want Redis to automatically prune older and less used keys as it fills up, you can turn off automatic key eviction:

/etc/redis/redis.conf

    maxmemory-policy noeviction

For improved durability guarantees, you can turn on append-only file persistence. This will help minimize data loss in the event of a systems failure at the expense of larger files and slightly slower performance:

/etc/redis/redis.conf

    appendonly yes
    appendfilename "redis-staging-ao.aof"

When you are finished, save and close the file.

Restart the Redis service to reload our configuration changes:

    sudo systemctl restart redis-server.service

Now that the master server configured, take a moment to test it.

## Step 4: Test the Redis Master

Check that you can authenticate using the password you set by starting the Redis client:

    redis-cli

First, try a command without authenticating:

    info replication

You should get the following response:

    Redis master outputNOAUTH Authentication required.

This is expected and indicates that our Redis server is correctly rejecting unauthenticated requests.

Next, use the `auth` command to authenticate:

    auth your_redis_master_password

You should receive confirmation that your credentials were accepted:

    Redis master outputOK

If you try the command again, it should succeed this time:

    info replication

    Redis master output# Replication
    role:master
    connected_slaves:0
    master_repl_offset:0
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0

While you are authenticated, set a test key so that we can check replication later:

    set test 'this key was defined on the master server'

Exit back to the operating system shell when you are finished:

    exit

Now that we have the master server ready, let’s move on to our slave machine.

## Step 5: Configure the Redis Slave

Next, we need to make some changes to allow our **slave server** to connect to our master instance.

Open `/etc/redis/redis.conf` on the slave server:

    sudo nano /etc/redis/redis.conf

First, find and uncomment the `slaveof` line. This directive takes the IP address and port that you use to securely contact the master Redis server, separated by a space. By default, the Redis server listens on 6379 on the local interface, but each of the network security methods modifies the default in some way for external parties.

The values you use will depend on the method you used to secure your network traffic:

- **isolated network** : use the isolated network IP address and Redis port (6379) of the master server (for example `slaveof isolated_IP_address 6379`).
- **stunnel** or **spiped** : use the local interface (127.0.0.1) and the port configured to tunnel traffic (this would be `slaveof 127.0.0.1 8000` if you followed the guide).
- **PeerVPN** : Use the master server’s VPN IP address and the regular Redis port (this would be `slaveof 10.8.0.1 6379` if you followed the guide).

The general form is:

/etc/redis/redis.conf

    slaveof ip_to_contact_master port_to_contact_master

Next, uncomment and fill out the `masterauth` line with the password that was set for the Redis master server:

/etc/redis/redis.conf

    masterauth your_redis_master_password

Set a password for your slave server to prevent unauthorized access. The same warnings about password complexity apply here:

/etc/redis/redis.conf

    requirepass your_redis_slave_password

Save and close the file when you are finished.

## Step 6: Test the Redis Slave and Apply Changes

Before we restart the service to implement our changes, let’s connect to the local Redis instance on the slave machine and verify that the `test` key is unset:

    redis-cli

Query for the key by typing:

    get test

You should get back the following response:

    Redis slave output(nil)

This indicates that the local Redis instance does not have a key named `test`. Exit back to the shell by typing:

    exit

Restart the Redis service on the slave to implement these changes:

    sudo systemctl restart redis-server.service

This will apply all of the changes we made to the Redis slave configuration file.

Reconnect to the local Redis instance again:

    redis-cli

As with the Redis master server, operations should now fail if not authorized:

    get test

    Redis slave output(error) NOAUTH Authentication required.

Now, authenticate using the Redis slave’s password that you set in the last section:

    auth your_redis_slave_password

    Redis slave outputOK

If we try to access the key this time, we will find that it is available:

    get test

    Redis slave output"this key was defined on the master server"

Once we restarted our Redis service on the slave, replication began immediately.

You can verify this with Redis’s `info` command, which reports information about replication. The value of `master_host` and `master_port` should match the arguments you used for the `slaveof` option:

    info replication

    Redis slave output# Replication
    role:slave
    master_host:10.8.0.1
    master_port:6379
    master_link_status:up
    master_last_io_seconds_ago:5
    master_sync_in_progress:0
    slave_repl_offset:1387
    slave_priority:100
    slave_read_only:1
    connected_slaves:0
    master_repl_offset:0
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0

If you happen to look at the same information on the Redis master server, you would see something like this:

    info replication

    Redis master output# Replication
    role:master
    connected_slaves:1
    slave0:ip=10.8.0.2,port=6379,state=online,offset=1737,lag=1
    master_repl_offset:1737
    repl_backlog_active:1
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:2
    repl_backlog_histlen:1736

As you can see, the master and slave servers correctly identify one another in their defined relationship.

## Step 7: Promoting a Redis Slave to Master

A primary reason for setting up replication is to handle failures with minimal data loss and downtime. Redis slaves can be promoted to master status to handle write traffic in the event of a Redis master failure.

### Promoting a Redis Slave Manually

We can do this manually from the Redis slave server. Log in with the Redis client:

    redis-cli

Authenticate using the Redis slave password:

    auth your_redis_slave_password

Before promoting the Redis slave, try to overwrite the test key:

    set test 'this key was overwritten on the slave server'

This should fail because, by default, Redis slaves are configured to be read-only with the `slave-read-only yes` option:

    Redis slave output(error) READONLY You can't write against a read only slave.

To disable replication and promote the current server to master status, use the `slaveof` command with the value of `no one`:

    slaveof no one

    Redis slave outputOK

Check the replication information again:

    info replication

    Redis slave output# Replication
    role:master
    connected_slaves:0
    master_repl_offset:6749
    repl_backlog_active:0
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:0
    repl_backlog_histlen:0

As you can see, the slave is now designated a Redis master.

Try to overwrite the key again, and this time it should succeed:

    set test 'this key was overwritten on the slave server'

    Redis slave outputOK

Keep in mind that since the configuration file still designates this node as a Redis slave, if the service is restarted without modifying the configuration, it will resume replication. Also note that any settings you used for the Redis master may need to be reapplied here (for instance, turning on append-only files or modifying the eviction policy).

If there are any other slaves, point them to the newly promoted master to continue replicating changes. This can be done using the `slaveof` command and the new master’s connection information.

To manually resume replication to the original master, point the interim master and the slaves back to the original master using the `slaveof` command with the values used in the configuration file:

    slaveof ip_to_contact_master port_to_contact_master

    Redis slave outputOK

If you check the key on the slave again, you should see that the original value has been restored by the Redis master:

    get test

    Redis slave output"this key was defined on the master server"

For consistency reasons, all the data on the slave is flushed when it is resynchronized with a master server.

### Promoting a Redis Slave Automatically

Automatically promoting a Redis slave requires coordination with the application layer. This means that the implementation depends heavily on the application environment, making it difficult to suggest specific actions.

However, we can go over the general steps needed to accomplish an automatic failover. The steps below assume that all of the Redis servers have been configured to access one another:

- From the application, detect that the master server is no longer available.
- On one slave, execute the `slaveof no one` command. This will stop replication and promote it to master status.
- Adjust any settings on the new master to align with the previous master settings. This can be done in advance in the configuration file for most options.
- Direct traffic from your application to the newly promoted Redis master.
- On any remaining slaves, run `slaveof new_master_ip new_master_port`. This will make the slaves stop replicating from the old master, discard their (now deprecated) data completely, and start replicating from the new master.

After you’ve restored service to the original master server, you can either allow it to rejoin as a slave pointing to the newly promoted master, or allow it to resume duty as the master if required.

## Conclusion

We have set up an environment consisting of two servers, one acting as the Redis master and the other replicating data as a slave. This provides redundancy in the event of a systems or network failure, and can help distribute read operations among multiple servers for performance reasons. This is a good starting point for designing a Redis configuration to fit your production application and infrastructure needs, but is in no way an exhaustive guide on the subject. To learn more about using Redis for your application needs, check out our [other Redis tutorials](https://www.digitalocean.com/community/tags/redis).
