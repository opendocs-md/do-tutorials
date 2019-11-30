---
author: Shaun Lewis
date: 2013-08-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-on-a-vps
---

# How To Use Cron To Automate Tasks On a VPS

## Introduction

* * *

One of the most standard ways to run tasks in the background on Linux machines is with cron jobs. They’re useful for scheduling tasks on the VPS and automating different maintenance-related jobs. “Cron” itself is a daemon (or program) that runs in the background. The schedule for the different jobs that are run is in a configuration file called “crontab.”

## Installation

* * *

Almost all distros have a form of cron installed by default. However, if you’re using a system that doesn’t have it installed, you can install it with the following commands:

**For Ubuntu/Debian:**

    sudo apt-get update
    sudo apt-get install cron

**For Cent OS/Red Hat Linux:**

    sudo yum update
    sudo yum install vixie-cron crontabs

You’ll need to make sure it runs in the background too:

    sudo /sbin/chkconfig crond on
    sudo /sbin/service crond start

## Syntax

* * *

Here is an example task we want to have run:

    5 * * * * curl http://www.google.com

The syntax for the different jobs we’re going to place in the crontab might look intimidating. It’s actually a very succinct and easy-to-parse if you know how to read it. Every command is broken down into:

- Schedule
- Command

The command can be virtually any command you would normally run on the command line. The schedule component of the syntax is broken down into 5 different options for scheduling in the following order:

- minute
- hour
- day of the month
- month
- day of the week

## Examples

* * *

Here is a list of examples for some common schedules you might encounter while configuring cron.

_To run a command every minute:_

    * * * * *

_To run a command every 12th minute on the hour:_

    12 * * * *

_You can also use different options for each placeholder. To run a command every 15 minutes:_

    0,15,30,45 * * * *

_To run a command every day at 4:00am, you’d use:_

    0 4 * * *

_To run a command every Tuesday at 4:00am, you’d use:_

    0 4 * * 2

_You can use division in your schedule. Instead of listing out 0,15,30,45, you could also use the following:_

    */4 2-6 * * *

Notice the “`2-6`” range. This syntax will run the command between the hours of 2:00am and 6:00am.

The scheduling syntax is incredibly powerful and flexible. You can express just about every possible time imaginable.

## Configuration

* * *

Once you’ve settled on a schedule and you know the job you want to run, you’ll have to have a place to put it so your daemon will be able to read it. There are a few different places, but the most common is the user’s crontab. If you’ll recall, this is a file that holds the schedule of jobs cron will run. The files for each user are located at `/var/spool/cron/crontab`, but they are not supposed to be edited directly. Instead, it’s best to use the `crontab` command.

You can edit your crontab with the following command:

    crontab -e

This will bring up a text editor where you can input your schedule with each job on a new line.

If you’d like to view your crontab, but not edit it, you can use the following command:

    crontab -l

You can erase your crontab with the following command:

    crontab -r

If you’re a privileged user, you can edit another user’s by specifying `crontab -u <user> -e`

## Output

* * *

For every cron job that gets executed, the user’s email address that’s associated with that user will get emailed the output unless it is directed into a log file or into /dev/null. The email address can be manually specified if you provide a “MAILTO” setting at the top of the crontab. You can also specify the shell you’d like run, the path where to search for the cron binary and the home directory with the following example:

First, let’s edit the crontab:

    crontab -e

Then, we’ll edit it like so:

    SHELL=/bin/bash
    HOME=/
    MAILTO=”example@digitalocean.com”
    #This is a comment
    * * * * * echo ‘Run this command every minute’

This particular job will output “Run this command every minute.” That output will get emailed every minute to the “[example@digitalocean.com](mailto:example@digitalocean.com)” email address I specified. Obviously, that might not be an ideal situation. As mentioned, we can also pipe the output into a log file or into an empty location to prevent getting an email with the output.

To append to a log file, it’s as simple as:

    * * * * * echo ‘Run this command every minute’ >> file.log

Note: “`>>`” appends to a file.

If you want to pipe into an empty location, use `/dev/null`. Here is a PHP script that gets executed and runs in the background.

    * * * * * /usr/bin/php /var/www/domain.com/backup.php > /dev/null 2>&1

## Restricting Access

* * *

Restricting access to cron is easy with the `/etc/cron.allow` and `/etc/cron.deny` files. In order to allow or deny a user, you just need to place their username in one of these files, depending on the access required. By default, most cron daemons will assume all users have access to cron unless one of these file exists. To deny access to all users and give access to the user tdurden, you would use the following command sequence:

    echo ALL >>/etc/cron.deny
    echo tdurden >>/etc/cron.allow

First, we lock out all users by appending “`ALL`” to the deny file. Then, by appending the username to the allow file, we give the user access to execute cron jobs.

## Special Syntax

* * *

There are several shorthand commands you can use in your crontab file to make administering a little easier. They are essential shortcuts for the equivalent numeric schedule specified:

- `@hourly` - Shorthand for `0 * * * *`
- `@daily` - Shorthand for `0 0 * * *`
- `@weekly` - Shorthand for `0 0 * * 0`
- `@monthly` - Shorthand for `0 0 1 * *`
- `@yearly` - Shorthand for `0 0 1 1 *`

and `@reboot`, which runs the command once at startup.

_Note: Not all cron daemons can parse this syntax (particularly older versions), so double-check it works before you rely on it._

To have a job that runs on start up, you would edit your crontab file (`crontab -e`) and place a line in the file similar to the following:

    @reboot echo "System start up"

This particular command would get executed and then emailed out to the user specified in the crontab.
