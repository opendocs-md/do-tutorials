---
author: Henrique Pinheiro
date: 2013-10-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-a-simple-shell-script-on-a-vps-part-3
---

# How To Write a Simple Shell Script on a VPS (Part 3)

## Introduction

Conditional statements are indispensable to any useful scripting and full-featured programming language. On the third part of our Shell Script tutorial, you'll learn all the "if's" and "else's" of bash, and how to use them to your advantage. This article has also been written assuming you have already configured your shell script folder according to the [first tutorial](https://www.digitalocean.com/community/articles/how-to-write-a-simple-shell-script-on-a-vps).

## The "if" command

A conditional statement is used to perform certain actions if a condition is _true_ or _false_. With shell scripts, this is performed by the "if" command. It's followed by an expression that's going to be tested. This expression can also be the exit code of the execution of a command, a mathematical expression, beyond other various things. When working with exit codes, the command is pretty straightforward:

    if ls folder then echo "Folder exists" fi

If the folder exists, the echo command will run, because ls will have returned exit code 0, as in successful. Otherwise, if the folder doesn't exist, the text will not be displayed. All "if" statements need to be followed by the "then" command, and ended with "fi". If you're not working with exit codes, and want to test a mathematical expression for example, you'll need the "test" command. There are the following operators in shell script to compare numbers:

    -eq or Is equal to -ne or Is not equal to -lt or Is less than -le or Is less than or equal to -gt or Is greater than -ge or Is greater than or equal to

Test commands can be written in two ways:

    if test 4 -gt 3 or if [4 -gt 3]

Both perform exactly the same, and also require "then" and "fi". Example:

    if [20 -lt 10] then echo "What?" fi

"What?" will never be displayed, because 20 is greater than 10. Now, what if you want to display a message to the user, in case the if statement returns false?

## The "else" command

"Else", as the name implies, adds an alternative route for the if command. It's pretty basic:

    if [20 -lt 10] then echo "What?" else echo "No, 20 is greater than 10." fi

Besides mathematical expressions, you can also compare strings with if/else. They require a little different syntax, but still use the test or "[]" commands. This is the syntax:

    string = string or string equals string string != string or string does not equal string string or string is not null or not defined -n string or string is not null and exists -z string or string is null and exists

There's also a way to know file properties:

    -s file tests for a file that is not empty -f file tests if the file exists and is not a folder -d folder tests if it's a folder and not a file -w file tests if the file is writable -r file tests if the file is read-only -x file tests if the file is executable

## Nested "if's"

You can also place entire "if" statements inside others, thus creating what is called a "nested if". In the following example, we'll be learning this with the help of user input provided by read, which we learned in the [previous tutorial](https://www.digitalocean.com/community/articles/how-to-write-a-simple-shell-script-on-a-vps-part-2):

    #!/bin/bash echo "Input which file you want created" read file if [-f $file] then echo "The file already exists" else touch $file if [-w $file] then echo "The file was created and is writable" else echo "The file was created but isn't writable" fi fi

## Example Script

In this example, we are going to keep trying to improve our file backup script with what we learn. This version includes testing the backup folder to see if it exists, or if it doesn't, if it has the rights to create it. First, as usual, create the script:

    touch ~/bin/filebackup3 chmod +x ~/bin/filebackup3 nano ~/bin/filebackup3

And proceed to edit it:

    #!/bin/bash #Backup script 3.0 #Description: makes a copy of any given file at the backup folder #Author: Your Name #Date: 9/29/2013 #Request the backup folder from the user: echo -e "\e[47m\e[1m\e[32mFile Backup Utility\n\e[39m\e[0m\e[47mPlease input your backup folder:" read BACKUPFOLDER #The script will make sure the folder exists if [-d $BACKUPFOLDER] then echo "You backup folder exists and will be used." else mkdir $BACKUPFOLDER if [-d $BACKUPFOLDER] then echo "Backup folder created successfully." else echo -e "I do not have the rights to create your backup folder.\nThis script will now exit." exit 1 #exit 1 is a command that exits the script with an error code fi fi #Request files to be backed up: echo -e "\e[30mWhich files do you want backed up?\e[39m\e[49m" read FILES if [-n $FILES] then cp -a $FILES $BACKUPFOLDER else echo "File does not exist." fi

The script tells you when the backup folder you typed in doesn't exist, when it creates one, when it can't create one, and when you specify a null string when asked for the files.

## Conclusion

The more you learn, the better the programs you can create along with broader possibilities to craft new and innovative solutions. In this tutorial, our already user friendly script just got even friendlier.
