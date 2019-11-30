---
author: Brennen Bearnes
date: 2016-04-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-and-delete-users-on-ubuntu-16-04
---

# How to Add and Delete Users on Ubuntu 16.04

## Introduction

One of the most basic tasks that you should know how to do on a fresh Linux server is add and remove users. When you create a new system, you are often (such as on DigitalOcean Droplets) only given the **root** account by default.

While running as the **root** user gives you a lot of power and flexibility, it is also dangerous and can be destructive. It is almost always a better idea to add an additional, unprivileged user to do common tasks. You also should create additional accounts for any other users you may have on your system. Each user should have a different account.

You can still acquire administrator privileges when you need them through a mechanism called `sudo`. In this guide we will cover how to create user accounts, assign `sudo` privileges, and delete users.

## How To Add a User

If you are signed in as the **root** user, you can create a new user at any time by typing:

    adduser newuser

If you are signed in as a non-root user who has been given `sudo` privileges, as demonstrated [in the initial server setup guide](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04), you can add a new user by typing:

    sudo adduser newuser

Either way, you will be asked a series of questions. The procedure will be:

- Assign and confirm a password for the new user
- Enter any additional information about the new user. This is entirely optional and can be skipped by hitting **Enter** if you don’t wish to utilize these fields.
- Finally, you’ll be asked to confirm that the information you provided was correct. Enter **Y** to continue.

Your new user is now ready for use! You can now log in using the password you set up.

**Note** : Continue if you need your new user to have access to administrative functionality.

## How To Grant a User Sudo Privileges

If your new user should have the ability to execute commands with root (administrative) privileges, you will need to give the new user access to `sudo`. Let’s examine two approaches to this problem: Adding the user to a pre-defined `sudo` _user group_, and specifying privileges on a per-user basis in `sudo`’s configuration.

### Add the New User to the Sudo Group

By default, `sudo` on Ubuntu 16.04 systems is configured to extend full privileges to any user in the **sudo** group.

You can see what groups your new user is in with the `groups` command:

    groups newuser

    Outputnewuser : newuser

By default, a new user is only in their own group, which is created at the time of account creation, and shares a name with the user. In order to add the user to a new group, we can use the `usermod` command:

    usermod -aG sudo newuser

The `-aG` option here tells `usermod` to add the user to the listed groups.

### Test Your User’s Sudo Privileges

Now, your new user is able to execute commands with administrative privileges.

When signed in as the new user, you can execute commands as your regular user by typing commands as normal:

    some_command

You can execute the same command with administrative privileges by typing `sudo` ahead of the command:

    sudo some_command

You will be prompted to enter the password of the regular user account you are signed in as.

### Specifying Explicit User Privileges in /etc/sudoers

As an alternative to putting your user in the **sudo** group, you can use the `visudo` command, which opens a configuration file called `/etc/sudoers` in the system’s default editor, and explicitly specify privileges on a per-user basis.

Using `visudo` is the only recommended way to make changes to `/etc/sudoers`, because it locks the file against multiple simultaneous edits and performs a sanity check on its contents before overwriting the file. This helps to prevent a situation where you misconfigure `sudo` and are prevented from fixing the problem because you have lost `sudo` privileges.

If you are currently signed in as **root** , type:

    visudo

If you are signed in using a non-root user with `sudo` privileges, type:

    sudo visudo

Traditionally, `visudo` opened `/etc/sudoers` in the `vi` editor, which can be confusing for inexperienced users. By default on new Ubuntu installations, it should instead use `nano`, which provides a more familiar text editing experience. Use the arrow keys to move the cursor, and search for the line that looks like this:

/etc/sudoers

    root ALL=(ALL:ALL) ALL

Below this line, copy the format you see here, changing only the word “root” to reference the new user that you would like to give sudo privileges to:

/etc/sudoers

    root ALL=(ALL:ALL) ALL
    newuser ALL=(ALL:ALL) ALL

You should add a new line like this for each user that should be given full sudo privileges. When you are finished, you can save and close the file by hitting **Ctrl-X** , followed by **Y** , and then **Enter** to confirm.

## How To Delete a User

In the event that you no longer need a user, it is best to delete the old account.

You can delete the user itself, without deleting any of their files, by typing this as root:

    deluser newuser

If you are signed in as another non-root user with sudo privileges, you could instead type:

    sudo deluser newuser

If, instead, you want to delete the user’s home directory when the user is deleted, you can issue the following command as root:

    deluser --remove-home newuser

If you’re running this as a non-root user with sudo privileges, you would instead type:

    sudo deluser --remove-home newuser

If you had previously configured sudo privileges for the user you deleted, you may want to remove the relevant line again by typing:

    visudo

Or use this if you are a non-root user with sudo privileges:

    sudo visudo

    root ALL=(ALL:ALL) ALL
    newuser ALL=(ALL:ALL) ALL # DELETE THIS LINE

This will prevent a new user created with the same name from being accidentally given sudo privileges.

## Conclusion

You should now have a fairly good handle on how to add and remove users from your Ubuntu 16.04 system. Effective user management will allow you to separate users and give them only the access that they are required to do their job.

For more information about how to configure `sudo`, check out our guide on [how to edit the sudoers file](https://www.digitalocean.com/community/articles/how-to-edit-the-sudoers-file-on-ubuntu-and-centos) here.
