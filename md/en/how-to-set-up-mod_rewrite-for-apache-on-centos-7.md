---
author: Michael Lenardson
date: 2016-10-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_rewrite-for-apache-on-centos-7
---

# How To Set Up mod_rewrite for Apache on CentOS 7

## Introduction

Apache is a modular web server that allows you to customize its capabilities by enabling and disabling modules. This provides administrators the ability to tailor the functionality of Apache to meet the needs of their web application.

In this tutorial, we will install Apache on a CentOS 7 server, confirm that the `mod_rewrite` module is enabled, and explore some essential functions.

## Prerequisite

Before following this tutorial, make sure you have a regular, non-root user with sudo privileges. You can learn more about how to set up a user with these privileges from our guide, [How To Create a Sudo User on CentOS](how-to-create-a-sudo-user-on-centos-quickstart).

## Step 1 – Installing Apache

We will install Apache using `yum`, the default package management utility for CentOS.

    sudo yum install httpd

When prompted with `Is this ok [y/d/N]:` message, type `Y` and press the `ENTER` key to authorize the installation.

Next, start the Apache daemon, a standalone process that creates a pool of child processes or threads to handle requests, with the `systemctl` utility:

    sudo systemctl start httpd

To make sure Apache successfully started, check its state with the `status` command:

    sudo systemctl status httpd

    Output. . .
    systemd[1]: Starting The Apache HTTP Server...
    systemd[1]: Started The Apache HTTP Server.

With Apache up and running, let’s turn our attention to its modules.

## Step 2 – Verifying mod\_rewrite

As of CentOS version 7, the `mod_rewrite` Apache module is enabled by default. We will verify this is the case with the `httpd` command and `-M` flag, which prints a list of all loaded modules:

    httpd -M

    Output . . .
     remoteip_module (shared)
     reqtimeout_module (shared)
     rewrite_module (shared)
     setenvif_module (shared)
     slotmem_plain_module (shared)
     . . .

If the `rewrite_module` does not appear in the output, enable it by editing the `00-base.conf` file with the `vi` editor:

    sudo vi /etc/httpd/conf.modules.d/00-base.conf

Once the text file opens type `i` to enter insert mode and then add or uncomment the highlighted line below:

/etc/httpd/conf.modules.d/00-base.conf

    #
    # This file loads most of the modules included with the Apache HTTP
    # Server itself.
    #
    . . .
    LoadModule rewrite_module modules/mod_rewrite.so
    . . .

Now press `ESC` to leave insert mode. Then, type `:x` then press the `ENTER` key to save and exit the file.

Next, apply the configuration change by restarting Apache:

    sudo systemctl restart httpd

With Apache installed and the `mod_rewrite` module enabled, we’re ready to configure the use of a `.htaccess` file.

## Step 3 – Setting up a .htaccess File

A `.htaccess` file allows the defining of directives for Apache, including a `RewriteRule`, on a per domain basis without altering server configuration files. In Linux, files preceded with a dot (`.`) are treated as hidden.

Before using a `.htaccess` file, we need to update the `AllowOverride` setting to be able to overwrite Apache directives.

    sudo vi /etc/httpd/conf/httpd.conf

Locate the `<Directory /var/www/html>` section and change the `AllowOverride` directive from `None` to `All`:

/etc/httpd/conf/httpd.conf

    . . .
    <Directory /var/www/html>
    . . .
     # 
     # AllowOverride controls what directives may be placed in .htaccess files.
     # It can be "All", "None", or any combination of the keywords:
     # Options FileInfo AuthConfig Limit
     #
     AllowOverride All
    . . .
    </Directory>
    . . .

Save and exit the file and then restart Apache to apply the change:

    sudo systemctl restart httpd

Next, create a `.htaccess` file in the default document root, `/var/www/html`, for Apache.

    sudo vi /var/www/html/.htaccess

Add the following line to the top of the file to activate the `RewriteEngine`, which instructs Apache to process any rules that follow:

/var/www/html/.htaccess

    RewriteEngine On

Save and exit the file.

You now have a `.htaccess` file that will let you define rules to manipulate URLs as needed. Before we get into writing actual rules, let’s take a moment to review the basic `mod_rewrite` syntax.

## Step 4 – Exploring the RewriteRule Syntax

The `RewriteRule` directive allows us to remap request to Apache based off of the URL. A `.htaccess` file can house more than one rewrite rule, but at run-time Apache applies the rules in their defined order. A rewrite rule consists of the following structure:

`RewriteRule Pattern Substitution [Flags]`

- RewriteRule: specifies the `RewriteRule` directive
- _Pattern_: a PCRE (Perl Compatible Regular Expression) that matches the desired string. You can learn more about regular expressions [here](an-introduction-to-regular-expressions).
- _Substitution_: where should the matching requests be sent
- [_Flags_]: optional parameters to modify the rule. For more information on the available flags and their meanings, see Apache’s documentation on [Rewrite Flags](http://httpd.apache.org/docs/current/rewrite/flags.html).

The `RewriteRule` is the workhorse of the `mod_rewrite` directives, which is why we predominately focus on it in this tutorial.

## Step 5 – Exploring the RewriteCond Syntax

The `RewriteCond` directive allows us to add conditions to a rewrite rule. A rewrite condition consists of the following structure:

`RewriteCond TestString Condition [Flags]`

- RewriteCond: specifies the `RewriteCond` directive
- _TestString_: a string to test against
- _Condition_: a pattern to match
- [_Flags_]: optional parameter to modify the condition.

The `RewriteCond` directive does not allow Apache to consider any rewrite rules that follow it unless the particular condition evaluates to true.

## Step 6 – Setting up Files

We will set up a basic rewrite rule to allow users to visit an `about.html` page without typing the file extension (`.html`) in the address bar of a web browser. Start by creating an `about.html` file in the document root directory:

    sudo vi /var/www/html/about.html

Copy the following HTML code into the file:

/var/www/html/about.html

    <!DOCTYPE html>
    <html>
        <head>
            <title>About Us</title>
        </head>
        <body>
            <h1>About Us</h1>
        </body>
    </html>

Save and exit the file.

In a web browser, navigate to the following address:

    http://server_domain_or_IP/about.html

You should see a white page with **About Us** on it. If you remove the **.html** from the address bar and reload the page, you’ll receive a 404 **Not Found** error. Apache can only access components by their full filename, but we can alter that with a rewrite rule.

## Step 7 – Setting up a RewriteRule

We would like visitors to the **About Us** page to access it without having to type `.html`. To accomplish this, we’ll create a rule.

Open the `.htaccess` file:

    sudo vi /var/www/html/.htaccess

After the `RewriteEngine On` line, add the following:

/var/www/html/.htaccess

    RewriteRule ^about$ about.html [NC]

Save and exit the file.

Visitors can now access the **About Us** page with the `http://server_domain_or_IP/about` URL.

Let’s examine the rewrite rule:

`^about$` serves as the pattern that gets matched from the URL, and what the user types into their browser.  
Our example uses a couple _metacharacters_ to ensure that the term only exists in a particular location in the URL:

- `^` indicates the start of the URL, after `server_domain_or_IP/` is stripped away.
- `&` means the end of the URL

`about.html` shows the path to the file that Apache serves when it encounters a matching pattern.

`[NC]` is a flag that instructs the rewrite rule to be case-insensitive so that a user can enter lower and upper case letters in the URL. For example, the following URLs point to the `about.html` file:

- server_domain_or\_IP/about
- server_domain_or\_IP/About
- server_domain_or\_IP/ABOUT

With a simple rewrite rule, we’ve added a dynamic aspect to how users can access the **About Us** page.

## Common Patterns

Now that we have a basic understanding of rewrite rules, we will explore two additional examples in this section.

Example files can be set up, but this tutorial does not include creating them; just the rewrite rules themselves.

### Example 1: Simplifying Query Strings with a RewriteRule

Web applications often make use of query strings, which are appended to a URL using the question mark character (`?`) and delimited by the ampersand character (`&`). Apache ignores these two characters when matching rewrite rules. However, sometimes query strings may be required for passing data between pages. For example, the URL for a search result page written in PHP may look like this:

    http://example.com/results.php?item=shoes&type=women

Instead, we would like our visitors to be able to use the following cleaner URL:

    http://example.com/shoes/women

We can achieve these results in one of two ways — through a simple replacement or matching options.

**Example 1A: Simple Replacement**

We’ll create a rewrite rule that performs a simple replacement, simplifying a long query URL:

/var/www/html/.htaccess

    RewriteRule ^shoes/women$ results.php?item=shoes&type=women

The rule maps `shoes/women` to `results.php?item=shoes&type=women`.

**Example 1B: Matching Options**

In some cases, we might want to generalize the query string to include different types of shoes. We can accomplish this by doing the following:

- Specify a series of options using the vertical pipe `|`, the Boolean “OR” operator
- Group the match using `()`, then reference the group using the `$1` variable, with `1` for the first matched group

The rewrite rule now becomes:

/var/www/html/.htaccess

    RewriteRule ^shoes/(men|women|youth) results.php?item=shoes&type=$1

The rule shown above matches a URL of `shoes/` followed by a specified type. This will modify the original URL so that:

    http://example.com/shoes/men

becomes:

    http://example.com/results.php?item=shoes&type=men

This matching option allows Apache to evaluate several patterns without having to create a separate rewrite rule for each one.

**Example 1C: Matching Character Sets**

However, we would also like to specify any item, not limit it to just `/shoes`. So, we will do the following:

- Write a _regular expression_ that matches all alphanumeric characters. The bracket expression `[]` matches any character inside of it, and the `+` matches any number of characters specified in the brackets
- Group the match, and reference it with `$2` as the second variable in the file

/var/www/html/.htaccess

    RewriteRule ^([A-Za-z0-9]+)/(men|women|youth) results.php?item=$1&type=$2

The above example will convert:

    http://example.com/pants/men

to:

    http://example.com/results.php?item=pants&type=men

We successfully expanded the matching ability to include multiple aspects of a URL.

**Example 1D: Passing Query Strings**

This section doesn’t introduce any new concepts but addresses an issue that may come up. Using the above example, say we would like to redirect `http://example.com/pants/men` but will pass an additional query string `?page=2`. We would like to map the following URL:

    http://example.com/pants/men?page=2

to:

    http://example.com/results.php?item=pants&type=men&page=2

If you were to attempt to access the above URL with our current settings, you would find that the query string `page=2` gets lost. This is easily fixed using an additional `QSA` flag, which causes the query strings to be combined. Modifying the rewrite rule to match the following will achieve the desired behavior.

/var/www/html.html

    RewriteRule ^([A-Za-z0-9]+)/(men|women|youth) results.php?item=$1&type=$2 [QSA]

### Example 2: Adding Conditions with Logic

Now we’re going to look at the use of the `RewriteCond` directive. If a rewrite condition evaluates to true, then Apache considers the `RewriteRule` that follows it.

**Example 2A: Default Page**

Previously, we saw Apache handle a request for an invalid URL by delivering a 404 **Not Found** page. However, instead of an error page, we would like all malformed URLs redirected back to the homepage. Using a condition, we can check if the requested file exists.

/var/www/html/.htacces

    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^admin/(.*)$ /admin/home

This will redirect something like `/admin/random_text` to `/admin/home`.

Let’s dissect the above rule:

- `%{REQUEST_FILENAME}` checks the requested string
- `!-f` the `!` or **not** operator states that if the requested filename does not exist, then execute the following rewrite rule.
- `RewriteRule` redirects the requests back to `/admin/home`

Defining the 404 `ErrorDocument` would follow best practices. To do that, we’ll create an `ErrorDocument` rule to point 404 errors to an `error.html` page:

/var/www/html/.htaccess

    ErrorDocument 404 /error.html

This redirects any request that results in an HTTP 404 response to the `error.html` page.

**Example 2B: IP Address Restriction**

A `RewriteCond` can be used to allow access to a site by a specific IP address.

This example blocks traffic from everywhere **except** 198.51.100.24.

/var/www/html/.htaccess

    RewriteCond %{REMOTE_ADDR} !^(198\.51\.100\.24)$
    RewriteRule (.*) - [F,L]

The entire rule states that if the IP address requesting resources is not 198.51.100.24, then do not allow access.

In short:

- `%{REMOTE_ADDR}` is the address string
- `!^(198\.51\.100\.24)$` negates the IP address. The `\` backslashes escape the `.` dot, because otherwise, they serve as metacharacters used to match any character.
- The `F` flag forbids access, and the `L` flag indicates that this is the last rule to run, if executed.

If you’d rather **block** access from the specific address, use the following instead:

/var/www/html/.htaccess

    RewriteCond %{REMOTE_ADDR} ^(198\.51\.100\.24)$
    RewriteRule (.*) - [F,L]

Though you can use other methods to block or allow traffic to your site, setting up the restriction in a `.htaccess` file is the easiest way to achieve these results.

## Conclusion

In this tutorial, we used a `.htaccess` file to work with the `RewriteRule` and `RewriteCond` directives. There are many reasons to use rewrite rules and the following resources detail the capabilities of the `mod_rewrite` module:

- [Apache mod\_rewrite Introduction](http://httpd.apache.org/docs/current/rewrite/intro.html)
- [Apache Documentation for mod\_rewrite](http://httpd.apache.org/docs/current/mod/mod_rewrite.html)
- [mod\_rewrite Cheat Sheet](http://www.cheatography.com/davechild/cheat-sheets/mod-rewrite/)

The `mod_rewrite` module is a crucial component of the Apache web server, and you can do a lot with it. However, things do not always go according to plan and when that happens you might find yourself with a redirect loop or an ambiguous `500 forbidden` error. For tips on debugging these kinds of situations, review [this StackOverflow post](http://stackoverflow.com/questions/9153262/tips-for-debugging-htaccess-rewrite-rules).
