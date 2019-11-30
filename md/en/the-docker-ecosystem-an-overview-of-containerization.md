---
author: Justin Ellingwood
date: 2015-02-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/the-docker-ecosystem-an-overview-of-containerization
---

# The Docker Ecosystem: An Overview of Containerization

## Introduction

There are often many roadblocks that stand in the way of easily moving your application through the development cycle and eventually into production. Besides the actual work of developing your application to respond appropriately in each environment, you may also face issues with tracking down dependencies, scaling your application, and updating individual components without affecting the entire application.

Docker containerization and service-oriented design attempts to solve many of these problems. Applications can be broken up into manageable, functional components, packaged individually with all of their dependencies, and deployed on irregular architecture easily. Scaling and updating components is also simplified.

In this guide, we will discuss the benefits of containerization and how Docker helps to solve many of the issues we mentioned above. Docker is the core component in distributed container deployments that provide easy scalability and management.

## A Brief History of Linux Containerization

Containerization and isolation are not new concepts in the computing world. Some Unix-like operating systems have leveraged mature containerization technologies for over a decade.

In Linux, LXC, the building block that formed the foundation for later containerization technologies was added to the kernel in 2008. LXC combined the use of kernel cgroups (allows for isolating and tracking resource utilization) and namespaces (allows groups to be separated so they cannot “see” each other) to implement lightweight process isolation.

Later, Docker was introduced as a way of simplifying the tooling required to create and manage containers. It initially used LXC as its default execution driver (it has since developed a library called `libcontainer` for this purpose). Docker, while not introducing many new ideas, made them accessible to the average developer and system administrator by simplifying the process and standardizing on an interface. It spurred a renewed interest in containerization in the Linux world among developers.

While some of the topics we will discuss in this article are more general, we will be focusing mainly on Docker containerization due to its overwhelming popularity and its standard adoption.

## What Containerization Brings to the Picture

Containers come with many very attractive benefits for both developers and system administrators / operations teams.

Some of the most benefits are listed below.

### Abstraction of the host system away from the containerized application

Containers are meant to be completely standardized. This means that the container connects to the host and to anything outside of the container using defined interfaces. A containerized application should not rely on or be concerned with details about the underlying host’s resources or architecture. This simplifies development assumptions about the operating environment. Likewise, to the host, every container is a black box. It does not care about the details of the application inside.

### Easy Scalability

One of the benefits of the abstraction between the host system and the containers is that, given the correct application design, scaling can be simple and straight-forward. Service-oriented design (discussed later) combined with containerized applications provide the groundwork for easy scalability.

A developer may run a few containers on their workstation, while this system may be scaled horizontally in a staging or testing area. When the containers go into production, they can scale out again.

### Simple Dependency Management and Application Versioning

Containers allow a developer to bundle an application or an application component along with all of its dependencies as a unit. The host system does not have to be concerned with the dependencies needed to run a specific application. As long as it can run Docker, it should be able to run all Docker containers.

This makes dependency management easy and also simplifies application version management as well. Host systems and operations teams are no longer responsible for managing the dependency needs of an application because, apart from a reliance on related containers, they should all be contained within the container itself.

### Extremely lightweight, isolated execution environments

While containers do not provide the same level of isolation and resource management as virtualization technologies, what they win from the trade off is an extremely lightweight execution environment. Containers are isolated at the process level, sharing the host’s kernel. This means that the container itself does not include a complete operating system, leading to almost instant startup times. Developers can easily run hundreds of containers from their workstation without an issue.

### Shared Layering

Containers are lightweight in a different sense in that they are committed in “layers”. If multiple containers are based on the same layer, they can share the underlying layer without duplication, leading to very minimal disk space utilization for later images.

### Composability and Predictability

Docker files allow users to define the exact actions needed to create a new container image. This allows you to write your execution environment as if it were code, storing it in version control if desirable. The same Docker file built in the same environment will always produce an identical container image.

## Using Dockerfiles for Repeatable, Consistent Builds

While it is possible to create container images using an interactive process, it is often better to place the configuration steps within a Dockerfile once the necessary steps are known. Dockerfiles are simple build files that describe how to create a container image from a known starting point.

Dockerfiles are incredible useful and fairly easy to master. Some of the benefits they provide are:

- **Easy versioning** : The Dockerfiles themselves can be committed to version control to track changes and revert any mistakes
- **Predicatability** : Building images from a Dockerfile helps remove human error from the image creation process.
- **Accountability** : If you plan on sharing your images, it is often a good idea to provide the Dockerfile that created the image as a way for other users to audit the process. It basically provides a command history of the steps taken to create the image.
- **Flexibility** : Creating images from a Dockerfile allows you to override the defaults that interactive builds are given. This means that you do not have to provide as many runtime options to get the image to function as intended.

Dockerfiles are a great tool for automating container image building to establish a repeatable process.

## The Architecture of Containerized Applications

When designing applications to be deployed within containers, one of the first areas of concern is the actual architecture of the application. Generally, containerized applications work best when implementing a service-oriented design.

Service-oriented applications break the functionality of a system into discrete components that communicate with each other over well-defined interfaces. Container technology itself encourages this type of design because it allows each component to scale out or upgrade independently.

Applications implementing this type of design should have the following qualities:

- They should not care about or rely on any specifics of the host system
- Each component should provide consistent APIs that consumers can use to access the service
- Each service should take cues from environmental variables during initial configuration
- Application data should be stored outside of the container on mounted volumes or in data containers

These strategies allow each component to be independently swapped out or upgraded as long as the API is maintained. They also lend themselves towards focused horizontal scalability due to the fact that each component can be scaled according to the bottleneck being experienced.

Rather than hard coding specific values, each component generally can define reasonable defaults. The component can use these as fallback values, but should prefer values that it can gather from its environment. This is often accomplished through the aid of service discovery tools, which the component can query during its startup procedure.

Taking the configuration out of the actual container and placing it into the environment allows for easy changes to application behavior without rebuilding the container image. It also allows a single setting to influence multiple instances of a component. In general, service-oriented design couples well with environmental configuration strategies because both allow for more flexible deployments and more straight-forward scaling.

## Using a Docker Registry for Container Management

Once your application is split into functional components and configured to respond appropriately to other containers and configuration flags within the environment, the next step is usually to make your container images available through a registry. Uploading container images to a registry allows Docker hosts to pull down the image and spin up container instances by simply knowing the image name.

There are various Docker registries available for this purpose. Some are public registries where anyone can see and use the images that have been committed, while other registries are private. Images can be tagged so that they are easy to target for downloads or updating.

## Conclusion

Docker provides the fundamental building block necessary for distributed container deployments. By packaging application components in their own containers, horizontal scaling becomes a simple process of spinning up or shutting down multiple instances of each component. Docker provides the tools necessary to not only build containers, but also manage and share them with new users or hosts.

While containerized applications provide the necessary process isolation and packaging to assist in deployment, there are many other components necessary to adequately manage and scale containers over a distributed cluster of hosts. In our [next guide](the-docker-ecosystem-service-discovery-and-distributed-configuration-stores), we will discuss how service discovery and globally distributed configuration stores contribute to clustered container deployments.
