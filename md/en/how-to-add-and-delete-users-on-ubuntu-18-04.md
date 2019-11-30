---
author: Jamon Camisso
date: 2019-09-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-ubuntu-18-04
---

# How to Add and Delete Users on Ubuntu 18.04

## Introduction

Adding and removing users on a Linux system is one of the most important system administration tasks to familiarize yourself with. When you create a new system, you are often only given access to the **root** account by default.

While running as the **root** user gives you complete control over a system and its users, it is also dangerous and can be destructive. For common system administration tasks, it is a better idea to add an unprivileged user and carry out those tasks without root privileges. You can also create additional unprivileged accounts for any other users you may have on your system. Each user on a system should have their own separate account.

For tasks that require administrator privileges, there is a tool installed on Ubuntu systems called `sudo`. Briefly, `sudo` allows you to run a command as another user, including users with administrative privileges. In this guide we will cover how to create user accounts, assign `sudo` privileges, and delete users.

## Prerequisites

To follow along with this guide, you will need:

- Access to a server running Ubuntu 18.04. Ensure that you have **root** access to the server. To set this up, follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04). 

## Adding a User

If you are signed in as the **root** user, you can create a new user at any time by typing:

    adduser newuser

If you are signed in as a non-root user who has been given `sudo` privileges, you can add a new user by typing:

    sudo adduser newuser

Either way, you will be asked a series of questions. The procedure will be:

- Assign and confirm a password for the new user
- Enter any additional information about the new user. This is entirely optional and can be skipped by hitting `ENTER` if you don’t wish to utilize these fields.
- Finally, you’ll be asked to confirm that the information you provided was correct. Enter `Y` to continue.

Your new user is now ready for use. You can now log in using the password that you entered.

If you need your new user to have access to administrative functionality, continue on to the next section.

## Granting a User Sudo Privileges

If your new user should have the ability to execute commands with root (administrative) privileges, you will need to give the new user access to `sudo`. Let’s examine two approaches to this problem: adding the user to a pre-defined **sudo** [_user group_](https://en.wikipedia.org/wiki/Group_identifier), and specifying privileges on a per-user basis in `sudo`’s configuration.

### Adding the New User to the Sudo Group

By default, `sudo` on Ubuntu 18.04 systems is configured to extend full privileges to any user in the **sudo** group.

You can see what groups your new user is in with the `groups` command:

    groups newuser

    Outputnewuser : newuser

By default, a new user is only in their own group which `adduser` creates along with the user profile. A user and its own group share the same name. In order to add the user to a new group, we can use the `usermod` command:

    usermod -aG sudo newuser

The `-aG` option here tells `usermod` to add the user to the listed groups.

### Specifying Explicit User Privileges in /etc/sudoers

As an alternative to putting your user in the **sudo** group, you can use the `visudo` command, which opens a configuration file called `/etc/sudoers` in the system’s default editor, and explicitly specify privileges on a per-user basis.

Using `visudo` is the only recommended way to make changes to `/etc/sudoers`, because it locks the file against multiple simultaneous edits and performs a sanity check on its contents before overwriting the file. This helps to prevent a situation where you misconfigure `sudo` and are prevented from fixing the problem because you have lost `sudo` privileges.

If you are currently signed in as **root** , type:

    visudo

If you are signed in as a non-root user with `sudo` privileges, type:

    sudo visudo

Traditionally, `visudo` opened `/etc/sudoers` in the `vi` editor, which can be confusing for inexperienced users. By default on new Ubuntu installations, `visudo` will instead use `nano`, which provides a more convenient and accessible text editing experience. Use the arrow keys to move the cursor, and search for the line that looks like this:

/etc/sudoers

    root ALL=(ALL:ALL) ALL

Below this line, add the following highlighted line. Be sure to change `newuser` to the name of the user profile that you would like to grant `sudo` privileges:

/etc/sudoers

    root ALL=(ALL:ALL) ALL
    newuser ALL=(ALL:ALL) ALL

Add a new line like this for each user that should be given full `sudo` privileges. When you are finished, you can save and close the file by hitting `CTRL+X`, followed by `Y`, and then `ENTER` to confirm.

## Testing Your User’s Sudo Privileges

Now, your new user is able to execute commands with administrative privileges.

When signed in as the new user, you can execute commands as your regular user by typing commands as normal:

    some_command

You can execute the same command with administrative privileges by typing `sudo` ahead of the command:

    sudo some_command

You will be prompted to enter the password of the regular user account you are signed in as.

## Deleting a User

In the event that you no longer need a user, it is best to delete the old account.

You can delete the user itself, without deleting any of their files, by typing the following command as **root** :

    deluser newuser

If you are signed in as another non-root user with `sudo` privileges, you could instead type:

    sudo deluser newuser

If, instead, you want to delete the user’s home directory when the user is deleted, you can issue the following command as **root** :

    deluser --remove-home newuser

If you’re running this as a non-root user with `sudo` privileges, you would instead type:

    sudo deluser --remove-home newuser

If you had previously configured `sudo` privileges for the user you deleted, you may want to remove the relevant line again by typing:

    visudo

Or use this if you are a non-root user with `sudo` privileges:

    sudo visudo

    root ALL=(ALL:ALL) ALL
    newuser ALL=(ALL:ALL) ALL # DELETE THIS LINE

This will prevent a new user created with the same name from being accidentally given `sudo` privileges.

## Conclusion

You should now have a fairly good handle on how to add and remove users from your Ubuntu 18.04 system. Effective user management will allow you to separate users and give them only the access that they are required to do their job.

For more information about how to configure `sudo`, check out our guide on [how to edit the sudoers file](https://www.digitalocean.com/community/articles/how-to-edit-the-sudoers-file-on-ubuntu-and-centos) here.
