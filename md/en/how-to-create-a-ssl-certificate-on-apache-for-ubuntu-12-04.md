---
author: Etel Sverdlov
date: 2012-06-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-apache-for-ubuntu-12-04
---

# How To Create a SSL Certificate on Apache for Ubuntu 12.04

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

### What the Red Means

The lines that the user needs to enter or customize will be in red in this tutorial! The rest should mostly be copy-and-pastable.

### About SSL Certificates

A SSL certificate is a way to encrypt a site's information and create a more secure connection. Additionally, the certificate can show the virtual private server's identification information to site visitors. Certificate Authorities can issue SSL certificates that verify the server's details while a self-signed certificate has no 3rd party corroboration.

## Set Up

The steps in this tutorial require the user to have root privileges on the VPS. You can see how to set that up [here](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04) in steps 3 and 4.

Additionally, you need to have apache already installed and running on your virtual server. If this is not the case, you can download it with this command:

    sudo apt-get install apache2

## Step One—Activate the SSL Module

The next step is to enable SSL on the droplet.

    sudo a2enmod ssl

Follow up by restarting Apache.

    sudo service apache2 restart

## Step Two—Create a New Directory

We need to create a new directory where we will store the server key and certificate

    sudo mkdir /etc/apache2/ssl 

## Step Three—Create a Self Signed SSL Certificate

When we request a new certificate, we can specify how long the certificate should remain valid by changing the 365 to the number of days we prefer. As it stands this certificate will expire after one year.

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt

With this command, we will be both creating the self-signed SSL certificate and the server key that protects it, and placing both of them into the new directory.

This command will prompt terminal to display a lists of fields that need to be filled in.

The most important line is "Common Name". Enter your official domain name here or, if you don't have one yet, your site's IP address.

    You are about to be asked to enter information that will be incorporated into your certificate request. What you are about to enter is what is called a Distinguished Name or a DN. There are quite a few fields but you can leave some blank For some fields there will be a default value, If you enter '.', the field will be left blank. ----- Country Name (2 letter code) [AU]:US State or Province Name (full name) [Some-State]:New York Locality Name (eg, city) []:NYC Organization Name (eg, company) [Internet Widgits Pty Ltd]:Awesome Inc Organizational Unit Name (eg, section) []:Dept of Merriment Common Name (e.g. server FQDN or YOUR name) []:example.com Email Address []:webmaster@awesomeinc.com

## Step Four—Set Up the Certificate

Now we have all of the required components of the finished certificate.The next thing to do is to set up the virtual hosts to display the new certificate. Open up the SSL config file:

     nano /etc/apache2/sites-available/default-ssl

Within the section that begins with &ltVirtualHost \_default\_:443\>, quickly make the following changes. Add a line with your server name right below the Server Admin email:

     ServerName example.com:443

Replace example.com with your DNS approved domain name or server IP address (it should be the same as the common name on the certificate). Find the following three lines, and make sure that they match the extensions below:

    SSLEngine on SSLCertificateFile /etc/apache2/ssl/apache.crt SSLCertificateKeyFile /etc/apache2/ssl/apache.key

Save and Exit out of the file.

## Step Five—Activate the New Virtual Host

Before the website that will come on the 443 port can be activated, we need to enable that Virtual Host:

    sudo a2ensite default-ssl

You are all set. Restarting your Apache server will reload it with all of your changes in place.

    sudo service apache2 reload

In your browser, type https://youraddress, and you will be able to see the new certificate.

## See More

Once you have setup your SSL certificate on the site, you can [Install an FTP server](https://www.digitalocean.com/community/articles/how-to-set-up-vsftpd-on-ubuntu-12-04) if you haven't done so yet.

By Etel Sverdlov
