---
author: Kathleen Juell
date: 2019-06-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-istio-with-kubernetes
---

# How To Install and Use Istio With Kubernetes

## Introduction

A service mesh is an infrastructure layer that allows you to manage communication between your application’s microservices. As more developers work with microservices, service meshes have evolved to make that work easier and more effective by consolidating common management and administrative tasks in a distributed setup.

Using a service mesh like [Istio](https://istio.io/) can simplify tasks like service discovery, routing and traffic configuration, encryption and authentication/authorization, and monitoring and telemetry. Istio, in particular, is designed to work without major changes to pre-existing service code. When working with [Kubernetes](https://kubernetes.io/), for example, it is possible to add service mesh capabilities to applications running in your cluster by building out Istio-specific objects that work with existing application resources.

In this tutorial, you will install Istio using the [Helm](https://helm.sh/) package manager for Kubernetes. You will then use Istio to expose a demo [Node.js](https://nodejs.org/) application to external traffic by creating [Gateway](https://istio.io/docs/reference/config/networking/v1alpha3/gateway/) and [Virtual Service](https://istio.io/docs/reference/config/networking/v1alpha3/virtual-service/) resources. Finally, you will access the [Grafana](https://grafana.com/) telemetry addon to visualize your application traffic data.

## Prerequisites

To complete this tutorial, you will need:

- A Kubernetes 1.10+ cluster with role-based access control (RBAC) enabled. This setup will use a [DigitalOcean Kubernetes cluster](https://www.digitalocean.com/products/kubernetes/) with three nodes, but you are free to [create a cluster using another method](how-to-create-a-kubernetes-1-11-cluster-using-kubeadm-on-ubuntu-18-04).

**Note:** We highly recommend a cluster with at least 8GB of available memory and 4vCPUs for this setup. This tutorial will use three of DigitalOcean’s standard 4GB/2vCPU Droplets as nodes.

- The `kubectl` command-line tool installed on a development server and configured to connect to your cluster. You can read more about installing `kubectl` in the [official documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- Helm installed on your development server and Tiller installed on your cluster, following the directions outlined in Steps 1 and 2 of [How To Install Software on Kubernetes Clusters with the Helm Package Manager](how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager).
- [Docker](https://www.docker.com/) installed on your development server. If you are working with Ubuntu 18.04, follow Steps 1 and 2 of [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04); otherwise, follow the [official documentation](https://docs.docker.com/install/) for information about installing on other operating systems. Be sure to add your non-root user to the `docker` group, as described in Step 2 of the linked tutorial.
- A [Docker Hub](https://hub.docker.com/) account. For an overview of how to set this up, refer to [this introduction](https://docs.docker.com/docker-hub/) to Docker Hub.

## Step 1 — Packaging the Application

To use our demo application with Kubernetes, we will need to clone the code and package it so that the [`kubelet` agent](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) can pull the image.

Our first step will be to clone the [nodejs-image-demo respository](https://github.com/do-community/nodejs-image-demo) from the [DigitalOcean Community GitHub account](https://github.com/do-community). This repository includes the code from the setup described in [How To Build a Node.js Application with Docker](how-to-build-a-node-js-application-with-docker), which describes how to build an image for a Node.js application and how to create a container using this image. You can find more information about the application itself in the series [From Containers to Kubernetes with Node.js](https://www.digitalocean.com/community/tutorial_series/from-containers-to-kubernetes-with-node-js).

To get started, clone the nodejs-image-demo repository into a directory called `istio_project`:

    git clone https://github.com/do-community/nodejs-image-demo.git istio_project

Navigate to the `istio_project` directory:

    cd istio_project

This directory contains files and folders for a shark information application that offers users basic information about sharks. In addition to the application files, the directory contains a Dockerfile with instructions for building a Docker image with the application code. For more information about the instructions in the Dockerfile, see [Step 3 of How To Build a Node.js Application with Docker](how-to-build-a-node-js-application-with-docker#step-3-%E2%80%94-writing-the-dockerfile).

To test that the application code and Dockerfile work as expected, you can build and tag the image using the [`docker build`](https://docs.docker.com/engine/reference/commandline/build/) command, and then use the image to run a demo container. Using the `-t` flag with `docker build` will allow you to tag the image with your Docker Hub username so that you can push it to Docker Hub once you’ve tested it.

Build the image with the following command:

    docker build -t your_dockerhub_username/node-demo .

The `.` in the command specifies that the build context is the current directory. We’ve named the image `node-demo`, but you are free to name it something else.

Once the build process is complete, you can list your images with [`docker images`](https://docs.docker.com/engine/reference/commandline/images/):

    docker images

You will see the following output confirming the image build:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    your_dockerhub_username/node-demo latest 37f1c2939dbf 5 seconds ago 77.6MB
    node 10-alpine 9dfa73010b19 2 days ago 75.3MB

Next, you’ll use `docker run` to create a container based on this image. We will include three flags with this command:

- `-p`: This publishes the port on the container and maps it to a port on our host. We will use port `80` on the host, but you should feel free to modify this as necessary if you have another process running on that port. For more information about how this works, see this discussion in the Docker docs on [port binding](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/binding/).
- `-d`: This runs the container in the background.
- `--name`: This allows us to give the container a customized name. 

Run the following command to build the container:

    docker run --name node-demo -p 80:8080 -d your_dockerhub_username/node-demo

Inspect your running containers with [`docker ps`](https://docs.docker.com/engine/reference/commandline/ps/):

    docker ps

You will see output confirming that your application container is running:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    49a67bafc325 your_dockerhub_username/node-demo "docker-entrypoint.s…" 8 seconds ago Up 6 seconds 0.0.0.0:80->8080/tcp node-demo

You can now visit your server IP to test your setup: `http://your_server_ip`. Your application will display the following landing page:

![Application Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Now that you have tested the application, you can stop the running container. Use `docker ps` again to get your `CONTAINER ID`:

    docker ps

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    49a67bafc325 your_dockerhub_username/node-demo "docker-entrypoint.s…" About a minute ago Up About a minute 0.0.0.0:80->8080/tcp node-demo

Stop the container with [`docker stop`](https://docs.docker.com/engine/reference/commandline/stop/). Be sure to replace the `CONTAINER ID` listed here with your own application `CONTAINER ID`:

    docker stop 49a67bafc325

Now that you have tested the image, you can push it to Docker Hub. First, log in to the Docker Hub account you created in the prerequisites:

    docker login -u your_dockerhub_username 

When prompted, enter your Docker Hub account password. Logging in this way will create a `~/.docker/config.json` file in your non-root user’s home directory with your Docker Hub credentials.

Push the application image to Docker Hub with the [`docker push` command](https://docs.docker.com/engine/reference/commandline/push/). Remember to replace `your_dockerhub_username` with your own Docker Hub username:

    docker push your_dockerhub_username/node-demo

You now have an application image that you can pull to run your application with Kubernetes and Istio. Next, you can move on to installing Istio with Helm.

## Step 2 — Installing Istio with Helm

Although Istio offers different installation methods, the documentation recommends using Helm to maximize flexibility in managing configuration options. We will install Istio with Helm and ensure that the Grafana addon is enabled so that we can visualize traffic data for our application.

First, add the Istio release repository:

    helm repo add istio.io https://storage.googleapis.com/istio-release/releases/1.1.7/charts/

This will enable you to use the Helm charts in the repository to install Istio.

Check that you have the repo:

    helm repo list

You should see the `istio.io` repo listed:

    OutputNAME URL                                                                
    stable https://kubernetes-charts.storage.googleapis.com                   
    local http://127.0.0.1:8879/charts                                       
    istio.io https://storage.googleapis.com/istio-release/releases/1.1.7/charts/

Next, install Istio’s [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) (CRDs) with the `istio-init` chart using the [`helm install` command](https://helm.sh/docs/helm/#helm-install):

    helm install --name istio-init --namespace istio-system istio.io/istio-init

    OutputNAME: istio-init
    LAST DEPLOYED: Fri Jun 7 17:13:32 2019
    NAMESPACE: istio-system
    STATUS: DEPLOYED
    ...

This command commits 53 CRDs to the [`kube-apiserver`](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/), making them available for use in the Istio mesh. It also creates a [namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) for the Istio objects called `istio-system` and uses the `--name` option to name the Helm _release_ `istio-init`. A release in Helm refers to a particular deployment of a chart with specific configuration options enabled.

To check that all of the required CRDs have been committed, run the following command:

    kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l

This should output the number `53`.

You can now install the `istio` chart. To ensure that the Grafana telemetry addon is installed with the chart, we will use the `--set grafana.enabled=true` configuration option with our `helm install` command. We will also use the installation protocol for our desired [configuration profile](https://istio.io/docs/setup/kubernetes/additional-setup/config-profiles/): the default profile. Istio has a number of configuration profiles to choose from when installing with Helm that allow you to customize the Istio [control plane and data plane sidecars](https://istio.io/docs/setup/kubernetes/additional-setup/config-profiles/). The default profile is recommended for production deployments, and we’ll use it to familiarize ourselves with the configuration options that we would use when moving to production.

Run the following `helm install` command to install the chart:

    helm install --name istio --namespace istio-system --set grafana.enabled=true istio.io/istio

    OutputNAME: istio
    LAST DEPLOYED: Fri Jun 7 17:18:33 2019
    NAMESPACE: istio-system
    STATUS: DEPLOYED
    ...

Again, we’re installing our Istio objects into the `istio-system` namespace and naming the release — in this case, `istio`.

We can verify that the [Service objects](https://kubernetes.io/docs/concepts/services-networking/service/) we expect for the default profile have been created with the following command:

    kubectl get svc -n istio-system

The Services we would expect to see here include `istio-citadel`, `istio-galley`, `istio-ingressgateway`, `istio-pilot`, `istio-policy`, `istio-sidecar-injector`, `istio-telemetry`, and `prometheus`. We would also expect to see the `grafana` Service, since we enabled this addon during installation:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    grafana ClusterIP 10.245.85.162 <none> 3000/TCP 3m26s
    istio-citadel ClusterIP 10.245.135.45 <none> 8060/TCP,15014/TCP 3m25s
    istio-galley ClusterIP 10.245.46.245 <none> 443/TCP,15014/TCP,9901/TCP 3m26s
    istio-ingressgateway LoadBalancer 10.245.171.39 174.138.125.110 15020:30707/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30285/TCP,15030:31668/TCP,15031:32297/TCP,15032:30853/TCP,15443:30406/TCP 3m26s
    istio-pilot ClusterIP 10.245.56.97 <none> 15010/TCP,15011/TCP,8080/TCP,15014/TCP 3m26s
    istio-policy ClusterIP 10.245.206.189 <none> 9091/TCP,15004/TCP,15014/TCP 3m26s
    istio-sidecar-injector ClusterIP 10.245.223.99 <none> 443/TCP 3m25s
    istio-telemetry ClusterIP 10.245.5.215 <none> 9091/TCP,15004/TCP,15014/TCP,42422/TCP 3m26s
    prometheus ClusterIP 10.245.100.132 <none> 9090/TCP 3m26s

We can also check for the corresponding Istio [Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) with the following command:

    kubectl get pods -n istio-system

The Pods corresponding to these services should have a `STATUS` of `Running`, indicating that the Pods are bound to nodes and that the containers associated with the Pods are running:

    OutputNAME READY STATUS RESTARTS AGE
    grafana-67c69bb567-t8qrg 1/1 Running 0 4m25s
    istio-citadel-fc966574d-v5rg5 1/1 Running 0 4m25s
    istio-galley-cf776876f-5wc4x 1/1 Running 0 4m25s
    istio-ingressgateway-7f497cc68b-c5w64 1/1 Running 0 4m25s
    istio-init-crd-10-bxglc 0/1 Completed 0 9m29s
    istio-init-crd-11-dv5lz 0/1 Completed 0 9m29s
    istio-pilot-785694f946-m5wp2 2/2 Running 0 4m25s
    istio-policy-79cff99c7c-q4z5x 2/2 Running 1 4m25s
    istio-sidecar-injector-c8ddbb99c-czvwq 1/1 Running 0 4m24s
    istio-telemetry-578b6f967c-zk56d 2/2 Running 1 4m25s
    prometheus-d8d46c5b5-k5wmg 1/1 Running 0 4m25s

The `READY` field indicates how many containers in a Pod are running. For more information, please consult the [documentation on Pod lifecycles](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/).

**Note:**  
If you see unexpected phases in the `STATUS` column, remember that you can troubleshoot your Pods with the following commands:

    kubectl describe pods your_pod -n pod_namespace
    kubectl logs your_pod -n pod_namespace

The final step in the Istio installation will be enabling the creation of [Envoy](https://www.envoyproxy.io/) proxies, which will be deployed as _sidecars_ to services running in the mesh.

Sidecars are typically used to add an extra layer of functionality in existing container environments. Istio’s [mesh architecture](https://istio.io/docs/concepts/what-is-istio/#architecture) relies on communication between Envoy sidecars, which comprise the data plane of the mesh, and the components of the control plane. In order for the mesh to work, we need to ensure that each Pod in the mesh will also run an Envoy sidecar.

There are two ways of accomplishing this goal: [manual sidecar injection](https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/#manual-sidecar-injection) and [automatic sidecar injection](https://istio.io/docs/setup/kubernetes/additional-setup/sidecar-injection/#automatic-sidecar-injection). We’ll enable automatic sidecar injection by [labeling](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) the namespace in which we will create our application objects with the label `istio-injection=enabled`. This will ensure that the [MutatingAdmissionWebhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook) controller can intercept requests to the `kube-apiserver` and perform a specific action — in this case, ensuring that all of our application Pods start with a sidecar.

We’ll use the `default` namespace to create our application objects, so we’ll apply the `istio-injection=enabled` label to that namespace with the following command:

    kubectl label namespace default istio-injection=enabled

We can verify that the command worked as intended by running:

    kubectl get namespace -L istio-injection

You will see the following output:

    OutputAME STATUS AGE ISTIO-INJECTION
    default Active 47m enabled
    istio-system Active 16m   
    kube-node-lease Active 47m   
    kube-public Active 47m   
    kube-system Active 47m   

With Istio installed and configured, we can move on to creating our application Service and [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) objects.

## Step 3 — Creating Application Objects

With the Istio mesh in place and configured to inject sidecar Pods, we can create an application [manifest](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#organizing-resource-configurations) with _specifications_ for our Service and Deployment objects. Specifications in a Kubernetes manifest describe each object’s desired state.

Our application Service will ensure that the Pods running our containers remain accessible in a dynamic environment, as individual Pods are created and destroyed, while our Deployment will describe the desired state of our Pods.

Open a file called `node-app.yaml` with `nano` or your favorite editor:

    nano node-app.yaml

First, add the following code to define the `nodejs` application Service:

~/istio\_project/node-app.yaml

    apiVersion: v1
    kind: Service
    metadata:
      name: nodejs
      labels: 
        app: nodejs
    spec:
      selector:
        app: nodejs
      ports:
      - name: http
        port: 8080 

This Service definition includes a `selector` that will match Pods with the corresponding `app: nodejs` label. We’ve also specified that the Service will target port `8080` on any Pod with the matching label.

We are also naming the Service port, in compliance with Istio’s [requirements for Pods and Services](https://istio.io/docs/setup/kubernetes/prepare/requirements/). The `http` value is one of the values Istio will accept for the `name` field.

Next, below the Service, add the following specifications for the application Deployment. Be sure to replace the `image` listed under the `containers` specification with the image you created and pushed to Docker Hub in [Step 1](how-to-install-and-use-istio#step-1-%E2%80%94-cloning-and-packaging-the-application):

~/istio\_project/node-app.yaml

    ...
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nodejs
      labels:
        version: v1
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: nodejs
      template:
        metadata:
          labels:
            app: nodejs
            version: v1
        spec:
          containers:
          - name: nodejs
            image: your_dockerhub_username/node-demo
            ports:
            - containerPort: 8080

The specifications for this Deployment include the number of `replicas` (in this case, 1), as well as a `selector` that defines which Pods the Deployment will manage. In this case, it will manage Pods with the `app: nodejs` label.

The `template` field contains values that do the following:

- Apply the `app: nodejs` label to the Pods managed by the Deployment. Istio [recommends](https://istio.io/docs/setup/kubernetes/prepare/requirements/) adding the `app` label to Deployment specifications to provide contextual information for Istio’s metrics and telemetry. 
- Apply a `version` label to specify the version of the application that corresponds to this Deployment. As with the `app` label, Istio recommends including the `version` label to provide contextual information.
- Define the specifications for the containers the Pods will run, including the container `name` and the `image`. The `image` here is the image you created in [Step 1](how-to-install-and-use-istio#step-1-%E2%80%94-cloning-and-packaging-the-application) and pushed to Docker Hub. The container specifications also include a `containerPort` configuration to point to the port each container will listen on. If ports remain unlisted here, they will bypass the Istio proxy. Note that this port, `8080`, corresponds to the targeted port named in the Service definition.

Save and close the file when you are finished editing.

With this file in place, we can move on to editing the file that will contain definitions for Gateway and Virtual Service objects, which control how traffic enters the mesh and how it is routed once there.

## Step 4 — Creating Istio Objects

To control access to a cluster and routing to Services, Kubernetes uses Ingress [_Resources_](https://kubernetes.io/docs/concepts/services-networking/ingress/) and [_Controllers_](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). Ingress Resources define rules for HTTP and HTTPS routing to cluster Services, while Controllers load balance incoming traffic and route it to the correct Services.

For more information about using Ingress Resources and Controllers, see [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes).

Istio uses a different set of objects to achieve similar ends, though with some important differences. Instead of using a Controller to load balance traffic, the Istio mesh uses a [Gateway](https://istio.io/docs/reference/config/networking/v1alpha3/gateway/), which functions as a load balancer that handles incoming and outgoing HTTP/TCP connections. The Gateway then allows for monitoring and routing rules to be applied to traffic entering the mesh. Specifically, the configuration that determines traffic routing is defined as a Virtual Service. Each Virtual Service includes routing rules that match criteria with a specific protocol and destination.

Though Kubernetes Ingress Resources/Controllers and Istio Gateways/Virtual Services have some functional similarities, the structure of the mesh introduces important differences. Kubernetes Ingress Resources and Controllers offer operators some routing options, for example, but Gateways and Virtual Services make a more robust set of functionalities available since they enable traffic to enter the mesh. In other words, the limited [application layer](https://en.wikipedia.org/wiki/OSI_model#Layer_7:_Application_Layer) capabilities that Kubernetes Ingress Controllers and Resources make available to cluster operators do not include the functionalities — including advanced routing, tracing, and telemetry — provided by the sidecars in the Istio service mesh.

To allow external traffic into our mesh and configure routing to our Node app, we will need to create an Istio Gateway and Virtual Service. Open a file called `node-istio.yaml` for the manifest:

    nano node-istio.yaml

First, add the definition for the Gateway object:

~/istio\_project/node-isto.yaml

    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: nodejs-gateway
    spec:
      selector:
        istio: ingressgateway 
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "*"

In addition to specifying a `name` for the Gateway in the `metadata` field, we’ve included the following specifications:

- A `selector` that will match this resource with the default Istio IngressGateway controller that was enabled with the [configuration profile](https://istio.io/docs/setup/kubernetes/additional-setup/config-profiles/) we selected when installing Istio.
- A `servers` specification that specifies the `port` to expose for ingress and the `hosts` exposed by the Gateway. In this case, we are specifying all `hosts` with an asterisk (`*`) since we are not working with a specific secured domain.

Below the Gateway definition, add specifications for the Virtual Service:

~/istio\_project/node-istio.yaml

    ...
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: nodejs
    spec:
      hosts:
      - "*"
      gateways:
      - nodejs-gateway
      http:
      - route:
        - destination:
            host: nodejs

In addition to providing a `name` for this Virtual Service, we’re also including specifications for this resource that include:

- A `hosts` field that specifies the destination host. In this case, we’re again using a wildcard value (`*`) to enable quick access to the application in the browser, since we’re not working with a domain.
- A `gateways` field that specifies the Gateway through which external requests will be allowed. In this case, it’s our `nodejs-gateway` Gateway.
- The `http` field that specifies how HTTP traffic will be routed.
- A `destination` field that indicates where the request will be routed. In this case, it will be routed to the `nodejs` service, which implicitly expands to the Service’s Fully Qualified Domain Name (FQDN) in a Kubernetes environment: `nodejs.default.svc.cluster.local`. It’s important to note, though, that the FQDN will be based on the namespace where the **rule** is defined, not the Service, so be sure to use the FQDN in this field when your application Service and Virtual Service are in different namespaces. To learn about Kubernetes Domain Name System (DNS) more generally, see [An Introduction to the Kubernetes DNS Service](an-introduction-to-the-kubernetes-dns-service).

Save and close the file when you are finished editing.

With your `yaml` files in place, you can create your application Service and Deployment, as well as the Gateway and Virtual Service objects that will enable access to your application.

## Step 5 — Creating Application Resources and Enabling Telemetry Access

Once you have created your application Service and Deployment objects, along with a Gateway and Virtual Service, you will be able to generate some requests to your application and look at the associated data in your Istio Grafana dashboards. First, however, you will need to configure Istio to expose the Grafana addon so that you can access the dashboards in your browser.

We will [enable Grafana access with HTTP](https://istio.io/docs/tasks/telemetry/gateways/#option-2-insecure-access-http), but when you are working in production or in sensitive environments, it is strongly recommended that you [enable access with HTTPS](https://istio.io/docs/tasks/telemetry/gateways/#option-1-secure-access-https).

Because we set the `--set grafana.enabled=true` configuration option when installing Istio in [Step 2](how-to-install-and-use-istio#step-2-%E2%80%94-installing-istio-with-helm), we have a Grafana Service and Pod in our `istio-system` namespace, which we confirmed in that Step.

With those resources already in place, our next step will be to create a manifest for a Gateway and Virtual Service so that we can expose the Grafana addon.

Open the file for the manifest:

    nano node-grafana.yaml

Add the following code to the file to create a Gateway and Virtual Service to expose and route traffic to the Grafana Service:

~/istio\_project/node-grafana.yaml

    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: grafana-gateway
      namespace: istio-system
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 15031
          name: http-grafana
          protocol: HTTP
        hosts:
        - "*"
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: grafana-vs
      namespace: istio-system
    spec:
      hosts:
      - "*"
      gateways:
      - grafana-gateway
      http:
      - match:
        - port: 15031
        route:
        - destination:
            host: grafana
            port:
              number: 3000

Our Grafana Gateway and Virtual Service specifications are similar to those we defined for our application Gateway and Virtual Service in [Step 4](how-to-install-and-use-istio#step-4-%E2%80%94-creating-istio-objects). There are a few differences, however:

- Grafana will be exposed on the `http-grafana` named port (port `15031`), and it will run on port `3000` on the host. 
- The Gateway and Virtual Service are both defined in the `istio-system` namespace.
- The `host` in this Virtual Service is the `grafana` Service in the `istio-system` namespace. Since we are defining this rule in the same namespace that the Grafana Service is running in, FQDN expansion will again work without conflict.

**Note:** Because our current [`MeshPolicy`](https://istio.io/docs/tasks/security/authn-policy/#globally-enabling-istio-mutual-tls) is configured to run TLS in [permissive mode](https://istio.io/docs/concepts/security/#permissive-mode), we do not need to apply a [Destination Rule](https://istio.io/docs/reference/config/networking/v1alpha3/destination-rule/) to our manifest. If you selected a different profile with your Istio installation, then you will need to add a Destination Rule to disable mutual TLS when enabling access to Grafana with HTTP. For more information on how to do this, you can refer to the [official Istio documentaion](https://istio.io/docs/tasks/telemetry/gateways/#option-2-insecure-access-http) on enabling access to telemetry addons with HTTP.

Save and close the file when you are finished editing.

Create your Grafana resources with the following command:

    kubectl apply -f node-grafana.yaml

The [`kubectl apply`](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#kubectl-apply) command allows you to apply a particular configuration to an object in the process of creating or updating it. In our case, we are applying the configuration we specified in the `node-grafana.yaml` file to our Gateway and Virtual Service objects in the process of creating them.

You can take a look at the Gateway in the `istio-system` namespace with the following command:

    kubectl get gateway -n istio-system

You will see the following output:

    OutputNAME AGE
    grafana-gateway 47s

You can do the same thing for the Virtual Service:

    kubectl get virtualservice -n istio-system

    OutputNAME GATEWAYS HOSTS AGE
    grafana-vs [grafana-gateway] [*] 74s

With these resources created, we should be able to access our Grafana dashboards in the browser. Before we do that, however, let’s create our application Service and Deployment, along with our application Gateway and Virtual Service, and check that we can access our application in the browser.

Create the application Service and Deployment with the following command:

    kubectl apply -f node-app.yaml

Wait a few seconds, and then check your application Pods with the following command:

    kubectl get pods

    OutputNAME READY STATUS RESTARTS AGE
    nodejs-7759fb549f-kmb7x 2/2 Running 0 40s

Your application containers are running, as you can see in the `STATUS` column, but why does the `READY` column list `2/2` if the application manifest from [Step 3](how-to-install-and-use-istio#step-3-%E2%80%94-creating-application-objects) only specified 1 replica?

This second container is the Envoy sidecar, which you can inspect with the following command. Be sure to replace the pod listed here with the `NAME` of your own `nodejs` Pod:

    kubectl describe pod nodejs-7759fb549f-kmb7x

    OutputName: nodejs-7759fb549f-kmb7x
    Namespace: default
    ...
    Containers:
      nodejs:
      ...
      istio-proxy:
        Container ID: docker://f840d5a576536164d80911c46f6de41d5bc5af5152890c3aed429a1ee29af10b
        Image: docker.io/istio/proxyv2:1.1.7
        Image ID: docker-pullable://istio/proxyv2@sha256:e6f039115c7d5ef9c8f6b049866fbf9b6f5e2255d3a733bb8756b36927749822 
        Port: 15090/TCP
        Host Port: 0/TCP
        Args:
        ...

Next, create your application Gateway and Virtual Service:

    kubectl apply -f node-istio.yaml

You can inspect the Gateway with the following command:

    kubectl get gateway

    OutputNAME AGE
    nodejs-gateway 7s

And the Virtual Service:

    kubectl get virtualservice

    OutputNAME GATEWAYS HOSTS AGE
    nodejs [nodejs-gateway] [*] 28s

We are now ready to test access to the application. To do this, we will need the external IP associated with our `istio-ingressgateway` Service, which is a [LoadBalancer Service type](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer).

Get the external IP for the `istio-ingressgateway` Service with the following command:

    kubectl get svc -n istio-system

You will see output like the following:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    grafana ClusterIP 10.245.85.162 <none> 3000/TCP 42m
    istio-citadel ClusterIP 10.245.135.45 <none> 8060/TCP,15014/TCP 42m
    istio-galley ClusterIP 10.245.46.245 <none> 443/TCP,15014/TCP,9901/TCP 42m
    istio-ingressgateway LoadBalancer 10.245.171.39 ingressgateway_ip 15020:30707/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30285/TCP,15030:31668/TCP,15031:32297/TCP,15032:30853/TCP,15443:30406/TCP 42m
    istio-pilot ClusterIP 10.245.56.97 <none> 15010/TCP,15011/TCP,8080/TCP,15014/TCP 42m
    istio-policy ClusterIP 10.245.206.189 <none> 9091/TCP,15004/TCP,15014/TCP 42m
    istio-sidecar-injector ClusterIP 10.245.223.99 <none> 443/TCP 42m
    istio-telemetry ClusterIP 10.245.5.215 <none> 9091/TCP,15004/TCP,15014/TCP,42422/TCP 42m
    prometheus ClusterIP 10.245.100.132 <none> 9090/TCP 42m

The `istio-ingressgateway` should be the only Service with the `TYPE` `LoadBalancer`, and the only Service with an external IP.

Navigate to this external IP in your browser: `http://ingressgateway_ip`.

You should see the following landing page:

![Application Landing Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Next, generate some load to the site by clicking refresh five or six times.

You can now check the Grafana dashboard to look at traffic data.

In your browser, navigate to the following address, again using your `istio-ingressgateway` external IP and the port you defined in your Grafana Gateway manifest: `http://ingressgateway_ip:15031`.

You will see the following landing page:

![Grafana Home Dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/istio_install/grafana_home.png)

Clicking on **Home** at the top of the page will bring you to a page with an **istio** folder. To get a list of dropdown options, click on the **istio** folder icon:

![Istio Dash Options Dropdown Menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/istio_install/istio_dropdown.png)

From this list of options, click on **Istio Service Dashboard**.

This will bring you to a landing page with another dropdown menu:

![Service Dropdown in Istio Service Dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/istio_install/service_dropdown.png)

Select `nodejs.default.svc.cluster.local` from the list of available options.

You will now be able to look at traffic data for that service:

![Nodejs Service Dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/istio_install/nodejs_dash.png)

You now have a functioning Node.js application running in an Istio service mesh with Grafana enabled and configured for external access.

## Conclusion

In this tutorial, you installed Istio using the Helm package manager and used it to expose a Node.js application Service using Gateway and Virtual Service objects. You also configured Gateway and Virtual Service objects to expose the Grafana telemetry addon, in order to look at traffic data for your application.

As you move toward production, you will want to take steps like [securing your application Gateway with HTTPS](https://istio.io/docs/tasks/traffic-management/secure-ingress/) and ensuring that access to your Grafana Service is also [secure](https://istio.io/docs/tasks/telemetry/gateways/#option-1-secure-access-https).

You can also explore other [telemetry-related tasks](https://istio.io/docs/tasks/telemetry/), including [collecting and processing metrics](https://istio.io/docs/tasks/telemetry/metrics/), [logs](https://istio.io/docs/tasks/telemetry/logs/), and [trace spans](https://istio.io/docs/tasks/telemetry/distributed-tracing/).
