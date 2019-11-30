---
author: Melissa Anderson
date: 2016-12-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-change-a-mysql-data-directory-to-a-new-location-using-a-symlink
---

# How to Change a MySQL Data Directory to a New Location Using a Symlink

## Introduction

Databases grow over time, sometimes outgrowing the space on the file system. You can also run into I/O contention when they’re located on the same partition as the rest of the operating system. RAID, network block storage, and other devices can offer redundancy and other desirable features. Whether you’re adding more space, evaluating ways to optimize performance, or looking to take advantage of other storage features, this tutorial will guide you through relocating MySQL’s data directory.

The directions here are suitable for servers that run a single instance of MySQL. If you have multiple instances, the guide [How To Move a MySQL Data Directory to a New Location on Ubuntu 16.04](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04) can help you with directions for explicitly changing the location through configuration settings.

## Prerequisites

To complete this guide, you will need:

- **An Ubuntu 16.04 server with a non-root user with `sudo` privileges**. You can learn more about how to set up a user with these privileges in our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide.

- **A MySQL server**. If you haven’t already set one up, the [How To Install MySQL on Ubuntu 16.04](how-to-install-mysql-on-ubuntu-16-04) guide can help you.

- **A Backup of your databases**. Unless you’re working with a fresh installation of MySQL, you should ensure that you have a backup of your data. The guide [How To Backup MySQL Databases on an Ubuntu VPS](how-to-backup-mysql-databases-on-an-ubuntu-vps) can help you with this.

In this example, we’re moving the data to a block storage device mounted at `/mnt/volume-nyc1-01`. You can learn how to set one up in the [How To Use Block Storage on DigitalOcean](how-to-use-block-storage-on-digitalocean) guide.

No matter what underlying storage you use, this guide can help you move the data directory to a new location.

## Step 1 — Moving the MySQL Data Directory

To ensure the integrity of the data, we’ll shut down MySQL:

    sudo systemctl stop mysql

`systemctl` doesn’t display the outcome of all service management commands, so if you want to be sure you’ve succeeded, use the following command:

    sudo systemctl status mysql

You can be sure it’s shut down if the final line of the output tells you the server is stopped:

    Output. . .
    Jul 18 11:24:20 ubuntu-512mb-nyc1-01 systemd[1]: Stopped MySQL Community Server.

With the server shut down, we’ll move the existing database directory to the new location:

    sudo mv /var/lib/mysql /mnt/volume-nyc1-01/mysql

Next, we’ll create the symbolic link:

    sudo ln -s /mnt/volume-nyc1-01/mysql /var/lib/mysql

With the symlink in place, this seems like the right time to bring up MySQL again, but there’s one more thing to configure before we can do that successfully.

## Step 2 — Configuring AppArmor Access Control Rules

When you move the MySQL directory to a different file system than the MySQL server, you will need to create an AppArmor alias.

To add the alias, edit the AppArmor `alias` file:

    sudo nano /etc/apparmor.d/tunables/alias

At the bottom of the file, add the following alias rule:

/etc/apparmor.d/tunables/alias

    . . .
    alias /var/lib/mysql/ -> /mnt/volume-nyc1-01/mysql/,
    . . .

For the changes to take effect, restart AppArmor:

    sudo systemctl restart apparmor

**Note:**   
 If you skipped the AppArmor configuration step and tried to start `mysql`, you would run into the following error message:

    OutputJob for mysql.service failed because the control process 
    exited with error code. See "systemctl status mysql.service" 
    and "journalctl -xe" for details.

The output from both `systemctl` and `journalctl` concludes with:

    OutputJul 18 11:03:24 ubuntu-512mb-nyc1-01 systemd[1]: 
    mysql.service: Main process exited, code=exited, status=1/FAILURE

Since the messages don’t make an explicit connection between AppArmor and the data directory, this error can take some time to figure out. However, a look at the `syslog` will show the problem:

    sudo tail /var/log/syslog

    OutputNov 24 00:03:40 digitalocean kernel: 
    [437.735748] audit: type=1400 audit(1479945820.037:20): 
    apparmor="DENIED" operation="mknod" profile="/usr/sbin/mysqld" 
    name="/mnt/volume-nyc1-01/mysql/mysql.lower-test" pid=4228 
    comm="mysqld" requested_mask="c" denied_mask="c" fsuid=112 ouid=112

_Now_ we’re ready to start MySQL.

    sudo systemctl start mysql
    sudo systemctl status mysql

Once you’ve restarted MySQL, take the opportunity to ensure that your data is in order and that MySQL is functioning as expected.

## Conclusion

In this tutorial, we’ve moved MySQL’s data and used a symlink to make MySQL aware of the new location. We’ve also updated Ubuntu’s AppArmor ACLs to accommodate the adjustment. Although we were using a Block Storage device, the instructions here should be suitable for redefining the location of the data directory regardless of the underlying technology.

This approach is only suitable if you are running a single instance of MySQL. If you need to support multiple MySQL instances running on a single server, [How To Move a MySQL Data Directory to a New Location on Ubuntu 16.04](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04) can help you.
