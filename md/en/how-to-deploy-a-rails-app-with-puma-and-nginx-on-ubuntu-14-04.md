---
author: Mitchell Anicas
date: 2015-04-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-puma-and-nginx-on-ubuntu-14-04
---

# How To Deploy a Rails App with Puma and Nginx on Ubuntu 14.04

## Introduction

When you are ready to deploy your Ruby on Rails application, there are many valid setups to consider. This tutorial will help you deploy the production environment of your Ruby on Rails application, with PostgreSQL as the database, using Puma and Nginx on Ubuntu 14.04.

Puma is an application server, like [Passenger](how-to-deploy-a-rails-app-with-passenger-and-nginx-on-ubuntu-14-04) or [Unicorn](how-to-deploy-a-rails-app-with-unicorn-and-nginx-on-ubuntu-14-04), that enables your Rails application to process requests concurrently. As Puma is not designed to be accessed by users directly, we will use Nginx as a reverse proxy that will buffer requests and responses between users and your Rails application.

## Prerequisites

This tutorial assumes that you have an Ubuntu 14.04 server with the following software installed, on the user that will deploy the application:

- [Ruby on Rails, using rbenv](how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-14-04)
- [PostgreSQL with Rails](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04)

If you do not have that set up already, follow the tutorials that are linked above. We will assume that your user is called **deploy**.

Also, this tutorial does not cover how to set up your development or test environments. If you need help with that, follow the example in the [PostgreSQL with Rails tutorial](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04).

## Create Rails Application

Ideally, you already have a Rails application that you want to deploy. If this is the case, you may skip this section, and make the appropriate substitutions while following along. If not, the first step is to create a new Rails application that uses PostgreSQL as its database.

This command will create a new Rails application, named “appname” that will use PostgreSQL as the database. Feel free to substitute the highlighted “appname” with something else:

    rails new appname -d postgresql

Then change into the application directory:

    cd appname

Let’s take a moment to create the PostgreSQL user that will be used by the production environment of your Rails application.

## Create Production Database User

To keep things simple, let’s name the production database user the same as your application name. For example, if your application is called “appname”, you should create a PostgreSQL user like this:

    sudo -u postgres createuser -s appname

We want to set the database user’s password, so enter the PostgreSQL console like this:

    sudo -u postgres psql

Then set the password for the database user, “appname” in the example, like this:

    \password appname

Enter your desired password and confirm it.

Exit the PostgreSQL console with this command:

    \q

Now we’re ready to configure the your application with the proper database connection information.

## Configure Database Connection

Ensure that you are in your application’s root directory (`cd ~/appname`).

Open your application’s database configuration file in your favorite text editor. We’ll use vi:

    vi config/database.yml

Update the `production` section so it looks something like this:

    production:
      <<: *default
      host: localhost
      adapter: postgresql
      encoding: utf8
      database: appname_production
      pool: 5
      username: <%= ENV['APPNAME_DATABASE_USER'] %>
      password: <%= ENV['APPNAME_DATABASE_PASSWORD'] %>

Note that the database username and password are configured to be read by environment variables, `APPNAME_DATABASE_USER` and `APPNAME_DATABASE_PASSWORD`. It is considered best practice to keep production passwords and secrets outside of your application codebase, as they can easily be exposed if you are using a distributed version control system such as Git. We will go over how to set up the database authentication with environment variables next.

Save and exit.

## Install rbenv-vars Plugin

Before deploying a production Rails application, you should set the production secret key and database password using environment variables. An easy way to manage environment variables, which we can use to load passwords and secrets into our application at runtime, is to use the **rbenv-vars** plugin.

To install the rbenv-vars plugin, simply change to the `.rbenv/plugins` directory and clone it from GitHub. For example, if rbenv is installed in your home directory, run these commands:

    cd ~/.rbenv/plugins
    git clone https://github.com/sstephenson/rbenv-vars.git

### Set Environment Variables

Now that the rbenv-vars plugin is installed, let’s set up the required environment variables.

First, generate the secret key, which will be used to verify the integrity of signed cookies:

    cd ~/appname
    rake secret

Copy the secret key that is generated, then open the `.rbenv-vars` file with your favorite editor. We will use vi:

    vi .rbenv-vars

Any environment variables that you set here can be read by your Rails application.

First, set the `SECRET_KEY_BASE` variable like this (replace the highlighted text with the secret that you just generated and copied):

    SECRET_KEY_BASE=your_generated_secret

Next, set the `APPNAME_DATABASE_USER` variable like this (replace the highlighted “APPNAME” with your your application name, and “appname” with your production database username):

    APPNAME_DATABASE_USER=appname

Lastly, set the `APPNAME_DATABASE_PASSWORD` variable like this (replace the highlighted “APPNAME” with your your application name, and “prod\_db\_pass” with your production database user password):

    APPNAME_DATABASE_PASSWORD=prod_db_pass

Save and exit.

You may view which environment variables are set for your application with the rbenv-vars plugin by running this command:

    rbenv vars

If you change your secret or database password, update your `.rbenv-vars` file. Be careful to keep this file private, and don’t include it any public code repositories.

## Create Production Database

Now that your application is configured to talk to your PostgreSQL database, let’s create the production database:

    RAILS_ENV=production rake db:create

### Generate a Controller

If you are following along with the example, we will generate a scaffold controller so our application will have something to look at:

    rails generate scaffold Task title:string note:text

Now run this command to update the production database:

    RAILS_ENV=production rake db:migrate

You should also precompile the assets:

    RAILS_ENV=production rake assets:precompile

To test out if your application works, you can run the production environment, and bind it to the public IP address of your server (substitute your server’s public IP address):

    RAILS_ENV=production rails server --binding=server_public_IP

Now visit this URL in a web browser:

    http://server_public_IP:3000/tasks

If it’s working properly, you should see this page:

![Tasks controller](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/rails_unicorn/tasks.png)

Go back to your Rails server, and press `Ctrl-c` to stop the application.

## Install Puma

Now we are ready to install Puma.

An easy way to do this is to add it to your application’s `Gemfile`. Open the Gemfile in your favorite editor (make sure you are in your application’s root directory):

    vi Gemfile

At the end of the file, add the Puma gem with this line:

    gem 'puma'

Save and exit.

To install Puma, and any outstanding dependencies, run Bundler:

    bundle

Puma is now installed, but we need to configure it.

## Configure Puma

Before configuring Puma, you should look up the number of CPU cores your server has. You can easily do that with this command:

    grep -c processor /proc/cpuinfo

Now, let’s add our Puma configuration to `config/puma.rb`. Open the file in a text editor:

    vi config/puma.rb

Copy and paste this configuration into the file:

    # Change to match your CPU core count
    workers 2
    
    # Min and Max threads per worker
    threads 1, 6
    
    app_dir = File.expand_path("../..", __FILE__ )
    shared_dir = "#{app_dir}/shared"
    
    # Default to production
    rails_env = ENV['RAILS_ENV'] || "production"
    environment rails_env
    
    # Set up socket location
    bind "unix://#{shared_dir}/sockets/puma.sock"
    
    # Logging
    stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true
    
    # Set master PID and state locations
    pidfile "#{shared_dir}/pids/puma.pid"
    state_path "#{shared_dir}/pids/puma.state"
    activate_control_app
    
    on_worker_boot do
      require "active_record"
      ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
      ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
    end

Change the number of `workers` to the number of CPU cores of your server.

Save and exit. This configures Puma with the location of your application, and the location of its socket, logs, and PIDs. Feel free to modify the file, or add any other options that you require.

Now create the directories that were referred to in the configuration file:

    mkdir -p shared/pids shared/sockets shared/log

## Create Puma Upstart Script

Let’s create an Upstart init script so we can easily start and stop Puma, and ensure that it will start on boot.

Download the Jungle Upstart tool from the Puma GitHub repository to your home directory:

    cd ~
    wget https://raw.githubusercontent.com/puma/puma/master/tools/jungle/upstart/puma-manager.conf
    wget https://raw.githubusercontent.com/puma/puma/master/tools/jungle/upstart/puma.conf

Now open the provided `puma.conf` file, so we can configure the Puma deployment user:

    vi puma.conf

Look for the two lines that specify `setuid` and `setgid`, and replace “apps” with the name of your deployment user and group. For example, if your deployment user is called “deploy”, the lines should look like this:

    setuid deploy
    setgid deploy

Save and exit.

Now copy the scripts to the Upstart services directory:

    sudo cp puma.conf puma-manager.conf /etc/init

The `puma-manager.conf` script references `/etc/puma.conf` for the applications that it should manage. Let’s create and edit that inventory file now:

    sudo vi /etc/puma.conf

Each line in this file should be the path to an application that you want `puma-manager` to manage. Add the path to your application now. For example:

    /home/deploy/appname

Save and exit.

Now your application is configured to start at boot time, through Upstart. This means that your application will start even after your server is rebooted.

### Start Puma Applications Manually

To start all of your managed Puma apps now, run this command:

    sudo start puma-manager

You may also start a single Puma application by using the `puma` Upstart script, like this:

    sudo start puma app=/home/deploy/appname

You may also use `stop` and `restart` to control the application, like so:

    sudo stop puma-manager
    sudo restart puma-manager

Now your Rails application’s production environment is running under Puma, and it’s listening on the `shared/sockets/puma.sock` socket. Before your application will be accessible to an outside user, you must set up the Nginx reverse proxy.

## Install and Configure Nginx

Install Nginx using apt-get:

    sudo apt-get install nginx

Now open the default server block with a text editor:

    sudo vi /etc/nginx/sites-available/default

Replace the contents of the file with the following code block. Be sure to replace the the highlighted parts with the appropriate username and application name (two locations):

    upstream app {
        # Path to Puma SOCK file, as defined previously
        server unix:/home/deploy/appname/shared/sockets/puma.sock fail_timeout=0;
    }
    
    server {
        listen 80;
        server_name localhost;
    
        root /home/deploy/appname/public;
    
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

Save and exit. This configures Nginx as a reverse proxy, so HTTP requests get forwarded to the Puma application server via a Unix socket. Feel free to make any changes as you see fit.

Restart Nginx to put the changes into effect:

    sudo service nginx restart

Now the production environment of your Rails application is accessible via your server’s public IP address or FQDN. To access the Tasks controller that we created earlier, visit your application server in a web browser:

    http://server_public_IP/tasks

You should see the same page that you saw the first time you tested your application, but now it’s being served through Nginx and Puma.

## Conclusion

Congratulations! You have deployed the production environment of your Ruby on Rails application using Nginx and Puma.

If you are looking to improve your production Rails application deployment, you should check out our tutorial series on [How To Use Capistrano to Automate Deployments](https://www.digitalocean.com/community/tutorial_series/how-to-use-capistrano-to-automate-deployments). The series is based on CentOS, but it should still be helpful in automating your deployments.
