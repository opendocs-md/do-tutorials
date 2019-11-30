---
author: Kathleen Juell
date: 2019-03-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/containerizing-a-node-js-application-for-development-with-docker-compose
---

# Containerizing a Node.js Application for Development With Docker Compose

## Introduction

If you are actively developing an application, using [Docker](https://www.docker.com/) can simplify your workflow and the process of deploying your application to production. Working with containers in development offers the following benefits:

- Environments are consistent, meaning that you can choose the languages and dependencies you want for your project without worrying about system conflicts.
- Environments are isolated, making it easier to troubleshoot issues and onboard new team members. 
- Environments are portable, allowing you to package and share your code with others. 

This tutorial will show you how to set up a development environment for a [Node.js](https://nodejs.org/) application using Docker. You will create two containers — one for the Node application and another for the [MongoDB](https://www.mongodb.com/) database — with [Docker Compose](https://docs.docker.com/compose/). Because this application works with Node and MongoDB, our setup will do the following:

- Synchronize the application code on the host with the code in the container to facilitate changes during development. 
- Ensure that changes to the application code work without a restart.
- Create a user and password-protected database for the application’s data.
- Persist this data.

At the end of this tutorial, you will have a working shark information application running on Docker containers:

![Complete Shark Collection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_docker_dev/persisted_data.png)

## Prerequisites

To follow this tutorial, you will need:

- A development server running Ubuntu 18.04, along with a non-root user with `sudo` privileges and an active firewall. For guidance on how to set these up, please see this [Initial Server Setup guide](initial-server-setup-with-ubuntu-18-04). 
- Docker installed on your server, following Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04). 
- Docker Compose installed on your server, following Step 1 of [How To Install Docker Compose on Ubuntu 18.04](how-to-install-docker-compose-on-ubuntu-18-04).

## Step 1 — Cloning the Project and Modifying Dependencies

The first step in building this setup will be cloning the project code and modifying its [`package.json`](https://docs.npmjs.com/files/package.json) file, which includes the project’s dependencies. We will add [`nodemon`](https://www.npmjs.com/package/nodemon) to the project’s [`devDependencies`](https://docs.npmjs.com/files/package.json#devdependencies), specifying that we will be using it during development. Running the application with `nodemon` ensures that it will be automatically restarted whenever you make changes to your code.

First, clone the [`nodejs-mongo-mongoose` repository](https://github.com/do-community/nodejs-mongo-mongoose) from the [DigitalOcean Community GitHub account](https://github.com/do-community). This repository includes the code from the setup described in [How To Integrate MongoDB with Your Node Application](how-to-integrate-mongodb-with-your-node-application), which explains how to integrate a MongoDB database with an existing Node application using [Mongoose](https://mongoosejs.com/).

Clone the repository into a directory called `node_project`:

    git clone https://github.com/do-community/nodejs-mongo-mongoose.git node_project

Navigate to the `node_project` directory:

    cd node_project

Open the project’s `package.json` file using `nano` or your favorite editor:

    nano package.json

Beneath the project dependencies and above the closing curly brace, create a new `devDependencies` object that includes `nodemon`:

~/node\_project/package.json

    ...
    "dependencies": {
        "ejs": "^2.6.1",
        "express": "^4.16.4",
        "mongoose": "^5.4.10"
      },
      "devDependencies": {
        "nodemon": "^1.18.10"
      }    
    }

Save and close the file when you are finished editing.

With the project code in place and its dependencies modified, you can move on to refactoring the code for a containerized workflow.

## Step 2 — Configuring Your Application to Work with Containers

Modifying our application for a containerized workflow means making our code more modular. Containers offer portability between environments, and our code should reflect that by remaining as decoupled from the underlying operating system as possible. To achieve this, we will refactor our code to make greater use of Node’s [process.env](https://nodejs.org/api/process.html#process_process_env) property, which returns an object with information about your user environment at runtime. We can use this object in our code to dynamically assign configuration information at runtime with environment variables.

Let’s begin with `app.js`, our main application entrypoint. Open the file:

    nano app.js

Inside, you will see a definition for a `port` [constant](understanding-variables-scope-hoisting-in-javascript#constants), as well a [`listen` function](https://expressjs.com/en/4x/api.html#app.listen) that uses this constant to specify the port the application will listen on:

~/home/node\_project/app.js

    ...
    const port = 8080;
    ...
    app.listen(port, function () {
      console.log('Example app listening on port 8080!');
    });

Let’s redefine the `port` constant to allow for dynamic assignment at runtime using the `process.env` object. Make the following changes to the constant definition and `listen` function:

~/home/node\_project/app.js

    ...
    const port = process.env.PORT || 8080;
    ...
    app.listen(port, function () {
      console.log(`Example app listening on ${port}!`);
    });

Our new constant definition assigns `port` dynamically using the value passed in at runtime or `8080`. Similarly, we’ve rewritten the `listen` function to use a [template literal](how-to-work-with-strings-in-javascript#string-literals-and-string-values), which will interpolate the port value when listening for connections. Because we will be mapping our ports elsewhere, these revisions will prevent our having to continuously revise this file as our environment changes.

When you are finished editing, save and close the file.

Next, we will modify our database connection information to remove any configuration credentials. Open the `db.js` file, which contains this information:

    nano db.js

Currently, the file does the following things:

- Imports Mongoose, the _Object Document Mapper_ (ODM) that we’re using to create schemas and models for our application data.
- Sets the database credentials as constants, including the username and password.
- Connects to the database using the [`mongoose.connect` method](https://mongoosejs.com/docs/api.html#connection_Connection).

For more information about the file, please see [Step 3](how-to-integrate-mongodb-with-your-node-application#step-3-%E2%80%94-creating-mongoose-schemas-and-models) of [How To Integrate MongoDB with Your Node Application](how-to-integrate-mongodb-with-your-node-application).

Our first step in modifying the file will be redefining the constants that include sensitive information. Currently, these constants look like this:

~/node\_project/db.js

    ...
    const MONGO_USERNAME = 'sammy';
    const MONGO_PASSWORD = 'your_password';
    const MONGO_HOSTNAME = '127.0.0.1';
    const MONGO_PORT = '27017';
    const MONGO_DB = 'sharkinfo';
    ...

Instead of hardcoding this information, you can use the `process.env` object to capture the runtime values for these constants. Modify the block to look like this:

~/node\_project/db.js

    ...
    const {
      MONGO_USERNAME,
      MONGO_PASSWORD,
      MONGO_HOSTNAME,
      MONGO_PORT,
      MONGO_DB
    } = process.env;
    ...

Save and close the file when you are finished editing.

At this point, you have modified `db.js` to work with your application’s environment variables, but you still need a way to pass these variables to your application. Let’s create an `.env` file with values that you can pass to your application at runtime.

Open the file:

    nano .env

This file will include the information that you removed from `db.js`: the username and password for your application’s database, as well as the port setting and database name. Remember to update the username, password, and database name listed here with your own information:

~/node\_project/.env

    MONGO_USERNAME=sammy
    MONGO_PASSWORD=your_password
    MONGO_PORT=27017
    MONGO_DB=sharkinfo

Note that we have **removed** the host setting that originally appeared in `db.js`. We will now define our host at the level of the Docker Compose file, along with other information about our services and containers.

Save and close this file when you are finished editing.

Because your `.env` file contains sensitive information, you will want to ensure that it is included in your project’s `.dockerignore` and `.gitignore` files so that it does not copy to your version control or containers.

Open your `.dockerignore` file:

    nano .dockerignore

Add the following line to the bottom of the file:

~/node\_project/.dockerignore

    ...
    .gitignore
    .env

Save and close the file when you are finished editing.

The `.gitignore` file in this repository already includes `.env`, but feel free to check that it is there:

    nano .gitignore

~~/node\_project/.gitignore

    ...
    .env
    ...

At this point, you have successfully extracted sensitive information from your project code and taken measures to control how and where this information gets copied. Now you can add more robustness to your database connection code to optimize it for a containerized workflow.

## Step 3 — Modifying Database Connection Settings

Our next step will be to make our database connection method more robust by adding code that handles cases where our application fails to connect to our database. Introducing this level of resilience to your application code is a [recommended practice](https://docs.docker.com/compose/startup-order/) when working with containers using Compose.

Open `db.js` for editing:

    nano db.js

You will see the code that we added earlier, along with the `url` constant for Mongo’s connection URI and the [Mongoose `connect`](https://mongoosejs.com/docs/api.html#mongoose_Mongoose-connect) method:

~/node\_project/db.js

    ...
    const {
      MONGO_USERNAME,
      MONGO_PASSWORD,
      MONGO_HOSTNAME,
      MONGO_PORT,
      MONGO_DB
    } = process.env;
    
    const url = `mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOSTNAME}:${MONGO_PORT}/${MONGO_DB}?authSource=admin`;
    
    mongoose.connect(url, {useNewUrlParser: true});

Currently, our `connect` method accepts an option that tells Mongoose to use Mongo’s [new URL parser](https://mongoosejs.com/docs/deprecations.html). Let’s add a few more options to this method to define parameters for reconnection attempts. We can do this by creating an `options` constant that includes the relevant information, in addition to the new URL parser option. Below your Mongo constants, add the following definition for an `options` constant:

~/node\_project/db.js

    ...
    const {
      MONGO_USERNAME,
      MONGO_PASSWORD,
      MONGO_HOSTNAME,
      MONGO_PORT,
      MONGO_DB
    } = process.env;
    
    const options = {
      useNewUrlParser: true,
      reconnectTries: Number.MAX_VALUE,
      reconnectInterval: 500, 
      connectTimeoutMS: 10000,
    };
    ...

The `reconnectTries` option tells Mongoose to continue trying to connect indefinitely, while `reconnectInterval` defines the period between connection attempts in milliseconds. `connectTimeoutMS` defines 10 seconds as the period that the Mongo driver will wait before failing the connection attempt.

We can now use the new `options` constant in the Mongoose `connect` method to fine tune our Mongoose connection settings. We will also add a [promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises) to handle potential connection errors.

Currently, the Mongoose `connect` method looks like this:

~/node\_project/db.js

    ...
    mongoose.connect(url, {useNewUrlParser: true});

Delete the existing `connect` method and replace it with the following code, which includes the `options` constant and a promise:

~/node\_project/db.js

    ...
    mongoose.connect(url, options).then( function() {
      console.log('MongoDB is connected');
    })
      .catch( function(err) {
      console.log(err);
    });

In the case of a successful connection, our function logs an appropriate message; otherwise it will [`catch`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/catch) and log the error, allowing us to troubleshoot.

The finished file will look like this:

~/node\_project/db.js

    const mongoose = require('mongoose');
    
    const {
      MONGO_USERNAME,
      MONGO_PASSWORD,
      MONGO_HOSTNAME,
      MONGO_PORT,
      MONGO_DB
    } = process.env;
    
    const options = {
      useNewUrlParser: true,
      reconnectTries: Number.MAX_VALUE,
      reconnectInterval: 500,
      connectTimeoutMS: 10000,
    };
    
    const url = `mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOSTNAME}:${MONGO_PORT}/${MONGO_DB}?authSource=admin`;
    
    mongoose.connect(url, options).then( function() {
      console.log('MongoDB is connected');
    })
      .catch( function(err) {
      console.log(err);
    });

Save and close the file when you have finished editing.

You have now added resiliency to your application code to handle cases where your application might fail to connect to your database. With this code in place, you can move on to defining your services with Compose.

## Step 4 — Defining Services with Docker Compose

With your code refactored, you are ready to write the `docker-compose.yml` file with your service definitions. A _service_ in Compose is a running container, and service definitions — which you will include in your `docker-compose.yml` file — contain information about how each container image will run. The Compose tool allows you to define multiple services to build multi-container applications.

Before defining our services, however, we will add a tool to our project called [`wait-for`](https://github.com/Eficode/wait-for) to ensure that our application only attempts to connect to our database once the database startup tasks are complete. This wrapper script uses [`netcat`](how-to-use-netcat-to-establish-and-test-tcp-and-udp-connections-on-a-vps) to poll whether or not a specific host and port are accepting TCP connections. Using it allows you to control your application’s attempts to connect to your database by testing whether or not the database is ready to accept connections.

Though Compose allows you to specify dependencies between services using the [`depends_on` option](https://docs.docker.com/compose/compose-file/#depends_on), this order is based on whether or not the container is running rather than its readiness. Using `depends_on` won’t be optimal for our setup, since we want our application to connect only when the database startup tasks, including adding a user and password to the `admin` authentication database, are complete. For more information on using `wait-for` and other tools to control startup order, please see the relevant [recommendations in the Compose documentation](https://docs.docker.com/compose/startup-order/).

Open a file called `wait-for.sh`:

    nano wait-for.sh

Paste the following code into the file to create the polling function:

~/node\_project/app/wait-for.sh

    #!/bin/sh
    
    # original script: https://github.com/eficode/wait-for/blob/master/wait-for
    
    TIMEOUT=15
    QUIET=0
    
    echoerr() {
      if ["$QUIET" -ne 1]; then printf "%s\n" "$*" 1>&2; fi
    }
    
    usage() {
      exitcode="$1"
      cat << USAGE >&2
    Usage:
      $cmdname host:port [-t timeout] [-- command args]
      -q | --quiet Do not output any status messages
      -t TIMEOUT | --timeout=timeout Timeout in seconds, zero for no timeout
      -- COMMAND ARGS Execute command with args after the test finishes
    USAGE
      exit "$exitcode"
    }
    
    wait_for() {
      for i in `seq $TIMEOUT` ; do
        nc -z "$HOST" "$PORT" > /dev/null 2>&1
    
        result=$?
        if [$result -eq 0] ; then
          if [$# -gt 0] ; then
            exec "$@"
          fi
          exit 0
        fi
        sleep 1
      done
      echo "Operation timed out" >&2
      exit 1
    }
    
    while [$# -gt 0]
    do
      case "$1" in
        *:* )
        HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
        PORT=$(printf "%s\n" "$1"| cut -d : -f 2)
        shift 1
        ;;
        -q | --quiet)
        QUIET=1
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if ["$TIMEOUT" = ""]; then break; fi
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        break
        ;;
        --help)
        usage 0
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage 1
        ;;
      esac
    done
    
    if ["$HOST" = "" -o "$PORT" = ""]; then
      echoerr "Error: you need to provide a host and port to test."
      usage 2
    fi
    
    wait_for "$@"

Save and close the file when you are finished adding the code.

Make the script executable:

    chmod +x wait-for.sh

Next, open the `docker-compose.yml` file:

    nano docker-compose.yml

First, define the `nodejs` application service by adding the following code to the file:

~/node\_project/docker-compose.yml

    version: '3'
    
    services:
      nodejs:
        build:
          context: .
          dockerfile: Dockerfile
        image: nodejs
        container_name: nodejs
        restart: unless-stopped
        env_file: .env
        environment:
          - MONGO_USERNAME=$MONGO_USERNAME
          - MONGO_PASSWORD=$MONGO_PASSWORD
          - MONGO_HOSTNAME=db
          - MONGO_PORT=$MONGO_PORT
          - MONGO_DB=$MONGO_DB 
        ports:
          - "80:8080"
        volumes:
          - .:/home/node/app
          - node_modules:/home/node/app/node_modules
        networks:
          - app-network
        command: ./wait-for.sh db:27017 -- /home/node/app/node_modules/.bin/nodemon app.js

The `nodejs` service definition includes the following options:

- `build`: This defines the configuration options, including the `context` and `dockerfile`, that will be applied when Compose builds the application image. If you wanted to use an existing image from a registry like [Docker Hub](https://hub.docker.com/), you could use the [`image` instruction](https://docs.docker.com/compose/compose-file/#image) instead, with information about your username, repository, and image tag.
- `context`: This defines the build context for the image build — in this case, the current project directory.
- `dockerfile`: This specifies the `Dockerfile` in your current project directory as the file Compose will use to build the application image. For more information about this file, please see [How To Build a Node.js Application with Docker](how-to-build-a-node-js-application-with-docker).
- `image`, `container_name`: These apply names to the image and container.
- `restart`: This defines the restart policy. The default is `no`, but we have set the container to restart unless it is stopped.
- `env_file`: This tells Compose that we would like to add environment variables from a file called `.env`, located in our build context.
- `environment`: Using this option allows you to add the Mongo connection settings you defined in the `.env` file. Note that we are not setting `NODE_ENV` to `development`, since this is [Express’s](https://expressjs.com/) [default](https://github.com/expressjs/express/blob/dc538f6e810bd462c98ee7e6aae24c64d4b1da93/lib/application.js#L71) behavior if `NODE_ENV` is not set. When moving to production, you can set this to `production` to [enable view caching and less verbose error messages](https://expressjs.com/en/advanced/best-practice-performance.html#set-node_env-to-production). Also note that we have specified the `db` database container as the host, as discussed in [Step 2](containerizing-a-node-js-application-for-development-with-docker-compose#step-2-%E2%80%94-configuring-your-application-to-work-with-containers).
- `ports`: This maps port `80` on the host to port `8080` on the container.
- `volumes`: We are including two types of mounts here:

- `networks`: This specifies that our application service will join the `app-network` network, which we will define at the bottom on the file.

- `command`: This option lets you set the command that should be executed when Compose runs the image. Note that this will override the `CMD` instruction that we set in our application `Dockerfile`. Here, we are running the application using the `wait-for` script, which will poll the `db` service on port `27017` to test whether or not the database service is ready. Once the readiness test succeeds, the script will execute the command we have set, `/home/node/app/node_modules/.bin/nodemon app.js`, to start the application with `nodemon`. This will ensure that any future changes we make to our code are reloaded without our having to restart the application.

Next, create the `db` service by adding the following code below the application service definition:

~/node\_project/docker-compose.yml

    ...
      db:
        image: mongo:4.1.8-xenial
        container_name: db
        restart: unless-stopped
        env_file: .env
        environment:
          - MONGO_INITDB_ROOT_USERNAME=$MONGO_USERNAME
          - MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD
        volumes:  
          - dbdata:/data/db   
        networks:
          - app-network  

Some of the settings we defined for the `nodejs` service remain the same, but we’ve also made the following changes to the `image`, `environment`, and `volumes` definitions:

- `image`: To create this service, Compose will pull the `4.1.8-xenial` [Mongo image](https://hub.docker.com/_/mongo) from Docker Hub. We are pinning a particular version to avoid possible future conflicts as the Mongo image changes. For more information about version pinning, please see the Docker documentation on [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).
- `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`: The `mongo` image makes these [environment variables](https://docs.docker.com/samples/library/mongo/#environment-variables) available so that you can modify the initialization of your database instance. `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` together create a `root` user in the `admin` authentication database and ensure that authentication is enabled when the container starts. We have set `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` using the values from our `.env` file, which we pass to the `db` service using the `env_file` option. Doing this means that our `sammy` application user will be a [`root` user](https://docs.mongodb.com/manual/reference/built-in-roles/#root) on the database instance, with access to all of the administrative and operational privileges of that role. When working in production, you will want to create a dedicated application user with appropriately scoped privileges. **Note:** Keep in mind that these variables will not take effect if you start the container with an existing data directory in place.
- `dbdata:/data/db`: The named volume `dbdata` will persist the data stored in Mongo’s [default data directory](https://docs.mongodb.com/manual/reference/configuration-options/#storage.dbPath), `/data/db`. This will ensure that you don’t lose data in cases where you stop or remove containers.

We’ve also added the `db` service to the `app-network` network with the `networks` option.

As a final step, add the volume and network definitions to the bottom of the file:

~/node\_project/docker-compose.yml

    ...
    networks:
      app-network:
        driver: bridge
    
    volumes:
      dbdata:
      node_modules:  

The user-defined bridge network `app-network` enables communication between our containers since they are on the same Docker daemon host. This streamlines traffic and communication within the application, as it opens all ports between containers on the same bridge network, while exposing no ports to the outside world. Thus, our `db` and `nodejs` containers can communicate with each other, and we only need to expose port `80` for front-end access to the application.

Our top-level `volumes` key defines the volumes `dbdata` and `node_modules`. When Docker creates volumes, the contents of the volume are stored in a part of the host filesystem, `/var/lib/docker/volumes/`, that’s managed by Docker. The contents of each volume are stored in a directory under `/var/lib/docker/volumes/` and get mounted to any container that uses the volume. In this way, the shark information data that our users will create will persist in the `dbdata` volume even if we remove and recreate the `db` container.

The finished `docker-compose.yml` file will look like this:

~/node\_project/docker-compose.yml

    version: '3'
    
    services:
      nodejs:
        build:
          context: .
          dockerfile: Dockerfile
        image: nodejs
        container_name: nodejs
        restart: unless-stopped
        env_file: .env
        environment:
          - MONGO_USERNAME=$MONGO_USERNAME
          - MONGO_PASSWORD=$MONGO_PASSWORD
          - MONGO_HOSTNAME=db
          - MONGO_PORT=$MONGO_PORT
          - MONGO_DB=$MONGO_DB
        ports:
          - "80:8080"
        volumes:
          - .:/home/node/app
          - node_modules:/home/node/app/node_modules
        networks:
          - app-network
        command: ./wait-for.sh db:27017 -- /home/node/app/node_modules/.bin/nodemon app.js 
    
      db:
        image: mongo:4.1.8-xenial
        container_name: db
        restart: unless-stopped
        env_file: .env
        environment:
          - MONGO_INITDB_ROOT_USERNAME=$MONGO_USERNAME
          - MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASSWORD
        volumes:     
          - dbdata:/data/db
        networks:
          - app-network  
    
    networks:
      app-network:
        driver: bridge
    
    volumes:
      dbdata:
      node_modules:  

Save and close the file when you are finished editing.

With your service definitions in place, you are ready to start the application.

## Step 5 — Testing the Application

With your `docker-compose.yml` file in place, you can create your services with the [`docker-compose up`](https://docs.docker.com/compose/reference/up/) command. You can also test that your data will persist by stopping and removing your containers with [`docker-compose down`](https://docs.docker.com/compose/reference/down/).

First, build the container images and create the services by running `docker-compose up` with the `-d` flag, which will then run the `nodejs` and `db` containers in the background:

    docker-compose up -d

You will see output confirming that your services have been created:

    Output...
    Creating db ... done
    Creating nodejs ... done

You can also get more detailed information about the startup processes by displaying the log output from the services:

    docker-compose logs 

You will see something like this if everything has started correctly:

    Output...
    nodejs | [nodemon] starting `node app.js`
    nodejs | Example app listening on 8080!
    nodejs | MongoDB is connected
    ...
    db | 2019-02-22T17:26:27.329+0000 I ACCESS [conn2] Successfully authenticated as principal sammy on admin

You can also check the status of your containers with [`docker-compose ps`](https://docs.docker.com/compose/reference/ps/):

    docker-compose ps

You will see output indicating that your containers are running:

    Output Name Command State Ports        
    ----------------------------------------------------------------------
    db docker-entrypoint.sh mongod Up 27017/tcp           
    nodejs ./wait-for.sh db:27017 -- ... Up 0.0.0.0:80->8080/tcp

With your services running, you can visit `http://your_server_ip` in the browser. You will see a landing page that looks like this:

![Application Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Click on the **Get Shark Info** button. You will see a page with an entry form where you can enter a shark name and a description of that shark’s general character:

![Shark Info Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_form.png)

In the form, add a shark of your choosing. For the purpose of this demonstration, we will add `Megalodon Shark` to the **Shark Name** field, and `Ancient` to the **Shark Character** field:

![Filled Shark Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_filled.png)

Click on the **Submit** button. You will see a page with this shark information displayed back to you:

![Shark Output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_added.png)

As a final step, we can test that the data you’ve just entered will persist if you remove your database container.

Back at your terminal, type the following command to stop and remove your containers and network:

    docker-compose down

Note that we are _not_ including the `--volumes` option; hence, our `dbdata` volume is not removed.

The following output confirms that your containers and network have been removed:

    OutputStopping nodejs ... done
    Stopping db ... done
    Removing nodejs ... done
    Removing db ... done
    Removing network node_project_app-network

Recreate the containers:

    docker-compose up -d

Now head back to the shark information form:

![Shark Info Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_form.png)

Enter a new shark of your choosing. We’ll go with `Whale Shark` and `Large`:

![Enter New Shark](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_docker_dev/whale_shark.png)

Once you click **Submit** , you will see that the new shark has been added to the shark collection in your database without the loss of the data you’ve already entered:

![Complete Shark Collection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_docker_dev/persisted_data.png)

Your application is now running on Docker containers with data persistence and code synchronization enabled.

## Conclusion

By following this tutorial, you have created a development setup for your Node application using Docker containers. You’ve made your project more modular and portable by extracting sensitive information and decoupling your application’s state from your application code. You have also configured a boilerplate `docker-compose.yml` file that you can revise as your development needs and requirements change.

As you develop, you may be interested in learning more about designing applications for containerized and [Cloud Native](https://github.com/cncf/toc/blob/master/DEFINITION.md) workflows. Please see [Architecting Applications for Kubernetes](architecting-applications-for-kubernetes) and [Modernizing Applications for Kubernetes](modernizing-applications-for-kubernetes) for more information on these topics.

To learn more about the code used in this tutorial, please see [How To Build a Node.js Application with Docker](how-to-build-a-node-js-application-with-docker) and [How To Integrate MongoDB with Your Node Application](how-to-integrate-mongodb-with-your-node-application). For information about deploying a Node application with an [Nginx](https://www.nginx.com/) reverse proxy using containers, please see [How To Secure a Containerized Node.js Application with Nginx, Let’s Encrypt, and Docker Compose](how-to-secure-a-containerized-node-js-application-with-nginx-let-s-encrypt-and-docker-compose).
