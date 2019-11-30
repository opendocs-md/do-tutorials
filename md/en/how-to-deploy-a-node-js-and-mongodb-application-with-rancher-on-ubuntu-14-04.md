---
author: James Kolce
date: 2016-07-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-node-js-and-mongodb-application-with-rancher-on-ubuntu-14-04
---

# How To Deploy a Node.js and MongoDB Application with Rancher on Ubuntu 14.04

## Introduction

[Rancher](http://rancher.com/rancher/) is an open source, self-hosted, and complete platform to run and easily manage containers in production. Being a Docker image itself, a Rancher server will work on any Linux host where Docker is available.

Some of the key features that make Rancher an attractive solution are:

- **Cross-host networking** : All the servers added to Rancher are linked allowing secure communication between containers.
- **Load balancing** : A load balancing service is included to distribute workloads between containers or even across multiple clouds.
- **Service discovery** : Rancher includes an internal DNS system enabling containers and services to be identified by name so they can be used within other services on the network.
- **Infrastructure management** : With Rancher you can add, monitor, and manage computing resources from any cloud provider.
- **Orchestration engines** : Rancher is the only container management platform that supports the most popular container orchestration frameworks including Cattle, Swarm, Kubernetes, and Mesos. So if you already have your infrastructure working with one of those frameworks then you will be able to use Rancher with ease.
- **Open Source** : Rancher is free, open, and transparent. You have absolute control of your infrastructure.

In this guide, you will build a Rancher cluster to deploy a load-balanced [Node.js](http://nodejs.org) application, with support for data storage using [MongoDB](https://www.mongodb.org).

At the end of this tutorial, you’ll have four load-balanced instances of a simple Node.js application and a MongoDB server with a separated data container for persistent storage.

## Prerequisites

- One 1GB Ubuntu 14.04 Droplet with Rancher installed. We’ll use Rancher to create six additional Droplets, each with 1GB of RAM. Follow the prerequisites and Step 1 of [How To Manage Your Multi-Node Deployments with Rancher and Docker Machine on Ubuntu 14.04](how-to-manage-your-multi-node-deployments-with-rancher-and-docker-machine-on-ubuntu-14-04) to set up your initial Droplet with Rancher.
- A Node.js application that uses MongoDB for data storage. We provide a simple example using the [Hapi.js](http://hapijs.com/) library, which you can use in case you don’t have your own application ready yet. You can find this example application in [this Github repository](https://github.com/do-community/hapi-example). 
- Git installed on your local machine, so you can clone the example application. Follow the [official Git installation documentation](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) if you need to fulfill this prerequisite.
- Docker installed on your local machine, so you can build the application image we’ll deploy. You can follow [the official documentation](https://docs.docker.com/engine/installation/) for this.
- An account on [Docker Hub](https://hub.docker.com/), which is a free and public registry for Docker images. This is where we are going to host our application code so we can deploy it to multiple hosts using Rancher. You will need your Docker Hub username to complete the steps in this tutorial.
- A DigitalOcean Access Token with both Read and Write access, which you can generate by visiting the [Applications & API](https://cloud.digitalocean.com/settings/api/tokens) page. Copy this token, as you will need to enter it in Rancher to create additional hosts.

You should also have basic knowledge of [Docker concepts](https://docs.docker.com/engine/reference/glossary/) like containers, images, and Dockerfiles. See [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04).

## Step One — Exploring the Node.js Application

For this tutorial, we’ll use a simple Node.js application based on the Hapi.js framework that receives a message, records it, and lists all the messages previously submitted. Let’s explore how the application works and how it receives configuration values so we can set those values with Docker when we create our image.

You’ll prepare the application and the Docker image on your local development machine, rather than a server.

Clone the example application to your local machine using the following command:

    git clone https://github.com/do-community/hapi-example

Then navigate into the project directory:

    cd hapi-example

Let’s look at the main file of the application, `server.js`. It contains the MongoDB connection and the code to initialize the server. Open this file in your local text editor and you’ll see the following contents:

server.js

    const Hapi = require('hapi');
    const mongojs = require('mongojs');
    
    // Loads environment variables
    // Used only in development
    require('dotenv').config({silent: true});
    
    const server = new Hapi.Server();
    server.connection({ port: process.env.PORT || 3000 });
    
    // Connect with the database
    server.app.db = mongojs(process.env.MONGO_HOST + '/api');
    
    // Add the routes
    server.register(require('./routes'), (err) => {
    
      if (err) {
        console.error('Failed to load plugin:', err);
      }
    
      // Start the server
      server.start((err) => {
        if (err) {
          throw err;
        }
    
        console.log('Server running at:', server.info.uri);
      });
    });

The code for the routes is encapsulated as a Hapi.js plugin to save space in this tutorial, but if you’re curious, you can look in the file `routes.js`.

The critical parts of the `server.js` file are as follows:

    require('dotenv').config({silent: true});

This uses the `dotenv` Node.js package to load our environment variables from a `.env` file. You can review the documentation for the `dotenv` package in its [Github repository](https://github.com/motdotla/dotenv) if you’re interested in how it works. We save the variables in this file only for the development process; it’s easier than manually writing the variables in the terminal. In production, we are going to get the variables from Docker, via Rancher.

Next we set the port for the server, using an environment variable called `PORT`, with a fallback value of `3000`, in case the variable isn’t defined:

    server.connection({ port: process.env.PORT || 3000 });

Port `3000` is a common convention for Node.js applications. This value can be changed if necessary; the only requirement is that it should be [above `1023` and below `65535`](http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml).

Finally, before loading the routes and starting the server, we connect to the MongoDB server, using an environment variable called `MONGO_HOST`:

    server.app.db = mongojs(process.env.MONGO_HOST + '/api');

This environment value will be defined through Rancher with the host name of the MongoDB server once we create the MongoDB containers. The value `api` is the name of the database we are going to connect to, and it will be set up automatically if it doesn’t exist.

Now that you have some background on what the app is looking for, and how we configure its port and database connection, let’s bring Docker into the picture.

## Step 2 — Building the Docker Image

Rancher uses Docker images to deploy applications to servers, so let’s create a Docker image for our application. In order to build a Docker image for our app, we need a file called `Dockerfile` which contains a series of steps that Docker will follow when building the image. This file is already included in the application repository that you cloned. Let’s look at its contents to understand how it works. Open it in your text editor and you’ll see the following code:

Dockerfile

    FROM node:6
    MAINTAINER James Kolce <contact@jameskolce.com>
    
    RUN mkdir -p /usr/api
    COPY . /usr/api
    WORKDIR /usr/api
    RUN npm install --production
    
    ENV PORT 3000
    EXPOSE $PORT
    
    CMD ["npm", "start"]

Let’s look at each step in detail. First, we see this line:

    FROM node:6

This line declares that our image is built on top of the [official Node.js image](https://hub.docker.com/_/node/) from Docker Hub, and we are selecting version 6 of Node.js since our app makes use of some ES6 features only available in that version or higher. It’s recommended practice to choose a particular version instead of just using **latest** in production so you avoid any changes that may break your app.

After that line, we set up our working directory:

    RUN mkdir -p /usr/api
    COPY . /usr/api
    WORKDIR /usr/api

First we run the `mkdir` command to create a new directory called `/usr/api`, which is where our application will live. The `-p` flag means that `mkdir` will create intermediate directories as required. Then we copy the contents of the image to that directory. Then we set this new directory as our working directory so subsequent commands will be run from that directory.

The next line runs the `npm` command and installs the production dependencies for our app.

    RUN npm install --production

Next, we see these two lines:

    ENV PORT 3000
    EXPOSE $PORT

The first line defines an environment variable called `PORT` which our application will use for its listening port. Just in case this variable isn’t defined, we set `3000` as the default value. Then we expose that port so we can have access to it from outside of the container. Using an environment variable makes this easier to change without having to rewrite our application code. And remember, our application is designed to use these environment variables.

The last step in our Dockerfile runs our Node.js server:

    CMD ["npm", "start"]

To create the Docker image of our application from this file, ensure you are in the `hapi-example` folder in your terminal and execute the following command:

    docker build -t your_dockerhub_username/hapi-example .

This command creates a Docker image using our `Dockerfile`. Note the dot at the end of the command. This specifies the path to the `Dockerfile`, which is in the current folder. The `-t` flag sets a tag for our image, and we’ll use `your_dockerhub_username/hapi-example` for the tag, which is a label we apply to the image so we can use it to create container instances from the image. We use the Docker Hub username as a prefix, as we are preparing to publish this image once we test it, and the local tag of the Docker image must match the repository name on Docker Hub.

If you receive the message `Cannot connect to the Docker daemon. Is the docker daemon running on this host?` when you run this command, ensure the Docker app is running and that Docker is started. Then run the command again.

Now let’s test the image we just built so we can be sure that everything is working as expected. As you saw earlier, our application relies on MongoDB, so let’s create a MongoDB container our app can use to store its data. Run the following command to create and start a MongoDB container based on the official MongoDB Docker image:

    docker run --name testdb -p 27017:27017 -d mongo:3

We assign a temporary name to the container with the `--name` option; we will use that name to stop the server when we finish testing the application. We also bind the host port `27017` to the port exposed by the container so we can test that MongoDB is running by using our local web browser. Finally, we specify the image we want to use. It’s a good idea to use the same version of MongoDB that the application was developed with to assure that everything works as expected, so in this case we specify version `3`.

After executing that command, visit `http://localhost:27017` in your browser and you’ll see the message: `It looks like you are trying to access MongoDB over HTTP on the native driver port` which means that MongoDB is running.

Now run your application container and link it to the MongoDB container by running this command:

    docker run --name hapi-app -p 3000:3000 -d -e MONGO_HOST=testdb --link testdb your_dockerhub_username/hapi-example

This command is similar to the command we used to start the MongoDB container, but this time we use our application image (`your_dockerhub_username/hapi-example`) and map port `3000` of our host with the port exposed by the container. This is the same port we used when we created the `Dockerfile`. Also, we add an environment variable called `MONGO_HOST` that specifies the name of our MongoDB container which will be used by our application to connect to the database server. The `--link testdb` parameter lets us use the name of the database container as a host inside of our application’s container.

After running the command, test the application by visiting `http://localhost:3000` in your browser. It should show an empty page **without any errors**.

You might also see an empty array (`[]`) or the JSON view on Firefox when you visit `http://localhost:3000`. Either of these outcomes is also okay.

Now that we’ve proven the Docker image works locally, let’s stop and delete our local containers. Keep in mind that deleting a container is not the same as deleting an image. Our image is going to remain intact so we can recreate the container later, or push the image to Rancher, which is what we’ll do after we clean up our local environment.

First, stop the database container by using its name you defined previously:

    docker stop testdb

Now that the container is stopped, you can delete it from your machine since you won’t need it anymore:

    docker rm testdb

Repeat the same steps for your application container. First stop it, then remove it.

    docker stop hapi-app && docker rm hapi-app

Now let’s publish the working image so we can use it with Rancher.

## Step 3 — Uploading the Image to Docker Hub

To deploy containers using Rancher we need access to a _Docker registry_, where we can create a repository to store our Docker image. We’ll use [Docker Hub](https://hub.docker.com/) which is the official registry for Docker. Docker Hub is free to use for public repositories.

Log in to Docker Hub with your username and password. Once logged in, click the **Create Repository** button at the right side of the screen. Fill in the fields as follows:

- **Name (required)**: The name of your repository, in this case, it’s `hapi-example`.
- **Description** : A short description to identify your image quickly in the future.
- **Full Description** : You can add a markdown document here as a reference for your image but since our application is pretty simple you can leave this field empty.
- **Visibility** : You can set your images as private where only you will have access to it, or as public where everybody can use your image. For this tutorial, create a public repository.

If you set your repository as private, you will have to add your Docker Hub credentials in the **Infrastructure -\> Registries** page in the Rancher UI.

After all the required fields are filled in, click the **Create** button. When the process is done you will be redirected to your new repository site.

In order to upload your Docker image, you must log in to Docker Hub through the `docker` command. Back in your terminal, execute the following command:

    docker login

You’ll be prompted to enter your username and password. Like most CLI tools, you won’t see your password as you type it.

Once you’re logged in, upload the image to Docker Hub with the following command which uploads all the files to the repository:

    docker push your_dockerhub_username/hapi-example

Pushing an image may take several minutes depending on your local internet connection. Once the image is successfully published, we can set up our hosts using Rancher.

## Step 4 — Creating and Labeling the Host Servers

Let’s use Rancher to create all of the hosts we’ll need to deploy our services. We’ll need two for the Node.js application, one for the MongoDB server, and one for the load balancer. We’ll do all of this within the Rancher UI using DigitalOcean’s API.

Visit your Rancher interface in your browser by visiting `http://your_rancher_ip_address` and follow these steps to create the four hosts we’ll need:

1. Go to **Infrastructure \> Hosts** and click the **Add Host** button at the top of the page.
2. Select **DigitalOcean** as the host provider.
3. Move the **Quantity** slider to **4** hosts.
4. Assign a name. Enter `host`, which will automatically generate names from `host1` to `host4`.
5. Paste your DigialOcean Application Token that you generated into the **Access Token** field.
6. For **Image** , use the default value of **ubuntu-14-04-x64**.
7. For **Size** , use the default value of **1GB**.
8. Click the **Create** button and wait a couple of minutes while the servers are created and added to Rancher.

Once Rancher finishes creating all of the hosts, we’ll add a label to each one of them to classify their type so we can organize where we are going to put each of our components. Labeling hosts also lets us scale our servers depending of their type. For example, if we are getting too much demand for our application, we can increase the number of servers of that type and Rancher will automatically deploy the appropriate Docker container for us. The labels that we are going to create are: `loadbalancer`, `application` and `database`.

Let’s create the first label, `loadbalancer`.

1. Go to **Infrastructure \> Hosts** and select the first host, `host1`.
2. Click the **Options** button (the icon with three dots) and select the **Edit** option.
3. Click the **Add Label** button and in the **Key** input enter the word `type`, and then enter `loadbalancer` in the **Value** input.
4. Click the **Save** button.

Next, label the application hosts. Repeat the previous process with the next two hosts but this time use `application` in the **Value** input.

For the last host, repeat the process again but use `database` in the **Value** input.

All four hosts should now have labels, so let’s set up the services. We’ll start with the database.

## Step 5 — Deploying the MongoDB Server

We’ll use the official MongoDB Docker image on Docker Hub to deploy our database server. The MongoDB container will also have a [sidekick](http://docs.rancher.com/rancher/v1.0/zh/rancher-compose/#sidekicks) container to store all of our data. Both containers will be deployed on the host labeled as `database`.

To do that, follow these steps in the Rancher user interface:

1. Select the **Stacks** menu, choose the **User** option, and then click the **Add Service** button.
2. In the **Add Service** page, ensure the **Scale** slider is set to **Run 1 container**.
3. For the name of the service, use `MongoDB`.
4. For the image, enter `mongo:3`.
5. Click the **Add Sidekick Container** button in the top section.
6. Name this new container `Data`. This container will be used as a volume to store the MongoDB data.
7. Since we are going to use this container for data only, use the `busybox` image.
8. In the **Command** tab below, switch the **Autorestart** option to **Never (Start Once)**, because we will use this container only for storage.
9. Switch to the **Volumes** tab and add a new volume by clicking the **+** button and enter `/data/db` into the text field that appears. This is the default path where MongoDB stores data.
10. Switch to the **Scheduling** tab and add a new scheduling rule with the following parameters: `The Host must have a host label of type = database`. Use the dropdowns to help you create this rule.
11. Go back and click the **MongoDB** service tab, and then scroll down to the **Command** tab, and set the **Autorestart** option to **Always**.
12. Switch to the **Volumes** tab and select **Data** in the **Volumes From** option.
13. Switch to the **Scheduling** tab and add a new scheduling rule with the following parameters: `The Host must have a host label of type = database`
14. Finally, click the **Create** button at the bottom and wait for a couple of minutes while the service is activated.

Now let’s configure the application service.

## Step 6 — Deploying the Node.js Server

We’ll use a similar approach to deploy the Node.js application we previously prepared. The image we stored on Docker Hub will be deployed on the hosts labeled `application`, and will be linked to the MongoDB service to store and access data. So, follow these steps in the Rancher user interface:

1. Select the **Stacks** menu, choose the **User** option, and then click the **Add Service** button.
2. In the **Scale** section, select the option **Always run one instance of this container on every host**.
3. The name we are going to use for this service is `NodeJS`.
4. For the image we’ll use the one we deployed to Docker Hub. Enter `your_dockerhub_username/hapi-example`. 
5. In the **Service links** section, select **Destination Service** and choose **MongoDB**. Then select **As name** and enter `db`, so our `NodeJS` service can have access to the MongoDB service.
6. In the **Command** tab on the bottom of the page, select **Add Environment Variable** and add a variable named `MONGO_HOST` with the value of `db`, which maps to the destination service name we used in the previous step. Remember that our application relies on this environment variable to locate the database server.
7. Switch to the **Scheduling** tab, click the **Add Scheduling Rule** button and use the dropdowns to construct a rule that says `The Host must have a host label of type = application`.
8. Finally, click **Create** and wait for Rancher to set up the service.

In a short time, you’ll see that both hosts labeled `application` are now running this new service. Since there’s more than one, let’s set up a load balancer so we can use both of these hosts effectively.

## Step 7 — Deploying the Load Balancer

Our load balancer is going to be linked to our `NodeJS` services to balance the workload between all the containers across the application hosts.

1. To create the load balancer, select the **Stacks** menu, choose the **User** option, but this time click the arrow on the **Add Service** button. Select **Add Load Balancer** from the dropdown list.
2. For the **Name** , enter `LoadBalancer`.
3. Set the **Source Port** to `80`, and the **Default Target Port** to `3000` which is the port our `NodeJS` containers are exposing.
4. In the **Target Service** option select **NodeJS** , which is the service we recently created.
5. In the **Scheduling** tab on the bottom of the page click the **Add Scheduling Rule** button and create a rule that says `The Host must have a host label of type = loadbalancer`.
6. Finally, click **Create** and wait while Rancher activates the service. 

Each time we’ve created a service, we’ve used the labels we created to determine how the service gets deployed. This makes managing additional hosts easy in the future. Now let’s make sure things work.

## Step 8 — Testing the Application

To test our application, we need to get the address of the load balancer host. Select the **LoadBalancer** service and you’ll see the IP address in the **Ports** tab.

To test that our application is working, execute the following command in a terminal:

    curl LoadBalancerIP

This command sends a GET request to the server. You’ll see a response that contains an empty array (`[]`) because our database is empty.

Now add a message to the database to ensure that the application can save data. Execute the following command:

    curl -i -X POST -H "Content-Type:application/json" LoadBalancerIP -d '{"message":"This is a test"}'

This command sends a POST request to the server with a JSON object which contains a `message` key with the value of This is a test. This application will only accept a `message` key, so any other name will be discarded. After sending the request, you should receive the same message you sent as a response, along with a `_id` from MongoDB. This means that the connection with the MongoDB server is working and the application saved your data.

Now, to double check that the application functions properly, execute the first command again and you should get the message you added in the previous step.

    curl LoadBalancerIP

The output will look like this:

    HTTP/1.1 200 OK
    content-type: application/json; charset=utf-8
    cache-control: no-cache
    content-length: 61
    Date: Tue, 12 Jul 2016 20:07:02 GMT
    Connection: keep-alive
    
    {"message":"This is a test","_id":"e64d85579aee7d1000b075a2"}

This example application is insecure; anyone who knows the address and the API can add messages to the system. When you’re done with this tutorial, you may want to disable this application by deleting the service in Rancher.

At this point you now have two application servers, a database, and a load balancer configured and ready for use. Let’s look at how to scale our services to handle more traffic.

## Step 9 — Scaling the Node.js Servers

When your application starts getting a lot of demand and your servers can’t handle the load, you can increase the amount of Node.js servers and the load will be distributed automatically between the containers across the application hosts. Follow these steps to scale your application:

1. Go to the **Infrastructure \> Hosts** page and click the **Add Host** button.
2. Select the quantity you want; in this case, we will add **2** more hosts.
3. Use `host5` as the name for the first new host, since the last host we created was `host4`. Because we are going to create two new hosts, Rancher will name the next one automatically to `host6`.
4. Add your DigitalOcean **Access Token** in the field of the same name.
5. For **Image** , use the default value of **ubuntu-14-04-x64**.
6. For **Size** , use the default value of **1GB**.
7. Click the **Add Label** button and in the **Key** input enter `type`, and then enter `application` in the **Value** input.
8. Click the **Create** button and wait while the new hosts are activated and added to Rancher.

After the new hosts come online, because they are labeled as application hosts, new instances of the `NodeJS` application will be configured and deployed automatically, and the load balancer will distribute the workload between four containers across four hosts.

## Conclusion

In this tutorial you learned how to prepare, deploy, and scale a functional Node.js application with support for data storage with MongoDB. As you can see, with Rancher and its GUI the process is pretty intuitive, and it’s easy to scale a complete application. And thanks to Rancher’s scheduling features, when your app hits the big time, you’ll be able to handle the load with ease.
