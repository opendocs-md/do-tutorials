---
author: ElliotForbes
date: 2019-06-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-resilient-go-app-digitalocean-kubernetes
---

# How to Deploy a Resilient Go Application to DigitalOcean Kubernetes

_The author selected [Girls Who Code](https://www.brightfunds.org/organizations/girls-who-code) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Docker](https://www.docker.com/) is a [containerization](https://en.wikipedia.org/wiki/OS-level_virtualisation) tool used to provide applications with a filesystem holding everything they need to run, ensuring that the software will have a consistent run-time environment and will behave the same way regardless of where it is deployed. [Kubernetes](https://kubernetes.io/) is a cloud platform for automating the deployment, scaling, and management of containerized applications.

By leveraging Docker, you can deploy an application on any system that supports Docker with the confidence that it will always work as intended. Kubernetes, meanwhile, allows you to deploy your application across multiple nodes in a cluster. Additionally, it handles key tasks such as bringing up new containers should any of your containers crash. Together, these tools streamline the process of deploying an application, allowing you to focus on development.

In this tutorial, you will build an example application written in [Go](https://golang.org/) and get it up and running locally on your development machine. Then you’ll containerize the application with Docker, deploy it to a Kubernetes cluster, and create a load balancer that will serve as the public-facing entry point to your application.

## Prerequisites

Before you begin this tutorial, you will need the following:

- A development server or local machine from which you will deploy the application. Although the instructions in this guide will largely work for most operating systems, this tutorial assumes that you have access to an Ubuntu 18.04 system configured with a non-root user with sudo privileges, as described in our [Initial Server Setup for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) tutorial.
- The `docker` command-line tool installed on your development machine. To install this, follow **Steps 1 and 2** of our tutorial on [How to Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04).
- The `kubectl` command-line tool installed on your development machine. To install this, follow [this guide from the official Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux).
- A free account on Docker Hub to which you will push your Docker image. To set this up, visit the [Docker Hub website](https://hub.docker.com/), click the **Get Started** button at the top-right of the page, and follow the registration instructions.
- A Kubernetes cluster. You can provision a [DigitalOcean Kubernetes cluster](https://www.digitalocean.com/products/kubernetes/) by following our [Kubernetes Quickstart guide](https://www.digitalocean.com/docs/kubernetes/quickstart/). You can still complete this tutorial if you provision your cluster from another cloud provider. Wherever you procure your cluster, be sure to set up a configuration file and ensure that you can connect to the cluster from your development server.

## Step 1 — Building a Sample Web Application in Go

In this step, you will build a sample application written in Go. Once you containerize this app with Docker, it will serve `My Awesome Go App` in response to requests to your server’s IP address at port `3000`.

Get started by updating your server’s package lists if you haven’t done so recently:

    sudo apt update

Then install Go by running:

    sudo apt install golang

Next, make sure you’re in your home directory and create a new directory which will contain all of your project files:

    cd && mkdir go-app

Then navigate to this new directory:

    cd go-app/

Use `nano` or your preferred text editor to create a file named `main.go` which will contain the code for your Go application:

    nano main.go

The first line in any Go source file is always a `package` statement that defines which code bundle the file belongs to. For executable files like this one, the `package` statement must point to the `main` package:

go-app/main.go

    package main

Following that, add an `import` statement where you can list all the libraries the application will need. Here, include `fmt`, which handles formatted text input and output, and `net/http`, which provides HTTP client and server implementations:

go-app/main.go

    package main
    
    import (
      "fmt"
      "net/http"
    )

Next, define a `homePage` function which will take in two arguments: `http.ResponseWriter` and a pointer to `http.Request`. In Go, a `ResponseWriter` interface is used to construct an HTTP response, while `http.Request` is an object representing an incoming request. Thus, this block reads incoming HTTP requests and then constructs a response:

go-app/main.go

    . . .
    
    import (
      "fmt"
      "net/http"
    )
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }

After this, add a `setupRoutes` function which will map incoming requests to their intended HTTP handler functions. In the body of this `setupRoutes` function, add a mapping of the `/` route to your newly defined `homePage` function. This tells the application to print the `My Awesome Go App` message even for requests made to unknown endpoints:

go-app/main.go

    . . .
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }

And finally, add the following `main` function. This will print out a string indicating that your application has started. It will then call the `setupRoutes` function before listening and serving your Go application on port `3000`.

go-app/main.go

    . . .
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }
    
    func main() {
      fmt.Println("Go Web App Started on Port 3000")
      setupRoutes()
      http.ListenAndServe(":3000", nil)
    }

After adding these lines, this is how the final file will look:

go-app/main.go

    package main
    
    import (
      "fmt"
      "net/http"
    )
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }
    
    func main() {
      fmt.Println("Go Web App Started on Port 3000")
      setupRoutes()
      http.ListenAndServe(":3000", nil)
    }

Save and close this file. If you created this file using `nano`, do so by pressing `CTRL + X`, `Y`, then `ENTER`.

Next, run the application using the following `go run` command. This will compile the code in your `main.go` file and run it locally on your development machine:

    go run main.go

    OutputGo Web App Started on Port 3000

This output confirms that the application is working as expected. It will run indefinitely, however, so close it by pressing `CTRL + C`.

Throughout this guide, you will use this sample application to experiment with Docker and Kubernetes. To that end, continue reading to learn how to containerize your application with Docker.

## Step 2 — Dockerizing Your Go Application

In its current state, the Go application you just created is only running on your development server. In this step, you’ll make this new application portable by containerizing it with Docker. This will allow it to run on any machine that supports Docker containers. You will build a Docker image and push it to a central public repository on Docker Hub. This way, your Kubernetes cluster can pull the image back down and deploy it as a container within the cluster.

The first step towards containerizing your application is to create a special script called a [_Dockerfile_](https://docs.docker.com/search/?q=dockerfile). A Dockerfile typically contains a list of instructions and arguments that run in sequential order so as to automatically perform certain actions on a base image or create a new one.

**Note:** In this step, you will configure a simple Docker container that will build and run your Go application in a single stage. If, in the future, you want to reduce the size of the container where your Go applications will run in production, you may want to look into [_mutli-stage builds_](https://docs.docker.com/develop/develop-images/multistage-build/).

Create a new file named `Dockerfile`:

    nano Dockerfile

At the top of the file, specify the base image needed for the Go app:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9

Then create an `app` directory within the container that will hold the application’s source files:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app

Below that, add the following line which copies everything in the `root` directory into the `app` directory:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app

Next, add the following line which changes the working directory to `app`, meaning that all the following commands in this Dockerfile will be run from that location:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app

Add a line instructing Docker to run the `go build -o main` command, which compiles the binary executable of the Go app:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app
    RUN go build -o main .

Then add the final line, which will run the binary executable:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app
    RUN go build -o main .
    CMD ["/app/main"]

Save and close the file after adding these lines.

Now that you have this `Dockerfile` in the root of your project, you can create a Docker image based off of it using the following `docker build` command. This command includes the `-t` flag which, when passed the value `go-web-app`, will name the Docker image `go-web-app` and _tag_ it.

**Note** : In Docker, tags allow you to convey information specific to a given image, such as its version number. The following command doesn’t provide a specific tag, so Docker will tag the image with its default tag: `latest`. If you want to give an image a custom tag, you would append the image name with a colon and the tag of your choice, like so:

    docker build -t sammy/image_name:tag_name .

Tagging an image like this can give you greater control over your images. For example, you could deploy an image tagged `v1.1` to production, but deploy another tagged `v1.2` to your pre-production or testing environment.

The final argument you’ll pass is the path: `.`. This specifies that you wish to build the Docker image from the contents of the current working directory. Also, be sure to update `sammy` to your Docker Hub username:

    docker build -t sammy/go-web-app .

This build command will read all of the lines in your `Dockerfile`, execute them in order, and then cache them, allowing future builds to run much faster:

    Output. . .
    Successfully built 521679ff78e5
    Successfully tagged go-web-app:latest

Once this command finishes building it, you will be able to see your image when you run the `docker images` command like so:

    docker images

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/go-web-app latest 4ee6cf7a8ab4 3 seconds ago 355MB

Next, use the following command create and start a container based on the image you just built. This command includes the `-it` flag, which specifies that the container will run in interactive mode. It also has the `-p` flag which maps the port on which the Go application is running on your development machine — port `3000` — to port `3000` in your Docker container:

    docker run -it -p 3000:3000 sammy/go-web-app

    OutputGo Web App Started on Port 3000

If there is nothing else running on that port, you’ll be able to see the application in action by opening up a browser and navigating to the following URL:

    http://your_server_ip:3000

**Note:** If you’re following this tutorial from your local machine instead of a server, visit the application by instead going to the following URL:

    http://localhost:3000

![Your containerized Go App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/resilient_go_kubernetes/resilient_screenshot_1.png)

After checking that the application works as expected in your browser, stop it by pressing `CTRL + C` in your terminal.

When you deploy your containerized application to your Kubernetes cluster, you’ll need to be able to pull the image from a centralized location. To that end, you can push your newly created image to your Docker Hub image repository.

Run the following command to log in to Docker Hub from your terminal:

    docker login

This will prompt you for your Docker Hub username and password. After entering them correctly, you will see `Login Succeeded` in the command’s output.

After logging in, push your new image up to Docker Hub using the `docker push` command, like so:

    docker push sammy/go-web-app

Once this command has successfully completed, you will be able to open up your Docker Hub account and see your Docker image there.

Now that you’ve pushed your image to a central location, you’re ready to deploy it to your Kubernetes cluster. First, though, we will walk through a brief process that will make it much less tedious to run `kubectl` commands.

## Step 3 — Improving Usability for `kubectl`

By this point, you’ve created a functioning Go application and containerized it with Docker. However, the application still isn’t publicly accessible. To resolve this, you will deploy your new Docker image to your Kubernetes cluster using the `kubectl` command line tool. Before doing this, though, let’s make a small change to the Kubernetes configuration file that will help to make running `kubectl` commands less laborious.

By default, when you run commands with the `kubectl` command-line tool, you have to specify the path of the cluster configuration file using the `--kubeconfig` flag. However, if your configuration file is named `config` and is stored in a directory named `~/.kube`, `kubectl` will know where to look for the configuration file and will be able pick it up without the `--kubeconfig` flag pointing to it.

To that end, if you haven’t already done so, create a new directory called `~/.kube`:

    mkdir ~/.kube

Then move your cluster configuration file to this directory, and rename it `config` in the process:

    mv clusterconfig.yaml ~/.kube/config

Moving forward, you won’t need to specify the location of your cluster’s configuration file when you run `kubectl`, as the command will be able to find it now that it’s in the default location. Test out this behavior by running the following `get nodes` command:

    kubectl get nodes

This will display all of the _nodes_ that reside within your Kubernetes cluster. In the context of Kubernetes, a node is a server or a worker machine on which one or more pods can be deployed:

    OutputNAME STATUS ROLES AGE VERSION
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfd Ready <none> 1m v1.13.5
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfi Ready <none> 1m v1.13.5
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfv Ready <none> 1m v1.13.5

With that, you’re ready to move on and deploy your application to your Kubernetes cluster. You will do this by creating two Kubernetes objects: one that will deploy the application to some pods in your cluster and another that will create a load balancer, providing an access point to your application.

## Step 4 — Creating a Deployment

[RESTful resources](https://en.wikipedia.org/wiki/Representational_state_transfer) make up all the persistent entities wihtin a Kubernetes system, and in this context they’re commonly referred to as _Kubernetes objects_. It’s helpful to think of Kubernetes objects as the work orders you submit to Kubernetes: you list what resources you need and how they should work, and then Kubernetes will constantly work to ensure that they exist in your cluster.

One kind of Kubernetes object, known as a _deployment_, is a set of identical, indistinguishable pods. In Kubernetes, a [_pod_](https://kubernetes.io/docs/concepts/workloads/pods/pod/) is a grouping of one or more containers which are able to communicate over the same shared network and interact with the same shared storage. A deployment runs more than one replica of the parent application at a time and automatically replaces any instances that fail, ensuring that your application is always available to serve user requests.

In this step, you’ll create a Kubernetes object description file, also known as a _manifest_, for a deployment. This manifest will contain all of the configuration details needed to deploy your Go app to your cluster.

Begin by creating a deployment manifest in the root directory of your project: `go-app/`. For small projects such as this one, keeping them in the root directory minimizes the complexity. For larger projects, however, it may be beneficial to store your manifests in a separate subdirectory so as to keep everything organized.

Create a new file called `deployment.yml`:

    nano deployment.yml

Different versions of the Kubernetes API contain different object definitions, so at the top of this file you must define the `apiVersion` you’re using to create this object. For the purpose of this tutorial, you will be using the `apps/v1` grouping as it contains many of the core Kubernetes object definitions that you’ll need in order to create a deployment. Add a field below `apiVersion` describing the `kind` of Kubernetes object you’re creating. In this case, you’re creating a `Deployment`:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment

Then define the `metadata` for your deployment. A `metadata` field is required for every Kubernetes object as it contains information such as the unique `name` of the object. This `name` is useful as it allows you to distinguish different deployments from one another and identify them using names that are human-readable:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: go-web-app

Next, you’ll build out the `spec` block of your `deployment.yml`. A `spec` field is a requirement for every Kubernetes object, but its precise format differs for each type of object. In the case of a deployment, it can contain information such as the number of _replicas_ of you want to run. In Kubernetes, a replica is the number of pods you want to run in your cluster. Here, set the number of `replicas` to `5`:

go-app/deployment.yml

    . . .
    metadata:
        name: go-web-app
    spec:
      replicas: 5

Next, create a `selector` block nested under the `spec` block. This will serve as a _label selector_ for your pods. Kubernetes uses label selectors to define how the deployment finds the pods which it must manage.

Within this `selector` block, define `matchLabels` and add the `name` label. Essentially, the `matchLabels` field tells Kubernetes what pods the deployment applies to. In this example, the deployment will apply to any pods with the name `go-web-app`:

go-app/deployment.yml

    . . .
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app

After this, add a `template` block. Every deployment creates a set of pods using the labels specified in a `template` block. The first subfield in this block is `metadata` which contains the `labels` that will be applied to all of the pods in this deployment. These labels are key/value pairs that are used as identifying attributes of Kubernetes objects. When you define your service later on, you can specify that you want all the pods with this `name` label to be grouped under that service. Set this `name` label to `go-web-app`:

go-app/deployment.yml

    . . .
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app
      template:
        metadata:
          labels:
            name: go-web-app

The second part of this `template` block is the `spec` block. This is different from the `spec` block you added previously, as this one applies only to the pods created by the `template` block, rather than the whole deployment.

Within this `spec` block, add a `containers` field and once again define a `name` attribute. This `name` field defines the name of any containers created by this particular deployment. Below that, define the `image` you want to pull down and deploy. Be sure to change `sammy` to your own Docker Hub username:

go-app/deployment.yml

    . . .
      template:
        metadata:
          labels:
            name: go-web-app
        spec:
          containers:
          - name: application
            image: sammy/go-web-app

Following that, add an `imagePullPolicy` field set to `IfNotPresent` which will direct the deployment to only pull an image if it has not already done so before. Then, lastly, add a `ports` block. There, define the `containerPort` which should match the port number that your Go application listens on. In this case, the port number is `3000`:

go-app/deployment.yml

    . . .
        spec:
          containers:
          - name: application
            image: sammy/go-web-app
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: 3000

The full version of your `deployment.yml` will look like this:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: go-web-app
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app
      template:
        metadata:
          labels:
            name: go-web-app
        spec:
          containers:
          - name: application
            image: sammy/go-web-app
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: 3000

Save and close the file.

Next, apply your new deployment with the following command:

    kubectl apply -f deployment.yml

**Note:** For more information on all of the configuration available to you for deployments, please check out the official Kubernetes documentation here: [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

In the next step, you’ll create another kind of Kubernetes object which will manage how you access the pods that exist in your new deployment. This service will create a load balancer which will then expose a single IP address, and requests to this IP address will be distributed to the replicas in your deployment. This service will also handle port forwarding rules so that you can access your application over HTTP.

## Step 5 — Creating a Service

Now that you have a successful Kubernetes deployment, you’re ready to expose your application to the outside world. In order to do this, you’ll need to define another kind of Kubernetes object: a _service_. This service will expose the same port on all of your cluster’s nodes. Your nodes will then forward any incoming traffic on that port to the pods running your application.

**Note:** For clarity, we will define this service object in a separate file. However, it is possible to group multiple resource manifests in the same YAML file, as long as they’re separated by `---`. See [this page from the Kubernetes documentation](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#organizing-resource-configurations) for more details.

Create a new file called `service.yml`:

    nano service.yml

Start this file off by again defining the `apiVersion` and the `kind` fields in a similar fashion to your `deployment.yml` file. This time, point the `apiVersion` field to `v1`, the Kubernetes API commonly used for services:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service

Next, add the name of your service in a `metadata` block as you did in `deployment.yml`. This could be anything you like, but for clarity we will call it `go-web-service`:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service

Next, create a `spec` block. This `spec` block will be different than the one included in your deployment, and it will contain the `type` of this service, as well as the port forwarding configuration and the `selector`.

Add a field defining this service’s `type` and set it to `LoadBalancer`. This will automatically provision a load balancer that will act as the main entry point to your application.

**Warning:** The method for creating a load balancer outlined in this step will only work for Kubernetes clusters provisioned from cloud providers that also support external load balancers. Additionally, be advised that provisioning a load balancer from a cloud provider will incur additional costs. If this is a concern for you, you may want to look into exposing an external IP address using an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer

Then add a `ports` block where you’ll define how you want your apps to be accessed. Nested within this block, add the following fields:

- `name`, pointing to `http`
- `port`, pointing to port `80`
- `targetPort`, pointing to port `3000`

This will take incoming HTTP requests on port `80` and forward them to the `targetPort` of `3000`. This `targetPort` is the same port on which your Go application is running:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer
      ports:
      - name: http
        port: 80
        targetPort: 3000

Lastly, add a `selector` block as you did in the `deployments.yml` file. This `selector` block is important, as it maps any deployed pods named `go-web-app` to this service:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer
      ports:
      - name: http
        port: 80
        targetPort: 3000
      selector:
        name: go-web-app

After adding these lines, save and close the file. Following that, apply this service to your Kubernetes cluster by once again using the `kubectl apply` command like so:

    kubectl apply -f service.yml

This command will apply the new Kubernetes service as well as create a load balancer. This load balancer will serve as the public-facing entry point to your application running within the cluster.

To view the application, you will need the new load balancer’s IP address. Find it by running the following command:

    kubectl get services

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    go-web-service LoadBalancer 10.245.107.189 203.0.113.20 80:30533/TCP 10m
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 3h4m

You may have more than one service running, but find the one labeled `go-web-service`. Find the `EXTERNAL-IP` column and copy the IP address associated with the `go-web-service`. In this example output, this IP address is `203.0.113.20`. Then, paste the IP address into the URL bar of your browser to the view the application running on your Kubernetes cluster.

**Note:** When Kubernetes creates a load balancer in this manner, it does so asynchronously. Consequently, the `kubectl get services` command’s output may show the `EXTERNAL-IP` address of the `LoadBalancer` remaining in a `<pending>` state for some time after running the `kubectl apply` command. If this the case, wait a few minutes and try re-running the command to ensure that the load balancer was created and is functioning as expected.

The load balancer will take in the request on port `80` and forward it to one of the pods running within your cluster.

![Your working Go App!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/resilient_go_kubernetes/resilient_screenshot_2.png)

With that, you’ve created a Kubernetes service coupled with a load balancer, giving you a single, stable entry point to application.

## Conclusion

In this tutorial, you’ve built Go application, containerized it with Docker, and then deployed it to a Kubernetes cluster. You then created a load balancer that provides a resilient entry point to this application, ensuring that it will remain highly available even if one of the nodes in your cluster fails. You can use this tutorial to deploy your own Go application to a Kubernetes cluster, or continue learning other Kubernetes and Docker concepts with the sample application you created in Step 1.

Moving forward, you could [map your load balancer’s IP address to a domain name that you control](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) so that you can access the application through a human-readable web address rather than the load balancer IP. Additionally, the following Kubernetes tutorials may be of interest to you:

- [How to Automate Deployments to DigitalOcean Kubernetes with CircleCI](how-to-automate-deployments-to-digitalocean-kubernetes-with-circleci)
- [White Paper: Running Cloud Native Applications on DigitalOcean Kubernetes](white-paper-running-cloud-native-applications-on-digitalocean-kubernetes)

Finally, if you’d like to learn more about Go, we encourage you to check out our series on [How To Code in Go](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-go).
