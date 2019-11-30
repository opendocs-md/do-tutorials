---
author: Justin Ellingwood
date: 2016-12-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-multistage-environments-with-ansible
---

# How to Manage Multistage Environments with Ansible

## Introduction

Ansible is a powerful configuration management system used to set up and manage infrastructure and applications in varied environments. While Ansible provides easy-to-read syntax, flexible workflows, and powerful tooling, it can be challenging to manage large numbers of hosts when they vary by deployment environment and functionality.

In this guide, we will discuss some strategies for using Ansible to work with multistage deployment environments. Typically, the requirements for different stages will lead to different numbers and configurations of components. For example, the memory requirements for a development server might be different than those for staging and production and it’s important to have explicit control over how the variables that represent those requirements are prioritized. In this article, we will discuss some ways that these differences can be abstracted and some constructs that Ansible provides to encourage configuration reuse.

## Incomplete Strategies for Managing Multistage Environment with Ansible

While there are a number of ways that you can manage environments within Ansible, Ansible itself does not offer an opinionated solution. Rather, it provides many constructs that can be used for managing environments and allows the user to choose.

The approach we will demonstrate in this guide relies on Ansible **group variables** and **multiple inventories**. However, there are several other strategies that are worth considering. We will explore some of these ideas below and why they might present problems when implemented in complex environments.

If you want to get started with Ansible’s recommended strategy, skip ahead to the section on [using Ansible groups and multiple inventories](how-to-manage-multistage-environments-with-ansible#ansible-recommended-strategy-using-groups-and-multiple-inventories).

### Relying Solely on Group Variables

At first glance, it may appear that group variables provide all of the separation between environments that Ansible requires. You can designate certain servers as belonging to your development environment, and others can be assigned to the staging and production areas. Ansible makes it easy to create groups and assign variables to them.

Group intersection, however, brings serious problems for this system. Groups are often used to categorize more than one dimension. For example:

- deployment environments (local, dev, stage, prod, etc.)
- host functionality (web servers, database servers, etc.)
- datacenter region (NYC, SFO, etc.)

In these cases, hosts will usually be in one group per category. For example, a host may be a web server (functional) on stage (deployment environment) in NYC (datacenter region).

If the same variable is set by more than one group for a host, Ansible has no way of explicitly specifying precedence. You may prefer the variables associated with the deployment environments to override other values, but Ansible doesn’t provide a way to define this.

Instead, **Ansible uses the last loaded value**. Since Ansible evaluates groups alphabetically, the variable associated with whichever group name happens to be last in dictionary ordering will win. This is predictable behavior, but explicitly managing group name alphabetization is less than ideal from an administrative perspective.

### Using Group Children to Establish a Hierarchy

Ansible allows you to assign groups to other groups using the `[groupname:children]` syntax in the inventory. This gives you the ability to name certain groups members of other groups. Children groups have the ability to override variables set by the parent groups.

Typically, this is used for natural classification. For example, we could have a group called `environments` that includes the groups `dev`, `stage`, `prod`. This means we could set variables in the `environment` group and override them in the `dev` group. You could similarly have a parent group called `functions` that contains the groups `web`, `database`, and `loadbalancer`.

This usage does not solve the problem of group intersection since child groups only override their parents. Child groups can override variables within the parent, but the above organization has not established any relationship between group categories, like `environments` and `functions`. The variable precedence between the two categories is still undefined.

It _is_ possible to exploit this system by setting non-natural group membership. For instance, if you want to establish the following precedence, from highest priority to lowest:

- development environment
- region
- function

You could assign group membership that looks like this:

Example inventory

    . . .
    [function:children]
    web
    database
    loadbalancer
    region
    
    [region:children]
    nyc
    sfo
    environments
    
    [environments:children]
    dev
    stage
    prod

We’ve established a hierarchy here that allows regional variables to override the functional variables since the `region` group is a child of the `function` group. Likewise, variables set in the `environments` groups can override any of the others. This means that if we set the same variable to a different value in the `dev`, `nyc`, and `web` groups, a host belonging to each of these would use the variable from `dev`.

This achieves the desired outcome and is also predictable. However, it is unintuitive, and it muddles the distinction between true children and children needed to establish the hierarchy. Ansible is designed so that its configuration is clear and easy to follow even for new users. This type of work around compromises that goal.

### Using Ansible Constructs that Allow Explicit Loading Order

There are a few constructs within Ansible that allow explicit variable load ordering, namely `vars_files` and `include_vars`. These can be used within [Ansible plays](configuration-management-101-writing-ansible-playbooks) to explicitly load additional variables in the order defined within the file. The `vars_files` directive is valid within the context of a play, while the `include_vars` module can be used in tasks.

The general idea is to set only basic identifying variables in `group_vars` and then leverage these to load the correct variable files with the rest of the desired variables.

For instance, a few of the `group_vars` files might look like this:

group\_vars/dev

    ---
    env: dev

group\_vars/stage

    ---
    env: stage

group\_vars/web

    ---
    function: web

group\_vars/database

    ---
    function: database

We would then have a separate vars file that defines the important variables for each group. These are typically kept in a separate `vars` directory for clarity. Unlike `group_vars` files, when dealing with `include_vars`, files must include a `.yml` file extension.

Let’s pretend that we need to set the `server_memory_size` variable to a different value in each `vars` file. Your development servers will likely be smaller than your production servers. Furthermore, your web servers and database servers might have different memory requirements:

vars/dev.yml

    ---
    server_memory_size: 512mb

vars/prod.yml

    ---
    server_memory_size: 4gb

vars/web.yml

    ---
    server_memory_size: 1gb

vars/database.yml

    ---
    server_memory_size: 2gb

We could then create a playbook that explicitly loads the correct `vars` file based on the values assigned to the host from the `group_vars` files. The order of the files loaded will determine the precedence, with the last value winning.

With `vars_files`, an example play would look like this:

example\_play.yml

    ---
    - name: variable precedence test
      hosts: all
      vars_files:
        - "vars/{{ env }}.yml"
        - "vars/{{ function }}.yml"
      tasks:
        - debug: var=server_memory_size

Since the functional groups are loaded last, the `server_memory_size` value would be taken from the `var/web.yml` and `var/database.yml` files:

    ansible-playbook -i inventory example_play.yml

    Output. . .
    TASK [debug] *******************************************************************
    ok: [host1] => {
        "server_memory_size": "1gb" # value from vars/web.yml
    }
    ok: [host2] => {
        "server_memory_size": "1gb" # value from vars/web.yml
    }
    ok: [host3] => {
        "server_memory_size": "2gb" # value from vars/database.yml
    }
    ok: [host4] => {
        "server_memory_size": "2gb" # value from vars/database.yml
    }
    . . .

If we switch the ordering of the files to be loaded, we can make the deployment environment variables higher priority:

example\_play.yml

    ---
    - name: variable precedence test
      hosts: all
      vars_files:
        - "vars/{{ function }}.yml"
        - "vars/{{ env }}.yml"
      tasks:
        - debug: var=server_memory_size

Running the playbook again shows values being applied from the deployment environment files:

    ansible-playbook -i inventory example_play.yml

    Output. . .
    TASK [debug] *******************************************************************
    ok: [host1] => {
        "server_memory_size": "512mb" # value from vars/dev.yml
    }
    ok: [host2] => {
        "server_memory_size": "4gb" # value from vars/prod.yml
    }
    ok: [host3] => {
        "server_memory_size": "512mb" # value from vars/dev.yml
    }
    ok: [host4] => {
        "server_memory_size": "4gb" # value from vars/prod.yml
    }
    . . .

The equivalent playbook using `include_vars`, which operates as a task, would look like:

    ---
    - name: variable precedence test
      hosts: localhost
      tasks:
        - include_vars:
            file: "{{ item }}"
          with_items:
            - "vars/{{ function }}.yml"
            - "vars/{{ env }}.yml"
        - debug: var=server_memory_size

This is one area where Ansible allows explicit ordering, which can be very useful. However, as with the previous examples, there are some significant drawbacks.

First of all, using `vars_files` and `include_vars` requires you to place variables that are tightly tied to groups in a different location. The `group_vars` location becomes a stub for the actual variables located in the `vars` directory. This once again adds complexity and decreases clarity. The user must match the correct variable files to the host, which is something that Ansible does automatically when using `group_vars`.

More importantly, relying on these techniques makes them mandatory. Every playbook will require a section that explicitly loads the correct variable files in the correct order. Playbooks without this will be unable to use the associated variables. Furthermore, running the `ansible` command for ad-hoc tasks will be almost entirely impossible for anything relying on variables.

## Ansible Recommended Strategy: Using Groups and Multiple Inventories

So far, we’ve looked at some strategies for managing multistage environments and discussed reasons why they may not be a complete solution. However, the Ansible project does offer some suggestions on how best to abstract your infrastructure across environments.

The recommended approach is to work with multistage environments by completely separating each operating environment. Instead of maintaining all of your hosts within a single inventory file, an inventory is maintained for each of your individual environments. Separate `group_vars` directories are also maintained.

The basic directory structure will look something like this:

    .
    ├── ansible.cfg
    ├── environments/ # Parent directory for our environment-specific directories
    │   │
    │   ├── dev/ # Contains all files specific to the dev environment
    │   │   ├── group_vars/ # dev specific group_vars files
    │   │   │   ├── all
    │   │   │   ├── db
    │   │   │   └── web
    │   │   └── hosts # Contains only the hosts in the dev environment
    │   │
    │   ├── prod/ # Contains all files specific to the prod environment
    │   │   ├── group_vars/ # prod specific group_vars files
    │   │   │   ├── all
    │   │   │   ├── db
    │   │   │   └── web
    │   │   └── hosts # Contains only the hosts in the prod environment
    │   │
    │   └── stage/ # Contains all files specific to the stage environment
    │   ├── group_vars/ # stage specific group_vars files
    │   │   ├── all
    │   │   ├── db
    │   │   └── web
    │   └── hosts # Contains only the hosts in the stage environment
    │
    ├── playbook.yml
    │
    └── . . .

As you can see, each environment is distinct and compartmentalized. The environment directories contain an inventory file (arbitrarily named `hosts`) and a separate `group_vars` directory.

There is some obvious duplication in the directory tree. There are `web` and `db` files for each individual environment. In this case, the duplication is desirable. Variable changes can be rolled out across environments by first modifying variables in one environment and moving them to the next after testing, just as you would with code or configuration changes. The `group_vars` variables track the current defaults for each environment.

One limitation is the inability to select all hosts by function across environments. Fortunately, this falls into the same category as the variable duplication problem above. While it is occasionally useful to select all of your web servers for a task, you almost always want to roll out changes across your environments one at a time. This helps prevent mistakes from affecting your production environment.

### Setting Cross-Environment Variables

One thing that is not possible in the recommended setup is variable sharing across environments. There are a number of ways we could implement cross-environment variable sharing. One of the simplest is to leverage Ansible’s ability to use directories in place of files. We can replace the `all` file within each `group_vars` directory with an `all` directory.

Inside the directory, we can set all environment-specific variables in a file again. We can then create a symbolic link to a file location that contains cross-environment variables. Both of these will be applied to all hosts within the environment.

Begin by creating a cross-environment variables file somewhere in the hierarchy. In this example, we’ll place it in the `environments` directory. Place all cross-environment variables in that file:

    cd environments
    touch 000_cross_env_vars

Next, move into one of the `group_vars` directory, rename the `all` file, and create the `all` directory. Move the renamed file into the new directory:

    cd dev/group_vars
    mv all env_specific
    mkdir all
    mv env_specific all/

Next, you can create a symbolic link to the cross-environmental variable file:

    cd all/
    ln -s ../../../000_cross_env_vars .

When you have completed the above steps for each of your environments, your directory structure will look something like this:

    .
    ├── ansible.cfg
    ├── environments/
    │   │
    │   ├── 000_cross_env_vars
    │   │
    │   ├── dev/
    │   │   ├── group_vars/
    │   │   │   ├── all/
    │   │   │   ├── 000_cross_env_vars -> ../../../000_cross_env_vars
    │   │   │   │   └── env_specific
    │   │   │   ├── db
    │   │   │   └── web
    │   │   └── hosts
    │   │
    │   ├── prod/
    │   │   ├── group_vars/
    │   │   │   ├── all/
    │   │   │   │   ├── 000_cross_env_vars -> ../../../000_cross_env_vars
    │   │   │   │   └── env_specific
    │   │   │   ├── db
    │   │   │   └── web
    │   │   └── hosts
    │   │
    │   └── stage/
    │   ├── group_vars/
    │   │   ├── all/
    │   │   │   ├── 000_cross_env_vars -> ../../../000_cross_env_vars
    │   │   │   └── env_specific
    │   │   ├── db
    │   │   └── web
    │   └── hosts
    │
    ├── playbook.yml
    │
    └── . . .

The variables set within `000_cross_env_vars` file will be available to each of the environments with a low priority.

### Setting a Default Environment Inventory

It is possible to set a default inventory file in the `ansible.cfg` file. This is a good idea for a few reasons.

First, it allows you to leave off explicit inventory flags to `ansible` and `ansible-playbook`. So instead of typing:

    ansible -i environments/dev -m ping

You can access the default inventory by typing:

    ansible -m ping

Secondly, setting a default inventory helps prevent unwanted changes from accidentally affecting staging or production environments. By defaulting to your development environment, the least important infrastructure is affected by changes. Promoting changes to new environments then is an explicit action that requires the `-i` flag.

To set a default inventory, open your `ansible.cfg` file. This may be in your project’s root directory or at `/etc/ansible/ansible.cfg` depending on your configuration.

**Note:** The example below demonstrates editing an `ansible.cfg` file in a project directory. If you are using the `/etc/ansibile/ansible.cfg` file for your changes, modify the editing path below. When using `/etc/ansible/ansible.cfg`, if your inventories are maintained outside of the `/etc/ansible` directory, be sure to use an absolute path instead of a relative path when setting the `inventory` value.

    nano ansible.cfg

As mentioned above, it is recommended to set your development environment as the default inventory. Notice how we can select the entire environment directory instead of the hosts file it contains:

    [defaults]
    inventory = ./environments/dev

You should now be able to use your default inventory without the `-i` option. The non-default inventories will still require the use of `-i`, which helps protect them from accidental changes.

## Conclusion

In this article, we’ve explored the flexibility that Ansible provides for managing your hosts across multiple environments. This allows users to adopt many different strategies for handling variable precedence when a host is a member of multiple groups, but the ambiguity and lack of official direction can be challenging. As with any technology, the best fit for your organization will depend on your use-cases and the complexity of your requirements. The best way to find a strategy that fits your needs is to experiment. Share your use case and approach in the comments below.
