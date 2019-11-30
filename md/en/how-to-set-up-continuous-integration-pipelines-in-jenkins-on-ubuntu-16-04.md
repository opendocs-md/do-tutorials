---
author: Justin Ellingwood
date: 2017-06-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-continuous-integration-pipelines-in-jenkins-on-ubuntu-16-04
---

# How To Set Up Continuous Integration Pipelines in Jenkins on Ubuntu 16.04

## Introduction

Jenkins is an open source automation server intended to automate repetitive technical tasks involved in the continuous integration and delivery of software. With a robust ecosystem of plugins and broad support, Jenkins can handle a diverse set of workloads to build, test, and deploy applications.

In previous guides, we [installed Jenkins on an Ubuntu 16.04 server](how-to-install-jenkins-on-ubuntu-16-04) and [configured Jenkins with SSL using an Nginx reverse proxy](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy). In this guide, we will demonstrate how to set up Jenkins to automatically test an application when changes are pushed to a repository.

For this tutorial, we will be integrating Jenkins with GitHub to so that Jenkins is notified when new code is pushed to the repository. When Jenkins is notified, it will checkout the code and then test it within Docker containers to isolate the test environment from the Jenkins host machine. We will be using an example Node.js application to show how to define the CI/CD process for a project.

## Prerequisites

To follow along with this guide, you will need an Ubuntu 16.04 server with at least 1G of RAM configured with a secure Jenkins installation. To properly secure the web interface, you will need to assign a domain name to the Jenkins server. Follow these guides to learn how to set up Jenkins in the expected format:

- [How To Install Jenkins on Ubuntu 16.04](how-to-install-jenkins-on-ubuntu-16-04)
- [How to Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04)
- [How to Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04)
- [How to Configure Jenkins with SSL using an Nginx Reverse Proxy](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy)

To best control our testing environment, we will run our application’s tests within Docker containers. After Jenkins is up and running, install Docker on the server by following steps one and two of this guide:

- [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04)

When you have completed the above guides, you can continue on with this article.

## Add the Jenkins User to the Docker Group

After following the prerequisites, both Jenkins and Docker are installed on your server. However, by default, the Linux user responsible for running the Jenkins process cannot access Docker.

To fix this, we need to add the `jenkins` user to the `docker` group using the `usermod` command:

    sudo usermod -aG docker jenkins

You can list the members of the `docker` group to confirm that the `jenkins` user has been added successfully:

    grep docker /etc/group

    Outputdocker:x:999:sammy,jenkins

In order for the Jenkins to use its new membership, you need to restart the process:

    sudo systemctl restart jenkins

With the help of some of the default plugins we enabled during installation, Jenkins can now use Docker to run build and test tasks.

## Create a Personal Access Token in GitHub

In order for Jenkins to watch your GitHub projects, you will need to create a Personal Access Token in our GitHub account.

Begin by visiting [GitHub](https://github.com/) and signing into your account if you haven’t already done so. Afterwards, click on your user icon in the upper-right hand corner and select **Settings** from the drop down menu:

![GitHub settings item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/github_settings_item.png)

On the page that follows, locate the **Developer settings** section of the left-hand menu and click **Personal access tokens** :

![GitHub personal access tokens link](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/developer_settings.png)

Click on **Generate new token** button on the next page:

![GitHub generate new token button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/new_token_button.png)

You will be taken to a page where you can define the scope for your new token.

In the **Token description** box, add a description that will allow you to recognize it later:

![GitHub token description](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/token_description.png)

In the **Select scopes** section, check the **repo:status** , **repo:public\_repo** and **admin:org\_hook** boxes. These will allow Jenkins to update commit statuses and to create webhooks for the project. If you are using a private repository, you will need to select the general **repo** permission instead of the repo subitems:

![GitHub token scope](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/token_scope3.png)

When you are finished, click **Generate token** at the bottom.

You will be redirected back to the Personal access tokens index page and your new token will displayed:

![GitHub view new token](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/view_token.png)

Copy the token now so that we can reference it later. As the message indicates, there is no way to retrieve the token once you leave this page.

**Note** : As mentioned in the screenshot above, for security reasons, there is no way to redisplay the token once you leave this page. If you lose your token, delete the current token from your GitHub account and then create a new one.

Now that you have have a personal access token for your GitHub account, we can configure Jenkins to watch your project’s repository.

## Add the GitHub Personal Access Token to Jenkins

Now that we have a token, we need to add it to our Jenkins server so it can automatically set up webhooks. Log into your Jenkins web interface using the administrative account you configured during installation.

From the main dashboard, click **Credentials** in the left hand menu:

![Jenkins credentials item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/credentials_item.png)

On the next page, click the arrow next to **(global)** within the **Jenkins** scope. In the box that appears, click **Add credentials** :

![Jenkins add credentials button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/add_credentials.png)

You will be taken to a form to add new credentials.

Under the **Kind** drop down menu, select **Secret text**. In the **Secret** field, paste your GitHub personal access token. Fill out the **Description** field so that you will be able to identify this entry at a later date. You can leave the Scope as Global and the ID field blank:

![Jenkins credentials form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/credentials_form.png)

Click the **OK** button when you are finished.

You will now be able to reference these credentials from other parts of Jenkins to aid in configuration.

## Set Up Jenkins Access to GitHub

Back in the main Jenkins dashboard, click **Manage Jenkins** in the left hand menu:

![Jenkins credentials item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/credentials_item.png)

In the list of links on the following page, click **Configure System** :

![Jenkins configure system link](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/configure_system_link.png)

Scroll through the options on the next page until you find the **GitHub** section. Click the **Add GitHub Server** button and then select **GitHub Server** :

![Jenkins add GitHub server](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/add_github_server.png)

The section will expand to prompt for some additional information. In the **Credentials** drop down menu, select your GitHub personal access token that you added in the last section:

![Jenkins select GitHub credentials](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/select_credentials.png)

Click the **Test connection** button. Jenkins will make a test API call to your account and verify connectivity:

![Jenkins test GitHub credentials](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/test_creds.png)

When you are finished, click the **Save** button to implement your changes.

## Set Up the Demonstration Application in your GitHub Account

To demonstrate how to use Jenkins to test an application, we will be using a simple [“hello world” program](https://github.com/do-community/hello_hapi) created with [Hapi.js](https://hapijs.com/). Because we are setting up Jenkins to react to pushes to the repository, you need to have your own copy of the demonstration code.

Visit the [project repository](https://github.com/do-community/hello_hapi) and click the **Fork** button in the upper-right corner to make a copy of the repository in your account:

![Fork example project](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/fork_example_project.png)

A copy of the repository will be added to your account.

The repository contains a `package.json` file that defines the runtime and development dependencies, as well as how to run the included test suite. The dependencies can be installed by running `npm install` and the tests can be run using `npm test`.

We’ve added a `Jenkinsfile` to the repo as well. Jenkins reads this file to determine the actions to run against the repository to build, test, or deploy. It is written using the declarative version of the Jenkins [Pipeline DSL](https://jenkins.io/doc/book/pipeline/syntax/).

The `Jenkinsfile` included in the `hello-hapi` repository looks like this:

Jenkinsfile

    #!/usr/bin/env groovy
    
    pipeline {
    
        agent {
            docker {
                image 'node'
                args '-u root'
            }
        }
    
        stages {
            stage('Build') {
                steps {
                    echo 'Building...'
                    sh 'npm install'
                }
            }
            stage('Test') {
                steps {
                    echo 'Testing...'
                    sh 'npm test'
                }
            }
        }
    }

The `pipeline` contains the entire definition that Jenkins will evaluate. Inside, we have an `agent` section that specifies where the actions in the pipeline will execute. To isolate our environments from the host system, we will be testing in Docker containers, specified by the `docker` agent.

Since Hapi.js is a framework for Node.js, we will be using the `node` Docker image as our base. We specify the `root` user within the container so that the user can simultaneously write to both the attached volume containing the checked out code, and to the volume the script writes its output to.

Next, the file defines two stages, which are just logical divisions of work. We’ve named the first one “Build” and the second “Test”. The build step prints a diagnostic message and then runs `npm install` to obtain the required dependencies. The test step prints another message and then run the tests as defined in the `package.json` file.

Now that you have a repository with a valid `Jenkinsfile`, we can set up Jenkins to watch this repository and run the file when changes are introduced.

## Create a New Pipeline in Jenkins

Next, we can set up Jenkins to use the GitHub personal access token to watch our repository.

Back in the main Jenkins dashboard, click **New Item** in the left hand menu:

![Jenkins side menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/credentials_item.png)

Enter a name for your new pipeline in the **Enter an item name** field. Afterwards, select **Pipeline** as the item type:

![Jenkins pipeline type](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/item_type.png)

Click the **OK** button at the bottom to move on.

On the next screen, check the **GitHub project** box. In the **Project url** field that appears, enter your project’s GitHub repository URL.

**Note** : Make sure to point to your fork of the Hello Hapi application so that Jenkins will have permission to configure webhooks.

![Jenkins add GitHub project](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/add_github_project.png)

Next, in the **Build Triggers** section, check the **GitHub hook trigger for GITScm polling** box:

![Jenkins GitHub hook box](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/github_hook_box.png)

In the **Pipeline** section, we need to tell Jenkins to run the pipeline defined in the `Jenkinsfile` in our repository. Change the **Definition** type to **Pipeline script from SCM**.

In the new section that appears, choose **Git** in the **SCM** menu. In the **Repository URL** field that appears, enter the URL to your fork of the repository again:

**Note** : Again, make sure to point to your fork of the Hello Hapi application.

![Jenkins GitHub add pipeline repository](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/add_pipeline_repo2.png)

**Note** : Our example references a `Jenkinsfile` available within a public repository. If your project is not publicly accessible, you will need to use the **add credentials** button to add additional access to the repository. You can add a personal access token as we did with the hooks configuration earlier.

When you are finished, click the **Save** button at the bottom of the page.

## Performing an Initial Build and Configuring the Webhooks

At the time of this writing (June, 2017), Jenkins does not automatically configure webhooks when you define the pipeline for the repository in the interface.

In order to trigger Jenkins to set up the appropriate hooks, we need to perform a manual build the first time.

In your pipeline’s main page, click **Build Now** in the left hand menu:

![Jenkins build pipeline now](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/build_pipeline_now.png)

A new build will be scheduled. In the **Build History** box in the lower left corner, a new build should appear in a moment. Additionally, a **Stage View** will begin to be drawn in the main area of the interface. This will track the progress of your testing run as the different stages are completed:

![Jenkins build progress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/build_progress.png)

In the **Build History** box, click on the number associated with the build to go to the build detail page. From here, you can click the **Console Output** button in the left hand menu to see details of the steps that were run:

![Jenkins console output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/console_output.png)

Click the **Back to Project** item in the left hand menu when you are finished in order to return to the main pipeline view.

Now that we’ve built the project once, we can have Jenkins create the webhooks for our project. Click **Configure** in the left hand menu of the pipeline:

![Jenkins configure item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/configure_menu_item.png)

No changes are necessary on this screen, just click the **Save** button at the bottom. Now that the Jenkins has information about the project from the initial build process, it will register a webhook with our GitHub project when you save the page.

You can verify this by going to your GitHub repository and clicking the **Settings** button. On the next page, click **Webhooks** from the side menu. You should see your Jenkins server webhook in the main interface:

![Jenkins view webhooks](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/view_webhooks.png)

Now, when you push new changes to your repository, Jenkins will be notified. It will then pull the new code and retest it using the same procedure.

To approximate this, in our repository page on GitHub, you can click the **Create new file** button to the left of the green **Clone or download** button:

![Jenkins create new file button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/create_new_file_button.png)

On the next page, choose a filename and some dummy contents:

![Jenkins new file contents](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/new_file_contents.png)

Click the **Commit new file** button at the bottom when you are finished.

If you return to your Jenkins interface, you will see a new build automatically started:

![Jenkins new build started](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins_usage_1604/new_build_started.png)

You can kick off additional builds by making commits to a local copy of the repository and pushing it back up to GitHub.

## Conclusion

In this guide, we configured Jenkins to watch a GitHub project and automatically test any new changes that are committed. Jenkins pulls code from the repository and then runs the build and testing procedures from within isolated Docker containers. The resulting code can be deployed or stored by adding additional instructions to the same `Jenkinsfile`.
