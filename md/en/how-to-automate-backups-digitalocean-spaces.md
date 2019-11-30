---
author: Sebastian Canevari
date: 2018-01-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-automate-backups-digitalocean-spaces
---

# How To Automate Backups with DigitalOcean Spaces

## Introduction

Backing up important data is an essential part of managing any computer infrastructure. Although everyone’s needs are different when it comes to performing backups, maintaining backup data at an offsite location is a good practice.

The process of sending copies of data to an offsite location used to be a major logistical challenge. But with the advent of cloud-based storage services like Crashplan and Dropbox, as well as the development of object storage solutions like [DigitalOcean Spaces](an-introduction-to-digitalocean-spaces), it has now become a much simpler task. Despite this, remembering to back up files and taking the time to upload them can still be a roadblock for some.

This is why people choose to use various tools to perform routine, automatic backups of their important data. In this tutorial, we will build a script around the `s3cmd` command line tool which can be used to quickly upload data to DigitalOcean Spaces. We will then use `crontab` to regularly invoke the backups script and upload files to our Space.

## Prerequisites

For this tutorial, you will need:

- One Ubuntu 16.04 x64 Droplet with a non-root sudo user. This can be configured by following our [initial server setup guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- [A DigitalOcean Space and API access key](how-to-create-a-digitalocean-space-and-api-key).
- [The `s3cmd` command line tool installed on your Droplet](how-to-configure-s3cmd-2-x-to-manage-digitalocean-spaces).

Having some familiarity with shell scripting and the `cron` job scheduler could also be helpful. For some guidance and additional context, consider reading “[An Introduction to Shell Scripting](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-shell-scripting)” and “[How To Schedule Routine Tasks With Cron and Anacron on a VPS](how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps).”

With our prerequisites in place, we’re ready to begin our backup automation process.

## Building our Backups Script

There are a number of tools which can be used to upload backup files to an object storage service automatically and at regular intervals. However, these can be difficult to configure and may not offer much in the way of flexibility. Using a simple shell script can be a much more elegant and straightforward approach to automating object storage backups.

For this tutorial, we will write a basic bash script which will create a backup of a file or directory using `tar`. The script will then upload that backup to Spaces using the `s3cmd` command line utility.

To get started, log into your Droplet and navigate to your home folder:

    cd ~

Once in the home folder, we’ll use `nano` to create an empty file where we can write in our script:

    nano bkupscript.sh

We are now ready to begin writing our backups script in the text editor. As we build the script, we will explain each part of it in order, section by section.

### Initiating Our Script

At this point, `bkupscript.sh` is only an empty text file. In order for our computer to invoke our executable file as commands, we need to begin our script with a hashbang. A **hashbang** is an interpreter directive which allows scripts or data files to be run as commands.

In our case, the hashbang will look like this:

bkupscript.sh

    #!/bin/bash

By including this at the top of the script, we are telling the shell to run the file’s commands in bash.

### Declaring Variables

Next, we’ll tell our script the variables it will need to know in order to function correctly. We can add these directly below the hashbang at the top of the text file:

bkupscript.sh

    ...
    DATETIME=`date +%y%m%d-%H_%M_%S`
    SRC=$1
    DST=$2
    GIVENNAME=$3

Let’s go through what we are assigning each of these variables to:

- `DATETIME`: This variable holds a timestamp to affix to the resulting filename so every file backed up to our Space has a unique name. This timestamp is created by invoking the `date` command and formatting the output to show the last two digits of the year (`%y`), the two digits of the month (`%m`), the two digits of the day (`%d`), the hour (`%H`), the minutes (`%M`) and the seconds (`%S`).
- `SRC`: This is the **source** path for the file or folder we want to backup. The `$1` indicates that we are taking this value from the first parameter passed to the script.
- `DST`: This variable represents the file’s **destination**. In our case this is the name of the Space to which we are uploading the backup. This name will come from the second parameter passed to the script as indicated by the `$2`.
- `GIVENNAME`: This variable hosts the user-chosen name for the destination file. The resulting filename will start with `GIVENNAME` and will have the `DATETIME` concatenated onto it. This name comes from the third parameter passed to the script (`$3`).

### Providing Some Help

When writing a script, it’s helpful to add some tips or general advice which can assist users troubleshooting if their attempts to use it fail.

For our backups script, we will add a function called `showhelp()` below our variables. This will print a series of messages to help users troubleshoot in case the script fails. When adding a function in bash, our syntax will look like this :

bkupscript.sh

    ...
    showhelp(){
    
    }

This function will provide help messages by echoing a series of usage instructions on the screen. Each instruction should be presented as a string enclosed with double quotes. You’ll notice in our example below that some of the strings have `\t` or `\n` written at their beginning or end. These are _escape characters_ which provide specific instructions for how the string should appear in the script’s output:

- `\t` indicates a tab space
- `\n` indicates a line break

Feel free to add any usage details that would be helpful for you in between the curly brackets (just remember to precede any string with `echo`). For demonstration purposes, we will add the following:

bkupscript.sh

    echo "\n\n############################################"
    echo "# bkupscript.sh #"
    echo "############################################"
    echo "\nThis script will backup files/folders into a single compressed file and will store it in the current folder."
    echo "In order to work, this script needs the following three parameters in the listed order: "
    echo "\t- The full path for the folder or file you want to backup."
    echo "\t- The name of the Space where you want to store the backup at."
    echo "\t- The name for the backup file (timestamp will be added to the beginning of the filename)\n"
    echo "Example: sh bckupscript.sh ./testdir testSpace backupdata\n"<^>

The final `showhelp` function should look something like this:

bkupscript.sh

    ...
    showhelp(
            echo "\n\n############################################"
            echo "# bkupscript.sh #"
            echo "############################################"
            echo "\nThis script will backup files/folders into a single compressed file and will store it in the current folder."
            echo "In order to work, this script needs the following three parameters in the listed order: "
            echo "\t- The full path for the folder or file you want to backup."
            echo "\t- The name of the Space where you want to store the backup at."
            echo "\t- The name for the backup file (timestamp will be added to the beginning of the filename)\n"
            echo "Example: sh bckupscript.sh ./testdir testSpace backupdata\n"
    }

With our help text in place, we can move on to collecting the files we would like to backup in our Space.

### Gathering Files

Before our script can transfer anything to our Space, it first needs to gather the right files and consolidate them into a single package for us to upload. We can accomplish this by using the `tar` utility and a conditional statement. Because we’re using `tar` to create an archive file (sometimes known as a “zip” file), we will call this function `tarandzip()`.

Let’s start by declaring the function and adding another `echo` command to let users know that the script has begun gathering files:

bkupscript.sh

    ...
    tarandzip(){
        echo "\n##### Gathering files #####\n"
    }

Below the `echo` command, we can add a `tar` command which will do the work of collecting and compressing the files into a single output file.

bkupscript.sh

    tarandzip(){
        echo "\n##### Gathering files #####\n"
        tar -czvf $GIVENNAME-$DATETIME.tar.gz $SRC
    }

You’ll notice that this `tar` command is invoked with several options and variables:

- `c`: This flag tells `tar` to compress the output file.
- `z`: This instructs `tar` to compress the file using `gzip`.
- `v`: This signifies the `verbose` option, which instructs `tar` to show more information in the output.
- `f`: This flag instructs `tar` to save the file with the filename indicated next.
- `$GIVENNAME-$DATETIME.tar.gz`: The script calls these variables which we declared at the beginning in order to create the new file name. It does this by combining the `$GIVENNAME` and `$DATETIME` variables and adding the `.tar.gz` extension to the end to form the new file name.
- `$SRC`: This variable represents the _source_ files or folders which we are instructing `tar` to back up.

This function should now be able to do what we want it to, but we can add a few more `echo` calls to give the user some extra information about how the script is working. This can be done by adding a couple of conditional statements, like this:

bkupscript.sh

        if tar -czvf $GIVENNAME-$DATETIME.tar.gz $SRC; then
            echo "\n##### Done gathering files #####\n"
            return 0
        else
            echo "\n##### Failed to gather files #####\n"
            return 1
        fi

When the `if` clause is invoked, it will execute the `tar` command and wait for the result. If the result for the command is positive (meaning, it ran successfully), the lines between `then` and `else` will be executed. These are:

- Echoing a message that the script has successfully completed the `tar` process
- Returning an error code of `0` so that the portion of the code which invokes this function knows that everything worked fine.

The `else` portion of this function will only be executed if the `tar` command finds an error while executing. In this case, the `else` branch of the clause will:

- Echo a message indicating that the `tar` command failed
- Return an error code of `1`, indicating that something went wrong

Finally, we end the `if/then/else` clause with a `fi`, which in bash language means that the `if` clause has ended.

The completed `tarandzip()` function will look like this:

bkupscript.sh

    tarandzip(){
        echo "\n##### Gathering files #####\n"
        if tar -czvf $GIVENNAME-$DATETIME.tar.gz $SRC; then
            echo "\n##### Done gathering files #####\n"
            return 0
        else
            echo "\n##### Failed to gather files #####\n"
            return 1
        fi
    }

With our `tarandzip()` function in place, we are ready to set the script up to move our backups.

### Transferring Files to Object Storage

At this point, we can get our backup script to transfer a file to our Space by using the `s3cmd` command. As with `tarandzip`, we can also `echo` a few strings and utilize an `if/then/else` statement to keep users up to speed with how the script is working as it is running.

First we will declare our function. Let’s again keep this simple and name it `movetoSpace()`:

bkupscript.sh

    ...
    movetoSpace(){
    
    }

Now we can use `s3cmd` and the variables we declared earlier to build the command which will push our backup files to our Space:

bkupscript.sh

    movetoSpace(){
        ~/s3cmd-2.0.1/s3cmd put $GIVENNAME-$DATETIME.tar.gz s3://$DST
    }

Here’s what each part of this command means:

- `~/s3cmd-2.0.1/s3cmd`: This invokes `s3cmd`, a [command line tool used for managing object storage buckets](how-to-manage-digitalocean-spaces-with-s3cmd).
- `put`: This is a command used by `s3cmd` for uploading data into a bucket.
- `$GIVENNAME-$DATETIME.tar.gz`: This is the name of the backup that will be uploaded to our Space. It consists of the fourth and first variables we declared, followed by `.tar.gz`, and is created by the `tarandzip()` function from earlier.
- `s3://$DST;`: This is the location where we want to upload the file. `s3://` is a URI-like schema used specifically to describe object storage locations online, while `$DST;` is the third variable we declared earlier.

We now have a function which can upload our archived files to our Space. However, it doesn’t notify the user about its status. Let’s change this by echoing a string before the command to let the user know that it has been started, and after the function is complete, to let us know whether it was successful.

Let’s start by notifying the user that the process has begun:

bkupscript.sh

    movetoSpace(){
        echo “\n##### MOVING TO SPACE #####\n”
        ~/s3cmd-2.0.1/s3cmd put $GIVENNAME-$DATETIME.tar.gz s3://$DST
    }

Because the command will be either successful or unsuccessful (meaning, it will either upload the files to our Space or it won’t), we can let users know whether it worked by echoing one of two strings held in an `if/then/else` statement, like this:

bkupscript.sh

    ...
    if ~/s3cmd-2.0.1/s3cmd put $GIVENNAME-$DATETIME.tar.gz s3://$DST; then
        echo "\n##### Done moving files to s3://"$DST" #####\n"
        return 0
    else
        echo "\n##### Failed to move files to the Space #####\n"
        return 1
    fi

This conditional statement tells bash “If our `s3cmd` command functions correctly, then let the user know that the script is done moving files to our Space. Otherwise, let the user know that the process failed.”

If the `s3cmd` process completes successfully then the function prints a message to the screen (the first `echo` string in the `then` statement) indicating so, and returns a value of `0`, which informs the calling function that the operation has been completed. If the process fails, the `then` clause simply prints the error message (the second `echo` string), and returns a `1` so the rest of the script is aware that an error occurred.

Altogether, the `movetoSpace()` function should look like this:

bkupscript.sh

    movetoSpace(){
        echo "\n##### MOVING TO SPACE #####\n"
        if ~/s3cmd-2.0.1/s3cmd put $GIVENNAME-$DATETIME.tar.gz s3://$DST; then
            echo "\n##### Done moving files to s3://"$DST" #####\n"
            return 0
        else
            echo "\n##### Failed to move files to the Space #####\n"
            return 1
        fi
    }

With the `movetoSpace()` function written, we can move on to ensuring that the script is set up to call functions in the expected order through using conditional statements for flow control.

### Setting Up Flow Control

Though we have set up our script with functions, we have not provided an order for the script to complete those functions. At this point, we can introduce a calling function which will tell the rest of the script exactly how and when to run the other functions we’ve written.

Assuming everything has been configured correctly, when we run the script it should read the input command, assign the values from it to each variable, perform the `tarandzip()` function, and follow that with the `movetoSpace()` function. Should the script fail between any of those points, it should print the output of our `showhelp()` function to help users with troubleshooting. We can order this and catch errors by adding a series of `if/then/else` statements at the bottom of the file:

bkupscript.sh

    ...
    if [! -z "$GIVENNAME"]; then
        if tarandzip; then
            movetoSpace
        else
            showhelp
        fi
    else
        showhelp
    fi

The first `if` statement in the section above checks that the third variable passed is not empty. It does so in the following way:

- `[]`: The square brackets indicate that what lies between them is a _test_. In this case, the test is for a specific variable to not be empty.
- `!`: In this case, this symbol means `not`.
- `-z`: This option indicates an _empty string_. So, combined with the _!_, we are asking for _not an empty string_.
- `$GIVENNAME`: We are indicating here that the string we don’t want to be empty is the value assigned to the variable `$GIVENNAME`. The reason we chose this approach is because this variable is assigned the value passed by the third parameter when calling the script from the command line. If we pass fewer than 3 parameters to the script, the code will not have a third parameter to assign the value to _$GIVENNAME_, so it will assign an empty string and this test will fail.

Assuming that this first test is successful, it will then move on to the next `if` statement and so on. If any of the `if` statements return an error, the `then` clause will call the `showhelp` function and help text will be displayed in the output. Essentially, what this does is it glues together all the previous functions we’ve written out and gives bash the information it needs to perform them in the correct order.

Our script is now complete! You can verify that your script looks like the complete script we built in the section below.

## The Complete Script

The completed backups script that we created should look like this:

bkupscript.sh

    #!/bin/bash
    DATETIME=`date +%y%m%d-%H_%M_%S`
    SRC=$1
    DST=$2
    GIVENNAME=$3
    showhelp(){
            echo "\n\n############################################"
            echo "# bkupscript.sh #"
            echo "############################################"
            echo "\nThis script will backup files/folders into a single compressed file and will store it in the current folder."
            echo "In order to work, this script needs the following three parameters in the listed order: "
            echo "\t- The full path for the folder or file you want to backup."
            echo "\t- The name of the Space where you want to store the backup at (not the url, just the name)."
            echo "\t- The name for the backup file (timestamp will be added to the beginning of the filename)\n"
            echo "Example: sh bkupscript.sh ./testdir testSpace backupdata\n"
    }
    tarandzip(){
        echo "\n##### Gathering files #####\n"
        if tar -czvf $GIVENNAME-$DATETIME.tar.gz $SRC; then
            echo "\n##### Done gathering files #####\n"
            return 0
        else
            echo "\n##### Failed to gather files #####\n"
            return 1
        fi
    }
    movetoSpace(){
        echo "\n##### MOVING TO SPACE #####\n"
        if ~/s3cmd-2.0.1/s3cmd put $GIVENNAME-$DATETIME.tar.gz s3://$DST; then
            echo "\n##### Done moving files to s3://"$DST" #####\n"
            return 0
        else
            echo "\n##### Failed to move files to the Space #####\n"
            return 1
        fi
    }
    if [! -z "$GIVENNAME"]; then
        if tarandzip; then
            movetoSpace
        else
            showhelp
        fi
    else
        showhelp
    fi

Once you have verified your script, be sure to save and close the file (`CTRL-x`, `y`, then `ENTER`) before exiting nano.

## Testing the Script

Now that we’re finished with building the script, we can move on to testing it out. Not only will this tell us whether we’ve written the script correctly, but it will also give us a chance to practice using the script and see it in action.

When testing out a script like this, it’s usually a good idea to use dummy files. Even though we know it isn’t capable of destroying or removing data, it’s smart to play it safe by testing it with some unimportant files. We’ll first create a directory using the `mkdir` command:

    mkdir backupthis

Next, we’ll create two empty files inside this directory using `touch`:

    sudo touch backupthis/file1.txt
    sudo touch backupthis/file2.txt

We can now test the script by uploading the `backupthis` directory and its contents to our Space. This is the format we will need to use in order to invoke the script:

    sh bkupscript.sh ./backupthis name_of_your_space testrun

**Note** Because the `movetoSpace()` function automatically prepends `s3://` to the destination variable (i.e., the name of your Space), this variable should simply be the name of your Space and not its full URL. For example, if your Space’s URL is “https://example-space-name.nyc3.digitaloceanspaces.com”, you would write the test command like this:

    sh bkupscript.sh ./backupthis example-space-name testrun

The command above will set the script in motion and you should see output like this:

    Output
    ##### Gathering files #####
    
    ./backupthis/
    ./backupthis/file1.txt
    ./backupthis/file2.txt
    
    ##### Done gathering files #####
    
    
    ##### MOVING TO SPACE #####
    
    upload: 'testrun-180119-15_09_36.tar.gz' -> 's3://name_of_your_space /testrun-180119-15_09_36.tar.gz' [1 of 1]
     162 of 162 100% in 8s 19.81 B/s done
    
    ##### Done moving files to s3://name_of_your_space #####

If you encounter any errors, please review your script to ensure that it matches our example. Also, make sure that your installation of `s3cmd` has been properly configured and that both the access key and the secret key you’re using are correct.

## Automating Backups with Crontab

After successfully testing the backups script, we can set up a `cron` job which will use the script to perform regular backups to our Space. For the purpose of this tutorial, we’ll set it up to execute our backups script every minute.

First, we need to make the script executable:

    chmod +x bkupscript.sh

Now that the script can be executed as a command, we can edit the `crontab` file to run the script every minute:

    crontab -e

The first time that you run `crontab -e`, it will ask you to select an editor from a list:

    no crontab for root - using an empty one
    Select an editor. To change later, run 'select-editor'.
      1. /bin/ed
      2. /bin/nano <---- easiest
      3. /usr/bin/vim.basic
      4. /usr/bin/vim.tiny
    Choose 1-4 [2]: 

You can select the default nano, or another text editor of your choice.

Once in `crontab`, we will add the following line at the bottom of the values that are already there:

/tmp/crontab.example/crontab

    * * * * * ~/bkupscript.sh ~/backupthis nameofyourspace cronupload

To save the changes, press `CTRL-x`, then `y`, then `ENTER`.

After a minute or so, you will see a new file in your Space’s dashboard!

If you leave the `cron` job running without making any changes, you will have a new file copied to your Space every minute. Once you’ve confirmed that `cron` is running successfully, feel free to reconfigure `crontab` to backup your files at your desired interval.

You now have a script that periodically compresses and ships your backups to a DigitalOcean Space!

## Conclusion

In this tutorial, we have gone over how to create regularly scheduled offsite backups of your important files using a bash script, `crontab`, and DigitalOcean Spaces. Although the script presented in this tutorial is only intended for demonstration purposes, it can be used as a foundation to build a production-ready version which could later be integrated with a CI/CD solution like [Jenkins](https://jenkins.io/), [Drone](http://try.drone.io/), or [Travis CI](https://travis-ci.org/).

If you want to learn more about CI/CD tools, you can do so by reading the following tutorials:

- [How To Set Up Jenkins For Continuous Develompment Integration On Centos7](how-to-set-up-jenkins-for-continuous-development-integration-on-centos-7).
- [How To Set Up Continuous Integration Pipelines with Drone on Ubuntu 16.04](how-to-set-up-continuous-integration-pipelines-with-drone-on-ubuntu-16-04).
