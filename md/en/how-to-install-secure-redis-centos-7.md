---
author: Mark Drake
date: 2018-03-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-secure-redis-centos-7
---

# How to Install and Secure Redis on Centos7

## Introduction

[Redis](https://redis.io/) is an open-source, in-memory data structure store which excels at caching. A non-relational database, Redis is known for its flexibility, performance, scalability, and wide language support.

Redis was designed for use by trusted clients in a trusted environment, and has no robust security features of its own. Redis does, however, have [a few security features](https://redis.io/topics/security) that include a basic unencrypted password and command renaming and disabling. This tutorial provides instructions on how to configure these security features, and also covers a few other settings that can boost the security of a standalone Redis installation on CentOS 7.

Note that this guide does not address situations where the Redis server and the client applications are on different hosts or in different data centers. Installations where Redis traffic has to traverse an insecure or untrusted network will require a different set of configurations, such as setting up an SSL proxy or a [VPN](how-to-setup-and-configure-an-openvpn-server-on-centos-7) between the Redis machines.

## Prerequisites

To follow along with this tutorial, you will need:

- One CentOS 7 Droplet configured using our [Initial Server Setup for CentOS 7](initial-server-setup-with-centos-7).
- Firewalld installed and configured using [this guide](how-to-set-up-a-firewall-using-firewalld-on-centos-7), up to and including the “Turning on the Firewall” step. 

With those prerequisites in place, we are ready to install Redis and perform some initial configuration tasks.

## Step 1 — Installing Redis

Before we can install Redis, we must first add [Extra Packages for Enterprise Linux (EPEL) repository](https://fedoraproject.org/wiki/EPEL) to the server’s package lists. EPEL is a package repository containing a number of open-source add-on software packages, most of which are maintained by the Fedora Project.

We can install EPEL using `yum`:

    sudo yum install epel-release

Once the EPEL installation has finished you can install Redis, again using `yum`:

    sudo yum install redis -y

This may take a few minutes to complete. After the installation finishes, start the Redis service:

    sudo systemctl start redis.service

If you’d like Redis to start on boot, you can enable it with the `enable` command:

    sudo systemctl enable redis

You can check Redis’s status by running the following:

    sudo systemctl status redis.service

    Output● redis.service - Redis persistent key-value database
       Loaded: loaded (/usr/lib/systemd/system/redis.service; disabled; vendor preset: disabled)
      Drop-In: /etc/systemd/system/redis.service.d
               └─limit.conf
       Active: active (running) since Thu 2018-03-01 15:50:38 UTC; 7s ago
     Main PID: 3962 (redis-server)
       CGroup: /system.slice/redis.service
               └─3962 /usr/bin/redis-server 127.0.0.1:6379

Once you’ve confirmed that Redis is indeed running, test the setup with this command:

    redis-cli ping

This should print `PONG` as the response. If this is the case, it means you now have Redis running on your server and we can begin configuring it to enhance its security.

## Step 2 — Binding Redis and Securing it with a Firewall

An effective way to safeguard Redis is to secure the server it’s running on. You can do this by ensuring that Redis is bound only to either localhost or to a private IP address and that the server has a firewall up and running.

However, if you chose to set up a Redis cluster using [this tutorial](how-to-configure-a-redis-cluster-on-centos-7), then you will have updated the configuration file to allow connections from anywhere, which is not as secure as binding to localhost or a private IP.

To remedy this, open the Redis configuration file for editing:

    sudo vi /etc/redis.conf

Locate the line beginning with `bind` and make sure it’s uncommented:

/etc/redis.conf

    bind 127.0.0.1

If you need to bind Redis to another IP address (as in cases where you will be accessing Redis from a separate host) we **strongly** encourage you to bind it to a private IP address. Binding to a public IP address increases the exposure of your Redis interface to outside parties.

/etc/redis.conf

    bind your_private_ip

If you’ve followed the prerequisites and installed firewalld on your server and you do not plan to connect to Redis from another host, then you do not need to add any extra firewall rules for Redis. After all, any incoming traffic will be dropped by default unless explicitly allowed by the firewall rules. Since a default standalone installation of Redis server is listening only on the loopback interface (`127.0.0.1` or localhost), there should be no concern for incoming traffic on its default port.

If, however, you do plan to access Redis from another host, you will need to make some changes to your firewalld configuration using the `firewall-cmd` command. Again, you should only allow access to your Redis server from your hosts by using their private IP addresses in order to limit the number of hosts your service is exposed to.

To begin, add a dedicated Redis zone to your firewalld policy:

    sudo firewall-cmd --permanent --new-zone=redis

Then, specify which port you’d like to have open. Redis uses port `6397` by default:

    sudo firewall-cmd --permanent --zone=redis --add-port=6379/tcp

Next, specify any private IP addresses which should be allowed to pass through the firewall and access Redis:

    sudo firewall-cmd --permanent --zone=redis --add-source=client_server_private_IP

After running those commands, reload the firewall to implement the new rules:

    sudo firewall-cmd --reload

Under this configuration, when the firewall sees a packet from your client’s IP address, it will apply the rules in the dedicated Redis zone to that connection. All other connections will be processed by the default `public` zone. The services in the default zone apply to every connection, not just those that don’t match explicitly, so you don’t need to add other services (e.g. SSH) to the Redis zone because those rules will be applied to that connection automatically.

If you chose to [set up a firewall using Iptables](how-to-set-up-a-basic-iptables-firewall-on-centos-6), you will need to grant your secondary hosts access to the port Redis is using with the following commands:

    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp -s client_servers_private_IP/32 --dport 6397 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    sudo iptables -P INPUT DROP

Make sure to save your Iptables firewall rules using the mechanism provided by your distribution. You can learn more about Iptables by taking a look at our [Iptables essentials guide](iptables-essentials-common-firewall-rules-and-commands).

Keep in mind that using either firewall tool will work. What’s important is that the firewall is up and running so that unknown individuals cannot access your server. In the next step, we will configure Redis to only be accessible with a strong password.

## Step 3 — Configuring a Redis Password

If you installed Redis using the [How To Configure a Redis Cluster on CentOS 7](how-to-configure-a-redis-cluster-on-centos-7) tutorial, you should have configured a password for it. At your discretion, you can make a more secure password now by following this section. If you haven’t set up a password yet, instructions in this section show how to set the database server password.

Configuring a Redis password enables one of its built-in security features — the `auth` command — which requires clients to authenticate before being allowed access to the database. Like the `bind` setting, the password is configured directly in Redis’s configuration file, `/etc/redis.conf`. Reopen that file:

    sudo vi /etc/redis.conf

Scroll to the `SECURITY` section and look for a commented directive that reads:

/etc/redis.conf

    # requirepass foobared

Uncomment it by removing the `#`, and change `foobared` to a very strong password of your choosing. Rather than make up a password yourself, you may use a tool like `apg` or `pwgen` to generate one. If you don’t want to install an application just to generate a password, though, you may use the command below.

Note that entering this command as written will generate the same password every time. To create a password different from the one that this would generate, change the word in quotes to any other word or phrase.

    echo "digital-ocean" | sha256sum

Though the generated password will not be pronounceable, it is a very strong and very long one, which is exactly the type of password required for Redis. After copying and pasting the output of that command as the new value for `requirepass`, it should read:

/etc/redis.conf

    requirepass password_copied_from_output

If you prefer a shorter password, use the output of the command below instead. Again, change the word in quotes so it will not generate the same password as this one:

    echo "digital-ocean" | sha1sum

After setting the password, save and close the file then restart Redis:

    sudo systemctl restart redis.service

To test that the password works, access the Redis command line:

    redis-cli

The following is a sequence of commands used to test whether the Redis password works. The first command tries to set a key to a value before authentication.

    set key1 10

That won’t work as we have not yet been authenticated, so Redis returns an error.

    Output(error) NOAUTH Authentication required.

The following command authenticates with the password specified in the Redis configuration file.

    auth your_redis_password

Redis will acknowledge that we have been authenticated:

    OutputOK

After that, running the previous command again should be successful:

    set key1 10

    OutputOK

The `get key1` command queries Redis for the value of the new key.

    get key1

    Output"10"

This last command exits `redis-cli`. You may also use `exit`:

    quit

It should now be very difficult for unauthorized users to access your Redis installation. Please note, though, that without SSL or a VPN the unencrypted password will still be visible to outside parties if you’re connecting to Redis remotely.

Next, we’ll look at renaming Redis commands to further protect Redis from malicious actors.

## Step 4 — Renaming Dangerous Commands

The other security feature built into Redis allows you to rename or completely disable certain commands that are considered dangerous. When run by unauthorized users, such commands can be used to reconfigure, destroy, or otherwise wipe your data. Some of the commands that are known to be dangerous include:

- `FLUSHDB`
- `FLUSHALL` 
- `KEYS` 
- `PEXPIRE` 
- `DEL` 
- `CONFIG` 
- `SHUTDOWN` 
- `BGREWRITEAOF`
- `BGSAVE` 
- `SAVE` 
- `SPOP` 
- `SREM``RENAME``DEBUG` 

This is not a comprehensive list, but renaming or disabling all of the commands in that list is a good starting point.

Whether you disable or rename a command is site-specific. If you know you will never use a command that can be abused, then you may disable it. Otherwise, you should rename it instead.

Like the authentication password, renaming or disabling commands is configured in the `SECURITY` section of the `/etc/redis.conf` file. To enable or disable Redis commands, open the configuration file for editing one more time:

    sudo vi /etc/redis.conf

**NOTE** : These are examples. You should choose to disable or rename the commands that make sense for you. You can check the commands for yourself and determine how they might be misused at [redis.io/commands](http://redis.io/commands).

To disable or kill a command, simply rename it to an empty string, as shown below:

/etc/redis.conf

    # It is also possible to completely kill a command by renaming it into
    # an empty string:
    #
    rename-command FLUSHDB ""
    rename-command FLUSHALL ""
    rename-command DEBUG ""

To rename a command, give it another name like in the examples below. Renamed commands should be difficult for others to guess, but easy for you to remember:

/etc/redis.conf

    rename-command CONFIG ""
    rename-command SHUTDOWN SHUTDOWN_MENOT
    rename-command CONFIG ASC12_CONFIG

Save your changes and close the file, and then apply the change by restarting Redis:

    sudo service redis-server restart

To test the new command, enter the Redis command line:

    redis-cli

Authenticate yourself using the password you defined earlier:

    auth your_redis_password

    OutputOK

Assuming that you renamed the **CONFIG** command to **ASC12\_CONFIG** , attempting to use the `config` command should fail.

    config get requirepass

    Output(error) ERR unknown command 'config'

Calling the renamed command should be successful (it’s case-insensitive):

    asc12_config get requirepass

    Output1) "requirepass"
    2) "your_redis_password"

Finally, you can exit from `redis-cli`:

    exit

Note that if you’re already using the Redis command line and then restart Redis, you’ll need to re-authenticate. Otherwise, you’ll get this error if you type a command:

    OutputNOAUTH Authentication required.

Regarding renaming commands, there’s a cautionary statement at the end of the `SECURITY` section in the `/etc/redis.conf` file, which reads:

> `Please note that changing the name of commands that are logged into the AOF file or transmitted to slaves may cause problems.`

That means if the renamed command is not in the AOF file, or if it is but the AOF file has not been transmitted to slaves, then there should be no problem. Keep that in mind as you’re renaming commands. The best time to rename a command is when you’re not using AOF persistence or right after installation (that is, before your Redis-using application has been deployed).

When you’re using AOF and dealing with a master-slave installation, consider this answer from the project’s GitHub issue page. The following is a reply to the author’s question:

> The commands are logged to the AOF and replicated to the slave the same way they are sent, so if you try to replay the AOF on an instance that doesn’t have the same renaming, you may face inconsistencies as the command cannot be executed (same for slaves).

The best way to handle renaming in cases like that is to make sure that renamed commands are applied to all instances of master-slave installations.

## Step 5 — Setting Data Directory Ownership and File Permissions

In this step, we’ll consider a couple of ownership and permissions changes you can make to improve the security profile of your Redis installation. This involves making sure that only the user that needs to access Redis has permission to read its data. That user is, by default, the **redis** user.

You can verify this by `grep`-ing for the Redis data directory in a long listing of its parent directory. The command and its output are given below.

    ls -l /var/lib | grep redis

    Outputdrwxr-xr-x 2 redis redis 4096 Aug 6 09:32 redis

You can see that the Redis data directory is owned by the **redis** user, with secondary access granted to the **redis** group. This ownership setting is secure, but the folder’s permissions (which are set to 755) are not. To ensure that only the Redis user has access to the folder and its contents, change the permissions setting to 770:

    sudo chmod 770 /var/lib/redis

The other permission you should change is that of the Redis configuration file. By default, it has a file permission of 644 and is owned by **root** , with secondary ownership by the **root** group:

    ls -l /etc/redis.conf

    Output-rw-r--r-- 1 root root 30176 Jan 14 2014 /etc/redis.conf

That permission (644) is world-readable. This presents a security issue as the configuration file contains the unencrypted password you configured in Step 4, meaning we need to change the configuration file’s ownership and permissions. Ideally, it should be owned by the **redis** user, with secondary ownership by the **redis** group. To do that, run the following command:

    sudo chown redis:redis /etc/redis.conf

Then change the permissions so that only the owner of the file can read and/or write to it:

    sudo chmod 660 /etc/redis.conf

You may verify the new ownership and permissions using:

    ls -l /etc/redis.conf

    Outputtotal 40
    -rw------- 1 redis redis 29716 Sep 22 18:32 /etc/redis.conf

Finally, restart Redis:

    sudo service redis-server restart

Congratulations, your Redis installation should now be more secure!

## Conclusion

Keep in mind that once someone is logged in to your server, it’s very easy to circumvent the Redis-specific security features we’ve put in place. This is why the most important security feature covered in this tutorial is the firewall, as that prevents unknown users from logging into your server in the first place.

If you’re attempting to secure Redis communication across an untrusted network you’ll have to employ an SSL proxy, as recommended by Redis developers in the [official Redis security guide](http://redis.io/topics/security).
