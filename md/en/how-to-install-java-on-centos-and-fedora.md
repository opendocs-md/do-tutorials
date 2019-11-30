---
author: Mitchell Anicas
date: 2014-12-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-java-on-centos-and-fedora
---

# How To Install Java on CentOS and Fedora

## Introduction

This tutorial will show you how to install Java on CentOS 7 (also 6 and 6.5), modern Fedora releases, and RHEL. Java is a popular software platform that allows you to run Java applications and applets.

The installation of the following versions of Java are covered:

- OpenJDK 8
- OpenJDK 7
- OpenJDK 6
- Oracle Java 9
- Oracle Java 8

Feel free to skip to your desired section using the **Contents** button on the sidebar!

## Prerequisites

Before you begin this guide, you should have a regular, non-root user with `sudo` privileges configured on both of your servers–this is the user that you should log in to your servers as. You can learn how to configure a regular user account by following the steps in our [initial server setup guide for Centos 7](initial-server-setup-with-centos-7).

## Variations of Java

There are three different editions of the Java Platform: Standard Edition (SE), Enterprise Edition (EE), and Micro Edition (ME). This tutorial is focused on Java SE (Java Platform, Standard Edition).

There are two different Java SE packages that can be installed: the Java Runtime Environment (JRE) and the Java Development Kit (JDK). JRE is an implementation of the Java Virtual Machine (JVM), which allows you to run compiled Java applications and applets. JDK includes JRE and other software that is required for writing, developing, and compiling Java applications and applets.

There are also two different implementations of Java: OpenJDK and Oracle Java. Both implementations are based largely on the same code but OpenJDK, the reference implementation of Java, is fully open source while Oracle Java contains some proprietary code. Most Java applications will work fine with either but you should use whichever implementation your software calls for.

You may install various versions and releases of Java on a single system, but most people only need one installation. With that in mind, try to only install the version of Java that you need to run or develop your application(s).

## Install OpenJDK 8

This section will show you how to install the prebuilt OpenJDK 8 JRE and JDK packages using the yum package manager, which is similar to apt-get for Ubuntu/Debian. OpenJDK 8 is the latest version of OpenJDK.

### Install OpenJDK 8 JRE

To install OpenJDK 8 **JRE** using yum, run this command:

    sudo yum install java-1.8.0-openjdk

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 8 JRE.

### Install OpenJDK 8 JDK

To install OpenJDK 8 **JDK** using yum, run this command:

    sudo yum install java-1.8.0-openjdk-devel

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 8 JDK.

## Install OpenJDK 7

This section will show you how to install the prebuilt OpenJDK 7 JRE and JDK packages using the yum package manager.

### Install OpenJDK 7 JRE

To install OpenJDK 7 **JRE** using yum, run this command:

    sudo yum install java-1.7.0-openjdk

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 7 JRE.

### Install OpenJDK 7 JDK

To install OpenJDK 7 **JDK** using yum, run this command:

    sudo yum install java-1.7.0-openjdk-devel

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 7 JDK.

## Install OpenJDK 6

This section will show you how to install the prebuilt OpenJDK 6 JRE and JDK packages using the yum package manager.

### Install OpenJDK 6

To install OpenJDK 6 **JRE** using yum, run this command:

    sudo yum install java-1.6.0-openjdk

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 6 JRE.

### Install OpenJDK 6 JDK

To install OpenJDK 6 **JDK** using yum, run this command:

    sudo yum install java-1.6.0-openjdk-devel

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Congratulations! You have installed OpenJDK 6 JDK.

## Install Oracle Java 9

This section of the guide will show you how to install Oracle Java 9 JRE and JDK (64-bit), the latest release of these packages at the time of this writing.

Throughout this section we will be using the `wget` command to download the Oracle Java software packages. `wget` may not be included by default on your Linux distribution, so in order to follow along you will need to install it by running:

    sudo yum install wget

**Note:** You must accept the Oracle Binary Code License Agreement for Java SE, which is one of the included steps, before installing Oracle Java.

### Install Oracle Java 9 JRE

**Note:** In order to install Oracle Java 9 JRE, you wil need to go to the [Oracle Java 9 JRE Downloads Page](http://www.oracle.com/technetwork/java/javase/downloads/jre9-downloads-3848532.html), accept the license agreement, and copy the download link of the appropriate Linux `.rpm` package. Substitute the copied download link in place of the highlighted part of the `wget` command.

Change to your home directory and download the Oracle Java 9 JRE RPM with these commands:

    cd ~
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://link_copied_from_site"

Then install the RPM with this yum command (if you downloaded a different release, substitute the filename here):

    sudo yum localinstall jre-9.0.4_linux_x64_bin.rpm

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Now Java should be installed at `/usr/java/jre-9.0.4/bin/java`, and linked from `/usr/bin/java`.

You may delete the archive file that you downloaded earlier:

    rm ~/jre-9.0.4_linux_x64_bin.rpm

Congratulations! You have installed Oracle Java 9 JRE.

### Install Oracle Java 9 JDK

**Note:** In order to install Oracle Java 9 JDK, you will need to go to the [Oracle Java 9 JDK Downloads Page](http://www.oracle.com/technetwork/java/javase/downloads/jdk9-downloads-3848520.html), accept the license agreement, and copy the download link of the appropriate Linux `.rpm` package. Substitute the copied download link in place of the highlighted part of the `wget` command.

Change to your home directory and download the Oracle Java 9 JDK RPM with these commands:

    cd ~
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://link_copied_from_site"

Then install the RPM with this yum command (if you downloaded a different release, substitute the filename here):

    sudo yum localinstall jdk-9.0.4_linux-x64_bin.rpm

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Now Java should be installed at `/usr/java/jdk-9.0.4/bin/java`, and linked from `/usr/bin/java`.

You may delete the archive file that you downloaded earlier:

    rm ~/jdk-9.0.4_linux-x64_bin.rpm

Congratulations! You have installed Oracle Java 9 JDK.

## Install Oracle Java 8

This section of the guide will show you how to install Oracle Java 8 JRE and JDK (64-bit).

**Note:** You must accept the Oracle Binary Code License Agreement for Java SE, which is one of the included steps, before installing Oracle Java.

### Install Oracle Java 8 JRE

**Note:** In order to install Oracle Java 8 JRE, you will need to go to the [Oracle Java 8 JRE Downloads Page](http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html), accept the license agreement, and copy the download link of the appropriate Linux `.rpm` package. Substitute the copied download link in place of the highlighted part of the `wget` command.

Change to your home directory and download the Oracle Java 8 JRE RPM with these commands:

    cd ~
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://link_copied_from_site"

Then install the RPM with this yum command (if you downloaded a different release, substitute the filename here):

    sudo yum localinstall jre-8u161-linux-x64.rpm

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Now Java should be installed at `/usr/java/jre1.8.0_161/bin/java`, and linked from `/usr/bin/java`.

You may delete the archive file that you downloaded earlier:

    rm ~/jre-8u161-linux-x64.rpm

Congratulations! You have installed Oracle Java 8 JRE.

### Install Oracle Java 8 JDK

**Note:** In order to install Oracle Java 8 JDK, you will need to go to the [Oracle Java 8 JDK Downloads Page](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html), accept the license agreement, and copy the download link of the appropriate Linux `.rpm` package. Substitute the copied download link in place of the highlighted part of the `wget` command.

Change to your home directory and download the Oracle Java 8 JDK RPM with these commands:

    cd ~
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://link_copied_from_site"

Then install the RPM with this yum command (if you downloaded a different release, substitute the filename here):

    sudo yum localinstall jdk-8u161-linux-x64.rpm

At the confirmation prompt, enter `y` then `RETURN` to continue with the installation.

Now Java should be installed at `/usr/java/jdk1.8.0_161/jre/bin/java`, and linked from `/usr/bin/java`.

You may delete the archive file that you downloaded earlier:

    rm ~/jdk-8u161-linux-x64.rpm

Congratulations! You have installed Oracle Java 8 JDK.

## Set Default Java

If you installed multiple versions of Java, you may want to set one as your default (i.e. the one that will run when a user runs the `java` command). Additionally, some applications require certain environment variables to be set to locate which installation of Java to use. This section will show you how to do this.

By the way, to check the version of your default Java, run this command:

    java -version

### Using Alternatives

The `alternatives` command, which manages default commands through symbolic links, can be used to select the default Java command.

To print the programs that provide the `java` command that are managed by `alternatives`, use this command:

    sudo alternatives --config java

Here is an example of the output:

    outputThere are 5 programs which provide 'java'.
    
      Selection Command
    -----------------------------------------------
       1 java-1.7.0-openjdk.x86_64 (/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.161-2.6.12.0.el7_4.x86_64/jre/bin/java)
       2 java-1.8.0-openjdk.x86_64 (/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.151-5.b12.el7_4.x86_64/jre/bin/java)
       3 /usr/lib/jvm/jre-1.6.0-openjdk.x86_64/bin/java
    *+ 4 /usr/java/jre-9.0.4/bin/java
       5 /usr/java/jdk-9.0.4/bin/java
    
    
    
    
    Enter to keep the current selection[+], or type selection number: 

Simply enter the a selection number to choose which `java` executable should be used by default.

### Using Environment Variables

Many Java applications use the `JAVA_HOME` or `JRE_HOME` environment variables to determine which `java` executable to use.

For example, if you installed Java to `/usr/java/jdk1.8.0_161/jre/bin` (i.e. `java` executable is located at `/usr/java/jdk1.8.0_161/jre/bin/java`), you could set your `JAVA_HOME` environment variable in a bash shell or script like so:

    export JAVA_HOME=/usr/java/jdk1.8.0_161/jre

If you want `JAVA_HOME` to be set for every user on the system by default, add the previous line to the `/etc/environment` file. An easy way to append it to the file is to run this command:

    sudo sh -c "echo export JAVA_HOME=/usr/java/jdk1.8.0_161/jre >> /etc/environment"

## Conclusion

Congratulations, you are now set to run and/or develop your Java applications!
