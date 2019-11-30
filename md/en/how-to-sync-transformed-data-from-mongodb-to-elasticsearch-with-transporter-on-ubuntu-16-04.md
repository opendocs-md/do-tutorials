---
author: Mandeep Singh Gulati
date: 2018-04-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-sync-transformed-data-from-mongodb-to-elasticsearch-with-transporter-on-ubuntu-16-04
---

# How To Sync Transformed Data from MongoDB to Elasticsearch with Transporter on Ubuntu 16.04

## Introduction

Transporter is an open-source tool for moving data across different data stores. Developers often write one-off scripts for tasks like moving data across databases, moving data from files to a database, or vice versa, but using a tool like Transporter has several advantages.

In Transporter, you build _pipelines_, which define the flow of data from a _source_ (where the data is read) to a _sink_ (where the data is written). Sources and sinks can be SQL or NoSQL databases, flat files, or other resources. Transporter uses _adaptors_, which are pluggable extensions, to communicate with these resources and the project includes [several adaptors](https://github.com/compose/transporter#adaptors) for popular databases by default.

In addition to moving data, Transporter also allows you to change data as it moves through a pipeline using a _transformer_. Like adaptors, there are [several transformers](https://github.com/compose/transporter/wiki/Transformers) included by default. You can also write your own transformers to customize the modification of your data.

In this tutorial, we’ll walk through an example of moving and processing data from a MongoDB database to Elasticsearch using Transporter’s built-in adaptors and a custom transformer written in JavaScript.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [this Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- MongoDB installed by following [this MongoDB on Ubuntu 16.04 tutorial](how-to-install-mongodb-on-ubuntu-16-04), or an existing MongoDB installation.
- Elasticsearch installed by following [this Elasticsearch on Ubuntu 16.04 tutorial](how-to-install-and-configure-elasticsearch-on-ubuntu-16-04), or an existing Elasticsearch installation.

Transporter pipelines are written in JavaScript. You won’t need any prior JavaScript knowledge or experience to follow along with this tutorial, but you can learn more in [these JavaScript tutorials](https://www.digitalocean.com/community/tags/javascript?type=tutorials).

## Step 1 — Installing Transporter

Transporter provides binaries for most common operating systems. The installation process for Ubuntu involves two steps: downloading the Linux binary and making it executable.

First, get the link for the latest version from [Transporter’s latest releases page on GitHub](https://github.com/compose/transporter/releases/latest). Copy the link that ends with `-linux-amd64`. This tutorial uses v0.5.2, which is the most recent at time of writing.

Download the binary into your home directory.

    cd
    wget https://github.com/compose/transporter/releases/download/v0.5.2/transporter-0.5.2-linux-amd64

[Move it into `/usr/local/bin`](http://do.co/techguide#preferred-installation-locations) or your preferred installation directory.

    mv transporter-*-linux-amd64 /usr/local/bin/transporter

Then make it executable so you can run it.

    chmod +x /usr/local/bin/transporter

You can test that Transporter is set up correctly by running the binary.

    transporter

You’ll see the usage help output and the version number:

    OutputUSAGE
      transporter <command> [flags]
    
    COMMANDS
      run run pipeline loaded from a file
      . . .
    
    VERSION
      0.5.2

In order to use Transporter to move data from MongoDB to Elasticsearch, we need two things: data in MongoDB that we want to move and a pipeline that tells Transporter how to move it. The next step creates some example data, but if you already have a MongoDB database that you want to move, you can skip the next step and go straight to Step 3.

## Step 2 — Adding Example Data to MongoDB (Optional)

In this step, we’ll create a example database with a single collection in MongoDB and add a few documents to that collection. Then, in the rest of the tutorial, we’ll migrate and transform this example data with a Transporter pipeline.

First, connect to your MongoDB database.

    mongo

This will change your prompt to `mongo>`, indicating that you’re using the MongoDB shell.

From here, select a database to work on. We’ll call ours `my_application`.

    use my_application

In `MongoDB`, you don’t need to explicitly create a database or a collection. Once you start adding data to a database you’ve selected by name, that database will automatically be created.

So, to create the `my_application` database, save two documents to its `users` collection: one representing Sammy Shark and one representing Gilly Glowfish. This will be our test data.

    db.users.save({"firstName": "Sammy", "lastName": "Shark"});
    db.users.save({"firstName": "Gilly", "lastName": "Glowfish"});

After you’ve added the documents, you can query the `users` collection to see your records.

    db.users.find().pretty();

The output will look similar to the output below, but the `_id` columns will be different. MongoDB automatically adds object IDs to uniquely identify the documents in a collection.

    output{
      "_id" : ObjectId("59299ac7f80b31254a916456"),
      "firstName" : "Sammy",
      "lastName" : "Shark"
    }
    {
      "_id" : ObjectId("59299ac7f80b31254a916457"),
      "firstName" : "Gilly",
      "lastName" : "Glowfish"
    }

Press `CTRL+C` to exit the MongoDB shell.

Next, let’s create a Transporter pipeline to move this data from MongoDB to Elasticsearch.

## Step 3 — Creating a Basic Pipeline

A pipeline in Transporter is defined by a JavaScript file named `pipeline.js` by default. The built-in `init` command creates a basic [configuration file](https://github.com/compose/transporter/wiki/Configuration) in the correct directory, given a source and sink.

Initialize a starter `pipeline.js` with MongoDB as the source and Elasticsearch as the sink.

    transporter init mongodb elasticsearch

You’ll see the following output:

    OutputWriting pipeline.js...

You won’t need to modify `pipeline.js` for this step, but let’s take a look to see how it works.

The file looks like this, but you can also view the contents of the file using the command `cat pipeline.js`, `less pipeline.js` (exit `less` by pressing `q`), or by opening it with your favorite text editor.

pipeline.js

    var source = mongodb({
      "uri": "${MONGODB_URI}"
      // "timeout": "30s",
      // "tail": false,
      // "ssl": false,
      // "cacerts": ["/path/to/cert.pem"],
      // "wc": 1,
      // "fsync": false,
      // "bulk": false,
      // "collection_filters": "{}",
      // "read_preference": "Primary"
    })
    
    var sink = elasticsearch({
      "uri": "${ELASTICSEARCH_URI}"
      // "timeout": "10s", // defaults to 30s
      // "aws_access_key": "ABCDEF", // used for signing requests to AWS Elasticsearch service
      // "aws_access_secret": "ABCDEF" // used for signing requests to AWS Elasticsearch service
      // "parent_id": "elastic_parent" // defaults to "elastic_parent" parent identifier for Elasticsearch
    })
    
    t.Source("source", source, "/.*/").Save("sink", sink, "/.*/")

The lines that begin with `var source` and `var sink` define [JavaScript variables](understanding-variables-scope-hoisting-in-javascript) for the MongoDB and Elasticsearch adaptors, respectively. We’ll define the `MONGODB_URI` and `ELASTICSEARCH_URI` environment variables that these adaptors need later in this step.

The lines that begin with `//` are comments. They highlight some common configuration options you can set for your pipeline, but we aren’t using them for the basic pipeline we’re creating here.

The last line connects the source and the sink. The variable `transporter` or `t` lets us access our pipeline. We use the `.Source()` and `.Save()` [functions](how-to-define-functions-in-javascript) to add the source and sink using the `source` and `sink` variables defined previously in the file.

The third argument to the `Source()` and `Save()` functions is the `namespace.` Passing `/.*/` as the last argument means that we want to transfer all the data from MongoDB and save it under the same namespace in Elasticsearch.

Before we can run this pipeline, we need to set the [environment variables](how-to-read-and-set-environmental-and-shell-variables-on-a-linux-vps) for the [MongoDB URI](https://docs.mongodb.com/manual/reference/connection-string/) and [Elasticsearch URI](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html). In the example we’re using, both are hosted locally with default settings, but make sure you customize these options if you’re using existing MongoDB or Elasticsearch instances.

    export MONGODB_URI='mongodb://localhost/my_application'
    export ELASTICSEARCH_URI='http://localhost:9200/my_application'

Now we’re ready to run the pipeline.

    transporter run pipeline.js

You’ll see output that ends like this:

    Output. . .
    INFO[0001] metrics source records: 2 path=source ts=1522942118483391242
    INFO[0001] metrics source/sink records: 2 path="source/sink" ts=1522942118483395960
    INFO[0001] exit map[source:mongodb sink:elasticsearch] ts=1522942118483396878

In the second- and third-to-last lines, this output indicates that there were 2 records present in the source and 2 records were moved over to the sink.

To confirm that both the records were processed, you can query Elasticsearch for the contents of the `my_application` database, which should now exist.

    curl $ELASTICSEARCH_URI/_search?pretty=true

The `?pretty=true` parameter makes the output easier to read:

    Output{
      "took" : 5,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "skipped" : 0,
        "failed" : 0
      },
      "hits" : {
        "total" : 2,
        "max_score" : 1.0,
        "hits" : [
          {
            "_index" : "my_application",
            "_type" : "users",
            "_id" : "5ac63e9c6687d9f638ced4fe",
            "_score" : 1.0,
            "_source" : {
              "firstName" : "Gilly",
              "lastName" : "Glowfish"
            }
          },
          {
            "_index" : "my_application",
            "_type" : "users",
            "_id" : "5ac63e986687d9f638ced4fd",
            "_score" : 1.0,
            "_source" : {
              "firstName" : "Sammy",
              "lastName" : "Shark"
            }
          }
        ]
      }
    }

Databases and collections in MongoDB are analogous to indexes and types in Elasticsearch. With that in mind, you should see:

- The `_index` field set to `my_application,`the name of the original MongoDB database).
- The `_type` field set to `users,`the name of the MongoDB collection.
- The `firstName` and `lastName` fields filled out with “Sammy” “Shark” and “Gilly” “Glowfish”, respectively.

This confirms that both the records from MongoDB were successfully processed through Transporter and loaded to Elasticsearch. To build upon this basic pipeline, we’ll add an intermediate processing step that can transform the input data.

## Step 4 — Creating a Transformer

As the name suggests, _transformers_ modify the source data before loading it to the sink. For example, they allow you to add a new field, remove a field, or change the data of a field. Transporter comes with some predefined transformers as well as support for custom ones.

Typically, custom transformers are written as JavaScript functions and saved in a separate file. To use them, you add a reference to the transformer file in `pipeline.js` . Transporter includes both the Otto and Goja JavaScript engines. Because Goja is newer and generally faster, we’ll use it here. The only functional difference is the syntax.

Create a file called `transform.js`, which we’ll use to write our transformation function.

    nano transform.js

Here’s the function we’ll use, which will create a new field called `fullName`, the value of which will be the `firstName` and `lastName` fields concatenated together, separated by a space (like `Sammy Shark`).

transform.js

    function transform(msg) {
        msg.data.fullName = msg.data.firstName + " " + msg.data.lastName;
        return msg
    }

Let’s walk through the lines of this file:

- The first line of the file, `function transform(msg),`is the [function definition](how-to-define-functions-in-javascript).
- `msg` is a [JavaScript object](understanding-data-types-in-javascript#objects) that contains the details of the source document. We use this object to [access the data](understanding-objects-in-javascript#accessing-object-properties) going through the pipeline.
- The first line of the function [concatenates](how-to-work-with-strings-in-javascript#string-concatenation) the two existing fields and [assigns that value](understanding-objects-in-javascript#adding-and-modifying-object-properties) to the new `fullName` field.
- The final line of the function returns the newly modified `msg` object for the rest of the pipeline to use.

Save and close the file.

Next, we need to modify the pipeline to use this transformer. Open the `pipeline.js` file for editing.

    nano pipeline.js

In the final line, we need to add a call to the `Transform()` function to add the transformer to the pipeline between the calls to `Source()` and `Save()`, like this:

~/transporter/pipeline.js

    . . .
    t.Source("source", source, "/.*/")
    .Transform(goja({"filename": "transform.js"}))
    .Save("sink", sink, "/.*/")

The argument passed to `Transform()` is the type of transformation, which is Goja in this case. Using the `goja` function, we specify the the filename of the transformer using its [relative path](basic-linux-navigation-and-file-management#moving-around-the-filesystem-with-quot-cd-quot).

Save and close the file. Before we rerun the pipeline to test the transformer, let’s clear the existing data in Elasticsearch from the previous test.

    curl -XDELETE $ELASTICSEARCH_URI

You’ll see this output acknowledging the success of the command.

    Output{"acknowledged":true}

Now rerun the pipeline.

    transporter run pipeline.js

The output will look very similar to the previous test, and you can see in the last few lines whether the pipeline completed successfully as before. To be sure, we can again check Elasticsearch to see if the data exists in the format we expect.

    curl $ELASTICSEARCH_URI/_search?pretty=true

You can see the `fullName` field in the new output:

    Output{
      "took" : 9,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "skipped" : 0,
        "failed" : 0
      },
      "hits" : {
        "total" : 2,
        "max_score" : 1.0,
        "hits" : [
          {
            "_index" : "my_application",
            "_type" : "users",
            "_id" : "5ac63e9c6687d9f638ced4fe",
            "_score" : 1.0,
            "_source" : {
              "firstName" : "Gilly",
              "fullName" : "Gilly Glowfish",
              "lastName" : "Glowfish"
            }
          },
          {
            "_index" : "my_application",
            "_type" : "users",
            "_id" : "5ac63e986687d9f638ced4fd",
            "_score" : 1.0,
            "_source" : {
              "firstName" : "Sammy",
              "fullName" : "Sammy Shark",
              "lastName" : "Shark"
            }
          }
        ]
      }
    }
    

Notice the `fullName` field has been added in both documents with the values correctly set. With this, now we know how to add custom transformations to a Transporter pipeline.

## Conclusion

You’ve built a basic Transporter pipeline with an transformer to copy and modify data from MongoDB to Elasticsearch. You can apply more complex transformations in the same way, chain multiple transformations in the same pipeline, and more. MongoDB and Elasticsearch are only two of the adapters Transporter supports. It also supports flat files, SQL databases like Postgres, and many other data sources.

You can check out the [Transporter project on GitHub](https://github.com/compose/transporter) to stay updated for the latest changes in the API, and visit [the Transporter wiki](https://github.com/compose/transporter/wiki) for more detailed information on how to use adaptors, transformers, and Transformer’s other features.
