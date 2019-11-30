---
author: Ian Mcxa
date: 2016-12-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-centralized-linux-authentication-with-freeipa-on-centos-7
---

# How To Set Up Centralized Linux Authentication with FreeIPA on CentOS 7

## Introduction

[FreeIPA](https://www.freeipa.org/page/Main_Page) is an open-source security solution for Linux which provides account management and centralized authentication, similar to Microsoft’s Active Directory. FreeIPA is built on top of multiple open source projects including the 389 Directory Server, MIT Kerberos, and SSSD.

FreeIPA has clients for CentOS 7, Fedora, and Ubuntu 14.04/16.04. These clients make it fairly straightforward to add machines into your IPA domain. Other operating systems can authenticate against FreeIPA using SSSD or LDAP.

In this tutorial, we will be installing the FreeIPA server on a CentOS 7 server. You can then configure client machines, allowing FreeIPA users to log in with their IPA credentials.

After you follow this tutorial, you can [configure a FreeIPA client on Ubuntu 16.04](how-to-configure-a-freeipa-client-on-ubuntu-16-04/) or [configure a FreeIPA client on CentOS 7](how-to-configure-a-freeipa-client-on-centos-7).

## Prerequisites

To follow this tutorial, you will need:

- One CentOS 7 server with at least 1 GB of RAM. By default, CentOS 7 only uses the root user. Because we will be using FreeIPA to manage users, it’s not necessary to manually add another user. You can simply follow this tutorial as the root user.

- A firewall enabled on your server, which you can set up by following [the firewall step in the Additional Recommended Steps for CentOS 7 tutorial](additional-recommended-steps-for-new-centos-7-servers#configuring-a-basic-firewall). This is strongly recommended because FreeIPA handles sensitive user credentials.

- A fully registered domain to use for the server and clients. You can purchase one on [Namecheap](https://namecheap.com) or get one for free on [Freenom](http://www.freenom.com/en/index.html).

- The following DNS records set up for your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them.

- Optionally, the `nano` text editor installed with `yum install nano`. CentOS comes with the `vi` text editor by default, but `nano` can be more user friendly.

## Step 1 — Preparing the IPA Server

Before we start installing anything, we need to do a few things to make sure the server is ready to run FreeIPA. Specifically, we’ll set the server hostname, update the system packages, check that the DNS records from the prerequisites have propagated, and make sure that the firewall will allow traffic to FreeIPA.

To begin, the hostname of your server will need to match your fully qualified domain name (FQDN) for FreeIPA to work correctly. We’ll be using `ipa.example.com` as the FQDN throughout this tutorial.

You can either set the hostname when you create the server or set it from the command line after the server is created, using the `hostname` command:

    hostname ipa.example.org

Now, update the package repository with `yum`.

    yum update

Next, open the required ports for FreeIPA in the firewall.

    firewall-cmd --permanent --add-port={80/tcp,443/tcp,389/tcp,636/tcp,88/tcp,464/tcp,53/tcp,88/udp,464/udp,53/udp,123/udp}

Reload the firewall so the changes will take effect.

    firewall-cmd --reload

Finally, you need to verify that the DNS names resolve properly. You can use the `dig` command for this. Install the `bind-utils` package to get `dig` and other DNS testing utilities.

    yum install bind-utils

Then use `dig` to check the A record.

    dig +short ipa.example.org A

This should return `your_server_ipv4`.

If you have IPv6 enabled, you can test the AAAA record the same way.

    dig +short ipa.example.org AAAA

This should return `your_server_ipv6`.

You can also test the reverse lookup. This tests whether you can resolve the hostname from the IP address.

    dig +short -x your_server_ipv4
    dig +short -x your_server_ipv6

These should both return `ipa.example.com.`

FreeIPA makes heavy use of DNS, so in the next step, we’ll make sure our server meets the specific DNS requirements FreeIPA needs to work properly.

## Step 2 — Setting Up DNS

All machines running FreeIPA must use fully qualified domain names (FQDNs) as their hostnames, which we set up in the previous step. Additionally, the hostname of each server must resolve to its IP address, not to `localhost`.

**Note** : If you are setting up FreeIPA on a server within your LAN, use private IPs instead.

On DigitalOcean, you can see the public IP addresses of your server on the [control panel](https://cloud.digitalocean.com/). You can also find the server IP addresses using the `ip` command.

    ip addr show

This should produce output similar to the following:

    Output. . .
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
        link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
        inet 111.111.111.111/18 brd 111.111.111.255 scope global eth0
           valid_lft forever preferred_lft forever
        inet6 1111:1111:1111:1111::1111:1111/64 scope global
           valid_lft forever preferred_lft forever
    . . .

The IPv4 address appears directly after **inet** and the IPv6 address, if you have it enabled, appears after **inet6**. You may also see additional private IP addresses if you have private networking enabled; you can ignore these addresses. To differentiate between public and private IP addresses, note that private IPv4 addresses will be in the following ranges: `192.168.*.*`, `10.*.*.*`, or `172.16.*.*` to `172.31.*.*`. Private IPv6 addresses will always start with the prefix `fe80::`.

Now we need to change the host file to point the server’s hostname to its external IP address. The hosts file, `/etc/hosts`, maps domain names to IP addresses locally on the machine. Open this file with `nano` or your favorite text editor.

    nano /etc/hosts

Look for the line that has your server hostname after `127.0.0.1`:

/etc/hosts

    . . .
    # The following lines are desirable for IPv4 capable hosts
    127.0.0.1 ipa.example.com ipa.example.com
    127.0.0.1 localhost.localdomain localhost
    127.0.0.1 localhost4.localdomain4 localhost4
    . . .

Change `127.0.01` to your server IPv4 address.

Modified /etc/hosts

    . . .
    # The following lines are desirable for IPv4 capable hosts
    your_server_ipv4 ipa.example.com ipa.example.com
    127.0.0.1 localhost.localdomain localhost
    127.0.0.1 localhost4.localdomain4 localhost4
    . . .

If you have IPv6 enabled you will need to edit the IPv6 mapping as as well, changing the `::1` line with your hostname.

/etc/hosts

    ...
    # The following lines are desirable for IPv6 capable hosts
    ::1 ipa.example.com ipa.example.com
    ::1 localhost.localdomain localhost
    ::1 localhost6.localdomain6 localhost6
    ...

Change `::1` to your server IPv6 address.

Modified /etc/hosts

    ...
    # The following lines are desirable for IPv6 capable hosts
    your_server_ipv6 ipa.example.com ipa.example.com
    ::1 localhost.localdomain localhost
    ::1 localhost6.localdomain6 localhost6
    ...

Save and exit the file.

By default, every time the system boots. CentOS uses the configuration in `/etc/cloud/templates/hosts.redhat.tmpl` to generate `/etc/hosts`. To make this configuration change permanent, we will need to make similar changes in that file as well.

Open the file.

    nano /etc/cloud/templates/hosts.redhat.tmpl

Change the `127.0.0.1 ${fqdn} ${hostname}` line to use your server IPv4 address.

Modified /etc/cloud/templates/hosts.redhat.tmpl

    ...
    # The following lines are desirable for IPv4 capable hosts
    your_server_ipv4 ${fqdn} ${hostname}
    127.0.0.1 localhost.localdomain localhost
    127.0.0.1 localhost4.localdomain4 localhost4
    ...

Similarly, change the `::1 ${fqdn} ${hostname}` line to use your IPv6 address, if you’re using one.

Modified /etc/cloud/templates/hosts.redhat.tmpl

    ...
    # The following lines are desirable for IPv6 capable hosts
    your_server_ipv6 ${fqdn} ${hostname}
    ::1 localhost.localdomain localhost
    ::1 localhost6.localdomain6 localhost6
    ...

Exit and save the file.

Next we will configure the random number generators within CentOS. This will allow FreeIPA to preform the cryptographic functions it needs for authentication.

## Step 3 — Configuring the Random Number Generator

Setting up FreeIPA requires a lot of random data for the cryptographic operations that it runs. By default, a virtual machine will run out of random data or entropy very quickly. To get around this, we will use `rngd`, a software random number generator. `rngd` works by taking data from the hardware devices attached to the server and feeding it into the kernel’s random number generator.

First, install `rngd`.

    yum install rng-tools

Then enable it.

    systemctl start rngd

Make sure the service is automatically started at boot.

    systemctl enable rngd

Finally, verify that `rngd` is running.

    systemctl status rngd

The output should include `active (running)` in green.

With all of the dependencies configured and functioning, we can move on to installing the FreeIPA server software itself.

## Step 4 — Installing the FreeIPA Server

We can move on to installing `ipa-server`, the FreeIPA server package itself.

    yum install ipa-server

Then run the FreeIPA installation command. This will run a script that will prompt you for configuration options and install FreeIPA.

    ipa-server-install

In addition to authentication, FreeIPA has the ability to manage DNS records for hosts. This can make provisioning and managing hosts easier. In this tutorial we will not be using FreeIPA’s integrated DNS. It is not needed for a basic setup.

    Installation script promptDo you want to configure integrated DNS (BIND)? [no]: no

Next, you’ll need to enter the server’s hostname, the domain name, and the Kerberos realm name. Kerberos is an authentication protocol which FreeIPA makes use of behind the scenes for authenticating host machines. It is highly recommended that you use your domain name as the Kerberos realm. Using a different naming scheme will cause problems with FreeIPA’s Active Directory integration, and may cause other issues.

**Warning:** Do not use your root domain (`example.com`) as your IPA domain name. This can cause DNS issues.

    Installation script promptServer host name [ipa.example.org]: ipa.example.org
    Please confirm the domain name [example.org]: ipa.example.org
    Please provide a realm name [EXAMPLE.ORG]: IPA.EXAMPLE.ORG

Next, create a password for the LDAP directory manager. This is needed for FreeIPA’s LDAP functionality. Then the IPA admin password, which will be used when logging into FreeIPA as the admin user. Using secure randomly generated passwords here is highly recommended, as your entire system’s security depends on them.

Confirm the configuration. After this, the installer will run.

    Installation script promptContinue to configure the system with these values? [no]: yes

The install process can take several minutes depending on the speed of your server.

Now that we have a completed server installation, we will need to test it.

## Step 5 — Verifying the FreeIPA Server Functions

First, verify that the Kerberos realm installed correctly by attempting to initialize a Kerberos token for the admin user.

    kinit admin

If working correctly, this should prompt you for the IPA admin password entered during the install process. Type it in, then press `ENTER`.

Next, verify that the IPA server is functioning properly.

    ipa user-find admin

This should print out the following:

    Output--------------
    1 user matched
    --------------
      User login: admin
      Last name: Administrator
      Home directory: /home/admin
      Login shell: /bin/bash
      Principal alias: admin@IPA.EXAMPLE.COM
      UID: 494800000
      GID: 494800000
      Account disabled: False
    ----------------------------
    Number of entries returned 1
    ----------------------------

We should also be able to access the web UI at `https://ipa.example.com`.

**Note** : The TLS certificate will be untrusted. For now, we’ll just bypass the warnings. In the future, you can use your favorite [certificate authority](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs) to get a valid TLS certificate. Once you have it, you’ll need to upload your CA certificate (usually `ca.crt`), certificate file (`your_domain.crt`), and key file ( `your_domain.key`) to the server.

Once you have the files, install the CA using the directory manager password you set earlier. You can precede the command with a space to prevent it from being saved to the shell history.

    ipa-cacert-manage -p your_directory_manager_password -n httpcrt -t C,, install ca.crt

Then install the site certificate and key.

    ipa-server-certinstall -w -d your_domain.key your_domain.crt

You will need to restart your server for these changes to take effect.

In the web UI, log in as the admin user. **Username** will be **admin** and **Password** will be the IPA admin password you set earlier. The top of the page will say **Authenticating…** and then you will be brought to the main IPA page, which looks like this:

![FreeIPA UI main page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freeipa/sYI5paO.jpg)

Finally, let’s explore some of FreeIPA’s features by adding a new user.

## Step 6 — Configuring IPA Users

FreeIPA has a very extensive set of user management and policy features. Similar to standard Unix users, FreeIPA users can belong to groups. Either groups or individual users can be allowed or denied access to hosts (client machines) or groups of hosts (hostgroups) based on policies. FreeIPA can also manage sudo access; groups or users can be granted sudo access on hosts or host groups.

This tutorial will just go over how to add new users to get you started.

To add a user, click the **Identity** tab and click on **Users**. This will display a table of users. Click the **+ Add** button above the table to add a new user. Fill in the required fields (like first and last name) in the form that opens, then click **Add** to add the user as is or **Add and edit** to configure advanced details.

The advanced details can also be accessed by clicking on the user in the original table. This is what an administrator sees when looking at a user’s details:

![FreeIPA UI user edit](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freeipa/TcJR35O.jpg)

Regular users can also log in to the IPA GUI. They will be able to view their own permissions and edit personal details.

New users will be asked to change their password the first time they log in to an IPA machine. This works in the IPA GUI as well as over SSH. One helpful feature is the ability to add SSH keys. A user can upload their public SSH keys and have them propagate out to the IPA machines, allowing passwordless login. The user can then remove the SSH key at any time without having to worry about it still being present on individual servers.

## Conclusion

Now that you have a working FreeIPA server, you will need to [configure clients](http://www.freeipa.org/page/Client) to authenticate against it. You can follow [this Ubuntu 16.04 FreeIPA client tutorial](how-to-configure-a-freeipa-client-on-ubuntu-16-04/) or [this CentOS 7 FreeIPA client tutorial](how-to-configure-a-freeipa-client-on-centos-7) to do so. In addition, FreeIPA is an LDAP server. Any service supporting LDAP authentication can be setup to authenticate against your FreeIPA server.

You can configure users, groups, and access policies through the FreeIPA GUI, or through its CLI. Sudo rules can provide a relatively straightforward way to manage root access. For larger deployments, setting up multiple IPA servers with replication is recommended. Finally, if you would like to bridge into a Windows environment, you can set up a trust to an Active Directory server.

FreeIPA is an extremely versatile authentication tool, and what you will need to do next depends largely on how you intend to use it. For further information, the FreeIPA website has a [list of documentation resources](https://www.freeipa.org/page/Documentation).
