---
author: Joshua Tan
date: 2017-07-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-virtualmin-with-webmin-lamp-bind-and-postfix-on-ubuntu-16-04
---

# How To Install Virtualmin with Webmin, LAMP, BIND, and PostFix on Ubuntu 16.04

## Introduction

[Webmin](http://www.webmin.com/) is a web front-end that allows you to manage your server remotely through a browser. [Virtualmin](http://www.webmin.com/virtualmin.html) is a plugin for Webmin that simplifies the management of multiple virtual hosts through a single interface, similar to [cPanel](https://cpanel.com/) or [Plesk](https://www.plesk.com/). With Virtualmin, you can manage user accounts, Apache virtual hosts, DNS entries, MySQL databases, mailboxes, and much more.

In this tutorial, you’ll use a script to install the free edition, Virtualmin GPL. This script will install everything you need to use Virtualmin, including Webmin and the following prerequisites:

- [A LAMP stack](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu) (Apache, PHP, and MySQL), for serving web sites and web applications.
- [BIND](how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04), a DNS server.
- [PostFix](how-to-install-and-configure-postfix-on-ubuntu-16-04), a mail server.

Once you install Virtualmin and its components, you’ll configure Webmin through its graphical interface and create a new virtual host with Virtualmin. Once you complete this tutorial you will be able to create any number of user accounts to host multiple domains on a single server through your browser.

**Warning:** Do not follow this tutorial on a live production server that is already running Apache, MySQL and PHP, as this can result in data loss. Use a new server and transfer your data over instead.

## Prerequisites

To complete this tutorial, you will need:

- One new Ubuntu 16.04 server with at least 1GB of RAM set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- A Fully-Qualified Domain Name configured to point to your server. You can learn how to point domain names to DigitalOcean Droplets by following the [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) tutorial.
- Two registered custom nameservers for Virtualmin by following the [How To Create Vanity or Branded Nameservers with DigitalOcean Cloud Servers](how-to-create-vanity-or-branded-nameservers-with-digitalocean-cloud-servers) tutorial. Register `ns1.your_domain.com` and `ns2.your_domain.com`, where `your_domain.com` is your domain name.

## Step 1 — Setting the Hostname and FQDN

For Virtualmin to work properly, you need to configure the hostname and FQDN on the server itself by editing the `/etc/hostname` and `/etc/hosts` files, as well as update your DNS settings so DNS lookups resolve properly.

First, log in to your server as your non-root user. Once you have logged in, update the package database:

    sudo apt-get update

Then install any necessary updates and packages to ensure you start with a stable and up-to-date system.

    sudo apt-get dist-upgrade -y

Next, change the hostname to match the FQDN you’ve pointed to the server in the prerequisites.

To check the current server hostname, run this command:

    hostname -f

To change the hostname for your server, open the file `/etc/hostname` in your editor:

    sudo nano /etc/hostname

Delete the current hostname and replace it with your hostname:

/etc/hostname

    your_hostname

Use just the hostname, not the entire FQDN, in this file. For example, if your FQDN is `virtualmin.example.com`, enter `virtualmin` in this file.

Save the file and exit the editor.

Next, add both the hostname and FQDN in the `/etc/hosts` file:

    sudo nano /etc/hosts

Modify the line that starts with `127.0.0.1` to use your FQDN and hostname, in that order:

/etc/hosts

    127.0.1.1 your_hostname.your_domain.com your_hostname
    127.0.0.1 localhost
    ...

Remember to replace `your_hostname` and `your_domain.com` with your own hostname and domain name. Save the file and exit the editor.

If this line doesn’t exist in your file, add it to avoid some compatibility issues with other software on your Ubuntu system. You can learn more about this in the [official Debian manual entry on setting up hostnames](http://www.debian.org/doc/manuals/debian-reference/ch05.en.html#_the_hostname_resolution).

To check if the name has been changed correctly, reboot your server.

    sudo reboot

Then ssh into your server again. You should see the new hostname on your terminal prompt. For example:

    your_user@your_hostname:~$

Use the `hostname` command to verify that the FQDN was set correctly:

    hostname -f

You’ll see your FQDN in the output:

    outputyour_hostname.your_domain.com

If you don’t, double-check the changes you made to your configuration, correct any errors, and reboot.

Next, edit the network configuration file so that it uses this server as one of the DNS servers to resolve domain names. Open the configuration file:

    sudo nano /etc/network/interfaces.d/50-cloud-init.cfg

Add the IP address `127.0.0.1` to the configuration file. Look for the following line:

/etc/network/interfaces.d/50-cloud-init.cfg

    dns-nameservers 8.8.8.8 8.8.4.4

Change it to:

/etc/network/interfaces.d/50-cloud-init.cfg

    dns-nameservers 8.8.8.8 8.8.4.4 127.0.0.1

Make sure there is a space before `127.0.0.1`. Save the file and exit the editor.

You have prepared the server by setting the hostname, FQDN, and the network configuration. Let’s install Virtualmin.

## Step 2 — Installing Virtualmin

To install Virtualmin, download and run the official Virtualmin installation script, which will install Virtualmin, and Webmin, along with a LAMP stack, BIND, and Postfix.

Use `wget` to download the script:

    wget https://software.virtualmin.com/gpl/scripts/install.sh

While this script comes from the official Virtualmin website, you may want to open the script in your editor and review the contents before running it.

    sudo nano ./install.sh

Once you’re comfortable with the contents of the script, use it to install Virtualmin and its prerequisites:

    sudo /bin/sh ./install.sh

The script will display a warning message about existing data and compatible operating systems. Press `y` to confirm that you want to continue the installation.

The script will take some time to complete all the steps as it installs various software packages and components.

Once the script completes, you can configure the root password.

## Step 3 — Configuring Webmin’s Root Password

Virtualmin is an add-on to Webmin, and by default, Webmin uses the system **root** user and password for the web interface login. If you log in to your server using an SSH key, you may not have the system root password, or may not feel comfortable using it to log in remotely through a browser. Let’s tell Webmin to use a different password for its web interface. This process won’t change the system root password; it’ll just tell Webmin to use the password you specify for the login.

To change Webmin’s root password, use the following command:

    sudo /usr/share/webmin/changepass.pl /etc/webmin root yourpassword

Replace `yourpassword` with your preferred password.

Next, restart the Webmin service so the changes take effect.

    sudo systemctl restart webmin

Next, we will configure Webmin using the web front-end.

## Step 4 — Configuring Webmin Using The Post-Installion Wizard

To configure Webmin, we’ll use its web-based Post-Installation Wizard. Open your web browser and navigate to `https://your_server_ip:10000`. You can also use your fully-qualified domain name to access the site.

**Note:** Your browser may show a “Your connection is not secure” or “Your connection is not private” warning since Virtualmin uses a self-signed certificate. This warning is normal. You can add Let’s Encrypt SSL certificate after you have completed this tutorial by following **Step 2** of the [How to Install Webmin on Ubuntu 16.04](how-to-install-webmin-on-ubuntu-16-04#step-2-%E2%80%94-adding-a-valid-certificate-with-let%27s-encrypt) tutorial.

Log in as the **root** user with the newly-changed password you set in the previous step.

Once you have logged in, you’ll see the **Introduction** screen stating that you are going through the steps to configure Virtualmin. Press **Next** to continue.

![The Introduction screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/virtualmin_1604/ewUrB0H.png)

On the **Memory use** screen, select **No** for **Preload Virtualmin libraries** , since you don’t need to run the Virtualmin UI all the time. Select **Yes** for **Run email domain lookup server** to enable faster mail processing. Press **Next** to continue.

On the **Virus scanning** screen, select **No** for **Run ClamAV server scanner** so you’ll use less RAM. Press **Next** to continue.

On the **Spam filtering** screen, select **No** for **Run SpamAssassin server filter** and press **Next** to continue.

The next three screens configure the database server:

- On the **Database servers** screen, select **Yes** to **Run MySQL database server** and **no** to **Run PostgreSQL database server**. Press **Next** to continue. 
- On the **MySQL password** screen, enter your desired MySQL root password. It should be different from the root password you used to log in to Webmin. 
- On the **MySQL database size** screen, select the RAM option that matches the amount of RAM your server has. For a 1GB server, select **Large system (1G) on which MySQL is heavily used**. Press **Next** to continue.

Next, you’ll see a screen like the following, where you’re asked to enter nameservers:

![DNS zones and nameservers screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/virtualmin_1604/Uyb7HYZ.png)

Enter your primary and secondary nameservers here which you configured in the prerequisites. If you haven’t set these up, check the **Skip check for resolvability** box to avoid error message and proceed.

Next, on the **Password storage mode** screen, select **Store plain-text passwords** if you must support password recovery. Otherwise, choose **Only store hashed passwords**. After clicking **Next** , you will see the **All done** screen. Click **Next** to end.

Finally, you’ll be presented with the Virtualmin/Webmin dashboard.

You may see a message at the top stating that Virtualmin comes with a new theme. To activate the new theme, click the **Switch Themes** button. The page will reload but may look unstyled, as the new theme’s CSS file might not load properly. To solve this issue, refresh your browser manually.

You may also see a message stating that Virtualmin’s configuration has not been checked. Click the **Re-check and refresh configuration** button to check your Virtualmin configuration. Address any errors that the check reports.

Your server is now configured. Let’s use the interface to create a new virtual server.

## Step 5 — Creating A New Virtual Server

Virtualmin makes it easy to set up new virtual hosts, as well as users to manage those hosts.

Click on the Virtualmin tab on the left sidebar to display the Virtualmin sidebar menu. Next, click **Create Virtual Server**. You’ll see the following screen:

![New virtual host settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/virtualmin_1604/BpxUzxk.png)

On the form that appears, enter the following:

- For **Domain name** , enter the domain name you plan to use for the new virtual server.
- For **Description** , enter an appropriate description of your server.
- For **Administration password** , enter a password that you’ll use to manage this virtual server. It should be different from other passwords you’ll use.

Leave all the other options at their default values.

Click **Create Server** to create the new virtual server. The screen will display output as Virtualmin creates the various components for you.

You have just created a new virtual server using Virtualmin, as well as a user that can manage the server. The username will be displayed in the output, and the password will be the password you set. You can provide that username and password to another user so they can manage the virtual server through Virtualmin themselves.

To log out of Virtualmin, click the red exit arrow icon at the bottom of the left sidebar.

## Conclusion

In this tutorial, you configured VirtualMin and used its interface to create a virtual server and a new administrative user for that server.

To learn more about Virtualmin, look at the [official Virtualmin documentation](https://www.virtualmin.com/documentation). Don’t forget to get familiar with the [Webmin documentaiton](http://www.webmin.com/docs.html), since you can use Webmin to manage services, install updates, and do other system administration tasks.
