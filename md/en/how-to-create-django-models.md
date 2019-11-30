---
author: Jeremy Morris
date: 2017-10-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-django-models
---

# How To Create Django Models

## Introduction

In the previous tutorial, “[How To Create a Django App and Connect it to a Database](how-to-create-a-django-app-and-connect-it-to-a-database),” we covered how to create a MySQL database, how to create and start a Django application, and how to connect it to a MySQL database.

In this tutorial, we will create the Django **models** that define the fields and behaviors of the Blog application data that we will be storing. These models map the data from your Django application to the database. It’s what Django uses to generate the database tables via their object relational mapping (ORM) API called “models.”

## Prerequisites

You should have MySQL installed on an Ubuntu 16.04 server, and you should also have a database connection set up with your Django application. If you haven’t done this already, please refer to part two of the Django series, “[How To Create a Django App and Connect it to a Database](how-to-create-a-django-app-and-connect-it-to-a-database).”

## Step 1 — Create Django Application

To keep with the Django philosophy of modularity, we will create a Django app within our project that contains all of the files necessary for creating the blog website.

First activate your Python virtual environment:

    cd ~/my_blog_app
    . env/bin/activate
    cd blog

From there, let’s run this command:

    python manage.py startapp blogsite

At this point, you’ll have the following directory structure for your project:

    my_blog_app/
    └── blog
        ├── blog
        │ ├── __init__.py
        │ ├── __pycache__
        │ │ ├── __init__.cpython-35.pyc
        │ │ ├── settings.cpython-35.pyc
        │ │ ├── urls.cpython-35.pyc
        │ │ └── wsgi.cpython-35.pyc
        │ ├── settings.py
        │ ├── urls.py
        │ └── wsgi.py
        ├── blogsite
        │ ├── admin.py
        │ ├── apps.py
        │ ├── __init__.py
        │ ├── migrations
        │ │ └── __init__.py
        │ ├── models.py
        │ ├── tests.py
        │ └── views.py
        └── manage.py

The file we will focus on for this tutorial, will be the `models.py` file.

## Step 2 — Add the Posts Model

First we need to open and edit the `models.py` file so that it contains the code for generating a `Post` model. A `Post` model contains the following database fields:

- `title` — The title of the blog post.
- `slug` — Where valid URLs are stored and generated for web pages.
- `content` — The textual content of the blog post.
- `created_on` — The date on which the post was created.
- `author` — The person who has written the post.

Now, change directories to where the `models.py` file is contained.

    cd ~/my_blog_app/blog/blogsite

Use the `cat` command to show the contents of the file in your terminal.

    cat models.py

The file should have the following code, which imports models, along with a comment describing what is to be placed into this `models.py` file.

models.py

    from django.db import models
    
    # Create your models here.

Using your favorite text editor or IDE, add the following code to the `models.py` file. We’ll use `nano` as our text editor. But, you are welcome to use whatever you prefer.

    nano models.py

Within this file, the code to import the models API is already added, we can go ahead and delete the comment that follows. Then we’ll import `slugify` for generating slugs from strings, and Django’s `User` for authentication like so:

models.py

    from django.db import models
    from django.template.defaultfilters import slugify
    from django.contrib.auth.models import User

Then, add the class method on the model class we will be calling `Post`, with the following database fields, `title`, `slug`, `content`, `created_on` and `author`.

models.py

    ...
    class Post(models.Model):
        title = models.CharField(max_length=255)
        slug = models.SlugField(unique=True, max_length=255)
        content = models.TextField()
        created_on = models.DateTimeField(auto_now_add=True)
        author = models.TextField()

Next, we will add functionality for the generation of the URL and the function for saving the post. This is crucial, because this creates a unique link to match our unique post.

models.py

    ...
    @models.permalink
     def get_absolute_url(self):
         return ('blog_post_detail', (),
              {
                 'slug': self.slug,
              })
     def save(self, *args, **kwargs):
         if not self.slug:
             self.slug = slugify(self.title)
             super(Post, self).save(*args, **kwargs)

Now, we need to tell the model how the posts should be ordered, and displayed on the web page. The logic for this will be added to a nested inner `Meta` class. The `Meta` class generally contains other important model logic that isn’t related to database field definition.

models.py

    ...
       class Meta:
            ordering = ['created_on']
            def __unicode__ (self):
                return self.title

Finally, we will add the `Comment` model to this file. This involves adding another class named `Comment` with `models.Models` in its signature and the following database fields defined:

- `name` — The name of the person posting the comment.
- `email` — The email address of the person posting the comment.
- `text` — The text of the comment itself.
- `post` — The post with which the comment was made.
- `created_on` — The time the comment was created.

models.py

    ...
    class Comment(models.Model):
        name = models.CharField(max_length=42)
        email = models.EmailField(max_length=75)
        website = models.URLField(max_length=200, null=True, blank=True)
        content = models.TextField()
        post = models.ForeignKey(Post, on_delete=models.CASCADE)
        created_on = models.DateTimeField(auto_now_add=True)

When finished, your complete `models.py` file should look like this:

models.py

    from django.db import models
    from django.template.defaultfilters import slugify
    from django.contrib.auth.models import User
    
    
    class Post(models.Model):
        title = models.CharField(max_length=255)
        slug = models.SlugField(unique=True, max_length=255)
        content = models.TextField()
        created_on = models.DateTimeField(auto_now_add=True)
        author = models.TextField()
    
        @models.permalink
        def get_absolute_url(self):
            return ('blog_post_detail', (),
                    {
                       'slug': self.slug,
                    })
    
        def save(self, *args, **kwargs):
            if not self.slug:
                self.slug = slugify(self.title)
            super(Post, self).save(*args, **kwargs)
    
        class Meta:
            ordering = ['created_on']
    
            def __unicode__ (self):
                return self.title
    
    
    class Comment(models.Model):
        name = models.CharField(max_length=42)
        email = models.EmailField(max_length=75)
        website = models.URLField(max_length=200, null=True, blank=True)
        content = models.TextField()
        post = models.ForeignKey(Post, on_delete=models.CASCADE)
        created_on = models.DateTimeField(auto_now_add=True)
    

Be sure to save and close the file.

With the `models.py` file set up, we can go on to update our `settings.py` file.

## Step 3 — Update Settings

Now that we’ve added models to our application, we must inform our project of the existence of the `blogsite` app that we’ve just added. We do this by adding it to the `INSTALLED_APPS` section in `settings.py`.

Navigate to the directory where your `settings.py` lives.

    cd ~/my_blog_app/blog/blog

From here, open up your `settings.py` file, with nano, for instance, using the command `nano settings.py`.

With the file open, add your `blogsite` app to the `INSTALLED_APPS` section of the file, as shown below.

settings.py

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

With the `blogsite` app added, you can save and exit the file.

At this point we are ready to move on to apply these changes.

## Step 4 — Make Migrations

With our models `Post` and `Comment` added, the next step is to apply these changes so that our `MySQL` database schema recognizes them and creates the necessary tables.

Let’s take a look at what tables already exist in our `blog_data` database.

To do this, we need to log in to MySQL server.

**Note:** In this example, we’ll be using the username `root` with no password, but you should use the username and password you have set up for MySQL.

    mysql blog_data -u root

You’ll notice that if you type into the `SHOW DATABASES;` command, you’ll see the following:

    Output+--------------------+
    | Database |
    +--------------------+
    | information_schema |
    | blog_data |
    | mysql |
    | performance_schema |
    | sys |
    +--------------------+
    5 rows in set (0.00 sec)

We will be looking at the `blog_data` database and view the tables that already exist, if any.

    USE blog_data;

Then, list the tables that exist in the `blog_data` database:

    SHOW TABLES;

    OutputEmpty set (0.00 sec)

Right now it won’t show any tables because we haven’t made any migrations yet. But, when we do make migrations, it will display the tables that have been generated by Django.

Now we will proceed to make the migrations that apply the changes we’ve made in `models.py`.

Close out of MySQL with `CTRL` + `D`.

First, we must package up our model changes into individual migration files using the command `makemigrations`. These files are similar to that of `commits` in a version control system like `git`.

Now, if you navigate to `~/my_blog_app/blog/blogsite/migrations` and run `ls`, you’ll notice that there is only an ` __init__.py` file. This will change once we add the migrations.

Change to the blog directory using `cd`, like so:

    cd ~/my_blog_app/blog

    python manage.py makemigrations

You should then see the following output in your terminal window:

    OutputMigrations for 'blogsite':
      blogsite/migrations/0001_initial.py
        - Create model Comment
        - Create model Post
        - Add field post to comment

Remember, when we navigated to `/~/my_blog_app/blog/blogsite/migrations` and it only had the ` __init__.py` file? If we now `cd` back to that directory we’ll see that two things have been added, ` __pycache__ ` and `0001_initial.py`. The `0001_initial.py` file was automatically generated when you ran `makemigrations`. A similar file will be generated every time you run `makemigrations`.

Run `less 0001_initial.py` if you’d like to see what the file contains.

Now navigate to `~/my_blog_app/blog`.

Since we have made a migration file, we must apply the changes these files describe to the database using the command `migrate`. But first let’s see what current migrations exists, using the `showmigrations` command.

    python manage.py showmigrations

    Outputadmin
     [] 0001_initial
     [] 0002_logentry_remove_auto_add
    auth
     [] 0001_initial
     [] 0002_alter_permission_name_max_length
     [] 0003_alter_user_email_max_length
     [] 0004_alter_user_username_opts
     [] 0005_alter_user_last_login_null
     [] 0006_require_contenttypes_0002
     [] 0007_alter_validators_add_error_messages
     [] 0008_alter_user_username_max_length
     [] 0009_alter_user_last_name_max_length
    blogsite
     [] 0001_initial
    contenttypes
     [] 0001_initial
     [] 0002_remove_content_type_name
    sessions
     [] 0001_initial

You’ll notice the migration we’ve just added for `blogsite`, which contains the migration `0001_initial` for models `Post` and `Comment`.

Now let’s see the `SQL` statements that will be executed once we make the migrations, using the following command. It takes in the migration and the migration’s title as an argument:

    python manage.py sqlmigrate blogsite 0001_initial

As you see below, this is the actual SQL query being made behind the scenes.

    BEGIN;
    --
    -- Create model Comment
    --
    CREATE TABLE `blogsite_comment` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `name` varchar(42) NOT NULL, `email` varchar(75) NOT NULL, `website` varchar(200) NULL, `content` longtext NOT NULL, `created_on` datetime(6) NOT NULL);
    --
    -- Create model Post
    --
    CREATE TABLE `blogsite_post` (`id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY, `title` varchar(255) NOT NULL, `slug` varchar(255) NOT NULL UNIQUE, `content` longtext NOT NULL, `created_on` datetime(6) NOT NULL, `author` longtext NOT NULL);
    --
    -- Add field post to comment
    --
    ALTER TABLE `blogsite_comment` ADD COLUMN `post_id` integer NOT NULL;
    ALTER TABLE `blogsite_comment` ADD CONSTRAINT `blogsite_comment_post_id_de248bfe_fk_blogsite_post_id` FOREIGN KEY (`post_id`) REFERENCES `blogsite_post` (`id`);
    COMMIT;

Let’s now perform the migrations so that they get applied to our MySQL database.

    python manage.py migrate

We will see the following output:

    OutputOperations to perform:
      Apply all migrations: admin, auth, blogsite, contenttypes, sessions
    Running migrations:
      Applying contenttypes.0001_initial... OK
      Applying auth.0001_initial... OK
      Applying admin.0001_initial... OK
      Applying admin.0002_logentry_remove_auto_add... OK
      Applying contenttypes.0002_remove_content_type_name... OK
      Applying auth.0002_alter_permission_name_max_length... OK
      Applying auth.0003_alter_user_email_max_length... OK
      Applying auth.0004_alter_user_username_opts... OK
      Applying auth.0005_alter_user_last_login_null... OK
      Applying auth.0006_require_contenttypes_0002... OK
      Applying auth.0007_alter_validators_add_error_messages... OK
      Applying auth.0008_alter_user_username_max_length... OK
      Applying auth.0009_alter_user_last_name_max_length... OK
      Applying blogsite.0001_initial... OK
      Applying sessions.0001_initial... OK

You have now successfully applied your migrations.

It is important to keep in mind that there are 3 caveats to Django migrations with MySQL as your backend, as stated in the Django documentation.

- Lack of support for transactions around schema alteration operations. In other words, if a migration fails to apply successfully, you will have to manually unpick the changes you’ve made in order to attempt another migration. It is not possible to rollback, to an earlier point, before any changes were made in the failed migration.
- For most schema alteration operations, MySQL will fully rewrite tables. In the worst case, the time complexity be proportional to the number of rows in the table to add or remove columns. According to the Django documentation, this could be as slow as one minute per million rows.
- In MySQL, there are small limits on name lengths for columns, tables and indices. There is also a limit on the combined size of all columns and index covers. While some other backends can support higher limits created in Django, the same indices will fail to be created with a MySQL backend in place.

For each database you consider for use with Django, be sure to weigh the advantages and disadvantages of each.

## Step 5 — Verify Database Schema

With migrations complete, we should verify the successful generation of the MySQL tables that we’ve created via our Django models.

To do this, run the following command in the terminal to log in to MySQL.

    mysql blog_data -u root

Now show the databases that exist.

    SHOW DATABASES;

Select our database `blog_data`:

    USE blog_data;

Then type the following command to view the tables.

    SHOW TABLES;

You should see the following:

    Output+----------------------------+
    | Tables_in_blog_data |
    +----------------------------+
    | auth_group |
    | auth_group_permissions |
    | auth_permission |
    | auth_user |
    | auth_user_groups |
    | auth_user_user_permissions |
    | blogsite_comment |
    | blogsite_post |
    | django_admin_log |
    | django_content_type |
    | django_migrations |
    | django_session |
    +----------------------------+

You’ll see `blogsite_comment` and `blogsite_post`. These are the models that we’ve made ourselves. Let’s validate that they contain the fields we’ve defined.

    DESCRIBE blogsite_comment;

    Output+------------+--------------+------+-----+---------+----------------+
    | Field | Type | Null | Key | Default | Extra |
    +------------+--------------+------+-----+---------+----------------+
    | id | int(11) | NO | PRI | NULL | auto_increment |
    | name | varchar(42) | NO | | NULL | |
    | email | varchar(75) | NO | | NULL | |
    | website | varchar(200) | YES | | NULL | |
    | content | longtext | NO | | NULL | |
    | created_on | datetime(6) | NO | | NULL | |
    | post_id | int(11) | NO | MUL | NULL | |
    +------------+--------------+------+-----+---------+----------------+
    7 rows in set (0.01 sec)

    DESCRIBE blogsite_post;

    Output+------------+--------------+------+-----+---------+----------------+
    | Field | Type | Null | Key | Default | Extra |
    +------------+--------------+------+-----+---------+----------------+
    | id | int(11) | NO | PRI | NULL | auto_increment |
    | title | varchar(255) | NO | | NULL | |
    | slug | varchar(255) | NO | UNI | NULL | |
    | content | longtext | NO | | NULL | |
    | created_on | datetime(6) | NO | | NULL | |
    | author | longtext | NO | | NULL | |
    +------------+--------------+------+-----+---------+----------------+
    6 rows in set (0.01 sec)

We have verified that the database tables were successfully generated from our Django model migrations.

You can close out of MySQL with `CTRL` + `D` and when you are ready to leave your Python environment, you can run the `deactivate` command:

    deactivate

Deactivating your programming environment will put you back to the terminal command prompt.

### Conclusion

In this tutorial we’ve successfully added models for basic functionality in a blog web application. You’ve learned how to code `models`, how `migrations` work and the process of translating Django `models` to actual `MySQL` database tables.
