---
author: Brian Hogan
date: 2017-10-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-convert-data-types-in-ruby
---

# How To Convert Data Types in Ruby

## Introduction

While each program you create will contain multiple [data types](understanding-data-types-in-ruby), it is important to keep in mind that you will generally be performing operations within the same data type. That is, you’ll be performing mathematics on numbers, or joining strings together.

Sometimes data comes from external sources, such as the keyboard, an API response, or a database, and you’ll need to convert it in order to work with it. Ruby provides several methods for converting values from one data type to another. In this tutorial, you’ll convert strings to numbers, objects to strings, strings to arrays, and convert between strings and symbols.

## Converting Strings to Numbers

Ruby provides the `to_i` and `to_f` methods to convert strings to numbers. `to_i` converts a string to an integer, and `to_f` converts a string to a float.

    "5".to_i # 5
    "55.5".to_i # 55
    "55.5".to_f # 55.5

Let’s demonstrate this by creating a small program that prompts for two numbers and displays the sum . Create a new Ruby program called `adder.rb` with the following code:

adder.rb

    print "What is the first number? "
    first_number = gets.chop
    
    print "What is the second number? "
    second_number = gets.chop
    
    sum = first_number + second_number
    
    print sum

When you run the program, you’ll get a surprising answer:

    ruby adder.rb

    OutputWhat is the first number? 5
    What is the second number? 5
    55

This program says that the sum of `5` and `5` is `55`. You know that’s not right, but the computer isn’t technically wrong. Our program prompted for two numbers, but we typed them in on the keyboard. We didn’t send the _number_ 5; we sent the _character_ `"5"`. In other words, our program saw both of our inputs as strings, and when you add the strings `"5"` and `"5"` together, you get a new string, `"55"`.

To avoid this, we have to convert both strings to numbers. Modify your program so that it converts both numbers to floats by using the `to_f` method:

adder.rb

    print "What is the first number? "
    first_number = gets.chop
    
    print "What is the second number? "
    second_number = gets.chop
    
    # convert strings to numbers
    first_number = first_number.to_f
    second_number = second_number.to_f
    
    sum = first_number + second_number
    
    print sum

Run the program with `ruby adder.rb` again. This time you’ll see this output:

    OutputWhat is the first number? 5
    What is the second number? 5
    10.0

When you enter in `5` and `5` again, you’ll get `10.0` this time.

The `to_i` and `to_f` methods have some interesting behaviors when the strings aren’t numeric. Look at the following example:

    "123-abc".to_i # 123

In this example, converting the string `"123abc"` to an Integer results in the integer `123`. The `to_i` method stops once it reaches the first non-numeric character. Ruby web developers exploit this by creating URLs like `15-sammy-shark`, where `15` is an internal ID to look up a record, but `sammy-shark` gives a textual description in the URL. When Ruby converts `15-sammy-shark` to an integer with `to_i`, the result is `15`, and the `-sammy-shark` part is truncated and discarded. The integer can then be used to retrieve the record from a database.

Here’s another example of integer behavior that can catch you off-guard:

    "abc".to_i # 0

In this example, the `to_i` method returns `0`, since none of the characters in the string could be converted. This may result in undesired behavior; if a user enters`"abc"` into your program, and you convert that value to an integer and divide some number by that value, your program will crash, since it can’t divide by zero.

Ruby offers anothe way to perform this conversion. You can use the `Integer` and `Float` methods to convert data instead:

    Integer("123") # 123

If you pass the `Integer` method a value that can’t be converted, Ruby will raise an error:

    Integer("123abc")

    OutputArgumentError: invalid value for Integer(): "123abc"

You can then handle the error and provide a message to the user, asking them to provide better data. This approach is less convenient, but it can result in better data integrity, since your data won’t be coerced.

Let’s look at how to convert other types of data to sttings next.

## Converting Data to Strings

Ruby provides the `to_s` method to convert any other type to a string:

    25.to_s # "25"
    (25.5).to_s # "25.5"
    ["Sammy", "Shark"].to_s # "[\"Sammy\", \"Shark\"]"

You’ll often convert data to Strings when creating program output.

Let’s say we want to keep track of a person’s daily calorie burn after a workout. We want to show this progress to the user, which means we’ll be printing out string and numeric values at the same time. Create the file `calories.rb` with the following content:

calories.rb

    user = "Sammy"
    calories = 100
    
    print "Congratulations, " + user + "! You just burned " + calories + " calories during this workout."

We’re hard-coding the name and calories in this program, but in a real program you’d retrieve those values from another source.

Run the program with `ruby calories.rb`.

When you run this program, you’ll see this error:

    OutputTypeError: no implicit conversion of Integer into String

Ruby won’t let you add the `calories` variable to the rest of the output, because it’s an integer. We can’t just change it to a string by putting quotes around it, because, again, the calorie data might be coming from somewhere we don’t control. Instead, we need to convert the calorie data to a string so we can join it to the rest of the output.

Modify the output line so it converts the `calories` to a string by using the `to_s` method:

calories.rb

    user = "Sammy"
    calories = 100
    
    print "Congratulations, " + user + "! You just burned " + calories.to_s + " calories during this workout."

Run the program again and you’ll see the output you’re expecting:

    OutputCongratulations, Sammy! You just burned 100 calories during this workout.

Ruby’s [string interpolation](how-to-work-with-strings-in-ruby#using-string-interpolation) feature automatically converts objects to strings for you. This is the preferred method for creating output in Ruby programs.

Rewrite the output line of your program to use string interpolation instead:

calories.rb

    print "Congratulations, #{user}! You just burned #{calories} calories during this workout."

Run the program again and you’ll see the same output.

Ruby objects all provide their own `to_s` implementation, which may or may not be adequate for output. You may have to write your own code to get the output you’re looking for or investigate other methods to format the data.

**Note** : Ruby objects also provide the `inspect` method which is great for debugging. The `inspect` method works just like `to_s`. It often returns a string representation of the object and its data. You wouldn’t use `inspect` in a production app, but you could use it with `puts` when looking at a variable while you’re writing code.

Let’s look at how to convert a string into an array.

## Converting Strings to Arrays

If you have a String, you can convert it to an Array using the `split` method.

    "one two three".split # ["one", "two", "three"]

You can specify the character you want to use as the delimiter by passing it as an argument to the `split` method.

Try it out. Create a program called `data_import.rb` that contains a string of sharks, separated by commas. The program takes the data, converts it to an array, sorts it, and prints out each element to the screen:

    data = "Tiger,Great White,Hammerhead,Whale,Bullhead"
    
    # Convert data to an array by splitting on commas
    sharks = data.split(",")
    
    # Sort the sharks alpabetically
    sharks = sharks.sort!
    
    # Print out the sharks
    sharks.each{|shark| puts shark }

Run the program with `ruby data_import.rb` and you’ll see this output:

    OutputBullhead
    Great White
    Hammerhead
    Tiger
    Whale

Ruby’s arrays are powerful data structures. This demonstrates one way to use them to process data.

Finally, let’s look at how to convert between Strings and Symbols.

## Converting Between Strings and Symbols

You’ll occasionally want to convert a Symbol to a String so you can display it, and you’ll sometimes want to convert a String to a Symbol so you can use it to look something up in a Hash.

Ruby’s `to_s` method works on Symbols too, so you can convert Symbols into Strings.

    :language.to_s # "language"

This comes in handy if you need to display a Symbol and want to transform how it looks. For example, this program takes the symbol `:first_name` and converts it to the string `"First name"`, which is more human-readable:

    string = :first_name.to_s
    
    # replace underscore with a space and capitalize
    string = string.gsub("_"," ").capitalize

To convert a string to a symbol, use the `to_sym` method, like this:

    "first_name".to_sym # :first_name

To take the string `"First name"` and convert it to the symbol `:first_name`, you’d lower-case all the letters and replace spaces with underscores:

    string = "First name"
    
    # replace spaces with underscores and convert to lowercase
    string = string.gsub(" ","_").downcase
    
    # Convert to symbol
    symbol = string.to_sym 

You’ll find cases where you’ll want to do these conversions, whether it’s displaying a symbol on the screen in a human-friendly format, or using a string to look up a key in a hash that uses symbols for its keys. Now you know how.

## Conclusion

This tutorial demonstrated how to convert several of the important native data types to other data types using built-in methods. You can now convert numbers to strings, strings to arrays, and convert between symbols and strings.

Take a look at these tutorials to continue your exploration of Ruby’s data types:

- [How to Work with Strings in Ruby](how-to-work-with-strings-in-ruby)
- [How to Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby)
