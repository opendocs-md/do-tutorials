---
author: Jack Cook
date: 2018-01-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-swift-and-vapor-on-ubuntu-16-04
---

# How To Install Swift and Vapor on Ubuntu 16.04

## Introduction

[Swift](https://developer.apple.com/swift/) is a programming language from Apple. It’s fast, safe, and modern, and it has an enormous community backing the language. Swift is used primarily for developing iOS and macOS applications, but as of Swift 3, you can use it for server-side application development as well.

[Vapor](https://vapor.codes/) is a popular server-side Swift web framework. Like Swift, Vapor is fast and modern, and it supports many of the features that you’ll see in web frameworks for other programming languages.

In this guide, you’ll install Swift and Vapor on Ubuntu 16.04. Then you’ll test your setup by creating a simple web application using one of Vapor’s templates.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server with a non-root user with access to `sudo`. You can learn how to set this up with our [initial server setup guide](initial-server-setup-with-ubuntu-16-04).
- Git installed on your server. Git should already be installed on Ubuntu 16.04, but if it’s not, run `sudo apt-get install git`. 

## Step 1 — Installing Swift

To be able to build and run Vapor web applications, you first need to install Swift.

First, ensure you have the latest list of packages on your system:

    sudo apt-get update

Then install Swift’s prerequisites, which include `clang` and some Python 2.7 components:

    sudo apt-get install clang libicu-dev libpython2.7

After that, download the latest Swift binary. This is not available via `apt`, but you can download it manually from the [Swift downloads page](https://swift.org/download/), or with `wget`:

    wget https://swift.org/builds/swift-4.0-release/ubuntu1604/swift-4.0-RELEASE/swift-4.0-RELEASE-ubuntu16.04.tar.gz

Next, verify that your download wasn’t damaged or tampered with. Import Swift’s PGP keys into your keyring, which will be used to verify the signature file:

    gpg --keyserver hkp://pool.sks-keyservers.net \
          --recv-keys \
          '7463 A81A 4B2E EA1B 551F FBCF D441 C977 412B 37AD' \
          '1BE1 E29A 084C B305 F397 D62A 9F59 7F4D 21A5 6D5F' \
          'A3BA FD35 56A5 9079 C068 94BD 63BC 1CFE 91D3 06C6' \
          '5E4D F843 FB06 5D7F 7E24 FBA2 EF54 30F0 71E1 B235'

You’ll see this output:

    Output[...
    gpg: key 412B37AD: public key "Swift Automatic Signing Key #1 <swift-infrastructure@swift.org>" imported
    gpg: key 21A56D5F: public key "Swift 2.2 Release Signing Key <swift-infrastructure@swift.org>" imported
    gpg: key 91D306C6: public key "Swift 3.x Release Signing Key <swift-infrastructure@swift.org>" imported
    gpg: key 71E1B235: public key "Swift 4.x Release Signing Key <swift-infrastructure@swift.org>" imported
    gpg: no ultimately trusted keys found
    gpg: Total number processed: 4
    gpg: imported: 4 (RSA: 4)

After importing the keys, download the signature file for the release you downloaded:

    wget https://swift.org/builds/swift-4.0-release/ubuntu1604/swift-4.0-RELEASE/swift-4.0-RELEASE-ubuntu16.04.tar.gz.sig

To verify this signature file, run the next command, which generates the following output:

    gpg --verify swift-4.0-RELEASE-ubuntu16.04.tar.gz.sig

You’ll see this output:

    Outputgpg: assuming signed data in `swift-4.0-RELEASE-ubuntu16.04.tar.gz'
    gpg: Signature made Wed 20 Sep 2017 01:13:38 AM UTC using RSA key ID 71E1B235
    gpg: Good signature from "Swift 4.x Release Signing Key <swift-infrastructure@swift.org>"
    Primary key fingerprint: 5E4D F843 FB06 5D7F 7E24 FBA2 EF54 30F0 71E1 B235

You might see a warning that looks like the following:

    Outputgpg: WARNING: This key is not certified with a trusted signature!
    gpg: There is no indication that the signature belongs to the owner.

This means that the Swift keys you imported arent trusted yet, either explicitly by you or by other keys you have installed in your keyring. You can safely ignore these messages. However, if you got a different error, you should re-download the Swift binary.

Now, we can actually install Swift. Execute the following command to extract the binary you downloaded earlier:

    tar xzf swift-4.0-RELEASE-ubuntu16.04.tar.gz

Then add the Swift toolchain to your path so you can run the `swift` command system-wide:

    export PATH=swift-4.0-RELEASE-ubuntu16.04/usr/bin:"${PATH}"

Entering this command will only add the `swift` command to your path for your current shell session. To make sure that it is added automatically in future sessions, add it to the `.bashrc` file.

Open the `.bashrc` file:

    nano ~/.bashrc

Add the following line at the end of the file

~/.bashrc

    . . .
    export PATH=swift-4.0-RELEASE-ubuntu16.04/usr/bin:"${PATH}"

Save and exit the file.

To make sure everything works, run the `swift` command:

    swift

You’ll be greeted with the Swift REPL, which indicates that everything is working correctly.

    OutputWelcome to Swift version 4.0 (swift-4.0-RELEASE). Type :help for assistance.
      1>  
    

Let’s double check that everything is working correctly. Enter this program which sums all integers between 1 and 5. Enter each line into the REPL, pressing the `ENTER` key after each line:

    var x = 0
    for i in 1...5 { 
        x += i 
    } 
    x

The REPL will display the result of the calculation:

    Output$R0: Int = 15

Exit the Swift REPL with `CTRL+D`. Now that Swift is installed, we’re ready to install Vapor.

## Step 2 — Installing Vapor

To install Vapor, you’ll download and execute a script from the Vapor developers that adds Vapor’s official package repository to your server’s list of packages. Then you’ll use `apt` to install the latest version of Vapor.

It’s generally not a good security practice to execute scripts you download from others without inspecting them first. First, download the installation script to your server using the `curl` command with the `-o` switch to specify a local file name:

    curl -sL apt.vapor.sh -o apt.vapor.sh

Use the `less` command to inspect this script:

    less apt.vapor.sh

Once you’ve inspected the installation script’s contents, execute the script to add the repository:

    bash ./apt.vapor.sh

You’ll be prompted for your sudo password. Enter it so the script can add the new package sources.

Once the script finishes, you can install the `vapor` package and its dependencies.

    sudo apt-get install vapor

You can verify that Vapor was successfully installed by using another script provided by the Vapor developers. Once again, download the script, inspect it, and then execute it:

    curl -sL check.vapor.sh -o check.vapor.sh
    less check.vapor.sh
    bash ./check.vapor.sh

You’ll see this output which indicates that Vapor has been installed successfully:

    Output✅ Compatible with Vapor 2

Now that Swift and Vapor have both been installed, you can create your first Vapor app.

## Step 3 — Create a Vapor app

To create our app, we will be using a template that Vapor provides by default. The `web` template lets you create a user-facing web application.

This template assumes you’re using Git and that you’ve configured it with your name and email address. If you haven’t, you may see an error message that will tell you to configure Git. You can safely ignore this message, or execute these commands to provide your details:

    git config --global user.email "your_email@example.com"
    git config --global user.name "Your Name"

To create a web app from this template, execute the following command:

    vapor new demo --template=web

The script generates a new application in a new directory with the name you specified:

    OutputCloning Template [Done]
    Updating Package Name [Done]
    Initializing git repository [Done]
    ...
                   _ _____  ______
                  \ \ / / /\ | |_) / / \ | |_)
                   \_\/ /_/--\ |_| \_\_/ |_| \
                     a web framework for Swift
    
                  Project "demo" has been created.
           Type `cd demo` to enter the project directory.
       Use `vapor cloud deploy` to host your project for free!
                               Enjoy!

If you would like to create an API instead of a full web app, you can use the `api` template with `vapor new demo --template=api`.

Take a look at the [source code for the web template](http://github.com/vapor/web-template) and the [api template](http://github.com/vapor/api-template) to see how they work.

Let’s run our app and see it in action.

## Step 4 — Compile and Run the Vapor Application

Swift applications must be compiled, unlike applications in Python or Ruby. This means that before you can run your Vapor app, you have to run a build process.

First, switch to the newly-created `demo` folder:

    cd demo

Then execute the `vapor build` command to compile the web application.

    vapor build

The first time you build the application, the process will fetch some dependencies. It will cache these and skip this step in the future which will make the build process much faster.

Once the build prcess completes, run the app with the following command:

    vapor run serve

The server will start, displaying this output:

    OutputRunning demo ...
    ...
    Starting server on 0.0.0.0:8080

You’ll see warnings about insecure hash and cipher keys, but you can ignore them while you’re trying out the demo. When you build your own app, follow the directions the warnings provide.

Open your web browser and visit `http://your_server_ip:8080` to see your working Vapor app’s welcome page.

## Conclusion

The Swift community is growing steadily, and there are plenty of ways to get involved. Although Swift is mostly used to build native iOS and macOS apps, Swift on the Linux platform is on the rise. You can learn more about Swift by reading [The Swift Programming Language](https://itunes.apple.com/us/book/the-swift-programming-language-swift-4/id881256329?mt=11), a free ebook from Apple. To learn more about Vapor, check out their [documentation](https://docs.vapor.codes/2.0/).
