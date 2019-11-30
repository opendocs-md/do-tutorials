---
author: Justin Ellingwood
date: 2016-11-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-redis-server-as-a-session-handler-for-php-on-ubuntu-16-04
---

# How to Set Up a Redis Server as a Session Handler for PHP on Ubuntu 16.04

## Introduction

Redis is an open source key-value cache and storage system, also referred to as a data structure server due to its advanced support for several data types, such as hashes, lists, sets, and bitmaps, amongst others. It also supports clustering, making it useful in highly-available and scalable environments.

In this tutorial, we’ll see how to install and configure an external Redis server to be used as a session handler for a PHP application running on Ubuntu 16.04.

The session handler is responsible for storing and retrieving data saved into sessions. By default, PHP uses **files** for this. This works well enough for a single server, but has some significant performance and scalability limitations because the session information is tied to a single server.

An external session handler provides a central location for shared session data that can be used by multiple application servers. This is important when creating [scalable PHP environments](https://www.digitalocean.com/company/blog/horizontally-scaling-php-applications/) behind a [load balancer](an-introduction-to-haproxy-and-load-balancing-concepts) because the same session data will be available regardless of which application server serves an individual request.

## Prerequisites

This tutorial will configure session handling using two servers. To follow along, you will need:

- A PHP web server running [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04) or [LEMP](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04) on Ubuntu 16.04. We will refer to this server as **web**.
- A second, clean Ubuntu 16.04 server where Redis will be installed. We will refer to this server as **redis**.

You’ll need to have a non-root user with `sudo` privileges configured on each of these servers. We will also assume that each of the servers has a basic firewall running. You can set up both of these requirements by following our [Ubuntu 16.04 initial server setup guide](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-16-04) on both servers.

## Step 1: Install the Redis Server and Client Software

Our first step will be to install the necessary software on both of our machines. Our **redis** machine will need a Redis server. On our **web** machine, we will install the Redis PHP extension for session handling and the Redis command line client for testing.

### Installing the Redis Server

The first thing we need to do is get the Redis server running on our **redis** machine.

We will be using the regular Ubuntu package manager with a trusted PPA repository provided by Chris Lea. This is necessary to make sure we get the latest stable version of Redis.

**Note:** As a general piece of security advice, you should only use PPAs from trusted sources.

First, add the PPA repository by running:

    sudo apt-add-repository ppa:chris-lea/redis-server

Press `ENTER` to confirm.

Next, update the package index and install the Redis server by typing:

    sudo apt-get update
    sudo apt-get install redis-server

Redis should now be installed and running on your server. Test that the service is running and accepting connections by typing:

    redis-cli ping

    Redis server outputPONG

This will connect to the Redis instance running on **localhost** on port **6379**. You should get **PONG** as the response.

### Installing the Redis Client and PHP Extension

Next, install the Redis command line client and the Redis PHP extension on the **web** server. We will be using the command line client to easily test connectivity and authentication. We will use the PHP extension to store our session data.

Update the local package index and install the software on your **web** server by typing:

    sudo apt-get update
    sudo apt-get install redis-tools php-redis

You should now have access to the `redis-cli` tool, although you do not yet have access to the server to test.

## Step 2: Configure Redis to Accept External Connections

By default, Redis only allows connections from `localhost`, which basically means you’ll only have access from inside the server where Redis is installed. We need to change this configuration to allow connections coming from other servers.

Redis offers no native encryption options and assumes that it has been deployed to an isolated network of trusted peers. This means that to securely allow external connections, either both servers must be on an isolated network or you will need to secure the traffic between them in another way.

### If Redis Is Deployed to an Isolated Network…

If your servers are operating in an isolated network, you probably only need to adjust Redis’s configuration file to bind to your isolated network IP address.

On the **redis** server, backup and open the Redis configuration file:

    sudo cp /etc/redis/redis.conf /etc/redis/redis.conf.bak
    sudo nano /etc/redis/redis.conf

Find the `bind` line and append the Redis server’s isolated network IP address:

/etc/redis/redis.conf

    bind 127.0.0.1 isolated_IP_address

Save and close the file. Restart the service by typing:

    sudo systemctl restart redis-server.service

Open up access to the Redis port:

    sudo ufw allow 6379

Redis is now be able to accept connections from your isolated network.

### If Redis Is Not Deployed to an Isolated Network…

For networks that are not isolated or that you do not control, it is imperative that traffic is secured through other means. There are many options to secure traffic to Redis servers, including:

- [Tunneling with stunnel](how-to-encrypt-traffic-to-redis-with-stunnel-on-ubuntu-16-04): You will need to set up an incoming tunnel on the **redis** server and an outgoing tunnel on the **web** server. The web server will connect to a local port to communicate with the remote Redis service.
- [Tunneling with spiped](how-to-encrypt-traffic-to-redis-with-spiped-on-ubuntu-16-04): The **web** server should function as the `spiped` client machine. You will need to create a systemd unit files on each server. The web server will connect to a local port to communicate with the remote Redis service.
- [Setting up a VPN with PeerVPN](how-to-encrypt-traffic-to-redis-with-peervpn-on-ubuntu-16-04): Both servers will need to be accessible on the VPN. The **web** server will be able to access the **redis** server using its VPN IP address.

Using one of the methods above, configure secure access from your **web** server to your **redis** server. You will need to know the IP address and port that your **web** machine will use to connect to the Redis service on the remote machine.

At this point, you should be able to access your Redis server from the web server securely.

## Step 3: Set a Password for the Redis Server

To add an extra layer of security to your Redis installation, you are encouraged to set a password for accessing the server data. We will edit the Redis configuration file at `/etc/redis/redis.conf`:

    sudo nano /etc/redis/redis.conf

Find the `requirepass` directive and set it to a strong passphrase. While your Redis traffic should be secure from outside parties, this provides authentication to Redis itself. Since Redis is fast and does not rate limit password attempts, choose a strong, complex passphrase to protect against brute force attempts:

/etc/redis/redis.conf

    requirepass yourverycomplexpasswordhere

Save and close the file when you are finished.

Restart the Redis service to implement the change:

    sudo systemctl restart redis-server.service

Your Redis server should now reject unauthenticated requests.

## Step 4: Test Redis Connection and Authentication

To test if your changes work as expected, connect to the Redis service from the **web** machine.

By default, the Redis server listens on 6379 on the local interface, but each of the network security options we covered above modifies the default in some way for external parties. We can use the `redis-cli` client with the `-h` option to specify the IP address and the `-p` option to specify the port needed to connect to the remote service. You can leave out either of these if they use the default options (127.0.0.1 and 6379 respectively).

The values you use will depend on the method you used to secure your network traffic:

- **isolated network** : Use the Redis server’s isolated network IP address. The default Redis port (6379) is used, so we don’t need to mention it: `redis-cli -h redis_isolated_IP`
- **stunnel** or **spiped** : Use the local port that tunnels to the remote Redis service: `redis-cli -p 8000`
- **PeerVPN** : Use the Redis server’s VPN IP address: `redis-cli -h 10.8.0.1`

The general form is:

    redis-cli -h ip_to_contact_redis -p port_to_contact_redis

You should be able to connect to the remote Redis instance from the **web** server.

If you defined a password and now try to access the data, you should get an AUTH error:

    keys *

    Web server output(error) NOAUTH Authentication required.

To authenticate, you just need to run the `AUTH` command, providing the same password you defined in the `/etc/redis/redis.conf` file:

    AUTH yourverycomplexpasswordhere

You should get an **OK** as response indicating that your credentials were accepted.

    Web server outputOK

Next, list the keys that are set within Redis:

    keys *

If this is a fresh Redis server, the output should be similar to this:

    Web server output(empty list or set)

This output just means your Redis server is empty, which is exactly what we expect. The **web** server is not yet configured to use this Redis server as a session handler.

Exit back to the command shell by typing:

    exit

Now that we’ve verified that we can connect successfully with authentication, we can make Redis our default session handler.

## Step 5: Set Redis as the Default Session Handler on the Web Server

Now we need to edit the `php.ini` file on the **web** server to change the default session handler for PHP. The location of this file will depend on your current stack.

For a **LAMP** stack on Ubuntu 16.04 installed from the default repositories, this is usually `/etc/php/7.0/apache2/php.ini`. For a **LEMP** stack on Ubuntu 16.04, the path is usually `/etc/php/7.0/fpm/php.ini`. If you’ve verified that one of these locations is correct, feel free to skip the next section.

### (Optional) Finding the Correct php.ini File

If you are unsure about the location of your main `php.ini` file, you can find out by using the `phpinfo()` function. Open a file on your **web** server called `info.php` in your document root, which by default will be `/var/www/html` for both LAMP and LEMP:

    sudo nano /var/www/html/info.php

Place the following code in the file:

/var/www/html/info.php

    <?php
    phpinfo();

Visit your **web** server’s domain name or IP address in your browser, followed by `/info.php`:

    http://web_server_domain_or_IP/info.php

Look for the row containing “Loaded Configuration File”, and you should find the exact location of the main `php.ini` loaded.

Remove the file when you are finished, as it displays sensitive information about your environment:

    sudo rm /var/www/html/info.php

Now that you know where the file is located, you can move onto editing.

### Modifying the Configuration

Open the `php.ini` file for editing.

If you are using a **LAMP** stack in its default configuration, the command you will need is:

    sudo nano /etc/php/7.0/apache2/php.ini

If you are using a **LEMP** stack in its default configuration, the command you will need is:

    sudo nano /etc/php/7.0/fpm/php.ini

If you discovered a different path using the `phpinfo()` method outlined above, substitute that path here instead.

Inside of the `php.ini` file, search for the line containing `session.save_handler`. The default value is `files`. Change this to `redis` to use the Redis PHP extension.

php.ini

     session.save_handler = redis

Next, find the line containing `session.save_path`. You will need to uncomment it and change the value so it contains your Redis connection string.

The connection string can be constructed using the following format, all in one line:

    tcp://IP_address:port?auth=redis_password

Again, the proper values will depend on the secure networking strategy you selected. Use the same values that you provided to the `redis-cli` command earlier. For example, if you were using `stunnel` or `spiped`, the `session.save_path` would likely look something like this:

php.ini

     session.save_path = "tcp://127.0.0.1:8000?auth=yourverycomplexpasswordhere"

Save and close the file when you are finished. Next, restart the PHP service to implement your changes.

In **LAMP** environments, type:

    sudo systemctl restart apache2

In **LEMP** environments, type:

    sudo systemctl restart php7.0-fpm

PHP should now be configured to use Redis as the session handler.

## Step 6: Test Redis Session Handling

To make sure your sessions are now handled by Redis, you will need a PHP script or application that stores information in sessions. We are going to use a simple script that implements a counter. Each time you reload the page, the printed number will be incremented.

Create a file named `test.php` on the **web** server inside your document root folder:

    sudo nano /var/www/html/test.php

Inside, paste the following code:

/var/www/html/test.php

     <?php
    //simple counter to test sessions. should increment on each page reload.
    session_start();
    $count = isset($_SESSION['count']) ? $_SESSION['count'] : 1;
    
    echo $count;
    
    $_SESSION['count'] = ++$count;

Save and close the file.

Point your browser to the **web** server’s public IP address followed by `/test.php` in order to access the script:

    http://web_server_public_IP/test.php

It should increment the number you see each time you reload the page.

Now, on your **redis** machine, use `redis-cli` to open a session. Since we’re connecting to the local instance, we won’t have to provide an IP address or port:

    redis-cli

Authenticate using the Redis password:

    AUTH yourverycomplexpasswordhere

    Redis server outputOK

Now, check the existing keys:

    keys *

You should see a new entry for our PHP session:

    Redis server output1) "PHPREDIS_SESSION:2ofnvhhr6gdvp88u0c4e7kb800"

If you ask for the value of the key, you should be able to see the current counter value:

    get PHPREDIS_SESSION:2ofnvhhr6gdvp88u0c4e7kb800

    Redis server output"count|i:6;"

This shows that the session information is being stored on the Redis server. You can connect additional web servers to the Redis server for centralized session management.

## Conclusion

Redis is a powerful and fast key-value storage service that can also be used as session handler for PHP, enabling scalable PHP environments by providing a distributed system for session storage. For more information about scaling PHP applications, you can check this article: [Horizontally Scaling PHP Applications](https://www.digitalocean.com/company/blog/horizontally-scaling-php-applications/).
