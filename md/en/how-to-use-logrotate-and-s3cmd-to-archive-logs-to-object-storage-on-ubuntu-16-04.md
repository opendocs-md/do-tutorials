---
author: Brian Boucheron
date: 2017-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-logrotate-and-s3cmd-to-archive-logs-to-object-storage-on-ubuntu-16-04
---

# How To Use Logrotate and S3cmd to Archive Logs to Object Storage on Ubuntu 16.04

## Introduction

The log files produced by your servers and applications are full of information that is potentially useful when debugging software, investigating security incidents, and generating insightful metrics and statistics.

A typical logging strategy nowadays is to centralize all this information through a log aggregation service such as [the Elastic stack](https://www.digitalocean.com/community/tutorial_series/centralized-logging-with-elk-stack-elasticsearch-logstash-and-kibana-on-ubuntu-14-04) or [Graylog](how-to-manage-logs-with-graylog-2-on-ubuntu-16-04). This is great for real-time analysis and short- to medium-term historical investigations, but often it’s not possible to retain long-term data in these systems due to storage constraints or other server resource issues.

A common solution for these long-term storage needs is archiving logs with an object storage service. The logs can remain available indefinitely for later analysis, legal retention requirements, or for backup purposes.

In this tutorial, we will use Logrotate on an Ubuntu 16.04 server to send `syslog` logs to an object storage service. This technique could be applied to any logs handled by Logrotate.

## Prerequisites

To complete this tutorial, you will need the following:

- An Ubuntu 16.04 server, with a non-root sudo-enabled user, as described in [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04). The configurations in this tutorial should work more broadly on many different Linux distributions, but may require some adaptation.
- You should be familiar with Logrotate and how the default configuration is set up on Ubuntu 16.04. Please read [How To Manage Logfiles with Logrotate on Ubuntu 16.04](how-to-manage-logfiles-with-logrotate-on-ubuntu-16-04) for more information.
- You will need to know the following details about your object storage service:

When you have completed the prerequisites, SSH into your server to begin.

## Step 1 — Installing S3cmd

We will be using a tool called **S3cmd** to send our logs to any S3-compatible object storage service. Before installing S3cmd, we need to install some tools to help us install Python programs (S3cmd is written in Python):

    sudo apt-get update
    sudo apt-get install python-setuptools

Next, change to a directory you can write to, then download the S3cmd `.tar.gz` file:

    cd /tmp
    curl -LO https://github.com/s3tools/s3cmd/releases/download/v2.0.1/s3cmd-2.0.1.tar.gz

**Note:** You can check to see if a newer version of S3cmd is available by visiting [their **Releases** page on Github](https://github.com/s3tools/s3cmd/releases). If you find a new version, copy the `.tar.gz` URL and substitute it in the `curl` command above.

When the download has completed, unzip and unpack the file using the `tar` utility:

    tar xf s3cmd-*.tar.gz

Then, change into the resulting directory and install the software using `sudo`:

    cd s3cmd-*
    sudo python setup.py install

Test the install by asking `s3cmd` for its version information:

    s3cmd --version

    Outputs3cmd version 2.0.1

If you see similar output, S3cmd has been successfully installed. Next, we’ll configure S3cmd to connect to our object storage service.

## Step 2 — Configuring S3cmd

S3cmd has an interactive configuration process that can create the configuration file we need to connect to our object storage server. The **root** user will need access to this configuration file, so we’ll start the configuration process using `sudo` and place the configuration file in the **root** user’s home directory:

    sudo s3cmd --configure --config=/root/logrotate-s3cmd.config

The interactive setup will begin. When appropriate, you may accept the default answers (in brackets) by pressing `ENTER`. We will walk through the options below, with suggested answers for a Space in DigitalOcean’s NYC3 region. Substitute the S3 endpoint and bucket template as needed for other DigitalOcean datacenters or other object storage providers:

- Access Key: `your-access-key`
- Secret Key: `your-secret-key`
- Default Region [US]: `ENTER`
- S3 Endpoint [s3.amazonaws.com]: `nyc3.digitaloceanspaces.com`
- DNS-style bucket+hostname:port template for accessing a bucket [%(bucket)s.s3.amazonaws.com]: `%(bucket)s.nyc3.digitaloceanspaces.com`
- Encryption password: `ENTER`, or specify a password to encrypt
- Path to GPG program [/usr/bin/gpg]: `ENTER`
- Use HTTPS protocol [Yes]: `ENTER`
- HTTP Proxy server name: `ENTER`, or fill out your proxy information

At this point, `s3cmd` will summarize your responses, then ask you to test the connection. Press `y` then `ENTER` to start the test:

    OutputTest access with supplied credentials? [Y/n] y
    Please wait, attempting to list all buckets...
    Success. Your access key and secret key worked fine :-)

After the test you’ll be prompted to save the settings. Again, type `y` then `ENTER` to do so. The configuration file will be written to the location we previously specified using the `--config` command line option.

In the next step, we’ll set up Logrotate to use S3cmd to upload our logs.

## Step 3 — Setting up Logrotate to Send Rotated Logs to Object Storage

Logrotate is a powerful and flexible system to manage the rotation and compression of log files. Ubuntu uses it by default to maintain all of the system logs found in `/var/log`.

For this tutorial, we are going to update the configuration to send the `syslog` log to object storage whenever it is rotated.

First, open the Logrotate configuration file for `rsyslog`, the system log processor:

    sudo nano /etc/logrotate.d/rsyslog

There will be two configuration blocks. We’re interested in the first one, which deals with `/var/log/syslog`:

/etc/logrotate.d/rsyslog

    /var/log/syslog
    {
        rotate 7
        daily
        missingok
        notifempty
        delaycompress
        compress
        postrotate
            invoke-rc.d rsyslog rotate > /dev/null
        endscript
    }
    . . .

This configuration specifies that `/var/log/syslog` will be rotated daily (`daily`), with seven old logs being kept (`rotate 7`). It will not produce an error if the log file is missing (`missingok`) and it won’t rotate the log if it’s empty (`notifempty`). Rotated logs will be compressed (`compress`), but not the most recent one (`delaycompress`). Finally, the `postrotate` script tells `rsyslog` to switch to the new log file after the old one has been rotated away.

Before we add our new configuration directives, delete the `delaycompress` line, highlighted above. We want all of our old logs to be compressed immediately before sending them to object storage.

Next, add the following lines to the end of the configuration block (outside of the `postrotate` … `endscript` block but inside of the closing `}` bracket):

/etc/logrotate.d/rsyslog

    . . .
            dateext
            dateformat -%Y-%m-%d-%s
            lastaction
                    HOSTNAME=`hostname`
                    /usr/local/bin/s3cmd sync --config=/root/logrotate-s3cmd.config /var/log/syslog*.gz "s3://your-bucket-name/$HOSTNAME/"
            endscript
    . . .

Be sure to substitute the correct bucket name for the highlighted portion above. These options will turn on date-based filename extensions (`dateext`) so we can timestamp our log files. We then set the format of these extensions with `dateformat`. The files will end up with filenames like `syslog-2017-11-07-1510091490.gz`: year, month, date, then a timestamp. The timestamp ensures we can ship two log files in the same day without the filenames conflicting. This is necessary in case we need to force a log rotation for some reason (more on that in the next step).

The `lastaction` script runs after all the log files have been compressed. It sets a variable with the server’s hostname, then uses `s3cmd sync` to sync all the syslog files up to your object storage bucket, placing them in a folder named with the hostname. Note that the final slash in `"s3://your-bucket-name/$HOSTNAME/"` is significant. Without it, `s3cmd` would treat `/$HOSTNAME` as a single file, not a directory full of log files.

Save and close the configuration file. The next time Logrotate does its daily run, `/var/log/syslog` will be moved to a date-based filename, compressed, and uploaded.

We can force this to happen immediately to test that it’s working properly:

    sudo logrotate /etc/logrotate.conf --verbose --force

    Outputrotating pattern: /var/log/syslog
    . . .
    considering log /var/log/syslog
      log needs rotating
    . . .
    running last action script
    switching euid to 0 and egid to 0
    upload: '/var/log/syslog-2017-11-08-1510175806.gz' -> 's3://example-bucket/example-hostname/syslog-2017-11-08-1510175806.gz' [1 of 1]
     36236 of 36236 100% in 0s 361.16 kB/s done
    Done. Uploaded 36236 bytes in 1.0 seconds, 35.39 kB/s.

This will output a lot of information for many log files. The portions relevant to the `syslog` log and our upload is excerpted above. Your output should look similar, with some evidence of a successful upload. You may have more files being uploaded if the server is not brand new.

Next, we’ll optionally set up a service to help us upload logs before system shutdowns.

## Step 4 — Sending Logs On Shutdown

This step is optional, and only necessary if you’re configuring ephemeral servers that are frequently being shut down and destroyed. If this is the case, you could lose up to a day of logs every time you destroy a server.

To fix this, we need to force Logrotate to run one last time before the system shuts down. We’ll do this by creating a systemd service that runs the `logrotate` command when it is stopped.

First, open up a new service file in a text editor:

    sudo nano /etc/systemd/system/logrotate-shutdown.service

Paste in the following service definition:

/etc/systemd/system/logrotate-shutdown.service

    [Unit]
    Description=Archive logs before shutdown
    After=network.target
    
    [Service]
    RemainAfterExit=yes
    ExecStop=/usr/sbin/logrotate /etc/logrotate.conf --force
    
    [Install]
    WantedBy=multi-user.target

This file defines a service that does nothing when started (it lacks an `ExecStart` statement), and runs `logrotate` (with the `--force` option) when stopped. It will be run before the network connection is shut down due to the `After=network.target` line.

Save the file and exit your text editor, then `start` and `enable` the service using `systemctl`:

    sudo systemctl start logrotate-shutdown.service
    sudo systemctl enable logrotate-shutdown.service

Check the status of the new service:

    sudo systemctl status logrotate-shutdown.service

    Output● logrotate-shutdown.service - Archive logs before shutdown
       Loaded: loaded (/etc/systemd/system/logrotate-shutdown.service; enabled; vendor preset: enabled)
       Active: active (exited) since Wed 2017-11-08 20:00:05 UTC; 8s ago
    
    Nov 08 20:00:05 example-host systemd[1]: Started Archive logs before shutdown.

We want to see that it is `active`. The fact that it has `exited` is fine, that’s due to having no `ExecStart` command.

You can test that the new service is functioning either by stopping it manually:

    sudo systemctl stop logrotate-shutdown.service

or by rebooting your system:

    sudo reboot

Either method will trigger the Logrotate command and upload a new log file. Now, barring an ungraceful shutdown, you’ll lose no logs when destroying a server.

**Note:** many cloud platforms **do not** perform a graceful shutdown when a server is being destroyed or terminated. You will need to test this functionality with your particular setup, and either configure it for graceful shutdowns or find another solution for triggering a final log rotation.

## Conclusion

In this tutorial we installed S3cmd, configured it to connect to our object storage service, and configured Logrotate to upload log files when it rotates `/var/log/syslog`. We then set up a systemd service to run `logrotate --force` on shutdown, to make sure we don’t lose any logs when destroying ephemeral servers.

To learn more about the configurations available for Logrotate, refer to its manual page by entering `man logrotate` on the command line. More information about S3cmd can be found on [their website](http://s3tools.org/).
