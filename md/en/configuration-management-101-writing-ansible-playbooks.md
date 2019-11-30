---
author: Erika Heidi
date: 2016-03-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuration-management-101-writing-ansible-playbooks
---

# Configuration Management 101: Writing Ansible Playbooks

## Introduction

In a nutshell, server configuration management (also popularly referred to as IT Automation) is a solution for turning your infrastructure administration into a codebase, describing all processes necessary for deploying a server in a set of provisioning scripts that can be versioned and easily reused. It can greatly improve the integrity of any server infrastructure over time.

In a [previous guide](an-introduction-to-configuration-management), we talked about the main benefits of implementing a configuration management strategy for your server infrastructure, how configuration management tools work, and what these tools typically have in common.

This part of the series will walk you through the process of automating server provisioning using Ansible, a configuration management tool that provides a complete automation framework and orchestration capabilities, while maintaining a goal of ultimate simplicity and minimalism. We will focus on the language terminology, syntax, and features necessary for creating a simplified example to fully automate the deployment of an Ubuntu 18.04 web server using Apache.

The following list contains all steps we need to automate in order to reach our goal:

1. Update the `apt` cache
2. Install Apache
3. Create a custom document root directory
4. Place an `index.html` file in the custom document root
5. Apply a template to set up our custom virtual host
6. Restart Apache

We’ll start by having a look at the terminology used by Ansible, followed by an overview of the main language features that can be used to write playbooks. At the end of the guide, you’ll find the contents of a full provisioning example to automate the steps described for setting up Apache on Ubuntu 18.04.

**Note** : this guide is intended to get you introduced to the Ansible language and how to write playbooks to automate your server provisioning. For a more introductory view of Ansible, including the steps necessary for installing and getting started with this tool, as well as how to run Ansible commands and playbooks, check our [How to Install and Configure Ansible on Ubuntu 18.04](how-to-install-and-configure-ansible-on-ubuntu-18-04) guide.

## Getting Started

Before we can move to a more hands-on view of Ansible, it is important that we get acquainted with important terminology and concepts introduced by this tool.

### Terminology

The following list contains a quick overview of the most relevant terms used by Ansible:

- **Control Node** : the machine where Ansible is installed, responsible for running the provisioning on the servers you are managing.
- **Inventory** : an `INI` file that contains information about the servers you are managing.
- **Playbook** : a `YAML` file containing a series of procedures that should be automated.
- **Task** : a block that defines a single procedure to be executed, e.g.: install a package.
- **Module** : a module typically abstracts a system task, like dealing with packages or creating and changing files. Ansible has a multitude of built-in modules, but you can also create custom ones.
- **Role** : a set of related playbooks, templates and other files, organized in a pre-defined way to facilitate reuse and share.
- **Play** : a provisioning executed from start to finish is called a _play_.
- **Facts** : global variables containing information about the system, like network interfaces or operating system.
- **Handlers** : used to trigger service status changes, like restarting or reloading a service.

### Task Format

A task defines a single automated step that should be executed by Ansible. It typically involves the usage of a module or the execution of a raw command. This is how a task looks:

    - name: This is a task
      apt: name=vim state=latest

The `name` part is actually optional, but recommended, as it shows up in the output of the provisioning when the task is executed. The `apt` part is a built-in Ansible module that abstracts the management of packages on Debian-based distributions. This example task tells Ansible that the package `vim` should have its state changed to `latest`, which will cause the package manager to install this package in case it is not installed yet.

### Playbook Format

Playbooks are `YAML` files containing a series of directives to automate the provisioning of a server. The following example is a simple playbook that perform two tasks: updates the `apt` cache and installs `vim` afterwards:

    ---
    - hosts: all
      become: true
      tasks:
         - name: Update apt-cache 
           apt: update_cache=yes
    
         - name: Install Vim
           apt: name=vim state=latest

`YAML` relies on indentation to serialize data structures. For that reason, when writing playbooks and especially when copying examples, you need to be extra careful to maintain the correct indentation.

Before the end of this guide we will see a more real-life example of a playbook, explained in detail. The next section will give you an overview of the most important elements and features that can be used to write Ansible playbooks.

## Writing Playbooks

Now that you are familiar with basic terminology and the overal format of playbooks and tasks in Ansible, we’ll learn about some playbook features that can help us creating more versatile automations.

### Working with Variables

There are different ways in which you can define variables in Ansible. The simplest way is by using the `vars` section of a playbook. The example below defines a variable `package` that later is used inside a task:

    ---
    - hosts: all
      become: true
      vars:
         package: vim
      tasks:
         - name: Install Package
           apt: name={{ package }} state=latest

The `package` variable has a global scope, which means it can be accessed from any point of the provisioning, even from included files and templates.

### Using Loops

Loops are typically used to repeat a task using different input values. For instance, instead of creating 10 tasks for installing 10 different packages, you can create a single task and use a loop to repeat the task with all the different packages you want to install.

To create a loop within a task, include the option `with_items` with an array of values. The content can be accessed through the loop variable `item`, as shown in the example below:

    - name: Install Packages
      apt: name={{ item }} state=latest
      with_items:
         - vim
         - git
         - curl  

You can also use an **array variable** to define your items:

    ---
    - hosts: all
      become: true
      vars:
         packages: ['vim', 'git', 'curl']
      tasks:
         - name: Install Package
           apt: name={{ item }} state=latest
           with_items: "{{ packages }}"

### Using Conditionals

Conditionals can be used to dynamically decide whether or not a task should be executed, based on a variable or an output from a command, for instance.

The following example will only shutdown Debian based systems:

    - name: Shutdown Debian Based Systems
      command: /sbin/shutdown -t now
      when: ansible_os_family == "Debian"

The conditional `when` receives as argument an expression to be evaluated. The task only gets executed in case the expression is evaluated to `true`. In our example, we tested a **fact** to check if the operating system is from the Debian family.

A common use case for conditionals in IT automation is when the execution of a task depends on the output of a command. With Ansible, the way we implement this is by registering a variable to hold the results of a command execution, and then testing this variable in a subsequent task. We can test for the command’s exit status (if failed or successful). We can also check for specific contents inside the output, although this might require the usage of regex expressions and string parsing commands.

The next example shows two conditional tasks based on the output from a `php -v` command. We will test for the exit status of the command, since we know it will fail to execute in case PHP is not installed on this server. The `ignore_errors` portion of the task is important to make sure the provisioning continues even when the command fails execution.

    - name: Check if PHP is installed
      register: php_installed
      command: php -v
      ignore_errors: true
    
    - name: This task is only executed if PHP is installed
      debug: var=php_install
      when: php_installed|success
    
    - name: This task is only executed if PHP is NOT installed
      debug: msg='PHP is NOT installed'
      when: php_installed|failed

The `debug` module used here is a useful module for showing contents of variables or debug messages. It can either print a string (when using the `msg` argument) or print the contents of a variable (when using the `var` argument).

### Working with Templates

Templates are typically used to set up configuration files, allowing for the use of variables and other features intended to make these files more versatile and reusable. Ansible uses the [Jinja2](http://jinja.pocoo.org/docs/dev/) template engine.

The following example is a template for setting up an Apache virtual host, using a variable for setting up the document root for this host:

    <VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot {{ doc_root }}
    
        <Directory {{ doc_root }}>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>

The built-in module `template` is used to apply the template from a task. If you named the template file above `vhost.tpl`, and you placed it in the same directory as your playbook, this is how you would apply the template to replace the default Apache virtual host:

    - name: Change default Apache virtual host
      template: 
        src: vhost.tpl
        dest: /etc/apache2/sites-available/000-default.conf

### Defining and Triggering Handlers

Handlers are used to trigger a state change in a service, such as a _restart_ or a _stop_. Even though they might look fairly similar to regular tasks, handlers are only executed when previously triggered from a `notify` directive in a task. They are typically defined as an array in a `handlers` section of the playbook, but they can also live in separate files.

Let’s take into consideration our previous template usage example, where we set up an Apache virtual host. If you want to make sure Apache is restarted after a virtual host change, you first need to create a handler for the Apache service. This is how handlers are defined inside a playbook:

    handlers:
        - name: restart apache
          service: name=apache2 state=restarted
    
        - name: other handler
          service: name=other state=restarted

The `name` directive here is important because it will be the unique identifier of this handler. To trigger this handler from a task, you should use the `notify` option:

    - name: Change default Apache virtual host
      template: 
        src: vhost.tpl
        dest: /etc/apache2/sites-available/000-default.conf
      notify: restart apache

We’ve seen some of the most important features you can use to begin writing Ansible playbooks. In the next section, we’ll dive into a more real-life example of a playbook that will automate the installation and configuration of Apache on Ubuntu.

## Example Playbook

Now let’s have a look at a playbook that will automate the installation of an Apache web server within an Ubuntu 18.04 system, as discussed in this guide’s introduction.

The complete example, including the template file for setting up Apache and an HTML file to be served by the web server, can be found [on Github](https://github.com/erikaheidi/cfmgmt/tree/master/ansible). The folder also contains a Vagrantfile that lets you test the playbook in a simplified setup, using a virtual machine managed by [Vagrant](https://vagrantup.com).

### Playbook Contents

The full contents of the playbook are available here for your convenience:

playbook.yml

    ---
    - hosts: all
      become: true
      vars:
        doc_root: /var/www/example
      tasks:
        - name: Update apt
          apt: update_cache=yes
    
        - name: Install Apache
          apt: name=apache2 state=latest
    
        - name: Create custom document root
          file: path={{ doc_root }} state=directory owner=www-data group=www-data
    
        - name: Set up HTML file
          copy: src=index.html dest={{ doc_root }}/index.html owner=www-data group=www-data mode=0644
    
        - name: Set up Apache virtual host file
          template: src=vhost.tpl dest=/etc/apache2/sites-available/000-default.conf
          notify: restart apache
      handlers:
        - name: restart apache
          service: name=apache2 state=restarted
    

Let’s examine each portion of this playbook in more detail:

**hosts: all**  
The playbook starts by stating that it should be applied to `all` hosts in your inventory (`hosts: all`). It is possible to restrict the playbook’s execution to a specific host, or a group of hosts. This option can be overwritten at execution time.

**become: true**  
The `become: true` portion tells Ansible to use privilege escalation (sudo) for executing all the tasks in this playbook. This option can be overwritten on a task-by-task basis.

**vars**  
Defines a variable, `doc_root`, which is later used in a task. This section could contain multiple variables.

**tasks**  
The section where the actual tasks are defined. The first task updates the `apt` cache, and the second task installs the package `apache2`.

The third task uses the built-in module **file** to create a directory to serve as our document root. This module can be used to manage files and directories.

The fourth task uses the module **copy** to copy a local file to the remote server. We’re copying a simple HTML file to be served as our website hosted by Apache.

**handlers**  
Finally, we have the `handlers` section, where the services are declared. We define the `restart apache` handler that is notified from the fourth task, where the Apache template is applied.

### Running a Playbook

Once you get the contents of this playbook downloaded to your Ansible control node, you can use `ansible-playbook` to execute it on one or more nodes from your inventory. The following command will execute the playbook on **all** hosts from your default inventory file, using SSH keypair authentication to connect as the current system user:

    ansible-playbook playbook.yml

You can also use `-l` to limit execution to a single host or a group of hosts from your inventory:

    ansible-playbook -l host_or_group playbook.yml

If you need to specify a different SSH user to connect to the remote server, you can include the argument `-u user` to that command:

    ansible-playbook -l host_or_group playbook.yml -u remote-user

For more information on how to run Ansible commands and playbooks, please refer to our guide on [How to Install and Configure Ansible on Ubuntu 18.04](how-to-install-and-configure-ansible-on-ubuntu-18-04).

## Conclusion

Ansible is a minimalist IT automation tool that has a low learning curve, using `YAML` for its provisioning scripts. It has a great number of built-in modules that can be used to abstract tasks such as installing packages and working with templates. Its simplified infrastructure requirements and simple language can be a good fit for those who are getting started with configuration management. It might, however, lack some advanced features that you can find with more complex tools like Puppet and Chef.

In the [next part of this series](configuration-management-101-writing-puppet-manifests), we will see a practical overview of Puppet, a popular and well established configuration management tool that uses an expressive and powerful custom DSL based on Ruby to write provisioning scripts.
