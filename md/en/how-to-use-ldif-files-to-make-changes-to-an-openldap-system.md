---
author: Justin Ellingwood
date: 2015-05-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-ldif-files-to-make-changes-to-an-openldap-system
---

# How To Use LDIF Files to Make Changes to an OpenLDAP System

## Introduction

LDAP is a protocol for managing and interacting with directory services. The OpenLDAP project provides an LDAP-compliant directory service that can be used to store and provide an interface to directory data.

In this guide, we will discuss the LDIF file format that is used to communicate with LDAP directories. We will discuss the tools that you can use to process these files and modify the LDAP Directory Information Tree based on the commands specified.

## Prerequisites

Before starting this guide, you should have access to an OpenLDAP server. You can learn how to set up an OpenLDAP server [here](how-to-install-and-configure-openldap-and-phpldapadmin-on-an-ubuntu-14-04-server). You should be familiar with the basic terminology used when working with an LDAP directory service. [This guide](understanding-the-ldap-protocol-data-hierarchy-and-entry-components) can be used to get more familiar with these topics.

## LDIF Format

LDIF, or the LDAP Data Interchange Format, is a text format for representing LDAP data and commands. When using an LDAP system, you will likely use the LDIF format to specify your data and the changes you wish to make to the LDAP DIT.

LDIF is meant to be able to describe any entry within an LDAP system, as well as any modifications that must take place. Because of this, the syntax is very precise and can initially seem somewhat complex. Using LDIF, LDAP changes are simple written within files with an arbitrary name and then fed into the LDAP system using one of the available management commands.

LDIF works using a basic key-value system, with one statement per-line. The key is on the left-hand side of a line followed by a colon (:) and a space. The space is important for the line to be read correctly. The value is then assigned on the right side. This format works well for LDAP’s attribute-heavy syntax, but can also be used to issue commands and provide instructions on how the content should be interpreted.

Multiple lines can be used to provide long values for attribute by beginning the extra lines with a single space. LDAP will join these when processing the entry.

## Adding Entries to the DIT

There are two main ways of specifying a new entry within an LDIF file. The best method for your needs depends on the types of other changes you need to coordinate with. The method you choose will dictate the tools and arguments you must use to apply the changes to the LDAP DIT (directory information tree).

### Listing Entries to Add to the DIT

The most basic method of defining new entries to add to LDAP is to simply list the entries in their entirety, exactly as they would typically displayed using LDAP tools. This starts with the DN (distinguished name) where the entry will be created, after the `dn:` indicator:

    dn: ou=newgroup,dc=example,dc=com

In the line above, we reference a few key-value pairs in order to construct the DN for our new entry. When _setting_ attribute values, you must use the colon and space. When _referencing_ attributes/values, an equal sign should be used instead.

In the simplest LDIF format for adding entries to a DIT, the rest of the entry is simply written out using this format beneath the DN definition. The necessary objectClass declarations and attributes must be set to construct a valid entry. For example, to create an organizational unit to contain the entries for the employees of our organization, we could use this:

    dn: ou=People,dc=example,dc=com
    objectClass: organizationalUnit
    ou: People

You can add multiple entries in a single file. Each entry must be separated by at least one completely blank line:

    dn: ou=People,dc=example,dc=com
    objectClass: organizationalUnit
    ou: People
    
    dn: ou=othergroup,dc=example,dc=com
    objectClass: organizationalUnit
    ou: othergroup

As you can see, this LDIF format mirrors almost exactly the format you would see when querying an LDAP tree for entries with this information. You can pretty much just write what you’d like the entry to contain verbatim.

### Using “Changetype: Add” to Create New Entries

The second format that we will be looking at works well if you are making other modifications within the same LDIF file. OpenLDAP provides tools that can handle both additions and modifications, so if we are modifying other entries within the same file, we can flag our new entries as additions so that they are processed correctly.

This looks much like the method above, but we add `changetype: add` directly below the DN specification. For instance, we could add a John Smith entry to a DIT that already contains the `ou=People,dc=example,dc=com` structure using an LDIF like this:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: add
    objectClass: inetOrgPerson
    description: John Smith from Accounting. John is the project
      manager of the building project, so contact him with any que
     stions.
    cn: John Smith
    sn: Smith
    uid: jsmith1

This is basically the format we’ve been using to describe entries thus far, with the exception of an additional line after the DN specification. Here, we tell LDAP that the change we are making is an entry creation. Since we are using the `changetype` option, this entry can be processed by the `ldapmodify` tool without a problem, allowing us to place modifications of other types in the same LDIF file. The `changetype` option must come immediately after the DN specification.

Another thing to note above is the use of a multi-line value for the `description` attribute. Since the lines that follow begin with a space, they will be joined with the space removed. Our first continuation line in our example contains an additional space, but that is part of the sentence itself, separating the words “project” and “manager”.

As with the last section, each additional entry within the same file is separated by a blank line. Comments can be used by starting the line with a `#` character. Comments must exist on their own line. For instance, if we wanted to add Sally in this same LDIF file, we could separate the two entries like this:

    # Add John Smith to the organization
    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: add
    objectClass: inetOrgPerson
    description: John Smith from Accounting. John is the project
      manager of the building project, so contact him with any qu
     estions.
    cn: John Smith
    sn: Smith
    uid: jsmith1
    
    # Add Sally Brown to the organization
    dn: uid=sbrown20,ou=People,dc=example,dc=com
    changetype: add
    objectClass: inetOrgPerson
    description: Sally Brown from engineering. Sally is responsibl
     e for designing the blue prints and testing the structural int
     egrity of the design.
    cn: Sally Brown
    sn: Brown
    uid: sbrown20

### Processing Entry Additions

Now that we know how to construct LDIF files to add new entries, we need to actually process these with LDAP tools to add them to the DIT. The tool and/or arguments you use will depend on the form you chose above.

If you are using the simple entry format (without the `changetype` setting), you can use the `ldapadd` command or the `ldapmodify` command with the `-a` flag, which specifies an entry addition. You will either need to use a SASL method to authenticate with the LDAP instance (this is outside of the scope of this guide), or bind to an administrative account in your DIT and provide the required password.

For instance, if we stored our entries from the simple entry section in a file called `newgroups.ldif`, the command we would need to process the file and add the new entries would look something like this:

    ldapadd -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f newgroups.ldif

You could also use the `ldapmodify -a` combination for the same result:

    ldapmodify -a -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f newgroups.ldif

If you are using the _second_ format, with the `changetype` declaration, you will want to use the `ldapmodify` command without the `-a` flag. Since this command and format works for most other modifications, it is probably easier to use for most changes. If we stored the two new user additions within a file called `newusers.ldif`, we could add it to our existing DIT by typing something like this:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f newusers.ldif

This will allow you to add entries to your DIT at will. You can easily store many entries in a single LDIF file and populate your DIT in a single command.

## Deleting Entries from the DIT

We had our first glimpse of the `changetype` option in the last section. This option provides the method for specifying the high-level type of modification we wish to make. For an entry deletion, the value of this option is “delete”.

Entry deletion is actually the most straight-forward change that you can perform because the only piece of information needed is the DN.

For instance, if we wanted to remove the `ou=othergroup` entry from our DIT, our LDIF file would only need to contain this:

    dn: ou=othergroup,dc=example,dc=com
    changetype: delete

To process the change, you can use the exact format used with `ldapmodify` above. If we call the file with the deletion request `rmothergroup.ldif`, we would apply it like this:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f rmothergroup.ldif

This will remove the `ou=othergroup` entry from the system immediately.

## Modifying an Entry’s Attributes

Modifying an entry’s attributes is a very common change to make and is made possible by specifying `changetype: modify` after the DN of the entry. The types of modifications you can make to attributes mostly mirror the modifications you can make to an entry itself. Because of this, the details of the type of requested attribute change are specified afterwards using additional directives.

### Adding an Attribute to an Entry

For instance, you can add an attribute by using the `add:` command after `changetype: modify`. This should specify the attribute you wish to add. You would then set the value of the attribute like normal. So the basic format would be:

    dn: entry_to_add_attribute
    changetype: modify
    add: attribute_type
    attribute_type: value_to_set

For instance, to add some email addresses to our accounts, we could have an LDIF file that looks like this:

    dn: uid=sbrown20,ou=People,dc=example,dc=com
    changetype: modify
    add: mail
    mail: sbrown@example.com
    
    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    add: mail
    mail: jsmith1@example.com
    mail: johnsmith@example.com

As you can see from the second entry, you can specify multiple additions at the same time. The `mail` attribute allows for multiple values, so this is permissible.

You can process this with `ldapmodify` as normal. If the change is in the file `sbrownaddmail.ldif`, you could type:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f sbrownaddmail.ldif

### Replacing the Value of an Attribute in an Entry

Another common change is to modify the existing value for an attribute. We can do this using the `replace:` option below `changetype: modify`.

This operates in almost the same way as the `add:` command, but by default, removes every existing occurrence of the attribute from the entry and replaces it with the values defined afterwards. For instance, if we notice that our last `add:` command had an incorrect email, we could modify it with the `replace` command like this:

    dn: uid=sbrown20,ou=People,dc=example,dc=com
    changetype: modify
    replace: mail
    mail: sbrown2@example.com

Keep in mind that this will replace _every_ instance of `mail` in the entry. This is important for multi-value attributes that can be defined more than once per-entry (like `mail`). If you wish to replace only a single occurrence of an attribute, you should use the attribute `delete:` option (described below) in combination with the attribute `add:` option (described above).

If this change was stored in a file called `sbrownchangemail.ldif`, we can replace Sally’s email by typing:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f sbrownchangemail.ldif

### Delete Attributes from an Entry

If you wish to remove an attribute from an entry, you can use the `delete:` command. You will specify the attribute you wish to delete as the value of the option. If you want to delete a specific instance of the attribute, you can specify the specific key-value attribute occurrence on the following line. Otherwise, every occurrence of that attribute in the entry will be removed.

For instance, this would delete every description attribute in John Smith’s entry:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    delete: description

However, this would delete only the email specified:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    delete: mail
    mail: jsmith1@example.com

Since we gave John two email addresses earlier, the other email address should be left unchanged by this request.

If these changes were in files called `jsmithrmdesc.ldif` and `jsmithrmextramail.ldif`, we could apply them by typing:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f jsmithrmdesc.ldif
    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f jsmithrmextramail.ldif

### Specifying Multiple Attribute Changes

This is a good time to talk about specifying multiple attribute changes at the same time. For a single entry within an LDIF file, you can specify multiple attribute changes by separating them with a line populated only with the `-` character. Following the separator, the attribute change type must be specified and the required attributes must be given.

For example, we could delete John’s remaining email attribute, change his name to “Johnny Smith” and add his location by creating a file with the following contents:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    delete: mail
    -
    replace: cn
    cn: Johnny Smith
    -
    add: l
    l: New York

To apply all of these changes in one command, we’d use the same `ldapmodify` format we’ve been using all along:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f multichange.ldif

## Renaming and Moving Entries

The `changetype: modrdn` option makes it possible to rename or move existing entries. After specifying the `dn:` you wish to target, set the `changetype: modrdn` option.

### Renaming an Entry

Let’s say that we mistyped Sally’s username when we initially entered it into the system. Since that is used in the entry’s DN, it can’t simply be replaced with the `changetype: modify` and `replace:` options because the entry’s RDN would be invalid. If her real username is `sbrown200`, we could change the entry’s DN, creating any necessary attributes along the way, with an LDIF file like this:

    dn: uid=sbrown20,ou=People,dc=example,dc=com
    changetype: modrdn
    newrdn: uid=sbrown200
    deleteoldrdn: 0

We could apply this change with this command:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f fixsallydn.ldif

This would make the complete entry look something like this:

    dn: uid=sbrown200,ou=People,dc=example,dc=com
    objectClass: inetOrgPerson
    description: Sally Brown from engineering. Sally is responsibl
     e for designing the blue prints and testing the structural int
     egrity of the design.
    cn: Sally Brown
    sn: Brown
    uid: sbrown20
    uid: sbrown200
    mail: sbrown2@example.com

As you can see, our DN has been adjusted to use the new attribute/value pair. The attribute has been added to the entry to make this possible.

You may have noticed two things in the example above. First, we set an option called `deleteoldrdn` to “0”. Secondly, the resulting entry has both `uid: sbrown20` and `uid: sbrown200`.

The `deleteoldrdn` option must be set when changing the DN of an entry. Setting `deleteoldrdn` to “0” causes LDAP to keep the old attribute used in the DN alongside the new attribute in the entry. Sometimes this is what you want, but often you will want to remove the old attribute from the entry completely after the DN has changed. You can do that by setting `deleteoldrdn` to “1” instead.

Let’s pretend we made a mistake again and that Sally’s actual username is `sbrown2`. We can set `deleteoldrdn` to “1” to remove the `sbrown200` instance that is currently used in the DN from the entry after the rename. We’ll go ahead and include an additional `changetype: modify` and `delete:` pair to get rid of the other stray username, `sbrown20`, since we kept that around during the first rename:

    dn: uid=sbrown200,ou=People,dc=example,dc=com
    changetype: modrdn
    newrdn: uid=sbrown2
    deleteoldrdn: 1
    
    dn: uid=sbrown2,ou=People,dc=example,dc=com
    changetype: modify
    delete: uid
    uid: sbrown20

Apply the file like this:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f fix2sallydn.ldif

This combination will not add a new username with the change (`sbrown200` will be removed), and the second entry modification will remove the original value of the username (`sbrown20`).

### Moving an Entry

If you need to move the entry to a new location, an additional setting for `changetype: modrdn` is the `newsuperior:` option. When using this option, you can specify a new location on the DIT to move the entry to. This will place the entry under the specified parent DN during the change.

For instance, if we wanted to move Sally under the `ou=superusers` entry, we could add this entry and then move her to it by typing:

    dn: ou=superusers,dc=example,dc=com
    changetype: add
    objectClass: organizationalUnit
    ou: superusers
    
    dn: uid=sbrown2,ou=People,dc=example,dc=com
    changetype: modrdn
    newrdn: uid=sbrown2
    deleteoldrdn: 0
    newsuperior: ou=superusers,dc=example,dc=com

Assuming that this is stored in a file called `mksuperuser.ldif`, we could apply the changes like this:

    ldapmodify -x -D "cn=admin,dc=example,dc=com" -w password -H ldap:// -f mksuperuser.ldif

This results in a move and never a copy.

In this case, we did not wish to actually change the RDN of the entry, so we set the `newrdn:` value to the same value that it currently has. We could easily rename during the move too though if we so desired. In this case, the `newsuperior:` setting is the only line of the second change that actually impacts the state of the entry.

## An Aside: Adding Binary Data to an Entry

This section is separate from the information above because it could fit within the sections on creating an entry or with defining additional attributes.

LDAP has the ability to store binary data for certain attributes. For instance, the `inetOrgPerson` class allows an attribute called `jpegPhoto`, which can be used to store a person’s photograph or user icon. Another attribute of this objectClass that can use binary data is the `audio` attribute.

To add this type of data to an LDAP entry, you must use a special format. When specifying the attribute, immediately following the colon, use a less-than character (\<) and a space. Afterwards, include the path to the file in question.

For instance, if you have a file called `john.jpg` in the `/tmp` directory, you can add the file to John’s entry with an LDIF file that looks like this:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    add: jpegPhoto
    jpegPhoto:< file:///tmp/john.jpg

Pay close attention to the placement of the colon, less than character, and space. If your file is located on disk, the `file://` prefix can be used. The path will add an additional slash to indicate the root directory if you are using an absolute path.

This would work the same way with an audio file:

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    changetype: modify
    add: audio
    audio:< file:///tmp/hellojohn.mp3

Once you have processed the LDIF file, the actual file will be encoded within your LDAP directory service. This is important to keep in mind, because adding significant number of files like this will have an impact on the size and performance of your service.

When you need to retrieve the encoded data using the `ldapsearch` tool, you will need to add the `-t` flag, which will allow the file to be written to the `/tmp` directory. The generated filename will be indicated in the results.

For instance, we could use this command to write out the binary data to a temporary file:

    ldapsearch -LLL -x -H ldap:// -t -b "dc=example,dc=com" "uid=jsmith1"

The search result will look like this:

ldapsearch output

    dn: uid=jsmith1,ou=People,dc=example,dc=com
    objectClass: inetOrgPerson
    sn: Smith
    uid: jsmith1
    cn: Johnny Smith
    l: New York
    audio:< file:///tmp/ldapsearch-audio-n5GRF6

If we go to the `/tmp` directory, we can find the file. It can be renamed as needed and should be in the exact state that it was in before entering it into the directory.

Be careful when doing this operation repeatedly, as a new file is written out each time the search is performed. You could easily fill a disk without realizing if you do not pay attention.

## Conclusion

By now you should have a fairly good handle on how to manipulate the entries within an LDAP directory information tree using LDIF formatted files and a few tools. While certain LDAP clients may make LDIF files unnecessary for day-to-day operations, LDIF files can be the best way of performing batch operations on your DIT entries. It is also important to know how to modify your entries using these methods for administration purposes, when setting up the initial directory service, and when fixing issues that might prevent clients from correctly accessing your data.
