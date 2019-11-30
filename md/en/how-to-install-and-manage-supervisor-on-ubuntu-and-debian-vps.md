---
author: 
date: 2013-07-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-manage-supervisor-on-ubuntu-and-debian-vps
---

# How To Install and Manage Supervisor on Ubuntu and Debian VPS

## Introduction

In many VPS environments, it is often the case that you will have a number of small programs that you want to run persistently, whether these be small shell scripts, Node.js apps, or any large-sized packages.

Conventionally, you may write a init script for each of these programs, but this can quickly become time consuming to manage and isn't always particularly transparent for newer users.

[Supervisor](http://supervisord.org/#) is a process manager which makes managing a number of long-running programs a trivial task by providing a consistent interface through which they can be monitored and controlled.

This tutorial assumes that you are familiar with the command line, installing packages, and basic server management.

## Installation

Installation of Supervisor on both Ubuntu and Debian is incredibly simple, as prebuilt packages already exist within both distributions' repositories.

As the root user, run the following command to install the Supervisor package:

    apt-get install supervisor

Once this has completed, the supervisor daemon should already be started, as the prebuilt packages come with an init script that will also ensure the Supervisor is restarted after a system reboot. You can ensure this is the case by running:

    service supervisor restart

Now that we have Supervisor installed, we can look at adding our first programs.

## Adding a Program

New programs are given to Supervisor through configuration files, which inform it of the executable to run, any environmental variables, and how output should be handled.

**Note:** All programs run under Supervisor must be run in a [non-daemonising mode](http://supervisord.org/subprocess.html#nondaemonizing-of-subprocesses) (sometimes also called 'foreground mode'). If, by default, the program forks and returns on startup, then you may need to consult the program's manual to find the option to enable this mode, otherwise Supervisor will not be able to properly determine the status of the program.

For the sake of this article, we'll assume we have a shell script we wish to keep persistently running that we have saved at **/usr/local/bin/long.sh** and looks like the following:

    #!/bin/bash while true do # Echo current date to stdout echo `date` # Echo 'error!' to stderr echo 'error!' \>&2 sleep 1 done

    chmod +x /usr/local/bin/long.sh

In a practical sense, this script is clearly rather pointless, but it will allow us to cover the fundamentals of Supervisor configuration.

The program configuration files for Supervisor programs are found in the **/etc/supervisor/conf.d** directory, normally with one program per file and a .conf extension. A simple configuration for our script, saved at **/etc/supervisor/conf.d/long\_script.conf** , would look like so:

     [program:long\_script] command=/usr/local/bin/long.sh autostart=true autorestart=true stderr\_logfile=/var/log/long.err.log stdout\_logfile=/var/log/long.out.log 

We'll look at the significance of each line and some of the tweaks that may be desirable for your program below:

    [program:long\_script] command=/usr/local/bin/long.sh

The configuration begins by defining a program with the name 'long\_script' and the full path to the program:

    autostart=true autorestart=true

The next two lines define the basic automatic behaviour of the script under certain conditions.

The **autostart** option tells Supervisor that this program should be started when the system boots. Setting this to false will require a manual start command following any system shutdown.

**autorestart** defines how Supervisor should manage the program in the event it exits and has three options:

- false' tells Supervisor not to ever restart the program after it exits
- 'true' tells Supervisor to always restart the program after it exits
- 'unexpected' tells Supervisor to only restart the program if it exits with an unexpected error code (by default anything other than codes 0 or 2).

    stderr\_logfile=/var/log/long.err.log stdout\_logfile=/var/log/long.out.log

The final two lines define the locations of the two main log files for the program. As suggested by the option names, stdout and stderr will be directed to the **stdout\_logfile** and **stderr\_logfile** locations respectively. The specified directory specified must exist before we start the program, as Supervisor will not attempt to create any missing directories.

The configuration we have created here is a minimal reasonable template for a Supervisor program. [The documentation](http://supervisord.org/configuration.html#program-x-section-settings) lists many more optional configuration options that are available to fine tune how the program is executed.

Once our configuration file is created and saved, we can inform Supervisor of our new program through the **supervisorctl** command. First we tell Supervisor to look for any new or changed program configurations in the **/etc/supervisor/conf.d** directory with:

    supervisorctl reread

Followed by telling it to enact any changes with:

    supervisorctl update

Any time you make a change to any program configuration file, running the two previous commands will bring the changes into effect.

At this point our program should now be running and we can check this is the case by looking at the output log file:

     $ tail /var/log/long.out.log Sat Jul 20 22:21:22 UTC 2013 Sat Jul 20 22:21:23 UTC 2013 Sat Jul 20 22:21:24 UTC 2013 Sat Jul 20 22:21:25 UTC 2013 Sat Jul 20 22:21:26 UTC 2013 Sat Jul 20 22:21:27 UTC 2013 Sat Jul 20 22:21:28 UTC 2013 Sat Jul 20 22:21:29 UTC 2013 Sat Jul 20 22:21:30 UTC 2013 Sat Jul 20 22:21:31 UTC 2013 

Success!

## Managing Programs

Once our programs are running, there will undoubtedly be a time when we want to stop, restart, or see their status. The supervisorctl program, which we first used above, also has an interactive mode through which we can issue commands to control our programs.

To enter the interactive mode, start supervisorctl with no arguments:

     $ supervisorctl long\_script RUNNING pid 12614, uptime 1:49:37 supervisor\> 

When started, supervisorctl will initially print the status and uptime of all programs, followed by showing a command prompt. Entering **help** will reveal all of the available commands that we can use:

     supervisor\> help default commands (type help <topic>):
    =====================================
    add clear fg open quit remove restart start stop update
    avail exit maintail pid reload reread shutdown status tail version
    </topic>

 To start in a simple manner, we can **start** , **stop** and **restart** a program with the associated commands followed by the program name: 

     supervisor\> stop long\_script long\_script: stopped supervisor\> start long\_script long\_script: started supervisor\> restart long\_script long\_script: stopped long\_script: started 

Using the **tail** command, we can view the most recent entries in the stdout and stderr logs for our program:

     supervisor\> tail long\_script Sun Jul 21 00:36:10 UTC 2013 Sun Jul 21 00:36:11 UTC 2013 Sun Jul 21 00:36:12 UTC 2013 Sun Jul 21 00:36:13 UTC 2013 Sun Jul 21 00:36:14 UTC 2013 Sun Jul 21 00:36:15 UTC 2013 Sun Jul 21 00:36:17 UTC 2013 supervisor\> tail long\_script stderr error! error! error! error! error! error! error! 

Using **status** we can view again the current execution state of each program after making any changes:

    supervisor\> status long\_script STOPPED Jul 21 01:07 AM

Finally, once we are finished, we can exit supervisorctl with Ctrl-C or by entering **quit** into the prompt:

    supervisor\> quit

And that's it! You've mastered the basics of managing persistent programs through Supervisor and extending this to your own programs should be a relatively simple task. If you have any questions or further advice, be sure to leave it in the comments section.
