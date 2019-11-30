---
author: Mark Drake
date: 2019-02-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-managed-databases
---

# Understanding Managed Databases

## Introduction

Secure, reliable data storage is a must for nearly every modern application. However, the infrastructure needed for a self-managed, on-premises database can be prohibitively expensive for many teams. Similarly, employees who have the skills and experience needed to maintain a production database effectively can be difficult to come by.

The spread of cloud computing services has lowered the barriers to entry associated with provisioning a database, but many developers still lack the time or expertise needed to manage and tune a database to suit their needs. For this reason, many businesses are turning to _managed database services_ to help them build and scale their databases in line with their growth.

In this conceptual article, we will go over what managed databases are and how they can be beneficial to many organizations. We will also cover some practical considerations one should make before building their next application on top of a managed database solution.

## Managed Databases in a Nutshell

A managed database is a cloud computing service in which the end user pays a cloud service provider for access to a database. Unlike a typical database, users don’t have to set up or maintain a managed database on their own; rather, it’s the provider’s responsibility to oversee the database’s infrastructure. This allows the user to focus on building their application instead of spending time configuring their database and keeping it up to date.

The process of provisioning a managed database varies by provider, but in general it’s similar to that of any other cloud-based service. After registering an account and logging in to the dashboard, the user reviews the available database options — such as the database engine and cluster size — and then chooses the setup that’s right for them. After you provision the managed database, you can connect to it through a GUI or client and can then begin loading data and and integrating the database with your application.

Managed data solutions simplify the process of provisioning and maintaining a database. Instead of running commands from a terminal to install and set one up, you can deploy a production-ready database with just a few clicks in your browser. By simplifying and automating database management, cloud providers make it easier for anyone, even novice database users, to build data-driven applications and websites. This was the result of a decades-long trend towards simplifying, automating, and abstracting various database management tasks, which was itself a response to pain points long felt by database administrators.

## Pain Points of On-Premises and Self-Managed Databases

Prior to the rise of the cloud computing model, any organization in need of a data center had to supply all the time, space, and resources that went into setting one up. Once their database was up and running, they also had to maintain the hardware, keep its software updated, hire a team to manage the database, and train their employees on how to use it.

As cloud computing services grew in popularity in the 2000s, it became easier and more affordable to provision server infrastructure, since the hardware and the space required for it no longer had to be owned or managed by those using it. Likewise, setting up a database entirely within the cloud became far less difficult; a business or developer would just have to requisition a server, install and configure their chosen database management system, and begin storing data.

While cloud computing did make the process of setting up a traditional database easier, it didn’t address all of its problems. For instance, in the cloud it can still be difficult to pinpoint the ideal size of a database’s infrastructure footprint before it begins collecting data. This is important because cloud consumers are charged based on the resources they consume, and they risk paying for more than what they require if the server they provision is larger than necessary. Additionally, as with traditional on-premises databases, managing one’s database in the cloud can be a costly endeavor. Depending on your needs, you may still need to hire an experienced database administrator or spend a significant amount of time and money training your existing staff to manage your database effectively.

Many of these issues are compounded for smaller organizations and independent developers. While a large business can usually afford to hire employees with a deep knowledge of databases, smaller teams usually have fewer resources available, leaving them with only their existing institutional knowledge. This makes tasks like replication, migrations, and backups all the more difficult and time consuming, as they can require a great deal of on-the-job learning as well as trial and error.

Managed databases help to resolve these pain points with a host of benefits to businesses and developers. Let’s walk through some of these benefits and how they can impact development teams.

## Benefits of Managed Databases

Managed database services can help to reduce many of the headaches associated with provisioning and managing a database. For one thing, developers build applications on top of managed database services to drastically speed up the process of provisioning a database server. With a self-managed solution, you must obtain a server (either on-premises or in the cloud), connect to it from a client or terminal, configure and secure it, and then install and set up the database management software before you can begin storing data. With a managed database, you only have to decide on the initial size of the database server, configure any additional provider-specific options, and you’ll have a new database ready to integrate with your app or website. This can usually be done in just a few minutes through the provider’s user interface.

Another appeal of managed databases is automation. Self-managed databases can consume a large amount of an organization’s resources because its employees have to perform every administrative task — from scaling to performing updates, running migrations, and creating backups — manually. With a managed database, however, these and other tasks are done either automatically or on-demand, which markedly reduces the risk of human error.

This relates to the fact that managed database services help to streamline the process of database scaling. Scaling a self-managed database can be very time- and resource-intensive. Whether you choose sharding, replication, load balancing, or something else as your scaling strategy, if you manage the infrastructure yourself then you’re responsible for ensuring that no data is lost in the process and that the application will continue to work properly. If you integrate your application with a managed database service, however, you can scale the database cluster on demand. Rather than having to work out the optimal server size or CPU usage beforehand, you can quickly provision more resources on-the-fly. This helps you avoid using unnecessary resources, meaning you also won’t pay for what you don’t need.

Managed solutions tend to have built-in high-availability. In the context of cloud computing, a service is said to be _highly available_ if it is stable and likely to run without failure for long periods of time. Most reputable cloud providers’ products come with a _service level agreement (SLA)_, a commitment between the provider and its customers that guarantees the availability and reliability of their services. A typical SLA will specify how much downtime the customer should expect, and many also define the compensation for customers if these service levels are not met. This provides assurance for the customer that their database won’t crash and, if it does, they can at least expect some kind of reparation from the provider.

In general, managed databases simplify the tasks associated with provisioning and maintaining a database. Depending on the provider, you or your team will still likely need some level of experience working with databases in order to provision a database and interact with it as you build and scale your application. Ultimately, though, the database-specific experience needed to administer a managed database will be much less than with self-managed solution.

Of course, managed databases aren’t able to solve every problem, and may prove to be a less-than-ideal choice for some. Next, we’ll go over a few of the potential drawbacks one should consider before provisioning a managed database.

## Practical Considerations

A managed database service can ease the stress of deploying and maintaining a database, but there are still a few things to keep in mind before committing to one. Recall that a principal draw of managed databases is that they abstract away most of the more tedious aspects of database administration. To this end, a managed database provider aims to deliver a rudimentary database that will satisfy the most common use cases. Accordingly, their database offerings won’t feature tons of customization options or the unique features included in more specialized database software. Because of this, you won’t have as much freedom to tailor your database and you’ll be limited to what the cloud provider has to offer.

A managed database is almost always more expensive than a self-managed one. This makes sense, since you’re paying for the cloud provider to support you in managing the database, but it can be a cause for concern for teams with limited resources. Moreover, pricing for managed databases is usually based on how much storage and RAM the database uses, how many reads it handles, and how many backups of the database the user creates. Likewise, any application using a managed database service that handle large amounts of data or traffic will be more expensive than if it were to use a self-managed cloud database.

One should also reflect on the impact switching to a managed database will have on their internal workflows and whether or not they’ll be able to adjust to those changes. Every provider differs, and depending on their SLA they may shoulder responsibility for only some administration tasks, which would be problematic for developers looking for a full-service solution. On the other hand, some providers could have a prohibitively restrictive SLA or make the customer entirely dependent on the provider in question, a situation known as [vendor lock-in](https://en.wikipedia.org/wiki/Vendor_lock-in).

Lastly, and perhaps most importantly, one should carefully consider whether or not any managed database service they’re considering using will meet their security needs. All databases, including on-premises databases, are prone to certain security threats, like SQL injection attacks or data leaks. However, the security dynamic is far different for databases hosted in the cloud. Managed database users can’t control the physical location of their data or who has access to it, nor can they ensure compliance with specific security standards. This can be especially problematic if your client has heightened security needs.

To illustrate, imagine that you’re hired by a bank to build an application where its clients can access financial records and make payments. The bank may stipulate that the app must have [data at rest encryption](https://en.wikipedia.org/wiki/Data_at_rest#Encryption) and appropriately scoped user permissions, and that it must be compliant with certain regulatory standards like [PCI DSS](https://en.wikipedia.org/wiki/Payment_Card_Industry_Data_Security_Standard). Not all managed database providers adhere to the same regulatory standards or maintain the same security practices, and they’re unlikely to adopt new standards or practices for just one of their customers. For this reason, it’s critical that you ensure any managed database provider you rely on for such an application is able to meet your security needs as well as the needs of your clients.

## Conclusion

Managed databases have many features that appeal to a wide variety of businesses and developers, but a managed database may not solve every problem or suit everyone’s needs. Some may find that a managed database’s limited feature set and configuration options, increased cost, and reduced flexibility outweigh any of its potential advantages. However, compelling benefits like ease of use, scalability, automated backups and upgrades, and high availability have led to increased adoption of managed database solutions in a variety of industries.

If you’re interested in learning more about DigitalOcean Managed Databases, we encourage you to check out our Managed Databases [product documentation](https://www.digitalocean.com/docs/databases).
