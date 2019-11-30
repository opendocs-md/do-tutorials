---
author: Jason Kurtz
date: 2013-03-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-git-effectively
---

# How To Use Git Effectively

This article assumes that you have git installed and that your global configuration settings (namely username and email) are properly set. If this is not the case, please refer to the [git introduction tutorial](https://www.digitalocean.com/community/articles/how-to-install-git-on-ubuntu-12-04).

Git is a very useful piece of software to help streamline development for programming projects. It comes with no language requirements nor file structure requirements, leaving it open for the developers to decide how they want to structure their workflow.

Before using git for your development, it's a good idea to plan out your workflow. The workflow decision is typically based on the size and scale of your project. To gain a basic understanding of git for now, a simple, single-branch workflow will suffice. By default, the first branch on any git project is called "master". In a following tutorial in this series, you will learn how to create other branches.

Let's create our first project and call it "testing". (If you already have a project that you want to import to git you can skip down to that section.)

## Creating your workspace 

Just like you want to have a good, clean work environment, the same idea applies to where you do your coding, especially if you're going to contribute to a number of projects at the same time. A good suggestion might be to have a folder called git in your home directory which has subfolders for each of your individual projects.

The first thing we need to do is create our workspace environment:

    user@host ~ $ mkdir -p ~/git/testing ; cd ~/git/testing

The above commands will accomplish two things: 1) It creates a directory called "git" in our home directory and then creates a subdirectory inside of that called "testing" (this is where our project will actually be stored). 2) It brings us to our project's base directory.

Once inside that directory, we need to create a few files that will be in our project. In this step, you can either follow along and create a few dummy files for testing purposes or you can create files/directories you wish that are going to be part of your project.

We are going to create a test file to use in our repository:

    user@host ~/git/testing $ touch file

Once all your project files are in your workspace, you need to start tracking your files with git. The next step explains that process.

## Converting an existing project into a workspace environment 

Once all the files are in your git workspace, you need to tell git that you want to use your current directory as a git environment.

     user@host ~/git/testing $ git init Initialized empty Git repository in /home/user/git/testing/.git/ 

Once your have initialized your new empty repository, you can add your files.

The following will add all files and directories to your newly created repository:

    user@host ~/git/testing $ git add .

In this case, no output is good output. Unfortunately, git does not always inform you if something worked.

Every time you add or make changes to files, you need to write a commit message. The next section describes what a commit message is and how to write one.

## Creating a commit message 

A commit message is a short message explaining the changes that you've made. It is required before sending your coding changes off (which is called a push) and it is a good way to communicate to your co-developers what to expect from your changes. This section will explain how to create them.

Commit messages are generally rather short, between one and two sentences explaining what your change did. It is good practice to commit each individual change before you do a push. You can push as many commits as you like. The only requirement for any commit is that it involves at least one file and it has a message. A push must have at least one commit.

Continuing with our example, we are going to create the message for our initial commit:

     user@host ~/git/testing $ git commit -m "Initial Commit" -a [master (root-commit) 1b830f8] initial commit 0 files changed create mode 100644 file 

There are two important parameters of the above command. The first is -m, which signifies that our commit message (in this case "Initial Commit") is going to follow. Secondly, the -a signifies that we want our commit message to be applied to all added or modified files. This is okay for the first commit, but generally you should specify the individual files or directories that we want to commit.

We could have also done:

    user@host ~/git/testing $ git commit -m "Initial Commit" file

To specify a particular file to commit. To add additional files or directories, you just add a space separated list to the end of that command.

## Pushing changes to a remote server

Up until this point, we have done everything on our local server. That's certainly an option to use git locally, if you want to have any easy way to have version control of your files. If you want to work with a team of developers, however, you're going to need to push changes to a remote server. This section will explain how to do that.

The first step to being able to push code to a remote server is providing the URL where the repository lives and giving it a name. To configure a remote repository to use and to see a list of all remotes (you can have more than one), type the following:

     user@host ~/git/testing $ git remote add origin ssh://git@git.domain.tld/repository.git user@host ~/git/testing $ git remote -v origin ssh://git@git.domain.tld/repository.git (fetch) origin ssh://git@git.domain.tld/repository.git (push) 

The first command adds a remote, called "origin", and sets the URL to ssh://git@git.domain.tld/repository.git.

You can name your remote whatever you'd like, but the URL needs to point to an actual remote repository. For example, if you wanted to push code to GitHub, you would need to use the repository URL that they provide.

Once you have a remote configured, you are now able to push your code.

You can push code to a remote server by typing the following:

     user@host ~/git/testing $ git push origin master Counting objects: 4, done. Delta compression using up to 2 threads. Compressing objects: 100% (2/2), done. Writing objects: 100% (3/3), 266 bytes, done. Total 3 (delta 1), reused 1 (delta 0) To ssh://git@git.domain.tld/repository.git 0e78fdf..e6a8ddc master -\> master 

"git push" tells git that we want to push our changes, "origin" is the name of our newly-configured remote server and "master" is the name of the first branch.

In the future, when you have commits that you want to push to the server, you can simply type "git push".

I hope this article provided you with a basic understanding of how git can be used effectively for a team of developers. The next article in this series will provide a more in-depth analysis of git branches and why they are so effective.

By Jason Kurtz
