---
author: Justin Ellingwood
date: 2014-10-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-kubernetes
---

# An Introduction to Kubernetes

## Introduction

Kubernetes is a powerful open-source system, initially developed by Google, for managing containerized applications in a clustered environment. It aims to provide better ways of managing related, distributed components and services across varied infrastructure.

In this guide, we’ll discuss some of Kubernetes’ basic concepts. We will talk about the architecture of the system, the problems it solves, and the model that it uses to handle containerized deployments and scaling.

## What is Kubernetes?

**Kubernetes** , at its basic level, is a system for running and coordinating containerized applications across a cluster of machines. It is a platform designed to completely manage the life cycle of containerized applications and services using methods that provide predictability, scalability, and high availability.

As a Kubernetes user, you can define how your applications should run and the ways they should be able to interact with other applications or the outside world. You can scale your services up or down, perform graceful rolling updates, and switch traffic between different versions of your applications to test features or rollback problematic deployments. Kubernetes provides interfaces and composable platform primitives that allow you to define and manage your applications with high degrees of flexibility, power, and reliability.

## Kubernetes Architecture

To understand how Kubernetes is able to provide these capabilities, it is helpful to get a sense of how it is designed and organized at a high level. Kubernetes can be visualized as a system built in layers, with each higher layer abstracting the complexity found in the lower levels.

At its base, Kubernetes brings together individual physical or virtual machines into a cluster using a shared network to communicate between each server. This cluster is the physical platform where all Kubernetes components, capabilities, and workloads are configured.

The machines in the cluster are each given a role within the Kubernetes ecosystem. One server (or a small group in highly available deployments) functions as the **master** server. This server acts as a gateway and brain for the cluster by exposing an API for users and clients, health checking other servers, deciding how best to split up and assign work (known as “scheduling”), and orchestrating communication between other components. The master server acts as the primary point of contact with the cluster and is responsible for most of the centralized logic Kubernetes provides.

The other machines in the cluster are designated as **nodes** : servers responsible for accepting and running workloads using local and external resources. To help with isolation, management, and flexibility, Kubernetes runs applications and services in **containers** , so each node needs to be equipped with a container runtime (like Docker or rkt). The node receives work instructions from the master server and creates or destroys containers accordingly, adjusting networking rules to route and forward traffic appropriately.

As mentioned above, the applications and services themselves are run on the cluster within containers. The underlying components make sure that the desired state of the applications matches the actual state of the cluster. Users interact with the cluster by communicating with the main API server either directly or with clients and libraries. To start up an application or service, a declarative plan is submitted in JSON or YAML defining what to create and how it should be managed. The master server then takes the plan and figures out how to run it on the infrastructure by examining the requirements and the current state of the system. This group of user-defined applications running according to a specified plan represents Kubernetes’ final layer.

## Master Server Components

As we described above, the master server acts as the primary control plane for Kubernetes clusters. It serves as the main contact point for administrators and users, and also provides many cluster-wide systems for the relatively unsophisticated worker nodes. Overall, the components on the master server work together to accept user requests, determine the best ways to schedule workload containers, authenticate clients and nodes, adjust cluster-wide networking, and manage scaling and health checking responsibilities.

These components can be installed on a single machine or distributed across multiple servers. We will take a look at each of the individual components associated with master servers in this section.

### etcd

One of the fundamental components that Kubernetes needs to function is a globally available configuration store. The [**etcd** project](https://coreos.com/etcd/docs/latest/), developed by the team at CoreOS, is a lightweight, distributed key-value store that can be configured to span across multiple nodes.

Kubernetes uses `etcd` to store configuration data that can be accessed by each of the nodes in the cluster. This can be used for service discovery and can help components configure or reconfigure themselves according to up-to-date information. It also helps maintain cluster state with features like leader election and distributed locking. By providing a simple HTTP/JSON API, the interface for setting or retrieving values is very straight forward.

Like most other components in the control plane, `etcd` can be configured on a single master server or, in production scenarios, distributed among a number of machines. The only requirement is that it be network accessible to each of the Kubernetes machines.

### kube-apiserver

One of the most important master services is an API server. This is the main management point of the entire cluster as it allows a user to configure Kubernetes’ workloads and organizational units. It is also responsible for making sure that the `etcd` store and the service details of deployed containers are in agreement. It acts as the bridge between various components to maintain cluster health and disseminate information and commands.

The API server implements a RESTful interface, which means that many different tools and libraries can readily communicate with it. A client called **kubectl** is available as a default method of interacting with the Kubernetes cluster from a local computer.

### kube-controller-manager

The controller manager is a general service that has many responsibilities. Primarily, it manages different controllers that regulate the state of the cluster, manage workload life cycles, and perform routine tasks. For instance, a replication controller ensures that the number of replicas (identical copies) defined for a pod matches the number currently deployed on the cluster. The details of these operations are written to `etcd`, where the controller manager watches for changes through the API server.

When a change is seen, the controller reads the new information and implements the procedure that fulfills the desired state. This can involve scaling an application up or down, adjusting endpoints, etc.

### kube-scheduler

The process that actually assigns workloads to specific nodes in the cluster is the scheduler. This service reads in a workload’s operating requirements, analyzes the current infrastructure environment, and places the work on an acceptable node or nodes.

The scheduler is responsible for tracking available capacity on each host to make sure that workloads are not scheduled in excess of the available resources. The scheduler must know the total capacity as well as the resources already allocated to existing workloads on each server.

### cloud-controller-manager

Kubernetes can be deployed in many different environments and can interact with various infrastructure providers to understand and manage the state of resources in the cluster. While Kubernetes works with generic representations of resources like attachable storage and load balancers, it needs a way to map these to the actual resources provided by non-homogeneous cloud providers.

Cloud controller managers act as the glue that allows Kubernetes to interact providers with different capabilities, features, and APIs while maintaining relatively generic constructs internally. This allows Kubernetes to update its state information according to information gathered from the cloud provider, adjust cloud resources as changes are needed in the system, and create and use additional cloud services to satisfy the work requirements submitted to the cluster.

## Node Server Components

In Kubernetes, servers that perform work by running containers are known as **nodes**. Node servers have a few requirements that are necessary for communicating with master components, configuring the container networking, and running the actual workloads assigned to them.

### A Container Runtime

The first component that each node must have is a container runtime. Typically, this requirement is satisfied by installing and running [Docker](https://www.docker.com/), but alternatives like [rkt](https://coreos.com/rkt/) and [runc](https://github.com/opencontainers/runc) are also available.

The container runtime is responsible for starting and managing containers, applications encapsulated in a relatively isolated but lightweight operating environment. Each unit of work on the cluster is, at its basic level, implemented as one or more containers that must be deployed. The container runtime on each node is the component that finally runs the containers defined in the workloads submitted to the cluster.

### kubelet

The main contact point for each node with the cluster group is a small service called **kubelet**. This service is responsible for relaying information to and from the control plane services, as well as interacting with the `etcd` store to read configuration details or write new values.

The `kubelet` service communicates with the master components to authenticate to the cluster and receive commands and work. Work is received in the form of a **manifest** which defines the workload and the operating parameters. The `kubelet` process then assumes responsibility for maintaining the state of the work on the node server. It controls the container runtime to launch or destroy containers as needed.

### kube-proxy

To manage individual host subnetting and make services available to other components, a small proxy service called **kube-proxy** is run on each node server. This process forwards requests to the correct containers, can do primitive load balancing, and is generally responsible for making sure the networking environment is predictable and accessible, but isolated where appropriate.

## Kubernetes Objects and Workloads

While containers are the underlying mechanism used to deploy applications, Kubernetes uses additional layers of abstraction over the container interface to provide scaling, resiliency, and life cycle management features. Instead of managing containers directly, users define and interact with instances composed of various primitives provided by the Kubernetes object model. We will go over the different types of objects that can be used to define these workloads below.

### Pods

A **pod** is the most basic unit that Kubernetes deals with. Containers themselves are not assigned to hosts. Instead, one or more tightly coupled containers are encapsulated in an object called a pod.

A pod generally represents one or more containers that should be controlled as a single application. Pods consist of containers that operate closely together, share a life cycle, and should always be scheduled on the same node. They are managed entirely as a unit and share their environment, volumes, and IP space. In spite of their containerized implementation, you should generally think of pods as a single, monolithic application to best conceptualize how the cluster will manage the pod’s resources and scheduling.

Usually, pods consist of a main container that satisfies the general purpose of the workload and optionally some helper containers that facilitate closely related tasks. These are programs that benefit from being run and managed in their own containers, but are tightly tied to the main application. For example, a pod may have one container running the primary application server and a helper container pulling down files to the shared filesystem when changes are detected in an external repository. Horizontal scaling is generally discouraged on the pod level because there are other higher level objects more suited for the task.

Generally, users should not manage pods themselves, because they do not provide some of the features typically needed in applications (like sophisticated life cycle management and scaling). Instead, users are encouraged to work with higher level objects that use pods or pod templates as base components but implement additional functionality.

### Replication Controllers and Replication Sets

Often, when working with Kubernetes, rather than working with single pods, you will instead be managing groups of identical, replicated pods. These are created from pod templates and can be horizontally scaled by controllers known as replication controllers and replication sets.

A **replication controller** is an object that defines a pod template and control parameters to scale identical replicas of a pod horizontally by increasing or decreasing the number of running copies. This is an easy way to distribute load and increase availability natively within Kubernetes. The replication controller knows how to create new pods as needed because a template that closely resembles a pod definition is embedded within the replication controller configuration.

The replication controller is responsible for ensuring that the number of pods deployed in the cluster matches the number of pods in its configuration. If a pod or underlying host fails, the controller will start new pods to compensate. If the number of replicas in a controller’s configuration changes, the controller either starts up or kills containers to match the desired number. Replication controllers can also perform rolling updates to roll over a set of pods to a new version one by one, minimizing the impact on application availability.

**Replication sets** are an iteration on the replication controller design with greater flexibility in how the controller identifies the pods it is meant to manage. Replication sets are beginning to replace replication controllers because of their greater replica selection capabilities, but they are not able to do rolling updates to cycle backends to a new version like replication controllers can. Instead, replication sets are meant to be used inside of additional, higher level units that provide that functionality.

Like pods, both replication controllers and replication sets are rarely the units you will work with directly. While they build on the pod design to add horizontal scaling and reliability guarantees, they lack some of the fine grained life cycle management capabilities found in more complex objects.

### Deployments

**Deployments** are one of the most common workloads to directly create and manage. Deployments use replication sets as a building block, adding flexible life cycle management functionality to the mix.

While deployments built with replications sets may appear to duplicate the functionality offered by replication controllers, deployments solve many of the pain points that existed in the implementation of rolling updates. When updating applications with replication controllers, users are required to submit a plan for a new replication controller that would replace the current controller. When using replication controllers, tasks like tracking history, recovering from network failures during the update, and rolling back bad changes are either difficult or left as the user’s responsibility.

Deployments are a high level object designed to ease the life cycle management of replicated pods. Deployments can be modified easily by changing the configuration and Kubernetes will adjust the replica sets, manage transitions between different application versions, and optionally maintain event history and undo capabilities automatically. Because of these features, deployments will likely be the type of Kubernetes object you work with most frequently.

### Stateful Sets

**Stateful sets** are specialized pod controllers that offer ordering and uniqueness guarantees. Primarily, these are used to have more fine-grained control when you have special requirements related to deployment ordering, persistent data, or stable networking. For instance, stateful sets are often associated with data-oriented applications, like databases, which need access to the same volumes even if rescheduled to a new node.

Stateful sets provide a stable networking identifier by creating a unique, number-based name for each pod that will persist even if the pod needs to be moved to another node. Likewise, persistent storage volumes can be transferred with a pod when rescheduling is necessary. The volumes persist even after the pod has been deleted to prevent accidental data loss.

When deploying or adjusting scale, stateful sets perform operations according to the numbered identifier in their name. This gives greater predictability and control over the order of execution, which can be useful in some cases.

### Daemon Sets

**Daemon sets** are another specialized form of pod controller that run a copy of a pod on each node in the cluster (or a subset, if specified). This is most often useful when deploying pods that help perform maintenance and provide services for the nodes themselves.

For instance, collecting and forwarding logs, aggregating metrics, and running services that increase the capabilities of the node itself are popular candidates for daemon sets. Because daemon sets often provide fundamental services and are needed throughout the fleet, they can bypass pod scheduling restrictions that prevent other controllers from assigning pods to certain hosts. As an example, because of its unique responsibilities, the master server is frequently configured to be unavailable for normal pod scheduling, but daemon sets have the ability to override the restriction on a pod-by-pod basis to make sure essential services are running.

### Jobs and Cron Jobs

The workloads we’ve described so far have all assumed a long-running, service-like life cycle. Kubernetes uses a workload called **jobs** to provide a more task-based workflow where the running containers are expected to exit successfully after some time once they have completed their work. Jobs are useful if you need to perform one-off or batch processing instead of running a continuous service.

Building on jobs are **cron jobs**. Like the conventional `cron` daemons on Linux and Unix-like systems that execute scripts on a schedule, cron jobs in Kubernetes provide an interface to run jobs with a scheduling component. Cron jobs can be used to schedule a job to execute in the future or on a regular, reoccurring basis. Kubernetes cron jobs are basically a reimplementation of the classic cron behavior, using the cluster as a platform instead of a single operating system.

## Other Kubernetes Components

Beyond the workloads you can run on a cluster, Kubernetes provides a number of other abstractions that help you manage your applications, control networking, and enable persistence. We will discuss a few of the more common examples here.

### Services

So far, we have been using the term “service” in the conventional, Unix-like sense: to denote long-running processes, often network connected, capable of responding to requests. However, in Kubernetes, a **service** is a component that acts as a basic internal load balancer and ambassador for pods. A service groups together logical collections of pods that perform the same function to present them as a single entity.

This allows you to deploy a service that can keep track of and route to all of the backend containers of a particular type. Internal consumers only need to know about the stable endpoint provided by the service. Meanwhile, the service abstraction allows you to scale out or replace the backend work units as necessary. A service’s IP address remains stable regardless of changes to the pods it routes to. By deploying a service, you easily gain discoverability and can simplify your container designs.

Any time you need to provide access to one or more pods to another application or to external consumers, you should configure a service. For instance, if you have a set of pods running web servers that should be accessible from the internet, a service will provide the necessary abstraction. Likewise, if your web servers need to store and retrieve data, you would want to configure an internal service to give them access to your database pods.

Although services, by default, are only available using an internally routable IP address, they can be made available outside of the cluster by choosing one of several strategies. The **NodePort** configuration works by opening a static port on each node’s external networking interface. Traffic to the external port will be routed automatically to the appropriate pods using an internal cluster IP service.

Alternatively, the **LoadBalancer** service type creates an external load balancer to route to the service using a cloud provider’s Kubernetes load balancer integration. The cloud controller manager will create the appropriate resource and configure it using the internal service service addresses.

### Volumes and Persistent Volumes

Reliably sharing data and guaranteeing its availability between container restarts is a challenge in many containerized environments. Container runtimes often provide some mechanism to attach storage to a container that persists beyond the lifetime of the container, but implementations typically lack flexibility.

To address this, Kubernetes uses its own **volumes** abstraction that allows data to be shared by all containers within a pod and remain available until the pod is terminated. This means that tightly coupled pods can easily share files without complex external mechanisms. Container failures within the pod will not affect access to the shared files. Once the pod is terminated, the shared volume is destroyed, so it is not a good solution for truly persistent data.

**Persistent volumes** are a mechanism for abstracting more robust storage that is not tied to the pod life cycle. Instead, they allow administrators to configure storage resources for the cluster that users can request and claim for the pods they are running. Once a pod is done with a persistent volume, the volume’s reclamation policy determines whether the volume is kept around until manually deleted or removed along with the data immediately. Persistent data can be used to guard against node-based failures and to allocate greater amounts of storage than is available locally.

### Labels and Annotations

A Kubernetes organizational abstraction related to, but outside of the other concepts, is labeling. A **label** in Kubernetes is a semantic tag that can be attached to Kubernetes objects to mark them as a part of a group. These can then be selected for when targeting different instances for management or routing. For instance, each of the controller-based objects use labels to identify the pods that they should operate on. Services use labels to understand the backend pods they should route requests to.

Labels are given as simple key-value pairs. Each unit can have more than one label, but each unit can only have one entry for each key. Usually, a “name” key is used as a general purpose identifier, but you can additionally classify objects by other criteria like development stage, public accessibility, application version, etc.

**Annotations** are a similar mechanism that allows you to attach arbitrary key-value information to an object. While labels should be used for semantic information useful to match a pod with selection criteria, annotations are more free-form and can contain less structured data. In general, annotations are a way of adding rich metadata to an object that is not helpful for selection purposes.

## Conclusion

Kubernetes is an exciting project that allows users to run scalable, highly available containerized workloads on a highly abstracted platform. While Kubernetes’ architecture and set of internal components can at first seem daunting, their power, flexibility, and robust feature set are unparalleled in the open-source world. By understanding how the basic building blocks fit together, you can begin to design systems that fully leverage the capabilities of the platform to run and manage your workloads at scale.
