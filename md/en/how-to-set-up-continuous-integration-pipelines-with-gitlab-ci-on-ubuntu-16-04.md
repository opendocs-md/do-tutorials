---
author: Justin Ellingwood
date: 2017-06-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04
---

# How To Set Up Continuous Integration Pipelines with GitLab CI on Ubuntu 16.04

## Introduction

GitLab Community Edition is a self-hosted Git repository provider with additional features to help with project management and software development. One of the most valuable features that GitLab offers is the builtin continuous integration and delivery tool called [GitLab CI](https://about.gitlab.com/features/gitlab-ci-cd/).

In this guide, we will demonstrate how to set up GitLab CI to monitor your repositories for changes and run automated tests to validate new code. We will start with a running GitLab installation where we will copy an example repository for a basic Node.js application. After configuring our CI process, when a new commit is pushed to the repository GitLab will use CI runner to execute the test suite against the code in an isolated Docker container.

## Prerequisites

Before we begin, you’ll need to set up an initial environment. We need a secure GitLab server configured to store our code and manage our CI/CD processes. Additionally, we need a place to run the automated tests. This can either be the same server that GitLab is installed on or a separate host. The below sections cover the requirements in more detail.

### A GitLab Server Secured with SSL

To store the source code and configure our CI/CD tasks, we need a GitLab instance installed on an Ubuntu 16.04 server. GitLab currently recommends a server with at least **2 CPU cores** and **4GB of RAM**. To protect your code from being exposed or tampered with, the GitLab instance will be protected with SSL using Let’s Encrypt. Your server needs to have a domain name or a subdomain associated with it in order to complete this step.

You can complete these requirements using the following tutorials:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04): Create a `sudo` user and configure a basic firewall
- [How To Install and Configure GitLab on Ubuntu 16.04](how-to-install-and-configure-gitlab-on-ubuntu-16-04): Install GitLab on the server and protect it with a Let’s Encrypt TLS/SSL certificate

We will be demonstrating how to share CI/CD runners (the components that run the automated tests) between projects and how to lock them to single projects. If you wish to share CI runners between projects, we strongly recommend that you restrict or disable public sign-ups. If you didn’t modify your settings during installation, go back and follow [the optional step from the GitLab installation article on restricting or disabling sign-ups](how-to-install-and-configure-gitlab-on-ubuntu-16-04#restrict-or-disable-public-sign-ups-(optional)) to prevent abuse by outside parties.

### One Or More Servers to Use as GitLab CI Runners

GitLab CI Runners are the servers that check out the code and run automated tests to validate new changes. To isolate the testing environment, we will be running all of our automated tests within Docker containers. To do this, we need to install Docker on the server or servers that will be running the tests.

This step can be completed on the GitLab server or on a different Ubuntu 16.04 server to provide additional isolation and avoid resource contention. The following tutorials will install Docker on the host you wish to use to run your tests:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04): Create a `sudo` user and configure a basic firewall (you do not have to complete this again if you are setting up the CI runner on the GitLab server)
- [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04): Follow **steps 1 and 2** to install Docker on the server

When you are ready to begin, continue with this guide.

## Copying the Example Repository From GitHub

To begin, we will create a new project in GitLab containing the example Node.js application. We will [import the original repository directly from GitHub](https://github.com/do-community/hello_hapi/) so that we do not have to upload it manually.

Log into GitLab and click the **plus icon** in the upper-right corner and select **New project** to add a new project:

![GitLab add new project icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_project_icon_3.png)

On the new project page, click on the **Import project** tab:

![GitLab new project name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/import-project.png)

Next, click on the **Repo by URL** button. Although there is a GitHub import option, it requires a Personal access token and is used to import the repository and additional information. We are only interested in the code and the Git history, so importing by URL is easier.

In the **Git repository URL** field, enter the following GitHub repository URL:

    https://github.com/do-community/hello_hapi.git

It should look like this:

![GitLab new project GitHub URL](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_project_github_url2.png)

Since this is a demonstration, it’s probably best to keep the repository marked **Private**. When you are finished, click **Create project**.

The new project will be created based on the repository imported from GitHub.

## Understanding the .gitlab-ci.yml File

GitLab CI looks for a file called `.gitlab-ci.yml` within each repository to determine how it should test the code. The repository we imported has a `gitlab-ci.yml` file already configured for the project. You can learn more about the format by reading the [.gitlab-ci.yml reference documentation](https://docs.gitlab.com/ce/ci/yaml/README.html)

Click on the `.gitlab-ci.yml` file in the GitLab interface for the project we just created. The CI configuration should look like this:

.gitlab-ci.yml

    image: node:latest
    
    stages:
      - build
      - test
    
    cache:
      paths:
        - node_modules/
    
    install_dependencies:
      stage: build
      script:
        - npm install
      artifacts:
        paths:
          - node_modules/
    
    test_with_lab:
      stage: test
      script: npm test

The file uses the [GitLab CI YAML configuration syntax](https://docs.gitlab.com/ee/ci/yaml/) to define the actions that should be taken, the order they should execute, under what conditions they should be run, and the resources necessary to complete each task. When writing your own GitLab CI files, you can visit a syntax linter by going to `/ci/lint` in your GitLab instance to validate that your file is formatted correctly.

The configuration file starts off by declaring a Docker `image` that should be used to run the test suite. Since Hapi is a Node.js framework, we are using the latest Node.js image:

    image: node:latest

Next, we explicitly define different continuous integration stages that will run:

    stages:
      - build
      - test

The names you choose here are arbitrary, but the ordering determines the order of execution for the steps that will follow. Stages are tags that you can apply to individual jobs. GitLab will run jobs of the same stage in parallel and will wait to execute the next stage until all jobs at the current stage are complete. If no stages are defined, GitLab will use three stages called `build`, `test`, and `deploy` and assign all jobs to the `test` stage by default.

After defining the stages, the configuration includes a `cache` definition:

    cache:
      paths:
        - node_modules/

This specifies files or directories that can be cached (saved for later use) between runs or stages. This can help decrease the amount of time that it takes to run jobs that rely on resources that might not change between runs. Here, we are caching the `node_modules` directory, which is where `npm` will install the dependencies it downloads.

Our first job is called `install_dependencies`:

    install_dependencies:
      stage: build
      script:
        - npm install
      artifacts:
        paths:
          - node_modules/

Jobs can be named anything, but because the names will be used in the GitLab UI, descriptive names are helpful. Usually, `npm install` can be combined with the next testing stages, but to better demonstrate the interaction between stages, we are extracting this step to run in its own stage.

We mark the stage explicitly as “build” with the `stage` directive. Next, we specify the actual commands to run using the `script` directive. You can include multiple commands by adding additional lines within the `script` section.

The `artifacts` subsection is used to specify file or directory paths to save and pass between stages. Because the `npm install` command installs the dependencies for the project, our next step will need access to the downloaded files. Declaring the `node_modules` path ensures that the next stage will have access to the files. These will also be available to view or download in the GitLab UI after the test, so this is useful for build artifacts like binaries as well. If you want to save everything produced during the stage, replace the entire `paths` section with `untracked: true`.

Finally, the second job called `test_with_lab` declares the command that will actually run the test suite:

    test_with_lab:
      stage: test
      script: npm test

We place this in the `test` stage. Since this is a later stage, it has access to the artifacts produced by the `build` stage, which are the project dependencies in our case. Here, the `script` section demonstrates the single-line YAML syntax that can be used when there’s only a single item. We could have used this same syntax in the previous job as well since only one command was specified.

Now that you have a basic idea of how the `.gitlab-ci.yml` file defines CI/CD tasks, we can define one or more runners capable of executing the testing plan.

## Triggering a Continuous Integration Run

Since our repository includes a `.gitlab-ci.yml` file, any new commits will trigger a new CI run. If no runners are available, the CI run will be set to “pending”. Before we define a runner, let’s trigger a CI run to see what a job looks like in the pending state. Once a runner is available, it will immediately pick up the pending run.

Back in the `hello_hapi` GitLab project repository view, click on the **plus sign** next to the branch and project name and select **New file** from the menu:

![GitLab new file button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_file_button2.png)

On the next page, enter `dummy_file` in the **File name** field and enter some text in the main editing window:

![GitLab dummy file](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/dummy_file2.png)

Click **Commit changes** at the bottom when you are finished.

Now, return to the main project page. A small **paused** icon will be attached to the most recent commit. If you mouse over the icon, it will display “Commit:pending”:

![GitLab pending marker](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pending_marker_2.png)

This means that the tests that validate code changes have not been run yet.

To get more information, go to the top of the page and click **Pipelines**. You will be taken to the pipeline overview page, where you can see that the CI run is marked as pending and labeled as “stuck”:

![GitLab pipeline index stuck](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_index_stuck.png)

**Note:** Along the right-hand side is a button for the **CI Lint** tool. This is where you can check the syntax of any `gitlab-ci.yml` files you write.

From here, you can click the **pending** status to get more details about the run. This view displays the different stages of our run, as well as the individual jobs associated with each stage:

![GitLab pipeline detail view](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_detail_view.png)

Finally, click on the **install\_dependencies** job. This will give you the specific details about what is delaying the run:

![GitLab job detail view](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/job_detail_view.png)

Here, the message indicates that the job is stuck because of a lack of runners. This is expected since we haven’t configured any yet. Once a runner is available, this same interface can be used to see the output. This is also the location where you can download artifacts produced during the build.

Now that we know what a pending job looks like, we can assign a CI runner to our project to pick up the pending job.

## Installing the GitLab CI Runner Service

We’re now ready to set up a GitLab CI runner. To do this, we need to install the GitLab CI runner package on the system and start the GitLab runner service. The service can run multiple runner instances for different projects.

As mentioned in the prerequisites, you can complete these steps on the same server that hosts your GitLab instance or a different server if you want to be sure to avoid resource contention. Remember that whichever host you choose, you need Docker installed for the configuration we will be using.

The process of installing the GitLab CI runner service is similar to the process used to install GitLab itself. We will download a script to add a GitLab repository to our `apt` source list. After running the script, we will download the runner package. We can then configure it to serve our GitLab instance.

Start by downloading the latest version of the GitLab CI runner repository configuration script to the `/tmp` directory (this is a different repository than the one used by the GitLab server):

    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh -o /tmp/gl-runner.deb.sh

Feel free to examine the downloaded script to ensure that you are comfortable with the actions that it will take. You can also find a hosted version of the script [here](https://packages.gitlab.com/runner/gitlab-ci-multi-runner/install):

    less /tmp/gl-runner.deb.sh

Once you are satisfied with the safety of the script, run the installer:

    sudo bash /tmp/gl-runner.deb.sh

The script will set up your server to use the GitLab maintained repositories. This lets you manage GitLab runner packages with the same package management tools you use for your other system packages. Once this is complete, you can proceed with the installation using `apt-get`:

    sudo apt-get install gitlab-runner

This will install the GitLab CI runner package on the system and start the GitLab runner service.

## Setting Up a GitLab Runner

Next, we need to set up a GitLab CI runner so that it can begin accepting work.

To do this, we need a GitLab runner token so that the runner can authenticate with the GitLab server. The type of token we need depends on how we want to use this runner.

A **project specific runner** is useful if you have specific requirements for the runner. For instance, if your `gitlab-ci.yml` file defines deployment tasks that require credentials, a specific runner may be required to authenticate correctly into the deployment environment. If your project has resource intensive steps in the CI process, this might also be a good idea. A project specific runner will not accept jobs from other projects.

On the other hand, a **shared runner** is a general purpose runner that can be used by multiple projects. Runners will take jobs from the projects according to an algorithm that accounts for the number of jobs currently being run for each project. This type of runner is more flexible. You will need to log into GitLab with an admin account to set up shared runners.

We will demonstrate how to get the runner tokens for both of these runner types below. Choose the method that suits you best.

### Collecting Information to Register a Project-Specific Runner

If you would like the runner to be tied to a specific project, begin by navigating to the project’s page in the GitLab interface.

From here, click the **Settings** item in the left-hand menu. Afterwards, click the **CI/CD** item in the submenu:

![GitLab project settings item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/project_settings_item2.png)

On this page, you will see a **Runners settings** section. Click the **Expand** button to see more details. In the detail view, the left-hand side will explain how to register a project-specific runner. Copy the registration token displayed in step 4 of the instructions:

![GitLab specific runner config settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/specific_runner_config_settings2.png)

If you wish to disable any active shared runners for this project, you can do so by clicking the **Disable shared Runners** button on the right-hand side. This is optional.

When you are ready, skip ahead to learn how to register your runner using the pieces of information you collected from this page.

### Collecting Information to Register a Shared Runner

To find the information required to register a shared runner, you will need to be logged in with an administrative account.

Begin by clicking the **wrench icon** in the top navigation bar to access the admin area. In the **Overview** section of the left-hand menu, click **Runners** to access the shared runner configuration page:

![GitLab admin area icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/admin_area_icon2.png)

Copy the registration token displayed towards the top of the page:

![GitLab shared runner token](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/shared_runner_token2.png)

We will use this token to register a GitLab CI runner for the project.

### Registering a GitLab CI Runner with the GitLab Server

Now that you have a token, go back to the server where your GitLab CI runner service is installed.

To register a new runner, type the following command:

    sudo gitlab-runner register

You will be asked a series of questions to configure the runner:

**Please enter the gitlab-ci coordinator URL (e.g. [https://gitlab.com/](https://gitlab.com/))**

Enter your GitLab server’s domain name, using `https://` to specify SSL. You can optionally append `/ci` to the end of your domain, but recent versions will redirect automatically.

**Please enter the gitlab-ci token for this runner**

The token you copied in the last section.

**Please enter the gitlab-ci description for this runner**

A name for this particular runner. This will show up in the runner service’s list of runners on the command line and in the GitLab interface.

**Please enter the gitlab-ci tags for this runner (comma separated)**

These are tags that you can assign to the runner. GitLab jobs can express requirements in terms of these tags to make sure they are run on a host with the correct dependencies.

You can leave this blank in this case.

**Whether to lock Runner to current project [true/false]**

Assigns the runner to the specific project. It cannot be used by other projects.

Select “false” here.

**Please enter the executor**

The method used by the runner to complete jobs.

Choose “docker” here.

**Please enter the default Docker image (e.g. ruby:2.1)**

The default image used to run jobs when the `.gitlab-ci.yml` file does not include an image specification. It’s best to specify a general image here and define more specific images in your `.gitlab-ci.yml` file as we have done.

We will enter “alpine:latest” here as a small, secure default.

After answering the prompts, a new runner will be created capable of running your project’s CI/CD tasks.

You can see the runners that the GitLab CI runner service currently has available by typing:

    sudo gitlab-runner list

    OutputListing configured runners ConfigFile=/etc/gitlab-runner/config.toml
    example-runner Executor=docker Token=e746250e282d197baa83c67eda2c0b URL=https://example.com

Now that we have a runner available, we can return to the project in GitLab.

## Viewing the CI/CD Run in GitLab

Back in your web browser, return to your project in GitLab. Depending on how long it has been since registering your runner, the runner may be currently running:

![GitLab CI running icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/ci_running_icon_2.png)

Or it might have completed already:

![GitLab CI run passed icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/ci_run_passed_icon_2.png)

Regardless of the state, click on the **running** or **passed** icon (or **failed** if you ran into a problem) to view the current state of the CI run. You can get a similar view by clicking the top **Pipelines** menu.

You will be taken to the pipeline overview page where you can see the status of the GitLab CI run:

![GitLab CI pipeline run overview](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_run_overview.png)

Under the **Stages** header, there will be a circle indicating the status of each of the stages in the run. If you click on the stage, you can see the individual jobs associated with the stage:

![GitLab CI pipeline run stage_view](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_run_stage_view.png)

Click on the **install\_dependencies** job within the **build** stage. This will take you to the job overview page:

![GitLab CI pipeline job overview](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_job_overview.png)

Now, instead of displaying a message about no runners being available, the output of the job is displayed. In our case, this means that you can see the results of `npm` installing each of the packages.

Along the right-hand side, you can see some other items as well. You can view other jobs by changing the **Stage** and clicking the runs below. You can also view or download any artifacts produced by the run.

## Conclusion

In this guide, we’ve added a demonstration project to a GitLab instance to showcase the continuous integration and deployment capabilities of GitLab CI. We discussed how to define a pipeline in `gitlab-ci.yml` files to build and test your applications and how to assign jobs to stages to define their relationship to one another. We then set up a GitLab CI runner to pick up CI jobs for our project and demonstrated how to find information about individual GitLab CI runs.
