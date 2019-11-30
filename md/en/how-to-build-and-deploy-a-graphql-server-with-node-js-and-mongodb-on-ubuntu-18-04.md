---
author: Roy Derks
date: 2019-04-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-and-deploy-a-graphql-server-with-node-js-and-mongodb-on-ubuntu-18-04
---

# How To Build and Deploy a GraphQL Server with Node.js and MongoDB on Ubuntu 18.04

_The author selected the [Wikimedia Foundation](https://www.brightfunds.org/organizations/wikimedia-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

GraphQL was publicly released by Facebook in 2015 as a query language for APIs that makes it easy to query and mutate data from different data collections. From a single endpoint, you can query and mutate multiple data sources with a single POST request. GraphQL solves some of the common design flaws in REST API architectures, such as situations where the endpoint returns more information than you actually need. Also, it is possible when using REST APIs you would need to send requests to multiple REST endpoints to collect all the information you require—a situation that is called the n+1 problem. An example of this would be when you want to show a users’ information, but need to collect data such as personal details and addresses from different endpoints.

These problems don’t apply to GraphQL as it has only one endpoint, which can return data from multiple collections. The data it returns depends on the _query_ that you send to this endpoint. In this query you define the structure of the data you want to receive, including any nested data collections. In addition to a query, you can also use a _mutation_ to change data on a GraphQL server, and a _subscription_ to watch for changes in the data. For more information about GraphQL and its concepts, you can visit the [documentation](https://graphql.org/learn/) on the official website.

As GraphQL is a query language with a lot of flexibility, it combines especially well with document-based databases like [MongoDB](https://www.mongodb.com/). Both technologies are based on hierarchical, typed schemas and are popular within the JavaScript community. Also, MongoDB’s data is stored as JSON objects, so no additional parsing is necessary on the GraphQL server.

In this tutorial, you’ll build and deploy a GraphQL server with Node.js that can query and mutate data from a MongoDB database that is running on Ubuntu 18.04. At the end of this tutorial, you’ll be able to access data in your database by using a single endpoint, both by sending requests to the server directly through the terminal and by using the pre-made GraphiQL playground interface. With this playground you can explore the contents of the GraphQL server by sending queries, mutations, and subscriptions. Also, you can find visual representations of the schemas that are defined for this server.

At the end of this tutorial, you’ll use the GraphiQL playground to quickly interface with your GraphQL server:

![The GraphiQL playground in action](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64864/GraphiQL_1.png)

## Prerequisites

Before you begin this guide you’ll need the following:

- An Ubuntu 18.04 server set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall.

- A MongoDB installation running on Ubuntu 18.04, which you can set up by following our tutorial [How to Install MongoDB on Ubuntu 18.04](how-to-install-mongodb-on-ubuntu-18-04).

- Nginx installed, as seen in [How to install Nginx on Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04-quickstart), including **Step 4 – Setting Up Server Blocks**.

- To allow remote access to your GraphQL server, you will need a _fully qualified domain name_ (FQDN) and an A record that points toward your server IP. You can learn more about this by reading through [An Introduction to DNS Terminology, Components, and Concepts](an-introduction-to-dns-terminology-components-and-concepts), or [Domains and DNS documentation](https://www.digitalocean.com/docs/networking/dns/) if you have a DigitalOcean account.

- Familiarity with JavaScript, which you can gain from the series [How To Code in JavaScript](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-javascript).

## Step 1 — Setting Up the MongoDB Database

Before creating the GraphQL server, make sure your database is configured right, has authentication enabled, and is filled with sample data. For this you need to connect to the Ubuntu 18.04 server running the MongoDB database from your command prompt. All steps in this tutorial will take place on this server.

After you’ve established the connection, run the following command to check if MongoDB is active and running on your server:

    sudo systemctl status mongodb

You’ll see the following output in your terminal, indicating the MongoDB database is actively running:

    Output● mongodb.service - An object/document-oriented database
       Loaded: loaded (/lib/systemd/system/mongodb.service; enabled; vendor preset: enabled)
       Active: active (running) since Sat 2019-02-23 12:23:03 UTC; 1 months 13 days ago
         Docs: man:mongod(1)
     Main PID: 2388 (mongod)
        Tasks: 25 (limit: 1152)
       CGroup: /system.slice/mongodb.service
               └─2388 /usr/bin/mongod --unixSocketPrefix=/run/mongodb --config /etc/mongodb.conf

Before creating the database where you’ll store the sample data, you need to create an **admin** user first, since regular users are scoped to a specific database. You can do this by executing the following command that opens the MongoDB shell:

    mongo

With the MongoDB shell you’ll get direct access to the MongoDB database and can create users or databases and query data. Inside this shell, execute the following command that will add a new **admin** user to MongoDB. You can replace the highlighted keywords with your own username and password combination, but don’t forget to write them down somewhere.

    use admin
    db.createUser({
        user: "admin_username",
        pwd: "admin_password",
        roles: [{ role: "root", db: "admin"}]
    })

The first line of the preceding command selects the database called `admin`, which is the database where all the admin roles are stored. With the method `db.createUser()` you can create the actual user and define its username, password, and roles.

Executing this command will return:

    OutputSuccessfully added user: {
        "user" : "admin_username",
        "roles" : [
            {
                "role" : "root",
                "db" : "admin"
            }
        ]
    }

You can now close the MongoDB shell by typing `exit`.

Next, log in at the MongoDB shell again, but this time with the newly created **admin** user:

    mongo -u "admin_username" -p "admin_password" --authenticationDatabase "admin"

This command will open the MongoDB shell as a specific user, where the `-u` flag specifies the username and the `-p` flag the password of that user. The extra flag `--authenticationDatabase` specifies that you want to log in as an **admin**.

Next, you’ll switch to a new database and then use the `db.createUser()` method to create a new user with permissions to make changes to this database. Replace the highlighted sections with your own information, making sure to write these credentials down.

Run the following command in the MongoDB shell:

    use database_name
    db.createUser({
        user: "username",
        pwd: "password",
        roles: ["readWrite"]
    })

This will return the following:

    OutputSuccessfully added user: { "user" : "username", "roles" : ["readWrite"] }

After creating the database and user, fill this database with sample data that can be queried by the GraphQL server later on in this tutorial. For this, you can use the [bios collection](https://docs.mongodb.com/manual/reference/bios-example-collection/#the-bios-example-collection) sample from the MongoDB website. By executing the commands in the following code snippet you’ll insert a smaller version of this `bios` collection dataset into your database. You can replace the highlighted sections with your own information, but for the purposes of this tutorial, name the collection `bios`:

    db.bios.insertMany([
       {
           "_id" : 1,
           "name" : {
               "first" : "John",
               "last" : "Backus"
           },
           "birth" : ISODate("1924-12-03T05:00:00Z"),
           "death" : ISODate("2007-03-17T04:00:00Z"),
           "contribs" : [
               "Fortran",
               "ALGOL",
               "Backus-Naur Form",
               "FP"
           ],
           "awards" : [
               {
                   "award" : "W.W. McDowell Award",
                   "year" : 1967,
                   "by" : "IEEE Computer Society"
               },
               {
                   "award" : "National Medal of Science",
                   "year" : 1975,
                   "by" : "National Science Foundation"
               },
               {
                   "award" : "Turing Award",
                   "year" : 1977,
                   "by" : "ACM"
               },
               {
                   "award" : "Draper Prize",
                   "year" : 1993,
                   "by" : "National Academy of Engineering"
               }
           ]
       },
       {
           "_id" : ObjectId("51df07b094c6acd67e492f41"),
           "name" : {
               "first" : "John",
               "last" : "McCarthy"
           },
           "birth" : ISODate("1927-09-04T04:00:00Z"),
           "death" : ISODate("2011-12-24T05:00:00Z"),
           "contribs" : [
               "Lisp",
               "Artificial Intelligence",
               "ALGOL"
           ],
           "awards" : [
               {
                   "award" : "Turing Award",
                   "year" : 1971,
                   "by" : "ACM"
               },
               {
                   "award" : "Kyoto Prize",
                   "year" : 1988,
                   "by" : "Inamori Foundation"
               },
               {
                   "award" : "National Medal of Science",
                   "year" : 1990,
                   "by" : "National Science Foundation"
               }
           ]
       }
    ]);

This code block is an array consisting of multiple objects that contain information about successful scientists from the past. After running these commands to enter this collection into your database, you’ll receive the following message indicating the data was added:

    Output{
        "acknowledged" : true,
        "insertedIds" : [
            1,
            ObjectId("51df07b094c6acd67e492f41")
        ]
    }

After seeing the success message, you can close the MongoDB shell by typing `exit`. Next, configure the MongoDB installation to have authorization enabled so only authenticated users can access the data. To edit the configuration of the MongoDB installation, open the file containing the settings for this installation:

    sudo nano /etc/mongodb.conf

Uncomment the highlighted line in the following code to enable authorization:

/etc/mongodb.conf

    ...
    # Turn on/off security. Off is currently the default
    #noauth = true
    auth = true
    ...

In order to make these changes active, restart MongoDB by running:

    sudo systemctl restart mongodb

Make sure the database is running again by executing the command:

    sudo systemctl status mongodb

This will yield output similar to the following:

    Output● mongodb.service - An object/document-oriented database
       Loaded: loaded (/lib/systemd/system/mongodb.service; enabled; vendor preset: enabled)
       Active: active (running) since Sat 2019-02-23 12:23:03 UTC; 1 months 13 days ago
         Docs: man:mongod(1)
     Main PID: 2388 (mongod)
        Tasks: 25 (limit: 1152)
       CGroup: /system.slice/mongodb.service
               └─2388 /usr/bin/mongod --unixSocketPrefix=/run/mongodb --config /etc/mongodb.conf

To make sure that your user can connect to the database you just created, try opening the MongoDB shell as an authenticated user with the command:

    mongo -u "username" -p "password" --authenticationDatabase "database_name"

This uses the same flags as before, only this time the `--authenticationDatabase` is set to the database you’ve created and filled with the sample data.

Now you’ve successfully added an **admin** user and another user that has read/write access to the database with the sample data. Also, the database has authorization enabled meaning you need a username and password to access it. In the next step you’ll create the GraphQL server that will be connected to this database later in the tutorial.

## Step 2 — Creating the GraphQL Server

With the database configured and filled with sample data, it’s time to create a GraphQL server that can query and mutate this data. For this you’ll use [Express](https://www.npmjs.com/package/express) and [`express-graphql`](https://graphql.org/graphql-js/express-graphql/), which both run on Node.js. Express is a lightweight framework to quickly create Node.js HTTP servers, and `express-graphql` provides middleware to make it possible to quickly build GraphQL servers.

The first step is to make sure your machine is up to date:

    sudo apt update

Next, install Node.js on your server by running the following commands. Together with Node.js you’ll also install [npm](https://www.npmjs.com/), a package manager for JavaScript that runs on Node.js.

    sudo apt install nodejs npm

After following the installation process, check if the Node.js version you’ve just installed is `v8.10.0` or higher:

    node -v

This will return the following:

    Outputv8.10.0

To initialize a new JavaScript project, run the following commands on the server as a `sudo` user, and replace the highlighted keywords with a name for your project.

First move into the root directory of your server:

    cd

Once there, create a new directory named after your project:

    mkdir project_name

Move into this directory:

    cd project_name 

Finally, initialize a new npm package with the following command:

    sudo npm init -y

After running `npm init -y` you’ll receive a success message that the following `package.json` file was created:

    OutputWrote to /home/username/project_name/package.json:
    
    {
      "name": "project_name",
      "version": "1.0.0",
      "description": "",
      "main": "index.js",
      "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      "keywords": [],
      "author": "",
      "license": "ISC"
    }

**Note:** You can also execute `npm init` without the `-y` flag, after which you would answer multiple questions to set up the project name, author, etc. You can enter the details or just press enter to proceed.

Now that you’ve initialized the project, install the packages you need to set up the GraphQL server:

    sudo npm install --save express express-graphql graphql

Create a new file called `index.js` and subsequently open this file by running:

    sudo nano index.js

Next, add the following code block into the newly created file to set up the GraphQL server:

index.js

    const express = require('express');
    const graphqlHTTP = require('express-graphql');
    const { buildSchema } = require('graphql');
    
    // Construct a schema, using GraphQL schema language
    const schema = buildSchema(`
      type Query {
        hello: String
      }
    `);
    
    // Provide resolver functions for your schema fields
    const resolvers = {
      hello: () => 'Hello world!'
    };
    
    const app = express();
    app.use('/graphql', graphqlHTTP({
      schema,
      rootValue: resolvers
    }));
    app.listen(4000);
    
    console.log(`🚀 Server ready at http://localhost:4000/graphql`);

This code block consists of several parts that are all important. First you describe the schema of the data that is returned by the GraphQL API:

index.js

    ...
    // Construct a schema, using GraphQL schema language
    const schema = buildSchema(`
      type Query {
        hello: String
      }
    `);
    ...

The type `Query` defines what queries can be executed and in which format it will return the result. As you can see, the only query defined is `hello` that returns data in a `String` format.

The next section establishes the [resolvers](https://graphql.org/learn/execution/#root-fields-resolvers), where data is matched to the schemas that you can query:

index.js

    ...
    // Provide resolver functions for your schema fields
    const resolvers = {
      hello: () => 'Hello world!'
    };
    ...

These resolvers are directly linked to schemas, and return the data that matches these schemas.

The final part of this code block initializes the GraphQL server, creates the API endpoint with Express, and describes the port on which the GraphQL endpoint is running:

index.js

    ...
    const app = express();
    app.use('/graphql', graphqlHTTP({
      schema,
      rootValue: resolvers
    }));
    app.listen(4000);
    
    console.log(`🚀 Server ready at http://localhost:4000/graphql`);

After you have added these lines, save and exit from `index.js`.

Next, to actually run the GraphQL server you need to run the file `index.js` with Node.js. This can be done manually from the command line, but it’s common practice to set up the `package.json` file to do this for you.

Open the `package.json` file:

    sudo nano package.json

Add the following highlighted line to this file:

package.json

    {
      "name": "project_name",
      "version": "1.0.0",
      "description": "",
      "main": "index.js",
      "scripts": {
        "start": "node index.js",
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      "keywords": [],
      "author": "",
      "license": "ISC"
    }

Save and exit the file.

To start the GraphQL server, execute the following command in the terminal:

    npm start

Once you run this, the terminal prompt will disappear, and a message will appear to confirm the GraphQL server is running:

    Output🚀 Server ready at http://localhost:4000/graphql

If you now open up another terminal session, you can test if the GraphQL server is running by executing the following command. This sends a `curl` `POST` request with a JSON body after the `--data` flag that contains your GraphQL query to the local endpoint:

    curl -X POST -H "Content-Type: application/json" --data '{ "query": "{ hello }" }' http://localhost:4000/graphql

This will execute the query as it’s described in the GraphQL schema in your code and return data in a predictable JSON format that is equal to the data as it’s returned in the resolvers:

    Output{ "data": { "hello": "Hello world!" } }

**Note:** In case the Express server crashes or gets stuck, you need to manually kill the `node` process that is running on the server. To kill all such processes, you can execute the following:

    killall node

After which, you can restart the GraphQL server by running:

    npm start

In this step you’ve created the first version of the GraphQL server that is now running on a local endpoint that can be accessed on your server. Next, you’ll connect your resolvers to the MongoDB database.

## Step 3 — Connecting to the MongoDB Database

With the GraphQL server in order, you can now set up the connection with the MongoDB database that you configured and filled with data before and create a new schema that matches this data.

To be able to connect to MongoDB from the GraphQL server, install the JavaScript package for MongoDB from npm:

    sudo npm install --save mongodb

Once this has been installed, open up `index.js` in your text editor:

    sudo nano index.js

Next, add the following highlighted code to `index.js` just after the imported dependencies and fill the highlighted values with your own connection details to the local MongoDB database. The `username`, `password`, and `database_name` are those that you created in the first step of this tutorial.

index.js

    const express = require('express');
    const graphqlHTTP = require('express-graphql');
    const { buildSchema } = require('graphql');
    const { MongoClient } = require('mongodb');
    
    const context = () => MongoClient.connect('mongodb://username:password@localhost:27017/database_name', { useNewUrlParser: true }).then(client => client.db('database_name'));
    ...

These lines add the connection to the local MongoDB database to a function called [context](https://graphql.org/learn/execution/#root-fields-resolvers). This context function will be available to every resolver, which is why you use this to set up database connections.

Next, in your `index.js` file, add the context function to the initialization of the GraphQL server by inserting the following highlighted lines:

index.js

    ...
    const app = express();
    app.use('/graphql', graphqlHTTP({
      schema,
      rootValue: resolvers,
      context
    }));
    app.listen(4000);
    
    console.log(`🚀 Server ready at http://localhost:4000/graphql`);

Now you can call this context function from your resolvers, and thereby read variables from the MongoDB database. If you look back to the first step of this tutorial, you can see which values are present in the database. From here, define a new GraphQL schema that matches this data structure. Overwrite the previous value for the constant `schema` with the following highlighted lines:

index.js

    ...
    // Construct a schema, using GrahQL schema language
    const schema = buildSchema(`
      type Query {
        bios: [Bio]
      }
      type Bio {
        name: Name,
        title: String,
        birth: String,
        death: String,
        awards: [Award]
      }
      type Name {
        first: String,
        last: String
      },
      type Award {
        award: String,
        year: Float,
        by: String
      }
    `);
    ...

The type `Query` has changed and now returns a collection of the new type `Bio`. This new type consists of several types including two other non-scalar types `Name` and `Awards`, meaning these types don’t match a predefined format like `String` or `Float`. For more information on defining GraphQL schemas you can look at the [documentation](https://graphql.org/graphql-js/utilities/#buildschema) for GraphQL.

Also, since the resolvers tie the data from the database to the schema, update the code for the resolvers when you make changes to the schema. Create a new resolver that is called `bios`, which is equal to the `Query` that can be found in the schema and the name of the collection in the database. Note that, in this case, the name of the collection in `db.collection('bios')` is `bios`, but that this would change if you had assigned a different name to your collection.

Add the following highlighted line to `index.js`:

index.js

    ...
    // Provide resolver functions for your schema fields
    const resolvers = {
      bios: (args, context) => context().then(db => db.collection('bios').find().toArray())
    };
    ...

This function will use the context function, which you can use to retrieve variables from the MongoDB database. Once you have made these changes to the code, save and exit `index.js`.

In order to make these changes active, you need to restart the GraphQL server. You can stop the current process by using the keyboard combination `CTRL` + `C` and start the GraphQL server by running:

    npm start

Now you’re able to use the updated schema and query the data that is inside the database. If you look at the schema, you’ll see that the `Query` for `bios` returns the type `Bio`; this type could also return the type `Name`.

To return all the first and last names for all the bios in the database, send the following request to the GraphQL server in a new terminal window:

     curl -X POST -H "Content-Type: application/json" --data '{ "query": "{ bios { name { first, last } } }" }' http://localhost:4000/graphql

This again will return a JSON object that matches the structure of the schema:

    Output{"data":{"bios":[{"name":{"first":"John","last":"Backus"}},{"name":{"first":"John","last":"McCarthy"}}]}}

You can easily retrieve more variables from the bios by extending the query with any of the types that are described in the type for `Bio`.

Also, you can retrieve a bio by specifying an `id`. In order to do this you need to add another type to the `Query` type and extend the resolvers. To do this, open `index.js` in your text editor:

    sudo nano index.js

Add the following highlighted lines of code:

index.js

    ...
    // Construct a schema, using GrahQL schema language
    const schema = buildSchema(`
      type Query {
        bios: [Bio]
        bio(id: Int): Bio
      }
    
      ...
    
      // Provide resolver functions for your schema fields
      const resolvers = {
        bios: (args, context) => context().then(db => db.collection('bios').find().toArray()),
        bio: (args, context) => context().then(db => db.collection('bios').findOne({ _id: args.id }))
      };
      ...

Save and exit the file.

In the terminal that is running your GraphQL server, press `CTRL` + `C` to stop it from running, then execute the following to restart it:

    npm start

In another terminal window, execute the following GraphQL request:

    curl -X POST -H "Content-Type: application/json" --data '{ "query": "{ bio(id: 1) { name { first, last } } }" }' http://localhost:4000/graphql

This returns the entry for the bio that has an `id` equal to `1`:

    Output{ "data": { "bio": { "name": { "first": "John", "last": "Backus" } } } }

Being able to query data from a database is not the only feature of GraphQL; you can also change the data in the database. To do this, open up `index.js`:

    sudo nano index.js

Next to the type `Query` you can also use the type `Mutation`, which allows you to mutate the database. To use this type, add it to the schema and also create input types by inserting these highlighted lines:

index.js

    ...
    // Construct a schema, using GraphQL schema language
    const schema = buildSchema(`
      type Query {
        bios: [Bio]
        bio(id: Int): Bio
      }
      type Mutation {
        addBio(input: BioInput) : Bio
      }
      input BioInput {
        name: NameInput
        title: String
        birth: String
        death: String
      }
      input NameInput {
        first: String
        last: String
      }
    ...

These input types define which variables can be used as inputs, which you can access in the resolvers and use to insert a new document in the database. Do this by adding the following lines to `index.js`:

index.js

    ...
    // Provide resolver functions for your schema fields
    const resolvers = {
      bios: (args, context) => context().then(db => db.collection('bios').find().toArray()),
      bio: (args, context) => context().then(db => db.collection('bios').findOne({ _id: args.id })),
      addBio: (args, context) => context().then(db => db.collection('bios').insertOne({ name: args.input.name, title: args.input.title, death: args.input.death, birth: args.input.birth})).then(response => response.ops[0])
    };
    ...

Just as with the resolvers for regular queries, you need to return a value from the resolver in `index.js`. In the case of a `Mutation` where the type `Bio` is mutated, you would return the value of the mutated bio.

At this point, your `index.js` file will contain the following lines:

index.js

    iconst express = require('express');
    const graphqlHTTP = require('express-graphql');
    const { buildSchema } = require('graphql');
    const { MongoClient } = require('mongodb');
    
    const context = () => MongoClient.connect('mongodb://username:password@localhost:27017/database_name', { useNewUrlParser: true })
      .then(client => client.db('GraphQL_Test'));
    
    // Construct a schema, using GraphQL schema language
    const schema = buildSchema(`
      type Query {
        bios: [Bio]
        bio(id: Int): Bio
      }
      type Mutation {
        addBio(input: BioInput) : Bio
      }
      input BioInput {
        name: NameInput
        title: String
        birth: String
        death: String
      }
      input NameInput {
        first: String
        last: String
      }
      type Bio {
        name: Name,
        title: String,
        birth: String,
        death: String,
        awards: [Award]
      }
      type Name {
        first: String,
        last: String
      },
      type Award {
        award: String,
        year: Float,
        by: String
      }
    `);
    
    // Provide resolver functions for your schema fields
    const resolvers = {
      bios: (args, context) =>context().then(db => db.collection('Sample_Data').find().toArray()),
      bio: (args, context) =>context().then(db => db.collection('Sample_Data').findOne({ _id: args.id })),
      addBio: (args, context) => context().then(db => db.collection('Sample_Data').insertOne({ name: args.input.name, title: args.input.title, death: args.input.death, birth: args.input.birth})).then(response => response.ops[0])
    };
    
    const app = express();
    app.use('/graphql', graphqlHTTP({
      schema,
      rootValue: resolvers,
      context
    }));
    app.listen(4000);
    
    console.log(`🚀 Server ready at http://localhost:4000/graphql`);

Save and exit `index.js`.

To check if your new mutation is working, restart the GraphQL server by pressing `CTRL` + `c` and running `npm start` in the terminal that is running your GraphQL server, then open another terminal session to execute the following `curl` request. Just as with the `curl` request for queries, the body in the `--data` flag will be sent to the GraphQL server. The highlighted parts will be added to the database:

    curl -X POST -H "Content-Type: application/json" --data '{ "query": "mutation { addBio(input: { name: { first: \"test\", last: \"user\" } }) { name { first, last } } }" }' http://localhost:4000/graphql

This returns the following result, meaning you just inserted a new bio to the database:

    Output{ "data": { "addBio": { "name": { "first": "test", "last": "user" } } } }

In this step, you created the connection with MongoDB and the GraphQL server, allowing you to retrieve and mutate data from this database by executing GraphQL queries. Next, you’ll expose this GraphQL server for remote access.

## Step 4 — Allowing Remote Access

Having set up the database and the GraphQL server, you can now configure the GraphQL server to allow remote access. For this you’ll use Nginx, which you set up in the prerequisite tutorial [How to install Nginx on Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04-quickstart). This Nginx configuration can be found in the `/etc/nginx/sites-available/example.com` file, where `example.com` is the server name you added in the prerequisite tutorial.

Open this file for editing, replacing your domain name with `example.com`:

    sudo nano /etc/nginx/sites-available/example.com

In this file you can find a server block that listens to port `80`, where you’ve already set up a value for `server_name` in the prerequisite tutorial. Inside this server block, change the value for `root` to be the directory in which you created the code for the GraphQL server and add `index.js` as the index. Also, within the location block, set a `proxy_pass` so you can use your server’s IP or a custom domain name to refer to the GraphQL server:

/etc/nginx/sites-available/example.com

    server {
      listen 80;
      listen [::]:80;
    
      root /project_name;
      index index.js;
    
      server_name example.com;
    
      location / {
        proxy_pass http://localhost:4000/graphql;
      }
    }

Make sure there are no Nginx syntax errors in this configuration file by running:

    sudo nginx -t

You will receive the following output:

    Outputnginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful

When there are no errors found for the configuration file, restart Nginx:

    sudo systemctl restart nginx

Now you will be able to access your GraphQL server from any terminal session tab by executing and replacing `example.com` by either your server’s IP or your custom domain name:

    curl -X POST -H "Content-Type: application/json" --data '{ "query": "{ bios { name { first, last } } }" }' http://example.com

This will return the same JSON object as the one of the previous step, including any additional data you might have added by using a mutation:

    Output{"data":{"bios":[{"name":{"first":"John","last":"Backus"}},{"name":{"first":"John","last":"McCarthy"}},{"name":{"first":"test","last":"user"}}]}}

Now that you have made your GraphQL server accessible remotely, make sure your GraphQL server doesn’t go down when you close the terminal or the server restarts. This way, your MongoDB database will be accessible via the GraphQL server whenever you want to make a request.

To do this, use the npm package [`forever`](https://www.npmjs.com/package/forever), a CLI tool that ensures that your command line scripts run continuously, or get restarted in case of any failure.

Install `forever` with npm:

    sudo npm install forever -g

Once it is done installing, add it to the `package.json` file:

package.json

    {
      "name": "project_name",
      "version": "1.0.0",
      "description": "",
      "main": "index.js",
      "scripts": {
        "start": "node index.js",
        "deploy": "forever start --minUptime 2000 --spinSleepTime 5 index.js",
        "test": "echo \"Error: no test specified\" && exit 1"
      },
      ...

To start the GraphQL server with `forever` enabled, run the following command:

    npm run deploy

This will start the `index.js` file containing the GraphQL server with `forever`, and ensure it will keep running with a minimum uptime of 2000 milliseconds and 5 milliseconds between every restart in case of a failure. The GraphQL server will now continuously run in the background, so you don’t need to open a new tab any longer when you want to send a request to the server.

You’ve now created a GraphQL server that is using MongoDB to store data and is set up to allow access from a remote server. In the next step you’ll enable the GraphiQL playground, which will make it easier for you to inspect the GraphQL server.

## Step 5 — Enabling GraphiQL Playground

Being able to send cURL requests to the GraphQL server is great, but it would be faster to have a user interface that can execute GraphQL requests immediately, especially during development. For this you can use GraphiQL, an interface supported by the package `express-graphql`.

To enable GraphiQL, edit the file `index.js`:

    sudo nano index.js

Add the following highlighted lines:

index.js

    const app = express();
    app.use('/graphql', graphqlHTTP({
      schema,
      rootValue: resolvers,
      context,
      graphiql: true
    }));
    app.listen(4000);
    
    console.log(`🚀 Server ready at http://localhost:4000/graphql`);

Save and exit the file.

In order for these changes to become visible, make sure to stop `forever` by executing:

    forever stop index.js

Next, start `forever` again so the latest version of your GraphQL server is running:

    npm run deploy

Open a browser at the URL `http://example.com`, replacing `example.com` with your domain name or your server IP. You will see the GraphiQL playground, where you can type GraphQL requests.

![The initial screen for the GraphiQL playground](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64864/GraphiQL_2.png)

On the left side of this playground you can type the GraphQL queries and mutations, while the output will be shown on the right side of the playground. To test if this is working, type the following query on the left side:

    query {
      bios {
        name {
          first
          last
        }
      }
    }

This will output the same result on the right side of the playground, again in JSON format:

![The GraphiQL playground in action](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cart_64864/GraphiQL_3.png)

Now you can send GraphQL requests using the terminal and the GraphiQL playground.

## Conclusion

In this tutorial you’ve set up a MongoDB database and retrieved and mutated data from this database using GraphQL, Node.js, and Express for the server. Additionally, you configured Nginx to allow remote access to this server. Not only can you send requests to this GraphQL server directly, you can also use the GraphiQL as a visual, in-browser GraphQL interface.

If you want to learn about GraphQL, you can watch a [recording](https://www.youtube.com/watch?v=Pmm12LtcPWs) of my presentation on GraphQL at [NDC {London}](https://www.ndcconferences.com/) or visit the website [howtographql.com](https://howtographql.com) for tutorials about GraphQL. To study how GraphQL interacts with other technologies, check out the tutorial on [How to Manually Set Up a Prisma Server on Ubuntu 18.04](how-to-manually-set-up-a-prisma-server-on-ubuntu-18-04), and for more information on building applications with MongoDB, see [How To Build a Blog with Nest.js, MongoDB, and Vue.js](how-to-build-a-blog-with-nest-js-mongodb-and-vue-js).
