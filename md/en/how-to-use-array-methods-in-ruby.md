---
author: Brian Hogan
date: 2017-10-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-array-methods-in-ruby
---

# How To Use Array Methods in Ruby

## Introduction

[Arrays](how-to-work-with-arrays-in-ruby) let you represent lists of data in your programs. Once you have data in an array, you can sort it, remove duplicates, reverse its order, extract sections of the array, or search through arrays for specific data. You can also convert an array to a [string](how-to-work-with-strings-in-ruby), transform one array of data into another, and roll up an array into a single value.

In this tutorial, you’ll explore some of the most practical methods Ruby provide for working with data stored in arrays.

As you work through this tutorial, you’ll see some methods that end with an exclamation point (`!`). These methods often have side-effects, such as mutating the original value, or raising exceptions. Many methods you’ll use in this tutorial have a related method with this suffix.

You’ll also come across methods that end with a question mark (`?`). These methods return a boolean value.

These are a naming convention used throughout Ruby. It’s not something that’s enforced at the program level; it’s just another way to identify what you can expect from the method.

Let’s start our exploration of array methods by looking at several ways to access elements

## Accessing Elements

If you’ve already followed the tutorial [How To Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby), you know you can access an individual element using its index, which is zero-based, like this:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sharks[0] # "Tiger"
    sharks[1] # "Great White"
    sharks[-1] # "Angel"

You also might recall that you can use the `first` and `last` methods to grab the first and last elements of an array:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sharks.first # "Tiger"
    sharks.last # "Angel"

Finally, when you access an element that doesn’t exist, you will get `nil`. But if you’d like to get an error instead, use the `fetch` method:

    sharks.fetch(42)

    OutputIndexError: index 42 outside of array bounds: -4...4

If you’d rather specify your own default instead of raising an error, you can do that too:

    sharks.fetch(42, "Nope") # "Nope"

Now let’s look at how to get more than one element from an array.

## Retrieving Multiple Elements

There are times you might want to grab a subset of values from your array instead of just a single element.

If you specify a starting index, followed by the number of elements you want, you’ll get a new array containing those values. For example, you can grab the two middle entries from the `sharks` array like this:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sharks[1,2] # ["Great White", "Hammerhead"] 

We start at index `1`, which is `"Great White"`, and we specify we want `2` elements, so we get a new array containing `"Great White"` and `"Hammerhead"`.

You can use the `slice` method to do the same thing:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sharks.slice(1,2) # ["Great White", "Hammerhead"] 

The `slice` method also returns a new array, leaving the original array unaltered. However, if you use the `slice!` method, the original array will be changed as well.

The `take` method lets you grab the specified number of entries from the beginning of an array:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sharks.take(2) # ["Tiger", "Great White"]

Sometimes you want to grab a random value from an array instead of a specific one. Let’s explore how.

## Getting a Random Entry from an Array

You might be working on a game of chance, or maybe you’re writing a program that picks a contest winner. Those kinds of things require some kind of random value. A common solution is to put the possible choices in an array and select a random index.

To get a random element from an array, you could generate a random index between `0` and the last index of the array and use that as an index to retrieve the value, but there’s an easier way: the`sample` method grabs a random entry from an array.

Let’s use it to grab a random answer from an array of stock answers, creating a primitive version of a Magic 8-Ball game:

8ball.rb

    answers = ["Yes", "No", "Maybe", "Ask again later"]
    print answers.sample

    OutputMaybe

The `sample` method also accepts an argument that returns an array of random entries, so if you happen to need more than one random entry, just supply the number you’d like:

random\_sharks.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sample = sharks.sample(2)
    print sample

    Output["Whale", "Great White"]

Let’s look at how to find specific elements in an array next.

## Finding and Filtering Elements

When you’re looking for specific elements in an array, you typically iterate over its elements until you find what you’re looking for. But Ruby arrays provide several methods specifically designed to simplify the process of searching through arrays.

If you just want to see if an element exists, you can use the `include?` method, which returns `true` if the specified data is an element of the array:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sharks.include? "Tiger" # true
    
    ["a", "b", "c"].include? 2 # false

However, `include?` requires an exact match, so you can’t look for a partial word.

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    sharks.include? "Tiger" # true
    sharks.include? "tiger" # false
    sharks.include? "ti" # false

The `find` method locates and returns the first element in the array that matches a condition you specify.

For example, to identify the first entry in the `sharks` array that contains the letter `a`, you could use the `each` method to compare each entry and stop iterating when you find the first one, like this:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    result = nil
    sharks.each do |shark|
      if sharks.include? "a"
        result = shark
        break
      end
    end

Or you could use the `find` method to do the same thing:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    result = sharks.find {|item| item.include?("a")}
    print result

    OutputHammerhead

`find` executes the block you provide for each element in the array. If the last expression in the block evaluates to `true`, the `find` method returns the value and stops iterating. If it doesn’t find anything after iterating through all of the elements, it returns `nil`.

The `select` method works in a similar way, but it constructs a new array containing all of the elements that match the condition, instead of just returning a single value and stopping.

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    results = sharks.select {|item| item.include?("a")}
    print results

    Output["Hammerhead", "Great White", "Whale"]

The `reject` method returns a new array containing elements that _don’t_ match the condition. You can think of it as a filter that removes elements you don’t want. Here’s an example that rejects all entries that contain the letter `a`:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    results = sharks.reject {|item| item.include?("a")}
    print results

    Output["Tiger"]

`select` and `reject` both return a new array, leaving the original array unchanged. However, if you use the `select!` and `reject!` methods, the original array will be modified.

The `find_all` method is an alias for `select`, but there is no `find_all!` method.

Next, let’s look at how to sort the values of an array.

## Sorting an Array

Sorting data is a common practice. You may need to alphabetize a list of names or sort numbers from smallest to largest.

Ruby arrays have a `reverse` method which can reverse the order of the elements in an array. If you have a list of data that’s already organised, `reverse` is a quick way to flip the elements around:

    sharks = ["Angel", "Great White", "Hammerhead", "Tiger"]
    reversed_sharks = sharks.reverse
    print reversed_sharks

    Output["Tiger", "Hammerhead", "Great White", "Angel"]

The `reverse` method returns a new array and doesn’t modify the original. Use the `reverse!` method if you want to change the original array instead.

However, reversing an array isn’t always the most efficent, or practical, way to sort data. Use the `sort` method to sort the elements in an array the way you’d like.

For simple arrays of strings or numbers, the `sort` method is efficient and will give you the results you’re looking for:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sorted_sharks = sharks.sort
    print sorted_sharks

    Output["Angel", "Great White", "Hammerhead", "Tiger"]

However, if you wanted to sort things a different way, you’ll want to tell the `sort` method how to do that. The `sort` method takes a Ruby block that gives you access to elements in the array so you can compare them.

To do the comparison, you use the _comparison operator_ (`<=>`), often referred to as the _spaceship operator_. This operator compares two Ruby objects and returns `-1` if the object on the left is smaller, `0` if the objects are the same, and `1` if the object on the left is bigger.

    1 <=> 2 # -1
    2 <=> 2 # 0
    2 <=> 1 # 1

Ruby’s `sort` method accepts a block that must return `-1`, `0`, or `1`, which it then uses to sort the values in the array.

Here’s an example that explicitly compares the entries in the array to sort in ascending order:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sorted_sharks = sharks.sort{|a,b| a <=> b }
    print sorted_sharks

The `a` and `b` variables represent individual elements in the array that are compared. The result looks like this:

    Output["Angel", "Great White", "Hammerhead", "Tiger"]

To sort the sharks in the reverse order, reverse the objects in the comparison:

    sharks = ["Tiger", "Great White", "Hammerhead", "Angel"]
    sorted_sharks = sharks.sort{|a,b| b <=> a }
    print sorted_sharks

    Output["Tiger", "Hammerhead", "Great White", "Angel"]

The `sort` method is great for arrays containing simple data types like integers, floats, and strings. But when arrays contain more complex objects, you’ll have to do a little more work.

Here’s an array of hashes, with each hash representing a shark:

    sharks = [
      {name: "Hammerhead"},
      {name: "Great white"},
      {name: "Angel"}
    ]

Sorting this with `sort` isn’t as easy. Calling `sort` on the array fails:

    sharks.sort

    OutputArgumentError: comparison of Hash with Hash failed

In order to do the comparison, we have to tell `sort` what we want to compare. So we’ll compare the values of the `:name` key in the hash:

    sorted_sharks.sort{|a, b| a[:name] <=> b[:name]}
    print sorted_sharks

    Output[{:name=>"Angel"}, {:name=>"Great white"}, {:name=>"Hammerhead"}]

When you’re working with more complex structures, you might want to look at the `sort_by` method instead, which uses a more efficient algorithm for sorting. `sort_by` takes a block that only requires one argument, the reference to the current element in the array:

    sharks = [
      {name: "Hammerhead"},
      {name: "Great white"},
      {name: "Angel"}
    ]
    
    sorted_sharks = sharks.sort_by{|shark| shark[:name] }
    print sorted_sharks

    Output[{:name=>"Angel"}, {:name=>"Great white"}, {:name=>"Hammerhead"}]

The `sort_by` method implements a [Schwartzian transform](https://en.wikipedia.org/wiki/Schwartzian_transform), a sorting algorithm best suited for comparing objects based on the value of a specific key. Therefore, you’ll find yourself using `sort_by` whenever comparing collections of objects, as it’s more efficient.

Both `sort` and `sort_by` return new arrays, leaving the original array intact. If you want to modify the original array, use `sort!` and `sort_by!` instead.

In addition to sorting values, you might also want to get rid of duplicates.

## Removing Duplicate Elements

Sometimes you’ll get lists of data that have some duplication. You could iterate through the array and filter out the duplicates, but Ruby’s `uniq` method makes that a lot easier. The `uniq` method returns a new array with all duplicate values removed.

    [1,2,3,4,1,5,3].uniq # [1,2,3,4,5]

Sometimes, when you merge two sets of data, you’ll end up with duplicates. Take these two arrays of sharks:

    sharks = ["Tiger", "Great White"]
    new_sharks = ["Tiger", "Hammerhead"]

If we add them together, we’ll get a duplicate entry:

    sharks + new_sharks
    # ["Tiger", "Great White", "Tiger", "Hammerhead"]

You could use `uniq` to remove the duplicates, but it’s better to avoid introducing them entirely. Instead of adding the arrays together, use the pipe operator`|`, which merges the arrays together:

    sharks | new_sharks
    # ["Tiger", "Great White", "Hammerhead"]

Ruby arrays also support subtraction, which means you could subtract `new_sharks` from `sharks` to get only the new values:

    sharks = ["Tiger", "Great White"]
    new_sharks = ["Tiger", "Hammerhead"]
    sharks - new_sharks # ["Great White"]

Next, let’s look at how to manipulate each element’s value.

## Transforming Data

The `map` method, and its alias `collect`, can transform the contents of array, meaning that it can perform an operation on each element in the array.

For example, you can use `map` to perform arithmetic on each entry in an array, and create a new array containing the new values:

    numbers = [2,4,6,8]
    
    # square each number
    squared_numbers = numbers.map {|number| number * number}
    
    print squared_numbers

The `squared_numbers` variable is an array of the original numbers, squared:

    [4, 16, 36, 64]

`map` is often used in web applications to transform an array into elements for an HTML dropdown list. Here’s a very simplified version of how that might look:

    ]sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    
    options = sharks.map {|shark| "<option>#{shark}</option>"}
    
    print options

The `options` array now has each shark wrapped in the `<option></option>` HTML tag:

    ["<option>Hammerhead</option>", "<option>Great White</option>", "<option>Tiger</option>", "<option>Whale</option>"]

`map` returns a new array, leaving the original array unmodified. Using `map!` would modify the existing array. And remember that `map` has an alias called `collect`. You should be consistent and use one or the other in your code.

Since `map` returns a new array, the array can then be transformed and maniupated further, or even converted to a string. Let’s look at that next.

## Converting an Array to a String

All objects in Ruby have a `to_s` method, which converts the object to a string. This is what the `print` statement uses. Given our array of `sharks`:

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]

Calling the `to_s` method creates this string:

    "[\"Hammerhead\", \"Great White\", \"Tiger\", \"Whale\"]"

That’s great for debugging, but it’s not very useful in a real program.

The `join` method converts an array to a string, but gives you much more control of how you want the elements combined. The `join` method takes an argument that specifies the character you want to use as a separator. To transform the array of sharks into a string of shark names separated by spaces, you’d do something like this:

shark\_join.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    result = sharks.join(" ")
    print result

    OutputHammerhead Great White Tiger Whale

If you wanted each shark name separated by a comma _and_ a space, use a comma and a space as your delimiter:

shark\_join.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    result = sharks.join(", ")
    print result

    OutputHammerhead, Great White, Tiger, Whale

If you don’t specify an argument to the `join` method, you’ll still get a string, but it won’t have any delimiters:

shark\_join.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    result = sharks.join
    print result

    OutputHammerheadGreat WhiteTigerWhale

Using `join` in conjunction with `map` is a quick way to transform an array of data into output. Use `map` to transform each element in the data, then use `join` to transform the whole thing into a string you can print out. Remember our example of transforming our `sharks` array into an array of HTML elements? Here’s that same example again, but this time we’ll use `join` to convert the array of elements into a string with newline characters as the separator:

map.rb

    sharks = ["Hammerhead", "Great White", "Tiger", "Whale"]
    options = sharks.map {|shark| "<option>#{shark}</option>"}
    output = options.join("\n")
    print output

    Output<option>Hammerhead</option>
    <option>Great White</option>
    <option>Tiger</option>
    <option>Whale</option>

Instead of converting an array to a string, you might want to get a total of its contents or perform some other kind of transformation that results in a single value. That’s up next.

## Reducing Arrays to a Single Value

When you’re working with a set of data, you may find that you need to rull the data up into a single value, such as a sum. One way you might do this is by using a variable and the `each` method:

    result = 0
    [1, 2, 3].each {|num| result += num}
    print result

    Output6

You can use the `reduce` method to do this instead. The `reduce` method iterates over an array and keeps a running total by executing a binary operation for each element.

The `reduce` method accepts an initial value for the result, as well as a block with two local values: a reference to the result and a reference to the current element. Inside of the block, you specify the logic to compute the end result.

Since we want to sum up the array, we’ll initialize the result to `0` and then add the current value to the result in the block:

    output = [1,2,3].reduce(0) {|result, current| result += current }
    print output

    Output6

If you plan to initialize the result to `0`, you can omit the argument and just pass the block. This will automatically set the result to the first value in the array:

    output = [1,2,3].reduce {|result, current| result += current }
    print output

    Output6

The `reduce` method also you specify a _binary method_, or a method on one object that accepts another object as its argument, which it will execute for each entry in the array. `reduce` then uses the results to create a single value.

When you write `2 + 2` in Ruby, you’re actually invoking the `+` method on the integer `2`:

    2.+(2) # 4

Ruby uses some _syntactic sugar_ so you can express it as `2 + 2`.

The `reduce` method lets you specify a binary method by passing its name as a symbol. That means you can pass `:+` to the `reduce` method to sum the array:

    output = [1, 2, 3].reduce(:+)   
    print output

    Output6

You can use `reduce` to do more than just add up lists of numbers though. You can use it to transform values. Remember that `reduce` reduces an array to a single value. But there’s no rule that says ther single value can’t be another array.

Let’s say we have a list of values that we need to convert to integers. but we only want the values that can be converted to integers.

We could use `reject` to throw out the non-numeric values, and then use `map` to convert the remaining values to integers. But we can do it all in one step with `reduce`. Here’s how.

Use an empty array as the initialization value. Then, in the block, convert the current value to an Integer with the `Integer` method. If the value can’t be converted to an Integer, `Integer` will raise an exception, which you can catch and assign `nil` to the value.

Then take the value and put it in the array, but only if it’s not `nil`.

Here’s what the code looks like. Try this out:

convert\_array\_of\_values.rb

    values = ["1", "2", "a", "3"]
    integers = values.reduce([]) do |array, current|
      val = Integer(current) rescue nil
      array.push(val) unless val.nil?
      array
    end
    print integers

    Output[1,2,3]

Whenever you have a list of elements that you need to convert to a single value, you might be able to solve it with `reduce`.

## Conclusion

In this tutorial, you used several methods to work with arrays. You grabbed individual elements, retrieved values by searching through the array, sorted elements, and you transformed the data, creating new arrays, strings, and totals. You can apply these concepts to solve many common programming problems with Ruby.

Be sure to look at these related tutorials to continue exploring how to work with data in Ruby:

- [How to Work with Strings in Ruby](how-to-work-with-strings-in-ruby)
- [How To Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby)
- [Understanding Data Types in Ruby](understanding-data-types-in-ruby)
