---
author: Mitchell Anicas
date: 2014-11-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-the-linux-terminal
---

# An Introduction to the Linux Terminal

## Introduction

This tutorial, which is the first in a series that teaches Linux basics to get new users on their feet, covers getting started with the terminal, the Linux command line, and executing commands. If you are new to Linux, you will want to familiarize yourself with the terminal, as it is the standard way to interact with a Linux server. Using the command line may seem like a daunting task but it is actually very easy if you start with the basics, and build your skills from there.

If you would like to get the most out of this tutorial, you will need a Linux server to connect to and use. If you do not already have one, you can quickly spin one up by following this link: [How To Create A DigitalOcean Droplet](how-to-create-your-first-digitalocean-droplet-virtual-server). This tutorial is based on an Ubuntu 14.04 server but the general principles apply to any other distribution of Linux.

Let’s get started by going over what a terminal emulator is.

## Terminal Emulator

A terminal emulator is a program that allows the use of the terminal in a graphical environment. As most people use an OS with a graphical user interface (GUI) for their day-to-day computer needs, the use of a terminal emulator is a necessity for most Linux server users.

Here are some free, commonly-used terminal emulators by operating system:

- **Mac OS X** : Terminal (default), iTerm 2
- **Windows** : PuTTY
- **Linux** : Terminal, KDE Konsole, XTerm

Each terminal emulator has its own set of features, but all of the listed ones work great and are easy to use.

## The Shell

In a Linux system, the _shell_ is a command-line interface that interprets a user’s commands and script files, and tells the server’s operating system what to do with them. There are several shells that are widely used, such as _Bourne shell_ (`sh`) and _C shell_ (`csh`). Each shell has its own feature set and intricacies, regarding how commands are interpreted, but they all feature input and output redirection, variables, and condition-testing, among other things.

This tutorial was written using the _Bourne-Again shell_, usually referred to as `bash`, which is the default shell for most Linux distributions, including Ubuntu, CentOS, and RedHat.

## The Command Prompt

When you first login to a server, you will typically be greeted by the _Message of the Day_ (MOTD), which is typically an informational message that includes miscellaneous information such as the version of the Linux distribution that the server is running. After the MOTD, you will be dropped into the command prompt, or shell prompt, which is where you can issue commands to the server.

The information that is presented at the command prompt can be customized by the user, but here is an example of the default Ubuntu 14.04 command prompt:

    sammy@webapp:~$

Here is a breakdown of the composition of the command prompt:

- `sammy`: The _username_ of the current user
- `webapp`: The _hostname_ of the server
- `~`: The _current directory_. In `bash`, which is the default shell, the `~`, or tilde, is a special character that expands to the path of the current user’s _home directory_; in this case, it represents `/home/sammy`
- `$`: The prompt symbol. This denotes the end of the command prompt, after which the user’s keyboard input will appear

Here is an example of what the command prompt might look like, if logged in as `root` and in the `/var/log` directory:

    root@webapp:/var/log#

Note that the symbol that ends the command prompt is a `#`, which is the standard prompt symbol for `root`. In Linux, the `root` user is the _superuser_ account, which is a special user account that can perform system-wide administrative functions–it is an unrestricted user that has permission to perform any task on a server.

## Executing Commands

Commands can be issued at the command prompt by specifying the name of an executable file, which can be a binary program or a script. There are many standard Linux commands and utilities that are installed with the OS, that allow you navigate the file system, install and software packages, and configure the system and applications.

An instance of a running command is known as a **process**. When a command is executed in the _foreground_, which is the default way that commands are executed, the user must wait for the process to finish before being returned to the command prompt, at which point they can continue issuing more commands.

It is important to note that almost everything in Linux is case-sensitive, including file and directory names, commands, arguments, and options. If something is not working as expected, double-check the spelling and case of your commands!

We will run through a few examples that will cover the basics of executing commands.

**Note:** If you’re not already connected to a Linux server, now is a good time to log in. If you have a Linux server but are having trouble connecting, follow this link: [How to Connect to Your Droplet with SSH](how-to-connect-to-your-droplet-with-ssh).

### Without Arguments or Options

To execute a command without any arguments or options, simply type in the name of the command and hit `RETURN`.

If you run a command like this, it will exhibit its default behavior, which varies from command to command. For example, if you run the `cd` command without any arguments, you will be returned to your current user’s home directory. The `ls` command will print a listing of the current directory’s files and directories. The `ip` command without any arguments will print a message that shows you how to use the `ip` command.

Try running the `ls` command with no arguments to list the files and directories in your current directory (there may be none):

    ls

### With Arguments

Many commands accept _arguments_, or _parameters_, which can affect the behavior of a command. For example, the most common way to use the `cd` command is to pass it a single argument that specifies which directory to change to. For example, to change to the `/usr/bin` directory, where many standard commands are installed, you would issue this command:

    cd /usr/bin

The `cd` component is the command, and the first argument `/usr/bin` follows the command. Note how your command prompt’s current path has updated.

If you would like, try running the `ls` command to see the files that are in your new current directory.

    ls

### With Options

Most commands accept _options_, also known as _flags_ or _switches_, that modify the behavior of the command. As they are special arguments, options follow a command, and are indicated by a single `-` character followed by one or more _options_, which are represented by individual upper- or lower-case letters. Additionally, some options start with `--`, followed by a single, multi-character (usually a descriptive word) option.

For a basic example of how options work, let’s look at the `ls` command. Here are a couple of common options that come in handy when using `ls`:

- `-l`: print a “long listing”, which includes extra details such as permissions, ownership, file sizes, and timestamps
- `-a`: list _all_ of a directory’s files, including hidden ones (that start with `.`)

To use the `-l` flag with `ls`, use this command:

    ls -l

Note that the listing includes the same files as before, but with additional information about each file.

As mentioned earlier, options can often be grouped together. If you want to use the `-l` and `-a` option together, you could run `ls -l -a`, or just combine them like in this command:

    ls -la

Note that the listing includes the hidden `.` and `..` directories in the listing, because of the `-a` option.

### With Options and Arguments

Options and arguments can almost always be combined, when running commands.

For example, you could check the contents of `/home`, regardless of your current directory, by running this `ls` command:

    ls -la /home

`ls` is the command, `-la` are the options, and `/home` is the argument that indicates which file or directory to list. This should print a detailed listing of the `/home` directory, which should contain the home directories of all of the normal users on the server.

## Environment Variables

Environment variables are named values that are used to change how commands and processes are executed. When you first log in to a server, several environment variables will be set according to a few configuration files by default.

### View All Environment Variables

To view all of the environment variables that are set for a particular terminal session, run the `env` command:

    env

There will likely be a lot of output, but try and look for `PATH` entry:

    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

The `PATH` environment variable is a colon-delimited list of directories where the shell will look for executable programs or scripts when a command is issued. For example, the `env` command is located in `/usr/bin`, and we are able to execute it without specifying its fully-qualified location because its path is in the `PATH` environment variable.

### View the Value of a Variable

The value of an environment variable can be retrieved by prefixing the variable name with a `$`. Doing so will expand the referenced variable to its value.

For example, to print out the value of the `PATH` variable, you may use the `echo` command:

    echo $PATH

Or you could use the `HOME` variable, which is set to your user’s home directory by default, to change to your home directory like this:

    cd $HOME

If you try to access an environment variable that hasn’t been set, it will be expanded to nothing; an empty string.

### Setting Environment Variables

Now that you know how to view your environment variables, you should learn how to set them.

To set an environment variable, all you need to do is start with a variable name, followed immediately by an `=` sign, followed immediately by its desired value:

    VAR=value

Note that if you set an existing variable, the original value will be overwritten. If the variable did not exist in the first place, it will be created.

Bash includes a command called `export` which exports a variable so it will be inherited by child processes. In simple terms, this allows you to use scripts that reference an exported environment variable from your current session. If you’re still unclear on what this means, don’t worry about it for now.

You can also reference existing variables when setting a variable. For example, if you installed an application to `/opt/app/bin`, you could add that directory to the end of your `PATH` environment variable with this command:

    export PATH=$PATH:/opt/app/bin

Now verify that `/opt/app/bin` has been added to the end of your `PATH` variable with `echo`:

    echo $PATH

Keep in mind that setting environment variables in this way only sets them for your current session. This means if you log out or otherwise change to another session, the changes you made to the environment will not be preserved. There is a way to permanently change environment variables, but this will be covered in a later tutorial.

## Conclusion

Now that you have learned about the basics of the Linux terminal (and a few commands), you should have a good foundation for expanding your knowledge of Linux commands. Read the [next tutorial in this series](basic-linux-navigation-and-file-management) to learn how to navigate, view, and edit files and their permissions.
