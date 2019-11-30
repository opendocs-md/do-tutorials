---
author: Justin Ellingwood
date: 2014-09-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-store
---

# How To Use Etcdctl and Etcd, CoreOS's Distributed Key-Value Store

## Introduction

One of the technologies that makes CoreOS possible is `etcd`, a globally distributed key-value store. This service is used by the individual CoreOS machines to form a cluster and as a platform to store globally-accessible data.

In this guide, we will explore the `etcd` daemon as well as the `etcdctl` utility and the HTTP/JSON API that can be used to control it.

## Prerequisites

To follow along with this guide, we assume that you have a cluster of CoreOS machines as our guide on [getting a CoreOS cluster set up on DigitalOcean](how-to-set-up-a-coreos-cluster-on-digitalocean) outlines. This will leave you with three servers in a single cluster:

- coreos-1
- coreos-2
- coreos-3

Once you have these machines up and running, you can continue with this guide.

## Etcd Cluster Discovery Model

One of the most fundamental tasks that `etcd` is responsible for is organizing individual machines into a cluster. This is done when CoreOS is booted by checking in at the discovery address supplied in the `cloud-config` file which is passed in upon creation.

The discovery service run by CoreOS is accessible at `https://discovery.etcd.io`. You can get a new token by visiting the `/new` page. There, you will get a token which your machines can use to discover their companion nodes. It will look like something like this:

    https://discovery.etcd.io/dcadc5d4d42328488ecdcd7afae5f57c

You _must_ supply a fresh token for every new cluster. This includes when you have to rebuild the cluster using nodes that may have the same IP address. The `etcd` instances will be confused by this and will not function correctly to build the cluster if you reuse the discovery address.

Visiting the discovery address in your web browser, you will get back a JSON object that describes the known machines. This won’t have any nodes when you first start out:

    {"action":"get","node":{"key":"/_etcd/registry/dcadc5d4d42328488ecdcd7afae5f57c","dir":true,"modifiedIndex":102511104,"createdIndex":102511104}}

After bootstrapping your cluster, you will be able to see more information here:

    {"action":"get","node":{"key":"/_etcd/registry/1edee33e6b03e75d9428eacf0ff94fda","dir":true,"nodes":[{"key":"/_etcd/registry/1edee33e6b03e75d9428eacf0ff94fda/2ddbdb7c872b4bc59dd1969ac166501e","value":"http://10.132.252.38:7001","expiration":"2014-09-19T13:41:26.912303668Z","ttl":598881,"modifiedIndex":102453704,"createdIndex":102453704},{"key":"/_etcd/registry/1edee33e6b03e75d9428eacf0ff94fda/921a7241c31a499a97d43f785108b17c","value":"http://10.132.248.118:7001","expiration":"2014-09-19T13:41:29.602508981Z","ttl":598884,"modifiedIndex":102453736,"createdIndex":102453736},{"key":"/_etcd/registry/1edee33e6b03e75d9428eacf0ff94fda/27987f5eaac243f88ca6823b47012c5b","value":"http://10.132.248.121:7001","expiration":"2014-09-19T13:41:41.817958205Z","ttl":598896,"modifiedIndex":102453860,"createdIndex":102453860}],"modifiedIndex":101632353,"createdIndex":101632353}}

If you need to find the discovery URL of a cluster, you can do so from any one of the machines that is a member. This information can be retrieved from within the `/run` hierarchy:

    cat /run/systemd/system/etcd.service.d/20-cloudinit.conf

    [Service]
    Environment="ETCD_ADDR=10.132.248.118:4001"
    Environment="ETCD_DISCOVERY=https://discovery.etcd.io/dcadc5d4d42328488ecdcd7afae5f57c"
    Environment="ETCD_NAME=921a7241c31a499a97d43f785108b17c"
    Environment="ETCD_PEER_ADDR=10.132.248.118:7001"

The URL is stored within the `ETCD_DISCOVERY` entry.

When the machines running `etcd` boot up, they will check the information at this URL. It will submit its own information and query about other members. The first node in the cluster will obviously not find information about other nodes, so it will designate itself as the cluster leader.

The subsequent machines will also contact the discovery URL with their information. They will receive information back about the machines that have already checked in. They will then choose one of these machines and connect directly, where they will get the full list of healthy cluster members. The replication and distribution of data is accomplished through the [Raft consensus algorithm](http://raftconsensus.github.io/).

The data about each of the machines is stored within a hidden directory structure within `etcd`. You can see the information about the machines that `etcd` knows about by typing:

    etcdctl ls /_etcd/machines --recursive

    /_etcd/machines/2ddbdb7c872b4bc59dd1969ac166501e
    /_etcd/machines/921a7241c31a499a97d43f785108b17c
    /_etcd/machines/27987f5eaac243f88ca6823b47012c5b

The details that `etcd` pass to new cluster members are contained within these keys. You can see the individual values by requesting those with `etcdctl`:

    etcdctl get /_etcd/machines/2ddbdb7c872b4bc59dd1969ac166501e

    etcd=http%3A%2F%2F10.132.252.38%3A4001&raft=http%3A%2F%2F10.132.252.38%3A7001

We will go over the `etcdctl` commands in more depth later on.

## Etcdctl Usage

There are two basic ways of interacting with `etcd`. Through the HTTP/JSON API and through a client, like the included `etcdctl` utility. We will go over `etcdctl` first.

### Viewing Keys and Directories

To get started, let’s look a what `etcdctl` is currently storing. We can see the top-level keys by typing:

    etcdctl ls /

    /coreos.com

As you can see, we have one result. At this point, it is unclear whether this is a directory or a key. We can attempt to `get` the node to see either the key’s value or to see that it is a directory:

    etcdctl get /coreos.com

    /coreos.com: is a directory

In order to avoid this manual recursive process, we can tell `etcdctl` to list its entire hierarchy of visible information by typing:

    etcdctl ls / --recursive

    /coreos.com
    /coreos.com/updateengine
    /coreos.com/updateengine/rebootlock
    /coreos.com/updateengine/rebootlock/semaphore

As you can see, there were quite a few directories under the initial `/coreos.com` node. We can see what it looks like to get actual data out of a node by asking for the information at the final endpoint:

    etcdctl get /coreos.com/updateengine/rebootlock/semaphore

    {"semaphore":1,"max":1,"holders":null}

This does not contain information that is very useful for us. We can get some additional metadata about this entry by passing in the `-o extended` option. This is a global option, so it must come before the `get` command:

    etcdctl -o extended get /coreos.com/updateengine/rebootlock/semaphore

    Key: /coreos.com/updateengine/rebootlock/semaphore
    Created-Index: 6
    Modified-Index: 6
    TTL: 0
    Etcd-Index: 170387
    Raft-Index: 444099
    Raft-Term: 8
    
    {"semaphore":1,"max":1,"holders":null}

### Setting Keys and Creating Nodes

To create a new directory, you can use the `mkdir` command like so:

    etcdctl mkdir /example

To make a key, you can use the `mk` command:

    etcdctl mk /example/key data

    data

This will only work if the key does not already exist. If we ask for the value of the key we created, we can retrieve the data we set:

    etcdctl get /example/key

    data

To update an existing key, use the `update` command:

    etcdctl update /example/key turtles

    turtles

The companion `updatedir` command for directories is probably only useful if you have set a TTL, or time-to-live on a directory. This will update the TTL time with the one passed. You can set TTLs for directories or keys by passing the `--ttl #` argument, where “#” is the number of seconds to keep:

    etcdctl mkdir /here/you/go --ttl 120

You can then update the TTL with `updatedir`:

    etcdctl updatedir /here/you/go --ttl 500

To change the value of an existing key, or to create a key if it does not exist, use the `set` command. Think of this as a combination of the `mk` and `update` command:

    etcdctl set /example/key new

    new

This can include non-existent paths. The path components will be created dynamically:

    etcdctl set /a/b/c here

    here

To get this same create-if-does-not-exist functionality for directories, you can use the `setdir` command:

    etcdctl setdir /x/y/z

**Note** : the `setdir` command does not currently function as stated. In the current build, its usage mirrors the `updatedir` command and will fail if the directory already exists. There is an open issue on the GitHub repository to address this.

### Removing Entries

To remove existing keys, you can use the `rm` or `rmdir` command.

The `rm` command can be used to remove a key:

    etcdctl rm /a/b/c

It can also be used recursively to remove a directory and every subdirectory:

    etcdctl rm /a --recursive

To remove only an empty directory _or_ a key, use the `rmdir` command:

    etcdctl rmdir /x/y/z

This can be used to make sure you are only removing the endpoints of the hierarchies.

### Watching for Changes

You can watch either a specific key or an entire directory for changes. Watching these with `etcdctl` will cause the operation to hang until some event happens to whatever is being watched.

To watch a key, use it without any flags:

    etcdctl watch /example/hello

To stop watching, you can press `CTRL-C`. If a change is detected during the watch, the new value will be returned.

To watch an entire directory structure, use the `--recursive` flag:

    etcdctl watch --recursive /example

You can see how this would be useful by placing it in a simple looping construct to constantly monitor the state of the values:

    while true; do etcdctl watch --recursive /example; done

If you would like to execute a command whenever a change is detected, use the `exec-watch` command:

    etcdctl exec-watch --recursive /example -- echo "hello"

This will echo “hello” to the screen whenever a value in that directory changes.

### Hidden Values

One thing that is not immediately apparent is that there are hidden directory structures within `etcd`. These are directories or keys that begin with an underscore.

These are not listed by the conventional `etcdctl` tools and you must know what you are looking for in order to find them.

For instance, there is a hidden directory called `/_coreos.com` that holds some internal information about `fleet`. You can see the hierarchy by explicitly asking for it:

    etcdctl ls --recursive /_coreos.com 

    /_coreos.com/fleet
    /_coreos.com/fleet/states
    /_coreos.com/fleet/states/apache@6666.service
    /_coreos.com/fleet/states/apache@6666.service/2ddbdb7c872b4bc59dd1969ac166501e
    /_coreos.com/fleet/states/apache@7777.service
    /_coreos.com/fleet/states/apache@7777.service/921a7241c31a499a97d43f785108b17c
    . . .

Another such directory structure is located within `/_etcd`:

    etcdctl ls --recursive /_etcd

    /_etcd/machines
    /_etcd/machines/27987f5eaac243f88ca6823b47012c5b
    /_etcd/machines/2ddbdb7c872b4bc59dd1969ac166501e
    /_etcd/machines/921a7241c31a499a97d43f785108b17c
    /_etcd/config

These function exactly like any other entry, with the only difference being that they do not show up in general listings. You can create them by simply starting your key or directory name with an underscore.

## Etcd HTTP/JSON API Usage

The other way to interacting with `etcd` is with the simple HTTP/JSON API.

To access the API, you can use a simple HTTP program like `curl`. You must supply the `-L` flag to follow any redirects that are passed back. From within your cluster, you can use the local `127.0.0.1` interface and port `4001` for most queries.

**Note** : To connect to `etcd` from within a Docker container, the address `http://172.17.42.1:4001` can be used. This can be useful for applications to update their configurations based on registered information.

The normal keyspace can be reached by going to `http://127.0.0.1:4001/v2/keys/` on any of the host machines. For instance, to get a listing of the top-level keys/directories, type:

    curl -L http://127.0.0.1:4001/v2/keys/

    {"action":"get","node":{"key":"/","dir":true,"nodes":[{"key":"/coreos.com","dir":true,"modifiedIndex":6,"createdIndex":6},{"key":"/services","dir":true,"modifiedIndex":333,"createdIndex":333}]}}

The trailing slash in the request is mandatory. It will not resolve correctly without it.

You can set or retrieve values using normal HTTP verbs.

To modify the behavior of these operations, you can pass in flags at the end of your request using the `?flag=value` syntax. Multiple flags can be separated by a `&` character.

For instance, to recursively list all of the keys, we could type:

    curl -L http://127.0.0.1:4001/v2/keys/?recursive=true

    {"action":"get","node":{"key":"/","dir":true,"nodes":[{"key":"/coreos.com","dir":true,"nodes":[{"key":"/coreos.com/updateengine","dir":true,"nodes":[{"key":"/coreos.com/updateengine/rebootlock","dir":true,"nodes":[{"key":"/coreos.com/updateengine/rebootlock/semaphore","value":"{\"semaphore\":1,\"max\":1,\"holders\":null}","modifiedIndex":6,"createdIndex":6}],"modifiedIndex":6,"createdIndex":6}],"modifiedIndex":6,"createdIndex":6}],"modifiedIndex":6,"createdIndex":6}. . .

Another useful piece of information that is accessible outside of the normal keyspace is version info, accessible here:

    curl -L http://127.0.0.1:4001/version

    etcd 0.4.6

You can view stats about each of the cluster leader’s relationship with each follower by visiting this endpoint:

    curl -L http://127.0.0.1:4001/v2/stats/leader

    {"leader":"921a7241c31a499a97d43f785108b17c","followers":{"27987f5eaac243f88ca6823b47012c5b":{"latency":{"current":1.607038,"average":1.3762888642395448,"standardDeviation":1.4404313533578545,"minimum":0.471432,"maximum":322.728852},"counts":{"fail":0,"success":98718}},"2ddbdb7c872b4bc59dd1969ac166501e":{"latency":{"current":1.584985,"average":1.1554367141497013,"standardDeviation":0.6872303198242179,"minimum":0.427485,"maximum":31.959235},"counts":{"fail":0,"success":98723}}}}

A similar operation can be used to detect stats about the machine you are currently on:

    curl -L http://127.0.0.1:4001/v2/stats/self

    {"name":"921a7241c31a499a97d43f785108b17c","state":"leader","startTime":"2014-09-11T16:42:03.035382298Z","leaderInfo":{"leader":"921a7241c31a499a97d43f785108b17c","uptime":"1h19m11.469872568s","startTime":"2014-09-12T19:47:25.242151859Z"},"recvAppendRequestCnt":1944480,"sendAppendRequestCnt":201817,"sendPkgRate":40.403374523779064,"sendBandwidthRate":3315.096879676072}

To see stats about operations that have been preformed, type:

    curl -L http://127.0.0.1:4001/v2/stats/store

    {"getsSuccess":78823,"getsFail":14,"setsSuccess":121370,"setsFail":4,"deleteSuccess":28,"deleteFail":32,"updateSuccess":20468,"updateFail":4,"createSuccess":39,"createFail":102340,"compareAndSwapSuccess":51169,"compareAndSwapFail":0,"compareAndDeleteSuccess":0,"compareAndDeleteFail":0,"expireCount":3,"watchers":6}

These are just a few of the operations that can be used to control `etcd` through the API.

## Etcd Configuration

The `etcd` service can be configured in a few different ways.

The first way is to pass in parameters with your `cloud-config` file that you use to bootstrap your nodes. In the bootstrapping guide, you saw a bit about how to do this:

    #cloud-config
    
    coreos:
      etcd:
        discovery: https://discovery.etcd.io/<token>
        addr: $private_ipv4:4001
        peer-addr: $private_ipv4:7001
    . . .

To see the options that you have available, use the `-h` flag with `etcd`:

    etcd -h

To include these options in your `cloud-config`, simply take off the leading dash and separate keys from values with a colon instead of an equal sign. So `-peer-addr=<host:port>` becomes `peer-addr: <host:port>`.

Upon reading the `cloud-config` file, CoreOS will translate these into environmental variables in a stub unit file, which is used to start the service.

Another way to adjust the settings for `etcd` is through the API. This is generally done using the `7001` port instead of the standard `4001` that is used for key queries.

For instance, you can get some of the current configuration values by typing:

    curl -L http://127.0.0.1:7001/v2/admin/config

    {"activeSize":9,"removeDelay":1800,"syncInterval":5}

You can change these values by passing in the new JSON as the data payload with a PUT operation:

    curl -L http://127.0.0.1:7001/v2/admin/config -XPUT -d '{"activeSize":9,"removeDelay":1800,"syncInterval":5}'

    {"activeSize":9,"removeDelay":1800,"syncInterval":5}

To get a list of machines, you can go to the `/v2/admin/machines` endpoint:

    curl -L http://127.0.0.1:7001/v2/admin/machines

    [{"name":"27987f5eaac243f88ca6823b47012c5b","state":"follower","clientURL":"http://10.132.248.121:4001","peerURL":"http://10.132.248.121:7001"},{"name":"2ddbdb7c872b4bc59dd1969ac166501e","state":"follower","clientURL":"http://10.132.252.38:4001","peerURL":"http://10.132.252.38:7001"},{"name":"921a7241c31a499a97d43f785108b17c","state":"leader","clientURL":"http://10.132.248.118:4001","peerURL":"http://10.132.248.118:7001"}]

This can be used to remove machines forcefully from the cluster with the DELETE method.

## Conclusion

As you can see, `etcd` can be used to store or retrieve information from any machine in your cluster. This allows you to synchronize data and provides a location for services to look for configuration data and connection details.

This is especially useful when building distributed systems because you can provide a simple endpoint that will be valid from any location within the cluster. By taking advantage of this resource, your services can dynamically configure themselves.
