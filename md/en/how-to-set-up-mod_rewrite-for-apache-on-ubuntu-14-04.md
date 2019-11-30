---
author: Alvin Wan
date: 2015-06-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_rewrite-for-apache-on-ubuntu-14-04
---

# How To Set Up mod_rewrite for Apache on Ubuntu 14.04

## Introduction

In this tutorial, we will activate and learn how to manage URL rewrites using Apache2’s `mod_rewrite` module. This tool allows us to rewrite URLs in a cleaner fashion, translating human-readable paths into code-friendly query strings.

This guide is split into two halves: the first sets up a sample web application and the second explains commonly-used rewrite rules.

## Prerequisites

To follow this tutorial, you will need:

- One fresh Ubuntu 14.04 Droplet
- A sudo non-root user, which you can set up by following steps 2 and 3 of [this tutorial](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps)

## Step 1 — Installing Apache

In this step, we will use a built-in _package installer_ called `apt-get`. It simplifies management drastically and facilitates a clean installation.

First, update the system’s package index. This will ensure that old or outdated packages do not interfere with the installation.

    sudo apt-get update

Apache2 is the aforementioned HTTP server and the world’s most commonly used. To install it, run the following:

    sudo apt-get install apache2

For information on the differences between Nginx and Apache2, the two most popular open-source web servers, see [this article](apache-vs-nginx-practical-considerations).

## Step 2 — Enabling mod\_rewrite

Now, we need to activate `mod_rewrite`.

    sudo a2enmod rewrite

This will activate the module or alert you that the module is already in effect. To put these changes into effect, restart Apache.

    sudo service apache2 restart

## Step 3 — Setting Up .htaccess

In this section, we will setup a `.htaccess` file for simpler rewrite rule management.

A `.htaccess` file allows us to modify our rewrite rules without accessing server configuration files. For this reason, `.htaccess` is critical to your web application’s security. The period that precedes the filename ensures that the file is hidden.

We will need to set up and secure a few more settings before we can begin.

First, allow changes in the `.htaccess` file. Open the default Apache configuration file using `nano` or your favorite text editor.

    sudo nano /etc/apache2/sites-enabled/000-default.conf

Inside that file, you will find the `<VirtualHost *:80>` block on line 1. Inside of that block, add the following block:

    /etc/apache2/sites-available/default<Directory /var/www/html>
                    Options Indexes FollowSymLinks MultiViews
                    AllowOverride All
                    Order allow,deny
                    allow from all
    </Directory>

Your file should now match the following. Make sure that all blocks are properly indented.

    /etc/apache2/sites-available/default<VirtualHost *:80>
        <Directory /var/www/html>
    
            . . .
    
        </Directory>
    
        . . .
    </VirtualHost>

To put these changes into effect, restart Apache.

    sudo service apache2 restart

Now, create the `.htaccess` file.

    sudo nano /var/www/html/.htaccess

Add this first line at the top of the new file to activate the `RewriteEngine`.

    /var/www/html/.htaccessRewriteEngine on

Save and exit the file.

To ensure that other users may only _read_ your `.htaccess`, run the following command to update permissions.

    sudo chmod 644 /var/www/html/.htaccess

You now have an operational `.htaccess` file, to govern your web application’s routing rules.

## Step 4 — Setting Up Files

In this section, we will set up a basic URL rewrite, which converts pretty URLs into actual paths to code. Specifically, we will allow users to access `example.com/about`.

We will begin by creating a file named `about.html`.

    sudo nano /var/www/html/about.html

Copy the following code into the HTML page.

    /var/www/html/about.html<html>
        <head>
            <title>About Us</title>
        </head>
        <body>
            <h1>About Us</h1>
        </body>
    </html>

You may access your web application at `your_server_ip/about.html` or `example.com/about.html`. Now notice that only `about.html` is accessible; if you try to access `your_server_ip/about`, you will get a **Not Found** error. We would like users to access `about` instead. Our rewrite rules will allow this very functionality.

Open up the `.htaccess` file.

    sudo nano /var/www/html/.htaccess

After the first line, add the following.

    /var/www/html/.htaccessRewriteRule ^about$ about.html [NC]

Your file should now be identical to the following.

    /var/www/html/.htaccessRewriteEngine on
    RewriteRule ^about$ about.html [NC]

Congratulations. You can now access `example.com/about` in your browser!

This is a good simple example that shows the general syntax that all Rewrite Rules follow.

`^about$` is the string that gets matched from the URL. That is, it’s what the viewer types in her browser. Our example uses a few _metacharacters_.

- `^` indicates the start of the URL, after `example.com/` is stripped away. 
- `$` indicates the end of the URL
- `about` matches the string “about”

`about.html` is the actual path that the user accesses; that is, Apache will still serve the `about.html` file.

`[NC]` is a _flag_ that ignores capitalization in the URL.

With the rule shown above, the following URLs will point to `about.html`:

- `example.com/about`
- `example.com/About`
- `example.com/about.html`

The following will not:

- `example.com/about/`
- `example.com/contact`

## Common Patterns

In this section, we will show some commonly-used directives.

Your web application is now running and is governed by a protected `.htaccess` file. The simplest example was included above. We will explore an additional two examples in this section.

You can set up example files at the result paths if you would like, but this tutorial does not include creating the HTML and PHP files; just the rules for rewriting.

### Example 1: Simplifying Query Strings with RewriteRule

All `RewriteRule`s abide by the following format:

    RewriteRule pattern substitution [flags]

- **RewriteRule** : specifies the directive `RewriteRule`
- **pattern** : a regular expression that matches the desired string
- **substitution** : path to the actual URL
- **flags** : optional parameters that can modify the rule

Web applications often make use of _query strings_, which are appended to a URL using the `?` question mark and delimited using the `&` ampersand. These are ignored when matching rewrite rules. However, sometimes query strings may be required for passing data between pages. For example, a search result page written in PHP may utilize something akin to the following:

    http://example.com/results.php?item=shirt&season=summer

In this example, we would like to simplify this to become:

    http://example.com/shirt/summer

**Example 1A: Simple Replacement**

Using a rewrite rule, we could use the following:

    /var/www/html/.htaccessRewriteRule ^shirt/summer$ results.php?item=shirt&season=summer

The above is fairly self-explanatory, as it actually maps `shirt/summer` to `results.php?item=shirt&season=summer`. This achieves our desired effect.

**Example 1B: Matching Options**

However, we would like to generalize this to include all seasons. So, we will do the following:

- Specify a series of options using the `|` boolean, meaning “OR”
- Group the match using `()`, then reference the group using `$1`, with `1` for the first matched group

The Rewrite Rule now becomes:

    /var/www/html/.htaccessRewriteRule ^shirt/(summer|winter|fall|spring) results.php?item=shirt&season=$1

The rule shown above matches a URL of `shirt/` followed by a specified season. That season is grouped using `()` and then referenced with the `$1` in the subsequent path. This means that, for example, that:

    http://example.com/shirt/winter

becomes:

    http://example.com/results.php?item=shirt&season=winter

This also achieves the desired effect.

**Example 1C: Matching Character Sets**

However, we would also like to specify any type of item, not just URLs at `/shirt`. So, we will do the following:

- Write a _regular expression_ that matches all alphanumeric characters. The bracket expression `[]` matches any character inside of it, and the `+` matches any number of characters specified in the brackets
- Group the match, and reference it with `$2` as the second variable in the file

    /var/www/html/.htaccessRewriteRule ^([A-Za-z0-9]+)/(summer|winter|fall|spring) results.php?item=$1&season=$2

The above will convert, for example:

    http://example.com/pants/summer

to:

    http://example.com/results.php?item=pants&season=summer

**Example 1D: Passing Query Strings**

This section doesn’t introduce any new concepts but addresses an issue that may come up. Using the above example, say we would like to redirect `http://example.com/pants/summer` but will pass an additional query string `?page=2`. We would like the following:

    http://example.com/pants/summer?page=2

to map to:

    http://example.com/results.php?item=pants&season=summer&page=2

If you were to attempt to access the above URL with our current settings, you would find that the query string `page=2` got lost. This is easily fixed using an additional `QSA` flag. Modify the rewrite rule to match the following, and the desired behavior will be achieved.

    /var/www/html/.htaccessRewriteRule ^([A-Za-z0-9]+)/(summer|winter|fall|spring) results.php?item=$1&season=$2 [QSA]

### Example 2: Adding Conditions with Logic

`RewriteCond` lets us add conditions to our rewrite rules. All `RewriteCond`s abide by the following format:

    RewriteCond TestString Condition [Flags]

- **RewriteCond** : specifies the `RewriteCond` directive
- **TestString** : the string to test against
- **Condition** : the pattern to match
- **Flags** : optional parameters that may modify the condition

If a `RewriteCond` evaluates to true, the `RewriteRule` immediately following will be considered.

**Example 2A: Default Page**

In an imaginary administration panel, we may want to direct all malformed URLs back to the home page, instead of greeting users with a 404. Using a condition, we can check to see if the requested file exists.

    /var/www/html/.htaccessRewriteCond %{REQUEST_FILENAME} !-f 
    RewriteRule ^admin/(.*)$ /admin/home

This will redirect something like `/admin/blargh` to `/admin/home`.

With the above:

- `%{REQUEST_FILENAME}` is the string to check
- `!-f` uses the `!` not operator on the filename
- `RewriteRule` redirects all requests back to `/admin/home`

Note that a more syntactically and technically correct approach would be to define the 404 `ErrorDocument`.

    /var/www/html/.htaccessErrorDocument 404 /error.html

**Example 2B: IP Access Restriction**

Although this can also achieved using other methods, a `RewriteCond` can be used to restrict access to one IP or a collection of IP addresses.

This example blocks traffic from everywhere **except** 12.34.56.789.

    /var/www/html/.htaccessRewriteCond %{REMOTE_ADDR} !^(12\.34\.56\.789)$
    RewriteRule (.*) - [F,L]

This example is simply the negation of [Example 3 from the old mod\_rewrite article](how-to-set-up-mod_rewrite-page-2). The entire statement reads “if the address is _not_ 12.34.56.789, do not allow access.”

In short:

- `%{REMOTE_ADDR}` is the address string
- `!^(12\.34\.56\.789)$` escapes all `.` periods with a `\` backslash and negates the IP address using `!`
- The `F` flag forbids access, and the `L` flag indicates that this is the last rule to run, if executed

If you’d rather **block** 12.34.56.789, use this instead:

    /var/www/html/.htaccessRewriteCond %{REMOTE_ADDR} ^(12\.34\.56\.789)$
    RewriteRule (.*) - [F,L]

You can find more rewrite rules, and how to prevent hot linking, in the original article’s [part 1](how-to-set-up-mod_rewrite) and [part 2](how-to-set-up-mod_rewrite-page-2).

## Conclusion

`mod_rewrite` can be used effectively to ensure human-readable URLs. The `.htaccess` file itself has many more uses than simply this module, however, and it should be noted that many other Apache modules may be installed to extend its functionality.

There are other resources that detail the capabilities of `mod_rewrite`:

- [Apache mod\_rewrite Introduction](http://httpd.apache.org/docs/current/rewrite/intro.html)
- [Apache Documentation for mod\_rewrite](http://httpd.apache.org/docs/current/mod/mod_rewrite.html)
- [mod\_rewrite Cheat Sheet](http://www.cheatography.com/davechild/cheat-sheets/mod-rewrite/)

`mod_rewrite` is a critical module for web application security, but can sometimes end up in redirect loops or ubiquitous, ambiguous `500 forbidden` errors. For tips on debugging `.htaccess`, see [this StackOverflow post](http://stackoverflow.com/questions/9153262/tips-for-debugging-htaccess-rewrite-rules).

Rewrite rules are written with regular expressions. To become an expert, reference this [tutorial all about regular expressions](an-introduction-to-regular-expressions).

For quick analysis of your regular expression patterns, here is an [online debugger](https://regex101.com/) that can provide immediate feedback and live interpretations of your regular expression patterns.
