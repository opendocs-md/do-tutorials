---
author: Lisa Tagliaferri
date: 2018-07-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-18-04
---

# How To Install Python 3 and Set Up a Local Programming Environment on Ubuntu 18.04

## Introduction

Python is a flexible and versatile programming language that can be leveraged for many use cases, with strengths in scripting, automation, data analysis, machine learning, and back-end development. First published in 1991 with a name inspired by the British comedy group Monty Python, the development team wanted to make Python a language that was fun to use. Quick to set up, and written in a relatively straightforward style with immediate feedback on errors, Python is a great choice for beginners and experienced developers alike. [Python 3 is the most current version](python-2-vs-python-3-practical-considerations-2) of the language and is considered to be the future of Python.

This tutorial will guide you through installing Python 3 on your **local** Linux machine and setting up a programming environment via the command line. This tutorial will explicitly cover the installation procedures for Ubuntu 18.04, but the general principles apply to any other distribution of Debian Linux.

## Prerequisites

You will need a computer or virtual machine with Ubuntu 18.04 installed, as well as have administrative access to that machine and an internet connection. You can download this operating system via the [Ubuntu 18.04 releases page](http://releases.ubuntu.com/releases/18.04/).

## Step 1 — Setting Up Python 3

We’ll be completing our installation and setup on the command line, which is a non-graphical way to interact with your computer. That is, instead of clicking on buttons, you’ll be typing in text and receiving feedback from your computer through text as well.

The command line, also known as a shell or terminal, can help you modify and automate many of the tasks you do on a computer every day, and is an essential tool for software developers. There are many terminal commands to learn that can enable you to do more powerful things. The article “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)” can get you better oriented with the terminal.

On Ubuntu 18.04, you can find the Terminal application by clicking on the Ubuntu icon in the upper-left hand corner of your screen and typing “terminal” into the search bar. Click on the Terminal application icon to open it. Alternatively, you can hit the `CTRL`, `ALT`, and `T` keys on your keyboard at the same time to open the Terminal application automatically.

![Ubuntu Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/UbuntuDebianSetUp/UbuntuSetUp.png)

Ubuntu 18.04 ships with both Python 3 and Python 2 pre-installed. To make sure that our versions are up-to-date, let’s update and upgrade the system with the `apt` command to work with Ubuntu’s **A** dvanced **P** ackaging **T** ool:

    sudo apt update
    sudo apt -y upgrade

The `-y` flag will confirm that we are agreeing that all items to be installed, but depending on your version of Linux, you may need to confirm additional prompts as your system updates and upgrades.

Once the process is complete, we can check the version of Python 3 that is installed in the system by typing:

    python3 -V

You will receive output in the terminal window that will let you know the version number. The version number may vary, but it will be similar to this:

    OutputPython 3.6.5

To manage software packages for Python, let’s install **pip** , a tool that will install and manage programming packages we may want to use in our development projects. You can learn more about modules or packages that you can install with pip by reading “[How To Import Modules in Python 3](how-to-import-modules-in-python-3).”

    sudo apt install -y python3-pip

Python packages can be installed by typing:

    pip3 install package_name

Here, `package_name` can refer to any Python package or library, such as Django for web development or NumPy for scientific computing. So if you would like to install NumPy, you can do so with the command `pip3 install numpy`.

There are a few more packages and development tools to install to ensure that we have a robust set-up for our programming environment:

    sudo apt install build-essential libssl-dev libffi-dev python-dev

Press `y` if prompted to do so.

Once Python is set up, and pip and other tools are installed, we can set up a virtual environment for our development projects.

## Step 2 — Setting Up a Virtual Environment

Virtual environments enable you to have an isolated space on your computer for Python projects, ensuring that each of your projects can have its own set of dependencies that won’t disrupt any of your other projects.

Setting up a programming environment provides us with greater control over our Python projects and over how different versions of packages are handled. This is especially important when working with third-party packages.

You can set up as many Python programming environments as you want. Each environment is basically a directory or folder in your computer that has a few scripts in it to make it act as an environment.

While there are a few ways to achieve a programming environment in Python, we’ll be using the **venv** module here, which is part of the standard Python 3 library. Let’s install venv by typing:

    sudo apt install -y python3-venv

With this installed, we are ready to create environments. Let’s either choose which directory we would like to put our Python programming environments in, or create a new directory with `mkdir`, as in:

    mkdir environments
    cd environments

Once you are in the directory where you would like the environments to live, you can create an environment by running the following command:

    python3 -m venv my_env

Essentially, this sets up a new directory that contains a few items which we can view with the `ls` command:

    ls my_env

    Outputbin include lib lib64 pyvenv.cfg share

Together, these files work to make sure that your projects are isolated from the broader context of your local machine, so that system files and project files don’t mix. This is good practice for version control and to ensure that each of your projects has access to the particular packages that it needs. Python Wheels, a built-package format for Python that can speed up your software production by reducing the number of times you need to compile, will be in the Ubuntu 18.04 `share` directory.

To use this environment, you need to activate it, which you can do by typing the following command that calls the activate script:

    source my_env/bin/activate

Your prompt will now be prefixed with the name of your environment, in this case it is called my\_env. Your prefix may appear somewhat differently, but the name of your environment in parentheses should be the first thing you see on your line:

    

This prefix lets us know that the environment my\_env is currently active, meaning that when we create programs here they will use only this particular environment’s settings and packages.

**Note:** Within the virtual environment, you can use the command `python` instead of `python3`, and `pip` instead of `pip3` if you would prefer. If you use Python 3 on your machine outside of an environment, you will need to use the `python3` and `pip3` commands exclusively.

After following these steps, your virtual environment is ready to use.

## Step 3 — Creating a “Hello, World” Program

Now that we have our virtual environment set up, let’s create a traditional “Hello, World!” program. This will let us test our environment and provides us with the opportunity to become more familiar with Python if we aren’t already.

To do this, we’ll open up a command-line text editor such as nano and create a new file:

    nano hello.py

When the text file opens up in the terminal window we’ll type out our program:

    print("Hello, World!")

Exit nano by typing the `CTRL` and `X` keys, and when prompted to save the file press `y`.

Once you exit out of nano and return to your shell, we’ll run the program:

    python hello.py

The `hello.py` program that you just created should cause your terminal to produce the following output:

    OutputHello, World!

To leave the environment, simply type the command `deactivate` and you will return to your original directory.

## Conclusion

Congratulations! At this point you have a Python 3 programming environment set up on your local Ubuntu machine and can begin a coding project!

If you are using a different local machine, refer to the tutorial that is relevant to your operating system in our “[How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3)” series. Alternatively, if you’re using an Ubuntu server, you can follow the “[How To Install Python and Set Up a Programming Environment on an Ubuntu 18.04 Server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server)” tutorial.

With your local machine ready for software development, you can continue to learn more about coding in Python by reading our free [_How To Code in Python 3_ eBook](https://do.co/python-book), or consulting our [Programming Project tutorials](https://www.digitalocean.com/community/tags/project/tutorials).
