---
author: Lisa Tagliaferri
date: 2016-11-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-a-twitter-app
---

# How To Create a Twitter App

## Introduction

Having access to the Twitter API can help you manage your social media accounts, and allow you to mine social media for data. This can be useful for brand promotion if you represent a business or an organization, and it can be enjoyable and entertaining for individual users and hobbyist programmers.

In this article, we will outline the steps necessary for you to create a Twitter application.

We’ll then build a script in Python that uses the Tweepy library to make use of the Twitter API.

### Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- A [Twitter](https://twitter.com/) account with a valid phone number, which you can add via the **[Mobile](https://twitter.com/settings/add_phone)** section of your **Settings** when you’re logged in
- A Python programming environment set up; this can either be on your [local machine](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) or on a [server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server)

## Step 1 — Create Your Twitter Application

Let’s go through the process of creating a Twitter application and retrieving your API access keys and tokens. These tokens are what will allow you to authenticate any applications you develop that work with Twitter. As mentioned in the prerequisites, you’ll need a valid phone number in order to create applications using Twitter.

Open up your browser and visit [https://apps.twitter.com/](https://apps.twitter.com/) then log in using your Twitter account credentials. Once logged in, click the button labeled **Create New App**.

![Create New Twitter App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter1.png)

You will now be redirected to the application creation page.

![Fill out Twitter application details](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter2.png)

On this page, you’ll fill out the required fields.

**Note:** The name that you provide for your app must be unique to your particular app. You cannot use the name as shown here since it already exists.

- Name: DigitalSeaBot-example-app
- Description: My example application.
- Website: [https://my.example.placeholder](https://my.example.placeholder)

Read the [Twitter Developer Agreement](https://dev.twitter.com/overview/terms/agreement-and-policy). If you agree to continue at this point, click the checkbox next to the line that reads, **Yes, I have read and agree to the Twitter Developer Agreement.**

Once you click the **Create your Twitter application** button at the bottom of the page, you’ll receive a confirmation page.

![Twitter application creation confirmation page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter3.png)

After successfully creating your application, you will be redirected to your application’s **Details** page, which provides you with some general information about your app.

## Step 2 — Modify Your Application’s Permission Level and Generate Your Access Tokens

From the **Details page** , let’s navigate over to the **Permissions** page to ensure that we have the appropriate access level to generate our application keys.

By default, your Twitter app should have Read and Write access. If this is not the case, modify your app to ensure that you have Read and Write access. This will allow your application to post on your behalf.

![Twitter application permissions](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter4.png)

After updating your application’s permissions to allow posting, click the tab labeled **Keys and Access Tokens**. This will take you to a page that lists your Consumer Key and Consumer Secret, and also will allow you to generate your Access Token and Access Token Secret. These are necessary to authenticate our client application with Twitter.

Click the button labeled **Create my access token** under the Access Token heading to generate your Access Token and Access Token Secret.

![Twitter access token creation](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter5.png)

Now you will now have an Access Token and an Access Token Secret.

![Twitter application settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter6.png)

On the page you’re redirected to, you’ll also see the application’s Access Level, your username as the Owner, and your Owner ID.

## Step 3 — Install Tweepy

You can use a variety of programming languages and associated packages to make use of the Twitter API. To test that our Twitter app set-up was successful, we’ll be using Python and the Tweepy package to run a script that outputs a string to our Twitter account.

Tweepy is an open-source and easy-to-use library that allows your Python programming projects to access the Twitter API.

In this step, we’ll use pip to install Tweepy.

Make sure you’re in your Python 3 programming environment and create a new directory or change directories as desired to keep your programming files organized. For our example, we’ll use the directory twitter.

Before installing Tweepy, let’s first ensure that pip is up-to-date:

    pip install --upgrade pip

Once any updates are completed, we can go on to install Tweepy with pip:

    pip install tweepy

With Tweepy installed, we can go on to creating our Python Twitter program.

## Step 4 — Create a Python Application that Interacts with Twitter

After successfully creating your Twitter application and generating the necessary keys and tokens, you are now ready to create your client application for posting to your timeline.

Create a new Python program file called `helloworld.py` with your favorite text editor. We’ll be using nano as an example:

    nano helloworld.py

Now, let’s construct our Python script. First, we’ll need to import the Tweepy library with an import statement:

helloworld.py

    import tweepy

Next, we’ll be making [variables](how-to-use-variables-in-python-3) for each key, secret, and token that we generated. Replace the items in single quotes with your unique strings from the Twitter apps website (and keep the single quotes).

helloworld.py

    import tweepy
    
    consumer_key = 'your_consumer_key'
    consumer_secret = 'your_consumer_secret'
    access_token = 'your_access_token'
    access_token_secret = 'your_access_token_secret'

We’ll next be creating an OAuthHandler instance into which we’ll pass our consumer token and secret. [OAuth](an-introduction-to-oauth-2) — which works over HTTP and authorizes devices, APIs, servers, and applications — is a standard that provides secure and delegated access. We’ll also be setting the access tokens and integrating with the API.

helloworld.py

    import tweepy
    
    consumer_key = 'your_consumer_key'
    consumer_secret = 'your_consumer_secret'
    access_token = 'your_access_token'
    access_token_secret = 'your_access_token_secret'
    
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)
    api = tweepy.API(auth)

Finally, at the bottom of our program, let’s have Tweepy update our status. We’ll create a variable called `tweet` and pass this variable to the `api.update_status()` method. In the method we’ll pass `status=tweet`.

helloworld.py

    import tweepy
    
    # Create variables for each key, secret, token
    consumer_key = 'your_consumer_key'
    consumer_secret = 'your_consumer_secret'
    access_token = 'your_access_token'
    access_token_secret = 'your_access_token_secret'
    
    # Set up OAuth and integrate with API
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)
    api = tweepy.API(auth)
    
    # Write a tweet to push to our Twitter account
    tweet = 'Hello, world!'
    api.update_status(status=tweet)

We can now save the file and run the script:

    python helloworld.py

Once you run the program, check your Twitter account.

![Twitter status updated](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/CreateTwitterApp/twitter7.png)

The status is posted to your account’s timeline and you have successfully configured your Twitter application and authenticated using Tweepy!

## Conclusion

By following this tutorial, you were able to set up a Twitter application tied to your Twitter username. Once setting up the application and collecting our Consumer Key and Consumer Secret, and generating our Access Token and Access Token Secret, we authenticated a Python 3 application to use it through the open-source Tweepy library.

If you’re not a Python developer, there are many other programming languages and libraries that you can use to make use of the Twitter API. The Twitter Developers website maintains a [list of libraries](https://dev.twitter.com/resources/twitter-libraries) that support the current Twitter API.
