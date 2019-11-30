---
author: finid
date: 2014-12-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ossec-security-notifications-on-ubuntu-14-04
---

# How To Install and Configure OSSEC Security Notifications on Ubuntu 14.04

## Introduction

**How do you keep track of authorized and unauthorized activity on your server?**

OSSEC is one tool you can install on your server to keep track of its activity.

OSSEC is an open-source, host-based intrusion detection system (HIDS) that performs log analysis, integrity checking, Windows registry monitoring, rootkit detection, time-based alerting, and active response. It can be used to monitor one server or thousands of servers in a server/agent mode.

If properly configured, OSSEC can give you a real-time view into what’s happening on your server.

This tutorial will show you how to install and configure OSSEC to monitor one DigitalOcean server running Ubuntu 14.04 LTS. We’ll configure OSSEC so that if a file is modified, deleted, or added to the server, OSSEC will notify you by email - in real-time. That’s in addition to other integrity-checking features that OSSEC offers.

OSSEC can do more than notify you of file modifications, but one article is not enough to show you how to take advantage of all its features.

\*\*What are the benefits of OSSEC?

Before we get to the install-and-configure part, let’s look at a couple of concrete benefits that you get from using OSSEC.

Below is an example of an email notification from OSSEC, showing that the file /var/ossec/etc/ossec.conf was modified.

    OSSEC HIDS Notification.
    2014 Nov 29 09:45:15
    
    Received From: kuruji->syscheck
    Rule: 552 fired (level 7) -> "Integrity checksum changed again (3rd time)."
    Portion of the log(s):
    
    Integrity checksum changed for: '/var/ossec/etc/ossec.conf'
    Size changed from '7521' to '7752'

If you received such an alert, and you were not expecting that file to change, then you know that something unauthorized has happened on your server.

Here’s another example email alert from OSSEC, showing that the file /etc/ossec/testossec.txt was deleted.

    OSSEC HIDS Notification.
    2014 Nov 29 10:56:14
    
    Received From: kuruji->syscheck
    Rule: 553 fired (level 7) -> "File deleted. Unable to retrieve checksum."
    Portion of the log(s):
    
    File /etc/ossec/testossec.txt was deleted. Unable to retrieve checksum.

Again, if you did not delete the file in question, you should figure out what is happening on your server.

Now, if the foregoing has tickled you enough to want to install OSSEC, here are a few things you need to do first.

### Prerequisites

You, of course, need to have a server that you want to monitor. This tutorial assumes that you already have one and that it’s already set up for use. It can be a server that you just set up today or that you’ve been using for months. The most important thing is that you have access to it and can log in via SSH. Setting up OSSEC is not something you want to undertake when you still don’t know how to ssh into your server.

- Ubuntu 14.04 server
- You should create a [sudo](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) user on the server. In this example, the user is named **sammy**. However, this tutorial will be much easier to complete as the **root** user:

    sudo su

- Optional: If you want to send mail from a local SMTP server, you should install [Postfix](how-to-install-and-setup-postfix-on-ubuntu-14-04) for simple email sending
- Installation of OSSEC involves some compiling, so you need `gcc` and `make` installed. You can install both by installing a single package called `build-essential`
- You also need to install a package called `inotify-tools`, which is required for real-time alerting to work

To install all required packages, first update the server:

    apt-get update

The install the packages:

    apt-get install build-essential inotify-tools

Now that we have the preliminaries sorted out, let’s get to the fun part.

## Step 1 — Download and Verify OSSEC

In this step, you’ll download the OSSEC tarball and a file containing its cryptographic checksums.

Since this a security article, we’re going to do a little extra work to verify that we’re installing valid software. The idea is that you generate the MD5 and SHA1 checksums of the downloaded OSSEC tarball and compare them with those in the checksum file. If they match, then you can assume that the tarball has not been tampered with.

At the time of writing, the latest server edition of OSSEC is version 2.8.1. To download it, type:

    wget -U ossec http://www.ossec.net/files/ossec-hids-2.8.1.tar.gz

To download the checksum file, type:

    wget -U ossec http://www.ossec.net/files/ossec-hids-2.8.1-checksum.txt

To verify that both files are in place, type:

    ls -l ossec*

You should see the files:

    ossec-hids-2.8.1-checksum.txt
    ossec-hids-2.8.1.tar.gz

Now, let’s examine the checksum file with the cat command, like so:

    cat ossec-hids-2.8.1-checksum.txt

Expected output:

    MD5(ossec-hids-2.8.1.tar.gz)= c2ffd25180f760e366ab16eeb82ae382
    SHA1(ossec-hids-2.8.1.tar.gz)= 0ecf1df09558dc8bb4b6f65e1fb2ca7a7df9817c

In the above output, the important parts are those to the right of the **=** sign. Those are the MD5 and SHA1 checksums of the tarball.

Now we’ll make sure the checksums we generate for the tarball match the checksums we downloaded.

To generate the MD5sum of the tarball, type:

    md5sum ossec-hids-2.8.1.tar.gz

Expected output:

    c2ffd25180f760e366ab16eeb82ae382 ossec-hids-2.8.1.tar.gz

Compare the generated MD5 checksum with the one in the checksum file. They should match.

Do the same for the SHA1 checksum by typing:

    sha1sum ossec-hids-2.8.1.tar.gz

Expected output:

    0ecf1df09558dc8bb4b6f65e1fb2ca7a7df9817c ossec-hids-2.8.1.tar.gz

If both match, you’re good to go. Step Two beckons.

## Step 2 — Install OSSEC

In this step, you’ll install OSSEC.

OSSEC can be installed in **server** , **agent** , **local** or **hybrid** mode. This installation is for monitoring the server that OSSEC is installed on. That means a **local** installation.

Before installation can start, you have to expand the file. You do that by typing:

    tar -zxf ossec-hids-2.8.1.tar.gz

After that, you should have a directory named ossec-hids-2.8.1. To start installation, you have to change (cd) into that directory, which you do by typing:

    cd ossec-hids-2.8.1

To see the contents of the directory that you’re now in, use the ls command by typing:

    ls -lgG

You should see these files and directories:

    total 100
    drwxrwxr-x 4 4096 Sep 8 21:03 active-response
    -rw-rw-r-- 1 542 Sep 8 21:03 BUGS
    -rw-rw-r-- 1 289 Sep 8 21:03 CONFIG
    drwxrwxr-x 6 4096 Sep 8 21:03 contrib
    -rw-rw-r-- 1 3196 Sep 8 21:03 CONTRIBUTORS
    drwxrwxr-x 4 4096 Sep 8 21:03 doc
    drwxrwxr-x 4 4096 Sep 8 21:03 etc
    -rw-rw-r-- 1 1848 Sep 8 21:03 INSTALL
    -rwxrwxr-x 1 32019 Sep 8 21:03 install.sh
    -rw-rw-r-- 1 24710 Sep 8 21:03 LICENSE
    -rw-rw-r-- 1 1664 Sep 8 21:03 README.md
    drwxrwxr-x 30 4096 Sep 8 21:03 src

The only file of interest to us in that listing is install.sh. That’s the OSSEC installation script. To initiate installation, type:

    ./install.sh

You will be prompted to answer some installation questions.

The first task that will be required of you is the selection of the language. As shown in the output below, the default is English. Throughout the installation process, if you’re required to make a selection, any entry in square brackets is the default. If the default is what you want, press the ENTER key to accept the default. Other than having to type your email address, we recommend that you accept all the defaults — unless you know what you’re doing.

Entries are shown in red.

So if your language is English, press `ENTER`. Otherwise, type the two letters for your language and press ENTER.

      (en/br/cn/de/el/es/fr/hu/it/jp/nl/pl/ru/sr/tr) [en]:
    

After selecting the language, you should see this:

    OSSEC HIDS v2.8 Installation Script - http://www.ossec.net
    
     You are about to start the installation process of the OSSEC HIDS.
     You must have a C compiler pre-installed in your system.
     If you have any questions or comments, please send an e-mail
     to dcid@ossec.net (or daniel.cid@gmail.com).
    
      - System: Linux kuruji 3.13.0-36-generic
      - User: root
      - Host: kuruji
    
      -- Press ENTER to continue or Ctrl-C to abort. --

After pressing ENTER, you should get:

    1- What kind of installation do you want (server, agent, local, hybrid or help)? local

Type `local` and press ENTER. You should get:

      - Local installation chosen.
    
    2- Setting up the installation environment.
    
      - Choose where to install the OSSEC HIDS [/var/ossec]:

Accept the default and press ENTER. After that, you’ll get:

        - Installation will be made at /var/ossec .
    
    3- Configuring the OSSEC HIDS.
    
      3.1- Do you want e-mail notification? (y/n) [y]:

Press ENTER.

      - What's your e-mail address? sammy@example.com

Type the email address where you want to receive notifications from OSSEC.

      - We found your SMTP server as: mail.example.com.
      - Do you want to use it? (y/n) [y]:
    
    --- Using SMTP server: mail.example.com.

Press ENTER unless you have specific SMTP server settings you want to use.

Now’s time to let OSSEC know what checks it should be running. In response to any prompt from the script, accept the default by pressing `ENTER`.

ENTER for the integrity check daemon.

      3.2- Do you want to run the integrity check daemon? (y/n) [y]:
    
    - Running syscheck (integrity check daemon).

ENTER for rootkit detection.

      3.3- Do you want to run the rootkit detection engine? (y/n) [y]:
    
    - Running rootcheck (rootkit detection).

ENTER for active response.

      3.4- Active response allows you to execute a specific command based on the events received.  
    
       Do you want to enable active response? (y/n) [y]:
    
       Active response enabled.

Accept the defaults for firewall-drop response. Your output may show some IPv6 options – that’s fine.

      Do you want to enable the firewall-drop response? (y/n) [y]:
    
    - firewall-drop enabled (local) for levels >= 6
    
       - Default white list for the active response:
          - 8.8.8.8
          - 8.8.4.4
    
       - Do you want to add more IPs to the white list? (y/n)? [n]:

**You may add your IP address here, but that’s not necessary.**

OSSEC will now present a default list of files that it will monitor. Additional files can be added after installation, so press ENTER.

    3.6- Setting the configuration to analyze the following logs:
        -- /var/log/auth.log
        -- /var/log/syslog
        -- /var/log/dpkg.log
    
     - If you want to monitor any other file, just change
       the ossec.conf and add a new localfile entry.
       Any questions about the configuration can be answered
       by visiting us online at http://www.ossec.net .
    
    
       --- Press ENTER to continue ---

By this time, the installer has all the information it needs to install OSSEC. Kick back and let the installer do its thing. Installation takes about 5 minutes. If installation is successful, you are now ready to start and configure OSSEC.

> **Note:** One reason installation might fail is if a compiler is not installed. In that case, you’ll get an error like this:
> 
> 5- Installing the system
> - Running the Makefile
> ./install.sh: 85: ./install.sh: make: not found
>     
> Error 0x5.
> Building error. Unable to finish the installation.
> 
> If you get that error, then you need to install `build-essential`, as explained in the Prerequisites section of the tutorial.

If installation succeeds, you should see this type of output:

     - System is Debian (Ubuntu or derivative).
     - Init script modified to start OSSEC HIDS during boot.
    
     - Configuration finished properly.
    
     - To start OSSEC HIDS:
                    /var/ossec/bin/ossec-control start
    
     - To stop OSSEC HIDS:
                    /var/ossec/bin/ossec-control stop
    
     - The configuration can be viewed or modified at /var/ossec/etc/ossec.conf
    
        --- Press ENTER to finish (maybe more information below). ---

OSSEC is now installed. The next step is to start it.

## Step 3 — Start OSSEC

By default OSSEC is configured to start at boot, but the first time, you’ll have to start it manually.

If you want to check its current status, type:

    /var/ossec/bin/ossec-control status

Expected output:

    ossec-monitord not running...
    ossec-logcollector not running...
    ossec-syscheckd not running...
    ossec-analysisd not running...
    ossec-maild not running...
    ossec-execd not running...

That tells you that none of OSSEC’s processes are running.

To start OSSEC, type:

    /var/ossec/bin/ossec-control start

You should see it starting up:

    Starting OSSEC HIDS v2.8 (by Trend Micro Inc.)...
    Started ossec-maild...
    Started ossec-execd...
    Started ossec-analysisd...
    Started ossec-logcollector...
    Started ossec-syscheckd...
    Started ossec-monitord...
    Completed.

If you check the status again, you should get confirmation that OSSEC is now running.

    /var/ossec/bin/ossec-control status

This output shows that OSSEC is running:

    ossec-monitord is running...
    ossec-logcollector is running...
    ossec-syscheckd is running...
    ossec-analysisd is running...
    ossec-maild is running...
    ossec-execd is running...

Right after starting OSSEC, you should get an email that reads like this:

    OSSEC HIDS Notification.
    2014 Nov 30 11:15:38
    
    Received From: ossec2->ossec-monitord
    Rule: 502 fired (level 3) -> "Ossec server started."
    Portion of the log(s):
    
    ossec: Ossec started.

That’s another confirmation that OSSEC is working and will send you email alerts whenever something it’s configured to monitor happens. Even when it is restarted, OSSEC will send you an email.

If you didn’t get this email right away, don’t worry. You may still need to tweak your email settings (which we’ll cover later in the tutorial) to make sure your OSSEC server’s emails can get through to your mail provider. This is especially true for some 3rd-party email service providers like Google and Fastmail.

## Step 4 — Configure OSSEC for Real-time Alerts on File Modifications

Next, let’s get to know OSSEC’s files and directories, and learn how to change OSSEC’s monitoring and alert settings.

In this tutorial, we’ll modify OSSEC to notify you whenever a file is modified, deleted, or added to directories that you specify.

### Getting to know OSSEC’s directory structure

OSSEC’s default directory is a _chroot_-ed (sandbox) environment that only a user with root (admin) privileges can access. A standard user cannot `cd` into `/var/ossec` or even list the files in it. As the root (or admin) user, however, you can.

So, `cd` into the installation directory by typing:

    cd /var/ossec

To list the files in your new working directory, type:

    ls -lgG

You should see these files and directories:

    total 40
    dr-xr-x--- 3 4096 Nov 26 14:56 active-response
    dr-xr-x--- 2 4096 Nov 20 20:56 agentless
    dr-xr-x--- 2 4096 Nov 20 20:56 bin
    dr-xr-x--- 3 4096 Nov 29 00:49 etc
    drwxr-x--- 5 4096 Nov 20 20:56 logs
    dr-xr-x--- 11 4096 Nov 20 20:56 queue
    dr-xr-x--- 4 4096 Nov 20 20:56 rules
    drwxr-x--- 5 4096 Nov 20 21:00 stats
    dr-xr-x--- 2 4096 Nov 20 20:56 tmp
    dr-xr-x--- 3 4096 Nov 29 18:34 var

- OSSEC’s main configuration file is in the `/var/ossec/etc` directory.
- Predefined rules are in the `/var/ossec/rules` directory
- Commands used to manage OSSEC are in `/var/ossec/bin`
- Take note of the `/var/ossec/logs` directory. If OSSEC ever throws an error, the `/var/ossec/logs/ossec.log` file in that directory is the first place to look

### Main configuration file, /var/ossec/etc/ossec.conf

To access the main configuration file, you have to change into `/var/ossec/etc`. To do that, type:

    cd /var/ossec/etc

If you do an `ls` while in that directory, you’ll see these files and directories:

    ls -lgG

Results:

    total 120
    -r--r----- 1 97786 Sep 8 22:03 decoder.xml
    -r--r----- 1 2842 Sep 8 22:03 internal_options.conf
    -r--r----- 1 3519 Oct 30 13:46 localtime
    -r--r----- 1 7752 Nov 29 09:45 ossec.conf
    -rw-r----- 1 87 Nov 20 20:56 ossec-init.conf
    drwxrwx--- 2 4096 Nov 20 21:00 shared

The main configuration file is `/var/ossec/etc/ossec.conf`.

Before modifying the file, make a backup copy, just in case. To make that copy, use the `cp` command like so:

    cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.00

The idea is if your changes don’t work or mess up the system, you can revert to the copy and be back to normal. It’s the simplest disaster recovery practice that you should always take advantage of.

Now, open `ossec.conf` by using the `nano` editor.

    nano /var/ossec/etc/ossec.conf

The configuration file is a very long XML file with several sections.

### Email settings

> **Note:** Email is finicky in general, especially if you are sending to a stricter mail provider like sending to a Gmail address. Check your spam, and tweak your settings if necessary.

The first configuration options you’ll see are the email credentials you specified during installation. If you need to specify a different email address and/or SMTP server, this is the place to do it.

    <global>
        <email_notification>yes</email_notification>
        <email_to>sammy@example.com</email_to>
        <smtp_server>mail.example.com.</smtp_server>
        <email_from>ossecm@ossec_server</email_from>
    </global>

By default, OSSEC sends 12 emails per hour, so you’ll not be flooded with email alerts. You can increase or decrease that value by adding the `<email_maxperhour>N</email_maxperhour>` setting to that section so that it reads:

    <global>
        <email_notification>yes</email_notification>
        <email_to>sammy@example.com</email_to>
        <smtp_server>mail.example.com.</smtp_server>
        <email_from>ossecm@ossec_server</email_from>
        <email_maxperhour>N</email_maxperhour>
    </global>

Please replace `N` with the number of emails you want to receive per hour, between **1** and **9999**.

Some third-party email service providers (Google and Fastmail, for example) will silently drop alerts sent by OSSEC if the `<email_from>` address does not contain a valid domain part, like the one in the code block above. To avoid that, make sure that that email address contains a valid domain part. For example:

    <global>
        <email_notification>yes</email_notification>
        <email_to>sammy@example.com</email_to>
        <smtp_server>mail.example.com.</smtp_server>
        <email_from>sammy@ossec_server.com</email_from>
    </global>

The `<email_to>` and `<email_from>` addresses can be the same. For example:

    <global>
        <email_notification>yes</email_notification>
        <email_to>sammy@example.com</email_to>
        <smtp_server>mail.example.com.</smtp_server>
        <email_from>sammy@example.com</email_from>
    </global>

If you don’t want to use an external email provider’s SMTP server, you can specify your own SMTP server, if you have one configured. (This is not covered in this tutorial, but you can install Postfix following [these instructions](how-to-install-and-setup-postfix-on-ubuntu-14-04).) If your SMTP server is running on the same Droplet as OSSEC, change the `<smtp_server>` setting to `localhost`. For example:

    <global>
        <email_notification>yes</email_notification>
        <email_to>sammy@example.com</email_to>
        <smtp_server>localhost</smtp_server>
        <email_from>sammy@example.com</email_from>
    </global>

OSSEC does not send real-time alerts by default, but this tutorial calls for real-time notifications, so that’s one aspect that you’re going to modify.

If you still aren’t receiving expected emails from OSSEC, check the logs at `/var/ossec/logs/ossec.log` for mail errors.

Example mail errors:

    2014/12/18 17:48:35 os_sendmail(1767): WARN: End of DATA not accepted by server
    2014/12/18 17:48:35 ossec-maild(1223): ERROR: Error Sending email to 74.125.131.26 (smtp server)

You can use these error messages to help you debug any issues with receiving email notifications.

### Frequency of scans

In the `<syscheck>` section of `ossec.conf`, which starts like this:

    <syscheck>
        <!-- Frequency that syscheck is executed - default to every 22 hours -->
        <frequency>79200</frequency>
    

We will turn on alerts for new file creation. Add the line `<alert_new_files>yes</alert_new_files>` so that it reads like this:

    <syscheck>
        <!-- Frequency that syscheck is executed - default to every 22 hours -->
        <frequency>79200</frequency>
    
        <alert_new_files>yes</alert_new_files>

For testing purposes, you may also want to set the frequency of the system check to be much lower. By default, the system check is run every 22 hours. For testing purposes, you may want to set this to once a minute, that is, `60` seconds. **Revert this to a sane value when you are done testing.**

    <syscheck>
        <!-- Frequency that syscheck is executed - default to every 22 hours -->
        <frequency>60</frequency>
    
        <alert_new_files>yes</alert_new_files>

### Directory and file change settings

Right after that, you should see the list of system directories that OSSEC monitors. It reads like:

    <!-- Directories to check (perform all possible verifications) -->
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin</directories>

Let’s enable real-time monitoring by adding the settings `report_changes="yes" realtime="yes"` to each line. Modify these lines so they read:

    <!-- Directories to check (perform all possible verifications) -->
    <directories report_changes="yes" realtime="yes" check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories report_changes="yes" realtime="yes" check_all="yes">/bin,/sbin</directories>

`report_changes="yes"` does exactly what is says. Ditto for `realtime="yes"`.

In addition to the default list of directories that OSSEC has been configured to monitor, you can add new directories that you wish to monitor. In this next section, I’m going to tell OSSEC to monitor `/home/sammy` and `/var/www`. For that, I’m going to add a new line right under the existing ones, so that that section now reads:

    <!-- Directories to check (perform all possible verifications) -->
    <directories report_changes="yes" realtime="yes" check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories report_changes="yes" realtime="yes" check_all="yes">/bin,/sbin</directories>
    
    <directories report_changes="yes" realtime="yes" restrict=".php|.js|.py|.sh|.html" check_all="yes">/home/sammy,/var/www</directories>

You should modify the directories to match your desired settings. If your user is not named **sammy** , you will want to change the path to the home directory.

For the new directories to monitor, we’ve added the `restrict` option, which tells OSSEC to monitor only the specified file formats. You don’t have to use that option, but it comes in handy when you have other files, like image files, that you don’t want OSSEC to alert on.

That’s all the changes for `ossec.conf`. You may save and close the file.

### Local rules in /var/ossec/rules/local\_rules.xml

The next file to modify is in the `/var/ossec/rules` directory, so `cd` into it by typing:

    cd /var/ossec/rules

If you do an `ls` in that directory, you’ll see a bunch of XML files like these:

    ls -lgG

Abbreviated output:

    total 376
    -r-xr-x--- 1 5882 Sep 8 22:03 apache_rules.xml
    -r-xr-x--- 1 2567 Sep 8 22:03 arpwatch_rules.xml
    -r-xr-x--- 1 3726 Sep 8 22:03 asterisk_rules.xml
    -r-xr-x--- 1 4315 Sep 8 22:03 attack_rules.xml
    
    ...
    
    -r-xr-x--- 1 1772 Nov 30 17:33 local_rules.xml
    
    ...
    
    -r-xr-x--- 1 10359 Sep 8 22:03 ossec_rules.xml
    
    ...

Only two of those files are of interest to us now - `local_rules.xml` and `ossec_rules.xml`. The latter contains OSSEC’s default rule definitions, while the former is where you add your custom rules. In other words, aside from `local_rules.xml`, you don’t modify any files in this directory.

The default rule definitions in `ossec_rules.xml` are useful to look at so we can modify and copy them into our local rules. In `ossec_rules.xml`, the rule that fires when a file is _added_ to a monitored directory is rule **554**. By default, OSSEC does not send out alerts when that rule is triggered, so the task here is to change that behavior. Here’s what rule 554 looks like in the default version:

    <rule id="554" level="0">
    <category>ossec</category>
    <decoded_as>syscheck_new_entry</decoded_as>
    <description>File added to the system.</description>
    <group>syscheck,</group>
    </rule>

OSSEC does not send out an alert if a rule has a `level` set to **0**. We want to modify this rule to raise the alert level. Instead of changing it in the default file, we will copy the rule to `local_rules.xml` and modify it so that it can trigger an alert.

To do that, make a backup copy of the `/var/ossec/rules/local_rules.xml` file:

    cp /var/ossec/rules/local_rules.xml /var/ossec/rules/local_rules.xml.00

Edit the file with **nano** :

    nano /var/ossec/rules/local_rules.xml

Add the new rule at the end of the file. Make sure that it is within the `<group> ... </group>` tag.

    <rule id="554" level="7" overwrite="yes">
    <category>ossec</category>
    <decoded_as>syscheck_new_entry</decoded_as>
    <description>File added to the system.</description>
    <group>syscheck,</group>
    </rule>

Save and close the file.

Those are all the changes necessary.

### Restart OSSEC

All that’s left now is to restart OSSEC, something that has to be done any time you modify OSSEC’s files. To restart OSSEC type:

    /var/ossec/bin/ossec-control restart

If all is working correctly, you should receive an email from OSSEC informing you that it has (re)started.

## Step 5 — Trigger File Change Alerts

And depending on what happens in the directories that OSSEC has been configured to monitor, you should be getting emails that read something like this:

Now try creating a sample file in `/home/sammy`

    touch /home/sammy/index.html

Wait a minute. Add some content:

    nano /home/sammy/index.html

Wait a minute. Delete the file:

    rm /home/sammy/index.html

You should start receiving notifications like this:

    OSSEC HIDS Notification.
    2014 Nov 30 18:03:51
    
    Received From: ossec2->syscheck
    Rule: 550 fired (level 7) -> "Integrity checksum changed."
    Portion of the log(s):
    
    Integrity checksum changed for: '/home/sammy/index.html'
    Size changed from '21' to '46'
    What changed:
    1c1,4
    < This is an html file
    ---
    
        <!doctype html> <p>This is an html file</p>
    
    Old md5sum was: '4473d6ada73de51b5b36748627fa119b'
    New md5sum is : 'ef36c42cd7014de95680d656dec62de9'
    Old sha1sum was: '96bd9d685a7d23b20abd7d8231bb215521bcdb6c'
    New sha1sum is : '5ab0f31c32077a23c71c18018a374375edcd0b90'
    

Or this:

    OSSEC HIDS Notification.
    2014 Dec 01 10:13:31
    
    Received From: ossec2->syscheck
    Rule: 554 fired (level 7) -> "File added to the system."
    Portion of the log(s):
    
    New file '/var/www/header.html' added to the file system.

> **Note:** OSSEC does not send out real-time alerts on file additions, only on file modifications and deletions. Alerts on file additions go out after a full system check, which is governed by the frequency check time in `ossec.conf`.
> 
> nano /var/ossec/etc/ossec.conf
> 
> Setting for `frequency`:
> 
> <syscheck>
> <!-- Frequency that syscheck is executed - default to every 22 hours -->
> <frequency>79200</frequency>

Again, if you are not getting emails, check your spam, check your `/var/ossec/logs/ossec.log`, check your mail logs, etc.

### Conclusion

I hope this has given you a taste of what OSSEC has to offer. More advanced setups and configurations are possible, so stay tuned for future articles on how to deploy OSSEC to monitor and protect your servers.

For more information on OSSEC, visit the project’s website at [http://www.ossec.net/](http://www.ossec.net).
