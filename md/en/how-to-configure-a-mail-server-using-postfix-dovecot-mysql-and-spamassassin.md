---
author: Nestor de Haro
date: 2014-04-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-a-mail-server-using-postfix-dovecot-mysql-and-spamassassin
---

# How To Configure a Mail Server Using Postfix, Dovecot, MySQL, and SpamAssassin

## Introduction

In this tutorial, we are going to configure a mail server using Postfix, Dovecot, MySQL and SpamAssassin on Ubuntu 12.04.

Following this tutorial you'll be able to add virtual domains, users, and aliases. Moreover, your virtual server will be secure from spam hub.

### Prerequisites

Before setting up your mail server, it's necessary your VPS has the following:

\* Domain is forwarding to your server ([setup domain](https://www.digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean))  
 \* MySQL installed and configured ([setup mysql](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu))  
\* User with root privileges ([setup new users](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04)- omit step 5)  
 \*Configure and identify your FQDN ([setup FQDN](https://github.com/DigitalOcean-User-Projects/Articles-and-Tutorials/blob/master/set_hostname_fqdn_on_ubuntu_centos.md#setting-the-fully-qualified-domain-name-fqdn))

**Optional** : SSL certificate ([setup free signed ssl certificate](https://www.digitalocean.com/community/articles/how-to-set-up-apache-with-a-free-signed-ssl-certificate-on-a-vps))

**Optional** ( Log in as root user )

Installing packages as the root user is useful because you have all privileges.

    sudo -i

Introduce your user's password. Once it's successful, you will see that `$` symbol changes to `#`.

## Step 1: Install Packages

    apt-get install postfix postfix-mysql dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql

When Postfix configuration is prompted choose Internet Site:

    
    

Postfix configuration will ask about System mail name – you could use your FDQN or main domain.

    
    

## Step 2: Create a MySQL Database, Virtual Domains, Users and Aliases

After the installation finishes, we are going to create a MySQL database to configure three different tables: one for domains, one for users and the last one for aliases.

We are going to name the database `servermail`, but you can use whatever name you want.

Create the servermail database:

    mysqladmin -p create servermail

Log in as MySQL root user

    mysql -u root -p

Enter your MySQL root's password; if it's successful you will see:

    mysql >

First we need to create a new user, specific for mail authentication, and we are going to give SELECT permission.

    mysql > GRANT SELECT ON servermail.* TO 'usermail'@'127.0.0.1' IDENTIFIED BY 'mailpassword';

After that, we need to reload MySQL privileges to ensure it applies those permissions successfully:

    mysql > FLUSH PRIVILEGES;

Finally we need to use the database for creating tables and introduce our data:

    mysql> USE servermail;

We are going to create a table for the specific domains recognized as authorized domains.

    
    CREATE TABLE `virtual_domains` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

We are going to create a table to introduce the users. Here you will add the email address and passwords. It is necessary to associate each user with a domain.

    CREATE TABLE `virtual_users` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `domain_id` INT NOT NULL,
    `password` VARCHAR(106) NOT NULL,
    `email` VARCHAR(120) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `email` (`email`),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

Finally we are going to create a virtual aliases table to specify all the emails that you are going to forward to the other email.

    
    CREATE TABLE `virtual_aliases` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `domain_id` INT NOT NULL,
    `source` varchar(100) NOT NULL,
    `destination` varchar(100) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

We have created the three tables successfully. Now we are going to introduce the data.

### Virtual Domains

Here we are going to introduce your domains inside the virtual\_domains table. You can add all the domains you want, but in this tutorial we are going to introduce just the primary domain (example.com) and your FQDN (hostname.example.com).

    
    INSERT INTO `servermail`.`virtual_domains`
    (`id` ,`name`)
    VALUES
    ('1', 'example.com'),
    ('2', 'hostname.example.com');

### Virtual Emails

We are going to introduce the email address and passwords associated for each domain. Make sure you change all the info with your specific information.

    
    INSERT INTO `servermail`.`virtual_users`
    (`id`, `domain_id`, `password` , `email`)
    VALUES
    ('1', '1', ENCRYPT('firstpassword', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 'email1@example.com'),
    ('2', '1', ENCRYPT('secondpassword', CONCAT('$6$', SUBSTRING(SHA(RAND()), -16))), 'email2@example.com');

### Virtual Aliases

We are going to introduce the email address (source) that we are going to forward to the other email address (destination).

    
    INSERT INTO `servermail`.`virtual_aliases`
    (`id`, `domain_id`, `source`, `destination`)
    VALUES
    ('1', '1', 'alias@example.com', 'email1@example.com');

Exit MySQL

     mysql > exit

## Step 3: Configure Postfix

We are going to configure Postfix to handle the SMTP connections and send the messages for each user introduced in the MySQL Database.

First we need to create a copy of the default file, in case you want to revert to the default configuration.

    cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

Open the main.cf file to modify it:

    nano /etc/postfix/main.cf

First we need to comment the TLS Parameters and append other parameters. In this tutorial, we are using the Free SSL certificates and the paths that are suggested in the tutorial ([link](https://www.digitalocean.com/community/articles/how-to-set-up-apache-with-a-free-signed-ssl-certificate-on-a-vps)), but you could modify depending your personal configurations.

    
    # TLS parameters
    #smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
    #smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
    #smtpd_use_tls=yes
    #smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
    #smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache 
    smtpd_tls_cert_file=/etc/ssl/certs/dovecot.pem
    smtpd_tls_key_file=/etc/ssl/private/dovecot.pem
    smtpd_use_tls=yes
    smtpd_tls_auth_only = yes

Then we are going to append the following parameters below the TLS settings that we have changed in the previous step:

    
    smtpd_sasl_type = dovecot
    smtpd_sasl_path = private/auth
    smtpd_sasl_auth_enable = yes
    smtpd_recipient_restrictions =
    permit_sasl_authenticated,
    permit_mynetworks,
    reject_unauth_destination

We need to comment the `mydestination` default settings and replace it with `localhost`. This change allows your VPS to use the virtual domains inside the MySQL table.

    
    #mydestination = example.com, hostname.example.com, localhost.example.com, localhost
    mydestination = localhost 

Verify that myhostname parameter is set with your FQDN.

    
    myhostname = hostname.example.com

Append the following line for local mail delivery to all virtual domains listed inside the MySQL table.

    virtual_transport = lmtp:unix:private/dovecot-lmtp

Finally, we need to add these three parameters to tell Postfix to configure the virtual domains, users and aliases.

    
    virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
    virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
    virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf

Note: Compare these changes with this file to detect mistakes or errors:

    https://www.dropbox.com/s/x9fpm9v1dr86gkw/etc-postfix-main.cf.txt

We are going to create the final three files that we append in the main.cf file to tell Postfix how to connect with MySQL.

First we need to create the `mysql-virtual-mailbox-domains.cf` file. It's necessary to change the values depending your personal configuration.

    
    nano /etc/postfix/mysql-virtual-mailbox-domains.cf
    		
    user = usermail
    password = mailpassword
    hosts = 127.0.0.1
    dbname = servermail
    query = SELECT 1 FROM virtual_domains WHERE name='%s'

Then we need to restart Postfix.

    
    service postfix restart

We need to ensure that Postfix finds your domain, so we need to test it with the following command. If it is successful, it should returns 1:

    
    postmap -q example.com mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf

Then we need to create the mysql-virtual-mailbox-maps.cf file.

    
    nano /etc/postfix/mysql-virtual-mailbox-maps.cf 
    		
    user = usermail
    password = mailpassword
    hosts = 127.0.0.1
    dbname = servermail
    query = SELECT 1 FROM virtual_users WHERE email='%s'

We need to restart Postfix again.

    service postfix restart

At this moment we are going to ensure Postfix finds your first email address with the following command. It should return 1 if it's successful:

    postmap -q email1@example.com mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf

Finally, we are going to create the last file to configure the connection between Postfix and MySQL.

    
    nano /etc/postfix/mysql-virtual-alias-maps.cf
    		
    user = usermail
    password = mailpassword
    hosts = 127.0.0.1
    dbname = servermail
    query = SELECT destination FROM virtual_aliases WHERE source='%s'

Restart Postfix

    service postfix restart
    

We need to verify Postfix can find your aliases. Enter the following command and it should return the mail that's forwarded to the alias:

    postmap -q alias@example.com mysql:/etc/postfix/mysql-virtual-alias-maps.cf

If you want to enable port 587 to connect securely with email clients, it is necessary to modify the /etc/postfix/master.cf file

    
    nano /etc/postfix/master.cf

We need to uncomment these lines and append other parameters:

    
    submission inet n - - - - smtpd
    -o syslog_name=postfix/submission
    -o smtpd_tls_security_level=encrypt
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_client_restrictions=permit_sasl_authenticated,reject

In some cases, we need to restart Postfix to ensure port 587 is open.

    service postfix restart

Note: You can use this tool to scan your domain ports and verify that port 25 and 587 are open ([http://mxtoolbox.com/SuperTool.aspx](http://mxtoolbox.com/SuperTool.aspx))

## Step 4: Configure Dovecot

We are going to copy the 7 files we're going to modify, so that you could revert it to default if you needed to. Enter the following commands one by one:

    
    cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
    cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
    cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
    cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
    cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
    cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig

Edit configuration file from Dovecot.

    nano /etc/dovecot/dovecot.conf

Verify this option is uncommented.

    !include conf.d/*.conf

We are going to enable protocols (add pop3 if you want to) below the `!include_try /usr/share/dovecot/protocols.d/*.protocol line`.

    
    !include_try /usr/share/dovecot/protocols.d/*.protocol
    protocols = imap lmtp

Note: Compare these changes with this file to detect mistakes or errors:

    
    https://www.dropbox.com/s/wmbe3bwy0vcficj/etc-dovecot-dovecot.conf.txt

Then we are going to edit the mail configuration file:

    nano /etc/dovecot/conf.d/10-mail.conf

Find the `mail_location` line, uncomment it, and put the following parameter:

    mail_location = maildir:/var/mail/vhosts/%d/%n

Find the `mail_privileged_group` line, uncomment it, and add the mail parameter like so:

    mail_privileged_group = mail

Note: Compare these changes with this file to detect mistakes or errors:

    
    https://www.dropbox.com/s/hnfeieuy77m5b0a/etc.dovecot.conf.d-10-mail.conf.txt

### Verify permissions

Enter this command:

    
    ls -ld /var/mail

Ensure permissions are like this:

    drwxrwsr-x 3 root vmail 4096 Jan 24 21:23 /var/mail

We are going to create a folder for each domain that we register in the MySQL table:

    mkdir -p /var/mail/vhosts/example.com

Create a vmail user and group with an id of 5000

    
    groupadd -g 5000 vmail 
    useradd -g vmail -u 5000 vmail -d /var/mail

We need to change the owner of the `/var/mail` folder to the vmail user.

    chown -R vmail:vmail /var/mail

Then we need to edit the `/etc/dovecot/conf.d/10-auth.conf` file:

    nano /etc/dovecot/conf.d/10-auth.conf

Uncomment plain text authentication and add this line:

    disable_plaintext_auth = yes

Modify `auth_mechanisms` parameter:

    auth_mechanisms = plain login

Comment this line:

    #!include auth-system.conf.ext

Enable MySQL authorization by uncommenting this line:

    !include auth-sql.conf.ext

Note: Compare these changes with this file to detect mistakes or errors:

    https://www.dropbox.com/s/4h472nqrj700pqk/etc.dovecot.conf.d.10-auth.conf.txt

We need to create the /etc/dovecot/dovecot-sql.conf.ext file with your information for authentication:

    nano /etc/dovecot/conf.d/auth-sql.conf.ext

Enter the following code in the file:

    
    passdb {
      driver = sql
      args = /etc/dovecot/dovecot-sql.conf.ext
    }
    userdb {
      driver = static
      args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
    } 

We need to modify the `/etc/dovecot/dovecot-sql.conf.ext` file with our custom MySQL information:

    nano /etc/dovecot/dovecot-sql.conf.ext

Uncomment the driver parameter and set mysql as parameter:

    driver = mysql

Uncomment the connect line and introduce your MySQL specific information:

    connect = host=127.0.0.1 dbname=servermail user=usermail password=mailpassword

Uncomment the `default_pass_scheme` line and change it to `SHA-512`.

    default_pass_scheme = SHA512-CRYPT

Uncomment the `password_query` line and add this information:

    password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';

Note: Compare these changes with this file to detect mistakes or errors:

    https://www.dropbox.com/s/48a5r0mtgdz25cz/etc.dovecot.dovecot-sql.conf.ext.txt

Change the owner and the group of the dovecot folder to vmail user:

    
    chown -R vmail:dovecot /etc/dovecot
    chmod -R o-rwx /etc/dovecot 

Open and modify the `/etc/dovecot/conf.d/10-master.conf` file (be careful because different parameters will be changed).

    
    nano /etc/dovecot/conf.d/10-master.conf
    
    ##Uncomment inet_listener_imap and modify to port 0
    service imap-login {
      inet_listener imap {
        port = 0
    }
    
    #Create LMTP socket and this configurations
    service lmtp {
       unix_listener /var/spool/postfix/private/dovecot-lmtp {
    	   mode = 0600
    	   user = postfix
    	   group = postfix
       }
      #inet_listener lmtp {
        # Avoid making LMTP visible for the entire internet
        #address =
        #port =
      #}
    } 

Modify `unix_listener` parameter to `service_auth` like this:

    
    service auth {
    
      unix_listener /var/spool/postfix/private/auth {
      mode = 0666
      user = postfix
      group = postfix
      }
    
      unix_listener auth-userdb {
      mode = 0600
      user = vmail
      #group =
      }
    
      #unix_listener /var/spool/postfix/private/auth {
      # mode = 0666
      #}
    
      user = dovecot
    }

Modify `service auth-worker` like this:

    
    service auth-worker {
      # Auth worker process is run as root by default, so that it can access
      # /etc/shadow. If this isn't necessary, the user should be changed to
      # $default_internal_user.
      user = vmail
    }

Note: Compare these changes with this file to detect mistakes or errors:

    https://www.dropbox.com/s/g0vnt233obh6v2h/etc.dovecot.conf.d.10-master.conf.txt

Finally, we are going to modify the SSL configuration file from Dovecot (skip this step if you are going to use default configuration).

    # nano /etc/dovecot/conf.d/10-ssl.conf

Change the ssl parameter to required:

    ssl = required

And modify the path for `ssl_cert` and `ssl_key`:

    ssl_cert = </etc/ssl/certs/dovecot.pem
     ssl\_key = \</etc/ssl/private/dovecot.pem

Restart Dovecot

    service dovecot restart

You should check that port 993 is open and working (in case you enable pop3; you should check also port 995).

    telnet example.com 993

**Congratulations.** You have successfully configured your mail server and you may test your account using an email client:

     - Username: email1@example.com - Password: email1's password - IMAP: example.com - SMTP: example.com 

Note: use port 993 for secure IMAP and port 587 or 25 for SMTP.

## Step 5: Configure SpamAssassin

First we need to install SpamAssassin.

    apt-get install spamassassin spamc

Then we need to create a user for SpamAssassin.

    adduser spamd --disabled-login

To successfully configure SpamAssassin, it's necessary to open and modify the configuration settings.

    nano /etc/default/spamassassin

We need to change the `ENABLED` parameter to enable SpamAssassin daemon.

    ENABLED=1

We need to configure the home and options parameters.

    
    SPAMD_HOME="/home/spamd/"
    OPTIONS="--create-prefs --max-children 5 --username spamd --helper-home-dir ${SPAMD_HOME} -s ${SPAMD_HOME}spamd.log" 

Then we need to specify the `PID_File` parameter like this:

    PIDFILE="${SPAMD_HOME}spamd.pid"

Finally, we need to specify that SpamAssassin's rules will be updated automatically.

    CRON=1

Note: Compare these changes with this file to detect mistakes or errors:

    https://www.dropbox.com/s/ndvpgc2jipdd4bk/etc.default.spamassassin.txt

We need to open `/etc/spamassassin/local.cf` to set up the anti-spam rules.

    nano /etc/spamassassin/local.cf

SpamAssassin will score each mail and if it determines this email is greater than 5.0 on its spam check, then it automatically will be considered spam. You could use the following parameters to configure the anti-spam rules:

    
    rewrite_header Subject *****SPAM _SCORE_*****
    report_safe 0
    required_score 5.0
    use_bayes 1
    use_bayes_rules 1
    bayes_auto_learn 1
    skip_rbl_checks 0
    use_razor2 0
    use_dcc 0
    use_pyzor 0

We need to change the Postfix `/etc/postfix/master.cf` file to tell it that each email will be checked with SpamAssassin.

    nano /etc/postfix/master.cf

Then we need to find the following line and add the spamassassin filter:

    
    smtp inet n - - - - smtpd
    -o content_filter=spamassassin

Finally we need to append the following parameters:

    
    spamassassin unix - n n - - pipe
    user=spamd argv=/usr/bin/spamc -f -e  
    /usr/sbin/sendmail -oi -f ${sender} ${recipient}

It is necessary to start SpamAssassin and restart Postfix to begin verifying spam from emails.

    
    service spamassassin start
    service postfix restart

**Congratulations!** You have successfully set up your mail server with Postfix and Dovecot with MySQL authentication and spam filtering with SpamAssassin!

Submitted by: [Nestor de Haro](https://www.mirefaccion.com.mx)
