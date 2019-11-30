---
author: Mitchell Anicas
date: 2016-03-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging-logstash-forwarder
---

# Adding Logstash Filters To Improve Centralized Logging (Logstash Forwarder)

 **Note:** This tutorial is for an older version of the ELK stack setup that uses Logstash Forwarder instead of Filebeat. The latest version of this tutorial is available at [Adding Logstash Filters To Improve Centralized Logging](adding-logstash-filters-to-improve-centralized-logging).

## Introduction

Logstash is a powerful tool for centralizing and analyzing logs, which can help to provide and overview of your environment, and to identify issues with your servers. One way to increase the effectiveness of your Logstash setup is to collect important application logs and structure the log data by employing filters, so the data can be readily analyzed and query-able. We will build our filters around “grok” patterns, that will parse the data in the logs into useful bits of information.

This guide is a sequel to the [How To Install Elasticsearch 1.7, Logstash 1.5, and Kibana 4.1 (ELK Stack) on Ubuntu 14.04](how-to-install-elasticsearch-1-7-logstash-1-5-and-kibana-4-1-elk-stack-on-ubuntu-14-04) tutorial, and focuses primarily on adding filters for various common application logs.

## Prerequisites

To follow this tutorial, you must have a working Logstash server, and a way to ship your logs to Logstash. If you do not have Logstash set up, here is another tutorial that will get you started: [How To Install Elasticsearch 1.7, Logstash 1.5, and Kibana 4.1 (ELK Stack) on Ubuntu 14.04](how-to-install-elasticsearch-1-7-logstash-1-5-and-kibana-4-1-elk-stack-on-ubuntu-14-04).

Logstash Server Assumptions:

- Logstash is installed in `/opt/logstash`
- You are receiving logs from Logstash Forwarder on port 5000
- Your Logstash configuration files are located in `/etc/logstash/conf.d`
- You have an input file named `01-lumberjack-input.conf`
- You have an output file named `30-lumberjack-output.conf`

Logstash Forwarder Assumptions:

- You have Logstash Forwarder configured, on each application server, to send syslog/auth.log to your Logstash server (as in the [Set Up Logstash Forwarder](how-to-install-elasticsearch-logstash-and-kibana-4-on-ubuntu-14-04#set-up-logstash-forwarder-(add-client-servers)) section of the previous tutorial)

If your setup differs from what we assume, simply adjust this guide to match your environment.

You may need to create the `patterns` directory by running this command on your Logstash Server:

    sudo mkdir -p /opt/logstash/patterns
    sudo chown logstash:logstash /opt/logstash/patterns

## About Grok

Grok works by parsing text patterns, using regular expressions, and assigning them to an identifier.

The syntax for a grok pattern is `%{PATTERN:IDENTIFIER}`. A Logstash filter includes a sequence of grok patterns that matches and assigns various pieces of a log message to various identifiers, which is how the logs are given structure.

To learn more about grok, visit the [Logstash grok page](http://logstash.net/docs/1.4.2/filters/grok), and the [Logstash Default Patterns listing](https://github.com/elasticsearch/logstash/blob/v1.4.2/patterns/grok-patterns).

## How To Use This Guide

Each main section following this will include the additional configuration details that are necessary to gather and filter logs for a given application. For each application that you want to log and filter, you will have to make some configuration changes on both the application server, and the Logstash server.

### Logstash Forwarder Subsection

The Logstash Forwarder subsections pertain to the application server that is sending its logs. The additional _files_ configuration should be added to the `/etc/logstash-forwarder.conf` file directly after the following lines:

      "files": [
        {
          "paths": [
            "/var/log/syslog",
            "/var/log/auth.log"
           ],
          "fields": { "type": "syslog" }
        }

Ensure that the additional configuration is before the `]` that closes the “files” section. This will include the proper log files to send to Logstash, and label them as a specific type (which will be used by the Logstash filters). The Logstash Forwarder must be reloaded to put any changes into effect.

### Logstash Patterns Subsection

If there is a Logstash Patterns subsection, it will contain grok patterns that can be added to a new file in `/opt/logstash/patterns` on the Logstash Server. This will allow you to use the new patterns in Logstash filters.

### Logstash Filter Subsection

The Logstash Filter subsections will include a filter that can can be added to a new file, between the input and output configuration files, in `/etc/logstash/conf.d` on the Logstash Server. The filter determine how the Logstash server parses the relevant log files. Remember to restart the Logstash server after adding a new filter, to load your changes.

Now that you know how to use this guide, the rest of the guide will show you how to gather and filter application logs!

## Application: Nginx

### Logstash Forwarder: Nginx

On your **Nginx** servers, open the `logstash-forwarder.conf` configuration file for editing:

    sudo vi /etc/logstash-forwarder.conf

Add the following, in the “files” section, to send the Nginx access logs as type “nginx-access” to your Logstash server:

    ,
        {
          "paths": [
            "/var/log/nginx/access.log"
           ],
          "fields": { "type": "nginx-access" }
        }

Save and exit. Reload the Logstash Forwarder configuration to put the changes into effect:

    sudo service logstash-forwarder restart

### Logstash Patterns: Nginx

Nginx log patterns are not included in Logstash’s default patterns, so we will add Nginx patterns manually.

On your **Logstash server** , create a new pattern file called `nginx`:

    sudo vi /opt/logstash/patterns/nginx

Then insert the following lines:

    NGUSERNAME [a-zA-Z\.\@\-\+_%]+
    NGUSER %{NGUSERNAME}
    NGINXACCESS %{IPORHOST:clientip} %{NGUSER:ident} %{NGUSER:auth} \[%{HTTPDATE:timestamp}\] "%{WORD:verb} %{URIPATHPARAM:request} HTTP/%{NUMBER:httpversion}" %{NUMBER:response} (?:%{NUMBER:bytes}|-) (?:"(?:%{URI:referrer}|-)"|%{QS:referrer}) %{QS:agent}

Save and exit. The NGINXACCESS pattern parses, and assigns the data to various identifiers (e.g. clientip, ident, auth, etc.).

Next, change the ownership of the pattern file to `logstash`:

    sudo chown logstash:logstash /opt/logstash/patterns/nginx

### Logstash Filter: Nginx

On your **Logstash server** , create a new filter configuration file called `11-nginx.conf`:

    sudo vi /etc/logstash/conf.d/11-nginx.conf

Then add the following filter:

    filter {
      if [type] == "nginx-access" {
        grok {
          match => { "message" => "%{NGINXACCESS}" }
        }
      }
    }

Save and exit. Note that this filter will attempt to match messages of “nginx-access” type with the NGINXACCESS pattern, defined above.

Now restart Logstash to reload the configuration:

    sudo service logstash restart

Now your Nginx logs will be gathered and filtered!

## Application: Apache HTTP Web Server

Apache’s log patterns are included in the default Logstash patterns, so it is fairly easy to set up a filter for it.

**Note:** If you are using a RedHat variant, such as CentOS, the logs are located at `/var/log/httpd` instead of `/var/log/apache2`, which is used in the examples.

### Logstash Forwarder

On your **Apache** servers, open the `logstash-forwarder.conf` configuration file for editing:

    sudo vi /etc/logstash-forwarder.conf

Add the following, in the “files” section, to send the Apache access logs as type “apache-access” to your Logstash server:

    ,
        {
          "paths": [
            "/var/log/apache2/access.log"
           ],
          "fields": { "type": "apache-access" }
        }

Save and exit. Reload the Logstash Forwarder configuration to put the changes into effect:

    sudo service logstash-forwarder restart

### Logstash Filter: Apache

On your **Logstash server** , create a new filter configuration file called `12-apache.conf`:

    sudo vi /etc/logstash/conf.d/12-apache.conf

Then add the following filter:

    filter {
      if [type] == "apache-access" {
        grok {
          match => { "message" => "%{COMBINEDAPACHELOG}" }
        }
      }
    }

Save and exit. Note that this filter will attempt to match messages of “apache-access” type with the COMBINEDAPACHELOG pattern, one the default Logstash patterns.

Now restart Logstash to reload the configuration:

    sudo service logstash restart

Now your Apache logs will be gathered and filtered!

## Conclusion

It is possible to collect and parse logs of pretty much any type. Try and write your own filters and patterns for other log files.

Feel free to comment with filters that you would like to see, or with patterns of your own!

If you aren’t familiar with using Kibana, check out the third tutorial in this series: [How To Use Kibana Visualizations and Dashboards](how-to-use-kibana-dashboards-and-visualizations).
