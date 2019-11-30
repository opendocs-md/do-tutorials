---
author: Lisa Tagliaferri
date: 2016-10-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-variables-in-python-3
---

# How To Use Variables in Python 3

## Introduction

**Variables** are an important programming concept to master. They are essentially symbols that stand in for a value you’re using in a program.

This tutorial will cover some variable basics and how to best use them within the Python 3 programs you create.

## Understanding Variables

In technical terms, a variable is assigning a storage location to a value that is tied to a symbolic name or identifier. The variable name is used to reference that stored value within a computer program.

You can think of a variable as a label that has a name on it, which you tie onto a value:

![Variables in Python](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/Variables/variable_value.png)

Let’s say we have an integer, `103204934813`, and we want to store it in a variable rather than continuously retype the long number over and over again. Instead, let’s use something that’s easy to remember like the variable `my_int`:

    my_int = 103204934813

If we think of it like a label that is tied to the value, it will look something like this:

![Python Variable Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/Variables/variable_example.png)

The label has the variable name `my_int` written on it, and is tied to the integer value `103204934813`.

The phrase `my_int = 103204934813` is an **assignment statement** , which consists of a few parts:

- the variable name (`my_int`) 
- the **assignment operator** , also known as the equal sign (`=`)
- the value that is being tied to the variable name (`103204934813`)

Together, those three parts make up the statement that sets the variable `my_int` equal to the value of the integer `103204934813`.

As soon as we set a variable equal to a value, we **initialize** or create that variable. Once we have done that, we are set to use the variable instead of the value. In Python, variables do not need explicit declaration prior to use like some programming languages; you can start using the variable right away.

As soon as we set `my_int` equal to the value of `103204934813`, we can use `my_int` in the place of the integer, so let’s print it out:

    print(my_int)

    Output103204934813

Using variables, we can quickly and easily do [math](how-to-do-math-in-python-3-with-operators). With `my_int = 1040`, let’s subtract the integer value 813:

    print(my_int - 813)

    Output103204934000

In this example, Python does the math for us, subtracting 813 from the variable `my_int` to return the sum `103204934000`.

Speaking of math, variables can be set equal to the result of a math equation. Let’s add two numbers together and store the value of the sum into the variable `x`:

    x = 76 + 145

The above example may look like something you’re already familiar with: algebra. In algebra, letters and other symbols are used to represent numbers and quantities within formulas and equations, just like how variables are symbolic names that represent the value of a data type. For correct Python syntax, you’ll need to make sure that your variable is on the left side of any equations.

Let’s go ahead and print `x`:

    print(x)

    Output221

Python returned the value `221` because the variable `x` was set equal to the sum of `76` and `145`.

Variables can represent any data type, not just integers:

    my_string = 'Hello, World!'
    my_flt = 45.06
    my_bool = 5 > 9 #A Boolean value will return either True or False
    my_list = ['item_1', 'item_2', 'item_3', 'item_4']
    my_tuple = ('one', 'two', 'three')
    my_dict = {'letter': 'g', 'number': 'seven', 'symbol': '&'}

If you print any of the above variables, Python will return what that variable is equivalent to. For example, let’s work with the assignment statement for the [list data type](understanding-lists-in-python-3) above:

    my_list = ['item_1', 'item_2', 'item_3', 'item_4']
    print(my_list)

    Output['item_1', 'item_2', 'item_3', 'item_4']

We passed the list value of `['item_1', 'item_2', 'item_3', 'item_4']` to the variable `my_list`, and then used the `print()` function to print out that value by calling `my_list`.

Variables work by carving out a little area of memory within your computer which accepts specified values that are then associated with that space.

## Naming Variables: Rules and Style

The naming of variables is quite flexible, but there are some rules you need to keep in mind:

- Variable names must only be one word (as in no spaces)
- Variable names must be made up of only letters, numbers, and underscore (`_`)
- Variable names cannot begin with a number

Following the rules above, let’s look at both valid and invalid variable names:

| Valid | Invalid | Why Invalid |
| --- | --- | --- |
| my\_int | my-int | Hyphens are not permitted |
| int4 | 4int | Cannot begin with a number |
| MY\_INT | $MY\_INT | Cannot use symbols other than `_` |
| another\_int | another int | Cannot be more than one word |

Something else to keep in mind when naming variables, is that they are case-sensitive, meaning that `my_int`, `MY_INT`, `My_Int`, and `mY_iNt` are all completely different variables. You should avoid using similar variable names within a program to ensure that both you and your current and future collaborators can keep your variables straight.

Finally, some notes about style. Conventionally speaking, when naming variables it is customary to begin them with a lower-case letter and to use underscores when separating words. Beginning with an upper-case letter is not invalid, and some people may prefer camelCase or mixed upper- and lower-case letters when writing their variables, but these are less conventional choices.

| Conventional Style | Unconventional Style | Why Unconventional |
| --- | --- | --- |
| my\_int | myInt | camelCase not conventional |
| int4 | Int4 | Upper-case first letter not conventional |
| my\_first\_string | myFirstString | camelCase not conventional |

The most important style choice you can make is to be consistent. If you begin working on an existing project that has been using camelCase for its variable names, then it is best to continue using the existing style.

[PEP 8](https://www.python.org/dev/peps/pep-0008/) is the official Python code style guide and it addresses many of the stylistic questions you may have about Python. In general, readability and consistency are favored over other stylistic concerns.

## Reassigning Variables

As the word **variable** implies, Python variables can be readily changed. This means that you can connect a different value with a previously assigned variable very easily through simple reassignment.

Being able to reassign is useful because throughout the course of a program, you may need to accept user-generated values into already initialized variables, or may have to change the assignment to something you previously defined.

Knowing that you can readily and easily reassign a variable can also be useful in situations where you may be working on a large program that was begun by someone else and you are not clear yet on what has already been defined.

Let’s assign `x` first as an integer, and then reassign it as a [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3):

    #Assign x to be an integer
    x = 76
    print(x)
    
    #Reassign x to be a string
    x = "Sammy"
    print(x)

    Output76
    Sammy

The example above shows that we can first assign the variable `x` and assign it with the value of an integer, and then reassign the variable `x` assigning it this time with the value of a string.

If we rewrote the program this way:

    x = 76
    x = "Sammy"
    print(x)

We would only receive the second assigned value as the output since that was the most recent assignment:

    OutputSammy

Reassigning variables can be useful in some cases, but you will want to be aware of the readability of your code and work to make your program as clear as possible.

## Multiple Assignment

With Python, you can assign one single value to several variables at the same time. This lets you initialize several variables at once, which you can reassign later in the program yourself, or through user input.

Through multiple assignment, you can set the variables `x`, `y`, and `z` to the value of the integer `0`:

    x = y = z = 0
    print(x)
    print(y)
    print(z)

    Output0
    0
    0

In this example, all three of the variables (`x`, `y`, and `z`) are assigned to the same memory location. They are each equal to the value of 0.

Python also allows you to assign several values to several variables within the same line. Each of these values can be of a different data type:

    j, k, l = "shark", 2.05, 15
    print(j)
    print(k)
    print(l)

    Outputshark
    2.05
    15

In the example above, the variable `j` was assigned to the string `"shark"`, the variable `k` was assigned to the float `2.05`, and the variable `l` was assigned to the integer `15`.

This approach to assigning multiple variables to multiple values in one line can keep your lines of code down, but make sure you are not compromising readability for fewer lines of code.

## Global and Local Variables

When using variables within a program, it is important to keep **variable scope** in mind. A variable’s scope refers to the particular places it is accessible within the code of a given program. This is to say that not all variables are accessible from all parts of a given program — some variables will be global and some will be local.

**Global variables** exist outside of [functions](how-to-define-functions-in-python-3). **Local variables** exist within functions.

Let’s take a look at global and local variables in action:

    #Create a global variable, outside of a function
    glb_var = "global"
    
    #Define a function
    def var_function():
        lcl_var = "local" #Create a local variable, inside function
        print(lcl_var)
    
    #Call function to print local variable
    var_function()
    
    #Print global variable outside function
    print(glb_var)

    Outputlocal
    global

The above program assigns the global variable `glb_var` outside of any function, then defines the function `var_function()`. Inside of the function a local variable called `lcl_var` is assigned and then printed out. The program ends by calling the `var_function()` and then printing the `glb_var`.

Because `glb_var` is a global variable, we can refer to it in `var_function()`. Let’s modify the small program above to do that:

    glb_var = "global"
    
    def var_function():
        lcl_var = "local"
        print(lcl_var)
        print(glb_var) #Print glb_var within function
    
    var_function()
    print(glb_var)

    Outputlocal
    global
    global

We now have the global variable `glb_var` printed out twice, because it is printed both by the function and outside of the function.

What if we try to call the local variable outside of the function?

    glb_var = "global"
    
    def var_function():
        lcl_var = "local"
        print(lcl_var)
    
    print(lcl_var)

    OutputNameError: name 'lcl_var' is not defined

We cannot use a local variable outside of the function it is assigned in. If we try to do so, we’ll receive a `NameError` in return.

Let’s look at another example where we use the same variable name for a global variable and a local variable:

    num1 = 5 #Global variable
    
    def my_function():
        num1 = 10 #Use the same variable name num1
        num2 = 7 #Assign local variable
    
        print(num1) #Print local variable num1
        print(num2) #Print local variable num2
    
    #Call my_function()
    my_function()
    
    #Print global variable num1
    print(num1)

    Output10
    7
    5

Because the local variable of `num1` is assigned locally within a function, when we call that function we see `num1` as equal to the local value of `10`. When we print out the global value of `num1` after calling `my_function()`, we see that the global variable `num1` is still equal to the value of `5`.

It is possible to assign global variables within a function by using Python’s `global` statement:

    def new_shark():
        #Assign variable as global
        global shark
        shark = "Sammy"
    
    #Call new_shark() function
    new_shark()
    
    #Print global variable shark
    print(shark)

Even though the variable `shark` was assigned locally within the `new_shark()` function, it is accessible outside of the function because of the `global` statement used before the assignment of the variable within the function. Due to that `global` statement, when we call `print(shark)` outside of the function we don’t receive an error. Though you _can_ assign a global variable within a function, you likely will not need to do this often, and should err on the side of readable code.

Something else to keep in mind is that if you reference a variable within a function, without also assigning it a value, that variable is implicitly global. In order to have a local variable, you must assign a value to it within the body of the function.

When working with variables, it is important to decide whether it is more appropriate to use a global or local variable. Usually it is best to keep variables local, but when you are using the same variable throughout several functions, you may want to initialize a global variable. If you are working with the variable only within one function or one [class](how-to-construct-classes-and-define-objects-in-python-3), you’ll probably want to use a local variable instead.

## Conclusion

This tutorial went through some of the common use cases of variables within Python 3. Variables are an important building block of programming, serving as symbols that stand in for the value of a [data type](understanding-data-types-in-python-3) you are using in a program.
