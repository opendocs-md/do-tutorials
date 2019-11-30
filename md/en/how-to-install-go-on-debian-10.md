---
author: Jamon Camisso
date: 2019-07-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-go-on-debian-10
---

# How To Install Go on Debian 10

## Introduction

[Go](https://golang.org/), also known as _golang_, is a modern, open-source programming language developed by Google. Go tries to make software development safe, fast and approachable to help you build reliable and efficient software.

This tutorial will guide you through downloading and installing Go from source, as well as compiling and executing a “Hello, World!” program on a Debian 10 server.

## Prerequisites

To complete this tutorial, you will need access to a Debian 10 server and a non-root user with `sudo` privileges, as described in [Initial Server Setup with Debian 10](initial-server-setup-with-debian-10).

## Step 1 — Downloading Go

In this step, we’ll install Go on your server.

First, ensure your `apt` package index is up to date using the following command:

    sudo apt update

Now install `curl` so you will be able to grab the latest Go release:

    sudo apt install curl

Next, visit the [official Go downloads page](https://golang.org/dl/) and find the URL for the current binary release’s tarball. Make sure you copy the link for the latest version that is compatible with a 64-bit architecture.

From your home directory, use `curl` to retrieve the tarball:

    curl -O https://dl.google.com/go/go1.12.7.linux-amd64.tar.gz

Although the tarball came from a genuine source, it is best practice to verify both the authenticity and integrity of items downloaded from the internet. This verification method certifies that the file was neither tampered with nor corrupted or damaged during the download process. The `sha256sum` command produces a unique 256-bit hash:

    sha256sum go1.12.7.linux-amd64.tar.gz

    Outputgo1.12.7.linux-amd64.tar.gz
     66d83bfb5a9ede000e33c6579a91a29e6b101829ad41fffb5c5bb6c900e109d9 go1.12.7.linux-amd64.tar.gz

Compare the hash in your output to the checksum value on the [Go download page](https://golang.org/dl/). If they match, then it is safe to conclude that the download is legitimate.

With Go downloaded and the integrity of the file validated, let’s proceed with the installation.

## Step 2 — Installing Go

We’ll now use `tar` to extract the tarball. The following flags are used to instruct `tar` how to extract, view, and operate on the downloaded tarball:

- The `x` flag tells it that we want to extract files from a tarball
- The `v` flag indicates that we want verbose output, including a list of the files being extracted
- The `f` flag tells `tar` that we’ll specify a filename to operate on

Now let’s put things all together and run the command to extract the package:

    tar xvf go1.12.7.linux-amd64.tar.gz

You should now have a directory called `go` in your home directory. Recursively change the owner and group of this directory to **root** , and move it to `/usr/local`:

    sudo chown -R root:root ./go
    sudo mv go /usr/local

**Note:** Although `/usr/local/go` is the officially-recommended location, some users may prefer or require different paths.

At this point, using Go would require specifying the full path to its install location in the command line. To make interacting with Go more user-friendly, we will set a few paths.

## Step 2 — Setting Go Paths

In this step, we’ll set some paths in your environment.

First, set Go’s root value, which tells Go where to look for its files:

    nano ~/.profile

At the end of the file, add the following lines:

    export GOPATH=$HOME/work
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

If you chose a different installation location for Go, then you should add the following lines to this file **instead** of the lines shown above. In this example, we are adding the lines that would be required if you installed Go in your home directory:

    export GOROOT=$HOME/go
    export GOPATH=$HOME/work
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

With the appropriate lines pasted into your profile, save and close the file.

Next, refresh your profile by running:

    source ~/.profile

With the Go installation in place and the necessary environment paths set, let’s confirm that our setup works by composing a short program.

## Step 3 — Testing Your Installation

Now that Go is installed and the paths are set for your server, you can ensure that Go is working as expected.

Create a new directory for your Go workspace, which is where Go will build its files:

    mkdir $HOME/work

Then, create a directory hierarchy in this folder so that you will be able to create your test file. We’ll use the directory `my_project` as an example:

    mkdir -p work/src/my_project/hello

Next, you can create a traditional “Hello World” Go file:

    nano ~/work/src/my_project/hello/hello.go

Inside your editor, add the following code to the file, which uses the main Go packages, imports the formatted IO content component, and sets a new function to print “Hello, World!” when run:

~/work/src/my\_project/hello/hello.go

    package main
    
    import "fmt"
    
    func main() {
       fmt.Printf("Hello, World!\n")
    }

When it runs, this program will print `Hello, World!`, indicating that Go programs are compiling correctly.

Save and close the file, then compile it by invoking the Go command `install`:

    go install my_project/hello

With the program compiled, you can run it by executing the command:

    hello

Go is successfully installed and functional if you see the following output:

    OutputHello, World!

You can determine where the compiled `hello` binary is installed by using the `which` command:

    which hello

    Output/home/sammy/work/bin/hello

The “Hello, World!” program established that you have a Go development environment.

## Conclusion

By downloading and installing the latest Go package and setting its paths, you now have a system to use for Go development. To learn more about working with Go, see our development series [How To Code in Go](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-go). You can also consult the official documentation on [How to Write Go Code](https://golang.org/doc/code.html).
