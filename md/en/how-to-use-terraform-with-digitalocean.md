---
author: Mitchell Anicas
date: 2014-08-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-terraform-with-digitalocean
---

# How To Use Terraform with DigitalOcean

## Introduction

Terraform is a tool for building and managing infrastructure in an organized way. It can be used to manage DigitalOcean droplets and DNS entries, in addition to a large variety of services offered by other providers. It is controlled via an easy to use command-line interface, and can run from your desktop or a remote server.

Terraform works by reading configuration files that describe the components that make up your application environment or datacenter. Based on the configuration, it generates an execution plan, which describes what it will do to reach the desired state. The plan is then executed to build the infrastructure. When changes to the configuration occur, Terraform can generate and execute incremental plans to update the existing infrastructure to the newly described state.

In this tutorial, we will demonstrate how to use Terraform to create a simple infrastructure that consists of two Nginx servers that are load balanced by an HAProxy server (see image below). This should help you get started with using Terraform, and give you an idea of how it can be used to manage and deploy a DigitalOcean-based infrastructure that meets your own needs.

![Example Infrastructure](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/terraform/terraform_example.png)

Let’s take a look at what you need to follow this tutorial.

## Prerequisites

### DigitalOcean Account

Because this tutorial is focused on the usage of the DigitalOcean provider of Terraform, you will need to have a valid DigitalOcean account. If you do not have one, [register here](https://cloud.digitalocean.com/registrations/new).

### DigitalOcean API Token

Generate a Personal Access Token via the DigitalOcean control panel. Instructions to do that can be found in this link: [How to Generate a Personal Access Token](how-to-use-the-digitalocean-api-v2#HowToGenerateaPersonalAccessToken).

In every terminal that you will run Terraform in, export your DigitalOcean Personal Access Token:

    export DO_PAT={YOUR_PERSONAL_ACCESS_TOKEN}

Terraform will use this token to authenticate to the DigitalOcean API, and control your account. Keep this private!

### Add Password-less SSH Key to DigitalOcean Cloud

If you have not already added a password-less SSH key to your DigitalOcean account, do so by following [this tutorial](how-to-use-ssh-keys-with-digitalocean-droplets).

Assuming that your private key is located at `~/.ssh/id_rsa`, use the following command to get the MD5 fingerprint of your public key:

    ssh-keygen -E md5 -lf ~/.ssh/id_rsa.pub | awk '{print $2}'

This will output something like the following:

    md5:e7:42:16:d7:e5:a0:43:29:82:7d:a0:59:cf:9e:92:f7

You will need to provide this fingerprint, minus the `md5:` prefix, when running Terraform, like so (substituting all of the highlighted words with their appropriate values):

    terraform plan \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=e7:42:16:d7:e5:a0:43:29:82:7d:a0:59:cf:9e:92:f7"

Now that we have the prerequisites out of the way, let’s install Terraform!

## Install Terraform

**Note:** This tutorial was written using Terraform 0.1.1.

Terraform is very easy to install, and can run on your desktop or on a remote server. Here are the steps:

#### 1. Download Terraform

Download the appropriate package for your OS and architecture: [Download Terraform](http://www.terraform.io/downloads.html)

#### 2. Extract Terraform

Extract the package you just downloaded to the directory of your choice.

If you downloaded it to `~/Downloads`, you may run the following commands to extract:

    mkdir -p ~/opt/terraform
    unzip ~/Downloads/terraform_0.1.1_darwin_amd64.zip -d ~/opt/terraform

This unarchives the package to the `opt/terraform/` directory, within your home directory.

#### 3. Add Path to Profile

The last step is to add Terraform’s bin directory, `~/opt/terraform/bin`, to your PATH environment variable for easy access.

For example, if you use _bash_ as your shell, you could add the path to your `.bash_profile`. Open your profile for editing:

    vi ~/.bash_profile

To append Terraform’s path to your PATH, add the following line at the end of the file:

    export PATH=$PATH:~/opt/terraform/bin

Save and exit.

Now all of your new bash sessions will be able to find the `terraform` command. If you want load the new PATH into your current session, type the following:

    . .bash_profile

### Verify Terraform Installation

To verify that you have installed Terraform correctly, let’s try and run it. In a terminal, run Terraform:

    terraform

If your path is set up properly, you will see output that is similar to the following:

    Available commands are:
        apply Builds or changes infrastructure
        graph Create a visual graph of Terraform resources
        output Read an output from a state file
        plan Generate and show an execution plan
        refresh Update local state file against real resources
        show Inspect Terraform state or plan
        version Prints the Terraform version

These are the commands that Terraform accepts. Their brief described here, but we will get into how to use them later.

Now that Terraform is installed, let’s start writing a configuration to describe our infrastructure!

## Create Configuration Directory

The first step to building an infrastructure with Terraform is to create a directory that will store our configuration files for a given project. The name of the directory does not matter, but we will use “loadbalance” for the example (feel free to change its name):

    mkdir ~/loadbalance

Terraform configurations are text files that end with the `.tf` file extension. They are human-readable and they support comments. Terraform also supports JSON-format configuration files, but we won’t cover those here. Terraform will read all of the configuration files in your working directory in a declarative manner, so the order of resource and variable definitions do not matter. Your entire infrastructure can exist in a single configuration file, but we will separate our configuration files by resources in this tutorial.

Change your current directory to the newly created directory:

    cd ~/loadbalance

From now on, we will assume that your working directory is the one that we just changed to. If you start a new terminal session, be sure to change to the directory that contains your Terraform configuration.

## If You Get Stuck

If you happen to get stuck, and Terraform is not working as you expect, you can start over by deleting the `terraform.tfstate` file, and manually destroying the resources that were created (e.g. through the control panel or another API tool like [Tugboat](https://github.com/pearkes/tugboat)).

You may also want to enable logging to stdout, so you can see what Terraform is trying to do. Do that by running the following command:

    export TF_LOG=1

Also, if you are unable to construct a working configuration, the complete configuration files are available in the following GitHub Gist: [Configuration Files](https://gist.github.com/thisismitch/91815a582c27bd8aa44d).

Let’s move on to creating a Terraform configuration.

## Create Provider Configuration

Terraform supports a variety of service providers through “providers” that ship with it. We are interested in DigitalOcean provider, which Terraform will use to interact with the DigitalOcean API to build our infrastructure. The first step to using the DigitalOcean provider is configuring it with the proper credential variables. Let’s do that now.

Create a file called `provider.tf`:

    vi provider.tf

Add the following lines into the file:

    variable "do_token" {}
    variable "pub_key" {}
    variable "pvt_key" {}
    variable "ssh_fingerprint" {}
    
    provider "digitalocean" {
      token = "${var.do_token}"
    }

Save and exit. Here is a breakdown of the first four lines:

- **variable “do\_token”** : your DigitalOcean Personal Access Token
- **variable “pub\_key”** : public key location, so it can be installed into new droplets
- **variable “pvt\_key”** : private key location, so Terraform can connect to new droplets
- **variable “ssh\_fingerprint”** : fingerprint of SSH key

The following lines specify the credentials for your DigitalOcean account by assigning “token” to the _do\_token_ variable. We will pass the values of these variables into Terraform, when we run it.

The official Terraform documentation of the DigitalOcean provider is located here: [DigitalOcean Provider](http://www.terraform.io/docs/providers/do/index.html).

## DigitalOcean Resources

Each provider has its own specifications, which generally map to the API of its respective service provider. In the case of the DigitalOcean provider, we are able to define three types of resources:

- **digitalocean\_domain** : DNS domain entries
- **digitalocean\_droplet** : Droplets (i.e. VPS or servers)
- **digitalocean\_record** : DNS records

Let’s start by creating a droplet which will run an Nginx server.

## Describe First Nginx Server

Create a new Terraform configuration file called `www-1.tf`:

    vi www-1.tf

Insert the following lines to define the droplet resource:

    resource "digitalocean_droplet" "www-1" {
        image = "ubuntu-14-04-x64"
        name = "www-1"
        region = "nyc2"
        size = "512mb"
        private_networking = true
        ssh_keys = [
          "${var.ssh_fingerprint}"
        ]

In the above configuration, the first line defines a _digitalocean\_droplet_ resource named “www-1”. The rest of the lines specify the droplet’s attributes, which can be accessed via the DigitalOcean API. Everything else is pretty self-explanatory, so we will not explain each line. Also, Terraform will collect a variety of information about the droplet, such as its public and private IP addresses, which can be used by other resources in your configuration.

If you are wondering which arguments are required or optional for a Droplet resource, please refer to the official Terraform documentation: [DigitalOcean Droplet Specification](http://www.terraform.io/docs/providers/do/r/droplet.html).

Now, we will set up a `connection` which Terraform can use to connect to the server via SSH. Insert the following lines at the end of the file:

      connection {
          user = "root"
          type = "ssh"
          private_key = "${file(var.pvt_key)}"
          timeout = "2m"
      }

These lines describe how Terraform should connect to the server, in case we want to provision anything over SSH (note the use of the private key variable).

Now that we have the connection set up, we can configure the “remote-exec” provisioner. We will use the remote-exec provisioner to install Nginx. Add the following lines to the configuration to do just that:

      provisioner "remote-exec" {
        inline = [
          "export PATH=$PATH:/usr/bin",
          # install nginx
          "sudo apt-get update",
          "sudo apt-get -y install nginx"
        ]
      }
    }

Save and exit.

Note that the strings in the _inline_ array are the commands that the _root_ will run to install Nginx.

## Run Terraform to Create Nginx Server

Currently, your Terraform configuration describes a single Nginx server. Let’s test it out.

First, initialize Terraform for your project. This will read your configuration files and install the plugins for your provider:

    terraform init

You’ll see this output:

    OutputInitializing provider plugins...
    - Checking for available provider plugins on https://releases.hashicorp.com... - Downloading plugin for provider "digitalocean" (0.1.2)...
    
    The following providers do not have any version constraints in configuration,
    so the latest version was installed.
    
    To prevent automatic upgrades to new major versions that may contain breaking
    changes, it is recommended to add version = "..." constraints to the
    corresponding provider blocks in configuration, with the constraint strings
    suggested below.
    
    * provider.digitalocean: version = "~> 0.1"
    
    Terraform has been successfully initialized!
    
    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.
    
    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other commands will detect it and remind you to do so if necessary.

Next, run the following `terraform plan` command to see what Terraform will attempt to do to build the infrastructure you described (i.e. see the execution plan). You will have to specify the values of all of the variables listed below:

    terraform plan \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

If all of your variables are set correctly, you should see several lines of output, including the following lines:

    Refreshing Terraform state prior to plan...
    ...
    + digitalocean_droplet.www-1
    ...

The green `+ digitalocean_droplet.www-1` line means that Terraform will create a new droplet resource called “www-1”, with the details that follow it. That’s exactly what we want, so let’s execute the plan. Run the following `terraform apply` command to execute the current plan. Again, specify all the values for the variables below:

    terraform apply \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

You should see output that contains the following lines (truncated for brevity):

    digitalocean_droplet.www-1: Creating...
    ...
    
    digitalocean_droplet.www-1: Provisioning with 'remote-exec'...
    digitalocean_droplet.www-1: Creation complete
    
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ...

At this point, Terraform has created a new droplet called `www-1` and installed Nginx on it. If you visit the public IP address of your new Droplet, you’ll see the Nginx welcome screen.

## Describe Second Nginx Server

Now that you have described an Nginx server, it is very easy to add a second one. Let’s just copy the original configuration file and replace the name (and hostname) of the droplet resource.

You can do this manually, or use `sed` to substitute all the instances of `www-1` with `www-2` (there are two) and create a new file. Here is the `sed` command to do that:

    sed 's/www-1/www-2/g' www-1.tf > www-2.tf

Now if you run `terraform plan` or `terraform apply` again, it will show or execute the new plan respectively. Since we already know Terraform will just create another Nginx droplet, let’s just save that for later.

Let’s configure our HAProxy droplet now.

## Describe HAProxy Server

Create a new Terraform configuration file called `haproxy-www.tf`:

    vi haproxy-www.tf

Insert the following lines to describe the new droplet. The first part is identical to the Nginx droplet descriptions except it has a different name, “haproxy-www”:

    resource "digitalocean_droplet" "haproxy-www" {
        image = "ubuntu-16-04-x64"
        name = "haproxy-www"
        region = "nyc2"
        size = "512mb"
        private_networking = true
        ssh_keys = [
          "${var.ssh_fingerprint}"
        ]

Insert the following connection information (again, identical to the Nginx droplets):

      connection {
          user = "root"
          type = "ssh"
          private_key = "${file(var.pvt_key)}"
          timeout = "2m"
      }

Now that we have the connection set up, we can configure the “remote-exec” provisioner. We will use the remote-exec provisioner to install and configure HAProxy. Add the following lines to the configuration to do just that:

      provisioner "remote-exec" {
        inline = [
          "export PATH=$PATH:/usr/bin",
          # install haproxy 1.5
          "sudo add-apt-repository -y ppa:vbernat/haproxy-1.5",
          "sudo apt-get update",
          "sudo apt-get -y install haproxy",
    
          # download haproxy conf
          "sudo wget https://gist.githubusercontent.com/thisismitch/91815a582c27bd8aa44d/raw/8fc59b7cb88a2be9b802cd76288ca1c2ea957dd9/haproxy.cfg -O /etc/haproxy/haproxy.cfg",
    
          # replace ip address variables in haproxy conf to use droplet ip addresses
          "sudo sed -i 's/HAPROXY_PUBLIC_IP/${digitalocean_droplet.haproxy-www.ipv4_address}/g' /etc/haproxy/haproxy.cfg",
          "sudo sed -i 's/WWW_1_PRIVATE_IP/${digitalocean_droplet.www-1.ipv4_address_private}/g' /etc/haproxy/haproxy.cfg",
          "sudo sed -i 's/WWW_2_PRIVATE_IP/${digitalocean_droplet.www-2.ipv4_address_private}/g' /etc/haproxy/haproxy.cfg",
    
          # restart haproxy to load changes
          "sudo service haproxy restart"
        ]
      }
    }

Save and exit.

Again, the strings in the _inline_ array are commands that root will run to install and configure HAProxy. After HAProxy is installed, a [sample haproxy.cfg file](https://gist.githubusercontent.com/thisismitch/91815a582c27bd8aa44d/raw/8fc59b7cb88a2be9b802cd76288ca1c2ea957dd9/haproxy.cfg) is downloaded. At this point, the `sed` command replaces certain strings in the HAProxy configuration file with the appropriate IP addresses of each droplet, through the use of Terraform variables (highlighted above in red), so HAProxy will be ready to run as soon as it is provisioned. Lastly, HAProxy is restarted to load the configuration changes.

In a more practical case, you might have your own _haproxy.cfg_ file on your Terraform system, which you could copy to your server with the “file” provisioner.

Our HAProxy server is now described, but we have to run Terraform in order to build it.

## Run Terraform to Create HAProxy Server

Currently, your Terraform configuration describes a two Nginx servers and an HAProxy server. Let’s

Run `terraform plan` command again to see the new execution plan:

    terraform plan \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

You should see several lines of output, including the following lines:

    ...
    digitalocean_droplet.www-1: Refreshing state... (ID: 2236747)
    ...
    + digitalocean_droplet.haproxy-www
    ...
    + digitalocean_droplet.www-2
    ...

This means that the _www-1_ droplet already exists, and Terraform will create the _haproxy-www_ and _www-2_ droplets. Let’s run `terraform apply` to build the remaining components:

    terraform apply \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

You should see output that contains the following lines (truncated for brevity):

    digitalocean_droplet.www-2: Creating...
    ...
    digitalocean_droplet.www-2: Provisioning with 'remote-exec'...
    digitalocean_droplet.www-2: Creation complete
    ...
    digitalocean_droplet.haproxy-www: Creating...
    ...
    digitalocean_droplet.haproxy-www: Provisioning with 'remote-exec'...
    digitalocean_droplet.haproxy-www: Creation complete
    ...
    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
    ...

At this point, Terraform has created a new Nginx server and HAProxy server. If you visit the public IP address of the haproxy-www, you should see an Nginx welcome screen (because HAProxy is load balancing the two Nginx servers).

**Your setup is complete!** The rest of the tutorial includes information about configuring DNS domain and record resources with Terraform, and information on how to use the other Terraform commands.

## Creating DNS Domains and Records

As mentioned earlier, Terraform can also create DNS domain and record domains. For example, if you want to point your domain `example.com` to your newly created HAProxy server, you can create Terraform configuration for that. **Note:** Use your own, unique, domain name or this step will fail because (i.e. do not use “example.com” or any other records that already exist in the DigitalOcean DNS)

Create a new file to describe your DNS:

    vi example.com

Insert the following domain resource:

    # Create a new domain record
    resource "digitalocean_domain" "default" {
       name = "example.com"
       ip_address = "${digitalocean_droplet.haproxy-www.ipv4_address}"
    }

And while we’re at it, let’s add a CNAME record that points “www.example.com” to “example.com”:

    resource "digitalocean_record" "CNAME-www" {
      domain = "${digitalocean_domain.default.name}"
      type = "CNAME"
      name = "www"
      value = "@"
    }

Save and exit.

To add the DNS entries, run `terraform plan` followed by `terraform apply`, as with the other resources.

## Other Terraform Commands

Terraform has several other commands that were not covered earlier, so we will go over most of them here.

### Show State

Terraform updates the state file every time it executes a plan or “refreshes” its state. Note that if you modify your infrastructure outside of Terraform, your state file will be out of date.

To view the current state of your environment, use the following command:

    terraform show terraform.tfstate

### Refresh State

If your resources are modified outside of Terraform, you may refresh the state file to bring it up to date. This command will pull the updated resource information from your provider(s):

    terraform refresh \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

### Destroy Infrastructure

Although not commonly used in production environments, Terraform can also destroy infrastructures that it creates. This is mainly useful in development environments that are built and destroyed multiple times. It is a two-step process and is described below.

#### 1. Create an execution plan to destroy the infrastructure:

    terraform plan -destroy -out=terraform.tfplan \
      -var "do_token=${DO_PAT}" \
      -var "pub_key=$HOME/.ssh/id_rsa.pub" \
      -var "pvt_key=$HOME/.ssh/id_rsa" \
      -var "ssh_fingerprint=$SSH_FINGERPRINT"

Terraform will output a plan with resources marked in red, and prefixed with a minus sign, indicating that it will delete the resources in your infrastructure.

#### 2. Apply destroy:

    terraform apply terraform.tfplan

Terraform will destroy the resources, as indicated in the destroy plan.

## Conclusion

Now that you understand how Terraform works, feel free to create configuration files that describe a server infrastructure that is useful to you. The example setup is simple, but demonstrates how easy it is to automate the deployment of servers. If you already use configuration management tools, like Puppet or Chef, you can call those with Terraform’s provisioners to configure servers as part of their creation process.

Terraform has many more features, and can work with other providers. Check out the official [Terraform Documentation](http://www.terraform.io/docs/index.html) to learn more about how you can use Terraform to improve your own infrastructure.
