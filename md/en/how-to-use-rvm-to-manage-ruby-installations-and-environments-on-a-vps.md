---
author: Justin Ellingwood
date: 2013-10-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps
---

# How To Use RVM to Manage Ruby Installations and Environments on a VPS

## Introduction

* * *

Ruby on Rails, or RoR, is a popular development framework for the Ruby programming language that allows you to easily get your application up and running with minimal hassle.

Developing applications often times requires that you emulate different environments. Different versions of Ruby may be necessary for different projects. With conventional installations, this would impede your ability to be flexible.

Luckily, the Ruby Version Manager, known more widely as RVM, allows you to easily install multiple, contained versions of Ruby and easily switch between them.

In other articles, we covered how to install RVM on various platforms:

- [Ubuntu](https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-ubuntu-12-04-lts-precise-pangolin-with-rvm)
- [CentOS](https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-centos-6-with-rvm)
- [Arch Linux](https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-arch-linux-with-rvm)
- [Debian](https://www.digitalocean.com/community/articles/how-to-install-ruby-on-rails-on-an-debian-7-0-wheezy-vps-using-rvm)

This article will assume that you’ve already installed RVM. We will be discussing the basic usage of this utility and how you can properly manage your Ruby environments.

## Basic Syntax

* * *

If you’ve already installed RVM, you should have the `rvm` command available to you. This is the way we call RVM.

The basic syntax of the command is:

    rvm command\_options command ruby\_to\_act\_on

There are also RVM flags that can alter the behavior of RVM, which are given in a similar way to command options.

You can get a list of the available commands by typing:

    rvm help

If you would like help on a specific command, you can reference it after “help” to get more detailed instruction:

    rvm help command

### How To Enable Tab Completion

* * *

We will enable RVM tab completion by putting the following line in our `.bashrc` file:

    [[-r $rvm_path/scripts/completion]] && . $rvm_path/scripts/completion

This will allow us to complete RVM commands by typing the TAB key twice after entering part of the command. For instance, we can type:

    rvm inst

At this point, we can hit TAB twice, and it will complete to:

    rvm install

We can then finish typing parameters.

Keep in mind that this also works with arguments. If you are switching to another Ruby version, you can type:

    rvm use

After you type a space and then TAB twice, you will be presented with a list of the available Ruby versions.

## How To Install and Uninstall Rubies

* * *

We can list all of the Rubies we have available to install with this command:

    rvm list known

Once you’ve selected the Ruby you wish to install, you can issue this command:

    rvm install ruby\_version

If you ever wish to uninstall a version of Ruby, you can do this simply by typing:

    rvm uninstall ruby\_version

### How To Switch Rubies

* * *

Once you’ve installed a few versions of Ruby, you can list them with this command:

    rvm list

* * *

    rvm rubies
    
    =* ruby-2.0.0-p247 [x86_64]
    
    # => - current
    # =* - current && default
    # * - default

As you can see, RVM gives you a handy guide to tell you which are the current and the default Ruby versions. In this case, they are one and the same.

Switch to a different Ruby by typing:

    rvm use ruby\_version

Set a default Ruby to use by using the `--default` flag:

    rvm --default use ruby\_version

To switch to the default Ruby, type:

    rvm default

In order to use the version of Ruby installed on the system (not through RVM), you can specify:

    rvm use system

## How To Use Gemsets

* * *

One common way to distribute code in Ruby is to use a format called `gems`. Gems can be installed to extend the capabilities of the core Ruby distribution, and there are often gems that are required to be installed to get certain programs to function correctly.

In keeping with RVM’s mission of providing contained Ruby environments, it is also possible to install gems that are only associated with a single Ruby installation. RVM calls this functionality **gemsets**.

This means that you can have two different versions of the same gem, or you can make gems unaware of other gems on the system.

To see the available gemsets for the current Ruby, you can type:

    rvm gemset list

If you have more than one Ruby version installed, you can see all of the gemsets by typing:

    rvm gemset list_all

By default, you should have two gemsets configured:

- **default** : The gemset that is applied if no other gemset is specified.

- **global** : This gemset is inherited by every other gemset that is used. This set generally does not need to be selected because it will be included automatically. You should install shared gems here.

You can create another gemset easily. We will create a gemset called “test\_project” to demonstrate how this works:

    rvm gemset create test_project

If you would rather copy a current gemset to a new gemset to run some tests, you can issue this command:

    rvm gemset copy default test_project

We can change the gemset we wish to use:

    rvm gemset use test_project

We can also change the Ruby version and gemset at one time. This is done giving the Ruby version, followed by the “@” character, and then specifying the gemset:

    rvm use 2.0.0@test_project

Now, we can install a Tic-Tac-Toe gem by issuing this command:

    gem install tictactoe -v 0.0.4

We can now change to our default gemset and install an earlier version of the same gem:

    rvm gemset use default
    gem install tictactoe -v 0.0.3

We now have two separate versions of the Tic-Tac-Toe gem installed and we can test them independently by switching the gemset that we are using.

If you’re confused about which gemset you’re currently working with, this command will print the current active gemset:

    rvm gemset name

When you’ve finished using a gemset, perhaps because your testing is complete, you can get rid of it by issuing the following command:

    rvm gemset delete test_project

## How To Configure Defaults

* * *

RVM can be configured with defaults on a few different levels. RVM keeps its defaults in a file here:

    nano ~/.rvm/config/db

You can see what RVM will use if you do not give it specific directions to do otherwise.

**Note: You should not edit this file. It is overwritten when RVM is upgraded.**

If you would like to override these settings, you can do so in a separate file at:

    nano ~/.rvm/user/db

For ease of use, you can copy parameters out of the `config/db` file and place it in the `user/db` file to modify easily.

## How To Automate Your Environment

* * *

You can create project-specific configurations that specify what Ruby version and gemset to use by creating an `.rvmrc` file inside of your project directory.

This eliminates the need to manually keep track of the ruby version you have active.

To create a project-specific environment, just create an `.rvmrc` file in the project’s top-level directory:

    nano .rvmrc

Inside, you just need to type “rvm”, followed by the Ruby version, the “@” symbol, and then the gemset:

    rvm ruby\_version@gemset

That’s all you need. You may have to accept the configuration the first time you enter the directory.

Ensure that you have created the gemset and installed the Ruby version you are specifying, or else you will be prompted to install and create the necessary components whenever you switch into that directory.

You can also include any kind of project-specific RVM configuration within this same file.

## How To Update RVM

* * *

When RVM comes out with a new version, you can update your installation easy from within the utility.

Simply issue the following command:

    rvm get stable

RVM will then fetch and install the newest version and then reload the environment. This is where your configurations would be wiped out if you placed them in `config/db` instead of `user/db`.

If you would like to upgrade to the latest available version (not necessarily stable), you can type:

    rvm get head

## Conclusion

* * *

As you can see, RVM is a versatile tool that can be used to manage projects and entire Ruby environments. You can use RVM to configure development conditions, server installations, and even to deploy your application.

If you work with Ruby on a regular basis, learning how to craft individualized Ruby environments with RVM is well worth it. It can help speed up your initial set up and can help you avoid making costly mistakes.

By Justin Ellingwood
