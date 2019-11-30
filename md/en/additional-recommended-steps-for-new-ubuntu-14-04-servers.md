---
author: Justin Ellingwood
date: 2014-11-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers
---

# Additional Recommended Steps for New Ubuntu 14.04 Servers

## Introduction

After setting up the bare minimum configuration for a new server, there are some additional steps that are highly recommended in most cases. In this guide, we’ll continue the configuration of our servers by tackling some recommended, but optional procedures.

## Prerequisites and Goals

Before you start this guide, you should run through the [Ubuntu 14.04 initial server setup](initial-server-setup-with-ubuntu-14-04) guide. This is necessary in order to set up your user accounts, configure privilege elevation with `sudo`, and lock down SSH for security.

Once you have completed the guide above, you can continue with this article. In this guide, we will be focusing on configuring some optional but recommended components. This will involve setting our system up with a firewall, Network Time Protocol synchronization, and a swap files.

## Configuring a Basic Firewall

Firewalls provide a basic level of security for your server. These applications are responsible for denying traffic to every port on your server with exceptions for ports/services you have approved. Ubuntu ships with a tool called `ufw` that can be used to configure your firewall policies. Our basic strategy will be to lock down everything that we do not have a good reason to keep open.

Before we enable or reload our firewall, we will create the rules that define the exceptions to our policy. First, we need to create an exception for SSH connections so that we can maintain access for remote administration.

The SSH daemon runs on port 22 by default and `ufw` can implement a rule by name if the default has not been changed. So if you have **not** modified SSH port, you can enable the exception by typing:

    sudo ufw allow ssh

If you have modified the port that the SSH daemon is listening on, you will have to allow it by specifying the actual port number, along with the TCP protocol:

    sudo ufw allow 4444/tcp

This is the bare minimum firewall configuration. It will only allow traffic on your SSH port and all other services will be inaccessible. If you plan on running additional services, you will need to open the firewall at each port required.

If you plan on running a conventional HTTP web server, you will need to allow access to port 80:

    sudo ufw allow 80/tcp

If you plan to run a web server with SSL/TLS enabled, you should allow traffic to that port as well:

    sudo ufw allow 443/tcp

If you need SMTP email enabled, port 25 will need to be opened:

    sudo ufw allow 25/tcp

After you’ve finished adding the exceptions, you can review your selections by typing:

    sudo ufw show added

If everything looks good, you can enable the firewall by typing:

    sudo ufw enable

You will be asked to confirm your selection, so type “y” if you wish to continue. This will apply the exceptions you made, block all other traffic, and configure your firewall to start automatically at boot.

Remember that you will have to explicitly open the ports for any additional services that you may configure later. For more in-depth information, check out our article on [configuring the ufw firewall](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server).

## Configure Timezones and Network Time Protocol Synchronization

The next step is to set the localization settings for your server and configure the Network Time Protocol (NTP) synchronization.

The first step will ensure that your server is operating under the correct time zone. The second step will configure your system to synchronize its system clock to the standard time maintained by a global network of NTP servers. This will help prevent some inconsistent behavior that can arise from out-of-sync clocks.

### Configure Timezones

Our first step is to set our server’s timezone. This is a very simple procedure that can be accomplished by reconfiguring the `tzdata` package:

    sudo dpkg-reconfigure tzdata

You will be presented with a menu system that allows you to select the geographic region of your server:

![Ubuntu select region](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/choose_country.png)

After selecting an area, you will have the ability to choose the specific time zone that is appropriate for your server:

![Ubuntu select timezone](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/choose_timezone.png)

Your system will be updated to use the selected timezone, and the results will be printed to the screen:

    Current default time zone: 'America/New_York'
    Local time is now: Mon Nov 3 17:00:11 EST 2014.
    Universal Time is now: Mon Nov 3 22:00:11 UTC 2014.

Next, we will move on to configure NTP.

### Configure NTP Synchronization

Now that you have your timezone set, we should configure NTP. This will allow your computer to stay in sync with other servers, leading to more predictability in operations that rely on having the correct time.

For NTP synchronization, we will use a service called `ntp`, which we can install from Ubuntu’s default repositories:

    sudo apt-get update
    sudo apt-get install ntp

This is all that you have to do to set up NTP synchronization on Ubuntu. The daemon will start automatically each boot and will continuously adjust the system time to be in-line with the global NTP servers throughout the day.

Click here if you wish to learn more about [NTP servers](how-to-set-up-time-synchronization-on-ubuntu-12-04).

## Create a Swap File

Adding “swap” to a Linux server allows the system to move the less frequently accessed information of a running program from RAM to a location on disk. Accessing data stored on disk is much slower than accessing RAM, but having swap available can often be the difference between your application staying alive and crashing. This is especially useful if you plan to host any databases on your system.

Note

Although swap is generally recommended for systems utilizing traditional spinning hard drives, using swap with SSDs can cause issues with hardware degradation over time. Due to this consideration, we do not recommend enabling swap on DigitalOcean or any other provider that utilizes SSD storage. Doing so can impact the reliability of the underlying hardware for you and your neighbors.

If you need to improve the performance of your server, we recommend upgrading your Droplet. This will lead to better results in general and will decrease the likelihood of contributing to hardware issues that can affect your service.

Advice about the best size for a swap space varies significantly depending on the source consulted. Generally, an amount equal to or double the amount of RAM on your system is a good starting point.

Allocate the space you want to use for your swap file using the `fallocate` utility. For example, if we need a 4 Gigabyte file, we can create a swap file located at `/swapfile` by typing:

    sudo fallocate -l 4G /swapfile

After creating the file, we need to restrict access to the file so that other users or processes cannot see what is written there:

    sudo chmod 600 /swapfile

We now have a file with the correct permissions. To tell our system to format the file for swap, we can type:

    sudo mkswap /swapfile

Now, tell the system it can use the swap file by typing:

    sudo swapon /swapfile

Our system is using the swap file for this session, but we need to modify a system file so that our server will do this automatically at boot. You can do this by typing:

    sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

With this addition, your system should use your swap file automatically at each boot.

## Where To Go from Here?

You now have a very decent beginning setup for your Linux server. From here, there are quite a few places you can go. First, you may wish to snapshot your server in its current configuration.

### Take a Snapshot of your Current Configuration

If you are happy with your configuration and wish to use this as a base for future installations, you can take a snapshot of your server through the DigitalOcean control panel. Starting in October of 2016, snapshots cost $0.05 per gigabyte per month, based on the amount of utilized space within the filesystem.

To prepare for the snapshot, shutdown your server from the command line. Although it is possible to take a snapshot of a running system, powering down leads to better guarantees that the filesystem will be consistent:

    sudo poweroff

Now, in the DigitalOcean control panel, you can take a snapshot by visiting the “Snapshots” tab of your server:

![DigitalOcean snapshot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/snapshots.png)

After taking your snapshot, you will be able to use that image as a base for future installations by selecting the snapshot from the “My Snapshots” tab for images during the creation process:

![DigitalOcean use snapshot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/use_snapshot.png)

### Additional Resources and Next Steps

From here, your path depends entirely on what you wish to do with your server. The list of guides below is in no way exhaustive, but represents some of the more common configurations that users turn to next:

- [Setting up a LAMP (Linux, Apache, MySQL/MariaDB, PHP) stack](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04)
- [Setting up a LEMP (Linux, Nginx, MySQL/MariaDB, PHP) stack](how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04)
- [Installing the WordPress CMS on an Apache web server](how-to-install-wordpress-on-ubuntu-14-04)
- [Installing the WordPress CMS on an Nginx web server](how-to-install-wordpress-with-nginx-on-ubuntu-14-04)
- [Installing the Drupal CMS on an Apache web server](how-to-install-drupal-on-an-ubuntu-14-04-server-with-apache)
- [Installing Node.js](how-to-install-node-js-on-an-ubuntu-14-04-server)
- [Installing Ruby on Rails and RVM](how-to-install-ruby-on-rails-on-ubuntu-14-04-using-rvm)
- [Installing Laravel, a PHP framework](how-to-install-laravel-with-an-nginx-web-server-on-ubuntu-14-04)
- [Installing Puppet to manage your infrastructure](how-to-install-puppet-to-manage-your-server-infrastructure)

## Conclusion

By this point, you should know how to configure a solid foundation for your new servers. Hopefully, you also have a good idea for your next steps. Feel free to explore the site for more ideas that you can implement on your server.
