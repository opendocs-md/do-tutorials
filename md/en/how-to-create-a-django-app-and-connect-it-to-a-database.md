---
author: Jeremy Morris
date: 2017-08-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-django-app-and-connect-it-to-a-database
---

# How To Create a Django App and Connect it to a Database

## Introduction

A free and open-source web framework written in Python, Django allows for scalability, re-usability, and rapid development.

In this tutorial, you will learn how to set up the initial foundation for a blog website with connections to a MySQL database. This will involve creating the skeleton structure of the blog web application using `django-admin`, creating the MySQL database and then connecting the web application to the database.

## Prerequisites

This tutorial is the second tutorial in the [Django Development](https://www.digitalocean.com/community/tutorial_series/django-development) series. To follow this tutorial, you should complete the following:

- Install the necessary software to use Django on an Ubuntu 16.04 server. If you haven’t set up a server with sudo privileges or haven’t installed Django yet, you can follow the first tutorial in this series, “[How To Install Django and Set Up a Development Environment on Ubuntu 16.04](how-to-install-django-and-set-up-a-development-environment-on-ubuntu-16-04).”
- Install MySQL before proceeding through this tutorial. If you you don’t have it installed already, you can follow [step 2 of “How To Install the Latest MySQL on Ubuntu 16.04”](how-to-install-the-latest-mysql-on-ubuntu-16-04#step-2-%E2%80%94-installing-mysql), which includes the commands for getting MySQL installed.

With the prerequisites installed and our Django development environment set up, we can move on to creating our app.

## Step 1 — Create the Initial Django Project Skeleton

In order to lay the groundwork for our application, we need to generate the project skeleton using the `django-admin` command. This generated project will be the foundation of our blog app.

The first thing that we need to do is navigate to the home directory, which we can do with the following command:

    cd ~

Next, we can list the contents of our current directory:

    ls

If you’ve started from scratch with the beginning of this series, you will notice that there is one directory:

    Outputdjango-apps

This contains the skeleton project that we generated to verify that everything was installed correctly.

As that was only a test, we won’t need this directory. Instead, we’ll make a new directory for our blog app. Call the directory something meaningful for the app you are building. As an example, we’ll call ours `my_blog_app`.

    mkdir my_blog_app

Now, navigate to the newly created directory:

    cd my_blog_app

Then, create and activate your Python virtual environment.

    python3 -m venv env
    . env/bin/activate

Now install Django:

    pip install django

While in the `my_blog_app` directory, we will generate a project by running the following command:

    django-admin startproject blog

Verify that it worked by navigating to the `blog/` directory:

    cd blog

The `blog/` directory should have been created in the current directory, `~/my_blog_app/`, after running the previous `django-admin` command.

Run `ls` to verify that the necessary items were created. There should be a `blog` directory and a `manage.py` file:

    Outputblog manage.py

Now that you’ve created a project directory containing the initial start of your blog application, we can continue on to the next step.

## Step 2 — Edit Settings

Since we’ve generated the skeleton project, we now have a `settings.py` file.

In order for our blog to have the correct time associated with our area, we will edit the `settings.py` file so that it will be using your current time zone. You can use this [list of time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) as a reference. For our example, we will be using `America/New_York` time.

Now navigate to the directory where the `settings.py` file is located:

    cd ~/my_blog_app/blog/blog/

Then, using nano or a text editor of your choice, open and edit the `settings.py` file:

    nano settings.py

We are editing the `TIME_ZONE` field, so navigate to the bottom section of the file that looks like this:

settings.py

    ...
    # Internationalization
    # https://docs.djangoproject.com/en/2.0/topics/i18n/
    
    LANGUAGE_CODE = 'en-us'
    
    TIME_ZONE = 'UTC'
    
    USE_I18N = True
    
    USE_L10N = True
    
    USE_TZ = True
    ...

We are going to modify the `TIME_ZONE` line so that it is set to your current time zone. We will be using the time zone for New York in this example:

settings.py

    ...
    # Internationalization
    # https://docs.djangoproject.com/en/2.0/topics/i18n/
    
    LANGUAGE_CODE = 'en-us'
    
    TIME_ZONE = 'America/New_York'
    
    USE_I18N = True
    ...

Let’s keep the file open because we need to add a path for our static files. The files that get served from your Django web application are referred to as **static files**. This could include any necessary files to render the complete web page, including JavaScript, CSS, and images.

Go to the end of the `settings.py` file and add `STATIC_ROOT` as shown below:

settings.py

    ...
    # Static files (CSS, JavaScript, Images)
    # https://docs.djangoproject.com/en/2.0/howto/static-files/
    
    STATIC_URL = '/static/'
    STATIC_ROOT = os.path.join(BASE_DIR, 'static')

Now that we’ve added the time zone and the path for static files, we should next add our IP to the list of allowed hosts. Navigate to the line of the `settings.py` file where it says `ALLOWED_HOSTS`, it’ll be towards the top of the `settings.py` file.

settings.py

    ...
    # SECURITY WARNING: don't run with debug turned on in production!
    DEBUG = True
    
    ALLOWED_HOSTS = ['your server IP address']
    
    # Application definition
    ...

Add your server’s IP address between the square brackets and single quotes.

Once you are satisfied with the changes you have made, save the file by pressing `CTRL` + `X` and then `y` to confirm changes.

Great, you’ve successfully edited your `settings.py` file so that the proper time zone has been configured. You’ve also added the path for your static files, and set your `ip address` to be an `ALLOWED_HOST` for your application.

At this point we can go on to setting up our database connection.

## Step 3 — Install MySQL Database Connector

In order to use MySQL with our project, we will need a Python 3 database connector library compatible with Django. So, we will install the database connector, `mysqlclient`, which is a forked version of `MySQLdb`.

According to the `mysqlclient` documentation, “`MySQLdb` is a thread-compatible interface to the popular `MySQL` database server that provides the Python database API.” The main difference being that `mysqlclient` has the added benefit of including Python 3 support.

First thing we will need to do is install `python3-dev`. You can install `python3-dev` by running the following command:

    sudo apt-get install python3-dev

Once `python3-dev` is installed, we can install the necessary Python and MySQL development headers and libraries:

    sudo apt-get install python3-dev libmysqlclient-dev

When you see the following output:

    OutputAfter this operation, 11.9 MB of additional disk space will be used.
    Do you want to continue? [Y/n]

Enter `y` then hit `ENTER` to continue.

Then, we will use `pip3` to install the `mysqlclient` library from `PyPi`. Since our version of `pip` points to `pip3`, we can just use `pip`.

    pip install mysqlclient

You will see output similar to this, verifying that it is installing properly:

    successfully installed mysqlclientCollecting mysqlclient
      Downloading mysqlclient-1.3.12.tar.gz (82kB)
        100% |████████████████████████████████| 92kB 6.7MB/s
    Building wheels for collected packages: mysqlclient
      Running setup.py bdist_wheel for mysqlclient ... done
      Stored in directory: /root/.cache/pip/wheels/32/50/86/c7be3383279812efb2378c7b393567569a8ab1307c75d40c5a
    Successfully built mysqlclient
    Installing collected packages: mysqlclient
    Successfully installed mysqlclient-1.3.12

Now, install `MySQL` server, with the following command:

    sudo apt-get install mysql-server

We have now successfully installed MySQL server and the MySQL client using the PyPi `mysqlclient` connector library.

## Step 4 — Create the Database

Now that the skeleton of your Django application has been set up and `mysqlclient` and `mysql-server` have been installed, we will to need to configure your Django backend for MySQL compatibility.

Verify that the MySQL service is running:

    systemctl status mysql.service

You will see output that looks similar to this:

    mysql.service active● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
       Active: active (running) since Sat 2017-12-29 11:59:33 UTC; 1min 44s ago
     Main PID: 26525 (mysqld)
       CGroup: /system.slice/mysql.service
            └─26525 /usr/sbin/mysqld
    
    Dec 29 11:59:32 ubuntu-512mb-nyc3-create-app-and-mysql systemd[1]: Starting MySQL Community Server...
    Dec 29 11:59:33 ubuntu-512mb-nyc3-create-app-and-mysql systemd[1]: Started MySQL Community Server.

If you instead see output similar to this:

    mysql.service inactive● mysqld.service
       Loaded: not-found (Reason: No such file or directory)
       Active: inactive (dead)

You can run `sudo systemctl start mysql` to get `mysql.service` started again.

Now you can log in with your MySQL credentials using the following command. Where `-u` is the flag for declaring your username and `-p` is the flag that tells MySQL that this user requires a password:

    mysql -u db_user -p

Then you will see output that asks you for this db\_user’s password:

    OutputEnter password:

Once you enter your password correctly, you will see the following output:

    OutputWelcome to the MySQL monitor. Commands end with ; or \g.
    Your MySQL connection id is 6
    Server version: 5.7.20-0ubuntu0.16.04.1 (Ubuntu)
    
    Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

We can have MySQL show us the current databases with the following command:

    SHOW DATABASES;

You’ll see output similar to the following, assuming that you haven’t created any databases yet:

    Output+--------------------+
    | Database |
    +--------------------+
    | information_schema |
    | mysql |
    | performance_schema |
    | sys |
    +--------------------+
    4 rows in set (0.00 sec)

**Note:** If you get an error while trying to connect, verify that your password is correct and that you’ve properly installed MySQL. Otherwise revisit the [tutorial on how to install and configure MySQL](how-to-install-MySQL-on-ubuntu-16-04).

By default, you will have 4 databases already created, `information_schema`, `MySQL`, `performance_schema` and `sys`. We won’t need to touch these, as they contain information important for the MySQL server itself.

Now, that you’ve successfully logged into your MySQL server, we will create the initial database that will hold the data for our blog.

To create a database in MySQL run the following command, using a meaningful name for your database:

    CREATE DATABASE blog_data;

Upon successful creation of the database, you will see the following output:

    OutputQuery OK, 1 row affected (0.00 sec)

**Note:** If you see the following output:

    database creation failedERROR 1007 (HY000): Can't create database blog_data; database exists

Then, as the error states, a database of the name `blog_data` already exists.

And if you see the following MySQL error, it means there’s a MySQL syntax error. Verify that you’ve entered the command exactly as shown in this tutorial.

    database creation failedERROR 1064 (42000): You have an error in your SQL syntax;

Next, verify that the database is now listed in your list of available databases:

    SHOW DATABASES;

You should see that the `blog_data` database is among the databases included in the output:

    output+--------------------+
    | Database |
    +--------------------+
    | information_schema |
    | blog_data |
    | mysql |
    | performance_schema |
    | sys |
    +--------------------+
    5 rows in set (0.00 sec)

You’ve successfully created a MySQL database for your blog.

Whenever you’d like to exit MySQL server, press `CTRL` + `D`.

## Step 5 — Add the MySQL Database Connection to your Application

Finally, we will be adding the database connection credentials to your Django application.

**Note:** It is important to remember that connection settings, according to the Django documentation, are used in the following order:  
 - `OPTIONS`  
 - `NAME`, `USER`, `PASSWORD`, `HOST`, `PORT`  
 - `MySQL option files.`

Let’s make the changes needed to connect your Django blog app to MySQL.

Navigate to the `settings.py` file and replace the current `DATABASES` lines with the following. We will configure your database dictionary so that it knows to use MySQL as your database backend and from what file to read your database connection credentials:

settings.py

    ...
    # Database
    # https://docs.djangoproject.com/en/2.0/ref/settings/#databases
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.mysql',
            'OPTIONS': {
                'read_default_file': '/etc/mysql/my.cnf',
            },
        }
    }
    ...

Next, let’s edit the config file so that it has your MySQL credentials. Use nano as `sudo` to edit the file and add the following information:

    sudo nano /etc/mysql/my.cnf

my.cnf

    ...
    [client]
    database = db_name
    user = db_user
    password = db_password
    default-character-set = utf8

Where database name in our case is `blog_data`, your username for the MySQL server is the one you’ve created, and the password is the MySQL server password you’ve created. Also, you’ll notice that `utf8` is set as the default encoding, this is a common way to encode unicode data in MySQL.

Once the file has been edited, we need to restart MySQL for the changes to take effect.

    systemctl daemon-reload
    systemctl restart mysql

Please note that restarting MySQL takes a few seconds, so please be patient.

## Step 6 — Test MySQL Connection to Application

We need to verify that the configurations in Django detect your MySQL server properly. We can do this by simply running the server. If it fails, it means that the connection isn’t working properly. Otherwise, the connection is valid.

We’ll need to navigate to the following directory:

    cd ~/my_blog_app/blog/

From there, we can run the following command:

    python manage.py runserver your-server-ip:8000

You will now see output similar to the following:

    OutputPerforming system checks...
    
    System check identified no issues (0 silenced).
    
    You have 13 unapplied migration(s). Your project may not work properly until you apply the migrations for app(s): admin, auth, contenttypes, sessions.
    Run 'python manage.py migrate' to apply them.
    
    January 4, 2018 - 15:45:39
    Django version 2.0.1, using settings 'blog.settings'
    Starting development server at http://your-server-ip:8000/
    Quit the server with CONTROL-C.

**Note:** You will see that you have unapplied migrations in the output. But, don’t worry, this will be addressed in the upcoming tutorials. This does not affect the initial setup of our application. Please continue.

Follow the instructions from the output and follow the suggested link, `http://your-server-ip:8000/`, to view your web application and to verify that it is working properly.

![Django Default Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/django-2-testsite.png)

If your page appears similar to the screenshot above, your Django application is working as expected!

When you are done with testing your app, you can press `CTRL` + `C` to stop the `runserver` command. This will return you to the your programming environment.

When you are ready to leave your Python environment, you can run the `deactivate` command:

    deactivate

Deactivating your programming environment will put you back to the terminal command prompt.

## Conclusion

In this tutorial, you created the initial foundation of your Django blog. You have installed, configured and connected MySQL to the Django backend. You’ve also added some important information to your application’s `settings.py` file such as `TIME_ZONE` and `ALLOWED_HOSTS`.

Now that these basic settings and configurations are complete, you can now begin to develop models and apply migrations in your Django application.
