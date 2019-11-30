---
author: coreh
date: 2018-08-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-logical-replication-with-postgresql-10-on-ubuntu-18-04
---

# How To Set Up Logical Replication with PostgreSQL 10 on Ubuntu 18.04

## Introduction

When setting up an application for production, it’s often useful to have multiple copies of your database in place. The process of keeping database copies in sync is called _replication_. Replication can provide high-availability horizontal scaling for high volumes of simultaneous read operations, along with reduced read latencies. It also allows for peer-to-peer replication between geographically distributed database servers.

[PostgreSQL](https://www.postgresql.org/) is an open-source object-relational database system that is highly extensible and compliant with [_ACID_](https://en.wikipedia.org/wiki/ACID_(computer_science)) (Atomicity, Consistency, Isolation, Durability) and the SQL standard. Version 10.0 of PostgreSQL introduced support for _logical replication_, in addition to _physical replication_. In a logical replication scheme, high-level write operations are streamed from a _master_ database server into one or more _replica_ database servers. In a physical replication scheme, binary write operations are instead streamed from master to replica, producing a byte-for-byte exact copy of the original content. In cases where you would like to target a particular subset of data, such as off-load reporting, patching, or upgrading, logical replication can offer speed and flexibility.

In this tutorial, you will configure logical replication with PostgreSQL 10 on two Ubuntu 18.04 servers, with one server acting as the master and the other as the replica. By the end of the tutorial you will be able to replicate data from the master server to the replica using logical replication.

## Prerequisites

To follow this tutorial, you will need:

- Two Ubuntu 18.04 servers, which we’ll name **db-master** and **db-replica** , each set up with a regular user account and sudo privileges. To set these up, follow [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04). 
- [Private networking enabled](https://www.digitalocean.com/docs/networking/private-networking/quickstart/) on your servers. Private networking allows for communication between your servers without the security risks associated with exposing databases to the public internet.
- PostgreSQL 10 installed on both servers, following Step 1 of [How To Install and Use PostgreSQL on Ubuntu 18.04](how-to-install-and-use-postgresql-on-ubuntu-18-04). 

## Step 1 — Configuring PostgreSQL for Logical Replication

There are several configuration settings you will need to modify to enable logical replication between your servers. First, you’ll configure Postgres to listen on the private network interface instead of the public one, as exposing data over the public network is a security risk. Then you’ll configure the appropriate settings to allow replication to **db-replica**.

On **db-master** , open `/etc/postgresql/10/main/postgresql.conf`, the main server configuration file:

    sudo nano /etc/postgresql/10/main/postgresql.conf

Find the following line:

/etc/postgresql/10/main/postgresql.conf

    ...
    #listen_addresses = 'localhost' # what IP address(es) to listen on;
    ...

Uncomment it by removing the `#`, and add your `db_master_private_ip_address` to enable connections on the private network:

**Note:** In this step and the steps that follow, make sure to use the **private** IP addresses of your servers, and not their public IPs. Exposing a database server to the public internet is a considerable security risk.

/etc/postgresql/10/main/postgresql.conf

    ...
    listen_addresses = 'localhost, db_master_private_ip_address'
    ...

This makes **db-master** listen for incoming connections on the private network in addition to the loopback interface.

Next, find the following line:

/etc/postgresql/10/main/postgresql.conf

    ...
    #wal_level = replica # minimal, replica, or logical
    ...

Uncomment it, and change it to set the PostgreSQL [_Write Ahead Log_](https://www.postgresql.org/docs/current/static/wal-intro.html) (WAL) level to `logical`. This increases the volume of entries in the log, adding the necessary information for extracting discrepancies or changes to particular data sets:

/etc/postgresql/10/main/postgresql.conf

    ...
    wal_level = logical
    ...

The entries on this log will be consumed by the replica server, allowing for the replication of the high-level write operations from the master.

Save the file and close it.

Next, let’s edit `/etc/postgresql/10/main/pg_hba.conf`, the file that controls allowed hosts, authentication, and access to databases:

    sudo nano /etc/postgresql/10/main/pg_hba.conf

After the last line, let’s add a line to allow incoming network connections from **db-replica**. We’ll use **db-replica** ’s private IP address, and specify that connections are allowed from all users and databases:

/etc/postgresql/10/main/pg\_hba.conf

    ...
    # TYPE DATABASE USER ADDRESS METHOD
    ...
    host all all db_replica_private_ip_address/32 md5

Incoming network connections will now be allowed from **db-replica** , authenticated by a password hash [(md5)](https://en.wikipedia.org/wiki/MD5).

Save the file and close it.

Next, let’s set our firewall rules to allow traffic from **db-replica** to port `5432` on **db-master** :

    sudo ufw allow from db_replica_private_ip_address to any port 5432

Finally, restart the PostgreSQL server for the changes to take effect:

    sudo systemctl restart postgresql 

With your configuration set to allow logical replication, you can now move on to creating a database, user role, and table.

## Step 2 — Setting Up a Database, User Role, and Table

To test the functionality of your replication settings, let’s create a database, table, and user role. You will create an `example` database with a sample table, which you can then use to test logical replication between your servers. You will also create a dedicated user and assign them privileges over both the database and the table.

First, open the [`psql` prompt](how-to-install-and-use-postgresql-on-ubuntu-18-04#using-postgresql-roles-and-databases) as the **postgres** user with the following command on both **db-master** and **db-replica** :

    sudo -u postgres psql

    sudo -u postgres psql

Create a new database called `example` on both hosts:

    CREATE DATABASE example;

    CREATE DATABASE example;

**Note:** The final `;` in these commands is required. On interactive sessions, PostgreSQL will not execute SQL commands until you terminate them with a semicolon. Meta-commands (those starting with a backslash, like `\q` and `\c`) directly control the psql client itself, and are therefore exempt from this rule. For more on meta-commands and the psql client, please refer to the [PostgreSQL documentation](https://www.postgresql.org/docs/current/static/app-psql.html).

Using the `\connect` meta-command, connect to the databases you just created on each host:

    \c example

    \c example

Create a new table called `widgets` with arbitrary fields on both hosts:

    CREATE TABLE widgets
    (
        id SERIAL,
        name TEXT,
        price DECIMAL,
        CONSTRAINT widgets_pkey PRIMARY KEY (id)
    );

    CREATE TABLE widgets
    (
        id SERIAL,
        name TEXT,
        price DECIMAL,
        CONSTRAINT widgets_pkey PRIMARY KEY (id)
    );

The table on **db-replica** does not need to be identical to its **db-master** counterpart. However, it must contain every single column present on the table at **db-master**. Additional columns must not have `NOT NULL` or other constraints. If they do, replication will fail.

On **db-master** , let’s create a new user role with the `REPLICATION` option and a login password. The `REPLICATION` attribute must be assigned to any role used for replication. We will call our user `sammy`, but you can replace this with your own username. Make sure to also replace `my_password` with your own secure password:

    CREATE ROLE sammy WITH REPLICATION LOGIN PASSWORD 'my_password';

Make a note of your password, as you will use it later on **db-replica** to set up replication.

Still on **db-master** , grant full privileges on the `example` database to the user role you just created:

    GRANT ALL PRIVILEGES ON DATABASE example TO sammy;

Next, grant privileges on all of the tables contained in the database to your user:

    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO sammy;

The [`public` schema](https://www.postgresql.org/docs/current/static/ddl-schemas.html) is a default schema in each database into which tables are automatically placed.

With these privileges set, you can now move on to making the tables in your `example` database available for replication.

## Step 3 — Setting Up a Publication

_Publications_ are the mechanism that PostgreSQL uses to make tables available for replication. The database server will keep track internally of the connection and replication status of any replica servers associated with a given publication. On **db-master** , you will create a publication, `my_publication`, that will function as a master copy of the data that will be sent to your _subscribers_ — in our case, **db-replica**.

On **db-master** , create a publication called `my_publication`:

    CREATE PUBLICATION my_publication;

Add the `widgets` table you created previously to it:

    ALTER PUBLICATION my_publication ADD TABLE widgets;

With your publication in place, you can now add a subscriber that will pull data from it.

## Step 4 — Creating a Subscription

_Subscriptions_ are used by PostgreSQL to connect to existing publications. A publication can have many subscriptions across different replica servers, and replica servers can also have their own publications with subscribers. To access the data from the table you created on **db-master** , you will need to create a subscription to the publication you created in the previous step, `my_publication`.

On **db-replica** , let’s create a subscription called `my_subscription`. The `CREATE SUBSCRIPTION` command will name the subscription, while the `CONNECTION` parameter will define the connection string to the publisher. This string will include the master server’s connection details and login credentials, including the username and password you defined earlier, along with the name of the `example` database. Once again, remember to use **db-master** ’s private IP address, and replace `my_password` with your own password:

    CREATE SUBSCRIPTION my_subscription CONNECTION 'host=db_master_private_ip_address port=5432 password=my_password user=sammy dbname=example' PUBLICATION my_publication;

You will see the following output confirming the subscription:

    OutputNOTICE: created replication slot "my_subscription" on publisher
    CREATE SUBSCRIPTION

Upon creating a subscription, PostgreSQL will automatically sync any pre-existing data from the master to the replica. In our case there is no data to sync since the `widgets` table is empty, but this is a useful feature when adding new subscriptions to an existing database.

With a subscription in place, let’s test the setup by adding some demo data to the `widgets` table.

## Step 5 — Testing and Troubleshooting

To test replication between our master and replica, let’s add some data to the `widgets` table and verify that it replicates correctly.

On **db-master** , insert the following data on the `widgets` table:

    INSERT INTO widgets (name, price) VALUES ('Hammer', 4.50), ('Coffee Mug', 6.20), ('Cupholder', 3.80);

On **db-replica** , run the following query to fetch all the entries on this table:

    SELECT * FROM widgets;

You should now see:

    Output id | name | price 
    ----+------------+-------
      1 | Hammer | 4.50
      2 | Coffee Mug | 6.20
      3 | Cupholder | 3.80
    (3 rows)

Success! The entries have been successfully replicated from **db-master** to **db-replica**. From now on, all `INSERT`, `UPDATE`, and `DELETE` queries will be replicated across servers unidirectionally.

One thing to note about write queries on replica servers is that they are not replicated back to the master server. PostgreSQL currently has limited support for resolving conflicts when the data between servers diverges. If there is a conflict, the replication will stop and PostgreSQL will wait until the issue is manually fixed by the database administrator. For that reason, most applications will direct all write operations to the master server, and distribute reads among available replica servers.

You can now exit the `psql` prompt on both servers:

    \q

    \q

Now that you have finished testing your setup, you can add and replicate data on your own.

## Troubleshooting

If replication doesn’t seem to be working, a good first step is checking the PostgreSQL log on **db-replica** for any possible errors:

    tail /var/log/postgresql/postgresql-10-main.log

Here are some common problems that can prevent replication from working:

- Private networking is not enabled on both servers, or the servers are on different networks;
- **db-master** is not configured to listen for connections on the correct private network IP;
- The Write Ahead Log level on **db-master** is incorrectly configured (it must be set to `logical`);
- **db-master** is not configured to accept incoming connections from the correct **db-replica** private IP address;
- A firewall like UFW is blocking incoming PostgreSQL connections on port `5432`;
- There are mismatched table names or fields between **db-master** and **db-replica** ;
- The `sammy` database role is missing the required permissions to access the `example` database on **db-master** ;
- The `sammy` database role is missing the `REPLICATION` option on **db-master** ;
- The `sammy` database role is missing the required permissions to access the `widgets` table on **db-master** ;
- The table wasn’t added to the publication on **db-master**.

After resolving the existing problem(s), replication should take place automatically. If it doesn’t, use following command to remove the existing subscription before recreating it:

    DROP SUBSCRIPTION my_subscription;

## Conclusion

In this tutorial you’ve successfully installed PostgreSQL 10 on two Ubuntu 18.04 servers and configured logical replication between them.

You now have the required knowledge to experiment with horizontal read scaling, high availability, and the geographical distribution of your PostgreSQL database by adding additional replica servers.

To learn more about logical replication in PostgreSQL 10, you can read the [chapter on the topic](https://www.postgresql.org/docs/10/static/logical-replication.html) on the official PostgreSQL documentation, as well as the manual entries on the [`CREATE PUBLICATION`](https://www.postgresql.org/docs/10/static/sql-createpublication.html) and [`CREATE SUBSCRIPTION`](https://www.postgresql.org/docs/10/static/sql-createsubscription.html) commands.
