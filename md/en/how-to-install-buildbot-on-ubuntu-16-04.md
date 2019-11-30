---
author: Melissa Anderson
date: 2017-05-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-buildbot-on-ubuntu-16-04
---

# How To Install Buildbot on Ubuntu 16.04

## Introduction

Buildbot is a Python-based continuous integration system for automating software build, test, and release processes. It uses Python’s [Twisted library](https://pypi.python.org/pypi/Twisted) to handle asynchronous communication between a buildmaster and one or more workers to facilitate testing builds on multiple platforms. Buildbot is highly configurable and makes few assumptions about how the build process should work, making it suitable for complex build processes or projects that require their tools to grow with the unique needs of the project.

In this tutorial, we’ll install and configure a Buildbot buildmaster and worker on the same machine.

## Prerequisites

To follow this tutorial, you will need:

- **An Ubuntu 16.04 server with at least 1 GB of RAM** , configured with a non-root `sudo` user and a firewall as described in the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04). 

When the server is set up, you’re ready to follow along.

## Step 1 — Installing Buildbot

The Buildbot project recommends using the Python Package Index, pip, to install Buildbot in order to get the most recent version, which is often several releases ahead of what is available in the Ubuntu packages.

We’ll begin as our `sudo` user, and use `apt-get update` to ensure we have the latest list of packages:

    sudo apt-get update

Then, we’ll install pip itself:

    sudo apt-get install python-pip

Once pip is available, we’ll use it to install the Buildbot bundle, which includes the master and worker as well as other dependencies, including those required by the web interface. Pip creates `.cache` files in the home directory of the user who executes it. We’ll use `sudo`’s `-H` flag to put these files in the right location:

    sudo -H pip install 'buildbot[bundle]'

Depending on the speed of your server, this may take a little bit to complete. The end of the output from a successful installation should look something like the following:

    Output. . . 
    Successfully installed Automat-0.6.0 Jinja2-2.10 MarkupSafe-1.0 
    PyJWT-1.6.0 Tempita-0.5.2 Twisted-17.9.0 attrs-17.4.0 autobahn-18.3.1 
    buildbot-1.0.0 buildbot-console-view-1.0.0 buildbot-grid-view-1.0.0 
    buildbot-waterfall-view-1.0.0 buildbot-worker-1.0.0 buildbot-www-1.0.0 
    constantly-15.1.0 decorator-4.2.1 future-0.16.0 hyperlink-18.0.0 idna-2.6 
    incremental-17.5.0 pbr-3.1.1 python-dateutil-2.6.1 six-1.11.0 sqlalchemy-1.2.5 
    sqlalchemy-migrate-0.11.0 sqlparse-0.2.4 txaio-2.9.0 zope.interface-4.4.3

It may also display a recommendation to upgrade pip itself:

    Output. . .
    You are using pip version 8.1.1, however version 9.0.1 is available.
    You should consider upgrading via the 'pip install --upgrade pip' command.

While this won’t affect our Buildbot installation, we’ll take a moment to upgrade to pip’s latest release:

    sudo -H pip install --upgrade pip

    OutputCollecting pip
     Downloading pip-9.0.1-py2.py3-none-any.whl (1.3MB)
       100% |████████████████████████████████| 1.3MB 768kB/s
    Installing collected packages: pip
     Found existing installation: pip 8.1.1
       Not uninstalling pip at /usr/lib/python2.7/dist-packages, outside environment /usr
    Successfully installed pip-9.0.1

Finally, we’ll verify the installation of Buildbot by checking the version:

    buildbot --version

    OutputBuildbot version: 1.0.0
    Twisted version: 17.9.0

In the tutorial prerequisite, we configured a UFW firewall to allow SSH traffic only. We’ll verify the status:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Buildbot uses port 8010 for the web interface, which isn’t allowed, so we’ll open that now.

    sudo ufw allow 8010

Then, we’ll add a dedicated system user and group to run the Buildbot services:

    sudo addgroup --system buildbot
    sudo adduser buildbot --system --ingroup buildbot --shell /bin/bash

Finally, we’ll log in as our new user to install Buildbot:

    sudo --login --user buildbot

This will log us in as the `buildbot` user and place us in the `/home/buildbot` directory, where we’ll configure our master and worker:

## Step 2 — Configuring the Master

We’ll use the the buildbot command `create-master` followed by the value of the base directory:

    buildbot create-master ~/master

    Outputmkdir /home/buildbot/master
    creating /home/buildbot/master/master.cfg.sample
    creating database (sqlite:///state.sqlite)
    buildmaster configured in /home/buildbot/master
    

Next we’ll copy `master.cfg.sample` to `master.cfg` and leave the original in place for reference:

    cp ~/master/master.cfg.sample ~/master/master.cfg

Then, we’ll edit the file to allow us to reach the web interface from a local machine.

    nano ~/master/master.cfg

In order to access the web interface from a desktop or other device, we’ll change the `buildbotURL` from `localhost` to the IP address or domain name of the server. We will also set the usage reporting policy. Other important configuration values are set in `master.cfg`, but we’re going to keep the rest of the defaults for now.

Near the bottom of the file, locate the `buildbotURL` line and replace `localhost` with the IP address or domain name of your site:

~/master/master.cfg

    c['buildbotURL'] = "http://IP_or_site_domain:8010/"

**Note:** The `master.cfg` also pre-defines a worker in the “Workers” section.

~/master/master.cfg

    . . .
    ####### WORKERS
    
    # The 'workers' list defines the set of recognized workers. Each element is
    # a Worker object, specifying a unique worker name and password. The same
    # worker name and password must be configured on the worker.
    c['workers'] = [worker.Worker("example-worker", "pass")]
    . . .
    

Later in the tutorial, we’ll create a worker with these credentials.

Next, at the bottom of the file, set the value of the `buildbotNetUsageData` directive. This defines whether Buildbot will report usage statistics to the the developers to aid in improving the application. You can set this to `None` to opt out of this. If you don’t mind sending back basic information about your usage, use the string `"basic"` instead.   
 You can find more about this setting in [the Buildbot global configuration documentation](https://docs.buildbot.net/latest/manual/cfg-global.html#buildbotnetusagedata):

~/master/master.cfg

    c['buildbotNetUsageData'] = None
    # To send back basic information, use this instead:
    #c['buildbotNetUsageData'] = 'basic'

When you’ve modified the `'buildbotURL'` and added the `buildbotNetUsageData` line, save and exit the file.

Check the configuration of the master by typing:

    buildbot checkconfig ~/master

You’ll receive output ending with the following message if the syntax is okay:

    Output. . . 
    Config file is good!

If the output indicates that there were syntax errors, go back and check the file again. Once the `checkconfig` command indicates success, start the master:

    buildbot start ~/master

When the restart is successful, you should receive the following confirmation:

    OutputFollowing twistd.log until startup finished..
    The buildmaster appears to have (re)started correctly.

Finally, let’s visit the site in a web browser on port 8010 at the `buildbotURL` we configured:

`http://IP_or_site_domain:8010/`

![Screenshot of Buildbot's Welcome screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-welcome.png)

Now that we have the master running and have verified that we can access the web interface, we’ll create the example worker.

## Step 3 — Configuring a Worker

The relationship between a master and a worker is established when a worker’s name and password in the `master.cfg` file matches the name and password of a worker configured to use the master.

In this step, we’ll create and configure a worker by calling `buildbot-worker`’s `create-worker` command and passing in four settings:

- `worker` is the name of the directory where the worker’s settings will be stored
- `localhost` is the address where the worker’s master is running
- `example-worker` is the name of the worker and must uniquely identify the worker in the `~/master/master.cfg` file.
- `pass` is the worker’s password and this password must match the value in `~master/master.cfg`.

    buildbot-worker create-worker ~/worker localhost example-worker pass

    Outputmkdir /home/buildbot/worker
    mkdir /home/buildbot/worker/info
    Creating info/admin, you need to edit it appropriately.
    Creating info/host, you need to edit it appropriately.
    Not creating info/access_uri - add it if you wish
    Please edit the files in /home/buildbot/worker/info appropriately.
    worker configured in /home/buildbot/worker

When the worker first connects, it will send files in the `info` directory to the buildmaster where it runs. They’ll be displayed in the web interface to give developers more information about test failures.

We’ll configure these now. First, open the file containing the administrator’s e-mail, delete the example line, `Your Name Here <admin@youraddress.invalid>` and replace it with your name and email address.

    nano ~/worker/info/admin

~/worker/info/admin

    Sammy Shark <sammy@digitalocean.com>

When you’re done, save and exit the file.

The `info/host` file, by convention, provides the OS, version, memory size, CPU speed, versions of relevant libraries installed, and finally the Buildbot version running on the worker.

Open the file and paste in the relevant information, updating the sample content as needed for your system:

    nano ~/worker/info/host

Update the information you use to reflect the specifics of your system:

~/worker/info/host

    Ubuntu 16.04.2 2GB Droplet - Buildbot version: 1.0.0 - Twisted version: 17.1.0

When you’re done, save and exit. Finally, start the worker:

    buildbot-worker start ~/worker

    OutputFollowing twistd.log until startup finished..
    The buildbot-worker appears to have (re)started correctly.

Now that both the master and worker are configured and running, we’ll execute a test build.

## Step 4 — Running a Test Build

To run a test build, we’ll open the “Builds” menu in the web interface, then select “Workers”. The example worker and the information we set in `info/admin` and `info/host` should be displayed. From here, we can click on the default builder, “runtests” to force a build.

![Screenshot of Buildbot’s Workers Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-workers.png)

The “runtests” screen will have little information until the first build request is made. We’ll force one now by clicking “force” button in the upper right of the screen:

![Screenshot showing the force button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buldbot-force.png)

This will bring up a dialog which allows you to enter information about the forced build.  
 ![Screenshot of Buildbot's force build popup](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-info.png)

For this test build, we’ll leave the fields blank and click the “Start Build” button in the popup window. Note that if you do enter a value in the “Your name” field, it must contain a valid email address.

In a few seconds, the build should complete successfully:

![Screenshot showing successful build](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-success.png)

You can explore the details of each step in the build by clicking the number or arrow next to its name:

![enter image description here](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-build-details.png)

You may have noticed that we weren’t required to log in to execute this build. By default, anyone can access administrative functions, so before we finish, we’ll take a moment to lock that down and create a user account. You can learn more about the available options ins [Buildbot’s Authorization documentation].([http://docs.buildbot.net/current/developer/authz.html](http://docs.buildbot.net/current/developer/authz.html)).

Open the `master.cfg` file again:

    nano ~/master/master.cfg

At the bottom of the file, add the following lines, changing the username and password.

File: ~/master/master.cfg

    . . .
    c['www']['authz'] = util.Authz(
           allowRules = [
               util.AnyEndpointMatcher(role="admins")
           ],
           roleMatchers = [
               util.RolesFromUsername(roles=['admins'], usernames=['Sammy'])
           ]
    )
    c['www']['auth'] = util.UserPasswordAuth({'Sammy': 'Password'})

When you are finished, run another syntax check on the file:

    buildbot checkconfig ~/master

    OutputConfig file is good!

If no errors are displayed, restart the master service:

    buildbot restart ~/master

When we reload the web interface, a link should appear in the upper-right that says Anonymous and access to the administrative functions is no longer available.

![enter image description here](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-anonymous.png)

We’ll test the credentials we just added by clicking “Anonymous”, which will bring up a login box where we can enter the username and password we configured. When we log in, we should see that while “Anonymous” no longer has access to start a build, our “Sammy” user does.

![enter image description here](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/buildbot-install-ubuntu-1604/buildbot-sammy.png)

At this point, our installation of Buildbot is complete and we’ve taken a minimal step to secure the interface. The username and password, however, are being transmitted in plain text. We recommend as a next step and before using Buildbot in earnest that you secure the web interface with a [reverse proxy](http://docs.buildbot.net/current/manual/cfg-www.html?highlight=reverse%20proxy#reverse-proxy-configuration).

## Conclusion

In this tutorial, we’ve installed and configured the Buildbot master and a local Buildbot worker on the same machine. If you’re evaluating Buildbot, you might want to take the project’s [Quick Tour](http://docs.buildbot.net/current/tutorial/tour.html).

Otherwise, proceed to the next tutorial, [How To Create Systemd Unit Files for Buildbot](how-to-create-systemd-unit-files-for-buildbot), to allow the server’s init system to manage the Buildbot processes.
