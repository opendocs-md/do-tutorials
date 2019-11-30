---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04
---

# How To Install and Configure Salt Master and Minion Servers on Ubuntu 14.04

## Introduction

SaltStack is a powerful, flexible, high performing configuration management and remote execution system. It can be used manage your infrastructure from a centralized location while minimizing manual maintenance steps. To learn more about some of the terminologies and tools involved with SaltStack, check out [this guide](an-introduction-to-saltstack-terminology-and-concepts).

In this article, we will focus on getting a Salt master server set up to manage your infrastructure. We will also demonstrate how to install the Salt minion daemon on other computers in order to manage them with Salt. We will be using two Ubuntu 14.04 servers to demonstrate these steps.

## Prerequisites

To get started, you should have at least two Ubuntu 14.04 server instances. These should have a non-root user configured with `sudo` privileges. You can learn how to create and configure these users by following our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04).

When you are ready to get started, log into the server you want to use as the Salt master with your `sudo` user. We will configure this machine first.

## Install the Master Daemon

The Salt master daemon can be installed in a number of ways on Ubuntu 14.04. The following is a brief rundown of the advantages and disadvantages of each method:

- **Ubuntu SaltStack PPA** : Uses the Ubuntu native package management tools to install and update the required software. This is the easiest method of install but, as is the case at the time of this writing, the packages can be significantly out-of-date.
- **Salt-Bootstrap** : This bootstrapping script attempts to provide a more universal method for installing and configuring Salt. It can attempt to use the native software tools available, which means that it may still try to install from the PPA above. It also provides easy access to the development versions of Salt.

Below, we will outline how to install using the Ubuntu PPA method. We will also provide instructions on how to use the `salt-bootstrap` script to install both the stable and the development versions of Salt master.

It is up to you to decide which option suits your needs best. If you run into issues, there might be bug fixes available in the development version. However, there is also a chance of running into newly released bugs.

### Install the Stable Version from the Official PPA

Installing from the Ubuntu PPA is the most straight forward installation method.

To get started, you will need to add the SaltStack PPA to the server you will use as your master. You can do this by typing:

    sudo add-apt-repository ppa:saltstack/salt

Once you have confirmed the PPA addition, it will be added to your system. To index the new packages available within, you will need to update your local package index. Afterwards, you can install the relevant software:

    sudo apt-get update
    sudo apt-get install salt-master salt-minion salt-ssh salt-cloud salt-doc

In the above command, we installed both the Salt master and minion daemons. This will allow us to control our master server with Salt as well. We also installed `salt-ssh` and `salt-cloud`, which give us more flexibility in how we connect to and control resources. We’ve included the documentation package as well.

At this point, you are done with the Salt master installation. Skip down to the [initial master configuration section](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04#initial-master-configuration) to get your new services up and running.

### Install the Stable Version Using Salt-Bootstrap

An alternative to using the PPA directly is to install the stable version using the `salt-bootstrap` script. This is available for download from the SaltStack website. One reason you may choose to use this method of installing the stable system over the above method is that it grabs some of its dependencies from the `pip` package manager. This may give you more up-to-date versions of some of the Salt dependencies.

To get started, move to your home directory or somewhere else where you have write permissions. We can use `curl` to download the bootstrap script. We will be following the instructions found on the [`salt-bootstrap` GitHub page](https://github.com/saltstack/salt-bootstrap) and will use the output name they selected for clarity:

    cd ~
    curl -L https://bootstrap.saltstack.com -o install_salt.sh

At this point, take a look at the script to make sure that it is not doing anything that you do not approve of:

    less ~/install_salt.sh

The `salt-bootstrap` script is maintained by the SaltStack team, but you should always check the contents of external scripts before running them.

When you are satisfied with the actions that will be taken, run the script by passing it to `sh`. We will use the `-P` flag so that the script can use `pip` as a dependency source, as necessary. Without this flag, the installation will likely fail. We also need to include the `-M` flag so that the Salt master daemon is installed. All of the Salt helper utilities will be automatically included.

The full command we need is:

    sudo sh install_salt.sh -P -M

At this point, you are done with the Salt master installation. Skip down to the [initial master configuration section](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04#initial-master-configuration) to get your new services up and running.

### Install the Development Version Using Salt-Bootstrap

We can also use the `salt-bootstrap` script to install a development version of Salt using `git`. This can be helpful to get access to newer features and, more importantly, to get access to more recent bug fixes that might not be available in the PPA version of the software.

The script needed is the same `salt-bootstrap` script we used above. Only the options we use will be different. With this in mind, if you don’t have the script already, download it to your home directory:

    cd ~
    curl -L https://bootstrap.saltstack.com -o install_salt.sh

Again, take a look at the script to ensure that you are okay with the operations that it will perform:

    less ~/install_salt.sh

When you are satisfied, you can pass the script to `sh` to execute it. We will include the `-P` flag to tell the script to get dependencies with `pip` if necessary. The `-M` flag is included to specify that we wish to install the Salt master. We will end the command with `git develop` to tell the script that we want to use the [SaltStack GitHub repo](https://github.com/saltstack/salt) to install the most recent development version instead of the Ubuntu PPA.

The full command we need is:

    sudo sh install_salt.sh -P -M git develop

At this point, you are done with the Salt master installation. Next, we will configure the master in order to get the new services up and running.

## Initial Master Configuration

Next, we need to configure the Salt master.

### Create the Salt Directory Structures

First, we will create the configuration management directory structure where the Salt master will look for various files. These are all under the `/srv` directory by default. We need `/srv/salt` and `/srv/pillar` to get started. Create them now by typing:

    sudo mkdir -p /srv/{salt,pillar}

### Modify the Salt Master Configuration

Next, we will adjust the Salt master configuration file. Open the file with `sudo` privileges in your text editor:

    sudo nano /etc/salt/master

The first thing we will do is set the `file_roots` dictionary. This basically specifies the locations where the Salt master will look for configuration management instructions. The `base` specifies the default environment. Two of the directories we created earlier will be used for this purpose. The `/srv/salt` will be used for administrator-created instructions, and the `/srv/formulas` will be set aside for pre-packaged configurations downloaded from external sources:

/etc/salt/master

    file_roots:
      base:
        - /srv/salt
        - /srv/formulas

Note
It is important to replicate the formats given exactly. Salt uses YAML-style configuration files. These require strict attention to spacing and indentation for the daemon to correctly interpret the values.  

Next, we will will set up the root directory for our Salt pillar configuration. This looks very similar to the above configuration and uses the third directory we created:

/etc/salt/master

    pillar_roots:
      base:
        - /srv/pillar

This is all we need to configure for the master at this time. Save and close the file when you are finished.

### Modify the Salt Minion Configuration

We also installed the Salt minion daemon on this machine so that we can keep it in line with the rest of our infrastructure policies. Open the Salt minion configuration with `sudo` privileges next:

    sudo nano /etc/salt/minion

The only change we need to make is to specify the master that this minion should connect to. In this case, the minion should connect to the master process running on the same machine. Set the `master` key equal to the local loopback address `127.0.0.1` in order for the minion to correctly connect:

/etc/salt/minion

    master: 127.0.0.1

Save and close the file when you are finished.

### Restart the Processes

Now, we need to restart both the Salt master and minion daemons in order to use our new configurations:

    sudo restart salt-master
    sudo restart salt-minion

Both of the daemons will restart, taking into account the configuration changes we’ve outlined.

### Accept the Minion Key

Following the reboot, the Salt minion daemon automatically contacted the Salt master with its credentials. As an administrator, you simple need to verify and accept the minion’s key to allow communication.

Start by listing all of the keys that the Salt master has knowledge of:

    sudo salt-key --list all

You should see something like this. The `saltmaster` below should match the Salt minion ID of your system. This is typically the hostname of your server:

    OutputAccepted Keys:
    Denied Keys:
    Unaccepted Keys:
    saltmaster
    Rejected Keys:

As you can see, our Salt minion has sent its key to the master, but it has not been accepted yet. For security purposes, before accepting the key, we will run two commands.

We need to make sure the output of this (which tells us the fingerprint of the key the Salt minion generated):

    sudo salt-call key.finger --local

    Outputlocal:
        24:c8:77:1d:ed:10:d7:b0:3e:bc:bc:ed:41:e1:5a:d1

Matches the fingerprint found here (the fingerprint of the key that the Salt master is being asked to accept). Substitute the minion ID here:

    sudo salt-key -f saltmaster

    OutputUnaccepted Keys:
    saltmaster: 24:c8:77:1d:ed:10:d7:b0:3e:bc:bc:ed:41:e1:5a:d1

Once you verify that those values are the same, you can accept the key by typing:

    sudo salt-key -a saltmaster

After accepting the key, you can see that the key has been moved to the “Accepted Keys” section:

    sudo salt-key --list all

    OutputAccepted Keys:
    saltmaster
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:

Now, you can test that the Salt master and minion processes are communicating correctly by typing:

    sudo salt '*' test.ping

You should receive a message back indicating that the health check was successful:

    Outputsaltmaster:
        True

Your Salt master server is now configured. We can move onto demonstrating how to set up an additional Salt minion server.

## Install a Separate Minion

Now that we have our Salt master server up and running smoothly, we can demonstrate how to bring a new server under Salt’s control as a minion.

Again, we have multiple ways of installing the necessary software, but **you should match the method used for the master server**. This will ensure that you do not have a version mismatch between Salt master and minion. Salt minions that are more up-to-date than their master server may exhibit unpredictable behavior.

When you are ready, log into your second server with your `sudo` user.

### Install the Stable Master from the Official PPA

If you installed your Salt master server from the SaltStack PPA, you can add the same PPA on your Ubuntu minion server:

    sudo add-apt-repository ppa:saltstack/salt

This time, we only need to install the `salt-minion` executable. Update your local package index after adding the PPA and install the software by typing:

    sudo apt-get update
    sudo apt-get install salt-minion

Your Salt minion should now be installed. Skip ahead to the section on [configuring your minion](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04#configure-the-minion).

### Install the Stable Version Using Salt-Bootstrap

If you installed the stable version using `salt-bootstrap`, you can download the same script to your minion machine:

    cd ~
    curl -L https://bootstrap.saltstack.com -o install_salt.sh

We will call the script in almost the same way that we did on the Salt master. The only difference is that we leave out the `-M` flag, since we do not need to install the master tools and daemons:

    sudo sh install_salt.sh -P

Your Salt minion should now be installed. Skip ahead to the section on [configuring your minion](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04#configure-the-minion).

### Install the Development Version Using Salt-Bootstrap

If you installed the current development version on the Salt master using `salt-bootstrap`, you can install the companion minion process using the same script. Download it to your minion by typing:

    cd ~
    curl -L https://bootstrap.saltstack.com -o install_salt.sh

The command we need to install the minion is almost the same as what we used on the master. The only difference is that we are leaving off the `-M` flag to indicate that we do not need the Salt master tools and daemon:

    sudo sh install_salt.sh -P git develop

When you are finished, continue ahead to configure your minion instance.

## Configure the Minion

Now that we have the minion installed, we can go ahead and configure it to communicate with our Salt master.

### Get the Salt Master Public Key Fingerprint

Before we begin, we should grab the Salt master’s key fingerprint. We can add this to our minion configuration for increased security.

On your Salt master server, type:

    sudo salt-key -F master

The output should look something like this:

    OutputLocal Keys:
    master.pem: 12:db:25:3d:7f:00:a3:ed:20:55:94:ca:18:f8:67:97
    master.pub: 7b:97:23:4b:a4:6d:16:31:2d:c9:e3:81:e2:d5:32:92
    Accepted Keys:
    saltmaster: 24:c8:77:1d:ed:10:d7:b0:3e:bc:bc:ed:41:e1:5a:d1

The value of the `master.pub` key, located under the “Local Keys” section is the fingerprint we are looking for. Copy this value to use in our Minion configuration.

### Modify the Minion Configuration

Back on your new Salt minion, open the minion configuration file with `sudo` privileges:

    sudo nano /etc/salt/minion

We need to specify the location where the Salt master can be found. This can either be a resolvable DNS domain name or an IP address:

/etc/salt/minion

    master: ip_of_salt_master

Next, set the `master_finger` option to the fingerprint value you copied from the Salt master a moment ago:

/etc/salt/minion

    master_finger: '7b:97:23:4b:a4:6d:16:31:2d:c9:e3:81:e2:d5:32:92'

Save and close the file when you are finished.

Now, restart the Salt minion daemon to implement your new configuration changes:

    sudo restart salt-minion

The new minion should contact the Salt master service at the provided address. It will then send its key for the master to accept. In order to securely verify the key, need to check the key fingerprint on the new minion server.

To do this, type:

    sudo salt-call key.finger --local

You should see output that looks like this:

    Outputlocal:
        32:2a:7c:9a:f2:0c:d1:db:84:df:d3:82:00:d5:8f:be

You will need to verify that the key fingerprint that the master server received matches this value.

### Accept the Minion Key on the Salt Master

Back on your Salt master server, we need to accept the key.

First, verify that we have an unaccepted key waiting on the master:

    sudo salt-key --list all

You should see a new key in the “Unaccepted Keys” section that is associated with your new minion:

    OutputAccepted Keys:
    saltmaster
    Denied Keys:
    Unaccepted Keys:
    saltminion
    Rejected Keys:

Check the fingerprint of the new key. Modify the highlighted portion below with the minion ID that you see in the “Unaccepted Keys” section:

    sudo salt-key -f saltminion

The output should look something like this:

    OutputUnaccepted Keys:
    saltminion: 32:2a:7c:9a:f2:0c:d1:db:84:df:d3:82:00:d5:8f:be

If this matches the value you received from the minion when issuing the `salt-call` command, you can safely accept the key by typing:

    sudo salt-key -a saltminion

The key should now be added to the “Accepted Keys” section:

    sudo salt-key --list all

    OutputAccepted Keys:
    saltmaster
    saltminion
    Denied Keys:
    Unaccepted Keys:
    Rejected Keys:

Test that you can send commands to your new minion by typing:

    sudo salt '*' test.ping

You should receive back answers from both of the minion daemons you’ve configured:

    Outputsaltminion:
        True
    saltmaster:
        True

## Conclusion

You should now have a Salt master server configured to control your infrastructure. We’ve also walked through the process of setting up a new minion server. You can follow this same procedure for additional Salt minions. These are the basic skills you need to set up new infrastructure for Salt management.
