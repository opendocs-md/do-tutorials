---
author: Mitchell Anicas
date: 2014-07-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging
---

# Adding Logstash Filters To Improve Centralized Logging

## Introduction

Logstash is a powerful tool for centralizing and analyzing logs, which can help to provide and overview of your environment, and to identify issues with your servers. One way to increase the effectiveness of your ELK Stack (Elasticsearch, Logstash, and Kibana) setup is to collect important application logs and structure the log data by employing filters, so the data can be readily analyzed and query-able. We will build our filters around “grok” patterns, that will parse the data in the logs into useful bits of information.

This guide is a sequel to the [How To Install Elasticsearch, Logstash, and Kibana 4 on Ubuntu 14.04](how-to-install-elasticsearch-logstash-and-kibana-4-on-ubuntu-14-04) tutorial, and focuses primarily on adding Logstash filters for various common application logs.

## Prerequisites

To follow this tutorial, you must have a working Logstash server that is receiving logs from a shipper such as Filebeat. If you do not have Logstash set up to receive logs, here is the tutorial that will get you started: [How To Install Elasticsearch, Logstash, and Kibana 4 on Ubuntu 14.04](how-to-install-elasticsearch-logstash-and-kibana-4-on-ubuntu-14-04).

### ELK Server Assumptions

- Logstash is installed in `/opt/logstash`
- Your Logstash configuration files are located in `/etc/logstash/conf.d`
- You have an input file named `02-beats-input.conf`
- You have an output file named `30-elasticsearch-output.conf`

You may need to create the `patterns` directory by running this command on your Logstash Server:

    sudo mkdir -p /opt/logstash/patterns
    sudo chown logstash: /opt/logstash/patterns

### Client Server Assumptions

- You have Filebeat configured, on each application server, to send syslog/auth.log to your Logstash server (as in the [Set Up Filebeat section](how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-14-04#set-up-filebeat-(add-client-servers)) of the prerequisite tutorial)

If your setup differs, simply adjust this guide to match your environment.

## About Grok

Grok works by parsing text patterns, using regular expressions, and assigning them to an identifier.

The syntax for a grok pattern is `%{PATTERN:IDENTIFIER}`. A Logstash filter includes a sequence of grok patterns that matches and assigns various pieces of a log message to various identifiers, which is how the logs are given structure.

To learn more about grok, visit the [Logstash grok page](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html), and the [Logstash Default Patterns listing](https://github.com/logstash-plugins/logstash-patterns-core/blob/master/patterns/grok-patterns).

## How To Use This Guide

Each main section following this will include the additional configuration details that are necessary to gather and filter logs for a given application. For each application that you want to log and filter, you will have to make some configuration changes on both the client server (Filebeat) and the Logstash server.

### Logstash Patterns Subsection

If there is a Logstash Patterns subsection, it will contain grok patterns that can be added to a new file in `/opt/logstash/patterns` on the Logstash Server. This will allow you to use the new patterns in Logstash filters.

### Logstash Filter Subsection

The Logstash Filter subsections will include a filter that can can be added to a new file, between the input and output configuration files, in `/etc/logstash/conf.d` on the Logstash Server. The filter determine how the Logstash server parses the relevant log files. Remember to restart the Logstash service after adding a new filter, to load your changes.

### Filebeat Prospector Subsection

Filebeat Prospectors are used specify which logs to send to Logstash. Additional prospector configurations should be added to the `/etc/filebeat/filebeat.yml` file directly after existing prospectors in the `prospectors` section:

Prospector Examples

    filebeat:
      # List of prospectors to fetch data.
      prospectors:
        -
          - /var/log/secure
          - /var/log/messages
          document_type: syslog
        -
          paths:
            - /var/log/app/*.log
          document_type: app-access
    ...

In the above example, the red highlighted lines represent a Prospector that sends all of the `.log` files in `/var/log/app/` to Logstash with the `app-access` type. After any changes are made, Filebeat must be reloaded to put any changes into effect.

Now that you know how to use this guide, the rest of the guide will show you how to gather and filter application logs!

## Application: Nginx

### Logstash Patterns: Nginx

Nginx log patterns are not included in Logstash’s default patterns, so we will add Nginx patterns manually.

On your **ELK server** , create a new pattern file called `nginx`:

    sudo vi /opt/logstash/patterns/nginx

Then insert the following lines:

Nginx Grok Pattern

    NGUSERNAME [a-zA-Z\.\@\-\+_%]+
    NGUSER %{NGUSERNAME}
    NGINXACCESS %{IPORHOST:clientip} %{NGUSER:ident} %{NGUSER:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:verb} %{URIPATHPARAM:request} HTTP/%{NUMBER:httpversion}" %{NUMBER:response} (?:%{NUMBER:bytes}|-) (?:"(?:%{URI:referrer}|-)"|%{QS:referrer}) %{QS:agent}

Save and exit. The `NGINXACCESS` pattern parses, and assigns the data to various identifiers (e.g. `clientip`, `ident`, `auth`, etc.).

Next, change the ownership of the pattern file to `logstash`:

    sudo chown logstash: /opt/logstash/patterns/nginx

### Logstash Filter: Nginx

On your **ELK server** , create a new filter configuration file called `11-nginx-filter.conf`:

    sudo vi /etc/logstash/conf.d/11-nginx-filter.conf

Then add the following filter:

Nginx Filter

    filter {
      if [type] == "nginx-access" {
        grok {
          match => { "message" => "%{NGINXACCESS}" }
        }
      }
    }

Save and exit. Note that this filter will attempt to match messages of `nginx-access` type with the `NGINXACCESS` pattern, defined above.

Now restart Logstash to reload the configuration:

    sudo service logstash restart

### Filebeat Prospector: Nginx

On your **Nginx servers** , open the `filebeat.yml` configuration file for editing:

    sudo vi /etc/filebeat/filebeat.yml

Add the following Prospector in the `filebeat` section to send the Nginx access logs as type `nginx-access` to your Logstash server:

Nginx Prospector

        -
          paths:
            - /var/log/nginx/access.log
          document_type: nginx-access

Save and exit. Reload Filebeat to put the changes into effect:

    sudo service filebeat restart

Now your Nginx logs will be gathered and filtered!

## Application: Apache HTTP Web Server

Apache’s log patterns are included in the default Logstash patterns, so it is fairly easy to set up a filter for it.

**Note:** If you are using a RedHat variant, such as CentOS, the logs are located at `/var/log/httpd` instead of `/var/log/apache2`, which is used in the examples.

### Logstash Filter: Apache

On your **ELK server** , create a new filter configuration file called `12-apache.conf`:

    sudo vi /etc/logstash/conf.d/12-apache.conf

Then add the following filter:

Apache Filter

    filter {
      if [type] == "apache-access" {
        grok {
          match => { "message" => "%{COMBINEDAPACHELOG}" }
        }
      }
    }

Save and exit. Note that this filter will attempt to match messages of `apache-access` type with the `COMBINEDAPACHELOG` pattern, one the default Logstash patterns.

Now restart Logstash to reload the configuration:

    sudo service logstash restart

### Filebeat Prospector: Apache

On your **Apache servers** , open the `filebeat.yml` configuration file for editing:

    sudo vi /etc/filebeat/filebeat.yml

Add the following Prospector in the `filebeat` section to send the Apache logs as type `apache-access` to your Logstash server:

Apache Prospector

        -
          paths:
            - /var/log/apache2/access.log
          document_type: apache-access

Save and exit. Reload Filebeat to put the changes into effect:

    sudo service filebeat restart

Now your Apache logs will be gathered and filtered!

## Conclusion

It is possible to collect and parse logs of pretty much any type. Try and write your own filters and patterns for other log files.

Feel free to comment with filters that you would like to see, or with patterns of your own!

If you aren’t familiar with using Kibana, check out this tutorial: [How To Use Kibana Visualizations and Dashboards](how-to-use-kibana-dashboards-and-visualizations).
