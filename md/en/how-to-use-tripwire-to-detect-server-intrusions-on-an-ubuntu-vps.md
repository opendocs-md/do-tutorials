---
author: Justin Ellingwood
date: 2014-01-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-tripwire-to-detect-server-intrusions-on-an-ubuntu-vps
---

# How To Use Tripwire to Detect Server Intrusions on an Ubuntu VPS

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

## Introduction

* * *

Security is an incredibly complex problem when administering online servers. While it is possible to configure firewalls, fail2ban policies, secure services, and lock down applications, it is difficult to know for sure if you have effectively blocked every attack.

A host-based intrusion detection system (HIDS), works by collecting details about your computer’s filesystem and configuration. It then stores this information to reference and validate the current state of the system. If changes are found between the known-good state and the current state, it could be a sign that your security has been compromised.

A popular host-based intrusion detection system on Linux is **tripwire**. This software can keep track of many different filesystem data points in order to detect whether unauthorized changes have occurred.

In this article, we will discuss how to install and configure tripwire on an Ubuntu 12.04 installation. Due to the nature of intrusion detection systems, it is best to run through this guide shortly after creating your server, so that you can verify that the filesystem is clean.

## Install Tripwire

* * *

Fortunately, tripwire can be found in Ubuntu’s default repositories. We can install it with `apt-get` by typing:

    sudo apt-get update
    sudo apt-get install tripwire

This installation will run through quite a bit of configuration of the packages that are required.

First, it will configure the mail application that is being pulled in as a dependency. If you want to configure email notifications, select “internet site”.

It will ask you if you want to select passphrases during installation. Select “yes” to both of these prompts. It will ask if it can rebuild the configuration file. Select “yes”. It will ask a similar question about the policy file. Again, answer “yes”.

Next, you will be asked to choose and confirm a site key passphrase. Tripwire uses two keys to secure its configuration files.

- **site key** : This key is used to secure the configuration files. We need to ensure that the configuration files aren’t modified, or else our entire detection system cannot be trusted. Since the same configuration files can be used for multiple servers, this key can be used across servers.

- **local key** : This key is used on each machine to run the binaries. This is necessary to ensure that our binaries are not run without our consent.

You will first choose and confirm a passphrase for the site key, and then for the local key. Make sure you choose strong passphrases.

## Initialize the Database

* * *

Following the installation, you must initialize and configure your installation. Like most security programs, tripwire is shipped with generic, but strict defaults that may need to be fine-tuned for your specific installation.

First, if you did not choose yes to create a policy file during installation, you can do so now by issuing the command:

    sudo twadmin --create-polfile /etc/tripwire/twpol.txt

You will be prompted for the site passphrase you configured earlier.

This creates an encrypted policy file from the plain text one that we specified in the `/etc/tripwire/` directory. This encrypted file is what tripwire actually reads when running its checks.

We can now initialize the database that tripwire will use to validate our system. This uses the policy file that we just initiated and checks the points that are specified within.

Because this file has not been tailored for our system yet, we will have a lot of warnings, false positives, and errors. We will use these as a reference to fine-tune our configuration file in a moment.

The basic way to initialize the database is by running:

    sudo tripwire --init

This will create our database file and complain about the things that we must adjust in the configuration.

Because we want to save the results to inform our configuration decisions, we can grab any instance where it mentions a file, and put it in a file in the tripwire configuration directory. We can run the check and place the files listed into a file called `test_results` in our tripwire config directory:

    sudo sh -c 'tripwire --check | grep Filename > test_results'

If we view this file, we should see entries that look like this:

    less /etc/tripwire/test_results

* * *

    Filename: /etc/rc.boot
    Filename: /root/mail
    Filename: /root/Mail
    Filename: /root/.xsession-errors
    . . .

## Configure the Policy File to Match Your System

* * *

Now that we have a list of files that are setting off tripwire, we can go through our policy file and edit it to get rid of these false positives.

Open the plain text policy in your editor with root privileges:

    sudo nano /etc/tripwire/twpol.txt

Do a search for each of the files that were returned in the `test_results` file. Comment out all of the lines that you find that match.

In the “Boot Scripts” section, you should comment out the `/etc/rc.boot` line, since this isn’t present in an Ubuntu system:

    ( rulename = "Boot Scripts", severity = $(SIG\_HI) ) { /etc/init.d -\> $(SEC\_BIN) ; #/etc/rc.boot -\> $(SEC\_BIN) ; /etc/rcS.d -\> $(SEC\_BIN) ;

There were a lot of files in the `/root` home directory that needed to be commented out on my system. Anything that is not present on your system should be commented out:

    ( rulename = "Root config files", severity = 100 ) { /root -\> $(SEC\_CRIT) ; # Catch all additions to /root #/root/mail -\> $(SEC\_CONFIG) ;#/root/Mail -\> $(SEC\_CONFIG) ;#/root/.xsession-errors -\> $(SEC\_CONFIG) ;#/root/.xauth -\> $(SEC\_CONFIG) ;#/root/.tcshrc -\> $(SEC\_CONFIG) ;#/root/.sawfish -\> $(SEC\_CONFIG) ;#/root/.pinerc -\> $(SEC\_CONFIG) ;#/root/.mc -\> $(SEC\_CONFIG) ;#/root/.gnome\_private -\> $(SEC\_CONFIG) ;#/root/.gnome-desktop -\> $(SEC\_CONFIG) ;#/root/.gnome -\> $(SEC\_CONFIG) ;#/root/.esd\_auth -\> $(SEC\_CONFIG) ;#/root/.elm -\> $(SEC\_CONFIG) ;#/root/.cshrc -\> $(SEC\_CONFIG) ; /root/.bashrc -\> $(SEC\_CONFIG) ; #/root/.bash\_profile -\> $(SEC\_CONFIG) ;#/root/.bash\_logout -\> $(SEC\_CONFIG) ; /root/.bash\_history -\> $(SEC\_CONFIG) ; #/root/.amandahosts -\> $(SEC\_CONFIG) ;#/root/.addressbook.lu -\> $(SEC\_CONFIG) ;#/root/.addressbook -\> $(SEC\_CONFIG) ;#/root/.Xresources -\> $(SEC\_CONFIG) ;#/root/.Xauthority -\> $(SEC\_CONFIG) -i ; # Changes Inode number on login#/root/.ICEauthority -\> $(SEC\_CONFIG) ;}

The last part of my check was complaining about file descriptors in the `/proc` filesystem. These files change all of the time, so will trigger false positives regularly if we leave the configuration as is.

In the “Devices & Kernel information” section, you can see that the `/proc` filesystem is listed to be checked.

    (
      rulename = "Devices & Kernel information",
      severity = $(SIG_HI),
    )
    {
            /dev -> $(Device) ;
            /proc -> $(Device) ;
    }

However, this will check every file under it. We don’t particularly want that. Instead, we will remove this specification, and add configuration options for all of the directories under `/proc` that we _do_ want to check:

    { /dev -\> $(Device) ; #/proc -\> $(Device) ; /proc/devices -\> $(Device) ; /proc/net -\> $(Device) ; /proc/tty -\> $(Device) ; /proc/sys -\> $(Device) ; /proc/cpuinfo -\> $(Device) ; /proc/modules -\> $(Device) ; /proc/mounts -\> $(Device) ; /proc/dma -\> $(Device) ; /proc/filesystems -\> $(Device) ; /proc/interrupts -\> $(Device) ; /proc/ioports -\> $(Device) ; /proc/scsi -\> $(Device) ; /proc/kcore -\> $(Device) ; /proc/self -\> $(Device) ; /proc/kmsg -\> $(Device) ; /proc/stat -\> $(Device) ; /proc/loadavg -\> $(Device) ; /proc/uptime -\> $(Device) ; /proc/locks -\> $(Device) ; /proc/meminfo -\> $(Device) ; /proc/misc -\> $(Device) ; }

While we are in this portion of the file, we also want to do something with the `/dev/pts` filesystem. Tripwire will not check that location by default because it is told to check `/dev`, and `/dev/pts` is on a separate filesystem, which it will not enter unless specified. To get tripwire to check this as well, we can explicitly name it here:

    { /dev -\> $(Device) ; /dev/pts -\> $(Device) ; #/proc -\> $(Device) ; /proc/devices -\> $(Device) ; /proc/net -\> $(Device) ; /proc/tty -\> $(Device) ; . . .

The last thing we will comment out are the `/var/run` and `/var/lock` lines so that our system does not flag normal filesystem changes by services:

    ( rulename = "System boot changes", severity = $(SIG\_HI) ) { #/var/lock -\> $(SEC\_CONFIG) ;#/var/run -\> $(SEC\_CONFIG) ; # daemon PIDs /var/log -\> $(SEC\_CONFIG) ; }

Save and close the file when you are finished editing.

Now that our file is configured, we need to implement it by recreating the encrypted policy file that tripwire actually reads:

    sudo twadmin -m P /etc/tripwire/twpol.txt

After this is created, we must reinitialize the database to implement our policy:

    sudo tripwire --init

* * *

    Please enter your local passphrase:
    Parsing policy file: /etc/tripwire/tw.pol
    Generating the database...
    ***Processing Unix File System***
    Wrote database file: /var/lib/tripwire/tripit.twd
    The database was successfully generated.

All of the warnings that you received earlier should be gone now. If there are still warnings, you should continue editing your `/etc/tripwire/twpol.txt` file until they are gone.

## Verify the Configuration

* * *

If your database initialization didn’t complain about any files, then your configuration should match your system at this point. But we should run a check to see what the tripwire report looks like and if there are truly no warnings:

The basic syntax for a check is:

    sudo tripwire --check

You should see a report output to your screen specifying that there were no errors or changes found on your system.

Once this is complete, you can be fairly confident that your configuration is correct. We should clean up our files a bit to remove sensitive information from our system.

We can delete the `test_results` file that we created:

    sudo rm /etc/tripwire/test_results

Another thing that we can do is remove the actual plain text configuration files. We can do this safely because they can be generated at-will from the encrypted files with our password.

All we have to do to regenerate the plain text file is pass the encripted file to twadmin, in much the same way that we did to generate the encrypted version. We just pipe it into a plain text file again:

    sudo sh -c 'twadmin --print-polfile > /etc/tripwire/twpol.txt'

Test this now by moving the text version to a backup location and then recreate it:

    sudo mv /etc/tripwire/twpol.txt /etc/tripwire/twpol.txt.bak
    sudo sh -c 'twadmin --print-polfile > /etc/tripwire/twpol.txt'

If it worked correctly, you can safely remove the plain text files now:

    sudo rm /etc/tripwire/twpol.txt
    sudo rm /etc/tripwire/twpol.txt.bak

## Set Up Email Notifications

* * *

We will configure tripwire to run every day and also implement automatic notifications. During the process, we can test how to update the database when we make changes to our system.

We will use the `mail` command to mail our notifications to our email address. This is not installed on our system currently, so we will have to download it from the repositories.

This gives us a great opportunity to see how tripwire reacts to changes in the system.

Install the files like this:

    sudo apt-get install mailutils

Now that we have that command installed, let’s do a test of our system’s ability to mail out a tripwire report. This report will have warnings and changes too, since we just installed new software without telling tripwire:

    sudo tripwire --check | mail -s "Tripwire report for `uname -n`" your\_email@domain.com

You should receive a report shortly in your email with details about the new mail software you just installed to send the message! This is good. It means that tripwire is picking up changes in the filesystem and that our mail software is working as well.

We should now “okay” the software changes we made by doing an interactive check to update the database.

We can do this by typing:

    sudo tripwire --check --interactive

This will run the same tests as normal, but at the end, instead of outputting the report to the screen, it is copied into a text file and opened with the default editor.

This report goes into quite a lot of detail about each file that changed. In fact, on my machine, the report generated was 2,275 lines long. This amount of information is extremely helpful in the event of a real security problem, but in our case, it’s generally probably not too interesting for the most part.

The important part is near the top. After some introductory information, you should see some lines with check boxes for each of the added or modified files:

    Rule Name: Other binaries (/usr/sbin)
    Severity Level: 66
    -------------------------------------------------------------------------------
    
    Remove the "x" from the adjacent box to prevent updating the database
    with the new values for this object.
    
    Added:
    [x] "/usr/sbin/maidag"
    
    Modified:
    [x] "/usr/sbin"
    . . .

These check boxes indicate that you want to update the database to allow these changes. You should search for every box that has an “x” in it and verify that those are changes that you made or are okay with.

If you are not okay with a change, you can remove the “x” from the box and that file will not be updated in the database. This will cause this file to still flag tripwire on the next run.

After you have decided on which file changes are okay, you can save and close the file.

At this point, it will ask for your local passphrase so that tripwire can update its database files.

If we accepted all of the changes, if we re-run this command, the report should be much shorter now and list no changes.

## Automate Tripwire with Cron

* * *

Now that we have verified that all of this functionality works manually, we can set up a cron job to execute a tripwire check every morning.

We will be using root’s crontab, because edits to the system cronjob can get wiped out with system updates.

Check to see if root already has a crontab by issuing this command:

    sudo crontab -l

If a crontab is present, you should pipe it into a file to back it up:

    sudo sh -c 'crontab -l > crontab.bad'

Afterwards, we can edit the crontab by typing:

    sudo crontab -e

If this is your first time running crontab, it will ask you which editor you wish to use. If you don’t have a preference for another editor, nano is typically a safe choice.

Afterwards, you will be taken to a file where we can automate tripwire. Since we will be running tripwire daily, we only need to decide what time we want it to run. Typically, services are run in non-peak times to not disrupt busy hours.

The format we need to use is `min hour * * * command`. The command that we want to use is the same one we used to mail our report before. We don’t need to use sudo since this is going to be run as root.

To have tripwire run at 3:30am every day, we can place a line like this in our file:

    30 3 \* \* \* /usr/sbin/tripwire --check | mail -s "Tripwire report for `uname -n`" your\_email@domain.com

You can adjust this to your preference.

## Conclusion

* * *

You should now have an automated intrusion detection system that sends you reports regarding changes on your filesystem. You should review the emailed reports regularly and take action where there are changes detected, either in updating the tripwire database to okay the changes, or investigating suspicious activity.

By Justin Ellingwood
