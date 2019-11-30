---
author: bsder
date: 2019-03-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-import-and-migrate-your-apache-kafka-data-on-centos-7
---

# How To Back Up, Import, and Migrate Your Apache Kafka Data on CentOS 7

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Backing up your [Apache Kafka](http://kafka.apache.org/) data is an important practice that will help you recover from unintended data loss or bad data added to the cluster due to user error. Data dumps of cluster and topic data are an efficient way to perform backups and restorations.

Importing and migrating your backed up data to a separate server is helpful in situations where your Kafka instance becomes unusable due to server hardware or networking failures and you need to create a new Kafka instance with your old data. Importing and migrating backed up data is also useful when you are moving the Kafka instance to an upgraded or downgraded server due to a change in resource usage.

In this tutorial, you will back up, import, and migrate your Kafka data on a single CentOS 7 installation as well as on multiple CentOS 7 installations on separate servers. ZooKeeper is a critical component of Kafka’s operation. It stores information about cluster state such as consumer data, partition data, and the state of other brokers in the cluster. As such, you will also back up ZooKeeper’s data in this tutorial.

## Prerequisites

To follow along, you will need:

- A CentOS 7 server with at least 4GB of RAM and a non-root sudo user set up by following [this tutorial](initial-server-setup-with-centos-7).
- A CentOS 7 server with Apache Kafka installed, to act as the source of the backup. Follow the [How To Install Apache Kafka on CentOS 7](how-to-install-apache-kafka-on-centos-7) guide to set up your Kafka installation, if Kafka isn’t already installed on the source server.
- [OpenJDK](http://openjdk.java.net/) 8 installed on the server. To install this version, follow these [instructions](how-to-install-java-on-centos-and-fedora#install-openjdk-8) on installing specific versions of OpenJDK.
- Optional for Step 7 — Another CentOS 7 server with Apache Kafka installed, to act as the destination of the backup. Follow the article link in the previous prerequisite to install Kafka on the destination server. This prerequisite is required only if you are moving your Kafka data from one server to another. If you want to back up and import your Kafka data to a single server, you can skip this prerequisite.

## Step 1 — Creating a Test Topic and Adding Messages

A Kafka **message** is the most basic unit of data storage in Kafka and is the entity that you will publish to and subscribe from Kafka. A Kafka **topic** is like a container for a group of related messages. When you subscribe to a particular topic, you will receive only messages that were published to that particular topic. In this section you will log in to the server that you would like to back up (the source server) and add a Kafka topic and a message so that you have some data populated for the backup.

This tutorial assumes you have installed Kafka in the home directory of the **kafka** user (`/home/kafka/kafka`). If your installation is in a different directory, modify the `~/kafka` part in the following commands with your Kafka installation’s path, and for the commands throughout the rest of this tutorial.

SSH into the source server by executing:

    ssh sammy@source_server_ip

Run the following command to log in as the **kafka** user:

    sudo -iu kafka

Create a topic named `BackupTopic` using the `kafka-topics.sh` shell utility file in your Kafka installation’s bin directory, by typing:

    ~/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic BackupTopic

Publish the string `"Test Message 1"` to the `BackupTopic` topic by using the `~/kafka/bin/kafka-console-producer.sh` shell utility script.

If you would like to add additional messages here, you can do so now.

    echo "Test Message 1" | ~/kafka/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic BackupTopic > /dev/null

The `~/kafka/bin/kafka-console-producer.sh` file allows you to publish messages directly from the command line. Typically, you would publish messages using a Kafka client library from within your program, but since that involves different setups for different programming languages, you can use the shell script as a language-independent way of publishing messages during testing or while performing administrative tasks. The `--topic` flag specifies the topic that you will publish the message to.

Next, verify that the `kafka-console-producer.sh` script has published the message(s) by running the following command:

    ~/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic BackupTopic --from-beginning

The `~/kafka/bin/kafka-console-consumer.sh` shell script starts the consumer. Once started, it will subscribe to messages from the topic that you published in the `"Test Message 1"` message in the previous command. The `--from-beginning` flag in the command allows consuming messages that were published before the consumer was started. Without the flag enabled, only messages published after the consumer was started will appear. On running the command, you will see the following output in the terminal:

    OutputTest Message 1

Press `CTRL+C` to stop the consumer.

You’ve created some test data and verified that it’s persisted. Now you can back up the state data in the next section.

## Step 2 — Backing Up the ZooKeeper State Data

Before backing up the actual Kafka data, you need to back up the cluster state stored in ZooKeeper.

ZooKeeper stores its data in the directory specified by the `dataDir` field in the `~/kafka/config/zookeeper.properties` configuration file. You need to read the value of this field to determine the directory to back up. By default, `dataDir` points to the `/tmp/zookeeper` directory. If the value is different in your installation, replace `/tmp/zookeeper` with that value in the following commands.

Here is an example output of the `~/kafka/config/zookeeper.properties` file:

~/kafka/config/zookeeper.properties

    ...
    ...
    ...
    # the directory where the snapshot is stored.
    dataDir=/tmp/zookeeper
    # the port at which the clients will connect
    clientPort=2181
    # disable the per-ip limit on the number of connections since this is a non-production config
    maxClientCnxns=0
    ...
    ...
    ...

Now that you have the path to the directory, you can create a compressed archive file of its contents. Compressed archive files are a better option over regular archive files to save disk space. Run the following command:

    tar -czf /home/kafka/zookeeper-backup.tar.gz /tmp/zookeeper/*

The command’s output `tar: Removing leading / from member names` you can safely ignore.

The `-c` and `-z` flags tell `tar` to create an archive and apply gzip compression to the archive. The `-f` flag specifies the name of the output compressed archive file, which is `zookeeper-backup.tar.gz` in this case.

You can run `ls` in your current directory to see `zookeeper-backup.tar.gz` as part of your output.

You have now successfully backed up the ZooKeeper data. In the next section, you will back up the actual Kafka data.

## Step 3 — Backing Up the Kafka Topics and Messages

In this section, you will back up Kafka’s data directory into a compressed tar file like you did for ZooKeeper in the previous step.

Kafka stores topics, messages, and internal files in the directory that the `log.dirs` field specifies in the `~/kafka/config/server.properties` configuration file. You need to read the value of this field to determine the directory to back up. By default and in your current installation, `log.dirs` points to the `/tmp/kafka-logs` directory. If the value is different in your installation, replace `/tmp/kafka-logs` in the following commands with the correct value.

Here is an example output of the `~/kafka/config/server.properties` file:

~/kafka/config/server.properties

    ...
    ...
    ...
    ############################# Log Basics #############################
    
    # A comma separated list of directories under which to store log files
    log.dirs=/tmp/kafka-logs
    
    # The default number of log partitions per topic. More partitions allow greater
    # parallelism for consumption, but this will also result in more files across
    # the brokers.
    num.partitions=1
    
    # The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
    # This value is recommended to be increased for installations with data dirs located in RAID array.
    num.recovery.threads.per.data.dir=1
    ...
    ...
    ...

First, stop the Kafka service so that the data in the `log.dirs` directory is in a consistent state when creating the archive with `tar`. To do this, return to your server’s non-root user by typing `exit` and then run the following command:

    sudo systemctl stop kafka

After stopping the Kafka service, log back in as your **kafka** user with:

    sudo -iu kafka

It is necessary to stop/start the Kafka and ZooKeeper services as your non-root sudo user because in the Apache Kafka installation prerequisite you restricted the **kafka** user as a security precaution. This step in the prerequisite disables sudo access for the **kafka** user, which leads to commands failing to execute.

Now, create a compressed archive file of the directory’s contents by running the following command:

    tar -czf /home/kafka/kafka-backup.tar.gz /tmp/kafka-logs/*

Once again, you can safely ignore the command’s output (`tar: Removing leading / from member names`).

You can run `ls` in the current directory to see `kafka-backup.tar.gz` as part of the output.

You can start the Kafka service again — if you do not want to restore the data immediately — by typing `exit`, to switch to your non-root sudo user, and then running:

    sudo systemctl start kafka

Log back in as your **kafka** user:

    sudo -iu kafka

You have successfully backed up the Kafka data. You can now proceed to the next section, where you will be restoring the cluster state data stored in ZooKeeper.

## Step 4 — Restoring the ZooKeeper Data

In this section you will restore the cluster state data that Kafka creates and manages internally when the user performs operations such as creating a topic, adding/removing additional nodes, and adding and consuming messages. You will restore the data to your existing source installation by deleting the ZooKeeper data directory and restoring the contents of the `zookeeper-backup.tar.gz` file. If you want to restore data to a different server, see Step 7.

You need to stop the Kafka and ZooKeeper services as a precaution against the data directories receiving invalid data during the restoration process.

First, stop the Kafka service by typing `exit`, to switch to your non-root sudo user, and then running:

    sudo systemctl stop kafka

Next, stop the ZooKeeper service:

    sudo systemctl stop zookeeper

Log back in as your **kafka** user:

    sudo -iu kafka

You can then safely delete the existing cluster data directory with the following command:

    rm -r /tmp/zookeeper/*

Now restore the data you backed up in Step 2:

    tar -C /tmp/zookeeper -xzf /home/kafka/zookeeper-backup.tar.gz --strip-components 2

The `-C` flag tells `tar` to change to the directory `/tmp/zookeeper` before extracting the data. You specify the `--strip 2` flag to make `tar` extract the archive’s contents in `/tmp/zookeeper/` itself and not in another directory (such as `/tmp/zookeeper/tmp/zookeeper/`) inside of it.

You have restored the cluster state data successfully. Now, you can proceed to the Kafka data restoration process in the next section.

## Step 5 — Restoring the Kafka Data

In this section you will restore the backed up Kafka data to your existing source installation (or the destination server if you have followed the optional Step 7) by deleting the Kafka data directory and restoring the compressed archive file. This will allow you to verify that restoration works successfully.

You can safely delete the existing Kafka data directory with the following command:

    rm -r /tmp/kafka-logs/*

Now that you have deleted the data, your Kafka installation resembles a fresh installation with no topics or messages present in it. To restore your backed up data, extract the files by running:

    tar -C /tmp/kafka-logs -xzf /home/kafka/kafka-backup.tar.gz --strip-components 2

The `-C` flag tells `tar` to change to the directory `/tmp/kafka-logs` before extracting the data. You specify the `--strip 2` flag to ensure that the archive’s contents are extracted in `/tmp/kafka-logs/` itself and not in another directory (such as `/tmp/kafka-logs/kafka-logs/`) inside of it.

Now that you have extracted the data successfully, you can start the Kafka and ZooKeeper services again by typing `exit`, to switch to your non-root sudo user, and then executing:

    sudo systemctl start kafka

Start the ZooKeeper service with:

    sudo systemctl start zookeeper

Log back in as your **kafka** user:

    sudo -iu kafka

You have restored the `kafka` data, you can move on to verifying that the restoration is successful in the next section.

## Step 6 — Verifying the Restoration

To test the restoration of the Kafka data, you will consume messages from the topic you created in Step 1.

Wait a few minutes for Kafka to start up and then execute the following command to read messages from the `BackupTopic`:

    ~/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic BackupTopic --from-beginning

If you get a warning like the following, you need to wait for Kafka to start fully:

    Output[2018-09-13 15:52:45,234] WARN [Consumer clientId=consumer-1, groupId=console-consumer-87747] Connection to node -1 could not be established. Broker may not be available. (org.apache.kafka.clients.NetworkClient)

Retry the previous command in another few minutes or run `sudo systemctl restart kafka` as your non-root sudo user. If there are no issues in the restoration, you will see the following output:

    OutputTest Message 1

If you do not see this message, you can check if you missed out any commands in the previous section and execute them.

Now that you have verified the restored Kafka data, this means you have successfully backed up and restored your data in a single Kafka installation. You can continue to Step 7 to see how to migrate the cluster and topics data to an installation in another server.

## Step 7 — Migrating and Restoring the Backup to Another Kafka Server (Optional)

In this section, you will migrate the backed up data from the source Kafka server to the destination Kafka server. To do so, you will first use the `scp` command to download the compressed `tar.gz` files to your local system. You will then use `scp` again to push the files to the destination server. Once the files are present in the destination server, you can follow the steps used previously to restore the backup and verify that the migration is successful.

You are downloading the backup files locally and then uploading them to the destination server, instead of copying it directly from your source to destination server, because the destination server will not have your source server’s SSH key in its `/home/sammy/.ssh/authorized_keys` file and cannot connect to and from the source server. Your local machine can connect to both servers however, saving you an additional step of setting up SSH access from the source to destination server.

Download the `zookeeper-backup.tar.gz` and `kafka-backup.tar.gz` files to your local machine by executing:

    scp sammy@source_server_ip:/home/kafka/zookeeper-backup.tar.gz .

You will see output similar to:

    Outputzookeeper-backup.tar.gz 100% 68KB 128.0KB/s 00:00

Now run the following command to download the `kafka-backup.tar.gz` file to your local machine:

    scp sammy@source_server_ip:/home/kafka/kafka-backup.tar.gz .

You will see the following output:

    Outputkafka-backup.tar.gz 100% 1031KB 488.3KB/s 00:02

Run `ls` in the current directory of your local machine, you will see both of the files:

    Outputkafka-backup.tar.gz zookeeper.tar.gz

Run the following command to transfer the `zookeeper-backup.tar.gz` file to `/home/kafka/` of the destination server:

    scp zookeeper-backup.tar.gz sammy@destination_server_ip:/home/sammy/zookeeper-backup.tar.gz

Now run the following command to transfer the `kafka-backup.tar.gz` file to `/home/kafka/` of the destination server:

    scp kafka-backup.tar.gz sammy@destination_server_ip:/home/sammy/kafka-backup.tar.gz

You have uploaded the backup files to the destination server successfully. Since the files are in the `/home/sammy/` directory and do not have the correct permissions for access by the **kafka** user, you can move the files to the `/home/kafka/` directory and change their permissions.

SSH into the destination server by executing:

    ssh sammy@destination_server_ip

Now move `zookeeper-backup.tar.gz` to `/home/kafka/` by executing:

    sudo mv zookeeper-backup.tar.gz /home/sammy/zookeeper-backup.tar.gz

Similarly, run the following command to copy `kafka-backup.tar.gz` to `/home/kafka/`:

    sudo mv kafka-backup.tar.gz /home/kafka/kafka-backup.tar.gz

Change the owner of the backup files by running the following command:

    sudo chown kafka /home/kafka/zookeeper-backup.tar.gz /home/kafka/kafka-backup.tar.gz

The previous `mv` and `chown` commands will not display any output.

Now that the backup files are present in the destination server at the correct directory, follow the commands listed in Steps 4 to 6 of this tutorial to restore and verify the data for your destination server.

## Conclusion

In this tutorial, you backed up, imported, and migrated your Kafka topics and messages from both the same installation and installations on separate servers. If you would like to learn more about other useful administrative tasks in Kafka, you can consult the [operations](http://kafka.apache.org/documentation/#operations) section of Kafka’s official documentation.

To store backed up files such as `zookeeper-backup.tar.gz` and `kafka-backup.tar.gz` remotely, you can explore [Digital Ocean Spaces](https://www.digitalocean.com/docs/spaces/). If Kafka is the only service running on your server, you can also explore other backup methods such as full instance [backups](https://www.digitalocean.com/docs/images/backups/how-to/).
