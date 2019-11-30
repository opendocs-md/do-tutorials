---
author: Justin Ellingwood
date: 2016-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-traffic-to-redis-with-spiped-on-ubuntu-16-04
---

# How To Encrypt Traffic to Redis with Spiped on Ubuntu 16.04

## Introduction

Redis is an open-source key-value data store, using an in-memory storage model with optional disk writes for persistence. It features transactions, a pub/sub messaging pattern, and automatic failover among other functionality. Redis has clients written in most languages with recommended ones featured on [their website](http://redis.io/clients).

Redis does not provide any encryption capabilities of its own. It operates under the assumption that it has been deployed to an isolated private network, accessible only to trusted parties. If your environment does not match that assumption, you will have to wrap Redis traffic in encryption separately.

In this guide, we will demonstrate how to encrypt Redis traffic using a secure piping program called `spiped`. Traffic between Redis clients and servers will be routed through a dedicated encrypted tunnel, similar to a dedicated SSH tunnel. We will be using two Ubuntu 16.04 servers to demonstrate.

## Prerequisites

To get started, you should have a non-root user with `sudo` privileges configured on each of your machines. Additionally, this guide will assume that you have a basic firewall in place. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to fulfill these requirements.

When you are ready to continue, follow along below.

## What is spiped?

The `spiped` utility is simple to install and configured for secure communication between two network sockets (regular network ports or Unix sockets). It can be used to configure encrypted communication between two remote servers. The client connects to a local port and `spiped` wraps it in encryption before forwarding it to the remote server. On the server side, `spiped` listens on the configured port and decrypts traffic before forwarding it to a local port (in our case, the port that the Redis server listens on).

Some advantages of using `spiped` are:

- Ubuntu maintains packages for `spiped` in its default repositories.
- The [Redis project currently suggests](http://redis.io/topics/encryption) using `spiped` to encrypt traffic.
- Configuration is straightforward and intuitive.
- A new pipe is used for each purpose. This might be a disadvantage in some situations, but it provides granular control over access.

Some disadvantages are:

- Clients connect to the remote machine by attaching to a non-default local port, which may be unintuitive at first.
- If connecting two Redis servers for replication or clustering, two tunnels must be configured on each machine for server-to-server communication (one for outbound and one for inbound traffic).
- There is no included init script, so one must be created in order to automatically create the necessary connections at boot.

With these characteristics in mind, let’s get started.

## Install the Redis Server and Client Packages

Before we begin, we should have the Redis server installed on one machine and the client packages available on the other. If you already have one or both of these configured, feel free to skip ahead.

**Note:** The Redis server instructions set a test key that will be used to test the connection later. If you already have the Redis server installed, you can go ahead and set this key or use any other known key when we test the connection.

### Installing the Redis Server

We will use [Chris Lea’s Redis server PPA](https://launchpad.net/%7Echris-lea/+archive/ubuntu/redis-server) to install an up-to-date version of Redis. Always use caution when utilizing a third party repository. In this case, Chris Lea is a trusted packager who maintains high quality, up-to-date packages for several popular open-source projects.

Add the PPA and install the Redis server software on your first machine by typing:

    sudo apt-add-repository ppa:chris-lea/redis-server
    sudo apt-get update
    sudo apt-get install redis-server

Type **Enter** to accept the prompts during this process.

When the installation is complete, test that you can connect to the Redis service locally by typing:

    redis-cli ping

If the software is installed and running, you should see:

    Redis server outputPONG

Let’s set a key that we can use later:

    redis-cli set test 'success'

We have set the **test** key to the value `success`. We will try to access this key from our client machine after configuring `spiped`.

### Installing the Redis Client

The other Ubuntu 16.04 machine will function as the client. All of the software we need is available in the `redis-tools` package in the default repository:

    sudo apt-get update
    sudo apt-get install redis-tools

With the default configuration of the remote Redis server and a firewall active, we can’t currently connect to the remote Redis instance to test.

## Install spiped On Each Computer

Next, you will need to install `spiped` on each of the servers and clients. If you did not need to install anything in the previous section, make sure to include the `sudo apt-get update` command to refresh your package index before installing:

    sudo apt-get install spiped

Now that we have have the necessary software installed, we can generate a secure key that `spiped` can use to encrypt traffic between our two machines.

## Generate an Encryption Key on the Redis Server

Next, create an `spiped` configuration directory within `/etc` on your Redis server to store the key we will generate for encryption:

    sudo mkdir /etc/spiped

Generate a secure key by typing:

    sudo dd if=/dev/urandom of=/etc/spiped/redis.key bs=32 count=1

Restrict access to the generated key file by adjusting the permissions:

    sudo chmod 600 /etc/spiped/redis.key

Now that we have the key available on the Redis server, we can set up `spiped` on the server using a systemd unit file.

## Create a systemd Unit File for Redis Servers

The `spiped` utility is very simple and it does not have support for reading a configuration file. Because each pipe must be configured manually, the Ubuntu package does not come with an init script to start a pipe automatically at boot.

To resolve these issues, we will create a simple systemd unit file. Open a new unit file in the `/etc/systemd/system` directory to get started:

    sudo nano /etc/systemd/system/spiped-receive.service

Inside, create a `[Unit]` section to describe the unit and establish ordering so that this unit is started after networking is available:

/etc/systemd/system/spiped-receive.service

    [Unit]
    Description=spiped receive for Redis
    Wants=network-online.target
    After=network-online.target

Next, open a `[Service]` section to define the actual command to run. We will use the following options with `spiped`:

- `-F`: Run in the foreground. The systemd init system is designed to manage services running in the foreground when possible. Running in the foreground simplifies the configuration required.
- `-d`: Decrypt traffic from the source socket. This tells `spiped` the direction of encryption so that it knows to decrypt traffic from the source and encrypt traffic from the target.
- `-s`: This defines the source socket. IP addresses must be in square brackets followed by a colon and then the port. For the Redis server, this should be set to the public IP address and the Redis port.
- `-t`: The target socket. This is where traffic will be forwarded to after decrypting. Redis listens to port 6379 on the local host by default, so that is what we must use.
- `-k`: Specifies the key file to use. This should point to the encryption key we generated earlier.

All of these options will go in a single `ExecStart` directive, which is the only item we need in this section:

/etc/systemd/system/spiped-receive.service

    [Unit]
    Description=spiped receive for Redis
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/bin/spiped -F -d -s [redis_server_public_IP]:6379 -t [127.0.0.1]:6379 -k /etc/spiped/redis.key

Finally, we will include an `[Install]` section to tell systemd when to automatically start the unit if enabled:

/etc/systemd/system/spiped-receive.service

    [Unit]
    Description=spiped receive for Redis
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/bin/spiped -F -d -s [redis_server_public_IP]:6379 -t [127.0.0.1]:6379 -k /etc/spiped/redis.key
    
    [Install]
    WantedBy=multi-user.target

When you are finished, save and close the file.

## Start the spiped Service and Adjust the Firewall on the Redis Server

Start and enable the new `spiped` unit by typing:

    sudo systemctl start spiped-receive.service
    sudo systemctl enable spiped-receive.service

If you check the services listening for connections on your Redis server, you should see `spiped` listening on port 6379 on the public interface. You should also see Redis is listening to that same port on the local interface:

    sudo netstat -plunt

    Redis server outputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 public_IP:6379 0.0.0.0:* LISTEN 4292/spiped
    tcp 0 0 127.0.0.1:6379 0.0.0.0:* LISTEN 2679/redis-server 1
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1720/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1720/sshd

Although `spiped` is listening on the public interface, the firewall is likely not configured to let traffic through yet.

To allow all traffic to port 6379, type:

    sudo ufw allow 6379

This will open up access to port 6379 on your public interface where `spiped` is listening. The `spiped` port only accepts encrypted traffic.

## Transfer the Encryption Key to the Client

To transfer the encryption key to the client, we’ll need to establish a secure connection between our two servers. We will use `ssh` since this allows us to leverage our existing configuration.

If you are using key-based authentication, you will need to forward your SSH key to the Redis server to establish the connection. This is not necessary for password-based systems.

### Extra Steps for Key-Based Authentication

Disconnect from your Redis server:

    exit

Now, on your local machine, make sure that an SSH agent is running and that your private key has been added to it:

    eval `ssh-agent`
    ssh-add

Now, reconnect to your Redis server and add the `-A` flag to forward your keys:

    ssh -A sammy@redis_server_public_IP

You can now continue with the steps below.

### Transferring the Key

We will connect from the Redis server to the client because our key file requires local `sudo` privileges to access. We can now transfer the file, making sure to include the colon at the end of the command below:

    sudo -E scp /etc/spiped/redis.key sammy@redis_client_public_IP:

`scp` to write to your user’s home directory on the client machine.

After transferring the key, create the `/etc/spiped` directory on the client machine:

    sudo mkdir /etc/spiped

Move the encryption key into the new directory:

    sudo mv ~/redis.key /etc/spiped

Lock down the permissions to restrict access:

    sudo chmod 600 /etc/spiped/redis.key

Now that the client has a copy of the server’s encryption key, we can configure the client side of the `spiped` configuration.

## Create a systemd Unit File for Redis Clients

We will need to create a systemd unit file for `spiped` on the client side just as we did on the Redis server.

Open up a new systemd unit file by typing:

    sudo nano /etc/systemd/system/spiped-send.service

Inside, open a `[Unit]` section to describe the service and establish that it depends on networking availability:

/etc/systemd/system/spiped-send.service

    [Unit]
    Description=spiped sending for Redis
    Wants=network-online.target
    After=network-online.target

Next, open up a `[Service]` section to execute the `spiped` process. The options used here are very similar to those used on the Redis server, with the following differences:

- `-e`: Specifies that traffic entering the source socket will need to be encrypted. This establishes the relationship between the source and target sockets.
- `-s`: Defines the source socket, just as before. In this case however, the source is an arbitrary available port on the local interface where the local Redis client can connect to.
- `-t`: Defines the target socket, just as before. For the client this will be the remote Redis server’s public IP address and the port that was opened.

These will be set using the `ExecStart` directive again:

/etc/systemd/system/spiped-send.service

    [Unit]
    Description=spiped sending for Redis
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/bin/spiped -F -e -s [127.0.0.1]:8000 -t [redis_server_public_IP]:6379 -k /etc/spiped/redis.key

Finally, include an `[Install]` section to define when the unit will be started if enabled:

/etc/systemd/system/spiped-send.service

    [Unit]
    Description=spiped sending for Redis
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/bin/spiped -F -e -s [127.0.0.1]:8000 -t [redis_server_public_IP]:6379 -k /etc/spiped/redis.key
    
    [Install]
    WantedBy=multi-user.target

When you are finished, save and close the file.

## Start the spiped Service on the Client and Test the Connection

Now, we can start our `spiped` service on the client and enable it to start automatically at boot:

    sudo systemctl start spiped-send.service
    sudo systemctl enable spiped-send.service

Check that the tunnel on the client was set up properly:

    sudo netstat -plunt

    Redis client outputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 127.0.0.1:8000 0.0.0.0:* LISTEN 3264/spiped     
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1705/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1705/sshd

As you can see, `spiped` is listening on local port 8000 for connections.

Now, you should be able to connect to the remote Redis instance by pointing your client to port 8000 on your local interface:

    redis-cli -p 8000 ping

    Redis client outputPONG

Query for the test key that we set in the beginning of this guide:

    redis-cli -p 8000 get test

    Redis client output"success"

This confirms that we are able to reach the remote database successfully.

To confirm that we are _unable_ to communicate with the remote Redis server without using the tunnel, we can try to connect to the remote port directly:

    redis-cli -h redis_server_public_IP -p 6379 ping

    Redis client outputError: Protocol error, got "\xac" as reply type byte

As you can see, traffic is only accepted on the remote Redis port if it is correctly encrypted through the tunnel.

## Extending the Above Example for Multi-Client and Server-to-Server Communication

The example we outlined above used a simple example of a single Redis server and a single client. However, these same methods can be applied to more complex interactions.

Extending this example to handle multiple clients is straightforward. You would need to perform the following actions outlined above.

- Install the Redis client software and `spiped` package on the new client
- Transfer the encryption key to the new client
- Copy the `spiped` systemd unit file to the new client machine
- Start the `spiped` service and enable it to start at boot

To set up secure server-to-server communication (for instance, for replication or clustering), you would need to set up two parallel tunnels:

- On the new server, install the Redis server package and `spiped`
- Generate a new encryption key for the new Redis server (use a unique name for the file)
- Copy the encryption key from one server to the other into the `/etc/spiped` directory
- Create an `spiped` systemd unit file on each server (including existing servers) so that each server has a file serving each role:

- Open the external port in the firewall on the new Redis server

- Configure each Redis instance to connect to the locally mapped port to access the remote server by adjusting the Redis configuration file (the directives required are dependent on the relationship of the servers. See the Redis docs for more details).

If necessary, multiple client unit files can be configured on each machine to map local ports to remote servers. In these cases, be sure to choose a different unused local port in source socket specification in the sending unit file.

## Conclusion

Redis is a powerful and flexible tool that is invaluable for many deployments. However, operating Redis in an insecure environment is a huge liability that leaves your servers and data vulnerable to attack or theft. It is essential to secure traffic through other means if you do not have an isolated network populated only by trusted parties. The method outlined in this guide is just one way to secure communication between Redis parties. Other options include [tunneling with stunnel](how-to-encrypt-traffic-to-redis-with-stunnel-on-ubuntu-16-04) or [setting up a VPN](how-to-encrypt-traffic-to-redis-with-peervpn-on-ubuntu-16-04).
