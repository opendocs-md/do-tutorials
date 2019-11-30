---
author: mohideen
date: 2018-05-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-elixir-phoenix-applications-with-mysql-on-ubuntu-16-04
---

# How To Deploy Elixir-Phoenix Applications with MySQL on Ubuntu 16.04

_The author selected [Code.org](https://www.brightfunds.org/organizations/code-org) to receive a $300 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

In the tutorial [How to Automate Elixir Phoenix Deployment with Distillery and edeliver](how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04), you created a Phoenix application without a database and deployed it to a production server with [edeliver](https://github.com/edeliver/edeliver). Most real-world applications require a database which requires some modifications to the deployment process.

You can use edeliver to push application and database changes to your production server at the same time so you can manage database changes during deployments.

In this guide, you’ll configure your existing Phoenix application to connect to a MySQL database using [Phoenix-Ecto](https://github.com/phoenixframework/phoenix_ecto) and [Mariaex](https://github.com/xerions/mariaex). Ecto is a widely used database wrapper for Phoenix applications. Mariaex is a database driver that integrates with Ecto and talks to MySQL and MariaDB databases.

You’ll also create a simple address book on your development machine that makes use of a database and use edeliver to deploy the changes to your production server. Users of your site will be able to create, read, update, and delete entries in this address book.

## Prerequisites

To complete this tutorial, you’ll need:

- The finished Phoenix application from the tutorial [How to Automate Elixir Phoenix Deployment with Distillery and edeliver](how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04). This app should be running behind Nginx using a Let’s Encrypt certificate and be deployed with edeliver.
- MySQL installed on your server by following [How To Install MySQL on Ubuntu 16.04](how-to-install-mysql-on-ubuntu-16-04).
- MySQL installed on your local development machine for testing the database before you deploy.

## Step 1 — Adding Mariaex and Ecto to Your Application

Typically, Phoenix applications do not directly establish connections to databases and execute SQL queries. Instead, a _database driver_ is used to connect to the desired database and a _database wrapper_ is then used to query the database.

A database driver is an Elixir application that takes care of the mundane tasks of using a database such as establishing connections, closing connections and executing queries. The database wrapper is a layer on top of the database driver that allows Elixir programmers to create database queries with Elixir code and provides additional features such as query composition (chaining of queries).

This separation makes for a modular application. The database wrapper, and therefore the application code to interact with the database, is largely the same regardless of the database used. Just by changing the database driver, Phoenix applications can use a different database software.

Since you supplied the `--no-ecto` flag when creating your application in the [previous tutorial](how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04), the application has neither Ecto nor Mariaex installed. You’ll add Ecto and Mariaex as dependencies on your project now.

**Note:** Phoenix applications use PostgreSQL by default. To generate a new application with a MySQL database, use the command `mix phx.new --database mysql myproject`.

First, switch to the directory containing your Phoenix project.

    cd ~/myproject

Then open the `mix.exs` file, which contains the list of dependencies for your application.

    nano mix.exs

Find the following block of code:

~/myproject/mix.exs

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

Add Mariaex and Phoenix-Ecto as dependencies:

~/myproject/mix.exs

      defp deps do
        [
          {:phoenix, "~> 1.3.0"},
          {:phoenix_pubsub, "~> 1.0"},
          {:phoenix_html, "~> 2.10"},
          {:phoenix_live_reload, "~> 1.0", only: :dev},
          {:gettext, "~> 0.11"},
          {:cowboy, "~> 1.0"},
          {:edeliver, "~> 1.4.3"},
          {:distillery, "~> 1.4"},
          {:phoenix_ecto, "~> 3.2"},
          {:mariaex, "~> 0.8.2"}
        ]
      end

**Warning:** To avoid potential configuration problems, double-check that you’ve added a comma (,) at the end of the line preceding the new `phoenix_ecto` entry.

Save and close `mix.exs`. Then run the following command to download the dependencies you just added to the project.

    mix deps.get

You’ll see this output as your dependencies are installed:

    OutputRunning dependency resolution...
    ...
    * Getting phoenix_ecto (Hex package)
      Checking package (https://repo.hex.pm/tarballs/phoenix_ecto-3.3.0.tar)
      Fetched package
    * Getting mariaex (Hex package)
      Checking package (https://repo.hex.pm/tarballs/mariaex-0.8.3.tar)
      Fetched package
    ...

The output shows that Mix checked for compatibility between the packages and got the packages along with their dependencies from the Hex repository. If this command fails, ensure that you have Hex installed and have modified `mix.exs` correctly.

With Ecto and Mariaex in place, you can set up the Ecto repository.

## Step 2 — Setting Up an Ecto Repository in Your Application

Phoenix applications access the database through a database wrapper called Ecto. The database wrapper is implemented in the form of an Elixir module in your project. You can import this module whenever you need to interact with the database and use the functions the module provides. The wrapped database is referred to as the _repository_.

This repository module must include the `Ecto.Repo` macro to give access to the query functions defined by Ecto. Additionally, it has to contain the code to initialize the options passed to the database adapter in a function named `init`.

If you hadn’t used the `--no-ecto` flag when creating your Phoenix project, Phoenix would have automatically generated this module for you. But since you did, you’ll have to create it yourself.

Let’s create the module in a file named `repo.ex` in the `lib/myproject` directory. First create the file:

    nano lib/myproject/repo.ex

Add the following code into the file to define the repository:

~/myproject/lib/myproject/repo.ex

    defmodule Myproject.Repo do
      use Ecto.Repo, otp_app: :myproject
    
      @doc """
      Dynamically loads the repository url from the
      DATABASE_URL environment variable.
      """
      def init(_, opts) do
        {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
      end
    end

By default, Phoenix projects define the `init` function such that if the environment variable `DATABASE_URL` exists, then Ecto will use the configuration in the environment variable to connect to the database instead of using the credentials in the Phoenix configuration files (as we do in this tutorial later).

Save and close `repo.ex`.

Phoenix projects use lightweight Elixir processes for concurrency and fault-tolerance. _Supervisors_ manage these processes and restart them, should they crash. Supervisors can also supervise other supervisors, and this structure is called a _supervision tree_.

The `Myproject.Repo` module you just added implements a supervisor that manages processes connecting to the database. To start this supervisor, you must add it to the project’s supervision tree.

Open the `application.ex` file in the `lib/myproject` folder.

    nano lib/myproject/application.ex

Find the following block of code which defines the supervision tree:

~/myproject/lib/myproject/application.ex

    ...
        children = [
          # Start the endpoint when the application starts
          supervisor(MyprojectWeb.Endpoint, []),
          ...
        ]
    ...

You can see that the application endpoint, `MyprojectWeb.Endpoint`, is being started as a supervisor. Add `Myproject.Repo` to this list:

~/myproject/lib/myproject/myproject.ex

        children = [
          # Start the Ecto repository
          supervisor(Myproject.Repo, []),
          # Start the endpoint when the application starts
          supervisor(MyprojectWeb.Endpoint, []),
          ...
        ]

If you skip this step, Ecto will not create processes to interact with the database and any attempt to interact with the database will cause the application to crash.

Save and close `application.ex` before continuing.

Lastly, specify the Ecto repository in the application configuration so you can use Mix tasks like `ecto.create` and `ecto.migrate` to create and manage your database.

Open the configuration file at `config/config.exs`.

    nano config/config.exs

Locate the following line at the end of the file:

~/myproject/config/config.exs

    import_config "#{Mix.env}.exs"

This line allows environment-specific configuration files, such as `prod.exs` and `test.exs`, to override the settings in `config.exs` if necessary. Add the following code **above** that line to configure the Ecto repository:

~/myproject/config/config.exs

    ...
    
    config :myproject,
      ecto_repos: [Myproject.Repo]
    ...

Save your changes and close the file.

Now that you have Ecto configured, move on to adding your database credentials to the application.

## Step 3 — Configuring Your Application with MySQL Credentials

There are three situations in which your application would connect to a database: during development, during testing and during production.

Correspondingly, Phoenix provides three environment-specific configuration files that contain credentials relevant to the environment the application is running in. These files are located in the `config` directory in the root of the project. You’ll modify these three files in this step.

First, let’s configure the development environment. Open `dev.exs`.

    nano config/dev.exs

Add the following lines to configure the database adapter to be `Ecto.Adapters.MySQL` since we’re using MySQL.

~/myproject/config/dev.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL

Next, specify the desired name of the database in the same code block.

~/myproject/config/dev.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL,
      database: "myproject_dev"

Here, we define the development database name to be `myproject_dev`. This is a naming convention Phoenix apps use for databases. Following this convention, the production database would be called `myproject_prod` and the test database `myproject_test`. You can use your own naming scheme instead.

Now, provide the hostname, username, and password for your development database server.

~/myproject/config/dev.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL,
      database: "myproject_dev",
      username: "root",
      password: "password",
      hostname: "localhost"

Lastly, set the pool size to an appropriate number. The pool size is the maximum number of connections to the database that the application can have. These connections will be shared across requests. The optimum size depends on your hardware but you can use `10` to start.

~/myproject/config/dev.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL,
      username: "root",
      password: "password",
      database: "myproject_dev",
      hostname: "localhost",
      pool_size: 10

Save and close `dev.exs`.

Next, configure your test environment. Open the test environment configuration file `test.exs`.

    nano config/test.exs

In this tutorial, we’ll host the test database on the local database server alongside the development database. As such, the configurations for the test database are almost the same.

Instead of pool size, however, we specify `Ecto.Adapters.SQL.Sandbox` for the pool value. This will run tests in a sandbox mode. That is, any transactions made with the test database during a test will be rolled back. And this means unit tests can be run in a random order as the database is reset to the initial state after each test.

And we’ll use `myproject_test` as the database name.

Add the following configuration to the `test.exs` file:

~/myproject/config/test.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL,
      username: "root",
      password: "password",
      database: "myproject_test",
      hostname: "localhost",
      pool: Ecto.Adapters.SQL.Sandbox

Save and close `test.exs`.

Finally, to configure the credentials for your application in production, open your production secret file, `prod.secret.exs`.

    nano config/prod.secret.exs

Add this code into the `prod.secret.exs` file. Note that we’re using the username **myproject** here with the password `password`. . We’ll create this user on the production database server shortly, using the password specified here. You’ll want to use a more secure password here.

~/myproject/config/prod.secret.exs

    config :myproject, Myproject.Repo,
      adapter: Ecto.Adapters.MySQL,
      username: "myapp",
      password: "password",
      database: "myproject_prod",
      hostname: "localhost",
      pool_size: 10

Save your changes and close the file.

This file is not tracked by Git for security reasons, so you must manually transfer it to the server. For more information on this process, consult step 3 of the prerequisite [tutorial on deploying Phoenix applications](how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04).

    scp ~/myproject/config/prod.secret.exs sammy@your_server_ip:/home/sammy/app_config/prod.secret.exs

Then invoke the `ecto.create` Mix task to create the development database. Note that you don’t have to create the test database as Phoenix will do that for you when you run your tests.

    mix ecto.create

You’ll see the following output showing that Ecto has successfully created the database:

    Output...
    The database for Myproject.Repo has been created

If you don’t see this output, ensure that your configuration details are correct and that MySQL is running. Ecto would also refuse to create the database if your application fails to compile due to any errors.

Now that you’ve set up the project to connect to a database, and even used Ecto to create a database in the development machine, you can proceed to modify the database on the server.

## Step 4 — Setting up the Production Database

With the `ecto.create` Mix task, you created an empty database on your development machine. Now, you’ll do the same for your production server. Unfortunately, there aren’t any Mix tasks or edeliver commands to help us achieve this, so you’ll manually log in to the server and create an empty database with SQL commands using the MySQL console.

Connect to the server via SSH.

    ssh sammy@your_server_ip

Now access the MySQL console using the **root** user and the password you configured.

    mysql -u root -p

Once logged in, create the production database:

    CREATE DATABASE myproject_prod;

You’ll see the following output, letting you know the database was created:

    OutputQuery OK, 1 row affected (0.00 sec)

Next, create a user for the app, using the username **myproject** and the password you specified in the previous step:

    CREATE USER 'myproject'@'localhost' IDENTIFIED BY 'password';

Then give the **myproject** user access to the database you created:

    GRANT ALL PRIVILEGES ON myproject_prod.* to 'myproject'@'localhost';

Finally, apply the permission changes:

    FLUSH PRIVILEGES;

Exit the MySQL console by typing `exit`. Terminate the SSH connection by typing `exit` again.

From now on, you’ll rarely have to touch the production database, as you’ll perform almost all operations like creating and altering tables from your local machine.

With the production database now ready, you can redeploy your application to the server.

## Step 5 — Deploying the Project to the Server

In this step, you’re going to replace the running application that has no connection to a database with your freshly configured application and its new Ecto repository. This step will allow you to ensure that the application is configured correctly and that it still runs as expected.

Open `mix.exs` and increment the application version. The version number makes it easier to track releases and roll back to previous versions if necessary. It is also used by edeliver to upgrade your application without downtime.

    nano mix.exs

Increment the version field to an appropriate value.

~/myproject/mix.exs

      def project do
        [
          app: :myproject,
          version: "0.0.3",
          elixir: "~> 1.4",
          elixirc_paths: elixirc_paths(Mix.env),
          compilers: [:phoenix, :gettext] ++ Mix.compilers,
          start_permanent: Mix.env == :prod,
          deps: deps()
        ]
      end

In order to use edeliver to perform database migrations, edeliver must be the last application to start within your project. Find the following block of code:

~/myproject/mix.exs

      def application do
        [
          mod: {Myproject.Application, []},
          extra_applications: [:logger, :runtime_tools]
        ]
      end

Add `edeliver` to the end of the `extra_applications` list:

~/myproject/mix.exs

      def application do
        [
          mod: {Myproject.Application, []},
          extra_applications: [:logger, :runtime_tools, :edeliver]
        ]
      end

Save and close `mix.exs`.

Launch the application to ensure everything works and there are no compilation errors:

    mix phx.server

Visit [http://localhost:4000/addresses](http://localhost:4000) to ensure the app still works. If it doesn’t start, or you see compilation errors, review the steps in this tutorial and resolve them before moving on.

If everything is working as expected, press `CTRL+C` twice in your terminal to stop the server.

Then, commit changes with Git. You have to do this every time you make changes to your project because edeliver uses Git to push the code from the latest commit to the build server for further action.

    git add .
    git commit -m "Configured application with database"

Finally, use edeliver to update the application on the production server. The following command will build and deploy the latest version of your project before upgrading the application running on the production machine without downtime.

    mix edeliver upgrade production

You’ll see the following output:

    OutputEDELIVER MYPROJECT WITH UPGRADE COMMAND
    
    -----> Upgrading to revision 2512398 from branch master
    -----> Detecting release versions on production hosts
    -----> Deploying upgrades to 1 online hosts
    -----> Checking whether installed version 0.0.2 is in release store
    -----> Building the upgrade from version 0.0.2
    -----> Authorizing hosts
    -----> Validating * version 0.0.2 is in local release store
    -----> Ensuring hosts are ready to accept git pushes
    -----> Pushing new commits with git to: sammy@example.com
    -----> Resetting remote hosts to 2512398838c2dcc43de3ccd869779dded4fd5b6b
    -----> Cleaning generated files from last build
    -----> Checking out 2512398838c2dcc43de3ccd869779dded4fd5b6b
    -----> Fetching / Updating dependencies
    -----> Compiling sources
    -----> Checking version of new release
    -----> Uploading archive of release 0.0.2 from local release store
    -----> Extracting archive myproject_0.0.2.tar.gz
    -----> Removing old releases which were included in upgrade package
    -----> Generating release
    -----> Removing built release 0.0.2 from remote release directory
    -----> Copying release 0.0.3 to local release store
    -----> Copying myproject.tar.gz to release store
    -----> Upgrading production hosts to version 0.0.3
    -----> Authorizing hosts
    -----> Uploading archive of release 0.0.3 from local release store
    -----> Upgrading release to 0.0.3
    
    UPGRADE DONE!

Although the upgrade has completed successfully, you won’t be able to run the database-related edeliver tasks until you restart the application.

**Warning:** The following command will cause your application to go offline for a short while.

    mix edeliver restart production

You’ll see this output:

    OutputEDELIVER MYPROJECT WITH RESTART COMMAND
    
    -----> restarting production servers
    
    production node:
    
      user : sammy
      host : example.com
      path : /home/sammy/app_release
      response: ok
    
    RESTART DONE!

edeliver tells us that it has successfully restarted the production server.

To ensure that your application has been upgraded, run the following edeliver command to retrieve the version of the application that is currently running on production.

    mix edeliver version production

    OutputEDELIVER MYPROJECT WITH VERSION COMMAND
    
    -----> getting release versions from production servers
    
    production node:
    
      user : sammy
      host : example.com
      path : /home/sammy/app_release
      response: 0.0.3
    
    VERSION DONE!

The output tells us that the production server is running application version `0.0.3`.

You can also visit your application at `https://example.com` to ensure that it’s running. There shouldn’t be any observable changes to the application as we didn’t touch the application code itself.

If the upgrade succeeds but fails to update the application, ensure that you’ve committed your code and have bumped up your application version. If the upgrade command fails, edeliver will output the bash code it was executing on the server when the error occurred and the error message itself. You can use these clues to fix your problem.

Now that you’ve added database support to your app and deployed it to production, you’re now ready to add some features that make use of MySQL.

## Step 6 — Creating the Address Book

To demonstrate how to deploy database changes, let’s build a simple address book into our application and deploy it to production.

**Warning:** This address book will be publicly accessible, and **anyone** would be able to access and edit it. Either take down the feature after completing this tutorial, or add an authentication system like [Guardian](https://github.com/ueberauth/guardian) to limit access.

Instead of writing the code for the address book from scratch, we’ll use [Phoenix generators](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Html.html) to create the address book. Phoenix generators are utilities that generate code for a simple CRUD (Create, Read, Update, Delete) feature. This provides a good starting point for many application features that you may want to build.

The address book will also require a table in the database to store the entries. To add this table to the database, you can construct and execute a SQL query, but we’ll use Ecto’s migrations feature to modify the database instead. This approach has a few advantages. Firstly, it is database independent; the commands are the same whether you are using a PostgreSQL, MySQL or some other database. Next, migration files provide a convenient way to track how your database schema has changed with time. Finally, you can also roll back the latest migrations on your development machine if you need to.

Thankfully, you don’t have to write a migration file from scratch as Phoenix generators will make one for you unless otherwise specified.

To use the generator, specify the context, singular name of the entity, plural name of the entity and all the other fields with their respective types.

The **context** is a module that will contain functions for related resources. For instance, if you are planning to maintain a list of users who signed up on your site and a log of sessions when the users sign in, it makes sense to put users and sessions under a single context module named “Account”.

Note that by convention, Phoenix assumes the plural name of the entity to be the name of the database table for that resource.

Let’s create the address book with the generator. To keep the address book simple, we’ll include just three fields for each record — name, email and ZIP code. We’ll refer to each entry as an `Address`, multiple entries as `addresses` and the context in which the address book should reside as `AddressBook`.

Run this command to generate the address book:

    mix phx.gen.html AddressBook Address addresses name:string email:string zip_code:integer

    Output* creating lib/myproject_web/controllers/address_controller.ex
    ...
    * creating priv/repo/migrations/20180318032834_create_address.exs
    
    Add the resource to your browser scope in web/router.ex:
    
        resources "/addresses", AddressController
    
    Remember to update your repository by running migrations:
    
        $ mix ecto.migrate

Phoenix tells us that it automatically generated the template files, test files, the model, the controller, and the migration file. It also instructs us to add the resource to the router file and update the repository.

You could follow the instructions you see in the output, but by doing so, you will bundle application code upgrade and database migration in a single release. This can cause certain parts of the application to fail in production from the time the application is deployed to the production server to the time the production database is migrated. During this interval, the application code may be referencing non-existent tables or columns in the database.

To prevent downtime and errors, deploy the changes in two steps:

1. Add a database migration file with the necessary changes to the database without making changes to the application code. Create a release, upgrade the production server and migrate the production database.
2. Make changes to the application code, then create and deploy another release.

If we don’t take this approach, the code for the address book will try to reference the addresses table that we have yet to create and our application will crash.

Before we migrate the production database, let’s look at the migration file. It’s located at `priv/repo/migrations/20180501040548_create_addresses.exs`, although the filename will have a different datestamp based on when you created it. Open the file in your editor:

    nano priv/repo/migrations/*_create_addresses.exs

The migration file generated by Phoenix is an Elixir module with a single function called `change`. When you carry out the migration later, this function will be called.

~/myproject/priv/repo/migrations/20180501040548\_create\_addresses.exs

    defmodule Myproject.Repo.Migrations.CreateAddresses do
      use Ecto.Migration
    
      def change do
        create table(:addresses) do
          add :name, :string
          add :email, :string
          add :zip_code, :integer
    
          timestamps()
        end
    
      end
    end

In this function, the Phoenix generator has written the code to create the `addresses` table along with the fields you supplied. Additionally, the generator has also included the `timestamps()` function which adds two more fields for you: `inserted_at` and `updated_at`. The values stored in these fields are updated automatically when you insert or update data.

Close the file without making any changes; the generated code is all you need.

To deploy just the migration file without including the application code, we’ll make use of the fact that edeliver uses Git to transfer our project to the build server. Specifically, we’ll just stage and commit the migration file while leaving the rest of the generated files untracked.

But before you can do that, increment the application version in `mix.exs`. Edeliver uses the version number to prepare for hot-upgrades, so you need to increment the version number for every update.

Open up `mix.exs`.

    nano mix.exs

Increment your application version to an appropriate value.

~/myproject/mix.exs

      def project do
        [
          app: :myproject,
          version: "0.0.4",
          ...

Save and close the file.

Now, use Git to stage both the `mix.exs` file and the migration file.

    git add mix.exs priv/repo/migrations/*_create_addresses.exs

Next, commit the staged files.

    git commit -m "Adding addresses table to the database"

With that, upgrade your production application with edeliver.

    mix edeliver upgrade production

Once the upgrade completes, execute the following edeliver command to migrate the production database.

    mix edeliver migrate production

The output shows that the migration was successfully run, and shows the timestamp of the migration file:

    OutputEDELIVER MYPROJECT WITH MIGRATE COMMAND
    
    -----> migrateing production servers
    
    production node:
    
      user : sammy
      host : example.com
      path : /home/sammy/app_release
      response: [20180501040548]
    
    MIGRATE DONE!

The production database now has an empty table named `addresses`.

The `response` field would show `[]` if no migrations were run. If this is the case, ensure that you’ve committed your code using Git before upgrading again. Should the problem persist, restart the production application by typing `mix edeliver restart production`, and run the database migration task again.

With the `addresses` table in place, we can proceed to follow the instructions issued by Phoenix when we generated the address book and create a new release.

First, open the file `lib/myproject_web/router.ex` file:

    nano lib/myproject_web/router.ex

Find the following block of code:

~/myproject/lib/myproject\_web/router.ex

      scope "/", MyprojectWeb do
        pipe_through :browser 
    
        get "/", PageController, :index
      end

Insert the route for the `addresses` resource:

~/myproject/lib/myproject\_web/router.ex

      scope "/", MyprojectWeb do
        pipe_through :browser 
    
        get "/", PageController, :index
        resources "/addresses", AddressController
      end

Save and close `router.ex`.

Next, ask Ecto to make changes to the local database.

    mix ecto.migrate

The output shows that the function in the migration file was invoked, which successfully created the table `addresses`.

    Output...
    [info] == Running Myproject.Repo.Migrations.CreateAddresses.change/0 forward
    [info] create table addresses
    [info] == Migrated in 0.0s

Now start up the local development server to test out your new feature:

    mix phx.server

Point your browser at [http://localhost:4000/addresses](http://localhost:4000/addresses) to see the new feature in action.

When you’re satisfied that things are working locally, return to your terminal and press `CTRL+C` twice to terminate the server.

Now that things are working, you can deploy the changes to production. Open `mix.exs` to update the application version.

    nano mix.exs

Increment the version field to an appropriate value.

~/myproject/mix.exs

      def project do
        [
          app: :myproject,
          version: "0.0.5",
          elixir: "~> 1.4",
          elixirc_paths: elixirc_paths(Mix.env),
          compilers: [:phoenix, :gettext] ++ Mix.compilers,
          start_permanent: Mix.env == :prod,
          deps: deps()
        ]
      end

Save and close `mix.exs`.

Commit your changes with Git. This time, stage all of the files.

    git add .
    git commit -m "Added application code for address book"

Upgrade the production application with edeliver.

    mix edeliver upgrade production

When the update has completed, you can access the new feature at `https://example.com/addresses`.

With that, you’ve successfully upgraded the production application and database.

## Conclusion

In this article, you configured your Phoenix application to use a MySQL database and used edeliver and Ecto migrations to make changes to the production database. With this method, you don’t have to touch the production database and any changes you want to make to the production database are done through Ecto migration files. This makes it easier to roll back changes and track changes to the database over time.

To learn more about Ecto migrations and how to perform complex database manipulations, refer to the [official Ecto migrations document](https://hexdocs.pm/ecto/Ecto.Migration.html).
