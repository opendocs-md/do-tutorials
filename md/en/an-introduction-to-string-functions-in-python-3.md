---
author: Lisa Tagliaferri
date: 2016-09-20
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-string-functions-in-python-3
---

# An Introduction to String Functions in Python 3

## Introduction

Python has several built-in functions associated with the [string data type](an-introduction-to-working-with-strings-in-python-3). These functions let us easily modify and manipulate strings. We can think of functions as being actions that we perform on elements of our code. Built-in functions are those that are defined in the Python programming language and are readily available for us to use.

In this tutorial, we’ll go over several different functions that we can use to work with strings in Python 3.

## Making Strings Upper and Lower Case

The functions `str.upper()` and `str.lower()` will return a string with all the letters of an original string converted to upper- or lower-case letters. Because strings are immutable data types, the returned string will be a new string. Any characters in the string that are not letters will not be changed.

Let’s convert the string `Sammy Shark` to be all upper case:

    ss = "Sammy Shark"
    print(ss.upper())

    OuputSAMMY SHARK

Now, let’s convert the string to be all lower case:

    print(ss.lower())

    Ouputsammy shark

The `str.upper()` and `str.lower()` functions make it easier to evaluate and compare strings by making case consistent throughout. That way if a user writes their name all lower case, we can still determine whether their name is in our database by checking it against an all upper-case version, for example.

## Boolean Methods

Python has some string methods that will evaluate to a [Boolean value](understanding-boolean-logic-in-python-3). These methods are useful when we are creating forms for users to fill in, for example. If we are asking for a post code we will only want to accept a numeric string, but when we are asking for a name, we will only want to accept an alphabetic string.

There are a number of string methods that will return Boolean values:

| Method | `True` if |
| --- | --- |
| `str.isalnum()` | String consists of only alphanumeric characters (no symbols) |
| `str.isalpha()` | String consists of only alphabetic characters (no symbols) |
| `str.islower()` | String’s alphabetic characters are all lower case |
| `str.isnumeric()` | String consists of only numeric characters |
| `str.isspace()` | String consists of only whitespace characters |
| `str.istitle()` | String is in title case |
| `str.isupper()` | String’s alphabetic characters are all upper case |

Let’s look at a couple of these in action:

    number = "5"
    letters = "abcdef"
    
    print(number.isnumeric())
    print(letters.isnumeric())

    OutputTrue
    False

Using the `str.isnumeric()` method on the string `5` returns a value of `True`, while using the same method on the string `abcdef` returns a value of `False`.

Similarly, we can query whether a string’s alphabetic characters are in title case, upper case, or lower case. Let’s create a few strings:

    movie = "2001: A SAMMY ODYSSEY"
    book = "A Thousand Splendid Sharks"
    poem = "sammy lived in a pretty how town"

Now let’s try the Boolean methods that check for case:

    print(movie.islower())
    print(movie.isupper())

    print(book.istitle())
    print(book.isupper())

    print(poem.istitle())
    print(poem.islower())

Now we can run these small programs and see the output:

    Output of movie stringFalse
    True

    Output of book stringTrue
    False

    Output of poem stringFalse
    True

Checking whether characters are lower case, upper case, or title case, can help us to sort our data appropriately, as well as provide us with the opportunity to standardize data we collect by checking and then modifying strings as needed.

Boolean string methods are useful when we want to check whether something a user enters fits within given parameters.

## Determining String Length

The string function `len()` returns the number of characters in a string. This method is useful for when you need to enforce minimum or maximum password lengths, for example, or to truncate larger strings to be within certain limits for use as abbreviations.

To demonstrate this method, we’ll find the length of a sentence-long string:

    open_source = "Sammy contributes to open source."
    print(len(open_source))

    Output33

We set the variable `open_source` equal to the string `"Sammy contributes to open source."` and then we passed that variable to the `len()` function with `len(open_source)`. We then passed the method into the `print()` method so that we could see the output on the screen from our program.

Keep in mind that any character bound by single or double quotation marks — including letters, numbers, whitespace characters, and symbols — will be counted by the `len()` function.

## join(), split(), and replace() Methods

The `str.join()`, `str.split()`, and `str.replace()` methods are a few additional ways to manipulate strings in Python.

The `str.join()` method will concatenate two strings, but in a way that passes one string through another.

Let’s create a string:

    balloon = "Sammy has a balloon."

Now, let’s use the `str.join()` method to add whitespace to that string, which we can do like so:

    " ".join(balloon)

If we print this out:

    print(" ".join(balloon))

We will see that in the new string that is returned there is added space throughout the first string:

    OuputS a m m y h a s a b a l l o o n .

We can also use the `str.join()` method to return a string that is a reversal from the original string:

    print("".join(reversed(balloon)))

    Ouput.noollab a sah ymmaS

We did not want to add any part of another string to the first string, so we kept the quotation marks touching with no space in between.

The `str.join()` method is also useful to combine a list of strings into a new single string.

Let’s create a comma-separated string from a list of strings:

    print(",".join(["sharks", "crustaceans", "plankton"]))

    Ouputsharks,crustaceans,plankton

If we want to add a comma and a space between string values in our new string, we can simply rewrite our expression with a whitespace after the comma: `", ".join(["sharks", "crustaceans", "plankton"])`.

Just as we can join strings together, we can also split strings up. To do this, we will use the `str.split()` method:

    print(balloon.split())

    Ouput['Sammy', 'has', 'a', 'balloon.']

The `str.split()` method returns a list of strings that are separated by whitespace if no other parameter is given.

We can also use `str.split()` to remove certain parts of an original string. For example, let’s remove the letter `a` from the string:

    print(balloon.split("a"))

    Ouput['S', 'mmy h', 's ', ' b', 'lloon.']

Now the letter `a` has been removed and the strings have been separated where each instance of the letter `a` had been, with whitespace retained.

The `str.replace()` method can take an original string and return an updated string with some replacement.

Let’s say that the balloon that Sammy had is lost. Since Sammy no longer has this balloon, we will change the substring `"has"` from the original string `balloon` to `"had"` in a new string:

    print(balloon.replace("has","had"))

Within the parentheses, the first substring is what we want to be replaced, and the second substring is what we are replacing that first substring with. Our output will look like this:

    OuputSammy had a balloon.

Using the string methods `str.join()`, `str.split()`, and `str.replace()` will provide you with greater control to manipulate strings in Python.

## Conclusion

This tutorial went through some of the common built-in methods for the string data type that you can use to work with and manipulate strings in your Python programs.

You can learn more about other data types in “[Understanding Data Types](understanding-data-types-in-python-3),” read more about strings in “[An Introduction to Working with Strings](an-introduction-to-working-with-strings-in-python-3),” and learn about changing the way strings look in “[How To Format Text in Python 3](how-to-format-text-in-python-3).”
