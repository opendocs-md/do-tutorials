---
author: Bob Aiello
date: 2013-12-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-aide-on-a-digitalocean-vps
---

# How To Install Aide on a DigitalOcean VPS

## Introduction

* * *

SysAdmins are responsible for installing and configuring software to support websites including those that run on DigitalOcean VPS. Unfortunately, as soon as your website is available on the internet, one or more malicious hackers will likely spend a great deal of time and effort trying to find some vulnerability in your system in order to gain unauthorized access and make changes that may take your system down completely. In extreme cases, these individuals could actually try to use your website to attack other systems, leaving you in a position where you have to explain how your IP was traced back as the source of an attack on another, likely more secure, system.

The good news is that you can secure your VPS using industry best practices, including establishing software configuration baselines that ensure that you can detect and track all changes to your droplet. One of the most popular tools for monitoring changes to a Unix or Linux system is known as Advanced Intrusion Detection Environment (AIDE) originally written by Rami Lehti and Pablo Virolainen in 1999. This article will help you get started by describing how to install, configure, and use Aide in an effective way.

### Creating a secure trusted base

* * *

Unix and Linux servers, including a DigitalOcean VPS, provide a robust platform for installing, configuring, and running software powering websites available on the internet. Industry standards such as the IEEE 828 Configuration Management Standard and the itSMF ITIL v3 framework provide well respected industry guidelines on how to record and maintain a stable operating system and application baselines which are essential for ensuring that these systems are secure and reliable.

Financial services firms including large banks, trading firms, and the exchanges themselves are required by Federal Regulatory authorities including Financial Industry Regulatory Authority (Finra), Office of the Comptroller of the Currency (OCC), and the Federal Reserve System (Fed) to implement these best practices. As a SysAdmin, you can use these same procedures to secure your DigitalOcean VPS and create a secure trusted application base using DevOps best practices. When I create a new Linux or Unix VPS, I always start by installing a tool such as Aide or Tripwire.

## Step 1 - Use yum to install Aide

* * *

The first step is to run the command `yum install aide` as shown in figure 1.0 to check for dependencies and verify that aide can be installed.

    [root@myserver ~]# yum install aide

You will need to enter to proceed with the installation.

    Is this ok [y/N]: y

## Step 2 - Run aide help and verify aide version

* * *

After the installation is complete you should run the aide –help screen and verify the version of aide as shown below

[root@myserver ~]# aide –help

Next you should verify the version of aide that you are running. Make note of the location of the /etc/aide.conf that we will discuss at the end of this technote.  
[root@myserver ~]# aide -v

    Aide 0.13.1
    Compiled with the following options:
    WITH_MMAP
    WITH_POSIX_ACL
    WITH_SELINUX
    WITH_XATTR
    WITH_LSTAT64
    WITH_READDIR64
    WITH_GCRYPT
    WITH_AUDIT
    CONFIG_FILE "/etc/aide.conf"

Now that we have verified that Aide is installed we will create our first aide database.

## Step 3 - Initialize first aide database

* * *

Initialize the first aide database by issuing the command “aide init” as shown.

    [root@myserver ~]# aide --init

Verify that the new aide database has been created

    [root@myserver ~]# cd /var/lib/aide
    [root@myserver aide]# ls -lt
    total 1488
    -rw------- 1 root root 1520639 Dec 8 16:57 aide.db.new.gz

The initial aide database (aide.db.new.gz) must be renamed (aide.db.gz) in order for aide to work successfully.

## Step 4 - Rename aide database using the unix mv command so that it can be used

* * *

    [root@myserver aide]# mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
    [root@myserver aide]# ls -lt
    total 1488
    -rw------- 1 root root 1520639 Dec 8 16:57 aide.db.gz

Next we will run the aide check just to demonstrate that no changes have occurred.

## Step 5 - Run the first aide –check without making any changes

* * *

    [root@myserver aide]# aide --check

Next we will create a file in the /usr/sbin directory to test that aide can detect and report the change.

## Step 6 - Create a new file as a test

* * *

Next we use the unix touch command to create a new file that we can then use to test aide and verify that the newly created file is detected by the aide check.

    [root@myserver aide]# touch /usr/sbin/mytestfile.txt

## Step 7 - Run aide check to detect new file

* * *

[root@myserver aide]# aide –check

Once we have reviewed the changes detected by aide check, we likely do not want aide to report them again because these reports can get very long. The practical approach is to review the changes and then update the aide database so that they are not reported again on the next run of aide check.

## Step 8 - Create updated aide database to ignore previous changes

* * *

Next you will create an updated aide database that ignores all previously made (and reviewed) changes.

    [root@myserver aide]# aide --update

The new aide database is called aide.db.new.gz as shown below in figure 11.

    [root@myserver aide]# ls -lt
    total 2976
    -rw------- 1 root root 1520708 Dec 8 17:13 aide.db.new.gz
    -rw------- 1 root root 1520639 Dec 8 16:57 aide.db.gz

The next step is to rename the aide database again so that we are using the new version of the aide database to report only changes that occur from this point forward.

## Step 9 - Use updated aide database

* * *

It is usually a good idea to save the old aide database by renaming it with a date as shown in figure 12 so that you can trace back any changes (if necessary). Eventually, the old versions of the aide databases can be archived and deleted. You also need to use the unix mv command to rename the newly create created aide database so that it can be used going forward.

    `[root@myserver aide]# mv aide.db.gz aide.db.gz-Dec082013`
    `[root@myserver aide]# mv aide.db.new.gz aide.db.gz`

While these procedures are straightforward, they can become both tedious and time consuming. It is essential to write scripts to update the database and also run the aide check report to automatically report changes.

## Step 10. Automate using cron and sendmail

* * *

I usually create a crontab entry to run an `aide --check` report on a daily basis that conveniently shows up on my handheld device. This makes using aide to monitor your filesystem much easier and more practical.

    `06 01 * * 0-6 /var/log/aide/chkaide.sh`

Here is a simple example of a script that can be run from crontab to automate the `aide check` and email the last 20 lines of the report, which is usually enough information for a daily summary.

    [root@myserver ~]# cat /var/log/aide/chaide.sh
    #! /bin/sh
    #chkaide.sh - Bob Aiello
    MYDATE`date +%Y-%m-%d`
    MYFILENAME"Aide-"$MYDATE.txt
    /bin/echo "Aide check !! `date`" > /tmp/$MYFILENAME
    /usr/sbin/aide --check > /tmp/myAide.txt
    /bin/cat /tmp/myAide.txt|/bin/grep -v failed >> /tmp/$MYFILENAME
    /bin/echo " **************************************" >> /tmp/$MYFILENAME
    /usr/bin/tail -20 /tmp/myAide.txt >> /tmp/$MYFILENAME
    /bin/echo " ****************DONE******************" >> /tmp/$MYFILENAME
    /bin/mail -s"$MYFILENAME `date`" bob.aiello@ieee.org < /tmp/$MYFILENAME

## Final Steps

* * *

You can also modify the /etc/aide.conf to configure advanced settings such as including or excluding specific directories. Since the version of the /etc/aide.conf that gets installed automatically has the most common settings, it is relatively unusual for SysAdmins to modify this file.

### Summary

* * *

Creating secure and robust websites using DigitalOcean VPS require a comprehensive approach to information security including tracking changes to system and application baselines. Using Aide is a great first step and will help you understand changes that are made to your system, as well as identify unauthorized changes which occur through malicious intent or human error. In future articles, we’ll describe additional steps that you can take to create a secure trusted base. Installing aide and using it daily will help you get started with managing your DigitalOcean VPS!

### Additional Resources

* * *

[Aide](http://aide.sourceforge.net/)

[By Bob Aiello](http://cmbestpractices.com)
