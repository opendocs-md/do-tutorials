---
author: Brian Boucheron
date: 2019-03-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-filesystem-quotas-on-debian-9
---

# How To Set Filesystem Quotas on Debian 9

## Introduction

Quotas are used to limit the amount of disk space a user or group can use on a filesystem. Without such limits, a user could fill up the machine’s disk and cause problems for other users and services.

In this tutorial we will install command line tools to create and inspect disk quotas, then set a quota for an example user.

## Prerequisites

This tutorial assumes you are logged into a Debian 9 server, with a non-root, sudo-enabled user, as described in [Initial Server Setup with Debian 9](initial-server-setup-with-debian-9).

The techniques in this tutorial should generally work on Linux distributions other than Debian, but may require some adaptation.

## Step 1 – Installing the Quota Tools

To set and check quotas, we first need to install the quota command line tools using `apt`. Let’s update our package list, then install the package:

    sudo apt update
    sudo apt install quota

You can verify that the tools are installed by running the `quota` command and asking for its version information:

    quota --version

    OutputQuota utilities version 4.03.
    . . .

It’s fine if your output shows a slightly different version number.

Next we will update our filesystem’s `mount` options to enable quotas on our **root** filesystem.

## Step 2 – Updating Filesystem Mount Options

To activate quotas on a particular filesystem, we need to mount it with a few quota-related options specified. We do this by updating the filesystem’s entry in the `/etc/fstab` configuration file. Open that file in your favorite text editor now:

    sudo nano /etc/fstab

The file’s contents will be similar to the following:

/etc/fstab

    # /etc/fstab: static file system information.
    UUID=06b2aae3-b525-4a4c-9549-0fc6045bd08e / ext4 errors=remount-ro 0 1

This `fstab` file is from a virtual server. A desktop or laptop computer will probably have a slightly different looking `fstab`, but in most cases you’ll have a `/` or **root** filesystem that represents all of your disk space.

Update the line pointing to the root filesystem by adding options as follows:

/etc/fstab

    # /etc/fstab: static file system information.
    UUID=06b2aae3-b525-4a4c-9549-0fc6045bd08e / ext4 errors=remount-ro,usrquota,grpquota 0 1

You will add the new options to the end of any existing options, being sure to separate them all with a comma and no spaces. The above change will allow us to enable both user- (`usrquota`) and group-based (`grpquota`) quotas on the filesystem. If you only need one or the other, you may leave out the unused option.

Remount the filesystem to make the new options take effect:

    sudo mount -o remount /

**Note:** Be certain there are no spaces between the options listed in your `/etc/fstab` file. If you put a space after the `,` comma, you will see an error like the following:

    Outputmount: /etc/fstab: parse error at line 2 -- ignored

If you see this message after running the previous `mount` command, reopen the `fstab` file, correct any errors, and repeat the `mount` command before continuing.

We can verify that the new options were used to mount the filesystem by looking at the `/proc/mounts` file. Here, we use `grep` to show only the root filesystem entry in that file:

    cat /proc/mounts | grep ' / '

    Output/dev/vda1 / ext4 rw,relatime,quota,usrquota,grpquota,errors=remount-ro,data=ordered 0 0

Note the two options that we specified. Now that we’ve installed our tools and updated our filesystem options, we can turn on the quota system.

## Step 3 – Enabling Quotas

Before finally turning on the quota system, we need to manually run the `quotacheck` command once:

    sudo quotacheck -ugm /

This command creates the files `/aquota.user` and `/aquota.group`. These files contain information about the limits and usage of the filesystem, and they need to exist before we turn on quota monitoring. The `quotacheck` parameters we’ve used are:

- **`u`:** specifies that a user-based quota file should be created
- **`g`:** indicates that a group-based quota file should be created
- **`m`:** disables remounting the filesystem as read-only while performing the initial tallying of quotas. Remounting the filesystem as read-only will give more accurate results in case a user is actively saving files during the process, but is not necessary during this initial setup.

If you don’t need to enable user- or group-based quotas, you can leave off the corresponding `quotacheck` option.

We can verify that the appropriate files were created by listing the root directory:

    ls /

    Outputaquota.group bin dev home initrd.img.old lib64 media opt root sbin sys usr vmlinuz
    aquota.user boot etc initrd.img lib lost+found mnt proc run srv tmp var vmlinuz.old

If you didn’t include the `u` or `g` options in the `quotacheck` command, the corresponding file will be missing. Now we’re ready to turn on the quota system:

    sudo quotaon -v /

    Output/dev/vda1 [/]: group quotas turned on
    /dev/vda1 [/]: user quotas turned on

Our server is now monitoring and enforcing quotas, but we’ve not set any yet! Next we’ll set a disk quota for a single user.

## Step 4 – Configuring Quotas for a User

There are a few ways we can set quotas for users or groups. Here, we’ll go over how to set quotas with both the `edquota` and `setquota` commands.

### Using `edquota` to Set a User Quota

We use the `edquota` command to **ed** it **quota** s. Let’s edit our example **sammy** user’s quota:

    sudo edquota -u sammy

The `-u` option specifies that this is a `user` quota we’ll be editing. If you’d like to edit a group’s quota instead, use the `-g` option in its place.

This will open up a file in the default text editor, similar to how `crontab -e` opens a temporary file for you to edit. The file will look similar to this:

    Disk quotas for user sammy (uid 1001):
      Filesystem blocks soft hard inodes soft hard
      /dev/vda1 24 0 0 7 0 0

This lists the username and `uid`, the filesystems that have quotas enabled on them, and the _block_- and _inode_-based usage and limits. Setting an inode-based quota would limit how many files and directories a user can create, regardless of the amount of disk space they use. Most people will want block-based quotas, which specifically limit disk space usage. This is what we will configure.

**Note:** The concept of a _block_ is poorly specified and can change depending on many factors, including which command line tool is reporting them. In the context of setting quotas on Debian, it’s fairly safe to assume that 1 block equals 1 kilobyte of disk space.

In the above listing, our user **sammy** is using 24 blocks, or 24KB of space on the `/dev/vda1` drive. The `soft` and `hard` limits are both disabled with a `0` value.

Each type of quota allows you to set both a _soft limit_ and a _hard limit_. When a user exceeds the soft limit, they are over quota, but they are not immediately prevented from consuming more space or inodes. Instead, some leeway is given: the user has – by default – seven days to get their disk use back under the soft limit. At the end of the seven day grace period, if the user is still over the soft limit it will be treated as a hard limit. A hard limit is less forgiving: all creation of new blocks or inodes is immediately halted when you hit the specified hard limit. This behaves as if the disk is completely out of space: writes will fail, temporary files will fail to be created, and the user will start to see warnings and errors while performing common tasks.

Let’s update our **sammy** user to have a block quota with a 100MB soft limit, and a 110MB hard limit:

    Disk quotas for user sammy (uid 1001):
      Filesystem blocks soft hard inodes soft hard
      /dev/vda1 24 100M 110M 7 0 0

Save and close the file. To check the new quota we can use the `quota` command:

    sudo quota -vs sammy

    OutputDisk quotas for user sammy (uid 1001):
         Filesystem space quota limit grace files quota limit grace
          /dev/vda1 24K 100M 110M 7 0 0

The command outputs our current quota status, and shows that our quota is `100M` while our limit is `110M`. This corresponds to the soft and hard limits respectively.

**Note:** If you want your users to be able to check their own quotas without having `sudo` access, you’ll need to give them permission to read the quota files we created in Step 4. One way to do this would be to make a `users` group, make those files readable by the `users` group, and then make sure all your users are also placed in the group.

To learn more about Linux permissions, including user and group ownership, please read [An Introduction to Linux Permissions](an-introduction-to-linux-permissions)

### Using `setquota` to Set a User Quota

Unlike `edquota`, `setquota` will update our user’s quota information in a single command, without an interactive editing step. We will specify the username and the soft and hard limits for both block- and inode-based quotas, and finally the filesystem to apply the quota to:

    sudo setquota -u sammy 200M 220M 0 0 /

The above command will double **sammy** ’s block-based quota limits to 200 megabytes and 220 megabytes. The `0 0` for inode-based soft and hard limits indicates that they remain unset. This is required even if we’re not setting any inode-based quotas.

Once again, use the `quota` command to check our work:

    sudo quota -vs sammy

    OutputDisk quotas for user sammy (uid 1001): 
         Filesystem space quota limit grace files quota limit grace
          /dev/vda1 24K 200M 220M 7 0 0

Now that we have set some quotas, let’s find out how to generate a quota report.

## Step 5 – Generating Quota Reports

To generate a report on current quota usage for all users on a particular filesystem, use the `repquota` command:

    sudo repquota -s /

    Output*** Report for user quotas on device /dev/vda1
    Block grace time: 7days; Inode grace time: 7days
                            Space limits File limits
    User used soft hard grace used soft hard grace
    ----------------------------------------------------------------------
    root -- 981M 0K 0K 35234 0 0
    nobody -- 7664K 0K 0K 3 0 0
    ntp -- 12K 0K 0K 3 0 0
    _apt -- 8K 0K 0K 2 0 0
    debian -- 16K 0K 0K 4 0 0
    sammy -- 24K 200M 220M 7 0 0

In this instance we’re generating a report for the `/` **root** filesystem. The `-s` command tells `repquota` to use human-readable numbers when possible. There are a few system users listed, which probably have no quotas set by default. Our user **sammy** is listed at the bottom, with the amounts used and soft and hard limits.

Also note the `Block grace time: 7days` callout, and the `grace` column. If our user was over the soft limit, the `grace` column would show how much time they had left to get back under the limit.

In the next step we’ll update the grace periods for our quota system.

## Step 6 – Configuring a Grace Period for Overages

We can configure the period of time where a user is allowed to float above the soft limit. We use the `setquota` command to do so:

    sudo setquota -t 864000 864000 /

The above command sets both the block and inode grace times to 864000 seconds, or 10 days. This setting applies to all users, and both values must be provided even if you don’t use both types of quota (block vs. inode).

Note that the values _must_ be specified in seconds.

Run `repquota` again to check that the changes took effect:

    sudo repquota -s /

    OutputBlock grace time: 10days; Inode grace time: 10days
    . . .

The changes should be reflected immediately in the `repquota` output.

## Conclusion

In this tutorial we installed the `quota` command line tools, set up a block-based quota for one user, and generated a report on our filesystem’s quota usage.

### Appendix: Common Quota-related Error Messages

The following are some common errors you may see when setting up and manipulating filesystem quotas.

    quotaon Outputquotaon: cannot find //aquota.group on /dev/vda1 [/]
    quotaon: cannot find //aquota.user on /dev/vda1 [/]

This is an error you might see if you tried to turn on quotas (using `quotaon`) before running the initial `quotacheck` command. The `quotacheck` command creates the `aquota` or `quota` files needed to turn on the quota system. See Step 3 for more information.

    quota Outputquota: Cannot open quotafile //aquota.user: Permission denied
    quota: Cannot open quotafile //aquota.user: Permission denied
    quota: Cannot open quotafile //quota.user: No such file or directory

This is the error you’ll see if you run `quota` and your current user does not have permission to read the quota files for your filesystem. You (or your system administrator) will need to adjust the file permissions appropriately, or use `sudo` when running commands that require access to the quota file.

To learn more about Linux permissions, including user and group ownership, please read [An Introduction to Linux Permissions](an-introduction-to-linux-permissions)
