---
author: Vinícius Zavam
date: 2016-06-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-openntpd-on-freebsd-10-2
---

# How To Install and Configure OpenNTPd on FreeBSD 10.2

## Introduction

NTP, the Network Time Protocol, is a standardized protocol providing ways to synchronize time on various operating systems. [OpenNTPd](http://openntpd.org) is a free and easy-to-use implementation of the Network Time Protocol (NTP), originally developed as part of the [OpenBSD](http://openbsd.org) project. It provides the ability to sync the local clock from remote NTP servers and can also act as server itself.

This tutorial will show you how to install OpenNTPd on FreeBSD.

## Prerequisites

To follow this tutorial, you need to have:

- One FreeBSD 10.2 Droplet with a **root** user; the default **freebsd** user on DigitalOcean is fine.

A FreeBSD Droplet requires an SSH key for remote access. For help on setting up an SSH key, read [How To Configure SSH Key-Based Authentication on a FreeBSD Server](how-to-configure-ssh-key-based-authentication-on-a-freebsd-server). To learn more about logging into your FreeBSD Droplet and basic management, check out the [Getting Started with FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd) tutorial series.

## Step 1 — Installing OpenNTPd

Before installing OpenNTPd, update the repository information used by `pkg`:

    sudo pkg update

Then install the OpenNTPd package:

    sudo pkg install openntpd

The default OpenNTPd configuration uses `pool.ntp.org` as its default time servers and is configured to work only as a client machine. The rest of this tutorial will show how to change the time server used and how to configure OpenNTPd as a time server.

## Step 2 — Changing the Time Server ((Optional)

The next several steps will edit `/usr/local/etc/ntpd.conf`, the default configuration file. Use `ee`, `vi`, or your favorite text editor to edit the configuration file.

    sudo ee /usr/local/etc/ntpd.conf

Powered by the Ask Bjørn Hansen’s [GeoDNS](https://github.com/abh/geodns), `pool.ntp.org` will usually return IP addresses for servers in or close to your country. For most users this will give the best results.

Alternatively, you can also use a country zone like `br.pool.ntp.org`, `de.pool.ntp.org`, or `ru.pool.ntp.org` to force/limit results to fit in your personal needs. To read more about the NTP Pool Project, visit [pool.ntp.org](http://www.pool.ntp.org).

For the example in this tutorial, we will use [NTP.br](http://ntp.br), a project in Brazil that preserves and distributes the legal time in Brazilian territory. If you are not in Brazil, use a similar project in your country or region.

Define your desired time server like this, substituting `pool.ntp.br` with your chosen time server.

/usr/local/etc/ntpd.conf

    # $OpenBSD: ntpd.conf,v 1.2 2015/02/10 06:40:08 reyk Exp $
    # sample ntpd configuration file, see ntpd.conf(5)
    
    # Addresses to listen on (ntpd does not listen by default)
    #listen on *
    
    # sync to a single server
    #server ntp.example.org
    
    # use a random selection of NTP Pool Time Servers
    # see http://support.ntp.org/bin/view/Servers/NTPPoolServers
    servers pool.ntp.br
    
    # use a specific local timedelta sensor (radio clock, etc)
    #sensor nmea0
    
    # use all detected timedelta sensors
    #sensor *
    
    # get the time constraint from a well-known HTTPS site
    #constraints from "https://www.google.com/search?q=openntpd"

## Step 3 — Changing the Constraints

A custom client setup can also add support to constraints so `ntpd` can query the `Date:` headers from trusted HTTPS servers via TLS.

The `ntpd.conf(5)` manpage says: “Received NTP packets with time information falling outside of a range near the constraint will be discarded and such NTP servers will be marked as invalid”. This prevents against some MITM attacks while preserving the clock accuracy.

Add the constraints to `/usr/local/etc/ntpd.conf`. Be sure to use one or more reliable, well-known HTTPS sites. You can uncomment the example line provided in the file by deleting the first `#` character higlighted below:

/usr/local/etc/ntpd.conf

    # $OpenBSD: ntpd.conf,v 1.2 2015/02/10 06:40:08 reyk Exp $
    # sample ntpd configuration file, see ntpd.conf(5)
    
    # Addresses to listen on (ntpd does not listen by default)
    #listen on *
    
    # sync to a single server
    #server ntp.example.org
    
    # use a random selection of NTP Pool Time Servers
    # see http://support.ntp.org/bin/view/Servers/NTPPoolServers
    servers pool.ntp.br
    
    # use a specific local timedelta sensor (radio clock, etc)
    #sensor nmea0
    
    # use all detected timedelta sensors
    #sensor *
    
    # get the time constraint from a well-known HTTPS site
    # constraints from "https://www.google.com/search?q=openntpd"

## Step 4 — Configuring OpenNTPd as a Time Server

This section shows you how to change the default behavior of OpenNTPd and turn FreeBSD to an NTP server capable of serving time over IPv4 and IPv6.

The final results for a server configuration should look like this, with `your_server_ip` replaced with the IPv4 or IPv6 address of your server.

/usr/local/etc/ntpd.conf

    # $OpenBSD: ntpd.conf,v 1.2 2015/02/10 06:40:08 reyk Exp $
    # sample ntpd configuration file, see ntpd.conf(5)
    
    # Addresses to listen on (ntpd does not listen by default)
    listen on your_server_ip
    
    # sync to a single server
    #server ntp.example.org
    
    # use a random selection of NTP Pool Time Servers
    # see http://support.ntp.org/bin/view/Servers/NTPPoolServers
    servers pool.ntp.br
    
    # use a specific local timedelta sensor (radio clock, etc)
    #sensor nmea0
    
    # use all detected timedelta sensors
    #sensor *
    
    # get the time constraint from a well-known HTTPS site
    #constraints from "https://www.google.com/search?q=openntpd"

## Step 5 — Starting OpenNTPd at Boot

The default service configuration for OpenNTPd will not start the daemon during the FreeBSD’s boot process. To add the NTP service provided by `ntpd` on FreeBSD, execute the following:

    sudo sysrc openntpd_enable="YES"

The output should be:

    Outputopenntpd_enable: -> YES

If you want to set the time immediately at startup, add `-s` to `openntpd_flags`. `-v` can also be used so that all calls to `adjtime` will be logged. Passing `-s` to `ntpd` will cause the daemon to stay in the foreground for up to 15 seconds waiting for one of the configured NTP servers to reply. This is not the default, and a custom setup like this should be configure as so:

    sudo sysrc openntpd_flags="-s -v"

The output should be:

    Outputopenntpd_flags: -> -s -v

## Step 6 — Managing the OpenNTPd Service

Now that you have the configuration file edited and customized to fit all your needs, you can start the service provided by OpenNTPd.

To start the service:

    sudo service openntpd start

If it starts successfully, you will see:

    OutputStarting openntpd.

If the OpenNTPd daemon’s flags are configured to log debug information, starting the output should look like this:

    OutputStarting openntpd.
    constraint certificate verification turned off
    ntp_adjtime returns frequency of 8.643158ppm

You can manage the OpenNTPd service with the usual commands: `status`, `restart`, etc.

## Step 7 — Troubleshooting (Optional)

OpenNTPd uses two binaries: `ntpd` and `ntpctl`. The first one is the daemon itself and is responsible for the NTP service provided to the client or server machine. The second one is used to display information about the running daemon.

This section will show you how to use `ntpctl`, `nc`, and `sockstat` to troubleshoot the NTP service provided by OpenNTPd and its daemon. If you have a running service, or just want a different way to check if your service is running, use this section.

### Getting Status and Peers

OpenNTPd’s `ntpctl` uses a local socket for communicating with the OpenNTPd daemon. It defaults to `/var/run/ntpd.sock`. This tutorial will cover two kinds of queries you can run with `ntpctl`: `status` and `peers`.

`status` shows the status of peers and sensors as well as whether the system clock is synced. When the system clock is synced, the stratum is displayed. When the system clock is not synced, the offset of the system clock, as reported by the `adjtime` system call, is displayed. When the median constraint is set, the offset to the local time is displayed.

To show the status using ntpctl:

    sudo ntpctl -s status

The output should be similar to the following:

Output

    8/8 peers valid, clock synced, stratum 2

`peers` shows the following information about each peer: weight(wt), trustlevel(tl), stratum(st), and the number of seconds until the next update to the peer (next poll). The offset, network delay, and network jitter values are in milliseconds. When the system clock is synced to a peer, an asterisk( **\*** ) is displayed to the left of the weight column for that peer.

To show peers information using `ntpctl`:

    sudo ntpctl -s peers

The following output shows you the information that OpenNTPd is running and synced to the stratum 1 server responding as ‘200.160.7.193’ (resolved from pool.ntp.br), and your OpenNTPd daemon will be updating the time via NTP in 31 seconds:

    Output peer
               wt tl st next poll offset delay jitter
            200.160.0.8 from pool pool.ntp.br
                1 10 2 8s 30s -0.005ms 44.814ms 0.023ms
            200.160.7.193 from pool pool.ntp.br
             * 1 10 1 26s 31s -0.012ms 44.814ms 0.027ms
            200.20.186.76 from pool pool.ntp.br
                1 10 1 18s 31s 0.023ms 37.481ms 0.031ms
    
    . . .

### Listening Sockets

You can use `sockstat` to list open IPv4, IPv6, and UNIX domain sockets. To list the listening sockets related to NTP over IPv4 and IPv6:

    sudo sockstat -4 -6 -p 123

Output

    USER COMMAND PID FD PROTO LOCAL ADDRESS FOREIGN ADDRESS     
    _ntp ntpd 44208 7 udp4 203.0.113.123:16987 200.160.0.8:123
    _ntp ntpd 44208 8 udp4 203.0.113.123:38739 200.160.7.193:123
    
    . . .

If you are running OpenNTPd to serve time over the network, the `LOCAL ADDRESS` column would show you a line with your IP addresses; `your_ipv4_address:123`, representing the IPv4 socket, and `your_ipv6_address:123`, showing a listening IPv6 socket.

### Connecting to the Internet

Use `nc` to troubleshoot not only NTP but lots of network daemons and their sockets (UNIX, TCP, or UDP). The manpage says: “Unlike `telnet`, netcat scripts nicely and separates error messages onto standard error instead of sending them to standard output as `telnet` does with some”.

To check if you can reach a NTP server, or pool host, over IPv4:

    sudo nc pool.ntp.br 123 -z -4 -u -v 

    OutputConnection to pool.ntp.br 123 port [udp/ntp] succeeded!

To check if you can reach a NTP server, or pool host, over IPv6:

    sudo nc pool.ntp.br 123 -z -6 -u -v 

    OutputConnection to pool.ntp.br 123 port [udp/ntp] succeeded!

### Using ntpdate

Use `ntpdate` to troubleshoot some of the servers you may want to use. You can get some information about the machine running the NTP service: `stratum`, `offset` and `delay`.

    sudo ntpdate -q -4 ntp.cais.rnp.br

The output will look similar to:

    Outputserver 200.144.121.33, stratum 3, offset -0.000049, delay 0.09001
    1 Sep 17:28:54 ntpdate[66740]: adjust time server 200.144.121.33 offset -0.000049 sec

Note that the functionality of `ntpdate` is now available in the FreeBSD’s `ntpd` program. See the `-q` command line option in the FreeBSD’s `ntpd` manpage, or use `ntpq`.

**Warning:** The `ntpdate` utility will be retired soon.

### Reading Manual Pages

OpenNTPd’s `ntpd`, `ntpd.conf` and `ntpctl` are not part of FreeBSD’s base system, so its manual pages are also not part of the operating system’s default `MANPATH`. To be sure you will be reading the OpenNTPd’s manual pages, you should run `man` with `-M /usr/local/man`. Don’t be confused with FreeBSD’s default `ntpd(8)` manpage.

    man -M /usr/local/man ntpd

Repeat the same procedure to read OpenNTPd’s `ntpctl(8)` or `ntpd.conf(5)` manpage.

## Conclusion

Time is inherently important to the function of workstations, servers, routers, and networks. Without synchronized time, accurately correlating information between devices becomes difficult, if not impossible. When it comes to security, if you cannot successfully compare logs between each of your routers and all your network servers, you will find it very hard to develop a reliable picture of an incident.
