---
author: Lisa Tagliaferri
date: 2016-09-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-format-text-in-python-3
---

# How To Format Text in Python 3

## Introduction

As strings are often made up of written text, there are many instances when we may want to have greater control over how strings look to make them more readable for humans through punctuation, line breaks, and indentation.

In this tutorial, we’ll go over some of the ways we can work with Python strings to make sure that all output text is formatted correctly.

## String Literals

Let’s first differentiate between a **string literal** and a **string value**. A string literal is what we see in the source code of a computer program, including the quotation marks. A string value is what we see when we call the `print()` function and run the program.

In the “Hello, World!” program, the string literal is `"Hello, World!"` while the string value is `Hello, World!` without the quotation marks. The string value is what we see as the output in a terminal window when we run a Python program.

But some string values may need to include quotation marks, like when we are quoting a source. Because string literals and string values are not equivalent, it is often necessary to add additional formatting to string literals to ensure that string values are displayed the way in which we intend.

## Quotes and Apostrophes

Because we can use single quotes or double quotes within Python, it is simple to embed quotes within a string by using double quotes within a string enclosed by single quotes:

    'Sammy says, "Hello!"'

Or, to use a possessive apostrophe in a string enclosed by double quotes:

    "Sammy's balloon is red."

In the way we combine single and double quotes, we can control the display of quotation marks and apostrophes within our strings.

## Multiple Lines

Printing strings on multiple lines can make text more readable to humans. With multiple lines, strings can be grouped into clean and orderly text, formatted as a letter, or used to maintain the linebreaks of a poem or song lyrics.

To create strings that span multiple lines, triple single quotes `'''` or triple double quotes `"""` are used to enclose the string.

    '''
    This string is on 
    multiple lines
    within three single 
    quotes on either side.
    '''

    """
    This string is on 
    multiple lines
    within three double 
    quotes on either side.
    """

With triple quotes, you can print strings on multiple lines to make text, especially lengthy text, easier to read.

## Escape Characters

Another way to format strings is to use an **escape character**. Escape characters all start with the backslash key ( `\` ) combined with another character within a string to format the given string a certain way.

Here is a list of several of the common escape characters:

| Escape character | How it formats |
| --- | --- |
| \ | New line in a multi-line string |
| \ | Backslash |
| ' | Apostrophe or single quote |
| " | Double quote |
| \n | Line break |
| \t | Tab (horizontal indentation) |

Let’s use an escape character to add the quotation marks to the example on quotation marks above, but this time we’ll use double quotes:

    print("Sammy says, \"Hello!\"")

    OutputSammy says, "Hello!"

By using the escape character `\"` we are able to use double quotes to enclose a string that includes text quoted between double quotes.

Similarly, we can use the escape character `\'` to add an apostrophe in a string that is enclosed in single quotes:

    print('Sammy\'s balloon is red.')

    OutputSammy's balloon is red.

Because we are now using the escape character we can have an apostrophe within a string that uses single quotes.

When we use triple quotes like we did above, we will see that there is a space at the top and bottom when we print the string. We can remove those spaces by using the `\` escape key at the top of our string and again at the end of the string while keeping the text within the program very readable.

    """\
    This multi-line string
    has no space at the
    top or the bottom
    when it prints.\
    """

Similarly, we can use the `\n` escape character to break lines without hitting the `enter` or `return` key:

    print("This string\nspans multiple\nlines.")

    OutputThis string
    spans multiple
    lines.

We can combine escape characters, too. Let’s print a multi-line string and include tab spacing for an itemized list, for example:

    print("1.\tShark\n2.\tShrimp\n10.\tSquid")

    Output1. Shark
    2. Shrimp
    10. Squid

The horizontal indentation provided with the `\t` escape character ensures alignment within the second column in the example above, making the output extremely readable for humans.

Though the `\n` escape character works well for short string literals, it is important to ensure that source code is also readable to humans. In the case of lengthy strings, the triple quote approach to multi-line strings is often preferable.

Escape characters are used to add additional formatting to strings that may be difficult or impossible to achieve. Without escape characters, how would you construct the string `Sammy says, "The balloon's color is red."`?

## Raw Strings

What if we don’t want special formatting within our strings? For example, we may need to compare or evaluate strings of computer code that use the backslash on purpose, so we won’t want Python to use it as an escape character.

A **raw string** tells Python to ignore all formatting within a string, including escape characters.

We create a raw string by putting an `r` in front of the string, right before the beginning quotation mark:

    print(r"Sammy says,\"The balloon\'s color is red.\"")

    OutputSammy says,\"The balloon\'s color is red.\"

By constructing a raw string by using `r` in front of a given string, we can retain backslashes and other characters that are used as escape characters.

## Conclusion

This tutorial went over several ways to format text in Python 3 through working with strings. By using techniques such as escape characters or raw strings, we are able to ensure that the strings of our program are rendered correctly on-screen so that the end user is able to easily read all of the output text.

Continue learning more about strings by taking a look at the following tutorials:

- [An Introduction to String Functions](an-introduction-to-string-functions-in-python-3)
- [How To Index and Slice Strings](how-to-index-and-slice-strings-in-python-3)
- [How To Use String Formatters](how-to-use-variables-in-python-3)
