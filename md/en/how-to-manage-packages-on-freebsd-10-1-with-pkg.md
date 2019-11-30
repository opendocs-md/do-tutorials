---
author: Mitchell Anicas
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-packages-on-freebsd-10-1-with-pkg
---

# How To Manage Packages on FreeBSD 10.1 with Pkg

## Introduction

FreeBSD’s binary package manager, **pkg** , can be used to easily manage the installation of pre-compiled applications, the FreeBSD equivalent Debian and RPM packages. When compared with the other prevalent method of software installation on FreeBSD, compiling **ports** with the Ports Collection, using packages provides a simpler and faster alternative that works in many situations. Packages, however, are not as flexible as ports because package installations cannot be customized—if you have the need to customize the compilation options of your software installations, use [ports](how-to-install-and-manage-ports-on-freebsd-10-1) instead of packages.

In this tutorial, we will show you how to manage packages on FreeBSD 10.1. This includes installing and deleting packages, among other related tasks.

## Prerequisites

To use the commands in this tutorial, you must have **root** access to a FreeBSD server. That is, you must be able to log in to the server as root or another user that has superuser privileges via the sudo command. If you are planning on using root, you may omit the `sudo` portion of the example commands.

## How To Install New Packages with Pkg

If you know the name of the package that you want to install, you can install it by using the `pkg` command like this:

    sudo pkg install package_name

You may also specify multiple packages to install, separated by spaces, like this:

    sudo pkg install package1 package2 ...

As an example, let’s install Nginx, a popular web server, with `pkg`:

    sudo pkg install nginx

Running this command will initiate the installation of the package you specified. First, your system will check for package repository catalog updates. If it is already fully updated, then search for the specified package. If the package is found, the package and the packages it depends on will be listed. A confirmation prompt will then appear.

In this case, only the `nginx` package will be installed. Respond to the prompt with `y` to confirm:

    New packages to be INSTALLED:
        nginx: 1.6.2_1,2
    
    The process will require 654 KB more space.
    244 KB to be downloaded.
    
    Proceed with this action? [y/N]: y

After confirming the package installation, the listed package(s) will be downloaded and installed on the system. Some packages will display important post-installation information or instructions regarding the use of the application, after the installation—be sure to follow any post-installation notes.

If you are using the default shell, `tcsh`, or `csh`, you should rebuild the list of binaries in your `PATH` with this command:

    rehash

It is also important to note that applications that are _services_ do not automatically start, nor are they enabled as a service, after being installed. Let’s look at how to run services now.

## How To Run Services

On FreeBSD, services that are installed with packages provide a service initialization script in `/usr/local/etc/rc.d`. In the example case of Nginx, which runs as a service, the startup script is called `nginx`. Note that you should substitute the appropriate service script name, instead of the highlighted “nginx”, when running the commands.

To demonstrate what happens if you attempt to start a service that is not enabled, try using the `service` command to start your software immediately after installing it:

    sudo service nginx start

The service will not start and you will encounter a message that looks like the following:

    Cannot 'start' nginx. Set nginx_enable to YES in /etc/rc.conf or use 'onestart' instead of 'start'.

To enable the service, follow the directions in the message and add the following line to `/etc/rc.conf`:

    nginx_enable="YES"

You may either open `/etc/rc.conf` in an editor and add the line, or use the `sysrc` utility to update the file like this:

    sudo sysrc nginx_enable=yes

Now the service is enabled. It will start when your system boots, and you may use the `start` subcommand that was attempted earlier:

    sudo service nginx start

If you want to run the service once, without enabling it, you may use the `onestart` subcommand. Starting a service in this fashion will run the startup script immediately, but it will not be started upon system boot. Try it now:

    sudo service nginx onestart

Using the `onestart` subcommand is useful if you want to test the configuration of your services before enabling them.

## How To View Package Information with Pkg

To view information about **installed** packages, you may use the `pkg info` command, like this:

    pkg info package_name

This will print various information about the specified package including a description of the software, the options it was compiled with, and a list of the libraries that it depends on.

## How To Upgrade Installed Packages with Pkg

You may install the latest available versions of your system’s installed packages with this command:

    sudo pkg upgrade

Running this command will compare your installed packages with the versions in the repository catalog, and print a list of the packages that can be updated to a newer version:

    Updating FreeBSD repository catalogue...
    FreeBSD repository is up-to-date.
    All repositories are up-to-date.
    Checking for upgrades (2 candidates): 100%
    Processing candidates (2 candidates): 100%
    The following 2 packages will be affected (of 0 checked):
    
    Installed packages to be UPGRADED:
        python27: 2.7.8_6 -> 2.7.9
        perl5: 5.18.4_10 -> 5.18.4_11
    
    The process will require 2 MB more space.
    23 MB to be downloaded.
    
    Proceed with this action? [y/N]: y

Respond with a `y` to the prompt to proceed to upgrade the listed packages.

## How To Delete Packages with Pkg

If you know the name of the package that you want to delete, you can delete it by using the `pkg` command like this:

    sudo pkg delete package_name

You may also specify multiple packages to delete, separated by spaces, like this:

    sudo pkg delete package1 package2 ...

Let’s delete Nginx package that we installed earlier:

    sudo pkg delete nginx

You will see a message like the following, with a confirmation prompt:

    Checking integrity... done (0 conflicting)
    Deinstallation has been requested for the following 1 packages (of 0 packages in the universe):
    
    Installed packages to be REMOVED:
        nginx-1.6.2_1,2
    
    The operation will free 654 KB.
    
    Proceed with deinstalling packages? [y/N]: y

Respond to the prompt with `y` to confirm the package delete action.

## How To Remove Unused Dependencies

If you delete a package that installed dependencies, the dependencies will still be installed. To remove the packages that are no longer required by any installed packages, run this command:

    sudo pkg autoremove

The list of packages that will be removed will be printed followed by a prompt. Respond `y` to the confirmation prompt if you want to delete the listed packages.

## How To Find Packages with Pkg

To find binary packages that are available in the repository, use the `pkg search` command.

### By Package Name

The most basic way to search is by package name. If you want to search on package name, use the command like this:

    pkg search package_name

For example, to search for packages with “nginx” in the name, use this command:

    pkg search nginx

This will print a list of the packages, including version numbers, with “nginx” in the name:

    nginx-1.6.2_1,2
    nginx-devel-1.7.8
    p5-Nginx-ReadBody-0.07_1
    p5-Nginx-Simple-0.07_1
    p5-Test-Nginx-0.24

If you want to read the detailed package information about the listed packages, use the `-f` option like this:

    pkg search -f package_name

This will print the package information about each package that matches the specified package name.

### By Description

If you’re not sure of the name of the package you want to install, you may also search the descriptions of packages that are available in the repository by specifying the `-D` option. By default, the pattern match is not case-sensitive:

    pkg search -D pattern

For example, to search for all packages with “java” in the description, use the command like this:

    pkg search -D java

This will print the names of all of available packages with the specified pattern in the description field, along with the description.

## How To Learn More About Using Pkg

Pkg is a very flexible utility that can be used in many ways that are not covered in this tutorial. Luckily, it provides an easy way to look up which options and subcommands are available, and what they do.

To print the available options and subcommands, use this command:

    pkg help

To read the man pages for the various subcommands, use `pkg help` and specify the command you want to learn about, like this:

    pkg help subcommand

For example, if you want to learn more about using `pkg search`, enter this command:

    pkg help search

This will pull up a man page that details how to use `pkg search`.

## Conclusion

You should now know enough about using `pkg` to manage binary packages on your FreeBSD server.

If you want to learn more about managing software on your FreeBSD server, be sure to read up on **ports** with this tutorial: [How To Install and Manage Ports on FreeBSD 10.1](how-to-install-and-manage-ports-on-freebsd-10-1).
