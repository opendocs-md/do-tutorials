---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-troubleshoot-mysql-queries
---

# How To Troubleshoot MySQL Queries

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

Sometimes users run into problems once they begin issuing queries on their data. In some database systems, including MySQL, query statements in must end in a semicolon (`;`) for the query to complete, as in the following example:

    SHOW * FROM table_name;

If you fail to include a semicolon at the end of your query, the prompt will continue on a new line until you complete the query by entering a semicolon and pressing `ENTER`.

Some users may find that their queries are exceedingly slow. One way to find which query statement is the cause of a slowdown is to enable and view MySQL’s slow query log. To do this, open your `mysqld.cnf` file, which is used to configure options for the MySQL server. This file is typically stored within the `/etc/mysql/mysql.conf.d/` directory:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Scroll through the file until you see the following lines:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    #slow_query_log = 1
    #slow_query_log_file = /var/log/mysql/mysql-slow.log
    #long_query_time = 2
    #log-queries-not-using-indexes
    . . .

These commented-out directives provide MySQL’s default configuration options for the slow query log. Specifically, here’s what each of them do:

- `slow-query-log`: Setting this to `1` enables the slow query log.
- `slow-query-log-file`: This defines the file where MySQL will log any slow queries. In this case, it points to the `/var/log/mysql-slow.log` file.
- `long_query_time`: By setting this directive to `2`, it configures MySQL to log any queries that take longer than 2 seconds to complete.
- `log_queries_not_using_indexes`: This tells MySQL to also log any queries that run without indexes to the `/var/log/mysql-slow.log` file. This setting isn’t required for the slow query log to function, but it can be helpful for spotting inefficient queries. 

Uncomment each of these lines by removing the leading pound signs (`#`). The section will now look like this:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    slow_query_log = 1
    slow_query_log_file = /var/log/mysql-slow.log
    long_query_time = 2
    log_queries_not_using_indexes
    . . .

**Note:** If you’re running MySQL 8+, these commented lines will not be in the `mysqld.cnf` file by default. In this case, add the following lines to the bottom of the file:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    slow_query_log = 1
    slow_query_log_file = /var/log/mysql-slow.log
    long_query_time = 2
    log_queries_not_using_indexes

After enabling the slow query log, save and close the file. Then restart the MySQL service:

    sudo systemctl restart mysql

With these settings in place, you can find problematic query statements by viewing the slow query log. You can do so with `less`, like this:

    sudo less /var/log/mysql_slow.log

Once you’ve singled out the queries causing the slowdown, you may find our guide on [How To Optimize Queries and Tables in MySQL and MariaDB on a VPS](how-to-optimize-queries-and-tables-in-mysql-and-mariadb-on-a-vps) to be helpful with optimizing them.

Additionally, MySQL includes the `EXPLAIN` statement, which provides information about how MySQL executes queries. [This page from the official MySQL documentation](https://dev.mysql.com/doc/refman/5.7/en/using-explain.html) provides insight on how to use `EXPLAIN` to highlight inefficient queries.

For help with understanding basic query structures, see our [Introduction to MySQL Queries](introduction-to-queries-mysql).
