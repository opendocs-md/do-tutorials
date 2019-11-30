---
author: Brian Rogers
date: 2013-08-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-git-server-on-a-vps
---

# How To Set Up a Private Git Server on a VPS

## Introduction

This tutorial will show you how to set up a fully fledged Git server using SSH keys for authentication. It will not have a web interface, this will just cover getting Git installed and your access to it set up. We'll use the host "git.droplet.com" in place of the domain you will use for your VPS.

This can be a great option if you want to keep your code private while you work. While open-souce tends to be the status quo, there are some times when you don't want to have your code freely available. An example would be if you are developing a mobile app, especially a paid one. Keep in mind this code can be read by anyone if they know the URL address to use for a clone, but that is only if they know it.

There is one major concern for many and that is a web interface to your repositories. GitHub accomplishes this amazingly well. There are applications that you can install such as [Gitosis](https://wiki.archlinux.org/index.php/Gitosis), [GitList](http://gofedora.com/insanely-awesome-web-interface-git-repos/), and [Goblet](http://git.kaarsemaker.net/). We don't go over those in this tutorial, but if you rely heavily on a graphic interface then you may want to look over those and think about installing one of them as soon as you done installing your Git server.

## Create the SSH Key Pair

First, we need to generate a SSH key pair. If you are using Mac or Linux, you can simply issue the following command in a terminal, but replace the email address with your own:

     ssh-keygen -C "youremail@mailprovider.com" Generating public/private rsa key pair. Enter file in which to save the key (/home/flynn/.ssh/id\_rsa): Enter passphrase (empty for no passphrase): Enter same passphrase again: Your identification has been saved in foo\_rsa. Your public key has been saved in foo\_rsa.pub. The key fingerprint is: ab:cd:ef:01:23:45:67:89:0a:bc:de:f0:12:34:56:78 flynn@en.com The key's randomart image is: +--[RSA 2048]----+ | o+-+ .. | | E o | | . ++.o.. | | o o H . | | . . = | | . =o.o= | | o . | | . | | = o . | +-----------------+ 

I highly recommend putting a password on the key files, it is one more layer of security and has a very minimal impact. If you are using Windows based operating system, there are tools available to generate key pairs, such as PuTTY Gen, though it does come with a disclaimer that you need to check with your local laws before using it as some countries have banned it's use. If that isn't the case, you may log into your VPS, create the key pair, and download both id\_rsa and id\_rsa.pub for your use.

Next, the VPS will need a user specifically for Git. Most people will simply create a user called "Git", and that is what we'll do for this tutorial but feel free to name this user whatever you'd like.

## Setup a Git User and Install Git on your VPS

Log into your VPS, and gain root\*:

    su -

\*Some people feel uncomfortable using root in this manner. If your VPS is set up to use sudo, then do so.

Add the Unix user (not necessarily Git user names) to handle the repositories:

    useradd git

Then give your Git user a password:

    passwd git

Now it's as easy as:

- CentOS/Fedora: `yum install git`
- Ubuntu/Debian: `apt-get install git`

## Add your SSH Key to the Access List

At this point, you'll want to be logged in as the Git user. If you haven't already logged in to that user, use this command to switch to it:

    su git

Now you need to upload your id\_rsa.pub file to your Git user's home directory. Once you have done that, we need let the SSH daemon know what SSH keys to accept. This is done using the authorized keys file, and it resides in the dot folder "ssh". To create this, input:

    mkdir ~/.ssh && touch ~/.ssh/authorized\_keys

Note: Using the double '&' in your command chains them, so it tells the system to execute the first command and then the second. Using the 'tilde' at the beginning of the path will tell the system to use your home directory, so '~' becomes /home/git/ to your VPS.

We are going to use the 'cat' command, which will take the contents of a file and return them to the command line. We then use the '\>\>' modifier to do something with that output rather than just print it in your console. Be careful with this, as a single '\>' will overwrite all the contents of the second file you specify. A double '\>' will append it, so make sure you know what you want to do and in most cases it will be easier to just use "\>\>" so that you can always delete what you append rather than looking to restore what you mashed over.

Each line in this file is an entry for a key that you wish to have access to this account. To add the key that you just uploaded, type the following, replacing :

    cat .ssh/id\_rsa.pub | ssh user@123.45.56.78 "cat \>\> ~/.ssh/authorized\_keys"

Now you can see the key there if you use cat on the authorized key file:

    cat ~/.ssh/authorized\_keys

If you want to add others to your access list, they simply need to give you their id\_rsa.pub key and you append it to the authorized keys file.

## Setup a Local Repository

This is a pretty simple process, you just call the Git command and initialize a bare repository in whichever directory you'd like. Let's say I want to use "My Project" as the project title. When creating the folder, I'd use all lower case, replace any spaces with hyphens, and append ".git" to the name. So "My Project" becomes "my-project.git".

To create that folder as an empty Git repository:

    git init --bare my-project.git

Thats it! You now have a Git repository set up on your VPS. Let's move on to how to use it with your local computer.

## Using your Git Server from your Local Computer

On Linux or Mac OS, you need to change the remote origin to your newly created server. If you already have a local repo that you want to push to the server, change the remote using this command:

    git remote set-url origin git@git.droplet.com:my-project.git

If this is a new repository you are setting up, use this:

    git init && git remote add origin git@git.droplet.com:my-project.git

Now you may add, push, pull, and even clone away knowing that your code is only accessible to yourself.

But what if you want a few trusted people to have access to this server and you want to keep things simple by sorting them by the names of your users? A simple and effective way to do that is to create a folder named after each person, so in the home folder for your Git user list, input:

    mkdir user1 user2

Now when you specify the remote repository, it would look like this:

    git remote add origin git@git.droplet.com:user1/user-project.git
