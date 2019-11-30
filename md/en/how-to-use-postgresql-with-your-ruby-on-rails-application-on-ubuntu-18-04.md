---
author: Mitchell Anicas, Timothy Nolan
date: 2019-06-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-18-04
---

# How To Use PostgreSQL with Your Ruby on Rails Application on Ubuntu 18.04

## Introduction

When using the [Ruby on Rails](https://rubyonrails.org/) web framework, your application is set up by default to use [SQLite](https://www.sqlite.org/index.html) as a database. SQLite is a lightweight, portable, and user-friendly relational database that performs especially well in low-memory environments, and will work well in many cases. However, for highly complex applications that need more reliable data integrity and programmatic extensibility, a [PostgreSQL](https://www.postgresql.org/) database will be a more robust and flexible choice. In order to configure your Ruby on Rails setup to use PostgreSQL, you will need to perform a few additional steps to get it up and running.

In this tutorial, you will set up a Ruby on Rails development environment connected to a PostgreSQL database on an Ubuntu 18.04 server. You will install and configure PostgreSQL, and then test your setup by creating a Rails application that uses PostgreSQL as its database server.

## Prerequisites

This tutorial requires the following:

- An Ubuntu 18.04 server set up by following the [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a non-root user with sudo privileges and a firewall.

- A Ruby on Rails development environment installed on your Ubuntu 18.04 server. To set this up, follow our guide on [How to Install Ruby on Rails with rbenv on Ubuntu 18.04](how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04). This tutorial will use version 2.6.3 of Ruby and 5.2.3 of Rails; for information on the latest versions, check out the official sites for [Ruby](https://www.ruby-lang.org/en/downloads/releases/) and [Rails](https://guides.rubyonrails.org/). 

## Step 1 – Installing PostgreSQL

In order to configure Ruby on Rails to create your web application with PostgreSQL as a database, you will first install the database onto your server.

Using `sudo` privileges, update your APT package index to make sure that your repositories are up to date:

    sudo apt update

Next, install PostgreSQL and its development libraries:

    sudo apt install postgresql postgresql-contrib libpq-dev

In the previous command, the `postgresql` package holds the main PostgreSQL program, while [`postgresql-contrib`](https://packages.debian.org/jessie/postgresql-contrib-9.4) adds several PostgreSQL features that extend its capabilities. `libpq-dev` is a PostgreSQL library that allows clients to send queries and receive responses from the back-end server, which will allow your application to communicate with its database.

Once PostgreSQL and its dependencies are installed, the next step is to create a role that your Rails application will use later to create your database.

## Step 2 – Creating a New Database Role

In PostgreSQL, **roles** can be used in the same way as users in Linux to organize permissions and authorization. This step will show you how to create a new super user role for your Linux username that will allow you to operate within the PostgreSQL system to create and configure databases.

To create a PostgreSQL super user role, use the following command, substituting the highlighted word with your Ubuntu 18.04 username:

    sudo -u postgres createuser -s sammy -P

Since you specified the `-P` flag, you will be prompted to enter a password for your new role. Enter your desired password, making sure to record it so that you can use it in a configuration file in a future step.

In this command, you used `createuser` to create a role named `sammy`. The `-s` gave this user super user privileges, and `sudo -u` allowed you to run the command from the `postgres` account that is automatically created upon installing PostgreSQL.

**Note:** Since the authentication mode for PostgreSQL on Ubuntu 18.04 starts out as `ident`, by default an Ubuntu user can only operate in PostgreSQL with a role of the same name. For more information, check out the [PostgreSQL official documentation on authentication](https://www.postgresql.org/docs/10/auth-methods.html#AUTH-IDENT).

If you did not use the `-P` flag and want to set a password for the role after you create it, enter the PostgreSQL console with the following command:

    sudo -u postgres psql

You will receive the following output, along with the prompt for the PostgreSQL console:

    Outputpsql (10.9 (Ubuntu 10.9-0ubuntu0.18.04.1))
    Type "help" for help.
    
    postgres=#

The PostgreSQL console is indicated by the `postgres=#` prompt. At the PostgreSQL prompt, enter this command to set the password for the new database role, replacing the highlighted name with the one you created:

    \password sammy

PostgreSQL will prompt you for a password. Enter your desired password at the prompt, then confirm it.

Now, exit the PostgreSQL console by entering this command:

    \q

Your usual prompt will now reappear.

In this step, you created a new PostgreSQL role with super user privileges. Now you are ready to create a new Rails app that uses this role to create a database.

## Step 3 – Creating a New Rails Application

With a role configured for PostgreSQL, you can now create a new Rails application that is set up to use PostgreSQL as a database.

First, navigate to your home directory:

    cd ~

Create a new Rails application in this directory, replacing `appname` with whatever you would like to call your app:

    rails new appname -d=postgresql

The `-d=postgresql` option sets PostgreSQL as the database.

Once you’ve run this command, a new folder named `appname` will appear in your home directory, containing all the elements of a basic Rails application.

Next, move into the application’s directory:

    cd appname

Now that you have created a new Rails application and have moved into the root directory for your project, you can configure and create your PostgreSQL database from within your Rails app.

## Step 4 – Configuring and Creating Your Database

When creating the `development` and `test` databases for your application, Rails will use the PostgreSQL role that you created for your Ubuntu username. To make sure that Rails creates these databases, you will alter the database configuration file of your project. You will then create your databases.

One of the configuration changes to make in your Rails application is to add the password for the PostgreSQL role you created in the last step. To keep sensitive information like passwords safe, it is a good idea to store this in an environment variable rather than to write it directly in your configuration file.

To store your password in an environment variable at login, run the following command, replacing `APPNAME` with the name of your app and `PostgreSQL_Role_Password` with the password you created in the last step:

    echo 'export APPNAME_DATABASE_PASSWORD="PostgreSQL_Role_Password"' >> ~/.bashrc

This command writes the `export` command to your `~/.bashrc` file so that the environment variable will be set at login.

To export the variable for your current session, use the `source` command:

    source ~/.bashrc

Now that you have stored your password in your environment, it’s time to alter the configuration file.

Open your application’s database configuration file in your preferred text editor. This tutorial will use `nano`:

    nano config/database.yml

Under the `default` section, find the line that says `pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>` and add the following highlighted lines, filling in your credentials and the environment variable you created. It should look something like this:

config/database.yml

    ...
    default: &default
      adapter: postgresql
      encoding: unicode
      # For details on connection pooling, see Rails configuration guide
      # http://guides.rubyonrails.org/configuring.html#database-pooling
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      username: sammy
      password: <%= ENV['APPNAME_DATABASE_PASSWORD'] %>
    
    development:
      <<: *default
      database: appname_development
    ...

This will make the Rails application run the database with the correct role and password. Save and exit by pressing `CTRL` + `x`, `Y`, then `ENTER`.

For more information on configuring databases in Rails, see the [Rails documentation](https://guides.rubyonrails.org/configuring.html#configuring-a-database).

Now that you have made changes to `config/database.yml`, create your application’s databases by using the `rails` command:

    rails db:create

Once Rails creates the database, you will receive the following output:

    OutputCreated database 'appname_development'
    Created database 'appname_test'

As the output suggests, this command created a `development` and `test` database in your PostgreSQL server.

You now have a PostgreSQL database connected to your Rails app. To ensure that your application is working, the next step is to test your configuration.

## Step 5 – Testing Your Configuration

To test that your application is able to use the PostgreSQL database, try to run your web application so that it will show up in a browser.

Using the `rails server` command, run your web application on the built-in webserver in your Rails app, [Puma](https://github.com/puma/puma):

    rails server --binding=127.0.0.1

`--binding` binds your application to a specified IP. By default, this flag will bind Rails to `0.0.0.0`, but since this means that Rails will listen to all interfaces, it is more secure to use `127.0.0.1` to specify the `localhost`. By default, the application listens on port `3000`.

Once your Rails app is running, your command prompt will disappear, replaced by this output:

    Output=> Booting Puma
    => Rails 5.2.3 application starting in development
    => Run `rails server -h` for more startup options
    Puma starting in single mode...
    * Version 3.12.1 (ruby 2.6.3-p62), codename: Llamas in Pajamas
    * Min threads: 5, max threads: 5
    * Environment: development
    * Listening on tcp://127.0.0.1:3000
    Use Ctrl-C to stop

To test if your application is running, open up a new terminal window on your server and use the `curl` command to send a request to `127.0.0.1:3000`:

    curl http://127.0.0.1:3000

You will receive a lot of output in HTML, ending in something like:

    Output...
            <strong>Rails version:</strong> 5.2.3<br />
            <strong>Ruby version:</strong> 2.6.3 (x86_64-linux)
          </p>
        </section>
      </div>
    </body>
    </html>

If your Rails application is on a remote server and you want to access it through a web browser, an easy way is to bind it to the public IP address of your server. First, open port `3000` in your firewall:

    sudo ufw allow 3000

Next, look up the public IP address of your server. You can do this by running the following `curl` command:

    curl http://icanhazip.com

This will return your public IP address. Use it with the `rails server` command, substituting `server_public_IP` with your server’s public IP:

    rails server --binding=server_public_IP

Now you will be able to access your Rails application in a local web browser via the server’s public IP address on port `3000` by visiting:

    http://server_public_IP:3000

At this URL, you will find a Ruby on Rails welcome page:

![Ruby on Rails Welcome Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66605/Rails_Welcome.png)

This means that your application is properly configured and connected to the PostgreSQL database.

After testing the configuration, if you would like to close port `3000`, use the following command.

    sudo ufw delete allow 3000

## Conclusion

In this tutorial, you created a Ruby on Rails web application that was configured to use PostgreSQL as a database on an Ubuntu 18.04 server. If you would like to learn more about the Ruby programming language, check out our [How To Code in Ruby series](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-ruby).

For more information on choosing a database for your application, check out our tutorial on the differences between and use cases of [SQLite, PostgreSQL, and MySQL](sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems). If you want to read more about how to use databases, see our [An Introduction to Queries in PostgreSQL](introduction-to-queries-postgresql) article, or explore DigitalOcean’s [Managed Databases product](https://www.digitalocean.com/products/managed-databases/).
