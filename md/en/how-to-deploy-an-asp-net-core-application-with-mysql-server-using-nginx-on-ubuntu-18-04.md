---
author: Oluyemi Olususi
date: 2019-07-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-an-asp-net-core-application-with-mysql-server-using-nginx-on-ubuntu-18-04
---

# How To Deploy an ASP.NET Core Application with MySQL Server Using Nginx on Ubuntu 18.04

_The author selected the [Open Source Initiative](https://www.brightfunds.org/organizations/open-source-initiative) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[ASP.NET Core](https://dotnet.microsoft.com/learn/web/what-is-aspnet-core) is a high-performant, open-source framework for building modern web applications, meant to be a more modular version of [Microsoft’s ASP.NET Framework](https://dotnet.microsoft.com/apps/aspnet). Released in 2016, it can run on several operating systems such as Linux and macOS. This enables developers to target a particular operating system for development based on design requirements. With ASP.NET Core, a developer can build any kind of web application or service irrespective of the complexity and size. Developers can also make use of [Razor pages](https://docs.microsoft.com/en-us/aspnet/core/razor-pages/?view=aspnetcore-2.2&tabs=visual-studio) to create page-focused design working on top of the traditional [Model-View-Controller](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) (MVC) pattern.

ASP.NET Core provides the flexibility to integrate with any front-end frameworks to handle client-side logic or consume a web service. You could, for example, build a RESTful API with ASP.NET Core and easily consume it with JavaScript frameworks such as Angular, React, and Vue.js.

In this tutorial you’ll set up and deploy a production-ready ASP.NET Core application with a MySQL Server on Ubuntu 18.04 using Nginx. You will deploy a demo ASP.NET Core application similar to the application from Microsoft’s documentation and hosted on [GitHub](https://github.com/aspnet/AspNetCore.Docs/tree/master/aspnetcore/tutorials/razor-pages/razor-pages-start/2.2-stage-samples). Once deployed, the demo application will allow you to create a list of movies and store it in the database. You’ll be able to create, read, update, and delete records from the database. You can use this tutorial to deploy your own ASP.NET Core application instead; it’s possible you’ll have to implement extra steps that include generating a new migration file for your database.

## Prerequisites

You will need the following for this tutorial:

- One Ubuntu 18.04 server set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a non-root user with `sudo` access and a firewall.
- Nginx installed by following [How To Install Nginx on Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04).
- A secured Nginx web server. You can follow this tutorial on [How To Secure Nginx with Let’s Encrypt on Ubuntu 18.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04).
- Both of the following DNS records set up for your server. You can follow this [introduction to DigitalOcean DNS](https://www.digitalocean.com/docs/networking/dns/) for details on how to add them.
  - An `A` record with `your-domain` pointing to your server’s public IP address.
  - An `A` record with `www.your-domain` pointing to your server’s public IP address.
- MySQL installed by following [How To Install the Latest MySQL on Ubuntu 18.04](how-to-install-the-latest-mysql-on-ubuntu-18-04).

## Step 1 — Installing .NET Core Runtime

A .NET Core runtime is required to successfully run a .NET Core application, so you’ll start by installing this to your machine. First, you need to register the Microsoft Key and product repository. After that, you will install the required dependencies.

First, logged in as your new created user, make sure you’re in your root directory:

    cd ~

Next, run the following command to register the Microsoft key and product repository:

    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

Use `dpkg` with the `-i` flag to install the specified file:

    sudo dpkg -i packages-microsoft-prod.deb

To facilitate the installation of other packages required for your application, you will install the `universe` repository with the following command:

    sudo add-apt-repository universe

Next install the `apt-transport` package to allow the use of repositories accessed via the HTTP Secure protocol:

    sudo apt install apt-transport-https

Now, run the following command to download the packages list from the repositories and update them to get information on the newest versions of packages and their dependencies:

    sudo apt update

Finally, you can install the .NET runtime SDK with:

    sudo apt install dotnet-sdk-2.2

You will be prompted with the details of the size of additional files that will be installed. Type `Y` and hit `ENTER` to continue.

Now that you’re done installing the .NET Core runtime SDK on the server, you are almost ready to download the demo application from GitHub and set up the deployment configuration. But first, you’ll create the database for the application.

## Step 2 — Creating a MySQL User and Database

In this section, you will create a MySQL server user, create a database for the application, and grant all the necessary privileges for the new user to connect to the database from your application.

To begin, you need to access the MySQL client using the MySQL root account as shown here:

    mysql -u root -p

You will be prompted to enter the root account password, set up during the prerequisite tutorial.

Next, create a MySQL database for the application with:

    CREATE DATABASE MovieAppDb;

You will see the following output in the console:

    OutputQuery OK, 1 row affected (0.03 sec)

You’ve now created the database successfully. Next, you will create a new MySQL user, associate them with the newly created database, and grant them all privileges.

Run the following command to create the MySQL user and password. Remember to change the username and password to something more secure:

    CREATE USER 'movie-admin'@'localhost' IDENTIFIED BY 'password';

You will see the following output:

    OutputQuery OK, 0 rows affected (0.02 sec)

To access a database or carry out a specific action on it, a MySQL user needs the appropriate permission. At the moment **movie-admin** does not have the appropriate permission over the application database.

You will change that by running the following command to grant access to **movie-admin** on `MovieAppDb`:

    GRANT ALL PRIVILEGES ON MovieAppDb.* TO 'movie-admin'@'localhost';

You will see the following output:

    OutputQuery OK, 0 rows affected (0.01 sec)

Now, you can reload the grant tables by running the following command to apply the changes that you just made using the flush statement:

    FLUSH PRIVILEGES;

You will see the following output:

    OutputQuery OK, 0 rows affected (0.00 sec)

You are done creating a new user and granting privileges. To test if you are on track, exit the MySQL client:

    quit;

Log in again, using the credentials of the MySQL user you just created and enter the appropriate password when prompted:

    mysql -u movie-admin -p

Check to be sure that the user **movie-admin** can access the created database, check with:

    SHOW DATABASES;

You will see the `MovieAppDb` table listed in the output:

    Output+--------------------+
    | Database |
    +--------------------+
    | MovieAppDb |
    | information_schema |
    +--------------------+
    2 rows in set (0.01 sec)

Now, exit the MySQL client:

    quit;

You’ve created a database, made a new MySQL user for the demo application, and granted the newly created user the right privileges to access the database. In the next section, you will start setting up the demo application.

## Step 3 — Setting Up the Demo App and Database Credentials

As stated earlier, you’ll deploy an existing ASP.NET Core application. This application was built to create a movie list and it uses the Model-View-Controller design pattern to ensure a proper structure and separation of concerns. To create or add a new movie to the list, the user will populate the form fields with the appropriate details and click on the **Create** button to post the details to the controller. The controller at this point will receive a POST HTTP request with the submitted details and persist the data in the database through the model.

You will use [Git](https://git-scm.com/) to pull the source code of this demo application from [GitHub](https://github.com/do-community/movie-app-list) and save it in a new directory. You could also download an alternate application here if you will be deploying a different application.

To begin, create a new directory named `movie-app` from the terminal by using the following command:

    sudo mkdir -p /var/www/movie-app

This will serve as the root directory for your application. Next, change the folder owner and group in order to allow a non-root user account to work with the project files:

    sudo chown sammy:sammy /var/www/movie-app

Replace **sammy** with your sudo non-root username.

Now, you can move into the parent directory and clone the application on GitHub:

    cd /var/www
    git clone https://github.com/do-community/movie-app-list.git movie-app

You will see the following output:

    OutputCloning into 'movie-app'...
    remote: Enumerating objects: 91, done.
    remote: Counting objects: 100% (91/91), done.
    remote: Compressing objects: 100% (73/73), done.
    remote: Total 91 (delta 13), reused 91 (delta 13), pack-reused 0
    Unpacking objects: 100% (91/91), done.

You have successfully cloned the demo application from GitHub, so the next step will be to create a successful connection to the application database. You will do this by editing the `ConnectionStrings` property within the `appsettings.json` file and add the details of the database.

Change directory into the application:

    cd movie-app

Now open the file for editing:

    sudo nano appsettings.json

Add your database credentials:

appsettings.json

    {
      "Logging": {
        "LogLevel": {
          "Default": "Warning"
        }
      },
      "AllowedHosts": "*",
      "ConnectionStrings": {
        "MovieContext": "Server=localhost;User Id=movie-admin;Password=password;Database=MovieAppDb"
      }
    }

With this in place, you’ve successfully created a connection to your database. Now press `CTRL+X` to save your changes to the file and type `Y` to confirm. Then hit `ENTER` to exit the page.

ASP.NET Core applications use a .NET standard library named [Entity Framework](https://docs.microsoft.com/en-us/ef/) (EF) Core to manage interaction with the database. [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/) is a lightweight, cross-platform version of the popular Entity Framework data access technology. It is an object-relational mapper (ORM) that enables .NET developers to work with a database using any of the database providers, such as MySQL.

You can now update your database with the tables from the cloned demo application. Run the following command for that purpose:

    dotnet ef database update

This will apply an update to the database and create the appropriate schemas.

Now, to build the project and all its dependencies, run the following command:

    dotnet build

You will see output similar to:

    OutputMicrosoft (R) Build Engine version 16.1.76+g14b0a930a7 for .NET Core
    Copyright (C) Microsoft Corporation. All rights reserved.
    
      Restore completed in 95.09 ms for /var/www/movie-app/MvcMovie.csproj.
      MvcMovie -> /var/www/movie-app/bin/Debug/netcoreapp2.2/MvcMovie.dll
      MvcMovie -> /var/www/movie-app/bin/Debug/netcoreapp2.2/MvcMovie.Views.dll
    
    Build succeeded.
        0 Warning(s)
        0 Error(s)
    
    Time Elapsed 00:00:01.91

This will build the project and install any third-party dependencies listed in the `project.assets.json` file but the application won’t be ready for production yet. To get the application ready for deployment, run the following command:

    dotnet publish

You will see the following:

    OutputMicrosoft (R) Build Engine version 16.1.76+g14b0a930a7 for .NET Core
    Copyright (C) Microsoft Corporation. All rights reserved.
    
    Restore completed in 89.62 ms for /var/www/movie-app/MvcMovie.csproj.
    MvcMovie -> /var/www/movie-app/bin/Debug/netcoreapp2.2/MvcMovie.dll
    MvcMovie -> /var/www/movie-app/bin/Debug/netcoreapp2.2/MvcMovie.Views.dll
    MvcMovie -> /var/www/movie-app/bin/Debug/netcoreapp2.2/publish/

This will pack and compile the application, read through its dependencies, publish the resulting set of files into a folder for deployment, and produce a cross-platform `.dll` file that uses the installed .NET Core runtime to run the application.

By installing dependencies, creating a connection to the database, updating the database with the necessary tables, and publishing it for production, you’ve completed the setup for this demo application. In the next step you will configure the web server to make the application accessible and secure at your domain.

## Step 4 — Configuring the Web Server

By now, having followed the [How To Secure Nginx with Let’s Encrypt tutorial](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04), you’ll have a server block for your domain at `/etc/nginx/sites-available/your_domain` with the `server_name` directive already set appropriately. In this step, you will edit this server block to configure Nginx as a reverse proxy for your application. A reverse proxy is a server that sits in front of web servers and forwards every web browser’s request to those web servers. It receives all requests from the network and forwards them to a different web server.

In the case of an ASP.NET Core application, [Kestrel](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel?view=aspnetcore-2.2) is the preferred web server that is included with it by default. It is great for serving dynamic content from an ASP.NET Core application as it provides better request-processing performance and was designed to make ASP.NET as fast as possible. However, Kestrel isn’t considered a full-featured web server because it can’t manage security and serve static files, which is why it is advisable to always run it behind a web server.

To begin, ensure that you are within the root directory of your server:

    cd ~

Open the server block for editing with:

    sudo nano /etc/nginx/sites-available/your_domain

As detailed in the [Step 4](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04#step-4-%E2%80%94-obtaining-an-ssl-certificate) of the [How To Secure Nginx with Let’s Encrypt tutorial](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04), if you selected option 2, Certbot will automatically configure this server block in order to redirect HTTP traffic to HTTPS with just a few modifications.

Continue with the configuration by editing the first two blocks in the file to reflect the following:

 /etc/nginx/sites-available/your-domain

    server {
    
        server_name your-domain www.your-domain;
    
       location / {
         proxy_pass http://localhost:5000;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection keep-alive;
         proxy_set_header Host $host;
         proxy_cache_bypass $http_upgrade;
         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
         proxy_set_header X-Forwarded-Proto $scheme;
        }
    
    listen [::]:443 ssl ipv6only=on; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/your-domain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/your-domain/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
    
    
    }
    ...

The configuration in this server block will instruct Nginx to listen on port `443`, which is the standard port for websites that use SSL. Furthermore, Nginx will accept public traffic on port `443` and forward every matching request to the built-in Kestrel server at `http://localhost:5000`.

Finally, following the server block you just edited in the file, ensure that the second server block looks like so:

 /etc/nginx/sites-available/your-domain

    
    ...
    server {
    if ($host = www.your-domain) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    
    if ($host = your-domain) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    
        listen 80;
        listen [::]:80;
    
        server_name your-domain www.your-domain;
    return 404; # managed by Certbot
    }

This server block will redirect all requests to `https://your-domain` and `https://www.your-domain` to a secure HTTPS access.

Next, force Nginx to pick up the changes you’ve made to the server block by running:

    sudo nginx -s reload

With the Nginx configuration successfully completed, the server is fully set up to forward all HTTPS requests made to `https://your-domain` on to the ASP.NET Core app running on Kestrel at `http://localhost:5000`. However, Nginx isn’t set up to manage the Kestrel server process. To handle this and ensure that the Kestrel process keeps running in the background, you will use `systemd` functionalities.

[Systemd](understanding-systemd-units-and-unit-files) files will allow you to manage a process by providing start, stop, restart, and log functionalities once you create a process of work called a unit.

Move into the `systemd` directory:

    cd /etc/systemd/systems

Create a new file for editing:

    sudo nano movie.service

Add the following content to it:

movie.service

    [Unit]
    Description=Movie app
    
    [Service]
    WorkingDirectory=/var/www/movie-app
    ExecStart=/usr/bin/dotnet /var/www/movie-app/bin/Debug/netcoreapp2.2/publish/MvcMovie.dll
    Restart=always
    RestartSec=10
    SyslogIdentifier=movie
    User=sammy
    Environment=ASPNETCORE_ENVIRONMENT=Production
    Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
    
    [Install]
    WantedBy=multi-user.target

The configuration file specifies the location of the project’s folder with `WorkingDirectory` and the command to execute at the start of the process in `ExecStart`. In addition, you’ve used the `RestartSec` directive to specify when to restart the `systemd` service if the .NET runtime service crashes.

Now save the file and enable the new movie service created with:

    sudo systemctl enable movie.service

After that, proceed to start the service and verify that it’s running by starting the service:

    sudo systemctl start movie.service

Then check its status:

    sudo systemctl status movie.service

You will see the following output:

    Outputmovie.service - Movie app
       Loaded: loaded (/etc/systemd/system/movie.service; enabled; vendor preset: enabled)
       Active: active (running) since Sun 2019-06-23 04:51:28 UTC; 11s ago
     Main PID: 6038 (dotnet)
        Tasks: 16 (limit: 1152)
       CGroup: /system.slice/movie.service
               └─6038 /usr/bin/dotnet /var/www/movie-app/bin/Debug/netcoreapp2.2/publish/MvcMovie.dll
    

This output gives you an overview of the current status of the `movie.service` created to keep your app running. It indicates that the service is enabled and currently active.

Navigate to `https://your-domain` from your browser to run and test out the application.

You’ll see the home page for the demo application— **Movie List Application**.

![Movie list application](https://i.imgur.com/VI7KTaU.png)

With the reverse proxy configured and Kestrel managed through systemd, the web app is fully configured and can be accessed from a browser.

## Conclusion

In this tutorial, you deployed an ASP.NET Core application to an Ubuntu server. To persist and manage data, you installed and used MySQL server and used the Nginx web server as a reverse proxy to serve your application.

Beyond this tutorial, if you’re interested in building an interactive web application using C# instead of Javascript you could try a web UI framework by Microsoft called [Blazor](https://dotnet.microsoft.com/apps/aspnet/web-apps/client). It is an event-driven component-based web UI for implementing logic on the client side of an ASP.NET Core application.

If you wish to deploy your own application, you’ll need to consider other required procedures to deploy your app. The complete source code for this demo application can be found [here on GitHub](https://github.com/do-community/movie-app-list).
