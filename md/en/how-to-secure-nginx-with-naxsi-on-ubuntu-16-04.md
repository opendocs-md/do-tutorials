---
author: Kunal  Relan
date: 2018-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-naxsi-on-ubuntu-16-04
---

# How To Secure Nginx with NAXSI on Ubuntu 16.04

_The author selected [The OWASP Foundation](https://www.brightfunds.org/organizations/owasp-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Nginx is a popular, open-source HTTP server and reverse proxy known for its stability, simple configuration, and frugal resource requirements. You can greatly increase the security of your Nginx server by using a module like NAXSI. NAXSI ( **Nginx Anti XSS & SQL Injection** ) is a free, third-party Nginx module that provides web application firewall features. NAXSI analyzes, filters, and secures the traffic that comes to your web application, and acts like a DROP-by-default firewall, which means that it blocks all the traffic coming its way unless instructed to specifically allow access.

The simplicity with which a user can manipulate access is a key feature that differentiates NAXSI from other web application firewalls (WAF) with similar functionality like [ModSecurity](https://www.modsecurity.org/). Although ModSecurity comes with a rich feature set, it is more difficult to maintain than NAXSI. This makes NAXSI a simple and adaptable choice that provides readily available rules that work well with popular web applications such as WordPress.

In this tutorial, you will use NAXSI to secure Nginx on your Ubuntu 16.04 server. Since the NAXSI module doesn’t come with the Nginx package by default, you will need to compile Nginx from source with NAXSI. By the end of this tutorial, you will know what kinds of attacks NAXSI can block and how to configure NAXSI rules.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

## Step 1 — Installing Nginx and NAXSI

Most of the Nginx modules are not available through repositories, and NAXSI is no exception. Because of this, you will have to manually download and compile Nginx from source with NAXSI.

First, download Nginx using the following command.

**Note:** This tutorial uses version 1.14 of Nginx. To use a more recent version, you can visit [the download page](http://nginx.org/en/download.html) and replace the highlighted text in the preceding command with an updated version number. It is recommended to use the latest stable version.

    wget http://nginx.org/download/nginx-1.14.0.tar.gz

Next, download NAXSI from the stable 0.56 release on Github.

**Note:** This tutorial uses version 0.56 of NAXSI. You can find more recent releases at the [NAXSI Github page](https://github.com/nbs-system/naxsi). It is recommended to use the latest stable version.

    wget https://github.com/nbs-system/naxsi/archive/0.56.tar.gz -O naxsi

As you may have noticed, the Nginx repository is a `tar` archive. You first need to extract it to be able to compile and install it, which you can do by using the `tar` command.

    tar -xvf nginx-1.14.0.tar.gz

In the preceding command, `-x` specifies the extract utility, `-v` makes the utility run in verbose mode, and `-f` indicates the name of the archive file to extract.

Now that you have extracted the Nginx files, you can move on to extract the NAXSI files using the following command:

    tar -xvf naxsi

You now have the folders `naxsi-0.56` and `nginx-1.14.0` in your home directory. Using the files that you just downloaded and extracted, you can compile the Nginx server with NAXSI. Move into your `nginx-1.14.0` directory

    cd nginx-1.14.0

In order to compile Nginx from source, you will need the C compiler `gcc`, the Perl Compatible Regular Expressions library `libpcre3-dev`, and `libssl-dev`, which implements the SSL and TLD cryptographic protocols. These dependencies can be added with the `apt-get` command.

First, run the following command to make sure you have an updated list of packages.

    sudo apt-get update

Then install the dependencies:

    sudo apt-get install build-essential libpcre3-dev libssl-dev

Now that you have all your dependencies, you can compile Nginx from source. In order to prepare Nginx to be compiled from source on your system, execute the following script, which will create the `Makefile` that shows where to find all necessary dependencies.

    ./configure \
    --conf-path=/etc/nginx/nginx.conf \
    --add-module=../naxsi-0.56/naxsi_src/ \
    --error-log-path=/var/log/nginx/error.log \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-log-path=/var/log/nginx/access.log \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --user=www-data \
    --group=www-data \
    --with-http_ssl_module \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
    --without-mail_imap_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --prefix=/usr

Each of the lines of the preceding command defines a parameter for the Nginx web server. The most important of these are the `--add-module=../naxsi-0.56/naxsi_src/` parameter, which connects the NAXSI module with Nginx, and the `--user=www-data` and `--group=www-data` paramaters, which make Nginx run with the user and group privileges of a dedicated user/group called `www-data` that comes with your Ubuntu 16.04 server. The `--with-http_ssl_module` parameter enables the Nginx server to use SSL cryptography, and the `--without-mail_pop3_module`, `--without-mail_smtp_module`, and `--without-mail_imap_module` parameters turn off the unneeded mail protocols that would otherwise be automatically included. For further explanation of these parameters, see the [official Nginx docs](http://nginx.org/en/docs/configure.html).

After using the `./configure` command, run the `make` command to enact a series of tasks defined in the `Makefile` you just created to build the program from the source code.

    make

When Nginx is built and ready to run, use the `make install` command as a superuser to copy the built program and its libraries to the correct location on your server.

    sudo make install

Once this succeeds, you will have a compiled version of Nginx with the NAXSI module. In order to get NAXSI to start blocking unwanted traffic, you now need to establish a set of rules that NAXSI will act upon by creating a series of configure files.

## Step 2 — Configuring NAXSI

The most important part of a firewall’s functioning is its rules, which determine how requests are blocked from the server. The basic set of rules that comes by default with NAXSI are called **core rules**. These rules are meant to search for patterns in parts of a request and to filter out ones that may be attacks. NAXSI core rules are applied globally to the server for signature matching.

To configure Nginx to use these core rules, copy the `naxsi_core.rules` file to Nginx config directory.

    sudo cp ~/naxsi-0.56/naxsi_config/naxsi_core.rules /etc/nginx/

Now that the core rules are established, add the basic Naxsi rules, which enable and implement the core rules on a per location basis and assign actions for the server to take when a URL request does not satisfy the core rules. Create a file called `naxsi.rules` inside the `/etc/nginx/` directory. To do so, use the following command to open the file in the text editor called nano, or use your text editor of choice.

    sudo nano /etc/nginx/naxsi.rules

Add the following block of code that defines some basic firewall rules.

/etc/nginx/naxsi.rules

     SecRulesEnabled;
     DeniedUrl "/error.html";
    
     ## Check for all the rules
     CheckRule "$SQL >= 8" BLOCK;
     CheckRule "$RFI >= 8" BLOCK;
     CheckRule "$TRAVERSAL >= 4" BLOCK;
     CheckRule "$EVADE >= 4" BLOCK;
     CheckRule "$XSS >= 8" BLOCK;

The preceding code defines the `DeniedUrl`, which is the `URL` NAXSI will redirect to when a request is blocked. The file also enables a checklist of different kinds of attacks that NAXSI should block, including SQL injection, cross-site scripting (XSS), and remote file inclusion (RFI). Once you have added the preceding code to the file, save and exit the text editor.

Since you redirected blocked requests to `/error.html`, you can now create an `error.html` file inside `/usr/html` directory to provide this destination with a landing page. Open up the file in your text editor:

    sudo nano /usr/html/error.html

Next, add the following HTML code to the file to make a web page that lets the user know that their request was blocked:

/usr/html/error.html

    <html>
      <head>
        <title>Blocked By NAXSI</title>
      </head>
      <body>
        <div style="text-align: center">
          <h1>Malicious Request</h1>
          <hr>
          <p>This Request Has Been Blocked By NAXSI.</p>
        </div>
      </body>
    </html>

Save the file and exit the editor.

Next, open up the Nginx configuration file `/etc/nginx/nginx.conf` in your text editor.

    sudo nano /etc/nginx/nginx.conf

To add the NAXSI configuration files to Nginx’s configuration so that the web server knows how to use NAXSI, insert the highlighted lines of code into the `http` section of the `nginx.conf` file:

/etc/nginx/nginx.conf

    . . .
    http {
        include mime.types;
        include /etc/nginx/naxsi_core.rules;
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
    
    
        default_type application/octet-stream;
    . . .

Then in the `server` section of the same file, add the following highlighted line:

/etc/nginx/nginx.conf

    . . .
        server {
            listen 80;
            server_name localhost;
    
            #charset koi8-r;
    
            #access_log logs/host.access.log main;
    
            location / {
            include /etc/nginx/naxsi.rules;
                root html;
                index index.html index.htm;
            }
    . . .

Now that you have configured Nginx with the core and basic rules for NAXSI, the firewall will block matching malicious requests when you start the web server. Next, you can write a startup script to ensure that Nginx starts up when you reboot the server.

## Step 3 — Creating the Startup Script for Nginx

Since you installed Nginx manually, the next step is to create a startup script to make the web server autostart on system reloads.

This tutorial uses the Systemd software suite to make the script. To do this, you will create a Unit File (see [Understanding Systemd Units and Unit Files](understanding-systemd-units-and-unit-files) for further study) to configure how Systemd should start and manage the Nginx service.

Make a file called `nginx.service` and open it up in your text editor:

    sudo nano /lib/systemd/system/nginx.service

Add the following lines to the file:

/lib/systemd/system/nginx.service

    [Unit]
    Description=The NGINX HTTP and reverse proxy server
    After=syslog.target network.target remote-fs.target nss-lookup.target
    
    [Service]
    Type=forking
    PIDFile=/run/nginx.pid
    ExecStartPre=/usr/sbin/nginx -t
    ExecStart=/usr/sbin/nginx
    ExecReload=/usr/sbin/nginx -s reload
    ExecStop=/bin/kill -s QUIT $MAINPID
    PrivateTmp=true
    
    [Install]
    WantedBy=multi-user.target

The `[Unit]` section defines the program that you are configuring, `[Service]` describes how Nginx should behave on startup, and `[Install]` provides information about unit installation. Once you add these lines to the `nginx.service` file, `systemd` will know how to start Nginx.

Next, Nginx needs a folder to temporarily store incoming request data before processing it in the event that your server doesn’t have enough memory. Since you installed Nginx from source, you will need to create a directory that Nginx can use to store this data. Make a directory called `body` inside `/var/lib/nginx`:

    sudo mkdir -p /var/lib/nginx/body

With the startup script set up, you will now be able to start the Nginx server.

Use the following command to start the server.

    sudo systemctl start nginx

To check that your server is active, run the following command:

    sudo systemctl status nginx

You will see the following output in your terminal stating that the server has started successfully:

    Output● nginx.service - The NGINX HTTP and reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; disabled; vendor preset: enabled)
       Active: active (running) since Mon 2018-11-05 13:59:40 UTC; 1s ago
      Process: 16199 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
      Process: 16194 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
     Main PID: 16201 (nginx)
        Tasks: 2
       Memory: 1.3M
          CPU: 17ms
       CGroup: /system.slice/nginx.service
               ├─16201 nginx: master process /usr/sbin/ngin
               └─16202 nginx: worker proces
    . . .

You now have a running Nginx server secured by NAXSI. The next step is to run a simulated XSS and SQL injection attack to ensure that NAXSI is protecting your server effectively.

## Step 4 — Testing NAXSI

To test that Nginx is up and running with the NAXSI module enabled, you will try hitting the server with malicious HTTP requests and analyze the responses.

First, copy the Public IP of your server and use the `curl` command to make malicious request the Nginx server.

    curl 'http://your_server_ip/?q="><script>alert(0)</script>'

This URL includes the XSS script `"><script>alert(0)</script>` in the `q` parameter and should be rejected by the server. According to the NAXSI rules that you set up earlier, you will be redirected to the `error.html` file and receive the following response:

    Output<html>
      <head>
        <title>Blocked By NAXSI</title>
      </head>
      <body>
        <div style="text-align: center">
          <h1>Malicious Request</h1>
          <hr>
          <p>This Request Has Been Blocked By NAXSI.</p>
        </div>
      </body>
    </html>

The NAXSI firewall has blocked the request.

Now, verify the same using the Nginx log by tailing the Nginx server log using the following command:

    tail -f /var/log/nginx/error.log

In the log, you will see that the XSS request from the remote IP address is getting blocked by NAXSI:

    Output2018/11/07 17:05:05 [error] 21356#0: *1 NAXSI_FMT: ip=your_server_ip&server=your_server_ip&uri=/&learning=0&vers=0.56&total_processed=1&total_blocked=1&block=1&cscore0=$SQL&score0=8&cscore1=$XSS&score1=8&zone0=ARGS&id0=1001&var_name0=q, client: your_server_ip, server: localhost, request: "GET /?q="><script>alert(0)</script> HTTP/1.1", host: "your_server_ip"

Press `CTRL-C` to exit `tail` and stop the output of the error log file.

Next, try another URL request, this time with a malicious SQL Injection query.

    curl 'http://your_server_ip/?q=1" or "1"="1"'

The `or "1"="1"` part of the preceding URL can expose a user’s data in a database, and will be blocked by NAXSI. It should produce the same response in the terminal:

    Output<html>
      <head>
        <title>Blocked By NAXSI</title>
      </head>
      <body>
        <div style="text-align: center">
          <h1>Malicious Request</h1>
          <hr>
          <p>This Request Has Been Blocked By NAXSI.</p>
        </div>
      </body>
    </html>

Now use `tail` to follow the server log again:

    tail -f /var/log/nginx/error.log

In the log file you’ll see the blocked entry for the SQL Injection attempt:

    Output2018/11/07 17:08:01 [error] 21356#0: *2 NAXSI_FMT: ip=your_server_ip&server=your_server_ip&uri=/&learning=0&vers=0.56&total_processed=2&total_blocked=2&block=1&cscore0=$SQL&score0=40&cscore1=$XSS&score1=40&zone0=ARGS&id0=1001&var_name0=q, client: your_server_ip, server: localhost, request: "GET /?q=1" or "1"="1" HTTP/1.1", host: "your_server_ip"

Press `CTRL-C` to exit the log.

NAXSI has now successfully blocked an XSS and SQL injection attack, which proves that NAXSI has been configured correctly and that your Nginx web server is secure.

## Conclusion

You now have a basic understanding of how to use NAXSI to protect your web server from malicious attacks. To learn more about setting up Nginx, see [How To Set Up Nginx Server Blocks (Virtual Hosts) on Ubuntu 16.04](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04). If you’d like to continue studying security on web servers, check out [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04) and [How To Create a Self-Signed SSL Certificate for Nginx in Ubuntu 16.04](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04).
