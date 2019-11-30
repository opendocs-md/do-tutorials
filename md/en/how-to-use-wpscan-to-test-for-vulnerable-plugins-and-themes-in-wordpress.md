---
author: Paul White
date: 2013-12-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-wpscan-to-test-for-vulnerable-plugins-and-themes-in-wordpress
---

# How To Use WPScan to Test for Vulnerable Plugins and Themes in Wordpress

## Introduction

* * *

This article will walk you through the installation of wpscan and serve as a guide on how to use wpscan to locate any known vulnerable plugins and themes that may make your site vulnerable to attack. Using wpscan we can see an outline of the site in a way similar to that of a would be attacker. There have been a staggering number of security issues found in plugins and themes used in Wordpress sites. These issues typically occur due to insecure coding practices and are often overlooked by users and patches are often not implemented by the users who are put at risk by them.

## Download and Install WPScan

* * *

Before we get started with the installation, it is important to note that wpscan _will not_ work on Windows systems, so you will need access to a Linux or OSX installation to proceed. If you only have access to a Windows system you can download Virtualbox and install any Linux distro you like as a Virtual Machine.

WPScan is hosted on Github, so if it is not already installed we will need to install the git packages before we can continue.

    sudo apt-get install git

Once git is installed, we need to install the dependencies for wpscan.

    sudo apt-get install libcurl4-gnutls-dev libopenssl-ruby libxml2 libxml2-dev libxslt1-dev ruby-dev ruby1.9.3

Now we need to clone the wpscan package from github.

    git clone https://github.com/wpscanteam/wpscan.git

Now we can move to the newly created wpscan directory and install the necessary ruby gems through bundler.

    cd wpscan
    sudo gem install bundler && bundle install --without test development

Now that we have wpscan installed, we will walk through using the tool to search for potentially vulnerable files on our Wordpress installation. Some of the most important aspects of wpscan are its ability to enumerate not only plugins and themes, but users and timthumb installations as well. WPScan can also perform bruteforce attacks against Wordpress– but that is outside of the scope of this article.

## Enumerating Plugins

* * *

To enumerate plugins, all we need to do is launch wpscan with the `--enumerate p` arguments like so.

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate p

or to only display vulnerable plugins:

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate vp

Some example output is pasted below:

    | Name: akismet
    | Location: http:// ********.com/wp-content/plugins/akismet/
    
    | Name: audio-player
    | Location: http:// ********.com/wp-content/plugins/audio-player/
    |
    | * Title: Audio Player - player.swf playerID Parameter XSS
    | * Reference: http://seclists.org/bugtraq/2013/Feb/35
    | * Reference: http://secunia.com/advisories/52083
    | * Reference: http://osvdb.org/89963
    | * Fixed in: 2.0.4.6
    
    | Name: bbpress - v2.3.2
    | Location: http:// ********.com/wp-content/plugins/bbpress/
    | Readme: http:// ********.com/wp-content/plugins/bbpress/readme.txt
    |
    | * Title: BBPress - Multiple Script Malformed Input Path Disclosure
    | * Reference: http://xforce.iss.net/xforce/xfdb/78244
    | * Reference: http://packetstormsecurity.com/files/116123/
    | * Reference: http://osvdb.org/86399
    | * Reference: http://www.exploit-db.com/exploits/22396/
    |
    | * Title: BBPress - forum.php page Parameter SQL Injection
    | * Reference: http://xforce.iss.net/xforce/xfdb/78244
    | * Reference: http://packetstormsecurity.com/files/116123/
    | * Reference: http://osvdb.org/86400
    | * Reference: http://www.exploit-db.com/exploits/22396/
    
    | Name: contact
    | Location: http:// ********.com/wp-content/plugins/contact/

From the output, we can see that the audio-player plugin is vulnerable to XSS attacks through the `playerid` parameter. We also see that the installation of bbpress is vulnerable to both path disclosure and SQL Injection. Note that manual verification of reported vulnerabilities is always a good idea if possible, as scanners will sometimes report false positives. If after running these tests against your site you are notified of any potential vulnerabilities, it is important to check with the plugin developers to see if there is a patch available, and if so how the patches need to be installed.

## Enumerating Themes

* * *

Enumeration of themes works the same as enumeration of plugins, just with the `--enumerate t` argument.

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate t

or to only display vulnerable themes:

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate vt

Sample output:

    | Name: path
    | Location: http:// ********.com/wp-content/themes/path/
    | Style URL: http:// ********.com/wp-content/themes/path/style.css
    | Description: 
    
    | Name: pub
    | Location: http:// ********.com/wp-content/themes/pub/
    | Style URL: http:// ********.com/wp-content/themes/pub/style.css
    | Description: 
    
    | Name: rockstar
    | Location: http:// ********.com/wp-content/themes/rockstar/
    | Style URL: http:// ********.com/wp-content/themes/rockstar/style.css
    | Description: 
    |
    | * Title: WooThemes WooFramework Remote Unauthenticated Shortcode Execution
    | * Reference: https://gist.github.com/2523147
    
    | Name: twentyten
    | Location: http:// ********.com/wp-content/themes/twentyten/
    | Style URL: http:// ********.com/wp-content/themes/twentyten/style.css
    | Description: 

As before, we can see that the installation of the rockstar theme is vulnerable to remote unauthenticated shortcode execution, which means that it is possible for anyone to execute shortcode on the site without the need to authenticate as a valid user.

WPScan can also be used to enumerate users with valid logins to the Wordpress installation. This is usually performed by attackers in order to get a list of users in preparation for a bruteforce attack.

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate u

The last function of wpscan we’ll discuss in this article is the ability to enumerate timthumb installations. In recent years, timthumb has become a very common target of attackers due to the numerous vulnerabilities found and posted to online forums, message lists, and advisory boards. Using wpscan to find vulnerable timthumb files is done with the following command.

    ruby wpscan.rb --url http(s)://www.yoursiteurl.com --enumerate tt

To update wpscan:

    ruby wpscan.rb --update

Submitted by: [Paul White](https://twitter.com/Su1ph3r)
