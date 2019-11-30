---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/saltstack-infrastructure-creating-salt-states-for-nginx-web-servers
---

# SaltStack Infrastructure: Creating Salt States for Nginx Web Servers

## Introduction

SaltStack, or Salt, is a powerful remote execution and configuration management system that can be used to easily manage infrastructure in a structured, repeatable way. In this series, we will be demonstrating one method of managing your development, staging, and production environments from a Salt deployment. We will use the Salt state system to write and apply repeatable actions. This will allow us to destroy any of our environments, safe in the knowledge that we can easily bring them back online in an identical state at a later time.

In our [previous guide](saltstack-infrastructure-configuring-salt-cloud-to-spin-up-digitalocean-resources), we expanded our Salt master server’s capabilities by setting up the DigitalOcean provider for `salt-cloud`. We created the files needed to allow us to spin up fresh servers for each of our environments. In this article, we will begin to dive into configuration management by creating Salt state files for Nginx. Nginx will be used on our web server nodes in all three environments in order to handle web requests.

## Create the Main Nginx State File

Salt handles configuration management through its state system. In the simplest case, these are controlled by files located within Salt’s file server root (which we configured as `/srv/salt`). To start off our Nginx configuration, we’ll create a directory in this location specific to the software we are configuring:

    sudo mkdir /srv/salt/nginx

State files have an `.sls` suffix. An `init.sls` file within a directory functions as the main configuration file for that specific Salt state or formula. We refer to the parent directory name to execute the functionality contained within the associated `init.sls` file.

With that in mind, create and open an `init.sls` file within this directory to get started:

    sudo nano /srv/salt/nginx/init.sls

### The Nginx Package and Service States

We will start by creating a state using the `nginx` identifier. This will serve as the unique name for this particular state within the Salt state system. Since we won’t be including the “name” attribute for our state modules, it will also serve as the target to be installed (for the `pkg.installed` function) and the service to be running (for the `service.running` function).

We want Nginx to automatically reload under certain conditions: when the package is updated, when the main configuration file has been changed, or when the default server block file is modified. We can tell Salt to restart the Nginx service when these conditions occur by using `watch`:

/srv/salt/nginx/init.sls

    nginx:
      pkg:
        - installed
      service.running:
        - watch:
          - pkg: nginx
          - file: /etc/nginx/nginx.conf
          - file: /etc/nginx/sites-available/default

The `pkg:` and `file:` keys beneath the `watch:` key represent the state modules associated with the resources to watch. The `pkg` resource is taken care of within the first part of this same definition. We will have to create the states to match the `file` resources next.

### The Nginx Configuration File States

We can start with the `/etc/nginx/nginx.conf` file. We would like to make this a managed file. In Salt terminology, this just means that we will define the contents of the file on the master server and upload it to each minion who needs it. We will set rather typical permissions and ownership on the file. The source references a location within the Salt file server (our current file is within this structure as well). We will be creating this path and file momentarily:

/srv/salt/nginx/init.sls

    nginx:
      pkg:
        - installed
      service.running:
        - watch:
          - pkg: nginx
          - file: /etc/nginx/nginx.conf
          - file: /etc/nginx/sites-available/default
    
    /etc/nginx/nginx.conf:
      file.managed:
        - source: salt://nginx/files/etc/nginx/nginx.conf
        - user: root
        - group: root
        - mode: 640

We also want to control the contents of the `/etc/nginx/sites-available/default` file. This defines the server block that controls how our content will be served. The state block is fairly similar to the last one. The major difference is that this file will be a Jinja template.

Jinja templates allow Salt to customize some of the contents of the file with details specific to each of the minions where it will be placed. This means that we can pull information from each host and construct an appropriate, customized version of the file for each of our web servers. We indicate that this file will use Jinja with the `template` option. We also will use the `.jinja` suffix on the source file so that we can tell at a glance that the file is a template:

/srv/salt/nginx/init.sls

    . . .
    
    /etc/nginx/nginx.conf:
      file.managed:
        - source: salt://nginx/files/etc/nginx/nginx.conf
        - user: root
        - group: root
        - mode: 640
    
    /etc/nginx/sites-available/default:
      file.managed:
        - source: salt://nginx/files/etc/nginx/sites-available/default.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 640

We have our default server block file slated to be placed in the `sites-available` directory on the minion hosts. However, we still need to link the file to the `sites-enabled` directory to activate it. We can do that with the `file.symlink` function. We just need to provide the original file location as the `target`. We also need to “require” that file so that this state is only executed after the previous state has completed successfully:

/srv/salt/nginx/init.sls

    . . .
    
    /etc/nginx/sites-available/default:
      file.managed:
        - source: salt://nginx/files/etc/nginx/sites-available/default.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 640
    
    /etc/nginx/sites-enabled/default:
      file.symlink:
        - target: /etc/nginx/sites-available/default
        - require:
          - file: /etc/nginx/sites-available/default

### The State for Our Default Site Content

We have our Nginx installation and configuration states written. Now, we just need to create a state for our `index.html` file which will be the actual content for our site.

This state uses the exact same format as our previous template state. The only differences are the identifier, the source, and the permissions mode on this file:

/srv/salt/nginx/init.sls

    . . .
    
    /etc/nginx/sites-enabled/default:
      file.symlink:
        - target: /etc/nginx/sites-available/default
        - require:
          - file: /etc/nginx/sites-available/default
    
    /usr/share/nginx/html/index.html:
      file.managed:
        - source: salt://nginx/files/usr/share/nginx/html/index.html.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644

When you are finished, save and close this file. We are done with the actual Nginx state information for the moment.

## Install Nginx and Transfer Original Files to the Salt Master

We have our main Nginx Salt state file created. However, some of the states we created references files on the Salt master’s file server that do not exist yet.

Since our files will be largely the same as the default files installed by Ubuntu’s Nginx package, the easiest way for us to start is with the files from that package. The web servers from one of our environments offer a perfect place to install Nginx so that we can grab the necessary files.

If you do not already have one of your environments spun up, select one of your environment map files to deploy. We will use the “stage” environment in this series because it is the smallest environment that has all of the server types we’ll need.

    sudo salt-cloud -P -m /etc/salt/cloud.maps.d/stage-environment.map

Once your servers are up and running, choose one of your web servers to install Nginx onto. We are just going to use the `pkg` execution module at this time, since our states are not fully functional yet:

    sudo salt stage-www1 pkg.install nginx

When we set up our Salt master configuration, we enabled the `file_recv` option. This allows us to request minions to push certain files back up to the master. We can use this to grab the default versions of the files we’ll be managing:

    sudo salt stage-www1 cp.push /etc/nginx/nginx.conf
    sudo salt stage-www1 cp.push /etc/nginx/sites-available/default
    sudo salt stage-www1 cp.push /usr/share/nginx/html/index.html

These files should now be available on the master. The path to these files is recreated within the `/var/cache/salt/master/minions/minion_id/files` directory. In our case, the minion ID would be `stage-www1`. We can copy the directories beneath this location, which represents the file paths on the minion, to our Salt state directory by typing:

    sudo cp -r /var/cache/salt/master/minions/stage-www1/files /srv/salt/nginx

If you look at the contents of your state directory, you will see a new directory called “files”. Beneath this directory, the relevant directories within the minion’s filesystem and the three files we copied are available:

    find /srv/salt/nginx -printf "%P\n"

    Outputfiles
    files/usr
    files/usr/share
    files/usr/share/nginx
    files/usr/share/nginx/html
    files/usr/share/nginx/html/index.html
    files/etc
    files/etc/nginx
    files/etc/nginx/sites-available
    files/etc/nginx/sites-available/default
    files/etc/nginx/nginx.conf
    init.sls

This is where all of our managed files will be maintained. This aligns with the “source” location we set in our Nginx state file.

Since we now have all of the files we need pulled from the minion where Nginx was installed, we can destroy the minion and rebuild it. This will ensure that later on, our state files can be tested on a clean server. Destroy the Nginx minion:

    sudo salt-cloud -d stage-www1

After waiting for the event to process, we can rebuild the minion.

We typically would use the map file for this, but since we are only rebuilding a single server, it’s actually preferable to use the `stage-web` profile directly. We can then use the `cloud.profile` Salt execution function instead of `salt-cloud`, which allows us to add the `--async` flag. Basically, this lets us rebuild our `stage-www1` server in the background as we continue to work. We will have to target our Salt master in this command since this is the server with the cloud profiles we need:

    sudo salt --async sm cloud.profile stage-web stage-www1

While our `stage-www1` node is rebuilding in the background, we can continue.

## Configure the /etc/nginx/nginx.conf File

Let’s look at the main Nginx configuration file first, which will be placed at `/etc/nginx/nginx.conf` on our minions. We can find this path under the `files` directory with out Nginx state directory:

    cd /srv/salt/nginx/files/etc/nginx

We’re actually not going to modify this file at the moment, but we can do ourselves a favor and back up the original right now:

    sudo cp nginx.conf nginx.conf.orig

This will give us a good point of reference for customizations we might make in the future. We can quickly see any changes we’ve made by typing:

    diff nginx.conf nginx.conf.orig

In the future, if we find we need to customize Nginx’s configuration in our various environments (for instance, we might want to match the `worker_processes` with the number of CPUs on our production servers later on), we might want to transition to using a template file. We don’t need this at the moment so, as a non-template file, our changes will be hard-coded.

As we stated earlier though, we don’t need any modifications at this time. Let’s move on.

## Configure the /etc/nginx/sites-available/default Template

Next, let’s take a look at our default server block template. We can find the original in this directory:

    cd /srv/salt/nginx/files/etc/nginx/sites-available

Again, we should copy the original to a backup location in case we need it later:

    sudo cp default default.orig

We can then rename the file so that it has a `.jinja` extension. This will visually remind us that this file is a template and not a usable file by itself:

    sudo mv default default.jinja

Now, we can open the template file to make some changes:

    sudo nano default.jinja

At the very top of the file, we need to start utilizing Jinja’s templating features. Our default server block needs to render different files depending on whether the web server will be behind a load balancer.

When connections are being received through a load balancer, we want our web server to restrict its traffic to the private interface. When we’re in the development environment however, we do not have a load balancer, so we’ll want to serve over the public interface. We can create this distinction with Jinja.

We will create a variable called `interface` which should contain the interface we want the address of. We’ll test if the environment of the minion is set to “dev”, in which case we’ll use the `eth0` interface. Otherwise, we’ll set it to `eth1`, the server’s private interface. We’ll then use the `grains.get` execution module function to grab the address associated with the selected interface and use that as the value for the `addr` variable. We will add this to the very top of the file:

/srv/salt/nginx/files/etc/nginx/sites-available/default.jinja

    {%- set interface = 'eth0' if salt['grains.get']('env') == 'dev' else 'eth1' -%}
    {%- set addr = salt['network.interface_ip'](interface) -%}
    # You may add here your
    # server {
    # ...
    # }
    
    . . .

Next, we can edit the `server` block further down in the file. We can use the `addr` variable we set at the top in the `listen` and `server_name` directives. We’ve removed the IPv6 and default server portions to restrict what this block serves:

/srv/salt/nginx/files/etc/nginx/sites-available/default.jinja

    {%- set interface = 'eth0' if salt['grains.get']('env') == 'dev' else 'eth1' -%}
    {%- set addr = salt['network.interface_ip'](interface) -%}
    
    . . .
    
    server {
        listen {{ addr }}:80;
    
        root /usr/share/nginx/html;
        index index.html index.htm;
    
        server_name {{ addr }};
    
        location / {
            try_files $uri $uri/ =404;
        }
    }

Save and close the file when you are finished.

## Configure the /usr/share/nginx/html/index.html Template

We can now move on to the `index.html` file. Move over to the directory on the Salt master that contains the file:

    cd /srv/salt/nginx/files/usr/share/nginx/html

Inside, we’ll need to start with the same procedure that we used last time. We should store a copy of the original file for auditing and backup purposes. We should then rename the file to indicate that this will be a template:

    sudo cp index.html index.html.orig
    sudo mv index.html index.html.jinja

Open up the template file so we can make the modifications we need:

    sudo nano index.html.jinja

At the top, we’ll set another variable using Jinja. We’ll use the `grains.get` execution module function to grab the minion’s hostname. We’ll store this in the `host` variable:

    {% set host = salt['grains.get']('host') -%}
    <!DOCTYPE html>
    <html>
    
    . . .

We’ll then use this value throughout the file so that we can easily tell which web server is serving our requests. Change the `<title>` value first:

    {% set host = salt['grains.get']('host') -%}
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome from {{ host }}</title>
    . . .

Let’s change the body text to this:

    . . .
    
    <body>
    <h1>Welcome to nginx!</h1>
    <p>Hello! This is being served from:</p>
    
    <h2>{{ host }}</h2>
    
    </body>
    </html>

Save and close the file when you are finished.

## Testing the Nginx State File

We’ve now completed our Nginx configuration. We can test certain aspects of the state in order to ensure that it works properly.

First, we can use the `state.show_sls` execution module function to view how Salt will interpret our Nginx state file. We can use our `stage-www1` server as the target. Nothing will execute on the server at this point though:

    sudo salt stage-www1 state.show_sls nginx

You should get back output that looks something like this:

    Outputstage-www1:
        ----------
        /etc/nginx/nginx.conf:
            ----------
            __env__ :
                base
            __sls__ :
                nginx
            file:
                |_
                  ----------
                  source:
                      salt://nginx/files/etc/nginx/nginx.conf
                |_
                  ----------
                  user:
                      root
                |_
                  ----------
                  group:
                      root
                |_
                  ----------
                  mode:
                      640
                - managed
                |_
                  ----------
                  order:
                      10002
    
    . . .

It mainly renders the information from our `/srv/salt/nginx/init.sls` file with some interesting additions. Check that there are no interpretation errors where Salt did not know how to read commands. The “order” of each piece is another good item to check. This determines when each of the individual states in the file will run. The first state will have the order number “10000”. Every additional state will count up from there. Note that the ` __env__ ` is different than the `env` we set using grains. We are not using Salt’s conception of environments in this guide.

Next, we can do a dry-run of applying our state file. We can do this with the `state.apply` function with the `test=True` option. The command looks like this:

    sudo salt stage-www1 state.apply nginx test=True

This will show you the changes that will be made if the `test=True` option is removed. Take a look to make sure that the changes make sense and that Salt is able to interpret all of your files correctly. The “Comment” field is particularly important as it can reveal issues even in cases where Salt did not mark the state as failed.

If the dry-run did not reveal any problems, you can try to apply the state to all of your available web servers by typing:

    sudo salt -G 'role:webserver' state.apply nginx

If you applied the Nginx state to your staging or production web servers, you’ll want to get their internal IP addresses. The pages will not be available over the public interface:

    sudo salt-call mine.get 'role:webserver' internal_ip expr_form=grain

    Outputlocal:
        ----------
        stage-www1:
            ip_address
        stage-www2:
            ip_address

If, on the other hand, you spun up your development web server and applied the Nginx state, you’ll want to grab the external address since:

    sudo salt-call mine.get 'role:webserver' external_ip expr_form=grain

You can test your servers using `curl`:

    curl ip_address

You should see the `index.html` page we modified:

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome from stage-www1</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>Hello! This is being served from:</p>
    
    <h2>stage-www1</h2>
    
    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>

As you can see, the minion’s host name was placed in the file when the Jinja was rendered. Our Nginx state is now complete.

## Conclusion

You should now have a fully functional Nginx state. This will allow you to turn any Salt-controlled machine into a web server with your specifications quickly and easily. We will use this as a part of our larger infrastructure management strategy to easily construct the web servers in our environments.

In the [next guide](saltstack-infrastructure-creating-salt-states-for-haproxy-load-balancers), we will move ahead and construct the state for the load balancers that will direct traffic in front of our web servers. We will use some of the same techniques that we used in this guide to make our load balancers flexible.
