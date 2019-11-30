---
author: Galen Gardo
date: 2019-05-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-f-and-set-up-a-local-programming-environment-on-ubuntu-18-04
---

# How To Install F# and Set Up a Local Programming Environment on Ubuntu 18.04

_The author selected the [Free Software Foundation](https://www.brightfunds.org/organizations/free-software-foundation-inc) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[F#](https://fsharp.org) is an open-source programming language initially developed at Microsoft Research to extend [.NET](https://dotnet.microsoft.com/), Microsoft’s set of tools, libraries, and languages to build applications and services. Besides its remarkably concise syntax, F# supports multiple [paradigms](https://en.wikipedia.org/wiki/Programming_paradigm), meaning that it can do different types of code structuring, though it was primarily designed to take advantage of the functional programming approach.

Adopting a specific _paradigm_, or a style of code, determines the way we will think and organize our programming problem solving. With an _imperative approach_, the design model used in languages like [C++](https://en.wikipedia.org/wiki/C%2B%2B) or [Java](https://www.java.com/en/), a developer describes step-by-step how the computer must accomplish a task. It’s about writing a sequence of statements that will change memory states at the program’s execution. This works fine until we encounter some irregular situations. Consider a _shared object_ for instance, which is used by multiple applications simultaneously. We might want to read its value at the same time that another component is modifying it. These are _concurrent actions_ upon a memory location that can produce data inconsistency and undefined behavior.

In [_functional code design_](https://docs.microsoft.com/en-us/dotnet/fsharp/introduction-to-functional-programming/), we prevent this kind of problem by minimizing the use of _mutable states_, or states that can change after we make them. Function is the keyword here, referring to mathematical transformations on some information provided as arguments. A functional code expresses what the program is by composing the solution as a set of functions to be executed. Typically, we build up layers of logic using functions that can return another function or take other functions as inputs.

Functional programming with F# brings a number of benefits:

- A more readable and expressive syntax that increases program maintainability.
- A code less prone to breaking and easier to debug because of stateless functions that can be isolated for testing.
- Native constructs that facilitate asynchronous programming and safer concurrency.
- Access to all the existing tools in the .NET world including the community-shared packages.

### Choosing a Runtime

Since F# is cross-platform, maintaining a similar execution model behavior through different operating systems is essential. .NET achieves this by means of a runtime. A _runtime system_ is a piece of software that orchestrates the execution of a program written with a specific programming language, handling interfacing with the operating system and memory management, among other things.

There are actually two .NET runtime implementations available on Linux: [.NET Core](https://docs.microsoft.com/en-us/dotnet/core/) and [Mono](https://www.mono-project.com). Historically, .NET only worked on Windows. In those days, one could resort to the community Mono project to run .NET applications on other platforms like Linux and macOS. Microsoft then launched .NET Core, a faster, modular subset of the original .NET framework, to target multiple platforms.

At the time of this tutorial’s publication, they both can be used for building web applications or command line utilities. That said, .NET Core does not ship models to create GUI desktop applications on Linux and macOS, while Mono is the only one to support mobile and gaming platforms. It is important to know these differences since the runtime you pick will shape the programs you will build. You could also choose to have both .NET Core and Mono installed in order to account for all use cases and to make a more productive stack.

In this tutorial, you will set up an F# programming environment on Ubuntu 18.04 using both .NET Core and Mono runtimes. You will then write some code examples to test and review build and compile methods.

## Prerequisites

To complete this tutorial, you will need basic familiarity with the command line and a computer running [Ubuntu 18.04](http://releases.ubuntu.com/18.04) with a [non-root user with sudo privileges](initial-server-setup-with-ubuntu-18-04#step-2-%E2%80%94-creating-a-new-user).

## Step 1 — Installing F# with .NET Core

Microsoft provides the [**.NET Core Software Development Kit (SDK)**](https://docs.microsoft.com/en-us/dotnet/core/sdk) for F# developers. A Software Development Kit is a set of programming tools that allows programmers to produce specialized applications and adapt them to various operating systems. It traditionally includes a text editor, languages support, a runtime, and a compiler, among other components. In this step, you are going to install this SDK. But first, you will register the Microsoft repository and fetch some dependencies.

You’ll be completing the installation and setup on the command line, which is a non-graphical way to interact with your computer. That is, instead of clicking on buttons, you’ll be typing in text and receiving feedback from your computer through text as well.

The command line, also known as a _shell_ or _terminal_, can help modify and automate many of the tasks you do on a computer every day, and is an essential tool for software developers. There are many terminal commands to learn that can enable you to do more powerful things. For more information about the command line, check out the [Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal) tutorial.

On Ubuntu 18.04, you can find the Terminal application by clicking on the Ubuntu icon in the upper-left hand corner of your screen and typing `terminal` into the search bar. Click on the Terminal application icon to open it. Alternatively, you can hit the `CTRL`, `ALT`, and `T` keys on the keyboard at the same time to open the Terminal application automatically.

![Ubuntu Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/UbuntuDebianSetUp/UbuntuSetUp.png)

Once you have opened the terminal, use the `wget` command to download a package containing some required files, the Microsoft repository configurations, and a key for server communication.

    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb

Now, add the Microsoft repository and install the packages to your system using the `dpkg -i` instruction.

    sudo dpkg -i packages-microsoft-prod.deb

Next, activate the _Universe_ repository, which on Ubuntu is a community-maintained archive of software that is free and open source. This will give you access to `apt-transport-https`, a dependency for enabling the Ubuntu package manager APT transport over HTTPS.

    sudo add-apt-repository universe
    sudo apt install apt-transport-https

Next, update available downloads:

    sudo apt update

Finally, install the [current version](https://dotnet.microsoft.com/download/linux-package-manager/ubuntu18-04/sdk-current) of the .NET SDK. This tutorial will use version 2.2:

    sudo apt install dotnet-sdk-2.2

Now that you have the .NET SDK installed, a quick way to check if everything went well is to try the .NET Core command line interface (CLI), which will be available in the shell once the SDK is downloaded and installed. Display information about your .NET setup by typing this in your terminal:

    dotnet --info

When you run a `dotnet` command for the first time, a text section is displayed as shown below:

    OutputWelcome to .NET Core!
    ---------------------
    Learn more about .NET Core: https://aka.ms/dotnet-docs
    Use 'dotnet --help' to see available commands or visit: https://aka.ms/dotnet-cli-docs
    
    Telemetry
    ---------
    The .NET Core tools collect usage data in order to help us improve your experience. The data is anonymous and doesn't include command-line arguments. The data is collected by Microsoft and shared with the community. You can opt-out of telemetry by setting the DOTNET_CLI_TELEMETRY_OPTOUT environment variable to '1' or 'true' using your favorite shell.
    
    Read more about .NET Core CLI Tools telemetry: https://aka.ms/dotnet-cli-telemetry
    ...

This notification is about collected data, and explains that some .NET CLI commands will send usage information to Microsoft. You will disable this in a moment; for now, look at the output from `dotnet --info`.

After a brief moment, the terminal will list information about your .NET installation:

    Output.NET Core SDK (reflecting any global.json):
     Version: 2.2.101
     Commit: 236713b0b7
    
    Runtime Environment:
     OS Name: ubuntu
     OS Version: 18.04
     OS Platform: Linux
     RID: ubuntu.18.04-x64
     Base Path: /usr/share/dotnet/sdk/2.2.101/
    
    Host (useful for support):
      Version: 2.2.0
      Commit: 1249f08fed
    
    .NET Core SDKs installed:
      2.2.101 [/usr/share/dotnet/sdk]
    
    .NET Core runtimes installed:
      Microsoft.AspNetCore.All 2.2.0 [/usr/share/dotnet/shared/Microsoft.AspNetCore.All]
      Microsoft.AspNetCore.App 2.2.0 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
      Microsoft.NETCore.App 2.2.0 [/usr/share/dotnet/shared/Microsoft.NETCore.App]
    
    To install additional .NET Core runtimes or SDKs:
      https://aka.ms/dotnet-download

Depending on the SDK version, the output may be slightly different, but this confirms that .NET Core is ready to use.

As mentioned before, the telemetry feature allows some .NET CLI commands to send usage information to Microsoft. It is enabled by default, and can be deactivated by setting the `DOTNET\_CLI\_TELEMETRY_OPTOUT` environment variable to `1`. To do so, add a new line to your `.profile` environment customization file by opening it in your text editor. For this tutorial, we will use `nano`:

    nano ~/.profile

Add the following line to the end of `.profile`:

~/.profile

    . . .
    export DOTNET_CLI_TELEMETRY_OPTOUT=1

Exit `nano` by pressing the `CTRL` and `X` keys. When prompted to save the file, press `Y` and then `ENTER`.

You can activate the new configuration using the `source` command:

    source ~/.profile

From now on, telemetry will be turned off at startup.

At this point you have .NET Core runtime, languages support, and libraries installed, allowing you to run and build some .NET applications. The `dotnet` CLI is also available for managing .NET source code and binaries. You could start building F# projects, but as mentioned previously, the .NET Core environment does not provide all the constructs needed to be completely cross-platform. For now you cannot use it to develop mobile applications, for example.

In order to solve this problem, in the next step you will install F# again, but this time with Mono.

## Step 2 — Installing F# with Mono

You can use Mono to fill in the remaining gaps in capability left by .NET Core. Mono and .NET Core are both based on the same standard library and both support .NET languages, but that is where the similarity ends. They use different runtimes, different CLIs, and different compilers, making it possible for them to be installed side by side to create a more reliable programming environment. In this section you are going to supplement your environment with the Mono tools for .NET programming and run an F# program from the command line.

A version of Mono is available in the Ubuntu repositories, but this can be outdated. Instead, add the [official Mono package repository](https://www.mono-project.com/download/stable/#download-lin) to your package manager:

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list

In the preceding commands, you used `apt-key` to retrieve keys for securing packages transferred from the official Mono repositories. You then added the Mono packages source to your repositories list.

With a new source list added for APT, update your repositories:

    sudo apt update

Next, download the Mono tools. Unlike .NET Core, Mono does not include F# tools, so you will download it as a separate package. Install `fsharp` and the `mono-complete` meta-package using the following command:

    sudo apt install mono-complete fsharp

**Note:** Because of the size of this download, the installation process for `mono-complete` may take a while.

Once done, you will have the compiler `fsharpc` and an interactive shell called `fsharpi` or simply FSI. FSI is an environment, inside the shell, that receives user’s input as an expression, evaluates it, then outputs the result and waits for another input. It is just like typing a command in the traditional shell and seeing the result, except here, inputs are F# expressions. FSI provides a fast method to test code or run scripts.

Activate FSI with the following command:

    fsharpi

This will start the interactive session and replace your regular prompt with the `fsharpi` prompt:

    OutputMicrosoft (R) F# Interactive version 4.1
    Copyright (c) Microsoft Corporation. All Rights Reserved.
    
    For help type #help;;
    
    >

You can return to the default shell by running `#quit;;`. In `fsharpi`, each command line ends with a double semicolon.

Let’s try a simple operation using the `printfn` function to render a message passed as a parameter:

    printfn "Hello World!";;

You will receive the following output:

    OutputHello World!
    val it : unit = ()
    
    > 

From the preceding interaction, `fsharpi` evaluates the expression as a [`unit` type](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/unit-type) value. The code is then executed and the result is printed with its type.

`fsharpi` can also run a file containing F# code. The script must be named with a `.fsx` extension and executed from the shell with the command:

    fsharpi some_script.fsx

Now that you know the F# installation is working, leave the shell with:

    > #quit;;

With Mono and .NET Core installed, you are now prepared to write any type of F# programs. FSI will allow you to test your code and run some scripts if needed, but executions will be slow. For your F# script to be executed, additional steps are performed to translate the source code into artifacts understandable by the processor, hence the slowness. To remedy this, in the next section you will compile your code with .NET Core, creating standalone binary files that can be immediately run by the machine.

## Step 3 — Writing and Compiling F# Programs with .NET Core

In this step, you will compile F# source code via command line compilers provided with .NET Core. This will allow you to make your applications faster and to produce preset executable packages for specific systems, making your program easier to distribute.

_Compiling_ is the transformation process that turns source code into binary file. The software that accomplishes this conversion is called a compiler. .NET Core relies on the `dotnet` CLI to perform compiling. To demonstrate this, you are going to create a basic F# source to review the compilation cases.

The `dotnet` CLI provides a complete application build toolchain. In general, an association of a command and the `dotnet` driver is used in the shell to complete a task. For example:

- `dotnet new` will create a project
- `dotnet build` will build a project and all of its dependencies
- `dotnet add package` will add a package reference to a project file

The following will create a new console project called `FSharpHello`. The `-lang` option sets the programming language you will code with while the `-o` option creates a directory in which to place the output.

    dotnet new console -lang F# -o FSharpHello

Once this is done, navigate into your newly created project directory:

    cd FSharpHello

This directory contains the `FSharpHello.fsproj` project configuration file and the `obj` folder which is used to store temporary object files. There is also the `Program.fs` file where your default source code exists. Open it in your text editor:

    nano Program.fs

The file has been automatically filled with a **Hello World** program:

Program.fs

    // Learn more about F# at http://fsharp.org
    
    open System
    
    [<EntryPoint>]
    let main argv =
        printfn "Hello World from F#!"
        0 // return an integer exit code

In this code, you start importing the `System` module with `open System`, then you define the program entry point, i.e., the place where the program starts when launched from the shell. The `main` function will call for a `Hello World` message printing to the console and will stop the program (`return an integer exit code`).

Exit out of the file.

To compile and run this code, use the following from the project directory `~/FSharpHello`:

    dotnet run

The program will run, printing the following output to the screen:

    OutputHello World from F#!

Note that it took a while for this program to run, just as with the FSI. As we mentioned before, it’s possible to run this faster by generating an executable, i.e., a binary file that can be run directly by the operating system. Here is how to achieve this:

    dotnet publish -c release -r linux-x64

This will produce the executable `bin/release/netcoreapp2.2/linux-x64/publish/FSharpHello.dll` file. This is a shared library that will run on a 64-bit Linux architecture. To export a generic executable for macOS systems, you would replace the `linux-x64` runtime identifier ([RID](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog#using-rids)) with `osx-x64`.

Now execute the file with the following command:

    dotnet bin/release/netcoreapp2.2/linux-x64/publish/FSharpHello.dll

This time, you will receive the output much quicker, since the program is already translated into binary.

Now that you know how to compile in .NET Core, let’s see how Mono compiles programs with the dedicated `fsharpc` command.

## Step 4 — Writing and Compiling F# Programs with Mono

Mono’s compilation process is similar to that of .NET Core, but this time there is a specific command used to compile the program. The `fsharpc` command is the tool, and it has been created only for compiling.

This time, create a `hello.fs` file and write some F# code. First, return to your home directory:

    cd

Next, open up a new file named `hello.fs`:

    nano hello.fs

Add the following line to the file:

hello.fs

    open System

As seen before, this imports the `System` module or namespace, giving you access to built-in system functions and objects like `Console`.

Now, add in some more lines of code:

hello.fs

    open System
    
    let hello() =
        printf "Who are you? "
        let name = Console.ReadLine()
        printfn "Oh, Hello %s!\nI'm F#." name

These new lines define the `hello()` function to read user input and print a feedback message.

Now you can add the final lines:

hello.fs

    open System
    
    let hello() =
        printf "Who are you? "
        let name = Console.ReadLine()
        printfn "Oh, Hello %s!\nI'm F#." name
    
    hello()
    Console.ReadKey() |> ignore

Here you are calling the function `hello()`, then using the `ReadKey()` method to end the program with a final keystroke.

Save and exit the file.

Now with the `fsharpc` command, use the `-o` flag to define the output filename and compile your `hello.fs` source code like this:

    fsharpc hello.fs -o hello

The preceding command will generate a `hello` executable file you can run with the `mono` command:

    mono hello

This gives you the following output and awaits user input:

    OutputWho are you?

If you type in `Sammy`, you will get the following.

    OutputOh, Hello Sammy!
    I'm F#.

Press a final keystroke, and the program will end.

Congratulations! You have written and compiled your first F# program, both with Mono and .NET Core.

## Conclusion

In this tutorial, you installed tooling for F# programming, covering both .NET Core and Mono environments. You also tested examples of F# code and built executables. These are the first steps toward learning this practical functional language.

Next steps could be to [learn](https://fsharpforfunandprofit.com/series/thinking-functionally.html) the [language](https://fsharp.org/about/index.html#documentation) and get in touch with the [community](https://fsharp.org/community/projects/). Also, with projects getting more complex, you might need to manage code and resources more efficiently. Package managers like [NuGet](https://www.nuget.org) or [Paket](https://fsprojects.github.io/Paket/) are bridges to the strong ecosystem built around .NET and tools-of-choice for organizing large programs.
