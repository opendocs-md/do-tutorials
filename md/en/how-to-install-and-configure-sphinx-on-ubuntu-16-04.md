---
author: Miyuru Sankalpa
date: 2016-07-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-sphinx-on-ubuntu-16-04
---

# How To Install and Configure Sphinx on Ubuntu 16.04

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

- One Ubuntu 16.04 server.

- A sudo non-root user, which you can set up by following [this tutorial](how-to-add-and-delete-users-on-ubuntu-16-04).

- MySQL installed on your server, which you can set up by following the step 2 of [this tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04#step-2-install-mysql).

## Step 1 — Installing Sphinx

Installing Sphinx on Ubuntu is easy because it’s in the native package repository. Install it using `apt-get`.

    sudo apt-get install sphinxsearch

Now you have successfully installed Sphinx on your server. Before starting the Sphinx daemon, let’s configure it.

## Step 2 – Creating the Test Database

Next, we’ll set up a database using the sample data in the SQL file provided with the package. This will allow us to test that Sphinx search is working later.

Let’s import the sample SQL file into the database. First, log in to the MySQL server shell.

    mysql -u root -p

Enter the password for the MySQL root user when asked. Your prompt will change to `mysql>`.

Create a dummy database. Here, we’re calling it **test** , but you can name it whatever you want.

    CREATE DATABASE test;

Import the example SQL file.

    SOURCE /etc/sphinxsearch/example.sql;

Then leave the MySQL shell.

    quit

Now you have a database filled with the sample data. Next, we’ll customize Sphinx’s configuration.

## Step 3 – Configuring Sphinx

Sphinx’s configuration should be in a file called `sphinx.conf` in `/etc/sphinxsearch`. The configuration consists of 3 main blocks that are essential to run: **index** , **searchd** , and **source**. We’ll provide an example configuration file for you to use, and explain each section so you can customize it later.

First, create the `sphinx.conf` file.

    sudo nano /etc/sphinxsearch/sphinx.conf

Each of these **index** , **searchd** , and **source** blocks are described below. Then, at the end of this step, the entirety of `sphinx.conf` is included for you to copy and paste into the file.

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
      path = /var/lib/sphinxsearch/data/test1
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
      log = /var/log/sphinxsearch/searchd.log
      query_log = /var/log/sphinxsearch/query.log
      read_timeout = 5
      max_children = 30
      pid_file = /var/run/sphinxsearch/searchd.pid
      seamless_rotate = 1
      preopen_indexes = 1
      unlink_old = 1
      binlog_path = /var/lib/sphinxsearch/data
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
      path = /var/lib/sphinxsearch/data/test1
      docinfo = extern
    }
    searchd
    {
      listen = 9306:mysql41
      log = /var/log/sphinxsearch/searchd.log
      query_log = /var/log/sphinxsearch/query.log
      read_timeout = 5
      max_children = 30
      pid_file = /var/run/sphinxsearch/searchd.pid
      seamless_rotate = 1
      preopen_indexes = 1
      unlink_old = 1
      binlog_path = /var/lib/sphinxsearch/data
    }

To explore more configurations, you can take a look at the `/etc/sphinxsearch/sphinx.conf.sample` file, which has all the variables explained in even more detail.

## Step 4 — Managing the Index

In this step, we’ll add data to the Sphinx index and make sure the index stays up to date using `cron`.

First, add data to the index using the configuration we created earlier.

    sudo indexer --all

You should get something that looks like the following.

    OutputSphinx 2.2.9-id64-release (rel22-r5006)
    Copyright (c) 2001-2015, Andrew Aksyonoff
    Copyright (c) 2008-2015, Sphinx Technologies Inc (http://sphinxsearch.com)
    
    using config file '/etc/sphinxsearch/sphinx.conf'...
    indexing index 'test1'...
    collected 4 docs, 0.0 MB
    sorted 0.0 Mhits, 100.0% done
    total 4 docs, 193 bytes
    total 0.010 sec, 18552 bytes/sec, 384.50 docs/sec
    total 4 reads, 0.000 sec, 0.1 kb/call avg, 0.0 msec/call avg
    total 12 writes, 0.000 sec, 0.1 kb/call avg, 0.0 msec/call avg

In production environments, it is necessary to keep the index up to date. To do that let’s create a cronjob. First, open crontab.

    crontab -e

You may be asked which text editor you want to use. Choose whichever you prefer; in this tutorial, we’ve used `nano`.

The follow cronjob will run on every hour and add new data to the index using the configuration file we created earlier. Copy and paste it at the end of the file, then save and close the file.

crontab

    @hourly /usr/bin/indexer --rotate --config /etc/sphinxsearch/sphinx.conf --all

Now that Sphinx is fully set up and configured, we can start the service and try it out.

## Step 5 — Starting Sphinx

By default, the Sphinx daemon is tuned off. First, we’ll enable it by changing the line `START=no` to `START=yes` in `/etc/default/sphinxsearch`.

    sudo sed -i 's/START=no/START=yes/g' /etc/default/sphinxsearch

Then, use `systemctl` to restart the Sphinx daemon.

    sudo systemctl restart sphinxsearch.service

To check if the Sphinx daemon is running correctly, run.

    sudo systemctl status sphinxsearch.service

You should get something that looks like the following.

    Output● sphinxsearch.service - LSB: Fast standalone full-text SQL search engine
       Loaded: loaded (/etc/init.d/sphinxsearch; bad; vendor preset: enabled)
       Active: active (running) since Tue 2016-07-26 01:50:00 EDT; 15s ago
       . . .

This will also make sure the Sphinx daemon starts even when the server is rebooted.

## Step 6 — Testing

Now that everything is set up, let’s test the search functionality. Connect to the SphinxQL (on port 9306) using the MySQL interface. Your prompt will change to `mysql>`.

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

Now you can leave the MySQL shell.

    quit

## Conclusion

In this tutorial, we have shown you how to install Sphinx and make a simple search using SphinxQL and MySQL.

You can also find official [native SphinxAPI implementations for PHP, Perl, Python, Ruby and Java](https://github.com/sphinxsearch/sphinx/tree/master/api). If you are using Nodejs, you can also use [the SphinxAPI package](https://www.npmjs.com/package/sphinxapi).

By using Sphinx, you can easily add a custom search to your site. For more information on using Sphinx, visit [the project website](http://sphinxsearch.com).
