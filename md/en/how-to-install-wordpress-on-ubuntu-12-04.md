---
author: Etel Sverdlov
date: 2012-06-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-on-ubuntu-12-04
---

# How To Install Wordpress on Ubuntu 12.04

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

### What the Red Means

The lines that the user needs to enter or customize will be in red in this tutorial! The rest should mostly be copy-and-pastable.

### About Wordpress

Wordpress is a free and open source website and blogging tool that uses php and MySQL. It was created in 2003 and has since then expanded to manage 22% of all the new websites created and has over 20,000 plugins to customize its functionality.

## Setup

The steps in this tutorial require the user to have root privileges. You can see how to set that up in the [Initial Server Setup.](https://www.DigitalOcean.com/community/articles/initial-server-setup-with-ubuntu-12-04)

Before working with wordpress, you need to have LAMP installed on your virtual private server. If you don't have the Linux, Apache, MySQL, PHP stack on your VPS, you can find the tutorial for setting it up in the [Ubuntu LAMP tutorial](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu).

Once you have the user and required software, you can start installing wordpress!

## Step One—Download WordPress

We can download Wordpress straight from their website:

    wget http://wordpress.org/latest.tar.gz

This command will download the zipped wordpress package straight to your user's home directory. You can unzip it the the next line:

    tar -xzvf latest.tar.gz 

## Step Two—Create the WordPress Database and User

After we unzip the wordpress files, they will be in a directory called wordpress in the home directory.

Now we need to switch gears for a moment and create a new MySQL directory for wordpress.

Go ahead and log into the MySQL Shell:

    mysql -u root -p

Login using your MySQL root password, and then we need to create a wordpress database, a user in that database, and give that user a new password. Keep in mind that all MySQL commands must end with semi-colon.

First, let's make the database (I'm calling mine wordpress for simplicity's sake; feel free to give it whatever name you choose):

    CREATE DATABASE wordpress; Query OK, 1 row affected (0.00 sec)

Then we need to create the new user. You can replace the database, name, and password, with whatever you prefer:

    CREATE USER wordpressuser@localhost; Query OK, 0 rows affected (0.00 sec)

Set the password for your new user:

    SET PASSWORD FOR wordpressuser@localhost= PASSWORD("password"); Query OK, 0 rows affected (0.00 sec)

Finish up by granting all privileges to the new user. Without this command, the wordpress installer will not be able to start up:

    GRANT ALL PRIVILEGES ON wordpress.\* TO wordpressuser@localhost IDENTIFIED BY 'password'; Query OK, 0 rows affected (0.00 sec)

Then refresh MySQL:

    FLUSH PRIVILEGES; Query OK, 0 rows affected (0.00 sec)

Exit out of the MySQL shell:

    exit

## Step Three—Setup the WordPress Configuration

The first step to is to copy the sample wordpress configuration file, located in the wordpress directory, into a new file which we will edit, creating a new usable wordpress config:

    cp ~/wordpress/wp-config-sample.php ~/wordpress/wp-config.php

Then open the wordpress config:

    sudo nano ~/wordpress/wp-config.php

Find the section that contains the field below and substitute in the correct name for your database, username, and password:

    // \*\* MySQL settings - You can get this info from your web host \*\* // /\*\* The name of the database for WordPress \*/ define('DB\_NAME', 'wordpress'); /\*\* MySQL database username \*/ define('DB\_USER', 'wordpressuser'); /\*\* MySQL database password \*/ define('DB\_PASSWORD', 'password');

Save and Exit.

## Step Four—Copy the Files

We are almost done uploading Wordpress to the virtual private server. The final move that remains is to transfer the unzipped WordPress files to the website's root directory.

    sudo rsync -avP ~/wordpress/ /var/www/

Finally we need to set the permissions on the installation. First, switch in to the web directory:

    cd /var/www/

Give ownership of the directory to the apache user.

    sudo chown username:www-data /var/www -R sudo chmod g+w /var/www -R 

From here, WordPress has its own easy to follow installation form online.

However, the form does require a specific php module to run. If it is not yet installed on your server, download php-gd:

    sudo apt-get install php5-gd

## Step Five—RESULTS: Access the WordPress Installation

Once that is all done, the wordpress online installation page is up and waiting for you:

Access the page by adding /wp-admin/install.php to your site's domain or IP address (eg. example.com/wp-admin/install.php) and fill out the short online form (it should look like [this](https://assets.digitalocean.com/tutorial_images/P6Jgw.png)).

## See More

Once Wordpress is installed, you have a strong base for building your site.

If you want to encrypt the information on your site, you can [Install an SSL Certificate](https://www.digitalocean.com/community/articles/how-to-create-a-ssl-certificate-on-apache-for-ubuntu-12-04)

By Etel Sverdlov
