---
author: Michelle Morales
date: 2017-01-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-language-data-in-python-3-using-the-natural-language-toolkit-nltk
---

# How To Work with Language Data in Python 3 using the Natural Language Toolkit (NLTK)

## Introduction

Text-based communication has become one of the most common forms of expression. We email, text message, tweet, and update our statuses on a daily basis. As a result, unstructured text data has become extremely common, and analyzing large quantities of text data is now a key way to understand what people are thinking.

Tweets on Twitter help us find trending news topics in the world. Reviews on Amazon help users purchase the best-rated products. These examples of organizing and structuring knowledge represent Natural Language Processing (NLP) tasks.

NLP is a field of computer science that focuses on the interaction between computers and humans. NLP techniques are used to analyze text, providing a way for computers to understand human language. A few examples of NLP applications include automatic summarization, topic segmentation, and sentiment analysis.

This tutorial will provide an introduction to using the [Natural Language Toolkit (NLTK)](http://www.nltk.org/): an NLP tool for Python.

## Prerequisites

For this tutorial, you should have Python 3 installed, as well as a local programming environment set up on your computer. If this is not the case, you can get set up by following the [appropriate installation and set up guide for your operating system](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3).

To make the most use of this tutorial, you should have some familiarity with the [Python programming language](https://www.digitalocean.com/community/tags/python?type=tutorials).

## Step 1 — Importing NLTK

Before we begin working in Python, let’s make sure that the NLTK module is installed. On the command line, check for NLTK by running the following command:

    python -c "import nltk"

**If NLTK is installed** , this command will complete with no error. Now, let’s make sure you have the latest version installed:

    python -c "import nltk; print(nltk. __version__ )"

You should have version 3.2.1 installed, since we’ll use NLTK’s Twitter package that requires this version.

**If NLTK is not installed** , you will receive an error message:

    OutputTraceback (most recent call last): File "<string>", line 1, in <module> ImportError: No module named 'nltk'

The error message indicates that NLTK is not installed, so download the library using `pip`:

    pip install nltk

Next, we will download the data and NLTK tools we will be working with in this tutorial.

## Step 2 — Downloading NLTK’s Data and Tagger

In this tutorial, we will use a Twitter corpus that we can download through NLTK. Specifically, we will work with NLTK’s `twitter_samples` corpus. Let’s download the corpus through the command line, like so:

    python -m nltk.downloader twitter_samples

If the command ran successfully, you should receive the following output:

    Output[nltk_data] Downloading package twitter_samples to
    [nltk_data] /Users/sammy/nltk_data...
    [nltk_data] Unzipping corpora/twitter_samples.zip.

Next, download the part-of-speech (POS) tagger. _POS tagging_ is the process of labelling a word in a text as corresponding to a particular POS tag: nouns, verbs, adjectives, adverbs, etc. In this tutorial, we will specifically use NLTK’s `averaged_perceptron_tagger`. The average perceptron tagger uses the perceptron algorithm to predict which POS tag is most likely given the word. Let’s download the tagger, like so:

    python -m nltk.downloader averaged_perceptron_tagger

If the command ran successfully, you should receive the following output:

    Output[nltk_data] Downloading package averaged_perceptron_tagger to
    [nltk_data] /Users/sammy/nltk_data...
    [nltk_data] Unzipping taggers/averaged_perceptron_tagger.zip.

Let’s double check that the corpus downloaded correctly. In your terminal, open up the Python interactive environment:

    python

In Python’s interactive environment, import the `twitter_samples` corpus:

    from nltk.corpus import twitter_samples

NLTK’s twitter corpus currently contains a sample of 20,000 tweets retrieved from the Twitter Streaming API. Full tweets are stored as line-separated [JSON](an-introduction-to-json). We can see how many JSON files exist in the corpus using the `twitter_samples.fileids()` method:

    twitter_samples.fileids()

Our output will look like this:

    Output[u'negative_tweets.json', u'positive_tweets.json', u'tweets.20150430-223406.json']

Using those file IDs we can then return the tweet [strings](an-introduction-to-working-with-strings-in-python-3):

    twitter_samples.strings('tweets.20150430-223406.json')

Running this will return a lot of output. It will generally look like this:

    Output[u'RT @KirkKus: Indirect cost of the UK being in the EU is estimated to be costing Britain \xa3170 billion per year! #BetterOffOut #UKIP'...]

We now know our corpus was downloaded successefully. So let’s exit the Python interactive environment with the shortcut `ctrl` + `D`.

Now that we have access to the `twitter_samples` corpus, we can begin writing a script to process tweets.

The goal of our script will be to count how many adjectives and nouns appear in the positive subset of the `twitter_samples` corpus:

- A **noun** , in its most basic definition, is usually defined as a person, place, or thing. For example, a _movie_, a _book_, and a _burger_ are all nouns. Counting nouns can help determine how many different topics are being discussed.

- An **adjective** is a word that modifies a noun (or pronoun), for example: a _horrible_ movie, a _funny_ book, or a _delicious_ burger. Counting adjectives can determine what type of language is being used, i.e. opinions tend to include more adjectives than facts.

You could later extend this script to count positive adjectives (_great_, _awesome_, _happy_, etc.) versus negative adjectives (_boring_, _lame_, _sad_, etc.), which could be used to analyze the sentiment of tweets or reviews about a product or movie, for example. This script provides data that can in turn inform decisions related to that product or movie.

We will begin our script in the next step.

## Step 3 — Tokenizing Sentences

First, in the text editor of your choice, create the script that we’ll be working with and call it `nlp.py`.

In our file, let’s first import the corpus. Then let’s create a `tweets` [variable](how-to-use-variables-in-python-3) and assign to it the [list](understanding-lists-in-python-3) of tweet strings from the `positive_tweets.json` file.

nlp.py

    from nltk.corpus import twitter_samples
    
    tweets = twitter_samples.strings('positive_tweets.json')

When we first load our list of tweets, each tweet is represented as one string. Before we can determine which words in our tweets are adjectives or nouns, we first need to tokenize our tweets.

**Tokenization** is the act of breaking up a sequence of strings into pieces such as words, keywords, phrases, symbols and other elements, which are called _tokens_. Let’s create a new variable called `tweets_tokens`, to which we will assign the tokenized list of tweets:

nlp.py

    from nltk.corpus import twitter_samples
    
    tweets = twitter_samples.strings('positive_tweets.json')
    tweets_tokens = twitter_samples.tokenized('positive_tweets.json')

This new variable, `tweets_tokens`, is a list where each element in the list is a list of tokens. Now that we have the tokens of each tweet we can tag the tokens with the appropriate POS tags.

## Step 4 — Tagging Sentences

In order to access NLTK’s POS tagger, we’ll need to import it. All [import statements](how-to-import-modules-in-python-3) must go at the beginning of the script. Let’s put this new import under our other import statement.

nlp.py

    from nltk.corpus import twitter_samples
    from nltk.tag import pos_tag_sents
    
    tweets = twitter_samples.strings('positive_tweets.json')
    tweets_tokens = twitter_samples.tokenized('positive_tweets.json')

Now, we can tag each of our tokens. NLTK allows us to do it all at once using: `pos_tag_sents()`. We are going to create a new variable ` tweets_tagged`, which we will use to store our tagged lists. This new line can be put directly at the end of our current script:

    tweets_tagged = pos_tag_sents(tweets_tokens)

To get an idea of what tagged tokens look like, here is what the first element in our tweets\_tagged list looks like:

    [(u'#FollowFriday', 'JJ'), (u'@France_Inte', 'NNP'), (u'@PKuchly57', 'NNP'), (u'@Milipol_Paris', 'NNP'), (u'for', 'IN'), (u'being', 'VBG'), (u'top', 'JJ'), (u'engaged', 'VBN'), (u'members', 'NNS'), (u'in', 'IN'), (u'my', 'PRP$'), (u'community', 'NN'), (u'this', 'DT'), (u'week', 'NN'), (u':)', 'NN')]

We can see that our tweet is represented as a list and for each token we have information about its POS tag. Each token/tag pair is saved as a [tuple](understanding-tuples-in-python-3).

In NLTK, the abbreviation for **adjective** is `JJ`.

The NLTK tagger marks **singular nouns** (`NN`) with different tags than **plural nouns** (`NNS`). To simplify, we will only count singular nouns by keeping track of the `NN` tag.

In the next step we will count how many times `JJ` and `NN` appear throughout our corpus.

## Step 5 — Counting POS Tags

We will keep track of how many times `JJ` and `NN` appear using an accumulator (count) variable, which we will continuously add to every time we find a tag. First let’s create our count at the bottom of our script, which we will first set to zero.

nlp.py

    from nltk.corpus import twitter_samples
    from nltk.tag import pos_tag_sents
    
    tweets = twitter_samples.strings('positive_tweets.json')
    tweets_tokens = twitter_samples.tokenized('positive_tweets.json')
    
    JJ_count = 0
    NN_count = 0

After we create the variables, we’ll create two [`for` loops](how-to-construct-for-loops-in-python-3). The **first loop** will iterate through each tweet in the list. The **second loop** will iterate through each token/tag pair in each tweet. For each pair, we will look up the tag using the appropriate tuple index.

We will then check to see if the tag matches either the string `'JJ'` or `'NN'` by using [conditional statements](how-to-write-conditional-statements-in-python-3-2). If the tag is a match we will add (`+= 1`) to the appropriate accumulator.

nlp.py

    from nltk.corpus import twitter_samples
    from nltk.tag import pos_tag_sents
    
    tweets = twitter_samples.strings('positive_tweets.json')
    tweets_tokens = twitter_samples.tokenized('positive_tweets.json')
    
    JJ_count = 0
    NN_count = 0
    
    for tweet in tweets_tagged:
        for pair in tweet:
            tag = pair[1]
            if tag == 'JJ':
                JJ_count += 1
            elif tag == 'NN':
                NN_count += 1

After the two loops are complete, we should have the total count for adjectives and nouns in our corpus. To see how many adjectives and nouns our script found, we’ll add print statements to the end of the script.

nlp.py

    ...
    
    for tweet in tweets_tagged:
        for pair in tweet:
            tag = pair[1]
            if tag == 'JJ':
                JJ_count += 1
            elif tag == 'NN':
                NN_count += 1
    
    print('Total number of adjectives = ', JJ_count)
    print('Total number of nouns = ', NN_count)

At this point, our program will be able to output the number of adjectives and nouns that were found in the corpus.

## Step 6 — Running the NLP Script

Save your `nlp.py` file and run it to see how many adjectives and nouns we find:

    python nlp.py

Be patient, it might take a few seconds for the script to run. If all went well, when we run our script, we should get the following output:

    OutputTotal number of adjectives = 6094
    Total number of nouns = 13180

If your output looks the same, it means you have successfully completed this tutorial. Congratulations!

## Finished Code

For our finished code, we should add some comments to make it easier for others and our future self to follow. Our script looks like this:

nlp.py

    # Import data and tagger
    from nltk.corpus import twitter_samples
    from nltk.tag import pos_tag_sents
    
    # Load tokenized tweets
    tweets_tokens = twitter_samples.tokenized('positive_tweets.json')
    
    # Tag tagged tweets
    tweets_tagged = pos_tag_sents(tweets_tokens)
    
    # Set accumulators
    JJ_count = 0
    NN_count = 0
    
    # Loop through list of tweets
    for tweet in tweets_tagged:
        for pair in tweet:
            tag = pair[1]
            if tag == 'JJ':
                JJ_count += 1
            elif tag == 'NN':
                NN_count += 1
    
    # Print total numbers for each adjectives and nouns
    print('Total number of adjectives = ', JJ_count)
    print('Total number of nouns = ', NN_count)

We have used the Twitter corpus downloaded through NLTK in this tutorial, but you can read in your own data. To familiarize yourself with reading files in Python, check out our guide on [“How To Handle Plain Text Files in Python 3"](how-to-handle-plain-text-files-in-python-3).

You may also be interested in working with real Twitter data. You can learn more about accessing the Twitter API by reading “[How To Create a Twitter App](how-to-create-a-twitter-app).” You can then check out our guide on [“How To Create a Twitterbot with Python 3 and the Tweepy Library”](how-to-create-a-twitterbot-with-python-3-and-the-tweepy-library), which shows how to use the Tweepy Python library to collect tweets which include a certain hash tag. The data you collect can then be analyzed with NLTK.

From here, you can extend the code to count both plural and singular nouns, do sentiment analysis of adjectives, or visualize your data with [Python and matplotlib](how-to-plot-data-in-python-3-using-matplotlib).

## Conclusion

In this tutorial, you learned some Natural Language Processing techniques to analyze text using the NLTK library in Python. Now you can download corpora, tokenize, tag, and count POS tags in Python. You can utilize this tutorial to facilitate the process of working with your own text data in Python.
