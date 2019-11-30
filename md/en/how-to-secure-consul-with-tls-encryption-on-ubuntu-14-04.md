---
author: Justin Ellingwood
date: 2014-08-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-consul-with-tls-encryption-on-ubuntu-14-04
---

# How To Secure Consul with TLS Encryption on Ubuntu 14.04

## Introduction

Consul is a service discovery tool that can be used to easily discover and keep track of the health of various services throughout your infrastructure. You can use consul to manage your services and maintain a distributed checking system to make sure you can respond when applications or servers go down.

In the [last guide](how-to-configure-consul-in-a-production-environment-on-ubuntu-14-04), we focused on getting a production-ready environment up and ready. This included creating configuration files that would be read at boot and upstart scripts to actually initiate the services.

This took us most of the way to our final base configuration, but we did not completely secure our configuration yet. We implemented a simple shared secret solution, which very easily encrypts our gossip protocol.

However, the RPC communication is still completely unencrypted at this point. To solve this problem, consul natively supports TLS encryption, which we will be focusing on in this guide. To implement this, we will have to create a certificate authority and sign and distribute keys to our nodes.

## Prerequisites and Goals

Before you complete this guide, you should have a system of consul servers set up as we left them in our last guide on [setting up a production-ready consul infrastructure](how-to-configure-consul-in-a-production-environment-on-ubuntu-14-04).

The servers we had for that guide had the following properties:

| Hostname | IP Address | Role |
| --- | --- | --- |
| server1.example.com | 192.0.2.1 | bootstrap consul server |
| server2.example.com | 192.0.2.2 | consul server |
| server3.example.com | 192.0.2.3 | consul server |
| agent1.example.com | 192.0.2.50 | consul client |

These are 64-bit Ubuntu 14.04 servers. Please note that each of these servers resides within the same domain. This will be important for the configuration we are implementing in this guide, because we will be leveraging a wildcard certificate that will match for any of the hosts within the domain.

In this guide, we will focus on creating a TLS certificate authority in order to sign certificates for each of our servers. This will allow the consul components to verify identities and encrypt traffic. We will then modify the configuration files slightly to force our nodes to encrypt traffic.

## Create the SSL Structure

To get started, we will set up some basic files and directories that we will use to manage our keys.

Again, we will be doing all of the procedures in this guide from within a root shell. Either log in as root, or use `sudo -i` as a user with sudo privileges.

On each of your consul members, create an `ssl` directory inside of the `/etc/consul.d` directory. This is where we will keep the necessary files for encrypting RPC traffic:

    mkdir /etc/consul.d/ssl

On the server you plan on using as your certificate authority, we will create a subdirectory within this directory to house all of the files necessary to create and sign the certificates. We can select any of our servers to house the certificate authority, but for our purposes, we will be using the `server1` that also houses the bootstrap configuration.

On this server, create a subdirectory called `CA` under the directory we just created:

    mkdir /etc/consul.d/ssl/CA

This will contain some sensitive data that we probably don’t want other people to access, so let’s lock down permissions:

    chmod 0700 /etc/consul.d/ssl/CA

Move into this directory on the CA server.

    cd /etc/consul.d/ssl/CA

Here, we will create some basic files that need to be present for our certificate signing. First, we need to create a file that will be incremented with the next available serial number for certificates. We need to pre-seed this with a value.

To do this, echo the value of `000a` to the serial file:

    echo "000a" > serial

We also need to provide a file where our certificate authority can record the certificates that it signs. We will call this file `certindex`:

    touch certindex

## Create a Self-Signed Root Certificate

To get started with our certificate authority, the first step we need to do is create a self-signed root certificate. We can do that with the `openssl` command that is installed by default on Ubuntu machines.

The command that we will use to create the certificate is:

    openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -out ca.cert

Let’s go over what this means:

- **req** : This argument tells openssl that you are interested in operating on a [PKCS#10](http://en.wikipedia.org/wiki/PKCS) certificate, either by creating or processing requests.
- **-x509** : This argument specifies that you would like a self-signed certificate instead of a certificate request. This is commonly done for root CA certificates.
- **-newkey rsa:2048** : This tells openssl to generate a new certificate request and private key. We pass it an argument specifying that we want an RSA key of 2048 bits.
- **-days 3650** : Here, we specify the number of days that the certificate is considered valid. We are using a value of `3650`, which is 10 years.
- **-nodes** : This specifies that the generated private key will not be encrypted with DES, which would require a password. This avoids that requirement.
- **-out ca.cert** : This sets the filename that will be used for the generated certificate file.

During the certificate creation process, you will be prompted to enter information about the host you are certifying. You can fill this out with whatever relevant information you would like about the server:

    . . .
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York City
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:ConsulCA
    Email Address []:admin@example.com

For the `Common Name`, which will be important in our other certificate, you can put whatever you would like.

When you are finished, you should have a `ca.cert` certificate file, as well as an associated key called `privkey.pem`.

## Create a Wildcard Certificate Signing Request

Now that we have the root CA certificate, we can generate a certificate signing request for our client machines.

In this case, all of our consul members are clients, including the server we’re operating on now. Instead of generating a unique certificate for each server and signing it with our CA, we are going to create a wildcard certificate that will be valid for any of the hosts in our domain.

The general format of the command will be the same, with a few minor differences:

    openssl req -newkey rsa:1024 -nodes -out consul.csr -keyout consul.key

The difference between the self-signed root CA certificate request that we created and the new certificate signing request we’re generating now are here:

- **no -x509 flag** : We have removed the `-x509` flag in order to generate a certificate signing request instead of a self-signed certificate.
- **-out consul.csr** : The outputted file is not a certificate itself, but a certificate signing request.
- **-keyout consul.key** : We have specified the name of the key that is associated with the certificate signing request.

Again, we will be prompted for our responses for the certificate signing request (CSR). This is more important than the answers we provided for the self-signed root CA cert. Here, we will need to use a wildcard `Common Name` in order for our certificate to check out as being valid for each of our hosts:

    . . .
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York City
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:DigitalOcean
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:*.example.com
    Email Address []:admin@example.com
    
    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:

As you can see here, we used our domain, with an asterisk as the host to signify that the certificate should be considered valid for any host within the domain. You can safely skip the challenge password and optional company name prompts that are added onto the end.

## Create a Certificate Authority Configuration File

Now, we have our self-signed root CA certificate file and a wildcard certificate signing request that matches all hosts in our domain. Before we can sign the signing request with our CA certificate, we need to create a configuration file that will control how this happens.

We will call the file we are creating `myca.conf` that will hold our CA information. Open this file now:

    nano /etc/consul.d/ssl/CA/myca.conf

This file uses an [INI format](http://en.wikipedia.org/wiki/INI_file) that is divided into sections. The first section we will define is the `ca` section. The only thing we’ll do here is point to our user-defined section with the actual CA information:

    [ca]
    default_ca = myca

Next, we’ll create the section we just referenced. This will contain the bulk of the CA configuration details.

We will specify that the information entered into cert prompts does not have to be unique. We will then give the location of all of the files that we have created that are needed for the signing process. We will tell `openssl` to place new certificates in the current directory.

We also want to select some defaults to be used when no alternatives are specified on the command line. We will select the signed certs to be good for 10 years, and will use the `sha1` algorithm. Finally, we will point to some additional sections we will be creating to define additional information:

    [myca]
    unique_subject = no
    new_certs_dir = .
    certificate = ca.cert
    database = certindex
    private_key = privkey.pem
    serial = serial
    default_days = 3650
    default_md = sha1
    policy = myca_policy
    x509_extensions = myca_extensions

Now, let’s focus on the first user-defined section we just referenced, which is used to decide what information needs to be provided for the CSR to be accepted. We’re going to mark some fields as required and others as optional. We will make some pretty standard choices for the usual prompts:

    [myca_policy]
    commonName = supplied
    stateOrProvinceName = supplied
    countryName = supplied
    emailAddress = optional
    organizationName = supplied
    organizationalUnitName = optional

The final section will define the x509 extensions that we want to use when signing certificates.

First, we need to tell it that the certificate we’ll be signing is not a CA certificate. We will use the standard value of “hash” for the subject key identifier as hex strings (the alternative) are strongly discouraged.

We will set the authority key identifier to “keyid” to copy the subject key identifier from the parent cert. We will also specify that the keys can be used as a signature or with a protocol that encrypts keys. We will specify that the extended usage of the keys can be for server and client authentication:

    [myca_extensions]
    basicConstraints = CA:false
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always
    keyUsage = digitalSignature,keyEncipherment
    extendedKeyUsage = serverAuth,clientAuth

All together, the file looks something like this:

    [ca]
    default_ca = myca
    
    [myca]
    unique_subject = no
    new_certs_dir = .
    certificate = ca.cert
    database = certindex
    private_key = privkey.pem
    serial = serial
    default_days = 3650
    default_md = sha1
    policy = myca_policy
    x509_extensions = myca_extensions
    
    [myca_policy]
    commonName = supplied
    stateOrProvinceName = supplied
    countryName = supplied
    emailAddress = optional
    organizationName = supplied
    organizationalUnitName = optional
    
    [myca_extensions]
    basicConstraints = CA:false
    subjectKeyIdentifier = hash
    authorityKeyIdentifier = keyid:always
    keyUsage = digitalSignature,keyEncipherment
    extendedKeyUsage = serverAuth,clientAuth

Save and close the file when you are finished. We now have a substantial configuration file that can be used to sign the certificate signing request we generated earlier.

## Sign the Certificate Signing Request to Generate a Certificate

Now, we have all of the components necessary to sign the CSR and generate a certificate. We just need to reference the configuration file we just created, and pass in the CSR we generated.

The command we will use is:

    openssl ca -batch -config myca.conf -notext -in consul.csr -out consul.cert

The options we use are:

- **ca** : Use openssl’s certificate authority management functionality.
- **-batch** : Specifies that it should enter batch mode. Batch mode automatically certifies any CSRs passed in, without prompting.
- **-config myca.conf** : Pass in the configuration file we created.
- **-notext** : Do not output the text form of the cert.

The rest of the options specify the input and output files.

This will produce a file called `consul.cert` in the current directory. It will also create new versions of the `serial` and `certindex` files, moving the old versions to backup files. A `.pem` file will also be created based on the serial number in the `serial` file.

## Move the Files to the Correct Location

Now, we have all of the components that we need within the `/etc/consul.d/ssl/CA` directory. We want to copy the three files we need to the `/etc/consul.d/ssl` directory, where we will reference them:

    cp ca.cert consul.key consul.cert ..

Our `server1` machine that holds the CA now has the necessary certificate and key files in the correct location.

To get them onto the other machines in your infrastructure, `scp` is a good choice. From the `/etc/consul.d/ssl` directory on `server1`, you can push the necessary files to the other servers by typing:

    cd /etc/consul.d/ssl
    scp ca.cert consul.key consul.cert root@192.0.2.2:/etc/consul.d/ssl
    scp ca.cert consul.key consul.cert root@192.0.2.3:/etc/consul.d/ssl
    scp ca.cert consul.key consul.cert root@192.0.2.50:/etc/consul.d/ssl

Change the IP addresses to reference each of the machines in your infrastructure.

## Modify the Consul Configuration Files

Now that we have our root certificate file and a certificate/key pair for our consul members, we can modify our consul configuration files to reference these files.

Open up each of the consul configuration files on your servers. For our `server1` machine, we will start with the bootstrap configuration file:

    nano /etc/consul.d/bootstrap/config.json

The file should look like this currently:

    {
        "bootstrap": true,
        "server": true,
        "datacenter": "nyc2",
        "data_dir": "/var/consul",
        "encrypt": "pmsKacTdVOb4x8/Vtr9PWw==",
        "log_level": "INFO",
        "enable_syslog": true
    }

The first thing we should do is use the consul parameters to identify each of our new files. The `ca_file` parameter references the location of the CA certificate file. The `cert_file` and `key_file` parameters reference the client’s certificate and key files respectively.

Since these have to do with encryption as well, we’ll add it below the `encrypt` parameter for clarity:

    {
        "bootstrap": true,
        "server": true,
        "datacenter": "nyc2",
        "data_dir": "/var/consul",
        "encrypt": "pmsKacTdVOb4x8/Vtr9PWw==",
        "ca_file": "/etc/consul.d/ssl/ca.cert",
        "cert_file": "/etc/consul.d/ssl/consul.cert",
        "key_file": "/etc/consul.d/ssl/consul.key",
        "log_level": "INFO",
        "enable_syslog": true
    }

Now, we’ve defined the locations of these files, but we haven’t told consul that we want to verify the authenticity of each of the hosts using these files. We can do that now by telling consul to verify both incoming and outgoing connections:

    {
        "bootstrap": true,
        "server": true,
        "datacenter": "nyc2",
        "data_dir": "/var/consul",
        "encrypt": "pmsKacTdVOb4x8/Vtr9PWw==",
        "ca_file": "/etc/consul.d/ssl/ca.cert",
        "cert_file": "/etc/consul.d/ssl/consul.cert",
        "key_file": "/etc/consul.d/ssl/consul.key",
        "verify_incoming": true,
        "verify_outgoing": true,
        "log_level": "INFO",
        "enable_syslog": true
    }

Save and close the file when you are finished.

Make these same changes to each of the configuration files that your consul members use.

On `server1`, you need to make these changes to `/etc/consul.d/bootstrap/config.json` and `/etc/consul.d/server/config.json`.

On your other servers, you would just need to modify `/etc/consul.d/server/config.json`. On your client machine(s), you would have to modify `/etc/consul.d/client/config.json`.

## Restarting the Servers

To implement our encrypted traffic, you must restart the consul session on each of your consul members in turn.

On each machine in your infrastructure, briefly stop and then start consul again:

    stop consul && sleep 5 && start consul

This will stop the process and restart it momentarily.

If you do this on each of your consul members in turn, they will switch to using SSL to encrypt the RPC traffic between them. When only some of them are switched over, some communication problems might exist briefly as some traffic is rejected for not being encrypted.

When all of the members are restarted, the RPC traffic should be entirely encrypted.

## Conclusion

At this point, you should have a fairly secure service discovery system in place for your infrastructure. We have leveraged all of the native security systems available with consul to lock down access and prevent spoofing of our different machines.
