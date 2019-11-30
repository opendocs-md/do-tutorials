---
author: Justin Ellingwood, Mark Drake
date: 2019-05-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-ssl-tls-for-mysql-on-ubuntu-18-04
---

# How To Configure SSL/TLS for MySQL on Ubuntu 18.04

## Introduction

MySQL is the [most popular](https://db-engines.com/en/ranking) open-source relational database management system in the world. While modern package managers have reduced some of the friction to getting MySQL up and running, there is still some further configuration that should be performed after you install it. One of the most important aspects to spend some extra time on is security.

By default, MySQL is configured to only accept local connections, or connections that originate from the same machine where MySQL is installed. If you need to access your MySQL database from a remote location, it’s important that you do so securely. In this guide, we will demonstrate how to configure MySQL on Ubuntu 18.04 to accept remote connections with SSL/TLS encryption.

## Prerequisites

To complete this guide, you will need:

- **Two** Ubuntu 18.04 servers. We will use one of these servers as the MySQL server while we’ll use the other as the client machine. Create a non-root user with `sudo` privileges and enable a firewall with `ufw` on each of these servers. Follow our [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04) to get both servers into the appropriate initial state.
- On **one of the machines** , install and configure the MySQL server. Follow **Steps 1 through 3** of our [MySQL installation guide for Ubuntu 18.04](how-to-install-mysql-on-ubuntu-18-04) to do this. As you follow this guide, be sure to configure your **root** MySQL user to authenticate with a password, as described in [Step 3](how-to-install-mysql-on-ubuntu-18-04#step-3-%E2%80%94-(optional)-adjusting-user-authentication-and-privileges) of the guide, as this is necessary to connect to MySQL using TCP rather than the local Unix socket.

Please note that throughout this guide, the server on which you installed MySQL will be referred to as the **MySQL server** and any commands that should be run on this machine will be shown with a blue background, like this:

    

Similarly, this guide will refer to the other server as the **MySQL client** and any commands that must be run on that machine will be shown with a red background:

    

Please keep these in mind as you follow along with this tutorial so as to avoid any confusion.

## Step 1 — Checking MySQL’s Current SSL/TLS Status

Before you make any configuration changes, you can check the current SSL/TLS status on the **MySQL server** instance.

Use the following command to begin a MySQL session as the **root** MySQL user. This command includes the `-p` option, which instructs `mysql` to prompt you for a password in order to log in. It also includes the `-h` option which is used to specify the host to connect to. In this case it points it to `127.0.0.1`, the IPv4 loopback interface also known as **localhost**. This will force the client to connect with [TCP](https://en.wikipedia.org/wiki/Transmission_Control_Protocol) instead of using the local socket file. MySQL attempts to make connections through a [Unix socket file](https://en.wikipedia.org/wiki/Unix_domain_socket) by default. This is generally faster and more secure, since these connections can only be made locally and don’t have to go through all the checks and routing operations that TCP connections must perform. Connecting with TCP, however, allows us to check the SSL status of the connection:

    mysql -u root -p -h 127.0.0.1

You will be prompted for the MySQL **root** password that you chose when you installed and configured MySQL. After entering it you’ll be dropped into an interactive MySQL session.

Show the state of the SSL/TLS variables issuing the following command:

    SHOW VARIABLES LIKE '%ssl%';

    Output+---------------+----------+
    | Variable_name | Value |
    +---------------+----------+
    | have_openssl | DISABLED |
    | have_ssl | DISABLED |
    | ssl_ca | |
    | ssl_capath | |
    | ssl_cert | |
    | ssl_cipher | |
    | ssl_crl | |
    | ssl_crlpath | |
    | ssl_key | |
    +---------------+----------+
    9 rows in set (0.01 sec)

The `have_openssl` and `have_ssl` variables are both marked as `DISABLED`. This means that SSL functionality has been compiled into the server, but that it is not yet enabled.

Check the status of your current connection to confirm this:

    \s

    Output--------------
    mysql Ver 14.14 Distrib 5.7.26, for Linux (x86_64) using EditLine wrapper
    
    Connection id: 9
    Current database:   
    Current user: root@localhost
    SSL: Not in use
    Current pager: stdout
    Using outfile: ''
    Using delimiter: ;
    Server version: 5.7.26-0ubuntu0.18.04.1 (Ubuntu)
    Protocol version: 10
    Connection: 127.0.0.1 via TCP/IP
    Server characterset: latin1
    Db characterset: latin1
    Client characterset: utf8
    Conn. characterset: utf8
    TCP port: 3306
    Uptime: 40 min 11 sec
    
    Threads: 1 Questions: 33 Slow queries: 0 Opens: 113 Flush tables: 1 Open tables: 106 Queries per second avg: 0.013
    --------------

As the above output indicates, SSL is not currently in use for this connection, even though you’re connected over TCP.

Close the current MySQL session when you are finished:

    exit

Now that you’ve confirmed your MySQL server isn’t using SSL, you can move on to the next step where you will begin the process of enabling SSL by generating some certificates and keys. These will allow your server and client to communicate with one another securely.

## Step 2 — Generating SSL/TLS Certificates and Keys

To enable SSL connections to MySQL, you first need to generate the appropriate certificate and key files. MySQL versions 5.7 and above provide a utility called `mysql_ssl_rsa_setup` that helps simplify this process. The version of MySQL you installed by following the [prerequisite MySQL tutorial](how-to-install-mysql-on-ubuntu-18-04) includes this utility, so we will use it here to generate the necessary files.

The MySQL process must be able to read the generated files, so use the `--uid` option to declare `mysql` as the system user that should own the generated files:

    sudo mysql_ssl_rsa_setup --uid=mysql

This will produce output that looks similar to the following:

    OutputGenerating a 2048 bit RSA private key
    .+++
    ..........+++
    writing new private key to 'ca-key.pem'
    -----
    Generating a 2048 bit RSA private key
    ........................................+++
    ............+++
    writing new private key to 'server-key.pem'
    -----
    Generating a 2048 bit RSA private key
    .................................+++
    ............................................................+++
    writing new private key to 'client-key.pem'
    -----

These new files will be stored in MySQL’s data directory, located by default at `/var/lib/mysql`. Check the generated files by typing:

    sudo find /var/lib/mysql -name '*.pem' -ls

    Output 258930 4 -rw-r--r-- 1 mysql mysql 1107 May 3 16:43 /var/lib/mysql/client-cert.pem
       258919 4 -rw-r--r-- 1 mysql mysql 451 May 3 16:43 /var/lib/mysql/public_key.pem
       258925 4 -rw------- 1 mysql mysql 1675 May 3 16:43 /var/lib/mysql/server-key.pem
       258927 4 -rw-r--r-- 1 mysql mysql 1107 May 3 16:43 /var/lib/mysql/server-cert.pem
       258922 4 -rw------- 1 mysql mysql 1675 May 3 16:43 /var/lib/mysql/ca-key.pem
       258928 4 -rw------- 1 mysql mysql 1675 May 3 16:43 /var/lib/mysql/client-key.pem
       258924 4 -rw-r--r-- 1 mysql mysql 1107 May 3 16:43 /var/lib/mysql/ca.pem
       258918 4 -rw------- 1 mysql mysql 1679 May 3 16:43 /var/lib/mysql/private_key.pem

These files are the key and certificate pairs for the certificate authority (starting with “ca”), the MySQL server process (starting with “server”), and for MySQL clients (starting with “client”). Additionally, the `private_key.pem` and `public_key.pem` files are used by MySQL to securely transfer passwords when not using SSL.

Now that you have the necessary certificate and key files, continue on to enable the use of SSL on your MySQL instance.

## Step 3 — Enabling SSL Connections on the MySQL Server

Modern versions of MySQL look for the appropriate certificate files within the MySQL data directory whenever the server starts. Because of this, you won’t need to modify MySQL’s configuration to enable SSL.

Instead, enable SSL by restarting the MySQL service:

    sudo systemctl restart mysql

After restarting, open up a new MySQL session using the same command as before. The MySQL client will automatically attempt to connect using SSL if it is supported by the server:

    mysql -u root -p -h 127.0.0.1

Let’s take another look at the same information we requested last time. Check the values of the SSL-related variables:

    SHOW VARIABLES LIKE '%ssl%';

    Output+---------------+-----------------+
    | Variable_name | Value |
    +---------------+-----------------+
    | have_openssl | YES |
    | have_ssl | YES |
    | ssl_ca | ca.pem |
    | ssl_capath | |
    | ssl_cert | server-cert.pem |
    | ssl_cipher | |
    | ssl_crl | |
    | ssl_crlpath | |
    | ssl_key | server-key.pem |
    +---------------+-----------------+
    9 rows in set (0.00 sec)

The `have_openssl` and `have_ssl` variables now read `YES` instead of `DISABLED`. Furthermore, the `ssl_ca`, `ssl_cert`, and `ssl_key` variables have been populated with the names of the respective files that we just generated.

Next, check the connection details again:

    \s

    Output--------------
    . . .
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    . . .
    Connection: 127.0.0.1 via TCP/IP
    . . .
    --------------

This time, the specific SSL cipher is displayed, indicating that SSL is being used to secure the connection.

Exit back out to the shell:

    exit

Your server is now capable of using encryption, but some additional configuration is required to allow remote access and mandate the use of secure connections.

## Step 4 — Configuring Secure Connections for Remote Clients

Now that you’ve enabled SSL on the MySQL server, you can begin configuring secure remote access. To do this, you’ll configure your MySQL server to require that any remote connections be made over SSL, bind MySQL to listen on a public interface, and adjust your system’s firewall rules to allow external connections

Currently, the MySQL server is configured to accept SSL connections from clients. However, it will still allow unencrypted connections if requested by the client. We can change this by turning on the `require_secure_transport` option. This requires all connections to be made either with SSL or with a local Unix socket. Since Unix sockets are only accessible from within the server itself, the only connection option available to remote users will be with SSL.

To enable this setting, open the MySQL configuration file in your preferred text editor. Here, we’ll use `nano`:

    sudo nano /etc/mysql/my.cnf

Inside there will be two `!includedir` directives which are used to source additional configuration files. You must add your own configuration **beneath** these lines so that it overrides any conflicting settings found in these additional configuration files.

Start by creating a `[mysqld]` section to target the MySQL server process. Under that section header, set `require_secure_transport` to `ON`, which will force MySQL to only allow secure connections:

/etc/mysql/my.cnf

    . . .
    
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    
    [mysqld]
    # Require clients to connect either using SSL
    # or through a local socket file
    require_secure_transport = ON

By default, MySQL is configured to only listen for connections that originate from `127.0.0.1`, the loopback IP address that represents **localhost**. This means that MySQL is configured to only listen for connections that originate from the machine on which the MySQL server is installed.

In order to allow MySQL to listen for external connections, you must configure it to listen for connections on an _external_ IP address. To do this, you can add the `bind-address` setting and point it to `0.0.0.0`, a wildcard IP address that represents all IP addresses. Essentially, this will force MySQL to listen for connections on every interface:

/etc/mysql/my.cnf

    . . .
    
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    
    [mysqld]
    # Require clients to connect either using SSL
    # or through a local socket file
    require_secure_transport = ON
    bind-address = 0.0.0.0

**Note:** You could alternatively set `bind-address` to your **MySQL server’s** public IP address. However, you would need to remember to update your `my.cnf` file if you ever migrate your database to another machine.

After adding these lines, save and close the file. If you used `nano` to edit the file, you can do so by pressing `CTRL+X`, `Y`, then `ENTER`.

Next, restart MySQL to apply the new settings:

    sudo systemctl restart mysql

Verify that MySQL is listening on `0.0.0.0` instead of `127.0.0.1` by typing:

    sudo netstat -plunt

The output of this command will look like this:

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name    
    tcp 0 0 0.0.0.0:3306 0.0.0.0:* LISTEN 13317/mysqld        
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1293/sshd           
    tcp6 0 0 :::22 :::* LISTEN 1293/sshd           

The `0.0.0.0` highlighted in the above output indicates that MySQL is listening for connections on all available interfaces.

Next, allow MySQL connections through your server’s firewall. Add an exception to your `ufw` rules by typing:

    sudo ufw allow mysql

    OutputRule added
    Rule added (v6)

With that, remote connection attempts are now able to reach your MySQL server. However, you don’t currently have any users configured that can connect from a remote machine. We’ll create and configure a MySQL user that can connect from your client machine in the next step.

## Step 5 — Creating a Dedicated MySQL User

At this point, your MySQL server will reject any attempt to connect from a remote client machine. This is because the existing MySQL users are all only configured to connect locally from the MySQL server. To resolve this, you will create a dedicated user that will only be able to connect from your client machine.

To create such a user, log back into MySQL as the **root** user:

    mysql -u root -p

From the prompt, create a new remote user with the `CREATE USER` command. You can name this user whatever you’d like, but in this guide we name it **mysql\_user**. Be sure to specify your client machine’s IP address in the host portion of the user specification to restrict connections to that machine and to replace `password` with a secure password of your choosing. Also, for some redundancy in case the `require_secure_transport` option is turned off in the future, specify that this user requires SSL by including the `REQUIRE SSL` clause, as shown here:

    CREATE USER 'mysql_user'@'your_mysql_client_IP' IDENTIFIED BY 'password' REQUIRE SSL;

Next, grant the new user permissions on whichever databases or tables that they should have access to. To demonstrate, create an `example` database:

    CREATE DATABASE example;

Then give your new user access to this database and all of its tables:

    GRANT ALL ON example.* TO 'mysql_user'@'your_mysql_client_IP';

Next, flush the privileges to apply those settings immediately:

    FLUSH PRIVILEGES;

Then exit back out to the shell when you are done:

    exit

Your MySQL server is now set up to allow connections from your remote user. To test that you can connect to MySQL successfully, you will need to install the `mysql-client` package on the **MySQL client**.

Log in to your client machine with `ssh`

    ssh sammy@your_mysql_client_ip

Then update the client machine’s package index:

    sudo apt update

And install `mysql-client` with the following command:

    sudo apt install mysql-client

When prompted, confirm the installation by pressing `ENTER`.

Once APT finishes installing the package, run the following command to test whether you can connect to the server successfully. This command includes the `-u` user option to specify **mysql\_user** and the `-h` option to specify the **MySQL server’s** IP address:

    mysql -u mysql_user -p -h your_mysql_server_IP

After submitting the password, you will be logged in to the remote server. Use `\s` to check the server’s status and confirm that your connection is secure:

    \s

    Output--------------
    . . .
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    . . .
    Connection: your_mysql_server_IP via TCP/IP
    . . .
    --------------

Exit back out to the shell:

    exit

You’ve confirmed that you’re able to connect to MySQL over SSL. However, you’ve not yet confirmed that the MySQL server is rejecting insecure connections. To test this, try connecting once more, but this time append `--ssl-mode=disabled` to the login command. This will instruct `mysql-client` to attempt an unencrypted connection:

    mysql -u mysql_user -p -h mysql_server_IP --ssl-mode=disabled

After entering your password when prompted, your connection will be refused:

    OutputERROR 1045 (28000): Access denied for user 'mysql_user'@'mysql_server_IP' (using password: YES)

This shows that SSL connections are permitted while unencrypted connections are refused.

At this point, your MySQL server has been configured to accept secure remote connections. You can stop here if this satisfies your security requirements, but there are some additional pieces that you can put into place to enhance security and trust between your two servers.

## Step 6 — (Optional) Configuring Validation for MySQL Connections

Currently, your MySQL server is configured with an SSL certificate signed by a locally generated certificate authority (CA). The server’s certificate and key pair are enough to provide encryption for incoming connections.

However, you aren’t yet fully leveraging the trust relationship that a certificate authority can provide. By distributing the CA certificate to clients — as well as the client certificate and key — both parties can provide proof that their certificates were signed by a mutually trusted certificate authority. This can help prevent spoofed connections from malicious servers.

In order to implement this extra, optional safeguard, we will transfer the appropriate SSL files to the client machine, create a client configuration file, and alter the remote MySQL user to require a trusted certificate.

**Note:** The process for transferring the CA certificate, client certificate, and client key to the MySQL client outlined in the following paragraphs involves displaying each file’s contents with `cat`, copying those contents to your clipboard, and pasting them in to a new file on the client machine. While it is possible to copy these files directly with a program like `scp` or `sftp`, this also requires you to [set up SSH keys](how-to-set-up-ssh-keys-on-ubuntu-1804) for both servers so as to allow them to communicate over SSH.

Our goal here is to keep the number of potential avenues for connecting to your MySQL server down to a minimum. While this process is slightly more laborious than directly transferring the files, it is equally secure and doesn’t require you to open an SSH connection between the two machines.

Begin by making a directory on the **MySQL client** in the home directory of your non-root user. Call this directory `client-ssl`:

    mkdir ~/client-ssl

Because the certificate key is sensitive, lock down access to this directory so that only the current user can access it:

    chmod 700 ~/client-ssl

On the **MySQL server** , display the contents of the CA certificate by typing:

    sudo cat /var/lib/mysql/ca.pem

    Output-----BEGIN CERTIFICATE-----
    
    . . .
    
    -----END CERTIFICATE-----

Copy the entire output, including the `BEGIN CERTIFICATE` and `END CERTIFICATE` lines, to your clipboard.

On the **MySQL client** , create a file with the same name inside the new directory:

    nano ~/client-ssl/ca.pem

Inside, paste the copied certificate contents from your clipboard. Save and close the file when you are finished.

Next, display the client certificate on the **MySQL server** :

    sudo cat /var/lib/mysql/client-cert.pem

    Output-----BEGIN CERTIFICATE-----
    
    . . .
    
    -----END CERTIFICATE-----

Copy the file contents to your clipboard. Again, remember to include the first and last line.

Open a file with the same name on the **MySQL client** within the `client-ssl` directory:

    nano ~/client-ssl/client-cert.pem

Paste the contents from your clipboard. Save and close the file.

Finally, display the contents of the client key file on the **MySQL server** :

    sudo cat /var/lib/mysql/client-key.pem

    Output-----BEGIN RSA PRIVATE KEY-----
    
    . . .
    
    -----END RSA PRIVATE KEY-----

Copy the displayed contents, including the first and last line, to your clipboard.

On the **MySQL client** , open a file with the same name in the `client-ssl` directory:

    nano ~/client-ssl/client-key.pem

Paste the contents from your clipboard. Save and close the file.

The client machine now has all of the credentials required to access the MySQL server. However, the MySQL server is still not set up to require trusted certificates for client connections.

To change this, log in to the MySQL **root** account again on the **MySQL server** :

    mysql -u root -p

From here, change the security requirements for your remote user. Instead of the `REQUIRE SSL` clause, apply the `REQUIRE X509` clause. This implies all of the security provided by the `REQUIRE SSL` clause, but additionally requires the connecting client to present a certificate signed by a certificate authority that the MySQL server trusts.

To adjust the user requirements, use the `ALTER USER` command:

    ALTER USER 'mysql_user'@'mysql_client_IP' REQUIRE X509;

Then flush the changes to ensure that they are applied immediately:

    FLUSH PRIVILEGES;

Exit back out to the shell when you are finished:

    exit

Following that, check whether you can validate both parties when you connect.

On the **MySQL client** , first try to connect without providing the client certificates:

    mysql -u mysql_user -p -h mysql_server_IP

    OutputERROR 1045 (28000): Access denied for user 'mysql_user'@'mysql_client_IP' (using password: YES)

As expected, the server rejects the connection when no client certificate is presented.

Now, connect while using the `--ssl-ca`, `--ssl-cert`, and `--ssl-key` options to point to the relevant files within the `~/client-ssl` directory:

    mysql -u mysql_user -p -h mysql_server_IP --ssl-ca=~/client-ssl/ca.pem --ssl-cert=~/client-ssl/client-cert.pem --ssl-key=~/client-ssl/client-key.pem

You’ve provided the client with the appropriate certificates and keys, so this attempt will be successful:

    

Log back out to regain access to your shell session:

    exit

Now that you’ve confirmed access to the server, let’s implement a small usability improvement in order to avoid having to specify the certificate files each time you connect.

Inside your home directory on the **MySQL client** machine, create a hidden configuration file called `~/.my.cnf`:

    nano ~/.my.cnf

At the top of the file, create a section called `[client]`. Underneath, add the `ssl-ca`, `ssl-cert`, and `ssl-key` options and point them to the respective files you copied over from the server. It will look like this:

~/.my.cnf

    [client]
    ssl-ca = ~/client-ssl/ca.pem
    ssl-cert = ~/client-ssl/client-cert.pem
    ssl-key = ~/client-ssl/client-key.pem

The `ssl-ca` option tells the client to verify that the certificate presented by the MySQL server is signed by the certificate authority you pointed to. This allows the client to trust that it is connecting to a trusted MySQL server. Likewise, the `ssl-cert` and `ssl-key` options point to the files needed to prove to the MySQL server that it too has a certificate that has been signed by the same certificate authority. You’ll need this if you want the MySQL server to verify that the client was trusted by the CA as well.

Save and close the file when you are finished.

Now, you can connect to the MySQL server without adding the `--ssl-ca`, `--ssl-cert`, and `--ssl-key` options on the command line:

    mysql -u remote_user -p -h mysql_server_ip

Your client and server will now each be presenting certificates when negotiating the connection. Each party is configured to verify the remote certificate against the CA certificate it has locally.

## Conclusion

Your MySQL server is now configured to require secure connections from remote clients. Additionally, if you followed the steps to validate connections using the certificate authority, some level of trust is established by both sides that the remote party is legitimate.
