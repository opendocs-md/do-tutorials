---
author: Lisa Tagliaferri
date: 2017-04-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-debug-python-with-an-interactive-console
---

# How To Debug Python with an Interactive Console

## Introduction

**Debugging** is a part of the software development process where programmers look for and then resolve issues that prevent the software from running correctly.

A useful and quick tool for debugging is the Python [`code` module](https://docs.python.org/3/library/code.html) because it can be used to emulate the interactive interpreter. The module also provides the opportunity for you to experiment with code that you write in Python.

## Understanding the `code` Module

Rather than step through code with a debugger, you can [add the `code` module](how-to-import-modules-in-python-3) to your Python program to instruct the program to stop execution and enter into the interactive mode in order to examine how your code is working. The `code` module is part of the Python standard library.

This is useful because you are able to leverage an interpreter without sacrificing the complexity and permanence that programming files can provide. Through using the `code` module you can avoid using `print()` statements throughout your code as a form of debugging, which can become unwieldy over time.

To make use of the module as a method for debugging, you can use the `interact()` function of the module, which stops execution of the program at the point at which it is called, and provides you with an interactive console so that you can examine the current state of your program.

The function with its possible parameters are as follows:

    code.interact(banner=None, readfunc=None, local=None, exitmsg=None)

This function runs a read-eval-print loop, and creates an object instance of the [`InteractiveConsole` class](https://docs.python.org/3/library/code.html#code.InteractiveConsole), which emulates the behavior of the interactive Python interpreter.

The optional parameters are as follows:

- `banner` can be set to a [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3), so that you can flag where the interpreter launches
- `readfunc` can be used as the [`InteractiveConsole.raw_input()` method](https://docs.python.org/3/library/code.html#code.InteractiveConsole.raw_input)
- `local` will set the default namespace for the interpreter loop
- `exitmsg` can be set to a string to note where the interpreter ends

With the `local` parameter, you can use, for example:

- `local=locals()` for a local namespace
- `local=globals()` for a global namespace
- `local=dict(globals(), **locals())` to use both the global namespace and the present local namespace

Note that the `exitmsg` parameter is new for Python 3.6, so if you are using an older version of Python, update it or leave off the `exitmsg` parameter.

You can place the `interact()` function wherever you would like in your program to launch the interactive interpreter in the code.

## Working with the `code` Module

Let’s look at this in the context of a bank account balances program called `balances.py`. We’ll set the `local` parameter to `locals()` to set the namespace to local.

balances.py

    # Import code module
    import code
    
    bal_a = 2324
    bal_b = 0
    bal_c = 409
    bal_d = -2
    
    account_balances = [bal_a, bal_b, bal_c, bal_d]
    
    
    def display_bal():
        for balance in account_balances:
            if balance < 0:
                print("Account balance of {} is below 0; add funds now."
                      .format(balance))
    
            elif balance == 0:
                print("Account balance of {} is equal to 0; add funds soon."
                      .format(balance))
    
            else:
                print("Account balance of {} is above 0.".format(balance))
    
    # Use interact() function to start the interpreter with local namespace
    code.interact(local=locals())
    
    display_bal()
    

We used the function `code.interact()` with the `local=locals()` parameter to use the local namespace as the default within the interpreter loop.

Let’s run the program above, using the `python3` command if we’re not in a virtual environment, or the `python` command if we are:

    python balances.py

Once we run the program, we’ll receive the following output initially:

    Python 3.5.2 (default, Nov 17 2016, 17:05:23) 
    [GCC 5.4.0 20160609] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    (InteractiveConsole)
    >>> 

Your cursor will be placed at the end of the `>>>` line, just like it would be in the Python interactive shell.

From here, you can issue calls to print variables, functions, etc.:

    >>> print(bal_c)
    409
    >>> print(account_balances)
    [2324, 0, 409, -2]
    >>> print(display_bal())
    Account balance of 2324 is 0 or above.
    Account balance of 0 is equal to 0, add funds soon.
    Account balance of 409 is 0 or above.
    Account balance of -2 is below 0, add funds now.
    None
    >>> print(display_bal)
    <function display_bal at 0x104b80f28>
    >>> 

We see that, by using the local namespace, we are able to print the variables and invoke the function. The final `print()` call shows the location of the function `display_bal` within computer memory.

Once you are satisfied with what you have been able to examine from working with the interpreter, you can press `CTRL + D` for \*nix-based systems, or `CTRL + Z` for Windows-based systems to leave the console and continue with the execution of the program.

If you would like to leave the console without running the remainder of the program, you can do so by typing `quit()` and the program will be aborted.

To leverage the `banner` and `exitmsg` parameters, we can do so as follows:

balances.py

    ...
    # Use interact() function to start the interpreter
    code.interact(banner="Start", local=locals(), exitmsg="End")
    
    display_bal()

When we run the program, we’ll receive the following output when we run the program:

    Start
    >>> 

Using the `banner` parameter can allow you to set multiple points within your code and give you the ability to identify them. For example, you can have a `banner` that prints `"In [for-loop](how-to-construct-for-loops-in-python-3)"` with an `exitmsg` that prints `"Out of for-loop"`, so you can tell exactly where you are in the code.

From here, we can use the interpreter as usual. Once we type `CTRL + D` to exit the interpreter, we’ll receive the exit message and the function will run:

    End
    Account balance of 2324 is 0 or above.
    Account balance of 0 is equal to 0, add funds soon.
    Account balance of 409 is 0 or above.
    Account balance of -2 is below 0, add funds now.

The program has now fully run following the interactive session.

Once you are done using the `code` module to debug your code, you should remove the `code` functions and import statement so that your program will run as usual. The `code` module provides a utility, so once you are done it is important to clean up after yourself.

## Conclusion

Using the `code` module to launch an interactive console can allow you to look at what the code is doing on a granular level to understand its behavior and make changes as needed. To read more about it, you can read the [official documentation of the `code` module](https://docs.python.org/3/library/code.html).

To learn more about other methods you can use to debug your Python code, read our tutorial on [how to use the Python debugger `pdb`](how-to-use-the-python-debugger), and our tutorial on [how to use logging](how-to-use-logging-in-python-3).
