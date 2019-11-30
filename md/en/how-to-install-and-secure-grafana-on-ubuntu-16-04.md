---
author: Marko Mudrinić
date: 2017-12-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-grafana-on-ubuntu-16-04
---

# How to Install and Secure Grafana on Ubuntu 16.04

## Introduction

[Grafana](https://grafana.com/) is an open-source, data visualization and monitoring tool that integrates with complex data from sources like [Prometheus](https://prometheus.io/), [InfluxDB](https://www.influxdata.com/), [Graphite](https://graphiteapp.org/), and [ElasticSearch](https://www.elastic.co/). Grafana lets you create alerts, notifications, and ad-hoc filters for your data while also making collaboration with your teammates easier through built-in sharing features.

In this tutorial, you will install Grafana and secure it with an [SSL certificate](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs) and an [Nginx reverse proxy](understanding-nginx-http-proxying-load-balancing-buffering-and-caching), then you’ll modify Grafana’s default settings for even tighter security.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial, including a sudo non-root user and a firewall.
- A fully registered domain name. This tutorial uses `example.com` throughout. You can purchase a domain name on [Namecheap](https://namecheap.com/), get one for free on [Freenom](http://www.freenom.com/en/index.html), or use the domain registrar of your choice.
- The following DNS records set up for your server. You can follow [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) for details on how to add them.
  - An **A** record with `example.com` pointing to your server’s public IP address.
  - An **A** record with `www.example.com` pointing to your server’s public IP address.
- Nginx set up by following the first two steps of the [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04) tutorial.
- An Nginx Server Block with Let’s Encrypt configured, which can be set up by following [How To Set Up Let’s Encrypt with Nginx Server Blocks on Ubuntu 16.04](how-to-set-up-let-s-encrypt-with-nginx-server-blocks-on-ubuntu-16-04).
- Optionally, to set up [GitHub](https://github.com) authentication, you’ll need a [GitHub account associated with an organization](https://github.com/business).

## Step 1 — Installing Grafana

You can install Grafana either by [downloading it directly from its official website](https://grafana.com/grafana/download) or by going through an [APT repository](ubuntu-and-debian-package-management-essentials#debian-package-management-tools-overview). Because an APT repository makes it easier to install and manage Grafana’s updates, we’ll use that method.

Although Grafana is available in [the official Ubuntu 16.04 packages repository](https://packages.ubuntu.com/xenial/), the version of Grafana there may not be the latest, so we’ll use Grafana’s official repository on [packagecloud](https://packagecloud.io/).

Download the packagecloud [GPG key](how-to-use-gpg-to-encrypt-and-sign-messages) with `curl`, then [pipe the output](an-introduction-to-linux-i-o-redirection#pipes) to `apt-key`. This will add the key to your APT installation’s list of trusted keys, which will allow you to download and verify the GPG-signed Grafana package.

    curl https://packagecloud.io/gpg.key | sudo apt-key add -

Next, add the packagecloud repository to your APT sources.

    sudo add-apt-repository "deb https://packagecloud.io/grafana/stable/debian/ stretch main"

**Note:** Although this tutorial is written for Ubuntu 16.04, packagecloud only provides Debian, Python, RPM, and RubyGem packages. You can use the Debian-based repository in the previous command, though, because the Grafana package it contains is the same as the one for Ubuntu. Just be sure to use the `stretch` repository to get the latest version of Grafana.

Refresh your APT cache to update your package lists.

    sudo apt-get update

And, make sure Grafana will be installed from the packagecloud repository.

    apt-cache policy grafana

The output tells you the version of Grafana that will be installed and where the package will be retrieved from. Verify that the installation candidate will come from the official Grafana repository at `https://packagecloud.io/grafana/stable/debian`.

    Output of apt-cache policy grafanagrafana:
      Installed: (none)
      Candidate: 4.6.2
      Version table:
         4.6.2 500
            500 https://packagecloud.io/grafana/stable/debian stretch/main amd64 Packages
    ...

You can now proceed with the installation.

    sudo apt-get install grafana

Once Grafana’s installed, you’re ready to start it.

    sudo systemctl start grafana-server

Next, verify that Grafana is running by checking the service’s status.

    sudo systemctl status grafana-server

The output contains information about Grafana’s process, including its status, Main Process Identifier (PID), memory use, and more.

If the service status isn’t `active (running)`, review the output and re-trace the preceding steps to resolve the problem.

    Output of grafana-server status● grafana-server.service - Grafana instance
       Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; disabled; vendor preset: enabled)
       Active: active (running) since Thu 2017-12-07 12:10:33 UTC; 19s ago
         Docs: http://docs.grafana.org
     Main PID: 14796 (grafana-server)
        Tasks: 6
       Memory: 32.0M
          CPU: 472ms
       CGroup: /system.slice/grafana-server.service
               └─14796 /usr/sbin/grafana-server --config=/etc/grafana/grafana.ini --pidfile=/var/run/grafana/grafana-server.pid cfg:default.paths.logs=/var/log/grafana cfg:default.paths.data=/var/lib/grafana cfg:default.paths.plugins=/var/lib/grafana/plugins
    ...

Lastly, enable the service to automatically start Grafana on boot.

    sudo systemctl enable grafana-server

The output confirms that `systemd` has created the necessary symbolic links to autostart Grafana. If you receive an error message, follow the instructions in the terminal to fix the problem before continuing.

    Output of systemctl enable grafana-serverSynchronizing state of grafana-server.service with SysV init with /lib/systemd/systemd-sysv-install...
    Executing /lib/systemd/systemd-sysv-install enable grafana-server
    Created symlink from /etc/systemd/system/multi-user.target.wants/grafana-server.service to /usr/lib/systemd/system/grafana-server.service.

Grafana is now installed and ready to be used. Next, secure your connection to Grafana with a reverse proxy and SSL certificate.

## Step 2 — Setting Up the Reverse Proxy

Using an SSL certificate will ensure that your data is secure by encrypting the connection to and from Grafana. But, to make use of this connection, you’ll first need to reconfigure Nginx.

Open the Nginx configuration file you created when you set up the Nginx server block with Let’s Encrypt in the Prerequisites.

    sudo nano /etc/nginx/sites-available/example.com

Locate the following block:

/etc/nginx/sites-available/example.com

    ...
        location / {
            # First attempt to serve request as file, then
            # as directory, then fall back to displaying a 404.
            try_files $uri $uri/ =404;
        }
    ...

Because you already configured Nginx to communicate over SSL and because all web   
traffic to your server already passes through Nginx, you just need to tell Nginx to forward all requests to Grafana, which runs on port `3000` by default.

Delete the existing `try_files` line in this location block and replace it with the following contents, which all begin with `proxy_`.

/etc/nginx/sites-available/example.com

    ...
        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    ...

Once you’re done, save the file and close your text editor.

Now, test the new settings to make sure everything is configured correctly.

    sudo nginx -t

The output should tell you that the `syntax is ok` and that the `test is successful`. If you receive an error message, follow the on-screen instructions.

Finally, activate the changes by reloading Nginx.

    sudo systemctl reload nginx

You can now access the default Grafana login screen by pointing your web browser to `https://example.com`. If you’re unable to reach Grafana, verify that your firewall is set to allow traffic on port `443` and then re-trace the previous instructions.

With the connection to Grafana encrypted, you can now implement additional security measures, starting with changing Grafana’s default administrative credentials.

## Step 3 — Updating Credentials

Because every Grafana installation uses the same administrative login credentials by default, in this step, you’ll update the credentials to improve security.

Start by navigating to `https://example.com` from your web browser. This will bring up the default login screen where you’ll see the Grafana logo, a form asking you to enter a **User** and **Password** , a **Log in** button, and a **Forgot your password?** link.

![Grafana Login](http://assets.digitalocean.com/articles/install-and-secure-grafana/default-login.png)

Enter **admin** into both the **User** and **Password** fields and then click on the **Log in** button.

On the next screen, you’ll be welcomed to the **Home Dashboard**. Here you can add data sources and create, preview, and modify dashboards.

Click on the small Grafana logo in the upper, left-hand corner of the screen to bring up the application’s main menu. Then, hover over the **admin** button with your mouse to open up a secondary set of menu options. Finally, click on the **Profile** button.

![Grafana menu](http://assets.digitalocean.com/articles/install-and-secure-grafana/main-menu.png)

You’re now on the **User Profile** page, where you can change the **Name** , **Email** , and **Username** associated with your account. You can also update your **Preferences** for settings like the **UI Theme** , and you can change your password.

![Grafana profile preferences](http://assets.digitalocean.com/articles/install-and-secure-grafana/user-profile.png)

Enter your name, email address, and the username you want to use in the **Name** , **Email** , and **Username** fields and then click the **Update** button in the **Information** section to save your settings.

If you want, you can also change the **UI Theme** and **Timezone** to fit your needs and then press the **Update** button in the **Preferences** area to save your changes. Grafana offers **Dark** and **Light** UI themes, as well as a **Default** theme, which is set to **Dark** by default.

Finally, change the password associated with your account by clicking on the **Change Password** button at the bottom of the page. This will take you to the **Change password** screen.

Enter your current password, **admin** , into the **Old Password** field and then enter the password you’d like to start using into the **New Password** and **Confirm Password** fields.

Click **Change Password** to save the new information or press **Cancel** to abandon your changes.

From there, you’ll be returned to the **User Profile** page where you’ll see a green box in the upper, right-hand corner of the screen telling you that the **User password changed**.

![Grafana change password successful](http://assets.digitalocean.com/articles/install-and-secure-grafana/user-profile2.png)

You’ve now secured your account by changing the default credentials, so let’s also make sure that nobody can create a new Grafana account without your permission.

## Step 4 — Disabling Grafana Registrations and Anonymous Access

Grafana provides options that allow visitors to create user accounts for themselves and preview dashboards without registering. As you’re exposing Grafana on the internet, this could be a security problem. However, when Grafana isn’t accessible via the internet or when working with publicly-available data, like service statuses, you may want to allow these features. So, it’s important that you know how to configure Grafana to meet your needs.

Start by opening Grafana’s main configuration file for editing.

    sudo nano /etc/grafana/grafana.ini

Locate the following `allow_sign_up` directive under the `[users]` heading:

/etc/grafana/grafana.ini

    ...
    [users]
    # disable user signup / registration
    ;allow_sign_up = true
    ...

Enabling this directive with `true` adds a **Sign Up** button to the login screen, allowing users to register themselves and access Grafana.

Disabling this directive with `false` removes the **Sign Up** button and strengthens Grafana’s security and privacy.

Unless you need to allow anonymous visitors to register themselves, uncomment this directive by removing the `;` at the beginning of the line and then set the option to `false`.

/etc/grafana/grafana.ini

    ...
    [users]
    # disable user signup / registration
    allow_sign_up = false
    ...

Next, locate the following `enabled` directive under the `[auth.anonymous]` heading.

/etc/grafana/grafana.ini

    ...
    [auth.anonymous]
    # enable anonymous access
    ;enabled = false
    ...

Setting `enabled` to `true` gives non-registered users access to your dashboards; setting this option to `false` limits dashboard access to registered users only.

Unless you need to allow anonymous access to your dashboards, uncomment this directive by removing the `;` at the beginning of the line and then set the option to `false`.

/etc/grafana/grafana.ini

    ...
    [auth.anonymous]
    enabled = false
    ...

Save the file and exit your text editor.

To activate the changes, restart Grafana.

    sudo systemctl restart grafana-server

Verify that everything is working by checking Grafana’s service status.

    sudo systemctl status grafana-server

Like before, the output should report that Grafana is `active (running)`. If it isn’t, review any terminal messages for additional help.

Now, point your web browser to `https://example.com` to verify that there is no **Sign Up** button and that you can’t sign in without entering login credentials.

If you see the **Sign Up** button or you’re able to login anonymously, re-examine the preceding steps to resolve the problem before continuing the tutorial.

At this point, Grafana is fully configured and ready for use. Optionally, you can simplify the login process for you organization by authenticating through GitHub.

## (Optional) Step 5 — Setting up a GitHub OAuth App

For an alternative approach to signing in, you can configure Grafana to authenticate through GitHub, which provides login access to all members of authorized GitHub organizations. This can be particularly useful when you want to allow multiple developers to collaborate and access metrics without having to create Grafana-specific credentials.

Start by logging into a GitHub account associated with your organization and then navigate to your GitHub profile page at `https://github.com/settings/profile`.

Click on your organization’s name under **Organization settings** in the navigation menu on the left-hand side of the screen.

![GitHub Settings page](http://assets.digitalocean.com/articles/install-and-secure-grafana/github-settings.png)

On the next screen, you’ll see your **Organization profile** where you can change settings like your **Organization display name** , organization **Email** , and organization **URL**.

Because Grafana uses [OAuth](https://oauth.net/) — an open standard for granting remote third-parties access to local resources — to authenticate users through GitHub, you’ll need to create a new [OAuth application within GitHub](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/).

Click the **OAuth Apps** link under **Developer settings** on the lower, left-hand side of the screen.

![GitHub Organization Settings](http://assets.digitalocean.com/articles/install-and-secure-grafana/organization-profile.png)

If you don’t already have any OAuth applications associated with your organization on GitHub, you’ll be told there are **No Organization Owned Applications**. Otherwise, you’ll see a list of the OAuth applications already connected to your account.

Click the **Register an application** button to continue.

On the next screen, you’ll fill in the following details about your Grafana installation:

- **Application Name** - This helps you distinguish your different OAuth applications from one another.
- **Homepage URL** - This tells GitHub where to find Grafana.
- **Application Description** - This provides a description of your OAuth application’s purpose.
- **Application callback URL** - This is the address where users will be sent once successfully authenticated. For Grafana, this field must be set to `https://example.com/login/github`.

Keep in mind that Grafana users logging in through GitHub will see the values you entered in the first three preceding fields, so be sure to enter something meaningful and appropriate.

When completed, the form should look something like:

![GitHub Register OAuth Application](http://assets.digitalocean.com/articles/install-and-secure-grafana/new-oauth-application.png)

Click the green, **Register application** button.

You will now be redirected to a page containing the **Client ID** and **Client Secret** associated with your new OAuth application. Make note of both values, because you will need to add them to Grafana’s main configuration file to complete the setup.

![GitHub Application Details](http://assets.digitalocean.com/articles/install-and-secure-grafana/client-id.png)

**Warning:** Make sure to keep your **Client ID** and **Client Secret** in a secure and non-public location, because they could be used as the basis of an attack.

With your GitHub OAuth application created, you’re now ready to reconfigure Grafana.

## (Optional) Step 6 — Configuring Grafana as a GitHub OAuth App

To begin, open the main Grafana configuration file.

    sudo nano /etc/grafana/grafana.ini

Locate the `[auth.github]` heading, and uncomment this section by removing the `;` at the beginning of every line, except `;team_ids=`, which we won’t be using in this tutorial.

Then, configure Grafana to use GitHub with your OAuth application’s `client_id` and `client_secret` values.

- Set `enabled` and `allow_sign_up` to true. This will enable GitHub Authentication and permit members of the allowed organization to create accounts themselves. Note that this setting is different than the `allow_sign_up` property under `[users]` that you changed in Step 4.
- Set `client_id` and `client_secret` to the values you got while creating your GitHub OAuth application. 
- Set `allowed_organizations` to the name of your organization to ensure that only members of your organization can sign up and log into Grafana. 

The complete configuration should look like:

/etc/grafana/grafana.ini

    ...
    [auth.github]
    enabled = true
    allow_sign_up = true
    client_id = your_client_id_from_github
    client_secret = your_client_secret_from_github
    scopes = user:email,read:org
    auth_url = https://github.com/login/oauth/authorize
    token_url = https://github.com/login/oauth/access_token
    api_url = https://api.github.com/user
    ;team_ids =
    allowed_organizations = your_organization_name
    ...

You’ve now told Grafana everything it needs to know about GitHub, but to complete the setup, you’ll need to enable redirects behind a reverse proxy. This is done by setting a `root_url` value under the `[server]` heading.

/etc/grafana/grafana.ini

    ...
    [server]
    root_url = https://example.com
    ...

Save your configuration and close the file.

Then, restart Grafana to activate the changes.

    sudo systemctl restart grafana-server

Lastly, verify that the service is up and running.

    sudo systemctl status grafana-server

If the output doesn’t indicate that the service is `active (running)`, consult the on-screen messages for more information.

Now, test your new authentication system by navigating to `https://example.com`. If you are already logged into Grafana, click on the small Grafana logo in the upper, left-hand corner of the screen, hover your mouse over your username, and click on **Sign out** in the secondary menu that appears to the right of your name.

On the login page, you’ll see a new section under the original **Log in** button that includes a **GitHub** button with the GitHub logo.

![Grafana Login page with GitHub](http://assets.digitalocean.com/articles/install-and-secure-grafana/login-with-github.png)

Click on the **GitHub** button to be redirected to GitHub, where you’ll need to confirm your intention to **Authorize Grafana**.

Click the green, **Authorize your\_github\_organization** button. In this example, the button reads, **Authorize SharkTheSammy**.

![Authorize with GitHub](http://assets.digitalocean.com/articles/install-and-secure-grafana/authorize-grafana.png)

If you try to authenticate with a GitHub account that isn’t a member of your approved organization, you’ll get a **Login Failed** message telling you, **User not a member of one of the required organizations**.

If the GitHub account is a member of your approved organization and your Grafana email address matches your GitHub email address, you will be logged in with your existing Grafana account.

But, if a Grafana account doesn’t already exist for the user you logged in as, Grafana will create a new user account with **Viewer** permissions, ensuring that new users can only use existing dashboards.

To change the default permissions for new users, open the main Grafana configuration file for editing.

    sudo nano /etc/grafana/grafana.ini

Locate the `auto_assign_org_role` directive under the `[users]` heading, and uncomment the setting by removing the `;` at the beginning of the line.

Set the directive to one of the following values:

- `Viewer` — can only use existing dashboards
- `Editor` — can change use, modify, and add dashboards
- `Admin` — has permission to do everything

/etc/grafana/grafana.ini

    ...
    [users]
    ...
    auto_assign_org_role = Viewer
    ...

Once you’ve saved your changes, close the file and restart Grafana.

    sudo systemctl restart grafana-server

Check the service’s status.

    sudo systemctl status grafana-server

Like before, the status should read `active (running)`. If it doesn’t, review the output for further instructions.

At this point, you have fully configured Grafana to allow members of your GitHub organization to register and use your Grafana installation.

## Conclusion

In this tutorial you installed, configured, and secured Grafana, and you also learned how to permit members of your organization to authenticate through GitHub.

To use Grafana as part of a system-monitoring software stack, see [How To Install Prometheus on Ubuntu 16.04](how-to-install-prometheus-on-ubuntu-16-04) and [How To Add a Prometheus Dashboard to Grafana](how-to-add-a-prometheus-dashboard-to-grafana).

To extend your current Grafana installation, see the [list of official and community-built dashboards](https://grafana.com/dashboards).

And, to learn more about using Grafana in general, see the [official Grafana documentation](http://docs.grafana.org/).
