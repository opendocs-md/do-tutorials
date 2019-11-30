---
author: Vadym Kalsin
date: 2019-04-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-zabbix-to-securely-monitor-remote-servers-on-ubuntu-18-04
---

# How To Install and Configure Zabbix to Securely Monitor Remote Servers on Ubuntu 18.04

_The author selected the [Open Source Initiative](https://www.brightfunds.org/organizations/open-source-initiative) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Zabbix](http://www.zabbix.com/) is open-source monitoring software for networks and applications. It offers real-time monitoring of thousands of metrics collected from servers, virtual machines, network devices, and web applications. These metrics can help you determine the current health of your IT infrastructure and detect problems with hardware or software components before customers complain. Useful information is stored in a database so you can analyze data over time and improve the quality of provided services, or plan upgrades of your equipment.

Zabbix uses several options for collecting metrics, including agentless monitoring of user services and client-server architecture. To collect server metrics, it uses a small agent on the monitored client to gather data and send it to the Zabbix server. Zabbix supports encrypted communication between the server and connected clients, so your data is protected while it travels over insecure networks.

The Zabbix server stores its data in a relational database powered by [MySQL](https://www.mysql.com/), [PostgreSQL](https://www.postgresql.org/), or [Oracle](https://www.oracle.com/index.html). You can also store historical data in nosql databases like [Elasticsearch](https://www.elastic.co/) and [TimescaleDB](https://www.timescale.com/). Zabbix provides a web interface so you can view data and configure system settings.

In this tutorial, you will configure two machines. One will be configured as the server, and the other as a client that you’ll monitor. The server will use a MySQL database to record monitoring data and use Apache to serve the web interface.

## Prerequisites

To follow this tutorial, you will need:

- Two Ubuntu 18.04 servers set up by following the [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a non-root user with sudo privileges and a firewall configured with `ufw`. On one server, you will install Zabbix; this tutorial will refer to this as the **Zabbix server**. It will monitor your second server; this second server will be referred to as the **second Ubuntu server**.

- The server that will run the Zabbix server needs Apache, MySQL, and PHP installed. Follow [this guide](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) to configure those on your Zabbix server.

Additionally, because the Zabbix Server is used to access valuable information about your infrastructure that you would not want unauthorized users to access, it’s important that you keep your server secure by installing a TLS/SSL certificate. This is optional but **strongly encouraged**. You can follow the [Let’s Encrypt on Ubuntu 18.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) guide to obtain the free TLS/SSL certificate.

## Step 1 — Installing the Zabbix Server

First, you need to install Zabbix on the server where you installed MySQL, Apache, and PHP. Log into this machine as your non-root user:

    ssh sammy@zabbix_server_ip_address

Zabbix is available in Ubuntu’s package manager, but it’s outdated, so use the [official Zabbix repository](https://repo.zabbix.com/) to install the latest stable version. Download and install the repository configuration package:

    wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
    sudo dpkg -i zabbix-release_4.2-1+bionic_all.deb

You will see the following output:

    OutputSelecting previously unselected package zabbix-release.
    (Reading database ... 61483 files and directories currently installed.)
    Preparing to unpack zabbix-release_4.2-1+bionic_all.deb ...
    Unpacking zabbix-release (4.2-1+bionicc) ...
    Setting up zabbix-release (4.2-1+bionicc) ...

Update the package index so the new repository is included:

    sudo apt update

Then install the Zabbix server and web frontend with MySQL database support:

    sudo apt install zabbix-server-mysql zabbix-frontend-php

Also, install the Zabbix agent, which will let you collect data about the Zabbix server status itself.

    sudo apt install zabbix-agent

Before you can use Zabbix, you have to set up a database to hold the data that the Zabbix server will collect from its agents. You can do this in the next step.

## Step 2 — Configuring the MySQL Database for Zabbix

You need to create a new MySQL database and populate it with some basic information in order to make it suitable for Zabbix. You’ll also create a specific user for this database so Zabbix isn’t logging into MySQL with the `root` account.

Log into MySQL as the **root** user using the **root** password that you set up during the MySQL server installation:

    mysql -uroot -p

Create the Zabbix database with UTF-8 character support:

    create database zabbix character set utf8 collate utf8_bin;

Then create a user that the Zabbix server will use, give it access to the new database, and set the password for the user:

    grant all privileges on zabbix.* to zabbix@localhost identified by 'your_zabbix_mysql_password';

Then apply these new permissions:

    flush privileges;

That takes care of the user and the database. Exit out of the database console.

    quit;

Next you have to import the initial schema and data. The Zabbix installation provided you with a file that sets this up.

Run the following command to set up the schema and import the data into the `zabbix` database. Use `zcat` since the data in the file is compressed.

    zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -p zabbix

Enter the password for the `zabbix` MySQL user that you configured when prompted.

This command will not output any errors if it was successful. If you see the error `ERROR 1045 (28000): Access denied for user`zabbix`@'localhost' (using password: YES)` then make sure you used the password for the **_zabbix_** user and not the **root** user.

In order for the Zabbix server to use this database, you need to set the database password in the Zabbix server configuration file. Open the configuration file in your preferred text editor. This tutorial will use `nano`:

    sudo nano /etc/zabbix/zabbix_server.conf

Look for the following section of the file:

/etc/zabbix/zabbix\_server.conf

    ### Option: DBPassword                           
    # Database password. Ignored for SQLite.   
    # Comment this line if no password is used.
    #                                                
    # Mandatory: no                                  
    # Default:                                       
    # DBPassword=

These comments in the file explain how to connect to the database. You need to set the `DBPassword` value in the file to the password for your database user. Add this line below those comments to configure the database:

/etc/zabbix/zabbix\_server.conf

    ...
    DBPassword=your_zabbix_mysql_password

Save and close `zabbix_server.conf` by pressing `CTRL+X`, followed by `Y` and then `ENTER` if you’re using `nano`.

That takes care of the Zabbix server configuration. Next, you will make some modifications to your PHP setup in order for the Zabbix web interface to work properly.

## Step 3 — Configuring PHP for Zabbix

The Zabbix web interface is written in PHP and requires some special PHP server settings. The Zabbix installation process created an Apache configuration file that contains these settings. It is located in the directory `/etc/zabbix` and is loaded automatically by Apache. You need to make a small change to this file, so open it up with the following:

    sudo nano /etc/zabbix/apache.conf

The file contains PHP settings that meet the necessary requirements for the Zabbix web interface. However, the timezone setting is commented out by default. To make sure that Zabbix uses the correct time, you need to set the appropriate timezone.

/etc/zabbix/apache.conf

    ...
    <IfModule mod_php7.c>
        php_value max_execution_time 300
        php_value memory_limit 128M
        php_value post_max_size 16M
        php_value upload_max_filesize 2M
        php_value max_input_time 300
        php_value always_populate_raw_post_data -1
        # php_value date.timezone Europe/Riga
    </IfModule>

Uncomment the timezone line, highlighted in the preceding code block, and change it to your timezone. You can use this [list of supported time zones](http://php.net/manual/en/timezones.php) to find the right one for you. Then save and close the file.

Now restart Apache to apply these new settings.

    sudo systemctl restart apache2

You can now start the Zabbix server.

    sudo systemctl start zabbix-server

Then check whether the Zabbix server is running properly:

    sudo systemctl status zabbix-server

You will see the following status:

    Output● zabbix-server.service - Zabbix Server
       Loaded: loaded (/lib/systemd/system/zabbix-server.service; disabled; vendor preset: enabled)
       Active: active (running) since Fri 2019-04-05 08:50:54 UTC; 3s ago
      Process: 16497 ExecStart=/usr/sbin/zabbix_server -c $CONFFILE (code=exited, status=0/SUCCESS)
      ...

Finally, enable the server to start at boot time:

    sudo systemctl enable zabbix-server

The server is set up and connected to the database. Next, set up the web frontend.

**Note:** As mentioned in the Prerequisites section, it is recommended that you enable SSL/TLS on your server. You can follow [this tutorial](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) now to obtain a free SSL certificate for Apache on Ubuntu 18.04. After obtaining your SSL/TLS certificates, you can come back and complete this tutorial.

## Step 4 — Configuring Settings for the Zabbix Web Interface

The web interface lets you see reports and add hosts that you want to monitor, but it needs some initial setup before you can use it. Launch your browser and go to the address `http://zabbix_server_name/zabbix/`. On the first screen, you will see a welcome message. Click **Next step** to continue.

On the next screen, you will see the table that lists all of the prerequisites to run Zabbix.

![Prerequisites](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Prerequisites.png)

All of the values in this table must be **OK** , so verify that they are. Be sure to scroll down and look at all of the prerequisites. Once you’ve verified that everything is ready to go, click **Next step** to proceed.

The next screen asks for database connection information.

![DB Connection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/DB_Connection.png)

You told the Zabbix server about your database, but the Zabbix web interface also needs access to the database to manage hosts and read data. Therefore enter the MySQL credentials you configured in Step 2 and click **Next step** to proceed.

On the next screen, you can leave the options at their default values.

![Zabbix Server Details](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Server_Details.png)

The **Name** is optional; it is used in the web interface to distinguish one server from another in case you have several monitoring servers. Click **Next step** to proceed.

The next screen will show the pre-installation summary so you can confirm everything is correct.

![Summary](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Summary.png)

Click **Next step** to proceed to the final screen.

The web interface setup is complete! This process creates the configuration file `/usr/share/zabbix/conf/zabbix.conf.php` which you could back up and use in the future. Click **Finish** to proceed to the login screen. The default user is **Admin** and the password is **zabbix**.

Before you log in, set up the Zabbix agent on your second Ubuntu server.

## Step 5 — Installing and Configuring the Zabbix Agent

Now you need to configure the agent software that will send monitoring data to the Zabbix server.

Log in to the second Ubuntu server:

    ssh sammy@second_ubuntu_server_ip_address

Then, just like on the Zabbix server, run the following commands to install the repository configuration package:

    wget https://repo.zabbix.com/zabbix/4.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.2-1+bionic_all.deb
    sudo dpkg -i zabbix-release_4.2-1+bionic_all.deb

Next, update the package index:

    sudo apt update

Then install the Zabbix agent:

    sudo apt install zabbix-agent

While Zabbix supports certificate-based encryption, setting up a certificate authority is beyond the scope of this tutorial, but you can use pre-shared keys (PSK) to secure the connection between the server and agent.

First, generate a PSK:

    sudo sh -c "openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk"

Show the key so you can copy it somewhere. You will need it to configure the host.

    cat /etc/zabbix/zabbix_agentd.psk

The key will look something like this:

    Output12eb854dea38ac9ee7d1ded2d74cee6262b0a56710f6946f7913d674ab82cdd4

Now edit the Zabbix agent settings to set up its secure connection to the Zabbix server. Open the agent configuration file in your text editor:

    sudo nano /etc/zabbix/zabbix_agentd.conf

Each setting within this file is documented via informative comments throughout the file, but you only need to edit some of them.

First you have to edit the IP address of the Zabbix server. Find the following section:

/etc/zabbix/zabbix\_agentd.conf

    ...
    ### Option: Server
    # List of comma delimited IP addresses (or hostnames) of Zabbix servers.
    # Incoming connections will be accepted only from the hosts listed here.
    # If IPv6 support is enabled then '127.0.0.1', '::127.0.0.1', '::ffff:127.0.0.1' are treated equally.
    #
    # Mandatory: no
    # Default:
    # Server=
    
    Server=127.0.0.1
    ...

Change the default value to the IP of your Zabbix server:

/etc/zabbix/zabbix\_agentd.conf

    ...
    Server=zabbix_server_ip_address
    ...

Next, find the section that configures the secure connection to the Zabbix server and enable pre-shared key support. Find the `TLSConnect` section, which looks like this:

/etc/zabbix/zabbix\_agentd.conf

    ...
    ### Option: TLSConnect
    # How the agent should connect to server or proxy. Used for active checks.
    # Only one value can be specified:
    # unencrypted - connect without encryption
    # psk - connect using TLS and a pre-shared key
    # cert - connect using TLS and a certificate
    #
    # Mandatory: yes, if TLS certificate or PSK parameters are defined (even for 'unencrypted' connection)
    # Default:
    # TLSConnect=unencrypted
    ...

Then add this line to configure pre-shared key support:

/etc/zabbix/zabbix\_agentd.conf

    ...
    TLSConnect=psk
    ...

Next, locate the `TLSAccept` section, which looks like this:

/etc/zabbix/zabbix\_agentd.conf

    ...
    ### Option: TLSAccept
    # What incoming connections to accept.
    # Multiple values can be specified, separated by comma:
    # unencrypted - accept connections without encryption
    # psk - accept connections secured with TLS and a pre-shared key
    # cert - accept connections secured with TLS and a certificate
    #
    # Mandatory: yes, if TLS certificate or PSK parameters are defined (even for 'unencrypted' connection)
    # Default:
    # TLSAccept=unencrypted
    ...

Configure incoming connections to support pre-shared keys by adding this line:

/etc/zabbix/zabbix\_agentd.conf

    ...
    TLSAccept=psk
    ...

Next, find the `TLSPSKIdentity` section, which looks like this:

/etc/zabbix/zabbix\_agentd.conf

    ...
    ### Option: TLSPSKIdentity
    # Unique, case sensitive string used to identify the pre-shared key.
    #
    # Mandatory: no
    # Default:
    # TLSPSKIdentity=
    ...

Choose a unique name to identify your pre-shared key by adding this line:

/etc/zabbix/zabbix\_agentd.conf

    ...
    TLSPSKIdentity=PSK 001
    ...

You’ll use this as the **PSK ID** when you add your host through the Zabbix web interface.

Then set the option that points to your previously created pre-shared key. Locate the `TLSPSKFile` option:

/etc/zabbix/zabbix\_agentd.conf

    ...
    ### Option: TLSPSKFile
    # Full pathname of a file containing the pre-shared key.
    #
    # Mandatory: no
    # Default:
    # TLSPSKFile=
    ...

Add this line to point the Zabbix agent to your PSK file you created:

/etc/zabbix/zabbix\_agentd.conf

    ...
    TLSPSKFile=/etc/zabbix/zabbix_agentd.psk
    ...

Save and close the file. Now you can restart the Zabbix agent and set it to start at boot time:

    sudo systemctl restart zabbix-agent
    sudo systemctl enable zabbix-agent

For good measure, check that the Zabbix agent is running properly:

    sudo systemctl status zabbix-agent

You will see the following status, indicating the agent is running:

    Output● zabbix-agent.service - Zabbix Agent
       Loaded: loaded (/lib/systemd/system/zabbix-agent.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2019-04-05 09:03:04 UTC; 1s ago
      ...

The agent will listen on port `10050` for connections from the server. Configure UFW to allow connections to this port:

    sudo ufw allow 10050/tcp

You can learn more about UFW in [How To Set Up a Firewall with UFW on Ubuntu 18.04](how-to-set-up-a-firewall-with-ufw-on-ubuntu-18-04).

Your agent is now ready to send data to the Zabbix server. But in order to use it, you have to link to it from the server’s web console. In the next step, you will complete the configuration.

## Step 6 — Adding the New Host to the Zabbix Server

Installing an agent on a server you want to monitor is only half of the process. Each host you want to monitor needs to be registered on the Zabbix server, which you can do through the web interface.

Log in to the Zabbix Server web interface by navigating to the address `http://zabbix_server_name/zabbix/`.

![The Zabbix login screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Login_Screen.png)

When you have logged in, click on **Configuration** , and then **Hosts** in the top navigation bar. Then click the **Create host** button in the top right corner of the screen. This will open the host configuration page.

![Creating a host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Create_Host.png)

Adjust the **Host name** and **IP address** to reflect the host name and IP address of your second Ubuntu server, then add the host to a group. You can select an existing group, for example **Linux servers** , or create your own group. The host can be in multiple groups. To do this, enter the name of an existing or new group in the **Groups** field and select the desired value from the proposed list.

Once you’ve added the group, click the **Templates** tab.

![Adding a template to the host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Add_Template.png)

Type `Template OS Linux` in the **Search** field and then click **Add** to add this template to the host.

Next, navigate to the **Encryption** tab. Select **PSK** for both **Connections to host** and **Connections from host**. Then set **PSK identity** to `PSK 001`, which is the value of the **TLSPSKIdentity** setting of the Zabbix agent you configured previously. Then set **PSK** value to the key you generated for the Zabbix agent. It’s the one stored in the file `/etc/zabbix/zabbix_agentd.psk` on the agent machine.

![Setting up the encryption](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Set_Up_Encryption.png)

Finally, click the **Add** button at the bottom of the form to create the host.

You will see your new host in the list. Wait for a minute and reload the page to see green labels indicating that everything is working fine and the connection is encrypted.

![Zabbix shows your new host](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/New_Host.png)

If you have additional servers you need to monitor, log in to each host, install the Zabbix agent, generate a PSK, configure the agent, and add the host to the web interface following the same steps you followed to add your first host.

The Zabbix server is now monitoring your second Ubuntu server. Now, set up email notifications to be notified about problems.

## Step 7 — Configuring Email Notifications

Zabbix automatically supports several types of notifications: email, [Jabber](https://www.jabber.org/), SMS, etc. You can also use alternative notification methods, such as Telegram or Slack. You can see the full list of integrations [here](https://www.zabbix.com/ru/integrations/?cat=notifications_alerting).

The simplest communication method is email, and this tutorial will configure notifications for this media type.

Click on **Administration** , and then **Media types** in the top navigation bar. You will see the list of all media types. Click on **Email**.

Adjust the SMTP options according to the settings provided by your email service. This tutorial uses Gmail’s SMTP capabilities to set up email notifications; if you would like more information about setting this up, see [How To Use Google’s SMTP Server](how-to-use-google-s-smtp-server).

**Note:** If you use 2-Step Verification with Gmail, you need to generate an App Password for Zabbix. You don’t need to remember it, you’ll only have to enter an App password once during setup. You will find instructions on how to generate this password in the [Google Help Center](https://support.google.com/accounts/answer/185833?hl=en).

You can also choose the message format—html or plain text. Finally, click the **Update** button at the bottom of the form to update the email parameters.

![Setting up email](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Set_Up_Email.png)

Now, create a new user. Click on **Administration** , and then **Users** in the top navigation bar. You will see the list of users. Then click the **Create user** button in the top right corner of the screen. This will open the user configuration page.

![Creating a user](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Create_User.png)

Enter the new username in the **Alias** field and set up a new password. Next, add the user to the administrator’s group. Type `Zabbix administrators` in the **Groups** field and select it from the proposed list.

Once you’ve added the group, click the **Media** tab and click on the **Add** underlined link. You will see a pop-up window.

![Adding an email](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Add_Email.png)

Enter your email address in the **Send to** field. You can leave the rest of the options at the default values. Click the **Add** button at the bottom to submit.

Now navigate to the **Permissions** tab. Select **Zabbix Super Admin** from the **User type** drop-down menu.

Finally, click the **Add** button at the bottom of the form to create the user.

Now you need to enable notifications. Click on the **Configuration** tab, and then **Actions** in the top navigation bar. You will see a pre-configured action, which is responsible for sending notifications to all Zabbix administrators. You can review and change the settings by clicking on its name. For the purposes of this tutorial, use the default parameters. To enable the action, click on the red **Disabled** link in the **Status** column.

Now you are ready to receive alerts. In the next step, you will generate one to test your notification setup.

## Step 8 — Generating a Test Alert

In this step, you will generate a test alert to ensure everything is connected. By default, Zabbix keeps track of the amount of free disk space on your server. It automatically detects all disk mounts and adds the corresponding checks. This discovery is executed every hour, so you need to wait a while for the notification to be triggered.

Create a temporary file that’s large enough to trigger Zabbix’s file system usage alert. To do this, log in to your second Ubuntu server if you’re not already connected.

    ssh sammy@second_ubuntu_server_ip_address

Next, determine how much free space you have on the server. You can use the `df` command to find out:

    df -h

The command `df` will report the disk space usage of your file system, and the `-h` will make the output human-readable. You’ll see output like the following:

    OutputFilesystem Size Used Avail Use% Mounted on
    /dev/vda1 25G 1.2G 23G 5% /

In this case, the free space is **23GB**. Your free space may differ.

Use the `fallocate` command, which allows you to pre-allocate or de-allocate space to a file, to create a file that takes up more than 80% of the available disk space. This will be enough to trigger the alert:

    fallocate -l 20G /tmp/temp.img

After around an hour, Zabbix will trigger an alert about the amount of free disk space and will run the action you configured, sending the notification message. You can check your inbox for the message from the Zabbix server. You will see a message like:

    OutputProblem started at 10:37:54 on 2019.04.05
    Problem name: Free disk space is less than 20% on volume /
    Host: Second Ubuntu server
    Severity: Warning
    
    Original problem ID: 34

You can also navigate to the **Monitoring** tab, and then **Dashboard** to see the notification and its details.

![Main dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66209/Main_Dashboard.png)

Now that you know the alerts are working, delete the temporary file you created so you can reclaim your disk space:

    rm -f /tmp/temp.img

After a minute Zabbix will send the recovery message and the alert will disappear from main dashboard.

## Conclusion

In this tutorial, you learned how to set up a simple and secure monitoring solution which will help you monitor the state of your servers. It can now warn you of problems, and you have the opportunity to analyze the processes occurring in your IT infrastructure.

To learn more about setting up monitoring infrastructure, check out [How To Install Elasticsearch, Logstash, and Kibana (Elastic Stack) on Ubuntu 18.04](how-to-install-elasticsearch-logstash-and-kibana-elastic-stack-on-ubuntu-18-04) and [How To Gather Infrastructure Metrics with Metricbeat on Ubuntu 18.04](how-to-gather-infrastructure-metrics-with-metricbeat-on-ubuntu-18-04).
