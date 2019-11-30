---
author: Lisa Tagliaferri
date: 2016-09-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-data-types-in-python-3
---

# Understanding Data Types in Python 3

## Introduction

In Python, like in all programming languages, data types are used to classify one particular type of data. This is important because the specific data type you use will determine what values you can assign to it and what you can do to it (including what operations you can perform on it).

In this tutorial, we will go over the important data types native to Python. This is not an exhaustive investigation of data types, but will help you become familiar with what options you have available to you in Python.

## Background

One way to think about data types is to consider the different types of data that we use in the real world. An example of data in the real world are numbers: we may use whole numbers (0, 1, 2, …), integers (…, -1, 0, 1, …), and irrational numbers (π), for example.

Usually, in math, we can combine numbers from different types, and get some kind of an answer. We may want to add 5 to π, for example:

    5 + π

We can either keep the equation as the answer to account for the irrational number, or round π to a number with a brief number of decimal places, and then add the numbers together:

    5 + π = 5 + 3.14 = 8.14 

But, if we start to try to evaluate numbers with another data type, such as words, things start to make less sense. How would we solve for the following equation?

    sky + 8

For computers, each data type can be thought of as being quite different, like words and numbers, so we will have to be careful about how we use them to assign values and how we manipulate them through operations.

## Numbers

Any [number](built-in-python-3-functions-for-working-with-numbers) you enter in Python will be interpreted as a number; you are not required to declare what kind of data type you are entering. Python will consider any number written without decimals as an **integer** (as in `138`) and any number written with decimals as a **float** (as in `138.0`).

### Integers

Like in [math](how-to-do-math-in-python-3-with-operators), **integers** in computer programming are whole numbers that can be positive, negative, or 0 (…, `-1`, `0`, `1`, …). An integer can also be known as an `int`. As with other programming languages, you should not use commas in numbers of four digits or more, so when you write 1,000 in your program, write it as `1000`.

We can print out an integer in a simple way like this:

    print(-25)

    Output-25

Or, we can declare a **variable** , which in this case is essentially a symbol of the number we are using or manipulating, like so:

    my_int = -25
    print(my_int)

    Output-25

We can do math with integers in Python, too:

    int_ans = 116 - 68
    print(int_ans)

    Output48

Integers can be used in many ways within Python programs, and as you continue to learn more about the language you will have a lot of opportunities to work with integers and understand more about this data type.

### Floating-Point Numbers

A **floating-point number** or a **float** is a real number, meaning that it can be either a rational or an irrational number. Because of this, floating-point numbers can be numbers that can contain a fractional part, such as `9.0` or `-116.42`. Simply speaking, for the purposes of thinking of a `float` in a Python program, it is a number that contains a decimal point.

Like we did with the integer, we can print out a floating-point number in a simple way like this:

    print(17.3)

    Output17.3

We can also declare a variable that stands in for a float, like so:

    my_flt = 17.3
    print(my_flt)

    Output17.3

And, just like with integers, we can do math with floats in Python, too:

    flt_ans = 564.0 + 365.24
    print(flt_ans)

    Output929.24

With integers and floating-point numbers, it is important to keep in mind that 3 ≠ 3.0, as `3` refers to an integer while `3.0` refers to a float.

## Booleans

The **[Boolean](understanding-boolean-logic-in-python-3)** data type can be one of two values, either **True** or **False**. Booleans are used to represent the truth values that are associated with the logic branch of mathematics, which informs algorithms in computer science.

Whenever you see the data type Boolean, it will start with a capitalized B because it is named for the mathematician George Boole. The values `True` and `False` will also always be with a capital T and F respectively, as they are special values in Python.

Many operations in math give us answers that evaluate to either True or False:

- **greater than**
  - 500 \> 100 `True`
  - 1 \> 5 `False`
- **less than**
  - 200 \< 400 `True`
  - 4 \< 2 `False`
- **equal**
  - 5 = 5 `True`
  - 500 = 400 `False`

Like with numbers, we can store a Boolean value in a variable:

    my_bool = 5 > 8

We can then print the Boolean value with a call to the `print()` function:

    print(my_bool)

Since 5 is not greater than 8, we will receive the following output:

    OutputFalse

As you write more programs in Python, you will become more familiar with how Booleans work and how different functions and operations evaluating to either True or False can change the course of the program.

## Strings

A **string** is a sequence of one or more characters (letters, numbers, symbols) that can be either a constant or a variable. Strings exist within either single quotes `'` or double quotes `"` in Python, so to create a string, enclose a sequence of characters in quotes:

    'This is a string in single quotes.'

    "This is a string in double quotes."

You can choose to use either single quotes or double quotes, but whichever you decide on you should be consistent within a program.

The simple program “[Hello, World!](how-to-write-your-first-python-3-program)” demonstrates how a string can be used in computer programming, as the characters that make up the phrase `Hello, World!` are a string.

    print("Hello, World!")

As with other data types, we can store strings in variables:

    hw = "Hello, World!"

And print out the string by calling the variable:

    print(hw)

    OuputHello, World!

Like numbers, there are many operations that we can perform on strings within our programs in order to manipulate them to achieve the results we are seeking. Strings are important for communicating information to the user, and for the user to communicate information back to the program.

## Lists

A **[list](understanding-lists-in-python-3)** is a mutable, or changeable, ordered sequence of elements. Each element or value that is inside of a list is called an **item**. Just as strings are defined as characters between quotes, lists are defined by having values between square brackets `[]`.

A list of integers looks like this:

    [-3, -2, -1, 0, 1, 2, 3]

A list of floats looks like this:

    [3.14, 9.23, 111.11, 312.12, 1.05]

A list of strings:

    ['shark', 'cuttlefish', 'squid', 'mantis shrimp']

If we define our string list as `sea_creatures`:

    sea_creatures = ['shark', 'cuttlefish', 'squid', 'mantis shrimp']

We can print them out by calling the variable:

    print(sea_creatures)

And we see that the output looks exactly like the list that we created:

    Output['shark', 'cuttlefish', 'squid', 'mantis shrimp']

Lists are a very flexible data type because they are mutable in that they can have values added, removed, and changed. There is a data type that is similar to lists but that can’t be changed, and that is called a tuple.

## Tuples

A **[tuple](understanding-tuples-in-python-3)** is used for grouping data. It is an immutable, or unchangeable, ordered sequence of elements.

Tuples are very similar to lists, but they use parentheses `( )` instead of square brackets and because they are immutable their values cannot be modified.

A tuple looks like this:

    ('blue coral', 'staghorn coral', 'pillar coral')

We can store a tuple in a variable and print it out:

    coral = ('blue coral', 'staghorn coral', 'pillar coral')
    print(coral)

    Ouput('blue coral', 'staghorn coral', 'pillar coral')

Like in the other data types, Python prints out the tuple just as we had typed it, with parentheses containing a sequence of values.

## Dictionaries

The **[dictionary](understanding-dictionaries-in-python-3)** is Python’s built-in **mapping** type. This means that dictionaries map **keys** to **values** and these key-value pairs are a useful way to store data in Python. A dictionary is constructed with curly braces on either side `{ }`.

Typically used to hold data that are related, such as the information contained in an ID, a dictionary looks like this:

    {'name': 'Sammy', 'animal': 'shark', 'color': 'blue', 'location': 'ocean'}

You will notice that in addition to the curly braces, there are also colons throughout the dictionary. The words to the left of the colons are the keys. Keys can be made up of any immutable data type. The keys in the dictionary above are: `'name', 'animal', 'color', 'location'`.

The words to the right of the colons are the values. Values can be comprised of any data type. The values in the dictionary above are: `'Sammy', 'shark', 'blue', 'ocean'`.

Like the other data types, let’s store the dictionary inside a variable, and print it out:

    sammy = {'name': 'Sammy', 'animal': 'shark', 'color': 'blue', 'location': 'ocean'}
    print(sammy)

    Ouput{'color': 'blue', 'animal': 'shark', 'name': 'Sammy', 'location': 'ocean'}

If we want to isolate Sammy’s color, we can do so by calling `sammy['color']`. Let’s print that out:

    print(sammy['color'])

    Outputblue

As dictionaries offer key-value pairs for storing data, they can be important elements in your Python program.

## Conclusion

At this point, you should have a better understanding of some of the major data types that are available for you to use in Python. Each of these data types will become important as you develop programming projects in the Python language.

You can learn about each of the data types above in more detail by reading the following specific tutorials:

- [Numbers](how-to-do-math-in-python-3-with-operators)
- [Booleans](understanding-boolean-logic-in-python-3)
- [Strings](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3)
- [Lists](understanding-lists-in-python-3)
- [Tuples](understanding-tuples-in-python-3)
- [Dictionaries](understanding-dictionaries-in-python-3)

Once you have a solid grasp of data types available to you in Python, you can learn how to [convert data types](how-to-convert-data-types-in-python-3).
