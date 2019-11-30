---
author: Justin Ellingwood
date: 2014-01-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-delete-and-grant-sudo-privileges-to-users-on-a-debian-vps
---

# How To Add, Delete, and Grant Sudo Privileges to Users on a Debian VPS

## Introduction

When you spin up a new server, a default account is created called `root`. This user has full system access and should be used only for administrative tasks. There are basically no restrictions on what you can do to your system as the root user, which is powerful, but extremely dangerous. Linux does not have an “undo” button.

To alleviate this risk, we can create a new user, who has less privileges, but is more appropriately suited to everyday tasks. When you need the power of an administrative user, you can access that functionality through a command called `sudo`, which will temporarily elevate the privileges of a single command.

This guide will go over how to create a new user on a Debian system. We will also cover how allow users access to the sudo command if they require administrative privileges, and how to delete users that you no longer need.

## Logging Into Your Server

To complete the steps in this guide, you will need to log into your Debian server as the **root** user.

If you created a server instance without selecting an SSH key to embed for authentication, you’ll typically receive an email with the **root** user’s password. You can use this information to log into your server as the **root** user in a terminal by typing:

    ssh root@your_server_ip_address

Enter the password you were emailed (nothing will appear on the screen as you enter your password. This is a security feature so that people nearby cannot guess your password based on its length).

If you configured your server to use SSH keys for authentication, you can use the same SSH procedure as above, but you will be automatically logged in without being asked for a password. Note that no password email will be sent to you either.

## Adding a New User

The first step is to add a new user. New users, by default, are unprivileged. This means that they will only be able to modify files in their own home directory, which is what we want.

If this is your first new user, and you are currently logged in as the root user, you can use the following syntax to create a new user:

    adduser newuser

If you are logged into a user that you added previously and gave sudo privileges, you can create a new user by invoking sudo with the same command:

    sudo adduser newuser

Either way, Debian will prompt you for more information about the user you are creating. The first piece of information you need to choose is the password for the new user.

It will ask you to select a password and then confirm it by repeating it (again, the characters you type will not appear in the window, for security purposes).

Afterwards, it will ask you for personal information about the user. You can feel free to fill this out or to leave it blank. The user will operate in entirely the same way regardless of your decision. Type `ENTER` to skip these prompts and accept the entered values.

### Accessing the New User

When you have finished these steps, your new user is now available. You can log into the new user by typing:

    exit

This will terminate your current session as **root** and allow you to log in as the new user through SSH by typing:

    ssh newuser@your_server_ip_address

This time, enter the new password you just configured for this user.

Another way to quickly switch to another user without logging out first is to use the `su` command. This command stands for substitute user and it allows you to enter the user you would like to change to. You can use it like this:

    su - newuser

This will ask you for the new user’s password. When you’ve entered it correctly, you will be changed to the new user. When you wish to exit back into your original session, simply issue the exit command again:

    exit

## Granting Users Administrative Privileges

Now that you have a new user on your system, you need to decide if this user should be able to perform administrative tasks with sudo.

If the user you created will be your primary user on the system, you usually want to enable sudo privileges so that you can do routine configuration and maintenance.

To add these privileges to our new user, we need to add the new user to the **sudo** group. By default users who belong to the **sudo** group are allowed to use the `sudo` command.

As **root** , run this command to add your new user to the sudo group (substitute the highlighted word with your new user):

    usermod -aG sudo sammy

Now, when you are logged in as your regular user, you can execute a certain command with root privileges by typing:

    sudo command_name

You will be prompted to enter _your_ user’s password (not the **root** user’s password). The command will then be executed with elevated access.

## Deleting a User

If more than one person is using your server, you should give them their own user to log in. If there is a user you created that you no longer need, it is very easy to delete it.

As a regular user with sudo privileges, you can delete a user using this syntax:

    sudo deluser --remove-home username

The `--remove-home` option will delete the user’s home directory as well.

If you are logged in as root, you do not need to add the `sudo` before the command:

    deluser --remove-home username

## Conclusion

Adding users, deleting users, and assigning sudo privileges are all basic tasks that you will most likely need to configure for any server. By becoming familiar with these processes, you will be able to set up your initial environment faster and more confidently.
