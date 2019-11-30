---
author: Maxwell Bernstein
date: 2013-07-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-get-started-with-sinatra-on-your-system-or-vps
---

# How To Install And Get Started With Sinatra On Your System Or VPS

## Introduction

Sinatra is a simple and lightweight web framework written in Ruby. This article assumes you know basic Ruby and have Ruby and RubyGems installed on your system or cloud server. Using Ruby Version Manager (RVM) is preferable.

### It's not Rails. What is it?

Sinatra is similar to Ruby on Rails in that they are both web frameworks. It's pretty different from Rails in that it's much lighter (less overhead), and you have more fine-grained control over your webapp. Additionally, there is no built-in database functionality or page rendering — all of that is done manually.

### Why Sinatra, then?

It's fast. It's simple. It's efficient. However, with that comes more work and more room for error.

Sinatra is best used for smaller web applications, or ones that don't need bloat, like those on the [list on their website](http://www.sinatrarb.com/wild.html). Single-purpose apps abound, like one that only [flips text upside down](http://cedarcreekit.com/labs/flip_text). You could even write a simple [Jekyll](http://jekyllrb.com/) front-end with Sinatra.

### Installing Ruby and RubyGems

The best way to install Ruby and RubyGems is with Ruby Version Manager, or RVM. RVM allows you to have multiple Rubies installed, with their own sets of gems (gemsets), and even different gemsets per Ruby. To get the latest RVM _and_ Ruby 2.0.0 run:

    \curl -L https://get.rvm.io | bash -s stable --ruby=2.0.0

You can put any version number for the Ruby version. This installs RVM for the one user running the command. To install systemwide, prepend **sudo** before **bash** :

    \curl -L https://get.rvm.io | sudo bash -s stable --ruby=2.0.0

If a binary Ruby is available for your system or cloud server (most likely), it will be downloaded and installed. If not, it will build Ruby from source. This can take some time.

At the end of the installation, log out and log back in. Then it will ask you to run the command

    source ~/.rvm/scripts/rvm

 — this loads RVM into your current terminal. If all goes well, you will not have to do that again for any other terminal you open. However, if you are continually prompted to run that command, add it to your startup file, like 

    .bashrc

or

    .zshrc

## Installing the gem

Just as you would install any other gem, Sinatra is installed like so:

    gem install sinatra

That is all. You have installed Sinatra.

## Getting started: Hello World

Your first web application should be simple, and easy to understand. Applications are wrapped in Ruby classes. Here's a simple web application in 2 files:

     # app.rb require 'sinatra' class HelloWorldApp \< Sinatra::Base get '/' do "Hello, world!" end end 

     # config.ru require './app' run HelloWorldApp 

After writing the contents to the two files **app.rb** and **config.ru** (using Emacs or your preferred text editor), you can run the application by running from the same folder (say, **/home/user/code/my\_sinatra\_app** ):

    rackup

This starts WEBrick, which serves your application. You will notice that WEBRick tells you what IP and port it is serving; take note. You can access your application at **http://IP:port**.

## Understanding the Hello World application

In Sinatra, each **get** (or **post** , **put** , etc) block defines each route, and how the app responds to specific HTTP requests. In our case, we defined what happens when the user requests the root directory of the application, or **/**.

## Let's try something more complex.

Let's configure our HelloWorldApp to take a parameter!

     # app.rb require 'sinatra' class HelloWorldApp \< Sinatra::Base get '/' do "Hello, world!" end get '/:name' do "Hello, #{params[:name]}!" end end 

URL parameters are specified like so: **:param** , and stored in the **params** hash back in the Ruby code.

This code specifies 2 routes: one for the naked **/** , and another for **/:name**. We could simplify this routing to one route that checks for the presence of a **name** parameter, though!

     # app.rb require 'sinatra' class HelloWorldApp \< Sinatra::Base get '/?:name?' do "Hello, #{params[:name] ? params[:name] : 'world'}!" end end 

This is more complex. We can denote "optional" parameters by surrounding them with question marks. Then we use the ternary operator to check for the presence of **params[:name]**.Alright, what if you wanted to led the user specify the greeting? Let's take a look... how would you structure that?

     # app.rb require 'sinatra' class HelloWorldApp \< Sinatra::Base get '/:greeting/?:name?' do "#{params[:greeting]}, #{params[:name] ? params[:name] : 'world'}!" end end 

Now you can just navigate to **http://yoursever:port/Aloha/Timothy** and Mr Timothy will feel very special!

## Further Information

We recommend Sinatra's own [Getting Started](http://www.sinatrarb.com/intro.html) guide, which is phenomenal. It'll help tremendously.
