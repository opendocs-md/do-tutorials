---
author: Marko Mudrinić
date: 2017-01-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-go-from-source-on-ubuntu-16-04
---

# How To Build Go from Source on Ubuntu 16.04

## Introduction

[Go](https://golang.org/) is a modern, open-source programming language developed by Google. It’s simple and has a robust set of libraries and tools, which makes it easy to build reliable and efficient applications.

If you want to test your Go application against the latest version of the language, contribute to the Go code base, or have better Go version management, you’ll need to build Go from source. This tutorial will show you how to build Go, cover some practical considerations, and build a “Hello, World” test application.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with at least 1GB of memory set up by following the [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.

- Git installed on your server, which you can set up by following [this Git installation tutorial for Ubuntu 16.04.](how-to-install-git-on-ubuntu-16-04)

- Optionally, a [GitHub](https://github.com/) account.

## Step 1 — Installing Build Dependencies

Before starting, make sure your repository cache is up to date.

    sudo apt-get update

By default, Ubuntu doesn’t come with all the packages necessary to build Go, like its compilers, libraries, and tools. It’s easy to install the build and compilation dependencies by installing `build-essential`, a package which includes `gcc` for compiling C, `g++` for compiling C++ and `make`, a build automation tool.

    sudo apt-get install build-essential

Once the installation finishes, you will have all necessary tools to build Go from source. Next, you’ll need the Go 1.4 binaries.

## Step 2 — Installing Go 1.4.3

Building Go 1.5+ requires you to have Go 1.4. This is because the tool chains for Go 1.5+ are written in Go itself. You can use Go 1.4 or any point release (1.4.1, 1.4.2, or 1.4.3); in this tutorial, we’ll use Go 1.4.3.

Go binaries with SHA1 checksums can be found on [Go’s download page](https://golang.org/dl/). Download the file called `go1.4.3.linux-amd64.tar.gz` to your home directory.

    cd ~
    curl -O https://storage.googleapis.com/golang/go1.4.3.linux-amd64.tar.gz

While this file was downloaded from a genuine source, it’s still a good security practice to verify the integrity of what you’ve downloaded. This is most easily done by comparing the file hash provided on the downloads page and the hash of the downloaded file.

First, get the hash of the file you downloaded.

    sha1sum go1.4.3.linux-amd64.tar.gz

Compare the output from this command with the provided checksum on the Go download page.

    Output332b64236d30a8805fc8dd8b3a269915b4c507fe go1.4.3.linux-amd64.tar.gz

If the checksums match, you can unpack the files.

    tar xvf go1.4.3.linux-amd64.tar.gz

The `x` flag stands for e **X** tract, `v` tells `tar` to use **V** erbose output (i.e. to list the files being extracted), and `f` lets us specify the **F** ilename.

Go 1.4 is now unpacked in a directory called `go`, but the Go build script looks for Go 1.4 binaries in `~/go1.4`by default. Rename the directory using the `mv` command.

    mv go go1.4

Now you have the necessary dependencies to build Go from source. If you want to move Go 1.4 out of your home directory to another location, you can follow the next step. If not, you can move on to Step 4 to clone the Go sources.

## Step 3 — Relocating Go 1.4.3 (Optional)

When the Go build script runs, it will look for Go 1.4 based on an environment variable called `GOROOT_BOOTSTRAP`. If that variable is unset, which it is by default, the build script will assume that the `go1.4` directory is in your home directory. You can use the `GOROOT_BOOTSTRAP` variable if you want to move Go 1.4 to another location. Here, we’ll move it to `/usr/local/go1.4`.

First, move the directory itself.

    sudo mv go1.4 /usr/local

Next, you need to set the path in your environment by modifying the `~/.profile` file.

    sudo nano ~/.profile

At the end of the file, add the following line:

~/.profile

    . . .
    export GOROOT_BOOTSTRAP=/usr/local/go1.4

Save the file and exit. To have this change take effect, refresh your profile.

    source ~/.profile

Next, you will clone the Go sources.

## Step 4 — Obtaining Go Sources

The recommended location to store Go binaries is `/usr/local`, which is what we’ll use in this tutorial. However, you can store it wherever you prefer.

Move into `/usr/local` and use Git to clone the repository.

    cd /usr/local
    sudo git clone https://go.googlesource.com/go

We need to execute `git clone` with root privileges because `/usr/local` is owned by **root**. If you are cloning Go to a directory where your user has write permissions, you can run this command without sudo.

**Note:** Storing Go in a location other than `/usr/local` will require you to set up `GOROOT` environment variable. Learn more about Go environment variables in [Step 7](how-to-build-go-from-source-on-ubuntu-16-04/#step-7-%E2%80%94-setting-go-variables).

Once the clone completes successfully, it will create a `go` directory in `/usr/local`. Move into that directory.

    cd go

Before building, we need to choose which Go version we want.

## Step 5 — Choosing a Go Version

Go sources have a different Git branch for every version available. The names of branches are:

- `master` for the latest version in development
- `goversion` for stable versions

Here, we’ll use Go 1.7.4, which means we want to use the `go1.7.4` branch.

**Warning:** It’s not recommended to use the development version (i.e. the `master` branch) of Go in production. It’s not tested and there are there could be bugs. Development versions are good for application testing, but only use released versions for production.

To change branches, use the `git checkout` command. You need to run these commands with root privileges because `/usr/local` and `/usr/local/go1.4` are owned by **root**.

    sudo git checkout go1.7.4

With this step completed, you have downloaded the Go source code of your preferred version. You’re ready to proceed onto the key part of this tutorial: building Go itself.

## Step 6 — Building Go

To build go, you need to execute a bash script, `src/all.bash`, that comes with the source code. The script will check that you have all necessary dependencies, run some tests, and complete the build.

Execute the script, but note that if you changed the location of the Go 1.4.3 binaries, you will need to add the `-E` flag (i.e. `sudo -E bash ./all.bash`) to preserve environment variables.

    cd src
    sudo bash ./all.bash

The script will take a short time to finish. Once the build is done, you’ll see the following output:

    Output of src/all.bashALL TESTS PASSED
    
    ---
    Installed Go for linux/amd64 in /usr/local/go
    Installed commands in /usr/local/go/bin
    *** You need to add /usr/local/go/bin to your PATH.

**Warning:** In some cases, the build can fail on Go 1.7 due to a `time` test failing. This is the result of a bug.

    Failed test output--- FAIL: TestLoadFixed (0.00s)
        time_test.go:943: Now().In(loc).Zone() = "-01", -3600, want "GMT+1", -3600
    FAIL
    FAIL time 2.403s
    ...
    2016/12/09 22:16:40 Failed: exit status 1

The workaround for this issue is to manually apply the bug fix. To do this, create a new branch and cherry pick the commit with the fix. _Cherry picking_ in Git is process of applying changes from specific commit to your branch.

This bug was fixed in [commit c5434f2](https://github.com/golang/go/commit/c5434f2973a87acff76bac359236e690d632ce95), so add it to your newly created branch.

    cd ..
    sudo git checkout -b go1.7.4-timefix
    sudo git cherry-pick c5434f2973a87acff76bac359236e690d632ce95

After you do this, you can run the script again. (Don’t forget the `-E` flag if you moved the Go 1.4.3 binaries.)

    cd src
    sudo bash ./all.bash

Now that Go is built, you need to set some environment variables for it.

## Step 7 — Setting Go Variables

Environmental variables are a powerful way to customize your Go installation. We will walk through most important and useful ones.

To start using Go, you need to add the Go binaries path, `/usr/local/go/bin`, to the `PATH` and `GOPATH` environment variables. `GOPATH` is where the Go application code and binaries are stored, which we’ll specify as `~/work`, though you’re free to customize this.

Add these variables to the `~/.profile` file. Open it with your favorite text editor:

    nano ~/.profile

At the end of the file, add the following lines:

~/.profile

    . . .
    export GOPATH=$HOME/work
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

If you installed Go in a non-default path, i.e. something other then `/usr/local/go`, you’ll need to define the `GOROOT` variable. In that case, add the following lines as well:

~/.profile

    export GOROOT=$HOME/go
    export GOPATH=$HOME/work
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

Save the file and exit. For these changes to take effect, refresh your profile.

    source ~/.profile

With this step completed successfully, you have a fully functional Go installation. Next, we’ll test it to be sure everything is working as expected.

## Step 8 — Testing the Go Installation

A common way to test is that Go is working is to write and run a simple “Hello, World” application.

To do this, first we’ll create and move into a directory for the app files based on your `GOPATH`. You can choose whatever you like within your Go path, but as an example here, we’ll set up the kind of hierarchy you’ll need if you [use GitHub to manage your code](https://github.com/golang/go/wiki/GithubCodeLayout). This hierarchy will work even without a GitHub account, though.

    mkdir -p $GOPATH/src/github.com/your_github_username/test_project
    cd $GOPATH/src/github.com/your_github_username/test_project

Next, create a “Hello, World” Go file called `hello.go`.

    nano hello.go

Add the following code to the file:

hello.go

    package main
    
    import "fmt"
    
    func main() {
        fmt.Printf("Hello World!\n")
    }

This example uses the `fmt` package, which implements I/O functions like `Printf()`, and defines the `main()` function which will print **Hello World** when the program is run.

Save it and exit the file, then compile it by using the Go command `install`.

    go install github.com/your_github_username/test_project

When compilation finishes, you can run it with the following command:

    hello

You’ll see **Hello World!** printed to the terminal, which means your Go installation is working.

## Step 9 — Changing Go Versions (Optional)

This tutorial set up Go 1.7.4. If you want to use a different version, you need to change the active Git branch and rebuild Go.

To check your current Go version, you can use `go version`.

    go version

    Outputgo version go1.7.4 linux/amd64

As an example, we’ll switch to Go version to 1.6.4. This version is located in the `go1.6.4` branch, so switch to it.

    cd /usr/local/go
    sudo git checkout go1.6.4

To make sure everything is up to date, run `git pull` to get the latest changes for the selected branch.

    sudo git pull origin go1.6.4

Now, run the build script as before, making sure to add the `-E` flag if you relocated Go 1.4 in Step 3.

    cd src
    sudo bash ./all.bash

This will take some time to finish. When the build is finished, you’ll see the following output:

    Output of src/all.bashALL TESTS PASSED
    
    ---
    Installed Go for linux/amd64 in /usr/local/go
    Installed commands in /usr/local/go/bin
    *** You need to add /usr/local/go/bin to your PATH.

You already have Go variables set up in `~/.profile` from Step 5, so this is all you need to do to change versions.

## Conclusion

By building from source and setting up paths, you now have a great base for developing and testing Go applications or contributing to the Go code base.

To learn more, you can explore [how to get started with Go](https://www.digitalocean.com/company/blog/get-your-development-team-started-with-go/) or [how to serve Go applications with Martini](how-to-use-martini-to-serve-go-applications-behind-an-nginx-server-on-ubuntu), which is a Go web framework. If you’re looking for inspiration to contribute to Go open source, you can read about the [go-qemu and go-libvirt](https://www.digitalocean.com/company/blog/introducing-go-qemu-and-go-libvirt/) projects.
