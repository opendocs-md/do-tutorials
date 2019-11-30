---
author: Kiyoto Tamura
date: 2014-08-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/elasticsearch-fluentd-and-kibana-open-source-log-search-and-visualization
---

# Elasticsearch, Fluentd, and Kibana: Open Source Log Search and Visualization

### An Article from [Fluentd](https://www.fluentd.org/)

## Overview

Elasticsearch, Fluentd, and Kibana (EFK) allow you to collect, index, search, and visualize log data. This is a great alternative to the proprietary software Splunk, which lets you get started for free, but requires a paid license once the data volume increases.

This tutorial shows you how to build a log solution using three open source software components: [Elasticsearch](http://www.elasticsearch.org), [Fluentd](https://www.fluentd.org/) and [Kibana](http://www.kibana.org).

### Prerequisites

- Droplet with **Ubuntu 14.04**
- User with [sudo](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) privileges

## Installing and Configuring Elasticsearch

### Getting Java

Elasticsearch requires Java, so the first step is to install Java.

    sudo apt-get update
    sudo apt-get install openjdk-7-jre-headless --yes

Check that Java was indeed installed. Run:

    java -version

The output should be as follows:

    java version "1.7.0_55"
    OpenJDK Runtime Environment (IcedTea 2.4.7) (7u55-2.4.7-1ubuntu1)
    OpenJDK 64-Bit Server VM (build 24.51-b03, mixed mode)

### Getting Elasticsearch

Next, download and install Elasticsearch’s deb package as follows.

    sudo wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.2.2.deb
    sudo dpkg -i elasticsearch-1.2.2.deb

### Securing Elasticsearch

Up to version 1.2, Elasticsearch’s dynamic scripting capability was enabled by default. Since this tutorial sets up the Kibana dashboard to be accessed from the public Internet, let’s disable dynamic scripting by appending the following line at the end of `/etc/elasticsearch/elasticsearch.yml`:

    script.disable_dynamic: true

### Starting Elasticsearch

Start running Elasticsearch with the following command.

    sudo service elasticsearch start

## Installing and Configuring Kibana

### Getting Kibana

Move to your home directory:

    cd ~

We will download Kibana as follows:

    curl -L https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz | tar xzf -
    sudo cp -r kibana-3.1.0 /usr/share/

### Configuring Kibana

Since Kibana will use port 80 to talk to Elasticsearch as opposed to the default port 9200, Kibana’s `config.js` must be updated.

Open `/usr/share/kibana-3.1.0/config.js` and look for the following line:

    elasticsearch: "http://"+window.location.hostname+":9200",

and replace it with the following line:

    elasticsearch: "http://"+window.location.hostname+":80",

## Installing and Configuring Nginx (Proxy Server)

We will use Nginx as a proxy server to allow access to the dashboard from the Public Internet (with basic authentication).

Install Nginx as follows:

    sudo apt-get install nginx --yes

Kibana provides a good default nginx.conf, which we will modify slightly.

First, install the configuration file as follows:

    wget https://assets.digitalocean.com/articles/fluentd/nginx.conf
    sudo cp nginx.conf /etc/nginx/sites-available/default

Note: The original file is from this [Kibana GitHub repository](https://github.com/elasticsearch/kibana/raw/master/sample/nginx.conf).

Then, edit `/etc/nginx/sites-available/default` as follows (changes marked in red):

    #
    # Nginx proxy for Elasticsearch + Kibana
    #
    # In this setup, we are password protecting the saving of dashboards. You may
    # wish to extend the password protection to all paths.
    #
    # Even though these paths are being called as the result of an ajax request, the
    # browser will prompt for a username/password on the first request
    #
    # If you use this, you'll want to point config.js at http://FQDN:80/ instead of
    # http://FQDN:9200
    #
    server {
     listen *:80 ;
     server_name localhost;
     access_log /var/log/nginx/kibana.log;
     location / {
       root /usr/share/kibana-3.1.0;
       index index.html index.htm;
     }

Finally, restart nginx as follows:

    $ sudo service nginx restart

Now, you should be able to see the generic Kibana dashboard at your server’s IP address or domain, using your favorite browser.

![Kibana Welcome](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_welcome.png)

## Installing and Configuring Fluentd

Finally, let’s install [Fluentd](https://www.fluentd.org). We will use td-agent, the packaged version of Fluentd, built and maintained by [Treasure Data](http://www.treasuredata.com).

### Installing Fluentd via the td-agent package

Install Fluentd with the following commands:

    wget http://packages.treasuredata.com/2/ubuntu/trusty/pool/contrib/t/td-agent/td-agent_2.0.4-0_amd64.deb
    sudo dpkg -i td-agent_2.0.4-0_amd64.deb

### Installing Plugins

We need a couple of plugins:

1. out\_elasticsearch: this plugin lets Fluentd to stream data to Elasticsearch.
2. out_record_reformer: this plugin lets us process data into a more useful format.

The following commands install both plugins (the first apt-get is for out\_elasticsearch: it requires `make` and `libcurl`)

    sudo apt-get install make libcurl4-gnutls-dev --yes
    sudo /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-elasticsearch
    sudo /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-record-reformer

Next, we configure Fluentd to listen to syslog messages and send them to Elasticsearch. Open `/etc/td-agent/td-agent.conf` and add the following lines at the top of the file:

    <source>
     type syslog
     port 5140
     tag system
    </source>
    <match system.*.*>
     type record_reformer
     tag elasticsearch
     facility ${tag_parts[1]}
     severity ${tag_parts[2]}
    </match>
    <match elasticsearch>
     type copy
     <store>
       type stdout
     </store>
     <store>
     type elasticsearch
     logstash_format true
     flush_interval 5s #debug
     </store>
    </match>

### Starting Fluentd

Start Fluentd with the following command:

    sudo service td-agent start

## Forwarding rsyslog Traffic to Fluentd

Ubuntu 14.04 ships with rsyslogd. It needs to be reconfigured to forward syslog events to the port Fluentd listens to (port 5140 in this example).

Open `/etc/rsyslog.conf` (you need to `sudo`) and add the following line at the top

    *.* @127.0.0.1:5140

After saving and exiting the editor, restart rsyslogd as follows:

    sudo service rsyslog restart

## Setting Up Kibana Dashboard Panels

Kibana’s default panels are very generic, so it’s recommended to customize them. Here, we show two methods.

### Method 1: Using a Template

The Fluentd team offers an alternative Kibana configuration that works with this setup better than the default one. To use this alternative configuration, run the following command:

    wget -O default.json https://assets.digitalocean.com/articles/fluentd/default.json
    sudo cp default.json /usr/share/kibana-3.1.0/app/dashboards/default.json

Note: The original configuration file is from the author’s [GitHub gist](https://bit.ly/fluentd-kibana).

If you refresh your Kibana dashboard home page at your server’s URL, Kibana should now be configured to show histograms by syslog severity and facility, as well as recent log lines in a table.

### Method 2: Manually Configuring

Go to your server’s IP address or domain to view the Kibana dashboard.

![Kibana Welcome](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_welcome.png)

There are a couple of starter templates, but let’s choose the blank one called **Blank Dashboard: I’m comfortable configuring on my own** , shown at the bottom of the welcome text.

![Kibana Blank Template](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_blank.png)

Next, click on the **+ ADD A ROW** button on the right side of the dashboard. A configuration screen for a new row (a **row** consists of one or more panels) should show up. Enter a title, press the **Create Row** button, followed by **Save**. This creates a row.

![Kibana Row](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_row.png)

When an empty row is created, Kibana shows the prompt **Add panel to empty row** on the left. Click this button. It takes you to the configuration screen to add a new panel. Choose **histogram** from the dropdown menu. A histogram is a time chart; for more information, see [Kibana’s documentation](http://www.elasticsearch.org/guide/en/kibana/current/_histogram.html#_histogram).

![Kibana Histogram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_histogram.png)

There are many parameters to configure for a new histogram, but you can just scroll down and press the **Save** button. This creates a new panel.

![Kibana Histogram Details](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/fluentd/kibana_histogram_details.png)

## Further Information

For further information about configuring Kibana, please see the [Kibana documentation page](http://www.elasticsearch.org/guide/en/kibana/current/).
