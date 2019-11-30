---
author: Brian Hogan
date: 2017-10-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-data-types-in-ruby
---

# Understanding Data Types in Ruby

## Introduction

When you write programs, you use _data types_ to classify data. Data types tell the computer how to handle the data in your program. They also determine what you can do with the data, including which operations you can perform.

One way to think about data types is to consider the different types of data that we use in the real world. For example, we use whole numbers (0, 1, 2, …), integers (…, -1, 0, 1, …), and irrational numbers (π).

Usually, in math, we can combine numbers from different types, and get some kind of an answer. For example, we may want to add 5 to π:

    5 + π

We can either keep the equation as the answer to account for the irrational number, or we can round π to a number with a brief number of decimal places, and then add the numbers together:

    5 + π = 5 + 3.14 = 8.14 

But if we try to evaluate numbers with another data type, such as words, things start to make less sense. How would we solve the following equation?

    sky + 8

This isn’t something we immediately know how to solve. The computer can’t either because the data is of two different types. “Sky” is a word, and `8` is a whole number. When we write programs, we have to be careful about how we assign values and how we manipulate them through operations like addition, subtraction, multiplication, and others.

In this tutorial, you’ll learn about the most important data types native to Ruby: integers, floats, strings, symbols, arrays, and hashes. This is not an exhaustive investigation of data types, but it will help you become familiar with the options you have available to you in your programs.

You’ll then explore _dynamic typing_. Ruby programs determine data types based on what the variables contain, so understanding how dynamic typing works will help you avoid tricky situations in your own programs. And because variables can contain any value, you’ll learn to identify a variable’s data type.

Let’s start by looking at how to work with whole numbers in Ruby.

## Integers

Like in math, _integers_ in computer programming are whole numbers that can be positive, negative, or 0 (…, `-1`, `0`, `1`, …). An integer is also commonly known as an `int`.

You can print out an integer like this:

    print -25

    Output-25

You can also store the integer in a variable and then print the value out by referencing the variable:

    my_int = -25
    print my_int

    Output-25

You can do math with integers, too. For example, you can calculate the sum of two numbers and print out the result:

    sum = 116 - 68
    print sum

    Output48

When we write out larger numbers, we tend to use commas to make them easier to read. For example, we’d write `1,000,000` for “one million”. You can’t use commas in your code, but Ruby lets you use the underscore (`_`) charater to make large numbers more readable.

Try it out:

large\_number.rb

    large_number = 1_234_567
    print large_number

You’ll see the integer printed without the underscores:

    Output1234567

The underscores let you write more readable code if you have to represent large numbers in your programs.

As you learn more about the Ruby language, you will have many more opportunities to work with integers. Let’s look at how to work with _real numbers._

## Floating-Point Numbers

A _floating-point number_ or a _float_ represents a _real_ number. Real numbers can be either a rational or an irrational number; numbers that contain a fractional part, such as `9.0` or `-116.42`. In other words, a float in a Ruby program is a number that contains a decimal point.

You can print out floats in Ruby just like you print out integers:

    print 17.3

    Output17.3

You can also declare a variable and assign a float:

    my_float = 17.3
    print my_float

    Output17.3

And, just like with integers, you can do math with floats in Ruby, too:

    sum = 564.0 + 365.24
    print sum

    Output929.24

If you add a float to an integer in Ruby, you’ll get a float:

    sum = 564 + 365.24
    print sum

    Output929.24

Ruby will consider any number written without decimals as an integer (as in `138`) and any number written with decimals as a float (as in `138.0`).

Next, let’s look at booleans in Ruby.

## Boolean Data Types

_Booleans_ are used to represent the truth values that are associated with the logic branch of mathematics, which informs algorithms in computer science. In Ruby, we represent this data type with one of two values, either `true` or `false`.

Many operations in math give us answers that evaluate to either true or false:

- greater than
  - 500 \> 100 `true`
  - 1 \> 5 `false`
- less than
  - 200 \< 400 `true`
  - 4 \< 2 `false`
- equal
  - 5 = 5 `true`
  - 500 = 400 `false`

Like with numbers, you can store a `true` or `false` value in a variable:

    result = 5 > 8

You can then print the Boolean value with a call to the `print()` function:

    print result

Since 5 is not greater than 8 you’ll see the following result:

    Outputfalse

As you write more programs in Ruby, you will become more familiar with how Booleans work and how different functions and operations evaluating to either `true` or `false` can change the course of the program.

Next, let’s explore working with text in our programs.

## Strings

A _[string](how-to-work-with-strings-in-ruby)_ is a sequence of one or more characters, such as letters, numbers, and symbols. Strings primarily exist within either single quotes (`'`) or double quotes (`"`) in Ruby, so to create a string, enclose a sequence of characters in quotes, like this:

    "This is a string in double quotes."

The simple program “[Hello, World!](how-to-write-your-first-python-3-program)” demonstrates how a string can be used in computer programming, as the characters that make up the phrase `Hello, World!` are a string.

    print "Hello, World!"

As with other data types, you can store strings in variables:

    output = "Hello, World!"

And print out the string by calling the variable:

    print output

    OutputHello, World!

Like numbers, there are many operations that we can perform on strings within our programs in order to manipulate them to achieve the results we are seeking. Strings are important for communicating information to the user, and for the user to communicate information back to the program.

Sometimes you need to work with lists of data. That’s where arrays come in handy.

## Arrays

An _[array](how-to-work-with-arrays-in-ruby)_ can hold multiple values within a single variable. This means that you can contain a list of values within an array and iterate through them. Each item or value that is inside of an array is called an _element_.

Arrays are defined by specifing values between square brackets `[]`, separated by commas.

An array of integers looks like this:

    [-3, -2, -1, 0, 1, 2, 3]

A array of floats looks like this:

    [3.14, 9.23, 111.11, 312.12, 1.05]

Here’s a list of strings:

    ['shark', 'cuttlefish', 'squid', 'mantis shrimp']

Like other data types, you can assign an array to a variable:

    sea_creatures = ['shark', 'cuttlefish', 'squid', 'mantis shrimp']

If we print out the variable, the output looks exactly like the array that we created:

    print sea_creatures

    ['shark', 'cuttlefish', 'squid', 'mantis shrimp']

You access individual elements in an array by using an index number, starting at `0`.

    puts sea_creatures[0] # shark
    puts sea_creatures[2] # squid

To print out the last value, you can use the index `-1`. Ruby also provides the `.first` and .`last` methods for grabbing the first and last entry, respectively:

    puts sea_creatures.first # shark
    puts sea_creatures.last # mantis shrimp

Arrays in Ruby can have many different types of data. You can store strings, symbols, and even other arrays in an array:

    record = [ 
      :en, 
      "Sammy", 
      42, 
      [
        "coral",
        "reef"
      ]
    ]

Arrays in Ruby are _mutable_, which means you can add values, remove values, and even modify entries in the array.

Sometimes we need a way to label things in a program. That’s what symbols are for.

## Symbols

A _symbol_ is a special data type that acts like a label or an identifier in a Ruby program. Symbols are _immutable_, which means that they cannot be changed. A symbol looks like a variable declaration without a value. Here’s an example of a symbol:

    :time_zone

In Ruby, you typically use a symbol to identify something of importance, whereas you’d use a string for text you need to work with or manipulate. Each string in a Ruby program is its own object, with its own unique location in memory, even if the strings are identical.

But if you reference the same symbol multiple times, you’re referencing the same object everywhere in your program, which means you’re referencing the same memory location.

You’ll see this concept in action as we look at hashes, which let you associate keys with values.

## Hashes

A _hash_ is a dictionary-like collection of keys and values. These key-value pairs provide a useful way to store and access data. Hashes are often used to hold data that are related, such as the information about a user. You define a hash like this:

    {"first_name" => "Sammy", "last_name" => "Shark"}

You can assign hashes to variables just like other data types:

    user = {"first_name" => "Sammy", "last_name" => "Shark"}

To retrieve values from the `user` hash, you use the key for the value:

    print user["first_name"] # "Sammy"
    print user["last_name"] # "Shark"

You can use symbols as the keys in your hash instead of strings:

    user = {:first_name => "Sammy", :last_name => "Shark"}

Using symbols as hash keys is preferred whenever possible. Every instance of a symbol points to the same object, whereas each instance of a string refers to a unique object. Using symbols as keys results in slightly better performance and less memory usage.

When you use symbols as keys, you use symbols to retrieve the values:

    print user[:first_name] # "Sammy"
    print user[:last_name] # "Shark"

You can also use a slightly different syntax when defining the hash:

    user = {first_name: "Sammy", last_name: "Shark"}

This syntax is similar to the syntax used in JavaScript and other languages. This syntax defines the keys as Symbols, so you would access the entries using `:first_name` and `:last_name` instead of the strings `"first_name"` and `"last_name"`.

You’ve looked at several data types, so let’s look at how Ruby works with those types.

## Dynamic Typing

In Ruby, you don’t explicitly declare a data type before you assign a value; assigning the value determines the data type. Ruby uses _dynamic typing_, which means type checking is done at runtime rather than compile time, as in languages that use _static typing_. Ruby determines the data type from the data stored in the variable. This is similar to [data types in Python](understanding-data-types-in-python-3) and to [data types in JavaScript](understanding-data-types-in-javascript).

The variable `t` in the following example can be set to any data type available:

    t = 42 # t is an Integer
    t = "Sammy" # t is a String
    t = :sammy # t is a Symbol
    t = true # t is a boolean (true)
    t # t is nil

With dynamically-typed languages, you can reuse an existing variable to hold different data types.

This is useful when converting data from one type to another. For example, you might have this code which asks the user for a numerical value:

    print "Please enter the length of the room: "
    length = gets.chop

The data you get from the keyboard is always a string, so in order to do mathematical operations, you have to convert the `length` variable’s data to a number. In statically-typed languages, where you have to declare the variable’s data type before you can assign it a value, you would need a new variable to hold the converted data. But in Ruby, because it’s dynamically typed, you can reuse the `length` variable if you’d like.

    # Convert the amount to a Float.
    length = length.to_f

The `to_f` method converts the String to a Float. Ruby also provides the `to_i` method to convert Strings to Integers, and most objects can be converted to Strings using the `to_s` method:

    42.to_s # "42"
    (42.5).to_s # "42.5"
    ["Sammy", "Shark"].to_s # "[\"Sammy\", \"Shark\"]"

Ruby is dynamically typed, but it doesn’t allow you to perform operations on different types of data without converting them to the same type. For example, this code will result in an error:

    print 5 + "5"

    OutputTypeError: String can't be coerced into Integer

As will this code:

    print "5" + 5

    OutputTypeError: no implicit conversion of Integer into String

If you want to add the numbers together to get `10`, convert the String to an integer. If you want to concatenate them together to get `"55"`, convert the Integer to a String.

Dynamic typing offers flexibility, but one downside is that you can’t always be sure what kind of data you’re working with, since the variable can contain any available type. Ruby provides ways for you to identify the type of data.

## Identifying Data Types

In Ruby, almost everything is an object. Integer, Float, Array, Symbol, and Hash are all Ruby objects, and they all have a method called `class` that will tell you what type they are. Even the booleans `true` and `false` , and the value `nil` are objects. Try it out for yourself:

    42.class # Integer
    (42.2).class # Float
    ["Sammy", "Shark"].class # Array
    true.class # TrueClass
    nil.class # NilClass

In addition, you can use the `kind_of?` method to verify a certain type of data, like this:

    42.kind_of?(Integer) # true

This is especially useful when you have a variable and you want to determine its type:

    # somewhere in the code...
    sharks = ["Hammerhead", "Tiger", "Great White"]
    ...
    # somewhere else...
    
    sharks.kind_of?(Hash) # false
    sharks.kind_of?(Array) # true

You can also use this to verify that data coming from an external source is correct:

    if data.kind_of? String
      data = data.to_f
    end

Ruby also provides the `is_a?` method, which does the same thing as `kind_of?` but might be a little easier to read for some developers:

    if data.is_a? String
      data = data.to_f
    end

Using `class`, `kind_of?`, and `is_a?` can help you ensure you’re working with the right kind of data. As you learn more about Ruby, you’ll discover other ways to handle data that don’t involve explicitly checking the data’s type.

## Conclusion

You will use many different data types in your Ruby programs. You now have a better understanding of the major data types available in Ruby programs.

Take a look at these tutorials to continue your exploration of Ruby’s data types:

- [How to Work with Strings in Ruby](how-to-work-with-strings-in-ruby)
- [How to Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby)
- [How to Convert Data Types in Ruby](how-to-convert-data-types-in-ruby)
