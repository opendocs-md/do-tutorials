---
author: Lisa Tagliaferri
date: 2017-05-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-logging-in-python-3
---

# How To Use Logging in Python 3

## Introduction

The `logging` module is part of the standard Python library and provides tracking for events that occur while software runs. You can add logging calls to your code to indicate what events have happened.

The `logging` module allows for both diagnostic logging that records events related to an application’s operation, as well as audit logging which records the events of a user’s transactions for analysis. It is especially used to record events to a file.

## Why Use the `logging` Module

The `logging` module keeps a record of the events that occur within a program, making it possible to see output related to any of the events that occur throughout the runtime of a piece of software.

You may be more familiar with checking that events are occurring by using the `print()` statement throughout your code. The `print()` statement _does_ provide a basic way to go about debugging your code to resolve issues. While embedding `print()` statements throughout your code can track the execution flow and the current state of your program, this solution proves to be less maintainable than using the `logging` module for a few reasons:

- It becomes difficult to distinguish between debugging output and normal program output because the two are mixed
- When using `print()` statements dispersed throughout code, there is no easy way to disable the ones that provide debugging output
- It becomes difficult to remove all the `print()` statements when you are done with debugging
- There is no log record that contains readily available diagnostic information

It is a good idea to get in the habit of using the `logging` module in your code as this is more suitable for applications that grow beyond simple Python scripts and provides a sustainable approach to debugging.

Because logs can show you behavior and errors over time, they also can give you a better overall picture of what is going on in your application development process.

## Printing Debug Messages to Console

If you are used to using the `print()` statement to see what is occurring in a program, you may be used to seeing a program that [defines a class](how-to-construct-classes-and-define-objects-in-python-3) and instantiates objects that looks something like this:

pizza.py

    class Pizza():
        def __init__ (self, name, price):
            self.name = name
            self.price = price
            print("Pizza created: {} (${})".format(self.name, self.price))
    
        def make(self, quantity=1):
            print("Made {} {} pizza(s)".format(quantity, self.name))
    
        def eat(self, quantity=1):
            print("Ate {} pizza(s)".format(quantity, self.name))
    
    pizza_01 = Pizza("artichoke", 15)
    pizza_01.make()
    pizza_01.eat()
    
    pizza_02 = Pizza("margherita", 12)
    pizza_02.make(2)
    pizza_02.eat()
    

The code above has an ` __init__ ` method to define the `name` and `price` of an object of the `Pizza` class. It then has two methods, one called `make()` for making pizzas, and one called `eat()` for eating pizzas. These two methods take in the parameter of `quantity`, which is initialized at `1`.

Now let’s run the program:

    python pizza.py

We’ll receive the following output:

    OutputPizza created: artichoke ($15)
    Made 1 artichoke pizza(s)
    Ate 1 pizza(s)
    Pizza created: margherita ($12)
    Made 2 margherita pizza(s)
    Ate 1 pizza(s)

While the `print()` statement allows us to see that the code is working, we can use the `logging` module to do this instead.

Let’s remove or comment out the `print()` statements throughout the code, and add `import logging` to the top of the file:

pizza.py

    import logging
    
    
    class Pizza():
        def __init__ (self, name, value):
            self.name = name
            self.value = value
    ...

The `logging` module has a [default level](how-to-use-logging-in-python-3#table-of-logging-levels) of `WARNING`, which is a level above `DEBUG`. Since we’re going to use the `logging` module for debugging in this example, we need to modify the configuration so that the level of `logging.DEBUG` will return information to the console for us. We can do that by adding the following line below the [import statement](how-to-import-modules-in-python-3):

pizza.py

    import logging
    
    logging.basicConfig(level=logging.DEBUG)
    
    
    class Pizza():
    ...

This level of `logging.DEBUG` refers to a constant integer value that we reference in the code above to set a threshold. The level of `DEBUG` is 10.

Now, we will replace all of the `print()` statements with `logging.debug()` statements instead. Unlike `logging.DEBUG` which is a constant, `logging.debug()` is a method of the `logging` module. When working with this method, we can make use of the same [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) passed to `print()`, as shown below.

pizza.py

    import logging
    
    logging.basicConfig(level=logging.DEBUG)
    
    
    class Pizza():
        def __init__ (self, name, price):
            self.name = name
            self.price = price
            logging.debug("Pizza created: {} (${})".format(self.name, self.price))
    
        def make(self, quantity=1):
            logging.debug("Made {} {} pizza(s)".format(quantity, self.name))
    
        def eat(self, quantity=1):
            logging.debug("Ate {} pizza(s)".format(quantity, self.name))
    
    pizza_01 = Pizza("artichoke", 15)
    pizza_01.make()
    pizza_01.eat()
    
    pizza_02 = Pizza("margherita", 12)
    pizza_02.make(2)
    pizza_02.eat()
    

At this point, when we run the program with the `python pizza.py` command, we’ll receive this output:

    OutputDEBUG:root:Pizza created: artichoke ($15)
    DEBUG:root:Made 1 artichoke pizza(s)
    DEBUG:root:Ate 1 pizza(s)
    DEBUG:root:Pizza created: margherita ($12)
    DEBUG:root:Made 2 margherita pizza(s)
    DEBUG:root:Ate 1 pizza(s)

The log messages have the severity level `DEBUG` as well as the word `root` embedded in them, which refers to the level of your Python module. The `logging` module can be used with a hierarchy of loggers that have different names, so that you can use a different logger for each of your modules.

For example, you can set loggers equal to different loggers that have different names and different output:

    logger1 = logging.getLogger("module_1")
    logger2 = logging.getLogger("module_2")
    
    logger1.debug("Module 1 debugger")
    logger2.debug("Module 2 debugger")

    OutputDEBUG:module_1:Module 1 debugger
    DEBUG:module_2:Module 2 debugger

Now that we have an understanding of how to use the `logging` module to print messages to the console, let’s move on to using the `logging` module to print messages out to a file.

## Logging Messages to a File

The primary purpose of the `logging` module is to log messages to a file rather than to a console. Keeping a file of messages provides you with data over time that you can consult and quantify so that you can see what changes need to be made to your code.

To start logging to a file, we can modify the `logging.basicConfig()` method to include a `filename` parameter. In this case, let’s call the filename `test.log`:

pizza.py

    import logging
    
    logging.basicConfig(filename="test.log", level=logging.DEBUG)
    
    
    class Pizza():
        def __init__ (self, name, price):
            self.name = name
            self.price = price
            logging.debug("Pizza created: {} (${})".format(self.name, self.price))
    
        def make(self, quantity=1):
            logging.debug("Made {} {} pizza(s)".format(quantity, self.name))
    
        def eat(self, quantity=1):
            logging.debug("Ate {} pizza(s)".format(quantity, self.name))
    
    pizza_01 = Pizza("artichoke", 15)
    pizza_01.make()
    pizza_01.eat()
    
    pizza_02 = Pizza("margherita", 12)
    pizza_02.make(2)
    pizza_02.eat()
    

The code above is the same as it was in the previous section, except that now we added the filename for the log to print to. Once we run the code with the `python pizza.py` command, we should have a new file in our directory called `test.log`.

Let’s open the `test.log` file with nano (or the text editor of your choice):

    nano test.log

When the file opens, we’ll see the following:

test.log

    DEBUG:root:Pizza created: artichoke ($15)
    DEBUG:root:Made 1 artichoke pizza(s)
    DEBUG:root:Ate 1 pizza(s)
    DEBUG:root:Pizza created: margherita ($12)
    DEBUG:root:Made 2 margherita pizza(s)
    DEBUG:root:Ate 1 pizza(s)

This is similar to the console output that we encountered in the previous section, except now it is in the `test.log` file.

Let’s close the file with `CTRL` + `x` and move back into the `pizza.py` file so that we can modify the code.

We’ll keep much of the code the same, but modify the parameters in the two pizza instances, `pizza_01` and `pizza_02`:

pizza.py

    import logging
    
    logging.basicConfig(filename="test.log", level=logging.DEBUG)
    
    
    class Pizza():
        def __init__ (self, name, price):
            self.name = name
            self.price = price
            logging.debug("Pizza created: {} (${})".format(self.name, self.price))
    
        def make(self, quantity=1):
            logging.debug("Made {} {} pizza(s)".format(quantity, self.name))
    
        def eat(self, quantity=1):
            logging.debug("Ate {} pizza(s)".format(quantity, self.name))
    
    # Modify the parameters of the pizza_01 object
    pizza_01 = Pizza("Sicilian", 18)
    pizza_01.make(5)
    pizza_01.eat(4)
    
    # Modify the parameters of the pizza_02 object
    pizza_02 = Pizza("quattro formaggi", 16)
    pizza_02.make(2)
    pizza_02.eat(2)
    

With these changes, let’s run the program again with the `python pizza.py` command.

Once the program has run, we can open our `test.log` file again with nano:

    nano test.log

When we look at the file, we’ll see that several new lines were added, and that the previous lines from the last time that the program ran were retained:

test.log

    DEBUG:root:Pizza created: artichoke ($15)
    DEBUG:root:Made 1 artichoke pizza(s)
    DEBUG:root:Ate 1 pizza(s)
    DEBUG:root:Pizza created: margherita ($12)
    DEBUG:root:Made 2 margherita pizza(s)
    DEBUG:root:Ate 1 pizza(s)
    DEBUG:root:Pizza created: Sicilian ($18)
    DEBUG:root:Made 5 Sicilian pizza(s)
    DEBUG:root:Ate 4 pizza(s)
    DEBUG:root:Pizza created: quattro formaggi ($16)
    DEBUG:root:Made 2 quattro formaggi pizza(s)
    DEBUG:root:Ate 2 pizza(s)

While this information is certainly useful, we can make the log more informative by adding additional [LogRecord attributes](https://docs.python.org/3/library/logging.html#logrecord-attributes). Primarily, we would like to add a human-readable time stamp that tells us when the LogRecord was created.

We can add that attribute to a parameter called `format`, referencing it as shown in the table with the string `%(asctime)s`. Additionally, to keep the `DEBUG` level name, we’ll need to include the string `%(levelname)s` and to keep the string message that we ask the logger to print out we’ll include `%(message)s`. Each of these attributes will be separated by a `colon`, as shown in the code added below.

pizza.py

    import logging
    
    logging.basicConfig(
        filename="test.log",
        level=logging.DEBUG,
        format="%(asctime)s:%(levelname)s:%(message)s"
        )
    
    
    class Pizza():
        def __init__ (self, name, price):
            self.name = name
            self.price = price
            logging.debug("Pizza created: {} (${})".format(self.name, self.price))
    
        def make(self, quantity=1):
            logging.debug("Made {} {} pizza(s)".format(quantity, self.name))
    
        def eat(self, quantity=1):
            logging.debug("Ate {} pizza(s)".format(quantity, self.name))
    
    pizza_01 = Pizza("Sicilian", 18)
    pizza_01.make(5)
    pizza_01.eat(4)
    
    pizza_02 = Pizza("quattro formaggi", 16)
    pizza_02.make(2)
    pizza_02.eat(2)
    

When we run the code above with the added attributes with the `python pizza.py` command, we’ll get new lines added to our `test.log` file that include the human-readable time stamp in addition to the level name of `DEBUG` and the associated messages that are passed into the logger as strings.

    OutputDEBUG:root:Pizza created: Sicilian ($18)
    DEBUG:root:Made 5 Sicilian pizza(s)
    DEBUG:root:Ate 4 pizza(s)
    DEBUG:root:Pizza created: quattro formaggi ($16)
    DEBUG:root:Made 2 quattro formaggi pizza(s)
    DEBUG:root:Ate 2 pizza(s)
    2017-05-01 16:28:54,593:DEBUG:Pizza created: Sicilian ($18)
    2017-05-01 16:28:54,593:DEBUG:Made 5 Sicilian pizza(s)
    2017-05-01 16:28:54,593:DEBUG:Ate 4 pizza(s)
    2017-05-01 16:28:54,593:DEBUG:Pizza created: quattro formaggi ($16)
    2017-05-01 16:28:54,593:DEBUG:Made 2 quattro formaggi pizza(s)
    2017-05-01 16:28:54,593:DEBUG:Ate 2 pizza(s)

Depending on your needs, you may want to make use of additional [LogRecord attributes](https://docs.python.org/3/library/logging.html#logrecord-attributes) in your code in order to make your program files’ logs relevant to you.

Logging debugging and other messages into separate files provides you with a holistic understanding of your Python program over time, giving you the opportunity to troubleshoot and modify your code in a manner that is informed by the historical work put into the program, as well as the events and transactions that occur.

## Table of Logging Levels

As a developer, you can ascribe a level of importance to the event that is captured in the logger by adding a severity level. The severity levels are shown in the table below.

Logging levels are technically integers (a constant), and they are all in increments of 10, starting with `NOTSET` which initializes the logger at the numeric value of 0.

You can also define your own levels relative to the predefined levels. If you define a level with the same numeric value, you will overwrite the name associated with that value.

The table below shows the various level names, their numeric value, what function you can use to call the level, and what that level is used for.

| Level | Numeric Value | Function | Used to |
| --- | --- | --- | --- |
| `CRITICAL` | 50 | `logging.critical()` | Show a serious error, the program may be unable to continue running |
| `ERROR` | 40 | `logging.error()` | Show a more serious problem |
| `WARNING` | 30 | `logging.warning()` | Indicate something unexpected happened, or could happen |
| `INFO` | 20 | `logging.info()` | Confirm that things are working as expected |
| `DEBUG` | 10 | `logging.debug()` | Diagnose problems, show detailed information |

The `logging` module sets the default level at `WARNING`, so `WARNING`, `ERROR`, and `CRITICAL` will all be logged by default. In the example above, we modified the configuration to include the `DEBUG` level with the following code:

    logging.basicConfig(level=logging.DEBUG)

You can read more about the commands and working with the debugger from the [official `logging` documentation](https://docs.python.org/3/library/logging.html).

## Conclusion

Debugging is an important step of any software development project. The `logging` module is part of the standard Python library, provides tracking for events that occur while software runs, and can output these events to a separate log file to allow you to keep track of what occurs while your code runs. This provides you with the opportunity to debug your code based on understanding the various events that occur from running your program over time.
