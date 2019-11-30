---
author: Justin Ellingwood
date: 2013-08-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-the-nginx-web-server-on-a-virtual-private-server
---

# How To Configure The Nginx Web Server On a Virtual Private Server

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
 This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

### What is Nginx?

Nginx is a web server and reverse proxy server. It has experienced wide-spread adoption and is displacing many other common options.

While Nginx is a powerful tool, its configuration can be intimidating for those coming from other servers, or who are new to web servers in general. In this guide, we will explore the main Nginx configuration files and demystify some of the syntax and options.

We will be using an Ubuntu 12.04 install, but most distributions will be configured with similar file locations.

## Nginx Configuration Directory Hierarchy

Nginx stores its configuration files within the "/etc/nginx" directory.

Inside of this directory, you will find a few directories and various modular configuration files:

    cd /etc/nginx ls -F

    conf.d/ koi-win naxsi.rules scgi\_params uwsgi\_params fastcgi\_params mime.types nginx.conf sites-available/ win-utf koi-utf naxsi\_core.rules proxy\_params sites-enabled/

If you are coming from Apache, the "sites-available" and "sites-enabled" directories will be familiar.

These directories are used to define configurations for your websites. Files are generally created in the "sites-available" directory, and then symbolically linked to the "sites-enabled" directory when they are ready to go live.

The "conf.d" directory can be used for site configuration as well. Every file within this directory ending with ".conf" is read into the configuration when Nginx is started, so make sure every file defines valid Nginx configuration syntax.

Most of the other files within the "/etc/nginx" directory contain configuration details of specific processes or optional components.

However, the "nginx.conf" file is the main configuration file. We will explore this file in more depth.

## Exploring the nginx.conf File

The nginx.conf file is Nginx's main control point. This file reads in all of the other appropriate configuration files and combines them into a monolithic configuration file when the server starts.

Open the file so that we can discuss the general format:

    sudo nano /etc/nginx/nginx.conf

    user www-data; worker\_processes 4; pid /var/run/nginx.pid; events { worker\_connections 768; # multi\_accept on; } http { . . .

The first few lines are used to define some general facts about how Nginx will operate.

For instance, the server decides what user to run as by the "user www-data" line. This is the typical web server user for Ubuntu.

The "pid" directive specifies where the process pid will be stored for internal reference. The "worker\_processes" defines how many concurrent processes that Nginx will use.

This portion of the configuration file can also include things like error log locations using the "error\_log" directive.

The next section in our file is the events section. This is a special location that controls how Nginx will handle connections. We do not need to adjust anything in this section in our example, so we will move on.

The following section is the http block. This leads into a more complex discussion about how the Nginx configuration file is formatted.

## Nginx Configuration File Layout

The Nginx configuration file is managed in "blocks".

The first block that we saw was the events block. The next one is the http block, and the start of the main hierarchy within the configuration file.

The configuration details within the http block are layered, with enclosed blocks inheriting properties from the block that they are located in. Most of Nginx's general configuration takes place in the http block, which houses server blocks, which, in turn, contain location blocks.

The important part is that you should always put configuration details into the highest container to which they apply. This means that if you want parameter X to apply to every server block, then placing it within the http block will cause it to propagate to every server configuration.

If you look at our file, you will notice that it has many options that dictate how the software should function as a whole. This is the appropriate place for these kinds of directives.

For instance, we have file compression options set up with these lines:

    gzip on; gzip\_disable "msie6";

This tells Nginx to enable gzip to compress data that is sent to clients, but to disable gzip compression when the client is Internet Explorer version 6, because that browser does not understand gzip compression.

If you have options that should have different values for some server blocks, you can specify them at a higher level and then override them within the server block. Nginx will take the lowest-level specification that applies to a setting.

This style of applying settings at the highest possible level saves you from having to manage multiple, identical declarations. It also has the advantage of providing defaults that can be used in case you forget to declare something on the "server" block level or below.

In the "nginx.conf" file, we can see that the end of the "http" block has:

    include /etc/nginx/conf.d/\*.conf; include /etc/nginx/sites-enabled/\*;

This tells us that the server and location blocks that define specific sites and url match locations will take place outside of this file.

This allows us to maintain a modular configuration arrangement where we can create new files when we would like to serve new sites. It allows us to group related content together, while hiding the details that do not change in most situations.

Exit out of the "nginx.conf" file so that we can examine an individual site configuration in the next section.

## Exploring the Default Server Block

Nginx uses server blocks to accomplish the functionality found in Apache's virtual hosts. Think of server blocks as specifications for individual web sites that your server can host.

We will look at the included default server block configuration located in the "sites-available" directory. This file contains all of the necessary information needed to serve the default webpage.

    cd sites-available sudo nano default

    server { root /usr/share/nginx/www; index index.html index.htm; server\_name localhost; location / { try\_files $uri $uri/ /index.html; } location /doc/ { alias /usr/share/doc/; autoindex on; allow 127.0.0.1; deny all; } }

The default file is very well-commented, but I've removed the comments here to save space and demonstrate how simple the definition of a site can be.

We have a server block that includes everything between the opening and associated closing brackets:

    server { . . . }

This block is placed into the "nginx.conf" file near the end of the http block, by using the "include" directive, as we discussed in the last section.

The "root" directive defines the directory where the website's contents are located. This is the location where Nginx will start looking for files that are requested by the browser. The default website searches for its content in "/usr/share/nginx/www".

Notice how each line ends with a semi-colon (;). This is how Nginx knows that one directive is finished and the next one will begin. Do not forget the semi-colon, or Nginx will treat the lines that follow as additional arguments to the directive. It will do this until it reaches a semi-colon.

The next line involves the "index" directive.

This configures the default pages served for the domain. If no page was requested, the server block will search for a file called "index.html" and return it. If it cannot find that file, it will try to serve a file called "index.htm".

### Using the server\_name Directive

The "server\_name" directive contains a list of domain names that will be served from this server block. You can include as many names as you would like, separated by spaces.

You can also use the asterisk character at the beginning or end of the server name as a wild-card that matches everything. For instance, "\*.example.com" would match requests for "forum.example.com" and "animals.example.com".

If a requested url matches more than one "server\_name" directive, it will choose the one that matches exactly first. If none match exactly, it will choose the longest wildcard name that begins with an asterisk.

If it still has not found a match, it will look for the longest matching wildcard name that ends with an asterisk. If none of these are found, it will return the first matching regular expression match.

Server names that use regular expressions to match start with the tilde (~) character. Regular expressions are very powerful, but outside of the scope of this article.

### Using Location Blocks

The next part of the configuration file opens a location block. Location blocks are used to specify how certain resource requests are handled within a server.

The line "location /" specifies that the directives within the brackets will apply to all resources requested by the client that do not match other location blocks.

Location blocks can contain a uri path like the "/doc/" path specified further down the file, can have an equal sign (=) between location and the uri to specify an exact match, or use tilde (~) characters to indicate regular expression matches.

A plain tilde indicates case-sensitive matching, a tilde followed by an asterisk (~\*) means case insensitive matching, and a tilde preceded by a carat (^~) tells Nginx to not perform regular expression searches if the uri matches this location.

Location matching is similar to server\_name matching in that Nginx has a well-defined process to decide which block to use.

If the query matches a location with the equal sign, that location is used and searching stops. If not, then the regular literal uri locations are searched. If a carat tilde (^~) was used and a uri location matches, this block will be selected.

If that option is not used, it will select the most specific match and hold the value. It will then perform regular expression matching to see if it can match any of those patterns. If one is found, the regular expression block is used. If not, the uri location matched previously is used.

In summary, Nginx prefers exact matches, followed by regular expression matches, and then literal URI matches, but literal URI matches can be explicitly made more important by preceding them with "^~".

This list defines these preferences:

1. Equal sign matches
2. Literal URI matches with "^~"
3. Most specific regular expression match
4. Most specific literal URI match

Although this might seem confusing, these defined rules are necessary so that Nginx can make a decision without ambiguity.

### How to Use try\_files

The try\_files directive is a very useful tool for defining a chain of attempts that should be made for resource requests.

What this means is that you can declare how you would like Nginx to attempt to serve a request through a series of alternative options.

The example in the default configuration file is:

    try\_files $uri $uri/ /index.html;

This means that when a request is made that is being served by that location block, Nginx will first try to serve the literal uri as a file. This is declared using the "$uri" variable, which will hold the resource being requested.

If there is no file that matches the value of $uri, then it will try to use the uri as a directory. It will attempt to serve the default file (ours is index.html, if you recall) for the uri directory.

If there is no directory that matches the value of $uri, then it uses a default file, which is the "index.html" file in the server block root directory. Each "try\_files" directive uses the last parameter as the fall-back default, so it must be a known, real file.

The other option if you do not wish to return a file if the preceding parameters do not match is to return an error page. This is accomlished using an equal sign and an error code.

For instance, if we wanted our "location /" block to return a 404 error if a resource could not be located instead of serving the default "index.html" page, we could replace the last file with "=404":

    try\_files $uri $uri/ =404;

This will throw the appropriate error page to the user if they request a resource that does not exist.

### Additional Options

The rest of the configuration file contains some other interesting directives.

The "alias" directive tells Nginx that the the pages for that location block should be served out of the specified directory. These can outside of the root directory.

In our example, resources requested within "/doc/" will be served out of "/usr/share/doc/".

The "autoindex on" directive allows Nginx to generate a directory listing for the specified location. This will be returned when the directory is requested.

The "allow" and "deny" lines set up access control for the directory. The lines in our file allow the contents to be read when the user is attempting to access the location from the local server.

## Conclusion

Nginx uses different terminology for some of its capabilities, but it is an extremely capable server with many configuration options.

Learning how to properly configure an Nginx web server will allow you to take full advantage of a piece of software that is simultaneously very powerful and very low on resources. This makes it an ideal choice for websites of any size.

By Justin Ellingwood
