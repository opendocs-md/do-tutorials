---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/saltstack-infrastructure-installing-the-salt-master
---

# SaltStack Infrastructure: Installing the Salt Master

## Introduction

SaltStack, or Salt, is a powerful remote execution and configuration management system that can be used to easily manage infrastructure in a structured, repeatable way. In this series, we will be demonstrating one method of managing your development, staging, and production environments from a Salt deployment. We will use the Salt state system to write and apply repeatable actions. This will allow us to destroy any of our environments, safe in the knowledge that we can easily bring them back online in an identical state at a later time.

In this article, we’ll introduce the various environments we’ll be building out and we will install the Salt master daemon onto our primary server in order to get started. This is the core system that will house our configuration instructions, control our infrastructure nodes, and manage our requirements.

### Prerequisites

To complete this guide, you will need a clean Ubuntu 14.04 server. This server will need to have private networking enabled.

On this server, you should have a non-root account configured with `sudo` privileges. You can learn how to set up an account of this type in our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04).

A later article in this series will use the `salt-cloud` command to spin up infrastructure servers using the DigitalOcean cloud. You can use other cloud providers if you would like, or even virtual instances using software like vagrant. However, this is outside of the scope of this guide and you will have to do your own research in these areas.

## Overview of the Infrastructure We Will Build

The servers we spin up with `salt-cloud` will represent our three environments we want to maintain for application development. Because our Salt master server will maintain the configuration for each of the servers we need, we will be able to spin these servers down when we’re not using them. For instance, if your development team has halted work for the holidays, you can spin down your non-production environments. When you return from your break, you can easily rebuild them and redeploy your application on top of this fresh infrastructure.

We will break down our example infrastructure into development, staging, and production.

Our development infrastructure will be our most modest. It will simply contain a single web server and an associated database server. Decoupling the database and web server will be enough to ensure that our application is built with remote data in mind.

The staging environment will be more robust. Most advice that you’ll find recommends configuring your staging environment to be as similar to your intended production environment as possible. With this in mind, our staging environment will consist of two web servers in order to spread out the traffic load. We will distribute traffic between these two servers using a load balancer. On the database side, we will spin up two database servers. We will set up master-master replication between these two servers so that both can accept write requests. Master-master replication has some disadvantages, but it allows us to be a bit lazy in our application design (any database server can receive writes) and it allows us to demonstrate a fairly complex configuration management scenario.

As we stated before, the production environment will be very similar to the staging environment. The only difference in our design will be an additional load balancer up front to provide high availability and fail over. If you wish, you could also use higher capacity servers for your production load. This is often needed to adequately handle traffic requirements, even though it makes it more difficult to assess load in the staging environment.

Keep in mind that while we are creating configurations for the environments listed above, they do not all have to be running at the same time. This is especially true during testing. Throughout this series, you will likely only have a few servers active at any one time. This is desirable from a cost perspective, but destroying and bringing up our environments as needed also ensures that our environment bootstrapping is robust and repeatable.

Now that you know the general layout of the environments we will be configuring, we can get our Salt master up and running.

## Installing the Salt Master

Start by logging into the server you intend to set up as the Salt master as a non-root user with `sudo` privileges.

There are quite a [few different ways](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04) to install the Salt master daemon on a server. There are PPAs available for Ubuntu, but these can often be out-of-date. The best approach for planning and managing configuration management software is to target a specific version. This will allow you to update your systems (after thorough testing) in a planned and structured way instead of relying on whatever is available from a repository at the time of installation.

For this guide, we will be targeting Salt version [v2015.8.0](https://github.com/saltstack/salt/releases/tag/v2015.8.0), the latest stable version at the time of this writing. If you choose a different version or installation method, be aware that the processes in this guide may not work as written.

The easiest way to install a specific version is with SaltStack’s bootstrap script. Download the latest bootstrap script to your home directory by typing:

    cd ~
    curl -L https://bootstrap.saltstack.com -o install_salt.sh

Feel free to take a look at the contents of the downloaded script until you are comfortable with the operations it will perform.

When you are ready to install the Salt master, you can run the script with the `sh` shell. We will pass it the `-P` flag to indicate that we are okay with allowing dependency installations with `pip`, the Python package manager. We will also need to include the `-M` flag to indicate that we want to install the master daemon. Finish off the command by including `git v2015.8.0`, which tells the script to fetch the specified release tag from the [SaltStack GitHub repo](https://github.com/saltstack/salt) and use that for the installation:

    sudo sh install_salt.sh -P -M git v2015.8.0

The script will install all of the necessary dependencies, pull the version specified from the `git` repo, and install the Salt master and minion daemons, as well as some related Salt utilities.

The installation should be rather straight forward. Next, we can begin to configure our Salt master.

## Configure the Salt Master

The first thing we need to is to edit the main Salt master configuration file. Open it now with `sudo` privileges:

    sudo nano /etc/salt/master

The configuration file is fairly long and well-commented. You only need to uncomment and set options when you wish to deviate from the default values. We only need to make a few edits to start off.

First, find the `file_recv` option in the file. Enabling this allows Salt minions to send files to the Salt master. This is extremely helpful when creating states to get configuration files you wish to modify, however, it does come with some risk. We will enable it for the duration of this guide. You can disable it afterwards if you’d like:

/etc/salt/master

    file_recv: True

Next, we will need to set the `file_roots` dictionary. The Salt master includes a file server that it uses to store and serve files for the entire infrastructure. This includes the configuration management State files themselves, as well as any minion files that are managed by our system. This YAML dictionary defines the root of the file server, which will be located at `/srv/salt`. We need to specify that this is located under the “base” environment, the mandatory default environment for all Salt deployments:

/etc/salt/master

    file_roots:
      base:
        - /srv/salt

Note
It is important to replicate the formats given exactly. Salt uses YAML-style configuration files. YAML requires strict attention to spacing and indentation in order to ensure correct interpretation. Typically, each level of indentation will be two spaces.  

The last item that we need for now is the `pillar_roots` dictionary. The pillar system is used to store configuration data that can be restricted to certain nodes. This allows us to customize behavior and to prevent sensitive data from being seen by infrastructure components not associated with the data. This format mirrors the `file_roots` exactly. The location of our pillar data will be at `/srv/pillar`:

/etc/salt/master

    pillar_roots:
      base:
        - /srv/pillar

Save and close the file when you are finished.

We can go ahead and create the directories we referenced in the configuration file by typing:

    sudo mkdir -p /srv/{salt,pillar}

## Configure the Minion Daemon on the Salt Master

We want to also configure our Salt master server to accept Salt commands. We can do this by configuring the minion daemon on our server. Open the file to get started:

    sudo nano /etc/salt/minion

The only item we need to change here is the location of the master server. Since both daemons are operating on the same host, we can set the address to the local loopback interface:

/etc/salt/minion

    master: 127.0.0.1

Save and close the file when you are finished.

## Restart the Services and Accept the Salt Keys

Now that we have the Salt master and minion configuration in place, restart the services to pick up our changes:

    sudo restart salt-master
    sudo restart salt-minion

Before the Salt master can communicate securely with a minion (even on the same server), it must accept the minion’s key. This is a security feature. You can see all accepted and pending keys by typing:

    sudo salt-key --list all

If your daemons were configured correctly and were restarted, you should see a key for your Salt master server in the “Unaccepted Keys” section. In our case, our Salt master is being hosted on a machine called “sm”:

    OutputAccepted Keys:
    Denied Keys:
    Unaccepted Keys:
    sm
    Rejected Keys:

You can accept this key by passing the server’s minion ID (`sm` in this case`) to the`salt-key`command with the`-a` flag:

    sudo salt-key -a sm

If you check again, your key will have moved to the “Accepted Keys” section:

    sudo salt-key --list all

    OutputAccepted Keys:
    sm
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:

You can verify that your Salt master server now responds to Salt commands by typing:

    sudo salt '*' test.ping

You should get a response back that looks something like this:

    Outputsm:
        True

Your Salt master server is now up and running.

## Conclusion

In this guide, we got started managing our infrastructure by running through the initial configuration of our Salt master server. This is the central server within our management design which will be used both as a control center and as a repository of configuration data.

In the [next guide](saltstack-infrastructure-configuring-salt-cloud-to-spin-up-digitalocean-resources) in this series, we will configure our Salt master server with our DigitalOcean API credentials. We will create a provider configuration that allows us to connect to our DigitalOcean account using the `salt-cloud` command and create and manage cloud resources. We will create the profiles for our infrastructure machines so that we can define the properties for each of our servers.
