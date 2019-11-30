---
author: Erika Heidi
date: 2019-05-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ansible-on-ubuntu-18-04
---

# Automating Initial Server Setup with Ansible on Ubuntu 18.04

## Introduction

When you first create a new Ubuntu 18.04 server, there are a few configuration steps that you should take early on as part of the basic setup. This will increase the security and usability of your server, working as a solid foundation for subsequent actions.

While you can complete these steps manually, automating the process will save you time and reduce human error. With the popularization of containerized applications and microservices, server automation now plays an essential role in systems administration. It is also a way to establish standard procedures for new servers.

This guide explains how to use [Ansible](https://ansible.com) to automate the steps contained in our [Initial Server Setup Guide](initial-server-setup-with-ubuntu-18-04). Ansible is a modern configuration management tool that can be used to automate the provisioning and configuration of remote systems.

## Pre-Flight Check

In order to execute the automated setup provided by the playbook we’re discussing in this guide, you’ll need:

- Ansible installed either on your local machine or on a remote server that you have set up as an _Ansible Control Node_. You can follow Step 1 of the tutorial [How to Install and Configure Ansible on Ubuntu 18.04](how-to-install-and-configure-ansible-on-ubuntu-18-04) to get this set up.
- Root access to one or more Ubuntu 18.04 servers that will be managed by Ansible.

Before running a playbook, it’s important to make sure Ansible is able to connect to your servers via SSH and run [Ansible modules](https://docs.ansible.com/ansible/latest/user_guide/modules.html) using Python. The next two sections cover how to set up your Ansible inventory to include your servers and how to run ad-hoc Ansible commands to test for connectivity and valid credentials.

### Inventory File

The _inventory file_ contains information about the hosts you’ll manage with Ansible. You can include anywhere from one to several hundred of servers in your inventory file, and hosts can be organized into groups and subgroups. The inventory file is also often used to set variables that will be valid for certain hosts and groups only, in order to be used within playbooks and templates. Some variables can also affect the way a playbook is run, like the `ansible_python_interpreter` variable that we’ll see in a moment.

To inspect the contents of your default Ansible inventory, open the `/etc/ansible/hosts` file using your command-line editor of choice, on your local machine or an Ansible Control Node:

    sudo nano /etc/ansible/hosts

**Note** : some Ansible installations won’t create a default inventory file. If the file doesn’t exist in your system, you can create a new file at `/etc/ansible/hosts` or provide a custom inventory path using the **-i** parameter when running commands and playbooks.

The default inventory file provided by the Ansible installation contains a number of examples that you can use as references for setting up your inventory. The following example defines a group named **servers** with three different servers in it, each identified by a custom alias: **server1** , **server2** , and **server3** :

/etc/ansible/hosts

    [servers]
    server1 ansible_host=203.0.113.111
    server2 ansible_host=203.0.113.112
    server3 ansible_host=203.0.113.113
    
    [servers:vars]
    ansible_python_interpreter=/usr/bin/python3

The `server:vars` subgroup sets the `ansible_python_interpreter` host parameter that will be valid for all hosts included in the `servers` group. This parameter makes sure the remote server uses the `/usr/bin/python3` Python 3 executable instead of `/usr/bin/python` (Python 2.7), which is not present on recent Ubuntu versions.

To finish setting up your inventory file, replace the highlighted IPs with the IP addresses of your servers. When you’re finished, save and close the file by pressing `CTRL+X` then `y` to confirm changes and then `ENTER`.

Now that your inventory file is ready, it’s time to test connectivity to your nodes

### Testing Connectivity

After setting up the inventory file to include your servers, it’s time to check if Ansible is able to connect to these servers and run commands via SSH. For this guide, we will be using the Ubuntu **root** account because that’s typically the only account available by default on newly created servers. This playbook will create a new non-root user with `sudo` privileges that you should use in subsequent interactions with the remote server.

From your local machine or Ansible Control Node, run:

    ansible -m ping all -u root

This command will use the built-in `ping` [Ansible module](https://docs.ansible.com/ansible/latest/modules/ping_module.html) to run a connectivity test on all nodes from your default inventory, connecting as **root**. The `ping` module will test:  
if hosts are accessible;  
if you have valid SSH credentials;  
if hosts are able to run Ansible modules using Python.

If instead of key-based authentication you’re using _password-based authentication_ to connect to remote servers, you should provide the additional parameter `-k` to the Ansible command, so that it will prompt you for the password of the connecting user.

    ansible -m ping all -u root -k

**Note:** Keep in mind that some servers might have additional security measures against password-based authentication as the **root** user, and in some cases you might be required to manually log in to the server to change the initial root password.

You should get output similar to this:

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
    
    

If this is the first time you’re connecting to these servers via SSH, you’ll be asked to confirm the authenticity of the hosts you’re connecting to via Ansible. When prompted, type `yes` and then hit `Enter` to confirm.

Once you get a “pong” reply back from a host, it means you’re ready to run Ansible commands and playbooks on that server.

## What Does this Playbook Do?

This Ansible playbook provides an alternative to manually running through the procedure outlined in the [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04) and the guide on [setting up SSH keys on Ubuntu 18.04](how-to-set-up-ssh-keys-on-ubuntu-1804).

Running this playbook will cause the following actions to be performed:

1. The administrative group **wheels** is created and then configured for _passwordless sudo_.
2. A new administrative user is created within that group, using the name specified by the `create_user` variable.
3. A public SSH key is copied from the location defined by the variable `copy_local_key`, and added to the `authorized_keys` file for the user created in the previous step.
4. Password-based authentication is disabled for the **root** user.
5. The local `apt` package index is updated and basic packages defined by the variable `sys_packages` are installed.
6. The UFW firewall is configured to allow only SSH connections and deny any other requests.

For more information about each of the steps included in this playbook, please refer to our [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04).

Once the playbook has finished running, you’ll be able to log in to the server using the newly created `sudo` account.

## How to Use this Playbook

To get started, we’ll download the contents of the [playbook](https://github.com/do-community/ansible-playbooks/blob/master/initial_server_setup/ubuntu1804.yml) to your Ansible Control Node. This can be either your local machine, or a remote server where you have Ansible installed and your inventory set up.

For your convenience, the contents of the playbook are also included in a further section of this guide.

To download this playbook from the command-line, you can use `curl`:

    curl -L https://raw.githubusercontent.com/do-community/ansible-playbooks/master/initial_server_setup/ubuntu1804.yml -o initial_server_setup.yml

This will download the contents of the playbook to a file named `initial_server_setup.yml` on your current local path. You can examine the contents of the playbook by opening the file with your command-line editor of choice:

    nano initial_server_setup.yml

Once you’ve opened the playbook file, you should notice a section named **vars** with three distinct variables that require your attention:

- **create\_user** : The name of the non-root user account to create and grant sudo privileges to. Our example uses **sammy** , but you can use whichever username you’d like.
- **copy\_local\_key** : Local path to a valid SSH public key to set up as an authorized key for the new non-root `sudo` account. The default value points to the current local user’s public key located at `~/.ssh/id_rsa.pub`.
- **sys\_packages** : A list of basic system packages that will be installed using the package manager tool `apt`. 

Once you’re done updating the variables inside `initial_server_setup.yml`, save and close the file.

You’re now ready to run this playbook on one or more servers. Most playbooks are configured to be executed on `all` servers from your inventory, by default. We can use the `-l` flag to make sure that only a subset of servers, or a single server, is affected by the playbook. To execute the playbook only on `server1`, you can use the following command:

    ansible-playbook initial_server_setup.yml -l server1

You will get output similar to this:

    Output
    PLAY [all] ***************************************************************************************************************************************
    
    TASK [Make sure we have a 'wheel' group] *********************************************************************************************************
    changed: [server1]
    
    TASK [Allow 'wheel' group to have passwordless sudo] *********************************************************************************************
    changed: [server1]
    
    TASK [Create a new regular user with sudo privileges] ********************************************************************************************
    changed: [server1]
    
    TASK [Set authorized key for remote user] ********************************************************************************************************
    changed: [server1]
    
    TASK [Disable password authentication for root] **************************************************************************************************
    changed: [server1]
    
    TASK [Update apt] ********************************************************************************************************************************
    changed: [server1]
    
    TASK [Install required system packages] **********************************************************************************************************
    ok: [server1]
    
    TASK [UFW - Allow SSH connections] ***************************************************************************************************************
    changed: [server1]
    
    TASK [UFW - Deny all other incoming traffic by default] ******************************************************************************************
    changed: [server1]
    
    PLAY RECAP ***************************************************************************************************************************************
    server1 : ok=9 changed=8 unreachable=0 failed=0   
    
    
    

Once the playbook execution is finished, you’ll be able to log in to the server with:

    ssh sammy@server_domain_or_IP 

Remember to replace sammy with the user defined by the `create_user` variable, and server\_domain\_or\_IP with your server’s hostname or IP address.

In case you have set a custom public key with the `copy_local_key` variable, you’ll need to provide an extra parameter specifying the location of its private key counterpart:

    ssh sammy@server_domain_or_IP -i ~/.ssh/ansible_controller_key

After logging in to the server, you can check the UFW firewall’s active rules to confirm that it’s properly configured:

    sudo ufw status

You should get output similar to this:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    

This means that the UFW firewall has successfully been enabled. Since this was the last task in the playbook, it confirms that the playbook was fully executed on this server.

## The Playbook Contents

You can find the initial server setup playbook in the [ansible-playbooks repository](https://github.com/do-community/ansible-playbooks/blob/master/initial_server_setup/ubuntu1804.yml) in the DigitalOcean [Community GitHub organization](https://github.com/do-community). To copy or download the script contents directly, click the **Raw** button towards the top of the script, or [click here to view the raw contents directly](https://raw.githubusercontent.com/do-community/ansible-playbooks/master/initial_server_setup/ubuntu1804.yml).

The full contents are also included here for convenience:

initial\_server\_setup.yml

    ---
    - hosts: all
      remote_user: root
      gather_facts: false
      vars:
        create_user: sammy
        copy_local_key: "{{ lookup('file', lookup('env','HOME') + '/.ssh/id_rsa.pub') }}"
        sys_packages: ['curl', 'vim', 'git', 'ufw']
    
      tasks:
        - name: Make sure we have a 'wheel' group
          group:
            name: wheel
            state: present
    
        - name: Allow 'wheel' group to have passwordless sudo
          lineinfile:
            path: /etc/sudoers
            state: present
            regexp: '^%wheel'
            line: '%wheel ALL=(ALL) NOPASSWD: ALL'
            validate: '/usr/sbin/visudo -cf %s'
    
        - name: Create a new regular user with sudo privileges
          user:
            name: "{{ create_user }}"
            state: present
            groups: wheel
            append: true
            create_home: true
            shell: /bin/bash
    
        - name: Set authorized key for remote user
          authorized_key:
            user: "{{ create_user }}"
            state: present
            key: "{{ copy_local_key }}"
    
        - name: Disable password authentication for root
          lineinfile:
            path: /etc/ssh/sshd_config
            state: present
            regexp: '^#?PermitRootLogin'
            line: 'PermitRootLogin prohibit-password'
    
        - name: Update apt
          apt: update_cache=yes
    
        - name: Install required system packages
          apt: name={{ sys_packages }} state=latest
    
        - name: UFW - Allow SSH connections
          ufw:
            rule: allow
            name: OpenSSH
    
        - name: UFW - Deny all other incoming traffic by default
          ufw:
            state: enabled
            policy: deny
            direction: incoming
    

Feel free to modify this playbook or include new tasks to best suit your individual needs within your own workflow.

## Conclusion

Automating the initial server setup can save you time, while also making sure your servers will follow a standard configuration that can be improved and customized to your needs. With the distributed nature of modern applications and the need for more consistency between different staging environments, automation like this becomes a necessity.

In this guide, we demonstrated how to use Ansible for automating the initial tasks that should be executed on a fresh server, such as creating a non-root user with sudo access, enabling UFW and disabling remote root login.

If you’d like to include new tasks in this playbook to further customize your initial server setup, please refer to our introductory Ansible guide [Configuration Management 101: Writing Ansible Playbooks](configuration-management-101-writing-ansible-playbooks).
