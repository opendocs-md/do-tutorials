---
author: Justin Ellingwood
date: 2014-09-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-troubleshoot-common-issues-with-your-coreos-servers
---

# How To Troubleshoot Common Issues with your CoreOS Servers

## Introduction

CoreOS introduces a number of interesting technologies that make building distributed systems easy. However, these tools can be unfamiliar to new users and have their own eccentricities. One of the main issues is that there are many layers of abstraction at work and it can be difficult to pin down where a problem is occurring.

In this guide, we will go over some basic troubleshooting procedures for working with CoreOS hosts, the Docker containers they run, and the service management tools that pull some of the disparate pieces together.

## Debugging your Cloud-Config File

One of the most common issues that new and experienced CoreOS users run into when a cluster is failing to come up correctly is an invalid cloud-config file.

CoreOS requires that a cloud-config file be passed into your server upon creation. It uses the information contained within this file to bootstrap itself and initiate or join an existing cluster. It also starts essential services and can configure system basics such as users and groups.

Some things to check with your cloud-config file:

- **Does it start with “#cloud-config”?** : Every cloud-config file passed in must begin with “#cloud-config” standing alone on the first line. While this is usually an ignored comment in YAML, in this instance this line is used to signal to the cloud init system that this contains configuration data.
- **Does your file contain valid YAML?** : Cloud-config files are written in YAML, a data serialization format with a focus on readability. If you are having issues, paste your cloud-config into an online [YAML validator](http://codebeautify.org/yaml-validator). Your file should contain no errors. CoreOS provides a helpful tool that can check your cloud-config file’s syntax, [Cloud-Config Validator](https://coreos.com/validate/).
- **Are you Using a fresh discovery token?** : The discovery address keeps track of your machines’ data even if the entire cluster is down. The discovery registration will fail when you boot up with an old token, especially if you had already registered the same IP address previously. Use a fresh discovery token each time you start a cluster in order to avoid this problem.
- **Are you starting the fleet and etcd services?** : Two services that must start in order for your cluster to function correctly are `fleet` and `etcd`. You should look at our guide on [getting a CoreOS cluster running on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean) for a basic cloud-config file that satisfies these minimum requirements.

You can only pass in the cloud-config file when the machine is created, so if you have made a mistake, destroy the server instance and start again (with a new token, in most cases).

Once you are fairly certain that the cloud-config file itself is correct, the next step is to log into the host to ensure that the file was processed correctly.

This should be easy in most cases since, on DigitalOcean, you are required to add ssh keys to the server during creation. This means that you can usually ssh into the server to troubleshoot without a problem.

### Logging In through the DigitalOcean Control Panel

However, there are certain times when your cloud-config may have actually affected the network availability of your server once launched. In this case, you will have to login through the DigitalOcean control panel. This presents a problem, since no passwords are set on the CoreOS image by default, for security reasons.

To work around this, you must recreate the server with a new cloud-config file which contains a password entry for the `core` user. Because of the recreation requirement, this will probably only be useful if you are consistently seeing this issue and want to get more information. You may want to add the password information to all of your cloud-config files as a general practice so you can troubleshoot. You can manually unset the password after verifying your connection.

The password must be in the form of a hash. You can generate these a few different ways depending on the software you have available. Any of the following will work, so use whichever option is best for you:

    mkpasswd --method=SHA-512 --rounds=4096
    openssl passwd -1
    python -c "import crypt, getpass, pwd; print crypt.crypt('password', '\$6\$SALT\$')"
    perl -e 'print crypt("password","\$6\$SALT\$") . "\n"'

Once you have a hash, you can add a new section to your cloud-config (outside of the “coreos” section), called `users` to place this information:

    #cloud-config
    users:
      - name: core
        passwd: hashed_password
    coreos:
      . . .

[Validate your YAML syntax](http://codebeautify.org/yaml-validator), and then use this new cloud-config when creating the server again. You should then be able to use the password you selected to log in through the DigitalOcean control panel.

## Checking the Individual Host

Once you are logged in, There are a few things you should check to see if your cloud-config was processed correctly.

### Check for Errors in the Essential Services

An easy way to start is to ask `fleetctl` what machines it knows about. If this returns without an error, it means that `fleet` and `etcd` were started correctly and that they are communicating with other hosts.

    fleetctl list-machines

If you get an error here, there are a number of things that you should look at. A common error looks like this:

    2014/09/18 17:10:50 INFO client.go:278: Failed getting response from http://127.0.0.1:4001/: dial tcp 127.0.0.1:4001: connection refused
    2014/09/18 17:10:50 ERROR client.go:200: Unable to get result for {Get /_coreos.com/fleet/machines}, retrying in 100ms
    2014/09/18 17:10:50 INFO client.go:278: Failed getting response from http://127.0.0.1:4001/: dial tcp 127.0.0.1:4001: connection refused
    2014/09/18 17:10:50 ERROR client.go:200: Unable to get result for {Get /_coreos.com/fleet/machines}, retrying in 200ms

Since this represents a stack of different components on top of each other, let’s start at the top level and work down. Check the `fleet` service to see what errors it gives us:

    systemctl status -l fleet

    ● fleet.service - fleet daemon
       Loaded: loaded (/usr/lib64/systemd/system/fleet.service; static)
      Drop-In: /run/systemd/system/fleet.service.d
               └─20-cloudinit.conf
       Active: active (running) since Thu 2014-09-18 17:10:50 UTC; 2min 26s ago
     Main PID: 634 (fleetd)
       CGroup: /system.slice/fleet.service
               └─634 /usr/bin/fleetd
    
    Sep 18 17:13:07 dumb1 fleetd[634]: INFO client.go:278: Failed getting response from http://localhost:4001/: dial tcp 127.0.0.1:4001: connection refused
    Sep 18 17:13:07 dumb1 fleetd[634]: ERROR client.go:200: Unable to get result for {Update /_coreos.com/fleet/machines/795de101bcd24a3a96aa698f770f0074/object}, retrying in 800ms
    Sep 18 17:13:08 dumb1 fleetd[634]: INFO client.go:278: Failed getting response from http://localhost:4001/: dial tcp 127.0.0.1:4001: connection refused

As you can see, the service is running, but it is not able to connect to port `4001`, which is the `etcd` port. This indicates that the problem might be with `etcd`.

For each of our essential services, we should check the status and logs. The general way of doing this is:

    systemctl status -l service
    journalctl -b -u service

The “status” command gives us the state of the service and the last few log lines. The journal command gives us access to the full logs.

If we try these with `etcd` next, we can see that the `etcd` service is not running in our case:

    systemctl status -l etcd

    ● etcd.service - etcd
       Loaded: loaded (/usr/lib64/systemd/system/etcd.service; static)
      Drop-In: /run/systemd/system/etcd.service.d
               └─20-cloudinit.conf
       Active: activating (auto-restart) (Result: exit-code) since Thu 2014-09-18 17:17:03 UTC; 9s ago
      Process: 938 ExecStart=/usr/bin/etcd (code=exited, status=1/FAILURE)
     Main PID: 938 (code=exited, status=1/FAILURE)
    
    Sep 18 17:17:03 dumb1 systemd[1]: etcd.service: main process exited, code=exited, status=1/FAILURE
    Sep 18 17:17:03 dumb1 systemd[1]: Unit etcd.service entered failed state.

If we check the `etcd` logs, we will see something like this:

    journalctl -b -u etcd

    Sep 18 17:21:27 dumb1 systemd[1]: Starting etcd...
    Sep 18 17:21:27 dumb1 systemd[1]: Started etcd.
    Sep 18 17:21:27 dumb1 etcd[1160]: [etcd] Sep 18 17:21:27.966 INFO | The path /var/lib/etcd/log is in btrfs
    Sep 18 17:21:27 dumb1 etcd[1160]: [etcd] Sep 18 17:21:27.967 INFO | Set NOCOW to path /var/lib/etcd/log succeeded
    Sep 18 17:21:27 dumb1 etcd[1160]: [etcd] Sep 18 17:21:27.967 INFO | Discovery via https://discovery.etcd.io using prefix /.
    Sep 18 17:21:28 dumb1 etcd[1160]: [etcd] Sep 18 17:21:28.422 WARNING | Discovery encountered an error: invalid character 'p' after top-level value
    Sep 18 17:21:28 dumb1 etcd[1160]: [etcd] Sep 18 17:21:28.423 WARNING | 795de101bcd24a3a96aa698f770f0074 failed to connect discovery service[https://discovery.etcd.io/]: invalid character 'p' after top-level value
    Sep 18 17:21:28 dumb1 etcd[1160]: [etcd] Sep 18 17:21:28.423 CRITICAL | 795de101bcd24a3a96aa698f770f0074, the new instance, must register itself to discovery service as required
    Sep 18 17:21:28 dumb1 systemd[1]: etcd.service: main process exited, code=exited, status=1/FAILURE
    Sep 18 17:21:28 dumb1 systemd[1]: Unit etcd.service entered failed state.

The highlighted line shows that this particular instance did not have a discovery token.

### Check the Filesystem to See the Configuration Files Generated by the Cloud-Config

The next thing to check is what service files were generated by the cloud-config.

When your CoreOS machine processes the cloud-config file, it generates stub `systemd` unit files that it uses to start up `fleet` and `etcd`. To see the `systemd` configuration files that were created and are being used to start your services, change to the directory where they were dropped:

    cd /run/systemd/system
    ls -F

    etcd.service.d/ fleet.service.d/ oem-cloudinit.service

You can see the generalized `oem-cloudinit.service` file, which is taken care of automatically by CoreOS, and the directories that have service information in them. We can see what information our `etcd` service is starting up with by typing:

    cat etcd.servicd.d/20-cloudinit.conf

    [Service]
    Environment="ETCD_ADDR=10.132.247.162:4001"
    Environment="ETCD_DISCOVERY=https://discovery.etcd.io/"
    Environment="ETCD_NAME=795de101bcd24a3a96aa698f770f0074"
    Environment="ETCD_PEER_ADDR=10.132.247.162:7001"

This is a stub `systemd` unit file that is used to add additional information to the service when it is started. As you can see here, the `ETCD_DISCOVERY` address matches the error we found in the logs: there is no discovery token appended at the end. We need to remake our machines using a cloud-config with a valid discovery token.

You can get similar information about `fleet` by typing:

    cat fleet.service.d/20-cloudinit.conf

    [Service]
    Environment="FLEET_METADATA=region=nyc,public_ip=104.131.1.89"
    Environment="FLEET_PUBLIC_IP=10.132.247.162"

Here, we can see that `fleet` was given some metadata information in the cloud-config. This can be used for scheduling when you create service unit files.

### Checking for Access to the Metadata Service

The actual cloud-config file that is given when the CoreOS server is created with DigitalOcean is stored using a metadata service. If you were unable to find any evidence of your cloud-config on your server, it is possible that it was unable to pull the information from the DigitalOcean metadata service.

From within your host machine, type:

    curl -L 169.254.169.254/metadata/v1

    id
    hostname
    user-data
    vendor-data
    public-keys
    region
    interfaces/
    dns/

You must include the `-L` to follow redirects. The `169.254.169.254` address will be used for _every_ server, so you should not modify this address. This shows you the metadata fields and directories that contain information about your server. If you are unable to reach this from within your DigitalOcean CoreOS server, you may need to open a support ticket.

You can query this URL for information about your server. You can explore each of the entries here with additional curl commands, but the one that contains the cloud-config file is the `user-data` field:

    curl -L 169.254.169.254/metadata/v1/user-data

    #cloud-config
    users:
      - name: core
        passwd: $6$CeKTMyfClO/CPSHB$02scg00.FnwlEYdq/oXiXoohzvvlY6ykUck1enMod7VKJrzyGRAtZGziZh48LNcECu/mtgPZpY6aGCoj.h4bV1
    coreos:
      etcd:
        # generated token from https://discovery.etcd.io/new
        discovery: https://discovery.etcd.io/
        # multi-region and multi-cloud deployments need to use $public_ipv4
        addr: $private_ipv4:4001
        peer-addr: $private_ipv4:7001
      fleet:
        public-ip: $private_ipv4
        metadata: region=nyc,public_ip=$public_ipv4
      units:
        - name: etcd.service
          command: start
        - name: fleet.service
          command: start

If you can read your cloud-config from this location, it means that your server has the ability to read the cloud-config data, and should implement its instructions when booting the server.

## Troubleshooting Other Issues with a CoreOS Host Machine

If you need to do further debugging, you may quickly find out that CoreOS contains a very minimal base installation. Since it expects all software to be run in containers, it does not include even some of the most basic utility programs.

Luckily, the CoreOS developers provide an elegant solution to this problem. By using the “toolbox” script included in each host, you can start up a Fedora container with access to the host systems. From inside of this container, you can install any utilities necessary to debug the host.

To start it up, just use the `toolbox` command:

    toolbox

This will pull down the latest Fedora image and drop you into a command line within the container. If you do some quick checks, you will realize that you have access to the host system’s network:

    ip addr show

    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host 
           valid_lft forever preferred_lft forever
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
        link/ether 04:01:28:7c:39:01 brd ff:ff:ff:ff:ff:ff
        inet 169.254.180.43/16 brd 169.254.255.255 scope link eth0
           valid_lft forever preferred_lft forever
        . . .

You also have full access to the host’s processes:

    ps aux

    USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
    root 1 0.0 0.1 106024 4912 ? Ss 17:10 0:04 /usr/lib/systemd/systemd --switched-root --system --deserialize 19
    root 2 0.0 0.0 0 0 ? S 17:10 0:00 [kthreadd]
    root 3 0.0 0.0 0 0 ? S 17:10 0:00 [ksoftirqd/0]
    root 5 0.0 0.0 0 0 ? S< 17:10 0:00 [kworker/0:0H]
    root 6 0.0 0.0 0 0 ? S 17:10 0:00 [kworker/u4:0]
    root 7 0.0 0.0 0 0 ? S 17:10 0:00 [rcu_sched]
    root 8 0.0 0.0 0 0 ? S 17:10 0:00 [rcu_bh]
    . . .

You can install any tools you need within this environment. For instance, we can install `htop`, a top clone with additional features, by using the Fedora package manager:

    yum install htop -y && htop

This will bring up the process monitor with all of the host’s processes loaded.

To exit the container environment, type “exit”, or hit `CTRL-]` three times fast. You will be dropped back into the host’s shell session.

## Troubleshooting Services From Any Host

Another area that you may need to troubleshoot is the actual services you are running. Because we have `fleet` and `fleetctl` to manage our services cluster-wide, our first steps can be preformed on any of the servers in our cluster.

We should begin by getting an idea of your services’ health, both from the perspective of `fleet`, and from the individual hosts that have been assigned to run each service. The `fleetctl` tool gives us commands to easily get this information.

First, get an idea of how `fleet` sees the service state by typing:

    fleetctl list-unit-files

    UNIT HASH DSTATE STATE TARGET
    apache-discovery@4444.service 06d78fb loaded loaded 04856ec4.../10.132.249.212
    apache-discovery@7777.service 06d78fb loaded loaded 197a1662.../10.132.249.206
    apache-discovery@8888.service 06d78fb loaded loaded e3ca8fd3.../10.132.252.37
    apache@4444.service 0f7f53b launched launched 04856ec4.../10.132.249.212
    apache@7777.service 0f7f53b launched launched 197a1662.../10.132.249.206
    apache@8888.service 0f7f53b launched launched e3ca8fd3.../10.132.252.37
    nginx_lb.service c8541af launched launched 96ec72cf.../10.132.248.177

This will give you an overview of all of the services that `fleet` knows about. This output has some very important information. Let’s take a look.

- **UNIT** : This is the name of the unit. In our case, the top six services are all instance units (find more about [templates and instances](how-to-create-flexible-services-for-a-coreos-cluster-with-fleet-unit-files) here) and the bottom appears to be a static instance. These are the names we can use to issue commands affecting each of these services.
- **HASH** : this is the hash of the unit file used to control this service. As you can see, all of the `apache-discovery` instances are spawned from the same template file. The `apache` instances are all spawned from another. This can be useful to see if any of your services are exhibiting strange behavior by using an out-of-date unit file.
- **DSTATE** : This is the desired state of the unit. When you issue a command to `fleetctl` to change a unit’s state, this column changes to reflect the desired state for that unit.
- **STATE** : This is the _actual_ state of the unit, as known to `fleet`. If this is different from the DSTATE, it may mean that an operation has failed.
- **TARGET** : The machine that has been scheduled to run this service. This will be available when a unit is either launched or loaded. It contains the machine ID and the IP address of the machine.

As you can see, there are quite a few pieces of information that can help you debug a problem.

However, this is not the only important place to check. It is important to realize that there are times when `fleet` will not agree with the machine’s local `systemd` instance about the state of a service. This can happen for a variety of reasons, such as if one unit starts or stops another unit internally.

To get information about the state of each service, taken from the `systemd` instance of the host that is running that service, use the `list-units` command instead:

    fleetctl list-units

    UNIT MACHINE ACTIVE SUB
    apache-discovery@4444.service 04856ec4.../10.132.249.212 active running
    apache-discovery@7777.service 197a1662.../10.132.249.206 active running
    apache-discovery@8888.service e3ca8fd3.../10.132.252.37 active running
    apache@4444.service 04856ec4.../10.132.249.212 active running
    apache@7777.service 197a1662.../10.132.249.206 active running
    apache@8888.service e3ca8fd3.../10.132.252.37 active running
    nginx_lb.service 96ec72cf.../10.132.248.177 active running

Here, we can see that all of the services are listed as running. This disagrees with the information that `list-unit-files` shows. That is because each of the `apache` services launches the associated `apache-discovery` service without letting `fleet` know. This is not an error, but can cause confusion about the actual state of a service.

To get further information about any of the services, you can use `fleetctl` to access the host system’s `systemctl status` and `journalctl -u` information. Just type:

    fleetctl status service_name

    ● apache@4444.service - Apache web server service on port 4444
       Loaded: loaded (/run/fleet/units/apache@4444.service; linked-runtime)
       Active: active (running) since Thu 2014-09-18 18:50:00 UTC; 7min ago
      Process: 3535 ExecStartPre=/usr/bin/docker pull imchairmanm/apache (code=exited, status=0/SUCCESS)
      Process: 3526 ExecStartPre=/usr/bin/docker rm apache.%i (code=exited, status=0/SUCCESS)
      Process: 3518 ExecStartPre=/usr/bin/docker kill apache.%i (code=exited, status=0/SUCCESS)
     Main PID: 3543 (docker)
       CGroup: /system.slice/system-apache.slice/apache@4444.service
               └─3543 /usr/bin/docker run -t --name apache.4444 -p 10.132.249.212:4444:80 imchairmanm/apache /usr/sbin/apache2ctl -D FOREGROUND

Or read the journal by typing:

    fleetctl journal service_name

    -- Logs begin at Mon 2014-09-15 14:54:12 UTC, end at Thu 2014-09-18 18:57:51 UTC. --
    Sep 17 14:33:20 lala2 systemd[1]: Started Apache web server service on port 4444.
    Sep 17 14:33:20 lala2 docker[21045]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.10. Set the 'ServerName' directive globally to suppress this message
    Sep 18 18:49:29 lala2 systemd[1]: Stopping Apache web server service on port 4444...
    Sep 18 18:49:39 lala2 docker[3500]: apache.4444
    Sep 18 18:49:39 lala2 systemd[1]: Stopped Apache web server service on port 4444.
    Sep 18 18:49:58 lala2 systemd[1]: Starting Apache web server service on port 4444...
    Sep 18 18:49:58 lala2 docker[3518]: apache.4444
    Sep 18 18:49:58 lala2 docker[3526]: apache.4444
    Sep 18 18:49:58 lala2 docker[3535]: Pulling repository imchairmanm/apache
    Sep 18 18:50:00 lala2 systemd[1]: Started Apache web server service on port 4444.

This can provide some good information about why your services are failing. For instance, if your unit file declared an unavailable dependency, that would show up here (this can happen if the dependency hasn’t been loaded into `fleet` yet).

One error you may come across when you are issuing some of these commands is:

    Error running remote command: SSH_ AUTH _SOCK environment variable is not set. Verify ssh-agent is running. See https://github.com/coreos/fleet/blob/master/Documentation/using-the-client.md for help.

This is an indication that you did not forward your ssh user agent when you connected to this host. In order for `fleet` to get information about other machines in the cluster, it connects using the SSH credentials that you keep on your local computer.

To do this, you must run an ssh agent on your local computer and add your private key. You can do this on your local computer by typing:

    eval $(ssh-agent)
    ssh-add

    Identity added: /home/username/.ssh/id_rsa (/home/username/.ssh/id_rsa)

Once your ssh agent has been given access to your private key, you should connect to your CoreOS host with the `-A` option to _forward_ this information:

    ssh -A core@coreos_host

This will allow the machine you are ssh-ing into to use your credentials to make connections to the other machines in the cluster. It is what allows you to read the `systemd` information from remote cluster members. It also allows you to ssh directly to other members.

## Troubleshooting Containers From the Host Running the Service

Although you can get many great pieces of information using only `fleetctl`, sometimes you have to go to the host that is responsible for running the service to troubleshoot.

As we stated above, this is easy when you have forwarded your SSH information when connecting. From the host you connected to, you can “hop” to other machines using `fleetctl`. You can either specify a machine ID, or simply the service name. The `fleetctl` process is smart enough to know which host you are referring to:

    fleetctl ssh service_name

This will give you an ssh connection to the host assigned to run that service. A service must be in the “loaded” or “launched” state for this to work.

From here, you will have access to all of the local troubleshooting tools. For instance, you can get access to the more complete set of `journalctl` flags that may not be available through the `fleetctl journal` command:

    journalctl -b --no-pager -u apache@4444

At this point, you may wish to troubleshoot Docker issues. To see the list of running containers, type:

    docker ps

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    b68139630337 imchairmanm/apache:latest "/usr/sbin/apache2ct 30 minutes ago Up 30 minutes 10.132.249.212:4444->80/tcp apache.4444

We can see that there is currently one container running. The highlighted container ID is useful for many more Docker operations.

If your service failed to start, your container will not be running. To see a list of all containers, including those that have exited/failed, pass the `-a` flag:

    docker ps -a

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    b68139630337 imchairmanm/apache:latest "/usr/sbin/apache2ct 31 minutes ago Up 31 minutes 10.132.249.212:4444->80/tcp apache.4444         
    4389108bff1a imchairmanm/apache:latest "/usr/sbin/apache2ct 28 hours ago Exited (-1) 28 hours ago apache.8888         
    5af6e4f95642 imchairmanm/lalala:latest "/usr/sbin/apache2ct 3 days ago Exited (-1) 3 days ago apache.7777

To see the _last_ container that was started, regardless of its state, you can use the `-l` flag instead:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    b68139630337 imchairmanm/apache:latest "/usr/sbin/apache2ct 33 minutes ago Up 33 minutes 10.132.249.212:4444->80/tcp apache.4444

Once you have the container ID of the container you are looking for, you can start to investigate at the Docker level. First, you can view the logs:

    docker logs container_id

This will give you the log information that can be collected from the container. This should work whether the container is running or not. If the container was run interactively (with the `-i` and `-t` flags and a shell session), the entire session will be available in the logs.

You can get a list of the running processes for any container that is active by typing:

    docker top container_id

### Spawning a Shell Session within a Container

One of the most useful steps is to actually open up a shell session on a running container to see what is going on from the inside. To do this, CoreOS ships with a utility called `nsenter`.

Docker containers work by setting up kernel namespaces and this tool can start up a session within these environments. The first step is to get the PID of the container that you wish to enter:

    PID=$(docker inspect --format {{.State.Pid}} container_id)

Now, you can open up a shell session within that container environment by typing:

    sudo nsenter -t $PID -m -u -i -n -p

You will be given a shell session within the container environment. From here, you can view logs or do any other troubleshooting necessary.

Depending on the way the container was constructed, you may get a message saying that `bash` was not found. In this case, you will have to use the generic `sh` shell by appending that at the end of your command:

    sudo nsenter -t $PID -m -u -i -n -p /bin/sh

## Conclusion

These are just a few of the procedures that you can use to troubleshoot issues with your CoreOS clusters. These should help you track down problems you may have with your cloud-config file and troubleshoot your machines’ ability to cluster and start services correctly. Tracking down problems with the Docker containers and services themselves is another area we covered.

One of the most important things to keep in mind is that debugging becomes much easier the more information you have about your system. It is helpful to have a solid grasp on what each components’ role is and how they interact to help the system function. If you find yourself lost when trying to track down an issue, it may be helpful to give yourself a refresher on the CoreOS basics.
