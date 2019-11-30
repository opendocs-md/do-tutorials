---
author: Mathias Jensen
date: 2013-08-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-compile-and-install-packages-from-source-using-make-on-a-vps
---

# How To Compile and Install Packages From Source Using Make on a VPS

## Introduction

When working on a Linux machine or VPS, the packages you need are usually available via apt or another package manager. But once in a while it happens that you need a package that isn't available from a repository, or sometimes you just need a newer, more bleeding-edge version than the one there is.

In this example we will be compiling and installing curl from source. The basics used in this example applies to the majority of packages, and can be applied in most cases.

## Requirements

To compile sources on Linux, you will need the package called "build-essential" on Debian-based systems and "Development Tools" on CentOS, as it contains the gcc/g++ compilers and libraries required to compile packages. To install this on Debian and Ubuntu run:

    apt-get install build-essential

And on CentOS run:

    yum groupinstall "Development Tools"

Some packages requires you to have some dependencies installed in order to be compiled or to be run afterwards. When using apt or another package manager, it usually handles this for you. When compiling packages yourself you should always check the documentation, and make sure you have the required packages installed beforehand.

Since we in this example are compiling curl you should have everything you need. You will however need root or sudo access on the VPS you are using, to install the compiled source afterwards.

## Getting and Compiling the Source on a VPS

### Downloading the Tarball

The first thing we need is to download the curl sourcecode. There are a lot of different ways to download the source, but in this example we will use the tarball available from the [curl website](http://curl.haxx.se/download.html). You can replace the url in the next command with current version of curl if you want. Just remember it should be the link to the tar.gz file. When you are ready go ahead and run:

    wget -O curl.tar.gz [http://curl.haxx.se/download/<wbr>curl-7.32.0.tar.gz</wbr>](http://curl.haxx.se/download/curl-7.32.0.tar.gz)

This will download and save the source as curl.tar.gz in your current directory.

Next we will need to extract the tarball. To do this run:

    tar -xvzf curl.tar.gz

The source will be in a folder called "curl-" and then the version number. If you type:

    ls

 it should output something like this: 

    user@droplet:~/curl ls curl-7.32.0 curl.tar.gz 

In my case the folder is called "curl-7.32.0" therefore to enter the folder I type:

    cd curl-7.32.0

### Configuring and Compiling the Source

Inside the folder you will notice a lot of different files. For now, we will just be focusing on the file called "configure". "configure" is a script designed to aid a program to be run on a wide number of different computers. Go ahead and run:

    ./configure

This will automatically use your system variables to configure and ready the source for your VPS. It basically matches the libraries required by the program, with the ones installed on your system. By doing this, the compiler knows where to look for the libraries required by the source, or in this case by curl. Besides that it will also figure out where to install the package afterwards. When it is done it will generate a file called Makefile with all the info in it. You are now ready to compile the source. To compile it run the command:

    make

This will compile the source output a lot of rubbish to your console. Just go ahead and let it finish. It should take about a minute or so. When it is done, you should be ready to install it. As root run:

    make install

Make will now follow the instructions in the Makefile to install the compiled package.

In most cases you should be done now. You can go ahead and type `curl` now. If curl has been installed properly you should see something like this:

    curl: try 'curl --help' or 'curl --manual' for more information

If it outputs a bash error, go ahead and type:

    ln -s /usr/local/bin/curl /usr/bin/curl

This will create a link at /usr/bin/curl that connects it to /usr/local/bin/curl. This will allow you to run curl by simply typing `curl` in the console. This will usually be done automatically, but in some cases the configure script can't find the right install location. You can now go ahead and type:

    curl -V

This will output your current version of curl.

It should return an output like this:

    user@droplet:~/curl curl -V curl 7.32.0 (x86\_64-unknown-linux-gnu) libcurl/7.26.0 OpenSSL/1.0.1e zlib/1.2.7 libidn/1.25 libssh2/1.4.2 librtmp/2.3 Protocols: dict file ftp ftps gopher http https imap imaps ldap pop3 pop3s rtmp rtsp scp sftp smtp smtps telnet tftp Features: Debug GSS-Negotiate IDN IPv6 Largefile NTLM NTLM\_WB SSL libz TLS-SRP 

Congratulations! You have now successfully compiled and installed curl from source.

## Conclusion

The steps you used in this example work for the majority of packages and can therefore be reused in a lot of situations. You should, however, always read the documentation of the package you want to install beforehand. It usually tells you what dependencies are needed, and sometimes it even tells you which commands to run. Just always remember: `./configure`, then `make`, and then `make install`.

Submitted by: [Mathias Jensen](http://mjdk.dk)
