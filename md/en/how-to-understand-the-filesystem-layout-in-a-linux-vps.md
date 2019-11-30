---
author: Justin Ellingwood
date: 2013-12-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-understand-the-filesystem-layout-in-a-linux-vps
---

# How To Understand the Filesystem Layout in a Linux VPS

## Introduction

* * *

If you are new to Linux and Unix-like operating systems, the basic ways to interact with and navigate your operating system can seem convoluted and confusing. One area that new users struggle with is how to make sense of the way that the filesystem is structured.

In this article, we will discuss the various parts of the standard Linux filesystem. We will explore some of the most interesting directories and where to look for various components in your server environment.

For demonstration purposes, we will be using an Ubuntu 12.04 server. Other Linux distros implement things in slightly different ways, so if you are following along and notice a discrepancy with your own system, check your distro’s documentation.

## Some Brief Notes on the History of the Linux Filesystem Layout

* * *

Linux inherits many of its concepts of filesystem organization from its Unix predecessors. As far back as 1979, Unix was establishing standards to control how compliant systems would organize their files.

The Linux Filesystem Hierarchy Standard, or FHS for short, is a prescriptive standard maintained by the Linux Foundation that establishes the organizational layout that Linux distributions should uphold for interoperability, ease of administration, and the ability to implement cross-distro applications reliably.

One important thing to mention when dealing with these systems is that Linux implements just about everything as a file. This means that a text file is a file, a directory is a file (simply a list of other files), a printer is represented by a file (the device drivers can send anything written to the printer file to the physical printer), etc.

Although this is in some cases an oversimplification, it informs us of the approach that the designers of the system encouraged: passing text and bytes back and forth and being able to apply similar strategies for editing and accessing diverse components.

In this article, we will not follow the specification exactly, because distributions stray from the actual standard often. Instead, we will check an Ubuntu 12.04 server to find the actual directory structure that was implemented. This is much more useful for the average user.

## Simple Navigation

* * *

Before actually delving into the filesystem layout, you need to know a few basics about how to navigate a filesystem from the command line. We will cover the bare minimum here to get you on your feet.

### Orient Yourself

* * *

The first thing you need to do is orient yourself in the filesystem. There are a few ways to do this, but one of the most basic is with the `pwd` command, which stands for “print working directory”:

    pwd

* * *

    /root

This simply returns the directory you are currently located in. We will learn how to interpret the results in a bit.

### Look Around

* * *

To see what files are in the current directory, you can issue the `ls` command, which stands for “list”:

    ls

* * *

    bin etc lib mnt root selinux tmp vmlinuz
    boot home lost+found opt run srv usr
    dev initrd.img media proc sbin sys var

This will tell you all directories and files in your current directory.

The `ls` command can take some optional flags. Flags modify the commands default behavior to either process or display the data in a different way.

For instance, if we would like to easily differentiate between files and directories by showing a “/” after directory entries, you can add the `-F` flag:

    ls -F

* * *

    bin/ home/ media/ root/ srv/ var/
    boot/ initrd.img@ mnt/ run/ sys/ vmlinuz@
    dev/ lib/ opt/ sbin/ tmp/
    etc/ lost+found/ proc/ selinux/ usr/

The two most common flags are probable `-l` and `-a`. The first flag forces the command to output information in long-form:

    ls -l

* * *

    total 76
    drwxr-xr-x 2 root root 4096 Apr 26 2012 bin
    drwxr-xr-x 3 root root 4096 Apr 26 2012 boot
    drwxr-xr-x 13 root root 3900 Dec 4 18:03 dev
    drwxr-xr-x 78 root root 4096 Dec 4 19:29 etc
    drwxr-xr-x 3 root root 4096 Dec 4 19:28 home
    lrwxrwxrwx 1 root root 33 Apr 26 2012 initrd.img -> /boot/initrd.img-3.2.0-24-virtual
    drwxr-xr-x 16 root root 4096 Apr 26 2012 lib
    . . .

This produces output with one line for each file or directory (the name is on the far right). This has a lot of information that we are not interested in right now. One part we _are_ interested in though is the very first character, which tells us what kind of file it is. The three most common types are:

- **-** : Regular file
- **d** : Directory (a file of a specific format that lists other files)
- **l** : A hard or soft link (basically a shortcut to another file on the system)

The `-a` flag lists all files, including hidden files. In Linux, files are hidden automatically if they begin with a dot:

    ls -a

* * *

    . .. .bash_logout .bashrc .profile

In this example, all of the files are hidden. The first two entries, `.` and `..` are special. The `.` directory is a shortcut that means “the current directory”. The `..` directory is a shortcut that means “the current directory’s parent directory”. We will learn some ways to utilize these in just a moment.

### Move Around

* * *

Now that you can find out where you are in the filesystem and see what is around you, it is time to learn how to move throughout the filesystem.

To change to a different directory, you issue the `cd` command, which stands for “change directory”:

    cd /bin

You can follow the command with either an absolute or a relative pathname.

An **absolute path** is a file path that specifies the location of a directory from at the top of the directory tree (we will explain this later). Absolute paths begin with a “/”, as you see above.

A **relative path** is a file path that is relative to the current working directory. This means that instead of defining a location from the top of the directory structure, it defines the location in relation to where you currently are.

For instance, if you want to move to a directory within the current directory called `documents`, you can issue this command:

    cd documents

The lack of the “/” from the beginning tells to use the current directory as the base for looking for the path.

This is where the `..` directory comes in handy. To move to the parent directory of your current directory, you can type:

    cd ..

## An Overview of the Linux Filesystem Layout

* * *

The first thing you need to know when viewing a Linux filesystem is that the filesystem is contained within a single tree, regardless of how many devices are incorporated.

What this means is that all components accessible to the operating system are represented somewhere in the main filesystem. If you use Windows as your primary operating system, this is different from what you are used to. In Windows, each hard drive or storage space is represented as its own filesystem, which are labeled with letter designations (C: being the standard top-level directory of the system file hierarchy and additional drives or storage spaces being given other  
letter labels).

In Linux, every file and device on the system resides under the “root” directory, which is denoted by a starting “/”.

_Note: This is different from the default administrative user, which is also called “root”. It is also different from the default administrative user’s home directory, which is located at “/root”._

Thus, if we want to go to the top-level directory of the entire operating system and see what is there, we can type:

    cd /
    ls

* * *

    bin etc lib mnt root selinux tmp vmlinuz
    boot home lost+found opt run srv usr
    dev initrd.img media proc sbin sys var

Every file, device, directory, or application is located under this one directory. Under this, we can see the beginnings of the rest of the directory structure. We will go into more details below:

### /bin

* * *

This directory contains basic commands and programs that are needed to achieve a minimal working environment upon booting. These are kept separate from some of the other programs on the system to allow you to boot the system for maintenance even if other parts of the filesystem may be damaged or unavailable.

If you search this directory, you will find that both `ls` and `pwd` reside here. The `cd` command is actually built into the shell we are using (bash), which is in this directory too.

### /boot

* * *

This directory contains the actual files, images, and kernels necessary to boot the system. While `/bin` contains basic, essential utilities, `/boot` contains the core components that actually allow the system to boot.

If you need to modify the bootloader on your system, or if you would like to see the actual kernel files and initial ramdisk (initrd), you can find them here. This directory must be accessible to the system very early on.

### /dev

* * *

This directory houses the files that represent devices on your system. Every hard drive, terminal device, input or output device available to the system is represented by a file here. Depending on the device, you can operate on the devices in different ways.

For instance, for a device that represents a hard drive, like `/dev/sda`, you can mount it to the filesystem to access it. On the other hand, if you have a file that represents a line printer like `/dev/lpr`, you can write directly to it to send the information to the printer.

### /etc

* * *

This is one area of the filesystem where you will spend a lot of time if you are working as a system administrator. This directory is basically a configuration directory for various system-wide services.

By default, this directory contains many files and subdirectories. It contains the configuration files for most of the activities on the system, regardless of their function. In cases where multiple configuration files are needed, many times a application-specific subdirectory is created to hold these files. If you are attempting to configure a service or program for the entire system, this is a great place to look.

### /home

* * *

This location contains the home directories of all of the users on the system (except for the administrative user, root). If you have created other users, a directory matching their username will typically be created under this directory.

Inside each home directory, the associated user has write access. Typically, regular users only have write access to their own home directory. This helps keep the filesystem clean and ensures that not just anyone can change important configuration files.

Within the home directory, that are often hidden files and directories (represented by a starting dot) that allow for user-specific configuration of tools. You can often set system defaults in the `/etc` directory, and then each user can override them as necessary in their own home directory.

### /lib

* * *

This directory is used for all of the shared system libraries that are required by the `/bin` and `/sbin` directories. These files basically provide functionality to the other programs on the system. This is one of the directories that you will not have to access often.

### /lost+found

* * *

This is a special directory that contains files recovered by `/fsck`, the Linux filesystem repair program. If the filesystem is damaged and recovery is undertaken, sometimes files are found but the reference to their location is lost. In this case, the system will place them in this directory.

In most cases, this directory will remain empty. If you experience corruption or any similar problems and are forced to perform recovery operations, it’s always a good idea to check this location when you are finished.

### /media

* * *

This directory is typically empty at boot. Its real purpose is simply to provide a location to mount removable media (like cds). In a server environment, this won’t be used in most circumstances. But if your Linux operating system ever mounts a media disk and you are unsure of where it placed it, this is a safe bet.

### /mnt

* * *

This directory is similar to the `/media` directory in that it exists only to serve as a organization mount point for devices. In this case, this location is usually used to mount filesystems like external hard drives, etc.

This directory is often used in a VPS environment for mounting network accessible drives. If you have a filesystem on a remote system that you would like to mount on your server, this is a good place to do that.

### /opt

* * *

This directory’s usage is rather ambiguous. It is used by some distributions, but ignored by others. Typically, it is used to store optional packages. In the Linux distribution world, this usually means packages and applications that were not installed from the repositories.

For instance, if your distribution typically provides the packages through a package manager, but you installed program X from source, then this directory would be a good location for that software. Another popular option for software of this nature is in the `/usr/local` directory.

### /proc

* * *

The `/proc` directory is actually more than just a regular directory. It is actually a pseudo-filesystem of its own that is mounted to that directory. The proc filesystem does not contain real files, but is instead dynamically generated to reflect the internal state of the Linux kernel.

This means that we can check and modify different information from the kernel itself in real time. For instance, you can get detailed information about the memory usage by typing `cat /proc/meminfo`.

### /root

* * *

This is the home directory of the administrative user (called “root”). It functions exactly like the normal home directories, but is housed here instead.

### /run

* * *

This directory is for the operating system to write temporary runtime information during the early stages of the boot process. In general, you should not have to worry about much of the information in this directory.

### /sbin

* * *

This directory is much like the `/bin` directory in that it contains programs deemed essential for using the operating system. The distinction is usually that `/sbin` contains commands that are available to the system administrator, while the other directory contains programs for all of the users of the system.

### /selinux

* * *

This directory contains information involving security enhanced Linux. This is a kernel module that is used to provide access control to the operating system. For the most part, you can ignore this.

### /srv

* * *

This directory is used to contain data files for services provided by the computer. In most cases, this directory is not used too much because its functionality can be implemented elsewhere in the filesystem.

### /tmp

* * *

This is a directory that is used to store temporary files on the system. It is writable by anyone on the computer and does not persist upon reboot. This means that any files that you need just for a little bit can be put here. They will be automatically deleted once the system shuts down.

### /usr

* * *

This directory is one of the largest directories on the system. It basically includes a set of folders that look similar to those in the root `/` directory, such as `/usr/bin` and `/usr/lib`. This location is basically used to store all non-essential programs, their documentation, libraries, and other data that is not required for the most minimal usage of the system.

This is where most of the files on the system will be stored. Some important subdirectories are `/usr/local`, which is an alternative to the `/opt` directory for storing locally compiled programs. Another interesting thing to check out is the `/usr/share` directory, which contains documentation, configuration files, and other useful files.

### /var

* * *

This directory is supposed to contain variable data. In practice, this means it is used to contain information or directories that you expect to grow as the system is used.

For example, system logs and backups are housed here. Another popular use of this directory is to store web content if you are operating a web server.

## Conclusion

* * *

Although the details of where things are stored can vary from distro to distro, in general, the locations we discussed should direct you in the right direction.

The best way of exploring the filesystem is simply to traverse the various directories and try to find out what the files inside are for. You will begin to be able to associate different directories with different functions and be able to guess where to go for specific tasks. If you want a quick reference for what each directory is for, you can use the built-in manual pages by typing:

    man hier

This will give you an overview of a typical filesystem layout and the purposes of each location.

By Justin Ellingwood
