---
author: Lisa Tagliaferri
date: 2016-08-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-macos
---

# How To Install Python 3 and Set Up a Local Programming Environment on macOS

## Introduction

Python is a versatile programming language that can be used for many different programming projects. First published in 1991 with a name inspired by the British comedy group Monty Python, the development team wanted to make Python a language that was fun to use. Easy to set up, and written in a relatively straightforward style with immediate feedback on errors, Python is a great choice for beginners and experienced developers alike. Python 3 is the most current version of the language and is considered to be the future of Python.

This tutorial will guide you through installing Python 3 on your local macOS machine and setting up a programming environment via the command line.

## Prerequisites

You will need a macOS computer with administrative access that is connected to the internet.

## Step 1 — Opening Terminal

We’ll be completing most of our installation and set up on the command line, which is a non-graphical way to interact with your computer. That is, instead of clicking on buttons, you’ll be typing in text and receiving feedback from your computer through text as well. The command line, also known as a shell, can help you modify and automate many of the tasks you do on a computer every day, and is an essential tool for software developers.

The macOS Terminal is an application you can use to access the command line interface. Like any other application, you can find it by going into Finder, navigating to the Applications folder, and then into the Utilities folder. From here, double-click the Terminal like any other application to open it up. Alternatively, you can use Spotlight by holding down the `command` and `spacebar` keys to find Terminal by typing it out in the box that appears.

![macOS Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/OSXSetUp/MacOSXSetUp.png)

There are many more Terminal commands to learn that can enable you to do more powerful things. The article “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)” can get you better oriented with the Linux Terminal, which is similar to the macOS Terminal.

## Step 2 — Installing Xcode

Xcode is an integrated development environment (IDE) that is comprised of software development tools for macOS. You may have Xcode installed already. To check, in your Terminal window, type:

    xcode-select -p

If you receive the following output, then Xcode is installed:

    Output/Library/Developer/CommandLineTools

If you received an error, then in your web browser install [Xcode from the App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12&ign-mpt=uo%3D2) and accept the default options.

Once Xcode is installed, return to your Terminal window. Next, you’ll need to install Xcode’s separate Command Line Tools app, which you can do by typing:

    xcode-select --install

At this point, Xcode and its Command Line Tools app are fully installed, and we are ready to install the package manager Homebrew.

## Step 3 — Installing and Setting Up Homebrew

While the OS X Terminal has a lot of the functionality of Linux Terminals and other Unix systems, it does not ship with a good package manager. A **package manager** is a collection of software tools that work to automate installation processes that include initial software installation, upgrading and configuring of software, and removing software as needed. They keep installations in a central location and can maintain all software packages on the system in formats that are commonly used. **Homebrew** provides OS X with a free and open source software package managing system that simplifies the installation of software on OS X.

To install Homebrew, type this into your Terminal window:

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Homebrew is made with Ruby, so it will be modifying your computer’s Ruby path. The `curl` command pulls a script from the specified URL. This script will explain what it will do and then pauses the process to prompt you to confirm. This provides you with a lot of feedback on what the script is going to be doing to your system and gives you the opportunity to verify the process.

If you need to enter your password note that your keystrokes will not display in the Terminal window but they will be recorded, simply press the `return` key once you’ve entered your password. Otherwise press the letter `y` for “yes” whenever you are prompted to confirm the installation.

Let’s walk through the flags that are associated with the `curl` command:

- The -`f` or `--fail` flag tells the Terminal window to give no HTML document output on server errors. 
- The `-s` or `--silent` flag mutes `curl` so that it does not show the progress meter, and combined with the `-S` or `--show-error` flag it will ensure that `curl` shows an error message if it fails. 
- The `-L` or `--location` flag will tell `curl` to redo the request to a new place if the server reports that the requested page has moved to a different location. 

Once the installation process is complete, we’ll put the Homebrew directory at the top of the `PATH` environment variable. This will ensure that Homebrew installations will be called over the tools that Mac OS X may select automatically that could run counter to the development environment we’re creating.

You should create or open the `~/.bash_profile` file with the command-line text editor **nano** using the `nano` command:

    nano ~/.bash_profile

Once the file opens up in the Terminal window, write the following:

    export PATH=/usr/local/bin:$PATH

To save your changes, hold down the `control` key and the letter `o`, and when prompted press the `return` key. Now you can exit nano by holding the `control` key and the letter `x`.

For these changes to activate, in the Terminal window, type:

    source ~/.bash_profile

Once you have done this, the changes you have made to the `PATH` environment variable will be effective.

We can make sure that Homebrew was successfully installed by typing:

    brew doctor

If no updates are required at this time, the Terminal output will read:

    OutputYour system is ready to brew.

Otherwise, you may get a warning to run another command such as `brew update` to ensure that your installation of Homebrew is up to date.

Once Homebrew is ready, you can install Python 3.

## Step 4 — Installing Python 3

You can use Homebrew to search for everything you can install with the `brew search` command, but to provide us with a shorter list, let’s instead search for just the available Python-related packages or modules:

    brew search python

The Terminal will output a list of what you can install, like this:

    Outputapp-engine-python micropython python3                 
    boost-python python wxpython                 
    gst-python python-markdown zpython                  
    homebrew/apache/mod_python homebrew/versions/gst-python010        
    homebrew/python/python-dbus Caskroom/cask/kk7ds-python-runtime     
    homebrew/python/vpython Caskroom/cask/mysql-connector-python   
    

Python 3 will be among the items on the list. Let’s go ahead and install it:

    brew install python3

The Terminal window will give you feedback regarding the installation process of Python 3, it may take a few minutes before installation is complete.

Along with Python 3, Homebrew will install **pip** , **setuptools** and **wheel**.

A tool for use with Python, we will use **pip** to install and manage programming packages we may want to use in our development projects. You can install Python packages by typing:

    pip3 install package_name

Here, `package_name` can refer to any Python package or library, such as Django for web development or NumPy for scientific computing. So if you would like to install NumPy, you can do so with the command `pip3 install numpy`.

**setuptools** facilitates packaging Python projects, and **wheel** is a built-package format for Python that can speed up your software production by reducing the number of times you need to compile.

To check the version of Python 3 that you installed, you can type:

    python3 --version

This will output the specific version of Python that is currently installed, which will by default be the most up-to-date stable version of Python 3 that is available.

To update your version of Python 3, you can first update Homebrew and then update Python:

    brew update
    brew upgrade python3

It is good practice to ensure that your version of Python is up-to-date.

## Step 5 — Creating a Virtual Environment

Now that we have Xcode, Homebrew, and Python installed, we can go on to create our programming environment.

Virtual environments enable you to have an isolated space on your computer for Python projects, ensuring that each of your projects can have its own set of dependencies that won’t disrupt any of your other projects.

Setting up a programming environment provides us with greater control over our Python projects and over how different versions of packages are handled. This is especially important when working with third-party packages.

You can set up as many Python programming environments as you would like. Each environment is basically a directory or folder in your computer that has a few scripts in it to make it act as an environment.

Choose which directory you would like to put your Python programming environments in, or create a new directory with `mkdir`, as in:

    mkdir Environments
    cd Environments

Once you are in the directory where you would like the environments to live, you can create an environment by running the following command:

    python3.7 -m venv my_env

Essentially, this command creates a new directory (in this case called my\_env) that contains a few items:

- The `pyvenv.cfg` file points to the Python installation that you used to run the command. 
- The `lib` subdirectory contains a copy of the Python version and has a `site-packages` subdirectory inside it that starts out empty but will eventually hold the relevant third-party modules that you install. 
- The `include` subdirectory compiles packages.
- The `bin` subdirectory has a copy of the Python binary along with the _activate_ shell script that is used to set up the environment. 

Together, these files work to make sure that your projects are isolated from the broader context of your local machine, so that system files and project files don’t mix. This is good practice for version control and to ensure that each of your projects has access to the particular packages that it needs.

To use this environment, you need to activate it, which you can do by typing the following command that calls the activate script:

    source my_env/bin/activate

Your prompt will now be prefixed with the name of your environment, in this case it is called my\_env:

    

This prefix lets us know that the environment my\_env is currently active, meaning that when we create programs here they will use only this particular environment’s settings and packages.

**Note:** Within the virtual environment, you can use the command `python` instead of `python3`, and `pip` instead of `pip3` if you would prefer. If you use Python 3 on your machine outside of an environment, you’ll need to use the `python3` and `pip3` commands exclusively, as `python` and `pip` will call an earlier version of Python.

After following these steps, your virtual environment is ready to use.

## Step 6 — Creating a Sample Program

Now that we have our virtual environment set up, let’s create a traditional “Hello, World!” program. This will make sure that our environment is working and gives us the opportunity to become more familiar with Python if we aren’t already.

To do this, we’ll open up a command-line text editor such as nano and create a new file:

    nano hello.py

Once the text file opens up in Terminal we’ll type out our program:

    print("Hello, World!")

Exit nano by typing the `control` and `x` keys, and when prompted to save the file press `y`.

Once you exit out of nano and return to your shell, let’s run the program:

    python hello.py

The hello.py program that you just created should cause Terminal to produce the following output:

    OutputHello, World!

To leave the environment, simply type the command `deactivate` and you’ll return to your original directory.

## Conclusion

Congratulations! At this point you have a Python 3 programming environment set up on your local Mac OS X machine and can begin a coding project!

To set up Python 3 on another computer, follow the [local programming environment guides](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) for [Ubuntu 16.04](how-to-set-up-a-local-programming-environment-for-python-3-in-ubuntu-16-04), [Debian 8](how-to-install-python-3-and-set-up-a-local-programming-environment-on-debian-8), [CentOS 7](how-to-set-up-a-local-programming-environment-for-python-3-on-centos-7), or [Windows 10](how-to-set-up-a-local-programming-environment-for-python-3-on-windows-10). You can also read about [installing Python and setting up a programming environment on an Ubuntu 16.04 server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server), which is especially useful when working on development teams.

With your local machine ready for software development, you can continue to learn more about coding in Python by following “[Understanding Data Types in Python 3](understanding-data-types-in-python-3)” and “[How To Use Variables in Python 3](how-to-use-variables-in-python-3)”.
