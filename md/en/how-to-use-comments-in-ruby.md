---
author: Brian Hogan
date: 2017-09-28
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-comments-in-ruby
---

# How To Use Comments in Ruby

## Introduction

Comments are lines in computer programs that are ignored by compilers and interpreters. You can use comments to make your programs easier for other programmers to understand by using them to provide more context or explanation about what each part of a program is doing. In addition, you can use comments to explain why you chose a particular solution, or even prevent a problematic or incomplete part of your program from executing temporarily while you work out a fix.

Some comments might stay in the code forever, such as those that explain context, while other comments can be temporary, such as notes you leave yourself while you’re building your program.

Let’s look at how to use comments in Ruby programs to leave notes, as well as how to use them as a debugging tool.

## Comment Syntax and Usage

Comments in Ruby begin with a hash mark (`#`) and continue to the end of the line, like this:

    # This is a comment in Ruby

While it’s not required, you should place a blank space after the hash mark to improve the comment’s readability.

When you run a program, you won’t see any indication of comments in the code; the Ruby interpreter ignores them entirely. Comments are in the source code for humans to read, not for computers to execute.

In a simple Ruby program, like the one in the tutorial [How to Write Your First Ruby Program](how-to-write-your-first-ruby-program), you can use comments to give additional detail about what’s happening in each part of the code:

greetings.rb

    # Display a prompt to the user
    puts "Please enter your name."
    
    # Save the input they type and remove the last character (the enter keypress)
    name = gets.chop
    
    # Print the output to the screen
    puts "Hi, #{name}! I'm Ruby!"

These comments give you a general idea of what each section of the program does and how it works.

In a program that iterates over an array and displays its contents as an HTML list, you might see comments like this, which give a little more explanation about what the code does:

sharks.rb

    sharks = ['hammerhead', 'great white', 'dogfish', 'frilled', 'bullhead', 'requiem']
    
    # transform each entry in the array to an HTML entity, with leading spaces and a newline.
    listitems = sharks.map{ |shark| " <li>#{shark}</li>\n"}
    
    # Print the opening <ul>, then print the array of list items
    print "<ul>\n#{listitems.join}</ul>"

You may not be familiar with things like `map` and `join` yet, but the comments give you an idea of how this program should work and what the output might look like. Try it out. Place this code in a file called `sharks.rb` and run it:

    ruby sharks.rb

You’ll see the program’s output:

    Output<ul>
      <li>hammerhead</li>
      <li>great white</li>
      <li>dogfish</li>
      <li>frilled</li>
      <li>bullhead</li>
      <li>requiem</li>
    </ul>

Notice you don’t see the comments, since the interpreter ignored them. But the output probably matched what you were expecting. Comments are a great communication tool, especially when the person reading the comments is new to the language.

Comments should be made at the same indent as the code they commenting. That is, a class definition with no indentation would have a comment with no indentation, and each indentation level following would have comments that are aligned with the code it is commenting.

For example, here is a Ruby implementation of a [Magic 8-Ball](https://en.wikipedia.org/wiki/Magic_8-Ball) game. The computer will give a random answer to a question you ask. Notice that the comments are indented at the same level of indentation as the code in each section.

magic8ball.rb

    # The Eightball class represents the Magic 8-Ball.
    class Eightball
    
      # Set up the available choices
      def initialize
          @choices = ["Yes", "No", "All signs point to yes", "Ask again later", "Don't bet on it"]
      end
    
      # Select a random choice from the available choices
      def shake
        @choices.sample
      end
    end
    
    def play
      puts "Ask the Magic 8 Ball your question."
    
      # Since we don't need their answer, we won't capture it.
      gets
    
      # Create a new instance of the Magic 8 Ball and use it to get an answer.
      eightball = Eightball.new
      answer = eightball.shake
      puts answer
    
      # Prompt to restart the game and evaluate the answer.
      puts "Want to try again? Press 'y' to continue or any other key to quit."
      answer = gets.chop
    
      if answer == 'y'
        play
      else
        exit
      end
    end
    
    # Start the first game.
    play

Comments are supposed to help programmers, whether it is the original programmer or someone else using or collaborating on the project. This means the comments must be maintained just like the code. A comment that contradicts the code is worse than no comment at all.

When you’re just starting out, you may write lots of comments to help you understand what you’re doing. But as you gain more experience, you should be looking to use comments to explain the _why_ behind the code as opposed to the _what_ or _how_. Unless the code is particularly tricky, looking at the code can generally tell what the code is doing or how it is doing it.

For example, this kind of comment isn’t that helpful once you know Ruby:

    # print "Hello Horld" to the screen.
    print "Hello World"

This comment reiterates what the code already does, and while it doesn’t affect the program’s output, it is extra noise when you’re reading code.

Sometimes you’ll need to write comments that are a little more detailed. That’s what block comments are for.

## Block Comments

You can use block comments to explain more complicated code or code that you don’t expect the reader to be familiar with. These longer-form comments apply to some or all of the code that follows, and are also indented at the same level as the code.

In block comments, each line begins with the hash mark followed by a single space for readability. If you need to use more than one paragraph, they should be separated by a line that contains a single hash mark.

Here is an example of a block comment from the [Sinatra](http://www.sinatrarb.com/) web framework’s source code. It provides some context to other developers about how this particular code works:

https://github.com/sinatra/sinatra/blob/master/lib/sinatra/base.rb

    ...
      # Some Rack handlers (Thin, Rainbows!) implement an extended body object protocol, however,
      # some middleware (namely Rack::Lint) will break it by not mirroring the methods in question.
      # This middleware will detect an extended body object and will make sure it reaches the
      # handler directly. We do this here, so our middleware and middleware set up by the app will
      # still be able to run.
      class ExtendedRack < Struct.new(:app)
        def call(env)
          result, callback = app.call(env), env['async.callback']
          return result unless callback and async?(*result)
          after_response { callback.call result }
          setup_close(env, *result)
          throw :async
        end
    ...

Block comments are great when you need to thoroughly explain pieces of code. However, you should try to avoid over-commenting your code, as those comments could be redundant and create additional noise. Trust other programmers to understand Ruby code unless you are writing for a particular audience. Comments should add context, not duplicate the code.

Ruby has an alternative syntax for multi-line comments, but it’s rarely used. Here’s an example:

multiline.rb

    =begin
    This is a multi-line comment.
    You can use this approach to make your comments
    span multiple lines without placing hash marks at the start of each
    line.
    =end

The `=begin` and `=end` lines must be at the beginning of the line. They can’t be indented. It’s for this reason that you’ll rarely see this used.

Let’s look at inline comments next.

## Inline Comments

Inline comments occur on the same line of a statement, following the code itself. Like other comments, they begin with a hash mark, followed by a single whitespace character for readability.

Generally, inline comments look like this:

    [code] # Inline comment about the code

Inline comments should be used sparingly, but can be effective for explaining tricky or non-obvious parts of code. They can also be useful if you think you may not remember a line of the code you are writing in the future, or if you are collaborating with someone who you know may not be familiar with all aspects of the code.

For example, if you don’t use a lot of math in your Ruby programs, you or your collaborators may not know that the following creates a complex number, so you may want to include an inline comment about that:

    a=Complex(4,3) # Create the complex number 4+3i

You can also use inline comments to explain the reason behind doing something:

    pi = 3.14159 # Intentionally limiting the value of pi for this program.

Comments that are made in line should be used only when necessary and when they can provide helpful guidance for the person reading the program.

## Commenting Out Code for Testing

In addition to using comments as a way to document code, you can use the hash mark to comment out code that you don’t want to execute while you are testing or debugging a program you are currently creating. Sometimes, when you experience errors after adding new lines of code, you may want to comment a few of them out to see if you can troubleshoot the issue through the process of elimination.

For example, in the Magic 8-Ball game, perhaps you want to prevent the game from running again because you’re just interested in making sure that the code evaluates the answer correctly. You can just comment out the line of code that starts the game again:

8ball.rb

    ...
    
      # Prompt to restart the game and evaluate the answer.
      puts "Want to try again? Press 'y' to continue or any other key to quit."
      answer = gets.chop
    
      if answer == 'y'
        # play
      else
        exit
      end
    end
    ...
    

Comments also let you try alternatives while you’re determining how to implement a solution in your code. For example, you may want to try a couple of different approaches when working with arrays in Ruby. You can use comments to test each approach and determine which one you like the most:

sharks.rb

    sharks = ["Tiger", "Great White", "Hammerhead"]
    
    # for shark in sharks do
    # puts shark
    # end
    
    sharks.each do |shark|
      puts shark
    end

Commenting out code lets you try out different programming methods as well as help you find the source of an error through systematically commenting out and running parts of a program.

## Conclusion

Using comments within your Ruby programs can make programs more readable to humans, including your future self. Including appropriate comments that are relevant and useful makes it easier for others to collaborate with you on programming projects. They’ll also help you understand code you wrote in the future when you revisit your project after a long period of time.
