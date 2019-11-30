---
author: Lisa Tagliaferri
date: 2017-01-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-construct-while-loops-in-python-3
---

# How To Construct While Loops in Python 3

## Introduction

Computer programs are great to use for automating and repeating tasks so that we don’t have to. One way to repeat similar tasks is through using **loops**. We’ll be covering Python’s **while loop** in this tutorial.

A `while` loop implements the repeated execution of code based on a given [Boolean](understanding-boolean-logic-in-python-3) condition. The code that is in a `while` block will execute as long as the `while` statement evaluates to True.

You can think of the `while` loop as a repeating [conditional statement](how-to-write-conditional-statements-in-python-3-2). After an `if` statement, the program continues to execute code, but in a `while` loop, the program jumps back to the start of the while statement until the condition is False.

As opposed to **[for loops](how-to-construct-for-loops-in-python-3)** that execute a certain number of times, `while` loops are conditionally based, so you don’t need to know how many times to repeat the code going in.

## While Loop

In Python, `while` loops are constructed like so:

    while [a condition is True]:
        [do something]

The something that is being done will continue to be executed until the condition that is being assessed is no longer true.

Let’s create a small program that executes a `while` loop. In this program, we’ll ask for the user to input a password. While going through this loop, there are two possible outcomes:

- If the password _is_ correct, the `while` loop will exit. 
- If the password is _not_ correct, the `while` loop will continue to execute.

We’ll create a file called `password.py` in our text editor of choice, and begin by initializing the variable `password` as an empty [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3):

password.py

    password = ''

The empty string will be used to take in input from the user within the `while` loop.

Now, we’ll construct the `while` statement along with its condition:

password.py

    password = ''
    
    while password != 'password':

Here, the `while` is followed by the variable `password`. We are looking to see if the variable `password` is set to the string `password` (based on the user input later), but you can choose whichever string you’d like.

This means that if the user inputs the string `password`, then the loop will stop and the program will continue to execute any code outside of the loop. However, if the string that the user inputs is not equal to the string `password`, the loop will continue.

Next, we’ll add the block of code that does something within the `while` loop:

password.py

    password = ''
    
    while password != 'password':
        print('What is the password?')
        password = input()

Inside of the `while` loop, the program runs a print statement that prompts for the password. Then the variable `password` is set to the user’s input with the `input()` function.

The program will check to see if the variable `password` is assigned to the string `password`, and if it is, the `while` loop will end. Let’s give the program another line of code for when that happens:

password.py

    password = ''
    
    while password != 'password':
        print('What is the password?')
        password = input()
    
    print('Yes, the password is ' + password + '. You may enter.')

The last `print()` statement is outside of the `while` loop, so when the user enters `password` as the password, they will see the final print statement outside of the loop.

However, if the user never enters the word `password`, they will never get to the last `print()` statement and will be stuck in an infinite loop.

An **infinite loop** occurs when a program keeps executing within one loop, never leaving it. To exit out of infinite loops on the command line, press `CTRL + C`.

Save the program and run it:

    python password.py

You’ll be prompted for a password, and then may test it with various possible inputs. Here is sample output from the program:

    OutputWhat is the password?
    hello
    What is the password?
    sammy
    What is the password?
    PASSWORD
    What is the password?
    password
    Yes, the password is password. You may enter.

Keep in mind that strings are case sensitive unless you also use a [string function](an-introduction-to-string-methods-in-python-3) to convert the string to all lower-case (for example) before checking.

## Example Program with While Loop

Now that we understand the general premise of a `while` loop, let’s create a command-line guessing game that uses a `while` loop effectively. To best understand how this program works, you should also read about [using conditional statements](how-to-write-conditional-statements-in-python-3-2) and [converting data types](how-to-convert-data-types-in-python-3).

First, we’ll create a file called `guess.py` in our text editor of choice. We want the computer to come up with random numbers for the user to guess, so we’ll [import](how-to-import-modules-in-python-3) the `random` module with an `import` statement. If you’re unfamiliar with this package, you can learn more about [generating random numbers from the Python docs](https://docs.python.org/3.6/library/random.html).

guess.py

    import random

Next, we’ll assign a random integer to the variable `number`, and keep it in the range of 1 through 25 (inclusive), in the hope that it does not make the game too difficult.

guess.py

    import random
    
    number = random.randint(1, 25)

At this point, we can get into our `while` loop, first initializing a variable and then creating the loop.

guess.py

    import random
    
    number = random.randint(1, 25)
    
    number_of_guesses = 0
    
    while number_of_guesses < 5:
        print('Guess a number between 1 and 25:')
    
        guess = input()
        guess = int(guess)
    
        number_of_guesses = number_of_guesses + 1
    
        if guess == number:
            break

We’ve initialized the variable `number_of_guesses` at 0, so that we increase it with each iteration of our loop so that we don’t have an infinite loop. Then we added the `while` statement so that the `number_of_guesses` is limited to 5 total. After the fifth guess, the user will return to the command line, and for now, if the user enters something other than an integer, they’ll receive an error.

Within the loop, we added a `print()` statement to prompt the user to enter a number, which we took in with the `input()` function and set to the `guess` variable. Then, we converted `guess` from a string to an integer.

Before the loop is over, we also want to increase the `number_of_guesses` variable by 1 so that we can iterate through the loop 5 times.

Finally, we write a conditional `if` statement to see if the `guess` that the user made is equivalent to the `number` that the computer generated, and if so we use a [`break` statement](how-to-use-break-continue-and-pass-statements-when-working-with-loops-in-python-3) to come out of the loop.

The program is fully functioning, and we can run it with the following command:

    python guess.py

Though it works, right now the user never knows if their guess is correct and they can guess the full 5 times without ever knowing if they got it right. Sample output of the current program looks like this:

    OutputGuess a number between 1 and 25:
    11
    Guess a number between 1 and 25:
    19
    Guess a number between 1 and 25:
    22
    Guess a number between 1 and 25:
    3
    Guess a number between 1 and 25:
    8

Let’s add some conditional statements outside of the loop so that the user is given feedback as to whether they correctly guess the number or not. These will go at the end of our current file.

guess.py

    import random
    
    number = random.randint(1, 25)
    
    number_of_guesses = 0
    
    while number_of_guesses < 5:
        print('Guess a number between 1 and 25:')
        guess = input()
        guess = int(guess)
    
        number_of_guesses = number_of_guesses + 1
    
        if guess == number:
            break
    
    if guess == number:
        print('You guessed the number in ' + str(number_of_guesses) + ' tries!')
    
    else:
        print('You did not guess the number. The number was ' + str(number))

At this point, the program will tell the user if they got the number right or wrong, which may not happen until the end of the loop when the user is out of guesses.

To give the user a little help along the way, let’s add a few more conditional statements into the `while` loop. These can tell the user whether their number was too low or too high, so that they can be more likely to guess the correct number. We’ll add these before our `if guess == number` line

guess.py

    import random
    
    number = random.randint(1, 25)
    
    number_of_guesses = 0
    
    while number_of_guesses < 5:
        print('Guess a number between 1 and 25:')
        guess = input()
        guess = int(guess)
    
        number_of_guesses = number_of_guesses + 1
    
        if guess < number:
            print('Your guess is too low')
    
        if guess > number:
            print('Your guess is too high')
    
        if guess == number:
            break
    
    if guess == number:
        print('You guessed the number in ' + str(number_of_guesses) + ' tries!')
    
    else:
        print('You did not guess the number. The number was ' + str(number))

When we run the program again with `python guess.py`, we see that the user gets more guided assistance in their guessing. So, if the randomly-generated number is `12` and the user guesses `18`, they will be told that their guess is too high, and they can adjust their next guess accordingly.

There is more that can be done to improve the code, including error handling for when the user does not input an integer, but in this example we see a `while` loop at work in a short command-line program.

## Conclusion

This tutorial went over how `while` loops work in Python and how to construct them. **While loops** continue to loop through a block of code provided that the condition set in the `while` statement is True.

From here, you can continue to learn about looping by reading tutorials on **[for loops](how-to-construct-for-loops-in-python-3)** and **[break, continue, and pass statements](how-to-use-break-continue-and-pass-statements-when-working-with-loops-in-python-3)**.
