---
author: Justin Ellingwood
date: 2016-12-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-django-web-framework-on-debian-8
---

# How To Install the Django Web Framework on Debian 8

## Introduction

Django is a full-featured Python web framework for developing dynamic websites and applications. Using Django, you can quickly create Python web applications and rely on the framework to do a good deal of the heavy lifting.

In this guide, we will show you how to get Django up and running on a Debian 8 server. After installation, we’ll show you how to start a new project to use as the basis for your site.

## Prerequisites

Before you begin, you should have a non-root user with `sudo` privileges available on your Debian 8 server. To set this up, follow our [Debian 8 initial server setup guide](initial-server-setup-with-debian-8).

When you are ready to continue, read below to decide on which installation method is best for your situation.

## Available Installation Methods

There are a number of different ways in which you can install Django depending upon your needs and how you want to configure your development environment. These have different advantages and one method may lend itself better to your specific situation than others.

Some of the different methods are below:

- **Global Install from Packages** : The official Debian repositories contain Django packages that can be installed easily with the conventional `apt` package manager. This is very simple, but not as flexible as some other methods. Also, the version contained in the repositories may lag behind the official versions available from the project.
- **Global Install through pip** : The `pip` tool is a package manager for Python packages. If you install `pip`, you can easily install Django on the system level for use by any user. This should always contain the latest stable release. Even so, global installations are inherently less flexible.
- **Install through pip in a Virtualenv** : The Python `virtualenv` package allows you to create self-contained environments for various projects. Using this technology, you can install Django in a project directory without affecting the system-level packages. This allows you to provide per-project customizations and packages easily. Virtual environments add some slight mental and process overhead in comparison to globally accessible installation, but provide the most flexibility.
- **Development Version Install through git** : If you wish to install the latest development version instead of the stable release, you will have to acquire the code from the `git` repo. This may be necessary to get the latest features/fixes and can be done globally or locally. Development versions do not have the same stability guarantees, however.

With the above caveats and qualities in mind, select the installation method that best suits your needs out of the below instructions. Afterwards, be sure to check out the section on creating a sample project to learn how to get started.

## Global Install from Packages

If you wish to install Django using the Debian repositories, the process is very straightforward.

First, update your local package index with `apt`:

    sudo apt-get update

Next, select which Python version you want to use with Django. For **Python 2** , type:

    sudo apt-get install python-django

If, instead, you would like to use **Python 3** with Django, type:

    sudo apt-get install python3-django

You can test that the installation was successful by typing:

    django-admin --version

    Output1.7.11

This means that the software was successfully installed. You may also notice that the Django version is not the latest stable. To learn a bit about how to use the software, skip ahead to learn [how to create a sample project](how-to-install-the-django-web-framework-on-debian-8#creating-a-sample-project).

## Global Install through pip

If you wish to install the latest version of Django globally, a better option is to use `pip`, the Python package manager. First, we need to install the `pip` package manager. Refresh your `apt` package index:

    sudo apt-get update

Now, you can install the appropriate packages and complete the installation. The packages and commands you need depend on the version of Python you plan to use with your projects.

### Python 2

If you plan on using Python 2, install `pip`, the Python package manager, using the following command:

    sudo apt-get install python-pip

Now that you have `pip`, you can easily install Django by typing:

    sudo pip install django

You can verify that the installation was successful by typing:

    django-admin --version

    Output1.10.4

As you can see, the version available through `pip` is more up-to-date than the one from the Debian repositories (yours will likely be different from the above).

### Python 3

If you plan on using **Python 3** , install `pip` using this command:

    sudo apt-get install python3-pip

Next, we can leverage the `pip` package manager to install Django by typing:

    sudo pip3 install django

To verify that the installation completed correctly, type:

    django-admin --version

    Output1.10.4

The version installed through `pip` should be the latest stable release (the specific version may be different than the one shown above).

## Virtualenv Install through pip

Perhaps the most flexible way to install Django on your system is with the `virtualenv` tool. This tool allows you to create virtual Python environments where you can install any Python packages you want without affecting the rest of the system. This allows you to select Python packages on a per-project basis regardless of conflicts with other project’s requirements.

We will begin by installing `pip` from the Debian repositories. Refresh your local package index before starting:

    sudo apt-get update

The packages and commands needed to install Django differ depending on the version of Python you wish to use for your projects. Follow the instructions below for the version of Python you plan to use.

### Python 2

The first step is to install `pip` globally. When using Python 2, the command to do this is:

    sudo apt-get install python-pip

Once `pip` is installed, you can use it to install the `virtualenv` package by typing:

    sudo pip install virtualenv

Now, whenever you start a new project, you can create a virtual environment for it. Start by creating and moving into a new project directory:

    mkdir ~/projectname
    cd ~/projectname

Now, create a virtual environment within the project directory by typing:

    virtualenv venv

This will install a standalone version of Python, as well as `pip`, into an isolated directory structure within your project directory. We chose to call our virtual environment `venv`, but you can name it something descriptive. A directory will be created with the name you select, which will hold the file hierarchy where your packages will be installed.

To install packages into the isolated environment, you must activate it by typing:

    cd ~/projectname
    source venv/bin/activate

Your prompt should change to reflect that you are now in your virtual environment. It will look something like `(venv)username@hostname:~/projectname$`.

In your new environment, you can use `pip` to install Django. You _do not_ need to use `sudo` since you are installing locally:

    pip install django

You can verify the installation by typing:

    django-admin --version

    Output1.10.4

As you can see, Django has been installed in the virtual environment.

**Note:** To exit your virtual environment, issue the `deactivate` command from anywhere on the system:

    deactivate

Your prompt should revert to the conventional display.

When you wish to work on your project again, you should re-activate your virtual environment by moving back into your project directory and activating:

    cd ~/projectname
    source venv/bin/activate

### Python 3

The first step is to install `pip` globally. To do this with Python 3, type:

    sudo apt-get install python3-pip

Next, use the package manager you just installed to install the `virtualenv` Python package:

    sudo pip3 install virtualenv

Next, create a virtual environment to hold the packages for your new project. Start by creating and moving into a new project directory:

    mkdir ~/projectname
    cd ~/projectname

Create a virtual environment within the project directory by typing:

    virtualenv venv

This will install a standalone version of Python, as well as `pip`, into an isolated directory structure within your project directory. A directory will be created with the name passed in as an argument. We have chosen `venv` here. This directory will hold the file hierarchy where your packages will be installed.

Before you install packages into the virtual environment, you must activate it by typing:

    cd ~/projectname
    source venv/bin/activate

Your command prompt should now be prefixed with the name of your virtual environment. It will look something like `(venv)username@hostname:~/projectname$`.

In your new environment, use `pip` to install Django. Notice that even though we are using Python 3, the command _within_ the virtual environment is `pip` (not `pip3`). Also note that you _do not_ need to use `sudo` since you are installing locally:

    pip install django

You can verify the installation by typing:

    django-admin --version

    Output1.10.4

As you can see, Django has been installed in the virtual environment.

**Note:** To exit your virtual environment, issue the `deactivate` command from anywhere on the system:

    deactivate

Your prompt should revert to the conventional display.

When you wish to work on your project again, you should re-activate your virtual environment by moving back into your project directory and activating:

    cd ~/projectname
    source venv/bin/activate

## Development Version Install through git

If you need a development version of Django, you will have to download and install Django from the project’s `git` repository.

To do so, you will first install `git` on your system with `apt`. We will also need `pip`, which is used to install from the downloaded source code. The package names and commands depend on the version of Python you plan on using with Django.

### Python 2

If you are using Python 2, you can update your package index and install the necessary packages by typing:

    sudo apt-get update
    sudo apt-get install git python-pip

Once you have `git`, you can clone the Django repository. Between releases, this repository will have more up-to-date features and bug fixes at the possible expense of stability. You can clone the repository to a directory called `django-dev` within your home directory by typing:

    git clone git://github.com/django/django ~/django-dev

Once the repository is cloned, you can install it using `pip`. We will use the `-e` option to install in “editable” mode, which is needed when installing from version control. If you are using version 2 of Python, type:

    sudo pip install -e ~/django-dev

You can verify that the installation was successful by typing:

    django-admin --version

    Output1.11.dev20161220175814

Keep in mind that you can combine this strategy with `virtualenv` if you wish to install a development version of Django in a single environment.

### Python 3

If you are using **Python 3** , update your package index and install `git` and `pip` by typing:

    sudo apt-get update
    sudo apt-get install git python3-pip

Next, you can clone the Django repository to a directory called `django-dev` within your home directory by typing:

    git clone git://github.com/django/django ~/django-dev

You can install Django directly from the `git` directory with `pip`. The `-e` option allows us to install in “editable” mode, which is needed when installing from version control repositories:

    sudo pip3 install -e ~/django-dev

You can verify that the installation was successful by typing:

    django-admin --version

    Output1.11.dev20161220175814

If you wish to install the development version within an isolated environment, you can combine this strategy with the `virtualenv` strategy.

## Creating a Sample Project

Once you have Django installed, we can show you how to get started on a project.

### Creating the Project Basics

Use the `django-admin` command to create a project. This will create a directory called `projectname` within your current directory. Within this new directory, a management script will be created and another directory called `projectname` will be created with the actual code.

**Note:** If you already have a parent project directory that you created for use with the `virtualenv` command, you can tell Django to place the management script and inner directory directly into the existing directory. This will help avoid an extra layer of project directories.

    cd ~/projectname
    source venv/bin/activate
    django-admin startproject projectname .

Note the ending dot at the end of the command.

To create the full directory structure (parent project directory, management script, and inner project directory), type:

    django-admin startproject projectname
    cd projectname

To bootstrap the database (this uses SQLite by default), type:

    ./manage.py migrate

Next, create an administrative user by typing:

    ./manage.py createsuperuser

You will be asked to select a username, email address, and password for the user.

### Modifying ALLOWED\_HOSTS in the Django Settings

Before you can test your application, you need to modify one of the directives in the Django settings.

Open the settings file by typing:

    nano ~/projectname/projectname/settings.py

Inside, locate the `ALLOWED_HOSTS` directive. This defines a whitelist of addresses or domain names that may be used to connect to the Django instance. Any incoming requests with a **Host** header that is not in this list will raise an exception. Django requires that you set this to prevent a certain class of security vulnerability.

In the square brackets, list the IP addresses or domain names that are associated with your Django server. Each item should be listed **in quotations** with entries **separated by a comma**. If you wish to respond to requests for a domain and any subdomains, prepend a period to the beginning of the entry. In the snippet below, there are a few commented out examples used to demonstrate the correct way to format entries:

~/myproject/myproject/settings.py

    . . .
    # The simplest case: just add the domain name(s) and IP addresses of your Django server
    # ALLOWED_HOSTS = ['example.com', '203.0.113.5']
    # To respond to 'example.com' and any subdomains, start the domain with a dot
    # ALLOWED_HOSTS = ['.example.com', '203.0.113.5']
    ALLOWED_HOSTS = ['your_server_domain_or_IP', 'second_domain_or_IP', . . .]

When you are finished, save and close the file.

### Testing with your Development Server

Next, start up the Django development server to see what a fresh Django project looks like. You should only use this for development purposes.

**Note:** Before you try the development server, make sure you open the port in your firewall.

If you happen to be running a `ufw` firewall, you can open the appropriate port by typing:

    sudo ufw allow 8000

If you are running an `iptables` firewall, the exact command you need depends on your current firewall configuration. For [most configurations](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04), this command should work:

    sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

Start up the development server by typing:

    ~/projectname/manage.py runserver 0.0.0.0:8000

Visit your server’s IP address followed by `:8000` in your web browser

    http://server_ip_address:8000

You should see something that looks like this:

![Django public page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_1404/django_default.png)

Now, append `/admin` to the end of your URL to get to the admin login page:

    server_ip_address:8000/admin

![Django admin login](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_1404/django_admin_login.png)

If you enter the admin username and password that you just created, you should be taken to the admin section of the site:

![Django admin page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_1404/django_admin_page.png)

When you are finished looking through the default site, you can stop the development server by typing `CTRL-C` in your terminal.

The Django project you’ve created provides the structural basis for designing a more complete site. Check out the [Django documentation](https://docs.djangoproject.com) for more information about how to build your applications and customize your site.

## Conclusion

You should now have Django installed on your Debian 8 server, providing the main tools you need to create powerful web applications. You should also know how to start a new project and launch the developer server. Leveraging a complete web framework like Django can help make development faster, allowing you to concentrate only on the unique aspects of your applications.
