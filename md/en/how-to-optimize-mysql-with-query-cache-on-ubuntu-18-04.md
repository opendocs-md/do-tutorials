---
author: FRANCIS NDUNGU
date: 2019-06-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-optimize-mysql-with-query-cache-on-ubuntu-18-04
---

# How To Optimize MySQL with Query Cache on Ubuntu 18.04

_The author selected the [Apache Software Foundation](https://www.brightfunds.org/organizations/apache-software-foundation) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Query cache](https://dev.mysql.com/doc/refman/5.7/en/query-cache.html) is a prominent [MySQL](https://www.mysql.com/) feature that speeds up data retrieval from a database. It achieves this by storing MySQL `SELECT` statements together with the retrieved record set in memory, then if a client requests identical queries it can serve the data faster without executing commands again from the database.

Compared to data read from disk, cached data from RAM (Random Access Memory) has a shorter access time, which reduces latency and improves input/output (I/O) operations. As an example, for a WordPress site or an e-commerce portal with high read calls and infrequent data changes, query cache can drastically boost the performance of the database server and make it more scalable.

In this tutorial, you will first configure MySQL without query cache and run queries to see how quickly they are executed. Then you’ll set up query cache and test your MySQL server with it enabled to show the difference in performance.

**Note:** Although query cache is deprecated as of MySQL 5.7.20, and removed in MySQL 8.0, it is still a powerful tool if you’re using supported versions of MySQL. However, if you are using newer versions of MySQL, you may adopt alternative third-party tools like [ProxySQL](https://proxysql.com) to optimize performance on your MySQL database.

## Prerequisites

Before you begin, you will need the following:

- One Ubuntu 18.04 server configured with a firewall and a non-root user. You can refer to the [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) guide to configure your server.

- A MySQL server set up as detailed in this [How To Install MySQL on Ubuntu 18.04](how-to-install-mysql-on-ubuntu-18-04) tutorial. Ensure you set a root password for the MySQL server.

## Step 1 — Checking the Availability of Query Cache

Before you set up query cache, you’ll check whether your version of MySQL supports this feature. First, `ssh` into your Ubuntu 18.04 server:

    ssh user_name@your_server_ip

Then, run the following command to log in to the MySQL server as the root user:

    sudo mysql -u root -p

Enter your MySQL server root password when prompted and then press `ENTER` to continue.

Use the following command to check if query cache is supported:

    show variables like 'have_query_cache';

You should get an output similar to the following:

    Output+------------------+-------+
    | Variable_name | Value |
    +------------------+-------+
    | have_query_cache | YES |
    +------------------+-------+
    1 row in set (0.01 sec)

You can see the value of `have_query_cache` is set to `YES` and this means query cache is supported. If you receive an output showing that your version does not support query cache, please see the note in the Introduction section for more information.

Now that you have checked and confirmed that your version of MySQL supports query cache, you will move on to examining the variables that control this feature on your database server.

## Step 2 — Checking the Default Query Cache Variables

In MySQL, a number of variables control query cache. In this step, you’ll check the default values that ship with MySQL and understand what each variable controls.

You can examine these variables using the following command:

    show variables like 'query_cache_%' ;

You will see the variables listed in your output:

    Output+------------------------------+----------+
    | Variable_name | Value |
    +------------------------------+----------+
    | query_cache_limit | 1048576 |
    | query_cache_min_res_unit | 4096 |
    | query_cache_size | 16777216 |
    | query_cache_type | OFF |
    | query_cache_wlock_invalidate | OFF |
    +------------------------------+----------+
    5 rows in set (0.00 sec)

The `query_cache_limit` value determines the maximum size of individual query results that can be cached. The default value is 1,048,576 bytes and this is equivalent to 1MB.

MySQL does not handle cached data in one big chunk; instead it is handled in blocks. The minimum amount of memory allocated to each block is determined by the `query_cache_min_res_unit` variable. The default value is 4096 bytes or 4KB.

`query_cache_size` controls the total amount of memory allocated to the query cache. If the value is set to zero, it means query cache is disabled. In most cases, the default value may be set to 16,777,216 (around 16MB). Also, keep in mind that `query_cache_size` needs at least 40KB to allocate its structures. The value allocated here is aligned to the nearest 1024 byte block. This means the reported value may be slightly different from what you set.

MySQL determines the queries to cache by examining the `query_cache_type` variable. Setting this value to `0` or `OFF` prevents caching or retrieval of cached queries. You can also set it to `1` to enable caching for all queries except for ones beginning with the [`SELECT SQL_NO_CACHE`](https://dev.mysql.com/doc/refman/5.7/en/query-cache-in-select.html) statement. A value of `2` tells MySQL to only cache queries that begin with `SELECT SQL_CACHE` command.

The variable `query_cache_wlock_invalidate` controls whether MySQL should retrieve results from the cache if the table used on the query is locked. The default value is `OFF`.

**Note:** The `query_cache_wlock_invalidate` variable is deprecated as of MySQL version 5.7.20. As a result, you may not see this in your output depending on the MySQL version you’re using.

Having reviewed the system variables that control the MySQL query cache, you’ll now test how MySQL performs without first enabling the feature.

## Step 3 — Testing Your MySQL Server Without Query Cache

The goal of this tutorial is to optimize your MySQL server by using the query cache feature. To see the difference in speed, you’re going to run queries and see their performance before and after implementing the feature.

In this step you’re going to create a sample database and insert some data to see how MySQL performs without query cache.

While still logged in to your MySQL server, create a database and name it `sample_db` by running the following command:

    Create database sample_db;

    OutputQuery OK, 1 row affected (0.00 sec)

Then switch to the database:

    Use sample_db;

    OutputDatabase changed

Create a table with two fields (`customer_id` and `customer_name`) and name it `customers`:

    Create table customers (customer_id INT PRIMARY KEY, customer_name VARCHAR(50) NOT NULL) Engine = InnoDB;

    OutputQuery OK, 0 rows affected (0.01 sec)

Then, run the following commands to insert some sample data:

    Insert into customers(customer_id, customer_name) values ('1', 'JANE DOE');
    Insert into customers(customer_id, customer_name) values ('2', 'JANIE DOE');
    Insert into customers(customer_id, customer_name) values ('3', 'JOHN ROE');
    Insert into customers(customer_id, customer_name) values ('4', 'MARY ROE');
    Insert into customers(customer_id, customer_name) values ('5', 'RICHARD ROE');
    Insert into customers(customer_id, customer_name) values ('6', 'JOHNNY DOE');
    Insert into customers(customer_id, customer_name) values ('7', 'JOHN SMITH');
    Insert into customers(customer_id, customer_name) values ('8', 'JOE BLOGGS');
    Insert into customers(customer_id, customer_name) values ('9', 'JANE POE');
    Insert into customers(customer_id, customer_name) values ('10', 'MARK MOE');

    OutputQuery OK, 1 row affected (0.01 sec)
    Query OK, 1 row affected (0.00 sec)
    ...

The next step is starting the [MySQL profiler](https://dev.mysql.com/doc/refman/5.5/en/show-profile.html), which is an analysis service for monitoring the performance of MySQL queries. To turn the profile on for the current session, run the following command, setting it to `1`, which is on:

    SET profiling = 1;

    OutputQuery OK, 0 rows affected, 1 warning (0.00 sec)

Then, run the following query to retrieve all customers:

    Select * from customers;

You’ll receive the following output:

    Output+-------------+---------------+
    | customer_id | customer_name |
    +-------------+---------------+
    | 1 | JANE DOE |
    | 2 | JANIE DOE |
    | 3 | JOHN ROE |
    | 4 | MARY ROE |
    | 5 | RICHARD ROE |
    | 6 | JOHNNY DOE |
    | 7 | JOHN SMITH |
    | 8 | JOE BLOGGS |
    | 9 | JANE POE |
    | 10 | MARK MOE |
    +-------------+---------------+
    10 rows in set (0.00 sec)

Then, run the `SHOW PROFILES` command to retrieve performance information about the `SELECT` query you just ran:

    SHOW PROFILES;

You will get output similar to the following:

    Output+----------+------------+-------------------------+
    | Query_ID | Duration | Query |
    +----------+------------+-------------------------+
    | 1 | 0.00044075 | Select * from customers |
    +----------+------------+-------------------------+
    1 row in set, 1 warning (0.00 sec)

The output shows the total time spent by MySQL when retrieving records from the database. You are going to compare this data in the next steps when query cache is enabled, so keep note of your `Duration`. You can ignore the warning within the output since this simply indicates that `SHOW PROFILES` command will be removed in a future MySQL release and replaced with [Performance Schema](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html).

Next, exit from the MySQL Command Line Interface.

    quit;

You have ran a query with MySQL before enabling query cache and noted down the `Duration` or time spent to retrieve records. Next, you will enable query cache and see if there is a performance boost when running the same query.

## Step 4 — Setting Up Query Cache

In the previous step, you created sample data and ran a `SELECT` statement before you enabled query cache. In this step, you’ll enable query cache by editing the MySQL configuration file.

Use `nano` to edit the file:

    sudo nano /etc/mysql/my.cnf

Add the following information to the end of your file:

/etc/mysql/my.cnf

    ...
    [mysqld]
    query_cache_type=1
    query_cache_size = 10M
    query_cache_limit=256K

Here you’ve enabled query cache by setting the `query_cache_type` to `1`. You’ve also set up the individual query limit size to `256K` and instructed MySQL to allocate `10` megabytes to query cache by setting the value of `query_cache_size` to `10M`.

Save and close the file by pressing `CTRL` + `X`, `Y`, then `ENTER`. Then, restart your MySQL server to implement the changes:

    sudo systemctl restart mysql

You have now enabled query cache.

Once you have configured query cache and restarted MySQL to apply the changes, you will go ahead and test the performance of MySQL with the feature enabled.

## Step 5 — Testing Your MySQL Server with Query Cache Enabled

In this step, you’ll run the same query you ran in Step 3 one more time to check how query cache has optimized the performance of your MySQL server.

First, connect to your MySQL server as the **root** user:

    sudo mysql -u root -p

Enter your **root** password for the database server and hit `ENTER` to continue.

Now confirm your configuration set in the previous step to ensure you enabled query cache:

    show variables like 'query_cache_%' ;

You’ll see the following output:

    Output+------------------------------+----------+
    | Variable_name | Value |
    +------------------------------+----------+
    | query_cache_limit | 262144 |
    | query_cache_min_res_unit | 4096 |
    | query_cache_size | 10485760 |
    | query_cache_type | ON |
    | query_cache_wlock_invalidate | OFF |
    +------------------------------+----------+
    5 rows in set (0.01 sec)

The variable `query_cache_type` is set to `ON`; this confirms that you enabled query cache with the parameters defined in the previous step.

Switch to the `sample_db` database that you created earlier.

    Use sample_db;

Start the MySQL profiler:

    SET profiling = 1;

Then, run the query to retrieve all customers at least two times in order to generate enough profiling information.

Remember, once you’ve run the first query, MySQL will create a cache of the results and therefore, you must run the query twice to trigger the cache:

    Select * from customers;
    Select * from customers;

Then, list the profiles information:

    SHOW PROFILES;

You’ll receive an output similar to the following:

    Output+----------+------------+-------------------------+
    | Query_ID | Duration | Query |
    +----------+------------+-------------------------+
    | 1 | 0.00049250 | Select * from customers |
    | 2 | 0.00026000 | Select * from customers |
    +----------+------------+-------------------------+
    2 rows in set, 1 warning (0.00 sec)

As you can see the time taken to run the query has drastically reduced from `0.00044075` (without query cache in Step 3) to `0.00026000` (the second query) in this step.

You can see the optimization from enabling the query cache feature by profiling the first query in detail:

    SHOW PROFILE FOR QUERY 1;

    Output+--------------------------------+----------+
    | Status | Duration |
    +--------------------------------+----------+
    | starting | 0.000025 |
    | Waiting for query cache lock | 0.000004 |
    | starting | 0.000003 |
    | checking query cache for query | 0.000045 |
    | checking permissions | 0.000008 |
    | Opening tables | 0.000014 |
    | init | 0.000018 |
    | System lock | 0.000008 |
    | Waiting for query cache lock | 0.000002 |
    | System lock | 0.000018 |
    | optimizing | 0.000003 |
    | statistics | 0.000013 |
    | preparing | 0.000010 |
    | executing | 0.000003 |
    | Sending data | 0.000048 |
    | end | 0.000004 |
    | query end | 0.000006 |
    | closing tables | 0.000006 |
    | freeing items | 0.000006 |
    | Waiting for query cache lock | 0.000003 |
    | freeing items | 0.000213 |
    | Waiting for query cache lock | 0.000019 |
    | freeing items | 0.000002 |
    | storing result in query cache | 0.000003 |
    | cleaning up | 0.000012 |
    +--------------------------------+----------+
    25 rows in set, 1 warning (0.00 sec)

Run the following command to show profile information for the second query, which is cached:

    SHOW PROFILE FOR QUERY 2;

    Output+--------------------------------+----------+
    | Status | Duration |
    +--------------------------------+----------+
    | starting | 0.000024 |
    | Waiting for query cache lock | 0.000003 |
    | starting | 0.000002 |
    | checking query cache for query | 0.000006 |
    | checking privileges on cached | 0.000003 |
    | checking permissions | 0.000027 |
    | sending cached result to clien | 0.000187 |
    | cleaning up | 0.000008 |
    +--------------------------------+----------+
    8 rows in set, 1 warning (0.00 sec)

The outputs from the profiler show that MySQL took less time on the second query because it was able to retrieve data from the query cache instead of reading it from the disk. You can compare the two sets of output for each of the queries. If you look at the profile information on `QUERY 2`, the status of `sending cached result to client` shows that data was read from the cache and no tables were opened since the `Opening tables` status is missing.

With the MySQL query cache feature enabled on your server, you’ll now experience improved read speeds.

## Conclusion

You have set up query cache to speed up your MySQL server on Ubuntu 18.04. Using features like MySQL’s query cache can enhance the speed of your website or web application. Caching reduces unnecessary execution for SQL statements and is a highly recommended and popular method for optimizing your database. For more on speeding up your MySQL server, try the [How To Set Up a Remote Database to Optimize Site Performance with MySQL on Ubuntu 18.04](how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql-on-ubuntu-18-04) tutorial.
