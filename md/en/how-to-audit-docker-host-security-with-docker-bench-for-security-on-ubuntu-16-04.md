---
author: Brian Boucheron
date: 2018-06-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-audit-docker-host-security-with-docker-bench-for-security-on-ubuntu-16-04
---

# How To Audit Docker Host Security with Docker Bench for Security on Ubuntu 16.04

## Introduction

Using Docker to containerize your applications and services can give you some security benefits out of the box, but a default Docker installation still has room for some security-related configuration improvements. The [Center for Internet Security](https://www.cisecurity.org), a non-profit whose mission is to promote internet security best-practices, created [a step-by-step checklist for securing Docker](https://www.cisecurity.org/benchmark/docker/). Subsequently, the Docker team released a security auditing tool – Docker Bench for Security – to run through this checklist on a Docker host and flag any issues it finds.

In this tutorial we will install Docker Bench for Security, then use it to assess the security stance of a default Docker installation (from the official Docker repository) on an Ubuntu 16.04 host. We will then fix some of the issues that it warns us about.

Our fixes mostly consist of the following two configuration updates:

- Installing `auditd` and setting up auditing rules for the Docker daemon and its associated files
- Updating Docker’s `daemon.json` configuration file

We will not go into any details about creating secure containers, we will only focus on updates to the Docker host security in this tutorial.

## Prerequisites

In order to complete this tutorial, you will need the following:

- An Ubuntu 16.04 server with a sudo-enabled, non-root user. You can learn how to set this up with our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide
- Docker installed from the official Docker repository, as covered in [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04). Be sure to give your non-root user access to Docker by adding it to the **docker** group. This is covered in Step 2 of the tutorial.

## Step 1 — Installing Docker Bench Security

To begin, SSH into the Docker host as your non-root user.

We will first clone the Docker Bench for Security script to the server using `git`, then run the script directly from the cloned repository.

Navigate to a directory that your user can write to. In this example, we’ll download the script to the user’s home directory:

    cd ~

Then clone the `docker-bench-security` Git repository:

    git clone https://github.com/docker/docker-bench-security.git

This will pull all the files from the repo and place them in a local `docker-bench-security` directory. Next, move into this resulting directory:

    cd docker-bench-security

Finally, to perform the security audit, run the `docker-bench-security.sh` script:

    ./docker-bench-security.sh

    Output# ------------------------------------------------------------------------------
    # Docker Bench for Security v1.3.4
    #
    # Docker, Inc. (c) 2015-
    #
    # Checks for dozens of common best-practices around deploying Docker containers in production.
    # Inspired by the CIS Docker Community Edition Benchmark v1.1.0.
    # ------------------------------------------------------------------------------
    
    Initializing Tue Jun 5 18:59:11 UTC 2018
    
    
    [INFO] 1 - Host Configuration
    [WARN] 1.1 - Ensure a separate partition for containers has been created
    [NOTE] 1.2 - Ensure the container host has been Hardened
    [INFO] 1.3 - Ensure Docker is up to date
    [INFO] * Using 18.03.1, verify is it up to date as deemed necessary
    . . .

The script runs through a variety of tests and gives an `INFO`, `NOTE`, `PASS`, or `WARN` result for each one. A default Docker installation on Ubuntu 16.04 will pass many of these tests, but will show some warnings in sections 1,2, and 4.

In the remainder of this tutorial we will address these warnings by securing our Docker installation.

## Step 2 — Correcting Host Configuration Warnings

The first section of the audit tests the configuration of your host’s operating system, including its hardening, package versions, and auditing configuration. Let’s look at the tests in this section:

**1.1 Ensure a separate partition for containers has been created**

To ensure proper isolation, it’s a good idea to keep Docker containers and all of `/var/lib/docker` on their own filesystem partition. This can be difficult in some cloud hosting situations where you may not have the ability to partition drives. In these cases you could satisfy this test by moving Docker’s data directory to an external network-attached block device.

- To learn how to partition a drive, take a look at [How To Partition and Format Storage Devices in Linux](how-to-partition-and-format-storage-devices-in-linux).
- To mount a block storage device to a DigitalOcean Droplet, read [An Introduction to DigitalOcean Block Storage](an-introduction-to-digitalocean-block-storage).
- To learn how to mount block storage devices on other cloud platforms, refer to your provider’s documentation.

**1.2 Ensure the container host has been Hardened**

This test is just a note to remind you to consider hardening your host. Hardening usually involves setting up a firewall, locking down various services, setting up auditing and logging, and implementing other security measures. You can get started with this by reading [7 Security Measures to Protect Your Servers](7-security-measures-to-protect-your-servers).

**1.3 Ensure Docker is up to date**

This test prints out your Docker version. You can check which version is the current stable release by visiting [the Docker CE release notes](https://docs.docker.com/release-notes/docker-ce/). If you’re not up to date, and you installed Docker using `apt-get install`, you can use `apt-get` again to upgrade the Docker package:

    sudo apt-get update
    sudo apt-get upgrade

**1.4 Ensure only trusted users are allowed to control Docker daemon**

In the [prerequisite Docker setup tutorial](how-to-install-and-use-docker-on-ubuntu-16-04) we added our non-root user to the **docker** group to give it access to the Docker daemon. This test outputs the **docker** group’s line from the `/etc/group` file:

    Outputdocker:x:999:sammy

This line shows all the users included in the **docker** group. Review the line and make sure that only appropriate users are authorized to control the Docker daemon. In the example above, our authorized user **sammy** is highlighted. To remove users from this group, you can use `gpasswd`:

    gpasswd -d username docker

**1.5–1.13 Ensure auditing is configured for various Docker files**

We need to install and configure `auditd` to enable auditing of some of Docker’s files, directories, and sockets. Auditd is a Linux access monitoring and accounting subsystem that logs noteworthy system operations at the kernel level.

Install `auditd` with `apt-get`:

    sudo apt-get install auditd

This will install and start the `auditd` daemon. We’ll now configure `auditd` to monitor Docker files and directories. In a text editor, open the audit rules file:

    sudo nano /etc/audit/audit.rules

You should see the following text:

/etc/audit/audit.rules

    # This file contains the auditctl rules that are loaded
    # whenever the audit daemon is started via the initscripts.
    # The rules are simply the parameters that would be passed
    # to auditctl.
    
    # First rule - delete all
    -D
    
    # Increase the buffers to survive stress events.
    # Make this bigger for busy systems
    -b 320
    
    # Feel free to add below this line. See auditctl man page

Paste the following snippet at the bottom of the file, then save and exit the editor:

/etc/audit/audit.rules

    -w /usr/bin/docker -p wa
    -w /var/lib/docker -p wa
    -w /etc/docker -p wa
    -w /lib/systemd/system/docker.service -p wa
    -w /lib/systemd/system/docker.socket -p wa
    -w /etc/default/docker -p wa
    -w /etc/docker/daemon.json -p wa
    -w /usr/bin/docker-containerd -p wa
    -w /usr/bin/docker-runc -p wa

These rules instruct auditd to watch (`-w`) the specified file or directory and log any writes or attribute changes (`-p wa`) to those files.

Restart `auditd` for the changes to take effect:

    sudo systemctl restart auditd

At this point, you’ve successfully configured `auditd` to watch Docker files and directories for suspicious changes. You can rerun the Docker Bench for Security script to confirm that the tests in Section 1 now pass.

For more information on `auditd`, you can read our tutorial [How To Use the Linux Auditing System on CentOS 7](how-to-use-the-linux-auditing-system-on-centos-7). Despite being written for CentOS, the sections on configuring and using the auditing system apply equally to Ubuntu.

Now that we’ve verified our host configuration, we’ll move on to Section 2 of the Docker security audit, the Docker daemon configuration.

## Step 3 — Correcting Docker Daemon Configuration Warnings

This section of the audit deals with the configuration of the Docker daemon. These warnings can all be addressed by creating a configuration file for the daemon called `daemon.json`, to which we’ll add some security-related configuration parameters. We’ll first create and save this configuration file, then review the tests and corresponding lines in the config one by one.

To begin, open up the configuration file in your favorite editor:

    sudo nano /etc/docker/daemon.json

This will present you with a blank text file. Paste in the following:

/etc/docker/daemon.json

    {
        "icc": false,
        "userns-remap": "default",
        "log-driver": "syslog",
        "disable-legacy-registry": true,
        "live-restore": true,
        "userland-proxy": false,
        "no-new-privileges": true
    }

Save and close the file, then restart the Docker daemon so it picks up this new configuration:

    sudo systemctl restart docker

You may now rerun the audit to confirm that all the Section 2 warnings have been addressed.

The configuration variables we’ve inserted into this file are arranged in the same order as the audit warnings. Let’s walk through each of them:

**2.1 Ensure network traffic is restricted between containers on the default bridge**

This warning is addressed by `"icc": false` in the configuration file. This configuration creates containers that can only communicate with each other when explicitly linked using `--link=container_name` on the Docker command line or the `links:` parameter in Docker Compose configuration files. One benefit of this is that if an attacker compromises one container, they’ll have a harder time finding and attacking other containers on the same host.

**2.8 Enable user namespace support**

Linux namespaces provide additional isolation for processes running in your containers. User namespace remapping allows processes to run as **root** in a container while being remapped to a less privileged user on the host. We enable user namespace remapping with the `"userns-remap": "default"` line in the configuration file.

We set the parameter to `default`, which means Docker will create a **dockremap** user to which container users will be remapped. You can verify that the **dockremap** user was created using the `id` command:

    sudo id dockremap

You should see output similar to the following:

    Outputuid=112(dockremap) gid=116(dockremap) groups=116(dockremap)

If remapping container users to a different host user makes more sense for your use case, specify the user or `user:group` combination in place of `default` in the configuration file.

**Warning:** User remapping is a powerful feature that could cause disruptions and breakages if improperly configured, so highly recommended that you [read the official documentation](https://docs.docker.com/engine/security/userns-remap/#about-remapping-and-subordinate-user-and-group-ids) and be aware of the implications before implementing this change in a production setting.

**2.11 Ensure that authorization for Docker client commands is enabled**

If you need to allow network access to the Docker socket you should [consult the official Docker documentation](https://docs.docker.com/engine/security/https/) to find out how to set up the certificates and keys necessary to do so securely.

We will not cover this process here, because the specifics depend too much on individual situations. The audit will continue to flag this test as a `WARN`, though access to the default local-only Docker socket is protected by requiring membership in the **docker** group so this can be safely ignored.

**2.12 Ensure centralized and remote logging is configured**

In the Docker daemon configuration file, we’ve enabled standard syslog logging with the `"log-driver": "syslog"` line. You should then configure syslog to forward logs to a centralized syslog server. This gets logs off the Docker host and away from any attacker who could alter or delete them.

If you only want to forward Docker logs and don’t want to ship the syslog, you can specify the remote syslog server in the Docker configuration file by appending the following parameter to the file:

/etc/docker/daemon.json

        `"log-opts": { "syslog-address": "udp://198.51.100.33:514" }`

Be sure to replace the IP address with your own syslog server’s address.

Alternately, you could specify a log driver like `splunk` or `fluentd` to ship Docker daemon logs using other log aggregation services. For more information on Docker log drivers and their configuration, [consult the official Docker logging drivers documentation](https://docs.docker.com/config/containers/logging/configure/).

**2.13 Ensure operations on legacy registry (v1) are Disabled**

This warning is fixed by the `"disable-legacy-registry": true` line in the daemon configuration file. This disables an insecure legacy image registry protocol. As support for this protocol has already been removed from the Docker daemon, this flag is in the process of being deprecated.

**2.14 Ensure live restore is Enabled**

By specifying `"live-restore": true` in the daemon config, we allow containers to continue running when the Docker daemon is not. This improves container uptime during updates of the host system and other stability issues.

**2.15 Ensure Userland Proxy is Disabled**

The `"userland-proxy": false` line fixes this warning. This disables the `docker-proxy` userland process that by default handles forwarding host ports to containers, and replaces it with `iptables` rules. If hairpin NAT is available, the userland proxy is not needed and should be disabled to reduce the attack surface of your host.

**2.18 Ensure containers are restricted from acquiring new privileges**

The `"no-new-privileges": true` line in the daemon config prevents privilege escalation from inside containers. This ensures that containers cannot gain new privileges using `setuid` or `setgid` binaries.

Now that we’ve updated the Docker daemon configuration, let’s fix the one remaining warning in section four of the audit.

## Step 4 — Enable Content Trust

The final test flagged by our audit is `4.5 Ensure Content trust for Docker is Enabled`. Content trust is a system for signing Docker images and verifying their signatures before running them. We can enable content trust with the `DOCKER_CONTENT_TRUST` environment variable.

To set this variable for your current shell session, type the following into the shell:

    export DOCKER_CONTENT_TRUST=1

Running the audit after this `export` command should show that Content trust has been enabled and clear this warning. To enable it automatically for all users and all sessions, add the `DOCKER_CONTENT_TRUST` variable to the `/etc/environment` file, which is a file for assigning system-wide environment variables:

    echo "DOCKER_CONTENT_TRUST=1" | sudo tee -a /etc/environment

More information about Docker Content trust can be found in [the official Docker Content trust documentation](https://docs.docker.com/engine/security/trust/content_trust/).

At this point, we’ve addressed all the warnings flagged by the Docker Bench for Security script. We now have a more secure Docker host to run containers on.

## Conclusion

In this tutorial we’ve installed the Docker Bench for Security script, used it to audit the security of our Docker installation, and addressed warnings by installing and configuring `auditd` and the Docker daemon’s configuration file.

After completing this tutorial, running the audit script should result in very few errors or warnings.You should also understand and have good reason for ignoring those that persist.

For more information about Docker security configuration options, please consult the [Docker documentation](https://docs.docker.com/) and take a look at the links to specific subsections of the documentation, which have been included throughout this tutorial.
