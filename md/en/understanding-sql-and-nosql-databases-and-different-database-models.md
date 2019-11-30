---
author: O.S. Tezer
date: 2014-02-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-sql-and-nosql-databases-and-different-database-models
---

# Understanding SQL and NoSQL Databases and Different Database Models

## Introduction

* * *

Since time immemorial, one of the most heavily needed and relied upon functionality of computers has been the memory. Although the technicalities and underlying implementation methods differ, most computers come equipped with necessary hardware to process information and safe-keep them to be used in future whenever necessary.

In today’s world, it is almost impossible to think of any application that does not make use of this ability of machines, whether they be servers, personal computers or hand-held devices. From simple games to business-related tools, including web sites, certain type(s) of data is processed, recorded, and retrieved with each operation.

**Database Management Systems** (DBMS) are the higher-level software, working with lower-level application programming interfaces (APIs), that take care of these operations. To help with solving different kind of problems, for decades new kinds of DBMSs have been developed (e.g. Relational, NoSQL, etc.) along with applications implementing them (e.g. MySQL, PostgreSQL, MongoDB, Redis, etc).

In this DigitalOcean article, we are going to go over the basics of databases and database management systems. We will learn about the logic behind how different databases work and what sets them apart.

## Glossary

* * *

### 1. Database Management Systems

* * *

### 2. Database Models

* * *

1. The Relational Model
2. The Model-less (NoSQL) Approach

### 3. Popular Database Management Systems

* * *

1. Relational Database Management Systems
2. NoSQL (NewSQL) Database Systems

### 4. A Comparison of SQL and No-SQL Database Management Systems

* * *

## Database Management Systems

* * *

Database Management System is an umbrella term that refers to all sorts of completely different tools (i.e. computer programs or embedded libraries), mostly working in different and very unique ways. These applications handle, or heavily assist in handling, dealing with collections of information. Since information (or data) itself can come in various shapes and sizes, dozens of DBMS have been developed, along with tons of DB applications, since the second half of the 21st century to help in solving different programming and computerisation needs.

Database management systems are based on **database models** : structures defined for handling the data. Each emerging DBMS, and applications created to actualise their methods, work in very different ways with regards to definitions and storage-and-retrieval operations of said information.

Although there are a large number of solutions that implement different DBMs, each period in history has seen a relatively small amount of choices rapidly become extremely popular and stay in use for a longer time, with probably the most predominant choice since the past couple of decades (or even longer) being the **Relational Database Management Systems** (RDBMS).

## Database Models

* * *

Each database system implements a different _database model_ to logically structure the data that is being managed. These models are the first step and the biggest determiner of how a database application will work and handle the information it deals with.

There are quite a few different types of database models which clearly and strictly provide the means of structuring the data, with most popular probably being the Relational Model.

Although the relational model and relational databases are extremely powerful and flexible - when the programmer knows how to use them, for many, there have been several issues or features that these solutions never really offered.

Recently, a series of different systems and applications called NoSQL databases started to gain popularity, expeditiously, with their promise of solving these problems and offering some very interesting additional functionality. By eradicating the strictly structured data keeping style defined within the relational model, these DB systems work by offering a much more freely shaped way of working with information, thus providing a great deal of flexibility and ease – despite the fact that they come with their own problems, some serious considering the important and indispensable nature of data.

### The Relational Model

* * *

Introduced in 1970s, the relational model offers a very mathematically-adapt way of structuring, keeping, and using the data. It expands the earlier designs of flat model, network model, et cetera by introducing means of _relations_. Relations bring the benefits of group-keeping the data as constrained collections whereby data-tables, containing the information in a structured way (e.g. a Person’s name and address), relates all the input by assigning values to attributes (e.g. _a_ Person’s ID number).

Thanks to decades of research and development, database systems that implement the relational model work extremely efficiently and reliably. Combined with the long experience of programmers and database administrators working with these tools, using relational database applications has become _the_ choice of mission-critical applications which can not afford loss of any information, in any situation – especially due to glitches or [_gotchas_](http://en.wikipedia.org/wiki/Gotcha_(programming)).

Despite their strict nature of forming and handling data, relational databases can become extremely flexible and offer a lot, granted with a little bit of effort.

### The Model-less (NoSQL) Approach

* * *

The NoSQL way of structuring the data consists of getting rid of these constraints, hence liberating the means of keeping, querying, and using information. NoSQL databases, by using an unstructured (or structured-on-the-go) kind of approach, aim to eliminate the limitations of strict relations, and offer many different types of ways to keep and work with the data for specific use cases efficiently (e.g. full-text document storage).

## Popular Database Management Systems

* * *

In this article, our aim is to introduce you to paradigms of some of the most (and more) popular and commonly used database solutions. Although it is hard to reach a numeric conclusion, it can be clearly estimated that for most, the odds lie between a relational database engine, or, a relatively newer NoSQL one. Before we begin with understanding the differences between different implementations of each one of these systems, let us now see what is under-the-hood.

### Relational Database Management Systems

* * *

Relational Database System takes its name from the model it implements: **The Relational Model** , which we have discussed previously. Currently, and for quite some time to come, they are and they will be the popular choice of keeping data reliably and safe – and they are efficient as well.

Relational database management systems require defined and clearly set schemas - which is not to be confused with PostgreSQL’s specific definition for the term - in order to accept data. These user-defined formats shape how the data is contained and used. Schemas are much like tables with columns, representing the number and the type of information that belongs to each record; and rows represent entries.

Some popular relational database management systems are:

- **SQLite:**  

A very powerful, embedded relational database management system.

- **MySQL:**  

The most popular and commonly used RDBMS.

- **PostgreSQL:**  

The most advanced, SQL-compliant and open-source objective-RDBMS.

**Note:** To learn more about NoSQL database management systems, check out our article on the subject: [A Comparison Of NoSQL Database Management Systems](https://www.digitalocean.com/community/articles/a-comparison-of-nosql-database-management-systems-and-models).

### NoSQL (NewSQL) Database Systems

* * *

NoSQL database systems do not come with a model as used (or needed) with structured relational solutions. There are many implementations with each working very differently and serving a specific need. These schema-less solutions either allow an unlimited forming of entries, or, a rather an opposing, very simple but extremely efficient as useful _key based value stores_.

Unlike traditional relational databases, it is possible to group collections of data together with some NoSQL databases, such as the MongoDB. These _document stores_ keep each data, together, as a single collection (i.e. document) in the database. These documents can be represented as singular data objects, similar to _JSON_ and still be quires depending on attributes.

NoSQL databases do not have a common way to query the data (i.e. similar to SQL of relational databases) and each solution provides its own query system.

**Note:** To learn more about relational database management systems, check out our article on the subject: [A Comparison Of Relational Database Management Systems](https://www.digitalocean.com/community/articles/sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems).

## A Comparison of SQL and No-SQL Database Management Systems

* * *

In order to reach a simpler, understandable conclusion, let us analyse SQL and No-SQL database management systems’ differences:

- **Structure and type of data being kept:**  

SQL/Relational databases require a structure with defined attributes to hold the data, unlike NoSQL databases which usually allow free-flow operations.

- **Querying:**  

Regardless of their licences, relational databases all implement the SQL standard to a certain degree and thus, they can be queried using the Structured Query Language (SQL). NoSQL databases, on the other hand, each implement a unique way to work with the data they manage.

- **Scaling:**  

Both solutions are easy to scale vertically (i.e. by increasing system resources). However, being more modern (and simpler) applications, NoSQL solutions usually offer much easier means to scale horizontally (i.e. by creating a cluster of multiple machines).

- **Reliability:**  

When it comes to data reliability and safe guarantee of performed transactions, SQL databases are still the better bet.

- **Support:**  

Relational database management systems have decades long history. They are extremely popular and it is very easy to find both free and paid support. If an issue arises, it is therefore much easier to solve than recently-popular NoSQL databases – especially if said solution is complex in nature (e.g. MongoDB).

- **Complex data keeping and querying needs:**  

By nature, relational databases are _the_ go-to solution for complex querying and data keeping needs. They are much more efficient and excel in this domain.

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
