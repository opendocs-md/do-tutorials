---
author: Lisa Tagliaferri
date: 2018-07-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-programming-environment-on-ubuntu-18-04-quickstart
---

# How To Install Python 3 and Set Up a Programming Environment on Ubuntu 18.04 [Quickstart]

## Introduction

Python is a flexible and versatile programming language, with strengths in scripting, automation, data analysis, machine learning, and back-end development.

This tutorial will walk you through installing Python and setting up a programming environment on an Ubuntu 18.04 server. For a more detailed version of this tutorial, with better explanations of each step, please refer to [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 18.04 Server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server).

## Step 1 — Update and Upgrade

Logged into your Ubuntu 18.04 server as a sudo non-root user, first update and upgrade your system to ensure that your shipped version of Python 3 is up-to-date.

    sudo apt update
    sudo apt -y upgrade

Confirm installation if prompted to do so.

## Step 2 — Check Version of Python

Check which version of Python 3 is installed by typing:

    python3 -V

You’ll receive output similar to the following, depending on when you have updated your system.

    OutputPython 3.6.7

## Step 3 — Install pip

To manage software packages for Python, install **pip** , a tool that will install and manage libraries or modules to use in your projects.

    sudo apt install -y python3-pip

Python packages can be installed by typing:

    pip3 install package_name

Here, `package_name` can refer to any Python package or library, such as Django for web development or NumPy for scientific computing. So if you would like to install NumPy, you can do so with the command `pip3 install numpy`.

## Step 4 — Install Additional Tools

There are a few more packages and development tools to install to ensure that we have a robust set-up for our programming environment:

    sudo apt install build-essential libssl-dev libffi-dev python3-dev

## Step 5 — Install venv

Virtual environments enable you to have an isolated space on your server for Python projects. We’ll use **venv** , part of the standard Python 3 library, which we can install by typing:

    sudo apt install -y python3-venv

## Step 6 — Create a Virtual Environment

You can create a new environment with the `pyvenv` command. Here, we’ll call our new environment `my_env`, but you can call yours whatever you want.

    python3.6 -m venv my_env

## Step 7 — Activate Virtual Environment

Activate the environment using the command below, where `my_env` is the name of your programming environment.

    source my_env/bin/activate

Your command prompt will now be prefixed with the name of your environment:

    

## Step 8 — Test Virtual Environment

Open the Python interpreter:

    python

Note that within the Python 3 virtual environment, you can use the command `python` instead of `python3`, and `pip` instead of `pip3`.

You’ll know you’re in the interpreter when you receive the following output:

    Python 3.6.5 (default, Apr 1 2018, 05:46:30) 
    [GCC 7.3.0] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> 

Now, use the `print()` function to create the traditional Hello, World program:

    print("Hello, World!")

    OutputHello, World!

## Step 9 — Deactivate Virtual Environment

Quit the Python interpreter:

    quit()

Then exit the virtual environment:

    deactivate

## Further Reading

Here are links to more detailed tutorials that are related to this guide:

- [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 18.04 Server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server)
- [Free _How To Code in Python 3_ eBook](https://do.co/python-book)
- [Programming Project Tutorials](https://www.digitalocean.com/community/tags/project?type=tutorials)
