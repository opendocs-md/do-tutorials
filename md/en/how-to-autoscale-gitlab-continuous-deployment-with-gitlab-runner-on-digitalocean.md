---
author: Owen Williams
date: 2018-06-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-autoscale-gitlab-continuous-deployment-with-gitlab-runner-on-digitalocean
---

# How To Autoscale GitLab Continuous Deployment with GitLab Runner on DigitalOcean

## Introduction

GitLab is an open-source tool used by software teams to manage their complete development and delivery lifecycle. GitLab provides a broad set of functionality: issue tracking, git repositories, continuous integration, container registry, deployment, and monitoring. These features are all built from the ground up as a single application. You can host GitLab on your own servers or use [GitLab.com](https://gitlab.com), a cloud service where open-source projects get all the top-tier features for free.

GitLab’s continuous integration / continuous delivery (CI/CD) functionality is an effective way to build the habit of testing all code before it’s deployed. GitLab CI/CD is also highly scalable thanks to an additional tool, GitLab Runner, which automates scaling your build queue in order to avoid long wait times for development teams trying to release code.

In this guide, we will demonstrate how to configure a highly scalable GitLab infrastructure that manages its own costs, and automatically responds to load by increasing and decreasing available server capacity.

## Goals

We’re going to build a scalable CI/CD process on DigitalOcean that automatically responds to demand by creating new servers on the platform and destroys them when the queue is empty.

These reusable servers are spawned by the GitLab Runner process and are automatically deleted when no jobs are running, reducing costs and administration overhead for your team.

As we’ll explain in this tutorial, you are in control of how many machines are created at any given time, as well as the length of time they’re retained before being destroyed.

We’ll be using three separate servers to build this project, so let’s go over terminology first:

- **GitLab** : Your hosted GitLab instance or self-hosted instance where your code repositories are stored. 

- **GitLab Bastion** : The _bastion_ server or Droplet is the core of what we’ll be configuring. It is the control instance that is used to interact with the DigitalOcean API to create Droplets and destroy them when necessary. No jobs are executed on this server.

- **GitLab Runners** : Your _runners_ are transient servers or Droplets that are created on the fly by the _bastion_ server when needed to execute a CI/CD job in your build queue. These servers are disposable, and are where your code is executed or tested before your build is marked as passing or failing.

![GitLab Runners Diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-runner/Autoscaling-GitLab-Runners.png)

By leveraging each of the GitLab components, the CI/CD process will enable you to scale responsively based on demands. With these goals in mind, we are ready to begin setting up our continuous deployment with GitLab and DigitalOcean.

## Prerequisites

This tutorial will assume you have already configured GitLab on your own server or through the hosted service, and that you have an existing DigitalOcean account.

To set this up on an Ubuntu 16.04 Droplet, you can use the DigitalOcean one-click image, or follow our guide: “[How To Install and Configure GitLab on Ubuntu 16.04](how-to-install-and-configure-gitlab-on-ubuntu-16-04).”

For the purposes of this tutorial, we assume you have private networking enabled on this Droplet, which you can achieve by following our guide on “[How To Enable DigitalOcean Private Networking on Existing Droplets](how-to-enable-digitalocean-private-networking-on-existing-droplets),” but it is not compulsory.

Throughout this tutorial, we’ll be using non-root users with admin privileges on our Droplets.

## Step 1 — Import JavaScript Project

To begin, we will create a new example project in your existing GitLab instance containing a sample Node.js application.

![GitLab Interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-runner/gitlab.jpg)

Login to your GitLab instance and click the **plus icon** , then select **New project** from the dropdown menu.

On the new project screen, select the **Import project** tag, then click **Repo by URL** to import our example project directly from GitHub.

Paste the below clone URL into the Git repository URL:

    https://github.com/do-community/hello_hapi.git

This repository is a basic JavaScript application for the purposes of demonstration, which we won’t be running in production. To complete the import, click the **New Project** button.

Your new project will now be in GitLab and we can get started setting up our CI pipeline.

## Step 2 — Set Up Infrastructure

Our GitLab Code Runner requires specific configuration as we’re planning to programmatically create Droplets to handle CI load as it grows and shrinks.

We will create two types of machines in this tutorial: a **bastion** instance, which controls and spawns new machines, and our **runner** instances, which are temporary servers spawned by the bastion Droplet to build code when required. The bastion instance uses Docker to create your runners.

Here are the DigitalOcean products we’ll use, and what each component is used for:

- **Flexible Droplets** — We will create memory-optimized Droplets for our GitLab Runners as it’s a memory-intensive process which will run using Docker for containerization. You can shrink or grow this Droplet in the future as needed, however we recommend the flexible Droplet option as a starting point to understand how your pipeline will perform under load.

- **DigitalOcean Spaces (Object Storage)** — We will use [DigitalOcean Spaces](https://www.digitalocean.com/products/spaces/) to persist cached build components across your runners as they’re created and destroyed. This reduces the time required to set up a new runner when the CI pipeline is busy, and allows new runners to pick up where others left off immediately.

- **Private Networking** — We will create a private network for your bastion Droplet and GitLab runners to ensure secure code compilation and to reduce firewall configuration required.

To start, we’ll create the bastion Droplet. Create a [new Droplet](https://cloud.digitalocean.com/droplets/new), then under **choose an image** , select the **One-click apps** tab. From there, select **Docker 17.12.0-ce on 16.04** (note that this version is current at the time of writing), then choose the smallest Droplet size available, as our bastion Droplet will manage the creation of other Droplets rather than actually perform tests.

It is recommended that you create your server in a data center that includes [DigitalOcean Spaces](an-introduction-to-digitalocean-spaces) in order to use the object storage caching features mentioned earlier.

Select both the **Private networking** and **Monitoring** options, then click **Create Droplet**.

We also need to set up our storage space which will be used for caching. Follow the steps in “[How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key)” to create a new Space in the same or nearest data center as your hosted GitLab instance, along with an API Key.

Note this key down, as we’ll need it later in the tutorial.

Now it’s time to get our CI started!

## Step 3 — Configure the GitLab Runner Bastion Server

With the fresh Droplet ready, we can now configure GitLab Runner. We’ll be installing scripts from GitLab and GitHub repositories.

As a best practice, be sure to inspect scripts to confirm what you will be installing prior to running the full commands below.

Connect to the Droplet using SSH, move into the `/tmp` directory, then add the [official GitLab Runner repository](https://docs.gitlab.com/runner/install/linux-repository.html) to Ubuntu’s package manager:

    cd /tmp
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

Once added, install the GitLab Runner application:

    sudo apt-get install gitlab-runner

We also need to install **[Docker Machine](https://docs.docker.com/machine/install-machine/#install-machine-directly)**, which is an additional Docker tool that assists with automating the deployment of containers on cloud providers:

    curl -L https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
    sudo install /tmp/docker-machine /usr/local/bin/docker-machine

With these installations complete, we can move on to connecting our GitLab Runner to our GitLab install.

## Step 4 — Obtain Runner Registration Token

To link GitLab Runner to your existing GitLab install, we need to link the two instances together by obtaining a token that authenticates your runner to your code repositories.

Login to your existing GitLab instance as the admin user, then click the wrench icon to enter the admin settings area.

On the left of your screen, hover over **Overview** and select **Runners** from the list that appears.

On the Runners page under the **How to setup a shared Runner for a new project** section, copy the token shown in Step 3, and make a note of it along with the publicly accessible URL of your GitLab instance from Step 2. If you are using HTTPS for Gitlab, make sure it is not a self-signed certificate, or GitLab Runner will fail to start.

## Step 5 — Configure GitLab on the Bastion Droplet

Back in your SSH connection with your bastion Droplet, run the following command:

    sudo gitlab-runner register

This will initiate the linking process, and you will be asked a series of questions.

On the next step, enter the **GitLab instance URL** from the previous step:

    Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com)
    https://example.digitalocean.com

Enter the token you obtained from your GitLab instance:

    Please enter the gitlab-ci token for this runner
    sample-gitlab-ci-token

Enter a description that will help you recognize it in the GitLab web interface. We recommend naming this instance something unique, like `runner-bastion` for clarity.

    Please enter the gitlab-ci description for this runner
    [yourhostname] runner-bastion

If relevant, you may enter the tags for code you will build with your runner. However, we recommend this is left blank at this stage. This can easily be changed from the GitLab interface later.

    Please enter the gitlab-ci tags for this runner (comma separated):
    code-tag

Choose whether or not your runner should be able to run untagged jobs. This setting allows you to choose whether your runner should build repositories with no tags at all, or require specific tags. Select true in this case, so your runner can execute all repositories.

    Whether to run untagged jobs [true/false]: true

Choose if this runner should be shared among your projects, or locked to the current one, which blocks it from building any code other than those specified. Select false for now, as this can be changed later in GitLab’s interface:

    Whether to lock Runner to current project [true/false]: false

Choose the executor which will build your machines. Because we’ll be creating new Droplets using Docker, we’ll choose `docker+machine` here, but you can read more about the advantages of each approach in this [compatibility chart](https://docs.gitlab.com/runner/executors/README.html#compatibility-chart):

    Please enter the executor: ssh, docker+machine, docker-ssh+machine, kubernetes, docker, parallels, virtualbox, docker-ssh, shell:
    docker+machine

You’ll be asked which image to use for projects that don’t explicitly define one. We’ll choose a basic, secure default:

    Please enter the Docker image (e.g. ruby:2.1):
    alpine:latest

Now you’re done configuring the core bastion runner! At this point it should appear within the GitLab Runner page of your GitLab admin settings, which we accessed to obtain the token.

If you encounter any issues with these steps, the [GitLab Runner documentation](https://docs.gitlab.com/runner/register/index.html) includes options for troubleshooting.

## Step 6 — Configure Docker Caching and Docker Machine

To speed up Droplet creation when the build queue is busy, we’ll leverage Docker’s caching tools on the Bastion Droplet to store the images for your commonly used containers on DigitalOcean Spaces.

To do so, upgrade Docker Machine on your SSH shell using the following command:

    curl -L https://github.com/docker/machine/releases/download/v0.14.0/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && sudo install /tmp/docker-machine /usr/local/bin/docker-machine

With Docker Machine upgraded, we can move on to setting up our access tokens for GitLab Runner to use.

## Step 7 — Gather DigitalOcean Credentials

Now we need to create the credentials that GitLab Runner will use to create new Droplets using your DigitalOcean account.

Visit your DigitalOcean [dashboard](https://cloud.digitalocean.com) and click **API**. On the next screen, look for **Personal access tokens** and click **Generate New Token**.

Give the new token a name you will recognize such as `GitLab Runner Access` and ensure that both the read and write scopes are enabled, as we need the Droplet to create new machines without human intervention.

Copy the token somewhere safe as we’ll use it in the next step. You can’t retrieve this token again without regenerating it, so be sure it’s stored securely.

## Step 8 — Edit GitLab Runner Configuration Files

To bring all of these components together, we need to finish configuring our bastion Droplet to communicate with your DigitalOcean account.

In your SSH connection to your bastion Droplet, use your favorite text editor, such as nano, to open the GitLab Runner configuration file for editing:

    nano /etc/gitlab-runner/config.toml

This configuration file is responsible for the rules your CI setup uses to scale up and down on demand. To configure the bastion to autoscale on demand, you need to add the following lines:

/etc/gitlab-runner/config.toml

    concurrent = 50 # All registered Runners can run up to 50 concurrent builds
    
    [[runners]]
      url = "https://example.digitalocean.com"
      token = "existinggitlabtoken" # Note this is different from the registration token used by `gitlab-runner register`
      name = "example-runner"
      executor = "docker+machine" # This Runner is using the 'docker+machine' executor
      limit = 10 # This Runner can execute up to 10 builds (created machines)
      [runners.docker]
        image = "alpine:latest" # Our secure image
      [runners.machine]
        IdleCount = 1 # The amount of idle machines we require for CI if build queue is empty
        IdleTime = 600 # Each machine can be idle for up to 600 seconds, then destroyed
        MachineName = "gitlab-runner-autoscale-%s" # Each machine will have a unique name ('%s' is required and generates a random number)
        MachineDriver = "digitalocean" # Docker Machine is using the 'digitalocean' driver
        MachineOptions = [
            "digitalocean-image=coreos-stable", # The DigitalOcean system image to use by default
            "digitalocean-ssh-user=core", # The default SSH user
            "digitalocean-access-token=DO_ACCESS_TOKEN", # Access token from Step 7
            "digitalocean-region=nyc3", # The data center to spawn runners in
            "digitalocean-size=1gb", # The size (and price category) of your spawned runners
            "digitalocean-private-networking" # Enable private networking on runners
        ]
      [runners.cache]
        Type = "s3" # The Runner is using a distributed cache with the S3-compatible Spaces service
        ServerAddress = "nyc3.spaces.digitaloceanspaces.com"
        AccessKey = "YOUR_SPACES_KEY"
        SecretKey = "YOUR_SPACES_SECRET"
        BucketName = "your_bucket_name"
        Insecure = true # We do not have a SSL certificate, as we are only running locally 

Once you’ve added the new lines, customize the access token, region and Droplet size based on your setup. For the purposes of this tutorial, we’ve used the smallest Droplet size of 1GB and created our Droplets in NYC3. Be sure to use the information that is relevant in your case.

You also need to customize the cache component, and enter your Space’s server address from the infrastructure configuration step, access key, secret key and the name of the Space that you created.

When completed, restart GitLab Runner to make sure the configuration is being used:

    gitlab-runner restart

If you would like to learn about more all available options, including off-peak hours, you can read [GitLab’s advanced documentation](https://docs.gitlab.com/runner/configuration/autoscale.html).

## Step 9 — Test Your GitLab Runner

At this point, our GitLab Runner bastion Droplet is configured and is able to create DigitalOcean Droplets on demand, as the CI queue fills up. We’ll need to test it to be sure it works by heading to your GitLab instance and the project we imported in Step 1.

To trigger a build, edit the `readme.md` file by clicking on it, then clicking **edit** , and add any relevant testing text to the file, then click **Commit changes**.

Now a build will be automatically triggered, which can be found under the project’s **CI/CD** option in the left navigation.

On this page you should see a pipeline entry with the status of **running**. In your DigitalOcean account, you’ll see a number of Droplets automatically created by GitLab Runner in order to build this change.

Congratulations! Your CI pipeline is cloud scalable and now manages its own resource usage. After the specified idle time, the machines should be automatically destroyed, but we recommend verifying this manually to ensure you aren’t unexpectedly billed.

## Troubleshooting

In some cases, GitLab may report that the runner is unreachable and as a result perform no actions, including deploying new runners. You can troubleshoot this by stopping GitLab Runner, then starting it again in debug mode:

    gitlab-runner stop
    gitlab-runner --debug start

The output should throw an error, which will be helpful in determining which configuration is causing the issue.

If your configuration creates too many machines, and you wish to remove them all at the same time, you can run this command to destroy them all:

    docker-machine rm $(docker-machine ls -q)

For more troubleshooting steps and additional configuration options, you can refer to [GitLab’s documentation](https://docs.gitlab.com/runner/).

## Conclusion

You’ve successfully set up an automated CI/CD pipeline using GitLab Runner and Docker. From here, you could configure higher levels of caching with Docker Registry to optimize performance or explore the use of tagging code builds to specific GitLab code runners.

For more on GitLab Runner, [see the detailed documentation](https://docs.gitlab.com/runner/), or to learn more, you can read [GitLab’s series of blog posts](https://docs.gitlab.com/ee/ci/) on how to make the most of your continuous integration pipeline.

_This post also appears on the [GitLab Blog](https://about.gitlab.com/2018/06/19/autoscale-continuous-deployment-gitlab-runner-digital-ocean/)._
