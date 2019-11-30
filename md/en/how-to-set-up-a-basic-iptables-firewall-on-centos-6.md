---
author: 
date: 2013-04-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-basic-iptables-firewall-on-centos-6
---

# How To Set Up a Basic Iptables Firewall on Centos 6

### Intro

This article will show how to create a simple firewall on a Centos VPS. It will only open up ports that we want and close up other services. I will also show how to prevent simpler attacks, and how to let yourself back in to the VPS if you deny access to yourself by accident.

The tutorial is not by any means exhaustive and only shows how to open up a few incoming ports: for apache, SSH and email and close all the others. We will not be blocking any outgoing traffic, and only create a few most common rules to block the usual scripts and bots that look for vulnerable VPS.

**iptables** is a simple firewall installed on most linux distributions. The linux [manual page](http://ipset.netfilter.org/iptables.man.html) for _iptables_ says it is an _administration tool for IPv4 packet filtering and NAT_, which, in translation, means it is a tool to filter out and block Internet traffic. **iptables** firewall is included by default in Centos 6.4 linux images provided by DigitalOcean.

We will set up firewall one by one rule. To simplify: a firewall is a list of _rules_, so when an incomming connection is open, if it matches any of the rules, this rule can accept that connection or reject it. If no rules are met, we use the default rule.

**Note:** _This tutorial covers IPv4 security. In Linux, IPv6 security is maintained separately from IPv4. For example, "iptables" only maintains firewall rules for IPv4 addresses but it has an IPv6 counterpart called "ip6tables", which can be used to maintain firewall rules for IPv6 network addresses._

_If your VPS is configured for IPv6, please remember to secure both your IPv4 and IPv6 network interfaces with the appropriate tools. For more information about IPv6 tools, refer to this guide: [How To Configure Tools to Use IPv6 on a Linux VPS](how-to-configure-tools-to-use-ipv6-on-a-linux-vps)_

## Decide which ports and services to open

To start with, we want to know what services we want to open to public. Let's use the typical web-hosting server: it is a web and email server, and we also need to let ourselves in by SSH server.

First, we want to leave SSH port open so we can connect to the VPS remotely: that is port 22.

Also, we need port 80 and 443 (SSL port) for web traffic. For sending email, we will open port 25 (regular SMTP) and 465 (secure SMTP). To let users receive email, we will open the usual port 110 (POP3) and 995 (secure POP3 port).

Additionally, we'll open IMAP ports, if we have it installed: 143 for IMAP, and 993 for IMAP over SSL.Note: _It is recommended to only allow secure protocols, but that may not be an option, if we cannot influence the mail service users to change their email clients._

## Block the most common attacks

DigitalOcean VPSs usually come with the empty configuration: all traffic is allowed. Just to make sure of this, we can _flush_ the firewall rules - that is, erase them all:

    iptables -F

We can then add a few simple firewall rules to block the most common attacks, to protect our VPS from script-kiddies. We can't really count on iptables alone to protect us from a full-scale DDOS or similar, but we can at least put off the usual network scanning bots that will eventually find our VPS and start looking for security holes to exploit. First, we start with blocking null packets.

    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

We told the firewall to take all incoming packets with tcp flags NONE and just DROP them. [Null packets](http://minsky.gsi.dit.upm.es/semanticwiki/index.php/TCP_Null_Scan) are, simply said, recon packets. The attack patterns use these to try and see how we configured the VPS and find out weaknesses. The next pattern to reject is a syn-flood attack.

    iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

[Syn-flood attack](http://en.wikipedia.org/wiki/Syn-flood) means that the attackers open a new connection, but do not state what they want (ie. SYN, ACK, whatever). They just want to take up our servers' resources. We won't accept such packages. Now we move on to one more common pattern: [XMAS](http://en.wikipedia.org/wiki/Christmas_tree_packet) packets, also a recon packet.

    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

We have ruled out at least some of the usual patterns that find vulnerabilities in our VPS.

## Open up ports for selected services

Now we can start adding selected services to our firewall filter. The first such thing is a localhost interface:

    iptables -A INPUT -i lo -j ACCEPT

We tell iptables to add (-A) a rule to the incoming (INPUT) filter table any trafic that comes to localhost interface (-i lo) and to accept (-j ACCEPT) it. Localhost is often used for, ie. your website or email server communicating with a database locally installed. That way our VPS can use the database, but the database is closed to exploits from the internet.

Now we can allow web server traffic:

    iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

 We added the two ports (http port 80, and https port 443) to the ACCEPT chain - allowing traffic in on those ports. Now, let's allow users use our SMTP servers: 

    iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT iptables -A INPUT -p tcp -m tcp --dport 465 -j ACCEPT

Like stated before, if we can influence our users, we should rather use the secure version, but often we can't dictate the terms and the clients will connect using port 25, which is much more easier to have passwords sniffed from. We now proceed to allow the users read email on their server:

    iptables -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT iptables -A INPUT -p tcp -m tcp --dport 995 -j ACCEPT

Those two rules will allow POP3 traffic. Again, we could increase security of our email server by just using the secure version of the service. Now we also need to allow IMAP mail protocol:

    iptables -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT iptables -A INPUT -p tcp -m tcp --dport 993 -j ACCEPT

## Limiting SSH access

We should also allow SSH traffic, so we can connect to the VPS remotely. The simple way to do it would be with this command:

    iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT

We now told iptables to add a rule for accepting _tcp_ traffic incomming to port 22 (the default SSH port). It is advised to change the SSH configuration to a different port, and this firewall filter should be changed accordingly, but configuring SSH is not a part of this article.

However, we could do one more thing about that with firewall itself. If our office has a permanent IP address, we could only allow connections to SSH from this source. This would allow only people from our location to connect.

First, find out your outside IP address. Make sure it is not an address from your LAN, or it will not work. You could do that simply by visiting the [whatismyip.com](http://whatismyip.org/) site. Another way to find it out is to type:

    w

in the terminal, we should see us logged in (if we're the only one logged in' and our IP address written down.

The output looks something like this:

    root@iptables# w 11:42:59 up 60 days, 11:21, 1 user, load average: 0.00, 0.00, 0.00 USER TTY FROM LOGIN@ IDLE JCPU PCPU WHAT root pts/0 213.191.xxx.xxx 09:27 0.00s 0.05s 0.00s w 

Now, you can create the firewall rule to only allow traffic to SSH port if it comes from one source: your IP address:

    iptables -A INPUT -p tcp -s YOUR\_IP\_ADDRESS -m tcp --dport 22 -j ACCEPT

Replace YOUR\_IP\_ADDRESS with the actuall IP, of course.

We could open more ports on our firewall as needed by changing the port numbers. That way our firewall will allow access only to services we want. Right now, we need to add one more rule that will allow us to use outgoing connections (ie. ping from VPS or run software updates);

    iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

It will allow any established outgoing connections to receive replies from the VPS on the other side of that connection. When we have it all set up, we will block everything else, and allow all outgoing connections.

    iptables -P OUTPUT ACCEPT iptables -P INPUT DROP

Now we have our firewall rules in place.

## Save the configuration

Now that we have all the configuration in, we can list the rules to see if anything is missing.

    iptables -L -n

The **-n** switch here is because we need only ip addresses, not domain names. Ie. if there is an IP in the rules like this: 69.55.48.33: the firewall would go look it up and see that it was a digitalocean.com IP. We don't need that, just the address itself. Now we can finally save our firewall configuration:

    iptables-save | sudo tee /etc/sysconfig/iptables

The _iptables_ configuration file on CentOS is located at _/etc/sysconfig/iptables_. The above command saved the rules we created into that file. Just to make sure everything works, we can restart the firewall:

    service iptables restart

The saved rules will persist even when the VPS is rebooted.

## Flush to unlock yourself

If we made an accident in our configuration, we may have blocked ourselves from accessing the VPS. Perhaps we have put in the incorrect IP address so the firewall does not allow connections from our workstation. Now we can't reach those rules, and if we saved them, even a restart won't help us. Luckily, the DO web interface allowes us to connect to server via console:

 ![Console](https://assets.digitalocean.com/tutorial_images/IDnXako.png)

Once connected, we log in as root and issue the following command:

    iptables -F

This will flush the filters, we'll be able to get in the VPS again.

## Conclusion

This article is not exhaustive, and it only scratched the surface of running a simple firewall on a linux machine. It will do enough for a typical web and email server scenario for a developer not familiar with linux command line or iptables.

However, a lot more could be done. There are good tutorials and samples on the internet to help us provide more robust configuration. For production environments, it would be advised to create a more detailed configuration or to have a security expert prepare the configuration.

Hopefully, the short instructions will provide basic security to new VPSs.
