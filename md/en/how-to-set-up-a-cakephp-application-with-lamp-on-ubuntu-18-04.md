---
author: Savic
date: 2019-02-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-cakephp-application-with-lamp-on-ubuntu-18-04
---

# How To Set Up a CakePHP Application with LAMP on Ubuntu 18.04

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[CakePHP](https://cakephp.org/) is a popular and feature-rich PHP web framework. It solves many of the common problems in web development, such as interacting with a database, shielding against SQL injections, and generating view code. It adheres to the _model-view-controller_ (MVC) pattern, which decouples various parts of the application, effectively allowing developers to work on different parts of the app in parallel. It also provides built-in security and authentication. To create a basic database app is a seamless process, which makes CakePHP useful for prototyping. However, you can use CakePHP to create fully developed web applications for deployment as well.

In this tutorial, you will deploy an example CakePHP web application to a production environment. To achieve this, you’ll set up an example database and user, configure Apache, connect your app to the database, and turn off debug mode. You’ll also use CakePHP’s `bake` command to automatically generate article models.

## Prerequisites

Before you begin this tutorial, you will need:

- A server running Ubuntu 18.04 with root access and a sudo, non-root account, you can set this up by following [this initial server setup guide](initial-server-setup-with-ubuntu-18-04).
- A LAMP stack installed according to [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04). At the time of this writing, PHP 7.2 is the latest version.
- [Composer](https://getcomposer.org/) (a PHP package manager) installed on your server. For a guide on how to do that, visit [How To Install and Use Composer on Ubuntu 18.04](how-to-install-and-use-composer-on-ubuntu-18-04). You only need to complete the first two steps from that tutorial.
- Apache secured with Let’s Encrypt. To complete this prerequisite, you’ll first need to set up virtual hosts following Step 5 of [How To Install Apache on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-(recommended)). You can then follow [How To Secure Apache with Let’s Encrypt on Ubuntu 18.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) to secure Apache with Let’s Encrypt. When asked, enable mandatory HTTPS redirection.
- A fully registered domain name. This tutorial will use `example.com` throughout. You can purchase a domain name on [Namecheap](https://www.namecheap.com/), get one for free on [Freenom](https://www.freenom.com/en/index.html?lang=en), or use the domain registrar of your choice.
- Both of the following DNS records set up for your server. You can follow [this introduction](https://www.digitalocean.com/docs/networking/dns/quickstart/) to DigitalOcean DNS for details on how to add them.
  - An A record with `example.com` pointing to your server’s public IP address.
  - An A record with `www.example.com` pointing to your server’s public IP address.

## Step 1 — Installing Dependencies

To prepare for your application, you’ll begin by installing the PHP extensions that CakePHP needs.

Start off by updating the package manager cache:

    sudo apt update

CakePHP requires the `mbstring`, `intl`, and `simplexml` PHP extensions, which add support for multibyte strings, internationalization, and XML processing. You have installed `mbstring` as part of the Composer prerequisite tutorial. You can install the remaining libraries with one command:

    sudo apt install php7.2-intl php7.2-xml -y

Remember that the version numbers above (7.2) will change with new versions of PHP.

You installed the required dependencies for CakePHP. You’re now ready to configure your MySQL database for production use.

## Step 2 — Setting Up a MySQL Database

Now, you’ll create a MySQL database to store information about your blog’s articles. You’ll also create a database user that your application will use to access the database. You’ll modify the database privileges to achieve this separation of control. As a result, bad actors won’t be able to cause issues on the system even with database credentials, which is an important security precaution in a production environment.

Launch your MySQL shell:

    sudo mysql -u root -p

When asked, enter the password you set up during the initial LAMP installation.

Next, create a database:

    CREATE DATABASE cakephp_blog;

You will see output similar to:

    OutputQuery OK, 1 row affected (0.00 sec)

Your CakePHP app will use this new database to read and store production data.

Then, instruct MySQL to operate on the new `cakephp_blog` database:

    USE cakephp_blog;

You will see output similar to:

    OutputDatabase changed

Now you’ll create a table schema for your blog articles in the `cakephp_blog` database. Run the following command to set this up:

    CREATE TABLE articles (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(50),
        body TEXT,
        created DATETIME DEFAULT NULL,
        modified DATETIME DEFAULT NULL
    );

You’ve created a schema with five fields to describe blog articles:

- `id`: is the unique identifier of an article, set up as a primary key.
- `title`: is the title of an article, declared as a text field containing a maximum of 50 characters.
- `body`: is the text of the article, declared as `TEXT` field.
- `created`: is the date and time of a record’s creation.
- `modified`: is the date and time of a record’s modification.

The output will be similar to:

    OutputQuery OK, 0 rows affected (0.01 sec)

You have created a table for storing articles in the `cakephp_blog` database. Next, populate it with example articles by running the following command:

    INSERT INTO articles (title, body, created)
        VALUES ('Sample title', 'This is the article body.', NOW());

You’ve added an example article with some sample data for the title and body text.

You will see the following output:

    OutputQuery OK, 0 rows affected (0.01 sec)

In order to connect the CakePHP app to the database, you need to create a new database user and restrict its privileges:

    GRANT ALL PRIVILEGES ON cakephp_blog.* TO 'cake_user'@'localhost' IDENTIFIED BY 'password';

This command grants all privileges to all the tables in the database.

Remember to replace `password` with a strong password of your choice.

To update your database with the changes you’ve made, reload by running:

    FLUSH PRIVILEGES;

You’ve just created a new database user, `cake_user` and given the user privileges only on the `cakephp_blog` database, thus tightening security.

Exit the MySQL terminal by entering `exit`.

You’ve created a new database with a schema, populated it with example data, and created an appropriate database user. In the next step, you will set up the CakePHP app itself.

## Step 3 — Creating the Blog Application

In this section, you’ll use Composer to install an example CakePHP app. It is advantageous to use Composer as it allows you to install CakePHP from your command line and it automatically sets up certain file permissions and configuration files.

First, navigate to the Apache web server folder:

    cd /var/www/example.com/html

Apache uses this directory to store files visible to the outside world. The `root` user owns this directory, and so your non-root user, `sammy`, can’t write anything to it. To correct this, you’ll change the file system permissions by running:

    sudo chown -R sammy .

You’ll now create a new CakePHP app via Composer:

    composer create-project --prefer-dist cakephp/app cake-blog

Here you have invoked `composer` and instructed it to create a new project with `create-project`. `--prefer-dist cakephp/app` tells `composer` to use CakePHP as a template with `cake-blog` as the name of the new application.

Keep in mind that this command may take some time to finish.

When Composer asks you to set up folder permissions, answer with `y`.

In this section, you created a new CakePHP project with Composer. In the next step, you will configure Apache to point to the new app, which will make it viewable in your browser.

## Step 4 — Configuring Apache to Point to Your App

Now, you’ll configure Apache for your new CakePHP application, as well as enable `.htaccess` overriding, which is a CakePHP requirement. This entails editing Apache configuration files.

For actual routing to take place, you must instruct Apache to use `.htaccess` files. These are configuration files that will be in subdirectories of the application (where needed), and then Apache uses the files to alter its global configuration for the requested part of the app. Among other tasks, they will contain URL rewriting rules, which you’ll be adjusting now.

Start off by opening the Apache global configuration file (`apache2.conf`) using your text editor:

    sudo nano /etc/apache2/apache2.conf

Find the following block of code:

/etc/apache2/apache2.conf

    ...
    <Directory /var/www/>
            Options Indexes FollowSymLinks
            AllowOverride None
            Require all granted
    </Directory>
    ...

Change `AllowOverride` from `None` to `All`, like the following:

/etc/apache2/apache2.conf

    ...
    <Directory /var/www/>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
    </Directory>
    ...

Save and close the file.

Next, you will instruct Apache to point to the `webroot` directory in the CakePHP installation. Apache stores its configuration files on Ubuntu 18.04 in `/etc/apache2/sites-available`. These files govern how Apache processes web requests.

During the Let’s Encrypt prerequisite tutorial, you enabled HTTPS redirection; therefore only allowing HTTPS traffic. As a result, you’ll only edit the `example.com-le-ssl.conf` file, which configures HTTPS traffic.

First, open the `example.com-le-ssl.conf` configuration file:

    sudo nano /etc/apache2/sites-available/example.com-le-ssl.conf

You need to change only one line, the one that sets up `DocumentRoot` and tells Apache from where to serve content to the browser. Find the following line in the file:

/etc/apache2/sites-available/example.com-le-ssl.conf

    DocumentRoot /var/www/example.com/html

Edit this line to point to the CakePHP installation, by adding the following highlighted content:

/etc/apache2/sites-available/example.com-le-ssl.conf

    DocumentRoot /var/www/example.com/html/cake-blog/webroot

Save the file and exit the editor.

Afterwards, restart Apache to reflect the new configuration:

    sudo systemctl restart apache2

Now you can visit `https://your_domain/` in your browser.

![CakePHP can't connect to the database](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cakephp_1804/step3.png)

You’ll see the default CakePHP success page. You’ll notice that there is a block indicating that your application can’t connect to the database. In the next step you’ll resolve this by connecting your app to the database.

You’ve now enabled `.htaccess` overriding, and pointed Apache to the correct `webroot` directory.

## Step 5 — Connecting Your App to the Database

In this section, you will connect your database to your application so that your blog can access the articles. You’ll edit CakePHP’s default `config/app.php` file to set up the connection to your database.

Navigate to the app folder:

    cd /var/www/example.com/html/cake-blog

Open the `config/app.php` file, by running the following command:

    sudo nano config/app.php

Find the `Datasources` block (it looks like the following):

/var/www/example.com/html/cake-blog/config/app.php

    ...
        'Datasources' => [
            'default' => [
                'className' => 'Cake\Database\Connection',
                'driver' => 'Cake\Database\Driver\Mysql',
                'persistent' => false,
                'host' => 'localhost',
                ...
                //'port' => 'non_standard_port_number',
                'username' => 'cake_user',
                'password' => 'password',
                'database' => 'cakephp_blog',
    ...

For `'username'` replace `my_app` with your database user’s username (this tutorial uses: `cake_user`), `secret` with your database user’s password, and the second `my_app` with the database name (`cakephp_blog` in this tutorial).

Save and close the file.

Refresh the app in your browser and observe the success message under the **Database** section. If it shows an error, double check your configuration file against the preceding steps.

![CakePHP can connect to the database](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cakephp_1804/step5.png)

In this step, you’ve connected the CakePHP app to your MySQL database. In the next step, you’ll generate the model, view, and controller files that will make up the user interface for interacting with the articles.

## Step 6 — Creating the Article User Interface

In this section, you’ll create a ready-to-use article interface by running the CakePHP `bake` command, which generates the article model. In CakePHP, baking generates all required models, views, and controllers in a basic state, ready for further development. Every database app must allow for create, read, update, and delete (CRUD) operations, which makes CakePHP’s `bake` feature useful for automatically generating code for these operations. Within a couple of minutes, you get a full prototype of the app, ready to enter, store, and edit the data.

Models, views, and controllers pertain to the _MVC_ pattern. Their roles are:

- Models represent the data structure.
- Views present the data in a user-friendly way.
- Controllers act upon user requests and serve as an intermediary between views and models.

CakePHP stores its CLI executable under `bin/cake`. While it is mostly used for baking, it offers a slew of other commands, such as the ones for clearing various caches.

The `bake` command will check your database, and generate the models based on the table definitions it finds. Start off by running the following command:

    ./bin/cake bake all

By passing the `all` command, you are instructing CakePHP to generate models, controllers, and views all at once.

Your output will look like this:

    OutputBake All
    ---------------------------------------------------------------
    Possible model names based on your database:
    - articles
    Run `cake bake all [name]` to generate skeleton files.

It has properly detected the `articles` definition from your database, and is offering to generate files for that model.

Bake it by running:

    ./bin/cake bake all articles

Your output will look like this:

    OutputBake All
    ---------------------------------------------------------------
    One moment while associations are detected.
    
    Baking table class for Articles...
    
    Creating file /var/www/example.com/html/cake-blog/src/Model/Table/ArticlesTable.php
    Wrote `/var/www/example.com/html/cake-blog/src/Model/Table/ArticlesTable.php`
    Deleted `/var/www/example.com/html/cake-blog/src/Model/Table/empty`
    
    Baking entity class for Article...
    
    Creating file /var/www/example.com/html/cake-blog/src/Model/Entity/Article.php
    Wrote `/var/www/example.com/html/cake-blog/src/Model/Entity/Article.php`
    Deleted `/var/www/example.com/html/cake-blog/src/Model/Entity/empty`
    
    Baking test fixture for Articles...
    
    Creating file /var/www/example.com/html/cake-blog/tests/Fixture/ArticlesFixture.php
    Wrote `/var/www/example.com/html/cake-blog/tests/Fixture/ArticlesFixture.php`
    Deleted `/var/www/example.com/html/cake-blog/tests/Fixture/empty`
    Bake is detecting possible fixtures...
    
    Baking test case for App\Model\Table\ArticlesTable ...
    
    Creating file /var/www/example.com/html/cake-blog/tests/TestCase/Model/Table/ArticlesTableTest.php
    Wrote `/var/www/example.com/html/cake-blog/tests/TestCase/Model/Table/ArticlesTableTest.php`
    
    Baking controller class for Articles...
    
    Creating file /var/www/example.com/html/cake-blog/src/Controller/ArticlesController.php
    Wrote `/var/www/example.com/html/cake-blog/src/Controller/ArticlesController.php`
    Bake is detecting possible fixtures...
    
    ...
    
    Baking `add` view template file...
    
    Creating file /var/www/example.com/html/cake-blog/src/Template/Articles/add.ctp
    Wrote `/var/www/example.com/html/cake-blog/src/Template/Articles/add.ctp`
    
    Baking `edit` view template file...
    
    Creating file /var/www/example.com/html/cake-blog/src/Template/Articles/edit.ctp
    Wrote `/var/www/example.com/html/cake-blog/src/Template/Articles/edit.ctp`
    Bake All complete.

In the output, you will see that CakePHP has logged all the steps it took to create a functional boilerplate for the `articles` database.

Now, navigate to the following in your browser:

    https://your_domain/articles

You’ll see a list of articles currently in the database, which includes one row titled **Sample Title**. The `bake` command created this interface allowing you to create, delete, and edit articles. As such, it provides a solid starting point for further development. You can try adding a new article by clicking the **New Article** link in the sidebar.

![The generated article user interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cakephp_1804/step6.png)

In this section, you generated model, view, and controller files with CakePHP’s `bake` command. You can now create, delete, view, and edit your articles, with all your changes immediately saved to the database.

In the next step, you will disable the debug mode.

## Step 7 — Disabling Debug Mode in CakePHP

In this section, you will disable the debug mode in CakePHP. This is crucial because in debug mode the app shows detailed debugging information, which is a security risk. You’ll complete this step after you’ve completed the development of your application.

Open the `config/app.php` file using your favorite editor:

    sudo nano config/app.php

Near the start of the file there will be a line for the `'debug'` mode. When you open the file `'debug'` mode will be set to `true`. Change this to `false` as per the following:

config/app.php

    ...
    'debug' => filter_var(env('DEBUG', false), FILTER_VALIDATE_BOOLEAN),
    ...

Once you’ve turned debug mode off, the home page, located under `src/Templates/Pages/home.ctp`, will show an error.

![The debug mode error](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cakephp_1804/step7.png)

**Note:** If you haven’t changed the default route or replaced the contents of `home.ctp`, the home page of your app will now show an error. This is because the default home page serves as a status dashboard during development, but does not work with debug mode disabled.

You’ve disabled debug mode. Any errors and exceptions that occur from now, along with their stack traces, won’t be shown to the end user, tightening the security of your application.

However, after, disabling debug mode, your `home.ctp` will show an error. If you’ve completed this step only for the purposes of this tutorial, you can now redirect your home page to the articles listing interface while keeping debug mode disabled. You’ll achieve this by editing the contents of `home.ctp`.

Open `home.ctp` for editing:

    sudo nano src/Template/Pages/home.ctp

Replace its contents with the following:

src/Template/Pages/home.ctp

    <meta http-equiv="refresh" content="0; url=./Articles" />
    <p><a href="./Articles">Click here if you are not redirected</a></p>

This HTML redirects to the `Articles` controller. If the automatic redirection fails, there is also a link for users to follow.

In this step, you disabled debug mode for security purposes and fixed the home page’s error by redirecting the user to the blog post listing interface that the `Articles` controller provides.

## Conclusion

You have now successfully set up a CakePHP application on a LAMP stack on Ubuntu 18.04. With CakePHP, you can create a database with as many tables as you like, and it will produce a live web editor for the data.

The [CakePHP cookbook](https://book.cakephp.org/3.0/en/index.html) offers detailed documentation regarding every aspect of CakePHP. The next step for your application could include implementing user authentication so that every user can make their own articles.
