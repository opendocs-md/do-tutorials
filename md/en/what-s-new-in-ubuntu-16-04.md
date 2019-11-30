---
author: Brennen Bearnes
date: 2016-04-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/what-s-new-in-ubuntu-16-04
---

# What's New in Ubuntu 16.04

## Introduction

The Ubuntu operating system’s most recent Long Term Support version, version 16.04 (Xenial Xerus), was released on April 21, 2016.

This guide is intended as a brief overview of new features and significant changes to the system as a whole, since 14.04 LTS, from the perspective of server system administration. It draws on [the official Xenial Xerus release notes](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes), along with a variety of other sources.

## What is a Long Term Support Release?

While new Ubuntu Desktop and Server releases appear every six months, LTS versions are released every two years, and are guaranteed support from Canonical for five years after release. This means that they constitute a stable platform for deploying production systems, and receive security updates and critical bugfixes for a substantial window of time. 16.04 will continue to be updated until April of 2021.

You can read a [detailed breakdown of the Ubuntu LTS release cycle](https://wiki.ubuntu.com/LTS) on the Ubuntu Wiki.

## The systemd Init System

Users of Ubuntu 15.10 or Debian Jessie may already be familiar with systemd, which is now the default init system for the majority of mainstream GNU/Linux distributions. On Ubuntu, systemd supplants Canonical’s Upstart.

If you make use of custom init scripts, or routinely configure long-running services, you will need to know the basics of systemd. For an overview, read [Systemd Essentials: Working with Services, Units, and the Journal](systemd-essentials-working-with-services-units-and-the-journal).

## The Kernel

Ubuntu 16.04 is built on [the 4.4 series of Linux Kernels](http://kernelnewbies.org/Linux_4.4), released in January of 2016.

On DigitalOcean, new 16.04 Droplets and Droplets upgraded from 15.10 will be able to manage and upgrade their own kernels. This is not the case for Droplets upgraded from Ubuntu 14.04 LTS.

## SSH

Ubuntu 16.04 defaults to OpenSSH 7.2p2, which disables the SSH version 1 protocol, and disallows the use of DSA (ssh-dss) keys. If you are using an older key or are required to communicate with a legacy SSH server from your system, you should read the [release notes on SSH](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes#OpenSSH_7.2p2). Although relatively few DSA keys are still in use, there is some possibility that you may need to generate new keys before performing an upgrade or disabling password-based SSH authentication on a new Ubuntu 16.04 server.

For an overview of generating and using new SSH keys, see [How To Configure SSH Key-Based Authentication on a Linux Server](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

## Packaging, Software Distribution, and Containers

### Apt

At its core, Ubuntu is still built on the Debian project, and by extension on `.deb` package files managed by Apt, the Advanced Package Tool.

The Apt tools have not changed a great deal, although Ubuntu 16.04 upgrades to Apt 1.2, which includes some security improvements. Users migrating from older releases may also wish to consider use of the `apt` command in place of the traditional `apt-get` and `apt-cache` for many package management operations. More detail on the `apt` command can be found in [Package Management Basics: apt, yum, dnf, pkg](package-management-basics-apt-yum-dnf-pkg).

### Snap Packages

Although most users of Ubuntu in server environments will continue to rely on Apt for package management, 16.04 [includes access](https://insights.ubuntu.com/2016/04/13/snaps-for-classic-ubuntu/) to a new kind of package called a **snap** , emerging from Ubuntu’s mobile and Internet of Things development efforts. While snaps are unlikely to be a major factor for server deployments early in 16.04’s lifecycle, Canonical have repeatedly indicated that snaps represent the future of packaging for Ubuntu, so they’re likely to be a development worth following.

### LXD

LXD is a “container hypervisor”, built around LXC, which in turn is an interface to Linux kernel containment features. You can read [an introduction to LXC](https://linuxcontainers.org/lxc/introduction/) and a [getting-started guide to LXD](https://linuxcontainers.org/lxd/getting-started-cli/) on linuxcontainers.org.

## ZFS

Ubuntu 16.04 includes a native kernel module for ZFS, an advanced filesystem originating in the 2000s at Sun Microsystems and currently developed for Open Source systems under the umbrella of the [OpenZFS project](http://open-zfs.org/wiki/Main_Page). ZFS combines the traditional roles of a filesystem and volume manager, and offers many compelling features.

The decision to distribute ZFS has not been without controversy, drawing [criticism over licensing issues](https://sfconservancy.org/blog/2016/feb/25/zfs-and-linux/) from the Software Conservancy and the Free Software Foundation. Nevertheless, ZFS is a promising technology with a long development history—an especially significant consideration for filesystems, which usually require years of work before they are considered mature enough for widespread production use. Systems administrators will likely want to track its adoption in the Linux ecosystem, both from a technical and a legal perspective.

You can read [more about ZFS on Ubuntu](https://wiki.ubuntu.com/Kernel/Reference/ZFS) on the Ubuntu Wiki.

## Language Runtimes and Development Tools

### Go 1.6

Go 1.6 was [released](https://blog.golang.org/go1.6) earlier this year, and is packaged for Ubuntu 16.04.

### PHP 7

Ubuntu 16.04’s PHP packages now default to v7.0. PHP 7 offers major performance improvements over its predecessors, along with new features such as scalar type declarations for function parameters and return values. It also deprecates some legacy features and removes a number of extensions. If you are developing or deploying PHP 5 software, code changes or upgrades to newer releases may be necessary before you migrate your application.

See [Getting Ready for PHP 7](https://www.digitalocean.com/company/blog/getting-ready-for-php-7/) and the [official PHP migration guide](http://php.net/manual/en/migration70.php) for a detailed list of changes.

### Python 3.5

Ubuntu 16.04 comes by default with Python 3.5.1 installed as the `python3` binary. Python 2 is still installable using the `python` package:

    sudo apt-get install python

This may be necessary to support existing code which hasn’t yet been ported.

Users of the Vim editor should note that the default builds of Vim now use Python 3, which may break plugins that rely on Python 2.

## Conclusion

While this guide is not exhaustive, you should now have a general idea of the major changes and new features in Ubuntu 16.04.

The safest course of action in migrating to a major new release is usually to install the distribution from scratch, configure services with careful testing along the way, and migrate application or user data as a separate step. For some common configurations, you may want to read one or more of:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04)
- [How to Add and Delete Users on Ubuntu 16.04](how-to-add-and-delete-users-on-ubuntu-16-04)
- [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 16.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04)
- [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04)
- [How To Install Linux, Nginx, MySQL, PHP (LEMP stack) in Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04)

You can also read [How To Upgrade to Ubuntu 16.04 LTS](how-to-upgrade-to-ubuntu-16-04-lts) for details on the process of upgrading an existing system in place.
