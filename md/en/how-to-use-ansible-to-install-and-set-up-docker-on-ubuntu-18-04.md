---
author: Erika Heidi
date: 2019-06-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-ansible-to-install-and-set-up-docker-on-ubuntu-18-04
---

# How to Use Ansible to Install and Set Up Docker on Ubuntu 18.04

## Introduction

With the popularization of containerized applications and microservices, server automation now plays an essential role in systems administration. It is also a way to establish standard procedures for new servers and reduce human error.

This guide explains how to use [Ansible](https://ansible.com) to automate the steps contained in our guide on [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04). [Docker](https://www.docker.com/) is an application that simplifies the process of managing _containers_, resource-isolated processes that behave in a similar way to virtual machines, but are more portable, more resource-friendly, and depend more heavily on the host operating system.

While you can complete this setup manually, using a configuration management tool like Ansible to automate the process will save you time and establish standard procedures that can be repeated through tens to hundreds of nodes. Ansible offers a simple architecture that doesn’t require special software to be installed on nodes, and it provides a robust set of features and built-in modules which facilitate writing automation scripts.

## Pre-Flight Check

In order to execute the automated setup provided by the playbook discussed in this guide, you’ll need:

- Ansible installed either on your local machine or on a remote server that you have set up as an _Ansible Control Node_. You can follow Step 1 of the tutorial [How to Install and Configure Ansible on Ubuntu 18.04](how-to-install-and-configure-ansible-on-ubuntu-18-04) to get this set up.
  - If you plan to use a remote server as your Ansible Control Node, it should have a non-root user with sudo privileges and a basic firewall configured prior to installing Ansible. Follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) to set this up.
- Access to one or more Ubuntu 18.04 servers which will be used as your _Ansible hosts_. Each should have a non-root user with sudo privileges and a basic firewall configured. Follow our guide on [Automating Initial Server Setup with Ansible on Ubuntu 18.04](automating-initial-server-setup-with-ansible-on-ubuntu-18-04) to set this up automatically. Alternatively, you can set this up manually by following our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) on each of your Ansible hosts.

### Testing Connectivity to Nodes

To make sure Ansible is able to execute commands on your nodes, run the following command from your Ansible Control Node:

    ansible -m ping all

This command will use Ansible’s built-in [`ping`](https://docs.ansible.com/ansible/latest/modules/ping_module.html) module to run a connectivity test on all nodes from your default inventory file, connecting as the current system user. The `ping` module will test whether:

- your Ansible hosts are accessible;
- your Ansible Control Node has valid SSH credentials;
- your hosts are able to run Ansible modules using Python.

If you installed and configured Ansible correctly, you will get output similar to this:

    Outputserver1 | SUCCESS => {
        "changed": false, 
        "ping": "pong"
    }
    server2 | SUCCESS => {
        "changed": false, 
        "ping": "pong"
    }
    server3 | SUCCESS => {
        "changed": false, 
        "ping": "pong"
    }
    
    

Once you get a `pong` reply back from a host, it means you’re ready to run Ansible commands and playbooks on that server.

**Note** : If you are unable to get a successful response back from your servers, check our [Ansible Cheat Sheet Guide](how-to-use-ansible-cheat-sheet-guide) for more information on how to run Ansible commands with custom connection options.

## What Does this Playbook Do?

This Ansible playbook provides an alternative to manually running through the procedure outlined in our guide on [How To Install and Use Docker on Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04).

Running this playbook will perform the following actions on your Ansible hosts:

1. Install `aptitude`, which is preferred by Ansible as an alternative to the `apt` package manager.
2. Install the required system packages.
3. Install the Docker GPG APT key.
4. Add the official Docker repository to the `apt` sources.
5. Install Docker.
6. Install the Python Docker module via `pip`.
7. Pull the default image specified by `default_container_image` from Docker Hub.
8. Create the number of containers defined by `create_containers` field, each using the image defined by `default_container_image`, and execute the command defined in `default_container_command` in each new container.

Once the playbook has finished running, you will have a number of containers created based on the options you defined within your configuration variables.

## How to Use this Playbook

To get started, we’ll download the contents of the [playbook](https://github.com/do-community/ansible-playbooks/blob/master/docker/ubuntu1804.yml) to your Ansible Control Node. For your convenience, the contents of the playbook are also included in the next section of this guide.

Use `curl` to download this playbook from the command line:

    curl -L https://raw.githubusercontent.com/do-community/ansible-playbooks/master/docker/ubuntu1804.yml -o docker_ubuntu.yml

This will download the contents of the playbook to a file named `docker_ubuntu.yml` in your current working directory. You can examine the contents of the playbook by opening the file with your command-line editor of choice:

    nano docker_ubuntu.yml

Once you’ve opened the playbook file, you should notice a section named `vars` with variables that require your attention:

docker\_ubuntu.yml

    . . .
    vars:
      create_containers: 4
      default_container_name: docker
      default_container_image: ubuntu
      default_container_command: sleep 1d
    . . .

Here’s what these variables mean:

- `create_containers`: The number of containers to create.
- `default_container_name`: Default container name. 
- `default_container_image`: Default Docker image to be used when creating containers. 
- `default_container_command`: Default command to run on new containers.

Once you’re done updating the variables inside `docker_ubuntu.yml`, save and close the file. If you used `nano`, do so by pressing `CTRL + X`, `Y`, then `ENTER`.

You’re now ready to run this playbook on one or more servers. Most playbooks are configured to be executed on `all` servers from your inventory, by default. We can use the `-l` flag to make sure that only a subset of servers, or a single server, is affected by the playbook. To execute the playbook only on `server1`, you can use the following command:

    ansible-playbook docker_ubuntu.yml -l server1

You will get output similar to this:

    Output...
    TASK [Add Docker GPG apt Key] ********************************************************************************************************************
    changed: [server1]
    
    TASK [Add Docker Repository] *********************************************************************************************************************
    changed: [server1]
    
    TASK [Update apt and install docker-ce] **********************************************************************************************************
    changed: [server1]
    
    TASK [Install Docker Module for Python] **********************************************************************************************************
    changed: [server1]
    
    TASK [Pull default Docker image] *****************************************************************************************************************
    changed: [server1]
    
    TASK [Create default containers] *****************************************************************************************************************
    changed: [server1] => (item=1)
    changed: [server1] => (item=2)
    changed: [server1] => (item=3)
    changed: [server1] => (item=4)
    
    PLAY RECAP ***************************************************************************************************************************************
    server1 : ok=9 changed=8 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0   
    
    

**Note** : For more information on how to run Ansible playbooks, check our [Ansible Cheat Sheet Guide](how-to-use-ansible-cheat-sheet-guide).

When the playbook is finished running, log in via SSH to the server provisioned by Ansible and run `docker ps -a` to check if the containers were successfully created:

    sudo docker ps -a

You should see output similar to this:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    a3fe9bfb89cf ubuntu "sleep 1d" 5 minutes ago Created docker4
    8799c16cde1e ubuntu "sleep 1d" 5 minutes ago Created docker3
    ad0c2123b183 ubuntu "sleep 1d" 5 minutes ago Created docker2
    b9350916ffd8 ubuntu "sleep 1d" 5 minutes ago Created docker1

This means the containers defined in the playbook were created successfully. Since this was the last task in the playbook, it also confirms that the playbook was fully executed on this server.

## The Playbook Contents

You can find the Docker playbook featured in this tutorial in the [ansible-playbooks repository](https://github.com/do-community/ansible-playbooks/blob/master/docker/ubuntu1804.yml) within the [DigitalOcean Community GitHub organization](https://github.com/do-community). To copy or download the script contents directly, click the **Raw** button towards the top of the script, or [click here to view the raw contents directly](https://raw.githubusercontent.com/do-community/ansible-playbooks/master/docker/ubuntu1804.yml).

The full contents are also included here for your convenience:

docker\_ubuntu.yml

    
    ---
    - hosts: all
      become: true
      vars:
        create_containers: 4
        default_container_name: docker
        default_container_image: ubuntu
        default_container_command: sleep 1d
    
      tasks:
        - name: Install aptitude using apt
          apt: name=aptitude state=latest update_cache=yes force_apt_get=yes
    
        - name: Install required system packages
          apt: name={{ item }} state=latest update_cache=yes
          loop: ['apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common', 'python3-pip', 'virtualenv', 'python3-setuptools']
    
        - name: Add Docker GPG apt Key
          apt_key:
            url: https://download.docker.com/linux/ubuntu/gpg
            state: present
    
        - name: Add Docker Repository
          apt_repository:
            repo: deb https://download.docker.com/linux/ubuntu bionic stable
            state: present
    
        - name: Update apt and install docker-ce
          apt: update_cache=yes name=docker-ce state=latest
    
        - name: Install Docker Module for Python
          pip:
            name: docker
    
        # Pull image specified by variable default_image from the Docker Hub
        - name: Pull default Docker image
          docker_image:
            name: "{{ default_container_image }}"
            source: pull
    
        # Creates the number of containers defined by the variable create_containers, using default values
        - name: Create default containers
          docker_container:
            name: "{{ default_container_name }}{{ item }}"
            image: "{{ default_container_image }}"
            command: "{{ default_container_command }}"
            state: present
          with_sequence: count={{ create_containers }}
    

Feel free to modify this playbook to best suit your individual needs within your own workflow. For example, you could use the [`docker_image`](https://docs.ansible.com/ansible/2.6/modules/docker_image_module.html#docker-image-module) module to push images to Docker Hub or the [`docker_container`](https://docs.ansible.com/ansible/2.6/modules/docker_container_module.html#docker-container-module) module to set up container networks.

## Conclusion

Automating your infrastructure setup can not only save you time, but it also helps to ensure that your servers will follow a standard configuration that can be customized to your needs. With the distributed nature of modern applications and the need for consistency between different staging environments, automation like this has become a central component in many teams’ development processes.

In this guide, we demonstrated how to use Ansible to automate the process of installing and setting up Docker on a remote server. Because each individual typically has different needs when working with containers, we encourage you to check out the [official Ansible documentation](https://docs.ansible.com/ansible/2.6/modules/docker_container_module.html#docker-container-module) for more information and use cases of the `docker_container` Ansible module.

If you’d like to include other tasks in this playbook to further customize your initial server setup, please refer to our introductory Ansible guide [Configuration Management 101: Writing Ansible Playbooks](configuration-management-101-writing-ansible-playbooks).
