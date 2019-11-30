---
author: Josh Barnett
date: 2014-10-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-centos-7
---

# How To Add Swap on CentOS 7

## Introduction

One of the easiest ways to make your server more responsive, and guard against out-of-memory errors in your application, is to add some swap space. **Swap** is an area on a storage drive where the operating system can temporarily store data that it can no longer hold in memory.

This gives you the ability to increase the amount of information that your server can keep in its working memory, with some caveats. Reading from and writing to swap is slower than using memory, but it can provide a good safety net for when your server is low on memory.

Without swap, a server that runs out of memory may start killing applications to free up memory, or even crash. This can cause you to lose unsaved data or experience downtime. To ensure reliable data access, some applications require swap to function.

In this guide, we will cover how to create and enable a swap file on a CentOS 7 server.

Note

Although swap is generally recommended for systems utilizing traditional spinning hard drives, using swap with SSDs can cause issues with hardware degradation over time. Due to this consideration, we do not recommend enabling swap on DigitalOcean or any other provider that utilizes SSD storage. Doing so can impact the reliability of the underlying hardware for you and your neighbors.

If you need to improve the performance of your server, we recommend upgrading your Droplet. This will lead to better results in general and will decrease the likelihood of contributing to hardware issues that can affect your service.

## Prerequisites

Before you begin with this guide, there are a few steps that need to be completed first.

You will need a CentOS 7 server installed and configured with a non-root user that has `sudo` privileges. If you haven’t done this yet, you can run through steps 1-4 in the [CentOS 7 initial server setup guide](initial-server-setup-with-centos-7) to create this account.

Once you have your non-root user, you can use it to SSH into your CentOS server and continue with the installation of your swap file.

## Check the System for Swap Information

Before we begin, we should take a look at our server’s storage to see if we already have some swap space available. While we can have multiple swap files or swap partitions, one should generally be enough.

We can see if the system has any configured swap by using `swapon`, a general-purpose swap utility. With the `-s` flag, `swapon` will display a summary of swap usage and availability on our storage device:

    swapon -s

If nothing is returned by the command, then the summary was empty and no swap file exists.

Another way of checking for swap space is with the `free` utility, which shows us the system’s overall memory usage. We can see our current memory and swap usage (in megabytes) by typing:

    free -m

                 total used free shared buffers cached
    Mem: 3953 315 3637 8 11 107
    -/+ buffers/cache: 196 3756
    Swap: 0 0 4095

As you can see, our total swap space in the system is 0. This matches what we saw with `swapon`.

## Check Available Storage Space

The typical way of allocating space for swap is to use a separate partition that is dedicated to the task. However, altering the partition scheme is not always possible due to hardware or software constraints. Fortunately, we can just as easily create a swap file that resides on an existing partition.

Before we do this, we should be aware of our current drive usage. We can get this information by typing:

    df -h

    Filesystem Size Used Avail Use% Mounted on
    /dev/vda1 59G 1.5G 55G 3% /
    devtmpfs 2.0G 0 2.0G 0% /dev
    tmpfs 2.0G 0 2.0G 0% /dev/shm
    tmpfs 2.0G 8.3M 2.0G 1% /run
    tmpfs 2.0G 0 2.0G 0% /sys/fs/cgroup

**Note:** the `-h` flag simply tells `dh` to output drive information in a human-friendly reading format. For example, instead of outputting the raw number of memory blocks in a partition, `df -h` will tell us the space usage and availability in M (for megabytes) or G (for gigabytes).

As you can see on the first line, our storage partition has 59 gigabytes available, so we have quite a bit of space to work with. Keep in mind that this is on a fresh, medium-sized VPS instance, so your actual usage might be very different.

Although there are many opinions about the appropriate size of a swap space, it really depends on your application requirements and your personal preferences. Generally, an amount equal to or double the amount of memory on your system is a good starting point.

Since my system has 4 gigabytes of memory, and doubling that would take a larger chunk from my storage space than I am willing to part with, I will create a swap space of 4 gigabytes to match my system’s memory.

## Create a Swap File

Now that we know our available storage space, we can go about creating a swap file within our filesystem. We will create a file called `swapfile` in our root (`/`) directory, though you can name the file something else if you prefer. The file must allocate the amount of space that we want for our swap file.

The fastest and easiest way to create a swap file is by using `fallocate`. This command creates a file of a preallocated size instantly. We can create a 4 gigabyte file by typing:

    sudo fallocate -l 4G /swapfile

After entering your password to authorize `sudo` privileges, the swap file will be created almost instantly, and the prompt will be returned to you. We can verify that the correct amount of space was reserved for swap by using `ls`:

    ls -lh /swapfile

    -rw-r--r-- 1 root root 4.0G Oct 30 11:00 /swapfile

As you can see, our swap file was created with the correct amount of space set aside.

## Enable a Swap File

Right now, our file is created, but our system does not know that this is supposed to be used for swap. We need to tell our system to format this file as swap and then enable it.

Before we do that, we should adjust the permissions on our swap file so that it isn’t readable by anyone besides the root account. Allowing other users to read or write to this file would be a huge security risk. We can lock down the permissions with `chmod`:

    sudo chmod 600 /swapfile

This will restrict both read and write permissions to the root account only. We can verify that the swap file has the correct permissions by using `ls -lh` again:

    ls -lh /swapfile

    -rw------- 1 root root 4.0G Oct 30 11:00 /swapfile

Now that our swap file is more secure, we can tell our system to set up the swap space for use by typing:

    sudo mkswap /swapfile

    Setting up swapspace version 1, size = 4194300 KiB
    no label, UUID=b99230bb-21af-47bc-8c37-de41129c39bf

Our swap file is now ready to be used as a swap space. We can begin using it by typing:

    sudo swapon /swapfile

To verify that the procedure was successful, we can check whether our system reports swap space now:

    swapon -s

    Filename Type Size Used Priority
    /swapfile file 4194300 0 -1

This output confirms that we have a new swap file. We can use the `free` utility again to corroborate our findings:

    free -m

                 total used free shared buffers cached
    Mem: 3953 315 3637 8 11 107
    -/+ buffers/cache: 196 3756
    Swap: 4095 0 4095

Our swap has been set up successfully, and our operating system will begin to use it as needed.

## Make the Swap File Permanent

Our swap file is enabled at the moment, but when we reboot, the server will not automatically enable the file for use. We can change that by modifying the `fstab` file, which is a table that manages filesystems and partitions.

Edit the file with `sudo` privileges in your text editor:

    sudo nano /etc/fstab

At the bottom of the file, you need to add a line that will tell the operating system to automatically use the swap file that you created:

    /swapfile swap swap sw 0 0

When you are finished adding the line, you can save and close the file. The server will check this file on each bootup, so the swap file will be ready for use from now on.

## Tweak Your Swap Settings (Optional)

There are a few options that you can configure that will have an impact on your system’s performance when dealing with swap. These configurations are optional in most cases, and the changes that you make will depend on your application needs and your personal preference.

### Swappiness

The `swappiness` parameter determines how often your system swaps data out of memory to the swap space. This is a value between 0 and 100 that represents the percentage of memory usage that will trigger the use of swap.

With values close to zero, the system will not swap data to the drive unless absolutely necessary. Remember, interactions with the swap file are “expensive” in that they are a lot slower than interactions with memory, and this difference in read and write speed can cause a significant reduction in an application’s performance. Telling the system not to rely on the swap as much will generally make your system faster.

Values that are closer to 100 will try to put more data into swap in an effort to keep more memory free. Depending on your applications’ memory profile, or what you are using your server for, this might be the better choice in some cases.

We can see the current swappiness value by reading the `swappiness` configuration file:

    cat /proc/sys/vm/swappiness

    30

CentOS 7 defaults to a swappiness setting of 30, which is a fair middle ground for most desktops and local servers. For a VPS system, we’d probably want to move it closer to 0.

We can set the swappiness to a different value by using the `sysctl` command. For instance, to set the swappiness to 10, we could type:

    sudo sysctl vm.swappiness=10

    vm.swappiness = 10

This setting will persist until the next reboot. To make the setting persist between reboots, we can add the outputted line to our `sysctl` configuration file:

    sudo nano /etc/sysctl.conf

Add your swappiness setting to the bottom of the file:

    vm.swappiness = 10

When you are finished adding the line, you can save and close the file. The server will now automatically set the swappiness to the value you declared on each bootup.

### Cache Pressure

Another related value that you might want to modify is the `vfs_cache_pressure`. This setting affects the storage of special filesystem metadata entries. Constantly reading and refreshing this information is generally very costly, so storing it on the cache for longer is excellent for your system’s performance.

You can see the current value of this cache pressure by querying the `proc` filesystem again:

    cat /proc/sys/vm/vfs_cache_pressure

    100

As it is currently configured, our system removes inode information from the cache far too quickly. We can set this to a more conservative setting, like 50, by using `sysctl`:

    sudo sysctl vm.vfs_cache_pressure=50

    vm.vfs_cache_pressure = 50

Again, this is only valid for our current session. We can change that by adding it to our configuration file, like we did with our swappiness setting:

    sudo nano /etc/sysctl.conf

At the bottom, add the line that specifies your new value:

    vm.vfs_cache_pressure = 50

When you are finished adding the line, you can save and close the file. The server will now automatically set the cache pressure to the value you declared on each bootup.

## Conclusion

By following the steps in this guide, you will have given your server some breathing room in terms of memory usage. Swap space is incredibly useful in avoiding some common problems.

If you are running into OOM (out of memory) errors, or if you find that your system is unable to use the applications that you need, the best solution is to optimize your application configurations or upgrade your server. However, configuring swap space can give you more flexibility and can help buy you time on a less powerful server.
