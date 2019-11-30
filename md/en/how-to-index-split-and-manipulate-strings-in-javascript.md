---
author: Tania Rascia
date: 2017-07-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-index-split-and-manipulate-strings-in-javascript
---

# How To Index, Split, and Manipulate Strings in JavaScript

## Introduction

A **string** is a sequence of one or more characters that may consist of letters, numbers, or symbols. Each character in a JavaScript string can be accessed by an index number, and all strings have methods and properties available to them.

In this tutorial, we will learn the difference between string primitives and the `String` object, how strings are indexed, how to access characters in a string, and common properties and methods used on strings.

## String Primitives and String Objects

First, we will clarify the two types of strings. JavaScript differentiates between the **string primitive** , an immutable datatype, and the `String` object.

In order to test the difference between the two, we will initialize a string primitive and a string object.

    // Initializing a new string primitive
    const stringPrimitive = "A new string.";
    
    // Initializing a new String object
    const stringObject = new String("A new string.");  

We can use the `typeof` operator to determine the type of a value. In the first example, we simply assigned a string to a variable.

    typeof stringPrimitive;

    Outputstring

In the second example, we used `new String()` to create a string object and assign it to a variable.

    typeof stringObject;

    Outputobject

Most of the time you will be creating string primitives. JavaScript is able to access and utilize the built-in properties and methods of the `String` object wrapper without actually changing the string primitive you’ve created into an object.

While this concept is a bit challenging at first, you should be aware of the distinction between primitive and object. Essentially, there are methods and properties available to all strings, and in the background JavaScript will perform a conversion to object and back to primitive every time a method or property is called.

## How Strings are Indexed

Each of the characters in a string correspond to an index number, starting with `0`.

To demonstrate, we will create a string with the value `How are you?`.

| H | o | w | | a | r | e | | y | o | u | ? |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |

The first character in the string is `H`, which corresponds to the index `0`. The last character is `?`, which corresponds to `11`. The whitespace characters also have an index, at `3` and `7`.

Being able to access every character in a string gives us a number of ways to work with and manipulate strings.

## Accessing Characters

We’re going to demonstrate how to access characters and indices with the `How are you?` string.

    "How are you?";

Using square bracket notation, we can access any character in the string.

    "How are you?"[5];

    Outputr

We can also use the `charAt()` method to return the character using the index number as a parameter.

    "How are you?".charAt(5);

    Outputr

Alternatively, we can use `indexOf()` to return the index number by the first instance of a character.

    "How are you?".indexOf("o");

    Output1

Although “o” appears twice in the `How are you?` string, `indexOf()` will get the first instance.

`lastIndexOf()` is used to find the last instance.

    "How are you?".lastIndexOf("o");

    Output9

For both of these methods, you can also search for multiple characters in the string. It will return the index number of the first character in the instance.

    "How are you?".indexOf("are");

    Output4

The `slice()` method, on the other hand, returns the characters between two index numbers. The first parameter will be the starting index number, and the second parameter will be the index number where it should end.

    "How are you?".slice(8, 11);

    Outputyou

Note that `11` is `?`, but `?` is not part of the returned output. `slice()` will return what is between, but not including, the last parameter.

If a second parameter is not included, `slice()` will return everything from the parameter to the end of the string.

    "How are you?".slice(8);

    Outputyou?

To summarize, `charAt()` and `slice()` will help return string values based on index numbers, and `indexOf()` and `lastIndexOf()` will do the opposite, returning index numbers based on the provided string characters.

## Finding the Length of a String

Using the `length` property, we can return the number of characters in a string.

    "How are you?".length;

    Output12

Remember that the `length` property is returning the actual number of characters starting with 1, which comes out to 12, not the final index number, which starts at `0` and ends at `11`.

## Converting to Upper or Lower Case

The two built-in methods `toUpperCase()` and `toLowerCase()` are helpful ways to format text and make textual comparisons in JavaScript.

`toUpperCase()` will convert all characters to uppercase characters.

    "How are you?".toUpperCase();

    OutputHOW ARE YOU?

`toLowerCase()` will convert all characters to lowercase characters.

    "How are you?".toLowerCase();

    Outputhow are you?

These two formatting methods take no additional parameters.

It is worth noting that these methods do not change the original string.

## Splitting Strings

JavaScript has a very useful method for splitting a string by a character and creating a new [array](understanding-arrays-in-javascript) out of the sections. We will use the `split()` method to separate the array by a whitespace character, represented by `" "`.

    const originalString = "How are you?";
    
    // Split string by whitespace character
    const splitString = originalString.split(" ");
    
    console.log(splitString);

    Output['How', 'are', 'you?']

Now that we have a new array in the `splitString` variable, we can access each section with an index number.

    splitString[1];

    Outputare

If an empty parameter is given, `split()` will create a comma-separated array with each character in the string.

By splitting strings you can determine how many words are in a sentence, and use the method as a way to determine people’s first names and last names, for example.

## Trimming Whitespace

The JavaScript `trim()` method removes white space from both ends of a string, but not anywhere in between. Whitespace can be tabs or spaces.

    const tooMuchWhitespace = " How are you? ";
    
    const trimmed = tooMuchWhitespace.trim();
    
    console.log(trimmed);

    OutputHow are you?

The `trim()` method is a simple way to perform the common task of removing excess whitespace.

## Finding and Replacing String Values

We can search a string for a value, and replace it with a new value using the `replace()` method. The first parameter will be the value to be found, and the second parameter will be the value to replace it with.

    const originalString = "How are you?"
    
    // Replace the first instance of "How" with "Where"
    const newString = originalString.replace("How", "Where");
    
    console.log(newString);

    OutputWhere are you?

In addition to being able to replace a value with another string value, we can also use [Regular Expressions](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions) to make `replace()` more powerful. For instance, `replace()` only affects the first value, but we can use the `g` (global) flag to catch all instances of a value, and the `i` (case insensitive) flag to ignore case.

    const originalString = "Javascript is a programming language. I'm learning javascript."
    
    // Search string for "javascript" and replace with "JavaScript"
    const newString = originalString.replace(/javascript/gi, "JavaScript");
    
    console.log(newString);

    OutputJavaScript is a programming language. I'm learning JavaScript.

This is a very common task that makes use of Regular Expressions. Visit [Regexr](http://regexr.com/) to practice more examples of RegEx.

## Conclusion

Strings are one of the most frequently used data types, and there is a lot we can do with them.

In this tutorial, we learned the difference between the string primitive and `String` object, how strings are indexed, and how to use the built-in methods and properties of strings to access characters, format text, and find and replace values.

For a more general overview on strings, read the tutorial “[How To Work with Strings in JavaScript](how-to-work-with-strings-in-javascript).”
