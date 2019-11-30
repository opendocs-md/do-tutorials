---
author: Koen Vlaswinkel
date: 2018-05-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-18-04
---

# How To Install Java with `apt` on Ubuntu 18.04

_The author selected the [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) to receive a $100 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Java and the JVM (Java’s virtual machine) are required for many kinds of software, including [Tomcat](http://tomcat.apache.org/), [Jetty](https://www.eclipse.org/jetty/), [Glassfish](https://javaee.github.io/glassfish/), [Cassandra](http://cassandra.apache.org/) and [Jenkins](https://jenkins.io/).

In this guide, you will install various versions of the Java Runtime Environment (JRE) and the Java Developer Kit (JDK) using `apt` . You’ll install OpenJDK as well as official packages from Oracle. You’ll then select the version you wish to use for your projects. When you’re finished, you’ll be able to use the JDK to develop software or use the Java Runtime to run software.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 18.04 server set up by following the [the Ubuntu 18.04 initial server setup guide](initial-server-setup-with-ubuntu-18-04) tutorial, including a sudo non-root user and a firewall.

## Installing the Default JRE/JDK

The easiest option for installing Java is to use the version packaged with Ubuntu. By default, Ubuntu 18.04 includes Open JDK, which is an open-source variant of the JRE and JDK.

This package will install either OpenJDK 10 or 11.

- Prior to September 2018, this will install OpenJDK 10. 
- After September 2018, this will install OpenJDK 11.

To install this version, first update the package index:

    sudo apt update

Next, check if Java is already installed:

    java -version

If Java is not currently installed, you’ll see the following output:

    OutputCommand 'java' not found, but can be installed with:
    
    apt install default-jre
    apt install openjdk-11-jre-headless
    apt install openjdk-8-jre-headless
    apt install openjdk-9-jre-headless

Execute the following command to install OpenJDK:

    sudo apt install default-jre

This command will install the Java Runtime Environment (JRE). This will allow you to run almost all Java software.

Verify the installation with:

    java -version

You’ll see the following output:

    Outputopenjdk version "10.0.1" 2018-04-17
    OpenJDK Runtime Environment (build 10.0.1+10-Ubuntu-3ubuntu1)
    OpenJDK 64-Bit Server VM (build 10.0.1+10-Ubuntu-3ubuntu1, mixed mode)

You may need the Java Development Kit (JDK) in addition to the JRE in order to compile and run some specific Java-based software. To install the JDK, execute the following command, which will also install the JRE:

    sudo apt install default-jdk

Verify that the JDK is installed by checking the version of `javac`, the Java compiler:

    javac -version

You’ll see the following output:

    Outputjavac 10.0.1

Next, let’s look at specifying which OpenJDK version we want to install.

## Installing Specific Versions of OpenJDK

While you can install the default OpenJDK package, you can also install different versions of OpenJDK.

### OpenJDK 8

Java 8 is the current Long Term Support version and is still widely supported, though public maintenance ends in January 2019. To install OpenJDK 8, execute the following command:

    sudo apt install openjdk-8-jdk

Verify that this is installed with

    java -version

You’ll see output like this:

    Outputopenjdk version "1.8.0_162"
    OpenJDK Runtime Environment (build 1.8.0_162-8u162-b12-1-b12)
    OpenJDK 64-Bit Server VM (build 25.162-b12, mixed mode)

It is also possible to install only the JRE, which you can do by executing `sudo apt install openjdk-8-jre`.

### OpenJDK 10/11

Ubuntu’s repositories contain a package that will install either Java 10 or 11. Prior to September 2018, this package will install OpenJDK 10. Once Java 11 is released, this package will install Java 11.

To install OpenJDK 10/11, execute the following command:

    sudo apt install openjdk-11-jdk

To install the JRE only, use the following command:

    sudo apt install openjdk-11-jre

Next, let’s look at how to install Oracle’s official JDK and JRE.

## Installing the Oracle JDK

If you want to install the Oracle JDK, which is the official version distributed by Oracle, you’ll need to add a new package repository for the version you’d like to use.

To install Java 8, which is the latest LTS version, first add its package repository:

    sudo add-apt-repository ppa:webupd8team/java

When you add the repository, you’ll see a message like this:

    output Oracle Java (JDK) Installer (automatically downloads and installs Oracle JDK8). There are no actual Jav
    a files in this PPA.
    
    Important -> Why Oracle Java 7 And 6 Installers No Longer Work: http://www.webupd8.org/2017/06/why-oracl
    e-java-7-and-6-installers-no.html
    
    Update: Oracle Java 9 has reached end of life: http://www.oracle.com/technetwork/java/javase/downloads/j
    dk9-downloads-3848520.html
    
    The PPA supports Ubuntu 18.04, 17.10, 16.04, 14.04 and 12.04.
    
    More info (and Ubuntu installation instructions):
    - for Oracle Java 8: http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html
    
    Debian installation instructions:
    - Oracle Java 8: http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
    
    For Oracle Java 10, see a different PPA: https://www.linuxuprising.com/2018/04/install-oracle-java-10-in-ubuntu-or.html
    
    More info: https://launchpad.net/~webupd8team/+archive/ubuntu/java
    Press [ENTER] to continue or Ctrl-c to cancel adding it.

Press `ENTER` to continue. Then update your package list:

    sudo apt update

Once the package list updates, install Java 8:

    sudo apt install oracle-java8-installer

Your system will download the JDK from Oracle and ask you to accept the license agreement. Accept the agreement and the JDK will install.

Now let’s look at how to select which version of Java you want to use.

## Managing Java

You can have multiple Java installations on one server. You can configure which version is the default for use on the command line by using the `update-alternatives` command.

    sudo update-alternatives --config java

This is what the output would look like if you’ve installed all versions of Java in this tutorial:

    OutputThere are 3 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode

Choose the number associated with the Java version to use it as the default, or press `ENTER` to leave the current settings in place.

You can do this for other Java commands, such as the compiler (`javac`):

    sudo update-alternatives --config javac

Other commands for which this command can be run include, but are not limited to: `keytool`, `javadoc` and `jarsigner`.

## Setting the `JAVA_HOME` Environment Variable

Many programs written using Java use the `JAVA_HOME` environment variable to determine the Java installation location.

To set this environment variable, first determine where Java is installed. Use the `update-alternatives` command:

    sudo update-alternatives --config java

This command shows each installation of Java along with its installation path:

    OutputThere are 3 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode
    
    Press <enter> to keep the current choice[*], or type selection number:

In this case the installation paths are as follows:

1. OpenJDK 11 is located at `/usr/lib/jvm/java-11-openjdk-amd64/bin/java.`
2. OpenJDK 8 is located at `/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java`.
3. Oracle Java 8 is located at `/usr/lib/jvm/java-8-oracle/jre/bin/java`.

Copy the path from your preferred installation. Then open `/etc/environment` using `nano` or your favorite text editor:

    sudo nano /etc/environment

At the end of this file, add the following line, making sure to replace the highlighted path with your own copied path:

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/"

Modifying this file will set the `JAVA_HOME` path for all users on your system.

Save the file and exit the editor.

Now reload this file to apply the changes to your current session:

    source /etc/environment

Verify that the environment variable is set:

    echo $JAVA_HOME

You’ll see the path you just set:

    Output/usr/lib/jvm/java-11-openjdk-amd64/bin/

Other users will need to execute the command `source /etc/environment` or log out and log back in to apply this setting.

## Conclusion

In this tutorial you installed multiple versions of Java and learned how to manage them. You can now install software which runs on Java, such as Tomcat, Jetty, Glassfish, Cassandra or Jenkins.
