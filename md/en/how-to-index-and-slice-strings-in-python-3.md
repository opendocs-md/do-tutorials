---
author: Lisa Tagliaferri
date: 2016-09-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-index-and-slice-strings-in-python-3
---

# How To Index and Slice Strings in Python 3

## Introduction

The Python string data type is a sequence made up of one or more individual characters that could consist of letters, numbers, whitespace characters, or symbols. Because a string is a sequence, it can be accessed in the same ways that other sequence-based data types are, through indexing and slicing.

This tutorial will guide you through accessing strings through indexing, slicing them through their character sequences, and go over some counting and character location methods.

## How Strings are Indexed

Like the [list data type](understanding-lists-in-python-3) that has items that correspond to an index number, each of a string’s characters also correspond to an index number, starting with the index number 0.

For the string `Sammy Shark!` the index breakdown looks like this:

| S | a | m | m | y | | S | h | a | r | k | ! |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |

As you can see, the first `S` starts at index 0, and the string ends at index 11 with the `!` symbol.

We also notice that the whitespace character between `Sammy` and `Shark` also corresponds with its own index number. In this case, the index number associated with the whitespace is 5.

The exclamation point (`!`) also has an index number associated with it. Any other symbol or punctuation mark, such as `*#$&.;?`, is also a character and would be associated with its own index number.

The fact that each character in a Python string has a corresponding index number allows us to access and manipulate strings in the same ways we can with other sequential data types.

## Accessing Characters by Positive Index Number

By referencing index numbers, we can isolate one of the characters in a string. We do this by putting the index numbers in square brackets. Let’s declare a string, print it, and call the index number in square brackets:

    ss = "Sammy Shark!"
    print(ss[4])

    Outputy

When we refer to a particular index number of a string, Python returns the character that is in that position. Since the letter `y` is at index number 4 of the string `ss = "Sammy Shark!"`, when we print `ss[4]` we receive `y` as the output.

Index numbers allow us to access specific characters within a string.

## Accessing Characters by Negative Index Number

If we have a long string and we want to pinpoint an item towards the end, we can also count backwards from the end of the string, starting at the index number `-1`.

For the same string `Sammy Shark!` the negative index breakdown looks like this:

| S | a | m | m | y | | S | h | a | r | k | ! |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| -12 | -11 | -10 | -9 | -8 | -7 | -6 | -5 | -4 | -3 | -2 | -1 |

By using negative index numbers, we can print out the character `r`, by referring to its position at the -3 index, like so:

    print(ss[-3])

    Outputr

Using negative index numbers can be advantageous for isolating a single character towards the end of a long string.

## Slicing Strings

We can also call out a range of characters from the string. Say we would like to just print the word `Shark`. We can do so by creating a **slice** , which is a sequence of characters within an original string. With slices, we can call multiple character values by creating a range of index numbers separated by a colon `[x:y]`:

    print(ss[6:11])

    OutputShark

When constructing a slice, as in `[6:11]`, the first index number is where the slice starts (inclusive), and the second index number is where the slice ends (exclusive), which is why in our example above the range has to be the index number that would occur just after the string ends.

When slicing strings, we are creating a **substring** , which is essentially a string that exists within another string. When we call `ss[6:11]`, we are calling the substring `Shark` that exists within the string `Sammy Shark!`.

If we want to include either end of a string, we can omit one of the numbers in the `string[n:n]` syntax. For example, if we want to print the first word of string `ss` — “Sammy” — we can do so by typing:

    print(ss[:5])

    OutputSammy

We did this by omitting the index number before the colon in the slice syntax, and only including the index number after the colon, which refers to the end of the substring.

To print a substring that starts in the middle of a string and prints to the end, we can do so by including only the index number before the colon, like so:

    print(ss[7:])

    Outputhark!

By including only the index number before the colon and leaving the second index number out of the syntax, the substring will go from the character of the index number called to the end of the string.

You can also use negative index numbers to slice a string. As we went through before, negative index numbers of a string start at -1, and count down from there until we reach the beginning of the string. When using negative index numbers, we’ll start with the lower number first as it occurs earlier in the string.

Let’s use two negative index numbers to slice the string `ss`:

    print(ss[-4:-1])

    Outputark

The substring “ark” is printed from the string “Sammy Shark!” because the character “a” occurs at the -4 index number position, and the character “k” occurs just before the -1 index number position.

## Specifying Stride while Slicing Strings

String slicing can accept a third parameter in addition to two index numbers. The third parameter specifies the **stride** , which refers to how many characters to move forward after the first character is retrieved from the string. So far, we have omitted the stride parameter, and Python defaults to the stride of 1, so that every character between two index numbers is retrieved.

Let’s look again at the example above that prints out the substring “Shark”:

    print(ss[6:11])

    OutputShark

We can obtain the same results by including a third parameter with a stride of 1:

    print(ss[6:11:1])

    OutputShark

So, a stride of 1 will take in every character between two index numbers of a slice. If we omit the stride parameter then Python will default with 1.

If, instead, we increase the stride, we will see that characters are skipped:

    print(ss[0:12:2])

    OutputSmySak

Specifying the stride of 2 as the last parameter in the Python syntax `ss[0:12:2]` skips every other character. Let’s look at the characters that are printed in red:

Sammy Shark!

Note that the whitespace character at index number 5 is also skipped with a stride of 2 specified.

If we use a larger number for our stride parameter, we will have a significantly smaller substring:

    print(ss[0:12:4])

    OutputSya

Specifying the stride of 4 as the last parameter in the Python syntax `ss[0:12:4]` prints only every fourth character. Again, let’s look at the characters that are printed in red:

Sammy Shark!

In this example the whitespace character is skipped as well.

Since we are printing the whole string we can omit the two index numbers and keep the two colons within the syntax to achieve the same result:

    print(ss[::4])

    OutputSya

Omitting the two index numbers and retaining colons will keep the whole string within range, while adding a final parameter for stride will specify the number of characters to skip.

Additionally, you can indicate a negative numeric value for the stride, which we can use to print the original string in reverse order if we set the stride to -1:

    print(ss[::-1])

    Output!krahS ymmaS

The two colons without specified parameter will include all the characters from the original string, a stride of 1 will include every character without skipping, and negating that stride will reverse the order of the characters.

Let’s do this again but with a stride of -2:

    print(ss[::-2])

    Output!rh ma

In this example, `ss[::-2]`, we are dealing with the entirety of the original string as no index numbers are included in the parameters, and reversing the string through the negative stride. Additionally, by having a stride of -2 we are skipping every other letter of the reversed string:

!krahS[whitespace]ymmaS

The whitespace character is printed in this example.

By specifying the third parameter of the Python slice syntax, you are indicating the stride of the substring that you are pulling from the original string.

## Counting Methods

While we are thinking about the relevant index numbers that correspond to characters within strings, it is worth going through some of the methods that count strings or return index numbers. This can be useful for limiting the number of characters we would like to accept within a user-input form, or comparing strings. Like other sequential data types, strings can be counted through several methods.

We’ll first look at the `len()` method which can get the length of any data type that is a sequence, whether ordered or unordered, including strings, lists, [tuples](understanding-tuples-in-python-3), and [dictionaries](understanding-dictionaries-in-python-3).

Let’s print the length of the string `ss`:

    print(len(ss))

    Output12

The length of the string “Sammy Shark!” is 12 characters long, including the whitespace character and the exclamation point symbol.

Instead of using a variable, we can also pass a string right into the `len()` method:

    print(len("Let's print the length of this string."))

    Output38

The `len()` method counts the total number of characters within a string.

If we want to count the number of times either one particular character or a sequence of characters shows up in a string, we can do so with the `str.count()` method. Let’s work with our string `ss = "Sammy Shark!"` and count the number of times the character “a” appears:

    print(ss.count("a"))

    Output2

We can search for another character:

    print(ss.count("s"))

    Output0

Though the letter “S” is in the string, it is important to keep in mind that each character is case-sensitive. If we want to search for all the letters in a string regardless of case, we can use the `str.lower()` method to convert the string to all lower-case first. You can read more about this method in “[An Introduction to String Methods in Python 3](an-introduction-to-string-methods-in-python-3#making-strings-upper-and-lower-case).”

Let’s try `str.count()` with a sequence of characters:

    likes = "Sammy likes to swim in the ocean, likes to spin up servers, and likes to smile."
    print(likes.count("likes"))

    Output3

In the string `likes`, the character sequence that is equivalent to “likes” occurs 3 times in the original string.

We can also find at what position a character or character sequence occurs in a string. We can do this with the `str.find()` method, and it will return the position of the character based on index number.

We can check to see where the first “m” occurs in the string `ss`:

    print(ss.find("m"))

    Ouput2

The first character “m” occurs at the index position of 2 in the string “Sammy Shark!” We can review the index number positions of the string `ss` [above](how-to-index-and-slice-strings-in-python-3#how-strings-are-indexed).

Let’s check to see where the first “likes” character sequence occurs in the string `likes`:

    print(likes.find("likes"))

    Ouput6

The first instance of the character sequence “likes” begins at index number position 6, which is where the character `l` of the sequence `likes` is positioned.

What if we want to see where the second sequence of “likes” begins? We can do that by passing a second parameter to the `str.find()` method that will start at a particular index number. So, instead of starting at the beginning of the string, let’s start after the index number 9:

    print(likes.find("likes", 9))

    Output34

In this second example that begins at the index number of 9, the first occurrence of the character sequence “likes” begins at index number 34.

Additionally, we can specify an end to the range as a third parameter. Like slicing, we can do so by counting backwards using a negative index number:

    print(likes.find("likes", 40, -6))

    Output64

This last example searches for the position of the sequence “likes” between the index numbers of 40 and -6. Since the final parameter entered is a negative number it will be counting from the end of the original string.

The string methods of `len()`, `str.count()`, and `str.find()` can be used to determine length, counts of characters or character sequences, and index positions of characters or character sequences within strings.

## Conclusion

Being able to call specific index numbers of strings, or a particular slice of a string gives us greater flexibility when working with this data type. Because strings, like lists and tuples, are a sequence-based data type, it can be accessed through indexing and slicing.

You can read more about [formatting strings](how-to-format-text-in-python-3) and [string methods](an-introduction-to-string-methods-in-python-3) to continue learning about strings.
