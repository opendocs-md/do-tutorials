---
author: Eduardo Silva
date: 2016-12-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-centralize-your-docker-logs-with-fluentd-and-elasticsearch-on-ubuntu-16-04
---

# How To Centralize Your Docker Logs with Fluentd and ElasticSearch on Ubuntu 16.04

### An Article from [Fluentd](https://www.fluentd.org/)

## Introduction

As you roll Docker containers into production, you’ll find an increasing need to persist logs somewhere less ephemeral than containers. Docker comes with a native logging driver for Fluentd, making it easy to collect those logs and route them somewhere else, like [Elasticsearch](https://www.elastic.co/), so you can analyze the data.

[Fluentd](http://www.fluentd.org/) is an open-source data collector designed to unify your logging infrastructure. It brings operations engineers, application engineers, and data engineers together by making it simple and scalable to collect and store logs.

Fluentd has four key features that makes it suitable to build clean, reliable logging pipelines:

- **Unified Logging with JSON:** Fluentd tries to structure data as JSON as much as possible. This allows Fluentd to unify all facets of processing log data: collecting, filtering, buffering, and outputting logs across multiple sources and destinations. The downstream data processing is much easier with JSON, since it has enough structure to be accessible without forcing rigid schemas.
- **Pluggable Architecture:** Fluentd has a flexible plugin system that allows the community to extend its functionality. Over 300 community-contributed plugins connect dozens of data sources to dozens of data outputs, manipulating the data as needed. By using plugins, you can make better use of your logs right away.
- **Minimum Resources Required:** A data collector should be lightweight so that it runs comfortably on a busy machine. Fluentd is written in a combination of C and Ruby, and requires minimal system resources. The vanilla instance runs on 30-40MB of memory and can process 13,000 events/second/core.
- **Built-in Reliability:** Data loss should never happen. Fluentd supports memory- and file-based buffering to prevent inter-node data loss. Fluentd also supports robust failover and can be set up for high availability.

In this tutorial, you’ll learn how to install Fluentd and configure it to collect logs from Docker containers. You’ll then stream the data to another container running Elasticsearch on the same Ubuntu 16.04 server and query the logs.

## Prerequisites

To complete this tutorial, you will need the following:

- One 4GB Ubuntu 16.04 server set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall. This satisfies Elasticsearch’s memory requirements.
- Docker installed on your server by following [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04). Be sure to configure Docker to run as a non-root user.

## Step 1 — Installing Fluentd

The most common way of installing [Fluentd](http://www.fluentd.org) is via the `td-agent` package. [Treasure Data](https://www.treasuredata.com), the original author of Fluentd, packages Fluentd with a self-contained Ruby runtime so you don’t need to set up a Ruby environment to run Fluentd. They also provide a script to get the latest `td-agent` package that configures a repository and installs the package for you.

Log into your server as your non-root user:

    ssh sammy@your_server_ip

Then install `td-agent` using the script provided by Treasure Data. First, download the script:

    \curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent2.sh -o install-td-agent.sh

If you want to audit the script, open it with your text editor:

    nano install-td-agent.sh

Once you’re comfortable with the script’s contents, run the script to install `td-agent`:

    sh install-td-agent.sh 

Once the installation finishes, start `td-agent`:

    sudo systemctl start td-agent

Check the logs to make sure it was installed successfully:

    tail /var/log/td-agent/td-agent.log

You’ll see output similar to the following:

    Output port 8888
      </source>
      <source>
        @type debug_agent
        bind 127.0.0.1
        port 24230
      </source>
    </ROOT>
    2016-12-02 19:45:31 +0000 [info]: listening fluent socket on 0.0.0.0:24224
    2016-12-02 19:45:31 +0000 [info]: listening dRuby uri="druby://127.0.0.1:24230" object="Engine"

Next, install the Elasticsearch plugin for Fluentd using the `td-agent-gem` command:

    sudo td-agent-gem install fluent-plugin-elasticsearch

**Note:** Alternately, Fluentd is available as a Ruby gem and can be installed with `gem install fluentd`. If you already have a Ruby environment configured, you can install Fluentd and the Elasticsearch plugin using the `gem` command:

    gem install fluentd --no-rdoc --no-ri
    gem install fluentd-plugin-elasticsearch --no-rdoc --no-ri

Fluentd is now up and running with the default configuration. Next, we’ll configure Fluentd so we can listen for Docker events and deliver them to an Elasticsearch instance.

## Step 2 — Configuring Fluentd

Fluentd needs to know where to gather the information from, and where to deliver it. You define these rules in the Fluentd configuration file located at `/etc/td-agent/td-agent.conf`.

Open this file in your text editor:

    sudo nano /etc/td-agent/td-agent.conf 

Remove the contents of the file. You’ll write your own rules from scratch in this tutorial.

You define sources of information in the `source` section. Add this configuration to the file:

/etc/td-agent/td-agent.conf

    <source>
      @type forward
      port 24224
    </source>

This defines the source as `forward`, which is the Fluentd protocol that runs on top of TCP and will be used by Docker when sending the logs to Fluentd.

When the log records come in,, they will have some extra associated fields, including `time`, `tag`, `message`, `container_id`, and a few others. You use the information in the `_tag_` field to decide where Fluentd should send that data. This is called _data routing_.

To configure this, define a `match` section that matches the contents of the `tag` field and route it appropriately. Add this configuration to the file:

/etc/td-agent/td-agent.conf

    <match docker.**>
      @type elasticsearch
      logstash_format true
      host 127.0.0.1
      port 9200
      flush_interval 5s
    </match>

This rule says that every record with a tag prefixed with `docker.` will be send to Elasticsearch, which is running on `127.0.0.1` on port `9200`. The `flush_interval` tells Fluentd how often it should records to Elasticsearch.

For more details about buffering and flushing please refer to the [buffer plugin](http://docs.fluentd.org/articles/buffer-plugin-overview) overview documentation section.

Once you save the new configuration file, restart the `td-agent` service so the changes are applied:

    sudo systemctl restart td-agent

Now that Fluentd is configured properly for our purposes, let’s install Elasticsearch to capture our logs from Fluentd.

## Step 3 — Starting the Elasticsearch Container

We’ll use Docker to run our instance of Elasticsearch, since it’s faster than configuring one ourselves. We’ll use the [Elasticsearch Docker image](https://hub.docker.com/_/elasticsearch/) to create our container. In order to use this image, increase the value of `max_map_count` on your Docker host as follows:

    sudo sysctl -w vm.max_map_count=262144

Then execute this command to download the Elasticsearch image and start the container:

    docker run -d -p 9200:9200 -p 9300:9300 elasticsearch

The image will download and the Elasticsearch container will start. Make sure that the container is running properly by checking the Docker processes and looking for the container:

    docker ps

You should see output like this:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    76e96943491f elasticsearch "/docker-entrypoint.s" About a minute ago Up 51 seconds 0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp gigantic_hawking

If the container isn’t listed, start it again without the `-d` switch so the container runs in the foreground. Run the command `docker run -p 9200:9200 -p 9300:9300 elasticsearch` and look for any specific error messages. The most likely errors you’ll run into are issues with not having enough system memory, or that the `max_map_count` value on your Docker host is too low. Check all of the steps in this tutorial to ensure you didn’t miss anything and try again.

Now that Elasticsearch is running in the container, let’s generate some logs and ingest them into Fluentd.

## Step 4 — Generating Logs from a Docker Container

With Docker, you can treat logs as a stream of data through the standard output (`STDOUT`) and error (`STDERR`) interfaces. When you start a Docker application, just instruct Docker to flush the logs using the native Fluentd logging driver. The Fluentd service will then receive the logs and send them to Elasticsearch.

Test this out by starting a Bash command inside a Docker container like this:

    docker run --log-driver=fluentd ubuntu /bin/echo 'Hello world'

This will print the message `Hello world` to the standard output, but it will also be caught by the Docker Fluentd driver and delivered to the Fluentd service you configured earlier. After about five seconds, the records will be flushed to Elasticsearch. You configured this interval in the `match` section of your Fluentd configuration file.

This is enough to get the logs over to Elasticsearch, but you may want to take a look at the [official documentation](https://docs.docker.com/engine/admin/logging/fluentd/) for more details about the options you can use with Docker to manage the Fluentd driver.

Finally, let’s confirm that Elasticsearch is receiving the events. Use `curl` to send a query to Elasticsearch:

    curl -XGET 'http://localhost:9200/_all/_search?q=*'

The output will contain events that look like this:

    {"took":2,"timed_out":false,"_shards":{"total":1,"successful":1,"failed":0},"hits":{"total":1,"max_score":1.0,"hits":[{"_index":"logstash-2016.12.02","_type":"fluentd","_id":"AVQwUi-UHBhoWtOFQKVx","_score":1.0,"_source":{"container_id":"d16af3ad3f0d361a1764e9a63c6de92d8d083dcc502cd904155e217f0297e525","container_name":"/nostalgic_torvalds","source":"stdout","log":"Hello world","@timestamp":"2016-12-02T14:59:26-06:00"}}]}}

You may have quite a few events logged depending on your setup. A single event should start with `{"took":` and end with a timestamp. It’ll also contain some extra information associated with the source container. As this output shows, Elasticsearch is receiving data from our Docker container.

## Conclusion

Collecting logs from Docker containers is just one way to use Fluentd. Many users come to Fluentd to build a logging pipeline that does both real-time log search and long-term storage. This architecture takes advantage of Fluentd’s ability to copy data streams and output them to multiple storage systems. For example, you can use Elasticsearch for real-time search, but use MongoDB or Hadoop for batch analytics and long-term storage.

Web applications produce a lot of logs, and they are often formatted arbitrarily and stored on the local file system. This can present problems for two reasons. First, the logs are difficult to parse programmatically, requiring lots of [regular expressions](an-introduction-to-regular-expressions), and thus are not very accessible to those who wish to understand user behavior through statistical analysis, review results of A/B testing, or performing fraud detection.

Second, the logs are not accessible in real-time because the text logs are bulk-loaded into storage systems. Worse, if the server’s disk gets corrupted between bulk-loads, the logs become lost or corrupted.

Fluentd solves both of these problems by providing logger libraries for various programming languages with a consistent API. Each logger sends a record containing the timestamp, a tag, and a JSON-formatted event to Fluentd, like the one you saw in this tutorial. There are [logger libraries](http://www.fluentd.org/datasources) for Ruby, Node.js, Go, Python, Perl, PHP, Java and C++. This lets applications “fire and forget”; the logger sends the data to Fluentd asynchronously, which in turn buffers the logs before shipping them off to backend systems.

There are plenty of other useful things you can do with Fluentd and Elasticsearch. You may find the following links interesting:

- [Unified Logging Layer](http://www.fluentd.org/blog/unified-logging-layer) to learn more about how the logging layer works.
- [Basic Elasticsearch operations](how-to-interact-with-data-in-elasticsearch-using-crud-operation) to learn more about how to work with Elasticsearch.
- [Adding a dashboard](elasticsearch-fluentd-and-kibana-open-source-log-search-and-visualization) so you can visualize your logs.
- [Fluentd + Elasticsearch for Kubernetes](http://blog.raintown.org/2014/11/logging-kubernetes-pods-using-fluentd.html) by Satnam Singh, Kubernetes committer.
