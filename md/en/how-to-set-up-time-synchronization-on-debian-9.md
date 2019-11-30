---
author: Brian Boucheron
date: 2018-09-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-debian-9
---

# How To Set Up Time Synchronization on Debian 9

## Introduction

Accurate timekeeping has become a critical component of modern software deployments. Whether it’s making sure logs are recorded in the right order or database updates are applied correctly, out-of-sync time can cause errors, data corruption, and other hard to debug issues.

Debian 9 has time synchronization built in and activated by default using the standard ntpd time server, provided by the `ntp` package. In this article we will look at some basic time-related commands, verify that ntpd is active and connected to peers, and learn how to activate the alternate systemd-timesyncd network time service.

## Prerequisites

Before starting this tutorial, you will need a Debian 9 server with a non-root, sudo-enabled user, as described in [this Debian 9 server setup tutorial](initial-server-setup-with-debian-9).

## Navigating Basic Time Commands

The most basic command for finding out the time on your server is `date`. Any user can type this command to print out the date and time:

    date

    OutputTue Sep 4 17:51:49 UTC 2018

Most often your server will default to the _UTC_ time zone, as highlighted in the above output. UTC is _Coordinated Universal Time_, the time at zero degrees longitude. Consistently using Universal Time reduces confusion when your infrastructure spans multiple time zones.

If you have different requirements and need to change the time zone, you can use the `timedatectl` command to do so.

First, list the available time zones:

    timedatectl list-timezones

A list of time zones will print to your screen. You can press `SPACE` to page down, and `b` to page up. Once you find the correct time zone, make note of it then type `q` to exit the list.

Now set the time zone with `timedatectl set-timezone`, making sure to replace the highlighted portion below with the time zone you found in the list. You’ll need to use `sudo` with `timedatectl` to make this change:

    sudo timedatectl set-timezone America/New_York

You can verify your changes by running `date` again:

    date

    OutputTue Sep 4 13:52:57 EDT 2018

The time zone abbreviation should reflect the newly chosen value.

Now that we know how to check the clock and set time zones, let’s make sure our time is being synchronized properly.

## Checking the Status of ntpd

By default, Debian 9 runs the standard ntpd server to keep your system time synchronized with a pool of external time servers. We can check that it’s running with the `systemctl` command:

    sudo systemctl status ntp

    Output● ntp.service - LSB: Start NTP daemon
       Loaded: loaded (/etc/init.d/ntp; generated; vendor preset: enabled)
       Active: active (running) since Tue 2018-09-04 15:07:03 EDT; 30min ago
         Docs: man:systemd-sysv-generator(8)
      Process: 876 ExecStart=/etc/init.d/ntp start (code=exited, status=0/SUCCESS)
        Tasks: 2 (limit: 4915)
       CGroup: /system.slice/ntp.service
               └─904 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 105:109
    . . .

The `active (running)` status indicates that ntpd started up properly. To get more information about the status of ntpd we can use the `ntpq` command:

    ntpq -p

    Output remote refid st t when poll reach delay offset jitter
    ==============================================================================
     0.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     1.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     2.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
     3.debian.pool.n .POOL. 16 p - 64 0 0.000 0.000 0.000
    -eterna.binary.n 204.9.54.119 2 u 240 256 377 35.392 0.142 0.211
    -static-96-244-9 192.168.10.254 2 u 60 256 377 10.242 1.297 2.412
    +minime.fdf.net 83.157.230.212 3 u 99 256 377 24.042 0.128 0.250
    *t1.time.bf1.yah 98.139.133.62 2 u 31 256 377 11.112 0.621 0.186
    +x.ns.gin.ntt.ne 249.224.99.213 2 u 108 256 377 1.290 -0.073 0.132
    -ord1.m-d.net 142.66.101.13 2 u 473 512 377 19.930 -1.764 0.293

`ntpq` is a query tool for ntpd. The `-p` flag asks for information about the NTP servers (or **p** eers) ntpd is connected to. Your output will be slightly different, but should list the default Debian pool servers plus a few others. Bear in mind that it can take a few minutes for ntpd to establish connections.

## Switching to systemd-timesyncd

It is possible to use systemd’s built-in **timesyncd** component to replace ntpd. timesyncd is a lighter-weight alternative to ntpd that is more integrated with systemd. Note however that it doesn’t support running as a time server, and it is slightly less sophisticated in the techniques it uses to keep your system time in sync. If you are running complex real-time distributed systems, you may want to stick with ntpd.

To use timesyncd, we must first uninstall ntpd:

    sudo apt purge ntp

Then, start up the timesyncd service:

    sudo systemctl start systemd-timesyncd

Finally, check the status of the service to make sure it’s running:

    sudo systemctl status systemd-timesyncd

    Output● systemd-timesyncd.service - Network Time Synchronization
       Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
      Drop-In: /lib/systemd/system/systemd-timesyncd.service.d
               └─disable-with-time-daemon.conf
       Active: active (running) since Tue 2018-09-04 16:14:23 EDT; 1s ago
         Docs: man:systemd-timesyncd.service(8)
     Main PID: 3399 (systemd-timesyn)
       Status: "Synchronized to time server 198.60.22.240:123 (0.debian.pool.ntp.org)."
        Tasks: 2 (limit: 4915)
       CGroup: /system.slice/systemd-timesyncd.service
               └─3399 /lib/systemd/systemd-timesyncd

We can use `timedatectl` to print out systemd’s current understanding of the time:

    timedatectl

    Output Local time: Tue 2018-09-04 16:15:34 EDT
      Universal time: Tue 2018-09-04 20:15:34 UTC
            RTC time: Tue 2018-09-04 20:15:33
           Time zone: America/New_York (EDT, -0400)
     Network time on: yes
    NTP synchronized: yes
     RTC in local TZ: no

This prints out the local time, universal time (which may be the same as local time, if you didn’t switch from the UTC time zone), and some network time status information. `Network time on: yes` means that timesyncd is enabled, and `NTP synchronized: yes` indicates that the time has been successfully synced.

## Conclusion

In this article we’ve shown how to view the system time, change time zones, work with ntpd, and switch to systemd’s timesyncd service. If you have more sophisticated timekeeping needs than what we’ve covered here, you might refer to [the offical NTP documentation](https://www.eecis.udel.edu/%7Emills/ntp/html/index.html), and also take a look at [the NTP Pool Project](http://www.pool.ntp.org/), a global group of volunteers providing much of the world’s NTP infrastructure.
