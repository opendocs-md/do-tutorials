---
author: Jeremy Morris
date: 2017-07-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-django-and-set-up-a-development-environment-on-ubuntu-16-04
---

# How To Install Django and Set Up a Development Environment on Ubuntu 16.04

## Introduction

Django is a free and open-source web framework written in Python that adheres to the **model template view (MTV)** software architectural pattern. The MTV pattern is Django’s take on the [model–view–controller (MVC)](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) pattern. According to the Django Software Foundation, the _model_ is the single definitive source of your data, the _view_ describes the data that gets represented to the user via a Python callback [function](how-to-define-functions-in-python-3) to a specific URL, and the _template_ is how Django generates HTML dynamically.

Django’s core principles are scalability, re-usability and rapid development. It is also known for its framework-level consistency and loose coupling, allowing for individual components to be independent of one another. Don’t repeat yourself ([DRY programming](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)) is an integral part of Django principles.

In this tutorial, we will set up a Django development environment. We’ll install Python 3, pip 3, Django and `virtualenv` in order to provide you with the tools necessary for developing web applications with Django.

## Prerequisites

A non-root user account with `sudo` privileges set up on a Debian or Ubuntu Linux server. You can achieve these prerequisites by following and completing the [initial server setup for Debian 8](initial-server-setup-with-debian-8), or steps 1-4 in the [initial server setup for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial.

## Step 1 — Install Python and pip

To install Python we must first update the local APT repository. In your terminal window, we’ll input the command that follows. Note that the `-y` flag answers “yes” to prompts during the upgrade process. Remove the flag if you’d like the upgrade to stop for each prompt.

    sudo apt-get update && sudo apt-get -y upgrade

When prompted to configure `grub-pc`, you can press `ENTER` to accept the default, or configure as desired.

It is recommended by the Django Software Foundation to use Python 3, so once everything is updated, we can install Python 3 by using the following command:

    sudo apt-get install python3

To verify the successful installation of Python 3, run a version check with the **python3** command:

    python3 -V

The resulting output will look similar to this:

    Outputpython 3.5.2

Now that we have Python 3 installed, we will also need **pip** in order to install packages from PyPi, Python’s package repository.

    sudo apt-get install -y python3-pip

To verify that pip was successfully installed, run the following command:

    pip3 -V

You should see output similar to this:

    Outputpip 8.1.1 from /usr/lib/python3/dist-packages (python 3.5)

Now that we have pip installed, we have the ability to quickly install other necessary packages for a Python environment.

## Step 2 — Install virtualenv

**virtualenv** is a [virtual environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server#step-2-%E2%80%94-setting-up-a-virtual-environment) where you can install software and Python packages in a contained development space, which isolates the installed software and packages from the rest of your machine’s global environment. This convenient isolation prevents conflicting packages or software from interacting with each other.

To install virtualenv, we will use the **pip3** command, as shown below:

    pip3 install virtualenv

Once it is installed, run a version check to verify that the installation has completed successfully:

    virtualenv --version

We should see the following output, or something similar:

    Output15.1.0

You have successfully installed **virtualenv**.

At this point, we can isolate our Django web application and its associated software dependencies from other Python packages or projects on our system.

## Step 3 — Install Django

There are three ways to install Django. We will be using the pip method of installation for this tutorial, but let’s address all of the available options for your reference.

- **Option 1: Install Django within a `virtualenv`.**  
This is ideal for when you need your version of Django to be isolated from the global environment of your server.

- **Option 2: Install Django from Source.**  
If you want the latest software or want something newer than what your Ubuntu APT repository offers, you can install directly from source. Note that opting for this installation method requires constant attention and maintenance if you want your version of the software to be up to date.

- **Option 3: Install Django Globally with pip.**  
The option we are going with is pip 3 as we will be installing Django globally. 

We’ll be installing Django using pip within a virtual environment. For further guidance and information on the setup and utilization of programming environments, check out this tutorial on [setting up a virtual environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server).

While in the server’s home directory, we have to create the directory that will contain our Django application. Run the following command to create a directory called `django-apps`, or another name of your choice. Then navigate to the directory.

    mkdir django-apps
    cd django-apps 

While inside the `django-apps` directory, create your virtual environment. Let’s call it `env`.

    virtualenv env

Now, activate the virtual environment with the following command:

    . env/bin/activate

You’ll know it’s activated once the prefix is changed to `(env)`, which will look similar to the following depending on what directory you are in:

    

Within the environment, install the Django package using pip. Installing Django allows us to create and run Django applications. To learn more about Django, read our tutorial series on [Django Development](https://www.digitalocean.com/community/tutorial_series/django-development).

    pip install django

Once installed, verify your Django installation by running a version check:

    django-admin --version

This, or something similar, will be the resulting output:

    Output2.0.1

With Django installed on your server, we can move on to creating a test project to make sure everything is working correctly.

## Step 4 — Creating a Django Test Project

To test the Django installation, we will be creating a skeleton web application.

### Setting Firewall Rules

First, if applicable, we’ll need to open the port we’ll be using in our server’s firewall. If you are using UFW (as detailed in the [initial server setup guide](initial-server-setup-with-ubuntu-16-04#step-seven-%E2%80%94-set-up-a-basic-firewall)), you can open the port with the following command:

    sudo ufw allow 8000

If you’re using DigitalOcean Firewalls, you can select `HTTP` from the inbound rules. You can read more about DigitalOcean Firewalls and creating rules for them by reading the [inbound rules section of the introductory tutorial](an-introduction-to-digitalocean-cloud-firewalls#creating-new-inbound-rules-from-presets).

### Starting the Project

We now can generate an application using `django-admin`, a command line utility for administration tasks in Python. Then we can use the `startproject` command to create the project directory structure for our test website.

While in the `django-apps` directory, run the following command:

    django-admin startproject testsite

**Note:** Running the `django-admin startproject <projectname>` command will name both project directory and project package the `<projectname>` and create the project in the directory in which the command was run. If the optional `<destination>` parameter is provided, Django will use the provided destination directory as the project directory, and create `manage.py` and the project package within it.

Now we can look to see what project files were just created. Navigate to the `testsite` directory then list the contents of that directory to see what files were created:

    cd testsite

    ls

    Outputmanage.py testsite

You will notice output that shows this directory contains a file named `manage.py` and a folder named `testsite`. The `manage.py` file is similar to `django-admin` and puts the project’s package on `sys.path`. This also sets the `DJANGO_SETTINGS_MODULE` environment variable to point to your project’s `settings.py` file.

You can view the `manage.py` script in your terminal by running the `less` command like so:

    less manage.py

When you’re finished reading the script, press `q`, to quit viewing the file.

Now navigate to the `testsite` directory to view the other files that were created:

    cd testsite/

Then run the following command to list the contents of the directory:

    ls

You will see four files:

    Output __init__.py settings.py urls.py wsgi.py

Let’s go over what each of these files are:

- ` __init__.py` acts as the entry point for your Python project.
- `settings.py` describes the configuration of your Django installation and lets Django know which settings are available.
- `urls.py` contains a `urlpatterns` list, that routes and maps URLs to their `views`.
- `wsgi.py` contains the configuration for the Web Server Gateway Interface. The Web Server Gateway Interface ([WSGI](https://nl.wikipedia.org/wiki/Web_Server_Gateway_Interface)) is the Python platform standard for the deployment of web servers and applications.

**Note:** Although a default file was generated, you still have the ability to tweak the `wsgi.py` at any time to fit your deployment needs.

### Start and View your Website

Now we can start the server and view the website on a designated host and port by running the `runserver` command.

We’ll need to add your server ip address to the list of `ALLOWED_HOSTS` in the `settings.py` file located in `~/test_django_app/testsite/testsite/`.

As stated in the [Django docs](https://docs.djangoproject.com/en/2.0/ref/settings/), the `ALLOWED_HOSTS` variable contains “a list of strings representing the host/domain names that this Django site can serve. This is a security measure to prevent HTTP Host header attacks, which are possible even under many seemingly-safe web server configurations.”

You can use your favorite text editor to add your ip address. For example, if you’re using `nano`, just simply run the following command:

    nano ~/django-apps/testsite/testsite/settings.py

Once you run the command, you’ll want to navigate to the Allowed Hosts Section of the document and add your server’s IP address inside the square brackets within single or double quotes.

settings.py

    """
    Django settings for testsite project.
    
    Generated by 'django-admin startproject' using Django 2.0.
    ...
    """
    ...
    # SECURITY WARNING: don't run with debug turned on in production!
    DEBUG = True
    
    # Edit the line below with your server IP address
    ALLOWED_HOSTS = ['your-server-ip']
    ...

You can save the change and exit nano by holding down the `CTRL` + `x` keys and then pressing the `y` key.

With this completed, be sure to navigate back to the directory where `manage.py` is located:

    cd ~/django-apps/testsite/

Now, run the following command replacing the your-server-ip text with the IP of your server:

    python manage.py runserver your-server-ip:8000

Finally, you can navigate to the below link to see what your skeleton website looks like, again replacing the highlighted text with your server’s actual IP:

    http://your-server-ip:8000/

Once the page loads, you’ll see the following:

![Django Default Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/django-2-testsite.png)

This confirms that Django was properly installed and our test project is working correctly.

When you are done with testing your app, you can press `CTRL` + `C` to stop the `runserver` command. This will return you to the your programming environment.

When you are ready to leave your Python environment, you can run the `deactivate` command:

    deactivate

Deactivating your programming environment will put you back to the terminal command prompt.

## Conclusion

In this tutorial you have successfully upgraded to the latest version of Python 3 available to you via the Ubuntu APT repository. You’ve also installed pip 3, `virtualenv`, and `django`.

You now have the tools needed to get started building Django web applications.
