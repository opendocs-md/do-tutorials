---
author: Justin Ellingwood
date: 2016-04-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-tomcat-8-connections-with-apache-or-nginx-on-ubuntu-16-04
---

# How To Encrypt Tomcat 8 Connections with Apache or Nginx on Ubuntu 16.04

## Introduction

Apache Tomcat is a web server and servlet container designed to serve Java applications. Frequently used in production enterprise deployments and for smaller application needs, Tomcat is both flexible and powerful.

In this guide, we will discuss how to secure your Ubuntu 16.04 Tomcat installation with SSL. By default, upon installation, all communication between the Tomcat server and clients is unencrypted, including any passwords entered or any sensitive data. There are a number of ways that we can incorporate SSL into our Tomcat installation. This guide will cover how to set up a SSL-enabled proxy server to securely negotiate with clients and then hand requests off to Tomcat.

We will cover how to set this up with both **Apache** and **Nginx**.

## Why a Reverse Proxy?

There are a number of ways that you can set up SSL for a Tomcat installation, each with its set of trade-offs. After learning that Tomcat has the ability to encrypt connections natively, it might seem strange that we’d discuss a reverse proxy solution.

SSL with Tomcat has a number of drawbacks that make it difficult to manage:

- **Tomcat, when run as recommended with an unprivileged user, cannot bind to restricted ports like the conventional SSL port 443** : There are workarounds to this, like using the `authbind` program to map an unprivileged program with a restricted port, setting up port forwarding with a firewall, etc., but they still represent additional complexity.
- **SSL with Tomcat is not as widely supported by other software** : Projects like Let’s Encrypt provide no native way of interacting with Tomcat. Furthermore, the Java keystore format requires conventional certificates to be converted before use, which complicates automation.
- **Conventional web servers release more frequently than Tomcat** : This can have significant security implications for your applications. For instance, the supported Tomcat SSL cipher suite can become out-of-date quickly, leaving your applications with suboptimal protection. In the event that security updates are needed, it is likely easier to update a web server than your Tomcat installation.

A reverse proxy solution bypasses many of these issues by simply putting a strong web server in front of the Tomcat installation. The web server can handle client requests with SSL, functionality it is specifically designed to handle. It can then proxy requests to Tomcat running in its normal, unprivileged configuration.

This separation of concerns simplifies the configuration, even if it does mean running an additional piece of software.

## Prerequisites

In order to complete this guide, you will have to have Tomcat already set up on your server. This guide will assume that you used the instructions in our [Tomcat 8 on Ubuntu 16.04 installation guide](how-to-install-apache-tomcat-8-on-ubuntu-16-04) to get set up.

When you have a Tomcat up and running, continue below with the section for your preferred web server. **Apache** starts directly below, while the **Nginx** configuration can be found by skipping ahead a bit.

## (Option 1) Proxying with the Apache Web Server’s `mod_jk`

The Apache web server has a module called `mod_jk` which can communicate directly with Tomcat using the Apache JServ Protocol. A connector for this protocol is enabled by default within Tomcat, so Tomcat is already ready to handle these requests.

### Section Prerequisites

Before we can discuss how to proxy Apache web server connections to Tomcat, you must install and secure an Apache web server.

You can install the Apache web server by following step 1 of [this guide](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04). Do not install MySQL or PHP.

Afterwards, you will need to set up SSL on the server. The way you do this will depend on whether you have a domain name or not.

- **If you have a domain name…** the easiest way to secure your server is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Apache](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) to set this up.
- **If you do not have a domain…** and you are just using this configuration for testing or personal use, you can use a self-signed certificate instead. This provides the same type of encryption, but without domain validation. Follow our [self-signed SSL guide for Apache](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04) to get set up.

When you are finished with these steps, continue below to learn how to hook up the Apache web server to your Tomcat installation.

### Step 1: Install and Configure `mod_jk`

First, we need to install the `mod_jk` module. The Apache web server uses this to communicate with Tomcat using the Apache JServ Protocol.

We can install `mod_jk` from Ubuntu’s default repositories. Update the local package index and install by typing:

    sudo apt-get update
    sudo apt-get install libapache2-mod-jk

The module will be enabled automatically upon installation.

Next, we need to configure the module. The main configuration file is located at `/etc/libapache2-mod-jk/workers.properties`. Open this file now in your text editor:

    sudo nano /etc/libapache2-mod-jk/workers.properties

Inside, find the `workers.tomcat_home` directive. Set this to your Tomcat installation home directory. For our Tomcat installation, that would be `/opt/tomcat`:

/etc/libapache2-mod-jk/workers.properties

    workers.tomcat_home=/opt/tomcat

Save and close the file when you are finished.

### Step 2: Adjust the Apache Virtual Host to Proxy with `mod_jk`

Next, we need to adjust our Apache Virtual Host to proxy requests to our Tomcat installation.

The correct Virtual Host file to open will depend on which method you used to set up SSL.

If you set up a self-signed SSL certificate using the guide linked to above, open the `default-ssl.conf` file:

    sudo nano /etc/apache2/sites-available/default-ssl.conf

If you set up SSL with Let’s Encrypt, the file location will depend on what options you selected during the certificate process. You can find which Virtual Hosts are involved in serving SSL requests by typing:

    sudo apache2ctl -S

Your output will likely begin with something like this:

    OutputVirtualHost configuration:
    *:80 example.com (/etc/apache2/sites-enabled/000-default.conf:1)
    *:443 is a NameVirtualHost
             default server example.com (/etc/apache2/sites-enabled/000-default-le-ssl.conf:2)
             port 443 namevhost example.com (/etc/apache2/sites-enabled/000-default-le-ssl.conf:2)
             port 443 namevhost www.example.com (/etc/apache2/sites-enabled/default-ssl.conf:2)
    
    . . .

Looking at the lines associated with SSL port 443 (lines 3-6 in this example), we can determine which Virtual Hosts files are involved in serving those domains. Here, we see that both the `000-default-le-ssl.conf` file and the `default-ssl.conf` file are involved, so you should edit both of these. Your results will likely differ:

    sudo nano /etc/apache2/sites-enabled/000-default-le-ssl.conf
    sudo nano /etc/apache2/sites-enabled/default-ssl.conf

Regardless of which files you have to open, the procedure will be the same. Somewhere within the `VirtualHost` tags, you should enter the following:

    <VirtualHost *:443>
    
        . . .
    
        JKMount /* ajp13_worker
    
        . . .
    
    </VirtualHost>

Save and close the file. Repeat the above process for any other files you identified that need to be edited.

When you are finished, check your configuration by typing:

    sudo apache2ctl configtest

If the output contains `Syntax OK`, restart the Apache web server process:

    sudo systemctl restart apache2

You should now be able get to your Tomcat installation by visiting the SSL version of your site in your web browser:

    https://example.com

Next, skip past the Nginx configuration below and continue at the section detailing how to restrict access to Tomcat in order to complete your configuration.

## (Option 2) HTTP Proxying with Nginx

Proxying is also easy with Nginx, if you prefer it to the Apache web server. While Nginx does not have a module allowing it to speak the Apache JServ Protocol, it can use its robust HTTP proxying capabilities to communicate with Tomcat.

### Section Prerequisites

Before we can discuss how to proxy Nginx connections to Tomcat, you must install and secure Nginx.

You can install Nginx by following [our guide on installing Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04).

Afterwards, you will need to set up SSL on the server. The way you do this will depend on whether you have a domain name or not.

- **If you have a domain name…** the easiest way to secure your server is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Nginx](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04) to set this up.
- **If you do not have a domain…** and you are just using this configuration for testing or personal use, you can use a self-signed certificate instead. This provides the same type of encryption, but without domain validation. Follow our [self-signed SSL guide for Nginx](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04) to get set up.

When you are finished with these steps, continue below to learn how to hook up the Nginx web server to your Tomcat installation.

### Step 1: Adjusting the Nginx Server Block Configuration

Setting up Nginx to proxy to Tomcat is very straight forward.

Begin by opening the server block file associated with your site. We will assume you are using the default server block file in this guide:

    sudo nano /etc/nginx/sites-available/default

Inside, towards the top of the file, we need to add an `upstream` block. This will outline the connection details so that Nginx knows where our Tomcat server is listening. Place this outside of any of the `server` blocks defined within the file:

/etc/nginx/sites-available/default

    upstream tomcat {
        server 127.0.0.1:8080 fail_timeout=0;
    }
    
    server {
    
        . . .

Next, within the `server` block defined for port 443, modify the `location /` block. We want to pass all requests directly to the `upstream` block we just defined. Comment out the current contents and use the `proxy_pass` directive to pass to the “tomcat” upstream we just defined.

We will also need to include the `proxy_params` configuration within this block. This file defines many of the details of how Nginx will proxy the connection:

/etc/nginx/sites-available/default

    upstream tomcat {
        server 127.0.0.1:8080 fail_timeout=0;
    }
    
    server {
        . . .
    
        location / {
            #try_files $uri $uri/ =404;
            include proxy_params;
            proxy_pass http://tomcat/;
        }
    
        . . .
    }

When you are finished, save and close the file.

### Step 2: Test and Restart Nginx

Next, test to make sure your configuration changes did not introduce any syntax errors:

    sudo nginx -t

If no errors are reported, restart Nginx to implement your changes:

    sudo systemctl restart nginx

You should now be able get to your Tomcat installation by visiting the SSL version of your site in your web browser:

    https://example.com

## Restricting Access to the Tomcat Installation

Now you have SSL encrypted access to your Tomcat installation, we can lock down the Tomcat installation a bit more.

Since we want all of our requests to Tomcat to come through our proxy, we can configure Tomcat to only listen for connections on the local loopback interface. This ensures that outside parties cannot attempt to make requests from Tomcat directly.

Open the `server.xml` file within your Tomcat configuration directory to change these settings:

    sudo nano /opt/tomcat/conf/server.xml

Within this file, we need to modify the **Connector** definitions. Currently there are two Connectors enabled within the configuration. One handles normal HTTP requests on port 8080, while the other handles Apache JServ Protocol requests on port 8009. The configuration will look something like this:

/opt/tomcat/conf/server.xml

    . . .
    
        <Connector port="8080" protocol="HTTP/1.1"
                   connectionTimeout="20000"
                   redirectPort="8443" />
    . . .
    
        <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

In order to restrict access to the local loopback interface, we just need to add an “address” attribute set to `127.0.0.1` in each of these Connector definitions. The end result will look like this:

/opt/tomcat/conf/server.xml

    . . .
    
        <Connector port="8080" protocol="HTTP/1.1"
                   connectionTimeout="20000"
                   address="127.0.0.1"
                   redirectPort="8443" />
    . . .
    
        <Connector port="8009" address="127.0.0.1" protocol="AJP/1.3" redirectPort="8443" />

After you’ve made those two changes, save and close the file.

We need to restart our Tomcat process to implement these changes:

    sudo systemctl restart tomcat

If you followed our Tomcat installation guide, you have a `ufw` firewall enabled on your installation. Now that all of our requests to Tomcat are restricted to the local loopback interface, we can remove the rule from our firewall that allowed external requests to Tomcat.

    sudo ufw delete allow 8080

Your Tomcat installation should now only be accessible through your web server proxy.

## Conclusion

At this point, connections to your Tomcat instance should be encrypted with SSL with the help of a web server proxy. While configuring a separate web server process might increase the software involved in serving your applications, it simplifies the process of securing your traffic significantly.
