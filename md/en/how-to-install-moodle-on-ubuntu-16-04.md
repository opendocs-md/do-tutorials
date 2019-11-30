---
author: Ben Blanchard
date: 2017-03-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-moodle-on-ubuntu-16-04
---

# How To Install Moodle on Ubuntu 16.04

## Introduction

[Moodle](https://moodle.org/) is a popular and open-source web-based learning management system (LMS) that is free for anyone to install and use. With Moodle, you can create and deliver learning resources such as courses, readings, and discussion boards to groups of learners. Moodle also allows you to manage user roles, so students and instructors can have different levels of access to materials. Once you install Moodle on your web server, anyone with access to your site can create and participate in browser-based learning.

In this guide, you will install and set up Moodle on your Ubuntu 16.04 server. You’ll install and configure all the software required by Moodle, run through the setup wizard, choose a theme, and create your first course.

## Prerequisites

Before you begin this guide you’ll need the following:

- A 1GB Ubuntu 16.04 server with a minimum of 200MB of disk space for the Moodle code and as much as you need to store your content. Moodle requires 512MB of memory, but recommends at least 1GB for best performance. 
- A non-root user with sudo privileges and a firewall, which you can set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04).
- The LAMP stack (Apache, MySQL, and PHP) installed by following [this tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04). Be sure to make a note of the root MySQL password you set during this process.

## Step 1 — Install Moodle and Dependencies

Moodle relies on a few pieces of software, including a spell-checking library and a graphing library. Moodle is a PHP application, and it has a few additional PHP library dependencies as well. Before we install Moodle, let’s install all of the prerequisite libraries using the package manager. First, ensure you have the latest list of packages:

    sudo apt-get update

Then install Moodle’s dependencies:

    sudo apt-get install aspell graphviz php7.0-curl php7.0-gd php7.0-intl php7.0-ldap php7.0-mysql php7.0-pspell php7.0-xml php7.0-xmlrpc php7.0-zip

Next, restart the Apache web server to load the modules you just installed:

    sudo systemctl restart apache2

Now we are ready to download and install Moodle itself. We’ll use `curl` to download Moodle from the official distribution server.

The following command will go to the Moodle website and get the compressed package that contains the entire current, stable version of Moodle into the file `moodle.tgz`. The `-L` flag tells `curl` to follow redirects.

    curl -L https://download.moodle.org/download.php/direct/stable32/moodle-latest-32.tgz > moodle.tgz

Now we can uncompress the file with the `tar` program and place the resulting files in the web document root:

    sudo tar -xvzf moodle.tgz -C /var/www/html

Verify that the `moodle` directory is in your server’s web root directory:

    ls /var/www/html

You should see the `moodle` directory listed:

    Outputindex.html moodle

Now view the files within the `moodle` directory:

    ls /var/www/html/moodle

You will see all of the Moodle files and directories you just downloaded and uncompressed:

    Outputadmin composer.json grade message README.txt
    auth composer.lock group mnet report
    availability config-dist.php Gruntfile.js mod repository
    backup config.php help_ajax.php my rss
    badges CONTRIBUTING.txt help.php notes search
    behat.yml.dist COPYING.txt index.php npm-shrinkwrap.json tag
    blocks course install package.json tags.txt
    blog dataformat install.php phpunit.xml.dist theme
    brokenfile.php draftfile.php INSTALL.txt pix TRADEMARK.txt
    cache enrol iplookup plagiarism user
    calendar error lang pluginfile.php userpix
    cohort file.php lib portfolio version.php
    comment files local PULL_REQUEST_TEMPLATE.txt webservice
    competency filter login question
    completion githash.php media rating
    

Now we need to create a directory outside the web root for Moodle to store all the course-related data that will be stored on the server, but not in the database. It is more secure to create this directory outside the web root so that it cannot be accessed directly from a browser. Execute this command:

    sudo mkdir /var/moodledata

Then set its ownership to make sure that the web service user `www-data` can access the directory:

    sudo chown -R www-data /var/moodledata

Then change the permissions on the folder so that only the owner has full permissions:

    sudo chmod -R 0770 /var/moodledata

Now that you’ve got Moodle on your server, it’s time to set up the database it’ll use.

## Step 2 — Configuring the Database

We need to create the MySQL database where Moodle will store most of its data. We’ll create the structure that the Moodle code expects, and we’ll create a user that Moodle will use to connect to the database.

But first we need to make a few changes to the MySQL configuration file in order our MySQL installation to be compatible with Moodle. Open the MySQL configuration file:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Then add the following highlighted lines to the ‘Basic Settings’ area, which configure the storage type that new databases should use:

mysqld configuration

    ...
    [mysqld]
    #
    # * Basic Settings
    #
    user = mysql
    pid-file = /var/run/mysqld/mysqld.pid
    socket = /var/run/mysqld/mysqld.sock
    port = 3306
    basedir = /usr
    datadir = /var/lib/mysql
    tmpdir = /tmp
    lc-messages-dir = /usr/share/mysql
    skip-external-locking
    default_storage_engine = innodb
    innodb_file_per_table = 1
    innodb_file_format = Barracuda
    ## Instead of skip-networking the default is now to listen only on
    # localhost which is more compatible and is not less secure.
    ...

Save this file and then restart the MySQL server to reload the configuration with the new settings.

    sudo systemctl restart mysql

Now we can create the Moodle database. In order to do this, you’ll interact with the MySQL command-line interface. Execute this command:

    mysql -u root -p

When prompted, supply the root password you set when you installed MySQL.

Once logged in, you’ll see the `mysql>` prompt. Run the following command to create the database:

    CREATE DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

Then create a Moodle user, so we don’t have to tell the Moodle application what our root password is. Execute this command:

**Note:** In the next two commands, replace `moodler` with your Moodle username and `moodlerpassword` with a chosen password.

    create user 'moodler'@'localhost' IDENTIFIED BY 'moodlerpassword';

And give the `moodler` user permission to edit the database. This user will need to create tables and change permissions:

    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON moodle.* TO 'moodler'@'localhost' IDENTIFIED BY 'moodlerpassword';

Now exit the MqSQL command-line interface:

    quit;

That takes care of the database configuration. Now we can launch Moodle in a browser and continue the setup there.

## Step 3 — Configuring Moodle in the Browser

To finish configuring Moodle, we’ll bring up the site in a web browser and provide it with some additional configuration details. In order for the web server to save the configuration, we need to temporarily alter the permission for the Moodle web root.

**Warning:**   
The permissions open this folder up to everyone. If you are uncomfortable with doing this, simply don’t change the permission. The web interface will provide instructions for you to manually modify the configuration file.

If you do change the permissions, it is very important to undo this as soon as you have completed the setup. That step is included in this tutorial.

    sudo chmod -R 777 /var/www/html/moodle

Now open up a browser and go to `http://your_server_ip/moodle`. You’ll see a page like the following.

![Initial Moodle Setup Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/moodle_ubuntu_1604/TpIkbFk.png)

Follow these steps to configure Moodle:

1. Set the language you want to use and click **Next**. 
2. On the next screen, set the **Data Directory** to `/var/moodledata` and click **Next**.
3. On the the **Choose Database Driver** page, set **Database driver** to **Improved MySQL (native mysqli)**. Then click **Next**.
4. On the **Database setting** page, enter the username and password for the Moodle MySQL user you created in Step 3. The other fields can be left as they are. Click **Next** to continue.
5. Review the license agreement and confirm that you agree to its terms by pressing **Continue.**
6. Review the **Server Checks** page for any possible issues. Ensure the message “Your server environment meets all minimum requirements” exists at the bottom and press **Continue.**
7. Moodle will install several components, displaying “Success” messages for each. Scroll to the bottom and press **Continue.**
8. You’ll then see a page where you can set up your administrator account for Moodle. 
  1. For **Username** , enter anything you’d like, ar accept the default. 
  2. For **Choose an authentication method** , leave the default value in place.
  3. For **New password** , enter the password you’d like to use.
  4. For **Email** , enter your email address.
  5. Set the rest of the fields to appropriate values.
  6. Click **Update profile**.
9. On the **Front Page Settings** screen, fill in the **Full site name** , the **Short name for site** , set a location, and select whether you want to allow self-registration via email. Then click **Save changes.**

Once you’ve done this. you’ll be taken to the dashboard of your new Moodle installation, logged in as the **admin** user.

Now that your setup is complete, it’s important to restrict permissions to the Moodle web root again. Back in your terminal, execute the following command:

    sudo chmod -R 0755 /var/www/html/moodle

Let’s make one more minor change to improve Moodle’s security. By default, Moodle creates files in the `/var/moodledata` folder with world-writeable permissions. Let’s tighten that up by changing the default permissions Moodle uses.

Open the Moodle configuration file in your editor:

    sudo nano /var/www/html/moodle/config.php

Locate this line:

config.php

    $CFG->directorypermissions = 0777;

Change it to the following:

config.php

    $CFG->directorypermissions = 0770;

Then save the file and exit the editor.

Finally, reset the permissions on the `/var/moodledata` directory itself, as Moodle already created some world-writeable folders and during the installation process:

    sudo chmod -R 0770 /var/moodledata

Now that Moodle is configured, let’s make a few customizations and create a test course to get a feel for the Moodle web interface.

## Step 4 — Customizing Moodle and Creating Your First Course

Now that your site is running, one of the first things you night want to do is register your Moodle site. This will subscribe you to the Moodle mailing list which will keep you up to date about things like security alerts and new releases.

To register, click the **Site Administration** link in the box on the left, and click on **Registration**. Then fill out the web form with the appropriate details. You can also choose to publish your Moodle site so others can find it.

Next, let’s change the theme for our Moodle site. Select **Site Administration** , select the **Appearance** tab, and select **Theme selector**. You will see a page that looks like the following figure, indicating that you’re currently using the “Boost” theme on the **Default** device, which refers to a modern web browser:

![Theme Selector Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/moodle_ubuntu_1604/OWwL2P7.png)

Click the **Change theme** button and you’ll be taken to a screen that shows you other available themes. When you click on the **Use theme** button under a theme name, your Moodle site will use that theme to display all of your site’s content. You can also choose different themes for different devices, like tablets or phones.

Now that you’ve got your Moodle site closer to how you want it to look, it’s time to create your first course. Select **Site home** from the navigation menu. You’ll see an empty list of courses and an **Add a new course** button. Click that button to display a form that looks like the following figure:

![Course Creation Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/moodle_ubuntu_1604/L8A6scz.png)

Fill in the information about your course, including the name, short name, a description, and any other relevant details. Then scroll to the bottom and click **Save and display**.

Your first Moodle course is now ready to go. You can start adding lessons and activities to the course using Moodle’s interface.

But before you start letting people sign up to take your new course, you should ensure your Moodle installation is ready for production. For starters, you’ll want to set up a TSL/SSL certificate for Apache to encrypt the traffic between your server and clients. To do that, follow the tutorial [How To Secure Apache with Let’s Encrypt on Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04). And to make sure your data is protected, ensure that you [back up your MySQL database](how-to-backup-mysql-databases-on-an-ubuntu-vps) periodically. You should also back up the files on the server, including the `/var/moodledata/` folder. The tutorial [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps) offers suggestions for backing up files.

## Conclusion

In this article you installed and set up Moodle on an Ubuntu 16.04 server. Moodle is a robust and highly configurable web application. Be sure to consult the Moodle documentation and get in touch with the worldwide community of Moodle users and administrators for ideas about how to make the most of it. Happy Moodling!
