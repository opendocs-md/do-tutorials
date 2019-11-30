---
author: Mark Drake
date: 2019-05-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-migrate-mysql-database-to-postgres-using-pgloader
---

# How To Migrate a MySQL Database to PostgreSQL Using pgLoader

## Introduction

[PostgreSQL](https://www.postgresql.org/), also known as “Postgres,” is an open-source relational database management system (RDBMS). It has seen a [drastic growth in popularity](https://db-engines.com/en/ranking_trend/system/PostgreSQL) in recent years, with many developers and companies migrating their data to Postgres from other database solutions.

The prospect of migrating a database can be intimidating, especially when migrating from one database management system to another. [pgLoader](https://pgloader.io/) is an open-source database migration tool that aims to simplify the process of migrating to PostgreSQL. It supports migrations from several file types and RBDMSs — including [MySQL](https://www.mysql.com/) and [SQLite](https://www.sqlite.org/index.html) — to PostgreSQL.

This tutorial provides instructions on how to install pgLoader and use it to migrate a remote MySQL database to PostgreSQL over an SSL connection. Near the end of the tutorial, we will also briefly touch on a few different migration scenarios where pgLoader may be useful.

## Prerequisites

To complete this tutorial, you’ll need the following:

- Access to **two** servers, each running Ubuntu 18.04. Both servers should have a firewall and a non-root user with sudo privileges configured. To set these up, you can follow our [Initial Server Setup guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).
- MySQL installed on **one of the servers**. To set this up, follow **Steps 1, 2, and 3** of our guide on [How To Install MySQL on Ubuntu 18.04](how-to-install-mysql-on-ubuntu-18-04). Please note that in order to complete all the prerequisite tutorials linked here, you will need to configure your **root** MySQL user to authenticate with a password, as described in [Step 3](how-to-install-mysql-on-ubuntu-18-04#step-3-%E2%80%94-(optional)-adjusting-user-authentication-and-privileges) of the MySQL installation guide.
- PostgreSQL installed on **the other server**. To set this up, complete **Step 1** of our guide [How To Install and Use PostgreSQL on Ubuntu 18.04](how-to-install-and-use-postgresql-on-ubuntu-18-04).
- Your **MySQL server** should also be configured to accept encrypted connections. To set this up, complete every step of our tutorial on [How To Configure SSL/TLS for MySQL on Ubuntu 18.04](how-to-configure-ssl-tls-for-mysql-on-ubuntu-18-04), including the optional [**Step 6**](how-to-configure-ssl-tls-for-mysql-on-ubuntu-18-04#step-6-%E2%80%94-(optional)-configuring-validation-for-mysql-connections). As you follow this guide, be sure to use your **PostgreSQL server** as the MySQL client machine, as you will need to be able to connect to your MySQL server from your Postgres machine in order to migrate the data with pgLoader.

Please note that throughout this guide, the server on which you installed MySQL will be referred to as the “ **MySQL server** ” and any commands that should be run on this machine will be shown with a blue background, like this:

    

Similarly, this guide will refer to the other server as the “ **PostgreSQL** ” or “ **Postgres” server** and any commands that must be run on that machine will be shown with a red background:

    

Please keep these in mind as you follow this tutorial so as to avoid any confusion.

## Step 1 — (Optional) Creating a Sample Database and Table in MySQL

This step describes the process of creating a test database and populating it with dummy data. We encourage you to practice using pgLoader with this test case, but if you already have a database you want to migrate, you can move on to the [next step](how-to-migrate-mysql-database-to-postgres-using-pgloader#step-2-%E2%80%94-installing-pgloader).

Start by opening up the MySQL prompt on your MySQL server:

    mysql -u root -p

After entering your **root** MySQL user’s password, you will see the MySQL prompt.

From there, create a new database by running the following command. You can name your database whatever you’d like, but in this guide we will name it `source_db`:

    CREATE DATABASE source_db;

Then switch to this database with the `USE` command:

    USE source_db;

    OutputDatabase changed

Within this database, use the following command to create a sample table. Here, we will name this table `sample_table` but feel free to give it another name:

    CREATE TABLE sample_table (
        employee_id INT PRIMARY KEY,
        first_name VARCHAR(50),
        last_name VARCHAR(50),
        start_date DATE,
        salary VARCHAR(50)
    );

Then populate this table with some sample employee data using the following command:

    INSERT INTO sample_table (employee_id, first_name, last_name, start_date, salary) 
    VALUES (1, 'Elizabeth', 'Cotten', '2007-11-11', '$105433.18'),
    (2, 'Yanka', 'Dyagileva', '2017-10-30', '$107540.67'),
    (3, 'Lee', 'Dorsey', '2013-06-04', '$118024.04'),
    (4, 'Kasey', 'Chambers', '2010-08-18', '$116456.98'),
    (5, 'Bram', 'Tchaikovsky', '2018-09-16', '$61989.50');

Following this, you can close the MySQL prompt:

    exit

Now that you have a sample database loaded with dummy data, you can move on to the next step in which you will install pgLoader on your PostgreSQL server.

## Step 2 — Installing pgLoader

pgLoader is a program that can load data into a PostgreSQL database from a variety of different sources. It uses [PostgreSQL’s `COPY` command](http://www.postgresql.org/docs/current/interactive/sql-copy.html) to copy data from a source database or file — such as a [comma-separated values (CSV)](https://en.wikipedia.org/wiki/Comma-separated_values) file — into a target PostgreSQL database.

pgLoader is available from the default Ubuntu APT repositories and you can install it using the `apt` command. However, in this guide we will take advantage of pgLoader’s `useSSL` option, a feature that allows for migrations from MySQL over an SSL connection. This feature is only available in the latest version of pgLoader which, as of this writing, can only be installed using the source code from its GitHub repository.

Before installing pgLoader, you will need to install its dependencies. If you haven’t done so recently, update **your Postgres server’s** package index:

    sudo apt update

Then install the following packages:

- `sbcl`: A [Common Lisp](https://en.wikipedia.org/wiki/Common_Lisp) compiler
- `unzip`: A de-archiver for `.zip` files
- `libsqlite3-dev`: A collection of development files for SQLite 3
- `gawk`: Short for “GNU awk”, a pattern scanning and processing language
- `curl`: A command line tool for transferring data from a URL
- `make`: A utility for managing package compilation
- `freetds-dev`: A client library for MS SQL and Sybase databases
- `libzip-dev`: A library for reading, creating, and modifying zip archives

Use the following command to install these dependencies:

    sudo apt install sbcl unzip libsqlite3-dev gawk curl make freetds-dev libzip-dev

When prompted, confirm that you want to install these packages by pressing `ENTER`.

Next, navigate to the pgLoader GitHub project’s [**Releases** page](https://github.com/dimitri/pgloader/releases) and find the latest release. For this guide, we will use the latest release at the time of this writing: [version 3.6.1](https://github.com/dimitri/pgloader/releases/tag/v3.6.1). Scroll down to its **Assets** menu and copy the link for the `tar.gz` file labeled **Source code**. Then paste the link into the following `wget` command. This will download the tarball to your server:

    wget https://github.com/dimitri/pgloader/archive/v3.6.1.tar.gz

Extract the tarball:

    tar xvf v3.6.1.tar.gz

This will create a number of new directories and files on your server. Navigate into the new pgLoader parent directory:

    cd pgloader-3.6.1/

Then use the `make` utility to compile the `pgloader` binary:

    make pgloader

This command will take some time to build the `pgloader` binary.

Move the binary file into the `/usr/local/bin` directory, the location where Ubuntu looks for executable files:

    sudo mv ./build/bin/pgloader /usr/local/bin/

You can test that pgLoader was installed correctly by checking its version, like so:

    pgloader --version

    Outputpgloader version "3.6.1"
    compiled with SBCL 1.4.5.debian

pgLoader is now installed, but before you can begin your migration you’ll need to make some configuration changes to both your PostgreSQL and MySQL instances. We’ll focus on the PostgreSQL server first.

## Step 3 — Creating a PostgreSQL Role and Database

The `pgloader` command works by copying source data, either from a file or directly from a database, and inserting it into a PostgreSQL database. For this reason, you must either run pgLoader as a Linux user who has access to your Postgres database or you must specify a PostgreSQL role with the appropriate permissions in your load command.

PostgreSQL manages database access through the use of [_roles_](https://www.postgresql.org/docs/8.1/user-manag.html). Depending on how the role is configured, it can be thought of as either a database user or a group of database users. In most RDBMSs, you create a user with the `CREATE USER` SQL command. Postgres, however, comes installed with a handy script called `createuser`. This script serves as a wrapper for the `CREATE USER` SQL command that you can run directly from the command line.

**Note:** In PostgreSQL, you authenticate as a database user using the [Identification Protocol](https://www.postgresql.org/docs/9.0/auth-methods.html#AUTH-IDENT), or _ident_, authentication method by default, rather than with a password. This involves PostgreSQL taking the client’s Ubuntu username and using it as the allowed Postgres database username. This allows for greater security in many cases, but it can also cause issues in instances where you’d like an outside program to connect to one of your databases.

pgLoader can load data into a Postgres database through a role that authenticates with the ident method as long as that role shares the same name as the Linux user profile issuing the `pgloader` command. However, to keep this process as clear as possible, this tutorial describes setting up a different PostgreSQL role that authenticates with a password rather than with the ident method.

Run the following command on your Postgres server to create a new role. Note the `-P` flag, which tells `createuser` to prompt you to enter a password for the new role:

    sudo -u postgres createuser --interactive -P

You may first be prompted for your `sudo` password. The script will then prompt you to enter a name for the new role. In this guide, we’ll call this role **pgloader\_pg** :

    OutputEnter name of role to add: pgloader_pg

Following that, `createuser` will prompt you to enter and confirm a password for this role. Be sure to take note of this password, as you’ll need it to perform the migration in Step 5:

    OutputEnter password for new role: 
    Enter it again: 

Lastly, the script will ask you if the new role should be classified as a superuser. In PostgreSQL, connecting to the database with a superuser role allows you to circumvent all of the database’s permissions checks, except for the right to log in. Because of this, the superuser privilege should not be used lightly, and the [PostgreSQL documentation recommends](https://www.postgresql.org/docs/11/role-attributes.html) that you do most of your database work as a non-superuser role. However, because pgLoader needs broad privileges to access and load data into tables, you can safely grant this new role superuser privileges. Do so by typing `y` and then pressing `ENTER`:

    Output. . .
    Shall the new role be a superuser? (y/n) y

PostgreSQL comes with another useful script that allows you to create a database from the command line. Since pgLoader also needs a target database into which it can load the source data, run the following command to create one. We’ll name this database `new_db` but feel free to modify that if you like:

    sudo -u postgres createdb new_db

If there aren’t any errors, this command will complete without any output.

Now that you have a dedicated PostgreSQL user and an empty database into which you can load your MySQL data, there are just a few more changes you’ll need to make before performing a migration. You’ll need to create a dedicated MySQL user with access to your source database and add your client-side certificates to Ubuntu’s trusted certificate store.

## Step 4 — Creating a Dedicated User in MySQL and Managing Certificates

Protecting data from snoopers is one of the most important parts of any database administrator’s job. Migrating data from one machine to another opens up an opportunity for malicious actors to [sniff](https://en.wikipedia.org/wiki/Sniffing_attack) the packets traveling over the network connection if it isn’t encrypted. In this step, you will create a dedicated MySQL user which pgLoader will use to perform the migration over an SSL connection.

Begin by opening up your MySQL prompt:

    mysql -u root -p

From the MySQL prompt, use the following `CREATE USER` command to create a new MySQL user. We will name this user **pgloader\_my**. Because this user will only access MySQL from your PostgreSQL server, be sure to replace `your_postgres_server_ip` with the public IP address of your PostgreSQL server. Additionally, replace `password` with a secure password or passphrase:

    CREATE USER 'pgloader_my'@'your_postgres_server_ip' IDENTIFIED BY 'password' REQUIRE SSL;

Note the `REQUIRE SSL` clause at the end of this command. This will restrict the **pgloader\_my** user to only access the database through a secure SSL connection.

Next, grant the **pgloader\_my** user access to the target database and all of its tables. Here, we’ll specify the database we created in the optional Step 1, but if you have your own database you’d like to migrate, use its name in place of `source_db`:

    GRANT ALL ON source_db.* TO 'pgloader_my'@'your_postgresql_server_ip';

Then run the `FLUSH PRIVILEGES` command to reload the grant tables, enabling the privilege changes:

    FLUSH PRIVILEGES;

After this, you can close the MySQL prompt:

    exit

Now go back to your Postgres server terminal and attempt to log in to the MySQL server as the new **pgloader\_my** user. If you followed the prerequisite guide on [configuring SSL/TLS for MySQL](how-to-configure-ssl-tls-for-mysql-on-ubuntu-18-04) then you will already have `mysql-client` installed on your PostgreSQL server and you should be able to connect with the following command:

    mysql -u pgloader_my -p -h your_mysql_server_ip

If the command is successful, you will see the MySQL prompt:

    

After confirming that your **pgloader\_my** user can successfully connect, go ahead and close the prompt:

    exit

At this point, you have a dedicated MySQL user that can access the source database from your Postgres machine. However, if you were to try to migrate your MySQL database using SSL the attempt would fail.

The reason for this is that pgLoader isn’t able to read MySQL’s configuration files, and thus doesn’t know where to look for the CA certificate or client certificate that you copied to your PostgreSQL server in the prerequisite [SSL/TLS configuration guide](how-to-configure-ssl-tls-for-mysql-on-ubuntu-18-04). Rather than ignoring SSL requirements, though, pgLoader requires the use of trusted certificates in cases where SSL is needed to connect to MySQL. Accordingly, you can resolve this issue by adding the `ca.pem` and `client-cert.pem` files to [Ubuntu’s trusted certificate store](https://help.ubuntu.com/lts/serverguide/certificates-and-security.html.en).

To do this, copy over the `ca.pem` and `client-cert.pem` files to the `/usr/local/share/ca-certificates/` directory. Note that you must also rename these files so they have the `.crt` file extension. If you don’t rename them, your system will not be able to recognize that you’ve added these new certificates:

    sudo cp ~/client-ssl/ca.pem /usr/local/share/ca-certificates/ca.pem.crt
    sudo cp ~/client-ssl/client-cert.pem /usr/local/share/ca-certificates/client-cert.pem.crt

Following this, run the `update-ca-certificates` command. This program looks for certificates within `/usr/local/share/ca-certificates`, adds any new ones to the `/etc/ssl/certs/` directory, and generates a list of trusted SSL certificates — `ca-certificates.crt` — based on the contents of the `/etc/ssl/certs/` directory:

    sudo update-ca-certificates

    OutputUpdating certificates in /etc/ssl/certs...
    2 added, 0 removed; done.
    Running hooks in /etc/ca-certificates/update.d...
    done.

With that, you’re all set to migrate your MySQL database to PostgreSQL.

## Step 5 — Migrating the Data

Now that you’ve configured remote access from your PostgreSQL server to your MySQL server, you’re ready to begin the migration.

**Note:** It’s important to back up your database before taking any action that could impact the integrity of your data. However, this isn’t necessary when performing a migration with pgLoader, since it doesn’t delete or transform data; it only copies it.

That said, if you’re feeling cautious and would like to back up your data before migrating it, you can do so with the `mysqldump` utility. See [the official MySQL documentation](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html) for details.

pgLoader allows users to migrate an entire database with a single command. For a migration from a MySQL database to a PostgreSQL database on a separate server, the command would have the following syntax:

    pgloader mysql://mysql_username:password@mysql_server_ip_/source_database_name?option_1=value&option_n=value postgresql://postgresql_role_name:password@postgresql_server_ip/target_database_name?option_1=value&option_n=value

This includes the `pgloader` command and two _connection strings_, the first for the source database and the second for the target database. Both of these connection strings begin by declaring what type of DBMS the connection string points to, followed by the username and password that have access to the database (separated by a colon), the host address of the server where the database is installed, the name of the database pgLoader should target, and [various options](https://pgloader.readthedocs.io/en/latest/pgloader.html?highlight=connection%20string#connection-string) that affect pgLoader’s behavior.

Using the parameters defined earlier in this tutorial, you can migrate your MySQL database using a command with the following structure. Be sure to replace any highlighted values to align with your own setup:

    pgloader mysql://pgloader_my:mysql_password@mysql_server_ip/source_db?useSSL=true postgresql://pgloader_pg:postgresql_password@localhost/new_db

Note that this command includes the `useSSL` option in the MySQL connection string. By setting this option to `true`, pgLoader will connect to MySQL over SSL. This is necessary, as you’ve configured your MySQL server to only accept secure connections.

If this command is successful, you will see an output table describing how the migration went:

    Output table name errors rows bytes total time
    ----------------------- --------- --------- --------- --------------
            fetch meta data 0 2 0.111s
             Create Schemas 0 0 0.001s
           Create SQL Types 0 0 0.005s
              Create tables 0 2 0.017s
             Set Table OIDs 0 1 0.010s
    ----------------------- --------- --------- --------- --------------
     source_db.sample_table 0 5 0.2 kB 0.048s
    ----------------------- --------- --------- --------- --------------
    COPY Threads Completion 0 4 0.052s
     Index Build Completion 0 1 0.011s
             Create Indexes 0 1 0.006s
            Reset Sequences 0 0 0.014s
               Primary Keys 0 1 0.001s
        Create Foreign Keys 0 0 0.000s
            Create Triggers 0 0 0.000s
           Install Comments 0 0 0.000s
    ----------------------- --------- --------- --------- --------------
          Total import time ✓ 5 0.2 kB 0.084s

To check that the data was migrated correctly, open up the PostgreSQL prompt:

    sudo -i -u postgres psql

From there, connect to the database into which you loaded the data:

    \c new_db

Then run the following query to test whether the migrated data is stored in your PostgreSQL database:

    SELECT * FROM source_db.sample_table;

**Note:** Notice the `FROM` clause in this query specifying the `sample_table` held within the `source_db` [schema](https://en.wikipedia.org/wiki/Database_schema):

    . . . FROM source_db.sample_table;

This is called a _qualified name_. You could go further and specify the _fully qualified name_ by including the database’s name as well as those of the schema and table:

    . . . FROM new_db.source_db.sample_table;

When you run queries in a PostgreSQL database, you don’t need to be this specific if the table is held within the default `public` schema. The reason you must do so here is that when pgLoader loads data into Postgres, it creates and targets a new schema named after the original database — in this case, `source_db`. This is pgLoader’s default behavior for MySQL to PostgreSQL migrations. However, you can use a load file to instruct pgLoader to change the table’s schema to`public`once it’s done loading data. See the next step for an example of how to do this.

If the data was indeed loaded correctly, you will see the following table in the query’s output:

    Output employee_id | first_name | last_name | start_date | salary   
    -------------+------------+-------------+------------+------------
               1 | Elizabeth | Cotten | 2007-11-11 | $105433.18
               2 | Yanka | Dyagileva | 2017-10-30 | $107540.67
               3 | Lee | Dorsey | 2013-06-04 | $118024.04
               4 | Kasey | Chambers | 2010-08-18 | $116456.98
               5 | Bram | Tchaikovsky | 2018-09-16 | $61989.50
    (5 rows)

To close the Postgres prompt, run the following command:

    \q

Now that we’ve gone over how to migrate a MySQL database over a network and load it into a PostgreSQL database, we will go over a few other common migration scenarios in which pgLoader can be useful.

## Step 6 — Exploring Other Migration Options

pgLoader is a highly flexible tool that can be useful in a wide variety of situations. Here, we’ll take a quick look at a few other ways you can use pgLoader to migrate a MySQL database to PostgreSQL.

### Migrating with a pgLoader Load File

In the context of pgLoader, a _load file_, or _command file_, is a file that tells pgLoader how to perform a migration. This file can include commands and options that affect pgLoader’s behavior, giving you much finer control over how your data is loaded into PostgreSQL and allowing you to perform complex migrations.

[pgLoader’s documentation](https://pgloader.readthedocs.io/en/latest/pgloader.html#pgloader-commands-syntax) provides comprehensive instructions on how to use and extend these files to support a number of migration types, so here we will work through a comparatively rudimentary example. We will perform the same migration we ran in Step 5, but will also include an `ALTER SCHEMA` command to change the `new_db` database’s schema from `source_db` to `public`.

To begin, create a new load file on the Postgres server using your preferred text editor:

    nano pgload_test.load

Then add the following content, making sure to update the highlighted values to align with your own configuration:

pgload\_test.load

    LOAD DATABASE
         FROM mysql://pgloader_my:mysql_password@mysql_server_ip/source_db?useSSL=true
         INTO pgsql://pgloader_pg:postgresql_password@localhost/new_db
    
     WITH include drop, create tables
    
    ALTER SCHEMA 'source_db' RENAME TO 'public'
    ;

Here is what each of these clauses do:

- `LOAD DATABASE`: This line instructs pgLoader to load data from a separate database, rather than a file or data archive. 
- `FROM`: This clause specifies the source database. In this case, it points to the connection string for the MySQL database we created in [Step 1](how-to-migrate-mysql-database-to-postgres-using-pgloader#step-1-%E2%80%94-(optional)-creating-a-sample-database-and-table-in-mysql).
- `INTO`: Likewise, this line specifies the PostgreSQL database in to which pgLoader should load the data. 
- `WITH`: This clause allows you to define specific behaviors for pgLoader. You can find the full list of `WITH` options that are compatible with MySQL migrations [here](https://pgloader.readthedocs.io/en/latest/ref/mysql.html#mysql-database-migration-options-with). In this example we only include two options:
  - `include drop`: When this option is used, pgLoader will drop any tables in the target PostgreSQL database that also appear in the source MySQL database. If you use this option when migrating data to an existing PostgreSQL database, you should back up the entire database to avoid losing any data.
  - `create tables`: This option tells pgLoader to create new tables in the target PostgreSQL database based on the metadata held in the MySQL database. If the opposite option, `create no tables`, is used, then the target tables must already exist in the target Postgres database prior to the migration. 
- `ALTER SCHEMA`: Following the `WITH` clause, you can add specific SQL commands like this to instruct pgLoader to perform additional actions. Here, we instruct pgLoader to change the new Postgres database’s schema from `source_db` to `public`, but only after it has created the schema. Note that you can also nest such commands within other clauses — such as `BEFORE LOAD DO` — to instruct pgLoader to execute those commands at specific points in the migration process.

This is a demonstrative example of what you can include in a load file to modify pgLoader’s behavior. The complete list of clauses that one can add to a load file and what they do can be found in [the official pgLoader documentation](https://pgloader.readthedocs.io/en/latest/pgloader.html#common-clauses).

Save and close the load file after you’ve finished adding this content. To use it, include the name of the file as an argument to the `pgloader` command:

    pgloader pgload_test.load

To test that the migration was successful, open up the Postgres prompt:

    sudo -u postgres psql

Then connect to the database:

    \c new_db

And run the following query:

    SELECT * FROM sample_table;

    Output employee_id | first_name | last_name | start_date | salary   
    -------------+------------+-------------+------------+------------
               1 | Elizabeth | Cotten | 2007-11-11 | $105433.18
               2 | Yanka | Dyagileva | 2017-10-30 | $107540.67
               3 | Lee | Dorsey | 2013-06-04 | $118024.04
               4 | Kasey | Chambers | 2010-08-18 | $116456.98
               5 | Bram | Tchaikovsky | 2018-09-16 | $61989.50
    (5 rows)

This output confirms that pgLoader migrated the data successfully, and also that the `ALTER SCHEMA` command we added to the load file worked as expected, since we didn’t need to specify the `source_db` schema in the query to view the data.

Note that if you plan to use a load file to migrate data held on one database to another located on a separate machine, you will still need to adjust any relevant networking and firewall rules in order for the migration to be successful.

### Migrating a MySQL Database to PostgreSQL Locally

You can use pgLoader to migrate a MySQL database to a PostgreSQL database housed on the same machine. All you need is to run the migration command from a Linux user profile with access to the **root** MySQL user:

    pgloader mysql://root@localhost/source_db pgsql://sammy:postgresql_password@localhost/target_db

Performing a local migration like this means you don’t have to make any changes to MySQL’s default networking configuration or your system’s firewall rules.

### Migrating from a CSV file

You can also load a PostgreSQL database with data from a CSV file.

Assuming you have a CSV file of data named `load.csv`, the command to load it into a Postgres database might look like this:

    pgloader load.csv pgsql://sammy:password@localhost/target_db

Because the CSV format is not fully standardized, there’s a chance that you will run into issues when loading data directly from a CSV file in this manner. Fortunately, you can correct for irregularities by including various options with [pgLoader’s command line options](https://pgloader.readthedocs.io/en/latest/quickstart.html#csv) or by specifying them in a load file. See [the pgLoader documentation](https://pgloader.readthedocs.io/en/latest/ref/csv.html) on the subject for more details.

### Migrating to a Managed PostgreSQL Database

It’s also possible to perform a migration from a self-managed database to a managed PostgreSQL database. To illustrate how this kind of migration could look, we will use the MySQL server and a DigitalOcean Managed PostgreSQL Database. We’ll also use the sample database we created in [Step 1](how-to-migrate-mysql-database-to-postgres-using-pgloader#step-1-%E2%80%94-(optional)-creating-a-sample-database-and-table-in-mysql), but if you skipped that step and have your own database you’d like to migrate, you can point to that one instead.

**Note:** For instructions on how to set up a DigitalOcean Managed Database, please refer to our [Managed Database Quickstart](https://www.digitalocean.com/docs/databases/quickstart/) guide.

For this migration, we won’t need pgLoader’s `useSSL` option since it only works with remote MySQL databases and we will run this migration from a local MySQL database. However, we will use the `sslmode=require` option when we load and connect to the DigitalOcean Managed PostgreSQL database, which will ensure your data stays protected.

Because we’re not using the `useSSL` this time around, you can use `apt` to install pgLoader along with the `postgresql-client` package, which will allow you to access the Managed PostgreSQL Database from your MySQL server:

    sudo apt install pgloader postgresql-client

Following that, you can run the `pgloader` command to migrate the database. To do this, you’ll need the connection string for the Managed Database.

For DigitalOcean Managed Databases, you can copy the connection string from the Cloud Control Panel. First, click **Databases** in the left-hand sidebar menu and select the database to which you want to migrate the data. Then scroll down to the **Connection Details** section. Click on the drop down menu and select **Connection string**. Then, click the **Copy** button to copy the string to your clipboard and paste it into the following migration command, replacing the example PostgreSQL connection string shown here. This will migrate your MySQL database into the `defaultdb` PostgreSQL database as the **doadmin** PostgreSQL role:

    pgloader mysql://root:password@localhost/source_db postgres://doadmin:password@db_host/defaultdb?sslmode=require

Following this, you can use the same connection string as an argument to `psql` to connect to the managed PostgreSQL database andhttps://[www.digitalocean.com/community/tutorials/how-to-migrate-mysql-database-to-postgres-using-pgloader#step-1-%E2%80%94-(optional)-creating-a-sample-database-and-table-in-mysql](http://www.digitalocean.com/community/tutorials/how-to-migrate-mysql-database-to-postgres-using-pgloader#step-1-%E2%80%94-(optional)-creating-a-sample-database-and-table-in-mysql) confirm that the migration was successful:

    psql postgres://doadmin:password@db_host/defaultdb?sslmode=require

Then, run the following query to check that pgLoader correctly migrated the data:

    SELECT * FROM source_db.sample_table;

    Output employee_id | first_name | last_name | start_date | salary   
    -------------+------------+-------------+------------+------------
               1 | Elizabeth | Cotten | 2007-11-11 | $105433.18
               2 | Yanka | Dyagileva | 2017-10-30 | $107540.67
               3 | Lee | Dorsey | 2013-06-04 | $118024.04
               4 | Kasey | Chambers | 2010-08-18 | $116456.98
               5 | Bram | Tchaikovsky | 2018-09-16 | $61989.50
    (5 rows)

This confirms that pgLoader successfully migrated your MySQL database to your managed PostgreSQL instance.

## Conclusion

pgLoader is a flexible tool that can perform a database migration in a single command. With a few configuration tweaks, it can migrate an entire database from one physical machine to another using a secure SSL/TLS connection. Our hope is that by following this tutorial, you will have gained a clearer understanding of pgLoader’s capabilities and potential use cases.

After migrating your data over to PostgreSQL, you may find the following tutorials to be of interest:

- [An Introduction to Queries in PostgreSQL](introduction-to-queries-postgresql)
- [How To Install and Configure pgAdmin 4 in Server Mode](how-to-install-configure-pgadmin4-server-mode)
- [How To Audit a PostgreSQL Database with InSpec on Ubuntu 18.04](how-to-audit-a-postgresql-database-with-inspec-on-ubuntu-18-04)
