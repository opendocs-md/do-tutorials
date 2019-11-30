---
author: O.S. Tezer
date: 2014-02-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-dns-round-robin-load-balancing-for-high-availability
---

# How To Configure DNS Round-Robin Load-Balancing For High-Availability

## Introduction

* * *

Albeit one of the more controversial techniques, a good method to geographically distribute your application by taking advantage of your provider’s global presence is to use and manage DNS responses (i.e. list of IP addresses returned). Unless you are willing to spend a little fortune on hardware and infrastructure costs, working with DNS to achieve high-availability is probably an excellent way to go.

In this article, we will see how to exploit some of the truly excellent and unique possibilities offered by DigitalOcean’s global cloud server / data-centre infrastructure to have a geographically-distributed, highly-available application set-up for minimal downtime (and thus dataloss) by managing DNS responses.

## Glossary

* * *

### 1. Traditional Application Deployment Structure

* * *

### 2. High-Availability

* * *

1. Highly-Available Application Deployment Structure
2. How To Achieve High-Availability Using DNS
3. Summary

### 3. How To Deploy Highly-Available Applications

* * *

1. Setting Up Load-Balancers / Reverse-Proxy
2. Setting Up DNS Records
3. Setting Up Application Servers
4. Setting Up Databases

## Traditional Application Deployment Structure

* * *

Traditional and most common application deployments depend on setups with all related components being located at the same place due to several reasons, such as:

- Providers’ lack of means;

- High costs, and/or;

- Complicated engineering work.

Even if an application is served from multiple machines sitting behind load-balancers (or reverse-proxies), and even if the database is also set up in a way to offer reliability and prevent data-loss, these kind of arrangements are prone to different levels of errors, causing you, at times, downtime.

In order to prevent this, one must rely on and use a more dependable system architecture. One whereby data and servers are globally distributed at different areas (e.g. San Francisco and New York).

## High-Availability

* * *

If your application is your business, you need to keep it accessible 24/7, if possible, almost without any interruption. Unfortunately, scaling horizontally over many servers at one location is not always the solution because of unexpected data-centre problems.

Globally-distributing your virtual servers across different geographical centres, however, can provide you the stability you require – thus, keeping applications’ up-time level as high as possible.

In terms of IT system-design, this kind of structure is referred to as _high-availability_.

Thanks to DigitalOcean’s presence in two continents, at five different locations, you can also spread your application stack globally.

You can connect a Floating IP, which is a publicly-accessible static IP address that can be mapped to one of your Droplets, to your redundant infrastructure and launch your site or service with a single public IP. This Floating IP can be instantly remapped to a new droplet, to allow for flexibility and responsiveness in your infrastructure. Read more about this new feature [here](how-to-use-floating-ips-on-digitalocean).

### Highly-Available Application Deployment Structure

* * *

Simply put, highly available application deployment structure, as we have just covered, depends on delivery and response to clients from different datacentres.

Although there are a number of possible ways to obtain this kind of structure, probably the simplest and the most affordable one is to take advantage of how DNS works.

A basic example set up can be considered as the following:

                                 ________________
                                | |
                                | CLIENT |
                                | WEB BROWSER |
                                | ________________ |
                                        ||
                                        ||
                                 _______\/_______
                                | |
                                | DNS SERVER |
                                | ________________ |
                                        ||
                                        ||
                                _______/ \_______
                               / \
                              / \
             ________________________________________
            | | | |
            | SAN FRANCISCO | | SAN FRANCISCO |
            | ____________________| |____________________ |
            | ______________| |______________ | 
            | | | | | | | |
            | | WEB SERVER | | | | WEB SERVER | |
            | | LOAD BALANCE | | | | LOAD BALANCE | |
            | | PROXY | | | | PROXY | |
            | | __________ | | | | __________ | |
            | ________| |________ | | ________| |________ |
                      || ____ ||
                      ||<=====||==================||=====>||    
                      \/ \/ \/ \/
             ________________________________________
            | | | |
            | SAN FRANCISCO | | NEW YORK |
            | ____________________| |____________________ |
            | ______________| |______________ |
            | | | | | | | |
            | | APP SERVER | | | | APP SERVER | |
            | | ____________ | | | | ____________ | |
            | ______||______ | | ______||______ |
            | | | | | | | |
            | | DATABASE |<==================>| DATABASE | |
            | | ______________| | | |______________ | |
            | ____________________| |____________________ |

### How To Achieve High-Availability Using DNS

* * *

When a user types the domain name of a website, through a set of defined rules (i.e. a protocol), the web-browser dials name-servers and asks them the address of the machines hosting the said web-site. Once it receives the IP address, then it sends the request to that computer, along with some additional data, and renders the response.

Since DNS allow multiple records to be kept (even the same kind), it becomes possible to list multiple hosts as the server.

Therefore, as demonstrated on the above schema, if you list the IP address of 2 load-balancers / reverse-proxies, located at two different locations, each set to balance the load between application servers, again located at at least two different data-centres, if one of the data-centres becomes unreachable, the client’s web-browser will try the next IP address records returned by the DNS server and repeat the process to get the web-site.

This kind of load-balancing is called Round Robin DNS load-balancing.

### Summary

* * *

Things might look a little bit complex at a first glance. Let’s summarise them using step-by-step instructions:

1. DNS can hold multiple records for the same domain name.

2. DNS can return the list of IP addresses for the same domain name.

3. When a web-browser requests a web-site, it will try these IP addresses one-by-one, until it gets a response.

4. These IP addresses should point at _not_ application servers but at load-balancers / reverse-proxies.

5. These reverse-proxies need to be balancing the load between multiple servers at multiple locations.

6. If a data-centre is down and the web-browser is unable to get a response from an IP address (i.e. a load-balancer), it will try to reach the address of the other.

7. Since it is very unlikely for both data-centres to be unreachable at the same time, the second load-balancer will return a response.

8. Web-application servers should be stateless to make the job of load-balancers easier.

9. Database servers should be set up in a replicated way.

## How To Deploy Highly-Available Applications

* * *

**Note:** This tutorial is programming language or web-server type agnostic. Following these instructions, you can achieve high-availability regardless of your choice of frameworks, web or HTTP servers.

### Setting Up Load-Balancers / Reverse-Proxy

* * *

The first step to high-availability is to set up two or more load-balancing reverse proxies which are going to communicate between your application servers.

1. **Instantiate two cloud servers at two locations:**  

Create two DigitalOcean droplets.

e.g. Article: [How To Create A DO Cloud Server](https://www.digitalocean.com/community/articles/how-to-create-your-first-digitalocean-droplet-virtual-server)

1. **Set up a load-balancer / reverse-proxy on each droplet:**  

Install and configure Nginx, Apache or HAProxy.

e.g. Article: [Nginx as a Front End Proxy](https://www.digitalocean.com/community/articles/how-to-configure-nginx-as-a-front-end-proxy-for-apache), [HAProxy Load-balancing on Ubuntu](https://www.digitalocean.com/community/articles/how-to-use-haproxy-to-set-up-http-load-balancing-on-an-ubuntu-vps)

1. **Get the IP Addresses of your load balancers:**  

Type `/sbin/ifconfig` and find out your droplets’ IP addresses.

e.g. `inet addr:107.170.40.112`

### Setting Up DNS Records

* * *

DNS A Records translate domain names (e.g. `www.digitalocean.com`) to machine-reachable IP addresses.

Once you are done configuring two droplets with a load-balancing reverse-proxy on each, the next step consists of adding 2 A records through DigitalOcean’s DNS service to point your domain name to the IP address.

1. **Log-in to your DigitalOcean control panel:**  

Click `DNS` on the left-hand menu and add a new domain name pointing to a load-balancer droplet from the previous step.

1. **Add a new A Records:**  

Once you are on the next step, click “Add Record” on the upper-hand side and create a new A record, with the IP address of the other load-balancer droplet.

### Setting Up Application Servers

* * *

Next step is setting up the application servers.

For global distribution to work, just like the first load-balancing servers you have created, you need two new droplets to host your application servers.

**Note:** You can also run each of your application servers on the same machine as the load-balancers; however, this would not be recommended.

Deploy or duplicate your application server droplet on two locations. For example:

- In **NY 1** and **NY 2** ;

- In **AMS 1** and **AMS 2** ;

- In **SF 1** and **NY 2** etc.

Go back to the first step and following the load-balancer setting up articles, configure them to proxy incoming connections to these two application-serving droplets.

### Setting Up Databases

* * *

It is hard to imagine a web-application without a database. The hardest part of distributing applications over multiple servers is probably dealing with databases.

Depending on your choice of database server, create a duplicated configuration but across multiple locations.

See:

- **For MySQL Master/Slave Replication:**  

[How To Set Up Master Slave Replication in MySQL](https://www.digitalocean.com/community/articles/how-to-set-up-master-slave-replication-in-mysql)

- **For MySQL Master/Master Replication:**  

[How To Set Up MySQL Master-Master Replication](https://www.digitalocean.com/community/articles/how-to-set-up-mysql-master-master-replication)

- **For PostgreSQL Master/Slave Replication:**  

[How To Set Up Master Slave Replication on PostgreSQL](https://www.digitalocean.com/community/articles/how-to-set-up-master-slave-replication-on-postgresql-on-an-ubuntu-12-04-vps)

Once you complete creating a replicated database structure, point your applications to use their addresses, as interacted in tutorials as the DB server.

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
