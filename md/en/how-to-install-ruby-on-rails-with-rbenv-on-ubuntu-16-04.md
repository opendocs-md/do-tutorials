---
author: Lisa Tagliaferri
date: 2016-08-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-16-04
---

# How To Install Ruby on Rails with rbenv on Ubuntu 16.04

## Introduction

Ruby on Rails is one of the most popular application stacks for developers looking to create sites and web apps. The Ruby programming language, combined with the Rails development framework, makes app development simple.

You can easily install Ruby and Rails with the command-line tool **rbenv**. Using rbenv will provide you with a solid environment for developing your Ruby on Rails applications as it will let you easily switch Ruby versions, keeping your entire team on the same version. The project repository is located on [GitHub](https://github.com/rbenv/rbenv).

rbenv provides support for specifying application-specific versions of Ruby, lets you change the global Ruby for each user, and allows you to use an environment variable to override the Ruby version.

This tutorial will take you through the Ruby and Rails installation process via rbenv.

## Prerequisites

To follow this tutorial, you need:

- One Ubuntu 16.04 server with a [non-root user](initial-server-setup-with-ubuntu-16-04).
- Node.js installed using the official PPA, as explained in [How To Install Node.js on Ubuntu 16.04](how-to-install-node-js-on-ubuntu-16-04). A few Rails features, such as the Asset Pipeline, depend on a JavaScript Runtime. Node.js provides this functionality.

## Update and install dependencies

First, we should update `apt-get` since this is the first time we will be using `apt` in this session. This will ensure that the local package cache is updated.

    sudo apt-get update

Next, let’s install the dependencies required for rbenv and Ruby with `apt-get`:

    sudo apt-get install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev

Once we have all of the required system dependencies installed, we can move onto the installation of rbenv itself.

## Install rbenv

Now we are ready to install rbenv. Let’s clone the rbenv repository from git. You should complete these steps from the user account from which you plan to run Ruby.

    git clone https://github.com/rbenv/rbenv.git ~/.rbenv

From here, you should add `~/.rbenv/bin` to your `$PATH` so that you can use rbenv’s command line utility. Also adding `~/.rbenv/bin/rbenv init` to your `~/.basrc` file will let you load rbenv automatically.

    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc

Next, source rbenv by typing:

     source ~/.bashrc

You can check to see if rbenv was set up properly by using the `type` command, which will display more information about rbenv:

    type rbenv

Your terminal window should output the following:

    Outputrbenv is a function
    rbenv ()
    {
        local command;
        command="${1:-}";
        if ["$#" -gt 0]; then
            shift;
        fi;
        case "$command" in
            rehash | shell)
                eval "$(rbenv "sh-$command" "$@")"
            ;;
            *)
                command rbenv "$command" "$@"
            ;;
        esac
    }

In order to use the `rbenv install` command, which simplifies the installation process for new versions of Ruby, you should install [ruby-build](https://github.com/rbenv/ruby-build), which we will install as a plugin for rbenv through git:

    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

At this point, you should have both rbenv and ruby-build installed, and we can move on to installing Ruby.

## Install Ruby

With the ruby-build rbenv plugin now installed, we can install whatever versions of Ruby that we may need through a simple command. First, let’s list all the available versions of Ruby:

    rbenv install -l

The output of that command should be a long list of versions that you can choose to install.

We’ll now install a particular version of Ruby. It’s important to keep in mind that installing Ruby can be a lengthy process, so be prepared for the installation to take some time to complete.

As an example here, let’s install Ruby version 2.5.0, and once it’s done installing, we can set it as our default version with the `global` sub-command:

    rbenv install 2.5.0
    rbenv global 2.5.0

If you would like to install and use a different version, simply run the `rbenv` commands with a different version number, as in `rbenv install 2.3.0` and `rbenv global 2.3.0`.

Verify that Ruby was properly installed by checking your version number:

    ruby -v

If you installed version 2.5.0 of Ruby, your output to the above command should look something like this:

    Outputruby 2.5.0p0 (2017-12-25 revision 61468) [x86_64-linux]

You now have at least one version of Ruby installed and have set your default Ruby version. Next, we will set up gems and Rails.

## Working with Gems

Gems are packages that extend the functionality of Ruby. We will want to install Rails through the `gem` command.

So that the process of installing Rails is less lengthy, we will turn off local documentation for each gem we install. We will also install the bundler gem to manage application dependencies:

    echo "gem: --no-document" > ~/.gemrc
    gem install bundler

You can use the `gem env` command (the subcommand `env` is short for `environment`) to learn more about the environment and configuration of gems. You can check the location where gems are being installed by using the `home` argument, which will show the pathway to where gems are installed on your server.

    gem env home

Your output should look something like this, with sammy being the name of the user:

    /home/sammy/.rbenv/versions/2.5.0/lib/ruby/gems/2.5.0

Once we have gems set up, we can move on to install Rails.

## Install Rails

As the same user, you can install the most recent version of Rails with the `gem install` command:

    gem install rails

If you would like to install a specific version of Rails, you can list the valid versions of Rails by doing a search, which will output a long list of possible versions. We can then install a specific version, such as 4.2.7:

    gem search '^rails$' --all
    gem install rails -v 4.2.7

rbenv works by creating a directory of **shims** , which point to the files used by the Ruby version that’s currently enabled. Through the `rehash` sub-command, rbenv maintains shims in that directory to match every Ruby command across every installed version of Ruby on your server. Whenever you install a new version of Ruby or a gem that provides commands, like Rails does, you should run:

    rbenv rehash

Verify that Rails has been installed properly by printing its version, with this command:

    rails -v

If it installed properly, you will see the version of Rails that was installed:

    OutputRails 5.1.5

At this point, you can begin testing your Ruby on Rails installation and start to develop web applications.

## Updating rbenv

As we installed rbenv manually using git, we can upgrade our installation to the most recent version at any time:

    cd ~/.rbenv
    git pull

This will ensure that we are using the most up-to-date version of rbenv available.

## Uninstalling Ruby versions

As you download more versions of Ruby, you may accumulate more versions than you would like in your `~/.rbenv/versions` directory.

Use the ruby-build plugin to automate the removal process with the `uninstall` subcommand. For example, typing this will uninstall Ruby version 2.1.3:

    rbenv uninstall 2.1.3

With the `rbenv uninstall` command you can clean-up your versions of Ruby so that you do not have more installed than you are currently using.

## Conclusion

We have covered the basics of how to install rbenv and Ruby on Rails here so that you can use multiple Ruby environments. For your next steps, you can learn more about making those environments more robust. For more scalability, centralization, and control in your Ruby on Rails application, you may want to use it with [PostgreSQL](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04) or [MySQL](how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04) rather than its default sqlite3 database. As your needs grow, you can also learn how to [scale Ruby on Rails applications across multiple servers](how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1).
