---
author: Brian Boucheron
date: 2017-11-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-logfiles-with-logrotate-on-ubuntu-16-04
---

# How To Manage Logfiles with Logrotate on Ubuntu 16.04

## Introduction

Logrotate is a system utility that manages the automatic rotation and compression of log files. If log files were not rotated, compressed, and periodically pruned, they could eventually consume all available disk space on a system.

Logrotate is installed by default on Ubuntu 16.04, and is set up to handle the log rotation needs of all installed packages, including `rsyslog`, the default system log processor.

In this article, we will explore the default Logrotate configuration, then configure log rotation for a fictional custom application.

## Prerequisites

This tutorial assumes you have an Ubuntu 16.04 server, with a non-root sudo-enabled user, as described in [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

Logrotate is available on many other Linux distributions as well, but the default configuration may be quite different. Other sections of this tutorial will still apply as long as your version of Logrotate is similar to Ubuntu 16.04’s. Follow Step 1 to determine your Logrotate version.

Log into your server as your sudo-enabled user to begin.

## Confirming Your Logrotate Version

If you’re using a non-Ubuntu server, first make sure Logrotate is installed by asking for its version information:

    logrotate --version

    Outputlogrotate 3.8.7

If Logrotate is not installed you will get an error. Please install the software using your Linux distribution’s package manager.

If Logrotate is installed but the version number is significantly different, you may have issues with some of the configuration discussed in this tutorial. Refer to the documentation for your specific version of Logrotate by reading its `man` page:

    man logrotate

Next we’ll look at Logrotate’s default configuration structure on Ubuntu.

## Exploring the Logrotate Configuration

Logrotate’s configuration information can generally be found in two places on Ubuntu:

- `/etc/logrotate.conf`: this file contains some default settings and sets up rotation for a few logs that are not owned by any system packages. It also uses an `include` statement to pull in configuration from any file in the `/etc/logrotate.d` directory.
- `/etc/logrotate.d/`: this is where any packages you install that need help with log rotation will place their Logrotate configuration. On a standard install you should already have files here for basic system tools like `apt`, `dpkg`, `rsyslog` and so on.

By default, `logrotate.conf` will configure weekly log rotations (`weekly`), with log files owned by the **root** user and the **syslog** group (`su root syslog`), with four log files being kept (`rotate 4`), and new empty log files being created after the current one is rotated (`create`).

Let’s take a look at a package’s Logrotate configuration file in `/etc/logrotate.d`. `cat` the file for the `apt` package utility:

    cat /etc/logrotate.d/apt

    Output/var/log/apt/term.log {
      rotate 12
      monthly
      compress
      missingok
      notifempty
    }
    
    /var/log/apt/history.log {
      rotate 12
      monthly
      compress
      missingok
      notifempty
    }

This file contains configuration blocks for two different log files in the `/var/log/apt/` directory: `term.log` and `history.log`. They both have the same options. Any options not set in these configuration blocks will inherit the default values or those set in `/etc/logrotate.conf`. The options set for the `apt` logs are:

- `rotate 12`: keep twelve old log files.
- `monthly`: rotate once a month.
- `compress`: compress the rotated files. this uses `gzip` by default and results in files ending in `.gz`. The compression command can be changed using the `compresscmd` option.
- `missingok`: don’t write an error message if the log file is missing.
- `notifempty`: don’t rotate the log file if it is empty.

There are many more configuration options available. You can read about all of them by typing `man logrotate` on the command line to bring up Logrotate’s manual page.

Next, we’ll set up a configuration file to handle logs for a fictional service.

## Setting Up an Example Config

To manage log files for applications outside of the pre-packaged and pre-configured system services, we have two options:

1. Create a new Logrotate configuration file and place it in `/etc/logrotate.d/`. This will be run daily as the **root** user along with all the other standard Logrotate jobs.
2. Create a new configuration file and run it outside of Ubuntu’s default Logrotate setup. This is only really necessary if you need to run Logrotate as a non- **root** user, or if you want to rotate logs more frequently than daily (an `hourly` configuration in `/etc/logrotate.d/` would be ineffective, because the system’s Logrotate setup only runs once a day).

Let’s walk through these two options with some example setups.

### Adding Configuration to `/etc/logrotate.d/`

We want to configure log rotation for a fictional web server that puts an `access.log` and `error.log` into `/var/log/example-app/`. It runs as the `www-data` user and group.

To add some configuration to `/etc/logrotate.d/`, first open up a new file there:

    sudo nano /etc/logrotate.d/example-app

Here is an example config file that could handle these logs:

/etc/logrotate.d/example-app

    /var/log/example-app/*.log {
        daily
        missingok
        rotate 14
        compress
        notifempty
        create 0640 www-data www-data
        sharedscripts
        postrotate
            systemctl reload example-app
        endscript
    }

Some of the new configuration directives in this file are:

- `create 0640 www-data www-data`: this creates a new empty log file after rotation, with the specified permissions (`0640`), owner (`www-data`), and group (also `www-data`).
- `sharedscripts`: this flag means that any scripts added to the configuration are run only once per run, instead of for each file rotated. Since this configuration would match two log files in the `example-app` directory, the script specified in `postrotate` would run twice without this option.
- `postrotate` to `endscript`: this block contains a script to run after the log file is rotated. In this case we’re reloading our example app. This is sometimes necessary to get your application to switch over to the newly created log file. Note that `postrotate` runs before logs are compressed. Compression could take a long time, and your software should switch to the new logfile immediately. For tasks that need to run _after_ logs are compressed, use the `lastaction` block instead.

**After customizing the config to fit your needs** and saving it in `/etc/logrotate.d`, you can test it by doing a dry run:

    sudo logrotate /etc/logrotate.conf --debug

This calls `logrotate`, points it to the standard configuration file, and turns on debug mode.

Information will print out about which log files Logrotate is handling and what it would have done to them. If all looks well, you’re done. The standard Logrotate job will run once a day and include your new configuration.

Next, we’ll try a setup that doesn’t use Ubuntu’s default configuration at all.

### Creating an Independent Logrotate Configuration

In this example we have an app running as our user **sammy** , generating logs that are stored in `/home/sammy/logs/`. We want to rotate these logs hourly, so we need to set this up outside of the `/etc/logrotate.d` structure provided by Ubuntu.

First, we’ll create a configuration file in our home directory. Open it in a text editor:

    nano /home/sammy/logrotate.conf

Then paste in the following configuration:

/home/sammy/logrotate.conf

    /home/sammy/logs/*.log {
        hourly
        missingok
        rotate 24
        compress
        create
    }

Save and close the file. We’ve seen all these options in previous steps, but let’s summarize: this configuration will rotate the files hourly, compressing and keeping twenty-four old logs and creating a new log file to replace the rotated one.

You’ll need to customize the configuration to suit your application, but this is a good start.

To test that it works, let’s make a log file:

    cd ~
    mkdir logs
    touch logs/access.log

Now that we have a blank log file in the right spot, let’s run the `logrotate` command.

Because the logs are owned by **sammy** we don’t need to use `sudo`. We _do_ need to specify a _state_ file though. This file records what `logrotate` saw and did last time it ran, so that it knows what to do the next time it runs. This is handled for us when using the Ubuntu Logrotate setup (it can be found at `/var/lib/logrotate/status`), but we need to do it manually now.

We’ll have Logrotate put the state file right in our home directory for this example. I can go anywhere that’s accessible and convenient:

    logrotate /home/sammy/logrotate.conf --state /home/sammy/logrotate-state --verbose

    Outputreading config file /home/sammy/logrotate.conf
    
    Handling 1 logs
    
    rotating pattern: /home/sammy/logs/*.log hourly (24 rotations)
    empty log files are rotated, old logs are removed
    considering log /home/sammy/logs/access.log
      log does not need rotating

`--verbose` will print out detailed information about what Logrotate is doing. In this case it looks like it didn’t rotate anything. This is Logrotate’s first time seeing this log file, so as far as it knows, the file is zero hours old and it shouldn’t be rotated.

If we look at the state file, we’ll see that Logrotate recorded some information about the run:

    cat /home/sammy/logrotate-state

    Outputlogrotate state -- version 2
    "/home/sammy/logs/access.log" 2017-11-7-19:0:0

Logrotate noted the logs that it saw and when it last considered them for rotation. If we run this same command one hour later, the log will be rotated as expected.

If you want to force Logrotate to rotate the log file when it otherwise would not have, use the `--force` flag:

    logrotate /home/sammy/logrotate.conf --state /home/sammy/logrotate-state --verbose --force

This is useful when testing `postrotate` and other scripts.

Finally, we need to set up a cron job to run Logrotate every hour. Open your user’s crontab:

    crontab -e

This will open a up a text file. There may be some comments already in the file that explain the basic syntax expected. Move the cursor down to a new blank line at the end of the file and add the following:

    crontab14 * * * * /usr/sbin/logrotate /home/sammy/logrotate.conf --state /home/sammy/logrotate-state

This task will run on the 14th minute of every hour, every day. It runs basically the same `logrotate` command we ran previously, though we expanded `logrotate` to its full path of `/usr/sbin/logrotate` just to be safe. It’s good practice to be as explicit as possible when writing cron jobs.

Save the file and exit. This will install the crontab and our task will run on the specified schedule.

If we revisit our log directory in about an hour we should find the rotated and compressed log file `access.log.1.gz` (or `.2.gz` if you ran Logrotate with the `--force` flag).

## Conclusion

In this tutorial we verified our Logrotate version, explored the default Ubuntu Logrotate configuration, and set up two different types of custom configurations. To learn more about the command line and configuration options available for Logrotate, you can read its manual page by running `man logrotate` in your terminal.
