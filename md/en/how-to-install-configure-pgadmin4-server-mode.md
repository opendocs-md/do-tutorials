---
author: Mark Drake
date: 2018-10-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-configure-pgadmin4-server-mode
---

# How To Install and Configure pgAdmin 4 in Server Mode

## Introduction

[pgAdmin](https://www.pgadmin.org/) is an open-source administration and development platform for PostgreSQL and its related database management systems. Written in Python and jQuery, it supports all the features found in PostgreSQL. You can use pgAdmin to do everything from writing basic SQL queries to monitoring your databases and configuring advanced database architectures.

In this tutorial, we’ll walk through the process of installing and configuring the latest version of pgAdmin onto an Ubuntu 18.04 server, accessing pgAdmin through a web browser, and connecting it to a PostgreSQL database on your server.

## Prerequisites

To complete this tutorial, you will need:

- A server running Ubuntu 18.04. This server should have a non-root user with sudo privileges, as well as a firewall configured with `ufw`. For help with setting this up, follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).
- The Apache web server installed on your server. Follow our guide on [How To Install the Apache Web Server on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04) to configure this on your machine.
- PostgreSQL installed on your server. You can set this up by following our guide on [How To Install and Use PostgreSQL on Ubuntu 18.04](how-to-install-and-use-postgresql-on-ubuntu-18-04). As you follow this guide, **be sure to create a new role and database** , as you will need both to connect pgAdmin to your PostgreSQL instance.
- Python 3 and `venv` installed on your server. Follow [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 18.04 server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server) to install these tools and set up a virtual environment.

## Step 1 — Installing pgAdmin and its Dependencies

As of this writing, the most recent version of pgAdmin is pgAdmin 4, while the most recent version available through the official Ubuntu repositories is pgAdmin 3. pgAdmin 3 is no longer supported though, and the project maintainers recommend installing pgAdmin 4. In this step, we will go over the process of installing the latest version of pgAdmin 4 within a virtual environment (as recommended by the project’s development team) and installing its dependencies using `apt`.

To begin, update your server’s package index if you haven’t done so recently:

    sudo apt update

Next, install the following dependencies. These include `libgmp3-dev`, a multiprecision arithmetic library; `libpq-dev`, which includes header files and a static library that helps communication with a PostgreSQL backend; and `libapache2-mod-wsgi-py3`, an Apache module that allows you to host Python-based web applications within Apache:

    sudo apt install libgmp3-dev libpq-dev libapache2-mod-wsgi-py3

Following this, create a few directories where pgAdmin will store its sessions data, storage data, and logs:

    sudo mkdir -p /var/lib/pgadmin4/sessions
    sudo mkdir /var/lib/pgadmin4/storage
    sudo mkdir /var/log/pgadmin4

Then, change ownership of these directories to your non-root user and group. This is necessary because they are currently owned by your **root** user, but we will install pgAdmin from a virtual environment owned by your non-root user, and the installation process involves creating some files within these directories. After the installation, however, we will change the ownership over to the **www-data** user and group so it can be served to the web:

    sudo chown -R sammy:sammy /var/lib/pgadmin4
    sudo chown -R sammy:sammy /var/log/pgadmin4

Next, open up your virtual environment. Navigate to the directory your programming environment is in and activate it. Following the naming conventions of the [prerequisite Python 3 tutorial](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server), we’ll go to the `environments` directory and activate the `my_env` environment:

    cd environments/
    source my_env/bin/activate

Following this, download the pgAdmin 4 source code onto your machine. To find the latest version of the source code, navigate to the [pgAdmin 4 (Python Wheel) Download page](https://www.pgadmin.org/download/pgadmin-4-python-wheel/) and click the link for the latest version (v3.4, as of this writing). This will take you to a **Downloads** page on the PostgreSQL website. Once there, copy the file link that ends with `.whl` — the standard built-package format used for Python distributions. Then go back to your terminal and run the following `wget` command, making sure to replace the link with the one you copied from the PostgreSQL site, which will download the `.whl` file to your server:

    wget https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v3.4/pip/pgadmin4-3.4-py2.py3-none-any.whl

Next install the `wheel` package, the reference implementation of the wheel packaging standard. A Python library, this package serves as an extension for building wheels and includes a command line tool for working with `.whl` files:

    python -m pip install wheel

Then install pgAdmin 4 package with the following command:

    python -m pip install pgadmin4-3.4-py2.py3-none-any.whl 

That takes care of installing pgAdmin and its dependencies. Before connecting it to your database, though, there are a few changes you’ll need to make to the program’s configuration.

## Step 2 — Configuring pgAdmin 4

Although pgAdmin has been installed on your server, there are still a few steps you must go through to ensure it has the permissions and configurations needed to allow it to correctly serve the web interface.

pgAdmin’s main configuration file, `config.py`, is read before any other configuration file. Its contents can be used as a reference point for further configuration settings that can be specified in pgAdmin’s other config files, but to avoid unforeseen errors, you should not edit the `config.py` file itself. We will add some configuration changes to a new file, named `config_local.py`, which will be read after the primary one.

Create this file now using your preferred text editor. Here, we will use `nano`:

    nano my_env/lib/python3.6/site-packages/pgadmin4/config_local.py

In your editor, add the following content:

environments/my\_env/lib/python3.6/site-packages/pgadmin4/config\_local.py

    LOG_FILE = '/var/log/pgadmin4/pgadmin4.log'
    SQLITE_PATH = '/var/lib/pgadmin4/pgadmin4.db'
    SESSION_DB_PATH = '/var/lib/pgadmin4/sessions'
    STORAGE_DIR = '/var/lib/pgadmin4/storage'
    SERVER_MODE = True

Here are what these five directives do:

- `LOG_FILE`: this defines the file in which pgAdmin’s logs will be stored. 
- `SQLITE_PATH`: pgAdmin stores user-related data in an SQLite database, and this directive points the pgAdmin software to this configuration database. Because this file is located under the persistent directory `/var/lib/pgadmin4/`, your user data will not be lost after you upgrade.
- `SESSION_DB_PATH`: specifies which directory will be used to store session data.
- `STORAGE_DIR`: defines where pgAdmin will store other data, like backups and security certificates.
- `SERVER_MODE`: setting this directive to `True` tells pgAdmin to run in Server mode, as opposed to Desktop mode.

Notice that each of these file paths point to the directories you created in Step 1.

After adding these lines, save and close the file (press `CTRL + X`, followed by `Y` and then `ENTER`). With those configurations in place, run the pgAdmin setup script to set your login credentials:

    python my_env/lib/python3.6/site-packages/pgadmin4/setup.py

After running this command, you will see a prompt asking for your email address and a password. These will serve as your login credentials when you access pgAdmin later on, so be sure to remember or take note of what you enter here:

    Output. . .
    Enter the email address and password to use for the initial pgAdmin user account:
    
    Email address: sammy@example.com
    Password: 
    Retype password:

Following this, deactivate your virtual environment:

    deactivate 

Recall the file paths you specified in the `config_local.py` file. These files are held within the directories you created in Step 1, which are currently owned by your non-root user. They must, however, be accessible by the user and group running your web server. By default on Ubuntu 18.04, these are the **www-data** user and group, so update the permissions on the following directories to give **www-data** ownership over both of them:

    sudo chown -R www-data:www-data /var/lib/pgadmin4/
    sudo chown -R www-data:www-data /var/log/pgadmin4/

With that, pgAdmin is fully configured. However, the program isn’t yet being served from your server, so it remains inaccessible. To resolve this, we will configure Apache to serve pgAdmin so you can access its user interface through a web browser.

## Step 3 — Configuring Apache

The Apache web server uses _virtual hosts_ to encapsulate configuration details and host more than one domain from a single server. If you followed the prerequisite Apache tutorial, you may have set up an example virtual host file under the name `your_domain.conf`, but in this step we will create a new one from which we can serve the pgAdmin web interface.

To begin, make sure you’re in your root directory:

    cd /

Then create a new file in your `/sites-available/` directory called `pgadmin4.conf`. This will be your server’s virtual host file:

    sudo nano /etc/apache2/sites-available/pgadmin4.conf

Add the following content to this file, being sure to update the highlighted parts to align with your own configuration:

/etc/apache2/sites-available/pgadmin4.conf

    <VirtualHost *>
        ServerName your_server_ip
    
        WSGIDaemonProcess pgadmin processes=1 threads=25 python-home=/home/sammy/environments/my_env
        WSGIScriptAlias / /home/sammy/environments/my_env/lib/python3.6/site-packages/pgadmin4/pgAdmin4.wsgi
    
        <Directory "/home/sammy/environments/my_env/lib/python3.6/site-packages/pgadmin4/">
            WSGIProcessGroup pgadmin
            WSGIApplicationGroup %{GLOBAL}
            Require all granted
        </Directory>
    </VirtualHost>

Save and close the virtual host file. Next, use the `a2dissite` script to disable the default virtual host file, `000-default.conf`:

    sudo a2dissite 000-default.conf

**Note:** If you followed the prerequisite Apache tutorial, you may have already disabled `000-default.conf` and set up an example virtual host configuration file (named `your_domain.conf` in the prerequisite). If this is the case, you will need to disable the `your_domain.conf` virtual host file with the following command:

    sudo a2dissite your_domain.conf

Then use the `a2ensite` script to enable your `pgadmin4.conf` virtual host file. This will create a symbolic link from the virtual host file in the `/sites-available/` directory to the `/sites-enabled/` directory:

    sudo a2ensite pgadmin4.conf

Following this, test that your configuration file’s syntax is correct:

    apachectl configtest

If your configuration file is all in order, you will see `Syntax OK`. If you see an error in the output, reopen the `pgadmin4.conf` file and double check that your IP address and file paths are all correct, then rerun the `configtest`.

Once you see `Syntax OK` in your output, restart the Apache service so it reads your new virtual host file:

    sudo systemctl restart apache2

pgAdmin is now fully installed and configured. Next, we’ll go over how to access pgAdmin from a browser before connecting it to your PostgreSQL database.

## Step 4 — Accessing pgAdmin

On your local machine, open up your preferred web browser and navigate to your server’s IP address:

    http://your_server_ip

Once there, you’ll be presented with a login screen similar to the following:

![pgAdmin login screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/pgadmin_login_blank.png)

Enter the login credentials you defined in Step 2, and you’ll be taken to the pgAdmin Welcome Screen:

![pgAdmin Welcome Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/pgadmin_welcome_page_1.png)

Now that you’ve confirmed you can access the pgAdmin interface, all that’s left to do is to connect pgAdmin to your PostgreSQL database. Before doing so, though, you’ll need to make one minor change to your PostgreSQL superuser’s configuration.

## Step 5 — Configuring your PostgreSQL User

If you followed the [prerequisite PostgreSQL tutorial](how-to-install-and-use-postgresql-on-ubuntu-18-04), you should already have PostgreSQL installed on your server with a new superuser role and database set up.

By default in PostgreSQL, you authenticate as database users using the “Identification Protocol,” or “ident,” authentication method. This involves PostgreSQL taking the client’s Ubuntu username and using it as the allowed database username. This can allow for greater security in many cases, but it can also cause issues in instances where you’d like an outside program, such as pgAdmin, to connect to one of your databases. To resolve this, we will set a password for this PostgreSQL role which will allow pgAdmin to connect to your database.

From your terminal, open the PostgreSQL prompt under your superuser role:

    sudo -u sammy psql

From the PostgreSQL prompt, update the user profile to have a strong password of your choosing:

    ALTER USER sammy PASSWORD 'password';

Then exit the PostgreSQL prompt:

    \q

Next, go back to the pgAdmin 4 interface in your browser, and locate the **Browser** menu on the left hand side. Right-click on **Servers** to open a context menu, hover your mouse over **Create** , and click **Server…**.

![Create Server context menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_server_box_resized.png)

This will cause a window to pop up in your browser in which you’ll enter info about your server, role, and database.

In the **General** tab, enter the name for this server. This can be anything you’d like, but you may find it helpful to make it something descriptive. In our example, the server is named `Sammy-server-1`.

![Create Server - General tab](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/server_general_tab_resized.png)

Next, click on the **Connection** tab. In the **Host name/address** field, enter `localhost`. The **Port** should be set to `5432` by default, which will work for this setup, as that’s the default port used by PostgreSQL.

In the **Maintenance database** field, enter the name of the database you’d like to connect to. Note that this database must already be created on your server. Then, enter the PostgreSQL username and password you configured previously in the **Username** and **Password** fields, respectively.

![Create Server - Connection tab](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/connection_tab_resized.png)

The empty fields in the other tabs are optional, and it’s only necessary that you fill them in if you have a specific setup in mind in which they’re required. Click the **Save** button, and the database will appear under the **Servers** in the **Browser** menu.

You’ve successfully connected pgAdmin4 to your PostgreSQL database. You can do just about anything from the pgAdmin dashboard that you would from the PostgreSQL prompt. To illustrate this, we will create an example table and populate it with some sample data through the web interface.

## Step 6 — Creating a Table in the pgAdmin Dashboard

From the pgAdmin dashboard, locate the **Browser** menu on the left-hand side of the window. Click on the plus sign ( **+** ) next to **Servers (1)** to expand the tree menu within it. Next, click the plus sign to the left of the server you added in the previous step ( **Sammy-server-1** in our example), then expand **Databases** , the name of the database you added ( **sammy** , in our example), and then **Schemas (1)**. You should see a tree menu like the following:

![Expanded Browser tree menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/table_tree_menu_resized.png)

Right-click the **Tables** list item, then hover your cursor over **Create** and click **Table…**.

![Create Table context menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_resized.png)

This will open up a **Create-Table** window. Under the **General** tab of this window, enter a name for the table. This can be anything you’d like, but to keep things simple we’ll refer to it as **table-01**.

![Create Table - General tab](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_general_tab_1.png)

Then navigate to the **Columns** tab and click the **+** sign in the upper right corner of the window to add some columns. When adding a column, you’re required to give it a **Name** and a **Data type** , and you may need to choose a **Length** if it’s required by the data type you’ve selected.

Additionally, the [official PostgreSQL documentation](https://www.postgresql.org/docs/9.1/static/ddl-constraints.html#AEN2520) states that adding a primary key to a table is usually best practice. A _primary key_ is a constraint that indicates a specific column or set of columns that can be used as a special identifier for rows in the table. This isn’t a requirement, but if you’d like to set one or more of your columns as the primary key, toggle the switch at the far right from **No** to **Yes**.

Click the **Save** button to create the table.

![Create Table - Columns Tab with Primary Key turned on](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_add_column_1primkey.png)

By this point, you’ve created a table and added a couple columns to it. However, the columns don’t yet contain any data. To add data to your new table, right-click the name of the table in the **Browser** menu, hover your cursor over **Scripts** and click on **INSERT Script**.

![INSERT script context menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/insert_script_context_menu.png)

This will open a new panel on the dashboard. At the top you’ll see a partially-completed `INSERT` statement, with the appropriate table and column names. Go ahead and replace the question marks ( **?** ) with some dummy data, being sure that the data you add aligns with the data types you selected for each column. Note that you can also add multiple rows of data by adding each row in a new set of parentheses, with each set of parentheses separated by a comma as shown in the following example.

If you’d like, feel free to replace the partially-completed `INSERT` script with this example `INSERT` statement:

    INSERT INTO public."table-01"(
        col1, col2, col3)
        VALUES ('Juneau', 14, 337), ('Bismark', 90, 2334), ('Lansing', 51, 556);

![Example INSERT statement](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/insert_script.png)

Click on the lightning bolt icon ( **⚡** ) to execute the `INSERT` statement. To view the table and all the data within it, right-click the name of your table in the **Browser** menu once again, hover your cursor over **View/Edit Data** , and select **All Rows**.

![View/Edit Data, All Rows context menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/view_edit_data_all_rows.png)

This will open another new panel, below which, in the lower panel’s **Data Output** tab, you can view all the data held within that table.

![View Data - example data output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/view_data_output.png)

With that, you’ve successfully created a table and populated it with some data through the pgAdmin web interface. Of course, this is just one method you can use to create a table through pgAdmin. For example, it’s possible to create and populate a table using SQL instead of the GUI-based method described in this step.

## Conclusion

In this guide, you learned how to install pgAdmin 4 from a Python virtual environment, configure it, serve it to the web with Apache, and how to connect it to a PostgreSQL database. Additionally, this guide went over one method that can be used to create and populate a table, but pgAdmin can be used for much more than just creating and editing tables.

For more information on how to get the most out of all of pgAdmin’s features, we encourage you to review the [project’s documentation](https://www.pgadmin.org/docs/pgadmin4/3.x/). You can also learn more about PostgreSQL through our [Community tutorials](https://www.digitalocean.com/community/tags/postgresql?type=tutorials) on the subject.
