---
author: Lisa Tagliaferri, Brian Hogan
date: 2018-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04
---

# How To Install Ruby on Rails with rbenv on Ubuntu 18.04

## Introduction

[Ruby on Rails](https://rubyonrails.org) is one of the most popular application stacks for developers looking to create sites and web apps. The Ruby programming language, combined with the Rails development framework, makes app development simple.

You can easily install Ruby and Rails with the command-line tool [rbenv](https://github.com/rbenv/rbenv). Using rbenv will provide you with a solid environment for developing your Ruby on Rails applications as it will let you easily switch Ruby versions, keeping your entire team on the same version.

rbenv provides support for specifying application-specific versions of Ruby, lets you change the global Ruby for each user, and allows you to use an environment variable to override the Ruby version.

This tutorial will take you through the Ruby and Rails installation process via rbenv.

## Prerequisites

To follow this tutorial, you need:

- One Ubuntu 18.04 server set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall.
- Node.js installed using the official PPA, as explained in [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04). A few Rails features, such as the Asset Pipeline, depend on a JavaScript Runtime. Node.js provides this functionality.

## Step 1 – Install rbenv and Dependencies

Ruby relies on several packages which you can install through your package manager. Once those are installed, you can install rbenv and use it to install Ruby,

First, update your package list:

    sudo apt update

Next, install the dependencies required to install Ruby:

    sudo apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev

Once the dependencies download, you can install rbenv itself. Clone the rbenv repository from GitHub into the directory `~/.rbenv`:

    git clone https://github.com/rbenv/rbenv.git ~/.rbenv

Next, add `~/.rbenv/bin` to your `$PATH` so that you can use the `rbenv` command line utility. Do this by altering your `~/.bashrc` file so that it affects future login sessions:

    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc

Then add the command `eval "$(rbenv init -)"` to your `~/.bashrc` file so rbenv loads automatically:

    echo 'eval "$(rbenv init -)"' >> ~/.bashrc

Next, apply the changes you made to your `~/.bashrc` file to your current shell session:

    source ~/.bashrc

Verify that rbenv is set up properly by using the `type` command, which will display more information about the `rbenv` command:

    type rbenv

Your terminal window will display the following:

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

Next, install the [ruby-build](https://github.com/rbenv/ruby-build), plugin. This plugin adds the`rbenv install` command, which simplifies the installation process for new versions of Ruby:

    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

At this point, you have both rbenv and ruby-build installed. Let’s install Ruby next.

## Step 2 – Installing Ruby with ruby-build

With the `ruby-build` plugin now installed, you can install versions of Ruby y may need through a simple command. First, let’s list all the available versions of Ruby:

    rbenv install -l

The output of that command should be a long list of versions that you can choose to install.

Let’s install Ruby 2.5.1:

    rbenv install 2.5.1

Installing Ruby can be a lengthy process, so be prepared for the installation to take some time to complete.

Once it’s done installing, set it as our default version of Ruby with the `global` sub-command:

    rbenv global 2.5.1

Verify that Ruby was properly installed by checking its version number:

    ruby -v

If you installed version 2.5.1 of Ruby, your output to the above command should look something like this:

    Outputruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux]

To install and use a different version of Ruby, run the `rbenv` commands with a different version number, as in `rbenv install 2.3.0` and `rbenv global 2.3.0`.

You now have at least one version of Ruby installed and have set your default Ruby version. Next, we will set up gems and Rails.

## Step 3 – Working with Gems

Gems are the way Ruby libraries are distributed. You use the `gem` command to manage these gems. We’ll use this command to install Rails.

When you install a gem, the installation process generates local documentation. This can add a significant amount of time to each gem’s installation process, so turn off local documentation generation by creating a file called `~/.gemrc` which contains a configuration setting to turn off this feature:

    echo "gem: --no-document" > ~/.gemrc

[Bundler](https://bundler.io/) is a tool that manages gem dependencies for projects. Install the Bundler gem next. as Rails depends on it.

    gem install bundler

You’ll see output like this:

    OutputFetching: bundler-1.16.2.gem (100%)
    Successfully installed bundler-1.16.2
    1 gem installed

You can use the `gem env` command (the subcommand `env` is short for `environment`) to learn more about the environment and configuration of gems. You can see where gems are being installed by using the `home` argument, like this:

    gem env home

You’ll see output similar to this:

    /home/sammy/.rbenv/versions/2.5.1/lib/ruby/gems/2.5.0

Once you have gems set up, you can install Rails.

## Step 4 – Installing Rails

To install Rails, use the `gem install` command along with the `-v` flag to specify the version. For this tutorial, we will use version `5.2.0`:

    gem install rails -v 5.2.0

The `gem` command installs the gem you specify, as well as every dependency. Rails is a complex web development framework and has many dependencies, so the process will take some time to complete. Eventually you’ll see a message stating that Rails is installed, along with its dependencies:

    Output...
    Successfully installed rails-5.2.0
    38 gems installed

**Note** : If you would like to install a different version of Rails, you can list the valid versions of Rails by doing a search, which will output a long list of possible versions. We can then install a specific version, such as 4.2.7:

    gem search '^rails$' --all
    gem install rails -v 4.2.7

If you would like to install the latest version of Rails, run the command without a version specified:

    gem install rails

rbenv works by creating a directory of **shims** , which point to the files used by the Ruby version that’s currently enabled. Through the `rehash` sub-command, rbenv maintains shims in that directory to match every Ruby command across every installed version of Ruby on your server. Whenever you install a new version of Ruby or a gem that provides commands, like Rails does, you should run:

    rbenv rehash

Verify that Rails has been installed properly by printing its version, with this command:

    rails -v

If it installed properly, you will see the version of Rails that was installed:

    OutputRails 5.2.0

At this point, you can begin testing your Ruby on Rails installation and start to develop web applications. Let’s look at keeping rbenv up to date.

## Step 5 – Updating rbenv

Since you installed rbenv manually using Git, you can upgrade your installation to the most recent version at any time by using the `git pull` command in the `~/.rbenv` directory:

    cd ~/.rbenv
    git pull

This will ensure that we are using the most up-to-date version of rbenv available.

## Step 6 – Uninstalling Ruby versions

As you download additional versions of Ruby, you may accumulate more versions than you would like in your `~/.rbenv/versions` directory. Use the `ruby-build`plugin ’s’ `uninstall` subcommand to remove these previous versions.

For example, typing this will uninstall Ruby version 2.1.3:

    rbenv uninstall 2.1.3

With the `rbenv uninstall` command you can clean up old versions of Ruby so that you do not have more installed than you are currently using.

## Step 7 – Uninstalling rbenv

If you’ve decided you no longer want to use rbenv, you can remove it from your system.

To do this, first open your `~/.bashrc` file in your editor:

    nano ~/.bashrc

Find and remove the following two lines from the file:

~/.bashrc

    ...
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"

Save the file and exit the editor.

Then remove rbenv and all installed Ruby versions with this command:

     rm -rf `rbenv root`

Log out and back in to apply the changes to your shell.

## Conclusion

In this tutorial you installed `rbenv` and Ruby on Rails. From here, you can learn more about making those environments more robust.

Explore how to use Ruby on Rails with [PostgreSQL](how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04) or [MySQL](how-to-use-mysql-with-your-ruby-on-rails-application-on-ubuntu-14-04) rather than its default sqlite3 database, which provide more scalability, centralization, and stability for your applications. As your needs grow, you can also learn how to [scale Ruby on Rails applications across multiple servers](how-to-scale-ruby-on-rails-applications-across-multiple-droplets-part-1).
