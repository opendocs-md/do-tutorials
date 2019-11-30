---
author: Koen Vlaswinkel
date: 2014-02-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-ubuntu-12-04-with-apt-get
---

# How To Install Java on Ubuntu 12.04 with Apt-Get

## **Status:** Deprecated

This article covers a version of Ubuntu that is no longer supported. If you are currently operating a server running Ubuntu 12.04, we highly recommend upgrading or migrating to a supported version of Ubuntu:

- [Upgrade to Ubuntu 14.04](how-to-upgrade-ubuntu-12-04-lts-to-ubuntu-14-04-lts).
- [Upgrade from Ubuntu 14.04 to Ubuntu 16.04](how-to-upgrade-to-ubuntu-16-04-lts)
- [Migrate the server data to a supported version](how-to-migrate-linux-servers-part-1-system-preparation)

**Reason:** [Ubuntu 12.04 reached end of life (EOL) on April 28, 2017](https://lists.ubuntu.com/archives/ubuntu-announce/2017-March/000218.html) and no longer receives security patches or updates. This guide is no longer maintained.

**See Instead:**  
This guide might still be useful as a reference, but may not work on other Ubuntu releases. We strongly recommend using the following guide for working with Java on Ubuntu: [How To Install Java with Apt-Get on Ubuntu 16.04](how-to-install-java-with-apt-get-on-ubuntu-16-04).

## Introduction

* * *

Having Java installed is a prerequisite for many articles and programs. This tutorial will guide you through the process of installing and managing different versions of Java on Ubuntu 12.04.

## Installing default JRE/JDK

* * *

This is the recommended and easiest option. This will install OpenJDK 6 on Ubuntu 12.04 and earlier and on 12.10+ it will install OpenJDK 7.

Installing Java with `apt-get` is easy. First, update the package index:

       sudo apt-get update

Then, check if Java is not already installed:

    java -version

If it returns “The program java can be found in the following packages”, Java hasn’t been installed yet, so execute the following command:

    sudo apt-get install default-jre

This will install the Java Runtime Environment (JRE). If you instead need the Java Development Kit (JDK), which is usually needed to compile Java applications (for example [Apache Ant](http://ant.apache.org/), [Apache Maven](http://maven.apache.org/), [Eclipse](https://www.eclipse.org/) and [IntelliJ IDEA](http://www.jetbrains.com/idea/,%20etc.) execute the following command:

    sudo apt-get install default-jdk

The JDK is usually only necessary if you are going to compile Java programs or if your software specifically requires it in addition to Java. Since the JDK contains the JRE, there are no disadvantages if you install the JDK instead of the JRE, except for the larger file size.

All other steps are optional and must only be executed when needed.

## Installing OpenJDK 7 (optional)

* * *

To install OpenJDK 7, execute the following command:

    sudo apt-get install openjdk-7-jre 

This will install the Java Runtime Environment (JRE). If you instead need the Java Development Kit (JDK), execute the following command:

    sudo apt-get install openjdk-7-jdk

## Installing Oracle JDK (optional)

* * *

The Oracle JDK is the official JDK; however, it is no longer provided by Oracle as a default installation for Ubuntu.

You can still install it using apt-get. To install any version, first execute the following commands:

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Then, depending on the version you want to install, execute one of the following commands:

### Oracle JDK 6

* * *

This is an old version but still in use.

    sudo apt-get install oracle-java6-installer

### Oracle JDK 7

* * *

This is the latest stable version.

    sudo apt-get install oracle-java7-installer

### Oracle JDK 8

* * *

This is a developer preview, the general release is scheduled for March 2014. This [external article about Java 8](http://www.techempower.com/blog/2013/03/26/everything-about-java-8/) may help you to understand what it’s all about.

    sudo apt-get install oracle-java8-installer

## Managing Java (optional)

* * *

When there are multiple Java installations on your Droplet, the Java version to use as default can be chosen. To do this, execute the following command:

    sudo update-alternatives --config java

It will usually return something like this if you have 2 installations (if you have more, it will of course return more):

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

You can now choose the number to use as default. This can also be done for the Java compiler (`javac`):

    sudo update-alternatives --config javac

It is the same selection screen as the previous command and should be used in the same way. This command can be executed for all other commands which have different installations. In Java, this includes but is not limited to: `keytool`, `javadoc` and `jarsigner`.

## Setting the “JAVA\_HOME” environment variable

* * *

To set the `JAVA_HOME` environment variable, which is needed for some programs, first find out the path of your Java installation:

    sudo update-alternatives --config java

It returns something like:

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

The path of the installation is for each:

1. `/usr/lib/jvm/java-7-oracle`

2. `/usr/lib/jvm/java-6-openjdk-amd64`

3. `/usr/lib/jvm/java-7-oracle`

Copy the path from your preferred installation and then edit the file `/etc/environment`:

    sudo nano /etc/environment

In this file, add the following line (replacing YOUR\_PATH by the just copied path):

    JAVA_HOME="YOUR_PATH"

That should be enough to set the environment variable. Now reload this file:

    source /etc/environment

Test it by executing:

    echo $JAVA_HOME

If it returns the just set path, the environment variable has been set successfully. If it doesn’t, please make sure you followed all steps correctly.

Submitted by: [Koen Vlaswinkel](http://koenv.com)
