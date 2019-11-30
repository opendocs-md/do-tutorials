---
author: ads2alpha
date: 2017-03-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-run-a-secure-mongodb-server-with-openvpn-and-docker-on-ubuntu-16-04
---

# How To Run a Secure MongoDB Server with OpenVPN and Docker on Ubuntu 16.04

[MongoDB](http://mongodb.org) is an open-source NoSQL database. A traditional MongoDB setup lacks some security features that you’d want if you’re concerned about data security.

There are a couple of methods to secure the server that runs the database. First, you can set up a VPN and restrict access to only those clients connected to the VPN. Then you can encrypt the transport layer between the client and the server with certificates. You’ll do both in this tutorial. Additionally, you’ll use [Docker](https://www.docker.com/) to run your MongoDB instance, so you can ensure reusability of your MongoDB configuration and certificates across multiple servers.

## Prerequisites

To complete this tutorial, you need:

- An OpenVPN server, which you can set up by following the tutorial [How To Set Up an OpenVPN Server on Ubuntu 16.04](how-to-set-up-an-openvpn-server-on-ubuntu-16-04). Make sure you check the **Private networking** box when creating the server. 
- An Ubuntu 16.04 machine with Docker installed. This is where you’ll create your MongoDB Docker image, and where you’ll run MongoDB in a container. To create it, click **Create Droplet** in the DigitalOcean management console, choose **One-click apps** , and then select **Docker 1.x on 16.04**. Enable private networking on this server as well.
- A non-root user with sudo privileges on both servers. The [Initial Setup Guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) explains how to set it up.
- [MongoDB installed on your local machine](https://www.mongodb.com/download-center?jmp=nav#community). You’ll use this to test your connection to your MongoDB server.

## Step 1 — Configuring the VPN to Forward to Private IP Addresses

If you followed the prerequisite OpenVPN article, you most likely configured your server to forward requests to the public network interface, but not the private one. In this tutorial, we’re going to configure the MongoDB server so it can only be accessed on its private interface, which we’ll only be able to access via our VPN connection. We need to modify the IP fowarding rules on the VPN server so that traffic from VPN clients gets routed to the private network too.

Connect to your OpenVPN server.

    ssh sammy@vpn_server_public_ip

Then go to the DigitalOcean dashboard, select your VPN Droplet, and find its private IP address.

Once you have the private IP address, execute this command on your VPN Droplet to identify the network interface that uses that IP address:

    sudo nano /etc/ufw/before.rules
    ip route | grep vpn_server_private_ip

You should see output similar to the following:

    Output10.132.0.0/16 dev eth1 proto kernel scope link src vpn_server_private_ip

Take note of the network interface in your output. In this example, the interface is `eth1`, but yours may be different.

Once you’ve identified the private network interface, edit the file `/etc/ufw/before.rules`:

    sudo nano /etc/ufw/before.rules

Locate the section you defined in the prerequisite tutorial, which looks like this:

/etc/ufw/before.rules

    # START OPENVPN RULES
    # NAT table rules
    *nat
    :POSTROUTING ACCEPT [0:0] 
    # Allow traffic from OpenVPN client to eth0
    -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
    COMMIT
    # END OPENVPN RULES

Add a new rule for the private network interface:

/etc/ufw/before.rules

    # START OPENVPN RULES
    # NAT table rules
    *nat
    :POSTROUTING ACCEPT [0:0] 
    # Allow traffic from OpenVPN client to eth0
    -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
    -A POSTROUTING -s 10.8.0.0/8 -o eth1 -j MASQUERADE
    COMMIT
    # END OPENVPN RULES

Be sure to substitute `eth1` with the interface for your private network. Then save the file and exit the editor.

Disable and re-enable the firewall:

    sudo ufw disable
    sudo ufw enable

Then log out of your VPN server.

    exit

Now establish a VPN connection from your local computer to your VPN server. Maintain this connection throughout this tutorial.

Now let’s connect to the MongoDB server using its private IP address and configure its firewall.

## Step 2 – Setting Up the MongoDB Server’s Firewall

We’re going to connect to the MongoDB server using its private IP address. If you don’t have it, return to the DigitalOcean dashboard and find the private IP address for the MongoDB Docker Droplet. You’ll use it here to connect to the server, and you’ll subsequently use it to connect to MongoDB directly, as we’re about to restrict access to the database server to VPN clients. This way you avoid exposing the database publicly, which is a must-have security measure.

Ensure you are connected to your VPN, and SSH to the MongoDB server using its private IP:

    ssh sammy@mongodb_server_private_ip

Once you’re logged in, delete all of the existing firewall rules to prevent access from the outside world:

    sudo ufw delete limit ssh
    sudo ufw delete allow 2375/tcp
    sudo ufw delete allow 2376/tcp

Then add two new rules that allow SSH and MongoDB access only from computers connected to your VPN. To do that, use the private IP address of your VPN server for the origin IP:

    sudo ufw allow from vpn_server_private_ip to any port 22 proto tcp
    sudo ufw allow from vpn_server_private_ip to any port 28018 proto tcp 

Ensure these are the only two rules configured:

    sudo ufw status

You should see the following output:

    OutputTo Action From
    -- ------ ----
    22/tcp ALLOW vpn_server_private_ip
    28018/tcp ALLOW vpn_server_private_ip

Enable the firewall and log out of the server:

    sudo ufw enable
    exit

Then log back in to the MongoDB server to make sure you still have access to the server after enabling the IP filter.

    ssh sammy@mongodb_server_private_ip

If you’re unable to establish an SSH connection, make sure you’re connected to the VPN and that you’ve set up the VPN server to forward traffic on the private network. If that doesn’t work, log in using the [DigitalOcean Console](how-to-use-the-digitalocean-console-to-access-your-droplet) and check the firewall rules. Ensure you’ve specified your VPN server’s private IP in the rules, and not the private IP of your MongoDB server.

To learn more about UFW, explore [this DigitalOcean UFW tutorial](how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04).

Now that you’ve configured the basic security measures, proceed to configuring MongoDB.

## Step 3 — Creating the MongoDB Configuration File

In this step, we’ll create a custom MongoDB configuration which configures MongoDB to use SSL certificates.

Let’s create a directory structure to hold our configuration and related files. We’ll create a directory called `mongoconf`, and then create a `config` directory inside of that for our configuration files. Within the `config` directory, we’ll create a directory called `ssl` , where we’ll store the certificates.

Create the structure with the following command:

    mkdir -p ~/mongoconf/config/ssl

Then switch to the `~/mongoconf/config` folder:

    cd ~/mongoconf/config

Open a new file called `mongod.conf` with your text editor:

    nano mongod.conf

First, set the database to bind to every network interface on port `28018`. Binding to `0.0.0.0` is not a security issue in this case as the firewall won’t allow connections from the outside world anyway. But we do need to allow connection from clients inside the VPN. Add the following to the file:

mongodb.conf

    net: 
      bindIp: 0.0.0.0 
      port: 28018

Also in the `net` section, set the paths to the SSL certificates and specify the certificate passphrase. We’ll create the actual certificiate files and passphrase shortly.

mongodb.conf

    net: 
    . . .
      ssl: 
        CAFile: /etc/mongo/ssl/client.pem
        PEMKeyFile: /etc/mongo/ssl/server.pem
        PEMKeyPassword: test
        mode: requireSSL

Finally, set the default storage directory and enable journaling.

mongodb.conf

    . . .
    storage: 
      dbPath: /mongo/db
      journal: 
        enabled: true

To learn about all available configuration options, [read MongoDB’s documentation](https://docs.mongodb.com/manual/reference/configuration-options/).

For now, save the file and exit the editor. It’s time to generate the SSL certificates we’ll use.

## Step 4 — Generating SSL Certificates

To secure data transportation, you need to generate two SSL certificates for MongoDB — one for the server, and one for the client that will access the database.

**Note:** We create self-signed certificates in this tutorial. In a production environment, you would use a trusted certificate authority to generate them.

To do that, you need to [set up a private DNS resolver](how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04). Then, [use the Let’s Encrypt DNS challenge](http://serverfault.com/a/812038) to validate the newly-created intranet domains and issue certificates for them.

First, change to the `~/mongoconf/config/ssl` directory and generate the server certificate-key pair. Fill in the prompts with information of your choice. Pay attention to the `Common Name` and `PEM Passphrase` fields.

    cd ~/mongoconf/config/ssl
    openssl req -new -x509 -days 365 -out server.crt -keyout server.key

You’ll see the following output, and will be asked to provide some details along the way:

    Server certificate-key generation. . .
    Enter PEM pass phrase: test
    Verifying - Enter PEM pass phrase: test
    . . .
    Common Name (e.g. server FQDN or YOUR name) []: mongodb_server_private_ip
    . . .

When you’re asked for the PEM pass phrase, make sure you use the same value you used in your MongoDB configuration file in the previous step.

MongoDB does not accept separate key and certificate files, so combine them into a single `.pem` file:

    cat server.crt server.key >> server.pem

Next, generate the certificate-key pair for the client:

    openssl req -new -x509 -days 365 -out client.crt -keyout client.key

You’ll follow the same process as before, but this time, use the private IP of the VPN server. The PEM pass phrase can be whatever you’d like for this step.

    Client certificate-key generation. . .
    Enter PEM pass phrase: secret_password
    Verifying - Enter PEM pass phrase: secret_password
    . . .
    Common Name (e.g. server FQDN or YOUR name) []: vpn_server_private_ip
    . . .

Concatenate the files you just generated into a single `.pem` file:

    cat client.crt client.key >> client.pem

Next, copy both certificate files to your local machine so you can connect to the MongoDB server remotely. You can do this with the `scp` command on your local machine:

    scp sammy@mongodb_server_private_ip:/home/sammy/mongoconf/config/ssl/\{client.pem,server.pem\} .

Alternatively, you can follow the tutorial [How To Use SFTP to Securely Transfer Files with a Remote Server](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) to transfer the `client.pem` and `server.pem` files to your local machine.

Now let’s create the Docker image and run the database engine in a container so this configuration can be more portable.

## Step 5 — Creating the MongoDB Docker Image and Running the Container

You’ve created a secure MongoDB configuration and generated certificates. Now let’s make it it portable with Docker. We’ll create a custom image for MongoDB, but we’ll pass in our configuration file and certificates when we run the container.

To build up an image, you need a Dockerfile.

**Note** : To run `docker` without `sudo`, add **sammy** to the **docker** group:

    sudo usermod -aG docker sammy

Then log out of the server and log back in again so the new group permissions take effect.

Switch to the root directory of the project and open up an empty Dockerfile in your editor:

    cd ~/mongoconf
    nano Dockerfile

Add the following to the new file:

Dockerfile

    FROM ubuntu:xenial
    
    RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    RUN echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    RUN apt-get update && apt-get install -y mongodb-org
    RUN mkdir -p /mongo/db /etc/mongo
    
    EXPOSE 28018
    ENTRYPOINT ["mongod", "--config", "/etc/mongo/mongod.conf"]

This file tells Docker to create an image based on Ubuntu 16.04 Xenial, download the latest MongoDB binaries, and create a few directories where we will store configuration files and the database. It makes port `28018` of the container available to the host, and runs Mongo every time the user restarts the container.

**Note:** For the sake of simplicity, our image is based on Ubuntu. However, containers built on lightweight distros like Alpine Linux use less disk space.

Save the file and exit your editor. Then build the image:

    docker build -t mongo .

Once the image builds, run a container based on the image. We’ll mount the `config` directory as a volume inside of the container so our custom configuration and keys are visible to the MongoDB instance inside of the container:

    docker run \
    --detach \
    --publish 28018:28018 \
    --volume $PWD/config:/etc/mongo \
    --name mongodb \
    mongo

Now that you have a running MongoDB instance, access it from your local computer.

## Step 6 — Accessing MongoDB

In a new terminal on your local machine, connect to the database using the private IP address of the MongoDB server. You’ll provide the client.pem and server.pem files you downloaded to your local machine, as well as the passphrase you used when creating the client certificate. Execute this command:

    mongo \
    --ssl \
    --sslCAFile path_to_server_pem \
    --sslPEMKeyFile path_to_client_pem \
    --sslPEMKeyPassword pem_key_passphrase \
    --host mongodb_server_private_ip \
    --port 28018

If everything is fine, you should see the MongoDB prompt.

    

If an error appears, double-check that you’re connecting to the private IP of the MongoDB server, and not to the VPN server’s IP address. Also verify that the key location and the passphrase are correct, and that your connection to the VPN is still running.

## Conclusion

Now you have a custom-configured MongoDB running in a Docker container. Its security is granted by SSL client-server authentication and transport encryption. You have added additional security by configuring the firewall to restrict database connections to clients connected to a VPN server.

Although this setup is optimal for testing, remember that in a production environment, you should use a trusted certificate authority and signed certificates. In addition,, you have to analyze your security needs and act accordingly. For example, you may want to set up users, passwords, and roles in the database. The tutorial [How to Install and Secure MongoDB on Ubuntu 16.04](how-to-install-and-secure-mongodb-on-ubuntu-16-04) has more information about creating users and is a great next-step towards a production-ready setup.
