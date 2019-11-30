---
author: Lisa Tagliaferri
date: 2017-07-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-web-data-using-requests-and-beautiful-soup-with-python-3
---

# How To Work with Web Data Using Requests and Beautiful Soup with Python 3

## Introduction

The web provides us with more data than any of us can read and understand, so we often want to work with that information programmatically in order to make sense of it. Sometimes, that data is provided to us by website creators via `.csv` or comma-separated values files, or through an API (Application Programming Interface). Other times, we need to collect text from the web ourselves.

This tutorial will go over how to work with the [Requests](http://docs.python-requests.org/en/master/) and [Beautiful Soup](https://www.crummy.com/software/BeautifulSoup/) Python packages in order to make use of data from web pages. The Requests module lets you integrate your Python programs with web services, while the Beautiful Soup module is designed to make screen-scraping get done quickly. Using the Python interactive console and these two libraries, we’ll go through how to collect a web page and work with the textual information available there.

## Prerequisites

To complete this tutorial, you’ll need a development environment for Python 3. You can follow the appropriate guide for your operating system available from the series [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) or [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 16.04 Server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server) to configure everything you need.

Additionally, you should be familiar with:

- The [Python Interactive Console](how-to-work-with-the-python-interactive-console)
- [Importing Modules in Python 3](how-to-import-modules-in-python-3)
- HTML structure and tagging

With your development environment set up and these Python programming concepts in mind, let’s start working with Requests and Beautiful Soup.

## Installing Requests

Let’s begin by activating our Python 3 programming environment. Make sure you’re in the directory where your environment is located, and run the following command:

    . my_env/bin/activate

In order to work with web pages, we’re going to need to request the page. The Requests library allows you to make use of HTTP within your Python programs in a human readable way.

With our programming environment activated, we’ll install Requests with pip:

    pip install requests

While the Requests library is being installed, you’ll receive the following output:

    OutputCollecting requests
      Downloading requests-2.18.1-py2.py3-none-any.whl (88kB)
        100% |████████████████████████████████| 92kB 3.1MB/s 
    ...
    Installing collected packages: chardet, urllib3, certifi, idna, requests
    Successfully installed certifi-2017.4.17 chardet-3.0.4 idna-2.5 requests-2.18.1 urllib3-1.21.1

If Requests was previously installed, you would have received feedback similar to the following from your terminal window:

    OutputRequirement already satisfied
    ...

With Requests installed into our programming environment, we can go on to install the next module.

## Installing Beautiful Soup

Just as we did with Requests, we’ll install Beautiful Soup with pip. The current version of Beautiful Soup 4 can be installed with the following command:

    pip install beautifulsoup4

Once you run this command, you should see output that looks similar to the following:

    OutputCollecting beautifulsoup4
      Downloading beautifulsoup4-4.6.0-py3-none-any.whl (86kB)
        100% |████████████████████████████████| 92kB 4.4MB/s 
    Installing collected packages: beautifulsoup4
    Successfully installed beautifulsoup4-4.6.0

Now that both Beautiful Soup and Requests are installed, we can move on to understanding how to work with the libraries to scrape websites.

## Collecting a Web Page with Requests

With the two Python libraries we’ll be using now installed, we’re can familiarize ourselves with stepping through a basic web page.

Let’s first move into the [Python Interactive Console](how-to-work-with-the-python-interactive-console):

    python

From here, we’ll import the Requests module so that we can collect a sample web page:

    import requests
    

We’ll assign the URL (below) of the sample web page, `mockturtle.html` to the [variable](how-to-use-variables-in-python-3) `url`:

    url = 'https://assets.digitalocean.com/articles/eng_python/beautiful-soup/mockturtle.html'
    

Next, we can assign the result of a request of that page to the variable `page` with the [`request.get()` method](http://docs.python-requests.org/en/master/user/quickstart/#make-a-request). We pass the page’s URL (that was assigned to the `url` variable) to that method.

    page = requests.get(url)
    

The variable `page` is assigned a Response object:

    >>> page
    <Response [200]>
    >>> 

The Response object above tells us the `status_code` property in square brackets (in this case `200`). This attribute can be called explicitly:

    >>> page.status_code
    200
    >>> 

The returned code of `200` tells us that the page downloaded successfully. Codes that begin with the number `2` generally indicate success, while codes that begin with a `4` or `5` indicate that an error occurred. You can read more about HTTP status codes from the [W3C’s Status Code Definitions](https://www.w3.org/Protocols/HTTP/1.1/draft-ietf-http-v11-spec-01#Status-Codes).

In order to work with web data, we’re going to want to access the text-based content of web files. We can read the content of the server’s response with `page.text` (or `page.content` if we would like to access the response in bytes).

    page.text

Once we press `ENTER`, we’ll receive the following output:

    Output'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n    
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n\n<html lang="en-US" 
    xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">\n<head>\n <meta 
    http-equiv="content-type" content="text/html; charset=us-ascii" />\n\n <title>Turtle 
    Soup</title>\n</head>\n\n<body>\n <h1>Turtle Soup</h1>\n\n <p class="verse" 
    id="first">Beautiful Soup, so rich and green,<br />\n Waiting in a hot tureen!<br />\n Who for 
    such dainties would not stoop?<br />\n Soup of the evening, beautiful Soup!<br />\n Soup of 
    the evening, beautiful Soup!<br /></p>\n\n <p class="chorus" id="second">Beau--ootiful 
    Soo--oop!<br />\n Beau--ootiful Soo--oop!<br />\n Soo--oop of the e--e--evening,<br />\n  
    Beautiful, beautiful Soup!<br /></p>\n\n <p class="verse" id="third">Beautiful Soup! Who cares 
    for fish,<br />\n Game or any other dish?<br />\n Who would not give all else for two<br />\n  
    Pennyworth only of Beautiful Soup?<br />\n Pennyworth only of beautiful Soup?<br /></p>\n\n  
    <p class="chorus" id="fourth">Beau--ootiful Soo--oop!<br />\n Beau--ootiful Soo--oop!<br />\n  
    Soo--oop of the e--e--evening,<br />\n Beautiful, beauti--FUL SOUP!<br 
    /></p>\n</body>\n</html>\n'
    >>> 

Here we see that the full text of the page was printed out, with all of its HTML tags. However, it is difficult to read because there is not much spacing.

In the next section, we can leverage the Beautiful Soup module to work with this textual data in a more human-friendly manner.

## Stepping Through a Page with Beautiful Soup

The Beautiful Soup library creates a parse tree from parsed HTML and XML documents (including documents with non-closed tags or [tag soup](https://en.wikipedia.org/wiki/Tag_soup) and other malformed markup). This functionality will make the web page text more readable than what we saw coming from the Requests module.

To start, we’ll import Beautiful Soup into the Python console:

    from bs4 import BeautifulSoup
    

Next, we’ll run the `page.text` document through the module to give us a `BeautifulSoup` object — that is, a parse tree from this parsed page that we’ll get from running Python’s built-in [`html.parser`](https://docs.python.org/3/library/html.parser.html) over the HTML. The constructed object represents the `mockturtle.html` document as a nested data structure. This is assigned to the variable `soup`.

    soup = BeautifulSoup(page.text, 'html.parser')
    

To show the contents of the page on the terminal, we can print it with the `prettify()` method in order to turn the Beautiful Soup parse tree into a nicely formatted Unicode string.

    print(soup.prettify())

This will render each HTML tag on its own line:

    Output<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
     <head>
      <meta content="text/html; charset=utf-8" http-equiv="content-type"/>
      <title>
       Turtle Soup
      </title>
     </head>
     <body>
      <h1>
       Turtle Soup
      </h1>
      <p class="verse" id="first">
       Beautiful Soup, so rich and green,
       <br/>
       Waiting in a hot tureen!
       <br/>
       Who for such dainties would not stoop?
       <br/>
       Soup of the evening, beautiful Soup!
     ...
    </html>

In the output above, we can see that there is one tag per line and also that the tags are nested because of the tree schema used by Beautiful Soup.

### Finding Instances of a Tag

We can extract a single tag from a page by using Beautiful Soup’s `find_all` method. This will return all instances of a given tag within a document.

    soup.find_all('p')

Running that method on our object returns the full text of the song along with the relevant `<p>` tags and any tags contained within that requested tag, which here includes the line break tags `<br/>`:

    Output[<p class="verse" id="first">Beautiful Soup, so rich and green,<br/>
      Waiting in a hot tureen!<br/>
      Who for such dainties would not stoop?<br/>
      Soup of the evening, beautiful Soup!<br/>
      Soup of the evening, beautiful Soup!<br/></p>, <p class="chorus" id="second">Beau--ootiful Soo--oop!<br/>
    ...
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beauti--FUL SOUP!<br/></p>]

You will notice in the output above that the data is contained in square brackets `[]`. This means it is a Python [list data type](understanding-lists-in-python-3).

Because it is a list, we can call a particular item within it (for example, the third `<p>` element), and use the `get_text()` method to extract all the text from inside that tag:

    soup.find_all('p')[2].get_text()

The output that we receive will be what is in the third `<p>` element in this case:

    Output'Beautiful Soup! Who cares for fish,\n Game or any other dish?\n Who would not give all else for two\n Pennyworth only of Beautiful Soup?\n Pennyworth only of beautiful Soup?'

Note that `\n` line breaks are also shown in the returned string above.

### Finding Tags by Class and ID

HTML elements that refer to CSS selectors like class and ID can be helpful to look at when working with web data using Beautiful Soup. We can target specific classes and IDs by using the `find_all()` method and passing the class and ID strings as arguments.

First, let’s find all of the instances of the class `chorus`. In Beautiful Soup we will assign the string for the class to the keyword argument `class_`:

    soup.find_all(class_='chorus')

When we run the above line, we’ll receive the following list as output:

    Output[<p class="chorus" id="second">Beau--ootiful Soo--oop!<br/>
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beautiful Soup!<br/></p>, <p class="chorus" id="fourth">Beau--ootiful Soo--oop!<br/>
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beauti--FUL SOUP!<br/></p>]

The two `<p>`-tagged sections with the class of `chorus` were printed out to the terminal.

We can also specify that we want to search for the class `chorus` only within `<p>` tags, in case it is used for more than one tag:

    soup.find_all('p', class_='chorus')

Running the line above will produce the same output as before.

We can also use Beautiful Soup to target IDs associated with HTML tags. In this case we will assign the string `'third'` to the keyword argument `id`:

    soup.find_all(id='third')

Once we run the line above, we’ll receive the following output:

    Output[<p class="verse" id="third">Beautiful Soup! Who cares for fish,<br/>
      Game or any other dish?<br/>
      Who would not give all else for two<br/>
      Pennyworth only of Beautiful Soup?<br/>
      Pennyworth only of beautiful Soup?<br/></p>]

The text associated with the `<p>` tag with the id of `third` is printed out to the terminal along with the relevant tags.

## Conclusion

This tutorial took you through retrieving a web page with the Requests module in Python and doing some preliminary scraping of that web page’s textual data in order to gain an understanding of Beautiful Soup.

From here, you can go on to creating a web scraping program that will create a CSV file out of data collected from the web by following the tutorial [How To Scrape Web Pages with Beautiful Soup and Python 3](how-to-scrape-web-pages-with-beautiful-soup-and-python-3).
