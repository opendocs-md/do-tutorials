---
author: Brennen Bearnes
date: 2018-07-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-go-on-ubuntu-18-04
---

# How To Install Go on Ubuntu 18.04

## Introduction

[Go](https://golang.org/) is a modern programming language developed at Google. It is increasingly popular for many applications and at many companies, and offers a robust set of libraries. This tutorial will walk you through downloading and installing the latest version of Go (Go 1.10 at the time of this article’s publication), as well as building a simple Hello World application.

## Prerequisites

This tutorial assumes that you have access to an Ubuntu 18.04 system, configured with a non-root user with `sudo` privileges as described in [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

## Step 1 — Installing Go

In this step, we’ll install Go on your server.

To begin, connect to your Ubuntu server via `ssh`:

    ssh sammy@your_server_ip

In order to install Go, you’ll need to grab the latest version from the [official Go downloads page](https://golang.org/dl/). On the site you can find the URL for the current binary release’s tarball, along with its SHA256 hash.

Visit the official Go downloads page and find the URL for the current binary release’s tarball, along with its SHA256 hash. Make sure you’re in your home directory, and use curl to retrieve the tarball:

    cd ~
    curl -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz

Next, you can use `sha256sum` to verify the tarball:

    sha256sum go1.10.3.linux-amd64.tar.gz

    Sample Outputgo1.10.3.linux-amd64.tar.gz
    fa1b0e45d3b647c252f51f5e1204aba049cde4af177ef9f2181f43004f901035 go1.10.3.linux-amd64.tar.gz

You’ll get a hash like the one highlighted in the above output. Make sure it matches the one from the downloads page.

Next, use `tar` to extract the tarball. The `x` flag tells `tar` to extract, `v` tells it we want verbose output (a listing of the files being extracted), and `f` tells it we’ll specify a filename:

    tar xvf go1.10.3.linux-amd64.tar.gz

You should now have a directory called `go` in your home directory. Recursively change `go`’s owner and group to **root** , and move it to `/usr/local`:

    sudo chown -R root:root ./go
    sudo mv go /usr/local

**Note:** Although `/usr/local/go` is the officially-recommended location, some users may prefer or require different paths.

## Step 2 — Setting Go Paths

In this step, we’ll set some paths in your environment.

First, set Go’s root value, which tells Go where to look for its files.

    sudo nano ~/.profile

At the end of the file, add this line:

    export GOPATH=$HOME/work
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

If you chose an alternate installation location for Go, add these lines instead to the same file. This example shows the commands if Go is installed in your home directory:

    export GOROOT=$HOME/go
    export GOPATH=$HOME/work
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

With the appropriate line pasted into your profile, save and close the file. Next, refresh your profile by running:

    source ~/.profile

## Step 3 — Testing Your Install

Now that Go is installed and the paths are set for your server, you can test to ensure that Go is working as expected.

Create a new directory for your Go workspace, which is where Go will build its files:

    mkdir $HOME/work

Then, create a directory hierarchy in this folder through this command in order for you to create your test file. You can replace the value user with your GitHub username if you plan to use Git to commit and store your Go code on GitHub. If you do not plan to use GitHub to store and manage your code, your folder structure could be something different, like `~/my_project`.

    mkdir -p work/src/github.com/user/hello

Next, you can create a simple “Hello World” Go file.

    nano ~/work/src/github.com/user/hello/hello.go

Inside your editor, paste the code below, which uses the main Go packages, imports the formatted IO content component, and sets a new function to print “Hello, World” when run.

    package main
    
    import "fmt"
    
    func main() {
        fmt.Printf("hello, world\n")
    }

This program will print “hello, world” if it successfully runs, which will indicate that Go programs are compiling correctly. Save and close the file, then compile it by invoking the Go command `install`:

    go install github.com/user/hello

With the file compiled, you can run it by simply executing the command:

    hello

If that command returns “hello, world”, then Go is successfully installed and functional. You can see where the compiled `hello` binary is installed by using the `which` command:

    which hello

    Output/home/user/work/bin/hello

## Conclusion

By downloading and installing the latest Go package and setting its paths, you now have a system to use for Go development. You can find and subscribe to additional articles on installing and using Go within our [“Go” tag](https://www.digitalocean.com/community/tags/go)
