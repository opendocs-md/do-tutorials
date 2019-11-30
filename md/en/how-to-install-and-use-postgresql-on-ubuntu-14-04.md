---
author: Justin Ellingwood
date: 2014-04-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-14-04
---

# How To Install and Use PostgreSQL on Ubuntu 14.04

## Introduction

Relational database management systems are a key component of many web sites and applications. They provide a structured way to store, organize, and access information.

**PostgreSQL** , or Postgres, is a relational database management system that provides an implementation of the SQL querying language. It is a popular choice for many small and large projects and has the advantage of being standards-compliant and having many advanced features like reliable transactions and concurrency without read locks.

In this guide, we will demonstrate how to install Postgres on an Ubuntu 14.04 VPS instance and go over some basic ways to use it.

## Installation

Ubuntu’s default repositories contain Postgres packages, so we can install them without a hassle using the `apt` packaging system.

Since we haven’t updated our local apt repository lately, let’s do that now. We can then get the Postgres package and a “contrib” package that adds some additional utilities and functionality:

    sudo apt-get update
    sudo apt-get install postgresql postgresql-contrib

Now that our software is installed, we can go over how it works and how it may be different from similar database management systems you may have used.

## Using PostgreSQL Roles and Databases

By default, Postgres uses a concept called “roles” to aid in authentication and authorization. These are, in some ways, similar to regular Unix-style accounts, but Postgres does not distinguish between users and groups and instead prefers the more flexible term “role”.

Upon installation Postgres is set up to use “ident” authentication, meaning that it associates Postgres roles with a matching Unix/Linux system account. If a Postgres role exists, it can be signed in by logging into the associated Linux system account.

The installation procedure created a user account called `postgres` that is associated with the default Postgres role. In order to use Postgres, we’ll need to log into that account. You can do that by typing:

    sudo -i -u postgres

You will be asked for your normal user password and then will be given a shell prompt for the `postgres` user.

You can get a Postgres prompt immediately by typing:

    psql

You will be auto-logged in and will be able to interact with the database management system right away.

However, we’re going to explain a little bit about how to use other roles and databases so that you have some flexibility as to which user and database you wish to work with.

Exit out of the PostgreSQL prompt by typing:

    \q

You should now be back in the `postgres` Linux command prompt.

## Create a New Role

From the `postgres` Linux account, you have the ability to log into the database system. However, we’re also going to demonstrate how to create additional roles. The `postgres` Linux account, being associated with the Postgres administrative role, has access to some utilities to create users and databases.

We can create a new role by typing:

    createuser --interactive

This basically is an interactive shell script that calls the correct Postgres commands to create a user to your specifications. It will only ask you two questions: the name of the role and whether it should be a superuser. You can get more control by passing some additional flags. Check out the options by looking at the `man` page:

    man createuser

## Create a New Database

The way that Postgres is set up by default (authenticating roles that are requested by matching system accounts) also comes with the assumption that a matching database will exist for the role to connect to.

So if I have a user called `test1`, that role will attempt to connect to a database called `test1` by default.

You can create the appropriate database by simply calling this command as the `postgres` user:

    createdb test1

## Connect to Postgres with the New User

Let’s assume that you have a Linux system account called `test1` (you can create one by typing: `adduser test1`), and that you have created a Postgres role and database also called `test1`.

You can change to the Linux system account by typing:

    sudo -i -u test1

You can then connect to the `test1` database as the `test1` Postgres role by typing:

    psql

This will log in automatically assuming that all of the components have been configured.

If you want your user to connect to a different database, you can do so by specifying the database like this:

    psql -d postgres

You can get information about the Postgres user you’re logged in as and the database you’re currently connected to by typing:

    \conninfo

* * *

    You are connected to database "postgres" as user "postgres" via socket in "/var/run/postgresql" at port "5432".

This can help remind you of your current settings if you are connecting to non-default databases or with non-default users.

## Create and Delete Tables

Now that you know how to connect to the PostgreSQL database system, we will start to go over how to complete some basic tasks.

First, let’s create a table to store some data. Let’s create a table that describes playground equipment.

The basic syntax for this command is something like this:

    CREATE TABLE table\_name ( column\_name1 col\_type (field\_length) column\_constraints, column\_name2 col\_type (field\_length), column\_name3 col\_type (field\_length) );

As you can see, we give the table a name, and then define the columns that we want, as well as the column type and the max length of the field data. We can also optionally add table constraints for each column.

You can learn more about [how to create and manage tables in Postgres](https://digitalocean.com/community/articles/how-to-create-remove-manage-tables-in-postgresql-on-a-cloud-server) here.

For our purposes, we’re going to create a simple table like this:

    CREATE TABLE playground (
        equip_id serial PRIMARY KEY,
        type varchar (50) NOT NULL,
        color varchar (25) NOT NULL,
        location varchar(25) check (location in ('north', 'south', 'west', 'east', 'northeast', 'southeast', 'southwest', 'northwest')),
        install_date date
    );

We have made a playground table that inventories the equipment that we have. This starts with an equipment ID, which is of the `serial` type. This data type is an auto-incrementing integer. We have given this column the constraint of `primary key` which means that the values must be unique and not null.

For two of our columns, we have not given a field length. This is because some column types don’t require a set length because the length is implied by the type.

We then give columns for the equipment type and color, each of which cannot be empty. We then create a location column and create a constraint that requires the value to be one of eight possible values. The last column is a date column that records the date that we installed the equipment.

We can see our new table by typing this:

    \d

* * *

                       List of relations
     Schema | Name | Type | Owner   
    --------+-------------------------+----------+----------
     public | playground | table | postgres
     public | playground_equip_id_seq | sequence | postgres
    (2 rows)

As you can see, we have our playground table, but we also have something called `playground_equip_id_seq` that is of the type `sequence`. This is a representation of the “serial” type we gave our `equip_id` column. This keeps track of the next number in the sequence.

If you want to see just the table, you can type:

    \dt

* * *

               List of relations
     Schema | Name | Type | Owner   
    --------+------------+-------+----------
     public | playground | table | postgres
    (1 row)

## Add, Query, and Delete Data in a Table

Now that we have a table created, we can insert some data into it.

Let’s add a slide and a swing. We do this by calling the table we’re wanting to add to, naming the columns and then providing data for each column. Our slide and swing could be added like this:

    INSERT INTO playground (type, color, location, install\_date) VALUES ('slide', 'blue', 'south', '2014-04-28'); INSERT INTO playground (type, color, location, install\_date) VALUES ('swing', 'yellow', 'northwest', '2010-08-16');

You should notice a few things. First, keep in mind that the column names should not be quoted, but the column _values_ that you’re entering do need quotes.

Another thing to keep in mind is that we do not enter a value for the `equip_id` column. This is because this is auto-generated whenever a new row in the table is created.

We can then get back the information we’ve added by typing:

    SELECT * FROM playground;

* * *

| equip\_id | type | color | location | install\_date |
| --- | --- | --- | --- | --- |
| 1 | slide | blue | south | 2014-04-28 |
| 2 | swing | yellow | northwest | 2010-08-16 |

    (2 rows)

Here, you can see that our `equip_id` has been filled in successfully and that all of our other data has been organized correctly.

If our slide breaks and we remove it from the playground, we can also remove the row from our table by typing:

    DELETE FROM playground WHERE type = 'slide';

If we query our table again, we will see our slide is no longer a part of the table:

    SELECT * FROM playground;

* * *

| equip\_id | type | color | location | install\_date |
| --- | --- | --- | --- | --- |
| 2 | swing | yellow | northwest | 2010-08-16 |

    (1 row)

## How To Add and Delete Columns from a Table

If we want to modify a table after it has been created to add an additional column, we can do that easily.

We can add a column to show the last maintenance visit for each piece of equipment by typing:

    ALTER TABLE playground ADD last\_maint date;

If you view your table information again, you will see the new column has been added (but no data has been entered):

    SELECT * FROM playground;

* * *

| equip\_id | type | color | location | install\_date | last\_maint |
| --- | --- | --- | --- | --- | --- |
| 2 | swing | yellow | northwest | 2010-08-16 | |

    (1 row)

We can delete a column just as easily. If we find that our work crew uses a separate tool to keep track of maintenance history, we can get rid of the column here by typing:

    ALTER TABLE playground DROP last_maint;

## How To Update Data in a Table

We know how to add records to a table and how to delete them, but we haven’t covered how to modify existing entries yet.

You can update the values of an existing entry by querying for the record you want and setting the column to the value you wish to use. We can query for the “swing” record (this will match _every_ swing in our table) and change its color to “red”. This could be useful if we gave it a paint job:

    UPDATE playground SET color = 'red' WHERE type = 'swing';

We can verify that the operation was successful by querying our data again:

    SELECT * FROM playground;

* * *

| equip\_id | type | color | location | install\_date |
| --- | --- | --- | --- | --- |
| 2 | swing | red | northwest | 2010-08-16 |

    (1 row)

As you can see, our slide is now registered as being red.

## Conclusion

You are now set up with PostgreSQL on your Ubuntu 14.04 server. However, there is still _much_ more to learn with Postgres. Here are some more guides that cover how to use Postgres:

- [A comparison of relational database management systems](https://digitalocean.com/community/articles/sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems)
- [Learn how to create and manage tables with Postgres](https://digitalocean.com/community/articles/how-to-create-remove-manage-tables-in-postgresql-on-a-cloud-server)
- [Get better at managing roles and permissions](https://digitalocean.com/community/articles/how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2)
- [Craft queries with Postgres with Select](https://digitalocean.com/community/articles/how-to-create-data-queries-in-postgresql-by-using-the-select-command)
- [Install phpPgAdmin to administer databases from a web interface](https://digitalocean.com/community/articles/how-to-install-and-use-phppgadmin-on-ubuntu-12-04)
- [Learn how to secure PostgreSQL](https://digitalocean.com/community/articles/how-to-secure-postgresql-on-an-ubuntu-vps)
- [Set up master-slave replication with Postgres](https://digitalocean.com/community/articles/how-to-set-up-master-slave-replication-on-postgresql-on-an-ubuntu-12-04-vps)
- [Learn how to backup a Postgres database](https://digitalocean.com/community/articles/how-to-backup-postgresql-databases-on-an-ubuntu-vps)

By Justin Ellingwood
