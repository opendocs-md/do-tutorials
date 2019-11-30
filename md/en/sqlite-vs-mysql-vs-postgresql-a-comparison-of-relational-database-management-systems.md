---
author: ostezer, Mark Drake
date: 2014-02-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems
---

# SQLite vs MySQL vs PostgreSQL: A Comparison Of Relational Database Management Systems

## Introduction

The _relational data model_, which organizes data in tables of rows and columns, predominates in database management tools. Today there are other data models, including [NoSQL](https://en.wikipedia.org/wiki/NoSQL) and [NewSQL](https://en.wikipedia.org/wiki/NewSQL), but relational database management systems (RDBMSs) [remain dominant](https://db-engines.com/en/ranking_categories) for storing and managing data worldwide.

This article compares and contrasts three of the most widely implemented open-source RDBMSs: [SQLite](https://www.sqlite.org/index.html), [MySQL](https://www.mysql.com/), and [PostgreSQL](https://www.postgresql.org/). Specifically, it will explore the data types that each RDBMS uses, their advantages and disadvantages, and situations where they are best optimized.

## A Bit About Database Management Systems

_Databases_ are logically modelled clusters of information, or _data_. A _database management system_ (DBMS), on the other hand, is a computer program that interacts with a database. A DBMS allows you to control access to a database, write data, run queries, and perform any other tasks related to database management. Although database management systems are often referred to as “databases,” the two terms are not interchangeable. A database can be any collection of data, not just one stored on a computer, while a DBMS is the software that allows you to interact with a database.

All database management systems have an underlying model that structures how data is stored and accessed. A relational database management system is a DBMS that employs the relational data model. In this model, data are organized into tables, which in the context of RDBMSs are more formally referred to as _relations_. A relation is a set of _tuples_, or rows in a table, with each tuple sharing a set of _attributes_, or columns:

![Diagram example showing how relations, tuples, and attributes relate to one another](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/sqlite_vs_mysql_vs_postgres/tupleschart_2.png)

Most relational databases use _structured query language_ (SQL) to manage and query data. However, many RDBMSs use their own particular dialect of SQL, which may have certain limitations or extensions. These extensions typically include extra features that allow users to perform more complex operations than they otherwise could with standard SQL.

**Note:** The term “standard SQL” comes up several times throughout this guide. SQL standards are jointly maintained by the [American National Standards Institute (ANSI)](https://www.ansi.org/), the [International Organization for Standardization (ISO)](https://www.iso.org/home.html), and the [International Electrotechnical Commission (IEC)](https://www.iec.ch/). Whenever this article mentions “standard SQL” or “the SQL standard,” it’s referring to the current version of the SQL standard published by these bodies.

It should be noted that the full SQL standard is large and complex: full core SQL:2011 compliance requires 179 features. Because of this, most RDBMSs don’t support the entire standard, although some do come closer to full compliance than others.

Each column is assigned a _data type_ which dictates what kind of entries are allowed in that column. Different RDBMSs implement different data types, which aren’t always directly interchangeable. Some common data types include dates, strings, integers, and Booleans.

Numeric data types can either be _signed_, meaning they can represent both positive and negative numbers, or _unsigned_, which means they can only represent positive numbers. For example, MySQL’s `tinyint` data type can hold 8 bits of data, which equates to 256 possible values. The signed range of this data type is from -128 to 127, while the unsigned range is from 0 to 255.

Sometimes, a database administrator will impose a _constraint_ on a table to limit what values can be entered into it. A constraint typically applies to one particular column, but some constraints can also apply to an entire table. Here are some constraints that are commonly used in SQL:

- `UNIQUE`: Applying this constraint to a column ensures that no two entries in that column are identical. 
- `NOT NULL`: This constraint ensures that a column doesn’t have any `NULL` entries.
- `PRIMARY KEY`: A combination of `UNIQUE` and `NOT NULL`, the `PRIMARY KEY` constraint ensures that no entry in the column is `NULL` and that every entry is distinct.
- `FOREIGN KEY`: A `FOREIGN KEY` is a column in one table that refers to the `PRIMARY KEY` of another table. This constraint is used to link two tables together: entries to the `FOREIGN KEY` column must already exist in the parent `PRIMARY KEY` column for the write process to succeed.
- `CHECK`: This constraint limits the range of values that can be entered into a column. For example, if your application is intended only for residents of Alaska, you could add a `CHECK` constraint on a ZIP code column to only allow entries between 99501 and 99950.
- `DEFAULT`: This provides a default value for a given column. Unless another value is specified, SQLite enters the default value automatically.
- `INDEX`: Used to help retrieve data from a table more quickly, this constraint is similar to an index in a textbook: instead of having to review every entry in a table, a query only has to review entries from the indexed column to find the desired results.

If you’d like to learn more about database management systems, check out our article on [Understanding SQL and NoSQL Databases and Different Database Models](https://www.digitalocean.com/community/articles/understanding-sql-and-nosql-databases-and-different-database-models).

Now that we’ve covered relational database management systems generally, let’s move onto the first of the three open-source relational databases this article will cover: SQLite.

## SQLite

SQLite is a self-contained, file-based, and fully open-source RDBMS known for its portability, reliability, and strong performance even in low-memory environments. Its transactions are [ACID-compliant](https://en.wikipedia.org/wiki/ACID_(computer_science)), even in cases where the system crashes or undergoes a power outage.

The [SQLite project’s website](https://www.sqlite.org/serverless.html) describes it as a “serverless” database. Most relational database engines are implemented as a server process in which programs communicate with the host server through an interprocess communication that relays requests. With SQLite, though, any process that accesses the database reads from and writes to the database disk file directly. This simplifies SQLite’s setup process, since it eliminates any need to configure a server process. Likewise, there’s no configuration necessary for programs that will use the SQLite database: all they need is access to the disk.

SQLite is free and open-source software, and no special license is required to use it. However, the project does offer several extensions — each for a one-time fee — that help with compression and encryption. Additionally, the project offers various commercial support packages, each for an annual fee.

### SQLite’s Supported Data Types

SQLite allows a variety of data types, organized into the following _storage classes_:

| Data Type | Explanation |
| --- | --- |
| `null` | Includes any `NULL` values. |
| `integer` | Signed integers, stored in 1, 2, 3, 4, 6, or 8 bytes depending on the magnitude of the value. |
| `real` | Real numbers, or floating point values, stored as 8-byte floating point numbers. |
| `text` | Text strings stored using the database encoding, which can either be UTF-8, UTF-16BE or UTF-16LE. |
| `blob` | Any blob of data, with every blob stored exactly as it was input. |

In the context of SQLite, the terms “storage class” and “data type” are considered interchangeable. If you’d like to learn more about SQLite’s data types and SQLite type affinity, check out SQLite’s [official documentation](http://www.sqlite.org/datatype3.html) on the subject.

### Advantages of SQLite

- **Small footprint** : As its name implies, the SQLite library is very lightweight. Although the space it uses varies depending on the system where it’s installed, it can take up less than 600KiB of space. Additionally, it’s fully self-contained, meaning there aren’t any external dependencies you have to install on your system for SQLite to work.
- **User-friendly** : SQLite is sometimes described as a “zero-configuration” database that’s ready for use out of the box. SQLite doesn’t run as a server process, which means that it never needs to be stopped, started, or restarted and doesn’t come with any configuration files that need to be managed. These features help to streamline the path from installing SQLite to integrating it with an application.
- **Portable** : Unlike other database management systems, which typically store data as a large batch of separate files, an entire SQLite database is stored in a single file. This file can be located anywhere in a directory hierarchy, and can be shared via removable media or file transfer protocol.

### Disadvantages of SQLite

- **Limited concurrency** : Although multiple processes can access and query an SQLite database at the same time, only one process can make changes to the database at any given time. This means SQLite supports greater concurrency than most other embedded database management systems, but not as much as client/server RDBMSs like MySQL or PostgreSQL.
- **No user management** : Database systems often come with support for _users_, or managed connections with predefined access privileges to the database and tables. Because SQLite reads and writes directly to an ordinary disk file, the only applicable access permissions are the typical access permissions of the underlying operating system. This makes SQLite a poor choice for applications that require multiple users with special access permissions.
- **Security** : A database engine that uses a server can, in some instances, provide better protection from bugs in the client application than a serverless database like SQLite. For example, stray pointers in a client cannot corrupt memory on the server. Also, because a server is a single persistent process, a client-server database cancontrol data access with more precision than a serverless database, allowing for more fine-grained locking and better concurrency.

### When To Use SQLite

- **Embedded applications** : SQLite is a great choice of database for applications that need portability and don’t require future expansion. Examples include single-user local applications and mobile applications or games.
- **Disk access replacement** : In cases where an application needs to read and write files to disk directly, it can be beneficial to use SQLite for the additional functionality and simplicity that comes with using SQL.
- **Testing** : For many applications it can be overkill to test their functionality with a DBMS that uses an additional server process. SQLite has an in-memory mode which can be used to run tests quickly without the overhead of actual database operations, making it an ideal choice for testing.

### When Not To Use SQLite

- **Working with lots of data** : SQLite can technically support a database up to 140TB in size, as long as the disk drive and filesystem also support the database’s size requirements. However, the SQLite website [recommends](https://www.sqlite.org/whentouse.html) that any database approaching 1TB be housed on a centralized client-server database, as an SQLite database of that size or larger would be difficult to manage.
- **High write volumes** : SQLite allows only one write operation to take place at any given time, which significantly limits its throughput. If your application requires lots of write operations or multiple concurrent writers, SQLite may not be adequate for your needs.
- **Network access is required** : Because SQLite is a serverless database, it doesn’t provide direct network access to its data. This access is built into the application, so if the data in SQLite is located on a separate machine from the application it will require a high bandwidth engine-to-disk link across the network. This is an expensive, inefficient solution, and in such cases a client-server DBMS may be a better choice.

## MySQL

According to the [DB-Engines Ranking](https://db-engines.com/en/), MySQL has been the most popular open-source RDBMS since the site began tracking database popularity in 2012. It is a feature-rich product that powers many of the world’s largest websites and applications, including Twitter, Facebook, Netflix, and Spotify. Getting started with MySQL is relatively straightforward, thanks in large part to its [exhaustive documentation](https://dev.mysql.com/doc/) and large [community of developers](https://forums.mysql.com/), as well as the abundance of MySQL-related resources online.

MySQL was designed for speed and reliability, at the expense of full adherence to standard SQL. The MySQL developers continually work towards closer adherence to standard SQL, but it still lags behind other SQL implementations. It does, however, come with various SQL modes and extensions that bring it closer to compliance. Unlike applications using SQLite, applications using a MySQL database access it through a separate daemon process. Because the server process stands between the database and other applications, it allows for greater control over who has access to the database.

MySQL has inspired a wealth of third-party applications, tools, and integrated libraries that extend its functionality and help make it easier to work with. Some of the more widely-used of these third-party tools are [phpMyAdmin](https://www.phpmyadmin.net/), [DBeaver](https://dbeaver.io/), and [HeidiSQL](https://www.heidisql.com/).

### MySQL’s Supported Data Types

MySQL’s data types can be organized into three broad categories: numeric types, date and time types, and string types.

**Numeric types** :

| Data Type | Explanation |
| --- | --- |
| `tinyint` | A very small integer. The signed range for this numeric data type is -128 to 127, while the unsigned range is 0 to 255. |
| `smallint` | A small integer. The signed range for this numeric type is -32768 to 32767, while the unsigned range is 0 to 65535. |
| `mediumint` | A medium-sized integer. The signed range for this numeric data type is -8388608 to 8388607, while the unsigned range is 0 to 16777215. |
| `int` or `integer` | A normal-sized integer. The signed range for this numeric data type is -2147483648 to 2147483647, while the unsigned range is 0 to 4294967295. |
| `bigint` | A large integer. The signed range for this numeric data type is -9223372036854775808 to 9223372036854775807, while the unsigned range is 0 to 18446744073709551615. |
| `float` | A small (single-precision) floating-point number. |
| `double`, `double precision`, or `real` | A normal sized (double-precision) floating-point number. |
| `dec`, `decimal`, `fixed`, or `numeric` | A packed fixed-point number. The display length of entries for this data type is defined when the column is created, and every entry adheres to that length. |
| `bool` or `boolean` | A Boolean is a data type that only has two possible values, usually either `true` or `false`. |
| `bit` | A bit value type for which you can specify the number of bits per value, from 1 to 64. |

**Date and time types** :

| Data Type | Explanation |
| --- | --- |
| `date` | A date, represented as `YYYY-MM-DD`. |
| `datetime` | A timestamp showing the date and time, displayed as `YYYY-MM-DD HH:MM:SS`. |
| `timestamp` | A timestamp indicating the amount of time since the [Unix epoch](https://en.wikipedia.org/wiki/Unix_time) (00:00:00 on January 1, 1970). |
| `time` | A time of day, displayed as `HH:MM:SS`. |
| `year` | A year expressed in either a 2 or 4 digit format, with 4 digits being the default. |

**String types** :

| Data Type | Explanation |
| --- | --- |
| `char` | A fixed-length string; entries of this type are padded on the right with spaces to meet the specified length when stored. |
| `varchar` | A string of variable length. |
| `binary` | Similar to the `char` type, but a binary byte string of a specified length rather than a nonbinary character string. |
| `varbinary` | Similar to the `varchar` type, but a binary byte string of a variable length rather than a nonbinary character string. |
| `blob` | A binary string with a maximum length of 65535 (2^16 - 1) bytes of data. |
| `tinyblob` | A `blob` column with a maximum length of 255 (2^8 - 1) bytes of data. |
| `mediumblob` | A `blob` column with a maximum length of 16777215 (2^24 - 1) bytes of data. |
| `longblob` | A `blob` column with a maximum length of 4294967295 (2^32 - 1) bytes of data. |
| `text` | A string with a maximum length of 65535 (2^16 - 1) characters. |
| `tinytext` | A `text` column with a maximum length of 255 (2^8 - 1) characters. |
| `mediumtext` | A `text` column with a maximum length of 16777215 (2^24 - 1) characters. |
| `longtext` | A `text` column with a maximum length of 4294967295 (2^32 - 1) characters. |
| `enum` | An enumeration, which is a string object that takes a single value from a list of values that are declared when the table is created. |
| `set` | Similar to an enumeration, a string object that can have zero or more values, each of which must be chosen from a list of allowed values that are specified when the table is created. |

### Advantages of MySQL

- **Popularity and ease of use** : As one of the world’s most popular database systems, there’s no shortage of database administrators who have experience working with MySQL. Likewise, there’s an abundance of documentation in print and online on how to install and manage a MySQL database, as well as a number of third-party tools — such as phpMyAdmin — that aim to simplify the process of getting started with the database.
- **Security** : MySQL comes installed with a script that helps you to improve the security of your database by setting the installation’s password security level, defining a password for the **root** user, removing anonymous accounts, and removing test databases that are, by default, accessible to all users. Also, unlike SQLite, MySQL does support user management and allows you to grant access privileges on a user-by-user basis. 
- **Speed** : By choosing not to implement certain features of SQL, the MySQL developers were able to prioritize speed. While more recent benchmark tests show that other RDBMSs like PostgreSQL can match or at least come close to MySQL in terms of speed, MySQL still holds a reputation as an exceedingly fast database solution.
- **Replication** : MySQL supports a number of different types of [_replication_](https://en.wikipedia.org/wiki/Replication_(computing)#Database_replication), which is the practice of sharing information across two or more hosts to help improve reliability, availability, and fault-tolerance. This is helpful for setting up a database backup solution or [_horizontally scaling_](https://en.wikipedia.org/wiki/Scalability#HORIZONTAL-SCALING) one’s database.

### Disadvantages of MySQL

- **Known limitations** : Because MySQL was designed for speed and ease of use rather than full SQL compliance, it comes with certain functional limitations. For example, it [lacks support for `FULL JOIN` clauses](https://fthiella.github.io/mysql-full-outer-join/).
- **Licensing and proprietary features** : MySQL is _dual-licensed_ software, with a free and open-source community edition licensed under [GPLv2](https://en.wikipedia.org/wiki/GNU_General_Public_License#Version_2) and several paid commercial editions released under proprietary licenses. Because of this, some features and plugins are only available for the proprietary editions. 
- **Slowed development** : Since the MySQL project was acquired by Sun Microsystems in 2008, and later by Oracle Corporation in 2009, there have been complaints from users that the development process for the DBMS has slowed down significantly, as the community no longer has the agency to quickly react to problems and implement changes. 

### When To Use MySQL

- **Distributed operations** : MySQL’s replication support makes it a great choice for distributed database setups like [primary-secondary](https://dev.mysql.com/doc/refman/8.0/en/group-replication-primary-secondary-replication.html) or [primary-primary](https://dev.mysql.com/doc/refman/8.0/en/group-replication-summary.html) architectures. 
- **Websites and web applications** : MySQL powers many websites and applications across the internet. This is, in large part, thanks to how easy it is to install and set up a MySQL database, as well as its overall speed and scalability in the long run.
- **Expected future growth** : MySQL’s replication support can help facilitate horizontal scaling. Additionally, it’s a relatively straightforward process to upgrade to a commercial MySQL product, like MySQL Cluster, which supports automatic sharding, another horizontal scaling process.  

### When Not To Use MySQL

- **SQL compliance is necessary** : Since MySQL does not try to implement the full SQL standard, this tool is not completely SQL compliant. If complete or even near-complete SQL compliance is a must for your use case, you may want to use a more fully compliant DBMS.
- **Concurrency and large data volumes** : Although MySQL generally performs well with read-heavy operations, concurrent read-writes can be problematic. If your application will have many users writing data to it at once, another RDBMS like PostgreSQL might be a better choice of database.

## PostgreSQL

PostgreSQL, also known as Postgres, bills itself as “the most advanced open-source relational database in the world.” It was created with the goal of being highly extensible and standards compliant. PostgreSQL is an object-relational database, meaning that although it’s primarily a relational database it also includes features — like table inheritance and function overloading — that are more often associated with [_object databases_](https://en.wikipedia.org/wiki/Object_database).

Postgres is capable of efficiently handling multiple tasks at the same time, a characteristic known as _concurrency_. It achieves this without read locks thanks to its implementation of [Multiversion Concurrency Control (MVCC)](https://en.wikipedia.org/wiki/Multiversion_concurrency_control), which ensures the atomicity, consistency, isolation, and durability of its transactions, also known as ACID compliance.

PostgreSQL isn’t as widely used as MySQL, but there are still a number of third-party tools and libraries designed to simplify working with with PostgreSQL, including [pgAdmin](https://www.pgadmin.org/) and [Postbird](https://github.com/paxa/postbird).

### PostgreSQL’s Supported Data Types

PostgreSQL supports numeric, string, and date and time data types like MySQL. In addition, it supports data types for geometric shapes, network addresses, bit strings, text searches, and JSON entries, as well as several idiosyncratic data types.

**Numeric types** :

| Data Type | Explanation |
| --- | --- |
| `bigint` | A signed 8 byte integer. |
| `bigserial` | An autoincrementing 8 byte integer. |
| `double precision` | An 8 byte double precision floating-point number. |
| `integer` | A signed 4 byte integer. |
| `numeric` or `decimal` | An number of selectable precision, recommended for use in cases where exactness is crucial, such as monetary amounts. |
| `real` | A 4 byte single precision floating-point number. |
| `smallint` | A signed 2 byte integer. |
| `smallserial` | An autoincrementing 2 byte integer. |
| `serial` | An autoincrementing 4 byte integer. |

**Character types** :

| Data Type | Explanation |
| --- | --- |
| `character` | A character string with a specified fixed length. |
| `character varying` or `varchar` | A character string with a variable but limited length. |
| `text` | A character string of a variable, unlimited length. |

**Date and time types** :

| Data Type | Explanation |
| --- | --- |
| `date` | A calendar date consisting of the day, month, and year. |
| `interval` | A time span. |
| `time` or `time without time zone` | A time of day, not including the time zone. |
| `time with time zone` | A time of day, including the time zone. |
| `timestamp` or `timestamp without time zone` | A date and time, not including the time zone. |
| `timestamp with time zone` | A date and time, including the time zone. |

**Geometric types** :

| Data Type | Explanation |
| --- | --- |
| `box` | A rectangular box on a plane. |
| `circle` | A circle on a plane. |
| `line` | An infinite line on a plane. |
| `lseg` | A line segment on a plane. |
| `path` | A geometric path on a plane. |
| `point` | A geometric point on a plane. |
| `polygon` | A closed geometric path on a plane. |

**Network address types** :

| Data Type | Explanation |
| --- | --- |
| `cidr` | An IPv4 or IPv6 network address. |
| `inet` | An IPv4 or IPv6 host address. |
| `macaddr` | A Media Access Control (MAC) address. |

**Bit string types** :

| Data Type | Explanation |
| --- | --- |
| `bit` | A fixed-length bit string. |
| `bit varying` | A variable-length bit string. |

**Text search types** :

| Data Type | Explanation |
| --- | --- |
| `tsquery` | A text search query. |
| `tsvector` | A text search document. |

**JSON types** :

| Data Type | Explanation |
| --- | --- |
| `json` | Textual JSON data. |
| `jsonb` | Decomposed binary JSON data. |

**Other data types** :

| Data Type | Explanation |
| --- | --- |
| `boolean` | A logical Boolean, representing either `true` or `false`. |
| `bytea` | Short for “byte array”, this type is used for binary data. |
| `money` | An amount of currency. |
| `pg_lsn` | A PostgreSQL Log Sequence Number. |
| `txid_snapshot` | A user-level transaction ID snapshot. |
| `uuid` | A universally unique identifier. |
| `xml` | XML data. |

### Advantages of PostgreSQL

- **SQL compliance** : More so than SQLite or MySQL, PostgreSQL aims to closely adhere to SQL standards. [According to the official PostgreSQL documentation](https://www.postgresql.org/docs/current/features.html), PostgreSQL supports 160 out of the 179 features required for full core SQL:2011 compliance, in addition to a long list of optional features.
- **Open-source and community-driven** : A fully open-source project, PostgreSQL’s source code is developed by a large and devoted community. Similarly, the Postgres community maintains and contributes to numerous online resources that describe how to work with the DBMS, including the [official documentation](https://www.postgresql.org/docs/), the [PostgreSQL wiki](https://wiki.postgresql.org/wiki/Main_Page), and various online forums.
- **Extensible** : Users can extend PostgreSQL programmatically and on the fly through its [catalog-driven operation](https://www.postgresql.org/docs/9.0/extend-how.html) and its use of [dynamic loading](https://en.wikipedia.org/wiki/Dynamic_loading). One can designate an object code file, such as a shared library, and PostgreSQL will load it as necessary. 

### Disadvantages of PostgreSQL

- **Memory performance** : For every new client connection, PostgreSQL forks a new process. Each new process is allocated about 10MB of memory, which can add up quickly for databases with lots of connections. Accordingly, for simple read-heavy operations, PostgreSQL is typically less performant than other RDBMSs, like MySQL.
- **Popularity** : Although more widely used in recent years, PostgreSQL historically lagged behind MySQL in terms of popularity. One consequence of this is that there are still fewer third-party tools that can help to manage a PostgreSQL database. Similarly, there aren’t as many database administrators with experience managing a Postgres database compared to those with MySQL experience.

### When To Use PostgreSQL

- **Data integrity is important** : PostgreSQL has been fully ACID-compliant since 2001 and implements multiversion currency control to ensure that data remains consistent, making it a strong choice of RDBMS when data integrity is critical.
- **Integration with other tools** : PostgreSQL is compatible with a wide array of programming languages and platforms. This means that if you ever need to migrate your database to another operating system or integrate it with a specific tool, it will likely be easier with a PostgreSQL database than with another DBMS.
- **Complex operations** : Postgres supports query plans that can leverage multiple CPUs in order to answer queries with greater speed. This, coupled with its strong support for multiple concurrent writers, makes it a great choice for complex operations like data warehousing and online transaction processing.

### When Not To Use PostgreSQL

- **Speed is imperative** : At the expense of speed, PostgreSQL was designed with extensibility and compatibility in mind. If your project requires the fastest read operations possible, PostgreSQL may not be the best choice of DBMS.
- **Simple setups** : Because of its large feature set and strong adherence to standard SQL, Postgres can be overkill for simple database setups. For read-heavy operations where speed is required, MySQL is typically a more practical choice.
- **Complex replication** : Although PostgreSQL does provide strong support for replication, it’s still a relatively new feature and some configurations — like a primary-primary architecture — are only possible with extensions. Replication is a more mature feature on MySQL and many users see MySQL’s replication to be easier to implement, particularly for those who lack the requisite database and system administration experience.

## Conclusion

Today, SQLite, MySQL, and PostgreSQL are the three most popular open-source relational database management systems in the world. Each has its own unique features and limitations, and excels in particular scenarios. There are a quite a few variables at play when deciding on an RDBMS, and the choice is rarely as simple as picking the fastest one or the one with the most features. The next time you’re in need of a relational database solution, be sure to research these and other tools in depth to find the one that best suits your needs.

If you’d like to learn more about SQL and how to use it to manage a relational database, we encourage you to refer to our [How To Manage an SQL Database](how-to-manage-sql-database-cheat-sheet) cheat sheet. On the other hand, if you’d like to learn about non-relational (or NoSQL) databases, check out our [Comparison Of NoSQL Database Management Systems](https://www.digitalocean.com/community/articles/a-comparison-of-nosql-database-management-systems-and-models).

### References

- [DB-Engines Rankings](https://db-engines.com/en/ranking)
- [SQLite Official Documentation](https://www.sqlite.org/docs.html)
- [SQLite Is Serverless](https://www.sqlite.org/serverless.html)
- [Appropriate Uses For SQLite](https://www.sqlite.org/whentouse.html)
- [MySQL Official Documentation](https://dev.mysql.com/doc/refman/8.0/en/)
- [Comparing MySQL and Postgres 9.0 Replication](https://www.theserverside.com/feature/Comparing-MySQL-and-Postgres-90-Replication)
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/current/index.html)
- [Has the time finally come for PostgreSQL?](https://www.zdnet.com/article/has-the-time-finally-come-for-postgresql/)
