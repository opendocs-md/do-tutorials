---
author: Justin Ellingwood
date: 2014-08-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-a-centos-7-server
---

# How To Install Node.js on a CentOS 7 server

## Introduction

Node.js is a Javascript platform for server-side programming. It allows users to easily create networked applications that require backend functionality. By using Javascript as both the client and server language, development can be fast and consistent.

In this guide, we will show you a few different ways of getting Node.js installed on a CentOS 7 server so that you can get started. Most users will want to use the [EPEL installation instructions](how-to-install-node-js-on-a-centos-7-server#InstallNodefromtheEPELRepository) or the [NVM installation steps](how-to-install-node-js-on-a-centos-7-server#InstallNodeUsingtheNodeVersionManager).

## Install Node from Source

One way of acquiring Node.js is to obtain the source code and compile it yourself.

To do so, you should grab the source code from the project’s website. On the [downloads page](http://nodejs.org/download/), right click on the “Source Code” link and click “Copy link address” or whatever similar option your browser gives you.

On your server, use `wget` and paste the link that you copied in order to download the archive file:

    wget http://nodejs.org/dist/v0.10.30/node-v0.10.30.tar.gz

Extract the archive and move into the new directory by typing:

    tar xzvf node-v* && cd node-v*

There are a few packages that we need to download from the CentOS repositories in order to compile the code. Use `yum` to get these now:

    sudo yum install gcc gcc-c++

Now, we can configure and compile the software:

    ./configure
    make

The compilation will take quite awhile. When it is finished, you can install the software onto your system by typing:

    sudo make install

To check that the installation was successful, you can ask Node to display its version number:

    node --version

    v0.10.30

If you see the version number, then the installation was completed successfully.

## Install a Package from the Node Site

Another option for installing Node.js on your server is to simply get the pre-built packages from the Node.js website and install them.

You can find the Linux binary packages [here](http://nodejs.org/download/). Since CentOS 7 only comes in the 64-bit architecture, right click on the link under “Linux Binaries (.tar.gz)” labeled “64-bit”. Select “Copy link address” or whatever similar option your browser provides.

On your server, change to your home directory and use the `wget` utility to download the files. Paste the URL you just copied as the argument for the command:

    cd ~
    wget http://nodejs.org/dist/v0.10.30/node-v0.10.30-linux-x64.tar.gz

**Note** : Your version number in the URL is likely to be different than the one above. Use the address you copied from the Node.js site rather than the specific URL provided in this guide.

Next, we will extract the binary package into our system’s local package hierarchy with the `tar` command. The archive is packaged within a versioned directory, which we can get rid of by passing the `--strip-components 1` option. We will specify the target directory of our command with the `-C` command:

    sudo tar --strip-components 1 -xzvf node-v* -C /usr/local

This will install all of the components within the `/usr/local` branch of your system.

You can verify that the installation was successful by asking Node for its version number:

    node --version

    v0.10.30

The installation was successful and you can now begin using Node.js on your CentOS 7 server.

## Install Node from the EPEL Repository

An alternative installation method uses the **EPEL** (Extra Packages for Enterprise Linux) repository that is available for CentOS and related distributions.

To gain access to the EPEL repo, you must modify the repo-list of your installation. Fortunately, we can reconfigure access to this repository by installing a package available in our current repos called `epel-release`.

    sudo yum install epel-release

Now that you have access to the EPEL repository, you can install Node.js using your regular `yum` commands:

    sudo yum install nodejs

Once again, you can check that the installation was successful by asking Node to return its version number:

    node --version

    v0.10.30

Many people will also want access to `npm` to manage their Node packages. You can also get this from EPEL by typing:

    sudo yum install npm

## Install Node Using the Node Version Manager

Another way of installing Node.js that is particularly flexible is through NVM, the Node version manager. This piece of software allows you to install and maintain many different independent versions of Node.js, and their associated Node packages, at the same time.

To install NVM on your CentOS 7 machine, visit [the project’s GitHub page](https://github.com/creationix/nvm). Copy the `curl` or `wget` command from the README file that displays on the main page. This will point you towards the most recent version of the installation script.

Before piping the command through to `bash`, it is always a good idea to audit the script to make sure it isn’t doing anything you don’t agree with. You can do that by removing the `| bash` segment at the end of the `curl` command:

    curl https://raw.githubusercontent.com/creationix/nvm/v0.13.1/install.sh

Take a look and make sure you are comfortable with the changes it is making. When you are satisfied, run the command again with `| bash` appended at the end. The URL you use will change depending on the latest version of NVM, but as of right now, the script can be downloaded and executed by typing:

    curl https://raw.githubusercontent.com/creationix/nvm/v0.13.1/install.sh | bash

This will install the `nvm` script to your user account. To use it, you must first source your `.bash_profile`:

    source ~/.bash_profile

Now, you can ask NVM which versions of Node it knows about:

    nvm list-remote

    . . .
    v0.10.29
    v0.10.30
     v0.11.0
     v0.11.1
     v0.11.2
     v0.11.3
     v0.11.4
     v0.11.5
     v0.11.6
     v0.11.7
     v0.11.8
     v0.11.9
    v0.11.10
    v0.11.11
    v0.11.12
    v0.11.13

You can install a version of Node by typing any of the releases you see. For instance, to get version 0.10.30, you can type:

    nvm install v0.10.30

You can see the different versions you have installed by typing:

    nvm list

    -> v0.10.30
          system

You can switch between them by typing:

    nvm use v0.10.30

    Now using node v0.10.30

To set this version as the default, type:

    nvm alias default v0.10.30

    default -> v0.10.30

You can verify that the install was successful using the same technique from the other sections, by typing:

    node --version

    v0.10.30

From the version number output, we can tell that Node is installed on our machine as we expected.

## Conclusion

As you can see, there are quite a few different ways of getting Node.js up and running on your CentOS 7 server. If one of the installation methods is giving you problems, try one of the other options.
