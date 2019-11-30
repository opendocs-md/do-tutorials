---
author: Justin Ellingwood
date: 2015-08-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-protect-an-apache-server-with-fail2ban-on-ubuntu-14-04
---

# How To Protect an Apache Server with Fail2Ban on Ubuntu 14.04

## Introduction

When operating a web server, it is important to implement security measures to protect your site and users. Protecting your web sites and applications with firewall policies and restricting access to certain areas with password authentication is a great starting point to securing your system. However, any publicly accessible password prompt is likely to attract brute force attempts from malicious users and bots.

Setting up `fail2ban` can help alleviate this problem. When users repeatedly fail to authenticate to a service (or engage in other suspicious activity), `fail2ban` can issue a temporary bans on the offending IP address by dynamically modifying the running firewall policy. Each `fail2ban` “jail” operates by checking the logs written by a service for patterns which indicate failed attempts. Setting up `fail2ban` to monitor Apache logs is easy using the included configuration filters.

In this guide, we will demonstrate how to install `fail2ban` and configure it to monitor your Apache logs for intrusion attempts. We will use an Ubuntu 14.04 server.

## Prerequisites

Before you begin, you should have an Ubuntu 14.04 server set up with a non-root account. This account should be configured with `sudo` privileges in order to issue administrative commands. To learn how to set up a user with `sudo` privileges, follow our [initial server setup guide for Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04).

## Installing Apache and Configuring Password Authentication

If you are interested in protecting your Apache server with `fail2ban`, you might already have a server set up and running. If not, you can install Apache from Ubuntu’s default repositories using `apt`.

Update the local package index and install by typing:

    sudo apt-get update
    sudo apt-get install apache2

The `fail2ban` service is useful for protecting login entry points. In order for this to be useful for an Apache installation, password authentication must be implemented for at least a subset of the content on the server. You can follow [this guide](how-to-set-up-password-authentication-with-apache-on-ubuntu-14-04) to configure password protection for your Apache server.

## Install Fail2Ban

Once your Apache server is running and password authentication is enabled, you can go ahead and install `fail2ban` (we include another repository re-fetch here in case you already had Apache set up in the previous steps):

    sudo apt-get update
    sudo apt-get install fail2ban

This will install the software. By default, `fail2ban` is configured to only ban failed SSH login attempts. We need to enable some rules that will configure it to check our Apache logs for patterns that indicate malicious activity.

## Adjusting the General Settings within Fail2Ban

To get started, we need to adjust the configuration file that `fail2ban` uses to determine what application logs to monitor and what actions to take when offending entries are found. The supplied `/etc/fail2ban/jail.conf` file is the main provided resource for this.

To make modifications, we need to copy this file to `/etc/fail2ban/jail.local`. This will prevent our changes from being overwritten if a package update provides a new default file:

    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

Open the newly copied file so that we can set up our Apache log monitoring:

    sudo nano /etc/fail2ban/jail.local

### Changing Defaults

We should start by evaluating the defaults set within the file to see if they suit our needs. These will be found under the `[DEFAULT]` section within the file. These items set the general policy and can each be overridden in specific jails.

One of the first items to look at is the list of clients that are not subject to the `fail2ban` policies. This is set by the `ignoreip` directive. It is sometimes a good idea to add your own IP address or network to the list of exceptions to avoid locking yourself out. This is less of an issue with web server logins though if you are able to maintain shell access, since you can always manually reverse the ban. You can add additional IP addresses or networks delimited by a space, to the existing list:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    ignoreip = 127.0.0.1/8 your_home_IP

Another item that you may want to adjust is the `bantime`, which controls how many seconds an offending member is banned for. It is ideal to set this to a long enough time to be disruptive to a malicious actor’s efforts, while short enough to allow legitimate users to rectify mistakes. By default, this is set to 600 seconds (10 minutes). Increase or decrease this value as you see fit:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    bantime = 3600

The next two items determine the scope of log lines used to determine an offending client. The `findtime` specifies an amount of time in seconds and the `maxretry` directive indicates the number of attempts to be tolerated within that time. If a client makes more than `maxretry` attempts within the amount of time set by `findtime`, they will be banned:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    findtime = 3600 # These lines combine to ban clients that fail
    maxretry = 6 # to authenticate 6 times within a half hour.

### Setting Up Mail Notifications (Optional)

You can enable email notifications if you wish to receive mail whenever a ban takes place. To do so, you will have to first set up an MTA on your server so that it can send out email. To learn how to use Postfix for this task, follow [this guide](how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-14-04).

Once you have your MTA set up, you will have to adjust some additional settings within the `[DEFAULT]` section of the `/etc/fail2ban/jail.local` file. Start by setting the `mta` directive. If you set up Postfix, like the above tutorial demonstrates, change this value to “mail”:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    mta = mail

You need to select the email address that will be sent notifications. Modify the `destemail` directive with this value. The `sendername` directive can be used to modify the “Sender” field in the notification emails:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    destemail = youraccount@email.com
    sendername = Fail2BanAlerts

In `fail2ban` parlance, an “action” is the procedure followed when a client fails authentication too many times. The default action (called `action_`) is to simply ban the IP address from the port in question. However, there are two other pre-made actions that can be used if you have mail set up.

You can use the `action_mw` action to ban the client and send an email notification to your configured account with a “whois” report on the offending address. You could also use the `action_mwl` action, which does the same thing, but also includes the offending log lines that triggered the ban:

/etc/fail2ban/jail.local

    [DEFAULT]
    
    . . .
    action = %(action_mwl)s

## Configuring Fail2Ban to Monitor Apache Logs

Now that you have some of the general `fail2ban` settings in place, we can concentrate on enabling the Apache-specific jails that will monitor our web server logs for specific behavior patterns.

Each jail within the configuration file is marked by a header containing the jail name in square brackets (every section but the `[DEFAULT]` section indicates a specific jail’s configuration). By default, only the `[ssh]` jail is enabled.

To enable log monitoring for Apache login attempts, we will enable the `[apache]` jail. Edit the `enabled` directive within this section so that it reads “true”:

/etc/fail2ban/jail.local

    [apache]
    
    enabled = true
    port = http,https
    filter = apache-auth
    logpath = /var/log/apache*/*error.log
    maxretry = 6
    . . .

If your Apache server is writing to the default log location (`/var/log/apache/error.log`) the jail is already configured to look in the correct place. If you are logging to a different location, modify the `logpath` as needed. Also, feel free to adjust the `maxretry` directive or add a `findtime` value for this jail if you wish to set different restrictions for this specific jail:

/etc/fail2ban/jail.local

    [apache]
    
    enabled = true
    port = http,https
    filter = apache-auth
    logpath = /var/log/apache/custom_log_location.log
    maxretry = 3
    findtime = 600
    . . .

The above jail will take care of banning basic authentication failures. There are also some other pre-configured jails that are worth enabling (the `[apache-multiport]` jail is a legacy jail that is not needed).

The `[apache-noscript]` jail is used to ban clients that are searching for scripts on the website to execute and exploit. If you do not use PHP or any other language in conjunction with your web server, you can enable this jail to ban those who request these types of resources:

/etc/fail2ban/jail.local

    [apache-noscript]
    
    enabled = true
    . . .

The `[apache-overflows]` jail is used to block clients who are attempting to request unusually long and suspicious URLs. These are often signs of attempts to exploit Apache by trying to trigger a buffer overflow. You can enable this jail if you wish to prevent these types of attacks:

/etc/fail2ban/jail.local

    [apache-overflows]
    
    enabled = true
    . . .

Some additional checks can be made by copying and pasting the `[apache-overflows]` entry and modifying it slightly. For instance, you can copy and paste that section and modify the jail name and filter to `apache-badbots` to stop some known malicious bot request patterns:

/etc/fail2ban/jail.local

    [apache-overflows]
    
    enabled = true
    port = http,https
    filter = apache-overflows
    logpath = /var/log/apache*/*error.log
    maxretry = 2
    
    [apache-badbots]
    
    enabled = true
    port = http,https
    filter = apache-badbots
    logpath = /var/log/apache*/*error.log
    maxretry = 2

If you do not use Apache to provide access to web content within users’ home directories, you can copy and paste again and change the jail and filter names to `apache-nohome`:

/etc/fail2ban/jail.local

    [apache-overflows]
    
    enabled = true
    port = http,https
    filter = apache-overflows
    logpath = /var/log/apache*/*error.log
    maxretry = 2
    
    [apache-badbots]
    
    enabled = true
    port = http,https
    filter = apache-badbots
    logpath = /var/log/apache*/*error.log
    maxretry = 2
    
    [apache-nohome]
    
    enabled = true
    port = http,https
    filter = apache-nohome
    logpath = /var/log/apache*/*error.log
    maxretry = 2

Lastly, if you are using Apache with PHP, you may want to enable the `[php-url-fopen]` jail, which blocks attempts to use certain PHP behavior for malicious purposes. You will likely have to change the `logpath` directive to point the correct access log location (on Ubuntu, the default location is `/var/log/apache2/access.log`). You can use a pattern similar to the one that matches the error log in the other jails:

/etc/fail2ban/jail.local

    [php-url-fopen]
    
    enabled = true
    port = http,https
    filter = php-url-fopen
    logpath = /var/log/apache*/*access.log

When you are finished making the modifications you need, save and close the file.

## Implementing your Apache Jails

To implement your configuration changes, you’ll need to restart the `fail2ban` service. You can do that by typing:

    sudo service fail2ban restart

The service should restart, implementing the different banning policies you’ve configured.

## Getting Info About Enabled Jails

You can see all of your enabled jails by using the `fail2ban-client` command:

    sudo fail2ban-client status

You should see a list of all of the jails you enabled:

    OutputStatus
    |- Number of jail: 7
    `- Jail list: php-url-fopen, apache-overflows, apache-noscript, ssh, apache-badbots, apache-nohome, apache

You can see that `fail2ban` has modified your firewall rules to create a framework for banning clients. Even with no previous firewall rules, you would now have a framework enabled that allows `fail2ban` to selectively ban clients by adding them to purpose-built chains:

    sudo iptables -S

    Output-P INPUT ACCEPT
    -P FORWARD ACCEPT
    -P OUTPUT ACCEPT
    -N fail2ban-apache
    -N fail2ban-apache-badbots
    -N fail2ban-apache-nohome
    -N fail2ban-apache-noscript
    -N fail2ban-apache-overflows
    -N fail2ban-php-url-fopen
    -N fail2ban-ssh
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-apache-nohome
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-apache-badbots
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-php-url-fopen
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-apache-overflows
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-apache-noscript
    -A INPUT -p tcp -m multiport --dports 80,443 -j fail2ban-apache
    -A INPUT -p tcp -m multiport --dports 22 -j fail2ban-ssh
    -A fail2ban-apache -j RETURN
    -A fail2ban-apache-badbots -j RETURN
    -A fail2ban-apache-nohome -j RETURN
    -A fail2ban-apache-noscript -j RETURN
    -A fail2ban-apache-overflows -j RETURN
    -A fail2ban-php-url-fopen -j RETURN
    -A fail2ban-ssh -j RETURN

If you want to see the details of the bans being enforced by any one jail, it is probably easier to use the `fail2ban-client` again:

    sudo fail2ban-client status apache

    OutputStatus for the jail: apache
    |- filter
    | |- File list: /var/log/apache2/error.log 
    | |- Currently failed: 0
    | `- Total failed: 0
    `- action
       |- Currently banned: 0
       | `- IP list:
       `- Total banned: 0

## Testing Fail2Ban Policies

It is important to test your `fail2ban` policies to ensure they block traffic as expected. For instance, for the Apache authentication prompt, you can give incorrect credentials a number of times. After you have surpassed the limit, you should be banned and unable to access the site. If you set up email notifications, you should see messages regarding the ban in the email account you provided.

If you look at the status with the `fail2ban-client` command, you will see your IP address being banned from the site:

    sudo fail2ban-client status apache

    OutputStatus for the jail: apache
    |- filter
    | |- File list: /var/log/apache2/error.log 
    | |- Currently failed: 0
    | `- Total failed: 12
    `- action
       |- Currently banned: 1
       | `- IP list: 111.111.111.111
       `- Total banned: 1

When you are satisfied that your rules are working, you can manually un-ban your IP address with the `fail2ban-client` by typing:

    sudo fail2ban-client set apache unbanip 111.111.111.111

You should now be able to attempt authentication again.

## Conclusion

Setting up `fail2ban` to protect your Apache server is fairly straight forward in the simplest case. However, `fail2ban` provides a great deal of flexibility to construct policies that will suit your specific security needs. By taking a look at the variables and patterns within the `/etc/fail2ban/jail.local` file, and the files it depends on within the `/etc/fail2ban/filter.d` and `/etc/fail2ban/action.d` directories, you can find many pieces to tweak and change as your needs evolve. Learning the basics of how to protect your server with `fail2ban` can provide you with a great deal of security with minimal effort.

To learn more about `fail2ban`, take a look at some of these links:

- [How Fail2Ban Works to Protect Services on a Linux Server](how-fail2ban-works-to-protect-services-on-a-linux-server)
- [How To Protect SSH with Fail2Ban on Ubuntu 14.04](how-to-protect-ssh-with-fail2ban-on-ubuntu-14-04)
- [How To Protect an Nginx Server with Fail2Ban on Ubuntu 14.04](how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04)
