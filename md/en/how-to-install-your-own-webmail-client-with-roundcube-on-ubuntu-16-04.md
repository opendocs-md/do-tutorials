---
author: Michael Holley
date: 2017-08-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04
---

# How To Install Your Own Webmail Client with Roundcube on Ubuntu 16.04

## Introduction

Nowadays, many people use browser-based email clients like Gmail to access their email. However, if you want to stop seeing ads when you check your email, or if you’ve moved from a public email service to your own domain, you can run your own webmail client (also known as a _mail user agent_ or MUA).

[Roundcube](https://roundcube.net/) is a modern and customizable IMAP-based webmail client written in PHP. It has a large set of features for viewing, organizing, and composing emails, as well as support for contacts and calendar management. With its plugin repository, you can add functionality comparable to the most popular browser-based clients.

To understand where Roundcube fits in your email infrastructure, let’s walk through the components that comprise email behind the scenes:

- A _mail user agent_ (MUA) is the interface a user interacts with to view and send email. 
- A _mail transfer agent_ (MTA) transfers email from the sender to the recipient.
- _Simple Mail Transfer Protocol_ (SMTP) is the protocol MUAs use to send mail to MTAs.
- A _mail delivery agent_ (MDA) receives emails from MTAs and stores them.
- _Internet Message Access Protocol_ (IMAP) is a protocol that MDAs use to deliver mail to MUAs.

When you send an email, your MUA transfers it to your email server’s MTA using SMTP. After several hops, your recipient’s MTA will receive the email and transfer it to their MDA using IMAP. Then your recipient can view the email using their MUA of choice.

**Note** : In other words, Roundcube is an MUA, not an MTA. This means that if you use it, you still need to have a service that manages your email. You can use [your own mail server](how-to-run-your-own-mail-server-with-mail-in-a-box-on-ubuntu-14-04), but if you [don’t want to run your own mail server](why-you-may-not-want-to-run-your-own-mail-server), Roundcube works equally well with public email services like Gmail or hosted email from an ISP.

In this tutorial, you will set up Roundcube backed by Gmail.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [this Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- The LAMP stack installed by following [this LAMP on Ubuntu 16.04 tutorial](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04).
- An IMAP-based email server. For simplicity, this article will use [Gmail](https://www.gmail.com), but any IMAP-based email server will work. Make sure you know the IMAP and SMTP settings for your email server. 

## Step 1 — Installing Dependencies

The first step in setting up Roundcube is installing its dependencies and configuring PHP. Once Roundcube is installed, we can use its helpful dependency check page to verify that everything is set up properly.

These are the Roundcube dependencies that aren’t included out of the box:

- Several PHP libraries (which are the `php-*` packages below, including support for XML and multi-byte strings)
- Support tools (`zip` and `unzip` to handle compressed files)
- Git for version control
- The PHP plugin management system (`composer`)

Update your package index and install all of these dependencies at once.

    sudo apt-get update
    sudo apt-get install php-xml php-mbstring php-intl php-zip php-pear zip unzip git composer

Next, some of the PHP libraries need to be enabled in the server’s `php.ini` file, which is located at `/etc/php/7.0/apache2/php.ini`. Open this file with `nano` or your favorite text editor.

    sudo nano /etc/php/7.0/apache2/php.ini

Many of the changes necessary are just enabling options that have been commented out. In `php.ini` files, commented lines start with a `;` semicolon (instead of the more common `#` hash symbol). To uncomment a line, delete this leading semicolon; to comment a line, add a leading semicolon.

Search for the section that contains many commented lines beginning with `extension=`. Uncomment the lines for the `php_mbstring.dll` and `php_xmlrpc.dll` extensions.

/etc/php/7.0/apache2/php.ini

    . . .
    ;extension=php_interbase.dll
    ;extension=php_ldap.dll
    extension=php_mbstring.dll
    ;extension=php_exif.dll ; Must be after mbstring as it depends on it
    ;extension=php_mysqli.dll
    . . .
    ;extension=php_sqlite3.dll
    ;extension=php_tidy.dll
    extension=php_xmlrpc.dll
    ;extension=php_xsl.dll
      . . .

Then add `extension=dom.so` to the bottom of the extension block.

/etc/php/7.0/apache2/php.ini

    . . .
    extension=php_xmlrpc.dll
    ;extension=php_xsl.dll
    extension=dom.so
    
    . . .

There are a few other modifications we need to make in this file.

First, search for the `date.timezone` setting. Uncomment the line and add your timezone in quotation marks. To see how to format your timezone in the `php.ini` file, you can reference [PHP’s timezone page](http://www.php.net/manual/en/timezones.php). For example, if you live in Eastern Standard Time, your file could look like this:

/etc/php/7.0/apache2/php.ini

    . . .
    [Date]
    ; Defines the default timezone used by the date functions
    ; http://php.net/date.timezone
    date.timezone = "America/New_York"
    . . .

Next, search for the `upload_max_filesize` setting. This setting mainly affects uploading attachments. By default, it’s set to 2MB. You can set it to any amount you want, but most email servers limit the total attachment size to 10MB. We’ll set it to 12MB here in the event that multiple users are adding attachments at the same time.

/etc/php/7.0/apache2/php.ini

    . . .
    ; Maximum allowed size for uploaded files.
    ; http://php.net/upload-max-filesize
    upload_max_filesize = 12M
    . . .

Next, search for `post_max_size`. Whereas the `upload_max_filesize` setting applied only to attachments, this setting applies to the size of the whole email (including attachments). To prevent deadlocks, we’ll set this one to a slightly higher value.

/etc/php/7.0/apache2/php.ini

    . . .
    ; Maximum size of POST data that PHP will accept.
    ; Its value may be 0 to disable the limit. It is ignored if POST data reading
    ; is disabled through enable_post_data_reading.
    ; http://php.net/post-max-size
    post_max_size = 18M
    . . .

Finally, search for `mbstring.func_overload`, uncomment it, and verify its value is set to 0. This enables support for multi-byte string functions.

/etc/php/7.0/apache2/php.ini

    . . .
    mbstring.func_overload = 0
    . . .

Save and close the file.

Your server is now set up with a LAMP stack, Roundcube’s dependencies, and the necessary PHP configuration. The next step is downloading the Roundcube software, installing it, and configuring it.

## Step 2 — Downloading Roundcube

As with many projects in the Linux world, there are two ways to install Roundcube: from a package or from source. There is a PPA for Roundcube, but because the project is under active development, the PPA is often out of date. (At time of writing, the PPA is on version 1.2.3 but the project itself is at 1.3). To make sure we’re getting the most recent version, we’ll install from source.

Navigate to the [Roundcube download page](https://roundcube.net/download/). Look under the **Stable version** section and locate the **Complete** package. Right click the **Download** button and select **Copy Link Address**.

Use this address with `wget` to download the Roundcube tarball on the server.

    wget https://github.com/roundcube/roundcubemail/releases/download/1.3.0/roundcubemail-1.3.0-complete.tar.gz

Decompress the Roundcube archive.

    tar -xvzf roundcubemail-1.3.0-complete.tar.gz

Arguments for tar can be a bit [intimidating](https://xkcd.com/1168/), so here’s what each flag does:

- The `x` flag stands for extract.
- The `v` flag stands for verbose, which tells `tar` to print the path and name of every file extracted.
- The `z` flag tells `tar` to not only remove the tar wrapper but to decompress the archive using gzip. We know the file is compressed with gzip because the file extension has `.gz` on the end.
- The `f` flag stands for file. This must be the last flag because `tar` uses whatever immediately follows it as the file to be extracted.

Next, move the decompressed directory to `/var/www` and rename it to `roundcube`. Make sure to omit the trailing `/` in the directory names because we want to move and rename the whole directory, not the contents in the directory.

    sudo mv roundcubemail-1.3.0 /var/www/roundcube

Finally, change the permissions to allow Apache to create and edit the files (like configuration files and logs). Specifically, change the owner and group to **www-data** , and change the permissions to read and write for the owner and group, but read only for everyone else.

    sudo chown -R www-data:www-data /var/www/roundcube/
    sudo chmod 775 /var/www/roundcube/temp/ /var/www/roundcube/logs/

We’ve downloaded Roundcube’s code and updated its location and permissions, but it’s only partially installed at this point. To finish the installation, we need to connect Roundcube to our database via Roundcube’s GUI. Before we can do that, we need to tell Apache where Roundcube is so it can load the website.

## Step 3 — Configuring Apache

The file we need to edit to configure Apache is a [virtual host file](how-to-set-up-apache-virtual-hosts-on-ubuntu-16-04). Virtual hosts are a feature that allow Apache to host multiple sites on the same server. Even if this is the only site Apache is hosting, it’s simpler and cleaner to use a virtual host configuration file than edit the main Apache configuration.

Each `.conf` file located under `/etc/apache2/sites-available/` represent a different site. We’ll create a virtual host file here for Roundcube, then tell Apache about it so it can make it available via a browser.

First, copy the default configuration file to use as a starting point for the new file.

    sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/roundcube.conf

Open the file with your text editor.

    sudo nano /etc/apache2/sites-available/roundcube.conf

We’ll need to make a number of changes to this file. We’ll walk through each of them first, then provide the whole file to copy and paste.

In the existing `VirtualHost` block, you’ll modify the following directives:

- The `ServerName` tells Apache which domain to listen to. This should be your server IP address or domain name, if you’re using one.
- `DocumentRoot` specifies where to send traffic when it comes in. In our case, we should send it to Roundcube at `/var/www/roundcube`.
- `ServerAdmin` lets you specify an contact email address for any issues with Apache. We aren’t configuring Apache to do that in this tutorial, but it’s best practice to include it anyway.
- The two logging lines, `ErrorLog` and `CustomLog`, define where to save successful connection logs and error logs for this site. We need to give the error logs specific names so if there is an issue the logs specific to this site are easily found.

Then, you’ll add a new `Directory` block which tells Apache what to do with the Roundcube directory. The first word in each line of a `Directory` block is the configuration name followed by the actual configuration options.

- `Options -Indexes` tells Apache to display a warning if it can’t find an `index.html` or `index.php` file. By default, it will list the contents of the directory instead.
- `AllowOverride All` tells Apache that if a local `.htaccess` file is found, any options in that file override the global settings in this file.
- `Order allow,deny` tells Apache first to allow matching clients access to the site, and then to deny any that don’t match.
- `allow from all` is a followup to the `Order` line. It defines what type of client is allowed, which is any in our case.

Here’s what the file will look like once you’ve made these changes. For brevity, the comments have been removed.

/etc/apache2/sites-available/roundcube.conf

    <VirtualHost *:80>
      ServerName your_server_ip_or_domain
      DocumentRoot /var/www/roundcube
      ServerAdmin sammy@example.com
    
      ErrorLog ${APACHE_LOG_DIR}/roundcube-error.log
      CustomLog ${APACHE_LOG_DIR}/roundcube-access.log combined
    
      <Directory /var/www/roundcube>
          Options -Indexes
          AllowOverride All
          Order allow,deny
          allow from all
      </Directory>
    </VirtualHost>

Save and close the file.

Next, tell Apache to stop hosting the default site.

    sudo a2dissite 000-default

Then tell Apache to start hosting the Roundcube site instead. Make sure not to include the `.conf` when enabling the site; `a2ensite` wants the file name of the configuration without the extension.

    sudo a2ensite roundcube

Enable the `mod_rewrite` Apache module, which Roundcube requires.

    sudo a2enmod rewrite

Finally, restart Apache, which will make the Roundcube installation accessible.

    sudo apache2ctl restart

The webmail client is almost ready to use. The last step of the installation process is to configure the database so Roundcube can store its app-specific data.

## Step 4 — Configuring MySQL

At this point, if you open a web browser and try accessing your server (by IP address or domain name, if you’re using one), you’ll see a configuration error page. This is because Roundcube is checking for a file generated during configuration setup, but we haven’t gone through the configuration setup yet. Before we can go through that setup, we need to prepare the database.

Connect to the MySQL interactive shell. This command tells MySQL to authenticate as the user (`-u`) **root** and that we’ll specify a password (`-p`).

    mysql -u root -p

After entering the command you’ll be prompted for the root password you created when you installed MySQL.

Now that we’re in the MySQL shell, we’ll create a database and a database user, and then give that user permissions to execute commands on that new database.

Create the database first. This command creates a database called `roundcubemail` and then provides database options, like the character set to use (`utf8`).

    CREATE DATABASE roundcubemail /*!40101 CHARACTER SET utf8 COLLATE utf8_general_ci */;

Unlike many other authentication systems, MySQL defines a user by a name and where they’ll connect from. This command creates a user called **roundcube** and defines that user to connect from `localhost`. For applications accessing a database, defining where the user will make the request from helps tighten security.

Create this user, making sure to change the password to something secure.

    CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'password';

Give the **roundcube** user all permissions on the `roundcubemail` database and all of its tables.

    GRANT ALL PRIVILEGES ON roundcubemail.* to 'roundcube'@'localhost';

Then save your changes and quit the MySQL interactive shell.

    FLUSH PRIVILEGES;
    EXIT;

We have created a blank database, `roundcubemail`, and a user, `roundcube@localhost`, and then gave that user full permissions to the database. Now we need to set up the structure of the database so Roundcube knows where to save its information. The Roundcube install provides a file that’ll configure the database for us, so we don’t have to do it by hand.

The following command tells MySQL to use our newly created user to read in a file `/var/www/roundcube/SQL/mysql.initial.sql` and apply the configuration to the database `roundcubemail`.

    mysql -u roundcube -p roundcubemail < /var/www/roundcube/SQL/mysql.initial.sql

You’ll be prompted to enter the **roundcube** user’s password.

Setting up the database in this way prepares it for Roundcube’s use and also allows us to verify that we have the right permissions. If all was successful, you’ll receive no feedback and be back at the command prompt. Then we’re ready to tell Roundcube our email settings and finalize the installation.

## Step 5 — Configuring Roundcube

As mentioned before, if you try to access your Roundcube installation now, you’ll get an error page. To finish the installation, we need to visit `http://your_server_ip_or_domain/installer` instead.

If everything’s set up properly, there will be a green **OK** to the right of every line item, except for a few: the optional LDAP setting and every database line except MySQL. If there is a **NOT AVAILABLE** next to any other line than those just mentioned, you’ll need to install those dependencies. Roundcube helpfully provides a link for any missing dependency so you can figure out what to install.

Once everything is set up correctly, scroll down to the bottom of the page and click the **NEXT** button.

The form on the next page, which is broken into seven sections, walks through generating the Roundcube configuration file. Below are the portions of the form we need to fill out, divided by section. If a line from the form is excluded in the sections below, you can skip that line and leave it with the default settings.

### General configuration

The **General configuration** section provides a few cosmetic options for customization and some general settings. There’s only one option you should change here:

- Make sure **ip\_check** is ticked for greater security. It checks the client’s IP in session authorization.

There are a few more optional changes you can make, too:

- You can change the **product\_name**. This can be anything you wish and all references to “Roundcube” in text will be replaced with this name instead.
- The **support\_url** is a URL where users can get support for their Roundcube installation. It isn’t strictly needed, but it can be nice if Roundcube is being provided for a group of people who may need assistance. If you don’t have a dedicated help desk site, you can use an email address, like `mailto:sammy@example.com`.
- You can replace the Roundcube logo with **skin\_logo** , which takes a URL to a PNG file (178px by 47px). If you are going to enable HTTPS (highly recommended, and covered later in this tutorial), then make sure the image URL is an HTTPS URL.

All other options can be left at their default values.

### Logging & Debugging

Leave everything in this section at its default settings.

### Database setup

Roundcube uses MySQL to store the information for running the web client (not your emails). In this section, you need to tell Roundcube how to access the database that you set up in Step 4. You’ll need the database user, user password, and database name you created previously.

- It should be already set, but select `MySQL` from the **Database type** pull down menu.
- Enter `localhost` for the **Database server**.
- Enter the database name, `roundcubemail`, in the **Database name** field.
- Enter the database user, `roundcube`, in the **Database user name** field.
- For the **Database password** field, enter the password you defined when creating the database in Step 4.
- The last option, **db\_prefix** , isn’t required unless you are with using a shared database with other apps. If so then enter something like, `rc_`.

### IMAP Settings

For this section, you’ll need the IMAP and SMTP settings for your email server. Because this tutorial uses Gmail as an example, the Gmail settings are included below, but if you have your own email provider, they should provide you with the details you need. Most email providers support connections with or without encryption. Make sure to avoid using non-secure connections by using the SSL IMAP/SMTP URLs and ports.

- In the **default\_host** field enter the IMAP server URL. When using SSL connections, prefix the URL with `ssl://` instead of `https://`. For Gmail, enter `ssl://imap.gmail.com`.

1. Next is setting the **default\_port** , which is the IMAP server port. SSL and non-SSL connections will use different ports, so make sure to use the SSL port. Gmail’s SSL IMAP port uses `993`.
2. The field **username\_domain** is a convenience option for email providers that use a full email address as the username. This field is optional. Entering a domain — not the full email — will allow you to login to Roundcube with just your name, before the `@`, instead of the whole email. For example, entering `gmail.com` in the field will allow `user@gmail.com` to log into Roundcube with `user`.
3. Make sure the **auto\_create\_user** check box is selected. If it’s unchecked, Roundcube won’t create a user in its own database, which will prevent you from logging in.
4. For now, leave all of the **\*\_mbox** fields, like **sent\_mbox** , with their default values. This can be updated later in the Roundcube UI, and most email clients use these folder names anyway.

### SMTP Settings

The SMTP server is the part of email that sends emails. Much like the IMAP server section, we’ll use the SSL URL and port, and Gmail for reference.

1. Enter the SMTP server address in the **smtp\_server** field. Gmail’s SMTP server is `ssl://smtp.gmail.com`.
2. Enter the SSL SMTP server port in the **smtp\_port** field. The SSL port for Gmail is `465`.
3. Because SMTP and IMAP are two separate services, they both need a username and password. Roundcube gives us the option to use the IMAP username and password set above so we don’t have to set it again here. This means you need to leave the fields under **smtp\_user/smtp\_pass** blank and check the box next to **Use the current IMAP username and password for SMTP authentication**.
4. Finally make sure that the checkbox for **smtp\_log** is checked.

### Display settings & user prefs

We’ll leave all of these options with their default values. If you want to customize your Roundcube installation to be in a different language than the operating system it’s running on, set it manually by clicking the **RFC1766** link on the configuration page and updating the **language** field.

### Plugins

Roundcube’s plugin support is what really makes this webmail client stand out. Below are a good set of defaults you can install. All plugins are optional, i.e,. they aren’t necessary to use Roundcube, but the list below is a good set to make the experience either easier or more secure.

Take a look at the descriptions for each plugin and install whichever you like. If you don’t select a plugin here, you can always install it later. This just pre-configures Roundcube with these plugins.

- **archive** : Gives you an Archive button, similar to how Gmail works.
- **emoticons** : Simply makes it easier to use emoticons in emails.
- **enigma** : Allows GPG email encryption. We’ll go into detail on how to configure this in [our Roundcube security tutorial](how-to-secure-roundcube-on-ubuntu-16-04).
- **filesystem\_attachments** : A core plugin to allow saving attachments to the Roundcube server temporarily when composing or saving a draft email.
- **hide\_blockquote** : Hides the quoted portion of replied emails to keep the UI cleaner.
- **identity\_select** : If you have multiple email addresses (identities), it allows you to easily select them while composing an email.
- **markasjunk** : Allows marking an email as spam and have it moved to your Spam folder.
- **newmail\_notifier** : Uses your browser notification system to alert you to new emails.

At last, that’s all of the configuration. Press the **UPDATE CONFIG** button at the bottom of the page to save your settings. Let’s test that everything works next.

## Step 6 — Testing the Roundcube Configuration

After you update the configuration, the page will refresh and you’ll see a yellow info box at the top of the page which says **The config file was saved successfully into `RCMAIL_CONFIG_DIR` directory of your Roundcube installation.**

From here, click on the **CONTINUE** button to test your configuration. Like the dependency check page, if there are no errors, you’ll see a green **OK** marker on every line. If not, go back and double check what you entered.

To test the rest of the configuration, put in your IMAP and SMTP username and password in the **Test SMTP config** and **Test IMAP config** sections, then click **Send test email** and **Check login** , respectively. If a test is successful, the page will reload and you’ll see the green ‘OK’ under the section you tested.

**Note:** If you are using Gmail and you have 2-step authentication enabled, you’ll need to [generate an app-specific password](https://support.google.com/accounts/answer/185833?hl=en) because Roundcube doesn’t know how to prompt for your 2-step auth token.

Once you’ve checked both SMTP and IMAP connections and both are green, then it’s time to jump back into your SSH session and remove the installer directory. This will prevent someone else to generate a new config and override the correct settings.

    sudo rm -rf /var/www/roundcube/installer/

Now you can visit your Roundcube instance using your server’s IP or your domain name, log in, and check your email.

## Conclusion

With Roundcube, you can have the feature set and appearance of a native desktop client with the flexibility of a webmail client. You have a fully functional installation now, but there are some additional steps you should take to make sure you’re fully secure (like adding HTTPS support and using GPG encryption for your email). You can do this by following [How to Secure Roundcube on Ubuntu 16.04](how-to-secure-roundcube-on-ubuntu-16-04).

In addition, you can install new themes to enhance the look of your client and plugins to add new functionality. Unlike [plugins](https://plugins.roundcube.net/), there isn’t a central site to find themes, but you can find [Roundcube Skins](http://roundcubeskins.net) or [Roundcube forums](http://www.roundcubeforum.net/index.php?board=28.0) as places to find some.
