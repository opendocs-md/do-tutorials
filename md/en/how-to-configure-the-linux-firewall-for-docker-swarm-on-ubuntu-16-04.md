---
author: finid
date: 2017-01-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-the-linux-firewall-for-docker-swarm-on-ubuntu-16-04
---

# How to Configure the Linux Firewall for Docker Swarm on Ubuntu 16.04

## Introduction

[Docker Swarm](https://www.docker.com/products/docker-swarm) is a feature of Docker that makes it easy to run Docker hosts and containers at scale. A Docker Swarm, or Docker cluster, is made up of one or more Dockerized hosts that function as _manager_ nodes, and any number of _worker_ nodes. Setting up such a system requires careful manipulation of the Linux firewall.

The network ports required for a Docker Swarm to function correctly are:

- TCP port `2376` for secure Docker client communication. This port is required for Docker Machine to work. Docker Machine is used to orchestrate Docker hosts.
- TCP port `2377`. This port is used for communication between the nodes of a Docker Swarm or cluster. It only needs to be opened on manager nodes.
- TCP and UDP port `7946` for communication among nodes (container network discovery).
- UDP port `4789` for overlay network traffic (container ingress networking). 

**Note:** Aside from those ports, port `22` (for SSH traffic) and any other ports needed for specific services to run on the cluster have to be open.

In this article, you’ll learn how to configure the Linux firewall on Ubuntu 16.04 using the different firewall management applications available on all Linux distributions. Those firewall management applications are FirewallD, IPTables Tools, and UFW, the Uncomplicated Firewall. UFW is the default firewall application on Ubuntu distributions, including Ubuntu 16.04. While this tutorial covers three methods, each one delivers the same outcome, so you can choose the one you are most familiar with.

## Prerequisites

Before proceeding with this article, you should:

- Set up the hosts that make up your cluster, including at least one swarm manager and one swarm worker. You can follow the tutorial [How To Provision and Manage Remote Docker Hosts with Docker Machine on Ubuntu 16.04](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-16-04) to set these up.

**Note:** You’ll notice that the commands (and all the commands in this article) are not prefixed with `sudo`. That’s because it’s assumed that you’re logged into the server using the `docker-machine ssh` command after provisioning it using Docker Machine.

## Method 1 — Opening Docker Swarm Ports Using UFW

If you just set up your Docker hosts, UFW is already installed. You just need to enable and configure it. Follow [this guide](how-to-set-up-a-firewall-with-ufw-on-ubuntu-16-04) to learn more about using UFW on Ubuntu 16.04.

Execute the following commands on the nodes that will function as Swarm managers:

    ufw allow 22/tcp
    ufw allow 2376/tcp
    ufw allow 2377/tcp
    ufw allow 7946/tcp
    ufw allow 7946/udp
    ufw allow 4789/udp

Afterwards, reload UFW:

    ufw reload

If UFW isn’t enabled, do so with the following command:

    ufw enable

This might not be necessary, but it never hurts to restart the Docker daemon anytime you make changes to and restart the firewall:

    systemctl restart docker

Then on each node that will function as a worker, execute the following commands:

    ufw allow 22/tcp
    ufw allow 2376/tcp
    ufw allow 7946/tcp 
    ufw allow 7946/udp 
    ufw allow 4789/udp 

Afterwards, reload UFW:

    ufw reload

If UFW isn’t enabled, enable it:

    ufw enable

Then restart the Docker daemon:

    systemctl restart docker

That’s all you need to do to open the necessary ports for Docker Swarm using UFW.

## Method 2 — Opening Docker Swarm Ports Using FirewallD

FirewallD is the default firewall application on Fedora, CentOS and other Linux distributions that are based on them. But FirewallD is also available on other Linux distributions, including Ubuntu 16.04.

If you opt to use FirewallD instead of UFW, first uninstall UFW:

    apt-get purge ufw

Then install FirewallD:

    apt-get install firewalld

Verify that it’s running:

    systemctl status firewalld

If it’s not running, start it:

    systemctl start firewalld

Then enable it so that it starts on boot:

    systemctl enable firewalld

On the node that will be a Swarm manager, use the following commands to open the necessary ports:

    firewall-cmd --add-port=22/tcp --permanent
    firewall-cmd --add-port=2376/tcp --permanent
    firewall-cmd --add-port=2377/tcp --permanent
    firewall-cmd --add-port=7946/tcp --permanent
    firewall-cmd --add-port=7946/udp --permanent
    firewall-cmd --add-port=4789/udp --permanent

**Note** : If you make a mistake and need to remove an entry, type:  
`firewall-cmd --remove-port=port-number/tcp —permanent`.

Afterwards, reload the firewall:

    firewall-cmd --reload

Then restart Docker.

    systemctl restart docker

Then on each node that will function as a Swarm worker, execute the following commands:

    firewall-cmd --add-port=22/tcp --permanent
    firewall-cmd --add-port=2376/tcp --permanent
    firewall-cmd --add-port=7946/tcp --permanent
    firewall-cmd --add-port=7946/udp --permanent
    firewall-cmd --add-port=4789/udp --permanent

Afterwards, reload the firewall:

    firewall-cmd --reload

Then restart Docker.

    systemctl restart docker

You’ve successfully used FirewallD to open the necessary ports for Docker Swarm.

## Method 3 — Opening Docker Swarm Ports Using IPTables

To use IPtables on any Linux distribution, you’ll have to first uninstall any other firewall utilities. If you’re switching from FirewallD or UFW, first uninstall them.

Then install the `iptables-persistent` package, which manages the automatic loading of IPtables rules:

    apt-get install iptables-persistent

Next, flush any existing rules using this command:

    netfilter-persistent flush

Now you can add rules using the `iptables` utility. This first set of command should be executed on the nodes that will serve as Swarm managers.

    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 2376 -j ACCEPT
    iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
    iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
    iptables -A INPUT -p udp --dport 7946 -j ACCEPT
    iptables -A INPUT -p udp --dport 4789 -j ACCEPT

After you enter all of the commands, save the rules to disk:

    netfilter-persistent save

Then restart Docker.

    sudo systemctl restart docker

On the nodes that will function as Swarm workers, execute these commands:

    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 2376 -j ACCEPT
    iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
    iptables -A INPUT -p udp --dport 7946 -j ACCEPT
    iptables -A INPUT -p udp --dport 4789 -j ACCEPT

Save these new rules to disk:

    netfilter-persistent save

Then restart Docker:

    sudo systemctl restart docker

That’s all it takes to open the necessary ports for Docker Swarm using IPTables. You can learn more about how these rules work in the tutorial [How the Iptables Firewall Works](how-the-iptables-firewall-works).

If you wish to switch to FirewallD or UFW after using this method, the proper way to go about it is to first stop the firewall:

    sudo netfilter-persistent stop

Then flush the rules:

    sudo netfilter-persistent flush

Finally, save the now empty tables to disk:

    sudo netfilter-persistent save

Then you can switch to UFW or FirewallD.

## Conclusion

FirewallD, IPTables Tools and UFW are the three firewall management applications in the Linux world. You just learned how to use each to open the network ports needed to set up Docker Swarm. Which method you use is just a matter of personal preference, as they are all equally capable.
