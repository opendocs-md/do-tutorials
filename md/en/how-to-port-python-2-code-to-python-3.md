---
author: Lisa Tagliaferri
date: 2017-05-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-port-python-2-code-to-python-3
---

# How To Port Python 2 Code to Python 3

## Introduction

Python was developed in the late 1980s and first published in 1991. With a name inspired by the British comedy group Monty Python, Python was conceived as a successor to the imperative general-purpose ABC programming language. In its first iteration, Python already included exception handling, [functions](how-to-define-functions-in-python-3), and [classes with inheritance](understanding-inheritance-in-python-3).

This tutorial will guide you through best practices and considerations to make when migrating code from Python 2 to Python 3 and whether you should maintain code that is compatible with both versions.

## Background

**Python 2** was published in 2000, signalling a more transparent and inclusive language development process. It included many more programmatic features and added more features throughout its development.

**Python 3** is regarded as the future of Python and is the version of the language that is currently in development. Released in late 2008, Python 3 addressed and amended intrinsic design flaws. However, Python 3 adoption has been slow due to the language not being backwards compatible with Python 2.

**Python 2.7** was published in 2010 as the last of the 2.x releases. The intention behind Python 2.7 was to make it easier for Python 2.x users to port features over to Python 3 by providing some measure of compatibility between the two.

You can learn more about Python versions and choosing which to use by reading our tutorial “[Python 2 vs Python 3: Practical Considerations](python-2-vs-python-3-practical-considerations-2).”

## Start with Python 2.7

To move to Python 3, or to support Python 2 and Python 3 simultaneously, you should ensure that your Python 2 code is completely Python 2.7 compatible.

Many developers have already been working exclusively with Python 2.7 code, but it is important to confirm that anything that is only supported by earlier versions is working properly with Python 2.7 and is consistent with Python 2.7 style.

Making sure that your code is in Python 2.7 is especially important because it is the only version of Python 2 that is still being maintained and receiving bugfixes. If you are working on an earlier version of Python 2, you will have to work around issues you encounter with code that is no longer supported and is no longer receiving buxfixes.

Additionally, some tools that make it easier for you to port code, such as the [Pylint](https://pypi.python.org/pypi/pylint) package that looks for programming errors, is not supported by versions of Python that are earlier than 2.7.

It is important to keep in mind that though Python 2.7 is currently still being supported and maintained, it will eventually meet its end of life. [PEP 373](http://legacy.python.org/dev/peps/pep-0373/) details the Python 2.7 release schedule and, at the time of writing, marks its sunset date as 2020.

## Test Coverage

Creating test cases can be an important part of the work done to migrate Python 2 to Python 3 code. If you are maintaining more than one version of Python, you should also ensure that your test suite has good coverage overall to ensure that each version is still working as expected.

As part of your testing, you can add interactive Python cases to the docstrings of all of your functions, methods, classes, and modules and then use the built-in [`doctest` module](https://docs.python.org/3.6/library/doctest.html) to verify that they work as shown.

Alongside `doctest`, you can use the [`coverage.py` package](https://pypi.python.org/pypi/coverage) to track unit test coverages. This tool will monitor your program and note which parts of the code have been executed and which parts could have been executed but were not. `coverage.py` can print out reports to the command line or provide HTML output. It is typically used to measure the effectiveness of tests, showing you what parts of the code are being exercised by testing and which are not.

Keep in mind that you are not aiming for 100% test coverage — you want to make sure that you cover any code that is confusing or unusual. For best practices, you should aim for 80% coverage.

## Learn About Differences Between Python 2 and Python 3

Learning about the differences between Python 2 and Python 3 will ensure that you are able to leverage the new features that are available, or will be available, in Python 3.

Our guide on “[Python 2 vs Python 3](python-2-vs-python-3-practical-considerations-2)” goes over some of the [key differences](python-2-vs-python-3-practical-considerations-2#key-differences) between the two versions, and you can review the [official Python documentation](https://docs.python.org/3/) for more detail.

When getting started with porting and migration, there are several syntax changes that you can implement now.

### `print`

_The_ `print` _statement of Python 2 has changed to a_ `print()` _function in Python 3._

| Python 2 | Python 3 |
| --- | --- |
| `print "Hello, World!"` | `print("Hello, World!")` |

### `exec`

_The_ `exec` _statement of Python 2 has changed to a function that allows explicit locals and globals in Python 3._

| Python 2 | Python 3 |
| --- | --- |
| `exec code` | `exec(code)` |
| `exec code in globals` | `exec(code, globals)` |
| `exec code in (globals, locals)` | `exec(code, globals, locals)` |

### `/` and `//`

_Python 2 does floor division with the_ `/` _[operator](how-to-do-math-in-python-3-with-operators), Python 3 introduced_ `//` _for floor division._

| Python 2 | Python 3 |
| --- | --- |
| `5 / 2 = 2` | `5 / 2 = 2.5` |
| | `5 // 2 = 2` |

To make use of these operators in Python 2, [import](how-to-import-modules-in-python-3) `division` from the ` __future__ ` module:

    from __future__ import division

_Read more about [division with integers](python-2-vs-python-3-practical-considerations-2#division-with-integers)._

### `raise`

_In Python 3, raising exceptions with arguments requires parentheses, and [strings](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) cannot be used as exceptions._

| Python 2 | Python 3 |
| --- | --- |
| `raise Exception, args` | `raise Exception` |
| | `raise Exception(args)` |
| `raise Exception, args, traceback` | `raise Exception(args).with_traceback(traceback)` |
| `raise "Error"` | `raise Exception("Error")` |

### `except`

_In Python 2 it was difficult to list multiple exceptions, but that has changed in Python 3._

_Note that_ `as` _is used explicitly with_ `except` _in Python 3_

| Python 2 | Python 3 |
| --- | --- |
| `except Exception, variable:` | `except AnException as variable:` |
| | `except (OneException, TwoException) as variable:` |

### `def`

_In Python 2, functions can take in sequences like [tuples](understanding-tuples-in-python-3) or [lists](understanding-lists-in-python-3). In Python 3, this unpacking has been removed._

| Python 2 | Python 3 |
| --- | --- |
| `def function(arg1, (x, y)):` | `def function(arg1, x_y): x, y = x_y` |

### `expr`

_The backtick syntax of Python 2 no longer exists. Use_ `repr()` _or_ `str.format()` _in Python 3._

| Python 2 | Python 3 |
| --- | --- |
| `x = `355/113`` | `x = repr(355/113):` |

### String Formatting

_String formatting syntax has changed from Python 2 to Python 3._

| Python 2 | Python 3 |
| --- | --- |
| `"%d %s" % (i, s)` | `"{} {}".format(i, s)` |
| `"%d/%d=%f" % (355, 113, 355/113)` | `"{:d}/{:d}={:f}".format(355, 113, 355/113)` |

_Learn [How To Use String Formatters in Python 3](how-to-use-string-formatters-in-python-3)._

### `class`

_There is no need to state_ `object` _in Python 3._

**Python 2**

    class MyClass(object):
        pass

**Python 3**

    class MyClass:
        pass

_In Python 3, metaclasses are set with the_ `metaclass` _keyword._

**Python 2**

    class MyClass:
        __metaclass__ = MyMeta

    class MyClass(MyBase):
        __metaclass__ = MyMeta

**Python 3**

    class MyClass(metaclass=type):
        pass

    class MyClass(MyBase, metaclass=MyMeta): 
        pass

## Update Code

There are two main tools you can use to automatically update your code to Python 3 while keeping it compatible with Python 2: **[future](http://python-future.org/automatic_conversion.html)** and **[modernize](https://python-modernize.readthedocs.io/en/latest/)**. Each of these tools behaves somewhat differently: `future` works to make Python 3 idioms and best practices exist in Python 2, while `modernize` aims for a Python 2/3 subset of Python that uses the Python [`six` module](https://pypi.python.org/pypi/six) to improve compatibility.

Using these tools to handle the details of rewriting the code can help you identify and correct potential problems and ambiguities.

You can run the tool over your unittest suite to visually inspect and verify the code, and ensure that the automatic revisions made are accurate. Once the tests pass, you can transform your code.

From here, you will likely need to do some manual revision, especially targeting the [changes between Python 2 and 3 noted in the section above](how-to-port-python-2-to-python-3#learn-about-differences-between-python-2-and-python-3).

Leveraging `future`, you should consider adding this `import` statement to each of your Python 2.7 modules:

    from __future__ import print_function, division, absolute_imports, unicode_literals

While this will also lead to rewrites, it will ensure that your Python 2 code aligns with Python 3 syntax.

Finally, you can use the [`pylint` package](https://pypi.python.org/pypi/pylint) to identify any other potential issues in the code. This package contains hundreds of individual rules that cover a broad spectrum of problems that may occur, including [PEP 8 style guide](https://www.python.org/dev/peps/pep-0008/) rules, as well as usage errors.

You may find that there are some constructs in your code that could potentially confuse `pylint` and tools used for automatic migration. If you can’t simplify these constructs, you’ll need to employ thorough unittest cases.

## Continuous Integration

If you’re going to maintain your code for multiple versions of Python, you’ll need to remain vigilant about running and re-running your unittest suite through continuous integration (rather than manually) as often as possible on the code as you develop it.

If you make use of the [`six` package](https://pypi.python.org/pypi/six) as part of your Python 2 and 3 compatibility maintenance, you’ll need to use multiple environments for your testing.

One environment management tool you may consider using is the [`tox` package](https://pypi.python.org/pypi/tox), as it will check your package installs with different Python versions, run tests in each of your environments, and act as a frontend to Continuous Integration servers.

## Conclusion

It is important to keep in mind that as more developer and community attention focuses on Python 3, the language will become more refined and in-line with the evolving needs of programmers, and less support will be given to Python 2.7. If you decide to maintain versions of your code base for both Python 2 and Python 3, you may have increasing difficulty with the former as it will receive fewer bugfixes over time.

It is worthwhile to look at projects that ported Python 2 to Python 3, including case studies such as [Porting `chardet` to Python 3](http://www.diveintopython3.net/case-study-porting-chardet-to-python-3.html).
