---
author: Mitchell Anicas
date: 2016-03-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-sudo-user-on-ubuntu-quickstart
---

# How To Create a Sudo User on Ubuntu [Quickstart]

The `sudo` command provides a mechanism for granting administrator privileges, ordinarily only available to the root user, to normal users. This guide will show you the easiest way to create a new user with sudo access on Ubuntu, without having to modify your server’s `sudoers` file. If you want to configure sudo for an existing user, simply skip to step 3.

## Steps to Create a New Sudo User

1. Log in to your server as the `root` user.

2. Use the `adduser` command to add a new user to your system.

3. Use the `usermod` command to add the user to the `sudo` group.

4. Test sudo access on new user account

## Related Tutorials

Here is a link to a more detailed user management tutorial:

- [How To Add and Delete Users on an Ubuntu Server](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps)
