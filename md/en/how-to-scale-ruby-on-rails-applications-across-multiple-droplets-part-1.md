---
author: O.S. Tezer
date: 2014-02-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1
---

# How To Scale Ruby on Rails Applications Across Multiple Droplets (Part 1)

## Introduction

* * *

Congratulations are in order. Your web-site is gaining traction and you are growing rapidly. Ruby is your programming language of choice and Rails? _Your go-to framework._ Now you are reaping the benefits of your efforts and sharing the joy of your happy clients thanks to your wonderful app.

However, you are starting to worry in the face of a new challenge: accommodating your ever-increasing number of guests (i.e. scaling).

Despite the controversy on the subject, even if you are running an extremely busy web-site (powered by Ruby and Rails), you can continue to serve your clients in a timely fashion. The key to achieve this is by scaling your application, or in other terms, distributing its load across multiple droplets geared to handle this precise tasks and nothing else.

In this DigitalOcean article we are going to see how to simply scale Ruby on Rails applications horizontally, distributing its load across multiple machines running on Unicorn all carefully set up behind a master load balancer running Nginx HTTP server, tasked with welcoming and handling the incoming requests and balancing the load.

**This tutorial covers distributing your app to multiple servers. However, in order to fully deploy your app, you’ll need to set it up with a database. The next articles in these series cover connecting your servers to a [MySQL](https://www.digitalocean.com/community/articles/scaling-ruby-on-rails-setting-up-a-dedicated-mysql-server-part-2) or [PostgreSQL](https://www.digitalocean.com/community/articles/scaling-ruby-on-rails-setting-up-a-dedicated-postgresql-server-part-3) database.**

## Glossary

* * *

### 1. Scalable Application Deployment

* * *

1. Unicorn Application Server
2. Nginx HTTP Server / Reverse-Proxy / Load-Balancer
3. Our Deployment Preparation Process
4. Final Architecture

### 2. Preparing The Servers And The Operating-System

* * *

### 3. Setting Up Application Servers

* * *

1. Setting Up Ruby Environment
2. Setting Up Rails
3. Installing Unicorn
4. Creating A Sample Rails Application
5. Configuring Unicorn
6. Running Unicorn
7. Finding Server’s IP Address To Configure Nginx

### 4. Setting Up Nginx As Reverse-Proxy And Load-Balancer

1. Setting Up Nginx
2. Configuring Nginx

## Scalable Application Deployment

* * *

Deploying applications, or publishing them online, can _technically_ mean different things and the process itself can take place at different levels. Previously, we have covered multiple ways of deploying Rails applications, using different servers (i.e. Unicorn and Passenger), and even seen how to automate the process using different tools for the job (e.g. Capistrano and Mina).

In order to have a [simply] scalable architecture, we are going to divide our deployment structure into two main elements:

- Application Servers (Unicorn/Rails)

- Front-facing HTTP Server / Load Balancer (Nginx)

The main reason for our preference towards the Unicorn application server is for its advanced functionality and the simple way it can be implemented – and maintained, as well.

The ever-so-popular Nginx HTTP server and reverse-proxy will be our load-balancer, tasked with distributing the load across Unicorn based application servers.

Therefore, we will cover two distinct areas separately.

1. Preparing (and deploying) Rails application servers running Unicorn.

2. Preparing an Nginx based front-facing, load-balancing reverse-proxy to distribute the load across Unicorn(s).

Similar to our previous manuals and articles, we’ll continue to use the latest available version of CentOS operating-system for its design choices which are perfectly aligned with our goal of simplicity and stability.

**Note:** As you make your way through this article, you will see links for others which discuss certain subjects further in depth. If you would like to learn more about them, consider checking them out.

### Unicorn Application Server

* * *

Unicorn is a remarkable application server that contains Rails applications to process the incoming requests. These application servers will only deal with requests that need processing, after having them filtered and pre-processed by front-facing Nginx server(s), working as a load-balancer.

As a very mature web application server, Unicorn is absolutely fully-featured. It denies by design trying to do everything and only handles what needs to be done by a web application and it delegates the rest of the responsibilities to the operating system (i.e. juggling processes).

Unicorn’s _master_ process spawns _workers_ to serve the requests. This process also monitors the workers in order to prevent memory and process related staggering issues. What this means for system administrators is that it will kill a process if, for example, it ends up taking too much time to complete a task or in case memory issues occur.

**Note:** To learn about different Ruby web-application servers and understand what _Rack_ is, check out our article [A Comparison of (Rack) Web Servers for Ruby Web Applications](https://www.digitalocean.com/community/articles/a-comparison-of-rack-web-servers-for-ruby-web-applications).

### Nginx HTTP Server / Reverse-Proxy / Load-Balancer

* * *

Nginx HTTP server, is designed from ground up to act as a multi-purpose, front-facing web server. It is capable of serving static files (e.g. images, text files etc.) extremely well, balance connections and deal with certain exploits attempts. It will act as the first entry point of all requests, and it is going to distribute them, to be processed, web-application servers running Unicorn.

### Our Deployment Preparation Process

* * *

Starting with the following section, we will perform the following procedures to prepare our distributed, load-balanced application deployment set-up.

- Update the operating system [\*]

- Get the necessary basic tools for deployment [\*]

- Install Ruby, Rails and libraries

- Install Application (i.e. Unicorn) and HTTP server (Nginx)

- Configure Nginx to distribute the load on TCP

**Note:** Marked items on the list are procedures that will need to be performed on all provisioned servers, regardless of their designated role as an application server or a load-balancer.

### Final Architecture

* * *

Below is an example of what our final architecture will look like for distributing the load across droplets and scaling horizontally.

    Client Request ----> Nginx (Reverse-Proxy / Load-Balancer)
                            |
                           /|\                           
                          | | `-> App. Server I. 10.128.xxx.yy1:8080 # Our example
                          | `--> App. Server II. 10.128.xxx.yy2:8080
                           `----> ..

## Preparing The Servers And The Operating-System

* * *

We will begin creating our set-up with preparing all the servers that will run Unicorn or Nginx.

In order to install Ruby and the other necessary application (e.g. our servers), we need to first prepare the minimally shipped CentOS droplet and equip it with some development tools that we are going to need.

Run the following command to update the default tools of your CentOS based droplet:

    yum -y update

Install the application bundle containing several development tools by executing the following command:

    yum groupinstall -y 'development tools'

Some of the packages we need for this tutorial (e.g. libyaml-devel, nginx etc.) are _not_ found within the official CentOS repository. To simplify things and not to deal with manually installing them, we will add the EPEL software repository for _YUM_ package manager to use.

    # Enable EPEL Repository
    sudo su -c 'rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'
    
    # Update everything, once more.
    yum -y update

Finally, we need to get `curl-devel` and several other tools and libraries for this tutorial (e.g. Rails needs sqlite-devel).

In order to install them, run the following:

    yum install -y curl-devel nano sqlite-devel libyaml-devel

## Setting Up Application Servers

* * *

In this step, we will prepare the server(s) that will be running the Rails on Unicorn application server.

**Let’s begin with getting Ruby and Rails ready.**

### Setting Up Ruby Environment

* * *

**Note:** This section is a summary of our dedicated article [How To Install Ruby 2.1.0 On CentOS 6.5](https://link_to_6.2_how_to_install_ruby_on_centos).

**Note:** You will need to perform the instructions from the previous section, together with the following, on all your application servers. At bare minimum, you need **one** application server to deploy your app. In order to balance the load, provision more droplets and repeat these steps.

We are going to be using _Ruby Version Manager_ (RVM) to download and install a Ruby interpreter.

Run the following two commands to install RVM and create a system environment for Ruby:

    curl -L get.rvm.io | bash -s stable
    source /etc/profile.d/rvm.sh

Finally, to finish installing Ruby on our system, let’s get RVM to download and install Ruby version 2.1.0:

    rvm reload
    rvm install 2.1.0

### Setting Up Rails

* * *

Since Rails needs first and foremost a JavaScript interpreter to work, we will also need to set up `Node.js`. For this purpose, we will be using the default system package manager YUM.

Run the following to download and install `nodejs` using yum:

    yum install -y nodejs

Execute the following command to download and install `rails` using gem:

    gem install bundler rails

### Installing Unicorn

* * *

There are a couple of ways to easily download Unicorn. Since it is an application-related dependency, the most logical way is to use RubyGems.

Run the following to download and install Unicorn using `gem`:

    gem install unicorn

**Note:** We will see how to work with this tool in the next sections.

### Creating A Sample Rails Application

* * *

**Note:** For our example to work, we are now going to create a basic Rails application. In order to run yours, you will need to upload your application source instead.

### Uploading Your Source Code

* * *

For the actual deployment, you will, of course, want to upload your code base to the server. For this purpose, you can either use SFTP or a graphical tool, such as FileZilla, to transfer and manage remote files securely. Likewise, you can use Git and a central repository such as Github to download and set up your code.

- To learn about working with SFTP, check out the article: [How To Use SFTP](https://www.digitalocean.com/community/articles/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server).

> - To learn about FileZilla, check out the article on the subject: [How To Use FileZilla](https://www.digitalocean.com/community/articles/how-to-use-filezilla-to-transfer-and-manage-files-securely-on-your-vps).

**Let’s begin with creating a very basic Rails application inside our home directory to serve with Unicorn.**

Execute the following command to get Rails to create a new application called _my\_app_:

    # Create a sample Rails application
    cd /var
    mkdir www
    cd www
    rails new my_app
    
    # Enter the application directory
    cd my_app
    
    # Create a sample resource
    rails generate scaffold Task title:string note:text
    
    # Create a sample database
    RAILS_ENV=development rake db:migrate
    RAILS_ENV=production rake db:migrate
    
    # Create a directory to hold the PID files
    mkdir pids    

To test that your application is set correctly and everything is working fine, enter the app directory and run a simple server with `rails s`:

    # Enter the application directory
    cd /var/www/my_app
    
    # Run a simple server
    rails s
    
    # You should now be able to access it by
    # visiting: http://[your droplet's IP]:3000/tasks
    
    # In order to terminate the server process,
    # Press CTRL+C

### Configuring Unicorn

* * *

Unicorn can be configured a number of ways. For this tutorial, focusing on the key elements, we will create a file from scratch which is going to be used by Unicorn when starting the application server daemon process.

Open up a blank `unicorn.rb` document, which will be saved inside `config/` directory using the `nano` text editor:

    nano config/unicorn.rb

Place the below block of code, modifying it as necessary:

    # Set the working application directory
    # working_directory "/path/to/your/app"
    working_directory "/var/www/my_app"
    
    # Unicorn PID file location
    # pid "/path/to/pids/unicorn.pid"
    pid "/var/www/my_app/pids/unicorn.pid"
    
    # Path to logs
    # stderr_path "/path/to/log/unicorn.log"
    # stdout_path "/path/to/log/unicorn.log"
    stderr_path "/var/www/my_app/log/unicorn.log"
    stdout_path "/var/www/my_app/log/unicorn.log"
    
    # Number of processes
    # Rule of thumb: 2x per CPU core available
    # worker_processes 4
    worker_processes 2
    
    # Time-out
    timeout 30

Save and exit by pressing CTRL+X and confirming with Y.

**Note:** To simply test your application with Unicorn, you can run `unicorn_rails` inside the application directory.

**Note:** To learn more about configuring Unicorn, check out its official documentation page [here](http://unicorn.bogomips.org/).

### Running Unicorn

* * *

We are ready to run our application using Unicorn.

Run the following to start Unicorn in daemon mode using the our configuration file (`config/unicorn.rb`):

    unicorn_rails -c config/unicorn.rb -D

### Finding Server’s IP Address To Configure Nginx

* * *

Let’s find our virtual server’s **_private network / private IP_** address.

Run the following to reveal the private IP address of the server:

    ifconfig

Sample output:

    eth0 Link encap:Ethernet HWaddr 04:01:10:4B:B8:01  
              inet addr:107.170.13.134 Bcast:107.170.13.255 Mask:255.255.255.0
              inet6 addr: fe80::601:10ff:fe4b:b801/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
              RX packets:164298 errors:0 dropped:0 overruns:0 frame:0
              TX packets:46316 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:230223345 (219.5 MiB) TX bytes:4969058 (4.7 MiB)
    
    eth1 Link encap:Ethernet HWaddr 04:01:10:4B:B8:02  
              inet addr:10.128.241.135 Bcast:10.128.255.255 Mask:255.255.0.0
              inet6 addr: fe80::601:10ff:fe4b:b802/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST MTU:1500 Metric:1
              RX packets:120 errors:0 dropped:0 overruns:0 frame:0
              TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:6810 (6.6 KiB) TX bytes:874 (874.0 b)
    
    lo Link encap:Local Loopback  
              inet addr:127.0.0.1 Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING MTU:16436 Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:0 
              RX bytes:0 (0.0 b) TX bytes:0 (0.0 b)

Second bit of information here, starting with `eth1` and continuing with `inet adde:` reveals the _private_ IP address assigned to our server, which is `10.128.241.135` in our case.

We are going to use this IP address to have Nginx communicate with our application server.

Note this address and continue to the next step to set-up and configure Nginx.

**Note:** To learn more about private networking on DigitalOcean, check out [How To Set Up And Use DigitalOcean Private Networking](https://www.digitalocean.com/community/articles/how-to-set-up-and-use-digitalocean-private-networking) tutorial on the community articles section.

## Setting Up Nginx As Reverse-Proxy And Load-Balancer

* * *

In this section, we are going to work on our front-facing server and set up Nginx to welcome incoming requests and balance the load across application servers.

### Setting Up Nginx

* * *

Since we have the EPEL repository enabled, it is possible to get Nginx using **yum**.

Run the following to download and install Nginx using yum:

    yum install -y nginx

### Configuring Nginx

* * *

After having Nginx installed, the next step is working with its configuration file, `nginx.conf`, located at `/etc/nginx` by default.

Execute the below command to start editing this file using the `nano` text editor:

    nano /etc/nginx/nginx.conf

Scroll down below the file and comment out the following line:

    # Before:
    include /etc/nginx/conf.d/*.conf;
    
    # After:
    # include /etc/nginx/conf.d/*.conf;

Inside `http {` node, add the following configurations, modifying them to suit your own set-up:

    # Set your server 
    # server_name www.example.com;
    
    upstream unicorn_servers {
    
        # Add a list of your application servers
        # Each server defined on its own line
        # Example:
        # server IP.ADDR:PORT fail_timeout=0;
        server 10.128.241.135:8080 fail_timeout=0;
    
        # server 10.128.241.136:8080 fail_timeout=0;
        # server 10.128.241.137:8080 fail_timeout=0;
    
    }
    
    server {
    
        # Port to listen on
        listen 80;
    
        location / {
            # Set proxy headers        
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    
            proxy_pass http://unicorn_servers;
        }
    
    }

Save and exit by pressing CTRL+X and confirming with Y.

To get started, run the Nginx daemon with the following command:

     service nginx start

After modifying the configuration file, you can restart the server with the following:

    service nginx restart

**Note:** To learn about further configurations and setting up directives for serving static files, check out the official Unicorn [**nginx.conf** example](http://unicorn.bogomips.org/examples/nginx.conf).

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
