---
author: Aaron Mildenstein
date: 2016-05-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-centralize-logs-with-rsyslog-logstash-and-elasticsearch-on-ubuntu-14-04
---

# How To Centralize Logs with Rsyslog, Logstash, and Elasticsearch on Ubuntu 14.04

### An Article from [Elastic](https://www.elastic.co/)

## Introduction

Making sense of the millions of log lines your organization generates can be a daunting challenge. On one hand, these log lines provide a view into application performance, server performance metrics, and security. On the other hand, log management and analysis can be very time consuming, which may hinder adoption of these increasingly necessary services.

Open-source software, such as [rsyslog](http://rsyslog.com), [Elasticsearch](https://www.elastic.co/products/elasticsearch), and [Logstash](https://www.elastic.co/products/logstash) provide the tools to transmit, transform, and store your log data.

In this tutorial, you will learn how to create a centralized rsyslog server to store log files from multiple systems and then use Logstash to send them to an Elasticsearch server. From there, you can decide how best to analyze the data.

## Goals

This tutorial teaches you how to centralize logs generated or received by syslog, specifically the variant known as [rsyslog](http://rsyslog.com). Syslog, and syslog-based tools like rsyslog, collect important information from the kernel and many of the programs that run to keep UNIX-like servers running. As syslog is a standard, and not just a program, many software projects support sending data to syslog. By centralizing this data, you can more easily audit security, monitor application behavior, and keep track of other vital server information.

From a centralized, or aggregating rsyslog server, you can then forward the data to Logstash, which can further parse and enrich your log data before sending it on to Elasticsearch.

The final objectives of this tutorial are to:

1. Set up a single, client (or forwarding) rsyslog server
2. Set up a single, server (or collecting) rsyslog server, to receive logs from the rsyslog client
3. Set up a Logstash instance to receive the messages from the rsyslog collecting server
4. Set up an Elasticsearch server to receive the data from Logstash

## Prerequisites

In the **same DigitalOcean data center** , create the following Droplets with **private networking enabled** :

- Ubuntu 14.04 Droplet named **rsyslog-client**
- Ubuntu 14.04 Droplet ( **1 GB** or greater) named **rsyslog-server** where centralized logs will be stored and Logstash will be installed
- Ubuntu 14.04 Droplet with Elasticsearch installed from [How To Install and Configure Elasticsearch on Ubuntu 14.04](how-to-install-and-configure-elasticsearch-on-ubuntu-14-04)

You will also need a non-root user with sudo privileges for each of these servers. [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.

**Note:** To maximize performance, Logstash will try to allocate 1 gigabyte of memory by default, so ensure the centralized server instance is sized accordingly.

Refer to [How To Set Up And Use DigitalOcean Private Networking](how-to-set-up-and-use-digitalocean-private-networking) for help on enabling private networking while creating the Droplets.

If you created the Droplets without private networking, refer to [How To Enable DigitalOcean Private Networking on Existing Droplets](how-to-enable-digitalocean-private-networking-on-existing-droplets).

## Step 1 — Determining Private IP Addresses

In this section, you will determine which private IP addresses are assigned to each Droplet. This information will be needed through the tutorial.

On each Droplet, find its IP addresses with the `ifconfig` command:

    sudo ifconfig -a

The `-a` option is used to show all interfaces. The primary Ethernet interface is usually called `eth0`. In this case, however, we want the IP from `eth1`, the _private_ IP address. These private IP addresses are not routable over the Internet and are used to communicate in private LANs — in this case, between servers in the same data center over secondary interfaces.

The output will look similar to:

Output from ifconfig -a

    eth0 Link encap:Ethernet HWaddr 04:01:06:a7:6f:01  
              inet addr:123.456.78.90 Bcast:123.456.78.255 Mask:255.255.255.0
              inet6 addr: fe80::601:6ff:fea7:6f01/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
              RX packets:168 errors:0 dropped:0 overruns:0 frame:0
              TX packets:137 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:18903 (18.9 KB) TX bytes:15024 (15.0 KB)
    
    eth1 Link encap:Ethernet HWaddr 04:01:06:a7:6f:02  
              inet addr:10.128.2.25 Bcast:10.128.255.255 Mask:255.255.0.0
              inet6 addr: fe80::601:6ff:fea7:6f02/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
              RX packets:6 errors:0 dropped:0 overruns:0 frame:0
              TX packets:5 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:468 (468.0 B) TX bytes:398 (398.0 B)
    
    lo Link encap:Local Loopback  
              inet addr:127.0.0.1 Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING MTU:16436 Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:0 
              RX bytes:0 (0.0 B) TX bytes:0 (0.0 B)

The section to note here is `eth1` and within that `inet addr`. In this case, the private network address is **10.128.2.25**. This address is only accessible from other servers, within the same region, that have private networking enabled.

Be sure to repeat this step for all 3 Droplets. Save these private IP addresses somewhere secure. They will be used throughout this tutorial.

## Step 2 — Setting the Bind Address for Elasticsearch

As part of the Prerequisites, you setup Elasticsearch on its own Droplet. The [How To Install and Configure Elasticsearch on Ubuntu 14.04](how-to-install-and-configure-elasticsearch-on-ubuntu-14-04) tutorial shows you how to set the bind address to `localhost` so that other servers can’t access the service. However, we need to change this so Logstash can send it data over its private network address.

We will bind Elasticsearch to its private IP address. **Elasticsearch will only listen to requests to this IP address.**

On the Elasticsearch server, edit the configuration file:

    sudo nano /etc/elasticsearch/elasticsearch.yml

Find the line that contains `network.bind_host`. If it is commented out, uncomment it by removing the `#` character at the beginning of the line. Change the value to the private IP address for the Elasticsearch server so it looks like this:

/etc/elasticsearch/elasticsearch.yml

    network.bind_host: private_ip_address

Finally, restart Elasticsearch to enable the change.

    sudo service elasticsearch restart

**Warning:** It is very important that you only allow servers you trust to connect to Elasticsearch. Using [iptables](how-to-isolate-servers-within-a-private-network-using-iptables) is highly recommended. For this tutorial, you only want to trust the private IP address of the **rsyslog-server** Droplet, which has Logstash running on it.

## Step 3 — Configuring the Centralized Server to Receive Data

In this section, we will configure the **rsyslog-server** Droplet to be the _centralized_ server able to receive data from other syslog servers on port 514.

To configure the **rsyslog-server** to receive data from other syslog servers, edit `/etc/rsyslog.conf` on the **rsyslog-server** Droplet:

    sudo nano /etc/rsyslog.conf

Find these lines already commented out in your `rsyslog.conf`:

/etc/rsyslog.conf

    # provides UDP syslog reception
    #$ModLoad imudp
    #$UDPServerRun 514
    
    # provides TCP syslog reception
    #$ModLoad imtcp
    #$InputTCPServerRun 514

The first lines of each section (`$ModLoad imudp` and `$ModLoad imtcp`) load the `imudp` and `imtcp` modules, respectively. The `imudp` stands for **i** nput **m** odule **udp** , and `imtcp` stands for **i** nput **m** odule **tcp**. These modules listen for incoming data from other syslog servers.

The second lines of each section (`$UDPSerververRun 514` and `$TCPServerRun 514`) indicate that rsyslog should start the respective UDP and TCP servers for these protocols listening on port 514 (which is the syslog default port).

To enable these modules and servers, uncomment the lines so the file now contains:

/etc/rsyslog.conf

    # provides UDP syslog reception
    $ModLoad imudp
    $UDPServerRun 514
    
    # provides TCP syslog reception
    $ModLoad imtcp
    $InputTCPServerRun 514

Save and close the rsyslog configuration file.

Restart rsyslog by running:

    sudo service rsyslog restart

Your centralized rsyslog server is now configured to listen for messages from remote syslog (including rsyslog) instances.

**Tip:** To validate your rsyslog configuration file, you can run the `sudo rsyslogd -N1` command.

## Step 4 — Configuring rsyslog to Send Data Remotely

In this section, we will configure the **rsyslog-client** to send log data to the **ryslog-server** Droplet we configured in the last step.

In a default rsyslog setup on Ubuntu, you’ll find two files in `/etc/rsyslog.d`:

- `20-ufw.conf`
- `50-default.conf`

On the **rsyslog-client** , edit the default configuration file:

    sudo nano /etc/rsyslog.d/50-default.conf

Add the following line at the top of the file before the `log by facility` section, replacing `private_ip_of_ryslog_server` with the **private** IP of your _centralized_ server:

/etc/rsyslog.d/50-default.conf

    *.* @private_ip_of_ryslog_server:514

Save and exit the file.

The first part of the line (_._) means we want to send all messages. While it is outside the scope of this tutorial, you can configure rsyslog to send only certain messages. The remainder of the line explains how to send the data and where to send the data. In our case, the `@` symbol before the IP address tells rsyslog to use UDP to send the messages. Change this to `@@` to use TCP. This is followed by the private IP address of **rsyslog-server** with rsyslog and Logstash installed on it. The number after the colon is the port number to use.

Restart rsyslog to enable the changes:

    sudo service rsyslog restart

Congratulations! You are now sending your syslog messages to a centralized server!

**Tip:** To validate your rsyslog configuration file, you can run the `sudo rsyslogd -N1` command.

## Step 5 — Formatting the Log Data to JSON

Elasticsearch requires that all documents it receives be in JSON format, and rsyslog provides a way to accomplish this by way of a template.

In this step, we will configure our centralized rsyslog server to use a JSON template to format the log data before sending it to Logstash, which will then send it to Elasticsearch on a different server.

Back on the **rsyslog-server** server, create a new configuration file to format the messages into JSON format before sending to Logstash:

    sudo nano /etc/rsyslog.d/01-json-template.conf

Copy the following contents to the file exactly as shown:

/etc/rsyslog.d/01-json-template.conf

    template(name="json-template"
      type="list") {
        constant(value="{")
          constant(value="\"@timestamp\":\"") property(name="timereported" dateFormat="rfc3339")
          constant(value="\",\"@version\":\"1")
          constant(value="\",\"message\":\"") property(name="msg" format="json")
          constant(value="\",\"sysloghost\":\"") property(name="hostname")
          constant(value="\",\"severity\":\"") property(name="syslogseverity-text")
          constant(value="\",\"facility\":\"") property(name="syslogfacility-text")
          constant(value="\",\"programname\":\"") property(name="programname")
          constant(value="\",\"procid\":\"") property(name="procid")
        constant(value="\"}\n")
    }

Other than the first and the last, notice that the lines produced by this template have a comma at the beginning of them. This is to maintain the JSON structure _and_ help keep the file readable by lining everything up neatly. This template formats your messages in the way that Elasticsearch and Logstash expect to receive them. This is what they will look like:

Example JSON message

    {
      "@timestamp" : "2015-11-18T18:45:00Z",
      "@version" : "1",
      "message" : "Your syslog message here",
      "sysloghost" : "hostname.example.com",
      "severity" : "info",
      "facility" : "daemon",
      "programname" : "my_program",
      "procid" : "1234"
    }

**Tip:** The [rsyslog.com docs](http://www.rsyslog.com/doc/v8-stable/configuration/properties.html) show the variables available from rsyslog if you would like to custom the log data. However, you must send it in JSON format to Logstash and then to Elasticsearch.

The data being sent is not using this format yet. The next step shows out to configure the server to use this template file.

## Step 6 — Configuring the Centralized Server to Send to Logstash

Now that we have the template file that defines the proper JSON format, let’s configure the centralized rsyslog server to send the data to Logstash, which is on the same Droplet for this tutorial.

At startup, rsyslog will look through the files in `/etc/rsyslog.d` and create its configuration from them. Let’s add our own configuration file to extended the configuration.

On the **rsyslog-server** , create `/etc/rsyslog.d/60-output.conf`:

    sudo nano /etc/rsyslog.d/60-output.conf

Copy the following lines to this file:

/etc/rsyslog.d/60-output.conf

    # This line sends all lines to defined IP address at port 10514,
    # using the "json-template" format template
    
    *.* @private_ip_logstash:10514;json-template

The `*.*` at the beginning means to process the remainder of the line for all log messages. The `@` symbols means to use UDP (Use `@@` to instead use TCP). The IP address or hostname after the `@` is where to forward the messages. In our case, we are using the private IP address for **rsyslog-server** since the rsyslog centralized server and the Logstash server are installed on the same Droplet. **This must match the private IP address you configure Logstash to listen on in the next step.**

The port number is next. This tutorial uses port 10514. Note that the Logstash server must listen on the same port using the same protocol. The last part is our template file that shows how to format the data before passing it along.

Do not restart rsyslog yet. First, we have to configure Logstash to receive the messages.

## Step 7 — Configure Logstash to Receive JSON Messages

In this step you will install Logstash, configure it to receive JSON messages from rsyslog, and configure it to send the JSON messages on to Elasticsearch.

Logstash requires Java 7 or later. Use the instructions from **Step 1** of the [Elasticsearch tutorial](how-to-install-and-configure-elasticsearch-on-ubuntu-14-04) to install Java 7 or 8 on the **rsyslog-server** Droplet.

Next, install the security key for the Logstash repository:

    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

Add the repository definition to your `/etc/apt/sources.list` file:

    echo "deb http://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list

**Note:** Use the `echo` method described above to add the Logstash repository. Do not use `add-apt-repository` as it will add a `deb-src` entry as well, but Elastic does not provide a source package. This will result in an error when you attempt to run `apt-get update`.

Update your package lists to include the Logstash repository:

    sudo apt-get update

Finally, install Logstash:

    sudo apt-get install logstash

Now that Logstash is installed, let’s configure it to listen for messages from rsyslog.

The default installation of Logstash looks for configuration files in `/etc/logstash/conf.d`. Edit the main configuration file:

    sudo nano /etc/logstash/conf.d/logstash.conf

Then, add these lines to `/etc/logstash/conf.d/logstash.conf`:

/etc/logstash/conf.d/logstash.conf`

    # This input block will listen on port 10514 for logs to come in.
    # host should be an IP on the Logstash server.
    # codec => "json" indicates that we expect the lines we're receiving to be in JSON format
    # type => "rsyslog" is an optional identifier to help identify messaging streams in the pipeline.
    
    input {
      udp {
        host => "logstash_private_ip"
        port => 10514
        codec => "json"
        type => "rsyslog"
      }
    }
    
    # This is an empty filter block. You can later add other filters here to further process
    # your log lines
    
    filter { }
    
    # This output block will send all events of type "rsyslog" to Elasticsearch at the configured
    # host and port into daily indices of the pattern, "rsyslog-YYYY.MM.DD"
    
    output {
      if [type] == "rsyslog" {
        elasticsearch {
          hosts => ["elasticsearch_private_ip:9200"]
        }
      }
    }

The syslog protocol is UDP by definition, so this configuration mirrors that standard.

In the input block, set the Logstash host address by replacing logstash_private_ip with the private IP address of **rsyslog-server** , which also has Logstash installed on it.

The input block configure Logstash to listen on port `10514` so it won’t compete with syslog instances on the same machine. A port less than 1024 would require Logstash to be run as root, which is not a good security practice.

Be sure to replace elasticsearch_private_ip with the **private IP address** of your Elasticsearch Droplet. The output block shows a simple [conditional](https://www.elastic.co/guide/en/logstash/current/event-dependent-configuration.html#conditionals) configuration. Its object is to only allow matching events through. In this case, that is only events with a “type” of “rsyslog”.

Test your Logstash configuraiton changes:

    sudo service logstash configtest

It should display `Configuration OK` if there are no syntax errors. Otherwise, try and read the error output to see what’s wrong with your Logstash configuration.

When all these steps are completed, you can start your Logstash instance by running:

    sudo service logstash start

Also restart rsyslog on the same server since it has a Logstash instance to forward to now:

    sudo service rsyslog restart

To verify that Logstash is listening on port 10514:

    netstat -na | grep 10514

You should see something like this:

Output of netstat

    udp6 0 0 10.128.33.68:10514 :::*  

You will see the private IP address of **rsyslog-server** and the 10514 port number we are using to listen for rsyslog data.

**Tip:** To troubleshoot Logstash, stop the service with `sudo service logstash stop` and run it in the foreground with verbose messages:

    /opt/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf --verbose

It will contain usual information such as verifying with IP address and UDP port Logstash is using:

    Starting UDP listener {:address=>"10.128.33.68:10514", :level=>:info}

## Step 8 — Verifying Elasticsearch Input

Earlier, we configured Elasticsearch to listen on its private IP address. It should now be receiving messages from Logstash. In this step, we will verify that Elasticsearch is receiving the log data.

The **rsyslog-client** and **rsyslog-server** Droplets should be sending all their log data to Logstash, which is then passed along to Elasticsearch. Let’s generate a security message to verify that Elasticsearch is indeed receiving these messages.

On **rsyslog-client** , execute the following command:

    sudo tail /var/log/auth.log

You will see the security log on the local system at the end of the output. It will look similar to:

Output of tail /var/log/auth.log

    May 2 16:43:15 rsyslog-client sudo: sammy : TTY=pts/0 ; PWD=/etc/rsyslog.d ; USER=root ; COMMAND=/usr/bin/tail /var/log/auth.log
    May 2 16:43:15 rsyslog-client sudo: pam_unix(sudo:session): session opened for user root by sammy(uid=0)

With a simple query, you can check Elasticsearch:

Run the following command on the Elasticsearch server or any system that is allowed to access it. Replace elasticsearch\_ip with the private IP address of the Elasticsearch server. This IP address must also be the one you configured Elasticsearch to listen on earlier in this tutorial.

    curl -XGET 'http://elasticsearch_ip:9200/_all/_search?q=*&pretty'

In the output you will see something similar to the following:

Output of curl

    {
          "_index" : "logstash-2016.05.04",
          "_type" : "rsyslog",
          "_id" : "AVR8fpR-e6FP4Elp89Ww",
          "_score" : 1.0,
          "_source":{"@timestamp":"2016-05-04T15:59:10.000Z","@version":"1","message":" sammy : TTY=pts/0 ; PWD=/home/sammy ; USER=root ; COMMAND=/usr/bin/tail /var/log/auth.log","sysloghost":"rsyslog-client","severity":"notice","facility":"authpriv","programname":"sudo","procid":"-","type":"rsyslog","host":"10.128.33.68"}
        },

Notice that the name of the Droplet that generated the rsyslog message is in the log ( **rsyslog-client** ).

With this simple verification step, your centralized rsyslog setup is complete and fully operational!

## Conclusion

Your logs are in Elasticsearch now. What’s next? Consider reading up on what [Kibana](https://www.elastic.co/products/kibana) can do to visualize the data you have in Elasticsearch, including line and bar graphs, pie charts, maps, and more. [How To Use Logstash and Kibana To Centralize Logs On Ubuntu 14.04](how-to-use-logstash-and-kibana-to-centralize-and-visualize-logs-on-ubuntu-14-04#connect-to-kibana) explains how to use Kibana web interface to search and visualize logs.

Perhaps your data would be more valuable with further parsing and tokenization. If so, then learning more about [Logstash](https://www.elastic.co/products/logstash) will help you achieve that result.
