---
author: Justin Ellingwood
date: 2016-11-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-traffic-to-redis-with-stunnel-on-ubuntu-16-04
---

# How To Encrypt Traffic to Redis with Stunnel on Ubuntu 16.04

## Introduction

Redis is an open-source key-value data store, using an in-memory storage model with optional disk writes for persistence. It features transactions, a pub/sub messaging pattern, and automatic failover among other functionality. Redis has clients written in most languages with recommended ones featured on [their website](http://redis.io/clients).

Redis does not provide any encryption capabilities of its own. It operates under the assumption that it has been deployed to an isolated private network, accessible only to trusted parties. If your environment does not match that assumption, you will have to wrap Redis traffic in encryption separately.

In this guide, we will demonstrate how to encrypt Redis traffic using a secure tunneling program called `stunnel`. Traffic between Redis clients and servers will be routed through a dedicated SSL encrypted tunnel. We will be using two Ubuntu 16.04 servers to demonstrate.

## Prerequisites

To get started, you should have a non-root user with `sudo` privileges configured on each of your machines. Additionally, this guide will assume that you have a basic firewall in place. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to fulfill these requirements.

When you are ready to continue, follow along below.

## What is stunnel?

For basic encrypted communication, the `stunnel` utility is simple to install and configure. It enables encrypted forwarding between two machines. The client connects to a local port and `stunnel` wraps it in encryption before forwarding it to the remote server. On the server side, `stunnel` listens on the configured port and decrypts traffic before forwarding it to a local port (in our case, the port that the Redis server listens on).

Some advantages of using `stunnel` are:

- Ubuntu maintains packages for `stunnel` in its default repositories
- Ubuntu includes an init script to automatically start the process at boot
- Configuration is straight-forward and intuitive
- A new tunnel is used for each purpose. This might be a disadvantage in some situations, but it provides granular control over access.

Some disadvantages are:

- Clients connect to the remote machine by attaching to a non-default local port, which may be unintuitive at first.
- If connecting two Redis servers for replication or clustering, two tunnels must be configured on each machine for server-to-server communication (one for outbound and one for inbound traffic).

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

We have set the **test** key to the value `success`. We will try to access this key from our client machine after configuring `stunnel`.

### Installing the Redis Client

The other Ubuntu 16.04 machine will function as the client. All of the software we need is available in the `redis-tools` package in the default repository:

    sudo apt-get update
    sudo apt-get install redis-tools

With the default configuration of the remote Redis server and a firewall active, we can’t currently connect to the remote Redis instance to test.

## Install and Enable stunnel On Each Computer

Next, you will need to install `stunnel` on each of the servers and clients. Ubuntu includes version four of the utility, called `stunnel4` in its default repositories. If you did not need to install anything in the previous section, make sure to include the `sudo apt-get update` command to refresh your package index before installing:

    # sudo apt-get update
    sudo apt-get install stunnel4

The `stunnel` service on Ubuntu uses an older SysVinit script for startup, which can be managed by systemd. Rather than using native systemd methods, to configure the service to start at boot you must modify the `/etc/default/stunnel4` file:

    sudo nano /etc/default/stunnel4

Enable the service to start at boot by setting the `ENABLED` option to “1”:

/etc/default/stunnel4

    . . .
    ENABLED=1
    . . .

Save and close the file on each server.

Next, we’ll create a self-signed SSL certificate and key that will be used to encrypt communication.

## Create a Self-Signed SSL Certificate and Key on the Redis Server

On your Redis server, create a self-signed SSL certificate and key in the `/etc/stunnel` directory. This will be used to encrypt the connection between the two instances of `stunnel`. We will use the name `redis-server` to refer to the certificate and key files:

    sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/stunnel/redis-server.key -out /etc/stunnel/redis-server.crt

You will be prompted for information about the certificate you are creating. Since this will only be used internally, the values don’t matter too much, so fill in whatever you’d like. You can see an example below:

    Redis server output. . .
    -----
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York City
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
    Organizational Unit Name (eg, section) []:Community
    Common Name (e.g. server FQDN or YOUR name) []:redis-server
    Email Address []:admin@example.com

Restrict access to the generated `.key` file by typing:

    sudo chmod 600 /etc/stunnel/redis-server.key

Now that we have an SSL certificate and key, we can create our Redis server’s `stunnel` configuration file.

## Create the Redis Server stunnel Configuration File

Open a file ending in `.conf` within the `/etc/stunnel` directory on the Redis server to get started:

    sudo nano /etc/stunnel/redis.conf

Inside, specify a location to write the PID file in the main section. The `/run` directory is designed to store these types of files, so we will use that:

/etc/stunnel/redis.conf

    pid = /run/stunnel-redis.pid

Next, create a section to configure access to the Redis service. You can call this whatever you’d like (we will call it `redis-server`). The section separates this configuration from any other tunnels you may need to configure on this machine at a later date.

We need to specify the locations of the Redis server’s own certificate and key using the `cert` and `key` directives respectively.

We will also define the tunnel for incoming data here. We want to `accept` encrypted traffic to the default Redis port (port 6379) on the Redis server’s external IP address. We then want to `connect` that traffic to the default Redis port on the _local_ interface to deposit the decrypted traffic. This is where the Redis service is actually listening:

/etc/stunnel/redis.conf

    pid = /run/stunnel-redis.pid
    
    [redis-server]
    cert = /etc/stunnel/redis-server.crt
    key = /etc/stunnel/redis-server.key
    accept = redis_servers_public_IP:6379
    connect = 127.0.0.1:6379

When you are finished, save and close the file.

## Restart stunnel and Configure the Firewall

Now that `stunnel` is configured on the Redis server, we can restart the service by typing:

    sudo systemctl restart stunnel4.service

If you check the services listening for connections on your Redis server, you should see `stunnel` listening on port 6379 on the public interface. You should also see Redis is listening to that same port on the local interface:

    sudo netstat -plunt

    Redis server outputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 public_IP:6379 0.0.0.0:* LISTEN 4292/stunnel4   
    tcp 0 0 127.0.0.1:6379 0.0.0.0:* LISTEN 2679/redis-server 1
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1720/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1720/sshd

Although `stunnel` is listening on the public interface, the firewall is likely not configured to let traffic through yet.

To allow all traffic to port 6379, type:

    sudo ufw allow 6379

This will open up access to port 6379 on your public interface where `stunnel` is listening. The `stunnel` port only accepts encrypted traffic.

## Distribute the Certificate to the Client

Each Redis client will need a copy of the Redis server’s certificate file. The easiest way to distribute the `.crt` files is to simply output the contents of the file on the server and then copy the contents to a corresponding file on the connecting machines.

Output the contents of the `.crt` file on your Redis server by typing:

    cat /etc/stunnel/redis-server.crt

    Redis server output-----BEGIN CERTIFICATE-----
    MIIEGTCCAwGgAwIBAgIJALUdz8P8q8UPMA0GCSqGSIb3DQEBCwUAMIGiMQswCQYD
    VQQGEwJVUzERMA8GA1UECAwITmV3IFlvcmsxFjAUBgNVBAcMDU5ldyBZb3JrIENp
    
    . . .
    
    Tq7WJk77tk4nPI8iGv1WuK8xTAm5aOncxP16VoMpsDMV+GB1p3nBkMQ/GKF8pPXU
    fn6BnDWKmeZqAlBM+MGYAfkbZWdBslrWasCJzs+tehTqL0LLJ6d3Gi9biBPb
    -----END CERTIFICATE-----

Copy the displayed certificate, **including the lines marked BEGIN CERTIFICATE and END CERTIFICATE** to your clipboard.

On the client machine, open a file with the same name in the `/etc/stunnel` directory:

    sudo nano /etc/stunnel/redis-server.crt

Paste the content you copied from the Redis server. Save and close the file when you are finished.

## Create the Redis Client stunnel Configuration File

Now that the client has a copy of the server’s certificate, we can configure the client side of the `stunnel` configuration.

Open a file ending in `.conf` in the `/etc/stunnel` directory on the client machine. We’ll call the file `redis.conf` again:

    sudo nano /etc/stunnel/redis.conf

Inside, specifying a PID file where the service will store its process ID again:

/etc/stunnel/redis.conf

    pid = /run/stunnel-redis.pid

Next, add a section to configure the tunnel for outbound data. You can name this whatever you’d like (we will call it `redis-client`). The section separates this configuration from any other tunnels you may need to configure on this machine at a later date.

We need to explicitly mark this section as a client configuration using the `client` directive. Set the `accept` directive to listen on an unused port on the local interface to handle connections from your local Redis client (we will use port 8000 in this example). Set the `connect` directive to the Redis server’s public IP address and the port we opened.

Then use `CAfile` to point to the copy of the Redis server’s certificate. We must also set `verify` to 4, which makes `stunnel` only check the certificate without regard to a certificate chain (since we self-signed our certificate):

/etc/stunnel/redis.conf

    pid = /run/stunnel-redis.pid
    
    [redis-client]
    client = yes
    accept = 127.0.0.1:8000
    connect = remote_server_IP_address:6379
    CAfile = /etc/stunnel/redis-server.crt
    verify = 4

Save and close the file when you are finished.

## Restarting the Client Service and Testing the Connection

Restart the `stunnel` service on the client to implement the changes:

    sudo systemctl restart stunnel4.service

Check that the tunnel on the client was set up properly:

    sudo netstat -plunt

    Redis client outputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 127.0.0.1:8000 0.0.0.0:* LISTEN 3809/stunnel4   
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1714/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1714/sshd

As you can see, `stunnel` is listening on local port 8000 for connections.

Now, you should be able to connect to the remote Redis instance by pointing your client to port 8000 on your local interface:

    redis-cli -p 8000 ping

    Redis client outputPONG

Query for the test key that we set in the beginning of this guide:

    redis-cli -p 8000 get test

    Redis client output"success"

This confirms that we are able to reach the remote database successfully.

To confirm that we are _unable_ to communicate with the remote Redis server without using the tunnel, we can try to connect to the remote port directly:

    redis-cli -h redis_server_public_IP -p 6379 ping

    Redis client outputError: Connection reset by peer

As you can see, traffic is only accepted on the remote Redis port if it is correctly encrypted through the tunnel.

## Extending the Above Example for Multi-Client and Server-to-Server Communication

The example we outlined above used a simple example of a single Redis server and a single client. However, these same methods can be applied to more complex interactions.

Extending this example to handle multiple clients is straightforward. You would need to perform the following actions outlined above.

- Install the Redis client software and `stunnel` package on the new client
- Enable the `stunnel` software to start at boot
- Copy the server’s certificate file to the `/etc/stunnel` directory
- Copy the `stunnel` client configuration file to the new client machine
- Restart the `stunnel` service

To set up secure server-to-server communication (for instance, for replication or clustering), you would need to set up two parallel tunnels:

- On the new server, install the Redis server package and `stunnel`
- Enable the `stunnel` software to start at boot
- Generate a new certificate and key file for the new Redis server (use a unique name for the files)
- Copy each of the certificate files from one server to the other into the `/etc/stunnel` directory
- Edit or create the `stunnel` configuration file on each server (including existing servers) so that it contains:
  - A server section mapping an external port to the local Redis
  - A client section mapping a local port to the remote server’s exposed port
- Open the external port in the firewall on the new Redis server
- Configure each Redis instance to connect to the locally mapped port to access the remote server by adjusting the Redis configuration file (the directives required are dependent on the relationship of the servers. See the Redis docs for more details).

The `stunnel` configuration files for both servers would look something like this:

stunnel configuration file for server-to-server communication

    pid = /run/stunnel-redis.pid
    
    [redis-server]
    cert = /etc/stunnel/this_servers_certificate.crt
    key = /etc/stunnel/this_servers_key.key
    accept = this_servers_public_IP:6379
    connect = 127.0.0.1:6379
    
    [redis-client]
    client = yes
    accept = 127.0.0.1:arbitrary_local_port
    connect = remote_servers_public_IP:6379
    CAfile = /etc/stunnel/remote_servers_certificate.crt
    verify = 4

If necessary, multiple client sections can be configured on each machine to map local ports to remote servers. In these cases, be sure to choose a different unused local port with the `accept` directive for each remote server.

## Conclusion

Redis is a powerful and flexible tool that is invaluable for many deployments. However, operating Redis in an insecure environment is a huge liability that leaves your servers and data vulnerable to attack or theft. It is essential to secure traffic through other means if you do not have an isolated network populated only by trusted parties. The method outlined in this guide is just one way to secure communication between Redis parties. Other options include [tunneling with spiped](how-to-encrypt-traffic-to-redis-with-spiped-on-ubuntu-16-04) or [setting up a VPN](how-to-encrypt-traffic-to-redis-with-peervpn-on-ubuntu-16-04).
