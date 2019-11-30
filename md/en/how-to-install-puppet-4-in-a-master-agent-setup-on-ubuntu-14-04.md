---
author: Mitchell Anicas
date: 2016-03-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-puppet-4-in-a-master-agent-setup-on-ubuntu-14-04
---

# How To Install Puppet 4 in a Master-Agent Setup on Ubuntu 14.04

## Introduction

Puppet, from Puppet Labs, is a configuration management tool that helps system administrators automate the provisioning, configuration, and management of a server infrastructure. Planning ahead and using config management tools like Puppet can cut down on time spent repeating basic tasks, and help ensure that your configurations are consistent and accurate across your infrastructure. Once you get the hang of managing your servers with Puppet and other automation tools, you will have more free time that can be used to improve other aspects of your setup.

Puppet comes in two varieties, Puppet Enterprise and open source Puppet. It runs on most Linux distributions, various UNIX platforms, and Windows.

In this tutorial, we will cover how to install open source Puppet 4 in a master-agent setup on Ubuntu 14.04. In this setup, the **Puppet master** server—which runs the Puppet Server software—can be used to control all your other servers, or **Puppet agent** nodes. Note that we’ll be using the Puppet Server package, instead of Passenger or any other runtime environment.

## Prerequisites

To follow this tutorial, you must have root or superuser access to all of the servers that you want to use Puppet with. **You will also be required to create a new Ubuntu 14.04 server to act as the Puppet master server**. If you do not have an existing server infrastructure, feel free to recreate the example infrastructure (described below) by following the prerequisite DNS setup tutorial.

Before we get started with installing Puppet, ensure that you have the following prerequisites:

- **Private Network DNS:** Forward and reverse DNS must be configured, and each server must have a unique hostname. Here is a tutorial to [configure your own private network DNS server](how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04). If you do not have DNS configured, you must use your `hosts` file for name resolution. We will assume that you will use your private network for communication within your infrastructure.
- **Firewall Open Ports:** The Puppet master must be reachable on port 8140. If your firewall is too restrictive, check out this [UFW tutorial](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server) for instructions on how to allow incoming requests on port 8140.

### Example Infrastructure

We will use the following infrastructure to demonstrate how to set up Puppet:

| Hostname | Role | Private FQDN |
| --- | --- | --- |
| host1 | Generic Ubuntu 14.04 server | host1.nyc3.example.com |
| host2 | Generic Ubuntu 14.04 server | host2.nyc3.example.com |
| ns1 | Primary nameserver | ns1.nyc3.example.com |
| ns2 | Secondary nameserver | ns2.nyc3.example.com |

The puppet agent will be installed on all of these hosts. These hosts will be referenced by their private network interfaces, which are mapped to the “.nyc3.example.com” subdomain in DNS. This is the same infrastructure that is described in the prerequisite tutorial: [How To Configure BIND as a Private Network DNS Server on Ubuntu 14.04](how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04).

Once you have all of the prerequisites, let’s move on to creating the Puppet master server!

## Create Puppet Master Server

Create a new **Ubuntu 14.04** x64 server, using “puppet” as its hostname. The hardware requirements depend on how many agent nodes you want to manage; two CPU cores and 1 GB of memory is the _minimum_ requirement to manage a handful of nodes, but you’ll need more resources if your server infrastructure is larger. Puppet Server is configured to use 2 GB of RAM by default.

Add its private network to your DNS with the following details:

| Hostname | Role | Private FQDN |
| --- | --- | --- |
| puppet | Puppet master | puppet.nyc3.example.com |

If you just set up your DNS and are unsure how to include new hosts, refer to the [Maintaining DNS Records](how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-14-04#maintaining-dns-records) section of the DNS tutorial. Essentially, you need to add an “A” and “PTR” record, and allow the new host to perform recursive queries. Also, ensure that you configure your search domain so your servers can use short hostnames to look up each other.

**Note:** This tutorial assumes that your Puppet master’s hostname is “puppet”. If you use a different name, you will need to make a few deviations from this tutorial. Specifically, you must specify your Puppet master’s hostname in your Puppet agent nodes’ configuration files, and you must regenerate your Puppet master’s SSL certificate before signing any agent certificates. Otherwise, you will receive this error: `Error: Could not request certificate: The certificate retrieved from the master does not match the agent's private key.`.

Configuring this setting is not covered in this tutorial.

### Install NTP

Because it acts as a certificate authority for agent nodes, the Puppet master server must maintain accurate system time to avoid potential problems when it issues agent certificates–certificates can appear to be expired if there are time discrepancies. We will use Network Time Protocol (NTP) for this purpose.

First, take a look at the available timezones with this command:

    timedatectl list-timezones

This will give you a list of the timezones available for your server. When you find the region/timezone setting that is correct for your server, set it with this command (substitute your preferred region and timezone):

    sudo timedatectl set-timezone America/New_York

Install NTP via apt-get with these commands:

    sudo apt-get update
    sudo apt-get -y install ntp

It is common practice to update the NTP configuration to use “pools zones” that are geographically closer to your NTP server. In a web browser, go to the [NTP Pool Project](http://www.pool.ntp.org/en/) and look up a _pool zone_ that is geographically close the datacenter that you are using. We will use the United States pool ([http://www.pool.ntp.org/zone/us](http://www.pool.ntp.org/zone/us)) in our example, because our servers are located in a New York datacenter.

Open `ntp.conf` for editing:

    sudo vi /etc/ntp.conf

Add the time servers from the NTP Pool Project page to the top of the file (replace these with the servers of your choice):

/etc/ntp.conf excerpt

    server 0.us.pool.ntp.org
    server 1.us.pool.ntp.org
    server 2.us.pool.ntp.org
    server 3.us.pool.ntp.org

Save and exit.

Start NTP to add the new time servers:

    sudo service ntp restart

Now that our server is keeping accurate time, let’s install the Puppet Server software.

## Install Puppet Server

Puppet Server is the software that runs on the Puppet master server. It is the component that will push configurations to your other servers, which will be running the Puppet agent software.

Enable the official Puppet Labs collection repository with these commands:

    cd ~ && wget https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
    sudo dpkg -i puppetlabs-release-pc1-trusty.deb
    sudo apt-get update

Install the `puppetserver` package:

    sudo apt-get -y install puppetserver

Puppet Server is now installed on your master server, but it is not running yet.

### Configure Memory Allocation

By default, Puppet Server is configured to use 2 GB of RAM. You should customize this setting based on how much free memory your master server has, and how many agent nodes it will manage.

First, open `/etc/default/puppetserver` in your favorite text editor. We’ll use `vi`:

    sudo vi /etc/default/puppetserver

Then find the `JAVA_ARGS` line, and use the `-Xms` and `-Xmx` parameters to set the memory allocation. For example, if you want to use 3 GB of memory, the line should look like this:

Memory Allocation

    JAVA_ARGS="-Xms3g -Xmx3g"

Save and exit when you’re done.

### Start Puppet Server

Now we’re ready to start Puppet Server with this command:

    sudo service puppetserver restart

Next, enable Puppet Server so that it starts when your master server boots:

    sudo /opt/puppetlabs/bin/puppet resource service puppetserver ensure=running enable=true

Puppet Server is running, but it isn’t managing any agent nodes yet. Let’s learn how to install and add Puppet agents!

## Install Puppet Agent

The Puppet agent software must be installed on any server that the Puppet master will manage. In most cases, this will include every server in your infrastructure. As mentioned in the introduction, the Puppet agent can run on all major Linux distributions, some UNIX platforms, and Windows. Because the installation varies on each OS slightly, we will only cover the installation on Ubuntu 14.04 servers. Instructions on installing the Puppet agent on CentOS 7 servers can be found [here](how-to-install-puppet-4-in-a-master-agent-setup-on-centos-7#install-puppet-agent).

**Perform these steps on all of your agent servers.**

Enable the official Puppet Labs collection repository with these commands:

    cd ~ && wget https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
    sudo dpkg -i puppetlabs-release-pc1-trusty.deb

Then install the `puppet-agent` package:

    sudo apt-get update
    sudo apt-get install puppet-agent

Now that the Puppet agent is installed, start it with this command:

    sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

The first time you run the Puppet agent, it generates an SSL certificate and sends a signing request to the Puppet master. After the Puppet master signs the agent’s certificate, it will be able to communicate with and control the agent node.

Remember to repeat this section for all of your Puppet agent nodes.

**Note:** If this is your first Puppet agent, it is recommended that you attempt to sign the certificate on the Puppet master, which is covered in the next step, before adding your other agents. Once you have verified that everything works properly, then you can go back and add the remaining agent nodes with confidence.

## Sign Certificates on Puppet Master

The first time Puppet runs on an agent node, it will send a certificate signing request to the Puppet master. Before Puppet Server will be able to communicate with and control the agent node, it must sign that particular agent node’s certificate. We will describe how to sign and check for signing requests.

### List Current Certificate Requests

On the Puppet master, run the following command to list all unsigned certificate requests:

    sudo /opt/puppetlabs/bin/puppet cert list

If you just set up your first agent node, you will see one request. It will look something like the following, with the agent node’s hostname:

    Output: "host1.nyc3.example.com" (SHA256) 15:90:C2:FB:ED:69:A4:F7:B1:87:0B:BF:F7:DD:B5:1C:33:F7:76:67:F3:F6:23:AE:07:4B:F6:E3:CC:04:11:4C

Note that there is no `+` in front of it. This indicates that it has not been signed yet.

### Sign A Request

To sign a certificate request, use the `puppet cert sign` command, with the hostname of the certificate you want to sign. For example, to sign `host1.nyc3.example.com`’s certificate, you would use the following command:

    sudo /opt/puppetlabs/bin/puppet cert sign host1.nyc3.example.com

You will see the following output, which indicates that the certificate request has been signed:

    Output:Notice: Signed certificate request for host1.nyc3.example.com
    Notice: Removing file Puppet::SSL::CertificateRequest host1.nyc3.example.com at '/etc/puppetlabs/puppet/ssl/ca/requests/host1.nyc3.example.com.pem'

The Puppet master can now communicate and control the node that the signed certificate belongs to.

If you want to sign all of the current requests, use the `--all` option, like so:

    sudo /opt/puppetlabs/bin/puppet cert sign --all

### Revoke Certificates

You may want to remove a host from Puppet, or rebuild a host then add it back to Puppet. In this case, you will want to revoke the host’s certificate from the Puppet master. To do this, you can use the `clean` action:

    sudo /opt/puppetlabs/bin/puppet cert clean hostname

The specified host’s associated certificates will be removed from Puppet.

### View All Signed Requests

If you want to view all of the requests, signed and unsigned, run the following command:

    sudo /opt/puppetlabs/bin/puppet cert list --all

You will see a list of all of the requests. Signed requests are preceded by a `+` and unsigned requests do not have the `+`.

    Output:+ "puppet" (SHA256) 5A:71:E6:06:D8:0F:44:4D:70:F0:BE:51:72:15:97:68:D9:67:16:41:B0:38:9A:F2:B2:6C:BB:33:7E:0F:D4:53 (alt names: "DNS:puppet", "DNS:puppet.nyc3.example.com")
    + "host1.nyc3.example.com" (SHA256) F5:DC:68:24:63:E6:F1:9E:C5:FE:F5:1A:90:93:DF:19:F2:28:8B:D7:BD:D2:6A:83:07:BA:FE:24:11:24:54:6A
    + "host2.nyc3.example.com" (SHA256) CB:CB:CA:48:E0:DF:06:6A:7D:75:E6:CB:22:BE:35:5A:9A:B3:93:63:BF:F0:DB:F2:D8:E5:A6:27:10:71:78:DA
    + "ns2.nyc3.example.com" (SHA256) 58:47:79:8A:56:DD:06:39:52:1F:E3:A0:F0:16:ED:8D:40:17:40:76:C2:F0:4F:F3:0D:F9:B3:64:48:2E:F1:CF

Congrats! Your infrastructure is now ready to be managed by Puppet!

## Getting Started with Puppet

Now that your infrastructure is set up to be managed with Puppet, we will show you how to use Puppet to do a few basic tasks.

### How Facts Are Gathered

Puppet gathers facts about each of its nodes with a tool called _facter_. Facter, by default, gathers information that is useful for system configuration (e.g. OS names, hostnames, IP addresses, SSH keys, and more). It is possible to add custom facts that aren’t part of the default fact set.

The facts gathered can be useful in many situations. For example, you can create an web server configuration template and automatically fill in the appropriate IP addresses for a particular virtual host. Or you can determine that your server’s distribution is “Ubuntu”, so you should run the `apache2` service instead of `httpd`. These are basic examples, but they should give you an idea of how facts can be used.

To see a list of facts that are automatically being gathered on your agent node, run the following command:

    /opt/puppetlabs/bin/facter

### Main Manifest File

Puppet uses a domain-specific language to describe system configurations, and these descriptions are saved to files called “manifests”, which have a .pp file extension. The default main manifest file is located **on your Puppet master server** at `/etc/puppetlabs/code/environments/production/manifests/site.pp`. Let’s will create a placeholder file for now:

    sudo touch /etc/puppetlabs/code/environments/production/manifests/site.pp

Note that the main manifest is empty right now, so Puppet won’t perform any configuration on the agent nodes.

### How The Main Manifest Is Executed

The Puppet agent periodically checks in with the Puppet Server (typically every 30 minutes). When it checks in, it will send facts about itself to the master, and pull a current catalog–a compiled list of resources and their desired states that are relevant to the agent, determined by the main manifest. The agent node will then attempt to make the appropriate changes to achieve its desired state. This cycle will continue as long as the Puppet master is running and communicating with the agent nodes.

#### Immediate Execution on a Particular Agent Node

It is also possible to initiate the check for a particular agent node manually, by running the following command (on the agent node in question):

    /opt/puppetlabs/bin/puppet agent --test

Running this will apply the main manifest to the agent running the test. You might see output like the following:

    Output:Info: Using configured environment 'production'
    Info: Retrieving pluginfacts
    Info: Retrieving plugin
    ...
    Info: Loading facts
    Info: Caching catalog for host1
    Info: Applying configuration version '1457389302'
    Notice: /Stage[main]/Main/File[/tmp/example-ip]/ensure: defined content as '{md5}dd769ec60ea7d4f7146036670c6ac99f'
    Notice: Applied catalog in 0.04 seconds

This command is useful for seeing how the main manifest will affect a single server immediately.

### One-off Manifests

The `puppet apply` command allows you to execute manifests that are not related to the main manifest, on demand. It only applies the manifest to the node that you run the _apply_ from. Here is an example:

    sudo /opt/puppetlabs/bin/puppet apply /path/to/your/manifest/init.pp

Running manifests in this fashion is useful if you want to test a new manifest on an agent node, or if you just want to run a manifest once (e.g. to initialize an agent node to a desired state).

## An Example Manifest

As you may recall, the main manifest file on the Puppet master is located at `/etc/puppetlabs/code/environments/production/manifests/site.pp`.

On the Puppet master server, edit it now:

    sudo vi /etc/puppetlabs/code/environments/production/manifests/site.pp

Now add the following lines to describe a file resource:

site.pp example

    file {'/tmp/example-ip': # resource type file and filename
      ensure => present, # make sure it exists
      mode => '0644', # file permissions
      content => "Here is my Public IP Address: ${ipaddress_eth0}.\n", # note the ipaddress_eth0 fact
    }

Now save and exit. The inline comments should explain the resource that we are defining. In plain English, this will ensure that all agent nodes will have a file at `/tmp/example-ip` with `-rw-r--r--` permissions, with content that includes the node’s public IP address.

You can either wait until the agent checks in with the master automatically, or you can run the `puppet agent --test` command (from one of your agent nodes). Then run the following command to print the file:

    cat /tmp/example-ip

You should see output that looks like the following (with that node’s IP address):

    Output:Here is my Public IP Address: 128.131.192.11.

### Specify a Node

If you want to define a resource for specific nodes, define a `node` in the manifest.

On the master, edit `site.pp`:

    sudo vi /etc/puppetlabs/code/environments/production/manifests/site.pp

Now add the following lines:

site.pp example

    node 'ns1', 'ns2' { # applies to ns1 and ns2 nodes
      file {'/tmp/dns': # resource type file and filename
        ensure => present, # make sure it exists
        mode => '0644',
        content => "Only DNS servers get this file.\n",
      }
    }
    
    node default {} # applies to nodes that aren't explicitly defined

Save and exit.

Now Puppet will ensure that a file at `/tmp/dns` will exist on _ns1_ and _ns2_. You may want to run the `puppet agent --test` command (from ns1 or ns2), if you do not want to wait for the scheduled Puppet agent pull.

Note that if you do not define a resource, Puppet will do its best not to touch it. So if you delete these resources from the manifest, Puppet will not delete the files it created. If you want to have it delete the files, change `ensure` to `absent`.

These examples don’t do anything useful, but they do prove that Puppet is working properly.

## Using a Module

Now let’s use a module. Modules are useful for grouping tasks together. There are many modules available in the Puppet community, and you can even write your own.

On the Puppet master, install the `puppetlabs-apache` module from forgeapi:

    sudo /opt/puppetlabs/bin/puppet module install puppetlabs-apache

**Warning** : Do not use this module on an existing Apache setup. It will purge any Apache configurations that are not managed by Puppet.

Now edit `site.pp`:

    sudo vi /etc/puppetlabs/code/environments/production/manifests/site.pp

Now add the following lines to install Apache on _host2_:

site.pp example

    node 'host2' {
      class { 'apache': } # use apache module
      apache::vhost { 'example.com': # define vhost resource
        port => '80',
        docroot => '/var/www/html'
      }
    }
    
    # node default {} # uncomment this line if it doesn't already exist in your manifest

Save and exit. Now the next time Puppet updates host2, it will install the Apache package, and configure a virtual host called “example.com”, listening on port 80, and with a document root `/var/www/html`.

On **host2** , run the following command:

    sudo /opt/puppetlabs/bin/puppet agent --test

You should see a bunch of output indicating that Apache is being installed. Once it is complete, open host2’s public IP address in a web browser. You should see a page that is being served by Apache.

Congrats! You have used your first Puppet module!

## Conclusion

Now that you have a basic agent/master Puppet installation, you are now ready to learn more about how to use Puppet to manage your server infrastructure. Check out the following tutorial: [Getting Started With Puppet Code: Manifests and Modules](getting-started-with-puppet-code-manifests-and-modules).
