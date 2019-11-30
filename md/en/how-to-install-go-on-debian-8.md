---
author: Lisa Tagliaferri
date: 2016-12-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-go-on-debian-8
---

# How To Install Go on Debian 8

## Introduction

Go, also referred to as _golang_, is a modern, open-source programming language developed by Google. Increasingly popular for many applications, Go takes a minimalist approach to development, helping you build reliable and efficient software.

This tutorial will guide you through downloading and installing Go, as well as compiling and executing a basic “Hello, World!” program, on a Debian 8 server.

## Prerequisites

This tutorial assumes you have access to a Debian 8 server, configured with a non-root user with `sudo` privileges as described in [Initial Server Setup with Debian 8](initial-server-setup-with-debian-8).

## Step 1 — Downloading Go

In this step, we’ll install Go on your server.

Visit the [official Go downloads page](https://golang.org/dl/) and find the URL for the current binary release’s tarball. Make sure you copy the link for the latest version that is compatible with a 64-bit architecture.

From your home directory, use `curl` to retrieve the tarball:

    curl -O https://dl.google.com/go/go1.10.2.linux-amd64.tar.gz

Although the tarball came from a genuine source, it is best practice to verify both the authenticity and integrity of items downloaded from the Internet. This verification method certifies that the file was neither tampered with nor corrupted or damaged during the download process. The `sha256sum` command produces a unique 256-bit hash:

    sha256sum go1.10*.tar.gz

    Output4b677d698c65370afa33757b6954ade60347aaca310ea92a63ed717d7cb0c2ff

Compare the hash in your output to the checksum value on the [Go download](https://golang.org/dl/) page. If they match, then it is safe to conclude that the download is legitimate.

With Go downloaded and the integrity of the file validated, let’s proceed with the installation.

## Step 2 — Installing Go

We’ll use `tar` to extract the tarball. The `x` flag tells `tar` to extract, `v` tells it we want verbose output (a listing of the files being extracted), and `f` tells it we’ll specify a filename:

    tar xvf go1.10.2.linux-amd64.tar.gz

You should now have a directory called `go` in your home directory. Recursively change `go`’s owner and group to **root** , and move it to `/usr/local`:

    sudo chown -R root:root ./go
    sudo mv go /usr/local

**Note:** Although `/usr/local/go` is the officially-recommended location, some users may prefer or require different paths.

At this point, using Go would require specifying the full path to its install location in the command line. To make interacting with Go more user-friendly, we will set a few paths.

## Step 3 — Setting Go Paths

In this step, we’ll set some paths in your environment.

First, set Go’s root value, which tells Go where to look for its files.

    nano ~/.profile

At the end of the file, add this line:

 ~/.profile

    ...
    export GOPATH=$HOME/work
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

If you chose an alternate installation location for Go, add these lines instead to the same file. This example shows the commands if Go is installed in your home directory:

~/.profile

    ...
    export GOROOT=$HOME/go
    export GOPATH=$HOME/work
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

With the appropriate line pasted into your profile, save and close the file. Next, refresh your profile by running:

    source ~/.profile

With the core of Go in place, let’s confirm that our setup works by composing a short program.

## Step 4 — Testing Your Install

Now that Go is installed and the paths are set for your server, you can test to ensure that Go is working as expected.

Create a new directory for your Go workspace, which is where Go will build its files:

    mkdir $HOME/work

Then, create a directory hierarchy in this folder in order for you to create your test program file. We’ll use the directory `my_project` as an example.

    mkdir -p work/src/my_project/hello

Next, you can create a traditional “Hello World” Go file.

    nano ~/work/src/my_project/hello/hello.go

Inside your editor, paste the code below, which uses the main Go packages, imports the formatted IO content component, and sets a new function to print “Hello, World” when run.

hello.go

    package main
    
    import "fmt"
    
    func main() {
        fmt.Printf("Hello, World!\n")
    }

This program will print “Hello, World!” if it successfully runs, which will indicate that Go programs are compiling correctly. Save and close the file, then compile it by invoking the Go command `install`:

    go install my_project/hello

With the program compiled, you can run it by executing the command:

    hello

Go is successfully installed and functional if you see the following output:

    OutputHello, World!

You can see where the compiled `hello` binary is installed by using the `which` command:

    which hello

    Output/home/user/work/bin/hello

The “Hello, World!” program established that you have a Go development environment.

## Conclusion

By downloading and installing the latest Go package and setting its paths, you now have a system to use for Go development. A typical application will use libraries and remote packages. To learn more about working with these additional components, check out the official documentation on [How to Write Go Code](https://golang.org/doc/code.html).

You can also read [some Go tips from our development team](https://www.digitalocean.com/company/blog/get-your-development-team-started-with-go/).
