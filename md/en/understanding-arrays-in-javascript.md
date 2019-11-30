---
author: Tania Rascia
date: 2017-07-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-arrays-in-javascript
---

# Understanding Arrays in JavaScript

## Introduction

An **array** in JavaScript is a type of global object that is used to store data. Arrays consist of an ordered collection or list containing zero or more datatypes, and use numbered indices starting from `0` to access specific items.

Arrays are very useful as they store multiple values in a single variable, which can condense and organize our code, making it more readable and maintainable. Arrays can contain any [data type](understanding-data-types-in-javascript), including [numbers](understanding-data-types-in-javascript#numbers), [strings](understanding-data-types-in-javascript#strings), and [objects](understanding-data-types-in-javascript#objects).

To demonstrate how arrays can be useful, consider assigning the five oceans of the world to their own variables.

oceans.js

    // Assign the five oceans to five variables
    const ocean1 = "Pacific";
    const ocean2 = "Atlantic";
    const ocean3 = "Indian";
    const ocean4 = "Arctic";
    const ocean5 = "Antarctic";

This method is very verbose, and can quickly become difficult to maintain and keep track of.

Using arrays, we can simplify our data.

oceans.js

    // Assign the five oceans
    let oceans = [
        "Pacific",
        "Atlantic",
        "Indian",
        "Arctic",
        "Antarctic",
    ];

Instead of creating five separate variables, we now have one variable that contains all five elements. We used square brackets — `[]` — to create an array.

To access a specific item, append its index to the variable.

    // Print out the first item of the oceans array
    oceans[0];

    OutputPacific

In this tutorial, we will learn how to create arrays; how they are indexed; how to add, modify, remove, or access items in an array; and how to loop through arrays.

## Creating an Array

There are two ways to create an array in JavaScript:

- The array literal, which uses square brackets.
- The array constructor, which uses the `new` keyword.

Let’s demonstrate how to create an array of shark species using the array literal, which is initialized with `[]`.

sharks.js

    // Initialize array of shark species with array literal
    let sharks = [
        "Hammerhead",
        "Great White",
        "Tiger",
    ];

Now here is the same data created with the array constructor, which is initialized with `new Array()`.

sharks.js

    // Initialize array of shark species with array constructor
    let sharks = new Array(
        "Hammerhead",
        "Great White",
        "Tiger",
    );

Both methods will create an array. However, the array literal (square brackets) method is much more common and preferred, as the `new Array()` constructor method may have inconsistencies and unexpected results. It’s useful to be aware of the array constructor in case you encounter it down the line.

We can print out an entire array, which will display the same as our input.

    // Print out the entire sharks array
    sharks;

    Output['Hammerhead', 'Great White', 'Tiger']

Arrays are often used to group together lists of similar data types, but they can technically contain any value or a mix of values, including other arrays.

    // Initialize array of mixed datatypes
    let mixedData = [
        "String",
        null,
        7,
        [
            "another",
            "array",
        ],
    ];

After creating an array, we can manipulate them in many ways, but first we must understand how arrays are indexed.

**Note:** You may see the last item in an array with or without a final comma. This is known as a [trailing comma](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Trailing_commas). It is common to see them omitted, but generally it is becomming preferred to include them in your code, as this makes version control diffs more clear, and makes it easier to add and remove items without errors. Note that trailing commas are not allowed in [JSON files](an-introduction-to-json).

## Indexing Arrays

If you’ve learned about [indexing and manipulating strings in JavaScript](how-to-index-split-and-manipulate-strings-in-javascript), you may be familiar with the concept of indexing arrays already, as a string is similar to an array.

Arrays do not have name/value pairs. Instead, they are indexed with integer values beginning with `0`. Here is an example array, assigned to `seaCreatures`.

seacreatures.js

    let seaCreatures = [
        "octopus",
        "squid",
        "shark",
        "seahorse",
        "starfish",
    ];

Here is a breakdown of how each item in the `seaCreatures` array is indexed.

| octopus | squid | shark | seahorse | starfish |
| --- | --- | --- | --- | --- |
| 0 | 1 | 2 | 3 | 4 |

The first item in the array is `octopus`, which is indexed at `0`. The last item is `starfish`, which is indexed at `4`. Counting starts with `0` in indices, which goes against our natural intuition to start counting at 1, so special care must be taken to remember this until it becomes natural.

We can find out how many items are in an array with the `length` property.

    seaCreatures.length;

    Output5

Although the indices of `seaCreatures` consist of `0` to `4`, the `length` property will output the actual amount of items in the array, starting with 1.

If we want to find out the index number of a specific item in an array, such as `seahorse`, we can use the `indexOf()` method.

    seaCreatures.indexOf("seahorse");

    Output3

If an index number is not found, such as for a value that does not exist, the console will return `-1`.

    seaCreatures.indexOf("cuttlefish");

    Output-1

With index numbers that correspond to items within an array, we’re able to access each item discretely in order to work with those items.

## Accessing Items in an Array

An item in a JavaScript array is accessed by referring to the index number of the item in square brackets.

    seaCreatures[1];

    Outputsquid

We know `0` will always output the first item in an array. We can also find the last item in an array by performing an operation on the `length` property and applying that as the new index number.

    const lastIndex = seaCreatures.length - 1;
    
    seaCreatures[lastIndex];

    Outputstarfish

Attempting to access an item that doesn’t exist will return `undefined`.

    seaCreatures[10];

    Outputundefined

In order to access items in a nested array, you would add another index number to correspond to the inner array.

    let nestedArray = [
        [
            "salmon",
            "halibut",
        ],
        [
            "coral",
            "reef",
        ]
    ];
    
    nestedArray[1][0];

    Outputcoral

In the above example, we accessed the array at position `1` of the `nestedArray` variable, then the item at position `0` in the inner array.

## Adding an Item to an Array

In our `seaCreatures` variable we had five items, which consisted of the indices from `0` to `4`. If we want to add a new item to the array, we can assign a value to the next index.

    seaCreatures[5] = "whale";
    
    seaCreatures;

    Output[ 'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale' ]

If we add an item and accidentally skip an index, it will create an undefined item in the array.

    seaCreatures[7] = "pufferfish";
    
    seaCreatures;

    Output[ 'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        ,
        'pufferfish' ]

Attempting to access the extra array item will return `undefined`.

    seaCreatures[6]

    Outputundefined

Issues like that can be avoided by using the `push()` method, which adds an item to the end of an array.

    // Append lobster to the end of the seaCreatures array
    seaCreatures.push("lobster");
    
    seaCreatures;

    Output[ 'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        ,
        'whale',
        'pufferfish',
        'lobster' ]

On the other end of the spectrum, the `unshift()` method will add an item to the beginning of an array.

    // Append dragonfish to the beginning of the seaCreatures array
    seaCreatures.unshift("dragonfish");
    
    seaCreatures;

    Output[ 'dragonfish',
        'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        ,
        'pufferfish',
        'lobster' ]

Between `push()` and `unshift()` you will be able to apend items to the beginning and end of an array.

## Removing an Item from an Array

When we want to remove a specific item from an array, we use the `splice()` method. In the `seaCreatures` array, we accidentally created an undefined array item earlier, so let’s remove that now.

    seaCreatures.splice(7, 1);
    
    seaCreatures;

    Output[ 'dragonfish',
        'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        'pufferfish',
        'lobster' ]

In the `splice()` method, the first parameter stands for the index number to be removed (in this case, `7`), and the second parameter is how many items should be removed. We put `1`, signifying that only one item will be removed.

The `splice()` method will change the original variable. If you would like the original variable to remain unchanged, use `slice()` and assign the result to a new variable.

    let newArray = slice(7, 1);

The `pop()` method will remove the last item in an array.

    // Remove the last item from the seaCreatures array
    seaCreatures.pop();
    
    seaCreatures;

    Output[ 'dragonfish',
        'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        'pufferfish' ]

`lobster` has been removed as the last item of the array. In order to remove the first item of the array, we will use the `shift()` method.

    // Remove the first item from the seaCreatures array
    seaCreatures.shift();
    
    seaCreatures;

    Output[ 'octopus',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        'pufferfish' ]

By using `pop()` and `shift()`, we can remove items from the beginning and the end of arrays. Using `pop()` is preferred wherever possible, as the rest of the items in the array retain their original index numbers.

## Modifying Items in Arrays

We can overwrite any value in an array by assigning a new value using the assignment operator, just like we would with a regular variable.

    // Assign manatee to the first item in the seaCreatures array
    seaCreatures[0] = "manatee";
    
    seaCreatures;

    Output[ 'manatee',
        'squid',
        'shark',
        'seahorse',
        'starfish',
        'whale',
        'pufferfish' ]

Another way to modify a value is using the `splice()` method with a new parameter. If we wanted to change the value of `seahorse`, which is the item at index `3`, we could remove it and add a new item in its place.

    // Replace seahorse with sea lion using splice method
    seaCreatures.splice(3, 1, "sea lion");
    
    seaCreatures();

    Output[ 'manatee',
        'squid',
        'shark',
        'sea lion',
        'starfish',
        'whale',
        'pufferfish' ]

In the above example, we removed `seahorse` from the array, and pushed a new value into index `3`.

## Looping Through an Array

We can loop through the entirety of the array with the `for` keyword, taking advantage of the `length` property. In this example, we can create an array of `shellfish` and print out each index number as well as each value to the console.

    // Create an array of shellfish species
    let shellfish = [
        "oyster",
        "shrimp",
        "clam",
        "mussel",
    ];
    
    // Loop through the length of the array
    for (let i = 0; i < shellfish.length; i++) {
      console.log(i, shellfish[i]);
    }

    Output0 'oyster'
    1 'shrimp'
    2 'clam'
    3 'mussel'

We can also use the `for...of` loop, a newer feature of JavaScript.

    // Create an array of aquatic mammals
    let mammals = [
        "dolphin",
        "whale",
        "manatee",
    ];
    
    // Loop through each mammal
    for (let mammal of mammals) {
        console.log(mammal);
    }

    Outputdolphin
    whale
    manatee

The `for...of` loop does not retrieve the index number of the elements in the array, but it is generally a simpler, more concise way to loop through an array.

Using loops is extremely useful for printing out the whole value of an array, such as when displaying the items from a database on a website.

## Conclusion

Arrays are an extremely versatile and fundamental part of programming in JavaScript. In this tutorial, we learned how to create an array, how arrays are indexed, and some of the most common tasks of working in arrays, such as creating, removing, and modifying items. We also learned two methods of looping through arrays, which is used as a common method to display data.

You can read more about other data types in JavaScript by reading our tutorial “[Understanding Data Types in JavaScript](understanding-data-types-in-javascript).”
