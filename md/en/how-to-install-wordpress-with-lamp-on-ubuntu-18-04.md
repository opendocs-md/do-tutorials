---
author: Brian Boucheron
date: 2018-07-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-with-lamp-on-ubuntu-18-04
---

# How To Install WordPress with LAMP on Ubuntu 18.04

_A previous version of this tutorial was written by [Justin Ellingwood](https://www.digitalocean.com/community/users/jellingwood)_

## Introduction

WordPress is the most popular CMS (content management system) on the internet. It allows you to easily set up flexible blogs and websites on top of a MySQL backend with PHP processing. WordPress has seen incredible adoption and is a great choice for getting a website up and running quickly. After setup, almost all administration can be done through the web frontend.

In this guide, we’ll focus on getting a WordPress instance set up on a LAMP stack (Linux, Apache, MySQL, and PHP) on an Ubuntu 18.04 server.

## Prerequisites

In order to complete this tutorial, you will need access to an Ubuntu 18.04 server.

You will need to perform the following tasks before you can start this guide:

- **Create a `sudo` user on your server** : We will be completing the steps in this guide using a non-root user with `sudo` privileges. You can create a user with `sudo` privileges by following our [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04).
- **Install a LAMP stack** : WordPress will need a web server, a database, and PHP in order to correctly function. Setting up a LAMP stack (Linux, Apache, MySQL, and PHP) fulfills all of these requirements. Follow [this guide](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) to install and configure this software.
- **Secure your site with SSL** : WordPress serves dynamic content and handles user authentication and authorization. TLS/SSL is the technology that allows you to encrypt the traffic from your site so that your connection is secure. The way you set up SSL will depend on whether you have a domain name for your site.
  - **If you have a domain name…** the easiest way to secure your site is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Apache](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) to set this up.
  - **If you do not have a domain…** and you are just using this configuration for testing or personal use, you can use a self-signed certificate instead. This provides the same type of encryption, but without the domain validation. Follow our [self-signed SSL guide for Apache](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-18-04) to get set up.

When you are finished with the setup steps, log into your server as your `sudo` user and continue below.

## Step 1 – Creating a MySQL Database and User for WordPress

The first step that we will take is a preparatory one. WordPress uses MySQL to manage and store site and user information. We have MySQL installed already, but we need to make a database and a user for WordPress to use.

To get started, log into the MySQL root (administrative) account by issuing this command:

    mysql -u root -p

You will be prompted for the password you set for the MySQL root account when you installed the software.

First, we can create a separate database that WordPress will control. You can call this whatever you would like, but we will be using **wordpress** in this guide to keep it simple. Create the database for WordPress by typing:

    CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

**Note:** Every MySQL statement must end in a semi-colon (;). Check to make sure this is present if you are running into any issues.

Next, we are going to create a separate MySQL user account that we will use exclusively to operate on our new database. Creating one-function databases and accounts is a good idea from a management and security standpoint. We will use the name **wordpressuser** in this guide. Feel free to change this if you’d like.

We are going to create this account, set a password, and grant access to the database we created. We can do this by typing the following command. Remember to choose a strong password here for your database user:

    GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';

You now have a database and user account, each made specifically for WordPress. We need to flush the privileges so that the current instance of MySQL knows about the recent changes we’ve made:

    FLUSH PRIVILEGES;

Exit out of MySQL by typing:

    EXIT;

## Step 2 – Installing Additional PHP Extensions

When setting up our LAMP stack, we only required a very minimal set of extensions in order to get PHP to communicate with MySQL. WordPress and many of its plugins leverage additional PHP extensions.

We can download and install some of the most popular PHP extensions for use with WordPress by typing:

    sudo apt update
    sudo apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

**Note:** Each WordPress plugin has its own set of requirements. Some may require additional PHP packages to be installed. Check your plugin documentation to discover its PHP requirements. If they are available, they can be installed with `apt` as demonstrated above.

We will restart Apache to load these new extensions in the next section. If you are returning here to install additional plugins, you can restart Apache now by typing:

    sudo systemctl restart apache2

## Step 3 – Adjusting Apache’s Configuration to Allow for .htaccess Overrides and Rewrites

Next, we will be making a few minor adjustments to our Apache configuration. Based on the prerequisite tutorials, you should have a configuration file for your site in the `/etc/apache2/sites-available/` directory. We’ll use `/etc/apache2/sites-available/wordpress.conf` as an example here, but you should substitute the path to your configuration file where appropriate.

Additionally, we will use `/var/www/wordpress` as the root directory of our WordPress install. You should use the web root specified in your own configuration.

**Note:** It’s possible you are using the `000-default.conf` default configuration (with `/var/www/html` as your web root). This is fine to use if you’re only going to host one website on this server. If not, it’s best to split the necessary configuration into logical chunks, one file per site.

### Enabling .htaccess Overrides

Currently, the use of `.htaccess` files is disabled. WordPress and many WordPress plugins use these files extensively for in-directory tweaks to the web server’s behavior.

Open the Apache configuration file for your website:

    sudo nano /etc/apache2/sites-available/wordpress.conf

To allow `.htaccess` files, we need to set the `AllowOverride` directive within a `Directory` block pointing to our document root. Add the following block of text inside the `VirtualHost` block in your configuration file, being sure to use the correct web root directory:

/etc/apache2/sites-available/wordpress.conf

    <Directory /var/www/wordpress/>
        AllowOverride All
    </Directory>

When you are finished, save and close the file.

### Enabling the Rewrite Module

Next, we can enable `mod_rewrite` so that we can utilize the WordPress permalink feature:

    sudo a2enmod rewrite

### Enabling the Changes

Before we implement the changes we’ve made, check to make sure we haven’t made any syntax errors:

    sudo apache2ctl configtest

The output might have a message that looks like this:

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

If you wish to suppress the top line, just add a `ServerName` directive to your main (global) Apache configuration file at `/etc/apache2/apache2.conf`. The `ServerName` can be your server’s domain or IP address. This is just a message however and doesn’t affect the functionality of our site. As long as the output contains `Syntax OK`, you are ready to continue.

Restart Apache to implement the changes:

    sudo systemctl restart apache2

Next, we will download and set up WordPress itself.

## Step 4 – Downloading WordPress

Now that our server software is configured, we can download and set up WordPress. For security reasons in particular, it is always recommended to get the latest version of WordPress from their site.

Change into a writable directory and then download the compressed release by typing:

    cd /tmp
    curl -O https://wordpress.org/latest.tar.gz

Extract the compressed file to create the WordPress directory structure:

    tar xzvf latest.tar.gz

We will be moving these files into our document root momentarily. Before we do, we can add a dummy `.htaccess` file so that this will be available for WordPress to use later.

Create the file by typing:

    touch /tmp/wordpress/.htaccess

We’ll also copy over the sample configuration file to the filename that WordPress actually reads:

    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

We can also create the `upgrade` directory, so that WordPress won’t run into permissions issues when trying to do this on its own following an update to its software:

    mkdir /tmp/wordpress/wp-content/upgrade

Now, we can copy the entire contents of the directory into our document root. We are using a dot at the end of our source directory to indicate that everything within the directory should be copied, including hidden files (like the `.htaccess` file we created):

    sudo cp -a /tmp/wordpress/. /var/www/wordpress

## Step 5 – Configuring the WordPress Directory

Before we do the web-based WordPress setup, we need to adjust some items in our WordPress directory.

### Adjusting the Ownership and Permissions

One of the big things we need to accomplish is setting up reasonable file permissions and ownership.

We’ll start by giving ownership of all the files to the **www-data** user and group. This is the user that the Apache webserver runs as, and Apache will need to be able to read and write WordPress files in order to serve the website and perform automatic updates.

Update the ownership with `chown`:

    sudo chown -R www-data:www-data /var/www/wordpress

Next we will run two `find` commands to set the correct permissions on the WordPress directories and files:

    sudo find /var/www/wordpress/ -type d -exec chmod 750 {} \;
    sudo find /var/www/wordpress/ -type f -exec chmod 640 {} \;

These should be a reasonable permissions set to start with. Some plugins and procedures might require additional tweaks.

### Setting up the WordPress Configuration File

Now, we need to make some changes to the main WordPress configuration file.

When we open the file, our first order of business will be to adjust some secret keys to provide some security for our installation. WordPress provides a secure generator for these values so that you do not have to try to come up with good values on your own. These are only used internally, so it won’t hurt usability to have complex, secure values here.

To grab secure values from the WordPress secret key generator, type:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

You will get back unique values that look something like this:

**Warning!** It is important that you request unique values each time. Do **NOT** copy the values shown below!

    Outputdefine('AUTH_KEY', '1jl/vqfs<XhdXoAPz9 DO NOT COPY THESE VALUES c_j{iwqD^<+c9.k<J@4H');
    define('SECURE_AUTH_KEY', 'E2N-h2]Dcvp+aS/p7X DO NOT COPY THESE VALUES {Ka(f;rv?Pxf})CgLi-3');
    define('LOGGED_IN_KEY', 'W(50,{W^,OPB%PB<JF DO NOT COPY THESE VALUES 2;y&,2m%3]R6DUth[;88');
    define('NONCE_KEY', 'll,4UC)7ua+8<!4VM+ DO NOT COPY THESE VALUES #`DXF+[$atzM7 o^-C7g');
    define('AUTH_SALT', 'koMrurzOA+|L_lG}kf DO NOT COPY THESE VALUES 07VC*Lj*lD&?3w!BT#-');
    define('SECURE_AUTH_SALT', 'p32*p,]z%LZ+pAu:VY DO NOT COPY THESE VALUES C-?y+K0DK_+F|0h{!_xY');
    define('LOGGED_IN_SALT', 'i^/G2W7!-1H2OQ+t$3 DO NOT COPY THESE VALUES t6**bRVFSD[Hi])-qS`|');
    define('NONCE_SALT', 'Q6]U:K?j4L%Z]}h^q7 DO NOT COPY THESE VALUES 1% ^qUswWgn+6&xqHN&%');

These are configuration lines that we can paste directly in our configuration file to set secure keys. Copy the output you received now.

Now, open the WordPress configuration file:

    sudo nano /var/www/wordpress/wp-config.php

Find the section that contains the dummy values for those settings. It will look something like this:

/var/www/wordpress/wp-config.php

    . . .
    
    define('AUTH_KEY', 'put your unique phrase here');
    define('SECURE_AUTH_KEY', 'put your unique phrase here');
    define('LOGGED_IN_KEY', 'put your unique phrase here');
    define('NONCE_KEY', 'put your unique phrase here');
    define('AUTH_SALT', 'put your unique phrase here');
    define('SECURE_AUTH_SALT', 'put your unique phrase here');
    define('LOGGED_IN_SALT', 'put your unique phrase here');
    define('NONCE_SALT', 'put your unique phrase here');
    
    . . .

Delete those lines and paste in the values you copied from the command line:

/var/www/wordpress/wp-config.php

    . . .
    
    define('AUTH_KEY', 'VALUES COPIED FROM THE COMMAND LINE');
    define('SECURE_AUTH_KEY', 'VALUES COPIED FROM THE COMMAND LINE');
    define('LOGGED_IN_KEY', 'VALUES COPIED FROM THE COMMAND LINE');
    define('NONCE_KEY', 'VALUES COPIED FROM THE COMMAND LINE');
    define('AUTH_SALT', 'VALUES COPIED FROM THE COMMAND LINE');
    define('SECURE_AUTH_SALT', 'VALUES COPIED FROM THE COMMAND LINE');
    define('LOGGED_IN_SALT', 'VALUES COPIED FROM THE COMMAND LINE');
    define('NONCE_SALT', 'VALUES COPIED FROM THE COMMAND LINE');
    
    . . .

Next, we need to modify some of the database connection settings at the beginning of the file. You need to adjust the database name, the database user, and the associated password that we configured within MySQL.

The other change we need to make is to set the method that WordPress should use to write to the filesystem. Since we’ve given the web server permission to write where it needs to, we can explicitly set the filesystem method to “direct”. Failure to set this with our current settings would result in WordPress prompting for FTP credentials when we perform some actions.

This setting can be added below the database connection settings, or anywhere else in the file:

/var/www/wordpress/wp-config.php

    . . .
    
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    . . .
    
    define('FS_METHOD', 'direct');

Save and close the file when you are finished.

## Step 6 – Completing the Installation Through the Web Interface

Now that the server configuration is complete, we can complete the installation through the web interface.

In your web browser, navigate to your server’s domain name or public IP address:

    https://server_domain_or_IP

Select the language you would like to use:

![WordPress language selection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/language_selection.png)

Next, you will come to the main setup page.

Select a name for your WordPress site and choose a username (it is recommended not to choose something like “admin” for security purposes). A strong password is generated automatically. Save this password or select an alternative strong password.

Enter your email address and select whether you want to discourage search engines from indexing your site:

![WordPress setup installation](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/setup_installation.png)

When you click ahead, you will be taken to a page that prompts you to log in:

![WordPress login prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/login_prompt.png)

Once you log in, you will be taken to the WordPress administration dashboard:

![WordPress login prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/admin_screen.png)

## Conclusion

WordPress should be installed and ready to use! Some common next steps are to choose the permalinks setting for your posts (can be found in `Settings > Permalinks`) or to select a new theme (in `Appearance > Themes`). If this is your first time using WordPress, explore the interface a bit to get acquainted with your new CMS.
