---
author: Mitchell Anicas
date: 2015-06-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/building-for-production-web-applications-overview
---

# Building for Production: Web Applications — Overview

## Introduction

This 6-part tutorial will show you how to build out a multi-server production application setup from scratch. The final setup will be supported by backups, monitoring, and centralized logging systems, which will help you ensure that you will be able to detect problems and recover from them. The ultimate goal of this series is to build on standalone system administration concepts, and introduce you to some of the practical considerations of creating a production server setup.

If you are interested in reviewing some of the concepts that will be covered in this series, read these tutorials:

- [5 Common Server Setups For Your Web Application](5-common-server-setups-for-your-web-application)
- [5 Ways to Improve your Production Web Application Server Setup](5-ways-to-improve-your-production-web-application-server-setup)

While the linked articles provide general guidelines of a production application setup, this series will demonstrate how to plan and set up a sample application from start to finish. Hopefully, this will help you plan and implement your own production server environment, even if you are running a different application on a completely different technology stack. Because this tutorial covers many different system administration topics, it will often defer the detailed explanation to external supporting articles that provide supplemental information.

## Our Goal

By the end of this set of tutorials, we will have a production server setup for a PHP application, WordPress for demonstration purposes, that is accessible via [https://www.example.com/](https://www.example.com/). We will also include servers that will support the production application servers. The final setup will look something like this (private DNS and remote backups not pictured):

![Production Setup](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/production/lamp/final.png)

In this setup, the servers in the **Application** box are considered to be essential for the application run properly. Aside from the recovery plan and the remote backup server, the remaining components—backups, monitoring, and logging—will be added to support the production application setup. Each component will be installed on a separate Ubuntu 14.04 server within the same DigitalOcean region, NYC3 in our example, with Private Networking enabled.

The set of servers that compose application will be referred to as the following hostnames:

- **lb1:** HAProxy Load Balancer, accessible via [https://example.com/](https://example.com/)
- **app1:** Apache and PHP application server
- **app2:** Apache and PHP application server
- **db1:** MySQL database server

It is important to note that this type setup was chosen to demonstrate how to components of an application can be built on multiple servers; your own setup should be customized based on your own needs. This particular server setup has single points of failure which could be eliminated by adding another load balancer (and [round-robin DNS](how-to-configure-dns-round-robin-load-balancing-for-high-availability)) and [database server replication](how-to-set-up-mysql-master-master-replication) or adding a static IP that points to either an active or passive load balancer which is covered below which we will briefly cover.

The components that will support the Application servers will be referred to as the following hostnames:

- **backups:** Bacula backups server
- **monitoring:** Nagios monitoring server
- **logging:** Elasticsearch, Logstash, Kibana (ELK) stack for centralized logging

Additionally, the three following supporting components are not pictured in the diagram:

- **ns1:** Primary BIND nameserver for private DNS
- **ns2:** Secondary BIND nameserver for private DNS
- **remotebackups:** Remote server, located in a different region, for storing copies of the Bacula backups in case of a physical disaster in the production datacenter-===\

We will also develop basic recovery plans for failures in the various components of the application.

When we reach our goal setup, we will have a total of 10 servers. We’ll create them all at once (this simplifies things such as setting up DNS), but feel free to create each one as needed. If you are planning on using DigitalOcean backups as your backups solution, in addition to or in lieu of Bacula, be sure to select that option when creating your Droplets.

### High Availability (Optional)

A single point of failure is when one part of your infrastructure going down can make your entire site or service unavailable. If you want to address the single points of failure you this setup, you can make it highly available by adding another load balancer. Highly available services automatically fail over to a backup or passive system in the event of a failure. Having two load balancers in a high availability setup protects against downtime by ensuring that one load balancer is always passively available to accept traffic if the active load balancer is unavailable.

There are a number of ways to implement a high availability setup. To learn more, read [this section of How To Use Floating IPs](how-to-use-floating-ips-on-digitalocean#how-to-implement-an-ha-setup).

### Virtual Private Network (Optional)

If you want to secure the network communications amongst your servers, you may want to consider setting up a VPN. Securing network transmissions with encryption is especially important when the data is traveling over the Internet. Another benefit of using a VPN is that the identities of hosts are validated by the key authentication process, which will protect your services from unauthorized sources.

If you are looking for an open source VPN solution, you may want to consider Tinc or OpenVPN. In this particular case, Tinc, which uses mesh routing, is the better solution. Tutorials on both VPN solutions can be found here:

- [How To Install Tinc and Set Up a Basic VPN on Ubuntu 14.04](how-to-install-tinc-and-set-up-a-basic-vpn-on-ubuntu-14-04)
- [How To Secure Traffic Between VPS Using OpenVPN](how-to-secure-traffic-between-vps-using-openvpn)

## Prerequisites

Each Ubuntu 14.04 server should have a non-root superuser, which can be set up by following this tutorial: [Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04). All commands will be run as this user, on each server.

We will assume that you have some knowledge of basic Linux security concepts, which we will not cover in detail. If you need a quick Linux security primer, read this article: [7 Security Measures to Protect your Servers](7-security-measures-to-protect-your-servers).

### Domain Name

We will assume that your application will be served via a domain name, such as “example.com”. If you don’t already own one, purchase one from a domain name registrar.

Once you have your domain name of choice, you can follow this tutorial to use it with the DigitalOcean DNS: [How to Point to DigitalOcean Nameservers From Common Domain Registrars](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars).

In addition to making your site easier to reach (compared to an IP address), a domain name is required to achieve the domain and identity validation benefits of using SSL certificates, which also provide encryption for communication between your application and its users.

### SSL Certificate

TLS/SSL provides encryption and domain validation between your application and its users, so we will use an SSL certificate in our setup. In our example, because we want users to access our site at “[www.example.com](http://www.example.com)”, that is what we will specify as the certificate’s Common Name (CN). The certificate will be installed on the HAProxy server, **lb1** , so you may want to generate the certificate keys and CSR there for convenience.

If you require a certificate that provides identity validation, you can get an SSL certificate free using Let’s Encrypt, or purchase one from a commercial Certificate Authority. For details on the Let’s Encrypt option, please read [How To Install an SSL Certificate from a Commercial Certificate Authority](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority). Skip the **Install Certificate on Web Server** section.

Alternatively, you may also use a self-signed SSL certificate, which can be generated with this command:

    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ~/www.example.com.key -out ~/www.example.com.crt

## Steps to Reach Our Goal

Now that we have an outline of our production application setup, let’s create a general plan to achieve our goal.

The components that comprise the application are the most important, so we want those up and running early. However, because we are planning on using name-based address resolution of our private network connections, **we should set up our DNS first**.

Once our DNS is ready, in order to get things up and running, we will set up the servers that comprise the application. Because the database is required by the application, and the application is required by the load balancer, we will set up the components in this order:

1. Database Server
2. Application Servers
3. Load Balancer

Once we have gone through the steps of setting up our application, we will be able to devise a **recovery plan** for various scenarios. This plan will be useful in determining our backups strategy.

After we have our various recovery plans, we will want to support it by setting up **backups**. Following that, we can set up **monitoring** to make sure our servers and services are in an OK state. Lastly, we will set up **centralized logging** so we can to help us view our logs, troubleshoot issues, and identify trends.

## Conclusion

With our general plan ready, we are ready to implement our production application setup. Remember that this setup, while completely functional, is an example that you should be able to glean useful information from, and use what you learned to improve your own application setup.

Continue to the next tutorial to get started with setting up the application: [Building for Production: Web Applications — Deploying](building-for-production-web-applications-deploying).
