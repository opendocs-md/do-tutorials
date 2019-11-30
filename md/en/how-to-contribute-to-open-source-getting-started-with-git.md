---
author: Lisa Tagliaferri
date: 2016-09-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-contribute-to-open-source-getting-started-with-git
---

# How To Contribute to Open Source: Getting Started with Git

## Introduction

Open-source projects that are hosted in public repositories benefit from contributions made by the broader developer community, and are typically managed through Git.

A distributed version control system, Git makes team-based and open-source software projects easy to contribute to and to maintain. Free to download and use, Git is an example of an open-source project itself.

This tutorial will discuss the benefits of contributing to open-source projects, and go over installing and setting up Git so that you can contribute to software projects.

## Contributing to Open-Source Projects

Open-source software is software that is freely available to use, redistribute, and modify.

Projects that are open source encourage a transparent process that is advanced through distributed peer review. Open-source projects can be updated quickly and as needed, and offer reliable and flexible software that is not built on locked proprietary systems.

Contributing to open-source projects helps ensure that they are as good as they can be and representative of the broad base of technology end-users. When end-users contribute to open-source projects through code or [documentation](https://blog.digitalocean.com/documentation-as-an-open-source-practice/), their diverse perspectives provide added value to the project, the project’s end-users, and the larger developer community.

The best way to begin to contribute to open-source projects is to start by contributing to software that you already use. As a user of a particular tool, you best understand what functionalities would be most valuable to the project. Make sure you read any available documentation about the software first. In fact, many open-source projects will have a `CONTRIBUTING.md` file in the root directory, which you should read carefully before you contribute. You may also want to get a sense of the interactions between other developers in the community if there are forums about the project available.

Finally, if you’re just starting out with contributing to open-source software, it is a good idea to start with something small — each contribution is valuable. You may want to start with fixing typos, adding comments, or writing clearer documentation.

# Git

One of the most popular version control systems for software is Git. Git was created in 2005 by Linus Torvalds, the creator of the Linux kernel. Originally utilized for the development of the Linux kernel, Junio Hamano is the current maintainer of the project.

Many projects maintain their files in a Git repository, and sites like GitHub, GitLab, and Bitbucket have made sharing and contributing to code simple, valuable, and effective. Every working directory in Git is a full-fledged repository with complete history and tracking independent of network access or a central server.

Version control has become an indispensable tool in modern software development because these systems allow you to keep track of software at the source level. You and other members of a development team can track changes, revert to previous stages, and branch off from the base code to create alternative versions of files and directories.

Git is so useful for open-source projects because it facilitates the contributions of many developers. Each contributor can branch off from the main or master branch of the code base repository to isolate their own changes, and can then make a pull request to have these changes integrated into the main project.

To use Git to contribute to open-source projects, let’s check to see if Git is installed, and if it’s not, let’s go through how to install it on your local machine.

## Check If Git is Installed

First, you will want to check to see if you have Git command line tools installed on your computer. If you have been making repositories of your own code, then you likely have Git installed on your local machine. Some operating systems also come with Git installed, so it is worth checking before you install.

You can check whether Git is installed and what version you are using by opening up a terminal window in Linux or Mac, or a command prompt window in Windows, and typing the following command:

    git --version

However, if Git is not installed, you will receive an error similar to the following:

    -bash: git: command not found

    'git' is not recognized as an internal or external command, operable program or batch file.

In this case, you should install Git into your machine. Let’s go through installation for several of the major operating systems.

## Installing Git on Linux

By far the easiest way of getting Git installed and ready to use is by using your version of Linux’s default repositories. Let’s go through how to install Git on your local Linux machine using this method.

### Installing Git on Ubuntu 18.04 or Debian 10

You can use the apt package management tools to update your local package index. Afterwards, you can download and install the program:

    sudo apt update
    sudo apt install git

While this is the fastest method of installing Git, the version may be older than the newest version. If you need the latest release, consider compiling Git from source by using [this guide](how-to-install-git-on-ubuntu-18-04#how-to-install-git-from-source).

From here, you can continue on to the section on [Setting Up Git](how-to-install-git-on-ubuntu-18-04#installing-git-from-source).

### Installing Git on CentOS

We’ll be using `yum`, CentOS’s native package manager, to search for and install the latest Git package available in CentOS’s repositories.

Let’s first make sure that yum is up to date by running this command:

    sudo yum -y update

The `-y` flag is used to alert the system that we are aware that we are making changes, preventing the terminal from prompting us to confirm.

Now, we can go ahead and install Git:

    sudo yum install git

While this is the fastest method of installing Git, the version may be older than the newest version. If you need the latest release, consider compiling Git from source by following Option 2 from [this guide](how-to-install-git-on-centos-7).

From here, you can continue on to the section on [Setting Up Git](an-introduction-to-contributing-to-open-source-projects-and-installing-git#setting-up-git).

### Installing Git on Fedora

Git packages for Fedora are available through both `yum` and `dnf`. Introduced in Fedora 18, DNF, or Dandified Yum, has been the default package manager for Fedora since Fedora 22.

From your terminal window, update dnf and install Git:

    sudo dnf update
    sudo dnf install git

If you have an older version of Fedora, you can use the `yum` command instead. Let’s first update `yum`, then install Git:

    sudo yum update
    sudo yum install git

From here, you can continue on to the section on [Setting Up Git](an-introduction-to-contributing-to-open-source-projects-and-installing-git#setting-up-git).

## Installing Git on macOS

On a local Macintosh computer, if you type a Git command into your Terminal window (as in `git --version` above), you’ll be prompted to install Git if it is not already on your system. When you receive this prompt, you should agree to have Git installed and follow the instructions and respond to the prompts in your Terminal window.

You can install the most recent version of Git onto your Mac by installing it through the binary installer. There is an OS X Git installer maintained and available for download through the Git website. Clicking [here](https://git-scm.com/download/mac) will cause the download to start automatically.

Once Git is fully installed, you can continue on to the section on [Setting Up Git](an-introduction-to-contributing-to-open-source-projects-and-installing-git#setting-up-git).

## Installing Git on Windows

For Windows, the official build is available for you to download through the Git website. Clicking [here](http://git-scm.com/download/win) will cause the download to start automatically.

There is also an open-source project called Git for Windows, which is separate from the official Git website. This tool provides both command line and graphical user interface tools for using Git effectively on your Windows machine. For more information about this project and to inspect and download the code, visit the [Git for Windows project site](https://git-for-windows.github.io/).

Once Git is fully installed, you can continue on to the section on [Setting Up Git](an-introduction-to-contributing-to-open-source-projects-and-installing-git#setting-up-git).

## Setting Up Git

Now that you have Git installed, you need to do a few things so that the commit messages that will be generated for you will contain your correct information.

The easiest way of doing this is through the `git config` command. Specifically, we need to provide our name and email address because Git embeds this information into each commit we do. We can go ahead and add this information by typing:

    git config --global user.name "Your Name"
    git config --global user.email "youremail@domain.com"

We can see all of the configuration items that have been set by typing:

    git config --list

git configuration

    user.name=Your Name
    user.email=youremail@domain.com

As you can see, this has a slightly different format. The information is stored in your Git configuration file, which you can optionally edit by hand with a text editor, like nano for example:

    nano ~/.gitconfig

~/.gitconfig contents

    [user]
        name = Your Name
        email = youremail@domain.com

There are many other options that you can set, but these are the two essential ones needed to prevent warnings in the future.

## Conclusion

With Git installed and set up on your local machine, you are now ready to use Git for version control of your own software projects as well as contribute to open-source projects that are open to the public.

Adding your own contributions to open-source software is a great way to become more involved in the broader developer community, and help to ensure that software made for the public is of a high quality and fully representative of the end users.
