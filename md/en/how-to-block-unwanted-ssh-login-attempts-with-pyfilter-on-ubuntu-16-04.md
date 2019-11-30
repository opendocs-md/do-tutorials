---
author: Jason Hall
date: 2018-03-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-block-unwanted-ssh-login-attempts-with-pyfilter-on-ubuntu-16-04
---

# How to Block Unwanted SSH Login Attempts with PyFilter on Ubuntu 16.04

_The author selected [Code.org](https://www.brightfunds.org/organizations/code-org) to receive a $200 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Secure Shell (SSH) is a cryptographic network protocol for operating network services securely. It’s typically used for remote control of a computer system or for transferring files. When SSH is exposed to the public internet, it becomes a security concern. For example, you’ll find bots attempting to guess your password via brute force methods.

[PyFilter](https://pyfilter.co.uk/) aims to filter out all of the illegitimate login requests to your server and block them if too many are sent. It works by reading log files and checking if a failed request has came from the same IP address within a user-configurable amount of time. It then adds rules to the firewall if it captures too many failed attempts, denying the ability to connect to your server.

In this tutorial, you’ll install and configure PyFilter to block SSH requests. Then you’ll install PyFilter as a service, and optionally configure cross-server ban syncing, a feature that lets multiple servers share the list of banned IP addresses, and enable PyFilter to record location data about an IP address. Finally, you’ll explore how to un-ban IP addresses.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- Python 3, which is already installed by default on Ubuntu 16.04.
- PIP installed with `sudo apt-get install python3-pip`.
- (Optional) Redis installed by following [How to Install Redis on Ubuntu 16.04](how-to-install-and-configure-redis-on-ubuntu-16-04) if you wish to configure PyFilter’s cross server ban syncing feature in Step 4.

## Step 1 — Downloading and Configuring PyFilter

We will download PyFilter by cloning its repository from Github. Switch to your home directory and clone the repository:

    cd ~
    git clone https://github.com/Jason2605/PyFilter.git

This will create a directory called `PyFilter`. Move this folder to the `/usr/local` folder:

    sudo mv PyFilter /usr/local/PyFilter

Then change to the `/usr/local/PyFilter` directory:

    cd /usr/local/PyFilter

Next, we need to make a configuration file. PyFilter comes with a default configuration file located at `Config/config.default.json`. We’ll copy this and edit the copied version rather than editing the default file directly. This way if something was to go wrong, you have the default config file to compare against.

Copy the default configuration file:

    sudo cp Config/config.default.json Config/config.json

You can use the `less` command to view the contents of the configuration file:

    less Config/config.json

The defaults settings require the requests to be within 5 seconds of the last request and that needs to happen 5 times, they are good enough to get going. Let’s run PyFilter and ensure things work.

## Step 2 — Running PyFilter

The PyFilter download includes a script called `run.sh` which you should use to launch PyFilter.

First, change the permissions on the script to make it executable.

    sudo chmod +x run.sh

Once the permissions have been granted, run the script to start PyFilter:

    ./run.sh

PyFilter will start watching logs and you will see output as events happen:

    OutputNo file to check within rule: Mysql
    No file to check within rule: Apache
    No file to check within rule: Nginx
    Checking Ssh logs

By default, PyFilter bans IPs that make five or more failed requests that happen within 5 seconds of the previous failed request. You can change this in the PyFilter configuration file.

These results are logged to the `/usr/local/PyFilter/Log` directory as well.

When an IP has reached the limits that warrant a ban, you will see output similar to this:

    Output2018-03-22 14:18:18 Found IP: 203.0.113.13 from server: your_server_name.

**Note** : If you accidentally lock yourself out of your Droplet because you’ve banned yourself, you can follow the tutorial [How To Use the DigitalOcean Console to Access your Droplet](how-to-use-the-digitalocean-console-to-access-your-droplet) to get back in. Then follow the steps in Step 6 to remove the banned IP.

To close PyFilter, press `CTRL+C`.

Now let’s install PyFilter as a service so it runs automatically.

## Step 3 — Creating a service for PyFilter

Now that you know that PyFilter works, let’s configure it to run as a service so it starts every time we reboot the server.

Within the `PyFilter` directory, there is a script called `install.sh` which creates a service for PyFilter and enables it to run on system startup.

Modify the script so you can execute it:

    sudo chmod +x install.sh

Then launch the script:

    ./install.sh

You’ll see this output, indicating the installation was successful:

    OutputService created and enabled, check the status of it by using "sudo systemctl status PyFilter"

So lets do just that to ensure everything is running correctly:

    sudo systemctl status PyFilter

You’ll see this output, showing that the service is `active`:

    Output● PyFilter.service - PyFilter
       Loaded: loaded (/etc/systemd/system/PyFilter.service; enabled; vendor preset: enabled)
       Active: <^>active^> (running) since Wed 2018-03-21 18:55:35 UTC; 12s ago
     Main PID: 8383 (bash)
       CGroup: /system.slice/PyFilter.service
               ├─8383 bash /usr/local/PyFilter/run.sh
               ├─8384 sudo python3 run.py
               └─8387 python3 run.py

If you see an error, review the installation steps again.

Next, let’s look at how to configure PyFilter to share banned IP addresses with other servers.

## Step 4 — Configuring PyFilter for Cross Server Ban Syncing (Optional)

Cross server ban syncing allows the banned IP address to be synced with all the other servers using PyFilter to protect them, and ban that address even if it has not fulfilled the qualifications to be banned. This means it can be one step ahead of potential bots targeting your other systems as the IP is already banned.

As stated in the prerequisites, you’ll need Redis installed and configured.

You also need the `redis` Python module, which you can install with `pip`:

    pip3 install redis

Then edit your configuration file to use Redis instead of SQLite. Open the `Config/config.json` file in your text editor:

    nano Config/config.json

Locate the following line:

Config/config.json

    "database": "sqlite"

Change `sqlite` to `redis`:

Config/config.json

    "database": "redis"

Next, change the Redis connection information. Locate this section of the file:

Config/config.json

      "redis": {
        "host": "127.0.0.1",
        "password": null,
        "database": 0,
        "sync_bans": {
          "active": true,
          "name": "your_hostname",
          "check_time": 600
        }
      },

Modify this section so it includes the connection details for your Redis server. Then, within the `sync_bans` section, change the `name` to your host name. This name has to be unique for each individual system running PyFilter using the same Redis server in order for the cross-server ban sync to work correctly.

Save the file and exit the editor. Then restart PyFilter to apply these changes:

    sudo systemctl restart PyFilter

PyFilter is now installed and running.

## Step 5 — Configuring PyFilter to Gather Location Data About IP Addresses (Optional)

PyFilter can retrieve location data about the banned IP in order to provide statistical information about where the majority of attacks are coming from. This optional module will append this information to PyFilter’s logs.

To use this feature, you first need the `geoip2` Python module, which you can install with `pip`:

    pip3 install geoip2

Once you have installed this module, restart PyFilter for it to recognize the new module:

    sudo systemctl restart PyFilter

Now, when you see a banned IP address, you’ll see additional information about the IP:

    Output2018-03-22 14:18:18 Found IP: 203.0.113.13 from server: your_server_name. The IP was from United Kingdom.

PyFilter is now successfully logging which country the requests are originating from.

Finally, let’s look at how to un-ban an address.

## Step 6 — Un-banning IP Addresses

PyFilter is purely a means of banning IP addresses by creating iptables rules. When it bans an IP, it updates the firewall rules and then saves snapshots of the rules to the files `/usr/local/PyFilter/Config/blacklist.v4` and `/usr/local/PyFilter/Config/blacklist.v6`.

Here’s an example of several banned IPv4 addresses in `/usr/local/PyFilter/Config/blacklist.v4`:

/usr/local/PyFilter/Config/blacklist.v4

    # Generated by iptables-save v1.6.0 on Thu Mar 22 19:53:04 2018
    *filter
    :INPUT ACCEPT [217:30580]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [249:30796]
    -A INPUT -s 203.0.113.13/32 -j DROP
    -A INPUT -s 203.0.113.14/32 -j DROP
    -A INPUT -s 203.0.113.15/32 -j DROP
    COMMIT
    # Completed on Thu Mar 22 19:53:04 2018

To un-ban this IP address, open the associated blacklist file in your text editor:

    sudo nano /usr/local/PyFilter/Config/blacklist.v4

Remove the associated iptables rules from the file. In this case, we’ve removed `203.0.113.13` from the file:

/usr/local/PyFilter/Config/blacklist.v4

    # Generated by iptables-save v1.6.0 on Thu Mar 22 19:53:04 2018
    *filter
    :INPUT ACCEPT [217:30580]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [249:30796]
    -A INPUT -s 203.0.113.14/32 -j DROP
    -A INPUT -s 203.0.113.15/32 -j DROP
    COMMIT
    # Completed on Thu Mar 22 19:53:04 2018

Then save the file and close the editor. Restart PyFilter with `sudo systemctl restart PyFilter` and PyFilter will update your firewall rules using this file.

See [How To List and Delete Iptables Firewall Rules](how-to-list-and-delete-iptables-firewall-rules) for more on managing rules with iptables.

You can also tell PyFilter to ignore certain IP addresses by adding them to the whitelisted section within the `/usr/local/PyFilter/Config/config.json` file.

## Conclusion

You now have PyFilter installed and monitoring your SSH connections.

To find out more about each section of the config file and how to configure monitoring for other services, such as MySQL and Apache, check the [PyFilter site.](http://pyfilter.co.uk).
