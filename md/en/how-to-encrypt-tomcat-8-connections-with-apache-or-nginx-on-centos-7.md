---
author: Justin Ellingwood
date: 2017-01-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-encrypt-tomcat-8-connections-with-apache-or-nginx-on-centos-7
---

# How To Encrypt Tomcat 8 Connections with Apache or Nginx on CentOS 7

## Introduction

Apache Tomcat is a web server and servlet container designed to serve Java applications. Frequently used in production enterprise deployments and for smaller application needs, Tomcat is both flexible and powerful.

In this guide, we will discuss how to secure your CentOS 7 Tomcat installation with SSL. By default, upon installation, all communication between the Tomcat server and clients is unencrypted, including any passwords entered or any sensitive data. There are a number of ways that we can incorporate SSL into our Tomcat installation. This guide will cover how to set up a SSL-enabled proxy server to securely negotiate with clients and then hand requests off to Tomcat.

We will cover how to set this up with both **Apache** and **Nginx**.

## Why a Reverse Proxy?

There are a number of ways that you can set up SSL for a Tomcat installation, each with its set of trade-offs. After learning that Tomcat has the ability to encrypt connections natively, it might seem strange that we’d discuss a reverse proxy solution.

SSL with Tomcat has a number of drawbacks that make it difficult to manage:

- **Tomcat, when run as recommended with an unprivileged user, cannot bind to restricted ports like the conventional SSL port 443** : There are workarounds to this, like using the `authbind` program to map an unprivileged program with a restricted port, setting up port forwarding with a firewall, etc., but they each introduce additional complexity.
- **SSL with Tomcat is not as widely supported by other software** : Projects like Let’s Encrypt provide no native way of interacting with Tomcat. Furthermore, the Java keystore format requires conventional certificates to be converted before use, which complicates automation.
- **Conventional web servers release more frequently than Tomcat** : This can have significant security implications for your applications. For instance, the supported Tomcat SSL cipher suite can become out-of-date quickly, leaving your applications with suboptimal protection. In the event that security updates are needed, it is likely easier to update a web server than your Tomcat installation.

A reverse proxy solution bypasses many of these issues by simply putting a strong web server in front of the Tomcat installation. The web server can handle client requests with SSL, functionality it is specifically designed to handle. It can then proxy requests to Tomcat running in its normal, unprivileged configuration.

This separation of concerns simplifies the configuration, even if it does mean running an additional piece of software.

## Prerequisites

In order to complete this guide, you will have to have Tomcat already set up on your server. This guide will assume that you used the instructions in our [Tomcat 8 on CentOS 7 installation guide](how-to-install-apache-tomcat-8-on-centos-7) to get set up.

When you have a Tomcat up and running, continue below with the section for your preferred web server. **Apache** starts directly below, while the **Nginx** configuration can be found by skipping ahead a bit.

## (Option 1) Proxying with the Apache Web Server’s `mod_jk`

The Apache web server has a module called `mod_jk` which can communicate directly with Tomcat using the Apache “JServ” Protocol. A connector for this protocol is enabled by default within Tomcat, so Tomcat is already ready to handle these requests.

### Section Prerequisites

Before we can discuss how to proxy Apache web server connections to Tomcat, you must install and secure an Apache web server.

You can install the Apache web server by following step 1 of [the CentOS 7 LAMP installation guide](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7). Do not install MySQL or PHP.

Afterwards, you will need to set up SSL on the server. The way you do this will depend on whether you have a domain name or not.

- **If you have a domain name…** the easiest way to secure your server is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Apache](how-to-secure-apache-with-let-s-encrypt-on-centos-7) to set this up.
- **If you do not have a domain…** and you are just using this configuration for testing or personal use, you can use a self-signed certificate instead. This provides the same type of encryption, but without domain validation. Follow our [self-signed SSL guide for Apache](how-to-create-an-ssl-certificate-on-apache-for-centos-7) to get set up.

When you are finished with these steps, continue below to learn how to hook up the Apache web server to your Tomcat installation.

### Step 1: Compile and Install `mod_jk`

While Tomcat itself comes with a JServ connector, the CentOS 7 package repositories do not include the `mod_jk` module that the Apache web server needs to communicate using that protocol. To add this functionality, we will have to download and compile the connector from the Tomcat project’s site.

Before we download the source code for the connector, we will need to install the necessary build and runtime dependencies from the CentOS repositories. We will be installing GCC to compile the connector and the Apache web server development files so that the required Apache library is available.

    sudo yum install gcc httpd-devel

Once the dependencies are installed, move into a writable directory and download the connector source code. You can find the latest version on the [Tomcat connector download page](https://tomcat.apache.org/download-connectors.cgi). Copy the link associated with the latest `tar.gz` source for the Tomcat JK connectors and use the `curl` command to download it to your server:

    cd /tmp
    curl -LO http://mirrors.ibiblio.org/apache/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.42-src.tar.gz

Next, extract the tarball into the current directory and move into the `native` subdirectory where the source code and build scripts are located within the extracted file hierarchy:

    tar xzvf tomcat-connectors*
    cd tomcat-connectors*/native

Now, we’re ready to configure the software. We need to set the location of the `apxs` Apache extention tool binary to successfully configure the source for our server. Afterwards, we can use `make` to build the software and install the compiled module:

    ./configure --with-apxs=/usr/bin/apxs
    make
    sudo make install

This will install the `mod_jk` module into the Apache modules directory.

### Step 2: Configure the mod\_jk Module

Now that the module is installed, we can configure the Apache web server to use it to communicate with our Tomcat instance. This can be done by setting up a few configuration files.

Begin by opening a file called `jk.conf` within the `/etc/httpd/conf.d` directory:

    sudo vi /etc/httpd/conf.d/jk.conf

Inside, we need to start off by loading the `mod_jk` module. Afterwards, we will configure a dedicated log and shared memory file. Finally, we will use the `JkWorkersFile` directive to point to the file we will be creating to specify our worker configuration.

Paste the following configuration into the file to link these pieces together. You should not have to modify anything:

/etc/httpd/conf.d/jk.conf

    LoadModule jk_module modules/mod_jk.so
    
    JkLogFile logs/mod_jk.log
    JkLogLevel info
    JkShmFile logs/mod_jk.shm
    
    JkWorkersFile conf/workers.properties

Save and close the file when you are finished.

Next, we will create the worker properties file. We will use this to define a worker to connect to our Tomcat backend:

    sudo vi /etc/httpd/conf/workers.properties

Inside this file, we will define a single worker, which will connect to our Tomcat instance on port 8009 using version 13 of the Apache JServ Protocol:

/etc/httpd/conf/workers.properties

    worker.list=worker1
    worker.worker1.type=ajp13
    worker.worker1.host=127.0.0.1
    worker.worker1.port=8009

When you are finished, save and close the file.

### Step 3: Adjust the Apache Virtual Host to Proxy with `mod_jk`

Finally, we need to adjust the Apache Virtual Host file that has SSL enabled. If you followed the prerequisites, this should be currently configured to protect your content using either a trusted or self-signed SSL certificate.

Open the file now by typing:

    sudo vi /etc/httpd/conf.d/ssl.conf

Inside, within the `VirtualHost` configuration block, add a `JkMount` directive to pass all traffic that this virtual host receives to the worker instance we just defined. The `JkMount` can be placed anywhere within the `VirtualHost` section:

/etc/httpd/conf.d/ssl.conf

    . . .
    
    <VirtualHost _default_:443>
    
    . . .
    JkMount /* worker1
    . . .
    
    </VirtualHost>

Save and close the file when you are finished.

Next, check your configuration by typing:

    sudo apachectl configtest

If the output contains `Syntax OK`, restart the Apache web server process:

    sudo systemctl restart httpd

You should now be able get to your Tomcat installation by visiting the SSL version of your site in your web browser:

    https://example.com

Next, skip past the Nginx configuration below and continue at the section detailing how to restrict access to Tomcat in order to complete your configuration.

## (Option 2) HTTP Proxying with Nginx

Proxying is also easy with Nginx, if you prefer it to the Apache web server. While Nginx does not have a module allowing it to use the Apache JServ Protocol, it can use its robust HTTP proxying capabilities to communicate with Tomcat.

### Section Prerequisites

Before we can discuss how to proxy Nginx connections to Tomcat, you must install and secure Nginx.

The way you do this will depend on whether you have a domain name or not.

- **If you have a domain name…** the easiest way to secure your server is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Nginx](how-to-secure-nginx-with-let-s-encrypt-on-centos-7) to set up Nginx and secure it with Let’s Encrypt.
- **If you do not have a domain…** and you are just using this configuration for testing or personal use, you can use a self-signed certificate instead. This provides the same type of encryption, but without domain validation. Follow our [self-signed SSL guide for Nginx](how-to-create-a-self-signed-ssl-certificate-for-nginx-on-centos-7) to install Nginx and configure it with a self-signed certificate.

When you are finished with these steps, continue below to learn how to hook up the Nginx web server to your Tomcat installation.

### Step 1: Adjusting the Nginx Server Block Configuration

Setting up Nginx to proxy to Tomcat is very straight forward.

Begin by opening the server block file associated with your site. Both the self-signed and Let’s Encrypt SSL guides configure the encrypted server block within the `/etc/httpd/conf.d/ssl.conf` file, so we will use that:

    sudo vi /etc/nginx/conf.d/ssl.conf

Inside, towards the top of the file, we need to add an `upstream` block. This will outline the connection details so that Nginx knows where our Tomcat server is listening. Place this outside of any of the `server` blocks defined within the file:

/etc/nginx/sites-available/default

    upstream tomcat {
        server 127.0.0.1:8080 fail_timeout=0;
    }
    
    server {
    
        . . .

Next, within the `server` block defined for port 443, modify the `location /` block. We want to pass all requests directly to the `upstream` block we just defined. Comment out any existing contents and use the `proxy_pass` directive to pass to the “tomcat” upstream we just defined.

We will also be setting some headers that allow Nginx to pass Tomcat information about the request:

/etc/nginx/sites-available/default

    upstream tomcat {
        server 127.0.0.1:8080 fail_timeout=0;
    }
    
    server {
        . . .
    
        location / {
            #try_files $uri $uri/ =404;
            proxy_pass http://tomcat/;
            proxy_set_header Host $http_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
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

    sudo vi /opt/tomcat/conf/server.xml

Within this file, we need to modify the **Connector** definitions. Currently there are two Connectors enabled within the configuration. One handles normal HTTP requests on port 8080, while the other handles Apache JServ Protocol requests on port 8009. The configuration will look something like this:

/opt/tomcat/conf/server.xml

    . . .
    
        <Connector port="8080" protocol="HTTP/1.1"
                   connectionTimeout="20000"
                   redirectPort="8443" />
    . . .
    
        <!-- Define an AJP 1.3 Connector on port 8009 -->
        <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />

In order to restrict access to the local loopback interface, we just need to add an “address” attribute set to `127.0.0.1` in each of these Connector definitions. The end result will look like this:

/opt/tomcat/conf/server.xml

    . . .
    
        <Connector port="8080" protocol="HTTP/1.1"
                   connectionTimeout="20000"
                   address="127.0.0.1"
                   redirectPort="8443" />
    . . .
    
        <!-- Define an AJP 1.3 Connector on port 8009 -->
        <Connector port="8009" address="127.0.0.1" protocol="AJP/1.3" redirectPort="8443" />

After you’ve made those two changes, save and close the file.

We need to restart our Tomcat process to implement these changes:

    sudo systemctl restart tomcat

Your Tomcat installation should now only be accessible through your web server proxy.

## Conclusion

At this point, connections to your Tomcat instance should be encrypted with SSL with the help of a web server proxy. While configuring a separate web server process might increase the software involved in serving your applications, it simplifies the process of securing your traffic significantly.
