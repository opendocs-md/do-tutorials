---
author: Justin Ellingwood
date: 2016-05-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-django-application-on-ubuntu-16-04
---

# How To Use PostgreSQL with your Django Application on Ubuntu 16.04

## Introduction

Django is a flexible framework for quickly creating Python applications. By default, Django applications are configured to store data into a lightweight SQLite database file. While this works well under some loads, a more traditional DBMS can improve performance in production.

In this guide, we’ll demonstrate how to install and configure PostgreSQL to use with your Django applications. We will install the necessary software, create database credentials for our application, and then start and configure a new Django project to use this backend.

## Prerequisites

To get started, you will need a clean Ubuntu 16.04 server instance with a non-root user set up. The non-root user must be configured with `sudo` privileges. Learn how to set this up by following our [initial server setup guide](initial-server-setup-with-ubuntu-16-04).

When you are ready to continue, log in as your `sudo` user and read on.

## Install the Components from the Ubuntu Repositories

Our first step will be install all of the pieces that we need from the repositories. We will install `pip`, the Python package manager, in order to install and manage our Python components. We will also install the database software and the associated libraries required to interact with them.

Python 2 and Python 3 require slightly different packages, so choose the commands below that match the Python version of your project.

If you are using **Python 2** , type:

    sudo apt-get update
    sudo apt-get install python-pip python-dev libpq-dev postgresql postgresql-contrib

If, instead, you are using **Python 3** , type:

    sudo apt-get update
    sudo apt-get install python3-pip python3-dev libpq-dev postgresql postgresql-contrib

With the installation out of the way, we can move on to create our database and database user.

## Create a Database and Database User

By default, Postgres uses an authentication scheme called “peer authentication” for local connections. Basically, this means that if the user’s operating system username matches a valid Postgres username, that user can login with no further authentication.

During the Postgres installation, an operating system user named `postgres` was created to correspond to the `postgres` PostgreSQL administrative user. We need to use this user to perform administrative tasks. We can use `sudo` and pass in the username with the `-u` option.

Log into an interactive Postgres session by typing:

    sudo -u postgres psql

First, we will create a database for our Django project. Each project should have its own isolated database for security reasons. We will call our database `myproject` in this guide, but it’s always better to select something more descriptive:

    CREATE DATABASE myproject;

note
Remember to end all commands at an SQL prompt with a semicolon.  

Next, we will create a database user which we will use to connect to and interact with the database. Set the password to something strong and secure:

    CREATE USER myprojectuser WITH PASSWORD 'password';

Afterwards, we’ll modify a few of the connection parameters for the user we just created. This will speed up database operations so that the correct values do not have to be queried and set each time a connection is established.

We are setting the default encoding to UTF-8, which Django expects. We are also setting the default transaction isolation scheme to “read committed”, which blocks reads from uncommitted transactions. Lastly, we are setting the timezone. By default, our Django projects will be set to use `UTC`. These are all recommendations from [the Django project itself](https://docs.djangoproject.com/en/1.9/ref/databases/#optimizing-postgresql-s-configuration).

    ALTER ROLE myprojectuser SET client_encoding TO 'utf8';
    ALTER ROLE myprojectuser SET default_transaction_isolation TO 'read committed';
    ALTER ROLE myprojectuser SET timezone TO 'UTC';

Now, all we need to do is give our database user access rights to the database we created:

    GRANT ALL PRIVILEGES ON DATABASE myproject TO myprojectuser;

Exit the SQL prompt to get back to the `postgres` user’s shell session:

    \q

## Install Django within a Virtual Environment

Now that our database is set up, we can install Django. For better flexibility, we will install Django and all of its dependencies within a Python virtual environment. The `virtualenv` package allows you to create these environments easily.

If you are using **Python 2** , you can install the correct package by typing:

    sudo pip install virtualenv

If you are using **Python 3** , type:

    sudo pip3 install virtualenv

Make and move into a directory to hold your Django project:

    mkdir ~/myproject
    cd ~/myproject

We can create a virtual environment to store our Django project’s Python requirements by typing:

    virtualenv myprojectenv

This will install a local copy of Python and a local `pip` command into a directory called `myprojectenv` within your project directory.

Before we install applications within the virtual environment, we need to activate it. You can do so by typing:

    source myprojectenv/bin/activate

Your prompt will change to indicate that you are now operating within the virtual environment. It will look something like this `(myprojectenv)user@host:~/myproject$`.

Once your virtual environment is active, you can install Django with `pip`. We will also install the `psycopg2` package that will allow us to use the database we configured:

Note
Regardless of which version of Python you are using, when the virtual environment is activated, you should use the `pip` command (not `pip3`).  

    pip install django psycopg2

We can now start a Django project within our `myproject` directory. This will create a child directory of the same name to hold the code itself, and will create a management script within the current directory. Make sure to add the dot at the end of the command so that this is set up correctly:

    django-admin.py startproject myproject .

## Configure the Django Database Settings

Now that we have a project, we need to configure it to use the database we created.

Open the main Django project settings file located within the child project directory:

    nano ~/myproject/myproject/settings.py

Towards the bottom of the file, you will see a `DATABASES` section that looks like this:

~/myproject/myproject/settings.py

    . . .
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
        }
    }
    
    . . .

This is currently configured to use SQLite as a database. We need to change this so that our PostgreSQL database is used instead.

First, change the engine so that it uses the `postgresql_psycopg2` adaptor instead of the `sqlite3` adaptor. For the `NAME`, use the name of your database (`myproject` in our example). We also need to add login credentials. We need the username, password, and host to connect to. We’ll add and leave blank the port option so that the default is selected:

~/myproject/myproject/settings.py

    . . .
    
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql_psycopg2',
            'NAME': 'myproject',
            'USER': 'myprojectuser',
            'PASSWORD': 'password',
            'HOST': 'localhost',
            'PORT': '',
        }
    }
    
    . . .

While you are here, you may also need to adjust the `ALLOWED_HOSTS` directive. This defines a whitelist of addresses or domain names may be used to connect to the Django instance. Any incoming requests with a **Host** header that is not in this list will raise an exception. Django requires that you set this to prevent a certain class of security vulnerability.

In the square brackets, list the IP addresses or domain names that are associated with your Django server. Each item should be listed in quotations with entries separated by a comma. If you wish requests for an entire domain and any subdomains, prepend a period to the beginning of the entry. In the snippet below, there are a few commented out examples used to demonstrate:

~/myproject/myproject/settings.py

    . . .
    # The simplest case: just add the domain name(s) and IP addresses of your Django server
    # ALLOWED_HOSTS = ['example.com', '203.0.113.5']
    # To respond to 'example.com' and any subdomains, start the domain with a dot
    # ALLOWED_HOSTS = ['.example.com', '203.0.113.5']
    ALLOWED_HOSTS = ['your_server_domain_or_IP', 'second_domain_or_IP', . . .]

When you are finished, save and close the file.

## Migrate the Database and Test your Project

Now that the Django settings are configured, we can migrate our data structures to our database and test out the server.

We can begin by creating and applying migrations to our database. Since we don’t have any actual data yet, this will simply set up the initial database structure:

    cd ~/myproject
    python manage.py makemigrations
    python manage.py migrate

After creating the database structure, we can create an administrative account by typing:

    python manage.py createsuperuser

You will be asked to select a username, provide an email address, and choose and confirm a password for the account.

If you followed the initial server setup guide, you should have a UFW firewall in place. Before we can access the Django development server to test our database, we need open the port we will be using in our firewall.

Allow external connections to the port by typing:

    sudo ufw allow 8000

Once you have the port open, you can test that your database is performing correctly by starting up the Django development server:

    python manage.py runserver 0.0.0.0:8000

In your web browser, visit your server’s domain name or IP address followed by `:8000` to reach default Django root page:

    http://server_domain_or_IP:8000

You should see the default index page:

![Django index](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_mysql_1404/django_index.png)

Append `/admin` to the end of the URL and you should be able to access the login screen to the admin interface:

![Django admin login](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_mysql_1404/admin_login.png)

Enter the username and password you just created using the `createsuperuser` command. You will then be taken to the admin interface:

![Django admin interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_mysql_1404/admin_interface.png)

When you’re done investigating, you can stop the development server by hitting CTRL-C in your terminal window.

By accessing the admin interface, we have confirmed that our database has stored our user account information and that it can be appropriately accessed.

## Conclusion

In this guide, we’ve demonstrated how to install and configure PostgreSQL as the backend database for a Django project. While SQLite can easily handle the load during development and light production use, most projects benefit from implementing a more full-featured DBMS.
