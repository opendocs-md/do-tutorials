---
author: Lisa Tagliaferri
date: 2018-07-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-18-04-quickstart
---

# How To Install Git on Ubuntu 18.04 [Quickstart]

## Introduction

Version control systems help you share and collaborate on software development projects. Git is one of the most popular version control systems currently available.

This tutorial will walk you through installing and configuring Git on an Ubuntu 18.04 server. For a more detailed version of this tutorial, with better explanations of each step, please refer to [How To Install Git on Ubuntu 18.04](how-to-install-git-on-ubuntu-18-04).

## Step 1 — Update Default Packages

Logged into your Ubuntu 18.04 server as a sudo non-root user, first update your default packages.

    sudo apt update

## Step 2 — Install Git

    sudo apt install git

## Step 3 — Confirm Successful Installation

You can confirm that you have installed Git correctly by running this command and receiving output similar to the following:

    git --version

    Outputgit version 2.17.1

## Step 4 — Set Up Git

Now that you have Git installed and to prevent warnings, you should configure it with your information.

    git config --global user.name "Your Name"
    git config --global user.email "youremail@domain.com"

If you need to edit this file, you can use a text editor such as nano:

    nano ~/.gitconfig

~/.gitconfig contents

    [user]
      name = Your Name
      email = youremail@domain.com

## Related Tutorials

Here are links to more detailed tutorials that are related to this guide:

- [How To Install Git on 18.04](how-to-install-git-on-ubuntu-18-04)
- [How To Use Git Effectively](https://www.digitalocean.com/community/articles/how-to-use-git-effectively)
- [How To Use Git Branches](https://www.digitalocean.com/community/articles/how-to-use-git-branches)
- [An Introduction to Open Source](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-open-source)
