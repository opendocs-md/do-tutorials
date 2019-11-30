---
author: Justin Ellingwood
date: 2016-12-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-apache-and-mod_wsgi-on-debian-8
---

# How To Serve Django Applications with Apache and mod_wsgi on Debian 8

## Introduction

Django is a powerful web framework that can help you get your Python application or website off the ground quickly. Django includes a simplified development server for testing your code locally, but for anything even slightly production related, a more secure and powerful web server is required.

In this guide, we will demonstrate how to install and configure Django in a Python virtual environment. We’ll then set up Apache in front of our application so that it can handle client requests directly before passing requests that require application logic to the Django app. We will do this using the `mod_wsgi` Apache module that can communicate with Django over the WSGI interface specification.

## Prerequisites and Goals

In order to complete this guide, you should have a fresh Debian 8 server instance with a non-root user with `sudo` privileges configured. You can learn how to set this up by running through our [initial server setup guide](initial-server-setup-with-debian-8).

We will be installing Django within a Python virtual environment. Installing Django into an environment specific to your project will allow your projects and their requirements to be handled separately.

Once we have our application up and running, we will configure Apache to interface with the Django app. It will do this with the `mod_wsgi` Apache module, which can translate HTTP requests into a predictable application format defined by a specification called WSGI. You can find out more about WSGI by reading the linked section on [this guide](how-to-set-up-uwsgi-and-nginx-to-serve-python-apps-on-ubuntu-14-04#definitions-and-concepts).

Let’s get started.

## Install Packages from the Debian Repositories

To begin the process, we’ll download and install all of the items we need from the Debian repositories. This will include the Apache web server, the `mod_wsgi` module used to interface with our Django app, and `pip`, the Python package manager that can be used to download our Python-related tools.

To get everything we need, update your server’s local package index and then install the appropriate packages.

If you are using Django with **Python 2** , the commands you need are:

    sudo apt-get update
    sudo apt-get install python-pip apache2 libapache2-mod-wsgi

If, instead, you are using Django with **Python 3** , you will need an alternative Apache module and `pip` package. The appropriate commands in this case are:

    sudo apt-get update
    sudo apt-get install python3-pip apache2 libapache2-mod-wsgi-py3

Now that we have the components from the Debian repositories, we can start working on our Django project.

## Configure a Python Virtual Environment

The first step is to create a Python virtual environment so that our Django project will be separate from the system’s tools and any other Python projects we may be working on. We need to install the `virtualenv` command to create these environments. We can get this package using `pip`.

If you are using **Python 2** , type:

    sudo pip install virtualenv

If you are using **Python 3** , type:

    sudo pip3 install virtualenv

With `virtualenv` installed, we can start forming our project. Create a directory where you wish to keep your project and move into the directory:

    mkdir ~/myproject
    cd ~/myproject

Within the project directory, create a Python virtual environment by typing:

    virtualenv myprojectenv

This will create a directory called `myprojectenv` within your `myproject` directory. Inside, it will install a local version of Python and a local version of `pip`. We can use this to install and configure an isolated Python environment for our project.

Before we install our project’s Python requirements, we need to activate the virtual environment. You can do that by typing:

    source ~/myproject/myprojectenv/bin/activate

Your prompt should change to indicate that you are now operating within a Python virtual environment. It will look something like this: `(myprojectenv)user@host:~/myproject$`.

With your virtual environment active, install Django with the local instance of `pip`:

**Note:** Virtual environments use their own version of Python and related tools. Regardless of whether you are using Python 2 or Python 3, when the virtual environment is activated, you should use the `pip` command (not `pip3`).

    pip install django

This will install the Django package within your Python virtual environment.

## Create and Configure a New Django Project

Now that Django is installed in our virtual environment, we can create the actual Django project files.

### Create the Django Project

Since we already have a parent project directory at `~/myproject`, we will tell Django to install the files here. The command will create a second level directory containing the actual code. It will also place a management script in the current project directory. The key to achieving the correct directory structure is to list the parent directory after the project name:

    django-admin.py startproject myproject ~/myproject

You should end up with a directory structure that looks like this:

    .
    └── ./myproject/ # parent project directory
        ├── manage.py # Django management script
        ├── myproject/ # project code directory
        │   ├── __init__.py
        │   ├── settings.py
        │   ├── urls.py
        │   └── wsgi.py
        └── myprojectenv/ # project virtual environment directory
            └── . . .

Checking that your directory structure aligns with this can help minimize errors later on.

### Adjust the Project Settings

The first thing we should do with our newly created project files is adjust the settings. Open the settings file with your text editor:

    nano ~/myproject/myproject/settings.py

We are going to be using the default SQLite database in this guide for simplicity’s sake, so we don’t actually need to change too much. We will focus on configuring the allowed hosts to restrict the domains that we respond to and configuring the static files directory, where Django will place static files so that the web server can serve these easily.

Begin by finding the `ALLOWED_HOSTS` line. Inside the square brackets, enter your server’s public IP address, domain name or both. Each value should be wrapped in quotes and separated by a comma like a normal Python list. It’s a good idea to add local addresses like `127.0.0.1` and `127.0.1.1` as well:

~/myproject/myproject/settings.py

    . . .
    ALLOWED_HOSTS = ["server_domain_or_IP", "127.0.0.1", "127.0.1.1"]
    . . .

At the bottom of the file, we will set Django’s `STATIC_ROOT`. Django can collect and output all static assets into a known directory so that the web server can serve them directly. We’ll use a bit of Python to tell it to use a directory called “static” in our project’s main directory:

~/myproject/myproject/settings.py

    . . .
    
    STATIC_URL = '/static/'
    STATIC_ROOT = os.path.join(BASE_DIR, 'static/')

Save and close the file when you are finished.

### Complete Initial Project Setup

Now, we can migrate the initial database schema to our SQLite database using the management script:

    cd ~/myproject
    ./manage.py makemigrations
    ./manage.py migrate

Create an administrative user for the project by typing:

    ./manage.py createsuperuser

You will have to select a username, provide an email address, and choose and confirm a password.

We can collect all of the static content into the directory location we defined with `STATIC_ROOT` by typing:

    ./manage.py collectstatic

You will have to confirm the operation. As expected, the static files will be placed in a directory called `static` within your project directory.

You may have to adjust your firewall settings to allow traffic to our Django development server, which we’ll run on port 8000.

If you are running a `ufw` firewall, you can allow traffic to port 8000 by typing:

    sudo ufw allow 8000

If you are running `iptables` instead, the exact command you need depends on your current firewall configuration. For most configurations, this command should work:

    sudo iptables -I INPUT -p tcp --dport 8000 -j ACCEPT

Finally, you can test your project by starting up the Django development server with this command:

    ./manage.py runserver 0.0.0.0:8000

In your web browser, visit your server’s domain name or IP address followed by `:8000`:

    http://server_domain_or_IP:8000

You should see the default Django index page:

![Django default index](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_uwsgi_nginx_1404/sample_site.png)

If you append `/admin` to the end of the URL in the address bar, you will be prompted for the administrative username and password you created with the `createsuperuser` command:

![Django admin login](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_uwsgi_nginx_1404/admin_login.png)

After authenticating, you can access the default Django admin interface:

![Django admin interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_uwsgi_nginx_1404/admin_interface.png)

When you are finished exploring, hit CTRL-C in the terminal window to shut down the development server.

We’re now done with Django for the time being, so we can back out of our virtual environment by typing:

    deactivate

The `(myprojectenv)` prefix to your shell prompt should disappear.

## Configure Apache

Now that your Django project is working, we can configure Apache as a front end. Client connections that it receives will be translated into the WSGI format that the Django application expects using the `mod_wsgi` module. This should have been automatically enabled upon installation earlier.

To configure the WSGI pass, we’ll need to edit the default virtual host file:

    sudo nano /etc/apache2/sites-available/000-default.conf

We can keep the directives that are already present in the file. We just need to add some additional items.

To start, let’s configure the static files. We will use an alias to tell Apache to map any requests starting with `/static` to the “static” directory within our project folder. We collected the static assets there earlier. We will set up the alias and then grant access to the directory in question with a directory block:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
        . . .
    
        Alias /static /home/sammy/myproject/static
        <Directory /home/sammy/myproject/static>
            Require all granted
        </Directory>
    
    </VirtualHost>

Next, we’ll grant access to the `wsgi.py` file within the second level project directory where the Django code is stored. To do this, we’ll use a directory section with a file section inside. We will grant access to the file inside of this nested construct:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
        . . .
    
        Alias /static /home/sammy/myproject/static
        <Directory /home/sammy/myproject/static>
            Require all granted
        </Directory>
    
        # Next, add the following directory block
        <Directory /home/sammy/myproject/myproject>
            <Files wsgi.py>
                Require all granted
            </Files>
        </Directory>
    
    </VirtualHost>

After this is configured, we are ready to construct the portion of the file that actually handles the WSGI pass. We’ll use daemon mode to run the WSGI process, which is the recommended configuration. We can use the `WSGIDaemonProcess` directive to set this up.

This directive takes an arbitrary name for the process. We’ll use `myproject` to stay consistent. Afterwards, we set up the Python home where Apache can find all of the components that may be required. Since we used a virtual environment, we can point this directly to our base virtual environment directory. Afterwards, we set the Python path to point to the base of our Django project.

Next, we need to specify the process group. This should point to the same name we selected for the `WSGIDaemonProcess` directive (`myproject` in our case). Finally, we need to set the script alias so that Apache will pass requests for the root domain to the `wsgi.py` file:

/etc/apache2/sites-available/000-default.conf

    <VirtualHost *:80>
        . . .
    
        Alias /static /home/sammy/myproject/static
        <Directory /home/sammy/myproject/static>
            Require all granted
        </Directory>
    
        <Directory /home/sammy/myproject/myproject>
            <Files wsgi.py>
                Require all granted
            </Files>
        </Directory>
    
        WSGIDaemonProcess myproject python-home=/home/sammy/myproject/myprojectenv python-path=/home/sammy/myproject
        WSGIProcessGroup myproject
        WSGIScriptAlias / /home/sammy/myproject/myproject/wsgi.py
    
    </VirtualHost>

When you are finished making these changes, save and close the file.

### Wrapping Up Some Permissions Issues

If you are using the SQLite database, which is the default used in this article, you need to allow the Apache process access to this file.

To do so, the first step is to change the permissions so that the group owner of the database can read and write. The database file is called `db.sqlite3` by default and it should be located in your base project directory:

    chmod 664 ~/myproject/db.sqlite3
    chmod 775 ~/myproject

Afterwards, we need to give the group Apache runs under, the `www-data` group, group ownership of the file:

    sudo chown :www-data ~/myproject/db.sqlite3

In order to write to the file, we also need to give the Apache group ownership over the database’s parent directory:

    sudo chown :www-data ~/myproject

We need to adjust through our firewall again. We no longer need port 8000 open since we are proxying through Apache, so we can remove that rule. We can then add an exception to allow traffic to the Apache process.

If you are using `ufw`, you can do this by typing:

    sudo ufw delete allow 8000
    sudo ufw allow 'Apache Full'

If you are using `iptables`, the appropriate commands will look something like this:

    sudo iptables -D INPUT -p tcp --dport 8000 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

Check your Apache files to make sure you did not make any syntax errors:

    sudo apache2ctl configtest

As long as the last line of output looks like this, your files are in good shape:

    Output. . .
    Syntax OK

Once these steps are done, you are ready to restart the Apache service to implement the changes you made. Restart Apache by typing:

    sudo systemctl restart apache2

You should now be able to access your Django site by going to your server’s domain name or IP address without specifying a port. The regular site and the admin interface should function as expected.

## Next Steps

After verifying that your application is accessible, it is important to secure traffic to your application.

If you have a domain name for your application, the easiest way to secure your application is with a free SSL certificate from Let’s Encrypt. Follow our [Let’s Encrypt guide for Apache on Debian 8](how-to-secure-apache-with-let-s-encrypt-on-debian-8) to learn how to set this up.

If you **do not** have a domain name for your application and are using this for your own purposes or for testing, you can always create a self-signed certificate. You can learn how to set this up with our [guide on creating self-signed SSL certificates for Apache on Debian 8](how-to-create-a-ssl-certificate-on-apache-for-debian-8).

## Conclusion

In this guide, we’ve set up a Django project in its own virtual environment. We’ve configured Apache with `mod_wsgi` to handle client requests and interface with the Django app.

Django makes creating projects and applications simple by providing many of the common pieces, allowing you to focus on the unique elements. By leveraging the general tool chain described in this article, you can easily serve the applications you create from a single server.
