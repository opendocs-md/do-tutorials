---
author: bsder, Hathy A
date: 2018-07-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-apache-kafka-on-ubuntu-18-04
---

# How To Install Apache Kafka on Ubuntu 18.04

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Apache Kafka](http://kafka.apache.org/) is a popular distributed message broker designed to efficiently handle large volumes of real-time data. A Kafka cluster is not only highly scalable and fault-tolerant, but it also has a much higher throughput compared to other message brokers such as [ActiveMQ](http://activemq.apache.org/) and [RabbitMQ](https://www.rabbitmq.com/). Though it is generally used as a _publish/subscribe_ messaging system, a lot of organizations also use it for log aggregation because it offers persistent storage for published messages.

A publish/subscribe messaging system allows one or more producers to publish messages without considering the number of consumers or how they will process the messages. Subscribed clients are notified automatically about updates and the creation of new messages. This system is more efficient and scalable than systems where clients poll periodically to determine if new messages are available.

In this tutorial, you will install and use Apache Kafka 2.1.1 on Ubuntu 18.04.

## Prerequisites

To follow along, you will need:

- One Ubuntu 18.04 server and a non-root user with sudo privileges. Follow the steps specified in this [guide](initial-server-setup-with-ubuntu-18-04) if you do not have a non-root user set up. 
- At least 4GB of RAM on the server. Installations without this amount of RAM may cause the Kafka service to fail, with the [Java virtual machine (JVM)](https://en.wikipedia.org/wiki/Java_virtual_machine) throwing an “Out Of Memory” exception during startup.
- [OpenJDK](http://openjdk.java.net/) 8 installed on your server. To install this version, follow [these instructions](how-to-install-java-with-apt-on-ubuntu-18-04#installing-specific-versions-of-openjdk) on installing specific versions of OpenJDK. Kafka is written in Java, so it requires a JVM; however, its startup shell script has a version detection bug that causes it to fail to start with JVM versions above 8.

## Step 1 — Creating a User for Kafka

Since Kafka can handle requests over a network, you should create a dedicated user for it. This minimizes damage to your Ubuntu machine should the Kafka server be compromised. We will create a dedicated **kafka** user in this step, but you should create a different non-root user to perform other tasks on this server once you have finished setting up Kafka.

Logged in as your non-root sudo user, create a user called **kafka** with the `useradd` command:

    sudo useradd kafka -m

The `-m` flag ensures that a home directory will be created for the user. This home directory, `/home/kafka`, will act as our workspace directory for executing commands in the sections below.

Set the password using `passwd`:

    sudo passwd kafka

Add the **kafka** user to the `sudo` group with the `adduser` command, so that it has the privileges required to install Kafka’s dependencies:

    sudo adduser kafka sudo

Your **kafka** user is now ready. Log into this account using `su`:

    su -l kafka

Now that we’ve created the Kafka-specific user, we can move on to downloading and extracting the Kafka binaries.

## Step 2 — Downloading and Extracting the Kafka Binaries

Let’s download and extract the Kafka binaries into dedicated folders in our **kafka** user’s home directory.

To start, create a directory in `/home/kafka` called `Downloads` to store your downloads:

    mkdir ~/Downloads

Use `curl` to download the Kafka binaries:

    curl "https://www.apache.org/dist/kafka/2.1.1/kafka_2.11-2.1.1.tgz" -o ~/Downloads/kafka.tgz

Create a directory called `kafka` and change to this directory. This will be the base directory of the Kafka installation:

    mkdir ~/kafka && cd ~/kafka

Extract the archive you downloaded using the `tar` command:

    tar -xvzf ~/Downloads/kafka.tgz --strip 1

We specify the `--strip 1` flag to ensure that the archive’s contents are extracted in `~/kafka/` itself and not in another directory (such as `~/kafka/kafka_2.11-2.1.1/`) inside of it.

Now that we’ve downloaded and extracted the binaries successfully, we can move on configuring to Kafka to allow for topic deletion.

## Step 3 — Configuring the Kafka Server

Kafka’s default behavior will not allow us to delete a _topic_, the category, group, or feed name to which messages can be published. To modify this, let’s edit the configuration file.

Kafka’s configuration options are specified in `server.properties`. Open this file with `nano` or your favorite editor:

    nano ~/kafka/config/server.properties

Let’s add a setting that will allow us to delete Kafka topics. Add the following to the bottom of the file:

~/kafka/config/server.properties

    delete.topic.enable = true

Save the file, and exit `nano`. Now that we’ve configured Kafka, we can move on to creating systemd unit files for running and enabling it on startup.

## Step 4 — Creating Systemd Unit Files and Starting the Kafka Server

In this section, we will create [systemd unit files](understanding-systemd-units-and-unit-files) for the Kafka service. This will help us perform common service actions such as starting, stopping, and restarting Kafka in a manner consistent with other Linux services.

Zookeeper is a service that Kafka uses to manage its cluster state and configurations. It is commonly used in many distributed systems as an integral component. If you would like to know more about it, visit the official [Zookeeper docs](https://zookeeper.apache.org/doc/current/index.html).

Create the unit file for `zookeeper`:

    sudo nano /etc/systemd/system/zookeeper.service

Enter the following unit definition into the file:

/etc/systemd/system/zookeeper.service

    [Unit]
    Requires=network.target remote-fs.target
    After=network.target remote-fs.target
    
    [Service]
    Type=simple
    User=kafka
    ExecStart=/home/kafka/kafka/bin/zookeeper-server-start.sh /home/kafka/kafka/config/zookeeper.properties
    ExecStop=/home/kafka/kafka/bin/zookeeper-server-stop.sh
    Restart=on-abnormal
    
    [Install]
    WantedBy=multi-user.target

The `[Unit]` section specifies that Zookeeper requires networking and the filesystem to be ready before it can start.

The `[Service]` section specifies that systemd should use the `zookeeper-server-start.sh` and `zookeeper-server-stop.sh` shell files for starting and stopping the service. It also specifies that Zookeeper should be restarted automatically if it exits abnormally.

Next, create the systemd service file for `kafka`:

    sudo nano /etc/systemd/system/kafka.service

Enter the following unit definition into the file:

/etc/systemd/system/kafka.service

    [Unit]
    Requires=zookeeper.service
    After=zookeeper.service
    
    [Service]
    Type=simple
    User=kafka
    ExecStart=/bin/sh -c '/home/kafka/kafka/bin/kafka-server-start.sh /home/kafka/kafka/config/server.properties > /home/kafka/kafka/kafka.log 2>&1'
    ExecStop=/home/kafka/kafka/bin/kafka-server-stop.sh
    Restart=on-abnormal
    
    [Install]
    WantedBy=multi-user.target

The `[Unit]` section specifies that this unit file depends on `zookeeper.service`. This will ensure that `zookeeper` gets started automatically when the `kafka` service starts.

The `[Service]` section specifies that systemd should use the `kafka-server-start.sh` and `kafka-server-stop.sh` shell files for starting and stopping the service. It also specifies that Kafka should be restarted automatically if it exits abnormally.

Now that the units have been defined, start Kafka with the following command:

    sudo systemctl start kafka

To ensure that the server has started successfully, check the journal logs for the `kafka` unit:

    sudo journalctl -u kafka

You should see output similar to the following:

    OutputJul 17 18:38:59 kafka-ubuntu systemd[1]: Started kafka.service.

You now have a Kafka server listening on port `9092`.

While we have started the `kafka` service, if we were to reboot our server, it would not be started automatically. To enable `kafka` on server boot, run:

    sudo systemctl enable kafka

Now that we’ve started and enabled the services, let’s check the installation.

## Step 5 — Testing the Installation

Let’s publish and consume a **“Hello World”** message to make sure the Kafka server is behaving correctly. Publishing messages in Kafka requires:

- A _producer_, which enables the publication of records and data to topics. 
- A _consumer_, which reads messages and data from topics.

First, create a topic named `TutorialTopic` by typing:

    ~/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic TutorialTopic

You can create a producer from the command line using the `kafka-console-producer.sh` script. It expects the Kafka server’s hostname, port, and a topic name as arguments.

Publish the string `"Hello, World"` to the `TutorialTopic` topic by typing:

    echo "Hello, World" | ~/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic TutorialTopic > /dev/null

Next, you can create a Kafka consumer using the `kafka-console-consumer.sh` script. It expects the ZooKeeper server’s hostname and port, along with a topic name as arguments.

The following command consumes messages from `TutorialTopic`. Note the use of the `--from-beginning` flag, which allows the consumption of messages that were published before the consumer was started:

    ~/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic TutorialTopic --from-beginning

If there are no configuration issues, you should see `Hello, World` in your terminal:

    OutputHello, World

The script will continue to run, waiting for more messages to be published to the topic. Feel free to open a new terminal and start a producer to publish a few more messages. You should be able to see them all in the consumer’s output.

When you are done testing, press `CTRL+C` to stop the consumer script. Now that we have tested the installation, let’s move on to installing KafkaT.

## Step 6 — Install KafkaT (Optional)

[KafkaT](https://github.com/airbnb/kafkat) is a tool from Airbnb that makes it easier for you to view details about your Kafka cluster and perform certain administrative tasks from the command line. Because it is a Ruby gem, you will need Ruby to use it. You will also need the `build-essential` package to be able to build the other gems it depends on. Install them using `apt`:

    sudo apt install ruby ruby-dev build-essential

You can now install KafkaT using the gem command:

    sudo gem install kafkat

KafkaT uses `.kafkatcfg` as the configuration file to determine the installation and log directories of your Kafka server. It should also have an entry pointing KafkaT to your ZooKeeper instance.

Create a new file called `.kafkatcfg`:

    nano ~/.kafkatcfg

Add the following lines to specify the required information about your Kafka server and Zookeeper instance:

~/.kafkatcfg

    {
      "kafka_path": "~/kafka",
      "log_path": "/tmp/kafka-logs",
      "zk_path": "localhost:2181"
    }

You are now ready to use KafkaT. For a start, here’s how you would use it to view details about all Kafka partitions:

    kafkat partitions

You will see the following output:

    OutputTopic Partition Leader Replicas ISRs    
    TutorialTopic 0 0 [0] [0]
    __consumer_offsets 0 0 [0] [0]
    ...
    ...

You will see `TutorialTopic`, as well as ` __consumer_offsets`, an internal topic used by Kafka for storing client-related information. You can safely ignore lines starting with `__ consumer_offsets`.

To learn more about KafkaT, refer to its [GitHub repository](https://github.com/airbnb/kafkat).

## Step 7 — Setting Up a Multi-Node Cluster (Optional)

If you want to create a multi-broker cluster using more Ubuntu 18.04 machines, you should repeat Step 1, Step 4, and Step 5 on each of the new machines. Additionally, you should make the following changes in the `server.properties` file for each:

- The value of the `broker.id` property should be changed such that it is unique throughout the cluster. This property uniquely identifies each server in the cluster and can have any string as its value. For example, `"server1"`, `"server2"`, etc. 

- The value of the `zookeeper.connect` property should be changed such that all nodes point to the same ZooKeeper instance. This property specifies the Zookeeper instance’s address and follows the `<HOSTNAME/IP_ADDRESS>:<PORT>` format. For example, `"203.0.113.0:2181"`, `"203.0.113.1:2181"` etc. 

If you want to have multiple ZooKeeper instances for your cluster, the value of the `zookeeper.connect` property on each node should be an identical, comma-separated string listing the IP addresses and port numbers of all the ZooKeeper instances.

## Step 8 — Restricting the Kafka User

Now that all of the installations are done, you can remove the **kafka** user’s admin privileges. Before you do so, log out and log back in as any other non-root sudo user. If you are still running the same shell session you started this tutorial with, simply type `exit`.

Remove the **kafka** user from the sudo group:

    sudo deluser kafka sudo

To further improve your Kafka server’s security, lock the **kafka** user’s password using the `passwd` command. This makes sure that nobody can directly log into the server using this account:

    sudo passwd kafka -l

At this point, only root or a sudo user can log in as `kafka` by typing in the following command:

    sudo su - kafka

In the future, if you want to unlock it, use `passwd` with the `-u` option:

    sudo passwd kafka -u

You have now successfully restricted the **kafka** user’s admin privileges.

## Conclusion

You now have Apache Kafka running securely on your Ubuntu server. You can make use of it in your projects by creating Kafka producers and consumers using [Kafka clients](https://cwiki.apache.org/confluence/display/KAFKA/Clients), which are available for most programming languages. To learn more about Kafka, you can also consult its [documentation](http://kafka.apache.org/documentation.html).
