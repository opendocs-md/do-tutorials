---
author: Melissa Anderson
date: 2017-05-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-buildbot-with-ssl-using-an-nginx-reverse-proxy
---

# How To Configure Buildbot with SSL using an Nginx Reverse Proxy

 **Note** : This tutorial covers an older version of Buildbot, so the instructions may not work on current versions. Until this article is updated, you can additionally use the [official Buildbot reverse proxy configuration documentation](http://docs.buildbot.net/latest/manual/cfg-www.html#reverse-proxy-configuration).

## Introduction

Buildbot is a Python-based continuous integration system for automating software build, test, and release processes. In the previous tutorials, we [installed Buildbot](how-to-install-buildbot-on-ubuntu-16-04) and [created systemd Unit files](how-to-create-systemd-unit-files-for-buildbot) to allow the server’s init system to manage the processes. Buildbot comes with its own built-in web server listening on port 8010, and in order to secure the web interface with SSL we’ll need to configure a reverse proxy.

In this tutorial, we’ll demonstrate how to configure Nginx as a reverse proxy in order to direct SSL-secured browser requests to Buildbot’s web interface.

## Prerequisites

To follow this tutorial, you will need:

- **One Ubuntu 16.04 server with at least 1 GB of RAM** , configured with a non-root `sudo` user and a firewall by following the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) 

In addition, you’ll need to complete the following tutorials on the server:

- [How To Install Buildbot on Ubuntu 16.04](how-to-install-buildbot-on-ubuntu-16-04)
- [How To Create Systemd Unit Files for Buildbot](how-to-create-systemd-unit-files-for-buildbot)
- [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04)
- [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04).

When you’ve completed these requirements, you’re ready to begin.

## Step 1— Configuring Nginx

In the prerequisite tutorial, [How to Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04), we configured Nginx to use SSL in the `/etc/nginx/sites-available/default` file. Before we begin, we’ll make a backup of our working configuration file:

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.ssl.bak

Next, we’ll open `default` and add our reverse proxy settings.

    sudo nano /etc/nginx/sites-available/default

First, we’ll add specific access and error logs in the SSL `server` block.

/etc/nginx/sites-available/default

    . . . 
    server {
            # SSL Configuration
            #
    . . .
             # include snippets/snakeoil.conf;
             access_log /var/log/nginx/buildbot.access.log;
             error_log /var/log/nginx/buildbot.error.log;
    . . .        
    

Next, we’ll configure the proxy settings.

Since we’re sending all requests to Buildbot, we’ll need to delete or comment out the default `try_files` line which, as written, will return 404 errors before requests reach Buildbot.

**Note:** Unlike most applications, Buildbot will return a 200 response for a request to the document root with the `try_files` setting enabled. If assets are cached by the browser, Buildbot may appear to be working. Without cached assets, it will return a blank page.

Then we’ll add the reverse proxy configuration. The first line includes the Nginx-supplied `proxy_params` to ensure information like the hostname, the protocol of the client request, and the client IP address will be available in our log files. The `proxy_pass` sets the protocol and address of the proxied server, which in our case is the Buildbot server accessed on the localhost on port 8010.

/etc/nginx/sites-available/default

    . . .
            location / {
                    # First attempt to serve request as file, then
                    # as directory, then fall back to displaying a 404.
                    # try_files $uri $uri/ =404;
    
                    # Reverse proxy settings
                    include proxy_params;
                    proxy_pass http://localhost:8010;
                 }
    . . . 
    

Directly after this stanza, we’ll configure two additional locations, `/sse` and `/ws`:

- **Server Sent Event (SSE) settings** [Server Sent Events](http://docs.buildbot.net/current/developer/www-server.html#server-sent-events) are a simpler, more REST compliant protocol than WebSockets that allow clients to subscribe to events. The Buildbot SSE endpoint requires its own `proxy_pass` setting and benefits from turning off `proxy_buffering`.

- **WebSocket settings** [WebSocket](http://docs.buildbot.net/current/developer/www-server.html#websocket) is a protocol for messaging between the web server and web browsers. Like the SSE protocol, it requires its own `proxy_pass` setting. Additional configuration is also required to pass header information. You can learn more these settings from the [Nginx WebSocket proxying documentation](http://nginx.org/en/docs/http/websocket.html). 

/etc/nginx/sites-available/default

    . . .
            # Server sent event (sse) settings
            location /sse {
                    proxy_buffering off;
                    proxy_pass http://localhost:8010;
            }
    
            # Websocket settings
            location /ws {
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection "upgrade";
                  proxy_pass http://localhost:8010;
                  proxy_read_timeout 6000s;
            }
     . . .

Once you’ve made these changes, save and exit the file.

Finally, we’ll edit the `ssl_params.conf` and increase the `ssl_session_timeout` to the project’s recommended setting of 1440 minutes (24 hours) to accommodate longer builds:

    sudo nano /etc/nginx/snippets/ssl-params.conf

At the bottom of the file, add the following line:

/etc/nginx/snippets/ssl-params.conf

     . . . 
    ssl_session_timeout 1440m;

When you’re done, save and exit the file.

**Note:** The Buildbot documentation’s sample Nginx file includes a line setting the `ssl_session_cache` size to 1,440 megabytes, which allows over 5 million connections. We’ve opted to retain a less memory-intensive setting of 10 megabytes. Each megabyte can store about 4000 sessions, so this will store around 40,000 sessions, which is sufficient for most use cases.

We won’t restart Nginx until after we’ve configured Buildbot, but we will test our configuration now in case we’ve made any mistakes:

    sudo nginx -t

If all is well, the command will return:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

If not, fix the reported errors until the test passes.

## Step 2 — Configuring Buildbot

Buildbot uses root-relative links in its web interface and needs to have the base URL defined in the `master.cfg` for links to work properly.

    sudo nano /home/buildbot/master/master.cfg

Locate the `buildbotURL` setting, change `http` to `https` , and change `localhost` to your domain. Remove the port specification (`:8010`) since Nginx will proxy requests made to the conventional web ports. **Important:** The protocol must be `https` and the definition must contain the trailing slash.

/home/buildbot/master/master.cfg

     . . .
     c['buildbotURL'] = "https://your.ssl.domain.name/"
     . . .

We will also ensure the master won’t accept direct connections from workers running on other hosts by binding to the local loopback interface. Comment out or replace the existing protocol line, `c['protocols'] = {'pb': {'port': 9989}}`, with the following:

/home/buildbot/master/master.cfg

    . . .
    c['protocols'] = {"pb": {"port": "tcp:9989:interface=127.0.0.1"}}
    . . .

When you’re done, save and exit the file.

Now that we’re using HTTPS and a domain name, we’ll install the [`service_identity` module](https://service-identity.readthedocs.io/en/stable/), which provides tools to determine certificate is valid for the intended purpose.

    sudo -H pip install service_identity

If we skipped this step, Buildbot would still restart, but would issue the UserWarning “You do not have a working installation of the service\_identity module” which would be visible in the output of systemd’s `status` command.

## Step 3 — Restarting Services

Now we’re ready to restart Nginx:

    sudo systemctl restart nginx

Since `systemctl` doesn’t provide output, we’ll use its `status` command to be sure Nginx is running.

    sudo systemctl status nginx

The output should highlight “Active: active (running) and end with something like:

    OutputMay 08 18:07:52 buildbot-server systemd[1]: 
    Started A high performance web server and a reverse proxy server.

Next, we’ll restart the buildmaster and worker using `systemctl`, which we configured in the [previous tutorial](how-to-create-systemd-unit-files-for-buildbot).

First, check the configuration file for syntax errors:

    sudo buildbot checkconfig /home/buildbot/master/

    OutputConfig file is good!

If no errors are reported, restart the service:

    sudo systemctl restart buildbot-master
    sudo systemctl status buildbot-master

The output should highlight "Active: active (running) and end with something like:

    OutputMay 10 21:28:05 buildbot-server systemd[1]: Started BuildBot master service.

Next, we’ll restart the worker:

    sudo systemctl restart buildbot-worker
    sudo systemctl status buildbot-worker

Again, the output should highlight "Active: active (running) and in this case end with something like:

    OutputMay 10 21:28:05 buildbot-server systemd[1]: Started BuildBot worker service.

Now that we’ve restarted Nginx, the buildmaster, and the worker, we’re ready to verify the reverse proxy is working as expected. When we visit the site via `http` we should be redirected to `https` and successfully reach our Buildbot site.

In your web browser, enter "http://your.ssl.domain.name”, substituting your domain for `your.ssl.domain.name`. After you press enter, the URL should start with `https` and the location bar should indicate that the connection is secure.   
 ![Screenshot of Buildbot home page with secure URL](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-nginx-ubuntu-1604/buildbot-secure.png)

Next, we’ll take a moment and see that the Web Socket and Server Sent Events are being proxied properly.

First, visit the `/sse` directory. If the redirect is working properly, the browser should return the following page. Note that the page will continue trying to load, and this is normal behavior:

![Buildbot SSE page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-nginx-ubuntu-1604/buildbot-sse-redirect.png)

Next, visit the /ws directory. If the proxy redirect isn’t correct, visiting the `/ws` directory will return a `404 Not Found` error. If all is well, the browser should return the following page:  
 ![Buildbot WebSocket page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-nginx-ubuntu-1604/buildbot-ws-redirect.png)

Finally, since the built-in web server listens on all interfaces, we’ll delete our rule that allows external traffic to port 8010 in order to prevent unencrypted connections when accessing the server by IP address:

    sudo ufw delete allow 8010

    OutputRule updated
    Rule updated (v6)

We have now configured Nginx as a reverse proxy and prevented users from accessing Buildbot using `HTTP`.

### Conclusion

In this tutorial we configured Nginx as a reverse proxy to Buildbot’s built-in web server in order to secure our credentials and other information transmitted via the Web interface. If you’re new to Buildbot, you might want to explore [the Buildbot project’s Quick Tour](http://docs.buildbot.net/current/tutorial/tour.html) guide. When you are ready to learn how to set up a complete continuous integration process, check out our [How To Set Up Continuous Integration with Buildbot on Ubuntu 16.04](how-to-set-up-continuous-integration-with-buildbot-on-ubuntu-16-04) guide.
