---
author: Justin Ellingwood
date: 2016-05-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-16-04
---

# How To Configure Bind as a Caching or Forwarding DNS Server on Ubuntu 16.04

## Introduction

DNS, or the Domain Name System, is often a difficult component to get right when learning how to configure websites and servers. While most people will probably choose to use the DNS servers provided by their hosting company or their domain registrar, there are some advantages to creating your own DNS servers.

In this guide, we will discuss how to install and configure the Bind9 DNS server as a caching or forwarding DNS server on Ubuntu 16.04 machines. These two configurations both have advantages when serving networks of machines.

## Prerequisites and Goals

To complete this guide, you will first need to be familiar with some common DNS terminology. Check out [this guide](an-introduction-to-dns-terminology-components-and-concepts) to learn about some of the concepts we will be implementing in this guide.

We will be demonstrating two separate configurations that accomplish similar goals: a caching and a forwarding DNS server.

To follow along, you will need to have access to two computers (at least one of which should be an Ubuntu 16.04 server). One will function as the client and the other will be configured as the DNS server. To get the server into a good preliminary state, follow the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04).

The details of our example configuration are:

| Role | IP Address |
| --- | --- |
| DNS Server | 192.0.2.2 |
| Client | 192.0.2.100 |

We will show you how to configure the client machine to use the DNS server for queries. We will show you how to configure the DNS server in two different configurations, depending on your needs.

### Caching DNS Server

The first configuration will be for a **caching** DNS server. This type of server is also known as a resolver because it handles recursive queries and generally can handle the grunt work of tracking down DNS data from other servers.

When a caching DNS server tracks down the answer to a client’s query, it returns the answer to the client. But it also stores the answer in its cache for the period of time allowed by the records’ TTL value. The cache can then be used as a source for subsequent requests in order to speed up the total round-trip time.

Almost all DNS servers that you might have in your network configuration will be caching DNS servers. These make up for the lack of adequate DNS resolver libraries implemented on most client machines. A caching DNS server is a good choice for many situations. If you do not wish to rely on your ISPs DNS or other publicly available DNS servers, making your own caching server is a good choice. If it is in close physical proximity to the client machines, it is also very likely to improve the DNS query times.

### Forwarding DNS Server

The second configuration that we will be demonstrating is a **forwarding** DNS server. A forwarding DNS server will look almost identical to a caching server from a client’s perspective, but the mechanisms and work load are quite different.

A forwarding DNS server offers the same advantage of maintaining a cache to improve DNS resolution times for clients. However, it actually does none of the recursive querying itself. Instead, it forwards all requests to an outside resolving server and then caches the results to use for later queries.

This lets the forwarding server respond from its cache, while not requiring it to do all of the work of recursive queries. This allows the server to only make single requests (the forwarded client request) instead of having to go through the entire recursion routine. This may be an advantage in environments where external bandwidth transfer is costly, where your caching servers might need to be changed often, or when you wish to forward local queries to one server and external queries to another server.

## Install Bind on the DNS Server

Regardless of which configuration choice you wish to use, the first step in implementing a Bind DNS server is to install the actual software.

The Bind software is available within Ubuntu’s default repositories, so we just need to update our local package index and install the software using `apt`. We will also include the documentation and some common utilities:

    sudo apt-get update
    sudo apt-get install bind9 bind9utils bind9-doc

Now that the Bind components are installed, we can begin to configure the server. The forwarding server will use the caching server configuration as a jumping off point, so regardless of your end goal, configure the server as a Caching server first.

## Configure as a Caching DNS Server

First, we will cover how to configure Bind to act as a caching DNS server. This configuration will force the server to recursively seek answers from other DNS servers when a client issues a query. This means that it is doing the work of querying each related DNS server in turn until it finds the entire response.

The Bind configuration files are kept by default in a directory at `/etc/bind`. Move into that directory now:

    cd /etc/bind

We are not going to be concerned with the majority of the files in this directory. The main configuration file is called `named.conf` (`named` and `bind` are two names for the same application). This file simply sources the `named.conf.options` file, the `named.conf.local` file, and the `named.conf.default-zones` file.

For a caching DNS server, we will only be modifying the `named.conf.options` file. Open this in your text editor with sudo privileges:

    sudo nano named.conf.options

With the comments stripped out for readability, the file looks like this:

/etc/bind/named.conf.options

    options {
            directory "/var/cache/bind";
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

To configure caching, the first step is to set up an access control list, or ACL.

As a DNS server that will be used to resolve recursive queries, we do not want the DNS server to be abused by malicious users. An attack called a **DNS amplification attack** is especially troublesome because it can cause your server to participate in distributed denial of service attacks.

A DNS amplification attack is one way that malicious users try to take down servers or sites on the internet. To do so, they try to find public DNS servers that will resolve recursive queries. They spoof the victim’s IP address and send a query that will return a large response to the DNS server. In doing so, the DNS server responds to a small request with a large payload directed at the victims server, effectively amplifying the available bandwidth of the attacker.

Hosting a public, recursive DNS server requires a great deal of special configuration and administration. To avoid the possibility of your server being used for malicious purposes, we will configure a list of IP addresses or network ranges that we trust.

Above the `options` block, we will create a new block called `acl`. Create a label for the ACL group that you are configuring. In this guide, we will call the group **goodclients**.

/etc/bind/named.conf.options

    acl goodclients {
    };
    
    options {
        . . .

Within this block, list the IP addresses or networks that should be allowed to use this DNS server. Since both our server and client are operating within the same /24 subnet in our example, we will restrict the example to this network. You should adjust this to include your own clients, and no outside parties. We will also add `localhost` and `localnets` which will attempt to do this automatically:

/etc/bind/named.conf.options

    acl goodclients {
        192.0.2.0/24;
        localhost;
        localnets;
    };
    
    options {
        . . .

Now that we have an ACL of clients that we want to resolve request for, we can configure those capabilities in the `options` block. Within this block, add the following lines:

/etc/bind/named.conf.options

    . . .
    
    options {
        directory "/var/cache/bind";
    
        recursion yes;
        allow-query { goodclients; };
        . . .

We explicitly turned recursion on, and then configured the `allow-query` parameter to use our ACL specification. We could have used a different parameter, like `allow-recursion` to reference our ACL group. If present and recursion is on, `allow-recursion` will dictate the list of clients that can use recursive services.

However, if `allow-recursion` is not set, then Bind falls back on the `allow-query-cache` list, then the `allow-query` list, and finally a default of `localnets` and `localhost` only. Since we are configuring a caching only server (it has no authoritative zones of its own and doesn’t forward requests), the `allow-query` list will always apply only to recursion. We are using it because it is the most general way of specifying the ACL.

When you are finished making these changes, save and close the file.

This is actually all that is required for a caching DNS server. If you decided that this is the server type you wish to use, feel free to skip ahead to learn how to check your configuration files, restart the service, and implement client configurations.

Otherwise, continue reading to learn how to set up a forwarding DNS server instead.

## Configure as a Forwarding DNS Server

If a forwarding DNS server is a better fit for your infrastructure, we can easily set that up instead.

We will start with the configuration that we left off in the caching server configuration. The `named.conf.options` file should look like this:

/etc/bind/named.conf.options

    acl goodclients {
            192.0.2.0/24;
            localhost;
            localnets;
    };
    
    options {
            directory "/var/cache/bind";
    
            recursion yes;
            allow-query { goodclients; };
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

We will be using the same ACL list to restrict our DNS server to a specific list of clients. However, we need to change the configuration so that the server no longer attempts to perform recursive queries itself.

To do this, we do _not_ change `recursion` to no. The forwarding server is still providing recursive services by answering queries for zones it is not authoritative for. Instead, we need to set up a list of caching servers to forward our requests to.

This will be done within the `options {}` block. First, we create a block inside called `forwarders` that contains the IP addresses of the recursive name servers that we want to forward requests to. In our guide, we will use Google’s public DNS servers (`8.8.8.8` and `8.8.4.4`):

/etc/bind/named.conf.options

    . . .
    
    options {
            directory "/var/cache/bind";
    
            recursion yes;
            allow-query { goodclients; };
    
            forwarders {
                    8.8.8.8;
                    8.8.4.4;
            };
            . . .

Afterward, we should set the `forward` directive to “only” since this server will forward all requests and should not attempt to resolve requests on its own.

The configuration file will look like this when you are finished:

/etc/bind/named.conf.options

    . . .
    
    options {
            directory "/var/cache/bind";
    
            recursion yes;
            allow-query { goodclients; };
    
            forwarders {
                    8.8.8.8;
                    8.8.4.4;
            };
            forward only;
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

One final change we should make is to the `dnssec` parameters. With the current configuration, depending on the configuration of forwarded DNS servers, you may see some errors that look like this in the logs:

    Jun 25 15:03:29 cache named[2512]: error (chase DS servers) resolving 'in-addr.arpa/DS/IN': 8.8.8.8#53
    Jun 25 15:03:29 cache named[2512]: error (no valid DS) resolving '111.111.111.111.in-addr.arpa/PTR/IN': 8.8.4.4#53

To avoid this, change the `dnssec-validation` setting to “yes” and explicitly enable dnssec:

/etc/bind/named.conf.options

    . . .
    
    forward only;
    
    dnssec-enable yes;
    dnssec-validation yes;
    
    auth-nxdomain no; # conform to RFC1035
    . . .

Save and close the file when you are finished. You should now have a forwarding DNS server in place. Continue to the next section to validate your configuration files and restart the daemon.

## Test your Configuration and Restart Bind

Now that you have your Bind server configured as either a caching DNS server or a forwarding DNS server, we are ready to implement our changes.

Before we take the plunge and restart the Bind server on our system, we should use Bind’s included tools to check the syntax of our configuration files.

We can do this easily by typing:

    sudo named-checkconf

If there are no syntax errors in your configuration, the shell prompt will return immediately without displaying any output.

If you have syntax errors in your configuration files, you will be alerted to the error and line number where it occurs. If this happens, go back and check your files for errors.

When you have verified that your configuration files do not have any syntax errors, restart the Bind daemon to implement your changes:

    sudo systemctl restart bind9

If you followed the initial server setup guide, the UFW firewall is enabled on your server. We need to allow DNS traffic to our server in order to respond to client requests.

Enable an exception to the firewall policy for Bind by typing:

    sudo ufw allow Bind9

Afterwards, keep an eye on the server logs while you set up your client machine to make sure that everything goes smoothly. Leave this running on the server:

    sudo journalctl -u bind9 -f

Now, open a new terminal window to configure your client machines.

## Configure the Client Machine

Now that you have your server up and running, you can configure your client machine to use this DNS server for queries.

Log into your client machine. Make sure that the client you are using was specified in the ACL group you set for your DNS server. Otherwise the DNS server will refuse to serve requests for the client.

We need to edit the `/etc/resolv.conf` file to point our server to the name server. Changes made here will only last until reboot, which is great for testing. If we are satisfied with the results of our tests, we can make these changes permanent.

Open the file with sudo privileges in your text editor:

    sudo nano /etc/resolv.conf

The file will list the DNS servers to use to resolve queries by setting the `nameserver` directives. Comment out all of the current entries and add a `nameserver` line that points to your DNS server:

/etc/resolv.conf

    nameserver 192.0.2.2
    # nameserver 8.8.4.4
    # nameserver 8.8.8.8
    # nameserver 209.244.0.3

Save and close the file.

Now, you can test to make sure queries can resolve correctly by using some common tools.

You can use `ping` to test that connections can be made to domains:

    ping -c 1 google.com

    OutputPING google.com (173.194.33.1) 56(84) bytes of data.
    64 bytes from sea09s01-in-f1.1e100.net (173.194.33.1): icmp_seq=1 ttl=55 time=63.8 ms
    
    --- google.com ping statistics ---
    1 packets transmitted, 1 received, 0% packet loss, time 0ms
    rtt min/avg/max/mdev = 63.807/63.807/63.807/0.000 ms

This means that our client can connect with `google.com` using our DNS server.

We can get more detailed information by using DNS specific tools like `dig`. Try a different domain this time:

    dig linuxfoundation.org

    Output; <<>> DiG 9.9.5-3-Ubuntu <<>> linuxfoundation.org
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35417
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
    
    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags:; udp: 4096
    ;; QUESTION SECTION:
    ;linuxfoundation.org. IN A
    
    ;; ANSWER SECTION:
    linuxfoundation.org. 6017 IN A 140.211.169.4
    
    ;; Query time: 36 msec
    ;; SERVER: 192.0.2.2#53(192.0.2.2)
    ;; WHEN: Wed Jun 25 15:45:57 EDT 2014
    ;; MSG SIZE rcvd: 64

You can see that the query took 36 milliseconds. If we make the request again, the server should pull the data from its cache, decreasing the response time:

    dig linuxfoundation.org

    Output; <<>> DiG 9.9.5-3-Ubuntu <<>> linuxfoundation.org
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 18275
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
    
    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags:; udp: 4096
    ;; QUESTION SECTION:
    ;linuxfoundation.org. IN A
    
    ;; ANSWER SECTION:
    linuxfoundation.org. 6012 IN A 140.211.169.4
    
    ;; Query time: 1 msec
    ;; SERVER: 192.0.2.2#53(192.0.2.2)
    ;; WHEN: Wed Jun 25 15:46:02 EDT 2014
    ;; MSG SIZE rcvd: 64

As you can see, the cached response is significantly faster.

We can also test the reverse lookup by using the IP address that we found (`140.211.169.4` in our case) with dig’s `-x` option:

    dig -x 140.211.169.4

    Output; <<>> DiG 9.9.5-3-Ubuntu <<>> -x 140.211.169.4
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 61516
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
    
    ;; OPT PSEUDOSECTION:
    ; EDNS: version: 0, flags:; udp: 4096
    ;; QUESTION SECTION:
    ;4.169.211.140.in-addr.arpa. IN PTR
    
    ;; ANSWER SECTION:
    4.169.211.140.in-addr.arpa. 3402 IN CNAME 4.0-63.169.211.140.in-addr.arpa.
    4.0-63.169.211.140.in-addr.arpa. 998 IN PTR load1a.linux-foundation.org.
    
    ;; Query time: 31 msec
    ;; SERVER: 192.0.2.2#53(192.0.2.2)
    ;; WHEN: Wed Jun 25 15:51:23 EDT 2014
    ;; MSG SIZE rcvd: 117

As you can see, the reverse lookup also succeeds.

Back on your DNS server, you should see if any errors have been recorded during your tests. One common error that may show up looks like this:

    Output from sudo journalctl -u bind9 -f. . .
    Jun 25 13:16:22 cache named[2004]: error (network unreachable) resolving 'ns4.apnic.net/A/IN': 2001:dc0:4001:1:0:1836:0:140#53
    Jun 25 13:16:22 cache named[2004]: error (network unreachable) resolving 'ns4.apnic.com/A/IN': 2001:503:a83e::2:30#53
    Jun 25 13:16:23 cache named[2004]: error (network unreachable) resolving 'sns-pb.isc.org/AAAA/IN': 2001:500:f::1#53
    Jun 25 13:16:23 cache named[2004]: error (network unreachable) resolving 'ns3.nic.fr/A/IN': 2a00:d78:0:102:193:176:144:22#53

These indicate that the server is trying to resolve IPv6 information but that the server is not configured for IPv6. You can fix this issue by telling Bind to only use IPv4.

To do this, we can modify the systemd unit file that starts Bind9:

    sudo systemctl edit --full bind9

Inside the file that appears, add `-4` to the end of the `ExecStart` line to restrict the server to IPv4 requests:

Editing bind9 systemd unit file

    [Unit]
    Description=BIND Domain Name Server
    Documentation=man:named(8)
    After=network.target
    
    [Service]
    ExecStart=/usr/sbin/named -f -u bind -4
    ExecReload=/usr/sbin/rndc reload
    ExecStop=/usr/sbin/rndc stop
    
    [Install]
    WantedBy=multi-user.target

Save and close the file when you are finished.

Reload the systemd daemon to read the changed unit file into the init system:

    sudo systemctl daemon-reload

Restart the Bind9 service to implement the changes:

    sudo systemctl restart bind9

You should not see these errors in the logs again.

### Making Client DNS Settings Permanent

As mentioned before, the `/etc/resolv.conf` settings that point the client machine to our DNS server will not survive a reboot. To make the changes last, we need to modify the files that are used to generate this file.

If the client machine is running Debian or Ubuntu, open the `/etc/network/interfaces` file with sudo privileges:

    sudo nano /etc/network/interfaces

Look for the `dns-nameservers` parameter. You can remove the existing entries and replace them with your DNS server or just add your DNS server as one of the options:

/etc/network/interfaces

    . . .
    
    iface eth0 inet static
            address 192.168.2.100
            netmask 255.255.255.0
            gateway 192.168.2.1
            dns-nameservers 192.0.2.2
    
    . . .

Save and close the file when you are finished. Next time you boot up, your settings will be applied.

If the client is running CentOS or Fedora, you need to open the `/etc/sysconfig/network/network-scripts/ifcfg-eth0` file instead:

    sudo nano /etc/sysconfig/network-scripts/ifcfg-eth0

Inside, look for the lines that begin with `DNS`. Change `DNS1` to your DNS server. If you don’t want to use the other DNS servers as a fallback, remove the other entries:

/etc/sysconfig/network-scripts/ifcfg-eth0

    . . .
    DNS1=192.0.2.2
    . . .

Save and close the file when you are finished. Your client should use those settings at next boot.

## Conclusion

You should now have either a caching or forwarding DNS server configured to serve your clients. This can be a great way to speed up DNS queries for the machines you are managing.
