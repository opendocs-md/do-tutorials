---
author: Marko Mudrinić
date: 2017-05-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-go-executables-for-multiple-platforms-on-ubuntu-16-04
---

# How To Build Go Executables for Multiple Platforms on Ubuntu 16.04

## Introduction

The [Go programming language](https://golang.org/) comes with a rich toolchain that makes obtaining packages and building executables incredibly easy. One of Go’s most powerful features is the ability to cross-build executables for any Go-supported foreign platform. This makes testing and package distribution much easier, because you don’t need to have access to a specific platform in order to distribute your package for it.

In this tutorial, you’ll use Go’s tools to obtain a package from version control and automatically install its executable. Then you’ll manually build and install the executable so you can be familiar with the process. Then you’ll build an executable for a different architecture, and automate the build process to create executables for multiple platforms. When you’re done, you’ll know how to build executables for Windows and macOS, as well as other platforms you want to support.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- Go installed, as described in [How to Install Go 1.6 on Ubuntu 16.04](how-to-install-go-1-6-on-ubuntu-16-04).

## Step 1 — Installing Go Programs from Version Control

Before we can create executables from a Go package, we have to obtain its source code. The `go get` tool can fetch packages from version control systems like GitHub. Under the hood, `go get` clones packages into subdirectories of the `$GOPATH/src/` directory. Then, if applicable, it installs the package by building its executable and placing it in the `$GOPATH/bin` directory. If you configured Go as described in the prerequisite tutorials, the `$GOPATH/bin` directory is included in your `$PATH` environmental variable, which ensures that you can use installed packages from anywhere on your system.

The syntax for the `go get` command is `go get package-import-path`. The `package-import-path` is a string that unique identifies a package. It’s often the location of the package in a remote repository like Github, or a directory within the `$GOPATH/src/` directory on your machine.

It’s common to use `go get` with the `-u` flag, which instructs `go get` to obtain the package and its dependencies, or update those dependencies if they’re already present on the machine.

In this tutorial, we will install [Caddy](https://github.com/mholt/caddy), a web server written in Go. Per [Caddy’s instructions](https://github.com/mholt/caddy#install)x, we’ll use `github.com/mholt/caddy/caddy` for the package import path. Use `go get` to fetch and install Caddy:

    go get -u github.com/mholt/caddy/caddy

The command will take some time to complete, but you won’t see any progress while it fetches the package and installs it. No output actually indicates that the command executed successfully.

When the command completes, you’ll find Caddy’s source code available at `$GOPATH/src/github.com/mholt/caddy`. In addition, since Caddy has an executable, it was automatically created and stored in the `$GOPATH/bin` directory. Verify this by using `which` to print the location of the executable:

    which caddy

You’ll see the following output:

    Output/home/sammy/work/bin/caddy

**Note** : The `go get` command installs packages from the default branch of a Git repository, which in many cases is the `master`, or in-development branch. Make sure to review the instructions, usually located in the repository’s `README` file, before using `go get`.

You can use Git commands like `git checkout` to select a different branch on sources obtained using the `go get` command. Review the tutorial [How to Use Git Branches](how-to-use-git-branches) to learn more about how to switch branches.

Let’s look at the process of installing Go packages in more detail, starting with creating executables from packages we’ve already obtained.

## Step 2 — Building an Executable

The `go get` command downloaded the source and installed Caddy’s executable for us in a single command. But you may want to rebuild the executable yourself, or build an executable from your own code. The `go build` command builds executables.

Although we already installed Caddy, let’s build it again manually so we can get comfortable with the process. Execute `go build` and specify the package import path:

    go build github.com/mholt/caddy/caddy

As before, no output indicates successful operation. The executable will be generated in your current directory, with the same name as the directory containing the package. In this case, the executable will be named `caddy`.

If you’re located in the package directory, you can omit the path to the package and simply run `go build`.

To specify a different name or location for the executable, use the `-o` flag. Let’s build an executable called `caddy-server` and place it in a `build` directory within the current working directory:

    go build -o build/caddy-server github.com/mholt/caddy/caddy

This command creates the executable, and also creates the `./build` directory if it doesn’t exist.

Now let’s look at installing executables.

## Step 3 — Installing an Executable

Building an executable creates the executable in the current directory or the directory of your choice. Installing an executable is the process of creating an executable and storing it in `$GOPATH/bin`. The `go install` command works just like `go build`, but `go install` takes care of placing the output file in the right place for you.

To install an executable, use `go install`, followed by the package import path. Once again, use Caddy to try this out:

    go install github.com/mholt/caddy/caddy

Just like with `go build`, you’ll see no output if the command was successful. And like before, the executable is created with the same name as the directory containing the package. But this time, the executable is stored in `$GOPATH/bin`. If `$GOPATH/bin` is part of your `$PATH` environmental variable, the executable will be available from anywhere on your operating system. You can verify its location using `which` command:

    which caddy

You’ll see the following output:

    Output of which/home/sammy/work/bin/caddy

Now that you understand how `go get`, `go build`, and `go install` work, and how they’re related, let’s explore one of the most popular Go features: creating executables for other target platforms.

## Step 4 — Building Executables for Different Architectures

The `go build` command lets you build an executable file for any Go-supported target platform, _on your platform_. This means you can test, release and distribute your application without building those executables on the target platforms you wish to use.

Cross-compiling works by setting required environment variables that specify the target operating system and architecture. We use the variable `GOOS` for the target operating system, and `GOARCH` for the target architecture. To build an executable, the command would take this form:

    env GOOS=target-OS GOARCH=target-architecture go build package-import-path

The `env` command runs a program in a modified environment. This lets you use environment variables for the current command execution only. The variables are unset or reset after the command executes.

The following table shows the possible combinations of `GOOS` and `GOARCH` you can use:

| `GOOS` - Target Operating System | `GOARCH` - Target Platform |
| --- | --- |
| `android` | `arm` |
| `darwin` | `386` |
| `darwin` | `amd64` |
| `darwin` | `arm` |
| `darwin` | `arm64` |
| `dragonfly` | `amd64` |
| `freebsd` | `386` |
| `freebsd` | `amd64` |
| `freebsd` | `arm` |
| `linux` | `386` |
| `linux` | `amd64` |
| `linux` | `arm` |
| `linux` | `arm64` |
| `linux` | `ppc64` |
| `linux` | `ppc64le` |
| `linux` | `mips` |
| `linux` | `mipsle` |
| `linux` | `mips64` |
| `linux` | `mips64le` |
| `netbsd` | `386` |
| `netbsd` | `amd64` |
| `netbsd` | `arm` |
| `openbsd` | `386` |
| `openbsd` | `amd64` |
| `openbsd` | `arm` |
| `plan9` | `386` |
| `plan9` | `amd64` |
| `solaris` | `amd64` |
| `windows` | `386` |
| `windows` | `amd64` |

**Warning:** Cross-compiling executables for Android requires the [Android NDK](https://developer.android.com/ndk/index.html), and some additional setup which is beyond the scope of this tutorial.

Using the values in the table, we can build Caddy for Windows 64-bit like this:

    env GOOS=windows GOARCH=amd64 go build github.com/mholt/caddy/caddy

Once again, no output indicates that the operation was successful. The executable will be created in the current directory, using the package name as its name. However, since we built this executable for Windows, the name ends with the suffix `.exe`.

You should have `caddy.exe` file in your current directory, which you can verify with the `ls` command.

    ls caddy.exe

You’ll see the `caddy.exe` file listed in the output:

    Outputcaddy.exe

**Note** : You can use the `-o` flag to rename the executable or place it in a different location. However, when building an executable for Windows and providing a different name, be sure to explicitly specify the `.exe`suffix when setting the executable’s name.

Let’s look at scripting this process to make it easier to release software for multiple target environments.

## Step 5 — Creating a Script to Automate Cross-Compilation

The process of creating executables for many platforms can be a little tedious, but we can create a script to make things easier.

The script will take the package import path as an argument, iterate through a predefined list of operating system and platform pairs, and generate an executable for each pair, placing the output in the current directory. Each executable will be named with the package name, followed by the target platform and architecture, in the form `package-OS-architecture`. This will be a universal script that you can use on any project.

Switch to your home directory and create a new file called `go-executable-build.bash` in your text editor:

    cd ~
    nano go-executable-build.bash

We will start our script with a _shebang_ line. This line defines which interpreter will parse this script when it’s run as an executable. Add the following line to specify that `bash` should execute this script:

go-executable-build.bash

    #!/usr/bin/env bash

We want to take the package import path as a command line argument. To do this, we will use `$n` variable, where `n` is a non-negative number. The variable `$0` contains the name of the script you executed, while `$1` and greater will contain user-provided arguments. Add this line to the script, which will take the first argument from the command line and store it in a variable called `package`:

go-executable-build.bash

    ...
    package=$1
    

Next, make sure that the user provided this value. If the value isn’t provided, exit the script with a message explaining how to use the script:

go-executable-build.bash

    ...
    
    if [[-z "$package"]]; then
      echo "usage: $0 <package-name>"
      exit 1
    fi

This `if` statement checks the value of the `$package` variable. If it’s not set, we use `echo` to print the correct usage, and then terminate the script using `exit`. `exit` takes a return value as an argument, which should be `0` for successful executions and any non-zero value for unsuccessful executions. We use `1` here since the script wasn’t successful.

**Note** : If you want to make this script work with a predefined package, change the `package` variable to point to that import path:

go-executable-build.bash

    ...
    package="github.com/user/hello"

Next, we want to extract the package name from the path. The package import path is delimited by `/` characters, with the package name located at the end of the path. First, we will split the package import path into an array, using the `/` as the delimiter:

go-executable-build.bash

    package_split=(${package//\// })

The package name should be the last element of this new `$package_split` array. In Bash, you can use a negative array index to access an array from the end instead of the beginning. Add this line to grab the package name from the array and store it in a variable called `package_name`:

go-executable-build.bash

    ...
    package_name=${package_split[-1]}

Now, you’ll need to decide what platforms and architectures you want build executables for. In this tutorial, we’ll build executables for Windows 64-bit, Windows 32-bit, and 64-bit macOS. We will put these targets in an array with the format `OS/Platform`, so we can split each pair into `GOOS` and `GOARCH` variables using the same method we used to extract the package name from the path. Add the platforms to the script:

go-executable-build.bash

    ...
    platforms=("windows/amd64" "windows/386" "darwin/amd64")

Next, we’ll iterate through the array of platforms, split each platform entry into values for the `GOOS` and `GOARCH` environment variables, and use those to build the executable. We can do that with the following `for` loop:

go-executable-build.bash

    ...
    for platform in "${platforms[@]}"
    do
        ...
    done

The `platform` variable will contain an entry from the `platforms` array in each iteration. We need to split `platform` to two variables - `GOOS` and `GOARCH`. Add the following lines to the `for` loop:

go-executable-build.bash

    for platform in "${platforms[@]}"
    do
        platform_split=(${platform//\// })
        GOOS=${platform_split[0]}
        GOARCH=${platform_split[1]}
    
    done

Next, we will generate the executable’s name by combining the package name with the OS and architecture. When we’re building for Windows, we also need to add the `.exe` suffix to the filename. Add this code to the `for` loop:

go-executable-build.bash

    for platform in "${platforms[@]}"
    do
        platform_split=(${platform//\// })
        GOOS=${platform_split[0]}
        GOARCH=${platform_split[1]}
    
        output_name=$package_name'-'$GOOS'-'$GOARCH
    
        if [$GOOS = "windows"]; then
            output_name+='.exe'
        fi
    done
    

With the variables set, we use `go build` to create the executable. Add this line to the body of the `for` loop, right above the `done` keyword:

go-executable-build.bash

    ...
        if [$GOOS = "windows"]; then
            output_name+='.exe'
        fi
    
        env GOOS=$GOOS GOARCH=$GOARCH go build -o $output_name $package
    
    done

Finally, we should check to see if there were errors building the executable. For example, we might run into an error if we try to build a package we don’t have sources for. We can check the `go build` command’s return code for a non-zero value. The variable `$?` contains the return code from a previous command’s execution. If `go build` returns anything other than `0`, there was a problem, and we’ll want to exit the script. Add this code to the `for` loop, after the `go build` command and above the `done` keyword.

go-executable-build.bash

    
    ...
    
        env GOOS=$GOOS GOARCH=$GOARCH go build -o $output_name $package
    
        if [$? -ne 0]; then
            echo 'An error has occurred! Aborting the script execution...'
            exit 1
        fi

With that, we now have a script that will build multiple executables from our Go package. Here’s the completed script:

go-executable-build.bash

    
    #!/usr/bin/env bash
    
    package=$1
    if [[-z "$package"]]; then
      echo "usage: $0 <package-name>"
      exit 1
    fi
    package_split=(${package//\// })
    package_name=${package_split[-1]}
    
    platforms=("windows/amd64" "windows/386" "darwin/amd64")
    
    for platform in "${platforms[@]}"
    do
        platform_split=(${platform//\// })
        GOOS=${platform_split[0]}
        GOARCH=${platform_split[1]}
        output_name=$package_name'-'$GOOS'-'$GOARCH
        if [$GOOS = "windows"]; then
            output_name+='.exe'
        fi  
    
        env GOOS=$GOOS GOARCH=$GOARCH go build -o $output_name $package
        if [$? -ne 0]; then
            echo 'An error has occurred! Aborting the script execution...'
            exit 1
        fi
    done

Verify that your file matches the preceding code. Then save the file and exit the editor.

Before we can use the script, we have to make it executable with the `chmod` command:

    chmod +x go-executable-build.bash

Finally, test the script by building executables for Caddy:

    ./go-executable-build.bash github.com/mholt/caddy/caddy

If everything goes well, you should have executables in your current directory. No output indicates successful script execution. You can verify are executables created using `ls` command:

    ls caddy*

You should see all three versions:

    Example ls outputcaddy-darwin-amd64 caddy-windows-386.exe caddy-windows-amd64.exe

To change the target platforms, just change the `platforms` variable in your script.

## Conclusion

In this tutorial, you’ve learned how to use Go’s tooling to obtain packages from version control systems, as well as build and cross-compile executables for different platforms.

You also created a script that you can use to cross-compile a single package for many platforms.

To make sure your application works correctly, you can take a look at **[testing](https://golang.org/pkg/testing/)** and **continuous integration** like [Travis-CI](https://travis-ci.org) and [AppVeyor](https://www.appveyor.com/) for testing on Windows.

If you are interested in Caddy and how to use it, take a look at [How to Host a Website with Caddy on Ubuntu 16.04](how-to-host-a-website-with-caddy-on-ubuntu-16-04).
