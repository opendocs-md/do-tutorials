---
author: Lisa Tagliaferri
date: 2017-01-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-tuples-in-python-3
---

# Understanding Tuples in Python 3

## Introduction

A **tuple** in Python looks like this:

    coral = ('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral')

A tuple is a data structure that is an immutable, or unchangeable, ordered sequence of elements. Because tuples are immutable, their values cannot be modified.

Tuples are used for grouping data. Each element or value that is inside of a tuple is called an item.

Tuples have values between parentheses `(` `)` separated by commas `,`. Empty tuples will appear as `coral = ()`, but tuples with even one value must use a comma as in `coral = ('blue coral',)`.

If we `print()` the tuple above, we’ll receive the following output, with the tuple still typed by parentheses:

    print(coral)

    Output('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral')

When thinking about Python tuples and other data structures that are types of collections, it is useful to consider all the different collections you have on your computer: your assortment of files, your song playlists, your browser bookmarks, your emails, the collection of videos you can access on a streaming service, and more.

Tuples are similar to [lists](understanding-lists-in-python-3), but their values can’t be modified. Because of this, when you use tuples in your code, you are conveying to others that you don’t intend for there to be changes to that sequence of values. Additionally, because the values do not change, your code can be optimized through the use of tuples in Python, as the code will be slightly faster for tuples than for lists.

## Indexing Tuples

As an ordered sequence of elements, each item in a tuple can be called individually, through indexing.

Each item corresponds to an index number, which is an integer value, starting with the index number `0`.

For the `coral` tuple, the index breakdown looks like this:

| ‘blue coral’ | 'staghorn coral’ | 'pillar coral’ | 'elkhorn coral’ |
| --- | --- | --- | --- |
| 0 | 1 | 2 | 3 |

The first item, the string `'blue coral'` starts at index `0`, and the list ends at index `4` with the item `'elkhorn coral'`.

Because each item in a Python tuple has a corresponding index number, we’re able to access items.

Now we can call a discrete item of the tuple by referring to its index number:

    print(coral[2])

    Outputpillar coral

The index numbers for this tuple range from `0`-`3`, as shown in the table above. So to call any of the items individually, we would refer to the index numbers like this:

    coral[0] = 'blue coral'
    coral[1] = 'staghorn coral' 
    coral[2] = 'pillar coral' 
    coral[3] = 'elkhorn coral'

If we call the tuple `coral` with an index number of any that is greater than `3`, it will be out of range as it will not be valid:

    print(coral[22])

    OutputIndexError: tuple index out of range

In addition to positive index numbers, we can also access items from the tuple with a negative index number, by counting backwards from the end of the tuple, starting at `-1`. This is especially useful if we have a long tuple and we want to pinpoint an item towards the end of a tuple.

For the same tuple `coral`, the negative index breakdown looks like this:

| 'blue coral’ | 'staghorn coral’ | 'pillar coral’ | 'elkhorn coral’ |
| --- | --- | --- | --- |
| -4 | -3 | -2 | -1 |

So, if we would like to print out the item `'blue coral'` by using its negative index number, we can do so like this:

    print(coral[-4])

    Outputblue coral

We can concatenate string items in a tuple with other strings using the `+` operator:

    print('This reef is made up of ' + coral[1])

    OutputThis reef is made up of staghorn coral

We were able to concatenate the string item at index number `0` with the string `'This reef is made up of '`. We can also use the `+` operator to [concatenate 2 or more tuples together](understanding-tuples-in-python-3#concatenating-and-multiplying-tuples).

With index numbers that correspond to items within a tuple, we’re able to access each item of a tuple discretely.

## Slicing Tuples

We can use indexing to call out a few items from the tuple. Slices allow us to call multiple values by creating a range of index numbers separated by a colon `[x:y]`.

Let’s say we would like to just print the middle items of `coral`, we can do so by creating a slice.

    print(coral[1:3])

    Output('staghorn coral', 'pillar coral')

When creating a slice, as in `[1:3]`, the first index number is where the slice starts (inclusive), and the second index number is where the slice ends (exclusive), which is why in our example above the items at position, `1` and `2` are the items that print out.

If we want to include either end of the list, we can omit one of the numbers in the `tuple[x:y]` syntax. For example, if we want to print the first 3 items of the tuple `coral` — which would be `'blue coral'`, `'staghorn coral'`, `'pillar coral'` — we can do so by typing:

    print(coral[:3])

    Output('blue coral', 'staghorn coral', 'pillar coral')

This printed the beginning of the tuple, stopping right before index `3`.

To include all the items at the end of a tuple, we would reverse the syntax:

    print(coral[1:])

    Output('staghorn coral', 'pillar coral', 'elkhorn coral')

We can also use negative index numbers when slicing tuples, just like with positive index numbers:

    print(coral[-3:-1])
    print(coral[-2:])

    Output('staghorn coral', 'pillar coral')
    ('pillar coral', 'elkhorn coral')

One last parameter that we can use with slicing is called **stride** , which refers to how many items to move forward after the first item is retrieved from the tuple.

So far, we have omitted the stride parameter, and Python defaults to the stride of 1, so that every item between two index numbers is retrieved.

The syntax for this construction is `tuple[x:y:z]`, with `z` referring to stride. Let’s make a larger list, then slice it, and give the stride a value of 2:

    numbers = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
    
    print(numbers[1:11:2])

    Output(1, 3, 5, 7, 9)

Our construction `numbers[1:11:2]` prints the values between index numbers inclusive of `1` and exclusive of `11`, then the stride value of `2` tells the program to print out only every other item.

We can omit the first two parameters and use stride alone as a parameter with the syntax `tuple[::z]`:

    print(numbers[::3])

    Output(0, 3, 6, 9, 12)

By printing out the tuple `numbers` with the stride set to `3`, only every third item is printed:

**0** , 1, 2, **3** , 4, 5, **6** , 7, 8, **9** , 10, 11, **12**

Slicing tuples with both positive and negative index numbers and indicating stride provides us with the control to receive the output we’re trying to achieve.

## Concatenating and Multiplying Tuples

[Operators](how-to-do-math-in-python-3-with-operators) can be used to concatenate or multiply tuples. Concatenation is done with the `+` operator, and multiplication is done with the `*` operator.

The `+` operator can be used to concatenate two or more tuples together. We can assign the values of two existing tuples to a new tuple:

    coral = ('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral')
    kelp = ('wakame', 'alaria', 'deep-sea tangle', 'macrocystis')
    
    coral_kelp = (coral + kelp)
    
    print(coral_kelp)

    Output('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral', 'wakame', 'alaria', 'deep-sea tangle', 'macrocystis')

Because the `+` operator can concatenate, it can be used to combine tuples to form a new tuple, though it cannot modify an existing tuple.

The `*` operator can be used to multiply tuples. Perhaps you need to make copies of all the files in a directory onto a server or share a playlist with friends — in these cases you would need to multiply collections of data.

Let’s multiply the `coral` tuple by 2 and the `kelp` tuple by 3, and assign those to new tuples:

    multiplied_coral = coral * 2
    multiplied_kelp = kelp * 3
    
    print(multiplied_coral)
    print(multiplied_kelp)

    Output('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral', 'blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral')
    ('wakame', 'alaria', 'deep-sea tangle', 'macrocystis', 'wakame', 'alaria', 'deep-sea tangle', 'macrocystis', 'wakame', 'alaria', 'deep-sea tangle', 'macrocystis')

By using the `*` operator we can replicate our tuples by the number of times we specify, creating new tuples based on the original data sequence.

Existing tuples can be concatenated or multiplied to form new tuples through using the `+` and `*` operators.

## Tuple Functions

There are a few built-in functions that you can use to work with tuples. Let’s look at a few of them.

### len()

Like with strings and lists, we can calculate the length of a tuple by using `len()`, where we pass the tuple as a parameter, as in:

    len(coral)

This function is useful for when you need to enforce minimum or maximum collection lengths, for example, or to compare sequenced data.

If we print out the length for our tuples `kelp` and `numbers`, we’ll receive the following output:

    print(len(kelp))
    print(len(numbers))

    Output4
    13

We receive the above output because the tuple `kelp` has 4 items:

    kelp = ('wakame', 'alaria', 'deep-sea tangle', 'macrocystis')

And the tuple `numbers` has 13 items:

    numbers = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)

Although these examples have relatively few items, the `len()` function provides us with the opportunity to see how many items are in large tuples.

### max() and min()

When we work with tuples composed of numeric items, (including [integers](understanding-data-types-in-python-3#integers) and [floats](understanding-data-types-in-python-3#floating-point-numbers)) we can use the `max()` and `min()` functions to find the highest and lowest values contained in the respective tuple.

These functions allow us to find out information about quantitative data, such as test scores, temperatures, prices, etc.

Let’s look at a tuple comprised of floats:

    more_numbers = (11.13, 34.87, 95.59, 82.49, 42.73, 11.12, 95.57)

To get the `max()`, we would pass the tuple into the function, as in `max(more_numbers)`. We’ll combine this with the `print()` function so that we can output our results:

    print(max(more_numbers))

    Output95.59

The `max()` function returned the highest value in our tuple.

Similarly, we can use the `min()` function:

    print(min(more_numbers))

    Output11.12

Here, the smallest float was found in the tuple and printed out.

Just like with the `len()` function, the `max()` and `min()` functions can be very useful when working with tuples that contain many values.

## How Tuples Differ from Lists

The primary way in which tuples are different from lists is that they cannot be modified. This means that items cannot be added to or removed from tuples, and items cannot be replaced within tuples.

You can, however, [concatenate](understanding-tuples-in-python-3#concatenating-and-multiplying-tuples) 2 or more tuples to form a new tuple.

Let’s consider our `coral` tuple:

    coral = ('blue coral', 'staghorn coral', 'pillar coral', 'elkhorn coral')

Say we want to replace the item `'blue coral'` with a different item called `'black coral'`. If we try to change that output the same way we do with a list, by typing:

    coral[0] = 'black coral'

We will receive an error as our output:

    OutputTypeError: 'tuple' object does not support item assignment

This is because tuples cannot be modified.

If we create a tuple and decide what we really need is a list, we can convert it to a list. To convert a tuple to a list, we can do so with `list()`:

    list(coral)

And now, our `coral` data type will be a list:

    coral = ['blue coral', 'staghorn coral', 'pillar coral']

We can see that the tuple was converted to a list because the parentheses changed to square brackets.

Likewise, we can convert lists to tuples with `tuple()`.

You can learn more about data type conversion by reading “[How To Convert Data Types in Python 3](how-to-convert-data-types-in-python-3).”

## Conclusion

The tuple data type is a sequenced [data type](understanding-data-types-in-python-3) that cannot be modified, offering optimization to your programs by being a somewhat faster type than lists for Python to process. When others collaborate with you on your code, your use of tuples will convey to them that you don’t intend for those sequences of values to be modified.

This tutorial covered the basic features of tuples, including indexing, slicing and concatenating tuples, and showing built-in functions that are available.
