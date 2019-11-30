---
author: Justin Ellingwood
date: 2014-02-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-cd-pwd-and-ls-to-explore-the-file-system-on-a-linux-server
---

# How To Use cd, pwd, and ls to Explore the File System on a Linux Server

## Introduction

* * *

Getting familiar with the command line is the first step towards utilizing the power of the Linux server platform. It is also an essential prerequisite for basically all server-related activities that you may wish to do within this environment.

While graphical alternatives exist for many tools, learning the command line is a skill that will allow you to work with efficiency, speed, and flexibility in a way that is not possible through most GUIs (graphical user interfaces).

We all have to start somewhere, so we will cover the very basics in this article: how to navigate your system and find out what’s there.

## Prerequisites

* * *

This article is very basic, so it does not assume much prior knowledge. However, you will need to be logged into your VPS instance to start exploring. The options that you have available to do this depends largely on the operating system that you are using at home.

When you [create a new DigitalOcean droplet](https://www.digitalocean.com/community/articles/how-to-create-your-first-digitalocean-droplet-virtual-server), you will be emailed a password and given an IP address to access your new server. Use the linked article to learn how to connect to your VPS.

    ssh root@your\_IP

Another option is to use the “Console Access” button in the top-right corner of your DigitalOcean control panel. This will create a virtual terminal session directly in your web browser window.

## Finding Out Where You Are with pwd

* * *

At this point, you should be logged into your Linux machine. You will likely see something that looks like this:

    root@your\_hostname:~# 

This is the prompt. It is where we type commands.

But there’s more to it than that. You are also in a specific place in the server’s file system. You will always be in one location or another in your server’s file hierarchy and this has implications on how the commands you type will operate.

This is similar to when you open the file browser on your local computer. You can click on different folders to travel to different places in the file system. If you go to the edit menu of your file browser, you might have some options that will apply to the items in the specific folder you are in.

The command line is just a textual representation of the same idea.

So where are we in our file system exactly? There is one clue in the prompt itself. Right before the `#` or `$` character at the end of your prompt (this will depend on what user you are logged in as), you will see a tilde character (~). This stands for your “home” directory.

Your home directory is the place where the files for your user are stored. The ~ character is shorthand for this directory.

Another way to find out where you are in the file system is with a command called `pwd`. This will be your first command!

Type these characters into your terminal and press ENTER:

    pwd

* * *

    /root

The `/root` directory is the home directory of the root (administrative) user. If you are logged in as another user, you will instead see something like this:

    pwd

    /home/your\_username

It doesn’t matter which user you are logged in as for this tutorial, so either output is fine.

## Looking Around with ls

* * *

Now you know which directory you are currently in. But how do we know what is in this directory?

We can ask our server what files and directories are in the current directory with a command called `ls`. Type it in at the command prompt now:

    ls

This should just return you to the command prompt and not give you any information. Did the command fail? No, it succeeded, it just didn’t find any files or folders in your current directory.

Let’s create a few test files to see how `ls` behaves when there are files in this directory. Type this to create a few files:

    touch file{1..5}

This will create 5 files called file1, file2, …, file5 in our current directory.

Let’s retry the `ls` command to see what it will do:

    ls

* * *

    file1 file2 file3 file4 file5

Wonderful. The command now recognizes that we have some files in our home directory.

Most commands have default behavior that gets executed when you call it like we did above. However, most command behavior can also be augmented by passing optional arguments to the command. You may hear these referred to as “options”, “arguments”, “flags”, or “parameters”.

Sometimes, these activate optional functionality available through the command and other times these specify the object that the command should be taken against.

Let’s start with the first situation.

### Exploring ls Options

* * *

Not all commands have a built-in help option, but we many do. Most of the time, you can access this by adding a `--help` or `-h` at the end of the command. We can try this with the `ls` command now:

    ls --help

* * *

    Usage: ls [OPTION]... [FILE]...
    List information about the FILEs (the current directory by default).
    Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.
    
    Mandatory arguments to long options are mandatory for short options too.
      -a, --all do not ignore entries starting with .
      -A, --almost-all do not list implied . and ..
          --author with -l, print the author of each file
      -b, --escape print C-style escapes for nongraphic characters
          --block-size=SIZE scale sizes by SIZE before printing them. E.g.,
    . . .

This will give you some guidance on the correct usage of the command and give you an idea of what options are available to alter the default behavior. The column on the left gives you the characters to type in to augment the command, and the column on the right describes each flag.

The `--help` that we added on was an example of an option that we can pass.

Another way to find out about options that are available for the command you are interested in is by checking the manual. This is accomplished by typing `man` followed by the command you are interested in. Try it now:

    man ls

You can scroll through the page with the arrow keys and exit by typing “q”.

As you can see, `ls` has quite a few options that we can pass to the command to change its behavior. Let’s try a few out.

    ls -l

* * *

    -rw-r--r-- 1 root root 0 Feb 28 19:45 file1
    -rw-r--r-- 1 root root 0 Feb 28 19:45 file2
    -rw-r--r-- 1 root root 0 Feb 28 19:45 file3
    -rw-r--r-- 1 root root 0 Feb 28 19:45 file4
    -rw-r--r-- 1 root root 0 Feb 28 19:45 file5

This shows us the same five files, but it shows them in “long” format. This gives us more information about the files, such as the owner (first “root”), the group owner (second “root”), the size of the file ( 0 ), the date the file was last modified, and some other information.

Let’s try another option:

    ls -a

* * *

    . .aptitude .bashrc file2 file4 .profile .ssh
    .. .bash_history file1 file3 file5 .rnd .viminfo

This shows us some files that we didn’t see before. The `-a` flag is synonymous with the `--all` flag. This shows us _all_ of the files in the current directory, including hidden files.

In Linux systems, all files that are named with a starting dot are hidden by default. They are not secret and anyone can find them, they are just kept out of the way for easy file administration. By passing the `-a` flag, we can tell `ls` to display these files as well.

We can pass multiple flags as well, by simply stringing them together:

    ls -l -a

* * *

    drwx------ 4 root root 4096 Feb 28 19:45 .
    drwxr-xr-x 23 root root 4096 May 3 2013 ..
    drwx------ 2 root root 4096 Feb 28 17:19 .aptitude
    -rw------- 1 root root 2036 Feb 28 18:20 .bash_history
    -rw-r--r-- 1 root root 570 Jan 31 2010 .bashrc
    -rw-r--r-- 1 root root 0 Feb 28 19:45 file1
    . . .

This works well, but we can also collapse option flags like this:

    ls -la

This will function exactly the same, and takes less typing.

Another interesting option is the `-R` flag, which lists files recursively. Since the only directories we have within our home directory are hidden, we’ll have to pass the `-a` option too:

    ls -Ra

* * *

        .:
    . .aptitude .bashrc file2 file4 .profile .ssh
    .. .bash_history file1 file3 file5 .rnd .viminfo
    
    ./.aptitude:
    . .. cache config
    
    ./.ssh:
    . .. authorized_keys

Now that we know how to change how `ls` behaves, let’s change the “object” that `ls` operates on.

### Using ls on Other Directories

* * *

By default, `ls` will list the contents of the current directory. However, we can pass the name of any directory that we would like to see the contents of at the end of the command.

For instance, we can view the contents of a directory called `/etc` that is available on all Linux systems by typing:

    ls /etc

* * *

    acpi fstab magic rc.local
    adduser.conf fstab.d magic.mime rc.local.orig
    aliases fuse.conf mailcap rcS.d
    aliases.db gai.conf mailcap.order reportbug.conf
    alternatives groff mailname resolvconf
    anacrontab group mail.rc resolv.conf
    apm group- manpath.config rmt
    . . .

We see here that there are many files in this directory.

Any directory path that begins with a slash (/) is known as an “absolute” path. This is because it references the directory path specifically from the very highest directory, the root directory, which is specified by the “/” character.

Another way to reference a directory is using a “relative” path. This will look for a directory relative to the directory that you are currently in. These directory specifications don’t start with a slash.

We don’t have any non-hidden directories in our current folder, so let’s make some really quickly to demonstrate. We’ll also add some files inside. Don’t worry about these commands right now, they’re just used to demonstrate an idea right now, so just type them in as-is:

    mkdir dir{1..3}
    touch dir{1..3}/test{A,B,C}

This will create some directories with some files inside. We can see the directories with a normal `ls` command:

    ls

* * *

    dir1 dir2 dir3 file1 file2 file3 file4 file5

In order to see what is inside of the “dir1” directory, we _could_ give the absolute path like we demonstrated above, by appending the directory we want to see onto the end of the value of our current directory. We could find out the current directory:

    pwd

* * *

    /root

And then add the directory we’re interested in onto the end:

    ls /root/dir1

* * *

    testA testB testC 

But we don’t have to do this. We can reference directories inside of our current directory by just naming the directory, like this:

    ls dir1

* * *

    testA testB testC

If we don’t begin a path specification with a slash, the operating system looks for the directory path starting at the current directory.

## Moving Around

* * *

So far, we’ve learned how to figure out where we are in the filesystem, and we’ve learned how to use the `ls` command to find out some information about files in certain directories.

But how do we change our working directory? Changing our working directory will allow us to use relative paths from a different location. Usually, it is easier to operate on files from the directory where they are contained.

We can move around the file hierarchy by using the `cd` command. This command stands for change directories.

In its most basic usage, we can just type:

    cd

This will not appear to do anything. In fact, it hasn’t. What `cd` does without any additional information is change to your home directory. Since we are already in our home directory, there’s nothing for the command to do.

A more general idea of how to use the command is like this:

    cd /path/to/directory

In this instance, `/path/to/directory` should be substituted with the path of the directory location that you would like to move to. For instance, to change to the “root” directory, specified by a single slash (/), which is the top of the tree, we can type:

    cd /

**Note** : The root directory (specified by a single forward slash “/”) is different from the home directory of the root user (located at “/root”). This can be confusing at first, but just remember that the top of the directory tree is called the file system root.

You may have noticed that your command prompt has changed.

Right before the “#” or “$”, the directory listing has changed from the tilde (remember, the symbol that looks like “~” that stands for your user’s home directory), to the “root” directory of the filesystem.

We can verify that we’re now in a different directory by using the `pwd` command again:

    pwd

* * *

    /

We can also check out the files in our new directory:

    ls

* * *

    bin etc lib media proc sbin sys var
    boot home lib64 mnt root selinux tmp vmlinuz
    dev initrd.img lost+found opt run srv usr

We’ve successfully moved to a different location. Now, let’s try to move to a new directory using a relative path. We see that there is a directory called `usr` within this directory. Change to it by typing:

    cd usr

As you can see, we can use relative paths with `cd` as well. How do we move back to the root directory? We could type the same `cd /` command that we used before, but let’s try something different.

Let’s try to move up the tree using relative paths. How do we reference the folder containing our current folder using relative paths?

We can reference the directory that contains our current directory using a special syntax. The directory containing our current directory is called its “parent” directory. We can reference the parent directory using two dots (..).

Let’s move back up a level:

    cd ..
    pwd

* * *

    /

As you can see, we’re back in the root directory. We can also reference our current directory with a single dot:

    ls .

* * *

    bin etc lib media proc sbin sys var
    boot home lib64 mnt root selinux tmp vmlinuz
    dev initrd.img lost+found opt run srv usr

This is useful in a number of situations that may not be very apparent at this stage, but you will appreciate the ability to refer to your current directory easily later on.

As we said earlier, the “~” symbol references our home directory. Let’s use that as the start of another directory path to change to our “dir1” inside our home:

    cd ~/dir1
    pwd

* * *

    /root/dir1

We have now moved into a directory within our home directory very easily using the “~” symbol to replace the first part of our path.

But what if we forgot to do something before changing directories and want to go back to our most recent directory? We can return to our previous directory by typing:

    cd -
    pwd

* * *

    /

We are back in our last directory.

Let’s finish up by moving back to our home directory. We could do this by using the tilde as the path to switch to. But you may recall that the default mode of `cd` is to return us to our home directory if we don’t add any path. Let’s try that instead:

    cd
    pwd

* * *

    /root

As you can see, we’ve made it back to our home directory again.

## Conclusion

* * *

You should now have the tools you need to explore the filesystem quite a bit. You don’t know how to investigate files yet, but you should be able to navigate around the system easily, keep track of where you are, and see the files that are around you.

By Justin Ellingwood
