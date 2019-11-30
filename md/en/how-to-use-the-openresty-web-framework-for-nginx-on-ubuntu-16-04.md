---
author: Koen Vlaswinkel
date: 2017-02-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-the-openresty-web-framework-for-nginx-on-ubuntu-16-04
---

# How to Use the OpenResty Web Framework for Nginx on Ubuntu 16.04

## Introduction

[OpenResty](http://openresty.org/en/) is a web server which extends Nginx by bundling it with many useful Nginx modules and Lua libraries. OpenResty excels at scaling web applications and services. For example, one module it includes enables you to write Lua code which will execute directly in an Nginx worker, enabling high-performance applications.

In this guide, you will set up OpenResty from source; the pre-built packages for some distros can be out of date. You’ll also explore some simple example applications with OpenResty’s unique features.

## Prerequisites

To follow this guide, you will need:

- One Ubuntu 16.04 server set up by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial, including a sudo non-root user and a firewall.

Note that Nginx should **not** be installed. It’s included in OpenResty and having it installed ahead of time will conflict.

## Step 1 — Downloading OpenResty’s Source Code and Dependencies

In this section, we will install OpenResty from source.

First, find the latest OpenResty source code release from the [Download](http://openresty.org/en/download.html) page on the OpenResty website. Download the tarball, making sure to replace the version number by the latest version if it has changed.

    wget https://openresty.org/download/openresty-1.11.2.2.tar.gz

Download the PGP key file as well so we can verify the contents of the file.

    wget https://openresty.org/download/openresty-1.11.2.2.tar.gz.asc

Next, we need to add the public key of the author as listed on the download page. At time of writing, this is public key `A0E98066`. However, do check if it has changed; it is listed on the same downloads page.

    gpg --keyserver pgpkeys.mit.edu --recv-key A0E98066

You should see the following output (with your username in place of **sammy** ):

    Outputgpg: directory `/home/sammy/.gnupg' created
    gpg: new configuration file `/home/sammy/.gnupg/gpg.conf' created
    gpg: WARNING: options in `/home/sammy/.gnupg/gpg.conf' are not yet active during this run
    gpg: keyring `/home/sammy/.gnupg/secring.gpg' created
    gpg: keyring `/home/sammy/.gnupg/pubring.gpg' created
    gpg: requesting key A0E98066 from hkp server pgpkeys.mit.edu
    gpg: /home/sammy/.gnupg/trustdb.gpg: trustdb created
    gpg: key A0E98066: public key "Yichun Zhang (agentzh) <agentzh@gmail.com>" imported
    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

Check that the name on the public key (in this case, it’s “Yichun Zhang”) matches the name listed on the OpenResty website.

Now, check whether the signature file matches the downloaded `.tar.gz` file.

    gpg openresty-1.11.2.2.tar.gz.asc

You’ll see the following output:

    Outputgpg: assuming signed data in `openresty-1.11.2.2.tar.gz'
    gpg: Signature made Thu 17 Nov 2016 10:24:29 PM UTC using RSA key ID A0E98066
    gpg: Good signature from "Yichun Zhang (agentzh) <agentzh@gmail.com>"
    gpg: WARNING: This key is not certified with a trusted signature!
    gpg: There is no indication that the signature belongs to the owner.
    Primary key fingerprint: 2545 1EB0 8846 0026 195B D62C B550 E09E A0E9 8066

The warning you see is because you haven’t personally verified whether this key belongs to the owner (i.e., you have not signed the public key with your own private key). There isn’t an easy way to completely guarantee that this public key belongs to the owner, which it isn’t completely trusted.

However, in this case, **Good signature** indicates that this file is indeed the file that the authors of OpenResty intended to distribute, so we can go ahead with the installation.

Next, extract the downloaded file and move into the newly created directory.

    tar -xvf openresty-1.11.2.2.tar.gz
    cd openresty-1.11.2.2

We will need to install the necessary tools to compile OpenResty. For more information about compiling programs from source, see [this tutorial about using make to install packages from source](how-to-compile-and-install-packages-from-source-using-make-on-a-vps).

    sudo apt-get install build-essential

We will also need to install some other packages:

- [readline](https://cnswww.cns.cwru.edu/php/chet/readline/rltop.html): This will be used by OpenResty for the command line interface.
- [ncurses](https://www.gnu.org/software/ncurses/): This is another piece of software that will be used by OpenResty for its command line interface.
- [PCRE](http://pcre.org/): This software will provide OpenResty with regular expression capabilities.
- [OpenSSL](https://www.openssl.org/): OpenSSL is used for secure communication, such as TLS (HTTPS).
- [Perl](https://www.perl.org/): Perl is a programming language that can be used in OpenResty.

To install these packages, execute the following command:

    sudo apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl

We now have all the components necessary to build and install OpenResty.

## Step 2 — Installing OpenResty

We will configure OpenResty with PCRE regular expression and IPv6 support. We will also parallelize part of the building process by supplying the `-j2` flag, which will tell `make` that 2 jobs can be run simultaneously. This command will mostly test if all dependencies are available on your system and gather information that will be used by the build step later on. It will also already build some dependencies, such as LuaJIT.

    ./configure -j2 --with-pcre-jit --with-ipv6

Then you can build OpenResty, again by supplying the `-j2` flags for parallelism. This will compile OpenResty itself.

    make -j2

Finally, you can install OpenResty. Using `sudo` makes sure all files can be copied to the correct locations on the system so that OpenResty can find them when it is running.

    sudo make install

You will need to allow HTTP connections in your firewall for the web server to work.

    sudo ufw allow http

You can optionally also allow HTTPS with `sudo ufw allow https` if you are going to be using it. You can verify the change in the firewall by checking its status.

    sudo ufw status

You should see HTTP traffic (port `80`) allowed in the displayed output, as well as HTTPS (port `443`) if you added it.

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    80 ALLOW Anywhere
    443 ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    80 (v6) ALLOW Anywhere (v6)
    443 (v6) ALLOW Anywhere (v6)

You can now check whether the installation has worked. First, start OpenResty.

    sudo /usr/local/openresty/bin/openresty

It will complete immediately without text output if the command is successful. In that case, you can visit `http://your_server_ip` in your browser. You’ll see a page which says **Welcome to OpenResty!** with confirmation that it’s fully installed and working.

You can now stop the OpenResty server.

    sudo /usr/local/openresty/bin/openresty -s quit

OpenResty is installed, but you still need to configure OpenResty to run on startup so the server does not have to be started manually.

## Step 3 — Setting Up OpenResty as a Service

Here, we are going to set up OpenResty as a service so it starts automatically on boot. We will do this using the `systemd` init service. You can read [this systemd basics tutorial](systemd-essentials-working-with-services-units-and-the-journal) for more information, and [this unit file tutorial](understanding-systemd-units-and-unit-files) for information on unit files specifically.

Start by creating a new `systemd` file with `nano` or your favorite text editor.

    sudo nano /etc/systemd/system/openresty.service

For this tutorial, we’ll copy the default Nginx `systemd` file from a fresh installation and modify it for OpenResty. The complete file looks like this and should be pasted into the file we just opened. We’ll walk through each part of the file to explain what it’s doing.

/etc/systemd/system/openresty.service

    # Stop dance for OpenResty
    # A modification of the Nginx systemd script
    # =======================
    #
    # ExecStop sends SIGSTOP (graceful stop) to the Nginx process.
    # If, after 5s (--retry QUIT/5) OpenResty is still running, systemd takes control
    # and sends SIGTERM (fast shutdown) to the main process.
    # After another 5s (TimeoutStopSec=5), and if OpenResty is alive, systemd sends
    # SIGKILL to all the remaining processes in the process group (KillMode=mixed).
    #
    # Nginx signals reference doc:
    # http://nginx.org/en/docs/control.html
    #
    [Unit]
    Description=A dynamic web platform based on Nginx and LuaJIT.
    After=network.target
    
    [Service]
    Type=forking
    PIDFile=/run/openresty.pid
    ExecStartPre=/usr/local/openresty/bin/openresty -t -q -g 'daemon on; master_process on;'
    ExecStart=/usr/local/openresty/bin/openresty -g 'daemon on; master_process on;'
    ExecReload=/usr/local/openresty/bin/openresty -g 'daemon on; master_process on;' -s reload
    ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/openresty.pid
    TimeoutStopSec=5
    KillMode=mixed
    
    [Install]
    WantedBy=multi-user.target

In the `[Unit]` Section:

- `After=network.target` makes OpenResty start after the network is up so that OpenResty can bind and listen to ports. This allows it to be reached from the outside.

In the `[Service]` section:

- `Type=forking` tells `systemd` that the process we call in `ExecStart` will start the service in the background and that the process will stop itself after it has done so. 

- `PIDFile=/run/openresty.pid` tells `systemd` where to find the PID file OpenResty creates when it is started. This allows `systemd` to know whether OpenResty is still running.

- `ExecStartPre=/usr/local/openresty/bin/openresty -t -q -g 'daemon on; master_process on;'` calls the OpenResty script without starting it. The `-t` flag tells OpenResty we only want it to test the configuration file; the `-q` flag tells it that we want to suppress any non-error output; the `-g` flag sets the global directives `daemon on; master_process on` that tell OpenResty we want it to start in the background as a daemon. We execute this script as `ExecStartPre` so that `systemd` will not try starting OpenResty when the configuration file is invalid, as it will error out on this command.

- `ExecStart=/usr/local/openresty/bin/openresty -g 'daemon on; master_process on;'` actually starts OpenReesty. This is the same as `ExecStartPre` without the `-t` flag.

- `ExecReload=/usr/local/openresty/bin/openresty -g 'daemon on; master_process on;' -s reload` tells `systemd` to run this command when we run `systemctl reload openresty`. The `-s` flag tells OpenResty to reload its configuration file.

- `ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/openresty.pid` tells `systemd` to run this command when OpenResty is stopped. It sents `SIGSTOP` to the process listed in the PID file. If it’s still running 5 seconds later, `systemd` will take control via the following two options.

- `TimeoutStopSec=5` tells `systemd` we want the process stopped in 5 seconds. If it does not stop, `systemd` will forcibly try stopping OpenRest.

- `KillMode=mixed` specifies how `systemd` should try stopping OpenResty when it has not stopped after 5 seconds.

In the `[Install]` section:

- `WantedBy=multi-user.target` tells `systemd` when we want the service to be started if it is configured to be started at boot. `multi-user.target` means the service will only be started when a multi-user system has been started, i.e. we can run OpenResty as a different user.

That’s all for the `etc/systemd/system/openresty.service` file. Next, we need to customize the OpenResty Nginx configuration file and enable the service.

Open the configuration file first.

    sudo nano /usr/local/openresty/nginx/conf/nginx.conf

By default, it will look like this:

Default /usr/local/openresty/nginx/conf/nginx.conf

    #user nobody;
    worker_processes 1;
    
    #error_log logs/error.log;
    #error_log logs/error.log notice;
    #error_log logs/error.log info;
    
    #pid logs/nginx.pid;
    
    
    events {
        worker_connections 1024;
    }
    
    . . .

Delete everything before the `events {` line, and replace it with the following three lines:

Updated /usr/local/openresty/nginx/conf/nginx.conf

    user www-data;
    worker_processes auto;
    pid /run/openresty.pid;
    
    events {
        worker_connections 1024;
    }
    
    . . .

This file will make sure we are running as the **www-data** user and that `systemd` can recognize when OpenResty is running due to the `pid` line that will be created by OpenResty once it starts.

Save and close the file.

Next, create the log directory.

    sudo mkdir /var/log/openresty

Reload the `systemd` service so that it can find our file.

    sudo systemctl daemon-reload

Now, start OpenResty via `systemd`.

    sudo systemctl start openresty

You can now visit `http://your_server_ip` again and see the same web page as before. The difference is that now, the process has been started by `systemd`.

The last step is to enable the service which will make sure that OpenResty is started on boot.

    sudo systemctl enable openresty

You can learn more about managing `systemd` services and units in our [services and units tutorial](how-to-use-systemctl-to-manage-systemd-services-and-units).

Now that we have configured the service, we can further configure OpenResty so it will e.g. log to a common location.

## Step 4 — Configuring OpenResty

To configure OpenResty, we have used the default Nginx configuration as a reference, so that it will mostly match what you might be familiar with.

First, open the OpenResty configuration file again:

    sudo nano /usr/local/openresty/nginx/conf/nginx.conf

This time, we are going to modify the `http` block and move the `server` block inside this `http` block to a new file to have a better structure. First, locate the `http {` line, and delete everything after it, except for the final line with the corresponding `}`.

Current /usr/local/openresty/nginx/conf/nginx.conf

    user www-data;
    worker_processes auto;
    pid /run/openresty.pid;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include mime.types;
        default_type application/octet-stream;
    
        . . .
    }

Then, copy the following into the `http` block so that your entire file looks like this. We’ll go over the changes one at a time.

/usr/local/openresty/nginx/conf/nginx.conf

    user www-data;
    worker_processes auto;
    pid /run/openresty.pid;
    
    events {
        worker_connections 1024;
    }
    
    http {
        include mime.types;
        default_type application/octet-stream;
    
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
    
        keepalive_timeout 65;
    
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;
    
        access_log /var/log/openresty/access.log;
        error_log /var/log/openresty/error.log;
    
        gzip on;
        gzip_disable "msie6";
    
        include ../sites/*;
    }

Save and close the file.

The changes we made to the default file are:

- Uncommenting `tcp_nopush on;`, which tells OpenResty to send only full packets. This option is useful when using the `sendfile` option, which will allow OpenResty to optimize sending static files to a client.

- Adding `tcp_nodelay on;`. This option will try sending packets as soon as possible, which may seem contrary to the above option, but it is used at a different time. `tcp_nodelay` is only used when using the `keepalive` option on HTTP requests, which is a connection to a web server by a web browser that will avoid the overhead of initiating an HTTP connection every time a request is made.

- Adding and modifying the `ssl_protocols` and `ssl_prefer_server_ciphers` lines. These options configure the SSL options of OpenResty. We have removed old protocols that are vulnerable to known attacks on HTTPS, such as the POODLE attack.

- Adding the `access_log` and `error_log` lines, which configures where the logs of the web server. We store the logs at the `/var/log/openresty` directory, which we created in the previous step.

- Uncommenting `gzip on` and adding `gzip_disable "msie6"`. These options will configure GZIP, which will compress web pages so that there is less data to transfer. We also add the last option because Internet Explorer 6 (and older) does not always process GZIP content properly.

- Adding `include ../sites/*;`, which tells OpenResty to look for extra configuration files in the `/usr/local/openresty/nginx/sites` directory, which we will be created in a moment.

- Removing all `server` blocks, which we’ll relocate to a new file later in this step.

Next, create the new `sites` directory that we specified in the `include` line.

    sudo mkdir /usr/local/openresty/nginx/sites

Create the `default` site.

    sudo nano /usr/local/openresty/nginx/sites/default.conf

Add the following in this new file. This is the relocation of the original server block from `nginx.conf`, but has inline comments for more detail.

/usr/local/openresty/nginx/sites/default.conf

    server {
        # Listen on port 80.
        listen 80 default_server;
        listen [::]:80 default_server;
    
        # The document root.
        root /usr/local/openresty/nginx/html/default;
    
        # Add index.php if you are using PHP.
        index index.html index.htm;
    
        # The server name, which isn't relevant in this case, because we only have one.
        server_name _;
    
        # When we try to access this site...
        location / {
            # ... first attempt to serve request as file, then as a directory,
            # then fall back to displaying a 404.
            try_files $uri $uri/ =404;
        }
    
        # Redirect server error pages to the static page /50x.html.
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /usr/local/openresty/nginx/html;
        }
    }

Save and close the file.

Now, create a new directory for this site.

    sudo mkdir /usr/local/openresty/nginx/html/default

Then move the original `index.html` from its original location to the new directory.

    sudo mv /usr/local/openresty/nginx/html/index.html /usr/local/openresty/nginx/html/default

Finally, restart OpenResty to use this new site.

    sudo systemctl restart openresty

You can now again visit `http://your_server_ip` and see the same web page as before.

Now that OpenResty is fully configured, we can try some of the features introduced by OpenResty that are not available in Nginx by default.

## Step 5 — Using the OpenResty Lua Module

In this section, we will look at a combination of different modules added by OpenResty which all exist to accommodate Lua scripting. We will modifying `/usr/local/openresty/nginx/sites/default.conf` throughout this step, so open it first.

    sudo nano /usr/local/openresty/nginx/sites/default.conf

First, we are going to look at the `content_by_lua_block` configuration option. Copy the `location` block from the example configuration below and add it into the `server` block, below the two existing `location` blocks.

/usr/local/openresty/nginx/sites/default.conf content\_by\_lua\_block example

    server {
        . . .
    
        location /example {
             default_type 'text/plain';
    
             content_by_lua_block {
                 ngx.say('Hello, Sammy!')
             }
        }
    }

Save and close the file, then reload the configuration.

    sudo systemctl reload openresty

If you visit `http://your_server_ip/example` now, you’ll see a page which says **Hello, Sammy!**. Let’s explain how this works.

The `content_by_lua_block` configuration directive executes everything within it as Lua code. Here, we used the Lua function `ngx.say` to print the message **Hello, Sammy!** to the page.

For another example, replace the contents of the `location /example` block with this:

/usr/local/openresty/nginx/sites/default.conf content\_by\_lua\_file example

    server {
        . . .
    
        location /example {
             default_type 'text/plain';
    
             content_by_lua_file /usr/local/openresty/nginx/html/default/index.lua;
        }
    }

The `content_by_lua_file` loads the Lua content from an external file, so let’s create the one we specified above: `/usr/local/openresty/nginx/html/default/index.lua`.

    sudo nano /usr/local/openresty/nginx/html/default/index.lua

Add the following to the file, then save and close it.

/usr/local/openresty/nginx/html/default/index.lua

    local name = ngx.var.arg_name or "Anonymous"
    ngx.say("Hello, ", name, "!")

This is a simple piece of Lua which reads a query parameter in the URL, `name`, and customizes the greeting message. If no parameter is passed, it uses “Anonymous” instead.

Reload the configuration again.

    sudo systemctl reload openresty

Now, visit `http://your_server_ip/example?name=Sammy` in your browser. This will display **Hello, Sammy!**. You can change the `name` query parameter, or omit it entirely.

    Hello, Sammy!

You can also change the `name` query parameter to show any other name.

**Warning:** Do not place the Lua file you are loading in an accessible location from the web. If you do, your application code might be comprised if someone accesses this file. Place the file outside of your document root, for example by changing the document root to `/usr/local/openresty/nginx/html/default/public` and placing the Lua files one directory above it.

## Conclusion

In this article you set up OpenResty, which will enable you to use Lua scripts in an Nginx worker. It is possible to create much more complex Lua scripts. You can also, for example, restrict access using Lua scripts or rewrite certain requests using Lua. You can find the documentation on the [lua-nginx-module’s GitHub page](https://github.com/openresty/lua-nginx-module). There are even complete web frameworks which use Lua on OpenResty, such as [Lapis](http://leafo.net/lapis/).

If you want to learn more, you can visit the [OpenResty website](http://openresty.org/en/). Because OpenResty is just an extended Nginx installation, you can also learn how to set up server blocks in the [Nginx server blocks tutorial](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04), but make sure to replace the paths used in that tutorial by the paths used in this one.
