---
author: Brian Boucheron
date: 2017-06-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql-on-ubuntu-16-04
---

# How To Set Up a Remote Database to Optimize Site Performance with MySQL on Ubuntu 16.04

## Introduction

As your application or website grows, you may come to a point where you’ve outgrown your current server setup. If you are hosting your web server and database backend on the same machine, it may be a good idea to separate these two functions so that each can operate on its own hardware and share the load of responding to your visitors’ requests.

In this guide, we’ll discuss how to configure a remote MySQL database server that your web application can connect to. We will be using WordPress as an example so that we have something to work with, but the technique is widely applicable to any MySQL-backed application.

## Prerequisites

Before beginning this tutorial, you will need:

- Two Ubuntu 16.04 servers, with a non-root sudo-enabled user, and UFW firewall enabled, as described in [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- On one of the servers you’ll need the LEMP (Linux, Nginx, MySQL, PHP) stack installed. Our tutorial [How To Install Linux, Nginx, MySQL, PHP (LEMP stack) in Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04) will guide you through the process. You should skip Step 2, which is about installing MySQL. We’ll install MySQL in this tutorial instead.
- Optionally (but strongly recommended), you can secure your LEMP web server with SSL certificates. You’ll need a domain name, but the certificates are free. Our guide [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04) will show you how.

## Step 1 — Installing MySQL on the Database Server

Having our data stored on a separate server is a good way to expand gracefully when we hit the performance ceiling of a one-machine configuration. It also provides the basic structure necessary to load balance and expand our infrastructure even more at a later time.

To get started, we’ll install MySQL on the server we **did not** install the LEMP stack on. Log into this server, then update your package cache and install the MySQL server software:

    sudo apt-get update
    sudo apt-get install mysql-server

You will be asked to set and confirm a **root** password for MySQL during the installation procedure. Choose a strong password and take note of it, as we’ll need it later.

MySQL should be installed and running now. Let’s check using `systemctl`:

    systemctl status mysql

    Output● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
       Active: active (running) since Tue 2017-05-23 14:54:04 UTC; 12s ago
     Main PID: 27179 (mysqld)
       CGroup: /system.slice/mysql.service
               └─27179 /usr/sbin/mysqld

The `Active: active (running)` line means MySQL is installed and running. Now we’ll make the installation a little more secure. MySQL comes with a script that walks you through locking down the system:

    mysql_secure_installation

This will ask you for the MySQL **root** password that we just set. Type it in and press `ENTER`. Now we’ll answer a series of yes or no prompts. Let’s go through them:

First, we are asked about the **validate password plugin** , a plugin that can automatically enforce certain password strength rules for your MySQL users. Enabling this is a decision you’ll need to make based on your individual security needs. Type `y` and `ENTER` to enable it, or just hit `ENTER` to skip it. If enabled, you will also be prompted to choose a level from 0–2 for how strict the password validation will be. Choose a number and hit `ENTER` to continue.

Next you’ll be asked if you want to change the **root** password. Since we just created the password when we installed MySQL, we can safely skip this. Hit `ENTER` to continue without updating the password.

The rest of the prompts can be answered **yes**. You will be asked about removing the **anonymous** MySQL user, disallowing remote **root** login, removing the **test** database, and reloading privilege tables to ensure the previous changes take effect properly. These are all a good idea. Type `y` and hit `ENTER` for each.

The script will exit after all the prompts are answered. Now our MySQL installation is reasonably secured. In the next step, we’ll configure MySQL to allow access from remote connections.

## Step 2 — Configuring MySQL to Listen for Remote Connections

Now that you have your database up and running, we need to change some configuration values to allow connections from other computers.

Open up the `mysqld` configuration file with root privileges in your editor:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

This file is divided into sections denoted by words in brackets ([and]). Find the section labeled `mysqld`:

mysqld.cnf

    . . .
    [mysqld]

Within this section you’ll need to find a parameter called `bind-address`. This tells the database software which network address to listen for connections on.

Currently, MySQL is configured to only look for local connections. We need to change that to reference an _external_ IP address that your server can be reached at.

If both of your servers are in a datacenter with private networking capabilities, use your server’s private network IP. Otherwise, you can use the public IP address:

/etc/mysql/my.cnf

    [mysqld]
    . . .
    bind-address = db_server_ip

Since we’ll be connecting to the database over the internet, we will require encrypted connections to keep our data secure. If you don’t encrypt your MySQL connection, anybody on the network could sniff sensitive information between your web and database server. Add the following line after the `bind-address` line we just updated:

/etc/mysql/my.cnf

    . . .
    require_secure_transport = on

Save and close the file when you are finished.

For SSL connections to work, we need to create some keys and certificates. MySQL comes with a command that automatically sets up everything we need:

    sudo mysql_ssl_rsa_setup --uid=mysql

This will create the necessary files and make them readable by the MySQL server (`--uid=mysql`).

To force MySQL to update its configuration and read in the new SSL information, restart the database:

    sudo systemctl restart mysql

To confirm that the server is now listening on the external interface, check with `netstat`:

    sudo netstat -plunt | grep mysqld

    Outputtcp 0 0 db_server_ip:3306 0.0.0.0:* LISTEN 27328/mysqld

`netstat` prints statistics about our server’s networking system. This output shows us that a process called `mysqld` is attached to the `db_server_ip` at port `3306`, the standard MySQL port.

Now open up that port on the firewall to allow traffic through:

    sudo ufw allow mysql

Next we’ll set up the users and database we’ll need to access the server remotely.

## Step 3 — Setting Up a WordPress Database and Remote Credentials

Even though MySQL itself is now listening on an external IP address, there are currently no remote-enabled users or databases configured. Let’s create a database for WordPress, and a user that can access it.

Begin by connecting to MySQL using the MySQL **root** account:

    mysql -u root -p

You will be asked for your MySQL **root** password and then you’ll be given a new `mysql>` prompt.

Now we can create the database that WordPress will use. We will just call this `wordpress` so that we can easily identify it later:

    CREATE DATABASE wordpress;

**Note:** All SQL statements must end in a semicolon (`;`). If you hit `ENTER` on a MySQL command and only see a new line with a `->` prompt, you likely forgot the semicolon. Just type it on the new line and press `ENTER` again to continue.

Now that we have a database, we need to create our user. One twist in creating our user is that we need to define two different profiles based on where the user is connecting from. We will create a local-only user, and a remote user tied to our web server’s IP address.

First, we create our local user **wordpressuser** and make this account only match local connection attempts by using **localhost** in the declaration:

    CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'password';

Let’s go ahead and grant this account full access to our database:

    GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'localhost';

This user can now do any operation on the database for WordPress, but this account cannot be used remotely, as it only matches connections from the local machine.

Now create a companion account that will match connections exclusively from our web server. For this, you’ll need your web server’s IP address. We could name this account anything, but for a more consistent experience, we’re going to use the exact same username as we did above, with only the host portion modified.

Keep in mind that you must use an IP address that utilizes the same network that you configured in your `mysqld.cnf` file. This means that if you used a private networking IP, you’ll want to create the rule below to use the private IP of your web server. If you configured MySQL to use the public internet, you should match that with the web server’s public IP address.

    CREATE USER 'wordpressuser'@'web-server_ip' IDENTIFIED BY 'password';

Now that we have our remote account, we can give it the same privileges as the local user:

    GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'web_server_ip';

Flush the privileges to write them to disk and begin using them:

    FLUSH PRIVILEGES;

Then exit the MySQL prompt by typing:

    exit

Now that we’ve set up a new database and remote-enabled user, let’s test the database and connections.

## Step 4 — Testing Remote and Local Connections

Before we continue, it’s best to verify that you can connect to your database from both the local machine and from your web server using the **wordpressuser** accounts.

First, test the local connection from your **database machine** by attempting to log in with our new account:

    mysql -u wordpressuser -p

Type in the password that you set up for this account when prompted.

If you are given a MySQL prompt, then the local connection was successful. You can exit out again by typing:

    exit

Log into your **web server** to test remote connections.

On your web server, you’ll need to install some client tools for MySQL in order to access the remote database. Update your local package cache, and then install the client utilities:

    sudo apt-get update
    sudo apt-get install mysql-client

Now, we can connect to our database server using the following syntax:

    mysql -u wordpressuser -h db_server_ip -p

Again, you must make sure that you are using the correct IP address for the database server. If you configured MySQL to listen on the private network, enter your database’s private network IP, otherwise enter your database server’s public IP address.

You will be asked for the password for your **wordpressuser** account, and if all goes well you will be given a MySQL prompt. We can verify that the connection is using SSL with the following command:

    status

    Output--------------
    mysql Ver 14.14 Distrib 5.7.18, for Linux (x86_64) using EditLine wrapper
    
    Connection id: 52
    Current database:
    Current user: wordpressuser@203.0.113.111
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    Current pager: stdout
    Using outfile: ''
    Using delimiter: ;
    Server version: 5.7.18-0ubuntu0.16.04.1 (Ubuntu)
    Protocol version: 10
    Connection: 203.0.113.111 via TCP/IP
    Server characterset: latin1
    Db characterset: latin1
    Client characterset: utf8
    Conn. characterset: utf8
    TCP port: 3306
    Uptime: 3 hours 43 min 40 sec
    
    Threads: 1 Questions: 1858 Slow queries: 0 Opens: 276 Flush tables: 1 Open tables: 184 Queries per second avg: 0.138
    --------------

The `SSL:` line will indicate if an SSL cipher is in use. You can go ahead and exit out of the prompt now, as you’ve verified that you can connect remotely:

    exit

For an additional check, you can try doing the same thing from a third server to make sure that this other server is _not_ granted access. You have verified local access and access from the web server, but you have not verified that other connections will be refused.

Go ahead and try that same procedure on a server that you did _not_ configure a specific user account for. You may have to install the client utilities as you did above:

    mysql -u wordpressuser -h db_server_ip -p

This should not complete successfully. It should throw back an error that looks something like:

    OutputERROR 1130 (HY000): Host '203.0.113.12' is not allowed to connect to this MySQL server

This is what we expect and what we want.

We’ve successfully tested our remote connection, and can now proceed with our WordPress installation.

## Step 5 — Installing WordPress

To demonstrate the capabilities of our new remote-capable MySQL server, we’ll be installing and configuring WordPress — the popular blogging platform — on our web server. This will require us to download and extract the software, configure our connection information, and then run through WordPress’s web-based installation.

On your **web server** , download the latest release of WordPress to your home directory:

    cd ~
    curl -O https://wordpress.org/latest.tar.gz

Extract the files, which will create a directory called `wordpress` in your home directory:

    tar xzvf latest.tar.gz

WordPress includes a sample configuration file which we’ll use as a starting point. We make a copy of this file, removing `-sample` from the filename so it will be loaded by WordPress:

    cp ~/wordpress/wp-config-sample.php ~/wordpress/wp-config.php

When we open the file, our first order of business will be to adjust some secret keys to provide security to our installation. WordPress provides a secure generator for these values so that you do not have to try to come up with good values on your own. These are only used internally, so it won’t hurt usability to have complex, secure values here.

To grab secure values from the WordPress secret key generator, type:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

This will print out some configuration that we can copy and paste into our `wp-config.php` file.

**Warning!** It is important that you request unique values each time. **Do not** copy the values shown below!

    Outputdefine('AUTH_KEY', '1jl/vqfs<XhdXoAPz9 DO NOT COPY THESE VALUES c_j{iwqD^<+c9.k<J@4H');
    define('SECURE_AUTH_KEY', 'E2N-h2]Dcvp+aS/p7X DO NOT COPY THESE VALUES {Ka(f;rv?Pxf})CgLi-3');
    define('LOGGED_IN_KEY', 'W(50,{W^,OPB%PB<JF DO NOT COPY THESE VALUES 2;y&,2m%3]R6DUth[;88');
    define('NONCE_KEY', 'll,4UC)7ua+8<!4VM+ DO NOT COPY THESE VALUES #`DXF+[$atzM7 o^-C7g');
    define('AUTH_SALT', 'koMrurzOA+|L_lG}kf DO NOT COPY THESE VALUES 07VC*Lj*lD&?3w!BT#-');
    define('SECURE_AUTH_SALT', 'p32*p,]z%LZ+pAu:VY DO NOT COPY THESE VALUES C-?y+K0DK_+F|0h{!_xY');
    define('LOGGED_IN_SALT', 'i^/G2W7!-1H2OQ+t$3 DO NOT COPY THESE VALUES t6**bRVFSD[Hi])-qS`|');
    define('NONCE_SALT', 'Q6]U:K?j4L%Z]}h^q7 DO NOT COPY THESE VALUES 1% ^qUswWgn+6&xqHN&%');

Copy the output you received to your clipboard, then, open the configuration file in your text editor:

    nano ~/wordpress/wp-config.php

Find the section that contains the dummy values for those settings. It will look something like this:

wp-config.php

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

Delete those lines and paste in the values you copied from the command line.

Next, we need to enter the connection info for our remote database. These configuration lines are at the top of the file, just above where we pasted in our keys. Remember to use the same IP address you used in your remote database test earlier:

wp-config.php

    . . .
    /** The name of the database for WordPress */
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    /** MySQL hostname */
    define('DB_HOST', 'db_server_ip');
    . . .

And finally, anywhere in the file, paste the following line which tells WordPress to use an SSL connection to our MySQL database:

wp-config.php

    define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);

Save and close the file.

Next, we’ll need to copy the files and directories found in our `~/wordpress` directory to Nginx’s document root. We use the `-a` flag to make sure our permissions are maintained:

    sudo cp -a ~/wordpress/* /var/www/html

Now all of our files are in place. The only thing left to do is modify the file ownership. We are going to set all of the files in the document root to be owned by our web server user, `www-data`:

    sudo chown -R www-data:www-data /var/www/html

WordPress should now be installed and ready to run through its web-based setup routine. We’ll do that in the next step.

## Step 6 — Setting Up Wordpress Through the Web Interface

WordPress has a web-based setup routine that will ask a few questions and install the tables it needs in our database. Let’s start that now.

Navigate to the domain name (or public IP address) associated with your web server:

    http://example.com

You will see a language selection screen for the WordPress installer. Select the appropriate language and click through to the main installation screen:

![WordPress install screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/remote-mysql-1604/wp-install.png)

Once you have submitted your information, you will need to log into the WordPress admin interface using the account you just created. You will then be taken to a dashboard where you can customize and operate your site.

## Conclusion

In this tutorial, we’ve set up a MySQL database to accept SSL-protected connections from a remote Wordpress install. The commands and techniques we used are applicable to any web application written in any programming language, but the specific implementation details will differ. Refer to your application or language’s database documentation for more information.
