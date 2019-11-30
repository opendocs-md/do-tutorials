---
author: Paul White
date: 2013-12-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-sshfs-to-mount-remote-file-systems-over-ssh
---

# How To Use SSHFS to Mount Remote File Systems Over SSH

## Introduction

* * *

In many cases it can become cumbersome to transfer files to and from a droplet. Imagine a development usage scenario where you are coding apps remotely and find yourself uploading a script repeatedly to your virtual server to test. This can become quite a hassle in a very short period of time. Luckily there is a way to mount your VPS file system to your local computer so you can make changes on the fly and treat your droplet as local storage. In this article, we will show you how to do exactly that.

## Installing SSHFS

* * *

### On Ubuntu/Debian

* * *

SSHFS is Linux based software that needs to be installed on your local computer. On Ubuntu and Debian based systems it can be installed through apt-get.

    sudo apt-get install sshfs

### On Mac OSX

* * *

You can install SSHFS on Mac OSX. You will need to download FUSE and SSHFS from the [osxfuse site](http://osxfuse.github.io/)

### On Windows

* * *

To install SSHFS in Windows you will need to grab the latest win-sshfs package from the google code repository. A direct download link can be found below. After you have downloaded the package, double click to launch the installer. You may be prompted to download additional files, if so the installer will download the .NET Framework 4.0 and install it for you.

    https://win-sshfs.googlecode.com/files/win-sshfs-0.0.1.5-setup.exe

## Mounting the Remote File System

* * *

The following instructions will work for both Ubuntu/Debian and OSX. Instructions for Windows systems can be found at the bottom of the tutorial.

To start we will need to create a local directory in which to mount the droplet’s file system.

    sudo mkdir /mnt/droplet <--replace "droplet" whatever you prefer

Now we can use sshfs to mount the file system locally with the following command. If your VPS was created with a password login the following command will do the trick. You will be asked for your virtual server’s root password during this step.

    sudo sshfs -o allow_other,defer_permissions root@xxx.xxx.xxx.xxx:/ /mnt/droplet

If your droplet is configured for login via ssh key authorization, you will need to tell sshfs to use your public keys with the following command. You will be asked to enter the passphrase you used during the creation of your keys with ssh-keygen.

    sudo sshfs -o allow_other,defer_permissions,IdentityFile=~/.ssh/id_rsa root@xxx.xxx.xxx.xxx:/ /mnt/droplet

Now you can work with files on your droplet as if it were a physical device attached to your local machine. For instance, if you move to the /mnt/droplet directory on your local machine you can create a file locally and the file will appear on your virtual server. Likewise you can copy files into the /mnt/droplet folder and they will be uploaded to your droplet in the background.

It is important to note that this process provides only a temporary mount point to your droplet. If the virtual server or local machine is powered off or restarted, you will need to use the same process to mount it again.

### Unmounting the Remote File System

* * *

When you no longer need the mount point you can simply unmount it with the command

    sudo umount /mnt/droplet

## Permanently Mounting the Remote File System

* * *

SSHFS also allows for setting up permanent mount points to remote file systems. This would set a mount point that would persist through restarts of both your local machine and droplets. In order to set up a permanent mount point, we will need to edit the `/etc/fstab` file on the local machine to automatically mount the file system each time the system is booted.

First we need to edit the `/etc/fstab` file with a text editor.

    sudo nano /etc/fstab

Scroll to the bottom of the file and add the following entry

    sshfs#root@xxx.xxx.xxx.xxx:/ /mnt/droplet

Save the changes to `/etc/fstab` and reboot if necessary.

It should be noted that permanently mounting your VPS file system locally is a potential security risk. If your local machine is compromised it allows for a direct route to your droplet. Therefore it is not recommended to setup permanent mounts on production servers.

## Using Win-SSHFS to Mount Remote File Systems on Windows

* * *

After launching the win-sshfs program, you will be presented with a graphical interface to make the process of mounting a remote file share simple.

- Step 1: Click the Add button in the lower left corner of the window.

- Step 2: Enter a name for the file share in the Drive Name field.

- Step 3. Enter the IP of your droplet in the Host field.

- Step 4. Enter your SSH port. (Leave as port 22 unless you have changed the SSH port manually).

- Step 5. Enter your username in the Username field. (Unless you have set up user accounts manually you will enter `root` in this field).

- Step 6. Enter your SSH password in the password field. (Note on Windows you will need to have your droplet configured for password logins rather than ssh-key-authentication).

- Step 7. Enter your desired mount point in the Directory field. (Enter `/` to mount the file system from root. Likewise you can enter `/var/www` or `~/` for your home directory).

- Step 8. Select the drive letter you would like Windows to use for your droplets file system.

- Step 9. Click the Mount button to connect to the droplet and mount the file system.

Now your virtual server’s file system will be available through My Computer as the drive letter you chose in step 8.

## Usage of the Remote Mount Point

* * *

The remote mount behaves similarly to locally mounted storage: you are able to create, copy, move, edit, compress or perform any file system operations you would be able to do on the droplet, but you are not able to launch programs or scripts on the remote server.

One typical usage of this would be if you host a website on your VPS and need to make changes to the website on a regular basis. Mounting the file system locally allows you to launch whatever code editor, IDE, or text editor you wish to edit the site, and any changes you make will reflect on the virtual server as soon as they are made on your local machine.

Similarly, on droplets used for testing purposes of coding projects, it allows for much simpler code modifications which can be tested immediately without the need to modify the code locally as well as remotely (and eliminates the hassle of uploading new copies of files for small code changes).
