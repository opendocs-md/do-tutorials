---
author: Justin Ellingwood
date: 2017-08-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-configure-gocd-with-let-s-encrypt-ssl-certificates-on-ubuntu-16-04
---

# How To Configure GoCD with Let's Encrypt SSL Certificates on Ubuntu 16.04

## Introduction

[GoCD](https://www.gocd.org/) is a powerful continuous integration and delivery platform designed to automate testing and release processes. With many advanced features like the ability to compare builds, visualize complex workflows, and automate build version tracking, GoCD is a flexible tool that can help teams deliver well-tested software to production environments.

In the last article, we [installed the GoCD server, set up an agent, and configured authentication](how-to-install-and-configure-gocd-on-ubuntu-16-04). In this guide, we will configure GoCD to use a trusted Let’s Encrypt SSL certificate to prevent browser warnings when accessing the web interface. We will provide instructions for two different possible configurations.

The first method will install an Nginx web server as a reverse proxy that will forward connections to GoCD’s HTTP endpoint. This choice provides a more seamless Let’s Encrypt experience and will probably be the best option for most people.

The second method we will discuss will acquire a certificate from Let’s Encrypt and then switch out the certificate used by GoCD’s HTTPS endpoint. While this removes the requirement for a separate web server, possibly saving resources, GoCD uses the Java keystore SSL certificate repository which is not directly compatible with the certificate format offered by Let’s Encrypt. We will need to create a script to automatically convert the certificates to the expected format every time a renewal occurs. This option is best if your server has minimal resources and you want to allocate everything available to GoCD itself.

## Prerequisites

If you do not already have a GoCD server configured on Ubuntu 16.04, you will need to configure one before starting this guide. The base server requires **at least 2G of RAM and 2 CPU cores**. GoCD also needs a dedicated partition or disk to use for artifact storage. You can learn how to configure this additional space using one of these two guides:

- If you are using DigitalOcean as your server host, you can use a block storage volume as the artifact storage location. Follow this guide to learn [how to provision, format, and mount a DigitalOcean block storage volume](how-to-use-block-storage-on-digitalocean).
- If you are _not_ using DigitalOcean, follow this guide to learn [how to partition, format, and mount devices on generic hosts](how-to-partition-and-format-storage-devices-in-linux).

After the server is set up, you can perform some initial configuration and install GoCD using these guides:

- [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04): This guide will show you how to create a `sudo` user and set up a basic firewall.
- [How To Install and Configure GoCD on Ubuntu 16.04](how-to-install-and-configure-gocd-on-ubuntu-16-04): This guide will take you through installing the software, configuring an artifacts mount point, and setting up user authentication.

To acquire an SSL certificate from Let’s Encrypt, your server will need to have a **domain name**.

Further requirements depend on the method you want to pursue and will be explained in the appropriate sections. When you are ready to continue, choose the method you want to use and follow the associated instructions.

## Option 1: Configuring Nginx as a Reverse Proxy for GoCD

If you’d like to set up Nginx as an SSL terminating reverse proxy for GoCD, follow this section. In this configuration, Nginx will be configured to serve HTTPS traffic using the Let’s Encrypt certificate. It will decrypt client connections and then forward traffic to GoCD’s web interface using regular HTTP. This requires some additional overhead for the Nginx frontend, but is a more straightforward approach.

### Additional Requirements

If you want to use Nginx as a reverse proxy for GoCD, you will first need to install Nginx and the Let’s Encrypt client and then request a certificate for your domain. These tutorials provide the steps necessary to obtain a certificate and configure your web server:

- [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04)
- [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04)

Once you’ve completed the above guides, GoCD should still be accessible using the self-signed certificate by accessing `https://your_domain:8154` and the default Nginx page should be displayed using the Let’s Encrypt certificate when you remove the port specification.

Now, we can configure Nginx to proxy requests to the GoCD backend so that the client connections are encrypted with the Let’s Encrypt certificate.

### Configuring Nginx To Proxy to GoCD’s HTTP Web Interface

We’ve downloaded an SSL certificate from Let’s Encrypt and configured Nginx to use the certificate when serving requests on the default SSL port. Our next step is to configure Nginx to proxy those requests to GoCD’s regular HTTP web interface, available on port 8153.

To get started, open up the default Nginx server block file that’s configured to use your Let’s Encrypt certificate:

    sudo nano /etc/nginx/sites-available/default

At the top of the file, outside of the `server` block, open a new `upsteam` section. We will call this block `gocd` so that we can easily recognize it later. Inside, specify the address that Nginx can use to contact GoCD’s HTTP interface. In our case, this would use the local loopback device, so the full address should be `127.0.0.1:8153`:

/etc/nginx/sites-available/default

    upstream gocd {
        server 127.0.0.1:8153;
    }
    
    server {
        . . .

Next, in the `server` block, find the `location /` block. Inside, comment out the `try_files` directive so that we can specify our proxy configuration. In place of the `try_files` line, add a proxy pass to the `gocd` upstream we defined, using the `http://` protocol. Include the `proxy_params` file to set the other proxy settings that our location block requires:

/etc/nginx/sites-available/default

    . . .
    
    server
        . . .
    
        location / {
            #try_files $uri $uri/ =404;
            proxy_pass http://gocd;
            include proxy_params;
        }
    
        . . .

Save and close the file when you are finished.

Once you’re back on the command line, check the Nginx configuration for syntax errors by typing:

    sudo nginx -t

If no errors are found, restart the Nginx service by typing:

    sudo systemctl restart nginx

Your GoCD web UI should now be accessible through your regular domain name with the `https://` protocol.

**Note:** Although we’re proxying requests on port 80 and 443 through Nginx, we still need to [keep the 8154 HTTPS port open in our firewall](https://docs.gocd.org/current/installation/configure_proxy.html#agents-and-custom-ssl-ports). GoCD agents need to be able to contact the GoCD server directly (without a proxy) so the server can validate the client’s SSL certificate directly. Leaving port 8154 open will allow external agents to contact the server correctly while regular web requests through the browser can go through the proxy.

The final item we need to adjust is the Site URL setting within GoCD’s web UI.

### Updating the GoCD Site URL to Use the New Address

Once you’ve restarted Nginx, the only remaining task is to modify the Site URL setting that GoCD uses internally to construct appropriate links.

Visit your GoCD server domain in your web browser and log in if necessary:

    https://example.com

Next, click **ADMIN** in the top menu bar and select **Server Configuration** from the drop down menu:

![GoCD configure server link](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gocd_ssl_1604/config_server_link.png)

In the **Server Management** section, modify the **Site URL** to remove the `:8154` port specification from the end. If you were using an IP address instead of a domain name previously, change the URL to use your domain name as well:

![GoCD site URL setting](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gocd_ssl_1604/site_url_setting.png)

Scroll down to the bottom of the page and click **SAVE** to implement the change immediately. Your site is now set up to proxy all requests for your domain through Nginx to the GoCD web UI.

## Option 2: Configuring GoCD’s Native SSL to Use Let’s Encrypt Certificates

Follow this section if you’d like to configure GoCD’s own web server to use Let’s Encrypt certificates. In this configuration, we will replace the self-signed certificate already used by the GoCD server with a trusted certificate provided by Let’s Encrypt. To do this though, we will need to convert the certificate files to a new format and import them into a Java keystore file. We will create a script so that the process can be repeated every time the certificate files are renewed.

### Additional Requirements

If you wish to handle all SSL operations from within GoCD itself, you will need to download a certificate from Let’s Encrypt without the web server configuration procedure. Follow this guide to download the appropriate client and obtain a certificate for your domain:

- [How To Use Certbot Standalone Mode to Retrieve Let’s Encrypt SSL Certificates](how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates): You can skip the step that sets up automatic renewal, as we will be creating a specific script to run during this process.

Once you’ve completed the above guides, GoCD should still be accessible using the self-signed certificate by accessing `https://your_domain:8154` and the Let’s Encrypt provided certificate files should be available within the `/etc/letsencrypt/live/your_domain` directory.

### Creating the Certificate Conversion Script

GoCD uses a [Java keystore](java-keytool-essentials-working-with-java-keystores) to handle SSL certificates. Unfortunately, this is a different format than the one used by Let’s Encrypt. To use our Let’s Encrypt certificates with GoCD, we will have to convert them using a very specific procedure.

Because of the complexity of the procedure and our need to convert certificates each time they are renewed, we will create a script to automate the procedure. In the `/usr/local/bin` directory, create and open a script called `convert_certs_for_gocd.sh` in your text editor:

    sudo nano /usr/local/bin/convert_certs_for_gocd.sh

Inside, paste the following script. The only setting you’ll need to update is the value of the `base_domain` variable. Set that to your GoCD server’s domain name (this should match the value of the directory within `/etc/letsencrypt/live/`):

/usr/local/bin/convert\_certs\_for\_gocd.sh

    #!/bin/bash
    
    base_domain="example.com"
    le_directory="/etc/letsencrypt/live/${base_domain}"
    working_dir="$(mktemp -d)"
    gocd_pass="serverKeystorepa55w0rd"
    
    
    clean_up () {
        rm -rf "${working_dir}"
    }
    
    # Use this to echo to standard error
    error () {
        printf "%s: %s\n" "$(basename "${BASH_SOURCE}")" "${1}" >&2
        clean_up
        exit 1
    }
    
    trap 'error "An unexpected error occurred."' ERR
    
    copy_cert_files () {
        cp "${le_directory}/fullchain.pem" "${working_dir}"
        cp "${le_directory}/privkey.pem" "${working_dir}"
    }
    
    convert_to_pkcs12 () {
        openssl_pkcs12_args=(
            "pkcs12"
            "-inkey" "${working_dir}/privkey.pem"
            "-in" "${working_dir}/fullchain.pem"
            "-export"
            "-out" "${working_dir}/${base_domain}.crt.pkcs12"
            "-passout" "pass:${gocd_pass}"
        )
        openssl "${openssl_pkcs12_args[@]}"
    }
    
    import_to_keytool () {
        keytool_args=(
            "-importkeystore"
            "-srckeystore" "${working_dir}/${base_domain}.crt.pkcs12"
            "-srcstoretype" "PKCS12"
            "-srcstorepass" "${gocd_pass}"
            "-destkeystore" "${working_dir}/keystore"
            "-srcalias" "1"
            "-destalias" "cruise"
            "-deststorepass" "${gocd_pass}"
            "-destkeypass" "${gocd_pass}"
        )
        keytool "${keytool_args[@]}"
    }
    
    install_new_keystore () {
        cp /etc/go/keystore /etc/go/keystore.bak
        mv "${working_dir}/keystore" "/etc/go/keystore"
        chown go:go /etc/go/keystore
        systemctl restart go-server
    }
    
    if (( EUID != 0 )); then
        error "This script requires root privileges"
    fi
    
    copy_cert_files && convert_to_pkcs12 && import_to_keytool && install_new_keystore && clean_up

Let’s go over exactly what this script is doing.

In the beginning, we set a few variables to help make our script easier to work with. We set the domain name for the certificates we want to convert and a variable that expands to the Let’s Encrypt certificate directory. We create a temporary working directory with the `mktemp` command and assign the value to another variable. [GoCD requires all of its Java keystore passwords](https://docs.gocd.org/current/installation/ssl_tls/custom_server_certificate.html#using-your-own-ssl-certificates-on-the-server) to be `serverKeystorepa55w0rd`, we set another variable to hold that value.

Next, we define a function that deletes the temporary directory when called. We use this at the end of our script to clean up after ourselves and also when any unexpected errors occur. To accomplish this second possibility, we create another function that displays an error message and cleans up before exiting. We use the `trap` command to call this function automatically whenever an error is raised.

Afterwards, we create the functions that do the actual conversion. The first function sets up our workspace by copying the private key and full chain certificate into the working directory. The `convert_to_pkcs12` function uses `openssl` to join the full chain certificate file and the private key file in the combined [PKCS 12 file](https://en.wikipedia.org/wiki/PKCS_12) that the keytool uses. This process requires an export password, so we use the GoCD password variable.

The next function imports the new PKCS 12 file into a Java keystore file. We import the file and provide the export password. We then supply the same password for the keystore file’s various passwords. Finally, the last function copies the new `keystore` file into the `/etc/go` directory (after backing up the old `keystore`), adjusts the file ownership, and restarts the GoCD server.

At the end of the script, we check that the script is being called with the appropriate permissions by checking if the effective user ID is “0”, which means “with the same permissions as root”. Then call the functions in the appropriate order to correctly convert the certificates and install the new `keystore` file.

When you are finished, save and close the file to continue.

### Performing the Initial Conversion

Now that we have a conversion script, we should use it to perform the initial certificate conversion.

First, mark the script as executable so that it can be executed directly without calling an interpreter:

    sudo chmod +x /usr/local/bin/convert_certs_for_gocd.sh

Now, call the script with `sudo` to perform the initial conversion, install the generated `keystore` file, and restart the GoCD process

    sudo /usr/local/bin/convert_certs_for_gocd.sh

Because the GoCD server has to restart, the process can take some time. After the script completes, it may take another moment or two before the server is ready to listen for connections. You can watch the ports currently being used by applications by typing:

    sudo watch netstat -plnt

This view will show the TCP ports that applications are currently listening on with a two second refresh rate. When GoCD starts listening to ports 8153 and 8154, the screen should look like this:

    OutputEvery 2.0s: netstat -plnt Thu Jul 27 20:16:20 2017
    
    Active Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 1736/sshd
    tcp6 0 0 :::22 :::* LISTEN 1736/sshd
    tcp6 0 0 :::8153 :::* LISTEN 8942/java
    tcp6 0 0 :::8154 :::* LISTEN 8942/java

Once ports 8153 and 8154 are present, hit **CTRL-C** to exit the display.

After the application begins listening for connections, check the web interface by visiting your GoCD domain on port 8154 using HTTPS:

    https://example.com:8154

Previously, when this page was accessed, an icon in the address bar indicated that the certificate could not be trusted (note that your browser’s visual indicator may be different):

![Chrome SSL cert not trusted icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gocd_ssl_1604/ssl_cert_not_trusted_icon.png)

The first time you visited, you likely had to click through a warning screen in your browser:

![Browser SSL warning](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gocd_install_1604/browser_ssl_warning.png)

Now that we’ve replaced the self-signed certificate with a trusted certificate provided by Let’s Encrypt, the browser will indicate that the certificate is trusted and users will not have to bypass a browser warning to access the site. Note that the previous certificate may be cached by your browser until you close your current tab, window, or session:

![Chrome SSL cert trusted icon](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gocd_ssl_1604/ssl_cert_trusted_icon.png)

This means that GoCD was able to use the Let’s Encrypt certificate that we converted.

### Setting Up an Auto Renew Hook

Now that we’ve verified that our script converted the certificate assets correctly, we can make sure that `certbot` calls our script every time the certificate is renewed.

Open the renewal configuration file for your domain within the `/etc/letsencrypt/renewal` directory by typing:

    sudo nano /etc/letsencrypt/renewal/example.com.conf

Inside, in the `[renewalparams]` section of the file, add a line setting `renew_hook` to the location of your script:

/etc/letsencrypt/renewal/example.com.conf

    . . .
    [renewalparams]
    . . .
    renew_hook = /usr/local/bin/convert_certs_for_gocd.sh

The `certbot` software installs a `cron` job that checks whether any certificates should be renewed twice a day. After a certificate is renewed, the script specified by `renew_hook` will be run. This way, we can ensure that GoCD is always using the latest valid certificate acquired from Let’s Encrypt.

Save and close the file when you are finished.

You can test that you didn’t introduce any syntax errors to the file by doing a dry run of the renewal procedure. Note that this won’t run our certificate conversion script, but it will print out a notice about it being skipped:

    sudo certbot renew --dry-run

    OutputSaving debug log to /var/log/letsencrypt/letsencrypt.log
    
    -------------------------------------------------------------------------------
    Processing /etc/letsencrypt/renewal/example.com.conf
    -------------------------------------------------------------------------------
    Cert not due for renewal, but simulating renewal for dry run
    Renewing an existing certificate
    Performing the following challenges:
    http-01 challenge for example.com
    Waiting for verification...
    Cleaning up challenges
    Dry run: skipping renewal hook command: /usr/local/bin/convert_certs_for_gocd.sh
    
    -------------------------------------------------------------------------------
    new certificate deployed without reload, fullchain is
    /etc/letsencrypt/live/example.com/fullchain.pem
    -------------------------------------------------------------------------------
    ** DRY RUN: simulating 'certbot renew' close to cert expiry
    ** (The test certificates below have not been saved.)
    
    Congratulations, all renewals succeeded. The following certs have been renewed:
      /etc/letsencrypt/live/example.com/fullchain.pem (success)
    ** DRY RUN: simulating 'certbot renew' close to cert expiry
    ** (The test certificates above have not been saved.)

The above output verify that the changes we made did not prevent certificate renewal. The output also indicates that the renewal hook is pointed to the correct script location.

## Conclusion

In this guide, we’ve covered two different ways of securing a GoCD installation with a trusted SSL certificate from Let’s Encrypt. The first method set up the certificate with Nginx and then proxied traffic through to GoCD’s web interface. The second option converted the Let’s Encrypt certificate files to the PKCS 12 format and imported them into a Java keystore file to be used by GoCD natively. Both options secure GoCD’s web interface with a trusted certificate, but they accomplish this using different strategies and with unique trade-offs. The approach that is right for you will largely depend on your team’s requirements and goals.
