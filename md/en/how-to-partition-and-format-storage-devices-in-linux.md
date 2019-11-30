---
author: Justin Ellingwood
date: 2016-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
---

# How To Partition and Format Storage Devices in Linux

## Introduction

Preparing a new disk for use on a Linux system can be quick and easy. There are many tools, filesystem formats, and partitioning schemes that may complicate the process if you have specialized needs, but if you want to get up and running quickly, it’s fairly straightforward.

This guide will cover the following process:

- Identifying the new disk on the system.
- Creating a single partition that spans the entire drive (most operating systems expect a partition layout, even if only one filesystem is present)
- Formatting the partition with the Ext4 filesystem (the default in most modern Linux distributions)
- Mounting and setting up Auto-mounting of the filesystem at boot

## Install the Tools

To partition the drive, we’ll use the `parted` utility. In most cases, this will already be installed on the server.

If you are on an Ubuntu or Debian server and do not have `parted` yet, you can install it by typing:

    sudo apt-get update
    sudo apt-get install parted

If you are on a CentOS or Fedora server, you can install it by typing:

    sudo yum install parted

## Identify the New Disk on the System

Before we set up the drive, we need to be able to properly identify it on the server.

If this is a completely new drive, the easiest way to find it on your server may be to look for the absence of a partitioning scheme. If we ask `parted` to list the partition layout of our disks, it will give us an error for any disks that don’t have a valid partition scheme. This can be used to help us identify the new disk:

    sudo parted -l | grep Error

You should see an `unrecognized disk label` error for the new, unpartitioned disk:

    OutputError: /dev/sda: unrecognised disk label

You can also use the `lsblk` command and look for a disk of the correct size that has no associated partitions:

    lsblk

    OutputNAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    sda 8:0 0 100G 0 disk 
    vda 253:0 0 20G 0 disk 
    └─vda1 253:1 0 20G 0 part /

Warning

Remember to check `lsblk` in every session before making changes. The `/dev/sd*` and `/dev/hd*` disk identifiers will not necessarily be consistent between boots, which means there is some danger of partitioning or formatting the wrong disk if you do not verify the disk identifier correctly.

Consider using more persistent disk identifiers like `/dev/disk/by-uuid`, `/dev/disk/by-label`, or `/dev/disk/by-id`. See our [introduction to storage concepts and terminology in Linux](an-introduction-to-storage-terminology-in-linux) article for more information.

When you know the name the kernel has assigned your disk, you can partition your drive.

## Partition the New Drive

As mentioned in the introduction, we’ll create a single partition spanning the entire disk in this guide.

### Choose a Partitioning Standard

To do this, we first need to specify the partitioning standard we wish to use. GPT is the more modern partitioning standard, while the MBR standard offers wider support among operating systems. If you do not have any special requirements, it is probably better to use GPT at this point.

To choose the **GPT** standard, pass in the disk you identified like this:

    sudo parted /dev/sda mklabel gpt

If you wish to use the **MBR** format, type this instead:

    sudo parted /dev/sda mklabel msdos

### Create the New Partition

Once the format is selected, you can create a partition spanning the entire drive by typing:

    sudo parted -a opt /dev/sda mkpart primary ext4 0% 100%

If we check `lsblk`, we should see the new partition available:

    lsblk

    OutputNAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    sda 8:0 0 100G 0 disk 
    └─sda1 8:1 0 100G 0 part 
    vda 253:0 0 20G 0 disk 
    └─vda1 253:1 0 20G 0 part /

## Create a Filesystem on the New Partition

Now that we have a partition available, we can format it as an Ext4 filesystem. To do this, pass the partition to the `mkfs.ext4` utility.

We can add a partition label by passing the `-L` flag. Select a name that will help you identify this particular drive:

note
Make sure you pass in the **partition** and not the entire **disk**. In Linux, disks have names like `sda`, `sdb`, `hda`, etc. The partitions on these disks have a number appended to the end. So we would want to use something like `sda1` and **not** `sda`.  

    sudo mkfs.ext4 -L datapartition /dev/sda1

If you want to change the partition label at a later date, you can use the `e2label` command:

    sudo e2label /dev/sda1 newlabel

You can see all of the different ways to identify your partition with `lsblk`. We want to find the name, label, and UUID of the partition.

Some versions of `lsblk` will print all of this information if we type:

    sudo lsblk --fs

If your version does not show all of the appropriate fields, you can request them manually:

    sudo lsblk -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT

You should see something like this. The highlighted output indicate different methods you can use to refer to the new filesystem:

    OutputNAME FSTYPE LABEL UUID MOUNTPOINT
    sda                                                              
    └─sda1 ext4 datapartition 4b313333-a7b5-48c1-a957-d77d637e4fda 
    vda                                                              
    └─vda1 ext4 DOROOT 050e1e34-39e6-4072-a03e-ae0bf90ba13a /

## Mount the New Filesystem

Now, we can mount the filesystem for use.

The [Filesystem Hierarchy Standard](http://refspecs.linuxfoundation.org/fhs.shtml) recommends using `/mnt` or a subdirectory under it for temporarily mounted filesystems. It makes no recommendations on where to mount more permanent storage, so you can choose whichever scheme you’d like. For this tutorial, we’ll mount the drive under `/mnt/data`.

Create the directory by typing:

    sudo mkdir -p /mnt/data

### Mounting the Filesystem Temporarily

You can mount the filesystem temporarily by typing:

    sudo mount -o defaults /dev/sda1 /mnt/data

### Mounting the Filesystem Automatically at Boot

If you wish to mount the filesystem automatically each time the server boots, adjust the `/etc/fstab` file:

    sudo nano /etc/fstab

Earlier, we issued a `sudo lsblk --fs` command to display three filesystem identifiers for our filesystem. We can use any of these in this file. We’ve used the partition _label_ below, but you can see what the lines would look like using the other two identifiers in the commented out lines:

/etc/fstab

    . . .
    ## Use one of the identifiers you found to reference the correct partition
    # /dev/sda1 /mnt/data ext4 defaults 0 2
    # UUID=4b313333-a7b5-48c1-a957-d77d637e4fda /mnt/data ext4 defaults 0 2
    LABEL=datapartition /mnt/data ext4 defaults 0 2

Note

You can learn about the various fields in the `/etc/fstab` file by typing `man fstab`. For information about the mount options available for a specific filesystem type, check `man [filesystem]` (like `man ext4`). For now, the mount lines above should get you started.

For SSDs, the `discard` option is sometimes appended to enable continuous TRIM. There is debate over the performance and integrity impacts of performing continuous TRIM in this manner, and most distributions include method of performing periodic TRIM as an alternative.

Save and close the file when you are finished.

If you did not mount the filesystem previously, you can now mount it by typing:

    sudo mount -a

### Testing the Mount

After we’ve mounted the volume, we should check to make sure that the filesystem is accessible.

We can check if the the disk is available in the output from the `df` command:

    df -h -x tmpfs -x devtmpfs

    OutputFilesystem Size Used Avail Use% Mounted on
    /dev/vda1 20G 1.3G 18G 7% /
    /dev/sda1 99G 60M 94G 1% /mnt/data

You should also be able to see a `lost+found` directory within the `/mnt/data` directory, which typically indicates the root of an Ext\* filesystem:

    ls -l /mnt/data

    Outputtotal 16
    drwx------ 2 root root 16384 Jun 6 11:10 lost+found

We can also check that the file mounted with read and write capabilities by writing to a test file:

    echo "success" | sudo tee /mnt/data/test_file

Read the file back just to make sure the write executed correctly:

    cat /mnt/data/test_file

    Outputsuccess

You can remove the file after you have verified that the new filesystem is functioning correctly:

    sudo rm /mnt/data/test_file

## Conclusion

Your new drive should now be partitioned, formatted, mounted, and ready for use. This is the general process you can use turn a raw disk into a filesystem that Linux can use for storage. There are more complex methods of partitioning, formatting, and mounting which may be more appropriate in some cases, but the above is a good starting point for general use.
