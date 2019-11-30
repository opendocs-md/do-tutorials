---
author: Justin Ellingwood
date: 2016-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-traffic-to-redis-with-peervpn-on-ubuntu-16-04
---

# How To Encrypt Traffic to Redis with PeerVPN on Ubuntu 16.04

## Introduction

Redis is an open-source key-value data store, using an in-memory storage model with optional disk writes for persistence. It features transactions, a pub/sub messaging pattern, and automatic failover among other functionality. Redis has clients written in most languages with recommended ones featured on [their website](http://redis.io/clients).

Redis does not provide any encryption capabilities of its own. It operates under the assumption that it has been deployed to an isolated private network, accessible only to trusted parties. If your environment does not match that assumption, you will have to wrap Redis traffic in encryption separately.

In this guide, we will demonstrate how to encrypt Redis traffic by routing it through a simple VPN program called PeerVPN. All traffic between the servers can be routed through the VPN securely. Unlike some solutions, this provides a flexible solution for general server-to-server communication that is not bound to a specific port or service. However, for the purposes of this guide, we will focus on configuring PeerVPN in order to secure Redis traffic. We will be using two Ubuntu 16.04 servers to demonstrate.

## Prerequisites

To get started, you should have a non-root user with `sudo` privileges configured on each of your machines. Additionally, this guide will assume that you have a basic firewall in place. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to fulfill these requirements.

When you are ready to continue, follow along below.

## What is PeerVPN?

PeerVPN is an incredibly simple VPN technology that establishes a mesh topology. This means that there is no central server that must always be available to arbitrate communication between nodes. This is ideal for situations where you wish to establish a trusted environment between parties without reconfiguring anything on existing hosts. All traffic between nodes can be encrypted through the VPN, and both services and the firewall can be configured to accept traffic only on the VPN interface.

Some advantages of using PeerVPN are:

- Simple and intuitive configuration. Unlike many VPNs, PeerVPN can be set up with very little work and it does not require a central server.
- A general purpose solution for encrypted network communication. Unlike some tunneling options, a VPN provides a secure network for _any_ traffic. Encrypted communication only has to be configured once and is usable by all services.
- Only a single connection is needed for server-to-server communication. Unlike tunneling solutions, only one configuration is needed for two Redis servers to communicate.

Some disadvantages are:

- Ubuntu does not currently have a package for PeerVPN in the default repositories.
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

We have set the **test** key to the value `success`. We will try to access this key from our client machine after configuring PeerVPN.

### Installing the Redis Client

The other Ubuntu 16.04 machine will function as the client. All of the software we need is available in the `redis-tools` package in the default repository:

    sudo apt-get update
    sudo apt-get install redis-tools

With the default configuration of the remote Redis server and a firewall active, we can’t currently connect to the remote Redis instance to test.

## Install PeerVPN On Each Computer

Next, you will need to install PeerVPN on each of the servers and clients. As mentioned above, Ubuntu does not currently include PeerVPN packages in its repositories.

Fortunately, the [project’s website](https://peervpn.net/) includes a compiled binary for Linux under the **Download** section. Right-click and copy the link for the statically linked Linux binary on that page to ensure you have the most recent version.

On each of your machines, move into the `/tmp` directory and then use `curl` to download the link you copied:

    cd /tmp
    curl -LO https://peervpn.net/files/peervpn-0-044-linux-x86.tar.gz

Extract the downloaded tarball by typing:

    tar xzvf peervpn*

Copy the binary into the `/usr/local/bin` directory and the example configuration file into the `/etc` directory:

    sudo cp /tmp/peervpn*/peervpn /usr/local/bin
    sudo cp /tmp/peervpn*/peervpn.conf /etc

PeerVPN is now installed on the system and ready to use.

## Configure the PeerVPN Network

With the executable and configuration file in their proper place, we can configure PeerVPN on each of our machines.

### Generating a Secure Secret Key

PeerVPN uses a shared secret of up to 512 characters to authenticate legitimate machines to the network. It is important to use strong values to protect the integrity of your network traffic. Since this is a shared secret, we only need to produce one value for our network (we will use the Redis server machine to do this, but it doesn’t matter which you choose).

One easy way to generate a strong secret of the maximum length is with OpenSSL. Check that it is producing output at or below 512 characters with `wc` (you can adjust the 382 in this command to affect output length):

    openssl rand -base64 382 | tr -d '\n' | wc

    Redis server output 0 1 512

If the length is correct, remove the `wc` to generate a high entropy secret. We will add an `echo` at the end to put in a final new line:

    openssl rand -base64 382 | tr -d '\n' && echo

You should see something like this **(do not copy the below value!)**:

    Redis server outputajHpYYMJYtv+m0K6yZbYmk8npPujlcv9QDozQZ06ucV2gsHoMGqyfd50X8OnY6hicj5iFNjDN/9QVTB3nhMOV2ufU/kfWCbtskUuk1zHWYZsvy71KnLRhA8W8dnu+NEKdIh28H2qUsiay7On5kOZPcrONvv/pHHYbxmFI2G9TyYT+CZWIAxUV/vUWl41VycjASmZYaSI6lWgYONopncNfDF5Z6oznPH8ge6sQsszbe1ZjNqLRUrx/jgL3fy7SXSLCIrsSuifBv/pb36d9/y+YPZEbxsMInoK5QEWrpIf/xjbMFlndtGc20olhh05h66qz/GiimLMivrN8g+PibVaBRUmWav/pngUvKYsEEPSc0wrr5ZuvpvBGTTKqPdR+soCnd/iWPzmwRBW56vBGxed3GNbkgmjDpTSnvNEN+gKPt07drHSbGqfFbdMdsKbjE+IWiqiVO1aviJsNpMhBO/o9uIcKxPmuze6loZKTh7/qjJuY62E//SsgFzDHDhP2w==

Copy your generated output so that you can use it in your PeerVPN configuration.

### Defining the PeerVPN Configuration

To configure PeerVPN, open the `/etc/peervpn.conf` file on each server:

    sudo nano /etc/peervpn.conf

Inside, you will find comments describing each of the configuration options. Feel free to read these to get familiar with the available settings. Our configuration will be very simple. You can either add the configuration lines to the top of the file or find, uncomment, and define the appropriate lines in the comments throughout the file.

Start by setting `networkname` and `psk`, both of which must be the same on each of the machines in your VPN. The network name is an arbitrary identifier for this particular network, while the `psk` is the shared secret referred to earlier:

/etc/peervpn.conf

    networkname RedisNet
    psk your_generated_secret

Next, explicitly set the `port` that PeerVPN can use to connect to peers so that we can adjust our firewall easily (we’ll use 7000 in this guide). Set `enabletunneling` so that this machine is an active part of the network. Set a name for the network `interface` that will show up in tools like `ip` and `ifconfig`.

/etc/peervpn.conf

    networkname RedisNet
    psk your_generated_secret
    
    port 7000
    enabletunneling yes
    interface peervpn0

You will need to select a VPN network size and assign a unique VPN IP address to each server using the `ifconfig4` directive. This is done using [CIDR notation](understanding-ip-addresses-subnets-and-cidr-notation-for-networking). We will define the VPN network as 10.8.0.0/24. This will give us 254 potential addresses (much more than we need), all beginning with 10.8.0. Since each address must be unique, we will use:

- **10.8.0.1/24** for our Redis server
- **10.8.0.2/24** for our client server

Finally, use `initpeers` to specify other servers that will be in the network. Since PeerVPN does not use a centralized management server, these hosts will be contacted during initialization in order to join the VPN network. After connecting, the server will receive information about any additional peers on the network automatically.

Peer should be specified using their public IP address ( **not** the VPN IP address assigned within the PeerVPN config) and the PeerVPN listening port. Additional peers can be specified on the same line, also separated by a space (look at the comments in the file for examples):

/etc/peervpn.conf

    networkname RedisNet<^>
    psk your_generated_secret
    
    port 7000
    enabletunneling yes
    interface peervpn0
    
    # Increment the IP address below for each additional server
    # For example, the second node on the network could be 10.8.0.2/24
    ifconfig4 10.8.0.1/24
    initpeers other_server_public_IP 7000

Save and close the file when you are finished. Both of your machines should have very similar configuration files, varying only in the `ifconfig4` and `initpeers` values.

## Create a systemd Unit File for PeerVPN

In order to manage PeerVPN as a service and start our network on boot, we will create a systemd unit file. Open a new unit file in the `/etc/systemd/system` directory on each machine to get started:

    sudo nano /etc/systemd/system/peervpn.service

Inside, create a `[Unit]` section to describe the unit and establish ordering so that this unit is started after networking is available:

/etc/systemd/system/peervpn.service

    [Unit]
    Description=PeerVPN network service
    Wants=network-online.target
    After=network-online.target

Next, open a `[Service]` section to define the actual command to run. Here, we just need to use `ExecStart` to call the `peervpn` binary and point it at the configuration file we created:

/etc/systemd/system/peervpn.service

    [Unit]
    Description=PeerVPN network service
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/local/bin/peervpn /etc/peervpn.conf

Finally, we will include an `[Install]` section to tell systemd when to automatically start the unit if enabled:

/etc/systemd/system/peervpn.service

    [Unit]
    Description=PeerVPN network service
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    ExecStart=/usr/local/bin/peervpn /etc/peervpn.conf
    
    [Install]
    WantedBy=multi-user.target

When you are finished, save and close the file.

## Start the PeerVPN Service and Adjust the Firewall

Start and enable the new `peervpn` unit on both machines by typing:

    sudo systemctl start peervpn.service
    sudo systemctl enable peervpn.service

If you check the services listening for connections on your servers, you should see PeerVPN listening on port 7000 for both IPv4 and IPv6 interfaces (if available):

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 127.0.0.1:6379 0.0.0.0:* LISTEN 2662/redis-server 1
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1724/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1724/sshd       
    udp 0 0 0.0.0.0:7000 0.0.0.0:* 4609/peervpn    
    udp6 0 0 :::7000 :::* 4609/peervpn

Although PeerVPN is listening on the public interface, the firewall is likely not configured to let traffic through yet. We need to allow traffic to port 7000 where PeerVPN is listening for connections, as well as traffic from the 10.8.0.0/24 network itself:

    sudo ufw allow 7000
    sudo ufw allow from 10.8.0.0/24

This will open up access to port 7000 on your public interface where PeerVPN is listening. It will also allow traffic to flow freely from the VPN.

Check whether you can reach your other server using the VPN IP address. For instance, from your Redis server you could type:

    ping 10.8.0.2

You should be able to connect without issue.

## Adjust the Redis Server Settings

Now, that the VPN is set up, we need to adjust the interfaces that Redis is listening to. By default, Redis binds only to the local interface.

Open the Redis configuration file on the Redis server:

    sudo nano /etc/redis/redis.conf

Inside, search for the `bind` directive, which should currently be set to 127.0.0.1. Append the Redis server’s VPN IP address to the end:

/etc/redis/redis.conf

    . . .
    bind 127.0.0.1 10.8.0.1
    . . .

Save and close the file when you are finished.

Now, restart the Redis service by typing:

    sudo systemctl restart redis-server.service

The Redis service should now be available for connections from VPN peers. You can verify this by re-checking the listening ports:

    sudo netstat -plunt

    Redis server outputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 10.8.0.1:6379 0.0.0.0:* LISTEN 4767/redis-server 1
    tcp 0 0 127.0.0.1:6379 0.0.0.0:* LISTEN 4767/redis-server 1
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1724/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1724/sshd       
    udp 0 0 0.0.0.0:7000 0.0.0.0:* 4609/peervpn    
    udp6 0 0 :::7000 :::* 4609/peervpn

You can see in the top line in this example that Redis is now listening to the VPN interface.

## Test Connections from the Redis Client

With the VPN running and Redis listening on the VPN network, we can test to make sure that our Redis client machine can access the Redis server.

To do so, point your client at the Redis server’s VPN IP address using the `-h` option:

    redis-cli -h 10.8.0.1 ping

    Redis client outputPONG

Query for the test key that we set in the beginning of this guide:

    redis-cli -h 10.8.0.1 get test

    Redis client output"success"

This confirms that we are able to reach the remote database successfully.

## Extending the Above Example for Multi-Client and Server-to-Server Communication

The example we outlined above used a simple example of a single Redis server and a single client. However, this can be easily expanded to accommodate more complex interactions.

Since PeerVPN uses a mesh network, adding additional clients or servers is simple. The new peer should complete the following steps:

- Install PeerVPN by downloading the tarball and then extracting and distributing the files
- Copy the PeerVPN configuration from the other servers and adjusting these directives:

- Copy the PeerVPN systemd unit file to the new client machine

- Start the PeerVPN service and enable it to start at boot

- Open the external port and VPN network in the firewall

- (Only for Redis servers) Adjust the Redis configuration to bind to the new VPN interface

## Conclusion

Redis is a powerful and flexible tool that is invaluable for many deployments. However, operating Redis in an insecure environment is a huge liability that leaves your servers and data vulnerable to attack or theft. It is essential to secure traffic through other means if you do not have an isolated network populated only by trusted parties. The method outlined in this guide is just one way to secure communication between Redis parties. Other options include configuring an encrypted tunnel with [stunnel](how-to-encrypt-traffic-to-redis-with-stunnel-on-ubuntu-16-04) or [spiped](how-to-encrypt-traffic-to-redis-with-spiped-on-ubuntu-16-04).
