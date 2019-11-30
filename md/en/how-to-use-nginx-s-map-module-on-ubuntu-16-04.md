---
author: Mateusz Papiernik
date: 2016-09-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-nginx-s-map-module-on-ubuntu-16-04
---

# How to Use Nginx's map Module on Ubuntu 16.04

## Introduction

When configuring a server for a website, there are some common conditional actions you may need to implement. For example, maybe some files should be cached by the user’s browser for longer than others, or some parts of the website should only be allowed via a secure connection (like anything that requires a user’s password), while other parts of the website don’t.

Another simple, common example is making sure that when a new webpage is published in place of an old one, all the old addresses will redirect to the correct places. This is useful because it means old links and bookmarks won’t stop working, and it also preserves Google’s caching.

Nginx’s map module lets you create variables in Nginx’s configuration file whose values are conditional — that is, they depend on other variables’ values. In this guide, we will look at how to use Nginx’s map module implement two examples: how to set up a list of redirects from old website URLs to new ones and how to create a whitelist of countries to control traffic to your website.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up with [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user.

- Nginx installed on your server by following the [How To Install Nginx on Ubuntu 16.04 tutorial](how-to-install-nginx-on-ubuntu-16-04).

## Step 1 — Creating and Testing an Example Webpage

First, we will create a test file representing a newly published website. We’ll use this file to test our configuration.

Let’s create a simple page, `index.html`, in the default Nginx website directory. This file will just have plain text describing what’s inside: Home.

    sudo sh -c 'echo "Home" > /var/www/html/index.html'

With this test file in place, next we’ll check that it’s being served correctly with `curl`. We don’t need to specify `index.html` for this command because that file is served by default if no exact filename is provided.

    curl http://localhost/

In response, you should see a single word saying **Home** just like below:

Nginx response

    Home

Now let’s try to access a file doesn’t exist in `/var/www/html/`, like `old.html`.

    curl -L http://localhost/old.html

The response will be a system error message, **404 Not Found** , meaning the page does not exist.

Nginx response

    <html>
    <head><title>404 Not Found</title></head>
    <body bgcolor="white">
    <center><h1>404 Not Found</h1></center>
    <hr><center>nginx/1.10.0 (Ubuntu)</center>
    </body>
    </html>

We’re just using a dummy website in this tutorial, but if `old.html` was a page on a real website that used to exist and was deleted, returning a 404 would mean that all links to that page are broken. This is less than ideal, because those links may have been indexed by Google, printed out or written down, or shared by any other means.

In the next step, we’ll utilize the map module to make sure this old address will work again by redirecting viewers to the new replacements automatically.

## Step 2 — Configuring the Redirects

For small websites with only a few pages, simple `if` conditional statements can be used for redirects and similar things. However, such a configuration is not easy to maintain or extend in the long run as the list of conditions grows longer.

The map module is a more elegant, concise solution. It allows you to compare Nginx variable values against a list of conditions, and then associate a new value with the variable depending on the match. In this example, we’ll be comparing the requested URL with the list of old pages that we want to redirect to their new counterparts. For each old address, we’ll associate the new one.

The map module is a core Nginx module, which means it doesn’t need to be installed separately to be used. To create the necessary map and redirect configuration, open the default server block Nginx configuration file in `nano` or your favorite text editor.

    sudo nano /etc/nginx/sites-available/default

Find the `server` configuration block, which looks like this:

/etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
    . . .

We’ll be adding two new sections: one before the `server` block, and one inside it.

The section before the `server` block is a new `map` block, which defines the mapping between the old URLs and the new one using the map module. The section inside the `server` block is the redirect itself.

Modified /etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    # Old website redirect map
    #
    map $uri $new_uri {
        /old.html /index.html;
    }
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        # Old website redirect
        if ($new_uri) {
            rewrite ^ $new_uri permanent;
        }
    . . .

The `map $uri $new_uri` directive takes the contents of system `$uri` variable, which contains the URL address of the requested page, and then compares it against the list of conditions in the curly brackets. Each item in the list of conditions has two sections: the value to match against, and the new value to assign to the variable if it matches.

The line `/old.html /index.html` inside the `map` block means that if `$uri`’s value is `/old.html`, `$new_uri` will be changed to `/index.html`. If it doesn’t match, it’s not changed. Here, we only define one condition, but you can define as many conditions as you want in a map.

Then, using a conditional `if` statement inside the `server` block, we check if the `$new_uri` variable’s value is set. If it is, it means the condition in the map was satisfied, and we should redirect to the new website using the `rewrite` command. The `permanent` keyword ensured that the redirect will be a **301 Moved Permanently** HTTP redirect, which means that the old address is no longer valid and will not come back online.

Save and close the file to exit.

To enable the new configuration, restart Nginx.

    sudo systemctl restart nginx

To test the new configuration, execute the same request as before:

    curl -L http://localhost/old.html

This time there will be no **404 Not Found** error in the output. Instead, you’ll see the simple home page we created in Step 1.

Nginx response

    Home

This means the map has been configured properly and you can use it to redirect URLs by adding more entries to the map.

Redirecting URLs is one useful application of the map module. Another, which we’ll explore in the next step, is filtering traffic based on the visitors’ geographical location.

## Step 3 — Restricting Website Access to Certain Countries

Sometimes, a server might receive an excessive quantity of automated, malicious requests. This could be a DDoS attack, an attempt to brute-force passwords to website administrative panels, or an attempt to exploit known vulnerabilities in software to attack the website and use it to send spam or modify the site contents.

Such automated attacks may come from many different distributed servers in many different countries, making it difficult to block. One solution to mitigate the effects of an attack like this is to create a whitelist of countries that can access the website.

It’s not a perfect solution, but in situations where restricting access to the website based on the visitor’s geographical location is a sensible choice and does not limit the audience for the website, this solution has the benefit of being fast and less error prone.

Filtering at the server level is faster than filtering at the website level and also covers all requests (including static files, like images). This kind of filtering also prevents requests from reaching the website software at all, which makes vulnerabilities harder to exploit.

To make use of the geographical filtering, let’s first create a new configuration file.

    sudo nano /etc/nginx/conf.d/geoip.conf

Paste the following contents into the file. This tells Nginx where to find the GeoIP database that contains mappings between visitors IP addresses and their respective countries. This database comes preinstalled with Ubuntu 16.04.

/etc/nginx/conf.d/geoip.conf

    . . .
    # GeoIP database path
    #
    
    geoip_country /usr/share/GeoIP/GeoIP.dat;

The next step is to create the necessary map and restriction configuration. Open the default server block Nginx configuration.

    sudo nano /etc/nginx/sites-available/default

Find the `server` configuration block which, after the modifications in steps 1 and 2, looks like this:

/etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    # Old website redirect map
    #
    map $uri $new_uri {
        /old.html /index.html;
    }
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        # Old website redirect
        if ($new_uri) {
            rewrite ^ $new_uri permanent;
        }
    . . .

We’ll be adding two new sections: one before the `server` block and one inside it.

The section before the `server` block is a new `map` block, which defines the default action (access disallowed) as well as the list of country codes allowed to access the website. The section inside the `server` block denies access to the website if the `map` result says so.

Modified /etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    # Allowed countries
    #
    map $geoip_country_code $allowed_country {
        default no;
        country_code_1 yes;
        country_code_2 yes;
    }
    
    # Old website redirect map
    #
    map $uri $new_uri {
        /old.html /index.html;
    }
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        # Disallow access based on GeoIP
        if ($allowed_country = no) {
            return 444;
        }
    
        # Old website redirect
        if ($new_uri) {
            rewrite ^ $new_uri permanent;
        }
    . . .

Save and close the file to exit.

Here, we used `country_code_1` and `country_code_2` as placeholders. Replace these variables with the two character country code for the country or countries you want to whitelist. You can use [the ISO’s full, searchable list of all country codes](https://www.iso.org/obp/ui/#search) to find. For example, the two character code for the United States is `US`.

Unlike the first example, in this `map` block, the `$allowed_country` variable will always be set to something. By default, it’s set to `no`; if the `$geoip_country_code` variable matches one of the country codes in the block, it’s set to `yes`. If the `$allowed_country` variable is `no`, we return a **444 Connection Closed Without Response** instead of serving the actual website.

To enable the new configuration, restart Nginx.

    sudo systemctl restart nginx

If you didn’t add your country to the whitelist, when you try to visit `http://your_server_ip`, you’ll see an error message like **The page isn’t working** or **The page didn’t send any data**. If you do add your country to the whitelist, you’ll see **Home** as before.

## Conclusion

While it might be a very simple example on how to use the map module, it shows the mechanism that can be used in many other different ways. The map module not only allows simple comparisons, but also supports regular expressions allowing more complex matches. It is a great way to make configuration files cleaner if multiple conditions must be evaluated.

Another very popular use case for map module is conditional redirects for secure parts of the website in an otherwise non-SSL environment. Setting up forced SSL connection just for forms requiring, for example, password input is a nice example how to apply the map module in the real world scenario and I encourage experimenting with such setup.

More detailed information can be found [in Nginx’s official map module documentation](http://nginx.org/en/docs/http/ngx_http_map_module.html).
