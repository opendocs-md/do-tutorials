---
author: Mitchell Anicas
date: 2015-03-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-14-04
---

# How To Install Ruby on Rails with rbenv on Ubuntu 14.04

## Introduction

Ruby on Rails is an extremely popular open-source web framework that provides a great way to write web applications with Ruby.

This tutorial will show you how to install Ruby on Rails on Ubuntu 14.04, using rbenv. This will provide you with a solid environment for developing your Ruby on Rails applications. rbenv provides an easy way to install and manage various versions of Ruby, and it is simpler and less intrusive than RVM. This will help you ensure that the Ruby version you are developing against matches your production environment.

## Prerequisites

Before installing rbenv, you must have access to a superuser account on an Ubuntu 14.04 server. Follow steps 1-3 of this tutorial, if you need help setting this up: [Initial Server Setup on Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04)

When you have the prerequisites out of the way, let’s move on to installing rbenv.

## Install rbenv

Let’s install rbenv, which we will use to install and manage our Ruby installation.

First, update apt-get:

    sudo apt-get update

Install the rbenv and Ruby dependencies with apt-get:

    sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

Now we are ready to install rbenv. The easiest way to do that is to run these commands, as the user that will be using Ruby:

    cd
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile

**Note:** On Ubuntu Desktop, replace all occurrences `.bash_profile` in the above code block with `.bashrc`.

This installs rbenv into your home directory, and sets the appropriate environment variables that will allow rbenv to the active version of Ruby.

Now we’re ready to install Ruby.

## Install Ruby

Before using rbenv, determine which version of Ruby that you want to install. We will install the latest version, at the time of this writing, Ruby 2.2.3. You can look up the latest version of Ruby by going to the [Ruby Downloads page](https://www.ruby-lang.org/en/downloads/).

As the user that will be using Ruby, install it with these commands:

    rbenv install -v 2.2.3
    rbenv global 2.2.3

The `global` sub-command sets the default version of Ruby that all of your shells will use. If you want to install and use a different version, simply run the rbenv commands with a different version number.

Verify that Ruby was installed properly with this command:

    ruby -v

It is likely that you will not want Rubygems to generate local documentation for each gem that you install, as this process can be lengthy. To disable this, run this command:

    echo "gem: --no-document" > ~/.gemrc

You will also want to install the bundler gem, to manage your application dependencies:

    gem install bundler

Now that Ruby is installed, let’s install Rails.

## Install Rails

As the same user, install Rails with this command (you may specify a specific version with the `-v` option):

    gem install rails

Whenever you install a new version of Ruby or a gem that provides commands, you should run the `rehash` sub-command. This will install _shims_ for all Ruby executables known to rbenv, which will allow you to use the executables:

    rbenv rehash

Verify that Rails has been installed properly by printing its version, with this command:

    rails -v

If it installed properly, you will see the version of Rails that was installed.

### Install Javascript Runtime

A few Rails features, such as the Asset Pipeline, depend on a Javascript runtime. We will install Node.js to provide this functionality.

Add the Node.js PPA to apt-get:

    sudo add-apt-repository ppa:chris-lea/node.js

Then update apt-get and install the Node.js package:

    sudo apt-get update
    sudo apt-get install nodejs

Congratulations! Ruby on Rails is now installed on your system.

## Optional Steps

If you’re looking to improve your setup, here are a few suggestions:

### Configure Git

A good version control system is essential when coding applications. Follow the [How To Set Up Git](how-to-install-git-on-ubuntu-14-04#how-to-set-up-git) section of the How To Install Git tutorial.

### Install a Database

Rails uses sqlite3 as its default database, which may not meet the requirements of your application. You may want to install an RDBMS, such as MySQL or PostgreSQL, for this purpose.

For example, if you want to use MySQL as your database, install MySQL with apt-get:

    sudo apt-get install mysql-server mysql-client libmysqlclient-dev

Then install the `mysql2` gem, like this:

    gem install mysql2

Now you can use MySQL with your Rails application. Be sure to configure MySQL and your Rails application properly.

## Create a Test Application (Optional)

If you want to make sure that your Ruby on Rails installation went smoothly, you can quickly create a test application to test it out. For simplicity, our test application will use sqlite3 for its database.

Create a new Rails application in your home directory:

    cd ~
    rails new testapp

Then move into the application’s directory:

    cd testapp

Create the sqlite3 database:

    rake db:create

If you don’t already know the public IP address of your server, look it up with this command:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Copy the IPv4 address to your clipboard, then use it with this command to start your Rails application (substitute the highlighted part with the IP address):

    rails server --binding=server_public_IP

If it is working properly, your Rails application should be running on port 3000 of the public IP address of your server. Visit your Rails application by going there in a web browser:

    http://server_public_IP:3000

If you see the Rails “Welcome aboard” page, your Ruby on Rails installation is working properly!

## Conclusion

You’re now ready to start developing your new Ruby on Rails application. Good luck!
