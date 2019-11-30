---
author: Lisa Tagliaferri
date: 2017-06-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-data-types-in-javascript
---

# Understanding Data Types in JavaScript

## Introduction

**Data types** are used to classify one particular type of data in programming languages. For instance, a number and a string of characters are different types of data that will be treated differently by JavaScript.

This is important because the specific data type you use will determine what values you can assign to it and what you can do to it. This is to say, to be able to do operations with variables in JavaScript, it is important to understand the data type of any given variable.

In this tutorial, we will go over how data types work in JavaScript as well as the important data types native to the language. This is not an exhaustive investigation of data types, but will help you become familiar with the options available to you in JavaScript.

## Dynamic Typing

JavaScript has dynamic data types, meaning that type checking is done at runtime rather than compile time. Python’s [data types](understanding-data-types-in-python-3) are also dynamically typed.

With dynamically typed languages, a variable of the same name can be used to hold different data types.

For example, the variable `t`, defined as a variable by the `let` keyword (note that `let` keeps a given variable limited in scope), can be assigned to hold different data types, or can be initialized but left undefined:

    let t = 16; // t is a number
    let t = "Teresa"; // t is a string
    let t = true; // t is a Boolean
    let t; // t is undefined

Each of the variables `t` above can be set to any data type available in JavaScript; they do not need to be explicitly declared with a data type before they are used.

## Numbers

JavaScript has only one number type, there is no separate designation for integers and floating-point numbers. Because of this, numbers can be written in JavaScript with or without decimals:

    let num1 = 93;
    let num2 = 93.00;

In both cases above, the data type is a number and is the same regardless of whether or not the number has decimal points.

Scientific exponential notation can be used in JavaScript to abbreviate very large or small numbers, as in the following examples:

    let num3 = 987e8; // 98700000000
    let num4 = 987e-8; // 0.00000987

Numbers in JavaScript are considered to be accurate up to 15 digits. That means that numbers will be rounded after the 16th digit is reached:

    let num5 = 999999999999999; // remains as 999999999999999
    let num6 = 9999999999999999; // rounded up to 10000000000000000

In addition to representing numbers, the JavaScript number type also has three symbolic values available:

- `Infinity` — a numeric value that represents a **positive** number that approaches infinity
- `-Infinity`— a numeric value that represents a **negative** number that approaches infinity
- `NaN` — a numeric value that represents a non-number, standing for **n** ot **a**  **n** umber

`Infinity` or `-Infinity` will be returned if you calculate a number outside of the largest possible number available in JavaScript. These will also occur for values that are undefined, as when dividing by zero:

    let num7 = 5 / 0; // will return Infinity
    let num8 = -5 / 0; // will return -Infinity

In technical terms, `Infinity` will be displayed when a number exceeds the number `1.797693134862315E+308`, which represents the upper limit in JavaScript.

Similarly, `-Infinity` will be displayed when a number goes beyond the lower limit of `-1.797693134862316E+308`.

The number `Infinity` can also be used in loops:

    while (num9 != Infinity) { 
        // Code here will execute through num9 = Infinity
    }

For numbers that are not legal numbers, `NaN` will be displayed. If you attempt to perform a mathematical operation on a number and a non-numeric value, `NaN` will be returned. This is the case in the following example:

    let x = 20 / "Shark"; // x will be NaN

Since the number `20` cannot be divided by the string `"Shark"` because it cannot be evaluated as a number, the returned value for the `x` variable is `NaN`.

However, if a string can be evaluated as a numeric value, the mathematical expression can be performed in JavaScript:

    let y = 20 / "5"; // y will be 4

In the above example, since the string `"5"` can be evaluated as a numeric value in JavaScript, it is treated as such and will work with the mathematical operator for division, `/`.

When assigning the value `NaN` to a variable used in an operation, it will result in the value of `NaN`, even when the other operand is a legal number:

    let a = NaN;
    let b = 37;
    let c = a + b; // c will be NaN

There is only one number data type in JavaScript. When working with numbers, any number you enter will be interpreted as the data type for numbers; you are not required to declare what kind of data type you are entering because JavaScript is dynamically typed.

## Strings

A **string** is a sequence of one or more characters (letters, numbers, symbols). Strings are useful in that they represent textual data.

In JavaScript, strings exist within either single quotes `'` or double quotes `"`, so to create a string, enclose a sequence of characters in quotes:

    let singleQuotes = 'This is a string in single quotes.';

    let doubleQuotes = "This is a string in double quotes.";

You can choose to use either single quotes or double quotes, but whichever you decide on you should remain consistent within a program.

The program “Hello, World!” demonstrates how a string can be used in computer programming, as the characters that make up the phrase `Hello, World!` in the `alert()` below are a string.

hello.html

    <!DOCTYPE HTML>
    <html>
    <head>
    <script>
    function helloFunction() {
        alert("Hello, World!");
    }
    </script>
    </head>
    <body>
    <p><button onclick="helloFunction()">Click me</button></p>
    </body>
    </html>

When we run the code and click on the `Click me` button, we’ll receive a pop-up with the following output:

    OutputHello, World!

As with other data types, we can store strings in variables:

    let hw = "Hello, World!";

And display the string in the `alert()` by calling the variable:

hello.html

    ...
    <script>
    let hw = "Hello, World!";
    function helloFunction() {
        alert(hw);
    }
    </script>
    ...

    OutputHello, World!

There are many operations that we can perform on strings within our programs in order to manipulate them to achieve the results we are seeking. Strings are important for communicating information to the user, and for the user to communicate information back to the program.

## Booleans

The **Boolean** data type can be one of two values, either **true** or **false**. Booleans are used to represent the truth values that are associated with the logic branch of mathematics, which informs algorithms in computer science.

Whenever you see the data type Boolean, it will start with a capitalized **B** because it is named for the mathematician George Boole.

Many operations in math give us answers that evaluate to either true or false:

- **greater than**
  - 500 \> 100 `true`
  - 1 \> 5 `false`
- **less than**
  - 200 \< 400 `true`
  - 4 \< 2 `false`
- **equal**
  - 5 = 5 `true`
  - 500 = 400 `false`

Like with other data types, we can store a Boolean value in a variable:

    let myBool = 5 > 8; // false

Since 5 is not greater than 8, the variable `myBool` has the value of `false`.

As you write more programs in JavaScript, you will become more familiar with how Booleans work and how different functions and operations evaluating to either true or false can change the course of the program.

## Arrays

An **array** can hold multiple values within a single variable. This means that you can contain a list of values within an array and iterate through them.

Each item or value that is inside of an array is called an **element**. You can refer to the elements of an array by using an index number.

Just as strings are defined as characters between quotes, arrays are defined by having values between square brackets `[]`.

An array of strings, for example, looks like this:

    let fish = ["shark", "cuttlefish", "clownfish", "eel"];

If we call the variable `fish`, we’ll receive the following output:

    ["shark", "cuttlefish", "clownfish", "eel"]

Arrays are a very flexible data type because they are mutable in that they can have element values added, removed, and changed.

## Objects

The JavaScript **object** data type can contain many values as **name:value** pairs. These pairs provide a useful way to store and access data. The object literal syntax is made up of name:value pairs separated by colons with curly braces on either side `{ }`.

Typically used to hold data that are related, such as the information contained in an ID, a JavaScript object literal looks like this, with whitespaces between properties:

    let sammy = {firstName:"Sammy", lastName:"Shark", color:"blue", location:"ocean"};

Alternatively, and especially for object literals with a high number of name:value pairs, we can write this data type on multiple lines, with a whitespace after each colon:

    let sammy = {
        firstName: "Sammy",
        lastName: "Shark",
        color: "blue",
        location: "Ocean"
    };
    

The object variable `sammy` in each of the examples above has 4 properties: `firstName`, `lastName`, `color`, and `location`. These are each passed values separated by colons.

## Working with Multiple Data Types

While each program you create will contain multiple data types, it is important to keep in mind that you will generally be performing operations within the same data type. That is, you’ll be performing mathematics on numbers, or slicing strings.

When you use an operator that works across data types, like the `+` operator that can add numbers or concatenate strings, you may achieve unexpected results.

For example, when using the `+` operator with numbers and strings together, the numbers will be treated as a string (thus they will be concatenated), but the order of the data types will influence the concatenation.

So, if you create a variable that performs the following concatenation, JavaScript will interpret each element below as a string:

    let o = "Ocean" + 5 + 3;

If you the call the `o` variable, you’ll get the following value returned:

    OutputOcean53

However, if you lead with numbers, the two numbers will be added before they are then interpreted as a string when the program runtime reaches `"Ocean"`, so the returned value will be the sum of the two numbers concatenated with the string:

    let p = 5 + 3 + "Ocean";

    Output8Ocean

Because of these unexpected outcomes, you’ll likely be performing operations and methods within one data type rather than across them. JavaScript, however, does not return errors when mixing data types, as some other programming languages do.

## Conclusion

At this point, you should have a better understanding of some of the major data types that are available for you to use in JavaScript.

Each of these data types will become important as you develop programming projects in the JavaScript language.
