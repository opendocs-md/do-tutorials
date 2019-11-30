---
author: Justin Ellingwood
date: 2016-04-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04
---

# How To Add Swap Space on Ubuntu 16.04

## Introduction

One of the easiest way of increasing the responsiveness of your server and guarding against out-of-memory errors in applications is to add some swap space. In this guide, we will cover how to add a swap file to an Ubuntu 16.04 server.

Warning

Although swap is generally recommended for systems utilizing traditional spinning hard drives, using swap with SSDs can cause issues with hardware degradation over time. Due to this consideration, we do not recommend enabling swap on DigitalOcean or any other provider that utilizes SSD storage. Doing so can impact the reliability of the underlying hardware for you and your neighbors. This guide is provided as reference for users who may have spinning disk systems elsewhere.

If you need to improve the performance of your server on DigitalOcean, we recommend upgrading your Droplet. This will lead to better results in general and will decrease the likelihood of contributing to hardware issues that can affect your service.

## What is Swap?

**Swap** is an area on a hard drive that has been designated as a place where the operating system can temporarily store data that it can no longer hold in RAM. Basically, this gives you the ability to increase the amount of information that your server can keep in its working “memory”, with some caveats. The swap space on the hard drive will be used mainly when there is no longer sufficient space in RAM to hold in-use application data.

The information written to disk will be significantly slower than information kept in RAM, but the operating system will prefer to keep running application data in memory and use swap for the older data. Overall, having swap space as a fall back for when your system’s RAM is depleted can be a good safety net against out-of-memory exceptions on systems with non-SSD storage available.

## Check the System for Swap Information

Before we begin, we can check if the system already has some swap space available. It is possible to have multiple swap files or swap partitions, but generally one should be enough.

We can see if the system has any configured swap by typing:

    sudo swapon --show

If you don’t get back any output, this means your system does not have swap space available currently.

You can verify that there is no active swap using the `free` utility:

    free -h

    Output total used free shared buff/cache available
    Mem: 488M 36M 104M 652K 348M 426M
    Swap: 0B 0B 0B

As you can see in the “Swap” row of the output, no swap is active on the system.

## Check Available Space on the Hard Drive Partition

The most common way of allocating space for swap is to use a separate partition devoted to the task. However, altering the partitioning scheme is not always possible. We can just as easily create a swap file that resides on an existing partition.

Before we do this, we should check the current disk usage by typing:

    df -h

    OutputFilesystem Size Used Avail Use% Mounted on
    udev 238M 0 238M 0% /dev
    tmpfs 49M 624K 49M 2% /run
    /dev/vda1 20G 1.1G 18G 6% /
    tmpfs 245M 0 245M 0% /dev/shm
    tmpfs 5.0M 0 5.0M 0% /run/lock
    tmpfs 245M 0 245M 0% /sys/fs/cgroup
    tmpfs 49M 0 49M 0% /run/user/1001

The device under `/dev` is our disk in this case. We have plenty of space available in this example (only 1.1G used). Your usage will probably be different.

Although there are many opinions about the appropriate size of a swap space, it really depends on your personal preferences and your application requirements. Generally, an amount equal to or double the amount of RAM on your system is a good starting point. Another good rule of thumb is that anything over 4G of swap is probably unnecessary if you are just using it as a RAM fallback.

## Create a Swap File

Now that we know our available hard drive space, we can go about creating a swap file within our filesystem. We will create a file of the swap size that we want called `swapfile` in our root (/) directory.

The best way of creating a swap file is with the `fallocate` program. This command creates a file of a preallocated size instantly.

Since the server in our example has 512MB of RAM, we will create a 1 Gigabyte file in this guide. Adjust this to meet the needs of your own server:

    sudo fallocate -l 1G /swapfile

We can verify that the correct amount of space was reserved by typing:

    ls -lh /swapfile

    -rw-r--r-- 1 root root 1.0G Apr 25 11:14 /swapfile

Our file has been created with the correct amount of space set aside.

## Enabling the Swap File

Now that we have a file of the correct size available, we need to actually turn this into swap space.

First, we need to lock down the permissions of the file so that only the users with `root` privileges can read the contents. This prevents normal users from being able to access the file, which would have significant security implications.

Make the file only accessible to `root` by typing:

    sudo chmod 600 /swapfile

Verify the permissions change by typing:

    ls -lh /swapfile

    Output-rw------- 1 root root 1.0G Apr 25 11:14 /swapfile

As you can see, only the root user has the read and write flags enabled.

We can now mark the file as swap space by typing:

    sudo mkswap /swapfile

    OutputSetting up swapspace version 1, size = 1024 MiB (1073737728 bytes)
    no label, UUID=6e965805-2ab9-450f-aed6-577e74089dbf

After marking the file, we can enable the swap file, allowing our system to start utilizing it:

    sudo swapon /swapfile

We can verify that the swap is available by typing:

    sudo swapon --show

    OutputNAME TYPE SIZE USED PRIO
    /swapfile file 1024M 0B -1

We can check the output of the `free` utility again to corroborate our findings:

    free -h

    Output total used free shared buff/cache available
    Mem: 488M 37M 96M 652K 354M 425M
    Swap: 1.0G 0B 1.0G

Our swap has been set up successfully and our operating system will begin to use it as necessary.

## Make the Swap File Permanent

Our recent changes have enabled the swap file for the current session. However, if we reboot, the server will not retain the swap settings automatically. We can change this by adding the swap file to our `/etc/fstab` file.

Back up the `/etc/fstab` file in case anything goes wrong:

    sudo cp /etc/fstab /etc/fstab.bak

You can add the swap file information to the end of your `/etc/fstab` file by typing:

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

## Tweak your Swap Settings

There are a few options that you can configure that will have an impact on your system’s performance when dealing with swap.

### Adjusting the Swappiness Property

The `swappiness` parameter configures how often your system swaps data out of RAM to the swap space. This is a value between 0 and 100 that represents a percentage.

With values close to zero, the kernel will not swap data to the disk unless absolutely necessary. Remember, interactions with the swap file are “expensive” in that they take a lot longer than interactions with RAM and they can cause a significant reduction in performance. Telling the system not to rely on the swap much will generally make your system faster.

Values that are closer to 100 will try to put more data into swap in an effort to keep more RAM space free. Depending on your applications’ memory profile or what you are using your server for, this might be better in some cases.

We can see the current swappiness value by typing:

    cat /proc/sys/vm/swappiness

    Output60

For a Desktop, a swappiness setting of 60 is not a bad value. For a server, you might want to move it closer to 0.

We can set the swappiness to a different value by using the `sysctl` command.

For instance, to set the swappiness to 10, we could type:

    sudo sysctl vm.swappiness=10

    Outputvm.swappiness = 10

This setting will persist until the next reboot. We can set this value automatically at restart by adding the line to our `/etc/sysctl.conf` file:

    sudo nano /etc/sysctl.conf

At the bottom, you can add:

/etc/sysctl.conf

    vm.swappiness=10

Save and close the file when you are finished.

### Adjusting the Cache Pressure Setting

Another related value that you might want to modify is the `vfs_cache_pressure`. This setting configures how much the system will choose to cache inode and dentry information over other data.

Basically, this is access data about the filesystem. This is generally very costly to look up and very frequently requested, so it’s an excellent thing for your system to cache. You can see the current value by querying the `proc` filesystem again:

    cat /proc/sys/vm/vfs_cache_pressure

    Output100

As it is currently configured, our system removes inode information from the cache too quickly. We can set this to a more conservative setting like 50 by typing:

    sudo sysctl vm.vfs_cache_pressure=50

    Outputvm.vfs_cache_pressure = 50

Again, this is only valid for our current session. We can change that by adding it to our configuration file like we did with our swappiness setting:

    sudo nano /etc/sysctl.conf

At the bottom, add the line that specifies your new value:

/etc/sysctl.conf

    vm.vfs_cache_pressure=50

Save and close the file when you are finished.

## Conclusion

Following the steps in this guide will give you some breathing room in cases that would otherwise lead to out-of-memory exceptions. Swap space can be incredibly useful in avoiding some of these common problems.

If you are running into OOM (out of memory) errors, or if you find that your system is unable to use the applications you need, the best solution is to optimize your application configurations or upgrade your server.
