---
author: Stack Abuse
date: 2019-08-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-and-run-your-first-program-in-node-js
---

# How To Write and Run Your First Program in Node.js

_The author selected the [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Node.js is a popular open-source runtime environment that can execute JavaScript outside of the browser using the V8 JavaScript engine, which is the same engine used to power the Google Chrome web browser’s JavaScript execution. The Node runtime is commonly used to create command line tools and web servers.

Learning Node.js will allow you to write your front-end code and your back-end code in the same language. Using JavaScript throughout your entire stack can help reduce time for context switching, and libraries are more easily shared between your back-end server and front-end projects.

Also, thanks to its support for asynchronous execution, Node.js excels at I/O-intensive tasks, which is what makes it so suitable for the web. Real-time applications, like video streaming, or applications that continuously send and receive data, can run more efficiently when written in Node.js.

In this tutorial you’ll create your first program with the Node.js runtime. You’ll be introduced to a few Node-specific concepts and build your way up to create a program that helps users inspect environment variables on their system. To do this, you’ll learn how to output strings to the console, receive input from the user, and access environment variables.

## Prerequisites

To complete this tutorial, you will need:

- Node.js installed on your development machine. This tutorial uses Node.js version 10.16.0. To install this on macOS or Ubuntu 18.04, follow the steps in [How to Install Node.js and Create a Local Development Environment on macOS](how-to-install-node-js-and-create-a-local-development-environment-on-macos) or the “Installing Using a PPA” section of [How To Install Node.js on Ubuntu 18.04](how-to-install-node-js-on-ubuntu-18-04).

- A basic knowledge of JavaScript, which you can find here: [How To Code in JavaScript](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-javascript)

## Step 1 — Outputting to the Console

To write a “Hello, World!” program, open up a command line text editor such as `nano` and create a new file:

    nano hello.js

With the text editor opened, enter the following code:

hello.js

    console.log("Hello World");

The `console` object in Node.js provides simple methods to write to `stdout`, `stderr`, or to any other Node.js stream, which in most cases is the command line. The `log` method prints to the `stdout` stream, so you can see it in your console.

In the context of Node.js, _streams_ are objects that can either receive data, like the `stdout` stream, or objects that can output data, like a network socket or a file. In the case of the `stdout` and `stderr` streams, any data sent to them will then be shown in the console. One of the great things about streams is that they’re easily redirected, in which case you can redirect the output of your program to a file, for example.

Save and exit `nano` by pressing `CTRL+X`, when prompted to save the file, press `Y`. Now your program is ready to run.

## Step 2 — Running the Program

To run this program, use the `node` command as follows:

    node hello.js

The `hello.js` program will execute and display the following output:

    Output Hello World

The Node.js interpreter read the file and executed `console.log("Hello World");` by calling the `log` method of the global `console` object. The string `"Hello World"` was passed as an argument to the `log` function.

Although quotation marks are necessary in the code to indicate that the text is a string, they are not printed to the screen.

Having confirmed that the program works, let’s make it more interactive.

## Step 3 — Receiving User Input via Command Line Arguments

Every time you run the Node.js “Hello, World!” program, it produces the same output. In order to make the program more dynamic, let’s get input from the user and display it on the screen.

Command line tools often accept various arguments that modify their behavior. For example, running `node` with the `--version` argument prints the installed version instead of running the interpreter. In this step, you will make your code accept user input via command line arguments.

Create a new file `arguments.js` with nano:

    nano arguments.js

Enter the following code:

arguments.js

    console.log(process.argv);

The `process` object is a _global_ Node.js object that contains functions and data all related to the currently running Node.js process. The `argv` property is an array of strings containing all the command line arguments given to a program.

Save and exit `nano` by typing `CTRL+X`, when prompted to save the file, press `Y`.

Now when you run this program, you provide a command line argument like this:

    node arguments.js hello world

The output looks like the following:

    Output [ '/usr/bin/node',
      '/home/sammy/first-program/arguments.js',
      'hello',
      'world' ]

The first argument in the `process.argv` array is always the location of the Node.js binary that is running the program. The second argument is always the location of the file being run. The remaining arguments are what the user entered, in this case: `hello` and `world`.

We are mostly interested in the arguments that the user entered, not the default ones that Node.js provides. Open the `arguments.js` file for editing:

    nano arguments.js

Change `console.log(process.arg);` to the following:

arguments.js

    console.log(process.argv.slice(2));

Because `argv` is an array, you can use JavaScript’s built-in `slice` method that returns a selection of elements. When you provide the `slice` function with `2` as its argument, you get all the elements of `argv` that comes _after_ its second element; that is, the arguments the user entered.

Re-run the program with the `node` command and the same arguments as last time:

    node arguments.js hello world

Now, the output looks like this:

    Output ['hello', 'world']

Now that you can collect input from the user, let’s collect input from the program’s environment.

## Step 4 — Accessing Environment Variables

_Environment variables_ are key-value data stored outside of a program and provided by the OS. They are typically set by the system or user and are available to all running processes for configuration or state purposes. You can use Node’s `process` object to access them.

Use `nano` to create a new file `environment.js`:

    nano environment.js

Add the following code:

environment.js

    console.log(process.env);

The `env` object stores _all_ the environment variables that are available when Node.js is running the program.

Save and exit like before, and run the `environment.js` file with the `node` command.

    node environment.js

Upon running the program, you should see output similar to the following:

    Output{ SHELL: '/bin/bash',
      SESSION_MANAGER:
       'local/digitalocean:@/tmp/.ICE-unix/1003,unix/digitalocean:/tmp/.ICE-unix/1003',
      COLORTERM: 'truecolor',
      SSH_AUTH_SOCK: '/run/user/1000/keyring/ssh',
      XMODIFIERS: '@im=ibus',
      DESKTOP_SESSION: 'ubuntu',
      SSH_AGENT_PID: '1150',
      PWD: '/home/sammy/first-program',
      LOGNAME: 'sammy',
      GPG_AGENT_INFO: '/run/user/1000/gnupg/S.gpg-agent:0:1',
      GJS_DEBUG_TOPICS: 'JS ERROR;JS LOG',
      WINDOWPATH: '2',
      HOME: '/home/sammy',
      USERNAME: 'sammy',
      IM_CONFIG_PHASE: '2',
      LANG: 'en_US.UTF-8',
      VTE_VERSION: '5601',
      CLUTTER_IM_MODULE: 'xim',
      GJS_DEBUG_OUTPUT: 'stderr',
      LESSCLOSE: '/usr/bin/lesspipe %s %s',
      TERM: 'xterm-256color',
      LESSOPEN: '| /usr/bin/lesspipe %s',
      USER: 'sammy',
      DISPLAY: ':0',
      SHLVL: '1',
      PATH:
       '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin',
      DBUS_SESSION_BUS_ADDRESS: 'unix:path=/run/user/1000/bus',
      _: '/usr/bin/node',
      OLDPWD: '/home/sammy' }

Keep in mind that many of the environment variables you see are dependent on the configuration and settings of your system, and your output may look substantially different than what you see here. Rather than viewing a long list of environment variables, you might want to retrieve a specific one.

## Step 5 — Accessing a Specified Environment Variable

In this step you’ll view environment variables and their values using the global `process.env` object and print their values to the console.

The `process.env` object is a simple mapping between environment variable names and their values stored as strings. Like all objects in JavaScript, you access an individual property by referencing its name in square brackets.

Open the `environment.js` file for editing:

    nano environment.js

Change `console.log(process.env);` to:

environment.js

    console.log(process.env["HOME"]);

Save the file and exit. Now run the `environment.js` program:

    node environment.js

The output now looks like this:

    Output /home/sammy

Instead of printing the entire object, you now only print the `HOME` property of `process.env`, which stores the value of the `$HOME` environment variable.

Again, keep in mind that the output from this code will likely be different than what you see here because it is specific to your system. Now that you can specify the environment variable to retrieve, you can enhance your program by asking the user for the variable they want to see.

## Step 6 — Retrieving An Argument in Response to User Input

Next, you’ll use the ability to read command line arguments and environment variables to create a command line utility that prints the value of an environment variable to the screen.

Use `nano` to create a new file `echo.js`:

    nano echo.js

Add the following code:

echo.js

    const args = process.argv.slice(2);
    console.log(process.env[args[0]]);

The first line of `echo.js` stores all the command line arguments that the user provided into a constant variable called `args`. The second line prints the environment variable stored in the first element of `args`; that is, the first command line argument the user provided.

Save and exit `nano`, then run the program as follows:

    node echo.js HOME

Now, the output would be:

    Output /home/sammy

The argument `HOME` was saved to the `args` array, which was then used to find its value in the environment via the `process.env` object.

At this point you can now access the value of any environment variable on your system. To verify this, try viewing the following variables: `PWD`, `USER`, `PATH`.

Retrieving single variables is good, but letting the user specify how many variables they want would be better.

## Step 7 — Viewing Multiple Environment Variables

Currently, the application can only inspect one environment variable at a time. It would be useful if we could accept multiple command line arguments and get their corresponding value in the environment. Use `nano` to edit `echo.js`:

    nano echo.js

Edit the file so that it has the following code instead:

echo.js

    const args = process.argv.slice(2);
    
    args.forEach(arg => {
      console.log(process.env[arg]);
    });

The `forEach` method is a standard JavaScript method on all array objects. It accepts a _callback function_ that is used as it iterates over every element of the array. You use `forEach` on the `args` array, providing it a callback function that prints the current argument’s value in the environment.

Save and exit the file. Now re-run the program with two arguments:

    node echo.js HOME PWD

You would see the following output:

    Output /home/sammy
    /home/sammy/first-program

The `forEach` function ensures that every command line argument in the `args` array is printed.

Now you have a way to retrieve the variables the user asks for, but we still need to handle the case where the user enters bad data.

## Step 8 — Handling Undefined Input

To see what happens if you give the program an argument that is not a valid environment variable, run the following:

    node echo.js HOME PWD NOT_DEFINED

The output will look similar to the following:

    Output /home/sammy
    /home/sammy/first-program
    undefined

The first two lines print as expected, and the last line only has `undefined`. In JavaScript, an `undefined` value means that a variable or property has not been assigned a value. Because `NOT_DEFINED` is not a valid environment variable, it is shown as `undefined`.

It would be more helpful to a user to see an error message if their command line argument was not found in the environment.

Open `echo.js` for editing:

    nano echo.js

Edit `echo.js` so that it has the following code:

echo.js

    const args = process.argv.slice(2);
    
    args.forEach(arg => {
      let envVar = process.env[arg];
      if (envVar === undefined) {
        console.error(`Could not find "${arg}" in environment`);
      } else {
        console.log(envVar);
      }
    });

Here, you have modified the callback function provided to `forEach` to do the following things:

1. Get the command line argument’s value in the environment and store it in a variable `envVar`.
2. Check if the value of `envVar` is `undefined`.
3. If the `envVar` is `undefined`, then we print a helpful message indicating that it could not be found.
4. If an environment variable was found, we print its value.

**Note** : The `console.error` function prints a message to the screen via the `stderr` stream, whereas `console.log` prints to the screen via the `stdout` stream. When you run this program via the command line, you won’t notice the difference between the `stdout` and `stderr` streams, but it is good practice to print errors via the `stderr` stream so that they can be easier identified and processed by other programs, which _can_ tell the difference.

Now run the following command once more:

    node echo.js HOME PWD NOT_DEFINED

This time the output will be:

    Output /home/sammy
    /home/sammy/first-program
    Could not find "NOT_DEFINED" in environment

Now when you provide a command line argument that’s not an environment variable, you get a clear error message stating so.

## Conclusion

Your first program displayed “Hello World” to the screen, and now you have written a Node.js command line utility that reads user arguments to display environment variables.

If you want to take this further, you can change the behavior of this program even more. For example, you may want to validate the command line arguments before you print. If an argument is undefined, you can return an error, and the user will only get output if all arguments are valid environment variables.
