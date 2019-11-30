---
author: Lisa Tagliaferri
date: 2016-07-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rvm-on-ubuntu-16-04
---

# How To Install Ruby on Rails with RVM on Ubuntu 16.04

## Introduction

Ruby on Rails is one of the most popular application stacks for developers looking to create sites and web apps. The Ruby programming language, combined with the Rails development framework, makes app development simple.

You can easily install Ruby and Rails with the command-line tool **RVM** (Ruby Version Manager). RVM will also let you manage and work with multiple Ruby environments and allow you to switch between them. The project repository is located on [GitHub](https://github.com/rvm/rvm).

In this guide, we’ll install RVM on an Ubuntu 16.04 server, and then use that to install a stable version of Ruby and Rails.

## Prerequisites

This tutorial will take you through the Ruby on Rails installation process via RVM. To follow this tutorial, you need an Ubuntu 16.04 server with a [non-root user](initial-server-setup-with-ubuntu-16-04).

## Installation

The quickest way of installing Ruby on Rails with RVM is to run the following commands as a regular user. You will be prompted for your regular user’s password as part of the installation procedure.

First, we’ll use a `gpg` command to contact a public key server and request a key associated with the given ID. In this case we are requesting the RVM project’s key which is used to sign each RVM release. Having the RVM project’s public key allows us to verify the legitimacy of the RVM release we will be downloading, which is signed with the matching private key.

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

Let’s now move into a writable location such as the `/tmp` directory and then download the RVM script into a file:

    cd /tmp

We’ll use the `curl` command to download the RVM installation script from the project’s website. The backslash that leads the command ensures that we are using the regular `curl` command and not any altered, aliased version.

We will append the `-s` flag to indicate that the utility should operate in silent mode along with the `-S` flag to override some of this to allow `curl` to output errors if it fails. The `-L` flag tells the utility to follow redirects, and finally the `-o` flag indicates to write output to a file instead of standard output.

Putting all of these elements together, our full command will look like this:

    curl -sSL https://get.rvm.io -o rvm.sh

Once it is downloaded, if you would like to audit the contents of the script before applying it, run:

    less /tmp/rvm.sh

Then we can [pipe](an-introduction-to-linux-i-o-redirection#pipes) it to `bash` to install the latest stable Rails version which will also pull in the associated latest stable release of Ruby.

    cat /tmp/rvm.sh | bash -s stable --rails

During the installation process, you will be prompted for your regular user’s password. When the installation is complete, source the RVM scripts from the directory they were installed, which will typically be in your `home/username` directory.

    source /home/sammy/.rvm/scripts/rvm

You should now have a full Ruby on Rails environment configured.

## Installing Specific Ruby and Rails Versions

If you need to install a specific version of Ruby for your application, rather than just the most recent one, you can do so with RVM. First, check to see which versions of Ruby are available by listing them:

    rvm list known

Then, install the specific version of Ruby that you need through RVM, where `ruby_version` can be typed as `ruby-2.3.0`, for instance, or just `2.3.0`:

    rvm install ruby_version

After the installation, we can list the available Ruby versions we have installed by typing:

    rvm list

We can switch between the Ruby versions by typing:

    rvm use ruby_version

Since Rails is a gem, we can also install various versions of Rails by using the `gem` command. Let’s first list the valid versions of Rails by doing a search:

    gem search '^rails$' --all

Next, we can install our required version of Rails. Note that `rails_version` will only refer to the version number, as in `4.2.7`.

    gem install rails -v rails_version 

We can use various Rails versions with each Ruby by creating gemsets and then installing Rails within those using the normal `gem` commands:

    rvm gemset create gemset_name # create a gemset
    rvm ruby_version@gemset_name # specify Ruby version and our new gemset

The gemsets allow us to have self-contained environments for gems and allow us to have multiple environments for each version of Ruby that we install.

## Install JavaScript Runtime

A few Rails features, such as the Asset Pipeline, depend on a JavaScript Runtime. We will install Node.js through apt-get to provide this functionality.

Like we did with the RVM script, we can move to a writable directory, verify the Node.js script by outputting it to a file, then read it with `less`:

    cd /tmp
    \curl -sSL https://deb.nodesource.com/setup_6.x -o nodejs.sh
    less nodejs.sh

Once we are satisfied with the Node.js script, we can install the NodeSource Node.js v6.x repo:

    cat /tmp/nodejs.sh | sudo -E bash -

The `-E` flag used here will preserve the user’s existing environment variables.

Now we can update apt-get and use it to install Node.Js:

    sudo apt-get update
    sudo apt-get install -y nodejs

At this point, you can begin testing your Ruby on Rails installation and start to develop web applications.

## Learning More

We have covered the basics of how to install RVM and Ruby on Rails here so that you can use multiple Ruby environments. For your next steps, you can learn more about [working with RVM and how to use RVM to manage your Ruby installations](how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps). For more scalability, centralization, and control in your Ruby on Rails application, you may want to use it with [PostgreSQL](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04) or [MySQL](how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04) rather than its default sqlite3 database. As your needs grow, you can also learn how to [scale Ruby on Rails applications across multiple servers](how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1).
