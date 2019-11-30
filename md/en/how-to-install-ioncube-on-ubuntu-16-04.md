---
author: Vlad Roman
date: 2017-01-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-ioncube-on-ubuntu-16-04
---

# How To Install ionCube on Ubuntu 16.04

## Introduction

[ionCube](http://www.ioncube.com/loaders.php) is a PHP module extension that loads encrypted PHP files and speeds up webpages. It is often required for PHP-based applications. In this tutorial, we will install ionCube on a Ubuntu 16.04 server.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with a sudo non-root user and firewall, which you can set up by following [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04). 
- A web server with PHP installed, like [Apache](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04#step-1-install-apache-and-allow-in-firewall) or [Nginx](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04). Follow the steps for installing the web server itself, updating the firewall, and installing PHP.

## Step 1 — Choosing the Right ionCube Version

It is important that the version of ionCube you choose matches your PHP version, so first, you need to know:

- The version of PHP our web server is running, and
- If it is 32-bit or 64-bit.

If you have a 64-bit Ubuntu server, you are probably running 64-bit PHP, but let’s make sure. To do so, we’ll use a small PHP script to retrieve information about our server’s current PHP configuration.

Create a file called `info.php` file in the root directory of your web server (likely `/var/www/html`, unless you’ve changed it) using `nano` or your favorite text editor.

    sudo nano /var/www/html/info.php

Paste the following inside the file, then save and close it.

info.php

    <?php
    phpinfo();

After saving the changes to the file, visit `http://your_server_ip/info.php` in your favorite browser. The web page you’ve opened should look something like this:

![Ubuntu 16.10 default PHP info](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ioncube-ubuntu/j3jtETT.png)

From that page, look at the header at the top where it says **PHP Version**. In this case, we’re running 7.0.8. Then, look at the **System** line. If it ends with **x86\_64** , you’re running 64-bit PHP; if it ends with **i686** , it’s 32-bit.

With this information, you can proceed with the download and installation.

## Step 2 — Setting Up ionCube

Visit the [ionCube download page](http://www.ioncube.com/loaders.php) and find the appropriate download link based on your OS. In our example, we need the [this 64-bit Linux version](http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz). Copy the **tar.gz** link on the site and download the file.

    wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

Next, extract the archive.

    tar xvfz ioncube_loaders_lin_x86-64.tar.gz

This creates a directory named `ioncube` which contains various files for various PHP versions. Choose the right folder for your PHP version. In our example, we need the file PHP version `7.0`, which is `ioncube_loader_lin_7.0.so`. We will copy this file to the PHP extensions folder.

To find out the path of the extensions folder, check the `http://your_server_ip/info.php` page again and search for **extension\_dir**.

![extension_dir PHP configuration directive](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ioncube-ubuntu/oyRzoMW.png)

In this example, it’s `/usr/lib/php/20151012`, so copy the file there:

    sudo cp ioncube/ioncube_loader_lin_7.0.so /usr/lib/php/20151012/

For PHP to load the extension, we need to add it to the PHP configuration. We can do it in the main `php.ini` PHP configuration file, but it’s cleaner to create a separate file. We can set this separate file to load before other extensions to avoid possible conflicts.

To find out where we should create the custom configuration file, look at `http://your_server_ip/info.php` again and search for **Scan this dir for additional .ini files**.

![Additional PHP configuration files](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ioncube-ubuntu/C5OUFOO.png)

So, we’ll create a file named `00-ioncube.ini` inside the `/etc/php/7.0/apache2/conf.d` directory. The `00` at the beginning of the filename ensures this file will be loaded before other PHP configuration files.

    sudo nano /etc/php/7.0/apache2/conf.d/00-ioncube.ini

Paste the following loading directive, then save and close the file.

00-ioncube.ini

    zend_extension = "/usr/lib/php/20151012/ioncube_loader_lin_7.0.so"

For the above change to take effect, we will need to restart the web server.

If you are using Apache, run:

    sudo systemctl restart apache2.service

If you are using Nginx, run:

    sudo systemctl restart nginx

You may also need to restart `php-fpm`, if you’re using it.

    sudo systemctl restart php7.0-fpm.service

Finally, let’s make sure that the PHP extension is installed and enabled.

## Step 3 — Verifying the ionCube Installation

Back on the `http://your_server_ip/info.php` page, refresh the page and search for the “ionCube” keyword. You should now see **with the ionCube PHP Loader (enabled)**:

![ionCube installed](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ioncube-ubuntu/faYixRc.png)

That confirms that the PHP ionCube extension is loaded on your server.

It can be a bit of a security risk to keep the `info.php` script, as it allows potential attackers to see information about your server, so remove it now.

    sudo rm /var/www/html/info.php

You can also safely remove the extra downloaded ionCube files which are no longer necessary.

    sudo rm ioncube_loaders_lin_x86-64.tar.gz
    sudo rm -rf ioncube_loaders_lin_x86-64

ionCube is now fully set up and functional.

## Conclusion

Now that the ionCube PHP extension has been installed, you can proceed with any PHP application which requires it.
