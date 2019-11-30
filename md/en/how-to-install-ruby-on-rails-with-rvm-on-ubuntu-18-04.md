---
author: Lisa Tagliaferri
date: 2018-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rvm-on-ubuntu-18-04
---

# How To Install Ruby on Rails with RVM on Ubuntu 18.04

## Introduction

A popular web application framework, Ruby on Rails was designed to help you develop successful projects while writing less code. With an aim to making web development fun and supported by a robust community, Ruby on Rails is open-source software that is free to use and welcomes contributions to make it better.

The command-line tool **RVM** ( **R** uby **V** ersion **M** anager) provides you with a solid development environment. RVM will let you manage and work with multiple Ruby environments and allow you to switch between them. The project repository is located in a [git repository](https://github.com/rvm/rvm).

This tutorial will take you through the Ruby and Rails installation process and set up via RVM

## Prerequisites

This tutorial will take you through the Ruby on Rails installation process via RVM. To follow this tutorial, you need a non-root user with sudo privileges on an Ubuntu 18.04 server.

To learn how to achieve this setup, follow our [manual initial server setup guide](initial-server-setup-with-ubuntu-18-04) or run our [automated script](automating-initial-server-setup-with-ubuntu-18-04).

## Installation

The quickest way of installing Ruby on Rails with RVM is to run the following commands.

We first need to update GPG, which stands for [GNU Privacy Guard](https://www.gnupg.org/), to the most recent version in order to contact a public key server and request a key associated with the given ID.

    sudo apt install gnupg2

We are using a user with `sudo` privileges to update here, but the rest of the commands can be done by a regular user.

Now, we’ll be requesting the RVM project’s key to sign each RVM release. Having the RVM project’s public key allows us to verify the legitimacy of the RVM release we will be downloading, which is signed with the matching private key.

    gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

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

During the installation process, you may be prompted for your regular user’s password. When the installation is complete, source the RVM scripts from the directory they were installed, which will typically be in your `home/username` directory.

    source /home/sammy/.rvm/scripts/rvm

You should now have a full Ruby on Rails environment configured.

## Installing Specific Ruby and Rails Versions

If you need to install a specific version of Ruby for your application, rather than just the most recent one, you can do so with RVM. First, check to see which versions of Ruby are available by listing them:

    rvm list known

Then, install the specific version of Ruby that you need through RVM, where `ruby_version` can be typed as `ruby-2.4.0`, for instance, or just `2.4.0`:

    rvm install ruby_version

After the installation, we can list the available Ruby versions we have installed by typing:

    rvm list

We can switch between the Ruby versions by typing:

    rvm use ruby_version

Since Rails is a gem, we can also install various versions of Rails by using the `gem` command. Let’s first list the valid versions of Rails by doing a search:

    gem search '^rails$' --all

Next, we can install our required version of Rails. Note that `rails_version` will only refer to the version number, as in `5.1.6`.

    gem install rails -v rails_version 

We can use various Rails versions with each Ruby by creating gemsets and then installing Rails within those using the normal `gem` commands.

To create a gemset we will use:

    rvm gemset create gemset_name

To specify a Ruby version to use when creating a gemset, use:

    rvm ruby_version@gemset_name --create

The gemsets allow us to have self-contained environments for gems as well as have multiple environments for each version of Ruby that we install.

## Install JavaScript Runtime

A few Rails features, such as the Asset Pipeline, depend on a JavaScript Runtime. We will install Node.js with the package manager apt to provide this functionality.

Like we did with the RVM script, we can move to a writable directory, verify the Node.js script by outputting it to a file, then read it with `less`:

    cd /tmp
    \curl -sSL https://deb.nodesource.com/setup_10.x -o nodejs.sh
    less nodejs.sh

Once we are satisfied with the Node.js script, we can install the NodeSource Node.js v10.x repo:

    cat /tmp/nodejs.sh | sudo -E bash -

The `-E` flag used here will preserve the user’s existing environment variables.

Now we can update apt and use it to install Node.js:

    sudo apt update
    sudo apt install -y nodejs

At this point, you can begin testing your Ruby on Rails installation and start to develop web applications.

## How To Uninstall RVM

If you no longer wish to use RVM, you can uninstall it by first removing the script calls in your `.bashrc` file and then removing the RVM files.

First, remove the script calls with a text editor like nano:

    nano ~/.bashrc

Scroll down to where you see the RVM lines of your file:

~/.bashrc

    ...
    # Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
    export PATH="$PATH:$HOME/.rvm/bin"

Delete the lines, then save and close the file.

Next, remove RVM with the following command:

    rm -rf ~/.rvm

At this point, you no longer have an

## Conclusion

We have covered the basics of how to install RVM and Ruby on Rails here so that you can use multiple Ruby environments.

For your next steps, you can learn more about [working with RVM and how to use RVM to manage your Ruby installations](how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps).

If you’re new to Ruby, you can learn about programming in Ruby by following our [How To Code in Ruby](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-ruby) tutorial series.

For more scalability, centralization, and control in your Ruby on Rails application, you may want to use it with [PostgreSQL](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04) or [MySQL](how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04) rather than its default sqlite3 database. As your needs grow, you can also learn how to [scale Ruby on Rails applications across multiple servers](how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1).
