---
author: Jon Schwenn
date: 2018-03-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-an-encrypted-file-system-on-a-digitalocean-block-storage-volume
---

# How to Create an Encrypted File System on a DigitalOcean Block Storage Volume

## Introduction

[DigitalOcean Volumes](how-to-use-block-storage-on-digitalocean) are scalable, SSD-based block storage devices. Volumes allow you to create and expand your infrastructure’s storage capacity without needing to resize your Droplets.

Volumes are encrypted at rest, which means that the data on a Volume is not readable outside of its storage cluster. When you attach a Volume to a Droplet, the Droplet is presented with a decrypted block storage device and all data is transmitted over isolated networks.

For additional security, you can also create a file system in a [LUKS encrypted disk](https://gitlab.com/cryptsetup/cryptsetup/blob/master/README.md) on your Volume. This means that the disk will need to be decrypted by the operating system on your Droplet in order to read any data.

This tutorial covers how to:

- Create a passphrase-protected encrypted disk on your Volume containing a file system.
- Manually mount the encrypted file system for use, then unmount and relock it when you’re done.
- Automatically mount the file system when the Droplet boots.

## Prerequisites

To follow this tutorial, you will need:

- A [Volume attached](how-to-use-block-storage-on-digitalocean#creating-and-attaching-volumes) to a [Droplet](how-to-create-your-first-digitalocean-droplet).

**Warning:** This process is destructive to any data on the Volume. Be sure to either start with a new Volume or [back up your data](an-introduction-to-digitalocean-snapshots#creating-a-snapshot-from-a-block-storage-volume) before reformatting an existing Volume.

## Step 1 — Creating the Encrypted Disk

`cryptsetup` is a utility used to manage LUKS volumes in addition to other encrypted formats. To begin, use `cryptsetup` to initialize an encrypted disk on your Volume.

    sudo cryptsetup -y -v luksFormat /dev/disk/by-id/scsi-0DO_Volume_volume-lon1-01

Make sure to replace `volume-lon1-01` with [the name of your Volume](how-to-partition-and-format-digitalocean-block-storage-volumes-in-linux#working-with-volumes-on-digitalocean). The `-y` flag will require you to enter your passphrase twice when you’re prompted to create it. The `-v` flag adds additional human-readable output to verify the success of the command.

The output will ask you to confirm overwriting the data on the Volume. Type `YES` in all caps, then press `ENTER` to continue.

    OutputWARNING!
    ========
    This will overwrite data on /dev/disk/by-id/scsi-0DO_Volume_volume-lon1-01 irrevocably.
    
    Are you sure? (Type uppercase yes): YES

Next, the output will prompt you to create a passphrase for the encrypted disk. Enter a unique, strong passphrase and verify it by entering it a second time. This passphrase **is not recoverable** , so keep it recorded in a safe place.

    Output. . .
    Enter passphrase:
    Verify passphrase:
    Command successful.

If you need to, you can change this passphrase in the future with the `cryptsetup luksChangeKey` command. You can also add up to 8 additional passphrases per device with `cryptsetup luksAddKey`.

At this point, your disk is created and encrypted. Next, decrypt it and map it to a [label](an-introduction-to-storage-terminology-and-concepts-in-linux#how-linux-manages-storage-devices) for easier referencing. Here, we’re labeling it `secure-volume`, but you can label it with anything you like.

    sudo cryptsetup luksOpen /dev/disk/by-id/scsi-0DO_Volume_volume-lon1-01 secure-volume

You’ll be prompted for the passphrase. Once you enter it, the Volume will now be mapped to `/dev/mapper/secure-volume`.

To make sure everything worked, verify the details of the encrypted disk.

    cryptsetup status secure-volume

You’ll see output like this indicating the Volume label and type.

    Output/dev/mapper/secure-volume is active.
      type: LUKS1
      cipher: aes-xts-plain64
      keysize: 256 bits
      device: /dev/sda
      offset: 4096 sectors
      size: 209711104 sectors
      mode: read/write

At this point, you have a passphrase-protected encrypted disk. The next step is to create a file system on that disk so the operating system can use it to store files.

## Step 2 — Creating and Mounting the File System

Let’s first take a look at the current available disk space on the Droplet.

    df -h

You’ll see output similar to this, depending on your Droplet configuration:

    OutputFilesystem Size Used Avail Use% Mounted on
    udev 2.0G 0 2.0G 0% /dev
    tmpfs 396M 5.6M 390M 2% /run
    /dev/vda1 78G 877M 77G 2% /
    tmpfs 2.0G 0 2.0G 0% /dev/shm
    tmpfs 5.0M 0 5.0M 0% /run/lock
    tmpfs 2.0G 0 2.0G 0% /sys/fs/cgroup
    /dev/vda15 105M 3.4M 101M 4% /boot/efi
    tmpfs 396M 0 396M 0% /run/user/1000

Right now, `/dev/mapper/secure-volume` doesn’t show up on this list because the Volume isn’t yet accessible to the Droplet. To make it accessible, we need to create and mount the file system.

Use the `mkfs.xfs` utility ( **m** a **k** e **f** ile **s** ystem) to create an [XFS](https://en.wikipedia.org/wiki/XFS) file system on the volume.

    sudo mkfs.xfs /dev/mapper/secure-volume

Once the file system is created, you can [mount](how-to-partition-and-format-digitalocean-block-storage-volumes-in-linux#mounting-the-filesystems) it, which means making it available to the operating system on your Droplet.

Create a _mount point_, which is where the file system will be attached. A good recommendation for a mount point is an empty directory in the `/mnt` directory, so we’ll use `/mnt/secure`.

    sudo mkdir /mnt/secure

Then mount the file system.

    sudo mount /dev/mapper/secure-volume /mnt/secure

To make sure it worked, check the available disk space on your Droplet again.

    df -h

You’ll now see `/dev/mapper/secure-volume` listed.

    OutputFilesystem Size Used Avail Use% Mounted on
    udev 2.0G 0 2.0G 0% /dev
    tmpfs 396M 5.6M 390M 2% /run
    /dev/vda1 78G 877M 77G 2% /
    tmpfs 2.0G 0 2.0G 0% /dev/shm
    tmpfs 5.0M 0 5.0M 0% /run/lock
    tmpfs 2.0G 0 2.0G 0% /sys/fs/cgroup
    /dev/vda15 105M 3.4M 101M 4% /boot/efi
    tmpfs 396M 0 396M 0% /run/user/1000
    /dev/mapper/secure-volume 100G 33M 100G 1% /mnt/secure

This means your encrypted file system is attached and available for use.

When you no longer need to access the data on the Volume, you can unmount the file system and lock the encrypted disk.

    sudo umount /mnt/secure
    sudo cryptsetup luksClose secure-volume

You can verify with `df -h` that the file system is no longer available. In order to make the data on the Volume accessible again, you would run through the steps to open the disk (`cryptsetup luksOpen ...`), create a mount point, and mount the file system.

To avoid going through this manual process every time you want use the Volume, you can instead configure the file system to mount automatically when your Droplet boots.

## Step 3 — Automatically Mounting the File System on Boot

The encrypted disk can have up to 8 passphrases. In this final step, we’ll create a key and add it as a passphrase, then use that key to configure the Volume to be decrypted and mounted as the Droplet is booting.

Create a key file at `/root/.secure_key`. This command will make a 4 KB file with random contents:

    sudo dd if=/dev/urandom of=/root/.secure-key bs=1024 count=4

Adjust the permissions of this key file so it’s only readable by the **root** user.

    sudo chmod 0400 /root/.secure-key

Then add the key as a passphrase for the encrypted disk.

    cryptsetup luksAddKey /dev/disk/by-id/scsi-0DO_Volume_volume-lon1-01 /root/.secure-key

You’ll be prompted for a passphrase. You can enter the one you set when you first created the encrypted disk.

`/etc/crypttab` is a configuration file that defines encrypted disks to set up when the system starts. Open this file with `nano` or your favorite text editor.

    sudo nano /etc/crypttab

Add the following line to the bottom of the file to map the Volume at boot.

/etc/crypttab

    . . .
    secure-volume /dev/disk/by-id/scsi-0DO_Volume_volume-lon1-01 /root/.secure-key luks

The format of the lines in `/etc/crypttab` is `device_name device_path key_path options`. Here, the device name is `secure-volume` (or the name you chose instead), the path is `/dev/disk/by-id/...`, the key file is what we just created at `/root/.secure_key`, and the options specify `luks` encryption.

Save and close the file.

`/etc/fstab` is a configuration file to automate mounting. Open this file for editing.

    sudo nano /etc/fstab

Add the following line to the bottom of the file to automatically mount the disk at boot.

/etc/fstab

    . . .
    /dev/mapper/secure-volume /mnt/secure xfs defaults,nofail 0 0

The first three arguments of the lines in `/etc/fstab` are always `device_path mount_point file_system_type`. Here, we have the same device path and mount point as in Step 2, and we specify the XFS file system. You can read about the other fields in `fstab`’s man page (`man fstab`).

Save and close the file. Your encrypted file system is now set to automatically mount when your Droplet boots. You can test this by rebooting your Droplet, but be cautious with any running services.

## Conclusion

By default, DigitalOcean Volumes are encrypted when they are not attached to a Droplet. In this tutorial, you added an additional layer of security by putting a file system in an encrypted disk on a Volume. You can create an encrypted disk, add passphrases to it, and mount it manually or automatically for use within the Droplet.

You can learn more about DigitalOcean Block Storage Volumes in the [Getting Started with DigitalOcean Block Storage](https://www.digitalocean.com/community/tutorial_series/getting-started-with-digitalocean-block-storage) series.
