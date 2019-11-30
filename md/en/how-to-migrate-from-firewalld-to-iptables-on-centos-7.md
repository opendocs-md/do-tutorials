---
author: Justin Ellingwood
date: 2015-08-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-migrate-from-firewalld-to-iptables-on-centos-7
---

# How To Migrate from FirewallD to Iptables on CentOS 7

## Introduction

Like most other Linux distributions, CentOS 7 uses the `netfilter` framework inside the Linux kernel in order to access packets that flow through the network stack. This provides the necessary interface to inspect and manipulate packets in order to implement a firewall system.

Most distributions use the `iptables` firewall, which uses the `netfilter` hooks to enforce firewall rules. CentOS 7 comes with an alternative service called `firewalld` which fulfills this same purpose.

While `firewalld` is a very capable firewall solution with great features, it may be easier for some users to stick with `iptables` if they are comfortable with its syntax and happy with its behavior and performance. The `iptables` _command_ is actually used by `firewalld` itself, but the `iptables` _service_ is not installed on CentOS 7 by default. In this guide, we’ll demonstrate how to install the `iptables` service on CentOS 7 and migrate your firewall from `firewalld` to `iptables` (check out [this guide](how-to-set-up-a-firewall-using-firewalld-on-centos-7) if you’d like to learn how to use FirewallD instead).

## Save your Current Firewall Rules (Optional)

Before making the switch to `iptables` as your server’s firewall solution, it is a good idea to save the current rules that `firewalld` is enforcing. We mentioned above that the `firewalld` daemon actually leverages the `iptables` command to speak to the `netfilter` kernel hooks. Because of this, we can dump the current rules using the `iptables` command.

Dump the current set of rules to standard output and to a file in your home directory called `firewalld_iptables_rules` by typing:

    sudo iptables -S | tee ~/firewalld_iptables_rules

Do the same with `ip6tables`:

    sudo ip6tables -S | tee ~/firewalld_ip6tables_rules

Depending on the `firewalld` zones that were active, the services that were enabled, and the rules that were passed from `firewall-cmd` directly to `iptables`, the dumped rule set might be quite extensive.

The `firewalld` service implements its firewall policies using normal `iptables` rules.It accomplishes this by building a management framework using `iptables` chains. Most of the rules you are likely to see will be used to create these management chains and direct the flow of traffic in and out of these structures.

The firewall rules you end up moving over to your `iptables` service will not need to recreate the management framework that `firewalld` relies on. Because of this, the rule set you end up implementing will likely be much simpler. We are saving the entire set here in order to keep as much raw data intact as possible.

You can see some of the more essential lines to get an idea of the policy you’ll have to recreate by typing something like this:

    grep 'ACCEPT\|DROP\|QUEUE\|RETURN\|REJECT\|LOG' ~/firewalld_iptables_rules

This will mostly display the rules that result in a final decision. Rules that only jump to user-created chains will not be shown.

## Download and Install the Iptables Service

To begin your server’s transition, you need to download and install the `iptables-service` package from the CentOS repositories.

Download and install the service files by typing:

    sudo yum install iptables-services

This will download and install the `systemd` scripts used to manage the `iptables` service. It will also write some default `iptables` and `ip6tables` configuration files to the `/etc/sysconfig` directory.

## Construct your Iptables Firewall Rules

Next, you need to construct your `iptables` firewall rules by modifying the `/etc/sysconfig/iptables` and `/etc/sysconfig/ip6tables` files. These files hold the rules that will be read and applied when we start the `iptables` service.

How you construct your firewall rules depends on whether the `system-config-firewall` process is installed and being used to manage these files. Check the top of the `/etc/sysconfig/iptables` file to see whether it recommends against manual editing or not:

    sudo head -2 /etc/sysconfig/iptables

If the output looks like this, feel free to manually edit the `/etc/sysconfig/iptables` and `/etc/sysconfig/ip6tables` files to implement the policies for your `iptables` firewall:

    output# sample configuration for iptables service
    # you can edit this manually or use system-config-firewall

Open and edit the files with `sudo` privileges to add your rules:

    sudo nano /etc/sysconfig/iptables
    sudo nano /etc/sysconfig/ip6tables

After you’ve made your rules, you can test your IPv4 and IPv6 rules using these commands:

    sudo sh -c 'iptables-restore -t < /etc/sysconfig/iptables'
    sudo sh -c 'ip6tables-restore -t < /etc/sysconfig/ip6tables'

If, on the other hand, the output from examining the `/etc/sysconfig/iptables` file looks like this, you should not manually edit the file:

    output# Firewall configuration written by system-config-firewall
    # Manual customization of this file is not recommended.

This means that the `system-config-firewall` management tool is installed and being used to manage this file. Any manual changes will be overwritten by the tool. If you see this, you should make changes to your firewall using one of the associated tools. For the text UI, type:

    sudo system-config-firewall-tui

If you have the graphical UI installed, you can launch it by typing:

    sudo system-config-firewall

If you need some help learning about `iptables` rules and syntax, the following guides may be helpful even though they are mainly targeted at Ubuntu systems:

- [How To Set Up a Firewall Using Iptables on Ubuntu 14.04](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04)
- [Iptables Essentials: Common Firewall Rules and Commands](iptables-essentials-common-firewall-rules-and-commands)
- [How To Implement a Basic Firewall Template with Iptables on Ubuntu 14.04](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04)

## Stop the FirewallD Service and Start the Iptables Service

Next, we need to stop the current `firewalld` firewall and bring up our `iptables` services. We will use the `&&` construct to start the new firewall services as soon as the `firewalld` service successfully shuts down:

    sudo systemctl stop firewalld && sudo systemctl start iptables; sudo systemctl start ip6tables

You can verify that `firewalld` is not running by typing:

    sudo firewall-cmd --state

You can also see that the rules you set up in the `/etc/sysconfig` directory have been loaded and applied by typing:

    sudo iptables -S
    sudo ip6tables -S

At this point, the `iptables` and `ip6tables` services are active for the current session. However, currently, the `firewalld` service is still the one that will start automatically when the server reboots.

This is best time to test your firewall policies to make sure that you have the level of access that you need, because you can restart the server to revert to your old firewall if there are any issues.

## Disable the FirewallD Service and Enable the Iptables Services

After testing your firewall rules to ensure that your policy is correctly being enforced, you can go ahead and disable the `firewalld` service by typing:

    sudo systemctl disable firewalld

This will prevent the service from starting automatically at boot. Since the `firewalld` service should not be started manually while the `iptables` services are running either, you can take an extra step by masking the service. This will prevent the `firewalld` service from being started manually as well:

    sudo systemctl mask firewalld

Now, you can enable your `iptables` and `ip6tables` services so that they will start automatically at boot:

    sudo systemctl enable iptables
    sudo systemctl enable ip6tables

This should complete your firewall transition.

## Conclusion

Implementing a firewall is an essential step towards keeping your servers secure. While `firewalld` is a great firewall solution, sometimes using the most familiar tool or using the same systems across more diverse infrastructure makes the most sense.
