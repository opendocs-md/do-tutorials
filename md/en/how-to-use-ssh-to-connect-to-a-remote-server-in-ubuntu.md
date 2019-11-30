---
author: Justin Ellingwood
date: 2013-09-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-ssh-to-connect-to-a-remote-server-in-ubuntu
---

# How To Use SSH to Connect to a Remote Server in Ubuntu

### What Is SSH?

One essential tool to master as a system administrator is SSH.

SSH, or _Secure Shell_, is a protocol used to securely log onto remote systems. It is the most common way to access remote Linux and Unix-like servers.

In this guide, we will discuss how to use SSH to connect to a remote system.

## Basic Syntax

The tool on Linux for connecting to a remote system using SSH is called, unsurprisingly, **ssh**.

The most basic form of the command is:

    ssh remote_host

The _remote\_host_ in this example is the IP address or domain name that you are trying to connect to.

This command assumes that your username on the remote system is the same as your username on your local system.

If your username is different on the remote system, you can specify it by using this syntax:

    ssh remote_username@remote_host

Once you have connected to the server, you will probably be asked to verify your identity by providing a password.

Later, we will cover how to generate keys to use instead of passwords.

To exit back into your local session, simply type:

    exit

## How Does SSH Work?

SSH works by connecting a client program to an **ssh server**.

In the above commands, _ssh_ is the client program. The _ssh server_ is already running on the _remote\_host_ that we specified.

In your Droplet, the sshd server should already be running. If this is not the case, click on the _Console Access_ button from your Droplet page:

![DigitalOcean Console Button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-use-ssh/small-000.png)

You will be presented with a login screen. Log in with your credentials.

The process needed to start an ssh server depends on the distribution of Linux that you are using.

On Ubuntu, you can start the ssh server on the Droplet by typing:

    sudo service ssh start

On Ubuntu 16.04 and Debian Jessie, you can use `systemctl`, the `systemd` command for managing services:

    sudo systemctl start ssh

That should start the sshd server and you can then log in remotely.

## How To Configure SSH

When you change the configuration of SSH, you are changing the settings of the sshd server.

In Ubuntu, the main sshd configuration file is located at _/etc/ssh/sshd\_config_.

Back up the current version of this file before editing:

    sudo cp /etc/ssh/sshd_config{,.bak}

Open it with a text editor:

    sudo nano /etc/ssh/sshd_config

You will want to leave most of the options in this file alone. However, there are a few you may want to take a look at:

/etc/ssh/sshd\_config

    Port 22

The port declaration specifies which port the sshd server will listen on for connections. By default, this is 22. You should probably leave this setting alone, unless you have specific reasons to do otherwise. If you _do_ change your port, we will show you how to connect to the new port later on.

/etc/ssh/sshd\_config

    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_dsa_key
    HostKey /etc/ssh/ssh_host_ecdsa_key

The host keys declarations specify where to look for global host keys. We will discuss what a host key is later.

/etc/ssh/sshd\_config

    SyslogFacility AUTH
    LogLevel INFO

These two items indicate the level of logging that should occur.

If you are having difficulties with SSH, increasing the amount of logging may be a good way to discover what the issue is.

/etc/ssh/sshd\_config

    LoginGraceTime 120
    PermitRootLogin yes
    StrictModes yes

These parameters specify some of the login information.

**LoginGraceTime** specifies how many seconds to keep the connection alive without successfully logging in.

It may be a good idea to set this time just a little bit higher than the amount of time it takes you to log in normally.

**PermitRootLogin** selects whether root is allowed to log in.

In most cases, this should be changed to “no” when you have created user account that has access to elevated privileges (through su or sudo) and can log in through ssh.

**strictModes** is a safety guard that will refuse a login attempt if the authentication files are readable by everyone.

This prevents login attempts when the configuration files are not secure.

/etc/ssh/sshd\_config

    X11Forwarding yes
    X11DisplayOffset 10

These parameters configure an ability called _X11 Forwarding_. This allows you to view a remote system’s graphical user interface (GUI) on the local system.

This option must be enabled on the server and given with the SSH client during connection with the `-X` option.

After making your changes, save and close the file by typing `CTRL-X` and `Y`, followed by `ENTER`.

* * *

If you changed any settings in `/etc/ssh/sshd_config`, make sure you restart your sshd server to implement your modifications:

    sudo service ssh restart

Or, on `systemd` systems such as Ubuntu 16.04 or Debian Jessie:

    sudo systemctl restart ssh

You should thoroughly test your changes to ensure that they operate in the way you expect.

It may be a good idea to have a few sessions active when you are making changes. This will allow you to revert the configuration if necessary.

If you run into problems, remember that you can log in through the _Console_ link on your Droplet page.

## How To Log Into SSH with Keys

While it is helpful to be able to log in to a remote system using passwords, it’s a much better idea to set up _key-based authentication_.

### How Does Key-based Authentication Work?

Key-based authentication works by creating a pair of keys: a _private key_ and a _public key_.

The _private key_ is located on the client machine and is secured and kept secret.

The _public key_ can be given to anyone or placed on any server you wish to access.

When you attempt to connect using a key-pair, the server will use the public key to create a message for the client computer that can only be read with the private key.

The client computer then sends the appropriate response back to the server and the server will know that the client is legitimate.

This entire process is done in the background automatically after you set up keys.

### How To Create SSH Keys

SSH keys should be generated on the computer you wish to log in _from_. This is usually your local computer.

Enter the following into the command line:

    ssh-keygen -t rsa

Press enter to accept the defaults. Your keys will be created at _~/.ssh/id\_rsa.pub_ and _~/.ssh/id\_rsa_.

Change into the `.ssh` directory by typing:

    cd ~/.ssh

Look at the permissions of the files:

    ls -l

    Output-rw-r--r-- 1 demo demo 807 Sep 9 22:15 authorized_keys
    -rw------- 1 demo demo 1679 Sep 9 23:13 id_rsa
    -rw-r--r-- 1 demo demo 396 Sep 9 23:13 id_rsa.pub

As you can see, the `id_rsa` file is readable and writable only to the owner. This is how it should be to keep it secret.

The `id_rsa.pub` file, however, can be shared and has permissions appropriate for this activity.

### How To Transfer Your Public Key to the Server

You can copy the public key to the remote server by issuing this command:

    ssh-copy-id remote_host

This will start an SSH session, which you will need to authenticate with your password.

After you enter your password, it will copy your public key to the server’s authorized keys file, which will allow you to log in without the password next time.

## Client-Side Options

There are a number of optional flags that you can select when connecting through SSH.

Some of these may be necessary to match the settings in the remote host’s sshd configuration.

For instance, if you changed the port number in your sshd configuration, you will need to match that port on the client-side by typing:

    ssh -p port_number remote_host

If you only wish to execute a single command on a remote system, you can specify it after the host like so:

    ssh remote_host command_to_run

You will connect to the remote machine, authenticate, and the command will be executed.

As we said before, if X11 forwarding is enabled on both computers, you can access that functionality by typing:

    ssh -X remote_host

Providing you have the appropriate tools on your computer, GUI programs that you use on the remote system will now open their window on your local system.

## Disabling Password Authentication

If you have created SSH keys, you can enhance your server’s security by disabling password-only authentication. Apart from the console, the only way to log into your server will be through the private key that pairs with the public key you have installed on the server.

**Note:** Before you proceed with this step, be sure you have installed a public key to your server. Otherwise, you will be locked out!

As **root** or a **non-root user with sudo privileges,** open the sshd configuration file:

    sudo nano /etc/ssh/sshd_config

Locate the line that reads `Password Authentication`, and uncomment it by removing the leading `#`. You can then change its value to “no”:

sshd\_config — Disable password authentication

    PasswordAuthentication no

Two more settings that should not need to be modified (provided you have not modified this file before) are `PubkeyAuthentication` and `ChallengeResponseAuthentication`. They are set by default, and should read as follows:

sshd\_config — Important defaults

    PubkeyAuthentication yes
    ChallengeResponseAuthentication no

After making your changes, save and close the file.

You can now reload the SSH daemon:

    sudo systemctl restart ssh

Password authentication should now be disabled, and your server should be accessible only through SSH key authentication.

## Conclusion

Learning your way around SSH is a worthwhile pursuit, if only because it is such a common activity.

As you utilize the various options, you will discover more advanced functionality that can make your life easier. SSH has remained popular because it is secure, light-weight, and useful in diverse situations.
