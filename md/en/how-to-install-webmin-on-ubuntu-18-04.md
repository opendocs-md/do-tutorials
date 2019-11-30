---
author: Theo B
date: 2018-05-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-webmin-on-ubuntu-18-04
---

# How To Install Webmin on Ubuntu 18.04

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a $100 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Webmin](http://www.webmin.com/) is a web-based control panel for any Linux machine which lets you manage your server through a modern web-based interface. With Webmin, you can change settings for common packages on the fly, including web servers and databases, as well as manage users, groups, and software packages.

In this tutorial, you’ll install and configure Webmin on your server and secure access to the interface with a valid certificate using [Let’s Encrypt](https://letsencrypt.org/) and Apache. You’ll then use Webmin to add new user accounts, and update all packages on your server from the dashboard.

## Prerequisites

To complete this tutorial, you will need:

- One Ubuntu 18.04 server set up by following [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall. 
- Apache installed by following [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04). We’ll use Apache to perform Let’s Encrypt’s domain verification and act as a proxy for Webmin. Ensure you configure access to Apache through your firewall when following this tutorial.
- A Fully-Qualified Domain Name (FQDN), with a DNS **A** record pointing to the IP address of your server. To configure this, follow the tutorial [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean). 
- Certbot installed by following Step 1 of [How To Secure Apache with Let’s Encrypt on Ubuntu 18.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04). You’ll use Certbot to generate the TLS/SSL certificate for Webmin.

## Step 1 — Installing Webmin

First, we need to add the Webmin repository so that we can easily install and update Webmin using our package manager. We do this by adding the repository to the `/etc/apt/sources.list` file.

Open the file in your editor:

    sudo nano /etc/apt/sources.list

Then add this line to the bottom of the file to add the new repository:

/etc/apt/sources.list

     . . . 
    deb http://download.webmin.com/download/repository sarge contrib

Save the file and exit the editor.

Next, add the Webmin PGP key so that your system will trust the new repository:

    wget http://www.webmin.com/jcameron-key.asc
    sudo apt-key add jcameron-key.asc

Next, update the list of packages to include the Webmin repository:

    sudo apt update 

Then install Webmin:

    sudo apt install webmin 

Once the installation finishes, you’ll be presented with the following output:

    OutputWebmin install complete. You can now login to 
    https://your_server_ip:10000 as root with your 
    root password, or as any user who can use `sudo`.

Now, let’s secure access to Webmin by putting it behind the Apache web server and adding a valid TLS/SSL certificate.

## Step 2 — Securing Webmin with Apache and Let’s Encrypt

To access Webmin, you have to specify port `10000` and ensure the port is open on your firewall. This is inconvenient, especially if you’re accessing Webmin using an FQDN like `webmin.your_domain` We are going to use an Apache virtual host to proxy requests to Webmin’s server running on port `10000`. We’ll then secure the virtual host using a TLS/SSL certificate from Let’s Encrypt.

First, create a new Apache virtual host file in Apache’s configuration directory:

    sudo nano /etc/apache2/sites-available/your_domain.conf

Add the following to the file, replacing the email address and domain with your own:

/etc/apache2/sites-available/your\_domain.conf

    
    <VirtualHost *:80>
            ServerAdmin your_email
            ServerName your_domain
            ProxyPass / http://localhost:10000/
            ProxyPassReverse / http://localhost:10000/
    </VirtualHost>
    

This configuration tells Apache to pass requests to `http://localhost:10000`, the Webmin server. It also ensures that internal links generated from Webmin will also pass through Apache.

Save the file and exit the editor.

Next, we need to tell Webmin to stop using TLS/SSL, as Apache will provide that for us going forward.

Open the file `/etc/webmin/miniserv.conf` in your editor:

    sudo nano /etc/webmin/miniserv.conf

Find the following line:

/etc/webmin/miniserv.conf

    ...
    ssl=1
    ...

Change the `1` to a `0` This will tell Webmin to stop using SSL.

Next we’ll add our domain to the list of allowed domains, so that Webmin understands that when we access the panel from our domain, it’s not something malicious, like a [Cross-Site Scripting (XSS) attack](https://www.owasp.org/index.php/Cross-site_Scripting_(XSS)).

Open the file `/etc/webmin/config` in your editor:

    sudo nano /etc/webmin/config

Add the following line to the bottom of the file, replacing `your_domain` with your fully-qualified domain name.

/etc/webmin/config

     . . . 
    referers=your_domain

Save the file and exit the editor.

Next, restart Webmin to apply the configuration changes:

    sudo systemctl restart webmin

Then enable Apache’s `proxy_http` module:

    sudo a2enmod proxy_http

You’ll see the following output:

    OutputConsidering dependency proxy for proxy_http:
    Enabling module proxy.
    Enabling module proxy_http.
    To activate the new configuration, you need to run:
      systemctl restart apache2

The output suggests you restart Apache, but first, activate the new Apache virtual host you created:

    sudo a2ensite your_domain

You’ll see the following output indicating your site is enabled:

    OutputEnabling site your_domain.
    To activate the new configuration, you need to run:
      systemctl reload apache2

Now restart Apache completely to activate the `proxy_http` module and the new virtual host:

    sudo systemctl restart apache2

**Note** : Ensure that you allow incoming traffic to your web server on port `80` and port `443` as shown in the prerequisite tutorial [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 18.04](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04). You can do this with the command `sudo ufw allow in "Apache Full"`.

Navigate to `http://your_domain` in your browser, and you will see the Webmin login page appear.

**Warning:** Do NOT log in to Webmin yet, as we haven’t enabled SSL. If you log in now, your credentials will be sent to the server in clear text.

Now let’s configure a certificate so that your connection is encrypted while using Webmin. In order to do this, we’re going to use Let’s Encrypt.

Tell Certbot to generate a TLS/SSL certificate for your domain and configure Apache to redirect traffic to the secure site:

    sudo certbot --apache --email your_email -d your_domain --agree-tos --redirect --noninteractive

You’ll see the following output:

    OutputSaving debug log to /var/log/letsencrypt/letsencrypt.log
    Plugins selected: Authenticator apache, Installer apache
    Obtaining a new certificate
    Performing the following challenges:
    http-01 challenge for your_domain
    Enabled Apache rewrite module
    Waiting for verification...
    Cleaning up challenges
    Created an SSL vhost at /etc/apache2/sites-available/your_domain-le-ssl.conf
    Enabled Apache socache_shmcb module
    Enabled Apache ssl module
    Deploying Certificate to VirtualHost /etc/apache2/sites-available/your_domain-le-ssl.conf
    Enabling available site: /etc/apache2/sites-available/your_domain-le-ssl.conf
    Enabled Apache rewrite module
    Redirecting vhost in /etc/apache2/sites-enabled/your_domain.conf to ssl vhost in /etc/apache2/sites-available/your_domain-le-ssl.conf
    
    -------------------------------------------------------------------------------
    Congratulations! You have successfully enabled https://your_domain
    
    You should test your configuration at:
    https://www.ssllabs.com/ssltest/analyze.html?d=your_domain
    -------------------------------------------------------------------------------

The output indicates that the certificate was installed and Apache is configured to redirect requests from `http://your_domain` to `https://your_domain`.

You’ve now set up a secured, working instance of Webmin. Let’s look at how to use it.

## Step 3 – Using Webmin

Webmin has modules that can control everything from the BIND DNS Server to something as simple as adding users to the system. Let’s look at how to create a new user, and then explore how to update software packages using Webmin.

In order to log in to Webmin, navigate to `http://your_domain` and sign in with either the **root** user or a user with sudo privileges.

### Managing Users and Groups

Let’s manage the users and groups on the server.

First, click the **System** tab, and then click the **Users and Groups** button. From here you can either add a user, manage a user, or add or manage a group.

Let’s create a new user called **deploy** which could be used for hosting web applications. To add a user, click **Create a new user** , which is located at the top of the users table. This displays the **Create User** screen, where you can supply the username, password, groups and other options. Follow these instructions to create the user:

1. Fill in **Username** with `deploy`.
2. Select **Automatic** for **User ID**.
3. Fill in **Real Name** with a descriptive name like `Deployment user`.
4. For **Home Directory** , select **Automatic**.
5. For **Shell** , select **/bin/bash** from the dropdown list.
6. For **Password** , select **Normal Password** and type in a password of your choice.
7. For **Primary Group** , select **New group with same name as user**.
8. For **Secondary Group** , select **sudo** from the **All groups** list, and press the **-\>** button to add the group to the **in groups** list.
9. Press **Create** to create this new user.

When creating a user, you can set options for password expiry, the user’s shell, or whether they are allowed a home directory.

Next, let’s look at how to install updates to our system.

### Updating Packages

Webmin lets you update all of your packages through its user interface. To update all of your packages,, click the **Dashboard** link, and then locate the **Package updates** field. If there are updates available, you’ll see a link that states the number of available updates, as shown in the following figure:

![Webmin shows the number of package updates available](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/webmin1804/RF2fRmB.png)

Click this link, and then press **Update selected packages** to start the update. You may be asked to reboot the server, which you can also do through the Webmin interface.

## Conclusion

You now have a secured, working instance of Webmin and you’ve used the interface to create a user and update packages. Webmin gives you access to many things you’d normally need to access through the console, and it organizes them in an intuitive way. For example, if you have Apache installed, you would find the configuration tab for it under **Servers** , and then **Apache**.

Explore the interface further, or check out the [Official Webmin wiki](http://doxfer.webmin.com/Webmin/Main_Page) to learn more about managing your system with Webmin.
