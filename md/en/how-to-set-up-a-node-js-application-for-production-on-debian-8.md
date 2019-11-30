---
author: Lisa Tagliaferri
date: 2016-12-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-debian-8
---

# How To Set Up a Node.js Application for Production on Debian 8

## Introduction

Node.js is an open-source JavaScript runtime environment for easily building server-side and networking applications. The platform runs on Linux, OS X, FreeBSD, and Windows. Node.js applications can be run at the command line, but we’ll focus on running them as a service, so that they will automatically restart on reboot or failure, and can safely be used in a production environment.

In this tutorial, we will cover setting up a production-ready Node.js environment on a single Debian 8 server. This server will run a Node.js application managed by PM2, and provide users with secure access to the application through an Nginx reverse proxy.

## Prerequisites

This guide assumes that you have a Debian 8 server, configured with a non-root user with `sudo` privileges, as described in the [initial server setup guide for Debian 8](initial-server-setup-with-debian-8).

It also assumes that you have a domain name, pointing at the server’s public IP address.

Let’s get started by installing the Node.js runtime on your server.

## Install Node.js

We will install the latest LTS release of Node.js, using the [NodeSource](https://github.com/nodesource/distributions) package archives.

First, you need to install the NodeSource PPA in order to get access to its contents. Make sure you’re in your home directory, and use curl to retrieve the installation script for the Node.js 6.x archives:

    cd ~
    curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh

You can inspect the contents of this script with nano (or your preferred text editor):

    nano nodesource_setup.sh

And run the script under `sudo`:

    sudo bash nodesource_setup.sh

The PPA will be added to your configuration and your local package cache will be updated automatically. After running the setup script from nodesource, you can install the Node.js package in the same way that you did above:

    sudo apt-get install nodejs

The `nodejs` package contains the `nodejs` binary as well as `npm`, so you don’t need to install `npm` separately. However, in order for some `npm` packages to work (such as those that require compiling code from source), you will need to install the `build-essential` package:

    sudo apt-get install build-essential

The Node.js runtime is now installed, and ready to run an application! Let’s write a Node.js application.

## Create Node.js Application

We will write a _Hello World_ application that simply returns “Hello World” to any HTTP requests. This is a sample application that will help you get your Node.js set up, which you can replace with your own application–just make sure that you modify your application to listen on the appropriate IP addresses and ports.

### Hello World Code

First, create and open your Node.js application for editing. For this tutorial, we will use `nano` to edit a sample application called `hello.js`:

    cd ~
    nano hello.js

Insert the following code into the file. If you want to, you may replace the highlighted port, `8080`, in both locations (be sure to use a non-admin port, i.e. 1024 or greater):

hello.js

    #!/usr/bin/env nodejs
    var http = require('http');
    http.createServer(function (req, res) {
      res.writeHead(200, {'Content-Type': 'text/plain'});
      res.end('Hello World\n');
    }).listen(8080, 'localhost');
    console.log('Server running at http://localhost:8080/');

Now save and exit.

This Node.js application simply listens on the specified address (`localhost`) and port (`8080`), and returns “Hello World” with a `200` HTTP success code. Since we’re listening on **localhost** , remote clients won’t be able to connect to our application.

### Test Application

To enable us to test the application, mark `hello.js` executable:

    chmod +x ./hello.js

And run it like so:

    ./hello.js

    OutputServer running at http://localhost:8080/

**Note:** Running a Node.js application in this manner will block additional commands until the application is killed by pressing **Ctrl-C**.

In order to test the application, open another terminal session on your server, and connect to **localhost** with `curl`:

    curl http://localhost:8080

If you see the following output, the application is working properly and listening on the proper address and port:

    OutputHello World

If you do not see the proper output, make sure that your Node.js application is running, and configured to listen on the proper address and port.

Once you’re sure it’s working, kill the application (if you haven’t already) by pressing **Ctrl+C**.

## Install PM2

Now we’ll install PM2, which is a process manager for Node.js applications. PM2 provides an easy way to manage and daemonize applications (run them in the background as a service).

We will use `npm`, a package manager for Node modules that installs with Node.js, to install PM2 on our server. Use this command to install PM2:

    sudo npm install -g pm2

The `-g` option tells `npm` to install the module _globally_, so that it’s available system-wide.

## Manage Application with PM2

PM2 is simple and easy to use. We will cover a few basic uses of PM2.

### Start Application

The first thing you will want to do is use the `pm2 start` command to run your application, `hello.js`, in the background:

    pm2 start hello.js

This also adds your application to PM2’s process list, which is outputted every time you start an application:

    Output[PM2] Spawning PM2 daemon
    [PM2] PM2 Successfully daemonized
    [PM2] Starting hello.js in fork_mode (1 instance)
    [PM2] Done.
    ┌──────────┬────┬──────┬──────┬────────┬─────────┬────────┬─────────────┬──────────┐
    │ App name │ id │ mode │ pid │ status │ restart │ uptime │ memory │ watching │
    ├──────────┼────┼──────┼──────┼────────┼─────────┼────────┼─────────────┼──────────┤
    │ hello │ 0 │ fork │ 3524 │ online │ 0 │ 0s │ 21.566 MB │ disabled │
    └──────────┴────┴──────┴──────┴────────┴─────────┴────────┴─────────────┴──────────┘
     Use `pm2 show <id|name>` to get more details about an app

As you can see, PM2 automatically assigns an **App name** (based on the filename, without the `.js` extension) and a PM2 **id**. PM2 also maintains other information, such as the **PID** of the process, its current status, and memory usage.

Applications that are running under PM2 will be restarted automatically if the application crashes or is killed, but an additional step needs to be taken to get the application to launch on system startup (boot or reboot). Luckily, PM2 provides an easy way to do this, the `startup` subcommand.

The `startup` subcommand generates and configures a startup script to launch PM2 and its managed processes on server boots. You must also specify the platform you are running on, which is `ubuntu`, in our case:

    pm2 startup systemd

The last line of the resulting output will include a command that you must run with superuser privileges:

    Output[PM2] You have to run this command as root. Execute the following command:
    sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u sammy --hp /home/sammy

Run the command that was generated (similar to the highlighted output above, but with your username instead of `sammy`) to set PM2 up to start on boot (use the command from your own output):

    sudo env PATH=$PATH:/usr/bin /usr/local/lib/node_modules/pm2/bin/pm2 startup systemd -u sammy --hp /home/sammy

This will create a systemd **unit** which runs `pm2` for your user on boot. This `pm2` instance, in turn, runs `hello.js`. You can check the status of the systemd unit with `systemctl`:

    systemctl status pm2

For a detailed overview of systemd, see [Systemd Essentials: Working with Services, Units, and the Journal](systemd-essentials-working-with-services-units-and-the-journal).

### Other PM2 Usage (Optional)

PM2 provides many subcommands that allow you to manage or look up information about your applications. Note that running `pm2` without any arguments will display a help page, including example usage, that covers PM2 usage in more detail than this section of the tutorial.

Stop an application with this command (specify the PM2 `App name` or `id`):

    pm2 stop app_name_or_id

Restart an application with this command (specify the PM2 `App name` or `id`):

    pm2 restart app_name_or_id

The list of applications currently managed by PM2 can also be looked up with the `list` subcommand:

    pm2 list

More information about a specific application can be found by using the `info` subcommand (specify the PM2 _App name_ or _id_):

    pm2 info example

The PM2 process monitor can be pulled up with the `monit` subcommand. This displays the application status, CPU, and memory usage:

    pm2 monit

Now that your Node.js application is running, and managed by PM2, let’s set up the reverse proxy.

## Set Up Nginx as a Reverse Proxy Server

Now that your application is running, and listening on **localhost** , you need to set up a way for your users to access it. We will set up an Nginx web server as a reverse proxy for this purpose. This tutorial will set up an Nginx server from scratch. If you already have an Nginx server setup, you can just copy the `location` block into the server block of your choice (make sure the location does not conflict with any of your web server’s existing content).

First, install Nginx using apt-get:

    sudo apt-get install nginx

Now open the default server block configuration file for editing:

    sudo nano /etc/nginx/sites-available/default

Delete everything in the file and insert the following configuration. Be sure to substitute your own domain name for the `server_name` directive. Additionally, change the port (`8080`) if your application is set to listen on a different port:

/etc/nginx/sites-available/default

    server {
        listen 80;
    
        server_name example.com;
    
        location / {
            proxy_pass http://localhost:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }

This configures the server to respond to requests at its root. Assuming our server is available at `example.com`, accessing `http://example.com/` via a web browser would send the request to `hello.js`, listening on port `8080` at **localhost**.

You can add additional `location` blocks to the same server block to provide access to other applications on the same server. For example, if you were also running another Node.js application on port `8081`, you could add this location block to allow access to it via `http://example.com/app2`:

Nginx Configuration — Additional Locations

        location /app2 {
            proxy_pass http://localhost:8081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

Once you are done adding the location blocks for your applications, save and exit.

Make sure you didn’t introduce any syntax errors by typing:

    sudo nginx -t

Next, restart Nginx:

    sudo systemctl restart nginx

Next, permit traffic to Nginx through a firewall, if you have it enabled.

If you’re using **ufw** , you can use the following command:

    sudo ufw allow 'Nginx Full'

With **ufw** , you can always check the status with the following command:

    sudo ufw status

If you’re using **IPTables** instead, you can permit traffic to Nginx by using the following command:

    sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT

You can always check the status of your IPTables by running the following command:

    sudo iptables -S

Assuming that your Node.js application is running, and your application and Nginx configurations are correct, you should now be able to access your application via the Nginx reverse proxy. Try it out by accessing your server’s URL (its public IP address or domain name).

From here, you should continue to secure your set up by reading [How To Secure Nginx with Let’s Encrypt on Debian 8](how-to-secure-nginx-with-let-s-encrypt-on-debian-8).

## Conclusion

Congratulations! You now have your Node.js application running behind an Nginx reverse proxy on a Debian 8 server. This reverse proxy setup is flexible enough to provide your users access to other applications or static web content that you want to share. Good luck with your Node.js development!
