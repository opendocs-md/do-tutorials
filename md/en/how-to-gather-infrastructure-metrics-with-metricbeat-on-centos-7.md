---
author: Vadym Kalsin
date: 2019-03-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-metricbeat-on-centos-7
---

# How To Gather Infrastructure Metrics with Metricbeat on CentOS 7

_The author selected the [Computer History Museum](https://www.brightfunds.org/organizations/computer-history-museum) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Metricbeat](https://www.elastic.co/products/beats/metricbeat), which is one of several [Beats](https://www.elastic.co/products/beats) that helps send various types of server data to an [Elastic Stack](https://www.elastic.co/products/) server, is a lightweight data shipper that, once installed on your servers, periodically collects system-wide and per-process CPU and memory statistics and sends the data directly to your Elasticsearch deployment. This shipper replaced the earlier [Topbeat](https://www.elastic.co/guide/en/beats/topbeat/current/_overview.html) in version 5.0 of the Elastic Stack.

Other Beats currently available from Elastic are:

- [Filebeat](https://www.elastic.co/products/beats/filebeat): collects and ships log files.
- [Packetbeat](https://www.elastic.co/products/beats/packetbeat): collects and analyzes network data.
- [Winlogbeat](https://www.elastic.co/products/beats/winlogbeat): collects Windows event logs.
- [Auditbeat](https://www.elastic.co/products/beats/auditbeat): collects Linux audit framework data and monitors file integrity.
- [Heartbeat](https://www.elastic.co/products/beats/heartbeat): monitors services for their availability with active probing.

In this tutorial, you will use Metricbeat to forward local system metrics like CPU/memory/disk usage and network utilization from a CentOS 7 server to another server of the same kind with the Elastic Stack installed. With this shipper, you will gather the basic metrics that you need to get the current state of your server.

## Prerequisites

To follow this tutorial, you will need:

- Two CentOS 7 servers set up by following the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) guide, including a non-root user with sudo privileges and a firewall set up with `firewalld`. To set up `firewalld`, follow the [“Configuring a Basic Firewall”](additional-recommended-steps-for-new-centos-7-servers#configuring-a-basic-firewall) section of the [Additional Recommended Steps for New CentOS 7 Servers](additional-recommended-steps-for-new-centos-7-servers) tutorial. On one server, you will download the Elastic Stack; this tutorial will refer to this as the “Elastic Stack server.” The Elastic Stack server, which in this tutorial will have 4GB of RAM and 2 CPUs, will monitor your second server. This second server will be referred to as the “second CentOS server.”
- The Elastic Stack installed on the Elastic Stack server by following the tutorial [How To Install Elasticsearch, Logstash, and Kibana (Elastic Stack) on CentOS 7](how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-centos-7).

**Note** : When installing the Elastic Stack, you must use the same version across the entire stack. In this tutorial, you will use the latest versions of the entire stack, which are, at the time of this writing, Elasticsearch 6.7.0, Kibana 6.7.0, Logstash 6.7.0, and Metricbeat 6.7.0.

## Step 1 — Configuring Elasticsearch to Listen for Traffic on an External IP

The tutorial [How To Install Elasticsearch, Logstash, and Kibana (Elastic Stack) on CentOS 7](how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-centos-7) restricted Elasticsearch access to the `localhost` only. In practice, this is rare, since you will often need to monitor many hosts. In this step, you will configure the Elastic Stack components to interact with the external IP address.

Log in to your Elastic Stack server as your non-root user:

    ssh sammy@Elastic_Stack_server_ip

Use your preferred text editor to edit Elasticsearch’s main configuration file, `elasticsearch.yml`. This tutorial will use `vi`:

    sudo vi /etc/elasticsearch/elasticsearch.yml

Find the following section and modify it so that Elasticsearch listens on all interfaces. Enter insert mode by pressing `i`, then add the following highlighted item:

/etc/elasticsearch/elasticsearch.yml

    ...
    network.host: 0.0.0.0
    ...

The address `0.0.0.0` is assigned specific meanings in a number of contexts. In this case, `0.0.0.0` means “any IPv4 address at all.”

When you’re finished, press `ESC` to leave insert mode, then `:wq` and `ENTER` to save and exit the file. To learn more about the text editor vi and its successor Vim, check out our [Installing and Using the Vim Text Editor on a Cloud Server](installing-and-using-the-vim-text-editor-on-a-cloud-server#managing-documents) tutorial. After you have saved and exited the file, restart the Elasticsearch service with `systemctl` to apply the new settings:

    sudo systemctl restart elasticsearch

Now, allow access to the Elasticsearch port from your second CentOS server. In order to configure access coming from specific IP addresses or subnets, use the [_rich rule_](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html) functionality of `firewalld`:

    sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="second_centos_server_ip/32" port protocol="tcp" port="9200" accept'

Rich rules allow you to create more complex and customizable `firewalld` rules to gain greater control over your firewall. In this command, you are adding a rule that accepts `ipv4` traffic from the `source`, which you have set as the IP address of the second CentOS server, to `port` `9200` of your Elastic Stack server.

Next, reload `firewalld` to activate the new rule:

    sudo firewall-cmd --reload

Repeat these commands for each of your servers if you have more than two. If your servers are on the same [network](https://en.wikipedia.org/wiki/Subnetwork), you can allow access using one rule for all hosts on the network. To do this, you need to replace the `/32` after the IP address with a lower value, for example `/24`.

Next, test the connection. Log in to your second CentOS server as your non-root user:

    ssh sammy@second_centos_server_ip

Use the `curl` command to test the connection to the Elastic Stack server:

    curl Elastic_Stack_server_ip:9200

You’ll receive output similar to the following:

    Output{
      "name" : "tl5Is5f",
      "cluster_name" : "elasticsearch",
      "cluster_uuid" : "W9AcSNWHQ3mYs2uE8odklA",
      "version" : {
        "number" : "6.7.0",
        "build_flavor" : "default",
        "build_type" : "rpm",
        "build_hash" : "3bd3e59",
        "build_date" : "2019-03-06T15:16:26.864148Z",
        "build_snapshot" : false,
        "lucene_version" : "7.6.0",
        "minimum_wire_compatibility_version" : "5.6.0",
        "minimum_index_compatibility_version" : "5.0.0"
      },
      "tagline" : "You Know, for Search"
    }
    

Now that you know the connection works, you are ready to send metrics to your Elastic Stack server.

## Step 2 — Installing and Configuring Metricbeat on the Elastic Stack Server

In the next two steps, you will first install Metricbeat on the Elastic Stack server and import all the needed data, then install and configure the client on the second CentOS server.

Log into your Elastic Stack server as your non-root user:

    ssh sammy@Elastic_Stack_server_ip

Since you previously set up the Elasticsearch repositories in the prerequisite, you only need to install Metricbeat:

    sudo yum install metricbeat

Once the installation is complete, load the index template into Elasticsearch. An [_Elasticsearch index_](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html) is a collection of documents that have similar characteristics. Specific names identify each index, which Elasticsearch will use to refer to the indexes when performing various operations. Your Elasticsearch server will automatically apply the index template when you create a new index.

To load the template, use the following command:

    sudo metricbeat setup --template -E 'output.elasticsearch.hosts=["localhost:9200"]'

You will see the following output:

    OutputLoaded index template

Metricbeat comes packaged with example Kibana dashboards, visualizations, and searches for visualizing Metricbeat data in Kibana. Before you can use the dashboards, you need to create the index pattern and load the dashboards into Kibana.

To load the templates, use the following command:

    sudo metricbeat setup -e -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601

You will see output that looks like this:

    Output...
    2019-03-20T09:51:32.096Z INFO instance/beat.go:281 Setup Beat: metricbeat; Version: 6.7.0
    2019-03-20T09:51:32.136Z INFO add_cloud_metadata/add_cloud_metadata.go:323 add_cloud_metadata: hosting provider type detected as digitalocean, metadata={"instance_id":"133130541","provider":"digitalocean","region":"fra1"}
    2019-03-20T09:51:32.137Z INFO elasticsearch/client.go:165 Elasticsearch url: http://localhost:9200
    2019-03-20T09:51:32.137Z INFO [publisher] pipeline/module.go:110 Beat name: elastic
    2019-03-20T09:51:32.138Z INFO elasticsearch/client.go:165 Elasticsearch url: http://localhost:9200
    2019-03-20T09:51:32.140Z INFO elasticsearch/client.go:721 Connected to Elasticsearch version 6.7.0
    2019-03-20T09:51:32.148Z INFO template/load.go:130 Template already exists and will not be overwritten.
    2019-03-20T09:51:32.148Z INFO instance/beat.go:894 Template successfully loaded.
    Loaded index template
    Loading dashboards (Kibana must be running and reachable)
    2019-03-20T09:51:32.149Z INFO elasticsearch/client.go:165 Elasticsearch url: http://localhost:9200
    2019-03-20T09:51:32.150Z INFO elasticsearch/client.go:721 Connected to Elasticsearch version 6.7.0
    2019-03-20T09:51:32.151Z INFO kibana/client.go:118 Kibana url: http://localhost:5601
    2019-03-20T09:51:56.209Z INFO instance/beat.go:741 Kibana dashboards successfully loaded.
    Loaded dashboards

Now you can start Metricbeat:

    sudo systemctl start metricbeat

To make Metricbeat start automatically at boot from now on, use the `enable` command:

    sudo systemctl enable metricbeat

Metricbeat will begin shipping your system stats into Elasticsearch.

To verify that Elasticsearch is indeed receiving this data, query the Metricbeat index with this command:

    curl -XGET 'http://localhost:9200/metricbeat-*/_search?pretty'

You will see an output that looks similar to this:

    Output...
    {
      "took" : 3,
      "timed_out" : false,
      "_shards" : {
        "total" : 1,
        "successful" : 1,
        "skipped" : 0,
        "failed" : 0
      },
      "hits" : {
        "total" : 108,
        "max_score" : 1.0,
        "hits" : [
          {
            "_index" : "metricbeat-6.7.0-2019.03.20",
            "_type" : "doc",
            "_id" : "A4mU8GgBKrpxEYMLjJZt",
            "_score" : 1.0,
            "_source" : {
              "@timestamp" : "2019-03-20T09:54:52.481Z",
              "metricset" : {
                "name" : "network",
                "module" : "system",
                "rtt" : 125
              },
              "event" : {
                "dataset" : "system.network",
                "duration" : 125260
              },
              "system" : {
                "network" : {
                  "in" : {
                    "packets" : 59728,
                    "errors" : 0,
                    "dropped" : 0,
                    "bytes" : 736491211
                  },
                  "out" : {
                    "dropped" : 0,
                    "packets" : 31630,
                    "bytes" : 8283069,
                    "errors" : 0
                  },
                  "name" : "eth0"
                }
              },
              "beat" : {
                "version" : "6.7.0",
                "name" : "elastic",
                "hostname" : "elastic"
              },
    ...

The line `"total" : 108,` indicates that Metricbeat has found 108 search results for this specific metric. Any number of search results indicates that Metricbeat is working; if your output shows 0 total hits, you will need to review your setup for errors. If you received the expected output, continue to the next step, in which you will install Metricbeat on the second CentOS server.

## Step 3 — Installing and Configuring Metricbeat on the Second CentOS Server

Perform this step on all CentOS servers from which you want to send metrics to your Elastic Stack server. If you also have Ubuntu servers, you can install Metricbeat by following Step 3 of [How To Gather Infrastructure Metrics with Metricbeat on Ubuntu 18.04](how-to-gather-infrastructure-metrics-with-metricbeat-on-ubuntu-18-04#step-3-%E2%80%94-installing-and-configuring-metricbeat-on-the-second-ubuntu-server).

Log into your second CentOS server as your non-root user:

    ssh sammy@second_centos_server_ip

The Elastic Stack components are not available through the yum package manager by default, but you can install them by adding Elastic’s package repository.

All of the Elastic Stack’s packages are signed with the Elasticsearch signing key in order to protect your system from package spoofing. Your package manager will trust packages that have been authenticated using the key. In this step, you will import the Elasticsearch public GPG key and add the Elastic package source list in order to install Metricbeat.

To begin, run the following command to download and install the Elasticsearch public signing key:

    sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

Next, add the Elastic repository. Use your preferred text editor to create the file `elasticsearch.repo` in the `/etc/yum.repos.d/` directory:

    sudo vi /etc/yum.repos.d/elasticsearch.repo

To provide yum with the information it needs to download and install the components of the Elastic Stack, enter insert mode by pressing `i` and add the following lines to the file:

/etc/yum.repos.d/elasticsearch.repo

    [elasticsearch-6.x]
    name=Elasticsearch repository for 6.x packages
    baseurl=https://artifacts.elastic.co/packages/6.x/yum
    gpgcheck=1
    gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
    enabled=1
    autorefresh=1
    type=rpm-md

When you’re finished, save and close the file.

Next, install Metricbeat with this command:

    sudo yum install metricbeat

Once Metricbeat is finished installing, configure it to connect to Elasticsearch. Open its configuration file, `metricbeat.yml`:

    sudo vi /etc/metricbeat/metricbeat.yml

**Note:** Metricbeat’s configuration file is in YAML format, which means that indentation is very important! Be sure that you do not add any extra spaces as you edit this file.

Metricbeat supports numerous outputs, but you’ll usually only send events directly to Elasticsearch or to Logstash for additional processing. Find the following section and update the IP address:

/etc/metricbeat/metricbeat.yml

    #-------------------------- Elasticsearch output ------------------------------
    output.elasticsearch:
      # Array of hosts to connect to.
      hosts: ["Elastic_Stack_server_ip:9200"]
    
    ...

Save and close the file.

You can extend the functionality of Metricbeat with [modules](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-modules.html). In this tutorial, you will use the [`system`](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-module-system.html) module, which allows you to monitor your server’s stats like CPU/memory/disk usage and network utilization.

In this case, the `system` module is enabled by default. You can see a list of enabled and disabled modules by running:

    sudo metricbeat modules list

You will see a list similar to the following:

    OutputEnabled:
    system
    
    Disabled:
    aerospike
    apache
    ceph
    couchbase
    docker
    dropwizard
    elasticsearch
    envoyproxy
    etcd
    golang
    graphite
    haproxy
    http
    jolokia
    kafka
    kibana
    kubernetes
    kvm
    logstash
    memcached
    mongodb
    munin
    mysql
    nginx
    php_fpm
    postgresql
    prometheus
    rabbitmq
    redis
    traefik
    uwsgi
    vsphere
    windows
    zookeeper

You can see the parameters of the module in the `/etc/metricbeat/modules.d/system.yml` configuration file. In the case of this tutorial, you do not need to change anything in the configuration. The default metricsets are `cpu`, `load`, `memory`, `network`, `process`, and `process_summary`. Each module has one or more metricset. A metricset is the part of the module that fetches and structures the data. Rather than collecting each metric as a separate event, metricsets retrieve a list of multiple related metrics in a single request to the remote system.

Now you can start and enable Metricbeat:

    sudo systemctl start metricbeat
    sudo systemctl enable metricbeat

Repeat this step on all servers where you want to collect metrics. After that, you can proceed to the next step in which you will see how to navigate through some of Kibana’s dashboards.

## Step 4 — Exploring Kibana Dashboards

In this step, you will take a look at Kibana, the web interface that you installed in the Prerequisites section.

In a web browser, go to the FQDN or public IP address of your Elastic Stack server. After entering the login credentials you defined in Step 2 of [the Elastic Stack tutorial](how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-centos-7#step-2-%E2%80%94-installing-and-configuring-the-kibana-dashboard), you will see the Kibana homepage:

![Kibana Homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64850/Metricbeat_Kibana_Landing_Page.png)

Click the **Discover** link in the left-hand navigation bar. On the **Discover** page, select the predefined **meticbeat-** \* index pattern to see Metricbeat data. By default, this will show you all of the log data over the last 15 minutes. You will find a histogram and some metric details:

![Discover page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64850/Metribeat_Data.png)

Here, you can search and browse through your metrics and also customize your dashboard. At this point, though, there won’t be much in there because you are only gathering system stats from your servers.

Use the left-hand panel to navigate to the **Dashboard** page and search for the **Metricbeat System** dashboard. Once there, you can search for the sample dashboards that come with Metricbeat’s `system` module.

For example, you can view brief information about all your hosts:

![Syslog Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64850/Metricbeat_Metrics_Overview.png)

You can also click on the host name and view more detailed information:

![Sudo Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64850/Metricbeat_Host_Metrics.png)

Kibana has many other features, such as graphing and filtering, so feel free to explore.

## Conclusion

In this tutorial, you’ve installed Metricbeat and configured the Elastic Stack to collect and analyze system metrics. Metricbeat comes with internal [modules](https://www.elastic.co/guide/en/beats/metricbeat/current/metricbeat-modules.html) that collect metrics from services like Apache, Nginx, Docker, MySQL, PostgreSQL, and more. Now you can collect and analyze the metrics of your applications by simply turning on the modules you need.

If you want to understand more about server monitoring, check out [An Introduction to Metrics, Monitoring, and Alerting](an-introduction-to-metrics-monitoring-and-alerting) and [Putting Monitoring and Alerting into Practice](putting-monitoring-and-alerting-into-practice).
