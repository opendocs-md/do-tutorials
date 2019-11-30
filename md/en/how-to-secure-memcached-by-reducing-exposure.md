---
author: DigitalOcean
date: 2018-03-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-memcached-by-reducing-exposure
---

# How To Secure Memcached by Reducing Exposure

## Introduction

On February 27, 2018, [Cloudflare posted a story about a severe increase in the volume of memcached amplification attacks](https://blog.cloudflare.com/memcrashed-major-amplification-attacks-from-port-11211/). Memcached, a popular object caching system, is frequently used to reduce response times and the load on components throughout a deployment. The amplification attack targets Memcached deployments exposed on the public network using UDP.

In order to mitigate the attack, the best option is to bind Memcached to a local interface, disable UDP, and protect your server with conventional network security best practices. In this guide, we will cover how to do this, as well as how to expose the service to selective external clients.

**Note** : Because of the potential impact of this amplification attack on network stability, DigitalOcean has disabled both UDP and TCP traffic on the public interface to port 11211 as of March 1, 2018. This affects access to Droplets from outside of the data center, but connections from within the data center are still allowed.

For additional security, if you need Memcached access between Droplets within the same data center, binding to your Droplet’s private network interface and using firewall rules to limit the source addresses allowed will help prevent unauthorized requests.

## Securing Memcached on Ubuntu and Debian Servers

For Memcached services running on Ubuntu or Debian servers, you can adjust the service parameters by editing the `/etc/memcached.conf` file with `nano`, for instance:

    sudo nano /etc/memcached.conf

By default, Ubuntu and Debian bind Memcached to the local interface `127.0.0.1`. Installations bound to `127.0.0.1` are not vulnerable to amplification attacks from the network. Check that the `-l` option is set to this address to confirm the behavior:

/etc/memcached.conf

    . . .
    -l 127.0.0.1
    . . .

In case the listening address is ever modified in the future to be more open, it is also a good idea to disable UDP, which is much more likely to be exploited by this particular attack. To disable UDP (TCP will still work as expected), add the following option to the bottom or your file:

/etc/memcached.conf

    . . .
    -U 0

When you are finished, save and close the file.

Restart your Memcached service to apply your changes:

    sudo service memcached restart

Verify that Memcached is currently bound to the local interface and listening only for TCP by typing:

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    . . .
    tcp 0 0 127.0.0.1:11211 0.0.0.0:* LISTEN 2383/memcached
    . . .

You should see `memcached` bound to the `127.0.0.1` address using only TCP.

## Securing Memcached on CentOS and Fedora Servers

For Memcached services running on CentOS and Fedora servers, you can adjust the service parameters by editing the `/etc/sysconfig/memcached` file with `vi`, for instance:

    sudo vi /etc/sysconfig/memcached

Inside, we will want to bind to the local network interface to restrict traffic to clients on the same machine by using the `-l 127.0.0.1` option. This can be too restrictive for some environments, but is a good starting place.

We will also set `-U 0` to disable the UDP listener. UDP as protocol is much more effective for amplification attacks, so disabling it will limit the strength of some attacks if we decide to change the binding port at a later date.

Add both of these parameters inside of the `OPTIONS` variable:

/etc/sysconfig/memcached

    PORT="11211"
    USER="memcached"
    MAXCONN="1024"
    CACHESIZE="64"
    OPTIONS="-l 127.0.0.1 -U 0"

Save and close the file when you are finished.

To apply the changes, restart the Memcached service:

    sudo service memcached restart

Verify that Memcached is currently bound to the local interface and listening only for TCP by typing:

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    . . .
    tcp 0 0 127.0.0.1:11211 0.0.0.0:* LISTEN 2383/memcached
    . . .

You should see `memcached` bound to the `127.0.0.1` address using only TCP.

## Allowing Access Over the Private Network

The above instructions tell Memcached to only listen on the local interface. This prevents the amplification attack by not exposing the Memcached interface to outside parties. If you need to allow access from other servers, you will have to adjust the configuration.

The safest option to extend access is to bind Memcached to the private network interface.

### Limit IP Access With Firewalls

Before you do so, it is a good idea to set up firewall rules to limit the machines that can connect to your Memcached server. You will need to know the **client servers private IP addresses** to configure your firewall rules.

If you are using the **UFW** firewall, you can limit access to your Memcached instance by typing the following:

    sudo ufw allow OpenSSH
    sudo ufw allow from client_servers_private_IP/32 to any port 11211
    sudo ufw enable

You can find out more about UFW firewalls by reading our [essentials guide](ufw-essentials-common-firewall-rules-and-commands).

If you are using Iptables, a basic firewall can be established by typing:

    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp -s client_servers_private_IP/32 --dport 11211 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    sudo iptables -P INPUT DROP

Make sure to save your Iptables firewall rules using the mechanism provided by your distribution. You can learn more about Iptables by taking a look at our [essentials guide](iptables-essentials-common-firewall-rules-and-commands).

Afterwards, you can adjust the Memcached service to bind to your server’s private networking interface.

### Bind Memcached to the Private Network Interface

Now that your firewall is in place, you can adjust the Memcached configuration to bind to your server’s private networking interface instead of `127.0.0.1`.

For **Ubuntu** or **Debian** servers, open the `/etc/memcached.conf` file again:

    sudo nano /etc/memcached.conf

Inside, find the `-l 127.0.0.1` line and change the address to match your server’s private networking interface:

/etc/memcached.conf

    . . .
    -l memcached_servers_private_IP
    . . .

Save and close the file when you are finished.

For **CentOS** and **Fedora** servers, open the `/etc/sysconfig/memcached` file again:

    sudo vi /etc/sysconfig/memcached

Inside, change the `-l 127.0.0.1` parameter in the `OPTIONS` variable to reference your Memcached server’s private IP:

/etc/sysconfig/memcached

    . . .
    OPTIONS="-l memcached_servers_private_IP -U 0"

Save and close the file when you are finished.

Next, restart the Memcached service again:

    sudo service memcached restart

Check your new settings with `netstat` to confirm the change:

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    . . .
    tcp 0 0 memcached_servers_private_IP:11211 0.0.0.0:* LISTEN 2383/memcached
    . . .

Test connectivity from your external client to ensure that you can still reach the service. It is a good idea to also check access from a non-authorized client to ensure that your firewall rules are effective.

## Conclusion

The Memcached amplification attack can have a serious impact on network health and the stability of your services. However, the attack can be mitigated effectively by following best practices for running networked services. After applying the changes in this guide, it is a good idea to continue to monitor your services to ensure proper functionality and connectivity is maintained.
