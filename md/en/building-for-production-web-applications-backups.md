---
author: Mitchell Anicas
date: 2015-06-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/building-for-production-web-applications-backups
---

# Building for Production: Web Applications — Backups

## Introduction

After coming up with a recovery plan for the various components of your application, you should set up the backup system that is required to support it. This tutorial will focus on using Bacula as a backups solution. The benefits of using a full-fledged backup system, such as Bacula, is that it gives you full control over what you back up and restore at the individual file level, and you can schedule backups and restores according to what is best for you.

![Backup Diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/production/backup_system.png)

Solutions such as [DigitalOcean Droplet Backups](understanding-digitalocean-droplet-backups) (snapshot backups of your entire Droplet) are easy to set up and may be sufficient for your needs, if you only require weekly backups. If you opt for DigitalOcean Backups, be sure to set up hot backups of your database by following the **Create Hot Backups of Your Database** section.

In this part of the tutorial, we will set up a Bacula to maintain daily backups of the **required backups** of the servers that comprise your application setup (db1, app1, app2, and lb1), defined previously in our recovery plan—essentially, this is a tutorial that shows you how to use Bacula to create backups of a LAMP stack. We will also use Percona XtraBackup to create hot backups of your MySQL database. Lastly, we will use rsync to create a copy of your backups, on a server in a remote data center. This will add two servers to your setup: **backups** and **remotebackups** (located in a separate data center).

Let’s get started.

## Install Bacula on Backups Server

Set up Bacula on your **backups** server by following this tutorial: [How To Install Bacula Server on Ubuntu 14.04](how-to-install-bacula-server-on-ubuntu-14-04).

Then follow the **Organize Bacula Director Configuration (Server)** section of this tutorial: [How To Back Up an Ubuntu 14.04 Server with Bacula](how-to-back-up-an-ubuntu-14-04-server-with-bacula#organize-bacula-director-configuration-(server)). You will need the Director Name when setting up the Bacula clients (on the servers you want to back up). Stop when you reach the **Install and Configure Bacula Client** section.

Note that we will be using the RemoteFile pool for all of the backups jobs that we will be setting up. With that said, you may want to change some of the settings before proceeding.

## Install Bacula Client on Each Server

Install the Bacula client on each server that you want to back up (db1, app1, app2, and lb1) by following the **Install and Configure Bacula Client** section of this tutorial: [How To Back Up an Ubuntu 14.04 Server with Bacula](how-to-back-up-an-ubuntu-14-04-server-with-bacula#install-and-configure-bacula-client). Stop when you reach the **Add FileSets (Server)** section.

Note that you will need the **FileDaemon Name** (usually the hostname appended by “-fd”) and the **Director Password** (the password that the Bacula server will use to connect to each client) from the `bacula-fd.conf` file on each server.

## Add Bacula Clients to Backups Server

On **backups** , the Bacula server, add a **Client resource** to the `/etc/bacula/conf.d/clients.conf` file for each server that you installed the Bacula client on.

Open the `clients.conf` file:

    sudo vi /etc/bacula/conf.d/clients.conf

Here is an example of the Client resource definition for the database server, **db1**. Note that the value of **Name** should match the the Name of the **FileDaemon** resource and the **Password** should match the Password of the **Director** resource, on the client server—these values can be found in `/etc/bacula/bacula-fd.conf` on each Bacula client server:

clients.conf — Example Client resource definition

    Client {
      Name = db1-fd
      Address = db1.nyc3.example.com
      FDPort = 9102
      Catalog = MyCatalog
      Password = "PDL47XPnjI0QzRpZVJKCDJ_xqlMOp4k46" # password for Remote FileDaemon
      File Retention = 30 days # 30 days
      Job Retention = 6 months # six months
      AutoPrune = yes # Prune expired Jobs/Files
    }

Create a similar Client resource for each of the remaining Bacula client servers. In our example, there should be four Client resources when we are finished: **db1-fd** , **app1-fd** , **app2-fd** , and **lb1-fd**. This configures the Bacula Director, on the **backups** server, to be able to connect to the Bacula client on each server..

Save and exit.

More details about this section can be found in the **Install and Configure Bacula Client** in the [How To Back Up an Ubuntu Server with Bacula tutorial](how-to-back-up-an-ubuntu-14-04-server-with-bacula#install-and-configure-bacula-client).

## Create Hot Backups of Your Database

To ensure that we produce consistent (i.e. usable) backups of our active database, special care must be taken. A simple and effective way to create hot backups with MySQL is to use Percona XtraBackup.

### Install Percona XtraBackup

On your database server, **db1** , install and configure Percona XtraBackup by following this tutorial: [How To Create Hot Backups of MySQL Databases with Percona XtraBackup on Ubuntu 14.04](how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-ubuntu-14-04). Stop when you reach the **Perform Full Hot Backup** section.

### Create XtraBackup Script

Percona XtraBackup is ready to create hot backups of your MySQL database, which will ultimately be backed up by Bacula (or DigitalOcean Backups), but the hot backups must be scheduled somehow. We will set up the simplest solution: a bash script and a cron job.

Create a bash script called `run_extra_backup.sh` in `/usr/local/bin`:

    sudo vi /usr/local/bin/run_xtrabackup.sh

Add the following script. Be sure to substitute the user and password with whatever you set up when you installed XtraBackup:

/usr/local/bin/run\_xtrabackup.sh

    #!/bin/bash
    
    # pre xtrabackup
    chown -R mysql: /var/lib/mysql
    find /var/lib/mysql -type d -exec chmod 770 "{}" \;
    
    # delete existing full backup
    rm -r /data/backups/full
    
    # xtrabackup create backup
    innobackupex --user=bkpuser --password=bkppassword --no-timestamp /data/backups/full
    
    # xtrabackup prepare backup
    innobackupex --apply-log /data/backups/full

Save and exit. Running this script (with superuser privileges) will delete the existing XtraBackup backup at `/data/backups/full` and create a new full backup. More details about creating backups with XtraBackup can be found in the [Perform Full Hot Backup](how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-ubuntu-14-04#perform-full-hot-backup) section of the of the XtraBackup tutorial.

Make the script executable:

    sudo chmod +x /usr/local/bin/run_xtrabackup.sh

In order to properly backup our database, we must run (and complete) the XtraBackup script before Bacula tries to backup the database server. A good solution is to configure your Bacula backup job to run the script as a “pre-backup script”, but we will opt to use a [cron job](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps) to keep it simple.

Create a cron configuration file (files in `/etc/cron.d` get added to root’s crontab):

    sudo vi /etc/cron.d/xtrabackup

Add the following cron job:

/etc/cron.d/xtrabackup

    30 22 * * * root /usr/local/bin/run_xtrabackup.sh

This schedules the script to run as root every day at 10:30pm (22nd hour, 30th minute). We chose this time because Bacula is currently scheduled to run its backup jobs at 11:05pm daily—we will discuss adjusting this later. This allows 35 minutes for the XtraBackup script to complete.

Now that the database hot backups are set up, let’s look at the Bacula backup FileSets.

## Configure Bacula FileSets

Bacula will create backups of files that are specified in the FileSets that are associated with the backup Jobs that will be executed. This section will cover creating FileSets that include the **required backups** that we identified in our recovery plans. More details about adding FileSets to Bacula can be found in the [Add FileSets (Server)](how-to-back-up-an-ubuntu-14-04-server-with-bacula#add-filesets-(server)) section of the Bacula tutorial.

On your **backups** server, open the `filesets.conf` file:

    sudo vi /etc/bacula/conf.d/filesets.conf

### Database Server FileSet

The required backups for our database server, according to our database server recovery plan, include:

- **MySQL database:** a backup copy is created by our XtraBackup script in `/data/backups/full`, daily at 10:30pm
- **MySQL configuration:** located in `/etc/mysql`

We also will include the XtraBackup script: `/usr/local/bin/run_xtrabackup.sh`, and the associated cron file.

With our required backups in mind, we will add this “MySQL Database” FileSet to our Bacula configuration:

filesets.conf — MySQL Database

    FileSet {
      Name = "MySQL Database"
      Include {
        Options {
          signature = MD5
          compression = GZIP
        }
        File = /data/backups
        File = /etc/mysql/my.cnf
        File = /usr/local/bin/run_xtrabackup.sh
        File = /etc/cron.d/xtrabackup
      }
      Exclude {
        File = /data/backups/exclude
      }
    }

Now let’s move on to the application server FileSet.

### Application Server FileSet

The required backups for our application servers, according to our application server recovery plan, include:

- **Application Files:** located in `/var/www/html` in our example

With our required backups in mind, we will add this “Apache DocumentRoot” FileSet to our Bacula configuration:

filesets.conf — Apache DocumentRoot

    FileSet {
      Name = "Apache DocumentRoot"
      Include {
        Options {
          signature = MD5
          compression = GZIP
        }
        File = /var/www/html
      }
      Exclude {
        File = /var/www/html/exclude
      }
    }

You may want to also include the Apache ports configuration file, but that is easily replaceable.

Now let’s move on to the load balancer server FileSet.

### Load Balancer Server FileSet

The required backups for our load balancer servers, according to our load balancer server recovery plan, include:

- **SSL Certificate (PEM) and related files:** located in `/root/certs` in our example
- **HAProxy configuration file:** located in `/etc/haproxy`

With our required backups in mind, we will add this “Apache DocumentRoot” FileSet to our Bacula configuration:

filesets.conf — SSL Certs and HAProxy Config

    FileSet {
      Name = "SSL Certs and HAProxy Config"
      Include {
        Options {
          signature = MD5
          compression = GZIP
        }
        File = /root/certs
        File = /etc/haproxy
      }
      Exclude {
        File = /root/exclude
      }
    }

Save and exit.

Now our FileSets are configured. Let’s move on to the creating the Bacula backup Jobs that will use these FileSets.

## Create Bacula Backup Jobs

We will create Bacula backup Jobs that will run and create backups of our servers.

Create a `jobs.conf` file in `/etc/bacula/conf.d`:

    sudo vi /etc/bacula/conf.d/jobs.conf

### Database Server Backup Job

For our database server backup job, we will create a new job named “Backup db1”. The important thing here is that we specify the correct **Client** (db1-fd) and **FileSet** (MySQL Database):

jobs.conf — Backup db1

    Job {
      Name = "Backup db1"
      JobDefs = "DefaultJob"
      Client = db1-fd
      Pool = RemoteFile
      FileSet="MySQL Database"
    }

Now we will set up the application server backup jobs.

### Application Server Backup Jobs

For our application servers, we will create two backup jobs named “Backup app1” and “Backup app2”. The important thing here is that we specify the correct **Clients** (app1-fd and app2-fd) and **FileSet** (Apache DocumentRoot).

App1 job:

jobs.conf — Backup app1

    Job {
      Name = "Backup app1"
      JobDefs = "DefaultJob"
      Client = app1-fd
      Pool = RemoteFile
      FileSet="Apache DocumentRoot"
    }

App2 job:

jobs.conf — Backup app2

    Job {
      Name = "Backup app2"
      JobDefs = "DefaultJob"
      Client = app2-fd
      Pool = RemoteFile
      FileSet="Apache DocumentRoot"
    }

Now we will set up the load balancer server backup job.

### Load Balancer Server Backup Job

For our load balancer server backup job, we will create a new job named “Backup lb1”. The important thing here is that we specify the correct **Client** (lb1-fd) and **FileSet** (SSL Certs and HAProxy Config):

jobs.conf — Backup lb1

    Job {
      Name = "Backup lb1"
      JobDefs = "DefaultJob"
      Client = lb1-fd
      Pool = RemoteFile
      FileSet="SSL Certs and HAProxy Config"
    }

Save and exit.

Now our backup Jobs are configured. The last step is to restart the Bacula Director.

## Restart Bacula Director

On the **backups** server, restart the Bacula Director to put all of our changes into effect:

    sudo service bacula-director restart

At this point, you will want to test your client connections and backup jobs, both of which are covered in the [How To Back Up a Server with Bacula tutorial](how-to-back-up-an-ubuntu-14-04-server-with-bacula#test-client-connection). That tutorial also covers how to restore Bacula backups. Note that restoring the MySQL database will require you to follow the [Perform Backup Restoration](how-to-create-hot-backups-of-mysql-databases-with-percona-xtrabackup-on-ubuntu-14-04#perform-backup-restoration) step in the Percona XtraBackup Tutorial.

## Review Backups Schedule

The Bacula backups schedule can be adjusted by modifying the Bacula Director configuration (`/etc/bacula/bacula-dir.conf`). All of the backup Jobs that we created use the “DefaultJob” JobDef, which uses the “WeeklyCycle” schedule, which is defined as:

- Full backup on the first Sunday of a month at 11:05pm
- Differential backups on all other Sundays at 11:05pm
- Incremental backups on other days, Monday through Saturday, at at 11:05pm

You can verify this by using the Bacula console to check the status of the Director. It should output all of your scheduled jobs:

    Director Status — Scheduled JobsScheduled Jobs:
    Level Type Pri Scheduled Name Volume
    ===================================================================================
    Incremental Backup 10 20-May-15 23:05 BackupLocalFiles MyVolume
    Incremental Backup 10 20-May-15 23:05 Backup lb1 Remote-0002
    Incremental Backup 10 20-May-15 23:05 Backup app2 Remote-0002
    Incremental Backup 10 20-May-15 23:05 Backup app1 Remote-0002
    Incremental Backup 10 20-May-15 23:05 Backup db1 Remote-0002

Feel free to add or adjust the schedule of any of your backup jobs. It would make sense to modify the schedule of the application servers to occur at the same time that the Percona XtraBackup script is executed (10:30pm). This will prevent the application and database backups from being inconsistent with each other.

## Set Up Remote Backups

Now we’re ready to set up a remote server that will store copies of our Bacula backups. This remote server should be in a geographically separate region so you will have a copy of your critical backups even if there is a disaster in your production data center. In our example, we will use DigitalOcean’s San Francisco (SFO1) region for our **remotebackups** server.

We will explain a simple method to send our backups from our **backups** server to our **remotebackups** server using public SSH keys, rsync, and cron.

On the **remotebackups** server, [create a user](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) that will be used for the rsync login.

Next, on the **backups** server, generate a password-less SSH key pair as root. Install the public key on the **remotebackups** user that you just created. This is covered in our [How To Set Up SSH Keys](how-to-set-up-ssh-keys--2) tutorial.

On the **backups** server, write up an rsync command that copies the Bacula backup data (`/bacula/backup`) to somewhere on the **remotebackups** server. Rsync usage is covered in our [How To Use Rsync tutorial](how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps). The command will probably look something like this:

    rsync -az /bacula/backup remoteuser@remotebackups_public_hostname_or_IP:/path/to/remote/backup

Add the command to a script, such as `/usr/local/bin/rsync_backups.sh` and make it executable.

Lastly, you will want to set up a cron job that runs the `rsync_backups.sh` script as root, after the Bacula backups jobs usually complete. This is covered in our [How To Schedule Routine Tasks With Cron tutorial](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps).

After you set all of this up, verify that there is a copy of your backups on the **remotebackups** server the next day.

## Other Considerations

We didn’t talk about the disk requirements for your backups. You will definitely want to review how much disk space your backups are using, and revise your setup and backups schedule based on your needs and resources.

In addition to creating backups of your application servers, you will probably want to set up backups for any other servers that are added to your setup. For example, you should configure Bacula to create backups of your monitoring and centralized logging servers once you get them up and running.

## Conclusion

You should now have daily backups, and a remote copy of those backups, of your production application servers. Be sure to verify that you are able to restore the files, and add the steps of restoring your data to your recovery plans.

Continue to the next tutorial to start setting up the monitoring for your production server setup: [Building for Production: Web Applications — Monitoring](building-for-production-web-applications-monitoring).
