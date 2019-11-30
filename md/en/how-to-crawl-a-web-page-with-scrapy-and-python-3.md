---
author: Justin Duke
date: 2016-09-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-crawl-a-web-page-with-scrapy-and-python-3
---

# How To Crawl A Web Page with Scrapy and Python 3

## Introduction

Web scraping, often called web crawling or web spidering, or “programmatically going over a collection of web pages and extracting data,” is a powerful tool for working with data on the web.

With a web scraper, you can mine data about a set of products, get a large corpus of text or quantitative data to play around with, get data from a site without an official API, or just satisfy your own personal curiosity.

In this tutorial, you’ll learn about the fundamentals of the scraping and spidering process as you explore a playful data set. We’ll use [BrickSet](http://brickset.com), a community-run site that contains information about LEGO sets. By the end of this tutorial, you’ll have a fully functional Python web scraper that walks through a series of pages on Brickset and extracts data about LEGO sets from each page, displaying the data to your screen.

The scraper will be easily expandable so you can tinker around with it and use it as a foundation for your own projects scraping data from the web.

## Prerequisites

To complete this tutorial, you’ll need a local development environment for Python 3. You can follow [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) to configure everything you need.

## Step 1 — Creating a Basic Scraper

Scraping is a two step process:

1. You systematically find and download web pages.
2. You take those web pages and extract information from them.

Both of those steps can be implemented in a number of ways in many languages.

You can build a scraper from scratch using [modules](how-to-import-modules-in-python-3) or libraries provided by your programming language, but then you have to deal with some potential headaches as your scraper grows more complex. For example, you’ll need to handle concurrency so you can crawl more than one page at a time. You’ll probably want to figure out how to transform your scraped data into different formats like CSV, XML, or JSON. And you’ll sometimes have to deal with sites that require specific settings and access patterns.

You’ll have better luck if you build your scraper on top of an existing library that handles those issues for you. For this tutorial, we’re going to use Python and [Scrapy](http://doc.scrapy.org/en/1.1/intro/overview.html) to build our scraper.

Scrapy is one of the most popular and powerful Python scraping libraries; it takes a “batteries included” approach to scraping, meaning that it handles a lot of the common functionality that all scrapers need so developers don’t have to reinvent the wheel each time. It makes scraping a quick and fun process!

Scrapy, like most Python packages, is on PyPI (also known as `pip`). PyPI, the Python Package Index, is a community-owned repository of all published Python software.

If you have a Python installation like the one outlined in the prerequisite for this tutorial, you already have `pip` installed on your machine, so you can install Scrapy with the following command:

    pip install scrapy

If you run into any issues with the installation, or you want to install Scrapy without using `pip`, check out the [official installation docs](https://doc.scrapy.org/en/1.1/intro/install.html).

With Scrapy installed, let’s create a new folder for our project. You can do this in the terminal by running:

    mkdir brickset-scraper

Now, navigate into the new directory you just created:

    cd brickset-scraper

Then create a new Python file for our scraper called `scraper.py`. We’ll place all of our code in this file for this tutorial. You can create this file in the terminal with the `touch` command, like this:

    touch scraper.py

Or you can create the file using your text editor or graphical file manager.

We’ll start by making a very basic scraper that uses Scrapy as its foundation. To do that, we’ll create a [Python class](how-to-construct-classes-and-define-objects-in-python-3) that subclasses `scrapy.Spider`, a basic spider class provided by Scrapy. This class will have two required attributes:

- `name` — just a name for the spider.
- `start_urls` — a [list](understanding-lists-in-python-3) of URLs that you start to crawl from. We’ll start with one URL.

Open the `scrapy.py` file in your text editor and add this code to create the basic spider:

scraper.py

    import scrapy
    
    
    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']

Let’s break this down line by line:

First, we [import](how-to-import-modules-in-python-3) `scrapy` so that we can use the classes that the package provides.

Next, we take the `Spider` class provided by Scrapy and make a _subclass_ out of it called `BrickSetSpider`. Think of a subclass as a more specialized form of its parent class. The `Spider` subclass has methods and behaviors that define how to follow URLs and extract data from the pages it finds, but it doesn’t know where to look or what data to look for. By subclassing it, we can give it that information.

Then we give the spider the name `brickset_spider`.

Finally, we give our scraper a single URL to start from: [http://brickset.com/sets/year-2016](http://brickset.com/sets/year-2016). If you open that URL in your browser, it will take you to a search results page, showing the first of many pages containing LEGO sets.

Now let’s test out the scraper. You typically run Python files by running a command like `python path/to/file.py`. However, Scrapy comes with [its own command line interface](https://doc.scrapy.org/en/latest/topics/commands.html) to streamline the process of starting a scraper. Start your scraper with the following command:

    scrapy runspider scraper.py

You’ll see something like this:

    Output2016-09-22 23:37:45 [scrapy] INFO: Scrapy 1.1.2 started (bot: scrapybot)
    2016-09-22 23:37:45 [scrapy] INFO: Overridden settings: {}
    2016-09-22 23:37:45 [scrapy] INFO: Enabled extensions:
    ['scrapy.extensions.logstats.LogStats',
     'scrapy.extensions.telnet.TelnetConsole',
     'scrapy.extensions.corestats.CoreStats']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled downloader middlewares:
    ['scrapy.downloadermiddlewares.httpauth.HttpAuthMiddleware',
     ...
     'scrapy.downloadermiddlewares.stats.DownloaderStats']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled spider middlewares:
    ['scrapy.spidermiddlewares.httperror.HttpErrorMiddleware',
     ...
     'scrapy.spidermiddlewares.depth.DepthMiddleware']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled item pipelines:
    []
    2016-09-22 23:37:45 [scrapy] INFO: Spider opened
    2016-09-22 23:37:45 [scrapy] INFO: Crawled 0 pages (at 0 pages/min), scraped 0 items (at 0 items/min)
    2016-09-22 23:37:45 [scrapy] DEBUG: Telnet console listening on 127.0.0.1:6023
    2016-09-22 23:37:47 [scrapy] DEBUG: Crawled (200) <GET http://brickset.com/sets/year-2016> (referer: None)
    2016-09-22 23:37:47 [scrapy] INFO: Closing spider (finished)
    2016-09-22 23:37:47 [scrapy] INFO: Dumping Scrapy stats:
    {'downloader/request_bytes': 224,
     'downloader/request_count': 1,
     ...
     'scheduler/enqueued/memory': 1,
     'start_time': datetime.datetime(2016, 9, 23, 6, 37, 45, 995167)}
    2016-09-22 23:37:47 [scrapy] INFO: Spider closed (finished)

That’s a lot of output, so let’s break it down.

- The scraper initialized and loaded additional components and extensions it needed to handle reading data from URLs.
- It used the URL we provided in the `start_urls` list and grabbed the HTML, just like your web browser would do. 
- It passed that HTML to the `parse` method, which doesn’t do anything by default. Since we never wrote our own `parse` method, the spider just finishes without doing any work.

Now let’s pull some data from the page.

## Step 2 — Extracting Data from a Page

We’ve created a very basic program that pulls down a page, but it doesn’t do any scraping or spidering yet. Let’s give it some data to extract.

If you look at [the page we want to scrape](http://brickset.com/sets/year-2016), you’ll see it has the following structure:

- There’s a header that’s present on every page.
- There’s some top-level search data, including the number of matches, what we’re searching for, and the breadcrumbs for the site.
- Then there are the sets themselves, displayed in what looks like a table or ordered list. Each set has a similar format.

When writing a scraper, it’s a good idea to look at the source of the HTML file and familiarize yourself with the structure. So here it is, with some things removed for readability:

    brickset.com/sets/year-2016<body>
      <section class="setlist">
        <article class='set'>
          <a href="https://images.brickset.com/sets/large/10251-1.jpg?201510121127" 
          class="highslide plain mainimg" onclick="return hs.expand(this)"><img 
          src="https://images.brickset.com/sets/small/10251-1.jpg?201510121127" title="10251-1: 
          Brick Bank" onError="this.src='/assets/images/spacer.png'" /></a>
          <div class="highslide-caption">
            <h1>Brick Bank</h1><div class='tags floatleft'><a href='/sets/10251-1/Brick- 
            Bank'>10251-1</a> <a href='/sets/theme-Creator-Expert'>Creator Expert</a> <a 
            class='subtheme' href='/sets/theme-Creator-Expert/subtheme-Modular- 
            Buildings'>Modular Buildings</a> <a class='year' href='/sets/theme-Creator- 
            Expert/year-2016'>2016</a> </div><div class='floatright'>&copy;2016 LEGO 
            Group</div>
              <div class="pn">
                <a href="#" onclick="return hs.previous(this)" title="Previous (left arrow 
                key)">&#171; Previous</a>
                <a href="#" onclick="return hs.next(this)" title="Next (right arrow key)">Next 
                &#187;</a>
              </div>
          </div>
    
    ...
    
        </article>
      </section>
    </body>

Scraping this page is a two step process:

1. First, grab each LEGO set by looking for the parts of the page that have the data we want.
2. Then, for each set, grab the data we want from it by pulling the data out of the HTML tags.

`scrapy` grabs data based on _selectors_ that you provide. Selectors are patterns we can use to find one or more elements on a page so we can then work with the data within the element. `scrapy` supports either CSS selectors or [XPath](https://en.wikipedia.org/wiki/XPath) selectors.

We’ll use CSS selectors for now since CSS is the easier option and a perfect fit for finding all the sets on the page. If you look at the HTML for the page, you’ll see that each set is specified with the class `set`. Since we’re looking for a class, we’d use `.set` for our CSS selector. All we have to do is pass that selector into the `response` object, like this:

scraper.py

    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
                pass

This code grabs all the sets on the page and loops over them to extract the data. Now let’s extract the data from those sets so we can display it.

Another look at the [source](https://brickset.com/sets/year-2016) of the page we’re parsing tells us that the name of each set is stored within an `h1` tag for each set:

    brickset.com/sets/year-2016<h1>Brick Bank</h1><div class='tags floatleft'><a href='/sets/10251-1/Brick-Bank'>10251-1</a>

The `brickset` object we’re looping over has its own `css` method, so we can pass in a selector to locate child elements. Modify your code as follows to locate the name of the set and display it:

scraper.py

    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 ::text'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                }

**Note** : The trailing comma after `extract_first()` isn’t a typo. We’re going to add more to this section soon, so we’ve left the comma there to make adding to this section easier later.

You’ll notice two things going on in this code:

- We append `::text` to our selector for the name. That’s a CSS _pseudo-selector_ that fetches the text _inside_ of the `a` tag rather than the tag itself.
- We call `extract_first()` on the object returned by `brickset.css(NAME_SELECTOR)` because we just want the first element that matches the selector. This gives us a [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3), rather than a list of elements.

Save the file and run the scraper again:

    scrapy runspider scraper.py

This time you’ll see the names of the sets appear in the output:

    Output...
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Brick Bank'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Volkswagen Beetle'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Big Ben'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Winter Holiday Train'}
    ...
    

Let’s keep expanding on this by adding new selectors for images, pieces, and miniature figures, or _minifigs_ that come with a set.

Take another look at the HTML for a specific set:

    brickset.com/sets/year-2016<article class="set">
      <a class="highslide plain mainimg" href="http://images.brickset.com/sets/images/10251-1.jpg?201510121127" onclick="return hs.expand(this)">
        <img src="http://images.brickset.com/sets/small/10251-1.jpg?201510121127" title="10251-1: Brick Bank"></a>
      ...
      <div class="meta">
        <h1><a href="/sets/10251-1/Brick-Bank"><span>10251:</span> Brick Bank</a> </h1>
        ...
        <div class="col">
          <dl>
            <dt>Pieces</dt>
            <dd><a class="plain" href="/inventories/10251-1">2380</a></dd>
            <dt>Minifigs</dt>
            <dd><a class="plain" href="/minifigs/inset-10251-1">5</a></dd>
            ...
          </dl>
        </div>
        ...
      </div>
    </article>

We can see a few things by examining this code:

- The image for the set is stored in the `src` attribute of an `img` tag inside an `a` tag at the start of the set. We can use another CSS selector to fetch this value just like we did when we grabbed the name of each set.
- Getting the number of pieces is a little trickier. There’s a `dt` tag that contains the text `Pieces`, and then a `dd` tag that follows it which contains the actual number of pieces. We’ll use [XPath](https://en.wikipedia.org/wiki/XPath), a query language for traversing XML, to grab this, because it’s too complex to be represented using CSS selectors.
- Getting the number of minifigs in a set is similar to getting the number of pieces. There’s a `dt` tag that contains the text `Minifigs`, followed by a `dd` tag right after that with the number.

So, let’s modify the scraper to get this new information:

scraper.py

    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }

Save your changes and run the scraper again:

    scrapy runspider scraper.py

Now you’ll see that new data in the program’s output:

    Output2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': '5', 'pieces': '2380', 'name': 'Brick Bank', 'image': 'http://images.brickset.com/sets/small/10251-1.jpg?201510121127'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '1167', 'name': 'Volkswagen Beetle', 'image': 'http://images.brickset.com/sets/small/10252-1.jpg?201606140214'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '4163', 'name': 'Big Ben', 'image': 'http://images.brickset.com/sets/small/10253-1.jpg?201605190256'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': None, 'name': 'Winter Holiday Train', 'image': 'http://images.brickset.com/sets/small/10254-1.jpg?201608110306'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': None, 'name': 'XL Creative Brick Box', 'image': '/assets/images/misc/blankbox.gif'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '583', 'name': 'Creative Building Set', 'image': 'http://images.brickset.com/sets/small/10702-1.jpg?201511230710'}

Now let’s turn this scraper into a spider that follows links.

## Step 3 — Crawling Multiple Pages

We’ve successfully extracted data from that initial page, but we’re not progressing past it to see the rest of the results. The whole point of a spider is to detect and traverse links to other pages and grab data from those pages too.

You’ll notice that the top and bottom of each page has a little right carat (`>`) that links to the next page of results. Here’s the HTML for that:

    brickset.com/sets/year-2016<ul class="pagelength">
    
      ...
    
      <li class="next">
        <a href="http://brickset.com/sets/year-2017/page-2">&#8250;</a>
      </li>
      <li class="last">
        <a href="http://brickset.com/sets/year-2016/page-32">&#187;</a>
      </li>
    </ul>

As you can see, there’s a `li` tag with the class of `next`, and inside that tag, there’s an `a` tag with a link to the next page. All we have to do is tell the scraper to follow that link if it exists.

Modify your code as follows:

scraper.py

    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }
    
            NEXT_PAGE_SELECTOR = '.next a ::attr(href)'
            next_page = response.css(NEXT_PAGE_SELECTOR).extract_first()
            if next_page:
                yield scrapy.Request(
                    response.urljoin(next_page),
                    callback=self.parse
                )

First, we define a selector for the “next page” link, extract the first match, and check if it exists. The `scrapy.Request` is a value that we return saying “Hey, crawl this page”, and `callback=self.parse` says “once you’ve gotten the HTML from this page, pass it back to this method so we can parse it, extract the data, and find the next page.“

This means that once we go to the next page, we’ll look for a link to the next page there, and on that page we’ll look for a link to the next page, and so on, until we don’t find a link for the next page. This is the key piece of web scraping: finding and following links. In this example, it’s very linear; one page has a link to the next page until we’ve hit the last page, But you could follow links to tags, or other search results, or any other URL you’d like.

Now, if you save your code and run the spider again you’ll see that it doesn’t just stop once it iterates through the first page of sets. It keeps on going through all 779 matches on 23 pages! In the grand scheme of things it’s not a huge chunk of data, but now you know the process by which you automatically find new pages to scrape.

Here’s our completed code for this tutorial, using Python-specific highlighting:

scraper.py

    import scrapy
    
    
    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }
    
            NEXT_PAGE_SELECTOR = '.next a ::attr(href)'
            next_page = response.css(NEXT_PAGE_SELECTOR).extract_first()
            if next_page:
                yield scrapy.Request(
                    response.urljoin(next_page),
                    callback=self.parse
                )

## Conclusion

In this tutorial you built a fully-functional spider that extracts data from web pages in less than thirty lines of code. That’s a great start, but there’s a lot of fun things you can do with this spider. Here are some ways you could expand the code you’ve written. They’ll give you some practice scraping data.

1. Right now we’re only parsing results from 2016, as you might have guessed from the `2016` part of `http://brickset.com/sets/year-2016` — how would you crawl results from other years?
2. There’s a retail price included on most sets. How do you extract the data from that cell? How would you get a raw number out of it? **Hint** : you’ll find the data in a `dt` just like the number of pieces and minifigs. 
3. Most of the results have tags that specify semantic data about the sets or their context. How do we crawl these, given that there are multiple tags for a single set?

That should be enough to get you thinking and experimenting. If you need more information on Scrapy, check out [Scrapy’s official docs](https://scrapy.org/doc/). For more information on working with data from the web, see our tutorial on ["How To Scrape Web Pages with Beautiful Soup and Python 3”](how-to-scrape-web-pages-with-beautiful-soup-and-python-3).
