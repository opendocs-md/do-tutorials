---
author: Mayank Raj
date: 2019-04-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-a-search-bar-with-rxjs
---

# How To Build a Search Bar with RxJS

_The author selected [Mozilla Foundation](https://www.brightfunds.org/organizations/mozilla-foundation) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) is a paradigm concerned with _asynchronous data streams_, in which the programming model considers everything to be a stream of data spread over time. This includes keystrokes, HTTP requests, files to be printed, and even elements of an array, which can be considered to be timed over very small intervals. This makes it a perfect fit for JavaScript as asynchronous data is common in the language.

[RxJS](https://rxjs-dev.firebaseapp.com/) is a popular library for reactive programming in [JavaScript](https://www.javascript.com/). [ReactiveX](http://reactivex.io/), the umbrella under which RxJS lies, has its extensions in many other languages like [Java](https://www.java.com), [Python](https://www.python.org/), [C++](https://isocpp.org/), [Swift](https://developer.apple.com/swift/), and [Dart](https://www.dartlang.org/). RxJS is also widely used by libraries like Angular and React.

RxJS’s implementation is based on chained functions that are aware and capable of handling data over a range of time. This means that one could implement virtually every aspect of RxJS with nothing more than functions that receive a list of arguments and callbacks, and then execute them when signaled to do so. The community around RxJS has done this heavy lifting, and the result is an API that you can directly use in any application to write clean and maintainable code.

In this tutorial, you will use RxJS to build a feature-rich search bar that returns real-time results to users. You will also use HTML and CSS to format the search bar. The end result will look this this:

![Demonstration of Search Bar](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-62307/introduction_search.gif)

Something as common and seemingly simple as a search bar needs to have various checks in place. This tutorial will show you how RxJS can turn a fairly complex set of requirements into code that is manageable and easy to understand.

## Prerequisites

Before you begin this tutorial you’ll need the following:

- A text editor that supports JavaScript syntax highlighting, such as [Atom](http://atom.io), [Visual Studio Code](https://code.visualstudio.com/), or [Sublime Text](https://www.sublimetext.com/). These editors are available on Windows, macOS, and Linux.
- Familiarity with using HTML and JavaScript together. Learn more in [How To Add JavaScript to HTML](how-to-add-javascript-to-html).
- Familiarity with the JSON data format, which you can learn more about in [How to Work with JSON in JavaScript](how-to-work-with-json-in-javascript).

The full code for the tutorial is available on [Github](https://github.com/do-community/RxJS-Search-Bar).

## Step 1 — Creating and Styling Your Search Bar

In this step, you will create and style the search bar with HTML and CSS. The code will use a few common elements from [Bootstrap](https://getbootstrap.com/) to speed up the process of structuring and styling the page so you can focus on adding custom elements. _Bootstrap_ is a CSS framework that contains templates for common elements like typography, forms, buttons, navigation, grids, and other interface components. Your application will also use [Animate.css](https://daneden.github.io/animate.css/) to add animation to the search bar.

You will start start by creating a file named `search-bar.html` with `nano` or your favorite text editor:

    nano search-bar.html

Next, create the basic structure for your application. Add the following HTML to the new file:

search-bar.html

    <!DOCTYPE html>
    <html>
    
      <head>
        <title>RxJS Tutorial</title>
        <!-- Load CSS -->
    
        <!-- Load Rubik font -->
    
        <!-- Add Custom inline CSS -->
    
      </head>
    
      <body>
          <!-- Content -->
    
          <!-- Page Header and Search Bar -->
    
          <!-- Results -->
    
          <!-- Load External RxJS -->
    
          <!-- Add custom inline JavaScript -->
          <script>
    
          </script>
      </body>
    
    </html>

As you need CSS from the entire Bootstrap library, go ahead and load the CSS for Bootstrap and Animate.css.

Add the following code under the `Load CSS` comment:

search-bar.html

    ...
    <!-- Load CSS -->
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/3.7.0/animate.min.css" />
    ...

This tutorial will use a custom font called [Rubik](https://fonts.google.com/specimen/Rubik) from the [Google Fonts](https://fonts.google.com/) library to style the search bar. Load the font by adding the highlighted code under the `Load Rubik font` comment:

search-bar.html

    ...
    <!-- Load Rubik font -->
        <link href="https://fonts.googleapis.com/css?family=Rubik" rel="stylesheet">
    ...

Next, add the custom CSS to the page under the `Add Custom inline CSS` comment. This will make sure that the headings, search bar, and the results on the page are easy to read and use.

search-bar.html

    ...
    <!-- Add Custom inline CSS -->
        <style>
          body {
            background-color: #f5f5f5;
            font-family: "Rubik", sans-serif;
          }
    
          .search-container {
            margin-top: 50px;
          }
          .search-container .search-heading {
            display: block;
            margin-bottom: 50px;
          }
          .search-container input,
          .search-container input:focus {
            padding: 16px 16px 16px;
            border: none;
            background: rgb(255, 255, 255);
            box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 25px 50px 0 rgba(0, 0, 0, 0.1) !important;
          }
    
          .results-container {
            margin-top: 50px;
          }
          .results-container .list-group .list-group-item {
            background-color: transparent;
            border-top: none !important;
            border-bottom: 1px solid rgba(236, 229, 229, 0.64);
          }
    
          .float-bottom-right {
            position: fixed;
            bottom: 20px;
            left: 20px;
            font-size: 20px;
            font-weight: 700;
            z-index: 1000;
          }
          .float-bottom-right .info-container .card {
            display: none;
          }
          .float-bottom-right .info-container:hover .card,
          .float-bottom-right .info-container .card:hover {
            display: block;
          }
        </style>
    ...

Now that you have all of the styles in place, add the HTML that will define the header and the input bar under the `Page Header and Search Bar` comment:

search-bar.html

    ...
    <!-- Content -->
    <!-- Page Header and Search Bar -->
          <div class="container search-container">
            <div class="row justify-content-center">
              <div class="col-md-auto">
                <div class="search-heading">
                  <h2>Search for Materials Published by Author Name</h2>
                  <p class="text-right">powered by <a href="https://www.crossref.org/">Crossref</a></p>
                </div>
              </div>
            </div>
            <div class="row justify-content-center">
              <div class="col-sm-8">
                <div class="input-group input-group-md">
                  <input id="search-input" type="text" class="form-control" placeholder="eg. Richard" aria-label="eg. Richard" autofocus>
                </div>
              </div>
            </div>
          </div>
    ...

This uses the grid system from Bootstrap to structure the page header and the search bar. You have assigned a `search-input` identifier to the search bar, which you will use to bind to a listener later in the tutorial.

Next, you will create a location to display the results of the search. Under the `Results` comment, create a `div` with the `response-list` identifier to add the results later in the tutorial:

search-bar.html

    ...
    <!-- Results -->
          <div class="container results-container">
            <div class="row justify-content-center">
              <div class="col-sm-8">
                <ul id="response-list" class="list-group list-group-flush"></ul>
              </div>
            </div>
          </div>
    ...

At this point, the `search-bar.html` file will look like this:

search-bar.html

    <!DOCTYPE html>
    <html>
    
      <head>
        <title>RxJS Tutorial</title>
        <!-- Load CSS -->
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/3.7.0/animate.min.css" />
    
        <!-- Load Rubik font -->
        <link href="https://fonts.googleapis.com/css?family=Rubik" rel="stylesheet">
    
        <!-- Add Custom inline CSS -->
        <style>
          body {
            background-color: #f5f5f5;
            font-family: "Rubik", sans-serif;
          }
    
          .search-container {
            margin-top: 50px;
          }
          .search-container .search-heading {
            display: block;
            margin-bottom: 50px;
          }
          .search-container input,
          .search-container input:focus {
            padding: 16px 16px 16px;
            border: none;
            background: rgb(255, 255, 255);
            box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 25px 50px 0 rgba(0, 0, 0, 0.1) !important;
          }
    
          .results-container {
            margin-top: 50px;
          }
          .results-container .list-group .list-group-item {
            background-color: transparent;
            border-top: none !important;
            border-bottom: 1px solid rgba(236, 229, 229, 0.64);
          }
    
          .float-bottom-right {
            position: fixed;
            bottom: 20px;
            left: 20px;
            font-size: 20px;
            font-weight: 700;
            z-index: 1000;
          }
          .float-bottom-right .info-container .card {
            display: none;
          }
          .float-bottom-right .info-container:hover .card,
          .float-bottom-right .info-container .card:hover {
            display: block;
          }
        </style>
      </head>
    
      <body>
          <!-- Content -->
          <!-- Page Header and Search Bar -->
          <div class="container search-container">
            <div class="row justify-content-center">
              <div class="col-md-auto">
                <div class="search-heading">
                  <h2>Search for Materials Published by Author Name</h2>
                  <p class="text-right">powered by <a href="https://www.crossref.org/">Crossref</a></p>
                </div>
              </div>
            </div>
            <div class="row justify-content-center">
              <div class="col-sm-8">
                <div class="input-group input-group-md">
                  <input id="search-input" type="text" class="form-control" placeholder="eg. Richard" aria-label="eg. Richard" autofocus>
                </div>
              </div>
            </div>
          </div>
    
          <!-- Results -->
          <div class="container results-container">
            <div class="row justify-content-center">
              <div class="col-sm-8">
                <ul id="response-list" class="list-group list-group-flush"></ul>
              </div>
            </div>
          </div>
    
          <!-- Load RxJS -->
    
          <!-- Add custom inline JavaScript -->
          <script>
    
          </script>
      </body>
    
    </html>

In this step, you’ve laid out the basic structure for your search bar with HTML and CSS. In the next step, you will write a JavaScript function that will accept search terms and return results.

## Step 2 — Writing the JavaScript

Now that you have the search bar formatted, you are ready to write the JavaScript code that will act as a foundation for the RxJS code that you’ll write later in this tutorial. This code will work with RxJS to accept search terms and return results.

Since you won’t need the functionalities that Bootstrap and JavaScript provide in this tutorial, you aren’t going to load them. However, you will be using RxJS. Load the RxJS library by adding the following under the `Load RxJS` comment:

search-bar.html

    ...
    <!-- Load RxJS -->
        <script src="https://unpkg.com/@reactivex/rxjs@5.0.3/dist/global/Rx.js"></script>
    ...

Now you will store references of the `div` from the HTML to which the results will be added. Add the highlighted JavaScript code in the `<script>` tag under the `Add custom inline JavaScript` comment:

search-bar.html

    ...
    <!-- Add custom inline JavaScript -->
    <script>
            const output = document.getElementById("response-list");
    
    </script>
    ...

Next, add the code to convert the JSON response from the API into the HTML elements to display on the page. This code will first clear the contents of the search bar and then set a delay for the search result animation.

Add the highlighted function between the `<script>` tags:

search-bar.html

    ...
    <!-- Add custom inline JavaScript -->
    <script>
        const output = document.getElementById("response-list");
    
            function showResults(resp) {
            var items = resp['message']['items']
            output.innerHTML = "";
            animationDelay = 0;
            if (items.length == 0) {
              output.innerHTML = "Could not find any :(";
            } else {
              items.forEach(item => {
                resultItem = `
                <div class="list-group-item animated fadeInUp" style="animation-delay: ${animationDelay}s;">
                  <div class="d-flex w-100 justify-content-between">
    <^> <h5 class="mb-1">${(item['title'] && item['title'][0]) || "&lt;Title not available&gt;"}</h5>
                  </div>
                  <p class="mb-1">${(item['container-title'] && item['container-title'][0]) || ""}</p>
                  <small class="text-muted"><a href="${item['URL']}" target="_blank">${item['URL']}</a></small>
                  <div> 
                    <p class="badge badge-primary badge-pill">${item['publisher'] || ''}</p>
                    <p class="badge badge-primary badge-pill">${item['type'] || ''}</p> 
                 </div>
                </div>
                `;
                output.insertAdjacentHTML("beforeend", resultItem);
                animationDelay += 0.1; 
    
              });
            }
          }
    
    </script>
    ...

The code block starting with `if` is a conditional loop that checks for search results, and displays a message if no results were found. If results are found, then the `forEach` loop will provide the results with an animation to the user.

In this step, you laid out the base for the RxJS by writing out a function that can accept results and return it on the page. In the next step, you will make the search bar functional.

## Step 3 — Setting Up a Listener

RxJS is concerned with data streams, which in this project is a series of characters that the user enters in to the input element, or search bar. In this step, you will add a listener on the input element to listen for updates.

First, take note of the `search-input` identifier that you added earlier in the tutorial:

search-bar.html

    ...
    <input id="search-input" type="text" class="form-control" placeholder="eg. Richard" aria-label="eg. Richard" autofocus>
    ...

Next, create a variable that will hold references for the `search-input` element. This will become the _`Observable`_ that the code will use to listen for input events. `Observables` are a collection of future values or events that an `Observer` listens to, and are also known as _callback functions_.

Add the highlighted line in the `<script>` tag under the JavaScript from the previous step:

search-bar.html

    ...
          output.insertAdjacentHTML("beforeend", resultItem);
          animationDelay += 0.1; 
    
        });
      }
    }
    
    
          let searchInput = document.getElementById("search-input");
    ...

Now that you’ve added a variable to reference input, you will use the `fromEvent` operator to listen for events. This will add a listener on a _DOM_, or **D** ocument **O** bject **M** odel, element for a certain kind of event. A DOM element could be a `html`, `body`, `div`, or `img` element on a page. In this case, your DOM element is the search bar.

Add the following highlighted line under your `searchInput` variable to pass your parameters to `fromEvent`. Your `searchInput` DOM element is the first parameter. This is followed by the `input` event as the second parameter, which is the event type the code will listen for.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
    ...

Now that your listener is set up, your code will receive a notification whenever any updates take place on the input element. In the next step you will use operators to take action on such events.

## Step 4 — Adding Operators

`Operators` are pure functions with one task—to perform an operation on data. In this step, you will use operators to perform various tasks such as buffering the `input` parameter, making HTTP requests, and filtering results.

You will first make sure that the results update in real-time as the user enters queries. To achieve this, you will use the DOM input event from the previous step. The DOM input event contains various details, but for this tutorial you are interested in values typed into the target element. Add the following code to use the `pluck` operator to take an object and return the value at the specified key:

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
    ...

Now that the events are in the necessary format, you will set the search-term minimum to three characters. In many cases, anything less than three characters will not yield relevant results, or the user may still be in the process of typing.

You will use the `filter` operator to set the minimum. It will pass the data further down the stream if it satisfies the specified condition. Set the length condition to greater than `2` to require at least three characters.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
    ...

You will also make sure that requests are only sent in at 500ms intervals to ease up the load on the API server. To do this, you will use the `debounceTime` operator to maintain a minimum specified interval between each event that it passes through the stream. Add the highlighted code under the `filter` operator:

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
    ...

The application should also ignore the search term if there have been no changes since the last API call. This will optimize the application by further reducing the number of sent API calls.

As an example, a user may type `super cars`, delete the last character (making the term `super car`), and then add the deleted character back to revert the term back to `super cars`. As a result, the term did not change, and therefore the search results should not change. In such cases it makes sense to not perform any operations.

You will use the `distinctUntilChanged` operator to configure this. This operator remembers the previous data that was passed through the stream and passes another only if it is different.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
            .distinctUntilChanged()
    ...

Now that you have regulated the inputs from the user, you will add the code that will query the API with the search term. To do this, you will use the RxJS implementation of _AJAX_. AJAX makes API calls asynchronously in the background on a loaded page. AJAX will allow you to avoid reloading the page with results for new search terms and also update the results on the page by fetching the data from the server.

Next, add the code to use `switchMap` to chain AJAX to your application. You will also use `map` to map the input to an output. This code will apply the function passed to it to every item emitted by an `Observable`.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
            .distinctUntilChanged()
            .switchMap(searchKey => Rx.Observable.ajax(`https://api.crossref.org/works?rows=50&query.author=${searchKey}`)
              .map(resp => ({
                  "status" : resp["status"] == 200,
                  "details" : resp["status"] == 200 ? resp["response"] : [],
                  "result_hash": Date.now()
                })
              )
            )
    ...

This code breaks the API response into three parts:

- `status`: The HTTP status code returned by the API server. This code will only accept `200`, or successful, responses.
- `details`: The actual response data received. This will contain the results for the queried search term.
- `result_hash`: A hash value of the responses returned by the API server, which for the purpose of this tutorial is a UNIX time-stamp. This is a hash of results that changes when the results change. The unique hash value will allow the application to determine if the results have changed and should be updated.

Systems fail and your code should be prepared to handle errors. To handle errors that may happen in the API call, use the `filter` operator to only accept successful responses:

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
            .distinctUntilChanged()
            .switchMap(searchKey => Rx.Observable.ajax(`https://api.crossref.org/works?rows=50&query.author=${searchKey}`)
              .map(resp => ({
                  "status" : resp["status"] == 200,
                  "details" : resp["status"] == 200 ? resp["response"] : [],
                  "result_hash": Date.now()
                })
              )
            )
            .filter(resp => resp.status !== false)
    ...

Next, you will add code to only update the DOM if changes are detected in the response. DOM updates can be a resource-heavy operation, so reducing the number of updates will have a positive impact on the application. Since the `result_hash` will only change when a response changes, you will use it to implement this functionality.

To do this, use the `distinctUntilChanged` operator like before. The code will use it to only accept user input when the key has changed.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
            .distinctUntilChanged()
            .switchMap(searchKey => Rx.Observable.ajax(`https://api.crossref.org/works?rows=50&query.author=${searchKey}`)
              .map(resp => ({
                  "status" : resp["status"] == 200,
                  "details" : resp["status"] == 200 ? resp["response"] : [],
                  "result_hash": Date.now()
                })
              )
            )
            .filter(resp => resp.status !== false)
            .distinctUntilChanged((a, b) => a.result_hash === b.result_hash)
    ...

You previously used the `distinctUntilChanged` operator to see if the entirety of the data had changed, but in this instance, you check for an updated key in the response. Comparing the entire response would be resource-costly when compared to identifying changes in a single key. Since the key hash is representative of the whole response, it can confidently be used to identify response changes.

The function accepts two objects, the previous value that it had seen and the new value. We check the hash from these two objects and return `True` when these two values match, in which case the data is filtered out and not passed further in the pipeline.

In this step, you created a pipeline that receives a search term entered by the user and then performs various checks on it. After the checks are complete, it makes an API call and returns the response in a format that displays results back to the user. You optimized the resource usage on both the client and server side by limiting API calls when necessary. In the next step, you will configure the application to start listening on the input element, and pass the results to the function that will render it on the page.

## Step 5 — Activating Everything with a Subscription

`subscribe` is the final operator of the link that enables the observer to see data events emitted by the `Observable`. It implements the following three methods:

- `onNext`: This specifies what to do when an event is received.
- `onError`: This is responsible for handling errors. Calls to `onNext` and `onCompleted` will not be made once this method is called.
- `onCompleted`: This method is called when `onNext` has been called for the final time. There would be no more data that will be passed in the pipeline.

This signature of a subscriber is what enables one to achieve _lazy execution_, which is the ability to define an `Observable` pipeline and set it in motion only when you subscribe to it. You won’t use this example in your code, but the following shows you how an `Observable` can be subscribed to:

Next, subscribe to the `Observable` and route the data to the method that is responsible for rendering it in the UI.

search-bar.html

    ...
          let searchInput = document.getElementById("search-input");
          Rx.Observable.fromEvent(searchInput, 'input')
            .pluck('target', 'value')
            .filter(searchTerm => searchTerm.length > 2)
            .debounceTime(500)
            .distinctUntilChanged()
            .switchMap(searchKey => Rx.Observable.ajax(`https://api.crossref.org/works?rows=50&query.author=${searchKey}`)
              .map(resp => ({
                  "status" : resp["status"] == 200,
                  "details" : resp["status"] == 200 ? resp["response"] : [],
                  "result_hash": Date.now()
                })
              )
            )
            .filter(resp => resp.status !== false)
            .distinctUntilChanged((a, b) => a.result_hash === b.result_hash)
            .subscribe(resp => showResults(resp.details));
    ...

Save and close the file after making these changes.

Now that you’ve completed writing the code, you are ready to view and test your search bar. Double-click the `search-bar.html` file to open it in your web browser. If the code was entered in correctly, you will see your search bar.

![The completed search bar](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-62307/completed_searchbar.png)

Type content in your search bar to test it out.

![A gif of content being entered into the search bar, showing that two characters won't return any results.](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-62307/test_searchbar.gif)

In this step, you subscribed to the `Observable` to activate your code. You now have a stylized and functioning search bar application.

## Conclusion

In this tutorial, you created a feature-rich search bar with RxJS, CSS, and HTML that provides real-time results to users. The search bar requires a minimum of three characters, updates automatically, and is optimized for both the client and the API server.

What could be considered a complex set of requirements was created with 18 lines of RxJS code. The code is not only reader-friendly, but it is also much cleaner than a standalone JavaScript implementation. This means that your code will be easier to understand, update, and maintain in the future.

To read more about using RxJS, check out the [official API documentation](https://rxjs-dev.firebaseapp.com/api).
