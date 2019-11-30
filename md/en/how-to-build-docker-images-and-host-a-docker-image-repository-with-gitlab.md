---
author: Brian Boucheron
date: 2018-02-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-docker-images-and-host-a-docker-image-repository-with-gitlab
---

# How To Build Docker Images and Host a Docker Image Repository with GitLab

## Introduction

Containerization is quickly becoming the most accepted method of packaging and deploying applications in cloud environments. The standardization it provides, along with its resource efficiency (when compared to full virtual machines) and flexibility, make it a great enabler of the modern _DevOps_ mindset. Many interesting _cloud native_ deployment, orchestration, and monitoring strategies become possible when your applications and microservices are fully containerized.

[Docker](https://www.docker.com/) containers are by far the most common container type today. Though public Docker image repositories like [Docker Hub](https://hub.docker.com/) are full of containerized open source software images that you can `docker pull` and use today, for private code you’ll need to either pay a service to build and store your images, or run your own software to do so.

[GitLab](https://about.gitlab.com/) Community Edition is a self-hosted software suite that provides Git repository hosting, project tracking, CI/CD services, and a Docker image registry, among other features. In this tutorial we will use GitLab’s continuous integration service to build Docker images from an example Node.js app. These images will then be tested and uploaded to our own private Docker registry.

## Prerequisites

Before we begin, we need to set up **a secure GitLab server** , and **a GitLab CI runner** to execute continuous integration tasks. The sections below will provide links and more details.

### A GitLab Server Secured with SSL

To store our source code, run CI/CD tasks, and host the Docker registry, we need a GitLab instance installed on an Ubuntu 16.04 server. GitLab currently recommends **a server with at least 2 CPU cores and 4GB of RAM**. Additionally, we’ll secure the server with SSL certificates from Let’s Encrypt. To do so, you’ll need a domain name pointed at the server.

You can complete these prerequisite requirements with the following tutorials:

- [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) will show you how to manage a domain with the DigitalOcean control panel
- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) will get a non-root, sudo-enabled user set up, and enable Ubuntu’s `ufw` firewall
- [How To Install and Configure GitLab on Ubuntu 16.04](how-to-install-and-configure-gitlab-on-ubuntu-16-04) will show you how to install GitLab and configure it with a free TLS/SSL certificate from Let’s Encrypt

### A GitLab CI Runner

[How To Set Up Continuous Integration Pipelines with GitLab CI on Ubuntu 16.04](how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04) will give you an overview of GitLab’s CI service, and show you how to set up a CI runner to process jobs. We will build on top of the demo app and runner infrastructure created in this tutorial.

## Step 1 — Setting Up a Privileged GitLab CI Runner

In the prerequisite GitLab continuous integration tutorial, we set up a GitLab runner using `sudo gitlab-runner register` and its interactive configuration process. This runner is capable of running builds and tests of software inside of isolated Docker containers.

However, in order to build Docker images, our runner needs full access to a Docker service itself. The recommended way to configure this is to use Docker’s official `docker-in-docker` image to run the jobs. This requires granting the runner a special `privileged` execution mode, so we’ll create a second runner with this mode enabled.

**Note:** Granting the runner **privileged** mode basically disables all of the security advantages of using containers. Unfortunately, the other methods of enabling Docker-capable runners also carry similar security implications. Please look at [the official GitLab documentation on Docker Build](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html) to learn more about the different runner options and which is best for your situation.

Because there are security implications to using a privileged runner, we are going to create a project-specific runner that will only accept Docker jobs on our `hello_hapi` project (GitLab admins can always manually add this runner to other projects at a later time). From your `hello_hapi` project page, click **Settings** at the bottom of the left-hand menu, then click **CI/CD** in the submenu:

![GitLab project settings menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/settings-ci.png)

Now click the **Expand** button next to the **Runners settings** section:

![GitLab "Runners settings" expand button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-expand.png)

There will be some information about setting up a **Specific Runner** , including a registration token. Take note of this token. When we use it to register a new runner, the runner will be locked to this project only.

![GitLab project-specific runners options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-token.png)

While we’re on this page, click the **Disable shared Runners** button. We want to make sure our Docker jobs always run on our privileged runner. If a non-privileged shared runner was available, GitLab might choose to use that one, which would result in build errors.

Log in to the server that has your current CI runner on it. If you don’t have a machine set up with runners already, go back and complete the [Installing the GitLab CI Runner Service  
](how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04#installing-the-gitlab-ci-runner-service) section of the prerequisite tutorial before proceeding.

Now, run the following command to set up the privileged project-specific runner:

    sudo gitlab-runner register -n \
      --url https://gitlab.example.com/ \
      --registration-token your-token \
      --executor docker \
      --description "docker-builder" \
      --docker-image "docker:latest" \
      --docker-privileged

    OutputRegistering runner... succeeded runner=61SR6BwV
    Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

Be sure to substitute your own information. We set all of our runner options on the command line instead of using the interactive prompts, because the prompts don’t allow us to specify `--docker-privileged` mode.

Your runner is now set up, registered, and running. To verify, switch back to your browser. Click the wrench icon in the main GitLab menu bar, then click **Runners** in the left-hand menu. Your runners will be listed:

![GitLab runner listing](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-list.png)

Now that we have a runner capable of building Docker images, let’s set up a private Docker registry for it to push images to.

## Step 2 — Setting Up GitLab’s Docker Registry

Setting up your own Docker registry lets you push and pull images from your own private server, increasing security and reducing the dependencies your workflow has on outside services.

GitLab will set up a private Docker registry with just a few configuration updates. First we’ll set up the URL where the registry will reside. Then we will (optionally) configure the registry to use an S3-compatible object storage service to store its data.

SSH into your GitLab server, then open up the GitLab configuration file:

    sudo nano /etc/gitlab/gitlab.rb

Scroll down to the **Container Registry settings** section. We’re going to uncomment the `registry_external_url` line and set it to our GitLab hostname with a port number of `5555`:

/etc/gitlab/gitlab.rb

    registry_external_url 'https://gitlab.example.com:5555'

Next, add the following two lines to tell the registry where to find our Let’s Encrypt certificates:

/etc/gitlab/gitlab.rb

    registry_nginx['ssl_certificate'] = "/etc/letsencrypt/live/gitlab.example.com/fullchain.pem"
    registry_nginx['ssl_certificate_key'] = "/etc/letsencrypt/live/gitlab.example.com/privkey.pem"

Save and close the file, then reconfigure GitLab:

    sudo gitlab-ctl reconfigure

    Output. . .
    gitlab Reconfigured!

Update the firewall to allow traffic to the registry port:

    sudo ufw allow 5555

Now switch to another machine with Docker installed, and log in to the private Docker registry. If you don’t have Docker on your local development computer, you can use whichever server is set up to run your GitLab CI jobs, as it has Docker installed already:

    docker login gitlab.example.com:5555

You will be prompted for your username and password. Use your GitLab credentials to log in.

    OutputLogin Succeeded

Success! The registry is set up and working. Currently it will store files on the GitLab server’s local filesystem. If you’d like to use an object storage service instead, continue with this section. If not, skip down to Step 3.

To set up an object storage backend for the registry, we need to know the following information about our object storage service:

- **Access Key**
- **Secret Key**
- **Region** (`us-east-1`) for example, if using Amazon S3, or **Region Endpoint** if using an S3-compatible service (`https://nyc.digitaloceanspaces.com`)
- **Bucket Name**

If you’re using DigitalOcean Spaces, you can find out how to set up a new Space and get the above information by reading [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key).

When you have your object storage information, open the GitLab configuration file:

    sudo nano /etc/gitlab/gitlab.rb

Once again, scroll down to the container registry section. Look for the `registry['storage']` block, uncomment it, and update it to the following, again making sure to substitute your own information where appropriate:

/etc/gitlab/gitlab.rb

    registry['storage'] = {
      's3' => {
        'accesskey' => 'your-key',
        'secretkey' => 'your-secret',
        'bucket' => 'your-bucket-name',
        'region' => 'nyc3',
        'regionendpoint' => 'https://nyc3.digitaloceanspaces.com'
      }
    }

If you’re using Amazon S3, you only need `region` and not `regionendpoint`. If you’re using an S3-compatible service like Spaces, you’ll need `regionendpoint`. In this case `region` doesn’t actually configure anything and the value you enter doesn’t matter, but it still needs to be present and not blank.

Save and close the file.

**Note:** There is currently a bug where the registry will shut down after thirty seconds if your object storage bucket is empty. To avoid this, put a file in your bucket before running the next step. You can remove it later, after the registry has added its own objects.

If you are using DigitalOcean Spaces, you can drag and drop to upload a file using the Control Panel interface.

Reconfigure GitLab one more time:

    sudo gitlab-ctl reconfigure

On your other Docker machine, log in to the registry again to make sure all is well:

    docker login gitlab.example.com:5555

You should get a `Login Succeeded` message.

Now that we’ve got our Docker registry set up, let’s update our application’s CI configuration to build and test our app, and push Docker images to our private registry.

## Step 3 — Updating `gitlab-ci.yaml` and Building a Docker Image

**Note:** If you didn’t complete the [prerequisite article on GitLab CI](how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04) you’ll need to copy over the example repository to your GitLab server. Follow the [Copying the Example Repository From GitHub](how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04#copying-the-example-repository-from-github) section to do so.

To get our app building in Docker, we need to update the `.gitlab-ci.yml` file. You can edit this file right in GitLab by clicking on it from the main project page, then clicking the **Edit** button. Alternately, you could clone the repo to your local machine, edit the file, then `git push` it back to GitLab. That would look like this:

    git clone git@gitlab.example.com:sammy/hello_hapi.git
    cd hello_hapi
    # edit the file w/ your favorite editor
    git commit -am "updating ci configuration"
    git push

First, delete everything in the file, then paste in the following configuration:

.gitlab-ci.yml

    image: docker:latest
    services:
    - docker:dind
    
    stages:
    - build
    - test
    - release
    
    variables:
      TEST_IMAGE: gitlab.example.com:5555/sammy/hello_hapi:$CI_COMMIT_REF_NAME
      RELEASE_IMAGE: gitlab.example.com:5555/sammy/hello_hapi:latest
    
    before_script:
      - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN gitlab.example.com:5555
    
    build:
      stage: build
      script:
        - docker build --pull -t $TEST_IMAGE .
        - docker push $TEST_IMAGE
    
    test:
      stage: test
      script:
        - docker pull $TEST_IMAGE
        - docker run $TEST_IMAGE npm test
    
    release:
      stage: release
      script:
        - docker pull $TEST_IMAGE
        - docker tag $TEST_IMAGE $RELEASE_IMAGE
        - docker push $RELEASE_IMAGE
      only:
        - master

Be sure to update the highlighted URLs and usernames with your own information, then save with the **Commit changes** button in GitLab. If you’re updating the file outside of GitLab, commit the changes and `git push` back to GitLab.

This new config file tells GitLab to use the latest docker image (`image: docker:latest`) and link it to the docker-in-docker service (docker:dind). It then defines `build`, `test`, and `release` stages. The `build` stage builds the Docker image using the `Dockerfile` provided in the repo, then uploads it to our Docker image registry. If that succeeds, the `test` stage will download the image we just built and run the `npm test` command inside it. If the test stage is successful, the `release` stage will pull the image, tag it as `hello_hapi:latest` and push it back to the registry.

Depending on your workflow, you could also add additional `test` stages, or even `deploy` stages that push the app to a staging or production environment.

Updating the configuration file should have triggered a new build. Return to the `hello_hapi` project in GitLab and click on the CI status indicator for the commit:

![GitLab commit notification with pipeline status icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/commit-widget.png)

On the resulting page you can then click on any of the stages to see their progress:

![GitLab pipeline detail](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/commit-pipeline.png)

![GitLab pipeline stage progress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/stage-detail.png)

Eventually, all stages should indicate they were successful by showing green check mark icons. We can find the Docker images that were just built by clicking the **Registry** item in the left-hand menu:

![GitLab container registry image list](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/docker-list.png)

If you click the little “document” icon next to the image name, it will copy the appropriate `docker pull ...` command to your clipboard. You can then pull and run your image:

    docker pull gitlab.example.com:5555/sammy/hello_hapi:latest
    docker run -it --rm -p 3000:3000 gitlab.example.com:5555/sammy/hello_hapi:latest

    Output> hello@1.0.0 start /usr/src/app
    > node app.js
    
    Server running at: http://56fd5df5ddd3:3000

The image has been pulled down from the registry and started in a container. Switch to your browser and connect to the app on port 3000 to test. In this case we’re running the container on our local machine, so we can access it via **localhost** at the following URL:

    http://localhost:3000/hello/test

    OutputHello, test!

Success! You can stop the container with `CTRL-C`. From now on, every time we push new code to the `master` branch of our repository, we’ll automatically build and test a new `hello_hapi:latest` image.

## Conclusion

In this tutorial we set up a new GitLab runner to build Docker images, created a private Docker registry to store them in, and updated a Node.js app to be built and tested inside of Docker containers.

To learn more about the various components used in this setup, you can read the official documentation of [GitLab CE](https://docs.gitlab.com/ce/README.html), [GitLab Container Registry](https://docs.gitlab.com/ee/administration/container_registry.html), and [Docker](https://docs.docker.com/).
