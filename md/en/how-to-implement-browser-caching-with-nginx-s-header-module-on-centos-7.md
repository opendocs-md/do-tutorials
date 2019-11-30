---
author: Mateusz Papiernik
date: 2016-10-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-implement-browser-caching-with-nginx-s-header-module-on-centos-7
---

# How to Implement Browser Caching with Nginx's header Module on CentOS 7

## Introduction

The faster a website loads, the more likely a visitor is to stay. When websites are full of images and interactive content run by scripts loaded in the background, opening a website is not a simple task. It consists of requesting many different files from the server one by one. Minimizing the quantity of these requests is one way to speed up your website.

This can be done in many ways, but one of the more important steps to take is to configure _browser caching_. This is telling the browser that files downloaded once can be reused from local copies instead of requesting the server for them again and again. To do this, new HTTP response headers telling the browser how to behave must be introduced.

This is where Nginx’s header module comes into play. This module can be used to add any arbitrary headers to the response, but its major role is to properly set caching headers. In this tutorial, we will look at how to use Nginx’s header module to implement browser caching.

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server set up with [this initial server setup tutorial](initial-server-setup-with-centos-7), including a sudo non-root user.

- Nginx installed on your server by following the [How To Install Nginx on CentOS 7 tutorial](how-to-install-nginx-on-centos-7).

In addition to the header module, we’ll also be using Nginx’s map module in this article. To learn more about the map module, you can read [How To Use Nginx’s map Module on CentOS 7](how-to-use-nginx-s-map-module-on-centos-7).

## Step 1 — Creating Test Files

In this step, we will create several test files in the default Nginx directory. We’ll use these files later to check Nginx’s default behavior and then to test that browser caching is working.

To make a decision about what kind of file is served over the network, Nginx does not analyze the file contents; that would be prohibitively slow. Instead, it just looks up the file extension to determine the file’s _MIME type_, which denotes the purpose of the file.

Because of this behavior, the content of our test files is irrelevant. By naming the files appropriately, we can trick Nginx into thinking that, for example, one entirely empty file is an image and another is a stylesheet.

Create a file named `test.html` in the default Nginx directory using `truncate`. This extension denotes that it’s an HTML page.

    sudo truncate -s 1k /usr/share/nginx/html/test.html

Let’s create a few more test files in the same manner: one `jpg` image file, one `css` stylesheet, and one `js` JavaScript file.

    sudo truncate -s 1k /usr/share/nginx/html/test.jpg
    sudo truncate -s 1k /usr/share/nginx/html/test.css
    sudo truncate -s 1k /usr/share/nginx/html/test.js

The next step is to check how Nginx behaves with respect to sending caching control headers on a fresh installation with the files we have just created.

## Step 2 — Checking the Default Behavior

By default, all files will have the same default caching behavior. To explore this, we’ll use the HTML file we created in step 1, but you can run these tests with any of the example files.

So, let’s check if `test.html` is served with any information regarding how long the browser should cache the response. The following command requests a file from our local Nginx server and shows the response headers.

    curl -I http://localhost/test.html

You should see several HTTP response headers:

    Output: Nginx response headersHTTP/1.1 200 OK
    Server: nginx/1.10.1
    Date: Thu, 06 Oct 2016 10:21:04 GMT
    Content-Type: text/html
    Content-Length: 1024
    Last-Modified: Thu, 06 Oct 2016 10:20:44 GMT
    Connection: keep-alive
    ETag: "57f6257c-400"
    Accept-Ranges: bytes

In the second to last line you can see the `ETag` header, which contains a unique identifier for this particular revision of the requested file. If you execute the previous `curl` command repeatedly, you will see the exact same `ETag` value.

When using a web browser, the `ETag` value is stored and sent back to the server with the `If-None-Match` request header when the browser wants to request the same file again — for example, when refreshing the page.

We can simulate this on the command line with the following command. Make sure you change the `ETag` value in this command to match the `ETag` value in your previous output.

    curl -I -H 'If-None-Match: "57f6257c-400"' http://localhost/test.html

The response will now be different:

    Output: Nginx response headersHTTP/1.1 304 Not Modified
    Server: nginx/1.10.1
    Date: Thu, 06 Oct 2016 10:21:40 GMT
    Last-Modified: Thu, 06 Oct 2016 10:20:44 GMT
    Connection: keep-alive
    ETag: "57f6257c-400"

This time, Nginx will respond with **304 Not Modified**. It won’t send the file over the network again; instead, it will tell the browser that it can reuse the file it already has downloaded locally.

This is useful because it reduces network traffic, but it’s not quite good enough for achieving good caching performance. The problem with `ETag` is that browser **always** sends a request to the server asking if it can reuse its cached file. Even though the server responds with a 304 instead of sending the file again, it still takes time to make the request and receive the response.

In the next step, we will use the headers module to append caching control information. This will make the browser to cache some files locally without explicitly asking the server if its fine to do so.

## Step 3 — Configuring Cache-Control and Expires Headers

In addition to the `ETag` file validation header, there are two caching control response headers: `Cache-Control` and `Expires`. `Cache-Control` is the newer version, which has more options than `Expires` and is generally more useful if you want finer control over your caching behavior.

If these headers are set, they can tell the browser that the requested file can be kept locally for a certain amount of time (including forever) without requesting it again. If the headers are not set, browsers will always request the file from the server, expecting either **200 OK** or **304 Not Modified** responses.

We can use the header module to set these HTTP headers. The header module is a core Nginx module, which means it doesn’t need to be installed separately to be used.

To add the header module, open the default server block Nginx configuration file in `vi` (here’s a [short introduction to `vi`](installing-and-using-the-vim-text-editor-on-a-cloud-server#modal-editing)) or your favorite text editor.

    sudo vi /etc/nginx/nginx.conf

Find the `server` configuration block, which looks like this:

/etc/nginx/nginx.conf

    . . .
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    . . .

Add the following two new sections here: one before the `server` block, to define how long to cache different file types, and one inside it, to set the caching headers appropriately.

Modified /etc/nginx/nginx.conf

    . . .
    # Expires map
    map $sent_http_content_type $expires {
        default off;
        text/html epoch;
        text/css max;
        application/javascript max;
        ~image/ max;
    }
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        expires $expires;
    . . .

The section before the `server` block is a new `map` block which defines the mapping between the file type and how long that kind of file should be cached.

We’re using several different settings in this map:

- The default value is set to `off`, which will not add any caching control headers. It’s a safe bet for content we have no particular requirements on how the cache should work.

- For `text/html`, we set the value to `epoch`. This is a special value which results explicitly in no caching, which forces the browser to always ask if the website itself is up to date.

- For `text/css` and `application/javascript`, which are stylesheets and Javascript files, we set the value to `max`. This means the browser will cache these files for as long as it can, reducing the amount of requests considerably given that there are typically many of these files.

- The last setting is for `~image/`, which is a regular expression that will match all file types containing `image/` in their _MIME type_ name (like `image/jpg` and `image/png`). Like stylesheets, there are often a lot of images on websites that can be safely cached, so we set this to `max` as well.

Inside the server block, the `expires` directive (a part of the headers module) sets the caching control headers. It uses the value from the `$expires` variable set in the map. This way, the resulting headers will be different depending on the file type.

Save and close the file to exit.

To enable the new configuration, restart Nginx.

    sudo systemctl restart nginx

Next, let’s make sure our new configuration works.

## Step 4 — Testing Browser Caching

Execute the same request as before for the test HTML file.

    curl -I http://localhost/test.html

This time the response will be different. You should see two additional HTTP response headers:

Nginx response headers

    HTTP/1.1 200 OK
    Server: nginx/1.10.1
    Date: Thu, 06 Oct 2016 10:24:42 GMT
    Content-Type: text/html
    Content-Length: 1024
    Last-Modified: Thu, 06 Oct 2016 10:20:44 GMT
    Connection: keep-alive
    ETag: "57f6257c-400"
    Expires: Thu, 01 Jan 1970 00:00:01 GMT
    Cache-Control: no-cache
    Accept-Ranges: bytes

The `Expires` header shows a date in the past and `Cache-Control` is set with `no-cache`, which tells the browser to always ask the server if there is a newer version of the file (using the `ETag` header, like before).

You’ll see a difference response with the test image file.

    curl -I http://localhost/test.jpg

Nginx response headers

    HTTP/1.1 200 OK
    Server: nginx/1.10.1
    Date: Thu, 06 Oct 2016 10:25:02 GMT
    Content-Type: image/jpeg
    Content-Length: 1024
    Last-Modified: Thu, 06 Oct 2016 10:20:46 GMT
    Connection: keep-alive
    ETag: "57f6257e-400"
    Expires: Thu, 31 Dec 2037 23:55:55 GMT
    Cache-Control: max-age=315360000
    Accept-Ranges: bytes

In this case, `Expires` shows the date in the distant future, and `Cache-Control` contains `max-age` information, which tells the browser how long it can cache the file in seconds. This tells the browser to cache the downloaded image for as long as it can, so any subsequent appearances of this image will use local cache and not send a request to the server at all.

The result should be similar for both `test.js` and `test.css`, as both JavaScript and stylesheet files are set with caching headers too.

This means the cache control headers have been configured properly and your website will benefit from the performance gain and less server requests due to browser caching. You should customize the caching settings based on the content for your website, but the defaults in this article are a reasonable place to start.

## Conclusion

The headers module can be used to add any arbitrary headers to the response, but properly setting caching control headers is one of its most useful applications. It increases performance for the website users, especially on networks with higher latency, like mobile carrier networks. It can also lead to better results on search engines that factor speed tests into their results. Setting browser caching headers is one of the major recommendations from Google’s PageSpeed testing tools.

More detailed information about the headers module can be found [in Nginx’s official headers module documentation](http://nginx.org/en/docs/http/ngx_http_headers_module.html).
