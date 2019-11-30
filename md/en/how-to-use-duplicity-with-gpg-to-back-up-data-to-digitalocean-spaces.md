---
author: Kathleen Juell
date: 2018-04-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-duplicity-with-gpg-to-back-up-data-to-digitalocean-spaces
---

# How To Use Duplicity with GPG to Back Up Data to DigitalOcean Spaces

## Introduction

[Duplicity](http://duplicity.nongnu.org/index.html) is a command-line utility written in Python that produces encrypted tar volumes for storage on a local or remote repository. It uses the [GNU Privacy Guard (GPG)](https://www.gnupg.org/) to encrypt and sign its archives and the rsync algorithm to create incremental, space-efficient backups. Backups can be transmitted to a variety of repositories, including local file storage, SFTP or FTP servers, and S3-compatible object stores.

In this tutorial, we will install Duplicity and go over how to back up project data to DigitalOcean Spaces, an S3-compatible object storage service. We will create a Spaces repository for this purpose, and cover how to manually back up data to it. Finally, we will automate this process by creating a script that will set up incremental and weekly full backup schedules.

## Prerequisites

For this tutorial, you will need:

- One Ubuntu 16.04 server, set up following our [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04). After following this tutorial, you should have a non-root sudo user.

- A DigitalOcean Space and API key, created by following [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key). Be sure to note the following credentials for your Space:

Once you have your Space set up and this information in hand, you can move on to installing Duplicity.

## Installing Duplicity

To get an up-to-date version of Duplicity, we can install it from the [Duplicity releases Personal Package Archive (PPA)](https://launchpad.net/%7Eduplicity-team/+archive/ubuntu/ppa):

    sudo apt-add-repository ppa:duplicity-team/ppa

We will also install the `python-boto` package to have access to [Boto](https://github.com/boto/boto), a Python package that provides interfaces to Amazon Web Services. This will help us take advantage of Spaces’ interoperability with the AWS S3 API. We will install `python-boto` from the official Ubuntu repositories, since this version is compatible with the version of Python that ships with our Ubuntu server image. If you would prefer to use [Boto3](https://github.com/boto/boto3), you can install it from source, although feature compatibility with Python 3.3+ is still under development.

In addition to `python-boto`, we will also install [Haveged](http://www.issihosts.com/haveged/), a tool that will help us generate the [_entropy_](how-to-setup-additional-entropy-for-cloud-servers-using-haveged) necessary to create our GPG keys. In order to create these keys, GPG draws on the level of entropy or unpredictability in our system. Installing `haveged` will help us speed up the key creation process.

Before installing these packages, update the local repository index:

    sudo apt-get update

Then install `duplicity`, `python-boto`, and `haveged` by typing:

    sudo apt-get install duplicity haveged python-boto

Press `y` when prompted to confirm installation. We now have Duplicity installed on our system and are ready to create our project folders and configuration files.

## Creating a Backup Directory

To demonstrate how the backup process works, we will create a directory for our backups in our non-root user’s home directory, along with some sample data. We will call our directory `sammy_backups`:

    mkdir ~/sammy_backups

Next, create a sample project file called `historical_sharks.txt`:

    echo "The ancient Megalodon shark reached lengths of up to 59 feet, and is widely regarded as one of history's most fearsome predators." >> ~/sammy_backups/historical_sharks.txt

With our backup directory and test data in place, we are ready to generate a GPG key for our non-root user.

## Generating GPG Keys

Next, we will generate a GPG key pair for our user. To ensure the secure transmission of information, GPG uses public key encryption. What this means in our context is that data will be encrypted to our public key and sent to our repository. For more about GPG keys and encryption see our tutorial on [How To Use GPG to Sign and Encrypt Messages](how-to-use-gpg-to-encrypt-and-sign-messages).

Our keyrings will be stored on our user account in a directory called `~/.gnupg`, which will be created when we generate the keys. When we use the `duplicity` command, we will specify a public key identifier that points to our key pair. Using this identifier enables data encryption and the signature that verifies our ownership of the private key. The encrypted data will be transmitted to our repository, where it will be difficult to infer much more than file size and upload time from the files themselves. This protects our data, which our user can restore in full at any time with the private key.

GPG should be installed on our server by default. To test this, type:

    gpg --version

Once you have verified that GPG is installed, you can generate a key pair as follows:

    gpg --gen-key

You will be asked a series of questions to configure your keys:

- Type of key. Select **(1) RSA and RSA (default)**.
- Size of key. Pressing `ENTER` will confirm the default size of **2048** bits.
- Key expiration date. By entering **1y** , we will create a key that expires after one year.
- Confirm your choices. You can do this by entering **y**.
- User ID/Real name. Enter **your name**. 
- Email address. Enter **your email address**.
- Comment. Here, you can enter an **optional comment** that will be visible with your signature.
- Change (N)ame, ©omment, (E)mail or (O)kay/(Q)uit? Type **O** if you are ready to proceed.
- Enter passphrase. You will be asked to enter a **passphrase** here. **Be sure to take note of this passphrase**. We will refer back to it throughout the rest of this tutorial as `your-GPG-key-passphrase`.

After you have created these settings, `gpg` will generate the keys based on the level of entropy in the system. Since we installed `haveged`, our keys should be generated either very quickly or right away. You will see output that includes the following:

    Output...
    gpg: /home/sammy/.gnupg/trustdb.gpg: trustdb created
    gpg: key your-GPG-public-key-id marked as ultimately trusted
    public and secret key created and signed.
    ...

Take note of `your-GPG-public-key-id`, as we will be using it in the next section to configure our local environment variables.

## Creating Manual Backups

We will now set environment variables so we do not need to enter any confidential information on the command line while running the `duplicity` command. These variables will be available to our user during our current session, and we will store them in a hidden directory so that they are available for later use. The variables that `duplicity` will need, which we will define as environment variables, include our Spaces Access Key and Secret, and our GPG public key ID and passphrase.

To begin, let’s create a hidden directory in our user’s home directory that will store the configuration file:

    mkdir ~/.duplicity

Next, let’s create a file called `.env_variables.conf` to define our variables, which we will do using `export` statements. These statements will make the variables available to programs for later use. Open the file by typing:

    nano ~/.duplicity/.env_variables.conf

Within the file, set your Spaces Access Key and Secret, as well as your GPG public key ID and passphrase:

~/.duplicity/.env\_variables.conf

    export AWS_ACCESS_KEY_ID="your-access-key"
    export AWS_SECRET_ACCESS_KEY="your-secret-key"
    export GPG_KEY="your-GPG-public-key-id"
    export PASSPHRASE="your-GPG-key-passphrase"

Save and close the file when you are finished.

We can now set permissions on the file to ensure that only our current non-root user has read and write access:

    chmod 0600 ~/.duplicity/.env_variables.conf

Make these variables available for use in the current Bash session by typing:

    source ~/.duplicity/.env_variables.conf

Next, we will run `duplicity` to create a manual, full backup of our `~/sammy_backups` directory. Running `duplicity` without the `full` action will create an initial full backup, followed by incremental backups. We will create a full backup in our first use of the command, but should you wish to create another full manual backup of this directory, you would need to specify the `full` action.

Other options that we will define in our command include:

- `--verbosity`: This will specify the level of information we would like in our output. We will specify `info`, which will provide more detail than the default `notice` setting.
- `--encrypt-sign-key`: This will tell `duplicity` to encrypt to the public key in the pair we identified with `your-GPG-public-key-id` in the `GPG_KEY` variable. It will also tell `duplicity` to use the same identifier to enable the signing function. 
- `--log-file`: This option will specify a location for the log files that will also be available to other programs. This will give us a straightforward place to look in case we need to troubleshoot. We will specify the log file location as `/home/sammy/.duplicity/info.log`.

Finally, we will specify the directory we are backing up and our repository endpoint. We will back up the `~/sammy_backups` directory in our user’s home directory. Our repository will be our Space, which we will define using the following information: `s3://spaces_endpoint/bucket_name/`. You can determine your endpoint and bucket name as follows: if the URL of your Space is `https://sammys-bucket.nyc3.digitaloceanspaces.com`, then `sammys-bucket` is your bucket name, and `nyc3.digitaloceanspaces.com` is your endpoint.

Our `duplicity` command will ultimately look like this:

    duplicity --verbosity info --encrypt-sign-key=$GPG_KEY --log-file /home/sammy/.duplicity/info.log /home/sammy/sammy_backups \
    s3://nyc3.digitaloceanspaces.com/sammys-bucket/

After running this command, we will see output like the following:

    Output...
    --------------[Backup Statistics]--------------
    StartTime 1522417021.39 (Fri Mar 30 13:37:01 2018)
    EndTime 1522417021.40 (Fri Mar 30 13:37:01 2018)
    ElapsedTime 0.01 (0.01 seconds)
    SourceFiles 2
    SourceFileSize 4226 (4.13 KB)
    NewFiles 2
    NewFileSize 4226 (4.13 KB)
    DeletedFiles 0
    ChangedFiles 0
    ChangedFileSize 0 (0 bytes)
    ChangedDeltaSize 0 (0 bytes)
    DeltaEntries 2
    RawDeltaSize 130 (130 bytes)
    TotalDestinationSizeChange 955 (955 bytes)
    Errors 0
    -------------------------------------------------

To check that the files uploaded to your Space as intended, you can navigate to your [Spaces page in the DigitalOcean control panel](https://cloud.digitalocean.com/spaces) to check that they are there.

## Restoring Files

To test that we can restore our data, we will now remove our sample file and restore it from our repository. To restore files with Duplicity, we can use the `--file-to-restore` option. It is also necessary to reverse the order of items in our `duplicity` command: our repository URL will now act as the origin, and our backup directory will be the destination for our restored file.

Remove the file by typing:

    rm ~/sammy_backups/historical_sharks.txt

Check to make sure that the file was removed:

    cat ~/sammy_backups/historical_sharks.txt

You should see the following output:

    Outputcat: /home/sammy/sammy_backups/historical_sharks.txt: No such file or directory

Next, let’s restore this file from our Space. The `--file-to-restore` option allows us to specify the path of the file we would like to restore. This path should be relative to the directory that we have backed up; in our case, our relative path will be `historical_sharks.txt`. We will also reverse the order of our Space URL and backup directory to indicate that we are restoring the file from our repository:

    duplicity --verbosity info --encrypt-sign-key=$GPG_KEY --log-file /home/sammy/.duplicity/info.log --file-to-restore historical_sharks.txt \
    s3://nyc3.digitaloceanspaces.com/sammys-bucket /home/sammy/sammy_backups/historical_sharks.txt

You will see output like the following:

    Output...
    Processing local manifest /home/sammy/.cache/duplicity/d9911d387bb9ee345a171141106ab714/duplicity-full.20180402T170008Z.manifest (195)
    Found 1 volumes in manifest
    Deleting /tmp/duplicity-e66MEL-tempdir/mktemp-_A24DP-6
    Processed volume 1 of 1

Running `cat` again will output the contents of the restored `historical_sharks.txt` file:

    cat ~/sammy_backups/historical_sharks.txt

    OutputThe ancient Megalodon shark reached lengths of up to 59 feet, and is widely regarded as one of history's most fearsome predators.

Now that we have created a manual backup of the `~/sammy_backups` directory and restored data from our repository, we are ready to move on to automating the backup process.

## Automating Backups

Automating the backup process can help ensure that the data in our `~/sammy_backups` directory remains recoverable and up-to-date. We can use the `cron` job scheduler to create a backup schedule that will include a full backup each week and incremental backups otherwise. To learn more about using `cron` to schedule tasks, check out our tutorial on [How To Schedule Routine Tasks With Cron and Anacron on a VPS](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps).

First, let’s create a backup script in our `~/.duplicity` directory:

    nano ~/.duplicity/.backup.sh

Within this file, we will first specify that this script will be run by the Bash shell:

~/.duplicity/.backup.sh

    #!/bin/bash

Next, we will create a `HOME` variable to use with our `source` and `duplicity` commands. Be sure to replace the highlighted username, backup directory, and bucket name with your information:

~/.duplicity/.backup.sh

    ...
    HOME="/home/sammy"
    
    source "$HOME/.duplicity/.env_variables.conf"
    
    duplicity \
        --verbosity info \
        --encrypt-sign-key="$GPG_KEY" \
        --full-if-older-than 7D \
        --log-file "$HOME/.duplicity/info.log" \
        /home/sammy/sammy_backups \
        s3://nyc3.digitaloceanspaces.com/sammys-bucket/

The `source` and `duplicity` commands do the same work here that they did when we created our manual backup: `source` loads our environment variables into the current context, while `duplicity` creates encrypted tar volumes to send to our repository. Our options all remain the same, except for the addition of the `--full-if-older-than` option. Set at `7D`, this option specifies that a full backup will happen each week, once the last full backup is older than seven days.

The final elements in our script will be `unset` commands that will remove our environment variables as a security measure:

~/.duplicity/.backup.sh

    ...
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset GPG_KEY
    unset PASSPHRASE

The complete script will look like this:

~/.duplicity/.backup.sh

    #!/bin/bash
    
    HOME="/home/sammy"
    
    source "$HOME/.duplicity/.env_variables.conf"
    
    duplicity \
        --verbosity info \
        --encrypt-sign-key="$GPG_KEY" \
        --full-if-older-than 7D \
        --log-file "$HOME/.duplicity/info.log" \
        /home/sammy/sammy_backups \
        s3://nyc3.digitaloceanspaces.com/sammys-bucket/
    
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset GPG_KEY
    unset PASSPHRASE

When you are satisfied with the script, you can save and close the file. We’ll also set permissions to ensure that only our current non-sudo user will have the ability to read, write, and execute the file:

    chmod 0700 ~/.duplicity/.backup.sh

Finally, we can automate our backup schedule by editing our user’s `crontab` file. Open this file for editing by typing:

    crontab -e 

Because this is our first time editing this file, we will be asked to choose an editor:

crontab

    no crontab for root - using an empty one
    Select an editor. To change later, run 'select-editor'.
      1. /bin/ed
      2. /bin/nano <---- easiest
      3. /usr/bin/vim.basic
      4. /usr/bin/vim.tiny
    Choose 1-4 [2]: 
    ...

You can select `2` for nano, or enter the number corresponding to the editor of your choice.

At the bottom of the file, we will add a line to specify how often our script should run. To test its functionality, we can set our time interval to two minutes as follows:

crontab

    ...
    
    */2 * * * * /home/sammy/.duplicity/.backup.sh

Save and close the file. After two minutes, you can navigate to your [Spaces page in the DigitalOcean control panel](https://cloud.digitalocean.com/spaces), where you should see incremental backup files. You can now modify the `crontab` file to specify the time interval you would like to use for your incremental backups.

## Conclusion

In this tutorial, we have covered how to back up the contents of a specific directory to a Spaces repository. Using a configuration file to store our repository information, we created a manual backup of our data, which we tested by restoring a sample file, and an automated backup schedule.

For more information on Duplicity, you can check out the [project website](http://duplicity.nongnu.org/index.html) as well as the [`duplicity` man page](http://duplicity.nongnu.org/duplicity.1.html). This documentation covers Duplicity’s many features, and offers guidance on creating full system backups.
