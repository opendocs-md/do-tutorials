---
author: Brian Boucheron
date: 2017-04-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-16-04
---

# How To Set Up Time Synchronization on Ubuntu 16.04

## Introduction

Accurate timekeeping has become a critical component of modern software deployments. Whether it’s making sure logs are recorded in the right order or database updates are applied correctly, out-of-sync time can cause errors, data corruption, and other hard to debug issues.

Ubuntu 16.04 has time synchronization built in and activated by default using systemd’s timesyncd service. In this article we will look at some basic time-related commands, verify that timesyncd is active, and learn how to install an alternate network time service.

## Prerequisites

Before starting this tutorial, you will need an Ubuntu 16.04 server with a non-root, sudo-enabled user, as described in [this Ubuntu 16.04 server setup tutorial](initial-server-setup-with-ubuntu-16-04).

## Navigating Basic Time Commands

The most basic command for finding out the time on your server is `date`. Any user can type this command to print out the date and time:

    date

    OutputWed Apr 26 17:44:38 UTC 2017

Most often your server will default to the _UTC_ time zone, as highlighted in the above output. UTC is _Coordinated Universal Time_, the time at zero degrees longitude. Consistently using Universal Time reduces confusion when your infrastructure spans multiple time zones.

If you have different requirements and need to change the time zone, you can use the `timedatectl` command to do so.

First, list the available time zones:

    timedatectl list-timezones

A list of time zones will print to your screen. You can press `SPACE` to page down, and `b` to page up. Once you find the correct time zone, make note of it then type `q` to exit the list.

Now set the time zone with `timedatectl set-timezone`, making sure to replace the highlighted portion below with the time zone you found in the list. You’ll need to use `sudo` with `timedatectl` to make this change:

    sudo timedatectl set-timezone America/New_York

You can verify your changes by running `date` again:

    date

    OutputWed Apr 26 13:55:45 EDT 2017

The time zone abbreviation should reflect the newly chosen value.

Now that we know how to check the clock and set time zones, let’s make sure our time is being synchronized properly.

## Controlling timesyncd with timedatectl

Until recently, most network time synchronization was handled by the _Network Time Protocol daemon_ or ntpd. This server connects to a pool of other NTP servers that provide it with constant and accurate time updates.

Ubuntu’s default install now uses timesyncd instead of ntpd. timesyncd connects to the same time servers and works in roughly the same way, but is more lightweight and more integrated with systemd and the low level workings of Ubuntu.

We can query the status of timesyncd by running `timedatectl` with no arguments. You don’t need to use `sudo` in this case:

    timedatectl

    OutputLocal time: Wed 2017-04-26 17:20:07 UTC
      Universal time: Wed 2017-04-26 17:20:07 UTC
            RTC time: Wed 2017-04-26 17:20:07
           Time zone: Etc/UTC (UTC, +0000)
     Network time on: yes
    NTP synchronized: yes
     RTC in local TZ: no

This prints out the local time, universal time (which may be the same as local time, if you didn’t switch from the UTC time zone), and some network time status information. `Network time on: yes` means that timesyncd is enabled, and `NTP synchronized: yes` indicates that the time has been successfully synced.

If timesyncd isn’t enabled, turn it on with timedatectl:

    sudo timedatectl set-ntp on

Run `timedatectl` again to confirm the network time status. It may take a minute for the actual sync to happen, but eventually both `Network time on:` and `NTP synchronized:` should read `yes`.

## Switching to ntpd

Though timesyncd is fine for most purposes, some applications that are very sensitive to even the slightest perturbations in time may be better served by ntpd, as it uses more sophisticated techniques to constantly and gradually keep the system time on track.

Before installing ntpd, we should turn off timesyncd:

    sudo timedatectl set-ntp no

Verify that timesyncd is off:

    timedatectl

Look for `Network time on: no` in the output. This means `timesyncd` has been stopped. We can now install the `ntp` package with `apt-get`:

    sudo apt-get install ntp

ntpd will be started automatically after install. You can query ntpd for status information to verify that everything is working:

    sudo ntpq -p

    Outputremote refid st t when poll reach delay offset jitter
    ==============================================================================
    0.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    1.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    2.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    3.ubuntu.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    ntp.ubuntu.com .POOL. 16 p - 64 0 0.000 0.000 0.000
    -makaki.miuku.ne 210.23.25.77 2 u 45 64 3 248.007 -0.489 1.137
    -69.10.161.7 144.111.222.81 3 u 43 64 3 90.551 4.316 0.550
    +static-ip-85-25 130.149.17.21 2 u 42 64 3 80.044 -2.829 0.900
    +zepto.mcl.gg 192.53.103.108 2 u 40 64 3 83.331 -0.385 0.391

`ntpq` is a query tool for ntpd. The `-p` flag asks for information about the NTP servers (or **p** eers) ntpd has connected to. Your output will be slightly different, but should list the default Ubuntu pool servers plus a few others. Bear in mind that it can take a few minutes for ntpd to establish connections.

## Conclusion

In this article we’ve shown how to view the system time, change time zones, work with Ubuntu’s default timesyncd, and install ntpd. If you have more sophisticated timekeeping needs than what we’ve covered here, you might reference [the offical NTP documentation](https://www.eecis.udel.edu/%7Emills/ntp/html/index.html), and also take a look at [the NTP Pool Project](http://www.pool.ntp.org/), a global group of volunteers providing much of the world’s NTP infrastructure.
