---
author: Justin Ellingwood
date: 2013-10-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-a-basic-ldap-server-on-an-ubuntu-12-04-vps
---

# How To Install and Configure a Basic LDAP Server on an Ubuntu 12.04 VPS

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operate a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
This guide might still be useful as a reference, but may not work on other Ubuntu releases. If available, we strongly recommend using a guide written for the version of Ubuntu you are using. You can use the search functionality at the top of the page to find a more recent version.

## Introduction

* * *

LDAP, or Lightweight Directory Access Protocol, is a protocol for managing related information from a centralized location through the use of a file and directory hierarchy.

It functions in a similar way to a relational database in certain ways, and can be used to organize and store any kind of information. LDAP is commonly used for centralized authentication.

In this guide, we will cover how to install and configure an OpenLDAP server on an Ubuntu 12.04 VPS. We will populate it with some users and groups. In a later tutorial, [authentication using LDAP](https://www.digitalocean.com/community/articles/how-to-authenticate-client-computers-using-ldap-on-an-ubuntu-12-04-vps) will be covered.

## Install LDAP

* * *

The OpenLDAP server is in Ubuntu’s default repositories under the package “slapd”, so we can install it easily with apt-get. We will also install some additional utilities:

    sudo apt-get update
    sudo apt-get install slapd ldap-utils

You will be asked to enter and confirm an administrator password for the administrator LDAP account.

### Reconfigure slapd

* * *

When the installation is complete, we actually need to reconfigure the LDAP package. Type the following to bring up the package configuration tool:

    sudo dpkg-reconfigure slapd

You will be asked a series of questions about how you’d like to configure the software.

- Omit OpenLDAP server configuration? **No**

- DNS domain name?

- Organization name?

- Administrator password?

- Database backend to use? **HDB**

- Remove the database when slapd is purged? **No**

- Move old database? **Yes**

- Allow LDAPv2 protocol? **No**

## Install PHPldapadmin

* * *

We will be administering LDAP through a web interface called PHPldapadmin. This is also available in Ubuntu’s default repositories.

Install it with this command:

    sudo apt-get install phpldapadmin

That will install all of the required web server and PHP dependencies.

### Configure PHPldapadmin

* * *

We need to configure some values within the web interface configuration files before trying it out.

Open the configuration file with root privileges:

    sudo nano /etc/phpldapadmin/config.php

Search for the following sections and modify them accordingly.

Change the red value to the way you will be referencing your server, either through domain name or IP address.

    $servers-\>setValue('server','host','domain\_nam\_or\_IP\_address');

For the next part, you will need to reflect the same value you gave when asked for the DNS domain name when we reconfigured “slapd”.

You will have to convert it into a format that LDAP understands by separating each domain component. Domain components are anything that is separated by a dot.

These components are then given as values to the “dc” attribute.

For instance, if your DNS domain name entry was “imaginary.lalala.com”, LDAP would need to see “dc=imaginary,dc=lalala,dc=com”. Edit the following entry to reflect the name you selected (ours is “test.com” as you recall):

    $servers-\>setValue('server','base',array('dc=test,dc=com'));

The next value to modify will use the same domain components that you just set up in the last entry. Add these after the “cn=admin” in the entry below:

    $servers-\>setValue('login','bind\_id','cn=admin,dc=test,dc=com');

Search for the following section about the “hide_template_warning” attribute. We want to uncomment this line and set the value to “true” to avoid some annoying warnings that are unimportant.

    $config-\>custom-\>appearance['hide\_template\_warning'] = true;

Save and close the file.

### Log Into the Web Interface

* * *

You can access by going to your domain name or IP address followed by “/phpldapadmin” in your web browser:

    domain\_name\_or\_IP\_address/phpldapadmin

![PHPldapadmin inital screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/phpldap_initial.png)

Click on the “login” link on the left-hand side.

You will receive a login prompt. The correct Login DN (distinguished name) should be pre-populated if you configured PHPldapadmin correctly. In our case, this would be “cn=admin,dc=test,dc=com”.

![PHPldapadmin login](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/phpldap_login.png)

Enter the password you selected during our slapd configuration.

You will be presented with a rather sparse interface initially.

![PHPldapadmin logged in](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/phpldap_logged_in.png)

If you click on the “plus” next to the domain components (dc=test,dc=com), you will see the admin login we are using.

![PHPldapadmin admin entry](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/phpldap_admin_entry.png)

## Add Organizational Units, Groups, and Users

* * *

LDAP is very flexible. You can create hierarchies and relationships in many different ways, depending on what kind of information you need accessible and what kind of use case you have.

We will create some basic structure to our information and then populate it with information.

### Create Organizational Units

* * *

First, we will create some categories of information where we will place the later information. Because this is a basic setup, we will only need two categories: groups and users.

Click on the “Create new entry here” link on the left-hand side.

Here, we can see the different kinds of entries we can create.

![LDAP object selection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/object_selection.png)

Because we are only using this as an organizational structure, rather than an information-heavy entry, we will use the “Generic: Organizational Unit” template.

We will be asked to create a name for our organizational unit. Type “groups”:

![LDAP groups name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/groups_name.png)

We will then need to commit the changes.

![LDAP commit ou](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/commit_ou.png)

When this is complete, we can see a new entry on the left-hand side.

![LDAP ou groups](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/ou_groups.png)

We will create one more organizational structure to get ourselves going. Repeat the procedure, but this time, use the name “users”.

When you are done, you should have something that looks like this:

![LDAP ou complete](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/ou_complete.png)

### Create Groups

* * *

We will be creating three different groups that could be used to organize users into different “access” groups based on the privileges they require.

We will create an “admin” group, an “irc” group, and a “user” group. We could then allow members of different groups to authenticate if we set up client LDAP authentication.

We want to create the groups within the “groups” organizational unit. Click on the “groups” category we created. In the main pane, click on the “Create a child entry” within the groups category.

![LDAP child of groups](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/child_groups.png)

This time, we will choose the “Generic: Posix Group” category.

![LDAP posix group](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/posix_group.png)

Fill in “admin” as the group name. Click “Create Object” and then confirm on the next page.

![LDAP admin group](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/admin_group.png)

Repeat the process, but simply replace the “admin” name with “irc” and “user”. Be sure to re-click the “ou=groups” entry before creating child entries, or else you may create entries under the wrong category.

You should now have three groups in the left-hand panel:

![LDAP three groups](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/three_groups.png)

You can see an overview of the entries in the “ou=groups” category by clicking on that entry, and then clicking on “View 3 children”:

![LDAP view three children](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/view_three_children.png)

### Create Users

* * *

Next, we will create users to put in these groups. Start by clicking the “ou=users” category. Click on “Create a child entry”.

We will choose “Generic: User Account” for these entries.

![LDAP user account](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/user_account.png)

We will be given a lot of fields to fill out:

![LDAP user fields](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/user_fields.png)

Fill in all of the entries with information that makes sense for your user.

Something to keep in mind is that the “Common Name” needs to be unique for each entry in a category. So you may want to use a username format instead of the default “FirstName LastName” that is auto-populated.

Click “Create Object” at the bottom and confirm on the following page.

To create additional users, we will take advantage of the ability to copy entries.

Click on the user you just created in the left-hand panel. In the main pane, click “Copy or move this entry”:

![LDAP copy user entry](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/copy_entry.png)

Adjust the “cn=user” portion of the entry to point it to the common name you’d like to use for the new entry. Click “Copy” at the bottom:

![LDAP copy common name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/copy_common_name.png)

You will be given the next page populated with your first users data. You will need to adjust it to match the new users information.

Be sure to adjust the uidNumber. Click the “Create Object” button at the bottom.

### Add Users to Groups

* * *

We can add users to various groups by clicking on the group in question. In the main pane, select “Add new attribute”:

![LDAP add new attribute](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/add_new_attr.png)

Select “memberUid” from the drop down menu:

![LDAP memberuid entry menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/memberuid_entry.png)

In the text field that populates, enter the first user you’d like to add. Click “Update Object” at the bottom:

![LDAP add user2](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/add_user2.png)

You can then add more members by clicking “modify group members” and selecting them from the available choices:

![LDAP user choices](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ldap_basics/user_choices.png)

## Conclusion

* * *

You should now have a basic LDAP server set up with a few users and groups. You can expand this information and add all of the different organizational structures to replicate the structure of your business.

We will cover in another section [how to authenticate using the LDAP credentials](https://www.digitalocean.com/community/articles/how-to-authenticate-client-computers-using-ldap-on-an-ubuntu-12-04-vps) for various services.

By Justin Ellingwood
