---
author: Brian Boucheron
date: 2018-04-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-vestacp-and-migrate-user-data
---

# How To Install VestaCP and Migrate User Data

## Introduction

The [Vesta Control Panel](https://vestacp.com/) is a free, open source control panel with website, email, database, and DNS functionalities. In this tutorial you will install the control panel on an Ubuntu or CentOS server, update the default admin interface port, and learn how to migrate user data from an existing installation.

**Note:** On April 8th, 2018, a vulnerability was discovered in VestaCP that allowed attackers to compromise host systems and send malicious traffic targeting other servers. As a result, DigitalOcean has disabled VestaCP’s default `port 8083`. This tutorial will update the installation to use `port 5600` instead. For more up to date information on this vulnerability, please read [this Community Q&A post](https://www.digitalocean.com/community/questions/how-do-i-determine-the-impact-of-vestacp-vulnerability-from-april-8th-2018).

## Prerequisites

The following resources are required to complete this tutorial:

- An **Ubuntu 16.04** or **CentOS 7** server
- A domain name pointed at your server. [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) will show you how to manage a domain with the DigitalOcean control panel. We will use **panel.example.com** throughout this tutorial
- Two **A** records pointing **ns1.example.com** and **ns2.example.com** to your server

## Installing VestaCP

Log into your server via SSH. Because VestaCP handles the creation of individual user accounts, this tutorial will assume you’re logging in as the **root** user to do the initial setup.

After logging in, move to the `/tmp` temporary directory and download the installation script:

    cd /tmp
    curl -O https://assets.digitalocean.com/vesta/install-vesta-do.sh

This script is a wrapper around the official VestaCP installation script. You can open it in your favorite text editor to see what it does. It uses the official script to install the software, then updates the admin interface to use `port 5600`.

Make the script executable:

    chmod +x install-vesta-do.sh

Finally, run the script to install VestaCP. You may pass in any of the options supported by the official installation script, which you can find on [VestaCP’s installation page](https://vestacp.com/install/). We will use the `--force` option, because otherwise the installer may complain about an existing **admin** group on some machines:

    ./install-vesta-do.sh --force

The script will interactively ask a few questions, then take around 5–15 minutes to complete the installation. The URL for your admin interface will be printed out, along with the admin login information:

    OutputCongratulations, you have just successfully installed Vesta Control Panel
    
        https://panel.example.com:8083
        username: admin
        password: a-random-password

**Note:** these initial URLs will be incorrect, as they’ll still be using `port 8083`. The very last line of the installation output should be

    Configuring to use port 5600 as admin port

Update all `port 8083` references to `port 5600` before attempting to connect. The example URL would be **[https://panel.example.com:5600](https://panel.example.com:5600)**, for instance. After the initial installation, any subsequent emails to your users will use the correct port.

VestaCP is now up and running on your server. If you have an existing VestaCP installation, continue on to the next step, where we’ll migrate your user data to the new server.

## Migrating VestaCP User Data Between Servers

VestaCP comes with some scripts to help back up and restore user data. We will migrate all users using these scripts.

On **the server you are migrating from** , use `v-backup-users` to backup all users:

    v-backup-users

**Note:** If you get a `command not found` error when running the backup program, you may need to update your `PATH` by running:

    export PATH=$PATH:/usr/local/vesta/bin

This is handled automatically if you log out and back in after installing VestaCP.

The command will output no status information. You can check for the resulting backup files in `/backup`:

    ls /backup

    Outputadmin.2018-04-11_13-07-02.tar exampleuser.2018-04-11_13-07-02.tar

The above output shows two users backed up, **admin** and **exampleuser**. To transfer these files to your new server, we’ll use the `scp` utility. The following steps will work the same whether you have one backup file or multiple.

If you’re using password authentication on the new server, it’s easiest to transfer the files directly from the old server to the new, like so:

    scp /backup/* root@panel.example.com:/backup/

This won’t easily work if you use SSH keys instead of passwords. In that case it’s easiest to download the files to your local machine, then upload them to the new server. We will create a temporary local directory to hold the files first. On your local command line, do the following:

    mkdir /tmp/vesta-backups
    scp root@old-server.example.com:/backup/* /tmp/vesta-backups/
    scp /tmp/vesta-backups/* root@panel.example.com:/backup/

Now, with the backup `.tar` files uploaded to the new server’s `/backup` directory, log back in to the new server and use the `v-restore-user` command to complete the process:

    v-restore-user admin admin.2018-04-11_13-07-02.tar

Note that the `v-restore-user` command needs the **filename** of the `.tar` file, **but not the full path to the file**. It is assumed that the filename you provide is in the `/backup` directory.

The command will output a summary of the items it has restored. Repeat this command for each user you need to restore, replacing the username and `.tar` file name as need. Your migration is now complete.

## Conclusion

In this tutorial you installed the VestaCP control panel, updated the port of its default admin interface, and migrated user data from a preexisting installation. To learn more about using the VestaCP software to set up websites and email, please refer to steps 3 and 4 of [How To Install VestaCP and Set Up a Website on Ubuntu 14.04](how-to-install-vestacp-and-set-up-a-website-on-ubuntu-14-04). You can also refer to [the official documentation](http://vestacp.com/docs/).
