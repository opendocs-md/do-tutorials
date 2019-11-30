---
author: Lisa Tagliaferri
date: 2017-06-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-pygame-and-create-a-template-for-developing-games-in-python-3
---

# How To Install pygame and Create a Template for Developing Games in Python 3

## Introduction

The [pygame](http://pygame.org/) library is an open-source module for the Python programming language specifically intended to help you make games and other multimedia applications. Built on top of the highly portable [SDL](http://www.libsdl.org/) (Simple DirectMedia Layer) development library, pygame can run across many platforms and operating systems.

By using the pygame module, you can control the logic and graphics of your games without worrying about the backend complexities required for working with video and audio.

This tutorial will first go through installing pygame into your Python programming environment, and then walk you through creating a template to develop games with pygame and Python 3.

## Prerequisites

To be able to use this tutorial, make sure you have Python 3 and a programming environment already installed on your [local computer](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) or [server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server).

You should also be familiar with the following Python programming concepts:

- [Importing modules](how-to-import-modules-in-python-3)
- [Variables](how-to-use-variables-in-python-3)
- [`while` loops](how-to-construct-while-loops-in-python-3)
- [`for` loops](how-to-construct-for-loops-in-python-3)
- [Conditional statements](how-to-write-conditional-statements-in-python-3-2)
- [Boolean logical operators](understanding-boolean-logic-in-python-3#logical-operators)

With a programming environment set up and a familiarity with [Python programming](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-python-3) you are ready to begin working with pygame.

## Installing pygame

Let’s begin by activating our Python 3 programming environment:

    . my_env/bin/activate

With this activated, you can install pygame with pip:

    pip install pygame

Once you run this command, you should see output that looks similar to the following:

    OutputCollecting pygame
      Using cached pygame-1.9.3-cp35-cp35m-manylinux1_x86_64.whl
    Installing collected packages: pygame
    Successfully installed pygame-1.9.3

If you have installed pygame into a system with video and audio available, you can verify your installation by running the following command, which will run a mock game showcasing what pygame can do with graphics and sound:

    python -m pygame.examples.aliens

If you would rather not open up the sample, or if you do not have AV as part of your setup, you can also enter into the Python interactive console to ensure that you can import the pygame module. First, type the `python` command to start the console:

    python

Then within the console you can import the module:

    import pygame

If you receive no errors upon hitting the `ENTER` key following the command, you will know that pygame was successfully installed. You can exit the Python interactive console with the `quit()` command.

If you are experiencing issues with installing on the command line, you can check out pygame’s [GettingStarted wiki](http://pygame.org/wiki/GettingStarted#Pygame%20Installation).

In later steps, we will be assuming the use of a monitor to display the graphical user interface as part of this tutorial to verify our code.

## Importing pygame

To become familiar with pygame, let’s create a file called `our_game.py`, which we can create with the nano text editor, for instance:

    nano our_game.py

When beginning a project in pygame, you’ll start with the `import` statement used for [importing modules](how-to-import-modules-in-python-3), which you can add at the top of your file:

our\_game.py

    import pygame

We can also optionally add another import statement below the first line to add some of the constants and functions of pygame into the [global namespace](how-to-import-modules-in-python-3#using-from--import) of your file:

our\_game.py

    import pygame
    from pygame.locals import *

With pygame imported into our program file, we are ready to use it to create a game template.

## Initializing pygame

From here, we’ll initialize pygame’s functionalities with the `init()` function, which is short for “initialize.”

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()

The `init()` function will automatically start up all the pygame modules that you need initialized.

You can also initialize each of pygame’s modules individually, as in:

    pygame.font.init()

The `init()` function will return a [tuple](understanding-tuples-in-python-3) to you if you would like. This tuple will show successful and unsuccessful initializing. We can do this both for the general `init()` call and for the initialization of specific modules (which will show us whether these modules are available):

    i = pygame.init()
    print(i)
    
    f = pygame.font.init()
    print(f)

If we run the code above, we will receive output similar to the following:

    Output(6, 0)
    None

In this case, the `i` [variable](how-to-use-variables-in-python-3) returned the tuple `(6, 0)`, which shows that there were 6 successful pygame initializations and 0 failures. The `f` variable returned `None`, indicating that the module is not available within this particular environment.

## Setting Up the Display Surface

From here, we need to set up our game display surface. We’ll use `pygame.display.set_mode()` to initialize a window or screen for display and pass it to a variable. Into the function, we will pass an argument for the display resolution which is a pair of numbers representing width and height in a tuple. Let’s add this function to our program:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    game_display = pygame.display.set_mode((800, 600))

We passed the tuple `(800, 600)` as the argument to the `set_mode()` function, standing for the resolution of the width (800 px) and the height (600 px). Note that the tuple is contained within the function’s parentheses, so there are double parentheses in the function above.

You will likely be using the [integers](understanding-data-types-in-python-3#numbers) for your game’s resolution often, so you’ll probably want to assign those numbers to variables rather than use the numbers again and again. This can make it easier when you need to modify your program, as you’ll only need to modify what is passed to the variables.

We’ll use the variable `display_width` for the width of our game’s display, and `display_height` for the height, and pass those variables to the `set_mode()` function:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))

At this point the game display surface is set up with a resolution for its width and height.

## Updating the Display

Next, we’ll need to use one of two available functions to update the display of the game surface.

Animations are generally changes between different frames over time. You may think of a [flip book](http://imgur.com/epkHzo4) when thinking about animations, as they consist of a series of images that vary gradually from one page to the following page. These pages give the simulation of movement when they are flipped through quickly, as the contents of the page appear to be in motion. In computer games, frames are used rather than pages.

Because of the concept of flipping pages or frames, one of the functions that can be used to update the display of the game surface is called `flip()`, and can be called in our file above like so:

    pygame.display.flip()

The `flip()` function updates the whole display surface to the screen.

More frequently, the `update()` function is used instead of the `flip()` function because it will update only portions of the screen, rather than the entire area, saving memory.

Let’s add the `update()` function to the bottom of the `our_game.py` file:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))
    
    pygame.display.update()

At this point, you can run the program without any errors but the display surface will merely open up and quickly close.

## Creating the Game Loop

With pygame imported and initialized, the display set, and the game surface being updated, we can start working on our main game loop.

We will be creating a [`while` loop](how-to-construct-while-loops-in-python-3) that will run the game. The loop will call the [Boolean](understanding-boolean-logic-in-python-3) value of `True`, meaning that the loop will loop forever unless it is disrupted.

Within this main game loop of our program, we will construct a [`for` loop](how-to-construct-for-loops-in-python-3) to iterate through the user events within the event queue, which will be called by the `pygame.event.get()` function.

At this point, we have nothing within the `for` loop, but we can add a `print()` statement to show that the code is behaving as we expect it to. We will pass the events within the iteration into the statement as `print(event)`.

Let’s add these two loops and the `print()` statement into our program file:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))
    
    pygame.display.update()
    
    while True:
        for event in pygame.event.get():
            print(event)

To make sure that our code is working, let’s run the program:

    python our_game.py

When we run the file, an 800x600 window will pop up. To test the events, you can mouse over the window, click within the window, and press keys on your keyboard. These events will print out to your console window.

The output you receive will look something like this:

    Output<Event(4-MouseMotion {'rel': (616, 355), 'buttons': (0, 0, 0), 'pos': (616, 355)})>
    <Event(5-MouseButtonDown {'button': 1, 'pos': (616, 355)})>
    <Event(6-MouseButtonUp {'button': 1, 'pos': (616, 355)})>
    <Event(2-KeyDown {'scancode': 3, 'key': 102, 'unicode': 'f', 'mod': 0})>
    <Event(3-KeyUp {'scancode': 3, 'key': 102, 'mod': 0})>
    ...

This output shows the user events that are taking place. These events are what will control the game as they are generated by the user. Whenever you run the `pygame.event.get()` function, your code will be taking in these events.

Stop the program from running by pressing `CTRL` + `C` in the terminal window.

At this point, you can delete or [comment out](how-to-write-comments-in-python-3) the `print()` statement as we won’t need to have all of this terminal output.

From here, we can work on finishing up our template by learning how to quit a game.

## Quitting

To quit a pygame program, we can first uninitialize the relevant modules, and then quit Python as usual.

The `pygame.quit()` function will uninitialize all pygame modules, and the Python `quit()` function will exit the program.

Since users are in control of game functionality and events, we should also know that `pygame.QUIT` is sent to the event queue when the user has requested the program to shut down by clicking on the “X” in the game window’s upper corner.

Let us start controlling the program’s flow with a [conditional `if` statement](how-to-write-conditional-statements-in-python-3-2) within the event-handling `for` loop:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))
    
    pygame.display.update()
    
    while True:
        for event in pygame.event.get():
            if event.type == QUIT:
                pygame.quit()
                quit()

In the code above, we are saying that if the user has requested the program to shut down, the program should uninitialize the pygame modules with `pygame.quit()` and exit the program with `quit()`.

Since we have imported `pygame.locals` we can evoke `event.type` and `QUIT` as-is (rather than with `pygame.` in front of these).

Though users may know to click the “X” in the upper corner of the game window, we may want to have certain other user events trigger the request to quit the program. We can do this with the `KEYDOWN` event type and one or more keys.

The `KEYDOWN` event means that the user is pressing a key on their keyboard down. For our purposes, let’s say that the `Q` key (as in “quit”) or the `ESC` key can quit the program. Let’s add code that signifies this within our `for` loop:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))
    
    pygame.display.update()
    
    while True:
        for event in pygame.event.get():
            if event.type == QUIT or (
                 event.type == KEYDOWN and (
                  event.key == K_ESCAPE or
                  event.key == K_q
                 )):
                pygame.quit()
                quit()

We have added [Boolean logical operators](understanding-boolean-logic-in-python-3#logical-operators) so that the program can quit if the user clicks the “X” in the upper-corner of the game window, or if the user presses a key down that is either the escape key or the `Q` key (note that this is not case sensitive).

At this point, if you run the program with the `python our_game.py` command, you’ll be able to test the functionality of the game running and then quitting by either exiting the window with the “X” icon, or through pressing either the `Q` or `ESC` key.

## Code Improvements and Next Steps

While the program above is fully functional, there are some things we can do to improve the code.

For starters, we can put the code that is in the `while` loop into a [function definition](how-to-define-functions-in-python-3) instead:

    def event_handler():
        for event in pygame.event.get():
            if event.type == QUIT or (
                 event.type == KEYDOWN and (
                  event.key == K_ESCAPE or
                  event.key == K_q
                 )):
                pygame.quit()
                quit()

This will make the `while` loop a bit neater and condensed, especially as we add more functionality to our game.

Additionally, to start making the game more polished, we can add a caption to the title bar of the window (which currently reads `pygame window`). This we can do with the following line:

    pygame.display.set_caption('Our Game')

We can set the string `'Our Game'` above to anything we would like to call the game.

Additionally, we can move the `pygame.display.update()` function into the main game loop.

Now, our full code looks like this:

our\_game.py

    import pygame
    from pygame.locals import *
    
    
    pygame.init()
    
    display_width = 800
    display_height = 600
    
    game_display = pygame.display.set_mode((display_width, display_height))
    pygame.display.set_caption('Our Game')
    
    
    def event_handler():
        for event in pygame.event.get():
            if event.type == QUIT or (
                 event.type == KEYDOWN and (
                  event.key == K_ESCAPE or
                  event.key == K_q
                 )):
                pygame.quit()
                quit()
    
    while True:
        event_handler()
    
        pygame.display.update()
    

You can also consider different ways of approaching the code above, including using a [break statement](how-to-use-break-continue-and-pass-statements-when-working-with-loops-in-python-3#break-statement) to get out of a loop before moving into a game exit.

From here, you will want to go on to learning about how to display images through drawing and sprites, animate images and control the frame rate, and more. You can continue to learn about pygame game development by reading the official [pygame documentation](http://www.pygame.org/docs/).

## Conclusion

This tutorial walked you through installing the open-source module pygame into your Python 3 programming environment, and how to begin to approach game development through setting up a template that you can use for controlling the main loop of a Python game.

To do other programming projects that make use of Python modules, you can learn “[How To Create a Twitterbot with the Tweepy Library](how-to-create-a-twitterbot-with-python-3-and-the-tweepy-library),” or “[How To Plot Data Using matplotlib](how-to-plot-data-in-python-3-using-matplotlib).”
