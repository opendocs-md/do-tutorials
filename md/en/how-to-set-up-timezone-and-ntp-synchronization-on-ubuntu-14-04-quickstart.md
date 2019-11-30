---
author: Mitchell Anicas
date: 2016-03-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-timezone-and-ntp-synchronization-on-ubuntu-14-04-quickstart
---

# How To Set Up Timezone and NTP Synchronization on Ubuntu 14.04 [Quickstart]

## Introduction

Setting your server’s clock and timezone properly is essential in ensuring the healthy operation of distributed systems and maintaining accurate log timestamps. This tutorial will show you how to configure NTP time synchronization and set the timezone on an Ubuntu 14.04 server.

A more detailed version of this tutorial, with better explanations of each step, can be found [here](additional-recommended-steps-for-new-ubuntu-14-04-servers#configure-timezones-and-network-time-protocol-synchronization).

## Step 1: List available timezones

    timedatectl list-timezones

- Press **Space** to scroll to the next page, **b** to scroll back a page.
- Once you find the timezone you want to use, press **q** to go back to the command line.

## Step 2: Set the desired timezone

Be sure to replace desired\_timezone with the timezone you selected from the list:

    sudo timedatectl set-timezone desired_timezone

For example, to set the timezone to New York use this command:

    sudo timedatectl set-timezone America/New_York

## Step 3: Verify that the timezone has been set properly

    timedatectl

    Example output: Local time: Fri 2016-03-25 12:00:43 EDT
      Universal time: Fri 2016-03-25 16:00:43 UTC
            Timezone: America/New_York (EDT, -0400)
    . . .

## Step 4: Install NTP

    sudo apt-get update
    sudo apt-get install ntp

Once the NTP package installation is completed, your server will have NTP synchronization enabled!

## Related Tutorials

Here is a link to a more detailed tutorial that is related to this guide:

- [Additional Recommended Steps for New Ubuntu 14.04 Servers](additional-recommended-steps-for-new-ubuntu-14-04-servers)
