---
author: Justin Ellingwood
date: 2013-11-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-optimize-queries-and-tables-in-mysql-and-mariadb-on-a-vps
---

# How To Optimize Queries and Tables in MySQL and MariaDB on a VPS

## Introduction

* * *

MySQL and MariaDB are popular choices for database management systems. Both use the SQL querying language to input and query data.

Although SQL queries are simple commands that are easy to learn, not all queries and database functions operate with the same efficiency. This becomes increasingly important as the amount of information you are storing grows and, if your database is backing a website, as your site’s popularity increases.

In this guide, we will discuss some simple measures you can take to speed up your MySQL and MariaDB queries. We will assume that you have already installed MySQL or MariaDB using one of our guides that is appropriate for your operating system.

## Table Design Generalities

* * *

One of the most fundamental ways to improve querying speed begins with the table structure design itself. This means that you need to begin considering the best way to organize your data _before_ you begin using the software.

These are some questions that you should be asking yourself:

### How Will your Table Primarily be Used?

* * *

Anticipating how you will use the table’s data often dictates the best approach to designing a data structure.

If you will be updating certain pieces of data often, it is often best to have those in their own table. Failure to do this can cause the query cache, an internal cache maintained within the software, to be dumped and rebuilt over and over again because it recognizes that there is new information. If this happens in a separate table, the other columns can continue to take advantage of the cache.

Updating operations are, in general, faster on smaller tables, while in-depth analysis of complex data is usually a task best relegated to large tables, as joins can be costly operations.

### What Kind of Data Types are Required?

* * *

Sometimes, it can save you significant time in the long run if you can provide some restraints for your data sizes upfront.

For instance, if there are a limited number of valid entries for a specific field that takes string values, you could use the “enum” type instead of “varchar”. This data type is compact and thus quick to query.

For instance, if you have only a few different kinds of users, you could make the column that handles that “enum” with the possible values: admin, moderator, poweruser, user.

### Which Columns Will You be Querying?

* * *

Knowing ahead of time which fields you will be querying repeatedly can dramatically improve your speed.

Indexing columns that you expect to use for searching helps immensely. You can add an index when creating a table using the following syntax:

    CREATE TABLE example\_table ( id INTEGER NOT NULL AUTO\_INCREMENT, name VARCHAR(50), address VARCHAR(150), username VARCHAR(16), PRIMARY KEY (id), INDEX (username));

This would be useful if we knew that our users were going to be searching for information by username. This will create a table with these properties:

    explain example\_table;

    +----------+--------------+------+-----+---------+----------------+ | Field | Type | Null | Key | Default | Extra | +----------+--------------+------+-----+---------+----------------+ | id | int(11) | NO | PRI | NULL | auto\_increment | | name | varchar(50) | YES | | NULL | | | address | varchar(150) | YES | | NULL | | | username | varchar(16) | YES | MUL | NULL | | +----------+--------------+------+-----+---------+----------------+ 4 rows in set (0.00 sec)

As you can see, we have two indices for our table. The first is the primary key, which in this case is the `id` field. The second is the index we’ve added for the `username` field. This will improve queries that utilize this field.

Although it is useful from a conceptual standpoint to think about which fields should be indexed during creation, it is simple to add indices to pre-existing tables as well. You can add one like this:

    CREATE INDEX index\_name ON table\_name(column\_name);

Another way of accomplishing the same thing is this:

    ALTER TABLE table\_name ADD INDEX ( column\_name );

**Use Explain to Find Points to Index in Queries**

If your program is querying in a very predictable way, you should be analysing your queries to ensure that they are using indices whenever possible. This is easy with the `explain` function.

We will import a MySQL sample database to see how some of this works:

    wget https://launchpad.net/test-db/employees-db-1/1.0.6/+download/employees_db-full-1.0.6.tar.bz2
    tar xjvf employees_db-full-1.0.6.tar.bz2
    cd employees_db
    mysql -u root -p -t < employees.sql

We can now log back into MySQL so that we can run some queries:

    mysql -u root -p
    use employees;

First, we need to specify that MySQL should not be using its cache, so that we can accurately judge the time these tasks take to complete:

    SET GLOBAL query_cache_size = 0;
    SHOW VARIABLES LIKE "query_cache_size";
    
    +------------------+-------+
    | Variable_name | Value |
    +------------------+-------+
    | query_cache_size | 0 |
    +------------------+-------+
    1 row in set (0.00 sec)

Now, we can run a simple query on a large dataset:

    SELECT COUNT(*) FROM salaries WHERE salary BETWEEN 60000 AND 70000;

* * *

    +----------+
    | count(*) |
    +----------+
    | 588322 |
    +----------+
    1 row in set (0.60 sec)

To see how MySQL executes the query, you can add the `explain` keyword directly before the query:

    EXPLAIN SELECT COUNT(*) FROM salaries WHERE salary BETWEEN 60000 AND 70000;

* * *

    +----+-------------+----------+------+---------------+------+---------+------+---------+-------------+
    | id | select_type | table | type | possible_keys | key | key_len | ref | rows | Extra |
    +----+-------------+----------+------+---------------+------+---------+------+---------+-------------+
    | 1 | SIMPLE | salaries | ALL | NULL | NULL | NULL | NULL | 2844738 | Using where |
    +----+-------------+----------+------+---------------+------+---------+------+---------+-------------+
    1 row in set (0.00 sec)

If you look at the `key` field, you will see that it’s value is `NULL`. This means that no index is being used for this query.

Let’s add one and run the query again to see if it speeds it up:

    ALTER TABLE salaries ADD INDEX ( salary );
    SELECT COUNT(*) FROM salaries WHERE salary BETWEEN 60000 AND 70000;

* * *

    +----------+
    | count(*) |
    +----------+
    | 588322 |
    +----------+
    1 row in set (0.14 sec)

As you can see, this significantly improves our querying performance.

Another general rule to use with indices is to pay attention to table joins. You should create indices and specify the same data type on any columns that will be used to join tables.

For instance, if you have a table called “cheeses” and a table called “ingredients”, you may want to join on a similar ingredient\_id field in each table, which could be an INT.

We could then create indices for both of these fields and our joins would speed up.

## Optimizing Queries for Speed

* * *

The other half of the equation when trying to speed up queries is optimizing the queries themselves. Certain operations are more computationally intensive than others. There are often multiple ways of getting the same result, some of which will avoid costly operations.

Depending on what you are using the query results for, you may only need a limited number of the results. For instance, if you only need to find out if there is anyone at the company making less than $40,000, you can use:

    SELECT * FROM SALARIES WHERE salary < 40000 LIMIT 1;

* * *

    +--------+--------+------------+------------+
    | emp_no | salary | from_date | to_date |
    +--------+--------+------------+------------+
    | 10022 | 39935 | 2000-09-02 | 2001-09-02 |
    +--------+--------+------------+------------+
    1 row in set (0.00 sec)

This query executes extremely fast because it basically short circuits at the first positive result.

If your queries use “or” comparisons, and the two components parts are testing different fields, your query can be longer than necessary.

For example, if you are searching for an employee whose first or last name starts with “Bre”, you will have to search two separate columns.

    SELECT * FROM employees WHERE last_name like 'Bre%' OR first_name like 'Bre%';

This operation may be faster if we perform the search for first names in one query, perform the search for matching last names in another, and then combine the output. We can do this with the union operator:

    SELECT * FROM employees WHERE last_name like 'Bre%' UNION SELECT * FROM employees WHERE first_name like 'Bre%';

In some instances, MySQL will use a union operation automatically. The example above is actually a case where MySQL will do this automatically. You can see if this is the case by checking for the kind of sorting being done by using `explain` again.

## Conclusion

* * *

There are an extraordinary amount of ways that you can fine-tune your MySQL and MariaDB tables and databases according on your use case. This article contains just a few tips that might be useful to get you started.

These database management systems have great documentation on how to optimize and fine-tune different scenarios. The specifics depend greatly on what kind of functionality you wish to optimize, otherwise they would have been completely optimized out-of-the-box. Once you’ve solidified your requirements and have a handle on what operations are going to be performed repeatedly, you can learn to tweak your settings for those queries.

By Justin Ellingwood
