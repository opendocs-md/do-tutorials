---
author: Brian Hogan
date: 2016-12-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rvm-on-debian-8
---

# How To Install Ruby on Rails with RVM on Debian 8

## Introduction

[Ruby on Rails](http://rubyonrails.org/) is one of the most popular application stacks for developers looking to create sites and web apps. The Ruby programming language, combined with the Rails development framework, makes app development simple.

You can easily install Ruby and Rails with [RVM](https://rvm.io/), the Ruby Version Manager. RVM also lets you manage and work with multiple Ruby environments.

In this guide, you’ll install RVM on a Debian 8 server, and then use RVM to install a stable version of Ruby on Rails. Once things are working, you’ll learn how to manage multiple versions of Ruby with RVM.

## Prerequisites

To follow this tutorial, you need:

- A Debian 8 server with a non-root user with `sudo` privileges. You can set up a user with these privileges in our [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8) guide.
- Node.js installed on your server, as Ruby on Rails uses Node.js to manage client-side assets. Follow [How To Install Node.js on Debian 8](how-to-install-node-js-on-debian-8).

## Installation

The quickest way to install Ruby on Rails with RVM is to run the installation script hosted on the RVM web site.

First, use the `gpg` command to contact a public key server and request the RVM project’s key which is used to sign each RVM release. This lets you verify the legitimacy of the RVM release you’ll download. From your home directory, execute the following command:

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

You’ll see the following output:

    Outputgpg: directory `/home/sammy/.gnupg' created
    gpg: new configuration file `/home/sammy/.gnupg/gpg.conf' created
    gpg: WARNING: options in `/home/sammy/.gnupg/gpg.conf' are not yet active during this run
    gpg: keyring `/home/sammy/.gnupg/secring.gpg' created
    gpg: keyring `/home/sammy/.gnupg/pubring.gpg' created
    gpg: requesting key D39DC0E3 from hkp server keys.gnupg.net
    gpg: /home/sammy/.gnupg/trustdb.gpg: trustdb created
    gpg: key D39DC0E3: public key "Michal Papis (RVM signing) <mpapis@gmail.com>" imported
    gpg: no ultimately trusted keys found
    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

Next, use the `curl` command to download the RVM installation script from the project’s website. The backslash that leads the command ensures that we are using the regular `curl` command and not any altered, aliased version.

    \curl -sSL https://get.rvm.io -o rvm.sh

The `-s` flag indicates that the utility should operate in silent mode, while the `-S` flag tells `curl` to still show errors if it fails. The `-L` flag follows any redirects, and the `-o` flag writes output to a file instead of standard output.

To audit the contents of the script before applying it, open it in a text editor to view its contents:

    nano rvm.sh

Once you’re comfortable with the script’s contents, [pipe](an-introduction-to-linux-i-o-redirection#pipes) the script to `bash` to install the latest stable Rails version, which will also pull in the associated latest stable release of Ruby.

    cat rvm.sh | bash -s stable --rails

During the installation process, you will be prompted for your regular user’s password.

    Output...
    
    Checking requirements for debian.
    Installing requirements for debian.
    Updating system sammy password required for 'apt-get --quiet --yes update':

Enter your password and RVM will install the tools it needs to build and compile Ruby.

    Output...
    Installing required packages: gawk, g++, gcc, make, libc6-dev, libreadline6-dev, zlib1g-dev, libssl-dev, libyaml-dev, libsqlite3-dev, sqlite3, autoconf, libgmp-dev, libgdbm-dev, libncurses5-dev, automake, libtool, bison, pkg-config, libffi-dev
    Requirements installation successful.

It will then download the latest version of Ruby, the Ruby on Rails framework, and its dependencies.

    Output...
    ruby-2.3.0 - #configure
    ruby-2.3.0 - #download
      % Total % Received % Xferd Average Speed Time Time Time Current
                                     Dload Upload Total Spent Left Speed
    100 24.2M 100 24.2M 0 0 31.4M 0 --:--:-- --:--:-- --:--:-- 31.4M
    No checksum for downloaded archive, recording checksum in user configuration.
    ruby-2.3.0 - #validate archive
    ruby-2.3.0 - #extract
    ruby-2.3.0 - #validate binary
    ruby-2.3.0 - #setup
    ruby-2.3.0 - #gemset created /home/sammy/.rvm/gems/ruby-2.3.0@global
    ruby-2.3.0 - #importing gemset /home/sammy/.rvm/gemsets/global.gems..............................
    ruby-2.3.0 - #generating global wrappers........
    ruby-2.3.0 - #gemset created /home/sammy/.rvm/gems/ruby-2.3.0
    ruby-2.3.0 - #importing gemsetfile /home/sammy/.rvm/gemsets/default.gems evaluated to empty gem list
    ruby-2.3.0 - #generating default wrappers........
    Creating alias default for ruby-2.3.0...
    
    ...
    
    36 gems installed
    
      * To start using RVM you need to run `source /home/sammy/.rvm/scripts/rvm`
        in all your open shell windows, in rare cases you need to reopen all shell windows.
    
      * To start using rails you need to run `rails new <project_dir>`.

When the installation is complete, source the RVM scripts by typing:

    source ~/.rvm/scripts/rvm

Verify that Ruby is installed via RVM by using the `which` command:

    which ruby

The output you see should look like this:

    Output/home/sammy/.rvm/rubies/ruby-2.3.0/bin/ruby

You now have a full Ruby on Rails environment configured.

## Installing Specific Ruby and Rails Versions

If you need to install a specific version of Ruby for your application, rather than just the most recent one, you can do so with RVM. First, make sure RVM is the most current release. Run this command to update RVM, ensuring that the list of available Ruby versions is up-to-date:

    rvm get stable

Then check to see which versions of Ruby are available by listing them:

    rvm list known

Then, install the specific version of Ruby that you need through RVM, where `ruby_version` can be typed as `ruby-2.3.0`, for instance, or just `2.3.0`:

    rvm install ruby_version

After the installation, list the available Ruby versions we have installed by typing:

    rvm list

You can switch between the Ruby versions by typing:

    rvm use ruby_version

Since Rails is a gem, you can also install various versions of Rails by using the `gem` command. First, list the valid versions of Rails by doing a search:

    gem search '^rails$' --all

Next, install your desired version of Rails. Note that `rails_version` will only refer to the version number, as in `4.2.7`.

    gem install rails -v rails_version 

You can use various Rails versions with each Ruby version by creating gemsets and then installing Rails within those using the normal `gem` commands:

    rvm gemset create gemset_name # create a gemset
    rvm ruby_version@gemset_name # specify Ruby version and our new gemset
    gem install rails -v rails_version 

Gemsets give self-contained environments for your Ruby applications, and they allow for multiple environments for each version of Ruby that you install. This means you can easily test an application on many versions of Ruby to see what issues you might encounter.

## Conclusion

Now that you’ve installed RVM and Ruby on Rails, you can start to develop or deploy web applications. You can learn more about [working with RVM and how to use RVM to manage your Ruby installations](how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps). As your needs grow, you can also [scale Ruby on Rails applications across multiple servers](how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1).
