---
author: Justin Ellingwood
date: 2014-04-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-on-ubuntu-14-04
---

# How To Install Wordpress on Ubuntu 14.04

## Introduction

At this time, WordPress is the most popular CMS (content management system) on the internet. It allows you to easily set up flexible blogs and websites on top of a MySQL backend with PHP processing. WordPress has seen incredible adoption and is a great choice for getting a website up and running quickly.

In this guide, we’ll focus on getting a WordPress instance set up with an Apache web server on Ubuntu 14.04.

## Prerequisites

Before you begin this guide, there are some important steps that you need to complete on your server.

We will be proceeding through these steps as a non-root user with sudo privileges, so you will need to have one available. You can find out how to create a user with sudo privileges by following steps 1-4 in our [Ubuntu 14.04 initial server setup](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04) guide.

Additionally, you’ll need to have a LAMP (Linux, Apache, MySQL, and PHP) stack installed on your VPS instance. If you don’t have these components already installed and configured, you can use this guide to learn [how to install LAMP on Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04).

When you are finished with these steps, you can continue with this guide.

## Step One — Create a MySQL Database and User for WordPress

The first step that we will take is a preparatory one. WordPress uses a relational database to manage and store site and user information.

We have MySQL installed, which can provide this functionality, but we need to make a database and a user for WordPress to work with.

To get started, log into the MySQL root (administrative) account by issuing this command:

    mysql -u root -p

You will be prompted for the password you set for the MySQL root account when you installed the software. You will then be given a MySQL command prompt.

First, we can create a separate database that WordPress can control. You can call this whatever you would like, but I will be calling it `wordpress` because it is descriptive and simple. Enter this command to create the database:

    CREATE DATABASE wordpress;

Every MySQL statement must end in a semi-colon (;), so check to make sure this is present if you are running into any issues.

Next, we are going to create a separate MySQL user account that we will use exclusively to operate on our new database. Creating one-function databases and accounts is a good idea from a management and security standpoint.

I am going to call the new account that I’m making `wordpressuser` and will assign it a password of `password`. You should definitely change the password for your installation and can name the user whatever you’d like. This is the command you need to create the user:

    CREATE USER wordpressuser@localhost IDENTIFIED BY 'password';

At this point, you have a database and a user account, each made specifically for WordPress. However, these two components have no relationship yet. The user has no access to the database.

Let’s fix that by granting our user account access to our database with this command:

    GRANT ALL PRIVILEGES ON wordpress.\* TO wordpressuser@localhost;

Now the user has access to the database. We need to flush the privileges so that the current instance of MySQL knows about the recent privilege changes we’ve made:

    FLUSH PRIVILEGES;

We’re all set now. We can exit out of the MySQL prompt by typing:

    exit

You should now be back to your regular command prompt.

## Step Two — Download WordPress

Next, we will download the actual WordPress files from the project’s website.

Luckily, the WordPress team always links the most recent stable version of their software to the same URL, so we can get the most up-to-date version of WordPress by typing this:

    cd ~
    wget http://wordpress.org/latest.tar.gz

This will download a compressed file that contains the archived directory contents of the WordPress files to our home directory.

We can extract the files to rebuild the WordPress directory we need by typing:

    tar xzvf latest.tar.gz

This will create a directory called `wordpress` in your home directory.

While we are downloading things, we should also get a few more packages that we need. We can get these directly from Ubuntu’s default repositories after we update our local package index:

    sudo apt-get update
    sudo apt-get install php5-gd libssh2-php

This will allow you to work with images and will also allow you to install plugins and update portions of your site using your SSH login credentials.

## Step Three — Configure WordPress

Most of the configuration that we will be doing will be through a web interface later on. However, we do need to do some work from the command line before we can get this up and running.

Begin by moving into the WordPress directory that you just unpacked:

    cd ~/wordpress

A sample configuration file that mostly matches the configuration we need is included by default. However, we need to copy it to the default configuration file location to get WordPress to recognize the file. Do that now by typing:

    cp wp-config-sample.php wp-config.php

Now that we have a configuration file to work with, we can generate some secret keys that help to secure the installation. WordPress provides a secure generator for these values so that you do not have to try to come up with good values on your own. These are only used internally, so it won’t hurt usability to have complex, secure values here.

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

Next, let’s open the configuration file in a text editor:

    nano wp-config.php

Find the section that contains the dummy values for those settings. It will look something like this:

    . . .
    #define('AUTH_KEY', 'put your unique phrase here');
    #define('SECURE_AUTH_KEY', 'put your unique phrase here');
    #define('LOGGED_IN_KEY', 'put your unique phrase here');
    #define('NONCE_KEY', 'put your unique phrase here');
    #define('AUTH_SALT', 'put your unique phrase here');
    #define('SECURE_AUTH_SALT', 'put your unique phrase here');
    #define('LOGGED_IN_SALT', 'put your unique phrase here');
    #define('NONCE_SALT', 'put your unique phrase here');
    . . .

Delete those lines and paste in the values you copied from the command line:

/var/www/html/wp-config.php

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

After that, the only modifications we need to make are to the parameters that hold our database information.

We will need to find the settings for `DB_NAME`, `DB_USER`, and `DB_PASSWORD` in order for WordPress to correctly connect and authenticate to the database we created.

Fill in the values of these parameters with the information for the database you created. It should look like this:

    // \*\* MySQL settings - You can get this info from your web host \*\* // /\*\* The name of the database for WordPress \*/ define('DB\_NAME', 'wordpress'); /\*\* MySQL database username \*/ define('DB\_USER', 'wordpressuser'); /\*\* MySQL database password \*/ define('DB\_PASSWORD', 'password');

These are the only values that you need to change.

When you are finished, save and close the file.

## Step Four — Copy Files to the Document Root

Now that we have our application configured, we need to copy it into Apache’s document root, where it can be served to visitors of our website.

One of the easiest and most reliable way of transferring files from directory to directory is with the `rsync` command. This preserves permissions and has good data integrity features.

The location of the document root in [the Ubuntu 14.04 LAMP guide](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04) is `/var/www/html/`. We can transfer our WordPress files there by typing:

    sudo rsync -avP ~/wordpress/ /var/www/html/

This will safely copy all of the contents from the directory you unpacked to the document root.

We should now move into the document root to make some final permissions changes

    cd /var/www/html

You will need to change the ownership of our files for increased security.

We want to give user ownership to the regular, non-root user (with sudo privileges) that you plan on using to interact with your site. This can be your regular user if you wish, but some may suggest that you create an additional user for this process. It is up to you which you choose.

For this guide, we will use the same account that we set up during the [initial server setup](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04) guide, which we called `demo`. This is the account I am performing all of the actions of this guide as.

The group ownership we will give to our web server process, which is `www-data`. This will allow Apache to interact with the content as necessary.

We can quickly assign these ownership values by typing:

    sudo chown -R demo:www-data \*

This will set up the ownership properties that we are looking for.

While we are dealing with ownership and permissions, we should also look into assigning correct ownership on our uploads directory. This will allow us to upload images and other content to our site. Currently, the permissions are too restrictive.

First, let’s manually create the `uploads` directory beneath the `wp-content` directory at our document root. This will be the parent directory of our content:

    mkdir /var/www/html/wp-content/uploads

We have a directory now to house uploaded files, however the permissions are still too restrictive. We need to allow the web server itself to write to this directory. We can do this by assigning group ownership of this directory to our web server, like this:

    sudo chown -R :www-data /var/www/html/wp-content/uploads

This will allow the web server to create files and directories under this directory, which will permit us to upload content to the server.

## Step Five — Complete Installation through the Web Interface

Now that you have your files in place and your software is configured, you can complete the installation through the web interface.

In your web browser, navigate to your server’s domain name or public IP address:

    http://server\_domain\_name\_or\_IP

You will see the WordPress initial configuration page, where you will create an initial administrator account:

![Wordpress initial config](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/initial_config.png)

Fill out the information for the site and the administrative account you wish to make. When you are finished, click on the install button at the bottom.

WordPress will confirm the installation, and then ask you to log in with the account you just created:

![WordPress confirm install](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/confirm_install.png)

Hit the button at the bottom and then fill out your account information:

![WordPress login](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/login.png)

You will be presented with the WordPress interface:

![WordPress admin interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/admin_interface.png)

## Step Six (Optional) — Configure Pretty Permalinks for WordPress

By default, WordPress creates URLs dynamically that look something like this:

    http://server\_domain\_name\_or\_IP/?p=1

This isn’t exactly the most useful interface for visitors or search engines, so most users want to modify this. WordPress has the ability to create “pretty” permalinks which will clean up the URL into a more human-friendly format.

There are a few things we need to do to get this to work with Apache on Ubuntu 14.04.

### Modifying Apache to Allow URL Rewrites

First, we need to modify the Apache virtual host file for WordPress to allow for `.htaccess` overrides. You can do this by editing the virtual host file.

By default, this is `000-default.conf`, but your file might be different if you created another configuration file:

    sudo nano /etc/apache2/sites-available/000-default.conf

Inside of this file, we want to set up a few things. We should set the `ServerName` and create a directory section where we allow overrides. This should look something like this:

    \<VirtualHost \*:80\> ServerAdmin webmaster@localhost DocumentRoot /var/www/html ServerName server\_domain\_name\_or\_IP\<Directory /var/www/html/\>AllowOverride All\</Directory\> . . .

When you are finished, save and close the file.

Next, we need to enable the rewrite module, which allows you to modify URLs. You can do this by typing:

    sudo a2enmod rewrite

After you have made these changes, restart Apache:

    sudo service apache2 restart

### Create an .htaccess File

Now that Apache is configured to allow rewrites through `.htaccess` files, we need to create an actual file.

You need to place this file in your document root. Type this to create an empty file:

    touch /var/www/html/.htaccess

This will be created with your username and user group. We need the web server to be the group owner though, so we should adjust the ownership by typing:

    sudo chown :www-data /var/www/html/.htaccess

We now have the correct ownership of this file.

We may need to adjust the permissions however. This depends on how you prefer to work. WordPress will generate the necessary rewrite rules for you. If it has write permissions to this file, it can implement the rules automatically. If it does not, you will have to manually edit this file to add the correct rules.

Which configuration you choose depends on how much you value convenience over security. Allowing the web server write access to this file will definitely be more convenient, but some say that it is an unnecessary security risk.

If you want WordPress to automatically update this file with rewrite rules, you can ensure that it has the correct permissions to do so by typing:

    chmod 664 /var/www/html/.htaccess

If you want to update this file manually for the sake of a small security gain, you can allow the web server only read privileges by typing:

    chmod 644 /var/www/html/.htaccess

### Change the Permalink Settings in WordPress

When you are finished doing the server-side changes, you can easily adjust the permalink settings through the WordPress administration interface.

On the left-hand side, under the `Settings` menu, you can select `Permalinks`:

![WordPress permalinks](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/perma_settings.png)

You can choose any of the preconfigured settings to organize URLs, or you can create your own.

![WordPress perma options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/perma_options.png)

When you have made your selection, click “Save Changes” to generate the rewrite rules.

If you allowed the web server write access to your `.htaccess` file, you should see a message like this:

![WordPress perma update](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_1404/perma_update.png)

If you did _not_ allow the web server write access to your `.htaccess` file, you will be provided with the rewrite rules you need to add to the file manually.

Copy the lines that WordPress gives you and then edit file on your server:

    nano /var/www/html/.htaccess

This should give you the same functionality.

## Conclusion

You should now have a WordPress instance up and running on your Ubuntu 14.04 VPS. There are many avenues you can take from here. Below we’ve listed some options:

- [Configure Secure Updates and Installations for WordPress](https://www.digitalocean.com/community/articles/how-to-configure-secure-updates-and-installations-in-wordpress-on-ubuntu)
- [Use WPScan to Test for Vulnerable Plugins and Themes](https://www.digitalocean.com/community/articles/how-to-use-wpscan-to-test-for-vulnerable-plugins-and-themes-in-wordpress)
- [Manage WordPress from the Command Line](https://www.digitalocean.com/community/articles/how-to-use-wp-cli-to-manage-your-wordpress-site-from-the-command-line)
- [Set Up Multiple WordPress Sites (non-multisite)](https://www.digitalocean.com/community/articles/how-to-set-up-multiple-wordpress-sites-on-a-single-ubuntu-vps)
- [Set Up Multiple WordPress Sites with Multisite](https://www.digitalocean.com/community/articles/how-to-set-up-multiple-wordpress-sites-using-multisite)
