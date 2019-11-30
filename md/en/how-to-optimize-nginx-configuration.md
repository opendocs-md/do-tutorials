---
author: Alex Kavon
date: 2014-03-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-optimize-nginx-configuration
---

# How To Optimize Nginx Configuration

## Introduction

### Nginx

Nginx is a fast and lightweight alternative to the sometimes overbearing Apache 2. However, Nginx just like any kind of server or software must be tuned to help attain optimal performance.

### Requirements

- A fresh Debian 7 droplet with the [intial setup completed](https://digitalocean.com/community/articles/initial-server-setup-with-debian-7).

- The droplet must also have a freshly installed and configured Nginx server running. Try the [Debian LEMP Stack tutorial](https://digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-debian-7), or for something a little more basic, try the [Debian Nginx Server Blocks tutorial](https://digitalocean.com/community/articles/how-to-setup-nginx-server-blocks-on-debian-7).

- A good understanding of [Linux basics](https://digitalocean.com/community/articles/an-introduction-to-linux-basics).

## Worker Processes and Worker Connections

The first two variables we need to tune are the worker processes and worker connections. Before we jump into each setting, we need to understand what each of these directives control. The **worker\_processes** directive is the sturdy spine of life for Nginx. This directive is responsible for letting our virtual server know many workers to spawn once it has become bound to the proper IP and port(s). It is common practice to run 1 worker process per core. Anything above this won’t hurt your system, but it will leave idle processes usually just lying about.

To figure out what number you’ll need to set **worker\_processes** to, simply take a look at the amount of cores you have on your setup. If you’re using the DigitalOcean 512MB setup, then it’ll probably be one core. If you end up fast resizing to a larger setup, then you’ll need to check your cores again and adjust this number accordingly. We can accomplish this by greping out the cpuinfo:

    grep processor /proc/cpuinfo | wc -l

Let’s say this returns a value of 1. Then that is the amount of cores on our machine!

The `worker_connections` command tells our worker processes how many people can simultaneously be served by Nginx. The default value is 768; however, considering that every browser usually opens up at least 2 connections/server, this number can half. This is why we need to adjust our worker connections to its full potential. We can check our core’s limitations by issuing a ulimit command:

    ulimit -n

On a smaller machine (512MB droplet) this number will probably read 1024, which is a good starting number.

Let’s update our config:

`sudo nano /etc/nginx/nginx.conf`

    worker_processes 1;
    worker_connections 1024;

Remember, the amount of clients that can be served can be multiplied by the amount of cores. In this case, we can server 1024 clients/second. This is, however, even further mitigated by the `keepalive_timeout` directive.

## Buffers

Another incredibly important tweak we can make is to the buffer size. If the buffer sizes are too low, then Nginx will have to write to a temporary file causing the disk to read and write constantly. There are a few directives we’ll need to understand before making any decisions.

`client_body_buffer_size`: This handles the client buffer size, meaning any POST actions sent to Nginx. POST actions are typically form submissions.

`client_header_buffer_size`: Similar to the previous directive, only instead it handles the client header size. For all intents and purposes, 1K is usually a decent size for this directive.

`client_max_body_size`: The maximum allowed size for a client request. If the maximum size is exceeded, then Nginx will spit out a 413 error or _Request Entity Too Large_.

`large_client_header_buffers`: The maximum number and size of buffers for large client headers.

    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 8m;
    large_client_header_buffers 2 1k;

## Timeouts

Timeouts can also drastically improve performance.

The `client_body_timeout` and `client_header_timeout` directives are responsible for the time a server will wait for a client body or client header to be sent after request. If neither a body or header is sent, the server will issue a 408 error or _Request time out_.

The `keepalive_timeout` assigns the timeout for keep-alive connections with the client. Simply put, Nginx will close connections with the client after this period of time.

Finally, the `send_timeout` is established not on the entire transfer of answer, but only between two operations of reading; if after this time client will take nothing, then Nginx is shutting down the connection.

    client_body_timeout 12;
    client_header_timeout 12;
    keepalive_timeout 15;
    send_timeout 10;

## Gzip Compression

Gzip can help reduce the amount of network transfer Nginx deals with. However, be careful increasing the `gzip_comp_level` too high as the server will begin wasting cpu cycles.

    gzip on;
    gzip_comp_level 2;
    gzip_min_length 1000;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain application/x-javascript text/xml text/css application/xml;

## Static File Caching

It’s possible to set expire headers for files that don’t change and are served regularly. This directive can be added to the actual Nginx server block.

    location ~* .(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 365d;
    }

Add and remove any of the file types in the array above to match the types of files your Nginx servers.

## Logging

Nginx logs every request that hits the VPS to a log file. If you use analytics to monitor this, you may want to turn this functionality off. Simply edit the `access_log` directive:

    access_log off;

Save and close the file, then run:

    sudo service nginx restart

### Conclusion

At the end of the day a properly configured server is one that is monitored and tweaked accordingly. None of the variables above are set in stone and will need to be adjusted to each unique case. Even further down the road, you may be looking to further your machine performance with research in load balancing and horizontal scaling. These are just a few of the many enhancements a good sysadmin can make to a server.

Submitted by: [Alex Kavon](https://twitter.com/alexkavon)
