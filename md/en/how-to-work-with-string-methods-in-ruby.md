---
author: Brian Hogan
date: 2017-10-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-string-methods-in-ruby
---

# How To Work with String Methods in Ruby

## Introduction

Ruby [strings](how-to-work-with-strings-in-ruby) have many built-in methods that make it easy to modify and manipulate text, a common task in many programs.

In this tutorial, you’ll use string methods to determine the length of a string, index and split strings to extract substrings, add and remove whitespace and other characters, change the case of characters in strings, and find and replace text. When you’re done, you’ll be able to incorporate these methods into your own programs.

## Determining String Length

The string method `length` returns the number of characters in a string. This method is useful for when you need to enforce minimum or maximum password lengths, or to truncate larger strings to be within certain limits for use as abbreviations.

Here’s an example that prints the length of a sentence:

    open_source = "Sammy contributes to open source."
    print open_source.length

    Output33

Keep in mind that every character, including letters, numbers, whitespace characters, and symbols, will be counted, since it’s part of the string.

To check to see if a string is empty, you can check to see if its length is `0`, or you can use the `empty?` method:

    name = ""
    name.empty? # true
    
    name = "Sammy"
    name.empty? # false
    
    name = " "
    name.empty? # false

Let’s look at how to we index strings and access a string’s contents.

## Accessing Characters Within a String

To print or work with some of the characters in a string, use the `slice` method to get the part you’d like.

Like [arrays](how-to-work-with-arrays-in-ruby), where each element corresponds to an index number, each of a string’s characters also correspond to an index number, starting with the index number 0.

For the string `Sammy` the index breakdown looks like this:

| 0 | 1 | 2 | 3 | 4 |
| --- | --- | --- | --- | --- |
| S | a | m | m | y |

The `slice` method lets you grab a single character or a range of characters. Passing a single integer returns the character at that index. Passing two integers, separated by a comma, tells `slice` to return all the characters from the first index to the last index, inclusive. The `slice` method also accepts a range, such as `1..4`, to specify the characters to extract:

    "Sammy".slice(0) # "s"
    "Sammy".slice(1,2) # "am"
    "Sammy".slice(1..4) # "ammy"

The `[]` syntax is an alias for `slice`, so you can treat strings like arrays:

    "Sammy"[0] # "s"
    "Sammy"[1,2] # "am"
    "Sammy"[1..4] # "ammy"

You can also access a single character from the end of the string with a negative index. `-1` would let you access the last character of the string, `-2` would access the second-to-last, and so on.

Finally, you can convert the string to an array of characters with the `chars` method:

    "sammy".chars # ["S", "a", "m", "m", "y"]

This can be useful for manipulating or transforming the characters in the string.

Next, let’s look at how to alter the case of the characters in a string.

## Converting to Upper and Lower Case

The `upcase` and `downcase` methods return a string with all the letters of an original string converted to upper- or lower-case letters. Any characters in the string that are not letters will not be changed.

Let’s convert the string `Sammy Shark` to be all upper case:

    name = "Sammy Shark"
    print name.upcase

    OuputSAMMY SHARK

Now, let’s convert the string to be all lower case:

    print name.downcase

    Ouputsammy shark

The `upcase` and `downcase` functions make it easier to evaluate and compare strings by making case consistent throughout. For example, if you ask for a username and the user enters the username with a capital letter, you can lowercase the user’s input and compare it against a lowercase known value.

Ruby strings also have a `capitalize` method which returns a new string with the first character capitalized:

    "sammy".capitalize # "Sammy"

This is a convenient method, but be careful how you use it; it only capitalizes the first letter so it might not always fit the use case you need.

Ruby also provides a `swapcase` method which returns a string with the casing swapped:

    text = "Sammy"
    print text.swapcase

    sAMMY

The `downcase`, `upcase`, `captalize` and `swapcase` methods all return a new string and leave the existing string unaltered. This is important to remember if you’re doing something other than immediately printing out the text. Take a look at the following esxample:

    text = "sammy"
    text.capitalize
    
    print "Hello, #{text}!"

    OutputHello, sammy!

Even though we called `capitalize` on the `text` variable, we never captured the value returned by `capitalize`. We would need to rewrite the program like this:

    text = "sammy"
    text = text.capitalize
    
    print "Hello, #{text}!"

    OutputHello, Sammy!

You can use `downcase!`, `upcase!`, `capitalize!` and `swapcase!` to modify the original string instead:

    text = "sammy"
    text = text.capitalize!
    
    print "Hello, #{text}!"

Be careful though. There are disadvantages to mutating the original string. Ruby provides both methods so you can choose the one that fits your needs.

Now let’s add and remove whitespace from strings.

## Padding and Stripping Strings

If you’re writing a program that has to format some text, you’ll often find that you’ll want to add some space in front of, after, or around a string in order to make it line up with other data. And other times, you may want to remove unnecessary characters from the beginning or end of your strings, like extra whitespace or special characters.

To surround a string with spaces, use the `center` method:

    "Sammy",center(21) # " Sammy "

You can specify a string as the second argument if you want to use a different character:

    " [Sammy] ".center(21, "<>") # "<><><> [Sammy] <><><>"

The `ljust` and `rjust` methods add spaces or characters to the left or right side of a string and work exactly like the `center` method:

    "Sammy".ljust(20) # "Sammy "
    "Sammy".rjust(20) # " Sammy"
    "Sammy".rjust(20, "!") # "!!!!!!!!!!!!!!!Sammy"

To remove leading spaces from a string, use the `rstrip` method. To remove trailing spaces, use `lstrip`. Use `strip` to remove both leading and trailing spaces:

    " Sammy".rstrip # "Sammy"
    "Sammy ".lstrip # "Sammy"
    " Sammy ".strip # "Sammy"

You can use the `center!`, `ljust`!, `rjust!`, `lstrip!`, `rstrip!`, and `strip!` methods to modify the original string.

Sometimes you’ll need to remove characters from the end of a string. Ruby’s `chop` method does just that; it removes the last character from a string:

    "Sammy".chop # "Samm"

This is especially useful for removing the newline character (`\n`) from strings:

    "This string has a newline\n".chop

The `chop` method leaves the original string intact, returning a new string. The `chop!` method modifies the existing string in place.

The `chomp` method can remove multiple characters from the end of a string:

    "Sammy".chomp("my") # "Sam"

If you don’t specify a string to remove, `chomp` will remove the newline:

    "This string has a newline\n".chomp # "This string has a newline

However, if the string doesn’t contain a newline character, `chomp` just returns the original string:

    "Sammy".chomp # "Sammy"

This makes `chomp` a little safer to use when removing newlines than the `chop` method, which always removes the last character.

Ruby has a `chomp!` method that mutates the original string and returns the modfied string if it performed a replacement. However, unlike `chomp`, the `chomp!` method returns `nil` if it didn’t alter the string:

    string = "Hello\n"
    string.chomp! # "Hello"
    
    string = "Hello"
    string.chomp! # nil

Next, let’s look at how to search for text in strings.

## Finding Characters and Text

Sometimes you need to determine whether or not a string contains another string.

The `include?` method checks to see if a string contains another string. It returns `true` if the string exists and `false` if not:

    "Sammy".include?("a") # true
    "Sammy".include?("b") # false

The `index` method returns the index of a character. It can also identify the index of the first character of a substring. And it returns `nil` if the character or substring doesn’t exist:

    "Sammy".index("a") # 1
    "Sammy".index("mm") # 2
    "Sammy".index("Fish") # nil

The `index` method only finds the first occurrance though. Here’s an example with a longer string:

    text = "Sammy has a balloon"
    text.index("a") # 1

The string `Sammy has a balloon` has four occurrances of the letter “a”. But `index` only found the first occurrance. You’ll have to write something more specific to locate one of the other occurrances.

For example, you could convert the string to an array of characters and use [array methods](how-to-use-array-methods-in-ruby) to iterate through the results and select the indices for the character. Here’s one method for doing that:

    text = "Sammy has a balloon"
    indices = text.chars
      .each_with_index
      .select{|char, index| char == "a" }
      .map{|pair| pair.last}
    
    print indices

    [1, 7, 10, 13]

`each_with_index` returns a two-dimensional array containing the an entry for each character and its index. `select` whittles it down to just the entries where the character is `a`, and `map` converts the two dimensional array into a one-dimensional array of the indices.

In addition to looking for characters in a string, you can check to see if a string starts with a character or substring using the `start_with?` method:

    text = "Sammy has a balloon"
    text.start_with?("s") # true
    text.start_with?("Sammy has" # true

The `start_with?` method accepts multiple strings and returns true if any of them match:

    text = "Sammy has a balloon"
    text.start_with?("Sammy the Shark", "Sammy") # true

In this example, “Sammy the Shark” isn’t found, but “Sammy” is, so the return value is `true`.

You can use the `end_with?` method to see if a string ends with the given substring. It works exactly like `start_with?`:

    text = "Sammy has a balloon"
    text.end_with?("balloon") # true
    text.end_with?("boomerang") # false
    text.end_with?("boomerang", "balloon") # true

We’ve looked at ways to find text, so let’s look at how to replace that text with different text.

## Replacing Text in Strings

The find and replace feature in word processors lets you search for a string and replace it with another string. You can do that in Ruby with the `sub` and `gsub` methods.

The `sub` method replaces part of a string with another.

Sammy no longer has the balloon; it flew away. Let’s change the substring `"has"` to `"had"`.

    balloon = "Sammy has a balloon"
    print balloon.sub("has","had")

Our output will look like this:

    OuputSammy had a balloon.

The `sub` method only replaces the first occurrance of the match with the new text. Let’s use a modified string that has two occurrences of the word `has`:

    balloon = "Sammy has a balloon. The balloon has a ribbon"
    print balloon.sub("has","had")

    OutputSammy had a balloon. The balloon has a ribbon

Only the first occurrance changed.

To change them all, use the `gsub` method, which performs _global_ substitution:

    balloon = "Sammy has a balloon. The balloon has a ribbon"
    print balloon.gsub("has","had")

    OutputSammy had a balloon. The balloon had a ribbon

The `sub` and `gsub` methods always return new strings, leaving the originals unmodified. Let’s demonstrate this by changing “balloon” to “boomerang” in our string:

    text = "Sammy has a balloon"
    text.gsub("ballooon", "boomerang")
    print text

    OutputSammy has a balloon

The output doesn’t show the result we’re looking for, because while we did specify the substitution, we never assigned the result of `gsub` to a new variable. To get the result we’d like, we could rewrite the program like this:

    text = "Sammy has a balloon"
    text = text.sub("ballooon", "boomerang")
    print text

Alternatively, you can use `sub!` instead, which modifies the original string. Let’s try this by doing a couple of string replacements. We’ll change “red balloon” to “blue boomerang”:

    text = "Sammy has a red balloon"
    text.sub!("red", "blue")
    text.sub!("balloon", "boomerang")
    print text

    OutputSammy has a blue boomerang

You can use the `gsub!` method to do a global substitution in place as well.

The `sub` and `gsub` methods accept [regular expressions](an-introduction-to-regular-expressions) for the search pattern. Let’s replace all the vowels in the string with the `@` symbol:

    "Sammy has a red balloon".gsub /[aeiou]/, "@"

    "S@mmy h@s @ r@d b@ll@@n"

The replacement value doesn’t have to be a string. You can use a hash to specify how individual characters or pieces should be replaced. Let’s replace all occurrances of the letter `a` with `@` and all the `o` characters with zeros:

    "Sammy has a red balloon".gsub /[aeiou]/, {"a" => "@", "o" => "0"}
    # "S@mmy h@s @ rd b@ll00n"

You can use this to perform more complex substitutions with less code.

## Conclusion

In this tutorial, you worked with and manipulated strings using some of the built-in methods for the string data type. You also learned that many of the methods for working with strings come in two variants: one that leaves the string unchanged, and one that modifies the original string. Which one you use depends on your needs. Ruby gives you the flexibility to choose how you want to work with your data. However, writing code that doesn’t modify existing data can be easier to debug later.

Be sure to look at these related tutorials to continue exploring how to work with data in Ruby:

- [How To Work with Strings in Ruby](how-to-work-with-strings-in-ruby)
- [How To Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby)
- [Understanding Data Types in Ruby](understanding-data-types-in-ruby)
- [How To Use Array Methods in Ruby](how-to-use-array-methods-in-ruby)
