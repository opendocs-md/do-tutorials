---
author: Melissa Anderson, Mark Drake
date: 2018-07-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-18-04
---

# How To Set Up an NFS Mount on Ubuntu 18.04

## Introduction

NFS, or Network File System, is a distributed file system protocol that allows you to mount remote directories on your server. This lets you manage storage space in a different location and write to that space from multiple clients. NFS provides a relatively quick and easy way to access remote systems over a network and works well in situations where the shared resources must be accessed regularly.

In this guide, we’ll go over how to install the components needed for NFS functionality, configure NFS mounts, and unmount an NFS remote share.

## Prerequisites

We will use two servers in this tutorial, with one sharing part of its filesystem with the other. To follow along, you will need:

- Two Ubuntu 18.04 servers. Each of these should have a non- **root** user with `sudo` privileges configured, a simple firewall set up with UFW, and private networking, if it’s available to you.

Throughout this tutorial, we refer to the server that shares its directories as the **host** and the server that mounts these directories as the **client**. In order to keep them straight, we’ll use the following IP addresses as stand-ins for the **host** and **client** values:

- **Host** : `203.0.113.0`
- **Client** : `203.0.113.24`

When these IP addresses appear in commands and configuration files, you will need to replace them with your own respective **host** and **client** IP addresses.

## Step 1 — Downloading and Installing the Components

We’ll begin by installing the necessary components on each server.

### On the Host

On the **host** server, install the `nfs-kernel-server` package, which will allow you to share your directories. Since this is the first operation that you’re performing with `apt` in this session, refresh your local package index before the installation:

    sudo apt update
    sudo apt install nfs-kernel-server

Once these packages are installed, switch to the **client** server.

### On the Client

On the **client** server, we need to install a package called `nfs-common`, which provides NFS functionality without including unneeded server components. Again, refresh the local package index prior to installation to ensure that you have up-to-date information:

    sudo apt update
    sudo apt install nfs-common

Now that both servers have the necessary packages, we can start configuring them.

## Step 2 — Creating the Share Directories on the Host

We’re going to share two separate directories, with different configuration settings, in order to illustrate two key ways that NFS mounts can be configured with respect to superuser access.

Superusers can do anything anywhere on their system. However, NFS-mounted directories are not part of the system on which they are mounted, so by default, the NFS server refuses to perform operations that require superuser privileges. This default restriction means that superusers on the **client** cannot write files as **root** , reassign ownership, or perform any other superuser tasks on the NFS mount.

Sometimes, however, there are trusted users on the **client** system who need to perform these actions on the mounted file system but who have no need for superuser access on the **host**. You can configure the NFS server to allow this to allow this, although it introduces an element of risk, as such a user _could_ gain root access to the entire **host** system.

### Example 1: Exporting a General Purpose Mount

In the first example, we’ll create a general-purpose NFS mount that uses default NFS behavior to makes it difficult for a user with root privileges on the **client** machine to interact with the **host** using those **client** superuser privileges. You might use something like this to store files which were uploaded using a content management system or to create space for users to easily share project files.

First, make a share directory called `nfs`:

    sudo mkdir /var/nfs/general -p

Since we’re creating it with `sudo`, the directory is owned by the **root** user on the **host**.

    ls -la /var/nfs/general

    Output4 drwxr-xr-x 2 root root 4096 Jul 25 15:26 .

NFS will translate any **root** operations on the **client** to the `nobody:nogroup` credentials as a security measure. Therefore, we need to change the directory ownership to match those credentials.

    sudo chown nobody:nogroup /var/nfs/general

You’re now ready to export this directory.

### Example 2: Exporting the Home Directory

In our second example, the goal is to make user home directories stored on the **host** available on **client** servers, while allowing trusted administrators of those **client** servers the access they need to conveniently manage users.

To do this, we’ll export the `/home` directory. Since it already exists, we don’t need to create it. We won’t change the permissions, either. If we _did_, it could lead to a range of issues for anyone with a home directory on the **host** machine.

## Step 3 — Configuring the NFS Exports on the Host Server

Next, we’ll dive into the NFS configuration file to set up the sharing of these resources.

Open the `/etc/exports` file in your text editor with **root** privileges:

    sudo nano /etc/exports

The file has comments showing the general structure of each configuration line. The syntax is basically:

/etc/exports

    directory_to_share client(share_option1,...,share_optionN)

We’ll need to create a line for each of the directories that we plan to share. Since our example **client** has an IP of `203.0.113.24`, our lines will look like the following. Be sure to change the IP address shown here to that of your **client** :

/etc/exports

    /var/nfs/general 203.0.113.24(rw,sync,no_subtree_check)
    /home 203.0.113.24(rw,sync,no_root_squash,no_subtree_check)

Here, we’re using the same configuration options for both directories with the exception of `no_root_squash`. Let’s take a look at what each of these options mean:

- `rw`: This option gives the **client** computer both read and write access to the volume.
- `sync`: This option forces NFS to write changes to disk before replying. This results in a more stable and consistent environment since the reply reflects the actual state of the remote volume. However, it also reduces the speed of file operations.
- `no_subtree_check`: This option prevents subtree checking, which is a process where the **host** must check whether the file is actually still available in the exported tree for every request. This can cause many problems when a file is renamed while the **client** has it opened. In almost all cases, it is better to disable subtree checking.
- `no_root_squash`: By default, NFS translates requests from a **root** user remotely into a non-privileged user on the server. This was intended as security feature to prevent a **root** account on the **client** from using the file system of the **host** as **root**. `no_root_squash` disables this behavior for certain shares. 

When you are finished making your changes, save and close the file. Then, to make the shares available to the clients that you configured, restart the NFS server with the following command:

    sudo systemctl restart nfs-kernel-server

Before you can actually use the new shares, however, you’ll need to be sure that traffic to the shares is permitted by firewall rules.

## Step 4 — Adjusting the Firewall on the Host

First, let’s check the firewall status to see if it’s enabled and, if so, to see what’s currently permitted:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

On our system, only SSH traffic is being allowed through, so we’ll need to add a rule for NFS traffic.

With many applications, you can use `sudo ufw app list` and enable them by name, but `nfs` is not one of those. However, because `ufw` also checks `/etc/services` for the port and protocol of a service, we can still add NFS by name. Best practice recommends that you enable the most restrictive rule that will still allow the traffic you want to permit, so rather than enabling traffic from just anywhere, we’ll be specific.

Use the following command to open port `2049` on the **host** , being sure to substitute your **client’s** IP address:

    sudo ufw allow from 203.0.113.24 to any port nfs

You can verify the change by typing:

    sudo ufw status

You should see traffic allowed from port `2049` in the output:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                 
    2049 ALLOW 203.0.113.24        
    OpenSSH (v6) ALLOW Anywhere (v6)

This confirms that UFW will only allow NFS traffic on port `2049` from our **client** machine.

## Step 5 — Creating Mount Points and Mounting Directories on the Client

Now that the **host** server is configured and serving its shares, we’ll prepare our **client**.

In order to make the remote shares available on the **client** , we need to mount the directories on the **host** that we want to share to empty directories on the **client**.

**Note:** If there are files and directories in your mount point, they will become hidden as soon as you mount the NFS share. To avoid the loss of important files, be sure that if you mount in a directory that already exists that the directory is empty.

We’ll create two directories for our mounts:

    sudo mkdir -p /nfs/general
    sudo mkdir -p /nfs/home

Now that we have a location to put the remote shares and we’ve opened the firewall, we can mount the shares by addressing our **host** server, which in this guide is `203.0.113.0`:

    sudo mount 203.0.113.0:/var/nfs/general /nfs/general
    sudo mount 203.0.113.0:/home /nfs/home

These commands will mount the shares from the host computer onto the **client** machine. You can double-check that they mounted successfully in several ways. You can check this with a plain `mount` or `findmnt` command, but `df -h` provides a more easily readable output that illustrates how disk usage is displayed differently for the NFS shares:

    df -h

    OutputFilesystem Size Used Avail Use% Mounted on
    udev 238M 0 238M 0% /dev
    tmpfs 49M 628K 49M 2% /run
    /dev/vda1 20G 1.2G 18G 7% /
    tmpfs 245M 0 245M 0% /dev/shm
    tmpfs 5.0M 0 5.0M 0% /run/lock
    tmpfs 245M 0 245M 0% /sys/fs/cgroup
    tmpfs 49M 0 49M 0% /run/user/0
    203.0.113.0:/home 20G 1.2G 18G 7% /nfs/home
    203.0.113.0:/var/nfs/general 20G 1.2G 18G 7% /nfs/general

Both of the shares we mounted appear at the bottom. Because they were mounted from the same file system, they show the same disk usage. To see how much space is actually being used under each mount point, use the disk usage command `du` and the path of the mount. The `-s` flag provides a summary of usage rather than displaying the usage for every file. The `-h` prints human-readable output.

For example:

    du -sh /nfs/home

    Output36K /nfs/home

This shows us that the contents of the entire home directory is using only 36K of the available space.

## Step 6 — Testing NFS Access

Next, let’s test access to the shares by writing something to each of them.

### Example 1: The General Purpose Share

First, write a test file to the `/var/nfs/general` share:

    sudo touch /nfs/general/general.test

Then, check its ownership:

    ls -l /nfs/general/general.test

    Output-rw-r--r-- 1 nobody nogroup 0 Aug 1 13:31 /nfs/general/general.test

Because we mounted this volume without changing NFS’s default behavior and created the file as the **client** machine’s **root** user via the `sudo` command, ownership of the file defaults to `nobody:nogroup`. **client** superusers won’t be able to perform typical administrative actions, like changing the owner of a file or creating a new directory for a group of users, on this NFS-mounted share.

### Example 2: The Home Directory Share

To compare the permissions of the General Purpose share with the Home Directory share, create a file Home Directory the same way:

    sudo touch /nfs/home/home.test

Then look at the ownership of the file:

    ls -l /nfs/home/home.test

    Output-rw-r--r-- 1 root root 0 Aug 1 13:32 /nfs/home/home.test

We created `home.test` as **root** using the `sudo` command, exactly the same way we created the `general.test` file. However, in this case it is owned by **root** because we overrode the default behavior when we specified the `no_root_squash` option on this mount. This allows our **root** users on the **client** machine to act as **root** and makes the administration of user accounts much more convenient. At the same time, it means we don’t have to give these users root access on the **host**.

## Step 7 — Mounting the Remote NFS Directories at Boot

We can mount the remote NFS shares automatically at boot by adding them to `/etc/fstab` file on the **client**.

Open this file with root privileges in your text editor:

    sudo nano /etc/fstab

At the bottom of the file, add a line for each of our shares. They will look like this:

/etc/fstab

    . . .
    203.0.113.0:/var/nfs/general /nfs/general nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
    203.0.113.0:/home /nfs/home nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
    

**Note:** You can find more information about the options we are specifying here in the NFS man page. You can access this by running the following command:

    man nfs

The **client** server will automatically mount the remote partitions at boot, although it may take a few moments to establish the connection and for the shares to be available.

## Step 8 — Unmounting an NFS Remote Share

If you no longer want the remote directory to be mounted on your system, you can unmount it by moving out of the share’s directory structure and unmounting, like this:

    cd ~
    sudo umount /nfs/home
    sudo umount /nfs/general

This will remove the remote shares, leaving only your local storage accessible:

    df -h

    Output
    Filesystem Size Used Avail Use% Mounted on
    /dev/vda 59G 1.3G 55G 3% /
    none 4.0K 0 4.0K 0% /sys/fs/cgroup
    udev 2.0G 12K 2.0G 1% /dev
    tmpfs 396M 320K 396M 1% /run
    none 5.0M 0 5.0M 0% /run/lock
    none 2.0G 0 2.0G 0% /run/shm
    none 100M 0 100M 0% /run/user

If you also want to prevent them from being remounted on the next reboot, edit `/etc/fstab` and either delete the line or comment it out by placing a # symbol at the beginning of the line. You can also prevent auto-mounting by removing the `auto` option, which will allow you to mount it manually.

## Conclusion

In this tutorial, we created an NFS host and illustrated some key NFS behaviours by creating two different NFS mounts, which we shared with our NFS **client**. If you’re looking to implement NFS in production, it’s important to note that the protocol itself is not encrypted. In cases where you’re sharing files that are intended to be publicly accessible, this doesn’t cause any serious problems.

If you’re using NFS for private data, however, you’ll need to decide how you want to protect that data. You might be able to route NFS over SSH or a VPN connection to create a more secure experience, but this often comes with a significant reduction in performance. If performance is an issue, consider [SSHFS](how-to-use-sshfs-to-mount-remote-file-systems-over-ssh). It’s slightly slower than unencrypted NFS traffic, but usually much faster than tunnelled NFS. Kerberos authenticated encryption for NFS is another option to explore.
