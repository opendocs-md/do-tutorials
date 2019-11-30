---
author: Fabian Barajas, Jon Schwenn
date: 2018-07-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/navigator-s-guide-modular-infrastructure-configuration
---

# Navigator's Guide: Modular Infrastructure Configuration

 **Note** : This is an early release version of the contents of the Navigator’s Guide book, an offering from the DigitalOcean Solutions Engineers. The goal of the book is to help business customers plan their infrastructure needs, provide working examples along the way, and include technical nuance and the “why” that makes some decisions better than others.

The book and accompanying code will be publicly available in a GitHub repository. Because this is an early release, the book is not yet complete and the repository is not yet public, but stay tuned!

The previous section used Terraform and Ansible to provision resources (Droplets, Load Balancers, and Floating IPs) and deploy your WordPress application.

Terraform created those resources using the `main.tf` file. Currently, all of the resources in that file are listed individually. The more complex your environment gets, the more resources you will need, and the longer and more complicated this file will get. This will make your configuration more difficult to manage in the long term.

In this supplemental section, we discuss some ways to simplify this configuration using Terraform modules and separate infrastructure environments. There’s no code to execute and no changes to make in this section, but the concepts are important when building a real-world setup.

## Understanding Terraform Modules

To use Terraform’s own description of modules:

> Modules in Terraform are self-contained packages of Terraform configurations that are managed as a group. Modules are used to create reusable components in Terraform as well as for basic code organization.

Modules create blocks of reusable infrastructure which can take inputs and provide outputs, like a function in a high-level programming language. We can create modules that accept optional input arguments for similar pieces of our infrastructure, and also set default values for those input parameters. This helps organize and simplify your configuration. You can learn more about modules in [Terraform’s module documentation](https://www.terraform.io/docs/modules/index.html).

For a completed example, take a look at the `main.tf` file. The last section is actually already using a Terraform module:

    module "sippin_db" {
      source = "github.com/cmndrsp0ck/galera-tf-mod.git?ref=v1.0.6"
      ...
    }

You can compare this section to the resource block for `wp_node` towards the top of the file, which has many more lines of code and is harder to follow. You’ll note that the module is called using a remote git repository. You can use local file paths, which can work for some quick development and testing, but using a remote git repo takes your environment isolation one step further. This is especially helpful when running multiple infrastructure environments, like staging and production. When using local file paths with multiple infrastructure environments, you can end up making a change intended to only affect staging, but if you were to run an apply on **prod** and the module file path is being shared, then you may end up breaking something. If you have dedicated directories for each environment, then you end up having to maintain two or more copies of your scripts, and reverting back to a previous state won’t be so easy.

Using a remote git repository and specifying a version number for the module avoids this problem. As mentioned before, it also makes reverting back to a known working version much easier if something goes wrong, which improves your ability to manage incidents and outages (which we cover in more detail in Chapter 9).

This module does more than just create a single Droplet. It creates Droplet tags, the Galera cluster nodes, the load balancers, and the Floating IP. You can think of terraform modules as nice way of packaging components of/or an entire service. It also means you can add more resources to a module or you can create module outputs which can in turn be used as inputs for another modules you may be developing. When it makes sense to create new module, like adding in a new service, or some supporting functionality that you want to decouple, you can absolutely create outputs in your modules and they will be stored as part of your state. If you’re using remote state, module outputs can be very beneficial when you want to share read-only information between different components of your infrastructure or provide an external service with a way to retrieve information it may need.

To put it simply, if you think of the resource sections in a Terraform plan as Lego bricks, your modules would be pre-assembled sections. That is a lot better than having to track Lego bricks everywhere, and possibly stepping on one. Beyond helping prevent that pain, the modules can also be used to inform the configurations of other modules as you add complexity to your infrastructure plan.

## Setting Up Infrastructure Environments

In most professional projects, you’ll work with three different environments: development, staging, and production.

Your development environment is often local, and gives you space to tinker and test independently as you work. Your staging and production environments, on the other hand, will be in a shared or public space and will be provisioned using an automated process like Terraform.

Starting with a thoughtful and planned deployment workflow will go a long way in preventing headaches, and part of that includes isolating environments from each other. Terraform’s workspace feature keeps `terraform.tfstate` files separate per environment, but changes made to terraform files describing your resources are not. So while this feature may work great as a quick way to make a minor change, test, and deploy, it shouldn’t be relied on when you have a larger deployment that may require the isolation of services from one another as well as the teams that manage them.

Here’s an example directory tree describing how you could set up environment isolation with directories:

    .
    ├── ansible.cfg
    ├── bin/
    ├── environments/
    │ ├── config/
    │ │ └── cloud-config.yaml
    │ │
    │ ├── dev/
    │ ├── prod/
    │ │ ├── config -> ../config
    │ │ ├── group_vars
    │ │ ├── host_vars
    │ │ ├── main.tf
    │ │ ├── terraform.tfvars
    │ │ ├── terraform-inventory -> ../terraform-inventory
    │ │ └── variables.tf
    │ │
    │ ├── staging/
    │ │ ├── config -> ../config
    │ │ ├── group_vars
    │ │ ├── host_vars
    │ │ ├── main.tf
    │ │ ├── terraform.tfvars
    │ │ ├── terraform-inventory -> ../terraform-inventory
    │ │ └── variables.tf
    │ │
    │ └── terraform-inventory
    │
    ├── site.yml
    ├── wordpress.yml
    │
    └── roles/

The key logic behind this kind of layout is to keep files that pertain to similar components in separate environments apart from one another.

For example, in the `environments` directory, we have a subdirectory for each of the three environments we want: `dev`, `staging`, and `prod`. This isolation helps prevent accidentally running an Ansible or Terraform script in the wrong place. You can go one step further and use another layer of subdirectories to hold files for different parts of each environment’s infrastructure.

There are [many great write-ups about this topic](https://blog.gruntwork.io/a-comprehensive-guide-to-terraform-b3d32832baca) online, one of which has actually turned into the book _Terraform: Up & Running_ by Yevgeniy Brikman.

## Using Module Versioning for Environments

Terraform modules can also help you make changes without affecting other environments. For example, take a look at these two modules.

One for a staging environment (for example, `staging/main.tf`):

    module "sippin_db" {
      source = "github.com/cmndrsp0ck/galera-tf-mod.git?ref=v1.0.8"
      project = "${var.project}"
      region = "${var.region}"
      keys = "${var.keys}"
      private_key_path = "${var.private_key_path}"
      ssh_fingerprint = "${var.ssh_fingerprint}"
      public_key = "${var.public_key}"
      ansible_user = "${var.ansible_user}"
    }

And one for a production environment (for example, `prod/main.tf`):

    module "sippin_db" {
      source = "github.com/cmndrsp0ck/galera-tf-mod.git?ref=v1.0.6"
      project = "${var.project}"
      region = "${var.region}"
      keys = "${var.keys}"
      private_key_path = "${var.private_key_path}"
      ssh_fingerprint = "${var.ssh_fingerprint}"
      public_key = "${var.public_key}"
      ansible_user = "${var.ansible_user}"
    }

The only difference between them is the value for the `ref` key at the end of the `source` line, which specifies the version to deploy. In staging, it’s `v1.0.8`, and in production, it’s `v1.0.6`. Using version control lets you make and test changes in staging before deploying to production, and setups like these simplify the configuration which supports that.

Right now, the hands-on setup in the previous section doesn’t use remote state. In Chapter 6, we cover using a remote state backend (like Consul), which is key when working on a team. Without a remote state backend, both you and another team member could execute changes to the infrastructure at the same time, causing conflicts, outages, or corruption your state file.

## What’s Next?

Once you understand how to simplify your infrastructure code by making it modular and how to isolate environments for safer development and deployment, we can look at how to increase deployment velocity by creating templates. The next chapter covers how to automate the deployment workflow using continuous development tools, which will help you deploy new code safely and quickly.
