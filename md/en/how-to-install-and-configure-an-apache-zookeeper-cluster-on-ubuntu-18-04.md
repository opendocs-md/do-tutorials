---
author: Shashank Tiwari
date: 2019-01-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-an-apache-zookeeper-cluster-on-ubuntu-18-04
---

# How To Install and Configure an Apache ZooKeeper Cluster on Ubuntu 18.04

_The author selected [Wikimedia Foundation Inc.](https://www.brightfunds.org/organizations/wikimedia-foundation-inc) to receive a donation as part of the [Write for DOnations](https://www.digitalocean.com/write-for-donations/) program._

## Introduction

[Apache ZooKeeper](https://zookeeper.apache.org/) is open-source software that enables resilient and highly reliable distributed coordination. It is commonly used in distributed systems to manage configuration information, naming services, distributed synchronization, quorum, and state. In addition, distributed systems rely on ZooKeeper to implement consensus, leader election, and group management.

In this guide, you will install and configure Apache ZooKeeper 3.4.13 on Ubuntu 18.04. To achieve resilience and high availability, ZooKeeper is intended to be replicated over a set of hosts, called an ensemble. First, you will create a standalone installation of a single-node ZooKeeper server and then add in details for setting up a multi-node cluster. The standalone installation is useful in development and testing environments, but a cluster is the most practical solution for production environments.

## Prerequisites

Before you begin this installation and configuration guide, you’ll need the following:

- The standalone installation needs one Ubuntu 18.04 server with a minimum of 4GB of RAM set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a non-root user with sudo privileges and a firewall. You need two additional servers, set up by following the same steps, for the multi-node cluster.
- OpenJDK 8 installed on your server, as ZooKeeper requires Java to run. To do this, follow the “Install Specific Versions of OpenJDK” step from the [How To Install Java with `apt` on Ubuntu 18.04](how-to-install-java-with-apt-on-ubuntu-18-04#installing-specific-versions-of-openjdk "Install Specific Versions of OpenJDK") guide.

Because ZooKeeper keeps data in memory to achieve high throughput and low latency, production systems work best with 8GB of RAM. Lower amounts of RAM may lead to JVM swapping, which could cause ZooKeeper server latency. High ZooKeeper server latency could result in issues like client session timeouts that would have an adverse impact on system functionality.

## Step 1 — Creating a User for ZooKeeper

A dedicated user should run services that handle requests over a network and consume resources. This practice creates segregation and control that will improve your environment’s security and manageability. In this step, you’ll create a non-root sudo user, named **zk** in this tutorial, to run the ZooKeeper service.

First, log in as the non-root sudo user that you created in the prerequisites.

    ssh sammy@your_server_ip

Create the user that will run the ZooKeeper service:

    sudo useradd zk -m

Passing the `-m` flag to the `useradd` command will create a home directory for this user. The home directory for **zk** will be `/home/zk` by default.

Set `bash` as the default shell for the **zk** user:

    sudo usermod --shell /bin/bash zk

Set a password for this user:

    sudo passwd zk

Next, you will add the **zk** user to the **sudo** group so it can run commands in a privileged mode:

    usermod -aG sudo zk

In terms of security, it is recommended that you allow SSH access to as few users as possible. Logging in remotely as **sammy** and then using `su` to switch to the desired user creates a level of separation between credentials for accessing the system and running processes. You will disable SSH access for both your **zk** and **root** user in this step.

Open your `sshd_config` file:

    sudo nano /etc/ssh/sshd_config

Locate the `PermitRootLogin` line and set the value to `no` to disable SSH access for the **root** user:

/etc/ssh/sshd\_config

    PermitRootLogin no

Under the `PermitRootLogin` value, add a `DenyUsers` line and set the value as any user who should have SSH access disabled:

/etc/ssh/sshd\_config

    DenyUsers zk

Save and exit the file and then restart the SSH daemon to activate the changes.

    sudo systemctl restart sshd

Switch to the **zk** user:

    su -l zk

The `-l` flag invokes a login shell after switching users. A login shell resets environment variables and provides a clean start for the user.

Enter the password at the prompt to authenticate the user.

Now that you have created, configured, and logged in as the **zk** user, you will create a directory to store your ZooKeeper data.

## Step 2 — Creating a Data Directory for ZooKeeper

ZooKeeper persists all configuration and state data to disk so it can survive a reboot. In this step, you will create a data directory that ZooKeeper will use to read and write data. You can create the data directory on the local filesystem or on a remote storage drive. This tutorial will focus on creating the data directory on your local filesystem.

Create a directory for ZooKeeper to use:

    sudo mkdir -p /data/zookeeper

Grant your **zk** user ownership to the directory:

    sudo chown zk:zk /data/zookeeper

`chown` changes the ownership and group of the `/data/zookeeper` directory so that the user **zk** , who belongs to the group **zk** , owns the data directory.

You have successfully created and configured the data directory. When you move on to configure ZooKeeper, you will specify this path as the data directory that ZooKeeper will use to store its files.

## Step 3 — Downloading and Extracting the ZooKeeper Binaries

In this step, you will manually download and extract the ZooKeeper binaries to the `/opt` directory. You can use the Advanced Packaging Tool, `apt`, to download ZooKeeper, but it may install an older version with different features. Installing ZooKeeper manually will give you full control to choose which version you would like to use.

Since you are downloading these files manually, start by changing to the `/opt` directory:

    cd /opt

From your local machine, navigate to the [Apache download page](https://www.apache.org/dyn/closer.cgi). This page will automatically provide you with the mirror closest to you for the fastest download. Click the link to the suggested mirror site, then scroll down and click **zookeeper/** to view the available releases. Select the version of ZooKeeper that you would like to install. This tutorial will focus on using 3.4.13. Once you select the version, right click the binary file ending with `.tar.gz` and copy the link address.

From your server, use the `wget` command along with the copied link to download the ZooKeeper binaries:

    sudo wget http://apache.osuosl.org/zookeeper/zookeeper-3.4.13/zookeeper-3.4.13.tar.gz

Extract the binaries from the compressed archive:

    sudo tar -xvf zookeeper-3.4.13.tar.gz

The `.tar.gz` extension represents a combination of TAR packaging followed by a GNU zip (gzip) compression. You will notice that you passed the flag `-xvf` to the command to extract the archive. The flag `x` stands for extract, `v` enables verbose mode to show the extraction progress, and `f` allows specifying the input, in our case `zookeeper-3.4.13.tar.gz`, as opposed to STDIN.

Next, give the **zk** user ownership of the extracted binaries so that it can run the executables. You can change ownership like so:

    sudo chown zk:zk -R zookeeper-3.4.13

Next, you will configure a symbolic link to ensure that your ZooKeeper directory will remain relevant across updates. You can also use symbolic links to shorten directory names, which can lessen the time it takes to set up your configuration files.

Create a symbolic link using the `ln` command.

    sudo ln -s zookeeper-3.4.13 zookeeper

Change the ownership of that link to `zk:zk`. Notice that you have passed a `-h` flag to change the ownership of the link itself. Not specifying `-h` changes the ownership of the target of the link, which you explicitly did in the previous step.

    sudo chown -h zk:zk zookeeper

With the symbolic links created, your directory paths in the configurations will remain relevant and unchanged through future upgrades. You can now configure ZooKeeper.

## Step 4 — Configuring ZooKeeper

Now that you’ve set up your environment, you are ready to configure ZooKeeper.

The configuration file will live in the `/opt/zookeeper/conf` directory. This directory contains a sample configuration file that comes with the ZooKeeper distribution. This sample file, named `zoo_sample.cfg`, contains the most common configuration parameter definitions and sample values for these parameters. Some of the common parameters are as follows:

- `tickTime`: Sets the length of a tick in milliseconds. A tick is a time unit used by ZooKeeper to measure the length between heartbeats. Minimum session timeouts are twice the tickTime.
- `dataDir`: Specifies the directory used to store snapshots of the in-memory database and the transaction log for updates. You could choose to specify a separate directory for transaction logs.
- `clientPort`: The port used to listen for client connections.
- `maxClientCnxns`: Limits the maximum number of client connections.

Create a configuration file named `zoo.cfg` at `/opt/zookeeper/conf`. You can create and open a file using `nano` or your favorite editor:

    nano /opt/zookeeper/conf/zoo.cfg

Add the following set of properties and values to that file:

/opt/zookeeper/conf/zoo.cfg

    tickTime=2000
    dataDir=/data/zookeeper
    clientPort=2181
    maxClientCnxns=60

A `tickTime` of 2000 milliseconds is the suggested interval between heartbeats. A shorter interval could lead to system overhead with limited benefits. The `dataDir` parameter points to the path defined by the symbolic link you created in the previous section. Conventionally, ZooKeeper uses port `2181` to listen for client connections. In most situations, 60 allowed client connections are plenty for development and testing.

Save the file and exit the editor.

You have configured ZooKeeper and are ready to start the server.

## Step 5 — Starting ZooKeeper and Testing the Standalone Installation

You’ve configured all the components needed to run ZooKeeper. In this step, you will start the ZooKeeper service and test your configuration by connecting to the service locally.

Navigate back to the `/opt/zookeeper` directory.

    cd /opt/zookeeper

Start ZooKeeper with the `zkServer.sh` command.

    bin/zkServer.sh start

You will see the following on your standard output:

    OutputZooKeeper JMX enabled by default
    Using config: /opt/zookeeper/bin/../conf/zoo.cfg
    Starting zookeeper ... STARTED

Connect to the local ZooKeeper server with the following command:

    bin/zkCli.sh -server 127.0.0.1:2181

You will get a prompt with the label `CONNECTED`. This confirms that you have a successful local, standalone ZooKeeper installation. If you encounter errors, you will want to verify that the configuration is correct.

    OutputConnecting to 127.0.0.1:2181
    ...
    ...
    [zk: 127.0.0.1:2181(CONNECTED) 0]

Type `help` on this prompt to get a list of commands that you can execute from the client. The output will be as follows:

    Output[zk: 127.0.0.1:2181(CONNECTED) 0] help
    ZooKeeper -server host:port cmd args
        stat path [watch]
        set path data [version]
        ls path [watch]
        delquota [-n|-b] path
        ls2 path [watch]
        setAcl path acl
        setquota -n|-b val path
        history
        redo cmdno
        printwatches on|off
        delete path [version]
        sync path
        listquota path
        rmr path
        get path [watch]
        create [-s] [-e] path data acl
        addauth scheme auth
        quit
        getAcl path
        close
        connect host:port

After you’ve done some testing, you will close the client session by typing `quit` on the prompt. The ZooKeeper service will continue running after you closed the client session. Shut down the ZooKeeper service, as you’ll configure it as a `systemd` service in the next step:

    bin/zkServer.sh stop

You have now installed, configured, and tested a standalone ZooKeeper service. This setup is useful to familiarize yourself with ZooKeeper, but is also helpful for developmental and testing environments. Now that you know the configuration works, you will configure `systemd` to simplify the management of your ZooKeeper service.

## Step 6 — Creating and Using a Systemd Unit File

The [`systemd`](https://github.com/systemd/systemd "systemd"), system and service manager, is an init system used to bootstrap the user space and to manage system processes after boot. You can create a daemon for starting and checking the status of ZooKeeper using `systemd`.

[Systemd Essentials](systemd-essentials-working-with-services-units-and-the-journal "Systemd Essentials") is a great introductory resource for learning more about `systemd` and its constituent components.

Use your editor to create a `.service` file named `zk.service` at `/etc/systemd/system/`.

    sudo nano /etc/systemd/system/zk.service

Add the following lines to the file to define the ZooKeeper Service:

/etc/systemd/system/zk.service

    [Unit]
    Description=Zookeeper Daemon
    Documentation=http://zookeeper.apache.org
    Requires=network.target
    After=network.target
    
    [Service]    
    Type=forking
    WorkingDirectory=/opt/zookeeper
    User=zk
    Group=zk
    ExecStart=/opt/zookeeper/bin/zkServer.sh start /opt/zookeeper/conf/zoo.cfg
    ExecStop=/opt/zookeeper/bin/zkServer.sh stop /opt/zookeeper/conf/zoo.cfg
    ExecReload=/opt/zookeeper/bin/zkServer.sh restart /opt/zookeeper/conf/zoo.cfg
    TimeoutSec=30
    Restart=on-failure
    
    [Install]
    WantedBy=default.target

The `Service` section in the unit file configuration specifies the working directory, the user under which the service would run, and the executable commands to start, stop, and restart the ZooKeeper service. For additional information on all the unit file configuration options, you can read the [Understanding Systemd Units and Unit Files](understanding-systemd-units-and-unit-files "Understanding Systemd Units and Unit Files") article.

Save the file and exit the editor.

Now that your `systemd` configuration is in place, you can start the service:

    sudo systemctl start zk

Once you’ve confirmed that your `systemd` file can successfully start the service, you will enable the service to start on boot.

    sudo systemctl enable zk

This output confirms the creation of the symbolic link:

    OutputCreated symlink /etc/systemd/system/multi-user.target.wants/zk.service → /etc/systemd/system/zk.service.

Check the status of the ZooKeeper service using:

    sudo systemctl status zk

Stop the ZooKeeper service using `systemctl`.

    sudo systemctl stop zk

Finally, to restart the daemon, use the following command:

    sudo systemctl restart zk

The `systemd` mechanism is becoming the init system of choice on many Linux distributions. Now that you’ve configured `systemd` to manage ZooKeeper, you can leverage this fast and flexible init model to start, stop, and restart the ZooKeeper service.

## Step 7 — Configuring a Multi-Node ZooKeeper Cluster

While the standalone ZooKeeper server is useful for development and testing, every production environment should have a replicated multi-node cluster.

Nodes in the ZooKeeper cluster that work together as an application form a _quorum_. Quorum refers to the minimum number of nodes that need to agree on a transaction before it’s committed. A quorum needs an odd number of nodes so that it can establish a majority. An even number of nodes may result in a tie, which would mean the nodes would not reach a majority or consensus.

In a production environment, you should run each ZooKeeper node on a separate host. This prevents service disruption due to host hardware failure or reboots. This is an important and necessary architectural consideration for building a resilient and highly available distributed system.

In this tutorial, you will install and configure three nodes in the quorum to demonstrate a multi-node setup. Before you configure a three-node cluster, you will spin up two additional servers with the same configuration as your standalone ZooKeeper installation. Ensure that the two additional nodes meet the prerequisites, and then follow steps one through six to set up a running ZooKeeper instance.

Once you’ve followed steps one through six for the new nodes, open `zoo.cfg` in the editor on each node.

    sudo nano /opt/zookeeper/conf/zoo.cfg

All nodes in a quorum will need the same configuration file. In your `zoo.cfg` file on each of the three nodes, add the additional configuration parameters and values for `initLimit`, `syncLimit`, and the servers in the quorum, at the end of the file.

/opt/zookeeper/conf/zoo.cfg

    tickTime=2000
    dataDir=/data/zookeeper
    clientPort=2181
    maxClientCnxns=60
    initLimit=10
    syncLimit=5
    server.1=your_zookeeper_node_1:2888:3888
    server.2=your_zookeeper_node_2:2888:3888
    server.3=your_zookeeper_node_3:2888:3888

`initLimit` specifies the time that the initial synchronization phase can take. This is the time within which each of the nodes in the quorum needs to connect to the leader. `syncLimit` specifies the time that can pass between sending a request and receiving an acknowledgment. This is the maximum time nodes can be out of sync from the leader. ZooKeeper nodes use a pair of ports, `:2888` and `:3888`, for follower nodes to connect to the leader node and for leader election, respectively.

Once you’ve updated the file on each node, you will save and exit the editor.

To complete your multi-node configuration, you will specify a node ID on each of the servers. To do this, you will create a `myid` file on each node. Each file will contain a number that correlates to the server number assigned in the configuration file.

On **your\_zookeeper\_node\_1** , create the `myid` file that will specify the node ID:

    sudo nano /data/zookeeper/myid

Since **your\_zookeeper\_node\_1** is identified as `server.1`, you will enter `1` to define the node ID. After adding the value, your file will look like this:

    your_zookeeper_node_1 /data/zookeeper/myid1

Follow the same steps for the remaining nodes. The `myid` file on each node should be as follows:

    your_zookeeper_node_1 /data/zookeeper/myid1

    your_zookeeper_node_2 /data/zookeeper/myid2

    your_zookeeper_node_3 /data/zookeeper/myid3

You have now configured a three-node ZooKeeper cluster. Next, you will run the cluster and test your installation.

## Step 8 — Running and Testing the Multi-Node Installation

With each node configured to work as a cluster, you are ready to start a quorum. In this step, you will start the quorum on each node and then test your cluster by creating sample data in ZooKeeper.

To start a quorum node, first change to the `/opt/zookeeper` directory on each node:

    cd /opt/zookeeper

Start each node with the following command:

    java -cp zookeeper-3.4.13.jar:lib/log4j-1.2.17.jar:lib/slf4j-log4j12-1.7.25.jar:lib/slf4j-api-1.7.25.jar:conf org.apache.zookeeper.server.quorum.QuorumPeerMain conf/zoo.cfg

As nodes start up, you will intermittently see some connection errors followed by a stage where they join the quorum and elect a leader among themselves. After a few seconds of initialization, you can start testing your installation.

Log in via SSH to **your\_zookeeper\_node\_3** as the non-root user you configured in the prerequisites:

    ssh sammy@your_zookeeper_node_3

Once logged in, switch to your **zk** user:

    your_zookeeper_node_3 /data/zookeeper/myidsu -l zk

Enter the password for the **zk** user. Once logged in, change the directory to `/opt/zookeeper`:

    your_zookeeper_node_3 /data/zookeeper/myidcd /opt/zookeeper

You will now start a ZooKeeper command line client and connect to ZooKeeper on **your\_zookeeper\_node\_1** :

    your_zookeeper_node_3 /data/zookeeper/myidbin/zkCli.sh -server your_zookeeper_node_1:2181

In the standalone installation, both the client and server were running on the same host. This allowed you to establish a client connection with the ZooKeeper server using `localhost`. Since the client and server are running on different nodes in your multi-node cluster, in the previous step you needed to specify the IP address of **your\_zookeeper\_node\_1** to connect to it.

You will see the familiar prompt with the `CONNECTED` label, similar to what you saw in Step 5.

Next, you will create, list, and then delete a _znode_. The znodes are the fundamental abstractions in ZooKeeper that are analogous to files and directories on a file system. ZooKeeper maintains its data in a hierarchical namespace, and znodes are the data registers of this namespace.

Testing that you can successfully create, list, and then delete a znode is essential to establishing that your ZooKeeper cluster is installed and configured correctly.

Create a znode named `zk_znode_1` and associate the string `sample_data` with it.

    create /zk_znode_1 sample_data

You will see the following output once created:

    OutputCreated /zk_znode_1

List the newly created znode:

    ls /

Get the data associated with it:

    get /zk_znode_1

ZooKeeper will respond like so:

    Output[zk: your_zookeeper_node_1:2181(CONNECTED)] ls /
    [zk_znode_1, zookeeper]
    [zk: your_zookeeper_node_1:2181(CONNECTED)] get /zk_znode_1
    sample_data
    cZxid = 0x100000002
    ctime = Tue Nov 06 19:47:41 UTC 2018
    mZxid = 0x100000002
    mtime = Tue Nov 06 19:47:41 UTC 2018
    pZxid = 0x100000002
    cversion = 0
    dataVersion = 0
    aclVersion = 0
    ephemeralOwner = 0x0
    dataLength = 11
    numChildren = 0

The output confirms the value, `sample_data`, that you associated with `zk_node_1`. ZooKeeper also provides additional information about creation time, `ctime`, and modification time, `mtime`. ZooKeeper is a versioned data store, so it also presents you with metadata about the data version.

Delete the `zk_znode_1` znode:

    delete /zk_znode_1

In this step, you successfully tested connectivity between two of your ZooKeeper nodes. You also learned basic znode management by creating, listing, and deleting znodes. Your multi-node configuration is complete, and you are ready to start using ZooKeeper.

## Conclusion

In this tutorial, you configured and tested both a standalone and multi-node ZooKeeper environment. Now that your multi-node ZooKeeper deployment is ready to use, you can review the [official ZooKeeper documentation](http://zookeeper.apache.org/doc/r3.4.13/ "ZooKeeper 3.4.13 Documentation") for additional information and projects.
