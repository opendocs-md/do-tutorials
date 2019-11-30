---
author: Tony Bandy
date: 2015-06-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-linux-apache-mysql-php-lamp-stack-on-debian-8
---

# How To Install Linux, Apache, MySQL, PHP (LAMP) Stack on Debian 8

## Introduction

The “LAMP” stack of software, consisting of the **L** inux operating system, **A** pache web server, **M** ySQL database, and **P** HP scripting language, is a great foundation for web or application development. Installed together, this software stack enables your server to host dynamic websites and web applications.

In this tutorial, we’ll install a LAMP stack on a Debian 8 server.

## Prerequisites

- Before we get started, you will need to set up a Debian 8 server with a non-root `sudo`-enabled user account. You can do this by following our [initial server setup guide for Debian 8](initial-server-setup-with-debian-8).

- You should also create a basic firewall, which you can do by following the [Ubuntu and Debian UFW setup tutorial](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server).

## Step 1 — Updating the System

Before you install any software, it’s important to make sure your system is up to date. To update your package lists, type:

    sudo apt-get update

This tells your operating system to compare the software packages currently installed on your server with any new versions that might have been updated recently in the Debian online repositories, where base software packages are stored.

**Note:** If you are running a development or mission-critical high-use server, be cautious about installing updates without carefully going through each package to determine if it is actually needed for your system. In our example here, all packages have been installed for the purposes of this tutorial only.

Once you’ve determined that these updated software components are relevant for your needs, go ahead and update your server. You can do this by typing the following command:

    sudo apt-get dist-upgrade

This may take a while, depending on the current version of the operating system you have installed, software packages, and network conditions. On a fresh server, it will take a couple of seconds.

Now your server is fully patched, updated, and ready for LAMP installation. Since your server is already running the Linux operating system Debian, you can move on to installing the Apache web server to manage your networking connections.

## Step 2 — Installing Apache and Updating the Firewall

The next step in our LAMP installation is to install the Apache web server. This is a well-documented and widely used web server that will allow your server to display web content. To install Apache, type the following:

    sudo apt-get install apache2 apache2-doc

This installs the basic Apache web server package as well as the documentation that goes along with it. This may take a few seconds as Apache and its required packages are installed. Once done, `apt-get` will exit, and the installation will be complete.

Next, assuming that you have followed the UFW setup tutorial by installing and enabling a firewall, make sure that your firewall allows HTTP and HTTPS traffic.

When installed on Debian 8, UFW comes loaded with app profiles which you can use to tweak your firewall settings. View the full list of application profiles by running:

    sudo ufw app list

The `WWW` profiles are used to manage ports used by web servers:

    OutputAvailable applications:
    . . .
      WWW
      WWW Cache
      WWW Full
      WWW Secure
    . . .

If you inspect the `WWW Full` profile, it shows that it enables traffic to ports `80` and `443`:

    sudo ufw app info "WWW Full"

    OutputProfile: WWW Full
    Title: Web Server (HTTP,HTTPS)
    Description: Web Server (HTTP,HTTPS)
    
    Ports:
      80,443/tcp

Allow incoming HTTP and HTTPS traffic for this profile:

    sudo ufw allow in “WWW Full”

Now that we’ve allowed web traffic through our firewall, let’s test to make sure the web server will respond to requests with a sample web page. First up, you will need the IP address of your server. You can view your IP address in your current SSH session by running the following command:

    sudo ifconfig eth0

On your screen, you will see a few lines of output, including your server’s IP address. You’ll want the four-part number shown after `inet addr:`:

    Outputinet addr:111.111.111.111

Note the IP address listed and type it into your favorite web browser like this:

- `http://111.111.111.111`

Once done, you will see the default Apache 2 web page, similar to this:

![Apache2 Debian Default Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp-debian8/JUGu5aW.png)

Now that you have successfully installed Apache on your server, you can upload your website content to the `/var/www/html` directory. If you want to set up multiple websites, please see this article on setting up [Apache virtual hosts](how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts).

For additional instructions and Apache-related security information, please take a look at [Debian’s Apache information](https://wiki.debian.org/Apache).

With your web server up and running, you are ready to create a place for your website to store data, which you can do with MySQL.

## Step 3 — Installing and Securing MySQL

The next component of the LAMP server is MySQL. This relational database software is an essential backend component for other software packages such as WordPress, Joomla, Drupal, and many others.

To install MySQL and PHP support for it, type the following:

    sudo apt-get install mysql-server php5-mysql

This will install MySQL and other required packages. Note that the installation routine will ask you to enter a new password for the **root** MySQL user:

![New password for the MySQL "root" user](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp-debian8/a0O038P.png)

This is a separate account used specifically for administrative functions in MySQL. The username is **root** and the password is whatever you set here. Be sure to set a good password with various combinations of letters and numbers.

After this, the MySQL installation is finished.

To keep your new database server safe, there is an additional script you need to run. Type the following to get started:

    sudo mysql_secure_installation

At this point, the script will ask you a few questions. When prompted, enter the password for the root MySQL account. The system will then ask you:

    InteractiveChange the root password? [Y/n] n

Since we already set the root MySQL password at our installation, you can say no at this point. The script will then ask:

    InteractiveRemove anonymous users? [Y/n] y

Answer yes to remove the anonymous users option for safety.

Next, the script will ask you to either allow or disallow remote logins for the root account. For safety, disallow remote logins for root unless your environment requires this.

Finally, the script will ask you to remove the test database and then reload the privilege tables. Answer yes to both of these. This will remove the test database and process the security changes.

If everything is correct, once done, the script will return with:

    OutputAll done! If you have completed all of the above steps, your MySQL installation should now be secure.

Let’s double-check that our new MySQL server is running. Type this command:

    mysql -u root -p

Enter the root password you set up for MySQL when you installed the software package. Remember, this is **not** the root account used for your server administration. Once in, type the following to get the server status, version information, and more:

    status

This is a good way to ensure that you’ve installed MySQL and are ready for further configuration. When you are finished examining the output, exit the application by typing this:

    exit

After confirming that MySQL is active, the next step is to install PHP so that you can run scripts and process code on your server.

## Step 4 — Installing PHP

For our last component, we will set up and install PHP, which stands for PHP: Hypertext Preprocessor. This popular server-side scripting language is used far and wide for dynamic web content, making it essential to many web and application developers.

To install PHP, type the following:

    sudo apt-get install php5-common libapache2-mod-php5 php5-cli

After you agree to the installation, PHP will be installed on your server. You will see many packages being installed beyond just PHP. Don’t worry; your system is integrating the PHP software with your existing Apache2 installation and other programs.

Restart Apache on your server to make sure all of the changes with the PHP installation take effect. To do this, type the following:

    sudo service apache2 restart

Now, let’s take a moment to test the PHP software that you just installed. Move into your public web directory:

    cd /var/www/html

Once there, use your favorite console text editor to create a file named `info.php`. Here’s one method of doing this:

    sudo nano info.php

This command will use the command line editor `nano` to open a new blank file with this name. Inside this file, type the following to populate a web page with output information for your PHP’s configuration:

/var/www/html/info.php

    <?php phpinfo(); ?>

Hit `CTRL-X` to exit the file, then `Y` to save the changes that you made, then `ENTER` to confirm the file name. To access the configuration info, open your web browser and type the following URL, replacing the highlighted section with your server’s IP address:

- `http://111.111.111.111/info.php`

If you’ve done everything correctly, you will see the default PHP information page, like the one shown below:

![PHP Information Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp-debian8/kAOmYue.png)

When you are done looking at this test PHP page, remove it for security. To do that, run this command:

    sudo rm -i /var/www/html/info.php

The system will then ask if you wish to remove the test file that you’ve created. Answer yes to remove the file. Once this is done, you will have completed the basic PHP installation.

## Conclusion

You have now installed the basic LAMP stack on your server, giving you a platform to create a wide range of websites and web applications. From here, there are many ways that you could customize and extend the capabilities of your server. To learn more about securing your Linux server, check out [An Introduction to Securing Your Linux VPS](an-introduction-to-securing-your-linux-vps). If you would like to set up your server to host multiple websites, follow the [Apache virtual hosts tutorial](how-to-set-up-apache-virtual-hosts-on-ubuntu-14-04-lts).
