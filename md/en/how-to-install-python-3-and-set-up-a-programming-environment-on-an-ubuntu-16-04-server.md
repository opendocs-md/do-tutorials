---
author: Lisa Tagliaferri
date: 2016-11-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server
---

# How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 16.04 Server

## Introduction

This tutorial will get your Ubuntu 16.04 or Debian 8 server set up with a Python 3 programming environment. Programming on a server has many advantages and makes it easier for teams to collaborate on a development project. The general principles of this tutorial will apply to any distribution of Debian Linux.

Python is a versatile programming language that can be used for many different programming projects. First published in 1991 with a name inspired by the British comedy group Monty Python, the development team wanted to make Python a language that was fun to use. Easy to set up, and written in a relatively straightforward style with immediate feedback on errors, Python is a great choice for beginners and experienced developers alike. [Python 3 is the most current version](python-2-vs-python-3-practical-considerations-2) of the language and is considered to be the future of Python.

This tutorial will guide you through installing Python 3 on a Debian Linux server and setting up a programming environment.

## Prerequisites

Before you begin, you’ll need a server with Ubuntu 16.04, Debian 8, or another version of Debian Linux installed. You’ll also need a sudo non-root user, which you can set up by following one of the tutorials below:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04)
- [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8)

If you’re not already familiar with a terminal environment, you may find the article “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)” useful for becoming better oriented with the terminal.

## Step 1 — Setting Up Python 3

Ubuntu 16.04, Debian 8, and other versions of Debian Linux ship with both Python 3 and Python 2 pre-installed. To make sure that our versions are up-to-date, let’s update and upgrade the system with `apt-get`:

    sudo apt-get update
    sudo apt-get -y upgrade

The `-y` flag will confirm that we are agreeing for all items to be installed, but depending on your version of Linux, you may need to confirm additional prompts as your system updates and upgrades.

Once the process is complete, we can check the version of Python 3 that is installed in the system by typing:

    python3 -V

You’ll receive output in the terminal window that will let you know the version number. The version number may vary depending on whether you are on Ubuntu 16.04, Debian 8, or another version of Linux, but it will look similar to this:

    OutputPython 3.5.2

To manage software packages for Python, let’s install **pip** :

    sudo apt-get install -y python3-pip

A tool for use with Python, **pip** installs and manages programming packages we may want to use in our development projects. You can install Python packages by typing:

    pip3 install package_name

Here, `package_name` can refer to any Python package or library, such as Django for web development or NumPy for scientific computing. So if you would like to install NumPy, you can do so with the command `pip3 install numpy`.

There are a few more packages and development tools to install to ensure that we have a robust set-up for our programming environment:

    sudo apt-get install build-essential libssl-dev libffi-dev python3-dev

Once Python is set up, and pip and other tools are installed, we can set up a virtual environment for our development projects.

## Step 2 — Setting Up a Virtual Environment

Virtual environments enable you to have an isolated space on your server for Python projects, ensuring that each of your projects can have its own set of dependencies that won’t disrupt any of your other projects.

Setting up a programming environment provides us with greater control over our Python projects and over how different versions of packages are handled. This is especially important when working with third-party packages.

You can set up as many Python programming environments as you want. Each environment is basically a directory or folder on your server that has a few scripts in it to make it act as an environment.

We need to first install the **venv** module, part of the standard Python 3 library, so that we can invoke the **pyvenv** command which will create virtual environments for us. Let’s install venv by typing:

    sudo apt-get install -y python3-venv

With this installed, we are ready to create environments. Let’s choose which directory we would like to put our Python programming environments in, or we can create a new directory with `mkdir`, as in:

    mkdir environments
    cd environments

Once you are in the directory where you would like the environments to live, you can create an environment by running the following command:

    pyvenv my_env

Essentially, `pyvenv` sets up a new directory that contains a few items which we can view with the `ls` command:

    ls my_env

    Outputbin include lib lib64 pyvenv.cfg share

Together, these files work to make sure that your projects are isolated from the broader context of your local machine, so that system files and project files don’t mix. This is good practice for version control and to ensure that each of your projects has access to the particular packages that it needs. Python Wheels, a built-package format for Python that can speed up your software production by reducing the number of times you need to compile, will be in the Ubuntu 16.04 `share` directory but in Debian 8 it will be in each of the `lib` directories as there is no `share` directory.

To use this environment, you need to activate it, which you can do by typing the following command that calls the activate script:

    source my_env/bin/activate

Your prompt will now be prefixed with the name of your environment, in this case it is called my\_env. Depending on what version of Debian Linux you are running, your prefix may look somewhat different, but the name of your environment in parentheses should be the first thing you see on your line:

    

This prefix lets us know that the environment my\_env is currently active, meaning that when we create programs here they will use only this particular environment’s settings and packages.

**Note:** Within the virtual environment, you can use the command `python` instead of `python3`, and `pip` instead of `pip3` if you would prefer. If you use Python 3 on your machine outside of an environment, you will need to use the `python3` and `pip3` commands exclusively.

After following these steps, your virtual environment is ready to use.

## Step 3 — Creating a Simple Program

Now that we have our virtual environment set up, let’s create a simple “Hello, World!” program. This will make sure that our environment is working and gives us the opportunity to become more familiar with Python if we aren’t already.

To do this, we’ll open up a command-line text editor such as nano and create a new file:

    nano hello.py

Once the text file opens up in the terminal window we’ll type out our program:

    print("Hello, World!")

Exit nano by typing the `control` and `x` keys, and when prompted to save the file press `y`.

Once you exit out of nano and return to your shell, let’s run the program:

    python hello.py

The hello.py program that you just created should cause your terminal to produce the following output:

    OutputHello, World!

To leave the environment, simply type the command `deactivate` and you will return to your original directory.

## Conclusion

Congratulations! At this point you have a Python 3 programming environment set up on your Debian Linux server and you can now begin a coding project!

To set up Python 3 on another computer, follow the [local programming environment guides](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) for [Ubuntu 16.04](how-to-set-up-a-local-programming-environment-for-python-3-in-ubuntu-16-04), [Debian 8](how-to-install-python-3-and-set-up-a-local-programming-environment-on-debian-8), [Windows 10](how-to-set-up-a-local-programming-environment-for-python-3-on-windows-10), or [macOS](how-to-set-up-a-local-programming-environment-for-python-3-on-mac-os-x).

With your server set up for software development, you can continue to learn more about coding in Python by following “[Understanding Data Types in Python 3](understanding-data-types-in-python-3)” and “[How To Use Variables in Python 3](how-to-use-variables-in-python-3)”.
