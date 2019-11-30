---
author: Melissa Anderson
date: 2017-01-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-postgresql-against-automated-attacks
---

# How To Secure PostgreSQL Against Automated Attacks

## Introduction

It can be tempting to think because a server has just recently been brought up, sees little traffic, or offers nothing that seems of value to hackers that it will go unnoticed. However, many exploits are automated and specifically designed to look for common errors in configuration. These programs scan networks to discover servers, independent of the nature of the content.

Allowing remote connections is one of the common and more easily rectified situations that can lead to the exploit of a PostgreSQL database. This happens because certain configurations make it easy for programs like these to discover the server.

In this tutorial, we will show how to mitigate the specific risk posed by allowing remote connections. While this is an important first step, since servers can be compromised in other ways, we also recommend that you take additional measures to protect your data, outlined in the Additional Security Considerations.

## Background

To understand the specific risk we’re mitigating, imagine the server as a store. If the server is listening on any port at all, it’s a little like turning on a neon “Open” sign. It makes the server itself visible on the network, where automated scripts can find it.

We can think of each port as way to enter the store, like a door or a window. These entrances may be open, closed, locked, or broken depending on the state of the software that’s listening, but listening on a public interface means that a script seeking to get inside can start trying. For example, the script might be configured to attempt to log in with a default password on the chance that it hasn’t been changed. It might attempt known exploits of the listening daemon in case it hasn’t been patched. Whatever the script tries, if it is able to find a weakness and exploit it, then the intruder is inside and can get down to the serious business of compromising the server.

When we restrict a daemon like `postgresql` to listening locally, it’s like that particular door to the outside doesn’t exist. There’s no next step to try, at least with respect to Postgres. Firewalls and VPNs protect in a similar way. In this tutorial, we’ll focus on removing PostgreSQL as a publicly accessible doorway. To secure the daemon itself or the data as it is transmitted or stored, see Additional Security Considerations.

## Prerequisites

In this tutorial, we’ll use **two Ubuntu installations** , one for the database host and one as the client that will be connecting to the host remotely. Each one should have a `sudo` user and the firewall enabled. The guide, [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) can help you with this.

**One Ubuntu 16.04 PostgreSQL Database Host** :

If you haven’t install PostgreSQL yet, you can do so with the following commands:

    sudo apt-get update
    sudo apt-get install postgresql postgresql-contrib

**One Ubuntu 16.04 Client Machine** :  
In order to demonstrate and test allowing remote connections, we’ll use the PostgreSQL client, `psql`. To install it, use the following commands:

    sudo apt-get update
    sudo apt-get install postgresql-client

When these prerequisites are in place, you’re ready to follow along.

## Understanding the Default Configuration

When PostgreSQL is installed from the Ubuntu packages, by default it is restricted to listening on localhost. This default can be changed by overriding the `listen_addresses` in the `postgresql.conf` file, but the default prevents the server from automatically listening on a public interface.

In addition, the `pg_hba.conf` file only allows connections from Unix/Linux domain sockets and the local loopback address for the server, so it wouldn’t accept connections from external hosts:

replace

    # Put your actual configuration here
    # ----------------------------------
    #
    # If you want to allow non-local connections, you need to add more
    # "host" records. In that case you will also need to make PostgreSQL
    # listen on a non-local interface via the listen_addresses
    # configuration parameter, or via the -i or -h command line switches.
    
    # DO NOT DISABLE!
    # If you change this first entry you will need to make sure that the
    # database superuser can access the database using some other method.
    # Noninteractive access to all databases is required during automatic
    # maintenance (custom daily cronjobs, replication, and similar tasks).
    #
    # Database administrative login by Unix domain socket
    local all postgres peer
    
    # TYPE DATABASE USER ADDRESS METHOD
    
    # "local" is for Unix domain socket connections only
    local all all peer
    # IPv4 local connections:
    host all all 127.0.0.1/32 md5
    # IPv6 local connections:
    host all all ::1/128 md5

These defaults meet the objective of not listening on a public interface. If we leave them intact and keep our firewall up, we’re done! We can proceed directly to the Additional Security Considerations to learn how to secure data in transit.

If you need to connect from a remote host, we’ll cover how to override the defaults as well as the immediate steps you can take to protect the server in the next section.

## Configuring Remote Connections

For a production setup and before we start working with sensitive data, ideally we’ll have PostgreSQL traffic encrypted with SSL in transit, secured behind an external firewall, or protected by a virtual private network (VPN). As we work toward that, we can take the somewhat less complicated step of enabling a firewall on our database server and restricting access to the hosts that need it.

## Step 1 — Adding a User and Database

We’ll begin by adding a user and database that will allow us to test our work. To do so, we’ll use the PostgreSQL client, `psql`, to connect as the administrative user `postgres`. By passing the `-i` option to `sudo` we’ll run the postgres user’s login shell, which ensures that we load options from the `.profile` or other login-specific resources. `-u` species the postgres user:

    sudo -i -u postgres psql

Next, we’ll create a user with a password. Be sure to use secure password in place of the example highlighted below:

    CREATE USER sammy WITH PASSWORD 'password';

When the user is successfully created, we should receive the following output:

    OutputCREATE ROLE

**Note:** Since PostgreSQL 8.1, ROLES and USERS are synonymous. By convention, a role that has a password is still called a USER, while a role that does not is called a ROLE, so sometimes we will see ROLE in output where we might expect to see USER.

Next, we’ll create a database and grant full access to our new user. Best practices recommend that we grant users only the access that they need and only on the resources where they should have them, so depending on the use case, it may be appropriate to restrict a user’s access even more. You can learn more about permissions in the guide [How To Use Roles and Manage Grant Permissions in PostgreSQL on a VPS](how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2).

    CREATE DATABASE sammydb OWNER sammy;

When the database is created successfully, we should receive confirmation:

    OutputCREATE DATABASE

Now, that we’ve created a user and database, we’ll exit the monitor

    \q

After pressing ENTER, we’ll be at the command prompt and ready to continue.

## Step 2 — Configuring UFW

In the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) prerequisite, we enabled UFW and only allowed SSH connections. Before we start our configuration, let’s verify UFW’s status:

    sudo ufw status

**Note:** If the output indicates that the firewall is `inactive` we can activate it with:

    sudo ufw enable

Once it’s enabled, rerunning the status command, `sudo ufw status` will show the current rules. If necessary, be sure to allow SSH.

    sudo ufw allow OpenSSH

Unless we made changes to the prerequisites, the output should show that only OpenSSH is allowed:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Now that we’ve checked the firewall status, we will allow access to the PostgreSQL port and restrict it to the host or hosts we want to allow.

The command below will add the rule for the PostgreSQL default port, which is 5432. If you’ve changed that port, be sure to update it in the command below. Make sure that you’ve used the IP address of the server that needs access. If need be, re-run this command to add each client IP address that needs access:

    sudo ufw allow from client_ip_address to any port 5432

To double-check the rule, we can run `ufw status` again:

    sudo ufw status

    OutputTo Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    5432 ALLOW client_ip_address
    OpenSSH (v6) ALLOW Anywhere (v6)

**Note:** If you’re new to UFW, you can learn more in the guide [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands).

With this firewall rule in place, we’ll now configure PostgreSQL to listen on its public IP address. This requires a combination of two settings, an entry for the connecting host in `pg_hba.conf` and configuration of the listen\_addresses in `postgresql.conf`.

## Step 3 — Configuring the Allowed Hosts

We’ll start by adding the host entry in `pg_hba.conf`. If you have a different version of PostgreSQL installed, be sure to substitute it in the path below:

    sudo nano /etc/postgresql/9.5/main/pg_hba.conf

We’ll place the `host` lines under the comment block that describes how to allow non-local connections. We’ll also include a line with the public address of the database server so we can quickly test that our firewall is configured correctly. Be sure to substitute the hostname or IP address of _your_ machines in the example below.

Excerpt from pg\_hba.conf

    # If you want to allow non-local connections, you need to add more
    # "host" records. In that case you will also need to make PostgreSQL
    # listen on a non-local interface via the listen_addresses
    # configuration parameter, or via the -i or -h command line switches.
    host sammydb sammy client_ip_address/32 md5

Before we save our changes, let’s focus on each of the values in this line in case you want to change some of the options:

- **host** The first parameter, `host`, establishes that a TCP/IP connection will be used. 
- **database** `sammydb`The second column indicates which database/s the host can connect to. More than one database can be added by separating the names with commas.
- **user** `sammy` indicates the user that is allowed to make the connection. As with the database column, multiple users can be specified, separated by commas. 
- **address** The address specifies the client machine address or addresses and may contain a hostname, IP address range or other [special key words](https://www.postgresql.org/docs/9.5/static/auth-pg-hba-conf.html). In the example above, we’ve allowed just the single IP address of our client.
- **auth-method** Finally, the auth-method, `md5` indicates a [double-MD5-hashed password](https://www.postgresql.org/docs/9.5/static/auth-methods.html#AUTH-PASSWORD) will be supplied for authentication. You’ll need to do nothing more than supply the password that was created for the user connecting.

For a more complete discussion of these and additional settings, see [The `pg_hba.conf` File](https://www.postgresql.org/docs/9.5/static/auth-pg-hba-conf.html) PostgreSQL documentation.

Once you’re done, save and exit the file.

## Step 4 — Configuring the Listening Address

Next we’ll set the listen address in the `postgresql.conf` file:

    sudo nano /etc/postgresql/9.5/main/postgresql.conf

Find the `listen_addresses` line and below it, define your listen addresses, being sure to substitute the hostname or IP address of your database host. You may want to double-check that you’re using the public IP of the database server, not the connecting client:

postgresql.conf

    #listen_addresses = 'localhost' # what IP address(es) to listen on;
    listen_addresses = 'localhost,server_ip_address'

When you’re done save and exit the file.

## Step 5 — Restarting PostgreSQL

Our configuration changes won’t take effect until we restart the PostgreSQL daemon, so we’ll do that before we test:

    sudo systemctl restart postgresql

Since `systemctl` doesn’t provide feedback, we’ll check the status to make sure the daemon restarted successfully:

    sudo systemctl status postgresql

If the output contains “Active: active” and ends with something like the following, then the PostgreSQL daemon is running.

    Output...
    Jan 10 23:02:20 PostgreSQL systemd[1]: Started PostgreSQL RDBMS.

Now that we’ve restarted the daemon, we’re ready to test.

## Step 6 — Testing

Finally, let’s test that we can connect from our client machine. To do this, we’ll use `psql` with `-U` to specify the user, `-h` to specify the client’s IP address, and `-d` to specify the database, since we’ve tightened our security so that the `sammy` can only connect to a single database.

    psql -U sammy -h postgres_host_ip -d sammydb

If everything is configured correctly, you should receive the following prompt:

    OutputPassword for user sammy:

Enter the password you set earlier when you added the user `sammy` in the PostgreSQL monitor.

If you arrive at the following prompt, you’re successfully connected:

    [secondary_label]
    sammydb=>

This confirms that we can get through the firewall and connect to the database. We’ll exit now:

    \q

Since we’ve confirmed our configuration, we’ll finish by cleaning up.

## Step 7 — Removing the Test Database and User

Back on the host once we’ve finished testing the connection, we can use the following commands to delete the database and the user as well.

    sudo -i -u postgres psql

To delete the database:

    DROP DATABASE sammydb;

The action is confirmed by the following output:

    OutputDROP DATABASE

To delete the user:

    DROP USER sammy;

The success is confirmed by:

    OutputDROP ROLE

We’ll finish our cleanup by removing the host entry for the `sammydb` database from `pg_hba.conf` file since we no longer need it:

    sudo nano /etc/postgresql/9.5/main/pg_hba.conf

Line to remove from `pg_hba.conf`

    host sammydb sammy client_ip_address/32 md5

For the change to take effect, we’ll save and exit, then restart the database server:

    sudo systemctl restart postgresl

To be sure it restarted successfully, we’ll check the status:

    sudo systemctl status postgres

If we see “Active: active” we’ll know the restart succeeded.

At this point, we can move forward with configuring the application or service on the client that needs to connect remotely.

## Additional Security Considerations

This tutorial is intended to mitigate the risks posed by allowing unsecured remote connections to PostgreSQL, which is a common situation that inadvertently exposes PostgreSQL to exploits. Limiting access to the listening port to specific host/s doesn’t address other significant security considerations, such as how to encrypt your data in transit.

Before working with real data, we recommend reviewing the following resources and taking the appropriate steps for your use case.

- [Security within PostgreSQL](how-to-secure-postgresql-on-an-ubuntu-vps#security-within-postgresql): GRANT statements determine which users are allowed to access any particular database, while Roles establish the privileges of those users. In combination, they provide separation between multiple databases in a single installation.

- [Setting up SSL with PostgreSQL](http://www.postgresql.org/docs/9.5/interactive/ssl-tcp.html): Configuring SSL will encrypt data in transit. This protects data as it is sent.

- [Securing PostgreSQL TCP/IP Connections with SSH Tunnels](https://www.postgresql.org/docs/9.5/static/ssh-tunnels.html): SSH Tunnels are useful when connecting with clients that are not SSL-capable. In almost any other situation, it is preferable to set up SSL with Postgres.

## Conclusion

In this tutorial, we’ve taken essential steps to prevent advertising our PostgreSQL installation by configuring the server’s firewall to allow connections only from hosts that require access and by configuring PostgreSQL to accept connections only from those hosts. This mitigates the risk of certain kinds of attacks. This is just the first step to securing data, and we recommend that review and implement additional security measures outlined above.
