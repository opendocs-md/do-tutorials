---
author: Yüce Tekol
date: 2016-10-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-nats-on-ubuntu-16-04
---

# How To Install and Configure NATS on Ubuntu 16.04

## Introduction

[NATS](http://nats.io/) is an open source high performance messaging system, often described as “a central nervous system for the cloud”. It is capable of routing millions of messages per second, which makes it ideal for connecting microservices and _IoT_ (Internet of Things) devices.

NATS is a _PubSub messaging system_. In this kind of system, one or more _publishers_ send messages with a certain subject to a _message broker_ and the message broker delivers these messages to any clients, or _subscribers_ of the given subject. Publishers don’t know or even care about subscribers and vice versa. This architecture makes it easy to scale the system and add new capabilities since we can add publishers and subscribers without affecting the rest of the system. This type of system is perfect for monitoring servers and devices; devices can send messages and we can subscribe to those messages to send notifications through email or other means.

In this tutorial, we will install `gnatsd`, the official NATS server, as a service and make it accessible in a secure way. We will also create a basic server overload warning system that sends out emails when server load gets too high, using `gnatsd` as its message broker.

## Prerequisites

To complete this tutorial, you will need:

- A new Ubuntu 16.04 server. 
- A standard user account with `sudo` privileges. You can set up a standard account by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

## Step 1 — Downloading the NATS Server

Let’s start by downloading the `gnatsd` server and making sure it runs on our system without any issues.

The latest stable `gnatsd` release is version 0.9.4 at the time this tutorial was written. You can check [the NATS download page](http://nats.io/download) for a later version and adapt the commands below as necessary if you’d like to use a newer version.

First, log into your server with your non-root account:

    ssh sammy@your_server_ip

Then, make sure you are in your user’s home directory:

    cd

Next, use `wget` to download `gnatsd` to your server:

    wget https://github.com/nats-io/gnatsd/releases/download/v0.9.4/gnatsd-v0.9.4-linux-amd64.zip

The archive you just downloaded is a compressed archive, so you’ll need to install `unzip` to extract the files. You can install it with `apt`:

    sudo apt-get install -y unzip

Then use `unzip` to extract `gnatsd`:

    unzip -p gnatsd-v0.9.4-linux-amd64.zip gnatsd-v0.9.4-linux-amd64/gnatsd > gnatsd

Then make `gnatsd` executable so you can run it:

    chmod +x gnatsd

Let’s test that we can run `gnatsd` by running it from the current directory. Use the following command to start `gnatsd`:

    ./gnatsd --addr 127.0.0.1 --port 4222

The output you see will be similar to this example:

    Output[1851] 2016/09/23 05:20:02.247420 [INF] Starting nats-server version 0.9.4
    [1851] 2016/09/23 05:20:02.248182 [INF] Listening for client connections on 127.0.0.1:4222
    [1851] 2016/09/23 05:20:02.248626 [INF] Server is ready

By default, `gnatsd` listens on port `4222` on address `0.0.0.0` which corresponds to all interfaces. Using the `--port` argument, you can change the port, and with `--addr` you can change the address it listens on. We ran `gnatsd` with `--addr 127.0.0.1`, so that it is available only within our server and cannot be accessed by external clients. Later in the tutorial, we will secure `gnatsd` and open it up to the world.

Press `CTRL+C` to shut down `gnatsd`.

Now that you know things work, let’s set things up in a more formal way.

## Step 2 — Creating the Directory Structure and Configuration File

On Linux, third party, service-related software is frequently kept under the `/srv` directory. We are going to follow that convention and keep NATS-related files under `/srv/nats`. We’ll place the `gnatsd` executable file in `/srv/nats/bin`.

First, create the `/srv/nats/bin` folder:

    sudo mkdir -p /srv/nats/bin

Then move `gnatsd` to the `/srv/nats/bin` folder:

    sudo mv ~/gnatsd /srv/nats/bin

The server can load its configuration from a file, which will come in handy when we need to modify server settings later in the tutorial. Create the file `/srv/nats/gnatsd.config`:

    sudo nano /srv/nats/gnatsd.config

And add the following contents to the file:

/srv/nats/gnatsd.config

    port: 4222
    net: '127.0.0.1'

This configuration file tells the `gnatsd` server to listen on port `4222` on address `127.0.0.1`, just like before, but this time we won’t have to specify those options on the command line.

Let’s run the server again to make sure that we have configured things correctly. Execute the following command to launch `gnatsd` using the new configuration file:

    /srv/nats/bin/gnatsd -c /srv/nats/gnatsd.config

The output is similar to what you have seen before:

    Output[1869] 2016/06/18 05:30:55.988856 [INF] Starting nats-server version 0.9.4
    [1869] 2016/06/18 05:30:55.989190 [INF] Listening for client connections on 127.0.0.1:4222
    [1869] 2016/06/18 05:30:55.989562 [INF] Server is ready

Once again, press `CTRL+C` to shut down `gnatsd` and return to your prompt. Now let’s create a user that will run this service.

## Step 3 — Creating the Service User

It is a good security practice to run each service with its own user account to limit the damage in case a service is compromised. Let’s create a user and group that will own the NATS service and NATS-related files.

First, let’s create a system user and group called `nats`:

    sudo adduser --system --group --no-create-home --shell /bin/false nats

    OutputAdding system user `nats' (UID 106) ...
    Adding new group `nats' (GID 114) ...
    Adding new user `nats' (UID 106) with group `nats' ...
    Not creating home directory `/home/nats'.

We assigned `/bin/false` shell to the `nats` system user to disable logins for this user and suppressed home directory creation. We also created a `nats` group.

Let’s change the owner of the `/srv` directory to the `nats` user and group:

    sudo chown -R nats:nats /srv

Now that we have created the `nats` user and group, let’s continue with creating the NATS service.

## Step 4 — Running gnatsd as a Service

We would like `gnatsd` to start when the system boots and restart if it crashes. We’ll use _systemd_ to handle this.

[systemd](https://www.freedesktop.org/wiki/Software/systemd/) is a service manager for Linux systems. It is responsible for starting services on boot, restarting them as necessary and stopping them in a controlled fashion on system shutdown.

We need to create a _service configuration_ in order to define how and when the NATS service should be started. User-created service files live in `/etc/systemd/system`, so create the file `/etc/systemd/system/nats.service`:

    sudo nano /etc/systemd/system/nats.service

And in the file, place this script to define how `gnatsd` should start up:

 /etc/systemd/system/nats.service

    [Unit]
    Description=NATS messaging server
    
    [Service]
    ExecStart=/srv/nats/bin/gnatsd -c /srv/nats/gnatsd.config
    User=nats
    Restart=on-failure
    
    [Install]
    WantedBy=multi-user.target

- The `[Unit]` section contains generic information about the service, such as `Description` which describes the service.
- The `[Service]` section contains service-related configuration. `ExecStart` is the command to run the server. We use the absolute path of the `gnatsd` executable here. `Restart=on-failure` means that the service must be restarted if it crashes or terminates with a failure. It will not be restarted if it was stopped by systemd.
- The `[Install]` section contains installation information about the service. `WantedBy=multi-user.target` tells systemd to start the service when starting `multi-user.target`. This is a generic way of starting services on system boot.

Once the service description is in place, we can start it with the following command:

    sudo systemctl start nats

Let’s confirm that `gnatsd` is running by sending a `PING` message:

    printf "PING\r\n" | nc 127.0.0.1 4222

We have just used `nc` to communicate with `gnatsd`. `nc` is a command line utility to communicate with TCP or UDP servers. The command we used prints an output similar to the following:

    OutputINFO {"server_id":"Os7xI5uGlYFJfLlfo1vHox","version":"0.9.4","go":"go1.6.3","host":"127.0.0.1","port":4222,"auth_required":false,"ssl_required":false,"tls_required":false,"tls_verify":false,"max_payload":1048576}
    PONG

The response `PONG` lets us know the server is listening and working as expected. We need to run one last command to make our NATS server start on boot:

    sudo systemctl enable nats

You will see the following output which confirms that the service was installed:

    OutputCreated symlink from /etc/systemd/system/multi-user.target.wants/nats.service to /etc/systemd/system/nats.service.

We successfully configured `gnatsd` to run as a service. Now let’s secure it and make it accessible to external clients.

## Step 5 — Securing Connections to the NATS Service

If all publishers and subscribers we would like to use with `gnatsd` ran on the same server, we could call it done and move on but that’s rarely the case these days. We’ll need to let external clients connect and publish messages to `gnatsd` in a secure way.

`gnatsd` supports TLS transport, so we will use that to secure the communication between `gnatsd` and NATS clients.

First, we need a certificate. You can buy a commercial certificate, retrieve one from [Let’s Encrypt](http://letsencrypt.org) or generate a self-signed certificate. We will use the latter approach, since acquiring a certificate is out of the scope of this article.

Create a directory to hold the certificate temporarily:

    mkdir ~/priv

Then create a self-signed certificate with the following command:

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout priv/gnatsd.key -out priv/gnatsd.crt \
        -subj "/C=US/ST=Texas/L=Austin/O=AwesomeThings/CN=www.example.com"

This command creates an RSA certificate with 2048 bits and 10 years of validity. Note that we have used an arbitrary domain name since we won’t enable TLS verification for the `gnatsd` server in this article.

You should now have the files `gnatsd.key` and `gnatsd.crt` in the `~/priv` directory. Let’s move those files under our `/srv/nats/` directory structure so everything is in one place. Execute the following command:

    sudo mv ~/priv /srv/nats

Now, make `/srv/nats/priv` accessible to only to the `nats` user and group:

    sudo chmod 440 /srv/nats/priv/*
    sudo chmod 550 /srv/nats/priv
    sudo chown -R nats:nats /srv/nats/priv

Now we update `/srv/nats/gnatsd.config` to contain the certificate and key we just created. Open the configuration file again:

    sudo nano /srv/nats/gnatsd.config

And add the following section to tell `gnatsd` to use your certificate and key:

/srv/nats/gnatsd.config

    . . .
    
    tls {
      cert_file: "/srv/nats/priv/gnatsd.crt"
      key_file: "/srv/nats/priv/gnatsd.key"
      timeout: 1
    }

Save the file and exit the editor. Then restart the service so it can pick up the changes.

    sudo systemctl restart nats

Let’s test that our certificates work. Run this command:

    printf "PING\r\n" | nc localhost 4222

This time, the command outputs this message:

    OutputINFO {"server_id":"npkIPrCE5Kp8O3v1EfV8dz","version":"0.9.4","go":"go1.6.3","host":"127.0.0.1","port":4222,"auth_required":false,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    
    -ERR 'Secure Connection - TLS Required'

The server returned the message `-ERR 'Secure Connection - TLS Required'` which confirms that the new configuration was picked up and a secure connection is required, which `nc` doesn’t know how to do.

In order to be able to communicate with our NATS service without installing a full blown NATS client, we will be using a tool called _catnats_. Let’s download it first:

    wget https://github.com/yuce/catnats/raw/0.1.2/catnats.py

And make it executable:

    chmod +x catnats.py

Finally, move `catnats.py` to the `/srv/nats/bin` folder and rename it to `catnats`:

    sudo mv catnats.py /srv/nats/bin/catnats

Let’s check that we can communicate with our NATS service using `catnats`, by sending the same `PING` message we have sent before:

    printf "PING\r\n" | /srv/nats/bin/catnats --addr 127.0.0.1:4222

You’ll see this output indicating our connection is secure:

    OutputINFO {"server_id":"npkIPrCE5Kp8O3v1EfV8dz","version":"0.9.4","go":"go1.6.3","host":"127.0.0.1","port":4222,"auth_required":false,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    PONG

Now that we have secured the communication, let’s enable authentication so that a username and password is required to connect to NATS.

## Step 6 — Requiring Authentication

Our NATS service does not require authentication by default. This is fine when the service is only accessible on a private network, but we want our NATS service accessible on the internet so we should enable authentication. `gnatsd` supports username and password authentication, and it is easy to enable.

Open the `/srv/nats/gnatsd.config` file:

    sudo nano /srv/nats/gnatsd.config

Add a new `authorization` section that specifies the credentials. We will use `user1` as the username and `pass1` as the password for this tutorial. You should use a longer, more complex password in a production environment:

/srv/nats/gnatsd.config

    . . .
    
    authorization {
      user: user1
      password: pass1
    }

Save the file, and then change the owner of `/srv/nats/gnatsd.config` to `nats` and make it readable by that user in order to protect the username and password from other users on the system:

    sudo chown nats /srv/nats/gnatsd.config
    sudo chmod 400 /srv/nats/gnatsd.config

Then restart the service for the changes to take effect:

    sudo systemctl restart nats

Let’s send a `PING` message to `gnatsd` to check whether everything is OK. Once again, use `catnats` to send the message:

    printf "PING\r\n" | /srv/nats/bin/catnats --addr 127.0.0.1:4222

You’ll see the following output:

    OutputNFO {"server_id":"sY0SSJBNbEw53HxzS9mH1t","version":"0.9.4","go":"go1.6.3","host":"127.0.0.1","port":4222,"auth_required":true,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    -ERR 'Authorization Violation'

This tells us that the changes were successfully applied and we now need to send the correct username and password in order to connect to the service. Let’s try again, this time providing the username `user1` and password `pass1`:

    printf "PING\r\n" | /srv/nats/bin/catnats --addr 127.0.0.1:4222 --user user1 --pass pass1

This time it worked, as you can see from the following output:

    OutputINFO {"server_id":"sY0SSJBNbEw53HxzS9mH1t","version":"0.9.4","go":"go1.6.3","host":"127.0.0.1","port":4222,"auth_required":true,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    +OK
    PONG

Now that we’ve restricted this service to clients that know the username and password, we can reconfigure the service so outside clients can connect.

## Step 7 — Opening the Service to the World

We’ve configured our NATS server to listen on `127.0.0.1`, which is the local interface. If we make it listen on `0.0.0.0`, then it will be available to the world. Let’s update `/srv/nats/gnatsd.config` one last time:

    sudo nano /srv/nats/gnatsd.config

Then change the IP address associated with the `net` setting:

/srv/nats/gnatsd.config

    . . .
    net: '0.0.0.0'
    . . .

Save the file and restart the service:

    sudo systemctl restart nats

And now our NATS service is ready for external client connections. To learn how to use it, let’s create a simple monitoring service that uses our NATS server as a message broker.

## Step 8 — (Optional) Configuring Notifications on Server Overload

In this section, you will create a simple overload monitoring system that makes use of your NATS service. The system will receive load averages of servers and send an email to an administrator if any of the servers are overloaded.

The sample project will consist of the following components:

- The NATS service you’ve just configured.
- A _monitor_, which publishes the hostname, load average and processor count of the server to the `stats.loadaverage` subject every 60 seconds. You need to run this component on any server you would like to monitor for load.
- A _notifier_, which subscribes to the `stats.loadaverage` subject and receives the host name, load average and processor count of a server. If the load average of a host is above a certain threshold, the notifier sends an email to a predefined address through an SMTP server.

We will run all of these components on the same server for simplicity, but you can try running each component in a different server when you’ve completed this tutorial.

### Setting Up the Monitor

You can read the average load on a Linux system from `/proc/loadavg`. For this project, we are interested only in the load average of the last minute, which is the first field of the output. Use this command to get that value:

    cat /proc/loadavg | cut -f1 -d" "

You’ll see the following output:

    Output0.11

The load average you get by reading `/proc/loadavg` depends on the number of processors, so you have to normalize it by dividing the load average by the number of processors. You can use the following command to get the processor count of your server:

    getconf _NPROCESSORS_ONLN

You’ll see the result displayed in your terminal:

    Output1

Since the default shell of our server cannot deal with floating number arithmetic, we will send both the load average and number of processors together with the host name as the payload of our message and do the division in the notifier later. Here’s the command we’ll use to construct the payload:

    echo $(hostname) `cat /proc/loadavg | cut -f1 -d" "` `getconf _NPROCESSORS_ONLN`

The command displays the hostname, the load average, and the number of processors, respectively:

    Outputyour_hostname 0.28 1

Let’s create a shell script which publishes the host name, load average and processor count to our NATS server with the subject `stats.loadaverage`. We’ll configure our system to run this script periodically. Create a new file called `~/publish_load_average.sh`:

    nano ~/publish_load_average.sh

In the file, add this script:

~/publish\_load\_average.sh

    NATS_ADDR=127.0.0.1:4222
    LOADAVG=$(cat /proc/loadavg | cut -f1 -d" ")
    NPROC=$(getconf _NPROCESSORS_ONLN)
    SUBJECT="stats.loadaverage"
    PAYLOAD=$(echo $(hostname) $LOADAVG $NPROC)
    MESSAGE="PUB $SUBJECT ${#PAYLOAD}\r\n${PAYLOAD}\r\n"
    printf "$MESSAGE" | /srv/nats/bin/catnats -q --raw --addr $NATS_ADDR --user user1 --pass pass1

This script creates the message and then pipes it to `catnats`, which publishes the message to the NATS service. We run `catnats` with the `-q` switch to suppress any output, and we use the `--raw` switch so `catnats` doesn’t try to interpret the contents of the input. You can change the `$NATS_ADDR` variable’s value if the NATS service are on different servers.

Let’s test that the script sends load averages to NATS.

The following command runs `~/publish_load_average.sh` every 5 seconds. Note that we use the `&` character at the end of line to run the command in the background:

    while true; do sh ~/publish_load_average.sh; sleep 5; done &

You’ll see output showing that the command is running in the background with a process ID:

    Output[1] 14123

**Note** : Jot down the process ID somewhere, since you will need to use the ID to stop the command later.

Now connect to NATS and subscribe to the subject `stats.loadaverage` to retrieve load averages:

    printf "SUB stats.loadaverage 0\r\n" | /srv/nats/bin/catnats --raw --no-exit --pong --user user1 --pass pass1

We use the `--no-exit` flag to disable auto-exit, and `--pong` to keep our connection to NATS alive. If everything is correct, you should get an output similar to the following which will update every 5 seconds:

    OutputINFO {"server_id":"A8qJc7mdTy8AWBRhPWACzW","version":"0.8.1","go":"go1.6.2","host":"0.0.0.0","port":4222,"auth_required":true,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    +OK
    +OK
    MSG stats.loadaverage 0 27
    your_hostname 0.08 1

Press `CTRL+C` to exit from `catnats`. Let’s stop the loop that called `publish_load_average.sh` too since we are going to have a better way of running `publish_load_average.sh`:

    kill 14123

The approach we just took works great for testing, but it’s not something we want to use permanently. We would like the system to run `publish_load_average.sh` to run every minute. In order to accomplish that, we can add a _crontab_ entry. Linux systems use `cron`, a system that can run commands, or “jobs”, on a schedule we specify. The `crontab` command lets us manage these jobs. You can learn all about Cron in the tutorial [How To Use Cron To Automate Tasks On a VPS](how-to-use-cron-to-automate-tasks-on-a-vps).

To create a new entry, execute the command:

    crontab -e

If you have never run the command above, you may see the following prompt which will ask you to choose a text editor to manage entries:

    Outputno crontab for demo - using an empty one
    
    Select an editor. To change later, run 'select-editor'.
      1. /bin/ed
      2. /bin/nano <---- easiest
      3. /usr/bin/vim.basic
      4. /usr/bin/vim.tiny
    
    Choose 1-4 [2]:

Type the number corresponding to the editor you are most comfortable with and press `ENTER`. A file will be displayed in the editor you’ve chosen.

At the end of the opened file, add the following line, but substitute your username if you’ve used something other than `sammy`:

    */1 * * * * bash /home/sammy/publish_load_average.sh

The entry above tells `cron` to run our `publish_load_average.sh` script every minute. Save the file and close the editor.

Now let’s test that periodic publishing of the load average is working:

    printf "SUB stats.loadaverage 0\r\n" | /srv/nats/bin/catnats --raw --no-exit --pong --user user1 --pass pass1

Wait for a few minutes, and the output you see will be similar to the following:

    OutputINFO {"server_id":"A8qJc7mdTy8AWBRhPWACzW","version":"0.8.1","go":"go1.6.2","host":"0.0.0.0","port":4222,"auth_required":true,"ssl_required":true,"tls_required":true,"tls_verify":false,"max_payload":1048576}
    +OK
    +OK
    MSG stats.loadaverage 0 27
    your_hostname 0.01 1
    MSG stats.loadaverage 0 27
    your_hostname 0.00 1

Press `CTRL+C` to exit `catnats`.

We have successfully set up the monitor, and it’s sending messages to our NATS server. Next, we’ll set up the notifier that makes use of this data.

### Creating the Notifier

Let’s create the notifier which connects to our NATS service and listens for `stats.loadaverage` messages. Whenever our program receives a message, it calculates the load average per processor. If it is higher than 0.6, or 60% CPU utilization per processor, it sets a warning flag for the host that published the message and sends an email to a predefined address. If the load average per processor is less than 0.4, the warning flag for the host is cleared. To prevent flooding the inbox, we send a single email when the warning flag is set.

We will use Node.JS to create the notifier, as there’s a great NATS client for Node.js. So, install Node.js first:

    sudo apt-get install -y npm

Next, create the directory for the notifier and switch to it:

    mkdir ~/overload_notifier && cd ~/overload_notifier

Node.js projects use a file called `package.json` which contains information about the project and its dependencies. Execute the following command to create that file:

    npm init -y

Then install the NATS client for Node.js, as well as the `nodemailer` module which we’ll use in this project to send warning emails:

    npm install nodemailer@2.4.2 nats@0.6.4 --save-exact

Now we can create the notifier. Create the file `notifier.js`:

    nano notifier.js

Then add the following code to the file:

notifier.js

    var NATS_URL = 'nats://127.0.0.1:4222';
    var NATS_USER = 'user1';
    var NATS_PASS = 'pass1';
    var EMAIL_TO = 'admin@example.com';

Be sure you change these options to match your username and password for the NATS service, as well as your email address.

Next, add this code to import the Node.js NATS client and connect to the `gnatsd` service:

notifier.js

    var tlsOptions = {
      rejectUnauthorized: false,
    };
    var nats = require('nats').connect({url: NATS_URL,
                                        tls: tlsOptions,
                                        user: NATS_USER,
                                        pass: NATS_PASS});

Then add this code to set up the mailer and connect to the SMTP server which will send the emails. We’ll set this server up shortly:

notifier.js

    var nodemailer = require('nodemailer');
    var transport = nodemailer.createTransport('smtp://localhost:2525');

Then add the rest of the code to calculate the load average and determine whether or not we need to send a notification email:

notifier.js

    // keep the state of warnings for each host
    var warnings = {};
    
    function sendEmail(subject, text) {
        transport.sendMail({
            to: EMAIL_TO,
            subject: subject,
            text: text
        });
    }
    
    function processMessage(message) {
        // message fields: host load processor_count
        var fields = message.split(" ");
        var host = fields[0];
        var loadAverage = parseFloat(fields[1]) / parseInt(fields[2]);
        if (loadAverage > 0.6) {
            if (!warnings[host]) {
                // send warning email if one wasn't already sent
                var res = sendEmail('Warning! Server is Overloaded: ' + host,
                                    'Load average: ' + loadAverage);
                // set warning for the host
                warnings[host] = true;
            }
        }
        else if (loadAverage < 0.4) {
            if (warnings[host]) {
                // clear the warning
                warnings[host] = false;
            }
        }
    }
    
    nats.subscribe('stats.loadaverage', processMessage);

We subscribe to the message, and every time we receive a message we execute the `processMessage` function, which parses the payload we sent and determines the load average. If it’s too high, we send the message, and we track if we’ve previously sent one by setting a flag based on the hostname. This way we can track notifications on a per-host basis. If the load average is below our threshold, we clear that flag.

With the monitor and notifier in place, it’s time to test our sample project.

### Testing the Project

Let’s take this for a test drive. We are going to generate some artificial load and check whether the notifier will send the warning email when the load gets too high.

Let’s install the `stress` tool to generate CPU load on our server:

    sudo apt-get install -y stress

Next we need to set up an SMTP server to mail out the messages from our notifier. Installing and configuring a full-blown SMTP server would be overkill for this test, so we are going to use a simple SMTP server which just displays the emails handed to it instead of actually sending them. The Python programming language has a `DebuggingServer` module we can load that discards emails it receives, but displays them to the screen so we can ensure things work. Python is already installed on our Ubuntu server, so this is a perfect solution.

Let’s start the debugging SMTP server in the background. We’ll make it listen on `localhost` port `2525`, which matches the SMTP address we configured in our `notifier.js` code. Execute this command to start the SMTP server:

    python -m smtpd -n -c DebuggingServer localhost:2525 &

Then start the notifier in the background with this command:

    nodejs ~/overload_notifier/notifier.js &

And lastly, let’s generate some load on all processors of our server. Execute the `stress` command with the following options:

    stress --cpu $(getconf _NPROCESSORS_ONLN)

After a few minutes, you’ll see output similar to the following, as the SMTP server starts displaying the messages sent by the notifier:

    Output---------- MESSAGE FOLLOWS ----------
    Content-Type: text/plain
    To: admin@example.com
    Subject: Warning! Server is Overloaded: your_hostname
    Message-Id: <1466354822129-04c5d944-0d19670b-780eee12@localhost>
    X-Mailer: nodemailer (2.4.2; +http://nodemailer.com/;
     SMTP/2.5.0[client:2.5.0])
    Content-Transfer-Encoding: 7bit
    Date: Sun, 19 Jun 2016 16:47:02 +0000
    MIME-Version: 1.0
    X-Peer: 127.0.0.1
    
    Load average: 0.88
    ------------ END MESSAGE ------------

This lets you know you’ve successfully sent emails when the load gets too high on the server.

Press `CTRL+C` to stop generating load. You’ve completed the sample project and should now have a good idea how to make this work for you in your own environment.

## Conclusion

In this article, you learned about the NATS PubSub messaging system, installed it in a secure way as a service, and tested it in a sample project. The sample project used the Node.JS client, but NATS has clients for more languages and frameworks which you can find listed on the [NATS download page](http://nats.io/download). You can learn more about NATS in its [official documentation](http://nats.io/documentation/).
