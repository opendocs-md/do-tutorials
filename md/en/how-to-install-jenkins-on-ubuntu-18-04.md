---
author: Melissa Anderson, Kathleen Juell
date: 2018-07-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-18-04
---

# How To Install Jenkins on Ubuntu 18.04

## Introduction

[Jenkins](https://jenkins.io/) is an open-source automation server that automates the repetitive technical tasks involved in the continuous integration and delivery of software. Jenkins is Java-based and can be installed from Ubuntu packages or by downloading and running its web application archive (WAR) file — a collection of files that make up a complete web application to run on a server.

In this tutorial, you will install Jenkins by adding its Debian package repository, and using that repository to install the package with `apt`.

### Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 18.04 server configured with a non-root sudo user and firewall by following the [Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04). We recommend starting with at least 1 GB of RAM. See [Choosing the Right Hardware for Masters](https://jenkins.io/doc/book/hardware-recommendations/) for guidance in planning the capacity of a production Jenkins installation.
- Java 8 installed, following our guidelines on [installing specific versions of OpenJDK on Ubuntu 18.04](how-to-install-java-with-apt-on-ubuntu-18-04#installing-specific-versions-of-openjdk).

## Step 1 — Installing Jenkins

The version of Jenkins included with the default Ubuntu packages is often behind the latest available version from the project itself. To take advantage of the latest fixes and features, you can use the project-maintained packages to install Jenkins.

First, add the repository key to the system:

    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

When the key is added, the system will return `OK`. Next, append the Debian package repository address to the server’s `sources.list`:

    sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

When both of these are in place, run `update` so that `apt` will use the new repository:

    sudo apt update

Finally, install Jenkins and its dependencies:

    sudo apt install jenkins

Now that Jenkins and its dependencies are in place, we’ll start the Jenkins server.

## Step 2 — Starting Jenkins

Let’s start Jenkins using `systemctl`:

    sudo systemctl start jenkins

Since `systemctl` doesn’t display output, you can use its `status` command to verify that Jenkins started successfully:

    sudo systemctl status jenkins

If everything went well, the beginning of the output should show that the service is active and configured to start at boot:

    Output● jenkins.service - LSB: Start Jenkins at boot time
       Loaded: loaded (/etc/init.d/jenkins; generated)
       Active: active (exited) since Mon 2018-07-09 17:22:08 UTC; 6min ago
         Docs: man:systemd-sysv-generator(8)
        Tasks: 0 (limit: 1153)
       CGroup: /system.slice/jenkins.service

Now that Jenkins is running, let’s adjust our firewall rules so that we can reach it from a web browser to complete the initial setup.

## Step 3 — Opening the Firewall

By default, Jenkins runs on port `8080`, so let’s open that port using `ufw`:

    sudo ufw allow 8080

Check `ufw`’s status to confirm the new rules:

    sudo ufw status

You will see that traffic is allowed to port `8080` from anywhere:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    8080 ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    8080 (v6) ALLOW Anywhere (v6)

**Note:** If the firewall is inactive, the following commands will allow OpenSSH and enable the firewall:

    sudo ufw allow OpenSSH
    sudo ufw enable

With Jenkins installed and our firewall configured, we can complete the initial setup.

## Step 4 — Setting Up Jenkins

To set up your installation, visit Jenkins on its default port, `8080`, using your server domain name or IP address: `http://your_server_ip_or_domain:8080`

You should see the **Unlock Jenkins** screen, which displays the location of the initial password:

![Unlock Jenkins screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1604/unlock-jenkins.png)

In the terminal window, use the `cat` command to display the password:

    sudo cat /var/lib/jenkins/secrets/initialAdminPassword

Copy the 32-character alphanumeric password from the terminal and paste it into the **Administrator password** field, then click **Continue**.

The next screen presents the option of installing suggested plugins or selecting specific plugins:

![Customize Jenkins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/customize_jenkins_screen_two.png)

We’ll click the **Install suggested plugins** option, which will immediately begin the installation process:

![Jenkins Getting Started Install Plugins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/jenkins_plugin_install_two.png)

When the installation is complete, you will be prompted to set up the first administrative user. It’s possible to skip this step and continue as `admin` using the initial password we used above, but we’ll take a moment to create the user.

**Note:** The default Jenkins server is NOT encrypted, so the data submitted with this form is not protected. When you’re ready to use this installation, follow the guide [How to Configure Jenkins with SSL Using an Nginx Reverse Proxy on Ubuntu 18.04](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy-on-ubuntu-18-04). This will protect user credentials and information about builds that are transmitted via the web interface.

![Jenkins Create First Admin User Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/jenkins_create_user.png)

Enter the name and password for your user:

![Jenkins Create User](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/jenkins_user_info.png)

You will see an **Instance Configuration** page that will ask you to confirm the preferred URL for your Jenkins instance. Confirm either the domain name for your server or your server’s IP address:

![Jenkins Instance Configuration](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/instance_confirmation.png)

After confirming the appropriate information, click **Save and Finish**. You will see a confirmation page confirming that **“Jenkins is Ready!”** :

![Jenkins is ready screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/jenkins_ready_page_two.png)

Click **Start using Jenkins** to visit the main Jenkins dashboard:

![Welcome to Jenkins Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jenkins-install-ubuntu-1804/jenkins_home_page.png)

At this point, you have completed a successful installation of Jenkins.

## Conclusion

In this tutorial, you have installed Jenkins using the project-provided packages, started the server, opened the firewall, and created an administrative user. At this point, you can start exploring Jenkins.

When you’ve completed your exploration, if you decide to continue using Jenkins, follow the guide [How to Configure Jenkins with SSL Using an Nginx Reverse Proxy on Ubuntu 18.04](how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy-on-ubuntu-18-04) to protect your passwords, as well as any sensitive system or product information that will be sent between your machine and the server in plain text.
