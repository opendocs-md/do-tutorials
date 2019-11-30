---
author: Tania Rascia
date: 2017-09-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-the-switch-statement-in-javascript
---

# How To Use the Switch Statement in JavaScript

## Introduction

Conditional statements are among the most useful and common features of all programming languages. “[How To Write Conditional Statements in JavaScript](how-to-write-conditional-statements-in-javascript)” describes how to use the `if`, `else`, and `else if` keywords to control the flow of a program based on different conditions, which in JavaScript are often the result of user input.

In addition to `if...else`, JavaScript has a feature known as a `switch` statement. `switch` is a type of conditional statement that will evaluate an expression against multiple possible cases and execute one or more blocks of code based on matching cases. The `switch` statement is closely related to a conditional statement containing many `else if` blocks, and they can often be used interchangeably.

In this tutorial, we will learn how to use the `switch` statement, as well as how to use the related keywords `case`, `break`, and `default`. Finally, we’ll go through how to use multiple cases in a `switch` statement.

## Switch

The `switch` statement evaluates an expression and executes code as a result of a matching case. At first it can look a bit intimidating, but the basic syntax is similar to that of an `if` statement. It will always be written with `switch () {}`, with parentheses containing the expression to test, and curly brackets containing the potential code to execute.

Below is an example of a `switch` statement with two `case` statements, and a fallback known as `default`.

    switch (expression) {
        case x:
            // execute case x code block
            break;
        case y:
            // execute case y code block
            break;
        default:
            // execute default code block
    }

Following the logic of the code block above, this is the sequence of events that will take place.

- The expression is evaluated
- The first `case`, `x`, will be tested against the expression. If it matches, the code will execute, and the `break` keyword will end the `switch` block.
- If it does not match, `x` will be skipped and the `y` case will be tested against the expression. If `y` matches the expression, the code will execute and exit out of the `switch` block.
- If none of the cases match, the `default` code block will run.

Let’s make a working example of a `switch` statement following the syntax above. In this code block, we will find the current day of the week with the `new Date()` method, and `getDay()` to print a number corresponding to the current day. `1` stands for Monday, all the way through `7` which stands for Sunday. We’ll start by setting up our variable.

    const day = new Date().getDay();

Using `switch`, we will send a message to the console each day of the week. The program will run in order from top to bottom looking for a match, and once one is found, the `break` command will halt the `switch` block from continuing to evaluate statements.

week.js

    // Set the current day of the week to a variable, with 1 being Monday and 7 being Sunday
    const day = new Date().getDay();
    
    switch (day) {
        case 1:
            console.log("Happy Monday!");
            break;
        case 2:
            console.log("It's Tuesday. You got this!");
            break;
        case 3:
            console.log("Hump day already!");
            break;
        case 4:
            console.log("Just one more day 'til the weekend!");
            break;
        case 5:
            console.log("Happy Friday!");
            break;
        case 6:
            console.log("Have a wonderful Saturday!");
            break;
        case 7:
            console.log("It's Sunday, time to relax!");
            break;
        default:
            console.log("Something went horribly wrong...");
    }

    Output'Just one more day 'til the weekend!'

This code was tested on a Thursday, which corresponds to `4`, therefore the console output was `Just one more day 'til the weekend!`. Depending on what day of the week you are testing the code, your output will be different. We have included a `default` block at the end to run in case of an error, which in this case should not happen as there are only 7 days of the week. We also could have, for example, only printed results for Monday to Friday, and the `default` block could have had the same message for the weekend.

If we had omitted the `break` keyword in each statement, none of the other `case` statements would have evaluated to true, but the program would have continued to check until it reached the end. In order to make our programs faster and more efficient, we include the `break`.

## Switch Ranges

There might be an occasion in which you will need to evaluate a range of values in a `switch` block, as opposed to a single value as in our example above. We can do this by setting our expression to `true` and doing an operation within each `case` statement.

To make this easier to understand, we will use a familiar example. In the [conditional statements](how-to-write-conditional-statements-in-javascript) tutorial, we made a simple grading app which would take a number score and convert it to a letter grade, with the following requirements.

- Grade of 90 and above is an **A**
- Grade of 80 to 89 is a **B**
- Grade of 70 to 79 is a **C**
- Grade of 60 to 69 is a **D**
- Grade of 59 or below is an **F**

Now we can write that as a `switch` statement. Since we’re checking a range, we will perform the operation in each `case` to check if each expression is evaluating to `true` then break out of the statement once the requirements for `true` have been satisfied.

grades.js

    // Set the student's grade
    const grade = 87;
    
    switch (true) {
        // If score is 90 or greater
        case grade >= 90:
            console.log("A");
            break;
        // If score is 80 or greater
        case grade >= 80:
            console.log("B");
            break;
        // If score is 70 or greater
        case grade >= 70:
            console.log("C");
            break;
        // If score is 60 or greater
        case grade >= 60:
            console.log("D");
            break;
        // Anything 59 or below is failing
        default:
            console.log("F");
    }

    Output'B'

The expression in parentheses to be evaluated is `true` in this example. This means that any `case` that evaluates to `true` will be a match.

Just like with `else if`, `switch` is evaluated from top to bottom, and the first true match will be accepted. Therefore, even though our `grade` variable is `87` and therefore evaluates to `true` for C and D as well, the first match is B, which will be the output.

## Multiple Cases

You may encounter code in which multiple `case`s should have the same output. In order to accomplish this, you can use more than one `case` for each block of code.

In order to test this, we are going to make a small application matching the current month to the appropriate season. First, we will use the `new Date()` method to find a number corresponding to the current month, and apply that to the `month` variable.

    const month = new Date().getMonth();

The `new Date().getMonth()` method will output a number from `0` to `11`, with `0` being January and `11` being December. At the time of this publication, the month is September, which will correspond to `8`.

Our application will output the four seasons with the following specifications for simplicity:

- **Winter** : January, February, and March
- **Spring** : April, May, and June
- **Summer** : July, August, and September
- **Autumn** : October, November, and December

Below is our code.

seasons.js

    
    // Get number corresponding to the current month, with 0 being January and 11 being December
    const month = new Date().getMonth();
    
    switch (month) {
        // January, February, March
        case 0:
        case 1:
        case 2:
            console.log("Winter");
            break;
        // April, May, June
        case 3:
        case 4:
        case 5:
            console.log("Spring");
            break;
        // July, August, September
        case 6:
        case 7:
        case 8:
            console.log("Summer");
            break;
        // October, November, December
        case 9:
        case 10:
        case 11:
            console.log("Autumn");
            break;
        default:
            console.log("Something went wrong.");
    }

When we run the code, we’ll receive output identifying the current season based on the specifications above.

    OutputSummer

The current month at the time of publication was `8`, which corresponded to one of the `case` statements with the `"Summer"` season output.

## Conclusion

In this article, we reviewed the `switch` statement, a type of [conditonal statement](how-to-write-conditional-statements-in-javascript) which evaluates an expression and outputs different values based on matching results. We reviewed `switch` statements using a range and multiple `case` statements.

To learn more about `switch`, you can review it on the [Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/switch).
