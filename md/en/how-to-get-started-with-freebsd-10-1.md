---
author: Justin Ellingwood
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-get-started-with-freebsd-10-1
---

# How To Get Started with FreeBSD 10.1

## Introduction

FreeBSD is a secure, high performance operating system that is suitable for a variety of server roles. In this guide, we will cover some basic information about how to get started with a FreeBSD server.

## Step One — Log In with SSH

The first step you need to take to begin configuring your FreeBSD server is to log in.

On DigitalOcean, you must provide a public SSH key when creating a FreeBSD server. This key is added to the server instance, allowing you to securely login from your home computer using the associated private key. To learn more about how to use SSH keys with FreeBSD on DigitalOcean, [follow this guide](how-to-configure-ssh-key-based-authentication-on-a-freebsd-server).

To login to your server, you will need to know your server’s public IP address. For DigitalOcean Droplets, you can find this information in the control panel. The main user account available on FreeBSD servers created through DigitalOcean is called `freebsd`. This user account is configured with `sudo` privileges, allowing you to complete administrative tasks.

To log into your FreeBSD server, use the `ssh` command. You will need to specify the `freebsd` user account along with your server’s public IP address:

    ssh freebsd@server_IP_address

You should be automatically authenticated and logged in. You will be dropped into a command line interface.

## Changing the tcsh Shell Prompt and Defaults (Optional)

When you are logged in, you will be presented with a very minimal command prompt that looks like this:

    >

This is the default prompt for `tcsh`, the standard command line shell in FreeBSD. In order to help us stay oriented within the filesystem as we move about, we will implement a more useful prompt by modifying our shell’s configuration file.

An example configuration file is included in our filesystem. We will copy it into our home directory so that we can modify it as we wish:

    cp /usr/share/skel/dot.cshrc ~/.cshrc

After the file has been copied into our home directory, we can edit it. The `vi` editor is included on the system by default. If you want a simpler editor, you can try the `ee` editor:

    vi ~/.cshrc

The file includes some reasonable defaults, including a more functional prompt. Some areas you might want to change are the `setenv` entries:

    . . .
    
    setenv EDITOR vi
    setenv PAGER more
    
    . . .

If you are not familiar with the `vi` editor and would like an easier editing environment, you should change the `EDITOR` environmental variable to something like `ee`. Most users will want to change the `PAGER` to `less` instead of `more`. This will allow you to scroll up and down in man pages without exiting the pager:

    setenv EDITOR ee
    setenv PAGER less

The other item that we should add to this configuration file is a block of code that will correctly map some of our keyboard keys inside the `tcsh` session. Without these lines, “Delete” and other keys will not work correctly. This information is found on [this page](http://www.ibb.net/%7Eanne/keyboard/keyboard.html#Tcsh) maintained by Anne Baretta. At the bottom of the file, copy and paste these lines:

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

When you are finished, save and close the file.

To make your current session reflect these changes immediately, you can source the file now:

    source ~/.cshrc

Your prompt should immediately change to look something like this:

    freebsd@hostname:~ %

It might not be immediately apparent, but the “Home”, “Insert”, “Delete”, and “End” keys also work as expected now.

One thing to note at this point is that if you are using the `tcsh` or `csh` shells, you will need to execute the `rehash` command whenever any changes are made that may affect the executable path. Common scenarios where this may happen are when installing or uninstalling applications.

After installing programs, you may need to type this in order for the shell to find the new application files:

    rehash

## Changing the Default Shell (Optional)

The above configuration gives you a fairly good `tcsh` environment. If you are more familiar with the `bash` shell and would prefer to use that as your default shell, you can easily make that adjustment.

First, you need to install the `bash` shell by typing:

    sudo pkg install bash

After the installation is complete, we need to add a line to our `/etc/fstab` file to mount the file-descriptor file system, which is needed by `bash`. You can do this easily by typing:

    sudo sh -c 'echo "fdesc /dev/fd fdescfs rw 0 0" >> /etc/fstab'

This will add the necessary line to the end of your `/etc/fstab` file. Afterwards, we can mount the filesystem by typing:

    sudo mount -a

This will mount the filesystem, allowing us to start `bash`. You can do this by typing:

    bash

To change your default shell to `bash`, you can type:

    sudo chsh -s /usr/local/bin/bash freebsd

The next time you log in, the `bash` shell will be started automatically instead of the `tcsh`.

If you wish to change the default pager or editor in the `bash` shell, you can do so in a file called `~/.bash_profile`. This will not exist by default, so we will need to create it:

    vi ~/.bash_profile

Inside, to change the default pager or editor, you can add your selections like this:

    export PAGER=less
    export EDITOR=vi

You can make many more modifications if you wish. Save and close the file when you are finished.

To implement your changes immediately, source the file:

    source ~/.bash_profile

## Set a Root Password (Optional)

By default, FreeBSD servers do not allow `ssh` logins for the `root` account. On DigitalOcean, this policy has been supplemented to tell users to log in with the `freebsd` account.

With SSH access locked to the root user account, it is relatively safe to set a root account password. While you will not be able to use this to log in through SSH, if you ever need to log in through the DigitalOcean web console, you can use this password to log into `root`.

To set a `root` password, type:

    sudo passwd

You will be asked to select and confirm a password for the `root` account. As mentioned above, you still won’t be able to use this for SSH authentication (this is a security decision), but you will be able to use it to log in through the DigitalOcean console.

Click the “Console Access” button in the upper-right corner of your Droplet’s page to bring up the web console:

![DigitalOcean web console](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_set_pass/console_access.png)

If you choose _not_ to set a password and you get locked out of your server (for instance if you accidentally set overly restrictive firewall rules), you can always set one later by booting your droplet into single user mode. We have a guide that shows you how to do that [here](how-to-set-or-reset-your-password-if-you-are-locked-out-of-a-freebsd-droplet).

## Conclusion

By now, you should know how to log into a FreeBSD server and how to set up a reasonable shell environment. A good next step is to complete some [additional recommended steps for new FreeBSD 10.1 servers](recommended-steps-for-new-freebsd-10-1-servers).

Afterwards, there are many different directions you can go. Some popular choices are:

- [A Comparative Introduction to FreeBSD for Linux Users](a-comparative-introduction-to-freebsd-for-linux-users)
- [An Introduction to Basic FreeBSD Maintenance](an-introduction-to-basic-freebsd-maintenance)
- [Installing Apache, MySQL, and PHP on FreeBSD 10.1](how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-10-1)
- [Installing Nginx, MySQL and PHP on FreeBSD 10.1](how-to-install-an-nginx-mysql-and-php-femp-stack-on-freebsd-10-1)
- [Installing WordPress with Apache on FreeBSD 10.1](how-to-install-wordpress-with-apache-on-freebsd-10-1)
- [Installing WordPress with Nginx on FreeBSD 10.1](how-to-install-wordpress-with-nginx-on-a-freebsd-10-1-server)
- [How To Install Java on FreeBSD 10.1](how-to-install-java-on-freebsd-10-1)

Once you become familiar with FreeBSD and configure it to your needs, you will be able to take advantage of its flexibility, security, and performance.
