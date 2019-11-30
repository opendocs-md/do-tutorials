---
author: Lisa Tagliaferri
date: 2016-08-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-centos-7
---

# How To Install Python 3 and Set Up a Local Programming Environment on CentOS 7

## Introduction

Python is a versatile programming language that can be used for many different programming projects. First published in 1991 with a name inspired by the British comedy group Monty Python, the development team wanted to make Python a language that was fun to use. Easy to set up, and written in a relatively straightforward style with immediate feedback on errors, Python is a great choice for beginners and experienced developers alike. Python 3 is the most current version of the language and is considered to be the future of Python.

This tutorial will guide you through installing Python 3 on your local CentOS 7 machine and setting up a programming environment via the command line.

## Prerequisites

You will need a CentOS 7 computer with a non-root superuser account that is connected to the internet.

## Step 1 — Preparing the System

We will be completing this installation through the command line. If your CentOS 7 computer starts up with a Graphical User Interface (GUI) desktop, you can gain access to the command line interface through the Menu, by navigating to Applications, then Utilities, and then clicking on Terminal. If you need more guidance on the terminal, be sure to read through the article “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal).”

Before we begin with the installation, let’s make sure to update the default system applications to have the latest versions available.

We will be using the open-source package manager tool **yum** , which stands for Yellowdog Updater Modified. This is a commonly used tool for working with software packages on Red Hat based Linux systems like CentOS. It will let you easily install and update, as well as remove software packages on your computer.

Let’s first make sure that yum is up to date by running this command:

    sudo yum -y update

The `-y` flag is used to alert the system that we are aware that we are making changes, preventing the terminal from prompting us to confirm.

Next, we will install **yum-utils** , a collection of utilities and plugins that extend and supplement yum:

    sudo yum -y install yum-utils

Finally, we’ll install the CentOS Development Tools, which are used to allow you to build and compile software from source code:

    sudo yum -y groupinstall development

Once everything is installed, our setup is in place and we can go on to install Python 3.

## Step 2 — Installing and Setting Up Python 3

CentOS is derived from RHEL (Red Hat Enterprise Linux), which has stability as its primary focus. Because of this, tested and stable versions of applications are what is most commonly found on the system and in downloadable packages, so on CentOS you will only find Python 2.

Since instead we would like to install the most current upstream stable release of Python 3, we will need to install **IUS** , which stands for Inline with Upstream Stable. A community project, IUS provides Red Hat Package Manager (RPM) packages for some newer versions of select software.

To install IUS, let’s install it through `yum`:

    sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm

Once IUS is finished installing, we can install the most recent version of Python:

    sudo yum -y install python36u

When the installation process of Python is complete, we can check to make sure that the installation was successful by checking for its version number with the `python3.6` command:

    python3.6 -V

With a version of Python 3.6 successfully installed, we will receive the following output:

    OutputPython 3.6.1

We will next install **pip** , which will manage software packages for Python:

    sudo yum -y install python36u-pip

A tool for use with Python, we will use **pip** to install and manage programming packages we may want to use in our development projects. You can install Python packages by typing:

    sudo pip3.6 install package_name

Here, `package_name` can refer to any Python package or library, such as Django for web development or NumPy for scientific computing. So if you would like to install NumPy, you can do so with the command `pip3.6 install numpy`.

Finally, we will need to install the IUS package **python36u-devel** , which provides us with libraries and header files we will need for Python 3 development:

    sudo yum -y install python36u-devel

The **venv** module will be used to set up a virtual environment for our development projects in the next step.

## Step 3 — Setting Up a Virtual Environment

Now that we have Python installed and our system set up, we can go on to create our programming environment with venv.

Virtual environments enable you to have an isolated space on your computer for Python projects, ensuring that each of your projects can have its own set of dependencies that won’t disrupt any of your other projects.

Setting up a programming environment provides us with greater control over our Python projects and over how different versions of packages are handled. This is especially important when working with third-party packages.

You can set up as many Python programming environments as you want. Each environment is basically a directory or folder in your computer that has a few scripts in it to make it act as an environment.

Choose which directory you would like to put your Python programming environments in, or create a new directory with `mkdir`, as in:

    mkdir environments
    cd environments

Once you are in the directory where you would like the environments to live, you can create an environment by running the following command:

    python3.6 -m venv my_env

Essentially, this command creates a new directory (in this case called my\_env) that contains a few items that we can see with the `ls` command:

    bin include lib lib64 pyvenv.cfg

Together, these files work to make sure that your projects are isolated from the broader context of your local machine, so that system files and project files don’t mix. This is good practice for version control and to ensure that each of your projects has access to the particular packages that it needs.

To use this environment, you need to activate it, which you can do by typing the following command that calls the **activate** script in the `bin` directory:

    source my_env/bin/activate

Your prompt will now be prefixed with the name of your environment, in this case it is called my\_env:

    

This prefix lets us know that the environment my\_env is currently active, meaning that when we create programs here they will use only this particular environment’s settings and packages.

**Note:** Within the virtual environment, you can use the command `python` instead of `python3.6`, and `pip` instead of `pip3.6` if you would prefer. If you use Python 3 on your machine outside of an environment, you will need to use the `python3.6` and `pip3.6` commands exclusively.

After following these steps, your virtual environment is ready to use.

## Step 4 — Creating a Simple Program

Now that we have our virtual environment set up, let’s create a simple “Hello, World!” program. This will make sure that our environment is working and gives us the opportunity to become more familiar with Python if we aren’t already.

To do this, we’ll open up a command-line text editor such as **vim** and create a new file:

    vi hello.py

Once the text file opens up in our terminal window, we will have to type `i` to enter insert mode, and then we can write our first program:

    print("Hello, World!")

Now press `ESC` to leave insert mode. Next, type `:x` then `ENTER` to save and exit the file.

We are now ready to run our program:

    python hello.py

The hello.py program that you just created should cause the terminal to produce the following output:

    OutputHello, World!

To leave the environment, simply type the command `deactivate` and you’ll return to your original directory.

## Conclusion

Congratulations! At this point you have a Python 3 programming environment set up on your local CentOS 7 machine and can begin a coding project!

To set up Python 3 on another computer, follow the [local programming environment guides](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) for [Ubuntu 16.04](how-to-set-up-a-local-programming-environment-for-python-3-in-ubuntu-16-04), [Debian 8](how-to-install-python-3-and-set-up-a-local-programming-environment-on-debian-8), [macOS](how-to-set-up-a-local-programming-environment-for-python-3-on-mac-os-x), or [Windows 10](how-to-set-up-a-local-programming-environment-for-python-3-on-windows-10). You can also read about [installing Python and setting up a programming environment on an Ubuntu 16.04 server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server), which is especially useful when working on development teams.

With your local machine ready for software development, you can continue to learn more about coding in Python by following “[Understanding Data Types in Python 3](understanding-data-types-in-python-3)” and “[How To Use Variables in Python 3](how-to-use-variables-in-python-3)”.
