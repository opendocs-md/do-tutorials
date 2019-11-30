---
author: Justin Ellingwood
date: 2015-05-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls
---

# How To Encrypt OpenLDAP Connections Using STARTTLS

## Introduction

OpenLDAP provides an LDAP directory service that is flexible and well-supported. However, out-of-the-box, the server itself communicates over an unencrypted web connection. In this guide, we will demonstrate how to encrypt connections to OpenLDAP using STARTTLS to upgrade conventional connections to TLS. We will be using an Ubuntu 14.04 as our LDAP server.

## Prerequisites

Before you get started with this guide, you should have a non-root user with `sudo` set up on your server. To set up a user of this type, follow our [Ubuntu 14.04 initial setup guide](initial-server-setup-with-ubuntu-14-04).

We will cover how to install OpenLDAP on an Ubuntu 14.04 server in this guide. If you already have OpenLDAP installed on your server, you can skip the relevant installation and configuration steps.

## LDAP Over SSL vs LDAP with STARTTLS

There are two ways to encrypt LDAP connections with SSL/TLS.

Traditionally, LDAP connections that needed to be encrypted were handled on a separate port, typically `636`. The entire connection would be wrapped with SSL/TLS. This process, called LDAP over SSL, uses the `ldaps://` protocol. This method of encryption is now deprecated.

STARTTLS is an alternative approach that is now the preferred method of encrypting an LDAP connection. STARTTLS “upgrades” a non-encrypted connection by wrapping it with SSL/TLS after/during the connection process. This allows unencrypted and encrypted connections to be handled by the same port. This guide will utilize STARTTLS to encrypt connections.

## Setting the Hostname and FQDN

Before you get started, we should set up our server so that it correctly resolves its hostname and fully qualified domain name (FQDN). This will be necessary in order for our certificates to be validated by clients. We will assume that our LDAP server will be hosted on a machine with the FQDN of `ldap.example.com`.

To set the hostname in all of the relevant places on your server, use the `hostnamectl` command with the `set-hostname` option. Set the hostname to the short hostname (do not include the domain name component):

    sudo hostnamectl set-hostname ldap

Next, we need to set the FQDN of our server by making sure that our `/etc/hosts` file has the correct information:

    sudo nano /etc/hosts

Find the line that maps the `127.0.1.1` IP address. Change the first field after the IP address to the FQDN of the server, and the second field to the short hostname. For our example, it would look something like this:

/etc/hosts

    . . .
    
    127.0.1.1 ldap.example.com ldap
    127.0.0.1 localhost
    
    . . .

Save and close the file when you are finished.

You can check that you’ve configured these values correctly by typing:

    hostname

This should return your short hostname:

short hostname

    ldap

Check the FQDN by typing:

    hostname -f

This should return the FQDN:

FQDN setting

    ldap.example.com

## Installing the LDAP Server and GnuTLS Software

After ensuring that your hostname is set properly, we can install the software we need. If you already have OpenLDAP installed and configured, you can skip the first sub-section.

### Install the OpenLDAP Server

If you do not already have OpenLDAP installed, now is the time to fix that. Update your server’s local package index and install the software by typing:

    sudo apt-get update
    sudo apt-get install slapd ldap-utils

You will be asked to provide an LDAP administrative password. Feel free to skip the prompt, as we will be reconfiguring immediately after.

In order to access some additional prompts that we need, we’ll reconfigure the package after installation. To do so, type:

    sudo dpkg-reconfigure slapd

Answer the prompts appropriately, using the information below as a starting point:

- Omit OpenLDAP server configuration? **No** (we want an initial database and configuration)
- DNS domain name: **`example.com`** (use the server’s domain name, minus the hostname. This will be used to create the base entry for the information tree)
- Organization name: **Example Inc** (This will simply be added to the base entry as the name of your organization)
- Administrator password: [whatever you’d like]
- Confirm password: [must match the above]
- Database backend to use: **HDB** (out of the two choices, this has the most functionality)
- Do you want the database to be removed when slapd is purged? (your choice. Choose “Yes” to allow a completely clean removal, choose “No” to save your data even when the software is removed)
- Move old database? **Yes**
- Allow LDAPv2 protocol? **No**

### Install the SSL Components

Once your OpenLDAP server is configured, we can go ahead and install the packages we’ll use to encrypt our connection. The Ubuntu OpenLDAP package is compiled against the GnuTLS SSL libraries, so we will use GnuTLS to generate our SSL credentials:

    sudo apt-get install gnutls-bin ssl-cert

With all of our tools installed, we can begin creating the certificates and keys needed to encrypt our connections.

## Create the Certificate Templates

To encrypt our connections, we’ll need to configure a certificate authority and use it to sign the keys for the LDAP server(s) in our infrastructure. So for our single server setup, we will need two sets of key/certificate pairs: one for the certificate authority itself and one that is associated with the LDAP service.

To create the certificates needed to represent these entities, we’ll create some template files. These will contain the information that the `certtool` utility needs in order to create certificates with the appropriate properties.

Start by making a directory to store the template files:

    sudo mkdir /etc/ssl/templates

### Create the CA Template

Create the template for the certificate authority first. We’ll call the file `ca_server.conf`. Create and open the file in your text editor:

    sudo nano /etc/ssl/templates/ca_server.conf

We only need to provide a few pieces of information in order to successfully create a certificate authority. We need to specify that the certificate will be for a CA (certificate authority) by adding the `ca` option. We also need the `cert_signing_key` option to give the generated certificate the ability to sign additional certificates. We can set the `cn` to whatever descriptive name we’d like for our certificate authority:

caserver.conf

    cn = LDAP Server CA
    ca
    cert_signing_key

Save and close the file.

### Create the LDAP Service Template

Next, we can create a template for our LDAP server certificate called `ldap_server.conf`. Create and open the file in your text editor with `sudo` privileges:

    sudo nano /etc/ssl/templates/ldap_server.conf

Here, we’ll provide a few different pieces of information. We’ll provide the name of our organization and set the `tls_www_server`, `encryption_key`, and `signing_key` options so that our cert has the basic functionality it needs.

The `cn` in this template **must** match the FQDN of the LDAP server. If this value does not match, the client will reject the server’s certificate. We will also set the expiration date for the certificate. We’ll create a 10 year certificate to avoid having to manage frequent renewals:

ldapserver.conf

    organization = "Example Inc"
    cn = ldap.example.com
    tls_www_server
    encryption_key
    signing_key
    expiration_days = 3652

Save and close the file when you’re finished.

## Create CA Key and Certificate

Now that we have our templates, we can create our two key/certificate pairs. We need to create the certificate authority’s set first.

Use the `certtool` utility to generate a private key. The `/etc/ssl/private` directory is protected from non-root users and is the appropriate location to place the private keys we will be generating. We can generate a private key and write it to a file called `ca_server.key` within this directory by typing:

    sudo certtool -p --outfile /etc/ssl/private/ca_server.key

Now, we can use the private key that we just generated and the template file we created in the last section to create the certificate authority certificate. We will write this to a file in the `/etc/ssl/certs` directory called `ca_server.pem`:

    sudo certtool -s --load-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ca_server.conf --outfile /etc/ssl/certs/ca_server.pem

We now have the private key and certificate pair for our certificate authority. We can use this to sign the key that will be used to actually encrypt the LDAP session.

## Create LDAP Service Key and Certificate

Next, we need to generate a private key for our LDAP server. We will again put the generated key in the `/etc/ssl/private` directory for security purposes and will call the file `ldap_server.key` for clarity.

We can generate the appropriate key by typing:

    sudo certtool -p --sec-param high --outfile /etc/ssl/private/ldap_server.key

Once we have the private key for the LDAP server, we have everything we need to generate a certificate for the server. We will need to pull in almost all of the components we’ve created thus far (the CA certificate and key, the LDAP server key, and the LDAP server template).

We will put the certificate in the `/etc/ssl/certs` directory and name it `ldap_server.pem`. The command we need is:

    sudo certtool -c --load-privkey /etc/ssl/private/ldap_server.key --load-ca-certificate /etc/ssl/certs/ca_server.pem --load-ca-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ldap_server.conf --outfile /etc/ssl/certs/ldap_server.pem

## Give OpenLDAP Access to the LDAP Server Key

We now have all of the certificates and keys we need. However, currently, our OpenLDAP process will be unable to access its own key.

A group called `ssl-cert` already exists as the group-owner of the `/etc/ssl/private` directory. We can add the user our OpenLDAP process runs under (`openldap`) to this group:

    sudo usermod -aG ssl-cert openldap

Now, our OpenLDAP user has access to the directory. We still need to give that group ownership of the `ldap_server.key` file though so that we can allow read access. Give the `ssl-cert` group ownership over that file by typing:

    sudo chown :ssl-cert /etc/ssl/private/ldap_server.key

Now, give the `ssl-cert` group read access to the file:

    sudo chmod 640 /etc/ssl/private/ldap_server.key

Our OpenSSL process can now access the key file properly.

## Configure OpenLDAP to Use the Certificate and Keys

We have our files and have configured access to the components correctly. Now, we need to modify our OpenLDAP configuration to use the files we’ve made. We will do this by creating an LDIF file with our configuration changes and loading it into our LDAP instance.

Move to your home directory and open a file called `addcerts.ldif`. We will put our configuration changes in this file:

    cd ~
    nano addcerts.ldif

To make configuration changes, we need to target the `cn=config` entry of the configuration DIT. We need to specify that we are wanting to modify the attributes of the entry. Afterwards we need to add the `olcTLSCACertificateFile`, `olcCertificateFile`, and `olcCertificateKeyFile` attributes and set them to the correct file locations.

The end result will look like this:

addcerts.ldif

    dn: cn=config
    changetype: modify
    add: olcTLSCACertificateFile
    olcTLSCACertificateFile: /etc/ssl/certs/ca_server.pem
    -
    add: olcTLSCertificateFile
    olcTLSCertificateFile: /etc/ssl/certs/ldap_server.pem
    -
    add: olcTLSCertificateKeyFile
    olcTLSCertificateKeyFile: /etc/ssl/private/ldap_server.key

Save and close the file when you are finished. Apply the changes to your OpenLDAP system using the `ldapmodify` command:

    sudo ldapmodify -H ldapi:// -Y EXTERNAL -f addcerts.ldif

We can reload OpenLDAP to apply the changes:

    sudo service slapd force-reload

Our clients can now encrypt their connections to the server over the conventional `ldap://` port by using STARTTLS.

## Setting up the Client Machines

In order to connect to the LDAP server and initiate a STARTTLS upgrade, the clients must have access to the certificate authority certificate and must request the upgrade.

### On the OpenLDAP Server

If you are interacting with the OpenLDAP server from the server itself, you can set up the client utilities by copying the CA certificate and adjusting the client configuration file.

First, copy the CA certificate from the `/etc/ssl/certs` directory to a file within the `/etc/ldap` directory. We will call this file `ca_certs.pem`. This file can be used to store all of the CA certificates that clients on this machine may wish to access. For our purposes, this will only contain a single certificate:

    sudo cp /etc/ssl/certs/ca_server.pem /etc/ldap/ca_certs.pem

Now, we can adjust the system-wide configuration file for the OpenLDAP utilities. Open up the configuration file in your text editor with `sudo` privileges:

    sudo nano /etc/ldap/ldap.conf

Adjust the value of the `TLS_CACERT` option to point to the file we just created:

/etc/ldap/ldap.conf

    . . .
    
    TLS_CACERT /etc/ldap/ca_certs.pem
    
    . . .

Save and close the file.

You should now be able to upgrade your connections to use STARTTLS by passing the `-Z` option when using the OpenLDAP utilities. You can force STARTTLS upgrade by passing it twice. Test this by typing:

    ldapwhoami -H ldap:// -x -ZZ

This forces a STARTTLS upgrade. If this is successful, you should see:

STARTTLS success

    anonymous

If you mis-configured something, you will likely see an error like this:

STARTTLS failure

    ldap_start_tls: Connect error (-11)
        additional info: (unknown error code)

### Configuring Remote Clients

If you are connecting to your OpenLDAP server from remote servers, you will need to complete a similar process. First, you must copy the CA certificate to the client machine. You can do this easily with the `scp` utility.

#### Forwarding SSH Keys to the Client

If you connect to your OpenLDAP server using SSH keys and your client machine is also remote, you will need to add them to an agent and forward them when connecting to your client machine.

To do this, on your local machine, start the SSH agent by typing:

    eval $(ssh-agent)

Add your SSH key to the agent by typing:

    ssh-add

Now, you can forward your SSH keys when you connect to your LDAP client machine by adding the `-A` flag:

    ssh -A user@ldap_client

#### Copying the CA Certificate

Once you are connected to the OpenLDAP client, you can copy the CA certificate by typing:

    scp user@ldap.example.com:/etc/ssl/certs/ca_server.pem ~/

Now, append the copied certificate to the list of CA certificates that the client knows about. This will append the certificate to the file if it already exists and will create the file if it doesn’t:

    cat ~/ca_server.pem | sudo tee -a /etc/ldap/ca_certs.pem

#### Adjust the Client Configuration

Next, we can adjust the global configuration file for the LDAP utilities to point to our `ca_certs.pem` file. Open the file with `sudo` privileges:

    sudo nano /etc/ldap/ldap.conf

Find the `TLS_CACERT` option and set it to the `ca_certs.pem` file:

/etc/ldap/ldap.conf

    . . .
    
    TLS_CACERT /etc/ldap/ca_certs.pem
    
    . . .

Save and close the file when you are finished.

Test the STARTTLS upgrade by typing this:

    ldapwhoami -H ldap://ldap.example.com -x -ZZ

If the STARTTLS upgrade is successful, you should see:

STARTTLS success

    anonymous

## Force Connections to Use TLS (Optional)

We’ve successfully configured our OpenLDAP server so that it can seamlessly upgrade normal LDAP connections to TLS through the STARTTLS process. However, this still allows unencrypted sessions, which may not be what you want.

If you wish to force STARTTLS upgrades for every connection, you can adjust your server’s settings. We will only be applying this requirement to the regular DIT, not the configuration DIT accessible beneath the `cn=config` entry.

First, you need to find the appropriate entry to modify. We will print a list of all of the DITs (directory information trees: the hierarchies of entries that an LDAP server handles) that the OpenLDAP server has information about as well as the entry that configures each DIT.

On your OpenLDAP server, type:

    sudo ldapsearch -H ldapi:// -Y EXTERNAL -b "cn=config" -LLL -Q "(olcSuffix=*)" dn olcSuffix

The response should look something like this:

DITs Served by OpenLDAP

    dn: olcDatabase={1}hdb,cn=config
    olcSuffix: dc=example,dc=com

You may have more DIT and database pairs if your server is configured to handle more than one DIT. Here, we have a single DIT with the base entry of `dc=example,dc=com`, which would be the entry created for a domain of `example.com`. This DIT’s configuration is handled by the `olcDatabase={1}hdb,cn=config` entry. Make note of the DNs of the DITs you want to force encryption on.

We will use an LDIF file to make the changes. Create the LDIF file in your home directory. We will call it `forcetls.ldif`:

    nano ~/forcetls.ldif

Inside, target the DN you want to force TLS on. In our case, this will be `dn: olcDatabase={1}hdb,cn=config`. We will set the `changetype` to “modify” and add the `olcSecurity` attribute. Set the value of the attribute to “tls=1” to force TLS for this DIT:

forcetls.ldif

    dn: olcDatabase={1}hdb,cn=config
    changetype: modify
    add: olcSecurity
    olcSecurity: tls=1

Save and close the file when you are finished.

To apply the change, type:

    sudo ldapmodify -H ldapi:// -Y EXTERNAL -f forcetls.ldif

Reload the OpenLDAP service by typing:

    sudo service slapd force-reload

Now, if you search the `dc=example,dc=com` DIT, you will be refused if you do not use the `-Z` option to initiate a STARTTLS upgrade:

    ldapsearch -H ldap:// -x -b "dc=example,dc=com" -LLL dn

TLS required failure

    Confidentiality required (13)
    Additional information: TLS confidentiality required

We can demonstrate that STARTTLS connections still function correctly:

    ldapsearch -H ldap:// -x -b "dc=example,dc=com" -LLL -Z dn

TLS required success

    dn: dc=example,dc=com
    
    dn: cn=admin,dc=example,dc=com

## Conclusion

You should now have an OpenLDAP server configured with STARTTLS encryption. Encrypting your connection to the OpenLDAP server with TLS allows you to verify the identity of the server you are connecting with. It also shields your traffic from intermediate parties. When connecting over an open network, encrypting your traffic is essential.
