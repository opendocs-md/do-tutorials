---
author: Mitchell Anicas
date: 2014-11-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-linux-permissions
---

# An Introduction to Linux Permissions

## Introduction

Linux is a multi-user OS that is based on the Unix concepts of _file ownership_ and _permissions_ to provide security at the file system level. If you are planning to improve your Linux skills, it is essential that you have a decent understanding of how ownership and permissions work. There are many intricacies when dealing with file ownership and permissions, but we will try our best to distill the concepts down to the details that are necessary for a foundational understanding of how they work.

In this tutorial, we will cover how to view and understand Linux ownership and permissions. If you are looking for a tutorial on how to modify permissions, check out this guide: [Linux Permissions Basics and How to Use Umask on a VPS](linux-permissions-basics-and-how-to-use-umask-on-a-vps#types-of-permissions)

## Prerequisites

Make sure you understand the concepts covered in the prior tutorials in this series:

- [An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)
- [Basic Linux Navigation and File Management](basic-linux-navigation-and-file-management)

Access to a Linux server is not strictly necessary to follow this tutorial, but having one to use will let you get some first-hand experience. If you want to set one up, [check out this link](how-to-create-your-first-digitalocean-droplet-virtual-server) for help.

## About Users

As mentioned in the introduction, Linux is a multi-user system. We must understand the basics of Linux _users_ and _groups_ before we can talk about ownership and permissions, because they are the entities that the ownership and permissions apply to. Let’s get started with the basics of what users are.

In Linux, there are two types of users: _system users_ and _regular users_. Traditionally, system users are used to run non-interactive or background processes on a system, while regular users used for logging in and running processes interactively. When you first log in to a Linux system, you may notice that it starts out with many system users that run the services that the OS depends on–this is completely normal.

An easy way to view all of the users on a system is to look at the contents of the `/etc/passwd` file. Each line in this file contains information about a single user, starting with its _user name_ (the name before the first `:`). Print the `passwd` file with this command:

    cat /etc/passwd

### Superuser

In addition to the two user types, there is the _superuser_, or _root_ user, that has the ability to override any file ownership and permission restrictions. In practice, this means that the superuser has the rights to access anything on its own server. This user is used to make system-wide changes, and must be kept secure.

It is also possible to configure other user accounts with the ability to assume “superuser rights”. In fact, creating a normal user that has `sudo` privileges for system administration tasks is considered to be best practice.

## About Groups

Groups are collections of zero or more users. A user belongs to a default group, and can also be a member of any of the other groups on a server.

An easy way to view all the groups and their members is to look in the `/etc/group` file on a server. We won’t cover group management in this article, but you can run this command if you are curious about your groups:

    cat /etc/group

Now that you know what users and groups are, let’s talk about file ownership and permissions!

## Viewing Ownership and Permissions

In Linux, each and every file is owned by a single user and a single group, and has its own access permissions. Let’s look at how to view the ownership and permissions of a file.

The most common way to view the permissions of a file is to use `ls` with the long listing option, e.g. `ls -l myfile`. If you want to view the permissions of all of the files in your current directory, run the command without an argument, like this:

    ls -l

**Hint:** If you are in an empty home directory, and you haven’t created any files to view yet, you can follow along by listing the contents of the `/etc` directory by running this command: `ls -l /etc`

Here is an example screenshot of what the output might look like, with labels of each column of output:

![ls -l](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/linux_basics/ls-l.png)

Note that each file’s mode (which contains permissions), owner, group, and name are listed. Aside from the _Mode_ column, this listing is fairly easy to understand. To help explain what all of those letters and hyphens mean, let’s break down the _Mode_ column into its components.

## Understanding Mode

To help explain what all the groupings and letters mean, take a look at this closeup of the _mode_ of the first file in the example above:

![Mode and permissions breakdown](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/linux_basics/mode.png)

### File Type

In Linux, there are two basic types of files: _normal_ and _special_. The file type is indicated by the first character of the _mode_ of a file–in this guide, we refer to this as the _file type field_.

Normal files can be identified by files with a hyphen (`-`) in their file type fields. Normal files are just plain files that can contain data. They are called normal, or regular, files to distinguish them from special files.

Special files can be identified by files that have a non-hyphen character, such as a letter, in their file type fields, and are handled by the OS differently than normal files. The character that appears in the file type field indicates the kind of special file a particular file is. For example, a directory, which is the most common kind of special file, is identified by the `d` character that appears in its file type field (like in the previous screenshot). There are several other kinds of special files but they are not essential what we are learning here.

### Permissions Classes

From the diagram, we know that _Mode_ column indicates the file type, followed by three triads, or classes, of permissions: user (owner), group, and other. The order of the classes is consistent across all Linux distributions.

Let’s look at which users belong to each permissions class:

- **User** : The _owner_ of a file belongs to this class
- **Group** : The members of the file’s group belong to this class
- **Other** : Any users that are not part of the _user_ or _group_ classes belong to this class.

### Reading Symbolic Permissions

The next thing to pay attention to are the sets of three characters, or triads, as they denote the permissions, in symbolic form, that each class has for a given file.

In each triad, read, write, and execute permissions are represented in the following way:

- **Read** : Indicated by an `r` in the first position
- **Write** : Indicated by a `w` in the second position
- **Execute** : Indicated by an `x` in the third position. In some special cases, there may be a different character here

A hyphen (`-`) in the place of one of these characters indicates that the respective permission is not available for the respective class. For example, if the _group_ triad for a file is `r--`, the file is “read-only” to the group that is associated with the file.

## Understanding Read, Write, Execute

Now that you know how to read which permissions of a file, you probably want to know what each of the permissions actually allow users to do. We will explain each permission individually, but keep in mind that they are often used in combination with each other to allow for meaningful access to files and directories.

Here is a quick breakdown of the access that the three basic permission types grant a user.

### Read

For a normal file, read permission allows a user to view the contents of the file.

For a directory, read permission allows a user to view the names of the file in the directory.

### Write

For a normal file, write permission allows a user to modify and delete the file.

For a directory, write permission allows a user to delete the directory, modify its contents (create, delete, and rename files in it), and modify the contents of files that the user can read.

### Execute

For a normal file, execute permission allows a user to execute a file (the user must also have read permission). As such, execute permissions must be set for executable programs and shell scripts before a user can run them.

For a directory, execute permission allows a user to access, or traverse, into (i.e. `cd`) and access metadata about files in the directory (the information that is listed in an `ls -l`).

## Examples of Modes (and Permissions)

Now that know how to read the mode of a file, and understand the meaning of each permission, we will present a few examples of common modes, with brief explanations, to bring the concepts together.

- `-rw-------`: A file that is only accessible by its owner
- `-rwxr-xr-x`: A file that is executable by every user on the system. A “world-executable” file
- `-rw-rw-rw-`: A file that is open to modification by every user on the system. A “world-writable” file
- `drwxr-xr-x`: A directory that every user on the system can read and access
- `drwxrwx---`: A directory that is modifiable (including its contents) by its owner and group
- `drwxr-x---`: A directory that is accessible by its group

As you may have noticed, the owner of a file usually enjoys the most permissions, when compared to the other two classes. Typically, you will see that the _group_ and _other_ classes only have a subset of the owner’s permissions (equivalent or less). This makes sense because files should only be accessible to users who need access to them for a particular reason.

Another thing to note is that even though many permissions combinations are possible, only certain ones make sense in most situations. For example, _write_ or _execute_ access is almost always accompanied by _read_ access, since it’s hard to modify, and impossible to execute, something you can’t read.

## Modifying Ownership and Permissions

To keep this tutorial simple, we will not cover how to modify file ownership and permissions here. To learn how to use `chown`, `chgrp`, and `chmod` to accomplish these tasks, refer to this guide: [Linux Permissions Basics and How to Use Umask on a VPS](linux-permissions-basics-and-how-to-use-umask-on-a-vps#types-of-permissions).

## Conclusion

You should now have a good understanding of how ownership and permissions work in Linux. If you would like to learn more about Linux basics, it is highly recommended that you read the next tutorial in this series:

- [An Introduction to Linux I/O Redirection](an-introduction-to-linux-i-o-redirection)
