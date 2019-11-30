---
author: Etel Sverdlov
date: 2012-07-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_rewrite
---

# How To Set Up Mod_Rewrite

### About Mod\_Rewrite

Think about the last time you visited some shopping website, looking for that one specific thing you needed to buy. When you finally reached the page, the URL most likely looked something like this:

    gizmo.com/latest\_and\_greatest/specific\_gadgets/exactly\_what\_youre\_looking\_for

This is not because this website took the time to set up every single directory you would need to make your purchase, but because of a handy module called Mod\_Rewrite. Mod\_Rewrite allows you to make custom and simplified URLs as needed. In reality, the actual URL may have looked closer to this:

    http://www.gizmo.com/gp/itemB004RYVI0Q/ref=as\_li\_ss\_tl?

This tutorial will go over Activating Mod\_Rewrite, Creating and Using the required .htaccess page, and setting up the URL rewrites.

### Contents

1. How to Activate Mod\_Rewrite
2. How to Create and Allow the Use of the .htaccess file
3. How to Use Rewrite Rules
4. [How to Use the Rewrite Cond Directive](https://www.digitalocean.com/community/articles/how-to-set-up-mod_rewrite-page-2#Section 4)
5. [Resources](https://www.digitalocean.com/community/articles/how-to-set-up-mod_rewrite-page-2#Section 5)

### Setup

The steps in this tutorial require the user to have root privileges. You can see how to set that up on Ubuntu [here](https://www.DigitalOcean.com/community/articles/initial-server-setup-with-ubuntu-12-04), in steps 3 and 4.

Additionally, you need to have apache installed on your server. If you do not have it, you can download it for Ubuntu with this command:

    sudo apt-get install apache2

### Section 1—How to Activate Mod\_Rewrites

Before we begin generating the actual URL rewrites, we need to activate the apache mod\_rewrite module that controls them. This is simple:

    sudo a2enmod rewrite

The command activates the module or—if it is already activated, displays the words, "Module rewrite already enabled"

### Section 2—About the .htaccess File:

Once the module has been activated, you can set up your URL rewrites by creating an .htaccess file in your website directory.

An .htaccess file is a way to configure the details of your website without needed to alter the server config files. The period that starts the file name will keep the file hidden within the folder.

Additionally the placement of the .htaccess file is important. The configurations in that file will affect everything in its directory and the directories under it.

You can create the .htaccess file in a text editor (make sure to name it only .htaccess without any other extension or name) and then upload it to your site through an ftp client.

Alternatively you can use this command, replacing the example.com with the name of your site, to create your .htaccess file in terminal.

    sudo nano /var/www/example.com/.htaccess

### How to permit changes in the .htaccess file:

To allow the .htaccess file to override standard website configs, start by opening up the configuration file. NB: You will need sudo privileges for this step.

    sudo nano /etc/apache2/sites-available/default

Once inside that file, find the following section, and change the line that says AllowOverride from None to All. The section should now look like this:

     \<Directory /var/www/\> Options Indexes FollowSymLinks MultiViews AllowOverride All Order allow,deny allow from all \</Directory\>

After you save and exit that file, restart apache. .htacess files will now be available for all of your sites.

    sudo service apache2 restart

Now you are all set up to rewrite your site’s URLs.

### Section 3—How to Rewrite URLS

The entire URL rewriting operation takes place within the .htaccess file.

Overall, all of the URL rewrite commands follow the same pattern:

     RewriteRule Pattern Substitution [OptionalFlags]

Here is a short explanation of each part:

- RewriteRule: This is the section in which you can write in the name of the the mod\_rewrite directive that you want to use.
- Pattern: This section is dedicated to interpreting the requested URL, using regular expressions. This tutorial does not include a discussion of regular expressions, but you can find a useful tutorial on the subject [here](http://httpd.apache.org/docs/current/rewrite/intro.html).
- Substitution: This is the actual URL of the page with the information we want to display. It may be hard to remember or confusing because of php paremeters or long strings of numbers. eg. www.cityzoo.com/animals.php?mammals=seals 
- Optional Flags: A flag is a tag at the end of the Rewrite Rule directive that may change the behavior of of the expression. Some common flags include [F], making the URL forbidden, [NC], forcing the rule to disregard capitalization, [R=301] or [R=302], controlling the redirect code you want to use, [L] indicating that this is the last rule in a series.

### Three URL Rewrite Examples:

**Example 1: Go to Page A, find page B:**

This is the most basic example for a URL rewrite: a visitor to the site types one URL into the browser but is redirected to another. Here is how to set it up.

Lets go ahead and make two separate pages on for a site—say, one for Apples (apples.html) and one for Oranges (oranges.html):

Copy the code into the Apple page:

    \<html\> \<head\> \<title\>Apples\</title\> \</head\> \<body\> \<h1\>This page is about Apples\</h1\> \</body\> \</html\>

After that, can make the orange page, substituting all the fruit names to refer to the appropriate one.

Now open up the .htaccess file.

    sudo nano /var/www/example.com/.htaccess

Add the following URL rewrite commands to the file:

    RewriteEngine on RewriteRule ^oranges.html$ apples.html

Save and exit.

Once everything is in place, visit the site ending in "/oranges.html"— all of the information displayed will come from the "/apple.html" site.

**Now for an explanation:**

- ^oranges.html: this refers to how the page starts. The caret (^) signifies the beginning of a string. In other words-- if the page whose URL we wanted to rewrite began with anything but oranges (eg.navel\_oranges.html), it would not be recognized by the rewrite rule, and it would not redirect to apples.html. 
- $: the dollars sign refers to the URL's end. If there is anything else after the last characters in the string, the web page would be equally unrecognizable by the rewrite rule.
- apples.html: this is where the browser is actually directing traffic.

**Example 2: The website has a parameter in its URL. How to make it look like a subdirectory.**

The first example referred to a site that simply needed to be substituted with another one. The instance below, however, addresses a common scenario that can be seen when there is a parameter in the url.

Check out this URL:

    http://example.com/results.php?products=apple

It would be much clearer displayed as:

     http://example.com/products/apple

The lines within the .htaccess file would look like this:

    RewriteEngine on RewriteRule ^products/([A-Za-z0-9-]+)/?$ results.php?products=$1 [NC]

**Now for an explanation:**

- ^products: In order to be caught and rerouted, the URL must start with products (keep in mind that this only refers to the text after the domain name). Should it begin with anything else, the rule will not apply and the URL will stay the same. 
- ([A-Za-z0-9-]+): The content within the parentheses refers to any information that could be typed into the URL. In other words, the URL will be rewritten to reflect whatever a visitor to the site inputs after /products/. 
- +: The plus sign indicates what is in the brackets can be one or more characters (as opposed to, say, a single character that is either a letter or a number). 
- /?$: the dollar sign points out the end of the string. The question mark allows the last character in the string to be a forward slash (although it does not require it).
- results.php?products=$1: the $1 indicates where the string from the pattern should go. In other words, it will put in the information captured from whatever people wrote in the "([A-Za-z0-9-]+):" part. After the process completes, the browser will display the information from the second URL
- [NC]: this is a flag at the end of the phrase, indicating that the rule should ignore the cases of all of the characters in the string. 

**Example 3: The site has an unwieldy URL. How to clean it up**

This sort of situation can arise when URLs are long and complex.

Take the URL below as an example:

    http://example.com/results.php?products=produce&type=fruit&species=apple

As effective as the URL is in delivering the correct content, it is not very memorable for the consumer. URL rewrites would allow you to convert the URL to something simpler and clearer:

    http://example.com/produce/fruit/apple

In order to accomplish this, we would need the following lines in our .htaccess file (you can add as many section as needed in the .htaccess file):

    RewriteEngine on RewriteRule ^(meat|produce|dairy)/([^/.]+)/([^/.]+)$ results.php?products=$1&type=$2&species=$3

**Now for an explanation:**

- First the ^(caret) starts the expression.
- (meat|produce|dairy): If we want to limit the options that can be typed in, we can specify the only values we will accept: in this case the variety of groceries. If anything besides one of those three 3 keywords is typed in, the URL rewrite will not take place. 
- The ([^/.]+) indicates that anything can be written between the forward slash besides the characters following the caret, in this case, the forward slash or period. 
- results.php?products=$1&type=$2&species=$3: Each value in the parentheses will be extracted and then applied to the longer URL in the substitution part of the expression. $1 indicates the first parantheses, $2, the second, $3, the third. 

[Continued on Page 2](https://www.digitalocean.com/community/articles/90)

By Etel Sverdlov
