---
author: Lisa Tagliaferri
date: 2017-08-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-convert-data-types-in-javascript
---

# How To Convert Data Types in JavaScript

## Introduction

In JavaScript, [data types](understanding-data-types-in-javascript) are used to classify one particular type of data, determining the values that you can assign to the type and the operations you can perform on it.

Although due to [**type coercion**](how-to-convert-data-types-in-javascript#implicit-conversion), JavaScript will automatically convert many values, it is often best practice to manually convert values between types in order to achieve expected results.

This tutorial will guide you through converting JavaScript’s primitive data types, including numbers, strings, and Booleans.

## Implicit Conversion

As a programming language, JavaScript is very tolerant of unexpected values. Because of this, JavaScript will attempt to convert unexpected values rather than reject them outright. This implicit conversion is known as type coercion.

Some methods will automatically convert values in order to make use of them. The [`alert()` method](https://www.w3schools.com/jsref/met_win_alert.asp) takes a string as its parameter, but it will automatically convert other types into strings. So, we can pass a number value to the method:

    alert(8.5);

If we run the line above, the browser will return a pop-up alert dialog box that displays the `8.5` value except it will have been converted to a string in order to do so.

When using strings that can be evaluated to numbers with [mathematical operators](how-to-do-math-in-javascript-with-operators), you’ll find that JavaScript is able to handle the values by implicitly converting the strings to numbers, as shown in the examples below.

    // Subtraction
    "15" - "10";

    Output5

    // Modulo
    "15" % "10";

    Output5

However, not every operator will work as expected. The `+` operator is notably problematic as it can signify either addition or [string concatenation](how-to-work-with-strings-in-javascript#string-concatenation).

    // When working with strings, + stands for concatenation
    "2" + "3";

    Output"23"

Since the `+` operator is multi-purpose, the string values of `2` and `3`, despite being numerical strings, are concatenated to the string value of `23` rather than added together to be the number `5`.

Because ambiguity can exist and sometimes cause unexpected results, it is often best to explicitly convert data types in your code as much as possible. This will help with managing input from users and handling errors.

## Converting Values to Strings

Values can be explicitly converted to strings by calling either `String()` or `n.toString()`.

With the `String()` function, let’s convert a [Boolean value](understanding-data-types-in-javascript#booleans) to a string by passing the value `true` into the parameters for `String()`.

    String(true);

When we do this, the string literal `"true"` will be returned.

    Output"true"

Alternatively, we can pass a number into the function.

    String(49);

A string literal of that number will be returned.

    Output"49"

Let’s use the `String()` function with a variable. We’ll assign a number value to the variable `odyssey` and then use the `typeof` operator to check for type.

    let odyssey = 2001;
    console.log(typeof odyssey);

    Outputnumber

At this point, the variable `odyssey` is assigned the numerical value of `2001`, which we have confirmed to be a number.

Now, let’s reassign `odyssey` to its string equivalent and then use `typeof` to confirm that we have successfully converted the variable’s value from a number to a string.

    odyssey = String(odyssey); // "2001"
    console.log(typeof odyssey);

    Outputstring

In the example above, we have confirmed that `odyssey` was reassigned to be equivalent to a string value following the data type conversion.

We can use `n.toString()` in a similar way. We can replace `n` with a variable:

    let blows = 400;
    blows.toString();

The variable `blows` will be returned as a string.

    Output"400"

Alternatively, we can put a value within parentheses rather than a variable with `n.toString()`:

    (1776).toString(); // returns "1776"
    (false).toString(); // returns "false"
    (100 + 200).toString(); // returns "300"

By using `String()` or `n.toString()` we are able to explicitly convert values of Boolean or [number data types](understanding-data-types-in-javascript#numbers) to string values in order to ensure that our code behaves as we anticipate.

## Converting Values to Numbers

When converting values to a number data type, we’ll use the `Number()`method. Primarily, we’ll be converting strings of numerical text to numbers, but we can also convert Boolean values.

We can pass a string of a number to the `Number()` method:

    Number("1984");

The string will be converted to a number and no longer be enclosed within quotation marks.

    Output1984

We can also assign a string to a variable and then convert it.

    let dalmatians = "101";
    Number(dalmatians);

    Output101

The string literal `"101"` was converted to the number `101` via its variable.

Strings of white spaces or empty strings will convert to `0`.

    Number(" "); // returns 0
    Number(""); // returns 0

Be aware that strings of non-numbers will convert to `NaN` which stands for **N** ot **a**  **N** umber. This includes numbers separated by spaces.

    Number("twelve"); // returns NaN
    Number("20,000"); // returns NaN
    Number("2 3"); // returns NaN
    Number("11-11-11"); // returns NaN

For Boolean data types, `false` will evaluate to `0` and `true` will evaluate to `1`.

    Number(false); // returns 0
    Number(true); // returns 1

The `Number()` method converts non-number data types to numbers.

## Converting Values to Booleans

To convert numbers or strings to Boolean values, the `Boolean()` method is used. This can be useful for determining whether a user entered data into a text field or not, for example.

Any value that is interpreted as empty, like the number `0`, an empty string, or values that are undefined or `NaN` or `null` are converted to `false`.

    Boolean(0); // returns false
    Boolean(""); // returns false
    Boolean(undefined); // returns false
    Boolean(NaN); // returns false
    Boolean(null); // returns false

Other values will be converted to `true`, including string literals composed of white space.

    Boolean(2000); // returns true
    Boolean(" "); // returns true
    Boolean("Maniacs"); // returns true

Note that `"0"` as a string literal will convert to `true` since it is a non-empty string value:

    Boolean("0"); // returns true

Converting numbers and strings to Boolean values can allow us to evaluate data within binary terms and can be leveraged for control flow in our programs.

## Conclusion

This tutorial covered how JavaScript handles conversion of its primitive data types. Though due to type coercion, data types will implicitly convert in many cases, it is a good habit to explicitly convert data types in order to ensure that programs are functioning as expected.

To learn more about JavaScript’s data types, read “[Understanding Data Types in JavaScript](understanding-data-types-in-javascript).” To see how data type conversion is done in other programming languages, take a look at “[How To Convert Data Types in Python 3](how-to-convert-data-types-in-python-3).”
