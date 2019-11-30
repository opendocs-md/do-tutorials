---
author: Kathleen Juell, Brennen Bearnes
date: 2018-09-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-debian-9
---

# How To Install Node.js on Debian 9

## Introduction

[Node.js](https://nodejs.org/en/) is a JavaScript platform for general-purpose programming that allows users to build network applications quickly. By leveraging JavaScript on both the front and backend, Node.js makes development more consistent and integrated.

In this guide, we’ll show you how to get started with Node.js on a Debian 9 server.

## Prerequisites

This guide assumes that you are using Debian 9. Before you begin, you should have a non-root user account with sudo privileges set up on your system. You can learn how to set this up by following the [initial server setup for Debian 9](initial-server-setup-with-debian-9).

## Installing the Distro-Stable Version for Debian

Debian contains a version of Node.js in its default repositories. At the time of writing, this version is 4.8.2, which will reach end-of-life at the end of April 2018. If you would like to experiment with the language using a stable and sufficient option, then installing from the repositories may make sense. It is recommended, however, that for development and production use cases you install a more recent version with a PPA. We will discuss how to install from a PPA in the next step.

To get the distro-stable version of Node.js, you can use the `apt` package manager. First, refresh your local package index:

    sudo apt update

Then install the Node.js package from the repositories:

    sudo apt install nodejs

If the package in the repositories suits your needs, then this is all you need to do to get set up with Node.js.

To check which version of Node.js you have installed after these initial steps, type:

    nodejs -v

Because of a conflict with another package, the executable from the Debian repositories is called `nodejs` instead of `node`. Keep this in mind as you are running software.

Once you have established which version of Node.js you have installed from the Debian repositories, you can decide whether or not you would like to work with different versions, package archives, or version managers. Next, we’ll discuss these elements, along with more flexible and robust methods of installation.

## Installing Using a PPA

To work with a more recent version of Node.js, you can add the _PPA_ (personal package archive) maintained by NodeSource. This will have more up-to-date versions of Node.js than the official Debian repositories, and will allow you to choose between Node.js v4.x (the older long-term support version, which will be supported until the end of April 2018), Node.js v6.x (supported until April of 2019), Node.js v8.x (the current LTS version, supported until December of 2019), and Node.js v10.x (the latest version, supported until April of 2021).

Let’s first update the local package index and install `curl`, which you will use to access the PPA:

    sudo apt update
    sudo apt install curl

Next, let’s install the PPA in order to get access to its contents. From your home directory, use `curl` to retrieve the installation script for your preferred version, making sure to replace `10.x` with your preferred version string (if different):

    cd ~
    curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh

You can inspect the contents of this script with `nano` or [your preferred text editor](initial-server-setup-with-debian-9#step-six-%E2%80%94-completing-optional-configuration):

    nano nodesource_setup.sh

Run the script under `sudo`:

    sudo bash nodesource_setup.sh

The PPA will be added to your configuration and your local package cache will be updated automatically. After running the setup script, you can install the Node.js package in the same way you did above:

    sudo apt install nodejs

To check which version of Node.js you have installed after these initial steps, type:

    nodejs -v

    Outputv10.9.0

The `nodejs` package contains the `nodejs` binary as well as `npm`, so you don’t need to install `npm` separately.

`npm` uses a configuration file in your home directory to keep track of updates. It will be created the first time you run `npm`. Execute this command to verify that `npm` is installed and to create the configuration file:

    npm -v

    Output6.2.0

In order for some `npm` packages to work (those that require compiling code from source, for example), you will need to install the `build-essential` package:

    sudo apt install build-essential

You now have the necessary tools to work with `npm` packages that require compiling code from source.

## Installing Using NVM

An alternative to installing Node.js through `apt` is to use a tool called `nvm`, which stands for “Node.js Version Manager”. Rather than working at the operating system level, `nvm` works at the level of an independent directory within your home directory. This means that you can install multiple self-contained versions of Node.js without affecting the entire system.

Controlling your environment with `nvm` allows you to access the newest versions of Node.js and retain and manage previous releases. It is a different utility from `apt`, however, and the versions of Node.js that you manage with it are distinct from those you manage with `apt`.

To download the `nvm` installation script from the [project’s GitHub page](https://github.com/creationix/nvm), you can use `curl`. Note that the version number may differ from what is highlighted here:

    curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh -o install_nvm.sh

Inspect the installation script with `nano`:

    nano install_nvm.sh

Run the script with `bash`:

    bash install_nvm.sh

It will install the software into a subdirectory of your home directory at `~/.nvm`. It will also add the necessary lines to your `~/.profile` file to use the file.

To gain access to the `nvm` functionality, you’ll need to either log out and log back in again or source the `~/.profile` file so that your current session knows about the changes:

    source ~/.profile

With `nvm` installed, you can install isolated Node.js versions. For information about the versions of Node.js that are available, type:

    nvm ls-remote

    Output...
             v8.11.1 (Latest LTS: Carbon)
             v9.0.0
             v9.1.0
             v9.2.0
             v9.2.1
             v9.3.0
             v9.4.0
             v9.5.0
             v9.6.0
             v9.6.1
             v9.7.0
             v9.7.1
             v9.8.0
             v9.9.0
            v9.10.0
            v9.10.1
            v9.11.0
            v9.11.1
            v10.0.0  
            v10.1.0
            v10.2.0
            v10.2.1
            v10.3.0
            v10.4.0
            v10.4.1
            v10.5.0
            v10.6.0
            v10.7.0
            v10.8.0
            v10.9.0

As you can see, the current LTS version at the time of this writing is v8.11.1. You can install that by typing:

    nvm install 8.11.1

Usually, `nvm` will switch to use the most recently installed version. You can tell `nvm` to use the version you just downloaded by typing:

    nvm use 8.11.1

When you install Node.js using `nvm`, the executable is called `node`. You can see the version currently being used by the shell by typing:

    node -v

    Outputv8.11.1

If you have multiple Node.js versions, you can see what is installed by typing:

    nvm ls

If you wish to default one of the versions, type:

    nvm alias default 8.11.1

This version will be automatically selected when a new session spawns. You can also reference it by the alias like this:

    nvm use default

Each version of Node.js will keep track of its own packages and has `npm` available to manage these.

You can also have `npm` install packages to the Node.js project’s `./node_modules` directory. Use the following syntax to install the `express` module:

    npm install express

If you’d like to install the module globally, making it available to other projects using the same version of Node.js, you can add the `-g` flag:

    npm install -g express

This will install the package in:

    ~/.nvm/versions/node/node_version/lib/node_modules/express

Installing the module globally will let you run commands from the command line, but you’ll have to link the package into your local sphere to require it from within a program:

    npm link express

You can learn more about the options available to you with nvm by typing:

    nvm help

## Removing Node.js

You can uninstall Node.js using `apt` or `nvm`, depending on the version you want to target. To remove versions installed from the repositories or from the PPA, you will need to work with the `apt` utility at the system level.

To remove either of these versions, type the following:

    sudo apt remove nodejs

This command will remove the package and the configuration files.

To uninstall a version of Node.js that you have enabled using `nvm`, first determine whether or not the version you would like to remove is the current active version:

    nvm current

If the version you are targeting is **not** the current active version, you can run:

    nvm uninstall node_version

This command will uninstall the selected version of Node.js.

If the version you would like to remove **is** the current active version, you must first deactivate `nvm` to enable your changes:

    nvm deactivate

You can now uninstall the current version using the `uninstall` command above, which will remove all files associated with the targeted version of Node.js except the cached files that can be used for reinstallation.

## Conclusion

There are a quite a few ways to get up and running with Node.js on your Debian 9 server. Your circumstances will dictate which of the above methods is best for your needs. While using the packaged version in the Debian repository is an option for experimentation, installing from a PPA and working with `npm` or `nvm` offers additional flexibility.
