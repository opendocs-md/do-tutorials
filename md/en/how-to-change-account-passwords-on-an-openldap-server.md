---
author: Justin Ellingwood
date: 2015-05-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-change-account-passwords-on-an-openldap-server
---

# How To Change Account Passwords on an OpenLDAP Server

## Introduction

LDAP systems are often used to store user account information. In fact, some of the most common methods of authenticating to LDAP involve account information stored within LDAP entries.

Whether your LDAP entries are used by external services for account information or are just used for LDAP-specific authorization binds, password management becomes important to understand. In this guide, we will talk about how to go about modifying an LDAP entry’s password.

## Changing Your Own User Password

The ability to change passwords is managed by the access controls for the LDAP server. Typically, LDAP is configured to allow accounts the ability to change their own passwords. This works well if you, as a user, know your previous password.

We can use the `ldappasswd` tool to modify user account passwords. To change your password, you will need to bind to an LDAP user entry and authenticate with the current password. This follows the same general syntax as the other OpenLDAP tools.

We will have to provide several arguments beyond the conventional bind arguments in order to change the password. You should specify the old password using one of the following options:

- **`-a [oldpassword]`**: The `-a` flag allows you to supply the old password as part of the request on the command line.
- **`-A`** : This flag is an alternative to the `-a` flag that will prompt you for the old password when the command is entered.
- **`-t [oldpasswordfile]`**: This flag can be used instead of the above to read the old password from a file.

You also need to specify the new password using one of these options:

- **`-s [newpassword]`**: The `-s` flag is used to supply the new password on the command line.
- **`-S`** : This variant of the `-s` flag will prompt you for the new password when the command is entered.
- **`-T [newpasswordfile]`**: This flag can be used instead of the above to read the new password from a file.

Using one option from each group, along with the regular options to specify the server location and the bind entry and password, you can change your LDAP password. Technically, OpenLDAP does not always need the old password since it is used to bind to the entry, but other LDAP implementations require this, so it is best to set anyways.

Typically, the command will look something like this:

    ldappasswd -H ldap://server_domain_or_IP -x -D "user_dn" -W -A -S

This will connect to the specified LDAP server, authenticate with the user DN entry, and then issue a series of prompts. You will be asked to supply and confirm the old password, the new password, and then you will need to supply the old password again for the actual bind to take place. Afterwards, your password will change.

Since you are going to be changing your password anyways, it might be easier give your old password on the command line instead of through prompts. You could do that like this:

    ldappasswd -H ldap://server_domain_or_IP -x -D "user's_dn" -w old_passwd -a old_passwd -S

## Changing a User’s Password Using the RootDN Bind

The `ldappasswd` tool also allows you to change another user’s password if needed as the LDAP administrator. Technically, you can bind with any account that has write access to the account’s password, but this access is usually limited to the rootDN (administrative) entry and the account itself.

To change another user’s password, you need to bind to an entry with elevated privileges and then specify the entry you wish to change. Usually, you’ll be binding to the rootDN (see the next section if you need to find out how to find this account).

The basic `ldappasswd` command will look very similar, the only difference being that you must specify the entry to change at the end of the command. You may use the `-a` or `-A` options if you have the old password available, but this is often not the case when changing the password for a user. If you do not have the old password, just leave it off.

For example, if the rootDN for your LDAP server is `cn=admin,dc=example,dc=com`, and the password you wish to change is for the `uid=bob,ou=people,dc=example,dc=com` entry, you can type this:

    ldappasswd -H ldap://server_domain_or_IP -x -D "cn=admin,dc=example,dc=com" -W -S "uid=bob,ou=people,dc=example,dc=com"

You will be prompted for Bob’s new password and then you will be prompted for the password needed to bind to the admin entry to make the change.

## Changing the RootDN Password

In the event that you have forgotten your LDAP administrative password, you will need to have root or `sudo` access on the LDAP system’s server to reset it. Log into your server to get started.

### Finding the Current RootDN Information

First, you will have to find the RootDN account and the current RootDN password hash. This is available in the special `cn=config` configuration DIT. We can find the information that we are looking for by typing:

    sudo ldapsearch -H ldapi:// -LLL -Q -Y EXTERNAL -b "cn=config" "(olcRootDN=*)" dn olcRootDN olcRootPW | tee ~/newpasswd.ldif

This should return the rootDN account and password for your DIT. It will also tell you the configuration database where this is defined. We also wrote this information to a file in our home directory so that we can modify it once we have the new password hash:

RootDN and RootPW for DIT

    dn: olcDatabase={1}hdb,cn=config
    olcRootDN: cn=admin,dc=example,dc=com
    olcRootPW: {SSHA}ncCXAJ5DjfRWgxE9pz9TUCNl2qGQHQT3

### Hashing a New Password

Next, we can use the `slappasswd` utility to hash a new password. We want to use the same hash that was in the `olcRootPW` line that we queried, indicated by the prefixed value with braces. In our case, this is `{SSHA}`.

Use the `slappasswd` utility to generate a correct hash for the password we want to use. We will append our new hash to the end of the file we created with the last command. You will need to specify the full path to the command if you are using a non-root account:

    /usr/sbin/slappasswd -h {SSHA} >> ~/newpasswd.ldif

You will be prompted to enter and confirm the new password you wish to use. The hashed value will be appended to the end of our file.

### Changing the Password in the Config DIT

Now, we can edit the file to construct a valid LDIF command to change the password. Open the file we’ve been writing to:

    nano ~/newpasswd.ldif

It should look something like this:

~/newpasswd.ldif

    dn: olcDatabase={1}hdb,cn=config
    olcRootDN: cn=admin,dc=example,dc=com
    olcRootPW: {SSHA}ncCXAJ5DjfRWgxE9pz9TUCNl2qGQHQT3
    
    {SSHA}lieJW/YlN5ps6Gn533tJuyY6iRtgSTQw

You could possibly have multiple values depending on if your LDAP server has more than one DIT. If that is the case, use the `olcRootDN` value to find the correct account that you wish to modify. Delete the other `dn`, `olcRootDN`, `olcRootPW` triplets if there are any.

After you’ve confirmed that the `olcRootDN` line matches the account you are trying to modify, comment it out. Below it, we will add two lines. The first one should specify `changetype: modify`, and the second line should tell LDAP that you are trying to `replace: olcRootPW`. It will look like this:

~/newpasswd.ldif

    dn: olcDatabase={1}hdb,cn=config
    #olcRootDN: cn=admin,dc=example,dc=com
    changetype: modify
    replace: olcRootPW
    olcRootPW: {SSHA}ncCXAJ5DjfRWgxE9pz9TUCNl2qGQHQT3
    
    {SSHA}lieJW/YlN5ps6Gn533tJuyY6iRtgSTQw

Now, delete the hash that is in the `olcRootPW` line and replace it with the one you generated below. Remove any extraneous lines. It should now look like this:

~/newpasswd.ldif

    dn: olcDatabase={1}hdb,cn=config
    #olcRootDN: cn=admin,dc=example,dc=com
    changetype: modify
    replace: olcRootPW
    olcRootPW: {SSHA}lieJW/YlN5ps6Gn533tJuyY6iRtgSTQw

Save and close the file when you are finished.

Now, we can apply the change by typing:

    sudo ldapmodify -H ldapi:// -Y EXTERNAL -f ~/newpasswd.ldif

This will change the administrative password within the `cn=config` DIT.

### Changing the Password in the Normal DIT

This has changed the password for the entry within the administrative DIT. However, we still need to modify the entry within the regular DIT. Currently both the old and new passwords are valid. We can fix this by modifying the regular DIT entry using our new credentials.

Open up the LDIF file again:

    nano ~/newpasswd.ldif

Replace the value in the `dn:` line with the RootDN value that you commented out earlier. This entry is our new target for the password change. We will also need to change **both** occurrences of `olcRootPW` with `userPassword` so that we are modifying the correct value. When you are finished, the LDIF file should look like this:

    [output ~/newpasswd.ldif]
    dn: cn=admin,dc=example,dc=com
    changetype: modify
    replace: userPassword
    userPassword: {SSHA}lieJW/YlN5ps6Gn533tJuyY6iRtgSTQw

Save and close the file.

Now, we can modify the password for that entry by binding to it using the new password we set in the config DIT. You will need to bind to the RootDN entry to perform the operation:

    ldapmodify -H ldap:// -x -D "cn=admin,dc=example,dc=com" -W -f ~/newpasswd.ldif

You will be prompted for the new password you set in the config DIT. Once authenticated, the password will be changed, leaving only the new password for authentication purposes.

## Conclusion

LDAP is often used for storing account information, so it is important to know how to properly manage passwords. Most of the time the process is relatively simple, but for more intensive operations, you should still be able to modify the passwords with a little work.
