---
author: neependrakhare
date: 2018-09-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/webinar-series-building-blocks-for-doing-ci-cd-with-kubernetes
---

# Webinar Series: Building Blocks for Doing CI/CD with Kubernetes

## Webinar Series

This article supplements a [webinar series on doing CI/CD with Kubernetes](https://go.digitalocean.com/cicd-on-k8s). The series discusses how to take a Cloud Native approach to building, testing, and deploying applications, covering release management, Cloud Native tools, Service Meshes, and CI/CD tools that can be used with Kubernetes. It is designed to help developers and businesses that are interested in integrating CI/CD best practices with Kubernetes into their workflows.

This tutorial includes the concepts and commands from the first session of the series, Building Blocks for Doing CI/CD with Kubernetes.

<iframe width="854" height="480" src="//www.youtube.com/embed/XxxlmkKdw6M?rel=0" frameborder="0" allowfullscreen></iframe>

## Introduction

If you are getting started with [containers](webinar-series-getting-started-with-containers), you will likely want to know how to automate building, testing, and deployment. By taking a [Cloud Native](https://github.com/cncf/toc/blob/master/DEFINITION.md) approach to these processes, you can leverage the right infrastructure APIs to package and deploy applications in an automated way.

Two building blocks for doing automation include _container images_ and _container orchestrators_. Over the last year or so, [Kubernetes](https://kubernetes.io/) has become the default choice for container orchestration. In this first article of the **CI/CD with Kubernetes** series, you will:

- Build container images with [Docker](https://www.docker.com/), [Buildah](https://github.com/projectatomic/buildah), and [Kaniko](https://github.com/GoogleContainerTools/kaniko).
- Set up a Kubernetes cluster with [Terraform](https://www.terraform.io/), and create _Deployments_ and _Services_.
- Extend the functionality of a Kubernetes cluster with _Custom Resources_. 

By the end of this tutorial, you will have container images built with Docker, Buildah, and Kaniko, and a Kubernetes cluster with Deployments, Services, and Custom Resources.

Future articles in the series will cover related topics: package management for Kubernetes, CI/CD tools like [Jenkins X](https://jenkins-x.io/) and [Spinnaker](https://www.spinnaker.io/), Services Meshes, and GitOps.

## Prerequisites

- An Ubuntu 16.04 server with a non-root user account. Follow our [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial for guidance.
- [Docker](https://www.docker.com/) installed on your server. Please follow Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04) for installation instructions.
- A [Docker Hub account](https://hub.docker.com). For an overview on getting started with Docker Hub, please see [these instructions](https://docs.docker.com/docker-hub/).  
- A DigitalOcean account and personal access token. Please refer to [these instructions](https://www.digitalocean.com/docs/api/create-personal-access-token/) to get your access token. 
- Familiarity with containers and Docker. Please refer to the [Webinar Series: Getting Started with Containers](webinar-series-getting-started-with-containers) for more details. 
- Familiarity with Kubernetes concepts. Please refer to [An Introduction to Kubernetes](an-introduction-to-kubernetes) for more details. 

## Step 1 — Building Container Images with Docker and Buildah

A container image is a self-contained entity with its own application code, runtime, and dependencies that you can use to create and run containers. You can use different tools to create container images, and in this step you will build containers with two of them: Docker and Buildah.

### Building Container Images with Dockerfiles

Docker builds your container images automatically by reading instructions from a Dockerfile, a text file that includes the commands required to assemble a container image. Using the `docker image build` command, you can create an automated build that will execute the command-line instructions provided in the Dockerfile. When building the image, you will also pass the _build context_ with the Dockerfile, which contains the set of files required to create an environment and run an application in the container image.

Typically, you will create a project folder for your Dockerfile and build context. Create a folder called `demo` to begin:

    mkdir demo
    cd demo

Next, create a Dockerfile inside the `demo` folder:

    nano Dockerfile

Add the following content to the file:

~/demo/Dockerfile

    FROM ubuntu:16.04
    
    LABEL MAINTAINER neependra@cloudyuga.guru
    
    RUN apt-get update \
        && apt-get install -y nginx \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
        && echo "daemon off;" >> /etc/nginx/nginx.conf
    
    EXPOSE 80
    CMD ["nginx"]

This Dockerfile consists of a set of instructions that will build an image to run Nginx. During the build process `ubuntu:16.04` will function as the base image, and the `nginx` package will be installed. Using the `CMD` instruction, you’ve also configured `nginx` to be the default command when the container starts.

Next, you’ll build the container image with the `docker image build` command, using the current directory (.) as the build context. Passing the `-t` option to this command names the image `nkhare/nginx:latest`:

    sudo docker image build -t nkhare/nginx:latest .

You will see the following output:

    OutputSending build context to Docker daemon 49.25MB
    Step 1/5 : FROM ubuntu:16.04
     ---> 7aa3602ab41e
    Step 2/5 : MAINTAINER neependra@cloudyuga.guru
     ---> Using cache
     ---> 552b90c2ff8d
    Step 3/5 : RUN apt-get update && apt-get install -y nginx && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && echo "daemon off;" >> /etc/nginx/nginx.conf
     ---> Using cache
     ---> 6bea966278d8
    Step 4/5 : EXPOSE 80
     ---> Using cache
     ---> 8f1c4281309e
    Step 5/5 : CMD ["nginx"]
     ---> Using cache
     ---> f545da818f47
    Successfully built f545da818f47
    Successfully tagged nginx:latest

Your image is now built. You can list your Docker images using the following command:

    docker image ls

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    nkhare/nginx latest 4073540cbcec 3 seconds ago 171MB
    ubuntu 16.04 7aa3602ab41e 11 days ago     

You can now use the `nkhare/nginx:latest` image to create containers.

### Building Container Images with Project Atomic-Buildah

Buildah is a CLI tool, developed by [Project Atomic](https://github.com/projectatomic/), for quickly building _Open Container Initiative ([OCI](https://www.opencontainers.org))_-compliant images. OCI provides specifications for container runtimes and images in an effort to standardize industry best practices.

Buildah can create an image either from a working container or from a Dockerfile. It can build images completely in user space without the Docker daemon, and can perform image operations like `build`, `list`, `push`, and `tag`. In this step, you’ll compile Buildah from source and then use it to create a container image.

To install Buildah you will need the required dependencies, including tools that will enable you to manage packages and package security, among other things. Run the following commands to install these packages:

     cd
     sudo apt-get install software-properties-common
     sudo add-apt-repository ppa:alexlarsson/flatpak
     sudo add-apt-repository ppa:gophers/archive
     sudo apt-add-repository ppa:projectatomic/ppa
     sudo apt-get update
     sudo apt-get install bats btrfs-tools git libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme11-dev libostree-dev libseccomp-dev libselinux1-dev skopeo-containers go-md2man

Because you will compile the `buildah` source code to create its package, you’ll also need to install [Go](https://golang.org/):

    sudo apt-get update
    sudo curl -O https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz
    sudo tar -xvf go1.8.linux-amd64.tar.gz
    sudo mv go /usr/local
    sudo echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    source ~/.profile
    go version 

You will see the following output, indicating a successful installation:

    Outputgo version go1.8 linux/amd64

You can now get the `buildah` source code to create its package, along with the `runc` binary. `runc` is the implementation of the `OCI` container runtime, which you will use to run your Buildah containers.

Run the following commands to install `runc` and `buildah`:

    mkdir ~/buildah
    cd ~/buildah
    export GOPATH=`pwd`
    git clone https://github.com/containers/buildah ./src/github.com/containers/buildah
    cd ./src/github.com/containers/buildah
    make runc all TAGS="apparmor seccomp"
    sudo cp ~/buildah/src/github.com/opencontainers/runc/runc /usr/bin/.
    sudo apt install buildah 

Next, create the `/etc/containers/registries.conf` file to configure your container registries:

    sudo nano /etc/containers/registries.conf

Add the following content to the file to specify your registries:

/etc/containers/registries.conf

    
    # This is a system-wide configuration file used to
    # keep track of registries for various container backends.
    # It adheres to TOML format and does not support recursive
    # lists of registries.
    
    # The default location for this configuration file is /etc/containers/registries.conf.
    
    # The only valid categories are: 'registries.search', 'registries.insecure',
    # and 'registries.block'.
    
    [registries.search]
    registries = ['docker.io', 'registry.fedoraproject.org', 'quay.io', 'registry.access.redhat.com', 'registry.centos.org']
    
    # If you need to access insecure registries, add the registry's fully-qualified name.
    # An insecure registry is one that does not have a valid SSL certificate or only does HTTP.
    [registries.insecure]
    registries = []
    
    # If you need to block pull access from a registry, uncomment the section below
    # and add the registries fully-qualified name.
    #
    # Docker only
    [registries.block]
    registries = []

The `registries.conf` configuration file specifies which registries should be consulted when completing image names that do not include a registry or domain portion.

Now run the following command to build an image, using the `https://github.com/do-community/rsvpapp-webinar1` repository as the build context. This repository also contains the relevant Dockerfile:

    sudo buildah build-using-dockerfile -t rsvpapp:buildah github.com/do-community/rsvpapp-webinar1 

This command creates an image named `rsvpapp:buildah` from the Dockerfille available in the `https://github.com/do-community/rsvpapp-webinar1` repository.

To list the images, use the following command:

    sudo buildah images

You will see the following output:

    OutputIMAGE ID IMAGE NAME CREATED AT SIZE
    b0c552b8cf64 docker.io/teamcloudyuga/python:alpine Sep 30, 2016 04:39 95.3 MB
    22121fd251df localhost/rsvpapp:buildah Sep 11, 2018 14:34 114 MB

One of these images is `localhost/rsvpapp:buildah`, which you just created. The other, `docker.io/teamcloudyuga/python:alpine`, is the base image from the Dockerfile.

Once you have built the image, you can push it to Docker Hub. This will allow you to store it for future use. You will first need to login to your Docker Hub account from the command line:

    docker login -u your-dockerhub-username -p your-dockerhub-password

Once the login is successful, you will get a file, `~/.docker/config.json`, that will contain your Docker Hub credentials. You can then use that file with `buildah` to push images to Docker Hub.

For example, if you wanted to push the image you just created, you could run the following command, citing the `authfile` and the image to push:

    sudo buildah push --authfile ~/.docker/config.json rsvpapp:buildah docker://your-dockerhub-username/rsvpapp:buildah

You can also push the resulting image to the local Docker daemon using the following command:

    sudo buildah push rsvpapp:buildah docker-daemon:rsvpapp:buildah

Finally, take a look at the Docker images you have created:

    sudo docker image ls

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    rsvpapp buildah 22121fd251df 4 minutes ago 108MB
    nkhare/nginx latest 01f0982d91b8 17 minutes ago 172MB
    ubuntu 16.04 b9e15a5d1e1a 5 days ago 115MB

As expected, you should now see a new image, `rsvpapp:buildah`, that has been exported using `buildah`.

You now have experience building container images with two different tools, Docker and Buildah. Let’s move on to discussing how to set up a cluster of containers with Kubernetes.

## Step 2 — Setting Up a Kubernetes Cluster on DigitalOcean using kubeadm and Terraform

There are different ways to set up Kubernetes on DigitalOcean. To learn more about how to set up Kubernetes with [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/), for example, you can look at [How To Create a Kubernetes Cluster Using Kubeadm on Ubuntu 18.04](how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04).

Since this tutorial series discusses taking a Cloud Native approach to application development, we’ll apply this methodology when setting up our cluster. Specifically, we will automate our cluster creation using kubeadm and [Terraform](https://www.terraform.io/), a tool that simplifies creating and changing infrastructure.

Using your personal access token, you will connect to DigitalOcean with Terraform to provision 3 servers. You will run the `kubeadm` commands inside of these VMs to create a 3-node Kubernetes cluster containing one master node and two workers.

On your Ubuntu server, create a pair of [SSH keys](how-to-configure-ssh-key-based-authentication-on-a-linux-server), which will allow password-less logins to your VMs:

    ssh-keygen -t rsa

You will see the following output:

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (~/.ssh/id_rsa): 

Press `ENTER` to save the key pair in the `~/.ssh` directory in your home directory, or enter another destination.

Next, you will see the following prompt:

    OutputEnter passphrase (empty for no passphrase): 

In this case, press `ENTER` without a password to enable password-less logins to your nodes.

You will see a confirmation that your key pair has been created:

    OutputYour identification has been saved in ~/.ssh/id_rsa.
    Your public key has been saved in ~/.ssh/id_rsa.pub.
    The key fingerprint is:
    SHA256:lCVaexVBIwHo++NlIxccMW5b6QAJa+ZEr9ogAElUFyY root@3b9a273f18b5
    The key's randomart image is:
    +---[RSA 2048]----+
    |++.E ++o=o*o*o |
    |o +..=.B = o |
    |. .* = * o |
    | . =.o + * |
    | . . o.S + . |
    | . +. . |
    | . ... = |
    | o= . |
    | ... |
    +----[SHA256]-----+

Get your public key by running the following command, which will display it in your terminal:

    cat ~/.ssh/id_rsa.pub

Add this key to your DigitalOcean account by following [these directions](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/to-account/).

Next, install Terraform:

    sudo apt-get update
    sudo apt-get install unzip
    wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
    unzip terraform_0.11.7_linux_amd64.zip
    sudo mv terraform /usr/bin/.
    terraform version

You will see output confirming your Terraform installation:

    OutputTerraform v0.11.7

Next, run the following commands to install `kubectl`, a CLI tool that will communicate with your Kubernetes cluster, and to create a `~/.kube` directory in your user’s home directory:

    sudo apt-get install apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo touch /etc/apt/sources.list.d/kubernetes.list 
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install kubectl
    mkdir -p ~/.kube

Creating the `~/.kube` directory will enable you to copy the configuration file to this location. You’ll do that once you run the Kubernetes setup script later in this section. By default, the `kubectl` CLI looks for the configuration file in the `~/.kube` directory to access the cluster.

Next, clone the sample project repository for this tutorial, which contains the Terraform scripts for setting up the infrastructure:

    git clone https://github.com/do-community/k8s-cicd-webinars.git

Go to the Terrafrom script directory:

    cd k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/

Get a fingerprint of your SSH public key:

    ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}'

You will see output like the following, with the highlighted portion representing your key:

    OutputMD5:dd:d1:b7:0f:6d:30:c0:be:ed:ae:c7:b9:b8:4a:df:5e

Keep in mind that your key will differ from what’s shown here.

Save the fingerprint to an environmental variable so Terraform can use it:

    export FINGERPRINT=dd:d1:b7:0f:6d:30:c0:be:ed:ae:c7:b9:b8:4a:df:5e

Next, export your DO personal access token:

    export TOKEN=your-do-access-token

Now take a look at the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/` project directory:

    ls

    Outputcluster.tf destroy.sh files outputs.tf provider.tf script.sh

This folder contains the necessary scripts and configuration files for deploying your Kubernetes cluster with Terraform.

Execute the `script.sh` script to trigger the Kubernetes cluster setup:

    ./script.sh

When the script execution is complete, `kubectl` will be configured to use the Kubernetes cluster you’ve created.

List the cluster nodes using `kubectl get nodes`:

    kubectl get nodes

    OutputNAME STATUS ROLES AGE VERSION
    k8s-master-node Ready master 2m v1.10.0
    k8s-worker-node-1 Ready <none> 1m v1.10.0
    k8s-worker-node-2 Ready <none> 57s v1.10.0

You now have one master and two worker nodes in the `Ready` state.

With a Kubernetes cluster set up, you can now explore another option for building container images: [Kaniko from Google](https://github.com/GoogleContainerTools/kaniko).

## Step 3 — Building Container Images with Kaniko

Earlier in this tutorial, you built container images with Dockerfiles and Buildah. But what if you could build container images directly on Kubernetes? There are ways to run the `docker image build` command inside of Kubernetes, but this isn’t native Kubernetes tooling. You would have to depend on the Docker daemon to build images, and it would need to run on one of the [_Pods_](https://kubernetes.io/docs/concepts/workloads/pods/pod/) in the cluster.

A tool called Kaniko allows you to build container images with a Dockerfile on an existing Kubernetes cluster. In this step, you will build a container image with a Dockerfile using Kaniko. You will then push this image to Docker Hub.

In order to push your image to Docker Hub, you will need to pass your Docker Hub credentials to Kaniko. In the previous step, you logged into Docker Hub and created a `~/.docker/config.json` file with your login credentials. Let’s use this configuration file to create a Kubernetes _ConfigMap_ object to store the credentials inside the Kubernetes cluster. The ConfigMap object is used to store configuration parameters, decoupling them from your application.

To create a ConfigMap called `docker-config` using the `~/.docker/config.json` file, run the following command:

    sudo kubectl create configmap docker-config --from-file=$HOME/.docker/config.json

Next, you can create a Pod definition file called `pod-kaniko.yml` in the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/` directory (though it can go anywhere).

First, make sure that you are in the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/` directory:

    cd ~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/

Create the `pod-kaniko.yml` file:

    nano pod-kaniko.yml

Add the following content to the file to specify what will happen when you deploy your Pod. Be sure to replace `your-dockerhub-username` in the Pod’s `args` field with your own Docker Hub username:

~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/pod-kaniko.yaml

    apiVersion: v1
    kind: Pod
    metadata:
      name: kaniko
    spec:
      containers:
      - name: kaniko
        image: gcr.io/kaniko-project/executor:latest
        args: ["--dockerfile=./Dockerfile",
                "--context=/tmp/rsvpapp/",
                "--destination=docker.io/your-dockerhub-username/rsvpapp:kaniko",
                "--force" ]
        volumeMounts:
          - name: docker-config
            mountPath: /root/.docker/
          - name: demo
            mountPath: /tmp/rsvpapp
      restartPolicy: Never
      initContainers:
        - image: python
          name: demo
          command: ["/bin/sh"]
          args: ["-c", "git clone https://github.com/do-community/rsvpapp-webinar1.git /tmp/rsvpapp"] 
          volumeMounts:
          - name: demo
            mountPath: /tmp/rsvpapp
      restartPolicy: Never
      volumes:
        - name: docker-config
          configMap:
            name: docker-config
        - name: demo
          emptyDir: {}

This configuration file describes what will happen when your Pod is deployed. First, the [Init container](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) will clone the Git repository with the Dockerfile, `https://github.com/do-community/rsvpapp-webinar1.git`, into a shared volume called `demo`. Init containers run before application containers and can be used to run utilties or other tasks that are not desirable to run from your application containers. Your application container, `kaniko`, will then build the image using the Dockerfile and push the resulting image to Docker Hub, using the credentials you passed to the ConfigMap volume `docker-config`.

To deploy the `kaniko` pod, run the following command:

    kubectl apply -f pod-kaniko.yml 

You will see the following confirmation:

    Outputpod/kaniko created

Get the list of pods:

    kubectl get pods

You will see the following list:

    OutputNAME READY STATUS RESTARTS AGE
    kaniko 0/1 Init:0/1 0 47s

Wait a few seconds, and then run `kubectl get pods` again for a status update:

    kubectl get pods

You will see the following:

    OutputNAME READY STATUS RESTARTS AGE
    kaniko 1/1 Running 0 1m

Finally, run `kubectl get pods` once more for a final status update:

    kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    kaniko 0/1 Completed 0 2m

This sequence of output tells you that the Init container ran, cloning the GitHub repository inside of the `demo` volume. After that, the Kaniko build process ran and eventually finished.

Check the logs of the pod:

    kubectl logs kaniko

You will see the following output:

    Outputtime="2018-08-02T05:01:24Z" level=info msg="appending to multi args docker.io/your-dockerhub-username/rsvpapp:kaniko"
    time="2018-08-02T05:01:24Z" level=info msg="Downloading base image nkhare/python:alpine"
    .
    .
    .
    ime="2018-08-02T05:01:46Z" level=info msg="Taking snapshot of full filesystem..."
    time="2018-08-02T05:01:48Z" level=info msg="cmd: CMD"
    time="2018-08-02T05:01:48Z" level=info msg="Replacing CMD in config with [/bin/sh -c python rsvp.py]"
    time="2018-08-02T05:01:48Z" level=info msg="Taking snapshot of full filesystem..."
    time="2018-08-02T05:01:49Z" level=info msg="No files were changed, appending empty layer to config."
    2018/08/02 05:01:51 mounted blob: sha256:bc4d09b6c77b25d6d3891095ef3b0f87fbe90621bff2a333f9b7f242299e0cfd
    2018/08/02 05:01:51 mounted blob: sha256:809f49334738c14d17682456fd3629207124c4fad3c28f04618cc154d22e845b
    2018/08/02 05:01:51 mounted blob: sha256:c0cb142e43453ebb1f82b905aa472e6e66017efd43872135bc5372e4fac04031
    2018/08/02 05:01:51 mounted blob: sha256:606abda6711f8f4b91bbb139f8f0da67866c33378a6dcac958b2ddc54f0befd2
    2018/08/02 05:01:52 pushed blob sha256:16d1686835faa5f81d67c0e87eb76eab316e1e9cd85167b292b9fa9434ad56bf
    2018/08/02 05:01:53 pushed blob sha256:358d117a9400cee075514a286575d7d6ed86d118621e8b446cbb39cc5a07303b
    2018/08/02 05:01:55 pushed blob sha256:5d171e492a9b691a49820bebfc25b29e53f5972ff7f14637975de9b385145e04
    2018/08/02 05:01:56 index.docker.io/your-dockerhub-username/rsvpapp:kaniko: digest: sha256:831b214cdb7f8231e55afbba40914402b6c915ef4a0a2b6cbfe9efb223522988 size: 1243

From the logs, you can see that the `kaniko` container built the image from the Dockerfile and pushed it to your Docker Hub account.

You can now pull the Docker image. Be sure again to replace `your-dockerhub-username` with your Docker Hub username:

    docker pull your-dockerhub-username/rsvpapp:kaniko

You will see a confirmation of the pull:

    Outputkaniko: Pulling from your-dockerhub-username/rsvpapp
    c0cb142e4345: Pull complete 
    bc4d09b6c77b: Pull complete 
    606abda6711f: Pull complete 
    809f49334738: Pull complete 
    358d117a9400: Pull complete 
    5d171e492a9b: Pull complete 
    Digest: sha256:831b214cdb7f8231e55afbba40914402b6c915ef4a0a2b6cbfe9efb223522988
    Status: Downloaded newer image for your-dockerhub-username/rsvpapp:kaniko

You have now successfully built a Kubernetes cluster and created new images from within the cluster. Let’s move on to discussing _Deployments_ and _Services_.

## Step 4 — Create Kubernetes Deployments and Services

Kubernetes _Deployments_ allow you to run your applications. Deployments specify the desired state for your Pods, ensuring consistency across your rollouts. In this step, you will create an [Nginx](https://www.nginx.com/) deployment file called `deployment.yml` in the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/` directory to create an Nginx Deployment.

First, open the file:

    nano deployment.yml

Add the following configuration to the file to define your Nginx Deployment:

~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terraform/deployment.yml

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.7.9
            ports:
            - containerPort: 80
    

This file defines a Deployment named `nginx-deployment` that creates three pods, each running an `nginx` container on port `80`.

To deploy the Deployment, run the following command:

    kubectl apply -f deployment.yml

You will see a confirmation that the Deployment was created:

    Outputdeployment.apps/nginx-deployment created

List your Deployments:

    kubectl get deployments

    OutputNAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE
    nginx-deployment 3 3 3 3 29s

You can see that the `nginx-deployment` Deployment has been created and the desired and current count of the Pods are same: `3`.

To list the Pods that the Deployment created, run the following command:

    kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    kaniko 0/1 Completed 0 9m
    nginx-deployment-75675f5897-nhwsp 1/1 Running 0 1m
    nginx-deployment-75675f5897-pxpl9 1/1 Running 0 1m
    nginx-deployment-75675f5897-xvf4f 1/1 Running 0 1m

You can see from this output that the desired number of Pods are running.

To expose an application deployment internally and externally, you will need to create a Kubernetes object called a _Service_. Each Service specifies a _ServiceType_, which defines how the service is exposed. In this example, we will use a _NodePort_ ServiceType, which exposes the Service on a static port on each node.

To do this, create a file, `service.yml`, in the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom/` directory:

    nano service.yml

Add the following content to define your Service:

~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom/service.yml

    kind: Service
    apiVersion: v1
    metadata:
      name: nginx-service
    spec:
      selector:
        app: nginx
      type: NodePort
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        nodePort: 30111

These settings define the Service, `nginx-service`, and specify that it will target port `80` on your Pod. `nodePort` defines the port where the application will accept external traffic.

To deploy the Service run the following command:

    kubectl apply -f service.yml

You will see a confirmation:

    Outputservice/nginx-service created

List the Services:

    kubectl get service

You will see the following list:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kubernetes ClusterIP 10.96.0.1 <none> 443/TCP 5h
    nginx-service NodePort 10.100.98.213 <none> 80:30111/TCP 7s

Your Service, `nginx-service`, is exposed on port `30111` and you can now access it on any of the node’s public IPs. For example, navigating to `http://node_1_ip:30111` or `http://node_2_ip:30111` should take you to Nginx’s standard welcome page.

Once you have tested the Deployment, you can clean up both the Deployment and Service:

    kubectl delete deployment nginx-deployment
    kubectl delete service nginx-service

These commands will delete the Deployment and Service you have created.

Now that you have worked with Deployments and Services, let’s move on to creating Custom Resources.

## Step 5 — Creating Custom Resources in Kubernetes

Kubernetes offers limited but production-ready functionalities and features. It is possible to extend Kubernetes’ offerings, however, using its [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) feature. In Kubernetes, a _resource_ is an endpoint in the Kubernetes API that stores a collection of API _objects_. A Pod resource contains a collection of Pod objects, for instance. With Custom Resources, you can add custom offerings for networking, storage, and more. These additions can be created or removed at any point.

In addition to creating custom objects, you can also employ sub-controllers of the Kubernetes _Controller_ component in the control plane to make sure that the current state of your objects is equal to the desired state. The Kubernetes Controller has sub-controllers for specified objects. For example, [_ReplicaSet_](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) is a sub-controller that makes sure the desired Pod count remains consistent. When you combine a Custom Resource with a Controller, you get a true _declarative API_ that allows you to specify the desired state of your resources.

In this step, you will create a Custom Resource and related objects.

To create a Custom Resource, first make a file called `crd.yml` in the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom/` directory:

    nano crd.yml

Add the following Custom Resource Definition (CRD):

~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom/crd.yml

    apiVersion: apiextensions.k8s.io/v1beta1
    kind: CustomResourceDefinition
    metadata:
      name: webinars.digitalocean.com
    spec:
      group: digitalocean.com
      version: v1
      scope: Namespaced
      names:
        plural: webinars
        singular: webinar
        kind: Webinar
        shortNames:
        - wb

To deploy the CRD defined in `crd.yml`, run the following command:

    kubectl create -f crd.yml 

You will see a confirmation that the resource has been created:

    Outputcustomresourcedefinition.apiextensions.k8s.io/webinars.digitalocean.com created

The `crd.yml` file has created a new RESTful resource path: `/apis/digtialocean.com/v1/namespaces/*/webinars`. You can now refer to your objects using `webinars`, `webinar`, `Webinar`, and `wb`, as you listed them in the `names` section of the `CustomResourceDefinition`. You can check the RESTful resource with the following command:

    kubectl proxy & curl 127.0.0.1:8001/apis/digitalocean.com

**Note:** If you followed the initial server setup guide in the prerequisites, then you will need to allow traffic to port `8001` in order for this test to work. Enable traffic to this port with the following command:

    sudo ufw allow 8001

You will see the following output:

    OutputHTTP/1.1 200 OK
    Content-Length: 238
    Content-Type: application/json
    Date: Fri, 03 Aug 2018 06:10:12 GMT
    
    {
        "apiVersion": "v1", 
        "kind": "APIGroup", 
        "name": "digitalocean.com", 
        "preferredVersion": {
            "groupVersion": "digitalocean.com/v1", 
            "version": "v1"
        }, 
        "serverAddressByClientCIDRs": null, 
        "versions": [
            {
                "groupVersion": "digitalocean.com/v1", 
                "version": "v1"
            }
        ]
    }

Next, create the object for using new Custom Resources by opening a file called `webinar.yml`:

    nano webinar.yml

Add the following content to create the object:

~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom/webinar.yml

    apiVersion: "digitalocean.com/v1"
    kind: Webinar
    metadata:
      name: webinar1
    spec:
      name: webinar
      image: nginx

Run the following command to push these changes to the cluster:

    kubectl apply -f webinar.yml 

You will see the following output:

    Outputwebinar.digitalocean.com/webinar1 created

You can now manage your `webinar` objects using `kubectl`. For example:

    kubectl get webinar

    OutputNAME CREATED AT
    webinar1 21s

You now have an object called `webinar1`. If there had been a Controller, it would have intercepted the object creation and performed any defined operations.

### Deleting a Custom Resource Definition

To delete all of the objects for your Custom Resource, use the following command:

    kubectl delete webinar --all

You will see:

    Outputwebinar.digitalocean.com "webinar1" deleted

Remove the Custom Resource itself:

    kubectl delete crd webinars.digitalocean.com

You will see a confirmation that it has been deleted:

    Outputcustomresourcedefinition.apiextensions.k8s.io "webinars.digitalocean.com" deleted

After deletion you will not have access to the API endpoint that you tested earlier with the `curl` command.

This sequence is an introduction to how you can extend Kubernetes functionalities without modifying your Kubernetes code.

## Step 6 — Deleting the Kubernetes Cluster

To destroy the Kubernetes cluster itself, you can use the `destroy.sh` script from the `~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom` folder. Make sure that you are in this directory:

    cd ~/k8s-cicd-webinars/webinar1/2-kubernetes/1-Terrafrom

Run the script:

    ./destroy.sh

By running this script, you’ll allow Terraform to communicate with the DigitalOcean API and delete the servers in your cluster.

## Conclusion

In this tutorial, you used different tools to create container images. With these images, you can create containers in any environment. You also set up a Kubernetes cluster using Terraform, and created Deployment and Service objects to deploy and expose your application. Additionally, you extended Kubernetes’ functionality by defining a Custom Resource.

You now have a solid foundation to build a CI/CD environment on Kubernetes, which we’ll explore in future articles.
