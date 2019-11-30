---
author: Justin Ellingwood
date: 2014-04-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-on-ubuntu-14-04-using-rvm
---

# How To Install Ruby on Rails on Ubuntu 14.04 using RVM

## Introduction

Ruby on Rails is one of the most popular application stacks for developers wishing to create sites and web apps. The Ruby programming language, coupled with the Rails development framework, makes app development simple.

Since Ruby on Rails doesn’t come in a neatly packaged format, getting the framework installed used to be one of the more difficult parts of getting started. Luckily, tools like **rvm** , the Ruby Version Manager, have made installation simple.

In this guide, we’ll show how to install `rvm` on an Ubuntu 14.04 VPS, and use it to install a stable version of Ruby and Rails. Although you can go through these procedures as the root user, we’ll assume you’re operating using [an unprivileged user](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04) as shown in steps 1-4 in this guide.

## The Quick Way

The quickest way of installing Ruby on Rails with `rvm` is to run the following commands as a regular user:

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    \curl -sSL https://get.rvm.io | bash -s stable --rails

You will be prompted for your regular user’s password as part of the installation procedure.

Let’s go over exactly what’s happening here.

The `gpg` command contacts a public key server and requests a key associated with the given ID. In this case we are requesting the RVM project’s key which is used to sign each RVM release. Having the RVM project’s public key allows us to verify the legitimacy of the RVM release we will be downloading, which is signed with the matching private key.

The `\curl` portion uses the `curl` web grabbing utility to grab a script file from the `rvm` website. The backslash that leads the command ensures that we are using the regular `curl` command and not any altered, aliased version.

The `-s` flag indicates that the utility should operate in silent mode, the `-S` flag overrides some of this to allow `curl` to output errors if it fails. The `-L` flag tells the utility to follow redirects.

The script is then piped directly to `bash` for processing. The `-s` flag indicates that the input is coming from standard in. We then specify that we want the latest stable version of `rvm`, and that we also want to install the latest stable Rails version, which will pull in the associated Ruby.

Following a long installation procedure, all you need to do is source the `rvm` scripts by typing:

    source ~/.rvm/scripts/rvm

You should now have a full Ruby on Rails environment configured.

## Installing Specific Ruby and Rails Versions

If you need to install specific versions of Ruby for your application, you can do so with `rvm` like this:

    rvm install ruby\_version

After the installation, we can list the available Ruby versions we have installed by typing:

    rvm list

We can switch between the Ruby versions by typing:

    rvm use ruby\_version

We can use various Rails versions with each Ruby by creating `gemsets` and then installing Rails within those using the normal `gem` commands:

    rvm gemset create gemset\_name # create a gemset rvm ruby\_version@gemset\_name # specify Ruby version and our new gemset gem install rails -v rails\_version # install specific Rails version

The gemsets allow us to have self-contained environments for gems and allow us to have multiple environments for each version of Ruby that we install.

## Learning More

We have covered the basics of how to install `rvm` and Ruby on Rails here, but there is a lot more to learn about `rvm`. Check out our article on [how to use rvm to manage your Ruby environments](https://digitalocean.com/community/articles/how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps) to learn more about working with rvm.

By Justin Ellingwood
