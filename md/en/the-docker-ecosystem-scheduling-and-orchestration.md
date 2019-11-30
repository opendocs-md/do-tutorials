---
author: Justin Ellingwood
date: 2015-02-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/the-docker-ecosystem-scheduling-and-orchestration
---

# The Docker Ecosystem: Scheduling and Orchestration

## Introduction

The Docker tool provides all of the functions necessary to build, upload, download, start, and stop containers. It is well-suited for managing these processes in single-host environments with a minimal number of containers.

However, many Docker users are leveraging the platform as a tool for easily scaling large numbers of containers across many different hosts. Clustered Docker hosts present special management challenges that require a different set of tools.

In this guide, we will discuss Docker schedulers and orchestration tools. These represent the primary container management interface for administrators of distributed deployments.

## Scheduling Containers, Orchestration and Cluster Management

When applications are scaled out across multiple host systems, the ability to manage each host system and abstract away the complexity of the underlying platform becomes attractive. Orchestration is a broad term that refers to container scheduling, cluster management, and possibly the provisioning of additional hosts.

In this environment, “scheduling” refers to the ability for an administrator to load a service file onto a host system that establishes how to run a specific container. While scheduling refers to the specific act of loading the service definition, in a more general sense, schedulers are responsible for hooking into a host’s init system to manage services in whatever capacity needed.

Cluster management is the process of controlling a group of hosts. This can involve adding and removing hosts from a cluster, getting information about the current state of hosts and containers, and starting and stopping processes. Cluster management is closely tied to scheduling because the scheduler must have access to each host in the cluster in order to schedule services. For this reason, the same tool is often used for both purposes.

In order to run and manage containers on hosts throughout the cluster, the scheduler must interact with each host’s individual init system. At the same time, for ease of management, the scheduler presents a unified view of the state of services throughout the cluster. This ends up functioning like a cluster-wide init system. For this reason, many schedulers mirror the command structure of the init system’s they are abstracting.

One of the biggest responsibilities of schedulers is host selection. If an administrator decides to run a service (container) on the cluster, the scheduler often is charged with automatically selecting a host. The administrator can optionally provide scheduling constraints according to their needs or desires, but the scheduler is ultimately responsible for executing on these requirements.

## How Does a Scheduler Make Scheduling Decisions?

Schedulers often define a default scheduling policy. This determines how services are scheduled when no input is given from the administrator. For instance, a scheduler might choose to place new services on hosts with the fewest currently active services.

Schedulers typically provide override mechanisms that administrators can use to fine-tune the selection processes to satisfy specific requirements. For instance, if two containers should always run on the same host because they operate as a unit, that affinity can often be declared during the scheduling. Likewise, if two containers should _not_ be placed on the same host, for example to ensure high availability of two instances of the same service, this can be defined as well.

Other constraints that a scheduler may pay attention to can be represented by arbitrary metadata. Individual hosts may be labeled and targeted by schedulers. This may be necessary, for instance, if a host contains the data volume needed by an application. Some services may need to be deployed on every individual host in the cluster. Most schedulers allow you to do this.

## What Cluster Management Functions do Schedulers Provide?

Scheduling is often tied to cluster management functions because both functions require the ability to operate on specific hosts and on the cluster as a whole.

Cluster management software may be used to query information about members of a cluster, add or remove members, or even connect to individual hosts for more granular administration. These functions may be included in the scheduler, or may be the responsibility of another process.

Often, cluster management is also associated with the service discovery tool or distributed key-value store. These are particularly well-suited for storing this type of information because the information is dispersed throughout the cluster itself and the platform already exists for its primary function.

Because of this, if the scheduler itself does not provide methods, some cluster management operations may have to be done by modifying the values in the configuration store using the provided APIs. For example, cluster membership changes may need to be handled through raw changes to the discovery service.

The key-value store is also usually the location where metadata about individual hosts can be stored. As mentioned before, labelling hosts allows you to target individuals or groups for scheduling decisions.

#### How Do Multi-Container Deployments Fit into Scheduling?

Sometimes, even though each component of an application has been broken out into a discrete service, they should be managed as a single unit. There are times when it wouldn’t make sense to ever deploy one service without another because of the functions each provide.

Advanced scheduling that takes into account container grouping is available through a few different projects. There are quite a few benefits that users gain from having access to this functionality.

Group container management allows an administrator to deal with a collection of containers as a single application. Running tightly integrated components as a unit simplifies application management without sacrificing the benefits of compartmentalizing individual functionality. In effect, it allows administrators to keep the gains won from containerization and service-oriented architecture while minimizing the additional management overhead.

Grouping applications together can mean simply scheduling them together and providing the ability to start and stop them at the same time. It can also allow for more complex scenarios like configuring separate subnets for each group of applications or scaling entire sets of containers where we previously would only be able to scale on the container scale.

#### What Is Provisioning?

A concept related to cluster management is provisioning. Provisioning is the processes of bringing new hosts online and configuring them in a basic way so that they are ready for work. With Docker deployments, this often implies configuring Docker and setting up the new host to join an existing cluster.

While the end result of provisioning a host should always be that a new system is available for work, the methodology varies significantly depending on the tools used and the type of host. For instance, if the host will be a virtual machine, tools like `vagrant` can be used to spin up a new host. Most cloud providers allow you to create new hosts using APIs. In contrast, provisioning of bare hardware would probably require some manual steps. Configuration management tools like Chef, Puppet, Ansible, or Salt may be involved in order to take care of the initial configuration of the host and to provide it with the information it needs to connect to an existing cluster.

Provisioning may be left as an administrator-initiated process, or it’s possible that it may be hooked into the cluster management tools for automatic scaling. This latter method involves defining the process for requesting additional hosts as well as the conditions under which this should automatically be triggered. For instance, if your application is suffering from severe load, you may wish your system to spin up additional hosts and horizontally scale the containers across the new infrastructure in order to alleviate the congestion.

#### What Are Some Common Schedulers?

In terms of basic scheduling and cluster management, some popular projects are:

- **fleet** : Fleet is the scheduling and cluster management component of CoreOS. It reads connection info for each host in the cluster from etcd and provides systemd-like service management.
- **marathon** : Marathon is the scheduling and service management component of a Mesosphere installation. It works with mesos to control long-running services and provides a web UI for process and container management.
- **Swarm** : Docker’s Swarm is a scheduler that the Docker project announced in December 2014. It hopes to provide a robust scheduler that can spin up containers on hosts provisioned with Docker, using Docker-native syntax.

As part of the cluster management strategy, Mesosphere configurations rely on the following component:

- **mesos** : Apache mesos is a tool that abstracts and manages the resources of all hosts in a cluster. It presents a collection of the resources available throughout the entire cluster to the components built on top of it (like marathon). It describes itself as analogous to a “kernel” for a clustered configurations.

In terms of advanced scheduling and controlling groups of containers as a single unit, the following projects are available:

- **kubernetes** : Google’s advanced scheduler, kubernetes allows much more control over the containers running on your infrastructure. Containers can be labeled, grouped, and given their own subnet for communication.
- **compose** : Docker’s compose project was created to allow group management of containers using declarative configuration files. It uses Docker links to learn about the dependency relationship between containers.

## Conclusion

Cluster management and work schedulers are a key part of implementing containerized services on a distributed set of hosts. They provide the main point of management for actually starting and controlling the services that are providing your application. By utilizing schedulers effectively, you can make drastic changes to your applications with very little effort.
