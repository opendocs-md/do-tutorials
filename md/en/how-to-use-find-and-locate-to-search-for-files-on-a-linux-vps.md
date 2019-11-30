---
author: Justin Ellingwood
date: 2013-09-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-find-and-locate-to-search-for-files-on-a-linux-vps
---

# How To Use Find and Locate to Search for Files on a Linux VPS

## Introduction

* * *

One problem users run into when first dealing with a Linux machine is how to find the files they are looking for.

This guide will cover how to use the aptly named `find` command. This will help you search for files on your VPS using a variety of filters and parameters. We will also briefly cover the `locate` command, which can be used to search for commands in a different way.

## Finding by Name

* * *

The most obvious way of searching for files is by name.

To find a file by name, type:

    find -name "query"

This will be case sensitive, meaning a search for “file” is different than a search for “File”.

To find a file by name, but ignore the case of the query, type:

    find -iname "query"

If you want to find all files that don’t adhere to a specific pattern, you can invert the search with “-not” or “!”. If you use “!”, you must escape the character so that bash does not try to interpret it before find can act:

    find -not -name "query\_to\_avoid"

Or

    find \! -name "query\_to\_avoid"

## Finding by Type

* * *

You can specify the type of files you want to find with the “-type” parameter. It works like this:

    find -type type\_descriptor query

Some of the most common descriptors that you can use to specify the type of file are here:

- **f** : regular file

- **d** : directory

- **l** : symbolic link

- **c** : character devices

- **b** : block devices

For instance, if we wanted to find all of the character devices on our system, we could issue this command:

    find / -type c

* * *

    /dev/parport0
    /dev/snd/seq
    /dev/snd/timer
    /dev/autofs
    /dev/cpu/microcode
    /dev/vcsa7
    /dev/vcs7
    /dev/vcsa6
    /dev/vcs6
    /dev/vcsa5
    /dev/vcs5
    /dev/vcsa4
    . . .

We can search for all files that end in “.conf” like this:

    find / -type f -name "*.conf"

* * *

    /var/lib/ucf/cache/:etc:rsyslog.d:50-default.conf
    /usr/share/base-files/nsswitch.conf
    /usr/share/initramfs-tools/event-driven/upstart-jobs/mountall.conf
    /usr/share/rsyslog/50-default.conf
    /usr/share/adduser/adduser.conf
    /usr/share/davfs2/davfs2.conf
    /usr/share/debconf/debconf.conf
    /usr/share/doc/apt-utils/examples/apt-ftparchive.conf
    . . .

## Filtering by Time and Size

* * *

Find gives you a variety of ways to filter results by size and time.

### Size

* * *

You can filter by size with the use of the “-size” parameter.

We add a suffix on the end of our value that specifies how we are counting. These are some popular options:

- **c** : bytes

- **k** : Kilobytes

- **M** : Megabytes

- **G** : Gigabytes

- **b** : 512-byte blocks

To find all files that are exactly 50 bytes, type:

    find / -size 50c

To find all files less than 50 bytes, we can use this form instead:

    find / -size -50c

To Find all files more than 700 Megabytes, we can use this command:

    find / -size +700M

### Time

* * *

Linux stores time data about access times, modification times, and change times.

- **Access Time** : Last time a file was read or written to.

- **Modification Time** : Last time the contents of the file were modified.

- **Change Time** : Last time the file’s inode meta-data was changed.

We can use these with the “-atime”, “-mtime”, and “-ctime” parameters. These can use the plus and minus symbols to specify greater than or less than, like we did with size.

The value of this parameter specifies how many days ago you’d like to search.

To find files that have a modification time of a day ago, type:

    find / -mtime 1

If we want files that were accessed in less than a day ago, we can type:

    find / -atime -1

To get files that last had their meta information changed more than 3 days ago, type:

    find / -ctime +3

There are also some companion parameters we can use to specify minutes instead of days:

    find / -mmin -1

This will give the files that have been modified type the system in the last minute.

Find can also do comparisons against a reference file and return those that are newer:

    find / -newer myfile

## Finding by Owner and Permissions

* * *

You can also search for files by the file owner or group owner.

You do this by using the “-user” and “-group” parameters respectively. Find a file that is owned by the “syslog” user by entering:

    find / -user syslog

Similarly, we can specify files owned by the “shadow” group by typing:

    find / -group shadow

We can also search for files with specific permissions.

If we want to match an exact set of permissions, we use this form:

    find / -perm 644

This will match files with exactly the permissions specified.

If we want to specify anything with _at least_ those permissions, you can use this form:

    find / -perm -644

This will match any files that have additional permissions. A file with permissions of “744” would be matched in this instance.

## Filtering by Depth

* * *

For this section, we will create a directory structure in a temporary directory. It will contain three levels of directories, with ten directories at the first level. Each directory (including the temp directory) will contain ten files and ten subdirectories.

Make this structure by issuing the following commands:

    cd
    mkdir -p ~/test/level1dir{1..10}/level2dir{1..10}/level3dir{1..10}
    touch ~/test/{file{1..10},level1dir{1..10}/{file{1..10},level2dir{1..10}/{file{1..10},level3dir{1..10}/file{1..10}}}}
    cd ~/test

Feel free to check out the directory structures with `ls` and `cd` to get a handle on how things are organized. When you are finished, return to the test directory:

    cd ~/test

We will work on how to return specific files from this structure. Let’s try an example with just a regular name search first, for comparison:

    find -name file1

* * *

    ./level1dir7/level2dir8/level3dir9/file1
    ./level1dir7/level2dir8/level3dir3/file1
    ./level1dir7/level2dir8/level3dir4/file1
    ./level1dir7/level2dir8/level3dir1/file1
    ./level1dir7/level2dir8/level3dir8/file1
    ./level1dir7/level2dir8/level3dir7/file1
    ./level1dir7/level2dir8/level3dir2/file1
    ./level1dir7/level2dir8/level3dir6/file1
    ./level1dir7/level2dir8/level3dir5/file1
    ./level1dir7/level2dir8/file1
    . . .

There are a lot of results. If we pipe the output into a counter, we can see that there are 1111 total results:

    find -name file1 | wc -l

* * *

    1111

This is probably too many results to be useful to you in most circumstances. Let’s try to narrow it down.

You can specify the maximum depth of the search under the top-level search directory:

    find -maxdepth num -name query

To find “file1” only in the “level1” directories and above, you can specify a max depth of 2 (1 for the top-level directory, and 1 for the level1 directories):

    find -maxdepth 2 -name file1

* * *

    ./level1dir7/file1
    ./level1dir1/file1
    ./level1dir3/file1
    ./level1dir8/file1
    ./level1dir6/file1
    ./file1
    ./level1dir2/file1
    ./level1dir9/file1
    ./level1dir4/file1
    ./level1dir5/file1
    ./level1dir10/file1

That is a much more manageable list.

You can also specify a minimum directory if you know that all of the files exist past a certain point under the current directory:

    find -mindepth num -name query

We can use this to find only the files at the end of the directory branches:

    find -mindepth 4 -name file

* * *

    ./level1dir7/level2dir8/level3dir9/file1
    ./level1dir7/level2dir8/level3dir3/file1
    ./level1dir7/level2dir8/level3dir4/file1
    ./level1dir7/level2dir8/level3dir1/file1
    ./level1dir7/level2dir8/level3dir8/file1
    ./level1dir7/level2dir8/level3dir7/file1
    ./level1dir7/level2dir8/level3dir2/file1
    . . .

Again, because of our branching directory structure, this will return a large number of results (1000).

You can combine the min and max depth parameters to focus in on a narrow range:

    find -mindepth 2 -maxdepth 3 -name file

* * *

    ./level1dir7/level2dir8/file1
    ./level1dir7/level2dir5/file1
    ./level1dir7/level2dir7/file1
    ./level1dir7/level2dir2/file1
    ./level1dir7/level2dir10/file1
    ./level1dir7/level2dir6/file1
    ./level1dir7/level2dir3/file1
    ./level1dir7/level2dir4/file1
    ./level1dir7/file1
    . . .

## Executing and Combining Find Commands

* * *

You can execute an arbitrary helper command on everything that find matches by using the “-exec” parameter. This is called like this:

    find find\_parameters -exec command\_and\_params {} \;

The “{}” is used as a placeholder for the files that find matches. The “\;” is used so that find knows where the command ends.

For instance, we could find the files in the previous section that had “644” permissions and modify them to have “664” permissions:

    cd ~/test
    find . -type f -perm 644 -exec chmod 664 {} \;

We could then change the directory permissions like this:

    find . -type d -perm 755 -exec chmod 700 {} \;

If you want to chain different results together, you can use the “-and” or “-or” commands. The “-and” is assumed if omitted.

    find . -name file1 -or -name file9 

## Find Files Using Locate

* * *

An alternative to using `find` is the `locate` command. This command is often quicker and can search the entire file system with ease.

You can install the command with apt-get:

    sudo apt-get update
    sudo apt-get install mlocate

The reason locate is faster than find is because it relies on a database of the files on the filesystem.

The database is usually updated once a day with a cron script, but you can update it manually by typing:

    sudo updatedb

Run this command now. Remember, the database must always be up-to-date if you want to find recently acquired or created files.

To find files with locate, simply use this syntax:

    locate query

You can filter the output in some ways.

For instance, to only return files containing the query itself, instead of returning every file that has the query in the directories leading to it, you can use the “-b” for only searching the “basename”:

    locate -b query

To have locate only return results that still exist in the filesystem (that were not removed between the last “updatedb” call and the current “locate” call), use the “-e” flag:

    locate -e query

To see statistics about the information that locate has cataloged, use the “-S” option:

    locate -S

* * *

    Database /var/lib/mlocate/mlocate.db:
        3,315 directories
        37,228 files
        1,504,439 bytes in file names
        594,851 bytes used to store database

## Conclusion

* * *

Both find and locate are good ways to find files on your system. It is up to you to decide which of these tools is appropriate in each situation.

Find and locate are powerful commands that can be strengthened by combining them with other utilities through pipelines. Experiment with filtering by using commands like `wc`, `sort`, and `grep`.

By Justin Ellingwood
