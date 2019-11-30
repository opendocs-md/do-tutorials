---
author: Brennen Bearnes
date: 2016-04-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-upgrade-to-ubuntu-16-04-lts
---

# How To Upgrade to Ubuntu 16.04 LTS

## Introduction

**Warning:** As with almost any upgrade between major releases of an operating system, this process carries an inherent risk of failure, data loss, or broken software configuration. Comprehensive backups and extensive testing are strongly advised.

To avoid these problems, when possible, we recommend migrating to a fresh Ubuntu 16.04 server rather than upgrading in-place. You may still need to review differences in software configuration when upgrading, but the core system will likely have greater stability. You can follow our series on [how to migrate to a new Linux server](https://www.digitalocean.com/community/tutorial_series/how-to-migrate-to-a-new-linux-server) to learn how to migrate between servers.

The Ubuntu operating system’s next Long Term Support release, version 16.04 (Xenial Xerus), is due to be released on April 21, 2016.

Although it hasn’t yet been released at the time of this writing, it’s already possible to upgrade a 15.10 system to the development version of 16.04. This may be useful for testing both the upgrade process and the features of 16.04 itself in advance of the official release date.

This guide will explain the process for systems including (but not limited to) DigitalOcean Droplets running Ubuntu 15.10.

## Prerequisites

This guide assumes that you have a system running Ubuntu 15.10, configured with a non-root user with `sudo` privileges for administrative tasks.

## Potential Pitfalls

Although many systems can be upgraded in place without incident, it is often safer and more predictable to migrate to a major new release by installing the distribution from scratch, configuring services with careful testing along the way, and migrating application or user data as a separate step.

You should never upgrade a production system without first testing all of your deployed software and services against the upgrade in a staging environment. Keep in mind that libraries, languages, and system services may have changed substantially. In Ubuntu 16.04, important changes since the preceding LTS release include a transition to the systemd init system in place of Upstart, an emphasis on Python 3 support, and PHP 7 in place of PHP 5.

Before upgrading, consider reading the [Xenial Xerus Release Notes](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes).

## Step 1 – Back Up Your System

Before attempting a major upgrade on any system, you should make sure you won’t lose data if the upgrade goes awry. The best way to accomplish this is to make a backup of your entire filesystem. Failing that, ensure that you have copies of user home directories, any custom configuration files, and data stored by services such as relational databases.

On a DigitalOcean Droplet, the easiest approach is to power down the system and take a snapshot (powering down ensures that the filesystem will be more consistent). See [How To Use DigitalOcean Snapshots to Automatically Backup your Droplets](how-to-use-digitalocean-snapshots-to-automatically-backup-your-droplets) for more details on the snapshot process. When you have verified that the update was successful, you can delete the snapshot so that you will no longer be charged for it.

For backup methods which will work on most Ubuntu systems, see [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps).

## Step 2 – Upgrade Currently Installed Packages

Before beginning the release upgrade, it’s safest to install the latest versions of all packages _for the current release_. Begin by updating the package list:

    sudo apt-get update

Next, upgrade installed packages to their latest available versions:

    sudo apt-get upgrade

You will be shown a list of upgrades, and prompted to continue. Answer **y** for yes and press **Enter**.

This process may take some time. Once it finishes, use the `dist-upgrade` command, which will perform upgrades involving changing dependencies, adding or removing new packages as necessary. This will handle a set of upgrades which may have been held back by `apt-get upgrade`:

    sudo apt-get dist-upgrade

Again, answer **y** when prompted to continue, and wait for upgrades to finish.

Now that you have an up-to-date installation of Ubuntu 15.10, you can use `do-release-upgrade` to upgrade to the 16.04 release.

## Step 3 – Use Ubuntu’s do-release-upgrade Tool to Perform Upgrade

First, make sure you have the `update-manager-core` package installed:

    sudo apt-get install update-manager-core

Traditionally, Debian releases have been upgradeable by changing Apt’s `/etc/apt/sources.list`, which specifies package repositories, and using `apt-get dist-upgrade` to perform the upgrade itself. Ubuntu is still a Debian-derived distribution, so this process would likely still work. Instead, however, we’ll use `do-release-upgrade`, a tool provided by the Ubuntu project, which handles checking for a new release, updating `sources.list`, and a range of other tasks. This is the officially recommended upgrade path for server upgrades which must be performed over a remote connection.

Start by running `do-release-upgrade` with no options:

    sudo do-release-upgrade

If Ubuntu 16.04 has not been released yet, you should see the following:

Sample Output

    Checking for a new Ubuntu release
    No new release found

In order to upgrade to 16.04 before its official release, specify the `-d` option in order to use the _development_ release:

    sudo do-release-upgrade -d

If you’re connected to your system over SSH, as is likely with a DigitalOcean Droplet, you’ll be asked whether you wish to continue.

On a Droplet, it’s safe to upgrade over SSH. Although `do-upgrade-release` has not informed us of this, you can use the console available from the DigitalOcean Control Panel to connect to your Droplet without running SSH.

For virtual machines or managed servers hosted by other providers, you should keep in mind that losing SSH connectivity is a risk, particularly if you don’t have another means of remotely connecting to the system’s console. For other systems under your control, remember that it’s safest to perform major operating system upgrades only when you have direct physical access to the machine.

At the prompt, type **y** and press **Enter** to continue:

    Reading cache
    
    Checking package manager
    
    Continue running under SSH?
    
    This session appears to be running under ssh. It is not recommended
    to perform a upgrade over ssh currently because in case of failure it
    is harder to recover.
    
    If you continue, an additional ssh daemon will be started at port
    '1022'.
    Do you want to continue?
    
    Continue [yN] y

Next, you’ll be informed that `do-release-upgrade` is starting a new instance of `sshd` on port 1022:

    Starting additional sshd 
    
    To make recovery in case of failure easier, an additional sshd will 
    be started on port '1022'. If anything goes wrong with the running 
    ssh you can still connect to the additional one. 
    If you run a firewall, you may need to temporarily open this port. As 
    this is potentially dangerous it's not done automatically. You can 
    open the port with e.g.: 
    'iptables -I INPUT -p tcp --dport 1022 -j ACCEPT' 
    
    To continue please press [ENTER]

Press **Enter**. Next, you may be warned that a mirror entry was not found. On DigitalOcean systems, it is safe to ignore this warning and proceed with the upgrade, since a local mirror for 16.04 is in fact available. Enter **y** :

    Updating repository information
    
    No valid mirror found 
    
    While scanning your repository information no mirror entry for the 
    upgrade was found. This can happen if you run an internal mirror or 
    if the mirror information is out of date. 
    
    Do you want to rewrite your 'sources.list' file anyway? If you choose 
    'Yes' here it will update all 'trusty' to 'xenial' entries. 
    If you select 'No' the upgrade will cancel. 
    
    Continue [yN] y

Once new package lists have been downloaded and changes calculated, you’ll be asked if you want to start the upgrade. Again, enter **y** to continue:

    Do you want to start the upgrade?
    
    
    6 installed packages are no longer supported by Canonical. You can
    still get support from the community.
    
    9 packages are going to be removed. 104 new packages are going to be
    installed. 399 packages are going to be upgraded.
    
    You have to download a total of 232 M. This download will take about
    46 seconds with your connection.
    
    Installing the upgrade can take several hours. Once the download has
    finished, the process cannot be canceled.
    
     Continue [yN] Details [d]y

New packages will now be retrieved, then unpacked and installed. Even if your system is on a fast connection, this will take a while.

During the installation, you may be presented with interactive dialogs for various questions. For example, you may be asked if you want to automatically restart services when required:

![Service Restart Dialog](http://assets.digitalocean.com/articles/how-to-upgrade-to-ubuntu-1604/0.png)

In this case, it is safe to answer “Yes”. In other cases, you may be asked if you wish to replace a configuration file that you have modified with the default version from the package that is being installed. This is often a judgment call, and is likely to require knowledge about specific software that is outside the scope of this tutorial.

Once new packages have finished installing, you’ll be asked whether you’re ready to remove obsolete packages. On a stock system with no custom configuration, it should be safe to enter **y** here. On a system you have modified heavily, you may wish to enter **d** and inspect the list of packages to be removed, in case it includes anything you’ll need to reinstall later.

    Remove obsolete packages? 
    
    
    53 packages are going to be removed. 
    
     Continue [yN] Details [d]y

Finally, assuming all has gone well, you’ll be informed that the upgrade is complete and a restart is required. Enter **y** to continue:

    System upgrade is complete.
    
    Restart required 
    
    To finish the upgrade, a restart is required. 
    If you select 'y' the system will be restarted. 
    
    Continue [yN] y

On an SSH session, you’ll likely see something like the following:

    === Command detached from window (Thu Apr 7 13:13:33 2016) ===
    === Command terminated normally (Thu Apr 7 13:13:43 2016) ===

You may need to press a key here to exit to your local prompt, since your SSH session will have terminated on the server end. Wait a moment for your system to reboot, and reconnect. On login, you should be greeted by a message confirming that you’re now on Xenial Xerus:

    Welcome to Ubuntu Xenial Xerus (development branch) (GNU/Linux 4.4.0-17-generic x86_64)

## Conclusion

You should now have a working Ubuntu 16.04 installation. From here, you likely need to investigate necessary configuration changes to services and deployed applications. In the coming weeks, we’ll begin posting DigitalOcean guides specific to Ubuntu 16.04 on a wide range of topics.
