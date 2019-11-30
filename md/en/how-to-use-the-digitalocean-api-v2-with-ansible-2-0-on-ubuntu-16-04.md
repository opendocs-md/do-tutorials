---
author: Stephen Rees-Carter
date: 2016-07-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2-with-ansible-2-0-on-ubuntu-16-04
---

# How To Use the DigitalOcean API v2 with Ansible 2.0 on Ubuntu 16.04

## **Status:** Deprecated

This article is deprecated and no longer maintained.

### Reason

This article relies on a project, [dopy](https://github.com/Wiredcraft/dopy), which is no longer maintained.

### See Instead

This article may still be useful as a reference, but may not work or follow best practices. We strongly recommend using a recent article written for the operating system you are using.

## Introduction

Ansible 2.0 provides support for [version 2 of the DigitalOcean API](https://developers.digitalocean.com/documentation/v2/), which means that you can use Ansible to not only provision your web applications, but also to provision and manage your Droplets automatically.

While DigitalOcean provides a simple web interface for setting up SSH keys and creating Droplets, it is a manual process that you need to go through each time you want to provision a new server. When your application expands to include a larger number of servers and needs the ability to grow and shrink on demand, you don’t want to have to deal with creating and configuring the application deployment scripts for each server by hand.

The benefit of using a provisioning tool like Ansible is that it allows you to completely automate this process, and initiating it is as simple as running a single command. This tutorial will show by example how to use Ansible’s support of the DigitalOcean API v2.

In particular, this tutorial will cover the process of setting up a new SSH key on a DO account and provisioning two different Droplets so they are ready to use for deploying your web applications. After following this tutorial, you’ll be able to modify and integrate these tasks into your existing application deployment scripts.

## Prerequisites

This tutorial builds on basic Ansible knowledge, so if you are new to Ansible, you can read [this section of the Ansible installation tutorial](how-to-install-and-configure-ansible-on-ubuntu-16-04#how-does-ansible-work) first.

To follow this tutorial, you will need:

- One Ubuntu 16.04 Droplet with a [sudo non-root user](initial-server-setup-with-ubuntu-16-04).

- Ansible installed on your server, which you can set up by following [this step from a previous Ansible tutorial](how-to-install-and-configure-ansible-on-ubuntu-16-04#install-ansible-on-ubuntu-1404).

- A read and write [Personal Access Token](how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token) for the API. Make sure you write down the token in a safe place; you’ll need it later on in this tutorial.

## Step 1 — Configuring Ansible

In this step, we will configure Ansible to communicate with the DigitalOcean API.

Typically, Ansible just uses SSH to connect to different servers and run commands. This means that the configuration necessary start using Ansible is generally standard for all modules. However, because communicating with the DigitalOcean API is not simply an SSH shell command, we’ll need to do a little additional setup. The `dopy` (_DigitalOcean API Python Wrapper_) Python module is what will allow Ansible to communicate with the API.

In order to install `dopy`, first install the Python package manager `pip`.

    sudo apt-get install python-pip

Then, install `dopy` using `pip`.

    sudo pip install dopy

Next, we’ll create a new directory to work in to keep things neat, and we’ll set up a basic Ansible configuration file.

By default, Ansible uses a hosts file located at `/etc/ansible/hosts`, which contains all of the servers it is managing. While that file is fine for some use cases, it’s global. This is a global configuration, which is fine in some uses cases, but we’ll use a local hosts file in this tutorial. This way, we won’t accidentally break any existing configurations you might have while learning about and testing Ansible’s DO API support.

Create and move into a new directory, which we will use for the rest of this tutorial.

    mkdir ~/ansible-do-api
    cd ~/ansible-do-api/

When you run Ansible, it will look for an `ansible.cfg` file in the directory where it is run, and if it finds one, it’ll apply those configuration settings. This means we can easily override options, such as the `hostfile` option, for each individual use case.

Create a new file called `ansible.cfg` and open it for editing using `nano` or your favorite text editor.

    nano ansible.cfg

Paste the following into `ansible.cfg`, then save and close the file.

Updated ansible.cfg

    [defaults]
    hostfile = hosts

Setting the `hostfile` option in the `[defaults]` group tells Ansible to use a particular hosts file instead of the global one. This `ansible.cfg` tells Ansible to look for a hostfile called `hosts` in the same directory.

Next, we’ll create the `hosts` file.

    nano hosts

Because we will only be dealing with the DigitalOcean API in this tutorial, we can tell Ansible to run on `localhost`, which keeps things simple and will remove the need to connect to a remote host. This can be done by telling Ansible to use `localhost`, and specifying the `ansible_connection` as `local`. Paste the code below into `hosts`, then save and close the file.

Updated hosts file

    [digitalocean]
    localhost ansible_connection=local

Finally, we will use the API token created in the prerequisites to allow Ansible to communicate with the DigitalOcean API. There are three ways we can tell Ansible about the API token:

1. Provide it directly on each DigitalOcean task, using the `api_token` parameter.
2. Define it as a variable in the playbook or hosts file, and use that variable for the `api_token` parameter.
3. Export it as an environment variable, as either `DO_API_TOKEN` or `DO_API_KEY`.

Option 1 is the most direct approach and may sound appealing if you do not wish to create variables. However, it means that the API token will need to be copied into each task it is being used for. More importantly, this means that if it ever changes, you’ll need to find all instances of it and replace them all.

Option 2 allows us to set the API token directly within our playbook, like option 1. Unlike option 1, we only define it in a single place by using a variable, which is more convenient and easier to update. We will be using option 2 for this tutorial because it is the simplest approach.

However, it’s worth nothing that option 3 is the best method to use to protect your API token because it makes it a lot harder for you to accidentally commit the API token into a repository (which might be shared with anyone). It allows the token to be configured on the system level, and to work across different playbooks without having to include the token in each.

Create a basic playbook called `digitalocean.yml`.

    nano digitalocean.yml

Paste the following code into the file, making sure to substitute in your API token.

Updated digitalocean.yml

    ---
    - hosts: digitalocean
    
      vars:
        do_token: your_API_token
    
      tasks:

You can leave this file open in your editor as we’ll continue working with it in the next step.

## Step 2 — Setting Up an SSH key

In this step, we will create a new SSH key on your server and add it to your DigitalOcean account using Ansible.

The first thing we need to do is ensure the user has a SSH key pair, which we can push to DigitalOcean so it can be installed by default on your new Droplets. Although this is easy to do this via the command line, we can do it just as easily with the [users](http://docs.ansible.com/ansible/user_module.html) module in Ansible. Using Ansible also has the benefit of ensuring the key exists before it is used, which can avoid issues when running the playbook on different hosts.

In your playbook, add in the `user` task below, which we can use to ensure an SSH key exists, then save and close the file.

Updated digitalocean.yml

    ---
    - hosts: digitalocean
    
      vars:
        do_token: your_API_token
    
      tasks:
    
      - name: ensure ssh key exists
        user: >
          name={{ ansible_user_id }}
          generate_ssh_key=yes
          ssh_key_file=.ssh/id_rsa

You can change the name of the key if you would like to use something other than `~/.ssh/id_rsa`.

Run your playbook.

    ansible-playbook digitalocean.yml

The output should look like this:

Output

    PLAY ***************************************************************************
    
    TASK [setup] *******************************************************************
    ok: [localhost]
    
    TASK [ensure ssh key exists] ***************************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost : ok=2 changed=1 unreachable=0 failed=0   

When that has finished, you can manually verify the key exists by running:

    ls -la ~/.ssh/id_rsa*

It will list all files that match `id_rsa*`. You should see `id_rsa` and `id_rsa.pub` listed, indicating that your SSH key exists.

Next, we’ll push the key into your DigitalOcean account, so open your playbook for editing again.

    nano digitalocean.yml

We’ll be using the [digital\_ocean](http://docs.ansible.com/ansible/digital_ocean_module.html) Ansible module to upload your SSH key.We will also register the output of the task as the `my_ssh_key` variable because we’ll need it for a later step.

Add the task to the bottom of the file, then save and close the file.

Updated digitalocean.yml

    ---
    . . .
      - name: ensure ssh key exists
        user: >
          name={{ ansible_user_id }}
          generate_ssh_key=yes
          ssh_key_file=.ssh/id_rsa
    
      - name: ensure key exists at DigitalOcean
        digital_ocean: >
          state=present
          command=ssh
          name=my_ssh_key
          ssh_pub_key={{ lookup('file', '~/.ssh/id_rsa.pub') }}
          api_token={{ do_token }}
        register: my_ssh_key

If you named your key something other than `id_rsa`, make sure to update the name is the `ssh_pub_key` line in this task.

We’re using a number of different options from the `digital_ocean` module here:

- **state** — This can be present, active, absent, or deleted. In this case, we want `present`, because we want the SSH key to be present in the account.
- **command** — This is the either droplet or ssh. We want `ssh`, which allows us to manage the state of SSH keys within the account.
- **name** — This is the name to save the SSH key under, this must be unique and will be used to identify your key via the API and the web interface.
- **ssh\_pub\_key** — This is your SSH public key, which will be the key whose existence we assured using the user module.
- **api\_token** — This is your DigitalOcean API token, which we have accessible as a variable (`do_token`, defined in the `vars` section).

Now, run your playbook.

    ansible-playbook digitalocean.yml

The output should look like this:

Output

    . . .
    
    TASK [ensure key exists at digital ocean] **************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************************
    localhost : ok=3 changed=1 unreachable=0 failed=0   

When that has finished, you can manually check that your SSH key exists in your DigitalOcean account by going to the control panel, clicking **Settings** (from the gear menu), then **Security** (in the **User** category on the left sidebar). You should see your new key listed under **SSH Keys**.

## Step 3 — Creating a New Droplet

In this step, we will create a new Droplet.

We briefly touched on the `digital_ocean` module in Step 2. We will be using a different set of options for this module in this step:

- **command** — We used this option in the previous step with ``ssh`; this time, we’ll use it with `droplet` to manage Droplets via this module.
- **state** — We used this in the previous step, too; here, it represents the state of the Droplet, which we want to be `present`.
- **image\_id** — This is the image to use for the new Droplet, like `ubuntu-16-04-x64`.
- **name** — This is the hostname to use when creating the Droplet.
- **region\_id** — This is the the region to create the Droplet in, like `NYC3`.
- **size\_id** — This is the the size of the Droplet we want to create, like `512mb`.
- **ssh_key_ids** — This is SSH key ID (or IDs) to be set on the server when it is created.

There are many more options than just the ones that we are covering in this tutorial (all of which can be found on the Ansible documentation page), but using these options as a guide, we can write your new task.

Open your playbook for editing.

    nano digitalocean.yml

Update your playbook to with the new task highlighted in red below, then save and close the file. You can change options like size, region, and image to suit your application. The options below will create a 512MB Ubuntu 16.04 server named **droplet-one** using the SSH key we created in the previous step.

Updated digitalocean.yml

    . . .
          api_token={{ do_token }}
        register: my_ssh_key
    
      - name: ensure droplet one exists
        digital_ocean: >
          state=present
          command=droplet
          name=droplet-one
          size_id=512mb
          region_id=sgp1
          image_id=ubuntu-16-04-x64
          ssh_key_ids={{ my_ssh_key.ssh_key.id }}
          api_token={{ do_token }}
        register: droplet_one
    
      - debug: msg="IP is {{ droplet_one.droplet.ip_address }}"

Note that we are using `{{ my_ssh_key.ssh_key.id }}` to retrieve the ID of the previously set up SSH key and pass it into your new Droplet. This works if the SSH key is newly created or if it already exists.

Now, run your playbook. This will take a little longer to execute than it did previously because it will be creating a Droplet.

    ansible-playbook digitalocean.yml

The output should look like this:

    . . .
    
    TASK [ensure key exists at DigitalOcean] **************************************
    ok: [localhost]
    
    TASK [ensure droplet one exists] ******************************************************
    changed: [localhost]
    
    TASK [debug] *******************************************************************
    ok: [localhost] => {
    "msg": "IP is 111.111.111.111"
    }
    
    PLAY RECAP *********************************************************************
    localhost : ok=5 changed=1 unreachable=0 failed=0   

Ansible has provided us with the IP address of the new Droplet in the return message. To verify that it’s running, you can log into it directly using SSH.

    ssh root@111.111.111.111

This should connect you to your new server (using the SSH key we created on your Ansible server in step 2). You can then exit back to your Ansible server by pressing `CTRL+D`.

## Step 4 — Ensuring a Droplet Exists

In this step, we will discuss the concept of idempotence and how to relates to provisioning Droplets with Ansible.

Ansible aims to operate using the concept of idempotence. This means that you can run the same tasks multiple times, and changes should only be made when they are needed — which is usually the first time it’s run. This idea maps well to provisioning servers, installing packages, and other server administration.

If you run your playbook again (don’t do it yet!), given the current configuration, it will go ahead and provision a second Droplet also called `droplet-one`. Run it again, and it will make a third Droplet. This is due to the fact that DigitalOcean allows multiple Droplets with the same name. To avoid this, we can use the `unique_name` parameter.

The `unique_name` parameter tells Ansible and DigitalOcean that you want unique hostnames for your servers. This means that when you run your playbook again, it will honor idempotence and consider the Droplet already provisioned, and therefore won’t create a second server with the same name.

Open your playbook for editing:

    nano digitalocean.yml

Add in the `unique_name` parameter:

Updated digitalocean.yml

    . . .
      - name: ensure droplet one exists
        digital_ocean: >
          state=present
          command=droplet
          name=droplet-one
          unique_name=yes
          size_id=512mb
    . . .

Save and run your playbook:

    ansible-playbook digitalocean.yml

The output should result in no changed tasks, but you will notice the debug output with the IP address is still displayed. If you check your DigitalOcean account, you will notice only a single **droplet-one** Droplet was provisioned.

## Step 5 — Creating a Second Droplet

In this step, we will replicate our existing configuration to provision a separate Droplet.

In order to provision a separate Droplet, all we need to do is replicate the Ansible task from our first Droplet. To make our playbook a little more robust, however, we will convert it to using a list of Droplets to provision, which allows us to easily scale out our fleet as required.

First, we need to define our list of Droplets.

Open your playbook for editing:

    nano digitalocean.yml

Add in a list of Droplet names to be provisioned in the `vars` section.

Updated digitalocean.yml

    ---
    - hosts: digitalocean
    
      vars:
        do_token: <digitalocean_token>
        droplets:
        - droplet-one
        - droplet-two
    
      tasks:
    . . .

Next, we need to update our task to loop through the list of Droplets, check if they exist, and then save the results into a variable. Following that, we also need to modify our `debug` tasks to output the information stored in the variable for each item.

To do this, update the **ensure droplet one exists** task in your playbook as below:

Updated digitalocean.yml

    . . .
      - name: ensure droplets exist
        digital_ocean: >
          state=present
          command=droplet
          name={{ item }}
          unique_name=yes
          size_id=512mb
          region_id=sgp1
          image_id=ubuntu-16-04-x64
          ssh_key_ids={{ my_ssh_key.ssh_key.id }}
          api_token={{ do_token }}
        with_items: droplets
        register: droplet_details
    
      - debug: msg="IP is {{ item.droplet.ip_address }}"
        with_items: droplet_details.results

Save and run your playbook.

    ansible-playbook digitalocean.yml

The results should look like this:

Output

    . . .
    TASK [ensure droplets exists] **************************************************
    ok: [localhost] => (item=droplet-one)
    changed: [localhost] => (item=droplet-two)
    
    TASK [debug] *******************************************************************
    
    . . .
    
    "msg": "IP is 111.111.111.111"
    
    . . .
    
    "msg": "IP is 222.222.222.222"
    }
    
    PLAY RECAP *********************************************************************
    localhost : ok=5 changed=1 unreachable=0 failed=0   

You might notice that the the `debug` output has a lot more information in it than it did the first time. This is because the `debug` module prints additional information for help with debugging; this is a small downside of using registered variables with this module.

Apart from that, you will see that our second Droplet has been provisioned, while our first was already running. You have now provisioned two DigitalOcean Droplets using only Ansible!

Deleting your Droplets is just as simple. The state parameter in the task tells Ansible what state the Droplet should be in. Setting it to `present` ensures that the Droplet exists, and it will be created if it doesn’t already exist; setting it to `absent` ensures the Droplet with the specified name **not** exist, and it will delete any Droplets matching the specified name (as long as `unique_name` is set).

If you want to delete the two example Droplets you created in this tutorial, just change the state in the creation task to `absent` and rerun your playbook.

Updated digitalocean.yml

    . . .
      - name: ensure droplets exist
        digital_ocean: >
          state=absent
          command=droplet
    . . .

You may also want to remove the debug line before you rerun your playbook. If you don’t, your Droplets will still be deleted, but you’ll see an error from the debug command (because there are no IP addresses to return).

    ansible-playbook digitalocean.yml

Now your two example Droplets will be deleted.

## Conclusion

Ansible is an incredibly powerful and very flexible provisioning tool. You have seen how easy it is to provision (and deprovision) Droplets using the DigitalOcean API using only standard Ansible concepts and the built-in modules.

The state parameter, which was set to `present`, tells Ansible what state the Droplet should be in. Setting it to `present` ensures that the Droplet exists, and it will be created if it doesn’t already exist; setting it to `absent` tells Ansible to ensure the Droplet with the specified name **not** exist, and it will delete any Droplets matching the specified name (as long as `unique_name` is set).

As your number of Droplets you manage increases, the ability to automate the process will save you time in creating, setting up, and destroying Droplets as part of a automated process. You can adapt and expand the examples in this tutorial to improve your provisioning scripts custom to your setup.
