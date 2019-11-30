---
author: Mateusz Papiernik
date: 2016-12-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-temporary-and-permanent-redirects-with-apache
---

# How To Create Temporary and Permanent Redirects with Apache

## Introduction

_HTTP redirection_ is way to point one domain or address to another. There are a few different kinds of redirects, each of which mean something different to the client browser. The two most common types are temporary redirects and permanent redirects.

_Temporary redirects_ (response status code **302 Found** ) are useful if a URL temporarily needs to be served from a different location. For example, if you are performing site maintenance, you may wish to use a temporary redirect of from your domain to an explanation page to inform your visitors that you will be back shortly.

_Permanent redirects_ (response status code **301 Moved Permanently** ), on the other hand, inform the browser that it should forget the old address completely and not attempt to access it anymore. These are useful when your content has been permanently moved to a new location, like when you change domain names.

You can create a temporary redirect in Apache by adding a line like this to the virtual host entry in the server configuration file:

    Redirect /oldlocation http://www.newdomain.com/newlocation

Similarly, use a line like this for a permanent redirect:

    Redirect permanent /oldlocation http://www.newdomain.com/newlocation

This guide will cover a more in depth explanation of how to implement each kind of redirect in Apache, and go through some examples for specific use cases.

## Prerequisites

To follow this tutorial, you will need:

- One server with Apache 2 installed and set up to serve your website(s) with virtual hosts. You can do by following [How To Set Up Apache Virtual Hosts on Ubuntu 16.04](how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04), [on CentOS 7](how-to-set-up-apache-virtual-hosts-on-centos-7), or [on Debian 7](how-to-set-up-apache-virtual-hosts-on-debian-7).

## Solution at a Glance

In Apache, you can accomplish simple, single-page redirects using the `Redirect` directive, which is included in the `mod_alias` module that is enabled by default on a fresh Apache installation. This directive takes at least two arguments, the old URL and the new URL, and can be used to create both temporary and permanent redirects.

In its simplest form, you can accomplish a temporary redirect with the following lines in your server configuration:

Temporary redirect with Redirect

    <VirtualHost *:80>
        ServerName www.domain1.com
        Redirect / http://www.domain2.com
    </VirtualHost>
    
    <VirtualHost *:80>
        ServerName www.domain2.com
        . . .
    </VirtualHost>

This redirect instructs the browser to direct all requests for `www.domain1.com` to `www.domain2.com`. This solution, however, works only for a single home page, not for the entire site.

To redirect more than a single page, you can use the `RedirectMatch` directive, which uses [regular expressions](an-introduction-to-regular-expressions) to specify entire directories instead of just single files. `RedirectMatch` matches regular expression patterns in parenthesis and then references the matched text in the redirect destination using `$1` expression, where `1` is the first group of matched text. In more complex examples, subsequent matched groups are given numbers sequentially.

For example, if you wanted to temporarily redirect every page within `www.domain1.com` to `www.domain2.com`, you could use the following:

Temporary redirect with RedirectMatch

    <VirtualHost *:80>
        ServerName www.domain1.com
        RedirectMatch ^/(.*)$ http://www.domain2.com/$1
    </VirtualHost>
    
    <VirtualHost *:80>
        ServerName www.domain2.com
        . . .
    </VirtualHost>

By default, both `Redirect` and `RedirectMatch` directives establish a temporary redirect. If you would like to create a permanent redirect, you can do so by appending `permanent` to either of the directives:

Permanent redirects

    Redirect permanent / http://www.domain2.com
    RedirectMatch permanent ^/(.*)$ http://www.domain2.com/$1

You can also create more flexible and powerful redirects with the `mod_rewrite` module. This is outside of the scope of this article, but you can get started with `mod_rewrite` in [How To Set Up mod\_rewrite for Apache](how-to-set-up-mod_rewrite-for-apache-on-ubuntu-14-04).

Let’s move on to some specific examples.

## Example 1 — Moving to a Different Domain

If you have established a web presence and would like to change your domain to a new address, it is best not to just abandon your old domain. Bookmarks to your site and links to your site located on other pages throughout the internet will break if your content disappears without any instructions to the browser about how to find its new location. Changing domains without redirecting will cause your site to lose traffic from previous visitors.

In this example, we will configure a redirect from the old domain called `domain1.com` to the new one called `domain2.com`. We’ll use permanent redirects here because the old domain will be taken down, and all traffic should go to the new domain from now on.

Let’s assume you have your website configured to be served from a single domain called `domain1.com` already configured in Apache as follows:

/etc/apache2/sites-available/domain1.com.conf

    <VirtualHost *:80>
        ServerAdmin admin@domain1.com
        ServerName domain1.com
        ServerAlias www.domain1.com
        DocumentRoot /var/www/domain1.com/public_html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>

We’ll also assume you are already serving your future version of website at `domain2.com`:

/etc/apache2/sites-available/domain2.com.conf

    <VirtualHost *:80>
        ServerAdmin admin@domain2.com
        ServerName domain2.com
        ServerAlias www.domain2.com
        DocumentRoot /var/www/domain2.com/public_html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>

Let’s change the `domain1.com` virtual host configuration file to add a permanent redirect to `domain2.com`:

/etc/apache2/sites-available/domain1.com.conf

    <VirtualHost *:80>
        ServerAdmin admin@domain1.com
        ServerName domain1.com
        ServerAlias www.domain1.com    
        DocumentRoot /var/www/domain1.com/public_html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        RedirectMatch permanent ^/(.*)$ http://domain2.com/$1
    </VirtualHost>

We’ve added the aforementioned redirect using a `RedirectMatch` directive. We use `RedirectMatch` instead of a simple `Redirect` to make sure that all website pages will get affected, not only the home page. The `^/(.*)$` regular expression matches everything after the `/` in the URL. For example, `http://domain1.com/index.html` will get redirected to `http://domain2.com/index.html`. To achieve the permanent redirect we simply add `permanent` after the `RedirectMatch` directive.

**Note:** Remember to restart Apache after configuration changes using `systemctl restart apache2`.

## Example 2 — Creating a Persistent Experience Despite Single Page Name Changes

Sometimes, it is necessary to change the names of individual pages that have already been published and received traffic on your site. Changing the name alone would cause a 404 Not Found error for visitors trying to access the original URL, but you can avoid this by using a redirect. This makes sure that people who have bookmarked your old pages, or found them through outdated links on search engines, will still reach the correct page.

Let’s imagine your website had two separate pages for products and services called `products.html` and `services.html` respectively. Now, you’ve decided to replace those two pages with a single offer page called `offers.html` instead. We will configure a simple redirect for `products.html` and `services.html` to `offers.html`.

We assume you have your website configured as follows:

Assumed original virtual host configuration

    <VirtualHost *:80>
        ServerName example.com
        . . .
    </VirtualHost>

Configuring the redirects is as simple as using two `Redirect` directives.

Redirects added to the original configuration

    <VirtualHost *:80>
        ServerName example.com
    
        Redirect permanent /products.html /offer.html
        Redirect permanent /services.html /offer.html
        . . .
    </VirtualHost>

The `Redirect` directive accepts the original address that has to be redirected as well as the destination address of a new page. Since the change here is not a temporary one, we used `permanent` in the directive as well. You can use as many redirects like that as you wish to make sure your visitors won’t see unnecessary Not Found errors when moving site contents.

## Conclusion

You now have the knowledge to redirect requests to new locations. Be sure to use the correct redirection type, as an improper use of temporary redirects can hurt your search ranking.

There are multiple other uses of HTTP redirects, including forcing secure SSL connections (i.e. using `https` instead of `http`) and making sure all visitors will end up only on the `www.` prefixed address of the website.

Using redirects correctly will allow you to leverage your current web presence while allowing you to modify your site structure as necessary. If you would like to learn more about the ways that you can redirect your visitors, Apache has great documentation on the subject in [mod\_alias](https://httpd.apache.org/docs/current/mod/mod_alias.html) and [mod\_rewrite](http://httpd.apache.org/docs/current/mod/mod_rewrite.html) sections of the official documentation.
