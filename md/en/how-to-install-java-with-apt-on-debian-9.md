---
author: Brian Hogan
date: 2018-09-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-debian-9
---

# How To Install Java with Apt on Debian 9

## Introduction

Java and the JVM (Java’s virtual machine) are required for many kinds of software, including [Tomcat](http://tomcat.apache.org/), [Jetty](https://www.eclipse.org/jetty/), [Glassfish](https://javaee.github.io/glassfish/), [Cassandra](http://cassandra.apache.org/) and [Jenkins](https://jenkins.io/).

In this guide, you will install various versions of the Java Runtime Environment (JRE) and the Java Developer Kit (JDK) using `apt` . You’ll install OpenJDK as well as official packages from Oracle. You’ll then select the version you wish to use for your projects. When you’re finished, you’ll be able to use the JDK to develop software or use the Java Runtime to run software.

## Prerequisites

To follow this tutorial, you will need:

- One Debian 9 server set up by following the [the Debian 9 initial server setup guide](initial-server-setup-with-debian-9) tutorial, including a non-root user with `sudo` access and a firewall.

## Installing the Default JRE/JDK

The easiest option for installing Java is to use the version packaged with Debian. By default, Debian 9 includes Open JDK, which is an open-source variant of the JRE and JDK.

This package will install OpenJDK version 1.8, which is compatible with Java 8. Java 8 is the current Long Term Support version and is still widely supported, though public maintenance ends in January 2019.

To install this version, first update the package index:

    sudo apt update

Next, check if Java is already installed:

    java -version

If Java is not currently installed, you’ll see the following output:

    Output-bash: java: command not found

Execute the following command to install OpenJDK:

    sudo apt install default-jre

This command will install the Java Runtime Environment (JRE). This will allow you to run almost all Java software.

Verify the installation with:

    java -version

You’ll see the following output:

    Outputopenjdk version "1.8.0_181"
    OpenJDK Runtime Environment (build 1.8.0_181-8u181-b13-1~deb9u1-b13)
    OpenJDK 64-Bit Server VM (build 25.181-b13, mixed mode)

You may need the Java Development Kit (JDK) in addition to the JRE in order to compile and run some specific Java-based software. To install the JDK, execute the following command, which will also install the JRE:

    sudo apt install default-jdk

Verify that the JDK is installed by checking the version of `javac`, the Java compiler:

    javac -version

You’ll see the following output:

    Outputjavac 1.8.0_181

Next, let’s look at how to install Oracle’s official JDK and JRE.

## Installing the Oracle JDK

If you want to install the Oracle JDK, which is the official version distributed by Oracle, you’ll need to add a new package repository for the version you’d like to use.

First, install the `software-properties-common` package which adds the `apt-get-repository` command which you’ll use to add additional repositories to your sources list.

Install `software-properties-common` with:

    sudo apt install software-properties-common

With this installed, you can install Oracle’s Java.

### Installing Oracle Java 8

To install Java 8, which is the current long-term support version, first add its package repository:

    sudo add-apt-repository ppa:webupd8team/java

When you add the repository, you’ll see a message like this:

    output Oracle Java (JDK) Installer (automatically downloads and installs Oracle JDK8). There are no actual Java files in this PPA.
    
    Important -> Why Oracle Java 7 And 6 Installers No Longer Work: http://www.webupd8.org/2017/06/why-oracle-java-7-and-6-installers-no.html
    
    Update: Oracle Java 9 has reached end of life: http://www.oracle.com/technetwork/java/javase/downloads/jdk9-downloads-3848520.html
    
    The PPA supports Ubuntu 18.04, 17.10, 16.04, 14.04 and 12.04.
    
    More info (and Ubuntu installation instructions):
    - for Oracle Java 8: http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html
    
    Debian installation instructions:
    - Oracle Java 8: http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
    
    For Oracle Java 10, see a different PPA: https://www.linuxuprising.com/2018/04/install-oracle-java-10-in-ubuntu-or.html
     More info: https://launchpad.net/~webupd8team/+archive/ubuntu/java
    Press [ENTER] to continue or ctrl-c to cancel adding it

Press `ENTER` to continue. It will attempt to import some GPG signing keys, but it won’t be able to find any valid ones:

    Outputgpg: keybox '/tmp/tmpgt9wdvth/pubring.gpg' created
    gpg: /tmp/tmpgt9wdvth/trustdb.gpg: trustdb created
    gpg: key C2518248EEA14886: public key "Launchpad VLC" imported
    gpg: no ultimately trusted keys found
    gpg: Total number processed: 1
    gpg: imported: 1
    gpg: no valid OpenPGP data found.

Execute the following command to add the GPG key for the repository source manually:

    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886

Then update your package list:

    sudo apt update

Once the package list updates, install Java 8:

    sudo apt install oracle-java8-installer

Your system will download the JDK from Oracle and ask you to accept the license agreement. Accept the agreement and the JDK will install.

### Installing Oracle Java 10

To install Oracle Java 10, first add its repository:

    sudo add-apt-repository ppa:linuxuprising/java

You’ll see this message:

    Output Oracle Java 10 installer
    
    Java binaries are not hosted in this PPA due to licensing. The packages in this PPA download and install Oracle Java 10 (JDK 10), so a working Internet connection is required.
    
    The packages in this PPA are based on the WebUpd8 Oracle Java PPA packages: https://launchpad.net/~webupd8team/+archive/ubuntu/java
    
    Created for users of https://www.linuxuprising.com/
    
    Issues or suggestions? Leave a comment here: https://www.linuxuprising.com/2018/04/install-oracle-java-10-in-ubuntu-or.html
     More info: https://launchpad.net/~linuxuprising/+archive/ubuntu/java
    Press [ENTER] to continue or ctrl-c to cancel adding it

Press `ENTER` to continue the installation. Like with Java 8, you’ll see a message about invalid signing keys:

    Outputgpg: keybox '/tmp/tmpvuqsh9ui/pubring.gpg' created
    gpg: /tmp/tmpvuqsh9ui/trustdb.gpg: trustdb created
    gpg: key EA8CACC073C3DB2A: public key "Launchpad PPA for Linux Uprising" imported
    gpg: Total number processed: 1
    gpg: imported: 1
    gpg: no valid OpenPGP data found.
    

Execute this command to import the necessary key:

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EA8CACC073C3DB2A

Then update your package list:

    sudo apt update

Once the package list updates, install Java 10:

    sudo apt install oracle-java10-installer

Your system will download the JDK from Oracle and ask you to accept the license agreement. Accept the agreement and the JDK will install.

Now let’s look at how to select which version of Java you want to use.

## Managing Java

You can have multiple Java installations on one server. You can configure which version is the default for use on the command line by using the `update-alternatives` command.

    sudo update-alternatives --config java

This is what the output would look like if you’ve installed all versions of Java in this tutorial:

    OutputThere are 3 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
      0 /usr/lib/jvm/java-10-oracle/bin/java 1091 auto mode
    * 1 /usr/lib/jvm/java-10-oracle/bin/java 1091 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode
    
    Press <enter> to keep the current choice[*], or type selection number:

Choose the number associated with the Java version to use it as the default, or press `ENTER` to leave the current settings in place.

You can do this for other Java commands, such as the compiler (`javac`):

    sudo update-alternatives --config javac

Other commands for which this command can be run include, but are not limited to: `keytool`, `javadoc` and `jarsigner`.

Let’s set the `JAVA_HOME` environment variable next.

## Setting the `JAVA_HOME` Environment Variable

Many programs written using Java use the `JAVA_HOME` environment variable to determine the Java installation location.

To set this environment variable, first determine where Java is installed. Use the `update-alternatives` command again:

    sudo update-alternatives --config java

This command shows each installation of Java along with its installation path:

    Output Selection Path Priority Status
    ------------------------------------------------------------
      0 /usr/lib/jvm/java-10-oracle/bin/java 1091 auto mode
    * 1 /usr/lib/jvm/java-10-oracle/bin/java 1091 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode

In this case the installation paths are as follows:

- Oracle Java 10 is located at `/usr/lib/jvm/java-10-oracle/jre/bin/java`.
- Oracle Java 8 is located at `/usr/lib/jvm/java-8-oracle/jre/bin/java`.
- OpenJDK 8 is located at `/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java`.

These paths show the path to the `java` executable.

Copy the path for your preferred installation, excluding the trailing `bin/java` component. Then open `/etc/environment` using `nano` or your favorite text editor:

    sudo nano /etc/environment

At the end of this file, add the following line, making sure to replace the highlighted path with your own copied path:

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-8-oracle/jre"

Modifying this file will set the `JAVA_HOME` path for all users on your system.

Save the file and exit the editor.

Now reload this file to apply the changes to your current session:

    source /etc/environment

Verify that the environment variable is set:

    echo $JAVA_HOME

You’ll see the path you just set:

    Output/usr/lib/jvm/java-8-oracle/jre

Other users will need to execute the command `source /etc/environment` or log out and log back in to apply this setting.

## Conclusion

In this tutorial you installed multiple versions of Java and learned how to manage them. You can now install software which runs on Java, such as Tomcat, Jetty, Glassfish, Cassandra or Jenkins.
