---
author: O.S Tezer
date: 2013-11-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-logwatch-log-analyzer-and-reporter-on-a-vps
---

# How To Install and Use Logwatch Log Analyzer and Reporter on a VPS

## Introduction

* * *

Applications create what are called “log files” to keep track of activities taking place at any given time. These files, which are far from being simple text outputs, can be very complex to go through, especially if the server being managed is a busy one.

When the time comes to refer to log files (e.g. in case of failure, loss of data etc.), making use of all the available help becomes vital. Being able to quickly understand (parse) what they can tell regarding the past events and _analyzing_ what exactly has happened then becomes exceptionally important for coming up with a solution.

Following in the footsteps of our previous articles on Linux system hardening, security monitoring and emailing alerts, in this DigitalOcean article we will talk about **Logwatch** : a very powerful log parser and analyzer which can make any dedicated system administrator’s life a little bit easier when tackling application related tasks and issues.

## Log Files

* * *

Much like the black boxes of starships from Startrek, to keep the systems (i.e. servers) running, administrators even today rely on logs. Jokes aside, these application-generated files play a decisive role in tracking back and understanding what has happened in the past [at a given time] for the purposes of full / partial data recovery (i.e. from [transaction logs](http://en.wikipedia.org/wiki/Transaction_log)), performance or strategy related analyses (e.g. from [server logs](http://en.wikipedia.org/wiki/Server_log)) or amendments for the future (e.g. from access logs).

Simply put, log files will consist of actions and events taking place within a given time range.

A good log file should be as detailed as possible in order to help the administrator, who have the responsibility of maintaining the system, find the exact information needed for a certain purpose. Because of this very reason, log files are usually NOT concise and they contain loads of repetitions and loads of (mostly) redundant entries which need thorough analyses and filtering to make sense to a human.

This is where Logwatch, a computer application designed for this job, comes into play.

## Enter Logwatch

* * *

Log management is an area consisting mostly of search, log rotation / retention and reporting. Logwatch is an application that helps with simple log management by daily analyzing and reporting a short digest from activities taking place on your machine.

Reports created by Logwatch are categorised by _services_ (i.e. applications) running on your system, which can be configured to consist of the ones you like or all of them together by modifying its relatively simple configuration file. Furthermore, Logwatch allows the creation of custom analysis scripts for specific needs.

## Installing Logwatch

* * *

**Please note:** Logwatch is a harmless application which should not interfere with your current services or workload. However, as always, it is recommended that you first try it on a new system and make sure to take backups.

### On CentOS / RHEL

* * *

It is very simple to have Logwatch installed on a RHEL based system (e.g. CentOS). As it is an application consisting of various Perl scripts, certain related dependencies are required. Since we are going to be using **yum** package manager, this will be automatically taken care of. Unless you have mailx installed already, Logwatch will download it for you during the process as well.

**To install Logwatch on CentOS / RHEL, run the following:**

    $ yum install -y logwatch

### On Ubuntu / Debian

* * *

Getting Logwatch for Debian based systems (e.g. Ubuntu) is very similar to the process explained above, apart from the differences in package managers (aptitude v. yum).

**To install Logwatch on Ubuntu / Debian, run the following:**

    $ aptitude install -y logwatch

## Configuring Logwatch

* * *

Although its settings can be overridden during each run manually, in general, you will want to have Logwatch running daily, using common configuration.

### Setting The Common Configurations of Logwatch

* * *

The default configuration file for Logwatch is located at:

    /usr/share/logwatch/default.conf/logwatch.conf

**Let’s open up this file using the nano text editor in order to modify its contents:**

    $ nano /usr/share/logwatch/default.conf/logwatch.conf

Upon running the command above, you will be met with a long list of variables the application uses each time it runs, whether automatically or manually.

In order to begin using it, we will need to make a few changes to these defaults.

> Please remember in the future, you might want to come back to modify certain settings defined here. All **services** (applications) that are analyzed by Logwatch are listed on this file, as explained above (Configuration #5). As you install or remove applications from your virtual server, you can continue to receive reports on **_all_** of them or **_some_** of them by changing the settings here (see below\*).

The important options which we need to set:

**Please note:** You will need to use your arrow keys to go up or down the lines when you will be making the following changes on the document. Once you are done going through the changes (items 1 - 6), you will need to press **CTRL+X** and then confirm with **Y** to save and close. Changes will come into effect automatically the next time `logwatch` runs.

**1. The e-mail address to which daily digest (reports) are sent:**

    MailTo = root

Replace `root` with your email address.

**Example:** `MailTo = sysadmin@mydomain.com`

**2. The e-mail address _from_ which these reports originate:**

    MailFrom = Logwatch

You might wish to replace `Logwatch` with your own again.

**Example:** `MailFrom = sysadmin@mydomain.com`

**3. Setting the _range_ for the reports:**

    Range = yesterday

You have options of receiving reports for **_All_** (all available since the beginning), **_Today_** (just today) or **_Yesterday_** (just yesterday).

**Example:** `Range = Today`

**4. Setting the reports’ detail:**

    Detail = Low

You can modify the reports’ detail here. Options are: **_Low_** , **_Medium_** and **_High_**.

**Example:** `Detail = Medium`

**5. Setting services (applications) to be analysed:**

> By default, Logwatch covers a really wide range of services. If you would like to see a full list, you can query the contents of the file `scripts/services` located at `/usr/share/logwatch/`.
> 
> **Example:** `ls -l /usr/share/logwatch/scripts/services`

    Service = All

You can choose to receive reports for all services or some specific ones.

**For all services, keep the line as:** `Service = All`

If you wish to receive reports for specific ones, modify it similar to the following example, listing each service on a new line (e.g. `Service = [name]`).

**Example:**

    Service = sendmail
    Service = http
    Service = identd
    Service = sshd2
    Service = sudo
    ..

**6. Disabling daily reports:**

    # DailyReport = No

If you do **not** wish to have daily repots generated, you should uncomment this line.

**Example:** `DailyReport = No` instead of `# DailyReport = No`

And that’s it! After making these changes, you will receive daily reports based on log files from your server **automatically**.

> To learn more about Logwatch, and creating custom services to receive reports on, you can visit its full documentation by clicking [here](http://www.stellarcore.net/logwatch/tabs/docs/HOWTO-Customize-LogWatch.html).

## Running Logwatch Manually

* * *

It should be mentioned that you have the option to run Logwatch manually whenever you need through the command line.

Here are the available options [from the documentation]:

    logwatch [--detail level] [--logfile log-file-group] [--service service-name] [--print]
       [--mailto address] [--archives] [--range range] [--debug level] [--save file-name]
       [--logdir directory] [--hostname hostname] [--splithosts] [--multiemail] [--output output-
       type ] [--numeric] [--no-oldfiles-log] [--version] [--help|--usage]

Unless you specify an option, it will be read from the configuration file.

**Example:**

    $ logwatch --detail Low --mailto email@address --service http --range today

**And here is what a Logwatch report can look like:**

    ################### Logwatch 7.3.6 (05/19/07) ####################
            Processing Initiated: Wed Nov 15 15:07:00 2013
            Date Range Processed: today
                                  ( 2013-Nov-15 )
                                  Period is day.
          Detail Level of Output: 0
                  Type of Output: unformatted
               Logfiles for Host: host_name
                     ##################################################################
    
     --------------------- Postfix Begin ------------------------
    
        3.453K Bytes accepted 3,536
        3.453K Bytes delivered 3,536
     ======== ================================================
    
            3 Accepted 100.00%
     -------- ------------------------------------------------
            3 Total 100.00%
     ======== ================================================
    
            3 Removed from queue
            2 Delivered
            1 Sent via SMTP
    
            1 Connection failure (outbound)
    
            1 Postfix start
    
    
     ---------------------- Postfix End -------------------------
    
    
     --------------------- Connections (secure-log) Begin ------------------------
    
     New Users:
        apache (48)
    
     New Groups:
        apache (48)
    
    
     **Unmatched Entries**
        groupadd: group added to /etc/group: name=apache, GID=48: 1 Time(s)
        groupadd: group added to /etc/gshadow: name=apache: 1 Time(s)
    
     ---------------------- Connections (secure-log) End -------------------------
    
     --------------------- SSHD Begin ------------------------
    
    
     SSHD Started: 2 Time(s)
    
     Users logging in through sshd:
        root:
           ip_addr (ip_addr): 1 time
    
     ---------------------- SSHD End -------------------------
    
     --------------------- yum Begin ------------------------
    
    
     Packages Installed:
        apr-1.3.9-5.el6_2.x86_64
        apr-util-1.3.9-3.el6_0.1.x86_64
        perl-YAML-Syck-1.07-4.el6.x86_64
        4:perl-5.10.1-131.el6_4.x86_64
        mailx-12.4-6.el6.x86_64
        1:perl-Pod-Simple-3.13-131.el6_4.x86_64
        1:perl-Pod-Escapes-1.04-131.el6_4.x86_64
        3:perl-version-0.77-131.el6_4.x86_64
        httpd-2.2.15-29.el6.centos.x86_64
        4:perl-libs-5.10.1-131.el6_4.x86_64
        mailcap-2.1.31-2.el6.noarch
        perl-Date-Manip-6.24-1.el6.noarch
        1:perl-Module-Pluggable-3.90-131.el6_4.x86_64
        httpd-tools-2.2.15-29.el6.centos.x86_64
        apr-util-ldap-1.3.9-3.el6_0.1.x86_64
        logwatch-7.3.6-49.el6.noarch
    
     ---------------------- yum End -------------------------

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
