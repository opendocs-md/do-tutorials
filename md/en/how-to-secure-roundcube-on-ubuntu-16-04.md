---
author: Michael Holley
date: 2018-02-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-roundcube-on-ubuntu-16-04
---

# How To Secure Roundcube on Ubuntu 16.04

## Introduction

Because email is such a crucial part of modern day communication, it’s important to keep security in mind for all parts of your email pipeline. [Roundcube](https://roundcube.net/) is a webmail client with strong security features and extensive customization options from its plugin repository. This article explains how to further secure a basic, existing Roundcube installation.

If you used SSL when configuring your [IMAP](how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04#imap-settings) and [STMP](how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04#stmp-settings) settings in Roundcube’s initial setup, then the connection from Roundcube to your email server is already secured. However, the connection from your browser to Roundcube is not, and your emails themselves are sent in the clear. Your Roundcube account itself is also protected only by a password.

In this tutorial, you’ll secure these these three parts of the email pipeline by:

- Adding SSL to Apache with Let’s Encrypt.
- Adding [two-factor authentication](how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04) to your Roundcube account with a Roundcube plugin.
- Using GPG to sign and encrypt email with a Roundcube plugin.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with Roundcube installed by following this [Roundcube on Ubuntu 16.04 tutorial](how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04). After finishing this prerequisite tutorial, you will have a fully functional — but partially insecure — web email client.
- A smartphone or tablet with a TOTP-compatible app installed, like Google Authenticator ([iOS](https://itunes.apple.com/us/app/google-authenticator/id388497605?mt=8), [Android](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=en)). You’ll use this to set up two-factor authentication.

You can learn more about multi-factor authentication in the introduction to [How To Set Up Multi-Factor Authentication for SSH on Ubuntu 16.04](how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-16-04). You can learn more about GPG in [How To Use GPG to Encrypt and Sign Messages](how-to-use-gpg-to-encrypt-and-sign-messages).

## Step 1 — Adding SSL to Secure Access to Roundcube

Right now, if you visit your Roundcube installation by using your server’s domain name in your browser, you’ll be connected via HTTP instead of HTTPS. To fully secure the whole communication chain from your browser to your email server, this connection to Roundcube should use SSL/TLS.

One easy way to do this is by using free SSL certificates from Let’s Encrypt. Roundcube is set up on top of the LAMP stack, so you can follow [How To Secure Apache with Let’s Encrypt on Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) for a detailed walkthrough on setting this up. Here’s a brief summary:

First, install the Let’s Encrypt Client.

    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get update
    sudo apt-get install python-certbot-apache

Then get your SSL certificate and verify that auto-renewal works. Replace `example.com` with your domain, and use additional `-d` flags for any subdomains or aliases.

    sudo certbot --apache -d example.com
    sudo certbot renew --dry-run

During the interactive configuration (after entering `sudo certbot --apache -d example.com`), when asked if you want a basic or secure setup, make sure to choose **secure**. This will make sure all HTTP traffic is redirected to HTTPS.

You now have a secure connection from your computer to your Roundcube install, which in turns makes a secure connection out to your IMAP/SMTP email server. There are still a few more things you can do to improve the security of your email communications, but they require plugins.

The next step uses plugin to harden the security of a Roundcube account by adding two-factor authentication.

## Step 2 — Installing the Two-Factor Authentication Plugin

While the Roundcube project is working on GUI functionality for plugins, at the moment, all plugins must be installed via the command line. There are two ways to do this:

- **Manual installation** , which was the first method available. This involves downloading the plugin (which is usually either a `.zip` file or in a Git repository), then enabling it by modifying the Roundcube configuration file `/var/www/roundcube/config/config.inc.ph`.
- **Semi-automatic installation** , which is the more modern method. This replies on the PHP package manager, Composer, to install the plugins you specify in its configuration file.

Some plugins recommend one installation method over the other. [The 2FA plugin](https://github.com/alexandregz/twofactor_gauthenticator) works with both methods and doesn’t make a recommendation, so here, we’ll use semi-automatic installation because of its ease of use.

Composer is controlled by a `composer.json` file stored in `$RC_HOME/composer.json`. To enable Composer by creating that configuration file. Roundcube comes with a basic configuration file called `composer.json-dist`, so we’ll start from a copy of that.

    cd /var/www/roundcube
    sudo cp composer.json-dist composer.json

There are a few core plugins already specified in this default file, so next, run Composer to install these and finish its initial configuration. Make sure you run Composer from the `/var/www/roundcube` directory.

    sudo composer install

Next, to add the 2FA plugin, we need to add it to the `composer.json` file.

The syntax of a plugin line is `"organization/plugin_name": "version_or_branch"`. So for the 2FA plugin, the line you’ll add is `"alexandregz/twofactor_gauthenticator": "dev-master"`.

Open the `composer.json` file for editing using `nano` or your favorite text editor.

    sudo nano /var/www/roundcube/composer.json

Look for the require block, which begins with `"require": {`. Each line between the curly brackets (`{` and `}`) is a plugin line. All of the plugin lines in the block should end with a comma except for the very last entry.

Add the 2FA plugin line to the end of the block, and make sure to add a comma to the preceding line.

/var/www/roundcube/composer.json

    . . .
    "require": {
        "php": ">=5.4.0",
        "pear/pear-core-minimal": "~1.10.1",
        "pear/net_socket": "~1.2.1",
        "pear/auth_sasl": "~1.1.0",
        "pear/net_idna2": "~0.2.0",
        "pear/mail_mime": "~1.10.0",
        "pear/net_smtp": "~1.7.1",
        "pear/crypt_gpg": "~1.6.2",
        "pear/net_sieve": "~1.4.0",
        "roundcube/plugin-installer": "~0.1.6",
        "endroid/qr-code": "~1.6.5",
        "alexandregz/twofactor_gauthenticator": "dev-master"
    },
    . . .

Save and close the file, then run tell Composer to update its package information to install the new plugin.

    sudo composer update

When Composer asks if you want to enable the plugin, enter `Y` to continue. Once it’s intalled, log out of Roundcube and log back in to enable the plugin.

Now that the plugin is installed, we need use to to set it up 2FA on our account via Roundcube’s GUI.

## Step 3 — Enabling 2FA on Your Account

To get started, log in to Roundcube using your server IP or domain in your browser. Click on the **Settings** button in the right hand corner, then **2-Factor Authentication** in the left side navigation.

![Roundcube 2-Factor Authentication settings page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/QlcwvKy.png)

In the 2-Factor Authentication options section, click on the **Activate** checkbox, then click **Create secret**.

Next, click **Show recovery codes** and store the four displayed recovery codes in a safe place. You’ll use these codes to log in if you can’t generate a token (for example, if you lose your phone).

Finally, click the **Save** button.

This enables 2FA, but now you need to add the secret to your TOTP-compatible app, like Google Authenticator. Click the **Show QR** code button that appeared after you saved your secret and scan the code with your app. If the scan doesn’t work, you can also enter the secret manually.

![Roundcube 2-Factor Authentication QR code](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/vrraKDc.png)

Finally, once your app is generating codes, make sure that it works by entering a code into the field next to the **Check code** button, then click that button. If it works, you’ll see a window that reads **Code OK** , and you can click the **OK** button at the bottom to close that window. If there’s a problem, try re-adding the secret to your app.

The final step of securing your digital communications is encrypting the actual messages you send via email. We’ll do this in the next step using plugin called Enigma.

## Step 4 — Enabling Encrypted Email with GPG

The [Enigma plugin](https://github.com/roundcube/roundcubemail/tree/master/plugins/enigma) adds support for viewing and sending signed, encrypted emails. If you followed [the previous Roundcube installation tutorial](how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04#plugins), then the Enigma plugin is already enabled on your installation. If not, you can follow the same procedure you used for the 2FA plugin in Step 2 to add the Enigma plugin now.

To start, we need to enable some default encryption options. Log in to Roundcube and click on the **Settings** button in the upper right hand corner. From there, click on **Preferences** and then **Encryption** under the **Section** list.

![Set Encryption Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/kNwyhTr.png)

There are 7 encryption settings in the **Main Options** list. Enabling all 7 will give the most security, but that comes with some trade-off in usability.

Here are each of the options in the **Main Options** menu and our suggestions (necessary, recommended, or optional) for each, but you should choose the settings that fit your use case:

- **Enable message encryption and signing** : Necessary. This allows you to sign and encrypt messages.
- **Enable message signatures verification** Recommended. If someone sends you a signed email, this setting makes Roundcube try to verify the sender by their email address and key.
- **Enable message decryption** : Recommended. If someone sends you an encrypted email, this setting makes Roundcube use your GPG keys to decrypt it.
- **Sign all messages by default** : Optional. This signs every email you send, even if the person you are sending it to doesn’t have GPG support. If they don’t, they’ll see a blob of characters at the bottom of the email. You can also toggle this option when composing an email.
- **Encrypt all messages by default** : Optional. This encrypts every email you send, assuming you have the public key of the person you are emailing. You can also toggle this option when composing an email.
- **Attach my public PGP key by default** : Optional. This adds your GPG public key as an attachment in every email you send. If the recipient has GPG support, their email client will see the key and install it into their keyring so they can then send you encrypted email.
- **Keep private key passwords for** sets the amount of time Roundcube remembers the passphrase you enter when encrypting or decrypting email, so you don’t have to type it each time.

Once you’ve chosen your settings, click **Save.** Next, click on **Identities** in the **Settings** column.

![Update Identity](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/ESIwBCI.png)

The default setting is a single identity with the email address you signed up with. Click on the email and fill in the **Display Name** field. You can optionally fill out the other fields, like **Organization**. When you’re done, click the **Save** button.

The last part of the configuration is creating a key. Click **PGP Keys** in the left navigation.

If you have a GPG key already, you can click **Import** in the top right and import your secret key, then click it again to import your public key.

If you don’t have a GPG key, or if you want to create a new one, click the plus ( **+** ) button at the bottom of the **PGP Keys** column. From there, choose the identity you want to create the key for and select the key strength (the bigger the key size, the harder it is to break the encryption, but the slower it is to perform the encryption). Finally, choose a strong password and click **Save**.

**Warning** : There is a bug that prevents the creation of new keys in Roundcube when using Chrome. If you normally use Chrome, switch temporarily to another browser to create a new key. Once there is a key in Chrome, importing key pairs and signing/encrypting work as expected.

When you receive a verified signed email, Roundcube displays a green **Verified signature from** notification at the top:

![Signed Email](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/HOjm9fV.png)

When you receive and decrypt an encrypted email, Roundcube displays a **Message decrypted** notification:

![Decrypted Email](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/roundcube-security/CAN7RYZ.png)

To use GPG encryption in your messages, compose a new email by clicking the **Mail** icon in the upper left, then **Compose**. Click the **Encryption** icon to see the encryption options available to you. These depend on what you chose in the encryption settings. If you followed our recommendations, you should see **Digitally sign this message** , **Encrypt this message** , and **Attach my public key**. When you send an email, check the encryption options you want.

## Conclusion

By adding SSL, two-factor authentication, and GPG encryption, your email pipeline is significantly more secure. From here, you can continue expanding and customizing Roundcube by exploring the [Roundcube Plugin Repository](https://plugins.roundcube.net/explore/).
