---
author: Anatoliy Dimitrov
date: 2015-07-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-host-multiple-websites-securely-with-nginx-and-php-fpm-on-ubuntu-14-04
---

# How To Host Multiple Websites Securely With Nginx And Php-fpm On Ubuntu 14.04

## Introduction

It’s well known that the LEMP stack (Linux, nginx, MySQL, PHP) provides unmatched speed and reliability for running PHP sites. Other benefits of this popular stack such as security and isolation are less popular, though.

In this article we’ll show you the security and isolation benefits of running sites on LEMP with different Linux users. This will be done by creating different php-fpm pools for each nginx server block (site or virtual host).

## Prerequisites

This guide has been tested on Ubuntu 14.04. The described installation and configuration would be similar on other OS or OS versions, but the commands and location of configuration files may vary.

It also assumes you already have nginx and php-fpm set up. If not, please follow step one and step three from the article [How To Install Linux, nginx, MySQL, PHP (LEMP) stack on Ubuntu 14.04](how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04).

All the commands in this tutorial should be run as a non-root user. If root access is required for the command, it will be preceded by `sudo`. If you don’t already have that set up, follow this tutorial: [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04).

You will also need a fully qualified domain name (fqdn) that points to the Droplet for testing in addition to the default `localhost`. If you don’t have one at hand, you can use `site1.example.org`. Edit the `/etc/hosts` file with your favorite editor like this `sudo vim /etc/hosts` and add this line (replace `site1.example.org` with your fqdn if you are using it):

/etc/hosts

    ...
    127.0.0.1 site1.example.org
    ... 

## Reasons to Secure LEMP Additionally

Under a common LEMP setup there is only one php-fpm pool which runs all PHP scripts for all sites under the same user. This poses two major problems:

- If a web application on one nginx server block, i.e. subdomain or separate site, gets compromised, all of the sites on this Droplet will be affected too. The attacker is able to read the configuration files, including database details, of the other sites or even alter their files. 
- If you want to give a user access to a site on your Droplet, you will be practically giving him access to all sites. For example, your developer needs to work on the staging environment. However, even with very strict file permissions you will be still giving him access to all the sites, including your main site, on the same Droplet.

The above problems are solved in php-fpm by creating a different pool which runs under a different user for each site.

## Step 1 —&nbsp;Configuring php-fpm

If you have covered the prerequisites, then you should already have one functional website on the Droplet. Unless you have specified a custom fqdn for it, you should be able to access it under the fqdn `localhost` locally or by the IP of the droplet remotely.

Now we’ll create a second site (site1.example.org) with its own php-fpm pool and Linux user.

Let’s start with creating the necessary user. For best isolation, the new user should have its own group. So first create the user group `site1`:

    sudo groupadd site1

Then please create an user site1 belonging to this group:

    sudo useradd -g site1 site1

So far the new user site1 does not have a password and cannot log in the Droplet. If you need to provide someone with direct access to the files of this site, then you should create a password for this user with the command `sudo passwd site1`. With the new user/password combination a user can log in remotely by ssh or sftp. For more info and security details check the article [Setup a secondary SSH/SFTP user with limited directory access](https://www.digitalocean.com/community/questions/setup-a-secondary-ssh-sftp-user-with-limited-directory-access).

Next, create a new php-fpm pool for site1. A php-fpm pool in its very essence is just an ordinary Linux process which runs under certain user/group and listens on a Linux socket. It could also listen on an IP:port combination too but this would require more Droplet resources, and it’s not the preferred method.

By default, in Ubuntu 14.04 every php-fpm pool should be configured in a file inside the directory `/etc/php5/fpm/pool.d`. Every file with the extensions `.conf` in this directory is automatically loaded in the php-fpm global configuration.

So for our new site let’s create a new file `/etc/php5/fpm/pool.d/site1.conf`. You can do this with your favorite editor like this:

    sudo vim /etc/php5/fpm/pool.d/site1.conf

This file should contain:

/etc/php5/fpm/pool.d/site1.conf

    [site1]
    user = site1
    group = site1
    listen = /var/run/php5-fpm-site1.sock
    listen.owner = www-data
    listen.group = www-data
    php_admin_value[disable_functions] = exec,passthru,shell_exec,system
    php_admin_flag[allow_url_fopen] = off
    pm = dynamic
    pm.max_children = 5
    pm.start_servers = 2
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3
    chdir = /

In the above configuration note these specific options:

- `[site1]` is the name of the pool. For each pool you have to specify a unique name.
- `user` and `group` stand for the Linux user and the group under which the new pool will be running.
- `listen` should point to a unique location for each pool. 
- `listen.owner` and `listen.group` define the ownership of the listener, i.e. the socket of the new php-fpm pool. Nginx must be able to read this socket. That’s why the socket is created with the user and group under which nginx runs - `www-data`.
- `php_admin_value` allows you to set custom php configuration values. We have used it to disable functions which can run Linux commands - `exec,passthru,shell_exec,system`. 
- `php_admin_flag` is similar to `php_admin_value`, but it is just a switch for boolean values, i.e. on and off. We’ll disable the PHP function `allow_url_fopen` which allows a PHP script to open remote files and could be used by attacker. 

**Note:** The above `php_admin_value` and `php_admin_flag` values could be also applied globally. However, a site may need them, and that’s why by default they are not configured. The beauty of php-fpm pools is that it allows you to fine tune the security settings of each site. Furthermore, these options can be used for any other php settings, outside of the security scope, to further customize the environment of a site.

The `pm` options are outside of the current security topic, but you should know that they allow you to configure the performance of the pool.

The `chdir` option should be `/` which is the root of the filesystem. This shouldn’t be changed unless you use another important option `chroot`.

The option `chroot` is not included in the above configuration on purpose. It would allow you to run a pool in a jailed environment, i.e. locked inside a directory. This is great for security because you can lock the pool inside the web root of the site. However, this ultimate security will cause serious problems for any decent PHP application which relies on system binaries and applications such as Imagemagick, which will not be available. If you are further interested in this topic please read the article [How To Use Firejail to Set Up a WordPress Installation in a Jailed Environment](how-to-use-firejail-to-set-up-a-wordpress-installation-in-a-jailed-environment).

Once you have finished with the above configuration restart php-fpm for the new settings to take effect with the command:

    sudo service php5-fpm restart

Verify that the new pool is properly running by searching for its processes like this:

    ps aux |grep site1

If you have followed the exact instructions up to here you should see output similar to:

    site1 14042 0.0 0.8 133620 4208 ? S 14:45 0:00 php-fpm: pool site1
    site1 14043 0.0 1.1 133760 5892 ? S 14:45 0:00 php-fpm: pool site1

In red is the user under which the process or the php-fpm pool runs - site1.

In addition, we’ll disable the default php caching provided by opcache. This particular caching extension might be great for performance, but it’s not for security as we’ll see later. To disable it edit the file `/etc/php5/fpm/conf.d/05-opcache.ini` with super user privileges and add the line:

/etc/php5/fpm/conf.d/05-opcache.ini

    opcache.enable=0
    

Then restart again php-fpm (`sudo service php5-fpm restart`) for the setting to take effect.

## Step 2 —&nbsp;Configuring nginx

Once we have configured the php-fpm pool for our site we’ll configure the server block in nginx. For this purpose please create a new file `/etc/nginx/sites-available/site1` with your favorite editor like this:

    sudo vim /etc/nginx/sites-available/site1

This file should contain:

/etc/nginx/sites-available/site1

    server {
        listen 80;
    
        root /usr/share/nginx/sites/site1;
        index index.php index.html index.htm;
    
        server_name site1.example.org;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php5-fpm-site1.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }

The above code shows a common configuration for a server block in nginx. Note the interesting highlighted parts:

- Web root is `/usr/share/nginx/sites/site1`. 
- The server name uses the fqdn `site1.example.org` which is the one mentioned in the prerequisites of this article.
- `fastcgi_pass` specifies the handler for the php files. For every site you should use a different unix socket such as `/var/run/php5-fpm-site1.sock`. 

Create the web root directory:

    sudo mkdir /usr/share/nginx/sites
    sudo mkdir /usr/share/nginx/sites/site1

To enable the above site you have to create a symlink to it in the directory `/etc/nginx/sites-enabled/`. This can be done with the command:

    sudo ln -s /etc/nginx/sites-available/site1 /etc/nginx/sites-enabled/site1

Finally, restart nginx for the change to take effect like this:

    sudo service nginx restart

## Step 3 —&nbsp;Testing

For running the tests we’ll use the well-known phpinfo function which provides detailed information about the php environment. Create a new file under the name `info.php` which contains only the line `<?php phpinfo(); ?>`. You will need this file first in the the default nginx site and its web root `/usr/share/nginx/html/`. For this purpose you can use an editor like this:

    sudo vim /usr/share/nginx/html/info.php

After that copy the file to to the web root of the other site (site1.example.org) like this:

    sudo cp /usr/share/nginx/html/info.php /usr/share/nginx/sites/site1/

Now you are ready to run the most basic test to verify the server user. You can perform the test with a browser or from the Droplet terminal and lynx, the command line browser. If you don’t have lynx on your Droplet yet, install it with the command `sudo apt-get install lynx`.

First check the `info.php` file from your default site. It should be accessible under localhost like this:

    lynx --dump http://localhost/info.php |grep 'SERVER\["USER"\]' 

In the above command we filter the output with grep only for the variable `SERVER["USER"]` which stands for the server user. For the default site the output should show the default `www-data` user like this:

    _SERVER["USER"] www-data

Similarly, next check the server user for site1.example.org:

    lynx --dump http://site1.example.org/info.php |grep 'SERVER\["USER"\]' 

You should see this time in the output the `site1` user:

    _SERVER["USER"] site1

If you have made any custom php settings on a per php-fpm pool basis, then you can also check their corresponding values in the above manner by filtering the output that interests you.

So far, we know that our two sites run under different users, but now let’s see how to secure a connection. To demonstrate the security problem we are solving in this article, we’ll create a file with sensitive information. Usually such a file contains the connection string to the database and include the user and password details of the database user. If anyone finds out that information, the person is able to do anything with the related site.

With your favorite editor create a new file in your main site `/usr/share/nginx/html/config.php`. That file should contain:

/usr/share/nginx/html/config.php

    <?php
    $pass = 'secret';
    ?>

In the above file we define a variable called `pass` which holds the value `secret`. Naturally, we want to restrict the access to this file, so we’ll set its permissions to 400, which give read only access to the owner of the file.

To change the permissions to 400 run the command:

    sudo chmod 400 /usr/share/nginx/html/config.php

Also, our main site runs under the user `www-data` who should be able to read this file. Thus, change the ownership of the file to that user like this:

    sudo chown www-data:www-data /usr/share/nginx/html/config.php

In our example we’ll use another file called `/usr/share/nginx/html/readfile.php` to read the secret information and print it. This file should contain the following code:

/usr/share/nginx/html/readfile.php

    <?php
    include('/usr/share/nginx/html/config.php');
    print($pass);
    ?>

Change the ownership of this file to `www-data` as well:

    sudo chown www-data:www-data /usr/share/nginx/html/readfile.php

To confirm all permissions and ownerships are correct in the web root run the command `ls -l /usr/share/nginx/html/`. You should see output similar to:

    -r-------- 1 www-data www-data 27 Jun 19 05:35 config.php
    -rw-r--r-- 1 www-data www-data 68 Jun 21 16:31 readfile.php

Now access the latter file on your default site with the command `lynx --dump http://localhost/readfile.php`. You should be able to see printed in the output `secret` which shows that the file with sensitive information is accessible within the same site, which is the expected correct behavior.

Now copy the file `/usr/share/nginx/html/readfile.php` to your second site, site1.example.org like this:

    sudo cp /usr/share/nginx/html/readfile.php /usr/share/nginx/sites/site1/

To keep the site/user relations in order, make sure that within each site the files are owned by the respective site user. Do this by changing the ownership of the newly copied file to site1 with the command:

    sudo chown site1:site1 /usr/share/nginx/sites/site1/readfile.php

To confirm you have set the correct permissions and ownership of the file, please list the contents of the site1 web root with the command `ls -l /usr/share/nginx/sites/site1/`. You should see:

    -rw-r--r-- 1 site1 site1 80 Jun 21 16:44 readfile.php

Then try to access the same file from site1.example.com with the command `lynx --dump http://site1.example.org/readfile.php`. You will only see empty space returned. Furthermore, if you search for errors in the error log of nginx with the grep command `sudo grep error /var/log/nginx/error.log` you will see:

    2015/06/30 15:15:13 [error] 894#0: *242 FastCGI sent in stderr: "PHP message: PHP Warning: include(/usr/share/nginx/html/config.php): failed to open stream: Permission denied in /usr/share/nginx/sites/site1/readfile.php on line 2
    

**Note:** You would also see a similar error in the lynx output if you have `display_errors` set to `On` in php-fpm configuration file `/etc/php5/fpm/php.ini`.

The warning shows that a script from the site1.example.org site cannot read the sensitive file `config.php` from the main site. Thus, sites which run under different users cannot compromise the security of each other.

If you go back to the end of configuration part of this article, you will see that we have disabled the default caching provided by opcache. If you are curious why, try to enable again opcache by setting with super user privileges `opcache.enable=1` in the file `/etc/php5/fpm/conf.d/05-opcache.ini` and restart php5-fpm with the command `sudo service php5-fpm restart`.

Amazingly, if you run again the test steps in the exactly the same order, you’ll be able to read the sensitive file regardless of its ownership and permission. This problem in opcache has been reported for a long time, but by the time of this article it has not been fixed yet.

## Conclusion

From a security point of view it’s essential to use php-fpm pools with a different user for every site on the same Nginx web server. Even if it comes with a small performance penalty, the benefit of such isolation could prevent serious security breaches.

The idea described in this article is not unique, and it’s present in other similar PHP isolation technologies such as SuPHP. However, the performance of all other alternatives is much worse than that of php-fpm.
