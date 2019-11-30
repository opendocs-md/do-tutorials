---
author: Veena K John
date: 2015-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-custom-system-audit-rules-on-centos-7
---

# How To Write Custom System Audit Rules on CentOS 7

## Introduction

The Linux Audit System creates an audit trail, a way to track all kinds of information on your system. It can record a lot of data like types of events, the date and time, user IDs, system calls, processes, files used, SELinux contexts, and sensitivity levels. It can track whether a file has been accessed, edited, or executed. It can even track if changes to file attributes. It is capable of logging usage of system calls, commands executed by a user, failed login attempts, and many other events. By default, the audit system records only a few events in the logs such as users logging in, users using sudo, and SELinux-related messages. It uses audit rules to monitor for specific events and create related log entries. It is possible to create audit rules.

In this tutorial, we will discuss the different types of audit rules and how to add or remove custom rules on your server.

## Prerequisites

Before you get started with this tutorial, you should have the following:

- CentOS 7 Droplet (works with CentOS 6 as well)
- Non-root user with sudo privileges. To setup a user of this type, follow the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) tutorial. All commands will be run as this user.
- A basic understanding of the Linux Audit System. Check out [Understanding the Linux Auditing System on CentOS 7](understanding-the-linux-auditing-system-on-centos-7) for more information.

## Viewing Audit Rules

You can view the current set of audit rules using the command `auditctl -l`.

    sudo auditctl -l

It will show no rules if none are present(this is the default):

    No rules

As you add rules in this tutorial, you can use this command to verify that they have been added.

The current status of the audit system can be viewed using:

    sudo auditctl -s

Output will be similar to:

    AUDIT_STATUS: enabled=1 flag=1 pid=9736 rate_limit=0 backlog_limit=320 lost=0 backlog=0

The `enabled=1` value shows that auditing is enabled on this server. The `pid` value is the process number of the audit daemon. A pid of 0 indicates that the audit daemon is not running. The `lost` entry will tell you how many event records have  
been discarded due to the kernel audit queue overflowing. The `backlog` field shows how many event records are currently queued waiting for auditd to read them. We will discuss the rest of the output fields in the next section of this tutorial.

## Adding Audit Rules

You can add custom audit rules using the command line tool `auditctl`. By default, rules will be added to the bottom of the current list, but could be inserted at the top too. To make your rules permanent, you need to add them to the file `/etc/audit/rules.d/audit.rules`. Whenever the `auditd` service is started, it will activate all the rules from the file. You can read more about the audit daemon and the audit system in our other article [Understanding the Audit System on CentOS 7](understanding-the-linux-auditing-system-on-centos-7). Audit rules work on a first match wins basis — when a rule matches, it will not evaluate rules further down. Correct ordering of rules is important.

If you are on CentOS 6, the audit rules file is located at `/etc/audit/audit.rules` instead.

There are three types of audit rules:

- Control rules: These rules are used for changing the configuration and settings of the audit system itself.

- Filesystem rules: These are file or directory watches. Using these rules, we can audit any kind of access to specific files or directories.

- System call rules: These rules are used for monitoring system calls made by any process or a particular user.

### Control Rules

Let us look at some of the control rules we can add:

- `auditctl -b <backlog>` - Set maximum number of outstanding audit buffers allowed. If all buffers are full, the failure flag is consulted by the kernel for action. The default backlog limit set on a CentOS server is 320. You can view this using:

    sudo auditctl -s

In the output, you can see the current **backlog\_limit** value:

    AUDIT_STATUS: enabled=1 flag=1 pid=9736 rate_limit=0 backlog_limit=320 lost=0 backlog=0

If your backlog value is more than the **backlog\_limit** currently set, you might need to increase the **backlog\_limit** for the audit logging to function correctly. For example, to increase the value to 1024, run:

    sudo auditctl -b 1024

Output will show the status:

    AUDIT_STATUS: enabled=1 flag=1 pid=9736 rate_limit=0 backlog_limit=1024 lost=0 backlog=0

- `auditctl -f [0 1 2]` - Set failure flag (0=silent, 1=printk. 2=panic). This option lets you determine how you want the kernel to handle critical errors. If set to 0, audit messages which could not be logged will be silently discarded. If set to 1, messages are sent to the kernel log subsystem. If set to 2, it will trigger a kernel panic. Example conditions where this flag is consulted include backlog limit exceeded, out of kernel memory, and rate limit exceeded. The default value is 1. Unless you have any major problems with auditing daemon on your server, you will not need to change this value.

- `auditctl -R <filename>` - Read audit rules from the file specified. This is useful when you are testing some temporary rules and want to use the old rules again from the `audit.rules` file.

The rules we add via `auditctl` are not permanent. To make them persistent across reboots, you can add them to the file `/etc/audit/rules.d/audit.rules`. This file uses the same `auditctl` command line syntax to specify the rules but without the `auditctl` command itself in front. Any empty lines or any text following a hash sign (#) is ignored. The default rules file looks like this:

/etc/audit/rules.d/audit.rules

    # This file contains the auditctl rules that are loaded
    # whenever the audit daemon is started via the initscripts.
    # The rules are simply the parameters that would be passed
    # to auditctl.
    
    # First rule - delete all
    -D
    
    # Increase the buffers to survive stress events.
    # Make this bigger for busy systems
    -b 320
    
    # Feel free to add below this line. See auditctl man page

To change the backlog value to say, 8192, you can change **-b 320** to **-b 8192** and restart the audit daemon using:

    sudo service auditd restart

If you don’t restart the daemon, it will still set the new value from the configuration at the next server reboot.

### Filesystem Rules

Filesystem watches can be set on files and directories. We can also specify what type of access to watch for. The syntax for a filesystem rule is:

    auditctl -w path_to_file -p permissions -k key_name

where

`path_to_file` is the file or directory that is audited. `permissions` are the permissions that are logged. This value can be one or a combination of r(read), w(write), x(execute), and a(attribute change). `key_name` is an optional string that helps you identify which rule(s) generated a particular log entry.

Let us look at some examples.

    sudo auditctl -w /etc/hosts -p wa -k hosts_file_change

The above rule asks the audit system to watch for any write access or attribute change to the file `/etc/hosts` and log them to the audit log with the custom key string specified by us — `hosts_file_change`.

If you wish to make this rule permanent, then add it to the file `/etc/audit/rules.d/audit.rules` at the bottom like this:

/etc/audit/rules.d/audit.rules

    -w /etc/hosts -p wa -k hosts_file_change

To make sure the rule was added successfully, you can run:

    sudo auditctl -l

If all goes well, output should show:

    LIST_RULES: exit,always watch=/etc/hosts perm=wa key=hosts_file_change

We can also add watches to directories.

    sudo auditctl -w /etc/sysconfig/ -p rwa -k configaccess

The above rule will add a watch to the directory `/etc/sysconfig` and all files and directories beneath it for any read, write, or attribute change access. It will also label log messages with a custom key **configaccess**.

To add a rule to watch for execution of the `/sbin/modprobe` command (this command can add/remove kernel modules from the server):

    sudo auditctl -w /sbin/modprobe -p x -k kernel_modules

**Note:** You can’t insert a watch to the top level directory. This is prohibited by the kernel. Wildcards are not supported either and will generate a warning.

To search the audit logs for specific events, you can use the command `ausearch`. For example, to search the audit logs for all events labeled with the key `configaccess`, you can run:

    sudo ausearch -k configaccess

`ausearch` is discussed in detail in our other tutorial [Understanding the Audit System on CentOS 7](understanding-the-linux-auditing-system-on-centos-7).

### System Call Rules

By auditing system calls, you can track activities on the server well beyond the application level. The syntax for system call rules is:

    auditctl -a action,filter -S system_call -F field=value -k key_name`

where:

- Replacing `-a` with `-A` in the above command will insert the rule at the top instead of at the bottom.

- `action` and `filter` specify when a certain event is logged. `action` can be either `always` or `never`. `filter` specifies which kernel rule-matching filter is applied to the event. The rule-matching filter can be one of the following: `task`, `exit`, `user`, and `exclude`. `action,filter` will be `always,exit` in most cases, which tells `auditctl` that you want to audit this system call when it exits.

- `system_call` specifies the system call by its name. Several system calls can be grouped into one rule, each specified after a `-S` option. The word `all` may also be used. You can use the `sudo ausyscall --dump` command to view a list of all system calls along with their numbers. 

- `field=value` specifies additional options that modify the rule to match events based on a specified architecture, user ID, process ID, path, and others.

- `key_name` is an optional string that helps you identify later which rule or a set of rules generated a particular log entry. 

Let us now look at some example system call rules.

To define an audit rule that creates a log entry labelled `rename` every time a file is renamed by a user whose ID is 1000 or larger, run:

    sudo auditctl -a always,exit -F arch=b64 -F "auid>=1000" -S rename -S renameat -k rename

The `-F arch=b64` says to audit the 64-bit version of the system calls in the rule.

To define a rule that logs what files a particular user (with UID 1001) accessed and labels the log entries with `userfileaccess`:

    sudo auditctl -a always,exit -F arch=b64 -F auid=1001 -S open -k userfileaccess

If you wish to make this rule permanent, then add it to the file `/etc/audit/rules.d/audit.rules` at the bottom like this:

/etc/audit/rules.d/audit.rules

    -a always,exit -F arch=b64 -F auid=1001 -S open -k userfileaccess

You can also define a filesystem rule using the system call rule syntax. For example, the following rule:

    sudo auditctl -a always,exit -F path=/etc/hosts -F perm=wa -k hosts_file_change

does the same job as the filesystem rule we saw in the earlier section:

    sudo auditctl -w /etc/hosts -p wa -k hosts_file_change

To watch a directory recursively using a system call rule, you can use the option `-F "dir=/path/to/dir"`.

**Note:** Please note that all processes started earlier than the audit daemon itself will have an `auid` of `4294967295`. To exclude those from your rules, you can add `-F "auid!=4294967295"` to your rules. To avoid this problem, you can add `audit=1` to the kernel boot parameters. This enables the kernel audit system at boot even before the audit daemon starts and all processes will have the correct login uid.

## Removing Audit Rules

To remove all the current audit rules, you can use the command `auditctl -D`. To remove filesystem watch rules added using the `-w`option, you can replace `-w` with `-W` in the original rule. System call rules added using the options `-a` or `-A` can be deleted using the `-d` option with the original rule. For example, say we have added the following rule:

    sudo auditctl -w /etc/passwd -p wa -k passwdaccess

View the rule set using:

    sudo auditctl -l

The output should include:

    LIST_RULES: exit,always watch=/etc/passwd perm=wa key=passwdaccess

To remove this rule, we can use the following command, just replacing `-w` with `-W`:

    sudo auditctl -W /etc/passwd -p wa -k passwdaccess

Now, view the rule set using:

    sudo auditctl -l

The rule should not be in the list now.

**Note:** If there are any permanent audit rules added inside the `audit.rules` file, an audit daemon restart or system reboot will load all the rules from the file. To permanently delete audit rules, you need to remove them from the file.

## Locking Audit Rules

It is possible to disable or enable the audit system and lock the audit rules using `auditctl -e [0 1 2]`. For example, to disable auditing temporarily, run:

    auditctl -e 0

When `1` is passed as an argument, it will enable auditing. To lock the audit configuration so that it cannot be changed, pass `2` as the argument. This makes the current set of audit rules immutable. Rules can no longer be added, removed, or edited, and the audit daemon can no longer be stopped. Locking the configuration is intended to be the last command in `audit.rules` for anyone wishing this feature to be active. Any attempt to change the configuration in this mode will be audited and denied. The configuration can only be changed by rebooting the server.

## Conclusion

Information provided by the Linux Auditing System is very useful for intrusion detection. You should now be able to add custom audit rules so that you can log particular events.

Remember that you can always refer to the `auditctl` man page when adding custom logging rules. It offers a full list of command line options, performance tips, and examples. The `/usr/share/doc/audit-<version>/` directory contains files with pre-configured audit rules based on some common certification standards.
