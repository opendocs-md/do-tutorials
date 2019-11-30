---
author: Mitchell Anicas
date: 2015-06-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-centos-7
---

# How To Set Up a Node.js Application for Production on CentOS 7

## Introduction

Node.js is an open source Javascript runtime environment for easily building server-side and networking applications. The platform runs on Linux, OS X, FreeBSD, and Windows, and its applications are written in JavaScript. Node.js applications can be run at the command line but we will teach you how to run them as a service, so they will automatically restart on reboot or failure, so you can use them in a production environment.

In this tutorial, we will cover setting up a production-ready Node.js environment that is composed of two CentOS 7 servers; one server will run Node.js applications managed by PM2, while the other will provide users with access to the application through an Nginx reverse proxy to the application server.

The Ubuntu version of this tutorial can be found [here](how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04).

## Prerequisites

This guide uses two CentOS 7 servers **with private networking** (in the same datacenter). We will refer to them by the following names:

- **app** : The server where we will install Node.js runtime, your Node.js application, and PM2
- **web** : The server where we will install the Nginx web server, which will act as a reverse proxy to your application. Users will access this server’s public IP address to get to your Node.js application.

It is possible to use a single server for this tutorial, but you will have to make a few changes along the way. Simply use the localhost IP address, i.e. `127.0.0.1`, wherever the **app** server’s private IP address is used.

Here is a diagram of what your setup will be after following this tutorial:

![Reverse Proxy to Node.js Application](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nodejs/node_diagram.png)

Before you begin this guide, you should have a regular, non-root user with `sudo` privileges configured on both of your servers—this is the user that you should log in to your servers as. You can learn how to configure a regular user account by following our [initial server setup guide for CentOS 7](initial-server-setup-with-centos-7).

If you want to be able to access your **web** server via a domain name, instead of its public IP address, purchase a domain name then follow these tutorials:

- [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean)
- [How to Point to DigitalOcean Nameservers From Common Domain Registrars](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars)

Let’s get started by installing the Node.js runtime on the **app** server.

## Install Node.js

We will install the latest LTS release of Node.js, on the **app** server.

On the **app** server, let’s use `yum` to install the `git` package, which `npm` depends on:

    sudo yum install git

Go to the [Node.js Downloads page](https://nodejs.org/en/download/) and find the **Linux Binaries (.tar.gz)** download link. Right-click it, and copy its link address to your clipboard. At the time of this writing, the latest LTS release is **4.2.3**. If you prefer to install the latest stable release of Node.js, go to the [appropriate page](https://nodejs.org/en/download/stable/) and copy that link.

Change to your home directory and download the Node.js source with `wget`. Paste the download link in place of the highlighted part:

    cd ~
    wget https://nodejs.org/dist/v4.2.3/node-v4.2.3-linux-x64.tar.gz

Now extract the tar archive you just downloaded into the `node` directory with these command:

    mkdir node
    tar xvf node-v*.tar.gz --strip-components=1 -C ./node

If you want to delete the Node.js archive that you downloaded, since we no longer need it, change to your home directory and use this `rm` command:

    cd ~
    rm -rf node-v*

Next, we’ll configure the global `prefix` of `npm`, where `npm` will create symbolic links to installed Node packages, to somewhere that it’s in your default path. We’ll set it to `/usr/local` with this command:

    mkdir node/etc
    echo 'prefix=/usr/local' > node/etc/npmrc

Now we’re ready to move the `node` and `npm` binaries our installation location. We’ll move it into `/opt/node` with this command:

    sudo mv node /opt/

At this point, you may want to make `root` the owner of the files:

    sudo chown -R root: /opt/node

Lastly, let’s create symbolic links of the `node` and `npm` binaries in your default path. We’ll put the links in `/usr/local/bin` with these commands:

    sudo ln -s /opt/node/bin/node /usr/local/bin/node
    sudo ln -s /opt/node/bin/npm /usr/local/bin/npm

Note that, by default, `/usr/local/bin` is excluded from `PATH` when `sudo` is used. To change that, open the `sudoers` file:

    sudo visudo

Find the line that specifies `Defaults secure_path` and add `:/usr/local/bin` to the end of it. It should look like this when you’re done:

sudoers excerpt

    Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

Save and exit.

Verify that Node is installed by checking its version with this command:

    node -v

The Node.js runtime is now installed, and ready to run an application! Let’s write a Node.js application.

## Create Node.js Application

Now we will create a _Hello World_ application that simply returns “Hello World” to any HTTP requests. This is a sample application that will help you get your Node.js set up, which you can replace it with your own application–just make sure that you modify your application to listen on the appropriate IP addresses and ports.

Because we want our Node.js application to serve requests that come from our reverse proxy server, **web** , we will utilize our **app** server’s private network interface for inter-server communication. Look up your **app** server’s private network address.

If you are using a DigitalOcean droplet as your server, you may look up the server’s private IP address through the _Metadata_ service. On the **app** server, use the `curl` command to retrieve the IP address now:

    curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/private/0/ipv4/address 

You will want to copy the output (the private IP address), as it will be used to configure our Node.js application.

### Hello World Code

Next, create and open your Node.js application for editing. For this tutorial, we will use `vi` to edit a sample application called `hello.js`:

    vi hello.js

Insert the following code into the file, and be sure to substitute the **app** server’s private IP address for both of highlighted `APP_PRIVATE_IP_ADDRESS` items. If you want to, you may also replace the highlighted port, `8080`, in both locations (be sure to use a non-admin port, i.e. 1024 or greater):

hello.js

    var http = require('http');
    http.createServer(function (req, res) {
      res.writeHead(200, {'Content-Type': 'text/plain'});
      res.end('Hello World\n');
    }).listen(8080, 'APP_PRIVATE_IP_ADDRESS');
    console.log('Server running at http://APP_PRIVATE_IP_ADDRESS:8080/');

Now save and exit.

This Node.js application simply listens on the specified IP address and port, and returns “Hello World” with a `200` HTTP success code. This means that the application is only reachable from servers on the same private network, such as our **web** server.

## Test Application (Optional)

If you want to test if your application works, run this `node` command on the **app** server:

    node hello.js

**Note:** Running a Node.js application in this manner will block additional commands until the application is killed by pressing `CTRL+C`.

In order to test the application, open another terminal session and connect to your **web** server. Because the web server is on the same private network, it should be able to reach the private IP address of the **app** server using `curl`. Be sure to substitute in the **app** server’s private IP address for `APP_PRIVATE_IP_ADDRESS`, and the port if you changed it:

    curl http://APP_PRIVATE_IP_ADDRESS:8080

If you see the following output, the application is working properly and listening on the proper IP address and port:

    Node Application Output:Hello World

If you do not see the proper output, make sure that your Node.js application is running, and configured to listen on the proper IP address and port.

On the **app** server, be sure to kill the application (if you haven’t already) by pressing `CTRL+C`.

## Install PM2

Now we will install PM2, which is a process manager for Node.js applications. PM2 provides an easy way to manage and daemonize applications (run them as a service).

We will use Node Packaged Modules (NPM), which is basically a package manager for Node modules that installs with Node.js, to install PM2 on our **app** server. Use this command to install PM2:

    sudo npm install pm2@latest -g

## Manage Application with PM2

PM2 is simple and easy to use. We will cover a few basic uses of PM2.

### Start Application

The first thing you will want to do is use the `pm2 start` command to run your application, `hello.js`, in the background:

    pm2 start hello.js

This also adds your application to PM2’s process list, which is outputted every time you start an application:

    Output:┌──────────┬────┬──────┬───────┬────────┬─────────┬────────┬─────────────┬──────────┐
    │ App name │ id │ mode │ pid │ status │ restart │ uptime │ memory │ watching │
    ├──────────┼────┼──────┼───────┼────────┼─────────┼────────┼─────────────┼──────────┤
    │ hello │ 0 │ fork │ 30099 │ online │ 0 │ 0s │ 14.227 MB │ disabled │
    └──────────┴────┴──────┴───────┴────────┴─────────┴────────┴─────────────┴──────────┘

As you can see, PM2 automatically assigns an _App name_ (based on the filename, without the `.js` extension) and a PM2 _id_. PM2 also maintains other information, such as the _PID_ of the process, its current status, and memory usage.

Applications that are running under PM2 will be restarted automatically if the application crashes or is killed, but an additional step needs to be taken to get the application to launch on system startup (boot or reboot). Luckily, PM2 provides an easy way to do this, the `startup` subcommand.

The `startup` subcommand generates and configures a startup script to launch PM2 and its managed processes on server boots. You must also specify the init system you are running on, which is `systemd`, in our case:

    sudo pm2 startup systemd

You should see output like the following, which indicates that the pm2 service has been installed.

    Output:[PM2] Generating system init script in /etc/systemd/system/pm2.service
    [PM2] Making script booting at startup...
    [PM2] -systemd- Using the command:
          su root -c "pm2 dump && pm2 kill" && su root -c "systemctl daemon-reload && systemctl enable pm2 && systemctl start pm2"
    [PM2] Dumping processes
    [PM2] Stopping PM2...
    [PM2] All processes have been stopped and deleted
    [PM2] PM2 stopped
    [PM2] Done.

Now your pm2-managed applications should start automatically on boot.

### Other PM2 Usage (Optional)

PM2 provides many subcommands that allow you to manage or look up information about your applications. Note that running `pm2` without any arguments will display a help page, including example usage, that covers PM2 usage in more detail than this section of the tutorial.

Stop an application with this command (specify the PM2 `App name` or `id`):

    pm2 stop example

Restart an application with this command (specify the PM2 `App name` or `id`):

    pm2 restart example

The list of applications currently managed by PM2 can also be looked up with the `list` subcommand:

    pm2 list

More information about a specific application can be found by using the `info` subcommand (specify the PM2 _App name_ or _id_)::

    pm2 info example

The PM2 process monitor can be pulled up with the `monit` subcommand. This displays the application status, CPU, and memory usage:

    pm2 monit

Now that your Node.js application is running, and managed by PM2, let’s set up the reverse proxy.

## Set Up Reverse Proxy Server

Now that your application is running, and listening on a private IP address, you need to set up a way for your users to access it. We will set up an Nginx web server as a reverse proxy for this purpose. This tutorial will set up an Nginx server from scratch. If you already have an Nginx server setup, you can just copy the `location` block into the server block of your choice (make sure the location does not conflict with any of your web server’s existing content).

On the **web** server, let’s install the `epel-release` package using yum:

    sudo yum install epel-release

Then install Nginx:

    sudo yum install nginx

Now open the Nginx configuration file for editing:

    sudo vi /etc/nginx/nginx.conf

Find the line where `location /` is defined, within the default server block. It should look something like this:

nginx.conf excerpt — location / (before)

            location / {
            }

Replace it with the following code block and be sure to substitute your own domain name for the `server_name` directive (or IP address if you don’t have a domain set up), and the **app** server private IP address for the `APP_PRIVATE_IP_ADDRESS`. Additionally, change the port (`8080`) if your application is set to listen on a different port:

/etc/nginx/nginx.conf excerpt — location / (after)

        location / {
            proxy_pass http://APP_PRIVATE_IP_ADDRESS:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

This configures the **web** server to respond to requests at its root. Assuming our server is available at `example.com`, accessing `http://example.com/` via a web browser would send the request to the application server’s private IP address on port `8080`, which would be received and replied to by the Node.js application.

You can add additional `location` blocks to the same server block to provide access to other applications on the same **web** server. For example, if you were also running another Node.js application on the **app** server on port `8081`, you could add this location block to allow access to it via `http://example.com/app2`:

Nginx Configuration — Additional Locations

        location /app2 {
            proxy_pass http://APP_PRIVATE_IP_ADDRESS:8081;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

Once you are done adding the location blocks for your applications, save and exit.

On the **web** server, restart Nginx and enable it to start on boot:

    sudo systemctl restart nginx
    sudo systemctl enable nginx

Assuming that your Node.js application is running, and your application and Nginx configurations are correct, you should be able to access your application via the reverse proxy of the **web** server. Try it out by accessing your **web** server’s URL (its public IP address or domain name).

## Conclusion

Congratulations! You now have your Node.js application running behind an Nginx reverse proxy. This reverse proxy setup is flexible enough to provide your users access to other applications or static web content that you want to share. Good luck with your Node.js development!

Also, if you are looking to encrypt transmissions between your web server and your users, [here is a tutorial that will help you get HTTPS (TLS/SSL) support set up](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority).
