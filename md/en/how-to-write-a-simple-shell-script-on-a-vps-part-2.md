---
author: Henrique Pinheiro
date: 2013-09-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-a-simple-shell-script-on-a-vps-part-2
---

# How To Write a Simple Shell Script on a VPS (Part 2)

## Introduction

The second part of this tutorial will teach you more basic commands for shell scripts on a VPS. They are responsible for both displaying and gathering information to and from the user. This article has been written assuming you have already configured your shell script folder according to the [first tutorial](https://www.digitalocean.com/community/articles/how-to-write-a-simple-shell-script-on-a-vps).

## The echo Command

This command enables you to display information for the user. You can display simple text strings, variables, or both of them together. It has two parameters: -n, which makes the text displayed not be followed by a new line, and -e, which enables the following set of “code” inside the string:

    \a - Alert sound \b - Backspace character \c - Don’t display new line \e - Escape character \n - New line \r - Carriage return \t - Horizontal tab \0xx - ASCII character \\ - Backslash

For example, the following commands perform exactly the same:

    echo -e "Text\c" echo -n "Text"

To display variables with echo, simply write it in the string preceded by the “$” character, like so:

    string=World! echo "Hello $string"

You can combine text, commands, and variables in a single string. You can even have multiple lines of text in the same line of code simply by having the “\n” command when you want to output a new line.

## Formatted Text with echo

Text can be displayed in a multitude of colors and styles with the echo command. Not everything works with every terminal client out there, so keep in mind that people may get different results than you get when running your script. As they’re only visual changes, it isn’t a real issue most of the time. Each customization (making the text bold, underlined or colored) are defined by escape sequences, a code that follows the escape character (which is defined by '\e'), like so:

    echo -e "This is \e[1mBold"

This is a small table with the most common codes:

    Bold: \e[1m Dim: \e[2m Underlined: \e[4m Inverted colors: \e[7m

You can mix them to create an underlined bold text, for example, and you can reset it all by typing "\e[0m".

    echo -e "\e[4mThis \e[1mis\e[0m \e[7man example \e[0mstring"

Try it out and see how it looks.

Colors are basically the same thing. Each color has a code and they can be inserted in the same way as formatting codes. Here's a table below with the colors supported by most terminal clients:

    Black: \e[30m (Text) and \e[40m (Background) Red: \e[31m (Text) and \e[41m (Background) Green: \e[32m (Text) and \e[42m (Background) Yellow: \e[33m (Text) and \e[43m (Background) Blue: \e[34m (Text) and \e[44m (Background) Magenta: \e[35m (Text) and \e[45m (Background) Cyan: \e[36m (Text) and \e[46m (Background) Light gray: \e[37m (Text) and \e[47m (Background) Default color: \e[39m (Text) and \e[49m (Background)

You can also mix text colors with different background colors and also add the regular formatting codes to the colored text:

## The read Command

To get information from the user, use the read command. It’ll store whatever the user types up to the moment ENTER is pressed and store it in a variable. The only argument to it is the variable you want the information stored in. For example, this is a short script that creates a folder with the name the user wants:

    #!/bin/bash read foldername mkdir foldername

But this is a script without any sort of user interface. How is the user supposed to know if and what he has to type?

## Example script

In this example we'll use everything we learned in this tutorial. Custom formatted messages will be displayed to the user and an input will be required. The first tutorial had an example that backed up files based on parameters passed when summoning the script. Now we'll rewrite it, asking the user what he wants backed up.

First, we need to set up and open the file:

    touch ~/bin/filebackup2 chmod +x ~/bin/filebackup2 nano ~/bin/filebackup2

Proceeding to rewrite the script so it has an interface:

    #!/bin/bash #Backup script 2.0 #Description: makes a copy of any given file at the backup folder #Author: Your Name #Date: 9/19/2013 #Request the backup folder from the user: echo -e "\e[1m\e[32mFile Backup Utility\n\e[39m\e[0mPlease input your backup folder:" read BACKUPFOLDER #The script will make sure the folder exists mkdir -p $BACKUPFOLDER #Request files to be backed up: echo -e "\e[47m\e[30mWhich files do you want backed up?\e[39m\e[49m" read FILES cp -a $FILES $BACKUPFOLDER

## Conclusion

This tutorial covers basic commands that enable you to write a script with proper user interaction, which is crucial to ensure everyone understands what the script does and what kind of data it's requesting. Not all scripts should have an user interface; the first one we coded is in most cases faster and better. But even in the command line, only scripts you should implement a "help" interface, for which you'll need the "echo" command.
