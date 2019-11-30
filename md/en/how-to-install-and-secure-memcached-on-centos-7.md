---
author: Kathleen Juell
date: 2018-03-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-memcached-on-centos-7
---

# How To Install and Secure Memcached on CentOS 7

## Introduction

Memory object caching systems like Memcached can optimize backend database performance by temporarily storing information in memory, retaining frequently or recently requested records. In this way, they reduce the number of direct requests to your databases.

Because systems like Memcached can contribute to denial of service attacks if improperly configured, it is important to secure your Memcached servers. In this guide, we will cover how to protect your Memcached server by binding your installation to a local or private network interface and creating an authorized user for your Memcached instance.

## Prerequisites

This tutorial assumes that you have a server set up with a non-root sudo user and a basic firewall. If that is not the case, set up and install the following:

- One CentOS 7 server, set up following our [Initial Server Setup with CentOS 7 tutorial](initial-server-setup-with-centos-7).
- FirewallD, configured following the [“Install and Enable Your Firewall to Start at Boot”](how-to-set-up-a-firewall-using-firewalld-on-centos-7#install-and-enable-your-firewall-to-start-at-boot) section of our guide on using FirewallD with CentOS 7.

With these prerequisites in place, you will be ready to install and secure your Memcached server.

## Installing Memcached from Official Repositories

If you don’t already have Memcached installed on your server, you can install it from the official CentOS repositories. First, make sure that your local package index is updated:

    sudo yum update

Next, install the official package as follows:

    sudo yum install memcached

We can also install `libmemcached`, a library that provides several tools to work with your Memcached server:

    sudo yum install libmemcached

Memcached should now be installed as a service on your server, along with tools that will allow you to test its connectivity. We can now move on to securing its configuration settings.

## Securing Memcached Configuration Settings

To ensure that our Memcached instance is listening on the local interface `127.0.0.1`, we will modify the `OPTIONS` variable in the configuration file located at `/etc/sysconfig/memcached`. We will also disable the UDP listener. Both of these actions will protect our server from denial of service attacks.

You can open `/etc/sysconfig/memcached` with `vi`:

    sudo vi /etc/sysconfig/memcached

Locate the `OPTIONS` variable, which will initially look like this:

/etc/sysconfig/memcached

    . . .
    OPTIONS=""

Binding to our local network interface will restrict traffic to clients on the same machine. We will do this by adding `-l 127.0.0.1` to our `OPTIONS` variable. This may be too restrictive for certain environments, but it can make a good starting point as a security measure.

Because UDP protocol is much more effective for denial of service attacks than TCP, we can also disable the UDP listener. To do this, we will add the `-U 0` parameter to our `OPTIONS` variable. The file in full should look like this:

/etc/sysconfig/memcached

    
    PORT="11211"
    USER="memcached"
    MAXCONN="1024"
    CACHESIZE="64"
    OPTIONS="-l 127.0.0.1 -U 0" 

Save and close the file when you are done.

Restart your Memcached service to apply your changes:

    sudo systemctl restart memcached

Verify that Memcached is currently bound to the local interface and listening only for TCP connections by typing:

    sudo netstat -plunt

You should see the following output:

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    . . .
    tcp 0 0 127.0.0.1:11211 0.0.0.0:* LISTEN 2383/memcached
    . . .

This confirms that `memcached` is bound to the `127.0.0.1` address using only TCP.

## Adding Authorized Users

To add authenticated users to your Memcached service, it is possible to use Simple Authentication and Security Layer (SASL), a framework that de-couples authentication procedures from application protocols. We will enable SASL within our Memcached configuration file and then move on to adding a user with authentication credentials.

### Configuring SASL Support

We can first test the connectivity of our Memcached instance with the `memstat` command. This will help us establish that SASL and user authentication are enabled after we make changes to our configuration files.

To check that Memcached is up and running, type the following:

    memstat --servers="127.0.0.1"

You should see output like the following:

    OutputServer: 127.0.0.1 (11211)
         pid: 3831
         uptime: 9
         time: 1520028517
         version: 1.4.25
         . . .

Now we can move on to enabling SASL. First, we can add the `-S` parameter to our `OPTIONS` variable in `/etc/sysconfig/memcached`, which will enable SASL. Open the file again:

    sudo vi /etc/sysconfig/memcached

We will add both the `-S` and `-vv` parameters to our `OPTIONS` variable. The `-vv` option will provide verbose output to `/var/log/memcached`, which will help us as we debug. Add these options to the `OPTIONS` variable as follows:

/etc/sysconfig/memcached

    . . .
    OPTIONS="-l 127.0.0.1 -U 0 -S -vv" 

Save and close the file.

Restart the Memcached service:

    sudo systemctl restart memcached

Next, we can take a look at the logs to be sure that SASL support has been enabled:

    sudo journalctl -u memcached

You should see the following line, indicating that SASL support has been initialized:

    Output. . .
    Mar 05 18:16:11 memcached-server memcached[3846]: Initialized SASL.
    . . .

We can check the connectivity again, but because SASL has been initialized, this command should fail without authentication:

    memstat --servers="127.0.0.1"

This command should not produce output. We can type the following to check its status:

    echo $?

`$?` will always return the exit code of the last command that exited. Typically, anything besides `0` indicates process failure. In this case, we should see an exit status of `1`, which tells us that the `memstat` command failed.

### Adding an Authenticated User

Now we can download two packages that will allow us to work with the Cyrus SASL Library and its authentication mechanisms, including plugins that support _PLAIN_ authentication schemes. These packages, `cyrus-sasl-devel` and `cyrus-sasl-plain`, will allow us to create and authenticate our user. Install the packages by typing:

    sudo yum install cyrus-sasl-devel cyrus-sasl-plain

Next, we will create the directory and file that Memcached will check for its SASL configuration settings:

    sudo mkdir -p /etc/sasl2
    sudo vi /etc/sasl2/memcached.conf 

Add the following to the SASL configuration file:

/etc/sasl2/memcached.conf

    mech_list: plain
    log_level: 5
    sasldb_path: /etc/sasl2/memcached-sasldb2

In addition to specifying our logging level, we will set `mech_list` to `plain`, which tells Memcached that it should use its own password file and verify a plaintext password. We will also specify the path to the user database file that we will create next. Save and close the file when you are finished.

Now we will create a SASL database with our user credentials. We will use the `saslpasswd2` command to make a new entry for our user in our database using the `-c` option. Our user will be **sammy** here, but you can replace this name with your own user. Using the `-f` option, we will specify the path to our database, which will be the path we set in `/etc/sasl2/memcached.conf`:

    sudo saslpasswd2 -a memcached -c -f /etc/sasl2/memcached-sasldb2 sammy

Finally, we want to give the `memcached` user ownership over the SASL database:

    sudo chown memcached:memcached /etc/sasl2/memcached-sasldb2

Restart the Memcached service:

    sudo systemctl restart memcached

Running `memstat` again will confirm whether or not our authentication process worked. This time we will run it with our authentication credentials:

    memstat --servers="127.0.0.1" --username=sammy --password=your_password

You should see output like the following:

    OutputServer: 127.0.0.1 (11211)
         pid: 3831
         uptime: 9
         time: 1520028517
         version: 1.4.25
         . . .

Our Memcached service is now successfully running with SASL support and user authentication.

## Allowing Access Over the Private Network

We have covered how to configure Memcached to listen on the local interface, which can prevent denial of service attacks by protecting the Memcached interface from exposure to outside parties. There may be instances where you will need to allow access from other servers, however. In this case, you can adjust your configuration settings to bind Memcached to the private network interface.

**Note:** We will cover how to configure firewall settings using **FirewallD** in this section, but it is also possible to use DigitalOcean Cloud Firewalls to create these settings. For more information on setting up DigitalOcean Cloud Firewalls, see our [Introduction to DigitalOcean Cloud Firewalls](an-introduction-to-digitalocean-cloud-firewalls). To learn more about how to limit incoming traffic to particular machines, check out the section of this tutorial on [applying firewall rules using tags and server names](an-introduction-to-digitalocean-cloud-firewalls#applying-a-cloud-firewall-to-droplets) and our discussion of [firewall tags](how-to-organize-digitalocean-cloud-firewalls#using-tags).

### Limiting IP Access With Firewalls

Before you adjust your configuration settings, it is a good idea to set up firewall rules to limit the machines that can connect to your Memcached server. If you followed the prerequisites and installed FirewallD on your server and do **not** plan on connecting to Memcached from another host, then you do not need to adjust your firewall rules. Your standalone Memcached instance should be listening on `127.0.0.1`, thanks to the `OPTIONS` variable we defined earlier, and there should therefore be no concerns about incoming traffic. If you plan to allow access to your Memcached server from other hosts, however, then you will need to make changes to your firewall settings using the `firewall-cmd` command.

Begin by adding a dedicated Memcached zone to your `firewalld` policy:

    sudo firewall-cmd --permanent --new-zone=memcached

Then, specify which port you would like to keep open. Memcached uses port `11211` by default:

    sudo firewall-cmd --permanent --zone=memcached --add-port=11211/tcp

Next, specify the private IP addresses that should be allowed to access Memcached. For this, you will need to know your **client server’s private IP address** :

    sudo firewall-cmd --permanent --zone=memcached --add-source=client_server_private_IP

Reload the firewall to ensure that the new rules take effect:

    sudo firewall-cmd --reload

Packets from your client’s IP address should now be processed according to the rules in the dedicated Memcached zone. All other connections will be processed by the default `public` zone.

With these changes in place, we can move on to making the necessary configuration changes to our Memcached service, binding it to our server’s private networking interface.

### Binding Memcached to the Private Network Interface

The first step in binding to our server’s private networking interface will be modifying the `OPTIONS` variable we set earlier.

We can open `/etc/sysconfig/memcached` again by typing:

    sudo vi /etc/sysconfig/memcached

Inside, locate the `OPTIONS` variable. We can now modify `-l 127.0.0.1` to reflect our Memcached server’s private IP:

/etc/sysconfig/memcached

    . . .
    OPTIONS="-l memcached_servers_private_IP -U 0 -S -vv"

Save and close the file when you are finished.

Restart the Memcached service again:

    sudo systemctl restart memcached

Check your new settings with `netstat` to confirm the change:

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    . . .
    tcp 0 0 memcached_servers_private_IP:11211 0.0.0.0:* LISTEN 2383/memcached
    . . .

Test connectivity from your external client to ensure that you can still reach the service. It is a good idea to also check access from a non-authorized client to ensure that your firewall rules are effective.

## Conclusion

In this tutorial we have covered how to secure your Memcached server by configuring it to bind to your local or private network interface, and by enabling SASL authentication.

To learn more about Memcached, check out the [project documentation](https://memcached.org/about). For more information about how to work with Memcached, see our tutorial on [How To Install and Use Memcache on Ubuntu 14.04](how-to-install-and-use-memcache-on-ubuntu-14-04).
