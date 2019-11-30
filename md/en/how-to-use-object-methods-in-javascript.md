---
author: Tania Rascia
date: 2018-08-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-object-methods-in-javascript
---

# How To Use Object Methods in JavaScript

## Introduction

[Objects](understanding-objects-in-javascript) in JavaScript are collections of **key** / **value** pairs. The values can consist of **properties** and **methods** , and may contain all other JavaScript data types, such as strings, numbers, and Booleans.

All objects in JavaScript descend from the parent [`Object`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object) constructor. `Object` has many useful built-in methods we can use and access to make working with individual objects straightforward. Unlike [Array prototype methods](how-to-use-array-methods-in-javascript-mutator-methods) like `sort()` and `reverse()` that are used on the array instance, Object methods are used directly on the `Object` constructor, and use the object instance as a parameter. This is known as a static method.

This tutorial will go over important built-in object methods, with each section below dealing with a specific method and providing an example of use.

## Prerequisites

In order to get the most out of this tutorial, you should be familiar with creating, modifying, and working with objects, which you can review in the “[Understanding Objects in JavaScript](understanding-objects-in-javascript)” article.

For additional guidance on JavaScript in general, you can review our _[How To Code in JavaScript](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-javascript)_ series.

## Object.create()

The [`Object.create()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/create) method is used to create a new object and link it to the prototype of an existing object.

We can create a `job` object instance, and extend it to a more specific object.

    // Initialize an object with properties and methods
    const job = {
        position: 'cashier',
        type: 'hourly',
        isAvailable: true,
        showDetails() {
            const accepting = this.isAvailable ? 'is accepting applications' : "is not currently accepting applications";
    
            console.log(`The ${this.position} position is ${this.type} and ${accepting}.`);
        }
    };
    
    // Use Object.create to pass properties
    const barista = Object.create(job);
    
    barista.position = "barista";
    barista.showDetails();

    OutputThe barista position is hourly and is accepting applications.

The `barista` object now has one property — `position` — but all the other properties and methods from `job` are available through the prototype. `Object.create()` is useful for keeping code [DRY](digitalocean-community-glossary#dry-development) by minimizing duplication.

## Object.keys()

[`Object.keys()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys) creates an array containing the keys of an object.

We can create an object and print the array of keys.

    // Initialize an object
    const employees = {
        boss: 'Michael',
        secretary: 'Pam',
        sales: 'Jim',
        accountant: 'Oscar'
    };
    
    // Get the keys of the object
    const keys = Object.keys(employees);
    
    console.log(keys);

    Output["boss", "secretary", "sales", "accountant"]

`Object.keys` can be used to iterate through the keys and values of an object.

    // Iterate through the keys
    Object.keys(employees).forEach(key => {
        let value = employees[key];
    
         console.log(`${key}: ${value}`);
    });

    Outputboss: Michael
    secretary: Pam
    sales: Jim
    accountant: Oscar

`Object.keys` is also useful for checking the length of an object.

    // Get the length of the keys
    const length = Object.keys(employees).length;
    
    console.log(length);

    Output4

Using the `length` property, we were able to count the `4` properties of `employees`.

## Object.values()

[`Object.values()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/values) creates an array containing the values of an object.

    // Initialize an object
    const session = {
        id: 1,
        time: `26-July-2018`,
        device: 'mobile',
        browser: 'Chrome'
    };
    
    // Get all values of the object
    const values = Object.values(session);
    
    console.log(values);

    Output[1, "26-July-2018", "mobile", "Chrome"]

`Object.keys()` and `Object.values()` allow you to return the data from an object.

## Object.entries()

[`Object.entries()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/entries) creates a nested array of the key/value pairs of an object.

    // Initialize an object
    const operatingSystem = {
        name: 'Ubuntu',
        version: 18.04,
        license: 'Open Source'
    };
    
    // Get the object key/value pairs
    const entries = Object.entries(operatingSystem);
    
    console.log(entries);

    Output[
        ["name", "Ubuntu"]
        ["version", 18.04]
        ["license", "Open Source"]
    ]

Once we have the key/value pair arrays, we can use the `forEach()` method to loop through and work with the results.

    // Loop through the results
    entries.forEach(entry => {
        let key = entry[0];
        let value = entry[1];
    
        console.log(`${key}: ${value}`);
    });

    Outputname: Ubuntu
    version: 18.04
    license: Open Source

The `Object.entries()` method will only return the object instance’s own properties, and not any properties that may be inherited through its prototype.

## Object.assign()

[`Object.assign()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign) is used to copy values from one object to another.

We can create two objects, and merge them with `Object.assign()`.

    // Initialize an object
    const name = {
        firstName: 'Philip',
        lastName: 'Fry'
    };
    
    // Initialize another object
    const details = {
        job: 'Delivery Boy',
        employer: 'Planet Express'
    };
    
    // Merge the objects
    const character = Object.assign(name, details);
    
    console.log(character);

    Output{firstName: "Philip", lastName: "Fry", job: "Delivery Boy", employer: "Planet Express"}

It is also possible to use the spread operator (`...`) to accomplish the same task. In the code below, we’ll modify how we declare `character` through merging the `name` and `details` objects.

    // Initialize an object
    const name = {
        firstName: 'Philip',
        lastName: 'Fry'
    };
    
    // Initialize another object
    const details = {
        job: 'Delivery Boy',
        employer: 'Planet Express'
    };
    
    // Merge the object with the spread operator
    const character = {...name, ...details}
    
    console.log(character);

    Output{firstName: "Philip", lastName: "Fry", job: "Delivery Boy", employer: "Planet Express"}

This [spread syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax#Spread_in_object_literals) in object literals is also known as shallow-cloning.

## Object.freeze()

[`Object.freeze()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/freeze) prevents modification to properties and values of an object, and prevents properties from being added or removed from an object.

    // Initialize an object
    const user = {
        username: 'AzureDiamond',
        password: 'hunter2'
    };
    
    // Freeze the object
    const newUser = Object.freeze(user);
    
    newUser.password = ' *******';
    newUser.active = true;
    
    console.log(newUser);

    Output{username: "AzureDiamond", password: "hunter2"}

In the example above, we tried to override the password `hunter2` with ` ******* `, but the `password` property remained the same. We also tried to add a new property, `active`, but it was not added.

`Object.isFrozen()` is available to determine whether an object has been frozen or not, and returns a Boolean.

## Object.seal()

[`Object.seal()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/seal) prevents new properties from being added to an object, but allows the modification of existing properties. This method is similar to `Object.freeze()`. Refresh your console before implementing the code below to avoid an error.

    // Initialize an object
    const user = {
        username: 'AzureDiamond',
        password: 'hunter2'
    };
    
    // Seal the object
    const newUser = Object.seal(user);
    
    newUser.password = ' *******';
    newUser.active = true;
    
    console.log(newUser);

    Output{username: "AzureDiamond", password: " *******"}

The new `active` property was not added to the sealed object, but the `password` property was successfully changed.

## Object.getPrototypeOf()

[`Object.getPrototypeOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getPrototypeOf) is used to get the internal hidden `[[Prototype]]` of an object, also accessible through the ` __proto__ ` property.

In this example, we can create an array, which has access to the `Array` prototype.

    const employees = ['Ron', 'April', 'Andy', 'Leslie'];
    
    Object.getPrototypeOf(employees);

    Output[constructor: ƒ, concat: ƒ, find: ƒ, findIndex: ƒ, pop: ƒ, …]

We can see in the output that the prototype of the `employees` array has access to `pop`, `find`, and other Array prototype methods. We can confirm this by testing the `employees` prototype against `Array.prototype`.

    Object.getPrototypeOf(employees) === Array.prototype;

    Outputtrue

This method can be useful to get more information about an object or ensure it has access to the prototype of another object.

There is also a related [`Object.setPrototypeOf()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/setPrototypeOf) method that will add one prototype to another object. It is recommended that you use `Object.create()` instead as it is faster and more performant.

## Conclusion

Objects have many useful methods that help us modify, protect, and iterate through them. In this tutorial, we reviewed how to create and assign new objects, iterate through the keys and/or values of an object, and freeze or seal an object.

If you need to review JavaScript objects you can read “[Understanding Objects in JavaScript](understanding-objects-in-javascript).” If you would like to familiarize yourself with the prototype chain, you can take a look at “[Understanding Prototypes and Inheritance in JavaScript](understanding-prototypes-and-inheritance-in-javascript).”
