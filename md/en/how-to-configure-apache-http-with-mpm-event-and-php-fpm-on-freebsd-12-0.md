---
author: Albert Valbuena
date: 2019-07-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-apache-http-with-mpm-event-and-php-fpm-on-freebsd-12-0
---

# How To Configure Apache HTTP with MPM Event and PHP-FPM on FreeBSD 12.0

_The author selected the [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

The [Apache HTTP](http://httpd.apache.org/) web server has evolved through the years to work in different environments and solve different needs. One important problem Apache HTTP has to solve, like any web server, is how to handle different processes to serve an http protocol request. This involves opening a socket, processing the request, keeping the connection open for a certain period, handling new events occurring through that connection, and returning the content produced by a program made in a particular language (such as PHP, Perl, or Python). These tasks are performed and controlled by a _Multi-Processing Module_ (MPM).

Apache HTTP comes with three different MPM:

- **Pre-fork** : A new process is created for each incoming connection reaching the server. Each process is isolated from the others, so no memory is shared between them, even if they are performing identical calls at some point in their execution. This is a safe way to run applications linked to libraries that do not support threading—typically older applications or libraries.
- **Worker** : A parent process is responsible for launching a pool of child processes, some of which are listening for new incoming connections, and others are serving the requested content. Each process is threaded (a single thread can handle one connection) so one process can handle several requests concurrently. This method of treating connections encourages better resource utilization, while still maintaining stability. This is a result of the pool of available processes, which often has free available threads ready to immediately serve new connections.
- **Event** : Based on worker, this MPM goes one step further by optimizing how the parent process schedules tasks to the child processes and the threads associated to those. A connection stays open for 5 seconds by default and closes if no new event happens; this is the keep-alive directive default value, which retains the thread associated to it. The Event MPM enables the process to manage threads so that some threads are free to handle new incoming connections while others are kept bound to the live connections. Allowing re-distribution of assigned tasks to threads will make for better resource utilization and performance.

The [MPM Event](https://httpd.apache.org/docs/2.4/mod/event.html) module is a fast multi-processing module available on the Apache HTTP web server.

[PHP-FPM](https://php-fpm.org/) is the FastCGI Process Manager for PHP. The FastCGI protocol is based on the Common Gateway Interface (CGI), a protocol that sits between applications and web servers like Apache HTTP. This allows developers to write applications separately from the behavior of web servers. Programs run their processes independently and pass their product to the web server through this protocol. Each new connection in need of processing by an application will create a new process.

By combining the MPM Event in Apache HTTP with the PHP FastCGI Process Manager (PHP-FPM) a website can load faster and handle more concurrent connections while using fewer resources.

In this tutorial you will improve the performance of the [FAMP stack](how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0) by changing the default multi-processing module from pre-fork to event and by using the PHP-FPM process manager to handle PHP code instead of the classic `mod_php` in Apache HTTP.

## Prerequisites

Before you begin this guide you’ll need the following:

- A FreeBSD 12.0 server set up following this [guide](how-to-get-started-with-freebsd).
- The FAMP stack installed on your server following this [tutorial](how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-12-0).
- Access to a user with root privileges (or allowed by using sudo) in order to make configuration changes.

## Step 1 — Changing the Multi-Processing Module

You’ll begin by looking for the pre-fork directive in the `httpd.conf` file. This is the main configuration file for Apache HTTP in which you can enable and disable modules. You can edit and set directives such as the listening port where Apache HTTP will serve content or the location of the content to display in this file.

To make these changes, you’ll use the `nl`, number line, program, with the `-ba` flag to count and number lines so that nothing is mismatched at a later stage. Combined with `grep` this command will first count all the lines in the file specified in the path, and once finished, it will search for the string of characters you’re looking for.

Run the following command so that the `nl` program will process and number the lines in `httpd.conf`. Then, `grep` will process the output by searching for the given string of characters `'mod_mpm_prefork'`:

    nl -ba /usr/local/etc/apache24/httpd.conf | grep 'mod_mpm_prefork'

As output you’ll see something similar to:

    Output67 LoadModule mpm_prefork_module libexec/apache24/mod_mpm_prefork.so

Let’s edit line 67 with your text editor. In this tutorial, you’ll use `vi`, which is the default editor on FreeBSD:

    sudo vi +67 /usr/local/etc/apache24/httpd.conf

Append a `#` symbol at the beginning of the line so this line is commented out, like so:

/usr/local/etc/apache24/httpd.conf

    ...
    # LoadModule mpm_prefork_module libexec/apache24/mod_mpm_prefork.so
    ...

By appending the `#` symbol you’ve disabled the pre-fork MPM module.

Now you’ll find the event directive in the same `httpd.conf` file.

    nl -ba /usr/local/etc/apache24/httpd.conf | grep mpm_event

You’ll see output similar to the following:

    Output...
    66 #LoadModule mpm_event_module libexec/apache24/mod_mpm_event.so
    ...

Now you’ll remove the `#` symbol in line 66 to enable the Event MPM:

    sudo vi +66 /usr/local/etc/apache24/httpd.conf

The directive will now read as follows:

/usr/local/etc/apache24/httpd.conf

    ...
    LoadModule mpm_event_module libexec/apache24/mod_mpm_event.so
    ...

Now that you’ve switched the configuration from the MPM pre-fork to event, you can remove the `mod_php73` package connecting the PHP processor to Apache HTTP, since it is no longer necessary and will interfere if it remains on the system:

    sudo pkg remove -y mod_php73

Make sure the configuration is correct by running the following command to test:

    sudo apachectl configtest

If you see `Syntax OK` in your output, you can restart the Apache HTTP server:

    sudo apachectl restart

**Note:** If there are other running HTTP connections on your server a [graceful restart](https://httpd.apache.org/docs/2.4/stopping.html) is recommended instead of a regular restart. This will ensure that users are not pushed out, losing their connection:

    sudo apachectl graceful

You’ve switched the MPM from pre-fork to event and removed the `mod_php73` module connection PHP to Apache HTTP. In the next step you’ll install the PHP-FPM module and configure Apache HTTP so that it can communicate with PHP more quickly.

## Step 2 — Configuring Apache HTTP to Use the FastCGI Process Manager

FreeBSD has several supported versions of PHP that you can install via the package manager. On FreeBSD different binaries of the various available versions are compiled instead of using just one like most GNU/Linux distributions offer in their default repositories. To follow best practice you’ll use the supported version, which you can check on at [PHP’s supported versions page](https://www.php.net/supported-versions.php).

In this step you’ll add PHP-FPM as a running service to start at boot. You’ll also configure Apache HTTP to work with PHP by adding a dedicated configuration for the module as well as enabling some further modules in `httpd.conf`.

First you’ll append `'php_fpm_enable=YES'` to the `/etc/rc.conf` file so the PHP-FPM service can start. You’ll do that by using the `sysrc` command:

    sudo sysrc php_fpm_enable="YES"

Now you’ll add the `php-fpm` module into the Apache module’s directory, so it is configured to be used by Apache HTTP. Create the following file to do so:

    sudo vi /usr/local/etc/apache24/modules.d/030_php-fpm.conf

Add the following into `030_php-fpm.conf`:

/usr/local/etc/apache24/modules.d/030\_php-fpm.conf

    <IfModule proxy_fcgi_module>
        <IfModule dir_module>
            DirectoryIndex index.php
        </IfModule>
        <FilesMatch "\.(php|phtml|inc)$">
            SetHandler "proxy:fcgi://127.0.0.1:9000"
        </FilesMatch>
    </IfModule>

This states that if the module `'proxy_fcgi'` is enabled as well as the `'dir_module'` then any processed files matching the extensions in parentheses should be handled by the FastCGI process manager running on the local machine through port `9000`—as if the local machine were a proxy server. This is where the PHP-FPM module and Apache HTTP interconnect. To achieve this, you’ll activate further modules during this step.

To enable the proxy module, you’ll first search for it in the `httpd.conf` file:

    nl -ba /usr/local/etc/apache24/httpd.conf | grep mod_proxy.so

You’ll see output similar to the following:

    Output...
    129 #LoadModule proxy_module libexec/apache24/mod_proxy.so
    ...

You’ll uncomment the line by removing the `#` symbol:

    sudo vi +129 /usr/local/etc/apache24/httpd.conf

The line will look as follows once edited:

/usr/local/etc/apache24/httpd.conf

    ...
    LoadModule proxy_module libexec/apache24/mod_proxy.so
    ...

Now you can activate the FastCGI module. Find the module with the following command:

    nl -ba /usr/local/etc/apache24/httpd.conf | grep mod_proxy_fcgi.so

You’ll see something similar to the following:

    Output...
    133 #LoadModule proxy_fcgi_module libexec/apache24/mod_proxy_fcgi.so
    ...

Now uncomment the line 133 as you’ve already done with the other modules:

    sudo vi +133 /usr/local/etc/apache24/httpd.conf

You’ll leave the line as follows:

/usr/local/etc/apache24/httpd.conf

    ...
    LoadModule proxy_fcgi_module libexec/apache24/mod_proxy_fcgi.so
    ...

Once this is done you’ll start the PHP-FPM service:

    sudo service php-fpm start

And you’ll restart Apache so it loads the latest configuration changes incorporating the PHP module:

    sudo apachectl restart

You’ve installed the PHP-FPM module, configured Apache HTTP to work with it, enabled the necessary modules for the FastCGI protocol to work, and started the corresponding services.

Now that Apache has the Event MPM module enabled and PHP-FPM is present and running, it is time to check everything is working as intended.

## Step 3 — Checking Your Configuration

In order to check that the configuration changes have been applied you’ll run some tests. The first one will check what multi-processing module Apache HTTP is using. The second will verify that PHP is using the FPM manager.

Check the Apache HTTP server by running the following command:

    sudo apachectl -M | grep 'mpm'

Your output will be as follows:

    Outputmpm_event_module (shared)

You can repeat the same for the proxy module and FastCGI:

    sudo apachectl -M | grep 'proxy'

The output will show:

    Outputproxy_module (shared)
    proxy_fcgi_module (shared)

If you would like to see the entire list of the modules, you can remove the the second part of the command after `-M`.

It is now time to check if PHP is using the FastCGI Process Manager. To do so you’ll write a very small PHP script that will show you all the information related to PHP.

Run the following command to write a file named as follows:

    sudo vi /usr/local/www/apache24/data/info.php

Add the following content into the info.php file:

info.php

    <?php phpinfo(); ?>

Now visit your server’s URL and append `info.php` at the end like so: `http://your_server_IP_address/info.php`.

The Server API entry will be **FPM/FastCGI**.

![PHP Screen the Server API entry FPM/FastCGI](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/MPMEvent/FastCGIPHP.png)

Remember to delete the `info.php` file after this check so no information about the server is publicly disclosed.

    sudo rm /usr/local/www/apache24/data/info.php

You’ve checked the working status of the MPM module, the modules handling the FastCGI, and the handling of PHP code.

## Conclusion

You’ve optimized your original FAMP stack, so the number of connections to create new Apache HTTP processes has increased, PHP-FPM will handle PHP code more efficiently, and overall resource utilization has improved.

See the Apache HTTP server project [documentation](http://httpd.apache.org/) for more information on the different modules and related projects.
