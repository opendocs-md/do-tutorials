---
author: Vlad Roman
date: 2016-11-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-share-files-with-filerun-on-centos-7
---

# How To Share Files with FileRun on CentOS 7

### An Article from [FileRun](http://www.filerun.com/)

## Introduction

[FileRun](http://www.filerun.com) is a PHP file manager and file sharing application that helps you access, organize, view and edit files. You can use it with office documents, photos, music, and any other type of file that you might store on your web server. In this tutorial, we will install FileRun on a CentOS 7 server.

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server with a sudo non-root user, which you can set up by following [this initial server setup tutorial](initial-server-setup-with-centos-7). 
- Apache and MariaDB installed on your server, which you can set up by following Step One and Two of [this LAMP on CentOS 7 tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7).

FileRun is a resource-friendly application, so 512MB of memory should be sufficient for most cases. As for disk space, FileRun and all of its required third-party software will not use more than 2GB.

## Step 1 — Setting Up FileRun’s Database

FileRun uses MariaDB to manage its database, which holds application settings, user settings, and information about your files. First, we’ll create this database and the user account which will access it.

To get started, log into MariaDB with the root account on your server.

    mysql -u root -p

Enter the password you set for the MariaDB root user when you installed the server.

FileRun requires a separate database for storing its data. You can call this database whatever you prefer; here, we’re using the name **filerun**.

    CREATE DATABASE filerun;

Next, create a separate MariaDB user account that will interact with the newly created database. Creating one-function databases and accounts is a good idea from a management and security standpoint.

Like naming the database, you can choose any username that you prefer. Here, we’re using the username **sammy**. Make sure you choose a strong database password.

    GRANT ALL ON filerun.* to 'sammy'@'localhost' IDENTIFIED BY 'your_database_password';

With the user assigned access to the database, refresh the grant tables to ensure that the running instance of MariaDB knows about the recent privilege assignment.

    FLUSH PRIVILEGES;

Now you can exit MariaDB.

    exit

Make a note of the database name **filerun** , the username **sammy** , and the password you chose, as you will need this information again shortly.

## Step 2 — Setting Up PHP

PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI implementation that has some additional features useful for busier sites. It’s a better choice here than the popular `mod_php` because, among other benefits, files created by PHP scripts will not be owned by the web server. This means you can simultaneously access them via FTP or other methods.

FileRun requires PHP version 5.5 or higher. CentOS 7 only provides the older PHP version 5.4 by default, so we first need to update the `yum` repositories.

    sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

Now, install PHP 5.6.

    sudo yum install php56w-fpm

Next, create the system startup links for PHP-FPM and start it.

    sudo systemctl enable php-fpm.service
    sudo systemctl start php-fpm.service

PHP-FPM is a daemon process (with the init script `/etc/init.d/php-fpm`) that runs a FastCGI server on port `9000`. To make Apache work with PHP-FPM, we can use the `ProxyPassMatch` directive in each `vhost` that should use PHP-FPM. We do that by editing the Apache configuration file:

    sudo vi /etc/httpd/conf/httpd.conf

Add this block near the end, before the `IncludeOptional conf.d/*.conf` line.

Section to add to httpd.conf

    <IfModule proxy_module>
      ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1
    </IfModule>

It should look like this:

/etc/httpd/conf/httpd.conf

    . . .
    #EnableMMAP off
    EnableSendFile on
    
    <IfModule proxy_module>
      ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1
    </IfModule>
    
    # Supplemental configuration
    #
    # Load config files in the "/etc/httpd/conf.d" directory if any.
    IncludeOptional conf.f/*.conf

Next, higher up in the same file, locate the `DirectoryIndex` directive and append `index.php` to it.

/etc/httpd/conf/httpd.conf

    . . .
    #
    # DirectoryIndex: sets the file that Apache will serve if a directory
    # is requested.
    #
    <IfModule dir_module>
        DirectoryIndex index.html index.php
    </IfModule>
    . . .

Restart Apache to finish the PHP installation.

    sudo systemctl restart httpd.service

FileRun also needs the following additional PHP modules:

- `php56w-mbstring`, which allows FileRun to handle multibytes characters.
- `php56w-pdo` and `php56w-mysql`, which allow FileRun to make use of the MySQL/MariaDB database.
- `php56w-mcrypt`, which provides cryptographic capabilities to FileRun.
- `php56w-gd`, which is optional but allows FileRun to generate user avatars, QR codes, and other small similar images.
- `php56w-opcache` , which is also optional but drastically improves PHP’s performance.

We can install all of the above with the following command:

    sudo yum install php56w-mbstring php56w-mcrypt php56w-opcache php56w-pdo php56w-mysql php56w-gd

One last necessary module which is not included in the `yum` repository is `ionCube`. ionCube is a widely used PHP extension for running protected PHP code for increased website security, malware blocking, and increased performance.

Download the latest ionCube version into the `/usr/lib64/php/modules` directory.

    sudo wget -P /usr/lib64/php/modules http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz

Then decompress the file in that directory.

    sudo tar xvfz /usr/lib64/php/modules/ioncube_loaders_lin_x86-64.tar.gz -C /usr/lib64/php/modules

Next, let’s create a file which will automatically get appended by PHP to its configuration. This will include the FileRun-specific settings.

    sudo vi /etc/php.d/filerun.ini

Paste the following inside the created file:

    date.timezone = "UTC"
    zend_extension = "/usr/lib64/php/modules/ioncube/ioncube_loader_lin_5.6.so"

This will set the timezone and have PHP load the ionCube extension. Here, we chose the UTC timezone, but you can [choose your own](http://www.php.net/manual/en/timezones.php).

**Note:** You can take a look at [all of FileRun’s recommended PHP settings here](http://docs.filerun.com/php_configuration). The directives can be appended to the `/etc/php.d/filerun.ini` file.

Finally, we need to restart the PHP-FPM service for the changes to take effect:

    sudo systemctl restart php-fpm.service

Your server now meets all the requirements and we can proceed with installing FileRun.

## Step 3 — Installing FileRun

Download FileRun in the root folder of your webserver (`/var/www/html/`):

    cd /var/www/html/
    sudo wget -O FileRun.zip http://www.filerun.com/download-latest

To extract the FileRun installer, we’ll need the `unzip` utility.

    sudo yum install unzip

Now, unzip the FIleRun archive.

    sudo unzip FileRun.zip

Make Apache the owner of the directory so that it can allow PHP to install FileRun.

    sudo chown -R apache:apache /var/www/html/

Open your browser and point it to `http://your_server_ip`. From here, you just have to follow the web installer, which will help you get FileRun running with just a few clicks.

On the first **Welcome to FileRun!** screen, click the blue **Next** button in the bottom right to proceed. Review the server requirements check on the next page to make sure there are no red error messages, then click **Next** again.

The next page sets up the database connection. Fill in the fields as follows:

- **MySQL Hostname** should be **localhost**.
- **Database name** should be the name you used in Step 2 of this tutorial. Our example used **filerun**.
- **MySQL user** should be the name you used in Step 2 of this tutorial. Our example used **sammy**.
- **Password** should be the password you chose in Step 2.

Once these are filled in, click **Next**. You’ll be presented with a screen that says **All done!** , which means FileRun was successfully installed.

**Note** : You’ll see a username and (randomly generated) password on this screen. Make sure to copy it! You’ll need it later.

Click **Next** to open FileRun. You’ll see a login page. The form should be prefilled, so you can just click **Sign in**.

You’re all logged in! Next, let’s make sure our installation is secure.

## Step 4 — Securing the FileRun installation

As soon as you sign in to FileRun, you will be prompted to change the password. Although the automatically generated password is quite secure, it’s still a good idea to set your own.

**Warning:** The FileRun superuser is the only account not protected against brute force login attacks, so it is very important that you set a password that is very difficult for a computer to guess. Set a long password containing uppercase letters, digits, and symbols.

The permissions of the FileRun application files should not allow PHP (or any other web server application) to make changes to them, so update them now.

    sudo chown -R root:root /var/www/html

The `/var/www/html/system/data` FileRun folder is the only folder where PHP needs write access, so update that too.

    sudo chown -R apache:apache /var/www/html/system/data

By default, the superuser’s home folder is located inside `/var/www/html/system/data/`. It is important that you edit the user account from the FileRun control panel, and set the home folder path pointing to a folder which is located outside the public area of your web server (i.e. outside `/var/www/html`).

An easy solution is to create a directory called `/files` and store all the FileRun files in there:

    sudo mkdir /files
    sudo chown apache:apache /files

Next, connect to the MariaDB server again.

    mysql -u root -p

Update the configured MariaDB user account and remove the `ALTER` and `DROP` privileges.

    REVOKE ALTER, DROP ON filerun.* FROM 'sammy'@'localhost';
    FLUSH PRIVILEGES;

Then exit MariaDB by entering `CTRL+D`.

**Note** : You will need to add these permissions back before you will be installing any FileRun software update in the future. To do that, connect again to the database server and run `GRANT ALTER, DROP ON filerun.* TO 'sammy'@'localhost';` followed by `FLUSH PRIVILEGES;`.

Your FileRun installation is now secure and ready to use. If you’d like, you can now install some optional packages to support thumbnails for different file types.

## Step 5 — Adding Thumbnail Support (Optional)

To generate thumbnails for image files, photography files, and PDF documents, you’ll need to install ImageMagick.

    sudo yum install ImageMagick*

Next, enable it inside FileRun from the control panel, under the **System configuration** \> **Files** \> **Image preview** section, using the path `/usr/bin/convert`.

To generate thumbnails for video files, you’ll need to install ffmpeg, which is available in the ATrpms package repository.

    sudo rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms
    sudo rpm -ivh http://dl.atrpms.net/el6-x86_64/atrpms/stable/atrpms-repo-6-7.el6.x86_64.rpm

Finally, install it.

    sudo yum install ffmpeg

Similarly, enable it inside FileRun from the control panel, under the **System configuration** \> **Files** \> **Image preview** section, using the path `/usr/bin/ffmpeg`.

If you access FileRun in your browser now, you’ll see thumbnails for your files.

## Conclusion

You have now successfully deployed FileRun on your own private and secure server. It’s time to upload your files, photos, music, or work documents and start sharing.

There are a lot of additional things you can do from here. For example, you can point a domain name to your server by following [this host name tutorial](how-to-set-up-a-host-name-with-digitalocean).

You can also set up SSL. An SSL certificate will encrypt the communication between your browser and your FileRun installation. Not only it will considerably increase the privacy and security of your data, but it will also allow you to access your files using the FileRun free [Android app](https://play.google.com/store/apps/details?id=com.afian.FileRun&utm_source=global_co&utm_medium=prtnr&utm_content=Mar2515&utm_campaign=PartBadge&pcampaignid=MKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1).

To install a free SSL certificate, follow [this Let’s Encrypt tutorial](how-to-secure-apache-with-let-s-encrypt-on-centos-7). If you do not have a domain name and you are using this configuration only for testing or personal use, you can use a self-signed certificate instead. Follow the [self-signed SSL guide for Apache](how-to-create-an-ssl-certificate-on-apache-for-centos-7) to set it up.

For more information on FileRun features and settings, visit [the official documentation](http://docs.filerun.com).
