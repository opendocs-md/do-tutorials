---
author: Sam Cater
date: 2018-05-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/getting-started-software-defined-networking-creating-vpn-zerotier-one
---

# Getting Started with Software-Defined Networking and Creating a VPN with ZeroTier One

## Introduction

These days, more and more software projects are built by teams whose members work together from separate geographic locations. While this workflow has many clear advantages, there are cases where such teams might want to link their computers together across the internet and treat them as though they’re in the same room. For example, you may be testing distributed systems like Kubernetes or building a complex multi-service application. Sometimes it just helps with productivity if you can treat machines as though they’re right next to one another, as you wouldn’t need to risk exposing your unfinished services to the internet. This paradigm can be achieved through Software-Defined Networking (SDN), a relatively new technology that provides a dynamic network fabric whose existence is entirely made up of software.

[ZeroTier One](https://www.zerotier.com/) is an open-source application which uses some of the latest developments in SDN to allow users to create secure, manageable networks and treat connected devices as though they’re in the same physical location. ZeroTier provides a web console for network management and endpoint software for the clients. It’s an encrypted Peer-to-Peer technology, meaning that unlike traditional VPN solutions, communications don’t need to pass through a central server or router — messages are sent directly from host to host. As a result it is very efficient and ensures minimal latency. Other benefits include ZeroTier’s simple deployment and configuration process, straightforward maintenance, and that it allows for centralized registration and management of authorized nodes via the Web Console.

By following this tutorial, you will connect a client and server together in a simple point-to-point network. Since Software-Defined Networking doesn’t utilize the traditional client/server design, there is no central VPN server to install and configure; this streamlines deployment of the tool and the addition of any supplementary nodes. Once connectivity is established, you’ll have the opportunity to utilize ZeroTier’s VPN capability by using some clever Linux functionalities to allow traffic to leave your ZeroTier network from your server and instruct a client to send it’s traffic in that direction.

## Prerequisites

Before working through this tutorial, you’ll need the following resources:

- A server running Ubuntu 16.04. On this server, you’ll also need a non-root user with sudo privileges which can be set up using our [initial server setup guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

- An account with ZeroTier One, which you can set up by going to [My ZeroTier](https://my.zerotier.com/). For the purpose of this tutorial, you can use the free version of this service which comes with no costs or commitments.

- A local computer to join your SDN as a client. In the examples throughout this tutorial, both the server and local computer are running Ubuntu Linux but any operating system listed on the [ZeroTier Download Page](https://zerotier.com/download.shtml) will work on the client.

With those prerequisites in place, you are ready to set up software-defined networking for your server and local machine.

## Step 1 — Creating a Software-Defined Network Using ZeroTier One

The ZeroTier platform provides the central point of control for your software-defined network. There, you can authorize and deauthorize clients, choose an addressing scheme, and create a Network ID to which you can direct your clients when setting them up.

Log in to your ZeroTier account, click **Networks** at the top of the screen, and then click **Create**. An automatically-generated network name will appear. Click it to view your Network’s configuration screen. Make a note of the **Network ID** shown in yellow as you will need to reference this later.

If you prefer to change the network name to something more descriptive, edit the name at the left-hand side of the screen; you could also add a description, if you wish. Any changes you make will be saved and applied automatically.

Next, choose which IPv4 address range the SDN will operate on. On the right-hand side of the screen, in the area titled **IPv4 Auto-Assign** , select an address range which your nodes will fall under. For the purposes of this tutorial any range can be used, but it is important to leave the **Auto-Assign from Range** box ticked.

Make sure that **Access Control** on the left remains set to **Certificate (Private Network)**. This ensures that only approved machines can connect to your network, and not just anyone who happens to know your Network ID!

Once finished, your settings should look similar to these:

![ZeroTier settings configuration](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/zerotier-1604/ZeroTierSettings-updated.png)

At this point, you have successfully put together the foundation of a ZeroTier Software-Defined Network. Next, you will install the ZeroTier software on your server and client machines to allow them to connect to your SDN.

## Step 2 — Installing the ZeroTier One Client on Your Server and Local Computer

Since ZeroTier One is a relatively new piece of software, it hasn’t yet been included in the core Ubuntu software repositories. For this reason, ZeroTier provides an installation script which we’ll use to install the software. This command is a GPG-signed script, meaning that the code you download will be verified as published by ZeroTier. This script has four main parts, and here’s a piece-by-piece explanation of each of them:

- `curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61'` - This imports the ZeroTier public key from MIT.
- `gpg --import` - This section of the command adds the ZeroTier public key to your local keychain of authorities to trust for packages you attempt to install. The next part of the command will only be executed if the GPG import completes successfully
- `if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z"` - There are a few things happening in this section, but it essentially translates to: “If the cryptographically-signed install script downloaded from ZeroTier.com passes through GPG and is not rejected as unsigned by ZeroTier, paste that information to the screen.”
- `sudo bash; fi` - This section takes the newly-validated installer script and actually executes it before ending the routine.

**Warning:** You should never download something from the internet and pipe it into another program unless you’re sure it comes from a trusted source. If you’d like, you can inspect the ZeroTier software by reviewing the source code on [the project’s official GitHub page](https://github.com/zerotier/ZeroTierOne).

Use an SSH Console to connect to your newly created server and run the following command as your normal user (an explanation of the command is provided below). Be sure that you **do not** run it as root, since the script automatically requests your password to raise its privilege level, and remember to keep the ZeroTier console open in your browser so you can interact with it when necessary.

    curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import && if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi

Once the script completes, you’ll see two lines of output similar to those shown below. Make a note of your ZeroTier address (without the square brackets) and the name of the system which generated that address, both of which you’ll need later:

    Output*** Waiting for identity generation...
    
    *** Success! You are ZeroTier address [916af8664d].

Repeat this step on your local computer if using Ubuntu, or follow the relevant steps for your operating system on the ZeroTier website’s [Download page](https://www.zerotier.com/download.shtml). Again, make sure to note the ZeroTier address and the machine which generated that address. You will need this information in the next step of this tutorial when you actually join your server and client to the network.

## Step 3 — Joining your ZeroTier Network

Now that both the server and client have the ZeroTier software running on them, you’re ready to connect them to the network you created in the ZeroTier web console.

Use the following command to instruct your client to request access to the ZeroTier network via their platform. The client’s initial request will be rejected and left hanging, but we will fix that in a moment. Be sure to replace NetworkID with the Network ID that you noted earlier from your Network’s configuration window.

    sudo zerotier-cli join NetworkID

    Output200 join OK

You will receive a `200 join OK` message, confirming that the ZeroTier service on your server has understood the command. If you do not, double-check the ZeroTier Network ID you entered.

Since you’ve not created a public network that anyone in the world can join, you now need to authorize your clients. Go to the ZeroTier Web Console and scroll far down to the bottom where the **Members** section is. You should spot two entries marked as **Online** , with the same addresses that you noted earlier.

In the first column marked **Auth?** , tick the boxes to authorize them to join the network. The Zerotier Controller will allocate an IP address to the server and the client from the range you chose earlier the next time they call the SDN.

Allocating the IP addresses may take a moment. While waiting, you could provide a **Short Name** and **Description** for your nodes in the **Members** section.

With that, you will have connected two systems to your software-defined network.

So far, you’ve gained a basic familiarization with the ZeroTier control panel, have used the command line interface to download and install ZeroTier, and then attached both the server and client to that network. Next, you will check that everything was applied correctly by performing a connectivity test.

## Step 4 — Verifying Connectivity

At this stage, it’s important to validate that the two hosts can actually talk to one another. There’s a chance that even though the hosts claim to be joined to the network, they are unable to communicate. By verifying connectivity now, you won’t have to worry about basic interconnectivity issues that could cause trouble later on.

An easy way to find the ZeroTier IP address of each host is to look in the **Members** section of the ZeroTier Web Console. You may need to refresh it after authorizing the server and client before their IP addresses appear. Alternatively, you can use the Linux command line to find these addresses. Use the following command on both machines — the first IP address shown in the list is the one to use. In the example shown below, that address is `203.0.113.0`.

    ip addr sh zt0 | grep 'inet'

    Outputinet 203.0.113.0/24 brd 203.0.255.255 scope global zt0
    inet6 fc63:b4a9:3507:6649:9d52::1/40 scope global
    inet6 fe80::28e4:7eff:fe38:8318/64 scope link

To test connectivity between the hosts, run the `ping` command from one host followed by the IP address of the other. For example, on the client:

    ping your_server_ip

And on the server:

    ping your_client_ip

If replies are being returned from the opposite host (as shown in the output shown below), then the two nodes are successfully communicating over the SDN.

    OutputPING 203.0.113.0 (203.0.113.0) 56(84) bytes of data.
    64 bytes from 203.0.113.0: icmp_seq=1 ttl=64 time=0.054 ms
    64 bytes from 203.0.113.0: icmp_seq=2 ttl=64 time=0.046 ms
    64 bytes from 203.0.113.0: icmp_seq=3 ttl=64 time=0.043 ms

You can add as many machines as you like to this configuration by repeating the ZeroTier installation and join processes outlined above. Remember, these machines need not be in any way proximate to one another.

Now that you’ve confirmed that your server and client are able to communicate with one another, read on to learn how to adjust the network to provide an exit gateway and construct your own VPN.

## Step 5 — Enabling ZeroTier’s VPN Capability

As mentioned in the introduction, it is possible to use ZeroTier as a VPN tool. If you don’t plan to user ZeroTier as a VPN solution, then you needn’t follow this step and can jump ahead to Step 6.

Using a VPN hides the source of your communications with websites across the internet. It allows you to bypass filters and restrictions which may exist on the network you are using. To the wider internet, you will appear to be browsing from the public IP address of your server. In order to use ZeroTier as a VPN tool, you will need to make a few more changes to your server and client’s configurations.

### Enabling Network Address Translation and IP Forwarding

_Network Address Translation_, more commonly referred to as “NAT,” is a method by which a router accepts packets on one interface tagged with the sender’s IP address and then swaps out that address for that of the router. A record of this swap is kept in the router’s memory so that when return traffic comes back in the opposite direction, the router can translate the IP back to its original address. NAT is typically used to allow multiple computers to operate behind one publicly-exposed IP address, which comes in handy for a VPN service. An example of NAT in practice is the domestic router that your Internet Service Provider gave you to connect all the devices in your home to the internet. Your laptop, phone, tablets, and any other internet-enabled devices all appear to share the same public IP address to the internet, because your router is performing NAT.

Though NAT is typically conducted by a router, a server is also capable of performing it. Throughout this step, you will leverage this functionality in your ZeroTier server to enable its VPN capabilities.

_IP forwarding_ is a function performed by a router or server in which it forwards traffic from one interface to another if those IP addresses are in different zones. If a router was connected to two networks, IP forwarding allows it to forward traffic between them. This may sound simple, but it can be surprisingly complex to implement successfully. In the case of this tutorial, though, it’s just a matter of editing a few configuration files.

By enabling IP forwarding, the VPN traffic from your client in the ZeroTier network will arrive on the ZeroTier interface of the server. Without these configuration changes the Linux kernel will (by default) throw away any packets not destined for the interface they arrive on. This is normal behavior for the Linux kernel, since typically any packets arriving on an interface which have a destination address for another network could be caused by a routing misconfiguration elsewhere in the network.

It’s helpful to think of IP forwarding as informing the Linux kernel that it is acceptable to forward packets between interfaces. The default setting is `0` — equivalent to “Off”. You will toggle it to `1` — equivalent to “On”.

To see the current configuration, run the following command:

    sudo sysctl net.ipv4.ip_forward

    Outputnet.ipv4.ip_forward = 0

To enable IP forwarding, modify the `/etc/sysctl.conf` file on your server and add in the required line. This configuration file allows an administrator to override default kernel settings, and will always be applied after reboots so you don’t need to worry about setting it again. Use `nano` or your favorite text editor to add the following line to the bottom of the file.

    sudo nano /etc/sysctl.conf

/etc/sysctl.conf

    . . .
    net.ipv4.ip_forward = 1

Save and close the file, then run the next command to trigger the kernel’s adoption of the new configuration

    sudo sysctl -p

The server will adopt any new configuration directives within the file and apply them immediately, with no reboot required. Run the same command as you did earlier and you will see that IP forwarding is enabled.

    sudo sysctl net.ipv4.ip_forward

    Outputnet.ipv4.ip_forward = 1

Now that IP forwarding is enabled, you’ll make good use of it by providing the server with some basic routing rules. Since the Linux kernel already has a network routing capability embedded inside of it, all you’ll have to do is add some rules to tell the built-in firewall and router that the new traffic it will be seeing is acceptable and where to send it.

To add these rules from the command line, you will first need to know the names which Ubuntu has assigned to both your Zerotier interface and your regular internet-facing ethernet interface. These are typically `zt0` and `eth0` respectively, although this isn’t always the case.

To find these interfaces’ names, use the command `ip link show`. This command-line utility is part of `iproute2`, a collection of userspace utilities which comes installed on Ubuntu by default:

    ip link show

In the output of this command, the names of the interfaces are directly next to the numbers that identify a unique interface in the list. These interface names are highlighted in the following example output. If yours differs from the names shown in the example, then substitute your interface name appropriately throughout this guide.

    Output1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
        link/ether 72:2d:7e:6f:5e:08 brd ff:ff:ff:ff:ff:ff
    3: zt0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 2800 qdisc pfifo_fast state UNKNOWN mode DEFAULT group default qlen 1000
        link/ether be:82:8f:f3:b4:cd brd ff:ff:ff:ff:ff:ff

With that information in hand, use `iptables` to enable Network-Address-Translation and IP masquerading:

    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

Permit traffic forwarding and track active connections:

    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

Next, allow traffic forwarding from `zt0` to `eth0`. A reverse rule is not required since, in this tutorial, it is assumed that the client always calls out through the server, and not the other way around:

    sudo iptables -A FORWARD -i zt0 -o eth0 -j ACCEPT

It is important to remember that the iptables rules you’ve set for the server do not automatically persist between reboots. You will need to save these rules to ensure they are brought back into effect if the server is ever rebooted. On your server run the commands below, following the brief on-screen instructions to save current IPv4 rules, IPv6 is not required.

    sudo apt-get install iptables-persistent

    sudo netfilter-persistent save

After running `sudo netfilter-persistent save` it may be worthwhile to reboot your server to validate that the iptables rules were saved correctly. An easy way to check is run `sudo iptables-save`, which will dump the current configuration loaded in memory to your terminal. If you see rules similar to the ones below in regards to masquerading, forwarding, and the `zt0` interface, then they were correctly saved.

    sudo iptables-save

    Output# Generated by iptables-save v1.6.0 on Tue Apr 17 21:43:08 2018
    . . .
    -A POSTROUTING -o eth0 -j MASQUERADE
    COMMIT
    . . .
    -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A FORWARD -i zt0 -o eth0 -j ACCEPT
    COMMIT
    . . .

Now that these rules have been applied to your server, it is ready to juggle traffic between the ZeroTier network and the public internet. However, the VPN will not function unless the ZeroTier Network itself is informed that the server is ready to be used as a gateway.

### Enabling Your Server to Manage the Global Route

In order for your server to process traffic from any client, you must ensure that other clients in the ZeroTier network know to send their traffic to it. One can do this by setting a global route in the ZeroTier Console. People who are familiar with computer networks may also describe this as a _Default Route_. It’s where any client sends their default traffic, i.e. any traffic that shouldn’t go to any other specific location.

Go to the top-right of your ZeroTier Networks page and add a new route with the following parameters. You can find the ZeroTier IP for your server in the **Members** section of your ZeroTier Network configuration page. In the **network/bits** field, enter in `0.0.0.0/0`, in the **(LAN)** field, enter your ZeroTier server’s IP address.

When the details are in place, click the “ **+** ” symbol and you’ll see a new rule appear below the existing one. There will be an orange globe in it to convey that it is indeed a global route:

![Global Route Rule](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/zerotier-1604/zerotierGlobalRouteRule-updated.png)

With your ZeroTier network ready to go there is only one configuration left to be made before the VPN will function: that of the clients.

### Configuring Linux Clients

**Note: The commands in this section are only applicable to Linux clients. Instructions for configuring Windows or macOS clients are provided in the next section.**

If your client is running Linux, you will need to make a manual change to its `/etc/sysctl.conf` file. This configuration change is required to alter the kernel’s view of what an acceptable return path for your client traffic is. Due to the way that the ZeroTier VPN is configured, the traffic coming back from your server to your client can sometimes appear to come from a different network address than the one it was sent it to. By default, the Linux kernel views these as invalid and drops them, making it necessary to override that behavior.

Open `/etc/sysctl.conf` on your client machine:

    sudo nano /etc/sysctl.conf

Then add the following line:

    Output. . .
    
    net.ipv4.conf.all.rp_filter=2

Save and close the file, then run `sudo sysctl -p` to adopt the changes.

    sudo sysctl -p

Next, tell the ZeroTier Client software that your network is allowed to carry default route traffic. This amends the routing of the client and so is considered a privileged function, which is why it must be enabled manually. The command will print a configuration structure to the output. Check this to confirm that it shows `allowDefault=1` at the top:

    sudo zerotier-cli set NetworkID allowDefault=1

If at any point you wish to stop using ZeroTier as a VPN with all your traffic routing through it, set `allowDefault` back to `0`:

    sudo zerotier-cli set NetworkID allowDefault=0

Each time the ZeroTier service on the client is restarted, the `allowDefault=1` value gets reset to 0, so remember to re-execute it in order to activate the VPN functionality.

By default, the ZeroTier service is set to start automatically at boot for both the Linux client and the server. If you do not wish for this to be the case, you can disable the startup routine with the following command.

    sudo systemctl disable zerotier-one

If you’d like to use other Operating Systems on your ZeroTier network then read into the next section. Otherwise, skip ahead to the Managing Flows section.

### Configuring Non-Linux Clients

ZeroTier client software is available for many systems and not just for Linux OS’s — even smartphones are supported. Clients exist for Windows, macOS, Android, iOS and even specialized operating systems like QNAP, Synology and WesternDigital NAS systems.

To join macOS- and Windows-based clients to the network, launch the ZeroTier tool (which you installed in Step 1) and enter your NetworkID in the field provided before clicking **Join**. Remember to check back in the ZeroTier console to tick the **Allow** button to authorize a new host into your network.

Be certain to tick the box labeled **Route all traffic through ZeroTier**. If you do not, your client will be attached to your ZeroTier network but won’t bother trying to send its internet traffic across it.

Use an IP-checking tool such as [ICanHazIP](http://icanhazip.com/) to verify that your traffic is appearing to the internet from your server’s IP. To check this, paste the following URL into the address bar of your browser. This website will show the IP address that its server (and the rest of the internet) sees you using to access the site:

    http://icanhazip.com

With these steps completed you can start utilizing your VPN however you please. The next optional section covers a technology built into the ZeroTier SDN known as “flow rules,” but they are not in any way required for the VPN functionality to work.

## Step 6 — Managing Flows (Optional)

One of the benefits of a Software-Defined Network is the centralized controller. In respect to ZeroTier, the centralized controller is the Web User Interface which sits atop the overall ZeroTier SDN service. From this interface, it is possible to write rules known as _flow rules_ which specify what traffic on a network can or cannot do. For example, you could specify a blanket-ban on certain network ports carrying traffic over the network, limit which hosts can talk to one another, and even redirect traffic.

This is an extremely powerful capability which takes effect almost instantaneously, since any changes made to the flow table are pushed out to network members and take effect after only a few moments. To edit flow rules, go back to the ZeroTier Web User Interface, click on the **Networking** tab, and scroll down until you see a box entitled **Flow Rules** (it may be collapsed and need expanding). This opens a text field where you can enter whatever rules you’d like. A full manual is available within the ZeroTier console in a box just below the **Flow Rules** input box, entitled **Rules Engine Help**.

Here are some example rules to help you explore this functionality.

To block any traffic bound for Google’s `8.8.8.8` DNS server, add this rule:

    drop
        ipdest 8.8.8.8/32
    ;

To redirect any traffic bound for Google’s public DNS server to one of your ZeroTier nodes, add the following rule. This could be an excellent catch-all for overriding DNS lookups:

    redirect NetworkID
        ipdest 8.8.8.8/32
    ;

If your network has special security requirements, you can drop any activity on FTP ports, Telnet, and unencrypted HTTP by adding this rule:

    drop
        dport 80,23,21,20
    ;

When you’ve finished adding flow rules, click the **Save Changes** button and ZeroTier will record your changes.

## Conclusion

In this tutorial you’ve taken a first step into the world of Software-Defined Networking, and working with ZeroTier provides some insight into the benefits of this technology. If you followed the VPN example, then although the initial setup may contrast with other tools yo may have used in the past, the ease of adding additional clients could be a compelling reason to use the technology elsewhere.

To summarize, you learned how to use ZeroTier as an SDN provider, as well as configure and attach nodes to that network. The VPN element will have given you a deeper understanding of how routing within such a network operates, and either path in this tutorial will allow you to utilize the powerful flow rules technology.

Now that a point-to-point network exists, you could combine it with another functionality like File Sharing. If you have a NAS or file server at home you could link it up to ZeroTier and access it on-the-go. If you want to share it with your friends, you can show them how to join your ZeroTier network. Employees who are distributed over a large area could even link back to the same central storage space. To get started with building the file share for any of these examples, take a look at [How To Set Up a Samba Share For A Small Organization on Ubuntu 16.04](how-to-set-up-a-samba-share-for-a-small-organization-on-ubuntu-16-04).
