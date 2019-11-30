---
author: Justin Ellingwood, Kathryn Hancox
date: 2019-06-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/recommended-steps-for-new-freebsd-12-0-servers
---

# Recommended Steps For New FreeBSD 12.0 Servers

## Introduction

When setting up a new FreeBSD server, there are a number of optional steps you can take to get your server into a more production-friendly state. In this guide, we will cover some of the most common examples.

We will set up a simple, easy-to-configure firewall that denies most traffic. We will also make sure that your server’s time zone accurately reflects its location. We will set up NTP polling in order to keep the server’s time accurate and, finally, demonstrate how to add some extra swap space to your server.

Before you get started with this guide, you should log in and configure your shell environment the way you’d like it. You can find out how to do this by following [this guide](how-to-get-started-with-freebsd).

## How To Configure a Simple IPFW Firewall

The first task is setting up a simple firewall to secure your server.

FreeBSD supports and includes three separate firewalls. These are called `pf`, `ipfw`, and `ipfilter`. In this guide, we will be using [`ipfw`](https://www.freebsd.org/doc/handbook/firewalls-ipfw.html) as our firewall. `ipfw` is a secure, stateful firewall written and maintained as part of FreeBSD.

### Configuring the Basic Firewall

Almost all of your configuration will take place in the `/etc/rc.conf` file. To modify the configuration you’ll use the `sysrc` command, which allows users to change configuration in `/etc/rc.conf` in a safe manner. Inside this file you’ll add a number of different lines to enable and control how the `ipfw` firewall will function. You’ll start with the essential rules; run the following command to begin:

    sudo sysrc firewall_enable="YES"

Each time you run `sysrc` to modify your configuration, you’ll receive output showing the changes:

    Outputfirewall_enable: NO -> YES

As you may expect, this first command enables the `ipfw` firewall, starting it automatically at boot and allowing it to be started with the usual `service` commands.

Now run the following:

    sudo sysrc firewall_quiet="YES"

This tells `ipfw` not to output anything to standard out when it performs certain actions. This might seem like a matter of preference, but it actually affects the functionality of the firewall.

Two factors combine to make this an important option. The first is that the firewall configuration script is executed in the current shell environment, not as a background task. The second is that when the `ipfw` command reads a configuration script without the `"quiet"` flag, it reads and outputs each line, in turn, to standard out. When it outputs a line, it **immediately** executes the associated action.

Most firewall configuration files flush the current rules at the top of the script in order to start with a clean slate. If the `ipfw` firewall comes across a line like this without the quiet flag, it will immediately flush all rules and revert to its default policy, which is usually to deny all connections. If you’re configuring the firewall over SSH, this would drop the connection, close the current shell session, and none of the rules that follow would be processed, effectively locking you out of the server. The quiet flag allows the firewall to process the rules as a set instead of implementing each one individually.

After these two lines, you can begin configuring the firewall’s behavior. Now select `"workstation"` as the type of firewall you’ll configure:

    sudo sysrc firewall_type="workstation"

This sets the firewall to protect the server from which you’re configuring the firewall using stateful rules. A _stateful firewall_ monitors the state of network connections over time and stores information about these connections in memory for a short time. As a result, not only can rules be defined on what connections the firewall should allow, but a stateful firewall can also use the data it has learned about previous connections to evaluate which connections can be made.

The `/etc/rc.conf` file also allows you to customize the services you want clients to be able to access by using the `firewall_myservices` and `firewall_allowservices` options.

Run the following command to open ports that should be accessible on your server, such as port `22` for your SSH connection and port `80` for a conventional HTTP web server. If you use SSL on your web server, make sure to add port `443`:

    sudo sysrc firewall_myservices="22/tcp 80/tcp 443/tcp"

The `firewall_myservices` option is set to a list of TCP ports or services, separated by spaces, that should be accessible on your server.

**Note:** You could also use services by name. The services that FreeBSD knows by name are listed in the `/etc/services` file. For instance, you could change the previous command to something like this:

    firewall_myservices="ssh http https"

This would have the same results.

The `firewall_allowservices` option lists items that should be allowed to access the provided services. Therefore it allows you to limit access to your exposed services (from `firewall_myservices`) to particular machines or network ranges. For example, this could be useful if you want a machine to host web content for an internal company network. The keyword `"any"` means that any IPs can access these services, making them completely public:

    sudo sysrc firewall_allowservices="any"

The `firewall_logdeny` option tells `ipfw` to log all connection attempts that are denied to a file located at `/var/log/security`. Run the following command to set this:

    sudo sysrc firewall_logdeny="YES"

To check on the changes you’ve made to the firewall configuration, run the following command:

    grep 'firewall' /etc/rc.conf

This portion of the `/etc/rc.conf` file will look like this:

    Outputfirewall_enable="YES"
    firewall_quiet="YES"
    firewall_type="workstation"
    firewall_myservices="22 80 443"
    firewall_allowservices="any"
    firewall_logdeny="YES"

Remember to adjust the `firewall_myservices` option to reference the services you wish to expose to clients.

### Allowing UDP Connections (Optional)

The ports and services listed in the `firewall_myservices` option in the `/etc/rc.conf` file allow access for TCP connections. If you have services that you wish to expose that use [UDP](https://en.wikipedia.org/wiki/User_Datagram_Protocol), you need to edit the `/etc/rc.firewall` file:

    sudo vi /etc/rc.firewall

You configured your firewall to use the `"workstation"` firewall type, so look for a section that looks like this:

/etc/rc.firewall

    . . .
    
    [Ww][Oo][Rr][Kk][Ss][Tt][Aa][Tt][Ii][Oo][Nn])
    
    . . .

There is a section within this block that is dedicated to processing the `firewall_allowservices` and `firewall_myservices` values that you set. It will look like this:

/etc/rc.firewall

    for i in ${firewall_allowservices} ; do
      for j in ${firewall_myservices} ; do
        ${fwcmd} add pass tcp from $i to me $j
      done
    done

After this section, you can add any services or ports that should accept UDP packets by adding lines like this:

    ${fwcmd} add pass udp from any to me port_num

In `vi`, press `i` to switch to `INSERT` mode and add your content, then save and close the file by pressing `ESC`, typing `:wq`, and pressing `ENTER`. In the previous example, you can leave the `"any"` keyword if the connection should be allowed for all clients or change it to a specific IP address or network range. The `port_num` should be replaced by the port number or service name you wish to allow UDP access to. For example, if you’re running a DNS server, you may wish to have a line that looks something like this:

    for i in ${firewall_allowservices} ; do
      for j in ${firewall_myservices} ; do
        ${fwcmd} add pass tcp from $i to me $j
      done
    done
    
    ${fwcmd} add pass udp from 192.168.2.0/24 to me 53

This will allow any client from within the `192.168.2.0/24` network range to access a DNS server operating on the standard port `53`. Note that in this example you would also want to open this port up for TCP connections as that is used by DNS servers for longer replies.

Save and close the file when you are finished.

### Starting the Firewall

When you are finished with your configuration, you can start the firewall by typing:

    sudo service ipfw start

The firewall will start correctly, blocking unwanted traffic while adhering to your allowed services and ports. This firewall will start automatically at every boot.

You also want to configure a limit on how many denials per IP address you’ll log. This will prevent your logs from filling up from a single, persistent user. You can do this in the `/etc/sysctl.conf` file:

    sudo vi /etc/sysctl.conf

At the bottom of the file, you can limit your logging to `"5"` by adding the following line:

/etc/sysctl.conf

    ...
    net.inet.ip.fw.verbose_limit=5

Save and close the file when you are finished. This will configure that setting on the next boot.

To implement this same behavior for your currently active session without restarting, you can use the `sysctl` command itself, like this:

    sudo sysctl net.inet.ip.fw.verbose_limit=5

This should immediately implement the limit for this boot.

## How To Set the Time Zone for Your Server

It is a good idea to correctly set the time zone for your server. This is an important step for when you configure NTP time synchronization in the next section.

FreeBSD comes with a menu-based tool called `tzsetup` for configuring time zones. To set the time zone for your server, call this command with `sudo` privileges:

    sudo tzsetup

First, you will be asked to select the region of the world your server is located in:

![FreeBSD region of the world](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_recommended/region.png)

You will need to choose a sub-region or country next:

![FreeBSD country](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_recommended/country.png)

**Note:** To navigate these menus, you’ll need to use the `PAGE UP` and `PAGE DOWN` keys. If you do not have these on your keyboard, you can use `FN` + `DOWN` or `FN` + `UP`.

Finally, select the specific time zone that is appropriate for your server:

![FreeBSD time zone](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_recommended/time.png)

Confirm the time zone selection that is presented based on your choices.

At this point, your server’s time zone should match the selections you made.

## How To Configure NTP to Keep Accurate Time

Now that you have the time zone configured on your server, you can set up NTP, or Network Time Protocol. This will help keep your server’s time in sync with others throughout the world. This is important for time-sensitive client-server interactions as well as accurate logging.

Again, you can enable the NTP service on your server by adjusting the `/etc/rc.conf` file. Run the following command to add the line `ntpd_enable="YES"` to the file:

    sudo sysrc ntpd_enable="YES"

You also need to add a second line that will sync the time on your machine with the remote NTP servers at boot. This is necessary because it allows your server to exceed the normal drift limit on initialization. Your server will likely be outside of the drift limit at boot because your time zone will be applied prior to the NTP daemon starting, which will offset your system time:

    sudo sysrc ntpd_sync_on_start="YES"

If you did not have this line, your NTP daemon would fail when started due to the timezone settings that skew your system time prior in the boot process.

You can start your `ntpd` service by typing:

    sudo service ntpd start

This will maintain your server’s time by synchronizing with the NTP servers listed in `/etc/ntp.conf`.

## How To Configure Extra Swap Space

On FreeBSD servers configured on DigitalOcean, 1 Gigabyte of [swap space](https://www.freebsd.org/doc/handbook/adding-swap-space.html) is automatically configured regardless of the size of your server. You can see this by typing:

    sudo swapinfo -g

It should show something like this:

    OutputDevice 1G-blocks Used Avail Capacity
    /dev/gpt/swapfs 1 0 1 0%

Some users and applications may need more swap space than this. This is accomplished by adding a swap file.

The first thing you need to do is to allocate a chunk of the filesystem for the file you want to use for swap. You’ll use the `truncate` command, which can quickly allocate space on the fly.

We’ll put the swapfile in `/swapfile` for this tutorial but you can put the file anywhere you wish, like `/var/swapfile` for example. This file will provide an additional 1 Gigabyte of swap space. You can adjust this number by modifying the value given to the `-s` option:

    sudo truncate -s 1G /swapfile

After you allocate the space, you need to lock down access to the file. Normal users should not have any access to the file:

    sudo chmod 0600 /swapfile

Next, associate a pseudo-device with your file and configure it to mount at boot by typing:

    echo "md99 none swap sw,file=/swapfile,late 0 0" | sudo tee -a /etc/fstab

This command adds a line that looks like this to the `/etc/fstab` file:

    md99 none swap sw,file=/swapfile,late 0 0

After the line is added to your `/etc/fstab` file, you can activate the swap file for the session by typing:

    sudo swapon -aqL

You can verify that the swap file is now working by using the `swapinfo` command again:

    sudo swapinfo -g

You should see the additional device (`/dev/md99`) associated with your swap file:

    OutputDevice 1G-blocks Used Avail Capacity
    /dev/gpt/swapfs 1 0 1 0%
    /dev/md99 1 0 1 0%
    Total 2 0 2 0%

This swap file will be mounted automatically at each boot.

## Conclusion

The steps outlined in this guide can be used to bring your FreeBSD server into a more production-ready state. By configuring basic essentials like a firewall, NTP synchronization, and appropriate swap space, your server can be used as a good base for future installations and services.
