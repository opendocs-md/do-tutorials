---
author: Tania Rascia
date: 2017-09-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/using-while-and-do-while-loops-in-javascript
---

# Using While and Do...While Loops in JavaScript

## Introduction

Automation is the technique of making a system operate automatically; in programming, we use **loops** to automate repetitious tasks. Loops are one of the most useful features of programming languages, and in this article we will learn about the `while` and `do...while` loops in JavaScript.

The `while` and `do...while` statements in JavaScript are similar to [conditional statements](how-to-write-conditional-statements-in-javascript), which are blocks of code that will execute if a specified condition results in [`true`](understanding-data-types-in-javascript#booleans). Unlike an `if` statement, which only evaluates once, a loop will run multiple times until the condition no longer evaluates to `true`.

Another common type of loop you will encounter is the [`for` statement](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/for), which executes a set number of times. `while` and `do...while` loops are conditionally based, and therefore it is not necessary to know beforehand how many times the loop will run.

## While Loop

In JavaScript, a `while` statement is a loop that executes as long as the specified condition evaluates to `true`.

The syntax is very similar to an `if` statement, as seen below.

    while (condition) {
        // execute code as long as condition is true
    }

The `while` statement is the most basic loop to construct in JavaScript.

As an example, let’s say we have an aquarium that has a population limit. For each iteration of the loop, we will add one fish. Once the aquarium has `10` fish, the population limit will be reached, and the program will cease to add more fish.

aquarium.js

    
    // Set population limit of aquarium to 10
    const popLimit = 10;
    
    // Start off with 0 fish
    let fish = 0;
    
    // Initiate while loop to run until fish reaches population limit
    while (fish < popLimit) {
        // add one fish for each iteration
        fish++;
        console.log("There's room for " + (popLimit - fish) + " more fish.");
    }

Once we run the above program, we’ll receive the following output, showing the iteration of the program through the `while` loop until the conditions are no longer evaluated as `true`.

    OutputThere's room for 9 more fish.
    There's room for 8 more fish.
    There's room for 7 more fish.
    There's room for 6 more fish.
    There's room for 5 more fish.
    There's room for 4 more fish.
    There's room for 3 more fish.
    There's room for 2 more fish.
    There's room for 1 more fish.
    There's room for 0 more fish.

In our example, we set our `while` loop to run as long as the number of fish was less than the population limit of the aquarium. For each iteration, one fish is added to the aquarium until all `10` spots are filled. At that point, the loop stops running.

## Infinite Loops

An **infinite loop** , as the name suggests, is a loop that will keep running forever. If you accidentally make an infinite loop, it could crash your browser or computer. It is important to be aware of infinite loops so you can avoid them.

A common infinite loop occurs when the condition of the `while` statement is set to `true`. Below is an example of code that will run forever. It is not necessary to test any infinite loops.

infiniteLoop.js

    
    // Initiate an infinite loop
    while (true) {
        // execute code forever
    }

An infinite loop will run forever, but the program can be terminated with the `break` keyword.

In the below example, we will add an `if` statement to the `while` loop, and when that condition is met, we will terminate the loop with `break`.

polarBears.js

    
    // Set a condition to true
    const iceCapsAreMelting = true;
    let polarBears = 5;
    
    // Initiate infinite loop
    while (iceCapsAreMelting) {
      console.log(`There are ${polarBears} polar bears.`);
      polarBears--;
      // Terminate infinite loop when following condition is true
      if (polarBears === 0) {
        console.log("There are no polar bears left.");
        break;
      }
    }

When we run the code above, the output will be as follows.

    OutputThere are 5 polar bears.
    There are 4 polar bears.
    There are 3 polar bears.
    There are 2 polar bears.
    There are 1 polar bears.
    There are no polar bears left.

Note that this is not necessarily a practical method of creating and terminating a loop, but `break` is a useful keyword to be aware of.

## Do…While Loop

We already learned about the `while` loop, which executes a block of code for as long as a specified condition is true. Building on that is the `do...while` statement, which is very similar to `while` with the major difference being that a `do...while` loop will always execute once, even if the condition is never true.

Below we will demonstrate the syntax of the `do...while` loop.

    do {
        // execute code
    } while (condition);

As you can see, the `do` portion of the loop comes first, and is followed by `while (condition)`. The code block will run, then the condition will be tested as it is in a normal `while` loop.

To test this, we can set a variable to `0`, increment it inside the `do` statement, and set our condition to `false`.

falseCondition.js

    
    // Set variable to 0
    let x = 0;
    
    do {
        // Increment variable by 1
        x++;
        console.log(x);
    } while (false);

    Output1

Our output came out to `1`, meaning that the code block iterated through the loop once (from `0`) before it was stopped by an unsuccessful `while` condition.

While keeping in mind that the loop will iterate at least once, the `do...while` loop can be used for the same purposes as a `while` loop.

## Conclusion

In this tutorial, we learned about the `while` loop, the `do...while` loop, and infinite loops in JavaScript.

Automation of repetitive tasks is an extremely important part of programming, and these loops can help make your programs more efficient and concise.

To learn more, read about the [`while`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/while) and [`do...while`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/do...while) loops on the Mozilla Developer Network.
