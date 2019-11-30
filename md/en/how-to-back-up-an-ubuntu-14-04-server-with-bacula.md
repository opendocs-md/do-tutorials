---
author: Mitchell Anicas
date: 2015-04-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-an-ubuntu-14-04-server-with-bacula
---

# How To Back Up an Ubuntu 14.04 Server with Bacula

## Introduction

This tutorial will show you how to set up Bacula to create backups of a remote Ubuntu 14.04 host, over a network connection. This involves installing and configuring the Bacula Client software on a remote host, and making some additions to the configuration of an existing Bacula Server (covered in the prerequisites).

If you are trying to create backups of CentOS 7 hosts, follow this link instead: [How To Back Up a CentOS 7 Server with Bacula](how-to-back-up-a-centos-7-server-with-bacula).

## Prerequisites

This tutorial assumes that you have a server running the Bacula Server components, as described in this link: [How To Install Bacula Server on Ubuntu 14.04](how-to-install-bacula-server-on-ubuntu-14-04).

We are also assuming that you are using private network interfaces for backup server-client communications. We will refer to the private FQDN of the servers (FQDNs that point to the private IP addresses). If you are using IP addresses, simply substitute the connection information where appropriate.

For the rest of this tutorial, we will refer to the Bacula Server as “BaculaServer”, “Bacula Server”, or “Backup Server”. We will refer to the remote host, that is being backed up, as “ClientHost”, “Client Host”, or “Client”.

Let’s get started by making some quick changes to the Bacula Server configuration.

## Organize Bacula Director Configuration (Server)

On your **Bacula Server** , perform this section once.

When setting up your Bacula Server, you may have noticed that the configuration files are excessively long. We’ll try and organize the Bacula Director configuration a bit, so it uses separate files to add new configuration such as jobs, file sets, and pools.

Let’s create a directory to help organize the Bacula configuration files:

    sudo mkdir /etc/bacula/conf.d

Then open the Bacula Director configuration file:

    sudo vi /etc/bacula/bacula-dir.conf

At the end of the file add, this line:

bacula-dir.conf — Add to end of file

    @|"find /etc/bacula/conf.d -name '*.conf' -type f -exec echo @{} \;"

Save and exit. This line makes the Director look in the `/etc/bacula/conf.d` directory for additional configuration files to append. That is, any `.conf` file added in there will be loaded as part of the configuration.

### Add RemoteFile Pool

We want to add an additional Pool to our Bacula Director configuration, which we’ll use to configure our remote backup jobs.

Open the `conf.d/pools.conf` file:

    sudo vi /etc/bacula/conf.d/pools.conf

Add the following Pool resource:

conf.d/pools.conf — Add Pool resource

    Pool {
      Name = RemoteFile
      Pool Type = Backup
      Label Format = Remote-
      Recycle = yes # Bacula can automatically recycle Volumes
      AutoPrune = yes # Prune expired volumes
      Volume Retention = 365 days # one year
        Maximum Volume Bytes = 50G # Limit Volume size to something reasonable
      Maximum Volumes = 100 # Limit number of Volumes in Pool
    }

Save and exit. This defines a “RemoteFile” pool, which we will use by the backup job that we’ll create later. Feel free to change any of the parameters to meet your own needs.

We don’t need to restart Bacula Director just yet, but let’s verify that its configuration doesn’t have any errors in it:

    sudo bacula-dir -tc /etc/bacula/bacula-dir.conf

If there are no errors, you’re ready to continue on to the Bacula Client setup.

## Install and Configure Bacula Client

Perform this section on any **Client Host** that you are adding to your Bacula setup.

First, update apt-get:

    sudo apt-get update

Then install the `bacula-client` package:

    sudo apt-get install bacula-client

This installs the Bacula File Daemon (FD), which is often referred to as the “Bacula client”.

### Configure Client

Before configuring the client File Daemon, you will want to look up the following information, which will be used throughout the remainder of this tutorial:

- **Client hostname:** : Our example will use “ClientHost”
- **Client Private FQDN:** We’ll refer to this as “client\_private\_FQDN”, which may look like `clienthost.private.example.com`
- **Bacula Server hostname:** Our example will use “BackupServer”

Your actual setup will vary from the example, so be sure to make substitutions where appropriate.

Open the File Daemon configuration:

    sudo vi /etc/bacula/bacula-fd.conf

We need to change a few items and save some information that we will need for our server configuration.

Begin by finding the Director resource that is named after your client hostname (e.g. “ClientHost-dir”). As the Bacula Director that we want to control this Client is located on the Bacula Server, change the “Name” parameter to the hostname of your backup server followed by “-dir”. Following our example, with “BackupServer” as the Bacula Server’s hostname, it should look something like this after being updated:

bacula-fd.conf — Update Director Name

    Director {
      Name = BackupServer-dir
      Password = "IrIK4BHRA2o5JUvw2C_YNmBX_70oqfaUi"
    }

You also need to copy the `Password`, which is the automatically generated password used for connections to File Daemon, and save it for future reference. This will be used in the Backup Server’s Director configuration, which we will set in an upcoming step, to connect to your Client’s File Daemon.

Next, we need to adjust one parameter in the FileDaemon resource. We will change the `FDAddress` parameter to match the private FQDN of our client machine. The `Name` parameter should already be populated correctly with the client file daemon name. The resource should looks something like this (substitute the actual FQDN or IP address):

bacula-fd.conf — Update FDAddress

    FileDaemon { # this is me
      Name = ClientHost-fd
      FDport = 9102 # where we listen for the director
      WorkingDirectory = /var/lib/bacula
      Pid Directory = /var/run/bacula
      Maximum Concurrent Jobs = 20
      FDAddress = client_private_FQDN
    }

We also need to configure this daemon to pass its log messages to the Backup Server. Find the Messages resource and change the `director` parameter to match your backup server’s hostname with a “-dir” suffix. It should look something like this:

bacula-fd.conf — Update director

    Messages {
      Name = Standard
      director = BackupServer-dir = all, !skipped, !restored
    }

Save the file and exit. Your File Daemon (Bacula Client) is now configured to listen for connections over the private network.

Check that your configuration file has the correct syntax with the following command:

    sudo bacula-fd -tc /etc/bacula/bacula-fd.conf

If the command returns no output, the configuration file has valid syntax. Restart the file daemon to use the new settings:

    sudo service bacula-fd restart

Let’s set up a directory that the Bacula Server can restore files to. Create the file structure and lock down the permissions and ownership for security with the following commands:

    sudo mkdir -p /bacula/restore
    sudo chown -R bacula:bacula /bacula
    sudo chmod -R 700 /bacula

The client machine is now configured correctly. Next, we will configure the Backup Server to be able to connect to the Bacula Client.

## Add FileSets (Server)

A Bacula FileSet defines a set of files or directories to include or exclude files from a backup selection, and are used by backup jobs on the Bacula Server.

If you followed the prerequisite tutorial, which sets up the Bacula Server components, you already have a FileSet called “Full Set”. If you want to run Backup jobs that include almost every file on your Backup Clients, you can use that FileSet in your jobs. You may find, however, that you often don’t want or need to have backups of everything on a server, and that a subset of data will suffice.

Being more selective in which files are included in a FileSet will decrease the amount of disk space and time, required by your Backup Server, to run a backup job. It can also make restoration simpler, as you won’t need to sift through the “Full Set” to find which files you want to restore.

We will show you how to create new FileSet resources, so that you can be more selective in what you back up.

On your **Bacula Server** , open a file called `filesets.conf`, in the Bacula Director configuration directory we created earlier:

    sudo vi /etc/bacula/conf.d/filesets.conf

Create a FileSet resource for each particular set of files that you want to use in your backup jobs. In this example, we’ll create a FileSet that only includes the home and etc directories:

filesets.conf — Add Home and Etc FileSet

    FileSet {
      Name = "Home and Etc"
      Include {
        Options {
          signature = MD5
          compression = GZIP
        }
        File = /home
        File = /etc
      }
      Exclude {
        File = /home/bacula/not_important
      }
    }

There are a lot of things going on in this file, but here are a few details to keep in mind:

- The FileSet Name must be unique
- Include any files or partitions that you want to have backups of
- Exclude any files that you don’t want to back up, but were selected as a result of existing within an included file

You can create multiple FileSets if you wish. Save and exit, when you are finished.

Now we’re ready to create backup job that will use our new FileSet.

## Add Client and Backup Job to Bacula Server

Now we’re ready to add our Client to the Bacula Server. To do this, we must configure the Bacula Director with new Client and Job resources.

Open the `conf.d/clients.conf` file:

    sudo vi /etc/bacula/conf.d/clients.conf

### Add Client Resource

A Client resource configures the Director with the information it needs to connect to the Client Host. This includes the name, address, and password of the Client’s File Daemon.

Paste this Client resource definition into the file. Be sure to substitute in your Client hostname, private FQDN, and password (from the Client’s `bacula-fd.conf`), where highlighted:

conf.d/clients.conf — Add Client resource

    Client {
      Name = ClientHost-fd
      Address = client_private_FQDN
      FDPort = 9102 
      Catalog = MyCatalog
      Password = "IrIK4BHRA2o5JUvw2C_YNmBX_70oqfaUi" # password for Remote FileDaemon
      File Retention = 30 days # 30 days
      Job Retention = 6 months # six months
      AutoPrune = yes # Prune expired Jobs/Files
    }

You only need to do this once for each Client.

### Create a backup job:

A Backup job, which must have a unique name, defines the details of which Client and which data should be backed up.

Next, paste this backup job into the file, substituting the Client hostname for the highlighted text:

conf.d/clients.conf — Add Backup job resource

    Job {
      Name = "BackupClientHost"
      JobDefs = "DefaultJob"
      Client = ClientHost-fd
      Pool = RemoteFile
      FileSet="Home and Etc"
    }

This creates a backup job called “BackupClientHost”, which will back up the home and etc directories of the Client Host, as defined in the “Home and Etc” FileSet. It will use the settings specified in the “DefaultJob” JobDefs and “RemoteFile” Pool resources, which are both defined in the main `bacula-dir.conf` file. By default, jobs that specify `JobDefs = "DefaultJob"` will run weekly.

Save and exit when you are done.

### Verify Director Configuration

Let’s verify that there are no syntax errors in your Director configuration file:

    sudo bacula-dir -tc /etc/bacula/bacula-dir.conf

If you are returned to the shell prompt, there are no syntax errors in your Bacula Director’s configuration files.

### Restart Bacula Director

To put the configuration changes that you made into effect, restart Bacula Director:

    sudo service bacula-director restart

Now your Client, or remote host, is configured to be backed up by your Bacula Server.

## Test Client Connection

We should verify that the Bacula Director can connect to the Bacula Client.

On your Bacula Server, enter the Bacula Console:

    sudo bconsole

    status client

    Select Client resource: ClientHost-fdThe defined Client resources are:
         1: BackupServer-fd
         2: ClientHost-fd
    Select Client (File daemon) resource (1-2): 2

The Client’s File Daemon status should return immediately. If it doesn’t, and there is a connection error, there is something wrong with the configuration of the Bacula Server or of the Client’s File Daemon.

## Test Backup Job

Let’s run the backup job to make sure it works.

On the **Bacula Server** , while still in the Console, use this command:

    run

You will be prompted to select which Job to run. Select the one we created earlier, e.g. “4. BackupClientHost”:

    Select Job resource: BackupClientHostThe defined Job resources are:
         1: BackupLocalFiles
         2: BackupCatalog
         3: RestoreLocalFiles
         4: BackupClientHost
    Select Job resource (1-4): 4

At the confirmation prompt, enter “yes”:

    Confirmation prompt:
    OK to run? (yes/mod/no): yes

### Check Messages and Status

After running a job, Bacula will tell you that you have messages. The messages are output generated by running jobs.

Check the messages by typing:

    messages

The messages should say “No prior Full backup Job record found”, and that the backup job started. If there are any errors, something is wrong, and they should give you a hint as to why the job did not run.

Another way to see the status of the job is to check the status of the Director. To do this, enter this command at the bconsole prompt:

    status director

If everything is working properly, you should see that your job is running or terminated with an “OK” status.

## Perform Restore

The first time you set up a new Bacula Client, you should test that the restore works properly.

If you want to perform a restore, use the `restore` command at the Bacula Console:

    restore all

A selection menu will appear with many different options, which are used to identify which backup set to restore from. Since we only have a single backup, let’s “Select the most recent backup"—select option 5:

    Select item (1-13):5

Then you must specify which Client to restore. We want to restore the remote host that we just set up, e.g. "ClientHost-fd”:

    Select the Client: ClientHost-fdDefined Clients:
         1: BackupServer-fd
         2: ClientHost-fd
    Select the Client (1-2): 2

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

If everything worked properly, your restored files will be on your Client host, in the `/bacula/restore` directory. If you were simply testing the restore process, you should delete the contents of that directory.

## Conclusion

You now have a Bacula Server that is backing up files from a remote Bacula Client. Be sure to review and revise your configuration until you are certain that you are backing up the correct FileSets, on a schedule that meets your needs. If you are trying to create backups of CentOS 7 hosts, follow this link: [How To Back Up a CentOS 7 Server with Bacula](how-to-back-up-a-centos-7-server-with-bacula).

The next thing you should do is repeat the relevant sections of this tutorial for any additional Ubuntu 14.04 servers that you want to back up.
