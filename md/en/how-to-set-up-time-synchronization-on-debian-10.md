---
author: Brian Boucheron, Kathleen Juell
date: 2019-07-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-debian-10
---

# How To Set Up Time Synchronization on Debian 10

## Introduction

Accurate timekeeping has become a critical component of modern software deployments. Whether it’s making sure logs are recorded in the right order or database updates are applied correctly, out-of-sync time can cause errors, data corruption, and other difficult issues to debug.

Debian 10 has time synchronization built in and activated by default using the standard ntpd time server, provided by the `ntp` package. In this article we will look at some basic time-related commands, verify that ntpd is active and connected to peers, and learn how to activate the alternate systemd-timesyncd network time service.

## Prerequisites

Before starting this tutorial, you will need a Debian 10 server with a non-root, `sudo`-enabled user, as described in [this Debian 10 server setup tutorial](initial-server-setup-with-debian-10).

## Step 1 — Navigating Basic Time Commands

The most basic command for finding out the time on your server is `date`. Any user can type this command to print out the date and time:

    date

    OutputWed 31 Jul 2019 06:03:19 PM UTC

Most often your server will default to the _UTC_ time zone, as highlighted in the above output. UTC is _Coordinated Universal Time_, the time at zero degrees longitude. Consistently using Universal Time reduces confusion when your infrastructure spans multiple time zones.

If you have different requirements and need to change the time zone, you can use the `timedatectl` command to do so.

First, list the available time zones:

    timedatectl list-timezones

A list of time zones will print to your screen. You can press `SPACE` to page down, and `b` to page up. Once you find the correct time zone, make note of it then type `q` to exit the list.

Now set the time zone with `timedatectl set-timezone`, making sure to replace the highlighted portion below with the time zone you found in the list. You’ll need to use `sudo` with `timedatectl` to make this change:

    sudo timedatectl set-timezone America/New_York

You can verify your changes by running `date` again:

    date

    OutputWed 31 Jul 2019 02:08:43 PM EDT

The time zone abbreviation should reflect the newly chosen value.

Now that we know how to check the clock and set time zones, let’s make sure our time is being synchronized properly.

## Step 2 — Checking the Status of ntpd

By default, Debian 10 runs the standard ntpd server to keep your system time synchronized with a pool of external time servers. We can check that it’s running with the `systemctl` command:

    sudo systemctl status ntp

    Output● ntp.service - Network Time Service
       Loaded: loaded (/lib/systemd/system/ntp.service; enabled; vendor preset: enabled)
       Active: active (running) since Wed 2019-07-31 13:57:08 EDT; 17min ago
         Docs: man:ntpd(8)
     Main PID: 429 (ntpd)
        Tasks: 2 (limit: 1168)
       Memory: 2.1M
       CGroup: /system.slice/ntp.service
               └─429 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 106:112
    . . .

The `active (running)` status indicates that ntpd started up properly. To get more information about the status of ntpd we can use the `ntpq` command:

    ntpq -p

    Output remote refid st t when poll reach delay offset jitter
    ==============================================================================
     0.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     1.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     2.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     3.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    +208.67.72.50 152.2.133.55 2 u 12 64 377 39.381 1.696 0.674
    +198.46.223.227 204.9.54.119 2 u 6 64 377 22.671 3.536 1.818
    -zinc.frizzen.ne 108.61.56.35 3 u 43 64 377 12.012 1.268 2.553
    -pyramid.latt.ne 204.123.2.72 2 u 11 64 377 69.922 2.858 0.604
    +nu.binary.net 128.252.19.1 2 u 10 64 377 35.362 3.148 0.587
    #107.155.79.108 129.7.1.66 2 u 65 64 377 42.380 1.638 1.014
    +t1.time.bf1.yah 98.139.133.62 2 u 6 64 377 11.233 3.305 1.118
    *sombrero.spider 129.6.15.30 2 u 47 64 377 1.304 2.941 0.889
    +hydrogen.consta 209.51.161.238 2 u 45 64 377 1.830 2.280 1.026
    -4.53.160.75 142.66.101.13 2 u 42 64 377 29.077 2.997 0.789
    #horp-bsd01.horp 146.186.222.14 2 u 39 64 377 16.165 4.189 0.717
    -ntpool1.603.new 204.9.54.119 2 u 46 64 377 27.914 3.717 0.939

`ntpq` is a query tool for ntpd. The `-p` flag asks for information about the NTP servers (or **p** eers) ntpd is connected to. Your output will be slightly different, but should list the default Debian pool servers plus a few others. Bear in mind that it can take a few minutes for ntpd to establish connections.

## Step 3 — Switching to systemd-timesyncd

It is possible to use systemd’s built-in **timesyncd** component to replace ntpd. timesyncd is a lighter-weight alternative to ntpd that is more integrated with systemd. Note, however, that it doesn’t support running as a time server, and it is slightly less sophisticated in the techniques it uses to keep your system time in sync. If you are running complex real-time distributed systems, you may want to stick with ntpd.

To use timesyncd, we must first uninstall ntpd:

    sudo apt purge ntp

Then, start up the timesyncd service:

    sudo systemctl start systemd-timesyncd

Finally, check the status of the service to make sure it’s running:

    sudo systemctl status systemd-timesyncd

    Output● systemd-timesyncd.service - Network Time Synchronization
       Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
      Drop-In: /usr/lib/systemd/system/systemd-timesyncd.service.d
               └─disable-with-time-daemon.conf
       Active: active (running) since Wed 2019-07-31 14:21:37 EDT; 6s ago
         Docs: man:systemd-timesyncd.service(8)
     Main PID: 1681 (systemd-timesyn)
       Status: "Synchronized to time server for the first time 96.245.170.99:123 (0.debian.pool.ntp.org)."
        Tasks: 2 (limit: 1168)
       Memory: 1.3M
       CGroup: /system.slice/systemd-timesyncd.service
               └─1681 /lib/systemd/systemd-timesyncd

We can use `timedatectl` to print out systemd’s current understanding of the time:

    timedatectl

    Output Local time: Wed 2019-07-31 14:22:15 EDT
               Universal time: Wed 2019-07-31 18:22:15 UTC
                     RTC time: n/a
                    Time zone: America/New_York (EDT, -0400)
    System clock synchronized: yes
                  NTP service: active
              RTC in local TZ: no

This prints out the local time, universal time (which may be the same as local time, if you didn’t switch from the UTC time zone), and some network time status information. `System clock synchronized: yes` means that the time has been successfully synced, and `NTP service: active` means that timesyncd is enabled and running.

## Conclusion

In this article we’ve shown how to view the system time, change time zones, work with ntpd, and switch to systemd’s timesyncd service. If you have more sophisticated timekeeping needs than what we’ve covered here, you might refer to [the offical NTP documentation](https://www.eecis.udel.edu/%7Emills/ntp/html/index.html), and also take a look at [the NTP Pool Project](http://www.pool.ntp.org/), a global group of volunteers providing much of the world’s NTP infrastructure.
