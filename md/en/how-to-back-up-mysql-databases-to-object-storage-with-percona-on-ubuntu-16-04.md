---
author: Justin Ellingwood
date: 2017-10-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-mysql-databases-to-object-storage-with-percona-on-ubuntu-16-04
---

# How To Back Up MySQL Databases to Object Storage with Percona on Ubuntu 16.04

## Introduction

Databases often store some of the most valuable information in your infrastructure. Because of this, it is important to have reliable backups to guard against data loss in the event of an accident or hardware failure.

The [Percona XtraBackup backup tools](https://www.percona.com/software/mysql-database/percona-xtrabackup) provide a method of performing “hot” backups of MySQL data while the system is running. They do this by copying the data files at the filesystem level and then performing a crash recovery to achieve consistency within the dataset.

In [a previous guide](how-to-configure-mysql-backups-with-percona-xtrabackup-on-ubuntu-16-04), we installed Percona’s backup utilities and created a series of scripts to perform rotating local backups. This works well for backing up data to a different drive or network mounted volume to handle problems with your database machine. However, in most cases, data should be backed up off-site where it can be easily maintained and restored. In this guide, we will extend our previous backup system to upload our compressed, encrypted backup files to an object storage service. We will be using [DigitalOcean Spaces](https://www.digitalocean.com/products/object-storage/) as an example in this guide, but the basic procedures are likely applicable for other S3-compatible object storage solutions as well.

### Prerequisites

Before you start this guide, you will need a MySQL database server configured with the local Percona backup solution outlined in our previous guide. The full set of guides you need to follow are:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04): This guide will help you configure a user account with `sudo` privileges and configure a basic firewall.
- One of the following MySQL installation guides:
  - [How To Install MySQL on Ubuntu 16.04](how-to-install-mysql-on-ubuntu-16-04): Uses the default package provided and maintained by the Ubuntu team.
  - [How To Install the Latest MySQL on Ubuntu 16.04](how-to-install-the-latest-mysql-on-ubuntu-16-04): Uses updated packages provided by the MySQL project.
- [How To Configure MySQL Backups with Percona XtraBackup on Ubuntu 16.04](how-to-configure-mysql-backups-with-percona-xtrabackup-on-ubuntu-16-04): This guide sets up a local MySQL backup solution using the Percona XtraBackup tools.

In addition to the above tutorials, you will also need to generate an access key and secret key to interact with your object storage account using the API. If you are using DigitalOcean Spaces, you can find out how to generate these credentials by following our [How to Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key) guide. You will need to save both the API access key and API secret value.

When you are finished with the previous guides, log back into your server as your `sudo` user to get started.

## Install the Dependencies

We will be using some Python and Bash scripts to create our backups and upload them to remote object storage for safekeeping. We will need the `boto3` Python library to interact with the [object storage API](https://developers.digitalocean.com/documentation/spaces/). We can download this with `pip`, Python’s package manager.

Refresh our local package index and then install the Python 3 version of `pip` from Ubuntu’s default repositories using `apt-get` by typing:

    sudo apt-get update
    sudo apt-get install python3-pip

Because Ubuntu maintains its own package life cycle, the version of `pip` in Ubuntu’s repositories is not kept in sync with recent releases. However, we can update to a newer version of `pip` using the tool itself. We will use `sudo` to install globally and include the `-H` flag to set the `$HOME` variable to a value `pip` expects:

    sudo -H pip3 install --upgrade pip

Afterwards, we can install `boto3` along with the `pytz` module, which we will use to compare times accurately using the offset-aware format that the object storage API returns:

    sudo -H pip3 install boto3 pytz

We should now have all of the Python modules we need to interact with the object storage API.

## Create an Object Storage Configuration File

Our backup and download scripts will need to interact with the object storage API in order to upload files and download older backup artifacts when we need to restore. They will need to use the access keys we generated in the prerequisite section. Rather than keeping these values in the scripts themselves, we will place them in a dedicated file that can be read by our scripts. This way, we can share our scripts without fear of exposing our credentials and we can lock down the credentials more heavily than the script itself.

In the [last guide](how-to-configure-mysql-backups-with-percona-xtrabackup-on-ubuntu-16-04), we created the `/backups/mysql` directory to store our backups and our encryption key. We will place the configuration file here alongside our other assets. Create a file called `object_storage_config.sh`:

    sudo nano /backups/mysql/object_storage_config.sh

Inside, paste the following contents, changing the access key and secret key to the values you obtained from your object storage account and the bucket name to a unique value. Set the endpoint URL and region name to the values provided by your object storage service (we will use the values associated with DigitalOcean’s NYC3 region for Spaces here):

/backups/mysql/object\_storage\_config.sh

    #!/bin/bash
    
    export MYACCESSKEY="my_access_key"
    export MYSECRETKEY="my_secret_key"
    export MYBUCKETNAME="your_unique_bucket_name"
    export MYENDPOINTURL="https://nyc3.digitaloceanspaces.com"
    export MYREGIONNAME="nyc3"

These lines define two environment variables called `MYACCESSKEY` and `MYSECRETKEY` to hold our access and secret keys respectively. The `MYBUCKETNAME` variable defines the object storage bucket we want to use to store our backup files. Bucket names must be universally unique, so you must choose a name that no other user has selected. Our script will check the bucket value to see if it is already claimed by another user and automatically create it if it is available. We `export` the variables we define so that any processes we call from within our scripts will have access to these values.

The `MYENDPOINTURL` and `MYREGIONNAME` variables contain the API endpoint and the specific region identifier offered by your object storage provider. For DigitalOcean spaces, the endpoint will be `https://region_name.digitaloceanspaces.com`. You can find the available regions for Spaces in the DigitalOcean Control Panel (at the time of this writing, only “nyc3” is available).

Save and close the file when you are finished.

Anyone who can access our API keys has complete access to our object storage account, so it is important to restrict access to the configuration file to the `backup` user. We can give the `backup` user and group ownership of the file and then revoke all other access by typing:

    sudo chown backup:backup /backups/mysql/object_storage_config.sh
    sudo chmod 600 /backups/mysql/object_storage_config.sh

Our `object_storage_config.sh` file should now only be accessible to the `backup` user.

## Creating the Remote Backup Scripts

Now that we have an object storage configuration file, we can go ahead and begin creating our scripts. We will be creating the following scripts:

- `object_storage.py`: This script is responsible for interacting with the object storage API to create buckets, upload files, download content, and prune older backups. Our other scripts will call this script anytime they need to interact with the remote object storage account.
- `remote-backup-mysql.sh`: This script backs up the MySQL databases by encrypting and compressing the files into a single artifact and then uploading it to the remote object store. It creates a full backup at the beginning of each day and then an incremental backup every hour afterwards. It automatically prunes all files from the remote bucket that are older than 30 days.
- `download-day.sh`: This script allows us to download all of the backups associated with a given day. Because our backup script creates a full backup each morning and then incremental backups throughout the day, this script can download all of the assets necessary to restore to any hourly checkpoint.

Along with the new scripts above, we will leverage the `extract-mysql.sh` and `prepare-mysql.sh` scripts from the previous guide to help restore our files. You can view the scripts in the [repository for this tutorial on GitHub](https://github.com/do-community/ubuntu-1604-mysql-backup) at any time. If you do not want to copy and paste the contents below, you can download the new files directly from GitHub by typing:

    cd /tmp
    curl -LO https://raw.githubusercontent.com/do-community/ubuntu-1604-mysql-backup/master/object_storage.py
    curl -LO https://raw.githubusercontent.com/do-community/ubuntu-1604-mysql-backup/master/remote-backup-mysql.sh
    curl -LO https://raw.githubusercontent.com/do-community/ubuntu-1604-mysql-backup/master/download-day.sh

Be sure to inspect the scripts after downloading to make sure they were retrieved successfully and that you approve of the actions they will perform. If you are satisfied, mark the scripts as executable and then move them into the `/usr/local/bin` directory by typing:

    chmod +x /tmp/{remote-backup-mysql.sh,download-day.sh,object_storage.py}
    sudo mv /tmp/{remote-backup-mysql.sh,download-day.sh,object_storage.py} /usr/local/bin

Next, we will set up each of these scripts and discuss them in more detail.

### Create the object\_storage.py Script

If you didn’t download the `object_storage.py` script from GitHub, create a new file in the `/usr/local/bin` directory called `object_storage.py`:

    sudo nano /usr/local/bin/object_storage.py

Copy and paste the script contents into the file:

/usr/local/bin/object\_storage.py

    #!/usr/bin/env python3
    
    import argparse
    import os
    import sys
    from datetime import datetime, timedelta
    
    import boto3
    import pytz
    from botocore.client import ClientError, Config
    from dateutil.parser import parse
    
    # "backup_bucket" must be a universally unique name, so choose something
    # specific to your setup.
    # The bucket will be created in your account if it does not already exist
    backup_bucket = os.environ['MYBUCKETNAME']
    access_key = os.environ['MYACCESSKEY']
    secret_key = os.environ['MYSECRETKEY']
    endpoint_url = os.environ['MYENDPOINTURL']
    region_name = os.environ['MYREGIONNAME']
    
    
    class Space():
        def __init__ (self, bucket):
            self.session = boto3.session.Session()
            self.client = self.session.client('s3',
                                              region_name=region_name,
                                              endpoint_url=endpoint_url,
                                              aws_access_key_id=access_key,
                                              aws_secret_access_key=secret_key,
                                              config=Config(signature_version='s3')
                                              )
            self.bucket = bucket
            self.paginator = self.client.get_paginator('list_objects')
    
        def create_bucket(self):
            try:
                self.client.head_bucket(Bucket=self.bucket)
            except ClientError as e:
                if e.response['Error']['Code'] == '404':
                    self.client.create_bucket(Bucket=self.bucket)
                elif e.response['Error']['Code'] == '403':
                    print("The bucket name \"{}\" is already being used by "
                          "someone. Please try using a different bucket "
                          "name.".format(self.bucket))
                    sys.exit(1)
                else:
                    print("Unexpected error: {}".format(e))
                    sys.exit(1)
    
        def upload_files(self, files):
            for filename in files:
                self.client.upload_file(Filename=filename, Bucket=self.bucket,
                                        Key=os.path.basename(filename))
                print("Uploaded {} to \"{}\"".format(filename, self.bucket))
    
        def remove_file(self, filename):
            self.client.delete_object(Bucket=self.bucket,
                                      Key=os.path.basename(filename))
    
        def prune_backups(self, days_to_keep):
            oldest_day = datetime.now(pytz.utc) - timedelta(days=int(days_to_keep))
            try:
                # Create an iterator to page through results
                page_iterator = self.paginator.paginate(Bucket=self.bucket)
                # Collect objects older than the specified date
                objects_to_prune = [filename['Key'] for page in page_iterator
                                    for filename in page['Contents']
                                    if filename['LastModified'] < oldest_day]
            except KeyError:
                # If the bucket is empty
                sys.exit()
            for object in objects_to_prune:
                print("Removing \"{}\" from {}".format(object, self.bucket))
                self.remove_file(object)
    
        def download_file(self, filename):
            self.client.download_file(Bucket=self.bucket,
                                      Key=filename, Filename=filename)
    
        def get_day(self, day_to_get):
            try:
                # Attempt to parse the date format the user provided
                input_date = parse(day_to_get)
            except ValueError:
                print("Cannot parse the provided date: {}".format(day_to_get))
                sys.exit(1)
            day_string = input_date.strftime("-%m-%d-%Y_")
            print_date = input_date.strftime("%A, %b. %d %Y")
            print("Looking for objects from {}".format(print_date))
            try:
                # create an iterator to page through results
                page_iterator = self.paginator.paginate(Bucket=self.bucket)
                objects_to_grab = [filename['Key'] for page in page_iterator
                                   for filename in page['Contents']
                                   if day_string in filename['Key']]
            except KeyError:
                print("No objects currently in bucket")
                sys.exit()
            if objects_to_grab:
                for object in objects_to_grab:
                    print("Downloading \"{}\" from {}".format(object, self.bucket))
                    self.download_file(object)
            else:
                print("No objects found from: {}".format(print_date))
                sys.exit()
    
    
    def is_valid_file(filename):
        if os.path.isfile(filename):
            return filename
        else:
            raise argparse.ArgumentTypeError("File \"{}\" does not exist."
                                             .format(filename))
    
    
    def parse_arguments():
        parser = argparse.ArgumentParser(
            description='''Client to perform backup-related tasks with
                         object storage.''')
        subparsers = parser.add_subparsers()
    
        # parse arguments for the "upload" command
        parser_upload = subparsers.add_parser('upload')
        parser_upload.add_argument('files', type=is_valid_file, nargs='+')
        parser_upload.set_defaults(func=upload)
    
        # parse arguments for the "prune" command
        parser_prune = subparsers.add_parser('prune')
        parser_prune.add_argument('--days-to-keep', default=30)
        parser_prune.set_defaults(func=prune)
    
        # parse arguments for the "download" command
        parser_download = subparsers.add_parser('download')
        parser_download.add_argument('filename')
        parser_download.set_defaults(func=download)
    
        # parse arguments for the "get_day" command
        parser_get_day = subparsers.add_parser('get_day')
        parser_get_day.add_argument('day')
        parser_get_day.set_defaults(func=get_day)
    
        return parser.parse_args()
    
    
    def upload(space, args):
        space.upload_files(args.files)
    
    
    def prune(space, args):
        space.prune_backups(args.days_to_keep)
    
    
    def download(space, args):
        space.download_file(args.filename)
    
    
    def get_day(space, args):
        space.get_day(args.day)
    
    
    def main():
        args = parse_arguments()
        space = Space(bucket=backup_bucket)
        space.create_bucket()
        args.func(space, args)
    
    
    if __name__ == ' __main__':
        main()

This script is responsible for managing the backups within your object storage account. It can upload files, remove files, prune old backups, and download files from object storage. Rather than interacting with the object storage API directly, our other scripts will use the functionality defined here to interact with remote resources. The commands it defines are:

- `upload`: Uploads to object storage each of the files that are passed in as arguments. Multiple files may be specified.
- `download`: Downloads a single file from remote object storage, which is passed in as an argument.
- `prune`: Removes every file older than a certain age from the object storage location. By default this removes files older than 30 days. You can adjust this by specifying the `--days-to-keep` option when calling `prune`.
- `get_day`: Pass in the day to download as an argument using a standard date format (using quotations if the date has whitespace in it) and the tool will attempt to parse it and download all of the files from that date.

The script attempts to read the object storage credentials and bucket name from environment variables, so we will need to make sure those are populated from the `object_storage_config.sh` file before calling the `object_storage.py` script.

When you are finished, save and close the file.

Next, if you haven’t already done so, make the script executable by typing:

    sudo chmod +x /usr/local/bin/object_storage.py

Now that the `object_storage.py` script is available to interact with the API, we can create the Bash scripts that use it to back up and download files.

### Create the remote-backup-mysql.sh Script

Next, we will create the `remote-backup-mysql.sh` script. This will perform many of the same functions as the original `backup-mysql.sh` local backup script, with a more basic organization structure (since maintaining backups on the local filesystem is not necessary) and some additional steps to upload to object storage.

If you did not download the script from the repository, create and open a file called `remote-backup-mysql.sh` in the `/usr/local/bin` directory:

    sudo nano /usr/local/bin/remote-backup-mysql.sh

Inside, paste the following script:

/usr/local/bin/remote-backup-mysql.sh

    #!/bin/bash
    
    export LC_ALL=C
    
    days_to_keep=30
    backup_owner="backup"
    parent_dir="/backups/mysql"
    defaults_file="/etc/mysql/backup.cnf"
    working_dir="${parent_dir}/working"
    log_file="${working_dir}/backup-progress.log"
    encryption_key_file="${parent_dir}/encryption_key"
    storage_configuration_file="${parent_dir}/object_storage_config.sh"
    now="$(date)"
    now_string="$(date -d"${now}" +%m-%d-%Y_%H-%M-%S)"
    processors="$(nproc --all)"
    
    # Use this to echo to standard error
    error () {
        printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}" >&2
        exit 1
    }
    
    trap 'error "An unexpected error occurred."' ERR
    
    sanity_check () {
        # Check user running the script
        if ["$(id --user --name)" != "$backup_owner"]; then
            error "Script can only be run as the \"$backup_owner\" user"
        fi
    
        # Check whether the encryption key file is available
        if [! -r "${encryption_key_file}"]; then
            error "Cannot read encryption key at ${encryption_key_file}"
        fi
    
        # Check whether the object storage configuration file is available
        if [! -r "${storage_configuration_file}"]; then
            error "Cannot read object storage configuration from ${storage_configuration_file}"
        fi
    
        # Check whether the object storage configuration is set in the file
        source "${storage_configuration_file}"
        if [-z "${MYACCESSKEY}"] || [-z "${MYSECRETKEY}"] || [-z "${MYBUCKETNAME}"]; then
            error "Object storage configuration are not set properly in ${storage_configuration_file}"
        fi
    }
    
    set_backup_type () {
        backup_type="full"
    
    
        # Grab date of the last backup if available
        if [-r "${working_dir}/xtrabackup_info"]; then
            last_backup_date="$(date -d"$(grep start_time "${working_dir}/xtrabackup_info" | cut -d' ' -f3)" +%s)"
        else
                last_backup_date=0
        fi
    
        # Grab today's date, in the same format
        todays_date="$(date -d "$(date -d "${now}" "+%D")" +%s)"
    
        # Compare the two dates
        (( $last_backup_date == $todays_date ))
        same_day="${?}"
    
        # The first backup each new day will be a full backup
        # If today's date is the same as the last backup, take an incremental backup instead
        if ["$same_day" -eq "0"]; then
            backup_type="incremental"
        fi
    }
    
    set_options () {
        # List the xtrabackup arguments
        xtrabackup_args=(
            "--defaults-file=${defaults_file}"
            "--backup"
            "--extra-lsndir=${working_dir}"
            "--compress"
            "--stream=xbstream"
            "--encrypt=AES256"
            "--encrypt-key-file=${encryption_key_file}"
            "--parallel=${processors}"
            "--compress-threads=${processors}"
            "--encrypt-threads=${processors}"
            "--slave-info"
        )
    
        set_backup_type
    
        # Add option to read LSN (log sequence number) if taking an incremental backup
        if ["$backup_type" == "incremental"]; then
            lsn=$(awk '/to_lsn/ {print $3;}' "${working_dir}/xtrabackup_checkpoints")
            xtrabackup_args+=( "--incremental-lsn=${lsn}" )
        fi
    }
    
    rotate_old () {
        # Remove previous backup artifacts
        find "${working_dir}" -name "*.xbstream" -type f -delete
    
        # Remove any backups from object storage older than 30 days
        /usr/local/bin/object_storage.py prune --days-to-keep "${days_to_keep}"
    }
    
    take_backup () {
        find "${working_dir}" -type f -name "*.incomplete" -delete
        xtrabackup "${xtrabackup_args[@]}" --target-dir="${working_dir}" > "${working_dir}/${backup_type}-${now_string}.xbstream.incomplete" 2> "${log_file}"
    
        mv "${working_dir}/${backup_type}-${now_string}.xbstream.incomplete" "${working_dir}/${backup_type}-${now_string}.xbstream"
    }
    
    upload_backup () {
        /usr/local/bin/object_storage.py upload "${working_dir}/${backup_type}-${now_string}.xbstream"
    }
    
    main () {
        mkdir -p "${working_dir}"
        sanity_check && set_options && rotate_old && take_backup && upload_backup
    
        # Check success and print message
        if tail -1 "${log_file}" | grep -q "completed OK"; then
            printf "Backup successful!\n"
            printf "Backup created at %s/%s-%s.xbstream\n" "${working_dir}" "${backup_type}" "${now_string}"
        else
            error "Backup failure! If available, check ${log_file} for more information"
        fi
    }
    
    main

This script handles the actual MySQL backup procedure, controls the backup schedule, and automatically removes older backups from remote storage. You can choose how many days of backups you’d like to keep on-hand by adjusting the `days_to_keep` variable.

The local `backup-mysql.sh` script we used in the last article maintained separate directories for each day’s backups. Since we are storing backups remotely, we will only store the latest backup locally in order to minimize the disk space devoted to backups. Previous backups can be downloaded from object storage as needed for restoration.

As with the previous script, after checking that a few basic requirements are satisfied and configuring the type of backup that should be taken, we encrypt and compress each backup into a single file archive. The previous backup file is removed from the local filesystem and any remote backups that are older than the value defined in `days_to_keep` are removed.

Save and close the file when you are finished. Afterwards, ensure that the script is executable by typing:

    sudo chmod +x /usr/local/bin/remote-backup-mysql.sh

This script can be used as a replacement for the `backup-mysql.sh` script on this system to switch from making local backups to remote backups.

### Create the download-day.sh Script

Finally, download or create the `download-day.sh` script within the `/usr/local/bin` directory. This script can be used to download all of the backups associated with a particular day.

Create the script file in your text editor if you did not download it earlier:

    sudo nano /usr/local/bin/download-day.sh

Inside, paste the following contents:

/usr/local/bin/download-day.sh

    #!/bin/bash
    
    export LC_ALL=C
    
    backup_owner="backup"
    storage_configuration_file="/backups/mysql/object_storage_config.sh"
    day_to_download="${1}"
    
    # Use this to echo to standard error
    error () {
        printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}" >&2
        exit 1
    }
    
    trap 'error "An unexpected error occurred."' ERR
    
    sanity_check () {
        # Check user running the script
        if ["$(id --user --name)" != "$backup_owner"]; then
            error "Script can only be run as the \"$backup_owner\" user"
        fi
    
        # Check whether the object storage configuration file is available
        if [! -r "${storage_configuration_file}"]; then
            error "Cannot read object storage configuration from ${storage_configuration_file}"
        fi
    
        # Check whether the object storage configuration is set in the file
        source "${storage_configuration_file}"
        if [-z "${MYACCESSKEY}"] || [-z "${MYSECRETKEY}"] || [-z "${MYBUCKETNAME}"]; then
            error "Object storage configuration are not set properly in ${storage_configuration_file}"
        fi
    }
    
    main () {
        sanity_check
        /usr/local/bin/object_storage.py get_day "${day_to_download}"
    }
    
    main

This script can be called to download all of the archives from a specific day. Since each day starts with a full backup and accumulates incremental backups throughout the rest of the day, this will download all of the relevant files necessary to restore to any hourly snapshot.

The script takes a single argument which is a date or day. It uses the [Python’s `dateutil.parser.parse` function](https://dateutil.readthedocs.io/en/stable/parser.html#dateutil.parser.parse) to read and interpret a date string provided as an argument. The function is fairly flexible and can interpret dates in a variety of formats, including relative strings like “Friday”, for example. To avoid ambiguity however, it is best to use more well-defined dates. Be sure to wrap dates in quotations if the format you wish to use contains whitespace.

When you are ready to continue, save and close the file. Make the script executable by typing:

    sudo chmod +x /usr/local/bin/download-day.sh

We now have the ability to download the backup files from object storage for a specific date when we want to restore.

## Testing the Remote MySQL Backup and Download Scripts

Now that we have our scripts in place, we should test to make sure they function as expected.

### Perform a Full Backup

Begin by calling the `remote-mysql-backup.sh` script with the `backup` user. Since this is the first time we are running this command, it should create a full backup of our MySQL database.

    sudo -u backup remote-backup-mysql.sh

**Note:** If you receive an error indicating that the bucket name you selected is already in use, you will have to select a different name. Change the value of `MYBUCKETNAME` in the `/backups/mysql/object_storage_config.sh` file and delete the local backup directory (`sudo rm -rf /backups/mysql/working`) so that the script can attempt a full backup with the new bucket name. When you are ready, rerun the command above to try again.

If everything goes well, you will see output similar to the following:

    OutputUploaded /backups/mysql/working/full-10-17-2017_19-09-30.xbstream to "your_bucket_name"
    Backup successful!
    Backup created at /backups/mysql/working/full-10-17-2017_19-09-30.xbstream

This indicates that a full backup has been created within the `/backups/mysql/working` directory. It has also been uploaded to remote object storage using the bucket defined in the `object_storage_config.sh` file.

If we look within the `/backups/mysql/working` directory, we can see files similar to those produced by the `backup-mysql.sh` script from the last guide:

    ls /backups/mysql/working

    Outputbackup-progress.log full-10-17-2017_19-09-30.xbstream xtrabackup_checkpoints xtrabackup_info

The `backup-progress.log` file contains the output from the `xtrabackup` command, while `xtrabackup_checkpoints` and `xtrabackup_info` contain information about options used, the type and scope of the backup, and other metadata.

### Perform an Incremental Backup

Let’s make a small change to our `equipment` table in order to create additional data not found in our first backup. We can enter a new row in the table by typing:

    mysql -u root -p -e 'INSERT INTO playground.equipment (type, quant, color) VALUES ("sandbox", 4, "brown");'

Enter your database’s administrative password to add the new record.

Now, we can take an additional backup. When we call the script again, an incremental backup should be created as long as it is still the same day as the previous backup (according to the server’s clock):

    sudo -u backup remote-backup-mysql.sh

    OutputUploaded /backups/mysql/working/incremental-10-17-2017_19-19-20.xbstream to "your_bucket_name"
    Backup successful!
    Backup created at /backups/mysql/working/incremental-10-17-2017_19-19-20.xbstream

The above output indicates that the backup was created within the same directory locally, and was again uploaded to object storage. If we check the `/backups/mysql/working` directory, we will find that the new backup is present and that the previous backup has been removed:

    ls /backups/mysql/working

    Outputbackup-progress.log incremental-10-17-2017_19-19-20.xbstream xtrabackup_checkpoints xtrabackup_info

Since our files are uploaded remotely, deleting the local copy helps reduce the amount of disk space used.

### Download the Backups from a Specified Day

Since our backups are stored remotely, we will need to pull down the remote files if we need to restore our files. To do this, we can use the `download-day.sh` script.

Begin by creating and then moving into a directory that the `backup` user can safely write to:

    sudo -u backup mkdir /tmp/backup_archives
    cd /tmp/backup_archives

Next, call the `download-day.sh` script as the `backup` user. Pass in the day of the archives you’d like to download. The date format is fairly flexible, but it is best to try to be unambiguous:

    sudo -u backup download-day.sh "Oct. 17"

If there are archives that match the date you provided, they will be downloaded to the current directory:

    OutputLooking for objects from Tuesday, Oct. 17 2017
    Downloading "full-10-17-2017_19-09-30.xbstream" from your_bucket_name
    Downloading "incremental-10-17-2017_19-19-20.xbstream" from your_bucket_name

Verify that the files have been downloaded to the local filesystem:

    ls

    Outputfull-10-17-2017_19-09-30.xbstream incremental-10-17-2017_19-19-20.xbstream

The compressed, encrypted archives are now back on the server again.

### Extract and Prepare the Backups

Once the files are collected, we can process them the same way we processed local backups.

First, pass the `.xbstream` files to the `extract-mysql.sh` script using the `backup` user:

    sudo -u backup extract-mysql.sh *.xbstream

This will decrypt and decompress the archives into a directory called `restore`. Enter that directory and prepare the files with the `prepare-mysql.sh` script:

    cd restore
    sudo -u backup prepare-mysql.sh

    OutputBackup looks to be fully prepared. Please check the "prepare-progress.log" file
    to verify before continuing.
    
    If everything looks correct, you can apply the restored files.
    
    First, stop MySQL and move or remove the contents of the MySQL data directory:
    
            sudo systemctl stop mysql
            sudo mv /var/lib/mysql/ /tmp/
    
    Then, recreate the data directory and copy the backup files:
    
            sudo mkdir /var/lib/mysql
            sudo xtrabackup --copy-back --target-dir=/tmp/backup_archives/restore/full-10-17-2017_19-09-30
    
    Afterward the files are copied, adjust the permissions and restart the service:
    
            sudo chown -R mysql:mysql /var/lib/mysql
            sudo find /var/lib/mysql -type d -exec chmod 750 {} \;
            sudo systemctl start mysql

The full backup in the `/tmp/backup_archives/restore` directory should now be prepared. We can follow the instructions in the output to restore the MySQL data on our system.

### Restore the Backup Data to the MySQL Data Directory

Before we restore the backup data, we need to move the current data out of the way.

Start by shutting down MySQL to avoid corrupting the database or crashing the service when we replace its data files.

    sudo systemctl stop mysql

Next, we can move the current data directory to the `/tmp` directory. This way, we can easily move it back if the restore has problems. Since we moved the files to `/tmp/mysql` in the last article, we can move the files to `/tmp/mysql-remote` this time:

    sudo mv /var/lib/mysql/ /tmp/mysql-remote

Next, recreate an empty `/var/lib/mysql` directory:

    sudo mkdir /var/lib/mysql

Now, we can type the `xtrabackup` restore command that the `prepare-mysql.sh` command provided to copy the backup files into the `/var/lib/mysql` directory:

    sudo xtrabackup --copy-back --target-dir=/tmp/backup_archives/restore/full-10-17-2017_19-09-30

Once the process completes, modify the directory permissions and ownership to ensure that the MySQL process has access:

    sudo chown -R mysql:mysql /var/lib/mysql
    sudo find /var/lib/mysql -type d -exec chmod 750 {} \;

When this finishes, start MySQL again and check that our data has been properly restored:

    sudo systemctl start mysql
    mysql -u root -p -e 'SELECT * FROM playground.equipment;'

    Output+----+---------+-------+--------+
    | id | type | quant | color |
    +----+---------+-------+--------+
    | 1 | slide | 2 | blue |
    | 2 | swing | 10 | yellow |
    | 3 | sandbox | 4 | brown |
    +----+---------+-------+--------+

The data is available, which indicates that it has been successfully restored.

After restoring your data, it is important to go back and delete the restore directory. Future incremental backups cannot be applied to the full backup once it has been prepared, so we should remove it. Furthermore, the backup directories should not be left unencrypted on disk for security reasons:

    cd ~
    sudo rm -rf /tmp/backup_archives/restore

The next time we need clean copies of the backup directories, we can extract them again from the backup archive files.

## Creating a Cron Job to Run Backups Hourly

We created a `cron` job to automatically backup up our database locally in the last guide. We will set up a new `cron` job to take remote backups and then disable the local backup job. We can easily switch between local and remote backups as necessary by enabling or disabling the `cron` scripts.

To start, create a file called `remote-backup-mysql` in the `/etc/cron.hourly` directory:

    sudo nano /etc/cron.hourly/remote-backup-mysql

Inside, we will call our `remote-backup-mysql.sh` script with the `backup` user through the `systemd-cat` command, which allows us to log the output to `journald`:

/etc/cron.hourly/remote-backup-mysql

    #!/bin/bash 
    sudo -u backup systemd-cat --identifier=remote-backup-mysql /usr/local/bin/remote-backup-mysql.sh

Save and close the file when you are finished.

We will enable our new `cron` job and disable the old one by manipulating the `executable` permission bit on both files:

    sudo chmod -x /etc/cron.hourly/backup-mysql
    sudo chmod +x /etc/cron.hourly/remote-backup-mysql

Test the new remote backup job by executing the script manually:

    sudo /etc/cron.hourly/remote-backup-mysql

Once the prompt returns, we can check the log entries with `journalctl`:

    sudo journalctl -t remote-backup-mysql

    [seconary_label Output]
    -- Logs begin at Tue 2017-10-17 14:28:01 UTC, end at Tue 2017-10-17 20:11:03 UTC. --
    Oct 17 20:07:17 myserver remote-backup-mysql[31422]: Uploaded /backups/mysql/working/incremental-10-17-2017_22-16-09.xbstream to "your_bucket_name"
    Oct 17 20:07:17 myserver remote-backup-mysql[31422]: Backup successful!
    Oct 17 20:07:17 myserver remote-backup-mysql[31422]: Backup created at /backups/mysql/working/incremental-10-17-2017_20-07-13.xbstream

Check back in a few hours to make sure that additional backups are being taken on schedule.

## Backing Up the Extraction Key

One final consideration that you will have to handle is how to back up the encryption key (found at `/backups/mysql/encryption_key`).

The encryption key is required to restore any of the files backed up using this process, but storing the encryption key in the same location as the database files eliminates the protection provided by encryption. Because of this, it is important to keep a copy of the encryption key in a separate location so that you can still use the backup archives if your database server fails or needs to be rebuilt.

While a complete backup solution for non-database files is outside the scope of this article, you can copy the key to your local computer for safekeeping. To do so, view the contents of the file by typing:

    sudo less /backups/mysql/encryption_key

Open a text file on your local computer and paste the value inside. If you ever need to restore backups onto a different server, copy the contents of the file to `/backups/mysql/encryption_key` on the new machine, set up the system outlined in this guide, and then restore using the provided scripts.

## Conclusion

In this guide, we’ve covered how take hourly backups of a MySQL database and upload them automatically to a remote object storage space. The system will take a full backup every morning and then hourly incremental backups afterwards to provide the ability to restore to any hourly checkpoint. Each time the backup script runs, it checks for backups in object storage that are older than 30 days and removes them.
