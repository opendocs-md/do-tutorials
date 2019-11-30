---
author: Erika Heidi
date: 2016-03-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-configuration-management
---

# An Introduction to Configuration Management

## Introduction

As a broader subject, configuration management (CM) refers to the process of systematically handling changes to a system in a way that it maintains integrity over time. Even though this process was not originated in the IT industry, the term is broadly used to refer to **server configuration management**.

Automation plays an essential role in server configuration management. It’s the mechanism used to make the server reach a desirable state, previously defined by provisioning scripts using a tool’s specific language and features. Automation is, in fact, the heart of configuration management for servers, and that’s why it’s common to also refer to configuration management tools as _Automation Tools_ or _IT Automation Tools_.

Another common term used to describe the automation features implemented by configuration management tools is _Server Orchestration_ or _IT Orchestration_, since these tools are typically capable of managing one to hundreds of servers from a central controller machine.

There are a number of configuration management tools available in the market. Puppet, Ansible, Chef and Salt are popular choices. Although each tool will have its own characteristics and work in slightly different ways, they are all driven by the same purpose: to make sure the system’s state matches the state described by your provisioning scripts.

## Benefits of Configuration Management for Servers

Although the use of configuration management typically requires more initial planning and effort than manual system administration, all but the simplest of server infrastructures will be improved by the benefits that it provides. To name a few:

### Quick Provisioning of New Servers

Whenever a new server needs to be deployed, a configuration management tool can automate most, if not all, of the provisioning process for you. Automation makes provisioning much quicker and more efficient because it allows tedious tasks to be performed faster and more accurately than any human could. Even with proper and thorough documentation, manually deploying a web server, for instance, could take hours compared to a few minutes with configuration management/automation.

### Quick Recovery from Critical Events

With quick provisioning comes another benefit: quick recovery from critical events. When a server goes offline due to unknown circumstances, it might take several hours to properly audit the system and find out what really happened. In scenarios like this, deploying a replacement server is usually the safest way to get your services back online while a detailed inspection is done on the affected server. With configuration management and automation, this can be done in a quick and reliable way.

### No More Snowflake Servers

At first glance, manual system administration may seem to be an easy way to deploy and quickly fix servers, but it often comes with a price. With time, it may become extremely difficult to know exactly what is installed on a server and which changes were made, when the process is not automated. Manual hotfixes, configuration tweaks, and software updates can turn servers into unique _snowflakes_, hard to manage and even harder to replicate. By using a configuration management tool, the procedure necessary for bringing up a new server or updating an existing one will be all documented in the provisioning scripts.

### Version Control for the Server Environment

Once you have your server setup translated into a set of provisioning scripts, you will have the ability to apply to your server environment many of the tools and workflows you normally use for software source code.

Version control tools, such as Git, can be used to keep track of changes made to the provisioning and to maintain separate branches for legacy versions of the scripts. You can also use version control to implement a _code review_ policy for the provisioning scripts, where any changes should be submitted as a pull request and approved by a project lead before being accepted. This practice will add extra consistency to your infrastructure setup.

### Replicated Environments

Configuration management makes it trivial to replicate environments with the exact same software and configurations. This enables you to effectively build a multistage ecosystem, with production, development, and testing servers. You can even use local virtual machines for development, built with the same provisioning scripts. This practice will minimize problems caused by environment discrepancies that frequently occur when applications are deployed to production or shared between co-workers with different machine setups (different operating system, software versions and/or configurations).

## Overview of Configuration Management Tools

Even though each _CM_ tool has its own terms, philosophy and ecosystem, they typically share many characteristics and have similar concepts.

Most configuration management tools use a controller/master and node/agent model. Essentially, the controller directs the configuration of the nodes, based on a series of instructions or _tasks_ defined in your provisioning scripts.

Below you can find the most common features present in most configuration management tools for servers:

### Automation Framework

Each CM tool provides a specific syntax and a set of features that you can use to write provisioning scripts. Most tools will have features that make their language similar to conventional programming languages, but in a simplified way. Variables, loops, and conditionals are common features provided to facilitate the creation of more versatile provisioning scripts.

### Idempotent Behavior

Configuration management tools keep track of the state of resources in order to avoid repeating tasks that were executed before. If a package was already installed, the tool won’t try to install it again. The objective is that after each provisioning run the system reaches (or keeps) the desired state, even if you run it multiple times. This is what characterizes these tools as having an _idempotent behavior_. This behavior is not necessarily enforced in all cases, though.

### System Facts

Configuration management tools usually provide detailed information about the system being provisioned. This data is available through global variables, known as _facts_. They include things like network interfaces, IP addresses, operating system, and distribution. Each tool will provide a different set of _facts_. They can be used to make provisioning scripts and templates more adaptive for multiple systems.

### Templating System

Most CM tools will provide a built-in templating system that can be used to facilitate setting up configuration files and services. Templates usually support variables, loops, and conditionals that can be used to maximise versatility. For instance, you can use a template to easily set up a new virtual host within Apache, while reusing the same template for multiple server installations. Instead of having only hard-coded, static values, a template should contain placeholders for values that can change from host to host, such as `NameServer` and `DocumentRoot`.

### Extensibility

Even though provisioning scripts can be very specialized for the needs and demands of a particular server, there are many cases when you have similar server setups or parts of a setup that could be shared between multiple servers. Most provisioning tools will provide ways in which you can easily reuse and share smaller chunks of your provisioning setup as modules or plugins.

Third-party modules and plugins are often easy to find on the Internet, specially for common server setups like installing a PHP web server. CM tools tend to have a strong community built around them and users are encouraged to share their custom extensions. Using extensions provided by other users can save you a lot of time, while also serving as an excellent way of learning how other users solved common problems using your tool of choice.

## Choosing a Configuration Management Tool

There are many CM tools available in the market, each one with a different set of features and different complexity levels. Popular choices include Chef, Ansible, and Puppet. The first challenge is to choose a tool that is a good fit for your needs.

There are a few things you should take into consideration before making a choice:

### Infrastructure Complexity

Most configuration management tools require a minimum hierarchy consisting of a controller machine and a node that will be managed by it. Puppet, for example, requires an _agent_ application to be installed on each node, and a _master_ application to be installed on the controller machine. Ansible, on the other hand, has a decentralized structure that doesn’t require installation of additional software on the nodes, but relies on SSH to execute the provisioning tasks. For smaller projects, a simplified infrastructure might seem like a better fit, however it is important to take into consideration aspects like scalability and security, which may not be enforced by the tool.

Some tools can have more components and moving parts, which might increase the complexity of your infrastructure, impacting on the learning curve and possibly increasing the overall cost of implementation.

### Learning Curve

As mentioned earlier in this article, CM tools provide a custom syntax, sometimes using a Domain Specific Language (DSL), and a set of features that comprise their framework for automation. As with conventional programming languages, some tools will demand a higher learning curve to be mastered. The infrastructure requirements might also influence the complexity of the tool and how quickly you will be able to see a return of investment.

### Cost

Most CM tools offer free or open source versions, with paid subscriptions for advanced features and services. Some tools will have more limitations than others, so depending on your specific needs and how your infrastructure grows, you might end up having to pay for these services. You should also consider training as a potential extra cost, not only in monetary terms, but also regarding the time that will be necessary to get your team up to speed with the tool you end up choosing.

### Advanced Tooling

As mentioned before, most tools offer paid services that can include support, extensions, and advanced tooling. It’s important to analyse your specific needs, the size of your infrastructure and whether or not there is a need for using these services. Management panels, for instance, are a common service offered by these tools, and they can greatly facilitate the process of managing and monitoring all your servers from a central point. Even if you don’t need such services just yet, consider the options for a possible future necessity.

### Community and Support

A strong and welcoming community can be extremely resourceful for support and for documentation, since users are typically happy to share their knowledge and their extensions (modules, plugins, and provisioning scripts) with other users. This can be helpful to speed up your learning curve and avoid extra costs with paid support or training.

## Overview of Popular Tools

The table below should give you a quick overview of the main differences between three of the most popular configuration management tools available in the market today: Ansible, Puppet, and Chef.

| | **Ansible** | **Puppet** | **Chef** |
| --- | --- | --- | --- |
| **Script Language** | YAML | Custom DSL based on Ruby | Ruby |
| **Infrastructure** | Controller machine applies configuration on nodes via SSH | Puppet Master synchronizes configuration on Puppet Nodes | Chef Workstations push configuration to Chef Server, from which the Chef Nodes will be updated |
| **Requires specialized software for nodes** | No | Yes | Yes |
| **Provides centralized point of control** | No. Any computer can be a controller | Yes, via Puppet Master | Yes, via Chef Server |
| **Script Terminology** | Playbook / Roles | Manifests / Modules | Recipes / Cookbooks |
| **Task Execution Order** | Sequential | Non-Sequential | Sequential |

## Next Steps

So far, we’ve seen how configuration management works for servers, and what to consider when choosing a tool for building your configuration management infrastructure. In subsequent guides in this series, we will have a hands-on experience with three popular configuration management tools: Ansible, Puppet and Chef.

In order to give you a chance to compare these tools by yourself, we are going to use a simple example of server setup that should be fully automated by each tool. This setup consists of an Ubuntu 18.04 server running Apache to host a simple web page.

## Conclusion

Configuration management can drastically improve the integrity of servers over time by providing a framework for automating processes and keeping track of changes made to the system environment. [In the next guide](configuration-management-101-writing-ansible-playbooks) in this series, we will see how to implement a configuration management strategy in practice using _Ansible_ as tool.
