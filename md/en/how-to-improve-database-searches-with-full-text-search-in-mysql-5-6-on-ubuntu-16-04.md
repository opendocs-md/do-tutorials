---
author: Ilya Kotov
date: 2017-10-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-improve-database-searches-with-full-text-search-in-mysql-5-6-on-ubuntu-16-04
---

# How To Improve Database Searches with Full-Text Search in MySQL 5.6 on Ubuntu 16.04

## Introduction

_Full-text search_, or FTS, is a technique used by search engines to find results in a database. You can use it to power search results on websites like shops, search engines, newspapers, and more.

More specifically, FTS retrieves documents that don’t perfectly match the search criteria. _Documents_ are database entities containing textual data. This means that when a user searches for “cats and dogs”, for example, an application backed by FTS is able to return results which contain the words separately (just “cats” or “dogs”), contain the words in a different order (“dogs and cats”), or contain variants of the words (“cat” or “dog”). This gives applications an advantage in guessing what the user means and returning more relevant results faster.

Technically speaking, database management systems (DBMS) like MySQL usually allow partial text lookups using `LIKE` clauses. However, these requests tend to underperform on large datasets. They’re also limited to matching the user’s input exactly, which means a query might produce no results even if there are documents with relevant information.

Using FTS, you can build a more powerful text search engine without introducing extra dependencies on more advanced tools. In this tutorial, you will use MySQL 5.6 to query a database using full-text search, then quantify the results by their relevance to the search input and display only the best matches.

## Prerequisites

Before you begin this tutorial, you will need:

- One Ubuntu 16.04 server set up by following this [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide, including a sudo non-root user and a firewall.
- MySQL 5.6 or higher installed by following the [How To Install MySQL on Ubuntu 16.04](how-to-install-mysql-on-ubuntu-16-04) guide.

## Step 1 — Creating Test Data

In order to try full-text search, we need some data. In this step, we’ll create a database called `testdb` with a table called `news`, which we’ll populate with some example data representing articles from a fictional news aggregator site.

**Note** : If you have your own table with text data that you’d like to use instead, you can skip to Step 2 and make appropriate substitutions while following along.

First, access the MySQL console. You’ll be prompted to enter the **root** password you set when you installed MySQL.

    mysql -u root -p

Once you’re connected, your prompt will change to `mysql>`.

Next, create a new database called `testdb`. This database will contain the test data.

    CREATE DATABASE testdb;

Switch to using the `testdb` database by default so you won’t have to specify the database’s name to create or update things in it.

    USE testdb;

Next, create a table in the database called `news` with columns for an example news aggregator’s articles.

    CREATE TABLE news (
       id INT NOT NULL AUTO_INCREMENT,
       title TEXT NOT NULL,
       content TEXT NOT NULL,
       author TEXT NOT NULL,
    
       PRIMARY KEY (id)
    );

Let’s walk through what this command does:

- `CREATE TABLE` is a SQL command that creates a table, similar to many other databases.
- `news` is the name of the table.
- `title`, `content` and `author` are textual columns with unlimited length.
- `NOT NULL` is a declaration used to mark the columns that cannot have [null values](https://dev.mysql.com/doc/refman/5.7/en/working-with-null.html) (although they may contain empty strings).
- `id` is the table’s primary index with the special type `AUTO_INCREMENT`, which automatically fills in the ID field with the next available ID.

Now add some example data to the table.

    INSERT INTO news (id, title, content, author) VALUES 
        (1, 'Pacific Northwest high-speed rail line', 'Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.', 'Greg'),
        (2, 'Hitting the beach was voted the best part of life in the region', 'Exploring tracks and trails was second most popular, followed by visiting the shops and then traveling to local parks.', 'Ethan'),
        (3, 'Machine Learning from scratch', 'Bare bones implementations of some of the foundational models and algorithms.', 'Jo');

Let’s walk through what this command does:

- `INSERT` inserts data.
- `INTO` specifies where the data should be inserted. In this case, it’s the `news` table.
- `(id, title, content, author) VALUES` specifies the columns where each entry’s data values should be stored.
- The last three lines are the three rows of data we’re adding to the table. Each contains an example article for a news website with a `title`, some `content`, and the `author`’s name.

Each entry also has a unique `id`entifier which is automatically entered into the database index. The _database index_ is a data structure that improves the performance of data retrieval operations. This index is stored separately from the main data. It updates on any change in the table content at the cost of additional writes and comparatively little storage space. Its small size and tailored data structure allow indexes to operate much more effectively than using the main table space for selecting queries.

Now that we have some data, we can start writing queries to search that data using FTS.

## Step 2 — Creating a FTS Index and Using FTS Functions

Let’s make an index for the text columns we have so we can use FTS.

To do this, we’ll use a MySQL-exclusive command called `FULLTEXT`. This command tells MySQL to put all the fields we want to be able to search with FTS into an internal index.

    ALTER TABLE news ADD FULLTEXT (title, content, author);

This works by combining all of the text columns and sanitizing them (e.g. removing the punctuation and making uppercase letters lowercase). Now that this index is created, it will be updated by any SQL query that changes the content of the source table.

Next, try performing a full-text search for “Seattle beach” using the function `MATCH() AGAINST()`.

    SELECT * FROM news WHERE MATCH (title,content,author) AGAINST ('Seattle beach' IN NATURAL LANGUAGE MODE)\G

The `MATCH()` portion of the command specifies which set of columns are indexed using FTS; it must match the column list you used to create the index. The `AGAINST()` portion specifies which word we’re performing a full-text search for, which is “Seattle beach” in this example.

`IN NATURAL LANGUAGE MODE` means the search words are provided directly from user input without any pre-processing. MySQL assumes natural language mode by default, so you don’t have to specify it explicitly.

**Note:** In comparison to natural language mode, _word stemming_ is another useful FTS technique which makes the index strip the affix of a word, storing only the root portion. For example, the words “fits” and “fitted” would be identical using FTS with word stemming.

Unfortunately, MySQL doesn’t support word stemming. [Stemming is in MySQL’s worklog](https://dev.mysql.com/worklog/task/?id=2423), but there’s no time frame to implement and release it yet. FTS is still useful because it’s still much faster than `LIKE` clauses. If you’d like to use word stemming, you can investigate integrating with the [Snowball library](https://snowballstem.org/).

The `\G` at the end of the query above makes each column in the output print on a new line. This can make long results a little easier to read. The output for the above command will look like this:

    Output ***************************1. row***************************
         id: 1
      title: Pacific Northwest high-speed rail line
    content: Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.
     author: Greg
    ***************************2. row***************************
         id: 2
      title: Hitting the beach was voted the best part of life in the region
    content: Exploring tracks and trails was second most popular, followed by visiting the shops and then traveling to local parks.
     author: Ethan
    2 rows in set (0.00 sec)

None of the entries contained the phrase “Seattle beach”, but because we used full-text search, we still got two results: the first row, which only contains the word “Seattle”, and the second row, which only contains the word “beach”. You can try additional searches by changing the keywords to see the results.

Now that you can use FTS functions in SQL queries to find the rows relevant to a search input, you can make those results more relevant.

## Step 3 — Refining FTS Results

There are two techniques that can help make full-text search results more relevant. One is filtering by the relevance score of the results, and the other is using `IN BOOLEAN` to exclude particular words from results and specify a maximum distance between search terms.

### Using Relevance Score

The _relevance score_ of a result quantifies how good of a match it is for the search term, where 0 is not relevant at all. The relevance score is based off of a number of factors, including how often the term is found in a specific document and how many documents contain the term. [MySQL’s full-text search documentation](https://dev.mysql.com/doc/internals/en/full-text-search.html) goes into the math behind calculating this number.

Get the relevance scores for each row based on the query “traveling to parks”.

    SELECT id, MATCH (title,content,author) AGAINST ('traveling to parks') as score FROM news;

The `as score` portion of this command labels the second column in the output as `score`. Otherwise, it would be labeled with the command used to populate it, which in this case was `MATCH (title,content,author) AGAINST ('traveling to parks')`.

The result will look similar to this:

    Output+----+----------------------+
    | id | score |
    +----+----------------------+
    | 1 | 0.031008131802082062 |
    | 2 | 0.25865283608436584 |
    | 2 | 0 |
    +----+----------------------+
    3 rows in set (0.00 sec)

The third row has a relevance score of 0 because none of the search terms appear in it. The first row contains the word “traveling”, but not “to” or “parks”, and has a very low relevance score of `0.03`. The second row, which contains all the words, has the highest relevance score of `0.25`.

You can use these scores to return the most relevant results first, or to return only the results which are above a certain relevance range. Relevance scores will vary by dataset, so choosing a cutoff point requires manual tuning.

The following command runs the same query, but adds two things:

- It shows only rows with nonzero relevance scores by adding `WHERE MATCH (title,content,author) AGAINST ('traveling to parks') > 0`

- It sorts the results by relevance by adding `ORDER BY score DESC`

    SELECT id, MATCH (title,content,author) AGAINST ('traveling to parks') as score FROM news WHERE MATCH (title,content,author) AGAINST ('traveling to parks') > 0 ORDER BY score DESC;

You need to repeat the `MATCH() AGAINST()` function in the `WHERE` clause because of SQL restrictions on what can be included in that clause.

The output will look like this:

    Output+----+----------------------+
    | id | score |
    +----+----------------------+
    | 2 | 0.25865283608436584 |
    | 1 | 0.031008131802082062 |
    +----+----------------------+
    2 rows in set (0.01 sec)

The most relevant result, row 2, is shown first, followed by the less relevant row 1. Row 3 is not shown at all because its relevance score is 0.

You can change the cutoffs to continue fine-tuning your results. For example, if you use `0.1` instead of `0` as the cutoff, only row 2 will be returned.

### Using IN BOOLEAN

In Step 2, you used the default mode of `IN NATURAL LANGUAGE` when specifying a query term. There’s another mode, `IN BOOLEAN`, which allows you to exclude particular words from a search, define a range of how far away the words in the input must be from one another, and more.

To omit a term from a query, use the minus operator with `IN BOOLEAN`. The following command will return results that contain the word “traveling” but don’t contain the word “Seattle”.

    SELECT * FROM news WHERE MATCH (title,content,author) AGAINST ('traveling -Seattle' IN BOOLEAN MODE)\G

The results will only show row 2:

    Output ***************************1. row***************************
         id: 2
      title: Hitting the beach was voted the best part of life in the region
    content: Exploring tracks and trails was second most popular, followed by visiting the shops and then traveling to local parks.
     author: Ethan
    1 row in set (0.01 sec)

This works because the minus operator tells the DMS to mark any document with the excluded words with a relevance score of 0. Only results with a nonzero relevance score are shown in this mode.

You can also use `IN BOOLEAN MODE` to specify the maximum distance between search terms. This distance is measured in words and, importantly, includes the search terms. For example, the phrase “cats and dogs” has a distance of 3.

The following command returns results in which the words “traveling” and “miles” appear with no more than 2 words between them.

    SELECT * FROM news WHERE MATCH (title,content,author) AGAINST ('"traveling miles" @4' IN BOOLEAN MODE)\G

You’ll see one result, which matched `traveling the 140 miles` in row 2’s `content`.

    Output ***************************1. row***************************
         id: 1
      title: Pacific Northwest high-speed rail line
    content: Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.
     author: Greg
    1 row in set (0.00 sec)

If you change the `@4` to an `@3` in the original command, you’ll see no results.

Limiting your search results by distance between search terms can be helpful when searching against very large documents with diverse vocabularies. The smaller the gap between the query terms, the more accurate the results will be, although fine-tuning the distance will depend on the set of documents you’re working with. For example, a set of scientific papers may work well with a small word gap of 3 , but searching forum posts may perform better with a gap of 8 or higher, depending on how broad or narrow you want the results to be.

## Conclusion

In this guide, you used the full-text search feature in MySQL. You created an index when building a database schema for your document-driven database, then used special operators to find the most relevant results when querying against it.

If you want to explore MySQL’s FTS capabilities further, you can read the [MySQL 5.6 official documentation on full-text search](https://dev.mysql.com/doc/refman/5.6/en/fulltext-search.html).
