---
author: Brian Hogan, Brian Boucheron
date: 2019-07-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-10
---

# How To Install Java with Apt on Debian 10

## Introduction

Java and the JVM (Java Virtual Machine) are required for many kinds of software, including [Tomcat](http://tomcat.apache.org/), [Jetty](https://www.eclipse.org/jetty/), [Glassfish](https://javaee.github.io/glassfish/), [Cassandra](https://cassandra.apache.org/) and [Jenkins](https://jenkins.io/).

In this guide, you will install different versions of the Java Runtime Environment (JRE) and the Java Developer Kit (JDK) using Debian’s `apt` package management system.

You’ll install OpenJDK 11 as well as the official Java 11 software from Oracle. You’ll then select the version you wish to use for your projects. When you’re finished, you’ll be able to use the JDK to develop software or use the Java Runtime to run software.

## Prerequisites

To begin this tutorial, you will need:

- One Debian 10 server with a non-root, `sudo`-enabled user. You can set this up by following our [Debian 10 initial server setup guide](initial-server-setup-with-debian-10).

## Installing the Default JRE/JDK

The easiest option for installing Java is to use the version packaged with Debian. By default, Debian 10 includes OpenJDK version 11, which is an open-source variant of the JRE and JDK, and is compatible with Java 11.

Java 11 is the current Long Term Support version of Java.

To install the OpenJDK version of Java, first update your `apt` package index:

    sudo apt update

Next, check if Java is already installed:

    java -version

If Java is not currently installed, you’ll see the following output:

    Output-bash: java: command not found

Then use the `apt install` command to install OpenJDK:

    sudo apt install default-jre

This will install the Java Runtime Environment (JRE), allowing you to run almost all Java software.

Verify the installation with:

    java -version

You’ll see the following output:

    Outputopenjdk version "11.0.4" 2019-07-16
    OpenJDK Runtime Environment (build 11.0.4+11-post-Debian-1deb10u1)
    OpenJDK 64-Bit Server VM (build 11.0.4+11-post-Debian-1deb10u1, mixed mode, sharing)

You may also need the Java Development Kit (JDK) in order to compile and run some specific Java-based software. To install the JDK, execute the following command:

    sudo apt install default-jdk

Verify that the JDK is installed by checking the version of `javac`, the Java compiler:

    javac -version

You’ll see the following output:

    Outputjavac 11.0.4

Next, let’s look at how to install Oracle’s official JDK and JRE.

## Installing the Oracle JDK

To install the official Oracle JDK, we’ll need to download some files directly from Oracle, then install them using an installer we’ll fetch from a third-party repository.

First, let’s download Java from Oracle’s website.

### Downloading Oracle’s Java SE Software Package

Due to recent changes in the way Oracle handles Java licensing, you’ll need to create an Oracle account and download the software directly from their website before continuing with the installation.

If you don’t already have an Oracle account, create one at [Oracle’s account creation page](https://profile.oracle.com/myprofile/account/create-account.jspx).

Afterwards, navigate to [Oracle’s Java SE Downloads page](https://www.oracle.com/technetwork/java/javase/downloads/index.html):

![the Oracle Java downloads webpage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apt-install-java/downloads-page.png)

We need to make sure we’re downloading the correct version of Java, because it needs to match what the installer is expecting. We can check what version the installer needs by visiting the [package listing](https://launchpad.net/%7Elinuxuprising/+archive/ubuntu/java/+packages) of the installer’s software repository.

We’ll download the install from this repository in the next step, but for now look for the `oracle-java11-installer-local...` files:

![a screenshot of the linuxuprising java installer package list](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apt-install-java/package-list.png)

In this case, we can see that the installer is expecting version 11.0.4. Ignore any number that comes after the `-` hyphen in the package version number (`1` in the example screenshot above).

Now that we know the correct version number, scroll down the Java download page until you find the correct version:

![a screenshot showing the location of the Oracle JDK download button](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apt-install-java/download-link.png)

Press the download button, and you’ll be taken to one final screen:

![a screenshot of the Java download options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apt-install-java/download-selection.png)

Select the **Accept License Agreement** radio button, then click the `.tar.gz` package for Linux, and your download will begin. You may need to log in to your Oracle account one more time before the download starts.

After the download has finished, we need to get the downloaded file onto our server. We will use the `scp` command to do so, but you could use any file transfer software you’re comfortable with.

On your local computer, use `scp` to upload the file to your server. The following command assumes your file downloaded to a **Downloads** directory in your user’s home folder, and will upload to the **sammy** user’s home directory on the server. Adjust the file paths as needed for your systems:

    scp ~/Downloads/jdk-11.0.4_linux-x64_bin.tar.gz sammy@your_server_ip:~

Now that we’ve got the correct Java software package up on our server, let’s add the repo that contains the installer we’ll use to install Java.

### Adding the Installer’s Apt Repository

First, install the `software-properties-common` package, which adds the `add-apt-repository` command to your system:

    sudo apt install software-properties-common

Next, import the signing key used to verify the software we’re about to install:

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EA8CACC073C3DB2A

Then we use the `add-apt-repository` command to add the repo to our list of package sources:

    sudo add-apt-repository ppa:linuxuprising/java

You’ll see this message:

    Output Oracle Java 11 (LTS) and 12 installer for Ubuntu, Linux Mint and Debian.
    
    Java binaries are not hosted in this PPA due to licensing. The packages in this PPA download and install Oracle Java 11, so a working Internet connection is required.
    
    The packages in this PPA are based on the WebUpd8 Oracle Java PPA packages: https://launchpad.net/~webupd8team/+archive/ubuntu/java
    
    Created for users of https://www.linuxuprising.com/
    
    Installation instructions (with some tips), feedback, suggestions, bug reports etc.:
    
    . . .
    
    Press [ENTER] to continue or ctrl-c to cancel adding it

Press `ENTER` to continue the installation. You’ll may see a message about `no valid OpenPGP data found`. This can be ignored.

Finally, update your package list to make the new software available for installation:

    sudo apt update

Next we’ll, install the Java package using the new software we just made available.

### Installing the Downloaded Java Software

First, we need to create a specific directory that the installer uses to find the Java software package, then copy the `.tar.gz` file in:

    sudo mkdir -p /var/cache/oracle-jdk11-installer-local/
    sudo cp ~/jdk-11.0.4_linux-x64_bin.tar.gz /var/cache/oracle-jdk11-installer-local/

Once the file copy is complete, install Oracle’s Java 11 by installing the `oracle-java11-installer-local` package:

    sudo apt install oracle-java11-installer-local

The installer will first ask you to accept the Oracle license agreement. Accept the agreement, then the installer will extract the Java package and install it.

Now that we have multiple versions of Java installed, let’s look at how to select which version of Java you want to use.

## Managing Java

You can have multiple Java installations on one server. You can configure which version is the default for use on the command line by using the `update-alternatives` command.

    sudo update-alternatives --config java

This is what the output would look like if you’ve installed both versions of Java in this tutorial:

    OutputThere are 2 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
      0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1111 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1111 manual mode
    * 2 /usr/lib/jvm/java-11-oracle/bin/java 1091 manual mode
    
    Press <enter> to keep the current choice[*], or type selection number:

Choose the number associated with the Java version to use it as the default, or press `ENTER` to leave the current settings in place.

You can do this for other Java commands, such as the compiler (`javac`):

    sudo update-alternatives --config javac

Other commands for which this command can be run include, but are not limited to: `keytool`, `javadoc`, and `jarsigner`.

Let’s set the `JAVA_HOME` environment variable next.

## Setting the `JAVA_HOME` Environment Variable

Many programs written in Java use the `JAVA_HOME` environment variable to determine which Java installation location to use.

To set this environment variable, first determine where Java is installed. Use the `update-alternatives` command again:

    sudo update-alternatives --config java

This command shows each installation of Java along with its installation path:

    Output Selection Path Priority Status
    ------------------------------------------------------------
      0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1111 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1111 manual mode
    * 2 /usr/lib/jvm/java-11-oracle/bin/java 1091 manual mode

In this case the installation paths are as follows:

- Oracle Java 11 is located at `/usr/lib/jvm/java-11-oracle/bin/java`.
- OpenJDK 11 is located at `/usr/lib/jvm/java-11-openjdk-amd64/bin/java`.

These paths show the path to the `java` executable.

Copy the path for your preferred installation, excluding the trailing `bin/java` component. Then open `/etc/environment` using `nano` or your favorite text editor:

    sudo nano /etc/environment

This file may be blank initially. At the end of the file, add the following line, making sure to replace the highlighted path with your own copied path:

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-11-oracle/"

Modifying this file will set the `JAVA_HOME` path for all users on your system.

Save the file and exit the editor.

Now reload this file to apply the changes to your current session:

    source /etc/environment

Verify that the environment variable is set:

    echo $JAVA_HOME

You’ll see the path you just set:

    Output/usr/lib/jvm/java-11-oracle/

Other users will need to execute the command `source /etc/environment` or log out and log back in to apply this setting.

## Conclusion

In this tutorial you installed multiple versions of Java and learned how to manage them. You can now install software which runs on Java, such as Tomcat, Jetty, Glassfish, Cassandra or Jenkins.
