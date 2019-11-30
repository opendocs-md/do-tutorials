---
author: Jon Schwenn, Fabian Barajas
date: 2018-03-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/navigator-s-guide-our-solutions-for-cloud-computing
---

# Navigator's Guide: Our Solutions for Cloud Computing

 **Note** : This is an early release version of the contents of the Navigator’s Guide book, an offering from the DigitalOcean Solutions Engineers. The goal of the book is to help business customers plan their infrastructure needs, provide working examples along the way, and include technical nuance and the “why” that makes some decisions better than others.

The book and accompanying code will be publicly available in a GitHub repository. Because this is an early release, the book is not yet complete and the repository is not yet public, but stay tuned!

Before we set sail, we want to share a brief infrastructure history lesson. This will help provide context on the needs that cloud infrastructure fills and how to take full advantage of it to get the most value, performance, and stability out of your infrastructure.

In the past, an online presence required one of the three major infrastructure options:

- Shared hosting, which was primarily suitable only for web developers and small web applications.
- Dedicated servers, the most expensive and least flexible option, which could be hosted in a data center or on premises.
- Virtual servers, widely known as VPSes (Virtual Private Servers), which shared the resources of dedicated hardware. Despite some inherent performance loss from virtualization, overall VPSes with modern server hardware exceed the requirements of the majority of users.

In order to scale, companies that relied on expensive on-premise servers would need request additional hardware far in advance. At any given time, their computing resources would exceed their requirements or fall short, but never match up. And, while virtual servers offered the best of both shared and dedicated offerings, the pricing structure was still similar to dedicated servers; the rigid monthly billing cycle required commitments and low flexibility.

In the late 2000s, in response to these growing market demands, the virtual server market began to expand and operate at a larger scale, which gave rise to the branding of “cloud computing”. Cloud computing solved the scalability problem by offering on-demand resources. The concept of billing at smaller increments of time made on-demand resources very cost effective. An entire development cluster could be deployed for a fraction of the cost when it was being billed at a per-hour rate and only existed for the short time required for development and testing.

Cloud computing was less clearly defined in its earlier days, but the concept was marketed as an fault-tolerant, always online infrastructure solution with built-in data redundancy. While may not be the case by default, it’s possible to build, and this book will show you how. We’ll architect solutions to prevent common cloud infrastructure issues, and by the end, your infrastructure will stay online, scale as you need it, and be both secure and easy to troubleshoot.

A single cloud instance is a single point of failure. Our recommendations, plans, and solutions help to distribute your application across many instances.

To help illustrate this concept, we are taking a familiar use-case and applying scaling and cloud methodologies. WordPress is a popular CMS and blog platform that is often hosted using shared hosting providers. WordPress sites that see a surge in traffic would require a switch to a dedicated server or VPS for more performance. These introductory and reactionary actions do not address future scalability or any redundancy needs. Let’s say that you have a website using the WordPress CMS software and you have been tasked with ensuring a 99.999% uptime. There is a business case for the website to nearly be online and performing perfectly all the time. This complex problem can be solved easier with cloud computing when compared to working with the dedicated server paradigm.

In this book we’ll take the concept of an individual Wordpress installation and scale it to handle enormous amounts of traffic and users while making sure that downtime and data loss concerns are properly planned for.

## Our Solutions

This book is broken into five parts. Here’s a more detailed overview of each. If you don’t understand some of the concepts in these overviews, don’t worry. That’s exactly what this book will teach you.

### Part 1 — Introduction and Setup

This is what you’re reading now. The next and final chapter walks you through the tools we’ll use to build our starter infrastructure and how to get your environment set up to follow along.

### Part 2 — Scaling and Preventing Downtime

If your infrastructure can’t stay online, you’re going to have a tough time doing much of anything.

In this section, we introduce configuration management to ensure that all of our infrastructure’s resources are standardized and can be deployed quickly. From there, we’ll introduce load balancing and high availability to eliminate the majority of problems that cause downtime. After we have a scalable solution in place, we’ll add continuous development controls to allow us to iterate and update our infrastructure.

### Part 3 — Keeping Your Data Safe

Your data is one of the most important assets your company has. Data loss is not an option.

Here, we highlight the best storage solutions for specific use cases. We go beyond basic backup concepts by outlining data-loss pitfalls to be aware of as well as planning for high impact outages. The goal is to have plans in place to reduce outages and always have multiple sources for data recovery.

### Part 4 — Knowing Everything About Your Infrastructure

At this point, our infrastructure will scale and we won’t lose any data, but there will always be issues that we didn’t or couldn’t foresee.

No matter how well-designed our infrastructure is, we’ll need to be able to troubleshoot and diagnose issues effectively. This section covers identifying bottlenecks and errors, defining performance, and testing.

### Part 5 — Securing Your Infrastructure

For as disruptive as downtime can be, having a bad security-related incident can make you wish you had a simple scaling issue instead.

This entire book is about proactive measures you can take to prevent catastrophic issues. This final portion keeps security top of mind and reviews best practices to keep infrastructure safe from mainstream security threats.
