---
author: Anatoliy Dimitrov
date: 2016-05-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-16-04
---

# How To Install and Configure Elasticsearch on Ubuntu 16.04

## Introduction

[Elasticsearch](http://www.elasticsearch.org/) is a platform for distributed search and analysis of data in real time. Its popularity is due to its ease of use, powerful features, and scalability.

Elasticsearch supports RESTful operations. This means that you can use HTTP methods (GET, POST, PUT, DELETE, etc.) in combination with an HTTP URI (`/collection/entry`) to manipulate your data. The intuitive RESTful approach is both developer- and user-friendly, which is one of the reasons for Elasticsearch’s popularity.

Elasticsearch is a free and open source software with a solid company behind it: Elastic. This combination makes it suitable for use in anywhere from personal testing to corporate integration.

This article will introduce you to Elasticsearch and show you how to install, configure, secure, and start using it.

## Prerequisites

Before following this tutorial, you will need:

- A Ubuntu 16.04 Droplet set up by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04), including creating a sudo non-root user.

- The Oracle JDK 8 installed, which you can do by following the “Installing the Oracle JDK” section of [this Java installation article](how-to-install-java-with-apt-get-on-ubuntu-16-04)

Except otherwise noted, all of the commands that require root privileges in this tutorial should be run as a non-root user with sudo privileges.

## Step 1 — Downloading and Installing Elasticsearch

Elasticsearch can be downloaded directly from [elastic.co](https://www.elastic.co/downloads/elasticsearch) in `zip`, `tar.gz`, `deb`, or `rpm` packages. For Ubuntu, it’s best to use the `deb` (Debian) package which will install everything you need to run Elasticsearch.

First, update your package index.

    sudo apt-get update

Download the latest Elasticsearch version, which is 2.3.1 at the time of writing.

    wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/deb/elasticsearch/2.3.1/elasticsearch-2.3.1.deb

Then install it in the usual Ubuntu way with `dpkg`.

    sudo dpkg -i elasticsearch-2.3.1.deb

This results in Elasticsearch being installed in `/usr/share/elasticsearch/` with its configuration files placed in `/etc/elasticsearch` and its init script added in `/etc/init.d/elasticsearch`.

To make sure Elasticsearch starts and stops automatically with the server, add its init script to the default runlevels.

    sudo systemctl enable elasticsearch.service

Before starting Elasticsearch for the first time, please check the next section about the recommended minimum configuration.

## Step 2 — Configuring Elasticsearch

Now that Elasticsearch and its Java dependencies have been installed, it is time to configure Elasticsearch. The Elasticsearch configuration files are in the `/etc/elasticsearch` directory. There are two files:

- `elasticsearch.yml` configures the Elasticsearch server settings. This is where all options, except those for logging, are stored, which is why we are mostly interested in this file. 

- `logging.yml` provides configuration for logging. In the beginning, you don’t have to edit this file. You can leave all default logging options. You can find the resulting logs in `/var/log/elasticsearch` by default.

The first variables to customize on any Elasticsearch server are `node.name` and `cluster.name` in `elasticsearch.yml`. As their names suggest, `node.name` specifies the name of the server (node) and the cluster to which the latter is associated.

If you don’t customize these variable, a `node.name` will be assigned automatically in respect to the Droplet hostname. The `cluster.name` will be automatically set to the name of the default cluster.

The `cluster.name` value is used by the auto-discovery feature of Elasticsearch to automatically discover and associate Elasticsearch nodes to a cluster. Thus, if you don’t change the default value, you might have unwanted nodes, found on the same network, in your cluster.

To start editing the main `elasticsearch.yml` configuration file with `nano` or your favorite text editor.

    sudo nano /etc/elasticsearch/elasticsearch.yml

Remove the `#` character at the beginning of the lines for `cluster.name` and `node.name` to uncomment them, and then update their values. Your first configuration changes in the `/etc/elasticsearch/elasticsearch.yml` file should look like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    cluster.name: mycluster1
    node.name: "My First Node"
    . . .

These the minimum settings you can start with using Elasticsearch. However, it’s recommended to continue reading the configuration part for more thorough understanding and fine-tuning of Elasticsearch.

One especially important setting of Elasticsearch is the role of the server, which is either master or slave. _Master servers_ are responsible for the cluster health and stability. In large deployments with a lot of cluster nodes, it’s recommended to have more than one dedicated master. Typically, a dedicated master will not store data or create indexes. Thus, there should be no chance of being overloaded, by which the cluster health could be endangered.

_Slave servers_ are used as workhorses which can be loaded with data tasks. Even if a slave node is overloaded, the cluster health shouldn’t be affected seriously, provided there are other nodes to take additional load.

The setting which determines the role of the server is called `node.master`. By default, a node is a master. If you have only one Elasticsearch node, you should leave this option to the default `true` value because at least one master is always needed. Alternatively, if you wish to configure the node as a slave, assign a `false` value to the variable `node.master` like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    node.master: false
    . . .

Another important configuration option is `node.data`, which determines whether a node will store data or not. In most cases this option should be left to its default value (`true`), but there are two cases in which you might wish not to store data on a node. One is when the node is a dedicated master" as previously mentioned. The other is when a node is used only for fetching data from nodes and aggregating results. In the latter case the node will act up as a _search load balancer_.

Again, if you have only one Elasticsearch node, you should not change this value. Otherwise, to disable storing data locally, specify `node.data` as `false` like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    node.data: false
    . . .

In larger Elasticsearch deployments with many nodes, two other important options are `index.number_of_shards` and `index.number_of_replicas`. The first determines how many pieces, or _shards_, the index will be split into. The second defines the number of replicas which will be distributed across the cluster. Having more shards improves the indexing performance, while having more replicas makes searching faster.

By default, the number of shards is 5 and the number of replicas is 1. Assuming that you are still exploring and testing Elasticsearch on a single node, you can start with only one shard and no replicas. Thus, their values should be set like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    index.number_of_shards: 1
    index.number_of_replicas: 0
    . . .

One final setting which you might be interested in changing is `path.data`, which determines the path where data is stored. The default path is `/var/lib/elasticsearch`. In a production environment, it’s recommended that you use a dedicated partition and mount point for storing Elasticsearch data. In the best case, this dedicated partition will be a separate storage media which will provide better performance and data isolation. You can specify a different `path.data` path by specifying it like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    path.data: /media/different_media
    . . .

Once you make all the changes, save and exit the file. Now you can start Elasticsearch for the first time.

    sudo systemctl start elasticsearch

Give Elasticsearch a few to fully start before you try to use it. Otherwise, you may get errors about not being able to connect.

## Step 3 — Securing Elasticsearch

By default, Elasticsearch has no built-in security and can be controlled by anyone who can access the HTTP API. This is not always a security risk because Elasticsearch listens only on the loopback interface (i.e., `127.0.0.1`) which can be accessed only locally. Thus, no public access is possible and your Elasticsearch is secure enough as long as all server users are trusted or this is a dedicated Elasticsearch server.

Still, if you wish to harden the security, the first thing to do is to enable authentication. Authentication is provided by the commercial [Shield plugin](https://www.elastic.co/downloads/shield). Unfortunately, this plugin is not free but there is a free 30 day trial you can use to test it. Its official page has excellent installation and configuration instructions. The only thing you may need to know in addition is that the path to the Elasticsearch plugin installation manager is `/usr/share/elasticsearch/bin/plugin`.

If you don’t want to use the commercial plugin but you still have to allow remote access to the HTTP API, you can at least limit the network exposure with Ubuntu’s default firewall, UFW (Uncomplicated Firewall). By default, UFW is installed but not enabled. If you decide to use it, follow these steps:

First, create a rule to allow any needed services. You will need at least SSH allowed so that you can log in the server. To allow world-wide access to SSH, whitelist port 22.

    sudo ufw allow 22

Then allow access to the default Elasticsearch HTTP API port (TCP 9200) for the trusted remote host, e.g.`TRUSTED_IP`, like this:

    sudo ufw allow from TRUSTED_IP to any port 9200

Only after that enable UFW with the command:

    sudo ufw enable

Finally, check the status of UFW with the following command:

    sudo ufw status

If you have specified the rules correctly, the output should look like this:

    Output of java -versionStatus: active
    
    To Action From
    -- ------ ----
    9200 ALLOW TRUSTED_IP
    22 ALLOW Anywhere
    22 (v6) ALLOW Anywhere (v6)

Once you have confirmed UFW is enabled and protecting Elasticsearch port 9200, then you can allow Elasticsearch to listen for external connections. To do this, open the `elasticsearch.yml` configuration file again.

    sudo nano /etc/elasticsearch/elasticsearch.yml

Find the line that contains `network.bind_host`, uncomment it by removing the `#` character at the beginning of the line, and change the value to `0.0.0.0` so it looks like this:

/etc/elasticsearch/elasticsearch.yml

    . . .
    network.host: 0.0.0.0
    . . .

We have specified `0.0.0.0` so that Elasticsearch listens on all interfaces and bound IPs. If you want it to listen only on a specific interface, you can specify its IP in place of `0.0.0.0`.

To make the above setting take effect, restart Elasticsearch with the command:

    sudo systemctl restart elasticsearch

After that try to connect from the trusted host to Elasticsearch. If you cannot connect, make sure that the UFW is working and the `network.host` variable has been correctly specified.

## Step 4 — Testing Elasticsearch

By now, Elasticsearch should be running on port 9200. You can test it with `curl`, the command line client-side URL transfers tool and a simple GET request.

    curl -X GET 'http://localhost:9200'

You should see the following response:

    Output of curl{
      "name" : "My First Node",
      "cluster_name" : "mycluster1",
      "version" : {
        "number" : "2.3.1",
        "build_hash" : "bd980929010aef404e7cb0843e61d0665269fc39",
        "build_timestamp" : "2016-04-04T12:25:05Z",
        "build_snapshot" : false,
        "lucene_version" : "5.5.0"
      },
      "tagline" : "You Know, for Search"
    }

If you see a response similar to the one above, Elasticsearch is working properly. If not, make sure that you have followed correctly the installation instructions and you have allowed some time for Elasticsearch to fully start.

To perform a more thorough check of Elasticsearch execute the following command:

    curl -XGET 'http://localhost:9200/_nodes?pretty'

In the output from the above command you can see and verify all the current settings for the node, cluster, application paths, modules, etc.

## Step 5 — Using Elasticsearch

To start using Elasticsearch, let’s add some data first. As already mentioned, Elasticsearch uses a RESTful API, which responds to the usual CRUD commands: **c** reate, **r** ead, **u** pdate, and **d** elete. For working with it, we’ll use again `curl`.

You can add your first entry with the command:

    curl -X POST 'http://localhost:9200/tutorial/helloworld/1' -d '{ "message": "Hello World!" }'

You should see the following response:

    Output{"_index":"tutorial","_type":"helloworld","_id":"1","_version":1,"_shards":{"total":2,"successful":1,"failed":0},"created":true}

With `cuel`, we have sent an HTTP POST request to the Elasticsearch server. The URI of the request was `/tutorial/helloworld/1` with several parameters:

- `tutorial` is the index of the data in Elasticsearch.
- `helloworld` is the type.
- `1` is the id of our entry under the above index and type.

You can retrieve this first entry with an HTTP GET request.

    curl -X GET 'http://localhost:9200/tutorial/helloworld/1'

The result should look like:

    Output{"_index":"tutorial","_type":"helloworld","_id":"1","_version":1,"found":true,"_source":{ "message": "Hello World!" }}

To modify an existing entry, you can use an HTTP PUT request.

    curl -X PUT 'localhost:9200/tutorial/helloworld/1?pretty' -d '
    {
      "message": "Hello People!"
    }'

Elasticsearch should acknowledge successful modification like this:

    Output{
      "_index" : "tutorial",
      "_type" : "helloworld",
      "_id" : "1",
      "_version" : 2,
      "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
      },
      "created" : false
    }

In the above example we have modified the `message` of the first entry to “Hello People!”. With that, the version number has been automatically increased to `2`.

You may have noticed the extra argument `pretty` in the above request. It enables human readable format so that you can write each data field on a new row. You can also “prettify” your results when retrieving data and get much nicer output like this:

    curl -X GET 'http://localhost:9200/tutorial/helloworld/1?pretty'

Now the response will be in a much better format:

    Output{
      "_index" : "tutorial",
      "_type" : "helloworld",
      "_id" : "1",
      "_version" : 2,
      "found" : true,
      "_source" : {
        "message" : "Hello People!"
      }
    }

So far we have added to and queried data in Elasticsearch. To learn about the other operations please check [the API documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html).

## Conclusion

That’s how easy it is to install, configure, and begin using Elasticsearch. Once you have played enough with manual queries, your next task will be to start using it from your applications.
