---
author: wrexroad
date: 2016-12-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-convert-an-owncloud-installation-to-nextcloud-on-ubuntu-14-04
---

# How To Convert an ownCloud Installation to Nextcloud on Ubuntu 14.04

## Introduction

Recently, a large portion of the core development team at [ownCloud](https://owncloud.org/) left to start a new project called [Nextcloud](https://nextcloud.com/). While ownCloud will still continue to be developed, you might want to see what the new project has to offer. Nextcloud and ownCloud share a common code base which means migrating your existing ownCloud installation to Nextcloud should be a painless task.

In this tutorial, you’ll migrate an existing ownCloud installation to Nextcloud. The process involves swapping out the core application files with those from Nextcloud, and letting Nextcloud’s built-in updater do the heavy lifting. While the process is simple, there are a number of things that need to be done in the correct order to make sure everything goes smoothly.

**Note:** You can only update ownCloud and Nextcloud installations one major version number at a time. If you currently use ownCloud 9, you must migrate to Nextcloud 10 first, and then upgrade to Nextcloud 11. This tutorial covers this process.

## Prerequisites

In order to migrate you ownCloud installation to Nextcloud, you will need:

- A working ownCloud 9 installation running on Ubuntu 14.04.
- An unprivileged user account on the ownCloud server which can run commands with `sudo`. You can configure this by following the [How to Create a Sudo User on Ubuntu](how-to-create-a-sudo-user-on-ubuntu-quickstart) tutorial.

## Step 1 — Stopping the Web Server and Backing Up Data

Even if you’re working with a freshly configured install, it is a good idea to do a quick backup. You’re about to start moving and deleting things, so safety first!

Log into your server running ownCloud if you’re not already connected:

    ssh sammy@your_server_ip

It’s important to make sure nothing changes while you perform the backup and migration, so the easiest way to ensure that is to shut down the web server so users can’t access ownCloud. Execute this command:

    sudo service apache2 stop

Now that the web server has stopped, navigate to the directory where your server stores ownCloud. If you are using the One-Click installation for ownCloud on Ubuntu 14.04, your installation is located within the `/var/www/` directory. Run the following commands to switch to this directory and verify that it contains `owncloud/`:

    cd /var/www
    ls

You’ll see the `owncloud` folder:

    Outputhtml owncloud

Next, create the backup archive using the `tar` command to **c** ompress a g **z** ip **f** ile and display **v** erbose output to the screen. The new archive will be called `owncloud.tar.gz` and will contain the entire `owncloud/` directory. Execute the following command:

    sudo tar czfv owncloud.tar.gz owncloud/

Now move the archive to your home directory for safe-keeping:

    sudo mv owncloud.tar.gz ~/

**Note** : Your ownCloud files are backed up, but if you are using MySQL or any other database instead of the internal data storage option, you should also make a backup of the database. For MySQL, create a backup by running this command:

    mysqldump -u username -p dbname > ~/owncloud_backup.sql

You can find the values for `username`, `password`, and `dbname` in the configuration file located at `/var/www/owncloud/config/config.php`.

You can find more information about backing up and restoring MySQL databases [here](how-to-backup-mysql-databases-on-an-ubuntu-vps).

Before installing Nextcloud, there is one more step specific to Ubuntu 14.04 servers.

## Step 2 - Upgrading PHP

If you are migrating from the One-Click installation on Ubuntu 14.04 you will need to upgrade PHP to be able to use any version of Nextcloud that is newer than 10.0.2. The standard Ubuntu 14.04 repositories only include PHP 5.5, but PHP 5.6 is required starting with NextCloud 11. Luckily, Ubuntu supports 3rd party repositories known as PPAs. If you have not installed PPAs before, execute this command to install a package called `python-software-properties`:

    sudo apt-get install python-software-properties

Next, add the PPA that contains updated versions of PHP:

    sudo add-apt-repository ppa:ondrej/php

Then tell the package manager to update its list of known packages, which includes those in the PPA:

    sudo apt-get update

Now you can install PHP7 and all of the modules that are required by Nextcloud:

    sudo apt-get install php7.0 php7.0-sqlite php7.0-mysql php7.0-pgsql php7.0-zip php7.0-gd php7.0-mb php7.0-curl php7.0-xml php7.0-apc

Finally, switch the PHP module that your web server uses. For Apache, the commands to do this are:

    a2dismod php5
    a2enmod php7.0

**Note:** If you are using your server for anything other than ownCloud, you should make sure that your web server doesn’t need PHP5.5 before disabling that module.

Now let’s get Nextcloud installed.

## Step 3 — Downloading Nextcloud

At the [Nextcloud release site](https://download.nextcloud.com/server/releases/) you will find a list of every Nextcloud release in a number of different formats. Find the most recent `.tar.gz` file for the release that is the same as, or one major version after, your current ownCloud version. For example, if you are migrating from the ownCloud 9 One-Click installation you would be looking for the file `nextcloud-10.0.2.tar.bz2`.

When you find the file, don’t download it onto your personal computer. Instead, right click the file name and copy the link address so you can download the file to your server.

You’re going to download two files. The first will be the Nextcloud package that you found on the web site. The other file will be a verification file called an “md5 checksum”. The md5 file will have the exact same path as the package, but with the extra extension `.md5` added to the end. Execute the follow commands to move to your home directory, then download the two files.

    cd ~
    wget https://download.nextcloud.com/server/releases/nextcloud-10.0.2.tar.bz2
    wget https://download.nextcloud.com/server/releases/nextcloud-10.0.2.tar.bz2.md5

Run the `md5sum` command to generate its checksum to verify the integrity of the package file:

    md5sum nextcloud-10.0.2.tar.bz2

You’ll see something similar to this output:

    Outputdc30ee58858d4f6f2373472264f7d147 nextcloud-10.0.2.tar.bz2

Then display the contents of the `.md5` file that you downloaded:

    cat nextcloud-10.0.2.tar.bz2.md5

The output of this command should be identical to the output of the previous command:

    Outputdc30ee58858d4f6f2373472264f7d147 nextcloud-10.0.2.tar.bz2

If the outputs are different, download Nextcloud again.

To unpack the file, use the `tar` command again, but this time, e **x** tract the **f** ile with **v** erbose output. Execute this command to extract the archive:

    tar xfv nextcloud-10.0.2.tar.bz2

Finally, copy the newly extracted `nextcloud` folder to the `/var/www` folder:

    sudo mv nextcloud /var/www/nextcloud

Now you can start migrating your files from ownCloud to Nextcloud.

## Step 4 — Migrating Data and Setting File Ownership

Your existing ownCloud installation has two directories you’ll want to preserve: `data/` and `config/`. You’ll move these from their original locations into your `nextcoud` directory, but first, you’ll want to remove the default versions that came with Nextclout.

First, execute the command to delete the default directories from your `nextcloud` directory, if they exist:

    sudo rm -rf /var/www/nextcloud/data /var/www/nextcloud/config

Then move the old directories over from the `owncloud` directory:

    sudo mv /var/www/owncloud/data /var/www/nextcloud/data
    sudo mv /var/www/owncloud/config /var/www/nextcloud/config

One consquence of moving files with the `sudo` command is the files will all be owned by the **root** user. Nextcloud, however, is always run by the **www-data** user. This means you need to change the ownership of the `/var/www/nextcloud` folder and its contents before you go any further. To do this run the `chown` command with the `-R` argument to recursivly change all of the file ownerships to the **www-data** user:

    sudo chown -R www-data:www-data /var/www/nextcloud/

Now that the files are in place, we need to tell the web server how to access them.

## Step 5 — Upgrading the Nextcloud Internals

With all of the files in place, you can initiate the internal upgrade process. Nextcloud and ownCloud provide a tool to manage and upgrade installations called `occ`. Navigate to the `/var/www/nextcloud/` directory:

    cd /var/www/nextcloud

Before you can use `occ`, you’ll have to update the `/var/www/nextcloud/config/config.php` file to reflect the new location of the data directory. Specifically, the line `'datadirectory' => '/var/www/owncloud/data',` needs to be changed to `'datadirectory' => '/var/www/nextcloud/data',`. Use `sed` to easily make ths change:

    sudo sed -i "s/owncloud\/data/nextcloud\/data/g" config/config.php

**NOTE:** Normally, `sed` streams output to the screen, but the `-i` flag tells it to modify the file in place. For information about how to use regular expressions, see [An Introduction To Regular Expressions](an-introduction-to-regular-expressions). And for more on `sed`, look at [The Basics of Using the Sed Stream Editor to Manipulate Text in Linux](the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux).

Now use `occ` to put Nextcloud into maintenance mode. This locks down the files so no changes can be made externally while you upgrade the application. Run the following command to turn on maintenance mode:

    sudo -u www-data php occ maintenance:mode --on

Note that this uses `sudo` to run commands as the **www-data** user.

You’ll see this output so you can confirm that maintenance mode is turned on:

    [secondary_output]
    Nextcloud or one of the apps require upgrade - only a limited number of commands are available
    You may use your browser or the occ upgrade command to do the upgrade
    Maintenance mode enabled

Next, use `occ` to initiate the internal upgrade process:

    sudo -u www-data php occ upgrade

This command displays a lot of output as it migrates all of the ownCloud data to Nextcloud, but in the end you’ll see the following messages:

    Output...
    
    Starting code integrity check...
    Finished code integrity check
    Update successful
    Maintenance mode is kept active
    Reset log level

If there were problems with the upgrade, the output will give you some feedback about what went wrong and how to solve the problem. Assuming the upgrade went smoothly its time to turn off maintenance mode.

    sudo -u www-data php occ maintenance:mode --off

Your ownCloud installation has now been migrated to Nextcloud, but it may still be out-of-date. If you migrated ownCloud 9 you will have only migrated to Nextcloud 10, but there is still a newer version so let’s upgrade.

## Step 6 — Upgrading Nextcloud

To upgrade Nextcloud to a new major version, you use the same procedure you used in Steps 3 through 5 of this tutorial. First, move your currently installed Nextcloud folder out of the way with this command:

    sudo mv /var/www/nextcloud /var/www/nextcloud.old

Then find the `.tar.gz` file from the [Nextcloud release site](https://download.nextcloud.com/server/releases/), download it, and check its MD5 checksum just as you did in Step 3.

    wget https://download.nextcloud.com/server/releases/nextcloud-11.0.0.tar.bz2
    wget https://download.nextcloud.com/server/releases/nextcloud-11.0.0.tar.bz2.md5
    md5sum nextcloud-11.0.0.tar.bz2
    cat nextcloud-11.0.0.tar.bz2.md5

Once you’ve downloaded and verified the archive. unpack it and move it to the Nextcloud location on the web server:

    tar xfv nextcloud-11.0.0.tar.bz2
    mv nextcloud /var/www/nextcloud

Next, move the configuration and data files from the old installation to the new one as you did in Step 4:

    rm -rf /var/www/nextcloud/config /var/www/nextcloud/data 
    mv /var/www/nextcloud.old/config /var/www/nextcloud
    mv /var/www/nextcloud.old/data /var/www/nextcloud
    sudo chown -R www-data:www-data /var/www/nextcloud/

Finally, use `occ` to perform the upgrade:

    sudo -u www-data php occ maintenance:mode --on
    sudo -u www-data php occ upgrade
    sudo -u www-data php occ maintenance:mode --off

Repeat these steps for each major version of Nextcloud you need to upgrade through.

Now that everything is up-to-date, we can configure the web server to send traffic to Nextcloud.

## Step 7 - Modifying the Web Server’s Traffic Flow

The Apache web server directs to different directories through the use of virtual hosts, or vhosts. The folder `/etc/apache2/sites-available/` contains a description of each vhost that is configured for the server. These vhosts are enabled by linking their associated files to the `/etc/apache2/sites-enabled/` folder. The file `/etc/apache2/sites-available/000-owncloud.conf` configures the server to read the `/var/www/owcloud` and that configuration is enabled by the link located at `/etc/apache2/sites-enabled/000-owncloud.conf`.

To convert the server to use the Nextcloud installation, create a copy of the ownCloud vhost configuration, edit it to point at Nextcloud, disable the ownCloud vhost, and enable the Nextcloud vhost.

Fist copy the ownCloud configuration file:

    sudo cp /etc/apache2/sites-available/000-owncloud.conf /etc/apache2/sites-available/000-nextcloud.conf

Next, replace all instances of `owncloud` in the configuration file with `nextcloud`. You can do this by opening `/etc/apache2/sites-available/000-nextcloud.conf` with a text editor and making the changes yourself, or by using regular expressions and the `sed` command.

Run the following command to convert the contents of the vhost configuration file with `sed`:

    sudo sed -i "s/owncloud/nextcloud/g" /etc/apache2/sites-available/000-nextcloud.conf  

Next, disable the ownCloud vhost by deleting the link `/etc/apache2/sites-enabled/000-owncloud.conf`. Ubuntu provides the `a2dissite` command to disable sites. Execute this command:

    sudo a2dissite 000-owncloud.conf

Finally, enable the Nextcloud vhost by creating a symbolic link to the Nextcloud configuration file. Use the `a2ensite` command to create the link:

    sudo a2ensite 000-nextcloud.conf

**Note:** If you access ownCloud through HTTPS, you will also need to repeat these steps with the `/etc/apache2/sites-available/owncloud-ssl.conf` vhost.

Now that the web server knows where to find Nextcloud, we can start it back up with this command:

    sudo service apache2 start

At this point everything should be up and running with your new Nextcloud installation. Open up a web browser and navigate to the location of your old ownCloud server and you’ll see the Nextcloud login screen. All of your old user names and passwords will work just as they did before the migration. Log in as the **admin** user, as you may need to re-enable some of your apps, including the Calendar and Contacts apps.

## Conclusion

In this tutorial you backed up your previous ownCloud installation, migrated to Nextcloud, and disabled ownCloud. You can now log into Nextcloud using the web interface just as you did with ownCloud.

Now that your server has been migrated to Nextcloud, it is time to update any sync clients you are using. Just like ownCloud, Nextcloud provides a number of syncing clients for your desktop and mobile devices.

If you decide to switch back to ownCloud you can restore the `data/` and `config/` folders from the backup you created in Step 1, as well as any external database you backed up. Do not try to copy the `data/` and `config/` folders from `/var/www/nextcloud` back to ownCloud. Once the backups have been restored, all you have to do is disable the Nextcloud vhost and enable the ownCloud one, using the same procedure in Step 4.
