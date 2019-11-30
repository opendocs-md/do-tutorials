---
author: Justin Ellingwood
date: 2014-11-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/ubuntu-and-debian-package-management-essentials
---

# Ubuntu and Debian Package Management Essentials

## Introduction

Package management is one of the fundamental advantages that Linux systems provide. The packaging format and the package management tools differ from distribution to distribution, but two general families have emerged as the most common.

For RHEL-based distributions, the RPM packaging format and packaging tools like `rpm` and `yum` are common. The other major family, used by Debian, Ubuntu, and related distributions, uses the `.deb` packaging format and tools like `apt` and `dpkg`. This latter group is the family that we will be discussing in this guide.

In this cheat sheet-style guide, we will cover some of the most common package management tools that system administrators use on Debian and Ubuntu systems. This can be used as a quick reference when you need to know how to accomplish a package management task within these systems.

## How To Use This Guide

This guide will cover the user-level package management tools that are often used on Debian and Ubuntu systems. We will not be covering the tools necessary to create packages due to divergent views on policy between the different distributions and the complexities involved with non-trivial examples.

We will discuss each common tool individually in the Debian Package Management Tools Overview, but the majority of this guide will be organized by function rather than tool. This organization makes more sense since this guide is conceptualized as a functional reference.

To get the most of this guide, keep the following points in mind:

- Read the Debian Package Management Tools Overview section below if you are unfamiliar with the Debian family of package management tools. This will give you a rough overview of what each tool’s purpose is and how they are related.
- Use each section of this guide as necessary to produce the desired affect. This is not procedural, so feel free to jump around to whatever is most relevant for you at the moment.
- Use the Contents menu on the left side of this page (at wide page widths) or your browser’s find function to locate the sections you need.
- Copy and paste the command-line examples given, substituting the values in `red` with your own values.

## Debian Package Management Tools Overview

The Debian/Ubuntu ecosystem employs quite a few different package management tools in order to manage software on the system.

Most of these tools are interrelated and work on the same package databases. Some of these tools attempt to provide high-level interfaces to the packaging system, while other utilities concentrate on providing low-level functionality.

### Apt-get

The `apt-get` command is probably the most often used member of the `apt` suite of packaging tools. Its main purpose is interfacing with remote repositories maintained by the distribution’s packaging team and performing actions on the available packages.

The `apt` suite in general functions by pulling information from remote repositories into a cache maintained on the local system. The `apt-get` command is used to refresh the local cache. It is also used to modify the package state, meaning to install or remove a package from the system.

In general, `apt-get` will be used to update the local cache, and to make modifications to the live system.

### Apt-cache

Another important member of the `apt` suite is `apt-cache`. This utility uses the local cache to query information about the available packages and their properties.

For instance, any time you wish to search for a specific package or a tool that will perform a certain function, `apt-cache` is a good place to start. It can also be informative on what exact package version will be targeted by a procedure. Dependency and reverse dependency information is another area where `apt-cache` is useful.

### Aptitude

The `aptitude` command combines much of the functionality of the above two commands. It has the advantage of operating as a command-line tool, combining the functionality of the two tools above, and can also operate using an ncurses text-based menued interface.

When operating from the command line, most of the commands mirror the abilities of `apt-get` and `apt-cache` exactly. Because of this overlap, we won’t be discussing `aptitude` extensively in this guide. You can often use `aptitude` in place of either `apt-get` or `apt-cache` if you prefer this tool.

### Dpkg

While the previous tools were focused on managing packages maintained in repositories, the `dpkg` command can also be used to operate on individual `.deb` packages. The `dpkg` tool actually is responsible for most of the behind-the-scenes work of the commands above.

Unlike the `apt-*` commands, `dpkg` does not have the ability to resolve dependencies automatically. It’s main feature is the ability to easily work with `.deb` packages directly, and its ability to dissect a package and find out more about its structure. Although it can gather some information about the packages installed on the system, its main purpose is on the individual package level.

### Tasksel

The `tasksel` program is a different type of tool for managing software. Instead of managing individual packages or even applications, `tasksel` focuses on grouping the software together needed to accomplish specific “tasks”.

The organized tasks can be selected using a text-based interface, or they can be targeted just as you’d target packages in conventional packaging tools. While not the most surgical approach, it can be very useful for getting up and running quickly.

### Others

There are many other package management tools available that provide different functionality or present information in different ways. We will only be touching on these as necessary, but they can be very useful in certain situations.

Some of the tools that fall into this category are `apt-file`, `dselect`, and `gdebi`.

## Updating the Package Cache and the System

The Debian and Ubuntu package management tools provide a great way to keep your system’s list of available packages up-to-date. It also provides simple methods of updating packages you currently have installed on your server.

### Update Local Package Cache

The remote repositories that your packaging tools rely on for package information are updated all of the time. However, the majority of the package management tools work with a local cache of this information.

It is usually a good idea to update your local package cache every session before performing other package commands. This will ensure that you are operating on the most up-to-date information about the available software. Even more to the point, some installation commands will fail if you are operating with stale package information.

To update the local cache, use the `apt-get` command with the `update` sub-command:

    sudo apt-get update

This will pull down an updated list of the available packages in the repositories you are tracking.

### Update Packages without Package Removal

The `apt` packaging suite makes it trivial to keep all of the software installed on your server up-to-date.

The `apt` command distinguishes between two different update procedures. The first update procedure (covered in this section) can be used to upgrade any components that do not require component removal. To learn how to update and allow `apt` to remove and swap components as necessary, see the section below.

This can be very important when you do not want to remove any of the installed packages under any circumstance. However, some updates involve replacing system components or removing conflicting files. This procedure will ignore any updates that require package removal:

    sudo apt-get upgrade

After preforming this action, any update that does not involve removing components will be applied.

### Update Packages and Remove As Necessary

The `apt` packaging suite makes it trivial to keep all of the software installed on your server up-to-date.

The `apt` command distinguishes between two different update procedures. The first update procedure ignores any updates that require package removal. This is covered in the above section.

The second procedure (covered in this section) will update all packages, even those that require package removal. This is often necessary as dependencies for packages change.

Usually, the packages being removed will be replaced by functional equivalents during the upgrade procedure, so this is generally safe. However, it is a good idea to keep an eye on the packages to be removed, just in case some essential components are marked for removal. To preform this action, type:

    sudo apt-get dist-upgrade

This will update all packages on your system. It is a more complete upgrade procedure than the last upgrade.

## Downloading and Installing Packages

One of the primary functions of package management tools is to facilitate downloading and installing package onto the system.

### Search for Packages

The first step when downloading and installing packages is often to search your distribution’s repositories for the packages you are looking for.

The majority of `apt` commands operate primarily on the cache of package information that is maintained on the local machine. This allows for quicker execution and less network traffic.

Searching for packages is one operation that targets the package cache for information. The `apt-cache search` sub-command is the tool needed to search for available packages. Keep in mind that you should ensure that your local cache is up-to-date using `sudo apt-get update` prior to searching for packages:

    apt-cache search package

Since this procedure is only querying for information, it does not require `sudo` privileges. Any search preformed will look at the package names, as well as the full descriptions for packages.

For instance, if you search for `htop`, you will see results like these:

    apt-cache search htop

    aha - ANSI color to HTML converter
    htop - interactive processes viewer
    libauthen-oath-perl - Perl module for OATH One Time Passwords

As you can see, we have a package named `htop`, but we also see two other programs, each of which mention `htop` in the full description field of the package (the description next to the output is only a short summary).

### Install a Package from the Repos

To install a package from the repositories, as well as all of the necessary dependencies, we can use the `apt-get` command with the `install` sub-command.

The arguments for this command should be the package name or names as they are labeled in the repository:

    sudo apt-get install package

You can install multiple packages at once, separated by a space:

    sudo apt-get install package1 package2

If your requested package requires additional dependencies, these will be printed to standard out and you will be asked to confirm the procedure. It will look something like this:

    sudo apt-get install apache2

    Reading package lists... Done
    Building dependency tree       
    Reading state information... Done
    The following extra packages will be installed:
      apache2-data
    Suggested packages:
      apache2-doc apache2-suexec-pristine apache2-suexec-custom
      apache2-utils
    The following NEW packages will be installed:
      apache2 apache2-data
    0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
    Need to get 236 kB of archives.
    After this operation, 1,163 kB of additional disk space will be used.
    Do you want to continue [Y/n]?

As you can see, even though our install target was the `apache2` package, the `apache2-data` package is needed as a dependency. In this case, you can continue by pressing ENTER or “y”, or abort the operation by typing “n”.

### Install a Specific Package Version from the Repos

If you need to install a specific version of a package, you can provide the version you would like to target with an equal sign, like this:

    sudo apt-get install package=version

The version in this case must match a one of the package version numbers available in the repository. This means utilizing the versioning scheme employed by your distribution. You can find the available versions by typing `apt-cache policy package`.

### Reconfigure Packages

Many packages include post-installation configuration scripts that are run after the installation is complete. These often include prompts for the administrator to make configuration choices.

If you need to run through these (and additional) configuration steps at a later time, you can use the `dpkg-reconfigure` command. This command looks at the package passed to it and re-runs any post-configuration commands included within the package specification:

    sudo dpkg-reconfigure package

This will allow you access to the same (and often more) prompts that you ran upon installation.

### Perform a Dry Run of Package Actions

Many times, you will want to see the side effects of a procedure before without actually committing to executing the command. Fortunately, `apt` allows you to add the `-s` flag to “simulate” a procedure.

For instance, to see what would be done if you choose to install a package, you can type:

    apt-get install -s package

This will let you see all of the dependencies and the changes to your system that will take place if you remove the `-s` flag. One benefit of this is that you can see the results of a process that would normally require root privileges, without using `sudo`.

For instance, if we want to evaluate what would be installed with the `apache2` package, we can type:

    apt-get install -s apache2

    NOTE: This is only a simulation!
          apt-get needs root privileges for real execution.
          Keep also in mind that locking is deactivated,
          so don't depend on the relevance to the real current situation!
    Reading package lists... Done
    Building dependency tree       
    Reading state information... Done
    The following extra packages will be installed:
      apache2-data
    Suggested packages:
      apache2-doc apache2-suexec-pristine apache2-suexec-custom
      apache2-utils
    The following NEW packages will be installed:
      apache2 apache2-data
    0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
    Inst apache2-data (2.4.6-2ubuntu2.2 Ubuntu:13.10/saucy-updates [all])
    Inst apache2 (2.4.6-2ubuntu2.2 Ubuntu:13.10/saucy-updates [amd64])
    Conf apache2-data (2.4.6-2ubuntu2.2 Ubuntu:13.10/saucy-updates [all])
    Conf apache2 (2.4.6-2ubuntu2.2 Ubuntu:13.10/saucy-updates [amd64])

We get all of the information about the packages and versions that would be installed, without having to complete the actual process.

This also works with other procedures, like doing system upgrades:

    apt-get -s dist-upgrade

### Do Not Prompt for Approval with Package Actions

By default, `apt` will prompt the user for confirmation for many processes. This includes installations that require additional dependencies, and package upgrades.

In order to bypass these upgrades, and defaulting to accept any of these prompts, you can pass the `-y` flag when performing these operations:

    sudo apt-get install -y package

This will install the package and any dependencies without further prompting from the user. This can be used for upgrade procedures as well:

    sudo apt-get dist-upgrade -y

### Fix Broken Dependencies and Packages

There are times when an installation may not finish successfully due to dependencies or other problems. One common scenario where this may happen is when installing a `.deb` package with `dpkg`, which does not resolve dependencies.

The `apt-get` command can attempt to sort out this situation by passing it the `-f` command.

    sudo apt-get install -f

This will search for any dependencies that are not satisfied and attempt to install them to fix the dependency tree. If your installation complained about a dependency problem, this should be your first step in attempting to resolve it.

### Download Package from the Repos

There are main instances where it may be helpful to download a package from the repositories without actually installing it. You can do this with the `download` sub-command of `apt-get`.

Because this is only downloading a file and not impacting the actual system, no `sudo` privileges are required:

    apt-get download package

This will download the specified package(s) to the current directory.

### Download Package Source from Repository

Although `apt` mainly deals with `.deb` packages, you can also get the source files for packages, as long as your `apt` source lists are configured with that information.

To download the source of a package, you must have a corresponding `deb-src` line in your `source.list` file for `apt`. You can find out how to do this in the section on adding apt repositories.

Once you have source repositories configured, you can download the source of a package by typing:

    sudo apt-get source package

This will download the package files to the current directory. Typically this consists of a package directory, a `dsc` description file, and the tarred and compressed package:

    ls -F

    sublime-text-2.0.2/ sublime-text_2.0.2-1~webupd8~3.tar.gz
    sublime-text_2.0.2-1~webupd8~3.dsc

This can be used if you would like to use a distribution’s package as a base for further modifications.

### Install a .deb Package

Although most distributions recommend installing software from their maintained repositories, some vendors supply raw `.deb` files which you can install on your system.

In order to do this, we use a tool called `dpkg`. The `dpkg` tool is mainly used to work with individual packages. It does not attempt to perform installs from the repository, and instead looks for `.deb` packages in the current directory, or the path supplied:

    sudo dpkg --install debfile.deb

It is important to note that the `dpkg` tool does not implement any dependency handling. This means that if there are any unmet dependencies, the installation will fail. Luckily, it marks the dependencies needed, so if all of the dependencies are available within the repositories, you can satisfy them easily by typing this afterwards:

    sudo apt-get install -f

This will install any unmet dependencies, including those marked by `dpkg`.

### Install Software “Tasks” with Tasksel

It’s possible to install large sets of related software through the use of “tasks”. Tasks are simply groups of packages that set up a certain environment when installed together. Examples of tasks include LAMP servers, desktop environments, and application servers.

Some systems may not have the `tasksel` package installed by default. To get it, you can type:

    sudo apt-get update
    sudo apt-get install tasksel

You can select the different task package groups interactively by typing:

    sudo tasksel

This will display an interface allowing you to select different package groups and apply the changes.

You can also print out the list of the available tasks and their install state by typing:

    tasksel --list-task

Afterwards, you can choose to install tasks from the command line by typing:

    sudo tasksel install task_name

## Removing Packages and Deleting Files

The inverse operations to installing and downloading packages are also possible with package managers. This section will discuss how to uninstall packages and clean up the files that may be left behind by package operations.

### Uninstall a Package

In order to remove an installed package, the `remove` sub-command can be given to `apt-get`. This will remove most of the files that the package installed to the system, with one notable exception.

This command leaves configuration files in place so that your configuration will be available if you need to reinstall the application at a later date. This is helpful because it means that the configuration files that you customized won’t be removed if you accidentally get rid of a package.

To complete this operation, you simply need to provide the name of the package you wish to uninstall:

    sudo apt-get remove package

The package will be uninstalled with the exception of your configuration files.

### Uninstall a Package and All Associated Configuration Files

If you wish to remove a package and all associated files from your system, including configuration files, you can use the `purge` sub-command of `apt-get`.

Unlike the `remove` command mentioned above, the `purge` command removes everything. This is useful if you do not want to save the configuration files or if you are having issues and want to start from a clean slate.

Keep in mind that once your configuration files are removed, you won’t be able to get them back:

    sudo apt-get purge package

Now, if you ever need to reinstall that package, the default configuration will be used.

### Remove Any Automatic Dependencies that are No Longer Needed

When removing packages from your system with `apt-get remove` or `apt-get purge`, the package target will be removed. However, any dependencies that were automatically installed in order to fulfill the installation requirements will remain behind.

In order to automatically remove any packages that were installed as dependencies that are no longer required by any packages, you can use the `autoremove` command:

    sudo apt-get autoremove

If you wish to remove all of the associated configuration files from the dependencies being removed, you will want to add the `--purge` option to the `autoremove` command. This will clean up configuration files as well, just like the `purge` command does for a targeted removal:

    sudo apt-get --purge autoremove

### Clean Obsolete Downloaded Package Files

As packages are added and removed from the repositories by a distribution’s package maintainers, some packages will become obsolete.

The `apt-get` tool can remove any package files on the local system that are associated with packages that are no longer available from the repositories by using the `autoclean` command.

This will free up space on your server and allow the cache on your local system to be up-to-date without the cruft that comes from keeping useless information.

    sudo apt-get autoclean

## Getting Information about Packages

Each package contains a large amount of metadata that can be accessed using the package management tools. This section will demonstrate some common ways to get information about available and installed packages.

### Show Information About a Package

To show detailed information about a package in your distribution’s repositories, you can use the `show` sub-command of `apt-cache`. The target of this command is a package name within the repository:

    apt-cache show package

This will information about any installation candidates for the package in question. Each candidate will have information about its dependencies, version, architecture, conflicts, the actual package file name, the size of the package and installation, and a detailed description among other things.

To show additional information about each of the candidates, including a full list of reverse dependencies (a list of packages that depend on the queried package), use the `showpkg` command instead. This will include a lot of information about this package’s relationship to other packages:

    apt-cache showpkg package

### Show Info about a .deb Package

To show details about a `.deb` file, you can user the `--info` flag with the `dpkg` command. The target of this command should be the path to a `.deb` file:

    dpkg --info debfile.deb

This will show you some metadata about the package in question. This includes the package name and version, the architecture it was built for, the size and dependencies required, a description and conflicts.

### Show Dependencies and Reverse Dependencies

To specifically list the dependencies (packages this package relies on) and the reverse dependencies (the packages that rely on this package), you can use the `apt-cache` utility.

For conventional dependency information, you can use the `depends` sub-command:

    apt-cache depends package

This will show information about every package that is listed as a hard dependency, suggestion, recommendation, or conflict.

If you need to find out which packages depend on a certain package, you can pass that package to the `rdepends` sub-command:

    apt-cache rdepends package

### Show Installed and Available Package Versions

Often times, there are multiple versions of a package within the repositories, with a single default package. To see the available versions of a package you can use the `policy` sub-command to `apt-cache`:

    apt-cache policy package

This will show you which version is installed (if any), the candidate which will be installed by default if you do not specify a version with the installation command, and a table of package versions, complete with the weight that indicates each version’s priority.

This can be used to determine what version will be installed and which alternatives are available. Because this also lists the repositories where each version is located, this can be used for determining if any extra repositories or PPAs are superseding the packages from the default repositories.

### Show Installed Packages with dpkg -l

To show the packages installed on your system, you have a few separate options, depending on the format and verbosity of the output you would like.

The first method involves using either the `dpkg` or the `dpkg-query` command with the `-l`. The output from both of these commands is identical. With no arguments, it gives a list of every installed or partially installed package on the system. The output will look like this:

    dpkg -l

    Desired=Unknown/Install/Remove/Purge/Hold
    | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
    |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
    ||/ Name Version Architecture Description
    +++-===========================================-=======================================-============-=====================================================================================================================
    ii account-plugin-generic-oauth 0.10bzr13.03.26-0ubuntu1.1 amd64 GNOME Control Center account plugin for single signon - generic OAuth
    ii accountsservice 0.6.34-0ubuntu6 amd64 query and manipulate user account information
    ii acl 2.2.52-1 amd64 Access control list utilities
    ii acpi-support 0.142 amd64 scripts for handling many ACPI events
    ii acpid 1:2.0.18-1ubuntu2 amd64 Advanced Configuration and Power Interface event daemon
    . . .

The output continues for every package on the system. At the top of the output, you can see the meanings of the first three characters on each line. The first character indicates the desired state of the package. It can be:

- **u** : Unknown
- **i** : Installed
- **r** : Removed
- **p** : Purged
- **h** : Version held

The second character indicates the actual status of the package as known to the packaging system. These can be:

- **n** : Not installed
- **i** : Installed
- **c** : Configuration files are present, but the application is uninstalled.
- **u** : Unpacked. The files are unpacked, but not configured yet.
- **f** : The package is half installed, meaning that there was a failure part way through an installation that halted the operation.
- **w** : The package is waiting for a trigger from a separate package
- **p** : The package has been triggered by another package.

The third character, which will simply be a blank space for most packages, only has one potential other option:

- **r** : This indicates that a re-installation is required. This usually means that the package is broken and in a non-functional state.

The rest of the columns contain the package name, version, architecture, and a description.

### Show Install States of Filtered Packages

If you add a search pattern after the `-l` pattern, `dpkg` will list all packages (whether installed or not) that contain that pattern. For instance, we can search for YAML processing libraries here:

    dpkg -l libyaml*

    Desired=Unknown/Install/Remove/Purge/Hold
    | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
    |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
    ||/ Name Version Architecture Description
    +++-===============-============-============-===================================
    ii libyaml-0-2:amd 0.1.4-2ubunt amd64 Fast YAML 1.1 parser and emitter li
    ii libyaml-dev:amd 0.1.4-2ubunt amd64 Fast YAML 1.1 parser and emitter li
    un libyaml-perl <none> (no description available)
    un libyaml-syck-pe <none> (no description available)
    ii libyaml-tiny-pe 1.51-2 all Perl module for reading and writing

As you can see from the first column, the third and fourth result are not installed. This gives you every package that matches the pattern, as well as its current and desired states.

### Show Installed Packages with dpkg –get-selections

An alternative way to render the packages that are installed on your system is with the `--get-selections` flag with `dpkg`.

This provides a list of all of the packages installed or removed but not purged:

    dpkg --get-selections

To differentiate between these two states, you can use `awk` to filter by state. To see only installed packages, type:

    dpkg --get-selections | awk '$2 ~ /^install/'

To get a list of removed packages that have not had their configuration files purged, you can instead type:

    dpkg --get-selections | awk '$2 !~ /^install/'

### Search Installed Packages

To search your installed package base for a specific package, you can add a package filter string after the `--get-selections` option. This can use wildcards to match. Again, this will show any packages that are installed or that still have configuration files on the system:

    dpkg --get-selections libz*

You can, once again, filter using the `awk` expressions from the last section.

### List Files Installed by a Package

To find out which files a package is responsible for, you can use the `-L` flag with the `dpkg` command:

    dpkg -L package

This will print out the absolute path of each file that is controlled by the package. This will not include any configuration files that are generated by processes within the package.

### Search for What Package Installs to a Location

To find out which package is responsible for a certain file in your filesystem, you can pass the absolute path to the `dpkg` command with the `-S` flag.

This will print out the package that installed the file in question:

    dpkg -S /path/to/file

Keep in mind that any files that are moved into place by post installation scripts cannot be tied back to the package with this technique.

### Find Which Package Provides a File Without Installing It

Using `dpkg`, it is simple to find out which package owns a file using the `-S` option. However, there are times when you may need to know which package provides a file or command, even if you may not have the associated package installed.

To do so, you will need to install a utility called `apt-file`. This maintains its own database of information, which includes the installation path of every file controlled by a package in the database.

Install the utility by typing:

    sudo apt-get update
    sudo apt-get install apt-file

Now, update the tool’s database and search for a file by typing:

    sudo apt-file update
    sudo apt-file search /path/to/file

This will only work for file locations that are installed directly by a package. Any file that is created through post-installation scripts will not be found.

## Transferring Package Lists Between Systems

Many times, you may wish to back up the list of installed packages from one system and use it to install an identical set of packages on a different system. This is also helpful for backup purposes. This section will demonstrate how to export and import package lists.

### Export Package List

If you need to replicate the set of packages installed on one system to another, you will first need to export your package list.

You can export the list of installed packages to a file in the format required to later import them by piping the output of `dpkg --get-selections`:

    dpkg --get-selections > ~/packagelist.txt

This list can then be copied to the second machine and imported.

You also may wish to backup your sources lists and your trusted key list. You can back up your sources by creating a directory with the necessary files and copying them over:

    mkdir ~/sources
    cp -R /etc/apt/sources.list* ~/sources

The trusted keys can be backed up by typing:

    apt-key exportall > ~/trusted_keys.txt

You can now transfer the `packagelist.txt` file, the `sources` directory, and the `trusted_keys.txt` file to another computer to import.

### Import Package List

If you have created a package list using `dpkg --get-selections` as demonstrated above, you can import the packages on another computer using the `dpkg` command as well.

First, you need to add the trusted keys and implement the sources lists you copied from the first computer. Assuming that all of the data you backed up has been copied to the home directory of the new computer, you could type:

    sudo apt-key add ~/trusted_keys.txt
    sudo cp -R ~sources/* /etc/apt/

Next, clear the state of all non-essential packages from the new computer. This will ensure that you are applying the changes to a clean slate. This must be done with the root account or `sudo` privileges:

    sudo dpkg --clear-selections

This will mark all non-essential packages for deinstallation. We should update the local package list so that our installation will have records for all of the software we want to install. The actual installation and upgrade procedure will be handled by a tool called `dselect`.

We should ensure that the `dselect` tool is installed. This tool maintains its own database, so we also need to update that before we can continue:

    sudo apt-get update
    sudo apt-get install dselect
    sudo dselect update

Next, we can apply the package list on top of the current list to configure which packages should be kept or downloaded:

    sudo dpkg --set-selections < packagelist.txt

This sets the package states that we want. To apply the changes, we will perform a `dselect-upgrade`, which is an `apt-get` sub-command:

    sudo apt-get dselect-upgrade

This will download and install any necessary packages. It will also remove any packages marked for deselection. In the end, your package list should match that of the previous computer, although the configuration files will still need to be copied or modified.

## Adding Repositories and PPAs

Although the default set of repositories provided by most distributions contain enough packages for most users, there are times when additional sources may be helpful. In this section, we’ll discuss how to configure your packaging tools to consult additional sources.

### Add PPAs

An alternative to traditional repositories are PPAs, or personal package archives. At the time of this writing, PPAs are only available for Ubuntu systems. Usually, PPAs have a smaller scope than repositories and contain focused sets of applications maintained by the PPA owner.

Adding PPAs to your system allows you to manage the packages they contain with your usual package management tools. This can be used to provide more up-to-date package or packages that are not included with the distribution’s repositories. Take care that you only add PPAs that you trust, as you will be allowing a non-standard maintainer to build packages for your system.

To add a PPA, you can use the `add-apt-repository` command. The target should include the label `ppa:`, followed by the PPA owner’s name on [Launchpad](https://launchpad.net/ubuntu/+ppas), a slash, and the PPA name:

    sudo add-apt-repository ppa:owner_name/ppa_name

You may be asked to accept the packager’s key. Afterwards, the PPA will be added to your system, allowing you to install the packages with the normal `apt` commands. Before searching for or installing packages, make sure to update your local cache with the information about your new PPA:

    sudo apt-get update

### Add Repositories

To add additional repositories to your Ubuntu or Debian system, you can take two different approaches.

The first is to edit the sources lists directly. You can either edit the `/etc/apt/sources.list` file or place a new list in the `/etc/apt/sources.list.d` directory. If you go this latter route, the filename you create must end in `.list`:

    sudo nano /etc/apt/sources.list.d/new_repo.list

Inside the file, you can add the location of the new repository by using the following format:

    deb_or_deb-src url_of_repo release_code_name_or_suite component_names

The different parts of the repository specification are:

- **deb** or **deb-src** : This identifies the type of repository. Conventional repositories are marked with `deb`, while source repositories begin with `deb-src`.
- **url** : The main URL for the repository. This should be the location where the repository can be found.
- **release code name or suite** : This is usually the code name of your distribution’s release, but it can be whatever name is used to identify a specific set of packages created for your version of the distribution.
- **component names** : The labels for the selection of packages you wish to have available. This is often a distinction provided by the repository maintainer to express something about the reliability or licensing restrictions of the software it contains.

You can add these lines within the file. Most repositories will contain information about the exact format that should be used.

The second way to accomplish this is through the use of the `add-apt-repository` command. This is usually included by default on Ubuntu, and for Debian, it can be installed with the `software-properties-common` package:

    sudo apt-get update
    sudo apt-get install software-properties-common

Afterwards, you can supply the lines you want to add to the `add-apt-repository` command. These should be in the same format as you would use for manual additions:

    sudo add-apt-repository 'deb url release component'

Make sure you update your local package cache after applying any repository updates so that your system is aware of the newly available packages:

    sudo apt-get update

## Conclusion

There are many other package management operations that you can perform, but we have tried to cover the most common procedures here. If you have any other favorites, use the comments section below to let us know.
