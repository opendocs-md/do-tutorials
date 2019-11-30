---
author: Brian Hogan
date: 2017-06-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-and-set-up-a-local-programming-environment-on-macos
---

# How To Install Ruby and Set Up a Local Programming Environment on macOS

## Introduction

[Ruby](http://ruby-lang.org) is a dynamic programming language you can use to write anything from simple scripts to games and web applications. It was first released in Japan in 1993, but gained popularity in 2005 as a language for server-side web development. Ruby is designed to be easy to use and fun for beginners, but powerful enough to create complex systems. It’s a great choice for beginners and experienced developers alike.

Ruby is already included in a default macOS installation, although it won’t be the most recent version. You may run into compatibility issues when following tutorials or attempting to use other projects if you use it.

In this tutorial, you’ll set up a Ruby programming environment on your local macOS machine using [Homebrew](http://brew.sh), and you’ll test your environment out by writing a simple Ruby program.

## Prerequisites

You will need a macOS computer running El Capitan or higher with administrative access and an internet connection.

## Step 1 — Using the macOS Terminal

You’ll use the command line to install Ruby and run various commands related to developing Ruby applications. The command line is a non-graphical way to interact with your computer. Instead of clicking buttons with your mouse, you’ll type commands as text and receive text-based feedback. The command line, also known as a shell, lets you automate many tasks you do on your computer daily, and is an essential tool for software developers.

To access the command line interface, you’ll use the Terminal application provided by macOS. Like any other application, you can find it by going into Finder, navigating to the Applications folder, and then into the Utilities folder. From here, double-click the Terminal application to open it up. Alternatively, you can use Spotlight by holding down the `COMMAND` key and pressing `SPACE` to find Terminal by typing it out in the box that appears.

![macOS Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/OSXSetUp/MacOSXSetUp.png)

If you’d like to get comfortable using the command line, take a look at [An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal). The command line interface on macOS is very similar, and the concepts in that tutorial are directly applicable.

Now that you have the Terminal running, let’s install some prerequisites we’ll need for Ruby.

## Step 2 — Installing Xcode’s Command Line Tools

Xcode is an integrated development environment (IDE) that is comprised of software development tools for macOS. You won’t need Xcode to write Ruby programs, but Ruby and some of its components will rely on Xcode’s Command Line Tools package.

Execute this command in the Terminal to download and install these components:

    xcode-select --install

You’ll be prompted to start the installation, and then prompted again to accept a software license. Then the tools will download and install automatically.

We’re now ready to install the package manager Homebrew, which will let us install the latest version of Ruby.

## Step 3 — Installing and Setting Up Homebrew

While the command line interface on macOS has a lot of the functionality you’d find in Linux and other Unix systems, it does not ship with a good package manager. A _package manager_ is a collection of software tools that work to automate software installations, configurations, and upgrades. They keep the software they install in a central location and can maintain all software packages on the system in formats that are commonly used. [Homebrew](http://brew.sh) is a free and open-source software package managing system that simplifies the installation of software on macOS. We’ll use Homebrew to install the most recent version of Ruby, and then configure our system to use this version instead of the version of Ruby that macOS uses by default.

To install Homebrew, type this command into your Terminal window:

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Homebrew and its installation script are written in Ruby, and we’ll use the default Ruby interpreter that comes with macOS to install it. The command uses `curl` to download the Homebrew installation script from Homebrew’s Git repository on GitHub.

Let’s walk through the flags that are associated with the `curl` command:

- The -`f` or `--fail` flag tells the Terminal window to give no HTML document output on server errors.
- The `-s` or `--silent` flag mutes `curl` so that it does not show the progress meter, and combined with the `-S` or `--show-error` flag it will ensure that `curl` shows an error message if it fails.
- The `-L` or `--location` flag will tell `curl` to handle redirects. If the server reports that the requested page has moved to a different location, it’ll automatically execute the request again using the new location.

Once `curl` downloads the script, it’s then executed by the Ruby interpreter, starting the Homebrew installation process.

The installation script will explain what it will do and will prompt you to confirm that you want to do it. This lets you know exactly what Homebrew is going to do to your system before you let it proceed. It also ensures you have the prerequisites in place before it continues.

You’ll be prompted to enter your password during the process. However, when you type your password, your keystrokes will not display in the Terminal window. This is a security measure and is something you’ll see often when prompted for passwords on the command line. Even though you don’t see them, your keystrokes are being recorded by the system, so press the `RETURN` key once you’ve entered your password.

Press the letter `y` for “yes” whenever you are prompted to confirm the installation.

Once the installation process is complete, we’ll put the directory Homebrew uses to store its executables at the front of the `PATH` environment variable. This ensures that Homebrew installations will be called over the tools that macOS includes. Specifically, when we install Ruby with Homebrew, this change makes sure our system will run the version we installed with Homebrew instead of the one macOS includes.

Create or open the file `~/.bash_profile` with the text editor **nano** using the `nano` command:

    nano ~/.bash_profile

Once the file opens up in the Terminal window, add the following lines to the end of the file:

~/.bash\_profile

    # Add Homebrew's executable directory to the front of the PATH
    export PATH=/usr/local/bin:$PATH

The first line is a comment that will help you remember what this does if you open this file in the future.

To save your changes, hold down the `CTRL` key and the letter `O`, and when prompted, press the `RETURN` key. Then exit the editor by holding the `CTRL` key and pressing `X`. This will return you to your Terminal prompt.

To activate these changes, execute this command:

    source ~/.bash_profile

Once you have done this, the changes you have made to the `PATH` environment variable will take effect. They’ll be set correctly when you log in again in the future, as the `.bash_profile` file is executed automatically when you open the Terminal app.

Now let’s verify that Homebrew is set up correctly. Execute this command:

    brew doctor

If no updates are required at this time, you’ll see this in your Terminal:

    OutputYour system is ready to brew.

Otherwise, you may get a warning to run another command such as `brew update` to ensure that your installation of Homebrew is up to date.

Now that Homebrew is installed, you can install Ruby.

## Step 4 — Installing Ruby

With Homebrew installed, you can easily install a wide range of software and developer tools. We’ll use it to install Ruby and its dependencies.

You can use Homebrew to search for everything you can install with the `brew search` command, but to provide us with a shorter list, let’s instead search for packages related to Ruby:

    brew search ruby

You’ll see a list of packages you can install, like this:

    Outputchruby
    chruby-fish
    imessage-ruby
    jruby
    mruby
    rbenv-bundler-ruby-version
    ruby
    ruby-build
    ruby-completion
    ruby-install
    ruby@1.8
    ruby@1.9
    ruby@2.0
    ruby@2.1
    ruby@2.2
    ruby@2.3
    homebrew/portable/portable-ruby
    homebrew/portable/portable-ruby@2.2

Ruby itself will be among the items on the list. Let’s go ahead and install it:

    brew install ruby

You’ll see output similar to the following in your Terminal. Homebrew will install many dependencies, but will eventually download and install Ruby itself:

    Output==> Installing dependencies for ruby: readline, libyaml, openssl
    
    ...
    
    ==> Summary
    🍺 /usr/local/Cellar/ruby/2.4.1_1: 1,191 files, 15.5MB
    

In addition to Ruby, Homebrew installs a few related tools, including `irb`, the interactive Ruby console, `rake`, a program that can run automation scripts called Rake tasks, and `gem`, which makes it easy to install and update Ruby libraries you might use in your own projects.

To check the version of Ruby that you installed, type

    ruby -v

This will output the specific version of Ruby that is currently installed, which will by default be the most up-to-date stable version of Ruby that is available.

    Outputruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin15]

To update your version of Ruby, you can first update Homebrew to get the latest list of packages, and then upgrade Ruby:

    brew update
    brew upgrade ruby

Now that Ruby is installed, let’s write a program to ensure everything works.

## Step 5 — Creating a Simple Program

Let’s create a simple “Hello, World” program. This will make sure that our environment is working and gets you comfortable creating and running a Ruby program.

To do this, create a new file called `hello.rb` using `nano`:

    nano hello.rb

Type the following code into the file:

hello.rb

    puts "Hello, World!"

Exit the editor by pressing `CTRL+X`. Then press `y` when prompted to save the file. You’ll be returned to your prompt.

Now run the program with the following command:

    ruby hello.rb

The program executes and displays its output to the screen:

    OutputHello, World!

This simple program proves that you have a working development environment. You can use this environment to continue exploring Ruby and build larger, more interesting projects.

## Conclusion

With your local machine ready for software development, you can continue to learn more about coding in Ruby by reading the tutorial [Creating Your First Ruby Program](how-to-write-your-first-ruby-program).
