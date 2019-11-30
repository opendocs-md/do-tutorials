---
author: Etel Sverdlov
date: 2012-07-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_rewrite-page-2
---

# How To Set Up Mod_Rewrite (page 2)

[Continued from Page 1](https://www.digitalocean.com/community/articles/how-to-set-up-mod_rewrite)

### Rewrite Conditions

The three examples on the previous page showed how to rewrite URLs to make sites easier to access and remember.

Rewrite Rules can also have conditions to make sure that the rewrites only take place under specific circumstances.

**Example 1: How To Prevent Hotlinking**

Hotlinking is the process of using an image or object from one server on another one. This action drains bandwidth from the victim's server and denies the creator of the object any additional visitors to their site that they might have gained otherwise.

You can prevent hotlinking by redirecting all the links to an object on your site to some other less pleasant image, or by forbidding the operation altogether.

    RewriteEngine on RewriteCond %{HTTP\_REFERER} !^$ RewriteCond %{HTTP\_REFERER} !^http://(www\.)?example\.com/.\*$ [NC] RewriteRule .\*\.(gif|jpeg|png)$ http://www.example.com/unpleasantness.jpg [R,NC,L]

**Now for an explanation:**

- %{HTTP\_REFERER}: this refers to where the traffic is coming from. The percent sign indicates that it is an apache variable.
- !: the exclamation mark negates the pattern following it. In effect, this points out that whatever follows it does _not_ fall under the conditions required to be affected by the rewrite rule.
- ^$: As mentioned earlier, the caret stands for the beginning of a string and dollar sign for the end of it. In this case, there is nothing between them and therefore the referrer does not exist. In other words, this line states that direct links are not affected by the rewrite rule. 
- The second condition references the referrer once again. 
- !^http://(www\.)?example\.com/.\*$: the exclamation point states that the referrer should not be the our own site 
- Finally we get to the rewrite rule itself which states that any link to a file ending with the extensions gif, jpeg, or png will be rerouted to some unpleasant picture to teach hotlinker a lesson. If we simply wanted to forbid them from accessing any image at all, we can make a small edit to the RewriteRule in the last line. Instead of providing an alternative destination, as this line does, you can instead just send the rewrite to a forbidden page: 

    RewriteRule .\*\.(gif|jpeg|png)$ - [F]

**Example 2: How to add www to a URL**

Another useful trick that mod\_rewrite can do is add www to a domain. Although it’s easy for a person to see that example.com and www.example.com are the same site, search engines register them as duplicates, hurting their rankings.

To resolve the issue you can choose to either consistently remove the www or always have it added to the URL. This example will show how to be sure that the www is always attached.

    RewriteEngine on RewriteCond %{HTTP\_HOST} ^example\.com$ RewriteRule ^(.\*)$ http://www.example.com/$1 [R=301]

**Now for an explanation:**

- %{HTTP\_HOST}: this refers the website in the requested URL 
- ^example.com$: explains that the requested page needs to be example.com 
- ^(.\*)$ :The rewrite rule says that any text after can follow the domain. 
- [R=301]: The flag denotes that the URL as being redirected, and the 301 points out that this is a permanent redirect. A temporary one is designated with the number 302. 

Everything will then convert from example.com to www.example.com

**Example 3: Blocking a Specific IP Address**

This a useful tool to prevent, for example, malicious parties at specific IP addresses from accessing a site.

    RewriteCond&nbsp;%{REMOTE\_ADDR} ^(12\.34\.56\.789)$ RewriteRule (.\*) - [F,L]

**Now for an explanation:**

- %{REMOTE\_ADDR}: This stands for the IP address from which our site is being accessed and which we want to block. 
- ^(12\.34\.56\.789)$: You can use this section to type in the malicious IP address. Keep in mind that the backslashes are very important. They designate the periods as punctuation, instead of their standard regular expression use as wildcards.
- (.\*): This signifies that any text from the blocked IP will result in the rewrite rule being completed.
- [F,L]: the flags finish off the rule. [F] forbids access and [L] stops any other rules from applying, making it the last rule.

### Resources

The previous sections have been a basic overview of the capabilities of Mod\_Rewrite.

The topic is quite expansive and has many nuances that can make it a very useful and flexible tool.

Here are some links for further information about Mod\_Rewrite:

- [Apache Introduction to Mod\_Rewrites](http://httpd.apache.org/docs/current/rewrite/intro.html)
- [Apache Documentation](http://httpd.apache.org/docs/current/mod/mod_rewrite.html)
- [A Quick Mod\_Rewrite Cheat Sheet](http://www.cheatography.com/davechild/cheat-sheets/mod-rewrite/)

By Etel Sverdlov
