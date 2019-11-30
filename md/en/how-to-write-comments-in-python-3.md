---
author: Lisa Tagliaferri
date: 2017-03-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-comments-in-python-3
---

# How To Write Comments in Python 3

## Introduction

Comments are lines that exist in computer programs that are ignored by compilers and interpreters. Including comments in programs makes code more readable for humans as it provides some information or explanation about what each part of a program is doing.

Depending on the purpose of your program, comments can serve as notes to yourself or reminders, or they can be written with the intention of other programmers being able to understand what your code is doing.

In general, it is a good idea to write comments while you are writing or updating a program as it is easy to forget your thought process later on, and comments written later may be less useful in the long term.

## Comment Syntax

Comments in Python begin with a hash mark (`#`) and whitespace character and continue to the end of the line.

Generally, comments will look something like this:

    # This is a comment

Because comments do not execute, when you run a program you will not see any indication of the comment there. Comments are in the source code for humans to read, not for computers to execute.

In a “Hello, World!” program, a comment may look like this:

hello.py

    # Print “Hello, World!” to console
    print("Hello, World!")

In a [`for` loop](how-to-construct-for-loops-in-python-3) that iterates over a [list](understanding-lists-in-python-3), comments may look like this:

sharks.py

    # Define sharks variable as a list of strings
    sharks = ['hammerhead', 'great white', 'dogfish', 'frilled', 'bullhead', 'requiem']
    
    # For loop that iterates over sharks list and prints each string item
    for shark in sharks:
       print(shark)

Comments should be made at the same indent as the code it is commenting. That is, a [function definition](how-to-define-functions-in-python-3) with no indent would have a comment with no indent, and each indent level following would have comments that are aligned with the code it is commenting.

For example, here is how the `again()` function from the [How To Make a Simple Calculator Program in Python 3 tutorial](how-to-make-a-simple-calculator-program-in-python-3) is commented, with comments following each indent level of the code:

calculator.py

    ...
    # Define again() function to ask user if they want to use the calculator again
    def again():
    
        # Take input from user
        calc_again = input('''
    Do you want to calculate again?
    Please type Y for YES or N for NO.
    ''')
    
        # If user types Y, run the calculate() function
        if calc_again == 'Y':
            calculate()
    
        # If user types N, say good-bye to the user and end the program
        elif calc_again == 'N':
            print('See you later.')
    
        # If user types another key, run the function again
        else:
            again()

Comments are made to help programmers, whether it is the original programmer or someone else using or collaborating on the project. If comments cannot be properly maintained and updated along with the code base, it is better to not include a comment rather than write a comment that contradicts or will contradict the code.

When commenting code, you should be looking to answer the _why_ behind the code as opposed to the _what_ or _how_. Unless the code is particularly tricky, looking at the code can generally tell what the code is doing or how it is doing it.

## Block Comments

Block comments can be used to explain more complicated code or code that you don’t expect the reader to be familiar with. These longer-form comments apply to some or all of the code that follows, and are also indented at the same level as the code.

In block comments, each line begins with the hash mark and a single space. If you need to use more than one paragraph, they should be separated by a line that contains a single hash mark.

Here is an example of a block comment that defines what is happening in the `main()` function defined below:

    # The main function will parse arguments via the parser variable. These
    # arguments will be defined by the user on the console. This will pass
    # the word argument the user wants to parse along with the filename the
    # user wants to use, and also provide help text if the user does not 
    # correctly pass the arguments.
    
    def main():
      parser = argparse.ArgumentParser()
      parser.add_argument(
          "word",
          help="the word to be searched for in the text file."
      )
      parser.add_argument(
          "filename",
          help="the path to the text file to be searched through"
      )
    ...

Block comments are typically used when operations are less straightforward and are therefore demanding of a thorough explanation. You should try to avoid over-commenting the code and should tend to trust other programmers to understand Python unless you are writing for a particular audience.

## Inline Comments

Inline comments occur on the same line of a statement, following the code itself. Like other comments, they begin with a hash mark and a single whitespace character.

Generally, inline comments look like this:

    [code] # Inline comment about the code

Inline comments should be used sparingly, but can be effective for explaining tricky or non-obvious parts of code. They can also be useful if you think you may not remember a line of the code you are writing in the future, or if you are collaborating with someone who you know may not be familiar with all aspects of the code.

For example, if you don’t use a lot of [math](how-to-do-math-in-python-3-with-operators) in your Python programs, you or your collaborators may not know that the following creates a complex number, so you may want to include an inline comment about that:

    z = 2.5 + 3j # Create a complex number

Inline comments can also be used to explain the reason behind doing something, or some extra information, as in:

    x = 8 # Initialize x with an arbitrary number

Comments that are made in line should be used only when necessary and when they can provide helpful guidance for the person reading the program.

## Commenting Out Code for Testing

In addition to using comments as a way to document code, the hash mark can also be used to comment out code that you don’t want to execute while you are testing or debugging a program you are currently creating. That is, when you experience errors after implementing new lines of code, you may want to comment a few of them out to see if you can troubleshoot the precise issue.

Using the hash mark can also allow you to try alternatives while you’re determining how to set up your code. For example, you may be deciding between using a [`while` loop](how-to-construct-while-loops-in-python-3) or a `for` loop in a Python game, and can comment out one or the other while testing and determining which one may be best:

guess.py

    import random
    
    number = random.randint(1, 25)
    
    # number_of_guesses = 0
    
    for i in range(5):
    # while number_of_guesses < 5:
        print('Guess a number between 1 and 25:')
        guess = input()
        guess = int(guess)
    
        # number_of_guesses = number_of_guesses + 1
    
        if guess < number:
            print('Your guess is too low')
    
        if guess > number:
            print('Your guess is too high')
    
        if guess == number:
            break
    
    if guess == number:
        print('You guessed the number!')
    
    else:
        print('You did not guess the number. The number was ' + str(number))
    

Commenting out code with the hash mark can allow you to try out different programming methods as well as help you find the source of an error through systematically commenting out and running parts of a program.

## Conclusion

Using comments within your Python programs helps to make your programs more readable for humans, including your future self. Including appropriate comments that are relevant and useful can make it easier for others to collaborate with you on programming projects and make the value of your code more obvious.

From here, you may want to read about Python’s [Docstrings in PEP 257](https://www.python.org/dev/peps/pep-0257/) to provide you with more resources to properly document your Python projects.
