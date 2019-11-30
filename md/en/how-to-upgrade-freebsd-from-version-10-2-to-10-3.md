---
author: Vinícius Zavam
date: 2016-07-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-upgrade-freebsd-from-version-10-2-to-10-3
---

# How To Upgrade FreeBSD from Version 10.2 to 10.3

## Introduction

FreeBSD is constantly evolving; the team is adding new features and patching security vulnerabilities. Keeping your server operating system up to date ensures better security and compatibility, and FreeBSD includes the `freebsd-update` tool to make this easy. In this tutorial, you’ll upgrade an existing FreeBSD server running FreeBSD 10.2-RELEASE to 10.3.RELEASE-p4.

**Warning:** As with almost any upgrade between major releases of an operating system, this process carries an inherent risk of failure, data loss, or broken software configuration. Comprehensive backups and extensive testing are strongly advised.

To avoid these problems, when possible, we recommend migrating to a fresh FreeBSD server rather than upgrading in-place. You may still need to review differences in software configuration when upgrading, but the core system will likely have greater stability. You can check out our series on [how to migrate to a new Linux server](https://www.digitalocean.com/community/tutorial_series/how-to-migrate-to-a-new-linux-server) which should mostly apply when migrating to new FreeBSD servers as well.

## Prerequisites

To follow this tutorial, you will need:

- A server running FreeBSD 10.2.
- A user account configured to run commands with `sudo`. We will use the default **freebsd** account which is created automatically when you create a FreeBSD Droplet. To learn more about logging into your FreeBSD Droplet and its basic management, check out the [Getting Started with FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd) tutorial series.

## Step 1 — Fetching and Applying Patches

In order to upgrade the operating system, we first need to fetch the packages and patches for our destination release. Log into the server with the **freebsd** account.

    ssh freebsd@your_server_ip

Then, use the `freebsd-upgrade` command to gather information about the system upgrade and determine what needs to change. Run the following command:

    sudo freebsd-update upgrade -r 10.3-RELEASE

We use the `-r` switch to specify the version we want to upgrade to, which is `10.3-RELEASE`. After a short time you’ll see the following output:

    Outputsrc component not installed, skipped
    Looking up update.FreeBSD.org mirrors... 4 mirrors found.
    Fetching public key from update6.freebsd.org... done.
    Fetching metadata signature for 10.2-RELEASE from update6.freebsd.org... done.
    Fetching metadata index... done.
    Fetching 2 metadata files... done.
    Inspecting system... 
    
    The following components of FreeBSD seem to be installed:
    kernel/generic world/base world/doc world/games world/lib32
    
    The following components of FreeBSD do not seem to be installed:
    
    Does this look reasonable (y/n)? y

This gives you a chance to review any potential problems. Type `y` and press `ENTER` to continue.

**Note:** Please remember that this tutorial uses a fresh FreeBSD 10.2 server to guide you through all the steps for upgrading the FreeBSD base system to version 10.3-RELEASE-p4. If you have modified or customized some of the components, create a backup before you continue, and accept all procedures described in this tutorial at your own risk.

Once you agree to continue, the process applies updates and patches. You’ll see the following output:

    OutputFetching metadata signature for 10.3-RELEASE from update6.freebsd.org... done.
    Fetching metadata index... done.
    Fetching 1 metadata patches. done.
    Applying metadata patches... done.
    Fetching 1 metadata files... done.
    Inspecting system... 
    Fetching files from 10.2-RELEASE for merging... done.
    Preparing to download files... 
    Fetching 10722 patches.....10....20....30....40....50....60....70....80....90
    ....100....110....120....130....140....150....160....170....180....190....200
    
        **. . .**
    
    ....10650....10660....10670....10680....10690....10700....10710....10720. done.
    Applying patches... done.
    Fetching 152 files... 
    Attempting to automatically merge changes in files... done.

However, the process can’t patch everything automatically. We’ll need to intervene manually.

## Step 2 — Resolving Conflicts

After applying patches to the operating system, `freebsd-update` will show you two warning messages, and you will need to manually resolve some minor conflicts in two different configuration files. One is `/etc/rc.subr` and the other one is `/etc/ssh/sshd_config`.

The first warning you see is as follows:

    outputThe following file could not be merged automatically: `/etc/rc.subr`
    Press Enter to edit this file in vi and resolve the conflicts
    manually...

When you press `Enter`, the `/etc/rc.subr` file opens in the `vi` text editor and you’ll see the following text:

/etc/rc.subr file with conflicts to solve manually

    # $NetBSD: rc.subr,v 1.67 2006/10/07 11:25:15 elad Exp $
    <<<<<<< current version
    # $FreeBSD: releng/10.1/etc/rc.subr 273188 2014-10-16 22:00:24Z hrs $
    =======
    # $FreeBSD: releng/10.3/etc/rc.subr 292450 2015-12-18 19:58:34Z jilles $
    >>>>>>> 10.3-RELEASE

Modify this section by removing the lines related to the current version, which are highlighted in red above. Even though we are currently running FreeBSD 10.2, this file references 10.1 as “current.” Remove those lines so the section looks like the following example:

/etc/rc.subr ready to proceed

    # $NetBSD: rc.subr,v 1.67 2006/10/07 11:25:15 elad Exp $
    # $FreeBSD: releng/10.3/etc/rc.subr 292450 2015-12-18 19:58:34Z jilles $

**Warning:** DigitalOcean keeps its custom configuration and data for FreeBSD Droplets under the `/etc/rc.digitalocean.d/` directory, and it’s referenced in the `/etc/rc.subr` file. **Please do not change or remove the files or configuration related to DigitalOcean.** The custom configurations and data under `/etc/rc.digitalocean.d/` is what keeps your Droplet up, running in a good shape, and integrated with DigitalOcean’s API.

Save your changes to the file and exit the editor.

As soon as you close the text editor, you will see a line reporting the successful merge of the file you just changed. Then you’ll see the second warning which says that the `/etc/ssh/sshd_config` configuration file needs your attention:

    Output/var/db/freebsd-update/merge/new//etc/rc.subr: 2087 lines, 47888 characters.
    
    The following file could not be merged automatically: `/etc/ssh/sshd_config`
    Press Enter to edit this file in vi and resolve the conflicts
    manually...

Just like before, when you press `ENTER` you will be presented with a text file you’ll have to modify. The piece you’ll need to change will be similar to the first file you edited.

/etc/ssh/sshd\_config file with conflicts to solve manually

    <<<<<<< current version
    # $OpenBSD: sshd_config,v 1.93 2014/01/10 05:59:19 djm Exp $
    # $FreeBSD: releng/10.1/crypto/openssh/sshd_config 264692 2014-04-20 12:46:18Z des $
    =======
    # $OpenBSD: sshd_config,v 1.98 2016/02/17 05:29:04 djm Exp $
    # $FreeBSD: releng/10.3/crypto/openssh/sshd_config 296853 2016-03-14 13:05:13Z des $
    >>>>>>> 10.3-RELEASE

Once again, modify this section by removing the lines related to the current version until the section of the file looks like this:

/etc/ssh/sshd\_config ready to proceed

    # $OpenBSD: sshd_config,v 1.98 2016/02/17 05:29:04 djm Exp $
    # $FreeBSD: releng/10.3/crypto/openssh/sshd_config 296853 2016-03-14 13:05:13Z des $

Save your changes to the file and close the editor.

Once the editor closes, the `freebsd-update` process will display each file you changed and ask if the changes look reasonable. Answer `y` to both questions to continue the installation.

Once you agree to the changes, you will see a list of binaries and configuration files that will be updated. This list is very long; press `SPACE` to scroll down the list one page at a time. Or, if you don’t want to review the list, type `q` to quit. Don’t worry; pressing `q` won’t abort the upgrade process.

The list looks like this:

    OutputThe following files will be added as part of updating to 10.3-RELEASE-p5:
    /boot/kernel/ismt.ko
    /boot/kernel/ismt.ko.symbols
    /boot/kernel/linux64.ko
    /boot/kernel/linux64.ko.symbols
    /boot/kernel/linux_common.ko
    /boot/kernel/linux_common.ko.symbols
    /boot/kernel/mlx5.ko
    
        . . .
    
    The following files will be updated as part of updating to 10.3-RELEASE-p5:
    /.cshrc
    /.profile
    /COPYRIGHT
    /bin/[
    /bin/cat
    /bin/chflags
    /bin/chio
    
        . . .

Once you’ve reviewed the list, you’ll be back at your terminal prompt. You’re ready to perform the installation.

## Step 3 — Installing FreeBSD 10.3

The updates have been downloaded and essential files have been successfully merged or configured, so to install the downloaded upgrades, use the following command:

    sudo /usr/sbin/freebsd-update install

Here is the output you will see:

    Outputsrc component not installed, skipped
    Installing updates...
    Kernel updates have been installed. Please reboot and run
    "/usr/sbin/freebsd-update install" again to finish installing updates.

The installation prompts you to perform a reboot, so execute this command to reboot your machine:

    sudo reboot

You’ll be disconnected from your SSH session, and the reboot will take about a minute. Once your machine has come back online, log back in and move on to the next step.

**Note:** You must reboot your server in order to load the new 10.3-RELEASE-p4 kernel and its patched binary files, which are loaded only during the boot process. Do not move on to the next steps without rebooting.

## Step 4 — Completing the Installation Process

Let’s check the version of our server to make sure the upgrade process worked and the new kernel is loaded. First, log back into your server:

    ssh freebsd@your_server_ip

Once logged in, run the following command:

    uname -a

and you’ll see the following output indicating that the upgrade worked:

    OutputFreeBSD YOUR_HOSTNAME 10.3-RELEASE-p4 FreeBSD 10.3-RELEASE-p4 #0: Sat May 28 12:23:44 UTC 2016 root@amd64-builder.daemonology.net:/usr/obj/usr/src/sys/GENERIC amd64

But we’re not quite done with the upgrade. We need to install any final updates that may have occurred since the release was created, so run `freebsd-update` once more.

    sudo /usr/sbin/freebsd-update install

You’ll see the following output:

    Outputsrc component not installed, skipped
    Installing updates...
    Installing updates...
    install: ///var/db/etcupdate/current/etc/mtree/BSD.debug.dist: No such file or directory
    install: ///var/db/etcupdate/current/etc/periodic/daily/480.leapfile-ntpd: No such file or directory
     done.

It’s safe to disregard the two warnings at the end. Both files will be created or updated by this process.

When you upgrade FreeBSD, you should also upgrade all of your third-party installed packages, especially if you are doing a major release upgrade. To do that, run the following command:

    sudo pkg upgrade

The output will look like this:

    OutputUpdating FreeBSD repository catalogue...
    FreeBSD repository is up-to-date.
    All repositories are up-to-date.
    
        . . .
    
    Processing entries: 100%
    FreeBSD repository update completed. 25089 packages processed.
    New version of pkg detected; it needs to be installed first.
    The following 1 package(s) will be affected (of 0 checked):
    
    Installed packages to be UPGRADED:
            pkg: 1.5.6 -> 1.7.2
    
    The process will require 242 KiB more space.
    2 MiB to be downloaded.
    
    Proceed with this action? [y/N]: y

Type `y` and press `ENTER` to continue, and you’ll see the following output:

    OutputFetching pkg-1.7.2.txz: 100% 2 MiB 1.3MB/s 00:02    
    Checking integrity... done (0 conflicting)
    [1/1] Upgrading pkg from 1.5.6 to 1.7.2...
    [1/1] Extracting pkg-1.7.2: 100%
    Updating FreeBSD repository catalogue...
    Repo "FreeBSD" upgrade schema 2011 to 2012: Add depends formula field
    Repo "FreeBSD" upgrade schema 2012 to 2013: Add vital field
    FreeBSD repository is up-to-date.
    All repositories are up-to-date.
    Checking for upgrades (24 candidates): 100%
    Processing candidates (24 candidates): 100%
    The following 24 package(s) will be affected (of 0 checked):
    
    Installed packages to be UPGRADED:
            xproto: 7.0.27 -> 7.0.28
            sudo: 1.8.13 -> 1.8.16_1
            rsync: 3.1.1_3 -> 3.1.2_1
            python27: 2.7.9_1 -> 2.7.11_2
            py27-setuptools27: 17.0 -> 20.0
            py27-pip: 7.0.3 -> 8.0.2
            perl5: 5.20.2_5 -> 5.20.3_12
            pcre: 8.37_4 -> 8.38_1
            libxml2: 2.9.2_3 -> 2.9.3
            libxcb: 1.11_1 -> 1.11.1
            libnet: 1.1.6_3,1 -> 1.1.6_4,1
            libiconv: 1.14_8 -> 1.14_9
            libX11: 1.6.2_3,1 -> 1.6.3,1
            kbproto: 1.0.6 -> 1.0.7
            indexinfo: 0.2.3 -> 0.2.4
            gobject-introspection: 1.42.0 -> 1.46.0
            glib: 2.42.2 -> 2.46.2
            gettext-runtime: 0.19.4 -> 0.19.7
            expat: 2.1.0_3 -> 2.1.1_1
            dbus: 1.8.16 -> 1.8.20
            curl: 7.43.0_2 -> 7.48.0_1
            ca_root_nss: 3.19.3 -> 3.22.2
            avahi-app: 0.6.31_3 -> 0.6.31_5
    
    Installed packages to be REINSTALLED:
            dbus-glib-0.104 (option added: DOCS)
    
    The process will require 5 MiB more space.
    39 MiB to be downloaded.
    
    Proceed with this action? [y/N]: y

Once again, type `y`, followed by `ENTER` to continue.

The packages will upgrade, but to make sure your user has access to the latest versions, run the `rehash` command:

    rehash

With that, the upgrade process is complete. But what if something went wrong?

## Step 5 — Rolling Back a Failed Installation (Optional)

This entire upgrade process should go smoothly, but if something goes wrong for you during the upgrade you can roll back recently installed packages with the following command:

    sudo freebsd-update rollback

This will initiate the rollback process, getting you back to where you were. You could also restore the most recent backup you made before you began the process.

## Conclusion

Upgrading an operating system to a newer release and applying security patches in a timely manner are important aspects of ongoing system administration. The `freebsd-update` command makes both of those tasks easy to do. Once you become familiar with the process, you’ll be able to perform future upgrades on your own.

To learn even more about how to upgrade FreeBSD, you can read [An Introduction To Basic FreeBSD Maintenance](an-introduction-to-basic-freebsd-maintenance), or review the corresponding chapter at the [FreeBSD Handbook](https://www.freebsd.org/doc/en/books/handbook/updating-upgrading.html).
