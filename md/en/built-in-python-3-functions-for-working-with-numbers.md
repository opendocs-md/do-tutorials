---
author: Lisa Tagliaferri
date: 2016-11-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/built-in-python-3-functions-for-working-with-numbers
---

# Built-in Python 3 Functions for Working with Numbers

## Introduction

Python 3 comes with many built-in functions that you can readily use in any program that you’re working on. Some functions enable you to [convert data types](how-to-convert-data-types-in-python-3), and others are specific to a certain type, like [strings](an-introduction-to-string-methods-in-python-3).

This tutorial will go through a few of the built-in functions that can be used with numeric data types in Python 3. We’ll go over the following functions:

- `abs()` for absolute value
- `divmod()` to find a quotient and remainder simultaneously 
- `pow()` to raise a number to a certain power
- `round()` to round a number to a certain decimal point
- `sum()` to calculate the sum of the items in an iterable data type

Becoming familiar with these methods can give you more flexibility when programming so that you can make informed decisions when deciding what operators and functions to use. We’ll go through some of these functions with examples throughout this tutorial.

### Absolute Value

The built-in function `abs()` will return the absolute value of a number that you pass to it. In mathematics, **absolute value** refers to the distance that a number is on the number line from 0. Absolute value does not take into consideration which direction from zero the number lies, meaning that negative numbers will be represented with positive numbers.

To give some examples, the absolute value of `15` is `15`, the absolute value of `-74` is `74`, and the absolute value of `0` is `0`.

Absolute value is an important concept for calculus and real analysis, but it also makes sense when we think about everyday situations like distance travelled. For example, if we are trying to get somewhere that is 58 miles away but we travel 93 miles instead, we overshot our original destination. If we want to calculate now how many miles left to travel to get to the intended destination, we’ll end up with a negative number, but we can’t travel negative miles.

Let’s use `abs()` to solve this problem:

destination\_miles.py

    miles_from_origin = 58 # Miles destination is from origin
    miles_travelled = 93 # Miles travelled from origin to destination (too many)
    
    # Calculate how many miles destination is from current location:
    miles_to_go = miles_from_origin - miles_travelled   
    
    print(miles_to_go) # Print how many miles left (a negative number)
    print(abs(miles_to_go)) # Use absolute value to account for negative number

    Output-35
    35

In the output, we see that if we don’t use the `abs()` function, in this instance we have a negative number, `-35`. Though we may be in a position where `miles_travelled` is less than `miles_from_origin`, including the `abs()` function takes the possibility of a negative number into account.

With a negative number, `abs()` will return a positive number as absolute values are always positive numbers or zero.

Let’s go through using `abs()` with a positive number and zero:

    print(abs(89.9))
    print(abs(0))

    Output89.9
    0

We’re most likely to use `abs()` with a variable that may be positive or negative in an instance when we are looking only for a positive number. To account for a negative input or result, we’ll use `abs()` to modify what is returned to be a positive number.

### Finding the Quotient and Remainder in One Function

Because both floor division (which returns a quotient), and modulo division (which returns a remainder), are closely related, it can be useful to use a function that combines both operations at once.

The Python built-in function `divmod()` combines the two, returning first the quotient that comes from floor division, then the remainder.

Because `divmod()` will be working with two numbers, we need to pass two numbers to it.

    divmod(a,b)

With this function we are basically performing the following:

    a // b
    a & b

Let’s say we have written a book that is 80,000 words long. With our publisher, we have the option of either 300 or 250 words per page, and we’d like to get a sense of how many pages we would have in each case. With `divmod()` we can see immediately how many pages we would have, and how many words would be spilled over onto an additional page.

words\_per\_page.py

    words = 80000 # How many words in our book
    per_page_A = 300 # Option A, 300 words per page
    per_page_B = 250 # Option B, 25- words per page
    
    print(divmod(words,per_page_A)) # Calculate Option A
    print(divmod(words,per_page_B)) # Calculate Option B

    Output(266, 200)
    (320, 0)

In Option A, we will have 266 pages filled with words and 200 words left over (⅔ of a page) for a total of 267 pages, and in Option B we’ll have an even 320-page book. If we want to be environmentally-conscious, we can choose Option A, but if we want to look more impressive with a bigger-sized book we may choose Option B.

Because the function `divmod()` can take both integers and floats, let’s also go through an example that uses floats:

    a = 985.5
    b = 115.25
    
    print(divmod(a,b))

    Output(8.0, 63.5)

In this example, `8.0` is the floor quotient of 985.5 divided by 115.25, and `63.5` is the remainder.

Keep in mind that you can use the floor division operator `//` and the modulo operator `%` to verify what `divmod()` did:

    print(a//b)
    print(a%b)

    Output8.0
    63.5

When using the `divmod()` function in Python. we get both the whole number of times the division occurs and the remainder returned.

## Power

In Python, you can use [the operator](how-to-do-math-in-python-3-with-operators#power) `**` to raise a number by an exponent, or you can use the built-in function `pow()` which takes in two numbers.

To see how the `pow()` function works, let’s say we are doing research on bacteria and want to see how many bacteria we’ll have at the end of the day if we start with 1. The particular bacteria we’re working with doubles each hour, so we’ll be calculating 2 (doubling) to the power of the total number of hours (24 in our case).

bacteria.py

    hours = 24
    total_bacteria = pow(2,hours)
    
    print(total_bacteria)

    Output16777216

We passed two integers to the `pow()` function and determined that by the end of this 24-hour period, we’ll have over 16 million bacteria.

In mathematics, if we want to calculate 3 to the power of 3, it is generally written like this:

3³

The computation that we are completing is 3 x 3 x 3, which is equal to 27.

To calculate 3³ in Python, we would type out `pow(3,3)`.

The function `pow()` will take both integers and floats, and provides an alternative to using the `**` operator when you intend to raise numbers to a certain power.

## Rounding Numbers

Being able to quickly and readily round numbers becomes important when working with floats that have a lot of decimal places. The built-in Python function `round()` takes in two numbers, one to be rounded, and one that specifies the number of decimal places to include.

We’ll use the function to take a float with more than 10 decimal places and use the `round()` function to reduce decimal places to 4:

    i = 17.34989436516001
    print(round(i,4))

    Output17.3499

In the example above, the float `17.34989436516001` is rounded to `17.3499` because we have specified that the number of decimal places should be limited to 4.

Note also that the `round()` function rounds numbers up, so instead of providing `17.3498` as the output, it has provided `17.3499` because the number following the decimal number 8 is the number 9. Any number that is followed by the number 5 or greater will be rounded up to the next whole number.

Let’s break down the syntax for `round()`:

    round(number to round,number of decimal places)

In everyday life, rounding numbers happens often, especially when working with money; we can’t split up a penny evenly among several friends.

Let’s go through an example of a simple program that can calculate a tip. Here we’ll provide figures, but we could rewrite the program to bring in user-provided numbers instead. In this example, 3 friends went to a restaurant who want to split a bill of $87.93 evenly, along with adding a 20% tip.

bill\_split.py

    bill = 87.93 # Total bill
    tip = 0.2 # 20% tip
    split = 3 # Number of people splitting the bill
    
    total = bill + (bill * tip) # Calculate the total bill
    
    each_pay = total / split # Calculate what each person pays
    
    print(each_pay) # What each person pays before rounded
    
    print(round(each_pay,2)) # Round the number — we can’t split pennies

    Output35.172000000000004
    35.17

In this program, we ask first for output of the number after we calculate the total bill plus tip divided by 3, which evaluates to a number with a lot of decimal places: `35.172000000000004`. Since this number doesn’t make sense as a monetary figure, we use the `round()` function and limit the decimal places to 2, so that we can provide an output that the 3 friends can actually work with: `35.17`.

If you would prefer to round to a number with only 0 as a decimal value, you can do so by using 0 as the second parameter in the `round()` function:

    round(345.9874590348545304636,0)

This would evaluate to `346.0`.

You can also pass integers into `round()` without receiving an error, in case you receive user input in the form of an integer rather than a float. When an integer is passed as the first parameter, an integer will be returned.

## Calculating a Sum

The `sum()` function is used for calculating sums of numeric compound data types, including [lists](understanding-lists-in-python-3), [tuples](understanding-tuples-in-python-3), and [dictionaries](understanding-dictionaries-in-python-3).

We can pass a list to the `sum()` function to add all the items in the list together in order from left to right:

    some_floats = [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9]
    print(sum(some_floats))

    Output49.5

This will work similarly with tuples and dictionaries:

    print(sum((8,16,64,512))) # Calculate sum of numbers in tuple
    print(sum({-10: 'x', -20: 'y', -30: 'z'})) # Calculate sum of numbers in dictionary 

    Output600 # Sum of numbers in tuple
    -60 # Sum of numbers in dictionary

The `sum()` function can take up to 2 arguments, so you can add an additional number in integer or float form to add to the numbers that make up the argument in the first position:

    some_floats = [1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9]
    
    print(sum(some_floats, 0.5))
    print(sum({-10: 'x', -20: 'y', -30: 'z'},60))

    Output50.0
    0

When you don’t include a second argument, the `sum()` function defaults to adding 0 to the iterable compound data type.

## Conclusion

This tutorial covered some built-in methods that you can use with numeric data types in the Python programming language.

To learn more about working with numbers, you can read “[How To Do Math in Python 3 with Operators](how-to-do-math-in-python-3-with-operators)”, and to learn more about lists, take a look at “[Understanding Lists in Python 3](understanding-lists-in-python-3).”
