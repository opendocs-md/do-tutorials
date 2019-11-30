---
author: Justin Ellingwood
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-basic-freebsd-maintenance
---

# An Introduction to Basic FreeBSD Maintenance

## Introduction

When administering FreeBSD servers, it is important to understand the basic maintenance procedures that will help you keep your systems in good shape.

In this guide, we will be covering the basic processes needed to keep your server up-to-date and functioning properly. We will be covering how to update the base operating system that the FreeBSD team maintains. We will also discuss how to update and maintain optional software installed through the ports or packages systems.

If you need help getting started with FreeBSD, follow our guide [here](how-to-get-started-with-freebsd-10-1).

## Updating the Base FreeBSD Operating System

One important thing to realize when working with FreeBSD is that the base operating system is built and managed separate from the other software on the system. This provides a number of benefits and allows the FreeBSD team to carefully test and develop the core functionality of the system.

**Note** : Read the note at the bottom of this section regarding a bug in the current update procedure before proceeding.

When you start using your server, there is a good chance that security updates have been published to the base system. To query the FreeBSD project’s servers for these updates, download any new files, and install them on your system, type the following command:

    sudo freebsd-update fetch install

If you are working off of a DigitalOcean FreeBSD installation, `sudo` is included by default. If you are using another platform, you may need to install `sudo` through the ports system or packages, or `su` to root.

The `freebsd-update` command is the management utility for software in the base operating system. The `fetch` subcommand downloads any new updates, while the `install` subcommand applies them to the live system.

If there are updates, you will see a list of software impacted by the update. You can scroll through with the down arrow or page through with the space bar. Once you reach the bottom of the list, the updates will be applied.

Any long-running software that was updated will need to be restarted to use the new version. If you see any updates to the kernel, a reboot will be needed to prevent strange behavior. You can do this by typing:

    sudo shutdown -r now

### IMPORTANT: Bug in Update Procedure

Currently, there is an upstream bug with the FreeBSD update procedure being worked on [here](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=195458). The bug results in a hang on system reboot following the update procedure.

There are two ways of dealing with this situation, the second being preferred in most cases.

The first is to simply force a power cycle to the server using the DigitalOcean control panel. This will result in a forceful and ungraceful restart of the server, but when you boot back up, it will be using the updated environment.

A safer alternative is to disable soft-updates or the journaling of soft-updates on the filesystem prior to updating. Soft-updates are at the core of the issue, so this will prevent the reboot hang. This is a bit more of an extensive procedure and will add some time to any recovery that your disks require in the future (until you re-enable these features).

To do this, before you apply any updates, boot into single user mode. You can do this by typing:

    sudo nextboot -o "-s" -k kernel
    sudo reboot

Next, go into the DigitalOcean control panel for your Droplet and click on the “Console Access” button to get to the web console. Press “Enter” when the boot finishes to get a rescue shell session. From here, you can either turn off soft-updates or soft-update journaling.

To disable soft-updates completely, type:

    tunefs -n disable /

If you wish to just disable the soft-update journaling, a less drastic compromise, you can use this command instead:

    tunefs -j disable /

Once this is complete, you can initiate a reboot to restart the server in full multi-user mode once again:

    reboot

After the boot is finished, you can fetch and apply FreeBSD updates using the procedure described above without the reboot hang.

We recommend that you keep an eye on the [bug report](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=195458) so that you can revert these changes when the upstream fix is available.

### Automating Update Checking

It is possible to configure your system to automatically check for these security patches daily by setting up a `cron` job. The `freebsd-update` utility has a special `cron` subcommand that is available specifically for this purpose.

This will pause for a random amount of time (up to an hour) in order to spread out the load on the download servers. It will then check for updates and download them (basically the `fetch` operation in the background). If updates are downloaded, a specified user account will be notified. Updates are not automatically installed so that the administrator can decide on an appropriate time.

To set up this automatic checking, edit the `/etc/crontab` file with `sudo` privileges:

    sudo vi /etc/crontab

At the bottom of the file, add a line that looks like this:

    @daily root freebsd-update -t freebsd cron

The above command will run the update command automatically as the root user. If updates are found, the user account specified after the `-t` component will be notified. In the above example, the default `freebsd` user will be notified.

Save and close the file when you are finished.

The next time you log into the `freebsd` account, you can check your mail by typing:

    mail

If updates were downloaded, you will see something like this:

    Mail version 8.1 6/6/93. Type ? for help.
    "/var/mail/freebsd": 1 message 1 new
    >N 1 freebsd@freebsdserver Thu Dec 18 21:45 209/3997 "freebsdserver security updates"
    &

You can view the list of updates by typing the message number associated with the notification:

    1

When you are satisfied with the software that will be changed, you can quickly install the updates by typing:

    sudo freebsd-update install

Remember to restart the machine if any kernel patches were applied and to restart any services that were affected by the update.

## Syncing the Operating System Sources

One task you probably want to do from time-to-time is to sync a copy of the FreeBSD source code to your system. This is useful for a variety of reasons. Some ports require the current source to build correctly and the source can also be used to start tracking to a new software branch.

The FreeBSD source code is maintained in an SVN repository. If you just need the most up-to-date version of the source, without the large overhead that subversion entails, you can use a utility called `svnup` to sync the current sources. This is much faster than using subversion itself.

You can install the `svnup` package by typing:

    sudo pkg install svnup

If you prefer using the port, you can get that by typing:

    cd /usr/ports/net/svnup
    sudo make config-recursive install clean

Once you have the utility, we should adjust the configuration file slightly. Open it with `sudo` privileges in your text editor:

    sudo vi /usr/local/etc/svnup.conf

First, we need to select a mirror from the list. There are multiple `host=` lines in the configuration file, all of which are commented out. Select one that you think may be close to you and uncomment it:

    . . .
    [defaults]
    work_directory=/var/tmp/svnup
    #host=svn.freebsd.org
    #host=svn0.us-west.freebsd.org
    host=svn0.us-east.freebsd.org
    #host=svn0.eu.freebsd.org
    
    . . .

Next, you should make sure that the sections of the file that describe each SVN branch are referencing the release version you are using. You can find this out your release version by typing this from the command line:

    freebsd-version

    10.1-RELEASE-p2

This tells us the branch of the operating system as well as the system patch level at the end. The portion we want to pay attention to for our current purposes is the number before the first dash. In this case, it specifies `10.1`. The `RELEASE` means that we are currently tracking the release branch, the most stable branch available for FreeBSD.

Back in the file, make sure that the definition for the `branch=` parameter under `[release]` is pointing to this number:

    . . .
    
    [release]
    branch=base/releng/10.1
    target=/usr/src
    
    . . .

This will ensure that you are downloading the correct source. Save and close the file when you are finished.

Now, since we are tracking the release branch, we can type:

    sudo svnup release

This will download the most recent version of the source tree to `/usr/src`. You can update it at any time by re-running this command.

If you need the ability run subversion commands on the source, you will have to download the subversion tool. You can install the package by typing:

    sudo pkg install subversion

If you prefer to use ports, you can acquire the tool by typing:

    cd /usr/ports/devel/subversion
    sudo make config-recursive install clean

Using the `subversion` command will take **significantly** more time. It will not only download the current version of each file in the tree, but the entire history of the project.

If you have previously synced source using the `svnup` tool, you will need to remove the source tree before checking out the source using `subversion`:

    sudo rm -rf /usr/src

Detailed instructions on how to use `subversion` is outside of the scope of this guide. However, the general idea is to issue a `checkout` command against one of the branches on one of the FreeBSD source mirrors.

For instance, to checkout the same exact source that we did using the `svnup` command above, we could type something like this:

    sudo svn checkout https://svn0.us-east.FreeBSD.org/base/releng/10.1 /usr/src

Note that the URL for this command is basically just a combination of the `host=` and `branch=` definitions that we saw in the `svnup` configuration file.

## Updating the System’s Record of Optional Software

FreeBSD provides two different formats to install additional software on your server. The first is a source-based system called “ports” and the second is a repository of pre-compiled packages based on the available ports. For software that resides outside of the base operating system, a number of additional tools are used for management.

The system keeps information about the ports that can be installed within a directory hierarchy rooted at `/usr/ports`. This directory structure is called the “ports tree”. Before we touch any ports, we should make sure our ports tree has up-to-date information about our available software. We can use the `portsnap` command to do this.

The syntax of the `portsnap` command mirrors that of the `freebsd-update` command in some ways. On DigitalOcean, the source tree will be pre-populated with initial information about the available ports, which you can update as demonstrated in the second `portsnap` command.

If you are _not_ using DigitalOcean, your `/usr/ports` directory will likely be empty when you are starting out. If this is the case, the first time you use `portsnap`, you should use `extract`:

    sudo portsnap fetch extract

This will fetch a complete ports tree and extract it into `/usr/ports`. This can take awhile and is only necessary if you don’t have any information in `/usr/ports`.

To update our system’s information about available ports (every subsequent `portsnap` run), type:

    sudo portsnap fetch update

This process can take a bit of time depending on how recently you last updated the ports tree. It must download a fair number of files for every piece of available software that has been modified since its last run. This will populate the `/usr/ports` hierarchy with information about ports.

The `pkg` packaging system can leverage some of this information too. However, it also maintains its own database to keep track of the pre-built binary packages available for installation. To update this, you can type:

    sudo pkg update

This will fetch the most recent package database information from the FreeBSD project’s servers. It’s worth noting that for many `pkg` operations, a `pkg update` is performed automatically as part of the command execution, so it is not always needed as a stand-alone command.

## Update the Optional Software

So far, we have learned how to update and apply updates to the base operating system. We have also learned how to update our operating system source code and how to refresh our local information about available ports and packages.

Now, we can use this updated software information to download and apply updates to our optional software. The process will be different depending on whether you are using ports or packages. If you are using a mixture of these two, you may need to juggle some processes.

### Finding Out Which Software can be Updated

The first step in updating your software is to find out which applications have new versions available. We can do this in a few different ways.

#### Checking for Updates with the pkg Command

If you would like to compare software that you have installed on your system against updated information about the newest versions available, you can use the `version` subcommand of `pkg`. This shows you the installed version and can optionally display information about available versions.

It is worth noting that this command will show optional software installed through **both** ports and packages. This command does not distinguish between the installation sources, so it is able to accurately show all updates available on your system.

We can see if our software is up-to-date by typing:

    pkg version -vIL=

If there are references to a new version of any software in the latest index file (downloaded through the `portsnap` command earlier), the output will display the discrepancies. For example:

    perl5-5.18.4_10 < needs updating (index has 5.18.4_11)

Since we are checking the software installed on our system against the latest index file in our ports tree, sometimes you will be checking this at a point when there are updates in the ports tree that have not made their way to the package yet. This happens because the packages are built from the ports tree and often have to lag behind slightly.

Because of this possibility, the above command may show updates that are not actually available as packages yet. To spot these instances, you can compare the output of the above command to the output of this command:

    pkg version -vRL=

This command checks for new versions in the `pkg` system’s database of available packages (instead of the index file in the ports tree). If the two commands produce the same output, then you will be able to update any packages using the `pkg` system.

If there are updates in the first command that do not show up in the second command, this means that the changes haven’t been packaged yet. If you are using packages for the software that needs to be updated, you can either wait until the package catches up, or you can switch to the port to get the latest update now.

#### Checking for Updates with Portmaster

If you more often choose to build software from source using the ports system, an attractive alternative is the `portmaster` command. This tool is useful for any ports-based software management tasks on FreeBSD, from checking for and applying updates, to installing or removing ports and all of their dependencies.

To get the `portmaster` command, you can either install the package or compile it from the ports system.

To install the package, type:

    sudo pkg install portmaster

If you’d rather compile the tool from source, switch to the package’s directory in the ports tree and install it using make:

    cd /usr/ports/ports-mgmt/portmaster
    sudo make install clean

Upon installation, you may see a message about adding some information to your `/etc/make.conf` file and converting your package database. This is not necessary if you are starting from FreeBSD 10.1 or later.

Once you have `portmaster` installed, you can check for updates by typing:

    portmaster -L

This will examine all of the software installed on your system and compare it against the index file to see if new versions are available. This operates in the same way as the `pkg` command in that it will show updates regardless of whether the software was installed using ports or a package. It categorizes the software based on how it is connected to other software in terms of dependencies.

Any software that has updates available will have an indented line like this:

    ===>>> perl5-5.18.4_10
            ===>>> New version available: perl5-5.18.4_11

At the bottom, a summary line will describe the number of applications that can be updated:

    ===>>> 42 total installed ports
            ===>>> 1 has a new version available

Since `portmaster` works primarily with ports, all of the detected updates should be available for application.

### Checking for Software Vulnerabilities

FreeBSD maintains a vulnerability database that should be checked regularly to ensure that there are no vulnerabilities in the software you have installed on your system.

While it is sometimes beneficial to update all of the software on your system, at the very least, any software with known vulnerabilities should be updated at the earliest possible time. To check for known vulnerabilities with any of the optional software you have installed on your system, type:

    pkg audit -F

This will download the latest vulnerability database from the FreeBSD servers and check it against the installed software on your system. If any vulnerabilities exist with your installed software, it will alert you.

### Checking the UPDATING Notes

Before you update any software, it is **essential** to check for any breakages that the updates may cause. The FreeBSD port maintainers must sometimes make changes that cannot be applied cleanly without user intervention. If you fail to check for these situations, you may end up with non-working software and potentially a broken system.

In the `/usr/ports` directory, a file called `UPDATING` contains information about any software updates that may have unexpected results. To read this file, type:

    less /usr/ports/UPDATING

This simple text file will contain information about any updates that require additional attention, regardless of whether the software is installed or not. Each entry will be marked with the date when the referenced update was committed to the ports tree. Another thing to note is that the file contains update information going all the way back to 2008. The file will look something like this:

    This file documents some of the problems you may encounter when upgrading
    your ports. We try our best to minimize these disruptions, but sometimes
    they are unavoidable.
    
    You should get into the habit of checking this file for changes each time
    you update your ports collection, before attempting any port upgrades.
    
    20141208:
      AFFECTS: users of ports-mgmt/poudriere, ports-mgmt/poudriere-devel
      AUTHOR: bdrewery@FreeBSD.org
    
      8.4 jails created with Poudriere 3.1, or poudriere-devel-3.0.99.20141117
      should be recreated with 'jail -d' and 'jail -c'. This fixes pkg(8)
      crashes.
    
    20141205:
      AFFECTS: users of polish/kadu
      AUTHOR: pawel@FreeBSD.org
    
      Before running kadu 1.x for the first time upstream developers
      advise to backup your ~/.kadu directory.
    
    . . .

You should check this file for any update issues that have been added since the last time that you updated. Since this file contains a large amount of information that will not be relevant to the update you are considering, either because it concerns software not installed on your system, or because it details an issue from a previous update, you usually only have to check the entries closer to the top of the file.

If there are any extra steps you need to take before the upgrade, complete them now.

### Updating Packages and Ports

After taking any actions recommended in the `UPDATING` file, you should now be ready to update your software. The methods that we use will depend on whether you want to use pre-compiled packages or source-based ports for your software.

If you are mainly using packages and wish to use this format for your upgrades, you can use the `pkg upgrade` command:

    sudo pkg upgrade

This should offer to upgrade all of the packages for which there are updates available.

One thing to note about this method is that, if you are mixing packages and ports, a package update may attempt to reinstall software that you built using the ports system. This can happen when you compiled the application with different options, selected customizations that required different dependencies, etc. from the packaged version.

This scenario will look like this:

    freebsd@wowie:~ % sudo pkg upgrade
    Updating FreeBSD repository catalogue...
    FreeBSD repository is up-to-date.
    All repositories are up-to-date.
    Updating database digests format: 100%
    Checking for upgrades (2 candidates): 100%
    Processing candidates (2 candidates): 100%
    The following 1 packages will be affected (of 0 checked):
    
    Installed packages to be REINSTALLED:
            portmaster-3.17.7 (options changed)
    
    The operation will free 1 KB.
    40 KB to be downloaded.
    
    Proceed with this action? [y/N]:

In this case, the `portmaster` command was installed through the ports system, but `pkg` is trying to bring it into line with the version it knows about. If you wish to keep your customized ports version, you can press “N” to this operation and then lock the package by typing:

    sudo pkg lock portmaster

This will prevent the software from being upgraded, allowing you to upgrade the rest of the software using the `pkg upgrade` command. When you wish to upgrade the locked software, you can unlock it temporarily by typing:

    sudo pkg unlock portmaster

If you are mainly using `portmaster` and ports to handle your packages, you can upgrade all of your optional installed software by typing:

    sudo portmaster -a

You will be asked to select options for the ports you are upgrading. If you do not know what any of the options mean, or if you don’t have any specific reason for making a selection, it is okay to use the defaults.

If you use `portmaster` before you upgrade your packages, because of the lag between port and package updates, there is a chance that some software that was previously installed using a package will now be updated using ports. If this is not a problem for you, feel free to use this method. If you would rather stick with packages for your software, it is probably best to wait until the update is repackaged.

If you wish to granularly update your packages, you can also upgrade a specific package by specifying its category and name as found in the port tree:

    sudo portmaster category/portname

For instance, to upgrade the `vim-lite` port, you could issue this command:

    sudo portmaster editors/vim-lite

## Conclusion

As you can see, there are quite a few different processes that need to take place in order to maintain your FreeBSD servers.

Some of these, like the process of updating the base system’s source, do not need to be run frequently, while other tasks, like updating the base operating system and updating any software with known vulnerabilities, should be completed often. Maintaining your system may seem complicated at first, but will become fairly straight forward as you get familiar with the tools you are using.

To find out more information about how to work with packages, follow [this link](how-to-manage-packages-on-freebsd-10-1-with-pkg). To get a better idea of how to work with ports, follow [this guide](how-to-install-and-manage-ports-on-freebsd-10-1).
