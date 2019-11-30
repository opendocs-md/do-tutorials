---
author: Justin Ellingwood
date: 2015-08-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-iptables-firewall-to-protect-traffic-between-your-servers
---

# How To Set Up an Iptables Firewall to Protect Traffic Between your Servers

## Introduction

Deploying discrete components in your application setup onto different nodes is a common way to decrease load and begin scaling horizontally. A typical example is configuring a database on a separate server from your application. While there are a great number of advantages with this setup, connecting over a network involves a new set of security concerns.

In this guide, we’ll demonstrate how to set up a simple firewall on each of your servers in a distributed setup. We will configure our policy to allow legitimate traffic between our components while denying other traffic.

For the demonstration in this guide, we’ll be using two Ubuntu 14.04 servers. One will have a WordPress instance served with Nginx and the other will host the MySQL database for the application. Although we will be using this setup as an example, you should be able to extrapolate the techniques involved to fit your own server requirements.

### Prerequisites

To get started, you will have to have two fresh Ubuntu 14.04 servers. Add a regular user account with `sudo` privileges on each. To learn how to do this correctly, follow our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04).

The application setup we will be securing is based on [this guide](how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql). If you’d like to follow along, set up your application and database servers as indicated by that tutorial.

## Setting Up a Basic Firewall

We will begin by implementing a baseline firewall configuration for each of our servers. The policy that we will be implementing takes a security-first approach. We will be locking down almost everything other than SSH traffic and then poking holes in the firewall for our specific application.

The firewall in [this guide](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04) provides the basic setup that we need. Install the `iptables-persistent` package and paste the basic rules into the `/etc/iptables/rules.v4` file:

    sudo apt-get update
    sudo apt-get install iptables-persistent
    sudo nano /etc/iptables/rules.v4

/etc/iptables/rules.v4

    *filter
    # Allow all outgoing, but drop incoming and forwarding packets by default
    :INPUT DROP [0:0]
    :FORWARD DROP [0:0]
    :OUTPUT ACCEPT [0:0]
    
    # Custom per-protocol chains
    :UDP - [0:0]
    :TCP - [0:0]
    :ICMP - [0:0]
    
    # Acceptable UDP traffic
    
    # Acceptable TCP traffic
    -A TCP -p tcp --dport 22 -j ACCEPT
    
    # Acceptable ICMP traffic
    
    # Boilerplate acceptance policy
    -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A INPUT -i lo -j ACCEPT
    
    # Drop invalid packets
    -A INPUT -m conntrack --ctstate INVALID -j DROP
    
    # Pass traffic to protocol-specific chains
    ## Only allow new connections (established and related should already be handled)
    ## For TCP, additionally only allow new SYN packets since that is the only valid
    ## method for establishing a new TCP connection
    -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
    -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
    -A INPUT -p icmp -m conntrack --ctstate NEW -j ICMP
    
    # Reject anything that's fallen through to this point
    ## Try to be protocol-specific w/ rejection message
    -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
    -A INPUT -p tcp -j REJECT --reject-with tcp-reset
    -A INPUT -j REJECT --reject-with icmp-proto-unreachable
    
    # Commit the changes
    COMMIT
    
    *raw
    :PREROUTING ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    COMMIT
    
    *nat
    :PREROUTING ACCEPT [0:0]
    :INPUT ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    COMMIT
    
    *security
    :INPUT ACCEPT [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    COMMIT
    
    *mangle
    :PREROUTING ACCEPT [0:0]
    :INPUT ACCEPT [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :POSTROUTING ACCEPT [0:0]
    COMMIT

If you are implementing this in a live environment **do not reload your firewall rules yet**. Loading the basic rule set outlined here will immediately drop the connection between your application and database server. We will need to adjust the rules to reflect our operational needs before reloading.

## Discover the Ports Being Used by Your Services

In order to add exceptions to allow communication between our components, we need to know the network ports being used. We could find the correct network ports by examining our configuration files, but an application-agnostic method of finding the correct ports is to just check which services are listening for connections on each of our machines.

We can use the `netstat` tool to find this out. Since our application is only communicating over IPv4, we will add the `-4` argument but you can remove that if you are using IPv6 as well. The other arguments we need in order to find our running services are `-plunt`.

On your web server, we would see something like this:

    sudo netstat -4plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1058/sshd
    tcp 0 0 0.0.0.0:80 0.0.0.0:* LISTEN 4187/nginx

The first highlighted column shows the IP address and port that the service highlighted towards the end of the line is listening on. The special `0.0.0.0` address means that the service in question is listening on all available addresses.

On our database server we would see something like this:

    sudo netstat -4plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1097/sshd
    tcp 0 0 192.0.2.30:3306 0.0.0.0:* LISTEN 3112/mysqld

You can read these columns exactly the same. In the above example, the `192.0.2.30` address represents the database server’s private IP address. In the application setup, we locked MySQL down to the private interface for security reasons.

Take note of the values you find in this step. These are the networking details that we need in order to adjust our firewall configuration.

In our example scenario, we can note that on our web server, we need to ensure that the following ports are accessible:

- Port 80 on all addresses
- Port 22 on all addresses (already accounted for in firewall rules)

Our database server would have to ensure that the following ports are accessible:

- Port 3306 on the address `192.0.2.30` (or the interface associated with it)
- Port 22 on all addresses (already accounted for in firewall rules)

## Adjust the Web Server Firewall Rules

Now that we have the port information we need, we will adjust our web server’s firewall rule set. Open the rules file in your editor with `sudo` privileges:

    sudo nano /etc/iptables/rules.v4

On the web server, we need to add port 80 to our list of acceptable traffic. Since the server is listening on all available addresses, we will not restrict the rule by interface or destination address.

Our web visitors will be using the TCP protocol to connect. Our basic framework already has a custom chain called `TCP` for TCP application exceptions. We can add port 80 to that chain, right below the exception for our SSH port:

/etc/iptables/rules.v4

    *filter
    . . .
    
    # Acceptable TCP traffic
    -A TCP -p tcp --dport 22 -j ACCEPT
    -A TCP -p tcp --dport 80 -j ACCEPT
    
    . . .

Our web server will initiate the connection with our database server. Our outgoing traffic is not restricted in our firewall and incoming traffic associated with established connections is permitted, so we do not have to open any additional ports on this server allow this connection.

Save and close the file when you are finished. Our web server now has a firewall policy that will allow all legitimate traffic while blocking everything else.

Test your rules file for syntax errors:

    sudo iptables-restore -t < /etc/iptables/rules.v4

If no syntax errors are displayed, reload the firewall to implement the new rule set:

    sudo service iptables-persistent reload

## Adjust the Database Server Firewall Rules

On our database server, we need to allow access to port `3306` on our server’s private IP address. In our case, that address was `192.0.2.30`. We can limit access destined for this address specifically, or we can limit access by matching against the interface that is assigned that address.

To find the network interface associated with that address, type:

    ip -4 addr show scope global

    Output2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        inet 203.0.113.5/24 brd 104.236.113.255 scope global eth0
           valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        inet 192.0.2.30/24 brd 192.0.2.255 scope global eth1
           valid_lft forever preferred_lft forever

The highlighted areas show that the `eth1` interface is associated with that address.

Next, we will adjust the firewall rules on the database server. Open the rules file with `sudo` privileges on your database server:

    sudo nano /etc/iptables/rules.v4

Again, we will be adding a rule to our `TCP` chain to form an exception for the connection between our web and database servers.

If you wish to restrict access based on the actual address in question, you would add the rule like this:

/etc/iptables/rules.v4

    *filter
    . . .
    
    # Acceptable TCP traffic
    -A TCP -p tcp --dport 22 -j ACCEPT
    -A TCP -p tcp --dport 3306 -d 192.0.2.30 -j ACCEPT
    
    . . .

If you would rather allow the exception based on the interface that houses that address, you can add a rule similar to this one instead:

/etc/iptables/rules.v4

    *filter
    . . .
    
    # Acceptable TCP traffic
    -A TCP -p tcp --dport 22 -j ACCEPT
    -A TCP -p tcp --dport 3306 -i eth1 -j ACCEPT
    
    . . .

Save and close the file when you are finished.

Check for syntax errors with this command:

    sudo iptables-restore -t < /etc/iptables/rules.v4

When you are ready, reload the firewall rules:

    sudo service iptables-persistent reload

Both of your servers should now be protected without restricting the necessary flow of data between them.

## Conclusion

Implementing a proper firewall should always be part of your deployment plan when setting up an application. Although we demonstrated this configuration using the two servers running Nginx and MySQL to provide a WordPress instance, the techniques demonstrated above are applicable regardless of your specific technology choices.

To learn more about firewalls and `iptables` specifically, take a look at the following guides:

- [How To Choose an Effective Firewall Policy to Secure your Servers](how-to-choose-an-effective-firewall-policy-to-secure-your-servers)
- [A Deep Dive into Iptables and Netfilter Architecture](a-deep-dive-into-iptables-and-netfilter-architecture)
- [How To Test your Firewall Configuration with Nmap and Tcpdump](how-to-test-your-firewall-configuration-with-nmap-and-tcpdump)
