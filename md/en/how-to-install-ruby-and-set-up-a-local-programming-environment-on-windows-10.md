---
author: Brian Hogan
date: 2017-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ruby-and-set-up-a-local-programming-environment-on-windows-10
---

# How To Install Ruby and Set Up a Local Programming Environment on Windows 10

## Introduction

[Ruby](http://ruby-lang.org) is a dynamic programming language you can use to write anything from simple scripts to games and web applications. It was first released in Japan in 1993, but gained popularity in 2005 as a language for server-side web development. Ruby is designed to be easy to use and fun for beginners, but powerful enough to create complex systems. It’s a great choice for beginners and experienced developers alike.

While there are many ways to set up Ruby on Windows, Microsoft recommends that you use the [Windows Subsystem for Linux](https://msdn.microsoft.com/commandline/wsl/about) (WSL) and Bash to do your Ruby development. WSL is a Windows 10 feature that lets you run native Linux command line tools on Windows. Many Ruby libraries are designed to run on Linux, and can exhibit problems when run on Windows. Microsoft partnered with Canonical and other Linux distributions to enable native support for the Bash shell and Linux command line tools to solve this issue. With Bash and WSL installed, you’ll edit your files with your favorite Windows tools, but use Bash and command line tools to execute Ruby and its related tools.

In this tutorial, you’ll set up a Ruby programming environment on your local Windows 10 machine using the command line. You’ll configure Bash on Windows, and then use [RVM](http://rvm.io), the Ruby Version Manager to install the latest version of Ruby and its prerequisites. Then you’ll test your environment out by writing a simple Ruby program.

## Prerequisites

You will need a computer running Windows 10 with the [Creators Update](https://support.microsoft.com/en-us/instantanswers/d4efb316-79f0-1aa1-9ef3-dcada78f3fa0/get-the-windows-10-creators-update), and access to install software with administrative privileges.

## Step 1 — Installing Bash on Windows

You’ll use the command line to install and work with Ruby. The command line is a non-graphical way to interact with your computer. Instead of clicking buttons with your mouse, you’ll type commands as text and receive text-based feedback. The command line, also known as a shell, lets you automate many tasks you do on your computer daily, and is an essential tool for software developers. Windows offers two command line interfaces out of the box: the classic Command Prompt, and PowerShell. We’re going to install Bash, a popular shell and command language that you’d find on Linux and macOS.

If you’d like to get comfortable using the command-line interface, take a look at [An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal).

First, enable **Developer mode** on your machine. To do this, open the **Settings** app, select **Update & Security** , and then choose the **For developers** entry in the sidebar. Then check the **Developer mode** option and accept the prompt asking you to verify this change.

Next, open the **Control Panel** and select **Programs**. Then select **Turn Windows features on or off**. In the list of components that appears, check the option for **Windows Subsystem For Linux (Beta)**. Then click **OK** and wait while Windows installs the additional components, which may take a few minutes.

You’ll be prompted to restart your computer to make sure all of the new components are configured correctly. Things won’t work right if you don’t reboot.

When the computer reboots, open the Command Prompt and type:

    bash

You’ll be prompted to install Bash from the Windows Store. It’s a free download that takes several minutes to download and extract.

    OutputThis will install Ubuntu on Windows, distributed by Canonical
    and licensed under its terms available here:
    https://aka.ms/uowterms
    
    Press "y" to continue: y
    Downloading from the Windows Store... 100%
    Extracting filesystem, this will take a few minutes....

Once the installer completes, it’ll ask you to create a user:

    OutputPlease create a default UNIX user account. The username does not need to match your Windows username.
    For more information visit: https://aka.ms.wslusers
    Enter new UNIX username: Sammy
    Enter new UNIX password:

Enter the username you’d like to use, press `ENTER`, and then enter the password. When you type your password, your keystrokes will not display in the Terminal window. This is a security measure and is something you’ll see often when prompted for passwords on the command line. Even though you don’t see them, your keystrokes are being recorded by the system, so press the `ENTER` key once you’ve entered your password, and the process will continue.

Finally, Bash will start, and you’ll see a prompt showing your machine name.

    sammy@yourmachine:/mnt/c/Users/Sammy$

**Warning** : The Windows Subsystem for Linux has its own file system, which is stored in a hidden file on your operating system. Microsoft does not support accessing this file system from any Windows application.

However, all of your existing files are accessible from the Bash shell. For example, you’ll find the contents of your `C:` drive in the `/mnt/c` directory. Microsoft recommends you work on files from this folder. This way you can use your existing Windows tools to open and modify files, and still access them from the Bash shell. Attempting to access files in other parts of the Windows Subsystem for Linux file system from Windows programs such as text editors, file managers, and IDEs can result in data corruption and is not supported.

Now that you have Bash installed and running, let’s install RVM, which we’ll use to install Ruby and all of its dependencies.

## Step 2 — Installing RVM and Ruby

RVM automates the process of setting up a Ruby environment on an Ubuntu or macOS system, and since the Bash setup you’re running is based on Ubuntu, this is the quickest way to set things up on Windows as well. Let’s get it installed so we can use it to install Ruby.

The quickest way to install Ruby with RVM is to run the installation script hosted on the RVM web site.

First, use the `gpg` command to contact a public key server and request the RVM project’s key which is used to sign each RVM release. This lets you verify the legitimacy of the RVM release you’ll download.

    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

Next, install the `gnupg2` package, as RVM’s installation script will use components of that to verify the release. Execute this command to install this package:

    sudo apt-get install gnupg2

You’ll be prompted for your password, and you should enter the password you used for your Linux user when you installed Bash. However, when you type your password, your keystrokes will not display in the Terminal window. This is a security measure and is something you’ll see often when prompted for passwords on the command line. Even though you don’t see them, your keystrokes are being recorded by the system, so press the `ENTER` key once you’ve entered your password, and the process will continue.

Next, use the `curl` command to download the RVM installation script from the project’s website. The backslash that leads the command ensures that we are using the regular curl command and not any altered, aliased version.

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

The script creates a new directory in your Linux user’s home directory called `.rvm`. This is where Ruby and all of its related components will be installed, along with the `rvm` executable program you use to install Ruby. The installation process modifies your `.bashrc` file to add the `.rvm/bin` folder to your `PATH` environment variable so you can run the `rvm` command easily.

However, the `rvm` command won’t be accessible in your current session. So execute this command to fix that:

    source ~/.rvm/scripts/rvm

Now use the `rvm` command to install the latest version of Ruby:

    rvm install ruby --default

This process will download and install Ruby and its components, and make this version of Ruby the default version your system will use. This will avoid conflicts if you have a version of Ruby already installed.

    OutputSearching for binary rubies, this might take some time.
    Found remote file https://rvm_io.global.ssl.fastly.net/binaries/ubuntu/16.04/x86_64/ruby-2.4.0.tar.bz2

If you are missing some important prerequisites, the installer will fetch those prerequisites and install them:

    OutputChecking requirements for ubuntu.
    Installing requirements for ubuntu.
    Updating system....
    Installing required packages: gawk, libssl-dev, zlib1g-dev, libyaml-dev, libsqlite3-dev, sqlite3, autoconf, libgmp-dev, libgdbm-dev, libncurses5-dev, automake, libtool, bison, libffi-dev, libgmp-dev, libreadline6-dev..................
    Requirements installation successful.

The installation script may ask you for your password, and you should use the one you created for your Linux user when you installed Bash.

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

In order for RVM to automatically use its version of Ruby whenever you open a new Bash session, you have to start Bash as a **login shell** , as RVM modifies the `.bash_profile` file, which is only invoked on login shells. The Bash for Windows shortcut doesn’t start a login shell, so if you’re going to use Ruby, just open a new Command Prompt and start Bash with `bash -l`.

If you forget, just run the command `source ~/.rvm/scripts/rvm` every time you start Bash.

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
