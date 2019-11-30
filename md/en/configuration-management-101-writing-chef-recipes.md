---
author: Erika Heidi
date: 2016-06-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuration-management-101-writing-chef-recipes
---

# Configuration Management 101: Writing Chef Recipes

In a nutshell, server configuration management (also popularly referred to as IT Automation) is a solution for turning your infrastructure administration into a codebase, describing all processes necessary for deploying a server in a set of provisioning scripts that can be versioned and easily reused. It can greatly improve the integrity of any server infrastructure over time.

In a [previous guide](an-introduction-to-configuration-management), we talked about the main benefits of implementing a configuration management strategy for your server infrastructure, how configuration management tools work, and what these tools typically have in common.

This part of the series will walk you through the process of automating server provisioning using Chef, a powerful configuration management tool that leverages the Ruby programming language to automate infrastructure administration and provisioning. We will focus on the language terminology, syntax, and features necessary for creating a simplified example to fully automate the deployment of an Ubuntu 18.04 web server using Apache.

This is the list of steps we need to automate in order to reach our goal:

1. Update the `apt` cache
2. Install Apache
3. Create a custom document root directory
4. Place an `index.html` file in the custom document root
5. Apply a template to set up our custom virtual host
6. Restart Apache

We will start by having a look at the terminology used by Chef, followed by an overview of the main language features that can be used to write recipes. At the end of this guide, we will share the complete example so you can try it by yourself.

**Note:** this guide is intended to get you introduced to the Chef language and how to write recipes to automate your server provisioning. For a more introductory view of Chef, including the steps necessary for installing and getting started with this tool, please refer to [Chef’s official documentation](https://docs.chef.io/install_dk.html).

## Getting Started

Before we can move to a more hands-on view of Chef, it is important that we get acquainted with important terminology and concepts introduced by this tool.

### Chef Terms

- **Chef Server** : a central server that stores information and manages provisioning of the nodes
- **Chef Node** : an individual server that is managed by a Chef Server
- **Chef Workstation** : a controller machine where the provisionings are created and uploaded to the Chef Server
- **Recipe** : a file that contains a set of instructions (resources) to be executed. A recipe must be contained inside a _Cookbook_
- **Resource** : a portion of code that declares an element of the system and what action should be executed. For instance, to install a package we declare a _package_ resource with the action **install**
- **Cookbook** : a collection of recipes and other related files organized in a pre-defined way to facilitate sharing and reusing parts of a provisioning
- **Attributes** : details about a specific node. Attributes can be automatic (see next definition) and can also be defined inside recipes
- **Automatic Attributes** : global variables containing information about the system, like network interfaces and operating system (known as _facts_ in other tools). These automatic attributes are collected by a tool called _Ohai_
- **Services** : used to trigger service status changes, like restarting or stopping a service

### Recipe Format

Chef recipes are written using Ruby. A recipe is basically a collection of resource definitions that will create a step-by-step set of instructions to be executed by the nodes. These resource definitions can be mixed with Ruby code for more flexibility and modularity.

Below you can find a simple example of a recipe that will run `apt-get update` and install `vim` afterwards:

    execute "apt-get update" do
     command "apt-get update"
    end
    
    apt_package "vim" do
     action :install
    end
    

## Writing Recipes

### Working with Variables

Local variables can be defined inside recipes as regular Ruby local variables. The example below shows how to create a local variable that is later used inside a resource definition:

    package = "vim"
    
    apt_package package do
     action :install
    end

These variables, however, have a limited scope, being valid only inside the file where they were defined. If you want to create a variable and make it globally available, so you can use it from any of your cookbooks or recipes, you need to define a **custom attribute**.

#### Using Attributes

Attributes represent details about a node. Chef has automatic attributes, which are the attributes collected by a tool called Ohai and containing information about the system (such as platform, hostname and default IP address), but it also lets you define your own custom attributes.

Attributes have different precedence levels, defined by the type of attribute you create. `default` attributes are the most common choice, as they can still be overwritten by other attribute types when desired.

The following example shows how the previous example would look like with a `default` node attribute instead of a local variable:

    node.default['main']['package'] = "vim"
    
    apt_package node['main']['package'] do
     action :install
    end

There are two details to observe in this example:

The recommended practice when defining node variables is to organize them as hashes using the current cookbook in use as the key. In this case, we used `main`, because we have a cookbook with the same name. This avoids confusion if you are working with multiple cookbooks that might have similar named attributes.  
Notice that we used `node.default` when defining the attribute, but when accessing its value later, we used `node` directly. The `node.default` usage defines that we are creating an attribute of type **default**. This attribute could have its value overwritten by another type with higher precedence, such as **normal** or **override** attributes.

The attributes’ precedence can be slightly confusing at first, but you will get used to it after some practice. To illustrate the behavior, consider the following example:

    node.normal['main']['package'] = "vim"
    
    node.override['main']['package'] = "git"
    
    node.default['main']['package'] = "curl"
    
    apt_package node['main']['package'] do
     action :install
    end

Do you know which package will be installed in this case? If you guessed `git`, you guessed correctly. Regardless of the order in which the attributes were defined, the higher precedence of the type `override` will make the `node['main']['package'] be evaluated to`git`.

### Using Loops

Loops are typically used to repeat a task using different input values. For instance, instead of creating 10 tasks for installing 10 different packages, you can create a single task and use a loop to repeat the task with all the different packages you want to install.

Chef supports all Ruby loop structures for creating loops inside recipes. For simple usage, `each` is a common choice:

    ['vim', 'git', 'curl'].each do |package|
     apt_package package do
       action :install
     end
    end

Instead of using an inline array, you can also create a variable or attribute for defining the parameters you want to use inside the loop. This will keep things more organized and easier to read. Below, the same example now using a local variable to define the packages that should be installed:

    packages = ['vim', 'git', 'curl']
    
    packages.each do |package|
     apt_package package do
       action :install
     end
    end

### Using Conditionals

Conditionals can be used to dynamically decide whether or not a block of code should be executed, based on a variable or an output from a command, for instance.

Chef supports all Ruby conditionals for creating conditional statements inside recipes. Additionally, all resource types support two special properties that will evaluate an expression before deciding if the task should be executed or not: `if_only` and `not_if`.

The example below will check for the existence of `php` before trying to install the extension `php-pear`. It will use the command `which` for verifying if there is a `php` executable currently installed on this system. If the command `which php` returns false, this task won’t be executed:

    apt_package "php-pear" do
     action :install
     only_if "which php"
    end

If we want to do the opposite, executing a command at all times **except** when a condition is evaluated as true, we use `not_if` instead. This example will install `php5` unless the system is CentOS:

    apt_package "php5" do
     action :install
     not_if { node['platform'] == 'centos' }
    end

For performing more complex evaluations, of if you want to execute several tasks under a specific condition, you may use any of the standard Ruby conditionals. The following example will only execute `apt-get update` when the system is either Debian **or** Ubuntu:

    if node['platform'] == 'debian' || node['platform'] == 'ubuntu'
     execute "apt-get update" do
       command "apt-get update"
     end
    end

The attribute `node['platform']` is an automatic attribute from Chef. The last example was only to demonstrate a more complex conditional construction, however it could be replaced by a simple test using the automatic attribute `node['platform_family']`, which would return “debian” for both Debian and Ubuntu systems.

### Working with Templates

Templates are typically used to set up configuration files, allowing for the use of variables and other features intended to make these files more versatile and reusable.

Chef uses Embedded Ruby (ERB) templates, which is the same format used by Puppet. They support conditionals, loops and other Ruby features.

Below is an example of an ERB template for setting up an Apache virtual host, using a variable to define the document root for this host:

    <VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot <%= @doc_root %>
    
        <Directory <%= @doc_root %>>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>

In order to apply the template, we need to create a `template` resource. This is how you would apply this template to replace the default Apache virtual host:

    template "/etc/apache2/sites-available/000-default.conf" do
     source "vhost.erb"
     variables({ :doc_root => node['main']['doc_root'] })
     action :create
    end 

Chef makes a few assumptions when dealing with local files, in order to enforce organization and modularity. In this case, Chef would look for a `vhost.erb` template file inside a _templates_ folder that should be in the same cookbook where this recipe is located.

Unlike the other configuration management tools we’ve seen so far, Chef has a more strict scope for variables. This means you will have to explicitly provide any variables you plan to use inside a template, when defining the `template` resource. In this example, we used the `variables` method to pass along the `doc_root` attribute we need at the virtual host template.

### Defining and Triggering Services

Service resources are used to make sure services are initialized and enabled. They are also used to trigger service restarts.

In Chef, service resources need to be declared before you try to notify them, otherwise you will get an error.

Let’s take into consideration our previous template usage example, where we set up an Apache virtual host. If you want to make sure Apache is restarted after a virtual host change, you first need to create a _service_ resource for the Apache service. This is how such resource is defined in Chef:

    service "apache2" do
      action [:enable, :start]
    end

Now, when defining the **template** resource, you need to include a `notify` option in order to trigger a restart:

    template "/etc/apache2/sites-available/000-default.conf" do
     source "vhost.erb"
     variables({ :doc_root => node['main']['doc_root'] })
     action :create
     notifies :restart, resources(:service => "apache2")
    end

## Example Recipe

Now let’s have a look at a manifest that will automate the installation of an Apache web server within an Ubuntu 14.04 system, as discussed in this guide’s introduction.

The complete example, including the template file for setting up Apache and an HTML file to be served by the web server, can be found [on Github](https://github.com/erikaheidi/cfmgmt/tree/master/chef). The folder also contains a Vagrantfile that lets you test the manifest in a simplified setup, using a virtual machine managed by [Vagrant](https://vagrantup.com).

Below you can find the complete recipe:

    node.default['main']['doc_root'] = "/vagrant/web"
    
    execute "apt-get update" do
     command "apt-get update"
    end
    
    apt_package "apache2" do
     action :install
    end
    
    service "apache2" do
     action [:enable, :start]
    end
    
    directory node['main']['doc_root'] do
     owner 'www-data'
     group 'www-data'
     mode '0644'
     action :create
    end
    
    cookbook_file "#{node['main']['doc_root']}/index.html" do
     source 'index.html'
     owner 'www-data'
     group 'www-data'
     action :create
    end
    
    template "/etc/apache2/sites-available/000-default.conf" do
     source "vhost.erb"
     variables({ :doc_root => node['main']['doc_root'] })
     action :create
     notifies :restart, resources(:service => "apache2")
    end
    

### Recipe Explained

#### line 1

The recipe starts with an **attribute** definition, `node['main']['doc_root']`. We could have used a simple local variable here, however in most use case scenarios, recipes need to define global variables that will be used from included recipes or other files. For these situations, it is necessary to create an attribute instead of a local variable, as the later has a limited scope.

#### lines 3-5

This **execute** resource runs an `apt-get update`.

#### lines 7-10

This **apt\_package** resource installs the package `apache2`.

#### lines 12-15

This **service** resource enables and starts the service `apache2`. Later on, we will need to notify this resource for a service restart. It is important that the service definition comes before any resource that attempts to notify a service, otherwise you will get an error.

#### lines 17-22

This **directory** resource uses the value defined by the custom attribute `node['main']['doc_root']` to create a directory that will serve as our **document root**.

#### lines 24-29

A **cookbook\_file** resource is used to copy a local file to a remote server. This resource will copy our `index.html` file and place it inside the document root we created in a previous task.

#### lines 31-36

Finally, this **template** resource applies our Apache virtual host template and notifies the service `apache2` for a restart.

## Conclusion

Chef is a powerful configuration management tool that leverages the Ruby language to automate server provisioning and deployment. It gives you freedom to use the standard language features for maximum flexibility, while also offering custom DSLs for some resources.
