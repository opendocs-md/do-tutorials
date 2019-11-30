---
author: Justin Ellingwood
date: 2017-03-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-ssl-tls-for-mysql-on-ubuntu-16-04
---

# How To Configure SSL/TLS for MySQL on Ubuntu 16.04

## Introduction

MySQL is the most popular open-source relational database management system in the world. Modern package managers have reduced some of the friction to getting MySQL up and running, but there is still some configuration that should be done after installation. One of the most important areas to spend some extra time on is security.

By default, MySQL is configured to only accept local connections. If you need to allow remote connections, it is important to do so securely. In this guide, we will demonstrate how to configure MySQL on Ubuntu 16.04 to accept remote connections with SSL/TLS encryption.

## Prerequisites

To follow along with this guide, you will need **two** Ubuntu 16.04 servers. We will use one as the MySQL server and the other as the client. Create a non-root user with `sudo` privileges on each of these servers. Follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to get your server into the appropriate initial state.

On the first machine, you should have the **MySQL server** installed and configured. Follow our [MySQL installation guide for Ubuntu 16.04](how-to-install-mysql-on-ubuntu-16-04) to install and configure the software.

On the second machine, install the **MySQL client** package. You can update the `apt` package index and install the necessary software by typing:

    sudo apt-get update
    sudo apt-get install mysql-client

When your server and client are ready, continue below.

## Check the Current SSL/TLS Status

Before we begin, we can check the current status of SSL/TLS on our **MySQL server** instance.

Log into a MySQL session using the `root` MySQL user. We’ll use `-h` to specify the IPv4 local loopback interface in order to force the client to connect with TCP instead of using the local socket file. This will allow us to check the SSL status for TCP connections:

    mysql -u root -p -h 127.0.0.1

You will be prompted for the MySQL `root` password that you selected during the installation process. Afterward, you will be dropped into an interactive MySQL session.

Show the state of the SSL/TLS variables by typing:

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

Check the status of our current connection to confirm:

    \s

    Output--------------
    mysql Ver 14.14 Distrib 5.7.17, for Linux (x86_64) using EditLine wrapper
    
    Connection id: 30
    Current database:   
    Current user: root@localhost
    SSL: Not in use
    Current pager: stdout
    Using outfile: ''
    Using delimiter: ;
    Server version: 5.7.17-0ubuntu0.16.04.1 (Ubuntu)
    Protocol version: 10
    Connection: 127.0.0.1 via TCP/IP
    Server characterset: latin1
    Db characterset: latin1
    Client characterset: utf8
    Conn. characterset: utf8
    TCP port: 3306
    Uptime: 3 hours 38 min 44 sec
    
    Threads: 1 Questions: 70 Slow queries: 0 Opens: 121 Flush tables: 1 Open tables: 40 Queries per second avg: 0.005
    --------------

As the above output indicates, SSL is not currently in use for our connection, even though we are connected over TCP.

Close the current MySQL session when you are finished:

    exit

Now we can start configuring MySQL for SSL to secure our connections.

## Generate SSL/TLS Certificates and Keys

To enable SSL connections to MySQL, we first need to generate the appropriate certificate and key files. A utility called `mysql_ssl_rsa_setup` is provided with MySQL 5.7 and above to simplify this process. Ubuntu 16.04 has a compatible version of MySQL, so we can use this command to generate the necessary files.

The files will be created in MySQL’s data directory, located at `/var/lib/mysql`. We need the MySQL process to be able to read the generated files, so we will pass `mysql` as the user that should own the generated files:

    sudo mysql_ssl_rsa_setup --uid=mysql

The generation will produce output that looks something like this:

    OutputGenerating a 2048 bit RSA private key
    ...................................+++
    .....+++
    writing new private key to 'ca-key.pem'
    -----
    Generating a 2048 bit RSA private key
    ......+++
    .................................+++
    writing new private key to 'server-key.pem'
    -----
    Generating a 2048 bit RSA private key
    ......................................................+++
    .................................................................................+++
    writing new private key to 'client-key.pem'
    -----

Check the generated files by typing:

    sudo find /var/lib/mysql -name '*.pem' -ls

    Output 256740 4 -rw-r--r-- 1 mysql mysql 1078 Mar 17 17:24 /var/lib/mysql/server-cert.pem
       256735 4 -rw------- 1 mysql mysql 1675 Mar 17 17:24 /var/lib/mysqlsql/ca-key.pem
       256739 4 -rw-r--r-- 1 mysql mysql 451 Mar 17 17:24 /var/lib/mysqlsql/public_key.pem
       256741 4 -rw------- 1 mysql mysql 1679 Mar 17 17:24 /var/lib/mysqlsql/client-key.pem
       256737 4 -rw-r--r-- 1 mysql mysql 1074 Mar 17 17:24 /var/lib/mysqlsql/ca.pem
       256743 4 -rw-r--r-- 1 mysql mysql 1078 Mar 17 17:24 /var/lib/mysqlsql/client-cert.pem
       256736 4 -rw------- 1 mysql mysql 1675 Mar 17 17:24 /var/lib/mysqlsql/private_key.pem
       256738 4 -rw------- 1 mysql mysql 1675 Mar 17 17:24 /var/lib/mysqlsql/server-key.pem

The last column shows the generated filenames. The central columns that show “mysql” indicate that the generated files have the correct user and group ownership.

These files are the key and certificate pairs for the certificate authority (starting with “ca”), the MySQL server process (starting with “server”), and for MySQL clients (starting with “client”). Additionally, the `private_key.pem` and `public_key.pem` files are used by MySQL to securely transfer password when not using SSL.

## Enable SSL Connections on the MySQL Server

Modern MySQL versions will look for the appropriate certificate files within the MySQL data directory when the server starts. Because of this, we don’t actually need to modify the MySQL configuration to enable SSL.

We can just restart the MySQL service instead:

    sudo systemctl restart mysql

After restarting, open up a new MySQL session using the same command as before. The MySQL client will automatically attempt to connect using SSL if it is supported by the server:

    mysql -u root -p -h 127.0.0.1

Let’s take a look at the same information we requested last time. Check the values of the SSL related variables:

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

The `have_openssl` and `have_ssl` variables read “YES” instead of “DISABLED” this time. Furthermore, the `ssl_ca`, `ssl_cert`, and `ssl_key` variables have been populated with the names of the relevant certificates that we generated.

Next, check the connection details again:

    \s

    Output--------------
    . . .
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    . . .
    Connection: 127.0.0.1 via TCP/IP
    . . .
    --------------

This time, the specific SSL cipher is displayed, indicating that SSL is being used to secure our connection.

Exit back out to the shell:

    exit

Our server is now capable of using encryption, but some additional configuration is required to allow remote access and mandate use of secure connections.

## Configuring Secure Connections for Remote Clients

Now that we have SSL available on the server, we can begin configuring secure remote access. To do this, we need to:

- Require SSL for remote connections
- Bind to a public interface
- Create MySQL user for remote connections
- Adjust our firewall rules to allow external connections

### Configure Remote Access with Mandatory SSL

Currently, the MySQL server is configured to accept SSL connections from clients. However, it will still allow unencrypted connections if requested by the client.

We can fix this by turning on the `require_secure_transport` option. This requires all connections to be made either with SSL or with a local Unix socket. Since Unix sockets are only accessible from within the server itself, the only connection option open to remote users will be with SSL.

To enable this setting, open the `/etc/mysql/my.cnf` file in your text editor:

    sudo nano /etc/mysql/my.cnf

Inside, there will be two `!includedir` directives used to source additional configuration files. We will need to put our own configuration **beneath** these lines so that they override any conflicting settings.

Start by creating a `[mysqld]` section to target the MySQL server process. Under that section header, set `require_secure_transport` to `ON`:

/etc/mysql/my.cnf

    . . .
    
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    
    [mysqld]
    # Require clients to connect either using SSL
    # or through a local socket file
    require_secure_transport = ON

That line is the only setting required to enforce secure connections.

By default MySQL is configured to only listen for connections originating on the local computer. To configure it to listen for remote connections, we can set the `bind-address` to a different interface.

To allow MySQL to accept connections on any of its interfaces, we can set `bind-address` to “0.0.0.0”:

/etc/mysql/my.cnf

    . . .
    
    !includedir /etc/mysql/conf.d/
    !includedir /etc/mysql/mysql.conf.d/
    
    [mysqld]
    # Require clients to connect either using SSL
    # or through a local socket file
    require_secure_transport = ON
    bind-address = 0.0.0.0

Save and close the file when you are finished.

Next, restart MySQL to apply the new settings:

    sudo systemctl restart mysql

Verify that MySQL is listening on “0.0.0.0” instead of “127.0.0.1” by typing:

    sudo netstat -plunt

    OutputActive Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:3306 0.0.0.0:* LISTEN 4330/mysqld     
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1874/sshd       
    tcp6 0 0 :::22 :::* LISTEN 1874/sshd

The “0.0.0.0” in the above output indicates that MySQL is listening for connections on all available interfaces.

Next, we need to allow MySQL connections through our firewall. Create an exception by typing:

    sudo ufw allow mysql

    OutputRule added
    Rule added (v6)

Remote connection attempts should now be able to reach our MySQL server.

### Configure a Remote MySQL User

The MySQL server is now listening for remote connections, but we currently don’t have any users configured that can connect from an outside computer.

Log into MySQL as the `root` user to get started:

    mysql -u root -p

Inside, you can create a new remote user using the `CREATE USER` command. We will use our client machine’s IP address in the host portion of the user specification to restrict connections to that machine.

For some redundancy in case the `require_secure_transport` option is turned off in the future, we’ll also specify during account creation that this user requires SSL by including the `REQUIRE SSL` clause:

    CREATE USER 'remote_user'@'mysql_client_IP' IDENTIFIED BY 'password' REQUIRE SSL;

Next, grant the new user permissions on the databases or tables they should have access to. To demonstrate, we’ll create an `example` database and give our new user ownership:

    CREATE DATABASE example;
    GRANT ALL ON example.* TO 'remote_user'@'mysql_client_IP';

Next, flush the privileges to apply those settings immediately:

    FLUSH PRIVILEGES;

Exit back out to the shell when you are done:

    exit

Our server is set up to allow connections to our remote user.

### Testing Remote Connections

On the **MySQL client** machine, test to make sure you can connect to the server successfully. Use the `-u` option to specify the remote user and the `-h` option to specify the MySQL server’s IP address:

    mysql -u remote_user -p -h mysql_server_IP

After specifying the password, you will be logged in to the remote server.

Check to make sure that your connection is secure:

    \s

    Output--------------
    . . .
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    . . .
    Connection: mysql_server_IP via TCP/IP
    . . .
    --------------

Exit back out to the shell:

    exit

Next, attempt to connect insecurely:

    mysql -u remote_user -p -h mysql_server_IP --ssl-mode=disabled

After being prompted for your password, your connection should be refused:

    OutputERROR 1045 (28000): Access denied for user 'remote_user'@'mysql_server_IP' (using password: YES)

This is what we were working towards. It shows that SSL connections are permitted, while unencrypted connections are refused.

At this point, our MySQL server has been configured to accept remote connections securely. You can stop here if this satisfies your security requirements, but there are some additional pieces that we can put into place to increase our security and trust further.

## Configuring Validation for MySQL Connections (Optional)

Currently, our MySQL server is configured with an SSL certificate signed by a locally generated certificate authority (CA). The server’s certificate and key pair are enough to provide encryption for incoming connections.

However, we aren’t currently leveraging the trust relationship that a certificate authority can provide. By distributing the CA certificate to clients, as well as the client certificate and key, both parties can provide proof that their certificates were signed by a mutually trusted certificate authority. This can help prevent spoofed connections to malicious servers.

In order to implement this extra, optional safeguard, we will need to:

- Transfer the appropriate SSL files to the client machine
- Create a client configuration file
- Alter our remote user to require a trusted certificate

### Transfer the Client Certificates to the Client Machine

To start, we need to grab the MySQL CA and client certificate files from the MySQL server and place them on the MySQL client.

Begin by making a directory on the **MySQL client** in the home directory of the user you will use to connect. Call this `client-ssl`:

    mkdir ~/client-ssl

Since the certificate key is sensitive, we should lock down access to this directory so that only the current user can access it:

    chmod 700 ~/client-ssl

Now, we can copy the certificate information to the new directory.

On the **MySQL server** machine, display the contents of the CA certificate by typing:

    sudo cat /var/lib/mysql/ca.pem

    Output-----BEGIN CERTIFICATE-----
    
    . . .
    
    -----END CERTIFICATE-----

Copy the entire output, including the `BEGIN CERTIFICATE` and `END CERTIFICATE` lines to your clipboard.

On the **MySQL client** , create a file with the same name inside the new directory:

    nano ~/client-ssl/ca.pem

Inside, paste the copied certificate contents from your clipboard. Save and close the file when you are finished.

Next, display the client certificate on the **MySQL server** :

    sudo cat /var/lib/mysql/client-cert.pem

    Output-----BEGIN CERTIFICATE-----
    
    . . .
    
    -----END CERTIFICATE-----

Again, copy the contents to your clipboard. Remember to include the first and last line.

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

The client machine should now have all of the credentials required to access the MySQL server. Next, we need to alter our remote user.

### Require a Certificate from a Trusted CA for the Remote User

Currently, the MySQL client has the files available to present its certificate to the server when connecting. However, the server is still not set up to require the client certificate from a trusted CA.

To change this, log into the MySQL root account again on the **MySQL server** :

    mysql -u root -p

Next, we need to change the requirements for our remote user. Instead of the `REQUIRE SSL` clause, we need to apply the `REQUIRE X509` clause. This implies all of the security provided by the previous requirement, but additionally requires the connecting client to present a certificate signed by a certificate authority that the MySQL server trusts.

To adjust the user requirements, use the `ALTER USER` command:

    ALTER USER 'remote_user'@'mysql_client_IP' REQUIRE X509;

Flush the changes to ensure that they are applied immediately:

    FLUSH PRIVILEGES;

Exit back out to the shell when you are finished:

    exit

Next, we can test to make sure we can still connect.

### Test Certificate Validation When Connecting

Now is a good time to check whether we can validate both parties when we connect.

On the **MySQL client** , first try to connect without providing the client certificates:

    mysql -u remote_user -p -h mysql_server_IP

    OutputERROR 1045 (28000): Access denied for user 'remote_user'@'mysql_client_IP' (using password: YES)

Without providing the client certificate, the server rejects the connection.

Now, connect while using the `--ssl-ca`, `--ssl-cert`, and `--ssl-key` options to point to the relevant files within the `~/client-ssl` directory:

    mysql -u remote_user -p -h mysql_server_IP --ssl-ca=~/client-ssl/ca.pem --ssl-cert=~/client-ssl/client-cert.pem --ssl-key=~/client-ssl/client-key.pem

You should be logged in successfully. Log back out to regain access to your shell session:

    exit

Now that we’ve confirmed access to the server, we can implement a small usability improvement.

### Create a MySQL Client Configuration File

To avoid having to specify the certificate files each time you connect, we can create a simple MySQL client configuration file.

Inside your home directory on the **MySQL client** machine, create a hidden file called `~/.my.cnf`:

    nano ~/.my.cnf

At the top of the file, create a section called `[client]`. Underneath, we can set the `ssl-ca`, `ssl-cert`, and `ssl-key` options to point to the files we copied over from the server. It should look like this:

~/.my.cnf

    [client]
    ssl-ca = ~/client-ssl/ca.pem
    ssl-cert = ~/client-ssl/client-cert.pem
    ssl-key = ~/client-ssl/client-key.pem

The `ssl-ca` option tells the client to verify that the certificate presented by the MySQL server is signed by the certificate authority we pointed to. This allows the client to trust that it is connecting to a trusted MySQL server.

The `ssl-cert` and `ssl-key` options point to the files required to prove to the MySQL server that it too has a certificate that has been signed by the same certificate authority. We need this if we want the MySQL server to verify that the client was trusted by the CA as well.

Save and close the file when you are finished.

Now, you can connect to the MySQL server without adding the `--ssl-ca`, `--ssl-cert`, and `--ssl-key` options on the command line:

    mysql -u remote_user -p -h mysql_server_ip

Your client and server should now each be presenting certificates when negotiating the connection. Each party is configured to verify the remote certificate against the CA certificate it has locally.

## Conclusion

Your MySQL server should now be configured to require secured connections for remote clients. Additionally, if you followed the steps to validate connections using the certificate authority, some level of trust is established by both sides that the remote party is legitimate.
