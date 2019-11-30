---
author: Brian Hogan
date: 2017-10-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-arrays-in-ruby
---

# How To Work with Arrays in Ruby

## Introduction

An _array_ is a data structure that represents a list of values, called _elements_. Arrays let you store multiple values in a single variable. This can condense and organize your code, making it more readable and maintainable. And because arrays are objects with their own methods, they can make working with lists of data much easier.

In Ruby. arrays can contain any datatype, including numbers, strings, and other Ruby objects.

Let’s look at a simple example of how powerful arrays can be. Imagine you had to maintain a list of email addresses. Without an array, you might store email addresses in variables, like this:

emails.rb

    
    email1 = "ceo@example.com"
    email2 = "admin@example.com"
    email3 = "support@example.com"
    email4 = "sales@example.com"

This approach is verbose and can quickly become difficult to maintain, as it’s not very flexible. Adding another email address means you’d have to add, and track, an additional variable.

If you use an array, you can simplify this data:

emails.js

    emails = [
      "ceo@example.com",
      "admin@example.com",
      "support@example.com",
      "sales@example.com"
    ]

Instead of creating five separate variables, you now have one variable that contains all four email addresses. In this example, we used square brackets — `[]` — to create an array, and separated each entry with a comma. If you had to add an additional email address, you would add another email address to the array rather than creating and managing a new variable.

To access a specific item, or _element_ of an array, you reference its _index_, or its position in the array. In Ruby, indexes start at zero. so to retrieve the first element from our `emails` array, we append the element’s index to the variable using square brackets, like this:

    print emails[0];

    Outputceo@example.com

In this tutorial, you’ll create arrays, access the values they contain, add, modify, and remove elements in an array, and iterate through the elements in an array to solve more complex problems. Let’s start by looking at how to create arrays in more detail.

## Creating an Array

To create an array in a Ruby program, use square brackets: (`[]`), and separate the values you want to store with commas.

For example, create an array of sharks and assign it to a variable, like this:

sharks.rb

    sharks = ["Hammerhead", "Great White", "Tiger"]

You can print out an entire array with the `print` statment, which will display the array’s contents:

    print sharks

    Output["Hammerhead", "Great White", "Tiger"] 

If you want to create an array where each entry is a single word, you can use the `%w{}` syntax, which creates a _word array_:

    days = %w{Monday Tuesday Wednesday Thursday Friday Saturday Sunday}

This is equivalent to creating the array with square braces:

    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

However, notice that the `%w{}` method lets you skip the quotes and the commas.

Arrays are often used to group together lists of similar data types, but in Ruby, arrays can contain any value or a mix of values, including other arrays. Here’s an example of an array that contains a string, a `nil` value, an integer, and an array of strings:

mixed\_data.rb

    record = [
        "Sammy",
        null,
        7,
        [
            "another",
            "array",
        ]
    ]

Now let’s look at how we access data stored in arrays.

## Accessing Items in Arrays

You access an item in a Ruby array by referring to the _index_ of the item in square brackets.

Let’s explore this concept with our array of sharks, assigned to the variable `sharks`:

sharks.rb

    sharks = ["Hammerhead", "Great White", "Tiger"]

The `sharks` array has three elements. Here is a breakdown of how each element in the `sharks` array is indexed.

| Hammerhead | Greate White | Tiger |
| --- | --- | --- |
| 0 | 1 | 2 |

The first element in the array is `Hammerhead`, which is indexed at `0`. The last element is `Tiger`, which is indexed at `2`. Counting starts with `0` in indices, which goes against our natural intuition to start counting at 1, so you’ll want to keep this in mind until it becomes natural.

**Note** : It might help you to think of the index as an offset; it’s the number of places from the start of the array. The first element is at the beginning, so its offset, or index, is `0`. The second element is one spot away from the first entry in the array, so its offset, or index, is `1`.

You can find out how many elements are in an array with the `length` method.

    sharks.length

    Output3

Although the indices of `sharks` start at `0` and go to `2`, the `length` property returns the number of elements in the array, which is `3`. It’s not concerned with the indices at all.

If you wanted to find out the index number of a specific element in an array, such as `seahorse`, use the `index()` method:

    print sharks.index("Tiger")

    Output2

This returns the index of the first element containing that text. If an index number is not found, such as for a value that does not exist, the console will return `nil`.

    print sharks.index("Whale")

    Outputnil

To get the last element of an array in Ruby, use the index `-1`:

    print sharks[-1]

    Output"Tiger"

Ruby also provides the `first` and `last` methods to get the first and last elements without using indices:

    puts sharks.first
    puts sharks.last

    Output"Hammerhead"
    "Tiger"

Attempting to access an index that doesn’t exist will return `nil`.

    sharks[10]

    Outputnil

Arrays can contain other arrays, which we call _nested arrays_. This is one way to model two-dimentional data sets in a program. Here’s an example of a nested array:

    nested_array = [
        [
            "salmon",
            "halibut",
        ],
        [
            "coral",
            "reef",
        ]
    ]

In order to access elements in a nested array, you would add another index number to correspond to the inner array. For example, to retrive the value `coral` from this nested array, you’d use the following statement:

    print nested_array[1][0];

    Outputcoral

In this example, we accessed the array at position `1` of the `nested_array` variable, which returned the array `["coral", "reef"]`. We then accessed the elements at position `0` of that array, which was `"coral"`.

Now let’s look at how to add elements to an array.

## Adding Elements

We have three elements in our `sharks` array, which are indexed from `0` to `2`:

sharks.rb

    sharks = ["Hammerhead", "Great White", "Tiger"]

There are a few ways to add a new element. You could assign a value to the next index, which in this case would be `3`:

    sharks[3] = "whale";
    
    print sharks

    Output["Hammerhead", "Great White", "Tiger", "Whale"] 

This method is error-prone though. If you add an element and accidentally skip an index, it will create a `nil` element in the array.

    sharks[5] = "Sand";
    
    print sharks;

    Output["Hammerhead", "Great White", "Tiger", "Whale", nil, "Sand"]

Attempting to access the extra array element will return its value, which will be `nil`.

    sharks[4]

    Outputnil

Finding the next available index in an array is error-prone and takes extra time. Avoid errors by using the `push` method, which adds an element to the end of an array:

    sharks.push("thresher")
    print sharks

    Output["Hammerhead", "Great White", "Tiger", "Whale", nil, "Whale", "Thresher"]

You can also use the `<<` syntax instead of the `push` method to add an element to the end of an array:

    sharks << "Bullhead"

    Output["Hammerhead", "Great White", "Tiger", "Whale", nil, "Whale", "Thresher", "Bullhead"]

To add an element to the beginning of an array, use the `unshift()` method:

    sharks.unshift("Angel")
    print sharks

    Output["Angel", "Hammerhead", "Great White", "Tiger", "Whale", nil, "Whale", "Thresher", "Bullhead"]

Now that you know how to add elements, let’s look at removing them.

## Removing Elements

To remove a specific element from an array, use the `delete` or `delete_at` methods. In the `sharks` array, we accidentally created a `nil` array element earlier. Let’s get rid of it.

First, find its position in the array. You can use the `index` method to do that:

    print sharks.index(nil)

    Output4

Then use `delete_at` to remove the element at index `4` and print the array:

    sharks.delete_at(4)
    print sharks

    Output["Angel", "Hammerhead", "Great White", "Tiger", "Whale", "Thresher", "Bullhead"]

The `delete` method removes elements from an array that match the value you pass in. Use it to remove `Whale` from the array:

    sharks.delete("Whale")
    print sharks;

    Output["Angel", "Hammerhead", "Great White", "Tiger", "Thresher", "Bullhead"]

The `delete` method will remove _all_ occurances of the value you pass, so if your array has duplicate elements, they’ll all be removed.

The `pop` method will remove the last element in an array.

    sharks.pop
    print sharks;

    Output["Angel", "Hammerhead", "Great White", "Tiger", "Thresher"]

`Bullhead` has been removed as the last element of the array. In order to remove the first element of the array, use the `shift` method.

    sharks.shift
    print sharks

    Output["Hammerhead", "Great White", "Tiger", "Thresher"]

This time, `Angel` was removed from the beginning of the array.

By using `pop` and `shift`, you can remove elements from the beginning and the end of arrays. Using `pop` is preferred wherever possible, as the rest of the items in the array retain their original index numbers.

The `delete_at`, `pop`, and `shift` methods all change the original array and return the element you deleted. Try this example:

sharks.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    deleted_at_element = sharks.delete_at(1)
    popped_element = sharks.pop
    
    puts "Deleted_at element: #{deleted_at_element}"
    puts "Popped element: #{popped_element}"
    
    puts "Remaining array: #{sharks}"

    OuptutDeleted_at element: Great White
    Popped element: Whale
    Remaining array: ["Hammerhead", "Tiger"]

You now know several ways to remove elements from an array. Now let’s look at how to modify the element we already have.

## Modifying Existing Elements

To update an element in the array, assign a new value to the element’s index by using the assignment operator, just like you would with a regular variable.

Given a new array of sharks, with `"Hammerhead"` at index `0`, let’s replace `"Hammerhead"` with `"Angel"`:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sharks[0] = "Angel"
    print sharks;

    Output["Angel", "Great White", "Tiger", "Whale"]

To make sure you update the right element, you could use the `index` method to locate the element first, just like you did to find the element you wanted to delete.

Now let’s look at how to work with all of the elements in the array.

## Iterating Over an Array

Ruby provides many ways to iterate over an array, and each method you use depends on the kind of work you want to perform. In this article, we’ll explore how to iterate over an array and display each of its elements.

Ruby provides the `for..in` syntax, which looks like this:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    for shark in sharks do
      puts shark
    end

Here’s how it works. For each element in the `sharks` array, Ruby assigns that element to the local variable `shark`. We can then print the element’s value using `puts`.

You won’t see `for..in` very often though. Ruby arrays are objects, and they provide the `each` method for working with elements. The `each` method works in a similar fashion to `for..in`, but has a different syntax:

each.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sharks.each do |shark| 
      puts shark
    end

The `each` method uses a syntax you’ll see often in Ruby programming. It takes a Ruby block as its argument. A _block_ is some code that will be executed later in the context of the method. In this case, the code is `puts shark`. The `shark` keyword, enclosed in the pipe characters (`|`), is the local variable that represents the element in the array that the block will access. Ruby assigns the element to this variable and executes the code in the block. The `each` method repeats this process for each element in the array. The result looks like this:

    OutputHammerhead
    Great White
    Tiger
    Whale

When the block is only a single line, you often see Ruby developers replace the `do` and `end` keywords with curly braces and condense the whole statement into a single line, like this:

each.rb

    ...
    sharks.each {|shark| puts shark }

This produces the same results but uses fewer lines of code.

The `each_with_index` method works in a similar manner, but it also gives you access to the index of the array element. This program uses `each_with_index` to print out the index and the value for each element:

each\_with\_index.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sharks.each_with_index do |shark, index| 
      puts "The index is #{index}"
      puts "The value is #{shark}"
    end

For each element in the array, Ruby assigns the element to the variable `shark`, and assigns the current index to the `index` variable. We can then reference both of those variables in the block.

The result of this program looks like this:

    OutputThe index is 0
    The value is Hammerhead
    The index is 1
    The value is Great White
    The index is 2
    The value is Tiger
    The index is 3
    The value is Whale

You’ll interate over the elements in an array often in your own programs, such as when you need to display the items from a database on a website, or when you’re reading lines from a file and processing their contents.

## Conclusion

Arrays are an extremely versatile and fundamental part of programming in Ruby. In this tutorial, you created arrays and accessed individual elements. You also added, removed, and modified elements in an array. Finally, you explored two ways to iterate over an array and display its contents, which is used as a common method to display data.

Learn about other data types in Ruby by reading the tutorial [Understanding Data Types in Ruby](understanding-data-types-in-ruby).
