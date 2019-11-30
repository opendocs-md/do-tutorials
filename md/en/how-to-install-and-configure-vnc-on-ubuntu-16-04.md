---
author: finid
date: 2016-04-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-vnc-on-ubuntu-16-04
---

# How to Install and Configure VNC on Ubuntu 16.04

## Introduction

VNC, or “Virtual Network Computing”, is a connection system that allows you to use your keyboard and mouse to interact with a graphical desktop environment on a remote server. It makes managing files, software, and settings on a remote server easier for users who are not yet comfortable with the command line.

In this guide, we will be setting up VNC on an Ubuntu 16.04 server and connecting to it securely through an SSH tunnel. The VNC server we will be using is TightVNC, a fast and lightweight remote control package. This choice will ensure that our VNC connection will be smooth and stable even on slower internet connections.

## Prerequisites

To complete this tutorial, you’ll need:

- An Ubuntu 16.04 Droplet set up via the [Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), which includes having a sudo non-root user. Note that this tutorial can be completed using any size Droplet, but a VNC built on a smaller droplet may have more limits on functionality than a larger one.

- A local computer with a VNC client installed that supports VNC connections over SSH tunnels. If you are using Windows, you could use TightVNC, RealVNC, or UltraVNC. Mac OS X users can use the built-in Screen Sharing program, or can use a cross-platform app like RealVNC. Linux users can choose from many options: `vinagre`, `krdc`, RealVNC, TightVNC, and more.

## Step 1 — Installing the Desktop Environment and VNC Server

By default, an Ubuntu 16.04 Droplet does not come with a graphical desktop environment or a VNC server installed, so we’ll begin by installing those. Specifically, we will install packages for the latest Xfce desktop environment and the TightVNC package available in the official Ubuntu repository.

On your server, install the Xfce and TightVNC packages.

    sudo apt-get update
    sudo apt install xfce4 xfce4-goodies tightvncserver

To complete the VNC server’s initial configuration after installation, use the `vncserver` command to set up a secure password.

    vncserver

You’ll be prompted to enter and verify a password, and also a view-only password. Users who log in with the view-only password will not be able to control the VNC instance with their mouse or keyboard. This is a helpful option if you want to demonstrate something to other people using your VNC server, but isn’t necessary.

Running `vncserver` completes the installation of VNC by creating default configuration files and connection information for our server to use. With these packages installed, you are now ready to configure your VNC server.

## Step 2 — Configuring the VNC Server

First, we need to tell our VNC server what commands to perform when it starts up. These commands are located in a configuration file called `xstartup` in the `.vnc` folder under your home directory. The startup script was created when you ran the `vncserver` in the previous step, but we need modify some of the commands for the Xfce desktop.

When VNC is first set up, it launches a default server instance on port 5901. This port is called a display port, and is referred to by VNC as `:1`. VNC can launch multiple instances on other display ports, like `:2`, `:3`, etc. When working with VNC servers, remember that `:X` is a display port that refers to `5900+X`.

Because we are going to be changing how the VNC server is configured, we’ll need to first stop the VNC server instance that is running on port 5901.

    vncserver -kill :1

The output should look like this, with a different PID:

    OutputKilling Xtightvnc process ID 17648

Before we begin configuring the new `xstartup` file, let’s back up the original.

    mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

Now create a new `xstartup` file with `nano` or your favorite text editor.

    nano ~/.vnc/xstartup

Paste these commands into the file so that they are performed automatically whenever you start or restart the VNC server, then save and close the file.

    ~/.vnc/xstartup#!/bin/bash
    xrdb $HOME/.Xresources
    startxfce4 &

The first command in the file, `xrdb $HOME/.Xresources`, tells VNC’s GUI framework to read the server user’s `.Xresources` file. `.Xresources` is where a user can make changes to certain settings of the graphical desktop, like terminal colors, cursor themes, and font rendering. The second command simply tells the server to launch Xfce, which is where you will find all of the graphical software that you need to comfortably manage your server.

To ensure that the VNC server will be able to use this new startup file properly, we’ll need to grant executable privileges to it.

    sudo chmod +x ~/.vnc/xstartup

Now, restart the VNC server.

    vncserver

The server should be started with an output similar to this:

    OutputNew 'X' desktop is your_server_name.com:1
    
    Starting applications specified in /home/sammy/.vnc/xstartup
    Log file is /home/sammy/.vnc/liniverse.com:1.log

## Step 3 — Testing the VNC Desktop

In this step, we’ll test the connectivity of your VNC server.

First, we need to create an SSH connection on your local computer that securely forwards to the `localhost` connection for VNC. You can do this via the terminal on Linux or OS X with following command. Remember to replace `user` and `server_ip_address` with the sudo non-root username and IP address of your server.

    ssh -L 5901:127.0.0.1:5901 -N -f -l username server_ip_address

If you are using a graphical SSH client, like PuTTY, use `server_ip_address` as the connection IP, and set `localhost:5901` as a new forwarded port in the program’s SSH tunnel settings.

Next, you may now use a VNC client to attempt a connection to the VNC server at `localhost:5901`. You’ll be prompted to authenticate. The correct password to use is the one you set in Step 1.

Once you are connected, you should see the default Xfce desktop. It should look something like this:

![VNC connection to Ubuntu 16.04 server](http://i.imgur.com/X4eEcuV.png)

You can access files in your home directory with the file manager or from the command line, as seen here:

![Files via VNC connection to Ubuntu 16.04](http://i.imgur.com/n5VPuSa.png)

## Step 4 — Creating a VNC Service File

Next, we’ll set up the VNC server as a systemd service. This will make it possible to start, stop, and restart it as needed, like any other systemd service.

First, create a new unit file called `/etc/systemd/system/vncserver@.service` using your favorite text editor:

    sudo nano /etc/systemd/system/vncserver@.service

Copy and paste the following into it. Be sure to change the value of **User** and the username in the value of **PIDFILE** to match your username.

    /etc/systemd/system/vncserver@.service [Unit]
    Description=Start TightVNC server at startup
    After=syslog.target network.target
    
    [Service]
    Type=forking
    User=sammy
    PAMName=login
    PIDFile=/home/sammy/.vnc/%H:%i.pid
    ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
    ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
    ExecStop=/usr/bin/vncserver -kill :%i
    
    [Install]
    WantedBy=multi-user.target

Save and close the file.

Next, make the system aware of the new unit file.

    sudo systemctl daemon-reload

Enable the unit file.

    sudo systemctl enable vncserver@1.service

The `1` following the `@` sign signifies which display number the service should appear over, in this case the default `:1` as was discussed above.   
Stop the current instance of the VNC server if it’s still running.

    vncserver -kill :1

Then start it as you would start any other systemd service.

    sudo systemctl start vncserver@1

You can verify that it started with this command:

    sudo systemctl status vncserver@1

If it started correctly, the output should look like this:

Output

    vncserver@1.service - TightVNC server on Ubuntu 16.04
       Loaded: loaded (/etc/systemd/system/vncserver@.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-25 03:21:34 EDT; 6s ago
      Process: 2924 ExecStop=/usr/bin/vncserver -kill :%i (code=exited, status=0/SUCCESS)
    
    ...
    
     systemd[1]: Starting TightVNC server on Ubuntu 16.04...
     systemd[2938]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[2949]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[1]: Started TightVNC server on Ubuntu 16.04.

## Conclusion

You should now have a secured VNC server up and running on your Ubuntu 16.04 server. Now you’ll be able to manage your files, software, and settings with an easy-to-use and familiar graphical interface.
