---
author: Justin Ellingwood
date: 2016-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-perform-basic-administration-tasks-for-storage-devices-in-linux
---

# How To Perform Basic Administration Tasks for Storage Devices in Linux

## Introduction

There are many tools available to manage storage in Linux. However, only a handful are used for day-to-day maintenance and administration. In this guide, we will cover some of the most commonly used utilities for managing mount points, storage devices, and filesystems.

## Other Resources

This guide will not cover how to prepare storage devices for their initial use on a Linux system. Our guide on [partitioning and formatting block devices in Linux](how-to-partition-and-format-storage-devices-in-linux) will help you prepare your raw storage device if you have not set up your storage yet.

For more information about some of the terminology used to discuss storage, take a look at our article on [storage terminology](an-introduction-to-storage-terminology-and-concepts-in-linux).

## Finding Storage Capacity and Usage with df

Often, the most important information you will want to find out about the storage on your system is the capacity and current utilization of the connected storage devices.

To check how much storage space is available in total and to see the current utilization of your drives, use the **df** utility. By default, this outputs the measurements in 1K blocks, which isn’t usually too useful. Add the `-h` flag to output in human-readable units:

    df -h

    OutputFilesystem Size Used Avail Use% Mounted on
    udev 238M 0 238M 0% /dev
    tmpfs 49M 624K 49M 2% /run
    /dev/vda1 20G 1.1G 18G 6% /
    tmpfs 245M 0 245M 0% /dev/shm
    tmpfs 5.0M 0 5.0M 0% /run/lock
    tmpfs 245M 0 245M 0% /sys/fs/cgroup
    tmpfs 49M 0 49M 0% /run/user/1000
    /dev/sda1 99G 60M 94G 1% /mnt/data

As you can see, the `/dev/vda1` partition, which is mounted at `/`, is 6% full and has 18G of available space, while the `/dev/sda1` partition, which is mounted at `/mnt/data` is empty and has 94G of available space. The other entries use `tmpfs` or `devtmpfs` filesystems, which is volatile memory used as if it were permanent storage. We can exclude these entries by typing:

    df -h -x tmpfs -x devtmpfs

    OutputFilesystem Size Used Avail Use% Mounted on
    /dev/vda1 20G 1.1G 18G 6% /
    /dev/sda1 99G 60M 94G 1% /mnt/data

This output offers a more focused display of current disk utilization by removing some pseudo- and special devices.

## Finding Information about Block Devices with lsblk

A **block device** is a generic term for a storage device that reads or writes in blocks of a specific size. This term applies to almost every type of non-volatile storage, including hard disk drives (HDDs), solid state drives (SSDs), flash memory, etc. The block device is the physical device where the filesystem is written. The filesystem, in turn, dictates how data and files are stored.

The **lsblk** utility can be used to display information about block devices easily. The specific capabilities of the utility depend on the version installed, but in general, the `lsblk` command can be used to display information about the drive itself, as well as the partitioning information and the filesystem that has been written to it.

Without any arguments, `lsblk` will show device names, the major and minor numbers (used by the Linux kernel to keep track of drivers and devices), whether the drive is removable, its size, whether it is mounted read-only, its type (disk or partition), and its mount point. Some systems require `sudo` for this to display correctly, so we will use that below:

    sudo lsblk

    OutputNAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    sda 8:0 0 100G 0 disk 
    vda 253:0 0 20G 0 disk 
    └─vda1 253:1 0 20G 0 part /

Of the output displayed, the most important parts will usually be the name, which refers to the device name under `/dev`, the size, the type, and the mountpoint. Here, we can see that we have one disk (`/dev/vda`) with a single partition (`/dev/vda1`) being used as the `/` partition and another disk (`/dev/sda`) that has not been partitioned.

To get information more relevant to disk and partition management, you can pass the `--fs` flag on some versions:

    sudo lsblk --fs

    OutputNAME FSTYPE LABEL UUID MOUNTPOINT
    sda                                                       
    vda                                                       
    └─vda1 ext4 DOROOT c154916c-06ea-4268-819d-c0e36750c1cd /

If the `--fs` flag is unavailable for your version, you can manually replicate the output by using the `-o` flag to request specific output. You can use `-o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT` to get this same information.

To get information about the disk topology, type:

    sudo lsblk -t

    OutputNAME ALIGNMENT MIN-IO OPT-IO PHY-SEC LOG-SEC ROTA SCHED RQ-SIZE RA WSAME
    sda 0 512 0 512 512 1 deadline 128 128 2G
    vda 0 512 0 512 512 1 128 128 0B
    └─vda1 0 512 0 512 512 1 128 128 0B

There are many other shortcuts available to display related traits about your disks and partitions. You can output all available columns with the `-O` flag or you can customize the fields to display by specifying the column names with the `-o` flag. The `-h` flag can be used to list the available columns:

    lsblk -h

    Output. . .
    
    Available columns (for --output):
            NAME device name
           KNAME internal kernel device name
    
           . . .
    
      SUBSYSTEMS de-duplicated chain of subsystems
             REV device revision
          VENDOR device vendor
    
    For more details see lsblk(8).
    

## Working with Filesystem Mounts

Before you can use a new disk, you typically have to partition it, format it with a filesystem, and then mount the drive or partitions. Partitioning and formatting are usually one time procedures, so we won’t discuss them here. As mentioned earlier, you can find out more information on how to partition and format a drive with Linux in [this article](how-to-partition-and-format-storage-devices-in-linux).

Mounting, on the other hand, is something you may manage more frequently. Mounting the filesystem makes it available to the server at the selected mount point. A **mount point** is simply a directory under which the new filesystem can be accessed.

Two complementary commands are primarily used to manage mounting: `mount` and `umount`. The `mount` command is used to attach a filesystem to the current file tree. In a Linux system, a single unified file hierarchy is used for the entire system, regardless of how many physical devices it is composed of. The `umount` command (Note: this is `umount`, not `unmount`) is used to unmount a filesystem. Additionally, the `findmnt` command is helpful for gathering information about the current state of mounted filesystems.

### Using the mount Command

The most basic way to use `mount` is to pass in a formatted device or partition and the mount point where it is to be attached:

    sudo mount /dev/sda1 /mnt

The mount point, the final parameter which specifies where in the file hierarchy the new filesystem should be attached, should almost always be an empty directory.

Usually, you will want to select more specific options when mounting. Although `mount` can attempt to guess the filesystem type, it’s almost always a better idea to pass in the filesystem type with the `-t` option. For an Ext4 filesystem, this would be:

    sudo mount -t ext4 /dev/sda1 /mnt

There are many other options that will impact the way that the filesystem is mounted. There are generic mount options, which can be found in the **FILESYSTEM INDEPENDENT MOUNT OPTIONS** section of `man mount`. Filesystems also typically have a section under the **FILESYSTEM SPECIFIC MOUNT OPTIONS** header in the same man page filesystem-dependent options.

Pass in other options with the `-o` flag. For instance, to mount a partition with the default options (which stands for `rw,suid,dev,exec,auto,nouser,async`), we can pass in `-o defaults`. If we want to override the read-write permissions and mount as read-only, we can add `ro` as a later option, which will override the `rw` from the `defaults` option:

    sudo mount -t ext4 -o defaults,ro /dev/sda1 /mnt

To mount all of the filesystems outlined in the `/etc/fstab` file, you can pass the `-a` option:

    sudo mount -a

### Listing Filesystem Mount Options

To display the mount options used for a specific mount, pass it to the `findmnt` command. For instance, if we viewed the read-only mount that we gave as an example above with `findmnt`, it would look something like this:

    findmnt /mnt

    OutputTARGET SOURCE FSTYPE OPTIONS
    /mnt /dev/sda1 ext4 ro,relatime,data=ordered

This can be incredibly useful if you have been experimenting with multiple options and have finally discovered a set that you like. You can find the options it is using with `findmnt` so that you know what is appropriate to add to the `/etc/fstab` file for future mounting.

### Unmounting a Filesystem

The `umount` command is used to unmount a given filesystem. Again, this is `umount` not `unmount`.

The general form of the command is simply to name the mount point or device of a currently mounted filesystem. Make sure that you are not using any files on the mount point and that you do not have any applications (including your current shell) operating inside of the mount point:

    cd ~
    sudo umount /mnt

For the vast majority of users, nothing beyond the default unmounting behavior will ever be necessary.

## Conclusion

While this list is in no way exhaustive, these utilities should cover most of what you need for daily system administration tasks. By learning a few tools, you can easily handle storage devices on your server.
