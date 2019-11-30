---
author: Veena K John
date: 2015-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-the-linux-auditing-system-on-centos-7
---

# How To Use the Linux Auditing System on CentOS 7

## Introduction

The _Linux Auditing System_ helps system administrators create an audit trail, a log for every action on the server. We can track security-relevant events, record the events in a log file, and detect misuse or unauthorized activities by inspecting the audit log files. We can choose which actions on the server to monitor and to what extent. Audit does not provide additional security to your system, rather, it helps track any violations of system policies and enables you to take additional security measures to prevent them.

This tutorial explains the audit system, how to configure it, how to generate reports, and how to read these reports. We will also see how to search the audit logs for specific events.

## Prerequisites

For this tutorial, you need the following:

- CentOS 7 Droplet (works with CentOS 6 as well)
- Non-root user with sudo privileges. To setup a user of this type, follow the [Initial Server Setup with CentOS 7](initial-server-setup-with-centos-7) tutorial. All commands will be run as this user.

## Verifying the Audit Installation

There are two main parts to the audit system:

1. The audit kernel component intercepts system calls from user applications, records events, and sends these audit messages to the audit daemon 
2. The `auditd` daemon collects the information from the kernel and creates entries in a log file

The audit system uses the following packages: `audit` and `audit-libs`. These packages are installed by default on a new CentOS 7 Droplet (and a new CentOS 6 Droplet). It is good to verify that you have them installed on your server using:

    sudo yum list audit audit-libs

You should see both the packages under `Installed Packages` in the output:

    Installed Packages
    audit.x86_64
    audit-libs.x86_64

## Configuring Audit

The main configuration file for `auditd` is `/etc/audit/auditd.conf`. This file consists of configuration parameters that include where to log events, how to deal with full disks, and log rotation. To edit this file, you need to use sudo:

    sudo nano /etc/audit/auditd.conf

For example, to increase the number of audit log files kept on your server to 10, edit the following option:

/etc/audit/auditd.conf

    num_logs = 10

You can also configure the maximum log file size in MB and what action to take once the size is reached:

/etc/audit/auditd.conf

    max_log_file = 30
    max_log_file_action = ROTATE

When you make changes to the configuration, you need to restart the auditd service using:

    sudo service auditd restart

for the changes to take effect.

The other configuration file is `/etc/audit/rules.d/audit.rules`. (If you are on CentOS 6, the file is `/etc/audit/audit.rules` instead.) It is used for permanently adding auditing rules.

When `auditd` is running, audit messages will be recorded in the file `/var/log/audit/audit.log`.

## Understanding Audit Log Files

By default, the audit system logs audit messages to the `/var/log/audit/audit.log` file. Audit log files carry a lot of useful information, but reading and understanding the log files can seem difficult for many users due to the sheer amount of information provided, the abbreviations and codes used, etc. In this section, we will try to understand some of the fields in a typical audit message in the audit log files.

**‘Note:** If `auditd` is not running for whatever reason, audit messages will be sent to rsyslog.

For this example, let us assume we have an audit rule configured on the server with the label (`key`) `sshconfigchange` to log every access or modification to the file `/etc/ssh/sshd_config`. If you wish, you can add this rule temporarily using:

    sudo auditctl -w /etc/ssh/sshd_config -p rwxa -k sshconfigchange

Running the following command to view the `sshd_config` file creates a new **event** in the audit log file:

    sudo cat /etc/ssh/sshd_config

This event in the `audit.log` file looks as follows:

/var/log/audit/audit.log

    
    type=SYSCALL msg=audit(1434371271.277:135496): arch=c000003e syscall=2 success=yes exit=3 a0=7fff0054e929 a1=0 a2=1fffffffffff0000 a3=7fff0054c390 items=1 ppid=6265 pid=6266 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=113 comm="cat" exe="/usr/bin/cat" key="sshconfigchange"
    
    type=CWD msg=audit(1434371271.277:135496): cwd="/home/sammy"
    
    type=PATH msg=audit(1434371271.277:135496): item=0 name="/etc/ssh/sshd_config" inode=392210 dev=fd:01 mode=0100600 ouid=0 ogid=0 rdev=00:00 objtype=NORMAL

The above event consists of three records (each starting with the `type=` keyword), which share the same timestamp (`1434371271.277`) and id (`135496`). Each record consists of several _name=value_ pairs separated by a white space or a comma. We will see in detail what some of those fields stand for.

In the first record:

- `type=SYSCALL`

The `type` field contains the type of audit message. In this case, the `SYSCALL` value shows that this message was triggered by a system call to the kernel.

- `msg=audit(1434371271.277:135496):`

The timestamp and ID of the audit message in the form `audit(time_stamp:ID)`. Multiple audit messages/records can share the same time stamp and ID if they were generated as part of the same audit event. In our example, we can see the same timestamp (1434371271.277) and ID (135496) on all three messages generated by the audit event.

- `arch=c000003e`

The `arch` field contains information about the CPU architecture of the system. The value, c000003e, is in hexadecimal notation and stands for x86\_64.

- `syscall=2`

The `syscall` field denotes the type of the system call that was sent to the kernel. In this case, 2 is the `open` system call. The `ausyscall` utility allows you to convert system call numbers to their human-readable equivalents. For example, run the following command to convert the value 2 to its human-readable equivalent:

    sudo ausyscall 2

The output shows:

    open

**Note:** You can use the `sudo ausyscall --dump` command to view a list of all system calls along with their numbers.

- `success=yes`

The `success` field shows whether the system call in that particular event succeeded or failed. In this case, the call succeeded. The user sammy was able to open and read the file `sshd_config` when the `sudo cat /etc/ssh/sshd_config` command was run.

- `ppid=6265` 

The `ppid` field records the Parent Process ID (PPID). In this case, `6265` was the PPID of the `bash` process.

- `pid=6266`

The `pid` field records the Process ID (PID). In this case, `6266` was the PID of the `cat` process.

- `auid=1000`

`auid` is the audit UID or the original UID of the user who triggered this audit message. The audit system will remember your original UID even when you elevate privileges through su or sudo after initial login.

- `uid=0`

The `uid` field records the user ID of the user who started the analyzed process. In this case, the `cat` command was started by user root with uid 0.

- `comm="cat"`

`comm` records the name of the command that triggered this audit message.

- `exe="/usr/bin/cat"`

The `exe` field records the path to the command that was used to trigger this audit message.

- `key="sshconfigchange"`

The `key` field records the administrator-defined string associated with the audit rule that generated this event in the log. Keys are usually set while creating custom auditing rules to make it easier to search for certain types of events from the audit logs.

For the second record:

- `type=CWD`

In the second record, the type is `CWD` — Current Working Directory. This type is used to record the working directory from which the process that triggered the system call specified in the first record was executed.

- `cwd="/home/sammy"`

The `cwd` field contains the path to the directory from which the system call was invoked. In our case, the `cat` command which triggered the `open` syscall in the first record was executed from the directory `/home/sammy`.

For the third record:

- `type=PATH`

In the third record, the type is `PATH`. An audit event contains a `PATH` record for every path that is passed to the system call as an argument. In our audit event, only one path (`/etc/ssh/sshd_config`) was used as an argument.

- `msg=audit(1434371271.277:135496):`

The `msg` field shows the same timestamp and ID combination as in the first and second records since all three records are part of the same audit event.

- `name="/etc/ssh/sshd_config"`

The `name` field records the full path of the file or directory that was passed to the system call (open) as an argument. In this case, it was the `/etc/ssh/sshd_config` file.

- `ouid=0`

The `ouid` field records the user ID of the object’s owner. Here the object is the file `/etc/ssh/sshd_config`.

**Note:** More information on audit record types is available from the links at the end of this tutorial.

## Searching the Audit Logs for Events

The Linux Auditing System ships with a powerful tool called `ausearch` for searching audit logs. With `ausearch`, you can filter and search for event types. It can also interpret events for you by translating numeric values to human-readable values like system calls or usernames.

Let us look at a few examples.

The following command will search the audit logs for all audit events of the type LOGIN from today and interpret usernames.

    sudo ausearch -m LOGIN --start today -i

The command below will search for all events with event id 27020 (provided there is an event with that id).

    sudo ausearch -a 27020

This command will search for all events (if any) touching the file `/etc/ssh/sshd_config` and interpret them:

    sudo ausearch -f /etc/ssh/sshd_config -i

## Generating Audit Reports

Instead of reading the raw audit logs, you can get a summary of audit messages using the tool `aureport`. It provides reports in human-readable format. These reports can be used as building blocks for more complicated analysis. When `aureport` is run without any options, it will show a summary of the different types of events present in the audit logs. When used with search options, it will show the list of events matching the search criteria.

Let us try a few examples for `aureport`. If you want to generate a summary report on all command executions on the server, run:

    sudo aureport -x --summary

The output will look something like this with different values:

    Executable Summary Report
    =================================
    total file
    =================================
    117795 /usr/sbin/sshd
    1776 /usr/sbin/crond
    210 /usr/bin/sudo
    141 /usr/bin/date
    24 /usr/sbin/autrace
    18 /usr/bin/su

The first column shows the number of times the command was executed, and the second column shows the command that was executed. Please note that not all commands are logged by default. Only security-related ones are logged.

The following command will give you the statistics of all failed events:

    sudo aureport --failed

Output looks similar to:

    Failed Summary Report
    ======================
    Number of failed logins: 11783
    Number of failed authentications: 41679
    Number of users: 3
    Number of terminals: 4
    Number of host names: 203
    Number of executables: 3
    Number of files: 4
    Number of AVC's: 0
    Number of MAC events: 0
    Number of failed syscalls: 9

To generate a report about files accessed with system calls and usernames:

    sudo aureport -f -i

Sample output:

    File Report
    ===============================================
    # date time file syscall success exe auid event
    ===============================================
    1. Monday 15 June 2015 08:27:51 /etc/ssh/sshd_config open yes /usr/bin/cat sammy 135496
    2. Tuesday 16 June 2015 00:40:15 /etc/ssh/sshd_config getxattr no /usr/bin/ls root 147481
    3. Tuesday 16 June 2015 00:40:15 /etc/ssh/sshd_config lgetxattr yes /usr/bin/ls root 147482
    4. Tuesday 16 June 2015 00:40:15 /etc/ssh/sshd_config getxattr no /usr/bin/ls root 147483
    5. Tuesday 16 June 2015 00:40:15 /etc/ssh/sshd_config getxattr no /usr/bin/ls root 147484
    6. Tuesday 16 June 2015 05:40:08 /bin/date execve yes /usr/bin/date root 148617

To view the same in summary format, you can run:

    sudo aureport -f -i --summary

**Note:** The `aureport` tool can also take input from stdin instead of log files as long as the input is in the raw log data format.

## Analyzing a Process Using autrace

To audit an individual process, we can use the `autrace` tool. This tool traces the system calls performed by a process. This can be useful in investigating a suspected trojan or a problematic process. The output of `autrace` is written to `/var/log/audit/audit.log` and looks similar to the standard audit log entries. After execution, `autrace` will present you with an example `ausearch` command to investigate the logs. Always use the full path to the binary to track with autrace, for example `sudo autrace /bin/ls /tmp`.

**Note:** Please note that running `autrace` will remove all custom auditing rules. It replaces them with specific rules needed for tracing the process you specified. After `autrace` is complete, it will clear the new rules it added. For the same reason, `autrace` will not work when your auditing rules are set immutable.

Let us try an example, say, we want to trace the process `date` and view the files and system calls used by it. Run the following:

    sudo autrace /bin/date

You should see something similar to the following:

    Waiting to execute: /bin/date
    Wed Jun 17 07:22:03 EDT 2015
    Cleaning up...
    Trace complete. You can locate the records with 'ausearch -i -p 27020'

You can use the `ausearch` command from the above output to view the related logs or even pass it to `aureport` to get well-formatted human-readable output:

    sudo ausearch -p 27020 --raw | aureport -f -i

This command searches for the event with event ID `27020` from the audit logs, extracts it in raw log format, and passes it to `aureport`, which in turn interprets and gives the results in a better format for easier reading.

You should see output similar to the following:

    File Report
    ===============================================
    # date time file syscall success exe auid event
    ===============================================
    1. Wednesday 17 June 2015 07:22:03 /bin/date execve yes /usr/bin/date sammy 169660
    2. Wednesday 17 June 2015 07:22:03 /etc/ld.so.preload access no /usr/bin/date sammy 169663
    3. Wednesday 17 June 2015 07:22:03 /etc/ld.so.cache open yes /usr/bin/date sammy 169664
    4. Wednesday 17 June 2015 07:22:03 /lib64/libc.so.6 open yes /usr/bin/date sammy 169668
    5. Wednesday 17 June 2015 07:22:03 /usr/lib/locale/locale-archive open yes /usr/bin/date sammy 169683
    6. Wednesday 17 June 2015 07:22:03 /etc/localtime open yes /usr/bin/date sammy 169691

## Conclusion

We have covered the basics of the Linux Auditing System in this tutorial. You should now have a good understanding of how the audit system works, how to read the audit logs, and the different tools available to make it easier for you to audit your server.

By default, the audit system records only a few events in the logs such as users logging in and users using sudo. SELinux-related messages are also logged. The audit daemon uses rules to monitor for specific events and create related log entries. It is possible to create custom audit rules to monitor and record in the logs whatever we want. This is where the audit system becomes powerful for a system administrator. We can add rules using either the command line tool `auditctl` or permanently in the file `/etc/audit/rules.d/audit.rules`. Writing custom rules and using predefined rule sets are discussed in detail in the [Writing Custom System Audit Rules on CentOS 7](writing-custom-system-audit-rules-on-centos-7) tutorial.

You can also check out the following resources for even more information on the audit system:

- [Types of audit records](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Audit_Record_Types.html)

- [Configuring auditd for a CAPP Environment](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-configuring_the_audit_service.html)

- [Audit Event Fields and their definitions](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Security_Guide/app-Audit_Reference.html#sec-Audit_Events_Fields)
