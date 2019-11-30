---
author: Nik van der Ploeg
date: 2013-07-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-apache-with-a-free-signed-ssl-certificate-on-a-vps
---

# How To Set Up Apache with a Free Signed SSL Certificate on a VPS

 **Note:** You may want to consider using Let's Encrypt instead of the StartSSL.com process below. Let's Encrypt is a new certificate authority that provides a **free** and **easy** way of creating SSL/TLS certificates that are trusted in most web browsers. Check out the tutorial to get started: [How To Secure Apache with Let's Encrypt on Ubuntu 14.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04)  

### Prerequisites

Before we get started, here are the web tools you need for this tutorial:

1. [Google Chrome](https://www.google.com/intl/en/chrome/browser) browser
2. Apache installed on your VPS (cloud server)
3. A domain name you own
4. Access to an email address at that domain, either: 
  1. postmaster@duable.co
  2. hostmaster@duable.co
  3. webmaster@duable.co

[StartSSL.com](http://www.startssl.com) offers completely free **verified** (your users won't have to see those scary red screens saying "this site isn't trusted" anymore) SSL certificates that you can use on your website. This is a great deal as most companies charge $50-$60 for similar services. The free version is a bit tricky to set up, but it's well worth it.

To get started, browse to [StartSSL.com](http://www.startssl.com) and using the toolbar on the left, navigate to StartSSL Products and then to StartSSL™ Free. Choose the link for [Control Panel](https://www.startssl.com/?app=12) from the top of the page.

**Make sure you are using Google Chrome**

1. Choose the **Express Signup.** option
2. Enter your personal information, and click continue.
3. You'll get an email with a verification code inside it shortly. Copy and paste that email into the form on StartSSL's page.
4. They will review your request for a certificate and then send you an email with the new info. This process might take as long as 6 hours though, so be patient.
5. Once the email comes, use the link provided and the new authentication code (at the bottom of the email) to continue to the next step.
6. They will ask you to Generate a private key and you will be provided with the choice of "High" or "Medium" grade. Go ahead and choose "High".
7. Once your key is ready, click Install.
8. Chrome will show a popdown that says that the certificate has been succesfully installed to Chrome.

This means your browser is now authenticated with your new certificate and you can log into the StartSSL authentication areas using your new certificate. Now, we need to get a properly formatted certificate set up for use on your VPS. Click on the [Control panel](https://www.startssl.com/?app=12) link again, and choose the Authenticate option. Chrome will show a popup asking if you want to authenticate and will show the certificate you just installed. Go ahead and authenticate with that certificate to enter the control panel.

You will need to validate your domain name to prove that you own the domain you are setting up a certificate for. Click over to the Validations Wizard in the [Control panel](https://www.startssl.com/?app=12) and set Type to Domain Name Validation. You'll be prompted to choose from an email at your domain, something like postmaster@yourdomain.com.

 ![StartSSL](https://assets.digitalocean.com/tutorial_images/YRjxABj.png?1)

Check the email inbox for the email address you selected. You will get yet another verification email at that address, so like before, copy and paste the verification code into the StartSSL website.

Next, go to the Certificates Wizard tab and choose to create a Web Server SSL/TLS Certificate.

 ![Start SSL](https://assets.digitalocean.com/tutorial_images/Ydwnncd.png?1)

Hit continue and then enter in a secure password, leaving the other settings as is.

You will be shown a textbox that contains your private key. Copy and paste the contents into a text editor and save the data into a file called ssl.key.

 ![Private Key](https://assets.digitalocean.com/tutorial_images/UWpCFq6.png?1)

When you click continue, you will be asked which domain you want to create the certificate for:

 ![Choose Domain](https://assets.digitalocean.com/tutorial_images/Dzs1eLl.png?1)

Choose your domain and proceed to the next step.

You will be asked what subdomain you want to create a certificate for. In most cases, you want to choose www here, but if you'd like to use a different subdomain with SSL, then enter that here instead:

 ![Add Subdomain](https://assets.digitalocean.com/tutorial_images/LVyrhYT.png?1)

StartSSL will provide you with your new certificate in a text box, much as it did for the private key:

 ![Save Certificate](https://assets.digitalocean.com/tutorial_images/MbvWDQk.png?1)

Again, copy and paste into a text editor, this time saving it as ssl.crt.

You will also need the StartCom Root CA and StartSSL's Class 1 Intermediate Server CA in order to authenticate your website though, so for the final step, go over to the Toolbox pane and choose StartCom CA Certificates:

 ![Startcome CA Certs](https://assets.digitalocean.com/tutorial_images/MbvWDQk.png?1)

At this screen, right click and Save As two files:

- StartCom Root CA (PEM Encoded) (save to ca.pem)
- Class 1 Intermediate Server CA (save to sub.class1.server.ca.pem)

For security reasons, StartSSL encrypts your private key (the ssl.key file), but your web server needs the unencrypted version of it to handle your site's encryption. To unencrypt it, copy it onto your server, and use the following command to decrypt it into the file private.key:

    openssl rsa -in ssl.key -out private.key

OpenSSL will ask you for your password, so enter it in the password you typed in on StartSSL's website.

At this point you should have five files. If you're missing any, double-check the previous steps and re-download them:

- ca.pem - StartSSL's Root certificate
- private.key - The unencrypted version of your private key (be very careful no one else has access to this file!)
- sub.class1.server.ca.pem - The intermediate certificate for StartSSL
- ssl.key - The encrypted version of your private key (does not need to be copied to server)
- ssl.crt - Your new certificate

You can discard the ssl.key file. If you haven't already copied the others onto your server you upload them there now:

    scp {ca.pem,private.key,sub.class1.server.ca.pem,ssl.crt} YOURSERVER:~ 

## Activating the certificate in Apache

Having a certificate isn't any good if you can't actually use it. This section explains how to configure Apache to use your new SSL certificate. These instructions are for Apache running on recent versions of Ubuntu VPS. For other Linux-based distros or web servers, you'll have to adjust accordingly.

First, create the folders where we'll store the keys. Enable Apache's SSL module, and restart Apache.

    sudo a2enmod ssl sudo service apache2 restart sudo mkdir -p /etc/apache2/ssl 

Copy the files you set up in the previous section into the /etc/apache2/ssl folder on your VPS.

    sudo mkdir -p /etc/apache2/ssl cp ~/{ca.pem,private.key,sub.class1.server.ca.pem,ssl.crt} /etc/apache2/ssl 

Execute:

    ls /etc/apache2/ssl

And it should return:

    ca.pem ssl.crt private.key sub.class1.server.ca.pem

Now, open your apache2 configuration file. Unless you've already modified the default configuration, input:

    nano /etc/apache2/sites-enabled/000-default

It should look something like this:

     \<VirtualHost \*:80\> ServerAdmin webmaster@localhost DocumentRoot /var/www \<Directory /\> Options FollowSymLinks AllowOverride None \</Directory\> \<Directory /var/www/\> Options Indexes FollowSymLinks MultiViews AllowOverride None Order allow,deny allow from all \</Directory\> ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/ \<Directory "/usr/lib/cgi-bin"\> AllowOverride None Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch Order allow,deny Allow from all \</Directory\> ErrorLog ${APACHE\_LOG\_DIR}/error.log # Possible values include: debug, info, notice, warn, error, crit, # alert, emerg. LogLevel warn CustomLog ${APACHE\_LOG\_DIR}/access.log combined Alias /doc/ "/usr/share/doc/" \<Directory "/usr/share/doc/"\> Options Indexes MultiViews FollowSymLinks AllowOverride None Order deny,allow Deny from all Allow from 127.0.0.0/255.0.0.0 ::1/128 \</Directory\> \</VirtualHost\> 

Copy the entire script above (from \<VirtualHost \*:80\> to \</VirtualHost\>), paste it below the existing one, and change the top line from:

    \<VirtualHost \*:80\>

to

    \<VirtualHost \*:443\>

And add the following lines after the \<VirtualHost \*:443\> line:

    SSLEngine on SSLProtocol all -SSLv2 SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM SSLCertificateFile /etc/apache2/ssl/ssl.crt SSLCertificateKeyFile /etc/apache2/ssl/private.key SSLCertificateChainFile /etc/apache2/ssl/sub.class1.server.ca.pem 

The end result should look like this:

     \<VirtualHost \*:80\> ServerAdmin webmaster@localhost DocumentRoot /var/www \<Directory /\> Options FollowSymLinks AllowOverride None \</Directory\> \<Directory /var/www/\> Options Indexes FollowSymLinks MultiViews AllowOverride None Order allow,deny allow from all \</Directory\> ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/ \<Directory "/usr/lib/cgi-bin"\> AllowOverride None Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch Order allow,deny Allow from all \</Directory\> ErrorLog ${APACHE\_LOG\_DIR}/error.log # Possible values include: debug, info, notice, warn, error, crit, # alert, emerg. LogLevel warn CustomLog ${APACHE\_LOG\_DIR}/access.log combined Alias /doc/ "/usr/share/doc/" \<Directory "/usr/share/doc/"\> Options Indexes MultiViews FollowSymLinks AllowOverride None Order deny,allow Deny from all Allow from 127.0.0.0/255.0.0.0 ::1/128 \</Directory\> \</VirtualHost\> \<VirtualHost \*:443\> SSLEngine on SSLProtocol all -SSLv2 SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM SSLCertificateFile /etc/apache2/ssl/ssl.crt SSLCertificateKeyFile /etc/apache2/ssl/private.key SSLCertificateChainFile /etc/apache2/ssl/sub.class1.server.ca.pem ServerAdmin webmaster@localhost DocumentRoot /var/www \<Directory /\> Options FollowSymLinks AllowOverride None \</Directory\> \<Directory /var/www/\> Options Indexes FollowSymLinks MultiViews AllowOverride None Order allow,deny allow from all \</Directory\> ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/ \<Directory "/usr/lib/cgi-bin"\> AllowOverride None Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch Order allow,deny Allow from all \</Directory\> ErrorLog ${APACHE\_LOG\_DIR}/error.log # Possible values include: debug, info, notice, warn, error, crit, # alert, emerg. LogLevel warn CustomLog ${APACHE\_LOG\_DIR}/access.log combined Alias /doc/ "/usr/share/doc/" \<Directory "/usr/share/doc/"\> Options Indexes MultiViews FollowSymLinks AllowOverride None Order deny,allow Deny from all Allow from 127.0.0.0/255.0.0.0 ::1/128 \</Directory\> \</VirtualHost\>

Save your files and restart Apache with:

    sudo service apache2 restart

You can check Apache's log files to see if there are any show stopping errors with this command:

    cat /var/log/apache2/error.log 

If everything looks good, try accessing your site in your web browser using an HTTPS URL (e.g. **https** ://www.YOURSITE.com). When your site loads, you should see a little green padlock icon next to the URL. Click on it and you should see the following. The connections tab should show that the site's identity has been verified by StartCom.

 ![](https://assets.digitalocean.com/tutorial_images/hBgTUwf.png?1) ![](https://assets.digitalocean.com/tutorial_images/Pk6kEzm.png?1)

Congratulations! You are all set!

Reference Links:

Here are some of the other posts I consulted when putting this together. If you run into any problems they might be a source of inspiration on how to fix them:

- [Apache SSL Configuration](http://www.debian-administration.org/articles/349)
- [StartSSL Apache Guides](http://jasoncodes.com/posts/startssl-free-ssl)

Submitted by: Nik van der Ploeg
