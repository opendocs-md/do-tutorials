---
author: Justin Ellingwood
date: 2013-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/linux-permissions-basics-and-how-to-use-umask-on-a-vps
---

# Linux Permissions Basics and How to Use Umask on a VPS

## Introduction

Linux permissions allow a file or directory owner to restrict access based on the accessor's relationship to each file. This allows for control schemes that provide varying levels of access to different people.

The _umask_ command is used to determine the default permissions assigned to files created by each user. It can be modified to provide strict security restrictions or relaxed permissions for file sharing scenarios, depending on the needs of the system and user.

This guide will explain the basics of Linux permissions, and will demonstrate the usefulness of configuring umask correctly. It will also briefly cover the _chmod_ command as an associated permissions tool.

### Table of Contents

1. Permissions Categories
  - Owner Permissions
  - Group Permissions
  - Other Permissions
2. Types of Permissions
  - Alphabetic Notation
  - Octal Notation
3. Using the Chmod Command
4. Setting Default Permissions with Umask
5. A Word of Caution

## Permission Categories

Linux permissions can seem obscure and difficult to understand to new users. However, once you are familiar with the way that permissions are represented, it is trivial to read and change the permissions of a file or directory with ease.

### Owner Permissions

The first concept necessary to understand permissions is that Linux is fundamentally a multi-user operating system.

Each file is owned by exactly one user. Even if you are the only person using your VPS, there are still a number of different "users" created to run specific programs. You can see the different users on your system by typing:

    cat /etc/passwd

    root:x:0:0:root:/root:/bin/bash daemon:x:1:1:daemon:/usr/sbin:/bin/sh bin:x:2:2:bin:/bin:/bin/sh sys:x:3:3:sys:/dev:/bin/sh sync:x:4:65534:sync:/bin:/bin/sync games:x:5:60:games:/usr/games:/bin/sh man:x:6:12:man:/var/cache/man:/bin/sh lp:x:7:7:lp:/var/spool/lpd:/bin/sh mail:x:8:8:mail:/var/mail:/bin/sh news:x:9:9:news:/var/spool/news:/bin/sh uucp:x:10:10:uucp:/var/spool/uucp:/bin/sh . . . 

The _/etc/passwd_ file contains a line for every user that has been created on your operating system. The first field on each line is the name of a unique user. As you can see, many of these users are associated with services and applications.

Configuring services to operate as a distinct user allows us to control the service's access by taking advantage of the user permissions assignment. Many programs are configured to create a username and perform all operations using that user.

### Group Permissions

The second category that we can assign permissions to is the "group owner" of the file.

As with the owner category, a file can be owned by exactly one group. Each user can be a member of multiple groups and each group can contain multiple users.

To see the groups that your user currently belongs to, type:

    groups

This will show you all of the groups that your user is currently a member of. By default, you might only be a member of one or two groups, one of which might be the same as your username.

To show all of the groups currently available on your system, type:

    cat /etc/group

    root:x:0: daemon:x:1: bin:x:2: sys:x:3: adm:x:4: tty:x:5: disk:x:6: lp:x:7: . . .

The first field of each line is the name of a group.

Linux allows you to assign permissions based on the group owner of a file. This allows you to provide custom permissions to a group of people since only one user can own a file.

### Other Permissions

The last category that you can assign permissions for is the "other" category. In this context, other is defined as any user that is not the file owner and is not a member of the group that owns the file.

This category allows you to set a base permissions level that will apply to anyone outside of the other two control groups.

## Types of Permissions

Each permissions category (owner, group owner, and other) can be assigned permissions that allow or restrict their ability to read, write, or execute a file.

For a regular file, read permissions are required to read the contents of a file, write permissions are necessary to modify it, and execute permissions are needed to run the file as a script or an application.

For directories, read permissions are necessary to _ls_ (list) the contents of a directory, write permissions are required to modify the contents of a directory, and execute permissions allow a user to _cd_ (change directories) into the directory.

Linux represents these types of permissions using two separate symbolic notations: alphabetic and octal.

### Alphabetic Notation

Alphabetic notation is easy to understand and is used by a few common programs to represent permissions.

Each permission is represented by a single letter:

- r = read permissions
- w = write permissions
- x = execute permissions

It is important to remember that alphabetic permissions are always specified in this order. If a certain privilege is granted, it is represented by the appropriate letter. If access is restricted, it is represented by a dash (-).

Permissions are given for a file's owner first, followed by the group owner, and finally for other users. This gives us three groups of three values.

The _ls_ command uses alphabetic notation when called with its long-format option:

    cd /etc ls -l

    drwxr-xr-x 3 root root 4096 Apr 26 2012 acpi -rw-r--r-- 1 root root 2981 Apr 26 2012 adduser.conf drwxr-xr-x 2 root root 4096 Jul 5 20:53 alternatives -rw-r--r-- 1 root root 395 Jun 20 2010 anacrontab drwxr-xr-x 3 root root 4096 Apr 26 2012 apm drwxr-xr-x 3 root root 4096 Apr 26 2012 apparmor drwxr-xr-x 5 root root 4096 Jul 5 20:52 apparmor.d drwxr-xr-x 6 root root 4096 Apr 26 2012 apt …

The first field in the output of this command represents the permissions of the file.

Ten characters represent this data. The first character is not actually a permissions value and instead signifies the file type (- for a regular file, d for a directory, etc).

The next nine characters represent the permissions that we discussed above. Three groups representing owner, group owner, and other permissions, each with values indicating read, write, and execute permissions.

In the example above, the owner of the "acpi" directory has read, write, and execute permissions. The group owner and other users have read and execute permissions.

The "anacrontab" file allows the file owner to read and modify, but group members and other users only have permission to read.

### Octal Notation

The more concise, but slightly less intuitive way of representing permissions is with octal notation.

Using this method, each permissions category (owner, group owner, and other) is represented by a number between 0 and 7.

We arrive at the appropriate number by assigning each type of permission a numerical value:

- 4 = read permissions
- 2 = write permissions
- 1 = execute permission

We add up the numbers associated with the type of permissions we would like to grant for each category. This will be a number between 0 and 7 (0 representing no permissions and 7 representing full read, write, and execute permissions) for each category.

For example, if the file owner has read and write permissions, this would be represented as a 6 in the file owner's column. If the group owner requires only read permissions, then a 4 can be used to represent their permissions.

Similar to alphabetic notation, octal notation can include an optional leading character specifying the file type. This is followed by owner permissions, group owner permissions, and other permissions respectively.

An essential program that benefits from using octal notation is the _chmod_ command.

## Using the Chmod Command 

The most popular way of changing a file's permissions is by using octal notation with the _chmod_ command. We will practice by creating an empty file in our home directory:

    cd touch testfile

First, lets view the permissions that were given to this file upon creation:

    ls -l testfile

    -rw-rw-r-- 1 demouser demouser 0 Jul 10 17:23 testfile

If we interpret the permissions, we can see that the file owner and file group owner both have read and write privileges, and other users have read capabilities.

If we convert that into octal notation, the owner and group owner would have a permission value of 6 (4 for read, plus 2 for write) and the other category would have 4 (for read). The full permissions would be represented by the triplet 664.

We will pretend that this file contains a bash script that we would like to execute, as the owner. We don't want anyone else to modify the file, including group owners, and we don't want anyone not in the group to be able to read the file at all.

We can represent our desired permissions setting alphabetically like this: -rwxr-----. We will convert that into octal notation and change the permissions with _chmod_:

    chmod 740 testfile ls -l testfile

    -rwxr----- 1 demouser demouser 0 Jul 10 17:23 testfile

As you can see, the permissions were assigned correctly.

If we want to change the permissions back, we can easily do that by giving chmod the following command:

    chmod 664 testfile ls -l testfile

    -rw-rw-r-- 1 demouser demouser 0 Jul 10 17:23 testfile

## Setting Default Permissions with Umask

The _umask_ command defines the default permissions for newly created files based on the "base" permissions set defined for files and directories.

Files have a base permissions set of 666, or full read and write access for all users. Execute permissions are not assigned by default because most files are not made to be executed (assigning executable permissions also opens up some security concerns).

Directories have a base permissions set of 777, or read, write, and execute permissions for all users.

Umask operates by applying a subtractive "mask" to the base permissions shown above. We will use an example to demonstrate how this works.

If we want the owner and members of the owner group to be able to write to newly created directories, but not other users, we would want to assign the permissions to 775.

We need the three digit number that would express the difference between the base permissions and the desired permissions. That number is 002.

     777 - 775 ------ 002

This resulting number is the umask value that we would like to apply. Coincidently, this is the default umask value for many systems, as we saw when we created a file with the _touch_ command earlier. Let's try again:

    touch test2 ls -l test2

    -rw-rw-r-- 1 demouser demouser 0 Jul 10 18:30 test2

We can define a different umask using the _umask_ command.

If we want to secure our system more, we can say that by default, we want users who are not the file owner to have no permissions at all. This can be accomplished with the 077 umask:

    umask 077 touch restricted ls -l restricted

    -rw------- 1 demouser demouser 0 Jul 10 18:33 restricted

If we have a process that creates shared content, we may want give full permissions to every file and directory that it creates:

    umask 000 touch openfile ls -l openfile

    -rw-rw-rw- 1 demouser demouser 0 Jul 10 18:36 openfile

By default, the settings you assign to _umask_ will only apply to the current shell session. When you log in next time, any new files and directories will be give the original settings chosen by your distribution.

If you would like to make your umask settings persist across sessions, you can define the umask settings in your .bashrc file:

    cd nano .bashrc

Search to see if there is already a umask value set. Modify the existing value if there is one. Otherwise, add a line at the bottom of the file with your desired umask settings:

    umask 022

Here, we have chosen to give the owner full permissions, and take away write permissions for both the group owner and other categories. Adjust this setting to your liking to make your preferences available next time you log in.

## A Word of Caution

An important point to remember when changing permissions is that certain areas of the filesystem and certain processes require specific permissions to run correctly. Inadequate permissions can lead to errors and non-functioning applications.

On the other hand, settings that are _too_ permissive can be a security risk.

For these reasons, it is recommended that you do not adjust permissions outside of your own home directory unless you are aware of the repercussions that can arise due to improperly configured settings.

Another good rule to abide by, especially when configuring software manually, is to always assign the most restrictive permissions policy possible without affecting functionality.

This means that if only one user (such as a service) needs to access a group of files, then there is no need to allow the rest of the world to have write or even read access to the contents. This is especially true in contexts where passwords are stored in plain-text.

You can fine-tune permissions more fully by correctly utilizing group owner permissions and adding necessary users to the appropriate group. If all of the users who need access to a file are members of the group owner, then the other permission category can be locked down for more security.

By Justin Ellingwood
