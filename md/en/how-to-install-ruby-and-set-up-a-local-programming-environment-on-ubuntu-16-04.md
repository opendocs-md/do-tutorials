---
author: Brian Hogan
date: 2017-06-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-and-set-up-a-local-programming-environment-on-ubuntu-16-04
---

# How To Install Ruby and Set Up a Local Programming Environment on Ubuntu 16.04

## Introduction

[Ruby](http://ruby-lang.org) is a dynamic programming language you can use to write anything from simple scripts to games and web applications. It was first released in Japan in 1993, but gained popularity in 2005 as a language for server-side web development. Ruby is designed to be easy to use and fun for beginners, but powerful enough to create complex systems. It’s a great choice for beginners and experienced developers alike.

While there are many ways to install Ruby on Ubuntu, the easiest method is to use [RVM](http://rvm.io), the Ruby Version Manager. It downloads the latest version of Ruby and installs all of the prerequisite libraries.

In this tutorial, you’ll set up a Ruby programming environment on your local Linux machine via the command line. Then you’ll test your environment out by writing a simple Ruby program.

This tutorial will explicitly cover the installation procedures for Ubuntu 16.04, but the general principles apply to any other distribution of Debian Linux.

## Prerequisites

You will need a computer with Ubuntu 16.04 installed, as well as have administrative access to that machine and an internet connection.

## Step 1 — Using the Terminal

You’ll use the command line to install Ruby. The command line is a non-graphical way to interact with your computer. Instead of clicking buttons with your mouse, you’ll type commands as text and receive text-based feedback. The command line, also known as a shell, lets you automate many tasks you do on your computer daily, and is an essential tool for software developers.

On Ubuntu 16.04, you can find the Terminal application by clicking on the Ubuntu icon in the upper-left hand corner of your screen and typing “terminal” into the search bar. Click on the Terminal application icon to open it. Alternatively, you can hit the `CTRL`, `ALT`, and `T` keys on your keyboard at the same time to open the Terminal application automatically.

![Ubuntu Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/UbuntuDebianSetUp/UbuntuSetUp.png)

If you’d like to get comfortable using the command-line interface, take a look at [An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal).

Now that you have the Terminal running, let’s install RVM, which we’ll use to install Ruby and all of its prerequisites.

## Step 2 — Installing RVM and Ruby

RVM automates the process of setting up a Ruby environment on your Ubuntu system. Let’s get it installed so we can use it to install Ruby.

The quickest way to install Ruby with RVM is to run the installation script hosted on the RVM web site.

First, use the `gpg` command to contact a public key server and request the RVM project’s key which is used to sign each RVM release. This lets you verify the legitimacy of the RVM release you’ll download. From your home directory, execute the following command:

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

We’ll use `curl` to download the RVM installation script. Install `curl` if it’s not already installed.

    sudo apt-get install curl

This will prompt you for your password to install the program. However, when you type your password, your keystrokes will not display in the Terminal window. This is a security measure and is something you’ll see often when prompted for passwords on the command line. Even though you don’t see them, your keystrokes are being recorded by the system, so press the `ENTER` key once you’ve entered your password, and the program will install.

Next, use the curl command to download the RVM installation script from the project’s website. The backslash that leads the command ensures that we are using the regular curl command and not any altered, aliased version.

    \curl -sSL https://get.rvm.io -o rvm.sh

Let’s walk through the flags that are associated with the `curl` command:

- The `-s` or `--silent` flag mutes `curl` so that it does not show the progress meter.
- The `-S` or `--show-error` flag ensures that `curl` shows an error message if it fails.
- The `-L` or `--location` flag will tell `curl` to handle redirects. If the server reports that the requested page has moved to a different location, it’ll automatically execute the request again using the new location.

Once it is downloaded, if you would like to audit the contents of the script before applying it, run:

    less rvm.sh

Use the arrow keys to scroll through the file. Use the `q` key to exit and return to your prompt.

Once you’re comfortable with the script’s contents, execute this command to install the latest stable release of RVM:

    cat rvm.sh | bash -s stable

The script creates a new directory in your home directory called `.rvm`. This is where Ruby and all of its related components will be installed, along with the `rvm` executable program you use to install Ruby. The installation process modifies your `.bashrc` file to add the `.rvm/bin` folder to your `PATH` environment variable so you can run the `rvm` command easily.

However, the `rvm` command won’t be accessible in your current session. So execute this command to fix that:

    source ~/.rvm/scripts/rvm

Now use the `rvm` command to install the latest version of Ruby:

    rvm install ruby --default

This process will download and install Ruby and its components, and make this version of Ruby the default version your system will use. This will avoid conflicts if you have a version of Ruby already installed.

If you are missing some important prerequisites, the installer will fetch those prerequisites and install them. It may ask you for your password.

    OutputSearching for binary rubies, this might take some time.
    Found remote file https://rvm_io.global.ssl.fastly.net/binaries/ubuntu/16.04/x86_64/ruby-2.4.0.tar.bz2
    Checking requirements for ubuntu.
    Installing requirements for ubuntu.
    Updating system....
    Installing required packages: gawk, libssl-dev, zlib1g-dev, libyaml-dev, libsqlite3-dev, sqlite3, autoconf, libgmp-dev, libgdbm-dev, libncurses5-dev, automake, libtool, bison, libffi-dev, libgmp-dev, libreadline6-dev..................
    Requirements installation successful.

Once the prerequisites are satisfied, RVM will download and install Ruby:

    Outputruby-2.4.0 - #configure
    ruby-2.4.0 - #download
      % Total % Received % Xferd Average Speed Time Time Time Current
    Dload Upload Total Spent Left Speed
    100 16.4M 100 16.4M 0 0 4828k 0 0:00:03 0:00:03 --:--:-- 4829k
    ruby-2.4.0 - #validate archive
    ruby-2.4.0 - #extract
    ruby-2.4.0 - #validate binary
    ruby-2.4.0 - #setup
    ruby-2.4.0 - #gemset created /home/brian/.rvm/gems/ruby-2.4.0@global
    ruby-2.4.0 - #importing gemset /home/brian/.rvm/gemsets/global.gems..............................
    ruby-2.4.0 - #generating global wrappers........
    ruby-2.4.0 - #gemset created /home/brian/.rvm/gems/ruby-2.4.0
    ruby-2.4.0 - #importing gemsetfile /home/brian/.rvm/gemsets/default.gems evaluated to empty gem list
    ruby-2.4.0 - #generating default wrappers........

Once the script completes, the most recent version of Ruby is installed.

In addition to Ruby, RVM installs a few related tools, including `irb`, the interactive Ruby console, `rake`, a program that can run automation scripts, and `gem`, which makes it easy to install and update Ruby libraries you might use in your own projects.

To check the version of Ruby that you installed, type this command:

    ruby -v

This will output the specific version of Ruby:

    Outputruby 2.4.0p0 (2016-12-24 revision 57164) [x86_64-linux]

Before we can take Ruby out for a spin, let’s make one more modification to our system. In order for RVM to automatically use its version of Ruby whenever you open a new Terminal window, your Terminal has to open a login shell, as RVM modifies the `.bash_profile` file, which is only invoked on login shells. On Ubuntu, the default Terminal opens an interactive shell instead, which doesn’t invoke this file. To change this, select the **Edit** menu in the Terminal, choose **Profile Preferences** , select the **Command** tab, and check the box next to **Run command as a login shell**. If you’re uncomfortable making this change, just run the command `source ~/.rvm/scripts/rvm` every time you launch a new Terminal session.

Now that Ruby is installed, let’s write a program to ensure everything works.

## Step 3 — Creating a Simple Program

Let’s create a simple “Hello, World” program. This will make sure that our environment is working and gets you comfortable creating and running a Ruby program.

To do this, create a new file called `hello.rb` using `nano`:

    nano hello.rb

Type the following program into the editor:

hello.rb

    puts "Hello, World!"

Exit the editor by pressing `CTRL+X`. Press `Y` when prompted to save the file.

Now run the program:

    ruby hello.rb

The program executes and displays its output to the screen:

    OutputHello, World!

This simple program proves that you have a working development environment. You can use this environment to continue exploring Ruby and build larger, more interesting projects.

## Conclusion

With your local machine ready for software development, you can continue to learn more about coding in Ruby by reading the tutorial [Creating Your First Ruby Program](how-to-write-your-first-ruby-program).
