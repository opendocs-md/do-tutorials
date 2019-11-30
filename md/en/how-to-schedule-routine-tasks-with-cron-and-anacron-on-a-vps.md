---
author: Justin Ellingwood
date: 2013-08-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-schedule-routine-tasks-with-cron-and-anacron-on-a-vps
---

# How To Schedule Routine Tasks With Cron and Anacron on a VPS

### What is Cron?

Cron is a scheduling utility that allows you to assign tasks to run at preconfigured times. A basic tool, cron can be utilized to automate almost anything on your system that must happen at regular intervals.

Equally adept at managing tasks that must be performed hourly or daily and large routines that must be done once or twice a year, cron is an essential tool for a system administrator.

In this guide, we will discuss how to use cron from the command line and how to read its configuration file. We will also explore anacron, a tool that can be used to ensure that tasks are run even when the server is turned off part of the time.

We will be using an Ubuntu 12.04 VPS, but any modern Linux distribution should operate in a similar manner.

## How Cron Works

Cron is started at boot and runs in the background as a daemon. This means that it runs without user interaction and waits for certain events to happen to decide when to execute.

In the case of cron, these events are certain moments in time. Cron runs in the background and checks its configuration file once every minute to see if an event is scheduled to run that minute.

If an event is scheduled, cron executes whatever predetermined command has been given to it and then goes back into the background for another minute. If no event was scheduled, it waits 60 seconds and checks again.

Because of this minute-by-minute scheduling, it is extremely flexible and configurable. Upon installing your distribution, cron is already configured to run a variety of tasks.

## How to Read a Crontab

Cron decides which commands to run at what time by reading a series of files, each known as a "crontab". We can see the system-wide crontab by looking at "/etc/crontab":

    less /etc/crontab

    SHELL=/bin/sh PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin # m h dom mon dow user command 17 \* \* \* \* root cd / && run-parts --report /etc/cron.hourly 25 6 \* \* \* root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily ) 47 6 \* \* 7 root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly ) 52 6 1 \* \* root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )

This is the system crontab and should not be edited in most cases. Most of the time it is preferable to use your own crontab. The system file could be replaced in an update and your changes would be lost.

The file has a few interesting parts that we need to understand.

The first two lines specify the shell that will execute the commands listed and the path to check for the programs.

The rest of the file specifies the actual commands and scheduling. The lines in this list each represent a record, or row, in a table. The "tab" in "crontab" stands for table. Each table cell is represented by a column separated by spaces or tabs.

The commented line above the table gives a hint as to what each of the columns represent:

    # m h dom mon dow user command

### Scheduling Hours and Minutes with Cron

The first column is the minute (0-59) of the hour that the command should run. The second column is the hour of the day, from 0-23, that it should run. An asterisk (\*) means "every possible value", and is used as a wildcard.

By combining these first two columns, we can get a time value for the command. For instance, the second line in the table has 25 in the minutes column and 6 in the hours column:

    25 6 \* \* \* root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )

This means the second line should be run at 6:25 in the morning.

Similarly, the first line means that the command should be run every hour, at 17 minutes passed the hour:

    17 \* \* \* \* root cd / && run-parts --report /etc/cron.hourly

So it will be run at 1:17am, 2:17am, 3:17am, etc.

### Scheduling Days with Cron

The third, fourth, and fifth column determine which days the command should be run. The third column specifies a day of the month, 1-31 (be careful when scheduling for late in the month, as not all months have the same number of days).

The fourth column specifies which months, from 1-12, a command should be run, and the fifth column is reserved to specify which day of the week a command should be run, with 0 and 7 both meaning Sunday. This last one allows you to schedule by week instead of by month.

If both the day of the week and the day of the month columns have values that are not wildcards, then the command will execute if either of the columns match.

Days of the week and months can also be specified with the first three letters of their name. We can also use ranges with hyphens (-) and select multiple values with commas (,).

We can also specify an interval by following a value with / and a number. For instance, to execute the command every other hour, we could place "\*/2" in the hours column.

If we look at the crontab, you will see that the third record is run every Sunday at 6:47am:

    47 6 \* \* 7 root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )

The fourth record is run on the first of the month at 6:52am:

    52 6 1 \* \* root test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )

### Using Time Shortcuts to Schedule

You can replace the first five columns of each record with a named shortcut if you have simple requirements. The syntax for these is "@" followed by the named interval.

For instance, we can schedule something to be executed every week by specifying "@weekly" instead of creating the five column configuration. Other choices are "@yearly", "@monthly", "@daily", and "@hourly".

There is also a special shortcut called "@reboot" which runs as soon as cron is started. This usually only happens when the system starts, which is why it is called "reboot" instead of "cron-restart" or something similar.

Keep in mind that these shortcuts do not provide fine-grained control over when they are run. They are also all configured to run at the first possible moment of the matching time.

For example, "@monthly" will run at midnight of the first of the month. This can lead to many commands scheduled to run at one time if they all fall on the same time. You are unable to stagger these events like you can with the conventional scheduling syntax.

### Specifying Commands and Users with Cron

The next columns involve the actual execution of the commands scheduled.

The sixth column, which is only present in the system crontab that we are looking at, names the user that the command should be executed as.

The final column specifies the actual command that should be executed. The command can contain a percent sign (%), which means that everything beyond the first percent sign is passed to the command as standard input.

Every record needs to end with a new-line character. This is not a problem for most entries, but be sure that you have a blank line after the final entry, or else the command will not run properly.

## Using run-parts and Cron Directories

If you look at the commands specified in the system crontab, you will see a mention of "anacron", which we will discuss later, and "run-parts".

The run-parts command is a simple command that runs every executable located within a specified directory. It is used extensively with cron because it allows you to run multiple scripts at a specified time by placing them in a single location.

This has the advantage of allowing the crontab to be kept clean and simple, and allowing you to add additional scripts by simply placing them in or linking them to the appropriate directory instead of adjusting the crontab.

By default, most distributions set up folders for each interval, where they place the scripts or links to the scripts that they would like to run at that interval.

For instance, Ubuntu has folders named "cron.daily", "cron.hourly", "cron.monthly", and "cron.weekly". Inside of these folders are the appropriate scripts.

## Using User Specific Crontabs

Now that you understand the syntax of cron, you can use it to create scheduled tasks for your own user. We can do this with the "crontab" command.

Because the commands in your crontab will run with your user privileges, the "user" column does not exist in user-specific crontabs.

To see your current crontab, type:

    crontab -l

You will probably not have one unless you've specifically created it by hand. If you do have a crontab, it is best to backup the current copy before editing so that any changes you make can be reverted.

To store your backup in a file called "cron.bak" in your home directory, run:

    crontab -l \> ~/cron.back

To edit your crontab, type:

    crontab -e

    no crontab for demouser - using an empty one Select an editor. To change later, run 'select-editor'. 1. /bin/nano 
    
    You might be given a selection prompt similar to the one above your first time using this command. Select the editor you prefer to continue.
    
    
    
    You will be dropped into a commented file that you can edit to create your own rules.
    
    
    
    As a nonsensical example, if we wanted to echo the date into a file every 15 minutes every Wednesday, we could place this line into the file:
    
    
    
        \*/15 \* \* \* 3 echo "$(date)" \>\> /home/demouser/file
    
    
    
    We can then save the file and now, when we run "crontab -l", we should see the rule we just created:
    
    
    
        crontab -l
    
    
    
        . . . . . . \*/15 \* \* \* 3 echo "$(date)" \>\> /home/demouser/file
    
    
    
    If you need to edit the crontab of a specific user, you can also add the "-u username" option. You will only be able to do this as root or with an account with administrative privileges.
    
    
    
    For instance, if you would like to add something to the "root" crontab, you could issue:
    
    
    
        sudo crontab -u root -e
    
    
    ## Using Anacron with Cron
    
    
    One of cron's biggest weaknesses is that it assumes that your server or computer is always on. If your machine is off and you have a task scheduled during that time, the task will never run.
    
    
    
    This is a serious problem with systems that cannot be guaranteed to be on at any given time. Due to this scenario, a tool called "anacron" was developed. Anacron stands for anachronistic, and it is used compensate for this problem with cron.
    
    
    
    Anacron uses parameters that are not as detailed as cron's options. The smallest increment that anacron understands is days. This means that anacron should be used to complement cron, not to replace it.
    
    
    
    Anacron's advantage is that it uses time-stamped files to find out when the last time its commands were executed. This means, if a task is scheduled to be run daily and the computer was turned off during that time, when anacron is run, it can see that the task was last run more than 24 hours ago and execute the task correctly.
    
    
    
    The anacron utility has a scheduling table just like cron does. It is appropriately named "anacrontab" and is located in the "/etc" directory as well. Let's see how it is formatted:
    
    
    
        less /etc/anacrontab
    
    
    
        # /etc/anacrontab: configuration file for anacron # See anacron(8) and anacrontab(5) for details. SHELL=/bin/sh PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin # These replace cron's entries 1 5 cron.daily nice run-parts --report /etc/cron.daily 7 10 cron.weekly nice run-parts --report /etc/cron.weekly @monthly 15 cron.monthly nice run-parts --report /etc/cron.monthly
    
    
    
    We can see that it follows a similar format to the "crontab" files, but there are fewer columns and some noticeable differences.
    
    
    
    The first column specifies how often the command should be run. It is given as an interval in days. A value of "1" will run every day, while a value of "3" will run every three days.
    
    
    
    The second column is the delay to use before executing the commands. Anacron is not a daemon. It is run explicitly at one time. This field allows you to stagger execution so that not every task is running at the same time.
    
    
    
    For example, the first line runs every day, five minutes after anacron is called:
    
    
    
        1 5 cron.daily nice run-parts --report /etc/cron.daily
    
    
    
    The following line is run weekly (every 7 days), ten minutes after anacron is called:
    
    
    
        7 10 cron.weekly nice run-parts --report /etc/cron.weekly
    
    
    
    The third column contains the name that the job will be known as in the anacron's messages and log files. The fourth field is the actual command that is run.
    
    
    
    You can see that anacron is set to run some of the same scripts that are run by cron. Distributions handle this clash differently, by creating a preference for either cron or anacron and making the other program not execute the rule.
    
    
    
    For instance, on Ubuntu, the "/etc/crontab" tests if anacron is available on the system, and only executes the scripts in the cron.\* directories with cron if anacron is not found.
    
    
    
    Other distributions have cron update the anacron's time-stamps every time it runs the contents of these directories, so that anacron does not execute when it is called.
    
    
    ## Conclusion
    
    
    Both cron and anacron are useful tools for when you need to automate processes. Understanding how to leverage their strengths and work around their weaknesses will allow you to utilize them easily and effectively.
    
    
    
    Although the configuration syntax may be confusing at first, these tools will save you time in the long run and usually do not have to be adjusted often once you have a good working schedule.
    
