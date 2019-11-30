---
author: O.S Tezer
date: 2013-11-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-send-e-mail-alerts-on-a-centos-vps-for-system-monitoring
---

# How To Send E-Mail Alerts on a CentOS VPS for System Monitoring

## Introduction

* * *

The ability to send e-mail alerts is essential for the day to day management of any VPS. For system administrators (and users alike), being able to take advantage of this [new] possibility not only makes things easier, but also provides you with many allies in your combat against thieves or downtime with triggers you can create.

In this DigitalOcean article, we are going to learn how to simply send e-mail alerts on a CentOS VPS and talk about various triggers that we can set to establish better overall security and to maintain a smooth running system all around. We will do this by understanding basics of e-mail, going over the necessary applications along with examples of various e-mail alert triggers you can set and the logic behind identifying critical needs to create more.

## Understanding E-Mails

* * *

Undeterred by the number of times we use, the complexity of sending and receiving emails is rarely thought on (nor really visible) due to much of the complexity being abstracted by the companies in forms of simple, online e-mail services. The commitment for fighting spam messages made it even more so, costing a great deal of efforts for anyone who would like to simply send **_electronic mail messages_** (e-mails).

Electronic mail (or e-mail) can be considered a method or a type of message that is distributed electronically from one party to another. This does not have to be an online process spread across the internet either, as it can happen on a local network or on the same machine (i.e. your VPS) via (usually) a built in tool. However, when it is necessary to send e-mails over the internet, a lot of components come into play, starting with **message transfer agents**.

### Message Transfer Agent (or Message Transport Agent)

* * *

A “message transfer agent” is an application which actually performs the delivery of (e-mail) messages bound for user(s) both on the same system or located elsewhere (i.e. over the internet or a LAN). An MTA application is usually shipped by default with various Linux distributions and they are used by **e-mail clients** to send messages between _hosts_, usually using the **SMTP protocol**.

### Mail User Agent (E-Mail Client)

* * *

Numerously available “mail user agents” are applications that are used by _users_ (i.e. you) or other applications to send and receive e-mails. They depend on message transfer agents (MTAs) in order to work. Microsoft Outlook, Mozilla Thunderbird or even Gmail –which works online– are all suitable examples for mail user agents.

### Simple Mail Transfer Protocol (SMTP)

* * *

In order to transfer messages between hosts, a common language (i.e. a protocol) needs to be established for them to be able to communicate with each other. Created and standardized decades ago, SMTP has become the way for sending out messages. MTAs, using the SMTP protocol, do the delivery of e-mails.

## Simply Sending E-Mails with Heirloom mailx

* * *

Today, the architecture explained above covers only part of the complex nature of exchanging e-mails. For a “proper” system to work, there is so much more that needs to be done and even that, unfortunately, does not guarantee the deliverability of e-mails –to inboxes vs spam folders.

In our article, however, we are going to focus on extreme simplicity. We aim to get you up and running **in a few mere minutes** , so that you can focus on your actual work, administrating your system and receiving alerts in your inbox.

We will be working with **Heirloom mailx** , a fantastic Mail User Agent derived from _Berkeley Mail_. It provides additional support for several protocols including (but not limited to) IMAP, POP3 and of course SMTP. It will be the tool we use to receive alerts and system warnings.

**Note:** Going through online documentations or forums, you might see a similar application called **_nail_**. The two projects are (sort of) the same and _nail_ is incorporated into _mailx_. Therefore, if you see e-mail commands using “nail”, it will be enough to replace it with “mail” or “mailx” to get them executed. Alternatively you can create a **symbolic link** point to _mailx_ application. You can learn more about the history of mail, Mail, mailx and nail by visiting [mailx history](http://heirloom.sourceforge.net/mailx_history.html). For symbolic link creation, please continue to read.

### Installing mailx

* * *

Let’s begin with updating our system.

**Please note:** If you are on a stable, production environment you might wish to skip this step as it could interfere with your running applications.

**In order to update your system, run the following:**

    $ yum -y update

Getting started with mailx is quite simple. We will be using the yum package manager to download and have it installed.

**On your CentOS/RHEL machine, execute the following:**

    $ yum install -y mailx

And that’s it! We can now start sending e-mails using the “mail” (or mailx) command.

### What Are Symbolic Links and How To Create One

* * *

**Symbolic links** (symlink) are files which consist of a reference to another, existing file.

Some monitoring scripts and applications might use “email” instead “mail” or “mailx” to send e-mails. If you find yourself in this situation, you can create a _symbolic link_, pointing (referencing) to mailx.

Below, we are creating a symbolic link for “mail” to execute “mailx”.

**In order to create a symbolic link, run the following (replace `/bin/email` with the link name required):**

    $ ln -s /bin/mailx /bin/email

### How to Set an External SMTP Server to Relay E-Mails

* * *

Using this lean solution, as mentioned above, can mean that some of your e-mails might hit the spam folder. As you are aiming for a simple application for alerts, this should not be an issue. However, if you want increased delivery rates (i.e. to your inbox) you can opt to relay your messages through external SMTP servers (i.e. your e-mail provider’s or by commercial e-mail services).

In order to set up a SMTP server [configuration] for “mailx” to use, we need to edit the contents of `/etc/mail.rc` file where the application’s [certain] settings are found. We are going to open up this file using the “nano” text editor and append our settings to the top.

**Open up “mail.rc” using “nano”:**

    $ nano /etc/mail.rc

Below you can find an example SMTP settings, which you will need to modify to match your provider’s before appending to the top of “mail.rc”. Lines starting with a **#** sign are commented out –meaning, they are not in effect– and consist of the structure. The following line is the one you will need to replace accordingly to match your SMTP server details.

**Example:**

    # set smtp=smtp://smtp.server.tld:port_number
    set smtp=smtp://smtp.example.com:543
    # tell mailx that it needs to authorise
    set smtp-auth=login
    # set the user for SMTP
    # set smtp-auth-user=user@domain.tld
    set smtp-auth-user=user.name@example.com
    # set the password for authorisation
    set smtp-auth-password=enter-password-here-1234

Press “CTRL+X” and confirm “Y” to save and exit.

From now on, all mails sent will be relayed using the configuration you just have set.

> **Tip:** You can consider using Gmail’s servers or give a to simple-to-use professional mail service’s SMTP servers such as [MANDRILL](https://mandrillapp.com/) which allow you to send thousands of mails each month for free.

### Sending e-mails with `mail` (or `mailx`)

* * *

Although you could interact with the MTA sendmail directly, having “mailx” installed offers, amongst many other things, loads of simplicity and possible options to configure [in future] when necessary.

Here are some of the available options of **Heirloom mailx** :

- `-a` **file** Allows you to attach the given file to the e-mail
- `-b` **address** Sends _blind carbon copies_ to the comma separated e-mail address list
- `-c` **address** Sends _copies_ to a list of users 
- `-q` **file** Sets the message contents from the given file
- `-r` **from address** Sets the from address of the e-mail to be sent
- `-s` **subject** Sets the e-mail subject

> For a full list of options please visit the related documentation by clicking [here](http://heirloom.sourceforge.net/mailx/mailx.1.html#2).

**Example usage:**

Sending a simple message:

     echo "Your message" | mail -s "Message Subject" email@address

Sending a message with an attachment:

     echo "Message" | mail -s "Subject" -a /loc/to/attachment.txt email@address

Reading the message body from a file:

     echo | mail -s "Subject" -r from@address -q /loc/to/body.txt email@address

**Note:** Unless you have external SMTP servers set, your e-mails, as explained above, are likely to drop in the spam folder, which you will need to manually redirect to your inbox to continue to receive them there.

> For the complete Heirloom mailx documentation, consider visiting its official web site located at [http://heirloom.sourceforge.net/mailx.html](http://heirloom.sourceforge.net/mailx.html).

## Setting Up Alerts for System Monitoring, Warnings and Security Alarms

* * *

As we have everything ready, we can now look into several different examples of alerts we can get our server to issue and email.

### Monitoring Ports and Sockets

* * *

To learn more about port and socket monitoring, please refer the following article where you can learn about the subject and quickly set up Linux Socket Monitor for the task, which will use “mailx” to notify you when a new port / socket is opened.

[How to Install Linux Socket Monitor (LSM) on CentOS 6.4 on DigitalOcean Community Library](https://www.digitalocean.com/community/articles/how-to-install-linux-socket-monitor-lsm-on-centos-6-4)

### Other Monitoring Options using Bash Scripts:

* * *

If you have a specific need (i.e. monitoring against low memory, disk space, logins etc.), you can now search for various _bash_ scripts to perform the task –and there are thousands which you can find available!

### What are Bash Scripts?

* * *

**Bash Scripts** (or shell scripts, bash programs) are small applications which are used to perform quick tasks. They are simple to create and use, which is why they are heavily favored and make excellent tools for system administration.

Once you find one (for the task you need), you will need to create an empty file to save as an executable bash script.

**Example:**

You would like to receive an email alert when your disk space gets low. For this, perform a quick Google search for, say, “Send an Email Alert When Your Disk Space Gets Low”. Amongst the various result, you will see the one from Linux Jornal. Click the [URL](http://www.linuxjournal.com/content/tech-tip-send-email-alert-when-your-disk-space-gets-low) and you will see the bash script documented on the page.

**Create a new text file using `nano` for the bash script:**

    $ nano monitor_disk_space.sh

**Copy and paste the contents from the URL:**

    #!/bin/bash
    CURRENT=$(df / | grep / | awk '{ print $5}' | sed 's/%//g')
    THRESHOLD=90
    
    if ["$CURRENT" -gt "$THRESHOLD"] ; then
        mail -s 'Disk Space Alert' mailid@domainname.com << EOF
    Your root partition remaining free space is critically low. Used: $CURRENT%
    EOF
    fi

**Note:** Please do not forget to replace `mailid@domainname.com` with your e-mail address. Also, please remember that you can modify the subject line as well.

Press “CTRL+X” and confirm with “Y” in order to save and exit the file.

You have now created a small bash program called `monitor_disk_space.sh` which you can name it as you like.

We need to continue with telling our operating system that this file is an executable.

**Give the file _executable_ permission using “chmod”:**

    $ chmod +x monitor_disk_space.sh

You can try to run the file by executing it: `./monitor_disk_space.sh`

Given that we would like this small program to act like a system monitor, we will need to use the utility tool **cron** to schedule it to run at certain intervals.

Please read the following article on [How To Use Cron To Automate Tasks On a VPS](https://www.digitalocean.com/community/articles/how-to-use-cron-to-automate-tasks-on-a-vps) to learn about scheduling cron for certain tasks.

And we are done with creating our first monitoring script!

**Example 2:**

If you would like to **monitor [disk] space usage** and receive emails when a certain threshold is passed, you can refer to this excellent example from [Linix.com](https://www.linux.com/community/blogs/133-general-linux/748863-linux-shell-script-to-monitor-space-usage-and-send-email).

**Let’s begin with creating an empty shell script file:**

    $ nano monitor_space_usage.sh

**Copy and paste the contents of this self explanatory script:**

    #!/bin/bash
    
    LIMIT='80'
    #Here we declare variable LIMIT with max of used spave
    
    DIR='/var'
    #Here we declare variable DIR with name of directory
    
    MAILTO='monitor@gmail.com'
    #Here we declare variable MAILTO with email address
    
    SUBJECT="$DIR disk usage"
    #Here we declare variable SUBJECT with subject of email
    
    MAILX='mailx'
    #Here we declare variable MAILX with mailx command that will send email
    
    which $MAILX > /dev/null 2>&1
    #Here we check if mailx command exist
    
    if ! [$? -eq 0]
    #We check exit status of previous command if exit status not 0 this mean that mailx is not installed on system
    then
              echo "Please install $MAILX"
    #Here we warn user that mailx not installed
              exit 1
    #Here we will exit from script
    fi
    
    cd $DIR
    #To check real used size, we need to navigate to folder
    
    USED=`df . | awk '{print $5}' | sed -ne 2p | cut -d"%" -f1`    
    #This line will get used space of partition where we currently, this will use df command, and get used space in %, and after cut % from value.
    
    if [$USED -gt $LIMIT]
    #If used space is bigger than LIMIT
    
    then
          du -sh ${DIR}/* | $MAILX -s "$SUBJECT" "$MAILTO"
    #This will print space usage by each directory inside directory $DIR, and after MAILX will send email with SUBJECT to MAILTO
    fi

After making sure that you have modified it to match your needs (and set your e-mail address as the recipient by modifying MAILTO variable), you can save it by pressing “CTRL+X” and confirming with “Y”.

Set again the file as _executable_ and you have your second Linux system monitoring tool ready.

**To give the file execution permission, run the following:**

    $ chmod +x monitor_space_usage.sh

**Notes:**

For more shell scripts on monitoring, you can visit [http://bash.cyberciti.biz/shell/monitoring/](http://bash.cyberciti.biz/shell/monitoring/) and [http://linoxide.com/category/linux-shell-script/](http://linoxide.com/category/linux-shell-script/).

For more on shell scripts in general, visit [http://www.linoxide.com/guide/scripts-pdf.html](http://www.linoxide.com/guide/scripts-pdf.html).

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
