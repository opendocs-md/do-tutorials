---
author: William Shiao
date: 2017-04-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-logs-with-graylog-2-on-ubuntu-16-04
---

# How to Manage Logs with Graylog 2 on Ubuntu 16.04

## Introduction

[Graylog](https://www.graylog.org/) is a powerful open-source log management platform. It aggregates and extracts important data from server logs, which are often sent using the Syslog protocol. It also allows you to search and visualize the logs in a web interface.

In this tutorial, you’ll install and configure Graylog on Ubuntu 16.04, and set up a simple input that receives system logs.

## Prerequisites

Before you begin this tutorial, you’ll need:

- One Ubuntu 16.04 server with at least 2 GB of RAM, private networking enabled, and a non-root user. This can be set up by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- Oracle JDK 8 installed, which you can do by following the “Installing the Oracle JDK” section of [this Java installation article](how-to-install-java-with-apt-get-on-ubuntu-16-04).
- Elasticsearch 2.x, which you can install by following Steps 1 and 2 of the [Elasticsearch installation tutorial](how-to-install-and-configure-elasticsearch-on-ubuntu-16-04). Certain versions of Graylog only work with certain versions of Elasticearch. For example, Graylog 2.x does not work with Elasticsearch 5.x. Refer to [this Greylog-Elasticsearch version comparison table](http://docs.graylog.org/en/2.2/pages/configuration/elasticsearch.html) for the exact version. This tutorial uses Elasticsearch 2.4.4 and Graylog 2.2.
- MongoDB, which can be installed by following the [MongoDB tutorial](how-to-install-mongodb-on-ubuntu-16-04).

## Step 1 — Configuring Elasticsearch

We need to modify the Elasticsearch configuration file so that the cluster name matches the one set in the Graylog configuration file. To keep things simple, we’ll set the Elasticsearch cluster name to the default Graylog name of `graylog`. You may set it to whatever you wish, but make sure you update the Graylog configuration file to reflect that change.

Open the Elasticsearch configuration file in your editor:

    sudo nano /etc/elasticsearch/elasticsearch.yml

Find the following line:

/etc/elasticsearch/elasticsearch.yml

    cluster.name: <CURRENT CLUSTER NAME>

Change the `cluster.name` value to `graylog`:

/etc/elasticsearch/elasticsearch.yml

    cluster.name: graylog

Save the file and exit your editor.

Since we modified the configuration file, we have to restart the service for the changes to take effect.

    sudo systemctl restart elasticsearch

Now that you have configured Elasticsearch, let’s move on to installing Graylog.

## Step 2 — Installing Graylog

In this step, we we’ll install the Graylog server.

First, download the package file containing the Graylog repository configuration. Visit the [Graylog download page](https://www.graylog.org/download) to find the current version number. We’ll use version `2.2` for this tutorial.

    wget https://packages.graylog2.org/repo/packages/graylog-2.2-repository_latest.deb

Next, install the repository configuration from the `.deb` package file, again replacing `2.2` with the version you downloaded.

    sudo dpkg -i graylog-2.2-repository_latest.deb

Now that the repository configuration has been updated, we have to fetch the new list of packages. Execute this command:

    sudo apt-get update

Next, install the `graylog-server` package:

    sudo apt-get install graylog-server

Lastly, start Graylog automatically on system boot with this command:

    sudo systemctl enable graylog-server.service

Graylog is now successfully installed, but it’s not started yet. We have to configure it before it will start.

## Step 3 — Configuring Graylog

Now that we have Elasticsearch configured and Graylog installed, we need to change a few settings in the default Graylog configuration file before we can use it. Graylog’s configuration file is located at `/etc/graylog/server/server.conf` by default.

First, we need to set the `password_secret` value. Graylog uses this value to secure the stored user passwords. We will use a randomly-generated 128-character value.

We will use `pwgen` to generate the password, so install it if it isn’t already installed:

    sudo apt install pwgen

Generate the password and place it in the Graylog configuration file. We’ll use the `sed` program to inject the `password_secret` value into the Graylog configuration file. This way we don’t have to copy and paste any values. Execute this command to create the secret and store it in the file:

    sudo -E sed -i -e "s/password_secret =.*/password_secret = $(pwgen -s 128 1)/" /etc/graylog/server/server.conf

For more information on using `sed`, see [this DigitalOcean sed tutorial](the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux).

Next, we need to set the `root_password_sha2` value. This is an [SHA-256 hash](https://en.wikipedia.org/wiki/SHA-2) of your desired password. Once again, we’ll use the `sed` command to modify the Graylog configuration file so we don’t have to manually generate the SHA-256 hash using `shasum` and paste it into the configuration file.

Execute this command, but replace `password` below with your desired default administrator password:

**Note:** There is a leading space in the command, which prevents your password from being stored as plain text in your Bash history.

     sudo sed -i -e "s/root_password_sha2 =.*/root_password_sha2 = $(echo -n 'password' | shasum -a 256 | cut -d' ' -f1)/" /etc/graylog/server/server.conf

Now, we need to make a couple more changes to the configuration file. Open the Graylog configuration file with your editor:

    sudo nano /etc/graylog/server/server.conf

Find and change the following lines, uncommenting them and replacing `graylog_public_ip` with the public IP of your server. This can be an IP address or a fully-qualified domain name.

/etc/graylog/server/server.conf

    
    ...
    rest_listen_uri = http://your_server_ip_or_domain:9000/api/
    
    ...
    web_listen_uri = http://your_server_ip_or_domain:9000/
    
    ...

Save the file and exit your editor.

Since we changed the configuration file, we have to restart (or start) the `graylog-server` service. The restart command will start the server even if it is currently stopped.

    sudo systemctl restart graylog-server

Next, check the status of the server.

    sudo systemctl status graylog-server

The output should look something like this:

    ● graylog-server.service - Graylog server
       Loaded: loaded (/usr/lib/systemd/system/graylog-server.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2017-03-03 20:10:34 PST; 1 months 7 days ago
         Docs: http://docs.graylog.org/
     Main PID: 1300 (graylog-server)
        Tasks: 191 (limit: 9830)
       Memory: 1.2G
          CPU: 14h 57min 21.475s
       CGroup: /system.slice/graylog-server.service
               ├─1300 /bin/sh /usr/share/graylog-server/bin/graylog-server
               └─1388 /usr/bin/java -Xms1g -Xmx1g -XX:NewRatio=1 -server -XX:+ResizeTLAB -XX:+UseConcMarkSweepGC -XX:+CMSCon

You should see `active` for the status.

If the output reports that the system isn’t running, check `/var/log/syslog` for any errors. Make sure you installed Java when you installed Elasticsearch, and that you changed all of the values in Step 3. Then attept to restart the Graylog service again.

If you have configured a firewall with `ufw`, add a firewall exception for TCP port `9000` so you can access the web interface:

    sudo ufw allow 9000/tcp

Once Graylog is running, you should be able to access `http://your_server_ip:9000` with your web browser. You may have to wait up to five minutes after restarting `graylog-server` before the web interface starts. Additionally, ensure that MongoDB is running.

Now that Graylog is running properly, we can move on to processing logs.

## Step 4 — Creating an Input

Let’s add a new input to Graylog to receive logs. Inputs tell Graylog which port to listen on and which protocol to use when receiving logs. We ’ll add a Syslog UDP input, which is a commonly used logging protocol.

When you visit `http://your_server_ip:9000` in your browser, you’ll see a login page. Use `admin` for your username, and use the password you entered in Step 3 for your password.

Once logged in, you’ll see a page titled “Getting Started” that looks like the following image:

!["Getting Started" page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/graylog_ubuntu_1604/IeULQ5f.png)

To view the inputs page, click the **System** dropdown in the navigation bar and select **Inputs**.

You’ll then see a dropdown box that contains the text **Select Input**. Select **Syslog UDP** from this dropdown, and then click on the **Launch new input** button.

A modal with a form should appear. Fill in the following details to create your input:

1. For **Node** , select your server. It should be the only item in the list.
2. For **Title** , enter a suitable title, such as `Linux Server Logs`.
3. For **Bind address** , use your server’s private IP. If you also want to be able to collect logs from external servers (not recommended, as Syslog does not support authentication), you can set it to `0.0.0.0` (all interfaces).
4. For **Port** , enter `8514`. Note that we are using port `8514` for this tutorial because ports `0` through `1024` can be only used by the root user. You can use any port number above `1024` should be fine as long as it doesn’t conflict with any other services.

Click **Save**. The local input listing will update and show your new input, as shown in the following figure:

![Screenshot of local inputs](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/graylog_ubuntu_1604/ZL75jrK.png)

Now that an input has been created, we can send some logs to Graylog.

## Step 5 — Configure Servers to Send Logs to Graylog

We have an input configured and listening on port `8514`, but we are not sending any data to the input yet, so we won’t see any results. `rsyslog` is a software utility used to forward logs and is pre-installed on Ubuntu, so we’ll configure that to send logs to Graylog. In this tutorial, we’ll configure the Ubuntu server running Graylog to send its system logs to the input we just created, but you can follow these steps on any other servers you may have.

If you want to send data to Graylog from other servers, you need to add a firewall exception for UDP port `8514`.

    sudo ufw allow 8514/udp

Create and open a new `rsyslog` configuration file in your editor.

    sudo nano /etc/rsyslog.d/60-graylog.conf

Add the following line to the file, replacing `your_server_private_ip` with your Graylog server’s private IP.

/etc/rsyslog.d/60-graylog.conf

    *.* @your_server_private_ip:8514;RSYSLOG_SyslogProtocol23Format

Save and exit your editor.

Restart the `rsyslog` service so the changes take effect.

    sudo systemctl restart rsyslog

Repeat these steps for each server you want to send logs from.

You should now be able to view your logs in the web interface. Click the **Sources** tab in the navigation bar to view a graph of the sources. It should look something like this:

![Screenshot of sources](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/graylog_ubuntu_1604/SwMfGPD.png)

You can also click the **Search** tab in the navigation bar to view a overview of the most recent logs.

You can learn more about searches in the [Graylog searching documentation](http://docs.graylog.org/en/2.2/pages/queries.html).

## Conclusion

You now have a working Graylog server with an input source that can collect logs from other servers.

Next, you might want to look into setting up dashboards, alerts, and streams. Dashboards provide a quick overview of your logs. Streams categorize messages, which you can monitor with alerts. To learn more about configuring the more advanced features of Graylog, you can find instructions in the [Graylog documentation](http://docs.graylog.org/en/2.2/index.html).
