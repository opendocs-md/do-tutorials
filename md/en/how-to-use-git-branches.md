---
author: Jason Kurtz
date: 2013-03-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-git-branches
---

# How To Use Git Branches

This article is the third installment in the "Using Git" series. It assumes that you have read both the [installation article](https://www.digitalocean.com/community/articles/how-to-install-git-on-ubuntu-12-04) and the article on [how to use git effectively](https://www.digitalocean.com/community/articles/how-to-use-git-effectively).

In the world of version control systems, GIT is arguably one of the best in terms of flexbility. It's very easy to learn the syntax and to figure out how git can best serve your workflow and your environment.

This tutorial will teach you how to create two branches (master and develop) and how to merge code from the development stage to production.

A branch, at its core, is a unique series of code changes with a unique name. Each repository can have one or more branches.

By default, the first branch is called "master".

## Viewing branches

Prior to creating new branches, we want to see all the branches that exist. We can view all existing branches by typing the following:

    git branch -a

Adding the "-a" to the end of our command tells GIT that we want to see all branches that exist, including ones that we do not have in our local workspace.

The output will look similiar to the following:

     \* master remotes/origin/master 

The asterisk next to "master" in the first line of the output indicates that we are currently on that branch. The second line simply indicates that on our remote, named origin, there is a single branch, also called master.

Now that we know how to view branches, it time create our first one.

## Creating branches

As stated in the beginning of this article, we want to have a development and a production setup for our coding environment.

We are going to treat the default "master" branch as our production and therefore need to create a single branch for development, or pre-production.

To create a new branch, named develop, type the following:

    git checkout -b develop

Assuming we do not yet have a branch named "develop", the output would be as follows:

     Switched to a new branch 'develop' 

In the case of a branch by that name already existing, GIT would tell us so:

     fatal: A branch named 'develop' already exists. 

You can switch back and forth between your two branches, by using the git checkout command:

     git checkout master 

or

     git checkout develop 

Assuming the branch that you are trying to switch to exists, you'll see output similiar to the following:

     Switched to branch 'master' 

If you try to switch to a branch that doesn't exist, such as

     git checkout nosuchbranch 

Git will tell you:

     error: pathspec 'nosuchbranch' did not match any file(s) known to git. 

Now that we have multiple branches, we need to put them to good use. In our scenario, we are going to use our "develop" branch for testing out our changes and the master branch for releasing them to the public.

To illustrate this process, we need to switch back to our develop branch:

     git checkout develop 

## Making changes to our develop branch

On this branch, we are going to create a new blank file, named "develop". Until we merge it to the master branch (in the following step), it will not exist there.

     touch develop 

Just as in the previous tutorial, we need to tell git that we want to track this new file.

We can add the "develop" file, by typing:

     git add develop 

The above set of commands will create a blank file, named "develop", and add it to GIT.

We also need to commit this file, which will attach this file to the branch we're currently on, which is "develop".

     git commit -m "develop file" develop 

This file now exists on the develop branch; as we're about to find out, it doesn't exist on the master branch.

First, we are going to confirm that we are currently on the develop branch. We can do this by typing the following:

     git branch 

The output should appear similar to the following:

     \* develop master 

We learned earlier that the asterisk next to the branch name indicates that we are currently on that branch.

Running the "ls" command will show us that the two files exist:

     ls 

The output will show us that both of our files, respectively named "file" and "develop", are found:

     develop file 

## Merging code between branches

The interesting part comes after we switch back to our master branch, which we can do with the git checkout command:

     git checkout master 

To ensure that we are on the master branch, we can run type the following:

     git branch 

The output will tell us which branch we are one, indicated by the asterisk.

     develop \* master 

Running "ls" again, it appears that our new file is missing.

     file 

It's not missing - it's on our develop branch and we are on our master branch.

In our scenario, this file represents any change to any file (or a whole new file) that has passed all testing on our development branch,and is ready to be in production. The process of moving code between branches (often from development to production) is known as **merging**.

It is important to remember when merging, that we want to be on the branch that we want to merge to.

In this case, we want to merge from our develop branch, where the "develop" file exists, to our master branch.

Keeping that in mind, considering that we are already on the master branch, all we have to do is run the merge command.

One of the options that we can pass to the merge command, namely "--no-ff", means we want git to retain all of the commit messages prior to the merge. This will make tracking changes easier in the future.

To merge the changes from the develop branch to the master branch, type the following:

     git merge develop --no-ff 

The output of the command will be similiar to the following:

     Merge made by the 'recursive' strategy. 0 files changed create mode 100644 develop 

Running the ls command again will confirm that our "develop" file is now on our master branch.

     develop file 

The last thing we now need to do, to make this change on our remote server is to push our changes, which we can do with the help of the git push command.

     git push 

You will see output similar to following, confirming that your the merge from your develop branch to the master branch on your remote server:

     Counting objects: 4, done. Delta compression using up to 2 threads. Compressing objects: 100% (3/3), done. Writing objects: 100% (3/3), 332 bytes, done. Total 3 (delta 1), reused 0 (delta 0) To ssh://git@git.domain.tld/repository 9af2dcb..53649cf master -\> master 

## Conclusion

By following the above tutorial, you should have a working dual-branch workflow setup and hopefully a working understanding about how branching works in GIT. Let us know what you think in the comments!

By Jason Kurtz
