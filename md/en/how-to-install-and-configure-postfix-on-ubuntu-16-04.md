---
author: Justin Ellingwood
date: 2016-05-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-on-ubuntu-16-04
---

# How To Install and Configure Postfix on Ubuntu 16.04

## Introduction

Postfix is a popular open-source Mail Transfer Agent (MTA) that can be used to route and deliver email on a Linux system. It is estimated that around 25% of public mail servers on the internet run Postfix.

In this guide, we’ll teach you how to get up and running quickly with Postfix on an Ubuntu 16.04 server.

## Prerequisites

In order to follow this guide, you should have access to a non-root user with `sudo` privileges. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to create the necessary user.

In order to properly configure Postfix, you will need a Fully Qualified Domain Name pointed at your Ubuntu 16.04 server. You can find help on setting up your domain name with DigitalOcean by following [this guide](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean). If you plan on accepting mail, you will need to make sure you have an MX record pointing to your mail server as well.

For the purposes of this tutorial, we will assume that you are configuring a host that has the FQDN of `mail.example.com`.

## Step 1: Install Postfix

Postfix is included in Ubuntu’s default repositories, so installation is incredibly simple.

To begin, update your local `apt` package cache and then install the software. We will be passing in the `DEBIAN_PRIORITY=low` environmental variable into our installation command in order to answer some additional prompts:

    sudo apt-get update
    sudo DEBIAN_PRIORITY=low apt-get install postfix

Use the following information to fill in your prompts correctly for your environment:

- **General type of mail configuration?** : For this, we will choose **Internet Site** since this matches our infrastructure needs.
- **System mail name** : This is the base domain used to construct a valid email address when only the account portion of the address is given. For instance, the hostname of our server is `mail.example.com`, but we probably want to set the system mail name to `example.com` so that given the username `user1`, Postfix will use the address `user1@example.com`.
- **Root and postmaster mail recipient** : This is the Linux account that will be forwarded mail addressed to `root@` and `postmaster@`. Use your primary account for this. In our case, **sammy**.
- **Other destinations to accept mail for** : This defines the mail destinations that this Postfix instance will accept. If you need to add any other domains that this server will be responsible for receiving, add those here, otherwise, the default should work fine.
- **Force synchronous updates on mail queue?** : Since you are likely using a journaled filesystem, accept **No** here.
- **Local networks** : This is a list of the networks that your mail server is configured to relay messages for. The default should work for most scenarios. If you choose to modify it, make sure to be very restrictive in regards to the network range.
- **Mailbox size limit** : This can be used to limit the size of messages. Setting it to “0” disables any size restriction.
- **Local address extension character** : This is the character that can be used to separate the regular portion of the address from an extension (used to create dynamic aliases).
- **Internet protocols to use** : Choose whether to restrict the IP version that Postfix supports. We’ll pick “all” for our purposes.

To be explicit, these are the settings we’ll use for this guide:

- **General type of mail configuration?** : Internet Site
- **System mail name** : example.com (not mail.example.com)
- **Root and postmaster mail recipient** : sammy
- **Other destinations to accept mail for** : $myhostname, example.com, mail.example.com, localhost.example.com, localhost
- **Force synchronous updates on mail queue?** : No
- **Local networks** : 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
- **Mailbox size limit** : 0
- **Local address extension character** : +
- **Internet protocols to use** : all

If you need to ever return to re-adjust these settings, you can do so by typing:

    sudo dpkg-reconfigure postfix

The prompts will be pre-populated with your previous responses.

When you are finished, we can now do a bit more configuration to set up our system how we’d like it.

## Step 2: Tweak the Postfix Configuration

Next, we can adjust some settings that the package did not prompt us for.

To begin, we can set the mailbox. We will use the **Maildir** format, which separates messages into individual files that are then moved between directories based on user action. The other option is the **mbox** format (which we won’t cover here) which stores all messages within a single file.

We will set the `home_mailbox` variable to `Maildir/` which will create a directory structure under that name within the user’s home directory. The `postconf` command can be used to query or set configuration settings. Configure `home_mailbox` by typing:

    sudo postconf -e 'home_mailbox= Maildir/'

Next, we can set the location of the `virtual_alias_maps` table. This table maps arbitrary email accounts to Linux system accounts. We will create this table at `/etc/postfix/virtual`. Again, we can use the `postconf` command:

    sudo postconf -e 'virtual_alias_maps= hash:/etc/postfix/virtual'

## Step 3: Map Mail Addresses to Linux Accounts

Next, we can set up the virtual maps file. Open the file in your text editor:

    sudo nano /etc/postfix/virtual

The virtual alias map table uses a very simple format. On the left, you can list any addresses that you wish to accept email for. Afterwards, separated by whitespace, enter the Linux user you’d like that mail delivered to.

For example, if you would like to accept email at `contact@example.com` and `admin@example.com` and would like to have those emails delivered to the `sammy` Linux user, you could set up your file like this:

/etc/postfix/virtual

    contact@example.com sammy
    admin@example.com sammy

After you’ve mapped all of the addresses to the appropriate server accounts, save and close the file.

We can apply the mapping by typing:

    sudo postmap /etc/postfix/virtual

Restart the Postfix process to be sure that all of our changes have been applied:

    sudo systemctl restart postfix

## Step 4: Adjust the Firewall

If you are running the UFW firewall, as configured in the initial server setup guide, we’ll have to allow an exception for Postfix.

You can allow connections to the service by typing:

    sudo ufw allow Postfix

The Postfix server component is installed and ready. Next, we will set up a client that can handle the mail that Postfix will process.

## Step 5: Setting up the Environment to Match the Mail Location

Before we install a client, we should make sure our `MAIL` environmental variable is set correctly. The client will inspect this variable to figure out where to look for user’s mail.

In order for the variable to be set regardless of how you access your account (through `ssh`, `su`, `su -`, `sudo`, etc.) we need to set the variable in a few different locations. We’ll add it to `/etc/bash.bashrc` and a file within `/etc/profile.d` to make sure each user has this configured.

To add the variable to these files, type:

    echo 'export MAIL=~/Maildir' | sudo tee -a /etc/bash.bashrc | sudo tee -a /etc/profile.d/mail.sh

To read the variable into your current session, you can source the `/etc/profile.d/mail.sh` file:

    source /etc/profile.d/mail.sh

## Step 6: Install and Configure the Mail Client

In order to interact with the mail being delivered, we will install the `s-nail` package. This is a variant of the BSD `xmail` client, which is feature-rich, can handle the Maildir format correctly, and is mostly backwards compatible. The GNU version of `mail` has some frustrating limitations, such as always saving read mail to the mbox format regardless of the source format.

To install the `s-nail` package, type:

    sudo apt-get install s-nail

We should adjust a few settings. Open the `/etc/s-nail.rc` file in your editor:

    sudo nano /etc/s-nail.rc

Towards the bottom of the file, add the following options:

/etc/s-nail.rc

    . . .
    set emptystart
    set folder=Maildir
    set record=+sent

This will allow the client to open even with an empty inbox. It will also set the `Maildir` directory to the internal `folder` variable and then use this to create a `sent` mbox file within that, for storing sent mail.

Save and close the file when you are finished.

## Step 7: Initialize the Maildir and Test the Client

Now, we can test the client out.

### Initializing the Directory Structure

The easiest way to create the Maildir structure within our home directory is to send ourselves an email. We can do this with the `mail` command. Because the `sent` file will only be available once the Maildir is created, we should disable writing to that for our initial email. We can do this by passing the `-Snorecord` option.

Send the email by piping a string to the `mail` command. Adjust the command to mark your Linux user as the recipient:

    echo 'init' | mail -s 'init' -Snorecord sammy

You should get the following response:

    OutputCan't canonicalize "/home/sammy/Maildir"

This is normal and will only show during this first message. We can check to make sure the directory was created by looking for our `~/Maildir` directory:

    ls -R ~/Maildir

You should see the directory structure has been created and that a new message file is in the `~/Maildir/new` directory:

    Output/home/sammy/Maildir/:
    cur new tmp
    
    /home/sammy/Maildir/cur:
    
    /home/sammy/Maildir/new:
    1463177269.Vfd01I40e4dM691221.mail.example.com
    
    /home/sammy/Maildir/tmp:

It looks like our mail has been delivered.

### Managing Mail with the Client

Use the client to check your mail:

    mail

You should see your new message waiting:

    Outputs-nail version v14.8.6. Type ? for help.
    "/home/sammy/Maildir": 1 message 1 new
    >N 1 sammy@example.com Wed Dec 31 19:00 14/369 init

Just hitting **ENTER** should display your message:

    Output[-- Message 1 -- 14 lines, 369 bytes --]:
    From sammy@example.com Wed Dec 31 19:00:00 1969
    Date: Fri, 13 May 2016 18:07:49 -0400
    To: sammy@example.com
    Subject: init
    Message-Id: <20160513220749.A278F228D9@mail.example.com>
    From: sammy@example.com
    
    init

You can get back to your message list by typing **h** :

    h

    Outputs-nail version v14.8.6. Type ? for help.
    "/home/sammy/Maildir": 1 message 1 new
    >R 1 sammy@example.com Wed Dec 31 19:00 14/369 init

Since this message isn’t very useful, we can delete it with **d** :

    d

Quit to get back to the terminal by typing **q** :

    q

### Sending Mail with the Client

You can test sending mail by typing a message in a text editor:

    nano ~/test_message

Inside, enter some text you’d like to email:

~/test\_message

    Hello,
    
    This is a test. Please confirm receipt!

Using the `cat` command, we can pipe the message to the `mail` process. This will send the message as your Linux user by default. You can adjust the “From” field with the `-r` flag if you want to modify that value to something else:

    cat ~/test_message | mail -s 'Test email subject line' -r from_field_account user@email.com

The options above are:

- `-s`: The subject line of the email
- `-r`: An optional change to the “From:” field of the email. By default, the Linux user you are logged in as will be used to populate this field. The `-r` option allows you to override this.
- `user@email.com`: The account to send the email to. Change this to be a valid account you have access to.

You can view your sent messages within your `mail` client. Start the interactive client again by typing:

    mail

Afterwards, view your sent messages by typing:

    file +sent

You can manage sent mail using the same commands you use for incoming mail.

## Conclusion

You should now have Postfix configured on your Ubuntu 16.04 server. Managing email servers can be a tough task for beginning administrators, but with this configuration, you should have basic MTA email functionality to get you started.
