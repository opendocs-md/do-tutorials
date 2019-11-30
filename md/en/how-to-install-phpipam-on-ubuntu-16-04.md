---
author: Daniel Pellarini
date: 2017-11-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-phpipam-on-ubuntu-16-04
---

# How To Install phpIPAM on Ubuntu 16.04

## Introduction

As your infrastructure grows, the number of IP addresses you use may also increase so much that you will no longer be able to rely solely on your memory to manage them all. At that point, you will want a tool to help you keep track of things.

While spreadsheets and plain text files are low-tech solutions that you can implement quickly, they can also be too cumbersome when working with large pools of IP addresses or when trying to track multiple data points around each address.

[phpIPAM](https://phpipam.net/), a dedicated tool for IP address management, goes way beyond the low-tech options by providing automatic ping scans, status reports that let you see which of your hosts are up and which are down, email notifications about changes to the hosts you’re monitoring, and other features that make managing infrastructure much easier.

In this guide, you will install and configure phpIPAM on a Linux, Apache, MySQL, and PHP (LAMP) stack running on Ubuntu 16.04.

## Prerequisites

Before you begin, you will need:

- One Ubuntu 16.04 server set up by following this [Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- A fully registered domain name. This tutorial uses `example.com` throughout. You can purchase a domain name on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.
- The following DNS records set up for your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them.
  - An **A** record with `example.com` pointing to your server’s public IP address.
  - An **A** record with `www.example.com` pointing to your server’s public IP address.
- A LAMP stack set up by following this [Linux, Apache, MySQL, PHP installation guide](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04).
- An Apache vhost configured for your domain set up by following this [Apache virtual hosts guide](how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04).
- A Let’s Encrypt SSL certificate for the domain installed by following [this tutorial to secure your Apache installation with a TLS/SSL certificate](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

## Step 1 — Configuring Apache

By default, phpIPAM relies on _query strings_ in its URL structure to pass data from one part of the application to another. Query strings are appended to a URL with a `?` and contain one or more field-value pairs separated by `&`.

Although not absolutely required for installation, phpIPAM supports [URL-rewriting](how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-16-04) by way of Apache’s `mod_rewrite` module, which translates query strings into more readable and human-friendly URLs.

If you didn’t already enable `mod_rewrite` in the [secure your Apache installation with a TLS/SSL certificate](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) prerequisite by redirecting all HTTP requests to HTTPS, use Apache’s `a2enmod` utility now to enable `mod_rewrite` so that you can turn URL-rewriting on in Step 2.

    sudo a2enmod rewrite

This command creates a symbolic link to `/etc/apache2/mods-available/rewrite.load` in `/etc/apache2/mods-enabled/rewrite/`, which will enable the module on Apache’s next start.

If `mod_rewrite` already was enabled, the output will read:

    Output of sudo a2enmod rewriteModule rewrite already enabled

Otherwise, the output will tell you that the symlink was created and that you need to restart Apache to activate the change.

    Output of sudo a2enmod rewriteEnabling module rewrite.
    To activate the new configuration, you need to run:
      service apache2 restart

Even though Apache will now enable `mod_rewrite` the next time you start the web server, you still have to modify your phpIPAM virtual host configuration to make `mod_rewrite` available to phpIPAM. So, don’t restart Apache just yet.

Instead, open the Apache configuration file you created for phpIPAM in the Prerequisites.

    sudo nano /etc/apache2/sites-available/example.com-le-ssl.conf

Paste the following lines into the configuration file below the `DocumentRoot` section.

phpipam.conf

    ...
        <Directory /var/www/example.com/public_html
                Options FollowSymLinks
                AllowOverride all
                Require all granted
        </Directory>
    ...

- `Directory` is the location on the server where the directives will be applied. This should be the directory you plan to install phpIPAM into. If you followed the [Apache virtual hosts guide](how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04) in the Prerequisites, this is `/var/www/example.com/public_html`.
- `Options FollowSymLinks` tells Apache to follow symbolic links in this directory. This is the default setting. 
- `AllowOverride all` means any directive in an `.htaccess` file in this directory should override any corresponding global directive.
- `Require all granted` tells Apache to allow incoming requests from all hosts.

Save and close the file to proceed.

Now, test the configuration changes before restarting Apache.

    sudo apache2ctl configtest

If the output says `Syntax OK`, you’re ready to move on. Otherwise, review the previous instructions and follow the on-screen messages for more information.

Finally, restart Apache to enable `mod_rewrite` and activate the new configuration.

    sudo systemctl restart apache2

Because you haven’t installed phpIPAM yet, there’s nothing to see at `https://example.com`. So, let’s download and install phpIPAM now.

## Step 2 — Installing phpIPAM

The [official installation instructions](https://phpipam.net/documents/installation/) suggest two methods for installing phpIPAM: downloading a tarball from [the project’s SourceForge repository](https://sourceforge.net/projects/phpipam/files/) or cloning the project from its [GitHub repository](https://github.com/phpipam/phpipam). To make future updates easier, let’s use the latter method.

By default, Git will only clone into an existing directory if that directory is empty. So, use the `ls` command to view the contents of the directory you configured for Apache in Step 1.

    ls /var/www/example.com/public_html

If the directory isn’t empty, use [basic Linux navigation and file management commands](basic-linux-navigation-and-file-management#file-and-directory-manipulation) to clear it out now. `mv` moves the contents to a different location, and `rm` deletes them altogether.

Now, clone the Git project into the directory.

    git clone https://github.com/phpipam/phpipam.git /var/www/example.com/public_html

The output confirms the location you’re cloning into and then provides a real-time report of the process, including a count of the objects Git expected to copy as well as the number it actually did copy.

    Output of git cloneCloning into /var/www/example.com/public_html ...
    remote: Counting objects: 14234, done.
    remote: Compressing objects: 100% (50/50), done.
    remote: Total 14234 (delta 27), reused 40 (delta 17), pack-reused 14161
    Receiving objects: 100% (14234/14234), 11.38 MiB | 21.30 MiB/s, done.
    Resolving deltas: 100% (10066/10066), done.
    Checking connectivity... done.

You now have the complete phpIPAM application on your server, but you’re still missing some PHP modules that phpIPAM needs in order to run. Install them with `apt-get`.

These additional packages provide PHP with the [GNU Multiple Precision module](http://php.net/manual/en/book.gmp.php) for working with arbitrary-length integers, the [Multibyte String module](http://php.net/manual/en/book.mbstring.php) for handling languages that can’t be expressed in 256 characters, the [PEAR framework](https://pear.php.net/) for reusable PHP compontents, and the [GD module](http://php.net/manual/en/book.image.php) for image processing.

    sudo apt-get install php7.0-gmp php7.0-mbstring php-pear php7.0-gd

Restart Apache to make the new modules available to it.

    sudo systemctl restart apache2

With both the application files and additional modules on the server, you’re ready to configure phpIPAM.

## Step 3 — Configuring phpIPAM

phpIPAM looks for its main configuration settings in a file called called `config.php`. While this file doesn’t exist by default, the application does come with an example configuration file to work from.

Change to the installation directory and make a copy of the example configuration file to refer to later if you encounter a problem.

    cd /var/www/example.com/public_html
    cp config.dist.php config.php

Open the new file for editing.

    nano config.php

Look for the section labeled `* database connection details`. These settings tell phpIPAM how to connect to the MySQL database that will hold all of your data.

Because you’ve installed MySQL on the same machine as phpIPAM, you can leave the `$db['host']` value set to `localhost`. And because MySQL listens on port `3306` by default, you don’t need to change the `$db['port']` value.

There isn’t a MySQL database setup for phpIPAM yet, but in Step 4, phpIPAM’s web-based installation utiltiy will create a database and database user using the values you enter in this file. So, set the `$db['user']` value to the name of the user you want phpIPAM to connect to MySQL as, set the `$db['pass']` value to the password you want phpIPAM to use when connecting to MySQL, and set `$db['name']` to the name you want to give to the MySQL database.

phpIPAM’s config.php

    <?php
    
    /**
     * database connection details
     ****************************** /
    $db['host'] = 'localhost';
    $db['user'] = 'database_user';
    $db['pass'] = 'database_password';
    $db['name'] = 'database_name';
    $db['port'] = 3306;
    ...

**Warning:** If you ran the `mysql_secure_installation` script when installing MySQL in the Prerequisites, be sure to create a password here that satisfies the current policy requirments. Failure to do so will cause an error when creating the database in Step 4.

In addition to the previous settings, there are many other options available to you in this file. For example, you can configure a secure connection to the database using an SSL certificate, you can activate email notifications for various database events, and you can enable debugging mode to generate more detailed logs. For a basic installation, though, you can leave the remainder of these settings set to their default values.

When you’re done editing, save and close the file.

Now that you’ve created the main configuration file for phpIPAM, it’s time to connect to the web interface and complete the installation.

## Step 4 — Creating the Database and Database User

The last step in the installation process consists of creating a MySQL database and user for phpIPAM and setting up an admin user account for phpIPAM’s web interface. All of this can be done through phpIPAM’s web-based installation wizard.

Navigate your browser to `https://example.com/install`. You’ll see the phpIPAM installation homepage welcoming you to the wizard and asking you to choose the type of installation you want to perform. If you’re not able to bring this screen up, verify that your firewall is not blocking access on port `80` and retrace the previous steps to resolve the problem.

There are three options on this screen — **New phpipam installation** , **Migrate phpipam installation** , and **Working installation** — each with a short description of its purpose. As you’re setting up a new phpIPAM installation, press the button marked **New phpipam installation**.

![Installing phpIPAM, step 1](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step1.png)

On the next screen, the wizard describes the rest of the installation process, points you to [the official installation documentation](https://phpipam.net/documents/installation/) for more details, and asks you to decide which type of database installation you’d like to perform.

Again, you have three choices:

- **Automatic database installation** : The wizard will use the information you entered into `config.php` in Step 3 to create a MySQL database and user.
- **MySQL import instructions** : You will use MySQL’s own [mysqlimport utility](https://dev.mysql.com/doc/refman/5.7/en/mysqlimport.html) to create the database from plaintext files you provide.
- **Manual database installation** : The wizard will supply you with the default SQL commands you need to create a new phpIPAM database manually.

For simplicity’s sake, choose the fully automated option by clicking on the **Automatic database installation** button.

![Installing phpIPAM, step 2](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step2.png)

The wizard will now ask you to supply the information it needs to connect to MySQL. This includes the login credentials for the user it should connect as, the database’s location, and the database’s name.

As you need the wizard to create a new database and user, you must enter the login credentials for a user that has sufficient privileges to do so. Your MySQL **root** user is a good choice.

By default, the database’s location is set to **localhost** and its name is set to **phpipam**. If you’d like to change either of these, you will need to edit the `config.php` file you created in Step 3 and then restart the installation wizard.

You can access additional installation options by clicking on the **Show advanced options** button. Here, you’ll be given three more choices:

- **Drop existing database** Before running the installation procedure, the wizard will attempt to delete a database with the same name as the value in the **MySQL database name** field. This is turned off by default.
- **Create database** The wizard will attempt to create a database with the same name as the value in the **MySQL database name** field. This is turned on by default.
- **Create permissions** The wizard will attempt to set permissions on the new database, limiting access to only the MySQL user defined in `config.php`. This is turned on by default.

Enter the username and password for the MySQL user you want the wizard to connect as, leave the advanced options set to their default values, and press the **Install phpipam database** button.

![Installing phpIPAM, step 3](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step3.png)

You’ll see a confirmation message telling you that the wizard successfully installed the database. If you don’t, review the wizard’s error messages for additional help.

Click on **Continue** to proceed with the installation.

![Installing phpIPAM, step 4](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step4.png)

On this screen, the wizard prompts you to set the admin user password for the web interface, the title to display at the top of each phpIPAM web interface screen, and the URL for your phpIPAM installation.

Enter the admin password you’d like to use, a descriptive title for your phpIPAM interface, and the fully-qualified domain name that points to your phpIPAM installation, then press the **Save settings** button.

![Installing phpIPAM, step 5](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step5.png)

You should now see a confirmation message telling you that the settings were successfully saved. If you don’t, use the wizard’s error messages to diagnose the problem.

![Installing phpIPAM, step 6](http://assets.digitalocean.com/articles/how-to-install-phpipam/installation-step6.png)

Click the **Proceed to login** button to go to your phpIPAM installation’s homepage, and sign-in with the **admin** username and password you entered in the **Admin password** field.

phpIPAM installation and configuration are now complete, so you can begin adding information to manage the networks you monitor more easily.

## Conclusion

In this article you installed and configured phpIPAM, an open-source IP address management web application. You can now monitor IP address usage in both your own infrastructure and in other networks.

Additionally, you can use phpIPAM to track your VLANs and map them against your subnets, keep an inventory of your network devices that includes information like device type and location, and configure email notifications to be alerted of changes on your network.

For automating phpIPAM taks programatticaly and integrating with applications you’re writing yourself, see [the official documentation on phipIPAM’s built-in API](https://phpipam.net/api/api_documentation/). To get up and running faster with the API, explore the [official introductory tutorials](https://phpipam.net/news/api_example_curl/).

Lastly, be sure to investigate the [automated scanning settings](https://phpipam.net/news/automatic-host-availability-check/) either against a public infrastructure you are managing or against your own local infrastructure. It’s the host scan automation that may offer you the greatest benefit as a sysadmin or devops engineer.
