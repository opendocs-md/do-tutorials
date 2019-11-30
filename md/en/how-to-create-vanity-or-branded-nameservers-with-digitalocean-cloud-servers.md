---
author: Pablo Carranza
date: 2013-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-vanity-or-branded-nameservers-with-digitalocean-cloud-servers
---

# How To Create Vanity or Branded Nameservers with DigitalOcean Cloud Servers

## Introduction

Of particular interest to hosting providers or resellers, having branded or vanity nameservers provides a more professional look to clients. It eliminates the need of asking your clients to point their domains to another company's nameservers. This tutorial will outline two approaches to creating custom nameservers: (i) Vanity and (ii) Branded.

## Types

**Vanity nameservers** allow you to use your own domain name, without having to setup complicated zone files; you can do this using DigitalOcean's nameservers and DNS Manager. This is accomplished by mapping your custom nameservers to DigitalOcean's IPs.

**Branded Nameservers** require a little more configuration, but allow you to exert complete control over DNS for your domain. The added control, however, carries with it the burden of having to self-manage your DNS. You'll need to deploy at least two VPS, with specialized software such as BIND, PowerDNS or NSD (for "name server daemon"). Wikipedia publishes a nice [comparison of DNS server software](http://en.wikipedia.org/wiki/Comparison_of_DNS_server_software).

## Naming
 You can use any naming scheme you want. If you're unsure, the most common schemes are `ns1.yourdomain.com` or `a.ns.yourdomain.com`. 
## Prerequisites

### Ingredients for Both Vanity & Branded Nameservers:

1. Registered domain name from an established registrar, e.g. GoDaddy; NameCheap; 1&1; NetworkSolutions; Register.com etc. (at this time, DigitalOcean does not offer domain registration services.)

2. [Glue Records](http://en.wikipedia.org/wiki/Glue_records#Circular_dependencies_and_glue_records): Ascertain your domain registrar's procedure for creating glue records. Different registrar's refer to glue records by different names, such as GoDaddy whom refers to them as host names. Other providers may refer to the process as "registering a nameserver" or "creating a host record." Glue records tell the rest of the world where to find your nameservers and are needed to prevent circular references. Circular references exist where the nameservers for a domain can't be resolved without resolving the domain they're responsible for. **If you are not able to determine how to create Glue Records at your particular domain registrar (that is, how to "register a nameserver or host name"), then you need to contact your registrar directly and let them know that you need to register a nameserver.**

### For Vanity Nameservers Only

DigitalOcean's current IP addresses for its nameservers (which can be obtained by clicking on the respective hyperlinks, below; or, via nslookup; dig; or ping commands):

[ns1.digitalocean.com](http://reports.internic.net/cgi/whois?whois_nic=ns1.digitalocean.com&type=nameserver)

[ns2.digitalocean.com](http://reports.internic.net/cgi/whois?whois_nic=ns2.digitalocean.com&type=nameserver)

[ns3.digitalocean.com](http://reports.internic.net/cgi/whois?whois_nic=ns3.digitalocean.com&type=nameserver)

### Additional Requirements if You'd Like to Maximize Control Over Your Domain's DNS, with Branded Nameservers:

Create or identify at least two VPS that you control that will act as Primary and Secondary Nameservers.

NOTE: It's technically possible to have only one VPS act as both the Primary and Secondary Nameserver. This approach, however, is not recommended because it sacrifices the safety that redundancy provides (i.e., fault tolerance). Keep in mind, however, that there's no hard limit of only two nameservers for your domain. You're only limited by the number of nameservers that your domain registrar allows you to register.

Deploy a DNS Server on your Primary and Secondary Nameservers. _See_[How to Setup DNS Slave Auto Configuration Using Virtualmin/Webmin on Ubuntu](https://www.digitalocean.com/community/articles/how-to-setup-dns-slave-auto-configuration-using-virtualmin-webmin-on-ubuntu); [How to Install the BIND DNS Server on CentOS 6](https://www.digitalocean.com/community/articles/how-to-install-the-bind-dns-server-on-centos-6); or [How To Install PowerDNS on CentOS 6.3 x64](https://www.digitalocean.com/community/articles/how-to-install-powerdns-on-centos-6-3-x64)

### The Quick & Easy Recipe: Vanity Nameservers:

1. First, login to your [DigitalOcean Control Panel](https://www.digitalocean.com/community/articles/the-digitalocean-control-panel) and add your domain name to the [DigitalOcean DNS Manager](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean).

2. Then, create A Records for your vanity nameservers and point them to DigitalOcean's IPs for ns1.digitalocean.com; ns2.digitalocean.com; ns3.digitalocean.com.

To accomplish this, create a new host A-Record with **ns1.yourdomain.com.** (do **NOT** forget to end the hostname with a period) in the hostname field. The IP address to use for ns1.yourdomain.com. is the IP address you discovered for ns1.digitalocean.com (above). Repeat these steps for **ns2.yourdomain.com.** and **ns3.yourdomain.com.**

For example:

**(Do not forget the trailing dots)**

    A ns1.yourdomain.com **.** [IP address for ns1.digitalocean.com]

    A ns2.yourdomain.com **.** [IP address for ns2.digitalocean.com]

    A ns3.yourdomain.com **.** [IP address for ns3.digitalocean.com]

3. Next, you need to replace DigitalOcean's NS Records with each of your vanity nameservers in the [DigitalOcean DNS Manager](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean).

**(Do not forget the trailing dots)**

    NS ns1.yourdomain.com **.**

    NS ns2.yourdomain.com **.**

    NS ns3.yourdomain.com **.**

4. This next step will vary, depending on your domain name's registrar: Login to your domain name registrar's control panel and register the IPs of your nameservers by creating Glue Records. In another words, associate (or map) DigitalOcean's nameserver IPs with your vanity nameservers' hostnames.

With GoDaddy, for example, simply login to your Domain Name Control Panel and look for the area where you can list Host Names. There, click on Manage =\> Add Hostname and enter NS1 for the Hostname and ns1.digitalocean.com's IP address; click Add Hostname again and enter NS2 for the Hostname and ns2.digitalocean.com's IP Address. Click Add Hostname yet a third time and add NS3 for the Hostname and ns3.digitalocean.com's IP Address.

5. Almost done! Skip down to the DNS Testing section.

### Recipe for Maximum Control, with Branded Nameservers:

The simplest way to configure DNS is to have someone else do it. For that reason, you should consider using DigitalOcean's [DNS Manager](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean).

If you really want to manage your domain's DNS yourself, however, you next need to deploy a DNS server such as BIND. A complete zone-file configuration is beyond the scope of this tutorial. However, you need to ensure that you apply the same principals described above:

1. Create both A & NS Records for ns1.yourdomain.com. and ns2.yourdomain.com. (with BIND, especially, do not forget the trailing periods).

2. Ultimately, your zone file will contain the following entries:

    ns1.yourdomain.com. IN A 1.2.3.4

    ns2.yourdomain.com. IN A 1.2.3.5

    yourdomain.com. IN NS ns1.yourdomain.com.

    yourdomain.com. IN NS ns2.yourdomain.com.

3. Remember, the IP addresses for your ns1 and ns2 A Records (and for your Glue Records) come from you--in that you have to set up **at least** two VPS to run your name servers.

4. Login to your domain name registrar's control panel and create Glue Records for as many nameservers you wish to deploy. Just make sure that you are using the IP addresses of servers under your control (and not the addresses of DigitalOcean's nameservers).

## DNS Testing

To make sure you configured everything correctly, you can run the [Check Domain Configuration](http://www.webdnstools.com/dnstools/domain_check) tool. Keep in mind, however, that, depending on your registrar, nameserver changes can take up to 72 hours to properly propagate throughout the Internet.

Article Submitted by: [Pablo Carranza](http://vdevices.com)
