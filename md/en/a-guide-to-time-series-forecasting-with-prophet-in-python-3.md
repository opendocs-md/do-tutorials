---
author: Thomas Vincent
date: 2017-04-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/a-guide-to-time-series-forecasting-with-prophet-in-python-3
---

# A Guide to Time Series Forecasting with Prophet in Python 3

## Introduction

In previous tutorials, we showed [how to visualize and manipulate time series data](a-guide-to-time-series-visualization-with-python-3), and [how to leverage the ARIMA method to produce forecasts from time series data](a-guide-to-time-series-forecasting-with-arima-in-python-3). We noted how the correct parametrization of ARIMA models could be a complicated manual process that required a certain amount of time.

Other statistical programming languages such a `R` provide [automated ways](https://www.rdocumentation.org/packages/forecast/versions/7.3/topics/auto.arima) to solve this issue, but those have yet to be officially ported over to Python. Fortunately, the Core Data Science team at Facebook recently published a new method called [`Prophet`](https://facebookincubator.github.io/prophet/), which enables data analysts and developers alike to perform forecasting at scale in Python 3.

### Prerequisites

This guide will cover how to do time series analysis on either a local desktop or a remote server. Working with large datasets can be memory intensive, so in either case, the computer will need at least **2GB of memory** to perform some of the calculations in this guide.

For this tutorial, we’ll be using **Jupyter Notebook** to work with the data. If you do not have it already, you should follow our [tutorial to install and set up Jupyter Notebook for Python 3](how-to-set-up-jupyter-notebook-for-python-3).

## Step 1 — Pull Dataset and Install Packages

To set up our environment for time series forecasting with Prophet, let’s first move into our local programming environment or server-based programming environment:

    cd environments

    . my_env/bin/activate

From here, let’s create a new directory for our project. We will call it `timeseries` and then move into the directory. If you call the project a different name, be sure to substitute your name for `timeseries` throughout the guide:

    mkdir timeseries
    cd timeseries

We’ll be working with the Box and Jenkins (1976) [Airline Passengers dataset](https://raw.githubusercontent.com/tlfvincent/do-community-tutorials/master/monthly-airline-passengers.csv), which contains time series data on the monthly number of airline passengers between 1949 and 1960. You can save the data by using the `curl` command with the `-O` flag to write output to a file and download the CSV:

    curl -O https://assets.digitalocean.com/articles/eng_python/prophet/AirPassengers.csv

This tutorial will require the `pandas`, `matplotlib`, `numpy`, `cython` and `fbprophet` libraries. Like most other Python packages, we can install the `pandas`, `numpy`, `cython` and `matplotlib` libraries with pip:

    pip install pandas matplotlib numpy cython

In order to compute its forecasts, the `fbprophet` library relies on the `STAN` programming language, named in honor of the mathematician [Stanislaw Ulam](https://en.wikipedia.org/wiki/Stanislaw_Ulam). Before installing `fbprophet`, we therefore need to make sure that the `pystan` Python wrapper to `STAN` is installed:

    pip install pystan

Once this is done we can install Prophet by using pip:

    pip install fbprophet

Now that we are all set up, we can start working with the installed packages.

## Step 2 — Import Packages and Load Data

To begin working with our data, we will start up Jupyter Notebook:

    jupyter notebook

To create a new notebook file, select **New** \> **Python 3** from the top right pull-down menu:

![Create a new Python 3 notebook](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/JupyterNotebookPy3/jupyter-notebook-new.png)

This will open a notebook which allows us to load the required libraries.

As is best practice, start by importing the libraries you will need at the top of your notebook (notice the standard shorthands used to reference `pandas`, `matplotlib` and `statsmodels`):

    %matplotlib inline
    import pandas as pd
    from fbprophet import Prophet
    
    import matplotlib.pyplot as plt
    plt.style.use('fivethirtyeight')

Notice how we have also defined the fivethirtyeight [`matplotlib` style](https://tonysyu.github.io/raw_content/matplotlib-style-gallery/gallery.html) for our plots.

After each code block in this tutorial, you should type `ALT + ENTER` to run the code and move into a new code block within your notebook.

Let’s start by reading in our time series data. We can load the CSV file and print out the first 5 lines with the following commands:

    df = pd.read_csv('AirPassengers.csv')
    
    df.head(5)

![DataFrame](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-1.png)

Our [DataFrame](an-introduction-to-the-pandas-package-and-its-data-structures-in-python-3#dataframes) clearly contains a `Month` and `AirPassengers` column. The Prophet library expects as input a DataFrame with one column containing the time information, and another column containing the metric that we wish to forecast. Importantly, the time column is expected to be of the `datetime` type, so let’s check the type of our columns:

    df.dtypes

    OutputMonth object
    AirPassengers int64
    dtype: object

Because the `Month` column is not of the `datetime` type, we’ll need to convert it:

    df['Month'] = pd.DatetimeIndex(df['Month'])
    df.dtypes

    OutputMonth datetime64[ns]
    AirPassengers int64
    dtype: object

We now see that our `Month` column is of the correct `datetime` type.

Prophet also imposes the strict condition that the input columns be named `ds` (the time column) and `y` (the metric column), so let’s rename the columns in our DataFrame:

    df = df.rename(columns={'Month': 'ds',
                            'AirPassengers': 'y'})
    
    df.head(5)

![DataFrame](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-2.png)

It is good practice to visualize the data we are going to be working with, so let’s plot our time series:

    ax = df.set_index('ds').plot(figsize=(12, 8))
    ax.set_ylabel('Monthly Number of Airline Passengers')
    ax.set_xlabel('Date')
    
    plt.show()

![Time Series Plot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-3a.png)

With our data now prepared, we are ready to use the Prophet library to produce forecasts of our time series.

## Step 3 — Time Series Forecasting with Prophet

In this section, we will describe how to use the Prophet library to predict future values of our time series. The authors of Prophet have abstracted away many of the inherent complexities of time series forecasting and made it more intuitive for analysts and developers alike to work with time series data.

To begin, we must instantiate a new Prophet object. Prophet enables us to specify a number of arguments. For example, we can specify the desired range of our uncertainty interval by setting the `interval_width` parameter.

    # set the uncertainty interval to 95% (the Prophet default is 80%)
    my_model = Prophet(interval_width=0.95)

Now that our Prophet model has been initialized, we can call its `fit` method with our DataFrame as input. The model fitting should take no longer than a few seconds.

    my_model.fit(df)

You should receive output similar to this:

    Output<fbprophet.forecaster.Prophet at 0x110204080>

In order to obtain forecasts of our time series, we must provide Prophet with a new DataFrame containing a `ds` column that holds the dates for which we want predictions. Conveniently, we do not have to concern ourselves with manually creating this DataFrame, as Prophet provides the `make_future_dataframe` helper function:

    future_dates = my_model.make_future_dataframe(periods=36, freq='MS')
    future_dates.tail()

![DataFrame](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-4.png)

In the code chunk above, we instructed Prophet to generate 36 datestamps in the future.

When working with Prophet, it is important to consider the frequency of our time series. Because we are working with monthly data, we clearly specified the desired frequency of the timestamps (in this case, `MS` is the start of the month). Therefore, the `make_future_dataframe` generated 36 monthly timestamps for us. In other words, we are looking to predict future values of our time series 3 years into the future.

The DataFrame of future dates is then used as input to the `predict` method of our fitted model.

    forecast = my_model.predict(future_dates)
    forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail()

![Predict Model](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-5.png)

Prophet returns a large DataFrame with many interesting columns, but we subset our output to the columns most relevant to forecasting, which are:

- `ds`: the datestamp of the forecasted value
- `yhat`: the forecasted value of our metric (in Statistics, [`yhat`](http://www.chegg.com/homework-help/definitions/predicted-value-y-hat-31) is a notation traditionally used to represent the predicted values of a value `y`)
- `yhat_lower`: the lower bound of our forecasts
- `yhat_upper`: the upper bound of our forecasts

A variation in values from the output presented above is to be expected as Prophet relies on Markov chain Monte Carlo (MCMC) methods to generate its forecasts. MCMC is a stochastic process, so values will be slightly different each time.

Prophet also provides a convenient function to quickly plot the results of our forecasts:

    my_model.plot(forecast,
                  uncertainty=True)

![Forecast Plot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-6.png)

Prophet plots the observed values of our time series (the black dots), the forecasted values (blue line) and the uncertainty intervals of our forecasts (the blue shaded regions).

One other particularly strong feature of Prophet is its ability to return the components of our forecasts. This can help reveal how daily, weekly and yearly patterns of the time series contribute to the overall forecasted values:

    my_model.plot_components(forecast)

![Components of Forecasts Plots](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/prophet/fig-7.png)

The plot above provides interesting insights. The first plot shows that the monthly volume of airline passengers has been linearly increasing over time. The second plot highlights the fact that the weekly count of passengers peaks towards the end of the week and on Saturday, while the third plot shows that the most traffic occurs during the holiday months of July and August.

## Conclusion

In this tutorial, we described how to use the Prophet library to perform time series forecasting in Python. We have been using out-of-the box parameters, but Prophet enables us to specify many more arguments. In particular, Prophet provides the functionality to bring your own knowledge about time series to the table.

Here are a few additional things you could try:

- Assess the effect of holidays by including your prior knowledge on holiday months (for example, we know that the month of December is a holiday month). The official documentation on [modeling holidays](https://facebookincubator.github.io/prophet/docs/holiday_effects.html) will be helpful.
- Change the range of your uncertainty intervals, or forecast further into the future.

For more practice, you could also try to load another time series dataset to produce your own forecasts. Overall, Prophet offers a number of compelling features, including the opportunity to tailor the forecasting model to the requirements of the user.
