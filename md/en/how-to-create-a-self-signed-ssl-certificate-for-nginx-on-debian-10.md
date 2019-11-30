---
author: Brian Boucheron, Kathleen Juell, Hanif Jetha
date: 2019-07-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-10
---

# How To Create a Self-Signed SSL Certificate for Nginx on Debian 10

## Introduction

_TLS_, or transport layer security, and its predecessor _SSL_, which stands for secure sockets layer, are web protocols used to wrap normal traffic in a protected, encrypted wrapper.

Using this technology, servers can send traffic safely between the server and clients without the possibility of the messages being intercepted by outside parties. The certificate system also assists users in verifying the identity of the sites that they are connecting with.

In this guide, we will show you how to set up a self-signed SSL certificate for use with an Nginx web server on a Debian 10 server.

**Note:** A self-signed certificate will encrypt communication between your server and any clients. However, because it is not signed by any of the trusted certificate authorities included with web browsers, users cannot use the certificate to validate the identity of your server automatically.

A self-signed certificate may be appropriate if you do not have a domain name associated with your server and for instances where the encrypted web interface is not user-facing. If you _do_ have a domain name, in many cases it is better to use a CA-signed certificate. To learn how to set up a free trusted certificate with the Let’s Encrypt project, consult [How to Secure Nginx with Let’s Encrypt on Debian 10](how-to-secure-nginx-with-let-s-encrypt-on-debian-10).

## Prerequisites

- One Debian 10 server, a non-root user with `sudo` privileges, and an active firewall. To set these things up, follow the [initial server setup for Debian 10](initial-server-setup-with-debian-10) tutorial.
- Nginx installed on your server, following [How to Install Nginx on Debian 10](how-to-install-nginx-on-debian-10).

## Step 1 — Creating the SSL Certificate

TLS/SSL works by using a combination of a public certificate and a private key. The SSL key is kept secret on the server and is used to encrypt content sent to clients. The SSL certificate is publicly shared with anyone requesting the content. It can be used to decrypt the content signed by the associated SSL key.

We can create a self-signed key and certificate pair with OpenSSL in a single command:

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

You will be asked a series of questions. Before we go over that, let’s take a look at what is happening in the command we are issuing:

- **openssl** : This is the basic command line tool for creating and managing OpenSSL certificates, keys, and other files.
- **req** : This subcommand specifies that we want to use X.509 certificate signing request (CSR) management. The “X.509” is a public key infrastructure standard that SSL and TLS adheres to for its key and certificate management. We want to create a new X.509 cert, so we are using this subcommand.
- **-x509** : This further modifies the previous subcommand by telling the utility that we want to make a self-signed certificate instead of generating a certificate signing request, as would normally happen.
- **-nodes** : This tells OpenSSL to skip the option to secure our certificate with a passphrase. We need Nginx to be able to read the file without user intervention when the server starts up. A passphrase would prevent this from happening because we would have to enter it after every restart.
- **-days 365** : This option sets the length of time that the certificate will be considered valid. We set it for one year here.
- **-newkey rsa:2048** : This specifies that we want to generate a new certificate and a new key at the same time. We did not create the key that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The `rsa:2048` portion tells it to make an RSA key that is 2048 bits long.
- **-keyout** : This line tells OpenSSL where to place the generated private key file that we are creating.
- **-out** : This tells OpenSSL where to place the certificate that we are creating.

As we stated above, these options will create both a key file and a certificate. We will be asked a few questions about our server in order to embed the information correctly in the certificate.

Fill out the prompts appropriately. **The most important line is the one that requests the `Common Name (e.g. server FQDN or YOUR name)`. You need to enter the domain name associated with your server or your server’s public IP address.**

The entirety of the prompts will look something like this:

    OutputCountry Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:New York
    Locality Name (eg, city) []:New York City
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:Bouncy Castles, Inc.
    Organizational Unit Name (eg, section) []:Ministry of Water Slides
    Common Name (e.g. server FQDN or YOUR name) []:your_domain_or_server_IP_address
    Email Address []:admin@your_domain.com

Both of the files you created will be placed in the appropriate subdirectories of the `/etc/ssl` directory.

While we are using OpenSSL, we should also create a strong Diffie-Hellman group, which is used in negotiating [Perfect Forward Secrecy](https://en.wikipedia.org/wiki/Forward_secrecy) with clients.

We can do this by typing:

    sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096

This will take a while, but when it’s done you will have a strong DH group at `/etc/nginx/dhparam.pem` that you can use in your configuration.

## Step 2 — Configuring Nginx to Use SSL

We have created our key and certificate files under the `/etc/ssl` directory. Now we just need to modify our Nginx configuration to take advantage of these.

We will make a few adjustments to our configuration.

1. We will create a configuration snippet containing our SSL key and certificate file locations.
2. We will create a configuration snippet containing strong SSL settings that can be used with any certificates in the future.
3. We will adjust our Nginx server blocks to handle SSL requests and use the two snippets above.

This method of configuring Nginx will allow us to keep clean server blocks and put common configuration segments into reusable modules.

### Creating a Configuration Snippet Pointing to the SSL Key and Certificate

First, let’s create a new Nginx configuration snippet in the `/etc/nginx/snippets` directory.

To properly distinguish the purpose of this file, let’s call it `self-signed.conf`:

    sudo nano /etc/nginx/snippets/self-signed.conf

Within this file, we need to set the `ssl_certificate` directive to our certificate file and the `ssl_certificate_key` to the associated key. Add the following lines to the file:

/etc/nginx/snippets/self-signed.conf

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

When you’ve added those lines, save and close the file.

### Creating a Configuration Snippet with Strong Encryption Settings

Next, we will create another snippet that will define some SSL settings. This will set Nginx up with a strong SSL cipher suite and enable some advanced features that will help keep our server secure.

The parameters we will set can be reused in future Nginx configurations, so we will give the file a generic name:

    sudo nano /etc/nginx/snippets/ssl-params.conf

To set up Nginx SSL securely, we will be using the recommendations by Remy van Elst on the [**Cipherli.st**](https://cipherli.st) site. This site is designed to provide easy-to-consume encryption settings for popular software.

**Note:** The suggested settings on the **Cipherli.st** site offer strong security. Sometimes this comes at the cost of greater client compatibility. If you need to support older clients, there is an alternative list that you can access by clicking the link on the page labeled **Yes, give me a ciphersuite that works with legacy / old software.** That list can be substituted for the items below.

The choice of which config you use will depend largely on what you need to support. They both will provide great security.

For our purposes, we can copy the provided settings in their entirety. We just need to make a few small modifications.

First, we will add our preferred DNS resolver for upstream requests. We will use Google’s for this guide.

Second, we will comment out the line that sets the strict transport security header. Before uncommenting this line, you should take take a moment to read up on [HTTP Strict Transport Security, or HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security), and specifically its [“preload” functionality](https://hstspreload.org/). Preloading HSTS provides increased security, but can have far-reaching consequences if accidentally enabled or enabled incorrectly.

Copy the following into your `ssl-params.conf` snippet file:

/etc/nginx/snippets/ssl-params.conf

    ssl_protocols TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/dhparam.pem;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    ssl_stapling on; # Requires nginx >= 1.3.7
    ssl_stapling_verify on; # Requires nginx => 1.3.7
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable strict transport security for now. You can uncomment the following
    # line if you understand the implications.
    # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

Because we are using a self-signed certificate, SSL stapling will not be used. Nginx will output a warning but continue to operate correctly.

Save and close the file when you are finished.

### Adjusting the Nginx Configuration to Use SSL

Now that we have our snippets, we can adjust our Nginx configuration to enable SSL.

We will assume in this guide that you are using a custom server block configuration file in the `/etc/nginx/sites-available` directory, as outlined in [Step 5](how-to-install-nginx-on-debian-10#step-5-%E2%80%93-setting-up-server-blocks) of the prerequisite tutorial on installing Nginx. We will use `/etc/nginx/sites-available/your_domain` for this example. Substitute your configuration filename/domain name as needed.

Before we go any further, let’s back up our current configuration file:

    sudo cp /etc/nginx/sites-available/your_domain /etc/nginx/sites-available/your_domain.bak

Now, open the configuration file to make adjustments:

    sudo nano /etc/nginx/sites-available/your_domain

If you followed the prerequisites, your server block will look like this:

/etc/nginx/sites-available/your\_domain

    server {
        listen 80;
        listen [::]:80;
    
        root /var/www/your_domain/html;
        index index.html index.htm index.nginx-debian.html;
    
        server_name your_domain www.your_domain;
    
        location / {
                try_files $uri $uri/ =404;
        }
    
    }

Your file may be in a different order, and instead of the `root` and `index` directives you may have some `location`, `proxy_pass`, or other custom configuration statements. This is ok, as we only need to update the `listen` directives and include our SSL snippets. We will modify this existing server block to serve SSL traffic on port `443`, and then create a new server block to respond on port `80` and automatically redirect traffic to port `443`.

**Note:** We will use a 302 redirect until we have verified that everything is working properly. Afterwards, we can change this to a permanent 301 redirect.

In your existing configuration file, update the two `listen` statements to use port `443` and SSL, and then include the two snippet files we created in previous steps:

/etc/nginx/sites-available/your\_domain

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        include snippets/self-signed.conf;
        include snippets/ssl-params.conf;
    
        root /var/www/your_domain/html;
        index index.html index.htm index.nginx-debian.html;
    
        server_name your_domain www.your_domain;
    
        . . .
    }

Next, paste a second server block into the configuration file, after the closing bracket (`}`) of the first block:

/etc/nginx/sites-available/your\_domain

    . . .
    server {
        listen 80;
        listen [::]:80;
    
        server_name your_domain www.your_domain;
    
        return 302 https://$server_name$request_uri;
    }

This is a bare-bones configuration that listens on port `80` and performs the redirect to HTTPS. Save and close the file when you are finished editing.

## Step 3 — Adjusting the Firewall

If you have the `ufw` firewall enabled, as recommended by the prerequisite guides, you’ll need to adjust the settings to allow for SSL traffic. Luckily, Nginx registers a few profiles with `ufw` upon installation.

We can see the available profiles by typing:

    sudo ufw app list

You should see a list like this:

    OutputAvailable applications:
    . . .
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
    . . .

You can see the current setting by typing:

    sudo ufw status

If you followed the prerequisites, it will look like this, meaning that only HTTP traffic is allowed to the web server:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx HTTP ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx HTTP (v6) ALLOW Anywhere (v6)

To additionally let in HTTPS traffic, we can allow the “Nginx Full” profile and then delete the redundant “Nginx HTTP” profile allowance:

    sudo ufw allow 'Nginx Full'
    sudo ufw delete allow 'Nginx HTTP'

Your status should now look like this:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx Full ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx Full (v6) ALLOW Anywhere (v6)

With our firewall configured properly, we can move on to testing our Nginx configuration.

## Step 4 — Enabling the Changes in Nginx

Now that we’ve made our changes and adjusted our firewall, we can restart Nginx to implement our new changes.

First, we should check to make sure that there are no syntax errors in our files. We can do this by typing:

    sudo nginx -t

If everything is successful, you will get a result that looks like this:

    Outputnginx: [warn] "ssl_stapling" ignored, issuer certificate not found for certificate "/etc/ssl/certs/nginx-selfsigned.crt"
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

Note the warning in the beginning. As discussed earlier, this particular setting throws a warning since our self-signed certificate can’t use SSL stapling. This is expected and our server can still encrypt connections correctly.

If your output matches the above, your configuration file has no syntax errors. We can safely restart Nginx to implement our changes:

    sudo systemctl restart nginx

With our Nginx configuration tested, we can move on to testing our setup.

## Step 5 — Testing Encryption

We’re now ready to test our SSL server.

Open your web browser and type `https://` followed by your server’s domain name or IP into the address bar:

    https://your_domain_or_server_IP

Because the certificate we created isn’t signed by one of your browser’s trusted certificate authorities, you will likely see a scary looking warning like the one below (the following appears when using Google Chrome) :

![Nginx self-signed cert warning](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_ssl_1604/self_signed_warning.png)

This is expected and normal. We are only interested in the encryption aspect of our certificate, not the third party validation of our host’s authenticity. Click “ADVANCED” and then the link provided to proceed to your host:

![Nginx self-signed override](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_ssl_1604/warning_override.png)

You should be taken to your site. If you look in the browser address bar, you will see a lock with an “x” over it. In this case, this just means that the certificate cannot be validated. It is still encrypting your connection.

If you configured Nginx with two server blocks, automatically redirecting HTTP content to HTTPS, you can also check whether the redirect functions correctly:

    http://server_domain_or_IP

If this results in the same icon, this means that your redirect worked correctly.

## Step 6 — Changing to a Permanent Redirect

If your redirect worked correctly and you are sure you want to allow only encrypted traffic, you should modify the Nginx configuration to make the redirect permanent.

Open your server block configuration file again:

    sudo nano /etc/nginx/sites-available/<^>your_domain^>

Find the `return 302` and change it to `return 301`:

/etc/nginx/sites-available/your\_domain

        return 301 https://$server_name$request_uri;

Save and close the file.

Check your configuration for syntax errors:

    sudo nginx -t

When you’re ready, restart Nginx to make the redirect permanent:

    sudo systemctl restart nginx

## Conclusion

You have configured your Nginx server to use strong encryption for client connections. This will allow you serve requests securely, and will prevent outside parties from reading your traffic.
