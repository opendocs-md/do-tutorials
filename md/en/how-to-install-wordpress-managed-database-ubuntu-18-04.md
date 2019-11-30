---
author: Mark Drake
date: 2019-08-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-managed-database-ubuntu-18-04
---

# How To Install WordPress with a Managed Database on Ubuntu 18.04

_A previous version of this tutorial was written by [Justin Ellingwood](https://www.digitalocean.com/community/users/jellingwood)_

## Introduction

[WordPress](https://wordpress.org/) is the most popular CMS (content management system) on the internet. It’s a great choice for getting a website up and running quickly, and after the initial setup, almost all administration can be done through the web frontend.

WordPress is designed to pull content – including posts, comments, user profiles, and other data – from a database backend. As a website grows and must satisfy more and more traffic, it can eventually outgrow its initial database. To resolve this, one can scale up their database by migrating their data to a machine with more RAM or CPU, but this is a tedious process that runs the risk of data loss or corruption. This is why some WordPress developers choose to build their websites on [managed databases](understanding-managed-databases), which allow users to scale their database automatically with a far lower risk of data loss.

In this guide, we’ll focus on setting up a WordPress instance with a managed [MySQL](https://www.mysql.com/) database and an Ubuntu 18.04 server. This will require you to install [PHP](https://www.php.net/) and [Apache](https://httpd.apache.org/) to serve the content over the web.

## Prerequisites

In order to complete this tutorial, you will need:

- **Access to an Ubuntu 18.04 server** : This server should have a non- **root** sudo-enabled user and a firewall configured. You can set this up by following our [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04).
- **A managed MySQL database** : To provision a Managed MySQL Database from DigitalOcean, see our [Managed Databases product documentation](https://www.digitalocean.com/docs/databases/mysql/quickstart/#create-mysql-database-clusters). Note that this guide will refer to DigitalOcean Managed Databases in examples, but the instructions provided here should also generally work for managed MySQL databases from other cloud providers.
- **A LAMP stack installed on your server** : In addition to a database, WordPress requires a web server and PHP to function correctly. Setting up a complete LAMP stack (Linux, Apache, MySQL, and PHP) fulfills all of these requirements. Follow [this guide](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) to install and configure this software. As you follow this guide, make sure that you [set up a virtual host](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04#step-4-%E2%80%94-setting-up-virtual-hosts-(recommended)) to point to a domain name that you own. Additionally, be sure to **skip Step 2** , as installing `mysql-server` on your machine will make your managed database instance redundant.
- **TLS/SSL security implemented for your site** : If you have a domain name, the easiest way to secure your site is with Let’s Encrypt, which provides free, trusted certificates. Follow our [Let’s Encrypt guide for Apache](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) to set this up. Note that this will also require you to obtain a domain name and set up DNS records on your server. Follow [this introduction to DigitalOcean DNS](https://www.digitalocean.com/docs/networking/dns/) for details on how to configure this. Altneratively, if you don’t have a domain name, you [use a self-signed certificate](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-18-04) for your site.

When you are finished with the setup steps, log into your server as your non- **root** user and continue below.

## Step 1 – Adding the MySQL Software Repository and Installing `mysql-client`

In order to configure your managed MySQL instance, you will need to install a client that will allow you to access the database from your server. This step will walk you through the process of installing the `mysql-client` package.

In many cases, you can just install `mysql-client` with the `apt` command, but if you’re using the default Ubuntu repositories this will install version 5.7 of the program. In order to access a DigitalOcean Managed MySQL database, you will need to install version 8.0 or above. To do so, you must first add the MySQL software repository before installing the package.

Begin by navigating to [the **MySQL APT Repository** page](https://dev.mysql.com/downloads/repo/apt/) in your web browser. Find the **Download** button in the lower-right corner and click through to the next page. This page will prompt you to log in or sign up for an Oracle web account. You can skip that and instead look for the link that says **No thanks, just start my download**. Right-click the link and select **Copy Link Address** (this option may be worded differently, depending on your browser).

Now you’re ready to download the file. On your server, move to a directory you can write to:

    cd /tmp

Download the file using `curl`, remembering to paste the address you just copied in place of the highlighted portion of the following command. You also need to pass two command line flags to `curl`. `-O` instructs `curl` to output to a file instead of standard output. The `L` flag makes `curl` follow HTTP redirects, which is necessary in this case because the address you copied actually redirects to another location before the file downloads:

    curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb

The file should now be downloaded in your current directory. List the files to make sure:

    ls

You will see the filename listed in the output:

    Outputmysql-apt-config_0.8.13-1_all.deb
    . . .

Now you can add the MySQL APT repository to your system’s repository list. The `dpkg` command is used to install, remove, and inspect `.deb` software packages. The following command includes the `-i` flag, indicating that you’d like to install from the specified file:

    sudo dpkg -i mysql-apt-config*

During the installation, you’ll be presented with a configuration screen where you can specify which version of MySQL you’d prefer, along with an option to install repositories for other MySQL-related tools. The defaults will add the repository information for the latest stable version of MySQL and nothing else. This is what we want, so use the down arrow to navigate to the `Ok` menu option and hit `ENTER`.

![Selecting mysql-apt-config configuration options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pma_managed_db/dpkg_mysql_apt_config_alt2.png)

Following that, the package will finish adding the repository. Refresh your `apt` package cache to make the new software packages available:

    sudo apt update

Next, you can clean up your system a bit and delete the file you downloaded, as you won’t need it in the future:

    rm mysql-apt-config*

**Note:** If you ever need to update the configuration of these repositories, just run the following command to select your new options:

    sudo dpkg-reconfigure mysql-apt-config

After selecting your new options, run the following command to refresh your package cache:

    sudo apt update

Now that you’ve added the MySQL repositories, you’re ready to install the actual MySQL client software. Do so with the following `apt` command:

    sudo apt install mysql-client

Once that command finishes, check the software version number to ensure that you have the latest release:

    mysql --version

    Outputmysql Ver 8.0.17-cluster for Linux on x86_64 (MySQL Community Server - GPL)

You’re now able to connect to your managed database and begin preparing it to function with WordPress.

## Step 2 – Creating a MySQL Database and User for WordPress

WordPress uses MySQL to manage and store site and user information. Assuming you have completed all the [prerequisite tutorials](how-to-install-wordpress-managed-database-ubuntu-18-04#prerequisites), you will have already provisioned a managed MySQL instance. Here, we’ll take the preparatory step of creating a database and a user for WordPress to use.

Most managed database providers provide a [_uniform resource identifier_](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier) (URI) used for connecting to the database instance. If you’re using a DigitalOcean Managed Database, you can find the relevant connection information in your Cloud Control Panel.

First, click **Databases** in the left-hand sidebar menu and select the MySQL database you want to use for your WordPress installation. Scroll down to the **Connection Details** section and copy the link in the **host** field. Then paste this link into the following command, replacing `host_uri` with the information you just copied. Likewise, copy the port number in the **port** field – which will be `25060` on a DigitalOcean Managed Database – and replace `port` with that number. Additionally, if this is your first time connecting to your managed database and you’ve not created your own administrative MySQL user, copy the value in the **username** field and paste it into the command, replacing `user`:

    mysql -u user -p -h host_uri -P port

This command includes the `-p` flag, which will prompt you for the password of the MySQL user you specified. For a DigitalOcean Managed Database’s default **doadmin** user, you can find this by clicking the **show** link in the **Connection Details** section to reveal the password. Copy and paste it into your terminal when prompted.

**Note:** If you are not using a DigitalOcean Managed Database, your connection options may differ. If that’s the case, you should consult your provider’s documentation for instructions on connecting third party applications to your database.

From the MySQL prompt, create a new database that WordPress will control. You can call this whatever you would like, but we will use the name **wordpress** in this guide to keep it simple. Create the database for WordPress by typing:

    CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

**Note:** Every MySQL statement must end in a semi-colon (`;`). Check to make sure this is present if you are running into any issues.

Next, create a new MySQL user account that you will use exclusively to operate on the new database. Creating single-purpose databases and accounts is a good idea from a management and security standpoint. We will use the name **wordpressuser** in this guide, but feel free to change this if you’d like.

Run the following command, but replace `your_server_ip` with your Ubuntu server’s IP address. Be aware, though, that this will limit **wordpressuser** to only be able to connect from your LAMP server; if you plan to manage WordPress from your local computer, you should enter that machine’s IP address instead. Additionally, be sure to choose a strong password for your database user.

Notice that this command specifies that **wordpressuser** will use the `mysql_native_password` plugin to authenticate. In MySQL 8.0 and later, the default authentication plugin is `caching_sha2_password`, which is generally considered to be more secure than `mysql_native_password`. As of this writing, though, PHP does not support `caching_sha2_password`, which is why we specify `mysql_native_password` in this command:

    CREATE USER 'wordpressuser'@your_server_ip IDENTIFIED WITH mysql_native_password BY 'password';

**Note** : If you do not know what your server’s public IP address is, there are a number of ways you can find it. Usually, this is the address you use to connect to your server through SSH.

One method is to use the `curl` utility to contact an outside party to tell you how _it_ sees your server. For example, you can use `curl` to contact an IP-checking tool like ICanHazIP:

    curl http://icanhazip.com

This command will return your server’s public IP address in your output.

Then grant this user access to the database you just created. Do so by running the following command:

    GRANT ALL ON wordpress.* TO 'wordpressuser'@your_server_ip;

You now have a database and user account, each made specifically for WordPress. Go ahead and exit out of MySQL by typing:

    exit

That takes care of configuring your managed MySQL database to function with WordPress. In the next step, you will install a few PHP extensions in order to get more functionality out of the CMS.

## Step 3 – Installing Additional PHP Extensions

Assuming you followed the [prerequisite LAMP stack tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04), you will have installed a few extensions intended to get PHP to properly communicate with MySQL. WordPress and many of its plugins leverage additional PHP extensions to add additional functionalities.

To download and install some of the more popular PHP extensions for use with WordPress, run the following command:

    sudo apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip

**Note:** Each WordPress plugin has its own set of requirements. Some may require you to install additional PHP packages. Check your plugin documentation to see which extensions it requires. If they are available, they can be installed with `apt` as demonstrated above.

You will restart Apache to load these new extensions in the next section. If you’re returning here to install additional plugins, though, you can restart Apache now by typing:

    sudo systemctl restart apache2

Otherwise, continue on to Step 4.

## Step 4 – Adjusting Apache’s Configuration to Allow for .htaccess Overrides and Rewrites

In order for Apache to be able to properly serve your WordPress installation, you must make a few minor adjustments to your Apache configuration.

If you followed the prerequisite tutorials, you should already have a configuration file for your site in the `/etc/apache2/sites-available/` directory. We’ll use `/etc/apache2/sites-available/your_domain.conf` as an example here, **but you should substitute the path to your configuration file where appropriate**.

Additionally, we will use `/var/www/your_domain` as the root directory in this example WordPress install. **You should use the web root specified in your own configuration**.

**Note:** It’s possible you are using the `000-default.conf` default configuration (with `/var/www/html` as your web root). This is fine to use if you’re only going to host one website on this server. If not, it’s best to split the necessary configuration into logical chunks, one file per site.

Currently, the use of `.htaccess` files is disabled. WordPress and many WordPress plugins use these files extensively for in-directory tweaks to the web server’s behavior.

Open the Apache configuration file for your website:

    sudo nano /etc/apache2/sites-available/your_domain.conf

To allow `.htaccess` files, you need to set the `AllowOverride` directive within a `Directory` block pointing to your document root. Add the following block of text inside the `VirtualHost` block in your configuration file, being sure to use the correct web root directory:

/etc/apache2/sites-available/your\_domain.conf

    <Directory /var/www/your_domain>
        AllowOverride All
    </Directory>

When you are finished, save and close the file.

Next, enable `mod_rewrite` so that you can employ the WordPress permalink feature:

    sudo a2enmod rewrite

Before implementing the changes you’ve just made, check to make sure there aren’t any syntax errors in your configuration file:

    sudo apache2ctl configtest

The output might have a message that looks like this:

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

If you wish to suppress the top line, just add a `ServerName` directive to your main (global) Apache configuration file at `/etc/apache2/apache2.conf`. The `ServerName` can be your server’s domain or IP address. However, this is just a message; it doesn’t affect the functionality of your site and as long as the output contains `Syntax OK`, you’re all set to continue.

Restart Apache to implement the changes:

    sudo systemctl restart apache2

With that, you’re ready to download and set up WordPress itself.

## Step 5 – Downloading WordPress

Now that your server software is configured, you can install and configure WordPress. For security reasons, it is always recommended to get the latest version of WordPress from their site.

First, navigate to into a writable directory. `/tmp` will work for the purposes of this step:

    cd /tmp

Then download the compressed release by typing:

    curl -O https://wordpress.org/latest.tar.gz

Extract the compressed file to create the WordPress directory structure:

    tar xzvf latest.tar.gz

You will move these files into your document root momentarily. Before doing so, add a dummy `.htaccess` file so that this will be available for WordPress to use later.

Create the file by typing:

    touch /tmp/wordpress/.htaccess

Also, copy over the sample configuration file to the filename that WordPress actually reads:

    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

Create an `upgrade` directory, so that WordPress won’t run into permissions issues when trying to do this on its own following an update to its software:

    mkdir /tmp/wordpress/wp-content/upgrade

Then copy the entire contents of the directory into your document root. The following command uses a period at the end of the source directory to indicate that everything within the directory should be copied, including hidden files (like the `.htaccess` file you just created):

    sudo cp -a /tmp/wordpress/. /var/www/your_domain

That takes care of downloading WordPress onto your server. At this point, though, you still won’t be able to access the WordPress setup interface in your browser. To fix that, you’ll need to make a few changes to your server’s WordPress configuration.

## Step 6 – Configuring the WordPress Directory

Before going through the web-based WordPress setup, you need to adjust some items in your WordPress directory. One important configuration change involves setting up reasonable file permissions and ownership.

Start by giving ownership of all the files to the **www-data** user and group. This is the user that the Apache web server runs as on Debian and Ubuntu systems, and Apache will need to be able to read and write WordPress files in order to serve the website and perform automatic updates.

Update the ownership of your web root directory with `chown`:

    sudo chown -R www-data:www-data /var/www/your_domain

Next run the following two `find` commands to set the correct permissions on the WordPress directories and files:

    sudo find /var/www/your_domain/ -type d -exec chmod 750 {} \;
    sudo find /var/www/your_domain/ -type f -exec chmod 640 {} \;

These should be a reasonable permissions set to start with. Be aware, though, that some plugins and procedures might require additional updates.

Now, you need to make some changes to the main WordPress configuration file.

When you open the file, the first order of business will be to replace some secret keys to provide security for your installation. WordPress provides a secure generator for these values so that you do not have to try to come up with good values on your own. These are only used internally, so it won’t hurt usability to have complex, secure values here.

To grab secure values from the WordPress secret key generator, run the following command:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

You will get back unique values that look something like this:

**Warning!** It is important that you request unique values each time. Do **NOT** copy the values shown here!

    Outputdefine('AUTH_KEY', '1jl/vqfs<XhdXoAPz9 DO NOT COPY THESE VALUES c_j{iwqD^<+c9.k<J@4H');
    define('SECURE_AUTH_KEY', 'E2N-h2]Dcvp+aS/p7X DO NOT COPY THESE VALUES {Ka(f;rv?Pxf})CgLi-3');
    define('LOGGED_IN_KEY', 'W(50,{W^,OPB%PB<JF DO NOT COPY THESE VALUES 2;y&,2m%3]R6DUth[;88');
    define('NONCE_KEY', 'll,4UC)7ua+8<!4VM+ DO NOT COPY THESE VALUES #`DXF+[$atzM7 o^-C7g');
    define('AUTH_SALT', 'koMrurzOA+|L_lG}kf DO NOT COPY THESE VALUES 07VC*Lj*lD&?3w!BT#-');
    define('SECURE_AUTH_SALT', 'p32*p,]z%LZ+pAu:VY DO NOT COPY THESE VALUES C-?y+K0DK_+F|0h{!_xY');
    define('LOGGED_IN_SALT', 'i^/G2W7!-1H2OQ+t$3 DO NOT COPY THESE VALUES t6**bRVFSD[Hi])-qS`|');
    define('NONCE_SALT', 'Q6]U:K?j4L%Z]}h^q7 DO NOT COPY THESE VALUES 1% ^qUswWgn+6&xqHN&%');

These are configuration lines that you can paste directly into your configuration file to set secure keys. Copy the output you received now.

Then, open the WordPress configuration file:

    sudo nano /var/www/your_domain/wp-config.php

Find the section that contains the dummy values for those settings. It will look something like this:

/var/www/your\_domain/wp-config.php

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

/var/www/your\_domain/wp-config.php

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

Next you need to modify some of the database connection settings at the beginning of the file. First, update the `'DB_NAME'`, `'DB_USER'`, and `'DB_PASSWORD'` fields to point to the database name, database user, and the associated password that you configured within MySQL:

/var/www/your\_domain/wp-config.php

    . . .
    /** The name of the database for WordPress */
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    . . .

You will also need to replace `localhost` in the `'DB_HOST'` field with your managed database’s host. Additionally, append a colon (`:`) and your database’s port number to the host:

/var/www/wordpress/wp-config.php

    . . .
    
    /** MySQL hostname */
    define( 'DB_HOST', 'managed_database_host:managed_database_port' );
    
    . . .

The last change you need to make is to set the method that WordPress will use to write to the filesystem. Since you’ve already given the web server permission to write where it needs to, you can explicitly set the filesystem method to `direct` port. Failure to set this with your current settings would result in WordPress prompting for FTP credentials when you perform certain actions.

This setting can be added below the database connection settings, or anywhere else in the file:

/var/www/your\_domain/wp-config.php

    . . .
    
    define('FS_METHOD', 'direct');
    . . .

Save and close the file when you are finished.

After making those changes, you’re all set to finish the process of installing WordPress in your web browser. However, there’s one more step that we recommend you complete to add an extra layer of security to your configuration.

## Step 7 – (Recommended) Configuring WordPress to Communicate with MySQL Over TLS/SSL

At this point, your WordPress installation is communicating with your managed MySQL database. However, there’s no guarantee that data transfers between the two machines are secure. In this step, we will configure WordPress to communicate with your MySQL instance over a TLS/SSL connection to ensure secure communications between the two machines.

To do so, you’ll need your managed database’s CA certificate. For a DigitalOcean Managed Database, you can find this by once again navigating to the **Databases** tab in your **Control Panel**. Click on your database, and find the **Connection Details** section. There will be a button there that reads **Download the CA certificate**. Click this button to download the certificate to your local machine.

Then transfer this file to your WordPress server. If your local machine is running Linux or macOS, you can use a tool like `scp`:

    scp /path/to/file/ca-certificate.crt sammy@your_server_ip:/tmp

If your local machine is running Windows, you can use an alternative tool like [WinSCP](https://winscp.net/eng/index.php).

Once the CA certificate is on your server, move it to the `/user/local/share/ca-certificates/` directory, Ubuntu’s trusted certificate store:

    sudo mv /tmp/ca-certificate.crt /usr/local/share/ca-certificates/

Following this, run the `update-ca-certificates` command. This program looks for certificates within `/usr/local/share/ca-certificates`, adds any new ones to the `/etc/ssl/certs/` directory, and generates a list of trusted SSL certificates based on its contents:

    sudo update-ca-certificates

Then, reopen your `wp-config.php` file:

    nano /var/www/your_domain/wp-config.php

Somewhere in the file, add the following line:

/var/www/your\_domain/wp-config.php

    . . .
    define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);
    . . .

Save and close the file.

Following that, WordPress will securely communicate with your managed MySQL database.

## Step 8 – Completing the Installation Through the Web Interface

Now that the server configuration is complete, you can complete the installation through the WordPress web interface.

In your web browser, navigate to your server’s domain name or public IP address:

    https://server_domain_or_IP

Assuming there aren’t any errors in your WordPress or Apache configurations, you’ll see the WordPress language selection splash page. Select the language you would like to use:

![WordPress language selection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/language_selection.png)

After selecting your language, you will see the main setup page.

Select a name for your WordPress site and choose a username (it is recommended not to choose something like “admin” for security purposes). A strong password is generated automatically. Save this password or enter an alternative strong password.

Enter your email address and select whether you want to discourage search engines from indexing your site:

![WordPress setup installation](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/setup_installation.png)

When you click ahead, you will be taken to a page that prompts you to log in:

![WordPress login prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/login_prompt.png)

Once you log in, you will be taken to the WordPress administration dashboard:

![WordPress login prompt](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/admin_screen.png)

From here, you can begin customizing your new WordPress site and start publishing content. If this is your first time using WordPress, we encourage you to explore the interface a bit to get acquainted with your new CMS.

## Conclusion

By completing this guide, you will have WordPress installed and ready to use on your server. Additionally, your WordPress installation is dynamically pulling posts, pages, and other content from your managed MySQL database.

Some common next steps are to choose the permalinks setting for your posts. This setting can be found under **Settings** \> **Permalinks**. You could also select a new theme in **Appearance** \> **Themes**. Once you start loading some content into your site, you could also [configure a CDN to speed up your site’s asset delivery](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn).
