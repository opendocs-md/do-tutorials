---
author: Lisa Tagliaferri
date: 2017-06-21
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-the-python-interactive-console
---

# How To Work with the Python Interactive Console

## Introduction

The Python interactive console (also called the Python interpreter or Python shell) provides programmers with a quick way to execute commands and try out or test code without creating a file.

Providing access to all of Python’s built-in functions and any installed modules, command history, and auto-completion, the interactive console offers the opportunity to explore Python and the ability to paste code into programming files when you are ready.

This tutorial will go over how to work with the Python interactive console and leverage it as a programming tool.

## Entering the Interactive Console

The Python interactive console can be accessed from any local computer or server with Python installed.

The command you generally will want to use to enter into the Python interactive console for your default version of Python is:

    python

If you have set up a [programming environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server), you can launch the environment and access the version of Python and modules you have installed in that environment by first entering into that environment:

    cd environments
    . my_env/bin/activate

Then typing the `python` command:

    python

In this case, the default version of Python is Python 3.5.2, which is displayed in the output once we enter the command, along with the relevant copyright notice and some commands you can type for extra information:

    OutputPython 3.5.2 (default, Nov 17 2016, 17:05:23) 
    [GCC 5.4.0 20160609] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> 

The primary prompt for the next command is three greater-than signs (`>>>`):

    

You can target specific versions of Python by appending the version number to your command, with no spaces:

    python2.7

    OutputPython 2.7.12 (default, Nov 19 2016, 06:48:10) 
    [GCC 5.4.0 20160609] on linux2
    Type "help", "copyright", "credits" or "license" for more information.
    >>> 

Here, we received the output that Python 2.7.12 will be used. If this is our default version of Python 2, we could also have entered into this interactive console with the command `python2`.

Alternatively, we can call the default Python 3 version with the following command:

    python3

    OutputPython 3.5.2 (default, Nov 17 2016, 17:05:23) 
    [GCC 5.4.0 20160609] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> 

We could have also called the above interactive console with the command `python3.5`.

With the Python interactive console running, we can move onto working with the shell environment for Python.

## Working with the Python Interactive Console

The Python interactive interpreter accepts Python syntax, which you place following the `>>>` prefix.

We can, for example, assign values to [variables](how-to-use-variables-in-python-3):

    birth_year = 1868

Once we have assigned the integer value of `1868` to the variable `birth_year`, we will press return and receive a new line with the three greater-than signs as a prefix:

    birth_year = 1868
    

We can continue to assign variables and then [perform math with operators](how-to-do-math-in-python-3-with-operators) to get calculations returned:

    >>> birth_year = 1868
    >>> death_year = 1921
    >>> age_at_death = death_year - birth_year
    >>> print(age_at_death)
    53
    >>> 

As we would with a script in a file, we assigned variables, subtracted one variable from the other, and asked the console to print the variable that represents the difference.

Just like in any form of Python, you can also use the interactive console as a calculator:

    >>> 203 / 20
    10.15
    >>> 

Here, we divided the integer `203` by `20` and were returned the quotient of `10.15`.

### Multiple Lines

When we are writing Python code the will cover multiple lines, the interpreter will use the secondary prompt for continuation lines, three dots (`...`).

To break out of these continuation lines, you will need to press `ENTER` twice.

We can see what this looks like in the following code that assigns two variables and then uses a [conditional statement](how-to-write-conditional-statements-in-python-3-2) to determine what to print out to the console:

    >>> sammy = 'Sammy'
    >>> shark = 'Shark'
    >>> if len(sammy) > len(shark):
    ... print('Sammy codes in Java.')
    ... else:
    ... print('Sammy codes in Python.')
    ... 
    Sammy codes in Python.
    >>> 

In this case the lengths of the two [strings](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) are equal, so the `else` statement prints.  
Note that you will need to keep Python indenting convention of four whitespaces, otherwise you will receive an error:

    >>> if len(sammy) > len(shark):
    ... print('Sammy codes in Java.')
      File "<stdin>", line 2
        print('Sammy codes in Java.')
            ^
    IndentationError: expected an indented block
    >>> 

You can not only experiment with code across multiple lines in the Python console, you can also import modules.

### Importing Modules

The Python interpreter provides a quick way for you to check to see if modules are available in a specific programming environment. You can do this by using the `import` statement:

    >>> import matplotlib
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    ImportError: No module named 'matplotlib'

In the case above, the module [matplotlib](how-to-plot-data-in-python-3-using-matplotlib) was not available within the current programming environment.

In order to install it, we’ll need to leave the interactive interpreter and install with pip as usual:

    pip install matplotlib

    OutputCollecting matplotlib
      Downloading matplotlib-2.0.2-cp35-cp35m-manylinux1_x86_64.whl (14.6MB)
    ...
    Installing collected packages: pyparsing, cycler, python-dateutil, numpy, pytz, matplotlib
    Successfully installed cycler-0.10.0 matplotlib-2.0.2 numpy-1.13.0 pyparsing-2.2.0 python-dateutil-2.6.0 pytz-2017.2

Once the matplotlib module along with its dependencies are successfully installed, you can go back into the interactive interpreter:

    python

    import matplotlib
    

At this point you will receive no error message and can use the installed module either within the shell or within a file.

## Leaving the Python Interactive Console

There are two main ways to leave the Python interactive console, either with a keyboard shortcut or a Python function.

The keyboard shortcut `CTRL` + `D` in \*nix-based systems or `CTRL` + `Z` then the `CTRL` key in Windows systems will interrupt your console and return you to your original terminal environment:

    ...
    >>> age_at_death = death_year - birth_year
    >>> print(age_at_death)
    53
    >>> 
    sammy@ubuntu:~/environments$ 

Alternatively, the Python function `quit()` will quit out of the interactive console and also bring you back to the original terminal environment that you were previously in:

    >>> octopus = 'Ollie'
    >>> quit()
    sammy@PythonUbuntu:~/environments$ 

When you use the function `quit()`, it will show up in your history file, but the keyboard shortcut `CTRL` + `D` will not be recorded:

File: /home/sammy/.python\_history

    ...
    age_at_death = death_year - birth_year
    print(age_at_death)
    octopus = 'Ollie'
    quit()

Quitting the Python interpreter can be done either way, depending on what makes sense for your workflow and your history needs.

## Accessing History

One of the useful things about the Python interactive console is that all of your commands are logged to the `.python_history` file in \*nix-based systems, which you can look at in a text editor like nano, for instance:

    nano ~/.python_history

Once opened with a text editor, your Python history file will look something like this, with your own Python command history:

File: /home/sammy/.python\_history

    import pygame
    quit()
    if 10 > 5:
        print("hello, world")
    else:
        print("nope")
    sammy = 'Sammy'
    shark = 'Shark'
    ...

Once you are done with your file, you can press `CTRL` + `X` to leave nano.

By keeping track of all of your Python history, you can go back to previous commands and experiments, and copy and paste or modify that code for use in Python programming files or in a [Jupyter Notebook](how-to-set-up-jupyter-notebook-for-python-3).

## Conclusion

The Python interactive console provides a space to experiment with Python code. You can use it as a tool for testing, working out logic, and more.

For use with debugging Python programming files, you can use the Python `code` module to open up an interactive interpreter within a file, which you can read about in our guide [How To Debug Python with an Interactive Console](how-to-debug-python-with-an-interactive-console).
