---
author: Kathleen Juell
date: 2019-04-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-scale-a-node-js-application-with-mongodb-on-kubernetes-using-helm
---

# How To Scale a Node.js Application with MongoDB on Kubernetes Using Helm

## Introduction

[Kubernetes](https://kubernetes.io/) is a system for running modern, containerized applications at scale. With it, developers can deploy and manage applications across clusters of machines. And though it can be used to improve efficiency and reliability in single-instance application setups, Kubernetes is designed to run multiple instances of an application across groups of machines.

When creating multi-service deployments with Kubernetes, many developers opt to use the [Helm](https://helm.sh/) package manager. Helm streamlines the process of creating multiple Kubernetes resources by offering charts and templates that coordinate how these objects interact. It also offers pre-packaged charts for popular open-source projects.

In this tutorial, you will deploy a [Node.js](https://nodejs.org/) application with a MongoDB database onto a Kubernetes cluster using Helm charts. You will use the [official Helm MongoDB replica set chart](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset) to create a [StatefulSet object](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) consisting of three [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/), a [Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services), and three [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims). You will also create a chart to deploy a multi-replica Node.js application using a custom application image. The setup you will build in this tutorial will mirror the functionality of the code described in [Containerizing a Node.js Application with Docker Compose](containerizing-a-node-js-application-for-development-with-docker-compose) and will be a good starting point to build a resilient Node.js application with a MongoDB data store that can scale with your needs.

## Prerequisites

To complete this tutorial, you will need:

- A Kubernetes 1.10+ cluster with role-based access control (RBAC) enabled. This setup will use a [DigitalOcean Kubernetes cluster](https://www.digitalocean.com/products/kubernetes/), but you are free to [create a cluster using another method](how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04).
- The `kubectl` command-line tool installed on your local machine or development server and configured to connect to your cluster. You can read more about installing `kubectl` in the [official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- Helm installed on your local machine or development server and Tiller installed on your cluster, following the directions outlined in Steps 1 and 2 of [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager).
- [Docker](https://www.docker.com/) installed on your local machine or development server. If you are working with Ubuntu 18.04, follow Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04); otherwise, follow the [official documentation](https://docs.docker.com/install/) for information about installing on other operating systems. Be sure to add your non-root user to the `docker` group, as described in Step 2 of the linked tutorial.
- A [Docker Hub](https://hub.docker.com/) account. For an overview of how to set this up, refer to [this introduction](https://docs.docker.com/docker-hub/) to Docker Hub.

## Step 1 — Cloning and Packaging the Application

To use our application with Kubernetes, we will need to package it so that the [`kubelet` agent](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) can pull the image. Before packaging the application, however, we will need to modify the MongoDB [connection URI](https://docs.mongodb.com/manual/reference/connection-string/) in the application code to ensure that our application can connect to the members of the replica set that we will create with the Helm `mongodb-replicaset` chart.

Our first step will be to clone the [node-mongo-docker-dev repository](https://github.com/do-community/node-mongo-docker-dev.git) from the [DigitalOcean Community GitHub account](https://github.com/do-community). This repository includes the code from the setup described in [Containerizing a Node.js Application for Development With Docker Compose](containerizing-a-node-js-application-for-development-with-docker-compose), which uses a demo Node.js application with a MongoDB database to demonstrate how to set up a development environment with Docker Compose. You can find more information about the application itself in the series [From Containers to Kubernetes with Node.js](https://www.digitalocean.com/community/tutorial_series/from-containers-to-kubernetes-with-node-js).

Clone the repository into a directory called `node_project`:

    git clone https://github.com/do-community/node-mongo-docker-dev.git node_project

Navigate to the `node_project` directory:

    cd node_project

The `node_project` directory contains files and directories for a shark information application that works with user input. It has been modernized to work with containers: sensitive and specific configuration information has been removed from the application code and refactored to be injected at runtime, and the application’s state has been offloaded to a MongoDB database.

For more information about designing modern, containerized applications, please see [Architecting Applications for Kubernetes](architecting-applications-for-kubernetes) and [Modernizing Applications for Kubernetes](modernizing-applications-for-kubernetes).

When we deploy the Helm `mongodb-replicaset` chart, it will create:

- A StatefulSet object with three Pods — the members of the MongoDB [replica set](https://docs.mongodb.com/manual/replication/). Each Pod will have an associated PersistentVolumeClaim and will maintain a fixed identity in the event of rescheduling. 
- A MongoDB replica set made up of the Pods in the StatefulSet. The set will include one primary and two secondaries. Data will be replicated from the primary to the secondaries, ensuring that our application data remains highly available.  

For our application to interact with the database replicas, the MongoDB connection URI in our code will need to include both the hostnames of the replica set members as well as the name of the replica set itself. We therefore need to include these values in the URI.

The file in our cloned repository that specifies database connection information is called `db.js`. Open that file now using `nano` or your favorite editor:

    nano db.js

Currently, the file includes [constants](understanding-variables-scope-hoisting-in-javascript#constants) that are referenced in the database connection URI at runtime. The values for these constants are injected using Node’s [`process.env`](https://nodejs.org/api/process.html#process_process_env) property, which returns an object with information about your user environment at runtime. Setting values dynamically in our application code allows us to decouple the code from the underlying infrastructure, which is necessary in a dynamic, stateless environment. For more information about refactoring application code in this way, see [Step 2](containerizing-a-node-js-application-for-development-with-docker-compose#step-2-%E2%80%94-configuring-your-application-to-work-with-containers) of [Containerizing a Node.js Application for Development With Docker Compose](containerizing-a-node-js-application-for-development-with-docker-compose) and the relevant discussion in [The 12-Factor App](https://12factor.net/config).

The constants for the connection URI and the URI string itself currently look like this:

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
    
    const url = `mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOSTNAME}:${MONGO_PORT}/${MONGO_DB}?authSource=admin`;
    ...

In keeping with a 12FA approach, we do not want to hard code the hostnames of our replica instances or our replica set name into this URI string. The existing `MONGO_HOSTNAME` constant can be expanded to include multiple hostnames — the members of our replica set — so we will leave that in place. We will need to add a replica set constant to the [`options` section](https://docs.mongodb.com/manual/reference/connection-string/#components) of the URI string, however.

Add `MONGO_REPLICASET` to both the URI constant object and the connection string:

~/node\_project/db.js

    ...
    const {
      MONGO_USERNAME,
      MONGO_PASSWORD,
      MONGO_HOSTNAME,
      MONGO_PORT,
      MONGO_DB,
      MONGO_REPLICASET
    } = process.env;
    
    ...
    const url = `mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOSTNAME}:${MONGO_PORT}/${MONGO_DB}?replicaSet=${MONGO_REPLICASET}&authSource=admin`;
    ...

Using the [`replicaSet` option](https://docs.mongodb.com/manual/reference/connection-string/#urioption.replicaSet) in the options section of the URI allows us to pass in the name of the replica set, which, along with the hostnames defined in the `MONGO_HOSTNAME` constant, will allow us to connect to the set members.

Save and close the file when you are finished editing.

With your database connection information modified to work with replica sets, you can now package your application, build the image with the [`docker build`](https://docs.docker.com/engine/reference/commandline/build/) command, and push it to Docker Hub.

Build the image with `docker build` and the `-t` flag, which allows you to tag the image with a memorable name. In this case, tag the image with your Docker Hub username and name it `node-replicas` or a name of your own choosing:

    docker build -t your_dockerhub_username/node-replicas .

The `.` in the command specifies that the build context is the current directory.

It will take a minute or two to build the image. Once it is complete, check your images:

    docker images

You will see the following output:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    your_dockerhub_username/node-replicas latest 56a69b4bc882 7 seconds ago 90.1MB
    node 10-alpine aa57b0242b33 6 days ago 71MB

Next, log in to the Docker Hub account you created in the prerequisites:

    docker login -u your_dockerhub_username 

When prompted, enter your Docker Hub account password. Logging in this way will create a `~/.docker/config.json` file in your non-root user’s home directory with your Docker Hub credentials.

Push the application image to Docker Hub with the [`docker push` command](https://docs.docker.com/engine/reference/commandline/push/). Remember to replace `your_dockerhub_username` with your own Docker Hub username:

    docker push your_dockerhub_username/node-replicas

You now have an application image that you can pull to run your replicated application with Kubernetes. The next step will be to configure specific parameters to use with the MongoDB Helm chart.

## Step 2 — Creating Secrets for the MongoDB Replica Set

The `stable/mongodb-replicaset` chart provides different options when it comes to using Secrets, and we will create two to use with our chart deployment:

- A Secret for our [replica set keyfile](https://docs.mongodb.com/manual/tutorial/enforce-keyfile-access-control-in-existing-replica-set/#enforce-keyfile-access-control-on-existing-replica-set) that will function as a shared password between replica set members, allowing them to authenticate other members.
- A Secret for our MongoDB admin user, who will be created as a [**root** user](https://docs.mongodb.com/manual/reference/built-in-roles/#root) on the `admin` database. This role will allow you to create subsequent users with limited permissions when deploying your application to production.

With these Secrets in place, we will be able to set our preferred parameter values in a dedicated values file and create the StatefulSet object and MongoDB replica set with the Helm chart.

First, let’s create the keyfile. We will use the [`openssl` command](https://www.openssl.org/docs/man1.1.1/man1/openssl.html) with the `rand` option to generate a 756 byte random string for the keyfile:

    openssl rand -base64 756 > key.txt

The output generated by the command will be [base64](https://en.wikipedia.org/wiki/Base64) encoded, ensuring uniform data transmission, and redirected to a file called `key.txt`, following the guidelines stated in the [`mongodb-replicaset` chart authentication documentation](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset#authentication). The [key itself](https://docs.mongodb.com/manual/core/security-internal-authentication/#keyfiles) must be between 6 and 1024 characters long, consisting only of characters in the base64 set.

You can now create a Secret called `keyfilesecret` using this file with [`kubectl create`](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#create):

    kubectl create secret generic keyfilesecret --from-file=key.txt

This will create a Secret object in the `default` [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), since we have not created a specific namespace for our setup.

You will see the following output indicating that your Secret has been created:

    Outputsecret/keyfilesecret created

Remove `key.txt`:

    rm key.txt

Alternatively, if you would like to save the file, be sure [restrict its permissions](https://docs.mongodb.com/manual/tutorial/enforce-keyfile-access-control-in-existing-replica-set/#create-a-keyfile) and add it to your [`.gitignore` file](https://git-scm.com/docs/gitignore) to keep it out of version control.

Next, create the Secret for your MongoDB admin user. The first step will be to convert your desired username and password to base64.

Convert your database username:

    echo -n 'your_database_username' | base64

Note down the value you see in the output.

Next, convert your password:

    echo -n 'your_database_password' | base64

Take note of the value in the output here as well.

Open a file for the Secret:

    nano secret.yaml

**Note:** Kubernetes objects are [typically defined](https://kubernetes.io/docs/concepts/overview/object-management-kubectl/imperative-config/) using [YAML](https://yaml.org/), which strictly forbids tabs and requires two spaces for indentation. If you would like to check the formatting of any of your YAML files, you can use a [linter](http://www.yamllint.com/) or test the validity of your syntax using `kubectl create` with the `--dry-run` and `--validate` flags:

    kubectl create -f your_yaml_file.yaml --dry-run --validate=true

In general, it is a good idea to validate your syntax before creating resources with `kubectl`.

Add the following code to the file to create a Secret that will define a `user` and `password` with the encoded values you just created. Be sure to replace the dummy values here with your own **encoded** username and password:

~/node\_project/secret.yaml

    apiVersion: v1
    kind: Secret
    metadata:
      name: mongo-secret
    data:
      user: your_encoded_username
      password: your_encoded_password

Here, we’re using the key names that the `mongodb-replicaset` chart expects: `user` and `password`. We have named the Secret object `mongo-secret`, but you are free to name it anything you would like.

Save and close the file when you are finished editing.

Create the Secret object with the following command:

    kubectl create -f secret.yaml

You will see the following output:

    Outputsecret/mongo-secret created

Again, you can either remove `secret.yaml` or restrict its permissions and add it to your `.gitignore` file.

With your Secret objects created, you can move on to specifying the parameter values you will use with the `mongodb-replicaset` chart and creating the MongoDB deployment.

## Step 3 — Configuring the MongoDB Helm Chart and Creating a Deployment

Helm comes with an actively maintained repository called **stable** that contains the chart we will be using: `mongodb-replicaset`. To use this chart with the Secrets we’ve just created, we will create a file with configuration parameter values called `mongodb-values.yaml` and then install the chart using this file.

Our `mongodb-values.yaml` file will largely mirror the default [`values.yaml` file](https://github.com/helm/charts/blob/master/stable/mongodb-replicaset/values.yaml) in the `mongodb-replicaset` chart repository. We will, however, make the following changes to our file:

- We will set the `auth` parameter to `true` to ensure that our database instances start with [authorization enabled](https://docs.mongodb.com/manual/reference/program/mongod/#cmdoption-mongod-auth). This means that all clients will be required to authenticate for access to database resources and operations.
- We will add information about the Secrets we created in the previous Step so that the chart can use these values to create the replica set keyfile and admin user.
- We will decrease the size of the PersistentVolumes associated with each Pod in the StatefulSet to use the [minimum viable DigitalOcean Block Storage unit](https://www.digitalocean.com/docs/volumes/overview/), 1GB, though you are free to modify this to meet your storage requirements.

Before writing the `mongodb-values.yaml` file, however, you should first check that you have a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) created and configured to provision storage resources. Each of the Pods in your database StatefulSet will have a sticky identity and an associated [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims), which will dynamically provision a PersistentVolume for the Pod. If a Pod is rescheduled, the PersistentVolume will be mounted to whichever node the Pod is scheduled on (though each Volume must be manually deleted if its associated Pod or StatefulSet is permanently deleted).

Because we are working with [DigitalOcean Kubernetes](https://www.digitalocean.com/products/kubernetes/), our default StorageClass `provisioner` is set to `dobs.csi.digitalocean.com` — [DigitalOcean Block Storage](https://www.digitalocean.com/products/block-storage/) — which we can check by typing:

    kubectl get storageclass

If you are working with a DigitalOcean cluster, you will see the following output:

    OutputNAME PROVISIONER AGE
    do-block-storage (default) dobs.csi.digitalocean.com 21m

If you are not working with a DigitalOcean cluster, you will need to create a StorageClass and configure a `provisioner` of your choice. For details about how to do this, please see the [official documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/).

Now that you have ensured that you have a StorageClass configured, open `mongodb-values.yaml` for editing:

    nano mongodb-values.yaml

You will set values in this file that will do the following:

- Enable authorization. 
- Reference your `keyfilesecret` and `mongo-secret` objects. 
- Specify `1Gi` for your PersistentVolumes. 
- Set your replica set name to `db`.
- Specify `3` replicas for the set. 
- Pin the `mongo` image to the latest version at the time of writing: `4.1.9`.

Paste the following code into the file:

~/node\_project/mongodb-values.yaml

    replicas: 3
    port: 27017
    replicaSetName: db
    podDisruptionBudget: {}
    auth:
      enabled: true
      existingKeySecret: keyfilesecret
      existingAdminSecret: mongo-secret
    imagePullSecrets: []
    installImage:
      repository: unguiculus/mongodb-install
      tag: 0.7
      pullPolicy: Always
    copyConfigImage:
      repository: busybox
      tag: 1.29.3
      pullPolicy: Always
    image:
      repository: mongo
      tag: 4.1.9
      pullPolicy: Always
    extraVars: {}
    metrics:
      enabled: false
      image:
        repository: ssalaues/mongodb-exporter
        tag: 0.6.1
        pullPolicy: IfNotPresent
      port: 9216
      path: /metrics
      socketTimeout: 3s
      syncTimeout: 1m
      prometheusServiceDiscovery: true
      resources: {}
    podAnnotations: {}
    securityContext:
      enabled: true
      runAsUser: 999
      fsGroup: 999
      runAsNonRoot: true
    init:
      resources: {}
      timeout: 900
    resources: {}
    nodeSelector: {}
    affinity: {}
    tolerations: []
    extraLabels: {}
    persistentVolume:
      enabled: true
      #storageClass: "-"
      accessModes:
        - ReadWriteOnce
      size: 1Gi
      annotations: {}
    serviceAnnotations: {}
    terminationGracePeriodSeconds: 30
    tls:
      enabled: false
    configmap: {}
    readinessProbe:
      initialDelaySeconds: 5
      timeoutSeconds: 1
      failureThreshold: 3
      periodSeconds: 10
      successThreshold: 1
    livenessProbe:
      initialDelaySeconds: 30
      timeoutSeconds: 5
      failureThreshold: 3
      periodSeconds: 10
      successThreshold: 1

The `persistentVolume.storageClass` parameter is commented out here: removing the comment and setting its value to `"-"` would disable dynamic provisioning. In our case, because we are leaving this value undefined, the chart will choose the default `provisioner` — in our case, `dobs.csi.digitalocean.com`.

Also note the `accessMode` associated with the `persistentVolume` key: `ReadWriteOnce` means that the provisioned volume will be read-write only by a single node. Please see the [documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for more information about different access modes.

To learn more about the other parameters included in the file, see the [configuration table](https://github.com/helm/charts/tree/master/stable/mongodb-replicaset#configuration) included with the repo.

Save and close the file when you are finished editing.

Before deploying the `mongodb-replicaset` chart, you will want to update the **stable** repo with the [`helm repo update` command](https://helm.sh/docs/helm/#helm-repo-update):

    helm repo update

This will get the latest chart information from the **stable** repository.

Finally, install the chart with the following command:

    helm install --name mongo -f mongodb-values.yaml stable/mongodb-replicaset

**Note:** Before installing a chart, you can run `helm install` with the `--dry-run` and `--debug` options to check the generated manifests for your release:

    helm install --name your_release_name -f your_values_file.yaml --dry-run --debug your_chart

Note that we are naming the Helm _release_ `mongo`. This name will refer to this particular deployment of the chart with the configuration options we’ve specified. We’ve pointed to these options by including the `-f` flag and our `mongodb-values.yaml` file.

Also note that because we did not include the `--namespace` flag with `helm install`, our chart objects will be created in the `default` namespace.

Once you have created the release, you will see output about its status, along with information about the created objects and instructions for interacting with them:

    OutputNAME: mongo
    LAST DEPLOYED: Tue Apr 16 21:51:05 2019
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ConfigMap
    NAME DATA AGE
    mongo-mongodb-replicaset-init 1 1s
    mongo-mongodb-replicaset-mongodb 1 1s
    mongo-mongodb-replicaset-tests 1 0s
    ...

You can now check on the creation of your Pods with the following command:

    kubectl get pods

You will see output like the following as the Pods are being created:

    OutputNAME READY STATUS RESTARTS AGE
    mongo-mongodb-replicaset-0 1/1 Running 0 67s
    mongo-mongodb-replicaset-1 0/1 Init:0/3 0 8s

The `READY` and `STATUS` outputs here indicate that the Pods in our StatefulSet are not fully ready: the [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) associated with the Pod’s containers are still running. Because StatefulSet members are [created in sequential order](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#deployment-and-scaling-guarantees), each Pod in the StatefulSet must be `Running` and `Ready` before the next Pod will be created.

Once the Pods have been created and all of their associated containers are running, you will see this output:

    OutputNAME READY STATUS RESTARTS AGE
    mongo-mongodb-replicaset-0 1/1 Running 0 2m33s
    mongo-mongodb-replicaset-1 1/1 Running 0 94s
    mongo-mongodb-replicaset-2 1/1 Running 0 36s

The `Running` `STATUS` indicates that your Pods are bound to nodes and that the containers associated with those Pods are running. `READY` indicates how many containers in a Pod are running. For more information, please consult the [documentation on Pod lifecycles](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/).

**Note:**  
If you see unexpected phases in the `STATUS` column, remember that you can troubleshoot your Pods with the following commands:

    kubectl describe pods your_pod
    kubectl logs your_pod

Each of the Pods in your StatefulSet has a name that combines the name of the StatefulSet with the [ordinal index](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#ordinal-index) of the Pod. Because we created three replicas, our StatefulSet members are numbered 0-2, and each has a [stable DNS entry](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#stable-network-id) comprised of the following elements: `$(statefulset-name)-$(ordinal).$(service name).$(namespace).svc.cluster.local`.

In our case, the StatefulSet and the [Headless Service](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) created by the `mongodb-replicaset` chart have the same names:

    kubectl get statefulset

    OutputNAME READY AGE
    mongo-mongodb-replicaset 3/3 4m2s

    kubectl get svc

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 42m
    mongo-mongodb-replicaset ClusterIP None <none> 27017/TCP 4m35s
    mongo-mongodb-replicaset-client ClusterIP None <none> 27017/TCP 4m35s

This means that the first member of our StatefulSet will have the following DNS entry:

    mongo-mongodb-replicaset-0.mongo-mongodb-replicaset.default.svc.cluster.local

Because we need our application to connect to each MongoDB instance, it’s essential that we have this information so that we can communicate directly with the Pods, rather than with the Service. When we create our custom application Helm chart, we will pass the DNS entries for each Pod to our application using environment variables.

With your database instances up and running, you are ready to create the chart for your Node application.

## Step 4 — Creating a Custom Application Chart and Configuring Parameters

We will create a custom Helm chart for our Node application and modify the default files in the standard chart directory so that our application can work with the replica set we have just created. We will also create files to define ConfigMap and Secret objects for our application.

First, create a new chart directory called `nodeapp` with the following command:

    helm create nodeapp

This will create a directory called `nodeapp` in your `~/node_project` folder with the following resources:

- A `Chart.yaml` file with basic information about your chart.
- A `values.yaml` file that allows you to set specific parameter values, as you did with your MongoDB deployment.
- A `.helmignore` file with file and directory patterns that will be ignored when packaging charts.
- A `templates/` directory with the template files that will generate Kubernetes manifests. 
- A `templates/tests/` directory for test files.
- A `charts/` directory for any charts that this chart depends on.

The first file we will modify out of these default files is `values.yaml`. Open that file now:

    nano nodeapp/values.yaml

The values that we will set here include:

- The number of replicas.
- The application image we want to use. In our case, this will be the `node-replicas` image we created in [Step 1](how-to-scale-a-node-js-application-with-mongodb-using-helm#step-1-%E2%80%94-cloning-and-packaging-the-application).
- The [ServiceType](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types). In this case, we will specify [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) to create a point of access to our application for testing purposes. Because we are working with a DigitalOcean Kubernetes cluster, this will create a [DigitalOcean Load Balancer](https://www.digitalocean.com/products/load-balancer/) when we deploy our chart. In production, you can configure your chart to use [Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) and [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) to route traffic to your Services.
- The [targetPort](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service) to specify the port on the Pod where our application will be exposed. 

We will not enter environment variables into this file. Instead, we will create templates for ConfigMap and Secret objects and add these values to our application Deployment manifest, located at `~/node_project/nodeapp/templates/deployment.yaml`.

Configure the following values in the `values.yaml` file:

~/node\_project/nodeapp/values.yaml

    # Default values for nodeapp.
    # This is a YAML-formatted file.
    # Declare variables to be passed into your templates.
    
    replicaCount: 3
    
    image:
      repository: your_dockerhub_username/node-replicas
      tag: latest
      pullPolicy: IfNotPresent
    
    nameOverride: ""
    fullnameOverride: ""
    
    service:
      type: LoadBalancer
      port: 80
      targetPort: 8080
    ...

Save and close the file when you are finished editing.

Next, open a `secret.yaml` file in the `nodeapp/templates` directory:

    nano nodeapp/templates/secret.yaml

In this file, add values for your `MONGO_USERNAME` and `MONGO_PASSWORD` application constants. These are the constants that your application will expect to have access to at runtime, as specified in `db.js`, your database connection file. As you add the values for these constants, remember to the use the base64- **encoded** values that you used earlier in [Step 2](how-to-scale-a-node-js-application-with-mongodb-using-helm#step-2-%E2%80%94-creating-secrets-for-the-mongodb-replica-set) when creating your `mongo-secret` object. If you need to recreate those values, you can return to Step 2 and run the relevant commands again.

Add the following code to the file:

~/node\_project/nodeapp/templates/secret.yaml

    apiVersion: v1
    kind: Secret
    metadata:
      name: {{ .Release.Name }}-auth
    data:
      MONGO_USERNAME: your_encoded_username
      MONGO_PASSWORD: your_encoded_password

The name of this Secret object will depend on the name of your Helm release, which you will specify when you deploy the application chart.

Save and close the file when you are finished.

Next, open a file to create a ConfigMap for your application:

    nano nodeapp/templates/configmap.yaml

In this file, we will define the remaining variables that our application expects: `MONGO_HOSTNAME`, `MONGO_PORT`, `MONGO_DB`, and `MONGO_REPLICASET`. Our `MONGO_HOSTNAME` variable will include the DNS entry for **each** instance in our replica set, since this is what the [MongoDB connection URI requires](https://docs.mongodb.com/manual/reference/connection-string/).

According to the [Kubernetes documentation](https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/#using-stable-network-identities), when an application implements liveness and readiness checks, [SRV records](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#srv-records) should be used when connecting to the Pods. As discussed in [Step 3](how-to-scale-a-node-js-application-with-mongodb-using-helm#step-3-%E2%80%94-configuring-the-mongodb-helm-chart-and-creating-a-deployment), our Pod SRV records follow this pattern: `$(statefulset-name)-$(ordinal).$(service name).$(namespace).svc.cluster.local`. Since our MongoDB StatefulSet implements liveness and readiness checks, we should use these stable identifiers when defining the values of the `MONGO_HOSTNAME` variable.

Add the following code to the file to define the `MONGO_HOSTNAME`, `MONGO_PORT`, `MONGO_DB`, and `MONGO_REPLICASET` variables. You are free to use another name for your `MONGO_DB` database, but your `MONGO_HOSTNAME` and `MONGO_REPLICASET` values must be written as they appear here:

~/node\_project/nodeapp/templates/configmap.yaml

    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: {{ .Release.Name }}-config
    data:
      MONGO_HOSTNAME: "mongo-mongodb-replicaset-0.mongo-mongodb-replicaset.default.svc.cluster.local,mongo-mongodb-replicaset-1.mongo-mongodb-replicaset.default.svc.cluster.local,mongo-mongodb-replicaset-2.mongo-mongodb-replicaset.default.svc.cluster.local"  
      MONGO_PORT: "27017"
      MONGO_DB: "sharkinfo"
      MONGO_REPLICASET: "db"

Because we have already created the StatefulSet object and replica set, the hostnames that are listed here must be listed in your file exactly as they appear in this example. If you destroy these objects and rename your MongoDB Helm release, then you will need to revise the values included in this ConfigMap. The same applies for `MONGO_REPLICASET`, since we specified the replica set name with our MongoDB release.

Also note that the values listed here are quoted, which is [the expectation for environment variables in Helm](https://github.com/helm/helm/blob/master/docs/charts_tips_and_tricks.md#quote-strings-dont-quote-integers).

Save and close the file when you are finished editing.

With your chart parameter values defined and your Secret and ConfigMap manifests created, you can edit the application Deployment template to use your environment variables.

## Step 5 — Integrating Environment Variables into Your Helm Deployment

With the files for our application Secret and ConfigMap in place, we will need to make sure that our application Deployment can use these values. We will also customize the [liveness and readiness probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/) that are already defined in the Deployment manifest.

Open the application Deployment template for editing:

    nano nodeapp/templates/deployment.yaml

Though this is a YAML file, Helm templates use a different syntax from standard Kubernetes YAML files in order to generate manifests. For more information about templates, see the [Helm documentation](https://helm.sh/docs/chart_template_guide/#the-chart-template-developer-s-guide).

In the file, first add an `env` key to your application container specifications, below the `imagePullPolicy` key and above `ports`:

~/node\_project/nodeapp/templates/deployment.yaml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    ...
      spec:
        containers:
          - name: {{ .Chart.Name }}
            image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
            imagePullPolicy: {{ .Values.image.pullPolicy }}
            env:
            ports:

Next, add the following keys to the list of `env` variables:

~/node\_project/nodeapp/templates/deployment.yaml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    ...
      spec:
        containers:
          - name: {{ .Chart.Name }}
            image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
            imagePullPolicy: {{ .Values.image.pullPolicy }}
            env:
            - name: MONGO_USERNAME
              valueFrom:
                secretKeyRef:
                  key: MONGO_USERNAME
                  name: {{ .Release.Name }}-auth
            - name: MONGO_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: MONGO_PASSWORD
                  name: {{ .Release.Name }}-auth
            - name: MONGO_HOSTNAME
              valueFrom:
                configMapKeyRef:
                  key: MONGO_HOSTNAME
                  name: {{ .Release.Name }}-config
            - name: MONGO_PORT
              valueFrom:
                configMapKeyRef:
                  key: MONGO_PORT
                  name: {{ .Release.Name }}-config
            - name: MONGO_DB
              valueFrom:
                configMapKeyRef:
                  key: MONGO_DB
                  name: {{ .Release.Name }}-config      
            - name: MONGO_REPLICASET
              valueFrom:
                configMapKeyRef:
                  key: MONGO_REPLICASET
                  name: {{ .Release.Name }}-config        

Each variable includes a reference to its value, defined either by a [`secretKeyRef` key](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables), in the case of Secret values, or [`configMapKeyRef`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#define-container-environment-variables-using-configmap-data) for ConfigMap values. These keys point to the Secret and ConfigMap files we created in the previous Step.

Next, under the `ports` key, modify the `containerPort` definition to specify the port on the container where our application will be exposed:

~/node\_project/nodeapp/templates/deployment.yaml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    ...
      spec:
        containers:
        ...
          env:
        ...
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          ...

Next, let’s modify the liveness and readiness checks that are included in this Deployment manifest by default. These checks ensure that our application Pods are running and ready to serve traffic:

- Readiness probes assess whether or not a Pod is ready to serve traffic, stopping all requests to the Pod until the checks succeed.
- Liveness probes check basic application behavior to determine whether or not the application in the container is running and behaving as expected. If a liveness probe fails, Kubernetes will restart the container.

For more about both, see the [relevant discussion](architecting-applications-for-kubernetes#implementing-readiness-and-liveness-probes) in [Architecting Applications for Kubernetes](architecting-applications-for-kubernetes).

In our case, we will build on the [`httpGet` request](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-http-request) that Helm has provided by default and test whether or not our application is accepting requests on the `/sharks` endpoint. The [`kubelet` service](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) will perform the probe by sending a GET request to the Node server running in the application Pod’s container and listening on port `8080`. If the status code for the response is between 200 and 400, then the `kubelet` will conclude that the container is healthy. Otherwise, in the case of a 400 or 500 status, `kubelet` will either stop traffic to the container, in the case of the readiness probe, or restart the container, in the case of the liveness probe.

Add the following modification to the stated `path` for the liveness and readiness probes:

~/node\_project/nodeapp/templates/deployment.yaml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
    ...
      spec:
        containers:
        ...
          env:
        ...
          ports:
            - name: http
              containerPort: 8080
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /sharks
              port: http
          readinessProbe:
            httpGet:
              path: /sharks
              port: http

Save and close the file when you are finished editing.

You are now ready to create your application release with Helm. Run the following [`helm install` command](https://helm.sh/docs/helm/#helm-install), which includes the name of the release and the location of the chart directory:

    helm install --name nodejs ./nodeapp

Remember that you can run `helm install` with the `--dry-run` and `--debug` options first, as discussed in [Step 3](how-to-scale-a-node-js-application-with-mongodb-using-helm#step-3-%E2%80%94-configuring-the-mongodb-helm-chart-and-creating-a-deployment), to check the generated manifests for your release.

Again, because we are not including the `--namespace` flag with `helm install`, our chart objects will be created in the `default` namespace.

You will see the following output indicating that your release has been created:

    OutputNAME: nodejs
    LAST DEPLOYED: Wed Apr 17 18:10:29 2019
    NAMESPACE: default
    STATUS: DEPLOYED
    
    RESOURCES:
    ==> v1/ConfigMap
    NAME DATA AGE
    nodejs-config 4 1s
    
    ==> v1/Deployment
    NAME READY UP-TO-DATE AVAILABLE AGE
    nodejs-nodeapp 0/3 3 0 1s
    
    ...

Again, the output will indicate the status of the release, along with information about the created objects and how you can interact with them.

Check the status of your Pods:

    kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    mongo-mongodb-replicaset-0 1/1 Running 0 57m
    mongo-mongodb-replicaset-1 1/1 Running 0 56m
    mongo-mongodb-replicaset-2 1/1 Running 0 55m
    nodejs-nodeapp-577df49dcc-b5fq5 1/1 Running 0 117s
    nodejs-nodeapp-577df49dcc-bkk66 1/1 Running 0 117s
    nodejs-nodeapp-577df49dcc-lpmt2 1/1 Running 0 117s

Once your Pods are up and running, check your Services:

    kubectl get svc

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 96m
    mongo-mongodb-replicaset ClusterIP None <none> 27017/TCP 58m
    mongo-mongodb-replicaset-client ClusterIP None <none> 27017/TCP 58m
    nodejs-nodeapp LoadBalancer 10.245.33.46 your_lb_ip 80:31518/TCP 3m22s

The `EXTERNAL_IP` associated with the `nodejs-nodeapp` Service is the IP address where you can access the application from outside of the cluster. If you see a `<pending>` status in the `EXTERNAL_IP` column, this means that your load balancer is still being created.

Once you see an IP in that column, navigate to it in your browser: `http://your_lb_ip`.

You should see the following landing page:

![Application Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Now that your replicated application is working, let’s add some test data to ensure that replication is working between members of the replica set.

## Step 6 — Testing MongoDB Replication

With our application running and accessible through an external IP address, we can add some test data and ensure that it is being replicated between the members of our MongoDB replica set.

First, make sure you have navigated your browser to the application landing page:

![Application Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Click on the **Get Shark Info** button. You will see a page with an entry form where you can enter a shark name and a description of that shark’s general character:

![Shark Info Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_form.png)

In the form, add an initial shark of your choosing. To demonstrate, we will add `Megalodon Shark` to the **Shark Name** field, and `Ancient` to the **Shark Character** field:

![Filled Shark Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_filled.png)

Click on the **Submit** button. You will see a page with this shark information displayed back to you:

![Shark Output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_added.png)

Now head back to the shark information form by clicking on **Sharks** in the top navigation bar:

![Shark Info Form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_mongo/shark_form.png)

Enter a new shark of your choosing. We’ll go with `Whale Shark` and `Large`:

![Enter New Shark](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_docker_dev/whale_shark.png)

Once you click **Submit** , you will see that the new shark has been added to the shark collection in your database:

![Complete Shark Collection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/node_docker_dev/persisted_data.png)

Let’s check that the data we’ve entered has been replicated between the primary and secondary members of our replica set.

Get a list of your Pods:

    kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    mongo-mongodb-replicaset-0 1/1 Running 0 74m
    mongo-mongodb-replicaset-1 1/1 Running 0 73m
    mongo-mongodb-replicaset-2 1/1 Running 0 72m
    nodejs-nodeapp-577df49dcc-b5fq5 1/1 Running 0 5m4s
    nodejs-nodeapp-577df49dcc-bkk66 1/1 Running 0 5m4s
    nodejs-nodeapp-577df49dcc-lpmt2 1/1 Running 0 5m4s

To access the [`mongo` shell](https://docs.mongodb.com/manual/reference/program/mongo/#bin.mongo) on your Pods, you can use the [`kubectl exec` command](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#exec) and the username you used to create your `mongo-secret` in [Step 2](how-to-scale-a-node-js-application-with-mongodb-using-helm#step-2-%E2%80%94-creating-secrets-for-the-mongodb-replica-set). Access the `mongo` shell on the first Pod in the StatefulSet with the following command:

    kubectl exec -it mongo-mongodb-replicaset-0 -- mongo -u your_database_username -p --authenticationDatabase admin

When prompted, enter the password associated with this username:

    OutputMongoDB shell version v4.1.9
    Enter password: 

You will be dropped into an administrative shell:

    OutputMongoDB server version: 4.1.9
    Welcome to the MongoDB shell.
    ...
    
    db:PRIMARY>

Though the prompt itself includes this information, you can manually check to see which replica set member is the primary with the [`rs.isMaster()` method](https://docs.mongodb.com/manual/reference/command/isMaster/#dbcmd.isMaster):

    rs.isMaster()

You will see output like the following, indicating the hostname of the primary:

    Outputdb:PRIMARY> rs.isMaster()
    {
            "hosts" : [
                    "mongo-mongodb-replicaset-0.mongo-mongodb-replicaset.default.svc.cluster.local:27017",
                    "mongo-mongodb-replicaset-1.mongo-mongodb-replicaset.default.svc.cluster.local:27017",
                    "mongo-mongodb-replicaset-2.mongo-mongodb-replicaset.default.svc.cluster.local:27017"
            ],
            ...
            "primary" : "mongo-mongodb-replicaset-0.mongo-mongodb-replicaset.default.svc.cluster.local:27017",
            ...

Next, switch to your `sharkinfo` database:

    use sharkinfo

    Outputswitched to db sharkinfo

List the collections in the database:

    show collections

    Outputsharks

Output the documents in the collection:

    db.sharks.find()

You will see the following output:

    Output{ "_id" : ObjectId("5cb7702c9111a5451c6dc8bb"), "name" : "Megalodon Shark", "character" : "Ancient", "__v" : 0 }
    { "_id" : ObjectId("5cb77054fcdbf563f3b47365"), "name" : "Whale Shark", "character" : "Large", "__v" : 0 }

Exit the MongoDB Shell:

    exit

Now that we have checked the data on our primary, let’s check that it’s being replicated to a secondary. `kubectl exec` into `mongo-mongodb-replicaset-1` with the following command:

    kubectl exec -it mongo-mongodb-replicaset-1 -- mongo -u your_database_username -p --authenticationDatabase admin

Once in the administrative shell, we will need to use the `db.setSlaveOk()` method to permit read operations from the secondary instance:

    db.setSlaveOk(1)

Switch to the `sharkinfo` database:

    use sharkinfo

    Outputswitched to db sharkinfo

Permit the read operation of the documents in the `sharks` collection:

    db.setSlaveOk(1)

Output the documents in the collection:

    db.sharks.find()

You should now see the same information that you saw when running this method on your primary instance:

    Outputdb:SECONDARY> db.sharks.find()
    { "_id" : ObjectId("5cb7702c9111a5451c6dc8bb"), "name" : "Megalodon Shark", "character" : "Ancient", "__v" : 0 }
    { "_id" : ObjectId("5cb77054fcdbf563f3b47365"), "name" : "Whale Shark", "character" : "Large", "__v" : 0 }

This output confirms that your application data is being replicated between the members of your replica set.

## Conclusion

You have now deployed a replicated, highly-available shark information application on a Kubernetes cluster using Helm charts. This demo application and the workflow outlined in this tutorial can act as a starting point as you build custom charts for your application and take advantage of Helm’s **stable** repository and [other chart repositories](https://github.com/bitnami/charts/tree/master/bitnami).

As you move toward production, consider implementing the following:

- **Centralized logging and monitoring**. Please see the [relevant discussion](modernizing-applications-for-kubernetes#deploying-on-kubernetes) in [Modernizing Applications for Kubernetes](modernizing-applications-for-kubernetes) for a general overview. You can also look at [How To Set Up an Elasticsearch, Fluentd and Kibana (EFK) Logging Stack on Kubernetes](how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes) to learn how to set up a logging stack with [Elasticsearch](https://www.elastic.co/), [Fluentd](https://www.fluentd.org/), and [Kibana](https://www.elastic.co/products/kibana). Also check out [An Introduction to Service Meshes](an-introduction-to-service-meshes) for information about how service meshes like [Istio](https://istio.io/) implement this functionality.
- **Ingress Resources to route traffic to your cluster**. This is a good alternative to a LoadBalancer in cases where you are running multiple Services, which each require their own LoadBalancer, or where you would like to implement application-level routing strategies (A/B & canary tests, for example). For more information, check out [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes) and the [related discussion](an-introduction-to-service-meshes#routing-and-traffic-configuration) of routing in the service mesh context in [An Introduction to Service Meshes](an-introduction-to-service-meshes).
- **Backup strategies for your Kubernetes objects**. For guidance on implementing backups with [Velero](https://github.com/heptio/velero) (formerly Heptio Ark) with DigitalOcean’s Kubernetes product, please see [How To Back Up and Restore a Kubernetes Cluster on DigitalOcean Using Heptio Ark](how-to-back-up-and-restore-a-kubernetes-cluster-on-digitalocean-using-heptio-ark).

To learn more about Helm, see [An Introduction to Helm, the Package Manager for Kubernetes](an-introduction-to-helm-the-package-manager-for-kubernetes), [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager), and the [Helm documentation](https://helm.sh/docs/).
