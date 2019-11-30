---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-saltstack-terminology-and-concepts
---

# An Introduction to SaltStack Terminology and Concepts

## Introduction

Salt, or SaltStack, is a remote execution tool and configuration management system. The remote execution capabilities allow administrators to run commands on various machines in parallel with a flexible targeting system. The configuration management functionality establishes a client-server model to quickly, easily, and securely bring infrastructure components in line with a given policy.

In this guide, we will discuss some of the basic concepts and terminology needed to begin effectively learning to use Salt.

## Salt Machine Roles

Salt’s control structure is fairly simple as configuration management systems go. In a typical setup, there are only two distinct classes of machines.

### Master

The Salt **master** is the machine that controls the infrastructure and dictates policies for the servers it manages. It operates both as a repository for configuration data and as the control center that initiates remote commands and ensures the state of your other machines. A daemon called `salt-master` is installed on the master to provide this functionality.

While it is possible to control infrastructure using a masterless configuration, most setups benefit from the advanced features available in the Salt master. In fact, for larger infrastructure management, Salt has the ability to delegate certain components and tasks typically associated with the master to dedicated servers. It can also operate in a tiered master configuration where commands can be relayed through lower master machines.

### Minions

The servers that Salt manages are called **minions**. A daemon called `salt-minion` is installed on each of the managed machines and configured to communicate with the master. The minion is responsible for executing the instructions sent by the master, reporting on the success of jobs, and providing data about the underlying host.

## How Salt Components Communicate

Salt masters and minions, by default, communicate using the ZeroMQ messaging library. This provides extremely high performance network communication between parties, allowing Salt to send messages and data at rapid speeds. Because ZeroMQ is a library and not an independent service, this functionality is available in the `salt-master` and `salt-minion` daemons natively.

When using ZeroMQ, Salt maintains a public key system for authenticating masters and minions. Upon first boot, a minion generates a key pair and sends its credentials to the master server it is configured to contact. The master can then accept this key after verifying the identity of the minion. The two parties can then communicate quickly and securely using ZeroMQ encrypted with the keys.

If for some reason it is impossible to install the `salt-minion` daemon on a node, Salt can also issue commands over SSH. This transport option is provided for convenience, but it degrades performance quite considerably and can lead to complications with other Salt commands in some instances. It is highly recommended that you use the `salt-minion` daemon where possible for performance, security, and simplicity.

## Salt Terminology

Before diving into Salt, it is a good idea to familiarize yourself with some of the terminology that will be used. Salt has many powerful features, but it can be difficult to match names with their functionality at first. Let’s take a look at some of the more general terms you are likely to see.

### Remote Execution: Execution Modules and Functions

Salt attempts to provide a distinction between its remote execution and configuration management functions. The remote execution capabilities are provided by **execution modules**. Execution modules are sets of related **functions** that perform work on minions.

While Salt includes functions that allow you to run arbitrary shell commands on minions, the idea behind execution modules is to provide a concise mechanism for executing commands without having to “shell out” and provide detailed instructions about how to complete the process. The use of modules allows Salt to abstract the underlying differences between systems. You can get similar information from minions running Linux or BSD, even though the actual mechanisms to gather that data would be different.

Salt comes with a decent selection of [builtin execution modules](https://docs.saltstack.com/en/stage/ref/modules/all/index.html) to provide out-of-the-box functionality. Administrators can also write their own modules or include [community-written modules](https://github.com/saltstack/salt-contrib/tree/master/modules) to extend the library of commands that can be executed on minion machines.

### Configuration Management: States, Formulas, and Templates

The configuration management functionality of Salt can be accessed by creating repositories of configuration files. The files contained within these repositories can be of a few different types.

#### States and Formulas

The configuration management portion of Salt is primarily implemented using the **state** system.

The state system uses **state modules** , which are distinct from the execution modules described above. Fortunately, state and execution modules tend to mirror each other quite closely. The state system is aptly named, as it allows an administrator to describe the state that a system should be placed in. As with execution modules, most state modules represent functionality shortcuts and provide easy syntax for many common actions. This helps maintain readability and removes the necessity of including complex logic in the configuration management files themselves.

Salt **formulas** are sets of state module calls, arranged with the aim of producing a certain result. These are the configuration management files that describe how a system should look once the formula has been applied. By default, these are written in the YAML data serialization format, which provides a very good middle ground between high-readability and machine-friendliness.

The Salt administrator can apply formulas by mapping minions to specific sets of formulas. Formulas can also be applied in an ad hoc manner as needed. Minions will execute the state modules found within to bring its system in line with the provided policy.

A good collection of Salt formulas created by the SaltStack organization and community can by found in [this GitHub account](https://github.com/saltstack-formulas).

#### Templates

**Templating** allows Salt formulas and other files to be written in a more flexible manner. Templates can use the information available about the minions to construct customized versions of formula or configuration files. By default, Salt uses the Jinja template format, which provides substitution functionality and simple logical constructs for decision making.

**Renderers** are the components that runs the template to produce valid state or configuration files. Renderers are defined by the templating format that constitutes the input and the data serialization format that will be produced as an output. Considering the defaults described above, the default renderer processes Jinja templates in order to produce YAML files.

### Querying about and Assigning Information to Minions

In order to manage vast numbers of systems, Salt requires some information about each of the host systems. The templates described above can use data associated with each system to tailor the behavior of each minion. There are a few different systems in place to query about or assign this information to hosts.

#### Grains

Salt **grains** are pieces of information, gathered by and maintained by a minion, primarily concerning its underlying host system. These are typically collected by the `salt-minion` daemon and passed back to the master upon request. This functionality can be leveraged for many different purposes.

For instance, grain data can be used for targeting a specific subset of nodes from the pool of minions for remote execution or configuration management. If you want to see the uptime of your Ubuntu servers, grains allow you to target only these machines.

Grains can also be used as arguments for configuration changes or commands. For example, you can use grains to get the IPv4 address associated with the `eth0` interface for a change to a configuration file or as an argument to a command.

Administrators can also assign grains to minions. For instance, it is fairly common to use grains to assign a “role” to a server. This can then be used to target a subset of nodes similar to the operating system example above.

#### Pillars

While it is possible to assign grains to minions, the vast majority of configuration variables will be assigned through the **pillars** system. In Salt, a pillar represents a key-value store that a minion can use to retrieve arbitrary assigned data. This functions as a dictionary data structure which can be nested or tiered for organizational purposes.

Pillars offer a few important advantages over the grain system for assigning values. Most importantly, pillar data is only available to the minions assigned to it. Other minions will not have access to the values stored within. This makes it ideal for storing sensitive data specific to a node or a subset of nodes. For instance, secret keys or database connection strings are often provided in a pillar configuration.

Pillar data is often leveraged in the configuration management context as a way to inject variable data into a configuration template. Salt offers a selection of template formats for replacing the variable portions of a configuration file with the items specific to the node that will be applying it. Grains are also often used in this way for referencing host data.

#### Mine

Salt **mine** is an area on the master server where the results from regularly executed commands on minions can be stored. The purpose of this system is to collect the results of arbitrary commands run on minion machines. This global store can then be queried by other components and minions throughout your infrastructure.

The Salt mine only stores the most recent result for each command run, meaning that it will not help you if you need access to historic data. The main purpose of the mine is to provide up-to-date information from minion machines as a flexible supplement to the grain data that is already available. Minions can query data about their counterparts using the mine system. The interval in which the minion refreshes the data in the mine can be configured on a per-minion basis.

### Additional Functionality

Salt provides a few other systems that do not fit nicely into the above categories.

#### Reactors

The Salt **reactor** system provides a mechanism for triggering actions in response to generated events. In Salt, changes occurring throughout your infrastructure will cause the `salt-minion` or `salt-master` daemons to generate events on a ZeroMQ message bus. The reactor system watches this bus and compares events against its configured reactors in order to respond appropriately.

The main goal of the reactor system is to provide a flexible system for creating automated situational responses. For instance, if you have developed an auto-scaling strategy, your system will automatically create nodes to dynamically meet your resource demands. Each new node would trigger an event. A reactor could be set up to listen to these events and configure the new node, incorporating it into the existing infrastructure.

#### Runners

Salt **runners** are modules that execute on the master server instead of minions. Some runners are general purpose utilities used to check the status of various parts of the system or to do maintenance. Some are powerful applications that provide the ability to orchestrate your infrastructure on a broader scale.

#### Returners

Salt **returners** are used to specify alternative locations where the results of an action run on a minion will be sent. By default, minions return their data to the master. A returner allows the administrator to re-route the return data to a different destination. Typically, this means that the results are returned to the destination specified by the returner _and_ to the process that initiated the minion command.

Most often, returners will pass the results off to a database system or a metrics or logging service. This provides a flexible method for getting arbitrary data into these systems. Returners can also be used to collect Salt-specific data like job caches and event data.

## Salt Commands

Salt provides a number of commands to take advantage of the components outlined above. There is some significant crossover in terms of functionality between these tools, but we’ve attempted to highlight their primary functions below.

- **`salt-master`** : This is the master daemon process. You can start the master service with this command directly, or more typically, through an init script or service file.
- **`salt-minion`** : Likewise, this is minion daemon process, used to communicate with the master and execute commands. Most users will also start this from init scripts or service files.
- **`salt-key`** : This tool is used to manage minion public keys. This tool is used to view current keys and to make decisions about public keys sent by prospective minions. It can also generate keys to place on minions out-of-band.
- **`salt`** : This command is used to target minions in order to run ad-hoc execution modules. This is the main tool used for remote execution.
- **`salt-ssh`** : This command allows you to use SSH as an alternative to ZeroMQ for the transport mechanism.
- **`salt-run`** : This command is used to run runner modules on the master server.
- **`salt-call`** : This command is used to run execution modules directly on a minion you are logged into. This is often used to debug problematic commands by bypassing the master.
- **`salt-cloud`** : This command is used to control and provision cloud resources from many different providers. New minions can easily be spun up and bootstrapped.

There are some other commands as well, like `salt-api`, `salt-cp`, and `salt-syndic`, which aren’t used quite so often.

## Conclusion

Now that you are familiar with the basic SaltStack terminology and have a high level understanding of what the tools you’ll encounter are responsible for, you can begin setting up Salt to control your infrastructure. In the [next guide](how-to-install-and-configure-salt-master-and-minion-servers-on-ubuntu-14-04), we will cover how to install and configure a Salt master server on an Ubuntu 14.04 server. We will also demonstrate how to configure new minion servers to bring them under your master’s management.
