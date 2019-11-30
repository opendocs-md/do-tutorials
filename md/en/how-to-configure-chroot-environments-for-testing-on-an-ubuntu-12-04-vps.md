---
author: Justin Ellingwood
date: 2014-03-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-chroot-environments-for-testing-on-an-ubuntu-12-04-vps
---

# How To Configure Chroot Environments for Testing on an Ubuntu 12.04 VPS

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

## Introduction

There are many instances when you may wish to isolate certain applications, user, or environments within a Linux system. Different operating systems have different methods of achieving isolation, and in Linux, a classic way is through a `chroot` environment.

In this guide, we’ll discuss how to setup an isolated environment using chroot in order to create a barrier between your regular operating system and a contained environment. This is mainly useful for testing purposes. We will discuss when you may wish to utilize this technology, and when it may be a better idea to use another solution. We will discuss these steps on an Ubuntu 12.04 x86\_64 VPS instance.

Most system administrators will benefit from knowing how to accomplish a quick and easy chroot environment and it is a valuable skill to have.

## What is a Chroot Environment?

A chroot environment is an operating system call that will change the root location temporarily to a new folder. Typically, the operating system’s conception of the root directory is the actual root located at “`/`”. However, with `chroot`, you can specify another directory to serve as the top-level directory for the duration of a chroot.

Any applications that are run from within the `chroot` will be unable to see the rest of the operating system in principle. Similarly, a non-root user who is confined to a chroot environment will not be able to move further up the directory hierarchy.

### When to Use a Chroot Environment

This is useful in a variety of situations. For instance, it allows you to build, install, and test software in an environment that is separated from your normal operating system. It could also be used as a method of running 32-bit applications in a 64-bit environment.

Generally, you should think of a `chroot` as a way to temporarily recreate an operating system environment from a subset of your filesystem. This can mean switching out your normal utilities for experimental versions, it can allow you to see how applications behave in an uncontaminated environment, and it can help you with recovery operations, bootstrapping a system, or creating an extra barrier to break out of for a would-be attacker.

### When Not to Use a Chroot Environment

Linux chroot environments should not be used as a security feature alone. While they can be used as a barrier, they are not isolated enough to act as a legitimate guard to keep an attacker out of the larger system. This is due to the way that a chroot is executed and the way that processes and people can break out of the environment.

While chroot environments will certainly make additional work for an unprivileged user, they should be considered a hardening feature instead of a security feature, meaning that they attempt to reduce the number of attack vectors instead of creating a full solution. If you need full isolation, consider a more complete solution, such as Linux containers, Docker, vservers, etc.

## Setting Up the Tools

In order to get the most from our chroot environments, we will be using some tools that will help install some of the basic distribution files into our new environment. This makes the process quicker and helps ensure that we have the libraries and basic foundational packages available.

One tool, called `dchroot` or `schroot`, is used to manage different chroot environments. This can be used to easily execute commands within a chroot environment. The `dchroot` command is a legacy command and at this point is actually implemented as a compatibility wrapper for `schroot`, the more modern variant on most systems.

The other tool is called `debootstrap`, which will create a base operating system within a subdirectory of another system. This allows us to quickly get off the ground and running since a chroot environment requires certain tools and libraries within the environment in order to function properly.

Let’s install these two packages now. We will install `dchroot`, because it will actually pull in `schroot` and will give us the flexibility of using either:

    sudo apt-get update
    sudo apt-get install dchroot debootstrap

Now that we have the appropriate tools, we just need to specify a directory that we want to use as our environment root. We will create a directory called `test` in our root directory:

    sudo mkdir /test

As we stated before, the `dchroot` command in modern systems is actually implemented as a wrapper around the more capable `schroot` command. For this reason, we will modify the `schroot` configuration file with our information.

Let’s open the file now with administrative privileges:

    sudo nano /etc/schroot/schroot.conf

Inside, we need to create configuration options that will match the system we wish to create. For an Ubuntu system, we will want to specify the version, etc. There are well-commented values for Debian systems (`schroot` comes originally from Debian), which should give you a good idea.

We are on an Ubuntu 12.04 system currently, but let’s say that we want to test out some packages available on Ubuntu 13.10, code named “Saucy Salamander”. We can do that by creating an entry that looks like this:

    [saucy]
    description=Ubuntu Saucy
    location=/test
    priority=3
    users=demouser
    groups=sbuild
    root-groups=root

Save and close the file.

## Populating the Chroot Environment with a Skeleton Operating System

Now, all we need to do to install a system under our chroot target is type:

    sudo debootstrap --variant=buildd --arch amd64 saucy /test/ http://mirror.cc.columbia.edu/pub/linux/ubuntu/archive/

In the above command, the `--variant` flag specifies the type of chroot you want to build. The `buildd` option specifies that it should also install build tools contained within the `build-essential` package in order to allow it to be used out of the box for software creation. You can find out more options by typing:

    man debootstrap

Search for the `--variant` explanation.

The `--arch` specifies the architecture of the client system. If the architecture is different from the parent architecture, you should also pass the `--foreign` flag! Afterwards, you’ll need to call the `debootstrap` command a second time to complete the installation, using something like:

    sudo chroot /test /debootstrap/debootstrap --second-stage

This will do the actual installation, while the first command only downloads the packages when there are architecture differences. Do not forget the `--foreign` flag for the initial `debootstrap` if the architectures do not match.

The `saucy` in the command should match the heading you selected for your configuration in the `schroot.conf` file. The `/test/` specifies the target, and the URL is the url of repository that contains the files you want. These are generally the same format that you would find in your `/etc/apt/sources.list` file.

After this is complete, you can see all of the files that have been downloaded and installed by checking out the target directory:

    ls /test

* * *

    bin dev home lib64 mnt proc run srv tmp var
    boot etc lib media opt root sbin sys usr

As you can see, this looks just like a regular filesystem. It has just been created in an unconventional directory.

## Final Configuration and Changing into the New Environment

After the system is installed, we’ll need to do some final configurations to make sure the system functions correctly.

First, we’ll want to make sure our host `fstab` is aware of some pseudo-systems in our guest. Add lines like these to the bottom of your fstab:

    sudo nano /etc/fstab

* * *

    proc /test/proc proc defaults 0 0
    sysfs /test/sys sysfs defaults 0 0

Save and close the file.

Now, we’re going to need to mount these filesystems within our guest:

    sudo mount proc /test/proc -t proc
    sudo mount sysfs /test/sys -t sysfs

We’ll also want to copy our `/etc/hosts` file so that we will have access to the correct network information:

    cp /etc/hosts /test/etc/hosts

Finally, we can enter the chroot environment through a command like this:

    sudo chroot /test/ /bin/bash

You will be taken into your new chroot environment. You can test this by moving to root directory and then typing:

    cd /
    ls -di

If you get back any number but `2`, you are in a chroot environment. From within this environment, you can install software, and do many things without affecting the host operating system (besides taking up resources).

## Exiting a Chroot

To exit a chroot environment, you simply need to reverse some of the steps that you configured earlier.

First off, you exit the chroot environment as root just like you’d exit any other shell environment:

    exit

Afterwards, we need to unmount our proc and sys filesystems:

    sudo umount /test/proc
    sudo umount /test/sys

You can also delete the additional lines from your `/etc/fstab` file if you do not plan to use this again regularly.

If you are completely done with this environment, feel free to delete the directory where everything is stored with:

    rm -rf /test/

## Conclusion

While there are certainly other technologies like Docker that provide more complete isolation, these chroot environments are easy to create and manage and are available from within the host operating system, which is advantageous at times. It is a good tool to have and is extremely light-weight.

Keep in mind the situations where a chroot would be useful and try to avoid the circumstances when using a chroot is not appropriate. Chroot environments are great for testing and building software for different architectures without having an entirely separate system. Use them in the right situations and you will discover that they provide a flexible solution for a variety of problems.

By Justin Ellingwood
