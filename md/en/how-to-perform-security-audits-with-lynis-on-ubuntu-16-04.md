---
author: finid
date: 2017-04-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-perform-security-audits-with-lynis-on-ubuntu-16-04
---

# How to Perform Security Audits With Lynis on Ubuntu 16.04

## Introduction

[Lynis](https://cisofy.com/lynis/) is a host-based, open-source security auditing application that can evaluate the security profile and posture of Linux and other UNIX-like operating systems.

In this tutorial, you’ll install Lynis on and use it to perform a security audit of your Ubuntu 16.04 server. Then you’ll explore the results of a sample audit, and configure Lynis to skip tests that aren’t relevant to your needs.

Lynis won’t perform any system hardening automatically. but it will offer suggestions that show you how you can go about hardening the system yourself. As such, it’ll be helpful if you have a fundamental knowledge of Linux system security. You should also be familiar with the services running on the machine you plan to audit, such as web servers, databases, and other services that Lynis might scan by default. This will help you identify results you can safely ignore.

**Note** : Performing a security audit takes time and patience. You may want to take the time to read through the whole article once before installing Lynis and using it to audit your server.

## Prerequisites

To complete this article, you’ll need:

- One Ubuntu 16.04 server, configured with a non-root user with sudo privileges and a firewall, as shown in the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial.

## Step 1 — Installing Lynis on Your Server

There are several ways to install Lynis. You can compile it from source, download and copy the binary to an appropriate location on the system, or you can install it using the package manager. Using the package manager is the easist way to install Lynis and keep it updated, so that’s the method we’ll use.

However, on Ubuntu 16.04, the version available from the repository isn’t the most recent version. In order to have access to the very latest features, we’ll install Lynis from the project’s official repository.

Lynis’s software repository uses the HTTPS protocol, so we’ll need to make sure that HTTPS support for the package manager is installed. Use the following command to check:

    dpkg -s apt-transport-https | grep -i status

If it is installed, the output of that command should be:

    OutputStatus: install ok installed

If the output says it is not installed, install it using `sudo apt-get install apt-transport-https`

With the lone dependency now installed, we’ll install Lynis. To begin that process, add the repository’s key:

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C80E383C3DE9F082E01391A0366C67DE91CA5D5F

You’ll see the following output, indicating the key was added successfully:

    OutputExecuting: /tmp/tmp.AnVzwb6Mq8/gpg.1.sh --keyserver
    keyserver.ubuntu.com
    --recv-keys
    C80E383C3DE9F082E01391A0366C67DE91CA5D5F
    gpg: requesting key 91CA5D5F from hkp server keyserver.ubuntu.com
    gpg: key 91CA5D5F: public key "CISOfy Software (signed software packages) <software@cisofy.com>" imported
    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

Then add the Lynis repository to the list of those available to the package manager:

    sudo add-apt-repository "deb [arch=amd64] https://packages.cisofy.com/community/lynis/deb/ xenial main"

To make the packages in the newly-added repository available to the system, update the package database:

    sudo apt-get update

Finally, install Lynis:

    sudo apt-get install lynis

After the installation has completed, you should have access to the `lynis` command and its sub-commands. Let’s look at how to use Lynis next.

## Step 2 – Performing an Audit

With the installation completed, you can now use Lynis to perform security audits of your system. Let’s start by viewing a list of actions you can perform with Lynis. Execute the following command:

    lynis show commands

You’ll see the following output:

    Output
    Commands:
    lynis audit
    lynis configure
    lynis show
    lynis update
    lynis upload-only
    

Lynis audits are made possible using profiles, which are like configuration files with settings that control how Lynis conducts an audit. View the settings for the default profile:

    lynis show settings

You’ll see output like the following:

    Output# Colored screen output
    colors=1
    
    # Compressed uploads
    compressed-uploads=0
    
    # Use non-zero exit code if one or more warnings were found
    error-on-warnings=0
    
    ...
    
    # Upload server (ip or hostname)
    upload-server=[not configured]
    
    # Data upload after scanning
    upload=no
    
    # Verbose output
    verbose=0
    
    # Add --brief to hide descriptions, --configured-only to show configured items only, or --nocolors to remove colors

It’s always a good idea to verify whether a new version is available before performing an audit. This way you’ll get the most up-to-date suggestions and information. Issue the following command to check for updates:

    lynis update info

The output should be similar to the following, which shows that the version of Lynis is the most recent:

    Output == Lynis ==
    
      Version : 2.4.8
      Status : Up-to-date
      Release date : 2017-03-29
      Update location : https://cisofy.com/lynis/
    
    
    2007-2017, CISOfy - https://cisofy.com/lynis/

Alternatively, you could type `lynis update check`, which generates the following one-line output:

    Outputstatus=up-to-date

If the version requires an update, use your package manager to perform the update.

To run an audit of your system, use the `lynis audit system` command. You can run Lynis in privileged and non-privileged (pentest) mode. In the latter mode, some tests that require root privileges are skipped. As a result, you should run your audit in privileged mode with `sudo`. Execute this command to perform your first audit:

    sudo lynis audit system

After authenticating, Lynis will run its tests and stream the results to your screen. A Lynis audit typically takes a minute or less.

When Lynis performs an audit, it goes through a number of tests, divided into categories. After each audit, test results, debug information, and suggestions for hardening the system are written to standard output (the screen). More detailed information is logged to `/var/log/lynis.log`, while report data is saved to `/var/log/lynis-report.dat`. The report data contains general information about the server and the application itself, so the file you’ll need to pay attention to is the log file. The log file is purged (overwritten) on each audit, so results from a previous audit are not saved.

Once the audit is complete, you’ll review the results, warnings, and suggestions, and then implement any of the relevant suggestions.

Let’s look at the results of a Lynis audit performed on the machine used to write this tutorial. The results you see on your audit may be different, but you should still be able to follow along.

The first significant part of a Lynis audit output is purely informational. It tells you the result of every test, grouped by category. The information takes the form of keywords, like **NONE** , **WEAK** , **DONE** , **FOUND** , **NOT\_FOUND** , **OK** , and **WARNING**.

    Output[+] Boot and services
    ------------------------------------
     - Service Manager [systemd]
     - Checking UEFI boot [DISABLED]
     - Checking presence GRUB [OK]
     - Checking presence GRUB2 [FOUND]
       - Checking for password protection [WARNING]
    
    ..
    
    [+] File systems
    ------------------------------------
     - Checking mount points
        - Checking /home mount point [SUGGESTION]
        - Checking /tmp mount point [SUGGESTION]
        - Checking /var mount point [OK]
     - Query swap partitions (fstab) [NONE]
     - Testing swap partitions [OK]
     - Testing /proc mount (hidepid) [SUGGESTION]
     - Checking for old files in /tmp [OK]
     - Checking /tmp sticky bit [OK]
     - ACL support root file system [ENABLED]
     - Mount options of / [OK]
     - Checking Locate database [FOUND]
     - Disable kernel support of some filesystems
        - Discovered kernel modules: udf
    
    ...
    
    [+] Hardening
    ------------------------------------
     - Installed compiler(s) [FOUND]
     - Installed malware scanner [NOT FOUND]
     - Installed malware scanner [NOT FOUND]
    
    ...
    
    [+] Printers and Spools
    ------------------------------------
     - Checking cups daemon [NOT FOUND]
     - Checking lp daemon [NOT RUNNING]

Though Lynis performs more than 200 tests out of the box, not all are necessary for your server. How can you tell which tests are necessary and which are not? That’s where some knowledge about what should or should not be running on a server comes into play. For example, if you check the results section of a typical Lynis audit, you’ll find two tests under the **Printers and Spools** category:

    Output[+] Printers and Spools
    ------------------------------------
     - Checking cups daemon [NOT FOUND]
     - Checking lp daemon [NOT RUNNING]

Are you actually running a print server on an Ubuntu 16.04 server? Unless you’re running a cloud-based print server, you don’t need Lynis to be running that test every time.

While that’s a perfect example of a test you can skip, others are not so obvious. Take this partial results section, for example:

    Output[+] Insecure services
    ------------------------------------
      - Checking inetd status [NOT ACTIVE]

This output says that `inetd` is not active, but that’s expected on an Ubuntu 16.04 server, because Ubuntu replaced `inetd` with `systemd`. Knowing that, you may tag that test as one that Lynis should not be performing as part of an audit on your server.

As you review each of the test results, you’ll come up with a pretty good list of superfluous tests. With that list in hand, you may, then, customize Lynis to ignore them in future audits. You’ll learn how to get that done in Step 5.

In the next sections, we’ll go through the different parts of a Lynis audit output so you’ll have a better understanding of how to properly audit your system with Lynis. Let’s look at how to deal with warnings issued by Lynis first.

## Step 3 – Fixing Lynis Audit Warnings

A Lynis audit output does not always carry a warnings section, but when it does, you’ll know how to fix the issue(s) raised after reading this section.

Warnings are listed after the results section. Each warning starts with the warning text itself, with the test that generated the warning on the same line in brackets. The next line will contain a suggested solution, if one exists. The last line is a security control URL where you may find some guidance on the warning. Unfortunately, the URL does not always offer an explanation, so you may need to do some further research.

The following output comes from the warnings section of a Lynis audit performed on the server used for this article. Let’s walk through each warning and look at how to resolve or fix it:

    OutputWarnings (3):
      ----------------------------
    ! Version of Lynis is very old and should be updated [LYNIS]
        https://cisofy.com/controls/LYNIS/
    
    ! Reboot of system is most likely needed [KRNL-5830]
        - Solution : reboot
          https://cisofy.com/controls/KRNL-5830/
    
    ! Found one or more vulnerable packages. [PKGS-7392]
          https://cisofy.com/controls/PKGS-7392/

The first warning says that Lynis needs to be updated. That also means this audit used version of Lynis, so the results might not be complete. This could have been avoided if we’d performed a basic version check before running the results, as shown in Step 3. The fix for this one is easy: update Lynis.

The second warning indicates that the server needs to be rebooted. That’s probably because a system update that involved a kernel upgrade was performed recently. The solution here is to reboot the system.

When in doubt about any warning, or just about any test result, you can get more information about the test by querying Lynis for the test id. The command to accomplish that takes this form:

    sudo lynis show details test-id

So for the second warning, which has the test id **KRNL-5830** , we could run this command:

    sudo lynis show details KRNL-5830

The output for that particular test follows. This gives you an idea of the process Lynis walks through for each test it performs. From this output, Lynis even gives specific information about the item that gave rise to the warning:

    Output2017-03-21 01:50:03 Performing test ID KRNL-5830 (Checking if system is running on the latest installed kernel)
    2017-03-21 01:50:04 Test: Checking presence /var/run/reboot-required.pkgs
    2017-03-21 01:50:04 Result: file /var/run/reboot-required.pkgs exists
    2017-03-21 01:50:04 Result: reboot is needed, related to 5 packages
    2017-03-21 01:50:04 Package: 5
    2017-03-21 01:50:04 Result: /boot exists, performing more tests from here
    2017-03-21 01:50:04 Result: /boot/vmlinuz not on disk, trying to find /boot/vmlinuz*
    2017-03-21 01:50:04 Result: using 4.4.0.64 as my kernel version (stripped)
    2017-03-21 01:50:04 Result: found /boot/vmlinuz-4.4.0-64-generic
    2017-03-21 01:50:04 Result: found /boot/vmlinuz-4.4.0-65-generic
    2017-03-21 01:50:04 Result: found /boot/vmlinuz-4.4.0-66-generic
    2017-03-21 01:50:04 Action: checking relevant kernels
    2017-03-21 01:50:04 Output: 4.4.0.64 4.4.0.65 4.4.0.66
    2017-03-21 01:50:04 Result: Found 4.4.0.64 (= our kernel)
    2017-03-21 01:50:04 Result: found a kernel (4.4.0.65) later than running one (4.4.0.64)
    2017-03-21 01:50:04 Result: Found 4.4.0.65
    2017-03-21 01:50:04 Result: found a kernel (4.4.0.66) later than running one (4.4.0.64)
    2017-03-21 01:50:04 Result: Found 4.4.0.66
    2017-03-21 01:50:04 Warning: Reboot of system is most likely needed [test:KRNL-5830] [details:] [solution:text:reboot]
    2017-03-21 01:50:04 Hardening: assigned partial number of hardening points (0 of 5). Currently having 7 points (out of 14)
    2017-03-21 01:50:04 Checking permissions of /usr/share/lynis/include/tests_memory_processes
    2017-03-21 01:50:04 File permissions are OK
    2017-03-21 01:50:04 ===---------------------------------------------------------------===

For the third warning, **PKGS-7392** , which is about vulnerable packages, we’d run this command:

    sudo lynis show details PKGS-7392

The output gives us more information regarding the packages that need to be updated:

    Output2017-03-21 01:39:53 Performing test ID PKGS-7392 (Check for Debian/Ubuntu security updates)
    2017-03-21 01:39:53 Action: updating repository with apt-get
    2017-03-21 01:40:03 Result: apt-get finished
    2017-03-21 01:40:03 Test: Checking if /usr/lib/update-notifier/apt-check exists
    2017-03-21 01:40:03 Result: found /usr/lib/update-notifier/apt-check
    2017-03-21 01:40:03 Test: checking if any of the updates contain security updates
    2017-03-21 01:40:04 Result: found 7 security updates via apt-check
    2017-03-21 01:40:04 Hardening: assigned partial number of hardening points (0 of 25). Currently having 96 points (out of 149)
    2017-03-21 01:40:05 Result: found vulnerable package(s) via apt-get (-security channel)
    2017-03-21 01:40:05 Found vulnerable package: libc-bin
    2017-03-21 01:40:05 Found vulnerable package: libc-dev-bin
    2017-03-21 01:40:05 Found vulnerable package: libc6
    2017-03-21 01:40:05 Found vulnerable package: libc6-dev
    2017-03-21 01:40:05 Found vulnerable package: libfreetype6
    2017-03-21 01:40:05 Found vulnerable package: locales
    2017-03-21 01:40:05 Found vulnerable package: multiarch-support
    2017-03-21 01:40:05 Warning: Found one or more vulnerable packages. [test:PKGS-7392] [details:-] [solution:-]
    2017-03-21 01:40:05 Suggestion: Update your system with apt-get update, apt-get upgrade, apt-get dist-upgrade and/or unattended-upgrades [test:PKGS-7392] [details:-] [solution:-]
    2017-03-21 01:40:05 ===---------------------------------------------------------------===

The solution for this is to update the package database and update the system.

After fixing the item that led to a warning, you should run the audit again. Subsequent audits should be free of the same warning, although new warnings could show up. In that case, repeat the process shown in this step and fix the warnings.

Now that you know how to read and fix warnings generated by Lynis, let’s look at how to implement the suggestions that Lynis offers.

## Step 4 — Implementing Lynis Audit Suggestions

After the warnings section, you’ll see a series of suggestions that, if implemented, can make your server less vulnerable to attacks and malware. In this step, you’ll learn how to implement some suggestions generated by Lynis after an audit of a test Ubuntu 16.04 server. The process to do this is identical to the steps in the previous section.

A specific suggestion starts with the suggestion itself, followed by the test ID. Then, depending on the test, the next line will tell you exactly what changes to make in the affected service’s configuration file. The last line is a security control URL where you can find more information about the subject.

Here, for example, is a partial suggestion section from a Lynis audit, showing suggestions pertaining to the SSH service:

    OutputSuggestions (36):
      ----------------------------
      * Consider hardening SSH configuration [SSH-7408]
        - Details : ClientAliveCountMax (3 --> 2)
          https://cisofy.com/controls/SSH-7408/
    
      * Consider hardening SSH configuration [SSH-7408]
        - Details : PermitRootLogin (YES --> NO)
          https://cisofy.com/controls/SSH-7408/  
    
      * Consider hardening SSH configuration [SSH-7408]
        - Details : Port (22 --> )
          https://cisofy.com/controls/SSH-7408/
    
      * Consider hardening SSH configuration [SSH-7408]
        - Details : TCPKeepAlive (YES --> NO)
          https://cisofy.com/controls/SSH-7408/
    
      * Consider hardening SSH configuration [SSH-7408]
        - Details : UsePrivilegeSeparation (YES --> SANDBOX)
          https://cisofy.com/controls/SSH-7408/
    ...
    

Depending on your environment, all these suggestions are safe to implement. To make that determination, however, you have to know what each directive means. Because these pertain to the SSH server, all changes have to be made in the SSH daemons configuration file,`/etc/ssh/sshd_config`. If you have any doubt about any suggestion regarding SSH given by Lynis, look up the directive with `man sshd_config`. That information is also [available online](http://manpages.ubuntu.com/manpages/xenial/en/man5/sshd_config.5.html).

One of the suggestions calls for changing the default SSH port from `22`. If you make that change, and you have the firewall configured, be sure to insert a rule for SSH access through that new port.

As with the warnings section, you can get more detailed information about a suggestion by querying Lynis for the test id using `sudo lynis show details test-id`.

Other suggestions require that you to install additional software on your server. Take this one, for example:

    Output* Harden the system by installing at least one malware scanner, to perform periodic file system scans [HRDN-7230]
        - Solution : Install a tool like rkhunter, chkrootkit, OSSEC
          https://cisofy.com/controls/HRDN-7230/

The suggestion is to install `rkhunter`, `chkrootkit`, or OSSEC to satisfy a hardening test (HRDN-7230). OSSEC is a host-based intrusion detection system that can generate and send alerts. It’s a very good security application that will help with some of the tests performed by Lynis. You can learn more about this tool [in these DigitalOcean tutorials](https://www.digitalocean.com/community/tutorials?q=ossec). However, installing OSSEC alone does not cause this particular test to pass. Installing `chkrootkit` finally gets it passing. This is another case where you’ll sometimes have to additional research beyond what Lynis suggests.

Let’s look at another example. Here’s a suggestion displayed as a result of a file integrity test.

    Output* Install a file integrity tool to monitor changes to critical and sensitive files [FINT-4350]
          https://cisofy.com/controls/FINT-4350/

The suggestion given in the security control URL does not mention the OSSEC program mentioned in the previous suggestion, but installing it was enough to pass the test on a subsequent audit. That’s because OSSEC is a pretty good file integrity monitoring tool.

You can ignore some suggestions that don’t apply to you. Here’s an example:

    Output* To decrease the impact of a full /home file system, place /home on a separated partition [FILE-6310]
          https://cisofy.com/controls/FILE-6310/
    
      * To decrease the impact of a full /tmp file system, place /tmp on a separated partition [FILE-6310]
          https://cisofy.com/controls/FILE-6310/

Historically, core Linux file systems like `/home`, `/tmp`, `/var`, and `/usr` were mounted on a separate partition to minimize the impact on the whole server when they run out of disk space. This isn’t something you’ll see that often, especially on cloud servers. These file systems are now just mounted as a directory on the same root partition. But if you perform a Lynis audit on such a system, you’ll get a couple of suggestions like the ones shown in the preceding output. Unless you’re in a position to implement the suggestions, you’ll probably want to ignore them and configure Lynis so the test that caused them to be generated is not performed on future audits.

Performing a security audit using Lynis involves more than just fixing warning and implementing suggestions; it also involves identifying superfluous tests. In the next step, you’ll learn how to customize the default profile to ignore such tests.

## Step 5 – Customizing Lynis Security Audits

In this section, you’ll learn how to customize Lynis so that it runs only those tests that are necessary for your server. Profiles, which govern how audits run, are defined in files with the `.prf` extension in the `/etc/lynis` directory. The default profile is aptly named `default.prf`. You don’t edit that default profile directly. Instead, you add any changes you want to a `custom.prf` file in the same directory as the profile definition.

Create a new file called `/etc/lynis/custom.prf` using your text editor:

    sudo nano /etc/lynis/custom.prf

Let’s use this file to tell Lynis to skip some tests. Here are the tests we want to skip:

- **FILE-6310** : Used to check for separation of partitions.
- **HTTP-6622** : Used to test for Nginx web server installation.
- **HTTP-6702** : Used to check for Apache web server installation. This test and the Nginx test above are performed by default. So if you have Nginx installed and not Apache, you’ll want to skip the Apache test.
- **PRNT-2307** and **PRNT-2308** : Used to check for a print server.
- **TOOL-5002** : Use to check for automation tools like Puppet and Salt. If you have no need for such tools on your server, it’s OK to skip this test.
- **SSH-7408:tcpkeepalive** : Several Lynis tests can be grouped under a single test ID. If there’s a test within that test id that you wish to skip, this is how to specify it.  

To ignore a test, you pass the **skip-test** directive the test ID you wish to ignore, one per line. Add the following code to your file:

/etc/lynis/custom.prf

    # Lines starting with "#" are comments
    # Skip a test (one per line)
    
    # This will ignore separation of partitions test
    skip-test=FILE-6310
    
    # Is Nginx installed?
    skip-test=HTTP-6622
    
    # Is Apache installed?
    skip-test=HTTP-6702
    
    # Skip checking print-related services
    skip-test=PRNT-2307
    skip-test=PRNT-2308
    
    # If a test id includes more than one test use this form to ignore a particular test
    skip-test=SSH-7408:tcpkeepalive

Save and close the file.

The next time you perform an audit, Lynis will skip the tests that match the test IDs you configured in the custom profile. The tests will be omitted from the results section of the audit output, as well as the suggestions section.

The `/etc/lynis/custom.prf` file also lets you modify any settings in a profile. To do that, copy the setting from `/etc/lynis/default.prf` into `/etc/lynis/custom.prf` and modify it there. You’ll rarely need to modify these settings, so focus your effort on finding tests you can skip.

Next, let’s take a look at what Lynis calls the _hardening index_.

## Step 6 – Interpreting the Hardening Index

In the lower section of every Lynis audit output, just below the suggestions section, you’ll find a section that looks like the following:

    OutputLynis security scan details:
    
      Hardening index : 64 [############]
      Tests performed : 206
      Plugins enabled : 0

This output tells you how many tests were performed, along with a _hardening index_, a number that Lynis provides to give you a sense of how secure your server is. This number is unique to Lynis. The hardening index will change in relation to the warnings that you fix and the suggestions that you implement. This output, which shows that the system has a hardening index of 64 is from the first Lynis audit on a new Ubuntu 16.04 server.

After fixing the warnings and implementing most of the suggestions, a new audit gave the following output. You can see that the hardening index is slightly higher:

    OutputLynis security scan details:
    
     Hardening index : 86 [#################]
     Tests performed : 205
     Plugins enabled : 0

The hardening index is not an accurate assessment of how secure a server is, but merely a measure of how well the server is securely configured (or hardened) based on the tests performed by Lynis. And as you’ve seen, the higher the index, the better. The objective of a Lynis security audit is not just to get a high hardening index, but to fix the warnings and suggestions it generates.

## Conclusion

In this tutorial, you installed Lynis, used it to perform a security audit of an Ubuntu 16.04 server, explored how to fix the warnings and suggestions it generates, and how to customize the tests that Lynis performs.

It takes a little extra time and effort, but it’s worth the investment to make your machine more secure, and Lynis makes that process much easier.

For more information on Lynis, take a look at [Get Started with Lynis](https://cisofy.com/documentation/lynis/get-started) in the official documentation. Lynis is an open-source project, so if you are interested in contributing, visit the project’s [GitHub page](https://github.com/CISOfy/lynis).
