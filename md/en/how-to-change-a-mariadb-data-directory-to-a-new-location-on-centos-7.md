---
author: Melissa Anderson
date: 2016-12-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-change-a-mariadb-data-directory-to-a-new-location-on-centos-7
---

# How To Change a MariaDB Data Directory to a New Location on CentOS 7

## Introduction

Databases grow over time, sometimes outgrowing the space on the file system. You can also run into I/O contention when they’re located on the same partition as the rest of the operating system. RAID, network block storage, and other devices can offer redundancy and other desirable features. Whether you’re adding more space, evaluating ways to optimize performance, or looking to take advantage of other storage features, this tutorial will guide you through relocating MariaDB’s data directory.

## Prerequisites

To complete this guide, you will need:

- **A CentOS 7 server with a non-root user with `sudo` privileges and MariaDB installed**. You can learn more about how to set up a user with these privileges in our [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) guide. If you haven’t already installed MariaDB, the [How To Install MariaDB on CentOS 7](how-to-install-mariadb-on-centos-7) guide can help you.

In this example, we’re moving the data to a block storage device mounted at `/mnt/volume-nyc1-01`. You can learn how to set one up in the [How To Use Block Storage on DigitalOcean](how-to-use-block-storage-on-digitalocean) guide.

No matter what underlying storage you use, this guide can help you move the data directory to a new location.

## Step 1 — Moving the MariaDB Data Directory

To prepare for moving MariaDB’s data directory, let’s verify the current location by starting an interactive session using the administrative credentials.

    mysql -u root -p

When prompted, supply the MariaDB root password. Then from the `mysql` prompt, select the data directory:

    select @@datadir;

    Output+-----------------+
    | @@datadir |
    +-----------------+
    | /var/lib/mysql/ |
    +-----------------+
    1 row in set (0.00 sec)
    

This output confirms that MariaDB is configured to use the default data directory, `/var/lib/mysql/,` so that’s the directory we need to move. Once you’ve confirmed this, type `exit` and press “ENTER” to leave the monitor:

    exit

To ensure the integrity of the data, we’ll shut down MariaDB before we actually make changes to the data directory:

    sudo systemctl stop mariadb

`systemctl` doesn’t display the outcome of all service management commands, so if you want to be sure you’ve succeeded, use the following command:

    sudo systemctl status mariadb

You can be sure it’s shut down if the final line of the output tells you the server is stopped:

    Output. . .
    Dec 16 18:29:26 mysql systemd[1]: Stopped MariaDB database server.

Now that the server is shut down, we’ll copy the existing database directory to the new location with `rsync`. Using the `-a` flag preserves the permissions and other directory properties, while`-v` provides verbose output so you can follow the progress.

**Note:** Be sure there is no trailing slash on the directory, which may be added if you use tab completion. When there’s a trailing slash, `rsync` will dump the contents of the directory into the mount point instead of transferring it into a containing `mysql` directory:

    sudo rsync -av /var/lib/mysql /mnt/volume-nyc1-01

Once the `rsync` is complete, rename the current folder with a .bak extension and keep it until we’ve confirmed the move was successful. By re-naming it, we’ll avoid confusion that could arise from files in both the new and the old location:

    sudo mv /var/lib/mysql /var/lib/mysql.bak

Now we’re ready to turn our attention to configuration.

## Step 2 — Pointing to the New Data Location

MySQL has several ways to override configuration values. By default, the `datadir` is set to `/var/lib/mysql` in the `/etc/my.cnf` file. Edit this file to reflect the new data directory:

    sudo vi /etc/my.cnf

Find the line that begins with `datadir=` and change the path which follows to reflect the new location. In addition, we since the socket was previously located in the data directory, we’ll need to update it to the new location:

/etc/my.cnf 

    [mysqld]
    . . .
    datadir=/mnt/volume-nyc1-01/mysql
    socket=/mnt/volume-nyc1-01/mysql/mysql.sock
    . . .

After updating the existing lines, we’ll need to add configuration for the `mysql` client. Insert the following settings at the bottom of the file so won’t split up directives in the `[mysqld]` block and above the `include` line:

/etc/my.cnf 

    [client]
    port=3306
    socket=/mnt/volume-nyc1-01/mysql/mysql.sock
    
    !includedir /etc/my.cnf.d

When you’re done, hit `ESCAPE`, then type `:wq!` to save and exit the file.

## Step 3 — Restarting MariaDB

Now that we’ve updated the configuration to use the new location, we’re ready to start MariaDB and verify our work.

    sudo systemctl start mariadb
    sudo systemctl status mariadb

To make sure that the new data directory is indeed in use, start the monitor.

    mysql -u root -p

Look at the value for the data directory again:

    select @@datadir;

    Output+----------------------------+
    | @@datadir |
    +----------------------------+
    | /mnt/volume-nyc1-01/mysql/ |
    +----------------------------+
    1 row in set (0.01 sec)

Type `exit` to leave the monitor.

Now that you’ve restarted MariaDB and confirmed that it’s using the new location, take the opportunity to ensure that your database is fully functional. Once you’ve verified the integrity of any existing data, you can remove the backup data directory with `sudo rm -Rf /var/lib/mysql.bak`.

## Conclusion

In this tutorial, we’ve moved MariaDB’s data directory to a new location. Although we were using a Block Storage device, the instructions here should be suitable for redefining the location of the data directory regardless of the underlying technology.

Since MariaDB is designed as a drop-in replacement for MySQL, you can learn more about managing data directories from these sections in the official MySQL documentation:

- [The MySQL Data Directory](https://dev.mysql.com/doc/refman/5.7/en/data-directory.html)
- [Setting Up Multiple Data Directories](https://dev.mysql.com/doc/refman/5.7/en/multiple-data-directories.html)
