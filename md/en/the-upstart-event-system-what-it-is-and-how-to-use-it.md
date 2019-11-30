---
author: Yasin Soliman
date: 2014-08-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/the-upstart-event-system-what-it-is-and-how-to-use-it
---

# The Upstart Event System: What It Is And How To Use It

## Introduction

**Initialization** is a crucial procedure that lies at the heart of any Unix-based operating system to control the operation of every script and service. This is essential in a server environment, where issues can occur at the critical points of startup and shutdown, and where ensuring optimal performance is a priority.

In essence, initialization follows this kind of process:

1. The server boots
2. The **init** process runs (usually as `PID 1`)
3. A predefined set of startup tasks activate in sequence

Initialization is responsible for ensuring the cloud server can boot up and shut down cleanly.

Some distributions with a Unix foundation utilize the standard **init** process for initialization. In this article, we’ll take a look at **Upstart** – a practical and powerful replacement that can supercharge your server’s operations.

## What’s wrong with the classic init?

Traditional initialization follows a linear process: individual tasks load in a predefined sequence as the system boots. This isn’t that helpful, especially in rapidly changing situations. To understand why, imagine that, for example, you modified the server’s environment by adding an additional storage device.

The initialization process isn’t able to take into account sudden changes in environment, meaning that your cloud server would have to be re-initialized before it could recognize the additional storage. On-the-fly detection is what’s needed, although it’s not a capability of classic initialization procedure.

Booting in a linear sequence also takes time, which is especially disadvantageous in a cloud-based environment where fast deployment is essential.

You may also be concerned about the status of your tasks after the system has loaded. Unfortunately, **init** is concerned with the sequence only when you’re booting up or powering down.

Synchronous boot sequences are no longer desirable. A rigid system could support the systems of yesterday, but today is dynamic.

That’s where **Upstart** comes in – a solution to these problems with advanced capabilities.

Based on _real-time_ events instead of a preset list of tasks in sequence, this replacement init daemon handles the starting and stopping of tasks _and_ monitors these processes while the system is running – “full coverage” is the best way to describe it.

This newly asynchronous processing eliminates the need for a rigid boot sequence. Real-time processing may be messy to conceptualize, but Upstart can support the most complex of systems and keep everything in check by using a structure of **jobs**.

## An Overview of Upstart

![Upstart Logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/upstart_event_system/1.png)

Designed with flexibility from the beginning, the Upstart event system utilizes a variety of concepts that differ from conventional initialization systems. The solution is installed by default on Red Hat Enterprise Linux (RHEL) 6, as well as Google’s Chrome OS, and Ubuntu, although recent debate has caused confusion over whether this will continue.

**Jobs**

In the world of Upstart, jobs are working processes, split into task jobs (with a purpose) and service jobs (which can run in the background). There are also abstract jobs – processes that run forever, until stopped by a user with administrative privileges.

**Events**

**Events** , however, are the signals or “calls” used to trigger a certain action with a job or another event. The common forms of events refer to the monitoring of a process: `starting`, `started`, `stopping` and `stopped`.

**Emitting Events**

The process of broadcasting an event is called “emitting.” This is usually caused by a process or job state, although an administrator can also emit an event manually by issuing the `initctl emit <event>` command. You will notice that the `init control` command becomes incredibly useful when navigating the plethora of operations associated with Upstart.

## Writing Your First Job Configuration

Upstart is known to perform well on Ubuntu, so spin up an **Ubuntu 14.04 Droplet** before getting started.

Now that you’re ready, it’s important to understand that a job configuration file must abide by three basic principles to be valid.

- It must not be empty (a file with no content)
- It must not contain any syntax errors
- It must contain at least one command block, known as a **stanza**

Let’s keep it basic for now. In a moment we will create a file called `testjob.conf` in the `/etc/init` directory. In this case, “init” is just used as the shortened version of “initialization.”

Notice the `.conf` file association – indicating that you’ll be writing a **job configuration file**.

For the purposes of this tutorial, the command-line text editor **nano** is recommended. Some of these commands may may require administrative privileges with `sudo`, so check out [this article](how-to-add-delete-and-grant-sudo-privileges-to-users-on-a-debian-vps) to create an appropriate user.

To create a new configuration file for our test job, run:

    sudo nano /etc/init/testjob.conf

Let’s now outline the objective. We want this job to **write a message and the current timestamp to a log file**.

There are two basic stanzas that can help you define the purpose of a job script and who created it: `description` and `author`. Write these as your first lines in the file.

    description "A test job file for experimenting with Upstart"
    author "Your Name"

Now, we want this job to take place after the system services and processes have already loaded (to prevent any conflict), so your next line will incorporate the following event:

    start on runlevel [2345]

You may be wondering what a runlevel is. Essentially, it’s a single value that represents the current system configuration. The `[2345]` refers to all the configuration states with general Linux access and networking, which is ideal for a basic test example.

We will then add the execution code. This line starts with `exec` to indicate that the following commands should be run through the Bash shell:

    exec echo Test Job ran at `date` >> /var/log/testjob.log

Notice this `echo` command uses backticks to run `date` as a command and then write the entire message to a log file. If you wrote the word `date` without backticks, the word itself would be printed instead of the command’s output.

Save and close this file.

You can verify that this works by manually starting the job, but let’s check the configuration file syntax first:

    init-checkconf /etc/init/testjob.conf

If any issues are detected, this command will indicate the specific line number and the problem. However, with the test job you should see output like this:

    File /etc/init/testjob.conf: syntax ok

This command can be used for controlling Upstart jobs and other background services, such as a web server.

The basic command syntax is:

    sudo service <servicename> <control>

This syntax works with these basic controls:

- restart: this will stop, then start a service
- start: this will start a service, if it’s not running
- stop: this will stop a service, if it’s running
- status: this will display the status of a service

We want to manually start our test job, so the command should look like this:

    sudo service testjob start

Now, check the `testjob.log` file by running the following command:

    cat /var/log/testjob.log

This command will read out the file into the shell; you should see a single line similar to the one below:

    Test Job ran at Fri Aug 1 08:43:05 BST 2014

This shows that your test job is set up and ready to go.

Reboot your Droplet, then log in and read the log file again:

    cat /var/log/testjob.log

You should see a second line in the log displaying a later timestamp to confirm it ran as an Upstart job.

    Test Job ran at Fri Aug 1 08:44:23 BST 2014

This merely scratches the surface of what you can do with Upstart. We’ll cover a detailed example later, but for now, let’s move on to an explanation of job states and events.

## Job States and Events

System jobs reside in the `/etc/init/` directory, and user jobs reside in the user’s own init directory, `~/.init/`.

User jobs run in the user’s own session, so they’re also known as session jobs. These don’t run system-wide and aren’t in the `PID 1` designation. For the purposes of our test job, we used `/etc/init` so it could load as the system booted.

Regardless of its type, a job is **always** defined in a configuration file (.conf) where its filename should represent the service or task involved.

Each of these jobs has a goal – to `start` or `stop`. Between these two goals are a set of task states, which define the current actions of the job in regards to the goal. The important states are as follows:

- waiting: the initial state of processing
- starting: where a job is about to start
- pre-start: where the pre-start section is loaded
- spawned: where a script section is about to run
- post-start: where post-start operations take place
- running: where the job is fully operational
- pre-stop: where pre-stop operations take place
- stopping: where the job is being stopped
- killed: where the job is stopped
- post-stop: where post-stop operations take place - to clean up

After the post-start state, the job is defined as running. It stays running until a pre-stop is triggered, where the job gets ready to stop, then the job is killed and the post-stop **cleanup** procedures take place, if defined.

You can view how a job transitions between states by setting the priority of the Upstart system log (located in the `/var/log/upstart/` directory) to `debug` with this command:

    sudo initctl log-priority debug

Remember that **states are not events, and events are not states**. The four events (starting, started, stopping and stopped) are emitted by Upstart but the task states define the transition between the stages of a job’s lifetime.

We’re now ready to move on to a more focused example that incorporates elements from your very first configuration by writing a service job. This will demonstrate how you can transition from running basic test configurations to production-ready scripts.

## In-Depth Example: A Service Job

Covered briefly in the introduction, a service job involves scripting configuration files that allow processes to run in the background. We’ll be setting up a **basic Node.js server** from scratch.

If you’re not familiar with Node, in essence it’s a “cross-platform environment for server-side and networking applications” (Wikipedia).

Node.js is a very lightweight package, although it isn’t installed by default on Ubuntu 14.04. To get started, go ahead and install it on your cloud server.

    sudo apt-get install nodejs

Now, let’s get started with the service job. Create a new job configuration file in `/etc/init` called `nodetest.conf`. Naming the file with reference to its purpose is essential, so you’ll be able to recognize that this service job is for a Node.js test.

    sudo nano /etc/init/nodetest.conf

We’ll cover the Node application itself later in the example, as it’s important to understand the Upstart configuration beforehand.

First things first. Start by entering the job description and author lines to define the configuration.

    description "Service for a test node.js server"
    author "Your Name"

We want this Node-powered server application to start when the server is up and running and to stop when it shuts down gracefully. Because of this, make sure to specify both conditions:

    start on filesystem or runlevel [2345]
    stop on shutdown

Remember the runlevel criteria from earlier? Combined with the `filesystem` event, this will ensure that the job loads when the server is up and running normally.

Those are the basics, but now it gets more complicated; we’re going to use the **stanzas** we mentioned earlier.

Since this is a server application, we’re going to incorporate a logging element in the job configuration. Because we want to log when the Node application starts and stops, we’ll be using three different stanzas to separate our service actions - `script`, `pre-start script` and `pre-stop script`.

If you think these sound familiar, you’re absolutely right. Pre-start and pre-stop are job states, but they also work in stanzas. What this means is that different commands can be run based on the state the job is in.

However, the first stanza to write is the job script itself. This will get a process ID for the Node background server and then run the application script. Note the indentation of commands inside a stanza – this is essential for syntactically correct formatting.

    script
    
        export HOME="/srv"
        echo $$ > /var/run/nodetest.pid
        exec /usr/bin/nodejs /srv/nodetest.js
    
    end script

Node requires a home directory variable to be set, hence why `/srv` is exported in the first line of the stanza. Next, `$$` is used to get an available process ID and create a PID file for our job. After that’s ready, the Node.js application is loaded, which we’ll write later.

It’s now time to focus on `pre-start` and `pre-stop`, which will be used for our simple application logging. The date, along with a starting or stopping message will be appended to a log file for our job:

    pre-start script
        echo "[`date`] Node Test Starting" >> /var/log/nodetest.log
    end script

Notice that the pre-stop stanza contains another line: removing the PID file as part of the procedure for shutting down the server (what pre-stop does).

    pre-stop script
        rm /var/run/nodetest.pid
        echo "[`date`] Node Test Stopping" >> /var/log/nodetest.log
    end script

That’s the entire Upstart job configuration sorted; here’s the whole thing again for reference:

    description "Test node.js server"
    author "Your Name"
    
    start on filesystem or runlevel [2345]
    stop on shutdown
    
    script
    
        export HOME="/srv"
        echo $$ > /var/run/nodetest.pid
        exec /usr/bin/nodejs /srv/nodetest.js
    
    end script
    
    pre-start script
        echo "[`date`] Node Test Starting" >> /var/log/nodetest.log
    end script
    
    pre-stop script
        rm /var/run/nodetest.pid
        echo "[`date`] Node Test Stopping" >> /var/log/nodetest.log
    end script

Save and close the file.

As noted in the `exec` line, a Node.js script is run from the server, so create a `nodetest.js` file in your desired location (`/srv/` is used for this example):

    sudo nano /srv/nodetest.js

As this is an Upstart tutorial, we won’t spend too long reviewing the Node.js code, although here’s a rundown of what this script will accomplish:

- Require and load Node’s HTTP module
- Create an HTTP web server
- Provide a status 200 (OK) response in the Header
- Write “Hello World” as output
- Listen on port 8888

Here’s the code you need to get the Node application running, which can be copied directly to save time:

    var http = require("http");
    
    http.createServer(function(request, response) {
        response.writeHead(200, {"Content-Type": "text/plain"});
        response.write("Hello World");
        response.end();
    }).listen(8888);

After saving the Node.js file, the last thing to check is if the Upstart job syntax is valid. As usual, run the configuration check command and you should receive a confirmation as output:

    init-checkconf /etc/init/nodetest.conf 
    
    File nodetest.conf: syntax ok

You’ve got your job configuration, checked its syntax, and have your Node.js code saved - everything’s ready to go, so reboot your Droplet and then visit [http://IP:\*\*8888\*\*](http://IP: **8888** ), or the associated domain.

If you’re met with “Hello World” in the top-left corner of the window, the Upstart service job has worked!

For confirmation of the state-based logging, read the predefined log file and you should see a timestamped `Starting` line. Shutting the server down or manually stopping the Service Job would write a `Stopping` line to the log, which you can also check if you wish.

    cat /var/log/nodetest.log
    
    [Sun Aug 17 08:08:34 EDT 2014] Node Test Starting
    [Sun Aug 17 08:13:03 EDT 2014] Node Test Stopping

You can run starndard start, stop, restart, etc. commands for this service, and any other similar Upstart jobs, with syntax like the following:

    sudo service nodetest restart

### Conclusion

This tutorial only scratches the surface of the Upstart Event System. You’ve read the background on traditional initialization, found out why the open-source Upstart solution is a more powerful choice, and started writing your own jobs. Now that you know the basics, the possibilities are endless.

_Logo from Upstart official website, copyright original designers/Canonical Ltd._
