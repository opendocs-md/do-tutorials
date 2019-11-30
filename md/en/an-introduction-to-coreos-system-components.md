---
author: Justin Ellingwood
date: 2014-09-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-coreos-system-components
---

# An Introduction to CoreOS System Components

## **Status:** Out of Date

This article is no longer current. If you are interested in writing an update for this article, please see [DigitalOcean wants to publish your tech tutorial](https://www.digitalocean.com/community/get-paid-to-write)!

**Reason:** On December 22, 2016, CoreOS announced that it no longer maintains fleet. CoreOS recommends using Kubernetes for all clustering needs.

**See Instead:**  
For guidance using Kubernetes on CoreOS without fleet, see the [Kubernetes on CoreOS Documentation](https://coreos.com/kubernetes/docs/latest/).

### What is CoreOS?

CoreOS is a powerful Linux distribution built to make large, scalable deployments on varied infrastructure simple to manage. Based on a build of Chrome OS, CoreOS maintains a lightweight host system and uses Docker containers for all applications. This system provides process isolation and also allows applications to be moved throughout a cluster easily.

To manage these clusters, CoreOS uses a globally distributed key-value store called `etcd` to pass configuration data between nodes. This component is also the platform for service discovery, allowing applications to be dynamically configured based on the information available through the shared resource.

In order to schedule and manage applications across the entirety of the cluster, a tool called `fleet` is used. Fleet serves as a cluster-wide init system that can be used to manage processes across the entire cluster. This makes it easy to configure highly available applications and manage the cluster from a single point. It does this by tying into each individual node’s `systemd` init system.

In this guide, we will introduce you to some key CoreOS concepts and introduce each of the core components that allow the system to work. In a later guide, we’ll discuss [how to get started with CoreOS on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean).

## System Design

The general design of a CoreOS installation is geared towards clustering and containerization.

The main host system is relatively simple and foregoes many of the common “features” of traditional servers. In fact, CoreOS does not even have a package manager. Instead, all additional applications are expected to run as Docker containers, allowing for isolation, portability, and external management of the services.

At boot, CoreOS reads a user-supplied configuration file called “cloud-config” to do some initial configuration. This file allows CoreOS to connect with other members of a cluster, start up essential services, and reconfigure important parameters. This is how CoreOS is able to immediately join a cluster as a working unit upon creation.

Usually, the “cloud-config” file will, at a minimum, tell the host how to join an existing cluster and command the host to boot up two services called `etcd` and `fleet`. All three of these actions are related. They let the new host connect with the existing servers and provide the tools necessary to configure and manage each node within the cluster. Basically, these are the requirements to bootstrap a CoreOS node into a cluster.

The `etcd` daemon is used to store and distribute data to each of the hosts in a cluster. This is useful for keeping consistent configurations and it also serves as a platform with which services can announce themselves. This service-discovery mechanism can be used by other services to query for information in order to adjust their configuration details. For instance, a load balancer would be able to query `etcd` for the IP addresses of multiple backend web servers when it starts up.

The `fleet` daemon is basically a distributed init system. It works by hooking into the `systemd` init system on each individual host in a cluster. It handles service scheduling, constraining the deployment targets based on user-defined criteria. Users can conceptualize the cluster as a single unit with `fleet`, instead of having to worry about each individual server.

Now that you have a general idea about the system as a whole, let’s go over some more details about each of the specific components. Understanding the role each of these plays is important.

## A Basic Overview of Docker

Docker is a containerization system that utilizes LXC, also known as Linux containers, and uses kernel namespacing and cgroups in order to isolate processes.

The isolation helps keep the running environment of the application clean and predictable. One of the main benefits of this system though is that it makes distributing software trivial. A Docker container should be able to run exactly the same regardless of the operating environment. This means that a container built on a laptop can run seamlessly on a datacenter-wide cluster.

Docker allows you to distribute a working software environment with all of the necessary dependencies. Docker containers can run side-by-side with other containers, but act as an individual server. The advantage of Docker containers over virtualization is that Docker does not seek to emulate an entire operating system, it only implements the components necessary to get the application to run. Because of this, Docker has many of the benefits of virtualization, but without the heavy resource cost.

CoreOS leverages Docker containers for any software outside of the small set included in the base installation. This means that almost everything will have to run within a container. While this might seem like a hassle at first, it makes cluster orchestration significantly easier. CoreOS is designed to primarily be manipulated at the cluster-level, not at the level of individual servers.

This makes distributing services and spreading out your load easy on CoreOS. The included tools and services will allow you to start processes on any of the available nodes within your supplied constraints. Docker allows these services and tasks to be distributed as self-contained chunks instead of applications that must be configured on each node.

## A Basic Overview of Etcd

In order to provide a consistent set of global data to each of the nodes in a cluster and to enable service discovery functionality, a service called `etcd` was developed.

The etcd service is a highly available key-value store that can be used by each node to get configuration data, query information about running services, and publish information that should be known to other members. Each node runs its own etcd client. These are configured to communicate with the other clients in the cluster to share and distribute information.

Applications wishing to retrieve information from the store simply need to connect to the `etcd` interface on their local machine. All `etcd` data will be available on each node, regardless of where it is actually stored and each stored value will be distributed and replicated automatically throughout the cluster. Leader elections are also handled automatically, making management of the key-store fairly trivial.

To interact with etcd data, you can either use the simple HTTP/JSON API (accessible at `http://127.0.0.1:4001/v2/keys/` by default), or you can use an included utility called `etcdctl` to manipulate or read data. Both the `etcdctl` command and the HTTP API are simple and predictable ways of interacting with the store.

It is important to realize that HTTP API is also accessible to applications running within Docker containers. This means that configuration for individual containers can take into account the values stored in etcd.

## A Basic Overview of Fleet

In order to actually orchestrate the CoreOS clusters that you are building, a tool called `fleet` is used. A rather simple concept, fleet acts as a cluster-wide init system.

Each individual node within a clustered environment operates its own conventional `systemd` init system. This is used to start and manage services on the local machine. In a simplified sense, what fleet does is provide an interface for controlling each of the cluster members’ `systemd` systems.

You can start or stop services or get state information about running processes across your entire cluster. However, fleet does a few important things to make this more usable. It handles the process distribution mechanism, so it can start services on less busy hosts.

You can also specify placement conditions for the services you are running. You can insist that a service must or must not run on certain hosts depending on where they are located, what they are already running, and more. Because fleet leverages systemd for starting the local processes, each of the files which define services are systemd unit files (with a few custom options). You can pass these configuration files into fleet once and manage them for the entire cluster.

This flexibility makes it simple to design highly available configurations. For instance, you can require that each of your web server containers be deployed on separate nodes. You can similarly ensure that a helper container be deployed only on nodes that are running the parent container.

Any of the member nodes can be used to manage the cluster using the `fleetctl` utility. This allows you to schedule services, manage nodes, and see the general state of your systems. The `fleetctl` program will be your main interface with your cluster.

## Conclusion

CoreOS might be different from most other Linux distributions you may be familiar with. Each of the design decisions was made with ease of cluster management and application portability in mind. This resulted in a focused, powerful distribution built to address the needs of modern infrastructure and application scaling.

To learn more about how to get started, check out our guide on [getting a CoreOS cluster up and running on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean).
