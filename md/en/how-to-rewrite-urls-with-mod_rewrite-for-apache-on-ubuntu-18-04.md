---
author: Mateusz Papiernik, Brian Hogan
date: 2018-07-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-18-04
---

# How to Rewrite URLs with mod_rewrite for Apache on Ubuntu 18.04

## Introduction

Apache’s `mod_rewrite` module lets you rewrite URLs in a cleaner fashion, translating human-readable paths into code-friendly query strings. It also lets you rewrite URLs based on conditions.

An `.htaccess` file lets you create and apply rewrite rules without accessing server configuration files. By placing the `.htaccess` file in the root of your web site, you can manage rewrites on a per-site or per-directory basis.

In this tutorial, you’ll enable `mod_rewrite` and use `.htaccess` files to create a basic URL redirection, and then explore a couple of advanced use cases.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 18.04 server set up by following the [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall.

- Apache installed by following Step 1 of [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04).

## Step 1 — Enabling mod\_rewrite

In order for Apache to understand rewrite rules, we first need to activate `mod_rewrite`. It’s already installed, but it’s disabled on a default Apache installation. Use the `a2enmod` command to enable the module:

    sudo a2enmod rewrite

This will activate the module or alert you that the module is already enabled. To put these changes into effect, restart Apache.

    sudo systemctl restart apache2

`mod_rewrite` is now fully enabled. In the next step we will set up an `.htaccess` file that we’ll use to define rewrite rules for redirects.

## Step 2 — Setting Up .htaccess

An `.htaccess` file allows us to modify our rewrite rules without accessing server configuration files. For this reason, `.htaccess` is critical to your web application’s security. The period that precedes the filename ensures that the file is hidden.

**Note:** Any rules that you can put in an `.htaccess` file can be also put directly into server configuration files. In fact, the [official Apache documentation](http://httpd.apache.org/docs/2.4/howto/htaccess.html) recommends using server configuration files instead of `.htaccess` because Apache processes it faster that way.

However, in this simple example, the performance increase will be negligible. Additionally, setting rules in `.htaccess` is convenient, especially with multiple websites on the same server. It does not require a server restart for changes to take effect and it does not require root privileges to edit those rules, simplifying maintenance and and making changes possible with unprivileged account. Some popular open-source software, like Wordpress and Joomla, often relies on an `.htaccess` file for the software to modify and create additional rules on demand.

Before you start using `.htaccess` files, you’ll need to set up and secure a few more settings.

By default, Apache prohibits using an `.htaccess` file to apply rewrite rules, so first you need to allow changes to the file. Open the default Apache configuration file using `nano` or your favorite text editor.

    sudo nano /etc/apache2/sites-available/000-default.conf

Inside that file, you will find a `<VirtualHost *:80>` block starting on the first line. Inside of that block, add the following new block so your configuration file looks like the following. Make sure that all blocks are properly indented.

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
        <Directory /var/www/html>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Require all granted
        </Directory>
    
        . . .
    </VirtualHost>

Save and close the file. To put these changes into effect, restart Apache.

    sudo systemctl restart apache2

Now, create an `.htaccess` file in the web root.

    sudo nano /var/www/html/.htaccess

Add this line at the top of the new file to activate the rewrite engine.

/var/www/html/.htaccess

    RewriteEngine on

Save the file and exit.

You now have an operational `.htaccess` file which you can use to govern your web application’s routing rules. In the next step, we will create sample website files that we’ll use to demonstrate rewrite rules.

## Step 3 — Configuring URL Rewrites

Here, we will set up a basic URL rewrite which converts pretty URLs into actual paths to pages. Specifically, we will allow users to access `http://your_server_ip/about`, but display a page called `about.html`.

Begin by creating a file named `about.html` in the web root.

    sudo nano /var/www/html/about.html

Copy the following HTML code into the file, then save and close it.

/var/www/html/about.html

    <html>
        <head>
            <title>About Us</title>
        </head>
        <body>
            <h1>About Us</h1>
        </body>
    </html>

You can access this page at `http://your_server_ip/about.html`, but notice that if you try to access `http://your_server_ip/about`, you will see a **404 Not Found** error. To access the page using `/about` instead, we’ll create a rewrite rule.

All `RewriteRules` follow this format:

General RewriteRule structure

    RewriteRule pattern substitution [flags]

- `RewriteRule` specifies the directive.
- `pattern` is a [regular expression](an-introduction-to-regular-expressions) that matches the desired string from the URL, which is what the viewer types in the browser.
- `substitution` is the path to the actual URL, i.e. the path of the file Apache servers.
- `flags` are optional parameters that can modify how the rule works.

Let’s create our URL rewrite rule. Open up the `.htaccess` file.

    sudo nano /var/www/html/.htaccess

After the first line, add the `RewriteRule` marked in red and save the file.

/var/www/html/.htaccess

    RewriteEngine on
    RewriteRule ^about$ about.html [NC]

In this case, `^about$` is the pattern, `about.html` is the substitution, and `[NC]` is a flag. Our example uses a few characters with special meaning:

- `^` indicates the start of the URL, after `your_server_ip/`.
- `$` indicates the end of the URL.
- `about` matches the string “about”.
- `about.html` is the actual file that the user accesses.
- `[NC]` is a flag that makes the rule case insensitive.

You can now access `http://your_server_ip/about` in your browser. In fact, with the rule shown above, the following URLs will point to `about.html`:

- `http://your_server_ip/about`, because of the rule definition.
- `http://your_server_ip/About`, because the rule is case insensitive.
- `http://your_server_ip/about.html`, because the original proper filename will always work.

However, the following will not work:

- `http://your_server_ip/about/`, because the rule explicitly states that there may be nothing after `about`, since the `$` character appears after `about`.
- `http://your_server_ip/contact`, because it won’t match the `about` string in the rule.

You now have an operational `.htaccess` file with a basic rule that you can modify and extend to your needs. In the following sections, we will show two additional examples of commonly used directives.

## Example 1 — Simplifying Query Strings with RewriteRule

Web applications often make use of _query strings_, which are appended to a URL using a question mark (`?`) after the address. Separate parameters are delimited using an ampersand (`&`). Query strings may be used for passing additional data between individual application pages.

For example, a search result page written in PHP may use a URL like `http://example.com/results.php?item=shirt&season=summer`. In this example, two additional parameters are passed to the imaginary `result.php` application script: `item`, with the value `shirt`, and `season` with the value `summer`. The application may use the query string information to build the right page for the visitor.

Apache rewrite rules are often employed to simplify such long and unpleasent links as the above into _friendly URLs_ that are easier to type and interpret visually. In this example, we would like to simplify the above link to become `http://example.com/shirt/summer`. The `shirt` and `summer` parameter values are still in the address, but without the query string and script name.

Here’s one rule to implement this:

Simple substition

    RewriteRule ^shirt/summer$ results.php?item=shirt&season=summer [QSA]

The `shirt/summer` is explicitly matched in the requested address and Apache is told to serve `results.php?item=shirt&season=summer` instead.

The `[QSA]` flags are commonly used in rewrite rules. They tell Apache to append any additional query string to the served URL, so if the visitor types `http://example.com/shirt/summer?page=2` the server will respond with `results.php?item=shirt&season=summer&page=2`. Without it, the additional query string would get discarded.

While this method achieves the desired effect, both the item name and season are hardcoded into the rule. This means the rule will not work for any other items, like `pants`, or seasons, like `winter`.

To make the rule more generic, we can use [regular expressions](an-introduction-to-regular-expressions) to match parts of the original address and use those parts in a substitution pattern. The modified rule will then look as follows:

Simple substition

    RewriteRule ^([A-Za-z0-9]+)/(summer|winter|fall|spring) results.php?item=$1&season=$2 [QSA]

The first regular expression group in parenthesis matches a string containing alphanumeric characters and numbers like `shirt` or `pants` and saves the matched fragment as the `$1` variable. The second regular rexpression group in parenthesis matches exactly `summer`, `winter`, `fall`, or `spring`, and similarly saves the matched fragment as `$2`.

The matched fragments are then used in the resulting URL in `item` and `season` variables instead of hardcoded `shirt` and `summer` values we used before.

The above will convert, for example, `http://example.com/pants/summer` into `http://example.com/results.php?item=pants&season=summer`. This example is also future proof, allowing mutliple items and seasons to be correctly rewritten using a single rule.

## Example 2 — Adding Conditions with Logic Using RewriteConds

Rewrite rules are not necessarily always evaluated one by one without any limitations. The `RewriteCond` directive lets us add conditions to our rewrite rules to control when the rules will be processed. All `RewriteConds` abide by the following format:

General RewriteCond structure

    RewriteCond TestString Condition [Flags]

- `RewriteCond` specifies the `RewriteCond` directive.
- `TestString` is the string to test against.
- `Condition` is the pattern or condition to match.
- `Flags` are optional parameters that may modify the condition and evaluation rules.

If a `RewriteCond` evaluates to true, the `RewriteRule` immediately following will be considered. If it won’t, the rule will be discarded. Multiple `RewriteCond` may be used one after another and, with default behaviour, all must evaluate to true for the following rule to be considered.

As an example, let’s assume you would like to redirect all requests to non-existent files or directories on your site back to the home page instead of showing the standard **404 Not Found** error page. This can be achieved with following conditions rules:

Redirect all requests to non-existent files and directories to home page

    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /

With the above:

- `%{REQUEST_FILENAME}` is the string to check. In this case, it’s the requested filename, which is a system variable available for every request.
- `-f` is a built-in condition which verifies if the requested name exists on disk and is a file. The `!` is a negation operator. Combined, `!-f` evaluates to true only if a specified name does not exist or is not a file.
- Similarly, `!-d` evaluates to true only if a specified name does not exist or is not a directory.

The `RewriteRule` on the final line will come into effect only for requests to non-existent files or directories. The `RewriteRule` itself is very simple and redirects every request to the `/` website root.

# Conclusion

`mod_rewrite` lets you create human-readable URLs. In this tutorial, you learned how to use the `RewriteRule` directive to redirect URLs, including ones with query strings. You also learned how to conditionally redirect URLs using the `RewriteCond` directive.

If you’d like to learn more about `mod_rewrite`, take a look at [Apache’s mod\_rewrite Introduction](http://httpd.apache.org/docs/current/rewrite/intro.html) and [Apache’s official documentation for mod\_rewrite](http://httpd.apache.org/docs/current/mod/mod_rewrite.html).
