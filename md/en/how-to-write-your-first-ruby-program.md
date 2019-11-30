---
author: Brian Hogan
date: 2017-06-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-your-first-ruby-program
---

# How To Write Your First Ruby Program

## Introduction

The “Hello, World!” program is a classic and time-honored tradition in computer programming. It’s a simple and complete first program for beginners, and it’s a good way to make sure your environment is properly configured.

This tutorial will walk you through creating this program in Ruby. However, to make the program more interesting, we’ll modify the traditional “Hello, World” program so that it asks the user for their name. We’ll then use the name in the greeting. When you’re done with the tutorial, you’ll have a program that looks like this when you run it:

    OutputPlease enter your name.
    Sammy
    Hello, Sammy! I'm Ruby!

## Prerequisites

You should have a [local Ruby development environment](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-ruby) set up on your computer. Set one up by following one of these tutorials:

- [How to Install Ruby and Set Up a Local Programming Environment on macOS](how-to-install-ruby-and-set-up-a-local-programming-environment-on-macos)
- [How to Install Ruby and Set Up a Local Programming Environment on Ubuntu 16.04](how-to-install-ruby-and-set-up-a-local-programming-environment-on-ubuntu-16-04) 
- [How to Install Ruby and Set Up a Local Programming Environment on Windows 10](how-to-install-ruby-and-set-up-a-local-programming-environment-on-windows-10)

## Step 1 — Writing the Basic “Hello, World!” Program

To write the “Hello, World!” program, let’s open up a command-line text editor such as `nano` and create a new file:

    nano hello.rb

Once the text file opens up in the terminal window we’ll type out our program:

hello.rb

    puts "Hello, World!" 

Let’s break down the different components of the code.

`puts` is a Ruby _method_ that tells the computer to print some text to the screen.

The `puts` method is then followed by a sequence of characters — `Hello, World!`, enclosed in quotation marks. Any characters that are inside of quotation marks are called a [_string_](understanding-data-types-in-ruby#strings). The `puts` method will print this string to the screen when the program runs.

Some methods, like the `puts` method, are included in Ruby by default. These built-in methods are always available when you create Ruby programs. You can also define your own methods.

Save and exit `nano` by typing the `CONTROL` and `X` keys, and when prompted to save the file, press `y`.

Let’s try our program out.

## Step 2 — Running a Ruby Program

With our “Hello, World!” program written, we are ready to run the program. We’ll use the `ruby` command, followed by the name of the file we just created.

    ruby hello.rb

The program will execute and display this output:

    OutputHello, World!

Let’s explore what actually happened.

Running the `ruby` command launched the Ruby **interpreter**. The Ruby interpreter read the file you specified and evaluated its contents. It executed the line `puts "Hello, World!"` by _calling_ the `puts` function. The string value of `Hello, World!` was _passed_ to the function.

In this example, the string `Hello, World!` is also called an **argument** since it is a value that is passed to a method.

The quotes that are on either side of `Hello, World!` were not printed to the screen because they are used to tell Ruby that they contain a string. The quotation marks delineate where the string begins and ends.

The program works, but we can make it more interactive. Let’s explore how.

## Step 3 — Prompting for Input

Every time we run our program, it produces the same output. Let’s prompt the person running our program for their name. We can then use that name in the output.

Instead of modifying your existing program, create a new program called `greeting.rb` in the `nano` editor:

    nano greeting.rb

First, add this line, which prompts the user to enter their name:

greeting.rb

    puts "Please enter your name."

Once again, we use the `puts` method to print some text to the screen.

Now add this line to capture the user input:

greeting.rb

    puts "Please enter your name."
    name = gets

This next line is a little more involved. Let’s break it down.

The `gets` method tells the computer to wait for input from the keyboard. This pauses the program, allowing the user to enter any text they want. The program will continue when the user presses the `ENTER` key on their keyboard. All of the keystrokes, including the `ENTER` keystroke, are then captured and converted to a _string_ of characters.

We want to use those characters in our program’s output, so we save those characters by _assigning_ the string to a _variable_ called `name`. Ruby stores that string in your computer’s memory until the program finishes.

Finally, add this line to print the output:

greeting.rb

    puts "Please enter your name."
    name = gets
    puts "Hi, #{name}! I'm Ruby!"

We use the `puts` method again, but this time we use a Ruby feature called _string interpolation_, which lets us take the value assigned to a variable and place it inside of a string. Instead of the word `name`, we’ll get the value we saved in the `name` variable, which should be the name of the user.

Save and exit `nano` by pressing `CTRL+X`, and press `y` when prompted to save the file.

Now run the program. You’ll be prompted for your name, so enter it and press `ENTER`. The output might not exactly what you expect:

    OutputPlease enter your name.
    Sammy
    Hi, Sammy
    ! I'm Ruby!

Instead of `Hi, Sammy! I'm Ruby!`, there’s a line break right after the name.

The program captured **all** of our keystrokes, including the `ENTER` key that we pressed to tell the program to continue. In a string, pressing the `ENTER` key creates a special character that creates a new line. The program’s output is doing exactly what we told it to do; it’s displaying the text we entered, including that new line. It’s just not what we wanted. But we can fix it.

Open the `greeting.rb` file in your editor:

    nano greeting.rb

Locate this line in your program:

greeting.rb

    name = gets

And modify it so it looks like this:

greeting.rb

    name = gets.chop

This uses Ruby’s `chop` method on the string that we captured with `gets`. The `chop` method removes the very last character from a string. In this case, it removes the newline character at the end of the string created when we pressed `ENTER`.

Save and exit `nano`. Press `CTRL+X`, then press `y` when prompted to save the file.

Run the program again:

    ruby greeting.rb

This time, after you enter your name and press `ENTER`, you get the expected output:

    OutputPlease enter your name.
    Sammy
    Hi, Sammy! I'm Ruby!

You now have a Ruby program that takes input from a user and prints it back to the screen.

## Conclusion

Now that you know how to prompt for input, process the results, and display output, try to expand your program further. For example, ask for the user’s favorite color, and have the program say that its favorite color is red. You might even try to use this same technique to create a simple Mad-Lib program.
