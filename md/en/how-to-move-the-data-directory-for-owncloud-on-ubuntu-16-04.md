---
author: Michael Lenardson
date: 2016-08-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-move-the-data-directory-for-owncloud-on-ubuntu-16-04
---

# How To Move the Data Directory for ownCloud on Ubuntu 16.04

## Introduction

ownCloud is a capable solution for storing your digital life on a private server. By default, data is saved on the same partition as the operating system, which may lead to a lack of free disk space. For instance, with high-resolution pictures and high-definition videos continuously being backed up, it is easy to run out of space. As your storage needs grow, it may become necessary to move ownCloud’s `data` directory. Whether you are adding more space or just looking to change the default storage location, this tutorial will guide you through relocating ownCloud’s `data` directory.

## Prerequisites

Before you begin using this guide, an ownCloud server needs to be installed and configured. You can set one up by following [this guide](how-to-install-and-configure-owncloud-on-ubuntu-16-04). If our installation guide was used, then the `data` directory is in ownCloud’s web root, which by default is located at `/var/www/owncloud`.

In this example, we are moving ownCloud’s `data` directory to an attached additional storage volume that is mounted at `/mnt/owncloud`. If you are using DigitalOcean, you can mount a block storage volume to fulfill that role by following our [How To Use Block Storage on DigitalOcean](how-to-use-block-storage-on-digitalocean) guide.

Regardless of the underlying storage being used, this guide can help you move the `data` directory for ownCloud to a new location.

## Step 1 – Moving the ownCloud Data Directory

When ownCloud is in use and backend changes are being made, there is the possibility that data may become corrupt or damaged. To prevent that from happening, we will stop Apache with the `systemctl` utility:

    sudo systemctl stop apache2

Some of the service management commands do not display an output. To verify that Apache is no longer running, use the `systemctl` utility with the `status` command:

    sudo systemctl status apache2

The last line of the output should state that it’s stopped.

    Output. . .
    Stopped LSB: Apache2 web server.

**Warning:** It is highly recommended that you backup your data prior to making any changes.

Copy the contents of the `data` directory to a new directory using the `rsync` command. Using the `-a` flag preserves the permissions and other directory properties, while the `-v` flag provides verbose output so you can monitor the progress. In the example below, we back up our content into a new directory, `owncloud-data-bak`, within our user’s home directory.

    sudo rsync -av /var/www/owncloud/data/ ~/owncloud-data-bak/

&nbsp;  
With Apache stopped, we will move the `data` directory to the new location using the `mv` command:

    sudo mv /var/www/owncloud/data /mnt/owncloud/

With the `data` directory relocated, we will update ownCloud so that it’s aware of this change.

## Step 2 – Pointing ownCloud to the New Data Location

ownCloud stores its configurations in a single file, which we will edit with the new path to the `data` directory.

Open the file with the `nano` editor:

    sudo nano /var/www/owncloud/config/config.php

Find the `datadirectory` variable and update its value with the new location.

/var/www/owncloud/config/config.php

    . . .
      'datadirectory' => '/mnt/owncloud/data',
    . . .

With the `data` directory moved and the configuration file updated, we are ready to confirm that our files are accessible from the new storage location.

## Step 3 – Starting Apache

Now, we can start Apache using the `systemctl` command and regain access to ownCloud:

    sudo systemctl start apache2

Finally, navigate to the ownCloud web interface:

    https://server_domain_or_IP/owncloud

ownCloud is a web application and does not have a way to verify the integrity of its configuration. Therefore, access to the web interface means the operation was successful.

## Conclusion

In this tutorial, we expanded the amount of disk space available to ownCloud. We accomplished this by moving its `data` directory to an additional storage volume. Although we were using a block storage device, the instructions here should be applicable for relocating the `data` directory regardless of the technology being used.
