---
author: Hazel Virdó
date: 2016-12-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-the-gzip-module-to-nginx-on-ubuntu-16-04
---

# How To Add the gzip Module to Nginx on Ubuntu 16.04

## Introduction

How fast a website will load depends on the size of all of the files that have to be downloaded by the browser. Reducing the size of files to be transmitted can make the website not only load faster, but also cheaper to those who have to pay for their bandwidth usage.

[`gzip`](http://www.gzip.org/) is a popular data compression program. You can configure Nginx to use `gzip` to compress files it serves on the fly. Those files are then decompressed by the browsers that support it upon retrieval with no loss whatsoever, but with the benefit of smaller amount of data being transferred between the web server and browser.

Because of the way compression works in general, but also how `gzip` works, certain files compress better than others. For example, text files compress very well, often ending up over two times smaller in result. On the other hand, images such as JPEG or PNG files are already compressed by their nature and second compression using `gzip` yields little or no results. Compressing files use up server resources, so it is best to compress only those files that will reduce its size considerably in result.

In this guide, we’ll discuss how to configure Nginx installed on your Ubuntu 16.04 server to utilize `gzip` compression to reduce the size of content sent to website visitors.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following the [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall
- Nginx installed on your server by following the [How To Install Nginx on Ubuntu 16.04 tutorial](how-to-install-nginx-on-ubuntu-16-04)

## Step 1 — Creating Test Files

In this step, we will create several test files in the default Nginx directory to text `gzip`’s compression.

To make a decision what kind of file is served over the network, Nginx does not analyze the file contents because it wouldn’t be fast enough. Instead, it just looks up the file extension to determine its _MIME type_, which denotes the purpose of the file.

Because of this behavior, the contents of the test files is irrelevant. By naming the files appropriately, we can trick Nginx into thinking that one entirely empty file is an image and the another, for example, is a stylesheet.

In our configuration, Nginx will not compress very small files, so we’re are going to create test files that are exactly 1 kilobyte in size. This will allow us to verify whether Nginx uses compression where it should, compressing one type of files and not doing so with the others.

Create a 1 kilobyte file named `test.html` in the default Nginx directory using `truncate`. The extension denotes that it’s an HTML page.

    sudo truncate -s 1k /var/www/html/test.html

Let’s create a few more test files in the same manner: one `jpg` image file, one `css` stylesheet, and one `js` JavaScript file.

    sudo truncate -s 1k /var/www/html/test.jpg
    sudo truncate -s 1k /var/www/html/test.css
    sudo truncate -s 1k /var/www/html/test.js

The next step is to check how Nginx behaves in respect to compression on a fresh installation with the files we have just created.

## Step 2 — Checking the Default Behavior

Let’s check if HTML file named `test.html` is served with compression. The command requests a file from our Nginx server, and specifies that it is fine to serve `gzip` compressed content by using an HTTP header (`Accept-Encoding: gzip`).

    curl -H "Accept-Encoding: gzip" -I http://localhost/test.html

In response, you should see several HTTP response headers:

Nginx response headers

    HTTP/1.1 200 OK
    Server: nginx/1.4.6 (Ubuntu)
    Date: Tue, 19 Jan 2016 20:04:12 GMT
    Content-Type: text/html
    Last-Modified: Tue, 04 Mar 2014 11:46:45 GMT
    Connection: keep-alive
    Content-Encoding: gzip

In the last line, you can see the `Content-Encoding: gzip` header. This tells us that `gzip` compression has been used to send this file. This happened because on Ubuntu 16.04, Nginx has `gzip` compression enabled automatically after installation with its default settings.

However, by default, Nginx compresses only HTML files. Every other file on a fresh installation will be served uncompressed. To verify that, you can request our test image named `test.jpg` in the same way.

    curl -H "Accept-Encoding: gzip" -I http://localhost/test.jpg

The result should be slightly different than before:

Nginx response headers

    HTTP/1.1 200 OK
    Server: nginx/1.4.6 (Ubuntu)
    Date: Tue, 19 Jan 2016 20:10:34 GMT
    Content-Type: image/jpeg
    Content-Length: 0
    Last-Modified: Tue, 19 Jan 2016 20:06:22 GMT
    Connection: keep-alive
    ETag: "569e973e-0"
    Accept-Ranges: bytes

There is no `Content-Encoding: gzip` header in the output, which means the file was served without compression.

You can repeat the test with test CSS stylesheet.

    curl -H "Accept-Encoding: gzip" -I http://localhost/test.css

Once again, there is no mention of compression in the output.

Nginx response headers for CSS file

    HTTP/1.1 200 OK
    Server: nginx/1.4.6 (Ubuntu)
    Date: Tue, 19 Jan 2016 20:20:33 GMT
    Content-Type: text/css
    Content-Length: 0
    Last-Modified: Tue, 19 Jan 2016 20:20:33 GMT
    Connection: keep-alive
    ETag: "569e9a91-0"
    Accept-Ranges: bytes

The next step is to configure Nginx to not only serve compressed HTML files, but also other file formats that can benefit from compression.

## Step 3 — Configuring Nginx’s gzip Settings

To change the Nginx `gzip` configuration, open the main Nginx configuration file in `nano` or your favorite text editor.

    sudo nano /etc/nginx/nginx.conf

Find the `gzip` settings section, which looks like this:

/etc/nginx/nginx.conf

    . . .
    ##
    # `gzip` Settings
    #
    #
    gzip on;
    gzip_disable "msie6";
    
    # gzip_vary on;
    # gzip_proxied any;
    # gzip_comp_level 6;
    # gzip_buffers 16 8k;
    # gzip_http_version 1.1;
    # gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
    . . .

You can see that by default, `gzip` compression is enabled by the `gzip on` directive, but several additional settings are commented out with `#` comment sign. We’ll make several changes to this section:

- Enable the additional settings by uncommenting all of the commented lines (i.e., by deleting the `#` at the beginning of the line)
- Add the `gzip_min_length 256;` directive, which tells Nginx not to compress files smaller than 256 bytes. This is very small files barely benefit from compression.
- Append the `gzip_types` directive with additional file types denoting web fonts, `ico` icons, and SVG images.

After these changes have been applied, the settings section should look like this:

/etc/nginx/nginx.conf

    . . .
    ##
    # `gzip` Settings
    #
    #
    gzip on;
    gzip_disable "msie6";
    
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;
    . . .

Save and close the file to exit.

To enable the new configuration, reload Nginx.

    sudo systemctl reload nginx

The next step is to check whether changes to the configuration have worked as expected.

## Step 4 — Verifying the New Configuration

We can test this just like we did in step 2, by using `curl` on each of the test files and examining the output for the `Content-Encoding: gzip` header.

    curl -H "Accept-Encoding: gzip" -I http://localhost/test.html
    curl -H "Accept-Encoding: gzip" -I http://localhost/test.jpg
    curl -H "Accept-Encoding: gzip" -I http://localhost/test.css
    curl -H "Accept-Encoding: gzip" -I http://localhost/test.js

Now only `test.jpg`, which is an image file, should stay uncompressed. In all other examples, you should be able to find `Content-Encoding: gzip` header in the output.

If that is the case, you have configured `gzip` compression in Nginx successfully!

## Conclusion

Changing Nginx configuration to fully use `gzip` compression is easy, but the benefits can be immense. Not only visitors with limited bandwidth will receive the site faster but also Google will be happy about the site loading faster. Speed is gaining traction as an important part of modern web and using `gzip` is one big step to improve it.
