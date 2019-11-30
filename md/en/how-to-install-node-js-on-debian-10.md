---
author: Brennen Bearnes, Kathleen Juell
date: 2019-08-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-debian-10
---

# How To Install Node.js on Debian 10

## Introduction

[Node.js](https://nodejs.org/en/) is a JavaScript platform for general-purpose programming that allows users to build asynchronous network applications quickly. By leveraging JavaScript on both the front and backend, Node.js can make web application development more consistent and integrated.

In this guide, we’ll show you how to get started with Node.js on a Debian 10 server. We will discuss installing Node from the default Debian repository, using a more up-to-date PPA repository, and using NVM (Node Version Manager) to install and activate different versions of Node.

Finally, we will show how to uninstall these different versions of Node.

## Prerequisites

This guide assumes that you are using Debian 10. Before you begin, you should have a non-root user with sudo privileges set up on your system. You can learn how to set this up by following the [initial server setup for Debian 10](initial-server-setup-with-debian-10) tutorial.

## Installing the Official Debian Node.js Package

Debian contains a version of Node.js in its default repositories. At the time of writing, this version is 10.15.2, which will reach end-of-life on April 1, 2021. At this date it will no longer be supported with security and bug fixes. If you would like to experiment with Node using an easy-to-install, stable, and long-term option, then installing from the Debian repo may make sense.

To get Node.js from the default Debian software repository, you can use the `apt` package manager. First, refresh your local package index:

    sudo apt update

Then install the Node.js package, and `npm` the Node Package Manager:

    sudo apt install nodejs npm

To verify that the install was successful, run the `node` command with the `-v` flag to get the version:

    node -v

    Outputv10.15.2

If you need a more recent version of Node.js than this, the next two sections will explain other installation options.

## Installing Using a PPA

To work with a more recent version of Node.js, you can install from a _PPA_ (personal package archive) maintained by [NodeSource](https://nodesource.com). This is an alternate repository that still works with `apt, and will have more up-to-date versions of Node.js than the official Debian repositories. NodeSource has PPAs available for Node versions from 0.10 through to 12.

Let’s install the PPA now. This will add the repository to our package list and allow us to install the new packages using `apt`.

From your home directory, use `curl` to retrieve the installation script for your preferred Node.js version, making sure to replace `12.x` with your preferred version string (if different):

    cd ~
    curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh

You can inspect the contents of this script with `nano` or your preferred text editor:

    nano nodesource_setup.sh

If everything looks OK, exit your text editor and run the script using `sudo`:

    sudo bash nodesource_setup.sh

The PPA will be added to your configuration and your local package cache will be updated automatically. Now you can install the `nodejs` package in the same way you did in the previous step:

    sudo apt install nodejs

We don’t need to install a separate package for `npm` in this case, as it is included in the `nodejs` packae.

Verify the installation by running `node` with the `-v` version option:

    node -v

    Outputv12.8.0

`npm` uses a configuration file in your home directory to keep track of updates. It will be created the first time you run `npm`. Execute this command to verify that `npm` is installed and to create the configuration file:

    npm -v

    Output6.10.2

In order for some `npm` packages to work (those that require compiling code from source, for example), you will need to install the `build-essential` package:

    sudo apt install build-essential

You now have the necessary tools to work with `npm` packages that require compiling code from source.

## Installing Using NVM

An alternative to installing Node.js through `apt` is to use a tool called `nvm`, which stands for “Node Version Manager”. Rather than working at the operating system level, `nvm` works at the level of an independent directory within your user’s home directory. This means that you can install multiple self-contained versions of Node.js without affecting the entire system.

Controlling your environment with `nvm` allows you to access the newest versions of Node.js while also retaining and managing previous releases. It is a different utility from `apt`, however, and the versions of Node.js that you manage with it are distinct from those you manage with `apt`.

To download the `nvm` installation script from the [project’s GitHub page](https://github.com/creationix/nvm), you can use `curl`. Note that the version number may differ from what is highlighted here:

    curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh -o install_nvm.sh

Inspect the installation script with `nano`:

    nano install_nvm.sh

If the script looks OK, exit your text editor and run the script with `bash`:

    bash install_nvm.sh

We don’t need `sudo` here because `nvm` is not installed into any privileged system directories. It will instead install the software into a subdirectory of your home directory at `~/.nvm`. It will also add some configuration to your `~/.profile` file to enable the new software.

To gain access to the `nvm` functionality, you’ll need to either log out and log back in again or source the `~/.profile` file so that your current session knows about the changes:

    source ~/.profile

With `nvm` installed, you can install isolated Node.js versions. For information about the versions of Node.js that are available, type:

    nvm ls-remote

    Output. . .
           v10.16.2 (Latest LTS: Dubnium)
            v11.0.0
            v11.1.0
            v11.2.0
            v11.3.0
            v11.4.0
            v11.5.0
            v11.6.0
            v11.7.0
            v11.8.0
            v11.9.0
           v11.10.0
           v11.10.1
           v11.11.0
           v11.12.0
           v11.13.0
           v11.14.0
           v11.15.0
            v12.0.0
            v12.1.0
            v12.2.0
            v12.3.0
            v12.3.1
            v12.4.0
            v12.5.0
            v12.6.0
            v12.7.0
            v12.8.0

As you can see, the current LTS version at the time of this writing is v10.16.2. You can install that by typing:

    nvm install 10.16.2

Usually, `nvm` will switch to use the most recently installed version. You can tell `nvm` to use the version you just downloaded by typing:

    nvm use 10.16.2

As always, you can verify the Node.js version currently being used by typing:

    node -v

    Outputv10.16.2

If you have multiple Node.js versions, you can see what is installed by typing:

    nvm ls

If you wish to default to one of the versions, type:

    nvm alias default 10.16.2

This version will be automatically selected when a new session spawns. You can also reference it by the alias like this:

    nvm use default

Each version of Node.js will keep track of its own packages and has `npm` available to manage these.

## Removing Node.js

You can uninstall Node.js using `apt` or `nvm`, depending on the version you want to target. To remove versions installed from the Debian repository or from the PPA, you will need to work with the `apt` utility at the system level.

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

There are a quite a few ways to get up and running with Node.js on your Debian 10 server. Your circumstances will dictate which of the above methods is best for your needs. While using the packaged version in the Debian repository is an option for experimentation, installing from a PPA and working with `npm` or `nvm` offers additional flexibility.
