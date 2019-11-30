---
author: Brian Hogan
date: 2017-10-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-irb-to-explore-ruby
---

# How To Use IRB to Explore Ruby

## Introduction

IRB, short for Interactive Ruby, is a quick way to explore the Ruby programming language and try out code without creating a file. IRB is a [Read-Eval-Print Loop](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), or _REPL_, a tool offered by many modern programming languages. To use it, you launch the `irb` executable and type your Ruby code at the prompt. IRB evaluates the code you type and displays the results.

IRB gives you access to all of Ruby’s built-in features, as well as any libraries or gems you’ve installed. In addition, you can configure IRB to save your command history and even enable auto-completion of your code.

In this tutorial, you’ll use IRB to run some code, inspect its output, bring in external libraries, and customize your IRB session.

## Starting and Stopping IRB

If you have [Ruby installed](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-ruby), you’ll have IRB. You can start it on any computer where Ruby is installed by executing the command `irb` from your command line interface.

    irb

You’ll be greeted with the IRB prompt:

    IRB sessionirb(main):001:0>

The prompt indicates that you’re running IRB and that anything you execute will run in the `main` context, which is the top-level default context of a Ruby program. It also shows a line number.

**Note** : If you’ve installed Ruby with RVM, your prompt may look slightly different, showing the version number instead:

    IRB session from RVM2.4.0 :001 >

To get the prompt shown throughout this tutorial, launch IRB with `irb --prompt inf-ruby`.

IRB accepts Ruby syntax, which you can enter at the prompt. Try it out by adding two numbers together:

    2 + 2

Press the `ENTER` key and IRB will show you the result:

    IRB session=> 4

The `=>` symbol lets you know that this is the return value from the Ruby expression.

To exit IRB, type `exit` at the prompt, or press `CTRL+D`. You’ll return to your shell prompt.

Let’s dig a little deeper into IRB by looking at how you can use it to explore code.

## Executing Code in an IRB Session

IRB is a great way to try out code to see if it’s a good solution to your problem. Almost everything in Ruby returns some value, and every time you execute a statement in IRB, you’ll see that return value printed to the screen.

To demonstrate this, execute this statement in a new IRB session:

    puts "Hello World"

When you press the `ENTER` key, you’ll see two results from IRB:

    OUTPUTHello World
    => nil

The first result is the output from the `puts` method, which prints the string you specified, followed by a line break. The `puts` method prints the text to the standard output device, which is your screen. But the `puts` method has a return value, because every method in Ruby has a return value. The `puts` method returns `nil`, and that’s what IRB is showing you.

Every time you execute a statement, the prompt changes, indicating a new line number:

    irb(main):001:0> puts "Hello World"
    Hello World
    => nil
    irb(main):002:0>

This can help you debug statements when doing more complex expressions in an IRB session, as error messages will refer to line numbers.

You can assign values to variables in an IRB session just like you would in your standalone Ruby programs. Execute this statement by typing it in your IRB session and pressing `ENTER`:

    birth_year = 1868

You’ll see the return value of this statement echoed back:

    IRB session=> 1868

The variable `birth_year` holds this value, but, since most statements in Ruby return values, IRB shows you the return value here as well.

Add two more variables. First, create a variable called `death_year`:

    death_year = 1921

Then create the variable `age_at_death` by subtracting `birth_year` from `death_year`:

    age_at_death = death_year - birth_year

IRB assigns the value to the variable, but also shows you the result:

    IRB session=> 53

When you’re in an IRB session, you don’t have to use an explicit `puts` or `print` statement if you don’t want to, since you’ll see your return values displayed.

Sometimes you’ll want to write code that spans multiple lines. IRB supports this intuitively. IRB only executes code that is syntactically complete. The following Ruby code uses an [array](how-to-work-with-arrays-in-ruby) of sharks and uses the [select](how-to-use-array-methods-in-ruby#finding-and-filtering-elements) method to return only the sharks containing the letter “a” in their name. Type this code into your IRB session, pressing `ENTER` after each line:

    ["Tiger", "Great White", "Angel"].select do |shark|
       shark.include?("a")
    end

IRB lets you enter multiple lines of code, but it only executes the code when it thinks the code is syntactically complete. Notice that the prompt changes to indicate that IRB is not yet evaluating your code by using an asterisk (`*`) and changing the final zero to a one to indicate a different scope:

    IRB sessionirb(main):005:0> ["Tiger", "Great White", "Angel"].select do |shark|
    irb(main):006:1* shark.include?("a")
    irb(main):007:1> end

Since the first line contains the `do` keyword, IRB doesn’t attempt to execute anything until it encounters the `end` keyword. Then it displays the result:

    IRB session=> ["Great White"]

Using IRB, you can test out bits of code to see how they’ll work before you incorporate them into your own programs. You can also use IRB to work with external libraries.

## Using Libraries and Gems

You can import libraries into your IRB session using the `require` statement, just as you would in a Ruby program. These libraries can be things included in Ruby’s standard library, things you’ve written yourself, or _gems_, Ruby libraries distributed via [Rubygems.org](http://rubygems.org) which you install using the `gem` command.

Ruby’s standard library includes modules for making web requests and fetching the results. You can use those in your IRB session exactly like you would in a Ruby program.

Use the `require` statement to import [Net/HTTP](http://ruby-doc.org/stdlib-2.4.2/libdoc/net/http/rdoc/Net/HTTP.html) from Ruby’s standard library. Enter the following line of code into your IRB session and press `ENTER`:

    require 'net/http'

IRB indicates that this statement returns `true`, which tells you that the library was loaded successfully. Now type this code into IRB to make a request to `icanhazip.com` to fetch your external IP address:

    uri = URI.parse("http://icanhazip.com")
    response = Net::HTTP.get_response uri
    response.body

As you enter each line, IRB shows you the return value, so you can debug each step:

    IRB sessionirb(main):010:0> uri = URI.parse("http://icanhazip.com")
    => #<URI::HTTP http://icanhazip.com>
    irb(main):011:0> response = Net::HTTP.get_response uri
    => #<Net::HTTPOK 200 OK readbody=true>
    irb(main):012:0> response.body
    => 203.0.113.52\n

If a library couldn’t be found, you’ll see a different response. Try importing the [HTTParty](https://rubygems.org/gems/httparty) library, which makes working with HTTP requests a little easier:

    require 'httparty'

You’ll see this message:

    IRB sessionLoadError: cannot load such file -- httparty

This message tells you that the libary you want isn’t available. HTTParty is distributed as a gem, so we’ll have to install it. Exit your IRB session with `CTRL+D` or type `exit` to return to your prompt. Then use the `gem` command to install the `httparty` gem:

    gem install httparty

Now launch `irb` again.

    irb

Try loading the module again. In your IRB session, type this code:

    require 'httparty`

This time, IRB will display `true`, letting you know it was able to load the library. Enter this code into IRB to try it out:

    response = HTTParty.get("http://icanhazip.com")
    response.body

You’ll see the output printed to the screen:

    IRB session=> 203.0.113.52\n

Now let’s look at how to explore and test your own Ruby code with IRB.

## Loading Your Code into IRB

If you start an IRB session and use the `-r` switch, you can specify libraries or gems you want to load when IRB starts. For example, `irb -r httparty` would launch an IRB session with the `httparty` gem already loaded, meaning you can skip the explicit `require httparty` statement.

However, you can also use this to load your own code into a new session, which is helpful when you want to explore it or test it out.

Exit your IRB session by typing `exit` or by pressing `CTRL+D`.

Create a new Ruby file called `ip_grabber.rb` which defines a `IPGrabber` object with a `get` method that, when provided a URL, will return the external IP address of the machine. We’ll use the HTTParty library to fetch the response from `icanhazip.com`. We would use this `IPGrabber` object in our own program to insulate our code from external changes; using our obect would let us switch out the underlying library and the site we use to resolve the IP address without having to change how the rest of our code works.

Add this code to the file to define the class:

ip\_grabber.rb

    require 'httparty'
    class IPGrabber
    
      def initialize()
        @url = "http://icanhazip.com"
      end
    
      def get
        response = HTTParty.get(@url)
        response.body.chomp # remove the \n if it exists
      end
    end

Save the file and exit the editor.

Then launch IRB and load this file. Since it’s a local file rather than a gem or a built-in library, we have to specify a path. We also don’t need to specify the `.rb` extension of the file.

    irb -r ./ip_grabber

The IRB session loads, and you can start using this new object in your session like this:

    ip = IPGrabber.new
    ip.get

You’ll see this output:

    IRB session=> 203.0.113.52

By loading your own code into an IRB session, you can inspect code and work with your own libraries before incorporating them into a full program.

Now that you know how to work with code in an IRB session, let’s look at how to customize your IRB session.

## Customizing IRB

You can create a configuration file called `.irbrc` that lets you customize your IRB session. You can then add support for autocompletion, indentation, and command history.

Create this file in your home directory:

    nano ~/.irbrc

First, configure autocompletion support in IRB. This will let you use the `TAB` key to autocomplete object, variable names, and method names in IRB:

~/.irbrc

    require 'irb/completion'

Next, add support for saving your command history to an external file.

~/.irbrc

    IRB.conf[:SAVE_HISTORY] = 1000

With this enabled, the last 1000 statements you type will be logged to the `.irb_history` file in your home directory.

In addition, when you open a new IRB session, your history will load automatically, and you can use the `Up` and `Down` arrow keys to move through these entries, or use `CTRL+R` to do a reverse search, just like you would in a Bash shell.

If you wanted to specify a different history file, add this to your configuration file:

~/.irbrc

    IRB.conf[:HISTORY_FILE] = '~/your_history_filename'

Next, add this line to your configuration file to enable auto-indenting, which is handy when writing classes, methods, and blocks:

~/.irbrc

    IRB.conf[:AUTO_INDENT] = true

Your configuration file can include any additional valid Ruby code, which means you could define helper methods or use `require` to load additional libraries. For example, to add a `history` helper to your IRB session which would show your history, add this code to `.irbrc`:

.irbrc

    def history
      history_array = Readline::HISTORY.to_a
      print history_array.join("\n")
    end

When you load your IRB session, type `history` to see your IRB history. You may have quite a bit, so you can alter the `history` command so it takes an optional number of lines to show. Replace the code for the `history` function with this code, which takes an optional argument called `count` and uses it to limit the entries it displays:

.irbrc

    
    # history command
    def history(count = 0)
    
      # Get history into an array
      history_array = Readline::HISTORY.to_a
    
      # if count is > 0 we'll use it.
      # otherwise set it to 0
      count = count > 0 ? count : 0
    
      if count > 0
        from = hist.length - count
        history_array = history_array[from..-1] 
      end
    
      print history_array.join("\n")
    end

Save the file and start a new IRB session. Then type `history 2` and you’ll see only the last two ines of your history.

While you can use `.irbrc` to load libraries you use frequently, remember that each library you load increases the load time of the IRB session, which can make it less pleasant to use. You’re often better off loading specific libaries manually with `require` statements.

## Conclusion

IRB provides a place to experiment with Ruby code. It’s a great way to work out program logic before putting it in a file.

Now that you’re comfortable with IRB, you can use it to explore Ruby’s various data types by following these tutorials and using IRB to run the examples.

- [Understanding Data Types in Ruby](understanding-data-types-in-ruby)
- [How To Work with Strings in Ruby](how-to-work-with-strings-in-ruby)
- [How To Work with String Methods in Ruby](how-to-work-with-string-methods-in-ruby)
- [How To Work with Arrays in Ruby](how-to-work-with-arrays-in-ruby)
- [How To Use Array Methods in Ruby](how-to-use-array-methods-in-ruby)
