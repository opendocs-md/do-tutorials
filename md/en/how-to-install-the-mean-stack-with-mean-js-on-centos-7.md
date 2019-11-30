---
author: finid
date: 2016-09-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-mean-stack-with-mean-js-on-centos-7
---

# How To Install the MEAN Stack with MEAN.JS on CentOS 7

## Introduction

MEAN is a software application stack made up of the following components:

- **MongoDB** , a NoSQL database with support for server-side JavaScript execution

- **ExpressJS** , a Node.js web application framework

- **AngularJS** , a web application framework suitable for developing dynamic, single-page applications

- **NodeJS** , an asynchronous event driven framework suitable for building scalable network applications

The term MEAN was first coined by Valeri Karpov, and the term was derived from the first letter of each component. Valeri defined MEAN in [this blog post](http://blog.mongodb.org/post/49262866911/the-mean-stack-mongodb-expressjs-angularjs-andhttp://blog.mongodb.org/post/49262866911/the-mean-stack-mongodb-expressjs-angularjs-and), in which he gave the some motivations for choosing to develop JavaScript applications with the aid of the MEAN stack:

> By coding with Javascript throughout, we are able to realize performance gains in both the software itself and in the productivity of our developers. With MongoDB, we can store our documents in a JSON-­like format, write JSON queries on our ExpressJS and NodeJS based server, and seamlessly pass JSON documents to our AngularJS frontend. Debugging and database administration become a lot easier when the objects stored in your database are essentially identical to the objects your client Javascript sees. Even better, somebody working on the client side can easily understand the server side code and database queries; using the same syntax and objects the whole way through frees you from having to consider multiple sets of language best practices and reduces the barrier to entry for understanding your codebase.

There are currently two parallel implementations of the MEAN stack: **MEAN.io** and **MEAN.JS**. Each has a slightly different method of installation. MEAN.JS is a purely community-driven implementation, while MEAN.io is sponsored by a company called Linnovate. They both include the same components, but MEAN.io provides an additional command line tool, `mean`, as well as commercial support.

In this guide, we will install a MEAN stack on a CentOS 7 server using MEAN.JS. Using this method involves first installing MongoDB, then NodeJS, then cloning the MEAN.JS files from GitHub.

## Prerequisites

To begin, you’ll need to have the following:

- A CentOS 7 server with at least 4GB of RAM. Some of the components of the MEAN stack, like `npm`, require a lot of memory.

- A sudo non-root user configured using [this CentOS 7 initial server setup guide](initial-server-setup-with-centos-7).

## Step 1 — Installing Dependencies

Because we’ll be compiling applications from source, cloning a Git repository, and installing Ruby gems, we’ll need to install some dependencies first. `libpng-devel` and `fontconfig` are needed by one of the MEAN.JS modules (pngquant).

    sudo yum install gcc-c++ make git fontconfig bzip2 libpng-devel ruby ruby-devel

Some of the Node.js modules that we’ll be installing will require Sass, a CSS extension language. Install it using `gem`, Ruby’s package manager.

    sudo gem install sass

Now that the dependencies are installed, we can install the first component of the stack: MongoDB.

## Step 2 — Installing MongoDB

MongoDB is not in the official CentOS repository, so to install it, you’ll have to enable the official MongoDB repository. This will give you access to the latest packages and allow you to install it from there.

For this tutorial, we’ll be installing the community edition, which is available for free download. There’s also an Enterprise edition, but that requires a license, so we won’t be dealing with it here.

At time of publication, MongoDB 3.2 is the latest stable edition available for download and installation. To enable the repository, create a file for it under `/etc/yum.repos.d`, the CentOS repository directory. For MongoDB 3.2, we’ll call that file `mongodb.org-3.2.repo`.

Create and open `/etc/yum.repos.d/mongodb.org-3.2.repo` using `vi` or your favorite text editor.

    sudo vi /etc/yum.repos.d/mongodb.org-3.2.repo

To point the package manager to the official MongoDB repository and enable it, copy and paste the following into the file. Setting `enabled=1` enables the repository and setting `gpgcheck=1` turns on GNU Privacy Guard (GPG) signature checking on all packages installed from the repository.

/etc/yum.repos.d/mongodb.org-3.2.repo

    [mongodb-org-3.2]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc

Save and close the file, then install the `mongodb-org` package to install MongoDB and its related tools. When prompted to import the GPG key, type `y` for yes:

    sudo yum install mongodb-org

After installation has completed, start the MongoDB daemon.

    sudo systemctl start mongod

`mongod`, the MongoDB daemon, should now be running, and you can verify that using the following command:

    sudo systemctl status mongod

If it’s running, the output should look similar to the following:

    Outputmongod.service - SYSV: Mongo is a scalable, document-oriented database.
       Loaded: loaded (/etc/rc.d/init.d/mongod)
       Active: active (running) since Tue 2016-09-06 12:42:16 UTC; 9s ago
         Docs: man:systemd-sysv-generator(8)
      Process: 9374 ExecStart=/etc/rc.d/init.d/mongod start (code=exited, status=0/SUCCESS)
       CGroup: /system.slice/mongod.service
               └─9385 /usr/bin/mongod -f /etc/mongod.conf
    
    Sep 06 12:42:16 centos-mean-js systemd[1]: Starting SYSV: Mongo is a scalable, document-oriented database....
    Sep 06 12:42:16 centos-mean-js runuser[9381]: pam_unix(runuser:session): session opened for user mongod by (uid=0)
    Sep 06 12:42:16 centos-mean-js mongod[9374]: Starting mongod: [OK]
    Sep 06 12:42:16 centos-mean-js systemd[1]: Started SYSV: Mongo is a scalable, document-oriented database..

The next part of the stack we need to install is Node.js.

## Step 3 — Installing Node.js

One easy way to install Node.js is using the binary from the [NodeSource](https://nodesource.com/) Node.js repository. First, add the repository of the stable branch. You can read the contents of the script before executing it using the command below by visiting the URL in your browser.

    curl -sL https://rpm.nodesource.com/setup_4.x | sudo -E bash -

Next, install Node.js and `npm`, a package manager for Node.js.

    sudo yum install -y nodejs

Verify that Node.js and `npm` are installed.

    npm version

The output should be:

    Output{ npm: '2.15.9',
      ares: '1.10.1-DEV',
      http_parser: '2.7.0',
      icu: '56.1',
      modules: '46',
      node: '4.5.0',
      openssl: '1.0.2h',
      uv: '1.9.1',
      v8: '4.5.103.37',
      zlib: '1.2.8' }

Now that `npm` is installed, we can install the rest of the components of the MEAN stack.

## Step 4 — Installing Bower and Gulp

The components we’ll be installing in this step are Bower, a package manager which is used to manage front-end application, and Gulp, which is used to automate common tasks.

Both Bower and Gulp need to be installed globally, which we accomplish by passing the **g** option to `npm`. Installing both applications globally makes them available system-wide, rather than just from the local project’s directory.

First install Bower:

    sudo npm install -g bower

Then install Gulp:

    sudo npm install -g gulp

Now, we finally have all of the prerequisite packages installed. We can move onto installing the actual MEAN.JS boilerplate used to create applications.

## Step 5 — Installing the MEAN Boilerplate

First, we will clone the official MEAN.JS GitHub repository.

    git clone https://github.com/meanjs/mean.git meanjs

That clones the MEAN.JS boilerplate into a directory called `meanjs` in your home directory. To install all of the packages the project references, you need to be inside that directory, so move into it.

    cd ~/meanjs

Then install the required packages as the non-root user.

    npm install

The installation will take several minutes. When it completes, you have everything you need to develop a MEAN application. In the last step, we’ll test the stack to make sure it works.

## Step 6 — Running Your Sample MEAN Application

Let’s run the sample application to make sure that the system is functioning correctly. One method is to use `npm start`, and the other method is to use `gulp`. Both commands allow you to test your application in development mode. Here, we’ll use `npm`.

    npm start

**Note** : The initial run of either of these commands may fail with output similar to this:

    Error output[12:56:49] 'lint' errored after 702 ms
    [12:56:49] Error in plugin 'run-sequence'
    Message:
        An error occured in task 'sass'.

If you get this error, the fix is simple. It involves deleting the `node_modules` directory, clearing the cache, then reinstalling the packages.

    rm -rf node_modules
    npm cache clean
    npm install

Then restart the sample app with `npm start` or `gulp` as before.

You may now access your MEAN application by visiting `http://your_server_ip:3000` in your favorite browser. That should render a page with the MEAN.JS logo, including the text **Congrats! You’ve configured and run the sample application.** This means you have a fully functional MEAN stack on your server.

## Conclusion

Now that you have the necessary components and the MEAN.JS boilerplate, you can begin building, testing and deploying your own apps. Check out the [documentation on MEAN.JS website](http://meanjs.org/docs.html) for specific help on working with MEAN.JS.
