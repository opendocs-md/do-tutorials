---
author: Vadym Kalsin
date: 2019-06-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-help-desk-system-with-otrs-on-ubuntu-18-04
---

# How To Set Up a Help Desk System with OTRS on Ubuntu 18.04

_The author selected the [Free Software Foundation](https://www.brightfunds.org/organizations/free-software-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[OTRS](https://community.otrs.com), also known as **O** pen source **T** icket **R** equest **S** ystem, is a help desk and IT service management system. It provides a single point of contact for users, customers, IT personnel, IT services, and any external organizations. The program is written in [Perl](https://www.perl.org/), supports a variety of databases ([MySQL](https://www.mysql.com/), [PostgreSQL](https://www.postgresql.org/), etc.), and can integrate with [LDAP directories](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol).

In this tutorial, you will install OTRS Community Edition on an Ubuntu 18.04 server and set up a simple help desk system, which will allow you to receive and process requests from your customers using both the web interface and email.

## Prerequisites

To complete this tutorial, you will need the following:

- An Ubuntu 18.04 server set up by following our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a non-root user with sudo privileges and a firewall configured with `ufw`.

- Apache and MySQL installed on your Ubuntu server. Follow [step 1 and 2 of this guide](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) to configure these.

- A fully registered domain name. This tutorial will use `example.com` throughout. You can purchase a domain name on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.

- Both of the following DNS records set up for your server. You can follow [this introduction to DigitalOcean DNS](an-introduction-to-digitalocean-dns) for details on how to add them.

- A TLS/SSL certificate installed on your Ubuntu 18.04 server for your domain. You can follow the [Let’s Encrypt on Ubuntu 18.04 guide](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) to obtain a free TLS/SSL certificate.

- Postfix mail transfer agent set up by following our tutorial [How To Install and Configure Postfix on Ubuntu 18.04](how-to-install-and-configure-postfix-on-ubuntu-18-04).

- (Optional) A dedicated [Gmail account](https://accounts.google.com/) with [IMAP access enabled](https://support.google.com/mail/answer/7126229?hl=en), [2-step verification](https://support.google.com/accounts/answer/185839?co=GENIE.Platform%3DDesktop&hl=en), and an [App password](https://support.google.com/mail/answer/185833?hl=en) generated with the **Other (Custom name)** option. When you generate the App password, write it down so that you can use it in Step 5. You will use Gmail to configure inbound mail ticket creation in OTRS, with Gmail as your IMAPS mailbox. This is just one method of configuring inbound mail for OTRS; if you would like to explore other options, check out the [OTRS documentation](https://doc.otrs.com/doc/manual/admin/6.0/en/html/email-settings.html#email-receiving-fetchmail).

**Warning:** Do not use any of your own active Gmail accounts to configure inbound mail for OTRS. When `imap.gmail.com` forwards emails to OTRS, all emails in the Gmail account are deleted. Because of this, it is a better option to create a new Gmail account to use specifically for OTRS.

## Step 1 — Installing the OTRS Package and Perl Modules

In this step, you will install OTRS and a set of Perl modules that will increase the system’s functionality.

OTRS is available in Ubuntu’s package manager, but [the official documentation](https://doc.otrs.com/doc/manual/admin/6.0/en/html/installation.html#installation-on-debian) suggests installing OTRS from source.

To do this, first log into your Ubuntu server as your non-root user:

    ssh sammy@Ubuntu_Server_IP

Then download the source archive with the `wget` command. For this tutorial, you will download version 6.0.19; you can find the latest available version on the OTRS [download page](https://www.otrs.com/download-open-source-help-desk-software-otrs-free/).

    wget http://ftp.otrs.org/pub/otrs/otrs-6.0.19.tar.gz

Next, unpack the compressed file with `tar`:

    tar xzf otrs-6.0.19.tar.gz

Move the contents of the archive into the `/opt/otrs` directory:

    sudo mv otrs-6.0.19 /opt/otrs

Because OTRS is written in Perl, it uses a number of Perl modules. Check for missing modules by using the `CheckModules.pl` script included with OTRS:

    sudo /opt/otrs/bin/otrs.CheckModules.pl

You’ll see output like this, listing which modules you already have downloaded and which you are missing:

    Output o Apache::DBI......................FAILED! Not all prerequisites for this module correctly installed.
      o Apache2::Reload..................ok (v0.13)
    . . .
      o XML::LibXML......................Not installed! Use: 'apt-get install -y libxml-libxml-perl' (required - Required for XML processing.)
      o XML::LibXSLT.....................Not installed! Use: 'apt-get install -y libxml-libxslt-perl' (optional - Required for Generic Interface XSLT mapping module.)
      o XML::Parser......................Not installed! Use: 'apt-get install -y libxml-parser-perl' (optional - Recommended for XML processing.)
      o YAML::XS.........................Not installed! Use: 'apt-get install -y libyaml-libyaml-perl' (required - Required for fast YAML processing.)

Some modules are only needed for optional functionality, such as communication with other databases or handling mail with specific character sets; others are necessary for the program to work.

Although the suggested commands to download these modules use `apt-get`, this tutorial will install the missing modules with the `apt` command, which is the suggested best practice for Ubuntu 18.04. Feel free to go through these modules manually, or use the following command:

    $ sudo apt install libapache2-mod-perl2 libdbd-mysql-perl libtimedate-perl libnet-dns-perl libnet-ldap-perl \
        libio-socket-ssl-perl libpdf-api2-perl libsoap-lite-perl libtext-csv-xs-perl \
        libjson-xs-perl libapache-dbi-perl libxml-libxml-perl libxml-libxslt-perl libyaml-perl \
        libarchive-zip-perl libcrypt-eksblowfish-perl libencode-hanextra-perl libmail-imapclient-perl \
        libtemplate-perl libdatetime-perl

Whenever you’re done installing these modules, rerun the script to make sure that all the required modules have been installed:

    sudo /opt/otrs/bin/otrs.CheckModules.pl

Your output will now show all the installed modules:

    Output...
      o Text::CSV_XS.....................ok (v1.34)
      o Time::HiRes......................ok (v1.9741)
      o XML::LibXML......................ok (v2.0128)
      o XML::LibXSLT.....................ok (v1.95)
      o XML::Parser......................ok (v2.44)
      o YAML::XS.........................ok (v0.69)

Now that you have OTRS and its dependencies installed on your server, you can configure OTRS to use Apache and MySQL.

## Step 2 — Configuring OTRS, Apache, and MySQL server

In this step, you will create a system user for OTRS, and then configure Apache and MySQL server to work with OTRS.

Create a user named `otrs` to run OTRS functions with the `useradd` command:

    sudo useradd -d /opt/otrs -c 'OTRS user' otrs

`-d` sets the user’s home directory as `/opt/otrs`, and `-c` sets the `'OTRS user'` comment to describe the user.

Next, add `otrs` to the webserver group:

    sudo usermod -G www-data otrs

OTRS comes with a default config file `/opt/otrs/Kernel/Config.pm.dist`. Activate this by copying it without the `.dist` filename extension:

    sudo cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm

Now, navigate to the `/opt/otrs` directory:

    cd /opt/otrs

From here, run the `otrs.SetPermissions.pl` script. It will detect the correct user and group settings and set the file and directory permissions for OTRS.

    sudo bin/otrs.SetPermissions.pl

This will yield the following output:

    OutputSetting permissions on /opt/otrs

The correct permissions are now set.

Next, activate the `apache2` configuration file and make sure it is loaded after all other configurations. To do this, make a symbolic link with the `zzz_` prefix:

    sudo ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-enabled/zzz_otrs.conf

OTRS requires a few Apache modules to be active for optimal operation. You can activate them via the tool `a2enmod`. Although some of these have already been enabled, it is a good idea to check them all:

    sudo a2enmod perl
    sudo a2enmod headers
    sudo a2enmod deflate
    sudo a2enmod filter

These modules enable Apache to work with Perl, [control HTTP headers](https://httpd.apache.org/docs/current/mod/mod_headers.html), [compress server output](https://httpd.apache.org/docs/2.4/mod/mod_deflate.html), and [configure output content filters](https://httpd.apache.org/docs/2.4/mod/mod_filter.html).

Restart your web server to apply new configurations:

    sudo systemctl restart apache2

Before you go to the next step and run the web installer, change some of the MySQL configuration settings. Open the MySQL configuration file in your preferred text editor. This tutorial uses `nano`:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Look for the following options under the `[mysqld]` section. For `max_allowed_packet` and `query_cache_size`, change the values to `64M` and `32M` respectively, as highlighted in the following code block:

/etc/mysql/mysql.conf.d/mysqld.cnf

    ...
    max_allowed_packet = 64M
    thread_stack = 192K
    thread_cache_size = 8
    # This replaces the startup script and checks MyISAM tables if needed
    # the first time they are touched
    myisam-recover-options = BACKUP
    #max_connections = 100
    #table_open_cache = 64
    #thread_concurrency = 10
    #
    # * Query Cache Configuration
    #
    query_cache_limit = 1M
    query_cache_size = 32M
    ...

This adjusts the maximum allowed packet size and the query cache size so that MySQL can interface with OTRS.

Then add the following highlighted additional options under the `[mysqld]` section, at the end of the file:

/etc/mysql/mysql.conf.d/mysqld.cnf

    ...
    # ssl-cert=/etc/mysql/server-cert.pem
    # ssl-key=/etc/mysql/server-ikey.pem
    innodb_log_file_size = 256M
    collation-server = utf8_unicode_ci
    init-connect='SET NAMES utf8'
    character-set-server = utf8

This sets the database logfile size, determines the [character set and collation](https://dev.mysql.com/doc/refman/8.0/en/charset-server.html), and creates an `init_connect` string to set the character set upon starting the MySQL server.

Save and close `mysqld.cnf` by pressing `CTRL` + `X`, followed by `Y` and then `ENTER`. Then, restart your MySQL server to apply the new parameters:

    sudo systemctl restart mysql.service

Now that you have created the `otrs` user and configured Apache and MySQL to work with OTRS, you are ready to use the web installer.

## Step 3 — Using the Web Installer

In this step, you will configure OTRS’s database settings in a web browser and start the OTRS daemon process on the command line.

Open `https://example.com/otrs/installer.pl` in your favorite web browser, replacing `example.com` with your domain name. You will find a welcome screen with the message **Welcome to OTRS 6** and information about the OTRS offices.

![OTRS Welcome Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/First_Screen.png)

Click **Next**. The next screen will have the license for OTRS, which is the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html) common to open source programs. Accept by clicking **Accept license and continue** after reading.

On the next screen, you will be prompted to select a database type. The defaults ( **MySQL** and **Create a new database for OTRS** ) are fine for your setup, so click **Next** to proceed.

![Database Selection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Database_Selection.png)

On the next screen, enter the MySQL credentials that you set up during the MySQL server installation. Use **root** for the **User** field, then enter the password you created. Leave the default host value.

Click **Check database settings** to make sure it works. The installer will generate credentials for the new database. There is no need to remember this generated password.

![Result of database check](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Database_Check.png)

Click **Next** to proceed.

The database will be created and you will see the successful result:

![Database setup successful](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Database_Success.png)

Click **Next**.

Next, provide the following required system settings:

- **System FQDN** : A fully qualified domain name. Replace `example.com` with your own domain name.
- **AdminEmail** : The email address of your system administrator. Emails about errors with OTRS will go here.
- **Organization** : Your organization’s name.

Leave all other options at their default values:

![System Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/System_Settings.png)

Click **Next**.

Now you will land on the **Mail Configuration** page. In order to be able to send and receive emails, you have to configure a mail account. This tutorial will take care of this later in Step 5, so click **Skip this step**.

The OTRS installation is now complete; you will see a **Finished** page with a link to the admin panel after **Start page** , and the credentials of the OTRS super user after that. Make sure you write down the generated password for the **root@localhost** user and the URL for the **Start page**.

The only thing left after a successful installation is to start the OTRS daemon and activate its `cronjob`.

Bring up the terminal you are using to access your Ubuntu 18.04 server. The OTRS daemon is responsible for handling any asynchronous and recurring tasks in OTRS. Start it with the `otrs` user:

    sudo su - otrs -c "/opt/otrs/bin/otrs.Daemon.pl start"

You will see the following output:

    OutputManage the OTRS daemon process.
    
    Daemon started

There are two default cron files in the `/opt/otrs/var/cron/` directory. Move into this directory.

    cd /opt/otrs/var/cron

These cron files are used to make sure that the OTRS daemon is running. Activate them by copying them without the `.dist` filename extension.

    sudo cp aaa_base.dist aaa_base
    sudo cp otrs_daemon.dist otrs_daemon

To schedule these cron jobs, use the script `Cron.sh` with the `otrs` user:

    sudo su - otrs -c "/opt/otrs/bin/Cron.sh start"

You have now installed OTRS with the web installer and set up its connection to the MySQL database. You also started the OTRS daemon on your server. Next, you will log in to the administrator web interface and secure OTRS.

## Step 4 — Securing OTRS

At the moment, you have a fully functional application, but it’s not secure to use the super user account with OTRS. Instead, you’ll create a new _agent_. In OTRS, agents are users who have rights to the various functions of the system. In this example, you will use a single agent who has access to all functions of the system.

To get started, log in as **root@localhost**. Open the **Start page** link which you received in the previous step. Enter **root@localhost** for the username and the password you copied from Step 3, then click **Login**.

You will see the main dashboard. It contains several widgets which show different information about tickets, statistics, news, etc. You can freely rearrange them by dragging or switch their visibility in settings.

![Main screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Main_Screen.png)

First, create a new agent. To do this, follow the link by clicking on the red message in the top of the screen that reads **Don’t use the Superuser account to work with OTRS 6! Create new Agents and work with these accounts instead.** This will bring you to the **Agent Management** screen.

![Agent Management](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Agent_Management.png)

Click the **Add agent** button. This will bring you to the **Add Agent** screen. Most of the default options are fine. Fill in the first name, last name, username, password, and email fields. Record the username and password for future login. Submit the form by clicking the **Save** button.

Next, change the group relations for the new agent. Because your agent will also be the administrator, you can give it full read and write access to all groups. To do this, click the checkbox next to **RW** all the way on the right, under **Change Group Relations for Agent**.

![Change Group Relations](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Change_Group_Relations.png)

Finally, click **Save and finish**.

Now, log out and log back in again using the newly created account. You can find the **Logout** link by clicking on the avatar picture in the top left corner.

![Logout Location](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Logout_Location.png)

Once you have logged back in, you can customize your agent’s preferences by clicking on **Personal preferences** in the avatar menu. There you can change your password, choose the interface language, configure setup notifications and favorite queues, change interface skins, etc.

Once you have logged in as your new agent and configured the account to your liking, the next step is to configure the inbound mail options to generate tickets from incoming emails.

## Step 5 — Configuring Inbound Mail

Customers have two ways to forward new tickets to OTRS: via the customer front-end or by sending an email. In order to receive customer’s messages you need to set up a POP or IMAP account. In this tutorial, you will use your dedicated OTRS Gmail account that you created as a prerequisite.

Navigate to the Admin tab by clicking on **Admin** in the top menu. Then find the **PostMaster Mail Accounts** option and click on it. Press the **Add Mail Account** button to set up a new mailbox.

![Add Mail Account](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Add_Mail_Account.png)

On the **Add Mail Account** screen, select **IMAPS** for **Type**. For **Username** , type in your Gmail address, and for **Password** , enter the App password that you generated for your Gmail account in the prerequisites. Leave all other options as default. Click **Save**.

**Note:** You can use Gmail for IMAPS without 2-step verification by enabling **Less secure app access** for your Gmail account. You will find instructions on how to do this in the [Google Help Center](https://support.google.com/accounts/answer/6010255?hl=en). However, this method is less secure, and it can take up to 24 hours for **Less secure app access** to take effect. It is recommended that you use the App password method.

Next, send a test email from an external email account to your dedicated OTRS Gmail account. The mail will be fetched every 10 minutes by the OTRS daemon, but you can force receipt by clicking the **Fetch mail** link.

As a result, you will see the new ticket.

![Email ticket](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Email_Ticket.png)

Now you are ready to accept tickets from customers via email. Next, you will go through the process of creating a ticket through the customer front-end.

## Step 6 — Working with the Customer Interface

The second way for a customer to create a ticket is through the OTRS front-end. In this step, you will walk through this process to make sure this ticket creation method is set up.

The customer front-end is located at `https://example.com/otrs/customer.pl`. Navigate to it in a web browser. You can create a customer account there and submit a ticket using the GUI.

Use the **Sign up now** link to open the registration form.

![Create Account](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Create_Account.png)

Fill out the form and press the **Create** button.

You will see a message like this:

    New account created. Sent login information to sammy@gmail.com. Please check your email.

Check your inbox for the message from the OTRS. You will see a message with the new account credentials:

    Hi sammy,
    
    You or someone impersonating you has created a new OTRS account for
    you.
    
    Full name: sammy
    User name: sammy@email.com
    Password : Sammy_Password
    
    You can log in via the following URL. We encourage you to change your password
    via the Preferences button after logging in.
    
    http://example.com/otrs/customer.pl

Now, use the provided credentials to access the customer front-end and create another ticket. All new tickets created using the customer front-end will immediately appear on the agent’s dashboard:

![Customer ticket](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_66543/Customer_Ticket.png)

On the agent dashboard, you can see the information on all current tickets: their status (new, opened, escalated, etc.), their age (the time elapsed from the moment when the ticket was received), and subject.

You can click on the ticket number (in the **TICKET#** column) to view its details. The agent can also take actions on the ticket here, like changing its priority or state, moving it to another queue, closing it, or adding a note.

You have now successfully set up your OTRS account.

## Conclusion

In this tutorial, you set up OTRS and created test help desk tickets. Now you can accept and process requests from your users using both the web interface and email.

You can learn more about OTRS by reading the [OTRS Admin Manual](https://doc.otrs.com/doc/manual/admin/6.0/en/html/index.html). If you want to read more about how to use MySQL, see our [An Introduction to Queries in MySQL](introduction-to-queries-mysql) article, or explore DigitalOcean’s [Managed Databases product](https://www.digitalocean.com/products/managed-databases/).
