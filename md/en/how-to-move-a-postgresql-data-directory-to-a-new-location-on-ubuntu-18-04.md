---
author: Melissa Anderson, Mark Drake
date: 2018-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-move-a-postgresql-data-directory-to-a-new-location-on-ubuntu-18-04
---

# How To Move a PostgreSQL Data Directory to a New Location on Ubuntu 18.04

## Introduction

Databases grow over time, sometimes outgrowing the space on their original file system. When they’re located on the same partition as the rest of the operating system, this can also potentially lead to I/O contention.

RAID, network block storage, and other devices can offer redundancy and improve scalability, along with other desirable features. Whether you’re adding more space, evaluating ways to optimize performance, or looking to take advantage of other storage features, this tutorial will guide you through relocating PostgreSQL’s data directory.

## Prerequisites

To complete this guide, you will need:

- An Ubuntu 18.04 server with a non-root user with `sudo` privileges. You can learn more about how to set up a user with these privileges in our [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) guide.

- PostgreSQL installed on your server. If you haven’t already set this up, the [How To Install and Use PostgreSQL on Ubuntu 18.04](how-to-install-and-use-postgresql-on-ubuntu-18-04) guide can help you.

In this example, we’re moving the data to a block storage device mounted at `/mnt/volume_nyc1_01`. If you are using Block Storage on DigitalOcean, [this guide](how-to-use-block-storage-on-digitalocean) can help you mount your volume before continuing with this tutorial.

Regardless of what underlying storage you use, though, the following steps can help you move the data directory to a new location.

## Step 1 — Moving the PostgreSQL Data Directory

Before we get started with moving PostgreSQL’s data directory, let’s verify the current location by starting an interactive PostgreSQL session. In the following command, `psql` is the command to enter the interactive monitor and `-u postgres` tells `sudo` to execute `psql` as the system’s **postgres** user:

    sudo -u postgres psql

Once you have the PostgreSQL prompt opened up, use the following command to show the current data directory:

    SHOW data_directory;

    Output data_directory       
    ------------------------------
    /var/lib/postgresql/10/main
    (1 row)
    

This output confirms that PostgreSQL is configured to use the default data directory, `/var/lib/postgresql/10/main`, so that’s the directory we need to move. Once you’ve confirmed the directory on your system, type `\q` and press `ENTER` to close the PostgreSQL prompt.

To ensure the integrity of the data, stop PostgreSQL before you actually make changes to the data directory:

    sudo systemctl stop postgresql

`systemctl` doesn’t display the outcome of all service management commands. To verify that you’ve successfully stopped the service, use the following command:

    sudo systemctl status postgresql

The final line of the output should tell you that PostgreSQL has been stopped:

    Output. . .
    Jul 12 15:22:44 ubuntu-512mb-nyc1-01 systemd[1]: Stopped PostgreSQL RDBMS.

Now that the PostgreSQL server is shut down, we’ll copy the existing database directory to the new location with `rsync`. Using the `-a` flag preserves the permissions and other directory properties, while `-v` provides verbose output so you can follow the progress. We’re going to start the `rsync` from the `postgresql` directory in order to mimic the original directory structure in the new location. By creating that `postgresql` directory within the mount-point directory and retaining ownership by the PostgreSQL user, we can avoid permissions problems for future upgrades.

**Note:** Be sure there is no trailing slash on the directory, which may be added if you use tab completion. If you do include a trailing slash, `rsync` will dump the contents of the directory into the mount point instead of copying over the directory itself.

The version directory, `10`, isn’t strictly necessary since we’ve defined the location explicitly in the `postgresql.conf` file, but following the project convention certainly won’t hurt, especially if there’s a need in the future to run multiple versions of PostgreSQL:

    sudo rsync -av /var/lib/postgresql /mnt/volume_nyc1_01

Once the copy is complete, we’ll rename the current folder with a `.bak` extension and keep it until we’ve confirmed that the move was successful. This will help to avoid confusion that could arise from having similarly-named directories in both the new and the old location:

    sudo mv /var/lib/postgresql/10/main /var/lib/postgresql/10/main.bak

Now we’re ready to configure PostgreSQL to access the data directory in its new location.

## Step 2 — Pointing to the New Data Location

By default, the `data_directory` is set to `/var/lib/postgresql/10/main` in the `/etc/postgresql/10/main/postgresql.conf` file. Edit this file to reflect the new data directory:

    sudo nano /etc/postgresql/10/main/postgresql.conf

Find the line that begins with `data_directory` and change the path which follows to reflect the new location. In the context of this tutorial, the updated directive will look like this:

/etc/postgresql/10/main/postgresql.conf 

    . . .
    data_directory = '/mnt/volume_nyc1_01/postgresql/10/main'
    . . .

Save and close the file by pressing `CTRL + X`, `Y`, then `ENTER`. This is all you need to do to configure PostgreSQL to use the new data directory location. All that’s left at this point is to start the PostgreSQL service again and check that it is indeed pointing to the correct data directory.

## Step 3 — Restarting PostgreSQL

After changing the `data-directory` directive in the `postgresql.conf` file, go ahead and start the PostgreSQL server using `systemctl`:

    sudo systemctl start postgresql

To confirm that the PostgreSQL server started successfully, check its status by again using `systemctl`:

    sudo systemctl status postgresql

If the service started correctly, you will see the following line at the end of this command’s output:

    Output. . .
    Jul 12 15:45:01 ubuntu-512mb-nyc1-01[1]: Started PostgreSQL RDBMS.
    . . .

Lastly, to make sure that the new data directory is indeed in use, open the PostgreSQL command prompt.

    sudo -u postgres psql

Check the value for the data directory again:

    SHOW data_directory;

    Output data_directory
    -----------------------------------------
    /mnt/volume_nyc1_01/postgresql/10/main
    (1 row)
    

This confirms that PostgreSQL is using the new data directory location. Following this, take a moment to ensure that you’re able to access your database as well as interact with the data within. Once you’ve verified the integrity of any existing data, you can remove the backup data directory:

    sudo rm -Rf /var/lib/postgresql/10/main.bak

With that, you have successfully moved your PostgreSQL data directory to a new location.

## Conclusion:

If you’ve followed along, your database should be running with its data directory in the new location and you’ve completed an important step toward being able to scale your storage. You might also want to take a look at [5 Common Server Setups For Your Web Application](5-common-server-setups-for-your-web-application) for ideas on how to create a server infrastructure to help you scale and optimize web applications.
