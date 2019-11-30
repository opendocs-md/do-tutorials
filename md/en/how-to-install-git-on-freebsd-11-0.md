---
author: Steve Russo
date: 2016-11-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-git-on-freebsd-11-0
---

# How To Install Git on FreeBSD 11.0

## Introduction

Version control systems are an indispensable tool in modern software development. They allow you to keep track of your software at the source level. You can track changes, revert to previous stages, and branch to create alternate versions of files and directories.

Git is one of the most popular distributed version control systems. Many projects maintain their files in a Git repository, and sites like GitHub and Bitbucket have made sharing and contributing to code simple and valuable.

In this guide, we will demonstrate how to install and configure Git on a FreeBSD 11.0 server. We will cover how to install the software in two different ways, each of which has its own benefits.

## Prerequisites

To follow this tutorial, you will need:

- One FreeBSD 11 server with a **root** user. On DigitalOcean, the default **freebsd** user is fine.

A FreeBSD Droplet requires an SSH key for remote access. For help on setting up an SSH key, read [How To Configure SSH Key-Based Authentication on a FreeBSD Server](how-to-configure-ssh-key-based-authentication-on-a-freebsd-server). To learn more about logging into your FreeBSD Droplet and basic management, check out the [Getting Started with FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd) tutorial series.

## Installing Git via Packages

The first installation method we’ll show uses the FreeBSD package index. This is generally the easiest and fastest way to install Git.

First, update the `pkg` repository index.

    sudo pkg update -f

Next, download and install the `git` package.

    sudo pkg install git

You’ll need to enter `y` to confirm the installation. That’s it!

You can now move on to the Configuring Git section below to see some basic, useful customization options.

## Installing Git via Ports

The FreeBSD ports system is another way of manging applications on a FreeBSD server. It’s managed through a filesystem hierarchy called the _ports tree_, located at&nbsp;`/usr/ports`,&nbsp;which categorizes each available piece of software that FreeBSD knows how to build. `portsnap` is a tool that comes with FreeBSD and simplifies working with the ports tree. You can learn more in this [ports on FreeBSD tutorial](how-to-install-and-manage-ports-on-freebsd-10-1).

Install Git via ports will take longer than installing it via packages, as you will be building it and several dependencies from source (rather than downloading precompiled binaries, as you would do with `pkg`). The benefit of using ports is a higher level of customization.

First, if you haven’t already, download and extract the ports tree files into `/usr/ports`. This may take a while, but you only ever have to do it once.

    sudo portsnap fetch extract

If you already have the ports tree downloaded, instead you should update it with:

    sudo portsnap fetch update

Then, move to the `devel/git` directory in the ports tree.

    cd /usr/ports/devel/git

Finally, build Git. Including `BATCH="yes"` in this command will install the Git port quietly and avoid the many dialogs along the way asking which parts of certain software you would like installed. You can omit this if you would like to be prompted for which components of each port to install; hitting `ENTER` will assume the default.

    sudo make install clean BATCH="yes"

Now that Git is installed, we can configure it.

## Configuring Git

First, let’s view the existing Git configuration settings. These are pulled from the `~/.gitconfig` file.

    git config --list

From here, you can update any settings you’d like. For example, update your username with the following command replacing `sammy` with your username.

    git config --global user.name "sammy"

You can update your email address with this command, replacing `sammy@example.com` with your email address.

    git config --global user.email "sammy@example.com"

Specify your default text editor by replacing `vim` below with your preferred text editor.

    git config --global core.editor "vim"

You can check that your updates went through by looking at your configuration settings again.

    git config --list

    Outputuser.name=sammy
    user.email=sammy@example.com
    core.editor=vim

## Conclusion

You should now have Git installed on your FreeBSD 11.0 server. For more information on Git, check out the following tutorials:

- [How To Use Git Effectively](how-to-use-git-effectively)
- [How To Use Git Branches](how-to-use-git-branches)
