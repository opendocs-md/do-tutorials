---
author: Mohideen
date: 2017-10-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04
---

# How To Automate Elixir-Phoenix Deployment with Distillery and edeliver on Ubuntu 16.04

## Introduction

Built on the [Erlang](https://www.erlang.org/) programming language, [Elixir](https://elixir-lang.org/) is a functional programming language that’s popular for its focus on developer productivity and ease of writing highly concurrent and scalable applications.

[Phoenix](http://phoenixframework.org/) is a web framework built on Elixir to allow for the creation of highly performant web applications.

And when combined with two additional tools — [Distillery](https://github.com/bitwalker/distillery) and [edeliver](https://github.com/edeliver/edeliver) — you can completely automate the deployment of Phoenix projects from your development environment to a production server.

Distillery compiles Elixir applications into a single package that you can then deploy elsewhere. It also generates packages that allow for _hot-swapping_ of code, which means you can upgrade live applications with no downtime. All of this can be done with little to no configuration on your part, which sets Distillery apart from many other options.

edeliver automates this build and deployment process by taking care of repetitive tasks like building the application, transferring the built package to the server, migrating the database, and starting/updating the server. If needed, you can even configure edeliver to allow for an intermediate staging setup, too.

In this tutorial, you’ll install Erlang, Elixir, and Phoenix 1.3 on a local development machine and on a production server, you’ll simplify SSH communication between the two locations, and then you’ll create a sample Phoenix project to build and deploy with edeliver. Finally, you’ll secure the production server with an Nginx reverse proxy and SSL certificate.

By the end of the tutorial, you’ll have a single command that can:

- build a Phoenix release that is compatible with your production environment
- deploy the release to your production environment
- start your application in a production environment
- hot-swap the current production release by deploying a new release without any downtime

## Prerequisites

Before starting, ensure that you have the following:

- An Ubuntu-based local development machine. Although this tutorial’s instructions are written for an Ubuntu-based local development machine, one strength of this deployment process is that it’s completely independent of the production environment. For instructions on setting up local development machines on other operating systems, see the [official Elixir installation documentation](https://elixir-lang.org/install.html). Or, to set up an Ubuntu-based _remote_ development machine, follow [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04).

- A non-root user account with sudo privileges on an Ubuntu 16.04 production server with at least 1GB of RAM, set up by following the first four steps in [this initial server setup tutorial](initial-server-setup-with-ubuntu-16-04). 

- Nginx installed on the production server by following [this How To Install Nginx on Ubuntu 16.04 guide](how-to-install-nginx-on-ubuntu-16-04).

- A fully registered domain name. This tutorial will use `example.com` throughout. You can purchase a domain name on [Namecheap](https://namecheap.com), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.

- Both of the following DNS records set up for your server. You can follow [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them.

- Nginx secured with an SSL certificate by following [this setting up Let’s Encrypt with Nginx server blocks on Ubuntu 16.04 tutorial](how-to-set-up-let-s-encrypt-with-nginx-server-blocks-on-ubuntu-16-04). Be sure to choose option 2, `Redirect`, in Step 4 of the Nginx setup tutorial, as this will provide automatic redirects to HTTPS on the production server we’re creating in this tutorial.

## Step 1 — Installing Elixir and Phoenix on the Local Development Machine

Because Elixir runs on the Erlang VM, we’ll need to install the VM before we can install Elixir itself. And since we want to ensure that we’re using the most recent stable version of Erlang, we’ll install Erlang from the Erlang Solutions repository.

First, download and add the Erlang Solutions repository to your local development machine.

    cd ~
    wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
    sudo dpkg -i erlang-solutions_1.0_all.deb

Now, update your package list and install the `esl-erlang` package which provides both the Erlang programming language as well as useful tools, libraries, and middleware, collectively referred to as the Erlang/OTP platform.

    sudo apt-get update
    sudo apt-get install esl-erlang

Then, install Elixir.

    sudo apt-get install elixir

Next, use Mix — a build tool bundled with Elixir for creating Elixir projects and managing dependencies — to install Elixir’s own package manager, [Hex](https://hex.pm/), which you’ll use later to install Phoenix.

The `local` part of this command tells Mix to install `hex` locally.

    mix local.hex

When prompted to confirm the installation, enter `Y`.

    OutputAre you sure you want to install "https://repo.hex.pm/installs/1.5.0/hex-0.17.1.ez"? [Yn] Y
    * creating .mix/archives/hex-0.17.1

Now, use Hex to install the Phoenix 1.3.0 Mix archive, a Zip file that contains everything you’ll need to generate a new base Phoenix project to build off of.

    mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new-1.3.0.ez

Again, when prompted to confirm the installation, enter `Y`.

    OutputAre you sure you want to install "https://github.com/phoenixframework/archives/raw/master/phx_new-1.3.0.ez"? [Yn] Y
    * creating .mix/archives/phx_new-1.3.0

**Warning:** If you install Phoenix from the `phx_new.ez` archive, you’ll get the latest version of Phoenix, which may be different than the one we use in this tutorial — 1.3.0. You’ll then have to adapt this tutorial to the version of Phoenix you are using.

With Elixir and Phoenix installed on the local development machine, let’s install the pieces we need on the production server.

## Step 2 — Installing Elixir and Phoenix on the Production Server

Because we need our Phoenix project to run on both the local development machine and the production server, we’ll need to install all of the same languages and tools in both places.

Using the same commands from Step 1, download and add the Erlang Solutions repository to your production server.

    cd ~
    wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
    sudo dpkg -i erlang-solutions_1.0_all.deb

Update your package list and install the `esl-erlang` package.

    sudo apt-get update
    sudo apt-get install esl-erlang

Install Elixir.

    sudo apt-get install elixir

Use Mix to install Hex.

    mix local.hex

When prompted to confirm the installation, enter `Y`.

    OutputAre you sure you want to install "https://repo.hex.pm/installs/1.5.0/hex-0.17.1.ez"? [Yn] Y
    * creating .mix/archives/hex-0.17.1

Both the local development machine and the production server are now ready to run Phoenix, but let’s make it easier to connect to the production server from the local development machine by setting up an SSH host alias.

## Step 3 — Setting Up an SSH Host Alias

Because our goal is a completely automated deployment process, we generated an SSH key pair during the initial production server setup that doesn’t prompt for a passphrase.

Right now, we can connect from the local development machine to the production server with the command `ssh -i ~/.ssh/private_key_file sammy@example.com`.

Here, we’re connecting to `example.com` as the user **sammy**. The `-i` flag tells SSH to use the private key file located at `~/.ssh/private_key_file` for the connection.

We can make this command — and the deployment process itself — even simpler, though, by setting up an SSH host alias that automatically knows which private key, user, and domain to use when connecting to the production server.

Open `~/.ssh/config` on the local development machine for editing.

    nano ~/.ssh/config

And, copy in the following lines.

~/.ssh/config

    Host example.com 
        HostName example.com
        User sammy
        IdentityFile ~/.ssh/private_key_file

**Note:** If your `config` file already has something in it, include an additional empty line separating this new configuration from any existing ones.

The `Host` line provides an alias that identifies this particular configuration. To make it easier to remember, we’re using our domain name. The `HostName` line tells SSH the host to connect to. The `User` line lets SSH know which user to connect as, and the `IdentityFile` tells SSH which private key file to use.

Save your changes and close the file.

Finally, test the configuration by connecting to the production server.

    ssh example.com

You should have been able to make the connection without specifying a user, private key file, or domain. If you weren’t able to connect, follow the on-screen messages and retrace the previous steps to resolve the problem.

Now that we’ve simplified connecting to the production server, we can create a sample Phoenix project for deployment.

## Step 4 — Creating a Test Project

By default, when you create a new Phoenix project, it’s configured with a [PostgreSQL](https://www.postgresql.org/) database adapter and [Brunch](http://brunch.io/), a JavaScript-based web application build tool. To avoid this additional complexity, we’ll create a simple Phoenix project named `myproject` without a database adapter and without Brunch by passing in the `--no-ecto` and `--no-brunch` flags respectively.

Change to your home directory and create the new project.

    cd ~
    mix phx.new --no-ecto --no-brunch myproject

The output includes the directories and files that Phoenix created as the scaffolding for the `myproject` project, a prompt to confirm that you want to install the required dependencies, and instructions about how to start Phoenix’s built-in server.

Enter `Y` when prompted to confirm the installation.

    Output* creating myproject/config/config.exs
    * creating myproject/config/dev.exs
    * creating myproject/config/prod.exs
    ...
    
    Fetch and install dependencies? [Yn] Y
    * running mix deps.get
    * running mix deps.compile
    
    We are all set! Go into your application by running:
    
        $ cd myproject
    
    Start your Phoenix app with:
    
        $ mix phx.server
    
    You can also run your app inside IEx (Interactive Elixir) as:
    
        $ iex -S mix phx.server

Now, let’s see if our test project is working.

Go into the `myproject` directory and run the `mix phx.server` command to compile the project and start the server.

    cd ~/myproject
    mix phx.server

The output tells you the number and types of files Phoenix compiled, gives you warnings about issues it ran into along the way, and, if successful, lets you know where to reach the project.

The first time you compile an Elixir-based application on your local development machine, you’ll be prompted to install Rebar, a build and dependency tool for Erlang that Mix relies on. Enter `Y` at the prompt.

    Output==> file_system
    Compiling 6 files (.ex)
    Generated file_system app
    ...
    Could not find "rebar3", which is needed to build dependency :ranch
    I can install a local copy which is just used by Mix
    Shall I install rebar3? (if running non-interactively, use "mix local.rebar --force") [Yn] Y
    ...
    Compiling 11 files (.ex)
    Generated myproject app
    [info] Running MyprojectWeb.Endpoint with Cowboy using http://0.0.0.0:4000

To test the current setup, point your web browser to [http://localhost:4000](http://localhost:4000). You should see the default Phoenix Framework homepage welcoming you to Phoenix. If you don’t, make sure that your firewall is allowing connections on port `4000` and then review your terminal output for further instructions.

Once you’ve verified that everything’s working, press `CTRL+C` twice to stop the server so that it’s ready for further configuration in Step 5.

Now that you have a fully-functional, local Phoenix project, let’s configure it to use Distillery and edeliver.

## Step 5 — Configuring the Project to use Distillery and edeliver

Phoenix projects store configuration details like the port the project runs on and the project’s host URL in `config/prod.exs`, so we’ll begin by editing that file to tell Phoenix how to reach the project in the production environment.

Open `config/prod.exs` on your local development machine for editing.

    nano ~/myproject/config/prod.exs

Find the following block of code:

config/prod.exs

    ...
    config :myproject, MyprojectWeb.Endpoint,
      load_from_system_env: true,
      url: [host: "example.com", port: 80],
      cache_static_manifest: "priv/static/cache_manifest.json"
    ...

When `load_from_system_env` is set to `true`, Phoenix gets the port the project should run on from the `PORT` environment variable by default. This is referred to as the HTTP port.

The `url: [host]` and `url: [port]` are used to generate links within the project. This difference between HTTP and URL is particularly helpful when setting up proxies where the proxy endpoint is exposed on a different port than the Phoenix project.

For simplicity’s sake, we’ll hardcode in the HTTP port that the `myproject` runs on. This will reduce the number of moving parts, which, in turn, will increase the reliability of our automated deployment process.

In addition to the default options we’ll be modifying, we’ll also be adding two new options.

The `server` option tells Distillery to configure the project to boot the HTTP server on start, which is what we want in a fully automated deployment process.

The `code_reloader` option tells the project to refresh all connected web browsers whenever the project’s code changes. While this can be a very helpful feature in development, it’s not meant for production environments, so we’ll turn it off.

Now, modify the default configuration.

config/prod.exs

    ...
    config :myproject, MyprojectWeb.Endpoint,
      http: [port: 4000],
      url: [host: "example.com", port: 80],
      cache_static_manifest: "priv/static/manifest.json",
      server: true,
      code_reloader: false
    ...

**Note:** To avoid potential configuration problems, double-check that you’ve added a `,` to the end of the `cache_static_manifest` line before continuing.

Save and close `config/prod.exs` once you’ve made your changes.

When we created the `myproject` project in Step 4, Phoenix automatically generated a `.gitignore` file that we’ll need in Step 6 when we push code changes to the build server with edeliver.

By default, that `.gitignore` file tells Git to ignore dependencies and build files so that the repository doesn’t become unnecessarily large. Additionally, that file tells Git to ignore `prod.secret.exs`, a file in the `config` directory of all Phoenix projects that holds very sensitive information, like production database passwords and application secrets for signing tokens.

Since the `myproject` project needs `prod.secret.exs` on the production server to function properly and we can’t move it there with Git, we’ll have to transfer it to the server manually.

In your home directory on the production server, create a new directory called `app_config`. This is where you’ll store `prod.secret.exs`.

    cd ~
    mkdir app_config

Now, use `scp` to copy `prod.secret.exs` to the `app_config` directory on the production server.

    scp ~/myproject/config/prod.secret.exs example.com:/home/sammy/app_config/prod.secret.exs

Finally, verify that the transfer happened by listing the contents of `app_config` on the production server.

    ls ~/app_config

If you don’t see `prod.secret.exs` in the output, review the terminal on your local development machine for additional information.

With `prod.secret.exs` on the production server, we’re ready to install Distillery for the build process and edeliver for deployment by including them both in `mix.exs`, the main configuration file for the `myproject` project.

Open `mix.exs` on your local development machine.

    nano ~/myproject/mix.exs

Now, find the following block of code:

Dependencies in mix.exs

      ...
      defp deps do
        [
          {:phoenix, "~> 1.3.0"},
          {:phoenix_pubsub, "~> 1.0"},
          {:phoenix_html, "~> 2.10"},
          {:phoenix_live_reload, "~> 1.0", only: :dev},
          {:gettext, "~> 0.11"},
          {:cowboy, "~> 1.0"}
        ]
      end
      ...

`deps` is a private function that explicitly defines all of our `myproject` project’s dependencies. While it’s not strictly required, it does help keep the project configuration organized.

Add `edeliver` and `distillery` to the list of dependencies.

Dependencies in mix.exs

      ...
      defp deps do
        [
          {:phoenix, "~> 1.3.0"},
          {:phoenix_pubsub, "~> 1.0"},
          {:phoenix_html, "~> 2.10"},
          {:phoenix_live_reload, "~> 1.0", only: :dev},
          {:gettext, "~> 0.11"},
          {:cowboy, "~> 1.0"},
          {:edeliver, "~> 1.4.3"},
          {:distillery, "~> 1.4"}
        ]
      end
      ...

**Note:** To avoid potential configuration problems, double-check that you’ve added a , to the end of the line preceding the new `edeliver` entry.

Save your changes and close `mix.exs`.

Now, tell `mix` to fetch the new dependencies so that they’re available at runtime.

    cd ~/myproject/
    mix deps.get

The output tells us that `edeliver` and `distillery` have successfully been added to our project.

    OutputResolving Hex dependencies...
    Dependency resolution completed:
      ...
    * Getting edeliver (Hex package)
      Checking package (https://repo.hex.pm/tarballs/edeliver-1.4.4.tar)
      Fetched package
    * Getting distillery (Hex package)
      Checking package (https://repo.hex.pm/tarballs/distillery-1.5.2.tar)
      Fetched package

Finally, restart Phoenix’s server on the local development machine to test the current configuration.

    mix phx.server

Point your browser to [http://localhost:4000](http://localhost:4000). You should see the same default Phoenix homepage that you saw in Step 4. If you don’t, re-trace the previous steps and review your local development machine’s terminal for additional information.

When you’re ready to continue, press `CTRL+C` twice to stop the server so that it’s ready for further configuration in the next step.

With Distillery and edeliver installed, we’re ready to configure them for deployment.

## Step 6 — Configuring Edeliver and Distillery

Distillery requires a build configuration file that is not generated by default. However, we can generate a default configuration by running `mix release.init`.

Go into the `myproject` directory on your local development machine and generate the configuration file.

    cd ~/myproject
    mix release.init

The output confirms that the file was created and includes further instructions about how to edit and build the release.

    OutputAn example config file has been placed in rel/config.exs, review it,
    make edits as needed/desired, and then run `mix release` to build the release

edeliver will look for releases in the `rel/myproject` directory when performing hot upgrades, but Distillery puts releases in the `_build` directory by default. So, let’s modify Distillery’s default configuration file, `rel/config.exs`, to put production releases in the right place.

Open `rel/config.exs` in your editor.

    nano rel/config.exs

Find the following section:

rel/config.exs

    ...
    environment :prod do
      set include_erts: true
      set include_src: false
      set cookie: :"f3a1[Q^31~]3~N=|T|T=0NvN;h7OHK!%%c.}$)iP9!X|TS[X@sqG=m`yBYVt4/`:"
    end
    ...

This block tells Distillery how we want it to build self-contained production release packages. `include_erts` indicates whether we want to bundle the Erlang Runtime System, which is useful when the target system doesn’t have Erlang or Elixir installed. `include_src` indicates whether we want to include the source code files. And, the `cookie` value is used for authenticating Erlang nodes to communicate with one another.

Close the file.

We’re now ready to configure edeliver, but we’ll have to create its configuration file manually.

Go into the `myproject` directory on your local development machine and create a new directory called `.deliver`, then open a new file at `.deliver/config` for editing.

    cd ~/myproject
    mkdir .deliver
    nano .deliver/config

In this file, we’ll specify the build and production servers’ details. Since we’re using the same server for both building and production, our host and user are the same across build and production. Additionally, we’ll perform the build in the `app_build` directory and place the compiled production files in the `app_release` directory.

Copy the following into the file.

.deliver/config

    APP="myproject"
    
    BUILD_HOST="example.com"
    BUILD_USER="sammy"
    BUILD_AT="/home/sammy/app_build"
    
    PRODUCTION_HOSTS="example.com" 
    PRODUCTION_USER="sammy" 
    DELIVER_TO="/home/sammy/app_release" 

Next, we’ll create a symlink in the build folder to `prod.secret.exs`, the file we transferred to the `app_config` directory on the production server in Step 5. This symlink is created inside an _edeliver hook_. At each point in the build, stage, and deployment process, a specific hook is called by edeliver. For our automated deployment setup, we’re listening to the `pre_erlang_get_and_update_deps` hook that’s called before edeliver gets our dependencies and begins compilation.

Append the following to `.deliver/config`.

.deliver/config

    pre_erlang_get_and_update_deps() {
      local _prod_secret_path="/home/sammy/app_config/prod.secret.exs"
      if ["$TARGET_MIX_ENV" = "prod"]; then
        __sync_remote "
          ln -sfn '$_prod_secret_path' '$BUILD_AT/config/prod.secret.exs'
        "
      fi
    }

Save and close the file when you’re done editing.

Because edeliver uses Git to push the code from the latest commit to the build server for further action, the final step before deployment is to create a Git repository for our project.

In the `myproject` directory on your local development machine, use the `git init` command to create an empty Git repository.

    cd ~/myproject
    git init

Before we add our files to the Git index, we need to add the directory containing our release tarballs to the `.gitignore` file, too. Otherwise, the Git repository would become very large in size after a few releases.

    echo ".deliver/releases/" >> .gitignore

Next, add the complete set of files from the `myproject` project to the Git staging area so that they’ll be included in the next commit.

    git add .

Now, set the identity that Git should associate with this repository. This will help you track where changes to your project came from.

    git config user.email "you@example.com"
    git config user.name "Your Name"

Finally, commit the files to the repository using the `-m` option to describe the reason for the commit.

    git commit -m "Setting up automated deployment"

The output repeats back your commit message and then reports the number of files changed, the number of lines inserted, and the names of the files that were added to the repository.

    Output[master (root-commit) e58b766] Setting up automated deployment
     39 files changed, 2344 insertions(+)
     create mode 100644 .deliver/config
    ...

With our project now committed to Git and Distillery and edeliver fully configured, we’re ready for our first deployment.

## Step 7 — Deploying the Project

One benefit of this deployment process is that you’ll do almost everything on the local development machine, rarely ever needing to touch the production server.

Let’s myproject everything out now by pushing the `myproject` project to the production server.

First, use `mix` on your local development machine to build a release of the project and transfer it to the build server with edeliver.

    cd ~/myproject
    mix edeliver build release

The output updates you about each step of the build process in realtime and, if everything works as expected, tells you that the build was successful.

    OutputBUILDING RELEASE OF MYPROJECT APP ON BUILD HOST
    
    -----> Authorizing hosts
    -----> Ensuring hosts are ready to accept git pushes
    -----> Pushing new commits with git to: sammy@example.com
    -----> Resetting remote hosts to fc86f878d96...
    -----> Cleaning generated files from last build
    -----> Fetching / Updating dependencies
    -----> Compiling sources
    -----> Generating release
    -----> Copying release 0.0.1 to local release store
    -----> Copying myproject.tar.gz to release store
    
    RELEASE BUILD OF MYPROJECT WAS SUCCESSFUL!

If your build wasn’t successful, edeliver will indicate the line of code it was trying to execute when it encountered the problem. You can use that information to troubleshoot the issue.

Once the build is complete, transfer the release to the production server.

    mix edeliver deploy release to production

Once again, the output updates you about each step of the process in realtime and, if everything works, tells you the build was released to production.

    OutputDEPLOYING RELEASE OF MYPROJECT APP TO PRODUCTION HOSTS
    
    -----> Authorizing hosts
    -----> Uploading archive of release 0.0.1 from local release store
    -----> Extracting archive myproject.0.1.tar.gz
    
    DEPLOYED RELEASE TO PRODUCTION!

If you run into a problem deploying, examine the output in your terminal for additional information.

Finally, start the `myproject` project on the production server.

    mix edeliver start production

The output tells you the user that the project is running as, the host it’s running on, and the path to the release it’s using on the production server. The response will be `START DONE!`.

    OutputEDELIVER MYPROJECT WITH START COMMAND
    
    -----> starting production servers
    
    production node:
    
      user : sammy
      host : example.com
      path : /home/sammy/app_release
      response:
    
    START DONE!

Test the deployment process by pointing your browser to `http://example.com:4000`. You should once again see the default Phoenix Framework homepage. If you don’t, double-check that port `4000` is open on the production server and then consult the local development machine’s terminal for additional information.

Now that we’ve verified the complete build and deploy process, let’s take our setup one step further by performing a code update without any downtime on the production server.

## Step 8 — Upgrading the Project Without Production Downtime

One feature of our build and deployment process is the ability to hot-swap the code, updating the project on the production server without any downtime. Let’s make some changes to the project to try this out.

Open the project’s homepage file for editing.

    nano ~/myproject/lib/myproject_web/templates/page/index.html.eex

Find the following line:

~/myproject/web/templates/page/index.html.eex

    ...
    <h2><%= gettext "Welcome to %{name}", name: "Phoenix!" %></h2>
    ...

Now, replace that line with the following:

    <h2>Hello, World!</h2>

Save and close the file.

Now that we’ve updated the codebase, we also need to increment the application version. The version number makes it easier to track releases and rollback to previous versions if necessary.

Open `mix.exs` on your local development machine.

    nano ~/myproject/mix.exs

Find the following block:

mix.exs

      ...
      def project do
        [app: :myproject,
         version: "0.0.1",
         elixir: "~> 1.2",
         elixirc_paths: elixirc_paths(Mix.env),
         compilers: [:phoenix, :gettext] ++ Mix.compilers,
         build_embedded: Mix.env == :prod,
         start_permanent: Mix.env == :prod,
         deps: deps()]
      end
      ...

Increment the version from `0.0.1` to `0.0.2`.

mix.exs

      ...
      def project do
        [app: :myproject,
         version: "0.0.2",
         elixir: "~> 1.2",
         elixirc_paths: elixirc_paths(Mix.env),
         compilers: [:phoenix, :gettext] ++ Mix.compilers,
         build_embedded: Mix.env == :prod,
         start_permanent: Mix.env == :prod,
         deps: deps()]
      end
      ...

Then, save and close the file.

Now we need to add and commit our changes to Git so that edeliver knows it should push them to the build server.

    git add .
    git commit -m "Changed welcome message"

Finally, we’re ready to hot-swap our changes. This time around, we have a single command that’s equivalent to the three related commands we used in Step 7.

With one command, build, deploy, and re-start the application on the production server.

    mix edeliver upgrade production

Once again, the output takes us through each step of the process in realtime and, if successful, ends with, `UPGRADE DONE!`.

    OutputEDELIVER MYPROJECT WITH UPGRADE COMMAND
    
    -----> Upgrading to revision 2fc28b6 from branch master
    -----> Detecting release versions on production hosts
    -----> Deploying upgrades to 1 online hosts
    -----> Checking whether installed version 0.0.1 is in release store
    -----> Building the upgrade from version 0.0.1
    -----> Authorizing hosts
    -----> Validating * version 0.0.1 is in local release store
    -----> Ensuring hosts are ready to accept git pushes
    -----> Pushing new commits with git to: sammy@example.com
    -----> Resetting remote hosts to 2fc28b6...
    -----> Cleaning generated files from last build
    -----> Checking out 2fc28b6...
    -----> Fetching / Updating dependencies
    -----> Compiling sources
    -----> Checking version of new release
    -----> Uploading archive of release 0.0.1 from local release store
    -----> Extracting archive myproject_0.0.1.tar.gz
    -----> Generating release
    -----> Removing built release 0.0.1 from remote release directory
    -----> Copying release 0.0.2 to local release store
    -----> Copying myproject.tar.gz to release store
    -----> Upgrading production hosts to version 0.0.2
    -----> Authorizing hosts
    -----> Uploading archive of release 0.0.2 from local release store
    -----> Upgrading release to 0.0.2
    
    UPGRADE DONE!

To verify that everything worked, reload `http://example.com:4000` in your browser. You should see the new message. If you don’t, re-trace the previous steps and check your terminal for additional error and warning messages.

The deployment process has now been reduced to just a single command, and we’re also making use of one of Erlang’s most famous features — code hot-swapping. As a final touch, let’s fortify our application in production by putting it behind an Nginx proxy.

## Step 9 — Setting Up a Reverse Proxy on the Production Server

Although we can directly expose our application to the Internet, a reverse proxy will provide better security. For ease of configuration, support for SSL, and the ability to set custom HTTP response headers, we’ll use Nginx for our proxy.

If you followed the [setting up Let’s Encrypt with Nginx server blocks on Ubuntu 16.04 tutorial](how-to-set-up-let-s-encrypt-with-nginx-server-blocks-on-ubuntu-16-04) in the prerequisites, you should have already created a separate Nginx server block on the production server just for our project.

Open that server block’s configuration file for editing.

    sudo nano /etc/nginx/sites-available/example.com

First, we need to tell Nginx where our Phoenix project resides and which port it listens on. Since we’re serving our project on port `4000` locally, we’re telling Nginx that our proxy endpoint is at `127.0.0.1:4000`.

Copy the following code into the configuration file above the default server configuration block.

/etc/nginx/sites-available/example.com

    upstream phoenix {
        server 127.0.0.1:4000;
    }

Now, in the same file, find the following code block:

/etc/nginx/sites-available/example.com

        ...
            location / {
                    # First attempt to serve request as file, then
                    # as directory, then fall back to displaying a 404.
                    try_files $uri $uri/ =404;
            }
        ...

For the proxy to work, we need to tell Nginx to redirect all connections to the web server to our Phoenix project, including the request header, the IP address of the server that the client has been proxied through, and the IP address of the client itself.

We’ll also configure Nginx to forward incoming requests by way of [WebSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API), a protocol for messaging between web servers and clients that upgrades the standard stateless HTTP connection to a persistent one.

Phoenix has a feature called Channels that we didn’t explore in this tutorial, but Channels require support for WebSockets. Without this configuration, Channels won’t work because WebSocket requests won’t make it to the server.

Replace the previous `location` block with the following:

/etc/nginx/sites-available/example.com

      location / {
        allow all;
    
        # Proxy Headers
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Cluster-Client-Ip $remote_addr;
    
        # WebSockets
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    
        proxy_pass http://phoenix;
      }

Save and close the file to continue.

Now, verify the new Nginx configuration.

    sudo nginx -t

Nginx should report that the syntax is okay and that the test was successful. If not, follow the on-screen messages to resolve the problem.

Restart Nginx to propagate the changes.

    sudo systemctl restart nginx

Lastly, for security purposes, disallow access to your application via HTTP on port `4000`.

    sudo ufw delete allow 4000

Then, check UFW’s status.

    sudo ufw status

The firewall should only allow SSH and Nginx access at this point.

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx Full ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx Full (v6) ALLOW Anywhere (v6)

Finally, test that everything’s working by pointing your browser to `https://example.com`.

You now have a fully automated build and deploy process and a production server secured both by a reverse proxy and an SSL certificate.

## Conclusion

Even though we’ve set up edeliver to build and deploy our Phoenix project to a production server with a single command, there’s still a lot more you can do.

Most production Phoenix applications use a database. In [How to Deploy Elixir-Phoenix Applications with MySQL on Ubuntu 16.04](how-to-deploy-elixir-phoenix-applications-with-mysql-on-ubuntu-16-04), you’ll continue working with this application as you add a MySQL database and deploy new features to production.

If your production infrastructure is composed of a cluster of Phoenix nodes, you can use edeliver to deploy to and perform hot-swapping on all of the nodes at once.

Or, if you want a setup with greater reliability, you can create a full-blown staging infrastructure and use edeliver to manage the process of staging and deploying.

To find out more about either of these topics or to learn more about extending your current edeliver installation in general, visit the project’s [official home on GitHub](https://github.com/edeliver/edeliver).
