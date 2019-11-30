---
author: Timothy Nolan
date: 2019-07-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-macos
---

# How To Install Ruby on Rails with rbenv on macOS

## Introduction

[Ruby on Rails](https://rubyonrails.org) is a popular application stack for developers looking to create sites and web apps. The [Ruby programming language](https://www.ruby-lang.org/en/), combined with the Rails development framework, makes app development quick and efficient.

One way to install Ruby and Rails is with the command-line tool [rbenv](https://github.com/rbenv/rbenv). Using rbenv will provide you with a well-controlled and robust environment for developing your Ruby on Rails applications, allowing you to easily switch the version of Ruby for your entire team when needed.

rbenv provides support for specifying application-specific versions of Ruby, lets you change the global Ruby for each user, and allows you to use an environment variable to override the Ruby version.

In this tutorial, you will use rbenv to install and set up Ruby on Rails on your local macOS machine.

## Prerequisites

To follow this tutorial, you will need:

- One computer or virtual machine with macOS installed, with administrative access to that machine and an internet connection. This tutorial has been tested on [macOS 10.14 Mojave](https://www.apple.com/macos/mojave/).
- Node.js installed on your macOS machine, as explained in [How to Install Node.js and Create a Local Development Environment on macOS](how-to-install-node-js-and-create-a-local-development-environment-on-macos). A few Rails features, such as the [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html), depend on a JavaScript Runtime. Node.js provides this functionality.

## Step 1 — Installing rbenv

In this step, you will install rbenv and make sure that it starts automatically at boot. To do this on macOS, this tutorial will use the package manager [Homebrew](https://brew.sh/).

To download the `rbenv` package with Homebrew, run the following command:

    brew install rbenv

This will install rbenv and the [ruby-build](https://github.com/rbenv/ruby-build) plugin. This plugin adds the`rbenv install` command, which streamlines the installation process for new versions of Ruby.

Next, you’ll add the command `eval "$(rbenv init -)"` to your `~/.bash_profile` file to make rbenv load automatically when you open up the Terminal. To do this, open your `.bash_profile` in your favorite text editor:

    nano .bash_profile

Add the following line to the file:

~/.bash\_profile

    eval "$(rbenv init -)"

Save and quit the file.

Next, apply the changes you made to your `~/.bash_profile` file to your current shell session:

    source ~/.bash_profile

To verify that rbenv is set up properly, use the `type` command, which will display more information about the `rbenv` command:

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

At this point, you have both rbenv and ruby-build installed on your machine. This will allow you to install Ruby from the command line in the next step.

## Step 2 — Installing Ruby

With the ruby-build plugin now installed, you can install any version of Ruby you may need through a single command. In this step, you will choose a version of Ruby, install it on your machine, and then verify the installation.

First, use the `-l` flag to list all the available versions of Ruby:

    rbenv install -l

The output of that command will be a long list of versions that you can choose to install.

For this tutorial, install Ruby 2.6.3:

    rbenv install 2.6.3

Installing Ruby can be a lengthy process, so be prepared for the installation to take some time to complete.

Once it’s done installing, set it as your default version of Ruby with the `global` sub-command:

    rbenv global 2.6.3

Verify that Ruby was properly installed by checking its version number:

    ruby -v

Your output will look something like this:

    Outputruby 2.6.3p62 (2019-04-16 revision 67580) [x86_64-darwin18]

To install and use a different version of Ruby, run the `rbenv` commands with a different version number, such as `rbenv install 2.3.0` and `rbenv global 2.3.0`.

You now have one version of Ruby installed and have set your default Ruby version. Next, you will set yourself up to work with Ruby packages and libraries, or _gems_, which will then allow you to install Rails.

## Step 3 — Working with Gems

_Gems_ are packages of Ruby libraries and programs that can be distributed throughout the Ruby ecosystem. You use the `gem` command to manage these gems. In this step, you will configure the `gem` command to prepare for the Rails installation.

When you install a gem, the installation process generates local documentation. This can add a significant amount of time to each gem’s installation process, so turn off local documentation generation by creating a file called `~/.gemrc` which contains a configuration setting to turn off this feature:

    echo "gem: --no-document" > ~/.gemrc

With that done, use the `gem` command to install [Bundler](https://bundler.io/), a tool that manages gem dependencies for projects. This is needed for Rails to work correctly:

    gem install bundler

You’ll see output like this:

    OutputFetching: bundler-2.0.2.gem
    Successfully installed bundler-2.0.2
    1 gem installed

You can use the `gem env` command to learn more about the environment and configuration of gems. To see the location of installed gems, use the `home` argument, like this:

    gem env home

You’ll see output similar to this:

    /Users/sammy/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0

Now that you have set up and explored your gem workflow, you are free to install Rails.

## Step 4 — Installing Rails

To install Rails, use the `gem install` command along with the `-v` flag to specify the version. For this tutorial, we will use version `5.2.3`:

    gem install rails -v 5.2.3

The `gem` command installs the gem you specify, as well as every dependency. Rails is a complex web development framework and has many dependencies, so the process will take some time to complete. Eventually you’ll see a message stating that Rails is installed, along with its dependencies:

    Output...
    Successfully installed rails-5.2.3
    38 gems installed

**Note** : If you would like to install a different version of Rails, you can list the valid versions of Rails by doing a search, which will output a long list of possible versions. We can then install a specific version, such as 4.2.7:

    gem search '^rails$' --all
    gem install rails -v 4.2.7

If you would like to install the latest version of Rails, run the command without a version specified:

    gem install rails

rbenv works by creating a directory of _shims_, or libraries that intercept calls and change or redirect them. In this case, shims point Ruby commands to the files used by the Ruby version that’s currently enabled. Through the `rehash` sub-command, rbenv maintains shims in that directory to match every Ruby command across every installed version of Ruby on your server. Whenever you install a new version of Ruby or a gem that provides commands, such as Rails, you should use `rehash`.

To rehash the directory of shims, run the following command:

    rbenv rehash

Verify your installation of Rails by printing its version with this command:

    rails -v

You will see the version of Rails that was installed:

    OutputRails 5.2.3

With Rails successfully installed, you can begin testing your Ruby on Rails installation and start to develop web applications. In the next step, you will learn how to update and uninstall rbenv and Ruby.

## Step 5 — Updating and Uninstalling rbenv and Ruby

When maintaining projects, it is useful to know how to update and uninstall when the need arises. In this step, you will upgrade rbenv, then uninstall Ruby and rbenv from your machine.

You can upgrade rbenv and ruby-build using Homebrew by running the following command:

    brew upgrade rbenv ruby-build

If rbenv or ruby-build need to be updated, Homebrew will do it for you automatically. If your set up is already up to date, you will get output similar to the following:

    OutputError: rbenv 1.1.2 already installed
    Error: ruby-build 20190615 already installed

This will ensure that we are using the most up-to-date version of rbenv available.

As you download additional versions of Ruby, you may accumulate more versions than you would like in your `~/.rbenv/versions` directory. Using the ruby-build plugin’s `uninstall` subcommand, you can remove these previous versions.

For example, run the following to uninstall Ruby version 2.1.3:

    rbenv uninstall 2.1.3

With the `rbenv uninstall` command you can clean up old versions of Ruby so that you do not have more installed than you are currently using.

If you’ve decided you no longer want to use rbenv, you can remove it from your system.

To do this, first open your `~/.bash_profile` file in your editor:

    nano ~/.bash_profile

Find and remove the following line from the file to stop rbenv from starting when you open the Terminal:

~/.bash\_profile

    ...
    eval "$(rbenv init -)"

Once you have deleted this line, save the file and exit the editor.

Run the following command to apply the changes to your shell:

    source ~/.bash_profile

Next, remove rbenv and all installed Ruby versions with this command:

    rm -rf `rbenv root`

Finally, remove the rbenv package itself with Homebrew:

    brew uninstall rbenv

Check the rbenv version to make sure that it has been uninstalled:

    rbenv -v

You will get the following output:

    Output-bash: /usr/local/bin/rbenv: No such file or directory

This means that you have successfully removed rbenv from your machine.

## Conclusion

In this tutorial you installed Ruby on Rails with rbenv on macOS. From here, you can learn more about coding in Ruby with our [How To Code in Ruby](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-ruby) series. You can also explore how to use Ruby on Rails with [PostgreSQL](how-to-use-postgresql-with-your-ruby-on-rails-application-on-macos) rather than its default sqlite3 database, which provides more scalability, centralization, and stability for your applications.
