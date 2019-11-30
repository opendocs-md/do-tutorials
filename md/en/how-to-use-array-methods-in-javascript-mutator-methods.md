---
author: Tania Rascia
date: 2017-08-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-array-methods-in-javascript-mutator-methods
---

# How To Use Array Methods in JavaScript: Mutator Methods

## Introduction

[Arrays](understanding-data-types-in-javascript#arrays) in JavaScript consist of a list of elements. JavaScript has many useful built-in methods to work with arrays. Methods that modify the original array are known as **mutator** methods, and methods that return a new value or representation are known as [**accessor** methods](how-to-use-array-methods-in-javascript-accessor-methods). In this tutorial, we will focus on mutator methods.

In order to get the most out of this tutorial, you should have some familiarity with creating, indexing, modifying, and looping through arrays, which you can review in the tutorial [Understanding Arrays in JavaScript](understanding-arrays-in-javascript).

Arrays are similar to [strings](how-to-index-split-and-manipulate-strings-in-javascript), in that they both consist of a sequence of elements that can be accessed via index number. However, it is important to remember that strings are an immutable datatype, meaning they cannot be changed. Arrays, on the other hand, are mutable, which means that many array methods will affect the original array, not a copy of the array.

This tutorial will go through adding and removing elements, reversing, replacing, and otherwise modifying elements in an array.

**Note:** Array methods are properly written out as `Array.prototype.method()`, as `Array.prototype` refers to the `Array` object itself. For simplicity, we will simply list the name as `method()`.

## isArray()

Before we get into mutator methods, let’s look at the `isArray()` method to test whether objects are arrays. This is a [Boolean](understanding-data-types-in-javascript#booleans) method that returns `true` if the value of a variable is equal to an array. If the object is not an array, this method returns `false`.

    let fish = ["piranha", "barracuda", "koi", "eel"];
    
    // Test if fish variable is an array
    Array.isArray(fish);

    Outputtrue

The `isArray()` method is useful because the `typeof` operator we would normally use for testing returns `object` when used with arrays, and sometimes knowing the distinction between an object and an `Array` object is necessary.

Note that `isArray()` is written differently from most array methods, with the array variable being provided as an argument to the method.

Now that we know how to check to ensure that an object is an array, let’s move on to mutator methods.

## pop()

The first mutator method we’ll look at is the `pop()` method, which removes the last element from the end of an array.

We’ll begin with our `fish` array.

    let fish = ["piranha", "barracuda", "koi", "eel"];

Let’s initialize the `pop()` method in order to remove the last item. In this case, it will be the string literal `"eel"`.

    // Use pop method to remove an item from the end of an array
    fish.pop();

We’ll call our array to ensure that the array is returned without the last item:

    fish;

    Output['piranha', 'barracuda', 'koi']

We’ve successfully removed `"eel"` from the `fish` array. The `pop()` method takes no additional parameters.

## shift()

Another mutator method, the `shift()` method removes the first element from the beginning of an array.

    let fish = ["piranha", "barracuda", "koi", "eel"];

We will use `shift()` to remove `"piranha"` from index `0` and shift all the rest of the elements down by one index number.

    // Use shift method to remove an item from the beginning of an array
    fish.shift();
    
    fish;

    Output['barracuda', 'koi', 'eel']

In this example, `"piranha"` has been removed and each item has shifted down one index number. For this reason, it is generally preferred to use the `pop()` method whenever possible, as the other array elements will maintain their index positions.

## push()

The `push()` mutator method adds a new element or elements to the end of an array.

    let fish = ["piranha", "barracuda", "koi", "eel"];

In order to add an item at the end, we write the new element as a parameter of the function.

    // Use push method to add an item to the end of an array
    fish.push("swordfish");
    
    fish;

    Output['piranha', 'barracuda', 'koi', 'eel', 'swordfish']

It is also possible to add multiple new values to the array. For example, `fish.push("swordfish", "dragonfish")` would have added items to index `4` and `5`.

## unshift()

The `unshift()` mutator array method adds a new element or elements to the beginning of an array.

    let fish = ["piranha", "barracuda", "koi", "eel"];

    // Use unshift method to add an item to the beginning of an array
    fish.unshift("shark");
    
    fish;

    Output['shark', 'piranha', 'barracuda', 'koi', 'eel']

In the above example, `"shark"` was added to index position `0`, shifting all the other array elements by one. Just as with `shift()`, you can add multiple comma-separated items to the array at once.

`pop()` and `push()` affect the end of an array, and `shift()` and `unshift()` affect the beginning of an array. An easy way to remember this is to keep in mind that `shift()` and `unshift()` will change all the index numbers of the returned array

## splice()

The `splice()` method can add or remove an item from any position in an array. A mutator method, `splice()` can either add or remove, or add and remove simultaneously.

`splice()` takes three parameters — the index number to start at, the number of items to remove, and items to add (optional).

    splice(index number, number of items to remove, items to add)

`splice(0, 0, "new")` would add the string `"new"` to the beginning of an array, and delete nothing.

Let’s look at a few examples below at how `splice()` can add and remove items in an array.

### Adding with `splice()`

If we set our second parameter (items to remove) as `0`, `splice()` will delete zero items. In this way, we can choose to only add an item starting at any index number, making `splice()` more powerful than `push()` or `unshift()`, which only add items to the end or beginning of an array.

    let fish = ["piranha", "barracuda", "koi", "eel"];
    
    // Splice a new item number into index position 1
    fish.splice(1, 0, "manta ray");
    
    fish;

    Output['piranha', 'manta ray', 'barracuda', 'koi', 'eel']

The new string, `"manta ray"`, has been added into the array, starting at index `1`.

### Removing with `splice()`

If we leave the third parameter (items to add) blank, we can simply remove an item from any point in the array.

    let fish = ["piranha", "barracuda", "koi", "eel"];
    
    // Remove two items, starting at index position 1
    fish.splice(1, 2);
    
    fish;

    Output['piranha', 'eel']

We deleted two items from the array, starting with index `1`, `"barracuda"`. If the second argument is removed, all items to the end of the array will be removed.

### Adding and Removing with `splice()`

Using all the parameters at once, we can both add and remove items from an array at the same time.

To demonstrate this, let’s remove the same items as we did above, and add a new one in their positions.

    let fish = ["piranha", "barracuda", "koi", "eel"];
    
    // Remove two items and add one
    fish.splice(1, 2, "manta ray");
    
    fish;

    Output['piranha', 'manta ray', 'eel']

`splice()` is a powerful method for modifying any part of an array. Note that `splice()` is not to be confused with `slice()` an accessor array which will make a copy of a section of an array.

## reverse()

The `reverse()` method reverses the order of the elements in an array.

    let fish = ["piranha", "barracuda", "koi", "eel"];

Using `reverse()`, the last element will be first, and the first element will be last.

    // Reverse the fish array
    fish.reverse();
    
    fish;

    Output['eel', 'koi', 'barracuda', 'piranha']

The `reverse()` array method has no parameters.

## fill()

The `fill()` method replaces all the elements in an array with a static value.

    let fish = ["piranha", "barracuda", "koi", "eel"];

In the `fish` array, we have four items. Let’s apply `fill()`.

    // Replace all values in the array with "shark"
    fish.fill("shark");
    
    fish;

    Output['shark', 'shark', 'shark', 'shark']

All four items in the array have been replaced with the same value, `"shark"`. `fill()` also takes optional arguments of start and end points.

    fish.fill("shark", 1) // > ['piranha', 'shark', 'shark', 'shark']
    fish.fill("shark", 1, 3); // > ['piranha', 'shark', 'shark', 'eel']

Using `fill()` we can replace one or more elements in an array with a static value.

## sort()

The `sort()` method sorts the elements in an array based on the first character in the element. In the case that the first character is identical, it will continue down the line and compare the second character, and so on.

By default, `sort()` will alphabetize an array of strings that are all either uppercase or lowercase.

    let fish = ["piranha", "barracuda", "koi", "eel"];
    
    // Sort items in array
    fish.sort();
    
    fish;

    Output['barracuda', 'eel', 'koi', 'piranha']

Since `sort()` is based on the first unicode character, it will sort uppercase items before lowercase.

Let’s modify our original array so that one of our strings begin with an uppercase letter.

    let fish = ["piranha", "barracuda", "Koi", "eel"];
    
    fish.sort();
    
    fish;

    Output['Koi', 'barracuda', 'eel', 'piranha']

Numbers come before both uppercase and lowercase characters.

We can again modify the array to include a number in one of the string items.

    let fish = ["piranha", "barracuda", "Koi", "1 eel"];
    
    fish.sort();

    Output['1 eel', 'Koi', 'barracuda', 'piranha']

`sort()` will not sort an array of numbers by size by default. Instead, it will only check the first character in the number.

    let numbers = [42, 23, 16, 15, 4, 8];
    
    numbers.sort();

    Output[15, 16, 23, 4, 42, 8]

In order to sort numbers properly, you could create a comparison function as an argument.

    // Function to sort numbers by size
    const sortNumerically = (a, b) => {
      return a - b;
    }
    
    numbers.sort(sortNumerically);

    Output[4, 8, 15, 16, 23, 42]

The `sortNumerically` comparison function allowed us to sort as intended. `sort()` will apply the change to the original array.

## Conclusion

In this tutorial, we reviewed the major mutator array methods in JavaScript. Mutator methods modify the original array they are used on, as opposed to creating a copy like accessor methods do. We learned how to add and remove elements to the beginning or end of an array, as well as sorting, reversing, and replacing the value of array items.

To review the basics of arrays, read [Understanding Arrays in JavaScript](understanding-arrays-in-javascript). To see a complete list of all array methods, view the [Array reference on Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array).
