---
author: Lisa Tagliaferri
date: 2017-04-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-apply-polymorphism-to-classes-in-python-3
---

# How To Apply Polymorphism to Classes in Python 3

## Introduction

**Polymorphism** is the ability to leverage the same interface for different underlying forms such as [data types](understanding-data-types-in-python-3) or [classes](how-to-construct-classes-and-define-objects-in-python-3). This permits [functions](how-to-define-functions-in-python-3) to use entities of different types at different times.

For object-oriented programming in Python, this means that a particular object belonging to a particular class can be used in the same way as if it were a different object belonging to a different class.

Polymorphism allows for flexibility and loose coupling so that code can be extended and easily maintained over time.

This tutorial will go through applying polymorphism to classes in Python.

## What Is Polymorphism?

Polymorphism is an important feature of class definition in Python that is utilized when you have commonly named methods across classes or subclasses. This allows functions to use objects of any of these polymorphic classes without needing to be aware of distinctions across the classes.

Polymorphism can be carried out through [inheritance](understanding-inheritance-in-python-3), with subclasses making use of base class methods or overriding them.

Python’s **duck typing** , a special case of dynamic typing, uses techniques characteristic of polymorphism, including [late binding](https://en.wikipedia.org/wiki/Late_binding) and [dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch). The term “duck typing” is derived from a quote of writer James Whitcomb Riley: “When I see a bird that walks like a duck and swims like a duck and quacks like a duck, I call that bird a duck.” Appropriated by Italian computer engineer Alex Martelli in a message to the comp.lang.python newsgroup, the use of duck typing is concerned with establishing the suitability of an object for a specific purpose. When using normal typing this suitability is determined by the type of an object alone, but with duck typing the presence of methods and properties are used to determine suitability rather than the actual type of the object in question. That is to say, you check whether the object quacks like a duck and walks like a duck rather than asking whether the object _is_ a duck.

When several classes or subclasses have the same method names, but different implementations for these same methods, the classes are polymorphic because they are using a single interface to use with entities of different types. A function will be able to evaluate these polymorphic methods without knowing which classes are invoked.

## Creating Polymorphic Classes

To make use of polymorphism, we’re going to create two distinct classes to use with two distinct objects. Each of these distinct classes need to have an interface that is in common so that they can be used polymorphically, so we will give them methods that are distinct but that have the same name.

We’ll create a `Shark` class and a `Clownfish` class, each of which will define methods for `swim()`, `swim_backwards()`, and `skeleton()`.

polymorphic\_fish.py

    class Shark():
        def swim(self):
            print("The shark is swimming.")
    
        def swim_backwards(self):
            print("The shark cannot swim backwards, but can sink backwards.")
    
        def skeleton(self):
            print("The shark's skeleton is made of cartilage.")
    
    
    class Clownfish():
        def swim(self):
            print("The clownfish is swimming.")
    
        def swim_backwards(self):
            print("The clownfish can swim backwards.")
    
        def skeleton(self):
            print("The clownfish's skeleton is made of bone.")

In the code above, both the `Shark` and `Clownfish` class have three methods with the same name in common. However, each of the functionalities of these methods differ for each class.

Let’s instantiate these classes into two objects:

polymorphic\_fish.py

    ...
    sammy = Shark()
    sammy.skeleton()
    
    casey = Clownfish()
    casey.skeleton()

When we run the program with the `python polymorphic_fish.py` command, we can see that each object behaves as expected:

    OutputThe shark's skeleton is made of cartilage.
    The clownfish's skeleton is made of bone.

Now that we have two objects that make use of a common interface, we can use the two objects in the same way regardless of their individual types.

## Polymorphism with Class Methods

To show how Python can use each of these different class types in the same way, we can first create a [`for` loop](how-to-construct-for-loops-in-python-3) that iterates through a [tuple](understanding-tuples-in-python-3) of objects. Then we can call the methods without being concerned about which class type each object is. We will only assume that these methods actually exist in each class.

polymorphic\_fish.py

    ...
    sammy = Shark()
    
    casey = Clownfish()
    
    for fish in (sammy, casey):
        fish.swim()
        fish.swim_backwards()
        fish.skeleton()

We have two objects, `sammy` of the `Shark` class, and `casey` of the `Clownfish` class. Our `for` loop iterates through these objects, calling the `swim()`, `swim_backwards()`, and `skeleton()` methods on each.

When we run the program, the output will be as follows:

    OutputThe shark is swimming.
    The shark cannot swim backwards, but can sink backwards.
    The shark's skeleton is made of cartilage.
    The clownfish is swimming.
    The clownfish can swim backwards.
    The clownfish's skeleton is made of bone.

The `for` loop iterated first through the `sammy` instantiation of the `Shark` class, then the `casey` object of the `Clownfish` class, so we see the methods related to the `Shark` class first, then the `Clownfish` class.

This shows that Python is using these methods in a way without knowing or caring exactly what class type each of these objects is. That is, using these methods in a polymorphic way.

## Polymorphism with a Function

We can also create a function that can take any object, allowing for polymorphism.

Let’s create a function called `in_the_pacific()` which takes in an object we can call `fish`. Though we are using the name `fish`, any instantiated object will be able to be called into this function:

polymorphic\_fish.py

    …
    def in_the_pacific(fish):

Next, we’ll give the function something to do that uses the `fish` object we passed to it. In this case we’ll call the `swim()` methods, each of which is defined in the two classes `Shark` and `Clownfish`:

polymorphic\_fish.py

    ...
    def in_the_pacific(fish):
        fish.swim()

Next, we’ll create instantiations of both the `Shark` and `Clownfish` classes if we don’t have them already. With those, we can call their action using the same `in_the_pacific()` function:

polymorphic\_fish.py

    ...
    def in_the_pacific(fish):
        fish.swim()
    
    sammy = Shark()
    
    casey = Clownfish()
    
    in_the_pacific(sammy)
    in_the_pacific(casey)

When we run the program, the output will be as follows:

    OutputThe shark is swimming.
    The clownfish is swimming.

Even though we passed a random object (`fish`) into the `in_the_pacific()` function when defining it, we were still able to use it effectively for instantiations of the `Shark` and `Clownfish` classes. The `casey` object called the `swim()` method defined in the `Clownfish` class, and the `sammy` object called the `swim()` method defined in the `Shark` class.

## Conclusion

By allowing different objects to leverage functions and methods in similar ways through polymorphism, making use of this Python feature provides greater flexibility and extendability of your object-oriented code.
