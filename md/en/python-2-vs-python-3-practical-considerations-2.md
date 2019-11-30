---
author: Lisa Tagliaferri
date: 2016-08-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/python-2-vs-python-3-practical-considerations-2
---

# Python 2 vs Python 3: Practical Considerations

## Introduction

Python is an extremely readable and versatile programming language. With a name inspired by the British comedy group Monty Python, it was an important foundational goal of the Python development team to make the language fun to use. Easy to set up, and written in a relatively straightforward style with immediate feedback on errors, Python is a great choice for beginners.

As Python is a multiparadigm language — that is, it supports multiple programming styles including scripting and object-oriented — it is good for general purpose use. Increasingly used in industry by organizations such as United Space Alliance (NASA’s main shuttle support contractor), and Industrial Light & Magic (the VFX and animation studio of Lucasfilm), Python offers a lot of potential for those looking to pick up an additional programming language.

Developed in the late 1980s and first published in 1991, Python was authored by Guido van Rossum, who is still very active in the community. Conceived as a successor to the ABC programming language, Python’s first iteration already included exception handling, [functions](how-to-define-functions-in-python-3), and [classes with inheritance](understanding-inheritance-in-python-3). When an important Usenet newsgroup discussion forum called comp.lang.python was formed in 1994, Python’s user base grew, paving the way for Python to become one of the most popular programming languages for open source development.

## General Overview

Before looking into potential opportunities related to — and the key programmatic differences between — Python 2 and Python 3, let’s take a look into the background of the more recent major releases of Python.

### Python 2

Published in late 2000, Python 2 signalled a more transparent and inclusive language development process than earlier versions of Python with the implementation of PEP (Python Enhancement Proposal), a technical specification that either provides information to Python community members or describes a new feature of the language.

Additionally, Python 2 included many more programmatic features including a cycle-detecting garbage collector to automate memory management, increased Unicode support to standardize characters, and list comprehensions to create a list based on existing lists. As Python 2 continued to develop, more features were added, including unifying Python’s types and classes into one hierarchy in Python version 2.2.

### Python 3

Python 3 is regarded as the future of Python and is the version of the language that is currently in development. A major overhaul, Python 3 was released in late 2008 to address and amend intrinsic design flaws of previous versions of the language. The focus of Python 3 development was to clean up the codebase and remove redundancy, making it clear that there was only one way to perform a given task.

Major modifications to Python 3.0 included changing the `print` statement into a built-in function, improve the way integers are divided, and providing more Unicode support.

At first, Python 3 was slowly adopted due to the language not being backwards compatible with Python 2, requiring people to make a decision as to which version of the language to use. Additionally, many package libraries were only available for Python 2, but as the development team behind Python 3 has reiterated that there is an end of life for Python 2 support, more libraries have been ported to Python 3. The increased adoption of Python 3 can be shown by the number of Python packages that now provide Python 3 support, which at the time of writing includes 339 of the 360 most popular Python packages.

### Python 2.7

Following the 2008 release of Python 3.0, Python 2.7 was published on July 3, 2010 and planned as the last of the 2.x releases. The intention behind Python 2.7 was to make it easier for Python 2.x users to port features over to Python 3 by providing some measure of compatibility between the two. This compatibility support included enhanced modules for version 2.7 like `unittest` to support test automation, `argparse` for parsing command-line options, and more convenient classes in `collections`.

Because of Python 2.7’s unique position as a version in between the earlier iterations of Python 2 and Python 3.0, it has persisted as a very popular choice for programmers due to its compatibility with many robust libraries. When we talk about Python 2 today, we are typically referring to the Python 2.7 release as that is the most frequently used version.

Python 2.7, however, is considered to be a legacy language and its continued development, which today mostly consists of bug fixes, will cease completely in 2020.

## Key Differences

While Python 2.7 and Python 3 share many similar capabilities, they should not be thought of as entirely interchangeable. Though you can write good code and useful programs in either version, it is worth understanding that there will be some considerable differences in code syntax and handling.

Below are a few examples, but you should keep in mind that you will likely encounter more syntactical differences as you continue to learn Python.

### Print

In Python 2, `print` is treated as a statement instead of a function, which was a typical area of confusion as many other actions in Python require arguments inside of parentheses to execute. If you want your console to print out `Sammy the Shark is my favorite sea creature` in Python 2 you can do so with the following `print` statement:

    print "Sammy the Shark is my favorite sea creature"

With Python 3, `print()` is now explicitly treated as a function, so to print out the same string above, you can do so simply and easily using the syntax of a function:

    print("Sammy the Shark is my favorite sea creature")

This change made Python’s syntax more consistent and also made it easier to change between different print functions. Conveniently, the `print()` syntax is also backwards-compatible with Python 2.7, so your Python 3 `print()` functions can run in either version.

### Division with Integers

In Python 2, any number that you type without decimals is treated as the programming type called **integer**. While at first glance this seems like an easy way to handle programming types, when you try to divide integers together sometimes you expect to get an answer with decimal places (called a **float** ), as in:

    5 / 2 = 2.5

However, in Python 2 integers were strongly typed and would not change to a float with decimal places even in cases when that would make intuitive sense.

When the two numbers on either side of the division `/` symbol are integers, Python 2 does **floor division** so that for the quotient `x` the number returned is the largest integer less than or equal to `x`. This means that when you write `5 / 2` to divide the two numbers, Python 2.7 returns the largest integer less than or equal to 2.5, in this case `2`:

    a = 5 / 2
    print a

    Output2

To override this, you could add decimal places as in `5.0 / 2.0` to get the expected answer `2.5`.

In Python 3, [integer division](how-to-do-math-in-python-3-with-operators#multiplication-and-division) became more intuitive, as in:

    a = 5 / 2
    print(a)

    Output2.5

You can still use `5.0 / 2.0` to return `2.5`, but if you want to do floor division you should use the Python 3 syntax of `//`, like this:

    b = 5 // 2
    print(b)

    Output2

This modification in Python 3 made dividing by integers much more intuitive and is a feature that is **not** backwards compatible with Python 2.7.

### Unicode Support

When programming languages handle the **[string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3)** type — that is, a sequence of characters — they can do so in a few different ways so that computers can convert numbers to letters and other symbols.

Python 2 uses the ASCII alphabet by default, so when you type `"Hello, Sammy!"` Python 2 will handle the string as ASCII. Limited to a couple of hundred characters at best in various extended forms, ASCII is not a very flexible method for encoding characters, especially non-English characters.

To use the more versatile and robust Unicode character encoding, which supports over 128,000 characters across contemporary and historic scripts and symbol sets, you would have to type `u"Hello, Sammy!"`, with the `u` prefix standing for Unicode.

Python 3 uses Unicode by default, which saves programmers extra development time, and you can easily type and display many more characters directly into your program. Because Unicode supports greater linguistic character diversity as well as the display of emojis, using it as the default character encoding ensures that mobile devices around the world are readily supported in your development projects.

If you would like your Python 3 code to be backwards-compatible with Python 2, though, you can keep the `u` before your string.

### Continued Development

The biggest difference between Python 3 and Python 2 is not a syntactical one, but the fact that Python 2.7 will lose continued support in 2020 and Python 3 will continue to be developed with more features and more bug fixes.

Recent developments have included [formatted string literals](how-to-use-string-formatters-in-python-3), simpler customization of [class creation](how-to-construct-classes-and-define-objects-in-python-3), and a cleaner syntactical way to handle matrix multiplication.

Continued development of Python 3 means that developers can rely on having issues fixed in a timely manner, and programs can be more effective with increased functionality being built in over time.

## Additional Points to Consider

As someone starting Python as a new programmer, or an experienced programmer new to the Python language, you will want to consider what you are hoping to achieve in learning the language.

If you are hoping just to learn without a set project in mind, you will likely most want to take into account that Python 3 will continue to be supported and developed, while Python 2.7 will not.

If, however, you are planning to join an existing project, you will likely most want to see what version of Python the team is using, how a different version may interact with the legacy codebase, if the packages the project uses are supported in a different version, and what the implementation details of the project are.

If you are beginning a project that you have in mind, it would be worthwhile to investigate what packages are available to use and with which version of Python they are compatible. As noted above, though earlier versions of Python 3 had less compatibility with libraries built for versions of Python 2, many have ported over to Python 3 or are committed to doing so in the next four years.

## Conclusion

Python is a versatile and well-documented programming language to learn, and whether you choose to work with Python 2 or Python 3, you will be able to work on exciting software projects.

Though there are several key differences, it is not too difficult to move from Python 3 to Python 2 with a few tweaks, and you will often find that Python 2.7 can easily run Python 3 code, especially when you are starting out. You can learn more about this process by reading the tutorial [How To Port Python 2 Code to Python 3](how-to-port-python-2-code-to-python-3).

It is important to keep in mind that as more developer and community attention focuses on Python 3, the language will become more refined and in-line with the evolving needs of programmers, and less support will be given to Python 2.7.
