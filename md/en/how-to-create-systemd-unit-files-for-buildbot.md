---
author: Melissa Anderson
date: 2017-05-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-systemd-unit-files-for-buildbot
---

# How To Create Systemd Unit Files for Buildbot

## Introduction

Buildbot is a Python-based continuous integration system for automating software build, test, and release processes. In the prerequisite tutorial, [How To Install Buildbot on Ubuntu 16.04](how-to-install-buildbot-on-ubuntu-16-04), we created a `buildbot` user and group, installed the buildmaster in `/home/buildbot/master` and the worker in `/home/buildbot/worker`, then manually started the processes the new user.

In this tutorial, we’ll create systemd unit files so that the server’s init system can manage the Buildbot processes.

## Prerequisites

**One Ubuntu 16.04 server with at least 1 GB of RAM** , configured with a non-root `sudo` user and a firewall by following the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) with Buildbot installed and configured using the following guide:

- [How To Install Buildbot on Ubuntu 16.04](how-to-install-buildbot-on-ubuntu-16-04)

Once you’ve completed these requirements, you’re ready to begin.

## Step 1 — Stopping the Running Services

First, if you’re still logged in as the `buildbot` user from the previous tutorial, type `exit` to return to the `sudo` user.

As the `sudo` user, we’ll make sure that the Buildmaster is stopped:

    sudo buildbot stop /home/buildbot/master

Then, we’ll ensure the worker is stopped as well:

    sudo buildbot-worker stop /home/buildbot/worker

In each case, we’ll get feedback that `buildbot process 1234 is dead`, (showing the Process ID that was stopped) or `buildmaster not running`, which indicates the service wasn’t running in the first place.

## Step 2 — Creating the Buildmaster Unit File

Next, we’ll create and open a file named `buildbot-master.service`:

    sudo nano /etc/systemd/system/buildbot-master.service

In the `[Unit]` section we’ll add a description and require that networking must be available before starting the service. In the `[Service]` section, we’ll specify that the process runs as the `buildbot` user and group we created, define the working directory, and provide the commands that should be used to start or reload the master. Finally, in the `[Install]` section, we’ll indicate that it should start as part of the the multi-user target at boot:

/etc/systemd/system/buildbot-master.service

    [Unit]
    Description=BuildBot master service
    After=network.target
    
    [Service]
    User=buildbot
    Group=buildbot
    WorkingDirectory=/home/buildbot/master
    ExecStart=/usr/local/bin/buildbot start --nodaemon
    ExecReload=/bin/kill -HUP $MAINPID
    
    [Install]
    WantedBy=multi-user.target

Once we’ve added the content, we’ll save and exit, then test our work.

    sudo systemctl start buildbot-master

We’ll use systemd’s `status` command to check that it started appropriately:

    sudo systemctl status buildbot-master

The output should contain `Active: active (running)` and the last line should look something like:

    OutputMay 08 21:01:24 BuildBot-Install systemd[1]: Started BuildBot master service.

Finally, we’ll enable the buildmaster to start at boot:

    sudo systemctl enable buildbot-master

    OutputCreated symlink from /etc/systemd/system/multi-user.target.wants/buildbot-master.service to /etc/systemd/system/buildbot-master.service.

Now that the buildmaster is set up, we’ll add the worker.

## Step 3 — Creating the Worker Unit File

We’ll create and open a file called `buildbot-worker.service` which is configured like `buildbot-master.service` but with the values needed to start the worker. In the `[Install]` section, we’ll use set the`WantedBy` key to the `buildbot-master.service` so the worker will be started after the buildmaster.

    sudo nano /etc/systemd/system/buildbot-worker.service

/etc/systemd/system/buildbot-worker.service

    [Unit]
    Description=BuildBot worker service
    After=network.target
    
    [Service]
    User=buildbot
    Group=buildbot
    WorkingDirectory=/home/buildbot/worker
    ExecStart=/usr/local/bin/buildbot-worker start --nodaemon
    
    [Install]
    WantedBy=buildbot-master.service

We’ll save and exit, then use `systemctl` to start the worker:

    sudo systemctl start buildbot-worker

We’ll use the `status` command to verify it started successfully:

    sudo systemctl status buildbot-worker

Again, like the master, we should see `Active: active (running)` and a final line of output that looks something like:

    Output. . .
    May 08 21:54:46 BuildBot-Install systemd[1]: Started BuildBot worker service.

Finally, we’ll enable the worker to start at boot:

    sudo systemctl enable buildbot-worker.service

    OutputCreated symlink from /etc/systemd/system/buildbot-master.service.wants/buildbot-worker.service to /etc/systemd/system/buildbot-worker.service.

The output above indicates that the worker is configured to start at boot, but you might like to reboot the server now to confirm everything starts as expected.

### Conclusion

In this tutorial, we’ve added systemd unit files so the server’s init system can manage the Buildbot processes, and we’ve enabled both the buildmaster and worker to start at boot.

In the next tutorial, we’ll [secure the web interface with SSL using Let’s Encrypt](how-to-configure-buildbot-with-ssl-using-an-nginx-reverse-proxy), a free SSL certificate service. Note that you’ll need a domain name that you own or control in order to generate a certificate.
