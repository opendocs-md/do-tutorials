---
author: Mitchell Anicas
date: 2015-08-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/what-is-a-firewall-and-how-does-it-work
---

# What is a Firewall and How Does It Work?

## Introduction

A firewall is a system that provides network security by filtering incoming and outgoing network traffic based on a set of user-defined rules. In general, the purpose of a firewall is to reduce or eliminate the occurrence of unwanted network communications while allowing all legitimate communication to flow freely. In most server infrastructures, firewalls provide an essential layer of security that, combined with other measures, prevent attackers from accessing your servers in malicious ways.

This guide will discuss how firewalls work, with a focus on **stateful** software firewalls, such as iptables and FirewallD, as they relate to cloud servers. We’ll start with a brief explanation of TCP packets and the different types of firewalls. Then we’ll discuss a variety of topics that a relevant to stateful firewalls. Lastly, we will provide links to other tutorials that will help you set up a firewall on your own server.

## TCP Network Packets

Before discussing the different types of firewalls, let’s take a quick look at what Transport Control Protocol (TCP) network traffic looks like.

TCP network traffic moves around a network in **packets** , which are containers that consist of a packet header—this contains control information such as source and destination addresses, and packet sequence information—and the data (also known as a payload). While the control information in each packet helps to ensure that its associated data gets delivered properly, the elements it contains also provides firewalls a variety of ways to match packets against firewall rules.

It is important to note that successfully receiving incoming TCP packets requires the receiver to send outgoing acknowledgment packets back to the sender. The combination of the control information in the incoming and outgoing packets can be used to determine the connection state (e.g. new, established, related) of between the sender and receiver.

## Types of Firewalls

Let’s quickly discuss the three basic types of network firewalls: packet filtering (stateless), stateful, and application layer.

Packet filtering, or stateless, firewalls work by inspecting individual packets in isolation. As such, they are unaware of connection state and can only allow or deny packets based on individual packet headers.

Stateful firewalls are able to determine the connection state of packets, which makes them much more flexible than stateless firewalls. They work by collecting related packets until the connection state can be determined before any firewall rules are applied to the traffic.

Application firewalls go one step further by analyzing the data being transmitted, which allows network traffic to be matched against firewall rules that are specific to individual services or applications. These are also known as proxy-based firewalls.

In addition to firewall software, which is available on all modern operating systems, firewall functionality can also be provided by hardware devices, such as routers or firewall appliances. Again, our discussion will be focused on **stateful** software firewalls that run on the servers that they are intended to protect.

## Firewall Rules

As mentioned above, network traffic that traverses a firewall is matched against rules to determine if it should be allowed through or not. An easy way to explain what firewall rules looks like is to show a few examples, so we’ll do that now.

Suppose you have a server with this list of firewall rules that apply to incoming traffic:

1. Accept new and established incoming traffic to the public network interface on port 80 and 443 (HTTP and HTTPS web traffic)
2. Drop incoming traffic from IP addresses of the non-technical employees in your office to port 22 (SSH)
3. Accept new and established incoming traffic from your office IP range to the private network interface on port 22 (SSH)

Note that the first word in each of these examples is either “accept”, “reject”, or “drop”. This specifies the action that the firewall should do in the event that a piece of network traffic matches a rule. **Accept** means to allow the traffic through, **reject** means to block the traffic but reply with an “unreachable” error, and **drop** means to block the traffic and send no reply. The rest of each rule consists of the condition that each packet is matched against.

As it turns out, network traffic is matched against a list of firewall rules in a sequence, or chain, from first to last. More specifically, once a rule is matched, the associated action is applied to the network traffic in question. In our example, if an accounting employee attempted to establish an SSH connection to the server they would be rejected based on rule 2, before rule 3 is even checked. A system administrator, however, would be accepted because they would match only rule 3.

### Default Policy

It is typical for a chain of firewall rules to not explicitly cover every possible condition. For this reason, firewall chains must always have a default policy specified, which consists only of an action (accept, reject, or drop).

Suppose the default policy for the example chain above was set to **drop**. If any computer outside of your office attempted to establish an SSH connection to the server, the traffic would be dropped because it does not match the conditions of any rules.

If the default policy were set to **accept** , anyone, except your own non-technical employees, would be able to establish a connection to any open service on your server. This would be an example of a very poorly configured firewall because it only keeps a subset of your employees out.

## Incoming and Outgoing Traffic

As network traffic, from the perspective of a server, can be either incoming or outgoing, a firewall maintains a distinct set of rules for either case. Traffic that originates elsewhere, incoming traffic, is treated differently than outgoing traffic that the server sends. It is typical for a server to allow most outgoing traffic because the server is usually, to itself, trustworthy. Still, the outgoing rule set can be used to prevent unwanted communication in the case that a server is compromised by an attacker or a malicious executable.

In order to maximize the security benefits of a firewall, you should identify all of the ways you want other systems to interact with your server, create rules that explicitly allow them, then drop all other traffic. Keep in mind that the appropriate outgoing rules must be in place so that a server will allow itself to send outgoing acknowledgements to any appropriate incoming connections. Also, as a server typically needs to initiate its own outgoing traffic for various reasons—for example, downloading updates or connecting to a database—it is important to include those cases in your outgoing rule set as well.

### Writing Outgoing Rules

Suppose our example firewall is set to **drop** outgoing traffic by default. This means our incoming **accept** rules would be useless without complementary outgoing rules.

To complement the example incoming firewall rules (1 and 3), from the **Firewall Rules** section, and allow proper communication on those addresses and ports to occur, we could use these outgoing firewall rules:

1. Accept established outgoing traffic to the public network interface on port 80 and 443 (HTTP and HTTPS)
2. Accept established outgoing traffic to the private network interface on port 22 (SSH)

Note that we don’t need to explicitly write a rule for incoming traffic that is dropped (incoming rule 2) because the server doesn’t need to establish or acknowledge that connection.

## Firewall Software and Tools

Now that we’ve gone over how firewalls work, let’s take a look at common software packages that can help us set up an effective firewall. While there are many other firewall-related packages, these are effective and are the ones you will encounter the most.

### Iptables

Iptables is a standard firewall included in most Linux distributions by default (a modern variant called nftables will begin to replace it). It is actually a front end to the kernel-level netfilter hooks that can manipulate the Linux network stack. It works by matching each packet that crosses the networking interface against a set of rules to decide what to do.

To learn how to implement a firewall with iptables, check out these links:

- [How To Set Up a Firewall Using IPTables on Ubuntu 14.04](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04)
- [How To Implement a Basic Firewall Template with Iptables on Ubuntu 14.04](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04)
- [How To Set Up an Iptables Firewall to Protect Traffic Between your Servers](how-to-set-up-an-iptables-firewall-to-protect-traffic-between-your-servers)

### UFW

UFW, which stands for Uncomplicated Firewall, is an interface to iptables that is geared towards simplifying the process of configuring a firewall.

To learn more about using UFW, check out this tutorial: [How To Setup a Firewall with UFW on an Ubuntu and Debian Cloud Server](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server).

### FirewallD

FirewallD is a complete firewall solution available by default on CentOS 7 servers. Incidentally, FirewallD uses iptables to configure netfilter.

To learn more about using FirewallD, check out this tutorial: [How To Configure FirewallD to Protect Your CentOS 7 Server](how-to-configure-firewalld-to-protect-your-centos-7-server).

If you’re running CentOS 7 but prefer to use iptables, follow this tutorial: [How To Migrate from FirewallD to Iptables on CentOS 7](how-to-migrate-from-firewalld-to-iptables-on-centos-7).

### Fail2ban

Fail2ban is an intrusion prevention software that can automatically configure your firewall to block brute force login attempts and DDOS attacks.

To learn more about Fail2ban, check out these links:

- [How Fail2ban Works to Protect Services on a Linux Server](how-fail2ban-works-to-protect-services-on-a-linux-server)
- [How To Protect SSH with Fail2Ban on Ubuntu 14.04](how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04)
- [How To Protect an Nginx Server with Fail2Ban on Ubuntu 14.04](how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04)
- [How To Protect an Apache Server with Fail2Ban on Ubuntu 14.04](how-to-protect-an-apache-server-with-fail2ban-on-ubuntu-14-04)

## Conclusion

Now that you understand how firewalls work, you should look into implementing a firewall that will improve your security of your server setup by using the tutorials above.

If you want to learn more about how firewalls work, check out these links:

- [How the Iptables Firewall Works](how-the-iptables-firewall-works)
- [How To Choose an Effective Firewall Policy to Secure your Servers](how-to-choose-an-effective-firewall-policy-to-secure-your-servers)
- [A Deep Dive into Iptables and Netfilter Architecture](a-deep-dive-into-iptables-and-netfilter-architecture)
