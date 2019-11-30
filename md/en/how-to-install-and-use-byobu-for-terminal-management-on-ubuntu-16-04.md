---
author: Stephen Rees-Carter
date: 2016-08-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-byobu-for-terminal-management-on-ubuntu-16-04
---

# How To Install and Use Byobu for Terminal Management on Ubuntu 16.04

## Introduction

[Byobu](http://byobu.co/) is an easy-to-use wrapper around the `tmux` (or `screen`) terminal multiplexer. This means that it makes it easy for you to open multiple windows and run multiple commands within a single terminal connection.

Byobu’s primary features include multiple console windows, split panes within each window, notifications and status badges to display the status of the host, and persistent sessions across multiple connections. These provide you with a lot of different options and possibilities, and it is flexible enough to get out of your way and let you get things done.

This tutorial will cover how to install and configure Byobu as well as how to use its most common features.

## Prerequisites

For this tutorial, you will need:

- One Ubuntu 16.04 server with a sudo non-root user, which you can set up by following [this initial server setup tutorial](initial-server-setup-with-ubuntu-14-04).

## Step 1 — Installing Byobu

Ubuntu should come with Byobu installed by default, so here, we’ll check that it’s installed and then configure some if its settings.

To check that Byobu is installed, try running this command to output its version.

    byobu --version

    Outputbyobu version 5.106
    tmux 2.1

If that does not display the current version number, you can manually install Byobu using `sudo apt-get install byobu`.

Now that Byobu is installed, we can configure some options.

## Step 2 — Starting Byobu on Login

Byobu is disabled by default after installation. There are two main ways you can enable Byobu: you can manually start it with the `byobu` command every time you want to use it, or you can set it to start automatically when you log in to your account.

To add Byobu to your login profile, run the following command. This means that every time you log in to your account, it will be launched.

    byobu-enable

    OutputThe Byobu window manager will be launched automatically at each text login.

If you change your mind later on and want to disable Byobu on login, run `byobu-disable`.

Because Byobu sessions are maintained across multiple login sessions, if you don’t specifically close a Byobu session, it will be loaded again the next time you log in. This means you can leave scripts running and files open between connections with no problems. You can also have multiple active logins connected to the same session.

Once Byobu is configured to start on login if you want it to, you can customize which multiplexer it uses.

## Step 3 — Setting the Backend Multiplexer

By default, Byobu will use `tmux` as the backend multiplexer. However, if you prefer to use `screen`, you can easily change the enabled backend.

    byobu-select-backend

This will give you a prompt to choose the backend multiplexer. Enter the number for whichever you prefer, and then press `ENTER`.

    OutputSelect the byobu backend:
      1. tmux
      2. screen
    
    Choose 1-2 [1]:

This tutorial assumes you have the `tmux` backend enabled, however, the default keybindings should be the same with `screen` as well.

## Step 4 — Enabling the Colorful Prompt

Byobu also includes a colorful prompt which includes the return code of the last executed command. It is enabled by default in some environments. You can manually enable it (or check that it’s already enabled) by running:

    byobu-enable-prompt

After this, you’ll need to reload your shell configuration.

    . ~/.bashrc

Byobu’s colorful prompt looks like this:

![Byobu enabled prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/byobu/f2aYlVF.png)

If you change your mind later on and want to disable Byobu’s colorful prompt, you can run `byobu-disable-prompt`.

Byobu is fully configured now, so let’s go over how to use it.

## Step 5 — Using Sessions

Byobu uses the function keys (`F1` through `F12`, the top row of your keyboard) for the default keybindings which provide access to all of the available functions. In the next few steps, we’ll talk about the keybindings for sessions, windows, and panes.

A _session_ is simply a running instance of Byobu. A session consists of a collection of _windows_, which are basically shell sessions, and _panes_, which are windows split into multiple sections.

The first time you start Byobu, it starts you a fresh session in which you create windows and panes. On subsequent connections, if you have only one session open, Byobu will automatically open that session when you connect; if you have more than one session open, Byobu will ask you which session you want to use with a prompt like this:

Byobu multiple session prompt

    Byobu sessions...
    
      1. tmux: 1: 1 windows (created Wed Aug 3 16:34:26 2016) [80x23]
      2. tmux: 2: 1 windows (created Wed Aug 3 16:34:38 2016) [80x23]
      3. Create a new Byobu session (tmux)
      4. Run a shell without Byobu (/bin/bash)
    
    Choose 1-4 [1]: 

One reason to use sessions is because each session can have its own window size, which is useful if you’re connecting with multiple devices with different screen sizes (say, a phone and a desktop computer). Another reason to use sessions is simply to have a clean workspace without closing your existing windows.

First, SSH into your server and enable Byobu, if it isn’t already enabled from the previous steps. Start a new session by pressing `CTRL+SHIFT+F2`, then use `ALT+UP` and `ALT+DOWN` to move backwards and forwards through your open sessions.

You can press `CTRL+D` to exit Byobu and close all of your sessions. If you instead want to detach your session, there are three useful ways to do this.

Pressing `F6` cleanly detaches your current session and logs you out of the SSH connection. It does not close Byobu, so the next time you connect to the server, the current session will be restored. This is one of the most useful features of Byobu; you can leave commands running and documents open while disconnecting safely.

If you wish to detach the current session but maintain an SSH connection to the server, you can use `Shift-F6`. This will detach Byobu (but not close it), and leave you in an active SSH connection to the server. You can relaunch Byobu at any time using the `byobu` command.

Next, consider a scenario where you are logged into Byobu from multiple locations. While this is often quite a useful feature to take advantage of, it can cause problems if, for example, one of the connections has a much smaller window size (because Byobu will resize itself to match the smallest window). In this case, you can use `ALT+F6`, which will detach all other connections and leave the current one active. This ensures only the current connection is active in Byobu, and will resize the window if required.

To recap:

- `CTRL+SHIFT+F2` will create a new session.

- `ALT+UP` and ALT+DOWN` will scroll through your sessions.

- `F6` will detach your current Byobu session.

- `SHIFT+F6` will detach (but not close) Byobu, and will maintain your SSH connection to the server. You can get back to Byobu with the `byobu` command.

- `ALT+F6` will detach all connections to Byobu except for the current one.

Next, let’s explore one of Byobu’s features: windows.

## Step 6 — Using Windows

Byobu provides the ability to switch between different windows within a single session. This allows you to easily multi-task within a single connection.

To demonstrate how to manipulate windows, let us consider a scenario where we want to SSH into a server and watch a system log file while editing a file in another window. In a Byobu session, use `tail` to watch a system log file.

    sudo tail -n100 -f /var/log/syslog

While that is running, open a new window by pressing `F2`, which will provide us with a new command prompt. We’ll use this new window to edit a new text file in our home directory using `editor`:

    editor ~/random.file

We now have two windows open: one tailing `/var/log/syslog` and the other in an editor session. You can scroll left and right through your windows by using `F3` and `F4` respectively. You can also give these windows names so it’s easier to organize and find them. To add a name to your current window, press `F8`, then type in a useful name (like “tail syslog”), and press `ENTER`. Scroll through each window and name them. If you want to reorder them, use `CTRL+SHIFT+F3/F4` to move the current left or right through the list, respectively.

At this point, there should be some log entries in syslog. In order to look through some of the older messages that are no longer being displayed on the screen, scroll to the log window and press `F7` to enter the scrollback history. You can use `Up`/`Down` and `PageUp`/`PageDown` to move through the scrollback history. When you are finished, press `ENTER`.

Now, if you need to disconnect from the server for a moment, you can press `F6`. This will clearly end the SSH connection and detach from Byobu. When it has closed, you can use SSH to reconnect again, and when Byobu comes back, all three of our existing windows will be there.

To recap:

- `F2` creates new windows within the current session.

- `F3` and `F4` scroll left and right through the windows list.

- `CTRL+SHIFT+F3/F4` moves a window left and right through the windows list.

- `F8` renames the current open window in the list.

- `F7` lets you view scrollback history in the current window.

Using just a few options, you have performed a number of useful actions that would be hard to easily replicate with a single standard SSH connection. This is what makes Byobu so powerful. Next, let’s extend this example by learning how to use panes.

## Step 7 — Using Panes

Byobu provides the ability to split windows into multiple panes with both horizontal and vertical splits. These allow you multi-task within the same window, as opposed to across multiple windows.

Create horizontal splits in the current window panel by pressing `SHIFT+F2`, and vertical ones with `CTRL+F2`. The focused pane will be split evenly, allowing you to split panes as much as is required to create quite complex layouts. Note that you cannot split a pane if there is not enough space for the pane to split into two.

Once you have split a window into at least two panes, navigate between them using `SHIFT+LEFT/RIGHT/UP/DOWN` or `SHIFT+F3/F4`. This allows you to leave a command running in one pane, and then move to another pane to run a different command. You can reorder panes by using `CTRL+F3/F4` move the current pane up or down, respectively.

`SHIFT+ALT+LEFT/RIGHT/UP/DOWN` allows you to manipulate the width and height of the currently selected pane. This will automatically resize the surrounding panels within the window as the split is moved and makes it easy to make a pane a lot larger when you are working in it, and then enlarge a different pane when your focus has shifted.

You can also zoom into a pane with `SHIFT+F11`, which makes it fill the entire window; pressing `SHIFT+F11` again switches it back to its original size. Finally, if you want to split a pane into a completely new window, use `ALT+F11`.

To recap:

- `SHIFT+F2` creates a horizontal pane; `CTRL+F2` creates a vertical one.

- `SHIFT+LEFT/RIGHT/UP/DOWN` or `SHIFT+F3/F4` switches between panes.

- `CTRL+F3/F4` moves the current pane up or down, respectively.

- `SHIFT+ALT+LEFT/RIGHT/UP/DOWN` resizes the current pane.

- `SHIFT+F11` toggles a pane to fill the whole window temporarily.

- `ALT+F11` splits a pane into its own new window permanently.

In the example from Step 7, it would’ve have been easy to use splits instead of windows to allows us to have the syslog tail, editor window, and new command prompt, all open in the same window. Here’s what that would have looked like with one window split into three panes:

![Windows and panes example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/byobu/1lyGR84.png)

Now that you know how to use sessions, windows, and panes, we’ll cover another one of Byobu’s features: status notifications.

## Step 8 — Using Status Notifications

Status notifications are notifications in the status bar at the bottom of a Byobu screen. These are a great way to customize your Byobu experience.

Press `F9` to enter the Byobu configuration menu. The options available are to view the help guide, toggle status notifications, change the escape sequence, and toggle Byobu on or off at login. Navigate to the **Toggle status notification** option and press `ENTER`. The list of all available status notifications will be displayed; you can select the ones you wish to enable or disable.

![Status notifications](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/byobu/2LaQz62.png)

When status notifications are enabled, they will appear in the bottom status bar, alongside the window indicators. By default there are a couple enabled, usually including the date, load and memory. Some notifications have options that can be configured through config files, which we will cover in the next tutorial.

There are a lot of different notifications to choose from, some of the commonly used ones are:

- `arch` shows the system architecture, i.e. `x86_64`.
- `battery shows the current battery level (for laptops).
- `date` shows the current system date.
- `disk` shows the current disk space usage.
- `hostname` shows the current system hostname.
- `ip_address` shows the current system IP address.
- `load_average` shows the current system load average.
- `memory` shows the current memory usage.
- `network` shows the current network usage, sending and receiving.
- `reboot_required` shows an indicator when a system reboot is required.
- `release` shows the current distribution version (e.g. 14.04).
- `time` shows the current system time.
- `updates_available` shows an indicator when there are updates available.
- `uptime` shows the current system uptime.
- `whoami` shows the currently logged in user.

After selecting the status notifications you wish to enable, select **Apply**. You may need to press `F5` to refresh the status bar; an indicator in the status bar will appear, if required.

Status notifications are a great way to see the information you care about in your system at a glance.

## Conclusion

There’s a lot more that Byobu is capable of. You can read [Byobu’s man pages](http://byobu.co/documentation.html) for more detail, but here are a few more useful keybindings:

- `SHIFT+F1` displays the full list of keybindings. If you forget every other keybinding, just remember this one! Press `q` to exit.

- `SHIFT+F12` toggles whether keybinding are enabled or disabled. This comes in handy if you are trying to use another terminal application within Byobu that has conflicting keyboard keybindings.

- `CTRL+F9` opens a prompt that lets you send the same input to every window; `SHIFT+F9` does the same for every pane.

As you can see from the wide range of functions that we have covered, there are a lot of things that Byobu can do and there is a good chance that it will fit into your workflow to make getting things done easier.
