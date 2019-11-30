---
author: Lisa Tagliaferri
date: 2016-10-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-do-math-in-python-3-with-operators
---

# How To Do Math in Python 3 with Operators

## Introduction

Numbers are extremely common in programming. They are used to represent things like screen size dimensions, geographic locations, money and points, the amount of time that passes in a video, positions of game avatars, and colors through assigning numeric codes.

Being able to effectively perform mathematical operations in programming is an important skill to develop because of how frequently you’ll be working with numbers. Though a high-level understanding of mathematics can certainly help you become a better programmer, it is not a prerequisite. If you don’t have a background in mathematics, try to think of math as a tool to accomplish what you would like to achieve, and as a way to improve your logical thinking.

We’ll be working with two of Python’s most used numeric data types, **integers** and **floats** :

- [Integers](understanding-data-types-in-python-3#integers) are whole numbers that can be positive, negative, or 0 (…, `-1`, `0`, `1`, …).
- [Floats](understanding-data-types-in-python-3#floating-point-numbers) are real numbers, they contain a decimal point (as in `9.0` or `-2.25`).

This tutorial will go over operators that can be used with number data types in Python.

## Operators

An **operator** is a symbol or function that indicates an operation. For example, in math the plus sign or + is the operator that indicates addition.

In Python, we will see some familiar operators that are brought over from math, but other operators we will use are specific to computer programming.

Here is a quick reference table of math-related operators in Python. We’ll be covering all of the following operations in this tutorial.

| Operation | What it returns |
| --- | --- |
| [x + y](how-to-do-math-in-python-3-with-operators#addition-and-subtraction) | Sum of `x` and `y` |
| [x - y](how-to-do-math-in-python-3-with-operators#addition-and-subtraction) | Difference of `x` and `y` |
| [-x](how-to-do-math-in-python-3-with-operators#unary-arithmetic-operations) | Changed sign of `x` |
| [+x](how-to-do-math-in-python-3-with-operators#unary-arithmetic-operations) | Identity of `x` |
| [x \* y](how-to-do-math-in-python-3-with-operators#multiplication-and-division) | Product of `x` and `y` |
| [x / y](how-to-do-math-in-python-3-with-operators#multiplication-and-division) | Quotient of x and y |
| [x // y](how-to-do-math-in-python-3-with-operators#multiplication-and-division) | Quotient from floor division of `x` and `y` |
| [x % y](how-to-do-math-in-python-3-with-operators#modulo) | Remainder of `x / y` |
| [x \*\* y](how-to-do-math-in-python-3-with-operators#power) | `x` to the `y` power |

We’ll also be covering [compound assignment operators](how-to-do-math-in-python-3-with-operators#assignment-operators), including `+=` and `*=`, that combine an arithmetic operator with the `=` operator.

## Addition and Subtraction

In Python, addition and subtraction operators perform just as they do in mathematics. In fact, you can use the Python programming language as a calculator.

Let’s look at some examples, starting with integers:

    print(1 + 5)

    Output 6

Instead of passing integers directly into the `print` statement, we can initialize variables to stand for integer values:

    a = 88
    b = 103
    
    print(a + b)

    Output191

Because integers can be both positive and negative numbers (and 0 too), we can add a negative number with a positive number:

    c = -36
    d = 25
    
    print(c + d)

    Output-11

Addition will behave similarly with floats:

    e = 5.5
    f = 2.5
    
    print(e + f)

    Output8.0

Because we added two floats together, Python returned a float value with a decimal place.

The syntax for subtraction is the same as for addition, except you’ll change your operator from the plus sign (`+`) to the minus sign (`-`):

    g = 75.67
    h = 32
    
    print(g - h)

    Output43.67

Here, we subtracted an integer from a float. Python will return a float if at least one of the numbers involved in an equation is a float.

## Unary Arithmetic Operations

A unary mathematical expression consists of only one component or element, and in Python the plus and minus signs can be used as a single element paired with a value to return the value’s identity (`+`), or change the sign of the value (`-`).

Though not commonly used, the plus sign indicates the identity of the value. We can use the plus sign with positive values:

    i = 3.3
    print(+i)

    Output3.3

When we use the plus sign with a negative value, it will also return the identity of that value, and in this case it would be a negative value:

    j = -19
    print(+j)

    Output-19

With a negative value the plus sign returns the same negative value.

The minus sign, alternatively, changes the sign of a value. So, when we pass a positive value we’ll find that the minus sign before the value will return a negative value:

    i = 3.3
    print(-i)

    Output-3.3

Alternatively, when we use the minus sign unary operator with a negative value, a positive value will be returned:

    j = -19
    print(-j)

    Output19

The unary arithmetic operations indicated by the plus sign and minus sign will return either the value’s identity in the case of `+i`, or the opposite sign of the value as in `-i`.

## Multiplication and Division

Like addition and subtraction, multiplication and division will look very similar to how they do in mathematics. The sign we’ll use in Python for multiplication is `*` and the sign we’ll use for division is `/`.

Here’s an example of doing multiplication in Python with two float values:

    k = 100.1
    l = 10.1
    
    print(k * l)

    Output1011.0099999999999

When you divide in Python 3, your quotient will always be returned as a float, even if you use two integers:

    m = 80
    n = 5
    
    print(m / n)

    Output16.0

This is one of the [major changes between Python 2 and Python 3](python-2-vs-python-3-practical-considerations-2#division-with-integers). Python 3’s approach provides a fractional answer so that when you use `/` to divide `11` by `2` the quotient of `5.5` will be returned. In Python 2 the quotient returned for the expression `11 / 2` is `5`.

Python 2’s `/` operator performs **floor division** , where for the quotient `x` the number returned is the largest integer less than or equal to `x`. If you run the above example of `print(80 / 5)` with Python 2 instead of Python 3, you’ll receive `16` as the output without the decimal place.

In Python 3, you can use `//` to perform floor division. The expression `100 // 40` will return the value of `2`. Floor division is useful when you need a quotient to be in whole numbers.

## Modulo

The `%` operator is the modulo, which returns the remainder rather than the quotient after division. This is useful for finding numbers that are multiples of the same number, for example.

Let’s look at the modulo in action:

    o = 85
    p = 15
    
    print(o % p)

    Output10

To break this down, 85 divided by 15 returns the quotient of 5 with a remainder of 10. The value `10` is what is returned here because the modulo operator returns the remainder of a division expression.

If we use two floats with the modulo, a float value will be returned for the remainder:

    q = 36.0
    r = 6.0
    
    print(o % p)

    Output0.0

In the case of 36.0 divided by 6.0, there is no remainder, so the value of `0.0` is returned.

## Power

The ` **` operator in Python is used to raise the number on the left to the power of the exponent of the right. That is, in the expression `5** 3`, 5 is being raised to the 3rd power. In mathematics, we often see this expression rendered as 5³, and what is really going on is 5 is being multiplied by itself 3 times. In Python, we would get the same result of `125` by running either `5 ** 3` or `5 * 5 * 5`.

Let’s look at an example with variables:

    s = 52.25
    t = 7
    
    print(s ** t)

    1063173305051.292

Raising the float `52.25` to the power of `7` through the `**` operator results in a large float value returned.

## Operator Precedence

In Python, as in mathematics, we need to keep in mind that operators will be evaluated in order of precedence, not from left to right or right to left.

If we look at the following expression:

    u = 10 + 10 * 5

We may read it left to right, but remember that multiplication will be done first, so if we call `print(u)`, we will receive the following value:

    Output60

This is because `10 * 5` evaluates to `50`, and then we add `10` to return `60` as the final result.

If instead we would like to add the value `10` to `10`, then multiply that sum by `5`, we can use parentheses just like we would in math:

    u = (10 + 10) * 5
    print(u)

    Output100

One way to remember the order of operation is through the acronym **PEMDAS** :

| Order | Letter | Stands for |
| --- | --- | --- |
| 1 | **P** | **P** arentheses |
| 2 | **E** | **E** xponent |
| 3 | **M** | **M** ultiplication |
| 4 | **D** | **D** ivision |
| 5 | **A** | **A** ddition |
| 6 | **S** | **S** ubtraction |

You may be familiar with another acronym for the order of operations, such as **BEDMAS** or **BODMAS**. Whatever acronym works best for you, try to keep it in mind when performing math operations in Python so that the results that you expect are returned.

## Assignment Operators

The most common assignment operator is one you have already used: the equals sign `=`. The `=` assignment operator assigns the value on the right to a variable on the left. For example, `v = 23` assigns the value of the integer `23` to the variable `v`.

When programming, it is common to use compound assignment operators that perform an operation on a variable’s value and then assign the resulting new value to that variable. These compound operators combine an arithmetic operator with the `=` operator, so for addition we’ll combine `+` with `=` to get the compound operator `+=`. Let’s see what that looks like:

    w = 5
    w += 1
    print(w)

    Output6

First, we set the variable `w` equal to the value of `5`, then we used the `+=` compound assignment operator to add the right number to the value of the left variable _and then_ assign the result to `w`.

Compound assignment operators are used frequently in the case of **[for loops](how-to-construct-for-loops-in-python-3)**, which you’ll use when you want to repeat a process several times:

    for x in range (0, 7):
        x *= 2
        print(x)

    Output0
    2
    4
    6
    8
    10
    12

With the for loop, we were able to automate the process of the `*=` operator that multiplied the variable `w` by the number `2` and then assigned the result in the variable `w` for the next iteration of the for loop.

Python has a compound assignment operator for each of the arithmetic operators discussed in this tutorial:

    y += 1 # add then assign value
    
    y -= 1 # subtract then assign value
    
    y *= 2 # multiply then assign value
    
    y /= 3 # divide then assign value
    
    y // = 5 # floor divide then assign value
    
    y **= 2 # increase to the power of then assign value
    
    y %= 3 # return remainder then assign value

Compound assignment operators can be useful when things need to be incrementally increased or decreased, or when you need to automate certain processes in your program.

## Conclusion

This tutorial covered many of the operators you’ll use with the integer and float numeric data types. If you would like to keep reading about numbers in Python, you can continue onto [Built-in Python 3 Functions for Working with Numbers](built-in-python-3-functions-for-working-with-numbers).

To learn more about other data types, take a look at [Understanding Data Types in Python 3](understanding-data-types-in-python-3), and learn about how to convert data types by reading [How To Convert Data Types in Python 3](how-to-convert-data-types-in-python-3).
