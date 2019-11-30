---
author: Brian Hogan
date: 2016-12-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-debian-8
---

# How To Install Node.js on Debian 8

## Introduction

[Node.js](https://nodejs.org/) is a JavaScript platform for general-purpose programming that allows users to build network applications quickly. By leveraging JavaScript on both the front-end and the back-end, development can be more consistent and be designed within the same system.

In this guide, you’ll install Node.js on a Debian 8 server. Debian 8 contains a version of Node.js in its default repositories, but this version is outdated, so you’ll explore two methods to install the latest version of Node.js on your system.

## Prerequisites

To follow this tutorial, you need:

- A Debian 8 server with a non-root user with `sudo` privileges. You can set up a user with these privileges in our [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8) guide.

## How To Install Using a PPA

The quickest and easiest way to get the most recent version of Node.js on your server is to add the PPA (personal package archive) maintained by NodeSource. This will have more up-to-date versions of Node.js than the official Debian repositories. It also lets you choose between Node.js v4.x (the older long-term support version, supported until April of 2017), v6.x (the more recent LTS version, which will be supported until April of 2018), and Node.js v7.x (the current actively developed version).

First, install the PPA in order to get access to its contents. Make sure you’re in your home directory, and use `curl` to retrieve the installation script for your preferred version, making sure to replace `6.x` with the correct version string:

    cd ~
    curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh

You can inspect the contents of this script with `nano` (or your preferred text editor):

    nano nodesource_setup.sh

And run the script under `sudo`:

    sudo bash nodesource_setup.sh

The PPA will be added to your configuration and your local package cache will be updated automatically. After running the setup script from nodesource, you can install the Node.js package in the same way that you did above:

    sudo apt-get install nodejs

The `nodejs` package contains the `nodejs` binary as well as `npm`, so you don’t need to install `npm` separately. However, in order for some `npm` packages to work (such as those that require compiling code from source), you will need to install the `build-essential` package:

    sudo apt-get install build-essential

## How To Install Using nvm

An alternative to installing Node.js through `apt` is to use a specially designed tool called nvm, which stands for “Node.js version manager”. Using nvm, you can install multiple, self-contained versions of Node.js which will allow you to control your environment easier. It will give you on-demand access to the newest versions of Node.js, but will also allow you to target previous releases that your app may depend on.

To start off, we’ll need to get the software packages from our Debian repositories that will allow us to build source packages. The `nvm` command will leverage these tools to build the necessary components:

    sudo apt-get update
    sudo apt-get install build-essential libssl-dev

Once the prerequisite packages are installed, you can pull down the nvm installation script from the [project’s GitHub page](https://github.com/creationix/nvm). The version number may be different, but in general, you can download it with `curl`:

    curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh -o install_nvm.sh

And inspect the installation script with `nano`:

    nano install_nvm.sh

Run the script with `bash`:

    bash install_nvm.sh

It will install the software into a subdirectory of your home directory at `~/.nvm`. It will also add the necessary lines to your `~/.profile` file to make the `nvm` command available.

To gain access to the `nvm` command and its functionality, you’ll need to log out and log back in again, or you can source the `~/.profile` file so that your current session knows about the changes:

    source ~/.profile

Now that you have nvm installed, you can install isolated Node.js versions.

To find out the versions of Node.js that are available for installation, you can type:

    nvm ls-remote

    Output...
             v6.8.0
             v6.8.1
             v6.9.0 (LTS: Boron)
             v6.9.1 (LTS: Boron)
             v6.9.2 (Latest LTS: Boron)
             v7.0.0
             v7.1.0
             v7.2.0

As you can see, the newest version at the time of this writing is v7.2.0, but v6.9.2 is the latest long-term support release. You can install that by typing:

    nvm install 6.9.2

You’ll see the following output:

    OutputComputing checksum with sha256sum
    Checksums matched!
    Now using node v6.9.2 (npm v3.10.9)
    Creating default alias: default -> 6.9.2 (-> v6.9.2)

Usually, nvm will switch to use the most recently installed version. You can explicitly tell nvm to use the version we just downloaded by typing:

    nvm use 6.9.2

You can see the version currently being used by the shell by typing:

    node -v

    Outputv6.9.2

If you have multiple Node.js versions, you can see which ones are installed by typing:

    nvm ls

If you wish to make one of the versions the default, you can type:

    nvm alias default 6.9.2

This version will be automatically selected when you open a new terminal session. You can also reference it by the alias like this:

    nvm use default

Each version of Node.js will keep track of its own packages and has `npm` available to manage these.

You can have `npm` install packages to the Node.js project’s `./node_modules` directory by using the normal format. For example, for the `express` module:

    npm install express

If you’d like to install it globally (making it available to the other projects using the same Node.js version), you can add the `-g` flag:

    npm install -g express

This will install the package in:

    ~/.nvm/node_version/lib/node_modules/package_name

Installing globally will let you run the commands from the command line, but you’ll have to link the package into your local sphere to require it from within a program:

    npm link express

You can learn more about the options available to you with nvm by typing:

    nvm help

## Conclusion

As you can see, there are a quite a few ways to get up and running with Node.js on your Debian 8 server. Your circumstances will dictate which of the above methods is the best idea for your circumstance. While the packaged version in Ubuntu’s repository is the easiest, the `nvm` method is definitely much more flexible.
