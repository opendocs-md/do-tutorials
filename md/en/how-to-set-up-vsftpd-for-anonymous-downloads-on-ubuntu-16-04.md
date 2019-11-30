---
author: Melissa Anderson
date: 2016-08-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-vsftpd-for-anonymous-downloads-on-ubuntu-16-04
---

# How To Set Up vsftpd for Anonymous Downloads on Ubuntu 16.04

## Introduction

FTP, short for File Transfer Protocol, is a network protocol that was once widely used for moving files between a client and server. It has since been replaced by faster, more secure, and more convenient ways of delivering files. Many casual Internet users expect to download directly from their web browser with `https` and command-line users are more likely to use secure protocols such as the `scp` or [sFTP](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server).

FTP is often used to support legacy applications and workflows with very specific needs. If you have a choice of what protocol to use, consider exploring the more modern options. When you do need FTP, though, vsftpd is an excellent choice. Optimized for security, performance and stability, vsftpd offers strong protection against many security problems found in other FTP servers and is the default for many Linux distributions.

In this tutorial, we’ll show you how to set up vsftpd for an anonymous FTP download site intended to widely distribute public files. Rather than using FTP to manage the files, local users with `sudo` privileges are expected to use `scp`, `sFTP`, or any other secure protocol of their choice to transfer and maintain files.

## Prerequisites

To follow along with this tutorial you will need:

- **An Ubuntu 16.04 server with a non-root user with `sudo` privileges** : You can learn more about how to set up a user with these privileges in our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide.

Once you have the server in place, you’re ready to begin.

## Step 1 — Installing vsftpd

We’ll start by updating our package list and installing the `vsftpd` daemon:

    sudo apt-get update
    sudo apt-get install vsftpd

When the installation is complete, we’ll copy the configuration file so we can start with a blank configuration, saving the original as a backup.

    sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.orig

With a backup of the configuration in place, we’re ready to configure the firewall.

## Step 2 — Opening the Firewall

First, let’s check the firewall status to see if it’s enabled and if so, to see what’s currently permitted so that when it comes time to test the configuration, you won’t run into firewall rules blocking you.

    sudo ufw status

In our case, we see the following:

    OutputOutput
    Status: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

You may have other rules in place or no firewall rules at all. In this example, only `ssh` traffic is permitted, so we’ll need to add rules for FTP traffic.

With many applications, you can use `sudo ufw app list` and enable them by name, but FTP is not one of those. Because ufw also checks /etc/services for the port and protocol of a service, we can still add FTP by name. We need both `ftp-data` on port 20 and `ftp` (for commands) on port 21:

    sudo ufw allow ftp-data
    sudo ufw allow ftp
    sudo ufw status

Now our firewall rules looks like:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    21/tcp ALLOW Anywhere
    20/tcp ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    21/tcp (v6)ALLOW Anywhere (v6)
    20/tcp (v6)ALLOW Anywhere (v6)

With `vsftpd` installed and the necessary ports open, we’re ready to proceed.

## Step 3 — Preparing Space for Files

First, we’ll create the directory where we plan to host the files, using the `-p` flag to create the intermediate directory. The directory structure will allow you to keep all the FTP directories together and later add other folders that require authentication:

    sudo mkdir -p /var/ftp/pub

Next, we’ll set the directory permissions to `nobody:nogroup`. Later, we’ll configure the FTP server to show all files as being owned by the ftp user and group.

    sudo chown nobody:nogroup /var/ftp/pub

Finally, we’ll make a file in the directory for testing later.

     echo "vsftpd test file" | sudo tee /var/ftp/pub/test.txt

With this sample file in place, we’re ready to configure the vsftpd daemon.

## Step 4 — Configuring Anonymous Access

We’re setting up for users with `sudo` privileges to maintain files for wide distribution to the public. To do this, we’ll configure `vsftpd` to allow anonymous downloading. We’ll expect the file administrators to use `scp`, `sftp` or any other secure method to maintain files, so we will not enable uploading files via FTP.

The configuration file contains some of the many configuration options for vsftpd.

We’ll start by changing ones that are already set:

    sudo nano /etc/vsftpd.conf

Find the following values and edit them so they match the values below:

/etc/vsftpd.conf

    . . .
    # Allow anonymous FTP? (Disabled by default).
    anonymous_enable=YES
    #
    
    We’ll set the local_enable setting to “NO” because we’re not going to allow users with local accounts to upload files via FTP. The comment in the configuration file can be a little confusing, too, because the line is uncommented by default. 
    # Uncomment this to allow local users to log in.
    local_enable=NO
    . . .
    

In addition to changing existing settings, we’re going to add some additional configuration.

**Note:** You can learn about the full range of options with the `man vsftpd.conf` command.

Add these settings to the configuration file. They are not dependent on the order, so you can place them anywhere in the file.

    #
    # Point users at the directory we created earlier.
    anon_root=/var/ftp/
    #
    # Stop prompting for a password on the command line.
    no_anon_password=YES
    #
    # Show the user and group as ftp:ftp, regardless of the owner.
    hide_ids=YES
    #
    # Limit the range of ports that can be used for passive FTP
    pasv_min_port=40000
    pasv_max_port=50000

**Note:** If you are using UFW, these settings work as-is. If you’re using [Iptables](iptables-essentials-common-firewall-rules-and-commands), you may need to add rules to open the ports you specify between `pasv_min_port` and `pasv_max_port`.

Once those are added, save and close the file. Then, restart the daemon with the following command:

    sudo systemctl restart vsftpd

`systemctl` doesn’t display the outcome of all service management commands, so if you want to be sure you’ve succeeded, use the following command:

    sudo systemctl status vsftpd

If the final line says look like the following, you’ve succeeded:

    OutputAug 17 17:49:10 vsftpd systemd[1]: Starting vsftpd FTP server...
    Aug 17 17:49:10 vsftpd systemd[1]: Started vsftpd FTP server.

Now we’re ready to test our work.

## Step 5 — Testing Anonymous Access

From a web browser enter ftp:// followed by the IP address of _your_ server.

ftp://203.0.113.0

If everything is working as expected, you should see the `pub` directory:

![Image of the 'pub' folder in a browser](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vsftp-anon/anonftp-pub.png)

You should also be able to click into `pub`, see `test.txt`, then right-click to save the file.

![Image of the 'test.txt' file in a browser](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vsftp-anon/anonftp-test1.png)

You can also test from the command-line, which will give much more feedback about your configuration. We’ll ftp to the server in passive mode, which is the `-p` flag on many command-line clients. Passive mode allows users to avoid changing local firewall configurations to permit the server and client to connect.

**Note:** The native Windows command-line FTP client, `ftp.exe`, does not support passive mode at all. Windows users may want to look into another Windows FTP client such as [WinSCP](https://winscp.net/eng/docs/commandline).

    ftp -p 203.0.113.0

When prompted for a username, you can enter either “ftp” or “anonymous”. They’re equivalent, so we’ll use the shorter “ftp”:

    Connected to 203.0.113.0.
    220 (vsftpd 3.0.3)
    Name (203.0.113.0:21:sammy): ftp

After pressing enter, you should receive the following:

    Output
    230 Login successful.
    Remote system type is UNIX.
    Using binary mode to transfer files.
    ftp>

Ensure that passive mode is working as expected:

    ls

    Output227 Entering Passive Mode (45,55,187,171,156,74).
    150 Here comes the directory listing.
    drwxr-xr-x 2 ftp ftp 4096 Aug 17 19:30 pub
    226 Directory send OK.
    

As the anonymous user, you should be able to transfer the file to your local machine with the `get` command:

    cd pub
    get test.txt

    Outputftp> get test.txt
    227 Entering Passive Mode (45,55,187,171,156,73).
    150 Opening BINARY mode data connection for test.txt (14 bytes).
    226 Transfer complete.
    16 bytes received in 0.0121 seconds (1325 bytes/s)
    

This output tells you that you’ve succeeded at downloading the file, and you can take a peek to see that it’s on your local file system if you like.

We also want to be sure anonymous users won’t be filling our file system, so to test, we will turn right around and try to put the same file back on the server, but with a new name.:

    put test.txt upload.txt

    Output227 Entering Passive Mode (104,236,10,192,168,254).
    550 Permission denied.

Now that we’ve confirmed this, we’ll exit the monitor in preparation for the next step:

    bye

Now that we’ve confirmed the anonymous connection is working as expected, we’ll turn our attention to what happens when user tries to connect.

## Step 6 — Trying to Connect as a User

You might also want to be sure that you _cannot_ connect as a user with a local account since this set up does not encrypt their login credentials. Instead of entering “ftp” or “anonymous” when you’re prompted to log in, try using your sudo user:

    ftp -p 203.0.113.0

    OutputConnected to 203.0.113.0:21.
    220 (vsFTPd 3.0.3)
    Name (203.0.113.0:21:your_user)
    530 This FTP server is anonymous only.
    ftp: Login failed.
    ftp>

These tests confirm that you set up the system for anonymous downloading only.

## Conclusion

In this tutorial we covered how to configure vsftpd for anonymous downloads only. This allows us to support legacy applications unable to use more modern protocols or widely-published FTP urls that would be difficult to update. To learn more about maintaining the files, [How To Use SFTP to Securely Transfer Files with a Remote Server](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) can guide you.
