---
author: finid
date: 2017-07-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-bro-on-ubuntu-16-04
---

# How to Install Bro on Ubuntu 16.04

## Introduction

[Bro](https://www.bro.org/) is an open-source network analysis framework and security monitoring application. It brings together some of the best features of [OSSEC](https://www.digitalocean.com/community/tutorials?q=ossec) and [osquery](https://www.digitalocean.com/community/tutorials?q=osquery) into one nice package.

Bro can perform both signature- and behavior-based analysis and detection, but the bulk of what it does is behavior-based analysis and detection. Included in the long list of Bro’s features are the ability to:

- Detect brute-force attacks against network services like SSH and FTP
- Perform HTTP traffic monitoring and analysis
- Detect changes in installed software
- Perform SSL/TLS certificate validation
- Detect SQL injection attacks
- Perform file integrity monitoring of all files
- Send activity, summary and crash reports and alerts via email
- Perform geolocation of IP addresses to city-level
- Operate in standalone or distributed mode

Bro may be installed from source or via a package manager. Installation from source is more involved, but it is the only method that supports IP geolocation, if the geolocation library is installed before it’s compiled.

Installing Bro makes additional commands like `bro` and `broctl` available to the system. `bro` can be used for analyzing trace files and also for live traffic analysis; `broctl` is the interactive shell and command line utility used to manage standalone or distributed Bro installations.

In this article, you’ll install Bro from source on Ubuntu 16.04 in standalone mode.

## Prerequisites

To complete this article, you’ll need to have the following:

- An Ubuntu 16.04 server with a firewall and non-root user account with sudo privileges configured using this [Initial Setup Guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04). Because we’ll be performing some tasks that require extra RAM, you’ll need to spin up a server that has at least 1 GB of memory.
- Postfix installed as a send-only mail transfer agent (MTA) on the server using [this Postfix on Ubuntu 16.04 guide](how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-16-04). An MTA like Postfix has to be installed for Bro to send email alerts. It will run without one, but emails will not be sent.

## Step 1 — Installing Dependencies

Before you can install Bro from source, you need to install its dependencies.

First, update the package database. Failure to do this before installing packages can lead to package manager errors.

    sudo apt-get update

Bro’s dependences include a number of libraries and tools, like [Libpcap](http://www.tcpdump.org/), [OpenSSL](https://www.openssl.org/), and [BIND8](https://www.isc.org/downloads/bind/). BroControl additionally requires Python 2.6 or higher. Because we’re building Bro from source, we’ll need some additional dependencies, like [CMake](http://www.cmake.org/), [SWIG](http://www.swig.org/), [Bison](https://www.gnu.org/software/bison/), and a C/C++ compiler.

You can install all the necessary dependencies at once:

    sudo apt-get install bison cmake flex g++ gdb make libmagic-dev libpcap-dev libgeoip-dev libssl-dev python-dev swig2.0 zlib1g-dev

After that installation has completed, the next step is to download the databases that Bro will use for IP geolocation.

## Step 2 — Downloading a GeoIP Database

Here, we’ll download a GeoIP database which Bro will depend on for IP address geolocation. We’ll download two compressed files containing an IPv4 and an IPv6 database, decompress them, and then move them into the `/usr/share/GeoIP` directory.

**Note** : We’re downloading a [free legacy GeoIP database](http://dev.maxmind.com/geoip/legacy/downloadable/) from [MaxMind](https://www.maxmind.com/en/home). A [newer IP database format](https://dev.maxmind.com/geoip/geoip2/downloadable/) has since been released, but Bro does not have support for it yet.

Download both the IPv4 and IPv6 databases.

    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz

Decompress both files, which will place two files named `GeoLiteCity.dat` and `GeoLiteCityv6.dat` in your working directory.

    gzip -d GeoLiteCity.dat.gz
    gzip -d GeoLiteCityv6.dat.gz

Then move into the appropriate directory, renaming them in the process.

    sudo mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat
    sudo mv GeoLiteCityv6.dat /usr/share/GeoIP/GeoIPCityv6.dat

With the GeoIP database in place, we can install Bro itself in the next step.

## Step 3 — Installing Bro From Source

To install Bro from source, we’ll first have to clone the repository from GitHub.

Git is already installed by default on Ubuntu, so you can clone the repository with the following command. The files will be put into a directory named `bro`.

    git clone --recursive git://git.bro.org/bro

Change into the project’s directory.

    cd bro

Run Bro’s configuration, which should take less than a minute.

    ./configure

Then use `make` to build the program. This can take up to 20 minutes, depending on your server.

    make

You’ll see a percentage completion at the beginning of most lines of output as it runs.

Once it finishes, install Bro, which should take less than a minute.

    sudo make install

Bro will be installed in the `/usr/local/bro` directory.

Now you need to add the `/usr/local/bro/bin` directory into your `$PATH`. To make sure it’s available globally, the best approach to accomplish that is to specify the path in a file under the `/etc/profile.d` directory. We’ll call that file `3rd-party.sh`.

Create and open `3rd-party.sh` with your favorite text editor.

    sudo nano /etc/profile.d/3rd-party.sh

Copy and paste the following lines into it. The first line is an explanatory comment, and the second line will make sure `/usr/local/bro/bin` is added to the path of any user on the system.

/etc/profile.d/3rd-party.sh

    # Expand PATH to include the path to Bro's binaries
    
    export PATH=$PATH:/usr/local/bro/bin

Save and close the file, then activate the changes with `source`.

    source /etc/profile.d/3rd-party.sh

Artifacts from old settings tend to persist, though, so you can additionally log out and log back in to make sure that your path loads properly.

Now that Bro is installed, we need to make some configuration changes for it to run properly.

## Step 4 — Configuring Bro

In this step, we’ll customize a few files to make sure Bro works properly. All the files are located in the `/usr/local/bro/etc` directory, and they are:

- `node.cfg`, which is used to configure which nodes to monitor.
- `networks.cfg`, which contains a list of networks in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) that are local to the node.
- `broctl.cfg`, which is the global BroControl configuration file for mail, logging, and other settings.

Let’s look at what needs to be modified in each file.

### Configuring Which Nodes to Monitor

To configure the nodes Bro will monitor, we need to modify the `node.cfg` file.

Out of the box, Bro is configured to operate in standalone mode. Because this is a standalone installation, you shouldn’t need to modify this file, but it’s good to check that the values are correct.

Open the file for editing.

    sudo nano /usr/local/bro/etc/node.cfg

Under the `bro` section, look for the `interface` parameter. It’s `etho0` by default, and this should match the public interface of your Ubuntu 16.04 server. If it’s not, make sure to update it.

/usr/local/bro/etc/node.cfg

    [bro]
    type=standalone
    host=localhost
    interface=eth0

Save and close the file when you’re finished. We’ll configure the private network(s) that the node belongs to next.

### Configuring the Node’s Private Networks

The `networks.cfg` file is where you configure which IP networks the node belongs to (i.e. the IP network of any of your server’s interfaces that you wish to monitor).

To start, open the file.

    sudo nano /usr/local/bro/etc/networks.cfg

By default, the file comes with the three private IP blocks already configured as an example of how yours need to be specified.

/usr/local/bro/etc/networks.cfg

    # List of local networks in CIDR notation, optionally followed by a
    # descriptive tag.
    # For example, "10.0.0.0/8" or "fe80::/64" are valid prefixes.
    
    10.0.0.0/8 Private IP space
    172.16.0.0/12 Private IP space
    192.168.0.0/16 Private IP space

Delete the existing three entries, then add your own. You can use `ip addr show` to check the network addresses for your server interfaces. The final version of your `networks.cfg` should look similar to the following, with your network addresses substituted in:

Example /usr/local/bro/etc/networks.cfg

    203.0.113.0/24 Public IP space
    198.51.100.0/24 Private IP space

Save and close the file when you’re finished editing it. We’ll configure mail and logging settings next.

### Configuring Mail and Logging Settings

The `broctl.cfg` file is where you configure how BroControl handles its email and logging responsibilities. Most of the defaults don’t need to be changed. You’ll just need to specify the target email address.

Open the file for editing.

    sudo nano /usr/local/bro/etc/broctl.cfg

Under the **Mail Options** section at the top of the file, look for the **MailTo** parameter and change it to a valid email address that you control. All Bro email alerts will be sent to that address.

/usr/local/bro/etc/broctl.cfg

    . . .
    # Mail Options
    
    # Recipient address for all emails sent out by Bro and BroControl.
    MailTo = sammy@example.com
    . . .

Save and close the file when you’re finished editing it.

This is all the configuration Bro needs, so now you can use BroControl to start and manage Bro.

## Step 5 — Managing Bro with BroControl

BroControl is used for managing Bro installations — starting and stopping the service, deploying Bro, and performing other management tasks. It is both a command line tool and an interactive shell.

If `broctl` is invoked with `sudo /usr/local/bro/bin/broctl`, it will launch the interactive shell:

    OutputWelcome to BroControl 1.5-21
    
    Type "help" for help.
    
    [BroControl] >

You can exit the interactive shell with the `exit` command.

From the shell, you can run any valid Bro command. The same commands can also be run directly from the command line without invoking the shell. Running the commands at the command line is often a more useful approach because it allows you to pipe the output of a `broctl` command into a standard Linux command. For the rest of this step, we’ll be invoking `broctl` commands at the command line.

First, use `broctl deploy` to start Bro and ensure that files needed by BroControl and Bro are brought up-to-date based on the configurations in Step 4.

    sudo /usr/local/bro/bin/broctl deploy

You should also run this command whenever changes are made to the configuration files or scripts.

**Note** : If Bro does not start, the output of the command will hint at the cause. For example, you may see the following error message even though you have an MTA installed:

    Outputbro not running (was crashed)
    Error: error occurred while trying to send mail: send-mail: SENDMAIL-NOTFOUND not found
    starting ...
    starting bro ...

The solution is to edit the BroControl configuration file, `/usr/local/bro/etc/broctl.cfg` and add an entry for Sendmail at end of the **Mail Options** section:

/usr/local/bro/etc/broctl.cfg

    . . .
    # Added for Sendmail
    SendMail = /usr/sbin/sendmail
    
    ###############################################
    # Logging Options
    . . .

Then redeploy Bro with `sudo /usr/local/bro/bin/broctl deploy`.

You can check Bro’s status using the `status` command.

    sudo /usr/local/bro/bin/broctl status

The output will look like the following. Aside from `running`, the status can also be `crashed` or `stopped`.

    OutputName Type Host Status Pid Started
    bro standalone localhost running 6807 12 Apr 05:42:50

If you need to restart Bro, you can use `sudo /usr/local/bro/bin/broctl restart`.

**Note** : `broctl restart` and `broctl deploy` are not the same. Invoke the latter after you change the configuration settings and/or modify a script; invoke the former when you want to stop and restart the entire service.

Next, let’s make the Bro service more robust setting up [a cron job](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps).

## Step 6 — Configuring cron for Bro

Bro does not have a Systemd service descriptor file, but it does come with a cron script that, if enabled, will restart Bro if it crashes and perform other tasks like checking for adequate disk space and removing expired log files.

Bro’s `cron` command is enabled out of the box, but you need to install a cron job that actually triggers the script. You’ll need to first add a cron package file for Bro in `/etc/cron.d`. Following convention, we’ll call that file `bro`, so create and open it.

    sudo nano /etc/cron.d/bro

The entry to copy and paste into the file is shown next. It will run Bro’s `cron` every five minutes. If it detects that Bro has crashed, it will restart it.

/etc/cron.d/bro

    */5 * * * * root /usr/local/bro/bin/broctl cron

You can change the `5` in the command above if you want it to run more often.

Save and close the file when you’re finished with it.

When the cron job is activated, you should get an email stating that a directory for the stats file has been created at `/usr/local/bro/logs/stats`. Be aware that Bro has to actually crash (i.e. be stopped unceremoniously) for this to work. It will not work if you stop Bro yourself gracefully using BroControl’s `stop`.

To test that it works, you’ll either have to reboot the server or kill one of the Bro processes. If you go the reboot route, Bro will be restarted five minutes after the server has completed the reboot process. To use the other approach, first get one of Bro’s process IDs.

    ps aux | grep bro

Then kill one of the processes.

    sudo kill -9 process_id

If you then check the status using:

    sudo /usr/local/bro/bin/broctl status

The output will show that it has crashed.

    OutputName Type Host Status Pid Started
    bro standalone localhost crashed

Invoke that same command a few minutes minutes later, and the output will show that it’s running again.

With Bro working fully, you should be getting summary emails of interresting activities captured on the interface about every hour. And if it ever crashes and restarts, you’ll receive an email stating that it started after a crash. In the next and final step, let’s take a look at a couple of other major Bro utilities.

## Step 7 — Using `bro`, `bro-cut` and Bro Policy Scripts

`bro` and `bro-cut` are the two other main commands that come with Bro. With `bro`, you can capture live traffic and analyze trace files captured using other tools. `bro-cut` is a custom tool for reading and getting data from Bro logs.

The command used to capture live traffic with `bro` are in the format `sudo /usr/local/bro/bin/bro -i eth0 file...`. At a minimum, you have to specify which interface it should capture traffic from.`file...` refers to policy scripts that define what Bro processes. You don’t have to specify a script or scripts, so the command can also look like `sudo /usr/local/bro/bin/bro -i eth0`.

**Note** : The scripts that Bro uses to function are located in the `/usr/local/bro/share/bro` directory. Site-specific scripts are in the `/usr/local/bro/share/bro/site/` directory. Make sure not to customize the files in this directory other than `/usr/local/bro/share/bro/site/local.bro`, as your changes will be overwritten when upgrading or reinstalling Bro.

Because `bro` creates many files from a single capture session to the working directory, it’s best to invoke a `bro` capture command in a directory created just for that capture session. The following, for example, shows a long listing (`ls -l`) of the files created during a live traffic capture session.

    Outputtotal 152
    -rw-r--r-- 1 root root 277 Apr 14 09:20 capture_loss.log
    -rw-r--r-- 1 root root 4711 Apr 14 09:20 conn.log
    -rw-r--r-- 1 root root 2614 Apr 14 04:49 dns.log
    -rw-r--r-- 1 root root 25168 Apr 14 09:20 loaded_scripts.log
    -rw-r--r-- 1 root root 253 Apr 14 09:20 packet_filter.log
    -rw-r--r-- 1 root root 686 Apr 14 09:20 reporter.log
    -rw-r--r-- 1 root root 708 Apr 14 04:49 ssh.log
    -rw-r--r-- 1 root root 793 Apr 14 09:20 stats.log
    -rw-r--r-- 1 root root 373 Apr 14 09:20 weird.log

You can try running one of the capture commands now. After letting it run for a little bit, use `CTRL+C` to terminate the `bro` capture session. You can read each with `bro-cut` using a command like `cat ssh.log | /usr/local/bro/bin/bro-cut -C -d`.

## Conclusion

This article has introduced you to Bro and how to install it in standalone fashion from source. You also learned how to install the IPv4 and IPv6 GeoIP databases from MaxMind that Bro uses for geo-locating IP addresses to city level. For this standalone mode of installation, you also learned how to modify relevant aspects of its configuration files, manage it with `broctrl`, use `bro` to capture live traffic and `bro-cut` to output and read the resulting log files.

You may access more information on how to use Bro from the [project’s documentation site](https://www.bro.org/documentation/index.html).
