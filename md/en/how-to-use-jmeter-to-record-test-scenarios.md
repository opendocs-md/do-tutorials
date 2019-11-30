---
author: Mitchell Anicas
date: 2014-07-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-jmeter-to-record-test-scenarios
---

# How To Use JMeter To Record Test Scenarios

## Introduction

In this tutorial, we will teach you how to set up and use the Apache JMeter HTTP(S) Test Script Recorder to record HTTP requests. Recording HTTP requests is a great way to building test plans, and can be useful in creating tests that closely mimic a normal user’s behavior.

This tutorial assumes that you have a basic knowledge of Apache JMeter. If you are new to JMeter, here is another tutorial that can get you started: [How To Use Apache JMeter To Perform Load Testing on a Web Server](how-to-use-apache-jmeter-to-perform-load-testing-on-a-web-server)

## Prerequisites

Here is a list of the software that this tutorial requires:

- Apache JMeter: [Download binaries here](http://jmeter.apache.org/download_jmeter.cgi)
- Java 6 or later: [Oracle Java available here](https://www.java.com/en/download/help/download_options.xml) 
- Mozilla Firefox: [Download here](http://www.mozilla.org/en-US/firefox/new/)

For reference, when writing this tutorial, we used the following software versions:

- Oracle Java 7 update 60, 64-bit
- JMeter 2.11
- Firefox 30.0

## Start Building a Test Plan

First, start JMeter. Then let’s start building a test plan. If you already have a test plan that you would like to start with, skip this section and move on to adding a _Recording Controller_ to your Thread Group (the next section).

Minimally, we will want to add a Thread Group and HTTP Request Defaults. Let’s get start by adding a Thread Group.

### Add a Thread Group

Add a _Thread Group_ to _Test Plan_:

1. Right-click on _Test Plan_
2. Mouse over _Add \>_
3. Mouse over _Threads (Users) \>_
4. Click on _Thread Group_

Set the Thread Group properties with the following values:

- **Number of Threads (users)**: Set this to **50**
- **Ramp-Up Period (in seconds)**: Set this to **10**.
- **Loop Count** : Leave this set to **1**.

![Thread Group Properties](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/thread_group1.png)

### Add an HTTP Request Defaults

Now let’s add _HTTP Request Defaults_ to _Thread Group_:

1. Select _Thread Group_, then right-click it
2. Mouse over _Add \>_
3. Mouse over _Config Element \>_
4. Click on _HTTP Request Defaults_

In HTTP Request Defaults, under the Web Server section, fill in the _Server Name or IP_ field with the name or IP address of the web server you want to test.

![HTTP Request Defaults](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/http_request_defaults.png)

### Add an HTTP Cookie Manager

If your web server uses cookies, you can add support for cookies by adding an HTTP Cookie Manager to the Thread Group:

1. Select _Thread Group_, then right-click it
2. Mouse over _Add \>_
3. Mouse over _Config Element \>_
4. Click on _HTTP Cookie Manager_

## Add a Recording Controller

Now let’s add a _Recording Controller_ to _Thread Group_:

1. Select _Thread Group_, then right-click it
2. Mouse over _Add \>_
3. Mouse over _Logic Controller \>_
4. Click on _Recording Controller_

The Recording Controller is where recorded HTTP Request samplers will be created. The next step is to set up an HTTP(S) Test Script Recorder.

## Add HTTP(S) Test Script Recorder

Now let’s add an _HTTP(S) Test Script Recorder_ to the _WorkBench_:

1. Select _WorkBench_, then right-click it
2. Mouse over _Add \>_
3. Mouse over _Non-Test Elements \>_
4. Click on _HTTP(S) Test Script Recorder_

**Note:** Items that are added to the WorkBench do not get saved with the rest of the test plan. If you want to save your WorkBench, right-click on _WorkBench_, then click _Save Selection As…_, and save it to your desired location. After it is saved, you may add it to any test plan that you have open by using the “Merge” menu item, and selecting your saved WorkBench.

### Port Setting

The default port that the HTTP(S) Test Script Recorder proxy will run on is `8080`. This can be changed by changing the `Port` setting under _Global Settings_.

### Including or Excluding URL Patterns (Optional)

In the HTTP(S) Script Recorder, you may add URL Patterns, written as regular expressions, to include or exclude when you record. This can be useful to either include only the types of content you want to request (e.g. \*.html, \*.php, etc) or to exclude the types of content you do not want to request (e.g. \*.jpg, \*.png, \*.js, etc).

To add a URL Pattern, click the “Add” button under the _URL Patterns to Include_ or _URL Patterns to Exclude_ section, then click on the top of the white area in the section. You should now be able to type in a pattern. Repeat the process to add more patterns.

Example: URL Patterns for webpages

    .*\.html
    .*\.php
    .*\.htm

Example: URL Patterns for images

    .*\.png
    .*\.jpg
    .*\.gif

Here is a screenshot of the URL Patterns to Exclude for excluding images:

![URL Patterns to Exclude Images](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/exclude_images.png)

### Adding Items to the Script Recorder (Optional)

Adding JMeter items to a the HTTP(S) Test Script Recorder will make recorded requests inherit the added item. For example, if we add a _Timer_ item to the Script Recorder, the Timer will be added to each HTTP Request that is recorded. When the test is run, the timer will cause each test thread to wait before performing the HTTP Request.

Let’s add a _Constant Timer_ to _HTTP(S) Test Script Recorder_, as an example:

1. Select _HTTP(S) Test Script Recorder_, then Right-click it
2. Mouse over _Add \>_
3. Mouse over _Timers \>_
4. Click on _Constant Timer_

You may configure the thread delay to whatever you desire.

![Constant Timer](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/constant_timer.png)

Suppose that you want to simulate a user clicking on a different page every 2 seconds. Setting the thread delay to 2000 ms will accomplish this by adding a 2 second delay to each HTTP Request that is recorded.

This is just one example of how you can add items to the Script Recorder to help create a test plan that performs the tests that you desire.

## Start Recording

Clicking on the “Start” button, on the bottom of the Script Recorder window, will start the JMeter proxy server which will be used to intercept and record browser requests. Click on the Start button (of the recorder) now.

The first time you attempt to run the recorder, it will display an error saying that it can’t start because a certificate does not exist. Click OK, then click Start a second time. You should see a message that says that a temporary certificate named _ApacheJMeterTemporaryRootCA.crt_ has been created in JMeter bin directory. Click OK and continue.

![Temporary Certificate Created](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/temp_cert.png)

**Note:** If you browser already uses a proxy, then you need to configure JMeter to use that proxy before starting JMeter, using the command-line options -H and -P.

## Configure Firefox To Use JMeter Proxy

We will use Firefox as our browser when using the JMeter HTTP(S) Test Script Recorder because, unlike Chrome and some other browsers, it does allows you to override system-wide configuration for its proxy settings.

Configure Firefox to use localhost (127.0.0.1) on port 8080 as its proxy for all traffic by following these steps:

1. Open Firefox
2. Go to the Preferences menu
3. Click on the Advanced tab
4. Then Network tab
5. In the “Connection” section, click on “Settings…”
6. Select the “Manual proxy configuration” radio button
7. Set HTTP Proxy to “localhost” and Port to “8080”
8. Check “Use this proxy server for all protocols”
9. Click OK and exit the Preferences menu

**Note:** When Firefox is configured to use JMeter’s Script Recorder as a proxy, it will only work properly if the Script Recorder is running.

## Recording HTTP Requests

Now that our test plan’s HTTP(S) Test Script Recorder is running, and Firefox is configured to use it as a proxy, the HTTP requests that Firefox sends will be recorded. Let’s test it out.

In Firefox, go to your server’s homepage (the same server that you configured in your JMeter HTTP Request Defaults):

    http://your_domain.com/

Now there should be a little triangle next to your _Recording Controller_. Click on it to expand and show the requests that it has recorded. You should see the HTTP requests that were recorded, depending on which URL Patterns you have included and excluded. Feel free to browse your site to record more requests.

Here is an example of what was recorded when visiting the homepage of a WordPress site (with no URL Patterns set):

![Recorded HTTP Requests](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jmeter/no_patterns.png)

As you can see, a lot of requests were created. You may refine the list of HTTP requests by simply deleting unwanted entries here.

If you do not see any entries under your Recording Controller, you will want to review your URL Patterns in the HTTP(S) Test Script Recorder (Hint: Remove all includes and excludes to record everything).

Once you are done recording, click the “Stop” button at the bottom of the HTTP(S) Test Script Recorder window. Note that Firefox will no longer be able to reach any pages (because it is configured to use port 8080 as a proxy)–configure it to use “No proxy” if you want to function normally.

## Run Your Test Plan

Once you are happy with the test plan you have recorded, save it, then run it. It will function exactly like a manually created test, so you can configure it, delete, and add items to make it match your desired test case more closely.

## Conclusion

Now that you are able to use the HTTP(S) Test Script Recorder to assist the creation of JMeter test plans, you should have an easier time creating test plans that mimic realistic scenarios. Feel free to explore the recorded requests in your Recording Controller to learn more about the kinds of requests that are made when users browser your web server.

Good Luck!
