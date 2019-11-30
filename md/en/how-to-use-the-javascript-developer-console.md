---
author: Lisa Tagliaferri
date: 2017-06-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-the-javascript-developer-console
---

# How To Use the JavaScript Developer Console

## Introduction

Modern browsers have development tools built in to work with JavaScript and other web technologies. These tools include the Console which is similar to a shell interface, along with tools to inspect the DOM, debug, and analyze network activity.

The Console can be used to log information as part of the JavaScript development process, as well as allow you to interact with a web page by carrying out JavaScript expressions within the page’s context. Essentially, the Console provides you with the ability to write, manage, and monitor JavaScript on demand.

This tutorial will go over how to work with the Console in JavaScript within the context of a browser, and provide an overview of other built-in development tools you may use as part of your web development process.

## Working with the Console in a Browser

Most modern web browsers that support standards-based HTML and XHTML will provide you with access to a Developer Console where you can work with JavaScript in an interface similar to a terminal shell. We’ll go over how to access the Console in Firefox and Chrome.

### Firefox

To open the [Web Console](https://developer.mozilla.org/en-US/docs/Tools/Web_Console) in FireFox, you can navigate to the ☰ menu in the top right corner next to the address bar.

From there, click on the Developer button symbolized by the wrench icon, which will open the Web Developer menu. With that open, click on the Web Console menu item.

![Firefox Web Console Menu Item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/firefox-web-console-menu.png)

Once you do so, a tray will open at the bottom of your browser window:

![Firefox Web Console Tray Item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/firefox-web-console-tray.png)

You can also enter into the Web Console with the keyboard shortcut `CTRL` + `SHIFT` + `K` on Linux and Windows, or `COMMAND` + `OPTION` + `K` on macOS.

Now that we have accessed the Console, we can begin working within it in JavaScript.

### Chrome

To open the [JavaScript Console](https://developers.google.com/web/tools/chrome-devtools/console/) in Chrome, you can navigate to the menu at the top-right of your browser window signified by three vertical dots in a row. From there, you can select More Tools then Developer Tools.

![Chrome Developer Tools Menu Item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/chrome-developer-tools-menu.png)

This will open a panel where you can click on **Console** along the top menu bar to bring up the JavaScript Console if it is not highlighted already:

![Chrome Developer Tools Menu Item](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/chrome-console-tray.png)

You can also enter into the JavaScript Console by using the keyboard shortcut `CTRL` + `SHIFT` + `J` on Linux or Windows, or `COMMAND` + `OPTION` + `J` on macOS, which will bring focus immediately to the Console.

Now that we have accessed the Console, we can begin working within it in JavaScript.

## Working in the Console

Within the Console, you can type JavaScript code.

Let’s start with an alert that prints out the string `Hello, World!`:

    alert("Hello, World!");

Once you press the `ENTER` key following your line of JavaScript, you should see the following alert popup in your browser:

![JavaScript Console Alert Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-alert.png)

Note that the Console will also print the result of evaluating an expression, which will read as `undefined` when the expression does not explicitly return something.

Rather than have pop-up alerts that we need to continue to click out of, we can work with JavaScript by logging it to the Console with `console.log`.

To print the `Hello, World!` string, we can type the following into the Console:

    console.log("Hello, World!");

Within the console, you’ll receive the following output:

    OutputHello, World!

We can also use JavaScript to perform math in the Console:

    console.log(2 + 6);

    Output8

You can also try some more complicated math:

    console.log(34348.2342343403285953845 * 4310.23409128534);

    Output148048930.17230788

Additionally, we can work on multiple lines with variables:

    let d = new Date();
    console.log("Today's date is " + d);

    OutputToday's date is Wed Jun 21 2017 15:49:47 GMT-0400 (EDT)

If you need to modify a command that you passed through the Console, you can type the up arrow ↑ key on your keyboard to retrieve the previous command. This will allow you to edit the command and send it again.

The JavaScript Console provides you with a space to try out JavaScript code in real time by letting you use an environment similar to a terminal shell interface.

## Working with an HTML File

You can also work within the context of an HTML file or a dynamically-rendered page in the Console. This provides you with the opportunity to experiment with JavaScript code within the context of existing HTML, CSS, and JavaScript.

Bear in mind that as soon as you reload a page following modifying it with the Console, it will return to its state prior to your modifying the document, so make sure to save any changes you would like to keep elsewhere.

Let’s take a blank HTML document, such as the following `index.html` file to understand how to use the Console to modify it:

index.html

    <!DOCTYPE html>
    <html lang="en-US">
    
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Today's Date</title>
    </head>
    
    <body>
    
    </body>
    
    </html>

If you save the above HTML file, and load it into the browser of your choice, you should see a blank page with the title of the page as `Today's Date`.

You can then open up the Console and begin working with JavaScript to modify the page. We’ll begin by using JavaScript to insert a heading into the HTML.

    let d = new Date();
    document.body.innerHTML = "<h1>Today's date is " + d + "</h1>"

You’ll receive the following output on the Console:

    Output"<h1>Today's date is Sat Jun 24 2017 12:16:14 GMT-0400 (EDT)</h1>"

And at this point, your page should look similar to this:

![JavaScript Console Plain Date Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-console-plain.png)

We can also go on to modify the style of the page, such as the background color:

    document.body.style.backgroundColor = "lightblue";

    Output"lightblue"

As well as the color of the text on the page:

    document.body.style.color = "white";

    Output"white"

Now your page will look something like this:

![JavaScript Console Style Date Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-console-style.png)

From here, you can create a `<p>` paragraph element:

    let p = document.createElement("P");

With this element created, you can then go on to create a text node that we can then add to the paragraph:

    let t = document.createTextNode("Paragraph text.");

We’ll add the text node by appending it to the variable `p`:

    p.appendChild(t);

And finally append `p` with its paragraph `<p>` element and appended text node to the document:

    document.body.appendChild(p);

Once you have completed these steps, your HTML page `index.html` will look similar to this:

![JavaScript Console Date with Paragraph Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-console-with-paragraph.png)

The Console provides you with a space to experiment with modifying HTML pages, but it is important to keep in mind that you’re not changing the HTML document when you do things on the Console. In this case, once you reload the page it will return to a blank document.

## Understanding Other Development Tools

Depending on which browser’s development tools you use, you’ll be able to use other tools to help with your web development workflow. Let’s go over a few of these tools.

### DOM — Document Object Model

Each time a web page is loaded, the browser it is in creates a **D** ocument **O** bject **M** odel, or **DOM** , of the page.

The DOM is a tree of Objects and shows the HTML elements within a hierarchical view. The DOM Tree is available to view within the **[Inspector](https://developer.mozilla.org/en-US/docs/Tools/Page_Inspector)** panel in Firefox or the **[Elements](https://developers.google.com/web/tools/chrome-devtools/inspect-styles/)** panel in Chrome.

These tools enable you to inspect and edit DOM elements and also let you identify the HTML related to an aspect of a particular page. The DOM can tell you whether a text snippet or image has an ID attribute and can let you determine what that attribute’s value is.

The page that we modified above would have a DOM view that looks similar to this before we reload the page:

![JavaScript DOM Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-dom-example.png)

Additionally, you will see CSS styles in a side panel or below the DOM panel, allowing you to see what styles are being employed within the HTML document or via a CSS style sheet. This is what our sample page above’s body style looks like within the Firefox Inspector:

![JavaScript CSS Example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_javascript/js-console/javascript-css-example.png)

To live-edit a DOM node, double-click a selected element and make changes. To start, for example, you can modify an `<h1>` tag and make it an `<h2>` tag.

As with the Console, if you reload the page you’ll return to the saved state of the HTML document.

### Network

The **Network** tab of your browser’s built-in development tools can monitor and record network requests. This tab shows you the network requests that the browser makes, including when it loads a page, how long each request takes, and provides the details of each of these requests. This can be used to optimize page load performance and debug request issues.

You can use the Network tab alongside the JavaScript Console. That is, you can start debugging a page with the Console then switch to the Network tab to see network activity without reloading the page.

To learn more about how to use the Network tab, you can read about [working with Firefox’s Network Monitor](https://developer.mozilla.org/en-US/docs/Tools/Network_Monitor) or [getting started with analyzing Network performance with Chrome’s DevTools](https://developers.google.com/web/tools/chrome-devtools/network-performance/).

### Responsive Design

When websites are responsive, they are designed and developed to both look and function properly on a range of different devices: mobile phones, tablets, desktops, and laptops. Screen size, pixel density, and supporting touch are factors to consider when developing across devices. As a web developer, it is important to keep responsive design principles in mind so that your websites are fully available to people regardless of the device that they have access to.

Both Firefox and Chrome provide you with modes for ensuring that responsive design principles are given attention as you create and develop sites and apps for the web. These modes will emulate different devices that you can investigate and analyze as part of your development process.

Read more about Firefox’s [Responsive Design Mode](https://developer.mozilla.org/en-US/docs/Tools/Responsive_Design_Mode) or Chrome’s [Device Mode](https://developers.google.com/web/tools/chrome-devtools/device-mode/) to learn more about how to leverage these tools to ensure more equitable access to web technologies.

## Conclusion

This tutorial provided an overview of working with a JavaScript Console within modern web browsers, as well as some information on other development tools you can use in your workflow.

To learn more about JavaScript, you can read about [data types](understanding-data-types-in-javascript), or the [jQuery](an-introduction-to-jquery) or [D3](how-to-make-a-bar-chart-with-javascript-and-the-d3-library) libraries.
