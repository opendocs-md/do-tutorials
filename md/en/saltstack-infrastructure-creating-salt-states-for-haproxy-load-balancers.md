---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/saltstack-infrastructure-creating-salt-states-for-haproxy-load-balancers
---

# SaltStack Infrastructure: Creating Salt States for HAProxy Load Balancers

## Introduction

SaltStack, or Salt, is a powerful remote execution and configuration management system that can be used to easily manage infrastructure in a structured, repeatable way. In this series, we will be demonstrating one method of managing your development, staging, and production environments from a Salt deployment. We will use the Salt state system to write and apply repeatable actions. This will allow us to destroy any of our environments, safe in the knowledge that we can easily bring them back online in an identical state at a later time.

In our [previous guide](saltstack-infrastructure-creating-salt-states-for-nginx-web-servers), we created a Salt state for our web servers which installed and configured Nginx. In this guide, we will configure states for the load balancer that will sit in front of our web servers in our staging and production environments. Our load balancers need to be configured with the web server addresses in order to correctly pass traffic.

Let’s get started.

## Create the Main HAProxy State File

Our load balancers will use HAProxy to spread the traffic for our application between all of the available web servers in the environment. As with the Nginx state file, we will create a directory for this state in the `/srv/salt` directory:

    sudo mkdir /srv/salt/haproxy

We will use the name `init.sls` for our main state file within this directory so that we can refer to the state by the directory name:

    sudo nano /srv/salt/haproxy/init.sls

Inside, we can use the same pattern we used for Nginx in order to install the `haproxy` package and ensure that it is running. We will make sure the service is reloaded when there are changes to the package or changes to the `/etc/default/haproxy` file file or the `/etc/haproxy/haproxy.cfg` file. Again, be very careful with spacing to avoid YAML errors:

/srv/salt/haproxy/init.sls

    haproxy:
      pkg:
        - installed
      service.running:
        - watch:
          - pkg: haproxy
          - file: /etc/haproxy/haproxy.cfg
          - file: /etc/default/haproxy

We need to manage both of the files that the `haproxy` service is watching. We can create states for each.

The `/etc/haproxy/haproxy.cfg` file will be a template. This file will need to pull information about the environment in order to populate its list of web servers to pass traffic to. Our web servers will not have the same IPs each time that they’re created. We will need to dynamically create the list each time this state is applied.

The `/etc/default/haproxy` file is just a regular file. We are managing it because we want to ensure that HAProxy is started at boot. This isn’t dynamic information though, so we do not need to make this a template:

/srv/salt/haproxy/init.sls

    haproxy:
      pkg:
        - installed
      service.running:
        - watch:
          - pkg: haproxy
          - file: /etc/haproxy/haproxy.cfg
          - file: /etc/default/haproxy
    
    /etc/haproxy/haproxy.cfg:
      file.managed:
        - source: salt://haproxy/files/etc/haproxy/haproxy.cfg.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 644
    
    /etc/default/haproxy:
      file.managed:
        - source: salt://haproxy/files/etc/default/haproxy
        - user: root
        - group: root
        - mode: 644

This is actually all we need for the state file itself. Save and close the file when you are done.

## Install HAProxy and Transfer Package Files to the Salt Master

We will use the same technique that we used with Nginx in order to get the basic HAProxy files we need. We will install the package on a minion and then tell the server to push the files back up to the master.

Let’s use the `stage-lb` server since that will be the final target for this package anyways. If you don’t already have your staging machines up and running, type:

    sudo salt-cloud -P -m /etc/salt/cloud.maps.d/stage-environment.map

Once your servers are available, you can install the `haproxy` package on the `stage-lb` server by typing:

    sudo salt stage-lb pkg.install haproxy

Once the installation is complete, we can tell the minion to push the two files we need up to the master server:

    sudo salt stage-lb cp.push /etc/default/haproxy
    sudo salt stage-lb cp.push /etc/haproxy/haproxy.cfg

The relevant portions of the minion filesystem will be recreated in the `/var/cache/salt/master/minions/minion_id/files` directory. In this case, the minion ID is `stage-lb`. Copy the entire minion file structure to our HAProxy state directory:

    sudo cp -r /var/cache/salt/master/minions/stage-lb/files /srv/salt/haproxy

We can see the file structure by typing:

    find /srv/salt/haproxy -printf "%P\n"

    Outputfiles
    files/etc
    files/etc/default
    files/etc/default/haproxy
    files/etc/haproxy
    files/etc/haproxy/haproxy.cfg
    init.sls

Now that we have the files from the minion, we can destroy the load balancing server:

    sudo salt-cloud -d stage-lb

We can then recreate the server in the background so that we have a clean slate later to do our final testing and confirmation. Target your Salt master server with this command, since it has access to the relevant cloud files:

    sudo salt --async sm cloud.profile stage-lb stage-lb

While the server is rebuilding, we can move on and make the necessary modifications to the HAProxy files we are managing.

## Configure the /etc/default/haproxy File

We can start with the `/etc/default/haproxy` file. In our HAProxy state directory on the Salt master, move to the directory that houses the default file:

    cd /srv/salt/haproxy/files/etc/default

Copy the file to `haproxy.orig` so that we can preserve the file as it was originally packaged:

    sudo cp haproxy haproxy.orig

Now, open the file for editing:

    sudo nano haproxy

Change `ENABLED` to “1”. This will tell Ubuntu’s init system, Upstart, to start the HAProxy service when the server boots:

/srv/salt/haproxy/files/etc/default/haproxy

    # Set ENABLED to 1 if you want the init script to start haproxy.
    ENABLED=1
    # Add extra flags here.
    #EXTRAOPTS="-de -m 16"

This is the only change we need to make. Save and close the file.

## Configure the /etc/haproxy/haproxy.cfg Template File

Next, let’s work on the main HAProxy configuration file. Move into the appropriate directory on the Salt master server:

    cd /srv/salt/haproxy/files/etc/haproxy

Again, let’s copy the configuration to save it’s original state:

    sudo cp haproxy.cfg haproxy.cfg.orig

Then, rename the file to reflect that this is a Jinja template file:

    sudo mv haproxy.cfg haproxy.cfg.jinja

Open the template file in your text editor:

    sudo nano haproxy.cfg.jinja

At the top of the file, we can start by setting a Jinja variable. We need to grab the environment that the load balancer is operating in using the `network.interface_ip` execution function. We will use this later to populate the server list with the web servers from the same environment:

/srv/salt/haproxy/files/etc/haproxy/haproxy.cfg.jinja

    {%- set env = salt['grains.get']('env') -%}
    global
            log /dev/log local0
            log /dev/log local1 notice
            chroot /var/lib/haproxy
            . . .

Skip down to the “defaults” section of the file. We need to change `mode` to “tcp” and the first `option` to “tcplog”:

/srv/salt/haproxy/files/etc/haproxy/haproxy.cfg.jinja

    . . .
    
    defaults
        . . .
        mode tcp
        option tcplog
        . . .

At the bottom of the file, we need to create our actual configuration. We need to create a “frontend” section, which will describe how HAProxy will accept connections. We will label this section “www”.

We want to bind this to the server’s public IP address. We can grab this using the `network.interface_ip` execution module function with the `eth0` argument. Web requests will come in at port 80. We can specify the default backend to pass to with the `default_backend` option. We will call our backend `nginx_pool`:

/srv/salt/haproxy/files/etc/haproxy/haproxy.cfg.jinja

    . . .
    
    frontend www
        bind {{ salt['network.interface_ip']('eth0') }}:80
        default_backend nginx_pool

Next, we need to add the `nginx_pool` backend. We will use the conventional round robin balancing model and set the mode to “tcp” again.

After that, we need to populate the list of backend web servers from our environment. We can do this using a “for” loop in Jinja. We can use the `mine.get` execution module function to get the value of the `internal_ip` mine function. We will match the web server role and the environment. The `~ env` will catenate the value of `env` variable we set earlier to the match string that precedes it.

The results of this lookup will be stored in the `server` and `addr` variables for each iteration of the loop. Within the loop, we will add the server’s details using these loop variables. The final result looks like this:

/srv/salt/haproxy/files/etc/haproxy/haproxy.cfg.jinja

    . . .
    
    frontend www
        bind {{ salt['network.interface_ip']('eth0') }}:80
        default_backend nginx_pool
    
    backend nginx_pool
        balance roundrobin
        mode tcp
        {% for server, addr in salt['mine.get']('G@role:webserver and G@env:' ~ env, 'internal_ip', expr_form='compound').items() -%}
        server {{ server }} {{ addr }}:80 check
        {% endfor -%}

Save and close the file when you are finished.

## Testing the HAProxy State File

Our load balancing state is fairly basic, but complete. We can now move on to testing it.

First, let’s use `state.show_sls` to display the file ordering:

    sudo salt stage-lb state.show_sls haproxy

We can tell by the sequence in the various “order” values in the output that the package will be installed, the service will be started, and then the two files will be applied. This is what we expected. The file changes will trigger a service reload due to the “watch” setting we configured.

Next, we can do a dry run of the state application. This will catch some (but not all) errors that would cause the state to fail when run:

    sudo salt stage-lb state.apply haproxy test=True

Check that all of the states would have passed. Regardless of the failure count at the bottom or the output, scroll up and look at the “Comment” line for each of the states. Sometimes, this will include extra information about potential issues, even though the test was marked as successful.

After fixing any issues that have surfaced during the test commands, you can apply your state to your load balancer servers. Make sure that you have the backend Nginx web servers running and configured prior to applying the state:

    sudo salt-cloud -P -m /etc/salt/cloud.maps.d/stage-environment.map
    sudo salt -G 'role:webserver' state.apply nginx

When your web servers are running, apply the `haproxy` state:

    sudo salt -G 'role:lbserver' state.apply haproxy

You should now be able to get to one of your two backend web servers through your load balancer’s public IP address. You can display your load balancer’s public IP address with this command:

    sudo salt -G 'role:lbserver' network.interface_ip eth0

If you use the browser, it will look something like this:

![load balancer page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/saltstack_haproxy/example_page.png)

It is easier to see the load balancer pass traffic between the backend servers with `curl`:

    curl load_balancer_public_IP

    Output<!DOCTYPE html>
    <html>
    <head>
    <title>Welcome from stage-www2</title>
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
    
    <h2>stage-www2</h2>
    
    </body>
    </html>

If you type the command again a few times, it should swap between your two servers:

    curl load_balancer_public_IP

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
    
    </body>
    </html>

As you can see, the server serving the request has changed, meaning that our load balancer is functioning correctly.

## Conclusion

At this point, we have a functioning HAProxy state that can be applied to our load balancer machines. This can be used to split the incoming traffic for our application among all of the backend Nginx servers. We can easily destroy our load balancers and then rebuild them based on the web servers available.

In the [next guide](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers), we will focus on getting MySQL up and running as our backend database system. This will be used to store application data in our various environments.
