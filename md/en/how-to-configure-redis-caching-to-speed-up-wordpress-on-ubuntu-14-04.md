---
author: Scott Miller
date: 2014-12-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-redis-caching-to-speed-up-wordpress-on-ubuntu-14-04
---

# How To Configure Redis Caching to Speed Up WordPress on Ubuntu 14.04

## Introduction

Redis is an open-source key value store that can operate as both an in-memory store and as cache. Redis is a data structure server that can be used as a database server on its own, or paired with a relational database like MySQL to speed things up, as we’re doing in this tutorial.

For this tutorial, Redis will be configured as a cache for WordPress to alleviate the redundant and time-consuming database queries used to render a WordPress page. The result is a WordPress site which is much faster, uses less database resources, and provides a tunable persistent cache. This guide applies to Ubuntu 14.04.

While every site is different, below is an example benchmark of a default Wordpress installation home page with and without Redis, as configured from this guide. Chrome developer tools were used to test with browser caching disabled.

Default WordPress home page without Redis:

804ms page load time

Default WordPress home page with Redis:

449ms page load time

**Note:** This implementation of Redis caching for WordPress relies on a well-commented but third-party script. The script is hosted on DigitalOcean’s asset server, but was developed externally. If you would like to make your own implementation of Redis caching for WordPress, you will need to do some more work based on the concepts presented here.

### Redis vs. Memcached

Memcached is also a popular cache choice. However, at this point, Redis does everything Memcached can do, with a much larger feature set. This [Stack Overflow page](http://stackoverflow.com/questions/10558465/memcache-vs-redis) has some general information as an overview or introduction to persons new to Redis.

### How does the caching work?

The first time a WordPress page is loaded, a database query is performed on the server. Redis remembers, or _caches_, this query. So, when another user loads the Wordpress page, the results are provided from Redis and from memory without needing to query the database.

The Redis implementation used in this guide works as a persistent object cache for WordPress (no expiration). An object cache works by caching the SQL queries in memory which are needed to load a WordPress page.

When a page loads, the resulting SQL query results are provided from memory by Redis, so the query does not have to hit the database. The result is much faster page load times, and less server impact on database resources. If a query is not available in Redis, the database provides the result and Redis adds the result to its cache.

If a value is updated in the database (for example, a new post or page is created in WordPress) the Redis value for that query is invalidated to prevent bad cached data from being presented.

If you run into problems with caching, the Redis cache can be purged by using the `flushall` command from the Redis command line:

    redis-cli

Once you see the prompt, type:

    flushall

Additional Reference: [WordPress Object Cache Documentation](http://codex.wordpress.org/Class_Reference/WP_Object_Cache)

### Prerequisites

Before starting this guide, you’ll need to set up a sudo user and install WordPress.

- Ubuntu 14.04 Droplet (1 GB or higher recommended)
- Add a [sudo user](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps)
- Install WordPress. This guide has been tested with [these instructions](how-to-install-wordpress-on-ubuntu-14-04), although there are many ways to install WordPress

## Step 1 — Install Redis

In order to use Redis with WordPress, two packages need to be installed: `redis-server` and `php5-redis`. The `redis-server` package provides Redis itself, while the `php5-redis` package provides a PHP extension for PHP applications like WordPress to communicate with Redis.

Install the softare:

    sudo apt-get install redis-server php5-redis

## Step 2 — Configure Redis as a Cache

Redis can operate both as a NoSQL database store as well as a cache. For this guide and use case, Redis will be configured as a cache. In order to do this, the following settings are required.

Edit the file `/etc/redis/redis.conf` and add the following lines at the bottom:

    sudo nano /etc/redis/redis.conf

Add these lines at the end of the file:

    maxmemory 256mb
    maxmemory-policy allkeys-lru

When changes are complete, save and close the file.

## Step 3 — Obtain Redis Cache Backend Script

This PHP script for WordPress was originally developed by [Eric Mann](https://github.com/ericmann/Redis-Object-Cache/raw/master/object-cache.php). It is a Redis object cache backend for WordPress.

Download the `object-cache.php` script. This download is from DigitalOcean’s asset server, but **this is a third-party script**. You should read the comments in the script to see how it works.

Download the PHP script:

    wget https://assets.digitalocean.com/articles/wordpress_redis/object-cache.php

Move the file to the `/wp-content` directory of your WordPress installation:

    sudo mv object-cache.php /var/www/html/wp-content/

Depending on your WordPress installation, your location may be different.

## Step 4 — Enable Cache Settings in wp-config.php

Next, edit the `wp-config.php` file to add a cache key salt with the name of your site (or any string you would like).

    nano /var/www/html/wp-config.php

Add this line at the end of the `* Authentication Unique Keys and Salts.` section:

    define('WP_CACHE_KEY_SALT', 'example.com');

You can use your domain name or another string as the salt.

> **Note:** For users hosting more than one WordPress site, each site can share the same Redis installation as long as it has its own unique cache key salt.

Also, add the following line after the `WP_CACHE_KEY_SALT` line to create a persistent cache with the Redis object cache plugin:

    define('WP_CACHE', true);

All together, your file should look like this:

     * Authentication Unique Keys and Salts.
    
    . . .
    
    define('NONCE_SALT', 'put your unique phrase here');
    
    define('WP_CACHE_KEY_SALT', 'example.com');
    define('WP_CACHE', true);

Save and close the file.

## Step 5 — Restart Redis and Apache

Finally, restart `redis-service` and `apache2`.

Restart Redis:

    sudo service redis-server restart

Restart Apache:

    sudo service apache2 restart

Restart `php5-fpm` if you are using it; this is not part of the basic installation on DigitalOcean:

    sudo service php5-fpm restart 

That’s it! Your WordPress site is now using Redis caching. If you check your page load speeds and resource use, you should notice improvements.

## Monitor Redis with redis-cli

To monitor Redis, use the `redis-cli` command like so:

    redis-cli monitor

When you run this command, you will see the real-time output of Redis serving cached queries. If you don’t see anything, visit your website and reload a page.

Below is example output from a WordPress site configured per this guide using Redis:

    OK
    1412273195.815838 "monitor"
    1412273198.428472 "EXISTS" "example.comwp_:default:is_blog_installed"
    1412273198.428650 "GET" "example.comwp_:default:is_blog_installed"
    1412273198.432252 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.432443 "GET" "example.comwp_:options:notoptions"
    1412273198.432626 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.432799 "GET" "example.comwp_:options:alloptions"
    1412273198.433572 "EXISTS" "example.comwp_site-options:0:notoptions"
    1412273198.433729 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.433876 "GET" "example.comwp_:options:notoptions"
    1412273198.434018 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.434161 "GET" "example.comwp_:options:alloptions"
    1412273198.434745 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.434921 "GET" "example.comwp_:options:notoptions"
    1412273198.435058 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.435193 "GET" "example.comwp_:options:alloptions"
    1412273198.435737 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.435885 "GET" "example.comwp_:options:notoptions"
    1412273198.436022 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.436157 "GET" "example.comwp_:options:alloptions"
    1412273198.438298 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.438418 "GET" "example.comwp_:options:notoptions"
    1412273198.438598 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.438700 "GET" "example.comwp_:options:alloptions"
    1412273198.439449 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.439560 "GET" "example.comwp_:options:notoptions"
    1412273198.439746 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.439844 "GET" "example.comwp_:options:alloptions"
    1412273198.440764 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.440868 "GET" "example.comwp_:options:notoptions"
    1412273198.441035 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.441149 "GET" "example.comwp_:options:alloptions"
    1412273198.441813 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.441913 "GET" "example.comwp_:options:notoptions"
    1412273198.442023 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.442121 "GET" "example.comwp_:options:alloptions"
    1412273198.442652 "EXISTS" "example.comwp_:options:notoptions"
    1412273198.442773 "GET" "example.comwp_:options:notoptions"
    1412273198.442874 "EXISTS" "example.comwp_:options:alloptions"
    1412273198.442974 "GET" "example.comwp_:options:alloptions"

Press `CTRL-C` to stop the output.

This is useful for seeing exactly what queries Redis is processing.

### Conclusion

After following this guide, WordPress will now be configured to use Redis as a cache on Ubuntu 14.04.

Below are some additional security and administration guides for WordPress that may be of interest:

[How To Configure Secure Updates and Installations in WordPress on Ubuntu](how-to-configure-secure-updates-and-installations-in-wordpress-on-ubuntu)

[How To Use WPScan to Test for Vulnerable Plugins and Themes in Wordpress](how-to-use-wpscan-to-test-for-vulnerable-plugins-and-themes-in-wordpress)

[How To Use WP-CLI to Manage your WordPress Site from the Command Line](how-to-use-wp-cli-to-manage-your-wordpress-site-from-the-command-line)
