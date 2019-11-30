---
author: Mitchell Anicas
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-freebsd-10-1
---

# How To Install Java on FreeBSD 10.1

## Introduction

Java is a popular software platform that allows you to run Java applications and applets.

This tutorial covers how to install the following Java releases on FreeBSD 10.1, using packages and ports:

- OpenJDK 7 JDK _(default)_
- OpenJDK 8 JRE / JDK
- OpenJDK 6 JRE / JDK

This guide does not cover the installation of Oracle Java because only the 32-bit version is supported on FreeBSD, through the Linux Binary Compatibility feature. Additionally, OpenJDK satisfies the Java needs of most users.

## Prerequisites

Before you begin this guide, you should have a FreeBSD 10.1 server. Also, you must connect to your FreeBSD server as a user with superuser privileges (i.e. is allowed to use `sudo` or change to the root user).

## Variations of Java

There are two different Java packages that can be installed: the Java Runtime Environment (JRE) and the Java Development Kit (JDK). JRE is an implementation of the Java Virtual Machine (JVM), which allows you to run compiled Java applications and applets. The JDK includes the JRE and other software that is required for writing, developing, and compiling Java applications and applets.

You may install various versions and releases of Java on a single system, but most people only need one installation. With that in mind, try to only install the version of Java that you need to run or develop your application(s).

## Install OpenJDK via Packages

Using packages is an easy way to install the various releases of OpenJDK on your FreeBSD system.

### List Available OpenJDK Packages

To see the list of OpenJDK releases available via packages, use this command:

    pkg search ^openjdk

You should see output that looks like this (possibly with different version numbers):

    openjdk-7.71.14_1,1
    openjdk6-b33,1
    openjdk6-jre-b33,1
    openjdk8-8.25.17_3
    openjdk8-jre-8.25.17_3

The package names are highlighted in red, and are followed by their versions. As you can see the following packages are available:

- `openjdk`: The default OpenJDK package, which happens to be OpenJDK 7 JDK
- `openjdk6`: The OpenJDK 6 JDK
- `openjdk6-jre`: The OpenJDK 6 JRE
- `openjdk8`: The OpenJDK 8 JDK
- `openjdk8-jre`: The OpenJDK 8 JRE

### How To Install an OpenJDK Package

After you decide which release of OpenJDK you want, let’s install it.

To install an OpenJDK package, use the `pkg install` command followed by the package you want to install. For example, to install OpenJDK 7 JDK, `openjdk`, run this command (substitute the highlighted package name with the one that you want to install):

    sudo pkg install openjdk

Enter `y` at the confirmation prompt.

This installs OpenJDK and the packages it depends on.

This OpenJDK implementation requires a few file systems to be mounted for full functionality. Run these commands to perform the required mounts immediately:

    sudo mount -t fdescfs fdesc /dev/fd
    sudo mount -t procfs proc /proc

To make this change permanent, we must add these mount points to the `/etc/fstab` file. Open the file to edit now:

    sudo vi /etc/fstab

Insert the following mount information into the file:

    fdesc /dev/fd fdescfs rw 0 0
    proc /proc procfs rw 0 0

Save and exit.

Lastly, you will want to rehash to be sure that you can use your new Java binaries immediately:

    rehash

The OpenJDK package that you selected is now installed and ready to be used!

## Install OpenJDK via Ports

Using ports is a flexible way to build and install the various releases of OpenJDK on your FreeBSD system. Installing Java this way allows you to customize your software build but it takes much longer than installing via packages.

### List Available OpenJDK Ports

To see the list of OpenJDK releases available via ports, use this command:

    cd /usr/ports/java && ls -d openjdk*

You should see output that looks like this:

    openjdk6 openjdk6-jre openjdk7 openjdk8 openjdk8-jre

The package names correspond with the release of Java that they provide. Note that the `-jre` suffix marks the JRE ports, while the lack of the suffix indicates the JDK ports.

### How To Install an OpenJDK Port

After you decide which release of OpenJDK you want, let’s install it.

To build and install an OpenJDK port, use the `portmaster java/` command followed by the port you want to install. For example, to install OpenJDK 7 JDK, `openjdk7`, run this command (substitute the highlighted port name with the one that you want to install):

    sudo portmaster java/openjdk7

You will see a series of prompts asking for the options and libraries that you wish to build your Java port and its dependencies with. You may accept the defaults or customize it to your needs.

After you answer all of the prompts, the OpenJDK port and its dependencies will be built and installed.

This OpenJDK implementation requires a few file systems to be mounted for full functionality. Run these commands to perform the required mounts immediately:

    sudo mount -t fdescfs fdesc /dev/fd
    sudo mount -t procfs proc /proc

To make this change permanent, we must add these mount points to the `/etc/fstab` file. Open the file to edit now:

    sudo vi /etc/fstab

Insert the following mount information into the file:

    fdesc /dev/fd fdescfs rw 0 0
    proc /proc procfs rw 0 0

Save and exit.

Lastly, you will want to rehash to be sure that you can use your new Java binaries immediately:

    rehash

The OpenJDK port that you selected is now installed and ready to be used!

## Conclusion

Congratulations! You are now able to run and develop your Java applications.

If you’re interested in learning more about installing additional software on your FreeBSD servers, check out these tutorials about Packages and Ports:

- [How To Manage Packages on FreeBSD 10.1 with Pkg](how-to-manage-packages-on-freebsd-10-1-with-pkg)
- [How To Install and Manage Ports on FreeBSD 10.1](how-to-install-and-manage-ports-on-freebsd-10-1)
