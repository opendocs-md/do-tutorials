---
author: Justin Ellingwood
date: 2014-10-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-cloud-config-scripting
---

# An Introduction to Cloud-Config Scripting

## Introduction

The `cloud-init` program that is available on recent distributions (only Ubuntu 14.04 and CentOS 7 at the time of this writing) is able to consume and execute data from the `user-data` field of the [DigitalOcean metadata service](an-introduction-to-droplet-metadata). This process behaves differently depending on the format of the information it finds. One of the most popular formats for scripts within `user-data` is the **cloud-config** file format.

Cloud-config files are special scripts designed to be run by the cloud-init process. These are generally used for initial configuration on the very first boot of a server. In this guide, we will be discussing the format and usage of cloud-config files.

## General Information about Cloud-Config

The `cloud-config` format implements a declarative syntax for many common configuration items, making it easy to accomplish many tasks. It also allows you to specify arbitrary commands for anything that falls outside of the predefined declarative capabilities.

This “best of both worlds” approach lets the file acts like a configuration file for common tasks, while maintaining the flexibility of a script for more complex functionality.

### YAML Formatting

The file is written using the YAML data serialization format. The YAML format was created to be easy to understand for humans and easy to parse for programs.

YAML files are generally fairly intuitive to understand when reading them, but it is good to know the actual rules that govern them.

Some important rules for YAML files are:

- Indentation with whitespace indicates the structure and relationship of the items to one another. Items that are more indented are sub-items of the first item with a lower level of indentation above them.
- List members can be identified by a leading dash.
- Associative array entries are created by using a colon (:) followed by a space and the value.
- Blocks of text are indented. To indicate that the block should be read as-is, with the formatting maintained, use the pipe character (|) before the block.

Let’s take these rules and analyze an example `cloud-config` file, paying attention only to the formatting:

    #cloud-config
    users:
      - name: demo
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh-authorized-keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDf0q4PyG0doiBQYV7OlOxbRjle026hJPBWD+eKHWuVXIpAiQlSElEBqQn0pOqNJZ3IBCvSLnrdZTUph4czNC4885AArS9NkyM7lK27Oo8RV888jWc8hsx4CD2uNfkuHL+NI5xPB/QT3Um2Zi7GRkIwIgNPN5uqUtXvjgA+i1CS0Ku4ld8vndXvr504jV9BMQoZrXEST3YlriOb8Wf7hYqphVMpF3b+8df96Pxsj0+iZqayS9wFcL8ITPApHi0yVwS8TjxEtI3FDpCbf7Y/DmTGOv49+AWBkFhS2ZwwGTX65L61PDlTSAzL+rPFmHaQBHnsli8U9N6E4XHDEOjbSMRX user@example.com
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcthLR0qW6y1eWtlmgUE/DveL4XCaqK6PQlWzi445v6vgh7emU4R5DmAsz+plWooJL40dDLCwBt9kEcO/vYzKY9DdHnX8dveMTJNU/OJAaoB1fV6ePvTOdQ6F3SlF2uq77xYTOqBiWjqF+KMDeB+dQ+eGyhuI/z/aROFP6pdkRyEikO9YkVMPyomHKFob+ZKPI4t7TwUi7x1rZB1GsKgRoFkkYu7gvGak3jEWazsZEeRxCgHgAV7TDm05VAWCrnX/+RzsQ/1DecwSzsP06DGFWZYjxzthhGTvH/W5+KFyMvyA+tZV4i1XM+CIv/Ma/xahwqzQkIaKUwsldPPu00jRN user@desktop
    runcmd:
      - touch /test.txt

By looking at this file, we can learn a number of important things.

First, each `cloud-config` file must begin with `#cloud-config` alone on the very first line. This signals to the cloud-init program that this should be interpreted as a `cloud-config` file. If this were a regular script file, the first line would indicate the interpreter that should be used to execute the file.

The file above has two top-level directives, `users` and `runcmd`. These both serve as keys. The values of these keys consist of all of the indented lines after the keys.

In the case of the `users` key, the value is a single list item. We know this because the next level of indentation is a dash (-) which specifies a list item, and because there is only one dash at this indentation level. In the case of the `users` directive, this incidentally indicates that we are only defining a single user.

The list item itself contains an associative array with more key-value pairs. These are sibling elements because they all exist at the same level of indentation. Each of the user attributes are contained within the single list item we described above.

Some things to note are that the strings you see do not require quoting and that there are no unnecessary brackets to define associations. The interpreter can determine the data type fairly easily and the indentation indicates the relationship of items, both for humans and programs.

By now, you should have a working knowledge of the YAML format and feel comfortable working with information using the rules we discussed above.

We can now begin exploring some of the most common directives for `cloud-config`.

## User and Group Management

To define new users on the system, you can use the `users` directive that we saw in the example file above.

The general format of user definitions is:

    #cloud-config
    users:
      - first_user_parameter
        first_user_parameter
    
      - second_user_parameter
        second_user_parameter
        second_user_parameter
        second_user_parameter

Each new user should begin with a dash. Each user defines parameters in key-value pairs. The following keys are available for definition:

- **name** : The account username.
- **primary-group** : The primary group of the user. By default, this will be a group created that matches the username. Any group specified here must already exist or must be created explicitly (we discuss this later in this section).
- **groups** : Any supplementary groups can be listed here, separated by commas.
- **gecos** : A field for supplementary info about the user.
- **shell** : The shell that should be set for the user. If you do not set this, the very basic `sh` shell will be used.
- **expiredate** : The date that the account should expire, in YYYY-MM-DD format.
- **sudo** : The sudo string to use if you would like to define sudo privileges, without the username field.
- **lock-passwd** : This is set to “True” by default. Set this to “False” to allow users to log in with a password.
- **passwd** : A hashed password for the account.
- **ssh-authorized-keys** : A list of complete SSH public keys that should be added to this user’s `authorized_keys` file in their `.ssh` directory.
- **inactive** : A boolean value that will set the account to inactive.
- **system** : If “True”, this account will be a system account with no home directory.
- **homedir** : Used to override the default `/home/<username>`, which is otherwise created and set.
- **ssh-import-id** : The SSH ID to import from LaunchPad.
- **selinux-user** : This can be used to set the SELinux user that should be used for this account’s login.
- **no-create-home** : Set to “True” to avoid creating a `/home/<username>` directory for the user.
- **no-user-group** : Set to “True” to avoid creating a group with the same name as the user.
- **no-log-init** : Set to “True” to not initiate the user login databases.

Other than some basic information, like the `name` key, you only need to define the areas where you are deviating from the default or supplying needed data.

One thing that is important for users to realize is that the `passwd` field should **not** be used in production systems unless you have a mechanism of immediately modifying the given value. As with all information submitted as user-data, the hash will remain accessible to **any** user on the system for the entire life of the server. On modern hardware, these hashes can easily be cracked in a trivial amount of time. Exposing even the hash is a huge security risk that should not be taken on any machines that are not disposable.

For an example user definition, we can use part of the example `cloud-config` we saw above:

    #cloud-config
    users:
      - name: demo
        groups: sudo
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh-authorized-keys:
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDf0q4PyG0doiBQYV7OlOxbRjle026hJPBWD+eKHWuVXIpAiQlSElEBqQn0pOqNJZ3IBCvSLnrdZTUph4czNC4885AArS9NkyM7lK27Oo8RV888jWc8hsx4CD2uNfkuHL+NI5xPB/QT3Um2Zi7GRkIwIgNPN5uqUtXvjgA+i1CS0Ku4ld8vndXvr504jV9BMQoZrXEST3YlriOb8Wf7hYqphVMpF3b+8df96Pxsj0+iZqayS9wFcL8ITPApHi0yVwS8TjxEtI3FDpCbf7Y/DmTGOv49+AWBkFhS2ZwwGTX65L61PDlTSAzL+rPFmHaQBHnsli8U9N6E4XHDEOjbSMRX user@example.com
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcthLR0qW6y1eWtlmgUE/DveL4XCaqK6PQlWzi445v6vgh7emU4R5DmAsz+plWooJL40dDLCwBt9kEcO/vYzKY9DdHnX8dveMTJNU/OJAaoB1fV6ePvTOdQ6F3SlF2uq77xYTOqBiWjqF+KMDeB+dQ+eGyhuI/z/aROFP6pdkRyEikO9YkVMPyomHKFob+ZKPI4t7TwUi7x1rZB1GsKgRoFkkYu7gvGak3jEWazsZEeRxCgHgAV7TDm05VAWCrnX/+RzsQ/1DecwSzsP06DGFWZYjxzthhGTvH/W5+KFyMvyA+tZV4i1XM+CIv/Ma/xahwqzQkIaKUwsldPPu00jRN user@desktop

To define groups, you should use the `groups` directive. This directive is relatively simple in that it just takes a list of groups you would like to create.

An optional extension to this is to create a sub-list for any of the groups you are making. This new list will define the users that should be placed in this group:

    #cloud-config
    groups:
      - group1
      - group2: [user1, user2]

## Change Passwords for Existing Users

For user accounts that already exist (the `root` account is the most pertinent), a password can be suppled by using the `chpasswd` directive.

**Note** : This directive should **only** be used in debugging situations, because, once again, the value will be available to every user on the system for the duration of the server’s life. This is even more relevant in this section because passwords submitted with this directive must be given in **plain text**.

The basic syntax looks like this:

    #cloud-config
    chpasswd:
      list: |
        user1:password1
        user2:password2
        user3:password3
      expire: False

The directive contains two associative array keys. The `list` key will contain a block that lists the account names and the associated passwords that you would like to assign. The `expire` key is a boolean that determines whether the password must be changed at first boot or not. This defaults to “True”.

One thing to note is that you can set a password to “RANDOM” or “R”, which will generate a random password and write it to `/var/log/cloud-init-output.log`. Keep in mind that this file is accessible to any user on the system, so it is not any more secure.

## Write Files to the Disk

In order to write files to the disk, you should use the `write_files` directive.

Each file that should be written is represented by a list item under the directive. These list items will be associative arrays that define the properties of each file.

The only required keys in this array are `path`, which defines where to write the file, and `content`, which contains the data you would like the file to contain.

The available keys for configuring a `write_files` item are:

- **path** : The absolute path to the location on the filesystem where the file should be written.
- **content** : The content that should be placed in the file. For multi-line input, you should start a block by using a pipe character (|) on the “content” line, followed by an indented block containing the content. Binary files should include “!!binary” and a space prior to the pipe character.
- **owner** : The user account and group that should be given ownership of the file. These should be given in the “username:group” format.
- **permissions** : The octal permissions set that should be given for this file.
- **encoding** : An optional encoding specification for the file. This can be “b64” for Base64 files, “gzip” for Gzip compressed files, or “gz+b64” for a combination. Leaving this out will use the default, conventional file type.

For example, we could write a file to `/test.txt` with the contents:

    Here is a line.
    Another line is here.

The portion of the `cloud-config` that would accomplish this would look like this:

    #cloud-config
    write_files:
      - path: /test.txt
        content: |
          Here is a line.
          Another line is here.

## Update or Install Packages on the Server

To manage packages, there are a few related settings and directives to keep in mind.

To update the apt database on Debian-based distributions, you should set the `package_update` directive to “true”. This is synonymous with calling `apt-get update` from the command line.

The default value is actually “true”, so you only need to worry about this directive if you wish to disable it:

    #cloud-config
    package_update: false

If you wish to upgrade all of the packages on your server after it boots up for the first time, you can set the `package_upgrade` directive. This is akin to a `apt-get upgrade` executed manually.

This is set to “false” by default, so make sure you set this to “true” if you want the functionality:

    #cloud-config
    package_upgrade: true

To install additional packages, you can simply list the package names using the “packages” directive. Each list item should represent a package. Unlike the two commands above, this directive will function with either yum or apt managed distros.

These items can take one of two forms. The first is simply a string with the name of the package. The second form is a list with two items. The first item of this new list is the package name, and the second item is the version number:

    #cloud-config
    packages:
      - package_1
      - package_2
      - [package_3, version_num]

The “packages” directive will set `apt_update` to true, overriding any previous setting.

## Configure SSH Keys for User Accounts and the SSH Daemon

You can manage SSH keys in the `users` directive, but you can also specify them in a dedicated `ssh_authorized_keys` section. These will be added to the first defined user’s authorized\_keys file.

This takes the same general format of the key specification within the `users` directive:

    #cloud-config
    ssh_authorized_keys:
      - ssh_key_1
      - ssh_key_2

You can also generate the SSH server’s private keys ahead of time and place them on the filesystem. This can be useful if you want to give your clients the information about this server beforehand, allowing it to trust the server as soon as it comes online.

To do this, we can use the `ssh_keys` directive. This can take the key pairs for RSA, DSA, or ECDSA keys using the `rsa_private`, `rsa_public`, `dsa_private`, `dsa_public`, `ecdsa_private`, and `ecdsa_public` sub-items.

Since formatting and line breaks are important for private keys, make sure to use a block with a pipe key when specifying these. Also, you **must** include the begin key and end key lines for your keys to be valid.

    #cloud-config
    ssh_keys:
      rsa_private: |
        -----BEGIN RSA PRIVATE KEY-----
        your_rsa_private_key
        -----END RSA PRIVATE KEY-----
    
      rsa_public: your_rsa_public_key

## Set Up Trusted CA Certificates

If your infrastructure relies on keys signed by an internal certificate authority, you can set up your new machines to trust your CA cert by injecting the certificate information. For this, we use the `ca-certs` directive.

This directive has two sub-items. The first is `remove-defaults`, which, when set to true, will remove all of the normal certificate trust information included by default. This is usually not needed and can lead to some issues if you don’t know what you are doing, so use with caution.

The second item is `trusted`, which is a list, each containing a trusted CA certificate:

    #cloud-config
    ca-certs:
      remove-defaults: true
      trusted:
        - |
          -----BEGIN CERTIFICATE-----
          your_CA_cert
          -----END CERTIFICATE-----

## Configure resolv.conf to Use Specific DNS Servers

If you have configured your own DNS servers that you wish to use, you can manage your server’s resolv.conf file by using the `resolv_conf` directive. This currently only works for RHEL-based distributions.

Under the `resolv_conf` directive, you can manage your settings with the `nameservers`, `searchdomains`, `domain`, and `options` items.

The `nameservers` directive should take a list of the IP addresses of your name servers. The `searchdomains` directive takes a list of domains and subdomains to search in when a user specifies a host but not a domain.

The `domain` sets the domain that should be used for any unresolvable requests, and `options` contains a set of options that can be defined in the resolv.conf file.

If you are using the `resolv_conf` directive, you must ensure that the `manage-resolv-conf` directive is also set to true. Not doing so will cause your settings to be ignored:

    #cloud-config
    manage-resolv-conf: true
    resolv_conf:
      nameservers:
        - 'first_nameserver'
        - 'second_nameserver'
      searchdomains:
        - first.domain.com
        - second.domain.com
      domain: domain.com
      options:
        option1: value1
        option2: value2
        option3: value3

## Run Arbitrary Commands for More Control

If none of the managed actions that `cloud-config` provides works for what you want to do, you can also run arbitrary commands. You can do this with the `runcmd` directive.

This directive takes a list of items to execute. These items can be specified in two different ways, which will affect how they are handled.

If the list item is a simple string, the entire item will be passed to the `sh` shell process to run.

The other option is to pass a list, each item of which will be executed in a similar way to how `execve` processes commands. The first item will be interpreted as the command or script to run, and the following items will be passed as arguments for that command.

Most users can use either of these formats, but the flexibility enables you to choose the best option if you have special requirements. Any output will be written to standard out and to the `/var/log/cloud-init-output.log` file:

    #cloud-config
    runcmd:
      - [sed, -i, -e, 's/here/there/g', some_file]
      - echo "modified some_file"
      - [cat, some_file]

## Shutdown or Reboot the Server

In some cases, you’ll want to shutdown or reboot your server after executing the other items. You can do this by setting up the `power_state` directive.

This directive has four sub-items that can be set. These are `delay`, `timeout`, `message`, and `mode`.

The `delay` specifies how long into the future the restart or shutdown should occur. By default, this will be “now”, meaning the procedure will begin immediately. To add a delay, users should specify, in minutes, the amount of time that should pass using the `+<num_of_mins>` format.

The `timeout` parameter takes a unit-less value that represents the number of seconds to wait for cloud-init to complete before initiating the `delay` countdown.

The `message` field allows you to specify a message that will be sent to all users of the system. The `mode` specifies the type of power event to initiate. This can be “poweroff” to shut down the server, “reboot” to restart the server, or “halt” to let the system decide which is the best action (usually shutdown):

    #cloud-config
    power_state:
      timeout: 120
      delay: "+5"
      message: Rebooting in five minutes. Please save your work.
      mode: reboot

## Conclusion

The above examples represent some of the more common configuration items available when running a `cloud-config` file. There are additional capabilities that we did not cover in this guide. These include configuration management setup, configuring additional repositories, and even registering with an outside URL when the server is initialized.

You can find out more about some of these options by checking the `/usr/share/doc/cloud-init/examples` directory. For a practical guide to help you get familiar with `cloud-config` files, you can follow our tutorial on [how to use cloud-config to complete basic server configuration](how-to-use-cloud-config-for-your-initial-server-setup) here.
