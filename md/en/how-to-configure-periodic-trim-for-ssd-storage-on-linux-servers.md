---
author: Justin Ellingwood
date: 2016-08-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-periodic-trim-for-ssd-storage-on-linux-servers
---

# How To Configure Periodic TRIM for SSD Storage on Linux Servers

## Introduction

Due to the architecture of SSDs, or solid state drives, continuous use results in degraded performance if not accounted for and mitigated. The **TRIM** command is an operation that allows the operating system to propagate information down to the SSD about which blocks of data are no longer in use. This allows the SSD’s internal systems to better manage wear leveling and prepare the device for future writes. TRIM can have a major impact on the device’s performance over time and its overall longevity.

While it is possible to enable continuous TRIM in Linux, this can actually negatively affect performance because of the additional overhead on normal file operations. A gentler alternative is to configure _periodic TRIM_. This configures the operating system to TRIM the drive on a schedule instead of as a necessary component of regular file operations. In almost all cases it provides the same benefits of continuous TRIM without the performance hit.

In this guide, we will briefly discuss how SSDs and TRIM work and then demonstrate how to enable periodic TRIM on a variety of Linux distributions.

## How Do SSDs Store Data?

To better understand the problems that TRIM solves, it helps to know a few things about how SSDs store and manage their data.

### Data Units

Data on SSDs is written and read in units of a fixed size known as _pages_. Pages, in turn, are grouped together in larger units called _blocks_.

### Read, Write, and Erase Limitations

SSDs can read and write to pages individually. However, they can only erase data at the block level. Another limitation is that writes can only be performed on pages that have been completely _zeroed_ (all bits set to 0). This means that overwriting data directly is impossible.

To modify data, the SSD actually has to read the information from the old location, modify it in memory, and then write the modified data to new, zeroed pages. It then updates an internal table to map the logical location that the operating system is given to the new physical location of the data on the device. The old location is marked in a different internal table as _stale_: not in use, but not yet zeroed.

### Reclaiming Stale Pages

To reclaim the stale pages, the SSD’s internal garbage collecting processes must read all of the valid pages from a block and write them to a new block. Again, the internal table mapping logical and physical locations is updated. The old block, which now contains no unique, still-in-use data can then be zeroed and marked as ready for future writes.

## What Does TRIM Do?

The SSD’s internal garbage collecting processes are responsible for erasing blocks and managing wear leveling. However, filesystems typically “delete” data by just marking it in their own records as space that is available again. They do not actually erase the data from the underlying storage, but may overwrite the area previously occupied by that data on subsequent writes.

This means that the SSD will typically not know that a page is no longer needed until it receives instructions from the filesystem to write to the same logical location at a later time. It cannot perform its garbage collection routines because it is never informed when data is deleted, just when the space previously reserved for it should now be used for other data.

The TRIM command propagates information about which data is no longer being used from the filesystem down to the SSD. This allows the device to perform its regular garbage collecting duties when idle, in order to ensure that there are zeroed pages ready to handle new writes. The SSD can shuffle data ahead of time, clean up stale pages, and generally keep the device in good working condition.

Performing TRIM on every deletion can be costly however and can have a negative impact on the performance of the drive. Configuring periodic TRIM gives the device bulk information about unneeded pages on a regular schedule instead of with each operation.

## Disabling Continuous TRIM

You may have already enabled continuous TRIM on your devices when they were mounted. Before we enable periodic TRIM, it makes sense to take a look at our current mount options.

Continuous TRIM is enabled by mounting a drive or partition with the `discard` option.

First, find the filesystems that are currently mounted with the `discard` option:

    findmnt -O discard

    OutputTARGET SOURCE FSTYPE OPTIONS
    /mnt/data /dev/sda1 ext4 rw,relatime,discard,data=ordered
    /mnt/data2 /dev/sdb1 ext4 rw,relatime,discard,data=ordered

You can remount these filesystems in place, without the `discard` option, by including `-o remount,nodiscard` with `mount`:

    sudo mount -o remount,nodiscard /mnt/data
    sudo mount -o remount,nodiscard /mnt/data2

If you run the `findmnt` command again, you should receive no results:

    findmnt -O discard

Next, open the `/etc/fstab` file to see the mount options currently defined for your filesystems. These determine how the filesystems are mounted each boot:

    sudo nano /etc/fstab

Look for the `discard` option and remove it from lines that you find:

/etc/fstab

    . . .
    # /dev/sda1 /mnt/data ext4 defaults,nofail,discard 0 0
    /dev/sda1 /mnt/data ext4 defaults,nofail 0 0
    # /dev/sdb1 /mnt/data2 ext4 defaults,nofail,discard 0 0
    /dev/sdb1 /mnt/data2 ext4 defaults,nofail 0 0

Save and close the file when you are finished. The filesystems will now be mounted without the `discard` option, and will mount in this same way on subsequent boots. We can now set up periodic TRIM for all filesystems that support it.

## Setting Up Periodic TRIM for systemd Distributions

Setting up periodic TRIM for modern distributions shipping with systemd tends to be rather straight forward.

### Ubuntu 16.04

Ubuntu 16.04 ships with a script that is run weekly by `cron`. This means that enabling the systemd method described in the following section is unnecessary for Ubuntu 16.04.

If you wish to examine the script, you can see it by typing:

    cat /etc/cron.weekly/fstrim

    Output#!/bin/sh
    # trim all mounted file systems which support it
    /sbin/fstrim --all || true

As you can see, this script needs a version of `fstrim` with the `--all` flag. Many versions `fstrim` shipped with earlier releases of Ubuntu do not contain this option.

### Other systemd Distributions

For other systemd distributions, periodic TRIM can be enabled with the `fstrim.timer` file, which will run TRIM operations on all capable, mounted drives once a week. This also leverages the `fstrim --all` option.

At the time of this writing, this is the best method for the following distributions:

- Debian 8
- CentOS 7
- Fedora 24
- Fedora 23
- CoreOS

For CentOS 7, Fedora 23, Fedora 24, and CoreOS, the `fstrim.service` and `fstrim.timer` units are available by default. To schedule a weekly TRIM of all attached capable drives, enable the `.timer` unit:

    sudo systemctl enable fstrim.timer

Debian 8 has the `fstrim.service` and `fstrim.timer` available within the filesystem, but not loaded into systemd by default. You just need to copy the files over first:

    sudo cp /usr/share/doc/util-linux/examples/fstrim.service /etc/systemd/system
    sudo cp /usr/share/doc/util-linux/examples/fstrim.timer /etc/systemd/system

Now, you can enable the timer the same as with the other distributions:

    sudo systemctl enable fstrim.timer

Your server should now TRIM all mounted filesystems that support the operation, once weekly.

## Setting Up Periodic TRIM for Non-systemd Distributions

Coincidentally, most distribution releases that ship with non-systemd init systems also shipped with versions of the `fstrim` utility that did not have the `--all` flag. This makes safe, automatic TRIM operations much more difficult.

Using TRIM on drives that do not support it or on devices that incorrectly implement it can be dangerous and lead to data loss. The `--all` flag can handle these scenarios safely, but manually attempting to determine whether attached drives correctly support the operation can be dangerous.

In Ubuntu 14.04, a short script called `fstrim-all` is included, which attempts to do this. A weekly script run by `cron` executes this. However, the script does not always interpret the TRIM ability of attached drives correctly.

For this and other distributions with `fstrim` commands without the `--all` flag, the best workaround may be to compile a statically linked version of `fstrim` that does include the flag. This can be installed alongside the distribution-managed version and only called explicitly from the `cron` job.

This may be the best option for the following distributions:

- Ubuntu 14.04
- Ubuntu 12.04
- Debian 7
- CentOS 6

For Ubuntu 14.04, it’s probably best to disable the `fstrim-all` script from running, since it may not detect the status correctly:

    sudo chmod a-x /etc/cron.weekly/fstrim
    sudo mv /etc/cron.weekly/fstrim /etc/cron.weekly/fstrim.bak

For other distributions, you can jump right in.

### Install the Software Compilation Tools

First, install the needed software building tools.

For Ubuntu and Debian systems, this can be done by typing:

    sudo apt-get update
    sudo apt-get install build-essential

For CentOS systems, you can install a similar set of tools by typing:

    sudo yum groupinstall 'Development Tools'

You now have the build dependencies needed to compile a recent version of `fstrim`.

### Download and Extract the Source Files

The `fstrim` utility is released with other tools in a group called `util-linux`. You can find the source code, organized by release version, [here](https://www.kernel.org/pub/linux/utils/util-linux/).

Click on the most recent version of the package. At the moment, that is `v2.28`, but that may be different as development continues.

Within the next directory, find the most recent tarball for the software. This will start with `util-linux-` and end with `.tar.gz`. Currently, the most recent stable version is `util-linux-2.28.1.tar.gz`. Right-click on the appropriate link and copy it to your clipboard.

Back on your server, move to the `/tmp` directory. Use the `curl` or `wget` utility and paste in URL you copied to download the file:

    cd /tmp
    curl -LO https://www.kernel.org/pub/linux/utils/util-linux/v2.28/util-linux-2.28.1.tar.gz

Afterwards, extract the tarball to create the source directory structure:

    tar xzvf util-linux*

Now that we have the source code and the build tools, we can build the software.

### Configure and Compile a Statically Linked fstrim

Begin by enter the extracted directory structure:

    cd /tmp/util-linux*

Next we need to configure the software. Since we are only installing an isolated `fstrim` binary, and do not want to overwrite the utilities and libraries managed by our package management system, we will compile a static binary.

To do this, we need to enable static linking and disable shared libraries. Configure the software with these properties by typing:

    ./configure --enable-static --disable-shared

Once the software is configured, you can compile the `fstrim` utility by typing:

    make fstrim

This will compile the utility, placing it in the top-level directory of the extracted archive.

Copy the binary to a directory that is _not_ in your PATH. Since we’re only interested in calling this from the `cron` script, we should make sure that it does not compete with the system-installed `fstrim` for other uses.

We will make a directory called `/cron-bin` and place the binary in there:

    sudo mkdir /cron-bin
    sudo cp /tmp/util-linux*/fstrim /cron-bin

We now have access to a more functional `fstrim` utility.

### Create a Weekly Cron Script to Run fstrim

Now, we can create a new script that will be run by `cron` weekly. This will be exactly the same script that’s included with Ubuntu 16.04, except that it will point to the location where we placed our statically compiled binary.

Create the file by typing:

    sudo nano /etc/cron.weekly/fstrim

Inside, paste the following lines. This will run our new `fstrim` binary with the `--all` option:

/etc/cron.weekly/fstrim

    #!/bin/sh
    # trim all mounted file systems which support it
    /cron-bin/fstrim --all || true

Save and close the file when you are finished.

Make the script executable by typing:

    sudo chmod a+x /etc/cron.weekly/fstrim

The `cron` and `anacron` daemons will run this script once a week to TRIM the filesystems.

## Conclusion

Your Linux server should now be configured to periodically TRIM all supported filesystems on a weekly basis. TRIM helps to maximize both the long term performance and lifespan of your SSDs.

Continuous TRIM operations may sound ideal, but they can add signifiant overhead to regular filesystem operations. Periodic TRIM offers a good middle ground by relaying key information needed to perform routine maintenance of the drive in a scheduled job instead of as a component of each file operation.
