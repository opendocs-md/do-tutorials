---
author: Etel Sverdlov
date: 2012-10-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-time-synchronization-on-ubuntu-12-04
---

# How To Set Up Time Synchronization on Ubuntu 12.04

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

### About NTP

Launching a new virtual private server provides the user with a clock. You can see the time on your server with the command, _date_. Furthermore, you can adjust the server’s time zone, if needed, with the command _export TZ=America/New\_York_,modifying the time zone to match your location.

Although the built in clock is helpful for keeping track of events on the server itself, it may begin to cause issues if the virtual server has to work with external machines. Emails sent out from a misconfigured server may arrive 3 minutes in the past on another, or users granted access only at certain times of the day, may find themselves blocked because of a time mismatch.

In order to resolve this, servers can be synced using the NTP protocol, matching their time to a reference time that servers around the world agree upon. This can be set up by installing the ntp daemon on the VPS— the program will automatically, slowly shift the server clock to match the reference one. Another method of fixing the time is to run ntpdate which automatically matches the time on the server with that of the central time. However, ntpdate is not an action that should be taken regularly because it syncs the virtual server’s time so quickly, the jump in time may cause issues with time sensitive software. Therefore, it is best to run this only once, prior to setting up NTP, and then let NTP take over—otherwise, if the server’s time is too far off, NTP may not launch altogether.

    sudo ntpdate pool.ntp.org

NTP needs port 123 to be open in order to work.

## Step One— Install the NTP daemon

The easiest way to ensure that your time remains up to date is to install the Network Time Protocol daemon.

You can download it from apt-get.

    sudo apt-get install ntp

## Step Two— Configure the NTP Servers

Once the program is installed, open up the configuration file:

    sudo nano /etc/ntp.conf

Find the section within the configuration that lists the NTP Pool Project servers. The section will look like this:

    server 0.ubuntu.pool.ntp.org server 1.ubuntu.pool.ntp.org server 2.ubuntu.pool.ntp.org server 3.ubuntu.pool.ntp.org

Each line then refers to a set of hourly-changing random servers that provide your server with the correct time. The servers that are set up are located all around the world, and you can see the details of the volunteer servers that provide the time with the

     ntpq -p

command. You should see something like the following:

     remote refid st t when poll reach delay offset jitter ============================================================================== -mail.fspproduct 209.51.161.238 2 u 50 128 377 1.852 2.768 0.672 \*higgins.chrtf.o 18.26.4.105 2 u 113 128 377 14.579 -0.408 2.817 +mdnworldwide.co 108.71.253.18 2 u 33 128 377 47.309 -0.572 1.033 -xen1.rack911.co 209.51.161.238 2 u 44 128 377 87.449 -5.716 0.605 +europium.canoni 193.79.237.14 2 u 127 128 377 75.755 -2.797 0.718

 Although these servers will accomplish the task of setting and maintaining server time, you set your time much more effectively by limiting the ntp to the ones in your region (europe, north-america, oceania or asia), or even to the ones in your country, for example in America: 

     us.pool.ntp.org

You can find the list international country codes (although not all of the countries have codes) [here](http://support.ntp.org/bin/view/Servers/NTPPoolServers)

Once all of the information is in the configuration file, restart ntp:

    sudo service ntp restart

NTP will slowly start to adjust the virtual private server’s time.

By Etel Sverdlov
