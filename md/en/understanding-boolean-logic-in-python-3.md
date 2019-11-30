---
author: Lisa Tagliaferri
date: 2016-11-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-boolean-logic-in-python-3
---

# Understanding Boolean Logic in Python 3

## Introduction

The Boolean data type can be one of two values, either **True** or **False**. We use Booleans in programming to make comparisons and to control the flow of the program.

Booleans represent the truth values that are associated with the logic branch of mathematics, which informs algorithms in computer science. Named for the mathematician George Boole, the word Boolean always begins with a capitalized B. The values `True` and `False` will also always be with a capital T and F respectively, as they are special values in Python.

In this tutorial, we’ll go over the basics you’ll need to understand how Booleans work, including Boolean comparison and logical operators, and truth tables.

## Comparison Operators

In programming, comparison operators are used to compare values and evaluate down to a single Boolean value of either True or False.

The table below shows Boolean comparison operators.

| Operator | What it means |
| --- | --- |
| == | Equal to |
| != | Not equal to |
| \< | Less than |
| \> | Greater than |
| \<= | Less than or equal to |
| \>= | Greater than or equal to |

To understand how these operators work, let’s assign two integers to two variables in a Python program:

    x = 5
    y = 8

We know that in this example, since `x` has the value of `5`, it is less than `y` which has the value of `8`.

Using those two variables and their associated values, let’s go through the operators from the table above. In our program, we’ll ask Python to print out whether each comparison operator evaluates to either True or False. To help us and other humans better understand this output, we’ll have Python also print a [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) to show us what it’s evaluating.

    x = 5
    y = 8
    
    print("x == y:", x == y)
    print("x != y:", x != y)
    print("x < y:", x < y)
    print("x > y:", x > y)
    print("x <= y:", x <= y)
    print("x >= y:", x >= y)

    Outputx == y: False
    x != y: True
    x < y: True
    x > y: False
    x <= y: True
    x >= y: False

Following mathematical logic, in each of the expressions above, Python has evaluated:

- Is 5 (`x`) equal to 8 (`y`)? **False**
- Is 5 not equal to 8? **True**
- Is 5 less than 8? **True**
- Is 5 greater than 8? **False**
- Is 5 less than or equal to 8? **True**
- Is 5 not less than or equal to 8? **False**

Although we used integers here, we could substitute them with float values.

Strings can also be used with Boolean operators. They are case-sensitive unless you employ an additional [string method](an-introduction-to-string-methods-in-python-3#making-strings-upper-and-lower-case).

We can look at how strings are compared in practice:

    Sammy = "Sammy"
    sammy = "sammy"
    
    print("Sammy == sammy: ", Sammy == sammy)

    OutputSammy == sammy: False

The string `"Sammy"` above is not equal to the string `"sammy"`, because they are not exactly the same; one starts with an upper-case `S` and the other with a lower-case `s`. But, if we add another variable that is assigned the value of `"Sammy"`, then they will evaluate to equal:

    Sammy = "Sammy"
    sammy = "sammy"
    also_Sammy = "Sammy"
    
    print("Sammy == sammy: ", Sammy == sammy)
    print("Sammy == also_Sammy", Sammy == also_Sammy)

    OutputSammy == sammy: False
    Sammy == also_Sammy: True

You can also use the other comparison operators including `>` and `<` to compare two strings. Python will compare these strings lexicographically using the ASCII values of the characters.

We can also evaluate Boolean values with comparison operators:

    t = True
    f = False
    
    print("t != f: ", t != f)

    Outputt != f: True

The above code block evaluated that `True` is not equal to `False`.

Note the difference between the two operators `=` and `==`.

    x = y # Sets x equal to y
    x == y # Evaluates whether x is equal to y

The first, `=` is the assignment operator, which will set one value equal to another. The second, `==` is a comparison operator which will evaluate whether two values are equal.

## Logical Operators

There are three logical operators that are used to compare values. They evaluate expressions down to Boolean values, returning either `True` or `False`. These operators are `and`, `or`, and `not` and are defined in the table below.

| Operator | What it means | What it looks like |
| --- | --- | --- |
| and | True if both are true | `x and y` |
| or | True if at least one is true | `x or y` |
| not | True only if false | `not x` |

Logical operators are typically used to evaluate whether two or more expressions are true or not true. For example, they can be used to determine if the grade is passing **and** that the student is registered in the course, and if both cases are true then the student will be assigned a grade in the system. Another example would be to determine whether a user is a valid active customer of an online shop based on whether they have store credit **or** have made a purchase in the past 6 months.

To understand how logical operators work, let’s evaluate three expressions:

    print((9 > 7) and (2 < 4)) # Both original expressions are True
    print((8 == 8) or (6 != 6)) # One original expression is True
    print(not(3 <= 1)) # The original expression is False

    OutputTrue
    True
    True

In the first case, `print((9 > 7) and (2 < 4))`, both `9 > 7` and `2 < 4` needed to evaluate to True since the `and` operator was being used.

In the second case, `print((8 == 8) or (6 != 6))`, since `8 == 8` evaluated to True, it did not make a difference that `6 != 6` evaluates to False because the `or` operator was used. If we had used the `and` operator, this would evaluate to False.

In the third case, `print(not(3 <= 1))`, the `not` operator negates the False value that `3 <=1` returns.

Let’s substitute floats for integers and aim for False evaluations:

    print((-0.2 > 1.4) and (0.8 < 3.1)) # One original expression is False
    print((7.5 == 8.9) or (9.2 != 9.2)) # Both original expressions are False       
    print(not(-5.7 <= 0.3)) # The original expression is True

In the example above,

- `and` must have at least one False expression evaluate to False,
- `or` must have both expressions evaluate to False,
- `not` must have its inner expression be True for the new expression to evaluate to False.

If the results above seem unclear to you, we’ll go through some [truth tables](understanding-boolean-logic-in-python-3#truth-tables) below to get you up to speed.

You can also write compound statements using `and`, `or`, and `not`:

    not((-0.2 > 1.4) and ((0.8 < 3.1) or (0.1 == 0.1)))

Let’s look at the inner-most expression first: `(0.8 < 3.1) or (0.1 == 0.1)`. This expression evaluates to True because both mathematical statements are True.

Now, we can take the returned value `True` and combine it with the next inner expression: `(-0.2 > 1.4) and (True)`. This example returns `False` because the mathematical statement `-0.2 > 1.4` is False, and `(False) and (True)` returns False.

Finally, we have the outer expression: `not(False)`, which evaluates to True, so the final returned value if we print this statement out is:

    OutputTrue

The logical operators `and`, `or`, and `not` evaluate expressions and return Boolean values.

## Truth Tables

There is a lot to learn about the logic branch of mathematics, but we can selectively learn some of it to improve our algorithmic thinking when programming.

Below are truth tables for the comparison operator `==`, and each of the logic operators `and`, `or`, and `not`. While you may be able to reason them out, it can also be helpful to work to memorize them as that can make your programming decision-making process quicker.

### == Truth Table

| x | == | y | Returns |
| --- | --- | --- | --- |
| True | == | True | True |
| True | == | False | False |
| False | == | True | False |
| False | == | False | True |

### AND Truth Table

| x | and | y | Returns |
| --- | --- | --- | --- |
| True | and | True | True |
| True | and | False | False |
| False | and | True | False |
| False | and | False | False |

### OR Truth Table

| x | or | y | Returns |
| --- | --- | --- | --- |
| True | or | True | True |
| True | or | False | True |
| False | or | True | True |
| False | or | False | False |

### NOT Truth Table

| not | x | Returns |
| --- | --- | --- |
| not | True | False |
| not | False | True |

Truth tables are common mathematical tables used in logic, and are useful to memorize or keep in mind when constructing algorithms (instructions) in computer programming.

## Using Boolean Operators for Flow Control

To control the stream and outcomes of a program in the form of flow control statements, we can use a **condition** followed by a **clause**.

A **condition** evaluates down to a Boolean value of True or False, presenting a point where a decision is made in the program. That is, a condition would tell us if something evaluates to True or False.

The **clause** is the block of code that follows the **condition** and dictates the outcome of the program. That is, it is the **do this** part of the construction “If `x` is True, then do this.”

The code block below shows an example of comparison operators working in tandem with [conditional statements](how-to-write-conditional-statements-in-python-3-2) to control the flow of a Python program:

    if grade >= 65: # Condition
        print("Passing grade") # Clause
    
    else:
        print("Failing grade")

This program will evaluate whether each student’s grade is passing or failing. In the case of a student with a grade of 83, the first statement will evaluate to `True`, and the print statement of `Passing grade` will be triggered. In the case of a student with a grade of 59, the first statement will evaluate to `False`, so the program will move on to execute the print statement tied to the `else` expression: `Failing grade`.

Because every single object in Python can be evaluated to True or False, the [PEP 8 Style Guide](http://legacy.python.org/dev/peps/pep-0008/) recommends against comparing a value to `True` or `False` because it is less readable and will frequently return an unexpected Boolean. That is, you should **avoid** using `if sammy == True:` in your programs. Instead, compare `sammy` to another non-Boolean value that will return a Boolean.

Boolean operators present conditions that can be used to decide the eventual outcome of a program through flow control statements.

## Conclusion

This tutorial went through comparison and logical operators belonging to the Boolean type, as well as truth tables and using Booleans for program flow control.

You can learn more about other data types in our “[Understanding Data Types](understanding-data-types-in-python-3)” tutorial, and can read about conditional statements in our “[How To Write Conditional Statements](how-to-write-conditional-statements-in-python-3-2) tutorial.
