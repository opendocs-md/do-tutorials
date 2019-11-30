---
author: Josh Barnett
date: 2014-11-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-an-ssl-certificate-on-apache-for-centos-7
---

# How To Create an SSL Certificate on Apache for CentOS 7

## Introduction

**TLS** , or “transport layer security”, and its predecessor **SSL** , which stands for “secure sockets layer”, are web protocols used to wrap normal traffic in a protected, encrypted wrapper. Using this technology, servers can send traffic safely between the server and the client without the concern that the messages will be intercepted and read by an outside party. The certificate system also assists users in verifying the identity of the sites that they are connecting with.

In this guide, we will show you how to set up a self-signed SSL certificate for use with an Apache web server on a CentOS 7 machine.

**Note:** A self-signed certificate will encrypt communication between your server and any clients. However, because it is not signed by any of the trusted certificate authorities included with web browsers, users cannot use the certificate to validate the identity of your server automatically.

A self-signed certificate may be appropriate if you do not have a domain name associated with your server and for instances where the encrypted web interface is not user-facing. If you do have a domain name, in many cases it is better to use a CA-signed certificate. You can find out how to set up a free trusted certificate with the Let’s Encrypt project [here](how-to-secure-apache-with-let-s-encrypt-on-centos-7).

## Prerequisites

Before you begin with this guide, there are a few steps that need to be completed first.

You will need access to a CentOS 7 server with a non-root user that has `sudo` privileges. If you haven’t configured this yet, you can run through the [CentOS 7 initial server setup guide](initial-server-setup-with-centos-7) to create this account.

You will also need to have Apache installed in order to configure virtual hosts for it. If you haven’t already done so, you can use `yum` to install Apache through CentOS’s default software repositories:

    sudo yum install httpd

Next, enable Apache as a CentOS service so that it will automatically start after a reboot:

    sudo systemctl enable httpd.service

After these steps are complete, you can log in as your non-root user account through SSH and continue with the tutorial.

## Step One: Install Mod SSL

In order to set up the self-signed certificate, we first have to be sure that `mod_ssl`, an Apache module that provides support for SSL encryption, is installed the server. We can install `mod_ssl` with the `yum` command:

    sudo yum install mod_ssl

The module will automatically be enabled during installation, and Apache will be able to start using an SSL certificate after it is restarted. You don’t need to take any additional steps for `mod_ssl` to be ready for use.

## Step Two: Create a New Certificate

Now that Apache is ready to use encryption, we can move on to generating a new SSL certificate. The certificate will store some basic information about your site, and will be accompanied by a key file that allows the server to securely handle encrypted data.

First, we need to create a new directory to store our private key (the `/etc/ssl/certs` directory is already available to hold our certificate file):

    sudo mkdir /etc/ssl/private

Since files kept within this directory must be kept strictly private, we will modify the permissions to make sure only the root user has access:

    sudo chmod 700 /etc/ssl/private

Now that we have a location to place our files, we can create the SSL key and certificate files with `openssl`:

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

After you enter the request, you will be taken to a prompt where you can enter information about your website. Before we go over that, let’s take a look at what is happening in the command we are issuing:

- **openssl** : This is the basic command line tool for creating and managing OpenSSL certificates, keys, and other files.
- **req -x509** : This specifies that we want to use X.509 certificate signing request (CSR) management. The “X.509” is a public key infrastructure standard that SSL and TLS adhere to for key and certificate management.
- **-nodes** : This tells OpenSSL to skip the option to secure our certificate with a passphrase. We need Apache to be able to read the file, without user intervention, when the server starts up. A passphrase would prevent this from happening, since we would have to enter it after every restart.
- **-days 365** : This option sets the length of time that the certificate will be considered valid. We set it for one year here.
- **-newkey rsa:2048** : This specifies that we want to generate a new certificate and a new key at the same time. We did not create the key that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The `rsa:2048` portion tells it to make an RSA key that is 2048 bits long.
- **-keyout** : This line tells OpenSSL where to place the generated private key file that we are creating.
- **-out** : This tells OpenSSL where to place the certificate that we are creating.

Fill out the prompts appropriately. The most important line is the one that requests the `Common Name`. You need to enter the domain name that you want to be associated with your server. You can enter the public IP address instead if you do not have a domain name.

The full list of prompts will look something like this:

    Country Name (2 letter code) [XX]:US
    State or Province Name (full name) []:Example
    Locality Name (eg, city) [Default City]:Example 
    Organization Name (eg, company) [Default Company Ltd]:Example Inc
    Organizational Unit Name (eg, section) []:Example Dept
    Common Name (eg, your name or your server's hostname) []:example.com
    Email Address []:webmaster@example.com

Both of the files you created will be placed in the appropriate subdirectories of the `/etc/ssl` directory.

While we are using OpenSSL, we should also create a strong Diffie-Hellman group, which is used in negotiating [Perfect Forward Secrecy](https://en.wikipedia.org/wiki/Forward_secrecy) with clients.

We can do this by typing:

    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

This may take a few minutes, but when it’s done you will have a strong DH group at `/etc/ssl/certs/dhparam.pem` that we can use in our configuration.

Since the version of Apache that ships with CentOS 7 does not include the `SSLOpenSSLConfCmd` directive, we will have to manually append the generated file to the end of our self-signed certificate. To do this, type:

    cat /etc/ssl/certs/dhparam.pem | sudo tee -a /etc/ssl/certs/apache-selfsigned.crt

The `apache-selfsigned.crt` file should now have both the certificate and the generated Diffie-Hellman group.

## Step Three: Set Up the Certificate

We now have all of the required components of the finished interface. The next thing to do is to set up the virtual hosts to display the new certificate.

Open Apache’s SSL configuration file in your text editor with root privileges:

    sudo vi /etc/httpd/conf.d/ssl.conf

Find the section that begins with `<VirtualHost _default_:443>`. We need to make a few changes here to ensure that our SSL certificate is correctly applied to our site.

### Adjusting the VirtualHost Directives

First, uncomment the `DocumentRoot` line and edit the address in quotes to the location of your site’s document root. By default, this will be in `/var/www/html`, and you don’t need to change this line if you have not changed the document root for your site. However, if you followed a guide like our [Apache virtual hosts setup guide](how-to-set-up-apache-virtual-hosts-on-centos-7), your site’s document root may be different.

Next, uncomment the `ServerName` line and replace `www.example.com` with your domain name or server IP address (whichever one you put as the common name in your certificate):

/etc/httpd/conf.d/ssl.conf

    <VirtualHost _default_:443>
    . . .
    DocumentRoot "/var/www/example.com/public_html"
    ServerName www.example.com:443

Next, find the `SSLProtocol` and `SSLCipherSuite` lines and either delete them or comment them out. The configuration we be pasting in a moment will offer more secure settings than the default included with CentOS’s Apache:

/etc/httpd/conf.d/ssl.conf

    . . .
    # SSLProtocol all -SSLv2
    . . .
    # SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5:!SEED:!IDEA

Find the `SSLCertificateFile` and `SSLCertificateKeyFile` lines and change them to the directory we made at `/etc/httpd/ssl`:

/etc/httpd/conf.d/ssl.conf

    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

We’re now done with the changes within the actual `VirtualHost` block. The next changes will take place after the ending `</VirtualHost>` tag within this same file.

### Setting Up Secure SSL Parameters

Next, to set up Apache SSL more securely, we will be using the recommendations by [Remy van Elst](https://raymii.org/s/static/About.html) on the [Cipherli.st](https://cipherli.st) site. This site is designed to provide easy-to-consume encryption settings for popular software. You can read more about his decisions regarding the Apache choices [here](https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html).

**Note:** The suggested settings on the site linked to above offer strong security. Sometimes, this comes at the cost of greater client compatibility. If you need to support older clients, there is an alternative list that can be accessed by clicking the link on the page labelled “Yes, give me a ciphersuite that works with legacy / old software.” That list can be substituted for the items copied below.

The choice of which config you use will depend largely on what you need to support. They both will provide great security.

For our purposes, we can copy the provided settings in their entirety. We will just make two small changes.

Take a moment to read up on [HTTP Strict Transport Security, or HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), and specifically about the [“preload” functionality](https://hstspreload.appspot.com/). Preloading HSTS provides increased security, but can have far reaching consequences if accidentally enabled or enabled incorrectly. In this guide, we will not preload the settings, but you can modify that if you are sure you understand the implications.

The other change we will make is to comment out the `SSLSessionTickets` directive, since this isn’t available in the version of Apache shipped with CentOS 7.

Paste in the settings from the site **AFTER** the end of the `VirtualHost` block:

/etc/httpd/conf.d/ssl.conf

        . . .
    </VirtualHost>
    . . .
    
    # Begin copied text
    # from https://cipherli.st/
    # and https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html
    
    SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
    SSLProtocol All -SSLv2 -SSLv3
    SSLHonorCipherOrder On
    # Disable preloading HSTS for now. You can use the commented out header line that includes
    # the "preload" directive if you understand the implications.
    #Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
    Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff
    # Requires Apache >= 2.4
    SSLCompression off 
    SSLUseStapling on 
    SSLStaplingCache "shmcb:logs/stapling-cache(150000)" 
    # Requires Apache >= 2.4.11
    # SSLSessionTickets Off

When you are finished making these changes, you can save and close the file.

### (Recommended) Modify the Unencrypted Virtual Host File to Redirect to HTTPS

As it stands now, the server will provide both unencrypted HTTP and encrypted HTTPS traffic. For better security, it is recommended in most cases to redirect HTTP to HTTPS automatically. If you do not want or need this functionality, you can safely skip this section.

To redirect all traffic to be SSL encrypted, create and open a file ending in `.conf` in the `/etc/httpd/conf.d` directory:

    sudo vi /etc/httpd/conf.d/non-ssl.conf

Inside, create a `VirtualHost` block to match requests on port 80. Inside, use the `ServerName` directive to again match your domain name or IP address. Then, use `Redirect` to match any requests and send them to the SSL `VirtualHost`. Make sure to include the trailing slash:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
            ServerName www.example.com
            Redirect "/" "https://www.example.com/"
    </VirtualHost>

Save and close this file when you are finished.

## Step Four: Activate the Certificate

By now, you have created an SSL certificate and configured your web server to apply it to your site. To apply all of these changes and start using your SSL encryption, you can restart the Apache server to reload its configurations and modules.

First, check your configuration file for syntax errors by typing:

    sudo apachectl configtest

As long as the output ends with `Syntax OK`, you are safe to continue. If this is not part of your output, check the syntax of your files and try again:

    Output. . .
    Syntax OK

Restart the Apache server to apply your changes by typing:

    sudo systemctl restart httpd.service

Next, make sure port 80 and 443 are open in your firewall. If you are not running a firewall, you can skip ahead.

If you have a **firewalld** firewall running, you can open these ports by typing:

    sudo firewall-cmd --add-service=http
    sudo firewall-cmd --add-service=https
    sudo firewall-cmd --runtime-to-permanent

If have an **iptables** firewall running, the commands you need to run are highly dependent on your current rule set. For a basic rule set, you can add HTTP and HTTPS access by typing:

    sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT

In your web browser, try visiting your domain name or IP with `https://` to see your new certificate in action.

    https://example.com/

Your web browser will likely warn you that the site’s security certificate is not trusted. Since your certificate isn’t signed by a certificate authority that the browser trusts, the browser is unable to verify the identity of the server that you are trying to connect to. We created a self-signed certificate instead of a trusted CA-signed certificate, so this makes perfect sense.

Once you add an exception to the browser’s identity verification, you will be allowed to proceed to your newly secured site.

## Conclusion

You have configured your Apache server to handle both HTTP and HTTPS requests. This will help you communicate with clients securely and avoid outside parties from being able to read your traffic.

If you are planning on using SSL for a public website, you should probably purchase an SSL certificate from a trusted certificate authority to prevent the scary warnings from being shown to each of your visitors.
