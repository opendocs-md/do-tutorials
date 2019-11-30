---
author: Sanjin Šarić
date: 2018-06-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/deploying-react-applications-with-webhooks-and-slack-on-ubuntu-16-04
---

# Deploying React Applications with Webhooks and Slack on Ubuntu 16.04

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

When a developer is making continuous changes to an application, a deployment system with webhooks can streamline development, particularly for teams. Integrating Slack notifications for code changes into a team’s workflow can also be helpful if part of the team relies on back-end software like an API.

In this tutorial, you will build a React application with the [`create-react-app` `npm` package](https://github.com/facebook/create-react-app). This package simplifies the work of bootstrapping a React project by transpiling syntax and streamlining work with dependencies and prerequisite tools. After adding your application code to a GitHub repository, you will configure Nginx to serve your updated project files. You will then download and set up the webhook server and configure GitHub to communicate with it when your code is modified. Finally, you’ll configure Slack to act as another webhook server, which will receive notifications when a successful deploy has been triggered.

Ultimately, the deployment system you are building in this article will look like this:

![Sample deployment](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/react_deploy_webhooks/react-deploy.gif)

This short video shows an empty commit and push to the GitHub repository, which triggers the application build and notifications in Slack.

## Prerequisites

To complete this tutorial, you will need:

- An Ubuntu 16.04 server, which you can set up by following the [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04). After following this guide, you should have a non-root user account with sudo privileges.
- Nginx installed on your server by following the first two steps of [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04). 
- Git configured on both your local machine and your server. You can find instructions for installing and configuring Git in this tutorial on [getting started with Git](contributing-to-open-source-getting-started-with-git). 
- Node.js and `npm` installed on your local machine and server. For your server, follow the instructions on installing Node.js from a PPA in [How To Install Node.js on Ubuntu 16.04](how-to-install-node-js-on-ubuntu-16-04#how-to-install-using-a-ppa). On your local machine, you can follow the [project’s installation directions](https://nodejs.org/en/download/).
- Yarn installed on your server by following the official guide on [installing yarn](https://yarnpkg.com/lang/en/docs/install/).
- Permissions to configure Slack and individual channels for notifications. You can find more information on roles and permissions in the [Slack permissions docs](https://get.slack.help/hc/en-us/articles/201314026-Roles-and-permissions-in-Slack). 

## Step 1 — Creating a React Application Using create-react-app

Let’s first build the application that we will use to test our webhooks with `create-react-app`. We can then create a GitHub repository and push the project code to it.

On your local machine, add the `create-react-app` node module to your global repository and make the `create-react-app` command available in your shell environment:

    sudo npm install -g create-react-app

Next, run `create-react-app` to create a project called `do-react-example-app`:

    create-react-app do-react-example-app

Navigate to the directory `do-react-example-app`:

    cd do-react-example-app

With `nano` or your favorite text editor, open the `package.json` file:

    nano package.json

The file should look like this:

~/do-react-example-app/package.json

    
    {
      "name": "do-react-example-app",
      "version": "0.1.0",
      "private": true,
      "dependencies": {
        "react": "^16.2.0",
        "react-dom": "^16.2.0",
        "react-scripts": "1.0.17"
      },
      "scripts": {
        "start": "react-scripts start",
        "build": "react-scripts build",
        "test": "react-scripts test --env=jsdom",
        "eject": "react-scripts eject"
      }
    }

The `package.json` file includes the following scripts:

- **`start`** : This script is responsible for starting the development version of the application. It runs an HTTP server which serves the application.
- **`build`** : This script is responsible for making the production version of the application. You will use this script on the server.
- **`test`** : This script runs the default tests associated with the project.
- **`eject`** : This script is an advanced feature of the `create-react-app` package. If the developer is not satisfied with the build environment the package offers, it is possible to ‘eject’ the application, which will produce options that are otherwise unavailable (including things like custom CSS transpilers and JS processing tools). 

Close the file when you are finished inspecting the code.

Next, let’s create a GitHub repository for the project. You can follow this tutorial on [creating a GitHub repository](https://help.github.com/articles/create-a-repo/) for guidance. Take note of the repository’s origin (i.e. its GitHub URL).

Back in your `do-react-example-app` directory, initialize the repository with `git`:

    git init

Next, add the remote origin with your GitHub URL:

    git remote add origin your-github-url

Stage all of the files in the project directory:

    git add .

Commit them:

    git commit -m "initial commit"

And push them to repository:

    git push origin master

For more information on creating GitHub repositories and initializing existing applications with `git`, see GitHub’s [documentation](https://help.github.com/articles/adding-an-existing-project-to-github-using-the-command-line/).

Once we have finished the repository setup, we can move on to specifying configuration details on our server.

## Step 2 — Directory Set Up and Nginx Configuration

With the repository in place, it is now possible to pull the application code from GitHub and configure Nginx to serve the application.

Log into your server, go to your home directory, and clone your repository:

    cd ~
    git clone your-github-url

Go to the cloned project:

    cd do-react-example-app

To create a build directory within the project and files for Nginx to serve, you will will need to run the `yarn build` command. This runs the build script for the project, creating the build directory. This folder includes, among other things, an `index.html` file, a JavaScript file, and a CSS file. The `yarn` command will download all of the required node modules for your project:

    yarn && yarn build

Next, let’s make a symlink in the `/var/www/` directory to the `~/do-react-example-app` directory. This will keep the application in our home directory, while making it available to Nginx to serve from the `/var/www` directory:

    sudo ln -s ~/do-react-example-app /var/www/do-react-example-app

Note that this links to the project directory rather than to the build directory, which changes more frequently. Creating this link can be particularly helpful in scenarios where you are deploying new versions of the application: by creating a link to a stable version, you simplify the process of swapping it out later, as you deploy additional versions. If something goes wrong, you can also revert to a previous version in the same way.

Some permissions should be set on the symlink so Nginx can serve it properly:

    sudo chmod -R 755 /var/www

Next, let’s configure an Nginx server block to serve the build directory. Make a new server configuration by typing:

    sudo nano /etc/nginx/sites-available/test-server

Copy the following configuration, replacing `your_server_ip_or_domain` with your IP or domain (if applicable):

/etc/nginx/sites-available/test-server

    server {
            listen 80;
    
            root /var/www/do-react-example-app/build;
            index index.html index.htm index.nginx-debian.html;
    
            server_name your_server_ip_or_domain;
    
            location / {
                    try_files $uri /index.html;
            }
    }

The directives in this file include:

- **`listen`** : The property that configures the server listening port.
- **`root`** : The path to the folder from which Ngnix will serve files.
- **`index`** : The file that the server tries to serve first. It will try to serve any of following files from the `/var/www/do-react-example-app/build` directory: `index.html`, `index.htm`, `index.nginx-debian.html`, with priority from first to last.
- **`server_name`** : The server domain name or IP.

Next, make a symlink in the `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/test-server /etc/nginx/sites-enabled/test-server

This will tell Nginx to enable the server block configuration from the `sites-available`folder.

Check if the configuration is valid:

    sudo nginx -t

Finally, restart Nginx to apply the new configuration:

    sudo systemctl restart nginx

With these configuration details in place, we can move on to configuring the webhook.

## Step 3 — Installing and Configuring Webhooks

Webhooks are simple HTTP servers that have configurable endpoints called _hooks_. Upon receiving HTTP requests, webhook servers execute customizable code that adheres to a set of configurable rules. There are already many webhook servers integrated into applications across the internet, including Slack.

The most widely-used implementation of a webhook server is [Webhook](https://github.com/adnanh/webhook), written in Go. We will use this tool to set up our webhook server.

Make sure you are in your home directory on your server:

    cd ~

Then download the `webhook`:

    wget https://github.com/adnanh/webhook/releases/download/2.6.6/webhook-linux-amd64.tar.gz

Extract it:

    tar -xvf webhook-linux-amd64.tar.gz

Make the binary available in your environment by moving it to `/usr/local/bin`:

    sudo mv webhook-linux-amd64/webhook /usr/local/bin

Last, clean up the downloaded files:

    rm -rf webhook-linux-amd64*

Test the availability of `webhook` in your environment by typing:

    webhook -version

The output should display the `webhook` version:

    Outputwebhook version 2.6.5

Next, let’s set up `hooks` and `scripts` folders in the `/opt`directory, where files for third-party applications usually go. Since the `/opt` directory is usually owned by `root`, we can create directories with root privileges and then transfer ownership to the local `$USER`.

First, create the directories:

    sudo mkdir /opt/scripts
    sudo mkdir /opt/hooks

Then transfer the ownership to your `$USER`:

    sudo chown -R $USER:$USER /opt/scripts
    sudo chown -R $USER:$USER /opt/hooks

Next, let’s configure the `webhook` server by creating a `hooks.json` file. With `nano` or your favorite editor, create the `hooks.json` file in `/opt/hooks` directory:

    nano /opt/hooks/hooks.json

For the `webhook` to be triggered when GitHub sends HTTP requests, our file will need a JSON array of rules. These rules consist of the following properties:

    {
        "id": "",
        "execute-command": "",
        "command-working-directory": "",
        "pass-arguments-to-command": [],
        "trigger-rule": {}
    }

Specifically, these rules define the following information:

- **`id`** : The name of the endpoint the webhook server will serve. We will call this `redeploy-app`.
- **`execute-command`** : The path to the script that will be executed when the hook is triggered. In our case, this will be the `redeploy.sh` script located in `/opt/scripts/redeploy.sh`.
- **`command-working-directory`** : The working directory that will be used when executing the command. We will use `/opt/scripts` because that is where `redeploy.sh` is located.
- **`pass-arguments-to-command`** : The parameters passed to the script from the HTTP request. We will pass a commit message, pusher name, and commit id from the payload of the HTTP request. This same information will also be included in your Slack messages. 

The `/opt/hooks/hooks.json` file should include the following information:

/opt/hooks/hooks.json

    [
      {
        "id": "redeploy-app",
        "execute-command": "/opt/scripts/redeploy.sh",
        "command-working-directory": "/opt/scripts",
        "pass-arguments-to-command":
        [
          {
            "source": "payload",
            "name": "head_commit.message"
          },
          {
            "source": "payload",
            "name": "pusher.name"
          },
          {
            "source": "payload",
            "name": "head_commit.id"
          }
        ],
        "trigger-rule": {}
      }
    ]

The payload of the GitHub HTTP POST request includes the `head_commit.message`, `pusher.name`, and `head_commit.id` properties. When a configured event (like PUSH) happens in your GitHub repository, GitHub will send a POST request with a JSON body containing information about the event. Some examples of those POST payloads can be found in the [GitHub Event Types docs](https://developer.github.com/v3/activity/events/types/).

The last property in the configuration file is the `trigger-rule` property, which tells the webhook server under which condition the hook will be triggered. If left empty, the hook will always be triggered. In our case, we will configure the hook to be triggered when GitHub sends a POST request to our webhook server. Specifically, it will only be triggered if the GitHub secret (denoted here as `your-github-secret`) in the HTTP request matches the one in the rule, and the commit happened to the `master` branch.

Add the following code to define the `trigger-rule`, replacing `your-github-secret` with a password of your choosing:

    ... 
        "trigger-rule":
        {
          "and":
          [
            {
              "match":
              {
                "type": "payload-hash-sha1",
                "secret": "your-github-secret", 
                "parameter":
                {
                  "source": "header",
                  "name": "X-Hub-Signature"
                }
              }
            },
            {
              "match":
              {
                "type": "value",
                "value": "refs/heads/master",
                "parameter":
                {
                  "source": "payload",
                  "name": "ref"
                }
              }
            }
          ]
        }
      }
    ]

In full, `/opt/hooks/hooks.json` will look like this:

/opt/hooks/hooks.json

    [
      {
        "id": "redeploy-app",
        "execute-command": "/opt/scripts/redeploy.sh",
        "command-working-directory": "/opt/scripts",
        "pass-arguments-to-command":
        [
          {
            "source": "payload",  
            "name": "head_commit.message"
          },
          {
            "source": "payload",
            "name": "pusher.name"
          },
          {
            "source": "payload",
            "name": "head_commit.id"
          }
        ],
        "trigger-rule":
        {
          "and":
          [
            {
              "match":
              {
                "type": "payload-hash-sha1",
                "secret": "your-github-secret", 
                "parameter":
                {
                  "source": "header",
                  "name": "X-Hub-Signature"
                }
              }
            },
            {
              "match":
              {
                "type": "value",
                "value": "refs/heads/master",
                "parameter":
                {
                  "source": "payload",
                  "name": "ref"
                }
              }
            }
          ]
        }
      }
    ]

One final configuration item to check is your server’s firewall settings. The webhook server will be listening on port `9000`. This means that if a firewall is running on the server, it will need to allow connections to this port. To see a list of your current firewall rules, type:

    sudo ufw status

If port `9000` is not included in the list, enable it:

    sudo ufw allow 9000

For more information about `ufw`, see this introduction to [ufw essentials](ufw-essentials-common-firewall-rules-and-commands).

Next, let’s set up our GitHub repository to send HTTP requests to this endpoint.

## Step 4 — Configuring GitHub Notifications

Let’s configure our GitHub repository to send HTTP requests when a commit to master happens:

- 1. Go to your repository and click **Settings**.
- 2. Then go to **Webhooks** and click **Add Webhook** , located in top right corner.
- 3. For the **Payload URL** , type your server address as follows: `http://your_server_ip:9000/hooks/redeploy-app`. If you have a domain name, you can use that in place of `your_server_ip`. Note that the endpoint name matches the `id` property in the hook definition. This is a detail of webhook implementations: all hooks defined in `hooks.json` will appear in the URL as `http://your_server_ip:9000/hooks/id`, where `id` is the `id` in `hooks.json` file. 
- 4. For **Content type** , choose **application/json**.
- 5. For **Secret** , type the secret (`your-github-secret`) that you set in the `hooks.json` definition. 
- 6. For **Which events would you like to trigger this webhook?** select **Just push event**. 
- 7. Click the **Add webhook** button.

Now when someone pushes a commit to your repository, GitHub will send a POST request with the payload containing information about the commit event. Among other useful properties, it will contain the properties we defined in the trigger rule, so our webhook server can check whether the POST request was valid. If it is, it will contain other info like `pusher.name`.

The full list of properties sent with payload can be found on the [GitHub Webhooks page](https://developer.github.com/webhooks/).

## Step 5 — Writing the Deploy/Redeploy Script

At this point, we have pointed the webhook to the `redeploy.sh` script, but we haven’t created the script itself. It will do the work of pulling the latest master branch from our repository, installing node modules, and executing the build command.

Create the script:

    nano /opt/scripts/redeploy.sh

First, let’s add a function to top of the script that will clean up any files it has created. We can also use this as a place to notify third party software like Slack if the redeploy didn’t go through successfully:

/opt/scripts/redeploy.sh

    #!/bin/bash -e
    
    function cleanup {
          echo "Error occoured"
          # !!Placeholder for Slack notification
    }
    trap cleanup ERR

This tells the `bash` interpreter that if the script finished abruptly, it should run the code in the `cleanup` function.

Next, extract the parameters that `webhook` passes to the script when executing it:

/opt/scripts/redeploy.sh

    ...
    
    commit_message=$1 # head_commit.message
    pusher_name=$2 # pusher.name
    commit_id=$3 # head_commit.id
    
    
    # !!Placeholder for Slack notification

Notice that the order of the parameters corresponds to the `pass-arguments-to-command` property from the `hooks.json` file.

Last, let’s call the commands necessary for redeploying the application:

/opt/scripts/redeploy.sh

    ...
    
    cd ~/do-react-example-app/
    git pull origin master
    yarn && yarn build
    
    # !!Placeholder for Slack notification

The script in full will look like this:

/opt/scripts/redeploy.sh

    #!/bin/bash -e
    
    function cleanup {
          echo "Error occoured"
          # !!Placeholder for Slack notification
    }
    trap cleanup ERR
    
    commit_message=$1 # head_commit.message
    pusher_name=$2 # pusher.name
    commit_id=$3 # head_commit.id
    
    # !!Placeholder for Slack notification
    
    cd ~/do-react-example-app/
    git pull origin master
    yarn && yarn build
    
    # !!Placeholder for Slack notification

The script will go to the folder, pull the code from latest master branch, install fresh packages, and the build the production version of the application.

Notice the `!!Placeholder for Slack notification`. This is a placeholder for the last step in this tutorial. Without notifications, there is no real way of knowing if the script executed properly.

Make the script executable so the hook can execute it:

    chmod +x /opt/scripts/redeploy.sh

Because Nginx is configured to serve files from `/var/www/do-react-example-app/build`, when this script executes, the build directory will be updated and Nginx will automatically serve new files.

Now we are ready to test the configuration. Let’s run the webhook server:

    webhook -hooks /opt/hooks/hooks.json -verbose

The `-hooks` parameter tells `webhook` the location of the configuration file.

You will see this output:

    Output[webhook] 2017/12/10 13:32:03 version 2.6.5 starting
    [webhook] 2017/12/10 13:32:03 setting up os signal watcher
    [webhook] 2017/12/10 13:32:03 attempting to load hooks from /opt/hooks/hooks.json
    [webhook] 2017/12/10 13:32:03 os signal watcher ready
    [webhook] 2017/12/10 13:32:03 found 1 hook(s) in file
    [webhook] 2017/12/10 13:32:03 loaded: redeploy-app
    [webhook] 2017/12/10 13:32:03 serving hooks on http://0.0.0.0:9000/hooks/{id}

This tells us that everything is loaded properly and that our server is now serving the hook `redeploy-app` via the URL `http://0.0.0.0:9000/hooks/redeploy-app`. This exposes a path or hook on the server that can be executed. If you now do a simple REST call (like GET) with this URL, nothing special will happen because the hook rules were not satisfied. If we want the hook to be triggered successfully, we must fulfill the `trigger-rule` we defined in `hooks.json`.

Let’s test this with an empty commit in the local project directory. Leaving your webhook server running, navigate back to your local machine and type the following:

    git commit --allow-empty -m "Trigger notification"

Push the commit to the master branch:

    git push origin master

You will see output like this on your server:

    Output[webhook] 2018/06/14 20:05:55 [af35f1] incoming HTTP request from 192.30.252.36:49554
    [webhook] 2018/06/14 20:05:55 [af35f1] redeploy-app got matched
    [webhook] 2018/06/14 20:05:55 [af35f1] redeploy-app hook triggered successfully
    [webhook] 2018/06/14 20:05:55 200 | 726.412µs | 203.0.113.0:9000 | POST /hooks/redeploy-app
    [webhook] 2018/06/14 20:05:55 [af35f1] executing /opt/scripts/redeploy.sh (/opt/scripts/redeploy.sh) with arguments ["/opt/scripts/redeploy.sh" "Trigger notification" "sammy" "82438acbf82f04d96c53cd684f8523231a1716d2"] and environment [] using /opt/scripts as cwd

Let’s now add Slack notifications and look at what happens when the hook triggers a successful build with notifications.

## Step 6 — Adding Slack Notifications

To receive Slack notifications when your app is redeployed, you can modify the `redeploy.sh` script to send HTTP requests to Slack. It’s also necessary to configure Slack to receive notifications from your server by enabling the **Webhook Integration** in the Slack configuration panel. Once you have a **Webhook URL** from Slack, you can add information about the Slack webhook server to your script.

To configure Slack, take the following steps:

- 1. On the main screen of the Slack application, click the dropdown menu located on the top left and choose **Customize Slack**.
- 2. Next, go to the **Configure Apps** sections located in the left sidebar **Menu**.
- 3. In the **Manage** panel, choose **Custom Integration** from the lefthand list of options.
- 4. Search for the **Incoming WebHooks** integration.
- 5. Click **Add Configuration**.
- 6. Choose an existing channel or create a new one.
- 7. Click **Add Incoming WebHooks integration**.

After that, you will be presented with a screen displaying the Slack webhook settings. Make note of the **Webhook URL** , which is the endpoint generated by the Slack webhook server. When you are finished taking note of this URL and making any other changes, be sure to press the **Save Settings** button at the bottom of the page.

Return to your server and open the `redeploy.sh` script:

    nano /opt/scripts/redeploy.sh

In the previous step, we left placeholders in the script for Slack notifications, denoted as `!!Placeholder for Slack notification`. We will now replace these with `curl` calls that make POST HTTP requests to the Slack webhook server. The Slack hook expects the JSON body, which it will then parse, displaying the appropriate notification in the channel.

Replace the `!!Placeholder for slack notification` with the following `curl` calls. Note that you will need to replace `your_slack_webhook_url` with the **Webhook URL** you noted earlier:

/opt/scripts/redeploy.sh

    #!/bin/bash -e
    
    function cleanup {
          echo "Error occoured"
          curl -X POST -H 'Content-type: application/json' --data "{
                  \"text\": \"Error occoured while building app with changes from ${pusher_name} (${commit_id} -> ${commit_message})\",
                  \"username\": \"buildbot\",
                  \"icon_url\": \"https://i.imgur.com/JTq5At3.png\"
          }" your_slack_webhook_url
    }
    trap cleanup ERR
    
    commit_message=$1 # head_commit.message
    pusher_name=$2 # pusher.name
    commit_id=$3 # head_commit.id
    
    curl -X POST -H 'Content-type: application/json' --data "{
            \"text\": \"Started building app with changes from ${pusher_name} (${commit_id} -> ${commit_message})\",
            \"username\": \"buildbot\",
            \"icon_url\": \"https://i.imgur.com/JTq5At3.png\"
    }" your_slack_webhook_url
    
    cd ~/do-react-example-app/
    git pull origin master
    yarn && yarn build
    
    curl -X POST -H 'Content-type: application/json' --data "{
            \"text\": \"Build and deploy finished with changes from ${pusher_name} (${commit_id} -> ${commit_message})\",
            \"username\": \"buildbot\",
            \"icon_url\": \"https://i.imgur.com/JTq5At3.png\"
    }" your_slack_webhook_url

We have replaced each placeholder with a slightly different `curl` call:

- The first ensures that we receive notification of any errors that occurred while executing the script.
- The second sends the notification that the build of the application has started.
- The third sends the notification that the build has successfully finished.

More on Slack bots and integrations can be found in the [Slack webhooks documentation](https://api.slack.com/incoming-webhooks).

Again, we can test our hook with an empty commit in the local project directory. Leaving the webhook server running, navigate back to this directory and create the empty commit:

    git commit --allow-empty -m "Trigger notification"

Push the commit to the master branch to trigger the build:

    git push origin master

The output, including build information, will look like this:

    Output[webhook] 2018/06/14 20:09:55 [1a67a4] incoming HTTP request from 192.30.252.34:62900
    [webhook] 2018/06/14 20:09:55 [1a67a4] redeploy-app got matched
    [webhook] 2018/06/14 20:09:55 [1a67a4] redeploy-app hook triggered successfully
    [webhook] 2018/06/14 20:09:55 200 | 462.533µs | 203.0.113.0:9000 | POST /hooks/redeploy-app
    [webhook] 2018/06/14 20:09:55 [1a67a4] executing /opt/scripts/redeploy.sh (/opt/scripts/redeploy.sh) with arguments ["/opt/scripts/redeploy.sh" "Trigger notification" "sammy" "5415869a4f126ccf4bfcf2951bcded69230f85c2"] and environment [] using /opt/scripts as cwd
    [webhook] 2018/06/14 20:10:05 [1a67a4] command output: % Total % Received % Xferd Average Speed Time Time Time Current
                                     Dload Upload Total Spent Left Speed
    100 228 0 2 100 226 11 1324 --:--:-- --:--:-- --:--:-- 1329
    okFrom https://github.com/sammy/do-react-example-app
     * branch master -> FETCH_HEAD
       82438ac..5415869 master -> origin/master
    Updating 82438ac..5415869
    Fast-forward
    yarn install v1.7.0
    [1/4] Resolving packages...
    success Already up-to-date.
    Done in 1.16s.
    yarn run v1.7.0
    $ react-scripts build
    Creating an optimized production build...
    Compiled successfully.
    
    File sizes after gzip:
    
      36.94 KB build/static/js/main.a0b7d8d3.js
      299 B build/static/css/main.c17080f1.css
    
    The project was built assuming it is hosted at the server root.
    You can control this with the homepage field in your package.json.
    For example, add this to build it for GitHub Pages:
    
      "homepage" : "http://myname.github.io/myapp",
    
    The build folder is ready to be deployed.
    You may serve it with a static server:
    
      yarn global add serve
      serve -s build
    
    Find out more about deployment here:
    
      http://bit.ly/2vY88Kr
    
    Done in 7.72s.
      % Total % Received % Xferd Average Speed Time Time Time Current
                                     Dload Upload Total Spent Left Speed
    100 233 0 2 100 231 10 1165 --:--:-- --:--:-- --:--:-- 1166
    ok
    [webhook] 2018/06/14 20:10:05 [1a67a4] finished handling redeploy-app

In Slack, you will receive messages to your channel of choice notifying you that the application build has started and when it has finished.

## Conclusion

We have now finished setting up a deployment system using webhooks, Nginx, shell scripts, and Slack. You should now be able to:

- Configure Nginx to work with dynamic builds of your application. 
- Set up the webhook server and write hooks that trigger on GitHub POST requests.
- Write scripts that trigger application builds and notifications.
- Configure Slack to receive these notifications.

The system from this tutorial can be expanded, since the webhook server is modular and can be configured to work with other applications such as [GitLab](https://about.gitlab.com/). If configuring the webhook server through JSON is too much, you can build a similar setup using [Hookdoo](https://www.hookdoo.com). More information on how to configure trigger rules for `webhook` can be found on the webhook project [example hooks page](https://github.com/adnanh/webhook/wiki/Hook-Examples).
