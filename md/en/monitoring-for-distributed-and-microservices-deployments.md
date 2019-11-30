---
author: Justin Ellingwood
date: 2018-01-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/monitoring-for-distributed-and-microservices-deployments
---

# Monitoring for Distributed and Microservices Deployments

## Introduction

System and infrastructure monitoring is a core responsibility of operations teams of all sizes. The industry has collectively developed many strategies and tools to help monitor servers, collect important data, and respond to incidents and changing conditions in varying environments. However, as software methodologies and infrastructure designs evolve, monitoring must adapt to meet new challenges and provide insight in relatively unfamiliar territory.

So far in this series, we’ve discussed [what metrics, monitoring, and alerting are](an-introduction-to-metrics-monitoring-and-alerting) and the qualities of good monitoring systems. We talked about [gathering metrics from your infrastructure and applications](gathering-metrics-from-your-infrastructure-and-applications) and the important signals to monitor throughout your infrastructure. In our last guide, we covered how to [put metrics and alerting into practice](putting-monitoring-and-alerting-into-practice) by understanding individual components and the qualities of good alert design.

In this guide, we will take a look at how monitoring and metrics collection changes for highly distributed architectures and microservices. The growing popularity of cloud computing, big data clusters, and instance orchestration layers has forced operations professionals to rethink how to design monitoring at scale and tackle unique problems with better instrumentation. We will talk about what makes new models of deployment different and what strategies can be used to meet these new demands.

## What Challenges Do Highly Distributed Architectures Create?

In order to model and mirror the systems it watches, monitoring infrastructure has always been somewhat distributed. However, many modern development practices—including designs around microservices, containers, and interchangeable, ephemeral compute instances—have changed the monitoring landscape dramatically. In many cases, the core features of these advancements are the very factors that make monitoring most difficult. Let’s take a moment to look at some of the ways these differ from traditional environments and how that affects monitoring.

### Work Is Decoupled From Underlying Resources

Some of the most fundamental changes in the way many systems behave are due to an explosion in new abstraction layers that software can be designed around. Container technology has changed the relationship between deployed software and the underlying operating system. Applications deployed in containers have different relationship to the outside world, other programs, and the host operating system than applications deployed through conventional means. Kernel and network abstractions can lead to different understandings of the operating environment depending on which layer you check.

This level of abstraction is incredibly helpful in many ways by creating consistent deployment strategies, making it easier to migrate work between hosts, and allowing developers close control over their applications’ runtime environments. However, these new capabilities come at the expense of increased complexity and a more distant relationship with the resources powering each process.

### Increase in Network-Based Communication

One commonality among newer paradigms is an increased reliance on internal network communication to coordinate and accomplish tasks. What was formerly the domain of a single application might now be spread among many components that need to coordinate and share information. This has a few repercussions in terms of communication infrastructure and monitoring.

First, because these models are built upon communication between small, discrete services, network health becomes more important than ever. In traditional, more monolithic architectures, coordinating tasks, sharing information, and organizing results was largely accomplished within applications with regular programming logic or through a comparably small amount of external communication. In contrast, the logical flow of highly distributed applications use the network to synchronize, check the health of peers, and pass information. Network health and performance directly impacts more functionality than previously, which means more intensive monitoring is needed to guarantee correct operation.

While the network has become more critical than ever, the ability to effectively monitor it is increasingly challenging due to the extended number of participants and individual lines of communication. Instead of tracking interactions between a few applications, correct communication between dozens, hundreds, or thousands of different points becomes necessary to ensure the same functionality. In addition to considerations of complexity, the increased volume of traffic also puts additional strain on the networking resources available, further compounding the necessity of reliable monitoring.

### Functionality and Responsibility Partitioned to Greater Degree

Above, we mentioned in passing the tendency for modern architectures to divide up work and functionality between many smaller, discrete components. These designs can have a direct impact on the monitoring landscape because they make clarity and comprehensibility especially valuable but increasingly elusive.

More robust tooling and instrumentation is required to ensure good working order. However, because the responsibility for completing any given task is fragmented and split between different workers (potentially on many different physical hosts), understanding where responsibility lies for performance issues or errors can be difficult. Requests and units of work that touch dozens of components, many of which are selected from pools of possible candidates, can make request path visualization or root cause analysis impractical using traditional mechanisms.

### Short-Lived and Ephemeral Units

A further struggle in adapting conventional monitoring is tracking short-lived or ephemeral units sensibly. Whether the units of concern are cloud compute instances, container instances, or other abstractions, these components often violate some of the assumptions made by conventional monitoring software.

For instance, in order to distinguish between a problematic downed node and an instance that was intentionally destroyed to scale down, the monitoring system must have a more intimate understanding of your provisioning and management layer than was previously necessary. For many modern systems, these events happen a great deal more frequently, so manually adjusting the monitoring domain each time is not practical. The deployment environment shifts more rapidly with these designs, so the monitoring layer must adopt new strategies to remain valuable.

One question that many systems must face is what to do with the data from destroyed instances. While work units may be provisioned and deprovisioned rapidly to accommodate changing demands, a decision must be made about what to do with the data related to the old instances. Data doesn’t necessarily lose its value immediately just because the underlying worker is no longer available. When hundreds or thousands of nodes might come and go each day, it can be difficult to know how to best construct a narrative about the overall operational health of your system from the fragmented data of short-lived instances.

## What Changes Are Required to Scale Your Monitoring?

Now that we’ve identified some of the unique challenges of distributed architectures and microservices, we can talk about ways monitoring systems can work within these realities. Some of the solutions involve re-evaluating and isolating what is most valuable about different types of metrics, while others involve new tooling or new ways of understanding the environment they inhabit.

### Granularity and Sampling

The increase in total traffic volume caused by the elevated number of services is one of the most straightforward problems to think about. Beyond the swell in transfer numbers caused by new architectures, monitoring activity itself can start to bog down the network and steal host resources. To best deal with increased volume, you can either scale out your monitoring infrastructure or reduce the resolution of the data you work with. Both approaches are worth looking at, but we will focus on the second one as it represents a more extensible and broadly useful solution.

Changing your data sampling rates can minimize the amount of data your system needs to collect from hosts. Sampling is a normal part of metrics collection that represents how frequently you ask for new values for a metric. Increasing the sampling interval will reduce the amount of data you have to handle but also reduce the resolution—the level of detail—of your data. While you must be careful and understand your minimum useful resolution, tweaking the data collection rates can have a profound impact on how many monitoring clients your system can adequately serve.

To decrease the loss of information resulting from lower resolutions, one option is to continue to collect data on hosts at the same frequency, but compile it into more digestible numbers for transfer over the network. Individual computers can aggregate and average metric values and send summaries to the monitoring system. This can help reduce the network traffic while maintaining accuracy since a large number of data points are still taken into account. Note that this helps reduce the data collection’s influence on the network, but does not by itself help with strain involved with gathering those numbers within the host.

### Make Decisions Based on Data Aggregated from Multiple Units

As mentioned above, one of the major differentiators between traditional systems and modern architectures is the break down of what components participate in handling requests. In distributed systems and microservices, a unit of work is much more likely to be given to a pool of workers through some type of scheduling or arbitrating layer. This has implications on many of the automated processes you might build around monitoring.

In environments that use pools of interchangeable workers, health checking and alert policies can grow to have complex relationships with the infrastructure they monitor. Health checks on individual workers can be useful to automatically decommission and recycle defective units. However if you have automation in place, at scale, it doesn’t matter much if a single web server fails out of a large pool. The system will self-correct to make sure only healthy units are in the active pool receiving requests.

Though host health checks can catch defective units, health checking the pool itself is more appropriate for alerting. The pool’s ability to satisfy the current workload has greater bearing on user experience than the capabilities of any individual worker. Alerts based on the number of healthy members, latency for the pool aggregate, or the pool error rate can notify operators of problems that are more difficult to automatically mitigate and more likely to impact users.

### Integration with the Provisioning Layer

In general, the monitoring layer in distributed systems needs to have a more complete understanding of the deployment environment and the provisioning mechanisms. Automated life cycle management becomes incredibly valuable because of the number of individual units involved in these architectures. Regardless of whether the units are raw containers, containers within an orchestration framework, or compute nodes in a cloud environment, a management layer exists that exposes health information and accepts commands to scale and respond to events.

The number of pieces in play increases the statistical likelihood of failure. With all other factors being equal, this would require more human intervention to respond to and mitigate these issues. Since the monitoring system is responsible for identifying failures and service degradation, if it can hook into the platform’s control interfaces, it can alleviate a large class of these problems. An immediate and automatic response triggered by the monitoring software can help maintain your system’s operational health.

This close relationship between the monitoring system and the deployment platform is not necessarily required or common in other architectures. But automated distributed systems aim to be self-regulating, with the ability to scale and adjust based on preconfigured rules and observed status. The monitoring system in this case takes on a central role in controlling the environment and deciding when to take action.

Another reason the monitoring system must have knowledge of the provisioning layer is to deal with the side effects of ephemeral instances. In environments where there is frequent turnover in the working instances, the monitoring system depends on information from a side channel to understand when actions were intentional or not. For instance, systems that can read API events from a provisioner can react differently when a server is destroyed intentionally by an operator than when a server suddenly becomes unresponsive with no associated event. Being able to differentiate between these events can help your monitoring remain useful, accurate, and trustworthy even though the underlying infrastructure might change frequently.

### Distributed Tracing

One of the most challenging aspects of highly distributed workloads is understanding the interplay between different components and isolating responsibility when attempting root cause analysis. Since a single request might touch dozens of small programs to generate a response, it can be difficult to interpret where bottlenecks or performance changes originate. To provide better information about how each component contributes to latency and processing overhead, a technique called distributed tracing has emerged.

Distributed tracing is an approach to instrumenting systems that works by adding code to each component to illuminate the request processing as it traverses your services. Each request is given a unique identifier at the edge of your infrastructure that is passed along as the task traverses your infrastructure. Each service then uses this ID to report errors and the timestamps for when it first saw the request and when it handed it off to the next stage. By aggregating the reports from components using the request ID, a detailed path with accurate timing data can be traced through your infrastructure.

This method can be used to understand how much time is spent on each part of a process and clearly identify any serious increases in latency. This extra instrumentation is a way to adapt metrics collection to large numbers of processing components. When mapped visually with time on the x axis, the resulting display shows the relationship between different stages, how long each process ran, and the dependency relationship between events that must run in parallel. This can be incredibly useful in understanding how to improve your systems and how time is being spent.

## Improving Operational Responsiveness for Distributed Systems

We’ve discussed how distributed architectures can make root cause analysis and operational clarity difficult to achieve. In many cases, changing the way that humans respond to and investigate issues is part of the answer to these ambiguities. Setting tools up to expose information in a way that empowers you to analyze the situation methodically can help sort through the many layers of data available. In this section, we’ll discuss ways to set yourself up for success when troubleshooting issues in large, distributed environments.

### Setting Alerts for the Four Golden Signals on Every Layer

The first step to ensure you can respond to problems in your systems is to know when they are occurring. In our guide on [gathering metrics from your infrastructure and applications](gathering-metrics-from-your-infrastructure-and-applications), we introduced the four golden signals—monitoring indicators identified by the Google SRE team as the most vital to track. The four signals are:

- latency
- traffic
- error rate
- saturation

These are still the best places to start when instrumenting your systems, but the number of layers that must be watched usually increases for highly distributed systems. The underlying infrastructure, the orchestration plane, and the working layer each need robust monitoring with thoughtful alerts set to identify important changes. The alerting conditions may grow in complexity to account for the ephemeral elements inherent within the platform.

### Getting a Complete Picture

Once your systems have identified an anomaly and notified your staff, your team needs to begin gathering data. Before continuing on from this step, they should have an understanding of what components are affected, when the incident began, and what specific alert condition was triggered.

The most useful way to begin understanding the scope of an incident is to start at a high level. Begin investigating by checking dashboards and visualizations that gather and generalize information from across your systems. This can help you quickly identify correlated factors and understand the immediate user-facing impact. During this process, you should be able to overlay information from different components and hosts.

The goal of this stage is to begin to create a mental or physical inventory of items to check in more detail and to start to prioritize your investigation. If you can identify a chain of related issues that traverse different layers, the lowest layer should take precedence: fixes to foundational layers often resolve symptoms at higher levels. The list of affected systems can serve as an informal checklist of places to validate fixes against later when mitigation is deployed.

### Drilling Down for Specific Issues

Once you feel that you have a reasonable high level view of the incident, drill down for more details into the components and systems on your list in order of priority. Detailed metrics about individual units will help you trace the route of the failure to the lowest responsible resource. While looking at more fine-grained dashboards and log entries, reference the list of affected components to try to further understand how side effects are being propagated through the system. With microservices, the number of interdependent components means that problems spill over to other services more frequently.

This stage is focused on isolating the service, component, or system responsible for the initial incident and identifying what specific problem is occurring. This might be newly deployed code, faulty physical infrastructure, a mistake or bug in the orchestration layer, or a change in workload that the system could not handle gracefully. Diagnosing what is happening and why allows you to discover how to mitigate the issue and regain operational health. Understanding the extent to which resolving this issue might fix issues reported on other systems can help you continue to prioritize mitigation tasks.

### Mitigating the Resolving the Issues

Once the specifics are identified, you can work on resolving or mitigating the problem. In many cases, there might be an obvious, quick way to restore service by either providing more resources, rolling back, or rerouting traffic to an alternative implementation. In these scenarios, resolution will be broken into three phases:

- Performing actions to work around the problem and restore immediate service
- Resolving the underlying issue to regain full functionality and operational health
- Fully Evaluating the reason for failure and implementing long term fixes to prevent recurrence

In many distributed systems, redundancy and highly available components will ensure that service is restored quickly, though more work might be necessary in the background to restore redundancy or bring the system out of a degraded state. You should use the list of impacted components compiled earlier as a measuring stick to determine whether your initial mitigation resolves cascading service issues. As the sophistication of the monitoring systems evolves, it may also be able to automate some of these fuller recovery processes by sending commands to the provisioning layer to bring up new instances of failed units or cycle out misbehaving units.

Given the automation possible in the first two phases, the most important work for the operations team is often understanding the root causes of an event. The knowledge gleaned from this process can be used to develop new triggers and policies to help predict future occurrences and further automate the system’s reactions. The monitoring software often gains new capabilities in response to each incident to guard against the newly discovered failure scenarios. For distributed systems, distributed traces, log entries, time series visualizations, and events like recent deploys can help you reconstruct the sequence of events and identify where software and human processes could be improved.

Because of the particular complexity inherent in large distributed systems, it is important to treat the resolution process of any significant event as an opportunity to learn and fine-tune your systems. The number of separate components and communication paths involved forces heavy reliance on automation and tools to help manage complexity. Encoding new lessons into the response mechanisms and rule sets of these components (as well as operational policies your team abides by) is the best way for your monitoring system to keep the management footprint for your team in check.

## Conclusion

In this guide, we’ve talked about some of the specific challenges that distributed architectures and microservice designs can introduce for monitoring and visibility software. Modern ways of building systems break some assumptions of traditional methods, requiring different approaches to handle the new configuration environments. We explored the adjustments you’ll need to consider as you move from monolithic systems to those that increasingly depend on ephemeral, cloud or container-based workers and high volume network coordination. Afterwards, we discussed some ways that your system architecture might affect the way you respond to incidents and resolution.
