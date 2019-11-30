---
author: finid
date: 2015-10-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-cassandra-and-run-a-single-node-cluster-on-ubuntu-14-04
---

# How To Install Cassandra and Run a Single-Node Cluster on Ubuntu 14.04

## Introduction

Cassandra, or Apache Cassandra, is a highly scalable open source NoSQL database system, achieving great performance on multi-node setups.

In this tutorial, you’ll learn how to install and use it to run a single-node cluster on Ubuntu 14.04.

## Prerequisite

To complete this tutorial, you will need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)

## Step 1 — Installing the Oracle Java Virtual Machine

Cassandra requires that the Oracle Java SE Runtime Environment (JRE) be installed. So, in this step, you’ll install and verify that it’s the default JRE.

To make the Oracle JRE package available, you’ll have to add a Personal Package Archives (PPA) using this command:

    sudo add-apt-repository ppa:webupd8team/java

Update the package database:

    sudo apt-get update

Then install the Oracle JRE. Installing this particular package not only installs it but also makes it the default JRE. When prompted, accept the license agreement:

    sudo apt-get install oracle-java8-set-default

After installing it, verify that it’s now the default JRE:

    java -version

You should see output similar to the following:

    Outputjava version "1.8.0_60"
    Java(TM) SE Runtime Environment (build 1.8.0_60-b27)
    Java HotSpot(TM) 64-Bit Server VM (build 25.60-b23, mixed mode)

## Step 2 — Installing Cassandra

We’ll install Cassandra using packages from the official Apache Software Foundation repositories, so start by adding the repo so that the packages are available to your system. Note that Cassandra 2.2.2 is the latest version at the time of this publication. Change the `22x` to match the latest version. For example, use `23x` if Cassandra 2.3 is the latest version:

    echo "deb http://www.apache.org/dist/cassandra/debian 22x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

The add the repo’s source:

    echo "deb-src http://www.apache.org/dist/cassandra/debian 22x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list

To avoid package signature warnings during package updates, we need to add three public keys from the Apache Software Foundation associated with the package repositories.

Add the first one using this pair of commands, which must be run one after the other:

    gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
    gpg --export --armor F758CE318D77295D | sudo apt-key add -

Then add the second key:

    gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00
    gpg --export --armor 2B5C1B00 | sudo apt-key add -

Then add the third:

    gpg --keyserver pgp.mit.edu --recv-keys 0353B12C
    gpg --export --armor 0353B12C | sudo apt-key add -

Update the package database once again:

    sudo apt-get update

Finally, install Cassandra:

    sudo apt-get install cassandra

## Step 3 — Troubleshooting and Starting Cassandra

Ordinarily, Cassandra should have been started automatically at this point. However, because of a bug, it does not. To confirm that it’s not running, type:

    sudo service cassandra status

If it is not running, the following output will be displayed:

    Output* could not access pidfile for Cassandra

This is a well-known issue with the latest versions of Cassandra on Ubuntu. We’ll try a few fixes. First, start by editing its init script. The parameter we’re going to modify is on line 60 of that script, so open it using:

    sudo nano +60 /etc/init.d/cassandra

That line should read:

    /etc/init.d/cassandraCMD_PATT="cassandra.+CassandraDaemon"

Change it to:

    /etc/init.d/cassandra
    CMD_PATT="cassandra"

Close and save the file, then reboot the server:

    sudo reboot

Or:

    sudo shutdown -r now

After logging back in, Cassandra should now be running. Verify:

    sudo service cassandra status

If you are successful, you will see:

    Output* Cassandra is running

## Step 4 — Connecting to the Cluster

If you were able to successfully start Cassandra, check the status of the cluster:

    sudo nodetool status

In the output, **UN** means it’s **U** p and **N** ormal:

    OutputDatacenter: datacenter1
    =======================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    -- Address Load Tokens Owns Host ID Rack
    UN 127.0.0.1 142.02 KB 256 ? 2053956d-7461-41e6-8dd2-0af59436f736 rack1
    
    Note: Non-system keyspaces don't have the same replication settings, effective ownership information is meaningless

Then connect to it using its interactive command line interface `cqlsh`.

    cqlsh

You will see it connect:

    OutputConnected to Test Cluster at 127.0.0.1:9042.
    [cqlsh 5.0.1 | Cassandra 2.2.2 | CQL spec 3.3.1 | Native protocol v4]
    Use HELP for help.
    cqlsh>

Type `exit` to quit:

    exit

## Conclusion

Congratulations! You now have a single-node Cassandra cluster running on Ubuntu 14.04. More information about Cassandra is available at the [project’s website](http://wiki.apache.org/cassandra/GettingStarted).
