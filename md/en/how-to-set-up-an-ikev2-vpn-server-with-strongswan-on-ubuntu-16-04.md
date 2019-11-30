---
author: Namo
date: 2017-02-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04
---

# How to Set Up an IKEv2 VPN Server with StrongSwan on Ubuntu 16.04

## Introduction

A virtual private network, or VPN, allows you to securely encrypt traffic as it travels through untrusted networks, such as those at the coffee shop, a conference, or an airport.

[IKEv2](https://en.wikipedia.org/wiki/Internet_Key_Exchange), or Internet Key Exchange v2, is a protocol that allows for direct IPSec tunneling between the server and client. In IKEv2 VPN implementations, IPSec provides encryption for the network traffic. IKEv2 is natively supported on new platforms (OS X 10.11+, iOS 9.1+, and Windows 10) with no additional applications necessary, and it handles client hiccups quite smoothly.

In this tutorial, you’ll set up an IKEv2 VPN server using [StrongSwan](https://www.strongswan.org/) on an Ubuntu 16.04 server and connect to it from Windows, iOS, and macOS clients.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 16.04 server with multiple CPUs, configured by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

In addition, you should be familiar with IPTables. Review [How the Iptables Firewall Works](how-the-iptables-firewall-works) before you proceed.

## Step 1 — Installing StrongSwan

First, we’ll install StrongSwan, an open-source IPSec daemon which we’ll configure as our VPN server. We’ll also install the StrongSwan EAP plugin, which allows password authentication for clients, as opposed to certificate-based authentication. We’ll need to create some special firewall rules as part of this configuration, so we’ll also install a utility which allows us to make our new firewall rules persistent.

Execute the following command to install these components:

    sudo apt-get install strongswan strongswan-plugin-eap-mschapv2 moreutils iptables-persistent

**Note** : While installing `iptables-persistent`, the installer will ask whether or not to save current IPv4 and IPv6 rules. As we want any previous firewall configurations to stay the same, we’ll select yes on both prompts.

Now that everything’s installed, let’s move on to creating our certificates:

## Step 2 — Creating a Certificate Authority

An IKEv2 server requires a certificate to identify itself to clients. To help us create the certificate required, StrongSwan comes with a utility to generate a certificate authority and server certificates. To begin, let’s create a directory to store all the stuff we’ll be working on.

    mkdir vpn-certs
    cd vpn-certs

Now that we have a directory to store everything, let’s generate our root key. This will be a 4096-bit RSA key that will be used to sign our root certificate authority, so it’s very important that we also secure this key by ensuring that only the **root** user can read it.

Execute these commands to generate and secure the key:

    ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem
    chmod 600 server-root-key.pem

Now that we have a key, we can move on to creating our root certificate authority, using the key to sign the root certificate:

    ipsec pki --self --ca --lifetime 3650 \
    --in server-root-key.pem \
    --type rsa --dn "C=US, O=VPN Server, CN=VPN Server Root CA" \
    --outform pem > server-root-ca.pem

You can change the _distinguished name_ (DN) values, such as country, organization, and common name, to something else to if you want to. The common name here is just the indicator, so you could even make something up.

Later, we’ll copy the root certificate (`server-root-ca.pem`) to our client devices so they can verify the authenticity of the server when they connect.

Now that we’ve got our root certificate authority up and running, we can create a certificate that the VPN server will use.

## Step 3 — Generating a Certificate for the VPN Server

We’ll now create a certificate and key for the VPN server. This certificate will allow the client to verify the server’s authenticity.

First, create a private key for the VPN server with the following command:

    ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem

Then create and sign the VPN server certificate with the certificate authority’s key you created in the previous step. Execute the following command, but change the Common Name (CN) and the Subject Alternate Name (SAN) field to your VPN server’s DNS name or IP address:

    ipsec pki --pub --in vpn-server-key.pem \
    --type rsa | ipsec pki --issue --lifetime 1825 \
    --cacert server-root-ca.pem \
    --cakey server-root-key.pem \
    --dn "C=US, O=VPN Server, CN=server_name_or_ip" \
    --san server_name_or_ip \
    --flag serverAuth --flag ikeIntermediate \
    --outform pem > vpn-server-cert.pem

Copy the certificates to a path which would allow StrongSwan to read the certificates:

    sudo cp ./vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
    sudo cp ./vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem

Finally, secure the keys so they can only be read by the **root** user.

    sudo chown root /etc/ipsec.d/private/vpn-server-key.pem
    sudo chgrp root /etc/ipsec.d/private/vpn-server-key.pem
    sudo chmod 600 /etc/ipsec.d/private/vpn-server-key.pem

In this step, we’ve created a certificate pair that would be used to secure communications between the client and the server. We’ve also signed the certificates with our root key, so the client will be able to verify the authenticity of the VPN server. Now that we’ve got all the certificates ready, we’ll move on to configuring the software.

## Step 4 — Configuring StrongSwan

We’ve already created all the certificates that we need, so it’s time to configure StrongSwan itself.

StrongSwan has a default configuration file, but before we make any changes, let’s back it up first so that we’ll have a reference file just in case something goes wrong:

    sudo cp /etc/ipsec.conf /etc/ipsec.conf.original

The example file is quite long, so to prevent misconfiguration, we’ll clear the default configuration file and write our own configuration from scratch. First, clear out the original configuration:

    echo '' | sudo tee /etc/ipsec.conf

Then open the file in your text editor:

    sudo nano /etc/ipsec.conf

First, we’ll tell StrongSwan to log daemon statuses for debugging and allow duplicate connections. Add these lines to the file:

/etc/ipsec.conf

    config setup
      charondebug="ike 1, knl 1, cfg 0"
      uniqueids=no

Then, we’ll create a configuration section for our VPN. We’ll also tell StrongSwan to create IKEv2 VPN Tunnels and to automatically load this configuration section when it starts up. Append the following lines to the file:

/etc/ipsec.conf

    conn ikev2-vpn
      auto=add
      compress=no
      type=tunnel
      keyexchange=ikev2
      fragmentation=yes
      forceencaps=yes

Next, we’ll tell StrongSwan which encryption algorithms to use for the VPN. Append these lines:

/etc/ipsec.conf

      ike=aes256-sha1-modp1024,3des-sha1-modp1024!
      esp=aes256-sha1,3des-sha1!

We’ll also configure dead-peer detection to clear any “dangling” connections in case the client unexpectedly disconnects. Add these lines:

/etc/ipsec.conf

      dpdaction=clear
      dpddelay=300s
      rekey=no

Then we’ll configure the server (left) side IPSec parameters. Add this to the file:

/etc/ipsec.conf

      left=%any
      leftid=@server_name_or_ip
      leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
      leftsendcert=always
      leftsubnet=0.0.0.0/0

**Note** : When configuring the server ID (`leftid`), only include the `@` character if your VPN server will be identified by a domain name:

      leftid=@vpn.example.com

If the server will be identified by its IP address, just put the IP address in:

      leftid=111.111.111.111

Then we configure the client (right) side IPSec parameters, like the private IP address ranges and DNS servers to use:

/etc/ipsec.conf

      right=%any
      rightid=%any
      rightauth=eap-mschapv2
      rightsourceip=10.10.10.0/24
      rightdns=8.8.8.8,8.8.4.4
      rightsendcert=never

Finally, we’ll tell StrongSwan to ask the client for user credentials when they connect:

/etc/ipsec.conf

      eap_identity=%identity

The configuration file should look like this:

/etc/ipsec.conf

    config setup
        charondebug="ike 1, knl 1, cfg 0"
        uniqueids=no
    
    conn ikev2-vpn
        auto=add
        compress=no
        type=tunnel
        keyexchange=ikev2
        fragmentation=yes
        forceencaps=yes
        ike=aes256-sha1-modp1024,3des-sha1-modp1024!
        esp=aes256-sha1,3des-sha1!
        dpdaction=clear
        dpddelay=300s
        rekey=no
        left=%any
        leftid=@server_name_or_ip
        leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
        leftsendcert=always
        leftsubnet=0.0.0.0/0
        right=%any
        rightid=%any
        rightauth=eap-mschapv2
        rightdns=8.8.8.8,8.8.4.4
        rightsourceip=10.10.10.0/24
        rightsendcert=never
        eap_identity=%identity

Save and close the file once you’ve verified that you’ve configured things as shown.

Now that we’ve configured the VPN parameters, let’s move on to creating an account so our users can connect to the server.

## Step 5 — Configuring VPN Authentication

Our VPN server is now configured to accept client connections, but we don’t have any credentials configured yet, so we’ll need to configure a couple things in a special configuration file called `ipsec.secrets`:

- We need to tell StrongSwan where to find the private key for our server certificate, so the server will be able to encrypt and decrypt data.
- We also need to set up a list of users that will be allowed to connect to the VPN.

Let’s open the secrets file for editing:

    sudo nano /etc/ipsec.secrets

First, we’ll tell StrongSwan where to find our private key.

/etc/ipsec.secrets

    server_name_or_ip : RSA "/etc/ipsec.d/private/vpn-server-key.pem"

Then we’ll create the user credentials. You can make up any username or password combination that you like, but we have to tell StrongSwan to allow this user to connect from anywhere:

/etc/ipsec.secrets

    your_username %any% : EAP "your_password"

Save and close the file. Now that we’ve finished working with the VPN parameters, we’ll reload the VPN service so that our configuration would be applied:

    sudo ipsec reload

Now that the VPN server has been fully configured with both server options and user credentials, it’s time to move on to configuring the most important part: the firewall.

## Step 6 — Configuring the Firewall & Kernel IP Forwarding

Now that we’ve got the VPN server configured, we need to configure the firewall to forward and allow VPN traffic through. We’ll use IPTables for this.

First, disable UFW if you’ve set it up, as it can conflict with the rules we need to configure:

    sudo ufw disable

Then remove any remaining firewall rules created by UFW:

    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -F
    iptables -Z

To prevent us from being locked out of the SSH session, we’ll accept connections that are already accepted. We’ll also open port `22` (or whichever port you’ve configured) for future SSH connections to the server. Execute these commands:

    sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

We’ll also need to accept connections on the local loopback interface:

    sudo iptables -A INPUT -i lo -j ACCEPT

Then we’ll tell IPTables to accept IPSec connections:

    sudo iptables -A INPUT -p udp --dport 500 -j ACCEPT
    sudo iptables -A INPUT -p udp --dport 4500 -j ACCEPT

Next, we’ll tell IPTables to forward [ESP](https://wiki.wireshark.org/ESP) (Encapsulating Security Payload) traffic so the VPN clients will be able to connect. ESP provides additional security for our VPN packets as they’re traversing untrusted networks:

    sudo iptables -A FORWARD --match policy --pol ipsec --dir in --proto esp -s 10.10.10.10/24 -j ACCEPT
    sudo iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.10/24 -j ACCEPT

Our VPN server will act as a gateway between the VPN clients and the internet. Since the VPN server will only have a single public IP address, we will need to configure masquerading to allow the server to request data from the internet on behalf of the clients; this will allow traffic to flow from the VPN clients to the internet, and vice-versa:

    sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -j MASQUERADE

To prevent IP packet fragmentation on some clients, we’ll tell IPTables to reduce the size of packets by adjusting the packets’ maximum segment size. This prevents issues with some VPN clients.

    sudo iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.10/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

For better security, we’ll drop everything else that does not match the rules we’ve configured:

    sudo iptables -A INPUT -j DROP
    sudo iptables -A FORWARD -j DROP

Now we’ll make the firewall configuration persistent, so that all our configuration work won’t get wiped on reboot:

    sudo netfilter-persistent save
    sudo netfilter-persistent reload

Finally, we’ll enable packet forwarding on the server. Packet forwarding is what makes it possible for our server to “route” data from one IP address to the other. Essentially, we’re making our server act like a router.

Edit the file `/etc/sysctl.conf`:

    sudo nano /etc/sysctl.conf

We’ll need to configure a few things here:

- First, we’ll enable IPv4 packet forwarding.
- We’ll disable Path MTU discovery to prevent packet fragmentation problems.
- We also won’t accept ICMP redirects nor send ICMP redirects to prevent [man-in-the-middle](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) attacks.

The changes you need to make to the file are highlighted in the following code:

/etc/sysctl.conf

    
    . . .
    
    # Uncomment the next line to enable packet forwarding for IPv4
    net.ipv4.ip_forward=1
    
    . . .
    
    # Do not accept ICMP redirects (prevent MITM attacks)
    net.ipv4.conf.all.accept_redirects = 0
    # Do not send ICMP redirects (we are not a router)
    net.ipv4.conf.all.send_redirects = 0
    
    . . .
    
    net.ipv4.ip_no_pmtu_disc = 1

Make those changes, save the file, and exit the editor. Then restart the server:

    sudo reboot

You’ll get disconnected from the server as it reboots, but that’s expected. After the server reboots, log back in to the server as the sudo, non-root user. You’re ready to test the connection on a client.

## Step 7 – Testing the VPN Connection on Windows, iOS, and macOS

Now that you have everything set up, it’s time to try it out. First, you’ll need to copy the root certificate you created and install it on your client device(s) that will connect to the VPN. The easiest way to do this is to log into your server and execute this command to display the contents of the certificate file:

    cat ~/vpn-certs/server-root-ca.pem

You’ll see output similar to this:

    Output-----BEGIN CERTIFICATE-----
    MIIFQjCCAyqgAwIBAgIIFkQGvkH4ej0wDQYJKoZIhvcNAQEMBQAwPzELMAkGA1UE
    
    . . .
    
    EwbVLOXcNduWK2TPbk/+82GRMtjftran6hKbpKGghBVDPVFGFT6Z0OfubpkQ9RsQ
    BayqOb/Q
    -----END CERTIFICATE-----

Copy this output to your computer, including the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----` lines, and save it to a file with a recognizable name, such as `vpn_root_certificate.pem`. Ensure the file you create has the `.pem` extension.

Alternatively, [use SFTP to transfer the file to your computer](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server).

Once you have the `vpn_root_certificate.pem` file downloaded to your computer, you can set up the connection to the VPN.

### Connecting from Windows

First, import the root certificate by following these steps:

1. Press `WINDOWS+R` to bring up the **Run** dialog, and enter `mmc.exe` to launch the Windows Management Console.
2. From the **File** menu, navigate to **Add or Remove Snap-in** , select **Certificates** from the list of available snap-ins, and click **Add**.
3. We want the VPN to work with any user, so select **Computer Account** and click **Next**.
4. We’re configuring things on the local computer, so select **Local Computer** , then click **Finish**.
5. Under the **Console Root** node, expand the **Certificates (Local Computer)** entry, expand **Trusted Root Certification Authorities** , and then select the **Certificates** entry:  
 ![Certificates view](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ikevpn_ubuntu_1604/4PN0vT6.png)

6. From the **Action** menu, select **All Tasks** and click **Import** to display the Certificate Import Wizard. Click **Next** to move past the introduction.

7. On the **File to Import** screen, press the **Browse** button and select the certificate file that you’ve saved. Then click **Next**.

8. Ensure that the **Certificate Store** is set to **Trusted Root Certification Authorities** , and click **Next**.

9. Click **Finish** to import the certificate.

Then configure the VPN with these steps:

1. Launch **Control Panel** , then navigate to the **Network and Sharing Center**.
2. Click on **Set up a new connection or network** , then select **Connect to a workplace**.
3. Select **Use my Internet connection (VPN)**.
4. Enter the VPN server details. Enter the server’s domain name or IP address in the **Internet address** field, then fill in **Destination name** with something that describes your VPN connection. Then click **Done**.

Your new VPN connection will be visible under the list of networks. Select the VPN and click **Connect**. You’ll be prompted for your username and password. Type them in, click **OK** , and you’ll be connected.

### Connecting from iOS

To configure the VPN connection on an iOS device, follow these steps:

1. Send yourself an email with the root certificate attached.
2. Open the email on your iOS device and tap on the attached certificate file, then tap **Install** and enter your passcode. Once it installs, tap **Done**.
3. Go to **Settings** , **General** , **VPN** and tap **Add VPN Configuration**. This will bring up the VPN connection configuration screen.
4. Tap on **Type** and select **IKEv2**.
5. In the **Description** field, enter a short name for the VPN connection. This could be anything you like.
6. In the **Server** and **Remote ID** field, enter the server’s domain name or IP address. The **Local ID** field can be left blank.
7. Enter your username and password in the **Authentication** section, then tap **Done**.
8. Select the VPN connection that you just created, tap the switch on the top of the page, and you’ll be connected.

### Connecting from macOS

Follow these steps to import the certificate:

1. Double-click the certificate file. **Keychain Access** will pop up with a dialog that says “Keychain Access is trying to modify the system keychain. Enter your password to allow this.”
2. Enter your password, then click on **Modify Keychain**
3. Double-click the newly imported VPN certificate. This brings up a small properties window where you can specify the trust levels. Set **IP Security (IPSec)** to **Always Trust** and you’ll be prompted for your password again. This setting saves automatically after entering the password.

Now that the certificate is important and trusted, configure the VPN connection with these steps:

1. Go to **System Preferences** and choose **Network**. 
2. Click on the small “plus” button on the lower-left of the list of networks.
3. In the popup that appears, Set **Interface** to **VPN** , set the **VPN Type** to **IKEv2** , and give the connection a name.
4. In the **Server** and **Remote ID** field, enter the server’s domain name or IP address. Leave the **Local ID** blank.
5. Click on **Authentication Settings** , select **Username** , and enter your username and password you configured for your VPN user. Then click **OK**.

Finally, click on **Connect** to connect to the VPN. You should now be connected to the VPN.

### Troubleshooting Connections

If you are unable to import the certificate, ensure the file has the `.pem` extention, and not `.pem.txt`.

If you’re unable to connect to the VPN, check the server name or IP address you used. The server’s domain name or IP address must match what you’ve configured as the common name (CN) while creating the certificate. If they don’t match, the VPN connection won’t work. If you set up a certificate with the CN of `vpn.example.com`, you _must_ use `vpn.example.com` when you enter the VPN server details. Double-check the command you used to generate the certificate, and the values you used when creating your VPN connection.

Finally, double-check the VPN configuration to ensure the `leftid` value is configured with the `@` symbol if you’re using a domain name:

      leftid=@vpn.example.com

And if you’re using an IP address, ensure that the `@` symbol is omitted.

## Conclusion

In this tutorial, you’ve built a VPN server that uses the IKEv2 protocol. Now you can be assured that your online activities will remain secure wherever you go!

To add or remove users, just take a look at Step 5 again. Each line is for one user, so adding or removing users is as simple as editing the file.

From here, you might want to look into setting up a log file analyzer, because StrongSwan dumps its logs into syslog. The tutorial &nbsp;[How To Install and Use Logwatch Log Analyzer and Reporter on a VPS](how-to-install-and-use-logwatch-log-analyzer-and-reporter-on-a-vps) has more information on setting that up.

You might also be interested in [this guide from the EFF about online privacy](https://www.eff.org/wp/effs-top-12-ways-protect-your-online-privacy).
