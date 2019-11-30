---
author: Justin Ellingwood
date: 2014-06-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-collectd-to-gather-system-metrics-for-graphite-on-ubuntu-14-04
---

# How To Configure Collectd to Gather System Metrics for Graphite on Ubuntu 14.04

## Introduction

Collecting and visualizing data is an important way to make informed decisions about your servers and projects.

In a [previous guide](https://www.digitalocean.com/community/articles/how-to-install-and-use-graphite-on-an-ubuntu-14-04-server), we discussed how to install and configure Graphite to visualize data on our servers. However, we didn’t have a good way of collecting or even passing data into Graphite.

In this guide, we’ll discuss the installation and use of **collectd** , a system statistics gatherer that can collect and organize metrics about your server and running services.

We will show you how to install and configure collectd to pass data into Graphite to render. We will assume that you have Graphite up and running on an Ubuntu 14.04 server as we showed you in the last guide.

## Install Collectd

The first thing we are going to do is install collectd. We can get this from the default repositories.

Refresh the local package index and then install by typing:

    sudo apt-get update
    sudo apt-get install collectd collectd-utils

This will install the daemon and a helper control interface. We still need to configure it so that it knows to pass the data it collects to Graphite.

## Configure Collectd

Begin by opening the collectd configuration file in your editor with root privileges:

    sudo nano /etc/collectd/collectd.conf

The first thing that we should set is the hostname of the machine that we are on. Collectd can be used to send information to a remote Graphite server, but we are using this on the same machine for this guide. You can choose whatever name you’d like:

    Hostname "graph\_host"

If you have a real domain name configured, you can skip this and just leave toe `FQDNLookup` so that the server will use the DNS system to get the proper domain.

You may notice there is a parameter for “Interval”, which is the interval that collectd waits before querying data on the host. This is set by default to 10 seconds. If you followed along in the Graphite article, you will notice that this is the usual shortest interval for Graphite to track stats. These two values must match for data to be recorded reliably.

Next, we get right into the services that Collectd will gather information about. Collectd does this through the use of plugins. Most of the plugins are used to read information from the system, but plugins are also used to define where to send information. Graphite is one of these write plugins.

For this guide, we are going to ensure that the following plugins are enabled. You can comment out any other plugins, or you can work on configuring them correctly if you want to try them out on your host:

    LoadPlugin apache
    LoadPlugin cpu
    LoadPlugin df
    LoadPlugin entropy
    LoadPlugin interface
    LoadPlugin load
    LoadPlugin memory
    LoadPlugin processes
    LoadPlugin rrdtool
    LoadPlugin users
    LoadPlugin write_graphite

Some of these need configuration, and some of them will work fine out-of-the-box.

Continuing on down the file, we get to the configuration section of each plugin. Plugins are configured by defining a “block” for each configuration section. This is somewhat similar to how Apache compartmentalizes directives within blocks. We only will be taking a look at a few of these, since most of our plugins will work fine the way they are.

We enabled the Apache plugin because we have Apache installed to serve Graphite. We can configure the Apache plugin with a simple section that looks like this:

    \<Plugin apache\> \<Instance "Graphite"\> URL "http://domain\_name\_or\_IP/server-status?auto" Server "apache" \</Instance\> \</Plugin\>

In a production environment, you may wish to keep the server stats protected behind an authentication layer. You can look at the commented code in this section of the file to see how that would work. For simplicity’s sake, we are going to demonstrate an open setup that is not authenticated.

We will be creating the `server-status` page for Apache that provides us with the details we need in a bit.

For the `df` plugin, which tells us how full our disks are, we can add a simple configuration that looks like this:

    \<Plugin df\> Device "/dev/vda" MountPoint "/" FSType "ext3" \</Plugin\>

You should point the device to the device name of the drive on your system. You can find this by typing the command in the terminal:

    df

    Filesystem 1K-blocks Used Available Use% Mounted on/dev/vda 61796348 1766820 56867416 4% / none 4 0 4 0% /sys/fs/cgroup udev 2013364 12 2013352 1% /dev tmpfs 404836 340 404496 1% /run none 5120 0 5120 0% /run/lock none 2024168 0 2024168 0% /run/shm none 102400 0 102400 0% /run/user

Choose the networking interface you wish to monitor:

    \<Plugin interface\> Interface "eth0" IgnoreSelected false \</Plugin\>

Finally, we come to the Graphite plugin. This will tell collectd how to connect to our Graphite instance. Make the section look something like this:

    \<Plugin write\_graphite\> \<Node "graphing"\> Host "localhost" Port "2003" Protocol "tcp" LogSendErrors true Prefix "collectd." StoreRates true AlwaysAppendDS false EscapeCharacter "\_" \</Node\> \</Plugin\>

This tells our daemon how to connect to Carbon in order to pass off its data. We specify that it should look to the local computer on port 2003, which Carbon uses to listen for TCP connections.

Next, we tell it to use that protocol to reliably hand off the data to Carbon. We tell it to log errors about the hand off and then set the prefix for the data. Since we end this value with a dot, all of the collectd stats for this host will be stored in a “collectd” directory.

The store rates determines whether stats will be converted to gauges before being passed. The append data source line would append the node name to our metrics if enabled. The escape character determines how certain values with dots in them are converted to avoid Carbon from splitting them into directories.

Save and close the file when you are finished.

## Configure Apache to Report Stats

In our configuration file, we enabled Apache stats tracking. We still need to configure Apache to allow this though.

In the Apache virtual hosts file that we have enabled for Graphite, we can add a simple location block that will tell Apache to report stats.

Open the file in your text editor:

    sudo nano /etc/apache2/sites-available/apache2-graphite.conf

Below the “content” location block, we are going to add another block so that Apache will serve statistics at the `/server-status` page. Add the following section:

    Alias /content/ /usr/share/graphite-web/static/ \<Location "/content/"\> SetHandler None \</Location\> \<Location "/server-status"\>SetHandler server-statusRequire all granted\</Location\> ErrorLog ${APACHE\_LOG\_DIR}/graphite-web\_error.log

Save and close the file when you are finished.

Now, we can reload Apache to get access to the new statistics:

    sudo service apache2 reload

We can check to make sure everything is working correctly by visiting the page in our web browser. We just need to go to our domain, followed by `/server-status`:

    http://domain\_name\_or\_IP/server-status

You should see a page that looks something like this:

![server stats](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/collectd_statsd/server_stats.png)

## Setting the Storage Schema and Aggregation

Now that we have collectd configured to gather statistics about your services, we need to adjust Graphite to handle the data it receives correctly.

Let’s start by creating a storage schema definition. Open up the storage schema configuration file:

    sudo nano /etc/carbon/storage-schemas.conf

Inside, we need to add a definition that will dictate how long the information is kept, and how detailed the data should be at various levels.

We will tell Graphite to store collectd information at intervals of ten seconds for one day, at one minute for seven days, and intervals of ten minutes for one year.

This will give us a good balance between detailed information for recent activity and general trends over the long term. Collectd passes its metrics starting with the string `collectd`, so we will match that pattern.

The policy we described can be added by adding these lines. Remember, add these **above** the default policy, or else they will never be applied:

    [collectd]
    pattern = ^collectd.*
    retentions = 10s:1d,1m:7d,10m:1y

Save and close the file when you are finished.

## Reload the Services

Now that collectd is configured and Graphite knows how to handle its data, we can reload the services.

First, restart the Carbon service. It is a good idea to use the “stop” and then “start” command with a few seconds in between instead of the “restart” command. This makes sure that the data is completely flushed prior to the restart:

    sudo service carbon-cache stop ## wait a few seconds here
    sudo service carbon-cache start

After the Carbon service is up and running again, we can do the same thing with collectd. The service may not be running yet, but this will ensure that it handles the data correctly:

    sudo service collectd stop
    sudo service collectd start

After this, you can visit your domain again, and you should see a new tree with your collectd information:

![collectd tree](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/collectd_statsd/collectd_tree.png)

## Conclusion

Our collectd configuration is complete and our stats are already being recorded! Now, we have a daemon configured to track our server and services.

We can configure or write additional plugins for collectd as the need arises. Additional servers with collectd can also send data to our Graphite server. Collectd is mainly used for collecting statistics about common services and your machines as a whole.

In the [next article](https://www.digitalocean.com/community/articles/how-to-configure-statsd-to-collect-arbitrary-stats-for-graphite-on-ubuntu-14-04), we’ll set up StatsD, a service that can cache data before flushing it to Graphite. This will allow us us to work around the problem of data loss when sending stats too quickly that we described in the previous article. It will also give us with an interface to track statistics within our own programs and projects.

By Justin Ellingwood
