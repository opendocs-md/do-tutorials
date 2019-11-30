---
author: Justin Ellingwood, Brian Boucheron
date: 2018-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-18-04
---

# How To Set Up Time Synchronization on Ubuntu 18.04

## Introduction

Accurate timekeeping has become a critical component of modern software deployments. Whether it’s making sure logs are recorded in the right order or database updates are applied correctly, out-of-sync time can cause errors, data corruption, and other hard to debug issues.

Ubuntu 18.04 has time synchronization built in and activated by default using systemd’s timesyncd service. In this article we will look at some basic time-related commands, verify that timesyncd is active, and learn how to install an alternate network time service.

## Prerequisites

Before starting this tutorial, you will need an Ubuntu 18.04 server with a non-root, sudo-enabled user, as described in [this Ubuntu 18.04 server setup tutorial](initial-server-setup-with-ubuntu-18-04).

## Navigating Basic Time Commands

The most basic command for finding out the time on your server is `date`. Any user can type this command to print out the date and time:

    date

    OutputTue Jul 10 14:48:52 UTC 2018

Most often your server will default to the _UTC_ time zone, as highlighted in the above output. UTC is _Coordinated Universal Time_, the time at zero degrees longitude. Consistently using Universal Time reduces confusion when your infrastructure spans multiple time zones.

If you have different requirements and need to change the time zone, you can use the `timedatectl` command to do so.

First, list the available time zones:

    timedatectl list-timezones

A list of time zones will print to your screen. You can press `SPACE` to page down, and `b` to page up. Once you find the correct time zone, make note of it then type `q` to exit the list.

Now set the time zone with `timedatectl set-timezone`, making sure to replace the highlighted portion below with the time zone you found in the list. You’ll need to use `sudo` with `timedatectl` to make this change:

    sudo timedatectl set-timezone America/New_York

You can verify your changes by running `date` again:

    date

    OutputTue Jul 10 10:50:53 EDT 2018

The time zone abbreviation should reflect the newly chosen value.

Now that we know how to check the clock and set time zones, let’s make sure our time is being synchronized properly.

## Controlling timesyncd with timedatectl

Until recently, most network time synchronization was handled by the _Network Time Protocol daemon_ or ntpd. This service connects to a pool of other NTP servers that provide it with constant and accurate time updates.

Ubuntu’s default install now uses timesyncd instead of ntpd. timesyncd connects to the same time servers and works in roughly the same way, but is more lightweight and more integrated with systemd and the low level workings of Ubuntu.

We can query the status of timesyncd by running `timedatectl` with no arguments. You don’t need to use `sudo` in this case:

    timedatectl

    Output Local time: Tue 2018-07-10 10:54:12 EDT
                      Universal time: Tue 2018-07-10 14:54:12 UTC
                            RTC time: Tue 2018-07-10 14:54:12
                           Time zone: America/New_York (EDT, -0400)
           System clock synchronized: yes
    systemd-timesyncd.service active: yes
                     RTC in local TZ: no

This prints out the local time, universal time (which may be the same as local time, if you didn’t switch from the UTC time zone), and some network time status information. `System clock synchronized: yes` indicates that the time has been successfully synced, and `systemd-timesyncd.service active: yes` means that timesyncd is enabled and running.

If timesyncd isn’t active, turn it on with timedatectl:

    sudo timedatectl set-ntp on

Run `timedatectl` again to confirm the network time status. It may take a minute for the actual sync to happen, but eventually both `Network time on:` and `NTP synchronized:` should read `yes`.

## Switching to ntpd

Though timesyncd is fine for most purposes, some applications that are very sensitive to even the slightest perturbations in time may be better served by ntpd, as it uses more sophisticated techniques to constantly and gradually keep the system time on track.

Before installing ntpd, we should turn off timesyncd:

    sudo timedatectl set-ntp no

Verify that timesyncd is off:

    timedatectl

Look for `systemd-timesyncd.service active: no` in the output. This means `timesyncd` has been stopped. We can now install the `ntp` package with `apt`:

    sudo apt update
    sudo apt install ntp

ntpd will be started automatically after install. You can query ntpd for status information to verify that everything is working:

    ntpq -p

    Output remote refid st t when poll reach delay offset jitter
    ==============================================================================
     0.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     1.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     2.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     3.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     ntp.ubuntu.com .POOL. 16 p - 64 0 0.000 0.000 0.000
    +ec2-52-0-56-137 216.239.35.0 2 u 16 64 1 7.872 -2.137 1.485
    +66.220.10.2 129.6.15.30 2 u 12 64 1 65.204 3.740 2.686
    +block.steinhoff 209.51.161.238 2 u 11 64 1 33.364 1.710 3.586
    +eterna.binary.n 216.229.0.50 3 u 11 64 1 35.330 2.821 2.839
    +2604:a880:800:1 209.51.161.238 2 u 14 64 1 0.394 0.386 2.462
    +ec2-52-6-160-3. 130.207.244.240 2 u 11 64 1 8.150 2.050 3.053
    +mx.danb.email 127.67.113.92 2 u 13 64 1 63.868 1.539 2.240
    *hydrogen.consta 129.6.15.28 2 u 12 64 1 2.989 1.755 2.563
    +ntp-3.jonlight. 127.67.113.92 2 u 10 64 1 64.561 2.122 3.593
    +undef.us 45.33.84.208 3 u 12 64 1 33.508 1.631 3.647
    +ntp-3.jonlight. 127.67.113.92 2 u 8 64 1 64.253 2.645 3.174
     2001:67c:1560:8 145.238.203.14 2 u 22 64 1 71.155 -1.059 0.000
    +test.diarizer.c 216.239.35.4 2 u 11 64 1 64.378 4.648 3.244
     2001:67c:1560:8 145.238.203.14 2 u 18 64 1 70.744 -0.964 0.000
     alphyn.canonica 132.246.11.231 2 u 17 64 1 7.973 -0.170 0.000
    +vps5.ctyme.com 216.218.254.202 2 u 10 64 1 65.874 1.902 2.608

`ntpq` is a query tool for ntpd. The `-p` flag asks for information about the NTP servers (or **p** eers) ntpd has connected to. Your output will be slightly different, but should list the default Ubuntu pool servers plus a few others. Bear in mind that it can take a few minutes for ntpd to establish connections.

## Conclusion

In this article we’ve shown how to view the system time, change time zones, work with Ubuntu’s default timesyncd, and install ntpd. If you have more sophisticated timekeeping needs than what we’ve covered here, you might reference [the offical NTP documentation](https://www.eecis.udel.edu/%7Emills/ntp/html/index.html), and also take a look at [the NTP Pool Project](http://www.pool.ntp.org/), a global group of volunteers providing much of the world’s NTP infrastructure.
