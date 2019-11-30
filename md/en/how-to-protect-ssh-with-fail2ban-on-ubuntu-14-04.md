---
author: Justin Ellingwood
date: 2014-05-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04
---

# How To Protect SSH with Fail2Ban on Ubuntu 14.04

## Introduction

While connecting to your server through SSH can be very secure, the SSH daemon itself is a service that must be exposed to the internet to function properly. This comes with some inherent risk and creates a vector of attack for would-be assailants.

Any service that is exposed to the network is a potential target in this way. If you pay attention to application logs for these services, you will often see repeated, systematic login attempts that represent brute force attacks by users and bots alike.

A service called **fail2ban** can mitigate this problem by creating rules that can automatically alter your `iptables` firewall configuration based on a predefined number of unsuccessful login attempts. This will allow your server to respond to illegitimate access attempts without intervention from you.

In this guide, we’ll cover how to install and use fail2ban on an Ubuntu 14.04 server.

## Install Fail2Ban on Ubuntu 14.04

The installation process for this tool is simple because the Ubuntu packaging team maintains a package in the default repositories.

First, we need to update our local package index and then we can use `apt` to download and install the package:

    sudo apt-get update
    sudo apt-get install fail2ban

As you can see, the installation is trivial. We can now begin configuring the utility for our own use.

## Configure Fail2Ban with your Service Settings

The fail2ban service keeps its configuration files in the `/etc/fail2ban` directory. There is a file with defaults called `jail.conf`.

Since this file can be modified by package upgrades, we should not edit this file in-place, but rather copy it so that we can make our changes safely. In order for these two files to operate together successfully, it is best to only include the settings you wish to override in the `jail.local` file. All default options will be taken from the `jail.conf` file.

Even though we should only include deviations from the default in the `jail.local` file, it is easier to create a `jail.local` file based on the existing `jail.conf` file. So we will copy over that file, with the contents commented out, as the basis for the `jail.local` file. You can do this by typing:

    awk '{ printf "# "; print; }' /etc/fail2ban/jail.conf | sudo tee /etc/fail2ban/jail.local

Once the file is copied, we can open the original `jail.conf` file to see how things are set up by default

    sudo nano /etc/fail2ban/jail.conf

In this file, there are a few settings you may wish to adjust. The settings located under the `[DEFAULT]` section will be applied to all services enabled for fail2ban that are not overridden in the service’s own section.

/etc/fail2ban/jail.conf

    [DEFAULT]
    . . .
    ignoreip = 127.0.0.1/8
    . . .

The `ignoreip` setting configures the source addresses that fail2ban ignores. By default, it is configured to not ban any traffic coming from the local machine. You could add additional addresses to ignore by adding a `[DEFAULT]` section with an `ignoreip` setting under it to the `jail.local` file. You can add additional addresses by appending them to the end of the directive, separated by a space.

/etc/fail2ban/jail.conf

    [DEFAULT]
    . . .
    bantime = 600
    . . .

The `bantime` parameter sets length of time that a client will be banned when they have failed to authenticate correctly. This is measured in seconds. By default, this is set to 600 seconds, or 10 minutes.

/etc/fail2ban/jail.conf

    [DEFAULT]
    . . .
    findtime = 600
    maxretry = 3
    . . .

The next two parameters that you want to pay attention to are `findtime` and `maxretry`. These work together to establish the conditions under which a client is found to be an illegitimate user that should be banned.

The `maxretry` variable sets the number of tries a client has to authenticate within a window of time defined by `findtime`, before being banned. With the default settings, the fail2ban service will ban a client that unsuccessfully attempts to log in 3 times within a 10 minute window.

/etc/fail2ban/jail.conf

    [DEFAULT]
    . . .
    destemail = root@localhost
    sendername = Fail2Ban
    mta = sendmail
    . . .

You will want to evaluate the `destemail`, `sendername`, and `mta` settings if you wish to configure email alerts. The `destemail` parameter sets the email address that should receive ban messages. The `sendername` sets the value of the “From” field in the email. The `mta` parameter configures what mail service will be used to send mail. Again, add these to the `jail.local` file, under the `[DEFAULT]` header and set to the proper values if you wish to adjust them.

/etc/fail2ban/jail.conf

    [DEFAULT]
    . . .
    action = $(action_)s
    . . .

This parameter configures the action that fail2ban takes when it wants to institute a ban. The value `action_` is defined in the file shortly before this parameter. The default action is to simply configure the firewall to reject traffic from the offending host until the ban time elapses.

If you would like to configure email alerts, add or uncomment the `action` item to the `jail.local` file and change its value from `action_` to `action_mw`. If you want the email to include the relevant log lines, you can change it to `action_mwl`. Make sure you have the appropriate mail settings configured if you choose to use mail alerts.

### Individual Jail Settings

Finally, we get to the portion of the configuration file that deals with individual services. These are specified by the section headers, like `[ssh]`.

Each of these sections can be enabled by uncommenting the header in `jail.local` and changing the `enabled` line to be “true”:

/etc/fail2ban/jail.local

    [jail_to_enable]
    . . .
    enabled = true
    . . .

By default, the SSH service is enabled and all others are disabled.

These sections work by using the values set in the `[DEFAULT]` section as a basis and modifying them as needed. If you want to override any values, you can do so by adding the appropriate service’s section to `jail.local` and modifying its values.

Some other settings that are set here are the `filter` that will be used to decide whether a line in a log indicates a failed authentication and the `logpath` which tells fail2ban where the logs for that particular service are located.

The `filter` value is actually a reference to a file located in the `/etc/fail2ban/filter.d` directory, with its `.conf` extension removed. These files contain the regular expressions that determine whether a line in the log is a failed authentication attempt. We won’t be covering these files in-depth in this guide, because they are fairly complex and the predefined settings match appropriate lines well.

However, you can see what kind of filters are available by looking into that directory:

    ls /etc/fail2ban/filter.d

If you see a file that looks to be related to a service you are using, you should open it with a text editor. Most of the files are fairly well commented and you should be able to at least tell what type of condition the script was designed to guard against. Most of these filters have appropriate (disabled) sections in the `jail.conf` file that we can enable in the `jail.local` file if desired.

For instance, pretend that we are serving a website using Nginx and realize that a password-protected portion of our site is getting slammed with login attempts. We can tell fail2ban to use the `nginx-http-auth.conf` file to check for this condition within the `/var/log/nginx/error.log` file.

This is actually already set up in a section called `[nginx-http-auth]` in our `/etc/fail2ban/jail.conf` file. We would just need to uncomment the section in the `jail.local` file and flip the `enabled` parameter to protect our service:

/etc/fail2ban/jail.local

    . . .
    [nginx-http-auth]
    
    enabled = true
    . . .

If you enable this, you’ll want to restart your fail2ban service to make sure your rules are constructed correctly.

## Putting It All Together

Now that you understand the basic idea behind fail2ban, let’s run through a basic setup.

We’re going to configure a auto-banning policy for SSH and Nginx, just as we described above. We want fail2ban to email us when an IP is banned.

First, let’s install all of the relevant software.

If you don’t already have it, you’ll need nginx, since we’re going to be monitoring its logs, and you’ll need sendmail to mail us notifications. We’ll also grab `iptables-persistent` to allow the server to automatically set up our firewall rules at boot. These can be acquired from Ubuntu’s default repositories:

    sudo apt-get update
    sudo apt-get install nginx sendmail iptables-persistent

Stop the `fail2ban` service for a moment so that we can establish a base firewall without the rules it adds:

    sudo service fail2ban stop

### Establish a Base Firewall

When that is finished, we should implement a default firewall. You can learn [how to configure an iptables firewall on Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04) here. We are going to just create a basic firewall for this guide.

We’re going to tell it to allow established connections, traffic generated by the server itself, traffic destined for our SSH and web server ports. We will drop all other traffic. We can set this basic firewall up by typing:

    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
    sudo iptables -A INPUT -j DROP

These commands will implement the above policy. We can see our current firewall rules by typing:

    sudo iptables -S

    Output-P INPUT ACCEPT
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    -A INPUT -j DROP

You can save the firewalls so that they survive a reboot by typing:

    sudo dpkg-reconfigure iptables-persistent

Afterwards, you can restart `fail2ban` to implement the wrapping rules:

    sudo service fail2ban start

We can see our current firewall rules by typing:

    sudo iptables -S

    Output-P INPUT ACCEPT
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -N fail2ban-ssh
    -A INPUT -p tcp -m multiport --dports 22 -j fail2ban-ssh
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    -A INPUT -j DROP
    -A fail2ban-ssh -j RETURN

We have our default policy for each of our chains, and then the five base rules that we established. In red, we also have the default structure set up by fail2ban since it already implements SSH banning policies by default. These may or may not show up at first, since sometimes `fail2ban` does not add the structure until the first ban is implemented.

### Adjusting the Fail2ban Configuration

Now, we need to configure fail2ban using the settings we’d like. Open the `jail.local` file:

    sudo nano /etc/fail2ban/jail.local

We can set a more severe ban time here. Find and uncomment the `[DEFAULT]` heading. Under the default heading, change the `bantime` setting so that our service bans clients for half an hour:

/etc/fail2ban/jail.local

    [DEFAULT]
    . . .
    bantime = 1800
    . . .

We also need to configure our alert email information. First, find the `destemail` parameter, which should also be under the `[DEFAULT]` heading. Put in the email address that you want to use to collect these messages:

/etc/fail2ban/jail.local

    [DEFAULT]
    . . .
    destemail = admin@example.com
    . . .

You can set the `sendername` to something else if you’d like. It’s useful to have a value that can be easily filtered using your mail service though, or else your regular inbox may get flooded with alerts if there are a lot of break in attempts from various places.

Moving down, we need to adjust the `action` parameter to one of the actions that sends us email. The choices are between `action_mw` which institutes the ban and then emails us a “whois” report on the offending host, or `action_mwl` which does the above, but also emails the relevant log lines.

We’re going to choose `action_mwl` because the log lines will help us troubleshoot and gather more information if there are issues:

/etc/fail2ban/jail.local

    [DEFAULT]
    . . .
    action = %(action_mwl)s
    . . .

Moving on to our SSH section, if we want to adjust the amount of unsuccessful attempts that should be allowed before a ban is established, you can edit the `maxretry` entry. If you are using a port other than “22”, you’ll want to adjust the `port` parameter appropriately. As we said before, this service is already enabled, so we don’t need to modify that.

Next, search for the `nginx-http-auth` section. Uncomment the header and change the `enabled` parameter to read “true”.

/etc/fail2ban/jail.local

    . . .
    [nginx-http-auth]
    
    enabled = true
    . . .

This should be all you have to do this section unless your web server is operating on non-standard ports or if you moved the default error log path.

### Restarting the Fail2ban Service

When you are finished, save and close the file.

Now, start or restart your fail2ban service. Sometimes, it’s better to completely shut down the service and then start it again:

    sudo service fail2ban stop

Now we can restart it by typing:

    sudo service fail2ban start

It may take a few moments for all of your firewall rules to be populated. Sometimes, the rules are not added until the first ban of that type is instituted. However, after a time, you can check the new rules by typing:

    sudo iptables -S

    Output-P INPUT ACCEPT
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -N fail2ban-nginx-http-auth
    -N fail2ban-ssh
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-nginx-http-auth
    -A INPUT -p tcp -m multiport --dports 22 -j fail2ban-ssh
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    -A INPUT -j DROP
    -A fail2ban-nginx-http-auth -j RETURN
    -A fail2ban-ssh -j RETURN

The lines in red are the ones that our fail2ban policies have created. Right now, they are just directing traffic to new, almost empty chains and then letting the traffic flow right back into the INPUT chain.

However, these new chains are where the banning rules will be added.

### Testing the Banning Policies

From another server, one that won’t need to log into your fail2ban server with, we can test the rules by getting our second server banned.

After logging into your second server, try to SSH into the fail2ban server. You can try to connect using a non-existent name for instance:

    ssh blah@fail2ban_server_IP

Enter random characters into the password prompt. Repeat this a few times. At some point, the fail2ban server will stop responding with the `Permission denied` message. This signals that your second server has been banned from the fail2ban server.

On your fail2ban server, you can see the new rule by checking our iptables again:

    sudo iptables -S

    Output-P INPUT ACCEPT
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -N fail2ban-nginx-http-auth
    -N fail2ban-ssh
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-nginx-http-auth
    -A INPUT -p tcp -m multiport --dports 22 -j fail2ban-ssh
    -A INPUT -i lo -j ACCEPT
    -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    -A INPUT -j DROP
    -A fail2ban-nginx-http-auth -j RETURN
    -A fail2ban-ssh -s 203.0.113.14/32 -j REJECT --reject-with icmp-port-unreachable
    -A fail2ban-ssh -j RETURN

As you can see in the highlighted line, we have a new rule in our configuration which rejects traffic to the SSH port coming from our second server’s IP address. You should have also gotten an email about the ban in the account you configured.

## Conclusion

You should now be able to configure some basic banning policies for your services. Fail2ban is very easy to set up, and is a great way to protect any kind of service that uses authentication.

If you want to learn more about how fail2ban works, you can check out our tutorial on [how fail2ban rules and files work](https://www.digitalocean.com/community/articles/how-fail2ban-works-to-protect-services-on-a-linux-server).

For information about how to use fail2ban to protect other services, try these links:

- [How To Protect an Nginx Server with Fail2Ban on Ubuntu 14.04](how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04)
- [How To Protect an Apache Server with Fail2Ban on Ubuntu 14.04](how-to-protect-an-apache-server-with-fail2ban-on-ubuntu-14-04)
