---
author: Justin Ellingwood
date: 2015-05-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-and-use-ldap-servers-with-openldap-utilities
---

# How To Manage and Use LDAP Servers with OpenLDAP Utilities

## Introduction

LDAP systems can seem difficult to manage if you do not have a good grasp on the tools available and the information and methods that LDAP requires. In this guide, we will be demonstrating how to use the LDAP tools developed by the OpenLDAP team to interact with an LDAP directory server.

## Prerequisites

To get started, you should have access to a system with OpenLDAP installed and configured. You can learn how to set up an OpenLDAP server [here](how-to-install-and-configure-openldap-and-phpldapadmin-on-an-ubuntu-14-04-server). You should be familiar with the basic terminology used when working with an LDAP directory service. [This guide](understanding-the-ldap-protocol-data-hierarchy-and-entry-components) can be used to get more familiar with these topics.

## Installing the Tools

The prerequisites above assume that you already have access to an LDAP system, but you may not already have the OpenLDAP tools discussed in this guide installed.

On an Ubuntu or Debian system, you can install these tools through the `apt` repositories. Update your local package index and install by typing:

    sudo apt-get update
    sudo apt-get install ldap-utils

On CentOS or Fedora, you can get the appropriate files by using `yum`. Install them by typing:

    sudo yum install openldap-clients

Once you have the correct packages installed, continue below.

## Connecting to the LDAP Instance

Most of the OpenLDAP tools are extremely flexible, sacrificing a concise command structure for the ability to interact with systems in several different roles. Because of this, a user must select a variety of arguments just to express the bare minimum necessary to connect to an LDAP server.

In this section, we’ll focus on constructing the arguments needed to contact the server depending on the type of operation you wish to perform. The arguments discussed here will be used in a variety of tools, but we will use `ldapsearch` for demonstration purposes.

### Specifying the Server

The OpenLDAP tools require that you specify an authentication method and a server location for each operation. To specify the server, use the `-H` flag followed by the protocol and network location of the server in question.

For basic, unencrypted communication, the protocol scheme will be `ldap://` like this:

    ldapsearch -H ldap://server_domain_or_IP . . .

If you are communicating with a local server, you can leave off the server domain name or IP address (you still need to specify the scheme).

If you are using LDAP over SSL to connect to your LDAP server, you will instead want to use the `ldaps://` scheme (note that this is a deprecated method. The OpenLDAP project recommends using a STARTTLS upgrade on the normal LDAP port instead. Learn how to set this up here):

    ldapsearch -H ldaps://server_domain_or_IP . . .

These protocols assume the default port (`389` for conventional LDAP and `636` for LDAP over SSL). If you are using a non-standard port, you’ll need to add that onto the end with a colon and the port number.

To connect to an LDAP directory on the server you are querying from over Linux IPC (interprocess communication), you can use the `ldapi://` protocol. This is more secure and necessary for some administration tasks:

    ldapsearch -H ldapi:// . . .

Since the `ldapi` scheme requires a local connection, we never will have to specify a server name here. However, if you changed the socket-file location within the LDAP server configuration, you will need to specify the new socket location as part of the address.

### Anonymous Bind

LDAP requires that clients identify themselves so that the server can determine the level of access to grant requests. This works by using an LDAP mechanism called “binding”, which is basically just a term for associating your request with a known security entity. There are three separate types of authentication that LDAP understands.

The most generic type of authentication that a client can use is an “anonymous” bind. This is pretty much the absence of authentication. LDAP servers can categorize certain operations as accessible to anyone (typically, by default, the public-facing DIT is configured as read-only for anonymous users). If you are using an anonymous bind, these operations will be available to you.

The OpenLDAP tools assume SASL authentication (we’ll discuss this momentarily) by default, so to allow an anonymous bind, we must give the `-x` argument. Combined with the server specification, this will look something like this:

    ldapsearch -H ldap://server_domain_or_IP -x

If you type that in without providing additional arguments, you should get something like this:

Output for ldapsearch with an anonymous bind

    # extended LDIF
    #
    # LDAPv3
    # base <> (default) with scope subtree
    # filter: (objectclass=*)
    # requesting: ALL
    #
    
    # search result
    search: 2
    result: 32 No such object
    
    # numResponses: 1

This says that the tool didn’t find what we searched for. Since we didn’t provide query parameters, this is expected, but it does show us that our anonymous bind was accepted by the server.

### Simple Authentication

The second method of authenticating to an LDAP server is with a simple bind. A simple bind uses an entry within the LDAP server to authenticate the request. The DN (distinguished name) of the entry functions as a username for the authentication. Inside of the entry, an attribute defines a password which must be provided during the request.

#### Finding the DIT Root Entry and the RootDN Bind

To authenticate using simple authentication, you need to know the parent element at the top of the DIT hierarchy, called the root, base, or suffix entry, under which all other entries are placed. You also need to know of a DN to bind to.

Typically, during installation of the LDAP server, an initial DIT is set up and configured with an administrative entry, called the rootDN, and a password. When starting out, this will be the only DN that is configured for binds.

If you do not know the root entry of the LDAP server you are connecting to, you can query a special “meta” entry outside of the normal LDAP DIT for information about what DIT root entries it knows about (this is called the root DSE). You can query this entry for the DIT names by typing:

    ldapsearch -H ldap://server_domain_or_IP -x -LLL -s base -b "" namingContexts

The LDAP server should return the root entries that it knows about, which will look something like this:

LDAP root entry results

    dn:
    namingContexts: dc=example,dc=com

The highlighted area is the root of the DIT. We can use this to search for the entry to bind to. The admin entry typically uses the `simpleSecurityObject` objectClass in order to gain the ability to set a password in the entry. We can use this to search for entry’s with this class:

    ldapsearch -H ldap://server_domain_or_IP -x -LLL -b "dc=example,dc=com" "(objectClass=simpleSecurityObject)" dn

This will give you a list of the entries that use this class. Usually there is only one:

simpleSecurityObject search results

    dn: cn=admin,dc=example,dc=com

This is the rootDN account that we can bind to. You should have configured a password for this account during the server’s installation. If you do not know the password, you can follow [this guide](how-to-change-account-passwords-in-an-ldap-server) to reset the password.

#### Performing the Bind

Once you have an entry and password, you can perform a simple bind during your request to authenticate yourself to the LDAP server.

Again, we will have to specify the LDAP server location and provide the `-x` flag to indicate that we don’t wish to use SASL authentication. To perform the actual bind, we will need to use the `-D` flag to specify the DN to bind to, and provide a password using the `-w` or `-W` command. The `-w` option allows you to supply a password as part of the command, while the `-W` option will prompt you for the password.

An example request binding to the rootDN would look like this:

    ldapsearch -H ldap://server_domain_or_IP -x -D "cn=admin,dc=example,dc=com" -W

We should get the same result as our anonymous bind, indicating that our credentials were accepted. Binding to an entry often gives you additional privileges that are not available through an anonymous bind. Binding to the rootDN gives you read/write access to the entire DIT, regardless of access controls.

### SASL Authentication

SASL stands for simple authentication and security layer. It is a framework for hooking up authentication methods with protocols in order to provide a flexible authentication system that is not tied to a specific implementation. You can check out the [wikipedia page](http://en.wikipedia.org/wiki/Simple_Authentication_and_Security_Layer#SASL_mechanisms) to learn about the various methods available.

Your LDAP server will probably only support a subset of the possible SASL mechanisms. To find out which mechanisms it allows, you can type:

    ldapsearch -H ldap:// -x -LLL -s base -b "" supportedSASLMechanisms

The results that you see will differ depending on the scheme that you used to connect. For the unencrypted `ldap://` scheme, most systems will default to allowing:

ldap:// supportedSASLMechanisms

    dn:
    supportedSASLMechanisms: DIGEST-MD5
    supportedSASLMechanisms: NTLM
    supportedSASLMechanisms: CRAM-MD5

If you are using the `ldapi://` scheme, which uses secure interprocess communication, you will likely have an expanded list of choices:

    ldapsearch -H ldapi:// -x -LLL -s base -b "" supportedSASLMechanisms

ldapi:// supportedSASLMechanisms

    dn:
    supportedSASLMechanisms: DIGEST-MD5
    supportedSASLMechanisms: EXTERNAL
    supportedSASLMechanisms: NTLM
    supportedSASLMechanisms: CRAM-MD5
    supportedSASLMechanisms: LOGIN
    supportedSASLMechanisms: PLAIN

Configuring most SASL methods of authentication can take some time, so we will not cover much of the details here. While SASL authentication is generally outside of the scope of this article, we should talk about the `EXTERNAL` method that we see available for use with the `ldapi://` scheme.

The `EXTERNAL` mechanism indicates that authentication and security is handled by some other means associated with the connection. For instance, it can be used with SSL to provide encryption and authentication.

Most commonly, you will see it used with with the `ldapi://` interface with the root or `sudo` users. Since `ldapi://` uses Unix sockets, the user initiating the request can be obtained, and used to authenticate for certain operations. The DIT that LDAP uses for configuration uses this mechanism to authenticate the root user to read and make changes to LDAP. These requests look something like this:

    sudo ldapsearch -H ldapi:// -Y EXTERNAL . . .

This is used to modify the LDAP configuration that is typically kept in a DIT starting with a `cn=config` root entry.

### Setting Up an .ldaprc File

We have been specifying the connection information mainly on the command line so far. However, you can save yourself some typing by putting some of the common connection values in a configuration file.

The global client configuration file is located at `/etc/ldap/ldap.conf`, but you’ll mainly want to add changes to your user’s configuration file located in your home directory at `~/.ldaprc`. Create and open a file with this name in your text editor:

    nano ~/.ldaprc

Inside, the basic settings you probably want to configure are `BASE`, `URI`, and `BINDDN`:

- **`BASE`** : The default base DN used to specify the entry where searches should start. This will be overridden if another search base is provided on the command line (we’ll see more of this in the next section).
- **`URI`** : The address where the LDAP server can be reached. This should include a scheme (`ldap` for regular LDAP, `ldaps` for LDAP over SSL, and `ldapi` for LDAP over an IPC socket) followed by the name and port of the server. The name can be left off if the server is located on the same machine and the port can be left off if the server is running on the default port for the scheme selected.
- **`BINDDN`** : This specifies the default LDAP entry to bind to. This is used to provide the “account” information for the access you wish to use. You will still need to specify any password on the command line.

This will take care of the simple authentication information. If you are using SASL authentication, check out `man ldap.conf` to see the options for configuring SASL credentials.

If our LDAP’s base entry is `dc=example,dc=com`, the server is located on the local computer, and we are using the `cn=admin,dc=example,dc=com` to bind to, we might have an `~/.ldaprc` file that looks like this:

~/.ldaprc

    BASE dc=example,dc=com
    URI ldap://
    BINDDN cn=admin,dc=example,dc=com

Using this, we could perform a basic search by just specifying non-SASL authentication and providing the password associated with the admin entry. This would provide a full subtree search of the default base DN we specified:

    ldapsearch -x -w password

This can help shorten your the “boilerplate” connection options as you use the LDAP utilities. Throughout this guide, we’ll include the connection info in the commands in order to be explicit, but when running the commands, you can remove any portion that you’ve specified in your configuration file.

## Using ldapsearch to Query the DIT and Lookup Entries

Now that we have a good handle on how to authenticate to and specify an LDAP server, we can begin talking a bit more about the actual tools that are at your disposal. For most of our examples, we’ll assume we are performing these operations on the same server that hosts the LDAP server. This means that our host specification will be blank after the scheme. We’ll also assume that the base entry of the DIT that the server manages is for `dc=example,dc=com`. The rootDN will be `cn=admin,dc=example,dc=com`. Let’s get started.

We’ll start with `ldapsearch`, since we have been using it in our examples thus far. LDAP systems are optimized for search, read, and lookup operations. If you are utilizing an LDAP directory, the majority of your operations will probably be searches or lookups. The `ldapsearch` tool is used to query and display information in an LDAP DIT.

We’ve covered part of the syntax that is responsible for naming and connecting to the server, which looks something like this:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -W

This gets us the bare minimum needed to connect and authenticate to the LDAP instance running on the server, however, we’re not really searching for anything. To learn more, we’ll have to discuss the concepts of search base and search scope.

### Search Base and Scope

In LDAP, the place where a search begins is called the **search base**. This is an entry within a DIT from which the operation will commence and acts as an anchor. We specify the search base by passing the entry name with the `-b` flag.

For instance, to start at the root of our `dc=example,dc=com` DIT, we can use that as the search base, like this:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com"

This command should produce every entry beneath the `dc=example,dc=com` entry that the user you have bound to has access to. If we use a different entry, would get another section of the tree. For instance, if we start at the admin entry, you may only get the admin entry itself:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "cn=admin,dc=example,dc=com"

search base at cn=admin,dc=example,dc=com

    # extended LDIF
    #
    # LDAPv3
    # base <cn=admin,dc=example,dc=com> with scope subtree
    # filter: (objectclass=*)
    # requesting: ALL
    #
    
    # admin, example.com
    dn: cn=admin,dc=example,dc=com
    objectClass: simpleSecurityObject
    objectClass: organizationalRole
    cn: admin
    description: LDAP administrator
    userPassword:: e1NTSEF9ejN2UmHoRjdha09tQY96TC9IN0kxYUVCSjhLeXBsc3A=
    
    # search result
    search: 2
    result: 0 Success
    
    # numResponses: 2
    # numEntries: 1

We have specified the base in these examples, but we can further shape the way that the tool looks for results by specifying the search scope. This option is set by the `-s` option and can be any of the following:

- **`sub`** : The default search scope if no other is specified. This searches the base entry itself and any descendants all of the way down the tree. This is the largest scope.
- **`base`** : This only searches the search base itself. It is used to return the entry specified in the search base and better defined as a lookup than a search.
- **`one`** : This searches only the immediate descendants/children of the search base (the single hierarchy level below the search base). This does not include the search base itself and does not include the subtree below any of these entries.
- **`children`** : This functions the same as the `sub` scope, but it does not include the search base itself in the results (searches every entry beneath, but not including the search base).

Using the `-s` flag and the `-b` flag, we can begin to shape the areas of the DIT that we want the tool to look in. For instance, we can see all of the first-level children of our base entry by using the `one` scope, like this:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -s one -LLL dn

We added `-LLL dn` to the end to filter the output a bit. We’ll discuss this further later in the article. If we had added a few more entries to the tree, this might have returned results like this:

output

    dn: cn=admin,dc=example,dc=com
    
    dn: ou=groups,dc=example,dc=com
    
    dn: ou=people,dc=example,dc=com

If we wanted to see everything under the `ou=people` entry, we could set that as the search base and use the `children` scope:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "ou=people,dc=example,dc=com" -s children -LLL dn

By tweaking the search base and search scope, you can operate on just the portions of the DIT that you are interested in. This will make your query perform better by only searching a section of the tree and it will only return the entries you are interested in.

### Removing Extraneous Output

Before moving on, let’s talk about how to remove some of the extra output that `ldapsearch` produces.

The majority of the extra output is controlled with `-L` flags. You can use zero to three `-L` flags depending on the level of output that you’d like to see. The more `-L` flags you add, the more information is suppressed. It might be a good idea to refrain from suppressing any output when learning or troubleshooting, but during normal operation, using all three levels will probably lead to a better experience.

If you are using SASL authentication, when modifying the `cn=config` DIT for instance, you can additionally use the `-Q` flag. This will enable SASL quiet mode, which will remove any SASL-related output. This is fine when using the `-Y EXTERNAL` method, but be careful if you are using a mechanism that prompts for credentials because this will be suppressed as well (leading to an authentication failure).

### Search Filters and Output Attribute Filters

To actually perform a search instead of simply outputting the entirety of the search scope, you need to specify the search filter.

These can be placed towards the end of the line and take the form of an attribute type, a comparison operator, and a value. Often, they are specified within quotation marks to prevent interpretation by the shell. Parentheses are used to indicate the bounds of one filter from another. These are optional in simple, single-attribute searches, but required in more complex, compound filters. We’ll use them here to better indicate where the search filter is.

As an example, we could see if there is an entry within the `dc=example,dc=com` DIT with a username (`uid`) attribute set to “jsmith”. This searches each entry within the search scope for an attribute set to that value:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL "(uid=jsmith)"

We used the equality operator in the above example, which tests for an exact match of an attribute’s value. There are various other operator as well, which function as you would expect. For example, to search for entries that _contain_ an attribute, without caring about the value set, you can use the “presence” operator, which is simply an equals sign with a wildcard on the right side of the comparison. We could search for entries that contain a password by typing:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL "(userPassword=*)"

Some search filters that are useful are:

- **Equality** : Uses the `=` operator to match an exact attribute value.
- **Presence** : Uses `=*` to check for the attribute’s existence without regard to its value.
- **Greater than or equal** : Uses the `>=` operator to check for values greater than or equal to the given value.
- **Less than or equal** : Uses the `<=` operator to check for values less than or equal to the given value.
- **Substring** : Uses `=` with a string and the `*` wildcard character as part of a string. Used to specify part of the value you are looking for.
- **Proximity** : Uses the `~=` operator to approximately match what is on the right. This is not always supported by the LDAP server (in which case an equality or substring search will be performed instead).

You can also negate most of the searches by wrapping the search filter in an additional set of parentheses prefixed with the “!” negation symbol. For example, to search for all organizational unit entries, we could use this filter:

    "(ou=*)"

To search for all entries that are _not_ organizational unit entries, we could use this filter:

    "(!(ou=*)"

The negation modifier reverses the meaning of the search filter that follows.

Following the filter specification, we can also add attribute output filters. This is just a list of attributes that you wish to display from each matched entry. By default, every attribute that your credentials have read access to are displayed for each matched entry. Setting an attribute output filter allows you to specify exactly what type of output you’d like to see.

For instance, we can search for all entries that have user IDs, but only display the associated _common name_ of each entry by typing:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL "(uid=*)" cn

This might produce a list that looks like this:

Output

    dn: uid=bwright,ou=People,dc=example,dc=com
    cn: Brian Wright
    
    dn: uid=jsmith1,ou=People,dc=example,dc=com
    cn: Johnny Smith
    
    dn: uid=sbrown2,ou=People,dc=example,dc=com
    cn: Sally Brown

If we want to see their entry description as well, we can just add that to the list of attributes to display:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -b "dc=example,dc=com" -LLL "(uid=*)" cn description

It would instead show something like this:

Output

    dn: uid=bwright,ou=People,dc=example,dc=com
    cn: Brian Wright
    description: Brian Wright from Marketing. Brian takes care of marketing, pres
     s, and community. Ask him for help if you need any help with outreach.
    
    dn: uid=jsmith1,ou=People,dc=example,dc=com
    cn: Johnny Smith
    description: Johnny Smith from Accounting. Johnny is in charge of the company
      books and hiring within the Accounting department.
    
    dn: uid=sbrown2,ou=People,dc=example,dc=com
    cn: Sally Brown
    description: Sally Brown from engineering. Sally is responsible for designing
      the blue prints and testing the structural integrity of the design.

If no attribute filter is given, all attributes are returned. This can be made explicit with the “\*” character. To return operational attributes (special metadata attributes managed in the background for each entry), you can use the special “+” symbol. For instance, to see the operational attributes for our rootDN, we could type:

    ldapsearch -H ldap:// -x -D "cn=admin,dc=example,dc=com" -b "dc=example,dc=com" -LLL "(cn=admin)" "+"

The results would look something like this:

Output

    dn: cn=admin,dc=example,dc=com
    structuralObjectClass: organizationalRole
    entryUUID: cdc718a0-8c3c-1034-8646-e30b83a2e38d
    creatorsName: cn=admin,dc=example,dc=com
    createTimestamp: 20150511151904Z
    entryCSN: 20150514191233.782384Z#000000#000#000000
    modifiersName: cn=admin,dc=example,dc=com
    modifyTimestamp: 20150514191233Z
    entryDN: cn=admin,dc=example,dc=com
    subschemaSubentry: cn=Subschema
    hasSubordinates: FALSE

### Compound Searching

Compound searching involves combining two or more individual search filters to get more precise results. Search filters are combined by wrapping them in another set of parentheses with a relational operator as the first item. This is easier demonstrated than explained.

The relational operators are the “&” character which works as a logical AND, and the “|” character, which signifies a logical OR. These precede the filters whose relationships they define within an outer set of parentheses.

So to search for an entry that has both a description and an email address in our domain, we could construct a filter like this:

    "(&(description=*)(mail=*@example.com))"

For an entry to be returned, it must have both of those attributes defined.

The OR symbol will return the results if either of the sub-filters are true. If we want to output entries for which we have contact info, we might try a filter like this:

    "(|(telephoneNumber=*)(mail=*)(street=*))"

Here, we see that the operator can apply to more than two sub-filters. We can also nest these logical constructions as needed to create quite complex patterns.

## Using ldapmodify and Variations to Change or Create LDAP Entries

So far, we have focused exclusively on the `ldapsearch` command, which is useful for looking up, searching, and displaying entries and entry segments within an LDAP DIT. This will satisfy the majority of users’ read-only requirements, but we need a different tool if we want to change the objects in the DIT.

The `ldapmodify` command manipulates a DIT through the use of LDIF files. You can learn more about LDIF files and the specifics of how to use these to modify or add entries by looking at [this guide](how-to-use-ldif-files-to-make-changes-to-an-openldap-system).

The basic format of `ldapmodify` closely matches the `ldapsearch` syntax that we’ve been using throughout this guide. For instance, you will still need to specify the server with the `-H` flag, authenticate using the `-Y` flag for SASL authentication or the `-x`, `-D`, and `-[W|w]` flags for simple authentication.

### Applying Changes from an LDIF File

After providing these boilerplate options, the most common action is to read in an LDIF file and apply it to the DIT. This can be accomplished with the `-f` option (if you do not use the `-f` option, you will have to type in a change using the LDIF format on the command line). You will need to create the LDIF file yourself, using the syntax described in the guide linked to above:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -f /path/to/file.ldif

This will read the LDIF file and apply the changes specified within. For the `ldapmodify` command, each LDIF change should have a `changetype` specified. The `ldapmodify` command is the most general form of the DIT manipulation commands.

If your LDIF file is adding new entries and _does not_ include `changetype: add` for each entry, you can use the `-a` flag with `ldapmodify`, or simply use the `ldapadd` command, which basically aliases this behavior. For example, an LDIF file which _includes_ the `changetype` would look like this:

LDIF with changetype

    dn: ou=newgroup,dc=example,dc=com
    changetype: add
    objectClass: organizationalUnit
    ou: newgroup

To process this file, you could simply use `ldapmodify`:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -f /path/to/file.ldif

However, the file could also be constructed _without_ the `changetype`, like this:

LDIF without changetype

    dn: ou=newgroup,dc=example,dc=com
    objectClass: organizationalUnit
    ou: newgroup

In this case, to add this entry to the DIT, you would either need to use the `-a` flag with `ldapmodify`, or use the `ldapadd` command. Either:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -a -f /path/to/file.ldif

Or this:

    ldapadd -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -f /path/to/file.ldif

Similar commands are available for entry deletion (`ldapdelete`) and moving LDAP entries (`ldapmodrdn`). Using these commands eliminates the need for you to specify `changetype: delete` and `changetype: modrdn` explicitly in the files, respectively. For each of these, it is up to you which format to use (whether to specify the change in the LDIF file or on the command line).

### Testing Changes and Handling Errors

If you want to do a dry run of any LDIF file, you can use the `-n` and `-v` flags. This will tell you what change would be performed without modifying the actual DIT:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -n -v -f /path/to/file.ldif

Typically, if an error occurs while processing an LDIF file, the operation halts immediately. This is generally the safest thing to do because often, change requests later in the file will modify the DIT under the assumption that the earlier changes were applied correctly.

However, if you want the command to continue through the file, skipping the error-causing changes, you can use the `-c` flag. You’ll probably also want to use the `-S` flag to point to a file where the errors can be written to so that you can fix the offending requests and re-run them:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w password -c -S /path/to/error_file -f /path/to/file.ldif

This way, you will have a log (complete with comments indicating the offending entries) to evaluate after the operation.

## Various Other LDAP Commands

The commands that we’ve already covered perform the most common LDAP operations you will use on a day-to-day basis. There are a few more commands though that are useful to know about.

### ldappasswd

If some of your LDAP entries have passwords, the `ldappasswd` command can be used to modify the entry. This works by authenticating using the account in question or an administrative account and then providing the new password (and optionally the old password).

The old password should be specified using either the `-a` flag (the old password is given in-line as the next item), the `-A` flag (the old password is prompted for), or the `-t` flag (the old password is read from the file given as the next item). This is optional for some LDAP implementations but required by others, so it is best to include.

The new password should be specified using either the `-s` flag (the new password is given in-line as the next item), the `-S` flag (the new password is prompted for), or the `-T` flag (the new password is read from the file given as the next item).

So a typical change may look like this:

    ldappasswd -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w oldpassword -a oldpassword -s newpassword

If no entry is given, the entry that is being used for binding will be changed. If you are binding to an administrative entry, you can change other entries that you have write access to by providing them after the command.

    ldappasswd -H ldap:// -x -D "cn=admin,dc=example,dc=com" -w adminpassword -a oldpassword -s newpassword "uid=user,dc=example,dc=com"

To learn more about changing and resetting passwords, check out [this guide](how-to-change-account-passwords-in-an-ldap-server).

### ldapwhoami

The `ldapwhoami` command can tell you how the LDAP server sees you after authenticating.

If you are using anonymous or simple authentication, the results will probably not be too useful (“anonymous” or exactly the entry you are binding to, respectively). However, for SASL authentication, this can provide insight into how your authentication mechanism is being seen.

For instance, if we use the `-Y EXTERNAL` SASL mechanism with `sudo` to perform operations on the `cn=config` DIT, we could check with `ldapwhoami` to see the authentication DN:

    sudo ldapwhoami -H ldapi:// -Y EXTERNAL -Q

ldapwhoami output

    dn:gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth

This is not an actual entry in our DIT, it is just how SASL authentication gets translated into a format that LDAP can understand. Seeing the authentication DN can be used to create mappings and access restrictions though, so it is good to know how to get this information.

### ldapurl

The `ldapurl` tool allows you to construct LDAP URLs by specifying the various components involved in your query. LDAP URLs are a way that you can request resources from an LDAP server through a standardized URL. These are unauthenticated connections and are read-only. Many LDAP solutions no longer support LDAP URLs for requesting resources, so their use may be limited depending on the software you are using.

The standard LDAP URL is formatted using the following syntax:

    ldap://host:port/base_dn?attr_to_return?search_scope?filter?extension

The components are as follows:

- `base_dn`: The base DN to begin the search from.
- `attr_to_return`: The attributes from the matching entities that you’re interested in. These should be comma-separated.
- `search_scope`: The search scope. Either base, sub, one, or children.
- `filter`: The search filter used to select the entries that should be returned.
- `extension:` The LDAP extensions that you wish to specify. We won’t cover these here.

Each of the items are separated in the URL with a question mark. You do not have to provide the items that you aren’t using, but since the item type is identified by its position in the string, you must leave the “slot” empty for that item, which will leave you with multiple question marks in a row. You can stop the URL as soon as you have added your information (you don’t need question marks at the end to represent unused “slots”).

For example, a URL might look like this:

    ldap://localhost:389/dc=example,dc=com?dn,ou?sub?(ou=*)

If you were to feed this into the `ldapurl` tool, you’d use the `-H` flag and put the URL in quotes:

    ldapurl -H "ldap://localhost:389/dc=example,dc=com?dn,ou?sub?(ou=*)"

The command would break it apart like this:

ldapurl output

    scheme: ldap
    host: localhost
    port: 389
    dn: dc=chilidonuts,dc=tk
    selector: dn
    selector: ou
    scope: sub
    filter: (ou=*)

You can also use these flags to reverse the process and cobble together an LDAP URL. These mirror the various components of the LDAP URL:

- `-S`: The URL scheme (`ldap`, `ldaps`, or `ldapi`). The `ldap` scheme is default.
- `-h`: The LDAP server name or address
- `-p`: The LDAP server port. The default value will depend on the scheme.
- `-b`: The base DN to start the query
- `-a`: A comma-separated list of attributes to return
- `-s`: The search scope to use (base, sub, children, or one)
- `-f`: The LDAP filter to select the entries to return
- `-e`: The LDAP extensions to specify

Using these, you could type something like this:

    ldapurl -h localhost -b "dc=example,dc=com" -a dn,ou -s sub -f "(ou=*)"

The command would return the constructed URL, which would look like this:

ldapurl output

    ldap://localhost:389/dc=example,dc=com?dn,ou?sub?(ou=*)

You can use this to construct URLs that can be used with an LDAP client capable of communicating using this format.

### ldapcompare

The `ldapcompare` tool can be used to compare an entry’s attribute to a value. This is used to perform simple assertion checks to validate data.

The process involves binding as you normally would depending on the data being queried, providing the entry DN and the assertion to check. The assertion is given by specifying an attribute and then a value, separated by one or two colons. For simple string values, a single colon should be used. A double colon indicates a base64 encoded value has been given.

So you can assert that John is a member of the “powerusers” group with something like this:

    ldapcompare -H ldap:// -x "ou=powerusers,ou=groups,dc=example,dc=com" "member:uid=john,ou=people,dc=example,dc=com"

If he is in the group, it will return `TRUE`. If not, the command will return `FALSE`. If the DN being used to bind doesn’t have sufficient privileges to read the attribute in question, it will return `UNDEFINED`.

This could be used as the basis for an authorization system by checking group membership prior to performing requested actions.

## Conclusion

You should now have a good idea of how to use some of the LDAP utilities to connect to, manage, and use your LDAP server. Other clients may provide a more usable interface to your LDAP system for day-to-day management, but these tools can help you learn the ropes and provide good low-level access to the data and structures of your DIT.
