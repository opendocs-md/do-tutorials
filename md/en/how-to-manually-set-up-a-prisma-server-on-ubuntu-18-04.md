---
author: Etel Sverdlov
date: 2019-01-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manually-set-up-a-prisma-server-on-ubuntu-18-04
---

# How to Manually Set Up a Prisma Server on Ubuntu 18.04

_The author selected [the Electronic Frontier Foundation](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Prisma](https://www.prisma.io/) is a data layer that replaces traditional object-relational mapping tools (ORMs) in your application. Offering support for both building GraphQL servers as well as REST APIs, Prisma simplifies database access with a focus on _type safety_ and enables _declarative database migrations_. Type safety helps reduce potential code errors and inconsistencies, while the declarative database migrations allow you to store your datamodel in version control. These features help developers reduce time spent focused on setting up database access, migrations, and data management workflows.

You can deploy the Prisma server, which acts as a proxy for your database, in a number of ways and host it either remotely or locally. Through the Prisma service you can access your data and connect to your database with the GraphQL API, which allows realtime operations and the ability to create, update, and delete data. GraphQL is a query language for APIs that allows users to send queries to access the exact data they require from their server. The Prisma server is a standalone component that sits on top of your database.

In this tutorial you will manually install a Prisma server on Ubuntu 18.04 and run a test GraphQL query in the [GraphQL Playground](https://www.prisma.io/blog/introducing-graphql-playground-f1e0a018f05d/). You will host your Prisma setup code and development locally — where you will actually build your application — while running Prisma on your remote server. By running through the installation manually, you will have a deeper understanding and customizability of the underlying infrastructure of your setup.

While this tutorial covers the manual steps for deploying Prisma on an Ubuntu 18.04 server, you can also accomplish this in a more automated way with Docker Machine by following this [tutorial](https://www.prisma.io/tutorials/deploy-prisma-to-digitalocean-with-docker-machine-ct06/) on Prisma’s site.

**Note** : The setup described in this section does not include features you would normally expect from production-ready servers, such as automated backups and active failover.

## Prerequisites

To complete this tutorial, you will need:

- An Ubuntu 18.04 server set up by following the [Initial Server Setup Guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user.
- Docker installed on your server. You can achieve this by following Step 1 of the [Docker Installation on Ubuntu 18.04 tutorial](how-to-install-and-use-docker-on-ubuntu-18-04#step-1-%E2%80%94-installing-docker).
- Docker Compose installed. You can find instructions for this in Step 1 of [Installing Docker Compose](how-to-install-docker-compose-on-ubuntu-18-04#step-1-%E2%80%94-installing-docker-compose).
- Node.js installed on your server. You can accomplish this by going through the PPA section of the [Installing Node.js tutorial](how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa).

## Step 1 — Starting the Prisma Server

The Prisma CLI is the primary tool used to deploy and manage your Prisma services. To start the services, you need to set up the required infrastructure, which includes the Prisma server and a database for it to connect to.

Docker Compose allows you to manage and run multi-container applications. You’ll use it to set up the infrastructure required for the Prisma service.

You will begin by creating the `docker-compose.yml` file to store the Prisma service configuration on your server. You’ll use this file to automatically spin up Prisma, an associated database, and configure the necessary details, all in one step. Once the file is spun up with Docker Compose, it will configure the passwords for your databases, so be sure to replace the passwords for `managementAPIsecret` and `MYSQL_ROOT_PASSWORD` with something secure. Run the following command to create and edit the `docker-compose.yml` file:

    sudo nano docker-compose.yml

Add the following content to the file to define the services and volumes for the Prisma setup:

docker-compose.yml

    version: "3"
    services:
      prisma:
        image: prismagraphql/prisma:1.20
        restart: always
        ports:
          - "4466:4466"
        environment:
          PRISMA_CONFIG: |
            port: 4466
            managementApiSecret: my-secret
            databases:
              default:
                connector: mysql
                host: mysql
                port: 3306
                user: root
                password: prisma
                migrations: true
      mysql:
        image: mysql:5.7
        restart: always
        environment:
          MYSQL_ROOT_PASSWORD: prisma
        volumes:
          - mysql:/var/lib/mysql
    volumes:
      mysql:

This configuration does the following:

- It launches two services: `prisma-db` and `db`.
- It pulls in the latest version of Prisma. As of this writing, that is Prisma 1.20.
- It sets the ports Prisma will be available on and specifies all of the credentials to connect to the MySQL database in the `databases` section.

The `docker-compose.yml` file sets up the `managementApiSecret`, which prevents others from accessing your data with knowledge of your endpoint. If you are using this tutorial for anything but a test deployment, you should change the `managementAPIsecret` to something more secure. When you do, be sure to remember it so that you can enter it later during the `prisma init` process.

This file also pulls in the MySQL Docker image and sets those credentials as well. For the purposes of this tutorial, this Docker Compose file spins up a MySQL image, but you can also use PostgreSQL with Prisma. Both Docker images are available on Docker hub:

- [MySQL](https://hub.docker.com/_/mysql/)
- [PostgreSQL](https://hub.docker.com/_/postgres/postgres).

Save and exit the file.

Now that you have saved all of the details, you can start the Docker containers. The `-d` command tells the containers to run in detached mode, meaning they’ll run in the background:

    sudo docker-compose up -d

This will fetch the Docker images for both `prisma` and `mysql`. You can verify that the Docker containers are running with the following command:

    sudo docker ps

You will see an output that looks similar to this:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    24f4dd6222b1 prismagraphql/prisma:1.12 "/bin/sh -c /app/sta…" 15 seconds ago Up 1 second 0.0.0.0:4466->4466/tcp root_prisma_1
    d8cc3a393a9f mysql:5.7 "docker-entrypoint.s…" 15 seconds ago Up 13 seconds 3306/tcp root_mysql_1

With your Prisma server and database set up, you are now ready to work locally to deploy the Prisma service.

## Step 2 — Installing Prisma Locally

The Prisma server provides the runtime environments for your Prisma services. Now that you have your Prisma server started, you can deploy your Prisma service. You will run these steps locally, not on your server.

To start, create a separate folder to contain all of the Prisma files:

    mkdir prisma

Then move into that folder:

    cd prisma

You can install Prisma with Homebrew if you’re using MacOS. To do this, run the following command to add the Prisma repository:

    brew tap prisma/prisma

You can then install Prisma with the following command:

    brew install prisma

Or alternately, with `npm`:

    npm install -g prisma

With Prisma installed locally, you are ready to bootstrap the new Prisma service.

## Step 3 — Creating the Configuration for a New Prisma Service

After the installation, you can use `prisma init` to create the file structure for a new Prisma database API, which generates the files necessary to build your application with Prisma. Your endpoint will automatically be in the `prisma.yml` file, and `datamodel.prisma` will already contain a sample datamodel that you can query in the next step. The datamodel serves as the basis for your Prisma API and specifies the model for your application. At this point, you are only creating the files and the sample datamodel. You are not making any changes to the database until you run `prisma deploy` later in this step.

Now you can run the following command locally to create the new file structure:

    prisma init hello-world

After you run this command you will see an interactive prompt. When asked, select, `Use other server` and press `ENTER`:

    Output Set up a new Prisma server or deploy to an existing server?
    
      You can set up Prisma for local development (based on docker-compose)
      Use existing database Connect to existing database
      Create new database Set up a local database using Docker
    
      Or deploy to an existing Prisma server:
      Demo server Hosted demo environment incl. database (requires login)
    ❯ Use other server Manually provide endpoint of a running Prisma server

You will then provide the endpoint of your server that is acting as the Prisma server. It will look something like: `http://SERVER_IP_ADDRESS:4466`. It is key that the endpoint begins with http (or https) and has the port number indicated.

    OutputEnter the endpoint of your Prisma server http://SERVER_IP_ADDRESS:4466

For the management API secret, enter in the phrase or password that you indicated earlier in the configuration file:

    OutputEnter the management API secret my-secret

For the subsequent options, you can choose the default variables by pressing `ENTER` for the `service name` and `service stage`:

    OutputChoose a name for your service hello-world
    Choose a name for your stage dev

You will also be given a choice on a programming language for the Prisma client. In this case, you can choose your preferred language. You can read more about the client [here](https://www.prisma.io/blog/prisma-client-preview-ahph4o1umail).

    Output Select the programming language for the generated Prisma client (Use arrow keys)
    ❯ Prisma TypeScript Client
      Prisma Flow Client
      Prisma JavaScript Client
      Prisma Go Client
      Don't generate

Once you have completed the prompt, you will see the following output that confirms the selections you made:

    Output Created 3 new files:
    
      prisma.yml Prisma service definition
      datamodel.prisma GraphQL SDL-based datamodel (foundation for database)
      .env Env file including PRISMA_API_MANAGEMENT_SECRET
    
    Next steps:
    
      1. Open folder: cd hello-world
      2. Deploy your Prisma service: prisma deploy
      3. Read more about deploying services:
         http://bit.ly/prisma-deploy-services
    
    

Move into the `hello-world` directory:

    cd hello-world

Sync these changes to your server with `prisma deploy`. This sends the information to the Prisma server from your local machine and creates the Prisma service on the Prisma server:

    prisma deploy

**Note** : Running `prisma deploy` again will update your Prisma service.

Your output will look something like:

    OutputCreating stage dev for service hello-world ✔
    Deploying service `hello-world` to stage 'dev' to server 'default' 468ms
    
    Changes:
    
      User (Type)
      + Created type `User`
      + Created field `id` of type `GraphQLID!`
      + Created field `name` of type `String!`
      + Created field `updatedAt` of type `DateTime!`
      + Created field `createdAt` of type `DateTime!`
    
    Applying changes 716ms
    
    Your Prisma GraphQL database endpoint is live:
    
      HTTP: http://SERVER_IP_ADDRESS:4466/hello-world/dev
      WS: ws://SERVER_IP_ADDRESS:4466/hello-world/dev
    

The output shows that Prisma has updated your database according to your datamodel (created in the `prisma init` step) with a _type_ `User`. Types are an essential part of a datamodel; they represent an item from your application, and each type contains multiple fields. For your datamodel the associated fields describing the user are: the user’s ID, name, time they were created, and time they were updated.

If you run into issues at this stage and get a different output, double check that you entered all of the fields correctly during the interactive prompt. You can do so by reviewing the contents of the `prisma.yml` file.

With your Prisma service running, you can connect to two different endpoints:

- The management interface, available at `http://SERVER_IP_ADDRESS:4466/management`, where you can manage and deploy Prisma services.

- The GraphQL API for your Prisma service, available at `http://SERVER_IP_ADDRESS:4466/hello-world/dev`.

![GraphQL API exploring _Your Project_](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prisma_1804/prisma_step_four_project.png)

You have successfully set up and deployed your Prisma server. You can now explore queries and mutations in GraphQL.

## Step 4 — Running an Example Query

To explore another Prisma use case, you can experiment with the [GraphQL playground](https://github.com/prisma/graphql-playground) tool, which is an open-source GraphQL integrated development environment (IDE) on your server. To access it, visit your endpoint in your browser from the previous step:

    http://SERVER_IP_ADDRESS:4466/hello-world/dev

A _mutation_ is a GraphQL term that describes a way to modify — create, update, or delete (CRUD) — data in the backend via GraphQL. You can send a mutation to create a new user and explore the functionality. To do this, run the following mutation in the left-hand side of the page:

    mutation {
      createUser(data: { name: "Alice" }) {
        id
        name
      }
    }

Once you press the play button, you will see the results on the right-hand side of the page.  
 ![GraphQL Playground Creating a New User](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prisma_1804/prisma_step_five_user.png)

Subsequently, if you want to look up a user by using the `ID` column in the database, you can run the following query:

    query {
      user(where: { id: "cjkar2d62000k0847xuh4g70o" }) {
        id
        name
      }
    }

You now have a Prisma server and service up and running on your server, and you have run test queries in GraphQL’s IDE.

## Conclusion

You have a functioning Prisma setup on your server. You can see some additional Prisma use cases and next steps in the [Getting Started Guide](https://www.prisma.io/docs/1.20/get-started/01-setting-up-prisma-new-database-JAVASCRIPT-a002/) or explore Prisma’s feature set in the [Prisma Docs](https://www.prisma.io/docs/). Once you have completed all of the steps in this tutorial, you have a number of options to verify your connection to the database, one possibility is using the [Prisma Client](https://www.prisma.io/client/client-javascript).
