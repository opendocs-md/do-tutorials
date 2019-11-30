---
author: Justin Ellingwood
date: 2017-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-point-to-point-vpn-with-wireguard-on-ubuntu-16-04
---

# How To Create a Point-To-Point VPN with WireGuard on Ubuntu 16.04

## Introduction

[WireGuard](https://www.wireguard.com/) is a modern, high-performance VPN designed to be easy to use while providing robust security. WireGuard focuses only on providing a secure connection between parties over a network interface encrypted with public key authentication. This means that, unlike most VPNs, no topology is enforced so different configurations can be achieved by manipulating the surrounding networking configuration. This model offers great power and flexibility that can be applied according to your individual needs.

One of the simplest topologies that WireGuard can use is a point-to-point connection. This establishes a secure link between two machines without mediation by a central server. This type of connection can also be used between more than two members to establish a mesh VPN topology, where each individual server can talk to its peers directly. Because each host is on equal footing, these two topologies are best suited for establishing secure messaging between servers as opposed to using a single server as a gateway to route traffic through.

In this guide, we will demonstrate how to establish a point-to-point VPN connection with WireGuard using two Ubuntu 16.04 servers. We will start by installing the software and then generating cryptographic key pairs for each host. Afterwards, we will create a short configuration file to define the peer’s connection information. Once we start up the interface, we will be able to send secure messages between the servers over the WireGuard interface.

## Prerequisites

To follow along with this guide, you will need access to **two** Ubuntu 16.04 servers. On each server, you will need to create a non-root user with `sudo` privileges to perform administrative actions. You will also need a basic firewall configured on each system. You can fulfill these requirements by completing the following tutorial:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04)

When you are ready to continue, log into each server with your `sudo` user.

## Installing the Software

The WireGuard project provides a PPA with up-to-date packages for Ubuntu systems. We will need to install WireGuard on both of our servers before we can continue. On each server, perform the following actions.

First, add the WireGuard PPA to the system to configure access to the project’s packages:

    sudo add-apt-repository ppa:wireguard/wireguard

Press **ENTER** when prompted to add the new package source to your `apt` configuration. Once the PPA has been added, update the local package index to pull down information about the newly available packages and then install the WireGuard kernel module and userland components:

    sudo apt-get update
    sudo apt-get install wireguard-dkms wireguard-tools

Next, we can begin configuring WireGuard on each of our servers.

## Creating a Private Key

Each participant in a WireGuard VPN authenticates to its peers using public keys cryptography. Connections between new peers can be established by exchanging public keys and performing minimal configuration.

To generate a private key and write it directly to a WireGuard configuration file, type the following **on each server** :

    (umask 077 && printf "[Interface]\nPrivateKey = " | sudo tee /etc/wireguard/wg0.conf > /dev/null)
    wg genkey | sudo tee -a /etc/wireguard/wg0.conf | wg pubkey | sudo tee /etc/wireguard/publickey

The first command writes the initial contents of a configuration file to `/etc/wireguard/wg0.conf`. The `umask` value in a sub-shell so that we create the file with restricted permissions without affecting our regular environment.

The second command generates a private key using WireGuard’s `wg` command and writes it directly to our restricted configuration file. We also pipe the key back into the `wg pubkey` command to derive the associated public key, which we write to a file called `/etc/wireguard/publickey` for easy reference. We will need to exchange the key in this file with the second server as we define our configuration.

## Creating an Initial Configuration File

Next, we will open the configuration file in an editor to set up a few other details:

    sudo nano /etc/wireguard/wg0.conf

Inside, you should see your generated private key defined in a section called `[Interface]`. This section contains the configuration for the local side of the connection.

### Configuring the Interface Section

We need to define the VPN IP address this node will use and the port that it will listen on for connections from peers. Begin by adding `ListenPort` and `SaveConfig` lines so that your file looks like this:

/etc/wireguard/wg0.conf

    [Interface]
    PrivateKey = generated_private_key
    ListenPort = 5555
    SaveConfig = true

This sets the port that WireGuard will listen on. This can be any free, bindable port, but in this guide we will set up our VPN on port 5555 for both servers. Set the `ListenPort` on each host to the port you’ve selected:

We also set `SaveConfig` to `true`. This will tell the `wg-quick` service to automatically save its active configuration to this file at shutdown.

**Note:** When `SaveConfig` is enabled, the `wg-quick` service will overwrite the contents of the `/etc/wireguard/wg0.conf` file whenever the service shuts down. If you need to modify the WireGuard configuration, either shut down the `wg-quick` service prior to editing the `/etc/wireguard/wg0.conf` file or make the changes to the running service using the `wg` command (these will be be saved in the file when the service shuts down). Any changes made to the configuration file while the service is running will be overwritten when `wg-quick` stores its active configuration.

Next, add a unique `Address` definition to each server so that the `wg-quick` service can set the network information when it brings up the WireGuard interface. We will use the 10.0.0.0/24 subnet as the address space for our VPN. For each computer, you will need to pick a unique address within this range (10.0.0.1 to 10.0.0.254) and specify the address and subnet using [CIDR notation](understanding-ip-addresses-subnets-and-cidr-notation-for-networking).

We will give our **first server** an address of 10.0.0.1, which is represented as 10.0.0.1/24 in CIDR notation:

/etc/wireguard/wg0.conf on first server

    [Interface]
    PrivateKey = generated_private_key
    ListenPort = 5555
    SaveConfig = true
    Address = 10.0.0.1/24

On our **second server** , we will define the address as 10.0.0.2, which give us a CIDR representation of 10.0.0.2/24:

/etc/wireguard/wg0.conf on second server

    [Interface]
    PrivateKey = generated_private_key
    ListenPort = 5555
    SaveConfig = true
    Address = 10.0.0.2/24

This is the end of the `[Interface]` section.

We can enter the information about the server’s peers either within the configuration file or manually using the `wg` command later on. As mentioned above, the `wg-quick` service with the `SaveConfig` option set to `true` will mean that the peer information will eventually be written to the file with either method.

To demonstrate both ways of defining peer identities, we will create a `[Peer]` section in the second server’s configuration file but not the first. You can save and close the configuration file for the **first** server (the one defining the 10.0.0.1 address) now.

### Defining the Peer Section

In the configuration file that’s still open, create a section called `[Peer]` below the entries in the `[Interface]` section.

Begin by setting the `PublicKey` to the value of the _first_ server’s public key. You can find this value by typing `cat /etc/wireguard/publickey` on the opposite server. We will also set `AllowedIPs` to the IP addresses that are valid inside the tunnel. Since we know the specific IP address that the first server is using, we can input that directly, ending with `/32` to indicate a range that contains single IP value:

/etc/wireguard/wg0.conf on second server

    [Interface]
    . . .
    
    [Peer]
    PublicKey = public_key_of_first_server
    AllowedIPs = 10.0.0.1/32

Finally, we can set the `Endpoint` to the first server’s public IP address and the WireGuard listening port (we used port 5555 in this example). WireGuard will update this value if it receives legitimate traffic from this peer on another address, allowing the VPN to adapt to roaming conditions. We set the initial value so that this server can initiate contact:

/etc/wireguard/wg0.conf on second server

    [Interface]
    . . .
    
    [Peer]
    PublicKey = public_key_of_first_server
    AllowedIPs = 10.0.0.1/32
    Endpoint = public_IP_of_first_server:5555

When you are finished, save and close the file to return to the command prompt.

## Starting the VPN and Connecting to Peers

We’re now ready to start WireGuard on each server and configure the connection between our two peers.

### Opening the Firewall and Starting the VPN

First, open up the WireGuard port in the firewall on each server:

    sudo ufw allow 5555

Now, start the `wg-quick` service using the `wg0` interface file we defined:

    sudo systemctl start wg-quick@wg0

This will start of the `wg0` network interface on the machine. We can confirm this by typing:

    ip addr show wg0

    Output on first server6: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue state UNKNOWN group default qlen 1
        link/none 
        inet 10.0.0.1/24 scope global wg0
           valid_lft forever preferred_lft forever

We can use the `wg` tool to view information about the active configuration of the VPN:

    sudo wg

On the server without a peer definition, the display will look something like this:

    Output on first serverinterface: wg0
      public key: public_key_of_this_server
      private key: (hidden)
      listening port: 5555

On the server with a peer configuration already defined, the output will also contain that information:

    Output on second serverinterface: wg0
      public key: public_key_of_this_server
      private key: (hidden)
      listening port: 5555
    
    peer: public_key_of_first_server
      endpoint: public_IP_of_first_server:5555
      allowed ips: 10.0.0.1/32

To complete the connection, we now need to add the second server’s peering information to the first server using the `wg` command.

### Adding the Missing Peer Information on the Command Line

On the **first server** (the one that doesn’t display peer information), enter the peering information manually using the following format. The second server’s public key can be found in the output of `sudo wg` from the second server:

    sudo wg set wg0 peer public_key_of_second_server endpoint public_IP_of_second_server:5555 allowed-ips 10.0.0.2/32

You can confirm that the information is now in the active configuration by typing `sudo wg` again on the first server:

    sudo wg

    Output on first serverinterface: wg0
      public key: public_key_of_this_server
      private key: (hidden)
      listening port: 5555
    
    peer: public_key_of_second_server
      endpoint: public_IP_of_second_server:5555
      allowed ips: 10.0.0.2/32

Our point-to-point connection should now be available. Try pinging the VPN address of the second server from the first:

    ping -c 3 10.0.0.2

    Output on first serverPING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
    64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.635 ms
    64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=0.615 ms
    64 bytes from 10.0.0.2: icmp_seq=3 ttl=64 time=0.841 ms
    
    --- 10.0.0.2 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 1998ms
    rtt min/avg/max/mdev = 0.615/0.697/0.841/0.102 ms

If everything is working correctly, you can save the configuration on the first server back to the `/etc/wireguard/wg0.conf` file by restarting the service:

    sudo systemctl restart wg-quick@wg0

If you want to start the tunnel at boot, you can enable the service on each machine by typing:

    sudo systemctl enable wg-quick@wg0

The VPN tunnel should now be automatically started whenever the machine boots.

## Conclusion

WireGuard is a great option for many use cases due to its flexibility, light-weight implementation, and modern cryptography. In this guide, we installed WireGuard on two Ubuntu 16.04 servers and configured each host as a server with a point-to-point connection to its peer. This topology is ideal for establishing server-to-server communication with peers where each side is an equal participant or where hosts might have to establish ad-hoc connections to other servers.
