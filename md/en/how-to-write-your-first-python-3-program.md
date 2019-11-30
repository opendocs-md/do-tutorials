---
author: Lisa Tagliaferri
date: 2016-09-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-your-first-python-3-program
---

# How To Write Your First Python 3 Program

## Introduction

The “Hello, World!” program is a classic and time-honored tradition in computer programming. Serving as a simple and complete first program for beginners, as well as a good program to test systems and programming environments, “Hello, World!” illustrates the basic syntax of programming languages.

This tutorial will walk you through writing a “Hello, World” program in Python 3.

## Prerequisites

You should have [Python 3 installed](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) as well as a local programming environment set up on your computer.

If you don’t have one set up, you can use one of the installation and setup guides below that is appropriate for your operating system:

- [Ubuntu 16.04 or Debian 8](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04) 
- [CentOS 7](how-to-install-python-3-and-set-up-a-local-programming-environment-on-centos-7)
- [Mac OS X](how-to-install-python-3-and-set-up-a-local-programming-environment-on-mac-os-x)
- [Windows 10](how-to-install-python-3-and-set-up-a-local-programming-environment-on-windows-10)

## Writing the “Hello, World!” Program

To write the “Hello, World!” program, let’s open up a command-line text editor such as nano and create a new file:

    nano hello.py

Once the text file opens up in the terminal window we’ll type out our program:

hello.py

    print("Hello, World!")

Let’s break down the different components of the code.

`print()` is a **function** that tells the computer to perform an action. We know it is a function because it uses parentheses. `print()` tells Python to display or output whatever we put in the parentheses. By default, this will output to the current terminal window.

Some functions, like the `print()` function, are built-in functions included in Python by default. These built-in functions are always available for us to use in programs that we create. We can also [define our own functions](how-to-define-functions-in-python-3) that we construct ourselves through other elements.

Inside the parentheses of the `print()` function is a sequence of characters — `Hello, World!` — that is enclosed in quotation marks. Any characters that are inside of quotation marks are called a **[string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3)**.

Once we are done writing our program, we can exit nano by typing the `control` and `x` keys, and when prompted to save the file press `y`.

Once you exit out of nano you’ll return to your shell.

## Running the “Hello, World!” Program

With our “Hello, World!” program written, we are ready to run the program. We’ll use the `python3` command along with the name of our program file. Let’s run the program:

    python3 hello.py

The hello.py program that you just created will cause your terminal to produce the following output:

    OutputHello, World!

Let’s go over what the program did in more detail.

Python executed the line `print("Hello, World!")` by _calling_ the `print()` function. The string value of `Hello, World!` was _passed_ to the function.

In this example, the string `Hello, World!` is also called an **argument** since it is a value that is passed to a function.

The quotes that are on either side of `Hello, World!` were not printed to the screen because they are used to tell Python that they contain a string. The quotation marks delineate where the string begins and ends.

Since the program ran, you can now confirm that Python 3 is properly installed and that the program is syntactically correct.

## Conclusion

Congratulations! You have written the “Hello, World!” program in Python 3.

From here, you can continue to work with the `print()` function by writing your own strings to display, and can also create new program files.

Keep learning about programming in Python by reading our full tutorial series [How To Code in Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-python-3).
