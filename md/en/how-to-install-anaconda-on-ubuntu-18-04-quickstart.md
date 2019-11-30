---
author: Lisa Tagliaferri
date: 2018-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-anaconda-on-ubuntu-18-04-quickstart
---

# How To Install Anaconda on Ubuntu 18.04 [Quickstart]

## Introduction

Designed for data science and machine learning workflows, Anaconda is an open-source package manager, environment manager, and distribution of the Python and R programming languages.

This tutorial will guide you through installing Anaconda on an Ubuntu 18.04 server. For a more detailed version of this tutorial, with better explanations of each step, please refer to [How To Install the Anaconda Python Distribution on Ubuntu 18.04](how-to-install-the-anaconda-python-distribution-on-ubuntu-18-04).

## Step 1 — Retrieve the Latest Version of Anaconda

From a web browser, go to the [Anaconda Distribution page](https://www.anaconda.com/distribution/), available via the following link:

    https://www.anaconda.com/distribution/

Find the latest Linux version and copy the installer bash script.

## Step 2 — Download the Anaconda Bash Script

Logged into your Ubuntu 18.04 server as a sudo non-root user, move into the `/tmp` directory and use `curl` to download the link you copied from the Anaconda website:

    cd /tmp
    curl -O https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh

## Step 3 — Verify the Data Integrity of the Installer

Ensure the integrity of the installer with cryptographic hash verification through SHA-256 checksum:

    sha256sum Anaconda3-2019.03-Linux-x86_64.sh

    Output45c851b7497cc14d5ca060064394569f724b67d9b5f98a926ed49b834a6bb73a Anaconda3-2019.03-Linux-x86_64.sh

## Step 4 — Run the Anaconda Script

    bash Anaconda3-2019.03-Linux-x86_64.sh

You’ll receive the following output to review the license agreement by pressing `ENTER` until you reach the end.

    Output
    Welcome to Anaconda3 2019.03
    
    In order to continue the installation process, please review the license
    agreement.
    Please, press ENTER to continue
    >>>
    ...
    Do you approve the license terms? [yes|no]

When you get to the end of the license, type `yes` as long as you agree to the license to complete installation.

## Step 5 — Complete Installation Process

Once you agree to the license, you will be prompted to choose the location of the installation. You can press `ENTER` to accept the default location, or specify a different location.

    OutputAnaconda3 will now be installed into this location:
    /home/sammy/anaconda3
    
      - Press ENTER to confirm the location
      - Press CTRL-C to abort the installation
      - Or specify a different location below
    
    [/home/sammy/anaconda3] >>>

At this point, the installation will proceed. Note that the installation process takes some time.

## Step 6 — Select Options

Once installation is complete, you’ll receive the following output:

    Output...
    installation finished.
    Do you wish the installer to prepend the Anaconda3 install location
    to PATH in your /home/sammy/.bashrc ? [yes|no]
    [no] >>> 

It is recommended that you type `yes` to use the `conda` command.

## Step 7 — Activate Installation

You can now activate the installation with the following command:

    source ~/.bashrc

## Step 8 — Test Installation

Use the `conda` command to test the installation and activation:

    conda list

You’ll receive output of all the packages you have available through the Anaconda installation.

## Step 9 — Set Up Anaconda Environments

You can create Anaconda environments with the `conda create` command. For example, a Python 3 environment named `my_env` can be created with the following command:

    conda create --name my_env python=3

Activate the new environment like so:

    conda activate my_env

Your command prompt prefix will change to reflect that you are in an active Anaconda environment, and you are now ready to begin work on a project.

## Related Tutorials

Here are links to more detailed tutorials that are related to this guide:

- [How To Install the Anaconda Python Distribution on Ubuntu 18.04](how-to-install-the-anaconda-python-distribution-on-ubuntu-18-04) 
- [How To Set Up Jupyter Notebook for Python 3](how-to-set-up-jupyter-notebook-for-python-3)
- [How To Install the pandas Package and Work with Data Structures in Python 3](how-to-install-the-pandas-package-and-work-with-data-structures-in-python-3)
