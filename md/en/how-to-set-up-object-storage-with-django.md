---
author: Jeremy Morris
date: 2017-12-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-object-storage-with-django
---

# How To Set Up Object Storage with Django

## Introduction

DigitalOcean Spaces is an object storage solution, ideal for unstructured data such as audio, video, images or large amounts of text. To learn more about Spaces and object storage, you can read through [An Introduction to DigitalOcean Spaces](an-introduction-to-digitalocean-spaces).

In this tutorial, we will be covering how to setup your Django application to work with Spaces.

## Prerequisites

In order to begin this tutorial, you should have a few things set up:

- A non-root user account with `sudo` privileges set up on a Debian or Ubuntu Linux server. If you haven’t set this up already, follow the [initial server setup for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) or [Debian](initial-server-setup-with-debian-8) tutorial. 
- Additionally, you should create a DigitalOcean Space and generated an API key. For guidance on this, you can follow this [tutorial to create a Space and set up the API key](how-to-create-a-digitalocean-space-and-api-key).

With an initial server set up and a DigitalOcean Space and API key, you’re ready to begin.

## Step 1 — Set Up a Virtual Environment

If you haven’t already, first update and upgrade your server.

    sudo apt-get update && sudo apt-get -y upgrade

Your server should ship with Python 3, but you can run the following command to ensure that it is installed:

    sudo apt-get install python3

Next, install pip to manage software packages for Python:

    sudo apt-get install -y python3-pip

Finally, we can install the **virtualenv** module so we can use it to set up a programming environment:

    sudo pip3 install virtualenv

For additional guidance and information about programmig environments, you can read about [setting up a virtual environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server).

## Step 2 — Create Django App and Install Dependencies

We’ll now move on to creating the Django app that will be utilizing our DigitalOcean Space.

While in the server’s home directory, run the following command to create a directory (in this case, we’ll name it `django-apps`) to hold the project and navigate to the directory:

    mkdir django-apps
    cd django-apps

Within this directory, create a virtual environment with the following command. We’ll call it `env`, but you can call it whatever you would like.

    virtualenv env

You can now activate the environment and will receive feedback that you’re in the environment by the change in your command line’s prefix.

    . env/bin/activate

You will receive feedback that you’re in the environment by the change in your command line’s prefix. It will look something like this, but will change depending on what directory you are in:

    

Within the environment, install the Django package with pip so that we can create and run a Django app. To learn more about Django, read our tutorial series on [Django Development](https://www.digitalocean.com/community/tutorial_series/django-development).

    pip install django

Then create the project with the following command, in this case we’ll call it `mysite`.

    django-admin startproject mysite

Next we’ll install Boto 3, which is an [AWS SDK for Python](https://boto3.readthedocs.io/en/latest/) that will allow our application to interact with things like S3, EC2 and DigitalOcean Spaces. Because DigitalOcean Spaces is interoperable with Amazon S3, Spaces can interact with tools such as Boto 3 with ease. For more details on the comparison between S3 and Spaces please review the [Spaces docs](https://developers.digitalocean.com/documentation/spaces/).

    sudo pip install boto3

Another library that is crucial for our project is django-storages, which is [a collection of custom storage backends for Django](https://django-storages.readthedocs.io/en/latest/). We’ll also install this with pip.

    sudo pip install django-storages

You have setup your dependencies within the environment of your Django app and are now ready to set up static and template directories.

## Step 3 — Add Directories and Assets

With our environment set up with all dependencies, you can now switch to the `mysite/mysite` directory,

    cd ~/django-apps/mysite/mysite

Within the `mysite/mysite` directory, run the following commands to create the static and template directories.

    mkdir static && mkdir templates

We’ll next create the subdirectories for images and CSS to live within the `static` directory.

    mkdir static/img && mkdir static/css

Once you’ve made the directories, we’ll download a test file that we’ll eventually add to our object storage. Switch to the `img` directory since we’ll be downloading an image.

    cd ~/django-apps/mysite/mysite/static/img

Within this directory, we’ll download the DigitalOcean logo image using Wget’s `wget` command. This is a commonly used GNU program, preinstalled on Ubuntu distros, to retrieve content from web servers.

    wget http://assets.digitalocean.com/logos/DO_Logo_icon_blue.png

You’ll see the output similar to the following:

    OutputResolving www.digitalocean.com (www.digitalocean.com)... 104.16.24.4, 104.16.25.4
    Connecting to www.digitalocean.com (www.digitalocean.com)|104.16.24.4|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 1283 (1.3K) [image/png]
    Saving to: ‘DO_Logo_icon_blue.png’
    
    DO_Logo_icon_blue-6edd7377 100%[=====================================>] 1.25K --.-KB/s in 0s      
    
    2017-11-05 12:26:24 (9.60 MB/s) - ‘DO_Logo_icon_blue.png’ saved [1283/1283]

At this point, if you run the command `ls`, you’ll notice that an image named `DO_Logo_icon_blue.png` now exists in the `static/img/` directory.

With these directories set up and the image will be storing downloaded to the server, we can move on to editing the files associated with our Django app.

## Step 4 — Edit CSS and HTML Files

We’ll start by editing the style sheet. You should move into the `css` directory so that we can add a basic style sheet for our web app.

    cd ~/django-apps/mysite/mysite/static/css

Use nano, or another text editor of your choice, to edit the document.

    nano app.css

Once the file opens, add the following CSS:

app.css

    body {
      margin: 0;
      background-color: #f1f1f1;
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
    }
    
    .container {
      width: 80%;
      border: 1px solid #ddd;
      background-color: #fff;
      padding: 20px;
      margin: 40px auto;
    }
    
    form {
      margin-bottom: 20px;
      padding: 10px;
      border: 1px solid #ff9900;
      width: 350px;
    }
    
    table {
      border-collapse: collapse;
      width: 100%;
    }
    
    table td,
    table th {
      border: 1px solid #eceeef;
      padding: 5px 8px;
      text-align: left;
    }
    
    table thead {
      border-bottom: 2px solid #eceeef;
    }

Once you are finished, you can save and close the file. From here, navigate to the `templates` directory.

    cd ~/django-apps/mysite/mysite/templates

We need to open a file called `home.html` and add HTML into it for how our basic web app will be displayed. Using nano, open the file so it’s ready for editing:

    nano home.html

Within the document, add the following:

home.html

    {% load static %}
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Spaces + Django Tutorial</title>
      <link rel="stylesheet" type="text/css" href="{% static 'css/app.css' %}">
    </head>
    <body>
      <center>
      <header>
        <h1>Spaces + Django Tutorial</h1>
      </header>
      <main>
        <img src="{% static 'img/DO_Logo_icon_blue.png' %}">
        <h2>Congratulations, you’re using Spaces!</h2>
      </main>
      </center>
    </body>
    </html>

Save and close the file. The last file we will update is the `urls.py` file so that it points to your newly created `home.html` file. We need to move into the following directory:

    cd ~/django-apps/mysite/mysite

Use nano to edit the urls.py file.

    nano urls.py

You can delete everything in the file and then add the following:

urls.py

    from django.conf.urls import url
    from django.views.generic import TemplateView
    
    
    urlpatterns = [
        url(r'^$', TemplateView.as_view(template_name='home.html'), name='home'),
    ]
    

With these files set up, we can move on to editing our `settings.py` file in order to integrate it with object storage.

## Step 5 — Update Settings

Now it’s time to update your settings file with your Spaces credentials, so that we can take advantage of the page we’ve setup to display the image.

Keep in mind that in this example we will be hardcoding our credentials for brevity, but this is not secure enough for a production setup. It is recommended that you use a package like **[Python Decouple](https://pypi.python.org/pypi/python-decouple)** something like to mask your Spaces credentials. This package will separate the settings parameters from your source code, which is necessary for a production-grade Django application.

We’ll start by navigating to the location of your settings file.

    cd ~/django-apps/mysite/mysite

Open the file for editing, using nano:

    nano settings.py

Add your server ip as an allowed host.

settings.py

    ...
    ALLOWED_HOSTS = ['your-server-ip']
    ...

Then add `storages` to the installed apps section of the settings file and remove `django.contrib.admin` since we won’t be using that in this tutorial. It should look like the following.

settings.py

    ...
    # Application definition
    
    INSTALLED_APPS = [
        'django.contrib.auth',
        'django.contrib.contenttypes',
        'django.contrib.sessions',
        'django.contrib.messages',
        'django.contrib.staticfiles',
        'storages'
    ]
    ...

Replace and add the highlighted text to the `TEMPLATES` section of the settings file, so that the project knows where to locate your home.html file.

settings.py

    ...
    TEMPLATES = [
        {
            'BACKEND': 'django.template.backends.django.DjangoTemplates',
            'DIRS': [os.path.join(BASE_DIR, 'mysite/templates')],
            'APP_DIRS': True,
            'OPTIONS': {
                'context_processors': [
                    'django.template.context_processors.debug',
                    'django.template.context_processors.request',
                    'django.contrib.auth.context_processors.auth',
                    'django.contrib.messages.context_processors.messages',
                ],
            },
        },
    ]
    ...

Finally, let’s update your settings at the bottom of the file. We’ll be adding the following below the `# Static files` section. Be sure to add your own access keys, bucket name, and the directory you would like your files to live. You can add a directory through your Spaces interface in-browser. At the time of writing, NYC3 is the only region where Spaces currently are, so that is being passed as the endpoint URL.

settings.py

    ...
    # Static files (CSS, JavaScript, Images)
    # https://docs.djangoproject.com/en/1.11/howto/static-files/
    
    AWS_ACCESS_KEY_ID = 'your-spaces-access-key'
    AWS_SECRET_ACCESS_KEY = 'your-spaces-secret-access-key'
    AWS_STORAGE_BUCKET_NAME = 'your-storage-bucket-name'
    AWS_S3_ENDPOINT_URL = 'https://nyc3.digitaloceanspaces.com'
    AWS_S3_OBJECT_PARAMETERS = {
        'CacheControl': 'max-age=86400',
    }
    AWS_LOCATION = 'your-spaces-files-folder'
    
    STATICFILES_DIRS = [
        os.path.join(BASE_DIR, 'mysite/static'),
    ]
    STATIC_URL = 'https://%s/%s/' % (AWS_S3_ENDPOINT_URL, AWS_LOCATION)
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    

Now our settings file is ready to integrate our Django app with object storage.

## Step 6 — Collect Static Files

Now we’ll run `collectstatic` and you’ll notice files being transferred, including the image that we’ve saved in our static directory. It will get transferred to the Spaces location that we’ve identified in the settings file.

To accomplish this, let’s navigate to `~/django-apps/mysite/` :

    cd ~/django-apps/mysite

Within the directory, run the following command:

    python manage.py collectstatic

You’ll see the following output and should respond yes when prompted.

    OutputYou have requested to collect static files at the destination
    location as specified in your settings.
    
    This will overwrite existing files!
    Are you sure you want to do this?
    
    Type 'yes' to continue, or 'no' to cancel: 

Then you’ll see some more output telling you the file has been copied to Spaces.

    OutputCopying '/root/django-apps/mysite/mysite/static/css/app.css'
    
    1 static file copied, 1 unmodified.

At this point, if you return to your bucket from your DigitalOcean Cloud account, you’ll see the `css` and `img` directories added to the folder you pointed them to, with `app.css` in the `css` directory, and the `DO-Logo_icon_blue-.png` image in the `img` directory.

## Step 7 — Test the Application

With everything set up and our files in our object storage, we can now test our application by navigating to the page in which our static file is being served.

First, let’s ensure that our firewall will allow traffic to pass through port 8000 by issuing the following command:

    sudo ufw allow 8000

Now, we can run our server by referring to our server’s IP address and using port 8000.

    python manage.py runserver your-server-ip:8000

In a web browser, navigate to the `http://your-server-ip:8000` to see the result of the Django application you’ve created. You will see the following output in your browser:

![DigitalOcean Spaces Django Example App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/django/spaces-django.png)

When you are done with testing your app, you can press `CTRL` + `C` to stop the `runserver` command. This will return you to the your programming environment.

When you are ready to leave your Python environment, you can run the `deactivate` command:

    deactivate

Deactivating your programming environment will put you back to the terminal command prompt.

### Conclusion

In this tutorial you have successfully created a Django application that serves files from DigitalOcean Spaces. In the process you’ve learned about static files, how to manage static files and how to serve them from a cloud service.

You can continue learning about web development with Python and Django by reading our tutorial series on [Django Development](https://www.digitalocean.com/community/tutorial_series/django-development).
