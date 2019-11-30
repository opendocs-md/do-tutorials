---
author: Melissa Anderson
date: 2016-09-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-a-galera-cluster-with-mysql-5-6-on-ubuntu-16-04
---

# How To Configure a Galera Cluster with MySQL 5.6 on Ubuntu 16.04

## Introduction

Clustering adds high availability to your database by distributing changes across different servers. In the event that one of the instances fails, others are already available to continue serving.

Clusters come in two general configurations, active-passive and active-active. In active-passive clusters, all writes are done on a single active server and then copied to one or more passive servers that are poised to take over only in the event of an active server failure. Some active-passive clusters also allow `SELECT` operations on passive nodes. In an active-active cluster, every node is read-write and a change made to one is replicated to all.

In this guide, we will configure an active-active MySQL Galera cluster. For demonstration purposes, we will configure and test three nodes, the smallest configurable cluster.

## Prerequisites

To follow along, you will need three Ubuntu 16.04 servers, each with:

- **a minimum of 1GB of RAM**. Provisioning enough memory for your data set is essential [to prevent performance degradation and crashes](http://galeracluster.com/documentation-webpages/configuration.html). Memory usage for clusters is difficult to predict, so be sure to allow plenty.
- **a non-root user with `sudo` privileges**. This can be configured by following our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide.
- **a simple firewall enabled**. Follow the last step of our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide to configure this with `ufw`.
- **private networking** , if it’s available to you. Configure this by following our guide on [How to Set Up and Use DigitalOcean Private Networking](how-to-set-up-and-use-digitalocean-private-networking).

Once all of these prerequisites are in place, we’re ready to install the software.

## Step 1 — Adding the Galera Repository to All Servers

MySQL, patched to include Galera clustering, isn’t included in the default Ubuntu repositories, so we’ll start by adding the external Ubuntu repositories maintained by the Galera project to all three of our servers.

**Note:** Codership, the company behind Galera Cluster, maintains this repository, but be aware that not all external repositories are reliable. Be sure to install only from trusted sources.

On each server, add the repository key with the `apt-key` command, which `apt` will use to verify that the packages are authentic.

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA

Once we have the trusted key in each server’s database, we can add the repositories. To do so, create a new file called `galera.list` within the `/etc/apt/sources.list.d/` on each server:

    sudo nano /etc/apt/sources.list.d/galera.list

In the text editor, add the following lines which will make the appropriate repositories available to the APT package manager:

/etc/apt/sources.list.d/galera.list

    deb http://releases.galeracluster.com/mysql-wsrep-5.6/ubuntu xenial main
    deb http://releases.galeracluster.com/galera-3/ubuntu xenial main

Save and close the file (press `CTRL + X`, `Y`, then `ENTER`).

The Codership repositories are now available to all three of your servers. However, it’s important that you instruct `apt` to prefer Codership’s repositories over others to ensure that it installs the patched versions of the software needed to create a Galera cluster. To do this, create another new file called `galera.pref` within the `/etc/apt/preferences.d/` directory:

    sudo nano /etc/apt/preferences.d/galera.pref

Add the following lines to the text editor:

/etc/apt/preferences.d/galera.pref

    # Prefer Codership repository
    Package: *
    Pin: origin releases.galeracluster.com
    Pin-Priority: 1001

Save and close that file, and then run `sudo apt-get update` in order to include package manifests from the new repositories:

    sudo apt-get update

You may see a warning that the signature `uses weak digest algorithm (SHA1)`. There is [an open issue on GitHub to address this](https://github.com/codership/mysql-wsrep/issues/272). In the meantime, it’s okay to proceed.

Once the repositories are updated on all three servers, we’re ready to install MySQL and Galera.

## Step 2 — Installing MySQL and Galera on All Servers

Run the following command on all three servers to install a version of MySQL patched to work with Galera, as well as Galera and several dependencies:

    sudo apt-get install galera-3 galera-arbitrator-3 mysql-wsrep-5.6

During the installation, you will be asked to set a password for the MySQL administrative user.

We should have all of the pieces necessary to begin configuring the cluster, but since we’ll be relying on `rsync` in later steps, let’s make sure it’s installed on all three, as well:

    sudo apt-get install rsync

This will confirm that the newest version of `rsync` is already available, prompt you to upgrade the version you have, or install it.

Once we have installed MySQL on each of the three servers, we can begin configuration.

## Step 3 — Configuring the First Node

Each node in the cluster needs to have a nearly identical configuration. Because of this, we will do all of the configuration on our first machine, and then copy it to the other nodes.

By default, MySQL is configured to check the `/etc/mysql/conf.d` directory to get additional configuration settings from files ending in `.cnf`. We will create a file in this directory with all of our cluster-specific directives:

    sudo nano /etc/mysql/conf.d/galera.cnf

Add the following configuration into the file. You will need to change the settings highlighted in red. We’ll explain what each section means below.

/etc/mysql/conf.d/galera.cnf on the first node

    [mysqld]
    binlog_format=ROW
    default-storage-engine=innodb
    innodb_autoinc_lock_mode=2
    bind-address=0.0.0.0
    
    # Galera Provider Configuration
    wsrep_on=ON
    wsrep_provider=/usr/lib/galera/libgalera_smm.so
    
    # Galera Cluster Configuration
    wsrep_cluster_name="test_cluster"
    wsrep_cluster_address="gcomm://first_ip,second_ip,third_ip"
    
    # Galera Synchronization Configuration
    wsrep_sst_method=rsync
    
    # Galera Node Configuration
    wsrep_node_address="this_node_ip"
    wsrep_node_name="this_node_name"

- **The first section** modifies or re-asserts MySQL settings that will allow the cluster to function correctly. For example, Galera Cluster won’t work with MyISAM or similar non-transactional storage engines, and `mysqld` must not be bound to the IP address for localhost. You can learn about the settings in more detail on the Galera Cluster [system configuration page](http://galeracluster.com/documentation-webpages/configuration.html).

- **The “Galera Provider Configuration” section** configures the MySQL components that provide a write-set replication API. This means Galera in our case, since Galera is a wsrep (write-set replication) provider. We specify the general parameters to configure the initial replication environment. This doesn’t require any customization, but you can learn more about [Galera configuration options](http://galeracluster.com/documentation-webpages/?id=galera_parameters).

- **The “Galera Cluster Configuration” section** defines the cluster, identifying the cluster members by IP address or resolvable domain name, and creating a name for the cluster to ensure that members join the correct group. You can change the `wsrep_cluster_name` to something more meaningful than `test_cluster` or leave it as-is, but you _must_ update `wsrep_cluster_address` with the addresses of your three servers. If your servers have private IP addresses, use them here.

- **The “Galera Synchronization Configuration” section** defines how the cluster will communicate and synchronize data between members. This is used only for the state transfer that happens when a node comes online. For our initial setup, we are using `rsync`, because it’s commonly available and does what we need for now.

- **The “Galera Node Configuration” section** clarifies the IP address and the name of the current server. This is helpful when trying to diagnose problems in logs and for referencing each server in multiple ways. The `wsrep_node_address` must match the address of the machine you’re on, but you can choose any name you want in order to help you identify the node in log files.

When you are satisfied with your cluster configuration file, copy the contents into your clipboard and then save and close the file.

Now that the first server is configured, we’ll move on to the next two nodes.

## Step 4 — Configuring the Remaining Nodes

On each of the remaining nodes, open the configuration file:

    sudo nano /etc/mysql/conf.d/galera.cnf

Paste in the configuration you copied from the first node, then update the “Galera Node Configuration” to use the IP address or resolvable domain name for the specific node you’re setting up. Finally, update its name, which you can set to whatever helps you identify the node in your log files:

/etc/mysql/conf.d/galera.cnf

    . . .
    # Galera Node Configuration
    wsrep_node_address="this_node_ip"
    wsrep_node_name="this_node_name"
    . . .

Save and exit the file on each server.

We’re almost ready to bring up the cluster, but before we do, we’ll want to make sure that the appropriate ports are open.

## Step 5 — Opening the Firewall on Every Server

On every server, let’s check the status of the firewall:

    sudo ufw status

In this case, only SSH is allowed through:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

You may have other rules in place or no firewall rules at all. Since only SSH traffic is permitted in this case, you’ll need to add rules for MySQL and Galera traffic.

Galera can make use of four ports:

- `3306` is used for MySQL client connections and State Snapshot Transfer that use the mysqldump method.
- `4567` is used by Galera Cluster for replication traffic, multicast replication uses both UDP transport and TCP on this port.
- `4568` is used for Incremental State Transfer.
- `4444` is used for all other State Snapshot Transfer.

In our example, we’ll open all four ports while we do our setup. Once we’ve confirmed that replication is working, we will close any ports we’re not actually using and restrict traffic to just servers in the cluster.

Open the ports with the following command:

    sudo ufw allow 3306,4567,4568,4444/tcp
    sudo ufw allow 4567/udp

**Note:** Depending on what else is running on your servers, you might want restrict access right away. The [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands) guide can help with this.

## Step 6 — Starting the Cluster

To begin, we need to stop the running MySQL service so that our cluster can be brought online.

### Stop MySQL on all Three Servers:

Use the command below on all three servers to stop mysql so that we can bring them back up in a cluster:

    sudo systemctl stop mysql

`systemctl` doesn’t display the outcome of all service management commands, so to be sure we succeeded, run the following command:

    sudo systemctl status mysql

If the last line looks something like the following, the command was successful.

    Output. . .
    Sep 02 22:17:56 galera-02 systemd[1]: Stopped LSB: start and stop MySQL.

Once we’ve shut down `mysql` on all of the servers, we’re ready to proceed.

### Bring up the First Node:

The way we’ve configured our cluster, each node that comes online tries to connect to at least one other node specified in its `galera.cnf` file to get its initial state. A normal `systemctl start mysql` would fail because there are no nodes running for the first node to connect with, so we need to pass the `wsrep-new-cluster` parameter to the first node we start. However, neither `systemd` nor `service` will properly accept the [`--wsrep-new-cluster` argument at this time](https://github.com/codership/mysql-wsrep/issues/266), so we’ll need to start the first node using the startup script in `/etc/init.d`. Once you’ve done this, you can start the remaining nodes with `systemctl.`

**Note:** If you prefer them all to be started with `systemd`, once you have another node up, you can kill the initial node. Since the second node is available, when you restart the first one with `sudo systemctl start mysql` it will be able to join the running cluster

    sudo /etc/init.d/mysql start --wsrep-new-cluster

When this script completes, the node is registered as part of the cluster, and we can see it with the following command:

    mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

    Output+--------------------+-------+
    | Variable_name | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 1 |
    +--------------------+-------+

On the remaining nodes, we can start `mysql` normally. They will search for any member of the cluster list that is online, so when they find one, they will join the cluster.

### Bring up the Second Node:

Start `mysql`:

    sudo systemctl start mysql

We should see our cluster size increase as each node comes online:

    mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

    Output+--------------------+-------+
    | Variable_name | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 2 |
    +--------------------+-------+

### Bring up the Third Node:

Start `mysql`:

    sudo systemctl start mysql

If everything is working well, the cluster size should be set to three:

    mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

    Output+--------------------+-------+
    | Variable_name | Value |
    +--------------------+-------+
    | wsrep_cluster_size | 3 |
    +--------------------+-------+

At this point, the entire cluster should be online and communicating. With that, we can test replication between each of the cluster’s nodes.

## Step 7 — Testing Replication

We’ve gone through the steps up to this point so that our cluster can perform replication from any node to any other node, known as active-active replication. Let’s test to see if the replication is working as expected.

### Write to the First Node:

We’ll start by making database changes on our first node. The following commands will create a database called `playground` and a table inside of this called `equipment`.

    mysql -u root -p -e 'CREATE DATABASE playground;
    CREATE TABLE playground.equipment ( id INT NOT NULL AUTO_INCREMENT, type VARCHAR(50), quant INT, color VARCHAR(25), PRIMARY KEY(id));
    INSERT INTO playground.equipment (type, quant, color) VALUES ("slide", 2, "blue");'

We now have one value in our table.

### Read and Write on the Second Node:

Next, we’ll look at the second node to verify that replication is working:

    mysql -u root -p -e 'SELECT * FROM playground.equipment;'

If replication is working, the data we entered on the first node will be visible here on the second:

    Output+----+-------+-------+-------+
    | id | type | quant | color |
    +----+-------+-------+-------+
    | 1 | slide | 2 | blue |
    +----+-------+-------+-------+

From this same node, we can write data to the cluster:

    mysql -u root -p -e 'INSERT INTO playground.equipment (type, quant, color) VALUES ("swing", 10, "yellow");'

### Read and Write on the Third Node:

From the third node, we can read all of this data by querying the database again:

    mysql -u root -p -e 'SELECT * FROM playground.equipment;'

    Output +----+-------+-------+--------+
      | id | type | quant | color |
      +----+-------+-------+--------+
      | 1 | slide | 2 | blue |
      | 2 | swing | 10 | yellow |
      +----+-------+-------+--------+

Again, we can add another value from this node:

    mysql -u root -p -e 'INSERT INTO playground.equipment (type, quant, color) VALUES ("seesaw", 3, "green");'

### Read on the First Node:

Back on the first node, we can verify that our data is available everywhere:

    mysql -u root -p -e 'SELECT * FROM playground.equipment;'

    Output +----+--------+-------+--------+
      | id | type | quant | color |
      +----+--------+-------+--------+
      | 1 | slide | 2 | blue |
      | 2 | swing | 10 | yellow |
      | 3 | seesaw | 3 | green |
      +----+--------+-------+--------+

We’ve tested we can write to all of the nodes and that replication is being performed properly.

## Conclusion

At this point, you should have a working three-node Galera test cluster configured. If you plan on using a Galera cluster in a production situation, it’s recommended that you begin with no fewer than five nodes.

Before production use, you may want to take a look at some of the [other state snapshot transfer (sst) agents](http://galeracluster.com/documentation-webpages/sst.html) like “xtrabackup" which allows you to set up new nodes very quickly and without large interruptions to your active nodes. This does not affect the actual replication, but is a concern when nodes are being initialized. Finally, to protect your data as it moves between servers, you should also set up [SSL](http://galeracluster.com/documentation-webpages/ssl.html) encryption.
