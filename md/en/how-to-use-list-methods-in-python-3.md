---
author: Lisa Tagliaferri
date: 2016-11-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-list-methods-in-python-3
---

# How To Use List Methods in Python 3

## Introduction

Python 3 has a number of built-in data structures, including lists. Data structures provide us with a way to organize and store data, and we can use built-in methods to retrieve or manipulate that data.

To get the most out of this tutorial, you should have some familiarity with the list data type, its syntax, and how it is indexed. You can review lists by reading the tutorial [Understanding Lists in Python 3](understanding-lists-in-python-3).

Here, we’ll go through the built-in methods that you can use to work with lists. We’ll add items to and remove items from lists, extend lists, reverse and sort lists, and more.

It is important to keep in mind that lists are mutable — or changeable — data types. Unlike [strings](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3), which are immutable, whenever you use a method on a list you will be affecting the list itself and not a copy of the list.

For this tutorial, we’ll be working primarily with a list comprised of an inventory of various fish that we need to modify as fish are added to or removed from a municipal aquarium.

## list.append()

The method `list.append(x)` will add an item (`x`) to the end of a list. We’ll start with a list of our fish that are dispersed throughout the aquarium.

    fish = ['barracuda','cod','devil ray','eel']

This list is comprised of 4 string items, and their index numbers range from `'barracuda'` at 0 to `'eel'` at index 3.

We just got a new fish into the aquarium today, and we would like to add that fish to our list. We’ll pass the string of our new fish type, `'flounder'` into the `list.append()` method, and then print out our modified list to confirm that the item was added.

    fish.append('flounder')
    print(fish)

    Output['barracuda', 'cod', 'devil ray', 'eel', 'flounder']

Now, we have a list of 5 string items that ends with the item we passed to the `.append()` function.

## list.insert()

The `list.insert(i,x)` method takes two arguments, with `i` being the index position you would like to add an item to, and `x` being the item itself.

Our aquarium acquired another new fish, an anchovy. You may have noticed that so far the list `fish` is in alphabetical order. Because of this, we don’t want to just add the string `'anchovy'` to the end of `fish` with the `list.append()` function. Instead, we’ll use `list.insert()` to add `'anchovy'` to the beginning of this list at index position `0`:

    fish.insert(0,'anchovy')
    print(fish)

    Output['anchovy', 'barracuda', 'cod', 'devil ray', 'eel', 'flounder']

In this case, we added the string item to the front of the list. Each of the successive items will now be at a new index number as they have all moved down. Therefore, `'barracuda'` will be at index 1, `'cod'` will be at index 2, and `'flounder'` — the last item — will be at index 5.

If, at this point, we are bringing a damselfish to the aquarium and we wanted to maintain alphabetical order based on the list above, we would put the item at index `3`: `fish.insert(3,'damselfish')`.

## list.extend()

If we want to combine more than one list, we can use the `list.extend(L)` method, which takes in a second list as its argument.

Our aquarium is welcoming four new fish from another aquarium that is closing. We have these fish together in the list `more_fish`:

    more_fish = ['goby','herring','ide','kissing gourami']

We’ll now add the items from the list `more_fish` to the list `fish` and print the list to ensure that the second list was incorporated:

    fish.extend(more_fish)
    print(fish)

    Output['anchovy', 'barracuda', 'cod', 'devil ray', 'eel', 'flounder', 'goby', 'herring', 'ide', 'kissing gourami']

At this point, the list `fish` is comprised of 10 items.

## list.remove()

When we need to remove an item from a list, we’ll use the `list.remove(x)` method which removes the first item in a list whose value is equivalent to `x`.

A group of local research scientists have come to visit the aquarium. They are doing research on the kissing gourami species of fish. They have requested for us to loan our kissing gourami to them, so we’d like to remove the `'kissing gourami'` item from the list to reflect this change:

    fish.remove('kissing gourami')
    print(fish)

    Output['anchovy', 'barracuda', 'cod', 'devil ray', 'eel', 'flounder', 'goby', 'herring', 'ide']

Following the use of the `list.remove()` method, our list no longer has the `'kissing gourami'` item.

If you pass an item in for `x` in `list.remove()` that does not exist in the list, you’ll receive the following error:

    OutputValueError: list.remove(x): x not in list

Keep in mind that `list.remove()` will only remove the first instance of the item you pass to it, so if we had two kissing gouramis at our aquarium and we only loaned one to the scientists, we could use the same construction of `fish.remove('kissing gourami')` and still have the second kissing gourami on our list.

## list.pop()

We can use the `list.pop([i])` method to return the item at the given index position from the list and then remove that item. The square brackets around the `i` for index tell us that this parameter is optional, so if we don’t specify an index (as in `fish.pop()`), the last item will be returned and removed.

Our devil ray has gotten too large for our aquarium, and thankfully an aquarium a few towns over can accommodate the ray’s needs. We’ll use `.pop()` and specify the index number (`3`) of the string item `'devil ray'` to remove the item from our list, and through returning it we’ll confirm that we are removing the correct item.

    print(fish.pop(3))
    print(fish)

    Outputdevil ray
    ['anchovy', 'barracuda', 'cod', 'eel', 'flounder', 'goby', 'herring', 'ide']

By using the `.pop()` method we were able to return and remove `'devil ray'` from the list `fish`.

If we were to pass no parameters to this method and perform `fish.pop()`, the last item `'ide'` would be returned and then removed from the list.

## list.index()

When lists start to get long, it becomes more difficult for us to count out our items to determine at what index position a certain value is located. We can use `list.index(x)`, where `x` is equivalent to an item value, to return the index in the list where that item is located. If there is more than one item with value `x`, this method will return the first index location.

    print(fish)
    print(fish.index('herring'))

    Output['anchovy', 'barracuda', 'cod', 'eel', 'flounder', 'goby', 'herring', 'ide']
    6

Although the list `fish` is not very long, we’re still able to determine the index position of the item `'herring'` without counting. The index of each item is very important to know so that we are able to manipulate lists effectively.

We’ll receive an error if we specify a value with `.index()` and no such value exists in the given list: `ValueError: 'x' is not in list`.

## list.copy()

When we are working with a list and may want to manipulate it in multiple ways while still having the original list available to us unchanged, we can use `list.copy()` to make a copy of the list.

We’ll pass the value returned from `fish.copy()` to the variable `fish_2`, and then print out the value of `fish_2` to ensure that it is a list with the same items as `fish`.

    fish_2 = fish.copy()
    print(fish_2)

    Output['anchovy', 'barracuda', 'cod', 'eel', 'flounder', 'goby', 'herring', 'ide']

At this point, both `fish` and `fish_2` are equivalent lists.

## list.reverse()

We can reverse the order of items in a list by using the `list.reverse()` method. Perhaps it is more convenient for us to use reverse alphabetical order rather than traditional alphabetical order. In that case, we need to use the `.reverse()` method with the `fish` list to have the list be reversed in place.

    fish.reverse()
    print(fish)

    Output['ide', 'herring', 'goby', 'flounder', 'eel', 'cod', 'barracuda', 'anchovy']

After using the `.reverse()` method, our list begins with the item `'ide'`, which was at the end of our list, and ends with `'anchovy'`, which was at the beginning of the list.

## list.count()

The `list.count(x)` method will return the number of times the value `x` occurs within a specified list. We may want to use this method when we have a long list with a lot of matching values. If we had a larger aquarium, for example, and we had an item for each and every neon tetra that we had, we could use `.count()` to determine the total number of neon tetras we have at any given time.

We’ll use our current list to count the number of times the item `'goby'` appears:

    print(fish.count('goby'))

    Output1

Because the string `'goby'` appears only one time, the number 1 is returned when we use the `.count()` method.

Let’s also use this method with an integer list. Our aquarium is committed to providing great care for each and every fish, so we are keeping track of how old each of our fish are so we can ensure that their diets meet fish’s needs based on their ages. This second list, `fish_ages` corresponds to the type of fish from our other list, `fish`.

Because 1-year-old fish have special dietary needs, we’re going to count how many 1-year-old fish we have:

    fish_ages = [1,2,4,3,2,1,1,2]
    print(fish_ages.count(1))

    Output3

The integer `1` occurs in the list `fish_ages` 3 times, so when we use the `.count()` method, the number 3 is returned.

## list.sort()

We can use the `list.sort()` method to sort the items in a list.

Just like `list.count()`, `list.sort()` can make it more apparent how many of a certain integer value we have, and it can also put an unsorted list of numbers into numeric order.

Let’s use the integer list, `fish_ages` to see the `.sort()` method in action:

    fish_ages.sort()
    print(fish_ages)

    Output[1, 1, 1, 2, 2, 2, 3, 4]

By using `.sort()` with `fish_ages`, the integer values are returned in order. In practice, since these ages correspond to specific fish, you would likely want to make a copy of the original list prior to sorting it.

## list.clear()

When we’re done with a list, we can remove all values contained in it by using the `list.clear()` method.

The local government has decided to take over our aquarium, making it a public space for the people in our city to enjoy. Since we’re no longer working on the aquarium ourselves, we no longer need to keep an inventory of the fish, so let’s clear the `fish` list:

    fish.clear()
    print(fish)

    Output[]

We receive square brackets as our output after using the `.clear()` function on `fish`, letting us know that the list is now clear of all items.

## Conclusion

As a mutable, or changeable, ordered sequence of elements, lists are very flexible data structures in Python. List methods enable us to work with lists in a sophisticated manner. We can combine methods with [other ways to modify lists](understanding-lists-in-python-3) in order to have a full range of tools to use lists effectively in our programs. From here, you can read about [list comprehensions](understanding-list-comprehensions-in-python-3) to create lists based on existing lists.
