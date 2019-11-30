---
author: Mark Drake
date: 2014-02-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/a-comparison-of-nosql-database-management-systems-and-models
---

# A Comparison of NoSQL Database Management Systems and Models

_A previous version of this article was written by [O.S. Tezer](https://www.digitalocean.com/community/users/ostezer)._

## Introduction

When most people think of a database, they often envision the traditional relational database model that involves tables made up of rows and columns. While relational database management systems still handle the lion’s share of data on the internet, alternative data models have become more common in recent years as developers have sought workarounds to the relational model’s limitations. These non-relational database models, each with their own unique advantages, disadvantages, and use cases, have come to be categorized as _NoSQL databases_.

This article will introduce you to a few of the more commonly used NoSQL database models. It will weigh some of their strengths and disadvantages, as well as provide a few examples of database management systems and potential use cases for each.

## Relational Databases and Their Limitations

_Databases_ are logically modeled clusters of information, or _data_. A _database management system_ (DBMS), meanwhile, is a computer program that interacts with a database. A DBMS allows you to control access to a database, write data, run queries, and perform any other tasks related to database management. Although database management systems are often referred to as “databases,” the two terms are not exactly interchangeable. A database can be any collection of data, not just one stored on a computer, while a DBMS is the specific software that allows you to interact with a database.

All database management systems have an underlying model that structures how data is stored and accessed. A _relational database management system_ (RDBMS) is a DBMS that employs the relational data model. In this model, data is organized into tables, which in the context of RDBMSs are more formally referred to as _relations_. Relational database management systems typically employ [_Structured Query Language_ (SQL)](https://en.wikipedia.org/wiki/SQL) for managing and accessing data held within the database.

Historically, the relational model has been the most widely used approach for managing data, and to this day [many of the most popular database management systems implement the relational model](https://db-engines.com/en/ranking). However, the relational model presents several limitations that can be problematic in certain use cases.

For instance, it can be difficult to scale a relational database horizontally. _Horizontal scaling_, or _scaling out_, is the practice of adding more machines to an existing stack in order to spread out the load and allow for more traffic and faster processing. This is often contrasted with _vertical scaling_ which involves upgrading the hardware of an existing server, usually by adding more RAM or CPU.

The reason it’s difficult to scale a relational database horizontally has to do with the fact that the relational model is designed to ensure _consistency_, meaning clients querying the same database will always see the latest data. If you were to scale a relational database horizontally across multiple machines, it becomes difficult to ensure consistency since clients may write data to one node and not the others and there would likely be a delay between the initial write and the time when the other nodes are updated to reflect the changes.

Another limitation presented by RDBMSs is that the relational model was designed to manage _structured data_, or data that aligns with a predefined data type or is at least organized in some predetermined way, making it easily sortable and searchable. With the spread of personal computing and the rise of the internet in the early 1990s, however, _unstructured data_ — such as email messages, photos, videos, etc. — became more common.

As these limitations grew more constricting, developers began looking for alternatives to the traditional relational data model, leading to the growth in popularity of NoSQL databases.

## About NoSQL

The label _NoSQL_ itself has a rather fuzzy definition. “NoSQL” was coined in 1998 by Carlo Strozzi as the name for his then-new [NoSQL Database](http://www.strozzi.it/cgi-bin/CSA/tw7/I/en_US/nosql/Home%20Page), chosen simply because it doesn’t use SQL for managing data.

The term took on a new meaning after 2009 when Johan Oskarsson organized a meetup for developers to discuss the spread of “open source, distributed, and non relational databases” like [Cassandra](http://cassandra.apache.org/) and [Voldemort](https://www.project-voldemort.com/voldemort/). Oskarsson named the meetup “NOSQL” and since then the term has been used as a catch-all for any database that doesn’t employ the relational model. Interestingly, Strozzi’s NoSQL database does in fact employ the relational model, meaning that the original NoSQL database doesn’t fit the contemporary definition of NoSQL.

Because “NoSQL” generally refers to any DBMS that doesn’t employ the relational model, there are several operational data models associated with the NoSQL concept. The following table includes several such data models, but please note that this is not a comprehensive list:

| Operational Database Model | Example DBMSs |
| --- | --- |
| Key-value store | Redis, MemcacheDB |
| Columnar database | Cassandra, Apache HBase |
| Document store | MongoDB, Couchbase |
| Graph database | OrientDB, Neo4j |

Despite these different underlying data models, most NoSQL databases share several characteristics. For one, NoSQL databases are typically designed to maximize availability at the expense of consistency. In this sense, consistency refers to the idea that any read operation will return the most recent data written to the database. In a distributed database designed for strong consistency, any data written to one node will be immediately available on all other nodes; otherwise, an error will occur.

Conversely, NoSQL databases oftentimes aim for _eventual consistency_. This means that newly written data is made available on other nodes in the database eventually (usually in a matter of a few milliseconds), though not necessarily immediately. This has the benefit of improving the availability of one’s data: even though you may not see the very latest data written, you can still view an earlier version of it instead of receiving an error.

Relational databases are designed to deal with normalized data that fits neatly into a predefined schema. In the context of a DBMS, _normalized data_ is data that’s been organized in a way to eliminate redundancies — meaning that the database takes up as little storage space as possible — while a _schema_ is an outline of how the data in the database is structured.

While NoSQL databases are equipped to handle normalized data and they are able to sort data within a predefined schema, their respective data models usually allow for far greater flexibility than the rigid structure imposed by relational databases. Because of this, NoSQL databases have a reputation for being a better choice for storing semi-structured and unstructured data. With that in mind, though, because NoSQL databases don’t come with a predefined schema that often means it’s up to the database administrator to define how the data should be organized and accessed in whatever way makes the most sense for their application.

Now that you have some context around what NoSQL databases are and what makes them different from relational databases, let’s take a closer look at some of the more widely-implemented NoSQL database models.

## Key-value Databases

_Key-value databases_, also known as _key-value stores_, work by storing and managing _associative arrays_. An associative array, also known as a _dictionary_ or _hash table_, consists of a collection of key-value pairs in which a key serves as a unique identifier to retrieve an associated value. Values can be anything from simple objects, like integers or strings, to more complex objects, like JSON structures.

In contrast to relational databases, which define a data structure made up of tables of rows and columns with predefined data types, key-value databases store data as a single collection without any structure or relation. After connecting to the database server, an application can define a key (for example, `the_meaning_of_life`) and provide a matching value (for example, `42`) which can later be retrieved the same way by supplying the key. A key-value database treats any data held within it as an opaque blob; it’s up to the application to understand how it’s structured.

Key-value databases are often described as highly performant, efficient, and scalable. Common use cases for key-value databases are [caching](https://en.wikipedia.org/wiki/Cache_(computing)), [message queuing](https://en.wikipedia.org/wiki/Message_queue), and [session management](https://en.wikipedia.org/wiki/Session_(computer_science)).

Some popular open-source key-value data stores are:

| Database | Description |
| --- | --- |
| [Redis](https://redis.io/) | An in-memory data store used as a database, cache, or message broker, Redis supports a variety of data structures, ranging from strings to bitmaps, streams, and spatial indexes. |
| [Memcached](https://memcached.org/) | A general-purpose memory object caching system frequently used to speed up data-driven websites and applications by caching data and objects in memory. |
| [Riak](https://riak.com/products/riak-kv/index.html) | A distributed key-value database with advanced local and multi-cluster replication. |

## Columnar Databases

_Columnar databases_, sometimes called _column-oriented databases_, are database systems that store data in columns. This may seem similar to traditional relational databases, but rather than grouping columns together into tables, each column is stored in a separate file or region in the system’s storage.

The data stored in a columnar database appears in record order, meaning that the first entry in one column is related to the first entry in other columns. This design allows queries to only read the columns they need, rather than having to read every row in a table and discard unneeded data after it’s been stored in memory.

Because the data in each column is of the same type, it allows for various storage and read optimization strategies. In particular, many columnar database administrators implement a compression strategy such as [run-length encoding](https://en.wikipedia.org/wiki/Run-length_encoding) to minimize the amount of space taken up by a single column. This can have the benefit of speeding up reads since queries need to go over fewer rows. One drawback with columnar databases, though, is that load performance tends to be slow since each column must be written separately and data is often kept compressed. Incremental loads in particular, as well as reads of individual records, can be costly in terms of performance.

Column-oriented databases have been around since the 1960s. Since the mid-2000s, though, columnar databases have become more widely used for data analytics since the columnar data model lends itself well to fast query processing. They’re also seen as advantageous in cases where an application needs to frequently perform [aggregate functions](https://en.wikipedia.org/wiki/Aggregate_function), such as finding the average or sum total of data in a column. Some columnar database management systems are even capable of using SQL queries.

Some popular open-source columnar databases are:

| Database | Description |
| --- | --- |
| [Apache Cassandra](https://cassandra.apache.org) | A column store designed to maximize scalability, availability, and performance. |
| [Apache HBase](https://hbase.apache.org/) | A distributed database that supports structured storage for large amounts of data and is designed to work with the [Hadoop software library](https://hadoop.apache.org/). |
| [ClickHouse](https://clickhouse.yandex/) | A fault tolerant DBMS that supports real time generation of analytical data and SQL queries. |

## Document-oriented Databases

_Document-oriented databases_, or _document stores_, are NoSQL databases that store data in the form of documents. Document stores are a type of [key-value store](a-comparison-of-nosql-database-management-systems-and-models#key-value-databases): each document has a unique identifier — its key — and the document itself serves as the value.

The difference between these two models is that, in a key-value database, the data is treated as opaque and the database doesn’t know or care about the data held within it; it’s up to the application to understand what data is stored. In a document store, however, each document contains some kind of metadata that provides a degree of structure to the data. Document stores often come with an API or query language that allows users to retrieve documents based on the metadata they contain. They also allow for complex data structures, as you can nest documents within other documents.

Unlike relational databases, in which the information of a given object may be spread across multiple tables or databases, a document-oriented database can store all the data of a given object in a single document. Document stores typically store data as [JSON](https://en.wikipedia.org/wiki/JSON), [BSON](https://en.wikipedia.org/wiki/BSON), [XML](https://en.wikipedia.org/wiki/XML), or [YAML](https://en.wikipedia.org/wiki/YAML) documents, and some can store binary formats like PDF documents. Some use a variant of SQL, full-text search, or their own native query language for data retrieval, and others feature more than one query method.

Document-oriented databases have seen an enormous growth in popularity in recent years. Thanks to their flexible schema, they’ve found regular use in e-commerce, blogging, and analytics platforms, as well as content management systems. Document stores are considered highly scalable, with [sharding](understanding-database-sharding) being a common horizontal scaling strategy. They are also excellent for keeping large amounts of unrelated, complex information that varies in structure.

Some popular open-source document based data stores are:

| Database | Description |
| --- | --- |
| [MongoDB](https://www.mongodb.com/) | A general purpose, distributed document store, MongoDB is the [world’s most widely used document-oriented database](https://db-engines.com/en/ranking/document+store) at the time of this writing. |
| [Couchbase](https://www.couchbase.com/) | Originally known as Membase, a JSON-based, Memcached-compatible document-based data store. A _multi-model_ database, Couchbase can also function as a key-value store. |
| [Apache CouchDB](https://couchdb.apache.org/) | A project of the Apache Software Foundation, CouchDB stores data as JSON documents and uses JavaScript as its query language. |

## Graph Databases

_Graph databases_ can be thought of as a subcategory of the document store model, in that they store data in documents and don’t insist that data adhere to a predefined schema. The difference, though, is that graph databases add an extra layer to the document model by highlighting the relationships between individual documents.

To better grasp the concept of graph databases, it’s important to understand the following terms:

- **Node** : A _node_ is a representation of an individual entity tracked by a graph database. It is more or less equivalent to the concept of a _record_ or _row_ in a relational database or a _document_ in a document store. For example, in a graph database of music recording artists, a node might represent a single performer or band.
- **Property** : A _property_ is relevant information related to individual nodes. Building on our recording artist example, some properties might be “vocalist,” “jazz,” or “platinum-selling artist,” depending on what information is relevant to the database. 
- **Edge** : Also known as a _graph_ or _relationship_, an _edge_ is the representation of how two nodes are related, and is a key concept of graph databases that differentiates them from RDBMSs and document stores. Edges can be _directed_ or _undirected_. 
  - **Undirected** : In an undirected graph, the edges between nodes exist just to show a connection between them. In this case, edges can be thought of as “two-way” relationships — there’s no implied difference between how one node relates to the other.
  - **Directed** : In a directed graph, edges can have different meanings based on which direction the relationship originates from. In this case, edges are “one-way” relationships. For example, a directed graph database might specify a relationship from Sammy to the Seaweeds showing that Sammy produced an album for the group, but might not show an equivalent relationship from The Seaweeds to Sammy.

Certain operations are much simpler to perform using graph databases because of how they link and group related pieces of information. These databases are commonly used in cases where it’s important to be able to gain insights from the relationships between data points or in applications where the information available to end users is determined by their connections to others, as in a social network. They’ve found regular use in fraud detection, recommendation engines, and identity and access management applications.

Some popular open-source graph databases are:

| Database | Description |
| --- | --- |
| [Neo4j](https://neo4j.com/) | An [ACID](https://en.wikipedia.org/wiki/ACID)-compliant DBMS with native graph storage and processing. As of this writing, Neo4j is [the most popular graph database in the world](https://db-engines.com/en/ranking/graph+dbms). |
| [ArangoDB](https://www.arangodb.com/) | Not exclusively a graph database, ArangoDB is a multi-model database that unites the graph, document, and key-value data models in one DBMS. It features AQL (a native SQL-like query language), full-text search, and a ranking engine. |
| [OrientDB](https://orientdb.com) | Another multi-model database, OrientDB supports the graph, document, key-value, and object models. It supports SQL queries and ACID transactions. |

## Conclusion

In this tutorial, we’ve gone over only a few of the NoSQL data models in use today. Some NoSQL models, such as [object stores](https://en.wikipedia.org/wiki/Object_database), have seen varying levels of use over the years but remain as viable alternatives to the relational model in some use cases. Others, like [object-relational databases](https://en.wikipedia.org/wiki/Object-relational_database) and [time-series databases](https://en.wikipedia.org/wiki/Time_series_database), blend elements of relational and NoSQL data models to form a kind of middle ground between the two ends of the spectrum.

The NoSQL category of databases is extremely broad, and continues to evolve to this day. If you’re interested in learning more about NoSQL database management systems and concepts, we encourage you to check out our [library of NoSQL-related content](https://www.digitalocean.com/community/tags/nosql?type=tutorials).
