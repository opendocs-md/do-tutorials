---
author: Mitchell Anicas
date: 2014-09-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-mesosphere
---

# An Introduction to Mesosphere

### What is Mesosphere

Mesosphere is a software solution that expands upon the cluster management capabilities of Apache Mesos with additional components to provide a new and novel way to manage server infrastructures. By combining several components with Mesos, such as Marathon and Chronos, Mesosphere enables a way to easily scale applications by abstracting away many of the challenges associated with scaling.

Mesosphere provides features such as application scheduling, scaling, fault-tolerance, and self-healing. It also provides application service discovery, port unification, and end-point elasticity.

To give a better idea of how Mesosphere provides the aforementioned features, we will briefly explain what each key component of Mesosphere does, starting with Apache Mesos, and show how each is used in the context of Mesosphere.

## A Basic Overview of Apache Mesos

Apache Mesos is an open source cluster manager that simplifies running applications on a scalable cluster of servers, and is the heart of the Mesosphere system.

Mesos offers many of the features that you would expect from a cluster manager, such as:

- Scalability to over 10,000 nodes
- Resource isolation for tasks through Linux Containers
- Efficient CPU and memory-aware resource scheduling
- Highly-available master through Apache ZooKeeper
- Web UI for monitoring cluster state

### Mesos Architecture

Mesos has an architecture that is composed of master and slave daemons, and frameworks. Here is a quick breakdown of these components, and some relevant terms:

- **Master daemon** : runs on a master node and manages slave daemons
- **Slave daemon** : runs on a master node and runs tasks that belong to frameworks
- **Framework** : also known as a Mesos application, is composed of a _scheduler_, which registers with the master to receive resource _offers_, and one or more _executors_, which launches _tasks_ on slaves. Examples of Mesos frameworks include Marathon, Chronos, and Hadoop
- **Offer** : a list of a slave node’s available CPU and memory resources. All slave nodes send offers to the master, and the master provides offers to registered frameworks
- **Task** : a unit of work that is scheduled by a framework, and is executed on a slave node. A task can be anything from a bash command or script, to an SQL query, to a Hadoop job
- **Apache ZooKeeper** : software that is used to coordinate the master nodes

![Mesos Architecture](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/mesosphere/mesos_architecture.png)

**Note:** “ZK” represents ZooKeeper in this diagram.

This architecture allows Mesos to share the cluster’s resources amongst applications with a high level of granularity. The amount of resources offered to a particular framework is based on the policy set on the master, and the framework scheduler decides which of the offers to use. Once the framework scheduler decides which offers it wants to use, it tells Mesos which tasks should be executed, and Mesos launches the tasks on the appropriate slaves. After tasks are completed, and the consumed resources are freed, the resource offer cycle repeats so more tasks can be scheduled.

### High Availability

High availability of Mesos masters in a cluster is enabled through the use of Apache ZooKeeper to replicate the masters to form a _quorum_. ZooKeeper also coordinates master leader election and handles leader detection amongst Mesos components, including slaves and frameworks.

At least three master nodes are required for a highly-available configuration–a three master setup allows quorum to be maintained in the event that a single master fails–but five master nodes are recommended for a resilient production environment, allowing quorum to be maintained with two master nodes offline.

For more about Apache Mesos, visit [its official documentation page](http://mesos.apache.org/documentation/latest/).

## A Basic Overview of Marathon

Marathon is a framework for Mesos that is designed to launch long-running applications, and, in Mesosphere, serves as a replacement for a traditional `init` system. It has many features that simplify running applications in a clustered environment, such as high-availability, node constraints, application health checks, an API for scriptability and service discovery, and an easy to use web user interface. It adds its scaling and self-healing capabilities to the Mesosphere feature set.

Marathon can be used to start other Mesos frameworks, and it can also launch any process that can be started in the regular shell. As it is designed for long-running applications, it will ensure that applications it has launched will continue running, even if the slave node(s) they are running on fails.

For more about Marathon, visit [its GitHub page](https://github.com/mesosphere/marathon).

## A Basic Overview of Chronos

Chronos is a framework for Mesos that was originally developed by Airbnb as a replacement for `cron`. As such, it is a fully-featured, distributed, and fault-tolerant scheduler for Mesos, which eases the orchestration of jobs, which are collections of tasks. It includes an API that allows for scripting of scheduling jobs, and a web UI for ease of use.

In Mesosphere, Chronos compliments Marathon as it provides another way to run applications, according to a schedule or other conditions, such as the completion of another job. It is also capable of scheduling jobs on multiple Mesos slave nodes, and provides statistics about job failures and successes.

For more about Chronos, visit [its GitHub page](https://github.com/mesosphere/chronos).

## A Basic Overview of HAProxy

HAProxy is a popular open source load balancer and reverse proxying solution. It can be used in Mesosphere to route network traffic from known hosts, typically Mesos masters, to the actual services that are running on Mesos slave nodes. The service discovery capabilities of Mesos can be used to dynamically configure HAProxy to route incoming traffic to the proper backend slave nodes.

For more about the general capabilities of HAProxy, check out our [Introduction to HAProxy](an-introduction-to-haproxy-and-load-balancing-concepts).

## Conclusion

Mesosphere employs server infrastructure paradigms that may seem unfamiliar, as it was designed with a strong focus on clustering and scalability, but hopefully you now have a good understanding of how it works. Each of the components it is based on provides solutions to issues that are commonly faced when dealing with clustering and scaling a server infrastructure, and Mesosphere aims to provide a complete solution to these needs.

Now that you know the basics of Mesosphere, check out the next tutorial in this series. It will teach you [how to set up a production-ready Mesosphere cluster on Ubuntu 14.04](how-to-configure-a-production-ready-mesosphere-cluster-on-ubuntu-14-04)!
