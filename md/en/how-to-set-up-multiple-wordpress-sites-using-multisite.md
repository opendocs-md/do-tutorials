---
author: Etel Sverdlov
date: 2012-11-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-multiple-wordpress-sites-using-multisite
---

# How To Set Up Multiple WordPress Sites Using Multisite

## About Multiple WordPress Installs

In 2010, WordPress released version 3.0 of it popular content management platform. Among the many improvements included in the release, the WordPress community combined WordPress MU into the main WordPress configuration. Since the change, WordPress has made it easier to create multiple WordPress sites on one server. Whereas earlier, each WordPress blog on a server needed to have its own installation, now a new WordPress site can be installed once, and other blogs can be set up from within the WordPress dashboard.

### Setup

The steps in this tutorial require the user to have root privileges. You can see how to set that up in the [Initial Server Setup](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04)

Before working with WordPress, you need to have LAMP installed on your virtual private server. If you don't have the Linux, Apache, MySQL, PHP stack on your VPS, you can find the tutorial for setting it up in the [Ubuntu LAMP tutorial](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu).

Once you have the user and required software, go ahead and [Install WordPress](how-to-install-wordpress-on-ubuntu-12-04). **However—make sure you stop at the end of step 4** (We will add one more thing to the Wordpress config file in the next step)

## Step One—Setup Your WordPress Installation 

* * *

With WordPress installed, we need to take a series of steps in a variety of configuration files.

To begin with, modify the WordPress configuration, activating the multisite networking:

    sudo nano /var/www/wp-config.php

Add the following line above "_/\* That’s all, stop editing! Happy blogging. \*/_"

    /\* Multisite \*/ define('WP\_ALLOW\_MULTISITE', true);

Activate the apache Mod\_Rewrite module:

    sudo a2enmod rewrite

Follow up by permitting .htaccess changes in the virtual file. Open up your virtual host file (I am simply going to make these changes in the default Apache one).

    sudo nano /etc/apache2/sites-enabled/000-default

In the following section, change AllowOverride to All:

    &ltDirectory /var/www/\> Options Indexes FollowSymLinks MultiViews AllowOverride **All** Order allow,deny allow from all &lt/Directory\>

Restart apache:

    sudo service apache2 restart

Once that is all done, the wordpress online installation page is up and waiting for you:

Access the page by adding /wp-admin/install.php to your site's domain or IP address (eg. example.com/wp-admin/install.php) and fill out the short online form.

## Step Two—Setup Multiple WordPress Sites

Go into your WordPress dashboard and select the section called tools:

 ![networking setup](https://assets.digitalocean.com/tutorial_images/oxaEO.png?1)

Once you have filled out the required fields, go through the directions on the next page (I have elaborated on them further under the image):

 ![next page](https://assets.digitalocean.com/tutorial_images/rjwIc.png?1)
1. Create a directory for your new sites: 

    sudo mkdir /var/www/wp-content/blogs.dir

2. Alter your WordPress configuration. Make sure to paste this above the line _/\* That’s all, stop editing! Happy blogging. \*/_: 

    sudo nano /var/www/wp-config.php

     define('MULTISITE', true); define('SUBDOMAIN\_INSTALL', false); $base = '/'; define('DOMAIN\_CURRENT\_SITE', ' **_YOUR IP ADDRESS HERE_**'); define('PATH\_CURRENT\_SITE', '/'); define('SITE\_ID\_CURRENT\_SITE', 1); define('BLOG\_ID\_CURRENT\_SITE', 1);

3. Finally, add WordPress’s rewrite rules to /var/www htaccess file: 

     sudo nano /var/www/.htaccess

    RewriteEngine On RewriteBase / RewriteRule ^index\.php$ - [L] # uploaded files RewriteRule ^([\_0-9a-zA-Z-]+/)?files/(.+) wp-includes/ms-files.php?file=$2 [L] # add a trailing slash to /wp-admin RewriteRule ^([\_0-9a-zA-Z-]+/)?wp-admin$ $1wp-admin/ [R=301,L] RewriteCond %{REQUEST\_FILENAME} -f [OR] RewriteCond %{REQUEST\_FILENAME} -d RewriteRule ^ - [L] RewriteRule ^[\_0-9a-zA-Z-]+/(wp-(content|admin|includes).\*) $1 [L] RewriteRule ^[\_0-9a-zA-Z-]+/(.\*\.php)$ $1 [L] RewriteRule . index.php [L]

After making all of the necessary changes, log into WordPress once more.

## Step Three—Setup Your New WordPress Site

After you log into your site once again, you will notice that the header bar now has a section called, “My Sites” instead of simply displaying your blog’s name:

 ![header](https://assets.digitalocean.com/tutorial_images/rPn5f.png?1)

You can create new sites by going to My Sites at the top, clicking on Network Admin, and clicking on Sites:

 ![create a new site](https://assets.digitalocean.com/tutorial_images/OoYcp.png?1)
By Etel Sverdlov
