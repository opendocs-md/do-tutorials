---
author: Lisa Tagliaferri
date: 2017-01-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/understanding-dictionaries-in-python-3
---

# Understanding Dictionaries in Python 3

## Introduction

The **dictionary** is Python’s built-in **mapping** type. Dictionaries map **keys** to **values** and these key-value pairs provide a useful way to store data in Python.

Typically used to hold data that are related, such as the information contained in an ID or a user profile, dictionaries are constructed with curly braces on either side `{` `}`.

A dictionary looks like this:

    sammy = {'username': 'sammy-shark', 'online': True, 'followers': 987}

In addition to the curly braces, there are also colons (`:`) throughout the dictionary.

The words to the left of the colons are the keys. **Keys** can be made up of any immutable data type. The keys in the dictionary above are:

- `'username'`
- `'online'`
- `'followers'`

Each of the keys in the above example are [string](an-introduction-to-working-with-strings-in-python-3) values.

The words to the right of the colons are the values. **Values** can be comprised of any data type. The values in the dictionary above are:

- `'sammy-shark'`
- `True`
- `987`

Each of these values is either a string, [Boolean](understanding-boolean-logic-in-python-3), or [integer](understanding-data-types-in-python-3#integers).

Let’s print out the dictionary `sammy`:

    print(sammy)

    Output{'username': 'sammy-shark', 'followers': 987, 'online': True}

Looking at the output, the order of the key-value pairs may have shifted. In Python version 3.5 and earlier, the dictionary data type is unordered. However, in Python version 3.6 and later, the dictionary data type remains ordered. Regardless of whether the dictionary is ordered or not, the key-value pairs will remain intact, enabling us to access data based on their relational meaning.

## Accessing Dictionary Elements

We can call the values of a dictionary by referencing the related keys.

### Accessing Data Items with Keys

Because dictionaries offer key-value pairs for storing data, they can be important elements in your Python program.

If we want to isolate Sammy’s username, we can do so by calling `sammy['username']`. Let’s print that out:

    print(sammy['username'])

    Outputsammy-shark

Dictionaries behave like a database in that instead of calling an integer to get a particular index value as you would with a list, you assign a value to a key and can call that key to get its related value.

By invoking the key `'username'` we receive the value of that key, which is `'sammy-shark'`.

The remaining values in the `sammy` dictionary can similarly be called using the same format:

    sammy['followers']
    # Returns 987
    
    sammy['online']
    # Returns True

By making use of dictionaries’ key-value pairs, we can reference keys to retrieve values.

### Using Methods to Access Elements

In addition to using keys to access values, we can also work with some built-in methods:

- `dict.keys()` isolates keys
- `dict.values()` isolates values
- `dict.items()` returns items in a list format of `(key, value)` tuple pairs

To return the keys, we would use the `dict.keys()` method. In our example, that would use the variable name and be `sammy.keys()`. Let’s pass that to a `print()` method and look at the output:

    print(sammy.keys())

    Outputdict_keys(['followers', 'username', 'online'])

We receive output that places the keys within an iterable view object of the `dict_keys` class. The keys are then printed within a list format.

This method can be used to query across dictionaries. For example, we can take a look at the common keys shared between two dictionary data structures:

    sammy = {'username': 'sammy-shark', 'online': True, 'followers': 987}
    jesse = {'username': 'JOctopus', 'online': False, 'points': 723}
    
    for common_key in sammy.keys() & jesse.keys():
        print(sammy[common_key], jesse[common_key])

The dictionary `sammy` and the dictionary `jesse` are each a user profile dictionary.

Their profiles have different keys, however, because Sammy has a social profile with associated followers, and Jesse has a gaming profile with associated points. The 2 keys they have in common are `username` and `online` status, which we can find when we run this small program:

    Outputsammy-shark JOctopus
    True False

We could certainly improve on the program to make the output more user-readable, but this illustrates that `dict.keys()` can be used to check across various dictionaries to see what they share in common or not. This is especially useful for large dictionaries.

Similarly, we can use the `dict.values()` method to query the values in the `sammy` dictionary, which would be constructed as `sammy.values()`. Let’s print those out:

    sammy = {'username': 'sammy-shark', 'online': True, 'followers': 987}
    
    print(sammy.values())

    Outputdict_values([True, 'sammy-shark', 987])

Both the methods `keys()` and `values()` return unsorted lists of the keys and values present in the `sammy` dictionary with the view objects of `dict_keys` and `dict_values` respectively.

If we are interested in all of the items in a dictionary, we can access them with the `items()` method:

    print(sammy.items())

    Outputdict_items([('online', True), ('username', 'sammy-shark'), ('followers', 987)])

The returned format of this is a list made up of `(key, value)` tuple pairs with the `dict_items` view object.

We can iterate over the returned list format with a `for` loop. For example, we can print out each of the keys and values of a given dictionary, and then make it more human-readable by adding a string:

    for key, value in sammy.items():
        print(key, 'is the key for the value', value)

    Outputonline is the key for the value True
    followers is the key for the value 987
    username is the key for the value sammy-shark

The `for` loop above iterated over the items within the `sammy` dictionary and printed out the keys and values line by line, with information to make it easier to understand by humans.

We can use built-in methods to access items, values, and keys from dictionary data structures.

## Modifying Dictionaries

Dictionaries are a mutable data structure, so you are able to modify them. In this section, we’ll go over adding and deleting dictionary elements.

### Adding and Changing Dictionary Elements

Without using a method or function, you can add key-value pairs to dictionaries by using the following syntax:

    dict[key] = value

We’ll look at how this works in practice by adding a key-value pair to a dictionary called `usernames`:

    usernames = {'Sammy': 'sammy-shark', 'Jamie': 'mantisshrimp54'}
    
    usernames['Drew'] = 'squidly'
    
    print(usernames)

    Output{'Drew': 'squidly', 'Sammy': 'sammy-shark', 'Jamie': 'mantisshrimp54'}

We see now that the dictionary has been updated with the `'Drew': 'squidly'` key-value pair. Because dictionaries may be unordered, this pair may occur anywhere in the dictionary output. If we use the `usernames` dictionary later in our program file, it will include the additional key-value pair.

Additionally, this syntax can be used for modifying the value assigned to a key. In this case, we’ll reference an existing key and pass a different value to it.

Let’s consider a dictionary `drew` that is one of the users on a given network. We’ll say that this user got a bump in followers today, so we need to update the integer value passed to the `'followers'` key. We’ll use the `print()` function to check that the dictionary was modified.

    drew = {'username': 'squidly', 'online': True, 'followers': 305}
    
    drew['followers'] = 342
    
    print(drew)

    Output{'username': 'squidly', 'followers': 342, 'online': True}

In the output, we see that the number of followers jumped from the integer value of `305` to `342`.

We can use this method for adding key-value pairs to dictionaries with user-input. Let’s write a quick program, `usernames.py` that runs on the command line and allows input from the user to add more names and associated usernames:

usernames.py

    # Define original dictionary
    usernames = {'Sammy': 'sammy-shark', 'Jamie': 'mantisshrimp54'}
    
    # Set up while loop to iterate
    while True:
    
        # Request user to enter a name
        print('Enter a name:')
    
        # Assign to name variable
        name = input()
    
        # Check whether name is in the dictionary and print feedback
        if name in usernames:
            print(usernames[name] + ' is the username of ' + name)
    
        # If the name is not in the dictionary...
        else:
    
            # Provide feedback        
            print('I don\'t have ' + name + '\'s username, what is it?')
    
            # Take in a new username for the associated name
            username = input()
    
            # Assign username value to name key
            usernames[name] = username
    
            # Print feedback that the data was updated
            print('Data updated.')

Let’s run the program on the command line:

    python usernames.py

When we run the program we’ll get something like the following output:

    OutputEnter a name:
    Sammy
    sammy-shark is the username of Sammy
    Enter a name:
    Jesse
    I don't have Jesse's username, what is it?
    JOctopus
    Data updated.
    Enter a name:

When we are done testing the program, we can press `CTRL + C` to escape the program. You can set up a trigger to quit the program (such as typing the letter `q`) with a [conditional statement](how-to-write-conditional-statements-in-python-3-2) to improve the code.

This shows how you can modify dictionaries interactively. With this particular program, as soon as you exit the program with `CTRL + C` you’ll lose all your data unless you implement a way to [handle reading and writing files](how-to-handle-plain-text-files-in-python-3).

We can also add and modify dictionaries by using the `dict.update()` method. This varies from the `append()` [method](how-to-use-list-methods-in-python-3#listappend()) available in lists.

In the `jesse` dictionary below, let’s add the key `'followers'` and give it an integer value with `jesse.update()`. Following that, let’s `print()` the updated dictionary.

    jesse = {'username': 'JOctopus', 'online': False, 'points': 723}
    
    jesse.update({'followers': 481})
    
    print(jesse)

    Output{'followers': 481, 'username': 'JOctopus', 'points': 723, 'online': False}

From the output, we can see that we successfully added the `'followers': 481` key-value pair to the dictionary `jesse`.

We can also use the `dict.update()` method to modify an existing key-value pair by replacing a given value for a specific key.

Let’s change the online status of Sammy from `True` to `False` in the `sammy` dictionary:

    sammy = {'username': 'sammy-shark', 'online': True, 'followers': 987}
    
    sammy.update({'online': False})
    
    print(sammy)

    Output{'username': 'sammy-shark', 'followers': 987, 'online': False}

The line `sammy.update({'online': False})` references the existing key `'online'` and modifies its Boolean value from `True` to `False`. When we call to `print()` the dictionary, we see the update take place in the output.

To add items to dictionaries or modify values, we can use wither the `dict[key] = value` syntax or the method `dict.update()`.

### Deleting Dictionary Elements

Just as you can add key-value pairs and change values within the dictionary data type, you can also delete items within a dictionary.

To remove a key-value pair from a dictionary, we’ll use the following syntax:

    del dict[key]

Let’s take the `jesse` dictionary that represents one of the users. We’ll say that Jesse is no longer using the online platform for playing games, so we’ll remove the item associated with the `'points'` key. Then, we’ll print the dictionary out to confirm that the item was deleted:

    jesse = {'username': 'JOctopus', 'online': False, 'points': 723, 'followers': 481}
    
    del jesse['points']
    
    print(jesse)

    Output{'online': False, 'username': 'JOctopus', 'followers': 481}

The line `del jesse['points']` removes the key-value pair `'points': 723` from the `jesse` dictionary.

If we would like to clear a dictionary of all of its values, we can do so with the `dict.clear()` method. This will keep a given dictionary in case we need to use it later in the program, but it will no longer contain any items.

Let’s remove all the items within the `jesse` dictionary:

    jesse = {'username': 'JOctopus', 'online': False, 'points': 723, 'followers': 481}
    
    jesse.clear()
    
    print(jesse)

    Output{}

The output shows that we now have an empty dictionary devoid of key-value pairs.

If we no longer need a specific dictionary, we can use `del` to get rid of it entirely:

    del jesse
    
    print(jesse)

When we run a call to `print()` after deleting the `jesse` dictionary, we’ll receive the following error:

    Output...
    NameError: name 'jesse' is not defined

Because dictionaries are mutable data types, they can be added to, modified, and have items removed and cleared.

## Conclusion

This tutorial went through the dictionary data structure in Python. Dictionaries are made up of key-value pairs and provide a way to store data without relying on indexing. This allows us to retrieve values based on their meaning and relation to other data types.

From here, you can learn more about other data types in our “[Understanding Data Types](understanding-data-types-in-python-3)” tutorial.

You can see the dictionary data type used in programming projects such as [web scraping with Scrapy](how-to-crawl-a-web-page-with-scrapy-and-python-3).
