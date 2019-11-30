---
author: Justin Ellingwood
date: 2014-05-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-the-iptables-firewall-works
---

# How the Iptables Firewall Works

## Introduction

Setting up a good firewall is an essential step to take in securing any modern operating system. Most Linux distributions ship with a few different firewall tools that we can use to configure our firewalls. In this guide, we’ll be covering the `iptables` firewall.

Iptables is a standard firewall included in most Linux distributions by default (a modern variant called `nftables` will begin to replace it). It is actually a front end to the kernel-level netfilter hooks that can manipulate the Linux network stack. It works by matching each packet that crosses the networking interface against a set of rules to decide what to do.

In this guide we will discuss how iptables works. In the next article in the series, we’ll show you [how to configure a basic set of rules to protect your Ubuntu 14.04 server](https://www.digitalocean.com/community/articles/how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04).

## How Iptables Works

Before we get started discussing the actual commands needed to control iptables and build a firewall policy, let’s go over some terminology and discuss how iptables works.

The iptables firewall operates by comparing network traffic against a set of **rules**. The rules define the characteristics that a packet must have to match the rule, and the action that should be taken for matching packets.

There are many options to establish which packets match a specific rule. You can match the packet protocol type, the source or destination address or port, the interface that is being used, its relation to previous packets, etc.

When the defined pattern matches, the action that takes place is called a **target**. A target can be a final policy decision for the packet, such as accept, or drop. It can also be move the packet to a different chain for processing, or simply log the encounter. There are many options.

These rules are organized into groups called **chains**. A chain is a set of rules that a packet is checked against sequentially. When the packet matches one of the rules, it executes the associated action and is not checked against the remaining rules in the chain.

A user can create chains as needed. There are three chains defined by default. They are:

- **INPUT** : This chain handles all packets that are addressed to your server.
- **OUTPUT** : This chain contains rules for traffic created by your server.
- **FORWARD** : This chain is used to deal with traffic destined for other servers that are not created on your server. This chain is basically a way to configure your server to route requests to other machines.

Each chain can contain zero or more rules, and has a default **policy**. The policy determines what happens when a packet drops through all of the rules in the chain and does not match any rule. You can either drop the packet or accept the packet if no rules match.

Through a module that can be loaded via rules, iptables can also track connections. This means you can create rules that define what happens to a packet based on its relationship to previous packets. We call this capability “state tracking”, “connection tracking”, or configuring the “state machine”.

For this guide, we are mainly going to be covering the configuration of the INPUT chain, since it contains the set of rules that will help us deny unwanted traffic directed at our server.

### IPv4 Versus IPv6

The netfilter firewall that is included in the Linux kernel keeps IPv4 and IPv6 traffic completely separate. Likewise, the tools used to manipulate the tables that contain the firewall rulesets are distinct as well. If you have IPv6 enabled on your server, you will have to configure both tables to address the traffic you server is subjected to.

The regular `iptables` command is used to manipulate the table containing rules that govern IPv4 traffic. For IPv6 traffic, a companion command called `ip6tables` is used. This is an important point to internalize, as it means that any rules that you set with `iptables` will have no affect on packets using version 6 of the protocol.

The syntax between these twin commands is the same, so creating a ruleset for each of these tables is not too overwhelming. Just remember to modify both tables whenever you make a change. The `iptables` command will make the rules that apply to IPv4 traffic, and the `ip6tables` command will make the rules that apply to IPv6 traffic.

You must be sure to use the appropriate IPv6 addresses of your server to craft the `ip6tables` rules.

## Things to Keep in Mind

Now that we know how iptables directs packets that come through its interface (direct the packet to the appropriate chain, check it against each rule until one matches, issue the default policy of the chain if no match is found), we can begin to see some pitfalls to be aware of as we make rules.

First, we need to make sure that we have rules to keep current connections active if we implement a default drop policy. This is especially important if you are connected to your server through SSH. If you accidentally implement a rule or policy that drops your current connection, you can always log into your DigitalOcean VPS by using the web console, which provides out-of-band access.

Another thing to keep in mind is that the order of the rules in each chain _matter_. A packet must not come across a more general rule that it matches if it is meant to match a more specific rule.

Because of this, rules near the top of a chain should have a higher level of specificity than rules at the bottom. You should match specific cases first, and then provide more general rules to match broader patterns. If a packet falls through the entire chain (doesn’t match any rules), it will hit the _most_ general rule, the default policy.

For this reason, a chain’s default policy very strongly dictates the types of rules that will be included in the chain. A chain with the default policy of ACCEPT will contain rules that explicitly drop packets. A chain that defaults to DROP will contain exceptions for packets that should be specifically accepted.

## Conclusion

At this point, the easiest way to learn about how iptables works is to use it to implement your own firewall.

In the next guide, we will show [how to create a basic iptables firewall on Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04). This will lock down your server except for the few services that you want to allow.

By Justin Ellingwood
