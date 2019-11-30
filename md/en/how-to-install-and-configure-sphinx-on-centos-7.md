---
author: Miyuru Sankalpa
date: 2016-09-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-sphinx-on-centos-7
---

# How To Install and Configure Sphinx on CentOS 7

## Introduction

Sphinx is an open source search engine that allows full-text searches. It is best known for performing searches over large data very efficiently. The data to be indexed can generally come from very different sources: SQL databases, plain text files, HTML files, mailboxes, and so on.

Some key features of Sphinx are:

- High indexing and searching performance
- Advanced indexing and querying tools
- Advanced result set post-processing
- Proven scalability up to billions of documents, terabytes of data, and thousands of queries per second
- Easy integration with SQL and XML data sources, and SphinxQL, SphinxAPI, or SphinxSE search interfaces
- Easy scaling with distributed searches

In this tutorial, we will set up Sphinx with MySQL server using the sample SQL file included in the distribution package. It will give you a basic idea of how to use Sphinx for your project.

## Prerequisites

Before you begin this guide, you will need:

- One CentOS 7 server.

- A sudo non-root user, which you can set up by following [this tutorial](initial-server-setup-with-centos-7).

- MySQL installed on your server, which you can set up by following the step 2 of [this tutorial](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7).

## Step 1 — Installing Sphinx

At the time of writing, the latest Sphinx version is _2.2.11_. You can find the latest version [on the Sphinx website](http://sphinxsearch.com/downloads/release/).

Before installing Sphinx, first you need to install its dependencies.

    sudo yum install -y postgresql-libs unixODBC

Move to the `tmp` directory to download Sphinx’s files in an unobtrusive place.

    cd /tmp

Download the latest Sphinx version using `wget`.

    wget http://sphinxsearch.com/files/sphinx-2.2.11-1.rhel7.x86_64.rpm

Finally, install it using `yum`.

    sudo yum install -y sphinx-2.2.11-1.rhel7.x86_64.rpm

Now you have successfully installed Sphinx on your server. Before starting the Sphinx daemon, let’s configure it.

## Step 2 – Creating the Test Database

Here, we’ll set up a database using the sample data in the SQL file provided with the package. This will allow us to test that Sphinx search is working later.

Let’s import the sample SQL file into the database. First, log in to the MySQL server shell.

    mysql -u root -p

Enter the password for the MySQL root user when asked. Your prompt will change to `MariaDB>`.

Create a dummy database. Here, we’re calling it **test** , but you can name it whatever you want.

    CREATE DATABASE test;

Import the example SQL file.

    SOURCE /usr/share/doc/sphinx-2.2.11/example.sql;

Then leave the MySQL shell.

    quit

Now you have a database filled with the sample data. Next, we’ll customize Sphinx’s configuration.

## Step 3 – Configuring Sphinx

Sphinx’s configuration should be in a file called `sphinx.conf` in `/etc/sphinx`. The configuration consists of 3 main blocks: **index** , **searchd** , and **source**.

There is a minimal configuration already provided, but we’ll provide a new example configuration file for you to use and explain each section so you can customize it later.

First, move the existing `sphinx.conf` file.

    sudo mv /etc/sphinx/sphinx.conf /etc/sphinx/sphinx.conf2

Create a new `sphinx.conf` file with `vi` or your favorite text editor.

    sudo vi /etc/sphinx/sphinx.conf

Each of the **index** , **searchd** , and **source** blocks are described below. Then, at the end of this step, the entirety of `sphinx.conf` is included for you to copy and paste into the file.

The **source** block contains the type of source, username and password to the MySQL server. The first column of the `sql_query` should be a unique id. The SQL query will run on every index and dump the data to Sphinx index file. Below are the descriptions of each field and the source block itself.

- `type`: Type of data source to index. In our example, this is **mysql**. Other supported types include pgsql, mssql, xmlpipe2, odbc, and more.
- `sql_host`: Hostname for the MySQL host. In our example, this is `localhost`. This can be a domain or IP address.
- `sql_user`: Username for the MySQL login. In our example, this is **root**.
- `sql_pass`: Password for the MySQL user. In our example, this is the root MySQL user’s password.
- `sql_db`: Name of the database that stores data. In our example, this is **test**.
- `sql_query`: The query thats dumps data from the database to the index.

This is the source block:

source block for sphinx.conf

    source src1
    {
      type = mysql
    
      #SQL settings (for ‘mysql’ and ‘pgsql’ types)
    
      sql_host = localhost
      sql_user = root
      sql_pass = password
      sql_db = test
      sql_port = 3306 # optional, default is 3306
    
      sql_query = \
      SELECT id, group_id, UNIX_TIMESTAMP(date_added) AS date_added, title, content \
      FROM documents
    
      sql_attr_uint = group_id
      sql_attr_timestamp = date_added
    }

The **index** component contains the source and the path to store the data.  
in

- `source`: Name of the source block. In our example, this is **src1**.
- `path`: The path to save the index.

index block for sphinx.conf

    index test1
    {
      source = src1
      path = /var/lib/sphinx/test1
      docinfo = extern
    }

The **searchd** component contains the port and other variables to run the Sphinx daemon.

- `listen`: The port which the Sphinx daemon will run, followed by the protocol. In our example, this is **9306:mysql41**. Known protocols are _:sphinx_ (SphinxAPI) and _:mysql41_ (SphinxQL)
- `query_log`: The path to save the query log.
- `pid_file`: The path to PID file of Sphinx daemon.
- `seamless_rotate`: Prevents searchd stalls while rotating indexes with huge amounts of data to precache.
- `preopen_indexes`: Whether to forcibly preopen all indexes on startup.
- `unlink_old`: Whether to delete old index copies on successful rotation.

searchd block for sphinx.conf

    searchd
    {
      listen = 9312:sphinx #SphinxAPI port
      listen = 9306:mysql41 #SphinxQL port
      log = /var/log/sphinx/searchd.log
      query_log = /var/log/sphinx/query.log
      read_timeout = 5
      max_children = 30
      pid_file = /var/run/sphinx/searchd.pid
      seamless_rotate = 1
      preopen_indexes = 1
      unlink_old = 1
      binlog_path = /var/lib/sphinx/
    }

The full configuration to copy and paste is below. The only variable you need to change below is the `sql_pass` variable in the source block, which is highlighted.

The full sphinx.conf file

    source src1
    {
      type = mysql
    
      sql_host = localhost
      sql_user = root
      sql_pass = your_root_mysql_password
      sql_db = test
      sql_port = 3306
    
      sql_query = \
      SELECT id, group_id, UNIX_TIMESTAMP(date_added) AS date_added, title, content \
      FROM documents
    
      sql_attr_uint = group_id
      sql_attr_timestamp = date_added
    }
    index test1
    {
      source = src1
      path = /var/lib/sphinx/test1
      docinfo = extern
    }
    searchd
    {
      listen = 9306:mysql41
      log = /var/log/sphinx/searchd.log
      query_log = /var/log/sphinx/query.log
      read_timeout = 5
      max_children = 30
      pid_file = /var/run/sphinx/searchd.pid
      seamless_rotate = 1
      preopen_indexes = 1
      unlink_old = 1
      binlog_path = /var/lib/sphinx/
    }

To explore more configurations, you can take a look at the `/usr/share/doc/sphinx-2.2.11/sphinx.conf.dist` file, which has all the variables explained in detail.

## Step 4 — Managing the Index

In this step, we’ll add data to the Sphinx index and make sure the index stays up to date using `cron`.

First, add data to the index using the configuration we created earlier.

    sudo indexer --all

You should get something that looks like the following.

    OutputSphinx 2.2.11-id64-release (95ae9a6)
    Copyright (c) 2001-2016, Andrew Aksyonoff
    Copyright (c) 2008-2016, Sphinx Technologies Inc (http://sphinxsearch.com)
    
    using config file '/etc/sphinx/sphinx.conf'...
    indexing index 'test1'...
    collected 4 docs, 0.0 MB
    sorted 0.0 Mhits, 100.0% done
    total 4 docs, 193 bytes
    total 0.006 sec, 29765 bytes/sec, 616.90 docs/sec
    total 4 reads, 0.000 sec, 0.1 kb/call avg, 0.0 msec/call avg
    total 12 writes, 0.000 sec, 0.1 kb/call avg, 0.0 msec/call avg

In production environments, it is necessary to keep the index up to date. To do that let’s create a Cron job. First, open `crontab`.

    crontab -e

The following Cron job will run on every hour and add new data to the index using the configuration file we created earlier. Copy and paste it at the end of the file, then save and close the file.

crontab

    @hourly /usr/bin/indexer --rotate --config /etc/sphinx/sphinx.conf --all

Now that Sphinx is fully set up and configured, we can start the service and try it out.

## Step 5 — Starting Sphinx

Use `systemctl` to start the Sphinx daemon.

    sudo systemctl start searchd

To check if the Sphinx daemon is running correctly, run:

    sudo systemctl status searchd

You should get something that looks like the following.

    Output● searchd.service - SphinxSearch Search Engine
       Loaded: loaded (/usr/lib/systemd/system/searchd.service; disabled; vendor preset: disabled)
       Active: active (running) since Fri 2016-08-19 17:48:39 UTC; 5s ago
       . . .

Sphinx is fully customized and running, so we’ll check that it’s working correctly next.

## Step 6 — Testing Search Functionality

Now that everything is set up, let’s test the search functionality. Connect to the SphinxQL using the MySQL interface. Your prompt will change to `MySQL>`.

    mysql -h0 -P9306

Let’s search a sentence.

    SELECT * FROM test1 WHERE MATCH('test document'); SHOW META;

You should get something that looks like the following.

    Output+------+----------+------------+
    | id | group_id | date_added |
    +------+----------+------------+
    | 1 | 1 | 1465979047 |
    | 2 | 1 | 1465979047 |
    +------+----------+------------+
    2 rows in set (0.00 sec)
    
    +---------------+----------+
    | Variable_name | Value |
    +---------------+----------+
    | total | 2 |
    | total_found | 2 |
    | time | 0.000 |
    | keyword[0] | test |
    | docs[0] | 3 |
    | hits[0] | 5 |
    | keyword[1] | document |
    | docs[1] | 2 |
    | hits[1] | 2 |
    +---------------+----------+
    9 rows in set (0.00 sec)

In the result above you can see that Sphinx found 2 matches from our `test1` index for our test sentence. The `SHOW META;` command shows hits per keyword in the sentence as well.

Let’s search some keywords.

    CALL KEYWORDS ('test one three', 'test1', 1);

You should get something that looks like the following.

    Output+------+-----------+------------+------+------+
    | qpos | tokenized | normalized | docs | hits |
    +------+-----------+------------+------+------+
    | 1 | test | test | 3 | 5 |
    | 2 | one | one | 1 | 2 |
    | 3 | three | three | 0 | 0 |
    +------+-----------+------------+------+------+
    3 rows in set (0.00 sec)

In the result above you can see that in the **test1** index, Sphinx found:

- 5 matches in 3 documents for the keyword ‘test’
- 2 matches in 1 document for the keyword 'one’
- 0 matches in 0 documents for the keyword 'three’

Now that you’ve tested Sphinx, you can delete the test database with `DROP DATABASE test;` if you like.

When you’re done, leave the MySQL shell.

    quit

## Conclusion

In this tutorial, we have shown you how to install Sphinx and make a simple search using SphinxQL and MySQL.

You can also find official [native SphinxAPI implementations for PHP, Perl, Python, Ruby and Java](https://github.com/sphinx/sphinx/tree/master/api). If you are using Nodejs, you can also use [the SphinxAPI package](https://www.npmjs.com/package/sphinxapi).

By using Sphinx, you can easily add a custom search to your site. For more information on using Sphinx, visit [the project website](http://sphinx.com).
