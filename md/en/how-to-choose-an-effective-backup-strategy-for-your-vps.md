---
author: Justin Ellingwood
date: 2013-11-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-choose-an-effective-backup-strategy-for-your-vps
---

# How To Choose an Effective Backup Strategy for your VPS

## Introduction

* * *

An important consideration when storing your work and data in a digital environment is how to ensure that your information will be available in the event of a problem. This can mean many different things depending on what applications you are using, how important it is to have immediate failover, and what kind of problems you are anticipating.

In this guide, we will discuss some of the different approaches for providing backups and data redundancy. Because different use cases demand different solutions, we won’t be able to give you a one-size-fits-all answer, but you will learn what is important in different scenarios and what implementation (or implementations) are best suited for your operation.

In the first part of this guide, we will discuss different backup solutions that you can use. We will discuss the relative merits of each so that you can choose the plan that fits your environment. In part two, we will discuss redundancy options.

## What Is the Difference Between Redundancy and Backing Up?

* * *

The definitions of the terms **redundant** and **backup** are often overlapping and, in many cases, confused. These are two distinct concepts that are related, but different. Some solutions provide both.

### Redundancy

* * *

Redundancy in data means that there is immediate _failover_ in the event of a system problem. A failover means that if one set of data becomes unavailable, another perfect copy is immediately swapped into production to take its place. This results in almost no perceivable down time and the application or website can continue serving requests as if nothing happened. In the meantime, the system administrator (in this case, you) have the opportunity to fix the problem and return the system to a fully operational state.

While this may seem like it would also serve as a great backup solution, this is a dangerous fallacy. Redundancy does not provide protection against a failure that affects the entire machine or system. For instance, if you have a mirrored RAID configured (such as RAID 1), your data is redundant in that if one drive fails, the other will still be available. However, if the machine itself fails, all of your data could be lost.

Another disadvantage of this type of a setup is that every operation is done on all copies of the data. This includes malicious or accidental operations. A true backup solution would allow you to restore from a previous point where the data is known to be good.

### Backup

* * *

As we have already mentioned, it is imperative that you maintain functional backups for your important data. Depending on your situation, this could mean backing up application or user data, or an entire website or machine. The idea behind backups is that in the event of a system, machine, or data loss, you can restore, redeploy, or otherwise access your data. Restoring from a backup may require downtime, but it can mean the difference between starting from a point a day ago and starting from scratch. Anything that you cannot afford to lose should, by definition, be backed up.

In terms of methods, there are quite a few different levels of backups. These can be layered as necessary to account for different kinds of problems. For instance, you may back up a configuration file prior to modifying it so that you can easily revert to your old settings should a problem arise. This is ideal for small changes that you are actively monitoring. However, this setup would fail miserably in the case of a disk failure or anything more complex. You should also have regular, automated backups to a remote location.

Backups by themselves do not provide automatic failover. This means that you failures may not cost you any data (assuming your backups are 100% up-to-date), but they may cost you uptime. This is one reason why redundancy and backups are most often used in tandem, instead of precluding each other.

## File-Level Backup

* * *

One of the most familiar forms of backing up is a file-level backup. This type of backup uses normal filesystem level copying tools to transfer files to another location or device.

### How To Use the cp Command

* * *

The simplest form of backing up a Linux machine, like your VPS, is with the `cp` command. This simply copies files from one local location to another. On a local computer, you could mount a removable drive, and then copy files to it:

    mount /dev/sdc /mnt/my-backupcp -a /etc/\* /mnt/my-backupumount /dev/sdc

This example mounts a removable disk and then copies the `/etc` directory to the disk. It then unmounts the drive, which can be stored somewhere else.

### How to Use Rsync

* * *

A better alternative to `cp` is the `rsync` command, which can be used to perform local backups with greater flexibility. We can perform the same operation as above using rsync with these commands:

    mount /dev/sdc /mnt/my-backuprsync -azvP /etc/\* /mnt/my-backupumount /dev/sdc

While this is simple and to the point, you will quickly realize that backups on the local filesystem are cumbersome and problematic. You must physically attach and detach the backup drive and transport it elsewhere if you are to preserve the data in the event of theft or fire. You can achieve many of the same advantages by using networked backups.

Rsync can perform remote backups just as easily as it can complete local backups. You just need to use an alternative syntax. This will work on any host that you can SSH into, as long as rsync is installed at both ends:

    rsync -azvP /etc/\* username@remote\_host:/backup/

This will backup the local machine’s `/etc` directory to a directory on `remote_host` located at `/backup`. This will succeed if you have permission to write to this directory and there is available space.

For more information about [how to use rsync to backup](https://www.digitalocean.com/community/articles/how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps), click here.

### How to Use Other Backup Tools

* * *

Although `cp` and `rsync` are simple and can be used easily, they’re not always the ideal solution. To automate backups, you would need to script those utilities and write any code necessary for rotation and other niceties.

Luckily, there are some utilities that perform more complex backup procedures easily.

**Bacula**

Bacula is a complex, flexible solution that leverages the client server model to backup hosts. Bacula separates the ideas of clients, backup locations, and directors (the component that orchestrates the actual backup). It also configures each backup task into a unit called a “job”.

This allows for extremely granular and flexible configuration. You can backup multiple clients to one storage device, one client to multiple storage devices, and modify the backup scheme quickly and easily by adding nodes or adjusting their details. It functions well over a networked environment and is expandable and modular, making it great for backing up a site or application spread across multiple machines.

To learn more about [how to configure a Bacula backup server](https://www.digitalocean.com/community/articles/installing-and-configuring-bacula-on-an-ubuntu-12-04-vps) and [how to back up remote systems with Bacula](https://www.digitalocean.com/community/articles/how-to-configure-remote-backups-using-bacula-in-an-ubuntu-12-04-vps), visit these links.

**BackupPC**

Another popular solution is BackupPC. BackupPC can be used to back up Linux and Windows systems easily. It is installed onto a machine or VPS that will act as the backup server. This server then “pulls” the data from its clients using regular file transfer methods.

This setup offers the advantage of installing all of the relevant packages on one centralized machine. The only necessity client-side configuration is to allow the backup server SSH access. This can be easily configured, and with DigitalOcean, you can [embed the BackupPC server’s SSH Keys into the clients as you deploy](https://www.digitalocean.com/community/articles/how-to-use-ssh-keys-with-digitalocean-droplets). This would allow you to configure the backups from the backup server easily and deploy your production environments cleanly, without additional software.

To learn [how to install and use BackupPC on a server](https://www.digitalocean.com/community/articles/how-to-use-backuppc-to-create-a-backup-server-on-an-ubuntu-12-04-vps), click here.

**Duplicity**

Duplicity is another great alternative to traditional tools. Duplicity’s main claim of differentiation is that it uses GPG encryption to transfer and store the data. This has some remarkable advantages.

The obvious benefit of using GPG encryption for file backups is that the data is not stored in plain text. Only the owner of the GPG key can decrypt the data. This provides some level of security to offset the ballooning of security measures needed when your data is stored in multiple locations.

The other benefit that may not be immediately apparent to those who do not use GPG regularly is that each transaction is verified to be completely accurate. GPG enforces strict hash checking to ensure that there was no data loss during the transfer. This means that when the time comes to restore data from a backup, you will be significantly less likely to run into problems of file corruption.

To learn [how to enable GPG encrypted backups with Duplicity](https://www.digitalocean.com/community/articles/how-to-use-duplicity-with-gpg-to-securely-automate-backups-on-ubuntu), follow this link.

## Block-Level Backups

* * *

A slightly less common, but important alternative to file-level backups are block-level backups. This style of backup is also known as “imaging” because it can be used to duplicate and restore entire devices. Block-level backups allow you to copy on a deeper level than a file. While a file-based backup might copy file1, file2, and file3 to a backup location, a block-based backup system would copy the entire “block” that those files reside on. Another way of explaining the same concept is to say that block-level backups copy information bit after bit. They do not care about the abstract files that may be represented by those bytes (but the files _will_ be transfered intact through the process).

One advantage of the block-level backups is that they are typically faster. While file-based backups usually initiate a new transfer for each separate file, a block-based backup will transfer blocks, which are typically larger, meaning that fewer transfers need to be initiated to complete the copying.

### Using dd to Perform Block-Level Backups

* * *

The simplest way of performing block-level backups is probably with the `dd` utility. This piece of software is very flexible, but it allows us to copy information bit-by-bit to a new location. This means that we can backup a partition or disk to a single file or a raw device without any preliminary steps.

The most basic way to backup a partition or disk is to use dd like this:

    dd if=/path/of/original/device of=/path/to/place/backup

In this scenario, the `if=` specifies the **input** device or location. The `of=` indicates the **output** file or location. It is very important to remember this distinction, because it is trivial to wipe a full disk if these are reversed.

If you would like to back up the partition that contains your documents, which is located at `/dev/sda3`, you can create an image file like this:

    dd if=/dev/sda3 of=~/documents.img

There are several other block-level backup solutions available for Linux machines, but we will not discuss them here.

## Versioning Backups

* * *

One of the main reasons for backing up data is to be able to restore a previous version of a file or groups of file in the event of an unwanted change or deletion. While all of the backup mechanisms mentioned so far provide this to an extent, you can implement a more robust system using some additional tools.

The manual way of accomplishing this is to create a backup file prior to editing, like this:

    cp file1 file1.bak
    nano file1

You could even automate this process by creating timestamped hidden files every time you modify a file with your editor. For instance, you could place this in your `~/.bashrc` file:

    nano() { cp $1 .${1}.`date +%y-%m-%d_%H.%M.%S`.bak; /usr/bin/nano $1; }

Now when you call the “nano” command, it will automatically create backups.

This will provide some level of backup, but is very fragile and can quickly fill up a disk if you are editing files often. It is not a great solution and may end up being much worse than manually copying files you are going to edit.

An alternative that solves many of the problems inherent in this design is to use `git`, which is specifically a version control system. Although it may not be obvious, you can use git to control almost any kind of file.

You can create a git repository in your home directory instantly, simply by typing this:

    cd ~
    git init

You probably need to tweak the setup here to exclude certain files, but in general, it creates complex versioning instantly. You can then add the contents of your directory and commit the files with this:

    git add .
    git commit -m "Initializing home directory"

You can easily push to a remote location using git’s built in system as well:

    git remote add backup\_server git://backup\_server/path/to/projectgit push backup\_server master

This is not a great system for backing up on its own, but combined with another backup system, this type of version control can provide very fine-grained control of the changes you make.

To learn more about [how to use git](https://www.digitalocean.com/community/articles/how-to-use-git-effectively) and [how git can be used to version normal files](http://gitolite.com/articles/backup-and-sync-with-git.html), check out these links.

## VPS-Level Backups

* * *

While it is important to manage backups by yourself, DigitalOcean also provides some mechanisms to supplement your own backups.

We have a backup function, which regularly performs automated backups for droplets that have enabled this service. You can turn this on during droplet creation by checking the “Backups” check box:

![DigitalOcean backups](https://assets.digitalocean.com/site/ControlPanel/cp_create_settings.png)

This will backup your entire VPS image. This means that you can easily redeploy from the backup, or use it as a base for new droplets.

For one-off imaging of your system, you can also create snapshots. These work in a similar way to backups, but are not automated. Although it’s possible to take a snapshot of a running system, it’s usually a good idea to power down to ensure that the filesystem is in a consistent state. Beginning in October 2016, snapshots cost $0.05 per gigabyte per month, based on the amount of utilized space within the filesystem. You can create them by going to your droplet and selecting “Snapshots” from the left menu:

![DigitalOcean snapshots](https://assets.digitalocean.com/site/ControlPanel/Take_a_Snapshot.png)

To learn more about [DigitalOcean backups and snapshots](https://www.digitalocean.com/community/articles/digitalocean-backups-and-snapshots-explained), click here.

## Continuing

* * *

In this article, we mainly discussed different backup concepts and solutions. In [part 2](how-to-choose-a-redundancy-plan-to-ensure-high-availability), we will go over some options to enable redundancy.

By Justin Ellingwood
