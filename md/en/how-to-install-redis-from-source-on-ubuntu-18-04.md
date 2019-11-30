---
author: Mark Drake, Justin Ellingwood
date: 2018-06-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-redis-from-source-on-ubuntu-18-04
---

# How To Install Redis from Source on Ubuntu 18.04

## Introduction

[Redis](https://redis.io/) is an in-memory key-value store known for its flexibility, performance, and broad language support. It is commonly used as a database, cache, and message broker, and supports a wide range of data structures.

This tutorial demonstrates how to install and configure Redis from source on an Ubuntu 18.04 server. Please note that Redis can be installed in fewer steps by downloading and installing it via the official Ubuntu repositories. To install Redis using this method, please see our guide on [How to Install and Secure Redis on Ubuntu 18.04](how-to-install-and-secure-redis-on-ubuntu-18-04).

## Prerequisites

To complete this guide, you will need access to an Ubuntu 18.04 server set up by following [this initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a non-root user with `sudo` privileges and a firewall.

When you are ready to begin, log in to your Ubuntu 18.04 server with your `sudo` user and continue below.

## Step 1 — Installing the Build and Test Dependencies

In order to get the latest version of Redis, we will compile and install the software from source. Before you download the source code, though, you must satisfy the build dependencies so that you can compile the software.

To do this, install the `build-essential` meta-package from the Ubuntu repositories. Additionally, download the `tcl` package which you can use to test the binaries.

Update your local `apt` package cache and install the dependencies by typing:

    sudo apt update
    sudo apt install build-essential tcl

With that, all the build and test dependencies are installed on your server and you can begin the process of installing Redis itself.

## Step 2 — Downloading, Compiling, and Installing Redis

After installing its dependencies, you’re ready to install Redis by downloading, compiling, and then building the source code. Since you won’t need to keep the Redis source code for the long term (you can always re-download it), download the source code to your `/tmp` directory.

Start by navigating to this directory:

    cd /tmp

Next, use `curl` to download the latest stable version of Redis. The latest version can always be found at [a stable download URL](http://download.redis.io/redis-stable.tar.gz):

    curl -O http://download.redis.io/redis-stable.tar.gz

Unpack the tarball by typing:

    tar xzvf redis-stable.tar.gz

Then move into the Redis source directory structure that was just extracted:

    cd redis-stable

Compile the Redis binaries by typing:

    make

After the binaries have finished compiling, run the test suite to make sure everything was built correctly:

    make test

This typically takes a few minutes to finish. Once the test completes, install the binaries onto the system by typing:

    sudo make install

That’s it for installing Redis, and now you’re ready to start configuring it. To this end, you’ll need to create a configuration directory. The Redis configuration directory is conventionally located within the `/etc/` directory, and you can create it there by typing:

    sudo mkdir /etc/redis

Next, copy over the sample Redis configuration file that came included with the Redis source archive:

    sudo cp /tmp/redis-stable/redis.conf /etc/redis

Open the file with your preferred text editor to make a few changes to the configuration:

    sudo nano /etc/redis/redis.conf

Inside the file, find the `supervised` directive. This directive allows you to declare an init system to manage Redis as a service, providing you with more control over its operation. The `supervised` directive is set to `no` by default. Since you are running Ubuntu, which uses the systemd init system, change this to `systemd`:

/etc/redis/redis.conf

    . . .
    
    # If you run Redis from upstart or systemd, Redis can interact with your
    # supervision tree. Options:
    # supervised no - no supervision interaction
    # supervised upstart - signal upstart by putting Redis into SIGSTOP mode
    # supervised systemd - signal systemd by writing READY=1 to $NOTIFY_SOCKET
    # supervised auto - detect upstart or systemd method based on
    # UPSTART_JOB or NOTIFY_SOCKET environment variables
    # Note: these supervision methods only signal "process is ready."
    # They do not enable continuous liveness pings back to your supervisor.
    supervised systemd
    
    . . .

Next, find the `dir` directive. This option specifies the directory which Redis will use to dump persistent data. You need to change this to a location where Redis will have write permissions and which isn’t viewable by normal users.

Use the `/var/lib/redis` directory for this; you will create this directory and adjust its permissions later in Step 4:

/etc/redis/redis.conf

    . . .
    
    # The working directory.
    #
    # The DB will be written inside this directory, with the filename specified
    # above using the 'dbfilename' configuration directive.
    #
    # The Append Only File will also be created inside this directory.
    #
    # Note that you must specify a directory here, not a file name.
    dir /var/lib/redis
    
    . . .

Save and close the file when you are finished.

Those are all the changes you need to make to the Redis configuration file, but there are still a few steps you need to go through — such has configuring Redis to run as a service and creating its dedicated user and group — before you can start using it.

## Step 3 — Creating a Redis systemd Unit File

In order to have some more control over how you manage Redis, you can create a systemd unit file which will allow it to function as a systemd service. This will also have the benefit of making it easy to enable Redis to start up whenever your server boots.

Create and open the `/etc/systemd/system/redis.service` file to get started:

    sudo nano /etc/systemd/system/redis.service

Once inside, begin the `[Unit]` section by adding a description of the service and defining a requirement that networking must be available before it is started:

/etc/systemd/system/redis.service

    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target

The `[Service]` section is where you specify the service’s behavior. For security purposes, you should not run this service as **root**. You should instead use a dedicated user and group and, for simplicity, you can call both of these **redis**. You will create these momentarily.

To start the service, you just need to call the `redis-server` binary and point it at your configuration. To stop it, use the Redis `shutdown` command, which you can execute with the `redis-cli` binary. Also, since it’s desirable to have Redis recover from failures whenever possible, set the `Restart` directive to `always`:

/etc/systemd/system/redis.service

    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target
    
    [Service]
    User=redis
    Group=redis
    ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
    ExecStop=/usr/local/bin/redis-cli shutdown
    Restart=always

Finally, add an `[Install]` section. There, define the systemd target that the service should attach to if it’s enabled (meaning that it’s configured to start at boot):

/etc/systemd/system/redis.service

    [Unit]
    Description=Redis In-Memory Data Store
    After=network.target
    
    [Service]
    User=redis
    Group=redis
    ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
    ExecStop=/usr/local/bin/redis-cli shutdown
    Restart=always
    
    [Install]
    WantedBy=multi-user.target

Save and close the file when you are finished.

The Redis systemd unit file is all set. Before it can be put to use, though, you must create the dedicated user and group you referenced in the `[Service]` section and grant them the permissions they need to function.

## Step 4 — Creating the Redis User, Group, and Directories

The last things you need to do before starting and testing Redis are to create the user, group, and directory that you referenced in the previous two files.

Begin by creating the **redis** user and group. You can do this in a single command by typing:

    sudo adduser --system --group --no-create-home redis

Next, create the `/var/lib/redis` directory (which is referenced in the `redis.conf` file you created in Step 2) by typing:

    sudo mkdir /var/lib/redis

Give the `redis` user and group ownership over this directory:

    sudo chown redis:redis /var/lib/redis

Finally, adjust the permissions so that regular users cannot access this location:

    sudo chmod 770 /var/lib/redis

You’ve put all the components Redis needs to function in place. You’re now ready to start the Redis service and test its functionality.

## Step 5 — Starting and Testing Redis

Start the systemd service by typing:

    sudo systemctl start redis

Check that the service has no errors by running:

    sudo systemctl status redis

This will produce output similar to the following:

    Output● redis.service - Redis In-Memory Data Store
       Loaded: loaded (/etc/systemd/system/redis.service; disabled; vendor preset: enabled)
       Active: active (running) since Tue 2018-05-29 17:49:11 UTC; 4s ago
     Main PID: 12720 (redis-server)
        Tasks: 4 (limit: 4704)
       CGroup: /system.slice/redis.service
               └─12720 /usr/local/bin/redis-server 127.0.0.1:6379
    . . .

To test that your service is functioning correctly, connect to the Redis server with the command-line client:

    redis-cli

In the prompt that follows, test connectivity by typing:

    ping

This will return:

    OutputPONG

Next, check that you can set keys by typing:

    set test "It's working!"

    OutputOK

Retrieve the `test` value by typing:

    get test

You should be able to retrieve the value you stored:

    Output"It's working!"

After confirming that you can fetch the value, exit the Redis prompt to get back to the shell:

    exit

As a final test, we will check whether Redis is able to persist data even after it’s been stopped or restarted. To do this, first restart the Redis instance:

    sudo systemctl restart redis

Then connect with the client again and confirm that your test value is still available:

    redis-cli

    get test

The value of your key should still be accessible:

    Output"It's working!"

Exit out into the shell again when you are finished:

    exit

Assuming all of these tests worked and that you would like to start Redis automatically when your server boots, enable the systemd service:

    sudo systemctl enable redis

    OutputCreated symlink from /etc/systemd/system/multi-user.target.wants/redis.service to /etc/systemd/system/redis.service.

With that, your Redis installation is fully operational.

## Conclusion

In this tutorial, you installed, compiled, and built Redis from its source code, configured it to run as a systemd service, and you validated that your Redis installation is functioning correctly. As an immediate next step, we **strongly** encourage you to secure your Redis installation by following our guide on [How To Secure Your Redis Installation on Ubuntu 18.04](how-to-secure-your-redis-installation-on-ubuntu-18-04).
