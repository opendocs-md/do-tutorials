---
author: finid
date: 2015-09-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-your-redis-installation-on-ubuntu-14-04
---

# How To Secure Your Redis Installation on Ubuntu 14.04

## Introduction

Redis is an in-memory, NoSQL, key-value cache and store that can also be persisted to disk.

This tutorial shows how to implement basic security for a Redis server.

However, keep in mind that Redis was designed for use by _trusted clients_ in a _trusted environment_, with no robust security features of its own. To underscore that point, here’s a quote from the [official Redis website](http://redis.io/topics/security):

> Redis is designed to be accessed by trusted clients inside trusted environments. This means that usually it is not a good idea to expose the Redis instance directly to the internet or, in general, to an environment where untrusted clients can directly access the Redis TCP port or UNIX socket.
> 
> …
> 
> In general, Redis is not optimized for maximum security but for maximum performance and simplicity.

Performance and simplicity without security is a recipe for disaster. Even the few security features Redis has are really nothing to rave about. Those include: a basic unencrypted password, and command renaming and disabling. It lacks a true access control system.

However, configuring the existing security features is still a big step up from leaving your database unsecured.

In this tutorial, you’ll read how to configure the few security features Redis has, and a few other system security features that will boost the security posture of a standalone Redis installation on Ubuntu 14.04.

Note that this guide does not address situations where the Redis server and the client applications are on different hosts or in different data centers. Installations where Redis traffic has to traverse an insecure or untrusted network require an entirely different set of configurations, such as setting up an SSL proxy or a [VPN](how-to-set-up-an-openvpn-server-on-ubuntu-14-04) between the Redis machines, in addition to the ones given here.

## Prerequisites

For this tutorial, you’ll need:

- An Ubuntu 14.04 server with a sudo user added, from the [initial server setup](initial-server-setup-with-ubuntu-14-04)

- iptables configured using [this iptables guide](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04), up through the **(Optional) Update Nameservers** step (if you don’t do the nameserver configuration part, APT won’t work). After configuring the nameservers, you’re done

- Redis installed and working using instructions from the master-only installation from [this Redis guide](how-to-configure-a-redis-cluster-on-ubuntu-14-04), up through the **Step 2 — Configure Redis Master** step

## Step 1 — Verifying that Redis is Running

First log in to your server using SSH:

    ssh username@server-ip-address

To check that Redis is working, use the Redis command line. The `redis-cli` command is used to access the Redis command line.

    redis-cli

If you already set a password for Redis, you have to `auth` after connecting.

    auth your_redis_password

Output

    OK

Test the database server:

    ping

Response:

Output

    PONG

Exit:

    quit

## Step 2 — Securing the Server with iptables

If you followed the prerequisites for iptables, feel free to skip this step. Or, you can do it now.

Redis is just an application that’s running on your server, and because it has no real security features of its own, the first step to truly securing it is to first secure the server it is running on.

In the case of a public-facing server like your Ubuntu 14.04 server, configuring a firewall as given in [this iptables guide](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04) is that first step. **Follow that link and set up your firewall now.**

If you’ve implemented the firewall rules using that guide, then you do not need to add an extra rule for Redis, because by default, all incoming traffic is dropped unless explicitly allowed. Since a default standalone installation of Redis server is listening only on the loopback interface (127.0.0.1 or localhost), there should be no concern for incoming traffic on its default port.

If you need to specifically allow an IP address for Redis, you can check what IP address Redis is listening on, and what port it is bound to by `grep`-ing the output of the `netstat` command. The fourth column — **127.0.0.1:6379** here — indicates the IP address and port combination associated with Redis:

    sudo netstat -plunt | grep -i redis

Output

    tcp 0 0 127.0.0.1:6379 0.0.0.0:* LISTEN 8562/redis-server 1

Make sure this IP address is allowed in your Firewall policy. For more information on how to add rules, please see this [iptables basics article](iptables-essentials-common-firewall-rules-and-commands).

## Step 3 — Binding to localhost

By default, Redis server is only accessible from localhost. However, if you followed the tutorial to set up a Redis master server, you updated the configuration file to allow connections from anywhere. This is not as secure as binding to localhost.

Open the Redis configuration file for editing:

    sudo nano /etc/redis/redis.conf

Locate this line and make sure it is uncommented (remove the `#` if it exists):

/etc/redis/redis.conf

    bind 127.0.0.1

We’ll keep using this file, so keep it open for now.

## Step 4 — Configuring a Redis Password

If you installed Redis using the [How To Configure a Redis Cluster on Ubuntu 14.04](how-to-configure-a-redis-cluster-on-ubuntu-14-04) article, you should have configured a password for it. At your discretion, you can make a more secure password now by following this section. If not, instructions in this section show how to set the database server password.

Configuring a Redis password enables one of its two built-in security feature - the `auth` command, which requires clients to authenticate to access the database. The password is configured directly in Redis’s configuration file, `/etc/redis/redis.conf`, which you should still have open from the previous step.

Scroll to the `SECURITY` section and look for a commented directive that reads:

/etc/redis/redis.conf

    # requirepass foobared

Uncomment it by removing the `#`, and change `foobared` to a very strong and very long value.

Rather than make up a password yourself, you may use a tool like `apg` or `pwgen` to generate one. If you don’t want to install an application just to generate a password, you may use the one-liner below. To generate a password different from the one that this would generate, change the word in quotes.

    echo "digital-ocean" | sha256sum

Your output should look something like:

Output

    960c3dac4fa81b4204779fd16ad7c954f95942876b9c4fb1a255667a9dbe389d

Though the generated password will not be pronounceable, it gives you a very strong and very long one, which is exactly the type of password required for Redis. After copying and pasting the output of that command as the new value for `requirepass`, it should read:

/etc/redis/redis.conf

    requirepass 960c3dac4fa81b4204779fd16ad7c954f95942876b9c4fb1a255667a9dbe389d

If you prefer a shorter password, use the output of the command below instead. Again, change the word in quotes so it will not generate the same password as this one:

    echo "digital-ocean" | sha1sum

You’ll get somewhat shorter output this time:

Output

    10d9a99851a411cdae8c3fa09d7290df192441a9

After setting the password, save the file, and restart Redis:

    sudo service redis-server restart

To test that the password works, access the Redis command line:

    redis-cli

The following output shows a sequence of commands used to test whether the Redis password works. The first command tries to set a key to a value before authentication.

    set key1 10

That won’t work, so Redis returns an error.

Output

    (error) NOAUTH Authentication required.

The second command authenticates with the password specified in the Redis configuration file.

    auth your_redis_password

Redis acknowledges.

Output

    OK

After that, re-running the previous command succeeds.

    set key1 10

Output

    OK

`get key1` queries Redis for the value of the new key.

    get key1

Output

    "10"

The last command exits `redis-cli`. You may also use `exit`:

    quit

Next, we’ll look at renaming Redis commands.

## Step 5 — Renaming Dangerous Commands

The other security feature built into Redis allows you to rename or completely disable certain commands that are considered dangerous.

When run by unauthorized users, such commands can be used to reconfigure, destroy, or otherwise wipe your data. Like the authentication password, renaming or disabling commands is configured in the same `SECURITY` section of the `/etc/redis/redis.conf` file.

Some of the commands that are known to be dangerous include: **FLUSHDB** , **FLUSHALL** , **KEYS** , **PEXPIRE** , **DEL** , **CONFIG** , **SHUTDOWN** , **BGREWRITEAOF** , **BGSAVE** , **SAVE** , **SPOP** , **SREM** , **RENAME** and **DEBUG**. That’s not a comprehensive list, but renaming or disabling all of the commands in that list is a good starting point.

Whether you disable or rename a command is site-specific. If you know you will never use a command that can be abused, then you may disable it. Otherwise, rename it.

To enable or disable Redis commands, open the configuration file for editing one more time:

    sudo nano /etc/redis/redis.conf

**These are examples. You should choose to disable or rename the commands that make sense for you.** You can check the commands for yourself and determine how they might be misused at [redis.io/commands](http://redis.io/commands).

To disable or kill a command, simply rename it to an empty string, as shown below:

/etc/redis/redis.conf

    # It is also possible to completely kill a command by renaming it into
    # an empty string:
    #
    rename-command FLUSHDB ""
    rename-command FLUSHALL ""
    rename-command DEBUG ""

And to rename a command, give it another name, as in the examples below. Renamed commands should be difficult for others to guess, but easy for you to remember. Don’t make life difficult for yourself.

/etc/redis/redis.conf

    rename-command CONFIG ""
    rename-command SHUTDOWN SHUTDOWN_MENOT
    rename-command CONFIG ASC12_CONFIG

Save your changes.

After renaming a command, apply the change by restarting Redis:

    sudo service redis-server restart

To test the new command, enter the Redis command line:

    redis-cli

Then, assuming that you renamed the **CONFIG** command to **ASC12\_CONFIG** , the following output shows how to test that the new command has been applied.

After authenticating:

    auth your_redis_password

Output

    OK

The first attempt to use the `config` command should fail, because it has been renamed.

    config get requirepass

Output

    (error) ERR unknown command 'config'

Calling the renamed command should be successful (it’s case-insensitive):

    asc12_config get requirepass

Output

    1) "requirepass"
    2) "your_redis_password"

Finally, you can exit from `redis-cli`:

    exit

Note: If you’re already using the Redis command line and then restart Redis, you’ll need to re-authenticate. Otherwise, you’ll get this error if you type a command:

Output

    NOAUTH Authentication required.

Regarding renaming commands, there’s a cautionary statement at the end of the `SECURITY` section in `/etc/redis/redis.conf` which reads:

> `Please note that changing the name of commands that are logged into the AOF file or transmitted to slaves may cause problems.`

That means if the renamed command is not in the AOF file, or if it is but the AOF file has not beeen transmitted to slaves, then there should be no problem.

So, keep that in mind when you’re trying to rename commands. The best time to rename a command is when you’re not using AOF persistence, or right after installation, that is, before your Redis-using application has been deployed.

When you’re using AOF and dealing with a master-slave installation, consider this answer from the project’s GitHub issue page. The following is a reply to the author’s question:

> The commands are logged to the AOF and replicated to the slave the same way they are sent, so if you try to replay the AOF on an instance that doesn’t have the same renaming, you may face inconsistencies as the command cannot be executed (same for slaves).

So, the best way to handle renaming in cases like that is to make sure that renamed commands are applied to all instances in master-slave installations.

## Step 6 — Setting Data Directory Ownership and File Permissions

In this step, we’ll consider a couple of ownership and permissions changes you can make to improve the security profile of your Redis installation. This involves making sure that only the user that needs to access Redis has permission to read its data. That user is, by default, the **redis** user.

You can verify this by `grep`-ing for the Redis data directory in a long listing of its parent directory. The command and its output are given below.

    ls -l /var/lib | grep redis

Output

    drwxr-xr-x 2 redis redis 4096 Aug 6 09:32 redis

You can see that the Redis data directory is owned by the **redis** user, with secondary access granted to the **redis** group. That part is good.

The part that’s not is the folder’s permissions, which is 755. To ensure that only the Redis user has access to the folder and its contents, change the permission to 700:

    sudo chmod 700 /var/lib/redis

The other permission you should change is that of the Redis configuration file. By default, it has a file permission of 644 and is owned by **root** , with secondary ownership by the **root** group:

    ls -l /etc/redis/redis.conf

Output

    -rw-r--r-- 1 root root 30176 Jan 14 2014 /etc/redis/redis.conf

That permission (644) is world-readable, which is not a good idea, because it contains the unencrypted password configured in Step 4.

We need to change the ownership and permissions. Ideally, it should be owned by the **redis** user, with secondary ownership by the **root** user. To do that, run the following command:

    sudo chown redis:root /etc/redis/redis.conf

Then change the ownership so that only the owner of the file can read and/or write to it:

    sudo chmod 600 /etc/redis/redis.conf

You may verify the new ownership and permission using:

    ls -l /etc/redis/redis.conf

Output

    total 40
    -rw------- 1 redis root 29716 Sep 22 18:32 /etc/redis/redis.conf

Finally, restart Redis:

    sudo service redis-server restart

## Conclusion

Keep in mind that once someone is logged in to your server, it’s very easy to circumvent the Redis-specific security features we’ve put in place. So, the most important security feature is one that makes it extremely difficult to jump that fence.

That should be your firewall.

To take your server security to the next level, you could configure an intrusion detection system like OSSEC. To configure OSSEC on Ubuntu 14.04, see [this OSSEC guide](how-to-install-and-configure-ossec-security-notifications-on-ubuntu-14-04).

If you’re attempting to secure Redis communication across an untrusted network you’ll have to employ an SSL proxy, as recommeded by Redis developers in the [official Redis security guide](http://redis.io/topics/security). Setting up an SSL proxy to secure Redis commmunication is a separate topic.

We didn’t include a full list of Redis commands in the renaming section. However, you can check this for yourself and determine how they might be misused at [redis.io/commands](http://redis.io/commands).
