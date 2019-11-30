---
author: Mateusz Papiernik
date: 2016-12-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-temporary-and-permanent-redirects-with-nginx
---

# How To Create Temporary and Permanent Redirects with Nginx

## Introduction

_HTTP redirection_ is way to point one domain or address to another. There are a few different kinds of redirects, each of which mean something different to the client browser. The two most common types are temporary redirects and permanent redirects.

_Temporary redirects_ (response status code **302 Found** ) are useful if a URL temporarily needs to be served from a different location. For example, if you are performing site maintenance, you may wish to use a temporary redirect of from your domain to an explanation page to inform your visitors that you will be back shortly.

_Permanent redirects_ (response status code **301 Moved Permanently** ), on the other hand, inform the browser that it should forget the old address completely and not attempt to access it anymore. These are useful when your content has been permanently moved to a new location, like when you change domain names.

You can create a temporary redirect in Nginx by adding a line like this to the server block entry in the server configuration file:

    rewrite ^/oldlocation$ http://www.newdomain.com/newlocation redirect;

Similarly, use a line like this for a permanent redirect:

    rewrite ^/oldlocation$ http://www.newdomain.com/newlocation permanent;

This guide will cover a more in depth explanation of how to implement each kind of redirect in Nginx, and go through some examples for specific use cases.

## Prerequisites

To follow this tutorial, you will need:

- One server with Nginx installed and set up to serve your website(s) with server blocks. You can do by following How To Set Up Nginx Server Blocks (Virtual Hosts) on [Ubuntu 16.04](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04), [Debian](how-to-setup-nginx-server-blocks-on-debian-7), or [CentOS](how-to-set-up-nginx-virtual-hosts-server-blocks-on-centos-6).

## Solution at a Glance

In Nginx, you can accomplish most redirects with the built-in `rewrite` directive. This directive is available by default on a fresh Nginx installation and can be used to create both temporary and permanent redirects. In its simplest form, it takes at least two arguments: the old URL and the new URL.

You can implement a temporary redirect with the following lines in your server configuration:

Temporary redirect with rewrite

    server {
        . . .
        server_name www.domain1.com;
        rewrite ^/$ http://www.domain2.com redirect;
        . . .
    }

This redirect instructs the browser to direct all requests for `www.domain1.com` to `www.domain2.com`. This solution, however, works only for a single page, not for the entire site. To redirect more than a single page, you can use the `rewrite` directive with [regular expressions](an-introduction-to-regular-expressions) to specify entire directories instead of just single files.

`redirect` matches regular expression patterns in parenthesis. It then references the matched text in the redirect destination using `$1` expression, where `1` is the first group of matched text. In more complex examples, subsequent matched groups are given numbers sequentially.

For example, if you wanted to temporarily redirect every page within `www.domain1.com` to `www.domain2.com`, you could use the following:

Temporary redirect with rewrite

    server {
        . . .
        server_name www.domain1.com;
        rewrite ^/(.*)$ http://www.domain2.com/$1 redirect;
        . . .
    }
    
    server {
        . . .
        server_name www.domain2.com;
        . . .
    }

By default, the `rewrite` directive establishes a temporary redirect. If you would like to create a permanent redirect, you can do so by replacing `redirect` with `permanent` at the end of the directive, like this:

Permanent redirects

    rewrite ^/$ http://www.domain2.com permanent;
    rewrite ^/(.*)$ http://www.domain2.com/$1 permanent;

Let’s move on to some specific examples.

## Example 1 — Moving to a Different Domain

If you have established a web presence and would like to change your domain to a new address, it is best not to just abandon your old domain. Bookmarks to your site and links to your site located on other pages throughout the internet will break if your content disappears without any instructions to the browser about how to find its new location. Changing domains without redirecting will cause your site to lose traffic from previous visitors.

In this example, we will configure a redirect from the old domain called `domain1.com` to the new one called `domain2.com`. We’ll use permanent redirects here because the old domain will be taken down, and all traffic should go to the new domain from now on.

Let’s assume you have your website configured to be served from a single domain called `domain1.com` already configured in Nginx as follows:

/etc/nginx/sites-available/domain1.com

    server {
        . . .
        server_name domain1.com;
        . . .
    }

We’ll also assume you are already serving your future version of website at `domain2.com`:

/etc/nginx/sites-available/domain2.com

    server {
        . . .
        server_name domain2.com;
        . . .
    }

Let’s change the `domain1.com` server block configuration file to add a permanent redirect to `domain2.com`:

/etc/nginx/sites-available/domain1.com

    server {
        . . .
        server_name domain1.com;
        rewrite ^/(.*)$ http://domain2.com/$1 permanent;
        . . .
    }

We’ve added the aforementioned redirect using a `rewrite` directive. The `^/(.*)$` regular expression matches everything after the `/` in the URL. For example, `http://domain1.com/index.html` will get redirected to `http://domain2.com/index.html`. To achieve the permanent redirect we simply add `permanent` after the `rewrite` directive.

**Note:** Remember to restart Nginx after configuration changes using `systemctl restart nginx`.

## Example 2 — Creating a Persistent Experience Despite Single Page Name Changes

Sometimes, it is necessary to change the names of individual pages that have already been published and received traffic on your site. Changing the name alone would cause a 404 Not Found error for visitors trying to access the original URL, but you can avoid this by using a redirect. This makes sure that people who have bookmarked your old pages, or found them through outdated links on search engines, will still reach the correct page.

Let’s imagine your website had two separate pages for products and services called `products.html` and `services.html` respectively. Now, you’ve decided to replace those two pages with a single offer page called `offers.html` instead. We will configure a simple redirect for `products.html` and `services.html` to `offers.html`.

We assume you have your website configured as follows:

Assumed original server block configuration

    server {
        . . .
        server_name example.com www.example.com;
        . . .
    }

Configuring the redirects is as simple as using two `Redirect` directives.

Redirects added to the original configuration

    server {
        . . .
        server_name example.com www.example.com;
    
        rewrite ^/products.html$ /offer.html permanent;
        rewrite ^/services.html$ /offer.html permanent;
        . . .
    }

The `rewrite` directive accepts the original address that has to be redirected as well as the destination address of a new page. Since the change here is not a temporary one, we used `permanent` in the directive as well. You can use as many redirects like that as you wish to make sure your visitors won’t see unnecessary Not Found errors when moving site contents.

## Conclusion

You now have the knowledge to redirect requests to new locations. Be sure to use the correct redirection type, as an improper use of temporary redirects can hurt your search ranking.

There are multiple other uses of HTTP redirects, including forcing secure SSL connections (i.e. using `https` instead of `http`) and making sure all visitors will end up only on the `www.` prefixed address of the website.

Using redirects correctly will allow you to leverage your current web presence while allowing you to modify your site structure as necessary. If you would like to learn more about the ways that you can redirect your visitors, Nginx has great documentation on the subject in [rewrite module](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html) sections of the official documentation and [official blog post on creating redirects](https://www.nginx.com/blog/creating-nginx-rewrite-rules/).
