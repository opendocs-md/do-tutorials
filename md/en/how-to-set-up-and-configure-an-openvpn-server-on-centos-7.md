---
author: Jacob Tomlinson
date: 2014-12-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-centos-7
---

# How To Set Up and Configure an OpenVPN Server on CentOS 7

## Introduction

A [Virtual Private Network](https://en.wikipedia.org/wiki/Virtual_private_network) (VPN) allows you to traverse untrusted networks as if you were on a private network. It gives you the freedom to access the internet safely and securely from your smartphone or laptop when connected to an untrusted network, like the WiFi at a hotel or coffee shop.

When combined with [HTTPS connections](https://en.wikipedia.org/wiki/HTTP_Secure), this setup allows you to secure your wireless logins and transactions. You can circumvent geographical restrictions and censorship, and shield your location and any unencrypted HTTP traffic from the untrusted network.

[OpenVPN](https://openvpn.net) is a full featured, open-source Secure Socket Layer (SSL) VPN solution that accommodates a wide range of configurations. In this tutorial, you will set up OpenVPN on a CentOS 7 server, and then configure it to be accessible from a client machine.

**Note:** If you plan to set up an OpenVPN server on a DigitalOcean Droplet, be aware that we, like many hosting providers, charge for bandwidth overages. For this reason, please be mindful of how much traffic your server is handling.

See [this page](https://www.digitalocean.com/docs/accounts/billing/bandwidth/) for more info.

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server with a sudo non-root user and a firewall set up with firewalld, which you can achieve with our [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) guide and the [Additional Recommended Steps for New CentOS 7 Servers](additional-recommended-steps-for-new-centos-7-servers).

- A domain or subdomain that resolves to your server that you can use for the certificates. To set this up, you will first need to [register a domain name](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) and then [add a DNS record via the DigitalOcean Control Panel](how-to-set-up-a-host-name-with-digitalocean). Note that just adding an A record will meet the requirements of this tutorial.

- A client machine which you will use to connect to your OpenVPN server. For the purposes of this tutorial, it’s recommend that you use your local machine as the OpenVPN client.

With these prerequisites in place, you are ready to begin setting up and configuring an OpenVPN server on CentOS 7.

## Step 1 — Installing OpenVPN

To start, we will install OpenVPN on the server. We’ll also install Easy RSA, a public key infrastructure management tool which will help us set up an internal certificate authority (CA) for use with our VPN. We’ll also use Easy RSA to generate our SSL key pairs later on to secure the VPN connections.

Log in to the server as the non-root sudo user, and update the package lists to make sure you have all the latest versions.

    sudo yum update -y

The Extra Packages for Enterprise Linux (EPEL) repository is an additional repository managed by the Fedora Project containing non-standard but popular packages. OpenVPN isn’t available in the default CentOS repositories but it is available in EPEL, so install EPEL:

    sudo yum install epel-release -y

Then update your package lists once more:

    sudo yum update -y

Next, install OpenVPN and `wget`, which we will use to install Easy RSA:

    sudo yum install -y openvpn wget

Using `wget`, download Easy RSA. For the purposes of this tutorial, we recommend using easy-rsa-2 because there’s more available documentation for this version. You can find the download link for the latest version of easy-rsa-2 on the project’s [Releases page](https://github.com/OpenVPN/easy-rsa-old/releases):

    wget -O /tmp/easyrsa https://github.com/OpenVPN/easy-rsa-old/archive/2.3.3.tar.gz

Next, extract the compressed file with `tar`:

    tar xfz /tmp/easyrsa

This will create a new directory on your server called `easy-rsa-old-2.3.3`. Make a new subdirectory under `/etc/openvpn` and name it `easy-rsa`:

    sudo mkdir /etc/openvpn/easy-rsa

Copy the extracted Easy RSA files over to the new directory:

    sudo cp -rf easy-rsa-old-2.3.3/easy-rsa/2.0/* /etc/openvpn/easy-rsa

Then change the directory’s owner to your non-root sudo user:

    sudo chown sammy /etc/openvpn/easy-rsa/

Once these programs are installed and have been moved to the right locations on your system, the next step is to customize the server-side configuration of OpenVPN.

## Step 2 — Configuring OpenVPN

Like many other widely-used open-source tools, there are dozens of configuration options available to you. In this section, we will provide instructions on how to set up a basic OpenVPN server configuration.

OpenVPN has several example configuration files in its documentation directory. First, copy the sample `server.conf` file as a starting point for your own configuration file.

    sudo cp /usr/share/doc/openvpn-2.4.4/sample/sample-config-files/server.conf /etc/openvpn

Open the new file for editing with the text editor of your choice. We’ll use nano in our example, which you can download with the `yum install nano` command if you don’t have it on your server already:

    sudo nano /etc/openvpn/server.conf

There are a few lines we need to change in this file, most of which just need to be uncommented by removing the semicolon, `;`, at the beginning of the line. The functions of these lines, and the other lines not mentioned in this tutorial, are explained in-depth in the comments above each one.

To get started, find and uncomment the line containing `push "redirect-gateway def1 bypass-dhcp"`. Doing this will tell your client to redirect all of its traffic through your OpenVPN server. Be aware that enabling this functionality can cause connectivity issues with other network services, like SSH:

/etc/openvpn/server.conf

    push "redirect-gateway def1 bypass-dhcp"

Because your client will not be able to use the default DNS servers provided by your ISP (as its traffic will be rerouted), you need to tell it which DNS servers it can use to connect to OpenVPN. You can pick different DNS servers, but here we’ll use Google’s public DNS servers which have the IPs of `8.8.8.8` and `8.8.4.4`.

Set this by uncommenting both `push "dhcp-option DNS ..."` lines and updating the IP addresses:

/etc/openvpn/server.conf

    push "dhcp-option DNS 8.8.8.8"
    push "dhcp-option DNS 8.8.4.4"

We want OpenVPN to run with no privileges once it has started, so we need to tell it to run with a user and group of **nobody**. To enable this, uncomment the `user nobody` and `group nobody` lines:

/etc/openvpn/server.conf

    user nobody
    group nobody

Next, uncomment the `topology subnet` line. This, along with the `server 10.8.0.0 255.255.255.0` line below it, configures your OpenVPN installation to function as a subnetwork and tells the client machine which IP address it should use. In this case, the server will become `10.8.0.1` and the first client will become `10.8.0.2`:

/etc/openvpn/server.conf

    topology subnet

It’s also recommended that you add the following line to your server configuration file. This double checks that any incoming client certificates are truly coming from a client, hardening the security parameters we will establish in later steps:

/etc/openvpn/server.conf

    remote-cert-eku "TLS Web Client Authentication"

Lastly, OpenVPN strongly recommends that users enable TLS Authentication, a cryptographic protocol that ensures secure communications over a computer network. To do this, you will need to generate a static encryption key (named in our example as `myvpn.tlsauth`, although you can choose any name you like). Before creating this key, comment the line in the configuration file containing `tls-auth ta.key 0` by prepending it with a semicolon. Then, add `tls-crypt myvpn.tlsauth` to the line below it:

/etc/openvpn/server.conf

    ;tls-auth ta.key 0
    tls-crypt myvpn.tlsauth

Save and exit the OpenVPN server configuration file (in nano, press `CTRL - X`, `Y`, then `ENTER` to do so), and then generate the static encryption key with the following command:

    sudo openvpn --genkey --secret /etc/openvpn/myvpn.tlsauth

Now that your server is configured, you can move on to setting up the SSL keys and certificates needed to securely connect to your VPN connection.

## Step 3 — Generating Keys and Certificates

Easy RSA uses a set of scripts that come installed with the program to generate keys and certificates. In order to avoid re-configuring every time you need to generate a certificate, you can modify Easy RSA’s configuration to define the default values it will use for the certificate fields, including your country, city, and preferred email address.

We’ll begin our process of generating keys and certificates by creating a directory where Easy RSA will store any keys and certs you generate:

    sudo mkdir /etc/openvpn/easy-rsa/keys

The default certificate variables are set in the `vars` file in `/etc/openvpn/easy-rsa`, so open that file for editing:

    sudo nano /etc/openvpn/easy-rsa/vars

Scroll to the bottom of the file and change the values that start with `export KEY_` to match your information. The ones that matter the most are:

- `KEY_CN`: Here, enter the domain or subdomain that resolves to your server.
- `KEY_NAME`: You should enter `server` here. If you enter something else, you would also have to update the configuration files that reference `server.key` and `server.crt`.

The other variables in this file that you may want to change are:

- `KEY_COUNTRY`: For this variable, enter the two-letter abbreviation of the country of your residence.
- `KEY_PROVINCE`: This should be the name or abbreviation of the state of your residence.
- `KEY_CITY`: Here, enter the name of the city you live in.
- `KEY_ORG`: This should be the name of your organization or company. 
- `KEY_EMAIL`: Enter the email address that you want to be connected to the security certificate.
- `KEY_OU`: This should be the name of the “Organizational Unit” to which you belong, typically either the name of your department or team.

The rest of the variables can be safely ignored outside of specific use cases. After you’ve made your changes, the file should look like this:

/etc/openvpn/easy-rsa/vars

    . . .
    
    # These are the default values for fields
    # which will be placed in the certificate.
    # Don't leave any of these fields blank.
    export KEY_COUNTRY="US"
    export KEY_PROVINCE="NY"
    export KEY_CITY="New York"
    export KEY_ORG="DigitalOcean"
    export KEY_EMAIL="sammy@example.com"
    export KEY_EMAIL=sammy@example.com
    export KEY_CN=openvpn.example.com
    export KEY_NAME="server"
    export KEY_OU="Community"
    . . .

Save and close the file.

To start generating the keys and certificates, move into the `easy-rsa` directory and `source` in the new variables you set in the `vars` file:

    cd /etc/openvpn/easy-rsa
    source ./vars

Run Easy RSA’s `clean-all` script to remove any keys and certificates already in the folder and generate the certificate authority:

    ./clean-all

Next, build the certificate authority with the `build-ca` script. You’ll be prompted to enter values for the certificate fields, but if you set the variables in the `vars` file earlier, all of your options will already be set as the defaults. You can press `ENTER` to accept the defaults for each one:

    ./build-ca

This script generates a file called `ca.key`. This is the private key used to sign your server and clients’ certificates. If it is lost, you can no longer trust any certificates from this certificate authority, and if anyone is able to access this file they can sign new certificates and access your VPN without your knowledge. For this reason, OpenVPN recommends storing `ca.key` in a location that can be offline as much as possible, and it should only be activated when creating new certificates.

Next, create a key and certificate for the server using the `build-key-server` script:

    ./build-key-server server

As with building the CA, you’ll see the values you’ve set as the defaults so you can hit `ENTER` at these prompts. Additionally, you’ll be prompted to enter a challenge password and an optional company name. If you enter a challenge password, you will be asked for it when connecting to the VPN from your client. If you don’t want to set a challenge password, just leave this line blank and press `ENTER`. At the end, enter `Y` to commit the changes.

The last part of creating the server keys and certificates is generating a Diffie-Hellman key exchange file. Use the `build-dh` script to do this:

    ./build-dh

This may take a few minutes to complete.

Once your server is finished generating the key exchange file, copy the server keys and certificates from the`keys` directory into the `openvpn` directory:

    cd /etc/openvpn/easy-rsa/keys
    sudo cp dh2048.pem ca.crt server.crt server.key /etc/openvpn

Each client will also need a certificate in order for the OpenVPN server to authenticate it. These keys and certificates will be created on the server and then you will have to copy them over to your clients, which we will do in a later step. It’s advised that you generate separate keys and certificates for each client you intend to connect to your VPN.

Because we’ll only set up one client here, we called it `client`, but you can change this to a more descriptive name if you’d like:

    cd /etc/openvpn/easy-rsa
    ./build-key client

Finally, copy the versioned OpenSSL configuration file, `openssl-1.0.0.cnf`, to a versionless name, `openssl.cnf`. Failing to do so could result in an error where OpenSSL is unable to load the configuration because it cannot detect its version:

    cp /etc/openvpn/easy-rsa/openssl-1.0.0.cnf /etc/openvpn/easy-rsa/openssl.cnf

Now that all the necessary keys and certificates have been generated for your server and client, you can move on to setting up routing between the two machines.

## Step 4 — Routing

So far, you’ve installed OpenVPN on your server, configured it, and generated the keys and certificates needed for your client to access the VPN. However, you have not yet provided OpenVPN with any instructions on where to send incoming web traffic from clients. You can stipulate how the server should handle client traffic by establishing some firewall rules and routing configurations.

Assuming you followed the prerequisites at the start of this tutorial, you should already have firewalld installed and running on your server. To allow OpenVPN through the firewall, you’ll need to know what your active firewalld zone is. Find this with the following command:

    sudo firewall-cmd --get-active-zones

    Outputtrusted
      Interfaces: tun0

Next, add the `openvpn` service to the list of services allowed by firewalld within your active zone, and then make that setting permanent by running the command again but with the `--permanent` option added:

    sudo firewall-cmd --zone=trusted --add-service openvpn
    sudo firewall-cmd --zone=trusted --add-service openvpn --permanent

You can check that the service was added correctly with the following command:

    sudo firewall-cmd --list-services --zone=trusted

    Outputopenvpn

Next, add a masquerade to the current runtime instance, and then add it again with the `--permanent` option to add the masquerade to all future instances:

    sudo firewall-cmd --add-masquerade
    sudo firewall-cmd --permanent --add-masquerade

You can check that the masquerade was added correctly with this command:

    sudo firewall-cmd --query-masquerade

    Outputyes

Next, forward routing to your OpenVPN subnet. You can do this by first creating a variable (`SHARK` in our example) which will represent the primary network interface used by your server, and then using that variable to permanently add the routing rule:

    SHARK=$(ip route get 8.8.8.8 | awk 'NR==1 {print $(NF-2)}')
    sudo firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.8.0.0/24 -o $SHARK -j MASQUERADE

Be sure to implement these changes to your firewall rules by reloading firewalld:

    sudo firewall-cmd --reload

Next, enable IP forwarding. This will route all web traffic from your client to your server’s IP address, and your client’s public IP address will effectively be hidden.

Open `sysctl.conf` for editing:

    sudo nano /etc/sysctl.conf

Then add the following line at the top of the file:

/etc/sysctl.conf

    net.ipv4.ip_forward = 1

Finally, restart the network service so the IP forwarding will take effect:

    sudo systemctl restart network.service

With the routing and firewall rules in place, we can start the OpenVPN service on the server.

## Step 5 — Starting OpenVPN

OpenVPN is managed as a systemd service using `systemctl`. We will configure OpenVPN to start up at boot so you can connect to your VPN at any time as long as your server is running. To do this, enable the OpenVPN server by adding it to `systemctl`:

    sudo systemctl -f enable openvpn@server.service

Then start the OpenVPN service:

    sudo systemctl start openvpn@server.service

Double check that the OpenVPN service is active with the following command. You should see `active (running)` in the output:

    sudo systemctl status openvpn@server.service

    Output● openvpn@server.service - OpenVPN Robust And Highly Flexible Tunneling Application On server
       Loaded: loaded (/usr/lib/systemd/system/openvpn@.service; enabled; vendor preset: disabled)
       Active: **active (running)** since Wed 2018-03-14 15:20:11 EDT; 7s ago
     Main PID: 2824 (openvpn)
       Status: "Initialization Sequence Completed"
       CGroup: /system.slice/system-openvpn.slice/openvpn@server.service
               └─2824 /usr/sbin/openvpn --cd /etc/openvpn/ --config server.conf
    . . .

We’ve now completed the server-side configuration for OpenVPN. Next, you will configure your client machine and connect to the OpenVPN server.

## Step 6 — Configuring a Client

Regardless of your client machine’s operating system, it will need a locally-saved copy of the CA certificate and the client key and certificate generated in Step 3, as well as the static encryption key you generated at the end of Step 2.

Locate the following files **on your server**. If you generated multiple client keys with unique, descriptive names, then the key and certificate names will be different. In this article we used `client`.

    /etc/openvpn/easy-rsa/keys/ca.crt
    /etc/openvpn/easy-rsa/keys/client.crt
    /etc/openvpn/easy-rsa/keys/client.key
    /etc/openvpn/myvpn.tlsauth

Copy these files to your **client machine**. You can use [SFTP](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) or your preferred method. You could even just open the files in your text editor and copy and paste the contents into new files on your client machine. Regardless of which method you use, be sure to note where you save these files.

Next, create a file called `client.ovpn` **on your client machine**. This is a configuration file for an OpenVPN client, telling it how to connect to the server:

    sudo nano client.ovpn

Then add the following lines to `client.ovpn`. Notice that many of these lines reflect those which we uncommented or added to the `server.conf` file, or were already in it by default:

client.ovpn

    client
    tls-client
    ca /path/to/ca.crt
    cert /path/to/client.crt
    key /path/to/client.key
    tls-crypt /path/to/myvpn.tlsauth
    remote-cert-eku "TLS Web Client Authentication"
    proto udp
    remote your_server_ip 1194 udp
    dev tun
    topology subnet
    pull
    user nobody
    group nobody

When adding these lines, please note the following:

- You’ll need to change the first line to reflect the name you gave the client in your key and certificate; in our case, this is just `client`
- You also need to update the IP address from `your_server_ip` to the IP address of your server; port `1194` can stay the same
- Make sure the paths to your key and certificate files are correct

This file can now be used by any OpenVPN client to connect to your server. Below are OS-specific instructions for how to connect your client:

**Windows:**

On Windows, you will need the official [OpenVPN Community Edition binaries](http://openvpn.net/index.php/open-source/downloads.html) which come with a GUI. Place your `.ovpn` configuration file into the proper directory, `C:\Program Files\OpenVPN\config`, and click **Connect** in the GUI. OpenVPN GUI on Windows must be executed with administrative privileges.

**macOS:**

On macOS, the open source application [Tunnelblick](https://code.google.com/p/tunnelblick/) provides an interface similar to the OpenVPN GUI on Windows, and comes with OpenVPN and the required TUN/TAP drivers. As with Windows, the only step required is to place your `.ovpn` configuration file into the `~/Library/Application Support/Tunnelblick/Configurations` directory. Alternatively, you can double-click on your `.ovpn` file.

**Linux:**

On Linux, you should install OpenVPN from your distribution’s official repositories. You can then invoke OpenVPN by executing:

    sudo openvpn --config ~/path/to/client.ovpn

After you establish a successful client connection, you can verify that your traffic is being routed through the VPN by [checking Google to reveal your public IP](https://www.google.com/search?q=what%20is%20my%20ip).

### Conclusion

You should now have a fully operational virtual private network running on your OpenVPN server. You can browse the web and download content without worrying about malicious actors tracking your activity.

There are several steps you could take to customize your OpenVPN installation even further, such as configuring your client to connect to the VPN automatically or configuring client-specific rules and access policies. For these and other OpenVPN customizations, you should consult [the official OpenVPN documentation](https://openvpn.net/index.php/open-source/documentation.html). If you’re interested in other ways you can protect yourself and your machines on the internet, check out our article on [7 Security Measures to Protect Your Servers](7-security-measures-to-protect-your-servers).
