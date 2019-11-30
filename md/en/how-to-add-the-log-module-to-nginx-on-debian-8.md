---
author: Hazel Virdó
date: 2017-06-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-add-the-log-module-to-nginx-on-debian-8
---

# How To Add the log Module to Nginx on Debian 8

## Introduction

Server administration is not only about the initial configuration of services. It also involves overseeing those services and making sure they’re running as smoothly as possible. One of the most important sources of knowledge for administrators are log files, which contain information about system events.

In case of a web server, like Nginx, logs contain valuable information about each attempt to access resources through the web server. Each web site visitor and image seen or file downloaded is meticulously registered in the logs. When errors happen, they will be saved in the logs as well. It is much easier to work with log files that are well-structured.

In this guide, we will look at how to utilize Nginx’s logging module. We’ll set up separate log files for different server blocks and then customize the logging output. We’ll also add additional information about requests (in this tutorial’s example, the time it takes to serve a request) to the access log beyond what Nginx includes by default.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 8 server set up with [this initial server setup tutorial](initial-server-setup-with-debian-8), including a sudo non-root user.

- Nginx installed on your server by following the [How To Install Nginx on Debian 8 tutorial](how-to-install-nginx-on-debian-8).

## Step 1 — Creating Test Files

In this step, we will create several test files in the default Nginx website directory. We’ll use these to test our logging configuration.

When Nginx (or any other web server) receives a HTTP request for a file, it opens that file and serves it to the user by transferring its contents through the network. The smaller the file, the faster it can be transferred. When the file is transferred in full, the request is considered complete, and only then is transfer logged.

Later in this tutorial, we’ll be modifying the logging configuration to include useful information about how much time each request took. The easiest way to test the modified configuration and notice the difference between different requests is to create several test files of varying sizes that will be transmitted in different amount of time.

Let’s create a 1 megabyte file named `1mb.test` in the default Nginx directory using `truncate`.

    sudo truncate -s 1M /var/www/html/1mb.test

Similarly let’s create two more files of different sizes, first 10 and then 100 megabytes, naming them accordingly.

    sudo truncate -s 10M /var/www/html/10mb.test
    sudo truncate -s 100M /var/www/html/100mb.test

Last but not least, let’s create an empty file, too:

    sudo touch /var/www/html/empty.test

We’ll use these files in the next step to populate the log file with the default configuration, and then later in the tutorial to demonstrate the customized configuration.

## Step 2 — Understanding the Default Configuration

The log module is a core Nginx module, which means it doesn’t need to be installed separately to be used. The default configuration, however, is a bare minimum. In this step, we will see how the default configuration works.

On a fresh installation, Nginx logs all requests to two separate files: the access log and the error log. The error log, located in `/var/log/nginx/error.log`, stores information about unusual server errors, or errors in processing the request.

The access log, located in `/var/log/nginx/access.log`, is used more often. It’s where information about all requests to Nginx is kept. In this log you can see, among other things, which files users are accessing, which web browsers they’re using, which IP addresses they have, and which HTTP status code Nginx responded with to each request.

Let’s see what an example line of the access log file looks like. First, request the empty file we created in Step 1 from Nginx so the log file won’t be empty.

    curl -i http://localhost/empty.test

In response, you should see several HTTP response headers:

Nginx response headers

    HTTP/1.1 200 OK
    Server: nginx/1.6.2
    Date: Fri, 09 Dec 2016 23:05:18 GMT
    Content-Type: application/octet-stream
    Content-Length: 0
    Last-Modified: Fri, 09 Dec 2016 23:05:13 GMT
    Connection: keep-alive
    ETag: "584b38a9-0"
    Accept-Ranges: bytes

From this response, you can learn several things:

- `HTTP/1.1 200 OK` tells us that Nginx responded with `200 OK` status code telling us there was no error.
- `Content-Length: 0` means the returned document is zero-length.
- The request was processed on `Fri, 09 Dec 2016 23:05:18 GMT`.

Let’s see if this matches what Nginx stored in its access log. The log files are readable only by administrative users, so `sudo` must be used to access them.

    sudo tail /var/log/nginx/access.log

The log will contain a line like this, corresponding to the test request we have issued earlier.

Access log entry

    127.0.0.1 - - [09/Dec/2016:23:07:02 +0000] "GET /empty.test HTTP/1.1" 200 0 "-" "curl/7.38.0"

Nginx uses _Combined Log Format_, which is a standardized format of access logs commonly used by web servers for interoperability. In this format, each piece of information is delimited by a single space; hyphens represent missing pieces of information.

From left to right, the categories are:

- The **IP address of the user** who requested the resource. Because you used `curl` locally, the address points to the local host, `127.0.0.1`.

- **Remote logging** information. This will always be a hyphen here because Nginx doesn’t support this information.

- The **username of a logged in user** according to HTTP Basic Authentication. This will be empty for all anonymous requests.

- The **request date**. You can see this matches the date from our response headers.

- The **request path** , which includes the request method (`GET`), the path to the requested file (`/empty.text`) as well as the protocol used (`HTTP/1.1`).

- The **response status code** , which was `200 OK`, meaning success.

- The **length of the transferred file** , which is `0` here because the file was empty.

- The **HTTP Referer header** , which contains the address of the document where the request originated. In this example, it’s empty, but if this was an image file, the referer would point to the page on which the image was used.

- The **user agent** , which is `curl` here.

Even a single log entry in the access log contains a lot of valuable information about a request. However, there is one important bit of information missing. While we have requested the exact location of `http://localhost/empty.test`, only the path to the `/empty.test` file is in the log entry; information about the hostname (here, the `localhost`) is lost.

## Step 3 — Configuring a Separate Access Log

Next, we will override the default logging configuration (where Nginx stores one access log file for all requests) and make Nginx instead store separate log file for the default server block that comes with the clean Nginx installation. You can get acquainted with Nginx server blocks by reading the [How To Set Up Nginx Server Blocks on Debian 7](how-to-setup-nginx-server-blocks-on-debian-7) tutorial.

It is a good practice to store separate log files for each server block, effectively separating logs from different websites from each other. Not only does this make log files smaller, but it importantly makes logs easier to analyze to spot errors and suspicious activity.

To change the default Nginx server block configuration, open the server block Nginx configuration file in `nano` or your favorite text editor.

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

and add the two lines marked in red to the configuration:

/etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        access_log /var/log/nginx/default-access.log;
        error_log /var/log/nginx/default-error.log;
    . . .

The `access_log` directive sets the path to file where access logs will be stored, and `error_log` does the same for the error log. We use same directory as the default Nginx logs (`/var/log/nginx`), but with different filenames. If you have multiple server blocks, it is a good idea to name log files in a consistent and meaningful way, like using the domain name in the filename.

Save and close the file to exit.

**Note:** Remember that in order to maintain separate log files for each server block, you have to apply the aforementioned configuration change every time you create a new server block in your Nginx configuration.

To enable the new configuration, restart Nginx.

    sudo systemctl restart nginx.service

To test the new configuration, execute the same request for our empty test file as before.

    curl -i http://localhost/empty.test

Check that the log line identical to the one we saw before is written to the separate file we have just configured.

    sudo tail /var/log/nginx/default-access.log

In the next step, we’ll customize the format of the logs in this new file and include additional information.

## Step 4 — Configuring a Custom Log Format

Here, we’ll set up a custom logging format to make Nginx log additional information (how long the request took to be processed), and configure the default server block to use this new format.

We need to define the new log format before it can used. In Nginx, each log format has a unique name, which is global for the whole server. Individual server blocks can be configured to use those formats later on simply by referring to their names.

To define the new logging format, create a new configuration file called `timed-log-format.conf` in the Nginx extra configuration directory.

    sudo nano /etc/nginx/conf.d/timed-log-format.conf

Add the following contents:

/etc/nginx/conf.d/timed-log-format.conf

    log_format timed '$remote_addr - $remote_user [$time_local] '
                     '"$request" $status $body_bytes_sent '
                     '"$http_referer" "$http_user_agent" $request_time';

Save and close the file to exit.

The `log_format` setting directive defines the new log format. The next element is the unique identifier of this format; here we’re using **timed** , but you can choose any name.

Next is the log format itself, divided to three lines for readability. Nginx exposes the information about all requests in named system variables preceded by the dollar sign. These will be replaced by the actual information about the request while writing the request details into the access log (e.g., `$request_addr` will be replaced with the visitor’s IP address).

The format above is identical to Common Log Format discussed earlier with the one difference: the addition of `$request_time` system variable at the very end. Nginx uses this variable to store how long the request took in milliseconds, and by using this variable in our log format, we tell Nginx to write that information to the log file.

Now we have a custom log format named **timed** defined in the Nginx configuration, but the default server block does not use this format yet. Next, open the server block Nginx configuration file.

    sudo nano /etc/nginx/sites-available/default

Find the `server` configuration block which we modified earlier and add the `timed` log format name to the `access_log` setting as highlighted below in red:

/etc/nginx/sites-available/default

    . . .
    # Default server configuration
    #
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        access_log /var/log/nginx/default-access.log timed;
        error_log /var/log/nginx/default-error.log;
    . . .

Save and close the file to exit.

To enable the new configuration, restart Nginx.

    sudo systemctl restart nginx.service

Now that everything set up, let’s check that it works.

## Step 5 — Verifying the New Configuration

We can test the new configuration by invoking some requests to Nginx with `curl`, like we did in step 2. This time we will use the sample files created in step 1:

    curl -i http://localhost/empty.test
    curl -i http://localhost/1mb.test
    curl -i http://localhost/10mb.test
    curl -i http://localhost/100mb.test

You will notice that each subsequent command will take longer to execute, as the files get bigger and it takes more time to transfer them.

Let’s display the access log after executing those requests.

    sudo tail /var/log/nginx/default-access.log

The log will now contain more lines, but the last four will correspond to the test requests you just executed.

Access log entries

    127.0.0.1 - - [09/Dec/2016:23:07:02 +0000] "GET /empty.test HTTP/1.1" 200 0 "-" "curl/7.38.0"
    127.0.0.1 - - [09/Dec/2016:23:08:28 +0000] "GET /empty.test HTTP/1.1" 200 0 "-" "curl/7.38.0" 0.000
    127.0.0.1 - - [09/Dec/2016:23:08:28 +0000] "GET /1mb.test HTTP/1.1" 200 1048576 "-" "curl/7.38.0" 0.000
    127.0.0.1 - - [09/Dec/2016:23:08:28 +0000] "GET /10mb.test HTTP/1.1" 200 10485760 "-" "curl/7.38.0" 0.302
    127.0.0.1 - - [09/Dec/2016:23:08:39 +0000] "GET /100mb.test HTTP/1.1" 200 68516844 "-" "curl/7.38.0" 7.938

You will see that the paths differ each time, showing the correct filename, and the request size increases each time. The important part is the last highlighted number, which is the request processing time in milliseconds that we just configured in our custom log format. As you’d expect, the bigger the file gets, the longer it takes to transfer.

If that is the case, you have configured custom log format in Nginx successfully!

## Conclusion

While it is not particularly useful to see that bigger files take longer to transfer, the request processing time can be very useful when Nginx is used to serve dynamic websites. It can be used to trace bottlenecks in the website and easily find requests that took longer than they should.

`$request_time` is just one of many system variables Nginx exposes that can be used in custom logging configurations. Others include, for example, value of response headers sent with the response to the client. Adding other variables to the log format is as easy as putting them in the log format string just like we did with `$request_time`. It is a powerful tool you can use to your advantage while configuring logging for your websites.

The list of variables that can be used with Nginx log formats is described in [Nginx’s log module documentation](http://nginx.org/en/docs/http/ngx_http_log_module.html).
