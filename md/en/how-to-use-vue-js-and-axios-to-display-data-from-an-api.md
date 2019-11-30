---
author: rkoli
date: 2018-02-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-vue-js-and-axios-to-display-data-from-an-api
---

# How to Use Vue.js and Axios to Display Data from an API

## Introduction

[Vue.js](https://vuejs.org/v2/guide/#What-is-Vue-js) is a front-end JavaScript framework for building user interfaces. It’s designed from the ground up to be incrementally adoptable, and it integrates well with other libraries or existing projects. This makes it a good fit for small projects as well as sophisticated single-page applications when used with other tooling and libraries.

An API, or Application Programming Interface, is a software intermediary that allows two applications to talk to each other. An API often exposes data that other developers can consume in their own apps, without worrying about databases or differences in programming languages. Developers frequently fetch data from an API that returns data in the JSON format, which they integrate into front-end applications. Vue.js is a great fit for consuming these kinds of APIs.

In this tutorial, you’ll create a Vue application that uses the [Cryptocompare API](https://www.cryptocompare.com/api/) to display the current prices of two leading cryptocurrencies: Bitcoin and Etherium. In addition to Vue, you’ll use the [Axios library](https://github.com/axios/axios/blob/master/README.md) to make API requests and process the obtained results. Axios is a great fit because it automatically transforms JSON data into JavaScript objects, and it supports [Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises), which leads to code that’s easier to read and debug. And to make things look nice, we’ll use the [Foundation](https://foundation.zurb.com/) CSS framework.

**Note** : The Cryptocompare API is licensed for non-commercial use only. See their [licensing terms](https://www.cryptocompare.com/api/#introduction) if you wish to use it in a commercial project.

## Prerequisites

Before you begin this tutorial you’ll need the following:

- A text editor that supports JavaScript syntax highlighting, such as [Atom](http://atom.io), [Visual Studio Code](https://code.visualstudio.com/), or [Sublime Text](https://www.sublimetext.com/). These editors are available on Windows, macOS, and Linux.
- Familiarity with using HTML and JavaScript together. Learn more in [How To Add JavaScript to HTML](how-to-add-javascript-to-html).
- Familiarity with the JSON data format, which you can learn more about in [How to Work with JSON in JavaScript](how-to-work-with-json-in-javascript).
- Familiarity with making requests to APIs. For a comprehensive tutorial on working with APIs, take a look at [How to Use Web APIs in Python3](how-to-use-web-apis-in-python-3). While it’s written for Python, it will still help you understand the core concepts of working with APIs.

## Step 1 — Creating a Basic Vue Application

Let’s create a basic Vue application. We’ll build a single HTML page with some mocked-up data that we will eventually replace with live data from the API. We’ll use Vue.js to display this mocked data. For this first step, we’ll keep all of the code in a single file.

Create a new file called `index.html` using your text editor.

In this file, add the following HTML markup which defines an HTML skeleton and pulls in the Foundation CSS framework and the Vue.js library from content delivery networks (CDNs). By using a CDN, there’s no additional code you need to download to start bulding out your app.

index.html

    <!DOCTYPE html>
    <html lang="en">
    <head>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/foundation/6.3.1/css/foundation.min.css">
      <meta charset="utf-8">
      <title>Cryptocurrency Pricing Application</title>
    </head>
    
      <body>
        <div class="container" id="app">
          <h3 class="text-center">Cryptocurrency Pricing</h3>
          <div class="columns medium-4" >
            <div class="card">
              <div class="card-section">
                <p> BTC in USD </p>
              </div>
              <div class="card-divider">
                <p>{{ BTCinUSD }}</p>
              </div>
            </div>
          </div>
        </div>
    
        <script src="https://unpkg.com/vue"></script>
      </body>
    </html>

The line `{{ BTCinUSD }}` is a placeholder for the data that Vue.js will provide. This is how Vue lets us declaritively render data in the UI. Let’s define that data.

Right below the `<script>` tag that includes Vue, add this code which will create a new Vue application and define a data structure which we’ll display on the page:

index.html

    ...
    
        <script>
          const vm = new Vue({
                  el: '#app',   
                  //Mock data for the value of BTC in USD
                  data: { BTCinUSD: 3759.91}
                });
    
        </script>
    ...

This code creates a new Vue app instance and attaches the instance to the element with the `id` of `app`. Vue calls this process _mounting_ an application. We define a new Vue instance and configure it by passing a configuration [object](understanding-objects-in-javascript). This object contains an [`el`](https://vuejs.org/v2/api/#el) option which specifies the `id` of the element we want to mount this application on, and a [`data`](https://vuejs.org/v2/api/#Options-Data) option which contains the data we want available to the view.

In this example, our data model contains a single key-value pair that holds a mock value for the price of Bitcoin: `{ BTCinUSD: 3759.91}`. This data will be displayed on our HTML page, or our _view_, in the place where we enclosed the key in double curly braces like this:

    <div class="card-divider">
      <p>{{ BTCinUSD }}</p>
    </div>

We’ll eventually replace this hard-coded value with live data from the API.

Open this file in your browser. You’ll see the following output on your screen, which displays the mock data:

![Vue app showing mock data for the bitcoin price in US Dollars](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vuejs_api_cryptocurrency/NyjwbIM.png)

We’re displaying the price in U.S. dollars. To display it in an additional currency, like Euros, we’ll add another key-value pair in our data model and add another column in the markup. First, change the data model:

index.html

      <script>
      const vm = new Vue({
              el: '#app',
              //Mock data for the value of BTC in USD
              data: { BTCinUSD: 3759.91, BTCinEURO:3166.21 }
            });
    
      </script>   

Then add a new section to the markup that displays the price in Euros below the existing code.

index.html

      <div class="container" id="app">
        <h3 class="text-center">Cryptocurrency Pricing</h3>
        <div class="columns medium-4" >
          <div class="card">
            <div class="card-section">
              <p> BTC in USD </p>
            </div>
            <div class="card-divider">
              {{BTCinUSD}}
            </div>
          </div>
        </div>
    
        <div class="columns medium-4" >
          <div class="card">
            <div class="card-section">
              <p> BTC in EURO </p>
            </div>
            <div class="card-divider">
              {{BTCinEURO}}
            </div>
          </div>
        </div>
    
      </div>

Now save the file and reload it in your browser. The app now displays the price of Bitcoin both in Euros as well as in US Dollars.

![Vue app with mock price of Bitcoin in both USD and Euros](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vuejs_api_cryptocurrency/jTDUE3m.png)

We’ve done all the work in a single file. Let’s split things out to improve maintainability.

## Step 2 — Separating JavaScript and HTML for Clarity

To learn how things work, we placed all of the code in a single file. Now let’s separate the application code into two separate files, `index.html` and `vueApp.js`. The `index.html` file will handle the markup part, and the JavaScript file will contain the application logic. This will make our app more maintainable. We’ll keep both files in the same directory.

First, modify the `index.html` file and remove the JavaScript code, replacing it with a link to the `vueApp.js` file.

Locate this section of the file:

index.html

    ...
        <script src="https://unpkg.com/vue"></script>
        <script language="JavaScript">
        const vm = new Vue({
                el: '#app',
                // Mock data for the value of BTC in USD
                data: { BTCinUSD: 3759.91, BTCinEURO:3166.21 }
              });
        </script>
    ...

And modify it so it looks like this:

index.html

    ...
        <script src="https://unpkg.com/vue"></script>
        <script src="vueApp.js"></script>
    ...

Then create the `vueApp.js` file in the same directory as the `index.html` file.

In this new file, place the same JavaScript code that was originally in the `index.html` file, without the `<script>` tags:

vueApp.js

    const vm = new Vue({
            el: '#app',
            // Mock data for the value of BTC in USD
            data: { BTCinUSD: 3759.91, BTCinEURO:3166.21 }
          });

Save the file and reload the `index.html` in the browser. You will see the same result you saw previously.

We want to support more cryptocurrencies than just Bitcoiin, so let’s look at how we do that.

## Step 3 — Using Vue to Iterate Over Data

We’re currently showing some mock data for the price of Bitcoin. But let’s add Etherium too. To do this, we’ll restructure our data and modify the view to work with the new data.

Open the `vueApp.js` file and modify the data model so it looks like this:

vueApp.js

    const vm = new Vue({
            el: '#app',
            data: {
              results: {"BTC": {"USD":3759.91,"EUR":3166.21}, 
                        "ETH": {"USD":281.7,"EUR":236.25}}
            }
          });

Our data model has become a little more complex with a nested data structure. We now have a key called `results` which contains two records; one for Bitcoin prices and another for Etherium prices. This new structure will let us reduce some duplication in our view. It also resembles the data we’ll get from the cryptocompare API.

Save the file. Now let’s modify our markup to process the data in a more programmatic way.

Open the `index.html` file and locate this section of the file where we display the price of Bitcoin:

index.html

    ...
        <div class="columns medium-4" >
          <div class="card">
            <div class="card-section">
              <p> BTC in USD </p>
            </div>
            <div class="card-divider">
              {{BTCinUSD}}
            </div>
          </div>
        </div>
    
        <div class="columns medium-4" >
          <div class="card">
            <div class="card-section">
              <p> BTC in EURO </p>
            </div>
            <div class="card-divider">
              {{BTCinEURO}}
            </div>
          </div>
        </div>
    
      </div>
    ...

Replace it with this code which iterates over the dataset you defined.

index.html

    ...
      <div class="columns medium-4" v-for="(result, index) in results">
        <div class="card">
          <div class="card-section">
            <p> {{ index }} </p>
          </div>
          <div class="card-divider">
            <p>$ {{ result.USD }}</p>
          </div>
          <div class="card-section">
            <p> &#8364 {{ result.EUR }}</p>
          </div>
        </div>
      </div>
    ...

This code uses the [`v-for`](https://vuejs.org/v2/api/#v-for) directive which acts like a for-loop. It iterates over all the key-value pairs in our data model and displays the data for each one.

When you reload this in the browser, you’ll see the mocked prices:

![Vue app with Bitcoin and Ethereum mock price](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vuejs_api_cryptocurrency/PMg24or.png)

This modification lets us add a new currency to the `results` data in `vueApp.js` and have it display on the page without futher changes. Add another mocked entry to the dataset to try this out:

vueApp.js

    const vm = new Vue({
            el: '#app',
            data: {
              results: {"BTC":{"USD":3759.91,"EUR":3166.21},
                        "ETH":{"USD":281.7,"EUR":236.25},
                        "NEW Currency":{"USD":5.60,"EUR":4.70}}
            }
          });

Don’t forget to add the trailing comma after the Etherium entry.

If you now load the page in the web browser, you will see the new entry displayed:

![Vue app with Bitcoin, Ethereum and hypothetical currency mock price](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/vuejs_api_cryptocurrency/lYEvm4r.png)

Once we tackle the data programmatically, we don’t need to add new columns in the markup manually.

Now let’s fetch real data.

## Step 4 — Getting Data from the API

It’s time to replace our mocked-up data with live data from the cryptocompare API to show the price of Bitcoin and Ethereum on the webpage in US Dollars and Euros.

To get the data for our page, we’ll make a request to the following URL, which requests Bitcoin and Etherium in US Dollars and Euros:

    https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD,EUR

This API will return a JSON response. Use `curl` to make a request to the API to see the response:

    curl 'https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD,EUR'

You’ll see output like this:

    Output{"BTC":{"USD":11388.18,"EUR":9469.64},"ETH":{"USD":1037.02,"EUR":865.99}}

This result looks exactly like the hard-coded data model you used in the previous step. All we have to do now is switch out the data by making a request to this URL from our app.

To make the request, we’ll use the [`mounted()`](https://vuejs.org/v2/api/#mounted) function from Vue in combination with the `GET` function of the Axios library to fetch the data and store it in the `results` array in the data model. The `mounted` function is called once the Vue app is mounted to an element. Once the Vue app is mounted, we’ll make the request to the API and save the results. The web page will be notified of the change and the values will appear on the page.

First, open `index.html` and load the Axios library by adding a script below the line where you included Vue:

index.html

    ...
        <script src="https://unpkg.com/vue"></script>
        <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
    ...

Save the file, then open `vueApp.js` and modify it so it makes a request to the API and fills the data model with the results.

vueApp.js

       
    const url = "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC,ETH&tsyms=USD,EUR";
    
    const vm = new Vue({
            el: '#app',
            data: {
              results: []
            },
            mounted() {
              axios.get(url).then(response => {
                this.results = response.data
              })
            }
          });

Notice we’ve removed the default value for `results` and replaced it with an empty array. We won’t have data when our app first loads, but we don’t want things to break. Our HTML view is expecting some data to iterate over when it loads.

The `axios.get` function uses a [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises). When the API returns data successfully, the code within the `then` block is executed, and the data gets saved to our `results` variable.

Save the file and reload the `index.html` page in the web browser. This time you’ll see the current prices of the cryptocurrencies.

If you don’t, take a look at the tutorial [How To Use the JavaScript Developer Console](how-to-use-the-javascript-developer-console) and use the JavaScript console to debug your code.

## Conclusion

In less than fifty lines, you created an API-consuming application using only three tools: Vue.js, Axios, and the Cryptocompare API. You learned how to display data on a page, iterate over results, and replace static data with results from an API.

Now that you understand the fundamentals, you can add other functionality to your application. Modify this application to display additional currencies, or use the techniques you learned in this tutorial to create another web applications using a different API.
