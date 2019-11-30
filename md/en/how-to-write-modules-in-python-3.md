---
author: Lisa Tagliaferri
date: 2017-02-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-write-modules-in-python-3
---

# How To Write Modules in Python 3

## Introduction

Python **modules** are `.py` files that consist of Python code. Any Python file can be referenced as a module.

Some modules are available through the [Python Standard Library](https://docs.python.org/3/library/) and are therefore installed with your Python installation. Others can be [installed](how-to-import-modules-in-python-3#checking-for-and-installing-modules) with Python’s package manager `pip`. Additionally, you can create your own Python modules since modules are comprised of Python `.py` files.

This tutorial will guide you through writing Python modules for use within other programming files.

## Writing and Importing Modules

Writing a module is just like writing any other Python file. Modules can contain definitions of functions, classes, and variables that can then be utilized in other Python programs.

From our Python 3 [local programming environment](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04) or [server-based programming environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server), let’s start by creating a file `hello.py` that we’ll later import into another file.

To begin, we’ll [create a function](how-to-define-functions-in-python-3) that prints `Hello, World!`:

hello.py

    # Define a function
    def world():
        print("Hello, World!")

If we run the program on the command line with `python hello.py` nothing will happen since we have not told the program to do anything.

Let’s create a second file **in the same directory** called `main_program.py` so that we can [import the module](how-to-import-modules-in-python-3) we just created, and then call the function. This file needs to be in the same directory so that Python knows where to find the module since it’s not a built-in module.

main\_program.py

    # Import hello module
    import hello
    
    
    # Call function
    hello.world()

Because we are [importing a module](how-to-import-modules-in-python-3#importing-modules), we need to call the function by referencing the module name in dot notation.

We could instead import the module as `from hello import world` and call the function directly as `world()`. You can learn more about this method by reading [how to using `from` … `import` when importing modules](how-to-import-modules-in-python-3#using-from--import).

Now, we can run the program on the command line:

    python main_program.py

When we do, we’ll receive the following output:

    OutputHello, World!

To see how we can use [variables](how-to-use-variables-in-python-3) in a module, let’s add a variable definition in our `hello.py` file:

hello.py

    # Define a function
    def world():
        print("Hello, World!")
    
    # Define a variable
    shark = "Sammy"

Next, we’ll call the variable in a `print()` function within our `main_program.py` file:

main\_program.py

    # Import hello module
    import hello
    
    
    # Call function
    hello.world()
    
    # Print variable
    print(hello.shark)

Once we run the program again, we’ll receive the following output:

    OutputHello, World!
    Sammy

Finally, let’s also [define a class](how-to-construct-classes-and-define-objects-in-python-3) in the `hello.py` file. We’ll create the class `Octopus` with `name` and `color` attributes and a function that will print out the attributes when called.

hello.py

    # Define a function
    def world():
        print("Hello, World!")
    
    # Define a variable
    shark = "Sammy"
    
    
    # Define a class
    class Octopus:
        def __init__ (self, name, color):
            self.color = color
            self.name = name
    
        def tell_me_about_the_octopus(self):
            print("This octopus is " + self.color + ".")
            print(self.name + " is the octopus's name.")

We’ll now add the class to the end of our `main_program.py` file:

main\_program.py

    # Import hello module
    import hello
    
    
    # Call function
    hello.world()
    
    # Print variable
    print(hello.shark)
    
    # Call class
    jesse = hello.Octopus("Jesse", "orange")
    jesse.tell_me_about_the_octopus()

Once we have called the Octopus class with `hello.Octopus()`, we can access the functions and attributes of the class within the `main_program.py` file’s namespace. This lets us write `jesse.tell_me_about_the_octopus()` on the last line without invoking `hello`. We could also, for example, call one of the class’s attributes such as `jesse.color` without referencing the name of the `hello` module.

When we run the program, we’ll receive the following output:

    OutputHello, World!
    Sammy
    This octopus is orange.
    Jesse is the octopus's name.

It is important to keep in mind that though modules are often definitions, they can also implement code. To see how this works, let’s rewrite our `hello.py` file so that it implements the `world()` function:

hello.py

    # Define a function
    def world():
        print("Hello, World!")
    
    # Call function within module
    world()

We have also deleted the other definitions in the file.

Now, in our `main_program.py` file, we’ll delete every line except for the import statement:

main\_program.py

    # Import hello module
    import hello

When we run `main_program.py` we’ll receive the following output:

    OutputHello, World!

This is because the `hello` module implemented the `world()` function which is then passed to `main_program.py` and executes when `main_program.py` runs.

A module is a Python program file composed of definitions or code that you can leverage in other Python program files.

## Accessing Modules from Another Directory

Modules may be useful for more than one programming project, and in that case it makes less sense to keep a module in a particular directory that’s tied to a specific project.

If you want to use a Python module from a location other than the same directory where your main program is, you have a few options.

### Appending Paths

One option is to invoke the path of the module via the programming files that use that module. This should be considered more of a temporary solution that can be done during the development process as it does not make the module available system-wide.

To append the path of a module to another programming file, you’ll start by importing the `sys` module alongside any other modules you wish to use in your main program file.

The `sys` module is part of the Python Standard Library and provides system-specific parameters and functions that you can use in your program to set the path of the module you wish to implement.

For example, let’s say we moved the `hello.py` file and it is now on the path `/usr/sammy/` while the `main_program.py` file is in another directory.

In our `main_program.py` file, we can still import the `hello` module by importing the `sys` module and then appending `/usr/sammy/` to the path that Python checks for files.

main\_program.py

    import sys
    sys.path.append('/usr/sammy/')
    
    import hello
    ...

As long as you correctly set the path for the `hello.py` file, you’ll be able to run the `main_program.py` file without any errors and receive the same output as above when `hello.py` was in the same directory.

### Adding the Module to the Python Path

A second option that you have is to add the module to the path where Python checks for modules and packages. This is a more permanent solution that makes the module available environment-wide or system-wide, making this method more portable.

To find out what path Python checks, run the Python interpreter from your programming environment:

    python

Next, import the `sys` module:

    import sys

Then have Python print out the system path:

    print(sys.path)

Here, you’ll receive some output with at least one system path. If you’re in a programming environment, you may receive several. You’ll want to look for the one that is in the environment you’re currently using, but you may also want to add the module to your main system Python path. What you’re looking for will be similar to this:

    Output'/usr/sammy/my_env/lib/python3.5/site-packages'

Now you can move your `hello.py` file into that directory. Once that is complete, you can import the `hello` module as usual:

main\_program.py

    import hello
    ...

When you run your program, it should complete without error.

Modifying the path of your module can ensure that you can access the module regardless of what directory you are in. This is useful especially if you have more than one project referencing a particular module.

## Conclusion

Writing a Python module is the same as writing any other Python `.py` file. This tutorial covered how to write definitions within a module, make use of those definitions within another Python programming file, and went over options of where to keep the module in order to access it.

You can learn more about installing and importing modules by reading [How To Import Modules in Python 3](how-to-import-modules-in-python-3).
