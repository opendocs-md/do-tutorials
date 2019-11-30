---
author: Kevin Isaac
date: 2017-06-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-the-titan-graph-database-with-cassandra-and-elasticsearch-on-ubuntu-16-04
---

# How to Set Up the Titan Graph Database with Cassandra and ElasticSearch on Ubuntu 16.04

## Introduction

[Titan](http://titan.thinkaurelius.com/) is an open-source graph database that is highly scalable. A graph database is a type of NoSQL database where all data is stored as _nodes_ and _edges_. A graph database is suitable for applications that use highly connected data, where the relationship between data is an important part of the application’s functionality, like a social networking site. Titan is used for storing and querying high-volume data that is distributed across multiple machines. It can be configured to use any of the various available storage backends like Apache Cassandra, HBase and BerkeleyDB. This makes it easier to avoid vendor lock-in in the future if you need to change the data store.

In this tutorial, you’ll install Titan 1.0. Then, you will configure Titan to use Cassandra and ElasticSearch, both of which come bundled together with Titan. Cassandra acts as the datastore that holds the underlying data, while ElasticSearch, a free-text search engine, can be used to do some sophisticated search operations in the database. You will also create and query data from the database using Gremlin.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 16.04 server with at least 2 GB of RAM with a non-root user and a firewall. You can set this up by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- Oracle JDK 8 installed, which you can do by following the “Installing the Oracle JDK” section of [this Java installation article](how-to-install-java-with-apt-get-on-ubuntu-16-04).

## Step 1 — Downloading, Unpacking and Starting Titan

To download the Titan database, head over to [their downloads page](https://github.com/thinkaurelius/titan/wiki/Downloads). You will see two Titan distributions available for download. For this tutorial, we want **Titan 1.0.0 with Hadoop 1**. This is the stable release. Download it to your server with `wget`:

    wget http://s3.thinkaurelius.com/downloads/titan/titan-1.0.0-hadoop1.zip

Once the download is complete, unpack the zip file. The program to unzip files is not installed by default. Install it first:

    sudo apt-get install unzip

Then unzip Titan:

    unzip titan-1.0.0-hadoop1.zip

This creates a directory named `titan-1.0.0-hadoop`.

Let’s start Titan to make sure everything works. Change into the `titan-1.0.0-hadoop` directory and invoke the shell script to start Titan.

    cd titan-1.0.0-hadoop1
    ./bin/titan.sh start

You will see an output similar to this:

    OutputForking Cassandra...
    Running `nodetool statusthrift`... OK (returned exit status 0 and printed string "running").
    Forking Elasticsearch...
    Connecting to Elasticsearch (127.0.0.1:9300)...... OK (connected to 127.0.0.1:9300).
    Forking Gremlin-Server...
    Connecting to Gremlin-Server (127.0.0.1:8182)...... OK (connected to 127.0.0.1:8182).
    Run gremlin.sh to connect.

Titan depends on a bunch of other tools to work. So whenever Titan is started, Cassandra, ElasticSearch and Gremlin-Server are also started along with it.

You can check Titan’s status by running the following command.

    ./bin/titan.sh status

You’ll see this output:

    OutputGremlin-Server (org.apache.tinkerpop.gremlin.server.GremlinServer) is running with pid 7490
    Cassandra (org.apache.cassandra.service.CassandraDaemon) is running with pid 7077
    Elasticsearch (org.elasticsearch.bootstrap.Elasticsearch) is running with pid 7358

In the next step, you will see how to query the graph.

## Step 2 — Querying the Graph using Gremlin

[Gremlin](https://tinkerpop.apache.org/gremlin.html) is a _Graph Traversal Language_ which is used to query, analyze and manipulate Graph databases. Now that Titan is set up and started, you will use Gremlin to create and query nodes and edges from Titan.

To use Gremlin, open the Gremlin Console by issuing the following command.

    ./bin/gremlin.sh

You will see a response similar to this:

    Output \,,,/
             (o o)
    -----oOOo-(3)-oOOo-----
    plugin activated: tinkerpop.server
    plugin activated: tinkerpop.hadoop
    plugin activated: tinkerpop.utilities
    plugin activated: aurelius.titan
    plugin activated: tinkerpop.tinkergraph
    gremlin>

The Gremlin Console loads several plugins to support Titan and Gremlin-specific features.

First, instantiate the graph object. This object represents the graph that we are currently working on. It has a handful of methods that can help manage the graph like adding vertices, creating labels and handling transactions. Execute this command to instantiate the graph object:

    graph = TitanFactory.open('conf/titan-cassandra-es.properties')

You’ll see this output:

    Output==>standardtitangraph[cassandrathrift:[127.0.0.1]]

The output specifies the type of object returned by the `TitanFactory.open()` method, which is `standardtitangraph`. It also denotes which storage backend the graph uses (`cassandrathrift`), and that it is connected to via localhost (`127.0.0.1`).

The `open()` method creates a new Titan graph, or opens an existing one, using the configuration options present in the specified properties file. The configuration file contains the high-level configuration options like which storage backend to use, the caching backend, and a few other options. You can create a custom configuration file and use it instead of the defaults, which you’ll do in Step 3.

Once the command is executed, the graph object is instantiated and is stored in the `graph` variable. To have a look at all the available properties and methods for the graph object, type `graph.` , followed by the `TAB` key:

    gremlin> graph.
    addVertex( assignID( buildTransaction() close()                       
    closeTransaction( commit( compute( compute()                     
    configuration() containsEdgeLabel( containsPropertyKey( containsRelationType(         
    containsVertexLabel( edgeMultiQuery( edgeQuery( edges(                        
    features() getEdgeLabel( getOrCreateEdgeLabel( getOrCreatePropertyKey(       
    ...
    ...    

In graph databases, you query the data mostly by [traversing](https://en.wikipedia.org/wiki/Graph_traversal) it as opposed to retrieving records with joins and indices like in relational databases. In order to traverse a graph, we need a graph traversal source from the `graph` reference variable. The following command achieves this.

    g = graph.traversal()

You perform the traversals with this `g` variable. Let’s create a couple of vertices using that variable. Vertices are like rows in SQL. Each vertex has a vertex type or `label` and its associated properties, analogous to fields in SQL. Execute this command:

    sammy = g.addV(label, 'fish', 'name', 'Sammy', 'residence', 'The Deep Blue Sea').next()
    company = g.addV(label, 'company', 'name', 'DigitalOcean', 'website', 'www.digitalocean.com').next()

In this example, we have created two vertices with labels `fish` and `company` respectively. We have also defined two properties namely `name` and `residence` for the first vertex, and `name` and `website` for the second vertex. Let’s now access those vertices using the variables `sammy` and `company`.

For example, in order to list all the properties of the first vertex, execute the following command:

    g.V(sammy).properties()

The output will look something like this:

    Output==>vp[name->Sammy]
    ==>vp[residence->The Deep Blue Sea]

You can also add a new property to the vertex. Let’s add a color:

    g.V(sammy).property('color', 'blue')

Now, let’s define a relationship between those two vertices. This is achieved by creating an `edge` between them.

    company.addEdge('hasMascot', sammy, 'status', 'high')

This creates an edge between `sammy` and `company` with the label `hasMascot`, and a property named `status` with the value `high`.

Now, let’s get the mascot of the company:

    g.V(company).out('hasMascot')

This returns the outgoing vertices from the `company` vertex, and the edge between them labeled as `hasMascot`. We can also do the reverse and get the company associated with the mascot `sammy` like this:

    g.V(sammy).in('hasMascot')

These are a few basic Gremlin commands to get started with. To learn more, have a look at the descriptive [Apache Tinkerpop3 documentation](http://tinkerpop.apache.org/docs/3.0.0-incubating/).

Exit the Gremlin console by pressing `CTRL+C`.

Now let’s add some custom configuration options for Titan.

## Step 3 — Configuring Titan

Let’s create a new configuration file that you can use to define all your custom configuration options for Titan.

Titan has a pluggable storage layer; instead of handling data storage itself, Titan uses another database to handle it. Titan currently provides three options for storage database: Cassandra, HBase, and BerkeleyDB. In this tutorial, we will use Cassandra as the storage engine, as it is highly scalable and has high availability.

First, create the configuration file:

    nano conf/gremlin-server/custom-titan-config.properties

Add these lines to define what the storage backend is and where it is available. The storage backend is set to `cassandrathrift` which says that we are using Cassandra for storage with the [thrift](https://wiki.apache.org/cassandra/ThriftInterface) interface for Cassandra:

conf/gremlin-server/custom-titan-config.properties

    storage.backend=cassandrathrift
    storage.hostname=localhost

Then add these three lines to define which search backend to use. We’ll use `elasticsearch` as the search backend.

conf/gremlin-server/custom-titan-config.properties

    ...
    index.search.backend=elasticsearch
    index.search.hostname=localhost
    index.search.elasticsearch.client-only=true

The third line indicates that ElasticSearch is a thin client that stores no data. Setting it to `false` creates a regular ElasticSearch cluster node that may store data, which we don’t want now.

Finally, add this line to tell Gremlin Server the type of graph it is going to serve.

conf/gremlin-server/custom-titan-config.properties

    ...
    gremlin.graph=com.thinkaurelius.titan.core.TitanFactory

There are a number of example configuration files available in the `conf` directory that you can look into for reference.

Save the file and exit the editor.

We need to add this new configuration file to the Gremlin Server. Open up the Gremlin Server’s configuration file.

    nano conf/gremlin-server/gremlin-server.yaml

Navigate to the `graphs` section and find this line:

conf/gremlin-server/gremlin-server.yaml

    ..
     graph: conf/gremlin-server/titan-berkeleyje-server.properties}
    ..

Replace it with this:

conf/gremlin-server/gremlin-server.yaml

    ..
     graph: conf/gremlin-server/custom-titan-config.properties}
    ..

Save and exit the file.

Now restart Titan by stopping Titan and starting it again.

    ./bin/titan.sh stop
    ./bin/titan.sh start

Now that we’ve got a custom configuration, let’s configure Titan to run as a service.

## Step 4 — Managing Titan with Systemd

We should make sure that Titan starts automatically every time our server boots. If our server was accidentally restarted or had to be rebooted for any reason, we want Titan to start too.

To configure this, we’ll create a Systemd unit file for Titan so we can manage it.

To start, we create a file for our application inside the `/etc/systemd/system` directory with a `.service` extension:

    sudo nano /etc/systemd/system/titan.service

A unit file is made up of sections. The `[Unit]` section specifies the metadata and dependencies of our service, including a description of our service and when to start our service.

Add this configuration to the file:

/etc/systemd/system/titan.service

    [Unit]
    Description=The Titan database
    After=network.target

We specify that the service should start _after_ the networking target has been reached. In other words, we only start this service after the networking services are ready.

After the `[Unit]` section, we define the `[Service]` section where we specify how to start the service. Add this to the configuration file:

/etc/systemd/system/titan.service

    [Service]
    User=sammy
    Group=www-data
    Type=forking
    Environment="PATH=/home/sammy/titan-1.0.0-hadoop1/bin:/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
    WorkingDirectory=/home/sammy/titan-1.0.0-hadoop1/
    ExecStart=/home/sammy/titan-1.0.0-hadoop1/bin/titan.sh start
    ExecStop=/home/sammy/titan-1.0.0-hadoop1/bin/titan.sh stop

We first define the user and group that the service runs under. Then we define the type of service it’s going to be. The type is assumed to be `simple` by default. Since the startup script we are using to start Titan starts other child programs, we specify the service type as `forking`.

Then we specify the `PATH` environment variable, Titan’s working directory and the command to execute to start Titan. We assign the command to start Titan to the `ExecStart` variable.

The `ExecStop` variables define how the service should be stopped.

Finally, we add the `[Install]` section, which looks like this:

/etc/systemd/system/titan.service

    [Install]
    WantedBy=multi-user.target

The `Install` section lets you enable and disable the service. The `WantedBy` directive creates a directory called `multi-user.target` inside the `/etc/systemd/system` directory. Systemd will create a symbolic link of this unit file there. Disabling this service will remove this file from the directory.

Save the file, close the editor, and start the new service:

    sudo systemctl start titan

Then enable this service so that every time the server starts, Titan starts:

    sudo systemctl enable titan

You can check the status of Titan with the following command:

    sudo systemctl status titan

To learn more about unit files, read the tutorial [Understanding Systemd Units and Unit files](understanding-systemd-units-and-unit-files).

## Conclusion

You now have a basic Titan setup installed on your server. If you want a deeper look at the architecture of Titan, don’t hesitate to check out their [official documentation](http://s3.thinkaurelius.com/docs/titan/1.0.0/).

Now that you’ve set up Titan, you should learn more about Tinkerpop3 and Gremlin by looking at the [official documentation](http://tinkerpop.apache.org/docs/current/reference/).
