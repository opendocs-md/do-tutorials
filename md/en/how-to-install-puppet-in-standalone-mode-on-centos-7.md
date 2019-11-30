---
author: Ross Williams
date: 2014-09-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-puppet-in-standalone-mode-on-centos-7
---

# How To Install Puppet In Standalone Mode on CentOS 7

## Introduction

The goal of this tutorial is to get Puppet up and running in standalone mode on CentOS 7 as quickly as possible.

If you want to learn a bit about Puppet and how it might be useful to you, keep reading. If you’re already convinced, and want to start installing Puppet, skip to the section [Conventions Used In This Tutorial](how-to-install-puppet-in-standalone-mode-on-centos-7#conventions-used-in-this-tutorial) below.

## Why Use Puppet?

### What’s Puppet?

Puppet is an open source configuration management software tool that allows organizations to control the exact configuration of as many as tens of thousands of nodes from a single central server. Puppet is mature and popular, and is in use by large organisations around the world. However, installing Puppet under this distributed client/server model can be complicated, requiring the setup of a central Puppet server, and its relationship to client nodes.

Puppet has such a strong image as a mass cloud configuration tool, that it might surprise you to know that Puppet can also be run in “standalone” mode in which it is manually run to configure a single node. In standalone mode, Puppet is an excellent tool for configuring individual nodes.

If you have been configuring your DigitalOcean Droplets manually (i.e. by SSHing into the cloud server and typing a series of commands into the Linux command shell), then Puppet can assist you to embed all the knowledge of that configuration process into a single Puppet configuration file (or directory tree) that can be invoked to recreate the node from scratch, or reconfigure the node if it becomes damaged.

Puppet is not just a glorified installation script manager. When Puppet runs, it inspects the configuration of the node, identifies any differences between the configuration of the node and the configuration specified in the Puppet configuration file, and then makes the changes necessary to bring the node into the specified state. This means that it can be used both to configure nodes and repair them.

### Why Use A Configuration Management Tool?

We can identify three levels of sophistication in installing software: manual, scripted, and configuration management based.

- In a _manual installation_, you SSH into the node and issue a series of commands  
to the command shell to install the software.

- In a _scripted installation_, you create a script (e.g. a Ruby script or BASH script)  
to install the software and execute it.

- In a _configuration management based installation_, you create a configuration  
management tool specification of the desired state of the node, and the configuration tool compares the node’s state with the desired state, and drives the node into the desired state.

Manual installation should be avoided because it is a pre-automation solution that embeds all the installation knowledge in the head of one or more engineers rather than into a file (unless the engineers have written down the installation procedure).

Scripted installation is far better than manual installation, but suffers from the problem that if you perform an installation and then damage some small part of it, you cannot use the script to repair the damage; you have to start again from scratch and reinstall everything.

Configuration management based installation is the best solution. A configuration management tool will automate installation (as will an installation script), but it can also be used to repair the software if it gets damaged. It can also be used to change the desired configuration, and drive the node to the new desired state.

### Why Use Puppet In Particular?

As of August 2014, there appears to be two main configuration tools on the market: Puppet and Chef. A quick search reveals that both seem to be sound mature tools with loyal followings. One key difference is that Puppet is more declarative, and Chef is more procedural, which makes Puppet more attractive for damage repair. Here are some comparison articles.

- [http://www.scriptrock.com/blog/puppet-vs-chef-battle-wages](http://www.scriptrock.com/blog/puppet-vs-chef-battle-wages)
- [http://www.infoworld.com/d/data-center/puppet-or-chef-the-configuration-management-dilemma-215279](http://www.infoworld.com/d/data-center/puppet-or-chef-the-configuration-management-dilemma-215279)

This tutorial does not seek to make a comprehensive comparison.

### Snowflakes, Pets, and Cattle

A metaphor has arisen in the software configuration world to describe three levels  
of sophistication of server configuration management. You can be at the snowflake  
level, the pet level, or the cattle level. Here’s how it works:

- Your node is a **snowflake** if you do not know how it came to be in the state  
it is in and/or you are too nervous to make any changes to it, or even touch  
it in case it breaks. If it does break, you’re in real trouble. You node is  
like a delicate snowflake.

- Your node is a **pet** if you are confident that you could fix it if it breaks,  
but the thought of configuring it from scratch fills you with dread. When your  
pet gets sick, you take it to the vet to heal it.

- Your node is a **head of cattle** if configuring it has been so automated that, if  
something goes wrong with the node, it’s easier to reconfigure it from scratch  
using your automated configuration tool than it is to attempt to repair it. When  
one of your cattle gets sick, you don’t take it to the vet; you shoot it in the  
head and get a new one.

The purpose of the metaphor is to convey the “cattle” perspective of node management. Most system administrators are so used to treating nodes as snowflakes or pets that the idea of just killing a node when it becomes damaged seems quite alien. However, all it takes is a few seconds of thought to change one’s perspective and realise how powerful the cattle model is.

- The file system has become damaged? No problem, just kill the node and recreate it from scratch using Puppet.

- An obscure piece of software has suddenly stopped working? No problem, just kill the node and recreate it from scratch using Puppet.

- A hacker has penetrated your system and installed a root kit? No problem, just kill the node and recreate it from scratch using Puppet.

Treating your nodes like cattle can be a crutch. Ultimately, it’s best to find the source of whatever is damaging your node and fix the real problem, but in the meantime, it is very effective to just automatically rebuild.

Of the three installation levels, scripted and configuration management installations both support the cattle model. However, the configuration management model supports the pet model as well. Under the scripted model, if you want to install additional software, you have to start from scratch. Under the configuration management model, you can modify your existing node.

Puppet allows you to move from the snowflake model to the cattle model, with the option of treating your cattle as pets when convenient.

(Note: The author is not comfortable with treating any animals like cattle, but the cattle metaphor does work well as a configuration metaphor.)

### The Puppet Way

The Puppet Way to configure nodes is to configure everything from within Puppet. This can be somewhat challenging at times, but it’s almost always possible to configure whatever you want from within Puppet.

If you make a commitment to configure everything from within Puppet, then you can configure any node in your cloud with a single Puppet command, and if you can do that, you can start to treat the nodes in your cloud like cattle. You can move so far away from the snowflake mentality that you can adopt a policy of regularly picking a random node in your cloud and tearing it down and rebuilding it using Puppet, just to prove to yourself that it hasn’t somehow become a snowflake or a pet.

Once you have embodied all your configuration information into Puppet, the only thing stopping you from treating a node like a head of cattle is if it contains a database. You have to save the database before tearing down the node, and restore it after you have rebuilt the node, but that’s about the only reason.

Puppet is not just a configuration tool. It is a devops discipline that streamlines node installation, management, and repair, and which eliminates much of the stress of managing a cloud of nodes.

## Conventions Used In This Tutorial

For the purpose of this tutorial, a Droplet named:

    mynode.example.com

will be used. Whenever you see the word “mynode” or “example” in this tutorial, you can be sure that they are not command keywords, and that you must substitute your own name.

Unless otherwise specified, whenever this tutorial says to issue a command, it means to issue it within the command shell (e.g. bash) of your Droplet.

This tutorial assumes that you are logged in as root, so you don’t have to prefix every command with `sudo`. If you are not logged in as root, you could try prefixing all of the following commands with `sudo` (but this has not been tested).

Throughout this tutorial, we use the `cat` command to create and modify files. You are welcome to use `nano` or another text editor if desired.

## Create A Droplet

If you have not already created the Droplet to which you wish to apply Puppet, do so now. You can create any kind of Droplet so long as it is a CentOS 7 Droplet.

When you specify the hostname of your new Droplet on the DigitalOcean Droplet creation form, be sure to specify the fully-qualified domain name (FQDN) in the Hostname form field.

    Hostname = mynode.example.com

Don’t specify just “mynode”.

(You don’t need to configure `example.com`’s DNS for the new node `mynode` to be able to run Puppet, but it’s a good idea to do this anyway if you plan to keep the Droplet, so this is your reminder!)

## SSH Into Your Droplet As Root

SSH into the new Droplet as root from the command line of the computer you work from using the following command.

    ssh root@mynode.example.com

If you haven’t configured DNS to point a domain name to the node, you will need to use the node’s IP address instead.

    ssh root@xxx.xxx.xxx.xxx

## Install Puppet

The next step is to install Puppet. Puppet Labs ships Puppet in a free, open source release and separately as an enterprise release. In this tutorial, we will be installing the open source release, which is completely free for any number of nodes.

The Linux installation software `yum` makes installing Puppet easy. The only difficulty is that Puppet is not in the CentOS yum repository list by default, so we have to install that first before we can invoke `yum`. (If you have CentOS 5 or CentOS 6, change the 7 to a 5 or 6).

    rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm

You can confirm that the Puppet repository has been installed with the following command:

    yum repolist | grep puppet

which should yield output looking something like this:

    puppetlabs-deps/x86_64 Puppet Labs Dependencies El 7 - x86_64 10
    puppetlabs-products/x86_64 Puppet Labs Products El 7 - x86_64 70

Now install Puppet using yum. The `yes` command (piped in to the `yum` command using |) eliminates the need for you to answer a series of questions from yum. The command causes a lot of activity and should yield 180+ lines of console output.

    yes | yum -y install puppet

Test that Puppet is installed and working with the following command. The output should be just a simple version number such as `3.6.2`.

    puppet --version

## Set Hostname and FQDN

Puppet won’t run properly if the node’s hostname and Fully Qualified Domain Name (FQDN) settings are not properly configured. This is because Puppet is often configured with one configuration file that specifies the configuration of several different nodes. Puppet needs to know which node it is running on so that it can execute only the relevant parts of the configuration file.

To see whether your node is correctly configured for Puppet, execute the following two commands:

    facter | grep hostname
    facter | grep fqdn

On its own the `facter` command will display a list of key/value pairs with data about your Droplet. Only two of the key/value pairs are important here, so we’re using `grep` to search for the relevant output, which should look like this:

    hostname=mynode
    fqdn=mynode.example.com

If the **mynode** parts of the values are incorrect, you can fix this by  
giving the following command. This will change the **mynode** part of the  
value in both pairs:

    hostname mynode

If the domain value in **fqdn** is incorrect, you can fix it by appending a single  
line to the system configuration file `/etc/resolv.conf`. First take a quick look at it (useful if you damage it by accident and want to recreate it without recreating the Droplet):

    cat /etc/resolv.conf

Now append to it:

    cat >>/etc/resolv.conf
    domain example.com
    ^D

(where **^D** means to type Control-D to terminate the input to the `cat` command.)

Confirm that your changes worked with:

    facter | grep hostname
    facter | grep fqdn

Here’s a reminder of what the output should contain:

    hostname=mynode
    fqdn=mynode.example.com

## Create A Puppet Configuration File

Now that Puppet is installed and ready to run, it’s time to create a Puppet configuration. The CentOS/Puppet installation process should already have created a directory called `/etc/puppet` (If it hasn’t, create it with `mkdir /etc/puppet`). Let’s take a look there:

    ls -la /etc/puppet

There should be a few `.conf` files and a `modules` subdirectory.

Puppet configuration directory tree naming conventions direct us to create a `manifests` subdirectory to hold the actual configuration file that we’re about to create:

    mkdir /etc/puppet/manifests

Now create the configuration file. You will need to substitute your own domain name for `mynode.example.com`. The `cat` command is used, but you can use the `nano` editor (or any other editor) if you like. (Leading and trailing blank lines are ignored).

    cat >/etc/puppet/manifests/projectname.pp
    
    node "mynode.example.com" {
    
    file { '/root/example_file.txt':
        ensure => "file",
        owner => "root",
        group => "root",
        mode => "700",
        content => "Congratulations!
    Puppet has created this file.
    ",}
    
    } # End node mynode.example.com
    ^D

( **^D** means to type Control-D to terminate the input to the `cat` command.)

The configuration file specifies the configuration of node `mynode.example.com`. (You could add more construct blocks like `node "nodename" {...}` to this file and it would still run on node `mynode.example.com`).

Inside the `node` construct is an instruction to configure a particular file called `/root/example_file.txt`. The `file` construct instructs Puppet to ensure that there is a file at that name, that the file is a file and not a directory, that it has the specified ownership, that it has the specified protection mode, and that it has the specified content.

The `file` instruction is not simply a command to create the file if it does not exist. Rather, it is a specification of how the file should be configured. Puppet inspects the file and drives it into the specified state, regardless of the state it is in. If the file does not exist, Puppet creates it. If it does exist, but any of the specified aspects of it are incorrect (including the file content), Puppet will correct the deviation and drive the file into the specified state. So while Puppet might seem to fulfil the role of an installation script the first time it is run, on both first and subsequent runs, it is really comparing the existing state to the desired state and making changes to drive the file system into the desired state.

## Invoke Puppet

Now that you have installed Puppet and created a configuration file, you can invoke Puppet. (Ignore any ipaddress errors).

    puppet apply /etc/puppet/manifests/projectname.pp

Puppet should create the file `/root/example_file.txt` owned by `root`, in the `root` group, and with `-rwx------` permissions. Check this with:

    ls -la /root

Check the contents of the file with:

    cat /root/example_file.txt

You should see the text we specified in the configuration file.

## Invoke Puppet Again

Remember that Puppet does not execute your configuration file as a script.  
Instead it drives your system into the state specified in the configuration  
file. That means that if you run Puppet again, it should do nothing. Try it!

    puppet apply /etc/puppet/manifests/projectname.pp

## Damage The File And Invoke Puppet Again

Now let’s do some damage to the configured file by changing its protections  
using the `chmod` command.

    chmod o+r /root/example_file.txt

Check the damage with the following command. You should see `-rwx---r--`  
protection for `example_file.txt` instead of `-rwx------` protection:

    ls -la /root

Now invoke Puppet again:

    puppet apply /etc/puppet/manifests/projectname.pp

Puppet should repair the file’s protection. Check it with:

    ls -la /root

## More Damage And Repair

Now let’s damage the file again by changing its contents:

    cat >/root/example_file.txt
    This is a damaged file!
    ^D

Confirm the damage using:

    cat /root/example_file.txt

Invoke Puppet again. It should repair the file:

    puppet apply /etc/puppet/manifests/projectname.pp

Confirm that the file has been repaired with:

    cat /root/example_file.txt

## What Next?

This is just a “Hello World” example to get you started. The configuration file above is just a tiny example of what Puppet can do. For a taste of what’s ahead, take a quick look at this page:

- [https://docs.puppetlabs.com/references/latest/type.html](https://docs.puppetlabs.com/references/latest/type.html)

You can specify the configuration of individual files, entire directory trees, packages, services, cron, users, groups, and much more. There is also a huge Puppet-user-created library of configuration modules at:

- [https://forge.puppetlabs.com/](https://forge.puppetlabs.com/)

## Conclusion

This tutorial has shown you how to install Puppet in standalone mode, and how to create a Puppet configuration file to configure a single file in a single node. This configuration file can act as a platform upon which you can build a more complicated configuration. If you adhere to the discipline of doing all your configuration using Puppet, you will be able to convert your Droplets from snowflakes (or pets) to cattle, thus making your cloud management tasks quick and repeatable.

### References

The company behind Puppet is called Puppet Labs, Inc. and can be found here:

- [http://puppetlabs.com/](http://puppetlabs.com/)

Puppet installation instructions can be found at:

- [https://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html](https://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html)

You can get a taste of what Puppet is capable of configuring by browsing this page:

- [https://docs.puppetlabs.com/references/latest/type.html](https://docs.puppetlabs.com/references/latest/type.html)

The Puppet user community has created thousands of Puppet modules, which can be  
used to configure a wide range of software:

- [https://forge.puppetlabs.com/](https://forge.puppetlabs.com/)
