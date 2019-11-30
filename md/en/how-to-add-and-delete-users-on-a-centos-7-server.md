---
author: Josh Barnett
date: 2014-10-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-a-centos-7-server
---

# How To Add and Delete Users on a CentOS 7 Server

## Introduction

When you first start using a fresh Linux server, adding and removing users is one of the most basic tasks that you should know how to do. When you create a new server, you are only given the `root` account by default. While this gives you a lot of power and flexibility, it is also dangerous to regularly use an account with so much power; for example, a `root` user is more vulnerable to security exploits, since any commands run under that account can affect the server’s entire filesystem.

It is almost always a better idea to add an additional, unprivileged user to do common tasks. You should also create additional accounts for any other users that need access to your server. Each user should have an additional account so that their activities can be monitored and managed. You can still acquire administrative privileges, when needed, through a mechanism called `sudo`. In this guide, we will cover how to create user accounts, assign `sudo` privileges, and delete users on a CentOS 7 server.

## Adding Users

If you are signed in as the `root` user, you can create a new user at any time by typing:

    adduser username

If you are signed in as a non-root user who has been given `sudo` privileges, as demonstrated in the next section of this tutorial, you can add a new user by typing:

    sudo adduser username

Next, you’ll need to give your user a password so that they can log in. To do so, use the `passwd` command:

    passwd username

**Note:** Remember to add `sudo` ahead of the command if you are signed in as a non-root user with `sudo` privileges.

You will be prompted to type in the password twice to confirm it. Now your new user is set up and ready for use! You can now log in as that user, using the password that you set up.

## Granting Sudo Privileges to a User

If your new user should have the ability to execute commands with `root` (administrative) privileges, you will need to give the new user access to `sudo`.

We can do this by adding the user to the `wheel` group (which gives `sudo` access to all of its members by default) through the `gpasswd` command. This is the safest and easiest way to manage `sudo` user rights.

If you are currently signed in as the `root` user, type:

    gpasswd -a username wheel

If you are signed in using a non-root user with `sudo` privileges, type this instead:

    sudo gpasswd -a username wheel

Now your new user is able to execute commands with administrative privileges. To do so, simply type `sudo` ahead of the command that you want to execute as an administrator:

    sudo some_command

You will be prompted to enter the password of the regular user account that you are signed in as. Once the correct password has been submitted, the command you entered will be executed with `root` privileges.

### Managing Users with Sudo Privileges

While you can add and remove users from a group (such as `wheel`) with `gpasswd`, the command doesn’t have a way to show which users are members of a group. In order to see which users are part of the `wheel` group (and thus have `sudo` privileges by default), you can use the `lid` function. `lid` is normally used to show which groups a user belongs to, but with the `-g` flag, you can reverse it and show which users belong in a group:

    sudo lid -g wheel

The output will show you the usernames and UIDs that are associated with the group. This is a good way of confirming that your previous commands were successful, and that the user has the privileges that they need.

## Deleting Users

If you have a user account that you no longer need, it’s best to delete the old account. You have a couple of methods to do so, though the choice of which method to use depends on your own situation.

If you want to delete the user without deleting any of their files, type this command as `root`:

    userdel username

If you want to delete the user’s home directory along with the user account itself, type this command as `root`:

    userdel -r username

**Note:** Remember to add `sudo` ahead of the command if you are signed in as a non-root user with `sudo` privileges.

With either command, the user will automatically be removed from any groups that they were added to, including the `wheel` group if they were given `sudo` privileges. If you later add another user with the same name, they will have to be added to the `wheel` group again to gain `sudo` access.

## Conclusion

You should now have a good grasp on how to add and remove users from your CentOS 7 server. Effective user management will allow you to separate users and give them only the access that is needed for them to do their job. You can now move on to configuring your CentOS 7 server for whatever software you need, such as a [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7) or [LEMP](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7) web stack.

For more information about how to configure `sudo`, check out our guide on [how to edit the sudoers file](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).
