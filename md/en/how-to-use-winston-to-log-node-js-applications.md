---
author: Steve Milburn
date: 2018-03-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-winston-to-log-node-js-applications
---

# How To Use Winston to Log Node.js Applications

## Introduction

An effective logging solution is crucial to the success of any application. In this guide we’ll focus on a logging package called [Winston](https://www.npmjs.com/package/winston), an extremely versatile logging library and the most popular logging solution available for [Node.js](https://nodejs.org) applications, based on NPM download statistics. Winston’s features include support for multiple storage options and log levels, log queries, and even a built-in profiler. This tutorial will show you how to use Winston to log a Node/[Express](http://expressjs.com/) application that we’ll create as part of this process. We’ll also look at how we can combine Winston with another popular HTTP request middleware logger for Node.js called [Morgan](https://www.npmjs.com/package/morgan) to consolidate HTTP request data logs with other information.

After completing this tutorial you will have an Ubuntu server running a small Node/Express application. You will also have Winston implemented to log errors and messages to a file and the console.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 16.04 server set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

- Node.js installed using the official PPA, as explained in [How To Install Node.js on Ubuntu 16.04](how-to-install-node-js-on-ubuntu-16-04).

With these prerequisites in place, we can build our application and install Winston.

## Step 1 — Creating a Basic Node/Express App

A common use for Winston is logging events from web applications built with Node.js. In order to fully demonstrate how to incorporate Winston we will create a simple Node.js web application using the Express framework. To help us get a basic web application running we will use [`express-generator`](https://www.npmjs.com/package/express-generator), a command-line tool for getting a Node/Express web application running quickly. Because we installed the [Node Package Manager](https://www.npmjs.org) as part of our prerequisites, we will be able to use the `npm` command to install `express-generator`. We will also use the `-g` flag, which installs the package globally so it can used as a command line tool outside of an existing Node project/module. Install the package with the following command:

    sudo npm install express-generator -g

With `express-generator` installed, we can create our app using the `express` command, followed by the name of the directory we want to use for our project. This will create our application with everything we need to get started:

    express myApp

Next, install [Nodemon](https://www.npmjs.com/package/nodemon), which will automatically reload the application whenever we make any changes. A Node.js application needs to be restarted any time changes are made to the source code in order for those changes to take effect. Nodemon will automatically watch for changes and restart the application for us. And since we want to be able to use `nodemon` as a command-line tool we will install it with the `-g` flag:

    sudo npm install nodemon -g

To finish setting up the application, change to the application directory and install dependencies as follows:

    cd myApp
    npm install

By default, applications created with `express-generator` run on port 3000, so we need to make sure that port is not blocked by the firewall. To open port 3000, run the following command:

    sudo ufw allow 3000

We now have everything we need to start our web application. To do so, run the following command:

    nodemon bin/www

This starts the application running on port 3000. We can test that it’s working by going to `http://your_server_ip:3000` in a web browser. You should see something like this:

![Default express-generator homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/winston_logging_nodejs/winston_log_image_one.png)

It’s a good idea at this point to start a second SSH session to your server to use for the remainder of this tutorial, leaving the web application we just started running in the original session. For the rest of this article, we’ll refer to the SSH session we’ve been using so far and that is currently running the application as Session A. We will use the new SSH session for running commands and editing files, and we’ll refer to this session as Session B. Unless otherwise noted, all remaining commands should be run in Session B.

## Step 2 - Customizing the Node.js Application

The default application created by `express-generator` does a great job at getting us started, and it even includes the Morgan HTTP logging middleware we’ll be using to log data about all HTTP requests. And since Morgan supports output streams, it makes a nice pairing with the stream support built into Winston, enabling us to consolidate HTTP request data logs with anything else we choose to log with Winston.

By default, the `express-generator` boilerplate uses the variable **logger** when referencing the `morgan` package. Since we will be using `morgan` and `winston`, which are both logging packages, it can be confusing to call either one of them **logger**. So let’s change that by editing the `app.js` file in the root of the project and making some changes.

To open `app.js` for editing, use the `nano` command:

    nano ~/myApp/app.js

Find the following line near the top of the file:

~/myApp/app.js

    ...
    var logger = require('morgan');
    ...

Change it to the following:

~/myApp/app.js

    ...
    var morgan = require('morgan');
    ...

We also need to find where the variable **logger** was referenced in the file and change it to `morgan`. While we are at it, let’s change the log format used by the `morgan` package to `combined`, which is the standard Apache log format and will include useful information in the logs such as remote IP address and the user-agent HTTP request header.

To do so, find the following line:

~/myApp/app.js

    ...
    app.use(logger('dev'));
    ...

Change it to the following:

~/myApp/app.js

    ...
    app.use(morgan('combined'));
    ...

These changes will help us better understand which logging package we are referencing at any given time after we integrate our Winston configuration.

Exit and save the file by typing `CTRL-X`, then `Y`, and then `ENTER`.

Now that our app is set up we are ready to start working with Winston.

## Step 3 — Installing and Configuring Winston

We are now ready to install and configure Winston. In this step we will explore some of the configuration options that are available as part of the `winston` package and create a logger that will log information to a file and the console.

To install `winston` run the following command:

    cd ~/myApp
    npm install winston

It’s often useful to keep any type of support or utility configuration files for our applications in a special directory, so let’s create a `config` folder that will contain the `winston` configuration:

    mkdir ~/myApp/config

Now let’s create the file that will contain our `winston` configuration, which we’ll call `winston.js`:

    touch ~/myApp/config/winston.js

Next, create a folder that will contain your log files:

    mkdir ~/myApp/logs

Finally, let’s install `app-root-path`, a package that is useful when specifying paths in Node.js. This package is not directly related to Winston, but helps immensely when specifying paths to files in Node.js code. We’ll use it to specify the location of the Winston log files from the root of the project and avoid ugly relative path syntax:

    npm install app-root-path --save

Everything we need to configure how we want to handle our logging is in place, so we can move on to defining our configuration settings. Begin by opening `~/myApp/config/winston.js` for editing:

     nano ~/myApp/config/winston.js

Next, require the `app-root-path` and `winston` packages:

~/myApp/config/winston.js

    var appRoot = require('app-root-path');
    var winston = require('winston');

With these variables in place, we can define the configuration settings for our _transports_. Transports are a concept introduced by Winston that refer to the storage/output mechanisms used for the logs. Winston comes with three core transports - _console_, _file_, and _HTTP_. We will be focusing on the console and file transports for this tutorial: the console transport will log information to the console, and the file transport will log information to a specified file. Each transport definition can contain its own configuration settings such as file size, log levels, and log format. Here is a quick summary of the settings we’ll be using for each transport:

- **level** - Level of messages to log. 
- **filename** - The file to be used to write log data to.
- **handleExceptions** - Catch and log unhandled exceptions.
- **json** - Records log data in JSON format.
- **maxsize** - Max size of log file, in bytes, before a new file will be created.
- **maxFiles** - Limit the number of files created when the size of the logfile is exceeded.
- **colorize** - Colorize the output. This can be helpful when looking at console logs.

_Logging levels_ indicate message priority and are denoted by an integer. Winston uses `npm` logging levels that are prioritized from 0 to 5 (highest to lowest):

- **0** : error
- **1** : warn
- **2** : info
- **3** : verbose
- **4** : debug
- **5** : silly

When specifying a logging level for a particular transport, anything at that level or higher will be logged. For example, by specifying a level of `info`, anything at level `error`, `warn`, or `info` will be logged. Log levels are specified when calling the logger, meaning we can do the following to record an error: `logger.error('test error message')`.

We can define the configuration settings for the `file` and `console` transports in the `winston` configuration as follows:

~/myApp/config/winston.js

    ...
    var options = {
      file: {
        level: 'info',
        filename: `${appRoot}/logs/app.log`,
        handleExceptions: true,
        json: true,
        maxsize: 5242880, // 5MB
        maxFiles: 5,
        colorize: false,
      },
      console: {
        level: 'debug',
        handleExceptions: true,
        json: false,
        colorize: true,
      },
    };

Next, instantiate a new `winston` logger with file and console transports using the properties defined in the `options` variable:

~/myApp/config/winston.js

    ...
    var logger = new winston.Logger({
      transports: [
        new winston.transports.File(options.file),
        new winston.transports.Console(options.console)
      ],
      exitOnError: false, // do not exit on handled exceptions
    });

By default, `morgan` outputs to the console only, so let’s define a stream function that will be able to get `morgan`-generated output into the `winston` log files. We will use the `info` level so the output will be picked up by both transports (file and console):

~/myApp/config/winston.js

    ...
    logger.stream = {
      write: function(message, encoding) {
        logger.info(message);
      },
    };

Finally, export the logger so it can be used in other parts of the application:

~/myApp/config/winston.js

    ...
    module.exports = logger;

The completed `winston` configuration file should look like this:

~/myApp/config/winston.js

    var appRoot = require('app-root-path');
    var winston = require('winston');
    
    // define the custom settings for each transport (file, console)
    var options = {
      file: {
        level: 'info',
        filename: `${appRoot}/logs/app.log`,
        handleExceptions: true,
        json: true,
        maxsize: 5242880, // 5MB
        maxFiles: 5,
        colorize: false,
      },
      console: {
        level: 'debug',
        handleExceptions: true,
        json: false,
        colorize: true,
      },
    };
    
    // instantiate a new Winston Logger with the settings defined above
    var logger = new winston.Logger({
      transports: [
        new winston.transports.File(options.file),
        new winston.transports.Console(options.console)
      ],
      exitOnError: false, // do not exit on handled exceptions
    });
    
    // create a stream object with a 'write' function that will be used by `morgan`
    logger.stream = {
      write: function(message, encoding) {
        // use the 'info' log level so the output will be picked up by both transports (file and console)
        logger.info(message);
      },
    };
    
    module.exports = logger;

Exit and save the file.

We now have our logger configured, but our application is still not aware of it or how to use it. We will now integrate the logger with the application.

## Step 4 — Integrating Winston With Our Application

To get our logger working with the application we need to make `express` aware of it. We already saw in Step 2 that our `express` configuration is located in `app.js`, so let’s import our logger into this file. Open the file for editing by running:

    nano ~/myApp/app.js

Import `winston` near the top of the file with the other require statements:

~/myApp/app.js

    ...
    var winston = require('./config/winston');
    ...

The first place we’ll actually use `winston` is with `morgan`. We will use the `stream` option, and set it to the stream interface we created as part of the `winston` configuration. To do so, find the following line:

~/myApp/app.js

    ...
    app.use(morgan('combined'));
    ...

Change it to this:

~/myApp/app.js

    ...
    app.use(morgan('combined', { stream: winston.stream }));
    ...

Exit and save the file.

We’re ready to see some log data! If you reload the page in the web browser, your should see something similar to the following in the console of SSH Session A:

    Output[nodemon] restarting due to changes...
    [nodemon] starting `node bin/www`
    info: ::ffff:72.80.124.207 - - [07/Mar/2018:17:29:36 +0000] "GET / HTTP/1.1" 304 - "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36"
    
    info: ::ffff:72.80.124.207 - - [07/Mar/2018:17:29:37 +0000] "GET /stylesheets/style.css HTTP/1.1" 304 - "http://167.99.4.120:3000/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36"

There are two log entries here - the first for the request to the HTML page, the second for the accompanied stylesheet. Since each transport is configured to handle `info` level log data, we should also see similar information in the file transport located at `~/myApp/logs/app.log`. The output in the file transport, however, should be written as a JSON object since we specified `json: true` in the file transport configuration. You can learn more about JSON in our [introduction to JSON tutorial](an-introduction-to-json). To view the contents of the log file, run the following command:

    tail ~/myApp/logs/app.log

You should see something similar to the following:

    {"level":"info","message":"::ffff:72.80.124.207 - - [07/Mar/2018:17:29:36 +0000] \"GET / HTTP/1.1\" 304 - \"-\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36\"\n","timestamp":"2018-03-07T17:29:36.962Z"}
    {"level":"info","message":"::ffff:72.80.124.207 - - [07/Mar/2018:17:29:37 +0000] \"GET /stylesheets/style.css HTTP/1.1\" 304 - \"http://167.99.4.120:3000/\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36\"\n","timestamp":"2018-03-07T17:29:37.067Z"}

So far our logger is only recording HTTP requests and related data. This is very important information to have in our logs, but how do we record custom log messages? There will certainly be times that we want this ability for things such as recording errors or profiling database query performance, for example. To illustrate how we can do this, let’s call the logger from the error handler route.

The `express-generator` package includes a 404 and 500 error handler route by default, so we’ll work with that. Open the `~/myApp/app.js` file:

    nano ~/myApp/app.js

Find the code block at the bottom of the file that looks like this:

~/myApp/app.js

    ...
    // error handler
    app.use(function(err, req, res, next) {
      // set locals, only providing error in development
      res.locals.message = err.message;
      res.locals.error = req.app.get('env') === 'development' ? err : {};
    
      // render the error page
      res.status(err.status || 500);
      res.render('error');
    });
    ...

This is the final error handling route that will ultimately send an error response back to the client. Since all server-side errors will be run through this route, this is a good place to include the `winston` logger.

Because we are now dealing with errors, we want to use the `error` log level. Again, both transports are configured to log `error` level messages so we should see the output in the console and file logs. We can include anything we want in the log so be sure to include some useful information like:

- **err.status** - The HTTP error status code. If one is not already present, default to 500.
- **err.message** - Details of the error.
- **req.originalUrl** - The URL that was requested.
- **req.path** - The path part of the request URL.
- **req.method** - HTTP method of the request (GET, POST, PUT, etc.).
- **req.ip** - Remote IP address of the request.

Update the error handler route to match the following:

~/myApp/app.js

    ...
    // error handler
    app.use(function(err, req, res, next) {
      // set locals, only providing error in development
      res.locals.message = err.message;
      res.locals.error = req.app.get('env') === 'development' ? err : {};
    
      // add this line to include winston logging
      winston.error(`${err.status || 500} - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}`);
    
      // render the error page
      res.status(err.status || 500);
      res.render('error');
    });
    ...

Exit and save the file.

To test this, let’s try to access a page in our project that doesn’t exist, which will throw a 404 error. Back in your web browser, attempt to load the following URL: `http://your_server_ip:3000/foo`. The application is already set up to respond to such an error, thanks to the boilerplate created by `express-generator`. Your browser should display an error message that looks like this (your error message may be more detailed than what is shown):

![Browser error message](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/winston_logging_nodejs/winston_log_image_two.png)

Now take another look at the console in SSH Session A. There should be a log entry for the error, and thanks to the colorize setting it should be easy to find.

    Output[nodemon] starting `node bin/www`
    error: 404 - Not Found - /foo - GET - ::ffff:72.80.124.207
    info: ::ffff:72.80.124.207 - - [07/Mar/2018:17:40:11 +0000] "GET /foo HTTP/1.1" 404 985 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36"
    
    info: ::ffff:72.80.124.207 - - [07/Mar/2018:17:40:11 +0000] "GET /stylesheets/style.css HTTP/1.1" 304 - "http://167.99.4.120:3000/foo" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.186 Safari/537.36"

As for the file logger, running the `tail` command again should show us the new log records:

    tail ~/myApp/logs/app.log

You will see a message like the following:

    {"level":"error","message":"404 - Not Found - /foo - GET - ::ffff:72.80.124.207","timestamp":"2018-03-07T17:40:10.622Z"}

The error message includes all the data we specifically instructed `winston` to log as part of the error handler, including the error status (404 - Not Found), the requested URL (localhost/foo), the request method (GET), the IP address making the request, and the timestamp of when the request was made.

## Conclusion

In this tutorial, you built a simple Node.js web application and integrated a Winston logging solution that will function as an effective tool to provide insight into the performance of the application. You can do a lot more to build robust logging solutions for your applications, particularly as your needs become more complex. We recommend that you take the time to look at some of these other documents:

- To learn more about Winston transports, see [Winston Transports Documentation](https://github.com/winstonjs/winston/blob/master/docs/transports.md).
- To learn more about creating your own transports, see [Adding Custom Transports](https://www.npmjs.com/package/winston#adding-custom-transports)
- To create an HTTP endpoint for use with the HTTP core transport, see [`winstond`](https://www.npmjs.com/package/winstond).
- To use Winston as a profiling tool, see [Profiling](https://www.npmjs.com/package/winston#profiling)
