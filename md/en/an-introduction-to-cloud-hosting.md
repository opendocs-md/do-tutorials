---
author: Josh Barnett
date: 2014-11-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-hosting
---

# An Introduction to Cloud Hosting

## Introduction

Cloud hosting is a method of using online virtual servers that can be created, modified, and destroyed on demand. Cloud servers are allocated resources like CPU cores and memory by the physical server that it’s hosted on and can be configured with a developer’s choice of operating system and accompanying software. Cloud hosting can be used for hosting websites, sending and storing emails, and distributing web-based applications and other services.

In this guide, we will go over some of the basic concepts involved in cloud hosting, including how virtualization works, the components in a virtual environment, and comparisons with other common hosting methods.

## What is “the Cloud”?

“The Cloud” is a common term that refers to servers connected to the Internet that are available for public use, either through paid leasing or as part of a software or platform service. A cloud-based service can take many forms, including web hosting, file hosting and sharing, and software distribution. “The Cloud” can also be used to refer to cloud computing, which is the practice of using several servers linked together to share the workload of a task. Instead of running a complex process on a single powerful machine, cloud computing distributes the task across many smaller computers.

### Other Hosting Methods

Cloud hosting is just one of many different types of hosting available to customers and developers today, though there are some key differences between them. Traditionally, sites and apps with low budgets and low traffic would use shared hosting, while more demanding workloads would be hosted on dedicated servers.

**Shared hosting** is the most common and most affordable way to get a small and simple site up and running. In this scenario, hundreds or thousands of sites share a common pool of server resources, like memory and CPU. Shared hosting tends to offer the most basic and inflexible feature and pricing structures, as access to the site’s underlying software is very limited due to the shared nature of the server.

**Dedicated hosting** is when a physical server machine is sold or leased to a single client. This is more flexible than shared hosting, as a developer has full control over the server’s hardware, operating system, and software configuration. Dedicated servers are common among more demanding applications, such as enterprise software and commercial services like social media, online games, and development platforms.

## How Virtualization Works

Cloud hosting environments are broken down into two main parts: the virtual servers that apps and websites can be hosted on and the physical hosts that manage the virtual servers. This virtualization is what is behind the features and advantages of cloud hosting: the relationship between host and virtual server provides flexibility and scaling that are not available through other hosting methods.

### Virtual Servers

The most common form of cloud hosting today is the use of a virtual private server, or VPS. A VPS is a virtual server that acts like a real computer with its own operating system. While virtual servers share resources that are allocated to them by the host, their software is well isolated, so operations on one VPS won’t affect the others.

Virtual servers are deployed and managed by the hypervisor of a physical host. Each virtual server has an operating system installed by the hypervisor and available to the user to add software on top of. For many practical purposes, a virtual server is identical in use to a dedicated physical server, though performance may be lower in some cases due to the virtual server sharing physical hardware resources with other servers on the same host.

### Hosts

Resources are allocated to a virtual server by the physical server that it is hosted on. This host uses a software layer called a hypervisor to deploy, manage, and grant resources to the virtual servers that are under its control. The term “hypervisor” is often used to refer to the physical hosts that hypervisors (and their virtual servers) are installed on.

The host is in charge of allocating memory, CPU cores, and a network connection to a virtual server when one is launched. An ongoing duty of the hypervisor is to schedule processes between the virtual CPU cores and the physical ones, since multiple virtual servers may be utilizing the same physical cores. The method of choice for process scheduling is one of the key differences between different hypervisors.

### Hypervisors

There are a few common hypervisor software available for cloud hosts today. These different virtualization methods have some key differences, but they all provide the tools that a host needs to deploy, maintain, move, and destroy virtual servers as needed.

**KVM** , short for “Kernel-Based Virtual Machine”, is a virtualization infrastructure that is built in to the Linux kernel. When activated, this kernel module turns the Linux machine into a hypervisor, allowing it to begin hosting virtual servers. This method is in contrast from how other hypervisors usually work, as KVM does not need to create or emulate kernel components that are used for virtual hosting.

**Xen** is one of the most common hypervisors in use today. Unlike KVM, Xen uses a microkernel, which provides the tools needed to support virtual servers without modifying the host’s kernel. Xen supports two distinct methods of virtualization: paravirtualization, which skips the need to emulate hardware but requires special modifications made to the virtual servers’ operating system, and hardware-assisted virtualization, which uses special hardware features to efficiently emulate a virtual server so that they can use unmodified operating systems.

**ESXi** is an enterprise-level hypervisor offered by VMware. ESXi is unique in that it doesn’t require the host to have an underlying operating system. This is referred to as a “type 1” hypervisor and is extremely efficient due to the lack of a “middleman” between the hardware and the virtual servers. With type 1 hypervisors like ESXi, no operating system needs to be loaded on the host because the hypervisor itself acts as the operating system.

**Hyper-V** is one of the most popular methods of virtualizing Windows servers and is available as a system service in Windows Server. This makes Hyper-V a common choice for developers working within a Windows software environment. Hyper-V is included in Windows Server 2008 and 2012 and is also available as a stand-alone server without an existing installation of Windows Server.

## Why Cloud Hosting?

The features offered by virtualization lend themselves well to a cloud hosting environment. Virtual servers can be configured with a wide range of hardware resource allocations, and can often have resources added or removed as needs change over time. Some cloud hosts can move a virtual server from one hypervisor to another with little or no downtime or duplicate the server for redundancy in case of a node failure.

### Customization

Developers often prefer to work in a VPS due to the control that they have over the virtual environment. Most virtual servers running Linux offer access to the root (administrator) account or `sudo` privileges by default, giving a developer the ability to install and modify whatever software they need.

This freedom of choice begins with the operating system. Most hypervisors are capable of hosting nearly any guest operating system, from open source software like Linux and BSD to proprietary systems like Windows. From there, developers can begin installing and configuring the building blocks needed for whatever they are working on. A cloud server’s configurations might involve a web server, database, email service, or an app that has been developed and is ready for distribution.

### Scalability

Cloud servers are very flexible in their ability to scale. Scaling methods fall into two broad categories: horizontal scaling and vertical scaling. Most hosting methods can scale one way or the other, but cloud hosting is unique in its ability to scale both horizontally and vertically. This is due to the virtual environment that a cloud server is built on: since its resources are an allocated portion of a larger physical pool, it’s easy to adjust these resources or duplicate the virtual image to other hypervisors.

**Horizontal scaling** , often referred to as “scaling out”, is the process of adding more nodes to a clustered system. This might involve adding more web servers to better manage traffic, adding new servers to a region to reduce latency, or adding more database workers to increase data transfer speed. Many newer web utilities, like CoreOS, Docker, and Couchbase, are built around efficient horizontal scaling.

**Vertical scaling** , or “scaling up”, is when a single server is upgraded with additional resources. This might be an expansion of available memory, an allocation of more CPU cores, or some other upgrade that increases that server’s capacity. These upgrades usually pave the way for additional software instances, like database workers, to operate on that server. Before horizontal scaling became cost-effective, vertical scaling was the method of choice to respond to increasing demand.

With cloud hosting, developers can scale depending on their application’s needs — they can scale out by deploying additional VPS nodes, scale up by upgrading existing servers, or do both when server needs have dramatically increased.

## Conclusion

By now, you should have a decent understanding of how cloud hosting works, including the relationship between hypervisors and the virtual servers that they are responsible for, as well as how cloud hosting compares to other common hosting methods. With this information in mind, you can choose the best hosting for your needs.
