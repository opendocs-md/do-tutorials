---
author: Justin Ellingwood
date: 2016-04-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04
---

# How To Create a Self-Signed SSL Certificate for Apache in Ubuntu 16.04

## Introduction

**TLS** , or transport layer security, and its predecessor **SSL** , which stands for secure sockets layer, are web protocols used to wrap normal traffic in a protected, encrypted wrapper.

Using this technology, servers can send traffic safely between the server and clients without the possibility of the messages being intercepted by outside parties. The certificate system also assists users in verifying the identity of the sites that they are connecting with.

In this guide, we will show you how to set up a self-signed SSL certificate for use with an Apache web server on an Ubuntu 16.04 server.

**Note:** A self-signed certificate will encrypt communication between your server and any clients. However, because it is not signed by any of the trusted certificate authorities included with web browsers, users cannot use the certificate to validate the identity of your server automatically.

A self-signed certificate may be appropriate if you do not have a domain name associated with your server and for instances where the encrypted web interface is not user-facing. If you _do_ have a domain name, in many cases it is better to use a CA-signed certificate. You can find out how to set up a free trusted certificate with the Let’s Encrypt project [here](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

## Prerequisites

Before you begin, you should have a non-root user configured with `sudo` privileges. You can learn how to set up such a user account by following our [initial server setup for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

You will also need to have the Apache web server installed. If you would like to install an entire LAMP (Linux, Apache, MySQL, PHP) stack on your server, you can follow our guide on [setting up LAMP on Ubuntu 16.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04). If you just want the Apache web server, skip the steps pertaining to PHP and MySQL in the guide.

When you have completed the prerequisites, continue below.

## Step 1: Create the SSL Certificate

TLS/SSL works by using a combination of a public certificate and a private key. The SSL key is kept secret on the server. It is used to encrypt content sent to clients. The SSL certificate is publicly shared with anyone requesting the content. It can be used to decrypt the content signed by the associated SSL key.

We can create a self-signed key and certificate pair with OpenSSL in a single command:

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

You will be asked a series of questions. Before we go over that, let’s take a look at what is happening in the command we are issuing:

- **openssl** : This is the basic command line tool for creating and managing OpenSSL certificates, keys, and other files.
- **req** : This subcommand specifies that we want to use X.509 certificate signing request (CSR) management. The “X.509” is a public key infrastructure standard that SSL and TLS adheres to for its key and certificate management. We want to create a new X.509 cert, so we are using this subcommand.
- **-x509** : This further modifies the previous subcommand by telling the utility that we want to make a self-signed certificate instead of generating a certificate signing request, as would normally happen.
- **-nodes** : This tells OpenSSL to skip the option to secure our certificate with a passphrase. We need Apache to be able to read the file, without user intervention, when the server starts up. A passphrase would prevent this from happening because we would have to enter it after every restart.
- **-days 365** : This option sets the length of time that the certificate will be considered valid. We set it for one year here.
- **-newkey rsa:2048** : This specifies that we want to generate a new certificate and a new key at the same time. We did not create the key that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The `rsa:2048` portion tells it to make an RSA key that is 2048 bits long.
- **-keyout** : This line tells OpenSSL where to place the generated private key file that we are creating.
- **-out** : This tells OpenSSL where to place the certificate that we are creating.

As we stated above, these options will create both a key file and a certificate. We will be asked a few questions about our server in order to embed the information correctly in the certificate.

Fill out the prompts appropriately. **The most important line is the one that requests the `Common Name (e.g. server FQDN or YOUR name)`. You need to enter the domain name associated with your server or, more likely, your server’s public IP address.**

The entirety of the prompts will look something like this:

    OutputCountry Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York City
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:Bouncy Castles, Inc.
    Organizational Unit Name (eg, section) []:Ministry of Water Slides
    Common Name (e.g. server FQDN or YOUR name) []:server_IP_address
    Email Address []:admin@your_domain.com

Both of the files you created will be placed in the appropriate subdirectories of the `/etc/ssl` directory.

While we are using OpenSSL, we should also create a strong Diffie-Hellman group, which is used in negotiating [Perfect Forward Secrecy](https://en.wikipedia.org/wiki/Forward_secrecy) with clients.

We can do this by typing:

    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

This may take a few minutes, but when it’s done you will have a strong DH group at `/etc/ssl/certs/dhparam.pem` that we can use in our configuration.

## Step 2: Configure Apache to Use SSL

We have created our key and certificate files under the `/etc/ssl` directory. Now we just need to modify our Apache configuration to take advantage of these.

We will make a few adjustments to our configuration:

1. We will create a configuration snippet to specify strong default SSL settings.
2. We will modify the included SSL Apache Virtual Host file to point to our generated SSL certificates.
3. (Recommended) We will modify the unencrypted Virtual Host file to automatically redirect requests to the encrypted Virtual Host.

When we are finished, we should have a secure SSL configuration.

### Create an Apache Configuration Snippet with Strong Encryption Settings

First, we will create an Apache configuration snippet to define some SSL settings. This will set Apache up with a strong SSL cipher suite and enable some advanced features that will help keep our server secure. The parameters we will set can be used by any Virtual Hosts enabling SSL.

Create a new snippet in the `/etc/apache2/conf-available` directory. We will name the file `ssl-params.conf` to make its purpose clear:

    sudo nano /etc/apache2/conf-available/ssl-params.conf

To set up Apache SSL securely, we will be using the recommendations by [Remy van Elst](https://raymii.org/s/static/About.html) on the [Cipherli.st](https://cipherli.st) site. This site is designed to provide easy-to-consume encryption settings for popular software. You can read more about his decisions regarding the Apache choices [here](https://raymii.org/s/tutorials/Strong_SSL_Security_On_Apache2.html).

The suggested settings on the site linked to above offer strong security. Sometimes, this comes at the cost of greater client compatibility. If you need to support older clients, there is an alternative list that can be accessed by clicking the link on the page labelled “Yes, give me a ciphersuite that works with legacy / old software.” That list can be substituted for the items copied below.

The choice of which config you use will depend largely on what you need to support. They both will provide great security.

For our purposes, we can copy the provided settings in their entirety. We will just make two small changes.

Set the `SSLOpenSSLConfCmd DHParameters` directive to point to the Diffie-Hellman file we generated earlier. Also, take a moment to read up on [HTTP Strict Transport Security, or HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), and specifically about the [“preload” functionality](https://hstspreload.appspot.com/). Preloading HSTS provides increased security, but can have far reaching consequences if accidentally enabled or enabled incorrectly. In this guide, we will not preload the settings, but you can modify that if you are sure you understand the implications:

/etc/apache2/conf-available/ssl-params.conf

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
    SSLSessionTickets Off
    SSLUseStapling on 
    SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
    
    SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"

Save and close the file when you are finished.

### Modify the Default Apache SSL Virtual Host File

Next, let’s modify `/etc/apache2/sites-available/default-ssl.conf`, the default Apache SSL Virtual Host file. If you are using a different server block file, substitute it’s name in the commands below.

Before we go any further, let’s back up the original SSL Virtual Host file:

    sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak

Now, open the SSL Virtual Host file to make adjustments:

    sudo nano /etc/apache2/sites-available/default-ssl.conf

Inside, with most of the comments removed, the Virtual Host file should look something like this by default:

/etc/apache2/sites-available/default-ssl.conf

    <IfModule mod_ssl.c>
            <VirtualHost _default_:443>
                    ServerAdmin webmaster@localhost
    
                    DocumentRoot /var/www/html
    
                    ErrorLog ${APACHE_LOG_DIR}/error.log
                    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
                    SSLEngine on
    
                    SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
                    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
    
                    <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                    SSLOptions +StdEnvVars
                    </FilesMatch>
                    <Directory /usr/lib/cgi-bin>
                                    SSLOptions +StdEnvVars
                    </Directory>
    
                    # BrowserMatch "MSIE [2-6]" \
                    # nokeepalive ssl-unclean-shutdown \
                    # downgrade-1.0 force-response-1.0
    
            </VirtualHost>
    </IfModule>

We will be making some minor adjustments to the file. We will set the normal things we’d want to adjust in a Virtual Host file (ServerAdmin email address, ServerName, etc.), adjust the SSL directives to point to our certificate and key files, and uncomment one section that provides compatibility for older browsers.

After making these changes, your server block should look similar to this:

/etc/apache2/sites-available/default-ssl.conf

    <IfModule mod_ssl.c>
            <VirtualHost _default_:443>
                    ServerAdmin your_email@example.com
                    ServerName server_domain_or_IP
    
                    DocumentRoot /var/www/html
    
                    ErrorLog ${APACHE_LOG_DIR}/error.log
                    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
                    SSLEngine on
    
                    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
                    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
    
                    <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                    SSLOptions +StdEnvVars
                    </FilesMatch>
                    <Directory /usr/lib/cgi-bin>
                                    SSLOptions +StdEnvVars
                    </Directory>
    
                    BrowserMatch "MSIE [2-6]" \
                                   nokeepalive ssl-unclean-shutdown \
                                   downgrade-1.0 force-response-1.0
    
            </VirtualHost>
    </IfModule>

Save and close the file when you are finished.

### (Recommended) Modify the Unencrypted Virtual Host File to Redirect to HTTPS

As it stands now, the server will provide both unencrypted HTTP and encrypted HTTPS traffic. For better security, it is recommended in most cases to redirect HTTP to HTTPS automatically. If you do not want or need this functionality, you can safely skip this section.

To adjust the unencrypted Virtual Host file to redirect all traffic to be SSL encrypted, we can open the `/etc/apache2/sites-available/000-default.conf` file:

    sudo nano /etc/apache2/sites-available/000-default.conf

Inside, within the `VirtualHost` configuration blocks, we just need to add a `Redirect` directive, pointing all traffic to the SSL version of the site:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
            . . .
    
            Redirect "/" "https://your_domain_or_IP/"
    
            . . .
    </VirtualHost>

Save and close the file when you are finished.

## Step 3: Adjust the Firewall

If you have the `ufw` firewall enabled, as recommended by the prerequisite guides, might need to adjust the settings to allow for SSL traffic. Luckily, Apache registers a few profiles with `ufw` upon installation.

We can see the available profiles by typing:

    sudo ufw app list

You should see a list like this:

    OutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

You can see the current setting by typing:

    sudo ufw status

If you allowed only regular HTTP traffic earlier, your output might look like this:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Apache ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Apache (v6) ALLOW Anywhere (v6)

To additionally let in HTTPS traffic, we can allow the “Apache Full” profile and then delete the redundant “Apache” profile allowance:

    sudo ufw allow 'Apache Full'
    sudo ufw delete allow 'Apache'

Your status should look like this now:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Apache Full ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Apache Full (v6) ALLOW Anywhere (v6)

## Step 4: Enable the Changes in Apache

Now that we’ve made our changes and adjusted our firewall, we can enable the SSL and headers modules in Apache, enable our SSL-ready Virtual Host, and restart Apache.

We can enable `mod_ssl`, the Apache SSL module, and `mod_headers`, needed by some of the settings in our SSL snippet, with the `a2enmod` command:

    sudo a2enmod ssl
    sudo a2enmod headers

Next, we can enable our SSL Virtual Host with the `a2ensite` command:

    sudo a2ensite default-ssl

We will also need to enable our `ssl-params.conf` file, to read in the values we set:

    sudo a2enconf ssl-params

At this point, our site and the necessary modules are enabled. We should check to make sure that there are no syntax errors in our files. We can do this by typing:

    sudo apache2ctl configtest

If everything is successful, you will get a result that looks like this:

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

The first line is just a message telling you that the `ServerName` directive is not set globally. If you want to get rid of that message, you can set `ServerName` to your server’s domain name or IP address in `/etc/apache2/apache2.conf`. This is optional as the message will do no harm.

If your output has `Syntax OK` in it, your configuration file has no syntax errors. We can safely restart Apache to implement our changes:

    sudo systemctl restart apache2

## Step 5: Test Encryption

Now, we’re ready to test our SSL server.

Open your web browser and type `https://` followed by your server’s domain name or IP into the address bar:

    https://server_domain_or_IP

Because the certificate we created isn’t signed by one of your browser’s trusted certificate authorities, you will likely see a scary looking warning like the one below:

![Apache self-signed cert warning](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apache_ssl_1604/self_signed_warning.png)

This is expected and normal. We are only interested in the encryption aspect of our certificate, not the third party validation of our host’s authenticity. Click “ADVANCED” and then the link provided to proceed to your host anyways:

![Apache self-signed override](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apache_ssl_1604/warning_override.png)

You should be taken to your site. If you look in the browser address bar, you will see a lock with an “x” over it. In this case, this just means that the certificate cannot be validated. It is still encrypting your connection.

If you configured Apache to redirect HTTP to HTTPS, you can also check whether the redirect functions correctly:

    http://server_domain_or_IP

If this results in the same icon, this means that your redirect worked correctly.

## Step 6: Change to a Permanent Redirect

If your redirect worked correctly and you are sure you want to allow only encrypted traffic, you should modify the unencrypted Apache Virtual Host again to make the redirect permanent.

Open your server block configuration file again:

    sudo nano /etc/apache2/sites-available/000-default.conf

Find the `Redirect` line we added earlier. Add `permanent` to that line, which changes the redirect from a 302 temporary redirect to a 301 permanent redirect:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
            . . .
    
            Redirect permanent "/" "https://your_domain_or_IP/"
    
            . . .
    </VirtualHost>

Save and close the file.

Check your configuration for syntax errors:

    sudo apache2ctl configtest

When you’re ready, restart Apache to make the redirect permanent:

    sudo systemctl restart apache2

## Conclusion

You have configured your Apache server to use strong encryption for client connections. This will allow you serve requests securely, and will prevent outside parties from reading your traffic.
