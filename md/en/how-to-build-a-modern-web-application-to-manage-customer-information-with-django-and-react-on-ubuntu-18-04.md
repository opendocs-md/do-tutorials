---
author: Ahmed Bouchefra
date: 2018-10-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-a-modern-web-application-to-manage-customer-information-with-django-and-react-on-ubuntu-18-04
---

# How To Build a Modern Web Application to Manage Customer Information with Django and React on Ubuntu 18.04

_The author selected [Open Sourcing Mental Illness Ltd](https://www.brightfunds.org/organizations/open-sourcing-mental-illness-ltd) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

People use different types of devices to connect to the internet and browse the Web. Because of this, applications need to be accessible from a variety of locations. For traditional websites, having a responsive UI is usually enough, but more complex applications often require the use of other techniques and architectures. These include having separate REST back-end and front-end applications that can be implemented as client-side web applications, Progressive Web Apps (PWAs), or native mobile apps.

Some tools that you can use when building more complex applications include:

- [React](https://reactjs.org/), a JavaScript framework that allows developers to build web and native frontends for their REST API backends.
- [Django](https://www.djangoproject.com/), a free and open-source Python web framework that follows the [_model view controller (MVC)_](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) software architectural pattern. 
- [Django REST framework](http://www.django-rest-framework.org/), a powerful and flexible toolkit for building REST APIs in Django.

In this tutorial, you will build a modern web application with a separate REST API backend and frontend using React, Django, and the Django REST Framework. By using React with Django, you’ll be able to benefit from the latest advancements in JavaScript and front-end development. Instead of building a Django application that uses a built-in template engine, you will use React as a UI library, taking advantage of its virtual Document Object Model (DOM), declarative approach, and components that quickly render changes in data.

The web application you will build stores records about customers in a database, and you can use it as a starting point for a CRM application. When you are finished you’ll be able to create, read, update, and delete records using a React interface styled with [Bootstrap 4](https://getbootstrap.com/).

## Prerequisites

To complete this tutorial, you will need:

- A development machine with Ubuntu 18.04.
- Python 3, `pip`, and `venv` installed on your machine by following Steps 1 and 2 of [How To Install Python 3 and Set Up a Local Programming Environment on Ubuntu 18.04](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-18-04).
- Node.js 6+ and `npm` 5.2 or higher installed on your machine. You can install both of them by following the instructions in [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa) on installing from a PPA.

## Step 1 — Creating a Python Virtual Environment and Installing Dependencies

In this step, we’ll create a virtual environment and install the required dependencies for our application, including Django, the Django REST framework, and `django-cors-headers`.

Our application will use two different development servers for Django and React. They will run on different ports and will function as two separate domains. Because of this, we need to enable [_cross-origin resource sharing (CORS)_](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) to send HTTP requests from React to Django without being blocked by the browser.

Navigate to your home directory and create a virtual environment using the `venv` Python 3 module:

    cd ~
    python3 -m venv ./env

Activate the created virtual environment using `source`:

    source env/bin/activate

Next, install the project’s dependencies with `pip`. These will include:

- **Django** : The web framework for the project. 
- **Django REST framework** : A third-party application that builds REST APIs with Django. 
- **`django-cors-headers`** : A package that enables CORS. 

Install the Django framework:

    pip install django djangorestframework django-cors-headers

With the project dependencies installed, you can create the Django project and the React frontend.

## Step 2 — Creating the Django Project

In this step, we’ll generate the Django project using the following commands and utilities:

- **`django-admin startproject project-name`** : [`django-admin`](https://docs.djangoproject.com/en/2.0/ref/contrib/admin/#) is a command-line utility used to accomplish tasks with Django. The `startproject` command creates a new Django project.

- **`python manage.py startapp myapp`** : `manage.py` is a utility script, automatically added to each Django project, that performs a number of administrative tasks: creating new applications, migrating the database, and serving the Django project locally. Its `startapp` command creates a Django application inside the Django project. In Django, the term _application_ describes a Python package that provides some set of features in a project. 

To begin, create the Django project with `django-admin startproject`. We will call our project `djangoreactproject`:

    django-admin startproject djangoreactproject 

Before moving on, let’s look at the directory structure of our Django project using the `tree` command.

**Tip:** `tree` is a useful command for viewing file and directory structures from the command line. You can install it with the following command:

    sudo apt-get install tree

To use it, `cd` into the directory you want and type `tree` or provide the path to the starting point with `tree /home/sammy/sammys-project`.

Navigate to the `djangoreactproject` folder within your project root and run the `tree` command:

    cd ~/djangoreactproject
    tree

You will see the following output:

    Output├── djangoreactproject
    │ ├── __init__.py
    │ ├── settings.py
    │ ├── urls.py
    │ └── wsgi.py
    └── manage.py

The `~/djangoreactproject` folder is the root of the project. Within this folder, there are several files that will be important to your work:

- **`manage.py`** : The utility script that does a number of administrative tasks. 
- **`settings.py`** : The main configuration file for the Django project where you can modify the project’s settings. These settings include variables such as `INSTALLED_APPS`, a [list](understanding-lists-in-python-3) of strings designating the enabled applications for your project. The Django documentation has more information about [available settings](https://docs.djangoproject.com/en/2.0/ref/settings/). 
- **`urls.py`** : This file contains a list of URL patterns and related views. Each pattern maps a connection between a URL and the function that should be called for that URL. For more on URLs and views, please refer to our tutorial on [How To Create Django Views](how-to-create-django-views).

Our first step in working with the project will be to configure the packages we installed in the previous step, including the Django REST framework and the Django CORS package, by adding them to `settings.py`. Open the file with `nano` or your favorite editor:

    nano ~/djangoreactproject/djangoreactproject/settings.py

Navigate to the `INSTALLED_APPS` setting and add the `rest_framework` and `corsheaders` applications to the bottom of the list:

~/djangoreactproject/djangoreactproject/settings.py

    ...
    INSTALLED_APPS = [
        'django.contrib.admin',
        'django.contrib.auth',
        'django.contrib.contenttypes',
        'django.contrib.sessions',
        'django.contrib.messages',
        'django.contrib.staticfiles',
        'rest_framework',
        'corsheaders'
    ]

Next, add the `corsheaders.middleware.CorsMiddleware` middleware from the previously installed CORS package to the `MIDDLEWARE` setting. This setting is a list of _middlewares_, a Python class that contains code processed each time your web application handles a request or response:

~/djangoreactproject/djangoreactproject/settings.py

    ...
    
    MIDDLEWARE = [
    ...
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'corsheaders.middleware.CorsMiddleware'
    ]

Next, you can enable CORS. The `CORS_ORIGIN_ALLOW_ALL` setting specifies whether or not you want to allow CORS for all domains, and `CORS_ORIGIN_WHITELIST` is a Python tuple that contains allowed URLs. In our case, because the React development server will be running at `http://localhost:3000`, we will add new `CORS_ORIGIN_ALLOW_ALL = False` and `CORS_ORIGIN_WHITELIST('localhost:3000',)` settings to our `settings.py` file. Add these settings anywhere in the file:

~/djangoreactproject/djangoreactproject/settings.py

    
    ...
    CORS_ORIGIN_ALLOW_ALL = False
    
    CORS_ORIGIN_WHITELIST = (
           'localhost:3000',
    )
    ...

You can find more configuration options in the [`django-cors-headers` docs](https://github.com/ottoyiu/django-cors-headers/#configuration).

Save the file and exit the editor when you are finished.

Still in the `~/djangoreactproject` directory, make a new Django application called `customers`:

    python manage.py startapp customers

This will contain the [models](how-to-create-django-models) and [views](how-to-create-django-views) for managing customers. Models define the fields and behaviors of our application data, while views enable our application to properly handle web requests and return the required responses.

Next, add this application to the list of installed applications in your project’s `settings.py` file so Django will recognize it as part of the project. Open `settings.py` again:

    nano ~/djangoreactproject/djangoreactproject/settings.py

Add the `customers` application:

~/djangoreactproject/djangoreactproject/settings.py

    ...
    INSTALLED_APPS = [
        ...
        'rest_framework',
        'corsheaders',
        'customers'
    ]
    ...

Next, _migrate_ the database and start the local development server. [Migrations](https://docs.djangoproject.com/en/2.0/topics/migrations/) are Django’s way of propagating the changes you make to your models into your database schema. These changes can include things like adding a field or deleting a model, for example. For more on models and migrations, see [How To Create Django Models](how-to-create-django-models).

Migrate the database:

    python manage.py migrate

Start the local development server:

    python manage.py runserver

You will see output similar to the following:

    OutputPerforming system checks...
    
    System check identified no issues (0 silenced).
    October 22, 2018 - 15:14:50
    Django version 2.1.2, using settings 'djangoreactproject.settings'
    Starting development server at http://127.0.0.1:8000/
    Quit the server with CONTROL-C.

Your web application will be running from `http://127.0.0.1:8000`. If you navigate to this address in your web browser you should see the following page:

![Django demo page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_react_1604/django_home.png)

At this point, leave the application running and open a new terminal to continue developing the project.

## Step 3 — Creating the React Frontend

In this section, we’re going to create the front-end application of our project using React.

React has an official utility that allows you to quickly generate React projects without having to configure [Webpack](https://webpack.js.org/) directly. Webpack is a module bundler used to bundle web assets such as JavaScript code, CSS, and images. Typically, before you can use Webpack you need to set various configuration options, but thanks to the `create-react-app` utility you don’t have to deal with Webpack directly until you decide you need more control. To run `create-react-app` you can use [npx](https://github.com/zkat/npx), a tool that executes `npm` package binaries.

In your second terminal, make sure you are in your project directory:

    cd ~/djangoreactproject

Create a React project called `frontend` using `create-react-app` and `npx`:

    npx create-react-app frontend

Next, navigate inside your React application and start the development server:

    cd ~/djangoreactproject/frontend
    npm start

You application will be running from `http://localhost:3000/`:

![React demo page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_react_1604/react_home.png)

Leave the React development server running and open another terminal window to proceed.

To see the directory structure of the entire project at this point, navigate to the root folder and run `tree` again:

    cd ~/djangoreactproject
    tree

You’ll see a structure like this:

    Output├── customers
    │ ├── admin.py
    │ ├── apps.py
    │ ├── __init__.py
    │ ├── migrations
    │ │ └── __init__.py
    │ ├── models.py
    │ ├── tests.py
    │ └── views.py
    ├── djangoreactproject
    │ ├── __init__.py
    │ ├── __pycache__
    │ ├── settings.py
    │ ├── urls.py
    │ └── wsgi.py
    ├── frontend
    │ ├── package.json
    │ ├── public
    │ │ ├── favicon.ico
    │ │ ├── index.html
    │ │ └── manifest.json
    │ ├── README.md
    │ ├── src
    │ │ ├── App.css
    │ │ ├── App.js
    │ │ ├── App.test.js
    │ │ ├── index.css
    │ │ ├── index.js
    │ │ ├── logo.svg
    │ │ └── registerServiceWorker.js
    │ └── yarn.lock
    └── manage.py

Our application will use Bootstrap 4 to style the React interface, so we will include it in the `frontend/src/App.css` file, which manages our CSS settings. Open the file:

    nano ~/djangoreactproject/frontend/src/App.css

Add the following [_import_](how-to-import-modules-in-python-3#importing-modules) to the beginning of the file. You can delete the file’s existing content, though that’s not required:

~/djangoreactproject/frontend/src/App.css

    @import 'https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css';

Here, `@import` is a CSS instruction that’s used to import style rules from other style sheets.

Now that we have created both the back-end and front-end applications, let’s create the Customer model and some demo data.

## Step 4 — Creating the Customer Model and Initial Data

After creating the Django application and the React frontend, our next step will be to create the Customer model, which represents the database table that will hold information about customers. You don’t need any SQL since the Django _Object Relational Mapper (ORM)_ will handle database operations by mapping Python classes and variables to SQL tables and columns. In this way the Django ORM abstracts SQL interactions with the database through a Python interface.

Activate your virtual environment again:

    cd ~
    source env/bin/activate

Move to the `customers` directory, and open `models.py`, a Python file that holds the models of your application:

    cd ~/djangoreactproject/customers/
    nano models.py

The file will contain the following content:

~/djangoreactproject/customers/models.py

    from django.db import models
    # Create your models here.

The Customer model’s API is already imported in the file thanks to the `from django.db import models` import statement. You will now add the `Customer` class, which extends `models.Model`. Each model in Django is a Python class that extends [`django.db.models.Model`](https://docs.djangoproject.com/en/2.0/ref/models/instances/#django.db.models.Model).

The `Customer` model will have these database fields:

- **`first_name`** — The first name of the customer.
- **`last_name`** — The last name of the customer.
- **`email`** — The email address of the customer. 
- **`phone`** — The phone number of the customer.
- **`address`** — The address of the customer.
- **`description`** — The description of the customer.
- **`createdAt`** — The date when the customer is added. 

We will also add the ` __str__ ()` function, which defines how the model will be displayed. In our case, it will be with the customer’s first name. For more on constructing classes and defining objects, please see [How To Construct Classes and Define Objects in Python 3](how-to-construct-classes-and-define-objects-in-python-3).

Add the following code to the file:

~/djangoreactproject/customers/models.py

    from django.db import models
    
    class Customer(models.Model):
        first_name = models.CharField("First name", max_length=255)
        last_name = models.CharField("Last name", max_length=255)
        email = models.EmailField()
        phone = models.CharField(max_length=20)
        address = models.TextField(blank=True, null=True)
        description = models.TextField(blank=True, null=True)
        createdAt = models.DateTimeField("Created At", auto_now_add=True)
    
        def __str__ (self):
            return self.first_name

Next, migrate the database to create the database tables. The [`makemigrations`](how-to-create-django-models#step-4-%E2%80%94-make-migrations) command creates the migration files where model changes will be added, and `migrate` applies the changes in the migrations files to the database.

Navigate back to the project’s root folder:

    cd ~/djangoreactproject

Run the following to create the migration files:

    python manage.py makemigrations

You will get output that looks like this:

    Outputcustomers/migrations/0001_initial.py
        - Create model Customer

Apply these changes to the database:

    python manage.py migrate

You will see output indicating a successful migration:

    OutputOperations to perform:
      Apply all migrations: admin, auth, contenttypes, customers, sessions
    Running migrations:
      Applying customers.0001_initial... OK

Next, you will use a _data migration file_ to create initial customer data. A [data migration file](https://docs.djangoproject.com/en/2.0/topics/migrations/#data-migrations) is a migration that adds or alters data in the database. Create an empty data migration file for the `customers` application:

    python manage.py makemigrations --empty --name customers customers

You will see the following confirmation with the name of your migration file:

    OutputMigrations for 'customers':
      customers/migrations/0002_customers.py

Note that the name of your migration file is `0002_customers.py`.

Next, navigate inside the migrations folder of the `customers` application:

    cd ~/djangoreactproject/customers/migrations

Open the created migration file:

    nano 0002_customers.py

This is the initial content of the file:

~/djangoreactproject/customers/migrations/0002\_customers.py

    from django.db import migrations
    
    class Migration(migrations.Migration):
        dependencies = [
            ('customers', '0001_initial'),
        ]
        operations = [
        ]        

The import statement imports the `migrations` API, a Django API for creating migrations, from `django.db`, a built-in package that contains classes for working with databases.

The `Migration` class is a Python class that describes the operations that are executed when migrating databases. This class extends `migrations.Migration` and has two lists:

- **`dependencies`** : Contains the dependent migrations.
- **`operations`** : Contains the operations that will be executed when we apply the migration.

Next, add a [method](how-to-define-functions-in-python-3) to create demo customer data. Add the following method before the definition of the `Migration` class:

~/djangoreactproject/customers/migrations/0002\_customers.py

    ...
    def create_data(apps, schema_editor):
        Customer = apps.get_model('customers', 'Customer')
        Customer(first_name="Customer 001", last_name="Customer 001", email="customer001@email.com", phone="00000000", address="Customer 000 Address", description= "Customer 001 description").save()
    
    ...

In this method, we are grabbing the `Customer` class of our `customers` app and creating a demo customer to insert into the database.

To get the `Customer` class, which will enable the creation of new customers, we use the `get_model()` method of the `apps` object. The `apps` object represents the [registry](https://docs.djangoproject.com/en/2.1/ref/applications/#django.apps.apps) of installed applications and their database models.

The `apps` object will be passed from the `RunPython()` method when we use it to run `create_data()`. Add the `migrations.RunPython()` method to the empty `operations` list:

~/djangoreactproject/customers/migrations/0002\_customers.py

    
    ...
        operations = [
            migrations.RunPython(create_data),
        ]  

`RunPython()` is part of the Migrations API that allows you to run custom Python code in a migration. Our `operations` list specifies that this method will be executed when we apply the migration.

This is the complete file:

~/djangoreactproject/customers/migrations/0002\_customers.py

    from django.db import migrations
    
    def create_data(apps, schema_editor):
        Customer = apps.get_model('customers', 'Customer')
        Customer(first_name="Customer 001", last_name="Customer 001", email="customer001@email.com", phone="00000000", address="Customer 000 Address", description= "Customer 001 description").save()
    
    class Migration(migrations.Migration):
        dependencies = [
            ('customers', '0001_initial'),
        ]
        operations = [
            migrations.RunPython(create_data),
        ]        

For more information on data migrations, see the documentation on [data migrations in Django](https://docs.djangoproject.com/en/2.0/topics/migrations/#data-migrations)

To migrate your database, first navigate back to the root folder of your project:

    cd ~/djangoreactproject

Migrate your database to create the demo data:

    python manage.py migrate

You will see output that confirms the migration:

    OutputOperations to perform:
      Apply all migrations: admin, auth, contenttypes, customers, sessions
    Running migrations:
      Applying customers.0002_customers... OK

For more details on this process, refer back to [How To Create Django Models](how-to-create-django-models).

With the Customer model and demo data created, we can move on to building the REST API.

## Step 5 — Creating the REST API

In this step we’ll create the REST API using the Django REST Framework. We’ll create several different _API views_. An API view is a function that handles an API request or call, while an _API endpoint_ is a unique URL that represents a touchpoint with the REST system. For example, when the user sends a GET request to an API endpoint, Django calls the corresponding function or API view to handle the request and return any possible results.

We’ll also make use of [serializers](http://www.django-rest-framework.org/api-guide/serializers/). A [serializer](https://docs.djangoproject.com/en/2.0/topics/serialization/) in the Django REST Framework allows complex model instances and QuerySets to be converted into JSON format for API consumption. The serializer class can also work in the other direction, providing mechanisms for parsing and deserializing data into Django models and QuerySets.

Our API endpoints will include:

- `api/customers`: This endpoint is used to create customers and returns paginated sets of customers.
- `api/customers/<pk>`: This endpoint is used to get, update, and delete single customers by primary key or id. 

We’ll also create URLs in the project’s `urls.py` file for the corresponding endpoints (i.e `api/customers` and `api/customers/<pk>`).

Let’s start by creating the _serializer class_ for our `Customer` model.

### Adding the Serializer Class

Creating a serializer class for our `Customer` model is necessary for transforming customer instances and QuerySets to and from JSON. To create the serializer class, first make a `serializers.py` file inside the `customers` application:

    cd ~/djangoreactproject/customers/
    nano serializers.py

Add the following code to import the serializers API and `Customer` model:

~/djangoreactproject/customers/serializers.py

    from rest_framework import serializers
    from .models import Customer

Next, create a serializer class that extends `serializers.ModelSerializer` and specifies the fields that will be serialized:

~/djangoreactproject/customers/serializers.py

    
    ...
    class CustomerSerializer(serializers.ModelSerializer):
    
        class Meta:
            model = Customer 
            fields = ('pk','first_name', 'last_name', 'email', 'phone','address','description')

The `Meta` class specifies the model and fields to serialize: `pk`,`first_name`, `last_name`, `email`, `phone`, `address`,`description`.

This is the full content of the file:

~/djangoreactproject/customers/serializers.py

    from rest_framework import serializers
    from .models import Customer
    
    class CustomerSerializer(serializers.ModelSerializer):
    
        class Meta:
            model = Customer 
            fields = ('pk','first_name', 'last_name', 'email', 'phone','address','description')

Now that we’ve created our serializer class, we can add the API views.

### Adding the API Views

In this section, we’ll create the API views for our application that will be called by Django when the user visits the endpoint corresponding to the view function.

Open `~/djangoreactproject/customers/views.py`:

    nano ~/djangoreactproject/customers/views.py

Delete what’s there and add the following imports:

~/djangoreactproject/customers/views.py

    from rest_framework.response import Response
    from rest_framework.decorators import api_view
    from rest_framework import status
    
    from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
    from .models import Customer 
    from .serializers import *

We are importing the serializer we created, along with the `Customer` model and the Django and Django REST Framework APIs.

Next, add the view for processing POST and GET HTTP requests:

~/djangoreactproject/customers/views.py

    ...
    
    @api_view(['GET', 'POST'])
    def customers_list(request):
        """
     List customers, or create a new customer.
     """
        if request.method == 'GET':
            data = []
            nextPage = 1
            previousPage = 1
            customers = Customer.objects.all()
            page = request.GET.get('page', 1)
            paginator = Paginator(customers, 10)
            try:
                data = paginator.page(page)
            except PageNotAnInteger:
                data = paginator.page(1)
            except EmptyPage:
                data = paginator.page(paginator.num_pages)
    
            serializer = CustomerSerializer(data,context={'request': request} ,many=True)
            if data.has_next():
                nextPage = data.next_page_number()
            if data.has_previous():
                previousPage = data.previous_page_number()
    
            return Response({'data': serializer.data , 'count': paginator.count, 'numpages' : paginator.num_pages, 'nextlink': '/api/customers/?page=' + str(nextPage), 'prevlink': '/api/customers/?page=' + str(previousPage)})
    
        elif request.method == 'POST':
            serializer = CustomerSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

First we use the `@api_view(['GET', 'POST'])` decorator to create an API view that can accept GET and POST requests. A [decorator](https://wiki.python.org/moin/PythonDecorators) is a function that takes another function and dynamically extends it.

In the method body we use the `request.method` variable to check the current HTTP method and execute the corresponding logic depending on the request type:

- If it’s a GET request, the method paginates the data using Django [Paginator](https://docs.djangoproject.com/en/2.0/topics/pagination/), and returns the first page of data after serialization, the count of available customers, the number of available pages, and the links to the previous and next pages. Paginator is a built-in Django class that paginates a list of data into pages and provides methods to access the items for each page. 
- If it’s a POST request, the method serializes the received customer data and then calls the `save()` method of the serializer object. It then returns a Response object, an instance of [HttpResponse](https://docs.djangoproject.com/en/2.0/ref/request-response/#httpresponse-objects), with a 201 status code. Each view you create is responsible for returing an `HttpResponse` object. The `save()` method saves the serialized data in the database.

For more about `HttpResponse` and views, see this discussion of [creating view functions](how-to-create-django-views#step-1-%E2%80%94-create-view-functions).

Now add the API view that will be responsible for processing the GET, PUT, and DELETE requests for getting, updating, and deleting customers by `pk` (primary key):

~/djangoreactproject/customers/views.py

    
    ...
    @api_view(['GET', 'PUT', 'DELETE'])
    def customers_detail(request, pk):
     """
     Retrieve, update or delete a customer by id/pk.
     """
        try:
            customer = Customer.objects.get(pk=pk)
        except Customer.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    
        if request.method == 'GET':
            serializer = CustomerSerializer(customer,context={'request': request})
            return Response(serializer.data)
    
        elif request.method == 'PUT':
            serializer = CustomerSerializer(customer, data=request.data,context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
        elif request.method == 'DELETE':
            customer.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)

The method is decorated with `@api_view(['GET', 'PUT', 'DELETE'])` to denote that it’s an API view that can accept GET, PUT, and DELETE requests.

The check in the `request.method` field verifies the request method, and depending on its value calls the right logic:

- If it’s a GET request, customer data is serialized and sent using a Response object.
- If it’s a PUT request, the method creates a serializer for new customer data. Next, it calls the `save()` method of the created serializer object. Finally, it sends a Response object with the updated customer. 
- If it’s a DELETE request, the method calls the `delete()` method of the customer object to delete it, then returns a Response object with no data.  

The completed file looks like this:

~/djangoreactproject/customers/views.py

    from rest_framework.response import Response
    from rest_framework.decorators import api_view
    from rest_framework import status
    
    from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
    from .models import Customer 
    from .serializers import *
    
    
    @api_view(['GET', 'POST'])
    def customers_list(request):
        """
     List customers, or create a new customer.
     """
        if request.method == 'GET':
            data = []
            nextPage = 1
            previousPage = 1
            customers = Customer.objects.all()
            page = request.GET.get('page', 1)
            paginator = Paginator(customers, 5)
            try:
                data = paginator.page(page)
            except PageNotAnInteger:
                data = paginator.page(1)
            except EmptyPage:
                data = paginator.page(paginator.num_pages)
    
            serializer = CustomerSerializer(data,context={'request': request} ,many=True)
            if data.has_next():
                nextPage = data.next_page_number()
            if data.has_previous():
                previousPage = data.previous_page_number()
    
            return Response({'data': serializer.data , 'count': paginator.count, 'numpages' : paginator.num_pages, 'nextlink': '/api/customers/?page=' + str(nextPage), 'prevlink': '/api/customers/?page=' + str(previousPage)})
    
        elif request.method == 'POST':
            serializer = CustomerSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @api_view(['GET', 'PUT', 'DELETE'])
    def customers_detail(request, pk):
        """
     Retrieve, update or delete a customer by id/pk.
     """
        try:
            customer = Customer.objects.get(pk=pk)
        except Customer.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)
    
        if request.method == 'GET':
            serializer = CustomerSerializer(customer,context={'request': request})
            return Response(serializer.data)
    
        elif request.method == 'PUT':
            serializer = CustomerSerializer(customer, data=request.data,context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
        elif request.method == 'DELETE':
            customer.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)

We can now move on to creating our endpoints.

### Adding API Endpoints

We will now create the API endpoints: `api/customers/`, for querying and creating customers, and `api/customers/<pk>`, for getting, updating, or deleting single customers by their `pk`.

Open `~/djangoreactproject/djangoreactproject/urls.py`:

    nano ~/djangoreactproject/djangoreactproject/urls.py

Leave what’s there, but add the import to the `customers` views at the top of the file:

~/djangoreactproject/djangoreactproject/urls.py

    from django.contrib import admin
    from django.urls import path
    from customers import views
    from django.conf.urls import url

Next, add the `api/customers/` and `api/customers/<pk>` URLs to the [`urlpatterns` list](how-to-create-django-views#step-2-%E2%80%94-map-urls-to-views) that contains the application’s URLs:

~/djangoreactproject/djangoreactproject/urls.py

    ...
    
    urlpatterns = [
        path('admin/', admin.site.urls),
        url(r'^api/customers/$', views.customers_list),
        url(r'^api/customers/(?P<pk>[0-9]+)$', views.customers_detail),
    ]

With our REST endpoints created, let’s see how we can consume them.

## Step 6 — Consuming the REST API with Axios

In this step, we’ll install [Axios](https://github.com/axios/axios), the HTTP client we’ll use to make API calls. We’ll also create a class to consume the API endpoints we’ve created.

First, deactivate your virtual environment:

    deactivate

Next, navigate to your `frontend` folder:

    cd ~/djangoreactproject/frontend

Install `axios` from `npm` using:

    npm install axios --save

The `--save` option adds the `axios` dependency to your application’s `package.json` file.

Next, create a JavaScript file called `CustomersService.js`, which will contain the code to call the REST APIs. We’ll make this inside the `src` folder, where the application code for our project will live:

    cd src
    nano CustomersService.js

Add the following code, which contains methods to connect to the Django REST API:

~/djangoreactproject/frontend/src/CustomersService.js

    import axios from 'axios';
    const API_URL = 'http://localhost:8000';
    
    export default class CustomersService{
    
        constructor(){}
    
    
        getCustomers() {
            const url = `${API_URL}/api/customers/`;
            return axios.get(url).then(response => response.data);
        }  
        getCustomersByURL(link){
            const url = `${API_URL}${link}`;
            return axios.get(url).then(response => response.data);
        }
        getCustomer(pk) {
            const url = `${API_URL}/api/customers/${pk}`;
            return axios.get(url).then(response => response.data);
        }
        deleteCustomer(customer){
            const url = `${API_URL}/api/customers/${customer.pk}`;
            return axios.delete(url);
        }
        createCustomer(customer){
            const url = `${API_URL}/api/customers/`;
            return axios.post(url,customer);
        }
        updateCustomer(customer){
            const url = `${API_URL}/api/customers/${customer.pk}`;
            return axios.put(url,customer);
        }
    }

The `CustomersService` class will call the following Axios methods:

- `getCustomers()`: Gets first page of customers.
- `getCustomersByURL()`: Gets customers by URL. This makes it possible to get the next pages of customers by passing links such as `/api/customers/?page=2`. 
- `getCustomer()`: Gets a customer by primary key.
- `createCustomer()`: Creates a customer.
- `updateCustomer()`: Updates a customer.
- `deleteCustomer()`: Deletes a customer.

We can now display the data from our API in our React UI interface by creating a `CustomersList` component.

## Step 7 — Displaying Data from the API in the React Application

In this step, we’ll create the `CustomersList` React _component_. A React component represents a part of the UI; it also lets you split the UI into independent, reusable pieces.

Begin by creating `CustomersList.js` in `frontend/src`:

    nano ~/djangoreactproject/frontend/src/CustomersList.js

Start by importing `React` and `Component` to create a React component:

~/djangoreactproject/frontend/src/CustomersList.js

    import React, { Component } from 'react';

Next, import and instantiate the `CustomersService` module you created in the previous step, which provides methods that interface with the REST API backend:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    import CustomersService from './CustomersService';
    
    const customersService = new CustomersService();

Next, create a `CustomersList` component that extends `Component` to call the REST API. A React component should [extend or subclass the `Component` class](https://reactjs.org/docs/react-component.html). For more about E6 classes and inheritence, please see our tutorial on [Understanding Classes in JavaScript](understanding-classes-in-javascript).

Add the following code to create a React component that extends `react.Component`:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    class CustomersList extends Component {
    
        constructor(props) {
            super(props);
            this.state = {
                customers: [],
                nextPageURL: ''
            };
            this.nextPage = this.nextPage.bind(this);
            this.handleDelete = this.handleDelete.bind(this);
        }
    }
    export default CustomersList;

Inside the [constructor](https://reactjs.org/docs/react-component.html#constructor), we are initializing the [`state`](https://reactjs.org/docs/react-component.html#state) object. This holds the state variables of our component using an empty `customers` [array](https://www.digitalocean.com/community/tutorial_series/working-with-arrays-in-javascript). This array will hold customers and a `nextPageURL` that will hold the URL of the next page to retrieve from the back-end API. We are also [binding](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_objects/Function/bind) the `nextPage()` and `handleDelete()` [methods](understanding-classes-in-javascript#defining-methods) to `this` so they will be accessible from the HTML code.

Next, add the `componentDidMount()` method and a call to `getCustomers()` within the `CustomersList` class, before the closing curly brace.

The `componentDidMount()` method is a lifecycle method of the component that is called when the component is created and inserted into the DOM. `getCustomers()` calls the Customers Service object to get the first page of data and the link of the next page from the Django backend:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    componentDidMount() {
        var self = this;
        customersService.getCustomers().then(function (result) {
            self.setState({ customers: result.data, nextPageURL: result.nextlink})
        });
    }

Now add the `handleDelete()` method, which handles deleting a customer, below `componentDidMount()`:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    handleDelete(e,pk){
        var self = this;
        customersService.deleteCustomer({pk : pk}).then(()=>{
            var newArr = self.state.customers.filter(function(obj) {
                return obj.pk !== pk;
            });
            self.setState({customers: newArr})
        });
    }

The `handleDelete()` method calls the `deleteCustomer()` method to delete a customer using its `pk` (primary key). If the operation is successful, the `customers` array is filtered out for the removed customer.

Next, add a `nextPage()` method to get the data for the next page and update the next page link:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    nextPage(){
        var self = this;
        customersService.getCustomersByURL(this.state.nextPageURL).then((result) => {
            self.setState({ customers: result.data, nextPageURL: result.nextlink})
        });
    }

The `nextPage()` method calls a `getCustomersByURL()` method, which takes the next page URL from the state object, `this.state.nextPageURL`, and updates the `customers` array with the returned data.

Finally, add the component [`render()` method](https://reactjs.org/docs/react-component.html#render), which renders a table of customers from the component state:

~/djangoreactproject/frontend/src/CustomersList.js

    
    ...
    render() {
    
        return (
        <div className="customers--list">
            <table className="table">
                <thead key="thead">
                <tr>
                    <th>#</th>
                    <th>First Name</th>
                    <th>Last Name</th>
                    <th>Phone</th>
                    <th>Email</th>
                    <th>Address</th>
                    <th>Description</th>
                    <th>Actions</th>
                </tr>
                </thead>
                <tbody>
                    {this.state.customers.map( c =>
                    <tr key={c.pk}>
                        <td>{c.pk} </td>
                        <td>{c.first_name}</td>
                        <td>{c.last_name}</td>
                        <td>{c.phone}</td>
                        <td>{c.email}</td>
                        <td>{c.address}</td>
                        <td>{c.description}</td>
                        <td>
                        <button onClick={(e)=> this.handleDelete(e,c.pk) }> Delete</button>
                        <a href={"/customer/" + c.pk}> Update</a>
                        </td>
                    </tr>)}
                </tbody>
            </table>
            <button className="btn btn-primary" onClick= { this.nextPage }>Next</button>
        </div>
        );
    }

This is the full content of the file:

~/djangoreactproject/frontend/src/CustomersList.js

    import React, { Component } from 'react';
    import CustomersService from './CustomersService';
    
    const customersService = new CustomersService();
    
    class CustomersList extends Component {
    
    constructor(props) {
        super(props);
        this.state = {
            customers: [],
            nextPageURL: ''
        };
        this.nextPage = this.nextPage.bind(this);
        this.handleDelete = this.handleDelete.bind(this);
    }
    
    componentDidMount() {
        var self = this;
        customersService.getCustomers().then(function (result) {
            console.log(result);
            self.setState({ customers: result.data, nextPageURL: result.nextlink})
        });
    }
    handleDelete(e,pk){
        var self = this;
        customersService.deleteCustomer({pk : pk}).then(()=>{
            var newArr = self.state.customers.filter(function(obj) {
                return obj.pk !== pk;
            });
    
            self.setState({customers: newArr})
        });
    }
    
    nextPage(){
        var self = this;
        console.log(this.state.nextPageURL);        
        customersService.getCustomersByURL(this.state.nextPageURL).then((result) => {
            self.setState({ customers: result.data, nextPageURL: result.nextlink})
        });
    }
    render() {
    
        return (
            <div className="customers--list">
                <table className="table">
                <thead key="thead">
                <tr>
                    <th>#</th>
                    <th>First Name</th>
                    <th>Last Name</th>
                    <th>Phone</th>
                    <th>Email</th>
                    <th>Address</th>
                    <th>Description</th>
                    <th>Actions</th>
                </tr>
                </thead>
                <tbody>
                {this.state.customers.map( c =>
                    <tr key={c.pk}>
                    <td>{c.pk} </td>
                    <td>{c.first_name}</td>
                    <td>{c.last_name}</td>
                    <td>{c.phone}</td>
                    <td>{c.email}</td>
                    <td>{c.address}</td>
                    <td>{c.description}</td>
                    <td>
                    <button onClick={(e)=> this.handleDelete(e,c.pk) }> Delete</button>
                    <a href={"/customer/" + c.pk}> Update</a>
                    </td>
                </tr>)}
                </tbody>
                </table>
                <button className="btn btn-primary" onClick= { this.nextPage }>Next</button>
            </div>
            );
      }
    }
    export default CustomersList;

Now that we’ve created the `CustomersList` component for displaying the list of customers, we can add the component that handles customer creation and updates.

## Step 8 — Adding the Customer Create and Update React Component

In this step, we’ll create the `CustomerCreateUpdate` component, which will handle creating and updating customers. It will do this by providing a form that users can use to either enter data about a new customer or update an existing entry.

In `frontend/src`, create a `CustomerCreateUpdate.js` file:

    nano ~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

Add the following code to create a React component, importing `React` and `Component`:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    import React, { Component } from 'react';

We can also import and instantiate the `CustomersService` class we created in the previous step, which provides methods that interface with the REST API backend:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    ...
    import CustomersService from './CustomersService';
    
    const customersService = new CustomersService();

Next, create a `CustomerCreateUpdate` component that extends `Component` to create and update customers:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    class CustomerCreateUpdate extends Component {
    
        constructor(props) {
            super(props);
        }
    
    }
    export default CustomerCreateUpdate;

Within the class definition, add the `render()` method of the component, which renders an HTML form that takes information about the customer:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    render() {
            return (
              <form onSubmit={this.handleSubmit}>
              <div className="form-group">
                <label>
                  First Name:</label>
                  <input className="form-control" type="text" ref='firstName' />
    
                <label>
                  Last Name:</label>
                  <input className="form-control" type="text" ref='lastName'/>
    
                <label>
                  Phone:</label>
                  <input className="form-control" type="text" ref='phone' />
    
                <label>
                  Email:</label>
                  <input className="form-control" type="text" ref='email' />
    
                <label>
                  Address:</label>
                  <input className="form-control" type="text" ref='address' />
    
                <label>
                  Description:</label>
                  <textarea className="form-control" ref='description' ></textarea>
    
    
                <input className="btn btn-primary" type="submit" value="Submit" />
                </div>
              </form>
            );
      }

For each form input element, the method adds a `ref` property to access and set the value of the form element.

Next, above the `render()` method, define a `handleSubmit(event)` method so that you have the proper functionality when a user clicks on the submit button:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    handleSubmit(event) {
        const { match: { params } } = this.props;
        if(params && params.pk){
            this.handleUpdate(params.pk);
        }
        else
        {
            this.handleCreate();
        }
        event.preventDefault();
    }
    
    ...

The `handleSubmit(event)` method handles the form submission and, depending on the route, calls either the `handleUpdate(pk)` method to update the customer with the passed `pk`, or the `handleCreate()` method to create a new customer. We will define these methods shortly.

Back on the component constructor, bind the newly added `handleSubmit()` method to `this` so you can access it in your form:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    ...
    class CustomerCreateUpdate extends Component {
    
    constructor(props) {
        super(props);
        this.handleSubmit = this.handleSubmit.bind(this);
    }
    ...

Next, define the `handleCreate()` method to create a customer from the form data. Above the `handleSubmit(event)` method, add the following code:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    handleCreate(){
        customersService.createCustomer(
            {
            "first_name": this.refs.firstName.value,
            "last_name": this.refs.lastName.value,
            "email": this.refs.email.value,
            "phone": this.refs.phone.value,
            "address": this.refs.address.value,
            "description": this.refs.description.value
            }).then((result)=>{
                    alert("Customer created!");
            }).catch(()=>{
                    alert('There was an error! Please re-check your form.');
            });
    }
    
    ...

The `handleCreate()` method will be used to create a customer from inputted data. It calls the corresponding `CustomersService.createCustomer()` method that makes the actual API call to the backend to create a customer.

Next, below the `handleCreate()` method, define the `handleUpdate(pk)` method to implement updates:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    handleUpdate(pk){
    customersService.updateCustomer(
        {
        "pk": pk,
        "first_name": this.refs.firstName.value,
        "last_name": this.refs.lastName.value,
        "email": this.refs.email.value,
        "phone": this.refs.phone.value,
        "address": this.refs.address.value,
        "description": this.refs.description.value
        }
        ).then((result)=>{
    
            alert("Customer updated!");
        }).catch(()=>{
            alert('There was an error! Please re-check your form.');
        });
    }

The `updateCustomer()` method will update a customer by `pk` using the new information from the customer information form. It calls the `customersService.updateCustomer()` method.

Next, add a `componentDidMount()` method. If the the user visits a `customer/:pk` route, we want to fill the form with information related to the customer using the primary key from the URL. To do that, we can add the `getCustomer(pk)` method after the component gets mounted in the lifecycle event of `componentDidMount()`. Add the following code below the component constructor to add this method:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    
    ...
    componentDidMount(){
        const { match: { params } } = this.props;
        if(params && params.pk)
        {
            customersService.getCustomer(params.pk).then((c)=>{
                this.refs.firstName.value = c.first_name;
                this.refs.lastName.value = c.last_name;
                this.refs.email.value = c.email;
                this.refs.phone.value = c.phone;
                this.refs.address.value = c.address;
                this.refs.description.value = c.description;
            })
        }
    }

This is the full content of the file:

~/djangoreactproject/frontend/src/CustomerCreateUpdate.js

    import React, { Component } from 'react';
    import CustomersService from './CustomersService';
    
    const customersService = new CustomersService();
    
    class CustomerCreateUpdate extends Component {
        constructor(props) {
            super(props);
    
            this.handleSubmit = this.handleSubmit.bind(this);
          }
    
          componentDidMount(){
            const { match: { params } } = this.props;
            if(params && params.pk)
            {
              customersService.getCustomer(params.pk).then((c)=>{
                this.refs.firstName.value = c.first_name;
                this.refs.lastName.value = c.last_name;
                this.refs.email.value = c.email;
                this.refs.phone.value = c.phone;
                this.refs.address.value = c.address;
                this.refs.description.value = c.description;
              })
            }
          }
    
          handleCreate(){
            customersService.createCustomer(
              {
                "first_name": this.refs.firstName.value,
                "last_name": this.refs.lastName.value,
                "email": this.refs.email.value,
                "phone": this.refs.phone.value,
                "address": this.refs.address.value,
                "description": this.refs.description.value
            }          
            ).then((result)=>{
              alert("Customer created!");
            }).catch(()=>{
              alert('There was an error! Please re-check your form.');
            });
          }
          handleUpdate(pk){
            customersService.updateCustomer(
              {
                "pk": pk,
                "first_name": this.refs.firstName.value,
                "last_name": this.refs.lastName.value,
                "email": this.refs.email.value,
                "phone": this.refs.phone.value,
                "address": this.refs.address.value,
                "description": this.refs.description.value
            }          
            ).then((result)=>{
              console.log(result);
              alert("Customer updated!");
            }).catch(()=>{
              alert('There was an error! Please re-check your form.');
            });
          }
          handleSubmit(event) {
            const { match: { params } } = this.props;
    
            if(params && params.pk){
              this.handleUpdate(params.pk);
            }
            else
            {
              this.handleCreate();
            }
    
            event.preventDefault();
          }
    
          render() {
            return (
              <form onSubmit={this.handleSubmit}>
              <div className="form-group">
                <label>
                  First Name:</label>
                  <input className="form-control" type="text" ref='firstName' />
    
                <label>
                  Last Name:</label>
                  <input className="form-control" type="text" ref='lastName'/>
    
                <label>
                  Phone:</label>
                  <input className="form-control" type="text" ref='phone' />
    
                <label>
                  Email:</label>
                  <input className="form-control" type="text" ref='email' />
    
                <label>
                  Address:</label>
                  <input className="form-control" type="text" ref='address' />
    
                <label>
                  Description:</label>
                  <textarea className="form-control" ref='description' ></textarea>
    
    
                <input className="btn btn-primary" type="submit" value="Submit" />
                </div>
              </form>
            );
          }  
    }
    
    export default CustomerCreateUpdate;

With the `CustomerCreateUpdate` component created, we can update the main `App` component to add links to the different components we’ve created.

## Step 9 — Updating the Main App Component

In this section, we’ll update the `App` component of our application to create links to the components we’ve created in the previous steps.

From the `frontend` folder, run the following command to install the [React Router](https://www.npmjs.com/package/react-router-dom), which allows you to add routing and navigation between various React components:

    cd ~/djangoreactproject/frontend
    npm install --save react-router-dom

Next, open `~/djangoreactproject/frontend/src/App.js`:

    nano ~/djangoreactproject/frontend/src/App.js

Delete everything that’s there and add the following code to import the necessary classes for adding routing. These include `BrowserRouter`, which creates a Router component, and `Route`, which creates a route component:

~/djangoreactproject/frontend/src/App.js

    import React, { Component } from 'react';
    import { BrowserRouter } from 'react-router-dom'
    import { Route, Link } from 'react-router-dom'
    import CustomersList from './CustomersList'
    import CustomerCreateUpdate from './CustomerCreateUpdate'
    import './App.css';

[`BrowserRouter`](https://reacttraining.com/react-router/web/api/BrowserRouter) keeps the UI in sync with the URL using the [HTML5 history API](https://developer.mozilla.org/en-US/docs/Web/API/History_API).

Next, create a base layout that provides the base component to be wrapped by the `BrowserRouter` component:

~/djangoreactproject/frontend/src/App.js

    ...
    
    const BaseLayout = () => (
    <div className="container-fluid">
        <nav className="navbar navbar-expand-lg navbar-light bg-light">
            <a className="navbar-brand" href="#">Django React Demo</a>
            <button className="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNavAltMarkup" aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
            <span className="navbar-toggler-icon"></span>
        </button>
        <div className="collapse navbar-collapse" id="navbarNavAltMarkup">
            <div className="navbar-nav">
                <a className="nav-item nav-link" href="/">CUSTOMERS</a>
                <a className="nav-item nav-link" href="/customer">CREATE CUSTOMER</a>
            </div>
        </div>
        </nav>
        <div className="content">
            <Route path="/" exact component={CustomersList} />
            <Route path="/customer/:pk" component={CustomerCreateUpdate} />
            <Route path="/customer/" exact component={CustomerCreateUpdate} />
        </div>
    </div>
    )

We use the `Route` component to define the routes of our application; the component the router should load once a match is found. Each route needs a `path` to specify the path to be matched and a `component` to specify the component to load. The `exact` property tells the router to match the exact path.

Finally, create the `App` component, the root or top-level component of our React application:

~/djangoreactproject/frontend/src/App.js

    ...
    
    class App extends Component {
    
    render() {
        return (
        <BrowserRouter>
            <BaseLayout/>
        </BrowserRouter>
        );
    }
    }
    export default App;

We have wrapped the `BaseLayout` component with the `BrowserRouter` component since our app is meant to run in the browser.

The completed file looks like this:

~/djangoreactproject/frontend/src/App.js

    import React, { Component } from 'react';
    import { BrowserRouter } from 'react-router-dom'
    import { Route, Link } from 'react-router-dom'
    
    import CustomersList from './CustomersList'
    import CustomerCreateUpdate from './CustomerCreateUpdate'
    import './App.css';
    
    const BaseLayout = () => (
      <div className="container-fluid">
    <nav className="navbar navbar-expand-lg navbar-light bg-light">
      <a className="navbar-brand" href="#">Django React Demo</a>
      <button className="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNavAltMarkup" aria-controls="navbarNavAltMarkup" aria-expanded="false" aria-label="Toggle navigation">
        <span className="navbar-toggler-icon"></span>
      </button>
      <div className="collapse navbar-collapse" id="navbarNavAltMarkup">
        <div className="navbar-nav">
          <a className="nav-item nav-link" href="/">CUSTOMERS</a>
          <a className="nav-item nav-link" href="/customer">CREATE CUSTOMER</a>
    
        </div>
      </div>
    </nav>  
    
        <div className="content">
          <Route path="/" exact component={CustomersList} />
          <Route path="/customer/:pk" component={CustomerCreateUpdate} />
          <Route path="/customer/" exact component={CustomerCreateUpdate} />
    
        </div>
    
      </div>
    )
    
    class App extends Component {
      render() {
        return (
          <BrowserRouter>
            <BaseLayout/>
          </BrowserRouter>
        );
      }
    }
    
    export default App;

After adding routing to our application, we are now ready to test the application. Navigate to `http://localhost:3000`. You should see the first page of the application:

![Application Home Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/django_react_1604/django_react_app.png)

With this application in place, you now have the base for a CRM application.

## Conclusion

In this tutorial, you created a demo application using Django and React. You used the Django REST framework to build the REST API, Axios to consume the API, and Bootstrap 4 to style your CSS. You can find the source code of this project in this [GitHub repository](https://github.com/techiediaries/django-react).

This tutorial setup used separate front-end and back-end apps. For a different approach to integrating React with Django, check this [tutorial](https://www.techiediaries.com/django-react-rest/) and this [tutorial](http://v1k45.com/blog/modern-django-part-1-setting-up-django-and-react/).

For more information about building an application with Django, you can follow the [Django development series](https://www.digitalocean.com/community/tutorial_series/django-development). You can also look at the [official Django docs](https://docs.djangoproject.com/en/2.1/).
