---
author: Henrique Pinheiro
date: 2013-08-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-a-simple-shell-script-on-a-vps
---

# How To Write a Simple Shell Script on a VPS

## Introduction

This tutorial is aimed at teaching you how to write shell scripts for the most variety of purposes. Shell scripts can be used to run multiple commands, a single command with difficult and extensive arguments, or more user friendly interfaces for distributing your work. Essentially it makes your life easier by automating stuff you’d have to do manually without it.

## Setting Up a Folder

Before you start writing your shell script, it’s a good practice to designate it a folder. It’s recommended that, for personal scripts, you do it over at ~/bin. To create that folder, run:

    mkdir ~/bin

And to make scripts run from anywhere in the system, edit your /etc/profile by running:

    sudo nano /etc/profile

Then add the following lines to the end of the file:

    PATH=$PATH:$HOME/bin export PATH

Remember to CTRL+O to save and CTRL+X to exit. You can make the changes go into effect by running:

    source /etc/profile

If your Linux distribution doesn’t support the source command, you can also reboot the VPS by typing:

    sudo reboot

## Creating a File

To start your shell script, you’ll need to create an executable file. This can be easily achieved by running:

    touch ~/bin/firstscript chmod +x ~/bin/firstscript

Open the nano text editor to start adding commands:

    nano ~/bin/firstscript

For the program loader to recognize this executable file as a shell script and run commands from the right directory, you have to add the following line to the top of the file:

    #!/bin/sh

And you’re ready to add whichever Linux command you wish, such as:

    clear echo “Hello World!”

After saving (CTRL+O) and exiting (CTRL+X) nano, to run your script, simply type in:

    firstscript

from anywhere in your system. The result should be something like this:

 ![Test script running](https://assets.digitalocean.com/tutorial_images/PPFoJ5f.png)
## Example Script

One of the main points of shell scripts are making shortcuts for repetitive tasks. For example, if you're moving a lot of files to your ~/backup folder, you could setup a script that would simply drop anything you specify. The way it would work is by typing:

    filebackup file-name1 file-name2...

Then, when you need it, it’ll be there. Before we start coding, let’s take a look at what you’ll need to learn. Well written shell scripts are not hardcoded. That means, on this example's scope, if you want to change your backup folder, you can easily do so by only changing one of the first lines in the script. Yes, the variable that corresponds to it will only be referenced once, but it’ll really help you later if you get used to do it now. To test this, you won’t need to jump into the text editor, do it straight from the command line by typing:

    testvariable=teststring

The “echo” command outputs text. By running:

    echo $testvariable

You’ll be able to see the value you set for it, which in this case is “teststring”. Now you can start coding it by doing the usual.

    touch ~/bin/filebackup chmod +x ~/bin/filebackup nano ~/bin/filebackup

Remember, any given line that starts with a ‘#’ is a comment. It won’t impact your program in any way, except when it’s followed by an exclamation point at the first line of your program, which then turns into a “shebang”, as explained earlier when the “#!/bin/sh” line was introduced. This is what the script could look like:

    #!/bin/sh #Backup script #Description: makes a copy of any given file at the backup folder #Author: Your Name #Date: 8/10/2013 #Backup folder; set this variable to any folder you have write permissions on BACKUPFOLDER=~/backup #The script will make sure the folder exists mkdir -p $BACKUPFOLDER #Now the script will copy the given file to the folder cp -a $@ $BACKUPFOLDER

Now, after you’ve saved (CTRL+O) and exited (CTRL+X), let’s review the code. The first few lines were only comments. We then specified with a BACKUPFOLDER variable where we wanted our files backed up. We proceeded to run “mkdir -p $BACKUPFOLDER”. What that does is that it creates the folder, but doesn’t give out any errors if it already exists. On the next command, the “cp” one, we placed every argument that proceeded the call for the script with "$@". Arguments on this context are all the filenames you place after the script is called to be backed up. Just after that there's the destination folder, in this case "$BACKUPFOLDER". You can now test your script by going to any folder on your system with a couple of files and running:

    filebackup file1 file2

You can add as many files as you want to that line and they’ll all be copied to the backup folder.

## Conclusion

Shell scripts are everywhere on Linux systems, and it’s for a reason. They’re extremely useful and possibilities are incredibly high. This tutorial only covers the basics, there is much more to learn.
