---
author: getstreamio
date: 2016-08-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-node-js-app-using-terraform-on-ubuntu-14-04
---

# How to Deploy a Node.js App Using Terraform on Ubuntu 14.04

An Article from [Stream](https://getstream.io/)

## Introduction

With the help of orchestration tools, DevOps professionals can deploy a stack by leveraging a few API calls. [Terraform](https://www.terraform.io/) is a very simple, yet powerful tool that allows you to write your stack as code, then share it and keep it up-to-date by committing the definition files using [Git](https://git-scm.com/). Terraform is created by [HashiCorp](https://www.hashicorp.com/), the authors of popular open-source tools such as [Vagrant](https://www.vagrantup.com/), [Packer](https://www.packer.io/), and [Consul](https://www.consul.io/).

Terraform provides a common configuration to launch your infrastructure, from physical and virtual servers to email and DNS providers. Once launched, Terraform safely and efficiently changes infrastructure as the configuration evolves.

This tutorial shows you how to set up an environment for a fully functional, sophisticated [Node.js](https://nodejs.org/en/) application using [DigitalOcean](https://digitalocean.com), [Terraform](https://www.terraform.io/), [Cloud-init](https://cloudinit.readthedocs.io/en/latest/), and [PM2](http://pm2.keymetrics.io/) on Ubuntu 14.04. As our example application, we’ll be using [Cabin](http://cabin.getstream.io), an open source [React](https://facebook.github.io/react/) & [Redux](http://redux.js.org/docs/basics/UsageWithReact.html) Node.js application developed by [GetStream.io](http://getstream.io). The final output will be a feature-rich, scalable social network app!

You’ll start by using Terraform to deploy Cabin using a predefined configuration. Then you’ll take a deep dive into that configuration so you can get familiar with how it works.

If you’re only interested in installing Terraform on your DigitalOcean server, please see [How To Use Terraform with DigitalOcean](how-to-use-terraform-with-digitalocean).

## Prerequisites

To follow along with this tutorial, you’ll need:

- One 2 GB Ubuntu 14.04 server, which you will create in this tutorial with Terraform.
- The [Git](https://git-scm.com/) client installed on your local machine.
- A Facebook account, so you can create a Facebook Application, since Cabin uses Facebook for logins.
- A domain such as `cabin.example.com`; you’ll point this domain to the IPv4 address you’ll obtain in Step 4, and you’ll need this for the Site URL in Facebook.

While not a requirement, this tutorial assumes you’ve completed [Stream’s Cabin tutorial series](http://cabin.getstream.io/). You’ll need API keys and settings for several providers which are necessary for Cabin to work in production, as they play an integral role in Cabin’s functionality.

If you don’t obtain these keys, this tutorial will still work. You will still be able to use Terraform to provision and deploy the Cabin application, but the application won’t be usable until you configure all of its required components.

For additional information on these services, please feel free to visit the following blog posts from Stream:

- [Stream](http://blog.getstream.io/cabin-react-redux-example-app-stream/)
- [Imgix](http://blog.getstream.io/cabin-react-redux-example-app-imgix/)
- [Keen](http://blog.getstream.io/cabin-react-redux-example-app-keen/)
- [Algolia](http://blog.getstream.io/cabin-react-redux-example-app-algolia/)
- [Mapbox](http://blog.getstream.io/cabin-react-redux-example-app-mapbox/)

## Step 1 — Getting the Example Application

Clone the Cabin example application from [GitHub](https://github.com/GetStream/stream-react-example) into a directory of your choice on your local machine. We’re using a Mac, and assume you are as well.

First, navigate to your home directory.

    cd ~

Then use `git` to clone the repository:

    git clone https://github.com/GetStream/stream-react-example.git

This clones the example application to a new folder called `stream-react-example`. Navigate to the `stream-react-example/terraform/do/cabin` folder which contains Cabin’s Terraform project.

    cd stream-react-example/terraform/do/cabin

We’ll work with this folder in a bit. But first, let’s set up Terraform.

## Step 2 — Installing Terraform

For a simple installation on OSX, you can install Terraform using [Homebrew](http://brew.sh/) by issuing the following command:

    brew install terraform

Alternatively, you can download Terraform from [http://terraform.io](http://terraform.io). Once you download it, make it available to your command path, as shown below.

    PATH=location/of/terraform:$PATH

This temporarily adds Terraform to your path. If you want this change to be permanent, edit the file `~/.bash_profile` on OSX and add this line:

~/.bash\_profile

    export PATH=location/of/terraform:$PATH

Next, to check that Terraform was installed properly, run the following command:

    terraform

You’ll see the following output, showing Terraform’s options:

    Outputusage: terraform [--version] [--help] <command> [<args>]
    
    Available commands are:
        apply Builds or changes infrastructure
        destroy Destroy Terraform-managed infrastructure
        fmt Rewrites config files to canonical format
        get Download and install modules for the configuration
        graph Create a visual graph of Terraform resources
        init Initializes Terraform configuration from a module
        output Read an output from a state file
        plan Generate and show an execution plan
        push Upload this Terraform module to Atlas to run
        refresh Update local state file against real resources
        remote Configure remote state storage
        show Inspect Terraform state or plan
        taint Manually mark a resource for recreation
        untaint Manually unmark a resource as tainted
        validate Validates the Terraform files
        version Prints the Terraform version

Before Terraform can start your infrastructure we need to configure two things:

1. [DigitalOcean Token](how-to-use-the-digitalocean-api-v2)
2. [SSH Key Pair](how-to-set-up-ssh-keys--2)

So let’s take care of the DigitalOcean token first.

## Step 2 — Configuring the DigitalOcean Access Token

Terraform needs your DigitalOcean access token in order to use the DigitalOcean API.

Log in to your DigitalOcean account and click the **API** link. Then click the **Generate New Token** button. Be sure to check **Write Access**. The user interface will display a new access key which you should copy to your clipboard, as the key won’t be visible if you revisit the page.

Now open the file `variables.tf` with your favorite text editor and locate the `token` section:

variables.tf

    variable "token" {
      description = "DO Token"
    }

Add a new line starting with the text `default =` and include your DigitalOcean API token. Remember to surround the token with quotation marks.

variables.tf

    variable "token" {
      description = "DO Token"
      default = "57eaa5535910eae8e9359c0bed4161c895c2a40284022cbd2240..."
    }

Save and close the file.

Now let’s configure Terraform to use our SSH key pair.

## Step 3 — Add Your SSH Key Pair

Terraform needs an SSH key to connect to our server once it’s created, so it can install packages and deploy the application.

Look in your `~/.ssh` directory to see if you already have a key pair:

    ls -al ~/.ssh

Most likely, you have at least one key pair composed of a private and a public key. For example, you might have `id_rsa.pub` and `id_rsa`.

**Warning** : If your existing key pair is already associated with your DigitalOcean account, you’ll need to remove it using the DigitalOcean dashboard, or generate a new one to avoid conflicts.

If you don’t have any key pairs, or if the key you have is already associated with your DigitalOcean account, then please look at [DigitalOcean’s tutorial on setting up SSH keys](how-to-use-ssh-keys-with-digitalocean-droplets) to set one up.

You need to paste the contents of the `.pub` file into the `variables.tf` file, just like you did with the API token. If you are on a Mac, you can copy your SSH public key to your clipboard by issuing the following command:

    pbcopy < ~/.ssh/your_key.pub

You can also display the public key’s contents to the screen with the `cat` command and copy it to your clipboard manually:

    cat ~/.ssh/your_key.pub

Then open the file `variables.tf` in your editor and add the content of your SSH public key file to the `sshkey` setting:

variables.tf

    variable "sshkey" {
      description = "Public ssh key (for Cabin user)"
      default = "ssh-rsa AAAAB3NzaC1yc2EAAAADA...== nick@getstream.io"
    }

Once you’ve completed this step, save and exit the file.

If you’ve generated a new key for use with Terraform and DigitalOcean, you’ll need to run these two commands so your new key will be used instead of your default key:

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/your_id_rsa

You may need to run this each time you open a new shell if you are using an alternate key pair.

Now that you’ve provided Terraform with the variables it needs, you’re ready to create your server and deploy your app with Terraform.

## Step 4 — Running Terraform

Here comes the fun part! Let’s have a look at the infrastructure we are going to build. Terraform is going to do a lot of work for us, from setting up our server to deploying our app. We can have Terraform show us exactly what it’s going to do with the following command:

    terraform plan

The output of this command is quite verbose, so try to focus on the following statements:

    Output+ digitalocean_droplet.cabin-web
    ...
    + digitalocean_floating_ip.cabin-web-ip
    ...
    + digitalocean_ssh_key.cabin-ssh-key
    ...
    + template_file.pm2_processes_conf
    ...
    + template_file.userdata_web
    ...

The “+” symbol at the start of a line means that the resources will be created. The resources prefixed with `digitalocean` are the resources that will be created on DigitalOcean. In this specific case, Terraform will create a Droplet, a floating IP, and will add our SSH key.

**Warning** We are not responsible for charges that may accrue while your instance(s) or third party services are online. The command `terraform apply` will create a Droplet with 2GB of RAM (~$0.03/hour) and a floating IP which DigitalOcean provides free of charge. For exact numbers, double check the updated prices on DigitalOcean’s website.

Now it’s time to run Terraform and spin up Cabin on your Droplet.

    terraform apply

After a short time you will see Terraform print out the following:

    OutputApply complete! Resources: 6 added, 0 changed, 0 destroyed.
    
    The state of your infrastructure has been saved to the path
    below. This state is required to modify and destroy your
    infrastructure, so keep it safe. To inspect the complete state
    use the `terraform show` command.
    
    State path: terraform.tfstate
    
    Expected output:
    
      web_ipv4 = 111.111.111.111

`web_ipv4` is the floating IP address you can use to access to the Droplet.

Log into the newly-created Droplet using the value you see for `web_ipv4`:

    ssh cabin@your_value_for_web_ipv4

You can also use the command

    terraform output web_ipv4

to display the IP address associated with that value if you missed it.

You will see this welcome message when you log in:

       _____ _ _
      / ____ | | | (_)
     | | ___| |__ _ _ __
     | | / _` | '_ \| | '_ \
     | |___| (_| | |_) | | | | |
      \ _____\__ ,_|_.__/|_|_| |_|
    
    Initializing Cabin. Please wait... (up 1 minute) | CTRL+C to interrupt

You may need to wait several minutes for DigitalOcean to provision the instance and for `cloud-init` to install the required packages for Cabin. But once it’s ready, you’ll see this:

    Cabin initialized!
    Check running processes...
    ┌──────────┬────┬──────┬───────┬────────┬─────────┬────────┬─────────────┬──────────┐
    │ App name │ id │ mode │ pid │ status │ restart │ uptime │ memory │ watching │
    ├──────────┼────┼──────┼───────┼────────┼─────────┼────────┼─────────────┼──────────┤
    │ api │ 0 │ fork │ 14105 │ online │ 0 │ 36s │ 75.898 MB │ enabled │
    │ app │ 1 │ fork │ 14112 │ online │ 0 │ 36s │ 34.301 MB │ enabled │
    │ www │ 2 │ fork │ 14119 │ online │ 0 │ 36s │ 50.414 MB │ enabled │
    └──────────┴────┴──────┴───────┴────────┴─────────┴────────┴─────────────┴──────────┘
     Use `pm2 show <id|name>` to get more details about an app
    

Once Cabin is up and running, point your mobile browser to `http://your_value_for_web_ipv4`. Cabin is live and you should see a loading screen. But that’s as far as we’ll get until we make some changes to the code on the server.

## Step 5 — (Optionally) Configuring Cabin

The Cabin application is deployed, but it’s not usable yet. We have to configure Facebook and several other services if we want to get Cabin fully operational.

First, you’ll need to create a Facebook app using a valid domain name, like `cabin.example.com` that is mapped to the `web_ipv4` address that was generated during the installation process. Add a record to your DNS or add an entry to your `/etc/hosts` file that maps your domain to the IP address.

To create the Facebook app, follow these steps:

1. Visit [https://developers.facebook.com/docs/apps/register#step-by-step-guide](https://developers.facebook.com/docs/apps/register#step-by-step-guide).
2. Login to Facebook.
3. Under My Apps, click **Add a New App**.
4. Enter a name for your application (e.g. `Cabin - My Example App`).
5. Enter your **Contact Email**.
6. For **Category** , use the dropdown menu to select a category for the app. In our case, it’s **Lifestyle**.
7. Click the **Create App ID** button.
8. If required, complete the captcha.
9. Copy the `appId`. It will be a numeric value found at the top of the screen. You’ll need that shortly.
10. Choose **Dashboard** from the left sidebar.
11. Under the heading **Get Started with the Facebook SDK** , click **Choose A Platform**.
12. Choose **Web** for the platform.
13. Locate the **Site URL** field and enter `http://cabin.example.com`.
14. Click **Next**.

If you run into issues, you can follow [this step-by-step guide](https://developers.facebook.com/docs/apps/register#step-by-step-guide). If you get stuck, there’s a great article on debugging your application setup on Facebook, which can be found [here](https://www.facebook.com/help/community/question/?id=589302607826562).

Once you have your `appID` you’ll need to replace the default `appID` setting on the server.

So, ensure that you’re logged into your server. If you’re not, log back in with:

    ssh cabin@your_value_for_web_ipv4

Once logged in, open the file `~/stream-react-example/app/views/index.ejs`:

    nano ~/stream-react-example/app/views/index.ejs

Change the default `appId` with the one provided by Facebook.

strea-react-example/app/views/index.ejs

    FB.init({
        appId : 'your_facebook_app_id',
        xfbml : true,
        version : 'v2.6',
        status : true,
        cookie : true,
    })

Save this file and close it.

Next, you’ll need to know the database password for Cabin, which was generated by Terraform when it created the server. To get this value, type the following command:

    grep DB_PASSWORD processes.yml

Copy this password; you’ll need it shortly.

The file `env.sh` is where you’ll enter your credentials for the various providers and services that Cabin depends on. This file places these credentials into environment variables, which are then read by the application. This is a security precaution, as it keeps passwords and keys out of Git.

Open `env.sh`:

    nano env.sh

You’ll see the following content:

    Outputexport NODE_ENV=production
    export JWT_SECRET=ABC123
    export DB_USERNAME=cabin
    export DB_HOST=localhost
    export DB_PASSWORD=VALUE
    export DB_PORT=3306
    export MAPBOX_ACCESS_TOKEN=ADD_VALUE_HERE
    export S3_KEY=ADD_VALUE_HERE
    export S3_SECRET=ADD_VALUE_HERE
    export S3_BUCKET=ADD_VALUE_HERE
    export STREAM_APP_ID=ADD_VALUE_HERE
    export STREAM_KEY=ADD_VALUE_HERE
    export STREAM_SECRET=ADD_VALUE_HERE
    export ALGOLIA_APP_ID=ADD_VALUE_HERE
    export ALGOLIA_SEARCH_ONLY_KEY=ADD_VALUE_HERE
    export ALGOLIA_API_KEY=ADD_VALUE_HERE
    export KEEN_PROJECT_ID=ADD_VALUE_HERE
    export KEEN_WRITE_KEY=ADD_VALUE_HERE
    export KEEN_READ_KEY=ADD_VALUE_HERE
    export IMGIX_BASE_URL=https://react-example-app.imgix.net/uploads
    export API_URL=http://localhost:8000

As you can see, this file exports a bunch of environment variables that hold information about various services that Cabin needs. In order for Cabin to work in production, you’ll need to fill in all of these values.

Here’s a quick breakdown of these settings:

1. **NODE\_ENV** : The environment that Node.js will run in. (production will offer a speed enhancement).
2. **JWT\_SECRET** : Authentication secret for JSON Web Token authentication between the API and Web (app) interface.
3. **DB\_USERNAME** : The username for the database.
4. **DB\_HOST** : The database hostname.
5. **DB\_PASSWORD** : The password for the database, which you just viewed by looking at `processes.yml`.
6. **DB\_PORT** : Database port (default port 3306 for MySQL).
7. **MAPBOX\_ACCESS\_TOKEN** : Access token for MapBox (for mapping photo locations).
8. **S3\_KEY** : Amazon S3 key for image storage.
9. **S3\_SECRET** : Amazon S3 secret for image storage.
10. **S3\_BUCKET** : Amazon S3 bucket for image storage. Make sure this bucket exists.
11. **STREAM_APP_ID** : Stream app ID. Ensure that all of the required feed groups exist in the app associated with this ID.
12. **STREAM\_KEY** : Stream API key.
13. **STREAM\_SECRET** : Stream app secret.
14. **ALGOLIA\_APP\_ID** : Algolia app id for search.
15. **ALGOLIA\_SEARCH\_ONLY\_KEY** : Algolia search only key for search.
16. **ALGOLIA\_API\_KEY** : Algolia API key for search.
17. **KEEN\_PROJECT\_ID** : Keen tracking project id (for stats).
18. **KEEN\_WRITE\_KEY** : Keen tracking write key (for stats).
19. **KEEN\_READ\_KEY** : Keen tracking read key (for stats).
20. **IMGIX\_BASE\_URL** : Imgix base URL (for rendering photos at specific sizes).
21. **API\_URL** : The URL used by this application for its API. You’ll need to change this from `localhost` to the domain that points to your IP address, such as `cabin.example.com`.

For more details on the referenced environment variables and services, visit the following blog posts and ensure you have configured each application as specified:

- [Stream](http://blog.getstream.io/cabin-react-redux-example-app-stream/)
- [Imgix](http://blog.getstream.io/cabin-react-redux-example-app-imgix/)
- [Keen](http://blog.getstream.io/cabin-react-redux-example-app-keen/)
- [Algolia](http://blog.getstream.io/cabin-react-redux-example-app-algolia/)
- [Mapbox](http://blog.getstream.io/cabin-react-redux-example-app-mapbox/)

Once you’ve configured all of the providers, enter the password for your database and the values for the providers in the `env.sh` file.

Exit and save the `env.sh` file. Then source the file, loading the values into environment values that Cabin will use:

    source ./env.sh

Next, you’ll need to run the `webpack` command. Webpack is a JavaScript build tool that manages the frontend code for Cabin. Webpack will regenerate JavaScript and CSS files based on the values set by the `env.sh` file you just changed. So, change to the `app` directory:

    cd app

And then run the `webpack` command to rebuild the front-end JavaScript files. This will inject some of the provider tokens into the front-end code.

    webpack --progress --color

You will see the following output:

    OutputHash: 64dcb6ef9b46a0243a8c  
    Version: webpack 1.13.1
    Time: 21130ms
                      Asset Size Chunks Chunk Names
         ./public/js/app.js 2.22 MB 0 [emitted] app
    ./public/css/styles.css 23 kB 0 [emitted] app
       [0] multi app 28 bytes {0} [built]
        + 685 hidden modules
    Child extract-text-webpack-plugin:
            + 2 hidden modules
    Child extract-text-webpack-plugin:
            + 2 hidden modules

With the settings in place, run PM2 to reload all of the application processes to ensure that all components use the new settings:

    pm2 restart all

    Output[PM2] Applying action restartProcessId on app [all](ids: 0,1,2)
    [PM2] [api](0) ✓
    [PM2] [app](1) ✓
    [PM2] [www](2) ✓
    ┌──────────┬────┬──────┬───────┬────────┬─────────┬────────┬─────────────┬──────────┐
    │ App name │ id │ mode │ pid │ status │ restart │ uptime │ memory │ watching │
    ├──────────┼────┼──────┼───────┼────────┼─────────┼────────┼─────────────┼──────────┤
    │ api │ 0 │ fork │ 30834 │ online │ 516 │ 0s │ 39.027 MB │ enabled │
    │ app │ 1 │ fork │ 30859 │ online │ 9 │ 0s │ 22.504 MB │ enabled │
    │ www │ 2 │ fork │ 30880 │ online │ 9 │ 0s │ 19.746 MB │ enabled │
    └──────────┴────┴──────┴───────┴────────┴─────────┴────────┴─────────────┴──────────┘

That’s it! You can now log out of your remote server.

    exit

Finally, visit `http://your_value_for_web_ipv4` in your browser again to see the site. This will display a cover image with a link to log into Facebook. Once you log in, you’ll be able to explore the app later.

PM2 manages the processes for Cabin, and it can be a great tool to help you debug problems. You can use `pm2 list` to see the status of the application’s components, and `pm2 logs` to view a stream of the logs for the app, which can help you diagnose any configuration errors.

Now let’s dig into the Terraform configuration that made this deployment possible.

## Step 6 — Exploring the Configuration Tiles

So how does this all work? Let’s look at the files in the repository we cloned to our local machine. While there’s nothing for you to modify in this section, you should still follow along on your own machine so you can get a feel for how the pieces fit together.

The Terraform project is divided into multiple files and directories to keep the application clean and easy to understand. We’ve placed all of our DigitalOcean files inside of the `terraform/do` directory of the repository, which has the following structure:

terraform folder

    do
    └── cabin
        ├── files
        │ ├── cabin-web-nginx.conf
        │ └── cabin_mysql_init.sh
        ├── main.tf
        ├── outputs.tf
        ├── templates
        │ ├── processes.tpl
        │ └── web.tpl
        └── variables.tf

Let’s have a look at the above files, starting with `main.tf`. Open it up in your favorite text editor.

The first thing we do is tell Terraform what cloud provider we are going to use.

main.tf

    provider "DigitalOcean" {
      token = "${var.token}"
    }

Defining the DigitalOcean provider is as simple as that. You can find a full list of supported providers in the [Terraform documentation](https://www.terraform.io/docs/providers/index.html).

### Variable Configuration

Terraform allows you to define variables, which means you can set defaults for your deployment. That way you won’t have to enter the details each time or hard-code values throughout your configuration. Let’s look at how to set the variables for deployment on DigitalOcean.

Have a look at `variables.tf`, the location where we have defined the variables necessary to run the Cabin application.

variables.tf

    variable "token" {
      description = "DO Token"
    }
    
    variable "region" {
      description = "DO Region"
    }

To help you to better understand how the variables are processed inside Terraform, let’s go through the example above.

For the region variable, we specified a default value. If you don’t specify a default value, Terraform will prompt you for one, as shown in the following example:

    Outputterraform plan
    var.token
      DO Token
    
      Enter a value:

You can also supply variables when you run `terraform apply`. For example, if you wanted to specify a different region, you can run Terraform with the `var` argument:

    terraform -var 'region=ams3' apply

This overrides any configured settings.

### Droplet Setup

In `main.tf` we tell Terraform to provision a Droplet on DigitalOcean. By default, we deploy a server with the following characteristics:

main.tf

    resource "digitalocean_droplet" "cabin-web" {
      image = "ubuntu-14-04-x64"
      name = "cabin-web"
      region = "${var.region}"
      size = "2gb"
      ssh_keys = ["${digitalocean_ssh_key.cabin-ssh-key.id}"]
      user_data = "${template_file.userdata_web.rendered}"
    }

We are creating a new DigitalOcean Droplet with 2GB of RAM called **cabin-web** , and using the image **ubuntu-14-04-x64**. By looking at the resource definition above, you can see that it’s easy to change the image and size of the server.

### User Data & Cloud-Init

Okay, so what exactly is `user-data`? It’s the easiest way to send commands and instructions to a cloud instance at boot time. Coupled with `cloud-init`, it becomes a powerful way to configure your instance without leveraging unnecessary third-party applications like [Chef](https://www.chef.io/chef/) or [Puppet](https://puppet.com/).

The `cloud-init` program is embedded in many Linux distributions. It has a small set of instructions which let you perform simple tasks like adding users, managing groups, creating files, and running scripts or shell commands with root privileges.

Let’s dive into the `user_data` attribute so you have a better understanding of what it is:

main.tf

    resource "digitalocean_droplet" "cabin-web" {
      ...
      user_data = "${template_file.userdata_web.rendered}"
    }

Our goal is to start a new Droplet with Cabin up and running, and have `cloud-init` handle the heavy lifting for us. The `user_data` field points to a template file, using a variable points to another declaration in `main.tf`:

main.tf

    resource "template_file" "userdata_web" {
      template = "${file("${path.module}/templates/web.tpl")}"
    
      vars {
        userdata_sshkey = "${var.sshkey}"
        userdata_nginx_conf = "${base64encode(file("${path.module}/files/cabin-web-nginx.conf"))}"
        userdata_mysql_init = "${base64encode(file("${path.module}/files/cabin_mysql_init.sh"))}"
        userdata_pm2_conf = "${base64encode("${template_file.pm2_processes_conf.rendered}")}"
        userdata_env = "${base64encode("${template_file.env.rendered}")}"
        userdata_motd = "${base64encode(file("${path.module}/files/motd"))}"
        userdata_motd_script = "${base64encode(file("${path.module}/files/motd.sh"))}"
        userdata_giturl = "${var.git_url}"
        userdata_index = "${base64encode(file("${path.module}/files/index.html"))}"
      }
    }

Terraform provides functions that allow you to transform text. We can use this feature to inject values into templates by reading files and then converting the contents to Base64-encoded strings so they can be transferred through API calls.

This particular section prepares the data for the template `templates/web.tpl` which contains all of the settings and commands to execute on the server.

Let’s walk through the `web.tpl` file and see what it does.

The first part sets up the initial user and disables root access:

templates/web.tpl

    #cloud-config
    users:
      - name: cabin
        groups: sudo
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        shell: /bin/bash
        home: /home/cabin
        lock_passwd: true
        ssh-authorized-keys:
          - ${userdata_sshkey}
    
    disable_root: true

The very first statement in `web.tpl` must be `#cloud-config`. If you forget to add this, `cloud-init` will not pick up the configuration and the given commands will not be executed on the target instance.

The commands in this section do the following:

- add the `cabin` user to the system with a grant to become a super-user
- `lock-passwd: true` denies password authentication, so the `cabin` user will need to use SSH-key authentication to access the server.
- `ssh-authorized-keys` installs the user’s ssh-key into the authorized\_keys file.
- `disable_root: true` is used to disable SSH access as root

Remember that `${userdata_sshkey}` is a variable that was set when we invoked the template in `main.tf`.

Next, we install MySQL, Nginx, Git, and other packages we need for our application:

    package_update: true
    packages:
     - mysql-server-5.6
     - libmysqlclient-dev
     - iptables-persistent
     - git
     - nginx
     - npm
     - pwgen

The easiest way to install packages with `cloud-init` is by leveraging the Package module to install a list of given packages. This module uses the default package manager for the distribution. Since we’re using Ubuntu, this process will install packages with `apt`.

Next, we write some files to the file system, using data we passed in to the template as the file content:

    write_files:
     - encoding: b64
       content: ${userdata_nginx_conf}
       path: /tmp/cabin-web.conf
     - encoding: b64
       content: ${userdata_pm2_conf}
       path: /tmp/processes.yml
     - encoding: b64
       content: ${userdata_mysql_init}
       path: /tmp/cabin_mysql_init.sh
       permissions: '0554'

This section leverages the `write_file` module to create the files. In the example above, we are creating the following files:

- `cabin-web.conf` contains the NGINX configuration.
- `processes.yml` used by PM2 to handle the Node.js processes.
- `cabin_mysql_init.sh` is a custom script used to initialize the MySQL database.

Remember that when we passed the data to the template, we encoded it as Base64. We specify the encoding when we write the files so that the contents can be decoded.

In the next section, we use the `runcmd` module to run some shell commands to create firewall rules using `iptables`:

    runcmd:
     - iptables -A INPUT -i lo -j ACCEPT
     - iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
     - iptables -A INPUT -p tcp --dport ssh -j ACCEPT
     - iptables -A INPUT -p tcp --dport 80 -j ACCEPT
     - iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
     - iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
     - iptables -A INPUT -j DROP
     - iptables -A OUTPUT -j ACCEPT
     - invoke-rc.d iptables-persistent save
    …

The code then uses `iptables-persistent` to make the firewall configuration available in the event that the instance restarts.

After the firewall rules are in place, the rest of the commands to set up and start Cabin are executed:

     - apt-get update --fix-missing
     - curl -sL https://deb.nodesource.com/setup_5.x | bash && apt-get install -y nodejs
     - npm install pm2 webpack -g
     - cd /home/cabin && sudo -u cabin git clone ${userdata_giturl}
     - mv /tmp/env.sh /home/cabin/stream-react-example/env.sh
     - cd /home/cabin/stream-react-example/api && sudo -u cabin npm install
     - cd /home/cabin/stream-react-example/app && sudo -u cabin npm install
     - cd /home/cabin/stream-react-example/www && sudo -u cabin npm install
     - chown cabin.cabin /home/cabin/stream-react-example/env.sh && /home/cabin/stream-react-example/env.sh
     - mv /tmp/processes.yml /home/cabin/stream-react-example/processes.yml
     - chown cabin.cabin /home/cabin/stream-react-example/processes.yml
     - /tmp/cabin_mysql_init.sh
     - cd /home/cabin/stream-react-example && sudo -u cabin pm2 start processes.yml
     - mv /tmp/cabin-web.conf /etc/nginx/sites-available/cabin-web
     - rm /etc/nginx/sites-enabled/default
     - ln -s /etc/nginx/sites-available/cabin-web /etc/nginx/sites-enabled
     - service nginx reload

All of these commands are executed with root privileges, and _only happen at the very first boot_. If you reboot the machine, `runcmd` will not be executed again.

Now that you’ve learned more about Terraform, let’s explore how to handle your infrastructure’s lifecycle.

## Step 7 — Managing the Stack’s Lifecycle

Terraform makes it possible to save the state of your stack, update your stack, destroy it, and deploy code changes.

You may have noticed that after you run `terraform apply`, a file called `terraform.tfstate` is created in the `cabin` directory.

This file is very important as it contains the references to the actual resources created on DigitalOcean. Basically, this file tells Terraform the identifiers of the resources it manages.

If you run `terraform apply` again, Terraform won’t start over and wipe out everything you’ve created. Instead, it’ll only do the parts it hasn’t finished yet. So if your process fails in the middle because of a network issue or an API problem, you can address the issues and run the command again. Terraform will pick up where it left off.

### Changing the Droplet Configuration

You can also use `terraform apply` to change the Droplet’s configuration. For example, if you need to change data centers or regions, or increase the memory your Droplet uses in order to accommodate more traffic, Terraform makes both tasks extremely easy.

You can adjust the Droplet region by running the `terraform apply` command and overriding the `region` and `droplet_size` variables. This lets Terraform know that the existing Droplet needs to be destroyed, and a new Droplet needs to be provisioned in order to meet the requirements.

**Warning** : **Terraform will trash the existing Droplet**. Given that you’re running your MySQL database on the same server as your application, **this will also trash your MySQL data.**. To avoid this, we recommend either performing a database export prior to this step, or better yet, [running your MySQL database on a dedicated Droplet](how-to-install-mysql-on-ubuntu-14-04).

If you want to change the region or datacenter that holds your Droplet, execute the following command:

    terraform apply -var "region=sfo2"

And, as your user base grows, you’ll likely need to change the Droplet size to accommodate for the additional traffic. You can do that with the `droplet_size` variable like this:

    terraform apply -var "droplet_size=4gb"

The Droplet will be removed and replaced with a new one, and the application will be redeployed and configured.

### Destroying the Stack

One of the amazing things about Terraform is that it handles the entire lifecycle of the stack. You can easily destroy what you have built by running one simple Terraform command (destroy).

    terraform destroy

Terraform will then prompt you to confirm that you actually want to destroy all resources:

    OutputDo you really want to destroy?
      Terraform will delete all your managed infrastructure.
      There is no undo. Only 'yes' will be accepted to confirm.
    
      Enter a value: yes

Once Terraform is complete, the final output will look like the following:

    Outputdigitalocean_droplet.cabin-web: Destroying...
    digitalocean_droplet.cabin-web: Still destroying... (10s elapsed)
    digitalocean_droplet.cabin-web: Destruction complete
    digitalocean_ssh_key.cabin-ssh-key: Destroying...
    template_file.userdata_web: Destroying...
    template_file.userdata_web: Destruction complete
    template_file.pm2_processes_conf: Destroying...
    template_file.pm2_processes_conf: Destruction complete
    digitalocean_ssh_key.cabin-ssh-key: Destruction complete
    
    Apply complete! Resources: 0 added, 0 changed, 5 destroyed.

As you can see, all of the resources were destroyed.

### Deploying New Versions of Code

In the event that you make changes to your codebase, you’ll need to get the changes up to the server with little to no downtime. We have PM2 installed on our server, and it’ll handle the heavy lifting for us.

PM2 listens for filesystem changes in the application. In order to run a newer version of your code, simply SSH into the Droplet and issue the `git pull` command in the directory containing the application. This will instruct the server to pull from your repository. When the files change, PMZ will automatically restart the Node process.

For example, if there’s a new version of Cabin and you wanted to deploy the latest version of the code to the server, you would log in to your server:

    ssh cabin@your_value_for_web_ipv4

Then, on the server, navigate to the folder containing the Cabin application:

    cd ~/stream-react-example

And finally pull the latest version down.

    git pull

Once the new code is in place, your app will automatically restart, and visitors will see the newest version. If for some reason PM2 doesn’t catch a change, restart things manually with

    pm2 restart all

and all of the components will restart.

## Conclusion

Using DigitalOcean, Terraform, Cloud-init, and PM2, you’ve successfully set up a production environment for Cabin.

When using Terraform, all of your infrastructure is stored as code. This makes it easy for your team to track changes and collaborate. It also empowers you to make large infrastructure changes with relative ease.
