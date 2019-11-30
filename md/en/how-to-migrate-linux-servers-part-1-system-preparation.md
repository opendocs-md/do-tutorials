---
author: Justin Ellingwood
date: 2014-02-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-migrate-linux-servers-part-1-system-preparation
---

# How To Migrate Linux Servers Part 1 - System Preparation

## Introduction

* * *

There are many scenarios where you might have to move your data and operating requirements from one server to another. You may need to implement your solutions in a new datacenter, upgrade to a larger machine, or transition to new hardware or a new VPS provider.

Whatever your reasons, there are many different considerations you should make when migrating from one system to another. Getting functionally equivalent configurations can be difficult if you are not operating with a configuration management solution such as Chef, Puppet, or Ansible. You need to not only transfer data, but also configure your services to operate in the same way on a new machine.

In this guide, we will discuss how to prepare your source and target systems for a migration. This will include getting your two machines to communicate with SSH keys and a heavy investigation as to what components need to be transferred. We will work on the actual migration in the [next article](https://www.digitalocean.com/community/articles/how-to-migrate-linux-servers-part-2-transfer-core-data).

## Make Backups

* * *

The first step to take when performing any potentially destructive step is to create fresh backups. Just because there shouldn’t be a problem doesn’t mean that something unexpected isn’t going to happen. You don’t want to be left in a situation where a command breaks something on your current production machine before the replacement is up and running.

There are a number of different ways to back up your server. Your selection will depend on what options make sense for your scenario and what you are most comfortable with.

If you have access to the physical hardware and a space to backup (disk drive, USB, etc), you can clone the disk using any one of the many image backup solutions available. A functional equivalent when dealing with VPS machines is to take a snapshot or image from within the [control panel interface](https://www.digitalocean.com/community/articles/digitalocean-backups-and-snapshots-explained).

Other options often will preserve data and perhaps some of the information about your services. It all depends on which backup mechanism you wish to implement. Our community pages have [articles on many different backup options](https://www.digitalocean.com/community/community_tags/backups). Choose one that makes sense for your data and system.

Once you have completed backups, you are ready to continue. For the remainder of this guide, we will assume that you are logged into both systems as root.

## Gather Information about the Source System

* * *

Before we begin migrating, we should take the initial steps to set up our target system to match our source system.

We will want to match as much as we can between the current server and the one we plan on migrating to. If you want the migration to go smoothly, then you shouldn’t take this as an opportunity to upgrade to the newest version or try new things. Making changes can lead to instability and problems down the line.

Most of the basic information that will help you decide which server system to create for the new machine can be retrieved with a simple `uname` command:

    uname -r

* * *

    3.2.0-24-virtual

This is the version of the kernel that our current system is running. In order to make things go smoothly, it’s always a good idea to try to match that on the target system.

    uname -m

* * *

    i686

This is the system architecture. `i686` indicates that this is a 32-bit system. If the returned string was `x86_64`, this would mean that this is a 64-bit system.

You should also try to match the distribution and version of your source server. If you don’t know the version of the distribution that you have installed on the source machine, you can find out by typing:

    cat /etc/issue

* * *

    Ubuntu 12.04.2 LTS \n \l

You should create your new server with these same parameters if possible. In this case, we would create a 32-bit Ubuntu 12.04 system. If possible, we’d also attempt to match the kernel version on the new system.

## Set Up SSH Key Access between Source and Target Servers

* * *

We’ll need our servers to be able to communicate so that they can transfer files. The easiest way to do this is with SSH keys. You can learn [how to configure SSH keys on a Linux server](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2) here.

We want to create a new key on our target server so that we can add that to our source server’s `authorized_keys` file. This is cleaner than the other way around, because then the new server will not have a stray key in its `authorized_keys` file when the migration is complete.

First, on your destination machine, check that your root user doesn’t already have an SSH key (you should be logged in as root) by typing:

    ls ~/.ssh

* * *

    authorized_keys

If you see files called `id_rsa.pub` and `id_rsa`, then you already have keys and you’ll just need to transfer them.

If you don’t see those files, create a new key pair by typing:

    ssh-keygen -t rsa

Press “Enter” through all of the prompts to accept the defaults.

Now, transfer the key to the source server by typing:

    cat ~/.ssh/id\_rsa.pub | ssh other\_server\_ip "cat \>\> ~/.ssh/authorized\_keys"

You should now be able to SSH freely to your source server from the target system by typing:

    ssh other\_server\_ip

You should not be prompted for a password if you configured this correctly.

## Create a List of Requirements

* * *

This is actually the first part where you’re going to be doing in-depth analysis of your system and requirements.

During the course of operations, your software requirements can change. Sometimes old servers have some services and software that were needed at one point, but have been replaced.

While unneeded services should be disabled and, if completely unnecessary, uninstalled, this doesn’t always happen. You need to discover what services are being used on your source server, and then decide if those services should exist on your new server.

The way that you discover services and runlevels largely depends on the type of “init” system that your server employs. The init system is responsible for starting and stopping services, either at the user’s command or automatically.

### Discovering Services and Runlevels on System V Servers

* * *

System V is one of the older init systems still in use on many servers today. Ubuntu has attempted to switch to the Upstart init system, and in the future may be transitioning to a Systemd init system.

Currently, both System V style init files and the newer Upstart init files can be found on the same systems, meaning you’ll have more places to look. Other systems use System V as well. You can see if your server uses System V by typing:

    which service

* * *

    /usr/sbin/service

If the command returns a system path, as it did above, you have System V on your system.

You can get an idea of which services are currently running by typing this:

    service --status-all

* * *

     [?] acpid
     [?] anacron
     [+] apache2
     [?] atd
     [-] bootlogd
     [?] console-setup
     [?] cron
     [?] cryptdisks
     . . .

This will list all of the services that the System-V init system knows about. The “+” means that the service is started, the “-” means it is stopped, and the “?” means that System-V doesn’t know the state of the service.

If System-V doesn’t know the state of the service, it’s possible that it is controlled by an alternative init system. On Ubuntu systems, this is usually Upstart.

Other than figuring out which services are running currently, another good piece of information to have is what runlevel a service is active in. Runlevels dictate which services should be made available when the server is in different states. You will probably want to match the source server’s configuration on the new system.

You can discover the runlevels that each service will be active for using a number of tools. One way is through tools like `chkconfig` or `sysv-rc-conf`.

On an Ubuntu or Debian system, you can install and use `chkconfig` to check for which System V services are available at different runlevels like this. Most RHEL-based systems should already have this software installed:

    apt-get update
    apt-get install chkconfig
    chkconfig --list

* * *

    acpid 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    anacron 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    apache2 0:off 1:off 2:on 3:on 4:on 5:on 6:off
    atd 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    bootlogd 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    console-setup 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    cron 0:off 1:off 2:off 3:off 4:off 5:off 6:off
    cryptdisks 0:on 1:off 2:off 3:off 4:off 5:off 6:off
    cryptdisks-early 0:on 1:off 2:off 3:off 4:off 5:off 6:off
    . . .

Another alternative is `sysv-rc-conf`, which can be installed and run like this:

    apt-get update
    apt-get install sysv-rc-conf
    sysv-rc-conf --list

* * *

    acpid       
    anacron     
    apache2 0:off 1:off 2:on 3:on 4:on 5:on 6:off
    atd         
    bootlogd    
    console-setu
    cron        
    cryptdisks 0:on 6:on
    cryptdisks-e 0:on 6:on
    . . .

If you would like to manually check instead of using a tool, you can do that by checking a number of directories that take the form of `/etc/rc*.d/`. The asterisk will be replaced with the number of the runlevel.

For instance, to see what services are activated by System V in runlevel 2, you can check the files there:

    cd /etc/rc2.d
    ls -l

* * *

    total 4
    -rw-r--r-- 1 root root 677 Jul 26 2012 README
    lrwxrwxrwx 1 root root 18 Dec 28 2012 S20php5-fpm -> ../init.d/php5-fpm
    lrwxrwxrwx 1 root root 15 Apr 26 2012 S50rsync -> ../init.d/rsync
    lrwxrwxrwx 1 root root 14 Jun 21 2013 S75sudo -> ../init.d/sudo
    lrwxrwxrwx 1 root root 17 Dec 28 2012 S91apache2 -> ../init.d/apache2
    . . .

These are links to configuration files located in `/etc/init.d/`. Each link that begins with an “S” means that it is used to start a service. Scripts that start with a “K” kill services off at that runlevel.

### Discovering Services and Runlevels on Upstart Servers

* * *

Ubuntu and Ubuntu-based servers are pretty much the only servers that implement the Upstart init system by default. These are typically used as the main init system, with System V being configured for legacy services.

To see if your server has an Upstart init system, type:

    which initctl

* * *

    /sbin/initctl

If you receive a path to the executable as we did above, then your server has Upstart capabilities and you should investigate which services are controlled by Upstart.

You can see which services are started by Upstart by typing:

    initctl list

* * *

    mountall-net stop/waiting
    passwd stop/waiting
    rc stop/waiting
    rsyslog start/running, process 482
    tty4 start/running, process 728
    udev start/running, process 354
    upstart-udev-bridge start/running, process 350
    ureadahead-other stop/waiting
    . . .

This will tell you the current state of all Upstart managed services. You can tell which services are being run currently and maybe see if there are services that provide the same functionality where one has taken over for a legacy service that is no longer in use.

Again, you should become familiar with what services are supposed to be available at each runlevel.

You can do this with the `initctl` command by typing:

    initctl show-config

* * *

    mountall-net
      start on net-device-up
    passwd
      start on filesystem
    rc
      emits deconfiguring-networking
      emits unmounted-remote-filesystems
      start on runlevel [0123456]
      stop on runlevel [!$RUNLEVEL]
    rsyslog
      start on filesystem
      stop on runlevel [06]
      . . .

This spits out a lot of configuration information for each service. The part to look for is the runlevel specification.

If you would rather gather this information manually, you can look at the files located in the `/etc/init` directory (notice the omission of the “.d” after the “init” here).

Inside, you will find a number of configuration files. Within these files, there are runlevel specifications given like this:

    start on runlevel [2345]
    stop on runlevel [!2345]

You should have a good idea of different ways of discovering Upstart services and runlevels.

### Discovering Services and Runlevels on Systemd Servers

* * *

A newer init style that is increasingly being adopted by distributions is the systemd init system.

Systemd is rather divergent from the other types of init systems, but is incredibly powerful. You can find out about running services by typing:

    systemctl list-units -t service

* * *

    UNIT LOAD ACTIVE SUB DESCRIPTION
    atd.service loaded active running ATD daemon
    avahi-daemon.service loaded active running Avahi mDNS/DNS-SD Stack
    colord.service loaded active running Manage, Install and Generate Color Profiles
    cups.service loaded active running CUPS Printing Service
    dbus.service loaded active running D-Bus System Message Bus
    dcron.service loaded active running Periodic Command Scheduler
    dkms.service loaded active exited Dynamic Kernel Modules System
    . . .

Systemd doesn’t exactly replicate the runlevels concept of other init systems. Instead, it implements the concept of “targets”. While systems with traditional init systems can only be in one runlevel at a time, a server that uses systemd can reach several targets at the same time.

Because of this, figuring out what services are active when is a little bit more difficult.

You can see which targets are currently active by typing:

    systemctl list-units -t target

* * *

    UNIT LOAD ACTIVE SUB DESCRIPTION
    basic.target loaded active active Basic System
    cryptsetup.target loaded active active Encrypted Volumes
    getty.target loaded active active Login Prompts
    graphical.target loaded active active Graphical Interface
    local-fs-pre.target loaded active active Local File Systems (Pre)
    local-fs.target loaded active active Local File Systems
    . . .

You can list all available targets by typing:

    systemctl list-unit-files -t target

* * *

    UNIT FILE STATE   
    basic.target static  
    bluetooth.target static  
    cryptsetup.target static  
    ctrl-alt-del.target disabled
    default.target disabled
    emergency.target static  
    final.target static  
    getty.target static  
    graphical.target disabled
    halt.target disabled
    . . .

From here, we can find out which services are associated with each target. Targets can have services or other targets as dependencies, so we can see what policies each target implements by typing:

    systemctl list-dependencies target\_name.target

For instance, you might type something like this:

    systemctl list-dependencies multi-user.target

* * *

    multi-user.target
    ├─atd.service
    ├─avahi-daemon.service
    ├─cups.path
    ├─dbus.service
    ├─dcron.service
    ├─dkms.service
    ├─gpm.service
    . . .

This will list the dependency tree of that target, giving you a list of services and other targets that get started when that target is reached.

### Double Checking Services Through Other Methods

* * *

While most services will be configured through the init system, there are possibly some areas where a process or service will slip through the cracks and be controlled independently.

We can try to find these other services and processes by looking at the side effects of these services. In most cases, services communicate with each other or outside entities in some way. There are only a specific number of ways that services can communicate, and checking those interfaces is a good way to spot other services.

One tool that we can use to discover network ports and Unix sockets that are being used by processes to communicate is `netstat`. We can issue a command like this to get an overview of some of our services:

    netstat -nlp

* * *

    Active Internet connections (only servers) Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name tcp 0 0 127.0.0.1:3306 0.0.0.0:\* LISTEN 762/mysqld tcp 0 0 0.0.0.0:80 0.0.0.0:\* LISTEN 832/apache2 tcp 0 0 0.0.0.0:22 0.0.0.0:\* LISTEN 918/sshd tcp 0 0 127.0.0.1:9000 0.0.0.0:\* LISTEN 799/php-fpm.conf) tcp6 0 0 :::22 :::\* LISTEN 918/sshd Active UNIX domain sockets (only servers) Proto RefCnt Flags Type State I-Node PID/Program name Path unix 2 [ACC] STREAM LISTENING 1526 1/init @/com/ubuntu/upstart unix 2 [ACC] SEQPACKET LISTENING 1598 354/udevd /run/udev/controlunix 2 [ACC] STREAM LISTENING 6982 480/dbus-daemon /var/run/dbus/system\_bus\_socketunix 2 [ACC] STREAM LISTENING 8378 762/mysqld /var/run/mysqld/mysqld.sockunix 2 [ACC] STREAM LISTENING 1987 746/acpid /var/run/acpid.socket

The port numbers in the first section are associated with the programs on the far right. Similarly, the bottom portion focuses on Unix sockets that are being used by programs.

If you see services here that you do not have information about through the init system, you’ll have to figure out why that is and what kind of information you’ll need to gather about that service.

You can get similar information about the ports services are making available by using the `lsof` command:

    lsof -nPi

* * *

    COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
    mysqld 762 mysql 10u IPv4 8377 0t0 TCP 127.0.0.1:3306 (LISTEN)
    php5-fpm 799 root 6u IPv4 8195 0t0 TCP 127.0.0.1:9000 (LISTEN)
    php5-fpm 800 www-data 0u IPv4 8195 0t0 TCP 127.0.0.1:9000 (LISTEN)
    php5-fpm 801 www-data 0u IPv4 8195 0t0 TCP 127.0.0.1:9000 (LISTEN)
    php5-fpm 802 www-data 0u IPv4 8195 0t0 TCP 127.0.0.1:9000 (LISTEN)
    php5-fpm 803 www-data 0u IPv4 8195 0t0 TCP 127.0.0.1:9000 (LISTEN)
    apache2 832 root 3u IPv4 8210 0t0 TCP *:80 (LISTEN)
    sshd 918 root 3r IPv4 7738 0t0 TCP *:22 (LISTEN)
    . . .

You can get some great information from the `ss` command on what processes are using what ports and sockets:

    ss -nlpaxtudw

* * *

    Netid State Recv-Q Send-Q Local Address:Port Peer Address:Port 
    u_str LISTEN 0 0 @/com/ubuntu/upstart 1526 * 0 users:(("init",1,7))
    u_str ESTAB 0 0 @/com/ubuntu/upstart 1589 * 0 users:(("init",1,10))
    u_str ESTAB 0 0 * 1694 * 0 users:(("dbus-daemon",480,6))
    u_str ESTAB 0 0 * 1695 * 0 users:(("dbus-daemon",480,7))
    u_str ESTAB 0 0 * 1803 * 0

## Gathering Package Versions

* * *

After all of that exploration, you should have a good idea about what services are running on your source machine that you should be implementing on your target server.

You should have a list of services that you know you will need to implement. For the transition to go smoothly, it is important to attempt to match versions where ever it is possible.

You obviously won’t be able to go through every single package installed on the source system and attempt to replicate it on the new system, but you should check the software components that are important for your needs and try to find the version number.

You can try to get version numbers from the software itself, sometimes by passing `-v` or `--version` flags to the commands, but usually this is easier to accomplish through your package manager. If you are on an Ubuntu/Debian based system, you can see which version of the packages are installed from the package manager by typing:

    dpkg -l | grep package\_name

If you are instead on a RHEL-based system, you can use this command to check the installed version instead.

    rpm -qa | grep package\_name

This will give you a good idea of the program version you are looking to installed.

Keep a list of the version numbers of the important components that you wish to install. We will attempt to acquire these on the target system.

## Next Steps

* * *

You should now have a good idea of what processes and services on your source server need to be transferred over to your new machine. You should also have the preliminary steps completed to allow your two server instances to communicate with each other.

The groundwork for your migration is now complete. You should now be able to jump into the migration in the [next article](https://www.digitalocean.com/community/articles/how-to-migrate-linux-servers-part-2-transfer-core-data) with a good idea of what you need to do.

By Justin Ellingwood
