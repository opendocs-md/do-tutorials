---
author: Stephen Rees-Carter
date: 2016-07-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-ansible-on-ubuntu-16-04
---

# How to Install and Configure Ansible on Ubuntu 16.04

## Introduction

Configuration management systems are designed to make controlling large numbers of servers easy for administrators and operations teams. They allow you to control many different systems in an automated way from one central location.

While there are many popular configuration management systems available for Linux systems, such as Chef and Puppet, these are often more complex than many people want or need. **Ansible** is a great alternative to these options because it has a much smaller overhead to get started.

In this guide, we will discuss how to install Ansible on a Ubuntu 16.04 server and go over some basics of how to use the software.

## How Does Ansible Work?

Ansible works by configuring client machines from an computer with Ansible components installed and configured.

It communicates over normal SSH channels in order to retrieve information from remote machines, issue commands, and copy files. Because of this, an Ansible system does not require any additional software to be installed on the client computers.

This is one way that Ansible simplifies the administration of servers. Any server that has an SSH port exposed can be brought under Ansible’s configuration umbrella, regardless of what stage it is at in its life cycle.

Any computer that you can administer through SSH, you can also administer through Ansible.

Ansible takes on a modular approach, making it easy to extend to use the functionalities of the main system to deal with specific scenarios. Modules can be written in any language and communicate in standard JSON.

Configuration files are mainly written in the YAML data serialization format due to its expressive nature and its similarity to popular markup languages. Ansible can interact with clients through either command line tools or through its configuration scripts called Playbooks.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with a sudo non-root user and SSH keys, which you can set up by following [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including step 4

## Step 1 — Installing Ansible

To begin exploring Ansible as a means of managing our various servers, we need to install the Ansible software on at least one machine. We will be using an Ubuntu 16.04 server for this section.

The best way to get Ansible for Ubuntu is to add the project’s PPA (personal package archive) to your system. We can add the Ansible PPA by typing the following command:

    sudo apt-add-repository ppa:ansible/ansible

Press `ENTER` to accept the PPA addition.

Next, we need to refresh our system’s package index so that it is aware of the packages available in the PPA. Afterwards, we can install the software:

    sudo apt-get update
    sudo apt-get install ansible

As we mentioned above, Ansible primarily communicates with client computers through SSH. While it certainly has the ability to handle password-based SSH authentication, SSH keys help keep things simple. You can follow the tutorial linked in the prerequisites to set up SSH keys if you haven’t already.

We now have all of the software required to administer our servers through Ansible.

## Step 2 — Configuring Ansible Hosts

Ansible keeps track of all of the servers that it knows about through a “hosts” file. We need to set up this file first before we can begin to communicate with our other computers.

Open the file with root privileges like this:

    sudo nano /etc/ansible/hosts

You will see a file that has a lot of example configurations, none of which will actually work for us since these hosts are made up. So to start, let’s comment out all of the lines in this file by adding a “#” before each line.

We will keep these examples in the file to help us with configuration if we want to implement more complex scenarios in the future.

Once all of the lines are commented out, we can begin adding our actual hosts.

The hosts file is fairly flexible and can be configured in a few different ways. The syntax we are going to use though looks something like this:

Example hosts file

    [group_name]
    alias ansible_ssh_host=your_server_ip

The group\_name is an organizational tag that lets you refer to any servers listed under it with one word. The alias is just a name to refer to that server.

So in our scenario, we are imagining that we have three servers we are going to control with Ansible. These servers are accessible from the Ansible server by typing:

    ssh root@your_server_ip

You should not be prompted for a password if you have set this up correctly. We will assume that our servers’ IP addresses are `192.0.2.1`, `192.0.2.2`, and `192.0.2.3`. We will set this up so that we can refer to these individually as `host1`, `host2`, and `host3`, or as a group as `servers`.

This is the block that we should add to our hosts file to accomplish this:

    [servers]
    host1 ansible_ssh_host=192.0.2.1
    host2 ansible_ssh_host=192.0.2.2
    host3 ansible_ssh_host=192.0.2.3

Hosts can be in multiple groups and groups can configure parameters for all of their members. Let’s try this out now.

With our current settings, if we tried to connect to any of these hosts with Ansible, the command would fail (assuming you are not operating as the root user). This is because your SSH key is embedded for the root user on the remote systems and Ansible will by default try to connect as your current user. A connection attempt will get this error:

Ansible connection error

    host1 | UNREACHABLE! => {
        "changed": false,
        "msg": "Failed to connect to the host via ssh.",
        "unreachable": true
    }

On the Ansible server, we’re using a user called **demo**. Ansible will try to connect to each host with `ssh demo@server`. This will not work if the demo user is not on the remote system.

We can create a file that tells all of the servers in the “servers” group to connect using the root user.

To do this, we will create a directory in the Ansible configuration structure called `group_vars`. Within this folder, we can create YAML-formatted files for each group we want to configure:

    sudo mkdir /etc/ansible/group_vars
    sudo nano /etc/ansible/group_vars/servers

We can put our configuration in here. YAML files start with “—”, so make sure you don’t forget that part.

/etc/ansible/group\_vars/servers

    ---
    ansible_ssh_user: root

Save and close this file when you are finished.

If you want to specify configuration details for every server, regardless of group association, you can put those details in a file at `/etc/ansible/group_vars/all`. Individual hosts can be configured by creating files under a directory at `/etc/ansible/host_vars`.

## Step 3 — Using Simple Ansible Commands

Now that we have our hosts set up and enough configuration details to allow us to successfully connect to our hosts, we can try out our very first command.

Ping all of the servers you configured by typing:

    ansible -m ping all

Ping output

    host1 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    
    host3 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    
    host2 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }

This is a basic test to make sure that Ansible has a connection to all of its hosts.

The “all” means all hosts. We could just as easily specify a group:

    ansible -m ping servers

We could also specify an individual host:

    ansible -m ping host1

We can specify multiple hosts by separating them with colons:

    ansible -m ping host1:host2

The `-m ping` portion of the command is an instruction to Ansible to use the “ping” module. These are basically commands that you can run on your remote hosts. The ping module operates in many ways like the normal ping utility in Linux, but instead it checks for Ansible connectivity.

The ping module doesn’t really take any arguments, but we can try another command to see how that works. We pass arguments into a script by typing `-a`.

The “shell” module lets us send a terminal command to the remote host and retrieve the results. For instance, to find out the memory usage on our host1 machine, we could use:

    ansible -m shell -a 'free -m' host1

Shell output

    host1 | SUCCESS | rc=0 >>
                 total used free shared buffers cached
    Mem: 3954 227 3726 0 14 93
    -/+ buffers/cache: 119 3834
    Swap: 0 0 0

## Conclusion

By now, you should have your Ansible server configured to communicate with the servers that you would like to control. We have verified that Ansible can communicate with each host and we have used the `ansible` command to execute simple tasks remotely.

Although this is useful, we have not covered the most powerful feature of Ansible in this article: Playbooks. We have set up a great foundation for working with our servers through Ansible, but the heavy lifting will be done in a future article, when we cover how to use Playbooks to automate configuration of your remote computers.
