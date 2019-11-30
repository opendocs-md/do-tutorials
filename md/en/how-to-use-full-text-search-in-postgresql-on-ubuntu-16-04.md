---
author: Ilya Kotov
date: 2017-06-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-full-text-search-in-postgresql-on-ubuntu-16-04
---

# How to Use Full-Text Search in PostgreSQL on Ubuntu 16.04

## Introduction

_Full-text search_ (FTS) is a technique used by search engines to find results in a database. It can be used to power search results on websites like shops, search engines, newspapers, and more.

More specifically, FTS retrieves _documents_, which are database entities containing textual data, that don’t perfectly match the search criteria. This means that when a user searches for “cats and dogs”, for example, an application backed by FTS is able to return results which contain the words separately (just “cats” or “dogs”), contain the words in a different order (“dogs and cats”), or contain variants of the words (“cat” or “dog”). This gives applications an advantage in guessing what the user means and returning more relevant results faster.

Technically speaking, database management systems (DBMS) like PostgreSQL usually allow partial text lookups using LIKE clauses. However, these requests tend to underperform on large datasets. They’re also limited to matching the exact user’s input, which means a query might produce no results, even if there are documents with relevant information.

Using FTS, you can build a more powerful text search engine without introducing extra dependencies on more advanced tools. In this tutorial, we’ll use PostgreSQL to store data containing articles for a hypothetical news website, then learn how to query the database using FTS and select only the best matches. As the final step, we will implement some performance improvements for full-text search queries.

## Prerequisites

Before you begin this guide, you’ll need the following:

- One Ubuntu 16.04 server set up by following this [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide, including a sudo non-root user.
- PostgreSQL installed by following the [How To Install and Use PostgreSQL on Ubuntu 16.04](how-to-install-and-use-postgresql-on-ubuntu-16-04) guide. In this tutorial, we will use the `sammy` database and user set up in that guide.

If you set up a PostgreSQL server without following the above tutorial, make sure you have the `postgresql-contrib` package using `sudo apt-get list postgresql-contrib`.

## Step 1 — Creating Example Data

To start, we’ll need to have some data to test the full-text search plugin with, so let’s create some example data. If you have your own table with text values already, you can skip to Step 2 and make appropriate substitutions while following along.

Otherwise, the first step is to connect to the PostgreSQL database from its server. Because you are connecting from the same host, by default, you will not need to enter your password.

    sudo -u postgres psql sammy

This will establish an interactive PostgreSQL session indicating the database name you are operating on, which in our case is `sammy`. You should see a `sammy=#` database command prompt.

Next, create an example table in the database called `news`. Each entry in this table will represent a news article with a title, some content, and the author’s name along with a unique identifier.

    CREATE TABLE news (
       id SERIAL PRIMARY KEY,
       title TEXT NOT NULL,
       content TEXT NOT NULL,
       author TEXT NOT NULL
    );

`id` is the table’s primary index with the special type `SERIAL`, which creates an auto-increment counter for the table. This is a unique identifier which automatically goes to the database index. We’ll talk more about this index in Step 3 when we look at performance improvements.

Next, add some example data to the table using the `INSERT` command. This example data in the command below represents some sample news articles.

    INSERT INTO news (id, title, content, author) VALUES 
        (1, 'Pacific Northwest high-speed rail line', 'Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.', 'Greg'),
        (2, 'Hitting the beach was voted the best part of life in the region', 'Exploring tracks and trails was second most popular, followed by visiting the shops and then checking out local parks.', 'Ethan'),
        (3, 'Machine Learning from scratch', 'Bare bones implementations of some of the foundational models and algorithms.', 'Jo');

Now that the database has some data to search for, we can try writing some queries.

## Step 2 — Preparing and Searching Documents

The first step here is building one document with multiple text columns from the database table. Then, we can transform the resulting string into a vector of words, which is what we’ll use in the queries.

**Note:** In this guide, the `psql` output uses `expanded display` formatting which displays each column from the output on a new line making it easier to fit long text on the screen. You can enable it like this:

    \x

    OutputExpanded display is on.

First, we’ll need to put all the columns together using the PostgreSQL concatenate function `||` and transform function `to_tsvector()`.

    SELECT title || '. ' || content as document, to_tsvector(title || '. ' || content) as metadata FROM news WHERE id = 1;

This returns the first record as a whole document, as well as its transformed version to be used for searching.

    Output-[RECORD 1]-----------------------------------------------------
    document | Pacific Northwest high-speed rail line. Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.
    
    metadata | '140':18 'current':8 'high':4 'high-spe':3 'ideal':29 'line':7 'mile':19 'none':25 'northwest':2 'option':14 'pacif':1 'rail':6 'seattl':21 'speed':5 'travel':16 'vancouv':23

You may notice that there are fewer words in the transformed version, `metadata` in the output above, than in the original `document`. Some of the words are different and every word has a semicolon and a number appended to it. This is because the function `to_tsvector()` normalizes each word to allow to us to find variant forms of the same word, then sorts the result alphabetically. The number is the word’s position in the `document`. There may be additional comma-separated positions if the normalized word appears more than once.

Now we can use this converted document to take advantage of the FTS capabilities by searching for the term “Explorations”.

    SELECT * FROM news WHERE to_tsvector(title || '. ' || content) @@ to_tsquery('Explorations');

Let’s examine the functions and operators we used here.

The function `to_tsquery()` translates the parameter, which could be a direct or slightly adjusted user search, to a text search criteria which will reduce the input in the same way that `to_tsvector()` does. Additionally, the function lets you specify the language to use and whether all the words have to be present in the result or just one of them.

The `@@` operator identifies if the `tsvector` matches the `tsquery` or another `tsvector`. It returns `true` or `false`, which makes it easy to use as part of `WHERE` criteria.

    Output-[RECORD 1]-----------------------------------------------------
    id | 2
    title | Hitting the beach was voted the best part of life in the region
    content | Exploring tracks and trails was second most popular, followed by visiting the shops and then checking out local parks.
    author | Ethan

The query returned the document which contains the word “Exploring”, even though the word we were using for the search was “Explorations”. Using a `LIKE` operator instead of FTS here would have yielded an empty result.

Now that we know how to prepare documents for FTS and how to structure queries, let’s look at ways to improve FTS’s performance.

## Step 3 — Improving FTS Performance

Generating a document every time we use a FTS query can become a performance issue when using large datasets or smaller servers. One good solution to this, which we’ll implement here, is to generate the transformed document when inserting the row and store it along with the other data. This way, we can just retrieve it with a query instead of having to generate it every time.

First, create an extra column called `document` to the existing `news` table.

    ALTER TABLE news ADD "document" tsvector;

We’ll now need to use a different query to insert data into the table. Unlike Step 2, here we’ll also need to prepare the transformed document and add it into the new `document` column, like this:

    INSERT INTO news (id, title, content, author, document)
    VALUES (4, 'Sleep deprivation curing depression', 'Clinicians have long known that there is a strong link between sleep, sunlight and mood.', 'Patel', to_tsvector('Sleep deprivation curing depression' || '. ' || 'Clinicians have long known that there is a strong link between sleep, sunlight and mood.'));

Adding a new column to the existing table requires us to add empty values for the `document` column at first. Now we need to update it with the generated values.

Use the `UPDATE` command to add the missing data.

    UPDATE news SET document = to_tsvector(title || '. ' || content) WHERE document IS NULL;

Adding these rows to our table is a good performance improvement, but in large datasets, we may still have issues because the database will still have to scan the entire table to find the rows matching the search criteria. An easy solution to this is to use indexes.

The _database index_ is a data structure that stores data separately from the main data that enhances the performance of data retrieval operations. It updates after any changes in the table content at the cost of additional writes and comparatively little storage space. Its small size and tailored data structure allow indexes to operate much more effectively than using the main table space for selecting queries.

Ultimately, indexes help the database find rows faster by searching using special data structures and algorithms. PostgreSQL has [several types of indexes](https://www.postgresql.org/docs/9.1/static/indexes-types.html) which are suited to particular types of queries. The most relevant ones for this use case are GiST indexes and GIN indexes. The main difference between them is how fast they can retrieve documents from the table. GIN is slower to build when adding new data, but faster to query; GIST builds faster, but requires additional data reads.

Because GiST is about 3 times slower to retrieve data than GIN, we’ll create a GIN index here.

    CREATE INDEX idx_fts_search ON news USING gin(document);

Using the indexed `document` column, our `SELECT` query has also become a bit more simple.

    SELECT title, content FROM news WHERE document @@ to_tsquery('Travel | Cure');

The output will look like this:

    Output-[RECORD 1]-----------------------------------------------------
    title | Sleep deprivation curing depression
    content | Clinicians have long known that there is a strong link between sleep, sunlight and mood.
    -[RECORD 2]-----------------------------------------------------
    title | Pacific Northwest high-speed rail line
    content | Currently there are only a few options for traveling the 140 miles between Seattle and Vancouver and none of them are ideal.

When you’re done, you can exit the database console with `\q`.

## Conclusion

This guide covered how to use full-text search in PostgreSQL, including preparing and storing the metadata document and using an index to improve performance. If you want to learn more about FTS in PostgreSQL, take a look at the [official PostgreSQL documentation on full-text search](https://www.postgresql.org/docs/9.5/static/textsearch-intro.html).
