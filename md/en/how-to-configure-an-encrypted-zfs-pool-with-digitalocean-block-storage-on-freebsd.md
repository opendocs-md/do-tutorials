---
author: Chip Marshall
date: 2016-08-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-an-encrypted-zfs-pool-with-digitalocean-block-storage-on-freebsd
---

# How To Configure an Encrypted ZFS Pool with DigitalOcean Block Storage on FreeBSD

ZFS is a file system and volume manager that supports high storage capacities, supports compression, and can prevent data corruption. ZFS, when combined with DigitalOcean’s [block storage](https://www.digitalocean.com/features/storage/), provides a storage solution that is easy to set up and expand.

In this guide, you’ll configure block storage volumes for ZFS on FreeBSD that are encrypted to keep your data secure.

## Prerequisites

- A FreeBSD Droplet in a data center that supports Block Storage, with least 4GB of RAM, as ZFS tends to be very memory intensive, especially if you’re interested in doing block de-duplication. We will use the default **freebsd** account which is created automatically when you create a FreeBSD Droplet. To learn more about logging into your FreeBSD Droplet and its basic management, check out the [Getting Started with FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd) tutorial series.
- A 100 GB volume attached to your Droplet. You can create this volume when you create your Droplet, or you can use [this guide](how-to-use-block-storage-on-digitalocean#creating-and-attaching-volumes) to create and attach a volume. 

This tutorial will also use a second 100GB volume to demonstrate how to add volumes to the pool, but you don’t need to set it up beforehand; the instructions will be covered in context during step 5.

## Step 1 — Partitioning The Volume

Even though we’ll be using the entire volume for a single filesystem, it’s generally a good idea to put a partition map on the volume. This lets us apply meaningful labels partitions we create.

First, let’s confirm that the volume is attached and available. Log into your Droplet.

    ssh freebsd@your_server_ip

Once logged in, confirm that the volume has been attached by looking at the output of the `dmesg` command. The local SSD for a FreeBSD Droplet appears as `vtbd0` and any volumes attached will appear as `da` devices.

Use `grep` to filter the results of the `dmesg` command for `da0`, which is our attached volume. Learn more about `grep` in our tutorial [Using Grep & Regular Expressions to Search for Text Patterns in Linux](using-grep-regular-expressions-to-search-for-text-patterns-in-linux).

    dmesg | grep ^da0

You’ll see output similar to the following:

    Outputda0 at vtscsi0 bus 0 scbus2 target 0 lun 1
    da0: <DO Volume 1.5.> Fixed Direct Access SPC-3 SCSI device
    da0: 300.000MB/s transfers
    da0: Command Queueing enabled
    da0: 102400MB (209715200 512 byte sectors: 255H 63S/T 13054C)

Once you’ve verified that the volume is available, create a partition map using the GPT format. Execute the following command:

    sudo gpart create -s gpt da0

Next, create a single partition for ZFS.

    sudo gpart add -t freebsd-zfs -l volume-nyc1-01 da0

The `-t` flag lets us specify the partition type, and the `-l` option lets us apply a label for the partition. The label can be whatever we like. In this case, we’ll make it match the volume’s name to help keep things straight.

Now let’s protect the data we’ll place on this partition from prying eyes.

## Step 2 — Setting up Encryption

Encrypting data has many benefits and it is easy to set up. Let’s activate the [aesni](https://www.freebsd.org/cgi/man.cgi?query=aesni) driver so we can use hardware accelerated AES encryption:

    sudo kldload aesni

Now we can configure [geli](https://www.freebsd.org/cgi/man.cgi?query=geli) encryption on the partition. We’ll use the `geli` command and specify a key length and the partition we want to encrypt:

    sudo geli init -l 256 /dev/gpt/volume-nyc1-01

The `-l` option specifies the key length, which has to be either 128 bit or 256 bit for the AES-XTS algorithm. We reference the partition using the label we specified previously.

When you execute the command you’ll be prompted for a passphrase:

    OutputEnter new passphrase:
    Reenter new passphrase:
    
    Metadata backup can be found in /var/backups/gpt_volume-nyc1-01.eli and
    can be restored with the following command:
    
        # geli restore /var/backups/gpt_volume-nyc1-01.eli /dev/gpt/volume-nyc1-01

Whenever your Droplet is rebooted, you will need to enter this passphrase to re-attach the encrypted partition. It’s a minor inconvenience in exchange for better security.

Now attach the encrypted partition:

    sudo geli attach /dev/gpt/volume-nyc1-01

You’ll be prompted for the passphrase you entered when you initialized the partition:

    OutputEnter passphrase:

This sets up `/dev/gpt/volume-nyc1-01.eli`, which is the decrypted version of the partition. Data written to that block device is encrypted and written out to the underlying device. This is the path we’ll attach to our storage pool, which we’ll create next.

## Step 3 — Setting Up the ZFS Pool

A ZFS Storage Pool, or zpool, is a collection of volumes, and it’s how ZFS manages its filesystem. And they’re easy to create. Since DigitalOcean volumes implement their own data redundancy, there’s no need to create multiple volumes and mirror them, or to run them in a RAID-Z configuration; we can just use the individual volume directly in the pool.

The `zpool create` command creates a new zpool. It takes in a name for the pool and the volume you want to add to the pool.

    sudo zpool create tank /dev/gpt/volume-nyc1-01.eli

We’re using the generic name of `tank` for our pool, but you can use any name you’d like.

Since the volume is attached over a network, file access is going to be slower than it is on the local SSD. In order to minimize the amount of data being written to the device over the network, let’s enable compression at the ZFS filesystem layer. This is entirely optional, and can be set on a per-filesystem basis.

We’ll use the LZ4 compression algorithm, which is optimized for speed while still giving decent compression. For other options, consult the [`zfs`](https://www.freebsd.org/cgi/man.cgi?query=zfs) man page.

    sudo zfs set compression=lz4 tank

Now let’s look at our pool. We can get some detailed information using the `zpool list` command:

    zpool list

    OutputNAME SIZE ALLOC FREE EXPANDSZ FRAG CAP DEDUP HEALTH ALTROOT
    tank 99.5G 98.5K 99.5G - 0% 0% 1.00x ONLINE -

The pool’s total size is slightly smaller than the total volume size, due to partitioning and formatting overhead.

We can also view the ZFS filesystem in that pool, using the `zfs list` command:

    zfs list

    OutputNAME USED AVAIL REFER MOUNTPOINT
    tank 61K 96.4G 19K /tank

or with the `df` command:

    df -h

    OutputFilesystem Size Used Avail Capacity Mounted on
    /dev/gpt/rootfs 57G 2.2G 50G 4% /
    devfs 1.0K 1.0K 0B 100% /dev
    tank 96G 19K 96G 0% /tank

You’ll use these commands every so often to check on the health of your new file system.

Before we move on, let’s make sure that the ZFS kernel module starts up when we boot our operating system. The module was loaded automatically for us when we ran the `zpool create` command with `sudo`, but it would be better if the module loaded automatically.

To do this, edit the file `/etc/rc.conf`:

    sudo vi /etc/rc.conf

Add this line after any existing lines in the file:

/etc/rc.conf

    zfs_enable="YES"

Then save the changes to the file. When the server reboots, the ZFS kernel module will load.

One of the benefits of ZFS is the ability to add more storage to the pool as our needs increase. Let’s explore how that works.

## Step 4 — Adding Additional Volumes to the Pool

We can expand the pool with additional volumes if we need more space. With ZFS, it’s just a matter of adding an additional device to the pool.

First, we need another device. Attach a new 100GB volume to your Droplet. See [this guide](how-to-use-block-storage-on-digitalocean#creating-and-attaching-volumes) for details on how to do this.

Once the volume is ready, return to your server’s terminal and verify that the new volume exists and is connected. The new volume will be identified as `da1`.

    dmesg | grep ^da1

    Outputda1 at vtscsi0 bus 0 scbus2 target 0 lun 2
    da1: <DO Volume 1.5.> Fixed Direct Access SPC-3 SCSI device
    da1: 300.000MB/s transfers
    da1: Command Queueing enabled
    da1: 102400MB (209715200 512 byte sectors: 255H 63S/T 13054C)

Next, partition and label the new volume using the same process you used for the first volume. First create the partition:

    sudo gpart create -s gpt da1

And then create the volume:

    sudo gpart add -t freebsd-zfs -l volume-nyc1-02 da1

Since your existing volume is encrypted, enable encryption on this new volume:

    sudo geli init -l 256 /dev/gpt/volume-nyc1-02

Once again you’ll be prompted for a passphrase so the volume can be decrypted and attached.

    OutputEnter new passphrase:
    Reenter new passphrase:
    
    Metadata backup can be found in /var/backups/gpt_volume-nyc1-02.eli and
    can be restored with the following command:
    
        # geli restore /var/backups/gpt_volume-nyc1-02.eli /dev/gpt/volume-nyc1-02

Then attach this new volume, providing the passphrase when prompted:

    sudo geli attach /dev/gpt/volume-nyc1-02

And finally add it to the ZFS pool:

    sudo zpool add tank /dev/gpt/volume-nyc1-02.eli

The filesystem automatically expands to the size of the pool, which you can verify with the following command:

    zpool list

    OutputNAME SIZE ALLOC FREE EXPANDSZ FRAG CAP DEDUP HEALTH ALTROOT
    tank 199G 140K 199G - 0% 0% 1.00x ONLINE -

And we can double-check with the `zfs list` command:

    zfs list

The output shows the `tank` volume and the correct amount of space:

    OutputNAME USED AVAIL REFER MOUNTPOINT
    tank 62.5K 193G 19K /tank

When you need more space, just repeat this process to add more volumes to the pool.

We’ve added encrypted partitions to our pool, so let’s look at how to reattach them after a server reboot.

## Step 5 — Handling A Reboot

When you reboot your server, the encrypted partitions will no longer be attached. You’ll have to attach them manually. For practice, let’s go through a reboot so you can see the process.

Use the `shutdown` command to reboot your server, which will disconnect your SSH session.

    sudo shutdown -r now

It can take about a minute for your system to reboot. Once the machine is back online, log back in to your Droplet.

    ssh freebsd@your_server_ip

Then attach the encrypted partitions.

    sudo geli attach /dev/gpt/volume-nyc1-01

    sudo geli attach /dev/gpt/volume-nyc1-02

As you attach each partition, you’ll be prompted for the passphrase you entered when you initialized that partition.

Now look at the results of your pool using `zpool`:

    sudo zpool list

Once the partitions are attached, ZFS automatically sees the pool and mounts the filesystems.

    OutputNAME SIZE ALLOC FREE EXPANDSZ FRAG CAP DEDUP HEALTH ALTROOT
    tank 199G 95.5K 199G - 0% 0% 1.00x ONLINE -

If we hadn’t encrypted the volumes, we wouldn’t have to worry about these extra steps during a reboot. We’re trading convenience for increased security; nobody can attach the volumes and look at the content without the passphrase.

## Conclusion

As you can see, ZFS and DigitalOcean’s Block Storage makes it easy to create a scalable, encrypted file system for your needs. You can learn more about ZFS on FreeBSD in the [FreeBSD Handbook](https://www.freebsd.org/doc/handbook/zfs.html).
