---
author: Etel Sverdlov
date: 2012-10-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-multiple-ssl-certificates-on-one-ip-with-nginx-on-ubuntu-12-04
---

# How To Set Up Multiple SSL Certificates on One IP with Nginx on Ubuntu 12.04

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

You can host multiple SSL certificates on one IP Address using Server Name Identification (SNI).

### About SNI

Although hosting several sites on a single virtual private server is not a challenge with the use of virtual hosts, providing separate SSL certificates for each site traditionally required separate IP addresses. The process has recently been simplified through the use of Server Name Indication (SNI), which sends a site visitor the certificate that matches the requested server name.

### Note:

SNI can only be used for serving multiple SSL sites from your web server and is not likely to work at all on other daemons, such as mail servers, etc. There are also a small percentage of older web browsers that may still give certificate errors. [Wikipedia](http://en.wikipedia.org/wiki/Server_Name_Indication#Support) has an updated list of software that does and does not support this TLS extension.

## Set Up

SNI does need to have registered domain names in order to serve the certificates.

The steps in this tutorial require the user to have root privileges. You can see how to set that up in the [Initial Server Setup Tutorial](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04) in steps 3 and 4.

Nginx should already be installed and running on your VPS.

If this is not the case, you can download it with this command:

    sudo apt-get install nginx

You can make sure that SNI is enabled on your server:

     nginx -V

After displaying the nginx version, you should see the line:

     TLS SNI support enabled

## Step One—Create Your SSL Certificate Directories

For the purposes of this tutorial, both certificates will be self-signed. We will be working to create a server that hosts both example.com and example.org.

The SSL certificate has 2 parts main parts: the certificate itself and the public key. To make all of the relevant files easy to access, we should create a directory for each virtual host’s SSL certificate.

    mkdir -p /etc/nginx/ssl/example.com

    mkdir -p /etc/nginx/ssl/example.org

## Step Two—Create the Server Key and Certificate Signing Request

First, create the SSL certificate for example.com.

Switch into the proper directory:

    cd /etc/nginx/ssl/example.com

Start by creating the private server key. During this process, you will be asked to enter a specific passphrase. Be sure to note this phrase carefully, if you forget it or lose it, you will not be able to access the certificate.

    sudo openssl genrsa -des3 -out server.key 1024

Follow up by creating a certificate signing request:

    sudo openssl req -new -key server.key -out server.csr

This command will prompt terminal to display a lists of fields that need to be filled in.

The most important line is "Common Name". Enter your official domain name here or, if you don't have one yet, your site's IP address. Leave the challenge password and optional company name blank.

    You are about to be asked to enter information that will be incorporated into your certificate request. What you are about to enter is what is called a Distinguished Name or a DN. There are quite a few fields but you can leave some blank For some fields there will be a default value, If you enter '.', the field will be left blank. ----- Country Name (2 letter code) [AU]:US State or Province Name (full name) [Some-State]:New York Locality Name (eg, city) []:NYC Organization Name (eg, company) [Internet Widgits Pty Ltd]:Awesome Inc Organizational Unit Name (eg, section) []:Dept of Merriment Common Name (e.g. server FQDN or YOUR name) []:example.com Email Address []:webmaster@awesomeinc.com

## Step Three—Remove the Passphrase

We are almost finished creating the certificate. However, it would serve us to remove the passphrase. Although having the passphrase in place does provide heightened security, the issue starts when one tries to reload nginx. In the event that nginx crashes or needs to reboot, you will always have to re-enter your passphrase to get your entire web server back online.

Use this command to remove the password:

    sudo cp server.key server.key.org sudo openssl rsa -in server.key.org -out server.key

## Step Four—Sign your SSL Certificate

Your certificate is all but done, and you just have to sign it.

Keep in mind that you can specify how long the certificate should remain valid by changing the 365 to the number of days you prefer. As it stands this certificate will expire after one year.

    sudo openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

You are now done making the certificate for your first host.

To create the second certificate, switch into the second directory:

    cd /etc/nginx/ssl/example.org

Repeat the previous three steps for the second certificate. Once both are squared away, you can start adding the certificates to your virtual hosts.

## Step Five—Create the Virtual Hosts

Once you have the certificates saved and ready, you can add in your information in the virtual host file.

Although it’s not required, we can create two virtual host files to store virtual hosts in a separate files.

    sudo nano /etc/nginx/sites-available/example.com

Each file will then contain the virtual host configuration (make sure to edit the **server\_name** , **ssl\_certificate** , and **ssl\_certificate\_key** lines to match your details):

     server { listen 443; server\_name example.com; root /usr/share/nginx/www; index index.html index.htm; ssl on; ssl\_certificate /etc/nginx/ssl/example.com/server.crt; ssl\_certificate\_key /etc/nginx/ssl/example.com/server.key; }

You can then put in the appropriate configuration into the other virtual host file.

    sudo nano /etc/nginx/sites-available/example.org

     server { listen 443; server\_name example.org; root /usr/share/nginx/www; index index.html index.htm; ssl on; ssl\_certificate /etc/nginx/ssl/example.org/server.crt; ssl\_certificate\_key /etc/nginx/ssl/example.org/server.key; }

## Step Six—Activate the Virtual Hosts

The last step is to activate the hosts by creating a symbolic link between the sites-available directory and the sites-enabled directory.

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

    sudo ln -s /etc/nginx/sites-available/example.org /etc/nginx/sites-enabled/example.org

With all of the virtual hosts in place, restart nginx.

    sudo service nginx restart

You should now be able to access both sites, each with its own domain name and SSL certificate.

You can view the sites both with and without the signed SSL certificates by typing in just the domain (eg. _example.com_ or _example.org_) or the domain with the https prefix (_https://example.com_ or _https://example.org_).

By Etel Sverdlov
