---
author: Michael Lenardson
date: 2016-09-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-go-1-7-on-centos-7
---

# How To Install Go 1.7 on CentOS 7

## Introduction

Go, often referred to as _golang_, is an open-source programming language developed by Google. It takes a minimalist approach to development and makes it easy to build simple, reliable, and efficient software. This tutorial will guide you through downloading and installing Go 1.7, as well as compiling and executing a basic “Hello, World!” program, on a CentOS 7 server.

## Prerequisites

Before following this tutorial, be sure that you have a regular, non-root user with `sudo` privileges. You can learn more about how to set up a user with these privileges from our guide, [How To Create a Sudo User on CentOS](how-to-create-a-sudo-user-on-centos-quickstart).

## Step 1 – Downloading Go

As of September 2016, the `golang` package within the default repositories for CentOS is not up to date. As a result, we will manually download the package directly from the [Go website](https://golang.org/dl). Make sure you copy the link for the latest version that is compatible with a 64-bit architecture.

Start by moving into a writable directory:

    cd /tmp

Use the `curl` command and the link from Go to download the tarball:

    curl -LO https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz

Although the tarball came from a genuine source, it is best practice to verify both the authenticity and integrity of items downloaded from the Internet. This verification method certifies that the file was neither tampered with nor corrupted or damaged during the download process. The `shasum` command with the `-a 256` flag produces a unique 256-bit hash:

    shasum -a 256 go1.7*.tar.gz

    Output702ad90f705365227e902b42d91dd1a40e48ca7f67a2f4b2fd052aaa4295cd95 go1.7.linux-amd64.tar.gz

Compare the hash in your output to the checksum value on the Go [download page](https://golang.org/dl). If they match, then it is safe to conclude that the download is legitimate.

With Go downloaded, and the integrity of the file validated, let’s proceed with the installation.

## Step 2 – Installing Go

The installation of Go consists of extracting the tarball into the `/usr/local` directory. Using the `tar` command with the `-C` flag saves the content into a specified directory. The `-x` flag performs the extraction function, `-v` produces a verbose output, `-z` filters the archive through the `gzip` compression utility, and `-f` tells it the specified filename to perform the actions on:

    sudo tar -C /usr/local -xvzf go1.7.linux-amd64.tar.gz

**Note:** The publisher officially recommends placing Go in the `/usr/local` directory. Installing it in another location does not impact its usability, but the custom path would need to be defined in the Go environment variable, `GOROOT`. The next step discusses working with environment variables.

Next, under your user’s home directory, create your Go workspace with three child directories, `bin`, `src`, and `pkg`. The `bin` directory will contain executable programs compiled from the human-readable source files in the `src` directory. Even though we will not use the `pkg` directory in this tutorial, we still recommend setting it up because it is useful when creating more sophisticated programs. The `pkg` directory stores package objects, which is reusable code shared between programs.

We will call our workspace directory `projects`, but you can name it anything you would like. The `-p` flag for the `mkdir` command will create the appropriate directory tree.

    mkdir -p ~/projects/{bin,pkg,src}

At this point, using Go would require specifying the full path to its install location in the command line. To make interacting with Go more user-friendly, we will set a few paths.

## Step 3 – Setting Paths for Go

To execute Go like any other command, we need to append its install location to the `$PATH` variable. Go was installed in a system directory, which is why we will set the environment variable globally.

Create a `path.sh` script in the `/etc/profile.d` directory using the `vi` editor:

    sudo vi /etc/profile.d/path.sh

Add the following to the file, save and exit:

/etc/profile.d/path.sh

    export PATH=$PATH:/usr/local/go/bin

**Warning:** If Go was installed in a different location, then adjust the path accordingly.

Additionally, define the `GOPATH` and `GOBIN` Go environment variables in your user’s `.bash_profile` file to point to the recently created workspace. The `GOPATH` variable tells Go the location of your source files, while the `GOBIN` variable instructs it where to create the compiled binary files.

Open the `.bash_profile` file:

    vi ~/.bash_profile

Add the following to the end of the file, save and exit:

~/.bash\_profile

    . . .
    export GOBIN="$HOME/projects/bin"
    export GOPATH="$HOME/projects/src"

**Warning:** As noted in Step 2, if Go was not installed in the `/usr/local` directory, then define the `GOROOT` variable as well.

~/.bash\_profile

    . . .
    export GOROOT="/path/to/go"

&nbsp;  
To apply the changes to your current BASH session, use the `source` command to reload the updated profiles:

    source /etc/profile && source ~/.bash_profile

With the core of Go in place, let’s confirm that our setup works by composing a short program.

## Step 4 – Creating a Program

Writing our first program will ensure that our environment is working and give us an opportunity to become familiar with the Go programming language.

To get started, create a new `.go` file:

    vi ~/projects/src/hello.go

The code below uses the main Go package, imports the formatted IO content component, and sets a new function to print the string `Hello, World!`. Add the following to the file:

~/projects/hello.go

    package main
    
    import "fmt"
    
    func main() {
        fmt.Printf("Hello, World!\n")
    }

Then, save and exit the file.

Next, compile the `hello.go` source file with the `go install` command:

    go install $GOPATH/hello.go

We are now ready to run our program:

    $GOBIN/hello

The `hello.go` program should produce a `Hello, World!` message, confirming a successful installation of Go.

## Conclusion

The simple “Hello, World!” program established that you have a Go development environment. A typical application will use libraries and remote packages. To learn more about working with these additional components, check out the official documentation on [How to Write Go Code](https://golang.org/doc/code.html).
