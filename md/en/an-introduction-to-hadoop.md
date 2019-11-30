---
author: Melissa Anderson
date: 2016-10-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-hadoop
---

# An Introduction to Hadoop

## Introduction

Apache Hadoop is one of the earliest and most influential open-source tools for storing and processing the massive amount of readily-available digital data that has accumulated with the rise of the World Wide Web. It evolved from a project called Nutch, which attempted to find a better open source way to crawl the web. Nutch’s creators were heavily influenced by the thinking in two key papers from Google and originally incorporated them into Nutch, but eventually the storage and processing work split into the Hadoop project, while continuing to develop Nutch as its own web crawling project.

In this article, we’ll briefly consider data systems and some specific, distinguishing needs of big data systems. Then we’ll look at how Hadoop has evolved to address those needs.

## Data Systems

Data exists all over the place: on scraps of paper, in books, photos, multimedia files, server logs, and on web sites. When that data is purposefully collected, it enters a data system.

Imagine a school project where students measure the water level of a nearby creek each day. They record their measurements in the field on a clipboard, return to their classroom, and enter that data in a spreadsheet. When they’ve collected a sufficient amount, they begin to analyze it. They might compare the same months from different years, sort from the highest to lowest water level. They might build graphs to look for trends.

This school project illustrates a data system:

- Information exists in different locations (the field notebooks of different students)
- It is collected into a system (hand-entered into a spreadsheet)
- It is stored (saved to disk on the classroom computer; field notebooks might be copied or retained to verify the integrity of the data)
- It is analyzed (aggregated, sorted, or otherwise manipulated)
- Processed data is displayed (tables, charts, graphs)

This project is on the small end of the spectrum. A single computer can store, analyze, and display the daily water level measurements of one creek. Toward the other end of the spectrum, all the content on all the web pages in the world form a much larger dataset. At its most basic this is big data: so much information that it can’t fit on a single computer.

Search engine companies were facing this specific problem as web content exploded during the Dot-com era. In 2003, Google released its influential paper, [The Google File System](http://research.google.com/archive/gfs.html) describing how their proprietary software handled storage of the massive amount of data being processed for their search engine. It was followed in 2004 Google’s [MapReduce: Simplified Data Processing on Large Clusters](http://research.google.com/archive/mapreduce.html), which detailed how they simplified processing such large amounts of data. These two papers strongly influenced the architecture of Hadoop.

## How is Big Data Different?

The Google papers and Hadoop’s implementation of those ideas rested on four major changes in thinking about data that were necessary to accommodate the volume of data:

1. Big data systems had to accept that **data would be distributed**. Storing the dataset in pieces across a cluster of machines was unavoidable.

2. Once clusters became the storage foundation, then **software had to account for hardware failure** , because hardware failure is inevitable when you’re talking about running hundreds or thousands of machines in a cluster.

3. Since machines _will_ fail, they needed a new way of communicating with each other. In everyday data computing, we’re used to some specific machine, usually identified by an IP address or hostname sending specific data to another specific machine. This **explicit communication had to be replaced with implicit communication** , where some machine tells some other machine that it must process some specific data. Otherwise, programmers would face a verification problem at least as large as the data processing problem itself.

4. Finally, **computing would need to go to the data and process it on the distributed machines** rather than moving the vast quantities of data across the network.

Released in 2007, version 1.0 of the Java-based programming framework, Hadoop, was the first open source project to embrace these changes in thinking. Its first iteration consists of two layers:

1. **HDFS:** The Hadoop Distributed File System, responsible for storing data across multiple machines.
2. **MapReduce:** The software framework for processing the data in place and in parallel on each machine, as well as scheduling tasks, monitoring them and re-running failed ones.

## HDFS 1.0

The Hadoop Distributed File System, HDFS, is the distributed storage layer that Hadoop uses to spread out data and ensure that it is properly stored for high availability.

### How HDFS 1.0 Works

HDFS uses block replication to reliably store very large files across multiple machines with two distinct pieces of software: the NameNode server, which manages the file system namespace and client access, and the DataNodes, responsible for serving read and write requests, as well as block creation, deletion, and replication. A basic understanding of the replication pattern can be helpful for developers and cluster administrators since, while it generally works well, imbalances in the distribution of data can impact cluster performance and require tuning.

HDFS stores each file as a sequence of blocks, each identically sized except for the final one. By default, blocks are replicated three times, but both the size of the blocks and the number of replicas can be configured on a per-file basis. Files are write-once and have only a single writer at any time in order to enable high throughput data access and simplify data coherency issues.

The NameNode makes all decisions about block replication based on the heartbeat and block reports it receives from each DataNode in the cluster. The heartbeat signals that the DataNode is healthy, and the block report provides a list of all blocks on the DataNode.

When a new block is created, HDFS places the first replica on the node where the writer is running. A second replica is written on a randomly chosen node in any rack _except_ the rack where the the first replica was written. Then the third replica is placed on a randomly chosen machine in this second rack. If more than the default of three replicas is specified in the configuration, the remaining replicas are placed randomly, with the restriction that no more than one replica is placed on any one node and no more than two replicas are placed on the same rack.

### Limitations of HDFS 1.0

HDFS 1.0 established Hadoop as the early open source leader for storing big data. Part of that success resulted from architectural decisions that removed some of the complexity of distributed storage from the equation, but those choices weren’t without trade-offs. Key limitations of version 1.0 version included:

- **No Control over the Distributions of Blocks**  
The block replication pattern of HDFS is the backbone of its high availability. It can be very effective and removes the need for administrators and developers to be concerned at the block storage level, but since it doesn’t consider space utilization or the real-time situation of nodes, cluster administrators may need to use a balancer utility program to redistribute blocks.

- **The NameNode: A Single Point of Failure**  
A more significant limitation than the distribution of blocks, the NameNode represents a single point of failure. If the process or machine fails, the entire cluster is unavailable until the NameNode server is restarted, and even once it restarts, it must receive heartbeat messages from every node in the cluster before it is actually available, which prolongs the outage, especially with large clusters.

Despite these limitations, HDFS was a major contribution to working with big data.

## MapReduce 1.0

The second layer of Hadoop, MapReduce, is responsible for batch processing the data stored on HDFS. Hadoop’s implementation of Google’s MapReduce programming model makes it possible for developer to use the resources provided by HDFS without needing experience with parallel and distributed systems.

### How MapReduce 1.0 Works

Say we have a collection of text and we want to know how many times each word appears in the collection. The text is distributed across many servers, so mapping tasks are run on all the nodes in the cluster that have blocks of data in the collection. Each mapper loads the appropriate files, processes them, and creates a key-value pair for each occurrence.

These maps only have the data from the single node, so they must be shuffled together so that all the values with the same key can be sent to a reducer. When the reducer is done, the output is written to the disk of the reducer. This implicit communication model frees Hadoop users from having to explicitly move information from one machine to another.

We’ll illustrate this with a few sentences:

She sells seashells by six seashores.  
She sure sells seashells well.

    MAPPING SHUFFLING REDUCING
    {she, 1} {she, 1, 1} {she, 2}
    {sells, 1} {sells, 1, 1} {sells, 2}
    {seashells, 1} {seashells, 1, 1} {seashells, 2}
    {by, 1} {by, 1} {by, 1}
    {six, 1} {six, 1} {six, 1}
    {seashores, 1} {seashores, 1, 1} {seashores, 2}
    {she, 1} {sure, 1} {sure, 1}
    {sure, 1} {well, 1} {well, 1}
    {sells}
    {seashells, 1}
    {well, 1}       

If this mapping were done in sequence over a large dataset, it would take much too long, but done in parallel, then reduced, it becomes scalable for large datasets.

Higher-level components can plug into the MapReduce layer to supply additional functionality. For example, Apache Pig provides developers with a language for writing data analysis programs by abstracting the Java MapReduce idioms to a higher level, similar to what SQL does for relational databases. Apache Hive supports data analysis and reporting with an SQL-like interface to HDFS. It abstracts the MapReduce Java API queries to provide high-level query functionality for developers. Many additional components are available for Hadoop 1.x, but the ecosystem was constrained by some key limitations in MapReduce.

### Limitations of MapReduce 1

- **Tight coupling between MapReduce and HDFS**  
In the 1.x implementation, the responsibilities of the MapReduce layer extend beyond the data processing, to include cluster resource management and are tightly coupled to HDFS. This means that add-on developers for 1.x have to write multi-pass MapReduce programs, whether it is appropriate for the task or not, because MapReduce is the only way to access the filesystem.

- **Static Slots for Data Analysis**  
Mapping and Reducing take place on the DataNodes, which is key to working with big data, but only a limited, static number of single-purpose slots are available on each DataNode. The mapping slots can only map, and the reduce slots can only reduce. The number is set in configuration with no capacity for dynamic adjustment, and they’re idle and so wasted anytime the cluster workload doesn’t fit the configuration. The rigidity of slot allocation also makes it hard for non-MapReduce applications to schedule appropriately.

- **The JobTracker: A Single Point of Failure**  
Hadoop applications submit MapReduce tasks to the JobTracker, which in turn distributes those tasks to specific cluster nodes by locating a TaskTracker either with available slots or geographically near the data. The TaskTracker notifies the JobTracker if a task fails. The JobTracker may resubmit the job, mark the record to be excluded from future processing, or possibly blacklist an unreliable TaskTracker, but in the event of JobTracker failure for any reason, all MapReduce tasks are halted.

## Improvements in Hadoop 2.x

The 2.x branch of Hadoop, released in December of 2011, introduced four major improvements and corrected key limitations of version 1. Hadoop 2.0 introduced HDFS federation, which removed the NameNode as both a performance constraint and the single point of failure. In addition it decoupled MapReduce from HDFS with the introduction of YARN (Yet Another Resource Negotiator), opening the ecosystem of add-on products by allowing non-MapReduce processing models to interact with HDFS and bypass the MapReduce layer.

## 1 — HDFS Federation

HDFS federation introduces a clear separation between namespace and storage, making multiple namespaces in a cluster possible. This provides some key improvements:

- **Namespace scalability** The ability to add more NameNodes to a cluster allows horizontal scaling. Large clusters or clusters with many small files can benefit from adding additional NameNodes.
- **Performance gains** The single NameNode of 1.x limited filesystem read/write throughput. Multiple NameNodes alleviate this constraint on filesystem operations.
- **Isolation between namespaces** In multi-tenant environments with a single NameNode, it was possible for a one noisy neighbor to affect every other user on the system. With federation, it became possible to isolate system residents.

### How HDFS Federation Works

Federated NameNodes manage file system namespace. They operate independently and do not coordinate with each other. Instead, the DataNodes in the cluster register with every NameNode, sending heartbeats and block reports and handling incoming commands from the NameNode.

Blocks are spread across the common storage with the same random replication we saw in Hadoop 1.x. All the blocks that belong to a single namespace are known as a block pool. Such pools are managed independently, allowing a namespace to generate block IDs for new blocks without coordination with other namespaces. The combination of a namespace and its block pool is called a Namespace Volume, which forms a self-contained unit, so that when one of the federated NameNodes is deleted, its block pool is deleted as well.

In addition to the improved scalability, performance, and isolation provided by the introduction of NameNode federation, Hadoop 2.0 also introduced high availability for the NameNodes.

## 2 — NameNode High Availability

Prior to Hadoop 2.0, if the NameNode failed, the entire cluster was unavailable until it was restarted or brought up on a new machine. Upgrades to the software or hardware of the NameNode likewise created windows of downtime. To prevent this, Hadoop 2.0 implemented an active/passive configuration to allow for fast failover.

### How NameNode HA works

Two separate machines are configured as NameNodes, one active, the other in standby. They share access to a common directory on a shared storage device and when a modification is performed by the active node, it records the change in the log file stored in that common directory. The standby node constantly watches the directory and when edits occur, it applies those edits to its own namespace. If the active node fails, the standby will read unapplied edits from the shared storage, then promote itself to active.

## 3 — YARN

Hadoop 2.0 decoupled MapReduce from HDFS. The management of workloads, multi-tenancy, security controls, and high availability features were spun off into YARN (Yet Another Resource Negotiator). YARN is, in essence, a large-scale distributed operating system for big data applications that makes Hadoop well-suited for both MapReduce as well as other applications that can’t wait for batch processing to complete. YARN removed the need for working through the often I/O intensive, high latency MapReduce framework, enabling new processing models to be used with HDFS. The decoupled-MapReduce remained as a user-facing framework exclusively devoted to performing the task it was intended to do: batch processing.

Below are some of the processing models available to users of Hadoop 2.x:

- **Batch Processing**  
Batch processing systems are non-interactive and have access to all the data before processing starts. In addition, the questions being explored during processing must be known before processing starts. Batch processing is typically high latency, with the speed of big data batch jobs generally measured in minutes or more.

- **Interactive Processing**  
Interactive processing systems are needed when you don’t know all of your questions ahead of time. Instead, a user interprets the answer to a query, then formulates a new question. To support this kind of exploration, the response has to be returned much more quickly than a typical MapReduce job.

- **Stream Processing**  
Stream processing systems take large amounts of discrete data points and execute a continuous query to produce near-real time results as new data arrives in the system.

- **Graph Processing**  
Graph algorithms typically require communication between vertices or hops in order to move an edge from one vertex to another which required a lot of unnecessary overhead when passed through the 1.x MapReduce.

These are just a few of the alternative processing models and tools. For a comprehensive guide to the open source Hadoop ecosystem, including processing models other than MapReduce, see the [The Hadoop Ecosystem Table](http://hadoopecosystemtable.github.io/)

## 4 — ResourceManager High Availability

When it was first released, YARN had its own bottleneck: the ResourceManager. The single JobTracker in MapReduce 1.x handled resource management, job scheduling, and job monitoring. The early releases of YARN did improve on this by splitting responsibilities between a global ResourceManager and a per-application ApplicationMaster. The ResourceManager tracked cluster resources and schedules applications, such as MapReduce Jobs but was a single point of failure until the 2.4 release, which introduced an Active/Standby architecture.

In Hadoop 2.4 the single Resource manager was replaced by a single _active_ ResourceManager and one or more standbys. In the event of a failure of the active ResourceManager, administrators can manually trigger the transition from standby to active. They can also enable automatic failover by adding Apache Zookeeper to their stack. Among Zookeeper’s other task coordination responsibilities, it can track the status of YARN nodes and in the event of failure automatically trigger the transition to the standby.

## Hadoop 3.x

At the time of this writing, the Hadoop 3.0.0-alpha1 is available for testing. The 3.x branch aims to provide improvements such as HDFS erasure encoding to conserve disk space, improvements to YARN’s timeline service to improve its scalability, reliability, and usability, support for more than two NameNodes, and Intra-datanode balancer and more. To learn more, visit the overview of [major changes](http://hadoop.apache.org/docs/r3.0.0-alpha1).

## Conclusion

In this article, we’ve looked at how Hadoop evolved to meet the needs of increasingly large datasets. If you’re interested in experimenting with Hadoop, you might like to take a look at [Installing Hadoop in Stand-Alone Mode on Ubuntu 16.04](how-to-install-hadoop-in-stand-alone-mode-on-ubuntu-16-04). For more about big data concepts in general, see [An Introduction to Big Data Concepts and Terminology](an-introduction-to-big-data-concepts-and-terminology).
