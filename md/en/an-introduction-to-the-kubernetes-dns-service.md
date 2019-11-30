---
author: Brian Boucheron
date: 2018-10-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-the-kubernetes-dns-service
---

# An Introduction to the Kubernetes DNS Service

## Introduction

The Domain Name System (DNS) is a system for associating various types of information – such as IP addresses – with easy-to-remember names. By default most Kubernetes clusters automatically configure an internal DNS service to provide a lightweight mechanism for service discovery. Built-in service discovery makes it easier for applications to find and communicate with each other on Kubernetes clusters, even when pods and services are being created, deleted, and shifted between nodes.

The implementation details of the Kubernetes DNS service have changed in recent versions of Kubernetes. In this article we will take a look at both the **kube-dns** and **CoreDNS** versions of the Kubernetes DNS service. We will review how they operate and the DNS records that Kubernetes generates.

To gain a more thorough understanding of DNS before you begin, please read [_An Introduction to DNS Terminology, Components, and Concepts_](an-introduction-to-dns-terminology-components-and-concepts). For any Kubernetes topics you may be unfamiliar with, you could read [_An Introduction to Kubernetes_](an-introduction-to-kubernetes).

## What Does the Kubernetes DNS Service Provide?

Before Kubernetes version 1.11, the Kubernetes DNS service was based on **kube-dns**. Version 1.11 introduced **CoreDNS** to address some security and stability concerns with kube-dns.

Regardless of the software handling the actual DNS records, both implementations work in a similar manner:

- A service named `kube-dns` and one or more pods are created.
- The `kube-dns` service listens for **service** and **endpoint** events from the Kubernetes API and updates its DNS records as needed. These events are triggered when you create, update or delete Kubernetes services and their associated pods.
- kubelet sets each new pod’s `/etc/resolv.conf` `nameserver` option to the cluster IP of the `kube-dns` service, with appropriate `search` options to allow for shorter hostnames to be used:

- Applications running in containers can then resolve hostnames such as `example-service.namespace` into the correct cluster IP addresses.

### Example Kubernetes DNS Records

The full DNS `A` record of a Kubernetes service will look like the following example:

    service.namespace.svc.cluster.local

A pod would have a record in this format, reflecting the actual IP address of the pod:

    10.32.0.125.namespace.pod.cluster.local

Additionally, `SRV` records are created for a Kubernetes service’s named ports:

    _port-name._protocol.service.namespace.svc.cluster.local

The result of all this is a built-in, DNS-based service discovery mechanism, where your application or microservice can target a simple and consistent hostname to access other services or pods on the cluster.

### Search Domains and Resolving Shorter Hostnames

Because of the search domain suffixes listed in the `resolv.conf` file, you often won’t need to use the full hostname to contact another service. If you’re addressing a service in the same namespace, you can use just the service name to contact it:

    other-service

If the service is in a different namespace, add it to the query:

    other-service.other-namespace

If you’re targeting a pod, you’ll need to use at least the following:

    pod-ip.other-namespace.pod

As we saw in the default `resolv.conf` file, only `.svc` suffixes are automatically completed, so make sure you specify everything up to `.pod`.

Now that we know the practical uses of the Kubernetes DNS service, let’s run through some details on the two different implementations.

## Kubernetes DNS Implementation Details

As noted in the previous section, Kubernetes version 1.11 introduced new software to handle the `kube-dns` service. The motivation for the change was to increase the performance and security of the service. Let’s take a look at the original `kube-dns` implementation first.

### kube-dns

The `kube-dns` service prior to Kubernetes 1.11 is made up of three containers running in a `kube-dns` pod in the `kube-system` namespace. The three containers are:

- **kube-dns:** a container that runs [SkyDNS](https://github.com/skynetservices/skydns), which performs DNS query resolution
- **dnsmasq:** a popular lightweight DNS resolver and cache that caches the responses from SkyDNS
- **sidecar:** a sidecar container that handles metrics reporting and responds to health checks for the service

Security vulnerabilities in Dnsmasq, and scaling performance issues with SkyDNS led to the creation of a replacement system, CoreDNS.

### CoreDNS

As of Kubernetes 1.11 a new Kubernetes DNS service, **CoreDNS** has been promoted to General Availability. This means that it’s ready for production use and will be the default cluster DNS service for many installation tools and managed Kubernetes providers.

CoreDNS is a single process, written in Go, that covers all of the functionality of the previous system. A single container resolves and caches DNS queries, responds to health checks, and provides metrics.

In addition to addressing performance- and security-related issues, CoreDNS fixes some other minor bugs and adds some new features:

- Some issues with incompatibilities between using stubDomains and external services have been fixed
- CoreDNS can enhance DNS-based round-robin load balancing by randomizing the order in which it returns certain records
- A feature called `autopath` can improve DNS response times when resolving external hostnames, by being smarter about iterating through each of the search domain suffixes listed in `resolv.conf`
- With kube-dns `10.32.0.125.namespace.pod.cluster.local` would always resolve to `10.32.0.125`, even if the pod doesn’t actually exist. CoreDNS has a “pods verified” mode that will only resolve successfully if a pod exists with the right IP and in the right namespace.

For more information on CoreDNS and how it differs from kube-dns, you can read [the Kubernetes CoreDNS GA announcement](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/).

## Additional Configuration Options

Kubernetes operators often want to customize how their pods and containers resolve certain custom domains, or need to adjust the upstream nameservers or search domain suffixes configured in `resolv.conf`. You can do this with the `dnsConfig` option of your pod’s spec:

example\_pod.yaml

    apiVersion: v1
    kind: Pod
    metadata:
      namespace: example
      name: custom-dns
    spec:
      containers:
        - name: example
          image: nginx
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 203.0.113.44
        searches:
          - custom.dns.local

Updating this config will rewrite a pod’s `resolv.conf` to enable the changes. The configuration maps directly to the standard `resolv.conf` options, so the above config would create a file with `nameserver 203.0.113.44` and `search custom.dns.local` lines.

## Conclusion

In this article we covered the basics of what the Kubernetes DNS service provides to developers, showed some example DNS records for services and pods, discussed how the system is implemented on different Kubernetes versions, and highlighted some additional configuration options available to customize how your pods resolve DNS queries.

For more information on the Kubernetes DNS service, please refer to [the official Kubernetes _DNS for Services and Pods_ documentation](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).
