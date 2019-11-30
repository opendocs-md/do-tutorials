---
author: Mason Gravitt
date: 2013-09-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-traffic-between-vps-using-openvpn
---

# How To Secure Traffic Between VPS Using OpenVPN

## Introduction

OpenVPN is a great tool to ensure traffic is not eavesdropped. You can use this to ensure a secure connection from your laptop to your DigitalOcean VPS (droplet) as well as between cloud servers. You can also have both done simultaneously.

This is not a foolproof, definitive, perfectly-secure, life-depends-on-it set of instructions. We will be taking three shortcuts here, which in my opinion are reasonable tradeoffs between ease of use and security, but I, nor DigitalOcean can be held responsible for security of your VPS, even if you follow these instructions.

To quote a cryptography rock-star, _"You have to know what you are doing every step of the way, from conception through installation."_ — Bruce Schneier

This article is to help get you started on your way to setting up a Virtual Private Network. You have been warned. I'll point out the shortcuts taken and the general sequence to avoid making these shortcuts at Appendix 1.

If you only want to have two cloud servers to connect to each other, you may want to find a simpler (yet less secure) [tutorial](http://openvpn.net/index.php/open-source/documentation/miscellaneous/78-static-key-mini-howto.html) — though this is a good compromise between ease of setup and security.

**Note:** _This tutorial covers IPv4 security. In Linux, IPv6 security is maintained separately from IPv4. For example, "iptables" only maintains firewall rules for IPv4 addresses but it has an IPv6 counterpart called "ip6tables", which can be used to maintain firewall rules for IPv6 network addresses._

_If your VPS is configured for IPv6, please remember to secure both your IPv4 and IPv6 network interfaces with the appropriate tools. For more information about IPv6 tools, refer to this guide: [How To Configure Tools to Use IPv6 on a Linux VPS](how-to-configure-tools-to-use-ipv6-on-a-linux-vps)_

## Getting Started

You'll need at least two droplets or VPS for this OpenVPN setup, and will work up to around 60 VPS without major modifications. So to get started, create two droplets. For the rest of this tutorial, I'll refer to them as _Droplet 1_ and _Droplet 2_.

### On Droplet 1

• Create the droplet with Ubuntu 13.04 x32.

This should work without modification on any version of Ubuntu that DigitalOcean offers, but was only tested on 13.04.

Connect to the VPS via secure shell. We're going to update packages and install a few things.

`aptitude update && aptitude dist-upgrade -y && aptitude install openvpn firehol -y && reboot`

Note, if your shell goes purple during this, just choose "Install Package Maintainer's Version" twice.

### Meanwhile, on Droplet 2

• Create the droplet with Ubuntu 13.04 x32.

Again, this should work on any version of Ubuntu.

Connect to the VPS via secure shell. We're going to update packages in install a few things.

`aptitude update && aptitude dist-upgrade -y && aptitude install openvpn -y && reboot`

Again, if your shell goes purple during this, just choose "Install Package Maintainer's Version" twice.

## Generating the Keys

The key generation is going to be done exclusively on Droplet 1. Type the following commands into the shell:

    cd /etc/openvpn/ mkdir easy-rsa cd easy-rsa cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/\* . 

Next, we're going to type in some presets which will vastly speed up the key generation process. Type the following command:

    nano /etc/openvpn/easy-rsa/vars

Go ahead and edit the following values (you only need do to these, although there are several more present):

- &nbsp;&nbsp;_KEY\_COUNTRY_
- &nbsp;&nbsp;_KEY\_PROVINCE_
- &nbsp;&nbsp;_KEY\_CITY_
- &nbsp;&nbsp;_KEY\_ORG_ and
- &nbsp;&nbsp;_KEY\_EMAIL_

You may adjust the KEY\_SIZE to 2048 or higher for added protection.

Save and exit with Control-O, Enter, and Control-X.

## Create the Certificate Authority Certificate and Key

Next, type the following commands:

    source vars ./clean-all ./build-ca

You should be able to hit Enter though all of the questions.

**<small>Note: if you ever have to go back and create more keys, you'll need to retype <em><u>source vars</u></em> but <em>don't</em> type <em><u>./clean-all</u></em> or you'll erase your Certificate Authority, undermining your whole VPN setup.</small>**

## Create Server Certificate and Key

Generate the server certificate and key with the following command:

    ./build-key-server server

You should be able to hit Enter on defaults, but make sure the Common Name of the certificate is "server".

It will ask you to add a pass phrase, but just hit Enter without typing one.

When it asks you "Sign the certificate?", type _<u>y</u>_ and hit Enter.

When it says "1 out of 1 certificate requests certified, commit?", type _<u>y</u>_ and hit Enter.

## Generate Client Keys

Next is generating the certificate and keys for the clients. For security purposes, each client will get its own certificate and key.

I'm naming the first client "client1", so if you change this, you'll have to adjust it several times later. So type in the following:

    ./build-key client1

As with the server key, when it asks you "Sign the certificate?", type _<u>y</u>_ and hit Enter.

When it says "1 out of 1 certificate requests certified, commit?", type _<u>y</u>_ and hit Enter.

Go ahead and repeat this for as many clients as you need to make. You can also come back to this later (though remember to "source var" again if you do so).

## Generate Diffie-Hellman Parameters

This is used after authentication, to determine the encryption parameters. Simply type the following line:

    ./build-dh

## Copy Keys into Place

Next, we copy the various keys and certificates into place on the cloud server:

    cd /etc/openvpn/easy-rsa/keys cp ca.crt dh1024.pem server.crt server.key /etc/openvpn

It's very important that keys are kept secure. Double check that only root has permission to read. So type:

    ls -lah /etc/openvpn

What you're looking for is that _server.key_ has **-rw-------** for permissions (read/write for owner, none for group, and none everyone). If you need to change it, use this command:

    chmod 600 /etc/openvpn/server.key

## Distribute Client Certificate and Key

The following table shows which files go onto which client.

| client1 | client2 |
| --- | --- |
| ca.crt | ca.crt |
| client1.crt | client2.crt |
| client1.key <small><b>(SECRET)</b></small> | client2.key <small><b>(SECRET)</b></small> |

We'll securely copy the files to the second VPS using secure copy. (You could also cat, then copy and paste across SSH windows. But this is a nice technique to securely copy files.)

### On Droplet 1

Generate SSH keys with the following command:

    ssh-keygen -t rsa

It will choose a default filename and then ask you for a secure passphrase, which you should set. Find the SSH public key you just generated and type:

    cat ~/.ssh/id\_rsa.pub

Copy the results onto the clipboard. It's a few lines of letters and numbers looking like:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo249TgbI1gYP42RbLcDhsNN28r/fNT6ljdFOZxhk+05UAPhxq8bASaqSXZI3K8EEI3wSpigaceNUu65pxLEsZWS8xTtjY4AVxZU2w8GIlnFDSQYr3M2A77ZAq5DqyhGmnnB3cPsIJi5Q6JQNaQ/Meg1v7mYR9prfEENJeXrDiXjxUqi41NlVdb5ZQnPL1EdKM+KN/EPjiTD5XY1q4ICmLJUB8RkffHwH2knEcBoSZW2cNADpMu/IqtxTZpFL0I1eIEtoCWg4mGIdIo8Dj/nzjheFjavDhiqvUEImt1vWFPxHEXt79Iap/VQp/yc80fhr2UqXmxOa0XS7oSGGfFuXz root@openvpn1

But USE YOUR OWN, not mine. Your id\_rsa.pub doesn't need to be kept secure, but if you use the key above, that would allow me access to your VPS.

### Meanwhile, on Droplet 2

    cd ~/.ssh

(If you get an error, create the folder with `mkdir ~/.ssh`).

    nano authorized\_keys

Paste the public key that is in your clipboard onto a new line, then save and exit with Control-O, Enter, Control-X.

### Back to Droplet 1
 Next, we copy the appropriate keys onto the second server: 

    scp /etc/openvpn/easy-rsa/keys/ca.crt \ /etc/openvpn/easy-rsa/keys/client1.crt \ /etc/openvpn/easy-rsa/keys/client1.key \ root@droplet2ip:~/

It will ask you "Are you sure you want to continue connecting (yes/no)?", so type _yes_ and hit Enter.

Then input the passphrase you've just created.

### Switching again to Droplet 2

Next, we move the certificates and keys into their final location:

    cd ~ mv ca.crt client1.crt client1.key /etc/openvpn ls -l /etc/openvpn

As the key must be kept secure, let's make sure client1.key has the correct permissions ( **-rw-------** ).

Again, if need be, the permissions can be reset with the following command:

    chmod 600 /etc/openvpn/client1.key

## Networking

Next comes the excitement that is networking on a VPN. You can use OpenVPN using routing or bridging. If you know what the difference is, you don't need my help choosing. For this tutorial, we'll use routing. We'll also use OpenVPN's default network range, which is **10.8.0.0/24**. Unless you already use this network range somewhere, this will be fine. If you do need a different range, pick a private range and make sure you adjust all the later configuration steps accordingly.

### Droplet 1

On the OpenVPN server, we need to configure routing and setup a firewall as well. I use a tool called _firehol_ to configure iptables, which makes it very simple to set up a complex firewall. So, type the following commands:

    nano /etc/firehol/firehol.conf

While we could allow incoming OpenVPN connections from any address, we're going to limit these connections to the IP addresses of the computers you want to connect. Make this list of your IP addresses now.

Note: The following configuration only allows incoming SSH and OpenVPN connections. If you have other services that need to receive incoming connections, you'll need to modify the firewall to support these.

     version 5 interface eth0 inet client all accept // allow all outgoing connections server ssh accept // allow all incoming SSH connections server openvpn accept src "1.2.3.4 2.3.4.5" // allow incoming OpenVPN connections // from these designated addresses // NOTE: EDIT THESE ADDRESSES interface tun0 vpn server all accept // allow all incoming connections on the VPN client all accept // allow all outgoing connections on the router inet2vpn inface eth0 outface tun0 route all accept // route freely to the VPN router vpn2inet inface tun0 outface eth0 masquerade // use NAT masquerading from the VPN route all accept // route freely to the VPN 

Then, start the firewall with the following command:

    firehol start

If you have an issue with your firewall, you can restart your VPS and the firewall configuration will be cleared. To make the firewall permanent, input the following:

    nano /etc/default/firehol

Find the following line:

    START\_FIREHOL=NO

Now, change NO to YES. Save and exit with Control-O, Enter, Control-X.

## OpenVPN Server config files

### On Droplet 1

The next step is to copy the example server configuration into place and edit it to our needs.

    cd /etc/openvpn cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz . gunzip server.conf.gz nano /etc/openvpn/server.conf

The OpenVPN server will start as root, but we can set it to drop to lower privileges after startup, which is a good security measure. To configure this, find the following lines and uncomment them by removing the semicolons:

    ;user nobody ;group nogroup

If you have multiple servers that should communicate to each other, find the following line and remove the semicolon:

    ;client-to-client 

If you increased the key size of your DH key, find the line:

    dh dh1024.pem

and change 1024 to 2048 (or whatever number you selected).

We're going to assign the different clients static IP addresses from the OpenVPN server, so to do that, uncomment the following line:

    ;client-config-dir ccd

Save with Control-O, Enter, Control-X. Next, make the client configuration directory:

    mkdir /etc/openvpn/ccd

and we'll add configuration for the first client here:

    nano /etc/openvpn/ccd/client1

Type the following command, which assigns client1 to IP address, 10.8.0.5:

    ifconfig-push 10.8.0.5 10.8.0.6

Save and exit with Control-O, Enter, Control-X.

For reasons that require an in-depth knowledge of networking to understand, use the following addresses for additional clients:

**/etc/openvpn/ccd/client2** ifconfig-push 10.8.0.9 10.8.0.10

**/etc/openvpn/ccd/client3:** ifconfig-push 10.8.0.13 10.8.0.14

Simply, add 4 to each IP for each new set. A more technical explanation is at Appendix 2.

Now we can start the OpenVPN server with the following command:

    service openvpn start

Give it a second, then type the following commands to ensure OpenVPN is running:

    ifconfig

And among the network interfaces, you should see that the interface tun0 look like this:

    tun0 Link encap:UNSPEC HWaddr 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00 inet addr:10.8.0.1 P-t-P:10.8.0.2 Mask:255.255.255.255 UP POINTOPOINT RUNNING NOARP MULTICAST MTU:1500 Metric:1 RX packets:140 errors:0 dropped:0 overruns:0 frame:0 TX packets:149 errors:0 dropped:0 overruns:0 carrier:0 collisions:0 txqueuelen:100 RX bytes:13552 (13.5 KB) TX bytes:14668 (14.6 KB)

You can also type:

    service openvpn status

and if OpenVPN is running, you'll see the following:

     \* VPN 'server' is running

If both of these are in order, then the server is up and running and we'll configure the client connection next.

## OpenVPN Client Config Files

### On Droplet 2

First, let's copy the sample client configuration file to the proper locations:

    cd /etc/openvpn cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf .

 It's mostly configured, but we have to "tell" the address of our OpenVPN server, Droplet 1: 

    nano /etc/openvpn/client.conf

Find the line that says:

    remote my-server-1 1194

And change **my-server-1** to the IP address of Droplet 1. Next, we have to ensure that the client key and the certificate matches the actual file names. Search for the following lines:

    cert client.crt key client.key

and adjust them to the keys copied over (e.g. _client1.crt_ and _client1.key_).

Save and exit with Control-O, Enter, Control-X.

And next, let's start up the VPN:

    service openvpn start

 Again, we can test it with the following commands: 

    service openvpn status

    ifconfig

Now that both ends of the VPN are up, we should test the network. Use the following command:

    ping 10.8.0.1

And if successful, you should see something like:

    PING 10.8.0.1 (10.8.0.1) 56(84) bytes of data. 64 bytes from 10.8.0.1: icmp\_req=1 ttl=64 time=0.102 ms 64 bytes from 10.8.0.1: icmp\_req=2 ttl=64 time=0.056 ms

## Congratulations, You're Now Done!

Any traffic you do not need encrypted, you can connect via the public-facing IP address. Any traffic between cloud servers you want encrypted, connect to the Internet network address, e.g. Droplet 1 connect to **10.8.0.1**. Droplet 2 is **10.8.0.5** , Droplet 3 is **10.8.0.9** , and so on.

Encrypted traffic will be slower than unencrypted, especially if your cloud servers are in different datacenters, but either traffic methods are available simultaneously, so choose accordingly.

Also, now is a good time to learn more about OpenVPN and encryption in general. The [OpenVPN](http://openvpn.net/index.php/open-source.html) website has some good resources for this.

## Appendix 1

### Security

There were three shortcuts used here which if security is of the utmost importance, you should not do.

- First, the keys were all generated remotely on a virtual server that is both on the Internet and not fully under one's control. The most secure way of doing this is have the Certificate Authority keys generated on a standalone (not Internet-connected) computer in a secure location.
- Second, the keys were transmitted rather than generated in place. SSH provides a reasonably secure method of transmitting files but there are [various](http://www.schneier.com/blog/archives/2008/05/random_number_b.html) [instances](https://www.digitalocean.com/blog_posts/avoid-duplicate-ssh-host-keys) where SSH has not been fully secure. If you were to generate in host, transfer the CSRs to your offline CA, sign them there, then transmit the signed requests back, this would be more secure.
- Third, no passphrases were assigned to the keys. As these are servers and will likely need to reboot unattended, this tradeoff was made.

Additionally, OpenVPN supports loads of other hardening features, beyond the scope of this tutorial. Reading up at openvpn.org should be done.

<small> <a href="#t1">back</a></small>
## Appendix 2 

### A note on networking

So the first client will use 10.8.0.6 as its IP address, and 10.8.0.5 is the VPN tunnel endpoint. The second address is only used to route traffic through the tunnel. This is because each client uses a CIDR /30 network, meaning 4 IP addresses are used per client computer.

So the VPN server will use the 10.8.0.0/30 network:

| 10.8.0.0 | Network |
| 10.8.0.1 | Server IP address |
| 10.8.0.2 | Tunnel Endpoint |
| 10.8.0.3 | Broadcast |

And the first client, client1, will use the 10.8.0.4/30 network:

| 10.8.0.4 | Network |
| 10.8.0.5 | Server IP address |
| 10.8.0.6 | Tunnel Endpoint |
| 10.8.0.7 | Broadcast |

And so on...

<small> <a href="#t2">back</a></small>