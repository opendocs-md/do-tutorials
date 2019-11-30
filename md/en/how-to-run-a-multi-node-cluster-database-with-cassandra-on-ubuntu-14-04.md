---
author: finid
date: 2016-03-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-run-a-multi-node-cluster-database-with-cassandra-on-ubuntu-14-04
---

# How To Run a Multi-Node Cluster Database with Cassandra on Ubuntu 14.04

## Introduction

[Apache Cassandra](http://cassandra.apache.org/) is a highly scalable open source database system, achieving great performance on multi-node setups.

Previously, we went over [how to run a single-node Cassandra cluster](how-to-install-cassandra-and-run-a-single-node-cluster-on-ubuntu-14-04). In this tutorial, you’ll learn how to install and use Cassandra to run a multi-node cluster on Ubuntu 14.04.

## Prerequisites

Because you’re about to build a multi-node Cassandra cluster, you must determine how many servers you’d like to have in your cluster and configure each of them. It is recommended, but not required, that they have the same or similar specifications.

To complete this tutorial, you’ll need the following:

- At least two Ubuntu 14.04 servers configured using [this initial setup guide](initial-server-setup-with-ubuntu-14-04).

- Each server must be secured with a firewall using [this IPTables guide](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04).

- Each server must also have Cassandra installed by following [this Cassandra installation guide](how-to-install-cassandra-and-run-a-single-node-cluster-on-ubuntu-14-04).

## Step 1 — Deleting Default Data

Servers in a Cassandra cluster are known as _nodes_. What you have on each server right now is a single-node Cassandra cluster. In this step, we’ll set up the nodes to function as a multi-node Cassandra cluster.

All the commands in this and subsequent steps must be repeated on each node in the cluster, so be sure to have as many terminals open as you have nodes in the cluster.

The first command you’ll run on each node will stop the Cassandra daemon.

    sudo service cassandra stop

When that’s completed, delete the default dataset.

    sudo rm -rf /var/lib/cassandra/data/system/*

## Step 2 — Configuring the Cluster

Cassandra’s configuration file is located in the `/etc/cassandra` directory. That configuration file, `cassandra.yaml`, contains many directives and is very well commented. In this step, we’ll modify that file to set up the cluster.

Only the following directives need to be modified to set up a multi-node Cassandra cluster:

- `cluster_name`: This is the name of your cluster.

- `-seeds`: This is a comma-delimited list of the IP address of each node in the cluster.

- `listen_address`: This is IP address that other nodes in the cluster will use to connect to this one. It defaults to **localhost** and needs changed to the IP address of the node.

- `rpc_address`: This is the IP address for remote procedure calls. It defaults to **localhost**. If the server’s hostname is properly configured, leave this as is. Otherwise, change to server’s IP address or the loopback address (`127.0.0.1`).

- `endpoint_snitch`: Name of the snitch, which is what tells Cassandra about what its network looks like. This defaults to **SimpleSnitch** , which is used for networks in one datacenter. In our case, we’ll change it to **GossipingPropertyFileSnitch** , which is preferred for production setups. 

- `auto_bootstrap`: This directive is not in the configuration file, so it has to be added and set to **false**. This makes new nodes automatically use the right data. It is optional if you’re adding nodes to an existing cluster, but required when you’re initializing a fresh cluster, that is, one with no data.

Open the configuration file for editing using `nano` or your favorite text editor.

    sudo nano /etc/cassandra/cassandra.yaml

Search the file for the following directives and modify them as below to match your cluster. Replace `your_server_ip` with the IP address of the server you’re currently working on. The `- seeds:` list should be the same on every server, and will contain each server’s IP address separated by commas.

/etc/cassandra/cassandra.yaml

    . . .
    
    cluster_name: 'CassandraDOCluster'
    
    . . .
    
    seed_provider:
      - class_name: org.apache.cassandra.locator.SimpleSeedProvider
        parameters:
             - seeds: "your_server_ip,your_server_ip_2,...your_server_ip_n"
    
    . . .
    
    listen_address: your_server_ip
    
    . . .
    
    rpc_address: your_server_ip
    
    . . .
    
    endpoint_snitch: GossipingPropertyFileSnitch
    
    . . .

At the bottom of the file, add in the `auto_bootstrap` directive by pasting in this line:

/etc/cassandra/cassandra.yaml

    auto_bootstrap: false

When you’re finished modifying the file, save and close it. Repeat this step for all the servers you want to include in the cluster.

## Step 3 — Configuring the Firewall

At this point, the cluster has been configured, but the nodes are not communicating. In this step, we’ll configure the firewall to allow Cassandra traffic.

First, restart the Cassandra daemon on each.

    sudo service cassandra start

If you check the status of the cluster, you’ll find that only the local node is listed, because it’s not yet able to communicate with the other nodes.

    sudo nodetool status

Output

    Datacenter: datacenter1
    =======================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    -- Address Load Tokens Owns Host ID Rack
    UN 192.168.1.4 147.48 KB 256 ? f50799ee-8589-4eb8-a0c8-241cd254e424 rack1
    
    Note: Non-system keyspaces don't have the same replication settings, effective ownership information is meaningless

To allow communication, we’ll need to open the following network ports for each node:

- `7000`, which is the TCP port for commands and data.

- `9042`, which is the TCP port for the native transport server. `cqlsh`, the Cassandra command line utility, will connect to the cluster through this port.

To modify the firewall rules, open the rules file for IPv4.

    sudo nano /etc/iptables/rules.v4

Copy and paste the following line within the INPUT chain, which will allow traffic on the aforementioned ports. If you’re using the `rules.v4` file from the firewall tutorial, you can insert the following line just before the `# Reject anything that's fallen through to this point` comment.

The IP address specified by`-s` should be the IP address of another node in the cluster. If you have two nodes with IP addresses `111.111.111.111` and `222.222.222.222`, the rule on the `111.111.111.111` machine should use the IP address `222.222.222.222`.

New firewall rule

    -A INPUT -p tcp -s your_other_server_ip -m multiport --dports 7000,9042 -m state --state NEW,ESTABLISHED -j ACCEPT

After adding the rule, save and close the file, then restart IPTables.

    sudo service iptables-persistent restart

## Step 4 — Check the Cluster Status

We’ve now completed all the steps needed to make the nodes into a multi-node cluster. You can verify that they’re all communicating by checking their status.

    sudo nodetool status

Output

    Datacenter: datacenter1
    =======================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    -- Address Load Tokens Owns Host ID Rack
    UN 192.168.1.4 147.48 KB 256 ? f50799ee-8589-4eb8-a0c8-241cd254e424 rack1
    UN 192.168.1.6 139.04 KB 256 ? 54b16af1-ad0a-4288-b34e-cacab39caeec rack1
    
    Note: Non-system keyspaces don't have the same replication settings, effective ownership information is meaningless

If you can see all the nodes you configured, you’ve just successfully set up a multi-node Cassandra cluster.

You can also check if you can connect to the cluster using `cqlsh`, the Cassandra command line client. Note that you can specify the IP address of any node in the cluster for this command.

    cqlsh your_server_ip 9042

You will see it connect:

Output

    Connected to My DO Cluster at 192.168.1.6:9042.
    [cqlsh 5.0.1 | Cassandra 2.2.3 | CQL spec 3.3.1 | Native protocol v4]
    Use HELP for help.
    cqlsh>

Then you can exit the CQL terminal.

    exit

## Conclusion

Congratulations! You now have a multi-node Cassandra cluster running on Ubuntu 14.04. More information about Cassandra is available at the [project’s website](http://wiki.apache.org/cassandra/GettingStarted). If you need to troubleshoot the cluster, the first place to look for clues are in the log files, which are located in the `/var/log/cassandra` directory.
