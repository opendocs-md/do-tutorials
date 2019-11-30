---
author: Justin Ellingwood
date: 2014-04-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04
---

# Initial Server Setup with Ubuntu 14.04

## Introduction

When you first create a new Ubuntu 14.04 server, there are a few configuration steps that you should take early on as part of the basic setup. This will increase the security and usability of your server and will give you a solid foundation for subsequent actions.

## Step One — Root Login

To log into your server, you will need to know your server’s public IP address and the password for the “root” user’s account. If you have not already logged into your server, you may want to follow the first tutorial in this series, [How to Connect to Your Droplet with SSH](how-to-connect-to-your-droplet-with-ssh), which covers this process in detail.

If you are not already connected to your server, go ahead and log in as the `root` user using the following command (substitute the highlighted word with your server’s public IP address):

    ssh root@SERVER_IP_ADDRESS

Complete the login process by accepting the warning about host authenticity, if it appears, then providing your root authentication (password or private key). If it is your first time logging into the server, with a password, you will also be prompted to change the root password.

### About Root

The root user is the administrative user in a Linux environment that has very broad privileges. Because of the heightened privileges of the root account, you are actually _discouraged_ from using it on a regular basis. This is because part of the power inherent with the root account is the ability to make very destructive changes, even by accident.

The next step is to set up an alternative user account with a reduced scope of influence for day-to-day work. We’ll teach you how to gain increased privileges during the times when you need them.

## Step Two — Create a New User

Once you are logged in as `root`, we’re prepared to add the new user account that we will use to log in from now on.

This example creates a new user called “demo”, but you should replace it with a user name that you like:

    adduser demo

You will be asked a few questions, starting with the account password.

Enter a strong password and, optionally, fill in any of the additional information if you would like. This is not required and you can just hit “ENTER” in any field you wish to skip.

## Step Three — Root Privileges

Now, we have a new user account with regular account privileges. However, we may sometimes need to do administrative tasks.

To avoid having to log out of our normal user and log back in as the root account, we can set up what is known as “super user” or root privileges for our normal account. This will allow our normal user to run commands with administrative privileges by putting the word `sudo` before each command.

To add these privileges to our new user, we need to add the new user to the “sudo” group. By default, on Ubuntu 14.04, users who belong to the “sudo” group are allowed to use the `sudo` command.

As `root`, run this command to add your new user to the _sudo_ group (substitute the highlighted word with your new user):

    gpasswd -a demo sudo

Now your user can run commands with super user privileges! For more information about how this works, check out [this sudoers tutorial](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).

## Step Four — Add Public Key Authentication (Recommended)

The next step in securing your server is to set up public key authentication for your new user. Setting this up will increase the security of your server by requiring a private SSH key to log in.

### Generate a Key Pair

If you do not already have an SSH key pair, which consists of a public and private key, you need to generate one. If you already have a key that you want to use, skip to the _Copy the Public Key_ step.

To generate a new key pair, enter the following command at the terminal of your **local machine** (ie. your computer):

    ssh-keygen

Assuming your local user is called “localuser”, you will see output that looks like the following:

    ssh-keygen outputGenerating public/private rsa key pair.
    Enter file in which to save the key (/Users/localuser/.ssh/id_rsa):

Hit return to accept this file name and path (or enter a new name).

Next, you will be prompted for a passphrase to secure the key with. You may either enter a passphrase or leave the passphrase blank.

**Note:** If you leave the passphrase blank, you will be able to use the private key for authentication without entering a passphrase. If you enter a passphrase, you will need both the private key _and_ the passphrase to log in. Securing your keys with passphrases is more secure, but both methods have their uses and are more secure than basic password authentication.

This generates a private key, `id_rsa`, and a public key, `id_rsa.pub`, in the `.ssh` directory of the _localuser_’s home directory. Remember that the private key should not be shared with anyone who should not have access to your servers!

### Copy the Public Key

After generating an SSH key pair, you will want to copy your public key to your new server. We will cover two easy ways to do this.

**Note** : The `ssh-copy-id` method will not work on DigitalOcean if an SSH key was selected during Droplet creation. This is because DigitalOcean disables password authentication if an SSH key is present, and the `ssh-copy-id` relies on password authentication to copy the key.

If you are using DigitalOcean and selected an SSH key during Droplet creation, use option 2 instead.

### Option 1: Use ssh-copy-id

If your local machine has the `ssh-copy-id` script installed, you can use it to install your public key to any user that you have login credentials for.

Run the `ssh-copy-id` script by specifying the user and IP address of the server that you want to install the key on, like this:

    ssh-copy-id demo@SERVER_IP_ADDRESS

After providing your password at the prompt, your public key will be added to the remote user’s `.ssh/authorized_keys` file. The corresponding private key can now be used to log into the server.

### Option 2: Manually Install the Key

Assuming you generated an SSH key pair using the previous step, use the following command at the terminal of your **local machine** to print your public key (`id_rsa.pub`):

    cat ~/.ssh/id_rsa.pub

This should print your public SSH key, which should look something like the following:

    id_rsa.pub contentsssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local

Select the public key, and copy it to your clipboard.

#### Add Public Key to New Remote User

To enable the use of SSH key to authenticate as the new remote user, you must add the public key to a special file in the user’s home directory.

**On the server** , as the `root` user, enter the following command to switch to the new user (substitute your own user name):

    su - demo

Now you will be in your new user’s home directory.

Create a new directory called `.ssh` and restrict its permissions with the following commands:

    mkdir .ssh
    chmod 700 .ssh

Now open a file in _.ssh_ called `authorized_keys` with a text editor. We will use _nano_ to edit the file:

    nano .ssh/authorized_keys

Now insert your public key (which should be in your clipboard) by pasting it into the editor.

Hit `CTRL-X` to exit the file, then `Y` to save the changes that you made, then `ENTER` to confirm the file name.

Now restrict the permissions of the _authorized\_keys_ file with this command:

    chmod 600 .ssh/authorized_keys

Type this command _once_ to return to the `root` user:

    exit

Now you may SSH login as your new user, using the private key as authentication.

To read more about how key authentication works, read this tutorial: [How To Configure SSH Key-Based Authentication on a Linux Server](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

## Step Five — Configure SSH Daemon

Now that we have our new account, we can secure our server a little bit by modifying its SSH daemon configuration (the program that allows us to log in remotely) to disallow remote SSH access to the **root** account.

Begin by opening the configuration file with your text editor as root:

    nano /etc/ssh/sshd_config

Next, we need to find the line that looks like this:

/etc/ssh/sshd\_config (before)

    PermitRootLogin yes

Here, we have the option to disable root login through SSH. This is generally a more secure setting since we can now access our server through our normal user account and escalate privileges when necessary.

Modify this line to “no” like this to disable root login:

/etc/ssh/sshd\_config (after)

    PermitRootLogin no

Disabling remote root login is highly recommended on every server!

When you are finished making your changes, save and close the file using the method we went over earlier (`CTRL-X`, then `Y`, then `ENTER`).

## Step Six – Reload SSH

Now that we have made our change, we need to restart the SSH service so that it will use our new configuration.

Type this to restart SSH:

    service ssh restart

Now, before we log out of the server, we should **test** our new configuration. We do not want to disconnect until we can confirm that new connections can be established successfully.

Open a **new** terminal window on your local machine. In the new window, we need to begin a new connection to our server. This time, instead of using the root account, we want to use the new account that we created.

For the server that we showed you how to configure above, you would connect using this command. Substitute your own user name and server IP address where appropriate:

    ssh demo@SERVER_IP_ADDRESS

**Note:** If you are using PuTTY to connect to your servers, be sure to update the session’s _port_ number to match your server’s current configuration.

You will be prompted for the new user’s password that you configured. After that, you will be logged in as your new user.

Remember, if you need to run a command with root privileges, type “sudo” before it like this:

    sudo command_to_run

If all is well, you can exit your sessions by typing:

    exit

## Where To Go From Here?

At this point, you have a solid foundation for your server. You can install any of the software you need on your server now.

If you are not sure what you want to do with your server, check out the next tutorial in this series for [Additional Recommended Steps for New Ubuntu 14.04 Servers](additional-recommended-steps-for-new-ubuntu-14-04-servers). It covers things like basic firewall settings, NTP, and swap files. It also provides links to tutorials that show you how to set up common web applications. You may also want to check out [this guide](how-to-install-and-use-fail2ban-on-ubuntu-14-04) to learn how to enable `fail2ban` to reduce the effectiveness of brute force attacks.

If you just want to explore, take a look at the rest of our [community](https://digitalocean.com/community/articles) to find more tutorials. Some popular ideas are configuring a [LAMP stack](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04) or a [LEMP stack](https://www.digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04), which will  
allow you to host websites.
