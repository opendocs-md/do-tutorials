---
author: Gareth Dwyer
date: 2013-10-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-and-when-to-use-sqlite
---

# How and When to Use Sqlite

Sqlite is a very simple and fast open source SQL engine. This tutorial will explain when it is optimal to use Sqlite, as opposed to a full-blown RDBMS such as Mysql or Postgres, as well as how to install it and basic usage examples covering CRUD - Create, Read, Update, and Delete.

## Misconceptions

* * *

Don’t be deceived into thinking that Sqlite is only for testing and development. For example, it works fine for websites receiving up to 100,000 hits a day– and this is a conservative limit. The maximum size for a Sqlite database is 140 Terabytes (which should be enough, right?), and it can be substantially faster than a full-blown RDBMS. The full database and all other necessary data is stored in a normal file in the host’s file system, so no separate server process is needed (cutting out all need for slow inter-process communication).

## Optimal Usage on your VPS

* * *

Sqlite is focused on simplicity. Because it is completely internal, it is often significantly faster than alternatives. If you are looking for portability (with regards to both languages and platforms), simplicity, speed, and a small memory footprint–Sqlite is ideal. Its shortcomings are only apparent if you need high reading or writing concurrency: Sqlite can only support one writer at a time, and the normally high file system latency may be inconvenient if there is a need for many clients to access a Sqlite database simultaneously. A final possible disadvantage is that its syntax, though similar to other SQL systems, is unique. While it’s fairly trivial to move to another system, if you do ‘outgrow’ Sqlite, there will be some overhead involved in the transition.

For more information,, there are some very good outlines on the pros and cons of Sqlite [here](http://www.sqlite.org/whentouse.html).

## Install Sqlite on your VPS

* * *

The sqlite3 module is part of the standard Python library, so on a standard Ubuntu installation or any system with Python installed, no further installation is strictly necessary. To install the Sqlite command line interface on Ubuntu, use these commands:

    sudo apt-get update
    sudo apt-get install sqlite3 libsqlite3-dev

If you need to compile it from source, then grab the latest autoconf version from [sqlite.org/download.html](http://sqlite.org/download.html). At the time of writing:

    wget http://sqlite.org/2013/sqlite-autoconf-3080100.tar.gz
    tar xvfz sqlite-autoconf-3080100.tar.gz
    cd sqlite-autoconf-3080100
    ./configure
    make
    make install

(Notes for building from source: 1) Don’t do this on a standard Ubuntu installation, as you’ll probably get a “header and source version mismatch” error, due to conflict between an already installed version and the newly installed one. 2) If the `make` command seems to expect further input, just be patient, as the source can take a while to compile).

## Basic Command Line Interface Usage

* * *

To create a database, run the command:

    sqlite3 database.db

Where 'database’ is the name of your database. If the file `database.db` already exists, Sqlite will open a connection to it; if it does not exist, it will be created. You should see output similar to:

    SQLite version 3.8.1 2013-10-17 12:57:35
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite>

Now let’s create a table and insert some data. This table named “wines” has four columns: for an ID, the wine’s producer, the wine’s kind, and country of the wine’s origin. As it’s not Friday yet, we’ll insert only three wines into our database:

    CREATE TABLE wines (id integer, producer varchar(30), kind varchar(20), country varchar(20)); 
    INSERT INTO WINES VALUES (1, "Rooiberg", "Pinotage", "South Africa");
    INSERT INTO WINES VALUES (2, "KWV", "Shiraz", "South Africa");
    INSERT INTO WINES VALUES (3, "Marks & Spencer", "Pinot Noir", "France");

We’ve created the database, a table, and some entries. Now press `Ctrl + D` to exit Sqlite and type the following (again substituting your database’s name for 'database’), which will reconnect to the database we just created:

    sqlite3 database.db

Now type:

    SELECT * FROM wines;

And you should see the entries we’ve just made:

    1|Rooiberg|Pinotage|South Africa
    2|KWV|Shiraz|South Africa
    3|Marks & Spencer|Pinot Noir|France

Great. That’s it for creating and reading. Let’s do an update and delete:

    UPDATE wines SET country="South Africa" WHERE country="France";

Which will update the database so all wines which are listed as coming from France will instead be listed as coming from South Africa. Check the result with:

    SELECT * FROM wines;

And you should see:

    1|Rooiberg|Pinotage|South Africa
    2|KWV|Shiraz|South Africa
    3|Marks & Spencer|Pinot Noir|South Africa

Now all our wines come from South Africa. Let’s drink the KWV in celebration, and delete it from our database:

    DELETE FROM wines WHERE id=2;
    SELECT * FROM wines;

And we should see one fewer wine listed in our cellar:

    1|Rooiberg|Pinotage|South Africa
    3|Marks & Spencer|Pinot Noir|South Africa

And that covers all of the basic database operations. Before we finish, let’s try one more (slightly) less trivial example, which uses two tables and a basic join.

Exit from Sqlite with the command `Ctrl + D` and reconnect to a new database with `sqlite3 database2.db`.

We’ll be creating a very similar `wines` table, but also a `countries` table, which stores the country’s name and its current president. Let’s create the countries table first and insert South Africa and France into it with (note that you can copy-paste several lines of sqlite code at once):

    CREATE TABLE countries (id integer, name varchar(30), president varchar(30));
    INSERT INTO countries VALUES (1, "South Africa", "Jacob Zuma");
    INSERT INTO countries VALUES(2, "France", "Francois Hollande");

And then we can recreate our wines table with:

    CREATE TABLE wines (id integer, kind varchar(30), country_id integer);
    INSERT INTO wines VALUES (1, "Pinotage", 1);
    INSERT INTO wines VALUES (2, "Shiraz", 1);
    INSERT INTO wines VALUES (3, "Pinot Noir", 2);

Now let’s see what kinds of wine there are in South Africa with:

    SELECT kind FROM wines JOIN countries ON country_id=countries.id WHERE countries.name="South Africa";

And you should see:

    Pinotage
    Shiraz

And that covers a basic Join. Notice that Sqlite does a lot for you. In the join statement above, it defaults to `INNER JOIN`, although we just use the keyword `JOIN`. Also we don’t have to specify `wines.country_id` as it’s unambiguous. On the other hand, if we try the command:

    SELECT kind FROM wines JOIN countries ON country_id=id WHERE country_id=1;

We’ll get the error message `Error: ambiguous column name: id`. Which is fair enough as both of our tables have an `id` column. But generally Sqlite is fairly forgiving. Its error messages tend to make it fairly trivial to locate and fix any issues, and this helps speed up the development process. For help with further syntax, the official documentation is full of diagrams like this one [sqlite.org/lang_delete.html_](http://www.sqlite.org/lang_delete.html), which can be helpful, but if you prefer concrete examples, here is a link to a tutorial with a nice overview of most of the join types: \<a href=“[http://zetcode.com/db/sqlite/joins/](http://zetcode.com/db/sqlite/joins/)” target=“blank”\>zetcode.com/db/sqlite/joins/.

Finally, Sqlite has wrappers and drivers in all the major languages, and can run on most systems. A list of many of them can be found [here](http://www.sqlite.org/cvstrac/wiki?p=SqliteWrappers). Good luck, and have fun.

Submitted by: [Gareth Dwyer](http://techblog.garethdwyer.co.za)
