---
author: Lisa Tagliaferri
date: 2017-02-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-the-pandas-package-and-work-with-data-structures-in-python-3
---

# How To Install the pandas Package and Work with Data Structures in Python 3

## Introduction

The Python `pandas` package is used for data manipulation and analysis, designed to let you work with labeled or relational data in a more intuitive way.

Built on the `numpy` package, `pandas` includes labels, descriptive indices, and is particularly robust in handling common data formats and missing data.

The `pandas` package offers spreadsheet functionality but working with data is much faster with Python than it is with a spreadsheet, and `pandas` proves to be very efficient.

In this tutorial, we’ll first install `pandas` and then get you oriented with the fundamental data structures: **Series** and **DataFrames**.

## Installing `pandas`

Like with other Python packages, we can install `pandas` with `pip`.

First, let’s move into our [local programming environment](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04) or [server-based programming environment](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server) of choice and install `pandas` along with its dependencies there:

    pip install pandas numpy python-dateutil pytz

You should receive output similar to the following:

    OutputSuccessfully installed pandas-0.19.2

If you prefer to install `pandas` within [Anaconda](how-to-install-the-anaconda-python-distribution-on-ubuntu-16-04), you can do so with the following command:

    conda install pandas

At this point, you’re all set up to begin working with the `pandas` package.

## Series

In `pandas`, **Series** are one-dimensional arrays that can hold any [data type](understanding-data-types-in-python-3). The axis labels are referred to collectively as the **index**.

Let’s start the Python interpreter in your command line like so:

    python

From within the interpreter, import both the `numpy` and `pandas` packages into your namespace:

    import numpy as np
    import pandas as pd

Before we work with Series, let’s take a look at what it generally looks like:

    s = pd.Series([data], index=[index])

You may notice that the data is structured like a Python [list](understanding-lists-in-python-3).

### Without Declaring an Index

We’ll input integer data and then provide a name parameter for the Series, but we’ll avoid using the `index` parameter to see how `pandas` populates it implicitly:

    s = pd.Series([0, 1, 4, 9, 16, 25], name='Squares')

Now, let’s call the Series so we can see what `pandas` does with it:

    s

We’ll see the following output, with the index in the left column, our data values in the right column. Below the columns is information about the Name of the Series and the data type that makes up the values.

    Output0 0
    1 1
    2 4
    3 9
    4 16
    5 25
    Name: Squares, dtype: int64

Though we did not provide an index for the array, there was one added implicitly of the integer values `0` through `5`.

### Declaring an Index

As the syntax above shows us, we can also make Series with an explicit index. We’ll use data about the average depth in meters of the Earth’s oceans:

    avg_ocean_depth = pd.Series([1205, 3646, 3741, 4080, 3270], index=['Arctic', 'Atlantic', 'Indian', 'Pacific', 'Southern'])

With the Series constructed, let’s call it to see the output:

    avg_ocean_depth

    OutputArctic 1205
    Atlantic 3646
    Indian 3741
    Pacific 4080
    Southern 3270
    dtype: int64

We can see that the index we provided is on the left with the values on the right.

### Indexing and Slicing Series

With `pandas` Series we can index by corresponding number to retrieve values:

    avg_ocean_depth[2]

    Output3741

We can also slice by index number to retrieve values:

    avg_ocean_depth[2:4]

    OutputIndian 3741
    Pacific 4080
    dtype: int64

Additionally, we can call the value of the index to return the value that it corresponds with:

    avg_ocean_depth['Indian']

    Output3741

We can also slice with the values of the index to return the corresponding values:

    avg_ocean_depth['Indian':'Southern']

    OutputIndian 3741
    Pacific 4080
    Southern 3270
    dtype: int64

Notice that in this last example when slicing with index names the two parameters are inclusive rather than exclusive.

Let’s exit the Python interpreter with `quit()`.

### Series Initialized with Dictionaries

With `pandas` we can also use the [dictionary](understanding-dictionaries-in-python-3) data type to initialize a Series. This way, we will not declare an index as a separate list but instead use the built-in keys as the index.

Let’s create a file called `ocean.py` and add the following dictionary with a call to print it.

ocean.py

    import numpy as np
    import pandas as pd
    
    avg_ocean_depth = pd.Series({
                        'Arctic': 1205,
                        'Atlantic': 3646,
                        'Indian': 3741,
                        'Pacific': 4080,
                        'Southern': 3270
    })
    
    print(avg_ocean_depth)
    

Now we can run the file on the command line:

    python ocean.py

We’ll receive the following output:

    OutputArctic 1205
    Atlantic 3646
    Indian 3741
    Pacific 4080
    Southern 3270
    dtype: int64

The Series is displayed in an organized manner, with the index (made up of our keys) to the left, and the set of values to the right.

This will behave like other Python dictionaries in that you can access values by calling the key, which we can do like so:

ocean\_depth.py

    ...
    print(avg_ocean_depth['Indian'])
    print(avg_ocean_depth['Atlantic':'Indian'])

    Output3741
    Atlantic 3646
    Indian 3741
    dtype: int64

However, these Series are now Python objects so you will not be able to use dictionary functions.

Python dictionaries provide another form to set up Series in `pandas`.

## DataFrames

**DataFrames** are 2-dimensional labeled data structures that have columns that may be made up of different data types.

DataFrames are similar to spreadsheets or SQL tables. In general, when you are working with `pandas`, DataFrames will be the most common object you’ll use.

To understand how the `pandas` DataFrame works, let’s set up two Series and then pass those into a DataFrame. The first Series will be our `avg_ocean_depth` Series from before, and our second will be `max_ocean_depth` which contains data of the maximum depth of each ocean on Earth in meters.

ocean.py

    import numpy as np
    import pandas as pd
    
    
    avg_ocean_depth = pd.Series({
                        'Arctic': 1205,
                        'Atlantic': 3646,
                        'Indian': 3741,
                        'Pacific': 4080,
                        'Southern': 3270
    })
    
    max_ocean_depth = pd.Series({
                        'Arctic': 5567,
                        'Atlantic': 8486,
                        'Indian': 7906,
                        'Pacific': 10803,
                        'Southern': 7075
    })

With those two Series set up, let’s add the DataFrame to the bottom of the file, below the `max_ocean_depth` Series. In our example, both of these Series have the same index labels, but if you had Series with different labels then missing values would be labelled `NaN`.

This is constructed in such a way that we can include column labels, which we declare as keys to the Series’ variables. To see what the DataFrame looks like, let’s issue a call to print it.

ocean.py

    ...
    max_ocean_depth = pd.Series({
                        'Arctic': 5567,
                        'Atlantic': 8486,
                        'Indian': 7906,
                        'Pacific': 10803,
                        'Southern': 7075
    })
    
    ocean_depths = pd.DataFrame({
                        'Avg. Depth (m)': avg_ocean_depth,
                        'Max. Depth (m)': max_ocean_depth
    })
    
    print(ocean_depths)
    

    Output Avg. Depth (m) Max. Depth (m)
    Arctic 1205 5567
    Atlantic 3646 8486
    Indian 3741 7906
    Pacific 4080 10803
    Southern 3270 7075

The output shows our two column headings along with the numeric data under each, and the labels from the dictionary keys are on the left.

### Sorting Data in DataFrames

We can [sort the data in the DataFrame](http://pandas.pydata.org/pandas-docs/version/0.18.1/generated/pandas.DataFrame.sort_values.html#pandas.DataFrame.sort_values) by using the `DataFrame.sort_values(by=...)` function.

For example, let’s use the `ascending` Boolean parameter, which can be either `True` or `False`. Note that `ascending` is a parameter we can pass to the function, but descending is not.

ocean\_depth.py

    ...
    print(ocean_depths.sort_values('Avg. Depth (m)', ascending=True))

    Output Avg. Depth (m) Max. Depth (m)
    Arctic 1205 5567
    Southern 3270 7075
    Atlantic 3646 8486
    Indian 3741 7906
    Pacific 4080 10803

Now, the output shows the numbers ascending from low values to high values in the left-most integer column.

### Statistical Analysis with DataFrames

Next, let’s look at [some summary statistics](http://pandas.pydata.org/pandas-docs/version/0.18.1/generated/pandas.DataFrame.describe.html) that we can gather from `pandas` with the `DataFrame.describe()` function.

Without passing particular parameters, the `DataFrame.describe()` function will provide the following information for numeric data types:

| Return | What it means |
| --- | --- |
| `count` | Frequency count; the number of times something occurs |
| `mean` | The mean or average |
| `std` | The standard deviation, a numerical value used to indicate how widely data varies |
| `min` | The minimum or smallest number in the set |
| `25%` | 25th percentile |
| `50%` | 50th percentile |
| `75%` | 75th percentile |
| `max` | The maximum or largest number in the set |

Let’s have Python print out this statistical data for us by calling our `ocean_depths` DataFrame with the `describe()` function:

ocean.py

    ...
    print(ocean_depths.describe())

When we run this program, we’ll receive the following output:

    Output Avg. Depth (m) Max. Depth (m)
    count 5.000000 5.000000
    mean 3188.400000 7967.400000
    std 1145.671113 1928.188347
    min 1205.000000 5567.000000
    25% 3270.000000 7075.000000
    50% 3646.000000 7906.000000
    75% 3741.000000 8486.000000
    max 4080.000000 10803.000000

You can now compare the output here to the original DataFrame and get a better sense of the average and maximum depths of the Earth’s oceans when considered as a group.

### Handling Missing Values

Often when working with data, you will have missing values. The `pandas` package provides many different ways for [working with missing data](http://pandas.pydata.org/pandas-docs/stable/missing_data.html), which refers to `null` data, or data that is not present for some reason. In `pandas`, this is referred to as NA data and is rendered as `NaN`.

We’ll go over [dropping missing values](http://pandas.pydata.org/pandas-docs/stable/missing_data.html#dropping-axis-labels-with-missing-data-dropna) with the `DataFrame.dropna()` function and [filling missing values](http://pandas.pydata.org/pandas-docs/stable/missing_data.html#filling-missing-values-fillna) with the `DataFrame.fillna()` function. This will ensure that you don’t run into issues as you’re getting started.

Let’s make a new file called `user_data.py` and populate it with some data that has missing values and turn it into a DataFrame:

user\_data.py

    import numpy as np
    import pandas as pd
    
    
    user_data = {'first_name': ['Sammy', 'Jesse', np.nan, 'Jamie'],
            'last_name': ['Shark', 'Octopus', np.nan, 'Mantis shrimp'],
            'online': [True, np.nan, False, True],
            'followers': [987, 432, 321, np.nan]}
    
    df = pd.DataFrame(user_data, columns = ['first_name', 'last_name', 'online', 'followers'])
    
    print(df)
    

Our call to print shows us the following output when we run the program:

    Output first_name last_name online followers
    0 Sammy Shark True 987.0
    1 Jesse Octopus NaN 432.0
    2 NaN NaN False 321.0
    3 Jamie Mantis shrimp True NaN

There are quite a few missing values here.

Let’s first drop the missing values with `dropna()`.

user\_data.py

    ...
    df_drop_missing = df.dropna()
    
    print(df_drop_missing)

Since there is only one row that has no values missing whatsoever in our small data set, that is the only row that remains intact when we run the program:

    Output first_name last_name online followers
    0 Sammy Shark True 987.0

As an alternative to dropping the values, we can instead populate the missing values with a value of our choice, such as `0`. This we will achieve with `DataFrame.fillna(0)`.

Delete or comment out the last two lines we added to our file, and add the following:

user\_data.py

    ...
    df_fill = df.fillna(0)
    
    print(df_fill)

When we run the program, we’ll receive the following output:

    Output first_name last_name online followers
    0 Sammy Shark True 987.0
    1 Jesse Octopus 0 432.0
    2 0 0 False 321.0
    3 Jamie Mantis shrimp True 0.0

Now all of our columns and rows are intact, and instead of having `NaN` as our values we now have `0` populating those spaces. You’ll notice that floats are used when appropriate.

At this point, you can sort data, do statistical analysis, and handle missing values in DataFrames.

## Conclusion

This tutorial covered introductory information for data analytics with `pandas` and Python 3. You should now have `pandas` installed, and can work with the Series and DataFrames data structures within `pandas`.
