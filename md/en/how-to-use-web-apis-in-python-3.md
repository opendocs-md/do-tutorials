---
author: Brian King
date: 2017-08-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-web-apis-in-python-3
---

# How To Use Web APIs in Python 3

## Introduction

An API, or **A** pplication **P** rogram **I** nterface, enables developers to integrate one app with another. They expose some of a program’s inner workings in a limited way.

You can use APIs to get information from other programs or to automate things you normally do in your web browser. Sometimes you can use APIs to do things you just can’t do any other way. A surprising number of web properties offer web-based APIs alongside the more familiar website or mobile app, including Twitter, Facebook, GitHub, and DigitalOcean.

If you’ve worked your way through some tutorials on [how to code in Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-python-3), and you’re comfortable with Python’s syntax, structure, and some built-in [functions](how-to-define-functions-in-python-3), you can write Python programs that take advantage of your favorite APIs.

In this guide, you will learn how to use Python with the [DigitalOcean API](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwjttPKwlJbVAhVILyYKHSdOCDIQFggmMAA&url=https%3A%2F%2Fdevelopers.digitalocean.com%2F&usg=AFQjCNH6P3GhnE-YCtIHW0RfVz6-WOX--g) to retrieve information about your DigitalOcean account. Then we’ll look at how you can apply what you’ve learned to [GitHub’s API](https://developer.github.com/v3/).

When you’re finished, you’ll understand the concepts common across web APIs, and you’ll have a step-by-step process and working code samples that you can use to try out APIs from other services.

## Prerequisites

Before you begin this guide you’ll need the following:

- A local development environment for Python 3. You can follow [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) to configure everything you need.
- A text editor you are comfortable using. If you don’t already have a favorite, choose one with syntax highlighting. [Notepad++](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&sqi=2&ved=0ahUKEwjqr-mEq6LVAhUBjz4KHd8nAzEQFggiMAA&url=https%3A%2F%2Fnotepad-plus-plus.org%2F&usg=AFQjCNExci2YY1gy2cZYcnKLKfl2A9jWCg) for Windows, [BBEdit](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwil3PScq6LVAhWD6CYKHaWjD8oQFggmMAA&url=https%3A%2F%2Fwww.barebones.com%2Fproducts%2Fbbedit%2F&usg=AFQjCNEPJVqrxQA3XiwKthC8702r4oSf4A) for macOS, and Sublime Text or [Atom](https://atom.io/) for any platform are all good choices.
- A DigitalOcean account and API key. The first few paragraphs in [How To Use the DigitalOcean API v2](how-to-use-the-digitalocean-api-v2) show how to do this.

## Step 1 — Getting Familiar with an API

The first step in using a new API is to find the documentation, and get your bearings. The DigitalOcean API documentation starts at [https://developers.digitalocean.com/](https://developers.digitalocean.com/). To find APIs for other services, search for the name of the site and “API” — not all services promote them on their front pages.

Some services have _API wrappers_. An API wrapper is code that you install on your system to make the APIs easier to use in your chosen programming language. This guide doesn’t use any wrappers because they hide much of the inner workings of the APIs, and often don’t expose everything the API can do. Wrappers can be great when you want to get something done quickly, but having a solid understanding of what the APIs themselves can do will help you decide if the wrappers make sense for your goals.

First, look at the DigitalOcean API Introduction at [https://developers.digitalocean.com/documentation/v2/](https://developers.digitalocean.com/documentation/v2/) and try to understand only the basics about how to send a request, and what to expect in the response. At this point, you’re trying to learn only three things:

1. What does a request look like? Are they all just URLs? For more detailed requests, how is the data formatted? It’s usually [JSON](an-introduction-to-json) or querystring parameters like a web browser uses, but some use XML or a custom format.
2. What does a response look like? The API documents will show sample requests and responses. Are you going to get JSON, XML, or some other kind of response?
3. What goes into the request or response headers? Often, the request headers include your authentication token, and the response headers provide current information about your use of the service, such as how close you are to a rate limit.

The DigitalOcean API uses HTTP _methods_ (sometimes called _verbs_) to indicate whether you’re trying to read existing information, create new information, or delete something. This part of the documentation explains what methods are used, and for what purposes. Generally, a GET request is simpler than a POST, but by the time you’re done here, you won’t notice much difference.

The next section of the API documentation discusses how the server will respond to your requests. In general, a request either succeeds or it fails. When it fails, the cause is either something bad with the request, or a problem on the server. All of this information is communicated using [HTTP status codes](how-to-troubleshoot-common-http-error-codes), which are 3-digit numbers divided into categories.

- The `200` series means “success” — your request was valid, and the response is what logically follows from it.
- The `400` series means “bad request” — something was wrong with the request, so the server did not process it as you wanted it to. Common causes for HTTP `400`-level errors are badly-formatted requests and authentication problems.
- The `500` series means “server error” — your request may have been OK, but the server couldn’t give you a good response right now for reasons out of your control. These should be rare, but you need to be aware of the possibility so you can handle them in your code.

Your code should always check the HTTP status code for any response before trying to do anything with it. If you don’t do this, you’ll find yourself wasting time troubleshooting with incomplete information.

Now that you have a general idea of how to send a request, and what to look for in the response, it’s time to send that first request.

## Step 2 — Getting Information from the Web API

Your DigitalOcean account includes some administrative information that you may not have seen in the Web UI. An API can give you a different view of familiar information. Just seeing this alternate view can sometimes spark ideas about what you might want to do with an API, or reveal services and options you didn’t know about.

Let’s start by creating a project for our scripts. Create a new directory for the project called `apis`:

    mkdir apis

Then navigate into this new directory:

    cd apis

Create a new virtualenv for this project:

    python3 -m venv apis

Activate the virtualenv:

    source apis/bin/activate

Then install the [requests](http://docs.python-requests.org/en/master/) library, which we’ll use in our scripts to make HTTP requests in our scripts:

    pip install requests

With the environment configured, create a new Python file called `do_get_account.py` and open it in your text editor. Start this program off by [importing libraries](how-to-import-modules-in-python-3) for working with JSON and HTTP requests.

do\_get\_account.py

    import json
    import requests

These `import` statements load Python code that allow us to work with the JSON data format and the HTTP protocol. We’re using these libraries because we’re not interested in the details of how to send HTTP requests or how to parse and create valid JSON; we just want to use them to accomplish these tasks. All of our scripts in this tutorial will start like this.

Next, we want to set up some [variables](how-to-use-variables-in-python-3) to hold information that will be the same in every request. This saves us from having to type it over and over again, and gives us a single place to make updates in case anything changes. Add these lines to the file, after the `import` statements.

do\_get\_account.py

    ...
    api_token = 'your_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'

The `api_token` variable is a string that holds your DigitalOcean API token. Replace the value in the example with your own token. The `api_url_base` variable is the string that starts off every URL in the DigitalOcean API. We’ll append to it as needed later in the code.

Next, we need to set up the HTTP request headers the way the API docs describe. Add these lines to the file to set up a [dictionary](understanding-dictionaries-in-python-3) containing your request headers:

do\_get\_account.py

    ...
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}

This sets two headers at once. The `Content-Type` header tells the server to expect JSON-formatted data in the body of the request. The `Authorization` header needs to include our token, so we use Python’s string formatting logic to insert our `api_token` variable into the string as we create the string. We could have put the token in here as a literal string, but separating it makes several things easier down the road:

- If you need to replace the token, it’s easier to see where to do that when it’s a separate variable.
- If you want to share your code with someone, it’s easier to remove your API token, and easier for your friend to see where to put theirs.
- It’s self-documenting. If the API token is only used as a string literal, then someone reading your code may not understand what they’re looking at.

Now that we have these setup details covered, it’s time to actually send the request. Your inclination may be to just start creating and sending the requests, but there’s a better way. If you put this logic into a function that handles the sending of the request and reading the response, you’ll have to think a little more clearly about what you’re doing. You’ll also end up with code that makes testing and re-use more straightforward. That’s what we’re going to do.

This function will use the variables you created to send the request and return the account information in a Python dictionary.

In order to keep the logic clear at this early stage, we won’t do any detailed error handling yet, but we’ll add that in soon enough.

Define the function that fetches the account information. It’s always a good idea to name a function after what it does: This one gets account information, so we’ll call it `get_account_info`:

do\_get\_account.py

    ...
    def get_account_info():
    
        api_url = '{0}account'.format(api_url_base)
    
        response = requests.get(api_url, headers=headers)
    
        if response.status_code == 200:
            return json.loads(response.content.decode('utf-8'))
        else:
            return None

We build the value for `api_url` by using Python’s string formatting method similar to how we used it in the headers; we append the API’s base URL in front of the string `account` to get the URL `https://api.digitalocean.com/v2/account`, the URL that should return account information.

The `response` variable holds an object created by the Python `requests` [module](how-to-import-modules-in-python-3). This line sends the request to the URL we made with the headers we defined at the start of the script and returns the response from the API.

Next, we look at the response’s HTTP status code.

If it’s `200`, a successful response, then we use the `json` module’s `loads` function to load a string as JSON. The string we load is the content of the `response` object, `response.content`. The `.decode('utf-8')` part tells Python that this content is encoded using the UTF-8 character set, as all responses from the DigitalOcean API will be. The `json` module creates an object out of that, which we use as the return value for this function.

If the response was _not_ `200`, then we return `None`, which is a special value in Python that we can check for when we call this function. You’ll notice that we’re just ignoring any errors at this point. This is to keep the “success” logic clear. We will add more comprehensive error checking soon.

Now call this function, check to make sure it got a good response, and print out the details that the API returned:

do\_get\_account.py

    ...
    account_info = get_account_info()
    
    if account_info is not None:
        print("Here's your info: ")
        for k, v in account_info['account'].items():
            print('{0}:{1}'.format(k, v))
    
    else:
        print('[!] Request Failed')

`account_info = get_account_info()` sets the `account_info` variable to whatever came back from the call to `get_account_info()`, so it will be either the special value `None` or it will be the collection of information about the account.

If it is not `None`, then we print out each piece of information on its own line by using the `items()` method that all Python dictionaries have.

Otherwise (that is, if `account_info` is `None`), we print an error message.

Let’s pause for a minute here. This `if` statement with the double negative in it may feel awkward at first, but it is a common Python idiom. Its virtue is in keeping the code that runs on success very close to the [conditional](how-to-write-conditional-statements-in-python-3-2) instead of after handling error cases.

You can do it the other way if you prefer, and it may be a good exercise to actually write that code yourself. Instead of `if account_info is not None:` you might start with `if account_info is None:` and see how the rest falls into place.

Save the script and try it out:

    python do_get_account.py

The output will look something like this:

    OutputHere's your info: 
    droplet_limit:25
    email:sammy@digitalocean.com
    status:active
    floating_ip_limit:3
    email_verified:True
    uuid:123e4567e89b12d3a456426655440000
    status_message:

You now know how to retrieve data from an API. Next, we’ll move on to something a little more interesting — using an API to change data.

## Step 3 — Modifying Information on the Server

After practicing with a read-only request, it’s time to start making changes. Let’s explore this by using Python and the DigitalOcean API to add an SSH key to your DigitalOcean account.

First, take a look at the API documentation for SSH keys, available at [https://developers.digitalocean.com/documentation/v2/#ssh-keys](https://developers.digitalocean.com/documentation/v2/#ssh-keys).

The API lets you list the current SSH keys on your account, and also lets you add new ones. The request to get a list of SSH keys is a lot like the one to get account information. The response is different, though: unlike an account, you can have zero, one, or many SSH keys.

Create a new file for this script called `do_ssh_keys.py`, and start it off exactly like the last one. Import the `json` and `requests` modules so you don’t have to worry about the details of JSON or the HTTP protocol. Then add your DigitalOcean API token as a variable and set up the request headers in a dictionary.

do\_ssh\_keys.py

    import json
    import requests
    
    
    api_token = 'your_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}

The function we will create to get the SSH keys is similar to the one we used to get account information, but this time we’re going to handle errors more directly.

First, we’ll make the API call and store the response in a `response` response variable. The `api_url` won’t be the same as in the previous script though; this time it needs to point to `https://api.digitalocean.com/v2/account/keys`.

Add this code to the script:

do\_ssh\_keys.py

    ...
    def get_ssh_keys():
    
        api_url = '{0}account/keys'.format(api_url_base)
    
        response = requests.get(api_url, headers=headers)

Now let’s add some error handling by looking at the HTTP status code in the response. If it’s `200`, we’ll return the content of the response as a dictionary, just like we did before. If it’s anything else, we’ll print a helpful error message associated with the type of status code and then return `None`.

Add these lines to the `get_ssh_keys` function:

do\_ssh\_keys.py

    ...
    
        if response.status_code >= 500:
            print('[!] [{0}] Server Error'.format(response.status_code))
            return None
        elif response.status_code == 404:
            print('[!] [{0}] URL not found: [{1}]'.format(response.status_code,api_url))
            return None  
        elif response.status_code == 401:
            print('[!] [{0}] Authentication Failed'.format(response.status_code))
            return None
        elif response.status_code == 400:
            print('[!] [{0}] Bad Request'.format(response.status_code))
            return None
        elif response.status_code >= 300:
            print('[!] [{0}] Unexpected Redirect'.format(response.status_code))
            return None
        elif response.status_code == 200:
            ssh_keys = json.loads(response.content.decode('utf-8'))
            return ssh_keys
        else:
            print('[?] Unexpected Error: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))
        return None

This code handles six different error conditions by looking at the HTTP status code in the response.

- A code of `500` or greater indicates a problem on the server. These should be rare, and they are not caused by problems with the request, so we print only the status code.
- A code of `404` means “not found,” which probably stems from a typo in the URL. For this error, we print the status code and the URL that led to it so you can see why it failed.
- A code of `401` means the authentication failed. The most likely cause for this is an incorrect or missing `api_key`.
- A code in the `300` range indicates a redirect. The DigitalOcean API doesn’t use redirects, so this should never happen, but while we’re handling errors, it doesn’t hurt to check. A lot of bugs are caused by things the programmer thought should never happen.
- A code of `200` means the request was processed successfully. For this, we don’t print anything. We just return the ssh keys as a JSON object, using the same syntax we used in the previous script.
- If the response code was anything else we print the status code as an “unexpected error.”

That should handle any errors we’re likely to get from calling the API. At this point, we have either an error message and the `None` object, or we have success and a JSON object containing zero or more SSH keys. Our next step is to print them out:

do\_ssh\_keys.py

    ...
    
    ssh_keys = get_ssh_keys()
    
    if ssh_keys is not None:
        print('Here are your keys: ')
        for key, details in enumerate(ssh_keys['ssh_keys']):
            print('Key {}:'.format(key))
            for k, v in details.items():
                print(' {0}:{1}'.format(k, v))
    else:
        print('[!] Request Failed')

Because the response contains a [list](understanding-lists-in-python-3) (or array) of SSH keys, we want to iterate over the whole list in order to see all of the keys. We use Python’s `enumerate` method for this. This is similar to the `items` method available for dictionaries, but it works with lists instead.

We use `enumerate` and not just a [`for` loop](how-to-construct-for-loops-in-python-3#for-loops), because we want to be able to tell how far into the list we are for any given key.

Each key’s information is returned as a dictionary, so we use the same `for k,v in details.items():` code we used on the account information dictionary in the previous script.

Run this script and you’ll get a list of the SSH keys already on your account.

    python get_ssh_keys.py

The output will look something like this, depending on how many SSH keys you already have on your account.

    OutputHere are your keys: 
    Kcy 0:
      id:280518
      name:work
      fingerprint:96:f7:fb:9f:60:9c:9b:f9:a9:95:01:5c:5c:2c:d5:a0
      public_key:ssh-rsa AAAAB5NzaC1yc2cAAAADAQABAAABAQCwgr9Fzc/YTD/V2Ka5I52Rx4I+V2Ka5I52Rx4Ir5LKSCqkQ1Cub+... sammy@work
    Kcy 1:
      id:290536
      name:home
      fingerprint:90:1c:0b:ac:fa:b0:25:7c:af:ab:c5:94:a5:91:72:54
      public_key:ssh-rsa AAAAB5NzaC1yc2cAAAABJQAAAQcAtTZPZmV96P9ziwyr5LKSCqkQ1CubarKfK5r7iNx0RNnlJcqRUqWqSt... sammy@home

Now that you can list the SSH keys on your account, your last script here will be one that adds a new key to the list.

Before we can add a new SSH key, we need to generate one. For a fuller treatment of this step, take a look at the tutorial [How to Set Up SSH Keys](how-to-set-up-ssh-keys--2).

For our purposes, though, we just need a simple key. Execute this command to generate a new one on Linux, BSD, or MacOS. You can do this on an existing Droplet, if you like.

    ssh-keygen -t rsa

When prompted, enter the file to save the key and don’t provide a passphrase.

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (/home/sammy/.ssh/id_rsa): /home/sammy/.ssh/sammy 
    Created directory '/home/sammy/.ssh'.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /home/sammy/.ssh/sammy.
    Your public key has been saved in /home/sammy/.ssh/sammy.pub.
    ...

Take note of where the public key file was saved, because you’ll need it for the script.

Start a new Python script, and call it `add_ssh_key.py`, and start it off just like the others:

add\_ssh\_key.py

    
    import json
    import requests
    
    
    api_token = 'your_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}

We’ll use a function to make our request, but this one will be slightly different.

Create a function called `add_ssh_key` which will accept two arguments: the name to use for the new SSH key, and the filename of the key itself on your local system. The function will [read the file](how-to-handle-plain-text-files-in-python-3), and make an HTTP `POST` request, instead of a `GET`:

add\_ssh\_key.py

    ...
    
    def add_ssh_key(name, filename):
    
        api_url = '{0}account/keys'.format(api_url_base)
    
        with open(filename, 'r') as f:
            ssh_key = f.readline()
    
        ssh_key = {'name': name, 'public_key': ssh_key}
    
        response = requests.post(api_url, headers=headers, json=ssh_key)

The line `with open(filename, 'r') as f:` opens the file in read-only mode, and the line that follows reads the first (and only) line from the file, storing it in the `ssh_key` variable.

Next, we make a Python dictionary called `ssh_key` with the names and values that the API expects.

When we send the request, though, there’s a little bit more that’s new. It’s a `POST` rather than a `GET`, and we need to send the `ssh_key` in the body of the `POST` request, encoded as JSON. The `requests` module will handle the details for us; `requests.post` tells it to use the `POST` method, and including `json=ssh_key` tells it to send the `ssh_key` variable in the body of the request, encoded as JSON.

According to the API, the response will be HTTP `201` on success, instead of `200`, and the body of the response will contain the details of the key we just added.

Add the following error-handling code to the `add_ssh_key` function. It’s similar to the previous script, except this time we have to look for the code `201` instead of `200` for success:

add\_ssh\_key.py

    ...
        if response.status_code >= 500:
            print('[!] [{0}] Server Error'.format(response.status_code))
            return None
        elif response.status_code == 404:
            print('[!] [{0}] URL not found: [{1}]'.format(response.status_code,api_url))
            return None
        elif response.status_code == 401:
            print('[!] [{0}] Authentication Failed'.format(response.status_code))
            return None
        elif response.status_code >= 400:
            print('[!] [{0}] Bad Request'.format(response.status_code))
            print(ssh_key )
            print(response.content )
            return None
        elif response.status_code >= 300:
            print('[!] [{0}] Unexpected redirect.'.format(response.status_code))
            return None
        elif response.status_code == 201:
            added_key = json.loads(response.content)
            return added_key
        else:
            print('[?] Unexpected Error: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))
            return None

This function, like the previous ones, returns either `None` or the response content, so we use the same approach as before to check the result.

Next, call the function and process the result. Pass the path to your newly-created SSH key as the second argument:

add\_ssh\_key.py

    ...
    add_response = add_ssh_key('tutorial_key', '/home/sammy/.ssh/sammy.pub')
    
    if add_response is not None:
        print('Your key was added: ' )
        for k, v in add_response.items():
            print(' {0}:{1}'.format(k, v))
    else:
        print('[!] Request Failed')

Run this script and you’ll get a response telling you that your new key was added.

    python add_ssh_key.py 

The output will look something like this:

    OutputYour key was added: 
      ssh_key:{'id': 9458326, 'name': 'tutorial_key', 'fingerprint': '64:76:37:77:c8:c7:26:05:f5:7b:6b:e1:bb:d6:80:da', 'public_key': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUtY9aizEcVJ65/O5CE6tY8Xodrkkdh9BB0GwEUE7eDKtTh4NAxVjXc8XdzCLKtdMwfSg9xwxSi3axsVWYWBUhiws0YRxxMNTHCBDsLFTJgCFC0JCmSLB5ZEnKl+Wijbqnu2r8k2NoXW5GUxNVwhYztXZkkzEMNT78TgWBjPu2Tp1qKREqLuwOsMIKt4bqozL/1tu6oociNMdLOGUqXNrXCsOIvTylt6ROF3a5UnVPXhgz0qGbQrSHvCEfuKGZ1kw8PtWgeIe7VIHbS2zTuSDCmyj1Nw1yOTHSAqZLpm6gnDo0Lo9OEA7BSFr9W/VURmTVsfE1CNGSb6c6SPx0NpoN sammy@tutorial-test'}

If you forgot to change the “success” condition to look for HTTP `201` instead of `200`, you’ll see an error reported, but the key will still have been added. Your error handling would have told you that the status code was `201`. You should recognize that as a member of the `200` series, which indicates success. This is an example of how basic error handling can simplify troubleshooting.

Once you’ve successfully added the key with this script, run it again to see what happens when you try to add a key that’s already present.

The API will send back an HTTP `422` response, which your script will translate into a message saying “SSH Key is already in use on your account.”:

    Output[!] [422] Bad Request
    {'name': 'tutorial_key', 'public_key': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUtY9aizEcVJ65/O5CE6tY8Xodrkkdh9BB0GwEUE7eDKtTh4NAxVjXc8XdzCLKtdMwfSg9xwxSi3axsVWYWBUhiws0YRxxMNTHCBDsLFTJgCFC0JCmSLB5ZEnKl+Wijbqnu2r8k2NoXW5GUxNVwhYztXZkkzEMNT78TgWBjPu2Tp1qKREqLuwOsMIKt4bqozL/1tu6oociNMdLOGUqXNrXCsOIvTylt6ROF3a5UnVPXhgz0qGbQrSHvCEfuKGZ1kw8PtWgeIe7VIHbS2zTuSDCmyj1Nw1yOTHSAqZLpm6gnDo0Lo9OEA7BSFr9W/VURmTVsfE1CNGSb6c6SPx0NpoN sammy@tutorial-test'}
    b'{"id":"unprocessable_entity","message":"SSH Key is already in use on your account"}'
    [!] Request Failed

Now run your `get_ssh_keys.py` script again and you’ll see your newly-added key in the list.

With small modifications, these two scripts could be a quick way to add new SSH keys to your DigitalOcean account whenever you need to. Related functions in this API allow you to rename or delete a specific key by using its unique key ID or fingerprint.

Let’s look at another API and see how the skills you just learned translate.

## Step 4 — Working with a Different API

GitHub has an API, too. Everything you’ve learned about using the DigitalOcean API is directly applicable to using the GitHub API.

Get acquainted with the GitHub API the same way you did with DigitalOcean. Search for the [API documentation](https://developer.github.com/v3/), and skim the **Overview** section. You’ll see right away that the GitHub API and the DigitalOcean API share some similarities.

First, you’ll notice that there’s a common root to all of the API URLs: `https://api.github.com/`. You know how to use that as a variable in your code to streamline and reduce the potential for errors.

GitHub’s API uses JSON as its request and response format, just like DigitalOcean does, so you know how to make those requests and handle the responses.

Responses include information about rate limits in the HTTP response headers, using almost the same names and exactly the same values as DigitalOcean.

GitHub uses OAuth for authentication, and you can send your token in a request header. The details of that token are a little bit different, but the way it’s used is identical to how you’ve done it with DigitalOcean’s API.

There are some differences, too. GitHub encourages use of a request header to indicate the version of the API you want to use. You know how to add headers to requests in Python.

GitHub also wants you to use a unique `User-Agent` string in requests, so they can find you more easily if your code is causing problems. You’d handle this with a header too.

The GitHub API uses the same HTTP request methods, but also uses a new one called `PATCH` for certain operations. The GitHub API uses `GET` to read information, `POST` to add a new item, and `PATCH` to modify an existing item. This `PATCH` request is the kind of thing you’ll want to be on the lookout for in API documentation.

Not all GitHub API calls require authentication. For example, you can get a list of a user’s repositories without needing an access token. Let’s create a script to make that request and display the results.

We’ll simplify the error handling in this script and use only one statement to handle all possible errors. You don’t always need code to handle each kind of error separately, but it’s a good habit to do something with error conditions, if only to remind yourself that things don’t always go the way you expect them to.

Create a new file called `github_list_repos.py` in your editor and add the following content, which should look pretty familiar:

github\_list\_repos.py

    import json
    import requests
    
    
    api_url_base = 'https://api.github.com/'
    headers = {'Content-Type': 'application/json',
               'User-Agent': 'Python Student',
               'Accept': 'application/vnd.github.v3+json'}
    

The imports are the same ones we’ve been using. The `api_url_base` is where all GitHub APIs begin.

The headers include two of the optional ones GitHub mentions in their overview, plus the one that says we’re sending JSON-formatted data in our request.

Even though this is a small script, we’ll still define a function in order to keep our logic modular and encapsulate the logic for making the request. Often, your small scripts will grow into larger ones, so it’s helpful to be diligent about this. Add a function called `get_repos` that accepts a username as its argument:

github\_list\_repos.py

    
    ...
    def get_repos(username):
    
        api_url = '{}orgs/{}/repos'.format(api_url_base, username)
    
        response = requests.get(api_url, headers=headers)
    
        if response.status_code == 200:
            return (response.content)
        else:
            print('[!] HTTP {0} calling [{1}]'.format(response.status_code, api_url))
            return None
    

Inside the function, we build the URL out of the `api_url_base`, the name of the user we’re interested in, and the static parts of the URL that tell GitHub we want the repository list. Then we check the response’s HTTP Status Code to make sure it was `200` (success). If it was successful, we return the response content. If it wasn’t, then we print out the actual Status Code, and the URL we built so we’ll have an idea where we may have gone wrong.

Now, call the function and pass in the GitHub username you want to use. We’ll use `octokit` for this example. Then print the results to the screen:

github\_list\_repos.py

    
    ...
    repo_list = get_repos('octokit')
    
    if repo_list is not None:
        print(repo_list)
    else:
        print('No Repo List Found')

Save the file and run the script to see the repositories for the user you specified.

    python github_list_repos.py

You’ll see a lot of data in the output because we haven’t parsed the response as JSON in this example, nor have we filtered the results down to specific keys. Use what you’ve learned in the other scripts to do that. Look at the results you’re getting and see if you can print out the repository name.

Once nice thing about these GitHub APIs is that you can access the requests you don’t need authentication for directly in your web browser, This lets you compare responses to what you’re seeing in your scripts. Try visiting [https://api.github.com/orgs/octokit/repos](https://api.github.com/orgs/octokit/repos) in your browser to see the response there.

By now, you know how to read the documentation and write the code necessary to send more specific requests to support your own goals with the GitHub API.

You can find the completed code for all of the examples in this tutorial in [this repository on GitHub](https://github.com/do-community/python3_web_api_tutorial).

## Conclusion

In this tutorial, you learned how to use web APIs for two different services with slightly different styles. You saw the importance of including error handling code to make debugging easier and scripts more robust. You used the Python modules `requests` and `json` to insulate you from the details of those technologies and just get your work done, and you encapsulated the request and response processing in a function to make your scripts more modular.

And what’s more, you now have a repeatable process to follow when learning any new web API:

1. Find the documentation and read the introduction to understand the fundamentals of how to interact with the API.
2. Get an authentication token if you need one, and write a modular script with basic error handling to send a simple request, respond to errors, and process the response.
3. Create the requests that will get you the information that you want from the service.

Now, cement this newly-gained knowledge and find another API to use, or even another feature of one of the APIs you used here. A project of your own will help solidify what you’ve learned here.
