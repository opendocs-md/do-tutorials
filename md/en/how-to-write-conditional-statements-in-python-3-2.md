---
author: Lisa Tagliaferri
date: 2016-10-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-conditional-statements-in-python-3-2
---

# How To Write Conditional Statements in Python 3

## Introduction

Conditional statements are part of every programming language. With conditional statements, we can have code that sometimes runs and at other times does not run, depending on the conditions of the program at that time.

When we fully execute each statement of a program, moving from the top to the bottom with each line executed in order, we are not asking the program to evaluate specific conditions. By using conditional statements, programs can determine whether certain conditions are being met and then be told what to do next.

Let’s look at some examples where we would use conditional statements:

- If the student receives over 65% on her test, report that her grade passes; if not, report that her grade fails
- If he has money in his account, calculate interest; if he doesn’t, charge a penalty fee
- If they buy 10 oranges or more, calculate a discount of 5%; if they buy fewer, then don’t

Through evaluating conditions and assigning code to run based on whether or not those conditions are met, we are writing conditional code.

This tutorial will take you through writing conditional statements in the Python programming language.

## If statement

We will start with the `if` statement, which will evaluate whether a statement is true or false, and run code only in the case that the statement is true.

In a plain text editor, open a file and write the following code:

    grade = 70
    
    if grade >= 65:
        print("Passing grade")

With this code, we have the variable `grade` and are giving it the integer value of `70`. We are then using the `if` statement to evaluate whether or not the variable grade is greater than or equal ( `>=` ) to `65`. If it does meet this condition, we are telling the program to print out the [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) `Passing grade`.

Save the program as `grade.py` and run it in a [local programming environment from a terminal window](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) with the command `python grade.py`.

In this case, the grade of 70 _does_ meet the condition of being greater than or equal to 65, so you will receive the following output once you run the program:

    OutputPassing grade

Let’s now change the result of this program by changing the value of the `grade` variable to `60`:

grade.py

    grade = 60
    
    if grade >= 65:
        print("Passing grade")

When we save and run _this_ code, we will receive no output because the condition was _not_ met and we did not tell the program to execute another statement.

To give one more example, let us calculate whether a bank account balance is below 0. Let’s create a file called `account.py` and write the following program:

account.py

    balance = -5
    
    if balance < 0:
        print("Balance is below 0, add funds now or you will be charged a penalty.")

When we run the program with `python account.py`, we’ll receive the following output:

    OutputBalance is below 0, add funds now or you will be charged a penalty.

In the program we initialized the variable `balance` with the value of `-5`, which is less than 0. Since the balance met the condition of the `if` statement (`balance < 0`), once we save and run the code, we will receive the string output. Again, if we change the balance to 0 or a positive number, we will receive no output.

## Else Statement

It is likely that we will want the program to do something even when an `if` statement evaluates to false. In our grade example, we will want output whether the grade is passing or failing.

To do this, we will add an `else` statement to the grade condition above that is constructed like this:

grade.py

    grade = 60
    
    if grade >= 65:
        print("Passing grade")
    
    else:
        print("Failing grade")

Since the grade variable above has the value of `60`, the `if` statement evaluates as false, so the program will not print out `Passing grade`. The `else` statement that follows tells the program to do something anyway.

When we save and run the program, we’ll receive the following output:

    OutputFailing grade

If we then rewrite the program to give the grade a value of `65` or higher, we will instead receive the output `Passing grade`.

To add an `else` statement to the bank account example, we rewrite the code like this:

account.py

    balance = 522
    
    if balance < 0:
        print("Balance is below 0, add funds now or you will be charged a penalty.")
    
    else:
        print("Your balance is 0 or above.")

    OutputYour balance is 0 or above.

Here, we changed the `balance` variable value to a positive number so that the `else` statement will print. To get the first `if` statement to print, we can rewrite the value to a negative number.

By combining an `if` statement with an `else` statement, you are constructing a two-part conditional statement that will tell the computer to execute certain code whether or not the `if` condition is met.

## Else if statement

So far, we have presented a Boolean option for conditional statements, with each `if` statement evaluating to either true or false. In many cases, we will want a program that evaluates more than two possible outcomes. For this, we will use an **else if** statement, which is written in Python as `elif`. The `elif` or else if statement looks like the `if` statement and will evaluate another condition.

In the bank account program, we may want to have three discrete outputs for three different situations:

- The balance is below 0
- The balance is equal to 0
- The balance is above 0

The `elif` statement will be placed between the `if` statement and the `else` statement as follows:

account.py

    . . .
    if balance < 0:
        print("Balance is below 0, add funds now or you will be charged a penalty.")
    
    elif balance == 0:
        print("Balance is equal to 0, add funds soon.")
    
    else:
        print("Your balance is 0 or above.")

Now, there are three possible outputs that can occur once we run the program:

- If the variable `balance` is equal to `0` we will receive the output from the `elif` statement (`Balance is equal to 0, add funds soon.`)
- If the variable `balance` is set to a positive number, we will receive the output from the `else` statement (`Your balance is 0 or above.`). 
- If the variable `balance` is set to a negative number, the output will be the string from the `if` statement (`Balance is below 0, add funds now or you will be charged a penalty`).

What if we want to have more than three possibilities, though? We can do this by writing more than one `elif` statement into our code.

In the `grade.py` program, let’s rewrite the code so that there are a few letter grades corresponding to ranges of numerical grades:

- 90 or above is equivalent to an A grade
- 80-89 is equivalent to a B grade
- 70-79 is equivalent to a C grade
- 65-69 is equivalent to a D grade
- 64 or below is equivalent to an F grade

To run this code, we will need one `if` statement, three `elif` statements, and an `else` statement that will handle all failing cases.

Let’s rewrite the code from the example above to have strings that print out each of the letter grades. We can keep our `else` statement the same.

grade.py

    . . .
    if grade >= 90:
        print("A grade")
    
    elif grade >=80:
        print("B grade")
    
    elif grade >=70:
        print("C grade")
    
    elif grade >= 65:
        print("D grade")
    
    else:
        print("Failing grade")

Since `elif` statements will evaluate in order, we can keep our statements pretty basic. This program is completing the following steps:

1. If the grade is greater than 90, the program will print `A grade`, if the grade is less than 90, the program will continue to the next statement…

2. If the grade is greater than or equal to 80, the program will print `B grade`, if the grade is 79 or less, the program will continue to the next statement…

3. If the grade is greater than or equal to 70, the program will print `C grade`, if the grade is 69 or less, the program will continue to the next statement…

4. If the grade is greater than or equal to 65, the program will print `D grade`, if the grade is 64 or less, the program will continue to the next statement…

5. The program will print `Failing grade` because all of the above conditions were not met.

## Nested If Statements

Once you are feeling comfortable with the `if`, `elif`, and `else` statements, you can move on to nested conditional statements. We can use nested `if` statements for situations where we want to check for a secondary condition if the first condition executes as true. For this, we can have an if-else statement inside of another if-else statement. Let’s look at the syntax of a nested `if` statement:

    if statement1: #outer if statement
        print("true")
    
        if nested_statement: #nested if statement
            print("yes")
    
        else: #nested else statement
            print("no")
    
    else: #outer else statement
        print("false")

A few possible outputs can result from this code:

- If `statement1` evaluates to true, the program will then evaluate whether the `nested_statement` also evaluates to true. If both cases are true, the output will be:

> Outputtrue
> yes

- If, however, `statement1` evaluates to true, but `nested_statement` evaluates to false, then the output will be:

> Outputtrue
> no

- And if `statement1` evaluates to false, the nested if-else statement will not run, so the `else` statement will run alone, and the output will be:

> Outputfalse

We can also have multiple `if` statements nested throughout our code:

    if statement1: #outer if 
        print("hello world")
    
        if nested_statement1: #first nested if 
            print("yes")
    
        elif nested_statement2: #first nested elif
            print("maybe")
    
        else: #first nested else
            print("no")
    
    elif statement2: #outer elif
        print("hello galaxy")
    
        if nested_statement3: #second nested if
            print("yes")
    
        elif nested_statement4: #second nested elif
            print("maybe")
    
        else: #second nested else
            print("no")
    
    else: #outer else
        statement("hello universe")

In the above code, there is a nested `if` statement inside each `if` statement in addition to the `elif` statement. This will allow for more options within each condition.

Let’s look at an example of nested `if` statements with our `grade.py` program. We can check for whether a grade is passing first (greater than or equal to 65%), then evaluate which letter grade the numerical grade should be equivalent to. If the grade is not passing, though, we do not need to run through the letter grades, and instead can have the program report that the grade is failing. Our modified code with the nested `if` statement will look like this:

grade.py

    . . .
    if grade >= 65:
        print("Passing grade of:")
    
        if grade >= 90:
            print("A")
    
        elif grade >=80:
            print("B")
    
        elif grade >=70:
            print("C")
    
        elif grade >= 65:
            print("D")
    
    else:
        print("Failing grade")

If we run the code with the variable `grade` set to the integer value `92`, the first condition is met, and the program will print out `Passing grade of:`. Next, it will check to see if the grade is greater than or equal to 90, and since this condition is also met, it will print out `A`.

If we run the code with the `grade` variable set to `60`, then the first condition is not met, so the program will skip the nested `if` statements and move down to the `else` statement, with the program printing out `Failing grade`.

We can of course add even more options to this, and use a second layer of nested if statements. Perhaps we will want to evaluate for grades of A+, A and A- separately. We can do so by first checking if the grade is passing, then checkingto see if the grade is 90 or above, then checkingto see if the grade is over 96 for an A+ for instance:

grade.py

    . . .
    if grade >= 65:
        print("Passing grade of:")
    
        if grade >= 90:
            if grade > 96:
                print("A+")
    
            elif grade > 93 and grade <= 96:
                print("A")
    
            elif grade >= 90:
                print("A-")
    . . .

In the code above, for a `grade` variable set to `96`, the program will run the following:

1. Check if the grade is greater than or equal to 65 (true)
2. Print out `Passing grade of:`
3. Check if the grade is greater than or equal to 90 (true)
4. Check if the grade is greater than 96 (false)
5. Check if the grade is greater than 93 and also less than or equal to 96 (true)
6. Print `A`
7. Leave these nested conditional statements and continue with remaining code

The output of the program for a grade of 96 therefore looks like this:

    OutputPassing grade of:
    A

Nested `if` statements can provide the opportunity to add several specific levels of conditions to your code.

## Conclusion

By using conditional statements like the `if` statement, you will have greater control over what your program executes. Conditional statements tell the program to evaluate whether a certain condition is being met. If the condition is met it will execute specific code, but if it is not met the program will continue to move down to other code.

To continue practicing conditional statements, try using different [operators](how-to-do-math-in-python-3-with-operators), combining operators with `and` or `or`, and using conditional statements alongside [loops](how-to-construct-for-loops-in-python-3). You can also go through our tutorial on [How To Make a Simple Calculator Program](how-to-make-a-simple-calculator-program-in-python-3) to gain more familiarity with conditional statements.
