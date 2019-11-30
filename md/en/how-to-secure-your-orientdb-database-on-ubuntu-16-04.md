---
author: finid
date: 2017-03-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-your-orientdb-database-on-ubuntu-16-04
---

# How To Secure Your OrientDB Database on Ubuntu 16.04

## Introduction

OrientDB is a multi-model, NoSQL database with support for document and graph databases. It is a Java application and can run on any operating system. It’s also fully ACID-complaint with support for multi-master replication.

Out of the box, OrientDB has a very good security posture in that connecting to the server instance and connecting to a database both require authentication. Other security schemes, like Kerberos authentication and LDAP users are also supported, but they involve setting up additional software systems.

In this article, we’ll focus instead on securing an installation of the Community edition of OrientDB using only the resources available by default. Specifically, you’ll encrypt the OrientDB database, restrict access to the OrientDB web server and server instance, and manage OrientDB database accounts from both the web UI and console.

## Prerequisites

To follow this tutorial, you will need the following:

- One Ubuntu 16.04 server set up with a sudo non-root user and firewall, as in our [Initial Server Setup on Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide.
- OrientDB Community Edition installed on the server using [this OrientDB installation guide for Ubuntu 16.04](how-to-install-and-configure-orientdb-on-ubuntu-16-04).

This articles assumes OrientDB is installed in the `/opt/orientdb` directory, as in the original installation article. `/opt` is the traditional location for installing third party applications in Linux.

## Step 1 — Restricting Access to the OrientDB Web Server

OrientDB is a regular web server application, but it is not intended to be exposed to the Internet or public networks. Management access to it has to be confined to the local network.

The first step to running a secure OrientDB application is to secure the operating system it’s running on. You should be running a firewall. If you aren’t, follow the [Initial Server Setup on Ubuntu 16.04 guide](initial-server-setup-with-ubuntu-16-04) to set up UFW. The original OrientDB installation guide allows access to OrientDB Studio from the public network for testing purposes by allowing to port `2480` through the firewall.

If you want to make sure access from the Internet to OrientDB Studio and console is always denied, regardless of the firewall settings, you just need to make a couple of changes to the configuration file, `/opt/orientdb/config/orientdb-server-config.xml`.

Open that file for editing.

    sudo nano /opt/orientdb/config/orientdb-server-config.xml

Then look for the `listeners` tag:

/opt/orientdb/config/orientdb-server-config.xml

    . . .
    <listeners>
      <listener protocol="binary" socket="default" port-range="2424-2430" ip-address="0.0.0.0"/>
      <listener protocol="http" socket="default" port-range="2480-2490" ip-address="0.0.0.0">
      . . .
    </listeners>
    . . .

And change the `ip-address` parameters from `0.0.0.0` to `127.0.0.1`.

/opt/orientdb/config/orientdb-server-config.xml

    <listeners>
    . . .
      <listener protocol="binary" socket="default" port-range="2424-2430" ip-address="127.0.0.1"/>
      <listener protocol="http" socket="default" port-range="2480-2490" ip-address="127.0.0.1">
      . . .
    </listeners>
    . . .

Save and close the file.

When a change is made to the configuration file while the OrientDB daemon is running, be sure to restart it:

    sudo systemctl restart orientdb

That cuts off all connections to the Studio from the public Internet. Now try connecting to the Studio by visiting `http://your_server_ip:2480` in your browser again. This time, the connection will be denied.

In this step, you focused on security from the external network. In the next step, you’ll make the OrientDB server instance more secure internally.

## Step 2 — Securing the OrientDB Server Instance

Here, you’ll learn how to delete the guest account and modify the permissions of OrientDB’s configuration file.

One thing you can do to boost the server security is to give read-write access to the `config` directory _only_ to the OrientDB user. The default permission of that directory is `755`, but it doesn’t even need to have the execute bit set.

    sudo chmod 600 /opt/orientdb/config

And to batten things down a bit more, harden the permission of the config file itself.

    sudo chmod 600 /opt/orientdb/config/orientdb-server-config.xml

**Note** : These permissions will be set to `600` by default in [a future version of OrientDB](https://github.com/orientechnologies/orientdb/commit/c8cbe5546b500caac36724d8bb42726d298f38ef). However, at publication time, these steps are still necessary.

The rest of the security tips in this tutorial will be done via the the OrientDB console, so connect to it now.

    sudo /opt/orientdb/bin/console.sh

Every OrientDB server instance can support multiple OrientDB databases. Out of the box, each server instance comes with two user accounts: **guest** and **root**. You were given the option to set the root account password when you first installed and launched the OrientDB server. The hashed form of the password is stored in the OrientDB configuration file, `/opt/orientdb/config/orientdb-server-config.xml`. The hashed form of the auto-generated password for the guest account is also stored in that file.

From the OrientDB console, you can view information about both accounts by typing:

    list server users

**Note** : There’s currently [a bug in OrientDB](https://github.com/orientechnologies/orientdb/issues/7267) that will cause the following error when you try to run `list server users`:

    OutputError: com.orientechnologies.orient.core.exception.OConfigurationException: Cannot access to file ../config/orientdb-server-config.xml

If you receive this error, you can work around it by exiting the the OrientDB console and reconnecting after moving to the `bin` directory.

    cd /opt/orientdb/bin
    sudo ./console.sh

Then you can run `list server users` and it will work as expected.

The output will tell you what permissions both accounts have. The **guest** account has limited privileges, but the **root** user is allowed to perform all tasks. That’s what the asterisk in place of its permissions indicate:

    OutputSERVER USERS
    
    - 'guest', permissions: connect,server.listDatabases,server.dblist
    - 'root', permissions: *

Even with limited privileges, you might not want to keep the guest account. To delete it from the console, use the `drop` command.

    drop server user guest

Next time you `list server users` from the OrientDB console, it will show only the **root** user. If you look inside the `/opt/orientdb/config/orientdb-server-config.xml` file, you’ll see that the **guest** account has been deleted from the users tag.

Now that the server instance is more secure, next you will make the database itself more secure.

## Step 3 — Restricting Access to the OrientDB Database

The next step to securing your OrientDB installation is to make it very difficult to get unauthorized access to the database itself.

By default, every OrientDB database you create has three built-in accounts with the following usernames: **admin** , **reader** , and **writer** , each with a password that’s the same as the username. This is good for testing, but not for a production system. At the very least, you should change the passwords for all three accounts. Even better, you should delete or suspend any that you don’t need.

How you choose to manage these accounts depend on your needs and environment. For this tutorial, you’ll learn how to change the password of the **admin** account, suspend the **writer** account, and delete the **reader** account. You can do any of these three actions from the OrientDB console and the browser-based OrientDB Studio.

### Managing User Accounts from the OrientDB Console

To change user accounts from the console, you’ll need to connect to the database whose accounts you intend to manage. This example connects to the `GratefulDeadConcerts` database, a sample database that ships with every OrientDB installation, using the **admin** user and default password ( **admin** ):

    connect remote:127.0.0.1/GratefulDeadConcerts admin admin

Alternatively, you may also connect with the OrientDB server’s **root** account and password. In either case, the prompt should change to indicate that you’re connected to a specific database.

    OutputConnecting to database [remote:127.0.0.1/GratefulDeadConcerts] with user 'admin'...OK
    orientdb {db=GratefulDeadConcerts}> 

To list the database’s users, type the following. `ouser` is the OrientDB record where user passwords are stored:

    select from ouser

The complete output should be as follows. Notice that that all three accounts have an **ACTIVE** status.

    Output+----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+------+------+
    |# |@RID|@CLASS|name |password |status|roles |
    +----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+------+------+
    |0 |#5:0|OUser |admin |{PBKDF2WithHmacSHA256}6668FC52BF1D2883BEB4DC3A0468F734EA251E6D5B13AC51:39B1E812DEC299DC029A7922E206ED674EB52A6D6E27FE84:65536|ACTIVE|[#4:0]|
    |1 |#5:1|OUser |reader|{PBKDF2WithHmacSHA256}1168D930D370A0FB1B6FA11CAFF928CCB412A153C127C25F:0C287793DF156FB72E6E2D9D756E616995BBAC495D4A1616:65536|ACTIVE|[#4:1]|
    |2 |#5:2|OUser |writer|{PBKDF2WithHmacSHA256}22D3068CC3A39C08A941B4BF8B4CEB09D2609C20661529E3:8D6DA7FB4AF329234CA643663172EE913764E3096F63D007:65536|ACTIVE|[#4:2]|
    +----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+------+------+
    
    3 item(s) found. Query executed in 0.736 sec(s).

To change the password for the **admin** user, use the following command:

    update ouser set password = 'new_account_password' where name = 'admin'

To disable the **writer** user, change the status from `ACTIVE` to `SUSPENDED`.

    update ouser set status= 'SUSPENDED' where name = 'writer'

To delete the **reader** account from the database entirely, use:

    drop user reader

If you performed all of the above and view the list of accounts again, you’ll see the following output. One of the accounts is missing and another is suspended:

    Output+----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+---------+------+
    |# |@RID|@CLASS|name |password |status |roles |
    +----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+---------+------+
    |0 |#5:0|OUser |admin |{PBKDF2WithHmacSHA256}6668FC52BF1D2883BEB4DC3A0468F734EA251E6D5B13AC51:39B1E812DEC299DC029A7922E206ED674EB52A6D6E27FE84:65536|ACTIVE |[#4:0]|
    |1 |#5:2|OUser |writer|{PBKDF2WithHmacSHA256}22D3068CC3A39C08A941B4BF8B4CEB09D2609C20661529E3:8D6DA7FB4AF329234CA643663172EE913764E3096F63D007:65536|SUSPENDED|[#4:2]|
    +----+----+------+------+-----------------------------------------------------------------------------------------------------------------------------+---------+------+

After completing all the user management tasks, you may disconnect from the database (that is, close it) by typing:

    disconnect

### Managing OrientDB User Accounts from OrientDB Studio

In this section, you’ll learn how to manage OrientDB user accounts from OrientDB Studio. To start, launch the studio by visiting `http://your_server_ip:2480` in your browser. If you restricted access to the Studio in Step 1, you’ll need to re-allow it.

The first screen you’ll see is a login screen. Log in using **root** and the password you when you installed OrientDB. After logging in, click on the **Security** tab. On that page, you’ll see all three default users.

To change the password of the **admin** account:

1. Click on **EDIT** under its **Actions** column, which will bring up a small **Edit User** window.
2. Change the password in the **password** field.
3. Click on **SAVE USER**.

To delete the **reader** account:

1. Click on the **DELETE** button in the account’s **Actions** column.

To suspend the **writer** account:

1. Click on **EDIT** under its **Actions** , which will bring up a small **Edit User** window.
2. In the **Status** pull-down menu, select **SUSPENDED**.
3. Click on **SAVE USER**.

In the next step, you’ll learn how to encrypt an OrientDB database at rest.

## Step 4 — Encrypting the OrientDB Database

OrientDB supports encrypted databases, allowing you additional security on your stored data. You can only encript an OrientDB database when it’s being created; if you need to encrypt an existing database, you’ll have to export and import it into an encrypted database. For this section, we’ll go through the process of specifying that a database be encrypted at creation time.

OrientDB supports both the AES and DES encryption algorithms, but AES is preferred because it is stronger. We’ll need to set the encryption key, create the database, and specify the encryption method (AES or DES). Note that the length of the encryption key must be 24 characters, and the last two characters must be `==`.

To generate an encryption key, you can use `pwgen`, a password generation tool.

    sudo apt-get install pwgen

Then generate a single, 24-character key ending in `==` with the following command:

    echo `pwgen 22 1`==

Remember to store this key in a safe place, like you would a password. To set the encryption key for a new database you want to create, type the following into the OrientDB console:

    config set storage.encryptionKey Ohjojiegahv3tachah9eib==

Then create the encrypted database using that key. This creates the encrypted, document-based database in the local filesystem (`plocal`).

    create database plocal:/opt/orientdb/databases/name_of_encrypted_db root root_password plocal document -encryption=aes

You’ll be connected automatically to the new database and the prompt will change to reflect that. To disconnect from the database, simply type:

    encrypted-db}>'>disconnect

Bear in mind that the encryption key used to encrypt an OrientDB database is not stored on the system. Whenever you want to interact with the database from the console, you’ll have to type in the same command you used to set the encryption key.

    config set storage.encryptionKey Ohjojiegahv3tachah9eib==

Then to open the database, you would type:

    connect plocal:/opt/orientdb/databases/name_of_encrypted_db admin admin_password

Note that while you can create a new database from OrientDB Studio, you can’t create an encrypted one. At publication time, you can only create an encrypted database from the console.

## Conclusion

In this tutorial, you’ve restricted access to an installation of OrientDB, managed the user accounts both from the console and the web UI, and also encrypted an OrientDB database at rest. These are basic but important security configurations you can make to boost the security profile of your OrientDB server and databases.

For now, you may access additional information on OrientDB security by visiting [this OrientDB documentation](http://orientdb.com/docs/2.2/Security.html) on that topic.
