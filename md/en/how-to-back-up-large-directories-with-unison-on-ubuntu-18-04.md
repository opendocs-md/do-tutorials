---
author: Elliot Cooper
date: 2019-05-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-large-directories-with-unison-on-ubuntu-18-04
---

# How To Back Up Large Directories with Unison On Ubuntu 18.04

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Unison](https://www.cis.upenn.edu/%7Ebcpierce/unison/index.html) is an open-source file synchronization tool. It is very efficient at backing up large corpuses of data where only a few files have been added or updated. This situation occurs in, for example, a corporate [Samba](https://www.samba.org/) file server or an email server.

The majority of the files in these servers will remain the same while a small number will be added or modified each day. Unison is able to discover and back up these new files extremely rapidly—even when there are millions of files and terabytes of data. In these situations, traditional tools like [`rsync`](https://en.wikipedia.org/wiki/Rsync) can take a longer time to perform the same backup operation.

In this tutorial, you will install and configure Unison on a pair of servers and use it to back up a directory. You will also configure Unison to use SSH as the secure communication protocol and create a [cron job](https://help.ubuntu.com/community/CronHowto) to periodically run Unison.

## Prerequisites

Before you begin this guide, you’ll need the following:

- Two Ubuntu 18.04 servers, configured using the [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) guide.
- You should be familiar creating a crontab entry by reading the [How To Use Cron To Automate Tasks On a VPS](how-to-use-cron-to-automate-tasks-on-a-vps) guide.

This guide will use two servers:

- **primary** server: The server that hosts the data that you will back up.
- **backup** server: The server that will host the backed up data.

## Step 1 — Creating Additional Non-Root Users

The [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) tutorial guided you through creating a non-root sudo user called **sammy** on both the **primary** and **backup** server. In this step, you will create two new users, one on the **primary** server and one on the **backup** server. This prevents confusion as you work through the guide, and an alternative non-root sudo user is required on the **backup** server if the SSH security configuration is enabled at the end of the guide.

You will need to log in to both the **primary** and the **backup** server as the **sammy** user over SSH in two terminal windows. The following two SSH commands will log you into these servers:

    ssh sammy@primary_server_ip
    ssh sammy@backup_server_ip

First, on the **primary** server create a new user called **primary\_user** with this command:

    sudo adduser primary_user

Then give them `sudo` access rights:

    sudo usermod -aG sudo primary_user

Finally, change accounts to the **primary\_user** :

    su - primary_user

Next, follow the same steps on the **backup** server, but create a new user called **backup\_user**. Make sure you are logged into the **primary** and **backup** servers as these users for the rest of the guide.

Now that you have created the necessary users on both servers, you can move on to installing the Unison software.

## Step 2 — Installing Unison on Both Servers

In this step, you will install the Unison package on both of the servers.

You will use the Ubuntu package manager `apt` to install Unison on both servers. When using `apt` for the first time in a while, you should update the local package index with the following command:

    sudo apt-get update

This ensures that you will install the latest version of Unison. This will also help to avoid installation errors.

Next, install Unison:

    sudo apt-get install unison

You have now completed the installation of Unison. In the next step, you will configure SSH so that Unison is able to communicate between the two servers.

## Step 3 — Creating SSH Keys and Configuring SSH

The first thing you will need to do is to create an SSH key pair on the **primary** server as you will use key-based authentication for the SSH connection. The advantage of key-based authentication is that a secure connection is possible without entering a password. This is important because you will create an automated backup procedure that must take place without you entering a password every time it occurs.

Once you have that key pair on the **primary** server, you will copy the public key to the **backup** server and then test that Unison is able to communicate between the servers using SSH.

Start by ensuring that the `.ssh` directory exists:

    mkdir .ssh

Run the following command from the **primary\_user** home directory on the **primary** server to generate a SSH key pair:

    ssh-keygen -t rsa -b 4096 -f .ssh/unison-primary

When you create an SSH key pair, you usually use a strong password. However, Unison will run automatically, so a password can’t be manually entered each time it runs. Hit the `ENTER` key without entering a password. This will generate a passwordless SSH key pair.

The options used here mean the following:

- `-t rsa`: This sets the type of key that will be created. RSA keys are the most compatible type.
- `-b 4096`: This sets the length of the key. The longer a key is, the more secure it is. A key length of `4096` is the current recommended key length for RSA keys.
- `-f .ssh/unison-primary`: This sets the name of the key and the location where it will be saved. In this case, you will save the key into SSH’s default directory, `.ssh`, using a name of your choice.

The preceding command creates the public and private SSH keys in the following two files:

- `.ssh/unison-primary`
- `.ssh/unison-primary.pub`

The first is the private SSH key and the second is the public key. You need to copy the contents of the public key file to the **backup** server. The easiest way to display the contents of the public key file for copying is to use the `cat` command to print the contents to the terminal:

    cat .ssh/unison-primary.pub

On the **backup** server in the **backup\_user** home directory, open the `.ssh/authorized_keys` file with a text editor. Here, you will use `nano`:

    nano .ssh/authorized_keys

Paste the public key into the editor, then save and exit.

You can now test that the SSH configuration is working by logging into the **backup** from the **primary** server via SSH. This is important because you will need to accept and save the SSH server’s key fingerprint of the **backup** server or Unison will not work. In your terminal on the **primary** server, run the following command from the **primary\_user** ’s home directory:

    ssh -i .ssh/unison-primary backup_user@backup_server_ip

The `-i .ssh/unison-primary` option instructs SSH to use a specific key or identity file. Here you will use the new `unison-primary` key you created.

Accept the fingerprint by pressing `Y` and then `ENTER`, and log in and out. You just needed to confirm that SSH works between the servers and save the **backup** server’s SSH fingerprint. The fingerprint can only be saved manually, so it has to be done before the process is automated later in the tutorial.

Next, check that Unison will connect by running the following command from the **primary\_user** home directory on the **primary** server:

    ssh -i .ssh/unison-primary backup_user@backup_server_ip unison -version

In this command, you used the same SSH command you used to test the connection with the addition of the `unison` command at the end. When a command is placed at the end of an SSH connection, SSH will log in, run the command, and then exit. The `unison -version` command instructs Unison to print its version number.

If everything is working you will see a response showing the version of Unison on the **backup** server:

    Outputunison version 2.48.3

Now that you have confirmed that Unison can communicate between the servers using the SSH keys, you are ready to move on to configuring Unison.

## Step 4 — Configuring Unison

In this step, you will configure Unison to run a simple one-way backup on a directory from the **primary** server to the **backup** server.

To configure Unison, you first need to create the configuration directory under the **primary\_user** ’s home directory on the **primary** server:

    mkdir .unison

Next, you need to open a new file with the name `default.prf` in a text editor in the `.unison` directory. This file contains the Unison configuration. Open the file with the following command:

    nano .unison/default.prf

Then enter the following:

.unison/default.prf

    force = /home/primary_user/data
    sshargs = -i /home/primary_user/.ssh/unison-primary

The meaning of these lines is as follows

- `force`: This ensures that changes are only pushed from the **primary** server to the **backup** server. The `/home/primary_user/data` path is the location of the directory that holds the data that you want to back up.
- `sshargs`: This option instructs Unison to use the SSH key you generated.

If the directory that holds the data that you want to back up is not under the **primary\_user** home directory, then you must make sure that it is readable and writable by the **primary\_user**. If you aren’t familiar with Linux ownership and permissions, check out the [Introduction to Linux Permissions](an-introduction-to-linux-permissions) guide to learn more.

You’ve now configured Unison and can move on to testing it by backing up a directory.

## Step 5 — Backing Up a Directory With Unison

You are ready to back up a directory now that Unison is configured. You will back up the `/home/primary_user/data` directory on the **primary** server to the `/home/backup_user/data/` directory on the **backup** server. The directory that contains the data to back up must be the same directory that you put in the `.unison/default.prf` next to the force option.

You will need some data to back up to test that Unison is working. Create some empty files on the **primary** server, and then check if Unison transferred them to the **backup** server.

First, create the directory that will hold the data to back up by running the following command from the **primary\_user** home directory:

    mkdir /home/primary_user/data

Next, use the `touch` command to create five empty files:

    touch /home/primary_user/data/file{1..5}

The final part of the command, `file{1..5}`, uses Bash brace expansion to create the five files. When bash is given `{1..5}`, it automatically fills in the missing numbers, `2`, `3`, and `4`. This technique is useful to quickly enumerate multiple files.

Now that you have the `data` directory and some test files to back up, you can run Unison to back up the files to the **backup** server. The following command will do this:

    unison -batch -auto /home/primary_user/data ssh://backup_user@backup_server_ip//home/backup_user/data

These options do the following:

- `batch` - Run without asking any questions.
- `auto` - Automatically accept any non-conflicting actions.

As you are using Unison in a simple, one-way sync mode, you will not have to resolve any conflicts. This means that you can safely set these options.

A conflict can occur only during Unison’s other mode of operation, where it syncs in both directions. Such a use case would be syncing a directory on someone’s laptop and desktop. When they update a file on the desktop, they want that change pushed to the laptop and vice versa. A conflict occurs if the same file is modified at both ends before a Unison sync occurs, and Unison cannot automatically decide which file to keep and which to overwrite.

In a one-way push mode, the data on the **primary** is always retained and the data on the backup is overwritten.

This command will print a long message the first time that it is run. The message reads as follows:

    OutputContacting server...
    Connected [//primary_server_ip//home/primary_user/data -> //primary_server_ip//home/backup_user/data]
    Looking for changes
    Warning: No archive files were found for these roots, whose canonical names are:
            /home/primary_user/data
            //backup_server_ip//home/backup_user/data
    This can happen either
    because this is the first time you have synchronized these roots, 
    or because you have upgraded Unison to a new version with a different
    archive format.  
    
    Update detection may take a while on this run if the replicas are 
    large.
    
    Unison will assume that the 'last synchronized state' of both replicas
    was completely empty. This means that any files that are different
    will be reported as conflicts, and any files that exist only on one
    replica will be judged as new and propagated to the other replica.
    If the two replicas are identical, then no changes will be reported.
    
    If you see this message repeatedly, it may be because one of your machines
    is getting its address from DHCP, which is causing its host name to change
    between synchronizations. See the documentation for the UNISONLOCALHOSTNAME
    environment variable for advice on how to correct this.
    
    Donations to the Unison project are gratefully accepted: 
    http://www.cis.upenn.edu/~bcpierce/unison
    
      Waiting for changes from server
    Reconciling changes
    dir ----> /  
    Propagating updates
    UNISON 2.48.3 started propagating changes at 16:30:43.70 on 03 Apr 2019
    [BGN] Copying from /home/primary_user/data to //backup_server_ip//home/backup_user/data
    [END] Copying  
    UNISON 2.48.3 finished propagating changes at 16:30:43.71 on 03 Apr 2019
    Saving synchronizer state
    Synchronization complete at 16:30:43 (1 item transferred, 0 skipped, 0 failed)

This information is warning that this is the first synchronization. It also provides tips on how to resolve an issue if you see this message for every synchronization run. The last section tells you what data Unison synced during this run.

On each subsequent run, it will print much less information. Here is the output when no files have been updated:

    OutputContacting server...
    Connected [//primary_server_ip//home/primary_user/data -> //backup_server_ip//home/backup_user/data]
    Looking for changes
      Waiting for changes from server
    Reconciling changes
    Nothing to do: replicas have not changed since last sync.

This is the output when `/data/file1` is modified on the **primary** server:

    OutputContacting server...
    Connected [//primary_server_ip//home/primary_user/data -> //backup_server_ip//home/backup_user/data]
    Looking for changes
      Waiting for changes from server
    Reconciling changes
    changed ----> file1  
    Propagating updates
    UNISON 2.48.3 started propagating changes at 16:38:37.11 on 03 Apr 2019
    [BGN] Updating file file1 from /home/primary_user/data to //backup_server_ip//home/backup_user/data
    [END] Updating file file1
    UNISON 2.48.3 finished propagating changes at 16:38:37.16 on 03 Apr 2019
    Saving synchronizer state
    Synchronization complete at 16:38:37 (1 item transferred, 0 skipped, 0 failed)

After each synchronization run, the **backup** server will an exact copy of the `data` directory on the **primary** server.

**Warning:** Any new files or changes in the `data` directory on the **backup** server will get lost when you run Unison.

You are now able to run Unison to back up a directory. In the next step, you will automate the backup process by running Unison with _cron_.

## Step 6 — Creating a Unison Cron Job

In this section, you will create a [cron](how-to-use-cron-to-automate-tasks-on-a-vps) job that will run Unison and back up the `data` directory to the **backup** server at a specified frequency.

The _crontab_ is a file that is read by the cron process. The commands it contains are loaded into the cron process and are executed at the specified intervals.

You can view the contents of the crontab for your current user by running the following command:

    crontab -l

The `-l` option lists the contents of the current user’s crontab. If you have not edited the crontab for this user before, you will see the following error message because no crontab file exists yet:

    Outputno crontab for primary_user

Next, run the `crontab` command on the **primary** server with the `-e` flag to open it in edit mode:

    crontab -e

If you don’t have a default command line editor configured, you will be asked to select an editor the first time you run the command. Select the editor of your choice to open the crontab.

Once you have the crontab open, add the following command to the first empty line under the existing text:

    ...
    * */3 * * * /usr/bin/unison -log -logfile /var/log/unison.log -auto -batch -silent /home/primary_user/data ssh://backup_user@backup_server_ip//home/backup_user/data

The command you will use is almost the same as the one you used in Step 5 for the manual backup, but with some additional options. These additional options are as follows:

- `-silent`: Disables all output except errors. Normal output is not required when Unison is executed from the crontab as there is no one to read it.
- `-log`: Instructs Unison to log its actions.
- `-logfile`: Specifies where Unison will log its actions. In this example, Unison is run every 3 hours. You can change this to any frequency that better meets your requirements.

Whenever you edit the crontab, you must always put an empty line at the bottom before you save and exit or cron may not load the crontab file correctly. This could cause the commands to not be executed.

Once you’ve made these changes, save and close the file.

Next, create the log file that Unison will write to on the **primary** server. The following command will create this file:

    sudo touch /var/log/unison.log

Next, make the **primary\_user** the owner of the file.

    sudo chown primary_user /var/log/unison.log

You can check the status of the Unison backups by reading the log file at `/var/log/unison.log`. Unison will only log something when it has either backed up a new or updated file or if it encountered an error.

Unison is now backing up periodically from the crontab. The last and optional step is to make the SSH configuration more secure.

## Step 7 (Optional) — Securing SSH

In this guide, you have created and used an SSH key that does not have a password. This is a security concern that you can address by limiting what the **backup\_user** is able to do when they log in via SSH to the **backup** server.

You will do this by configuring SSH to only allow the **backup\_user** to execute a single command when logged in over SSH. This means that the SSH key that you created can only be used to execute the Unison backups and nothing else. This has the consequence that you will not be able to SSH into the **backup** server as the **backup\_user**. This is because logging in requires more than the single permitted command.

If you need to access the **backup** server as the **backup\_user** you should log in as the **sammy** user first, and then change to the **backup\_user** using `su - backup_user`.

Edit the SSH configuration file on the **backup** server at `/etc/ssh/sshd_config`:

    sudo nano /etc/ssh/sshd_config

Then add the following lines to the bottom of the file:

/etc/ssh/sshd\_config

    Match User backup_user
      ForceCommand unison -server

These configuration options mean the following:

- `Match User`: When the listed user logs in, SSH will apply the following and indented configuration option.
- `ForceCommand`: This restricts the matched user to the following command. In this case, the **backup\_user** can only run the `unison -server` command.

Save and exit your text editor. Next, reload the SSH service to enable the new configuration:

    sudo systemctl reload ssh.service

You can test this by trying to log in to the **backup** server as the **backup\_user** over SSH from the **primary** server.

    $ ssh -i .ssh/unison-primary backup_user@backcup_server_ip

If the `/etc/ssh/sshd_config` settings are working, you will see the following:

    OutputUnison 2.48

The SSH session will hang until the session is killed with with `CTRL + C` because Unison is waiting for a command.

This shows that the Unison server was invoked automatically on log in and no other access is possible outside of communicating with the Unison server.

You now have a working and secure Unison backup system that will back up your data as often as you want it to.

## Conclusion

In this guide, you installed and configured the Unison file synchronization software to back up a directory over SSH. You also configured cron to automatically run backups at a specified schedule and secured SSH so the passwordless key cannot be abused.

When determining if you should use Unison, there are a few things that you should consider:

- Unison may not be the best choice when you have smaller numbers of files or lower amounts of data. In this case, rsync would be a more appropriate choice. You can read more about using rsync in the [How To Use Rsync to Sync Local and Remote Directories on a VPS](how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps) guide.
- Backing up large amounts of data can take a long time and may use up your bandwidth allocation over public network interfaces. If your **primary** and **backup** servers are both DigitalOcean Droplets, then you will be able to complete the Unison backup much more rapidly and securely if you use a private network. For more information on the free DigitalOcean private networks, please see the [Private Network Overview](https://www.digitalocean.com/docs/networking/private-networking/overview/) documentation.
