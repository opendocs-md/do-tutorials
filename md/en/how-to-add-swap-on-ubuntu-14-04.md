---
author: Justin Ellingwood
date: 2014-04-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
---

# How To Add Swap on Ubuntu 14.04

## Introduction

One of the easiest way of increasing the responsiveness of your server and guarding against out of memory errors in your applications is to add some swap space. **Swap** is an area on a hard drive that has been designated as a place where the operating system can temporarily store data that it can no longer hold in RAM.

Basically, this gives you the ability to increase the amount of information that your server can keep in its working “memory”, with some caveats. The space on the hard drive will be used mainly when space in RAM is no longer sufficient for data.

The information written to disk will be slower than information kept in RAM, but the operating system will prefer to keep running application data in memory and use swap for the older data. Overall, having swap space as a fall back for when your system’s RAM is depleted is a good safety net.

In this guide, we’ll cover how to create and enable a swap file on an Ubuntu 14.04 server.

Note

Although swap is generally recommended for systems utilizing traditional spinning hard drives, using swap with SSDs can cause issues with hardware degradation over time. Due to this consideration, we do not recommend enabling swap on DigitalOcean or any other provider that utilizes SSD storage. Doing so can impact the reliability of the underlying hardware for you and your neighbors.

If you need to improve the performance of your server, we recommend upgrading your Droplet. This will lead to better results in general and will decrease the likelihood of contributing to hardware issues that can affect your service.

## Check the System for Swap Information

Before we begin, we will take a look at our operating system to see if we already have some swap space available. We can have multiple swap files or swap partitions, but generally one should be enough.

We can see if the system has any configured swap by typing:

    sudo swapon -s

* * *

    Filename Type Size Used Priority

If you only get back the header of the table, as I’ve shown above, you do not currently have any swap space enabled.

Another, more familiar way of checking for swap space is with the `free` utility, which shows us system memory usage. We can see our current memory and swap usage in Megabytes by typing:

    free -m

     total used free shared buffers cached Mem: 3953 154 3799 0 8 83 -/+ buffers/cache: 62 3890Swap: 0 0 0

As you can see above, our total swap space in the system is “0”. This matches what we saw with the previous command.

## Check Available Space on the Hard Drive Partition

The typical way of allocating space for swap is to use a separate partition devoted to the task. However, altering the partitioning scheme is not always possible. We can just as easily create a swap file that resides on an existing partition.

Before we do this, we should be aware of our current disk usage. We can get this information by typing:

    df -h

    Filesystem Size Used Avail Use% Mounted on/dev/vda 59G 1.3G 55G 3% /none 4.0K 0 4.0K 0% /sys/fs/cgroup udev 2.0G 12K 2.0G 1% /dev tmpfs 396M 312K 396M 1% /run none 5.0M 0 5.0M 0% /run/lock none 2.0G 0 2.0G 0% /run/shm none 100M 0 100M 0% /run/user

As you can see on the first line, our hard drive partition has 55 Gigabytes available, so we have a huge amount of space to work with. This is on a fresh, medium-sized VPS instance, however, so your actual usage might be very different.

Although there are many opinions about the appropriate size of a swap space, it really depends on your personal preferences and your application requirements. Generally, an amount equal to or double the amount of RAM on your system is a good starting point.

Since my system has 4 Gigabytes of RAM, and doubling that would take a significant chunk of my disk space that I’m not willing to part with, I will create a swap space of 4 Gigabytes to match my system’s RAM.

## Create a Swap File

Now that we know our available hard drive space, we can go about creating a swap file within our filesystem.

We will create a file called `swapfile` in our root (/) directory. The file must allocate the amount of space we want for our swap file. There are two main ways of doing this:

### The Traditional, Slow Way

Traditionally, we would create a file with preallocated space by using the `dd` command. This versatile disk utility writes from one location to another location.

We can use this to write zeros to the file from a special device in Linux systems located at `/dev/zero` that just spits out as many zeros as requested.

We specify the file size by using a combination of `bs` for block size and `count` for the number of blocks. What we assign to each parameter is almost entirely arbitrary. What matters is what the product of multiplying them turns out to be.

For instance, in our example, we’re looking to create a 4 Gigabyte file. We can do this by specifying a block size of 1 Gigabyte and a count of 4:

    sudo dd if=/dev/zero of=/swapfile bs=1G count=4

* * *

    4+0 records in
    4+0 records out
    4294967296 bytes (4.3 GB) copied, 18.6227 s, 231 MB/s

Check your command before pressing ENTER because this has the potential to destroy data if you point the `of` (which stands for output file) to the wrong location.

We can see that 4 Gigabytes have been allocated by typing:

    ls -lh /swapfile

    -rw-r--r-- 1 root root 4.0G Apr 28 17:15 /swapfile

If you’ve completed the command above, you may notice that it took quite a while. In fact, you can see in the output that it took my system 18 seconds to create the file. That is because it has to write 4 Gigabytes of zeros to the disk.

If you want to learn how to create the file faster, remove the file and follow along below:

    sudo rm /swapfile

### The Faster Way

The quicker way of getting the same file is by using the `fallocate` program. This command creates a file of a preallocated size instantly, without actually having to write dummy contents.

We can create a 4 Gigabyte file by typing:

    sudo fallocate -l 4G /swapfile

The prompt will be returned to you almost immediately. We can verify that the correct amount of space was reserved by typing:

    ls -lh /swapfile

    -rw-r--r-- 1 root root 4.0G Apr 28 17:19 /swapfile

As you can see, our file is created with the correct amount of space set aside.

## Enabling the Swap File

Right now, our file is created, but our system does not know that this is supposed to be used for swap. We need to tell our system to format this file as swap and then enable it.

Before we do that though, we need to adjust the permissions on our file so that it isn’t readable by anyone besides root. Allowing other users to read or write to this file would be a huge security risk. We can lock down the permissions by typing:

    sudo chmod 600 /swapfile

Verify that the file has the correct permissions by typing:

    ls -lh /swapfile

    -rw------- 1 root root 4.0G Apr 28 17:19 /swapfile

As you can see, only the columns for the root user have the read and write flags enabled.

Now that our file is more secure, we can tell our system to set up the swap space by typing:

    sudo mkswap /swapfile

* * *

    Setting up swapspace version 1, size = 4194300 KiB
    no label, UUID=e2f1e9cf-c0a9-4ed4-b8ab-714b8a7d6944

Our file is now ready to be used as a swap space. We can enable this by typing:

    sudo swapon /swapfile

We can verify that the procedure was successful by checking whether our system reports swap space now:

    sudo swapon -s

    Filename Type Size Used Priority/swapfile file 4194300 0 -1

We have a new swap file here. We can use the `free` utility again to corroborate our findings:

    free -m

     total used free shared buffers cached Mem: 3953 101 3851 0 5 30 -/+ buffers/cache: 66 3887Swap: 4095 0 4095

Our swap has been set up successfully and our operating system will begin to use it as necessary.

## Make the Swap File Permanent

We have our swap file enabled, but when we reboot, the server will not automatically enable the file. We can change that though by modifying the `fstab` file.

Edit the file with root privileges in your text editor:

    sudo nano /etc/fstab

At the bottom of the file, you need to add a line that will tell the operating system to automatically use the file you created:

    /swapfile none swap sw 0 0

Save and close the file when you are finished.

## Tweak your Swap Settings

There are a few options that you can configure that will have an impact on your system’s performance when dealing with swap.

The `swappiness` parameter configures how often your system swaps data out of RAM to the swap space. This is a value between 0 and 100 that represents a percentage.

With values close to zero, the kernel will not swap data to the disk unless absolutely necessary. Remember, interactions with the swap file are “expensive” in that they take a lot longer than interactions with RAM and they can cause a significant reduction in performance. Telling the system not to rely on the swap much will generally make your system faster.

Values that are closer to 100 will try to put more data into swap in an effort to keep more RAM space free. Depending on your applications’ memory profile or what you are using your server for, this might be better in some cases.

We can see the current swappiness value by typing:

    cat /proc/sys/vm/swappiness

* * *

    60

For a Desktop, a swappiness setting of 60 is not a bad value. For a VPS system, we’d probably want to move it closer to 0.

We can set the swappiness to a different value by using the `sysctl` command.

For instance, to set the swappiness to 10, we could type:

    sudo sysctl vm.swappiness=10

* * *

    vm.swappiness = 10

This setting will persist until the next reboot. We can set this value automatically at restart by adding the line to our `/etc/sysctl.conf` file:

    sudo nano /etc/sysctl.conf

At the bottom, you can add:

    vm.swappiness=10

Save and close the file when you are finished.

Another related value that you might want to modify is the `vfs_cache_pressure`. This setting configures how much the system will choose to cache inode and dentry information over other data.

Basically, this is access data about the filesystem. This is generally very costly to look up and very frequently requested, so it’s an excellent thing for your system to cache. You can see the current value by querying the `proc` filesystem again:

    cat /proc/sys/vm/vfs_cache_pressure

* * *

    100

As it is currently configured, our system removes inode information from the cache too quickly. We can set this to a more conservative setting like 50 by typing:

    sudo sysctl vm.vfs_cache_pressure=50

* * *

    vm.vfs_cache_pressure = 50

Again, this is only valid for our current session. We can change that by adding it to our configuration file like we did with our swappiness setting:

    sudo nano /etc/sysctl.conf

At the bottom, add the line that specifies your new value:

    vm.vfs_cache_pressure = 50

Save and close the file when you are finished.

## Conclusion

Following the steps in this guide will give you some breathing room in terms of your RAM usage. Swap space is incredibly useful in avoiding some common problems.

If you are running into OOM (out of memory) errors, or if you find that your system is unable to use the applications you need, the best solution is to optimize your application configurations or upgrade your server. Configuring swap space, however, can give you more flexibility and can help buy you time on a less powerful server.

By Justin Ellingwood
