---
author: Mark Drake
date: 2019-09-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-connect-to-managed-redis-over-tls-with-stunnel-and-redis-cli
---

# How To Connect to a Managed Redis Instance over TLS with Stunnel and redis-cli

## Introduction

A managed [Redis](https://redis.io/) instance can provide benefits like high availability and automated updates. However, any time you make a connection to a remote database server, you run the risk of malicious actors [sniffing](https://en.wikipedia.org/wiki/Sniffing_attack) the sensitive information you send to it.

[`redis-cli`](https://redis.io/topics/rediscli), the Redis command line interface, doesn’t natively support connections over [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security), a cryptographic protocol that allows for secure communications over a network. This means that without further configuration, `redis-cli` is not a secure way to connect to a remote Redis server. One way to establish a secure connection to a managed Redis instance is to create a [tunnel](https://en.wikipedia.org/wiki/Tunneling_protocol) that uses the TLS protocol.

[Stunnel](https://www.stunnel.org/) is an open-source proxy used to create secure tunnels, allowing you to communicate with other machines over TLS. In this guide, we will walk through installing and configuring stunnel so you can connect to a managed Redis instance over TLS with `redis-cli`.

## Prerequisites

To complete this guide, you will need:

- Access to an Ubuntu 18.04 server. This server should have a non-root user with administrative privileges and a firewall configured with `ufw`. To set this up, follow our [initial server setup guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).
- A managed Redis database instance. The steps outlined in this tutorial were tested on a DigitalOcean Managed Redis Database, though they should generally work for managed databases from any cloud provider. To provision a DigitalOcean Managed Redis Database, follow our [Managed Redis product documentation](https://www.digitalocean.com/docs/databases/redis/how-to/create/).

## Step 1 — Installing Stunnel and redis-cli

When you install a Redis server, it usually comes packaged with `redis-cli`. However, you can install `redis-cli` without the Redis server by installing the `redis-tools` package from the default Ubuntu repositories. You can also install stunnel from the default Ubuntu repositories by downloading the `stunnel4` package.

First, update your server’s package index if you’ve not done so recently:

    sudo apt update

Then install the `redis-tools` and `stunnel4` packages with APT:

    sudo apt install redis-tools stunnel4

When prompted, press `ENTER` to confirm that you want to install the packages.

You can check whether stunnel was installed correctly and its [systemd](https://en.wikipedia.org/wiki/Systemd) service is working by running the following command:

    sudo systemctl status stunnel4

    Output● stunnel4.service - LSB: Start or stop stunnel 4.x (TLS tunnel for network daemons)
       Loaded: loaded (/etc/init.d/stunnel4; generated)
       Active: active (exited) since Thu 2019-09-12 14:34:05 UTC; 8s ago
         Docs: man:systemd-sysv-generator(8)
        Tasks: 0 (limit: 2362)
       CGroup: /system.slice/stunnel4.service
    
    Sep 12 14:34:05 stunnel systemd[1]: Starting LSB: Start or stop stunnel 4.x (TLS tunnel for network daemons)...
    Sep 12 14:34:05 stunnel stunnel4[2034]: TLS tunnels disabled, see /etc/default/stunnel4
    Sep 12 14:34:05 stunnel systemd[1]: Started LSB: Start or stop stunnel 4.x (TLS tunnel for network daemons).

Here, you can see that the stunnel service is active, though the process immediately exited. This tells us that stunnel is running, but it isn’t able to actually do anything since we haven’t yet configured it.

## Step 2 — Configuring Stunnel

Modern Linux systems rely on systemd for initializing and managing services and daemons. However, stunnel uses a SysV-style init script, which is based on the older [UNIX System V](https://en.wikipedia.org/wiki/UNIX_System_V) init system, for startup. You’ll need to modify the `/etc/default/stunnel4` file to enable this init script.

Open this file with your preferred text editor. Here, we’ll use `nano`:

    sudo nano /etc/default/stunnel4

Find the `ENABLED` option near the top of the file. It will be set to `0` by default, but change this to `1` to enable stunnel to start at boot:

/etc/default/stunnel4

    # /etc/default/stunnel
    # Julien LEMOINE <speedblue@debian.org>
    # September 2003
    
    # Change to one to enable stunnel automatic startup
    ENABLED=1
    . . .

Save and close the file. If you used `nano` to edit the file, do so by pressing `CTRL+X`, `Y`, then `ENTER`.

Next, you will need to create a configuration file for stunnel which will tell the program where it needs to route traffic.

Open a new file called `stunnel.conf` under the `/etc/stunnel` directory:

    sudo nano /etc/stunnel/stunnel.conf

Add the following content to this file:

/etc/stunnel/stunnel.conf

    fips = no
    setuid = nobody
    setgid = nogroup
    pid =
    debug = 7
    [redis-cli]
      client = yes
      accept = 127.0.0.1:8000
      connect = managed_redis_hostname_or_ip:managed_redis_port

The first five lines in the file are _global options_, meaning they will apply to every service you include in this file:

- `fips`: Enables or disables stunnel’s FIPS 140-2 mode. In this mode, stunnel will validate that the connection meets the [Federal Information Processing Standard](https://en.wikipedia.org/wiki/FIPS_140-2). Setting this to `no` disables this feature. Note that disabling this is not any less secure, but keeping it enabled (as it is by default) would require some extra configuration.
- `setuid`: Defines the Unix user ID under which stunnel will run. By default, the stunnel process is owned by the **root** user. However, the [stunnel documentation recommends](https://www.stunnel.org/config_unix.html) that you drop administrative privileges once the tunnel starts, as failing to do so poses a security risk. Setting the `setuid` parameter to `nobody` will cause **nobody** , an unprivileged user, to take ownership over the stunnel process once the tunnel has been established.
- `setgid`: Defines the Unix group ID under which stunnel will run. As with `setuid`, this configuration specifies a group without any special privileges — **nogroup** — to avoid any potential security issues.
- `pid`: Defines a file location where stunnel will create a `.pid` file, a type of file that contains a process’s [PID](https://en.wikipedia.org/wiki/Process_identifier). `.pid` files are typically used by other programs to find the PID of a running process. By default, stunnel creates a `.pid` file in the `/var/run/stunnel4/` directory. Because the **nobody** user doesn’t have permission to access that directory, it will prevent the tunnel from starting correctly. By not providing any argument to the `pid` parameter in this configuration we’re disabling this behavior, as a `.pid` file isn’t necessary for the purposes of this tutorial. If you do need a `.pid` file for your use case, though, be sure to set this to a file that **nobody** has permission to write to.
- `debug`: Sets stunnel’s debugging level, which can range from `0` to `7`. In this example we’ll set it to `7`, the highest level available, as that will provide the most detailed information if stunnel runs into any issues. You can set it to any level you like, but be aware that the default setting is `5`. 

The remaining lines are _service-level options_, and only apply to the tunnel we’ll create for `redis-cli`:

- `[redis-cli]`: This is a _service name_ and specifies that the following lines represent an individual service configuration for a client program. You can have more than one service in a stunnel configuration file, though each must be associated with an existing client application and you can’t have two services for the same application.
- `client`: Setting this to `yes` tells stunnel to run in client mode, meaning that stunnel will connect to a TLS server (the managed Redis instance) rather than act as a TLS server.
- `accept`: Defines the host and port on which stunnel will accept connections from the client. Here, we specify the IP address `127.0.0.1`, which is an IPv4 loopback address used to represent **localhost** , and port `8000`. This means stunnel will listen for connections originating from the Ubuntu server on port `8000` and encrypt them. Note that you can set the port to any port number you like as long as it’s not already in use.
- `connect`: Defines the remote address and port to which stunnel will make the connection. Be sure to change this parameter to align with your managed database’s port and hostname or IP address.

**Note:** The hostname or IP address and port you should specify in the `connect` directive will be specific to your own managed Redis database. These can usually be found in your cloud provider’s database management user interface where you provisioned your Redis instance.

If you’re using a DigitalOcean Managed Redis Database, you can find this information by going to your [**Control Panel**](https://cloud.digitalocean.com/login) and clicking on **Databases** in the left-hand sidebar menu. Then, click on the name of the Redis instance you want to connect to and scroll down to the **Connection Details** section. There, you will find fields describing your database’s **host** and **port**.

This is a fairly minimal configuration that leaves many of stunnel’s default settings in place. The program has many options available for you to create tunnels that suit your particular needs. See [the official documentation](https://www.stunnel.org/static/stunnel.html) for more details.

After adding this content, save and close the file.

Then, restart the `stunnel4` service so stunnel will read the new configuration file:

    sudo systemctl restart stunnel4

Following that, you can test whether stunnel has created with `netstat`, a command line utility used to display network connections. Run the following command, which pipelines the `netstat` output into a `grep` command, which then searches it for every instance of `stunnel`:

    sudo netstat -plunt | grep stunnel

    Output tcp 0 0 127.0.0.1:8000 0.0.0.0:* LISTEN 17868/stunnel 

This output shows that stunnel is listening for connections on local port `8000`.

You can also confirm that the **nobody** user has taken ownership over the stunnel process with `ps`, a program that displays all currently-running processes:

    ps aux | grep stunnel

    Output nobody 15674 0.0 0.1 121912 3180 ? Ssl 19:28 0:00 /usr/bin/stunnel4 /etc/stunnel/stunnel.conf
    . . .

Here, you can see that **nobody** has indeed taken over the stunnel process.

Stunnel is now fully configured and running on your system. You’re ready to connect to your managed Redis instance and test that the tunnel is working as expected.

## Step 3 — Connecting To Your Managed Database over TLS

Now that you’ve installed `redis-cli` and configured stunnel on your server, you’re ready to connect to your managed database over TLS.

Based on the settings defined in the configuration file created in Step 2, you would connect to your managed database with the following command:

    redis-cli -h localhost -p 8000

This command includes the `-h` flag, which tells `redis-cli` that the next argument will be the host to connect to. In this case, it’s `localhost` since we’re connecting to a tunnel created locally on the server. After that is the `-p` flag, which precedes the port of the local tunnel we’re connecting to, which in this case is port `8000`.

After running that command, you will be connected to your managed Redis server. Your prompt will change to reflect that you’ve connected and are in `redis-cli`’s interactive mode:

    

**Note:** Oftentimes, managed databases are configured to require users to authenticate with a password when they connect. If your managed Redis instance requires a password, you can include the `-a` flag in your `redis-cli` command, followed by your password:

    redis-cli -h localhost -p 8000 -a password

Alternatively, you can authenticate by running the `auth` command followed by your password after establishing the connection:

    auth password

If you’re using a DigitalOcean Managed Database, you can find your Redis instance’s password in the same place you found its hostname and port. In your **Control Panel** , click on **Databases** in the left-hand sidebar menu. Then, click on the name of the Redis instance you’ve connected to. Scroll down to the **Connection Details** section, and there you’ll find a field labeled **password**. Click on the **show** button to reveal the password, then copy and paste it into either of these commands — replacing `password` — in order to authenticate.

You can test whether the tunnel is working as expected by running the `ping` command from Redis’s interactive mode:

    ping

If the connection is alive it will return `PONG`:

    Output PONG

If, however, stunnel is not tunnelling traffic from your server to your Redis instance correctly, you may see an error message like this before being disconnected from Redis:

    Output Error: Server closed the connection

If you receive this or a similar error, double check that you’ve entered your Redis instance’s hostname and port correctly in your `stunnel.conf` file. Likewise, be sure that you entered the correct port number in your `redis-cli` command.

Once you’ve confirmed that the tunnel is working, go ahead and disconnect from your Redis instance:

    exit

If you ever change stunnel’s configuration, you’ll need to reload or restart the `stunnel4` service so stunnel will notice the changes:

    sudo systemctl reload stunnel4

However, if at any point in the future you want to close the TLS tunnel, you won’t be able to close it with `systemctl`. Instead, you’ll need to kill the process with the `pkill` command:

    sudo pkill stunnel

After the tunnel has ben closed, you can reopen the tunnel by restarting the service:

    sudo systemctl restart stunnel4

Now that you’ve successfully configured stunnel, you’re all set to begin adding data to your managed Redis instance with `redis-cli`.

## Conclusion

Stunnel is a handy tool for creating TLS tunnels and establishing secure connections to remote servers. This is especially useful in cases where the secure transport of information between machines is critical, as with a remote database.

From here, you can begin exploring Redis and integrating it with your next application. If you’re new to working with Redis, you may find our series on [How To Manage a Redis Database](https://www.digitalocean.com/community/tutorial_series/how-to-manage-a-redis-database) useful.
