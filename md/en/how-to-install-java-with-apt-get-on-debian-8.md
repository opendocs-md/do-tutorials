---
author: Lisa Tagliaferri
date: 2016-12-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-debian-8
---

# How To Install Java with Apt-Get on Debian 8

## Introduction

The programming language Java and the Java virtual machine or **JVM** are used extensively and required for many kinds of software.

This tutorial provides different ways of installing Java on Debian 8: you can download the [Default JRE or JDK](how-to-install-java-with-apt-get-on-debian-8#installing-the-default-jrejdk) or the [Oracle JDK](how-to-install-java-with-apt-get-on-debian-8#installing-the-oracle-jdk). If you decide to install multiple versions of Oracle Java, you can follow the section on [managing Java](how-to-install-java-with-apt-get-on-debian-8#managing-java). The last section outlines [setting the JAVA\_HOME environment variable](how-to-install-java-with-apt-get-on-debian-8#setting-the-java_home-environment-variable)

## Prerequisites

To follow this tutorial, you will need:

- One Debian 8 server.
- A sudo non-root user, which you can set up by following [the Debian 8 initial server setup guide](initial-server-setup-with-debian-8).

## Installing the Default JRE/JDK

The easiest option for installing Java is using the version packaged with Debian. Specifically, this will install OpenJDK 8, the latest and recommended version.

First, update the package index.

    sudo apt-get update

Next, install Java. Specifically, this command will install the Java Runtime Environment (JRE).

    sudo apt-get install default-jre

When prompted, type `y` for yes to confirm the installation.

There is another default Java installation called the JDK (Java Development Kit). The JDK is usually only needed if you are going to compile Java programs or if the software that will use Java specifically requires it.

The JDK does contain the JRE, so there are no disadvantages if you install the JDK instead of the JRE, except for the larger file size.

You can install the JDK with the following command:

    sudo apt-get install default-jdk

You now have the Java Runtime Environment or the Java Development Kit installed.

## Installing the Oracle JDK

If you want to install the Oracle JDK, which is the official version distributed by Oracle, you’ll need to follow a few more steps. You’ll first need to install the `software-properties-common` package in order to use the `apt-get-repository` command. This will work to add the repository to your sources list and import the associated key.

    sudo apt-get install software-properties-common

When prompted to confirm the installation, type `y` for yes.

To ensure that we get the correct source line on Debian, we’ll need to run the following command that also modifies the line:

    sudo add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main"

Once we do that we’ll need to update:

    sudo apt-get update

Now we’ll go through the installation process of different versions of Java. You can decide which versions you would like to install, and can choose to install one or several. Because it’s the latest stable release, Oracle JDK 8 is the recommended version at the time of writing.

### Oracle JDK 8

Oracle JDK 8 is the latest stable version of Java at time of writing. You can install it using the following command:

    sudo apt-get install oracle-java8-installer

Again, you’ll be prompted to type `y` to confirm the install. You’ll also be required to accept the Oracle Binary Code license terms. Use the arrow key to select “Yes”, then press “Enter” to accept the license.   
Once the installation is complete, you can verify your Java version:

    javac -version

You’ll receive output similar to this:

    Outputjavac 1.8.0_111

At this point, you have Oracle JDK 8 installed, but you may want to also install one or more of the versions below. If you’re ready to get started, skip down to the [Managing Java](how-to-install-java-with-apt-get-on-debian-8#setting-the-java_home-environment-variable) section below.

### Oracle JDK 9

Oracle JDK 9 is currently available for early access through its developer preview. The general release is scheduled for summer 2017. There is more information about Java 9 on the [official JDK 9 website](http://jdk.java.net/9/).

To install JDK 9, use the following command:

    sudo apt-get install oracle-java9-installer

While it may be worth investigating Oracle JDK 9, there may still be security issues and bugs, so you should opt for Oracle JDK 8 as your default version.

## Managing Java

There can be multiple Java installations on one server. You can configure which version is the default for use in the command line by using `update-alternatives`, which manages which symbolic links are used for different commands.

    sudo update-alternatives --config java

The output will look something like the following. In this case, all Java versions mentioned above were installed.

Output

    There are 4 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
      0 /usr/lib/jvm/java-9-oracle/bin/java 1091 auto mode
      1 /usr/lib/jvm/java-6-oracle/jre/bin/java 1083 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1082 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode
    * 4 /usr/lib/jvm/java-9-oracle/bin/java 1091 manual mode
    
    Press enter to keep the current choice[*], or type selection number: 
    
    
    
    Press <enter> to keep the current choice[*], or type selection number:

If we press the enter key in this case, Java 9 will be kept as the default. We can, for example, press `3` for Java 8 and receive the following output:

    Outputupdate-alternatives: using /usr/lib/jvm/java-8-oracle/jre/bin/java to provide /usr/bin/java (java) in manual mode

Now Java 8 would be the default. Choose the default Java version that works best for your projects.

The `update-alternatives` command can also be used for other Java commands, such as the compiler (`javac`), the documentation generator (`javadoc`), the JAR signing tool (`jarsigner`), and more. You can use the following command, filling in the command you want to customize.

    sudo update-alternatives --config command

This will give us greater control over what default version of Java to use in each case.

## Setting the JAVA\_HOME Environment Variable

Many programs, such as Java servers, use the `JAVA_HOME` environment variable to determine the Java installation location. To set this environment variable, we will first need to find out where Java is installed. You can do this by executing the same command as in the previous section:

    sudo update-alternatives --config java

Copy the path from your preferred installation, and then open `/etc/environment` using `nano` or your favorite text editor.

    sudo nano /etc/environment

In this file, add the following line, making sure to replace the highlighted path with your own copied path.

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-8-oracle"

Save and exit the file, and reload it.

    source /etc/environment

You can now test whether the environment variable has been set by executing the following command:

    echo $JAVA_HOME

This will return the path you just set.

## Conclusion

You have now installed Java and know how to manage different versions of it. You can now install software which runs on Java, such as Tomcat, Jetty, Glassfish, Cassandra, or Jenkins.
