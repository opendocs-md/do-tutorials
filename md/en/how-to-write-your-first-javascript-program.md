---
author: Lisa Tagliaferri
date: 2017-08-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-your-first-javascript-program
---

# How To Write Your First JavaScript Program

## Introduction

The “Hello, World!” program is a classic and time-honored tradition in computer programming. It’s a short and complete first program for beginners, and it’s a good way to make sure your environment is properly configured.

This tutorial will walk you through creating this program in JavaScript. However, to make the program more interesting, we’ll modify the traditional “Hello, World!” program so that it asks the user for their name. We’ll then use the name in a greeting. When you’re done with this tutorial, you’ll have an interactive “Hello, World!” program.

## Prerequisites

You can complete this tutorial by using the JavaScript Developer Console in your web browser. Before beginning this tutorial, you should have some familiarity with working with this tool. To learn more about it, you can read our tutorial “[How To Use the JavaScript Developer Console](how-to-use-the-javascript-developer-console).”

## Creating the “Hello, World!” Program

To write the “Hello, World!” program, first open up your preferred web browser’s JavaScript Console.

There are two primary ways that we can go about creating the “Hello, World!” program in JavaScript, with the `alert()` method and with the `console.log()` method.

### Using `alert()`

The first way that we can write this program is by using the `alert()` method, which will display an alert box over your current window with a specified message (in this case, it will be “Hello, World!”) and an `OK` button that will allow the user to close the alert.

Within the method we will pass the [string](how-to-work-with-strings-in-javascript) data type as the parameter. This string will be set to the value `Hello, World!` so that that value will be printed to the alert box.

To write this first style of “Hello, World!” program, we’ll encase the string within the parentheses of the `alert()` method. We’ll end our JavaScript statement with a [semicolon](understanding-syntax-and-code-structure-in-javascript#semicolons).

    alert("Hello, World!");

Once you press the `ENTER` key following your line of JavaScript, you should see the following alert pop up in your browser:

![JavaScript Console Alert Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-alert.png)

The Console will also print the result of evaluating an expression, which will read as `undefined` when the expression does not explicitly return something.

Pop-up alerts can be tedious to continue to click out of, so let’s go over how to create the same program by logging it to the Console with `console.log()`.

### Using `console.log()`

We can print the same string, except this time to the JavaScript console, by using the `console.log()` method. Using this option is similar to working with a programming language in your computer’s terminal environment.

As we did with `alert()`, we’ll pass the `"Hello, World!"` string to the `console.log()` method, between its parentheses. We’ll end our statement with a semicolon, as is typical of JavaScript syntax conventions.

    console.log("Hello, World!");

Once we press `ENTER`, the `Hello, World!` message will be printed to the Console:

    OutputHello, World!

In the next section, we’ll go over how to make this program more interactive for the user.

## Prompting for Input

Every time we run our existing “Hello, World!” program, it produces the same output. Let’s prompt the person running our program for their name. We can then use that name to customize the output.

For each of our JavaScript methods we used above, we can begin with one line prompting for input. We’ll use JavaScript’s `prompt()` method, and pass to it the string `"What is your name?"` to ask the user for their name. The input that is entered by the user will then be stored in the [variable](how-to-use-variables-in-python-3) `name`. We’ll end our expression with a semicolon.

    let name = prompt("What is your name?");

When you press `ENTER` to run this line of code, you’ll receive a pop-up prompt:

![JavaScript Prompt Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/hello-world/js-prompt.png)

The dialog box that pops up over your web browser window includes a text field for the user to enter input. Once the user enters a value into the text field, they will have to click on `OK` for the value to be stored. The user can also prevent a value from being recorded by clicking on the `Cancel` button.

It is important to use the JavaScript `prompt()` method only when it makes sense within the context of the program, as overusing it can become tedious for the user.

At this point, enter the name that you will want the program to greet. For this example, we’ll use the name `Sammy`.

Now that we have collected the value of the user’s name, we can move on to using that value to greet the user.

### Greeting the User with `alert()`

As discussed above, the `alert()` method creates a pop-up box over the browser window. We can use this method to greet the user by making use of the variable `name`.

We’ll be utilizing [string concatenation](how-to-work-with-strings-in-javascript#string-concatenation) to write a greeting of “Hello!” that addresses the user directly. So, let’s concatenate the string of `Hello` with the variable for name:

    "Hello, " + name + "!"

We have combined two strings, `"Hello, "` and `"!"` with the `name` variable in between. Now, we can pass this expression to the `alert()` method.

    alert("Hello, " + name + "!");

Once we press `ENTER` here, we’ll receive the following dialog box on the screen:

![JavaScript Prompt Output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/hello-world/prompt-output.png)

In this case the user’s name is Sammy, so the output has greeted Sammy.

Now let’s rewrite this so that the output is printed to the Console instead.

### Greeting the User with `console.log()`

As we looked at in a previous section, the `console.log()` method prints output to the Console, much like the `print()` function can print output to the terminal in Python.

We’ll be using the same concatenated string that we used with the `alert()` method, which combines the strings `"Hello, "` and `"!"` with the `name` variable:

    "Hello, " + name + "!"

This entire expression will be put within the parentheses of the `console.log()` method so that we will receive a greeting as output.

    console.log("Hello, " + name + "!");

For a user named Sammy, the output on the Console will be as follows:

    OutputHello, Sammy!

You now have a JavaScript program that takes input from a user and prints it back to the screen.

## Conclusion

Now that you know how to write the classic “Hello, World!” program, as well as prompt the user for input, and display that as output, you can work to expand your program further. For example, ask for the user’s favorite color, and have the program say that their favorite color is red. You might even try to use this same technique to create a Mad Lib program.
