---
author: Justin Ellingwood
date: 2017-04-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-mysql-group-replication-on-ubuntu-16-04
---

# How To Configure MySQL Group Replication on Ubuntu 16.04

## Introduction

MySQL replication reliably mirrors the data and operations from one database to another. Conventional replication involves a primary server configured to accept database write operations with secondary servers that copy and apply actions from the primary server’s log to their own data sets. These secondary servers can be used for reads, but are usually unable to execute data writes.

Group replication is a way of implementing a more flexible, fault-tolerant replication mechanism. This process involves establishing a pool of servers that are each involved in ensuring data is copied correctly. If the primary server experiences problems, member elections can select a new primary from the group. This allows the remaining nodes to continue operating, even in the face of problems. Membership negotiation, failure detection, and message delivery is provided through an implementation of the [Paxos concensus algorithm](https://en.wikipedia.org/wiki/Paxos_(computer_science)).

In this tutorial, we will set up MySQL group replication using a set of three Ubuntu 16.04 servers. The configuration will cover how to operate a single primary or multi-primary replication group.

## Prerequisites

To follow along, you will need a group of three Ubuntu 16.04 servers. On each of these servers, you will need to set up a non-root user with `sudo` privileges and configure a basic firewall. We will use the [initial server setup guide for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) to satisfy these requirements and get each server into a ready state.

The version of MySQL in Ubuntu’s default repositories does not include the group replication plugin we require. Thankfully, the MySQL project maintains their own repositories for the latest MySQL version which includes this component. Follow our guide on [installing the latest MySQL on Ubuntu 16.04](how-to-install-the-latest-mysql-on-ubuntu-16-04) to install a group replication-capable version of MySQL on each server.

## Generate a UUID to Identify the MySQL Group

Before opening the MySQL configuration file to configure the group replication settings, we need to generate a UUID that we can use to identify the MySQL group we will be creating.

On **mysqlmember1** , use the `uuidgen` command to generate a valid UUID for the group:

    uuidgen

    Output959cf631-538c-415d-8164-ca00181be227

Copy the value you receive. We will have to reference this in a moment when configuring a group name for our pool of servers.

## Set Up Group Replication in the MySQL Configuration File

Now we are ready to modify MySQL’s configuration file. Open up the main MySQL configuration file on **each MySQL server** :

    sudo nano /etc/mysql/my.cnf

By default, this file is only used to source additional files from subdirectories. We will have to add our own configuration **beneath** the `!includedir` lines. This allows us to easily override any settings from the included files.

To start, open up a section for the MySQL server components by including a `[mysqld]` header. Beneath this, we’ll paste in the settings we need for group replication. The `loose-` prefix allows MySQL to gracefully handle options it does not recognize gracefully without failure. We will need to fill in and customize many of these settings in a moment:

/etc/mysql/my.cnf

    . . .
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    
    [mysqld]
    
    # General replication settings
    gtid_mode = ON
    enforce_gtid_consistency = ON
    master_info_repository = TABLE
    relay_log_info_repository = TABLE
    binlog_checksum = NONE
    log_slave_updates = ON
    log_bin = binlog
    binlog_format = ROW
    transaction_write_set_extraction = XXHASH64
    loose-group_replication_bootstrap_group = OFF
    loose-group_replication_start_on_boot = OFF
    loose-group_replication_ssl_mode = REQUIRED
    loose-group_replication_recovery_use_ssl = 1
    
    # Shared replication group configuration
    loose-group_replication_group_name = ""
    loose-group_replication_ip_whitelist = ""
    loose-group_replication_group_seeds = ""
    
    # Single or Multi-primary mode? Uncomment these two lines
    # for multi-primary mode, where any host can accept writes
    #loose-group_replication_single_primary_mode = OFF
    #loose-group_replication_enforce_update_everywhere_checks = ON
    
    # Host specific replication configuration
    server_id = 
    bind-address = ""
    report_host = ""
    loose-group_replication_local_address = ""

We’ve divided the configuration above into four sections. Let’s go over them now.

### Boilerplate Group Replication Settings

The first section contains general settings required for group replication that require no modification:

/etc/mysql/my.cnf

    . . .
    # General replication settings
    gtid_mode = ON
    enforce_gtid_consistency = ON
    master_info_repository = TABLE
    relay_log_info_repository = TABLE
    binlog_checksum = NONE
    log_slave_updates = ON
    log_bin = binlog
    binlog_format = ROW
    transaction_write_set_extraction = XXHASH64
    loose-group_replication_bootstrap_group = OFF
    loose-group_replication_start_on_boot = OFF
    loose-group_replication_ssl_mode = REQUIRED
    loose-group_replication_recovery_use_ssl = 1
    . . .

These settings turn on global transaction IDs, configure the binary logging that is required for group replication, and configure SSL for the group. The configuration also sets up a few other items that aid in recovery and bootstrapping. You don’t need to modify anything in this section, so you can move on after pasting it in.

### Shared Group Replication Settings

The second section sets up shared settings for the group. We will have to customize this once and then use the same settings on each of our nodes. This includes the UUID for the group, a whitelist of acceptable members, and seed members to contact to get initial data from.

Set the `loose-group_replication_group_name` to the UUID you generated previously with the `uuidgen` command. Paste the UUID you copied as the value for this variable.

Next, set `loose-group_replication_ip_whitelist` to a list of all of your MySQL server IP addresses, separated by commas. The `loose-group_replication_group_seeds` setting should be almost the same as the whitelist, but should append the group replication port we will use to the end of each member. For this guide, we’ll use the recommended port of 33061 for the group replication:

/etc/mysql/my.cnf

    . . .
    # Shared replication group configuration
    loose-group_replication_group_name = "959cf631-538c-415d-8164-ca00181be227"
    loose-group_replication_ip_whitelist = "203.0.113.1,203.0.113.2,203.0.113.3"
    loose-group_replication_group_seeds = ""203.0.113.1:33061,203.0.113.2:33061,203.0.113.3:33061"
    . . .

This section should be the same on each of your MySQL servers, so make sure to copy it carefully.

### Choosing Single Primary or Multi-Primary

Next, you need to decide whether to configure a single-primary or multi-primary group. In some parts of the official MySQL documentation, this distinction is also referred to as “single” versus “multi-master” replication. In a single primary configuration, MySQL designates a single primary server (almost always the first group member) to handle write operations. A multi-primary group allows writes to any of the group members.

If you wish to configure a multi-primary group, uncomment the `loose-group_replication_single_primary_mode` and `loose-group_replication_enforce_update_everywhere_checks` directives. This will set up a multi-primary group. For a single primary group, just leave those two lines commented:

/etc/mysql/my.cnf

    . . .
    # Single or Multi-primary mode? Uncomment these two lines
    # for multi-primary mode, where any host can accept writes
    #loose-group_replication_single_primary_mode = OFF
    #loose-group_replication_enforce_update_everywhere_checks = ON
    . . .

**These settings must be the same on each of your MySQL servers.**

You can change this setting at a later time, but not without restarting your MySQL group. To change over to the new configuration, you will have to stop each of the MySQL instances in the group, start each member with the new settings, and then re-bootstrap the group replication. This will not affect any of your data, but requires a small window of downtime.

### Host-Specific Configuration Settings

The fourth section contains settings that will be different on each of the servers, including:

- The server ID
- The address to bind to
- The address to report to other members
- The local replication address and listening port

The `server_id` directive must be set to a unique number. For the first member, just set this to “1” and increment the number on each additional host. Set `bind-address` and `report_host` to the current server’s IP address so that the MySQL instance will listen for external connections and report its address correctly to other hosts. The `loose-group_replication_local_address` should also be set to the current server’s IP address with the group replication port (33061), appended to the IP address:

/etc/mysql/my.cnf

    . . .
    # Host specific replication configuration
    server_id = 1
    bind-address = "203.0.113.1"
    report_host = "203.0.113.1"
    loose-group_replication_local_address = "203.0.113.1:33061"

Complete this process on each of your MySQL servers.

When you are finished, double check that the shared replication settings are the same on each host and that the host-specific settings are customized for each host. Save and close the file on each host when you’re finished.

## Restart MySQL and Enable Remote Access

Our MySQL configuration file now contains the directives required to bootstrap MySQL group replication. To apply the new settings to the MySQL instance, restart the service on **each of your servers** with the following command:

    sudo systemctl restart mysql

In the MySQL configuration file, we configured the service to listen for external connections on the default port 3306. We also defined 33061 as the port that members should use for replication coordination.

We need to open up access to these two ports in our firewall, which we can do by typing:

    sudo ufw allow 33061
    sudo ufw allow 3306

With access to the MySQL ports open, we can create a replication user and enable the group replication plugin.

## Configure Replication User and Enable Group Replication Plugin

On **each of your MySQL servers** , log into your MySQL instance with the administrative user to start an interactive session:

    mysql -u root -p

You will be prompted for the MySQL administrative password. Afterwards, you will be dropped into a MySQL session. The first thing we need to do is create a replication user.

A replication user is required on each server to establish group replication. Because each server will have its own replication user, we need to turn off binary logging during the creation process. Otherwise, once replication begins, the group would attempt to propagate the replication user from the primary to the other servers, creating a conflict with the replication user already in place.

We will require SSL for the replication user, grant them replication privileges on the server, and then flush the privileges to implement the changes. Afterwards, we’ll re-enable binary logging to resume normal operations. Make sure to use a secure password when creating the replication user:

    SET SQL_LOG_BIN=0;
    CREATE USER 'repl'@'%' IDENTIFIED BY 'password' REQUIRE SSL;
    GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
    FLUSH PRIVILEGES;
    SET SQL_LOG_BIN=1;

Next, we need to set the `group_replication_recovery` channel to use our new replication user and the associated password. Each server will then use these credentials to authenticate to the group.

    CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';

With the replication user in place, we can enable the group replication plugin to prepare to initialize the group. Since we are using the latest version of MySQL, we can enable the plugin by typing:

    INSTALL PLUGIN group_replication SONAME 'group_replication.so';

Verify that the plugin is active by typing:

    SHOW PLUGINS;

    Output+----------------------------+----------+--------------------+----------------------+---------+
    | Name | Status | Type | Library | License |
    +----------------------------+----------+--------------------+----------------------+---------+
    | | | | | |
    | . . . | . . . | . . . | . . . | . . . |
    | | | | | |
    | group_replication | ACTIVE | GROUP REPLICATION | group_replication.so | GPL |
    +----------------------------+----------+--------------------+----------------------+---------+
    45 rows in set (0.00 sec)

The `group_replication` row confirms that the plugin was loaded and is currently active.

## Start Group Replication

Now that each MySQL server has a replication user configured and the group replication plugin enabled, we can begin to bring up our group.

### Bootstrap First Node

To start up the group, complete the following steps on **a single member of the group**.

Group members rely on existing members to send replication data, up-to-date membership lists, and other information when initially joining the group. Because of this, we need to use a slightly different procedure to start up the initial group member so that it knows not to expect this information from other members in its seed list.

If set, the `group_replication_bootstrap_group` variable tells a member that it shouldn’t expect to receive information from peers and should instead establish a new group and elect itself the primary member. Since the only situation where this is appropriate is when there are no existing group members, we will turn this functionality off immediately after bootstrapping the group:

    SET GLOBAL group_replication_bootstrap_group=ON;
    START GROUP_REPLICATION;
    SET GLOBAL group_replication_bootstrap_group=OFF;

The group should be started with this server as the only member. We can verify this by checking the entries within the `replication_group_members` table in the `performance_schema` database:

    SELECT * FROM performance_schema.replication_group_members;

You should see a single row representing the current host:

    Output+---------------------------+--------------------------------------+--------------+-------------+--------------+
    | CHANNEL_NAME | MEMBER_ID | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    | group_replication_applier | 13324ab7-1b01-11e7-9dd1-22b78adaa992 | 203.0.113.1 | 3306 | ONLINE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    1 row in set (0.00 sec)

The `ONLINE` value for `MEMBER_STATE` indicates that this node is fully operational within the group.

Next, create a test database and table to test our replication:

    CREATE DATABASE playground;
    CREATE TABLE playground.equipment ( id INT NOT NULL AUTO_INCREMENT, type VARCHAR(50), quant INT, color VARCHAR(25), PRIMARY KEY(id));
    INSERT INTO playground.equipment (type, quant, color) VALUES ("slide", 2, "blue");

Check out the content to make sure it was entered correctly:

    SELECT * FROM playground.equipment;

    Output+----+-------+-------+-------+
    | id | type | quant | color |
    +----+-------+-------+-------+
    | 1 | slide | 2 | blue |
    +----+-------+-------+-------+
    1 row in set (0.00 sec)

We’ve now verified that this server is a member of the group and that it has write capabilities. Now the other servers can join the group.

### Start Up the Remaining Nodes

Next, on the **second server** , start the group replication. Since we already have an active member, we don’t need to bootstrap the group and can just join it:

    START GROUP_REPLICATION;

On the **third server** , start group replication the same way:

    START GROUP_REPLICATION;

Check the membership list again. You should see three servers now:

    SELECT * FROM performance_schema.replication_group_members;

    Output+---------------------------+--------------------------------------+--------------+-------------+--------------+
    | CHANNEL_NAME | MEMBER_ID | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    | group_replication_applier | 13324ab7-1b01-11e7-9dd1-22b78adaa992 | 203.0.113.1 | 3306 | ONLINE |
    | group_replication_applier | 1ae4b211-1b01-11e7-9d89-ceb93e1d5494 | 203.0.113.2 | 3306 | ONLINE |
    | group_replication_applier | 157b597a-1b01-11e7-9d83-566a6de6dfef | 203.0.113.3 | 3306 | ONLINE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    3 rows in set (0.01 sec)

All members should have a `MEMBER_STATE` value of `ONLINE`. For a fresh group, if any of the nodes are listed as `RECOVERING` for more than a second or two, it’s usually an indication that an error has occurred or something has been misconfigured. Check the logs at `/var/log/mysql/error.log` to get additional information about what went wrong.

Check to see whether the test database information has been replicated over on the new members:

    SELECT * FROM playground.equipment;

    Output+----+-------+-------+-------+
    | id | type | quant | color |
    +----+-------+-------+-------+
    | 1 | slide | 2 | blue |
    +----+-------+-------+-------+
    1 row in set (0.01 sec)

If the data is available on the new members, it means that group replication is working correctly.

## Testing Write Capabilities of New Group Members

Next, we can try to write to the database from our new members. Whether this succeeds or not is a function of whether you chose to configure a single primary or multi-primary group.

### Testing Writes in a Single Primary Environment

In a single primary group, you should expect any write operations from the non-primary server to be rejected for consistency reasons. You can discover the current primary at any time with the following query:

    SHOW STATUS LIKE '%primary%';

    Output+----------------------------------+--------------------------------------+
    | Variable_name | Value |
    +----------------------------------+--------------------------------------+
    | group_replication_primary_member | 13324ab7-1b01-11e7-9dd1-22b78adaa992 |
    +----------------------------------+--------------------------------------+
    1 row in set (0.01 sec)

The value of the query will be a `MEMBER_ID` that you can match to a host by querying the group member list like we did before:

    SELECT * FROM performance_schema.replication_group_members;

    Output+---------------------------+--------------------------------------+--------------+-------------+--------------+
    | CHANNEL_NAME | MEMBER_ID | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    | group_replication_applier | 13324ab7-1b01-11e7-9dd1-22b78adaa992 | 203.0.113.1 | 3306 | ONLINE |
    | group_replication_applier | 1ae4b211-1b01-11e7-9d89-ceb93e1d5494 | 203.0.113.2 | 3306 | ONLINE |
    | group_replication_applier | 157b597a-1b01-11e7-9d83-566a6de6dfef | 203.0.113.3 | 3306 | ONLINE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    3 rows in set (0.01 sec)

In this example, we can see that the host at `203.0.113.1` is currently the primary server. If we attempt to write to the database from another member, we should expect the operation to fail:

    INSERT INTO playground.equipment (type, quant, color) VALUES ("swing", 10, "yellow");

    OutputERROR 1290 (HY000): The MySQL server is running with the --super-read-only option so it cannot execute this statement

This is expected since the group is currently configured with a single write-capable primary. If the primary server has issues and leaves the group, the group will automatically elect a new member to be the primary and accept writes.

### Testing Writes in a Multi-Primary Environment

For groups that have been configured in a multi-primary orientation, any member should be able to commit writes to the database.

You can double-check that your group is operating in multi-primary mode by checking the value of the `group_replication_primary_member` variable again:

    SHOW STATUS LIKE '%primary%';

    Output+----------------------------------+-------+
    | Variable_name | Value |
    +----------------------------------+-------+
    | group_replication_primary_member | |
    +----------------------------------+-------+
    1 row in set (0.02 sec)

If the variable is empty, this means that there is no designated primary host and that any member should be able to accept writes.

Test this on your **second server** by typing:

    INSERT INTO playground.equipment (type, quant, color) VALUES ("swing", 10, "yellow");

    OutputQuery OK, 1 row affected (0.00 sec)

The second server committed the write operation without any errors.

On the **third server** , query to see that the new item was added:

    SELECT * FROM playground.equipment;

    Output+----+-------+-------+--------+
    | id | type | quant | color |
    +----+-------+-------+--------+
    | 1 | slide | 2 | blue |
    | 2 | swing | 10 | yellow |
    +----+-------+-------+--------+
    2 rows in set (0.00 sec)

This confirms that the second server’s write was successfully replicated.

Now, test write capabilities on the third server by typing:

    INSERT INTO playground.equipment (type, quant, color) VALUES ("seesaw", 3, "green");

    OutputQuery OK, 1 row affected (0.02 sec)

Back on the **first server** , test to make sure that the write operations from both of the new members were replicated back:

    SELECT * FROM playground.equipment;

    Output+----+--------+-------+--------+
    | id | type | quant | color |
    +----+--------+-------+--------+
    | 1 | slide | 2 | blue |
    | 2 | swing | 10 | yellow |
    | 3 | seesaw | 3 | green |
    +----+--------+-------+--------+
    3 rows in set (0.01 sec)

This confirms that replication is working in each direction and that each member is capable of performing write operations.

## Bringing the Group Back Up

Once the group is bootstrapped, individual members can join and leave without affecting availability, so long as there are enough members to elect primary servers. However, if certain configuration changes are made (like switching between single and multi-primary environments), or all members of the group leave, you might need to re-bootstrap the group. You do this in exactly the same way that you did initially.

On your **first server** , set the `group_replciation_bootstrap_group` variable and then begin to initialize the group:

    SET GLOBAL GROUP_REPLICATION_BOOTSTRAP_GROUP=ON;
    START GROUP_REPLICATION;
    SET GLOBAL GROUP_REPLICATION_BOOTSTRAP_GROUP=OFF;

Once the first member has started the group, other members can join:

    START GROUP_REPLICATION;

Follow this process for additional members:

    START GROUP_REPLICATION;

The group should now be online with all members available:

    SELECT * FROM performance_schema.replication_group_members;

    Output+---------------------------+--------------------------------------+--------------+-------------+--------------+
    | CHANNEL_NAME | MEMBER_ID | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    | group_replication_applier | 13324ab7-1b01-11e7-9dd1-22b78adaa992 | 203.0.113.1 | 3306 | ONLINE |
    | group_replication_applier | 1ae4b211-1b01-11e7-9d89-ceb93e1d5494 | 203.0.113.2 | 3306 | ONLINE |
    | group_replication_applier | 157b597a-1b01-11e7-9d83-566a6de6dfef | 203.0.113.3 | 3306 | ONLINE |
    +---------------------------+--------------------------------------+--------------+-------------+--------------+
    3 rows in set (0.01 sec)

This process can be used to start the group again whenever necessary.

## Joining a Group Automatically When MySQL Starts

With the current settings, if a member server reboots, it will not automatically rejoin the group on start up. If you want members to automatically rejoin the group, you can modify the configuration file slightly.

The setting we will outline is helpful when you want members to automatically join when they boot up. However, there are some things you should be aware of:

First, this setting only affects when the MySQL instance itself is started. If the member is removed from the group because of timeout issues, but the MySQL instance remained online, the member will not automatically rejoin.

Secondly, having this setting enabled when first bootstrapping a group can be harmful. When there is not an existing group to join, the MySQL process will take a long while to start because it will attempt to contact other, non-existent members to initialize. Only after a lengthy timeout will it give up and start normally. Afterwards, you will have to use the procedure outlined above to bootstrap the group.

With the above caveats in mind, if you wish to configure nodes to join the group automatically when MySQL starts, open up the main MySQL configuration file:

    sudo nano /etc/mysql/my.cnf

Inside, find the `loose-group_replication_start_on_boot` variable, and set it to “ON”:

/etc/mysql/my.cnf

    
    [mysqld]
    . . .
    loose-group_replication_start_on_boot = ON
    . . .

Save and close the file when you are finished. The member should automatically attempt to join the group the next time its MySQL instance is started.

## Conclusion

In this tutorial, we covered how to configure MySQL group replication between three Ubuntu 16.04 servers. For single primary setups, the members will automatically elect a write-capable primary when necessary. For multi-primary groups, any member can perform writes and updates.

Group replication provides a flexible replication topology that allows members to join or leave at will while simultaneously providing guarantees about data consistency and message ordering. MySQL group replication may be a bit more complex to configure, but it provides capabilities not possible in traditional replication.
