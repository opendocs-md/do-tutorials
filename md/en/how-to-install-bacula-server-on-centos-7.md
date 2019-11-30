---
author: Mitchell Anicas
date: 2015-04-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-bacula-server-on-centos-7
---

# How To Install Bacula Server on CentOS 7

## Introduction

Bacula is an open source network backup solution that allows you create backups and perform data recovery of your computer systems. It is very flexible and robust, which makes it, while slightly cumbersome to configure, suitable for backups in many situations. A backup system is an [important component in most server infrastructures](5-ways-to-improve-your-production-web-application-server-setup), as recovering from data loss is often a critical part of disaster recovery plans.

In this tutorial, we will show you how to install and configure the server components of Bacula on a CentOS 7 server. We will configure Bacula to perform a weekly job that creates a local backup (i.e. a backup of its own host). This, by itself, is not a particularly compelling use of Bacula, but it will provide you with a good starting point for creating backups of your other servers, i.e. the backup clients. The next tutorial in this series will cover creating backups of your other, remote, servers by installing and configuring the Bacula client, and configuring the Bacula server.

If you’d rather use Ubuntu 14.04 instead, follow this link: [How To Install Bacula Server on Ubuntu 14.04](how-to-install-bacula-server-on-ubuntu-14-04).

## Prerequisites

You must have superuser (sudo) access on a CentOS 7 server. Also, the server will require adequate disk space for all of the backups that you plan on retaining at any given time.

If you are using DigitalOcean, you should enable **Private Networking** on your Bacula server, and all of your client servers that are in the same datacenter region. This will allow your servers to use private networking when performing backups, reducing network overhead.

We will configure Bacula to use the private FQDN of our servers, e.g. `bacula.private.example.com`. If you don’t have a DNS setup, use the appropriate IP addresses instead. If you don’t have private networking enabled, replace all network connection information in this tutorial with network addresses that are reachable by servers in question (e.g. public IP addresses or VPN tunnels).

The last assumption is that SELinux is disabled or you are able to troubleshoot SELinux-related issues on your own.

Let’s get started by looking at an overview of Bacula’s components.

## Bacula Component Overview

Although Bacula is composed of several software components, it follows the server-client backup model; to simplify the discussion, we will focus more on the **backup server** and the **backup clients** than the individual Bacula components. Still, it is important to have cursory knowledge of the various Bacula components, so we will go over them now.

A Bacula **server** , which we will also refer to as the “backup server”, has these components:

- **Bacula Director (DIR):** Software that controls the backup and restore operations that are performed by the File and Storage daemons
- **Storage Daemon (SD):** Software that performs reads and writes on the storage devices used for backups
- **Catalog:** Services that maintain a database of files that are backed up. The database is stored in an SQL database such as MySQL or PostgreSQL
- **Bacula Console:** A command-line interface that allows the backup administrator to interact with, and control, Bacula Director

    Note: The Bacula server components don't need to run on the same server, but they all work together to provide the backup server functionality.

A Bacula **client** , i.e. a server that will be backed up, runs the **File Daemon (FD)** component. The File Daemon is software that provides the Bacula server (the Director, specifically) access to the data that will be backed up. We will also refer to these servers as “backup clients” or “clients”.

As we noted in the introduction, we will configure the backup server to create a backup of its own filesystem. This means that the backup server will also be a backup client, and will run the File Daemon component.

Let’s get started with the installation.

## Install Bacula and MySQL

Bacula uses an SQL database, such as MySQL or PostreSQL, to manage its backups catalog. We will use MariaDB, a drop-in replacement for MySQL, in this tutorial.

Install the Bacula and MariaDB Server packages with yum:

    sudo yum install -y bacula-director bacula-storage bacula-console bacula-client mariadb-server

When the installation is complete, we need to start MySQL with the following command:

    sudo systemctl start mariadb

Now that MySQL (MariaDB) is installed and running, let’s create the Bacula database user and tables, with these scripts:

    /usr/libexec/bacula/grant_mysql_privileges
    /usr/libexec/bacula/create_mysql_database -u root
    /usr/libexec/bacula/make_mysql_tables -u bacula

Next, we want to run a simple security script that will remove some dangerous defaults and lock down access to our database system a little bit. Start the interactive script by running:

    sudo mysql_secure_installation

The prompt will ask you for your current root password. Since you just installed MySQL, you most likely won’t have one, so leave it blank by pressing enter. Then the prompt will ask you if you want to set a root password. Go ahead and hit `Enter`, and set the password. For the rest of the questions, you should simply hit the `Enter` key through each prompt to accept the default values. This will remove some sample users and databases, disable remote root logins, and load these new rules so that MySQL immediately respects the changes we have made.

Now we need to set the password for the Bacula database user.

Enter the MySQL console, as the root MySQL user:

    mysql -u root -p

Enter the MySQL root password, that you just set, at the prompt.

Now set the password for the Bacula database user. Use this command, but replace the highlighted “bacula_db_password” with strong password:

    UPDATE mysql.user SET Password=PASSWORD('bacula_db_password') WHERE User='bacula';
    FLUSH PRIVILEGES;

Once you’re done here, exit the MySQL prompt:

    exit

Enable MariaDB to start on boot. Use the following command to do so:

    sudo systemctl enable mariadb

### Set Bacula to Use MySQL Library

By default, Bacula is set to use the PostgreSQL library. Because we are using MySQL, we need to set it to use the MySQL library instead.

Run this command:

    sudo alternatives --config libbaccats.so

You will see the following prompt. Enter 1 (MySQL):

    OutputThere are 3 programs which provide 'libbaccats.so'.
    
      Selection Command
    -----------------------------------------------
       1 /usr/lib64/libbaccats-mysql.so
       2 /usr/lib64/libbaccats-sqlite3.so
    *+ 3 /usr/lib64/libbaccats-postgresql.so
    
    Enter to keep the current selection[+], or type selection number: 1

The Bacula server (and client) components are now installed. Let’s create the backup and restore directories.

## Create Backup and Restore Directories

Bacula needs a **backup** directory—for storing backup archives—and **restore** directory—where restored files will be placed. If your system has multiple partitions, make sure to create the directories on one that has sufficient space.

Let’s create new directories for both of these purposes:

    sudo mkdir -p /bacula/backup /bacula/restore

We need to change the file permissions so that only the bacula process (and a superuser) can access these locations:

    sudo chown -R bacula:bacula /bacula
    sudo chmod -R 700 /bacula

Now we’re ready to configure the Bacula Director.

## Configure Bacula Director

Bacula has several components that must be configured independently in order to function correctly. The configuration files can all be found in the `/etc/bacula` directory.

We’ll start with the Bacula Director.

Open the Bacula Director configuration file in your favorite text editor. We’ll use vi:

    sudo vi /etc/bacula/bacula-dir.conf

### Configure Director Resource

Find the Director resource, and configure it to listen on `127.0.0.1` (localhost), by adding the `DirAddress` line shown here:

bacula-dir.conf — Add Director DirAddress

    Director { # define myself
      Name = bacula-dir
      DIRport = 9101 # where we listen for UA connections
      QueryFile = "/etc/bacula/query.sql"
      WorkingDirectory = "/var/spool/bacula"
      PidDirectory = "/var/run"
      Maximum Concurrent Jobs = 1
      Password = "@@DIR_PASSWORD@@" # Console password
      Messages = Daemon
      DirAddress = 127.0.0.1
    }

Now move on to the rest of the file.

### Configure Local Jobs

A Bacula job is used to perform backup and restore actions. Job resources define the details of what a particular job will do, including the name of the Client, the FileSet to back up or restore, among other things.

Here, we will configure the jobs that will be used to perform backups of the local filesystem.

In the Director configuration, find the **Job** resource with a name of “BackupClient1” (search for “BackupClient1”). Change the value of `Name` to “BackupLocalFiles”, so it looks like this:

bacula-dir.conf — Rename BackupClient1 job

    Job {
      Name = "BackupLocalFiles"
      JobDefs = "DefaultJob"
    }

Next, find the **Job** resource that is named “RestoreFiles” (search for “RestoreFiles”). In this job, you want to change two things: update the value of `Name` to “RestoreLocalFiles”, and the value of `Where` to “/bacula/restore”. It should look like this:

bacula-dir.conf — Rename RestoreFiles job

    Job {
      Name = "RestoreLocalFiles"
      Type = Restore
      Client=BackupServer-fd
      FileSet="Full Set"
      Storage = File
      Pool = Default
      Messages = Standard
      Where = /bacula/restore
    }

This configures the RestoreLocalFiles job to restore files to `/bacula/restore`, the directory we created earlier.

### Configure File Set

A Bacula FileSet defines a set of files or directories to **include** or **exclude** files from a backup selection, and are used by jobs.

Find the FileSet resource named “Full Set” (it’s under a comment that says, “# List of files to be backed up”). Here we will make three changes: (1) Add the option to use gzip to compress our backups, (2) change the include File from `/usr/sbin` to `/`, and (3) add `File = /bacula` under the Exclude section. With the comments removed, it should look like this:

bacula-dir.conf — Update “Full Set” FileSet

    FileSet {
      Name = "Full Set"
      Include {
        Options {
          signature = MD5
          compression = GZIP
        }    
    File = /
    }
      Exclude {
        File = /var/lib/bacula
        File = /proc
        File = /tmp
        File = /.journal
        File = /.fsck
        File = /bacula
      }
    }

Let’s go over the changes that we made to the “Full Set” FileSet. First, we enabled gzip compression when creating a backup archive. Second, we are including `/`, i.e. the root partition, to be backed up. Third, we are excluding `/bacula` because we don’t want to redundantly back up our Bacula backups and restored files.

    Note: If you have partitions that are mounted within /, and you want to include those in the FileSet, you will need to include additional File records for each of them.

Keep in mind that if you always use broad FileSets, like “Full Set”, in your backup jobs, your backups will require more disk space than if your backup selections are more specific. For example, a FileSet that only includes your customized configuration files and databases might be sufficient for your needs, if you have a clear recovery plan that details installing required software packages and placing the restored files in the proper locations, while only using a fraction of the disk space for backup archives.

### Configure Storage Daemon Connection

In the Bacula Director configuration file, the Storage resource defines the Storage Daemon that the Director should connect to. We’ll configure the actual Storage Daemon in just a moment.

Find the Storage resource, and replace the value of Address, `localhost`, with the private FQDN (or private IP address) of your backup server. It should look like this (substitute the highlighted word):

bacula-dir.conf — Update Storage Address

    Storage {
      Name = File
    # Do not use "localhost" here
      Address = backup_server_private_FQDN # N.B. Use a fully qualified name here
      SDPort = 9103
      Password = "@@SD_PASSWORD@@"
      Device = FileStorage
      Media Type = File
    }

This is necessary because we are going to configure the Storage Daemon to listen on the private network interface, so remote clients can connect to it.

### Configure Catalog Connection

In the Bacula Director configuration file, the Catalog resource defines where the Database that the Director should use and connect to.

Find the Catalog resource named “MyCatalog” (it’s under a comment that says “Generic catalog service”), and update the value of `dbpassword` so it matches the password you set for the _bacula_ MySQL user:

bacula-dir.conf — Update Catalog dbpassword

    # Generic catalog service
    Catalog {
      Name = MyCatalog
    # Uncomment the following line if you want the dbi driver
    # dbdriver = "dbi:postgresql"; dbaddress = 127.0.0.1; dbport =
      dbname = "bacula"; dbuser = "bacula"; dbpassword = "bacula_db_password"
    }

This will allow the Bacula Director to connect to the MySQL database.

### Configure Pool

A Pool resource defines the set of storage used by Bacula to write backups. We will use files as our storage volumes, and we will simply update the label so our local backups get labeled properly.

Find the Pool resource named “File” (it’s under a comment that says “# File Pool definition”), and add a line that specifies a Label Format. It should look like this when you’re done:

bacula-dir.conf — Update Pool:

    # File Pool definition
    Pool {
      Name = File
      Pool Type = Backup
      Label Format = Local-
      Recycle = yes # Bacula can automatically recycle Volumes
      AutoPrune = yes # Prune expired volumes
      Volume Retention = 365 days # one year
      Maximum Volume Bytes = 50G # Limit Volume size to something reasonable
      Maximum Volumes = 100 # Limit number of Volumes in Pool
    }

Save and exit. You’re finally done configuring the Bacula Director.

### Check Director Configuration:

Let’s verify that there are no syntax errors in your Director configuration file:

    sudo bacula-dir -tc /etc/bacula/bacula-dir.conf

If there are no error messages, your `bacula-dir.conf` file has no syntax errors.

Next, we’ll configure the Storage Daemon.

## Configure Storage Daemon

Our Bacula server is almost set up, but we still need to configure the Storage Daemon, so Bacula knows where to store backups.

Open the SD configuration in your favorite text editor. We’ll use vi:

    sudo vi /etc/bacula/bacula-sd.conf

### Configure Storage Resource

Find the Storage resource. This defines where the SD process will listen for connections. Add the `SDAddress` parameter, and assign it to the private FQDN (or private IP address) of your backup server:

bacula-sd.conf — update SDAddress

    Storage { # definition of myself
      Name = BackupServer-sd
      SDPort = 9103 # Director's port
      WorkingDirectory = "/var/lib/bacula"
      Pid Directory = "/var/run/bacula"
      Maximum Concurrent Jobs = 20
      SDAddress = backup_server_private_FQDN
    }

### Configure Storage Device

Next, find the Device resource named “FileStorage” (search for “FileStorage”), and update the value of `Archive Device` to match your backups directory:

bacula-sd.conf — update Archive Device

    Device {
      Name = FileStorage
      Media Type = File
      Archive Device = /bacula/backup 
      LabelMedia = yes; # lets Bacula label unlabeled media
      Random Access = Yes;
      AutomaticMount = yes; # when device opened, read it
      RemovableMedia = no;
      AlwaysOpen = no;
    }

Save and exit.

### Verify Storage Daemon Configuration

Let’s verify that there are no syntax errors in your Storage Daemon configuration file:

    sudo bacula-sd -tc /etc/bacula/bacula-sd.conf

If there are no error messages, your `bacula-sd.conf` file has no syntax errors.

We’ve completed the Bacula configuration. We’re ready to restart the Bacula server components.

## Set Bacula Component Passwords

Each Bacula component, such as the Director, SD, and FD, have passwords that are used for inter-component authentication—you probably noticed placeholders while going through the configuration files. It is possible to set these passwords manually but, because you don’t actually need to know these passwords, we’ll run commands to generate random passwords and insert them into the various Bacula configuration files.

These commands generate and set the Director password. The `bconsole` connects to the Director, so it needs the password too:

    DIR_PASSWORD=`date +%s | sha256sum | base64 | head -c 33`
    sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" /etc/bacula/bacula-dir.conf
    sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" /etc/bacula/bconsole.conf

These commands generate and set the Storage Daemon password. The Director connects to the SD, so it needs the password too:

    SD_PASSWORD=`date +%s | sha256sum | base64 | head -c 33`
    sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" /etc/bacula/bacula-sd.conf
    sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" /etc/bacula/bacula-dir.conf

These commands generate and set the local File Daemon (the Bacula client software) password. The Director connects to this FD, so it needs the password too:

    FD_PASSWORD=`date +%s | sha256sum | base64 | head -c 33`
    sudo sed -i "s/@@FD_PASSWORD@@/${FD_PASSWORD}/" /etc/bacula/bacula-dir.conf
    sudo sed -i "s/@@FD_PASSWORD@@/${FD_PASSWORD}/" /etc/bacula/bacula-fd.conf

Now we’re ready to start our Bacula components!

## Start Bacula Components

Start the Bacula Director, Storage Daemon, and local File Daemon with these commands:

    sudo systemctl start bacula-dir
    sudo systemctl start bacula-sd
    sudo systemctl start bacula-fd

If they all started correctly, run these commands so they start automatically on boot:

    sudo systemctl enable bacula-dir
    sudo systemctl enable bacula-sd
    sudo systemctl enable bacula-fd

Let’s test that Bacula works by running a backup job.

## Test Backup Job

We will use the Bacula Console to run our first backup job. If it runs without any issues, we will know that Bacula is configured properly.

Now enter the Console with this command:

    sudo bconsole

This will take you to the Bacula Console prompt, denoted by a `*` prompt.

### Create a Label

Begin by issuing a `label` command:

    label

You will be prompted to enter a volume name. Enter any name that you want:

    Enter new Volume name:MyVolume

Then select the pool that the backup should use. We’ll use the “File” pool that we configured earlier, by entering “2”:

    Select the Pool (1-3):2

### Manually Run Backup Job

Bacula now knows how we want to write the data for our backup. We can now run our backup to test that it works correctly:

    run

You will be prompted to select which job to run. We want to run the “BackupLocalFiles” job, so enter “1” at the prompt:

    Select Job resource (1-3):1

At the “Run Backup job” confirmation prompt, review the details, then enter “yes” to run the job:

    yes

### Check Messages and Status

After running a job, Bacula will tell you that you have messages. The messages are output generated by running jobs.

Check the messages by typing:

    messages

The messages should say “No prior Full backup Job record found”, and that the backup job started. If there are any errors, something is wrong, and they should give you a hint as to why the job did not run.

Another way to see the status of the job is to check the status of the Director. To do this, enter this command at the bconsole prompt:

    status director

If everything is working properly, you should see that your job is running. Something like this:

    Output — status director (Running Jobs)Running Jobs:
    Console connected at 09-Apr-15 12:16
     JobId Level Name Status
    ======================================================================
         3 Full BackupLocalFiles.2015-04-09_12.31.41_06 is running
    ====

When your job completes, it will move to the “Terminated Jobs” section of the status report, like this:

    Output — status director (Terminated Jobs)Terminated Jobs:
     JobId Level Files Bytes Status Finished Name
    ====================================================================
         3 Full 161,124 877.5 M OK 09-Apr-15 12:34 BackupLocalFiles

The “OK” status indicates that the backup job ran without any problems. Congratulations! You have a backup of the “Full Set” of your Bacula server.

The next step is to test the restore job.

## Test Restore Job

Now that a backup has been created, it is important to check that it can be restored properly. The `restore` command will allow us restore files that were backed up.

### Run Restore All Job

To demonstrate, we’ll restore all of the files in our last backup:

    restore all

A selection menu will appear with many different options, which are used to identify which backup set to restore from. Since we only have a single backup, let’s “Select the most recent backup"—select option 5:

    Select item (1-13):5

Because there is only one client, the Bacula server, it will automatically be selected.

The next prompt will ask which FileSet you want to use. Select "Full Set”, which should be 2:

    Select FileSet resource (1-2):2

This will drop you into a virtual file tree with the entire directory structure that you backed up. This shell-like interface allows for simple commands to mark and unmark files to be restored.

Because we specified that we wanted to “restore all”, every backed up file is already marked for restoration. Marked files are denoted by a leading `*` character.

If you would like to fine-tune your selection, you can navigate and list files with the “ls” and “cd” commands, mark files for restoration with “mark”, and unmark files with “unmark”. A full list of commands is available by typing “help” into the console.

When you are finished making your restore selection, proceed by typing:

    done

Confirm that you would like to run the restore job:

    OK to run? (yes/mod/no):yes

### Check Messages and Status

As with backup jobs, you should check the messages and Director status after running a restore job.

Check the messages by typing:

    messages

There should be a message that says the restore job has started or was terminated with an “Restore OK” status. If there are any errors, something is wrong, and they should give you a hint as to why the job did not run.

Again, checking the Director status is a great way to see the state of a restore job:

    status director

When you are finished with the restore, type `exit` to leave the Bacula Console:

    exit

### Verify Restore

To verify that the restore job actually restored the selected files, you can look in the `/bacula/restore` directory (which was defined in the “RestoreLocalFiles” job in the Director configuration):

    sudo ls -la /bacula/restore

You should see restored copies of the files in your root file system, excluding the files and directories that were listed in the “Exclude” section of the “RestoreLocalFiles” job. If you were trying to recover from data loss, you could copy the restored files to their appropriate locations.

### Delete Restored Files

You may want to delete the restored files to free up disk space. To do so, use this command:

    sudo -u root bash -c "rm -rf /bacula/restore/*"

Note that you have to run this `rm` command as root, as many of the restored files are owned by root.

## Conclusion

You now have a basic Bacula setup that can backup and restore your local file system. The next step is to add your other servers as backup clients so you can recover them, in case of data loss.

The next tutorial will show you how to add your other, remote servers as Bacula clients: [How To Back Up a CentOS 7 Server with Bacula](how-to-back-up-a-centos-7-server-with-bacula).
