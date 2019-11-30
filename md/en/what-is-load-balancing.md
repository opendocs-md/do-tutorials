---
author: Melissa Anderson
date: 2017-02-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/what-is-load-balancing
---

# What is Load Balancing?

## Introduction

Load balancing is a key component of highly-available infrastructures commonly used to improve the performance and reliability of web sites, applications, databases and other services by distributing the workload across multiple servers.

A web infrastructure with no load balancing might look something like the following:

![web_server](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/HAProxy/web_server.png)

In this example, the user connects directly to the web server, at _yourdomain.com_. If this single web server goes down, the user will no longer be able to access the website. In addition, if many users try to access the server simultaneously and it is unable to handle the load, they may experience slow load times or may be unable to connect at all.

This single point of failure can be mitigated by introducing a load balancer and at least one additional web server on the backend. Typically, all of the backend servers will supply identical content so that users receive consistent content regardless of which server responds.

![Diagram 01: Load Balancers / Top-to-bottom](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high-availability/Diagram_2.png)

In the example illustrated above, the user accesses the load balancer, which forwards the user’s request to a backend server, which then responds directly to the user’s request. In this scenario, the single point of failure is now the load balancer itself. This can be mitigated by introducing a second load balancer, but before we discuss that, let’s explore how load balancers work.

## What kind of traffic can load balancers handle?

Load balancer administrators create forwarding rules for four main types of traffic:

- **HTTP** — Standard HTTP balancing directs requests based on standard HTTP mechanisms. The Load Balancer sets the `X-Forwarded-For`, `X-Forwarded-Proto`, and `X-Forwarded-Port` headers to give the backends information about the original request.
- **HTTPS** — HTTPS balancing functions the same as HTTP balancing, with the addition of encryption. Encryption is handled in one of two ways: either with **SSL passthrough** which maintains encryption all the way to the backend or with **SSL termination** which places the decryption burden on the load balancer but sends the traffic unencrypted to the back end.
- **TCP** — For applications that do not use HTTP or HTTPS, TCP traffic can also be balanced. For example, traffic to a database cluster could be spread across all of the servers.
- **UDP** — More recently, some load balancers have added support for load balancing core internet protocols like DNS and syslogd that use UDP.

These forwarding rules will define the protocol and port on the load balancer itself and map them to the protocol and port the load balancer will use to route the traffic to on the backend.

## How does the load balancer choose the backend server?

Load balancers choose which server to forward a request to based on a combination of two factors. They will first ensure that any server they can choose is actually responding appropriately to requests and then use a pre-configured rule to select from among that healthy pool.

### Health Checks

Load balancers should only forward traffic to “healthy” backend servers. To monitor the health of a backend server, health checks regularly attempt to connect to backend servers using the protocol and port defined by the forwarding rules to ensure that servers are listening. If a server fails a health check, and therefore is unable to serve requests, it is automatically removed from the pool, and traffic will not be forwarded to it until it responds to the health checks again.

### Load Balancing Algorithms

The load balancing algorithm that is used determines which of the healthy servers on the backend will be selected. A few of the commonly used algorithms are:

**Round Robin** — Round Robin means servers will be selected sequentially. The load balancer will select the first server on its list for the first request, then move down the list in order, starting over at the top when it reaches the end.

**Least Connections** — Least Connections means the load balancer will select the server with the least connections and is recommended when traffic results in longer sessions.

**Source** — With the Source algorithm, the load balancer will select which server to use based on a hash of the source IP of the request, such as the visitor’s IP address. This method ensures that a particular user will consistently connect to the same server.

The algorithms available to administrators vary depending on the specific load balancing technology in use.

### How do load balancers handle state?

Some applications require that a user continues to connect to the same backend server. A Source algorithm creates an affinity based on client IP information. Another way to achieve this at the web application level is through **sticky sessions** , where the load balancer sets a cookie and all of the requests from that session are directed to the same physical server.

## Redundant Load Balancers

To remove the load balancer as a single point of failure, a second load balancer can be connected to the first to form a cluster, where each one monitors the others’ health. Each one is equally capable of failure detection and recovery.

![Diagram 02: Cluster / Distributed](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high-availability/Diagram_1.png)

In the event the main load balancer fails, DNS must take users to the to the second load balancer. Because DNS changes can take a considerable amount of time to be propagated on the Internet and to make this failover automatic, many administrators will use systems that allow for flexible IP address remapping, such as [floating IPs](how-to-use-floating-ips-on-digitalocean). On demand IP address remapping eliminates the propagation and caching issues inherent in DNS changes by providing a static IP address that can be easily remapped when needed. The domain name can remain associated with the same IP address, while the IP address itself is moved between servers.

This is how a highly available infrastructure using Floating IPs might look:

![Diagram 03: Floating IPs](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/high_availability/ha-diagram-animated.gif)

## Conclusion

In this article, we’ve given an overview of load balancer concepts and how they work in general. To learn more about specific load balancing technologies, you might like to look at:

### DigitalOcean’s Load Balancing Service

- [How To Create Your First DigitalOcean Load Balancer](how-to-create-your-first-digitalocean-load-balancer)
- [How To Configure SSL Passthrough on DigitalOcean Load Balancers](how-to-configure-ssl-passthrough-on-digitalocean-load-balancers)
- [How To Configure SSL Termination on DigitalOcean Load Balancers](how-to-configure-ssl-termination-on-digitalocean-load-balancers)
- How To Balance TCP Traffic with DigitalOcean Load Balancers

### HAProxy

- [An Introduction to HAProxy and Load Balancing Concepts](an-introduction-to-haproxy-and-load-balancing-concepts)
- [How To Set Up Highly Available HAProxy Servers with Keepalived and Floating IPs on Ubuntu 14.04](how-to-set-up-highly-available-haproxy-servers-with-keepalived-and-floating-ips-on-ubuntu-14-04)
- [Load Balancing WordPress with HAProxy](https://www.digitalocean.com/community/tutorial_series/load-balancing-wordpress-with-haproxy)

### Nginx

- [Understanding Nginx HTTP Proxying, Load Balancing, Buffering, and Caching](understanding-nginx-http-proxying-load-balancing-buffering-and-caching)
- [How To Set Up Nginx Load Balancing with SSL Termination](how-to-set-up-nginx-load-balancing-with-ssl-termination)
