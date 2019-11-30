---
author: Lisa Tagliaferri
date: 2016-09-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-working-with-strings-in-python-3
---

# An Introduction to Working with Strings in Python 3

## Introduction

A **string** is a sequence of one or more characters (letters, numbers, symbols) that can be either a constant or a variable. Made up of Unicode, strings are immutable sequences, meaning they are unchanging.

Because text is such a common form of data that we use in everyday life, the string data type is a very important building block of programming.

This Python tutorial will go over how to create and print strings, how to concatenate and replicate strings, and how to store strings in variables.

## Creating and Printing Strings

Strings exist within either single quotes `'` or double quotes `"` in Python, so to create a string, enclose a sequence of characters in one or the other:

    'This is a string in single quotes.'

    "This is a string in double quotes."

You can choose to use either single quotes or double quotes, but whichever you decide on you should be consistent within a program.

We can print out strings by simply calling the `print()` function:

    print("Let's print out this string.")

    OutputLet's print out this string.

With an understanding of how strings are formatted in Python, let’s take a look at how we can work with and manipulate strings in programs.

## String Concatenation

Concatenation means joining strings together end-to-end to create a new string. To concatenate strings, we use the `+` operator. Keep in mind that when we work with [numbers, `+` will be an operator for addition](how-to-do-math-in-python-3-with-operators#addition-and-subtraction), but when used with strings it is a joining operator.

Let’s combine the strings `"Sammy"` and `"Shark"` together with concatenation through a `print()` statement:

    print("Sammy" + "Shark")

    OutputSammyShark

If we would like a whitespace between the two strings, we can simply include the whitespace within a string, like after the word “Sammy”:

    print("Sammy " + "Shark")

    OutputSammy Shark

Be sure not to use the `+` operator between two different data types. We can’t concatenate strings and integers together, for instance. So, if we try to write:

    print("Sammy" + 27)

We will receive the following error:

    OutputTypeError: Can't convert 'int' object to str implicitly

If we wanted to create the string `"Sammy27"`, we could do so by putting the number `27` in quotes (`"27"`) so that it is no longer an integer but is instead a string. [Converting numbers to strings](how-to-convert-data-types-in-python-3#converting-with-strings) for concatenation can be useful when dealing with zip codes or phone numbers, for example, as we don’t want to perform addition between a country code and an area code, but we do want them to stay together.

When we combine two or more strings through concatenation we are creating a new string that we can use throughout our program.

## String Replication

There may be times when you need to use Python to automate tasks, and one way you may do this is through repeating a string several times. You can do so with the `*` operator. Like the `+` operator, [the `*` operator has a different use when used with numbers](how-to-do-math-in-python-3-with-operators#multiplication-and-division), where it is the operator for multiplication. When used with one string and one integer, `*` is the **string replication operator** , repeating a single string however many times you would like through the integer you provide.

Let’s print out “Sammy” 9 times without typing out “Sammy” 9 times with the `*` operator:

    print("Sammy" * 9)

    OutputSammySammySammySammySammySammySammySammySammy

With string replication, we can repeat the single string value the amount of times equivalent to the integer value.

## Storing Strings in Variables

**[Variables](how-to-use-variables-in-python-3)** are symbols that you can use to store data in a program. You can think of them as an empty box that you fill with some data or value. Strings are data, so we can use them to fill up a variable. Declaring strings as variables can make it easier for us to work with strings throughout our Python programs.

To store a string inside a variable, we simply need to assign a variable to a string. In this case let’s declare `my_str` as our variable:

    my_str = "Sammy likes declaring strings."

Now that we have the variable `my_str` set to that particular string, we can print the variable like so:

    print(my_str)

And we will receive the following output:

    OutputSammy likes declaring strings.

By using variables to stand in for strings, we do not have to retype a string each time we want to use it, making it simpler for us to work with and manipulate strings within our programs.

## Conclusion

This tutorial went over the basics of working with the string data type in the Python 3 programming language. Creating and printing strings, concatenating and replicating strings, and storing strings in variables will provide you with the fundamentals to use strings in your Python 3 programs.

Continue learning more about strings by taking a look at the following tutorials:

- [How To Format Text in Python 3](how-to-format-text-in-python-3)
- [An Introduction to String Functions](an-introduction-to-string-functions-in-python-3)
- [How To Index and Slice Strings](how-to-index-and-slice-strings-in-python-3)
- [How To Use String Formatters](how-to-use-variables-in-python-3)
