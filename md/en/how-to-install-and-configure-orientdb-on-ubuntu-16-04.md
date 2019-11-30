---
author: finid
date: 2017-03-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-orientdb-on-ubuntu-16-04
---

# How To Install and Configure OrientDB on Ubuntu 16.04

## Introduction

[OrientDB](http://orientdb.com/) is a multi-model NoSQL database with support for graph and document databases. It is a Java application and can run on any operating system. It’s also fully ACID-complaint with support for multi-master replication, allowing easy horizontal scaling.

In this article, you’ll install and configure the latest Community edition of OrientDB on an Ubuntu 16.04 server.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with at least 2GB of RAM ideally, but even 512MB will work.
- A sudo non-root user and firewall, set up by following this [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- Java installed, which you can do by following [the JDK 8 step of this Java installation guide](how-to-install-java-with-apt-get-on-ubuntu-16-04#installing-the-oracle-jdk).

## Step 1 — Downloading and Installing OrientDB

In this step, we’ll download the latest Community edition of OrientDB and install it into the `/opt` directory, the traditional location for installing third party applications in Linux.

Before you start, make sure the packages on your system are up to date.

    sudo apt-get update

Net, download the latest version of OrientDB Community. At publication time, that’s 2.2.20, but you can check [the project’s download page](http://orientdb.com/download) for the latest version and change the version number in the command below to match.

    wget -O orientdb-community-2.2.20.tar.gz http://orientdb.com/download.php?file=orientdb-community-2.2.20.tar.gz&os=linux

The downloaded tarball contains pre-compiled binary files that you need to run OrientDB on your system, so all you need to do now is untar it.

    tar -zxvf orientdb-community-2.2.20.tar.gz

The files are extracted into a directory named `orientdb-community-2.2.20`. Now you need to move it into the `/opt`directory, renaming it to `orientdb` in the process.

    sudo mv ~/orientdb-community-2.2.20 /opt/orientdb

OrientDB is now installed. If you’re using a memory-constrained server, you can configure OrientDB to use less RAM in the next step. Otherwise, you can move on to Step 3 to start the server itself.

## Step 2 — Configuring OrientDB to Use Less RAM (Optional)

By default, the OrientDB daemon expects to have at least 2 GB of RAM available, and will fail to start if it finds less. You’ll see an error like this if you try to start it anyway:

    Outputubuntu-orientdb server.sh[1670]: Java HotSpot(TM) 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000aaaa0000, 1431699456, 0) failed; error='Cannot allocate memory' (errno=12)
    ubuntu-orientdb server.sh[1670]: # There is insufficient memory for the Java Runtime Environment to continue.

There’s one configuration change you can make that will let you get away with using a server with as little as 512 MB of RAM. It’s a function of a setting in the `server.sh` file, which can be changed so that the daemon can start with far less RAM.

Open the file with `nano` or your favorite text editor.

    sudo nano /opt/orientdb/bin/server.sh

Then scroll to the section containing the chunk of code shown in this code block:

/opt/orientdb/bin/server.sh

    . . .
    # ORIENTDB memory options, default to 2GB of heap.
    
    if [-z "$ORIENTDB_OPTS_MEMORY"] ; then
        ORIENTDB_OPTS_MEMORY="-Xms2G -Xmx2G"
    fi
    . . .

The values you need to change are `Xms` and `Xmx`, which specify the initial and maximum memory allocation pool for the Java Virtual Machine. By default, they’re set to 2GB.

You can set new values that are less than amount of RAM allocated to the server, but make sure `Xms` is at least 128 MB or OrientDB won’t start. For example, the values below set the initial and maximum amount of ram to 128MB and 256MB, respectively.

/opt/orientdb/bin/server.sh

    # ORIENTDB memory options, default to 2GB of heap.
    
    if [-z "$ORIENTDB_OPTS_MEMORY"] ; then
        ORIENTDB_OPTS_MEMORY="-Xms128m -Xmx256m"
    fi

Save and close the file. In the next step, you’ll start OrientDB.

## Step 3 — Starting the Server

Now that the binary is in place and you’ve optionally configured the server to use less RAM, you can now start the server and connect to the console.

Navigate to the installation directory.

    cd /opt/orientdb

Then start the server.

    sudo bin/server.sh

When starting the server for the first time, you’ll be prompted to specify a password for the **root** user account. This is an internal OrientDB account that will be used to access the server for things like OrientDB Studio, the web-based interface for managing OrientDB. If you don’t specify a password, one will be generated automatically. However, it’s best to specify one yourself, so do so when prompted.

Part of the output generated from starting the server tells you what ports the server and OrientDB Studio are listening on.

    Output2017-02-04 19:13:21:306 INFO Listening binary connections on 0.0.0.0:2424 (protocol v.36, socket=default) [OServerNetworkListener]
    2017-02-04 19:13:21:310 INFO Listening http connections on 0.0.0.0:2480 (protocol v.10, socket=default) [OServerNetworkListener]
    . . .
    2017-02-04 19:13:21:372 INFO OrientDB Studio available at http://192.168.0.30:2480/studio/index.html [OServer]
    2017-02-04 19:13:21:374 INFO OrientDB Server is active v2.2.20 (build UNKNOWN@r98dbf8a2b8d43e4af09f1b12fa7ae9dfdbd23f26; 2017-02-02 07:01:26+0000). 
    [OServer]

When you see this, OrientDB is now running in your current terminal. Let’s confirm that the server is listening on the appropriate ports.

Open a second terminal and connect to the same server via SSH.

    ssh sammy@your_server_ip

Then, in that second terminal, confirm that the server is listening on ports `2424` (for binary connections) and `2480` (for HTTP connections) with the following command.

    sudo netstat -plunt | grep -i listen

The output should contain references to both port numbers, like this:

    Outputtcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1160/sshd       
    tcp6 0 0 :::2480 :::* LISTEN 2758/java       
    tcp6 0 0 :::22 :::* LISTEN 1160/sshd       
    tcp6 0 0 :::2424 :::* LISTEN 2758/java

Now that server is started and you’ve verified it’s running, you’ll connect to the OrientDB console in the second terminal next.

## Step 4 — Connecting to the Console

The OrientDB console is the command line interface for working with the application. To launch it, type:

    sudo /opt/orientdb/bin/console.sh

You will see the following:

    OutputOrientDB console v.2.2.20 (build UNKNOWN@r98dbf8a2b8d43e4af09f1b12fa7ae9dfdbd23f26; 2017-02-02 07:01:26+0000) www.orientdb.com
    Type 'help' to display all the supported commands.
    Installing extensions for GREMLIN language v.2.6.0
    
    
    orientdb>

Now, connect to the server instance. The password required is the one you specified when you first started the server in the previous step.

    connect remote:127.0.0.1 root root-password

You’ll see this output if you successfully connect.

    OutputConnecting to remote Server instance [remote:127.0.0.1] with user 'root'...OK
    orientdb {server=remote:127.0.0.1/}>

If you don’t, double check that you entered the root password correctly and that OrientDB is still running in your first terminal.

When you’re ready, type `exit` in your second terminal to quit the OrientDB prompt.

    exit

You’ve just installed OrientDB, manually started it, and connected to it. This means OrientDB is working, but it also means you’ll need to start it manually anytime you reboot the server. In the next few steps, we’ll configure and set up OrientDB to run just like any other daemon on the server.

## Step 5 — Configuring OrientDB as a Daemon

At this point, OrientDB is installed, but it’s just a bunch of scripts on the server. In this step, we’ll configure it to run as a daemon on the system. That involves modifying the `/opt/orientdb/bin/orientdb.sh` script and the configuration file, `/opt/orientdb/config/orientdb-server-config.xml`.

First, type `CTRL+C` in your first terminal window with OrientDB still running to stop it. You can also close the second terminal connection now.

Let’s start by modifying the `/opt/orientdb/bin/orientdb.sh` script to tell OrientDB the user it should be run as, and to point it to the installation directory.

So, create the system user that you want OrientDB to run as. In this example, we’re creating the **orientdb** user. The command will also create the **orientdb** group:

    sudo useradd -r orientdb -s /sbin/nologin

Give ownership of the OrientDB directory and files to the newly-created OrientDB user and group.

    sudo chown -R orientdb:orientdb /opt/orientdb

Now let’s make a few changes to the `orientdb.sh` script.

    sudo nano /opt/orientdb/bin/orientdb.sh

First, we need to point it to the proper installation directory, then tell it what user it should be run as. So look for the following two lines towards the top of the file:

 /opt/orientdb/bin/orientdb.sh

    . . .
    # You have to SET the OrientDB installation directory here
    ORIENTDB_DIR="YOUR_ORIENTDB_INSTALLATION_PATH"
    ORIENTDB_USER="USER_YOU_WANT_ORIENTDB_RUN_WITH"
    . . .

And change them to `/opt/orientdb` and `orientdb` respectively.

/opt/orientdb/bin/orientdb.sh

    # You have to SET the OrientDB installation directory here
    ORIENTDB_DIR="/opt/orientdb"
    ORIENTDB_USER="orientdb"

Save and close the file.

Then modify the server configuration file’s permissions to prevent unauthorized users from reading it.

    sudo chmod 640 /opt/orientdb/config/orientdb-server-config.xml

You can learn more about file permissions in [this Linux permissions tutorial](an-introduction-to-linux-permissions).

In the next step, we’ll configure the daemon so that it’s controlled by [Systemd, the service manager](understanding-systemd-units-and-unit-files).

## Step 6 — Installing the Systemd Startup Script

OrientDB comes with a Systemd service descriptor file that will be responsible for starting and stopping the service. That file has to be copied into the `/etc/systemd/system` directory.

    sudo cp /opt/orientdb/bin/orientdb.service /etc/systemd/system

There are a few settings in that file that we need to modify, so open it for editing.

    sudo nano /etc/systemd/system/orientdb.service

Modify the **User** , **Group** and **ExecStart** variables under **Service** to match your installation. You set the user and group in step 5 (which are both **orientdb** if you followed the step verbatim). **ExecStart** specifies the path to the script, which should begin with `/opt/orientdb` if you’ve followed this tutorial as written.

/etc/systemd/system/orientdb.service

    . . .
    
    [Service]
    User=orientdb
    Group=orientdb
    ExecStart=/opt/orientdb/bin/server.sh

Save and close the file.

Then run the following command to reload all units.

    sudo systemctl daemon-reload

With everything in place, you may now start the OrientDB service.

    sudo systemctl start orientdb

And ensure that it will start on boot.

    sudo systemctl enable orientdb

Verify that it really did start by checking the process status.

    sudo systemctl status orientdb

    Output● orientdb.service - OrientDB Server
       Loaded: loaded (/etc/systemd/system/orientdb.service; disabled; vendor preset: enabled)
       Active: active (running) since Sat 2017-02-04 20:54:27 CST; 11s ago
     Main PID: 22803 (java)
        Tasks: 14
       Memory: 126.4M
    . . .

If the server does not start, look for clues in the output. In the next step, you’ll learn how to connect to OrientDB Studio, the application’s web user interface.

## Step 7 — Connecting to OrientDB Studio

OrientDB Studio is the web interface for managing OrientDB. This is useful for testing purposes, although it’s a [better security practice](how-to-secure-your-orientdb-database-on-ubuntu-16-04) to restrict access to it entirely.

If you want to enable it for testing, you’ll need to add a rule to your firewall. By default, OrientDB studio listens on port `2480`, so if you configured the firewall on the server, you’ll need to allow access to port `2480`.

    sudo ufw allow 2480

Then, restart UFW.

    sudo systemctl restart ufw

To connect to OrientDB Studio, visit `http://your_server_ip:2480` in your browser. Once the page loads, you will see the login screen.

You can log in as **root** with the password you set earlier. You can also select the `GratefulDeadConcerts` database and log in using one of the default user accounts included with OrientDB ( **admin** , **reader** , or **writer** ).

## Conclusion

You’ve just installed the Community edition of OrientDB on your Ubuntu 16.04 server, customized its configuration, and set it up as a daemon to be managed by systemd.

Next, you should protect the application from unauthorized users by applying a few security tips using [this OrientDB security tutorial](how-to-secure-your-orientdb-database-on-ubuntu-16-04). If you have an existing OrientDB installation that you need to import into a new installation, use [this migration guide](how-to-import-and-export-an-orientdb-database-on-ubuntu-14-04), which was written for Ubuntu 14.04 but will also work for Ubuntu 16.04.

For additional information about OrientDB, visit [the project’s official documentation](http://orientdb.com/docs/last/index.html).
