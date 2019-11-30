---
author: Shantanu Kulkarni
date: 2014-03-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-regular-expressions
---

# An Introduction To Regular Expressions

## Introduction

As system administrators, developers, QA engineers, support engineers, etc. one needs to find a particular pattern, like a set of IP addresses belonging to certain range or a range of time-stamps or groups of domain or subdomain names, from files. One might also need to find a word spelled in a particular way or find possible typos in a file. This is where regular expressions come in.

Regular expressions are templates to match patterns (or sometimes not to match patterns). They provide a way to describe and parse text. This tutorial will give an insight to regular expressions without going into particularities of any language. We will simply use egrep to explain the concepts.

## Regular Expressions

Regular expressions consists of two types of characters:

- the regular literal characters and

- the metacharacters

These metacharacters are the ones which give the power to the regular expressions.

Consider the following country.txt file where the first column is the country name, the the second column is the population of the country, and the third column is the continent.

    $ cat country.txt
    India,1014003817,Asia
    Italy,57634327,Europe
    Yemen,1184300,Asia
    Argentina,36955182,Latin America
    Brazil,172860370,Latin America
    Cameroon,15421937,Africa
    Japan,126549976,Asia

## Anchor Metacharacters

The first group of “metacharacter” we will discuss are **^** and **$**. **^** and **$** matches the start and end of a pattern respectively and are called _anchor metacharacters_.

To find out the name of all the countries whose country name starts with I, we use the expression:

    $ egrep '^I' country.txt
    India,1014003817,Asia
    Italy,57634327,Europe

or to find out all the countries which have continent names ending with e, we do:

    $ egrep 'e$' country.txt
    Italy,57634327,Europe

The next metacharacter is the dot (.), which matches any _one character_. To match all the lines in which the country name is exactly 5 characters long:

    $ egrep '^.....,' country.txt
    India,1014003817,Asia
    Italy,57634327,Europe
    Yemen,1184300,Asia
    Japan,126549976,Asia

How about finding all lines in which country name starts with either I or J and the country name is 5 characters long?

    $ egrep '^[IJ]....,' country.txt
    India,1014003817,Asia
    Italy,57634327,Europe
    Japan,126549976,Asia

[…] is called as a _character set_ or a _character class_. Inside a character set only one of the given characters is matched.

An ^ inside the character set negates the character set. The following example will match country names five characters long but which do not start with either I or J.

    $ egrep '^[^IJ]....,' country.txt
    Yemen,1184300,Asia

## The Grouping Metacharacter and the Alternation

To match all the line containing Asia or Africa:

    $ egrep 'Asia|Africa' country.txt
    India,1014003817,Asia
    Yemen,1184300,Asia
    Cameroon,15421937,Africa
    Japan,126549976,Asia

This can be also done by taking _A_ and _a_ common.

    $ egrep 'A(si|fric)a' country.txt
    India,1014003817,Asia
    Yemen,1184300,Asia
    Cameroon,15421937,Africa
    Japan,126549976,Asia

## Quantifiers

Instead of writing

    $ egrep '^[IJ]....,' country.txt

we can write

    $ egrep '^[IJ].{4},' country.txt

where {} are called as the _quantifiers_. They determine how many times the character before them should occur.

We can give a range too:

    $ egrep '^[IJ].{4,6},' country.txt
    India,1014003817,Asia
    Italy,57634327,Europe
    Japan,126549976,Asia

This will match country names starting with I or J and having 4 to 6 character after it.

There are some shortcuts available for the quantifiers. For example,

{0,1} is equivalent to ?

    $ egrep '^ab{0,1}c$' filename

is the same as

    $ egrep '^ab?c' filename

{0,} is equivalent to \*

    $ egrep '^ab{0,}c$' filename

is the same as

    $ egrep '^ab*c' filename

{1,} is equivalent to +

    $ egrep '^ab{1,}c$' filename

is the same as

    $ egrep '^ab+c' filename

Let us see some examples involving the expressions we have seen so far. Here instead of searching from a file, we search from standard input. The trick we use is that we know grep (or egrep) searches for a pattern, and if a pattern is found, then the entire line containing the pattern is shown.

We would like to find out all the possible ways to spell the sentence _the grey colour suit was his favourite_.

The expression would be:

    $ egrep 'the gr[ea]y colou?r suit was his favou?rite'
    the grey color suit was his favourite
    the grey color suit was his favourite
    
    the gray colour suit was his favorite
    the gray colour suit was his favorite

Looking at the expression above, we can see that:

- grey can be spelled as grey or gray

- colour can be written as colour or color, that means u is optional so we use u?

- similarly favourite or favorite can be written favou?rite

How about matching a US zip code?

    $ egrep '^[0-9]{5}(-[0-9]{4})?$'
    83456
    83456
    
    83456-
    
    834562
    
    92456-1234
    92456-1234
    
    10344-2342-345

One more example of matching all valid times in a 24 hour clock.

    $ egrep '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]'
    23:44:02
    23:44:02
    
    33:45:11
    
    15:45:33
    15:45:33

In the above example we said that, if the first digit of the hour is either 0 or 1, then the second one will  
be any from 0 to 9. But if the first digit is 2, then the allowed values for second digit are 0,1, 2 or 3.

### Word Boundary

To write a pattern to match the words ending with color such that unicolor, watercolor, multicolor etc.  
is matched but not colorless or colorful. Try these examples yourself, to get familiar with them:

    $ egrep 'color\>'

Next, to match colorless and colorful, but not unicolor, watercolor, multicolor, etc.

    $ egrep '\<color'

Thereby to match the exact word color, we do:

    $ egrep '\<color\>'

## Backreferences

Suppose we want to match all words which were double typed, like _the the_ or _before before_, we have to use backreferences. Backreferences are used for remembering patterns.

Here’s an example:

    $ egrep "\<the\> \1"

Or the generic way:

    $ egrep "\<(.*)\> \1"

The above example can be used to find all names in which the first and the last names are the same. In case there are more than one set of parentheses, then the second, third fourth etc. can be referenced with \2, \3, \4 etc.

_This is just an introduction to the power of regular expressions._

Submitted by: [Shantanu Kulkarni](http://www.zsh.in/)
