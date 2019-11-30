---
author: Justin Ellingwood
date: 2013-07-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-screen-on-an-ubuntu-cloud-server
---

# How to Install and Use Screen on an Ubuntu Cloud Server

## Introduction

Screen is a console application that allows you to use multiple terminal sessions within one window. The program operates within a shell session and acts as a container and manager for other terminal sessions, similar to how a window manager manages windows.

There are many situations where creating several terminal windows is not possible or ideal. You might need to manage multiple console sessions without an X server running, you might need to access many remote cloud servers easily, or you might need to monitor a running program’s output while working on some other task. All of needs are easily addressed with the power of screen.

## Installation

In this tutorial, we’ll be using Ubuntu 12.04, but outside of the installation process, everything should be the same on every modern distribution.

Use “apt-get” to install on Ubuntu:

    sudo apt-get update sudo apt-get install screen

## Basic Usage

To start a new screen session, we simply type the “screen” command.

    screen

    Screen version 4.00.03jw4 (FAU) 2-May-06 Copyright (c) 1993-2002 Juergen Weigert, Michael Schroeder Copyright (c) 1987 Oliver Laumann This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program (see the file COPYING); if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA. Send bugreports, fixes, enhancements, t-shirts, money, beer & pizza to screen@uni-erlangen.de [Press Space for next page; Return to end.]

You’ll be greeted with the licensing page upon starting the program. Just press “Return” or “Enter” to continue.

What happens next may be surprising. We are given a normal command prompt and it looks like nothing has happened. Did “screen” fail to run correctly? Let’s try a quick keyboard shortcut to find out. Hold the control key, and then hit the “a” key, followed by the “v” key:

    Ctrl-a v

    screen 4.00.03jw4 (FAU) 2-May-06

We’ve just requested the version information from screen, and we’ve received some feedback that allows us to verify that screen _is_ running correctly.

Now is a great time to introduce the way that we will be controlling screen. Screen is mainly controlled through keyboard shortcuts. Every keyboard shortcut for screen is prefaced with “Ctrl-a” (hold the control key while pressing the “a” key). That sequence of keystrokes tells screen that it needs to pay attention to the next keys we press.

You’ve already used this paradigm once when we requested the version information about screen. Let’s use it to get some more useful information.

    Ctrl-a ?

     Screen key bindings, page 1 of 2. Command key: ^A Literal ^A: a break ^B b license , removebuf = clear C lockscreen ^X x reset Z colon : log H screen ^C c copy ^[[ login L select ' detach ^D d meta a silence \_ digraph ^V monitor M split S displays \* next ^@ ^N sp n suspend ^Z z dumptermcap . number N time ^T t fit F only Q title A flow ^F f other ^A vbell ^G focus ^I pow\_break B version v hardcopy h pow\_detach D width W help ? prev ^H ^P p ^? windows ^W w history { } quit \ wrap ^R r info i readbuf \< writebuf \> kill K k redisplay ^L l xoff ^S s lastmsg ^M m remove X xon ^Q q [Press Space for next page; Return to end.]

This is the internal keyboard shortcut screen. You’ll probably want to memorize how to get here, because it’s an excellent quick reference. As you can see at the bottom, you can press “space” to get more commands.

Okay, let’s try something more fun. Let’s run a program called “top” in this window, which will show us some information on our processes.

    top

    top - 16:08:07 up 1:44, 1 user, load average: 0.00, 0.01, 0.05 Tasks: 58 total, 1 running, 57 sleeping, 0 stopped, 0 zombie Cpu(s): 0.0%us, 0.0%sy, 0.0%ni,100.0%id, 0.0%wa, 0.0%hi, 0.0%si, 0.0%st Mem: 507620k total, 262920k used, 244700k free, 8720k buffers Swap: 0k total, 0k used, 0k free, 224584k cached PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND 1 root 20 0 3384 1836 1288 S 0.0 0.4 0:00.70 init 2 root 20 0 0 0 0 S 0.0 0.0 0:00.00 kthreadd 3 root 20 0 0 0 0 S 0.0 0.0 0:00.11 ksoftirqd/0 5 root 20 0 0 0 0 S 0.0 0.0 0:00.12 kworker/u:0 6 root RT 0 0 0 0 S 0.0 0.0 0:00.00 migration/0 7 root RT 0 0 0 0 S 0.0 0.0 0:00.07 watchdog/0 8 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 cpuset 9 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 khelper 10 root 20 0 0 0 0 S 0.0 0.0 0:00.00 kdevtmpfs 11 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 netns 12 root 20 0 0 0 0 S 0.0 0.0 0:00.03 sync\_supers 13 root 20 0 0 0 0 S 0.0 0.0 0:00.00 bdi-default 14 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 kintegrityd 15 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 kblockd 16 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 ata\_sff 17 root 20 0 0 0 0 S 0.0 0.0 0:00.00 khubd 18 root 0 -20 0 0 0 S 0.0 0.0 0:00.00 md

Okay, we are now monitoring the processes on our VPS. But what if we need to run some commands to find out more information about the programs we see? We don’t need to exit out of “top”. We can create a new window to run these commands.

    Ctrl-a c

The “Ctrl-a c” sequence creates a new window for us. We can now run whatever commands we want without disrupting the monitoring we were doing in the other window.

Where did that other window go? We can get back to it using a new command:

    Ctrl-a n

This sequence goes to the next window that we are running. The list of windows wrap, so when there aren’t windows beyond the current one, it switches us back to the first window.

    Ctrl-a p

This sequence changes the current window in the opposite direction. So if you have three windows and are currently on the third, this command will switch you to the second window.

A helpful shortcut to use when you’re flipping between the same two windows is this:

    Ctrl-a Ctrl-a

This sequence moves you to your most recently visited window. So in the previous example, this would move you back to your third window.

At this point, you might be wondering how you can keep track of all of the windows that we are creating. Thankfully, screen comes with a number of different ways of managing your different sessions. First, we’ll create three new windows for a total of four windows and then we’ll try out one of the simplest window management tools, “Ctrl-a w”.

    Ctrl-a c Ctrl-a c Ctrl-a c Ctrl-a w

    0$ bash 1$ bash 2-$ bash 3\*$ bash

We get some useful information from this command: a list of our current windows. Here, we have four windows. Each window has a number and the windows are numbered starting at “0”. The current window has an asterisk next to the number.

So you can see that we’re currently at window #3 (actually the fourth window because the first window is 0). So how do we get to window #1 quickly?

    Ctrl-a 1

We can use the index number to jump straight to the window we want. Let’s see our window list again.

    Ctrl-a w

    0$ bash 1\*$ bash 2$ bash 3-$ bash

As you can see, the asterisk tells us that we’re now on window #1. Let’s try a different way of switching windows.

    Ctrl-a “

    Num Name Flags 0 bash $ 1 bash $ 2 bash $ 3 bash $

We get an actual navigation menu this time. You can navigate with either the up and down arrows or with “j” and “k” like you would in the vi text editor. Switch to a window by pressing “Return” or “Enter”.

This is pretty useful, but right now all of our windows are named “bash”. That’s not very helpful. Let’s name some of our sessions. Switch to a window you want to name and then use the “Ctrl-a A” sequence.

    Ctrl-a 0 Ctrl-a A

    Set window's title to: bash

Using the “Ctrl-a A” sequence, we can name our sessions. You can now backspace over “bash” and then rename it whatever you’d like. We’re going to run “top” on window #0 again, so we’re going to name it “monitoring”.

    Set window's title to: monitoring

    Ctrl-a “

    Num Name Flags 0 monitoring $ 1 bash $ 2 bash $ 3 bash $

Now we have a more helpful label for window #0. So we know how to create and name windows, but how do we get rid of them when we don’t need them anymore? We use the “Ctrl-a k” sequence, which stands for “kill”.

    Ctrl-a k

    Really kill this window [y/n]

## Managing Screen Sessions

When you want to quit screen and kill all of your windows, you can use this command sequence.

    Ctrl-a \

    Really quit and kill all your windows [y/n]

This will destroy our screen session. We will lose any windows we have created and any unfinished work.

But we want to explore one of the huge benefits of using “screen”. We don’t want to destroy the session, we simply want to detach it. Detaching allows our programs in the screen instance to continue to run, but it gives us access back to our base-console session (the one where we started “screen” from initially). The screen session is still there, it will just be managed in the background.

    Ctrl-a d

    [detached from 1835.pts-0.Blank]

So our session is now detached. How do we get back into it?

    screen –r

The “r” stands for reattach. We are now back in our screen session. What if we have multiple screen sessions though? What if we had started a screen session and detached it, and then started a _new_ screen session and detached that as well?

    screen Ctrl-a d screen Ctrl-a d

How do we tell screen which session to attach?

     screen –ls

     There are screens on: 2171.pts-0.Blank (07/01/2013 05:00:39 PM) (Detached) 1835.pts-0.Blank (07/01/2013 03:50:43 PM) (Detached) 2 Sockets in /var/run/screen/S-justin.

Now we have a list of our sessions. We can reattach the second one by typing its id number after the “-r” flag.

    screen –r 1835

What if you want to attach a session on two separate computers or terminal windows? You can use the “-x” flag, which lets you share the session.

    screen –x

## Managing Terminals Within Screen

There are a number of commands that help you manage the terminal sessions you run within screen.

To copy text, you can use this sequence:

    Ctrl-a [

This will give you a cursor that you can move with arrow keys or h,j,k,l keys (like vi). Move to where you want to start copying, and hit “Return” or “Enter”. Move to the end of where you’d like to copy and hit “Return” or “Enter” again. The text is then copied to your clipboard.

One thing to be aware of is that this is also screen’s mechanism for scrolling. If you need to see some text that is off the screen, you can hit “Ctrl-a [“ and then scroll up off of the screen.

We can paste text that we copied with the right bracket.

    Ctrl-a ]

Another thing you might want to do is monitor programs that are executing in another screen window.

Let’s say that you’re compiling something in one window and you want to know when it’s completed. You can ask screen to monitor that window for silence with the “Ctrl-a \_” sequence, which will tell you when no output has been generated for 30 seconds.

Let’s try it with a simpler example. Let’s have screen tell us when our window is finished pinging google 4 times.

    ping –c 4 www.google.com Ctrl-a \_

     The window is now being monitored for 30 sec. silence.

Now we can do work in another window and be alerted when the task in this window is complete.

    Ctrl-a 1

    Window 2: silence for 30 seconds

We can also do the opposite and be alerted when there is activity happening on a specific window. We accomplish this with the “Ctrl-a M” sequence.

    sleep 20 && echo “output” Ctrl-a M

    Window 2 (bash) is now being monitored for all activity.

We will now be alerted when the command produces output.

    Ctrl-a 1

    Activity in window 2

Let’s say we are going to be doing some important changes and we want to have a log of all of the commands we run. We can log the session with:

    Ctrl-a H

    Creating logfile "screenlog.1".

## Screen Regions

If we need to see multiple windows at once, we can use something that screen calls “regions”. We create more regions by splitting the current region. To split the current region horizontally, we can type:

    Ctrl-a S

This will move our current window to the top half of the screen and open a new blank region below it. We can get to the lower screen with the “tab” key:

    Ctrl-a [tab]

We can then either create a new window in the bottom region or change the view to a different window in the normal way.

If we want to kill the current region, we can use this sequence:

    Ctrl-a X

That destroys the region without destroying the actual window. This means that if you were running a program in that region, you can still access it as a normal window, the view into that window was simply destroyed.

If we want to make a vertical split, we can use this sequence instead:

    Ctrl-a |

Note: that is not the 1 (number one) or L character. It is the “pipe” character, found on the same key as “\” on most keyboards.

The controls for vertical splits are the same as horizontal splits. If we’ve added a few different regions and want to go back to a single region, we can use this sequence, which destroys all regions but the current one.

    Ctrl-a Q

## Using Byobu

A great enhancement for screen is a program called “byobu”. It acts as a wrapper for screen and provides an enhanced user experience. On Ubuntu, you can install it with:

    sudo apt-get install byobu

Before we begin, we need to tell byobu to use screen as a backend. We can do this with the following command:

    byobu-select-backend

    Select the byobu backend: 1. tmux 2. screen Choose 1-2 [1]: 

We can choose screen here to set it as the default terminal manager.

Now, instead of typing in “screen” to start a session, you can type “byobu”.

    byobu

    Welcome to Ubuntu 12.04 LTS (GNU/Linux 3.2.0-24-virtual i686) \* Documentation: https://help.ubuntu.com/ Welcome to the light, powerful, text window manager, Byobu. You can toggle the launch of Byobu at login with: 'byobu-disable' and 'byobu-enable' For tips, tricks, and more information, see: \* http://bit.ly/byobu-help justin@Blank:~$ u? 12.04 0:\* 118! 3h55m 2.00 2.0GHz 496M6% 2013-07-01 18:19:21

 As you can see, you now have screen wrapped in a nice interface. When you type “Ctrl-a” for the first time, you’ll have to tell byobu to recognize that as a screen command and not an Emacs command. 

    Ctrl-a

    Configure Byobu's ctrl-a behavior... When you press ctrl-a in Byobu, do you want it to operate in: (1) Screen mode (GNU Screen's default escape sequence) (2) Emacs mode (go to beginning of line) Note that: - F12 also operates as an escape in Byobu - You can press F9 and choose your escape character - You can run 'byobu-ctrl-a' at any time to change your selection Select [1 or 2]:

 Select “1” to use byobu as normal. The interface gives you a lot of useful information, such as a window list and system information. On Ubuntu, it even tells you how many packages have security updates with a number followed by an exclamation point on a red background. One thing that is different between using byobu and screen is the way that byobu actually manages sessions. If you simply type “byobu” again once you’re detached, it will simply reattach your previous session instead of creating a new one. To create a new session, you must type: 

    byobu –S sessionname

 Change “sessionname” to whatever you’d like to call your new session. You can see a list of current sessions with: 

    byobu –ls

    There are screens on: 22961.new (07/01/2013 06:42:52 PM) (Detached) 22281.byobu (07/01/2013 06:37:18 PM) (Detached) 2 Sockets in /var/run/screen/S-root.

 And if there are multiple sessions, when you type “byobu”, you will be presented with a menu to choose which session you want to connet to. 

    byobu

    Byobu sessions... 1. screen: 22961.new (07/01/2013 06:42:52 PM) (Detached) 2. screen: 22281.byobu (07/01/2013 06:37:18 PM) (Detached) 3. Create a new Byobu session (screen) 4. Run a shell without Byobu (/bin/bash) Choose 1-4 [1]: 

You can select any of the current sessions, create a new byobu session, or even get a new shell without using byobu.

One option that might be useful on a cloud server you manage remotely is to have byobu start up automatically whenever you log into your session. That means that if you are ever disconnected from your session, your work won’t be lost, and you can simply re-connect to get right back to where you were before.

To enable byobu to automatically start with every login, type this into the terminal:

    byobu-enable

    The Byobu window manager will be launched automatically at each text login. To disable this behavior later, just run: byobu-disable Press <enter> to continue...</enter>

As it says, if you ever want to turn this feature off again, simply type:

    byobu-disable

It will no longer start automatically.

By [Justin Ellingwood](https://plus.google.com/u/1/100832288660935471563?rel=author)
