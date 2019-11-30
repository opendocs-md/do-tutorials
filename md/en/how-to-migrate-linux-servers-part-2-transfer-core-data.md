---
author: Justin Ellingwood
date: 2014-02-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-migrate-linux-servers-part-2-transfer-core-data
---

# How To Migrate Linux Servers Part 2 - Transfer Core Data

## Introduction

* * *

There are many scenarios where you might have to move your data and operating requirements from one server to another. You may need to implement your solutions in a new datacenter, upgrade to a larger machine, or transition to new hardware or a new VPS provider.

Whatever your reasons, there are many different considerations you should make when migrating from one system to another. Getting functionally equivalent configurations can be difficult if you are not operating with a configuration management solution such as Chef, Puppet, or Ansible. You need to not only transfer data, but also configure your services to operate in the same way on a new machine.

In the last article, we [prepped our servers for data migration](https://www.digitalocean.com/community/articles/how-to-migrate-linux-servers-part-1-system-preparation). At this point, your target and source system should be able to communicate (the target system should have SSH access to the source system). You should also have a list of software and services that you need to transfer, complete with version numbers of the most important components.

In this guide, we’ll continue where we left off and begin the actual migration to our new server.

## General Strategy

* * *

Before we begin, we should outline our general strategy for migrating data from our source to our target system.

The general idea is to transfer all of the relevant pieces of information while leaving the target system as clean as possible.

Some migration strategies simply point rsync at the root of the source machine and then pass in some exclude lines to tell the process not to include files that we know will cause conflicts. We won’t take this approach. Migrating large pieces of system data onto a live operating system can cause unpredictable results and we want to end up with a stable system.

Not only that, but we don’t want to needlessly clutter our new system with files that are no longer relevant to our operational requirements. This will take more effort, but it will lead to a more usable and friendly configuration when we are finished.

So we won’t be just migrating every possible non-conflicting file to the new system if it isn’t relevant to what we are hoping to achieve. Instead, we will be deciding exactly which data needs to be moved as a functional requirement for our purposes. This includes data and configuration details, user, jobs, etc.

### Creating a Migration Script

* * *

We will be making these decisions as we go, and adding them to a migration script.

This will give you a number of important advantages. It will allow you to easily re-run the commands again if there is a problem or in order to capture data changes on the source system after the first run. It will self-document the commands you used to transfer the data. It will also allow your source server to continue onto the next item of data transfer without user interaction.

As you write the script, you should be able to run it multiple times, refining it as you go. Most of the files will by transferred through `rsync`, which will only transfer file changes. If the other data transfer portions take a long time, you can safely comment them out until you are fairly sure your script is in its final state.

This article will mostly be a guide on what to add to your migration script to make your migration successful. It will provide general guidelines more often than specifics.

We can create a simple migration script in the root user’s home directory on the target system. We will use this to automate a large portion of our data migration operations:

    nano /root/sync.sh

Inside the file, begin with a standard script heading (we will use “sh” to make this more portable, but you can use “bash” if you would like to use the extended features it offers and have it available on both systems):

    #!/bin/sh

We will add to this as we continue. For now though, let’s exit the file quickly so that we can make it executable.

Back on the command line, make the script executable by typing:

    chmod 700 /root/sync.sh

To run the script at any time, you can now call it using its absolute path:

    /root/sync.sh

Or its relative path:

    cd /root
    ./sync.sh

You should test the script regularly as you go along to see if there are issues that come up.

## Install Needed Programs and Services

* * *

The first step that we need to take prior to automation is to acquire the packages that you need to get these services up and running. We could also add this to the script, but it is easier to just do this portion by hand and document it in our script.

The configuration details will come later. For now, we need these applications installed and basic access configured so that we can get to work. You should have a list of required packages and versions from your source machine.

### Add Additional Repositories if Necessary

* * *

Before we attempt to get these versions from our package manager, we should inspect our source system to see if any additional repositories have been added.

On Ubuntu/Debian machines, you can see if alternative software sources are present on your source system by investigating a few locations:

    nano /etc/apt/sources.list

This is the main source list. Additional source lists can be contained in the `sources.list.d` directory:

    ls /etc/apt/sources.list.d

If you need to, add the same sources to your target machine to have the same package versions available.

On a RHEL-based system, you can use `yum` to list the repositories configured for the server:

    yum repolist enabled

You can then add additional repositories to your target system by typing:

    yum-config-manager --add-repo repo\_url

If you make any changes to your source list, add them as comments at the top of your migration script. This way, if you have to start from a fresh install, you will know what procedures need to happen before attempting a new migration.

    nano /root/sync.sh

    #!/bin/sh ############# # Prep Steps ############# # Add additional repositories to /etc/apt/source.list # deb http://example.repo.com/linux/deb stable main non-free

Save and close the file.

### Specifying Version Constraints and Installing

* * *

You now have the repositories updated to match your source machine.

On Ubuntu/Debian machines, you can now attempt to install the version of the software that you need on your target machine by typing:

    apt-get update apt-get install package\_name=version\_number

Many times, if the version of the package is older, it will have been removed from the official repositories. In this case, you may have to manually hunt down the older version of the .deb files and their dependencies and install them manually with:

    dpkg -i package.deb

This is necessary if matching the software version is important for your application. Otherwise, you can just install regularly with your package manager.

For RHEL-based systems, you can install specific versions of software by typing:

    yum install package\_name-version\_number

If you need to hunt down rpm files that have been removed from the repository in favor of newer versions, you can install them with yum after you’ve found them like this:

    yum install package\_name.rpm

Install any relevant software that is available from your package manager into the new system. In the event that the software you need is not available through a repository or other easy means and has been installed by source or pulled in as a binary from a project’s website, you will have to replicate this process on the target system.

Again, keep track of what operations you are performing here. We will include them as comments in a script we are creating:

    nano /root/sync.sh

    #!/bin/sh ############# # Prep Steps ############# # Add additional repositories to /etc/apt/source.list # deb http://example.repo.com/linux/deb stable main non-free # Install necessary software and versions # apt-get update # apt-get install apache2=2.2.22-1ubuntu1.4 mysql-server=5.5.35-0ubuntu0.12.04.2 libapache2-mod-auth-mysql=4.3.9-13ubuntu3 php5-mysql=5.3.10-1ubuntu3.9 php5=5.3.10-1ubuntu3.9 libapache2-mod-php5=5.3.10-1ubuntu3.9 php5-mcrypt=5.3.5-0ubuntu1

Again, save and close the file.

## Start Transferring Data

* * *

The actual transfer of data can easily be the most time-intensive part of the migration. If you are migrating a server with a lot of data, it is probably a good idea to start transferring data sooner rather than later. You can refine your commands later on, and rsync only transfers the differences between files, so this shouldn’t be a problem.

We can begin by starting an rsync of any large chunks of user data that need to be transferred. In this context, we are using “user” data to refer to any significant data needed by your server except database data. This includes site data, user home directories, configuration files, etc.

### Installing and Using Screen

* * *

To do this effectively, we’re going to want to start a `screen` session on our target system that you can leave running while you continue to work.

You can install `screen` using your distribution’s package manager. On Ubuntu or Debian, you could type this:

    apt-get update
    apt-get install screen

You can find out [how to operate screen](https://www.digitalocean.com/community/articles/how-to-install-and-use-screen-on-an-ubuntu-cloud-server) by checking out this link.

Basically, you need to start a new screen session like this on your target server:

    screen

A screen session will start, and drop you back into a command line. It will probably look like nothing has happened, but you’re now operating a terminal that is contained within the screen program.

All of the work that we will do during our migration will happen within a screen session. This allows us to easily jump between multiple terminal sessions, and allows us to pick up where we left off if we have to leave our local terminal or we get disconnected.

You can issue commands here and then disconnect the terminal, allowing it to continue running. You can disconnect at any time by typing:

    CTRL-a d

You can reconnect later by typing:

    screen -r

If you need to create another terminal window within your screen session, type:

    CTRL-a c

To switch between windows, type these two to cycle through windows in either direction:

    CTRL-a n
    CTRL-a p

Destroy a window by typing:

    CTRL-a k

### Begin File Transfers Early

* * *

Inside of your screen session, start any rsync tasks that you anticipate taking a long time to complete. The time scale here depends on the amount of significant (non-database) data you have to transfer.

The general command you’ll want to use is:

    rsync -avz --progress source\_server:/path/to/directory/to/transfer /path/to/local/directory

You can find out more about how to create appropriate rsync commands by reading [this article](https://www.digitalocean.com/community/articles/how-to-use-rsync-to-sync-local-and-remote-directories-on-a-vps). You may have to create the directories leading up to the destination in order for the command to execute properly.

When you have your rsync session running, create a new screen window and switch to it by typing:

    CTRL-a c

Check back periodically to see if the syncing is complete and perhaps to start a subsequent sync by typing:

    CTRL-a p

### Adjusting the Script to Sync Data and Files

* * *

Now, you should add the same rsync command that you just executed into the script you are creating. Add any additional rsync commands that you need in order to get all of your significant user and application data onto your target server.

We will not worry about database files at this point, because there are better methods of transferring those files. We will discuss these in a later section.

    #!/bin/sh ############# # Prep Steps ############# # Add additional repositories to /etc/apt/source.list # deb http://example.repo.com/linux/deb stable main non-free # Install necessary software and versions # apt-get update # apt-get install apache2=2.2.22-1ubuntu1.4 mysql-server=5.5.35-0ubuntu0.12.04.2 libapache2-mod-auth-mysql=4.3.9-13ubuntu3 php5-mysql=5.3.10-1ubuntu3.9 php5=5.3.10-1ubuntu3.9 libapache2-mod-php5=5.3.10-1ubuntu3.9 php5-mcrypt=5.3.5-0ubuntu1 ############# # File Transfer ############# # Rsync web root rsync -avz --progress 111.222.333.444:/var/www/site1 /var/www/ # Rsync the apache configuration files rsync -avz --progress 111.222.333.444:/etc/apache2/\* /etc/apache2/ # Rsync php configuration rsync -avz --progress 111.222.333.444:/etc/php5/\* /etc/php5/ # Rsync mysql config files rsync -avz --progress 111.222.333.444:/etc/mysql/\* /etc/mysql/ # Rsync home directories . . .

You should add any rsync commands that you need to transfer your data and configurations off of the source system.

This does not need to be perfect, because we can always go back and adjust it, so just try your best. If you’re unsure of whether you need something right now, leave it out for the time being and just add a comment instead.

We will be running the script multiple times, allowing you to modify it to pick up additional files if you end up needing them. Being conservative about what you transfer will keep your target system clean of unnecessary files.

We are trying to replicate the functionality and data of the original system, and not necessarily the mess.

## Modifying Configuration Files

* * *

Although many pieces of software will work exactly the same after transferring the relevant configuration details and data from the original server, some configuration will likely need to be modified.

This presents a slight problem with our syncing script. If we run the script to sync our data, and then modify the values to reflect the correct information for its new home, these changes will be wiped out the next time we run the script again.

Remember, we will likely be running the rsync script multiple times to catch up with changes that have occurred on the source system since we’ve started our migration. The source system can change significantly during the course of migrating and testing the new server.

There are two general paths that we can take to avoid wiping out our changes. First, I’ll discuss the easy way, and follow up with what I consider the more robust solution.

### The Quick and Dirty Way

* * *

The easy way of addressing this is to modify the files as needed on the target system after the first sync operation. Afterwards, you then can modify the rsync commands in your script to exclude the files that you adjusted.

This will cause rsync to _not_ sync these files on subsequent runs, which would overwrite your changes with the original files again.

This can be accomplished by commenting out the previous sync command and adding a new one with some exclude statements like this:

    # rsync -avz --progress 111.222.333.444:/etc/mysql/\* /etc/mysql/ rsync -avz --progress --exclude='my.cnf' 111.222.333.444:/etc/mysql/\* /etc/mysql/

You should add exclusion lines for any files under the rsync directory specification that have been modified. It would also be a good idea to add a comment as to what was modified in the file, in case you actually do need to recreate it at any point.

    # Adding exclude rule. Changed socket to '/mysqld/mysqld.sock' # rsync -avz --progress 111.222.333.444:/etc/mysql/\* /etc/mysql/ rsync -avz --progress --exclude='my.cnf' 111.222.333.444:/etc/mysql/\* /etc/mysql/

### The Robust and Recommended Way

* * *

While the above method addresses the problem in some ways, it’s really just avoiding the issue instead of solving it. We can do better.

Linux systems include a variety of text manipulators that are very useful for scripting. In fact, most of these programs are made specifically to allow their use in a scripted environment.

The two most useful utilities for this task are `sed` and `awk`. You can click here to [learn how to use the sed stream editor](https://www.digitalocean.com/community/articles/the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux), and check out this link to see [how to use awk to manipulate text](https://www.digitalocean.com/community/articles/how-to-use-the-awk-language-to-manipulate-text-in-linux).

The basic idea is that we can script any changes that we would be making manually, so that the script itself will perform any necessary modifications.

So in the previous example, instead of adding an exclusion for the file we modified after the fact, we could keep that rsync command and make that change automatically using a sed command:

    rsync -avz --progress 111.222.333.444:/etc/mysql/\* /etc/mysql/ # Change socket to '/mysqld/mysqld.sock' sed -i 's\_/var/run/mysqld/mysqld.sock\_/mysqld/mysqld.sock\_g' /etc/mysql/my.cnf

This will change the socket location in every instance of the file, each time the file is transferred. Make sure that the text manipulation lines come _after_ the lines that sync the files that they operate on.

In a similar way, we can easily script changes made to tabular data files using awk. For instance, the `/etc/shadow` file is divided into tabs delimited by the colon (:) character. We could use awk to remove the hashed root password from the second column like this:

    awk 'BEGIN { OFS=FS=":"; } $1=="root" { $2=""; } { print; }' /etc/shadow > shadow.tmp && mv shadow.tmp /etc/shadow && rm shadow.tmp

This command is telling awk that both the original and the output delimiter should be “:” instead of the default space. We then specify that if column 1 is equal to “root”, then column 2 should be set to an empty string.

Up until fairly new versions of awk, there was no option to edit in place, so here we are writing this file to a temporary file, overwriting the original file, and then removing the temporary file.

We should do our best to script all of the changes needed in our files. This way, it will be easy to reuse some of the lines from our migration script for other migrations, with some easy modification.

An easy way of doing this is to go through your script and add comments to your script for each file that needs to be modified. After you know your requirements, go back and add the commands that will perform the necessary operations.

Add these changes to your script and let’s move on.

## Dump and Transfer your Database files

* * *

If your system is using a database management system, you will want to dump the database using the methods available for your system. This will vary depending on the DBMS you use (MySQL, MariaDB, PostgreSQL, etc.).

For a regular MySQL system, you can export the database using something like this:

    mysqldump -Q -q -e -R --add-drop-table -A -u root -proot\_password \> /root/database\_name.db

MySQL dump options are highly dependent on the context, so you’ll have to explore which options are right for your system before deciding. This is beyond the scope of this article.

Let’s go over what these options will do for the database dump.

- **-Q** : This option is enabled by default, but is added here for extra safety. It puts identifiers like database names inside quotes to avoid misinterpretation.
- **-q** : This stands for quick and can help speed up large table dumps. In actuality, it is telling MySQL to operate on a row-by-row basis instead of trying to handle the entire table at once.
- **-e** : This creates smaller dump files by grouping insert statements together instead of handling them individually when the dump file is loaded.
- **-R** : This allows MySQL to also dump stored routines along with the rest of the data.
- **–add-drop-table** : This option specifies that MySQL should issue a DROP TABLE command prior to each CREATE TABLE to avoid running into an error if the table already exists.
- **-A** : This option specifies that MySQL should dump all of the databases.
- **-u** : This details the MySQL user to use for the connection. This should be root.
- **-p** : This is the password needed for the MySQL root account.

This will create a MySQL dump of the source system’s MySQL data on the original system. We can wrap this in an SSH command to have it execute remotely:

    ssh root@111.222.333.444 'mysqldump -Q -q -e -R --add-drop-table -A -u root -proot_password > /root/database_name.db'

We can then use a normal rsync command to retrieve the file when it is finished:

    rsync -avz --progress 111.222.333.444:/root/database_name.db /root/

After that, we can import the dump into the target system’s MySQL instance:

    mysql -u root -proot_password < /root/database_name.db

Another option is to configure a replication setup between the original database and the target system’s database. This can allow you to simply swap the master and the slave when you are finished, in order to finalize the database migration.

This is also beyond this article’s scope, but you can find details about [how to configure master-slave replication](https://www.digitalocean.com/community/articles/how-to-set-up-master-slave-replication-in-mysql) here.

If you go this route, make sure to add comments to your script specifying your configuration. If there is a big issue, you want to be able to have good information on what you did so that you can avoid it on a second attempt.

## Next Steps

* * *

You should now have most of your data on your target system, or be in the process of transferring. This will accomplish the bulk of actual data transfer, but we still need to do quite a bit of configuration on our system to match our previous machine.

In the [next article](https://www.digitalocean.com/community/articles/how-to-migrate-linux-servers-part-3-final-steps), we will move on to transfer other information and user settings.

By Justin Ellingwood
