---
author: Justin Ellingwood
date: 2017-06-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-continuous-integration-with-buildbot-on-ubuntu-16-04
---

# How To Set Up Continuous Integration with Buildbot on Ubuntu 16.04

## Introduction

[Buildbot](https://buildbot.net/) is a Python-based continuous integration system for automating software build, test, and release processes. In the previous tutorials, we [installed Buildbot](how-to-install-buildbot-on-ubuntu-16-04), [created systemd Unit files](how-to-create-systemd-unit-files-for-buildbot) to allow the server’s init system to manage the processes, and [configured Nginx as a reverse proxy](how-to-configure-buildbot-with-ssl-using-an-nginx-reverse-proxy) in order to direct SSL-secured browser requests to Buildbot’s web interface.

In this guide, we will demonstrate how to set up a continuous integration system to automatically test new changes to a repository. We will use a simple Node.js application to demonstrate the testing process and the necessary configuration. To isolate our testing environment from the Buildbot host, we will create a Docker image to run as our Buildbot worker. We will then configure the Buildbot master to watch the GitHub repository for changes, automatically testing each time new changes are detected.

## Prerequisites

To follow this tutorial, you will need:

- **One Ubuntu 16.04 server with at least 1 GB of RAM** , configured with a non-root `sudo` user and a firewall by following the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) 

In addition, you’ll need to complete the following tutorials on the server:

- [How To Install Buildbot on Ubuntu 16.04](how-to-install-buildbot-on-ubuntu-16-04)
- [How To Create Systemd Unit Files for Buildbot](how-to-create-systemd-unit-files-for-buildbot)
- [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04)
- [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04).
- [How To Configure Buildbot with SSL using an Nginx Reverse Proxy](how-to-configure-buildbot-with-ssl-using-an-nginx-reverse-proxy)
- [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04): (only Steps 1 and 2)

When you’ve completed these requirements, you’re ready to begin.

## Fork the Example Repository in GitHub

Before we get started configuring Buildbot, we will take a look at the example repository that we will be using for this guide.

In your web browser, visit the [hello hapi application on GitHub](https://github.com/do-community/hello_hapi) that we will be using for demonstration. This application is a simple “hello world” program with a few unit and integration tests, written in [hapi](https://hapijs.com/), a Node.js web framework.

Since this example is used to demonstrate a variety of continuous integration systems, you may notice some files used to define pipelines for other systems. For Buildbot, we will be defining the build steps on the server instead of within the repository.

Later on, we will be setting up webhooks for Buildbot within our repository so that changes will automatically trigger new tests. For now, we need to create our own fork of the repository.

Click on the **Fork** button in the upper-right corner of the screen:

![GitHub fork repository button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/fork_repository.png)

If you are a member of a GitHub organization, you may be asked where you would like to fork the repository:

![GitHub where to fork repo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/where_to_fork.png)

Once you select an account or organization, a copy of the repository will be added to your account:

![GitHub your fork](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/your_fork.png)

You will use the URL for your fork within the Buildbot configuration. Now that we have a repository URL, we can begin configuring Buildbot.

## Set Up Docker for Buildbot

We will start off by setting up Docker so that Buildbot uses it to perform builds. First, we need to configure access between Docker and Buildbot. Afterwards, we need to create a Docker image to use for our containers.

### Configure Access to Docker for Buildbot

We need to allow Buildbot and Docker to communicate on a few different levels.

First, we need to make sure that the Buildbot process has access to the Docker daemon. We can do this by adding the **buildbot** user to the **docker** group:

    sudo usermod -aG docker buildbot

This new group will be available to Buildbot the next time the Buildbot master is restarted, which we will do later.

We also need to make sure that Buildbot knows how to communicate with Docker. Since Buildbot is written in Python, it leverages the [`docker-py` Python package](https://docker-py.readthedocs.io/en/stable/) instead of issuing Docker commands directly.

You can install `docker-py` by typing:

    sudo -H pip install docker-py

Finally, we need to open up network access from containers to the host system and the outside world. We can do this by allowing an exception for the `docker0` interface in our firewall.

Allow access to traffic from the `docker0` interface by typing:

    sudo ufw allow in on docker0

Buildbot and Docker should now be able to communicate with one another effectively.

### Create a Docker Image To Use as a Buildbot Worker

Next, we will create a Docker container to use as a Buildbot worker to run our tests. Buildbot can dynamically start Docker containers to use as workers, but the containers first need to be built with some Buildbot worker components included.

Fortunately, the Buildbot project provides a basic [Buildbot worker image](https://hub.docker.com/r/buildbot/buildbot-worker/) that already has all of the Buildbot-specific requirements configured. We just need to use this image as a base and install the additional dependencies that our project requires.

In our case, the [example application that we will be using](https://github.com/do-community/hello_hapi) is a Node.js application, so we need to make sure that Node.js is available on the image.

To define our image, create and open a file called `Dockerfile` in your home directory:

    nano ~/Dockerfile

In this file, we base our image off of the Buildbot worker image using `FROM buildbot/buildbot-worker:master`. Afterwards, we can switch to the `root` user to install Node.js, and then switch back to the `buildbot` user to run the actual commands:

~/Dockerfile

    FROM buildbot/buildbot-worker:master
    
    USER root
    RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
    RUN apt-get install -y nodejs
    USER buildbot

Save and close the file when you are finished.

Once we have a `Dockerfile`, we can build our image from it. We will call the image `npm-worker` to be explicit about the extra dependencies that we installed:

    docker build -t npm-worker - < ~/Dockerfile

Docker will begin to build your image based on the commands we outlined in the `Dockerfile`. It will pull down the base image and its dependency layers, install Node.js, and then save the resulting environment to an image called `npm-worker`.

## Configure the Buildbot Master

Now that we have a Docker image, we can configure the Buildbot master to use it.

Because we are defining an entirely new build process and because our customizations to the Master configuration have been minimal up to this point, we will be starting our configuration from scratch. To avoid losing the current information, we will move the original file to a backup file:

    sudo mv /home/buildbot/master/master.cfg /home/buildbot/master/master.cfg.bak

Display the configuration of the backup file so that we can copy a few important values to use in our new configuration:

    sudo cat /home/buildbot/master/master.cfg.bak

The important parts we want to transfer over to the new configuration are the user credentials and permissions. Look for the configuration sections starting with `c['www']['authz']` and `c['www']['auth']` in the output:

    Output. . .
    c['www']['authz'] = util.Authz(
            allowRules = [
                    util.AnyEndpointMatcher(role="admins")
            ],
            roleMatchers = [
                    util.RolesFromUsername(roles=['admins'], usernames=['Sammy'])
            ]
    )
    c['www']['auth'] = util.UserPasswordAuth({'Sammy': 'Password'})
    . . .

Copy and save these lines somewhere so that you can reference them later. We will be adding these details to our new Buildbot master configuration to preserve our user and authentication settings.

Now, create a new `master.cfg` file where we can redefine our Buildbot instance’s behavior:

    sudo nano /home/buildbot/master/master.cfg

We will define our new Buildbot master configuration in this file.

### Set Up a Basic Project Configuration

The Buildbot configuration file is actually a Python module, which provides great flexibility at the expense of some complexity.

We will begin with some basic configuration. Paste the following lines in your file:

/home/buildbot/master/master.cfg

    # -*- python -*-
    # ex: set filetype=python:
    from buildbot.plugins import *
    
    
    c = BuildmasterConfig = {}
    
    # Basic config
    c['buildbotNetUsageData'] = None
    c['title'] = "Hello Hapi"
    c['titleURL'] = "https://github.com/your_github_name/hello_hapi"
    c['buildbotURL'] = "https://buildmaster_domain_name/"
    c['protocols'] = {'pb': {'port': 9989}}

The top of the file contains a few comments that many text editors are able to interpret to correctly apply syntax highlighting. Afterwards, we import everything from the `buildbot.plugins` package so that we have the tools available to construct our configuration.

Buildbot configuration is all defined by a dictionary named `BuildmasterConfig`, so we set this variable to an empty dictionary to start. We create a shorthand variable named `c` set to this same dictionary to reduce the amount of typing necessary throughout the file.

Some things to note in the configuration that follows:

- `buildbotNetUsageData` is set to `None`. Change this to the string `"basic"` if you want to report usage data to the developers.
- The `title` and `titleURL` reflect the project’s name and GitHub repository. Use the link to your own fork.
- `buildbotURL` is set to the Buildbot master’s SSL-secured domain name. Remember to start with `https://` and end with a trailing slash `/`.
- Unlike our last configuration, the `protocol` definition does not bind to localhost. We need to allow connections from Docker containers over the Docker bridge network `docker0`.

### Configure the Docker Worker

Next, we need to define our Docker worker. Buildbot will use Docker to provision workers as needed. To do so, it needs to know how to connect to Docker and which image to use.

Paste the following at the bottom of the file:

/home/buildbot/master/master.cfg

    . . .
    
    # Workers
    c['workers'] = []
    c['workers'].append(worker.DockerLatentWorker("npm-docker-worker", None,
                            docker_host='unix://var/run/docker.sock',
                            image='npm-worker',
                            masterFQDN='buildmaster_domain_name'))

The `c['workers'] = []` line demonstrates a basic convention we will use as we go through the configuration. We set a key in the configuration dictionary to an empty list. We then append elements to the list to implement the actual configuration. This gives us the flexibility to add additional elements later.

To define our worker, we create and append a `worker.DockerLatentWorker` instance to the `worker` list. We name this worker `npm-docker-worker` so that we can refer to it later in the configuration. We then set the `docker_host` to Docker’s socket location and provide the name of the Docker image we created (`npm-worker` in our case). We set `masterFQDN` to our Buildbot master’s domain name to make sure that the container can reach the master regardless of the server’s internal hostname settings.

### Configure a Scheduler

Next, we will define a scheduler. Buildbot uses schedulers to decide when and how to run builds based on the changes it receives from change sources or change hooks (we will configure a change hook later).

Paste the following configuration at the bottom of the file:

/home/buildbot/master/master.cfg

    . . .
    
    # Schedulers
    c['schedulers'] = []
    c['schedulers'].append(schedulers.SingleBranchScheduler(
                    name="hello_hapi",
                    change_filter=util.ChangeFilter(project='your_github_name/hello_hapi', branch='master'),
                    treeStableTimer=3,
                    builderNames=["npm"]))

We use the same method of appending our config to an empty list here. In this case, we append a `schedulers.SingleBranchScheduler` instance. This allows us to watch a single branch on the repository, which simplifies the configuration.

We name the scheduler “hello\_hapi” to properly identify it. We then define a change filter. Many different sets of changes from different sources may be handed to a scheduler. Change filters define a set of criteria that will determine whether the change in question should be processed by this particular scheduler. In our case, we filter based on the name of the project, which will be reported by the GitHub webhook, and the branch we wish to watch.

Next, we set the `treeStableTimer`, which determines the amount of time to wait for additional changes, to 3 seconds. This helps prevent Buildbot from queuing up many small builds for changes that are closely related. Finally, we define the names of the builders that should be used when a change matches our criteria (we will define this builder momentarily).

### Configure a Build Factory for the Node.js Projects

Next, we will configure a build factory for handling Node.js projects. A build factory is responsible for defining the steps that should be taken to build, or in our case test, a project. It does this by defining a `util.BuildFactory` instance and then adding sequential steps that should be performed.

Paste the following at the bottom of your file:

/home/buildbot/master/master.cfg

    . . .
    
    # Build Factories
    npm_f = util.BuildFactory()
    npm_f.addStep(steps.GitHub(repourl='git://github.com/your_github_name/hello_hapi.git', mode='full', method='clobber'))
    npm_f.addStep(steps.ShellCommand(command=["npm", "install"]))
    npm_f.addStep(steps.ShellCommand(command=["npm", "test"]))

First, we define a build factory called `npm_f`. The first step that we add is a `steps.GitHub` instance. Here, we set the repository that should be pulled down into the builder. We set `mode` to “full” and the `method` to “clobber” to completely clean up our repository every time we pull new code.

The second and third steps we add are `steps.ShellCommand` objects, which define shell commands to run inside the repository during the build. In our case, we need to run `npm install` to gather the project’s dependencies. Afterwards, we need to run `npm test` to run our test suite. Defining the commands as an list (`["npm", "install"]`) is recommended in most cases to prevent the shell from applying unwanted expansion on elements within the command.

### Configure a Builder

Once we have a build factory with the steps added, we can set up a builder. The builder ties together many of the elements that we’ve already defined to determine how a build will be executed.

Paste the following configuration at the bottom of the file:

/home/buildbot/master/master.cfg

    . . .
    
    # Builders
    c['builders'] = []
    c['builders'].append(
            util.BuilderConfig(name="npm",
                    workernames=["npm-docker-worker"],
                    factory=npm_f))

We append a `util.BuilderConfig` object to the `builders` list. Remember that our build factory is called `npm_f`, that our Docker worker is called `npm-docker-worker`, and that the scheduler we defined will pass tasks to a worker named `npm`. Our builder defines the relationship between these elements so that changes from our scheduler will cause the build factory steps to be executed in the Docker worker.

### Configure the Database and Web Interface

Finally, we can configure the database and web interface settings. Unlike many of the previous items, these two settings are defined as dictionaries rather than lists. The `db` dictionary just points to the `state.sqlite` file already in our `/home/buildbot/master` directory. The `www` dictionary contains a significant amount of additional configuration.

Paste the following at the bottom of your file. Substitute the authentication information you copied from your original Buildbot master configuration for the authentication block below:

/home/buildbot/master/master.cfg

    . . .
    
    # Database
    c['db'] = { 'db_url': "sqlite:///state.sqlite",}
    
    # Web Interface
    c['www'] = dict(port=8010, plugins=dict(waterfall_view={}, console_view={}))
    
    # Auth info copied from the original configuration
    c['www']['authz'] = util.Authz(
            allowRules = [
                    util.AnyEndpointMatcher(role="admins")
            ],
            roleMatchers = [
                    util.RolesFromUsername(roles=['admins'], usernames=['Sammy'])
            ]
    )
    c['www']['auth'] = util.UserPasswordAuth({'Sammy': 'Password'})
    # End of auth info copied from the original configuration
    
    # GitHub webhook receiver
    c['www']['change_hook_dialects'] = {
            'github': {
                    'secret': 'your_secret_value',
                    'strict': True,
            }
    }

After defining the database settings, we create a `www` dictionary that starts off by defining the port to listen to and some of the views to include in the web UI. Next, we add the authentication requirements we pulled from the previous Buildbot configuration file.

At the end, we define a dictionary called `change_hook_dialects` within the `www` dictionary. We use this to define a GitHub change hook, which will listen for webhook messages from GitHub. Choose a secure passphrase for your `secret`, which will be used by GitHub to authenticate the messages it will send.

When you are finished, save and close the file.

## Restart the Buildbot Master to Apply the New Configuration

At this point, we’ve completely reconfigured the Buildbot master process. We need to restart the Buildbot master process to implement the changes.

Before we do that, it’s important to check our file for syntax errors. Since we’ve rebuilt the configuration from scratch, there’s a good chance that we might have introduced a few mistakes.

Check the syntax of the file by typing:

    sudo buildbot checkconfig /home/buildbot/master

The command will report any issues it finds. If no errors were found, you will receive a message that looks like this:

    OutputConfig file is good!

If any errors are reported, try to get a better sense of what is wrong by reading the error message carefully. Open the configuration file again to try to fix any issues.

When there are no longer any errors, restart the Buildbot master service by typing:

    sudo systemctl restart buildbot-master

Check whether the operation was successful by typing:

    sudo systemctl status buildbot-master

    Output● buildbot-master.service - BuildBot master service
       Loaded: loaded (/etc/systemd/system/buildbot-master.service; enabled; vendor preset: enabled)
       Active: active (running) since Tue 2017-06-27 19:24:07 UTC; 2s ago
     Main PID: 8298 (buildbot)
        Tasks: 2
       Memory: 51.7M
          CPU: 1.782s
       CGroup: /system.slice/buildbot-master.service
               └─8298 /usr/bin/python /usr/local/bin/buildbot start --nodaemon
    
    Jun 27 19:24:07 bb5 systemd[1]: Started BuildBot master service

If the service was able to restart successfully, it will be marked as active.

### Create a GitHub Webhook in the Example Repository

Now that Buildbot is configured with a web endpoint to accept GitHub webhook posts, we can configure a webhook for our fork.

In your web browser, navigate to your fork of the example project repository:

    https://github.com/your_github_user/hello_hapi

Click the **Settings** tab to view the project settings. In the left-hand menu of the settings page, click **Webhooks** (GitHub may prompt you to reenter your password during this process to confirm your identity):

![GitHub webhooks initial page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/webhooks_initial_page.png)

Click the **Add webhook** button along the right-hand side to add a new webhook.

The page that follows will contain a form to define your webhook. In the **Payload URL** field, add the URL for your project’s GitHub change hook endpoint. This is constructed by specifying the `https://` protocol, followed by your Buildbot master’s domain name, followed by `/change_hook/github`.

Leave the Content type set to `application/x-www-form-urlencoded`. In the **Secret** field, enter the secret passphrase that you chose in your Buildbot master configuration file. You can leave the “Just the push event” trigger selected and the “Active” check box ticked:

![GitHub webhooks form](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/webhooks_form.png)

When you are finished, click the **Add webhook** button.

You will be returned to the project’s webhooks index, where your new webhook will be displayed. If you refresh a few times, a green check mark icon should be displayed next to your webhook indicating that a message was transmitted successfully:

![GitHub webhook success icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/webhooks_success_icon.png)

If you see a red X instead, click on the webhook again and then scroll down to the **Recent Deliveries** section. More information about what went wrong is available if you click on the failed delivery.

## Testing the Webhook

Now that we have our webhook in place, we can test to make sure that when we make changes to our repository, Buildbot is alerted, triggers a build in Docker, and is able to successfully execute the test suite.

In the main page of your GitHub fork, click on the **Create new file** button to the left of the green “Clone or download” button:

![GitHub create new file button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/create_new_file_button.png)

On the screen that follows, create a `dummy_file` and fill in some text:

![GitHub create dummy file](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/create_dummy_file.png)

Click the **Commit new file** button at the bottom of the page when you are finished.

Next, visit your Buildbot web interface and log in if you aren’t already authenticated.

Depending on how long it has been since you committed the `dummy_file` to your repository, you may see an in progress build that looks like this:

![Buildbot in progress build](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/in_progress_build.png)

If the build is already completed, it will be in the “recent builds” section instead:

![Buildbot build complete](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/build_complete.png)

The name of the builder we defined, “npm”, is used to label the build. In the example, we can also see an older run of the sample builder from the previous Master configuration.

Regardless of the progress, click on the builder name and build number link to visit the build details page. This view contains information about the build that was conducted. Each step that we added to the build factory will be displayed in its own section:

![Buildbot build details view](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/build_details_view.png)

If you click on a step, the output from the command will be displayed. This can help with debugging if something goes wrong:

![Buildbot build step output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot_usage_1604/build_step_output.png)

In the above output, we can verify that Buildbot ran the three tests within our test suite successfully.

If the build did not complete successfully, some other areas you may wish to check are the other tabs on the build details page as well as the `/home/buildbot/master/twistd.log` file.

### Adjusting the Buildbot Services

Before we finish, we should make a few adjustments to our Buildbot services.

Currently, we have a `buildbot-worker` service defined for a worker we are no longer using (our Docker worker is started automatically when required). We should stop and disable our old worker.

To stop the running service and disable it from starting at boot, type:

    sudo systemctl stop buildbot-worker
    sudo systemctl disable buildbot-worker

    OutputRemoved symlink /etc/systemd/system/buildbot-master.service.wants/buildbot-worker.service.

The above output indicates that the worker will not be started next boot. To verify that the service is no longer running, type:

    sudo systemctl status buildbot-worker

    Output● buildbot-worker.service - BuildBot worker service
       Loaded: loaded (/etc/systemd/system/buildbot-worker.service; disabled; vendor preset: enabled)
       Active: inactive (dead)
    
    Jun 27 21:12:48 bb6 systemd[1]: Started BuildBot worker service.
    Jun 27 21:55:51 bb6 systemd[1]: Stopping BuildBot worker service...
    Jun 27 21:55:51 bb6 systemd[1]: Stopped BuildBot worker service.

The last thing we should do is establish a soft dependency between our Buildbot master service and the Docker daemon. Since the Buildbot master service will be unable to provision new workers without Docker, we should define this requirement.

Open the `buildbot-master.service` file within the `/etc/systemd/system` directory to adjust the service file:

    sudo nano /etc/systemd/system/buildbot-master.service

In the `[Unit]` section, add `docker.service` to the `After` directive after the `network.target` item. Add an additional `Wants` directive that also names `docker.service`. The `Wants` establishes a soft dependency while the `After` directive establishes the starting order:

/etc/systemd/system/buildbot-master.service

    [Unit]
    Description=BuildBot master service
    After=network.target docker.service
    Wants=docker.service
    
    [Service]
    User=buildbot
    Group=buildbot
    WorkingDirectory=/home/buildbot/master
    ExecStart=/usr/local/bin/buildbot start --nodaemon
    
    [Install]
    WantedBy=multi-user.target

Save and close the file when you are finished.

Reload the systemd daemon and the service to apply the configuration immediately:

    sudo systemctl daemon-reload
    sudo systemctl restart buildbot-master

The Buildbot master process should now be started after Docker is available.

## Conclusion

In this tutorial, we configured Buildbot to listen for changes to a GitHub repository using webhooks. When a change is received, Buildbot starts up a container based on a custom Docker image to test the new commit. The Docker image contains a Buildbot worker instance as well as the dependencies needed to test our project code. This allows Buildbot to dynamically start Buildbot workers as needed whenever a change is made to the repository.
