---
author: Hazel Virdó
date: 2017-09-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/what-is-immutable-infrastructure
---

# What Is Immutable Infrastructure?

## Introduction

In a traditional mutable server infrastructure, servers are continually updated and modified in place. Engineers and administrators working with this kind of infrastructure can SSH into their servers, upgrade or downgrade packages manually, tweak configuration files on a server-by-server basis, and deploy new code directly onto existing servers. In other words, these servers are mutable; they can be changed after they’re created. Infrastructure comprised of mutable servers can itself be called mutable, traditional, or (disparagingly) artisanal.

An _immutable infrastructure_ is another infrastructure paradigm in which servers are never modified after they’re deployed. If something needs to be updated, fixed, or modified in any way, new servers built from a common image with the appropriate changes are provisioned to replace the old ones. After they’re validated, they’re put into use and the old ones are decommissioned.

The benefits of an immutable infrastructure include more consistency and reliability in your infrastructure and a simpler, more predictable deployment process. It mitigates or entirely prevents issues that are common in mutable infrastructures, like configuration drift and snowflake servers. However, using it efficiently often includes comprehensive deployment automation, fast server provisioning in a cloud computing environment, and solutions for handling stateful or ephemeral data like logs.

The rest of this article will:

- Explain the conceptual and practical differences between mutable and immutable infrastructure
- Describe the advantages of using an immutable infrastructure and contextualize the complications
- Give a high-level overview of the implementation details and necessary components for an immutable infrastructure

## Differences Between Mutable and Immutable Infrastructure

The most fundamental difference between mutable and immutable infrastructure is in their central policy: the components of the former are designed to be changed after deployment; the components of the latter are designed to remain unchanged and ultimately be replaced. This tutorial focuses on those components as servers, but there are other ways to implement an immutable infrastructure, like with containers, that apply the same high-level concepts.

To go into more depth, there are both practical and conceptual differences between server-based mutable and immutable infrastructures.

Conceptually speaking, the two kinds of infrastructure vary greatly in their approach to how servers should be treated (e.g. created, maintained, updated, destroyed). This is commonly illustrated with a “pets versus cattle” analogy.

Practically speaking, mutable infrastructure is a much older infrastructure paradigm that predates the core technologies, like virtualization and cloud computing, that make immutable infrastructures possible and practical. Knowing this history helps contextualize the conceptual differences between the two and the implications of using one or the other in modern day infrastructure.

The next two sections will talk about these differences in more detail.

### Practical Differences: Embracing the Cloud

Before virtualization and cloud computing became possible and widely available, server infrastructure was centered around physical servers. These physical servers were expensive and time-consuming to create; the initial setup could take days or weeks because of how long it took to order new hardware, configure the machine, and then install it in a [colo](https://en.wikipedia.org/wiki/Colocation_centre) or similar location.

Mutable infrastructure has its origins here. Because the cost of replacing a server was so high, it was most practical to keep using the servers you had running for as long as possible with as little downtime as possible. This meant there were a lot of in place changes for regular deployments and updates, but also for ad-hoc fixes, tweaks, and patches when something went wrong. The consequence of frequent manual changes is that servers can become hard to replicate, making each one a unique and fragile component of the overall infrastructure.

The advent of [virtualization and on-demand/cloud computing](an-introduction-to-cloud-hosting) represented a turning point in server architecture. Virtual servers were less expensive, even at scale, and they could be created and destroyed in minutes instead of days or weeks. This made new deployment workflows and server management techniques possible for the first time, like using [configuration management](an-introduction-to-configuration-management) or [cloud APIs](how-to-use-the-digitalocean-api-v2) to provision new servers quickly, programmatically, and automatically. The speed and low cost of creating new virtual servers is what makes the immutability principle practical.

Traditional mutable infrastructures originally developed when the use of physical servers dictated what was possible in their management, and continued to develop as technology improved over time. The paradigm of modifying servers after deployment is still common in modern day infrastructure. In contrast, immutable infrastructures were designed from the start to rely on virtualization-based technologies for fast provisioning of architecture components, like cloud computing’s virtual servers.

### Conceptual Differences: Pets vs Cattle, Snowflakes vs Phoenixes

The fundamental conceptual change that cloud computing advanced was that servers could be considered disposable. It’s prohibitively impractical to consider discarding and replacing physical servers, but with virtual servers, it’s not only possible but easy and efficient to do so.

The servers in traditional mutable infrastructures were irreplaceable, unique systems that had to be kept running at all times. In this way, they were like pets: one of a kind, inimitable, and tended to by hand. Losing one could be devastating. The servers in immutable infrastructures, on the other hand, are disposable and easy to replicate or scale with automated tools. In this way, they’re like cattle: one of many in a herd where no individual is unique or indispensable.

To quote [Randy Bias](http://cloudscaling.com/blog/cloud-computing/the-history-of-pets-vs-cattle/), who first applied the pets vs. cattle analogy to cloud computing:

> In the old way of doing things, we treat our servers like pets, for example Bob the mail server. If Bob goes down, it’s all hands on deck. The CEO can’t get his email and it’s the end of the world. In the new way, servers are numbered, like cattle in a herd. For example, www001 to www100. When one server goes down, it’s taken out back, shot, and replaced on the line.

Another similar way of illustrating the implications of the difference between how servers are treated is with the concepts of snowflake servers and phoenix servers.

[Snowflake servers](https://martinfowler.com/bliki/SnowflakeServer.html) are similar to pets. They are servers that are managed by hand, frequently updated and tweaked in place, leading to a unique environment. [Phoenix servers](https://martinfowler.com/bliki/PhoenixServer.html) are similar to cattle. They are servers that are always built from scratch and are easy to recreate (or “rise from the ashes”) through automated procedures.

Immutable infrastructures are made almost entirely of cattle or phoenix servers, whereas mutable infrastructures allow some (or many) pets or snowflake servers. The next section discusses the implications of both.

## Advantages of Immutable Infrastructure

To understand the advantages of immutable infrastructures, it’s necessary to contextualize the disadvantages of mutable infrastructures.

Servers in mutable infrastructures can suffer from configuration drift, which is when undocumented, impromptu changes cause servers’ configurations to become increasingly divergent from each other and from the reviewed, approved, and originally-deployed configuration. These increasingly snowflake-like servers are hard to reproduce and replace, making things like scaling and recovering from issues difficult. Even replicating issues to debug them becomes challenging because of the difficulty of creating a staging environment that matches the production environment.

The importance or necessity of a server’s different configurations becomes unclear after many manual modifications, so updating or changing any of it may have unintended side effects. Even in the best case, making changes to an existing system isn’t guaranteed to work, which means deployments that rely on doing so risk failing or putting the server into an unknown state.

With this in mind, the primary benefits of using an immutable infrastructure are deployment simplicity, reliability, and consistency, all of which ultimately minimize or eliminate many common pain points and failure points.

#### Known-good server state and fewer deployment failures

All deployments in an immutable infrastructure are executed by provisioning new servers based on a validated and version-controlled image. As a result, these deployments don’t depend on the previous state of a server, and consequently can’t fail — or only partially complete — because of it.

When new servers are provisioned, they can be tested before being put into use, reducing the actual deployment process to a single update to make the new server available, like updating a load balancer. In other words, deployments become [atomic](https://en.wikipedia.org/wiki/Linearizability): either they complete successfully or nothing changes.

This makes deploying much more reliable and also ensures that the state of every server in the infrastructure is always known. Additionally, this process makes it easy to implement a [blue-green deployment](how-to-use-blue-green-deployments-to-release-software-safely) or [rolling releases](https://en.wikipedia.org/wiki/Rolling_release), meaning no downtime.

#### No configuration drift or snowflake servers

All configuration changes in an immutable infrastructure are implemented by checking an updated image into version control with documentation and using an automated, unified deployment process to deploy replacement servers with that image. Shell access to the servers is sometimes completely restricted.

This prevents complicated or hard-to-reproduce setups by eliminating the risk of snowflake servers and configuration drift. This also prevents situations where someone needs to modify a poorly-understood production server, which runs a high risk of error and causing downtime or unintended behavior.

#### Consistent staging environments and easy horizontal scaling

Because all servers use the same creation process, there are no deployment edge cases. This prevents messy or inconsistent staging environments by making it trivial to duplicate the production environment, and also simplifies [horizontal scaling](https://blog.digitalocean.com/horizontally-scaling-php-applications/) by seamlessly allowing you to add more identical servers to your infrastructure.

#### Simple rollback and recovery processes

Using version control to keep image history also helps with handling production issues. The same process that is used to deploy new images can also be used to roll back to older versions, adding additional resilience and reducing recovery time when handling downtime.

## Immutable Infrastructure Implementation Details

Immutable infrastructure comes with some requirements and nuance in its implementation details, especially compared to traditional mutable infrastructures.

It is technically possible to implement an immutable infrastructure independent of any automation, tooling, or software design principles by simply adhering to the key principle of immutability. However, the components below (roughly in priority order) are strongly recommended for practicality at scale:

- **Servers in a cloud computing environment** , or another virtualized environment ([like containers](https://www.youtube.com/watch?v=S3gYxEVz_b8), though that changes some other requirements below). The key here is to have isolated instances with fast provisioning from custom images, as well as automated management for creation and destruction via an API or similar. 

- **Full automation of your entire deployment pipeline** , ideally including post-creation image validation. Setting up this automation adds significantly to the upfront cost of implementing this infrastructure, but it is a one-time cost which amortizes out quickly.

- A **[service-oriented architecture](https://en.wikipedia.org/wiki/Service-oriented_architecture)**, separating your infrastructure into modular, logically discrete units that communicate over a network. This allows you to take full advantage of cloud computing’s offerings, which are [similarly service-oriented](https://en.wikipedia.org/wiki/Cloud_computing#Service_models) (e.g. IaaS, PaaS).

- A **[stateless](https://en.wikipedia.org/wiki/Service_statelessness_principle), volatile application layer** which includes your immutable servers. Anything here can get destroyed and rebuilt quickly at any time (volatile) without any loss of data (stateless).

- A **persistent data layer** that includes:

- **Dedication from engineering and operations teams** to collaborate and commit to the approach. For all the simplicity of the end product, there are a lot of moving parts in an immutable infrastructure, and no one person will know all of it. Additionally, some aspects of working within this infrastructure can be new or outside of people’s comfort zones, like debugging or doing one-off tasks without shell access.

There are many different ways to implement each of these components. Choosing one largely depends on personal preference and familiarity, and how much of your infrastructure you want to build yourself versus relying on a paid service.

[CI/CD tools](ci-cd-tools-comparison-jenkins-gitlab-ci-buildbot-drone-and-concourse) can be a good place to start for deployment pipeline automation; [Compose](https://www.compose.com/) is an option for a DBaaS solution; [rsyslog](how-to-centralize-logs-with-rsyslog-logstash-and-elasticsearch-on-ubuntu-14-04) and [ELK](https://www.digitalocean.com/community/tutorial_series/centralized-logging-with-elk-stack-elasticsearch-logstash-and-kibana-on-ubuntu-14-04) are popular choices for centralized logging; [Netflix’s Chaos Monkey](https://github.com/Netflix/chaosmonkey), which randomly kills servers in your production environment, is a real trial by fire for your final setup.

## Conclusion

This article covered what immutable infrastructure is, the conceptual and practical differences between it and older-style mutable infrastructure, the advantages of using it, and details on its implementation.

Knowing if or when you should consider moving to an immutable infrastructure can be difficult, and there’s no one clearly defined cutoff or inflection point. One way to begin is to implement some of the design practices recommended in this article, like configuration management, even if you’re still working in a largely mutable environment. This will make a transition to immutability easier in the future.

If you have an infrastructure with most of the components above and you find yourself hitting scaling issues or feeling frustrated with the clunkiness of your deployment process, that can be a good time to start evaluating how an immutability could improve your infrastructure.

You can learn more from several companies (including [Codeship](https://blog.codeship.com/immutable-infrastructure/), [Chef](https://blog.chef.io/2014/06/23/immutable-infrastructure-practical-or-not/), [Koddi](https://www.koddi.com/developing-with-an-immutable-infrastructure/), and [Fugue](https://fugue.co/assets/docs/Immutable_Infrastructure_Fugue.pdf)) that have written about their implementations of immutable infrastructure.
