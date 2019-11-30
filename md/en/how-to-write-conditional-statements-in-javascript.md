---
author: Tania Rascia
date: 2017-08-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-conditional-statements-in-javascript
---

# How To Write Conditional Statements in JavaScript

## Introduction

In programming, there will be many occasions in which you will want different blocks of code to run depending on user input or other factors.

As an example, you might want a form to submit if each field is filled out properly, but you might want to prevent that form from submitting if some required fields are missing. In order to achieve tasks like these we have **conditional statements** , which are an integral part of all programming languages.

Conditional statements execute a specific action based on the results of an outcome of [`true` or `false`](understanding-data-types-in-javascript#booleans).

A few examples of JavaScript conditional statements you might see include:

- Check the location of a user and display the correct language based on country
- Send a form on submit, or display warnings next to missing required fields
- Open a dropdown on a click event, or close a dropdown if it is already open
- Display an alcohol purveyor’s website if the user is over the legal drinking age
- Display the booking form for a hotel but not if the hotel is booked

Conditional statements are part of the logic, decision making, or flow control of a computer program. You can compare a conditional statement to a “[Choose Your Own Adventure](https://en.wikipedia.org/wiki/Choose_Your_Own_Adventure)” book, or a flowchart.

In this tutorial, we will go over conditional statements, including the `if`, `else`, and `else if` keywords. We will also cover the ternary operator.

## If Statement

The most fundamental of the conditional statements is the `if` statement. An `if` statement will evaluate whether a statement is true or false, and only run if the statement returns `true`. The code block will be ignored in the case of a `false` result, and the program will skip to the next section.

An `if` statement is written with the `if` keyword, followed by a condition in parentheses, with the code to be executed in between curly brackets. In short, it can be written as `if () {}`.

Here is a longer examination of the basic `if` statement.

    if (condition) {
        // code that will execute if condition is true
    }

The contents of an `if` statement are indented, and the curly brackets containing the block of code to run do not end in a semicolon, just like a function block.

As an example, let’s consider a shopping app. Say, for the functionality of this app, a user who has deposited a certain amount of funds into their account would then like to buy an item from the store.

shop.js

    // Set balance and price of item
    const balance = 500;
    const jeans = 40;
    
    // Check if there are enough funds to purchase item
    if (jeans <= balance) {
      console.log("You have enough money to purchase the item!");
    }

    OutputYou have enough money to purchase the item!

We have an account balance of `500`, and want to buy a pair of jeans for `40`. Using the less than or equal to operator, we can check if the price of jeans is less than or equal to the amount of funds we have. Since `jeans <= balance` evaluates to `true`, the condition will pass and the block of code will run.

In a new example, we will create a new shop item that costs more than the available balance.

shop.js

    // Set balance and price of item
    const balance = 500;
    const phone = 600;
    
    // Check if there is enough funds to purchase item
    if (phone <= balance) {
        console.log("You have enough money to purchase the item!");
    }

This example will have no output, since `phone <= balance` evaluates to `false`. The code block will simply be ignored, and the program will proceed to the next line.

## Else Statement

With `if` statements, we only execute code when a statement evaluates to `true`, but often we will want something else to happen if the condition fails.

For example, we might want to display a message telling the user which fields were filled out correctly if a form did not submit properly. In this case, we would utilize the `else` statement, which is the code that will execute if the original condition does not succeed.

The `else` statement is written after the `if` statement, and it has no condition in parentheses. Here is the syntax for a basic `if...else` statement.

    if (condition) {
        // code that will execute if condition is true
    } else {
        // code that will execute if condition is false
    }

Using the same example as above, we can add a message to display if the funds in the account are too low.

shop.js

    // Set balance and price of item
    const balance = 500;
    const phone = 600;
    
    // Check if there is enough funds to purchase item
    if (phone <= balance) {
        console.log("You have enough money to purchase the item!");
    } else {
        console.log("You do not have enough money in your account to purchase this item.");
    }

    OutputYou do not have enough money in your account to purchase this item.

Since the `if` condition did not succeed, the code moves on to what’s in the `else` statement.

This can be very useful for showing warnings, or letting the user know what actions to take to move forward. Usually an action will be required on both success and failure, so `if...else` is more common than a solo `if` statement.

## Else if Statement

With `if` and `else`, we can run blocks of code depending on whether a condition is `true` or `false`. However, sometimes we might have multiple possible conditions and outputs, and need more than simply two options. One way to do this is with the `else if` statement, which can evaluate more than two possible outcomes.

Here is a basic example of a block of code that contains an `if` statement, multiple `else if` statements, and an `else` statement in case none of the conditions evaluated to `true`.

    if (condition a) {
        // code that will execute if condition a is true
    } else if (condition b) {
        // code that will execute if condition b is true
    } else if (condition c) {
        // code that will execute if condition c is true
    } else {
        // code that will execute if all above conditions are false
    }

JavaScript will attempt to run all the statements in order, and if none of them are successful, it will default to the `else` block.

You can have as many `else if` statements as necessary. In the case of many `else if` statements, the [`switch` statement](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/switch) might be preferred for readability.

As an example of multiple `else if` statements, we can create a grading app that will output a letter grade based on a score out of 100.

The requirements of this app are as follows:

- Grade of 90 and above is an A
- Grade of 80 to 89 is a B
- Grade of 70 to 79 is a C
- Grade of 60 to 69 is a D
- Grade of 59 or below is an F

Below we will create a simple set of `if`, `else`, and `else if` statements, and test them against a given grade.

grades.js

    // Set the current grade of the student
    let grade = 87;
    
    // Check if grade is an A, B, C, D, or F
    if (grade >= 90) {
      console.log("A");
    } else if (grade >= 80) {
      console.log("B");
    } else if (grade >= 70) {
      console.log("C");
    } else if (grade >= 60) {
      console.log("D");
    } else {
      console.log("F");
    }

    OutputB

In our example, we first check for the highest score, which will be greater than or equal to `90`. After that, the `else if` statements will check for greater than `80`, `70`, and `60` until it reaches the default `else` of a failing grade.

Although our `grade` value of `87` is technically also true for `C`, `D` and `F`, the statements will stop at the first one that is successful. Therefore, we get an output of `B`, which is the first match.

## Ternary Operator

The **ternary operator** , also known as the conditional operator, is used as shorthand for an `if...else` statement.

A ternary operator is written with the syntax of a question mark (`?`) followed by a colon (`:`), as demonstrated below.

    (condition) ? expression on true : expression on false

In the above statement, the condition is written first, followed by a `?`. The first expression will execute on `true`, and the second expression will execute on `false`. It is very similar to an `if...else` statement, with more compact syntax.

In this example, we will create a program that checks if a user is `21` or older. If they are, it will print `"You may enter"` to the console. If they are not, it will print `"You may not enter."` to the console.

age.js

    // Set age of user
    let age = 20;
    
    // Place result of ternary operation in a variable
    const oldEnough = (age >= 21) ? "You may enter." : "You may not enter.";
    
    // Print output
    oldEnough;

    Output'You may not enter.'

Since the `age` of the user was less than `21`, the fail message was output to the console. The `if...else` equivalent to this would be `"You may enter."` in the `if` statement, and `"You may not enter."` in the `else` statement.

## Conclusion

Conditional statements provide us with flow control to determine the output of our programs. They are one of the foundational building blocks of programming, and can be found in virtually all programming languages.

In this article, we learned about how to use the `if`, `else`, and `else if` keywords, and covered nesting of statements, and use of the ternary operator.
