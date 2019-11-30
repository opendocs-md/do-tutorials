---
author: Oliver Lumby
date: 2017-07-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-matrix-synapse-on-ubuntu-16-04
---

# How To Install Matrix Synapse on Ubuntu 16.04

## Introduction

[Matrix](http://matrix.org/) is an open standard for decentralized communication. It’s a collection of servers and services used for online messaging which speak a standardized API that synchronizes in real time.

Matrix uses _homeservers_ to store your account information and chat history. They work in a similar way to how an email client connects to email servers through IMAP/SMTP. Like email, you can either use a Matrix homeserver hosted by somebody else or host your own and be in control of your own information and communications.

By following this guide you will install Synapse, the reference homeserver implementation of Matrix. When you’re finished, you will be able to connect to your homeserver via any [Matrix client](https://matrix.org/beta/) and communicate with others users across other Matrix federated homeservers.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 16.04 server set up by following [this initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

- Nginx installed on your server (allowing for HTTPS traffic); you can do this by following [this Nginx on Ubuntu 16.04 tutorial](how-to-install-nginx-on-ubuntu-16-04).

- A registered domain name set up with the appropriate DNS records by following [this hostname tutorial](how-to-set-up-a-host-name-with-digitalocean). Which DNS records you need depend on how you’re using your domain.

## Step 1 — Installing Matrix Synapse

Log in to your server as your non-root user to begin.

Before you start installing anything, make sure your local package index is up to date.

    sudo apt-get update

Next, add the official Matrix repository to APT.

    sudo add-apt-repository https://matrix.org/packages/debian/

To make sure your server remains secure, you should add the repository key. This will check to make sure any installations and updates have been signed by the developers and stop any unauthorized packages from being installed on your server.

    wget -qO - https://matrix.org/packages/debian/repo-key.asc | sudo apt-key add -

You’ll see the following output:

    OutputOK

After adding the repository, update the local package index so it will include the new repository.

    sudo apt-get update

With the repository added, installing Synapse is as simple as running a single APT command.

    sudo apt-get install matrix-synapse

During the installation, you will be prompted to enter a server name, which should be your domain name. You will also be asked to choose whether or not you wish to send anonymized statistics about your homeserver back to Matrix. Then, Synapse will install.

Once complete, use `systemctl` to automatically start Synapse whenever your server starts up.

    sudo systemctl enable matrix-synapse

That command only starts Synapse when the whole server starts. Your server is already running, so use `systemctl` manually to start Synapse now.

    sudo systemctl start matrix-synapse

Synapse is now installed and running on your server, but you’ll need to create a user before you can start using it.

## Step 2 — Creating a User for Synapse

Before you can start using Synapse, you will need to add a user account. Before you can add a new user, you need to set up a shared secret. A _shared secret_ is a string that can be used by anybody who knows it to register, even if registration is disabled.

Use the following command to generate a 32-character string.

    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1

Copy the string you create, then open the Synapse configuration file with `nano` or your favorite text editor.

    sudo nano /etc/matrix-synapse/homeserver.yaml

In the registration section, look for the `registration_shared_secret` key. Update its value to the random string you copied, inserting it between quotation marks (`" "`). Remember to activate the key by uncommenting the line (i.e. deleting the `#` at the beginning of the line).

If you want to enable public registration as well, you can update the value of `enable_registration` to `True` here.

/etc/matrix-synapse/homeserver.yaml

    . . .
    
    ## Registration ##
    
    # Enable registration for new users.
    enable_registration: False
    
    # If set, allows registration by anyone who also has the shared
    # secret, even if registration is otherwise disabled.
    registration_shared_secret: "randomly_generated_string"
    
    . . .

Save and close the file.

After modifying the configuration, you need to restart Synapse so the changes can take effect.

    sudo systemctl restart matrix-synapse

Once restarted, use the command line to create a new user. The `-c` flag specifies the configuration file, and uses the local Synapse instance which is listening on port `8448`.

    register_new_matrix_user -c /etc/matrix-synapse/homeserver.yaml https://localhost:8448

You will be prompted to choose a username and a password. You’ll also be asked if you want to make the user an administrator or not; it’s up to you, but an administrator isn’t necessary for this tutorial.

Once your user is created, let’s make sure the webserver is able to serve Synapse requests.

## Step 3 — Configuring Nginx and SSL

Matrix clients make requests to `https://example.com/_matrix/` to connect to Synapse. You’ll need to configure Nginx to listen for these requests and pass them on to Synapse, which is listening locally on port `8008`. You’ll also secure your setup by [using SSL](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs) backed by Let’s Encrypt.

To do this, you’ll create a custom Nginx configuration file for your website. Create this new configuration file.

    sudo nano /etc/nginx/sites-available/example.com

The `location /_matrix` block below specifies how Nginx should handle requests from Matrix clients. In addition to the request handling, the `/.well-known` block makes the directory of the same name available to Let’s Encrypt.

Copy and paste the following into the file.

/etc/nginx/sites-available/example.com

    server {
        listen 80;
        listen [::]:80;
    
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
    
        server_name example.com www.example.com;
    
        location /_matrix {
            proxy_pass http://localhost:8008;
        }
    
        location ~ /.well-known {
            allow all;
        }
    }

[This Nginx server blocks tutorial](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) has more information about how files like these work. When you have configured the server, you can save and close the file.

To enable this configuration, create a symlink for this file in the `/etc/nginx/sites-enabled` directory.

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

Test your configuration file for syntax errors by running the command.

    sudo nginx -t

Correct the syntax based on the error output, if any. When no errors are reported, use `systemctl` reload Nginx so the changes take effect.

    sudo systemctl reload nginx

To finish securing Nginx with a Let’s Encrypt certificate, follow [this Let’s Encrypt for Nginx on Ubuntu 16.04 tutorial](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04). Remember to use `/etc/nginx/sites-available/example.com` instead of the default configuration file. You’ve already added the `~/.well-known` block mentioned in Step 2 of that tutorial.

Once Let’s Encrypt is set up, you can move on to configuring the firewall to allow the necessary traffic for Synapse to communicate with other homeservers.

## Step 4 — Allowing Synapse through the Firewall

Client traffic connects to Synapse via the HTTPS port `443`, (which is already open in your firewall from the Nginx guide). However, traffic from other servers connects directly to Synapse on port `8448` without going through the Nginx proxy, so you need to allow this traffic through the firewall as well.

    sudo ufw allow 8448

Check the status of UFW.

    sudo ufw status

It should look like this:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx Full ALLOW Anywhere                  
    8448 ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx Full (v6) ALLOW Anywhere (v6)             
    8448 (v6) ALLOW Anywhere (v6)

This means that all the necessary traffic is allowed through your firewall. The last step you should take is improving Synapse’s security by updating its SSL certificates.

## Step 5 — Securing Federation with SSL (Recommended)

Now that Synapse is configured and can communicate with other homeservers, you can increase its security by using the same SSL certificates you requested from Let’s Encrypt at the end of Step 3. By default Synapse uses self signed certificates which do the job, but seeing as you already requested the Let’s Encrypt certificates it’s simple to use those and improve security.

Copy the certificates to your Synapse directory:

    sudo cp /etc/letsencrypt/live/example.com/fullchain.pem /etc/matrix-synapse/fullchain.pem
    sudo cp /etc/letsencrypt/live/example.com/privkey.pem /etc/matrix-synapse/privkey.pem

In order for these certificates to be updated when they are renewed you need to add these commands to your cron tab. Open it for editing.

    sudo crontab -e

And add the following lines:

    crontab entry35 2 * * 1 sudo cp /etc/letsencrypt/live/example.com/fullchain.pem /etc/matrix-synapse/fullchain.pem
    35 2 * * 1 sudo cp /etc/letsencrypt/live/example.com/privkey.pem /etc/matrix-synapse/privkey.pem
    36 2 * * 1 sudo systemctl restart matrix-synapse

Then save and close the file. Next, open your Synapse configuration file with `nano` or your favorite text editor.

    sudo nano /etc/matrix-synapse/homeserver.yaml

Using the same certificate you requested from Lets Encrypt in Step 3, replace the paths in the configuration file.

/etc/matrix-synapse/homeserver.yaml

    . . .
    
    tls_certificate_path: "/etc/matrix-synapse/fullchain.pem"
    
    # PEM encoded private key for TLS
    tls_private_key_path: "/etc/matrix-synapse/privkey.pem"
    
    # PEM dh parameters for ephemeral keys
    tls_dh_params_path: "/etc/ssl/certs/dhparam.pem"
    
    . . .

Restart Synapse so the configuration changes take effect.

    sudo systemctl restart matrix-synapse

Everything’s set up, so now you can connect to your homeserver with any Matrix client and start communicating with others. For example, you can use [the client on Matrix’s website](https://matrix.org/beta/).

Enter the following for the appropriate fields:

- Your **Matrix ID** is in the format `@user:server_name` (e.g. `@sammy:example.com`). Other federated servers use this to find where your homeserver is hosted.
- Your **Password** is the secure password you set when creating this user.
- Your **Home Server** is the server name you chose in Step 1.

If you enabled public registration in Step 2, you can also click the **Create account** link to create a new account or allow others to create a new account on your homeserver.

From there, you can log into rooms and start chatting. The official support room for Matrix is `#matrix:matrix.org`.

## Conclusion

In this guide, you securely installed Matrix Synapse with Nginx, backed by SSL certificates from Let’s Encrypt. There are [many Matrix clients](https://matrix.org/docs/projects/try-matrix-now.html#clients) you can use to connect to your homeserver, and you can even [write your own Matrix client](http://matrix.org/docs/guides/client-server.html) or [get involved with the project in other ways](http://matrix.org/docs/guides/).
