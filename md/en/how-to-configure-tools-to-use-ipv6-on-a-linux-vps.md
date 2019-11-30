---
author: Justin Ellingwood
date: 2014-04-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-tools-to-use-ipv6-on-a-linux-vps
---

# How To Configure Tools to Use IPv6 on a Linux VPS

## Introduction

IPv6 is the most recent version of the IP protocol that the entire internet relies on to connect to other locations (IP protocol is a bit redundant because IP stands for internet protocol, but we will use it because it is easy). While IPv4 is still in use in many areas of the world, the IPv4 address space is being consumed at a rapid rate and it is not large enough to sustain the rapid deployment of internet-ready devices.

IPv6 looks to solve these problems. As well as making general improvements on the protocol, the most obvious benefit of utilizing IPv6 addresses is that it has a _much_ larger address space. While IPv4 allowed for 2^32 addresses (with some of those reserved for special purposes), the IPv6 address space allows for 2^128 addresses, which is an incredible increase.

While IPv6 opens up a lot of opportunities and solves many long-standing issues, it does require a bit of an adjustment to some of your routine network configurations if you are used to using IPv4 exclusively. In this guide, we’ll talk about some of the IPv6 counterparts to some popular IPv4 tools and utilities and discuss how to configure some popular services to utilize IPv6.

## Trivial Network Diagnostics with IPv6

Some of the simplest utilities used to diagnose network issues were created with IPv4 in mind. To address this, we can use their IPv6 cousins when we wish to deal with IPv6 traffic.

First of all, to see your currently configured IPv6 addresses for your server, you can use the `iproute2` tools to show you the current configured addresses:

    ip -6 addr show

* * *

    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 
        inet6 ::1/128 scope host 
           valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qlen 1000
        inet6 2400:6180:0:d0::41f/64 scope global 
           valid_lft forever preferred_lft forever
        inet6 fe80::601:15ff:fe43:b201/64 scope link 
           valid_lft forever preferred_lft forever
    3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qlen 1000
        inet6 fe80::601:15ff:fe43:b202/64 scope link 
           valid_lft forever preferred_lft forever

To print out the IPv6 routing table, you can use `netstat` by typing something like this:

    netstat -A inet6 -rn

* * *

    Kernel IPv6 routing table
    Destination Next Hop Flag Met Ref Use If
    2400:6180:0:d0::/64 :: U 256 0 1 eth0
    fe80::/64 :: U 256 0 0 eth1
    fe80::/64 :: U 256 0 0 eth0
    ::/0 2400:6180:0:d0::1 UG 1024 0 0 eth0
    ::/0 :: !n -1 1 90 lo
    ::1/128 :: Un 0 1 20 lo
    2400:6180:0:d0::41f/128 :: Un 0 1 86 lo
    fe80::601:15ff:fe43:b201/128 :: Un 0 1 75 lo
    fe80::601:15ff:fe43:b202/128 :: Un 0 1 0 lo
    ff00::/8 :: U 256 0 0 eth1
    ff00::/8 :: U 256 0 0 eth0
    ::/0 :: !n -1 1 90 lo

If you prefer the iproute2 tools, you can get similar information by typing:

    ip -6 route show

* * *

    2400:6180:0:d0::/64 dev eth0 proto kernel metric 256 
    fe80::/64 dev eth1 proto kernel metric 256 
    fe80::/64 dev eth0 proto kernel metric 256 
    default via 2400:6180:0:d0::1 dev eth0 metric 1024 

Now that you know about how to get some of your own IPv6 information, let’s learn a bit about how to use some tools that work with IPv6.

The ubiquitous `ping` command is actually IPv4-specific. The IPv6 version of the command, which works exactly the same but for IPv6 addresses, is named unsurprisingly `ping6`. This will ping the local loopback interface:

    ping6 -c 3 ::1

* * *

    PING ::1(::1) 56 data bytes
    64 bytes from ::1: icmp_seq=1 ttl=64 time=0.021 ms
    64 bytes from ::1: icmp_seq=2 ttl=64 time=0.028 ms
    64 bytes from ::1: icmp_seq=3 ttl=64 time=0.022 ms
    
    --- ::1 ping statistics ---
    3 packets transmitted, 3 received, 0% packet loss, time 1998ms
    rtt min/avg/max/mdev = 0.021/0.023/0.028/0.006 ms

As you can see, this works exactly as expected, the only difference being the protocol version being used for the addressing.

Another tool that you might rely on is `traceroute`. There is also an IPv6 equivalent available:

    traceroute6 google.com

* * *

    traceroute to google.com (2404:6800:4003:803::1006) from 2400:6180:0:d0::41f, 30 hops max, 24 byte packets
     1 2400:6180:0:d0:ffff:ffff:ffff:fff1 (2400:6180:0:d0:ffff:ffff:ffff:fff1) 0.993 ms 1.034 ms 0.791 ms
     2 2400:6180::501 (2400:6180::501) 0.613 ms 0.636 ms 0.557 ms
     3 2400:6180::302 (2400:6180::302) 0.604 ms 0.506 ms 0.561 ms
     4 10gigabitethernet1-1.core1.sin1.he.net (2001:de8:4::6939:1) 6.21 ms 10.869 ms 1.249 ms
     5 15169.sgw.equinix.com (2001:de8:4::1:5169:1) 1.522 ms 1.205 ms 1.165 ms
     6 2001:4860::1:0:337f (2001:4860::1:0:337f) 2.131 ms 2.164 ms 2.109 ms
     7 2001:4860:0:1::523 (2001:4860:0:1::523) 2.266 ms 2.18 ms 2.02 ms
     8 2404:6800:8000:1c::8 (2404:6800:8000:1c::8) 1.741 ms 1.846 ms 1.895 ms

You may be familiar with is the `tracepath` command. This follows the example of the other commands for the IPv6 version:

    tracepath6 ::1

* * *

     1?: [LOCALHOST] 0.045ms pmtu 65536
     1: ip6-localhost 0.189ms reached
     1: ip6-localhost 0.110ms reached
         Resume: pmtu 65536 hops 1 back 64

If you need to monitor traffic as it comes into your machine, the `tcpdump` program is often used. We can get this utility to show only our IPv6 traffic by filtering it with the expression `ip6 or proto ipv6` after our options.

For example, we can measure rapidly flowing IPv6 traffic easily by telling the tool to only capture the information we’re interested in. We can use this command as taken from [here](http://www.tldp.org/HOWTO/Linux+IPv6-HOWTO/x811.html) to only gather a summary of the information to avoid delaying output:

    tcpdump -t -n -i eth0 -s 512 -vv ip6 or proto ipv6

## Checking IPv6 DNS Information

You can easily check the DNS information for your domains by using the typical tools. The main difference is that you will probably be asking for `AAAA` records, which are used for IPv6 addresses instead of `A` records, which are only used for IPv4 mapping.

To retrieve an IPv6 address record for a domain, you can simply request the `AAAA` record. With the `host` command, you can do that like this:

    host -t AAAA google.com

* * *

    google.com has IPv6 address 2404:6800:4003:803::1004

If you prefer to use `dig`, you can get similar results by using this syntax:

    dig google.com AAAA

* * *

    ; <<>> DiG 9.8.1-P1 <<>> google.com AAAA
    ;; global options: +cmd
    ;; Got answer:
    ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14826
    ;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0
    
    ;; QUESTION SECTION:
    ;google.com. IN AAAA
    
    ;; ANSWER SECTION:
    google.com. 299 IN AAAA 2404:6800:4003:803::1006
    
    ;; Query time: 5 msec
    ;; SERVER: 8.8.4.4#53(8.8.4.4)
    ;; WHEN: Tue Apr 1 13:59:23 2014
    ;; MSG SIZE rcvd: 56

As you can see, checking that your DNS is resolving correctly for your domains is just as easy when you are working with IPv6 addresses.

## Network Services with IPv6

Most of your common network services should have the ability to handle IPv6 traffic. Sometimes, they need special flags or syntax, and other times, they provide an alternative implementation specifically for IPv6.

### SSH Configuration

For SSH, the daemon can be configured to listen to an IPv6 address. This is controlled in the configuration file that you can open with:

    sudo nano /etc/ssh/sshd_config

The `ListenAddress` specifies which address the SSH daemon will bind to. For IPv4 addresses, this looks like this:

    ListenAddress 111.111.111.111:22

This listens to the IPv4 address `111.111.111.111` on port 22. For an IPv6 address, you can do the same by placing the address in square brackets:

    ListenAddress [1341:8954:a389:33:ba33::1]:22

This tells the SSH daemon to listen to the `1341:8954:a389:33:ba33::1` address on port 22. You can tell it to listen to _all_ available IPv6 addresses by typing:

    ListenAddress ::

Remember to reload the daemon after you’ve made changes:

    sudo service ssh restart

On the client side, if the daemon that you are connecting to is configured to listen using IPv4 _and_ IPv6, you can force the client to use IPv6 only by using the `-6` flag, like this:

    ssh -6 username@host.com

### Web Server Configuration

Similar to the SSH daemon, web servers also must be configured to listen on IPv6 addresses.

In Apache, you can configure the server to respond to requests on a certain IPv6 address using this syntax:

    Listen [1341:8954:a389:33:ba33::1]:80

This tells the server to listen to this specific address on port 80. We can combine this with an IPv4 address to allow more flexibility like this:

    Listen 111.111.111.111:80
    Listen [1341:8954:a389:33:ba33::1]:80

In practice, if you want to listen to connections on all interfaces in all protocols on port 80, you could just use:

    Listen 80

On the virtualhost level, you can also specify an IPv6 address. Here, you can see that it’s possible to configure a virtualhost to match for both an IPv4 address and an IPv6 address:

    <VirtualHost 111.111.111.111:80, [1341:8954:a389:33:ba33::1]:80>
        . . .
    </VirtualHost>

Remember to restart the service to make the changes:

    sudo service apache2 restart

If you prefer to use Nginx as your web server, we can implement similar configurations. For the listen directive, we can use this for IPv6 traffic:

    listen [1341:8954:a389:33:ba33::1]:80;

In Linux, this actually enables IPv4 traffic on port 80 as well because it automatically maps IPv4 requests to the IPv6 address. This actually prevents you from specifying an IPv6 address and IPv4 address separately like this:

    listen [1341:8954:a389:33:ba33::1]:80;
    listen 111.111.111.111:80;

This will result in an error saying that the port is already bound to another service. If you want to use separate directives like this, you must turn off this functionality using `sysctl` like this:

    sysctl -w net.ipv6.bindv6only=1

You can make sure this is automatically applied at boot by adding it to `/etc/sysctl.conf`:

    sudo nano /etc/sysctl.conf

* * *

    . . .
    net.ipv6.bindv6only=1

Afterwards, you can use use a similar configuration to the one that was failing before by adding the `ipv6only=on` flag to the IPv6 listening directive:

    listen [1341:8954:a389:33:ba33::1]:80 ipv6only=on;
    listen 111.111.111.111:80;

Again, restart Nginx to make the changes:

    sudo service nginx restart

### Firewall Configuration

If you are used to configuring your firewall rules using netfilter configuration front-ends like `iptables`, you’ll be happy to know that there is an equivalent tool called `ip6tables`.

We have a guide here on [how to configure iptables for Ubuntu](https://www.digitalocean.com/community/articles/how-to-set-up-a-firewall-using-ip-tables-on-ubuntu-12-04) here.

For the IPv6 variant, you can simply replace the command with `ip6tables` to manage the IPv6 packet filter rules. For instance, to list the IPv6 rules, you can type:

    sudo ip6tables -L

* * *

    Chain INPUT (policy ACCEPT)
    target prot opt source destination         
    
    Chain FORWARD (policy ACCEPT)
    target prot opt source destination         
    
    Chain OUTPUT (policy ACCEPT)
    target prot opt source destination

If you are using the `ufw` tool, then congratulations, you’re already done! The `ufw` tool configures both stacks at the same time unless otherwise specified. You may have to add rules for your specific IPv6 addresses, but you will not have to use a different tool.

You can learn more about [how to use ufw](https://www.digitalocean.com/community/articles/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server) here.

### TCP Wrappers Configuration

If you use TCP wrappers to control access to your server through the `/etc/hosts.allow` and `/etc/hosts.deny` files, you can simply use IPv6 syntax to match certain source rules.

For example, you could allow only an IPv4 and an IPv6 address to connect through SSH by typing editing the `/etc/hosts.allow` file and adding this:

    sudo nano /etc/hosts.allow

* * *

    . . .
    sshd: 111.111.0.0/255.255.254.0, [1341:8954:a389:33::]/64

As you can see, it is very easy to adapt your current TCP wrapper rules to apply to IPv6 addresses. You can learn more about [how to format IP addresses and subnets](https://www.digitalocean.com/community/articles/understanding-ip-addresses-subnets-and-cidr-notation-for-networking) here.

## Conclusion

Hopefully, by now you realize that transitioning to IPv6 or taking advantage of IPv6 in addition to IPv4 is a fairly straight forward process.

You will have to specifically investigate any network services that you use to find out if there are any additional configuration changes that are needed to correctly utilize your IPv6 resources. However, you should now feel more comfortable working with IPv6 with your most basic utilities and services.

By Justin Ellingwood
