---
author: Brian Hogan
date: 2017-07-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-strings-in-ruby
---

# How To Work with Strings in Ruby

## Introduction

A _string_ is a sequence of one or more characters that may consist of letters, numbers, or symbols.

[Strings in Ruby](understanding-data-types-in-ruby#strings) are objects, and unlike other languages, strings are _mutable_, which means they can be changed in place instead of creating new strings.

You’ll use strings in almost every program you write. Strings let you display and communicate with your users using text. In fact, the page you’re reading right now is made up of strings displayed on your screen through your web browser. Strings are one of the most important fundamentals of programming.

In this tutorial, you’ll learn how to work with strings in Ruby. You’ll create strings, display them on the screen, store them in variables, join multiple strings together, and learn how to handle special characters such as newlines, apostrophes, and double quotes.

## Creating and Printing Strings

Strings exist within either single quotes `'` or double quotes `"` in Ruby, so to create a string, enclose a sequence of characters in one or the other:

    'This is a string in single quotes.'
    
    "This is a string in double quotes."

You can choose to use either single quotes or double quotes. In most cases, it won’t matter which one you choose, as long as you are consistent. However, using double quotes lets you perform _string interpolation_, which you’ll learn about in this tutorial.

To display a string in your program, you can use the `print` method:

    print "Let's print out this string."

The `print` method displays the string exactly as written.

Try it out. [Create a new Ruby program](how-to-write-your-first-ruby-program) called `print.rb` using your text editor and use `print` to print three strings:

print.rb

    print 'This is the first string.'
    print 'This is the second string.'
    print 'This is the third string.'

Save the file and run the program:

    ruby print.rb

You’ll see the following output:

    OutputThis is the first string.This is the second string.This is the third string.

Instead of the three strings printed on their own lines, all three strings were printed together on a single line. The `print` method prints the string to the screen, but if you wanted each string on its own line, you’d have to add a line break character yourself.

If you wanted all three strings on separate lines, use the `puts` method instead. Modify your program to use `puts` instead of `print`:

print.rb

    puts 'This is the first string.'
    puts 'This is the second string.'
    puts 'This is the third string.'

Now run the program again, and you’ll see this output:

    OutputThis is the first string.
    This is the second string.
    This is the third string.

The `puts` method prints the string you specify, but also adds a newline character to the end of the string for you.

## Storing Strings in Variables

_Variables_ are a named reference to a place in the computer’s memory. You use variables to store data and retrieve it later.

To store a string in a variable, define the variable name and assign the string’s value:

    my_string = 'This is my string'

Then, to retrieve the value, use the variable’s name:

    print my_string

To test this out yourself, create the file `string_variables.rb` in your editor and add the following code:

string\_variables.rb

    my_name = "Sammy the Shark"
    my_age = "none of your business"
    
    puts my_name
    puts my_age

This program defines two variables: `my_name` and my\_age. Each variable is assigned a string. We then use the `puts` method to print out each string on its own line.

Save the file and execute the program:

    ruby string_variables.rb

You’ll see the following output:

    OutputSammy the Shark
    none of your business

By assigning strings to variables, you can avoid typing the same string over and over each time you want to use it, making it easier to work with and manipulate strings in your programs.

Let’s look at how to join strings together to create new strings.

## String Concatenation

_Concatenation_ means joining two or more strings together to create a new string. In order to concatenate, we use the concatenation operator, represented by a `+` symbol. The `+` symbol is also the addition operator when used with arithmetic operations.

Here’s how you’d concatenate the strings `sammy` and `shark` together:

    "sammy" + "shark"

This would produce the following output:

    Outputsammyshark

Concatenation joins the strings end to end, combining them and outputting a brand new string value. If you want to have a space between the words `sammy` and `shark`, you have to include that space in one of the strings, like this:

    "sammy " + "shark"

Now, you won’t really write code like this in a program, but you will need to mix strings and variables together quite often, and that’s where concatenation comes in.

Here’s an example:

    color = "Blue"
    print "My favorite color is " + color

This would result in the output `My favorite color is blue`. Note that we left a space after the word `is` in the string so the output would have a space between the string and the variable’s value in the output.

You can concatenate multiple strings together this way. Create the file `concatenation.rb` and add this code:

concatenation.rb

    my_name = "Sammy the Shark"
    my_age = "none of your business"
    
    puts "My name is " + my_name + " and my age is " + my_age + "."

This program defines two variables: `my_name` and `my_string`, each with its own assigned string, just like you’ve done before. But this time, instead of printing the values, we’re printing a string that uses concatenation to print those values with some more context.

When you run this program, you’ll see the following output:

    OutputMy name is Sammy the Shark and my age is none of your business.

In this small program, you used concatenation to insert variables into this string.

When you combine two or more strings through concatenation, you are creating a new string you can use throughout your program, so you may want to assign the string you created to a new variable which you can use later:

concatenation.rb

    my_name = "Sammy the Shark"
    my_age = "none of your business"
    
    # assign concatenated string to variable
    output = "My name is " + my_name + " and my age is " + my_age + "."
    
    # Print the output.
    puts output

In a small program like this, using an extra `output` variable is probably unnecessary. But in larger programs, you may want to create a string using concatenation that you’ll use in multiple places. It’s also a good habit to separate data processing like concatenation and arithmetic from output, as eventually your programs will get larger and you’ll want to separate the logic and output into separate files or components to make them easier to manage.

Be sure not to use the `+` operator between two different data types. You can’t concatenate strings and integers together, for instance.

To see what happens, create a new program called `strings_and_integers.rb` with the following content:

strings\_and\_integers.rb

    my_name = "Sammy the Shark"
    my_number = 27
    
    print my_name + my_number

This time we have `my_name` which holds the string `Sammy the Shark` and `my_number` which holds the integer `27`. We know that `27` is not a string because it’s surrounded with quotes. It also doesn’t have a decimal point, so we know it’s an integer.

If you run the program:

    ruby strings_and_ints.rb

You’ll see this error message:

    Outputstrings_and_ints.rb:4:in `+': no implicit conversion of Integer into String (TypeError)
        from strings_and_ints.rb:4:in `<main>'

The error `no implicit conversion of Integer into String` means that Ruby can only concatenate a string to the existing string.

In Ruby version 2.3 and below, you’d see this error message instead:

    strings_and_ints.rb:4:in `+': no implicit conversion of Fixnum into String (TypeError)
        from strings_and_ints.rb:4:in `<main>'

The keyword `Fixnum` was the data type given to integers in previous versions of Ruby. It’s short for Fixed Number. In Ruby 2.4, `Fixnum` and its counterpart, `Bignum`, no longer exist and are replaced with `Integer` instead.

We could alter our program and place the number`27` in quotes (`"27"`) so that it is declared as a string instead of an integer. Or we can convert the number to a string when we create the string, like this:

strings\_and\_integers.rb

    my_name = "Sammy the Shark"
    my_number = 27
    
    print my_name + my_number.to_s

The `.to_s` method converts the integer to a string. This is a better approach, as it lets us keep our number as an integer in our program. We only need it to be a string when we print it out, but we may want it to be an integer if we have to use it in other parts of our program logic.

Run the program again and you’ll see `Sammy the Shark27` printed to the screen.

Converting numbers to strings for concatenation is something you’ll encounter frequently when dealing with zip codes, currency, phone numbers, and other numerical data you want to display on the screen alongside text.

Concatenation is powerful, but it can be tricky. If you accidentally leave off one of the `+` operators, you can get a syntax error. And if you have to join strings with variables holding numbers, you have to convert the variables to strings. Ruby provides another way to inject variable values into a string, called _string interpolation_ that addresses both of these issues.

## Using String Interpolation

When concatenating strings and variables, the output can be hard to read and debug. String interpolation solves this by letting you embed expressions in a string enclosed in double quotes.

Instead of writing this:

    "My name is " + my_name + "!"

You can do this:

    "My name is #{my_name}!"

Instead of terminating the string and using the `+` operator, you enclose the variable with the `#{}` syntax. This syntax tells Ruby to evaluate the expression and inject it into the string.

Try it out. Create a new program called `interpolation.rb` and add this code:

interpolation.rb

    my_name = "Sammy the Shark"
    my_age = "none of your business"
    
    output = "My name is #{my_name} and my age is #{my_age}."
    
    puts output

This is the same program you’ve already written, but this time we’re using string interpolation to create the output.

String interpolation has another benefit: it can convert numerical values to strings automatically. Remember your `strings_and_integers.rb` program? Open that file in your editor again but change the last line so it looks like the following:

strings\_and\_integers.rb

    my_name = "Sammy the Shark"
    my_number = 27
    
    # use interpolation instead of concatenation
    print "My name is #{my_name} and my favorite number is #{my_number}."

Ruby will automatically convert `my_number` to a string, and your program will print the following output when you run it:

    OutputMy name is Sammy the Shark and my favorite number is 27.

String interpolation is powerful and convenient. It’s also the preferred method for concatenating strings with variables.

## String Literals and String Values

Notice that all the strings you’ve created are enclosed in quotes in the code, but the actual printed output does not include the quotation marks.

There is a distinction when referring to each of these. A _string literal_ is the string as it is written in the source code, including quotations. A _string value_ is what you see in the output, and does not include quotations.

This is a string literal:

    "Sammy the Shark"

The string value would be `Sammy the Shark`.

In most cases, you won’t have to worry about this difference, unless you want to use special characters like quotation marks or apostrophes in your strings.

## Escaping Quotes and Apostrophes in Strings

Due to the fact that quotation marks are used to denote strings, you’ll have to do a little extra work if you want apostrophes and quotes in strings.

If you attempt to use an apostrophe in the middle of a single-quoted string, like this:

    'This isn't what I wanted.'

The apostrophe in `isn't` ends the string, as you can see from the strange highlighting in this example. As a result, the Ruby interpreter will attempt to parse the rest of the intended string as code and you’ll get an error.

You’d run into the same situation if you used double quotes in a string enclosed in double quotes:

    "Sammy says, "Hello!""

In this example, the closing double quote in front of `Hello` terminates the string, and the double quote after `Hello!` creates a new string that doesn’t have a matching double quote to terminate it, so Ruby will display an error.

To avoid this problem, you have a few options. First, you can use the alternate syntax for creating strings; if you have to use double quotes in the string, use single quotes to define the string, and vice-versa. You could also _escape_ the quotes, or you could use a different Ruby syntax to define the strings. Let’s look at each approach.

### Option 1: Use the Alternate String Syntax

The easiest way to get around these issues is to enclose your string in single quotes when your string needs to include a double quote, and enclose your string in double quotes when your string needs to use single quotes.

Instead of defining this string with single quotes:

    'This isn't what I wanted.'

Define it with double quotes:

    "This isn't what I wanted."

And instead of using double quotes to define this string:

    "Sammy says, "Hello!""

Use single quotes:

    'Sammy says, "Hello!"'

Using the alternative syntax can get you out of some quick jams, but it’s not always going to work. For example, neither approach will work for this string:

    "Sammy says, "I'm a happy shark!""

In this example, the closing double quote in front of `I'm` really throws things off. This terminates the first string, and then Ruby encounters the apostrophe in `I'm`, which starts a new string with the value `m a happy shark!""`. But this new string doesn’t have a matching single quote to terminate it. And using single quotes to enclose the string introduces a similar problem:

    'Sammy says, "I'm a happy shark!"'

This time the apostrophe in `I'm` terminates the string.

Using the alternative syntax can also make your code inconsistent. Constantly flipping between string syntax can get confusing, We can _escape characters_ to get around this issue.

### Option 2: Escaping Characters in Strings

The backslash character (`\`) , often referred to as the _escape character_ in strings, will prevent Ruby from interpreting the next character in the string literally.

Here’s our problematic string, encoded in double quotes, with double quotes inside:

    "Sammy says, "I'm a happy shark!""

Create a new Ruby program called `quoting.rb` and add this code to the file:

quoting.rb

    print "Sammy says, "I'm a happy shark!""

Run the program:

    ruby quoting.rb

And you’ll see this output:

    Outputquoting.rb:1: syntax error, unexpected tCONSTANT, expecting end-of-input
    print "Sammy says, "I'm a happy shark!""
                         ^

To fix the error, use the backslash in front of the inner double quotes:

quoting.rb

    print "Sammy says, \"I'm a happy shark!\""

Then run the program again and you’ll see the output you expected:

    Sammy says, "I'm a happy shark!"

Notice you don’t have to escape the apostrophe in this example, since there’s no conflict. You only need to escape quotes that will confuse Ruby.

You can avoid escaping quotes entirely by using a different syntax to define strings.

### Option 3: Using Alternative Syntax for Strings

Up until now you’ve used quotes to define the boundaries of your strings. You can create strings in Ruby using other characters as well You can define the _delimiter_, or character you’d like to use to enclose your string, by specifying it after a percent sign, like this:

    %$Sammy says, "I'm a happy shark!"$

This syntax will automatically escape the embedded strings for you. The actual string looks like this:

    "Sammy says, \"I'm a happy shark!\""

However, changing the delimiter means you have to escape the delimiter if you need to use it. In this case. if you had to use a dollar sign in your string, you’d need to escape the literal dollar sign in the string.

To avoid this, you can also use pairs of braces, square brackets, or parentheses as delimiters. Curly braces are most common:

    %{Sammy says, "I'm a happy shark!"}

These forms all support string interpolation if you need it.

    droplets = 5
    print %{Sammy says, "I just created #{droplets} droplets!"}

You’ll also see `%Q{}` and `%q{}` used to define strings in Ruby programs. The `%Q{}` syntax works exactly like double-quoted strings, which means that you don’t have to esacpe double quoates, and you will be able to use string interpolation:

    droplets = 5
    print %Q{Sammy says, "I just created #{droplets} droplets!"}

The `%q{}` syntax works exactly like single-quoted strings:

    %q{Sammy says, "I'm a happy shark!"}

You might see the `%q` and `%Q` syntax used with parentheses or square braces in some programs instead of curly braces.

As you can see, there are lots of ways to create strings in Ruby. Whichever method you choose, be consistent in your code. You’ll find that the `%Q{}` and `%{}` methods are the most common.

Now that you know how to handle special characters, let’s look at how to handle long strings and newline characters.

## Long Strings and Newlines

There are times you may want to insert a newline character, or carriage return in your string. You can use the `\n` or `\r` escape characters to insert a newline in the code:

    output = "This is\na string\nwith newlines"
    puts output

This program would produce this output:

    OutputThis is
    a string
    with newlines

This technically works to get our output on multiple lines. However, writing a very long string on a single line will quickly become very hard to read and work with. There are a few solutions.

First, you can use the concatenation operator to split the string onto multiple lines:

    output = "This is a\n" +
             "longer string\n" +
             "with newlines."
    puts output

This just concatenates three strings together, similar to what you’ve already done.

You can also just put the line breaks right in the string:

    output = "This is a
             longer string
             with newlines"
    puts output

You can also use any of the alternate string syntaxes to create multiline strings:

    output = %{This is a
               longer string
               with newlines}
    puts output

In both of these examples, notice that we don’t need the newline ( `\n`) characters. This approach preserves whitespace, including indentation and newlines.

As a result, the output will contain the line breaks, as well as all the leading indentation, like this:

    OutputThis is a
               longer string
               with newlines

To prevent that, remove the extra whitespace from your code:

    output = %{This is a
    longer string
    with newlines
    }

You can also create multiline strings using a _[heredoc](https://en.wikipedia.org/wiki/Here_document)_, or “here document”, a term used for multiline string literals in programs. Here’s how you’d write that code:

    output = <<-END
    This is a
    longer string
    with newlines
    END

The `<<-END` and `END` markers denote the start and end of the heredoc.

Heredocs in Ruby also preserve whitespace characters, which means if you indent the code in the heredoc, the leading indentation is preserved too. So this code:

    output = <<-END
      This is a
      longer string
      with newlines
    END

would print out with two spaces of indentation.

Ruby 2.3 and higher provide the “squiggly heredoc” syntax which automatically removes this leading whitespace. Replace the hyphen in the heredoc definition with a tilde, so `<<-` becomes `<<~`, like this:

    output = <<~END
      This is a
      longer string
      with newlines
      and the code is indented
      but the output is not.
    END

This produces the following output:

    OutputThis is a
    longer string
    with newlines
    and the code is indented
    but the output is not.

This lets you use heredocs and keep your code nicely indented.

Heredocs in Ruby also supports string interpolation.

As you can see, there are a lot of ways to handle newlines and multiline strings in Ruby. You’ll encounter all of these methods as you work with existing Ruby code, as each project tends to have its own style. In your own code, choose the style that’s right for you and be consistent.

## String Replication

There may be times when you need to use Ruby to repeat a string of characters several times. You can do so with the `*` operator. Like the `+` operator, the `*` operator has a different use when used with numbers, where it is the operator for multiplication. When used with one string and one integer, `*` is the _string replication operator_, repeating a single string however many times you would like using the integer you provide.

To print out `Sammy` nine times, you’d use the following code:

    print "Sammy" * 9

This code produces the following output:

    OutputSammySammySammySammySammySammySammySammySammy

You can use this to create some nice ASCII art. Create a file called `banner.rb` and add the following code:

    puts "=" * 15
    puts "| Hello World |"
    puts "=" * 15

Can you picture what the program will produce before running it?

It produces this output:

    Output===============
    | Hello World |
    ===============

This is just a small example of how you can make the computer perform repetitive tasks for you.

## Conclusion

In this tutorial, you learned how to work with the _String_ data type in the Ruby programming language. You created new strings, concatenated them with other strings, and handled newlines, quotes, and apostrophes. Then you used string interpolation to make mixing strings and variable values easier, and you learned how to repeat strings.
