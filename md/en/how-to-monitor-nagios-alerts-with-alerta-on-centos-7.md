---
author: Vadym Kalsin
date: 2017-09-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-monitor-nagios-alerts-with-alerta-on-centos-7
---

# How To Monitor Nagios Alerts with Alerta on CentOS 7

## Introduction

[Alerta](http://alerta.io/) is a web application used to consolidate and de-duplicate alerts from multiple monitoring systems and visualize them on a single screen. Alerta can integrate with many well-known monitoring tools like Nagios, Zabbix, Sensu, InfluxData Kapacitor, and many others.

In this tutorial you’ll set up Alerta and configure it to display notifications from [Nagios](http://nagios.org), the popular open-source monitoring system.

## Prerequisites

To follow this tutorial, you will need:

- Two CentOS 7 servers set up by following [the CentOS 7 initial server setup guide](initial-server-setup-with-centos-7), including a sudo non-root user and a firewall.
- On the first CentOS server, which is where you’ll run Nagios, install the following components:
  - Apache, MySQL, and PHP, by following the tutorial [How To Install Linux, Apache, MySQL, PHP (LAMP) stack On CentOS 7](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7).
  - Nagios 4, installed by following the tutorial [How To Install Nagios 4 and Monitor Your Servers on CentOS 7](how-to-install-nagios-4-and-monitor-your-servers-on-centos-7) and its prerequisites to configure it. 
- On the second CentOS server, which is where we’ll install Alerta in this tutorial, install the following components:
  - Nginx, installed by following the tutorial [How To Install Nginx on CentOS 7](how-to-install-nginx-on-centos-7).
  - MongoDB, installed by following the tutorial [How To Install MongoDB on CentOS 7](how-to-install-mongodb-on-centos-7).
  - Alerta, installed by following steps 1 through 6 in the tutorial [How To Monitor Zabbix Alerts with Alerta on CentOS 7](how-to-monitor-zabbix-alerts-with-alerta-on-centos-7). 

## Step 1 — Installing the Nagios-to-Alerta Event Broker Module

You can extend Nagios’ functionality with Nagios Event Broker (NEB) modules. NEB is Nagios’ event integration mechanism, and NEB modules are shared libraries that let you integrate other services with Nagios. In this step, we’ll install the [Nagios to Alerta Gateway](https://github.com/alerta/nagios-alerta), the NEB module that will send notifications to Alerta.

Log into your Nagios server as your non-root user:

    ssh sammy@your_nagios_server_ip

The Nagios to Alerta Gateway does not have preconfigured system packages, so you’ll have to build it from source. To do that, you’ll need to install some development tools and files. You’ll also need Git installed so you can fetch the source code from GitHub.

    sudo yum install -y git curl gcc make libcurl-devel

With the prerequisites installed, use Git to clone the source code from the project’s GitHub repository:

    git clone https://github.com/alerta/nagios-alerta.git

Then change to the new `nagios-alerta` directory:

    cd nagios-alerta

Then compile the `nagios-alerta` module using `make`:

    make nagios4

You’ll see the following output:

    Outputcd ./src && make nagios4
    make[1]: Entering directory `/root/nagios-alerta/src'
    gcc -fPIC -g -O2 -DHAVE_CONFIG_H -I../include -I../include/nagios4 -lcurl -o alerta-neb.o alerta-neb.c -shared -lcurl
    make[1]: Leaving directory `/root/nagios-alerta/src'

If you see something different, ensure you have all of the prerequisites installed.

Now run the installation task:

    sudo make install

You’ll see this output, indicating the module was installed in `/usr/lib/nagios`:

    Outputcd ./src && make install
    make[1]: Entering directory `/root/nagios-alerta/src'
    [-d /usr/lib/nagios] || mkdir /usr/lib/nagios
    install -m 0644 alerta-neb.o /usr/lib/nagios
    make[1]: Leaving directory `/root/nagios-alerta/src'

With the module installed, we can configure Nagios to use this new module.

## Step 2 — Configuring the Nagios-to-Alerta Module

Let’s configure Nagios to send notification messages to Alerta.

First, enable the newly installed Alerta broker module in the Nagios main configuration file. Open the Nagios configuration file in your editor:

    sudo vi /usr/local/nagios/etc/nagios.cfg

Find the section which contains the `broker_module` directives:

/usr/local/nagios/etc/nagios.cfg

    ...
    # EVENT BROKER MODULE(S)
    # This directive is used to specify an event broker module that should
    # by loaded by Nagios at startup. Use multiple directives if you want
    # to load more than one module. Arguments that should be passed to
    # the module at startup are separated from the module path by a space.
    #
    [...]
    #broker_module=/somewhere/module1.o
    #broker_module=/somewhere/module2.o arg1 arg2=3 debug=0
    ...

To configure the Alerta module, you need to provide two mandatory arguments:

- **URL** : The address which is used to communicate with the Alerta API. You configured this in Step 3 of the tutorial [How To Monitor Zabbix Alerts with Alerta on CentOS 7](how-to-monitor-zabbix-alerts-with-alerta-on-centos-7).
- **key** : The API key you created in step 4 of the tutorial [How To Monitor Zabbix Alerts with Alerta on CentOS 7](how-to-monitor-zabbix-alerts-with-alerta-on-centos-7). You need this to authenticate with Alerta and post events.

Add this line to the file to configure the Alerta integration:

/usr/local/nagios/etc/nagios.cfg

    ...
    broker_module=/usr/lib/nagios/alerta-neb.o http://your_alerta_server_ip/api key=ALERTA_API_KEY
    ...

There are some additional optional arguments you can specify as well:

- **env** : This specifies the environment name. The default environment name is `Production`.
- **hard\_only** : Forwards results in Hard state only. You can find more info about Nagios State Types [in the Nagios documentation](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/statetypes.html). Set this to `1` to enable this mode.
- **debug** : - enable debug mode for the module. Set this to `1` to enable this mode.

To specify all of these options, use this line instead:

/usr/local/nagios/etc/nagios.cfg

    ...
    broker_module=/usr/lib/nagios/alerta-neb.o http://your_alerta_server_ip/api key=ALERTA_API_KEY env=Production hard_only=1 debug=1
    ...

Save the file and exit the editor.

In order to identify alerts by environment and service name, you’ll need to set up environment and service names using Nagios [Custom Object Variables](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/customobjectvars.html). To do this, use the `_Environment` and `_Service` variables in your configuration. Let’s configure those now.

Open the default Nagios host object configuration file, which you’ll find in the `/usr/local/nagios/etc/objects/` directory:

    sudo vi /usr/local/nagios/etc/objects/localhost.cfg

We’ll mark all alerts with this host as **Production** alerts, and we’ll call the default service **Nagios**. Find the following host definition:

/usr/local/nagios/etc/objects/localhost.cfg

    ...
    define host{
            use linux-server ; Name of host template to use
                                                            ; This host definition will inherit all variables that are defined
                                                            ; in (or inherited by) the linux-server host template definition.
            host_name localhost
            alias localhost
            address 127.0.0.1
            }
    
    ...

Add the `_Environment` and `_Service` values to the configuration:

/usr/local/nagios/etc/objects/localhost.cfg

    ...
            host_name localhost
            alias localhost
            address 127.0.0.1
            _Environment Production
            _Service Nagios
            }
    ...

Now mark all the events associated with a lack of space on the system partitio as **System** alerts. Locate this section of the file which defines how to check for free space:

/usr/local/nagios/etc/objects/localhost.cfg

    ...
    define service{
            use local-service ; Name of service template to use
            host_name localhost
            service_description Root Partition
            check_command check_local_disk!20%!10%!/
            }
    ...

Modify it to associate it with the `System` service:

/usr/local/nagios/etc/objects/localhost.cfg

    ...
    define service{
            use local-service ; Name of service template to use
            host_name localhost
            service_description Root Partition
            check_command check_local_disk!20%!10%!/
            _Service System
            }
    ...

Save the file and exit the editor. Restart Nagios to apply these new settings:

    sudo systemctl restart nagios.service

Ensure that the service is running by checking its status:

    systemctl status nagios.service

You’ll see the following output:

    Output...
    Jul 01 08:44:31 nagios nagios[8914]: [alerta] Initialising Nagios-Alerta Gateway module, v3.4.1
    Jul 01 08:44:31 nagios nagios[8914]: [alerta] debug is off
    Jul 01 08:44:31 nagios nagios[8914]: [alerta] states=Hard/Soft
    Jul 01 08:44:31 nagios nagios[8914]: [alerta] Forward service checks, host checks and downtime to http://your_alerta_server_ip/api
    Jul 01 08:44:31 nagios nagios[8914]: Event broker module '/usr/lib/nagios/alerta-neb.o' initialized successfully.
    Jul 01 08:44:31 nagios nagios[8914]: Successfully launched command file worker with pid 8920

Now Nagios will send a notification as soon as any system or service goes off. Let’s generate a test event.

## Step 3 — Generating a Test Alert to Verify Nagios-Alerta Integration

Let’s generate a test alert to ensure everything is connected. By default, Nagios keeps track of the amount of free disk space on your server. We’ll create a temporary file that’s large enough to trigger Nagios’ file system usage alert.

First, determine how much free space you have on the Nagios server. You can use the `df` command to find out:

    df -h

You’ll see output like the following:

    Output Filesystem Size Used Avail Use% Mounted on
        /dev/vda1 20G 3.1G 16G 17% /

Look at the amount of free space available. In this case, the free space is `16GB`. Your free space may differ.

Use the `fallocate` command to create a file that takes up more than 80% of the available disk space, which should be enough to trigger the alert:

    fallocate -l 14G /tmp/temp.img

Within a few minutes, Nagios will trigger an alert about the amount of free disk space and will send the notification message to Alerta. You will see this new notification in the Alerta dashboard:

![Alerta displaying the free space alert from Nagios](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/alerta_nagios_cent7/xPCO3K0.png)

Now that you know the alerts are working, delete the temporary file you created so you can reclaim your disk space:

    rm -f /tmp/temp.img

After a minute Nagios will send the recovery message. The alert will then disappear from the main Alerta dashboard, but you can view all closed events by selecting **Closed**.

![Alerta's closed alerts](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/alerta_nagios_cent7/NrCfEUV.png)

You can click on the event row to view more details.

## Conclusion

In this tutorial, you configured Nagios to send notifications to another server running Alerta.

Alerta gives you a convenient place to track alerts from many systems. For example, if some parts of your infrastructure use Nagios and others use Zabbix, you can merge notifications from both systems into one panel.
