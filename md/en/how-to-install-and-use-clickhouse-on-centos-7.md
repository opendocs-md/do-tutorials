---
author: bsder
date: 2019-04-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-clickhouse-on-centos-7
---

# How To Install and Use ClickHouse on CentOS 7

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[ClickHouse](https://clickhouse.yandex) is an open-source, column-oriented analytics database created by [Yandex](https://yandex.com) for [OLAP](https://en.wikipedia.org/wiki/Online_analytical_processing) and big data use cases. ClickHouse’s support for real-time query processing makes it suitable for applications that require sub-second analytical results. ClickHouse’s query language is a dialect of SQL that enables powerful declarative querying capabilities while offering familiarity and a smaller learning curve for the end user.

_Column-oriented_ databases store records in blocks grouped by columns instead of rows. By not loading data for columns absent in the query, column-oriented databases spend less time reading data while completing queries. As a result, these databases can compute and return results much faster than traditional row-based systems for certain workloads, such as OLAP.

_Online Analytics Processing_ (OLAP) systems allow for organizing large amounts of data and performing complex queries. They are capable of managing petabytes of data and returning query results quickly. In this way, OLAP is useful for work in areas like data science and business analytics.

In this tutorial, you’ll install the ClickHouse database server and client on your machine. You’ll use the DBMS for typical tasks and optionally enable remote access from another server so that you’ll be able to connect to the database from another machine. Then you’ll test ClickHouse by modeling and querying example website-visit data.

## Prerequisites

- One CentOS 7 server with a `sudo` enabled non-root user and firewall setup. You can follow the initial server setup [tutorial](initial-server-setup-with-centos-7) to create the user and this [tutorial](additional-recommended-steps-for-new-centos-7-servers#configuring-a-basic-firewall) to set up the firewall.
- (Optional) A secondary CentOS 7 server with a `sudo` enabled non-root user and firewall setup. You can follow the initial server setup [tutorial](initial-server-setup-with-centos-7) and the additional setup [tutorial](additional-recommended-steps-for-new-centos-7-servers#configuring-a-basic-firewall) for the firewall.

## Step 1 — Installing ClickHouse

In this section, you will install the ClickHouse server and client programs using `yum`.

First, SSH into your server by running:

    ssh sammy@your_server_ip

Install the base dependencies by executing:

    sudo yum install -y pygpgme yum-utils

The `pygpgme` packages is used for adding and verifying GPG signatures while the `yum-utils` allows easy management of source RPMs.

[Altinity](https://www.altinity.com/community-projects), a ClickHouse consulting firm, maintains a YUM repository that has the latest version of ClickHouse. You’ll add the repository’s details to securely download validated ClickHouse packages by creating the file. To check the package contents, you can inspect the sources from which they are built at this [Github project](https://github.com/Altinity/clickhouse-rpm).

Create the repository details file by executing:

    sudo vi /etc/yum.repos.d/altinity_clickhouse.repo

Next, add the following contents to the file:

/etc/yum.repos.d/altinity\_clickhouse.repo

    [altinity_clickhouse]
    name=altinity_clickhouse
    baseurl=https://packagecloud.io/altinity/clickhouse/el/7/$basearch
    repo_gpgcheck=1
    gpgcheck=0
    enabled=1
    gpgkey=https://packagecloud.io/altinity/clickhouse/gpgkey
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300
    
    [altinity_clickhouse-source]
    name=altinity_clickhouse-source
    baseurl=https://packagecloud.io/altinity/clickhouse/el/7/SRPMS
    repo_gpgcheck=1
    gpgcheck=0
    enabled=1
    gpgkey=https://packagecloud.io/altinity/clickhouse/gpgkey
    sslverify=1
    sslcacert=/etc/pki/tls/certs/ca-bundle.crt
    metadata_expire=300

Now that you’ve added the repositories, enable them with the following command:

    sudo yum -q makecache -y --disablerepo='*' --enablerepo='altinity_clickhouse'

The `-q` flag tells the command to run in quiet mode. The `makecache` command makes available the packages specified in the `--enablerepo` flag.

On execution, you’ll see output similar to the following:

    OutputImporting GPG key 0x0F6E36F6:
     Userid : "https://packagecloud.io/altinity/clickhouse (https://packagecloud.io/docs#gpg_signing) <support@packagecloud.io>"
     Fingerprint: 7001 38a9 6a20 6b22 bf28 3c06 ed26 58f3 0f6e 36f6
     From : https://packagecloud.io/altinity/clickhouse/gpgkey

The output confirms it has successfully verified and added the GPG key.

The `clickhouse-server` and `clickhouse-client` packages will now be available for installation. Install them with:

    sudo yum install -y clickhouse-server clickhouse-client

You’ve installed the ClickHouse server and client successfully. You’re now ready to start the database service and ensure that it’s running correctly.

## Step 2 — Starting the Service

The `clickhouse-server` package that you installed in the previous section creates a `systemd` service, which performs actions such as starting, stopping, and restarting the database server. [`systemd`](understanding-systemd-units-and-unit-files) is an init system for Linux to initialize and manage services. In this section you’ll start the service and verify that it is running successfully.

Start the `clickhouse-server` service by running:

    sudo service clickhouse-server start

You will see output similar to the following:

    OutputStart clickhouse-server service: Path to data directory in /etc/clickhouse-server/config.xml: /var/lib/clickhouse/
    DONE

To verify that the service is running successfully, execute:

    sudo service clickhouse-server status

It will print an output similar to the following which denotes that the server is running properly:

    Outputclickhouse-server service is running

You have successfully started the ClickHouse server and will now be able to use the `clickhouse-client` CLI program to connect to the server.

## Step 3 — Creating Databases and Tables

In ClickHouse, you can create and delete databases by executing SQL statements directly in the interactive database prompt. Statements consist of commands following a particular syntax that tell the database server to perform a requested operation along with any data required. You create databases by using the `CREATE DATABASE table_name` syntax. To create a database, first start a client session by running the following command:

    clickhouse-client --multiline

This command will log you into the client prompt where you can run ClickHouse SQL statements to perform actions such as:

- Creating, updating, and deleting databases, tables, indexes, partitions, and views.

- Executing queries to retrieve data that is optionally filtered and grouped using various conditions.

The `--multiline` flag tells the CLI to allow entering queries that span multiple lines.

In this step, with the ClickHouse client ready for inserting data, you’re going to create a database and table. For the purposes of this tutorial, you’ll create a database named `test`, and inside that you’ll create a table named `visits` that tracks website-visit durations.

Now that you’re inside the ClickHouse command prompt, create your `test` database by executing:

    CREATE DATABASE test;

You’ll see the following output that shows that you have created the database:

    Output
    CREATE DATABASE test
    
    Ok.
    
    0 rows in set. Elapsed: 0.003 sec.

A ClickHouse table is similar to tables in other relational databases; it holds a collection of related data in a structured format. You can specify columns along with their types, add rows of data, and execute different kinds of queries on tables.

The syntax for creating tables in ClickHouse follows this example structure:

    CREATE TABLE table_name
    (
        column_name1 column_type [options],
        column_name2 column_type [options],
        ...
    ) ENGINE = engine

The `table_name` and `column_name` values can be any valid ASCII identifiers. ClickHouse supports a wide range of column types; some of the most popular are:

- `UInt64`: used for storing integer values in the range 0 to 18446744073709551615.

- `Float64`: used for storing floating point numbers such as 2039.23, 10.5, etc.

- `String`: used for storing variable length characters. It does not require a max length attribute since it can store arbitrary lengths.

- `Date`: used for storing dates that follow the `YYYY-MM-DD` format.

- `DateTime`: used for storing dates coupled with time and follows the `YYYY-MM-DD HH:MM:SS` format.

After the column definitions, you specify the engine used for the table. In ClickHouse, _Engines_ determine the physical structure of the underlying data, the table’s querying capabilities, its concurrent access modes, and support for indexes. Different engine types are suitable for different application requirements. The most commonly used and widely applicable engine type is `MergeTree`.

Now that you have an overview of table creation, you’ll create a table. Start by confirming the database you’ll be modifying:

    USE test;

You will see the following output showing that you have switched to the `test` database from the `default` database:

    Output
    USE test
    
    Ok.
    
    0 rows in set. Elapsed: 0.001 sec.

The remainder of this guide will assume that you are executing statements within this database’s context.

Create your `visits` table by running this command:

    CREATE TABLE visits (
     id UInt64,
     duration Float64,
     url String,
     created DateTime
    ) ENGINE = MergeTree() 
    PRIMARY KEY id 
    ORDER BY id;

Here’s a breakdown of what the command does. You create a table named `visits` that has four columns:

- `id`: The primary key column. Similarly to other RDBMS systems, a primary key column in ClickHouse uniquely identifies a row; each row should have a unique value for this column.

- `duration`: A float column used to store the duration of each visit in seconds. `float` columns can store decimal values such as 12.50.

- `url`: A string column that stores the URL visited, such as `http://example.com`.

- `created`: A date and time column that tracks when the visit occurred.

After the column definitions, you specify `MergeTree` as the storage engine for the table. The [MergeTree family](https://clickhouse.yandex/docs/en/operations/table_engines/mergetree/) of engines is recommended for production databases due to its optimized support for large real-time inserts, overall robustness, and query support. Additionally, MergeTree engines support sorting of rows by primary key, partitioning of rows, and replicating and sampling data.

If you intend to use ClickHouse for archiving data that is not queried often or for storing temporary data, you can use the [Log family](https://clickhouse.yandex/docs/en/operations/table_engines/log_family/) of engines to optimize for that use-case.

After the column definitions, you’ll define other table-level options. The `PRIMARY KEY` clause sets `id` as the primary key column and the `ORDER BY` clause will store values sorted by the `id` column. A primary key uniquely identifies a row and is used for efficiently accessing a single row and efficient colocation of rows.

On executing the create statement, you will see the following output:

    OutputCREATE TABLE visits
    (
        id UInt64,
        duration Float64,
        url String,
        created DateTime
    )
    ENGINE = MergeTree()
    PRIMARY KEY id
    ORDER BY id
    
    Ok.
    
    0 rows in set. Elapsed: 0.010 sec.

In this section, you’ve created a database and a table to track website-visits data. In the next step, you’ll insert data into the table, update existing data, and delete that data.

## Step 4 — Inserting, Updating, and Deleting Data and Columns

In this step, you’ll use your `visits` table to insert, update, and delete data. The following command is an example of the syntax for inserting rows into a ClickHouse table:

    INSERT INTO table_name VALUES (column_1_value, column_2_value, ....);

Now, insert a few rows of example website-visit data into your `visits` table by running each of the following statements:

    INSERT INTO visits VALUES (1, 10.5, 'http://example.com', '2019-01-01 00:01:01');

    INSERT INTO visits VALUES (2, 40.2, 'http://example1.com', '2019-01-03 10:01:01');

    INSERT INTO visits VALUES (3, 13, 'http://example2.com', '2019-01-03 12:01:01');

    INSERT INTO visits VALUES (4, 2, 'http://example3.com', '2019-01-04 02:01:01');

You’ll see the following output repeated for each insert statement:

    Output
    INSERT INTO visits VALUES
    
    Ok.
    
    1 rows in set. Elapsed: 0.004 sec.

The output for each row shows that you’ve inserted it successfully into the `visits` table.

Now you’ll add an additional column to the `visits` table. When adding or deleting columns from existing tables, ClickHouse supports the `ALTER` syntax.

For example, the basic syntax for adding a column to a table is as follows:

    ALTER TABLE table_name ADD COLUMN column_name column_type;

Add a column named `location` that will store the location of the visits to a website by running the following statement:

    ALTER TABLE visits ADD COLUMN location String;

You’ll see output similar to the following:

    OutputALTER TABLE visits
        ADD COLUMN
        location String
    
    
    Ok.
    
    0 rows in set. Elapsed: 0.014 sec.

The output shows that you have added the `location` column successfully.

As of version 19.4.3, ClickHouse doesn’t support updating and deleting individual rows of data due to implementation constraints. ClickHouse has support for bulk updates and deletes, however, and has a distinct SQL syntax for these operations to highlight their non-standard usage.

The following syntax is an example for bulk updating rows:

    ALTER TABLE table_name UPDATE column_1 = value_1, column_2 = value_2 ... WHERE filter_conditions;

You’ll run the following statement to update the `url` column of all rows that have a `duration` of less than 15. Enter it into the database prompt to execute:

    ALTER TABLE visits UPDATE url = 'http://example2.com' WHERE duration < 15;

The output of the bulk update statement will be as follows:

    Output
    ALTER TABLE visits
        UPDATE url = 'http://example2.com' WHERE duration < 15
    
    
    Ok.
    
    0 rows in set. Elapsed: 0.003 sec.

The output shows that your update query completed successfully. The `0 rows in set` in the output denotes that the query did not return any rows; this will be the case for any update and delete queries.

The example syntax for bulk deleting rows is similar to updating rows and has the following structure:

    ALTER TABLE table_name DELETE WHERE filter_conditions;

To test deleting data, run the following statement to remove all rows that have a `duration` of less than 5:

    ALTER TABLE visits DELETE WHERE duration < 5;

The output of the bulk delete statement will be similar to:

    Output
    ALTER TABLE visits
        DELETE WHERE duration < 5
    
    
    Ok.
    
    0 rows in set. Elapsed: 0.003 sec.

The output confirms that you have deleted the rows with a duration of less than five seconds.

To delete columns from your table, the syntax would follow this example structure:

    ALTER TABLE table_name DROP COLUMN column_name;

Delete the `location` column you added previously by running the following:

    ALTER TABLE visits DROP COLUMN location;

The `DROP COLUMN` output confirming that you have deleted the column will be as follows:

    OutputALTER TABLE visits
        DROP COLUMN
        location String
    
    
    Ok.
    
    0 rows in set. Elapsed: 0.010 sec.

Now that you’ve successfully inserted, updated, and deleted rows and columns in your `visits` table, you’ll move on to query data in the next step.

## Step 5 — Querying Data

ClickHouse’s query language is a custom dialect of SQL with extensions and functions suited for analytics workloads. In this step, you’ll run selection and aggregation queries to retrieve data and results from your `visits` table.

Selection queries allow you to retrieve rows and columns of data filtered by conditions that you specify, along with options such as the number of rows to return. You can select rows and columns of data using the `SELECT` syntax. The basic syntax for `SELECT` queries is:

    SELECT func_1(column_1), func_2(column_2) FROM table_name WHERE filter_conditions row_options;

Execute the following statement to retrieve `url` and `duration` values for rows where the `url` is `http://example.com`:

    SELECT url, duration FROM visits WHERE url = 'http://example2.com' LIMIT 2;

You will see the following output:

    OutputSELECT
        url,
        duration
    FROM visits
    WHERE url = 'http://example2.com'
    LIMIT 2
    
    ┌─url─────────────────┬─duration─┐
    │ http://example2.com │ 10.5 │
    └─────────────────────┴──────────┘
    ┌─url─────────────────┬─duration─┐
    │ http://example2.com │ 13 │
    └─────────────────────┴──────────┘
    
    2 rows in set. Elapsed: 0.013 sec.

The output has returned two rows that match the conditions you specified. Now that you’ve selected values, you can move to executing aggregation queries.

Aggregation queries are queries that operate on a set of values and return single output values. In analytics databases, these queries are run frequently and are well optimized by the database. Some aggregate functions supported by ClickHouse are:

- `count`: returns the count of rows matching the conditions specified.

- `sum`: returns the sum of selected column values.

- `avg`: returns the average of selected column values.

Some ClickHouse-specific aggregate functions include:

- `uniq`: returns an approximate number of distinct rows matched.

- `topK`: returns an array of the most frequent values of a specific column using an approximation algorithm.

To demonstrate the execution of aggregation queries, you’ll calculate the total duration of visits by running the `sum` query:

    SELECT SUM(duration) FROM visits;

You will see output similar to the following:

    Output
    SELECT SUM(duration)
    FROM visits
    
    ┌─SUM(duration)─┐
    │ 63.7 │
    └───────────────┘
    
    1 rows in set. Elapsed: 0.010 sec.

Now, calculate the top two URLs by executing:

    SELECT topK(2)(url) FROM visits;

You will see output similar to the following:

    OutputSELECT topK(2)(url)
    FROM visits
    
    ┌─topK(2)(url)──────────────────────────────────┐
    │ ['http://example2.com','http://example1.com'] │
    └───────────────────────────────────────────────┘
    
    1 rows in set. Elapsed: 0.010 sec.

Now that you have successfully queried your `visits` table, you’ll delete tables and databases in the next step.

## Step 6 — Deleting Tables and Databases

In this section, you’ll delete your `visits` table and `test` database.

The syntax for deleting tables follows this example:

    DROP TABLE table_name;

To delete the `visits` table, run the following statement:

    DROP TABLE visits;

You will see the following output declaring that you’ve deleted the table successfully:

    OutputDROP TABLE visits
    
    Ok.
    
    0 rows in set. Elapsed: 0.005 sec.

You can delete databases using the `DROP database table_name` syntax. To delete the `test` database, execute the following statement:

    DROP DATABASE test;

The resulting output shows that you’ve deleted the database successfully:

    Output
    DROP DATABASE test
    
    Ok.
    
    0 rows in set. Elapsed: 0.003 sec.

You’ve deleted tables and databases in this step. Now that you’ve created, updated, and deleted databases, tables, and data in your ClickHouse instance, you’ll enable remote access to your database server in the next section.

## Step 7 — Setting Up Firewall Rules (Optional)

If you intend to only use ClickHouse locally with applications running on the same server, or do not have a firewall enabled on your server, you don’t need to complete this section. If instead, you’ll be connecting to the ClickHouse database server remotely, you should follow this step.

Currently your server has a firewall enabled that disables your public IP address accessing all ports. You’ll complete the following two steps to allow remote access:

- Add a firewall rule allowing incoming connections to port `8123`, which is the HTTP port that ClickHouse server runs.

If you are inside the database prompt, exit it by typing `CTRL+D`.

Edit the configuration file by executing:

    sudo vi /etc/clickhouse-server/config.xml

Then uncomment the line containing `<!-- <listen_host>0.0.0.0</listen_host> -->`, like the following file:

/etc/clickhouse-server/config.xml

    
    ...
     <interserver_http_host>example.yandex.ru</interserver_http_host>
        -->
    
        <!-- Listen specified host. use :: (wildcard IPv6 address), if you want to accept connections both with IPv4 and IPv6 from everywhere. -->
        <!-- <listen_host>::</listen_host> -->
        <!-- Same for hosts with disabled ipv6: -->
        <listen_host>0.0.0.0</listen_host>
    
        <!-- Default values - try listen localhost on ipv4 and ipv6: -->
        <!--
        <listen_host>::1</listen_host>
        <listen_host>127.0.0.1</listen_host>
        -->
    ...
    

Save the file and exit `vi`. For the new configuration to apply restart the service by running:

    sudo service clickhouse-server restart

You will see the following output from this command:

    OutputStop clickhouse-server service:
    DONE
    Start clickhouse-server service: Path to data directory in /etc/clickhouse-server/config.xml: /var/lib/clickhouse/
    DONE

Add the remote server’s IP to zone called public:

    sudo firewall-cmd --permanent --zone=public --add-source=second_server_ip/32

ClickHouse’s server listens on port `8123` for HTTP connections and port `9000` for connections from `clickhouse-client`. Allow access to both ports for your second server’s IP address with the following command:

    sudo firewall-cmd --permanent --zone=public --add-port=8123/tcp
    sudo firewall-cmd --permanent --zone=public --add-port=9000/tcp

You will see the following output for both commands that shows that you’ve enabled access to both ports:

    Outputsuccess

Now that you have added the rules, reload the firewall for the changes to take effect:

    sudo firewall-cmd --reload

This command will output a `success` message as well. ClickHouse will now be accessible from the IP that you added. Feel free to add additional IPs such as your local machine’s address if required.

To verify that you can connect to the ClickHouse server from the remote machine, first follow the steps in Step 1 of this tutorial on the second server and ensure that you have the `clickhouse-client` installed on it.

Now that you have logged into the second server, start a client session by executing:

    clickhouse-client --host your_server_ip --multiline

You will see the following output that shows that you have connected successfully to the server:

    OutputClickHouse client version 19.4.3.
    Connecting to your_server_ip:9000 as user default.
    Connected to ClickHouse server version 19.4.3 revision 54416.
    
    hostname :)

In this step, you’ve enabled remote access to your ClickHouse database server by adjusting your firewall rules.

## Conclusion

You have successfully set up a ClickHouse database instance on your server and created a database and table, added data, performed queries, and deleted the database. Within ClickHouse’s documentation you can read about their [benchmarks](https://ClickHouse.yandex/benchmark.html) against other open-source and commercial analytics databases and general reference [documents](https://ClickHouse.yandex/docs/en/). Further [features](https://ClickHouse.yandex/docs/en/introduction/distinctive_features/) ClickHouse offers includes distributed query processing across multiple servers to improve performance and protect against data loss by storing data over different [shards](understanding-database-sharding).
