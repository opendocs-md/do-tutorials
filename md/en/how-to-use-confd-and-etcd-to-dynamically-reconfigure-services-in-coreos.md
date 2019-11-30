---
author: Justin Ellingwood
date: 2014-09-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-confd-and-etcd-to-dynamically-reconfigure-services-in-coreos
---

# How To Use Confd and Etcd to Dynamically Reconfigure Services in CoreOS

## Introduction

CoreOS allows you to easily run services in Docker containers across a cluster of machines. The procedure for doing so usually involves starting one or multiple instances of a service and then registering each instance with `etcd`, CoreOS’s distributed key-value store.

By taking advantage of this pattern, related services can obtain valuable information about the state of the infrastructure and use this knowledge to inform their own behavior. This makes it possible for services to dynamically configure themselves whenever significant `etcd` values change.

In this guide, we will discuss a tool called `confd`, which is specifically crafted to watch distributed key-value stores for changes. It is run from within a Docker container and is used to trigger configuration modifications and service reloads.

## Prerequisites and Goals

In order to work through this guide, you should have a basic understanding of CoreOS and its component parts. In previous guides, we set up a CoreOS cluster and became familiar with some of the tools that are used to manage your clusters.

Below are the guides that you should read before starting on this article. We will be modifying the behavior of some of the services described in these guides, so while it is important to understand the material, you should start fresh when using this guide:

- [How To Set Up a CoreOS Cluster on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean)
- [How To Create and Run a Service on a CoreOS Cluster](how-to-create-and-run-a-service-on-a-coreos-cluster)
- [How to Create Flexible Services for a CoreOS Cluster with Fleet Unit Files](how-to-create-flexible-services-for-a-coreos-cluster-with-fleet-unit-files)

Additionally, to get more familiar with some of the management tools that we will be using, you want to go through these guides:

- [How To Use Fleet and Fleetctl to Manage your CoreOS Cluster](how-to-use-fleet-and-fleetctl-to-manage-your-coreos-cluster)
- [How To Use Etcdctl and Etcd, CoreOS’s Distributed Key-Value Store](how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-store)

The “How to Create Flexible Services” guide is especially important for this guide, as the templated main + sidekick services will serve as the basis for the front-end service we will be setting up in this guide. As we stated earlier, although the above guides discuss the creation of Apache and sidekick services, there are some configuration changes for this guide that make it easier to start from scratch. We will create modified versions of these services in this guide.

In this tutorial, we will focus on creating a new application container with Nginx. This will serve as a reverse proxy to the various Apache instances that we can spawn from our template files. The Nginx container will be configured with `confd` to watch the service registration that our sidekick services are responsible for.

We will start with the same three machine cluster that we have been using through this series.

- coreos-1
- coreos-2
- coreos-3

When you have finished reading the preceding guides and have your three machine cluster available, continue on.

## Configuring the Backend Apache Services

We will begin by setting up our backend Apache services. This will mainly mirror the last part of the previous guide, but we will run through the entire procedure here due to some subtle differences.

Log into one of your CoreOS machines to get started:

    ssh -A core@ip_address

### Apache Container Setup

We will start by creating the basic Apache container. This is actually identical to the last guide, so you do not have to do this again if you already have that image available in your Docker Hub account. We’ll base this container off of the Ubuntu 14.04 container image.

We can pull down the base image and start a container instance by typing:

    docker run -i -t ubuntu:14.04 /bin/bash

You will be dropped into a `bash` session once the container starts. From here, we will update the local `apt` package index and install `apache2`:

    apt-get update
    apt-get install apache2 -y

We will also set the default page:

    echo "<h1>Running from Docker on CoreOS</h1>" > /var/www/html/index.html

We can exit the container now since it is in the state we need:

    exit

Log into or create your account out Docker Hub by typing:

    docker login

You will have to give your username, password, and email address for your Docker Hub account.

Next, get the container ID of the instance you just left:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    1db0c9a40c0d ubuntu:14.04 "/bin/bash" 2 minutes ago Exited (0) 4 seconds ago jolly_pare

The highlighted field above is the container ID. Copy the output that you see on your own computer.

Now, commit using that container ID, your Docker Hub username, and a name for the image. We’ll use “apache” here:

    docker commit 1db0c9a40c0d user_name/apache

Push your new image up to Docker Hub:

    docker push user_name/apache

Now can use this image in your service files.

### Creating the Apache Service Template Unit File

Now that you have a container available, you can create a template unit file so that `fleet` and `systemd` can correctly manage the service.

Before we begin, let’s set up a directory structure so that we can stay organized:

    cd ~
    mkdir static templates instances

Now, we can make our template file within the `templates` directory:

    vim templates/apache@.service

Paste the following information into the file. You can get details about each of the options we are using by following the previous guide on [creating flexible fleet unit files](how-to-create-flexible-services-for-a-coreos-cluster-with-fleet-unit-files):

    [Unit]
    Description=Apache web server service on port %i
    
    # Requirements
    Requires=etcd.service
    Requires=docker.service
    Requires=apache-discovery@%i.service
    
    # Dependency ordering
    After=etcd.service
    After=docker.service
    Before=apache-discovery@%i.service
    
    [Service]
    # Let processes take awhile to start up (for first run Docker containers)
    TimeoutStartSec=0
    
    # Change killmode from "control-group" to "none" to let Docker remove
    # work correctly.
    KillMode=none
    
    # Get CoreOS environmental variables
    EnvironmentFile=/etc/environment
    
    # Pre-start and Start
    ## Directives with "=-" are allowed to fail without consequence
    ExecStartPre=-/usr/bin/docker kill apache.%i
    ExecStartPre=-/usr/bin/docker rm apache.%i
    ExecStartPre=/usr/bin/docker pull user_name/apache
    ExecStart=/usr/bin/docker run --name apache.%i -p ${COREOS_PRIVATE_IPV4}:%i:80 \
    user_name/apache /usr/sbin/apache2ctl -D FOREGROUND
    
    # Stop
    ExecStop=/usr/bin/docker stop apache.%i
    
    [X-Fleet]
    # Don't schedule on the same machine as other Apache instances
    Conflicts=apache@*.service

One modification we have made here is to use the private interface instead of the public interface. Since all of our Apache instances will be passed traffic _through_ the Nginx reverse proxy instead of handling connections from the open web, this is a good idea. Remember, if you use the private interface on DigitalOcean, the server that you spun up must have had the “private networking” flag selected upon creation.

Also, remember to change the `user_name` to reference your Docker Hub username in order to pull down the Docker file correctly.

### Creating the Sidekick Template Unit File

Now, we will do the same for the sidekick service. This one we will modify slightly in anticipation of the information we will need later.

Open the template file in your editor:

    vim templates/apache-discovery@.service

We will be using the following information in this file:

    [Unit]
    Description=Apache web server on port %i etcd registration
    
    # Requirements
    Requires=etcd.service
    Requires=apache@%i.service
    
    # Dependency ordering and binding
    After=etcd.service
    After=apache@%i.service
    BindsTo=apache@%i.service
    
    [Service]
    
    # Get CoreOS environmental variables
    EnvironmentFile=/etc/environment
    
    # Start
    ## Test whether service is accessible and then register useful information
    ExecStart=/bin/bash -c '\
      while true; do \
        curl -f ${COREOS_PRIVATE_IPV4}:%i; \
        if [$? -eq 0]; then \
          etcdctl set /services/apache/${COREOS_PRIVATE_IPV4} \'${COREOS_PRIVATE_IPV4}:%i\' --ttl 30; \
        else \
          etcdctl rm /services/apache/${COREOS_PRIVATE_IPV4}; \
        fi; \
        sleep 20; \
      done'
    
    # Stop
    ExecStop=/usr/bin/etcdctl rm /services/apache/${COREOS_PRIVATE_IPV4}
    
    [X-Fleet]
    # Schedule on the same machine as the associated Apache service
    MachineOf=apache@%i.service

The above configuration is different in a few ways from the one in the previous guide. We have adjusted the value set by the `etcdctl set` command. Instead of passing a JSON object, we are setting a simple IP address + port combination. This way, we can read this value directly to find the connection information necessary to get to this service.

We have also adjusted the information to specify the private interface as we did in our other file. Leave this as public if you don’t have this option available to you.

### Instantiate your Services

Now, let’s create two instances of these services.

First, let’s create the symbolic links. Move to the `~/instances` directory you created and link to define the ports that they will be running on. We want to run one service on port 7777, and another at port 8888:

    cd ~/instances
    ln -s ../templates/apache@.service apache@7777.service
    ln -s ../templates/apache@.service apache@8888.service
    ln -s ../templates/apache-discovery@.service apache-discovery@7777.service
    ln -s ../templates/apache-discovery@.service apache-discovery@8888.service

Now, we can start these services by passing the `~/instances` directory to `fleet`:

    fleetctl start ~/instances/*

After your instances start up (this could take a few minutes), you should be able to see the `etcd` entries that your sidekicks made:

    etcdctl ls --recursive /

    /coreos.com
    /coreos.com/updateengine
    /coreos.com/updateengine/rebootlock
    /coreos.com/updateengine/rebootlock/semaphore
    /services
    /services/apache
    /services/apache/10.132.249.206
    /services/apache/10.132.249.212

If you ask for the value of one of these entries, you can see that you get an IP address and a port number:

    etcdctl get /services/apache/10.132.249.206

    10.132.249.206:8888

You can use `curl` to retrieve the page and make sure it’s functioning correctly. This will only work from within your machine if you configured the service to use private networking:

    curl 10.132.249.206:8888

    <h1>Running from Docker on CoreOS</h1>

We now have our backend infrastructure set up. Our next step is to get familiar with `confd` so that we can watch the `/services/apache` location in `etcd` for changes and reconfigure Nginx each time.

## Creating the Nginx Container

We will start the Nginx container from the same Ubuntu 14.04 base that we used for the Apache services.

### Installing the Software

Start up a new container by typing:

    docker run -i -t ubuntu:14.04 /bin/bash

Update your local `apt` package cache and install Nginx. We also need to install `curl` since the base image does not include this and we need it to get the stable `confd` package from GitHub momentarily:

    apt-get update
    apt-get install nginx curl -y

Now, we can go to the [releases page](https://github.com/kelseyhightower/confd/releases) for `confd` on GitHub in our browsers. We need to find the link to the latest stable release. At the time of this writing, that is [v0.5.0](https://github.com/kelseyhightower/confd/releases/tag/v0.5.0), but this may have changed. Right-click on the link for the Linux version of the tool and select “copy link address” or whatever similar option is available.

Now, back in your Docker container, use the copied URL to download the application. We will be putting this in the `/usr/local/bin` directory. We need to choose `confd` as the output file:

    cd /usr/local/bin
    curl -L https://github.com/kelseyhightower/confd/releases/download/v0.5.0/confd-0.5.0<^>-linux-amd64 -o confd

Now, make the file executable so that we can use it within our container:

    chmod +x confd

We should also take this opportunity to create the configuration structure that `confd` expects. This will be within the `/etc` directory:

    mkdir -p /etc/confd/{conf.d,templates}

### Create a Confd Configuration File to Read Etcd Values

Now that we have our applications installed, we should begin to configure `confd`. We will start by creating a configuration file, or template resource file.

Configuration files in `confd` are used to set up the service to check certain `etcd` values and initiate actions when changes are detected. These use the [TOML](https://github.com/toml-lang/toml) file format, which is easy to use and fairly intuitive.

Begin by creating a file within within our configuration directory called `nginx.toml`:

    vi /etc/confd/conf.d/nginx.toml

We will build out our configuration file within here. Add the following information:

    [template]
    
    # The name of the template that will be used to render the application's configuration file
    # Confd will look in `/etc/conf.d/templates` for these files by default
    src = "nginx.tmpl"
    
    # The location to place the rendered configuration file
    dest = "/etc/nginx/sites-enabled/app.conf"
    
    # The etcd keys or directory to watch. This is where the information to fill in
    # the template will come from.
    keys = ["/services/apache"]
    
    # File ownership and mode information
    owner = "root"
    mode = "0644"
    
    # These are the commands that will be used to check whether the rendered config is
    # valid and to reload the actual service once the new config is in place
    check_cmd = "/usr/sbin/nginx -t"
    reload_cmd = "/usr/sbin/service nginx reload"

The above file has comments explaining some of the basic ideas, but we can go over the options you have below:

| Directive | Required? | Type | Description |
| --- | --- | --- | --- |
| src | Yes | String | The name of the template that will be used to render the information. If this is located outside of `/etc/confd/templates`, the entire path is should be used. |
| dest | Yes | String | The file location where the rendered configuration file should be placed. |
| keys | Yes | Array of strings | The `etcd` keys that the template requires to be rendered correctly. This can be a directory if the template is set up to handle child keys. |
| owner | No | String | The username that will be given ownership of the rendered configuration file. |
| group | No | String | The group that will be given group ownership of the rendered configuration file. |
| mode | No | String | The octal permissions mode that should be set for the rendered file. |
| check\_cmd | No | String | The command that should be used to check the syntax of the rendered configuration file. |
| reload\_cmd | No | String | The command that should be used to reload the configuration of the application. |
| prefix | No | String | A part of the `etcd` hierarchy that comes before the keys in the `keys` directive. This can be used to make the `.toml` file more flexible. |

The file that we created tells us a few important things about how our `confd` instance will function. Our Nginx container will use a template stored at `/etc/confd/templates/nginx.conf.tmpl` to render a configuration file that will be placed at `/etc/nginx/sites-enabled/app.conf`. The file will be given a permission set of `0644` and ownership will be given to the root user.

The `confd` application will look for changes at the `/services/apache` node. When a change is seen, `confd` will query for the new information under that node. It will then render a new configuration for Nginx. It will check the configuration file for syntax errors and reload the Nginx service after the file is in place.

We now have our template resource file created. We should work on the actual template file that will be used to render our Nginx configuration file.

### Create a Confd Template File

For our template file, we will use an example from the `confd` project’s [GitHub documentation](https://github.com/kelseyhightower/confd/blob/master/docs/templates-interation-example.md) to get us started.

Create the file that we referenced in our configuration file above. Put this file in our `templates` directory:

    vi /etc/confd/templates/nginx.tmpl

In this file, we basically just re-create a standard Nginx reverse proxy configuration file. However we will be using some Go templating syntax to substitute some of the information that `confd` is pulling from `etcd`.

First, we configure the block with the “upstream” servers. This section is used to define the pool of servers that Nginx can send requests to. The format is generally like this:

    upstream pool_name {
        server server_1_IP:port_num;
        server server_2_IP:port_num;
        server server_3_IP:port_num;
    }

This allows us to pass requests to the `pool_name` and Nginx will select one of the defined servers to hand the request to.

The idea behind our template file is to parse `etcd` for the IP addresses and port numbers of our Apache web servers. So instead of statically defining our upstream servers, we should dynamically fill this information in when the file is rendered. We can do this by using [Go templates](http://golang.org/pkg/text/template/) for the dynamic content.

To do this, we will instead use this as our block:

    upstream apache_pool {
    {{ range getvs "/services/apache/*" }}
        server {{ . }};
    {{ end }}
    }

Let’s explain for a moment what’s going on. We have opened a block to define an upstream pool of servers called `apache_pool`. Inside, we specify that we are beginning some Go language code by using the double brackets.

Within these brackets, we specify the `etcd` endpoint where the values we are interested in are held. We are using a `range` to make the list iterable.

We use this to pass all of the entries retrieved from below the `/services/apache` location in `etcd` into the `range` block. We can then get the value of the key in the current iteration using a single dot within the “{{” and “}}” that indicate an inserted value. We use this within the range loop to populate the server pool. Finally, we end the loop with the `{{ end }}` directive.

**Note** : Remember to add the semicolon after the `server` directive within the loop. Forgetting this will result in a non-working configuration.

After setting up the server pool, we can just use a proxy pass to direct all connections into that pool. This will just be a standard server block as a reverse proxy. The one thing to note is the `access_log`, which uses a custom format that we will be creating momentarily:

    upstream apache_pool {
    {{ range getvs "/services/apache/*" }}
        server {{ . }};
    {{ end }}
    }
    
    server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
    
        access_log /var/log/nginx/access.log upstreamlog;
    
        location / {
            proxy_pass http://apache_pool;
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

This will respond to all connections on port 80 and pass them to the pool of servers at `apache_pool` that is generated by looking at the `etcd` entries.

While we are dealing with this aspect of the service, we should remove the default Nginx configuration file so that we do not run into conflicts later on. We will just remove the symbolic link enabling the default config:

    rm /etc/nginx/sites-enabled/default

Now is also a good time to configure the log format that we referenced in our template file. This must go in the `http` block of the configuration, which is available in the main configuration file. Open that now:

    vi /etc/nginx/nginx.conf

We will add a `log_format` directive to define the information we want to log. It will log the client that is visiting, as well as the backend server that the request is passed to. We will log some data about the amount of time these procedures take:

    . . .
    http {
        ##
        # Basic Settings
        ##
        log_format upstreamlog '[$time_local] $remote_addr passed to: $upstream_addr: $request Upstream Response Time: $upstream_response_time Request time: $request_time';
    
        sendfile on;
        . . .

Save and close the file when you are finished.

### Creating a Script to Run Confd

We need to create a script file that will call `confd` with our template resource file and our template file at the appropriate times.

The script must do two things for our service to work correctly:

- It must run when the container launches to set up the initial Nginx settings based on the current state of the backend infrastructure.
- It must continue to watch for changes to the `etcd` registration for the Apache servers so that it can reconfigure Nginx based on the backend servers available.

We will get our script from [Marcel de Graaf’s GitHub page](https://github.com/marceldegraaf/blog-coreos-1/blob/master/nginx/boot.sh). This is a nice, simple script that does _exactly_ what we need. We will only make a few minor edits for our scenario.

Let’s place this script alongside our `confd` executable. We will call this `confd-watch`:

    vi /usr/local/bin/confd-watch

We will start off with the conventional `bash` header to identify the interpreter we need. We then will set some `bash` options so that the script fails immediately if anything goes wrong. It will return the value of the last command to fail or run.

    #!/bin/bash
    
    set -eo pipefail

Next, we want to set up some variables. By using `bash` parameter substitution, we will set default values, but build in some flexibility to let us override the hard-coded values when calling the script. This will basically just set up each component of the connection address independently and then group them together to get the full address needed.

The parameter substitution is created with this syntax: `${var_name:-default_value}`. This has the property of using the value of `var_name` if it is given and not null, otherwise defaulting to the `default_value`.

We are defaulting to the values that `etcd` expects by default. This will allow our script to function well without additional information, but we can customize as necessary when calling the script:

    #!/bin/bash
    
    set -eo pipefail
    
    export ETCD_PORT=${ETCD_PORT:-4001}
    export HOST_IP=${HOST_IP:-172.17.42.1}
    export ETCD=$HOST_IP:$ETCD_PORT

We will now use `confd` to render an initial version of the Nginx configuration file by reading the values from `etcd` that are available when this script is called. We will use an `until` loop to continuously try to build the initial configuration.

The looping construct can be necessary in case `etcd` is not available right away or in the event that the Nginx container is brought online before the backend servers. This allows it to poll `etcd` repeatedly until it can finally produce a valid initial configuration.

The actual `confd` command we are calling executes once and then exits. This is so we can wait 5 seconds until the next run to give our backend servers a chance to register. We connect to the full `ETCD` variable that we built using the defaults or passed in parameters, and we use the template resources file to define the behavior of what we want to do:

    #!/bin/bash
    
    set -eo pipefail
    
    export ETCD_PORT=${ETCD_PORT:-4001}
    export HOST_IP=${HOST_IP:-172.17.42.1}
    export ETCD=$HOST_IP:$ETCD_PORT
    
    echo "[nginx] booting container. ETCD: $ETCD"
    
    # Try to make initial configuration every 5 seconds until successful
    until confd -onetime -node $ETCD -config-file /etc/confd/conf.d/nginx.toml; do
        echo "[nginx] waiting for confd to create initial nginx configuration"
        sleep 5
    done

After the initial configuration has been set, the next task of our script should be to put into place a mechanism for continual polling. We want to make sure any future changes are detected so that Nginx will be updated.

To do this, we can call `confd` once more. This time, we want to set a continuous polling interval and place the process in the background so that it will run indefinitely. We will pass in the same `etcd` connection information and the same template resources file since our goal is still the same.

After putting the `confd` process into the background, we can safely start Nginx using the configuration file that was made. Since this script will be called as our Docker “run” command, we need to keep it running in the foreground so that the container doesn’t exit at this point. We can do this by just tailing the logs, giving us access to all of the information we have been logging:

    #!/bin/bash
    
    set -eo pipefail
    
    export ETCD_PORT=${ETCD_PORT:-4001}
    export HOST_IP=${HOST_IP:-172.17.42.1}
    export ETCD=$HOST_IP:$ETCD_PORT
    
    echo "[nginx] booting container. ETCD: $ETCD."
    
    # Try to make initial configuration every 5 seconds until successful
    until confd -onetime -node $ETCD -config-file /etc/confd/conf.d/nginx.toml; do
        echo "[nginx] waiting for confd to create initial nginx configuration."
        sleep 5
    done
    
    # Put a continual polling `confd` process into the background to watch
    # for changes every 10 seconds
    confd -interval 10 -node $ETCD -config-file /etc/confd/conf.d/nginx.toml &
    echo "[nginx] confd is now monitoring etcd for changes..."
    
    # Start the Nginx service using the generated config
    echo "[nginx] starting nginx service..."
    service nginx start
    
    # Follow the logs to allow the script to continue running
    tail -f /var/log/nginx/*.log

When you are finished with this, save and close the file.

The last thing we need to do is make the script executable:

    chmod +x /usr/local/bin/confd-watch

Exit the container now to get back to the host system:

    exit

### Commit and Push the Container

Now, we can commit the container and push it up to Docker Hub so that it is available to our machines to pull down.

Find out the container ID:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    de4f30617499 ubuntu:14.04 "/bin/bash" 22 hours ago Exited (0) About a minute ago stupefied_albattani

The highlighted string is the container ID we need. Commit the container using this ID along with your Docker Hub username and the name you would like to use for this image. We are going to use the name “nginx\_lb” in this guide:

    docker commit de4f30617499 user_name/nginx_lb

Log in to your Docker Hub account if necessary:

    docker login

Now, you should push up your committed image so that your other hosts can pull it down as necessary:

    docker push user_name/nginx_lb

## Build the Nginx Static Unit File

The next step is to build a unit file that will start up the container we just created. This will let us use `fleet` to control the process.

Since this is not going to be a template, we will put it into the `~/static` directory we created at the beginning of this directory:

    vim static/nginx_lb.service

We will start off with the standard `[Unit]` section to describe the service and define the dependencies and ordering:

    [Unit]
    Description=Nginx load balancer for web server backends
    
    # Requirements
    Requires=etcd.service
    Requires=docker.service
    
    # Dependency ordering
    After=etcd.service
    After=docker.service

Next, we need to define the `[Service]` portion of the file. We will set the timeout to zero and adjust the killmode to none again, just as we did with the Apache service files. We will pull in the environment file again so that we can get access to the public and private IP addresses of the host this container is running on.

We will then clean up our environment to make sure any previous versions of this container are killed and removed. We pull down the container we just created to make sure we always have the most recent version.

Finally, we will start the container. This involves starting the container, giving it the name we referenced in the remove and kill commands, and passing it the public IP address of the host it is running on to map port 80. We call the `confd-watch` script we wrote as the run command.

    [Unit]
    Description=Nginx load balancer for web server backends
    
    # Requirements
    Requires=etcd.service
    Requires=docker.service
    
    # Dependency ordering
    After=etcd.service
    After=docker.service
    
    [Service]
    # Let the process take awhile to start up (for first run Docker containers)
    TimeoutStartSec=0
    
    # Change killmode from "control-group" to "none" to let Docker remove
    # work correctly.
    KillMode=none
    
    # Get CoreOS environmental variables
    EnvironmentFile=/etc/environment
    
    # Pre-start and Start
    ## Directives with "=-" are allowed to fail without consequence
    ExecStartPre=-/usr/bin/docker kill nginx_lb
    ExecStartPre=-/usr/bin/docker rm nginx_lb
    ExecStartPre=/usr/bin/docker pull user_name/nginx_lb
    ExecStart=/usr/bin/docker run --name nginx_lb -p ${COREOS_PUBLIC_IPV4}:80:80 \
    user_name/nginx_lb /usr/local/bin/confd-watch

Now, all we need to sort out is the stopping command and the `fleet` scheduling directions. We want this container to be initiated only on hosts that are not running other load balancing instances or backend Apache servers. This will allow our service to spread the load effectively:

    [Unit]
    Description=Nginx load balancer for web server backends
    
    # Requirements
    Requires=etcd.service
    Requires=docker.service
    
    # Dependency ordering
    After=etcd.service
    After=docker.service
    
    [Service]
    # Let the process take awhile to start up (for first run Docker containers)
    TimeoutStartSec=0
    
    # Change killmode from "control-group" to "none" to let Docker remove
    # work correctly.
    KillMode=none
    
    # Get CoreOS environmental variables
    EnvironmentFile=/etc/environment
    
    # Pre-start and Start
    ## Directives with "=-" are allowed to fail without consequence
    ExecStartPre=-/usr/bin/docker kill nginx_lb
    ExecStartPre=-/usr/bin/docker rm nginx_lb
    ExecStartPre=/usr/bin/docker pull user_name/nginx_lb
    ExecStart=/usr/bin/docker run --name nginx_lb -p ${COREOS_PUBLIC_IPV4}:80:80 \
    user_name/nginx_lb /usr/local/bin/confd-watch
    
    # Stop
    ExecStop=/usr/bin/docker stop nginx_lb
    
    [X-Fleet]
    Conflicts=nginx.service
    Conflicts=apache@*.service

Save and close the file when you are finished.

## Running the Nginx Load Balancer

You should already have two Apache instances running from earlier in the tutorial. You can check by typing:

    fleetctl list-units

    UNIT MACHINE ACTIVE SUB
    apache-discovery@7777.service 197a1662.../10.132.249.206 active running
    apache-discovery@8888.service 04856ec4.../10.132.249.212 active running
    apache@7777.service 197a1662.../10.132.249.206 active running
    apache@8888.service 04856ec4.../10.132.249.212 active running

You can also double check that they are correctly registering themselves with `etcd` by typing:

    etcdctl ls --recursive /services/apache

    /services/apache/10.132.249.206
    /services/apache/10.132.249.212

We can now attempt to start up our Nginx service:

    fleetctl start ~/static/nginx_lb.service

    Unit nginx_lb.service launched on 96ec72cf.../10.132.248.177

It may take a minute or so for the service to start, depending on how long it takes the image to be pulled down. After it is started, if you check the logs with the `fleetctl journal` command, you should be able to see some log information from `confd`. It should look something like this:

    fleetctl journal nginx_lb.service

    -- Logs begin at Mon 2014-09-15 14:54:05 UTC, end at Tue 2014-09-16 17:13:58 UTC. --
    Sep 16 17:13:48 lala1 docker[15379]: 2014-09-16T17:13:48Z d7974a70e976 confd[14]: INFO Target config /etc/nginx/sites-enabled/app.conf out of sync
    Sep 16 17:13:48 lala1 docker[15379]: 2014-09-16T17:13:48Z d7974a70e976 confd[14]: INFO Target config /etc/nginx/sites-enabled/app.conf has been updated
    Sep 16 17:13:48 lala1 docker[15379]: [nginx] confd is monitoring etcd for changes...
    Sep 16 17:13:48 lala1 docker[15379]: [nginx] starting nginx service...
    Sep 16 17:13:48 lala1 docker[15379]: 2014-09-16T17:13:48Z d7974a70e976 confd[33]: INFO Target config /etc/nginx/sites-enabled/app.conf in sync
    Sep 16 17:13:48 lala1 docker[15379]: ==> /var/log/nginx/access.log <==
    Sep 16 17:13:48 lala1 docker[15379]: ==> /var/log/nginx/error.log <==
    Sep 16 17:13:58 lala1 docker[15379]: 2014-09-16T17:13:58Z d7974a70e976 confd[33]: INFO /etc/nginx/sites-enabled/app.conf has md5sum a8517bfe0348e9215aa694f0b4b36c9b should be 33f42e3b7cc418f504237bea36c8a03e
    Sep 16 17:13:58 lala1 docker[15379]: 2014-09-16T17:13:58Z d7974a70e976 confd[33]: INFO Target config /etc/nginx/sites-enabled/app.conf out of sync
    Sep 16 17:13:58 lala1 docker[15379]: 2014-09-16T17:13:58Z d7974a70e976 confd[33]: INFO Target config /etc/nginx/sites-enabled/app.conf has been updated

As you can see, `confd` looked to `etcd` for its initial configuration. It then started `nginx`. Afterwards, we can see lines where the `etcd` entries have been re-evaluated and a new configuration file made. If the newly generated file does not match the `md5sum` of the file in place, the file is switched out and the service is reloaded.

This allows our load balancing service to ultimately track our Apache backend servers. If `confd` seems to be continuously updating, it may be because your Apache instances are refreshing their TTL too often. You can increase the sleep and TTL values in the sidekick template to avoid this.

To see the load balancer in action, you can ask for the `/etc/environments` file from the host that is running the Nginx service. This contains the host’s public IP address. If you want to make this configuration better, consider running a sidekick service that registers this information with `etcd`, just as we did for the Apache instances:

    fleetctl ssh nginx_lb cat /etc/environment

    COREOS_PRIVATE_IPV4=10.132.248.177
    COREOS_PUBLIC_IPV4=104.131.16.222

Now, if we go to the public IPv4 address in our browser, we should see the page that we configured in our Apache instances:

![Apache index page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/coreos_confd/apache_index.png)

Now, if you look at your logs again, you should be able to see information indicating which backend server was actually passed the request:

    fleetctl journal nginx_lb

    . . .
    Sep 16 18:04:38 lala1 docker[18079]: 2014-09-16T18:04:38Z 51c74658196c confd[28]: INFO Target config /etc/nginx/sites-enabled/app.conf in sync
    Sep 16 18:04:48 lala1 docker[18079]: 2014-09-16T18:04:48Z 51c74658196c confd[28]: INFO Target config /etc/nginx/sites-enabled/app.conf in sync
    Sep 16 18:04:48 lala1 docker[18079]: [16/Sep/2014:18:04:48 +0000] 108.29.37.206 passed to: 10.132.249.212:8888: GET / HTTP/1.1 Upstream Response Time: 0.003 Request time: 0.003

## Conclusion

As you can see, it is possible to set up your services to check `etcd` for configuration details. Tools like `confd` can make this process relatively simple by allowing for continuous polling of significant entries.

In the example in this guide, we configured our Nginx service to use `etcd` to generate its initial configuration. We also set it up in the background to continuously check for changes. This, combined with the dynamic configuration generation based on templates allowed us to consistently have an up-to-date picture of our backend servers.
