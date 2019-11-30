---
author: Justin Ellingwood
date: 2015-08-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-forward-ports-through-a-linux-gateway-with-iptables
---

# How To Forward Ports through a Linux Gateway with Iptables

## Introduction

**NAT** , or network address translation, is a general term for mangling packets in order to redirect them to an alternative address. Usually, this is used to allow traffic to transcend network boundaries. A host that implements NAT typically has access to two or more networks and is configured to route traffic between them.

**Port forwarding** is the process of forwarding requests for a specific port to another host, network, or port. As this process modifies the destination of the packet in-flight, it is considered a type of NAT operation.

In this guide, we’ll demonstrate how to use `iptables` to forward ports to hosts behind a firewall by using NAT techniques. This is useful if you’ve configured a private network, but still want to allow certain traffic inside through a designated gateway machine. We will be using two Ubuntu 14.04 hosts to demonstrate this.

## Prerequisites and Goals

To follow along with this guide, you will need two Ubuntu 14.04 hosts in the same datacenter with private networking enabled. On each of these machines, you will need to set up a non-root user account with `sudo` privileges. You can learn how to create a user with `sudo` privileges by following our [Ubuntu 14.04 initial server setup guide](initial-server-setup-with-ubuntu-14-04).

The first host will function as our firewall and router for the private network. For demonstration purposes, the second host will be configured with a web server that is only accessible using its private interface. We will be configuring the firewall machine to forward requests received on its public interface to the web server, which it will reach on its private interface.

## Host Details

Before you begin, we need to know the what interfaces and addresses are being used by both of our servers.

### Finding Your Network Details

To get the details of your own systems, begin by finding your network interfaces. You can find the interfaces on your machines and the addresses associated with them by typing:

    ip -4 addr show scope global

    Sample Output2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        inet 198.51.100.45/18 brd 45.55.191.255 scope global eth0
           valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        inet 192.168.1.5/16 brd 10.132.255.255 scope global eth1
           valid_lft forever preferred_lft forever

The highlighted output above shows two interfaces (`eth0` and `eth1`) and the addresses assigned to each (`192.51.100.45` and `192.168.1.5` respectively). To find out which of these interfaces is your public interface, type:

    ip route show | grep default

    Outputdefault via 111.111.111.111 dev eth0

The interface shown (`eth0` in this example) will be the interface connected to your default gateway. This is almost certainly your public interface.

Find these values on each of your machines and use them to correctly follow along with this guide.

### Sample Data for this Guide

To make it easier to follow along, we’ll be using the following dummy address and interface assignments throughout this tutorial. Please substitute your own values for the ones you see below:

Web server network details:

- Public IP Address: `203.0.113.2`
- Private IP Address: `192.0.2.2`
- Public Interface: `eth0`
- Private Interface: `eth1`

Firewall network details:

- Public IP Address: `203.0.113.15`
- Private IP Address: `192.0.2.15`
- Public Interface: `eth0`
- Private Interface: `eth1`

## Setting Up the Web Server

We will begin with our web server host. Log in with your `sudo` user to begin.

### Install Nginx

The first process we will complete is to install `Nginx` on our web server host and lock it down so that it only listens to its private interface. This will ensure that our web server will only be available if we correctly set up port forwarding.

Begin by updating the local package cache and using `apt` to download and install the software:

    sudo apt-get update
    sudo apt-get install nginx

### Restrict Nginx to the Private Network

After Nginx is installed, we will open up the default server block configuration file to ensure that it only listens to the private interface. Open the file now:

    sudo nano /etc/nginx/sites-enabled/default

Inside, find the `listen` directive. You should find it twice in a row towards the top of the configuration:

/etc/nginx/sites-enabled/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
    
        . . .
    }

At the first `listen` directive, add your _web server’s private IP address_ and a colon just ahead of the `80` to tell Nginx to only listen on the private interface. We are only demonstrating IPv4 forwarding in this guide, so we can remove the second listen directive, which is configured for IPv6.

In our example, we’d modify the listen directives to look like this:

/etc/nginx/sites-enabled/default

    server {
        listen 192.0.2.2:80 default_server;
    
        . . .
    }

Save and close the file when you are finished. Test the file for syntax errors by typing:

    sudo nginx -t

If no errors are shown, restart Nginx to enable the new configuration:

    sudo service nginx restart

### Verify the Network Restriction

At this point, it’s useful to verify the level of access we have to our web server.

From our **firewall** server, if we try to access our web server from the private interface, it should work:

    curl --connect-timeout 5 192.0.2.2

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    . . .

If we try to use the public interface, we will see that we cannot connect:

    curl --connect-timeout 5 203.0.113.2

    curl: (7) Failed to connect to 203.0.113.2 port 80: Connection refused

This is exactly what we expect to happen.

## Configuring the Firewall to Forward Port 80

Now, we can work on implementing port forwarding on our firewall machine.

### Enable Forwarding in the Kernel

The first thing we need to do is enable traffic forwarding at the kernel level. By default, most systems have forwarding turned off.

To turn port forwarding on for this session only, type:

    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

To turn port forwarding on permanently, you will have to edit the `/etc/sysctl.conf` file. Open the file with `sudo` privileges by typing:

    sudo nano /etc/sysctl.conf

Inside, find and uncomment the line that looks like this:

/etc/sysctl.conf

    net.ipv4.ip_forward=1

Save and close the file when you are finished. You apply the settings in this file by typing:

    sudo sysctl -p
    sudo sysctl --system

### Setting Up the Basic Firewall

We will use the firewall in [this guide](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04) as the basic framework for the rules in this tutorial. Run through the guide now on your firewall machine in order to get set up. Upon finishing, you will have:

- Installed `iptables-persistent`
- Saved the default rule set into `/etc/iptables/rules.v4`
- Learned how to add or adjust rules by editing the rule file or by using the `iptables` command

When you have the basic firewall set up, continue below so that we can adjust it for port forwarding.

### Adding the Forwarding Rules

We want to configure our firewall so that traffic flowing into our public interface (`eth0`) on port 80 will be forwarded to our private interface (`eth1`).

Our basic firewall has a our `FORWARD` chain set to `DROP` traffic by default. We need to add rules that will allow us to forward connections to our web server. For security’s sake, we will lock this down fairly tightly so that only the connections we wish to forward are allowed.

In the `FORWARD` chain, we will accept new connections destined for port 80 that are coming from our public interface and travelling to our private interface. New connections are identified by the `conntrack` extension and will specifically be represented by a TCP SYN packet:

    sudo iptables -A FORWARD -i eth0 -o eth1 -p tcp --syn --dport 80 -m conntrack --ctstate NEW -j ACCEPT

This will let the first packet, meant to establish a connection, through the firewall. We also need to allow any subsequent traffic in both directions that results from that connection. To allow `ESTABLISHED` and `RLEATED` traffic between our public and private interfaces, type:

    iptables -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i eth1 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

We can double check that our policy on the `FORWARD` chain is set to `DROP` by typing:

    sudo iptables -P FORWARD DROP

At this point, we have allowed certain traffic between our public and private interfaces to proceed through our firewall. However, we haven’t yet configured the rules that will actually tell `iptables` how to translate and direct the traffic.

### Adding the NAT Rules to Direct Packets Correctly

Next, we’ll add the rules that will tell `iptables` how to route our traffic. We need to perform two separate operations in order for `iptables` to correctly alter the packets so that clients can communicate with the web server.

The first operation, called `DNAT`, will take place in the `PREROUTING` chain of the `nat` table. `DNAT` is an operation which alters a packet’s destination address in order to enable it to be correctly routed as it passes between networks. The clients on the public network will be connecting to our firewall server and will have no knowledge of our private network topology. We need to alter the destination address of each packet so that when it is sent out on our private network, it knows how to correctly reach our web server.

Since we are only configuring port forwarding and not performing NAT on every packet that hits our firewall, we’ll want to match port 80 on our rule. We will match packets aimed at port 80 to our web server’s private IP address (`192.0.2.2` in our example):

    sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 192.0.2.2

This takes care of half of the picture. The packet should get routed correctly to our web server. However, right now, the packet will still have the client’s original address as the source address. The server will attempt to send the reply directly to that address, which will make it impossible to establish a legitimate TCP connection.

Note
On DigitalOcean, packets leaving a Droplet with a different source address will actually be dropped by the hypervisor, so your packets at this stage will never even make it to the web server (we will fix this by implementing SNAT momentarily). This is an anti-spoofing measure put in place to prevent attacks where large amounts of data are requested to be sent to a victim’s computer by faking the source address in the request. To find out more, view this [response in our community](https://www.digitalocean.com/community/questions/nat-gateway-on-digital-ocean-s-droplet-possible?answer=13896).  

To configure proper routing, we also need to modify the packet’s source address as it leaves the firewall en route to the web server. We need to modify the source address to our firewall server’s private IP address (`192.0.2.15` in our example). The reply will then be sent back to the firewall, which can then forward it back to the client as expected.

To enable this functionality, we’ll add a rule to the `POSTROUTING` chain of the `nat` table, which is evaluated right before packets are sent out on the network. We’ll match the packets destined for our web server by IP address and port:

    sudo iptables -t nat -A POSTROUTING -o eth1 -p tcp --dport 80 -d 192.0.2.2 -j SNAT --to-source 192.0.2.15

Once this rule is in place, our web server should be accessible by pointing our web browser at our firewall machine’s public address:

    curl 203.0.113.15

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    . . .

Our port forwarding setup is complete.

## Adjusting the Permanent Rule Set

Now that we have set up port forwarding, we can save this to our permanent rule set.

If you do not care about losing the comments that are in your current rule set, just use the `iptables-persistent` service to save your rules:

    sudo service iptables-persistent save

If you would like to keep the comments in your file, open it up and edit manually:

    sudo nano /etc/iptables/rules.v4

You will need to adjust the configuration in the `filter` table for the `FORWARD` chain rules that were added. You will also need to adjust the section which configures the `nat` table so that you can add your `PREROUTING` and `POSTROUTING` rules. For our example, it would look something like this:

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
    
    # Rules to forward port 80 to our web server
    
    # Web server network details:
    
    # * Public IP Address: 203.0.113.2
    # * Private IP Address: 192.0.2.2
    # * Public Interface: eth0
    # * Private Interface: eth1
    # 
    # Firewall network details:
    # 
    # * Public IP Address: 203.0.113.15
    # * Private IP Address: 192.0.2.15
    # * Public Interface: eth0
    # * Private Interface: eth1
    -A FORWARD -i eth0 -o eth1 -p tcp --syn --dport 80 -m conntrack --ctstate NEW -j ACCEPT
    -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A FORWARD -i eth1 -o eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # End of Forward filtering rules
    
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
    
    # Rules to translate requests for port 80 of the public interface
    # so that we can forward correctly to the web server using the
    # private interface.
    
    # Web server network details:
    
    # * Public IP Address: 203.0.113.2
    # * Private IP Address: 192.0.2.2
    # * Public Interface: eth0
    # * Private Interface: eth1
    # 
    # Firewall network details:
    # 
    # * Public IP Address: 203.0.113.15
    # * Private IP Address: 192.0.2.15
    # * Public Interface: eth0
    # * Private Interface: eth1
    -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 192.0.2.2
    -A POSTROUTING -d 192.0.2.2 -o eth1 -p tcp --dport 80 -j SNAT --to-source 192.0.2.15
    # End of NAT translations for web server traffic
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

Save and close the file once you have added the above and adjusted the values to reflect your own network environment.

Test the syntax of your rules file by typeing:

    sudo iptables-restore -t < /etc/iptables/rules.v4

If no errors are detected, load the rule set:

    sudo service iptables-persistent reload

Test that your web server is still accessible through your firewall’s public IP address:

    curl 203.0.113.15

This should work just as it did before.

## Conclusion

By now, you should be comfortable with forwarding ports on a Linux server with `iptables`. The process involves permitting forwarding at the kernel level, setting up access to allow forwarding of the specific port’s traffic between two interfaces on the firewall system, and configuring the NAT rules so that the packets can be routed correctly. This may seem like an unwieldy process, but it also demonstrates the flexibility of the `netfilter` packet filtering framework and the `iptables` firewall. This can be used to disguise your private networks topology while permitting service traffic to flow freely through your gateway firewall machine.
