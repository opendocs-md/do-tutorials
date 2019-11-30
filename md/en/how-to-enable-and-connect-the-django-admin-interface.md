---
author: Jeremy Morris
date: 2017-10-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-enable-and-connect-the-django-admin-interface
---

# How To Enable and Connect the Django Admin Interface

## Introduction

So far, in this Django series, you’ve started a Django application, connected your application to MySQL and created the database models for the `Posts` and `Comments` data within your blog web application.

In this tutorial, we will connect to and enable the [Django admin site](https://docs.djangoproject.com/en/1.11/ref/contrib/admin/) so that you can manage your blog website. The Django admin site comes pre-built with a user interface that is designed to allow you and other trusted individuals to manage content for the website.

It is worth noting that Django’s official documentation points out that although this is ideal for an organization’s internal use, it is not recommended to build a web application around an automatically generated Django admin interface. If you find that your interface needs to be more process-centric or proves to abstract away the implementation details of database tables and fields, it would be best for you to write your own views for the admin side.

## Prerequisites

This tutorial is part of the [Django Development](https://www.digitalocean.com/community/tutorial_series/django-development) series.

In order to complete this tutorial you should have [installed Django and set up a development environment](how-to-install-django-and-set-up-a-development-environment-on-ubuntu-16-04), [created a Django app and connected it to a MySQL database](how-to-create-a-django-app-and-connect-it-to-a-database), and [created Django models](how-to-create-django-models).

## Step 1 — Enable the Admin

First activate your Python virtual environment:

    cd ~/my_blog_app
    . env/bin/activate

In order to enable the Django Admin, we need to add it to the list of `INSTALLED_APPS` in the `settings.py` file.

Navigate to the directory of the settings file:

    cd ~/my_blog_app/blog/blog/

From here, open the `settings.py` file. If it’s not already there, add `django.contrib.admin` to the list of `INSTALLED_APPS`, using a text editor like nano.

    nano settings.py

The `INSTALLED_APPS` section of the file should look like this:

settings.py

    ...
    # Application definition
    INSTALLED_APPS = [
        'blogsite',
        'django.contrib.admin',
        'django.contrib.auth',
        'django.contrib.contenttypes',
        'django.contrib.sessions',
        'django.contrib.messages',
        'django.contrib.staticfiles',
    ]
    ...

Be sure to save and close the file if you made changes.

We can now open the `urls.py` file, again with nano or another text editor.

    nano urls.py

The file will look like this:

urls.py

    ...
    from django.urls import path
    from django.contrib import admin
    urlpatterns = [
        path('admin/', admin.site.urls),
    ]

Since the [release of Django 2.0](https://docs.djangoproject.com/en/2.0/releases/2.0/), the new [django.url.path()](https://docs.djangoproject.com/en/2.0/topics/http/urls/) function, is an improvement to the old way of creating url patterns with the `url()` function. The `path()` function allows a simpler, more readable URL routing syntax.

Here’s an example illustrating this. The previous `url()` function, illustrated here:

    url(r'^articles/(?P<year>[0-9]{4})/$', views.year_archive),

Can now be written with the `path()` function:

    path('articles/<int:year>/', views.year_archive),

The new syntax also supports type coercion of URL parameters. The above example’s year keyword would then be interpreted as an `int` as opposed to a `string`.

Now that we have ensured that our Django web project has the appropriate code in the `settings.py` and `urls.py` files, we know our application will have access to the admin models and admin user interface.

## Step 2 — Verify that Admin is an Installed App

We should next migrate the models to the database so that it picks up the newly added Admin models.

Navigate to the directory where the `manage.py` file is located.

    cd ~/my_blog_app/blog

Remember to run the `migrate` command whenever you make any changes to the `models`, like so.

    python manage.py migrate

Upon running the command, we should have received the following output because the `admin` model was already added as we’ve seen when navigating to the `INSTALLED_APPS` sections of the `settings.py` file.

    OutputOperations to perform:
      Apply all migrations: admin, auth, blogsite, contenttypes, sessions
    Running migrations:
      No migrations to apply.

We can now start the server by running the following command with your server’s IP address.

    python manage.py runserver your-server-ip:8000

Then navigate to the admin panel’s URL in a browser of your choice:

    http://your-server-ip:8000/admin/

You will see something similar to this.

![Django Admin Login Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/django-admin-login.png)

Getting to this screen shows that we have successfully enabled the admin app.

Though we have enabled the app, right now we don’t have a Django administration account. We will need to create the admin account in order to login.

## Step 3 — Create Admin Super-User Account

You’ll notice that a login page pops up, but we don’t have credentials to log in. Creating these credentials will be simple.

Django provides an easy way to generate a super-user account, which we can do by running the `manage.py` file to start the super-user creation process:

    python manage.py createsuperuser

Once we do so, we’ll be prompted to fill in details for our username, email, and password. In this tutorial, we’ll make an admin account with the username `admin_user`, the email `sammy@example.com` and the password `admin123`. You should fill this information in with your own preferences and be sure to use a secure password that you’ll remember.

    OutputUsername (leave blank to use 'root'): admin_user
    Email address: sammy@example.com

Then put in your password twice when you see the `Password:` prompt. You will not see the keystrokes or your password when you enter it. Press enter after each prompt to confirm your password.

    OutputPassword: 
    Password (again):

At this point, we now have an admin account with the username `admin_user` and the password `admin123`.

Let’s log in and take a look at what exists on our admin page.  
If needed, navigate again to the URL `http://your-server-ip:8000/admin/` to get to the admin login page. Then log in with the username and password and password you just created.

After a successful login, you’ll see the following page.

![Django Admin Panel](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/django-admin-panel.png)

Next, we will need to work on connecting our blog app to the admin panel.

## Step 4 — Create URL Patterns for Post and Comment

In the previous step, we’ve successfully logged into the admin interface, but you may have noticed that our blog app is still not visible there. So now we must go and change that by adding and registering our blog app with the associated models `Post` and `Comment`.

To do this, we’ll create an empty file called `urls.py`, in the `blogsite` directory, like so:

    touch ~/my_blog_app/blog/blogsite/urls.py

In this file, we will add the URL pattern for our blog application so that we can access it via the admin interface.

Navigate to the location of that `urls.py` file we’ve just created.

    cd ~/my_blog_app/blog/blogsite/

Then open the file with nano, for instance.

    nano urls.py

Add the following lines of code to the file.

urls.py

    from django.urls import path
    from . import views
    urlpatterns = [
        path('$/', views.posts, name='posts'),
        path('$/', views.comments, name='comments'),
    ]

These are the URL pattern expressions needed to allow our application to access the `views` for `Posts` and `Comments`. We have not created those `views` yet but will cover this later on in the series.

## Step 5 — Connect the Blog App to Admin

Connecting our blog to the admin will allow us to see links for both the `Posts` and `Comments` inside the admin dashboard. As we’ve seen before, the dashboard currently just displays links for `Groups` and `Users`.

To do this, we need to register our `Posts` and `Comments` models inside of the admin file of `blogsite`.

Navigate to the `blogsite` directory:

    cd ~/my_blog_app/blog/blogsite

Then, create the `admin.py` file:

    touch admin.py

Once you’ve done that, open the file:

    nano admin.py

And edit the file so that it contains the following code.

admin.py

    from django.contrib import admin
    from blogsite.models import Post
    from blogsite.models import Comment
    
    
    admin.site.register(Post)
    admin.site.register(Comment)

Save and exit the file.

You have now registered the `Post` and `Comment` models inside of the admin panel. This will enable the admin interface to pick these models up and show it to the user that is logged into and viewing the admin dashboard.

## Step 6 — Verify that Blog App has Been Added to Admin

Now that you’ve added the relevant Python code, run the server. Open `http://your-server-ip:8000/admin` and log in to the admin using your credentials if you’re not logged in already. In this tutorial we’ve been logging in with the username `admin_user` and password `admin123`.

Now that you’ve logged in, you should see the following webpage when running the server.

![Django Admin Panel with Models Added](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/django-admin-models-added.png)

This shows that we have now connected our app, `blogsite`, to the Django admin dashboard.

When you are done with testing your app, you can press `CTRL` + `C` to stop the `runserver` command. This will return you to the your programming environment.

When you are ready to leave your Python environment, you can run the `deactivate` command:

    deactivate

Deactivating your programming environment will put you back to the terminal command prompt.

## Conclusion

In this tutorial, you have successfully enabled the admin interface, created an admin login, and registered the `Post` and `Comment` models with the admin.

The Django admin interface is how you will be able to create posts and monitor comments with your blog.

Coming up in the series, we will be creating the `views` for the blog application.
