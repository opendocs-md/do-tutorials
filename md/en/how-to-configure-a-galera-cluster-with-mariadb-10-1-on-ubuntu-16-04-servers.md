---
author: Melissa Anderson
date: 2016-08-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-a-galera-cluster-with-mariadb-10-1-on-ubuntu-16-04-servers
---

# How To Configure a Galera Cluster with MariaDB 10.1 on Ubuntu 16.04 Servers

## Introduction

Clustering adds high availability to your database by distributing changes to different servers. In the event that one of the instances fails, others are quickly available to continue serving.

Clusters come in two general configurations, active-passive and active-active. In active-passive clusters, all writes are done on a single active server and then copied to one or more passive servers that are poised to take over only in the event of an active server failure. Some active-passive clusters also allow SELECT operations on passive nodes. In an active-active cluster, every node is read-write and a change made to one is replicated to all.

In this guide, we will configure an active-active MariaDB Galera cluster. For demonstration purposes, we will configure and test three nodes, the smallest configurable cluster.

## Prerequisites

To follow along, you will need:

- **Three Ubuntu 16.04 servers** , each with a non-root user with `sudo` privileges and private networking, if it’s available to you. 

Once all of these prerequisites are in place, we’re ready to install MariaDB.

## Step 1 — Adding the MariaDB 10.1 Repositories to All Servers

MariaDB 10.1 isn’t included in the default Ubuntu repositories, so we’ll start by adding the external Ubuntu repository maintained by the MariaDB project to all three of our servers.

**Note:** MariaDB is a well-respected provider, but not all external repositories are reliable. Be sure to install only from trusted sources.

First, we’ll add the MariaDB repository key with the `apt-key` command, which apt will use to verify that the package is authentic.

    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

Once we have the trusted key in the database, we can add the repository. We’ll need to run `apt-get update` afterward in order to include package manifests from the new repository:

    sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.1/ubuntu xenial main'
    sudo apt-get update

**Note:** You must run `update`after adding the repository. Otherwise, you’ll install version 10.0 from the Ubuntu packages, which does not contain the Galera package.

Once the repositories are updated on all three servers, we’re ready to install MariaDB. One thing to note about MariaDB is that it originated as a drop-in replacement for MySQL, so in many configuration files and startup scripts, you’ll see `mysql` rather than `mariadb`. For consistency’s sake, we use `mysql` in this guide where either could work.

## Step 2 — Installing MariaDB on All Servers

Beginning with version 10.1, the MariaDB Server and MariaDB Galera Server packages are combined, so installing `mariadb-server`will automatically install Galera and several dependencies:

    sudo apt-get install mariadb-server

During the installation, you will be asked to set a password for the MariaDB administrative user. No matter what you choose, this root password will be overwritten with the password from the first node once replication begins.

We should have all of the pieces necessary to begin configuring the cluster, but since we’ll be relying on `rsync` in later steps, let’s make sure it’s installed.

    sudo apt-get install rsync

This will confirm that the newest version of `rsync` is already available or prompt you to upgrade or install it.

Once we have installed MariaDB on each of the three servers, we can begin configuration.

## Step 3 — Configuring the First Node

Each node in the cluster needs to have a nearly identical configuration. Because of this, we will do all of the configuration on our first machine, and then copy it to the other nodes.

By default, MariaDB is configured to check the `/etc/mysql/conf.d` directory to get additional configuration settings for from ending in `.cnf`. We will create a file in this directory with all of our cluster-specific directives:

    sudo nano /etc/mysql/conf.d/galera.cnf

Copy and paste the following configuration into the file. You will need to change the settings highlighted in red. We’ll explain what each section means below.

/etc/mysql/conf.d/galera.cnf

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

- **The first section** modifies or re-asserts MariaDB/MySQL settings that will allow the cluster to function correctly. For example, Galera Cluster won’t work with MyISAM or similar non-transactional storage engines, and `mysqld` must not be bound to the IP address for localhost. You can learn about the settings in more detail on the Galera Cluster [system configuration page](http://galeracluster.com/documentation-webpages/configuration.html).

- **The “Galera Provider Configuration” section** configures the MariaDB components that provide a WriteSet replication API. This means Galera in our case, since Galera is a wsrep (WriteSet Replication) provider. We specify the general parameters to configure the initial replication environment. This doesn’t require any customization, but you can learn more about [Galera configuration options](http://www.codership.com/wiki/doku.php?id=galera_parameters). 

- **The “Galera Cluster Configuration” section** defines the cluster, identifying the cluster members by IP address or resolvable domain name and creating a name for the cluster to ensure that members join the correct group. You can change the `wsrep_cluster_name` to something more meaningful than `test_cluster` or leave it as-is, but you _must_ update `wsrep_cluster_address` with the addresses of your three servers. If your servers have private IP addresses, use them here.

- **The “Galera Synchronization Configuration” section** defines how the cluster will communicate and synchronize data between members. This is used only for the state transfer that happens when a node comes online. For our initial setup, we are using `rsync`, because it’s commonly available and does what we need for now.

- **The “Galera Node Configuration” section** clarifies the IP address and the name of the current server. This is helpful when trying to diagnose problems in logs and for referencing each server in multiple ways. The `wsrep_node_address` must match the address of the machine you’re on, but you can choose any name you want in order to help you identify the node in log files.

When you are satisfied with your cluster configuration file, copy the contents into your clipboard, save and close the file.

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

Save and exit the file on each server. We’re almost ready to bring up the cluster, but before we do, we’ll want to make sure that the appropriate ports are open.

## Step 5 — Opening the Firewall on Every Server

On every server, let’s check the status of the firewall:

    sudo ufw status

In this case, only SSH is allowed through:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Since only ssh traffic is permitted in this case, we’ll need to add rules for MySQL and Galera traffic. If we tried to start the cluster, we would fail because of firewall rules.

Galera can make use of four ports:

- 3306 For MySQL client connections and State Snapshot Transfer that use the mysqldump method.
- 4567 For Galera Cluster replication traffic, multicast replication uses both UDP transport and TCP on this port.
- 4568 For Incremental State Transfer.
- 4444 For all other State Snapshot Transfer.

In our example, we’ll open all four ports while we do our setup. Once we’ve confirmed that replication is working, we’d want to close any ports we’re not actually using and restrict traffic to just servers in the cluster.

Open the ports with the following command:

    sudo ufw allow 3306,4567,4568,4444/tcp
    sudo ufw allow 4567/udp

**Note:** Depending on what else is running on your servers you might want restrict access right away. The [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands) guide can help with this.

## Step 6 — Starting the Cluster

To begin, we need to stop the running MariaDB service so that our cluster can be brought online.

### Stop MariaDB on all Three Servers:

Use the command below on all three servers to stop mysql so that we can bring them back up in a cluster:

    sudo systemctl stop mysql

`systemctl` doesn’t display the outcome of all service management commands, so to be sure we succeeded, we’ll use the following command:

    sudo systemctl status mysql

If the last line looks something like the following, the command was successful.

    Output . . . 
    Aug 19 02:55:15 galera-01 systemd[1]: Stopped MariaDB database server.

Once we’ve shut down `mysql` on all of the servers, we’re ready to proceed.

### Bring up the First Node:

To bring up the first node, we’ll need to use a special startup script. The way we’ve configured our cluster, each node that comes online tries to connect to at least one other node specified in its `galera.cnf` file to get its initial state. Without using the `galera_new_cluster` script that allows systemd to pass the the `--wsrep-new-cluster` parameter, a normal `systemctl start mysql` would fail because there are no nodes running for the first node to connect with.

    sudo galera_new_cluster

When this script succeeds, the node is registered as part of the cluster, and we can see it with the following command:

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

At this point, the entire cluster should be online and communicating. Before we test replication, however, there’s one more configuration detail to attend to.

## Step 7 — Configuring the Debian Maintenance User

Currently, Ubuntu and Debian’s MariaDB servers do routine maintenance such as log rotation as a special maintenance user. When we installed MariaDB, the credentials for that user were randomly generated, stored in `/etc/mysql/debian.cnf`, and inserted into the MariaDB’s `mysql` database.

As soon as we brought up our cluster, the password from the first node was replicated to the other nodes, so the value in `debian.cnf` no longer matches the password in the database. This means anything that uses the maintenance account will try to connect to the database with the password in the configuration file and will fail on all but the first node.

To correct this, we’ll copy our first node’s `debian.cnf` to the remaining nodes.

### Copy from the First Node:

Open the `debian.cnf` file with your text editor:

    sudo nano /etc/mysql/debian.cnf

The file should look something like:

    [client]
    host = localhost
    user = debian-sys-maint
    password = 03P8rdlknkXr1upf
    socket = /var/run/mysqld/mysqld.sock
    [mysql_upgrade]
    host = localhost
    user = debian-sys-maint
    password = 03P8rdlknkXr1upf
    socket = /var/run/mysqld/mysqld.sock
    basedir = /usr

Copy the information into your clipboard.

### Update the Second Node:

On your second node, open the same file:

    sudo nano /etc/mysql/debian.cnf

Despite the warning at the top of the file that says “DO NOT TOUCH!” we need to make the change for the cluster to work. You can confidently delete the current information and paste the contents from the first node’s configuration. They should be exactly the same now. Save and close the file.

### Update the Third Node:

On your third node, open the same file:

    sudo nano /etc/mysql/debian.cnf

Delete the current information and paste the contents from the first node’s configuration. Save and close the file.

The mismatch wouldn’t have affected our ability to test replication, but it’s best to take care of early on to avoid failures later.

**Note:** After you’re done, you can test that the maintenance account is able to connect by supplying the password from the local `debian.conf` as follows:

    sudo cat /etc/mysql/debian.cnf

Copy the password from the output. Then connect to `mysql`:

    mysql -u debian-sys-maint -p

At the prompt, supply the password that you copied. If you can connect, all is well.

If not, verify the password in the file is the same as the first node, then substitute below:

    update mysql.user set password=PASSWORD('password_from_debian.cnf') where User='debian-sys-maint';

Repeat to test remaining nodes.

## Step 8 — Testing Replication

We’ve gone through the steps up to this point so that our cluster can perform replication from any node to any other node, known as active-active or master-master replication. Let’s test to see if the replication is working as expected.

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

From the third node, we can read all of this data by querying the again:

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

Before production use, you may want to take a look at some of the [other state snapshot transfer (sst) agents](http://galeracluster.com/documentation-webpages/sst.html) like “xtrabackup" which allows you to set up new nodes very quickly and without large interruptions to your active nodes. This does not affect the actual replication, but is a concern when nodes are being initialized.

Finally, if your cluster members are not on a private network, you will also need to set up [SSL](http://galeracluster.com/documentation-webpages/ssl.html) to protect your data as it moves between servers.
