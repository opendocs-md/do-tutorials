---
author: Brian Boucheron, Erika Heidi
date: 2019-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-linux-nginx-mariadb-php-lemp-stack-on-debian-10
---

# How To Install Linux, Nginx, MariaDB, PHP (LEMP stack) on Debian 10

## Introduction

The LEMP software stack is a group of software that can be used to serve dynamic web pages and web applications. The name “LEMP” is an acronym that describes a **L** inux operating system, with an ( **E** )Nginx web server. The backend data is stored in a **M** ariaDB database and the dynamic processing is handled by **P** HP.

Although this software stack typically includes **MySQL** as the database management system, some Linux distributions — including Debian — use [MariaDB](https://mariadb.org) as a drop-in replacement for MySQL.

In this guide, you’ll install a LEMP stack on a Debian 10 server using MariaDB as the database management system.

## Prerequisites

To complete this guide, you will need access to a Debian 10 server. This server should have a regular user configured with `sudo` privileges and a firewall enabled with `ufw`. To set this up, you can follow our [Initial Server Setup with Debian 10](initial-server-setup-with-debian-10) guide.

## Step 1 — Installing the Nginx Web Server

In order to serve web pages to your site visitors, we are going to employ [Nginx](https://www.nginx.com/), a popular web server which is well known for its overall performance and stability.

All of the software you will be using for this procedure will come directly from Debian’s default package repositories. This means you can use the `apt` package management suite to complete the installation.

Since this is the first time you’ll be using `apt` for this session, you should start off by updating your local package index. You can then install the server:

    sudo apt update
    sudo apt install nginx

On Debian 10, Nginx is configured to start running upon installation.

If you have the `ufw` firewall running, you will need to allow connections to Nginx. You should enable the most restrictive profile that will still allow the traffic you want. Since you haven’t configured SSL for your server yet, for now you only need to allow HTTP traffic on port `80`.

You can enable this by typing:

    sudo ufw allow 'Nginx HTTP'

You can verify the change by typing:

    sudo ufw status

You should see HTTP traffic allowed in the displayed output:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx HTTP ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx HTTP (v6) ALLOW Anywhere (v6)

Now, test if the server is up and running by accessing your server’s domain name or public IP address in your web browser. If you do not have a domain name pointed at your server and you do not know your server’s public IP address, you can find it by typing one of the following into your terminal:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

This will print out a few IP addresses. You can try each of them in turn in your web browser.

Type one of the addresses that you receive in your web browser. It should take you to Nginx’s default landing page:

    http://your_domain_or_IP

![Nginx default page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_debian8/THcJfIl.png)

If you see the above page, you have successfully installed Nginx.

## Step 2 — Installing MariaDB

Now that you have a web server up and running, you need to install the database system to be able to store and manage data for your site.

In Debian 10, the metapackage `mysql-server`, which was traditionally used to install the MySQL server, was replaced by `default-mysql-server`. This metapackage references [MariaDB](https://mariadb.org/), a community fork of the original MySQL server by Oracle, and it’s currently the default MySQL-compatible database server available on debian-based package manager repositories.

For longer term compatibility, however, it’s recommended that instead of using the metapackage you install MariaDB using the program’s actual package, `mariadb-server`.

To install this software, run:

    sudo apt install mariadb-server

When the installation is finished, it’s recommended that you run a security script that comes pre-installed with MariaDB. This script will remove some insecure default settings and lock down access to your database system. Start the interactive script by running:

    sudo mysql_secure_installation

This script will take you through a series of prompts where you can make some changes to your MariaDB setup. The first prompt will ask you to enter the current **database root** password. This is not to be confused with the **system root**. The **database root** user is an administrative user with full privileges over the database system. Because you just installed MariaDB and haven’t made any configuration changes yet, this password will be blank, so just press `ENTER` at the prompt.

The next prompt asks you whether you’d like to set up a **database root** password. Because MariaDB uses a special authentication method for the **root** user that is typically safer than using a password, you don’t need to set this now. Type `N` and then press `ENTER`.

From there, you can press `Y` and then `ENTER` to accept the defaults for all the subsequent questions. This will remove anonymous users and the test database, disable remote **root** login, and load these new rules so that MariaDB immediately respects the changes you have made.  
When you’re finished, log in to the MariaDB console by typing:

    sudo mariadb

This will connect to the MariaDB server as the administrative database user **root** , which is inferred by the use of `sudo` when running this command. You should see output like this:

    OutputWelcome to the MariaDB monitor. Commands end with ; or \g.
    Your MariaDB connection id is 74
    Server version: 10.3.15-MariaDB-1 Debian 10
    
    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
    
    MariaDB [(none)]> 

Notice that you didn’t need to provide a password to connect as the **root** user. That works because the default authentication method for the administrative MariaDB user is `unix_socket` instead of `password`. Even though this might look like a security concern at first, it makes the database server more secure because the only users allowed to log in as the **root** MariaDB user are the system users with sudo privileges connecting from the console or through an application running with the same privileges. In practical terms, that means you won’t be able to use the administrative database **root** user to connect from your PHP application.

For increased security, it’s best to have dedicated user accounts with less expansive privileges set up for every database, especially if you plan on having multiple databases hosted on your server. To demonstrate such a setup, we’ll create a database named **example\_database** and a user named **example\_user** , but you can replace these names with different values.  
To create a new database, run the following command from your MariaDB console:

    CREATE DATABASE example_database;

Now you can create a new user and grant them full privileges on the custom database you’ve just created. The following command defines this user’s password as `password`, but you should replace this value with a secure password of your own choosing.

    GRANT ALL ON example_database.* TO 'example_user'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;

This will give the **example\_user** user full privileges over the **example\_database** database, while preventing this user from creating or modifying other databases on your server.

Flush the privileges to ensure that they are saved and available in the current session:

    FLUSH PRIVILEGES;

Following this, exit the MariaDB shell:

    exit

You can test if the new user has the proper permissions by logging in to the MariaDB console again, this time using the custom user credentials:

    mariadb -u example_user -p

Note the `-p` flag in this command, which will prompt you for the password used when creating the **example\_user** user. After logging in to the MariaDB console, confirm that you have access to the **example\_database** database:

    SHOW DATABASES;

This will give you the following output:

    Output+--------------------+
    | Database |
    +--------------------+
    | example_database |
    | information_schema |
    +--------------------+
    2 rows in set (0.000 sec)

To exit the MariaDB shell, type:

    exit

At this point, your database system is set up and you can move on to installing PHP, the final component of the LEMP stack.

## Step 3 — Installing PHP for Processing

You have Nginx installed to serve your content and MySQL installed to store and manage your data. Now you can install PHP to process code and generate dynamic content for the web server.

While Apache embeds the PHP interpreter in each request, Nginx requires an external program to handle PHP processing and act as _bridge_ between the PHP interpreter itself and the web server. This allows for a better overall performance in most PHP-based websites, but it requires additional configuration. You’ll need to install `php-fpm`, which stands for “PHP fastCGI process manager”, and tell Nginx to pass PHP requests to this software for processing. Additionally, you’ll need `php-mysql`, a PHP module that allows PHP to communicate with MySQL-based databases. Core PHP packages will automatically be installed as dependencies.

To install the `php-fpm` and `php-mysql` packages, run:

    sudo apt install php-fpm php-mysql

You now have your PHP components installed. Next, you’ll configure Nginx to use them.

## Step 4 — Configuring Nginx to Use the PHP Processor

When using the Nginx web server, _server blocks_ (similar to virtual hosts in Apache) can be used to encapsulate configuration details and host more than one domain on a single server. In this guide, we’ll use **your\_domain** as example domain name. To learn more about setting up a domain name with DigitalOcean, see our [introduction to DigitalOcean DNS](https://www.digitalocean.com/docs/networking/dns/).

On Debian 10, Nginx has one server block enabled by default and is configured to serve documents out of a directory at `/var/www/html`. While this works well for a single site, it can become difficult to manage if you are hosting multiple sites. Instead of modifying `/var/www/html`, let’s create a directory structure within `/var/www` for the **your\_domain** website, leaving `/var/www/html` in place as the default directory to be served if a client request doesn’t match any other sites.

Create the root web directory for **your\_domain** as follows:

    sudo mkdir /var/www/your_domain

Next, assign ownership of the directory with the $USER environment variable, which should reference your current system user:

    sudo chown -R $USER:$USER /var/www/your_domain

Then, open a new configuration file in Nginx’s `sites-available` directory using your preferred command-line editor. Here, we’ll use `nano`:

    sudo nano /etc/nginx/sites-available/your_domain

This will create a new blank file. Paste in the following bare-bones configuration:

/etc/nginx/sites-available/your\_domain

    server {
        listen 80;
        listen [::]:80;
    
        root /var/www/your_domain;
        index index.php index.html index.htm;
    
        server_name your_domain;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        }
    }

This is a basic configuration that listens on port `80` and serves files from the web root you just created. It will only respond to requests to the host or IP address provided after `server_name`, and any files ending in `.php` will be processed by `php-fpm` before Nginx sends the results to the user.

When you’re done editing, save and close the file. If you used `nano` to create the file, do so by typing `CTRL`+`X` and then `y` and `ENTER` to confirm.

Activate your configuration by linking to the config file from Nginx’s `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/

This will tell Nginx to use the configuration next time it is reloaded. You can test your configuration for syntax errors by typing:

    sudo nginx -t

If any errors are reported, go back to your configuration file to review its contents before continuing.

When you are ready, reload Nginx to make the changes:

    sudo systemctl reload nginx

Next, you’ll create a file in your new web root directory to test out PHP processing.

## Step 5 — Creating a PHP File to Test Configuration

Your LEMP stack should now be completely set up. You can test it to validate that Nginx can correctly hand `.php` files off to your PHP processor.

You can do this by creating a test PHP file in your document root. Open a new file called `info.php` within your document root in your text editor:

    nano /var/www/your_domain/info.php

Type or paste the following lines into the new file. This is valid PHP code that will return information about your server:

/var/www/your\_domain/info.php

    <?php
    phpinfo();

When you are finished, save and close the file by typing `CTRL`+`X` and then `y` and `ENTER` to confirm.

You can now access this page in your web browser by visiting the domain name or public IP address you’ve set up in your Nginx configuration file, followed by `/info.php`:

    http://your_domain/info.php

You will see a web page containing detailed information about your server:

![PHP page info](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_debian10/phpinfo.png)

After checking the relevant information about your PHP server through that page, it’s best to remove the file you created as it contains sensitive information about your PHP environment and your Debian server. You can use `rm` to remove that file:

    rm /var/www/your_domain/info.php

You can always regenerate this file if you need it later. Next, we’ll test the database connection from the PHP side.

## Step 6 — Testing Database Connection from PHP (Optional)

If you want to test if PHP is able to connect to MariaDB and execute database queries, you can create a test table with dummy data and query for its contents from a PHP script.

First, connect to the MariaDB console with the database user you created in Step 2 of this guide:

    mariadb -u example_user -p

Create a table named **todo\_list**. From the MariaDB console, run the following statement:

    CREATE TABLE example_database.todo_list (
        item_id INT AUTO_INCREMENT,
        content VARCHAR(255),
        PRIMARY KEY(item_id)
    );

Now, insert a few rows of content in the test table. You might want to repeat the next command a few times, using different values:

    INSERT INTO example_database.todo_list (content) VALUES ("My first important item");

To confirm that the data was successfully saved to your table, run:

    SELECT * FROM example_database.todo_list;

You will see the following output:

    Output+---------+--------------------------+
    | item_id | content |
    +---------+--------------------------+
    | 1 | My first important item |
    | 2 | My second important item |
    | 3 | My third important item |
    | 4 | and this one more thing |
    +---------+--------------------------+
    4 rows in set (0.000 sec)
    

After confirming that you have valid data in your test table, you can exit the MariaDB console:

    exit

Now you can create the PHP script that will connect to MariaDB and query for your content. Create a new PHP file in your custom web root directory using your preferred editor. We’ll use `nano` for that:

    nano /var/www/your_domain/todo_list.php

Add the following content to your PHP script:

    <?php
    $user = "example_user";
    $password = "password";
    $database = "example_database";
    $table = "todo_list";
    
    try {
      $db = new PDO("mysql:host=localhost;dbname=$database", $user, $password);
      echo "<h2>TODO</h2><ol>"; 
      foreach($db->query("SELECT content FROM $table") as $row) {
        echo "<li>" . $row['content'] . "</li>";
      }
      echo "</ol>";
    } catch (PDOException $e) {
        print "Error!: " . $e->getMessage() . "<br/>";
        die();
    }

Save and close the file when you’re done editing.

You can now access this page in your web browser by visiting the domain name or public IP address you’ve set up in your Nginx configuration file, followed by `/todo_list.php`:

    http://your_domain/todo_list.php

You should see a page like this, showing the content you’ve inserted in your test table:

![Example PHP todo list](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_debian10/todo_list.png)

That means your PHP environment is ready to connect and interact with your MariaDB server.

## Conclusion

In this guide, you’ve built a flexible foundation for serving PHP websites and applications to your visitors, using Nginx as web server. You’ve set up Nginx to handle PHP requests through `php-fpm`, and you also set up a MariaDB database to store your website’s data.

To further improve your current setup, you can [install Composer](how-to-install-and-use-composer-on-debian-10) for dependency and package management in PHP, and you can also [install an OpenSSL certificate](how-to-secure-nginx-with-let-s-encrypt-on-debian-10) for your website using [Let’s Encrypt](an-introduction-to-let-s-encrypt).
