---
author: Brian Boucheron
date: 2017-10-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-data-to-an-object-storage-service-with-the-restic-backup-client
---

# How To Back Up Data to an Object Storage Service with the Restic Backup Client

## Introduction

[Restic](https://restic.github.io/) is a secure and efficient backup client written in the Go language. It can backup local files to a number of different backend repositories such as a local directory, an SFTP server, or an S3-compatible object storage service.

In this tutorial we will install Restic and initialize a repository on an object storage service. We’ll then back up some files to the repository. Finally, we’ll automate our backups to take hourly snapshots and automatically prune old snapshots when necessary.

## Prerequisites

For this tutorial, you need a UNIX-based computer with some files you’d like to back up. Though Restic is available for Mac, Linux, and Windows, the commands and techniques used in this tutorial will only work on MacOS and Linux.

Restic requires a good amount of memory to run, so you should have 1GB or more of RAM to avoid receiving errors.

You will also need to know the following details about your object storage service:

- Access Key
- Secret Key
- Server URL
- Bucket Name

If you are using the [DigitalOcean Spaces](https://www.digitalocean.com/products/object-storage/) object storage service, you can set up a Space and get all the above information by following our tutorial [How to Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key).

Once you have your object storage information, proceed to the next section to install the Restic software.

## Installing the Restic Backup Client

Restic is available as a precompiled executable for many platforms. This means we can download a single file and run it, no package manager or dependencies necessary.

To find the right file to download, first use your web browser to navigate to [Restic’s release page on GitHub](https://github.com/restic/restic/releases/latest). You’ll find a list of files under the **Downloads** header.

For a 64-bit Linux system (the most common server environment) you want the file ending in `_linux_amd64.bz2`.

For MacOS, look for the file with `_darwin_amd64.bz2`.

Right-click on the correct file for your system, then choose **Copy Link Address** (the wording may be slightly different in your browser). This will copy the download URL to your clipboard.

Next, in a terminal session on the computer you’re backing up (if it’s a remote machine you may need to log in via SSH first), make sure you’re in your home directory, then download the file with `curl`:

    cd ~
    curl -LO https://github.com/restic/restic/releases/download/v0.7.3/restic_0.7.3_linux_amd64.bz

Unzip the file we downloaded:

    bunzip2 restic*

Then copy the file to `/usr/local/bin` and update its permissions to make it executable. We’ll need to use `sudo` for these two actions, as a normal user doesn’t have permission to write to `/usr/local/bin`:

    sudo cp restic* /usr/local/bin/restic
    sudo chmod a+x /usr/local/bin/restic

Test that the installation was successful by calling the `restic` command with no arguments:

    restic

Some help text should print to your screen. If so, the `restic` binary has been installed properly. Next, we’ll create a configuration file for Restic, then initialize our object storage repository.

### Creating a Configuration File

Restic needs to know our access key, secret key, object storage connection details, and repository password in order to initialize a repository we can then back up to. We are going to make this information available to Restic using _environment variables_.

Environment variables are bits of information that you can define in your shell, which are passed along to the programs you run. For instance, every program you run on the command line can see your `$PWD` environment variable, which contains the path of the current directory.

It’s common practice to put sensitive tokens and passwords in environment variables, because specifying them on the command line is not secure. Since we’re going to be automating our backups later on, we’ll save this information in a file where our script can access it.

First, open a file in your home directory:

    nano ~/.restic-env

This will open an empty file with the `nano` text editor. When we’re done, the file will consist of four `export` commands. These `export` statements define environment variables and make them available to any programs you run in the future:

.restic-env

    export AWS_ACCESS_KEY_ID="your-access-key"
    export AWS_SECRET_ACCESS_KEY="your-secret-key"
    export RESTIC_REPOSITORY="s3:server-url/bucket-name"
    export RESTIC_PASSWORD="a-strong-password"

The access and secret keys will be provided by your object storage service. You may want to generate a unique set of keys just for Restic, so that access can be easily revoked in case the keys are lost or compromised.

An example `RESTIC_REPOSITORY` value would be: `s3:nyc3.digitaloceanspaces.com/example-bucket`. If you need to connect to a server on a non-standard port or over unsecured HTTP-only, include that information in the URL like so `s3:http://example-server:3000/example-bucket`.

`RESTIC_PASSWORD` defines a password that Restic will use to encrypt your backups. This encryption happens locally, so you can back up to an untrusted offsite server without worrying about the contents of your files being exposed.

You should choose a strong password here, and copy it somewhere safe for backup. One way to generate a strong random password is to use the `openssl` command:

    openssl rand -base64 24

    Outputj8CGOSdz8ibUYK137wtdiD0SJiNroGUp

This outputs a 24-character random string, which you can copy and paste into the configuration file.

Once all the variables are filled out properly, save and close the file.

## Initializing the Repository

To load the configuration into our shell environment, we `source` the file we just created:

    source ~/.restic-env

You can check to make sure this worked by printing out one of the variables:

    echo $RESTIC_REPOSITORY

Your repository URL should print out. Now we can initialize our repository with the Restic command:

    restic init

    Outputcreated restic backend 57f73c1afc at s3:nyc3.digitaloceanspaces.com/example-bucket
    
    Please note that knowledge of your password is required to access
    the repository. Losing your password means that your data is
    irrecoverably lost.

The repository is now ready to receive backup data. We’ll send that data next.

## Backing Up a Directory

Now that our remote object storage repository is initialized, we can push backup data to it. In addition to encryption, Restic does diffing, and de-duplication while backing up. This means that our first backup will be a full backup of all files, and subsequent backups will only have to transmit new files and changes. Additionally, duplicate data will be detected and not written to the backend, which saves space.

Before we back up, if you’re testing things out on a bare system and need some example files to back up, create a simple text file in your home directory:

    echo "sharks have no organs for producing sound" >> ~/facts.txt

This will create a `facts.txt` file. Now back it up, along with the rest of your home directory:

    restic backup ~

    Outputscan [/home/sammy]
    scanned 4 directories, 14 files in 0:00
    [0:04] 100.00% 2.558 MiB/s 10.230 MiB / 10.230 MiB 18 / 18 items 0 errors ETA 0:00
    duration: 0:04, 2.16MiB/s
    snapshot 427696a3 saved

Restic will work for a bit, showing you live status updates along the way, then output the new snapshot’s ID (highlighted above).

**Note:** If you want to back up a different directory, substitute the `~` above with the path of the directory. You may need to use `sudo` in front of `restic backup` if the target directory is not owned by your user. If you need `sudo` to back up, remember to use it again when restoring the snapshot, otherwise you may get some errors about not being able to properly set permissions.

Next we’ll learn how to find out more information about the snapshots stored in our repository.

## Listing Snapshots

To list out the backups stored in the repository, use the `snapshots` subcommand:

    restic snapshots

    OutputID Date Host Tags Directory
    ----------------------------------------------------------------------
    427696a3 2017-10-23 16:37:17 restic-test /home/sammy

You can see the snapshot ID we received during our first backup, a timestamp for when the snapshot was taken, the hostname, tags, and the directory that was backed up.

Our **Tags** column is blank, because we didn’t use any in this example. You can add tags to a snapshot by including a `--tag` flag followed by the tag name. You can specify multiple tags by repeating the `--tag` option.

Tags can be useful to filter snapshots later on when you’re setting up retention policies, or when searching manually for a particular snapshot to restore.

The **Host** is included in the listing because you can send snapshots from multiple hosts to a single repository. You’ll need to copy the repository password to each machine. You can also set up multiple passwords for your repository to have more fine-grained access control. You can find out more information about managing repository passwords in [the official Restic docs](https://restic.readthedocs.io/en/stable/manual.html#manage-repository-keys).

Now that we’ve got a snapshot uploaded, and know how to list out our repository contents, we’ll use our snapshot ID to test restoring a backup.

## Restoring a Snapshot

We’re going to restore an entire snapshot into a temporary directory to verify that everything is working properly. Use a snapshot ID from the listing in the previous step. We’ll send the restored files to a new directory in `/tmp/restore`:

    restic restore 427696a3 --target /tmp/restore

    Outputrestoring <Snapshot 427696a3 of [/home/sammy] at 2017-10-23 16:37:17.573706791 +0000 UTC by sammy@restic-test> to /tmp/restore

Change to the directory and list its contents:

    cd /tmp/restore
    ls

You should see the directory we backed up. In this example it would be the user **sammy** ’s home directory. Enter the restored directory and list out the files inside:

    cd sammy
    ls

    Outputfacts.txt restic_0.7.3_linux_amd64

Our `facts.txt` file is there, along with the restic binary that we extracted at the beginning of the tutorial. Print `facts.txt` to the screen to make sure it’s what we expected:

    cat facts.txt

You should see the shark fact that we put in the file previously. It worked!

**Note:** If you don’t want to restore all the files in a snapshot, you can use the `--include` and `--exclude` options to fine-tune your selection. Read [the **Restore** section of the Restic documentation](https://restic.readthedocs.io/en/stable/manual.html#restore-a-snapshot) to find out more.

Now that we know backup and restore is working, let’s automate the creation of new snapshots.

## Automating Backups

Restic includes a `forget` command to help maintain a running archive of snapshots. You can use `restic forget --prune` to set policies on how many backups to keep daily, hourly, weekly, and so on. Backups that don’t fit the policy will be purged from the repository.

We will use the `cron` system service to run a backup task every hour. First, open up your user’s crontab:

    crontab -e

You may be prompted to choose a text editor. Select your favorite — or `nano` if you have no opinion — then press `ENTER`. The default crontab for your user will open up in your text editor. It may have some comments explaining the crontab syntax. At the end of the file, add the following to a new line:

crontab

    . . .
    42 * * * * . /home/sammy/.restic-env; /usr/local/bin/restic backup -q /home/sammy; /usr/local/bin/restic forget -q --prune --keep-hourly 24 --keep-daily 7

Let’s step through this command. The `42 * * * *` defines when `cron` should run the task. In this case, it will run in the 42nd **minute** of every **hour** , **day** , **month** , and **day of week**. For more information on this syntax, read our tutorial [How To Use Cron To Automate Tasks](how-to-use-cron-to-automate-tasks-on-a-vps).

Next, `. /home/sammy/.restic-env;` is equivalent to `source ~/.restic-env` which we ran previously to load our keys and passwords into our shell environment. This has the same effect in our crontab: subsequent commands on this line will have access to this information.

`/usr/local/bin/restic backup -q /home/sammy;` is our Restic backup command. We use the full path to the `restic` binary, because the `cron` service won’t automatically look in `/usr/local/bin` for commands. Similarly, we spell out the home folder path explicitly with `/home/sammy` instead of using the `~` shortcut. It’s best to be as explicit as possible when writing a command for `cron`. We use the `-q` flag to suppress status output from Restic, since we wont be around to read it.

Finally, `/usr/local/bin/restic forget -q --prune --keep-hourly 24 --keep-daily 7` will prune old snapshots that are no longer needed based on the specified retention flags. In this example, we’re keeping 24 hourly snapshots, and 7 daily snapshots. There are also options for weekly, monthly, yearly, and tag-based policies.

When you’ve updated the command to fit your needs, save the file and exit the text editor. The crontab will be installed and activated. After a few hours run `restic snapshots` again to verify that new snapshots are being uploaded.

## Conclusion

In this tutorial, we’ve created a configuration file for Restic with our object storage authentication details, used Restic to initialize a repository, backed up some files, and tested the backup. Finally, we automated the process with cron.

Restic has more flexibility and more features than were discussed here. To learn more about Restic, take a look at their [official documentation](https://restic.readthedocs.io/en/stable/index.html) or [main website](https://restic.github.io/).
