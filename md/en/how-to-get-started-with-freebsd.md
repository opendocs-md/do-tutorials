---
author: Mark Drake, Justin Ellingwood
date: 2018-10-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-get-started-with-freebsd
---

# How to Get Started with FreeBSD

## Introduction

[FreeBSD](https://www.freebsd.org/) is a secure, high performance operating system that is suitable for a variety of server roles. In this guide, we will cover some basic information about how to get started with a FreeBSD server.

This guide is intended to provide a general setup for FreeBSD servers, but please be aware that different versions of FreeBSD may have different functionalities. Depending on which version of FreeBSD your server is running, the instructions provided here may not work as described.

## Logging in with SSH

The first step you need to take to begin configuring your FreeBSD server is to log in.

On DigitalOcean, you must provide a public SSH key when creating a FreeBSD server. This key is added to the server instance, allowing you to securely log in from your local machine using the associated private key. To learn more about how to use SSH keys with FreeBSD on DigitalOcean, [follow this guide](how-to-configure-ssh-key-based-authentication-on-a-freebsd-server).

To log in to your server, you will need to know your server’s public IP address. For DigitalOcean Droplets, you can find this information in the control panel. The main user account available on FreeBSD servers created through DigitalOcean is called **freebsd**. This user account is configured with `sudo` privileges, allowing you to complete administrative tasks.

To log in to your FreeBSD server, use the `ssh` command. You will need to specify the **freebsd** user account along with your server’s public IP address:

    ssh freebsd@your_server_ip

You should be automatically authenticated and logged in. You will be dropped into a command line interface.

## Changing the Default Shell to tcsh (Optional)

If you logged into a DigitalOcean Droplet running FreeBSD 11, you will be presented with a very minimal command prompt that looks like this:

    

If you’re new to working with FreeBSD, this prompt may look somewhat unfamiliar to you. Let’s get some clarity on what kind of environment we’re working in. Run the following command to see what the default shell for your **freebsd** user is:

    echo $SHELL

    Output/bin/sh

In this output, you can see that the default shell for the **freebsd** user is `sh` (also known as the _Bourne shell_). On Linux systems, `sh` is often an alias for `bash`, a free software replacement for the Bourne shell that includes a few extra features. In FreeBSD, however, it’s actually the classic `sh` shell program, rather than an alias.

The default command line shell for FreeBSD is `tcsh`, but DigitalOcean Droplets running FreeBSD use `sh` by default. If you’d like to set `tcsh` as your **freebsd** user’s default shell, run the following command:

    sudo chsh -s /bin/tcsh freebsd

The next time you log in to your server, you will see the `tcsh` prompt instead of the `sh` prompt. You can invoke the `tcsh` shell for the current session by running:

    tcsh

Your prompt should immediately change to the following:

    

If you ever want to return to the Bourne shell you can do so with the `sh` command.

Although `tcsh` is typically the default shell for FreeBSD systems, it has a few default settings that users tend to tweak on their own, such as the default pager and editor, as well as the behaviors of certain keys. To illustrate how to change some of these defaults, we will modify the shell’s configuration file.

An example configuration file is already included in the filesystem. Copy it into your home directory so that you can modify it as you wish:

    cp /usr/share/skel/dot.cshrc ~/.cshrc

After the file has been copied into your home directory, you can edit it. The `vi` editor is included on the system by default, but if you want a simpler editor, you can try the `ee` editor instead:

    ee ~/.cshrc

As you go through this file, you can decide what entries you may want to modify. In particular, you may want to change the `setenv` entries to have specific defaults that you may be more familiar with.

~/.cshrc

    . . .
    
    setenv EDITOR vi
    setenv PAGER more
    
    . . .

If you are not familiar with the `vi` editor and would like a more basic editing environment, you could change the `EDITOR` environment variable to something like `ee`. Most users will want to change the `PAGER` to `less` instead of `more`. This will allow you to scroll up and down in man pages without exiting the pager:

~/.cshrc

    . . .
    setenv EDITOR ee
    setenv PAGER less
    . . .

Another thing that you will likely want to add to this configuration file is a block of code that will correctly map some of your keyboard keys inside the `tcsh` session. At the bottom of the file, add the following code. Without these lines, `DELETE` and other keys will not work correctly:

~/.cshrc

    . . .
    if ($term == "xterm" || $term == "vt100" \
                || $term == "vt102" || $term !~ "con*") then
              # bind keypad keys for console, vt100, vt102, xterm
              bindkey "\e[1~" beginning-of-line # Home
              bindkey "\e[7~" beginning-of-line # Home rxvt
              bindkey "\e[2~" overwrite-mode # Ins
              bindkey "\e[3~" delete-char # Delete
              bindkey "\e[4~" end-of-line # End
              bindkey "\e[8~" end-of-line # End rxvt
    endif

When you are finished, save and close the file by pressing `CTRL+C`, typing `exit`, and then pressing `ENTER`. If you instead edited the file with `vi`, save and close the file by pressing `ESC`, typing `:wq`, and then pressing `ENTER`.

To make your current session reflect these changes immediately, source the configuration file:

    source ~/.cshrc

It might not be immediately apparent, but the **Home** , **Insert** , **Delete** , and **End** keys will work as expected now.

One thing to note at this point is that if you are using the `tcsh` or `csh` shells, you will need to execute the `rehash` command whenever any changes are made that may affect the executable path. Common scenarios where this may happen occur when you are installing or uninstalling applications.

After installing programs, you may need to type this in order for the shell to find the new application files:

    rehash

With that, the `tcsh` shell is not only set as your **freebsd** user’s default, but it is also much more usable.

## Setting bash as the Default Shell (Optional)

If you are more familiar with the `bash` shell and would prefer to use that as your default shell, you can make that adjustment in a few short steps.

**Note:** `bash` is not supported on FreeBSD 11.1, and the instructions in this section will not work for that particular version.

First, you need to install the `bash` shell by typing:

    sudo pkg install bash

You will be prompted to confirm that you want to download the package. Do so by pressing `y` and then `ENTER`.

After the installation is complete, you can start `bash` by running:

    bash

This will update your shell prompt to look like this:

    

To change **freebsd** ’s default shell to `bash`, you can type:

    sudo chsh -s /usr/local/bin/bash freebsd

The next time you log in, the `bash` shell will be started automatically instead of the current default.

If you wish to change the default pager or editor in the `bash` shell, you can do so in a file called `~/.bash_profile`. This will not exist by default, so you will need to create it:

    ee ~/.bash_profile

Inside, to change the default pager or editor, add your selections like this:

~/.bash\_profile

    export PAGER=less
    export EDITOR=ee

Save and close the file when you are finished by pressing `CTRL+C`, typing `exit`, and then pressing `ENTER`.

To implement your changes immediately, `source` the file:

    source ~/.bash_profile

If you’d like to make further changes to your shell environment, like setting up special command aliases or setting environment variables, you can reopen that file and add your new changes to it.

## Setting a Root Password (Optional)

By default, FreeBSD servers do not allow `ssh` logins for the **root** account. On DigitalOcean, this policy has been supplemented to tell users to log in with the **freebsd** account.

Because the **root** user account is inaccessible over SSH, it is relatively safe to set a **root** account password. While you will not be able to use this to log in through SSH, you can use this password to log in as **root** through the DigitalOcean web console.

To set a **root** password, type:

    sudo passwd

You will be asked to select and confirm a password for the **root** account. As mentioned above, you still won’t be able to use this for SSH authentication (this is a security decision), but you will be able to use it to log in through the DigitalOcean console.

To do so, click the **Console** button in the upper-right corner of your Droplet’s page to bring up the web console:

![DigitalOcean web console](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_set_pass/console_access_2018.png)

If you choose _not_ to set a password and you get locked out of your server (for instance if you accidentally set overly restrictive firewall rules), you can always set one later by booting your Droplet into single user mode. We have a guide that shows you how to do that [here](https://www.digitalocean.com/docs/droplets/resources/freebsd-lost-password/).

## Conclusion

By now, you should know how to log into a FreeBSD server and how to set up a bash shell environment. A good next step is to familiarize yourself with some FreeBSD basics as well as what makes it different from Linux-based distributions.

- [A Comparative Introduction to FreeBSD for Linux Users](a-comparative-introduction-to-freebsd-for-linux-users)
- [An Introduction to Basic FreeBSD Maintenance](an-introduction-to-basic-freebsd-maintenance)

Once you become familiar with FreeBSD and configure it to your needs, you will be able to take greater advantage of its flexibility, security, and performance.
