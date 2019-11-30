---
author: Melissa Anderson
date: 2017-05-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-16-04
---

# How To Install Jenkins on Ubuntu 16.04

## Introduction

Jenkins is an open source automation server intended to automate repetitive technical tasks involved in the continuous integration and delivery of software. Jenkins is Java-based and can be installed from Ubuntu packages or by downloading and running its Web application ARchive (WAR) file — a collection of files that make up a complete web application which is intended to be run on a server.

In this tutorial we will install Jenkins by adding its Debian package repository, then using that repository to install the package using `apt-get`.

### Prerequisites

To follow this tutorial, you will need:

**One Ubuntu 16.04 server** configured with a non-root `sudo` user and a firewall by following the [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04). We recommend starting with at least 1 GB of RAM. See [Choosing the Right Hardware for Masters](https://jenkins.io/doc/book/hardware-recommendations/) for guidance in planning the capacity of a production Jenkins installation.

When the server is set up, you’re ready to follow along.

## Step 1 — Installing Jenkins

The version of Jenkins included with the default Ubuntu packages is often behind the latest available version from the project itself. In order to take advantage of the latest fixes and features, we’ll use the project-maintained packages to install Jenkins.

First, we’ll add the repository key to the system.

    wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -

When the key is added, the system will return `OK`. Next, we’ll append the Debian package repository address to the server’s `sources.list`:

    echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

When both of these are in place, we’ll run `update` so that `apt-get` will use the new repository:

    sudo apt-get update

Finally, we’ll install Jenkins and its dependencies, including Java:

    sudo apt-get install jenkins

Now that Jenkins and its dependencies are in place, we’ll start the Jenkins server.

## Step 2 — Starting Jenkins

Using `systemctl` we’ll start Jenkins:

    sudo systemctl start jenkins

Since `systemctl` doesn’t display output, we’ll use its `status` command to verify that it started successfully:

    sudo systemctl status jenkins

If everything went well, the beginning of the output should show that the service is active and configured to start at boot:

    Output● jenkins.service - LSB: Start Jenkins at boot time
      Loaded: loaded (/etc/init.d/jenkins; bad; vendor preset: enabled)
      Active:active (exited) since Thu 2017-04-20 16:51:13 UTC; 2min 7s ago
        Docs: man:systemd-sysv-generator(8)

Now that Jenkins is running, we’ll adjust our firewall rules so that we can reach Jenkins from a web browser to complete the initial set up.

## Step 3 — Opening the Firewall

By default, Jenkins runs on port 8080, so we’ll open that port using `ufw`:

    sudo ufw allow 8080

We can see the new rules by checking UFW’s status.

    sudo ufw status

We should see that traffic is allowed to port 8080 from anywhere:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    8080 ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    8080 (v6) ALLOW Anywhere (v6)

**Note:** If the firewall is inactive, the following commands will make sure that OpenSSH is allowed and then enable it.

    sudo ufw allow OpenSSH
    sudo ufw enable

Now that Jenkins is installed and the firewall allows us to access it, we can complete the initial setup.

## Step 4 — Setting up Jenkins

To set up our installation, we’ll visit Jenkins on its default port, `8080`, using the server domain name or IP address: `http://ip_address_or_domain_name:8080`

We should see “Unlock Jenkins” screen, which displays the location of the initial password

![Unlock Jenkins screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/unlock-jenkins.png)

In the terminal window, we’ll use the `cat` command to display the password:

    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

We’ll copy the 32-character alphanumeric password from the terminal and paste it into the “Administrator password” field, then click “Continue”. The next screen presents the option of installing suggested plugins or selecting specific plugins.

![Customize Jenkins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/jenkins-customize.png)

We’ll click the “Install suggested plugins” option, which will immediately begin the installation process:

![Jenkins Getting Started Install Plugins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/jenkins-plugins.png)

When the installation is complete, we’ll be prompted to set up the first administrative user. It’s possible to skip this step and continue as `admin` using the initial password we used above, but we’ll take a moment to create the user.

**Note:** The default Jenkins server is NOT encrypted, so the data submitted with this form is not protected. When you’re ready to use this installation, follow the guide [How to Configure Jenkins with SSL using an Nginx Reverse Proxy](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy). This will protect user credentials and information about builds that are transmitted via the Web interface.

![Jenkins Create First Admin User Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/jenkins-first-admin.png)

Once the first admin user is in place, you should see a “Jenkins is ready!” confirmation screen.

![Jenkins is ready screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/jenkins-ready.png)  
Click “Start using Jenkins” to visit the main Jenkins dashboard:

![Welcome to Jenkins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/jenkins-using.png)

At this point, Jenkins has been successfully installed.

## Conclusion

In this tutorial, we’ve installed Jenkins using the project-provided packages, started the server, opened the firewall, and created an administrative user. At this point, you can start exploring Jenkins.

When you’ve completed your exploration, if you decide to continue using Jenkins, follow the guide, [How to Configure Jenkins with SSL using an Nginx Reverse Proxy](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy) in order to protect passwords, as well as any sensitive system or product information that will be sent between your machine and the server in plain text.
