---
author: Justin Ellingwood
date: 2013-08-22
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-postgresql-on-an-ubuntu-vps
---

# How To Secure PostgreSQL on an Ubuntu VPS

### **What is PostgreSQL?**

PostgreSQL, also known as postgres, is a popular database management system that is used to handle the data of many websites and applications.

In this guide, we will discuss some ways that you can secure your PostgreSQL databases. This will help prevent unauthorized or malicious use of your data.

We will be completing the steps in this tutorial on an Ubuntu 12.04 VPS, but almost every modern distribution should function in a similar fashion.

## Installation

If you do not already currently have PostgreSQL installed, you can install it with the following commands:

    sudo apt-get update sudo apt-get install postgresql postgresql-contrib

The database software should now be installed on your system.

## Peer Authentication

By default, PostgreSQL handles authentication by associating Linux user accounts with PostgreSQL accounts. This is called "peer" authentication.

Upon installation, Postgres creates a Linux user called "postgres" which can be used to access the system. We can change to this user by typing:

    sudo su - postgres

From here, we can connect to the system by typing:

    psql

Notice how we can connect without a password. This is because Postgres has authenticated by username, which it assumes is secured.

**Do not** use the Linux "postgres" user for anything other than accessing the database software. This is an important security consideration.

Exit out of PostgreSQL and the postgres user by typing the following:

    \q exit

## Do Not Allow Remote Connections

One simple way to remove a potential attack vector is to not allow remote connections to the database. This is the current default when installing PostgreSQL from the Ubuntu repositories.

We can double check that no remote connections are allowed by looking in the host based authentication file:

    sudo nano /etc/postgresql/9.1/main/pg\_hba.conf

    local all postgres peer local all all peer host all all 127.0.0.1/32 md5 host all all ::1/128 md5

I have removed the comments from the output above.

As you can see, the first two security lines specify "local" as the scope that they apply to. This means they are using Unix/Linux domain sockets.

The second two declarations are remote, but if we look at the hosts that they apply to (127.0.0.1/32 and ::1/128), we see that these are interfaces that specify the local machine.

### **What If You Need To Access the Databases Remotely?**

To access PostgreSQL from a remote location, consider using SSH to connect to the database machine and then using a local connection to the database from there.

It is also possible to **tunnel** access to PostgreSQL through SSH so that the client machine can connect to the remote database as if it were local. You can learn how to [tunnel PostgreSQL through SSH](http://www.postgresql.org/docs/9.1/interactive/ssh-tunnels.html) here.

Another option is to configure access using **SSL certificates**. This will allow encrypted transfer of information. You can learn to [set up SSL with PostgreSQL](http://www.postgresql.org/docs/9.1/interactive/ssl-tcp.html) with this link.

## Security Within PostgreSQL

While securing access to the prompt is important, it is also essential that you secure your data within the PostgreSQL environment. PostgreSQL accomplishes this through the use of "roles".

Log into PostgreSQL to follow along with this section:

    sudo su - postgres psql

### **Create Separate Roles for Each Application**

One way to ensure that your users and data can be separated if necessary is to assign a distinct role for each application.

To create a new role, type the following:

    CREATE ROLE role\_name WITH optional\_permissions;

To see the permissions you can assign, type:

    \h CREATE ROLE

You can alter the permissions of any role by typing:

    ALTER ROLE role\_name WITH optional\_permissions;

List the current roles and their attributes by typing:

    \du

     List of roles Role name | Attributes | Member of -----------+------------------------------------------------+----------- hello | Create DB | {} postgres | Superuser, Create role, Create DB, Replication | {} testuser | | {}

Create a new user and assign appropriate permissions for every new application that will be utilizing PostgreSQL.

### **Separate Users From Functions**

Roles are a flexible way of handling permissions. They share some aspects of users and groups, and can be made to work like either. Roles can have membership in other roles.

This gives us some unique ways of addressing permissions.

We can assign users **login** roles (such as the applications roles we spoke about above), and then we can assign those roles membership in **access** roles to perform actual functions on data.

This separation of privileges allows us to manage what each user can do on a more fine-grained level.

To test this, let's create two roles:

    CREATE ROLE login\_role WITH login; CREATE ROLE access\_role; \du

     List of roles Role name | Attributes | Member of -------------+------------------------------------------------+----------- access\_role | Cannot login | {} login\_role | | {} postgres | Superuser, Create role, Create DB, Replication | {}

As you can see, we have two new roles, one of which cannot login.

We can now create a database owned by "access\_role":

    CREATE DATABASE demo\_application WITH OWNER access\_role;

We can now connect to the database and lock down the permissions to only let "access\_role" create tables:

    \c demo\_application REVOKE ALL ON SCHEMA public FROM public; GRANT ALL ON SCHEMA public TO access\_role;

We can test this by changing users to "login\_role" and trying to create a table:

    SET ROLE login\_role; CREATE TABLE test\_table( name varchar(25));

    ERROR: permission denied for schema public

Finally, we can add "login\_role" as a member to "access\_role". This will allow it access to the same functionality that "access\_role" has.

We will reset the role to "postgres", grant "login\_role" membership within "access\_role", and then re-try the process:

    RESET ROLE; GRANT access\_role TO login\_role; SET ROLE login\_role; CREATE TABLE test\_table( name varchar(25));

    CREATE TABLE

This works.

We can now log in using "login\_role" and administer the database. This makes it easy to add or revoke the ability to work on this database.

## Conclusion

The methods discussed in this article are only a jumping off point for developing your own security strategies. Your security needs will be unique depending on the different database users and the amount and type of traffic you need to cater to.

It is recommended that you research the benefits and shortcomings of any security measures prior to implementing them on production systems. It is essential to conduct thorough testing to ensure that you have implemented the control you are looking for, and that you have not accidentally restricted legitimate use of your software.

By Justin Ellingwood
