---
author: Morgan Tocker
date: 2015-04-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-prepare-for-your-mysql-5-7-upgrade
---

# How To Prepare For Your MySQL 5.7 Upgrade

### An Article from the [MySQL Team at Oracle](http://www.oracle.com/us/products/mysql/mysqlcommunityserver/overview/index.html)

## Introduction

MySQL 5.7 is the most current release candidate of the popular open-source database. It offers new scalability features that should have you eager to make the change.

To highlight one of the changes, scalability has been greatly improved. On the high end, MySQL 5.7 scales linearly on 48-core servers. On the low end, MySQL 5.7 also works out of the box on a 512 MB DigitalOcean Droplet (something that was not possible without configuration changes in MySQL 5.6).

The new peak performance for a MySQL server is over 640K queries per second, and the memcached API, which speaks directly to the InnoDB storage engine, is capable of sustaining [over 1.1 million requests per second](https://blogs.oracle.com/mysqlinnodb/entry/mysql_5_7_3_deep).

[![MySQL 5.7 Performance using the Memcached NoSQL API](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mysql_57_upgrade/1mm-memcached-api.png)](https://blogs.oracle.com/mysqlinnodb/entry/mysql_5_7_3_deep)

Before you rush to run `mysql_upgrade`, though, you should make sure you’re prepared. This tutorial can help you do just that.

## Data Integrity Changes, with Examples

One major change in MySQL 5.7 is that data integrity has been improved to be more in line with what veteran developers and DBAs expect. Previously, MySQL would adjust incorrect values to the closest possible correct value, but under the new defaults it will instead return an error.

Here are five examples of queries that will require modification to work in MySQL 5.7 out of the box. Does your application use any of these behaviors?

### 1) Inserting a negative value into an unsigned column

Create a table with an unsigned column:

    CREATE TABLE test (  
     id int unsigned  
    );

Insert a negative value.

Previous behavior:

    INSERT INTO test VALUES (-1);
    Query OK, 1 row affected, 1 warning (0.01 sec)

MySQL 5.7:

    INSERT INTO test VALUES (-1);  
    ERROR 1264 (22003): Out of range value for column 'a' at row 1

### 2) Division by zero

Create a test table:

    CREATE TABLE test2 (  
     id int unsigned  
    );

Attempt to divide by zero.

Previous behavior:

    INSERT INTO test2 VALUES (0/0);  
    Query OK, 1 row affected (0.01 sec)

MySQL 5.7:

    INSERT INTO test2 VALUES (0/0);  
    ERROR 1365 (22012): Division by 0

### 3) Inserting a 20 character string into a 10 character column

Create a table with a 10-character column:

    CREATE TABLE test3 (  
    a varchar(10)  
    );

Try to insert a longer string.

Previous behavior:

    INSERT INTO test3 VALUES ('abcdefghijklmnopqrstuvwxyz'); 
    Query OK, 1 row affected, 1 warning (0.00 sec)

MySQL 5.7:

    INSERT INTO test3 VALUES ('abcdefghijklmnopqrstuvwxyz');  
    ERROR 1406 (22001): Data too long for column 'a' at row 1

### 4) Inserting the non standard zero date into a datetime column

Create a table with a datetime column:

    CREATE TABLE test3 (  
    a datetime  
    );

Insert `0000-00-00 00:00:00`.

Previous behavior:

    INSERT INTO test3 VALUES ('0000-00-00 00:00:00');  
    Query OK, 1 row affected, 1 warning (0.00 sec)

MySQL 5.7:

    INSERT INTO test3 VALUES ('0000-00-00 00:00:00');  
    ERROR 1292 (22007): Incorrect datetime value: '0000-00-00 00:00:00' for column 'a' at row 1

### 5) Using GROUP BY and selecting an ambiguous column

This happens when the description is not part of the `GROUP BY`, and there is no aggregate function (such as `MIN` or `MAX`) applied to it.

Previous Behaviour:

    SELECT id, invoice_id, description FROM invoice_line_items GROUP BY invoice_id;  
    +----+------------+-------------+  
    | id | invoice_id | description |  
    +----+------------+-------------+  
    | 1 | 1 | New socks |  
    | 3 | 2 | Shoes |  
    | 5 | 3 | Tie |  
    +----+------------+-------------+  
    3 rows in set (0.00 sec)

MySQL 5.7:

    SELECT id, invoice_id, description FROM invoice_line_items GROUP BY invoice_id;  
    ERROR 1055 (42000): Expression #3 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'invoice_line_items.description' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by

## Understanding Behaviors Set by sql\_mode

In MySQL terms, each of the behaviors shown in the previous section is influenced by what is known as an `sql_mode`.

The feature debuted in MySQL 4.1 (2004), but has not been compiled in by default. MySQL 5.7 features the following modes turned on by default:

- [`ONLY_FULL_GROUP_BY`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_only_full_group_by)
- [`STRICT_TRANS_TABLES`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_strict_trans_tables)
- [`NO_ENGINE_SUBSTITUTION`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_engine_substitution)
- [`NO_AUTO_CREATE_USER`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_auto_create_user)

The mode [`STRICT_TRANS_TABLES`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_strict_trans_tables) has also become more strict, and enables the behaviour previously specified under the modes [`ERROR_FOR_DIVISION_BY_ZERO`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_error_for_division_by_zero), [`NO_ZERO_DATE`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_date) and [`NO_ZERO_IN_DATE`](http://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sqlmode_no_zero_in_date).

Click on any of these mode names to visit the MySQL manual, to find out more information.

## Suggestions on How to Transition

If you are using a recent version of Wordpress, Drupal, or Magento the good news is that you do not need to do anything. These applications are already aware of MySQL’s `sql_mode` feature and upon connecting to MySQL will set the options that they are compatible with.

If you are currently **building a new application** , then it may be a good idea to change the configuration of your existing MySQL 5.6 server to behave with the `sql_mode` settings that are shipped in MySQL 5.7.

If you have an **existing application** , you may want to work through your updates more gradually. These suggestions may help you to transition:

- **[Whitelist](http://en.wikipedia.org/wiki/Whitelist)**: Have new parts of your application enable the new default \<tt\>sql_mode\</tt\> options. For example, if you are building a set of cron jobs to rebuild caches of data, these can set the \<tt\>sql_mode\</tt\> as soon as they connect to MySQL. Existing application code can initially stay with the existing non-strict behaviour.
- **[Blacklist](http://en.wikipedia.org/wiki/blacklist)**: When you have made some headway in converting applications, it is time to make the new \<tt\>sql_mode\</tt\> the default for your server. It is possible to still have legacy applications the previous behaviour by having them change the `sql_mode`when they connect to MySQL. On an individual statement basis, MySQL also supports the`IGNORE`modifier to downgrade errors. For example:`INSERT IGNORE INTO my\_table …`
- **Staged Rollout** : If you are in control of your application, you may be able to implement a feature to change the `sql_mode` on a per user-basis. A good use case for this would be to allow internal users to beta test everything to allow for a more gradual transition.

### Step 1 — Finding Incompatible Statements that Produce Warnings or Errors

First, see if any of your current queries are producing warnings or errors. This is useful because the behavior for several queries has changed from a warning in 5.6 to an error in 5.7, so you can catch the warnings now before upgrading.

The MySQL [`performance_schema`](http://dev.mysql.com/doc/refman/5.6/en/performance-schema.html) is a diagnostic feature which is enabled by default on MySQL 5.6 and above. Using the `performance_schema`, it’s possible to write a query to return all the statements the server has encountered that have produced errors or warnings.

**MySQL 5.6+ query to report statements that produce errors or warnings:**

    SELECT 
    `DIGEST_TEXT` AS `query`,
    `SCHEMA_NAME` AS `db`,
    `COUNT_STAR` AS `exec_count`,
    `SUM_ERRORS` AS `errors`,
    (ifnull((`SUM_ERRORS` / nullif(`COUNT_STAR`,0)),0) * 100) AS `error_pct`,
    `SUM_WARNINGS` AS `warnings`,
    (ifnull((`SUM_WARNINGS` / nullif(`COUNT_STAR`,0)),0) * 100) AS `warning_pct`,
    `FIRST_SEEN` AS `first_seen`,
    `LAST_SEEN` AS `last_seen`,
    `DIGEST` AS `digest`
    FROM
     performance_schema.events_statements_summary_by_digest
    WHERE
    ((`SUM_ERRORS` &gt; 0) OR (`SUM_WARNINGS` &gt; 0))
    ORDER BY
     `SUM_ERRORS` DESC,
     `SUM_WARNINGS` DESC;

**MySQL 5.6+ query to report statements that produce errors:**

    SELECT 
    `DIGEST_TEXT` AS `query`,
    `SCHEMA_NAME` AS `db`,
    `COUNT_STAR` AS `exec_count`,
    `SUM_ERRORS` AS `errors`,
    (ifnull((`SUM_ERRORS` / nullif(`COUNT_STAR`,0)),0) * 100) AS `error_pct`,
    `SUM_WARNINGS` AS `warnings`,
    (ifnull((`SUM_WARNINGS` / nullif(`COUNT_STAR`,0)),0) * 100) AS `warning_pct`,
    `FIRST_SEEN` AS `first_seen`,
    `LAST_SEEN` AS `last_seen`,
    `DIGEST` AS `digest`
    FROM
     performance_schema.events_statements_summary_by_digest
    WHERE
     `SUM_ERRORS` &gt; 0
    ORDER BY
     `SUM_ERRORS` DESC,
     `SUM_WARNINGS` DESC;

### Step 2 — Making MySQL 5.6 Behave Like MySQL 5.7

You can also do a test run with MySQL 5.6 to make it behave like 5.7.

The author, Morgan Tocker from the MySQL team, has a [GitHub project](https://github.com/morgo/mysql-compatibility-config) available with a [sample configuration file](https://github.com/morgo/mysql-compatibility-config/blob/master/mysql-56/mysql-57.cnf) that will allow you to do this. By using the upcoming defaults in MySQL 5.6 you will be able to eliminate the chance that your application will depend on the less-strict behaviour.

The file is rather short, so we’re also including it here:

    # This makes a MySQL 5.6 server behave similar to the new defaults
    # in MySQL 5.7
    
    [mysqld]
    
    # MySQL 5.7 enables more SQL modes by default, but also
    # merges ERROR_FOR_DIVISION_BY_ZERO, NO_ZERO_DATE, NO_ZERO_IN_DATE
    # into the definition of STRICT_TRANS_TABLES.
    # Context: http://dev.mysql.com/worklog/task/?id=7467
    
    sql-mode="ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE"
    
    # The optimizer changes the default from 10 dives to 200 dives by default
    # Context: http://mysqlserverteam.com/you-asked-for-it-new-default-for-eq_range_index_dive_limit/
    
    eq_range_index_dive_limit=200
    
    # MySQL 5.7 contains a new internal server logging API.
    # The setting log_warnings is deprecated in 5.7.2 in favour of log_error_verbosity.
    # *But* the default fo log_warnings also changes to 2 as well:
    
    log_warnings=2
    
    # MySQL 5.7.7 changes a number of replication defaults
    # Binary logging is still disabled, but will default to ROW when enabled.
    
    binlog_format=ROW
    sync_binlog=1
    slave_net_timeout=60
    
    # InnoDB defaults to the new Dynamic Row format with Barracuda file format.
    # large_prefix is also enabled, which allows for longer index values.
    
    innodb_strict_mode=1
    innodb_file_format=Barracuda
    innodb_large_prefix=1
    innodb_purge_threads=4 # coming in 5.7.8
    innodb_checksum_algorithm=crc32
    
    # In MySQL 5.7 only 20% of the pool will be dumped, 
    # But 5.6 does not support this option
    
    innodb_buffer_pool_dump_at_shutdown=1
    innodb_buffer_pool_load_at_startup=1
    
    # These two options had different names in previous versions
    # (binlogging_impossible_mode,simplified_binlog_gtid_recovery)
    # This config file targets 5.6.23+, but includes the 'loose' modifier to not fail
    # prior versions.
    
    loose-binlog_error_action=ABORT_SERVER
    loose-binlog_gtid_recovery_simplified=1
    
    # 5.7 enable additional P_S consumers by default
    # This one is supported in 5.6 as well.
    performance-schema-consumer-events_statements_history=ON
    

### (Optional) Step 3 — Changing sql\_mode on a Per Session Basis

Sometimes you want to test or upgrade your server in stages. Rather than changing your server-wide configuration file for MySQL to use new SQL modes, it is also possible to change them on a per session basis. Here is an example:

    CREATE TABLE sql_mode_test (a int);

No SQL mode set:

    set sql_mode = '';
    INSERT INTO sql_mode_test (a) VALUES (0/0);
    Query OK, 1 row affected (0.01 sec)

Stricter SQL mode set:

    set sql_mode = 'STRICT_TRANS_TABLES';
    INSERT INTO sql_mode_test (a) VALUES (0/0);
    ERROR 1365 (22012): Division by 0

## Ready to Upgrade

At this point, you should be confident that you’re prepared to upgrade to MySQL 5.7. Follow along with [MySQL’s official upgrade guide](http://dev.mysql.com/doc/refman/5.7/en/upgrading-from-previous-series.html) to flip the switch.

### Conclusion

MySQL 5.7 takes a big step forward in improving the default configuration and data integrity for modern applications. We hope this article helps you make a smooth transition!

For an overview of all the changes in 5.7 (so far), check out the MySQL Server Team’s blog posts:

- [What’s New in MySQL 5.7? (So Far)](http://mysqlserverteam.com/whats-new-in-mysql-5-7-so-far/)
- [What’s New in MySQL 5.7? (First Release Candidate)](http://mysqlserverteam.com/whats-new-in-mysql-5-7-first-release-candidate/)
