---
author: Veena K John
date: 2015-07-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-protect-against-dos-and-ddos-with-mod_evasive-for-apache-on-centos-7
---

# How To Protect Against DoS and DDoS with mod_evasive for Apache on CentOS 7

## Introduction

The mod\_evasive Apache module, formerly known as mod\_dosevasive, helps protect against DoS, DDoS (Distributed Denial of Service), and brute force attacks on the Apache web server. It can provide evasive action during attacks and report abuses via email and syslog facilities. The module works by creating an internal dynamic table of IP addresses and URIs as well as denying any single IP address from any of the following:

- Requesting the same page more than a few times per second
- Making more than 50 concurrent requests on the same child per second
- Making any requests while temporarily blacklisted

If any of the above conditions are met, a 403 response is sent and the IP address is logged. Optionally, an email notification can be sent to the server owner or a system command can be run to block the IP address.

In this tutorial, we will discuss how to install, configure, and use mod\_evasive on your server.

## Prerequisites

Before you get started with this tutorial, you should have the following:

- CentOS 7 64-bit Droplet (works with CentOS 6 as well)
- Non-root user with sudo privileges. To setup a user of this type, follow the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) tutorial. All commands will be run as this user.
- Apache web server running on the Droplet. To install Apache please follow Step #1 of the [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on CentOS](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7) article.

## Step 1 — Installing mod\_evasive

In this section, we will be installing the packages required for mod\_evasive to function and finally install mod\_evasive.

First, we need to install the EPEL (Extra Packages for Enterprise Linux) yum repository on the server. EPEL is a Fedora Special Interest Group that creates, maintains, and manages a high quality set of open source add-on software packages for Enterprise Linux. Run the following command to install and enable the EPEL repository on your server:

On CentOS 7:

    sudo rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

On CentOS 6:

    sudo rpm -ivh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

Let us verify that the EPEL repo is enabled using:

    sudo yum repolist

If enabled, you will see the following repo listed in the output:

    epel/x86_64 Extra Packages for Enterprise Linux 7 - x86_64

Now, let us protect the base packages from EPEL using the yum plugin **protectbase**.

    sudo yum install yum-plugin-protectbase.noarch -y

The purpose of the **protectbase** plugin is to protect certain yum repositories from updates from other repositories. Packages in the protected repositories will not be updated or overridden by packages in non-protected repositories even if the non-protected repo has a later version.

Now we are ready to install mod\_evasive module. Run the following command to install it:

    sudo yum install mod_evasive -y

## Step 2 — Verifying the Installation

Now that mod\_evasive is installed, let’s verify that configuration file has been installed and that the module is being loaded.

During installation, the mod\_evasive configuration file `/etc/httpd/conf.d/mod_evasive.conf` was added. To verify this run:

    sudo ls -al /etc/httpd/conf.d/mod_evasive.conf

Output should look similar to:

    -rw-r--r-- 1 root root 3473 Jul 21 01:41 /etc/httpd/conf.d/mod_evasive.conf

By default, the following `LoadModule` line will be added to the top of configuration file `mod_evasive.conf`. Open the file and add the line if it is not already present. This line tells the Apache web server to load and use the mod\_evasive module.

On CentOS 7, the line should read as follows:

/etc/httpd/conf.d/mod\_evasive.conf

    LoadModule evasive20_module modules/mod_evasive24.so

On CentOS 6, the line should be as follows:

/etc/httpd/conf.d/mod\_evasive.conf

    LoadModule evasive20_module modules/mod_evasive20.so

Let us list the modules loaded for the Apache web server and look for mod\_evasive:

    sudo httpd -M | grep evasive

The output should show:

     evasive20_module (shared)

## Step 3 — Configuring mod\_evasive

Now that the installation is complete and verified, let us look into the configuration of the module. mod\_evasive can be easily customized through the `mod_evasive.conf` configuration file. We will discuss some of the configuration parameters in this tutorial. Please refer to the configuration file for information on all the parameters — it contains a description of each parameter.

One of the configuration options you need to change is `DOSEmailNotify`. This is a very useful directive. If this value is set, an email will be sent to the email address specified whenever an IP address is blacklisted. The email body will show `mod_evasive HTTP Blacklisted 111.111.111.111`

For example, if you want to send mod\_evasive alerts to say, [sammy@example.com](mailto:sammy@example.com), edit the file:

    sudo nano /etc/httpd/conf.d/mod_evasive.conf

Uncomment the `DOSEmailNotify` line by removing the `#` in front of the line, and change the email address to yours:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSEmailNotify sammy@example.com

**Note:** mod\_evasive uses `/bin/mail` for sending email alerts. You need to have a mail server installed and working, please refer to [this tutorial](how-to-send-e-mail-alerts-on-a-centos-vps-for-system-monitoring) for information on how to set up a simple mail server so that email notifications work.

Another parameter you might want to set is `DOSWhitelist`. Using this option, IP addresses of trusted clients can be added to the whitelist to ensure they are never denied. The purpose of whitelisting is to protect software, scripts, local search bots, or other automated tools from being denied for requesting large amounts of data from the server.

To whitelist an IP address, for example 111.111.111.111, add an entry to the configuration file like this:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSWhitelist 111.111.111.111

Wildcards can be used on up to the last 3 octets of the IP address if necessary.

To whitelist multiple IP addresses from different IP ranges, you can add separate DOSWhitelist lines in the configuration file like this:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSWhitelist 111.111.111.111
    DOSWhitelist 222.222.222.222

`DOSPageCount` and `DOSSiteCount` are two other parameters recommended to be changed to less aggressive values to avoid clients getting blocked unnecessarily.

`DOSPageCount` is the limit for the number of requests for the same page per page interval (usually set to one second) by an IP address. Once the threshold for that interval has been exceeded, the IP address of the client will be added to the blocked list. The default value is set quite low at 2. You can change it to a higher value, say 20, by editing the following in `/etc/httpd/conf.d/mod_evasive.conf`:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSPageCount 20

`DOSSiteCount` is the limit for the total number of requests for the same website by an IP address per site interval (defaults to 1 second). To change it to a larger value such as 100 seconds:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSSiteCount 100

There are a few other parameters you can change to achieve better performance.

One is `DOSBlockingPeriod`, which is the amount of time (in seconds) that a client (IP address) will be blocked for if they are added to the blocked list. During this time, all subsequent requests from the client will result in a 403 (Forbidden) error and the timer being reset (defaults to 10 seconds).

For example, if you want to increase the blocking period to 300 seconds:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSBlockingPeriod 300

Another is `DOSLogDir` which refers to the temporary directory used by mod\_evasive. By default `/tmp` will be used for a locking mechanism, which opens some security issues if your system is open to shell users. In the event you have non-privileged shell users, you will want to create a directory writeable only to the user Apache is running as (usually **apache** ) then set this parameter in your mod\_evasive.conf file.

For example, to set the directory used by mod\_evasive to `/var/log/mod_evasive`, create the directory using:

    sudo mkdir /var/log/mod_evasive

Then set the ownership to `apache` user:

    sudo chown -R apache:apache /var/log/mod_evasive

Now edit the mod\_evasive configuration and change the directory as follows:

/etc/httpd/conf.d/mod\_evasive.conf

    DOSLogDir "/var/log/mod_evasive"

Another parameter is `DOSSystemCommand`. If a value is set, the command specified will be executed whenever an IP address is blacklisted. Using this parameter, you can integrate mod\_evasive with the firewall installed on your server or a shell script and block the IP addresses blacklisted by mod\_evasive in the firewall.

## Step 4 — Loading the mod\_evasive Module

Once we have made the changes in the configuration file, we need to restart the Apache web server for them to take effect. Run the following command to restart Apache.

On CentOS 7:

    sudo systemctl restart httpd.service

On CentOS6:

    sudo service httpd restart

**Note:** Please note that mod\_evasive appears to conflict with the FrontPage Server Extensions. You might also want to check your Apache web server settings to make sure mod\_evasive is able to function well. Suggested Apache tweaks are to have a very high value for `MaxRequestsPerChild` but not unlimited (A value of zero implies unlimited) and to have `KeepAlive` enabled with `KeepAliveTimeout` set reasonably long.

## Step 5 — Testing mod\_evasive

Let us do a short test to see if the module is working correctly. We will be using a perl script **test.pl** written by mod\_evasive developers. To execute the script, we need to first install `perl` package on the server using:

    sudo yum install -y perl

The test script is installed with mod\_evasive at the following location:

    /usr/share/doc/mod_evasive-1.10.1/test.pl

By default, the test script requests the same page from your Apache web server 100 times in a row to trigger mod\_evasive. In the last section, we modified mod\_evasive to be more tolerant of requests per second to the same page. We need to change the script to 200 requests in a row instead of 100 to make sure we trigger all of mod\_evasive’s notification methods.

Edit `/usr/share/doc/mod_evasive-1.10.1/test.pl`:

    sudo nano /usr/share/doc/mod_evasive-1.10.1/test.pl

Find the following line:

/usr/share/doc/mod\_evasive-1.10.1/test.pl

    for(0..100) {

Replace 100 with 200:

/usr/share/doc/mod\_evasive-1.10.1/test.pl

    for(0..200) {

Save and exit.

To execute the script, run:

    sudo perl /usr/share/doc/mod_evasive-1.10.1/test.pl

You should see output similar to:

    HTTP/1.1 403 Forbidden
    HTTP/1.1 403 Forbidden
    HTTP/1.1 403 Forbidden
    HTTP/1.1 403 Forbidden
    HTTP/1.1 403 Forbidden
    ...

The script makes 100 requests to your web server. the 403 response code indicates access is denied by the web server. mod\_evasive also logs to syslog when the IP address is blocked. Check the log file using:

    sudo tailf /var/log/messages

It should show a line similar to:

    Jul 29 00:11:18 servername mod_evasive[18290]: Blacklisting address 127.0.0.1: possible DoS attack.

indicating the IP address is blocked by mod\_evasive.

If you have configured mod\_evasive to send email alerts when an IP is blocked, you will have an email in your inbox with the following content:

    mod_evasive HTTP Blacklisted 127.0.0.1

## Conclusion

mod\_evasive is great at fending off single server, scripted attacks as well as distributed attacks. However, it is only useful to the point of your server’s total bandwidth and processor capacity for processing and responding to invalid requests. For this reason, it is a good idea to integrate this module with your server firewall for maximum protection. Without a really good infrastructure and a firewall in place, a heavy DDoS might still take you offline. If an attack is very heavy and persistent, you might need to move to a hardware-based DDoS mitigation solution.
