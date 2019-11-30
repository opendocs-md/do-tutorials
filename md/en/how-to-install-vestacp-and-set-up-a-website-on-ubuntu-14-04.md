---
author: Jonah Aragon
date: 2015-12-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-vestacp-and-set-up-a-website-on-ubuntu-14-04
---

# How To Install VestaCP and Set Up a Website on Ubuntu 14.04

 **Warning:** On April 8th, 2018, a vulnerability was discovered in VestaCP that allowed attackers to compromise host systems and send malicious traffic targeting other servers. As a result, DigitalOcean has disabled port `8083` and VestaCP has taken down installation files until the issue has been patched which will affect new and existing installations. To find out more about ongoing developments and learn how to mitigate this issue, [read the Community question about this vulnerability](https://www.digitalocean.com/community/questions/how-do-i-determine-the-impact-of-vestacp-vulnerability-from-april-8th-2018).

## Introduction

The Vesta Control Panel is a free, open source website control panel with website, email, database, and DNS functionalities built in. By the end of this tutorial we will have Vesta installed and running on Ubuntu 14.04 with a working website and email account.

## Prerequisites

The following are required to complete this tutorial:

This tutorial uses `example.com` as the example hostname. Replace it with your domain name throughout this tutorial.

- An Ubuntu 14.04 server
- A registered domain name pointed to this Droplet. You can read [this series](how-to-set-up-a-host-name-with-digitalocean) on hostnames for more information.
- An **A record** pointing `example.com` to your Droplet’s IP
- An **A record** pointing `ns1.example.com` to your Droplet’s IP
- An **A record** pointing `ns2.example.com` to your Droplet’s IP
- An **A record** pointing `panel.example.com` to your Droplet’s IP
- A **CNAME record** pointing `www.example.com` to `example.com`
- Filezilla or another FTP client installed on your computer
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)

Unless otherwise specified, all the commands in this tutorial should be run as a non-root user with sudo access.

## Step 1 — Installing Vesta

The first step is to download the installation script. The installation script requires direct root access, so make sure you are the root user before executing the commands in this step.

    curl -O http://vestacp.com/pub/vst-install.sh

Then, as root, execute the installation script:

    bash vst-install.sh

When asked if you want to proceed, enter `y`. You will then be asked to enter a valid email address, enter your email address and press `ENTER`. Now you will be asked to enter a hostname. This can be whatever you want, but generally it’s a domain name, like `panel.example.com`.

**Note:** Whatever domain name you enter when installing Vesta will be used for the URL of the Vesta control panel. For example, if you enter `panel.example.com`, [https://panel](https://panel).example.com:8083 will be used to access Vesta. If you are using Vesta to setup a website for `example.com`, _do not_ use `example.com` during the installation process. Use `panel.example.com` and then setup the `example.com` website domain using the Vesta control panel.

The installation process will begin. It claims to take 15 minutes but I’ve found it to be around 5 with SSD and Gigabit Internet speeds, like on DigitalOcean Droplets.

This installation script will install the control panel and all its dependencies to your server. This includes:

- Nginx Web Server
- Apache Web Server (as backend)
- Bind DNS Server
- Exim mail server
- Dovecot POP3/IMAP Server
- MySQL Database Server
- Vsftpd FTP Server
- Iptables Firewall + Fail2Ban
- Roundcube mail client

It will also change your hostname to whatever hostname you entered at the beginning, however it will not change the hostname in your DigitalOcean control panel. I recommend you change that hostname as well for Pointer DNS records to match your domain, which will at the very least help emails sent from your server not to get sent to spam.

After the script finishes its work you’ll have some information displayed on your screen, which will look a bit like this:

    =======================================================
    
     _| _| _|_|_|_| _|_|_| _|_|_|_|_| _|_|   
     _| _| _| _| _| _| _| 
     _| _| _|_|_| _|_| _| _|_|_|_| 
       _| _| _| _| _| _| _| 
         _| _|_|_|_| _|_|_| _| _| _| 
    
    
    Congratulations, you have just successfully installed Vesta Control Panel
    
        https://panel.example.com:8083
        username: admin
        password: v6qyJwSfSj

This should conclude basic installation of your control panel. We can now continue to the web panel.

You no longer need to be logged in as the root user. Go back to your non-root sudo user now. For example:

    su - sammy

## Step 2 — Setting up Vesta

Now we will set up your Vesta control panel. Go to the URL given to you at the end of the install. In my case it was `https://panel.example.com:8083/`, but yours will vary based on the hostname you entered at the beginning. You will get an SSL warning, like shown below:

![SSL Warning](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vestacp/vestacp-ssl-warning.png)

This is completely normal because it is using a self-signed certificate. It is completely safe to continue. Click to proceed anyway. The exact steps vary by web browser. For Chrome, click `Advanced` and then click `Proceed`. Once you’re at the login screen, enter the two credentials displayed in the server console after the installation finished. These credentials were also emailed to you using the email you entered at the beginning of the install.

![Vesta Homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vestacp/vestacp-homepage.png)

The first thing we’ll do is change the admin user password. In the top right-hand corner of the web panel click the **admin** link:

In the **Password** field, enter any password you’d like, or click **Generate** to make Vesta generate a secure password for you.

While you’re on this screen, you can optionally change other settings as well such as name and language. Additionally, at the bottom of the screen, you should set Nameservers for your server. These will be subdomains of your own domain, and you will point future domains you want to set up on Vesta to them. Generally you would choose `ns1.example.com`, and `ns2.example.com`.

Press **Save** at the bottom of the page when you’re finished.

## Step 3 — Setting up a Website

Now we can set up your first website. On the homepage of Vesta, click **WEB** at the top.

Then click the green **+** button. In the **Domain** field on the next screen, enter the domain you’d like your website to be accessible from, or the one you registered to point to this Droplet’s IP address such as `example.com`. Also in some situations you may have multiple IP addresses under the **IP Address** dropdown, usually if you have Private Networking enabled. Make sure the IP address listed is your public IP address for your Droplet. Now click the **Advanced Options** link. Under **Aliases** enter any subdomains you also want this website to be accessible from, such as `www.example.com`. You can also choose _webalizer_ as a statistics option under **Web Statistics** for server side analytics. This option will give you accurate analytics for your website.

You should also choose **Additional FTP** so you can easily upload files to your hosting. Enter a **Username** and a **Password** in their respective fields. Note that whatever you enter in the username field will have `admin_` added as a prefix (entering example will result in admin\_example).

Be sure to click **Add** at the bottom of the page after making any configurations you’d like.

**Note:** FTP connections are not encrypted. The username, password, and any files sent over an FTP connection can be intercepted and read. Use a unique password and do not send sensitive files over this connection.

On your computer, you now need to connect via FTP to your Droplet:

    ftp your_droplet_ip

Alternatively, you can use a program such as Filezilla to connect to your website via FTP.

There will be a bunch of files in the directory, but we only need to worry about the `public_html` directory. That’s where all the files that are web accessible are stored. You can edit the `index.html` file to whatever you’d like, or upload your own. Anything uploaded will be instantly available at `example.com`. Be warned, any files you upload with the same filename will overwrite existing files on your server. Otherwise, by default, your website landing page will show up like this:

![example.com](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vestacp/vestacp-default-page.png)

Try visiting `http://example.com` now to make sure it works.

If you want to make changes to your domain later, click \*_WEB_ at the top of the Vesta control panel. You will see the domain you just created and the domain name for the Vesta control panel, such as panel.example.com.

## Step 4 — Setting Up an Email Account

Now we can set up an email account, something personalized like `username@example.com`. In Vesta, click **MAIL** at the top of the screen. On the mail screen hover over the domain you’d like your email on and click **ADD ACCOUNT** when the button shows up. On the following screen, enter a username in the **Account** field and a password for the account in the **Password** field. You can press **Add** now or check out the **Advanced Options**. In those options you have three fields.

- **Quota** allows you to set a mailbox size limit. This is useful if you want to conserve disk space or you’re making an account for another user. You can press the infinity symbol also to give it ‘unlimited’ storage.

- **Aliases** allows you to add other email addresses that forward to that main account.

- **Forward to** allows you to enter an email address to forward all this email to. For instance if you have an email account on another service and you want to keep your emails there, you can enter that email, so emails from `username@example.com` go to `username@emailservice.net`. If you use this option, it might be good to check the **Do not store forwarded email** checkbox as well, to make sure storage isn’t wasted on your server.

The email you just set up can be easily accessed from `http://panel.example.com/webmail/`. Simply login on that screen with the username and password you just set up. It’s important to note you need to include the domain in the **Username** field. If your account name was `hello` you should enter `hello@example.com`.

## Conclusion

Congratulations, you now have a fully functioning web and email server installed on your Droplet. You can repeat Steps 3 and 4 to add more websites and emails. Also check out the [Vesta documentation](https://vestacp.com/docs/) if you have any issues. Or if you need further help, ask a question at DigitalOcean’s great [Community Q/A center](https://www.digitalocean.com/community/questions).
