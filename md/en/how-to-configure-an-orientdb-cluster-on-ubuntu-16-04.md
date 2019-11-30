---
author: finid
date: 2017-06-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-an-orientdb-cluster-on-ubuntu-16-04
---

# How To Configure an OrientDB Cluster on Ubuntu 16.04

## Introduction

OrientDB is a multi-model NoSQL database with support for graph and document databases. It is a Java application and can run on any operating system. It’s also fully [ACID](https://en.wikipedia.org/wiki/ACID)-complaint with support for multi-master clustering and replication, allowing easy horizontal scaling.

However, the word “cluster” in OrientDB can refer to two different concepts:

1. You can have a cluster of OrientDB _nodes_, which are servers running OrientDB. This implies using at least one physical (or cloud) server, because more than one OrientDB instance can be running on one server.
2. You can also have a cluster within an OrientDB _database_, which is a grouping of records of similar type or value. Such a cluster can also exist across multiple servers or be confined to one server.

The focus of this article is on the first kind of cluster, i.e. a cluster of nodes. In cluster mode, OrientDB runs in a multi-master or master-less distributed architecture, which means that every node in the cluster operates on an equal footing and is able to read/write each other’s records. However, a node is also able to join a cluster as a _replica_, where it operates in read-only mode.

In this tutorial, you will set up a three-node cluster with two master nodes and one replica node using the community edition of OrientDB.

## Prerequisites

To follow this tutorial, you will need:

- Three Ubuntu 16.04 servers with enough RAM to support the cluster. This will vary depending on your needs and how you customize OrientDB, but 4GB each is a good default.

- A sudo non-root user account and firewall set up **on each server** using [this Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04).

- Java has to be installed on all servers, which you can do by following [the JDK 8 step of this Java installation guide](how-to-install-java-with-apt-get-on-ubuntu-16-04#installing-the-oracle-jdk). The OpenJDK JRE also works, so if you don’t want to accept the Oracle license, you can install the default JRE using that same tutorial.

- OrientDB installed **on each server** by following [Step 1 of the single server OrientDB installation guide](how-to-install-and-configure-orientdb-on-ubuntu-16-04) exactly as written. You can optionally follow Step 2 to limit the amount of RAM necessary as well; the OrientDB distributed startup script expects to have at least 4 GB of RAM available, and will fail to start if it finds less unless you change this.

- OrientDB set up as a Systemd service **on each server** by following [Steps 5 and 6 of the single server OrientDB installation guide](how-to-install-and-configure-orientdb-on-ubuntu-16-04), stopping after you reload the units (i.e. without starting the service). The only change you’ll need to make is the file you supply for `ExecStart` in the unit file. The original tutorial uses `server.sh`, but here, use `dserver.sh` for distributed mode.

## Step 1 — Generating The Root Password and OrientDB Instance Name

First, we’ll run the distributed server script, `dserver.sh` to generate credentials that the instance of OrientDB needs to function within a cluster. Specifically, this will let us set the root password and name for the instance of OrientDB. You’ll need to follow this step on **all three servers**.

To start, navigate to the installation directory.

    cd /opt/orientdb

Then start the distributed server.

    sudo bin/dserver.sh

When starting the distributed server for the first time, you’ll be prompted to specify a password for the **root** user account. This is an internal OrientDB account that will be used to access the server for things like OrientDB Studio, the web-based interface for managing OrientDB, and connecting to OrientDB from the console. If you don’t specify a password here, one will be generated automatically. However, it’s best to specify one yourself, so do so when presented with the following prompt:

    Output+---------------------------------------------------------------+
    | WARNING: FIRST RUN CONFIGURATION |
    +---------------------------------------------------------------+
    | This is the first time the server is running. Please type a |
    | password of your choice for the 'root' user or leave it blank |
    | to auto-generate it. |
    | |
    | To avoid this message set the environment variable or JVM |
    | setting ORIENTDB_ROOT_PASSWORD to the root password to use. |
    +---------------------------------------------------------------+
    
    Root password [BLANK=auto generate it]: *****
    Please confirm the root password: *****

Then you’ll be prompted to set a name for the instance of OrientDB, which can be the same as that of the cloud server it’s running on.

    Output+---------------------------------------------------------------+
    | WARNING: FIRST DISTRIBUTED RUN CONFIGURATION |
    +---------------------------------------------------------------+
    | This is the first time that the server is running as |
    | distributed. Please type the name you want to assign to the |
    | current server node. |
    | |
    | To avoid this message set the environment variable or JVM |
    | setting ORIENTDB_NODE_NAME to the server node name to use. |
    +---------------------------------------------------------------+
    
    Node name [BLANK=auto generate it]: node-name

When the script has finished running, you’ll see a line like this:

    Output2017-06-01 02:24:00:717 INFO OrientDB Server is active v2.2.20 (build 76ab59e72943d0ba196188ed100c882be4315139). [OServer]

At this point, you can terminate the process using `CTRL+C`. Now that OrientDB is installed, we need to modify several configuration files to let it run as a cluster.

## Step 2 — Configuring OrientDB to Function in Distributed Mode

For an installation of OrientDB to function as a node within a cluster, three files within its `config` directory need to be modified. They are:

1. `hazelcast.xml`: Parameters defined in this file make auto-discovery of nodes possible.
2. `default-distributed-db-config.json`: This file is solely for use in a distributed environment, and is used to define the behavior of the node for each database. 
3. `orientdb-server-config.xml`: This is the main OrientDB configuration file that needs to be modified whether in a distributed or standalone mode. 

We’ll modify each file in this step, starting with `hazelcast.xml`.

### Modifying The `hazelcast.xml` File

The most important setting you’ll have to configure in `hazelcast.xml` is the mechanism each node will use to join the cluster. Two mechanisms that we’ll consider in this section are _IP Multicast_ and _TCP/IP-cluster_. With the former, you specify a multicast address and port which each node will use to autodiscover the network it belongs to. With the latter, the IP address of each cluster member has to be specified. Because IP multicasting is not supported on the DigitalOcean, TCP/IP-cluster is the method we’ll use here.

To start, open the file for editing:

    sudo nano /opt/orientdb/config/hazelcast.xml

The file isn’t very long. This is a truncated version showing only the sections of the file you’ll change:

/opt/orientdb/config/hazelcast.xml

    . . .
        <group>
            <name>orientdb</name>
            <password>orientdb</password>
        </group>
        <properties>    
            . . .
        </properties>
        <network>
            <port auto-increment="true">2434</port>
            <join>
                <multicast enabled="true">
                    <multicast-group>235.1.1.1</multicast-group>
                    <multicast-port>2434</multicast-port>
                </multicast>
            </join>
        </network>

What you’ll do to this file is disable IP multicasting, add an entry that enables TCP/IP-cluster, and specify the cluster members. Let’s go through each tag:

- **group \> name** : This element defines the name of the cluster. You can choose anything you like.
- **group \> password** : Defines the password used to encrypt the broadcast messages sent by each member to join the cluster. Choose a strong password here.
- **network \> port** : Identifies the port used for auto-discovery of the nodes. The `auto-increment` attribute instructs the mechanism to start with the defined port and keep trying others if that port is in use. By setting it to false, the defined port will be used for communication, and node discovery will fail if the port is already in use. For this article, the attribute will be disabled.
- **join \> multicast** elements are used to define IP multicasting parameters. You won’t be using IP multicasting, so we’ll ignore them. That means we’ll set the `enabled` attribute to false.

- **join \> tcp-ip** : This is used to define TCP/IP-cluster-related parameters. The `enabled` attribute is used to enable it. 

- **join \> tcp-ip \> member** : Defines each member of the cluster. There are other approaches to specifying each member, but we’ll stick to this one where the IP address of each member is specified (one per line).

When you’re finished modifying the file, the final version will look like this:

/opt/orientdb/config/hazelcast.xml

    . . .
        <group>
            <name>clusterName</name>
            <password>clusterPassword</password>
        </group>
        <properties>    
            . . .
        </properties>
        <network>
            <port auto-increment="false">2434</port>
            <join>
                <multicast enabled="false">
                    <multicast-group>235.1.1.1</multicast-group>
                    <multicast-port>2434</multicast-port>
                </multicast>
                <tcp-ip enabled="true">
                    <member>your_master_server_ip_1</member>
                    <member>your_master_server_ip_2</member>
                    <member>your_replica_server_ip</member>
                </tcp-ip>
            </join>
        </network>

Save and close the file when you’re finshed editing it. Next is the second file on our list.

### Modifying The `default-distributed-db-config.json` File

As with the `hazelcast.xml`, we’ll be making just a few modifications to `/opt/orientdb/config/default-distributed-db-config.json`. It is in this file that you specify the role (master or replica) each server has to play in the cluster.

Open it for editing.

    sudo nano /opt/orientdb/config/default-distributed-db-config.json

The relevant portion of the file is shown in the code block below:

/opt/orientdb/config/default-distributed-db-config.json

    {
      "autoDeploy": true,
      "readQuorum": 1,
      "writeQuorum": "majority",
      "executionMode": "undefined",
      "readYourWrites": true,
      "newNodeStrategy": "static",
      "servers": {
        "*": "master"
      },
      . . . 
    }

Here’s what each line means:

- **autoDeploy** : Specifies whether to deploy a database to a new node in the cluster that does not already have it. 
- **readQuorum** : The number of responses from the cluster nodes that needs to be coherent before replying to a client on read operations. Setting it to “1” disables read coherency.
- **writeQuorum** : On write operations, how many nodes need to respond before sending a reply to the client. The default is **majority** , which is calculated using **(N/2) + 1**, where **N** is the number of available master nodes in the cluster. Replica nodes are not taken into consideration when calculating the majority. If left at the default in a cluster with just two master nodes, a quorum will never form if one of the nodes goes down. 
- **executionMode** : Defines a client’s mode of execution - synchronous or asynchronous. The default lets the client decide.
- **readYourWrites** : Specifies whether the response of the node counts towards reaching a write quorum.
- **newNodeStrategy** : What happens when a new node joins the cluster. With the default value, the node is automatically registered under the list of servers.

We will add the following parameters:

- **hotAlignment** : Specifies what happens if a node goes down and then comes back online. If enabled, synchronization messages are kept in a distributed queue when the node is offline. When it comes back online, it starts the synchronization phase by polling all the synchronization messages in the queue. 
- **servers** : Is used to specify the role (master or replica) of the nodes in the cluster. By default, an asterisk, `*`, is used to indicate that all nodes in the server will be masters. Because we intend to build a cluster that includes two masters and one replica, we’ll modify this parameter to match by specifying the name of each node and the role it will have in the cluster. The name is what you configured in Step 1. 

When you’re finished modifying the file, it should look like this:

/opt/orientdb/config/default-distributed-db-config.json

    {
      "replication": true,
      "hotAlignment" : true,
      "autoDeploy": true,
      "readQuorum": 1,
      "writeQuorum": "majority",
      "executionMode": "undefined",
      "readYourWrites": true,
      "newNodeStrategy": "static",
      "servers": {
        "orientdb_server_name_1": "master",
        "orientdb_server_name_2": "master",
        "orientdb_server_name_3": "replica"
      },
    
      ...
    
    }

Save and close the file when you’re done. We’ll now configure the last file on our list.

### Modifying The `orientdb-server-config.xml` File

Within `/opt/orientdb/config/orientdb-server-config.xml` is a parameter that’s used to enable or disable clustering using Hazelcast in-memory data grid in OrientDB. The name you gave the OrientDB instance (or had the script auto-generate) in Step 1 can be modified in this file.

Open it for editing.

    sudo nano /opt/orientdb/config/orientdb-server-config.xml

The relevant section of the file is shown below, which is towards the top of the file. Notice that the value of the **NodeName** parameter is what you specified in Step 1:

/opt/orientdb/config/orientdb-server-config.xml

    . . .
    <handler class="com.orientechnologies.orient.server.hazelcast.OHazelcastPlugin">
        <parameters>
            <parameter value="${distributed}" name="enabled"/>
            <parameter value="${ORIENTDB_HOME}/config/default-distributed-db-config.json" na$
            <parameter value="${ORIENTDB_HOME}/config/hazelcast.xml" name="configuration.haz$
            <parameter value="orientdb_server_name_1" name="nodeName"/>
        </parameters>
    </handler>
    . . .

To enable clustering, change the **enabled** parameter to **true**. After editing it, the final version will look like this:

/opt/orientdb/config/orientdb-server-config.xml

    . . .
    <handler class="com.orientechnologies.orient.server.hazelcast.OHazelcastPlugin">
        <parameters>
            <parameter value="true" name="enabled"/>
            <parameter value="${ORIENTDB_HOME}/config/default-distributed-db-config.json" na$
            <parameter value="${ORIENTDB_HOME}/config/hazelcast.xml" name="configuration.haz$
            <parameter value="orientdb_server_name_1" name="nodeName"/>
        </parameters>
    </handler>
    . . .

When you’re finished editing the file, save and close it.

The only things left before we can start and test the cluster is to allow OrientDB’s traffic through the firewall.

## Step 3 — Allowing OrientDB Traffic Through the Firewall

If you tried to start the cluster now, OrientDB’s traffic would be blocked by your firewall. Let’s add rules to allow traffic through the following ports:

- `2424`, used for binary communications
- `2434`, used for exchanging cluster communications

Open ports `2424` and `2480`.

    sudo ufw allow 2424
    sudo ufw allow 2434

**Note** : Port `2480` is used to access OrientDB Studio, the application’s web interface. This uses HTTP, so it is not secure and it should not be exposed to the public Internet. However, if you want to allow traffic on this port in a testing setup, you can do so with:

    sudo ufw allow 2480

Next, restart UFW.

    sudo systemctl restart ufw

OrientDB is already set up as a Systemd service from the prerequisites, so now that the rest of the configuration is finished, we can start the cluster.

## Step 4 — Starting and Testing the OrientDB Cluster

On each server, make sure the service is enabled so that it will be started on boot.

    sudo systemctl enable orientdb

Now you can start all three servers. The first server started (i.e. the first to join the cluster) becomes the _coordinator server_, which is where distributed operations are started. If you want a specific server to have that role, start that one first.

    sudo systemctl start orientdb

Check the process status to verify they started correctly.

    sudo systemctl status orientdb

You’ll see output that looks like this:

    Output● orientdb.service - OrientDB Server
       Loaded: loaded (/etc/systemd/system/orientdb.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2017-06-01 02:45:53 UTC; 7s ago

If the server does not start, look for clues in the output. Potential sources of error include not enough RAM, a Java JRE not installed, or a modified JSON file that failed validation. Remember to restart OrientDB if you make changes to any of the files from Step 2.

Once the process is running correctly, let’s test that the cluster is working properly. On any of the three nodes, filter for syslog entries related to the cluster:

    sudo tail -f /var/log/syslog | grep -i dserver

With that command, you’ll see output similar to the one below that indicates that all members of the cluster are online. The asterisk indicates which master is the coordinator server.

    Output-------------------+------+------------------------------------+-----+---------+-------------------+
    |Name |Status|Databases |Conns|StartedOn|Binary |
    -------------------+------+------------------------------------+-----+---------+-------------------+
    |orientdb-replica-1|ONLINE|GratefulDeadConcerts=ONLINE (MASTER)|4 |01:26:00 |111.111.111.111
    |orientdb-master-2 |ONLINE|GratefulDeadConcerts=ONLINE (MASTER)|4 |01:25:13 |222.222.222.222
    |orientdb-master-1*|ONLINE|GratefulDeadConcerts=ONLINE (MASTER)|6 |01:24:46 |333.333.333.333

This is a good sign, because if the servers and their databases are online, chances are high that the cluster is functioning properly. You’ll also see a similar output but with more information when you connect to one of the database from the console below. You can hit `CTRL+C` to stop this output for now.

To verify data replication on new data across the cluster, you’ll need to generate some data on one server, then see if it gets replicated to the others. **On one of the master servers** , launch the console using the following pair of commands:

    cd /opt/orientdb/bin
    sudo ./console.sh

The last command should give the following output while launching the console, changing your prompt to `orientdb>`.

    OutputOrientDB console v.2.2.17 (build UNKNOWN@r98dbf8a2b8d43e4af09f1b12fa7ae9dfdbd23f26; 2017-02-02 07:01:26+0000) www.orientdb.com
    Type 'help' to display all the supported commands.
    Installing extensions for GREMLIN language v.2.6.0
    
    orientdb> 

Now connect to the OrientDB server instance. This command merely connects to the instance of OrientDB running on the server using the **root** user account, not to any database. The password is the one you created in step 3:

    connect remote:localhost root root-password

Next, let’s create a database named `CallMeMaybe`:

    create database remote:localhost/CallMeMaybe root root-password plocal

If the database was created successfully, you’ll connect to it and your prompt should change to match.

**Note** : If you get an error that says “Permission denied” or similar, check the permissions on the `/opt/orientdb/databases` directory. The account creating the database from the console should have read and write permissions to that folder. You can learn more in [this Linux permissions tutorial](an-introduction-to-linux-permissions).

Right now, `CallMeMaybe` is still just an empty database. Just to have some test data, let’s add a class to it:

    create class Artist

Then insert a record into it:

    insert into Artist (id, name, age) values (01,'sammy', 35)

Check that the new database now holds the record you just inserted:

    select id, age, name from Artist

If all went well, the output should be similar to this:

    Output+----+----+----+------+
    |# |id |age |name |
    +----+----+----+------+
    |0 |1 |35 |sammy |
    +----+----+----+------+
    
    1 item(s) found. Query executed in 0.216 sec(s).

You can exit the console now.

    exit

The final step of this verification process is to log into a different node in the cluster and try to query the new database to see if the data has propagated successfully.

    ssh sammy@another_orientdb_server_ip

Launch the console as before.

    cd /opt/orientdb/bin
    sudo ./console.sh

Connect to the database as **admin** , which is a default user and password of any new OrientDB database.

    connect remote:localhost/CallMeMaybe admin admin

Perform the same query as before.

    select id, age, name from Artist 

The output should be the same one from the previous server — as it should, because your’re performing queries across a cluster of servers. You can now exit the console.

    exit

This confirms that your three-node cluster is functioning correctly.

## Conclusion

You’ve set up a OrientDB cluster made up of three nodes serving different roles (master or replica). With a setup like this, changing the number of nodes is easy. What will be even easier, more fun, and less tasking would be use [a configuration management tool like Ansible](configuration-management-101-writing-ansible-playbooks) to automate the deployment of a cluster like this.

For now, you might want to do is [consult this OrientDB security guide](how-to-secure-your-orientdb-database-on-ubuntu-16-04) to learn how to secure each node in the cluster. Official documentation on OrientDB administration is available at the [project’s documentation site](http://orientdb.com/docs/last/Administration.html), and for more information on Hazelcast, visit [the Hazelcast documentation](https://hazelcast.org/mastering-hazelcast).
