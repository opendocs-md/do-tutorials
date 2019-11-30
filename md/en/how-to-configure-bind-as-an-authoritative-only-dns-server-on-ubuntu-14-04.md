---
author: Justin Ellingwood
date: 2014-07-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-an-authoritative-only-dns-server-on-ubuntu-14-04
---

# How To Configure Bind as an Authoritative-Only DNS Server on Ubuntu 14.04

## Introduction

* * *

DNS, or the Domain Name System, is often a difficult component to get right when learning how to configure websites and servers. While most people will probably choose to use the DNS servers provided by their hosting company or their domain registrar, there are some advantages to creating your own DNS servers.

In this guide, we will discuss how to install and configure the Bind9 DNS server as authoritative-only DNS servers on Ubuntu 14.04 machines. We will set these up two Bind servers for our domain in a primary-secondary configuration.

## Prerequisites and Goals

To complete this guide, you will first need to be familiar with some common DNS terminology. Check out [this guide](an-introduction-to-dns-terminology-components-and-concepts) to learn about the concepts we will be implementing in this guide.

You will also need at least two servers. One will be for the “primary” DNS server where the zone files for our domain will originate and one will be the “secondary” server which will receive the zone data through transfers and be available in the event that the other server goes down. This avoids the peril of having a single point of failure for your DNS servers.

Unlike caching or forwarding DNS servers or a multi-purpose DNS server, authoritative-only servers only respond to iterative queries for the zones that they are authoritative for. This means that if the server does not know the answer, it will just tell the client (usually some kind of resolving DNS server) that it does not know the answer and give a reference to a server that may know more.

Authoritative-only DNS servers are often a good configuration for high performance because they do not have the overhead of resolving recursive queries from clients. They only care about the zones that they are designed to serve.

For the purposes of this guide, we will actually be referencing **three** servers. The two name servers mentioned above, plus a web server that we want to configure as a host within our zone.

We will use the dummy domain `example.com` for this guide. You should replace it with the domain that you are configuring. These are the details of the machines we will be configuring:

| Purpose | DNS FQDN | IP Address |
| --- | --- | --- |
| Primary name server | ns1.example.com. | 192.0.2.1 |
| Secondary name server | ns2.example.com. | 192.0.2.2 |
| Web Server | [www.example.com](http://www.example.com). | 192.0.2.3 |

After completing this guide, you should have two authoritative-only name servers configured for your domain zones. The names in the center column in the table above will be able to be used to reach your various hosts. Using this configuration, a recursive DNS server will be able to return data about the domain to clients.

## Setting the Hostname on the Name Servers

Before we get into the configuration of our name servers, we must ensure that our hostname is configured properly on both our primary and secondary DNS server.

Begin by investigating the `/etc/hosts` file. Open the file with sudo privileges in your text editor:

    sudo nano /etc/hosts

We need to configure this so that it correctly identifies each server’s hostname and FQDN. For the primary name server, the file will look something like this initially:

    127.0.0.1 localhost
    127.0.1.1 ns1 ns1
    . . .

We should modify the second line to reference our specific host and domain combination and point this to our public, static IP address. We can then add the unqualified name as an alias at the end. For the primary server in this example, you would change the second line to this:

    127.0.0.1 localhost
    192.0.2.1 ns1.example.com ns1
    . . .

Save and close the file when you are finished.

We should also modify the `/etc/hostname` file to contain our unqualified hostname:

    sudo nano /etc/hostname

    ns1

We can read this value into the currently running system then by typing:

    sudo hostname -F /etc/hostname

We want to complete the same procedure on our secondary server.

Start with the `/etc/hosts` file:

    sudo nano /etc/hosts

    127.0.0.1 localhost
    192.0.2.2 ns2.example.com ns2

Save and close the file when you are finished.

Then, modify the `/etc/hostname` file. Remember to only use the actual host (just `ns2` in our example) for this file:

    sudo nano /etc/hostname

    ns2

Again, read the file to modify the current system:

    sudo hostname -F /etc/hostname

Your servers should now have their host definitions set correctly.

## Install Bind on Both Name Servers

On each of your name servers, you can now install Bind, the DNS server that we will be using.

The Bind software is available within Ubuntu’s default repositories, so we just need to update our local package index and install the software using `apt`. We will also include the documentation and some common utilities:

    sudo apt-get update
    sudo apt-get install bind9 bind9utils bind9-doc

Run this installation command on your primary and secondary DNS servers to acquire the appropriate files.

## Configure the Primary Bind Server

Now that we have the software installed, we can begin by configuring our DNS server on the primary server.

### Configuring the Options File

The first thing that we will configure to get started is the `named.conf.options` file.

The Bind DNS server is also known as `named`. The main configuration file is located at `/etc/bind/named.conf`. This file calls on the other files that we will be actually configuring.

Open the options file with sudo privileges in your editor:

    sudo nano /etc/bind/named.conf.options

Below, most of the commented lines have been stripped out for brevity, but in general the file should look like this after installation:

    options {
            directory "/var/cache/bind";
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

The main thing that we need to configure in this file is recursion. Since we are trying to set up an authoritative-only server, we do not want to enable recursion on this server. We can turn this off within the `options` block.

We are also going to default to not allowing transfers. We will override this in individual zone specifications later:

    options {
            directory "/var/cache/bind";
            recursion no;
            allow-transfer { none; };
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

When you are finished, save and close the file.

### Configuring the Local File

The next step that we need to take is to specify the zones that we wish to control this server. A zone is any portion of the domain that is delegated for management to a name server that has not been sub-delegated to other servers.

We are configuring the `example.com` domain and we are not going to be sub-delegating responsibility for any portion of the domain to other servers. So the zone will cover our entire domain.

To configure our zones, we need to open the `/etc/bind/named.conf.local` file with sudo privileges:

    sudo nano /etc/bind/named.conf.local

This file will initially be empty besides comments. There are other zones that our server knows about for general management, but these are specified in the `named.conf.default-zones` file.

To start off, we need to configure the forward zone for our `example.com` domain. Forward zone are the conventional name-to-IP resolution that most of us think of when we discuss DNS. We create a configuration block that defines the domain zone we wish to configure:

    zone "example.com" {
    };

**_Note:_** _Many DNS tools, their configuration files, and documentation use the terms “master” and “slave” while DigitalOcean generally prefers alternative descriptors. To avoid confusion we’ve chosen to use the terms “primary” and “secondary” to denote relationships between servers, and only use “master” or “slave” where a configuration directive requires it._

Inside of this block, we add the management information about this zone. We specify the relationship of this DNS server to the zone. This is `type master;` in the example zone that follows since we are configuring this machine as the primary name server for all of our zones. We also point Bind to the file that holds the actual resource records that define the zone.

We are going to keep our primary zone files in a subdirectory called `zones` within the Bind configuration directory. We will call our file `db.example.com` to borrow convention from the other zone files in the Bind directory. Our block will look like this now:

    zone "example.com" {
        type master;
        file "/etc/bind/zones/db.example.com";
    };

We want to allow this zone to be transferred to our secondary server, we need to add a line like this:

    zone "example.com" {
        type master;
        file "/etc/bind/zones/db.example.com";
        allow-transfer { 192.0.2.2; };
    };

Next, we are going to define the reverse zone for our domain.

#### A Bit About Reverse Zones

If the organization that gave you your IP addresses did not give you a network range and delegate responsibility for that range to you, then your reverse zone file will not be referenced and will be handled by the organization itself.

With hosting providers, the reverse mapping is usually taken care of by the company itself. For instance, with DigitalOcean, reverse mappings for your servers will be automatically created if use the machine’s FQDN as the server name in the control panel. For instance, the reverse mappings for this tutorial could be created by naming the servers like this:

![DigitalOcean auto reverse DNS mapping](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bind_auth/auto_reverse.png)

In instances like these, since you have not been allocated a chunk of addresses to administer, you should use this strategy. The strategy outlined below is covered for completeness and to make it applicable if you have been delegated control over larger groups of contiguous addresses.

Reverse zones are used to connect an IP address back to a domain name. However, the domain name system was designed for the forward mappings originally, so some thought is needed to adapt this to allow for reverse mappings.

The pieces of information that you need to keep in mind to understand reverse mappings are:

- In a domain, the most specific portion is of the address is on the left. For an IP address, the most specific portion is on the right.
- The most specific part of a domain specification is either a subdomain or a host name. This is defined in the zone file for the domain.
- Each subdomain can, in turn, define more subdomains or hosts.

All reverse zone mappings are defined under the special domain `in-addr.arpa`, which is controlled by the Internet Assigned Numbers Authority (IANA). Under this domain, a tree exists that uses subdomains to map out each of the octets in an IP address. To make sure that the specificity of the IP addresses mirrors that of normal domains, the octets of the IP addresses are actually reversed.

So our primary DNS server, with an IP address of `192.0.2.1`, would be flipped to read as `1.2.0.192`. When we add this host specification as a hierarchy existing under the `in-addr.arpa` domain, the specific host can be referenced as `1.2.0.192.in-addr.arpa`.

Since we define individual hosts (like the leading “1” here) within the zone file itself when using DNS, the zone we would be configuring would be `2.0.192.in-addr.arpa`. If our network provider has given us a /24 block of addresses, say `192.0.2.0/24`, they would have delegated this `in-addr.arpa` portion to us.

Now that you know how to specify the reverse zone name, the actual definition is exactly the same as the forward zone. Below the `example.com` zone definition, make a reverse zone for the network you have been given. Again, this is probably only necessary if you were delegated control over a block of addresses:

    zone "2.0.192.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/db.192.0.2";
    };

We have chosen to name the file `db.192.0.2`. This is specific about what the zone configures and is more readable than the reverse notation.

Save and close the file when you are finished.

### Create the Forward Zone File

We have told Bind about our forward and reverse zones now, but we have not yet created the files that will define these zones.

If you recall, we specified the file locations as being within a subdirectory called `zones`. We need to create this directory:

    sudo mkdir /etc/bind/zones

Now, we can use some of the pre-existing zone files in the Bind directory as templates for the zone files we want to create. For the forward zone, the `db.local` file will be close to what we need. Copy that file into the `zones` subdirectory with the name used in the `named.conf.local` file.

    sudo cp /etc/bind/db.local /etc/bind/zones/db.example.com

While we are doing this, we can copy a template for the reverse zone as well. We will use the `db.127` file, since it’s a close match for what we need:

    sudo cp /etc/bind/db.127 /etc/bind/zones/db.192.0.2

Now, open the forward zone file with sudo privileges in your text editor:

    sudo nano /etc/bind/zones/db.example.com

The file will look like this:

    $TTL 604800
    @ IN SOA localhost. root.localhost. (
                                  2 ; Serial
                             604800 ; Refresh
                              86400 ; Retry
                            2419200 ; Expire
                             604800 ) ; Negative Cache TTL
    ;
    @ IN NS localhost.
    @ IN A 127.0.0.1
    @ IN AAAA ::1

The first thing we need want to do is modify the `SOA` (start of authority) record that starts with the first `@` symbol and continues until the closing parenthesis.

We need to replace the `localhost.` with the name of the FQDN of this machine. This portion of the record is used to define any name server that will respond authoritatively for the zone being defined. This will be the machine we are configuring now, `ns1.example.com.` in our case (notice the trailing dot. This is important for our entry to register correctly!).

We also want to change the next piece, which is actually a specially formatted email address with the `@` replaced by a dot. We want our emails to go to an administer of the domain, so the traditional email is `admin@example.com`. We would translate this so it looks like `admin.example.com.`:

    @ IN SOA ns1.example.com. admin.example.com. (

The next piece we need to edit is the serial number. The value of the serial number is how Bind tells if it needs to send updated information to the secondary server.

**Note** : Failing to increment the serial number is one of the most common mistakes that leads to issues with zone updates. Each time you make an edit, you _must_ bump the serial number.

One common practice is to use a convention for incrementing the number. One approach is to use the date in YYYYMMDD format along with a revision number for the day added onto the end. So the first revision made on June 05, 2014 could have a serial number of 2014060501 and an update made later that day could have a serial number of 2014060502. The value can be a 10 digit number.

It is worth adopting a convention for ease of use, but to keep things simple for our demonstration, we will just set ours to `5` for now:

    @ IN SOA ns1.example.com. admin.example.com. (
                                  5 ; Serial

Next, we can get rid of the last three lines in the file (the ones at the bottom that start with `@`) as we will be making our own.

The first thing we want to establish after the SOA record are the name servers for our zone. We specify the domain and then our two name servers that are authoritative for the zone, by name. Since these name servers will be hosts within the domain itself, it will look a bit self-referential.

For our guide, it will look like this. Again, pay attention to the ending dots!:

    ; Name servers
    example.com. IN NS ns1.example.com.
    example.com. IN NS ns2.example.com.

Since the purpose of a zone file is mainly to map host names and services to specific addresses, we are not done yet. Any software reading this zone file is going to want to know where the `ns1` and `ns2` servers are in order to access the authoritative zones.

So next, we need to create the `A` records that will associate these name server names to the actual IP addresses of our name servers:

    ; A records for name servers
    ns1 IN A 192.0.2.1
    ns2 IN A 192.0.2.2

Now that we have the A records to successfully resolve our name servers to their correct IP addresses, we can add any additional records. Remember, we have a web server on one of our hosts that we want to use to serve our site. We will point requests for the general domain (`example.com` in our case) to this host, as well as requests for the `www` host. It will look like this:

    ; Other A records
    @ IN A 192.0.2.3
    www IN A 192.0.2.3

You can add any additional hosts that you need to define by creating additional `A` records. Reference our [DNS basics guide](an-introduction-to-dns-terminology-components-and-concepts) to get familiar with some of your options with creating additional records.

When you are finished, your file should look something like this:

    $TTL 604800
    @ IN SOA ns1.example.com. admin.example.com. (
                                  5 ; Serial
                             604800 ; Refresh
                              86400 ; Retry
                            2419200 ; Expire
                             604800 ) ; Negative Cache TTL
    ;
    
    ; Name servers
    example.com. IN NS ns1.example.com.
    example.com. IN NS ns2.example.com.
    
    ; A records for name servers
    ns1 IN A 192.0.2.1
    ns2 IN A 192.0.2.2
    
    ; Other A records
    @ IN A 192.0.2.3
    www IN A 192.0.2.3

Save and close the file when you are finished.

### Create the Reverse Zone File

Now, we have the forward zone configured, but we need to set up the reverse zone file that we specified in our configuration file. We already created the file at the beginning of the last section.

Open the file in your text editor with sudo privileges:

    sudo nano db.192.0.2

The file should look like this:

    $TTL 604800
    @ IN SOA localhost. root.localhost. (
                                  1 ; Serial
                             604800 ; Refresh
                              86400 ; Retry
                            2419200 ; Expire
                             604800 ) ; Negative Cache TTL
    ;
    @ IN NS localhost.
    1.0.0 IN PTR localhost.

We will go through much of the same procedure as we did with the forward zone. First, adjust the domain name, the admin email, and the serial number to match exactly what you had in the last file (The serial number can be different, but should be incremented):

    @ IN SOA example.com. admin.example.com. (
                                  5 ; Serial

Again, wipe out the lines under the closing parenthesis of the `SOA` record. We will be taking the last octet of each IP address in our network range and mapping it back to that host’s FQDN using a `PTR` record. Each IP address should only have a single `PTR` record to avoid problems in some software, so you must choose the host name you wish to reverse map to.

For instance, if you have a mail server set up, you probably want to set up the reverse mapping to the mail name, since many systems use the reverse mapping to validate addresses.

First, we need to set our name servers again:

    ; Name servers
            IN NS ns1.example.com.
            IN NS ns2.example.com.

Next, you will use the last octet of the IP address you are referring to and point that back to the fully qualified domain name you want to return with. For our example, we will use this:

    ; PTR Records
    1 IN PTR ns1.example.com.
    2 IN PTR ns2.example.com.
    3 IN PTR www.example.com.

When you are finished, the file should look something like this:

    $TTL 604800
    @ IN SOA example.com. admin.example.com. (
                                  5 ; Serial
                             604800 ; Refresh
                              86400 ; Retry
                            2419200 ; Expire
                             604800 ) ; Negative Cache TTL
    ;
    
    ; Name servers
            IN NS ns1.example.com.
            IN NS ns2.example.com.
    
    ; PTR records
    1 IN PTR ns1.example.com.
    2 IN PTR ns2.example.com.
    3 IN PTR www.example.com.

Save and close the file when you are finished.

### Testing the Files and Restarting the Service

The configuration for the primary server is now complete, but we still need to implement our changes.

Before we restart our service, we should test all of our configuration files to make sure that they’re configured correctly. We have some tools that can check the syntax of each of our files.

First, we can check the `named.conf.local` and `named.conf.options` files by using the `named-checkconf` command. Since both of these files are source by the skeleton `named.conf` file, it will test the syntax of the files we modified.

    sudo named-checkconf

If this returns without any messages, it means that the `named.conf.local` and `named.conf.options` files are syntactically valid.

Next, you can check your individual zone files by passing the domain that the zone handles and the zone file location to the `named-checkzone` command. So for our guide, you could check the forward zone file by typing:

    sudo named-checkzone example.com /etc/bind/zones/db.example.com

If your file has no problems, it should tell you that it loaded the correct serial number and give the “OK” message;

    zone example.com/IN: loaded serial 5
    OK

If you run into any other messages, it means that you have a problem with your zone file. Usually, the message is quite descriptive about what portion is invalid.

You can check the reverse zone by passing the `in-addr.arpa` address and the file name. For our demonstration, we would be type this:

    sudo named-checkzone 2.0.192.in-addr.arpa /etc/bind/zones/db.192.0.2

Again, this should give you a similar message about loading the correct serial number:

    zone 2.0.192.in-addr.arpa/IN: loaded serial 5
    OK

If all of your files are checking out, you can restart your Bind service:

    sudo service bind9 restart

You should check the logs by typing:

    sudo tail -f /var/log/syslog

Keep an eye on this log to make sure that there are no errors.

## Configure the Secondary Bind Server

Now that we have the primary server configured, we can go ahead and get the secondary server set up. This will be significantly easier than the primary server.

### Configuring the Options File

Again, we will start with the `named.conf.options` file. Open it with sudo privileges in your text editor:

    sudo nano /etc/bind/named.conf.options

We will make the same exact modifications to this file that we made to our primary server’s file.

    options {
            directory "/var/cache/bind";
            recursion no;
            allow-transfer { none; };
    
            dnssec-validation auto;
    
            auth-nxdomain no; # conform to RFC1035
            listen-on-v6 { any; };
    };

Save and close the file when you are finished.

### Configuring the Local Configuration File

Next, we will configure the `named.conf.local` file on the secondary server. Open it with sudo privileges in your text editor:

    sudo nano /etc/bind/named.conf.local

Here, we will create each of our zone specifications like we did on our primary server. However, the values and some of the parameters will be different.

First, we will work on the forward zone. Start it off the same way that you did in the primary file:

    zone "example.com" {
    };

This time, we are going to set the `type` to `slave` since this server is acting as a secondary for this zone. This simply means that it receives its zone files through transfer rather than a file on the local system. Additionally, we are just going to specify the relative filename instead of the absolute path to the zone file.

The reason for this is that, for secondary zones, Bind stores the files `/var/cache/bind`. Bind is already configured to look in this directory location, so we do not need to specify the path.

For our forward zone, these details will look like this:

    zone "example.com" {
        type slave;
        file "db.example.com";
    };

Finally, instead of the `allow-transfer` directive, we will specify the primary servers, by IP address, that this server will accept zone transfers from. This is done in a directive called `masters`:

    zone "example.com" {
        type slave;
        file "db.example.com";
        masters { 192.0.2.1; };
    };

This completes our forward zone specification. We can use this same exact format to take care of our reverse zone specification:

    zone "2.0.192.in-addr.arpa" {
        type slave;
        file "db.192.0.2";
        masters { 192.0.2.1; };
    };

When you are finished, you can save and close the file.

### Testing the Files and Restarting the Service

We do not actually have to do any of the actual zone file creation on the secondary machine because, like we mentioned before, this server will receive the zone files from the primary server. So we are ready to test.

Again, we should check the configuration file syntax. Since we don’t have any zone files to check, we only need to use the `named-checkconf` tool:

    sudo named-checkconf

If this returns without any errors, it means that the files you modified have no syntax errors.

If this is the case, you can restart your Bind service:

    sudo service bind9 restart

Check the logs on both the primary and secondary servers using:

    sudo tail -f /var/log/syslog

You should see some entries that indicate that the zone files have been transferred correctly.

## Delegate Authority to your Name Servers

Your authoritative-only name servers should now be completely configured. However, you still need to delegate authority for your domain to your name servers.

To do this, you will have to go to the website where you purchased your domain name. The interface and perhaps the terminology will be different depending on the domain name registrar that you used.

In your domain settings, look for an option that will allow you to specify the name servers you wish to use. Since our name servers are _within_ our domain, this is a special case.

Instead of the registrar simply delegating authority for the zone through the use of NS records, it will need to create a **glue record**. A glue record is an A record that specifies the IP addresses for the name servers after it specifies the name servers that it is delegating authority to.

Usually, the delegation only lists the name servers that will handle the authority of the domain, but when the name servers are within the domain itself, an A record is needed for the name servers in the parent zone. If this didn’t happen, DNS resolvers would get stuck in a loop because it would never be able to find the IP address of the domain’s name servers to follow the delegation path.

So you need to find a section of your domain registrar’s control panel that allows you to specify name servers _and_ their IP addresses.

As a demonstration, the registrar [Namecheap](https://www.namecheap.com) has two different name server sections.

There is a section called “Nameserver Registration” that allows you to specify the IP addresses for name servers within your domain:

![NameCheap register name servers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bind_auth/register.png)

Inside, you will be able input the IP addresses of the name servers that exist within the domain:

![NameCheap internal name server](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bind_auth/give_ips.png)

This will create the A record that that serve as the glue records that you need in the parent zone file.

After you’ve done this, you should be able to change the active name servers to your domain’s servers. In NameCheap, this is done using the “Domain Name Server Setup” menu option:

![NameCheap domain name setup](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bind_auth/server_setup.png)

Here, you can tell it to use the name servers you added as the authoritative servers for your site:

![NameCheap use name servers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/bind_auth/use_servers.png)

The changes might take awhile to propagate, but you should see the data from your name servers being used within the next 24-48 hours for most registrars.

## Conclusion

You should now have two authoritative-only DNS servers configured to server your domains. These can be used to store zone information for additional domains as you acquire more.

Configuring and managing your own DNS servers gives you the most control over how the DNS records are handled. You can make changes and be sure that all relevant pieces of DNS data are up-to-date at the source. While other DNS solutions may make this process easier, it is important to know that you have options and to understand what is happening in more packaged solutions.
