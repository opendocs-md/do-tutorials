---
author: Anatoliy Dimitrov
date: 2015-10-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-14-04
---

# How To Install and Configure Elasticsearch on Ubuntu 14.04

## Introduction

[Elasticsearch](http://www.elasticsearch.org/) is a platform for distributed search and analysis of data in real time. Its popularity is due to its ease of use, powerful features, and scalability.

Elasticsearch supports RESTful operations. This means that you can use HTTP methods (GET, POST, PUT, DELETE, etc.) in combination with an HTTP URI (/collection/entry) to manipulate your data. The intuitive RESTful approach is both developer and user friendly, which is one of the reasons for Elasticsearch’s popularity.

Elasticsearch is a free and open source software with a solid company behind it — Elastic. This combination makes it suitable for use in anywhere from personal testing to corporate integration.

This article will introduce you to Elasticsearch and show you how to install, configure, and start using it.

## Prerequisites

Before following this tutorial, please make sure you complete the following prerequisites:

- A Ubuntu 14.04 Droplet
- A non-root sudo user. Check out [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) for details.

Except otherwise noted, all of the commands that require root privileges in this tutorial should be run as a non-root user with sudo privileges.

### Assumptions

This tutorial assumes that your servers are using a VPN like the one described here: [How To Use Ansible and Tinc VPN to Secure Your Server Infrastructure](how-to-use-ansible-and-tinc-vpn-to-secure-your-server-infrastructure). This will provide private network functionality regardless of the physical network that your servers are using.

If you are using a shared private network, such as [DigitalOcean Private Networking](digitalocean-private-networking-faq), then this security feature will already be enabled for servers on the same team or account in the same region. This is particularly important when using Elasticsearch, as it doesn’t have security built into its HTTP interface.

## Step 1 — Installing Java

First, you will need a Java Runtime Environment (JRE) on your Droplet because Elasticsearch is written in the Java programming language. Elasticsearch requires Java 7 or higher. Elasticsearch recommends Oracle JDK version 1.8.0\_73, but the native Ubuntu OpenJDK native package for the JRE works as well.

This step shows you how to install both versions so you can decide which is best for you.

### Installing OpenJDK

The native Ubuntu OpenJDK native package for the JRE is free, well-supported, and automatically managed through the Ubuntu APT installation manager.

Before installing OpenJDK with APT, update the list of available packages for installation on your Ubuntu Droplet by running the command:

    sudo apt-get update

After that, you can install OpenJDK with the command:

    sudo apt-get install openjdk-7-jre

To verify your JRE is installed and can be used, run the command:

    java -version

The result should look like this:

    Output of java -versionjava version "1.7.0_79"
    OpenJDK Runtime Environment (IcedTea 2.5.6) (7u79-2.5.6-0ubuntu1.14.04.1)
    OpenJDK 64-Bit Server VM (build 24.79-b02, mixed mode)

### Installing Java 8

When you advance in using Elasticsearch and you start looking for better Java performance and compatibility, you may opt to install Oracle’s proprietary Java (Oracle JDK 8).

Add the Oracle Java PPA to apt:

    sudo add-apt-repository -y ppa:webupd8team/java

Update your apt package database:

    sudo apt-get update

Install the latest stable version of Oracle Java 8 with this command (and accept the license agreement that pops up):

    sudo apt-get -y install oracle-java8-installer

Lastly, verify it is installed:

    java -version

## Step 2 — Downloading and Installing Elasticsearch

Elasticsearch can be downloaded directly from [elastic.co](https://www.elastic.co/downloads/elasticsearch) in zip, tar.gz, deb, or rpm packages. For Ubuntu, it’s best to use the deb (Debian) package which will install everything you need to run Elasticsearch.

At the time of this writing, the latest Elasticsearch version is 1.7.2. Download it in a directory of your choosing with the command:

    wget https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.2.deb

Then install it in the usual Ubuntu way with the `dpkg` command like this:

    sudo dpkg -i elasticsearch-1.7.2.deb

**Tip:** If you want the latest released version of Elasticsearch, go to [elastic.co](https://www.elastic.co/downloads/elasticsearch) to find the link, and then use `wget` to download it to your Droplet. Be sure to download the deb package.

This results in Elasticsearch being installed in `/usr/share/elasticsearch/` with its configuration files placed in `/etc/elasticsearch` and its init script added in `/etc/init.d/elasticsearch`.

To make sure Elasticsearch starts and stops automatically with the Droplet, add its init script to the default runlevels with the command:

    sudo update-rc.d elasticsearch defaults

## Step 3 — Configuring Elastic

Now that Elasticsearch and its Java dependencies have been installed, it is time to configure Elasticsearch.

The Elasticsearch configuration files are in the `/etc/elasticsearch` directory. There are two files:

- `elasticsearch.yml` — Configures the Elasticsearch server settings. This is where all options, except those for logging, are stored, which is why we are mostly interested in this file. 

- `logging.yml` — Provides configuration for logging. In the beginning, you don’t have to edit this file. You can leave all default logging options. You can find the resulting logs in `/var/log/elasticsearch` by default.

The first variables to customize on any Elasticsearch server are `node.name` and `cluster.name` in `elasticsearch.yml`. As their names suggest, `node.name` specifies the name of the server (node) and the cluster to which the latter is associated.

If you don’t customize these variable, a `node.name` will be assigned automatically in respect to the Droplet hostname. The `cluster.name` will be automatically set to the name of the default cluster.

The `cluster.name` value is used by the auto-discovery feature of Elasticsearch to automatically discover and associate Elasticsearch nodes to a cluster. Thus, if you don’t change the default value, you might have unwanted nodes, found on the same network, in your cluster.

To start editing the main `elasticsearch.yml` configuration file:

    sudo nano /etc/elasticsearch/elasticsearch.yml

Remove the `#` character at the beginning of the lines for `node.name` and `cluster.name` to uncomment them, and then change their values. Your first configuration changes in the `/etc/elasticsearch/elasticsearch.yml` file should look like this:

/etc/elasticsearch/elasticsearch.yml

    ...
    node.name: "My First Node"
    cluster.name: mycluster1
    ...

Another important setting is the role of the server, which could be either “master” or “slave”. “Masters” are responsible for the cluster health and stability. In large deployments with a lot of cluster nodes, it’s recommended to have more than one dedicated “master.” Typically, a dedicated “master” will not store data or create indexes. Thus, there should be no chance of being overloaded, by which the cluster health could be endangered.

“Slaves” are used as “workhorses” which can be loaded with data tasks. Even if a “slave” node is overloaded, the cluster health shouldn’t be affected seriously, provided there are other nodes to take additional load.

The setting which determines the role of the server is called `node.master`. If you have only one Elasticsearch node, you should leave this option commented out so that it keeps its default value of `true` — i.e. the sole node should be also a master. Alternatively, if you wish to configure the node as a slave, remove the `#` character at the beginning of the `node.master` line, and change the value to `false`:

/etc/elasticsearch/elasticsearch.yml

    ...
    node.master: false
    ...

Another important configuration option is `node.data`, which determines whether a node will store data or not. In most cases this option should be left to its default value (`true`), but there are two cases in which you might wish not to store data on a node. One is when the node is a dedicated “master,” as we have already mentioned. The other is when a node is used only for fetching data from nodes and aggregating results. In the latter case the node will act up as a “search load balancer”.

Again, if you have only one Elasticsearch node, you should leave this setting commented out so that it keeps the default `true` value. Otherwise, to disable storing data locally, uncomment the following line and change the value to `false`:

/etc/elasticsearch/elasticsearch.yml

    ...
    node.data: false
    ...

Two other important options are `index.number_of_shards` and `index.number_of_replicas`. The first determines into how many pieces (shards) the index will be split into. The second defines the number of replicas which will be distributed across the cluster. Having more shards improves the indexing performance, while having more replicas makes searching faster.

Assuming that you are still exploring and testing Elasticsearch on a single node, it’s better to start with only one shard and no replicas. Thus, their values should be set to the following (make sure to remove the `#` at the beginning of the lines):

/etc/elasticsearch/elasticsearch.yml

    ...
    index.number_of_shards: 1
    index.number_of_replicas: 0
    ...

One final setting which you might be interested in changing is `path.data`, which determines the path where data is stored. The default path is `/var/lib/elasticsearch`. In a production environment it’s recommended that you use a dedicated partition and mount point for storing Elasticsearch data. In the best case, this dedicated partition will be a separate storage media which will provide better performance and data isolation. You can specify a different `path.data` path by uncommenting the `path.data` line and changing its value:

/etc/elasticsearch/elasticsearch.yml

    ...
    path.data: /media/different_media
    ...

Once you make all the changes, please save and exit the file. Now you can start Elasticsearch for the first time with the command:

    sudo service elasticsearch start

Please allow at least 10 seconds for Elasticsearch to fully start before you are able to use it. Otherwise, you may get errors about not being able to connect.

## Step 4 — Securing Elastic

Elasticsearch has no built-in security and can be controlled by anyone who can access the HTTP API. This section is not a comprehensive guide to securing Elasticsearch. Take whatever measures are necessary to prevent unauthorized access to it and the server/virtual machine on which it is running. Consider using [iptables](iptables-essentials-common-firewall-rules-and-commands) to further secure your system.

The first security tweak is to prevent public access. To remove public access edit the file `elasticsearch.yml`:

    sudo nano /etc/elasticsearch/elasticsearch.yml

Find the line that contains `network.bind_host`, uncomment it by removing the `#` character at the beginning of the line, and change the value to `localhost` so it looks like this:

/etc/elasticsearch/elasticsearch.yml

    ...
    network.bind_host: localhost
    ...

**Warning:** Because Elasticsearch doesn’t have any built-in security, it is very important that you do not set this to any IP address that is accessible to any servers that you do not control or trust. Do not bind Elasticsearch to a public or **shared private network** IP address!  
  
Also, for additional security you can disable dynamic scripts which are used to evaluate custom expressions. By crafting a custom malicious expression, an attacker might be able to compromise your environment.

To disable custom expressions, add the following line is at the end of the `/etc/elasticsearch/elasticsearch.yml` file:

/etc/elasticsearch/elasticsearch.yml

    ...
    script.disable_dynamic: true
    ...

## Step 5 — Testing

By now, Elasticsearch should be running on port 9200. You can test it with curl, the command line client-side URL transfers tool and a simple GET request like this:

    curl -X GET 'http://localhost:9200'

You should see the following response:

    Output of curl{
      "status" : 200,
      "name" : "Harry Leland",
      "cluster_name" : "elasticsearch",
      "version" : {
        "number" : "1.7.2",
        "build_hash" : "e43676b1385b8125d647f593f7202acbd816e8ec",
        "build_timestamp" : "2015-09-14T09:49:53Z",
        "build_snapshot" : false,
        "lucene_version" : "4.10.4"
      },
      "tagline" : "You Know, for Search"
    }

If you see a response similar to the one above, Elasticsearch is working properly. If not, make sure that you have followed correctly the installation instructions and you have allowed some time for Elasticsearch to fully start.

## Step 6 — Using Elasticsearch

To start using Elasticsearch, let’s add some data first. As already mentioned, Elasticsearch uses a RESTful API, which responds to the usual CRUD commands: Create, Read, Update, and Delete. For working with it, we’ll use again curl.

You can add your first entry with the command:

    curl -X POST 'http://localhost:9200/tutorial/helloworld/1' -d '{ "message": "Hello World!" }'

You should see the following response:

    Output{"_index":"tutorial","_type":"helloworld","_id":"1","_version":1,"created":true}

With curl, we have sent an HTTP POST request to the Elasticseach server. The URI of the request was `/tutorial/helloworld/1`. It’s important to understand the parameters here:

- `tutorial` is the index of the data in Elasticsearch.
- `helloworld` is the type.
- `1` is the id of our entry under the above index and type.

You can retrieve this first entry with an HTTP GET request like this:

    curl -X GET 'http://localhost:9200/tutorial/helloworld/1'

The result should look like:

    Output{"_index":"tutorial","_type":"helloworld","_id":"1","_version":1,"found":true,"_source":{ "message": "Hello World!" }}

To modify an existing entry you can use an HTTP PUT request like this:

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
      "_source":{ "message": "Hello World!" }
    }

So far we have added to and queried data in Elasticsearch. To learn about the other operations please check [the API documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html).

## Conclusion

That’s how easy it is to install, configure, and begin using Elasticsearch. Once you have played enough with manual queries, your next task will be to start using it from your applications.
