---
author: Justin Ellingwood
date: 2015-10-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/saltstack-infrastructure-creating-salt-states-for-mysql-database-servers
---

# SaltStack Infrastructure: Creating Salt States for MySQL Database Servers

## Introduction

SaltStack, or Salt, is a powerful remote execution and configuration management system that can be used to easily manage infrastructure in a structured, repeatable way. In this series, we will be demonstrating one method of managing your development, staging, and production environments from a Salt deployment. We will use the Salt state system to write and apply repeatable actions. This will allow us to destroy any of our environments, safe in the knowledge that we can easily bring them back online in an identical state at a later time.

In the [last guide](saltstack-infrastructure-creating-salt-states-for-haproxy-load-balancers) in this series, we set up HAProxy as a load balancer in front of our web servers. In this guide, we will change our focus to create states that will install and manage our MySQL database servers in each of our environments. This article will cover the basic installation and setup of MySQL. In a future guide, we will tackle the more complex task of setting up replication.

## Get MySQL Prompt Information with debconf-utils

The process of creating our MySQL states will be a bit more complicated than our previous examples with Nginx and MySQL. Unlike the other two installation steps, the MySQL installation typically involves answering a set of prompts to set the MySQL root password.

Before we get started with our state file, we should do a test installation of MySQL on one of our minions. We can then use the `debconf-utils` package to get information about the prompts we will need to fill in.

If you don’t already have your staging environment available, you can use the staging environment map file we created previously to spin up the environment:

    sudo salt-cloud -P -m /etc/salt/cloud.maps.d/stage-environment.map

Once your database servers are up and available, choose one of your database servers to install MySQL so that we can get the relevant information from the installation:

    sudo salt stage-db1 pkg.install mysql-server

In order to easily query the `debconf` databases for the prompt information that we need, we should also install the `debconf-utils` package on the database minion:

    sudo salt stage-db1 pkg.install debconf-utils

The `debconf` functionality within Salt will be available now that this package is installed. We can use the `debconf.get_selections` execution module function to get all of the prompt information from the database minion. We should pipe this into `less` because this will return _all_ of the information from the packages installed on that host:

    sudo salt stage-db1 debconf.get_selections | less

In the output, look for the section that involves MySQL. It should look something like this:

    Output. . .
    
    mysql-server-5.5:
        |_
          - mysql-server/root_password
          - password
        |_
          - mysql-server/root_password_again
          - password
        |_
          - mysql-server-5.5/really_downgrade
          - boolean
          - false
        |_
          - mysql-server-5.5/start_on_boot
          - boolean
          - true
    
    . . .

The top two entries contain the field names we need (`mysql-server/root_password` and `mysql-server/root_password_again`). The second line of these entries specifies the field type, which we will need to specify in our state file.

Once you have copied down this information from the `debconf` output, we should also go ahead and grab the `/etc/mysql/my.cnf` file. We will need this later as we configure our MySQL states:

    sudo salt stage-db1 cp.push /etc/mysql/my.cnf

After pushing the `/etc/mysql/my.cnf` file back to the Salt master, we can delete the resource so that we have a clean slate to test on later in the guide:

    sudo salt-cloud -d stage-db1

Once the server is deleted, you can recreate it in the background by typing the following. The `sm` in this instance is the name of our Salt master server, which has the appropriate cloud credentials:

    sudo salt --async sm cloud.profile stage-db stage-db1

While your database server is rebuilding, we can start building the MySQL state file.

## Create the Main MySQL State File

We will start by creating a directory for our MySQL state within the `/srv/salt` directory:

    sudo mkdir -p /srv/salt/mysql

Within this directory, we can create and open an `init.sls` file to store our primary MySQL state file:

    sudo nano /srv/salt/mysql/init.sls

We will need to ensure that the `debconf-utils` package is installed on the minion in order to easily set the values we need. We can do this with the `pkg.installed` state module:

/srv/salt/mysql/init.sls

    debconf-utils:
      pkg.installed

After the `debconf-utils` package is installed, we can then pre-seed the answers to the prompts using the `debconf.set` state module. We will use the `name` attribute to specify the package name we wish to set prompts for. Then, we create a `data` structure that contains the dictionary of information that can be used to fill in the prompts.

The `data` structure basically uses the information about prompts that we queried from our test MySQL installation. We know the field names and the data types that should be used for these fields. To specify the actual password, we will pull from the Salt pillar system with the `pillar.get` execution module function.

We will set up the password in the pillar system a bit later. This will allow us to keep our password data separate from our configuration.

Note
Pay close attention to the indentation of the dictionary stored within `data`. The entire block is indented an additional **four** spaces instead of the typical two space indentation. This happens when a dictionary is embedded within a YAML list. You can find out more by visiting [this link](https://docs.saltstack.com/en/latest/topics/troubleshooting/yaml_idiosyncrasies.html#indentation).  

/srv/salt/mysql/init.sls

    debconf-utils:
      pkg.installed
    
    mysql_setup:
      debconf.set:
        - name: mysql-server
        - data:
            'mysql-server/root_password': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
            'mysql-server/root_password_again': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
        - require:
          - pkg: debconf-utils

In order to actually interact with MySQL, the appropriate Python libraries must be available on the database servers. We can install the `ptyhon-mysqldb` package to ensure that we have access to Salt’s MySQL capabilities. Afterwards, we can safely install the actual MySQL server software. We will use `require` to ensure that the `debconf` and the Python libraries are available.

After installation, we can add a service state to make sure that the service is running. This will watch for changes in the MySQL server package. It will also watch the basic MySQL configuration file and will reload the service if changes are detected:

/srv/salt/mysql/init.sls

    debconf-utils:
      pkg.installed
    
    mysql_setup:
      debconf.set:
        - name: mysql-server
        - data:
            'mysql-server/root_password': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
            'mysql-server/root_password_again': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
        - require:
          - pkg: debconf-utils
    
    python-mysqldb:
      pkg.installed
    
    mysql-server:
      pkg.installed:
        - require:
          - debconf: mysql-server
          - pkg: python-mysqldb
    
    mysql:
      service.running:
        - watch:
          - pkg: mysql-server
          - file: /etc/mysql/my.cnf

There are a few files that we will need to manage with MySQL. The most obvious file that we need to manage is the `/etc/mysql/my.cnf` file that we mentioned above. We will need to make some changes based on variable information, so this file will have to be a Jinja template.

The other files that we need to manage have to do with Salt’s management of MySQL systems. In order to manage databases, the Salt minion must have information about how to connect to the RDBMS. First, we can create a simple file in the `/etc/salt/minion.d` directory. This will simply list the file where our connection details can be found. The file with the database connection details is the other file we will need to manage. The database connection file will need to be a template:

/srv/salt/mysql/init.sls

    . . .
    
    mysql:
      service.running:
        - watch:
          - pkg: mysql-server
          - file: /etc/mysql/my.cnf
    
    /etc/mysql/my.cnf:
      file.managed:
        - source: salt://mysql/files/etc/mysql/my.cnf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - require:
          - pkg: mysql-server
    
    /etc/salt/minion.d/mysql.conf:
      file.managed:
        - source: salt://mysql/files/etc/salt/minion.d/mysql.conf
        - user: root
        - group: root
        - mode: 640
        - require:
          - service: mysql
    
    /etc/mysql/salt.cnf:
      file.managed:
        - source: salt://mysql/files/etc/mysql/salt.cnf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - require:
          - service: mysql

Lastly, we need to include a `service.restart` state that will reload the `salt-minion` process itself. This is necessary in order for our minion to pick up the `/etc/salt/minion.d/mysql.conf` file. We only want the `salt-minion` to be restarted when there are changes to the `/etc/salt/minion.d/mysql.conf` file itself. We can use a `watch` requisite to accomplish that:

/srv/salt/mysql/init.sls

    . . .
    
    /etc/mysql/salt.cnf:
      file.managed:
        - source: salt://mysql/files/etc/mysql/salt.cnf.jinja
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - require:
          - service: mysql
    
    restart_minion_for_mysql:
      service.running:
        - name: salt-minion
        - watch:
          - file: /etc/salt/minion.d/mysql.conf

When you are finished adding the details above, save and close the file.

## Create the Pillars for MySQL

In our MySQL state, we used the `pillar.get` execution module function to populate the MySQL root password with a value from the pillar system. We need to set up this pillar so that the state can pull the necessary data in order to construct the database credentials.

The pillar system is perfect for this type of use-case because it allows you to assign data to certain hosts. Non-matching hosts will not have access to the sensitive data. So far, our state only needs the root password. We specified the location within the pillar system to be `mysql:root_pw`. We will now go about setting up that key.

### Creating a Top File for the Pillar System

Before we create the MySQL pillar files we need, we need to create a pillar “top” file. The top file is used to match Salt minions with pillar data. Salt minions will not be able to access any pillar data that they do not match in the top file.

The `/srv/pillar` directory should have been created during the installation guide. We can create a `top.sls` file within this directory to get started:

    cd /srv/pillar
    sudo nano top.sls

Inside, we need to specify the `base` environment (we are not using Salt’s conception of environments in this series due to complexity and some undocumented behavior. All of our servers operate in the `base` environment and use grains for environmental designation). We will use compound matching to match nodes. We will match server role and the server environment to determine which pillars to assign to each host.

The pillars use dot notation to signify files within a directory. For instance, the root of the pillars system is `/srv/pillar`. To assign the `mysql.sls` pillar located within the `dev` directory, we use `dev.mysql`.

The assignment we will need for this guide looks like this:

/srv/pillar/top.sls

    base:
      'G@env:dev and G@role:dbserver':
        - match: compound
        - dev.mysql
    
      'G@env:stage and G@role:dbserver':
        - match: compound
        - stage.mysql
    
      'G@env:prod and G@role:dbserver':
        - match: compound
        - prod.mysql

Save and close the file when you are finished.

### Creating the Environmental-Specific Pillars

Above, we assigned pillars to servers based on role and environment. This allows us to specify different connection and credential information for different environments.

Start by making the directories referred to in the pillar top file:

    sudo mkdir /srv/pillar/{prod,stage,dev}

Next, we should create a `myslq.sls` file within each of these directories. We can start with the `/srv/salt/stage/mysql.sls` file, since we are currently using the staging environment to test:

    sudo nano /srv/pillar/stage/mysql.sls

The state file we created wants to pull the MySQL root password from the pillar system using the `mysql:root_pw` key. This is actually a nested key, meaning that `root_pw` is a child of the `mysql` key. With this in mind, we can choose a password for our MySQL root user and set it in the file like this:

/srv/pillar/stage/mysql.sls

    mysql:
      root_pw: staging_mysql_root_pass

Choose whatever password you would like to use. When you are done, save and close the file. This is all we need for now.

Create a similar file within your development pillar:

    sudo nano /srv/pillar/dev/mysql.sls

/srv/pillar/dev/mysql.sls

    mysql:
      root_pw: development_mysql_root_pass

Do the same for your production environment pillar:

    sudo nano /srv/pillar/prod/mysql.sls

/srv/pillar/prod/mysql.sls

    mysql:
      root_pw: production_mysql_root_pass

Choose different passwords for each of these environments.

We will return to these pillars later as we need more data that doesn’t belong in the configuration itself. For now, save and close out of any open files.

## Create the /etc/mysql/my.cnf.jinja Template

We created our basic MySQL state file earlier, but we never created the managed files for the installation.

When we did the test install of `mysql-server` on our `stage-db1` server earlier, we pushed the `/etc/mysql/my.cnf` file back up to the master. That should still be available in our Salt master cache. We can copy the entire directory structure leading up to that cache file to our `/srv/salt/mysql` directory by typing:

    sudo cp -r /var/cache/salt/master/minions/stage-db1/files /srv/salt/mysql

Go to the directory containing the copied `mycnf` file within the MySQL state directory:

    cd /srv/salt/mysql/files/etc/mysql

Copy the file as it exists currently to an `.orig` suffix so that we can revert changes if necessary:

    sudo cp my.cnf my.cnf.orig

Next, rename the `my.cnf` file to have a `.jinja` suffix. This will indicate to us, at a glance, that this file is a template, not a file that can be dropped onto a host without rendering:

    sudo mv my.cnf my.cnf.jinja

Open the Jinja template file to get started with the necessary edits:

    sudo nano my.cnf.jinja

All of the changes that we wish to create now have to do with allowing remote MySQL connections. As it stands, MySQL is binding to the local loopback interface. We want to set this up to listen on the node’s private networking address.

To do this, find the `bind-address` line in the `[mysqld]` section. We will use the `network.interface_ip` execution module function to get the address assigned to the minion’s `eth1` interface.

/srv/salt/mysql/files/etc/mysql/my.cnf.jinja

    . . .
    
    [mysqld]
    
    . . .
    
    bind-address = {{ salt['network.interface_ip']('eth1') }}

The other addition we need to make is to turn off DNS name resolution for our servers. By adding the `skip-name-resolve` option, MySQL will not fail if it cannot complete a name and reverse name resolution:

/srv/salt/mysql/files/etc/mysql/my.cnf.jinja

    . . .
    
    [mysqld]
    
    . . .
    
    bind-address = {{ salt['network.interface_ip']('eth1') }}
    skip-name-resolve

Save and close the file when you are finished.

## Create the /etc/salt/minion.d/mysql.conf File

Next, we need to create the managed file that is used to modify the minion’s configuration with knowledge about how to connect to the MySQL database. Instead of keeping the configuration within the `/etc/salt/minion` file itself, we will place a new file into the `/etc/salt/minion.d` directory telling the minion where to find the connection information.

Start by creating the necessary directory structure withing the `/srv/salt/mysql/files` directory:

    sudo mkdir -p /srv/salt/mysql/files/etc/salt/minion.d

We can create a file within this directory called `mysql.conf`:

    sudo nano /srv/salt/mysql/files/etc/salt/minion.d/mysql.conf

Inside, we only need to set one option: the location of the connection information file. In our case, we will be setting this to a file at `/etc/mysql/salt.cnf`:

/srv/salt/mysql/files/etc/salt/minion.d/mysql.conf

    mysql.default_file: '/etc/mysql/salt.cnf'

Save and close the file when you are finished.

## Create the /etc/mysql/salt.cnf Template File

Now, we need to create the file that our minion configuration referred to. This will be a template file since we need to grab some of the connection details from the pillar system. We will place this file within the `/srv/salt/mysql/files/etc/mysql` directory:

    sudo nano /srv/salt/mysql/files/etc/mysql/salt.cnf.jinja

Inside, we need to open up a `[client]` section to specify the type of information we are defining. Below this header, we can specify for the client to connect to the local machine with the MySQL root user at a Unix socket located at `/var/run/mysqld/mysqld.sock`. These are all default MySQL values:

/srv/salt/mysql/files/etc/mysql/salt.cnf.jinja

    [client]
    host = localhost
    user = root
    socket = /var/run/mysqld/mysqld.sock

The only thing we need to add now is the password. Again, we will pull this directly from the pillar system the same way we had to in the `debconf` section of our MySQL state file. It will look something like this:

/srv/salt/mysql/files/etc/mysql/salt.cnf.jinja

    [client]
    host = localhost
    user = root
    socket = /var/run/mysqld/mysqld.sock
    password = {{ salt['pillar.get']('mysql:root_pw', '') }}

Save and close the file when you are finished.

## Test Installation and Sanity Check

Now that we have the basic installation state and supporting files configured, we should test our set up quickly to make sure that it is operating correctly.

We will start by going through our typical testing process. Use the `state.show_sls` execution module function to make sure it can render your state file:

    sudo salt stage-db1 state.show_sls mysql

Look through the output to make sure that Salt has no issues parsing your `/srv/salt/mysql/init.sls` file.

Next, do a dry run of the state application by adding `test=True` to the end of the `state.apply` execution module function:

    sudo salt stage-db1 state.apply mysql test=True

**This command is expected to fail**. Because some of the state functions in our file aren’t available until after specific packages are installed, failure during the dry run is expected. During the actual run, the state ordering will ensure that the prerequisite packages are installed _before_ the states that utilize them are called.

All of the comments for the failed states should indicate that “one or more requisite failed” with the exception of the `mysql_setup` state, which should fail due to `debconf.set` not being available (this is just another prerequisite failure). Use the output here to ensure that no other unrelated errors are surfaced.

After running the test, we can apply the state by typing:

    sudo salt stage-db1 state.apply mysql

This should result in a successful state run.

We need to test that Salt is able to connect to and query the MySQL database. Make sure that you can list the default databases by typing:

    sudo salt stage-db1 mysql.db_list

You should get a listing that looks something like this:

    Outputstage-db1:
        - information_schema
        - mysql
        - performance_schema

This indicates that Salt was able to connect to the MySQL instance using the information specified in the `/etc/mysql/salt.cnf` file.

Now that we’ve verified that our base MySQL state works correctly, we can delete the `stage-db1` server:

    sudo salt-cloud -d stage-db1

Recreate the server in the background so that we will have it for further testing later. Again, `sm` is the name of our Salt master server in this instance:

    sudo salt --async sm cloud.profile stage-db stage-db1

Now, our basic MySQL setup is complete.

## Conclusion

You should now have states that will install MySQL on your minions. These will also kick the `salt-minion` process on each of these servers so that Salt can connect to and manage the databases involved.

While our current states install MySQL and configure our minions to control the database systems, currently our databases are completely separate. In a future guide, we will tackle MySQL database replication so that our data is consistent across each of our databases within each environment.
