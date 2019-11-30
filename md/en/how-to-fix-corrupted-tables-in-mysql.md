---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-fix-corrupted-tables-in-mysql
---

# How To Fix Corrupted Tables in MySQL

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

Occasionally, MySQL tables can become corrupted, meaning that an error has occurred and the data held within them is unreadable. Attempts to read from a corrupted table will usually lead to the server crashing.

Some common causes of corrupted tables are:

- The MySQL server stops in middle of a write.
- An external program modifies a table that’s simultaneously being modified by the server.
- The machine is shut down unexpectedly.
- The computer hardware fails.
- There’s a software bug somewhere in the MySQL code.

If you suspect that one of your tables has been corrupted, you should make a backup of your data directory before troubleshooting or attempting to fix the table. This will help to minimize the risk of data loss.

First, stop the MySQL service:

    sudo systemctl stop mysql

Then copy all of your data into a new backup directory. On Ubuntu systems, the default data directory is `/var/lib/mysql/`:

    cp -r /var/lib/mysql /var/lib/mysql_bkp

After making the backup, you’re ready to begin investigating whther the table is in fact corrupted. If the table uses the [MyISAM storage engine](https://dev.mysql.com/doc/refman/5.7/en/myisam-storage-engine.html), you can check whether it’s corrupted by running a `CHECK TABLE` statement from the MySQL prompt:

    CHECK TABLE table_name;

A message will appear in this statement’s output letting you know whether or not it’s corrupted. If the MyISAM table is indeed corrupted, it can usually be repaired by issuing a `REPAIR TABLE` statement:

    REPAIR TABLE table_name;

Assuming the repair was successful, you will see a message like the following in your output:

    Output+--------------------------+--------+----------+----------+
    | Table | Op | Msg_type | Msg_text |
    +--------------------------+--------+----------+----------+
    | database_name.table_name | repair | status | OK |
    +--------------------------+--------+----------+----------+

If the table is still corrupted, though, the MySQL documentation suggests a few [alternative methods for repairing corrupted tables](https://dev.mysql.com/doc/refman/5.7/en/rebuilding-tables.html).

On the other hand, if the corrupted table uses the [InnoDB storage engine](https://dev.mysql.com/doc/refman/5.7/en/innodb-storage-engine.html), then the process for repairing it will be different. InnoDB is the default storage engine in MySQL as of version 5.5, and it features automated corruption checking and repair operations. InnoDB checks for corrupted pages by performing checksums on every page it reads, and if it finds a checksum discrepancy it will automatically stop the MySQL server.

There is rarely a need to repair InnoDB tables, as InnoDB features a crash recovery mechanism that can resolve most issues when the server is restarted. However, if you do encounter a situation where you need to rebuild a corrupted InnoDB table, the MySQL documentation recommends using the [“Dump and Reload” method](https://dev.mysql.com/doc/refman/5.7/en/rebuilding-tables.html#rebuilding-tables-dump-reload). This involves regaining access to the corrupted table, using the `mysqldump` utility to create a [_logical backup_](https://dev.mysql.com/doc/refman/5.7/en/glossary.html#glos_logical_backup) of the table, which will retain the table structure and the data within it, and then reloading the table back into the database.

With that in mind, try restarting the MySQL service to see if doing so will allow you access to the server:

    sudo systemctl restart mysql

If the server remains crashed or otherwise inaccessible, then it may be helpful to enable InnoDB’s `force_recovery` option. You can do this by editing the `mysqld.cnf` file:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

In the `[mysqld]` section, add the following line:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    [mysqld]
    . . .
    innodb_force_recovery=1

Save and close the file, and then try restarting the MySQL service again. If you can successfully access the corrupted table, use the `mysqldump` utility to dump your table data to a new file. You can name this file whatever you like, but here we’ll name it `out.sql`:

    mysqldump database_name table_name > out.sql

Then drop the table from the database. To avoid having to reopen the MySQL prompt, you can use the following syntax:

    mysql -u user -p --execute="DROP TABLE database_name.table_name"

Following this, restore the table with the dump file you just created:

    mysql -u user -p < out.sql

Note that the InnoDB storage engine is generally more fault-tolerant than the older MyISAM engine. Tables using InnoDB _can_ still be corrupted, but because of its [auto-recovery features](https://dev.mysql.com/doc/refman/5.7/en/innodb-recovery.html) the risk of table corruption and crashes is decidedly lower.
