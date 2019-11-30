---
author: Li Heng Fong
date: 2018-06-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/securing-communications-three-tier-rails-application-using-ssh-tunnels
---

# Securing Communications in a Three-tier Rails Application Using SSH Tunnels

## Introduction

Web applications are often architected with three distinct tiers:

- The first tier is the _presentation layer_, which is what the user sees.
- Next comes the _application layer_, which provides the [business logic](https://en.wikipedia.org/wiki/Business_logic) of the application.
- Finally, the _data layer_ stores the data needed by the application.

In a [Ruby on Rails](https://rubyonrails.org/) application, this maps loosely to a web server for the presentation layer, a Rails server for the application layer, and a database for the data layer. In this setup, the application layer communicates with the data layer to retrieve data for the application which is then displayed to the user through the presentation layer.

While it is possible to install all these applications on a single server, putting each layer onto its own server makes it easier to scale the application. For instance, if the Rails server were to become a bottleneck, you could add more application servers without affecting the other two layers.

In this tutorial, you will deploy a Rails app in a three-tier configuration by installing a unique set of software on three separate servers, configuring each server and its components to communicate and function together, and securing the connections between them with SSH tunnels. For the software stack, you will use [Nginx](https://www.nginx.com/) as the web server on the presentation layer, [Puma](http://puma.io/) as the Rails application server on the application layer, and [PostgreSQL](https://www.postgresql.org/) as the database on the data layer.

## Prerequisites

In order to complete this tutorial, you will need to spin up three Ubuntu 16.04 servers. Name these **web-server** , **app-server** , and **database-server** , and each should have Private Networking enabled.

Each of the three servers should have a non-root user with `sudo` privileges as well as a firewall configured to allow SSH ocnnections (which you can configure using our [Initial Server Setup guide](initial-server-setup-with-ubuntu-16-04)). In the context of this tutorial, the `sudo` user on each server is named **sammy**.

Additionally, each of the three servers have their own unique configuration requirements:

- On the **web-server** :

- On the **app-server** :

- On the **database-server** :

## Step 1 — Creating a User for the SSH Tunnels

_SSH tunnels_ are encrypted connections that can send data from a port on one server to a port on another server, making it look as though a listening program on the second server is running on the first one. Having a dedicated user for the SSH tunnels helps to improve the security of your setup: should an intruder gain access to the **sammy** user on one of your servers, they will not be able to access the other servers in the three-tier setup. Likewise, if an intruder were to gain access to the **tunnel** user, they will neither be able to edit files in the Rails app directory nor could they use the `sudo` command.

On each server, create an additional user named **tunnel**. The **tunnel** user’s only function is to create SSH tunnels to facilitate communication between the servers, so, unlike **sammy** , do not give **tunnel** `sudo` privileges. Also, the **tunnel** user should not have write access to the Rails app directory. Run the following command on each server to add the **tunnel** user:

    sudo adduser tunnel

On the **web-server** machine, switch to the **tunnel** user.

    sudo su tunnel

As the **tunnel** user, generate an SSH key pair:

    ssh-keygen

Save the key in the default location and do not create a passphrase for the keys, as doing so could complicate authentication later on when you create SSH tunnels between the servers.

After creating the key pair, return to the **sammy** user:

    exit

Now switch to the **app-server** and execute the same commands again:

    sudo su tunnel
    ssh-keygen
    exit

You have now configured all the users you will need for the rest of the tutorial. Net, you’ll make some changes to the the `/etc/hosts` file for each **tunnel** user in order to streamline the process of creating the SSH tunnels.

## Step 2 — Configuring the Hosts File

Throughout this tutorial, there are many times when you must refer to the IP addresses of either the **app-server** or the **database-server** in a command. Rather than having to remember and type out these IP addresses each time, you can add the **app-server** and **database-server** ’s private IPs to each server’s `/etc/hosts` file. This will allow you to use their names in subsequent commands in place of their addresses, and will make the process of setting up SSH tunnels much smoother.

Please note that, in order to keep things simple, this tutorial instructs you to add both the **app-server** and **database-server** ’s private IP addresses to the `/etc/hosts` file on each of the three servers. While it technically isn’t necessary to add either the **app-server** or **database-server** ’s private IP addresses to their own `hosts` files, doing so won’t cause any issues. The method described here was chosen simply for speed and convenience.

First, find your **app-server** and **database-server** ’s private IP addresses. If you’re using DigitalOcean Droplets, navigate to your Control Panel and click on these Droplets’ names. On any of their Droplet-specific pages, both the public and private IP addresses are displayed near the top of the page.

Then on each server, open the `/etc/hosts` file with your favorite text editor and append the following lines:

    sudo nano /etc/hosts

/etc/hosts

    . . .
    app-server_private_ip app-server
    database-server_private_ip database-server

By adding these lines to this file on each server, you can use the names **app-server** and **database-server** in commands that would typically require you to use these servers’ IP addresses. You will use this functionality to set up the SSH keys so each of your **tunnel** users can connect to your other servers.

## Step 3 — Setting up SSH Logins

Now that you have a **tunnel** user and an updated `/etc/hosts` file on all three of your servers, you’re ready to begin creating SSH connections between them.

As you go through this step, think of the three tiers like a pyramid, with the **database-server** at the bottom, the **app-server** in the middle, and the **web-server** at the top. The **app-server** must be able to connect to the **database-server** in order to access the data needed for the Rails app, and the **web-server** must be able to connect to the **app-server** so it has something to present to users.

Thus, you only need to add each **tunnel** user’s SSH public key to the server “underneath” it, meaning that you must add the **web-server**  **tunnel** user’s public key to the **app-server** and add the **app-server**  **tunnel** user’s public key to the **database-server**. This will allow you to establish encrypted SSH tunnels between the tiers and prevent any eavesdroppers on the network from reading the traffic passing between them.

To begin this process, copy the public key of the **tunnel** user on the **web-server** , located at `/home/tunnel/.ssh/id_rsa.pub`, into the `/home/tunnel/.ssh/authorized_keys` file on the **app-server**.

On the **web-server** , display the **tunnel** user’s public key in the terminal with the following command:

    sudo cat /home/tunnel/.ssh/id_rsa.pub

Select the text output and copy it to your system’s clipboard.

SSH into the **app-server** in a separate terminal session, and switch to the tunnel user:

    sudo su tunnel

Append the key in your system’s clipboard to the `authorized_keys` file on the **app-server**. You can use the following command to do so in one step. Remember to replace `tunnel_ssh_publickey_copied_from_web_server` with the public key in your system’s clipboard:

    echo "tunnel_ssh_publickey_copied_from_web-server" >> /home/tunnel/.ssh/authorized_keys

After that, modify the permissions on the `authorized_keys` file to prevent unauthorized access to it:

    chmod 600 /home/tunnel/.ssh/authorized_keys

Then return to the **sammy** user:

    exit

Next, display the public key of the **tunnel** user on the **app-server** — located at `/home/tunnel/.ssh/id_rsa.pub` — and paste it into the `/home/tunnel/.ssh/authorized_keys` file on the **database-server** :

    sudo cat /home/tunnel/.ssh/id_rsa.pub

    sudo su tunnel

Because you did not generate a SSH key pair on the **database-server** , you’ll have to create the `/home/tunnel/.ssh` folder and adjust its permissions:

    mkdir /home/tunnel/.ssh
    chmod 700 /home/tunnel/.ssh

Then add the **app-server** ’s public key to the `authorized_keys` file and adjust its permissions:

    echo "tunnel_ssh_publickey_copied_from_app-server" >> /home/tunnel/.ssh/authorized_keys
    chmod 600 /home/tunnel/.ssh/authorized_keys

Then return to the **sammy** user:

    exit

Next, test the first connection by using SSH to connect to the **app-server** from your **web-server** as the **tunnel** user:

    sudo su tunnel

    ssh tunnel@app-server

The first time you connect from the **web-server** to the **app-server** , you will see a message asking you to confirm that the machine you’re connecting to can be trusted. Type “yes” to accept the authenticity of the **app-server** :

    OutputThe authenticity of host '111.111.11.111 (111.111.11.111)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

You will see the welcome banner from the **app-server** and the command prompt will show that you are logged in to the **app-server**. This confirms that the SSH connection from the **web-server** to the **app-server** is functioning correctly.

Exit from the SSH connection to the **app-server** , and then exit from the **tunnel** user to return to your **web-server** ’s **sammy** user:

    exit
    exit

Next, follow these same steps to test the SSH connection from the **app-server** to the **database-server** :

    sudo su tunnel

    ssh tunnel@database-server

Accept the authenticity of the **database-server** as well. When you see the welcome banner and command prompt from the **database-server** , you will know that the SSH connection from the **app-server** to the **database-server** is working as expected.

Exit from the SSH connection to the **database-server** , and then exit from the **tunnel** user:

    exit
    exit

The SSH connections you’ve set up in the step form the basis of the SSH tunnels that will enable secure communications between your three server tiers. However, in their current form, these connections are vulnerable to crashing and therefore they aren’t as reliable as they could be. By installing some additional software and configuring the tunnel to function as a service, though, you can mitigate these vulnerabilities.

## Step 4 — Setting up a Persistent SSH Tunnel to the Database Server

In the last step, you accessed the command prompt on a remote server from a local one. An SSH tunnel allows you to do much more than this by tunneling traffic from ports on the local host to ports on the remote one. Here, you will use an SSH tunnel to encrypt the connection between your **app-server** and the **database-server**.

If you followed along with all the prerequisites for this tutorial, you will have installed PostgreSQL on both the **app-server** and the **database-server**. To prevent a clash in port numbers, you must configure the SSH tunnel between these servers to forward connections from port `5433` of the **app-server** to port `5432` on the **database-server**. Later on, you will reconfigure your Rails application (hosted on your **app-server** ) to use the instance of PostgreSQL running on the **database-server**.

Starting as the **sammy** user on the **app-server** , switch to the **tunnel** user you created in Step 1:

    sudo su tunnel

Run the `ssh` command with the following flags and options to create the tunnel between the **app-server** and **database-server** :

    ssh -f -N -L 5433:localhost:5432 tunnel@database-server

- The `-f` option sends `ssh` to the background. This allows you to run new commands in your existing prompt while the tunnel continues running as a background process.
- The `-N` option tells `ssh` not to execute a remote command. This is used here as you only want to forward ports.
- The `-L` option is followed by the configuration value `5433:localhost:5432`. This specifies that traffic from port `5433` on the local side (the **app-server** ) is forwarded to **localhost** ’s port `5432` on the remote server (the **database-server** ). Note that **localhost** here is from the point of view of the remote server.
- The final part of the command, `tunnel@database-server`, specifies the user and remote server to connect to.

After establishing the SSH tunnel, return to the **sammy** user:

    exit

At this point, the tunnel is running, but there is nothing watching it to ensure that it stays up. If the process crashes, the tunnel will go down, the Rails app will no longer be able to communicate with its database, and you will start seeing errors.

Kill the tunnel you have created for now as we are going to make a more reliable setup. Since the connection is in the background, you will have to find its process ID to kill it. Because every tunnel is created by the **tunnel** user, you can find its proccess ID by listing the current processes and filtering the output for the keyword ‘tunnel’:

    ps axu | grep tunnel

This will return something like the output below:

    Outputtunnel 21814 0.0 0.1 44920 692 ? Ss 14:12 0:00 ssh -f -N -L 5433:localhost:5432 tunnel@database-server
    sammy 21816 0.0 0.2 12916 1092 pts/0 S+ 14:12 0:00 grep --color=auto tunnel

Stop the process by running the `kill` command followed by its process ID:

    sudo kill 21814

To maintain a persistent SSH connection between the application server and the database, install `autossh`. `autossh` is a program that starts and monitors an SSH connection, and restarts it should the connection die or stop passing traffic:

    sudo apt-get install autossh

[`systemd` is the default _init system_ on Ubuntu](understanding-systemd-units-and-unit-files), meaning that it manages processes after the system boots. You can use `systemd` to create a service that will manage and automatically start your SSH tunnel when the server restarts. To do this, create a file called `db-tunnel.service` within the `/lib/systemd/system/` directory, the standard location where `systemd` unit files are stored:

    sudo nano /lib/systemd/system/db-tunnel.service

Add the following content to the new file to configure a service for `systemd` to manage:

/lib/systemd/system/db-tunnel.service

    
    [Unit]
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    User=tunnel
    WorkingDirectory=/home/tunnel
    ExecStart=/bin/bash -lc 'autossh -N -L 5433:localhost:5432 tunnel@database-server'
    Restart=always
    StandardInput=null
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=%n
    KillMode=process
    
    [Install]
    WantedBy=multi-user.target

The key line here is `ExecStart`. This specifies the full path to the command and the arguments it needs to execute in order to start the process. Here, it starts a new `bash` shell and then runs the `autossh` program.

Save and close the file, and then reload the `systemd` configuration to make sure that it picks up the new service file:

    sudo systemctl daemon-reload

Enable the `db-tunnel` service so the tunnel to the **database-server** starts automatically whenever the server boots up:

    sudo systemctl enable db-tunnel.service

Then, start the service:

    sudo systemctl start db-tunnel.service

Run the following command again to check whether the tunnel is up:

    ps axu | grep tunnel

In the output, you will see that there are more processes running this time because `autossh` is now monitoring the tunnel:

    Outputtunnel 25925 0.0 0.1 4376 704 ? Ss 14:45 0:00 /usr/lib/autossh/autossh -N -L 5432:localhost:5432 tunnel@database-server
    tunnel 25939 0.2 1.0 44920 5332 ? S 14:45 0:00 /usr/bin/ssh -L 61371:127.0.0.1:61371 -R 61371:127.0.0.1:61372 -N -L 5432:localhost:5432 tunnel@database-server
    sammy 25941 0.0 0.2 12916 1020 pts/0 S+ 14:45 0:00 grep --color=auto tunnel

Now that the tunnel is up and running, you can test the connection to the **database-server** with `psql` to ensure that it is working correctly.

Start the `psql` client and tell it to connect to `localhost`. You must also specify port `5433` to connect through the SSH tunnel to the PostgreSQL instance on the **database-server**. Specify the database name you created earlier, and key in the password you created for the database user when prompted:

    psql -hlocalhost -p5433 sammy

If you see something like the following output, the database connection has been set up correctly:

    Outputpsql (9.5.10)
    SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
    Type "help" for help.
    
    sammy=#

To close the PostgreSQL prompt, type `\q` and then press `ENTER`.

At last, you have a persistent, reliable SSH tunnel that encrypts traffic between your **app-server** and **database-server**. The tunnel’s security features are key, because it is over this tunnel that the Rails app on your **app-server** will communicate with the PostgreSQL instance on your **database-server**.

## Step 5 — Configuring Rails to Use a Remote Database

Now that the tunnel from the **app-server** to the **database-server** is set up, you can use it as a secure channel for your Rails app to connect through the tunnel to the PostgreSQL instance on the **database-server**.

Open the application’s database configuration file:

    nano /home/sammy/appname/config/database.yml

Update the `production` section so the port number is specified as an environment variable. It should now look something like this:

/home/sammy/appname/config/database.yml

    . . .
    production:
      <<: *default
      host: localhost
      adapter: postgresql
      encoding: utf8
      database: appname_production
      pool: 5
      username: <%= ENV['APPNAME_DATABASE_USER'] %>
      password: <%= ENV['APPNAME_DATABASE_PASSWORD'] %>
      port: <%= ENV['APPNAME_DATABASE_PORT'] %>

Save and close this file, then open the `.rbenv-vars` file in the application directory and edit the environment variables:

    nano /home/sammy/appname/.rbenv-vars

If you set a different name and password for the PostgreSQL role on the **database-server** , replace them now (in the example below, the PostgreSQL role is named **sammy** ). Also, add a new line to specify the database port. After making these changes, your `.rbenv-vars` file should look like this:

/home/sammy/appname/.rbenv-vars

    
    SECRET_KEY_BASE=secret_key_base
    APPNAME_DATABASE_USER=sammy
    APPNAME_DATABASE_PASSWORD=database_password
    APPNAME_DATABASE_PORT=5433

Save and close this file when finished.

Because you are now using the PostgreSQL instance on the **database-server** instead of the one on the **app-server** where you deployed your Rails app, you will have to set up the database again.

On the **app-server** , navigate to your app’s directory and run the `rake` command to set up the database:

**Note:** This command will **not** migrate any data from the existing database to the new one. If you have important data on your database already, you should back it up and then restore it later.

    cd /home/sammy/appname
    rake db:setup

Once this command completes, your Rails app will begin communicating with the PostgreSQL instance on the **database-server** over an encrypted SSH tunnel. The next thing to do is configure Puma as a `systemd` service to make it easier to manage.

## Step 6 — Configuring and Starting Puma

Similar to how you set up the `db-tunnel` service in Step 4, you will configure `systemd` to run Puma (the server software you installed on the **app-server** as part of the prerequisites) as a service. Running Puma as a service allows it to start automatically when the server boots or restart automatically if it crashes, helping to make your deployment more robust.

Create a new file called `puma.service` within the `/lib/systemd/system/` directory:

    sudo nano /lib/systemd/system/puma.service

Add the following content, which was adapted from [Puma’s `systemd` documentation](https://github.com/puma/puma/blob/master/docs/systemd.md), to the new file. Be sure to update the highlighted values in the `User`, `WorkingDirectory`, and `ExecStart` directives to reflect your own configuration:

/lib/systemd/system/puma.service

    
    [Unit]
    Description=Puma HTTP Server
    After=network.target
    
    [Service]
    # Foreground process (do not use --daemon in ExecStart or config.rb)
    Type=simple
    
    # Preferably configure a non-privileged user
    User=sammy
    
    # The path to the puma application root
    # Also replace the "<WD>" place holders below with this path.
    WorkingDirectory=/home/sammy/appname
    
    # Helpful for debugging socket activation, etc.
    # Environment=PUMA_DEBUG=1
    
    Environment=RAILS_ENV=production
    
    # The command to start Puma.
    ExecStart=/home/sammy/.rbenv/bin/rbenv exec bundle exec puma -b tcp://127.0.0.1:9292
    
    Restart=always
    
    [Install]
    WantedBy=multi-user.target

Save and close the file. Then reload `systemd`, enable the Puma service, and start Puma:

    sudo systemctl daemon-reload
    sudo systemctl enable puma.service
    sudo systemctl start puma.service

After this, confirm that Puma is running by checking the service’s status:

    sudo systemctl status puma.service

If it is running, you will see an output similar to this:

    Outputpuma.service - Puma HTTP Server
       Loaded: loaded (/lib/systemd/system/puma.service; enabled; vendor preset: enabled)
       Active: active (running) since Tue 2017-12-26 05:35:50 UTC; 1s ago
     Main PID: 15051 (bundle)
        Tasks: 2
       Memory: 31.4M
          CPU: 1.685s
       CGroup: /system.slice/puma.service
               └─15051 puma 3.11.0 (tcp://127.0.0.1:9292) [appname]
    
    Dec 26 05:35:50 app systemd[1]: Stopped Puma HTTP Server.
    Dec 26 05:35:50 app systemd[1]: Started Puma HTTP Server.
    Dec 26 05:35:51 app rbenv[15051]: Puma starting in single mode...
    Dec 26 05:35:51 app rbenv[15051]: * Version 3.11.0 (ruby 2.4.3-p205), codename: Love Song
    Dec 26 05:35:51 app rbenv[15051]: * Min threads: 5, max threads: 5
    Dec 26 05:35:51 app rbenv[15051]: * Environment: production

Next, use `curl` to access and print the contents of the web page so you can check that it is being served correctly. The following command tells `curl` to visit the the Puma server you just started on **app-server** on port `9292`:

    curl localhost:9292/tasks

If you see something like the code below, then it confirms that both Puma and the database connection are working correctly:

    Output...
    
    <h1>Tasks</h1>
    
    <table>
      <thead>
        <tr>
          <th>Title</th>
          <th>Note</th>
          <th colspan="3"></th>
        </tr>
      </thead>
    
      <tbody>
      </tbody>
    </table>
    
    ...

Once you can confirm that your Rails app is being served by Puma and is correctly configured to use a remote PostgreSQL instance on the **database-server** , you can move on to setting up the SSH tunnel between the **web-server** and the **app-server**.

## Step 7 — Setting up and Persisting the SSH Tunnel to the App Server

Now that the **app-server** is up and running, you can connect it to the **web-server**. Similarly to the process you went through in Step 4, you will do this by setting up another SSH tunnel. This tunnel will allow Nginx on the **web-server** to connect securely over an encrypted connection to Puma on the **app-server**.

Start by installing `autossh` on the **web-server** :

    sudo apt-get install autossh

Create a new file called `app-tunnel.service` in the `/lib/systemd/system/` directory:

    sudo nano /lib/systemd/system/app-tunnel.service

Add the following content to this file. Again, the key line is the one that begins with `ExecStart`. Here, this line forwards port `9292` on the **web-server** to port `9292` on the **app-server** where Puma is listening:

/lib/systemd/system/app-tunnel.service

    
    [Unit]
    StopWhenUnneeded=true
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    User=tunnel
    WorkingDirectory=/home/tunnel
    ExecStart=/bin/bash -lc 'autossh -N -L 9292:localhost:9292 tunnel@app-server'
    Restart=always
    StandardInput=null
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=%n
    KillMode=process
    
    [Install]
    WantedBy=multi-user.target

**Note:** The port number in the `ExecStart` line is the same as the one configured for Puma in the previous step.

Reload `systemd` so it reads the new service file, then enable and start the `app-tunnel` service:

    sudo systemctl daemon-reload
    sudo systemctl enable app-tunnel.service
    sudo systemctl start app-tunnel.service

Check that the tunnel is up:

    ps axu | grep tunnel

You should see something resembling the output below:

    Outputtunnel 19469 0.0 0.1 4376 752 ? Ss 05:45 0:00 /usr/lib/autossh/autossh -N -L 9292:localhost:9292 tunnel@app-server
    tunnel 19482 0.5 1.1 44920 5568 ? S 05:45 0:00 /usr/bin/ssh -L 54907:127.0.0.1:54907 -R 54907:127.0.0.1:54908 -N -L 9292:localhost:9292 tunnel@app-server
    sammy 19484 0.0 0.1 12916 932 pts/0 S+ 05:45 0:00 grep --color=auto tunnel

This filtered process listing shows that `autossh` is running and it has started another `ssh` process which creates the actual encrypted tunnel between **web-server** and **app-server**.

Your second tunnel is now up and encrypting communication between your **web-server** and **app-server**. All that’s left for you to do in order to get your three-tier Rails app up and running is to configure Nginx to pass requests to Puma.

## Step 8 — Configuring Nginx

At this point, all the required SSH connections and tunnels have been set up and each of your three server tiers are able to communicate with one another. The final piece of this puzzle is for you to configure Nginx to send requests to Puma to make the setup fully functional.

On the **web-server** , create a new Nginx configuration file at `/etc/nginx/sites-available/appname`:

    sudo nano /etc/nginx/sites-available/appname

Add the following content into the file. This Nginx configuration file is similar to the one you used if you followed our guide on [How To Deploy a Rails App with Puma and Nginx](how-to-deploy-a-rails-app-with-puma-and-nginx-on-ubuntu-14-04#install-and-configure-nginx). The main difference is the location of the upstream app; instead of using the local socket file, this configuration points Nginx to the SSH tunnel listening on port `9292`:

/etc/nginx/sites-available/appname

    upstream app {
        server 127.0.0.1:9292;
    }
    
    server {
        listen 80;
        server_name localhost;
    
        root /home/sammy/appname/public;
    
        try_files $uri/index.html $uri @app;
    
        location @app {
            proxy_pass http://app;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $http_host;
            proxy_redirect off;
        }
    
        error_page 500 502 503 504 /500.html;
        client_max_body_size 4G;
        keepalive_timeout 10;
    }

Save and close this file, then enable the site and make the changes active.

First, remove the default site:

    sudo rm /etc/nginx/sites-enabled/default

Change to the Nginx `sites-enabled` directory:

    cd /etc/nginx/sites-enabled

Create a _symbolic link_ in the `sites-enabled` directory to the file you created just now in the `sites-available` directory:

    sudo ln -s /etc/nginx/sites-available/appname appname

Test your Nginx configuration for syntax errors:

    sudo nginx -t

If any errors are reported, go back and check your file before continuing.

When you’re ready, restart Nginx so it reads your new configuration:

    sudo systemctl restart nginx

If you followed the Puma tutorial in the prerequisites, you would have installed Nginx and PostgreSQL on the **app-server**. Both were replaced by separate instances running on the other two servers, so these programs are redundant. Therefore, you should remove these packages from the **app-server** :

    sudo apt remove nginx
    sudo apt remove postgresql

After removing these packages, be sure to update your firewall rules to prevent any unwanted traffic from accessing these ports.

Your Rails app is now in production. Visit your **web-server** ’s public IP in a web browser to see it in action:

    http://web-server_public_IP/tasks

## Conclusion

By following this tutorial, you have deployed your Rails application on a three-tiered architecture and secured the connections from your **web-server** to the **app-server** , and from the **app-server** to the **database-server** with encrypted SSH tunnels.

With the various components of your application on separate servers, you can pick the optimal specifications for each server based on the amount of traffic your site receives. The first step to doing this is to monitor the resources the server is consuming. See [our guide on CPU monitoring](how-to-monitor-cpu-use-on-digitalocean-droplets) for instructions on how to monitor your servers’ CPU usage. If you see that CPU or memory usage on one tier is very high, you can resize the server on that tier alone. For more advice on picking a server size, see our guide on [Choosing the Right Droplet for Your Application](choosing-the-right-droplet-for-your-application).

As an immediate next step, you should also secure the connection from your users to the **web-server** by installing an SSL certificate on the **web-server**. Check out the [Nginx Let’s Encrypt tutorial](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04) for instructions. Also, if you’d like to learn more about using SSH tunnels check out [this guide](ssh-essentials-working-with-ssh-servers-clients-and-keys#setting-up-ssh-tunnels).
