---
author: Lisa Tagliaferri
date: 2016-09-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-rebase-and-update-a-pull-request
---

# How To Rebase and Update a Pull Request

## Introduction

Contributing to open-source projects is a rewarding experience as you work to make software better for end users like yourself. Once you submit a pull request, the process of contributing to a project can require some rebasing and reworking of code prior to acceptance, followed by a general clean up of your branches.

This tutorial will guide you through some of the next steps you may need to take after you submit a [pull request](how-to-create-a-pull-request-on-github) to an open-source software project.

## Prerequisites

This tutorial will walk you through the steps you’ll take after making a pull request, so you should already have Git installed, and either have made or are thinking about creating a pull request.

To learn more about contributing to open source projects, you can read [this introduction](contributing-to-open-source-getting-started-with-git). To learn about making pull requests, you can read “[How To Create a Pull Request on GitHub](how-to-create-a-pull-request-on-github).”

## Rebasing Code and Cleaning Up Comments

While you contribute to open source, you may find that there are conflicts between your branch or pull request and the upstream code. You may get an error like this in your shell:

    OutputCONFLICT (content): Merge conflict in your-file.py
    Automatic merge failed; fix conflicts and then commit the result.

Or like this on your pull request via GitHub’s website:

![GitHub pull request conflicts](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/conflicts.png)

This may happen if the maintainers do not respond to your pull request for a while, or if many people are contributing to the project at once. When this happens and you still want to merge your pull request, you will have to resolve conflicts and rebase your code.

A **rebase** allows us to move branches around by changing the commit that they are based on. This way, we can rebase our code to make them based on the master branch’s more recent commits. Rebasing should be done with care, and you should make sure you are working with the right commits and on the right branch throughout the process. We’ll also go over using the `git reflog` command [below](how-to-rebase-and-update-a-pull-request#recovering-lost-commits) in case you make an error.

As we did in the [pull request tutorial](how-to-create-a-pull-request-on-github), we’ll move into the code directory and fetch the most recent upstream version of the code.

    cd repository
    git fetch upstream

Once you have the upstream version of the project fetched, you can clean up your comments by either squashing or rewording your commit messages to make them more digestible to the project maintainers. If you did not do many small commits, this may not be necessary.

To begin this process, you’ll perform an interactive rebase. An **interactive rebase** can be used to edit previous commit messages, combine several commits into one, or delete or revert commits that are not necessary any longer. To do this, we will need to be able to reference the commits that we have made either by number or by a string that references the base of our branch.

To find out the number of commits we have made, we can inspect the total number of commits that have been made to the project with the following command:

    git log

This will provide you with output that looks similar to this:

    Outputcommit 46f196203a16b448bf86e0473246eda1d46d1273
    Author: username-2 <email-2>
    Date: Mon Dec 14 07:32:45 2015 -0400
    
        Commit details
    
    commit 66e506853b0366c87f4834bb6b39d941cd034fe3
    Author: username1 <email-1>
    Date: Fri Nov 27 20:24:45 2015 -0500
    
        Commit details

The log shows all the commits made to the given project’s repository, so your commits will be mixed it with the commits made by others. For projects that have an extensive history of commits by multiple authors, you’ll want to specify yourself as author in the command:

    git log --author=your-username

By specifying this parameter, you should be able to count up the commits you’ve made. If you’re working on multiple branches you can add `--branches[=<branch>]` to the end of your command to limit by branch.

Now if you know the number of commits you’ve made on the branch that you want to rebase, you can simply run the `git rebase` command like so:

    git rebase -i HEAD~x

Here, `-i` refers to the rebase being interactive, and `HEAD` refers to the latest commit from the master branch. The `x` will be the number of commits you have made to your branch since you initially fetched it.

If, however, you don’t know how many commits you have made on your branch, you’ll need to find which commit is the base of your branch, which you can do by running the following command:

    git merge-base new-branch master

This command will return a long string known as a commit hash, something that looks like this:

    Output66e506853b0366c87f4834bb6b39d341cd094fe9

We’ll use this commit hash to pass to the `git rebase` command:

    git rebase -i 66e506853b0366c87f4834bb6b39d341cd094fe9

For either of the above commands, your command-line text editor will open with a file that contains a list of all the commits in your branch, and you can now choose whether to squash commits or reword them.

### Squash Commits

When we squash commit messages, we are squashing or combining several smaller commits into one larger one.

In front of each commit you’ll see the word “pick,” so your file will look similar to this if you have two commits:

GNU nano 2.0.6 File: …username/repository/.git/rebase-merge/git-rebase-todo

    pick a1f29a6 Adding a new feature
    pick 79c0e80 Here is another new feature
    
    # Rebase 66e5068..79c0e80 onto 66e5068 (2 command(s))

Now, for each line of the file except for the first line, you should replace the word “pick” with the word “squash” to combine the commits:

GNU nano 2.0.6 File: …username/repository/.git/rebase-merge/git-rebase-todo

    pick a1f29a6 Adding a new feature
    squash 79c0e80 Here is another new feature

At this point, you can save and close the file, which will open a new file that combines all the commit messages of all of the commits. You can reword the commit message as you see fit, and then save and close the file.

You’ll receive feedback once you have closed the file:

    OutputSuccessfully rebased and updated refs/heads/new-branch.

You now have combined all of the commits into one by squashing them together.

### Reword Commits

Rewording commit messages is great for when you notice a typo, or you realize you were not using parallel language for each of your commits.

Once you perform the interactive rebase as described above with the `git rebase -i` command, you’ll have a file open up that looks like this:

GNU nano 2.0.6 File: …username/repository/.git/rebase-merge/git-rebase-todo

    pick a1f29a6 Adding a new feature
    pick 79c0e80 Here is another new feature
    
    # Rebase 66e5068..79c0e80 onto 66e5068 (2 command(s))

Now, for each of the commits that you would like to reword, replace the word “pick” with “reword”:

GNU nano 2.0.6 File: …username/repository/.git/rebase-merge/git-rebase-todo

    pick a1f29a6 Adding a new feature
    reword 79c0e80 Adding a second new feature
    
    # Rebase 66e5068..79c0e80 onto 66e5068 (2 command(s))

Once you save and close the file, a new text file will appear in your terminal editor that shows the modified wording of the commit message. If you would like to edit the file again, you can do so before saving and closing the file. Doing this can ensure that your commit messages are useful and uniform.

### Complete the Rebase

Once you are satisfied with the number of commits you are making and the relevant commit messages, you should complete the rebase of your branch on top of the latest version of the project’s upstream code. To do this, you should run this command from your repository’s directory:

    git rebase upstream/master

At this point, Git will begin replaying your commits onto the latest version of master. If you get conflicts while this occurs, Git will pause to prompt you to resolve conflicts prior to continuing.

Once you have fixed the conflicts, you’ll run:

    git rebase --continue 

This command will indicate to Git that it can now continue replaying your commits.

If you previously combined commits through using the `squash` command, you will only need to resolve conflicts once.

### Update Pull Request with Force-Push

Once you perform a rebase, the history of your branch changes, and you are no longer able to use the `git push` command because the direct path has been modified.

We will have to instead use the `--force` or `-f` flag to force-push the changes, informing Git that you are fully aware of what you are pushing.

Let’s first insure that our `push.default` is `simple`, which is the default in Git 2.0+, by configuring it:

    git config --global push.default simple

At this point, we should ensure that we are on the correct branch by checking out the branch we are working on:

    git checkout new-branch

    OutputAlready on 'new-branch'
    . . .

Now we can perform the force-push:

    git push -f

Now you should receive feedback of your updates along with the message that this was a `forced update`. Your pull request is now updated.

### Recovering Lost Commits

If at some point you threw out a commit that you really wanted to integrate into the larger project, you should be able to use Git to restore commits you may have thrown away by accident.

We’ll be using the `git reflog` command to find our missing commits and then create a new branch from that commit.

**Reflog** is short for **reference logs** which record when the tips of branches and other references were last updated within the local repository.

From the local directory of the code repository we are working in, we’ll run the command:

    git reflog

Once you run this command, you’ll receive output that looks something like this:

    Output46f1962 HEAD@{0}: checkout: moving from branch-1 to new-branch
    9370d03 HEAD@{1}: commit: code cleanups
    a1f29a6 HEAD@{2}: commit: brand new feature 
    38f2fc2 HEAD@{3}: commit: remove testing methods 
    . . .

Your commit messages will let you know which of the commits is the one that you left behind, and the relevant string will be before the `HEAD@{x}` information on the left-hand side of your terminal window.

Now you can take that information and create a new branch from the relevant commit:

    git checkout -b new-new-branch a1f29a6

In the example above, we made a new branch from the third commit displayed above, the one that rolled out a “brand new feature,” represented by the string `a1f29a6`.

Depending on what you need to do from here, you can follow the steps on setting up your branch in [this tutorial on pull requests](how-to-create-a-pull-request-on-github#create-a-new-branch), or return to the [top of the current tutorial](how-to-rebase-and-update-a-pull-request#rebasing-code-and-cleaning-up-comments) to work through rebasing the new branch.

**Note** : If you recently ran the `git gc` command to clean up unnecessary files and optimize the local repository you may be unable to restore lost commits.

## What To Expect In a Code Review

When you submit a pull request, you are in dialogue with a larger project. Submitting a pull request is inviting others to talk about your work, just as you yourself are talking about and engaging with a bigger project. For you to have a successful conversation, it is important for you to be able to communicate _why_ you are making the pull request through your commit messages, so it is best to be as precise and clear as possible.

The pull request review may be lengthy and detailed, depending on the project. It is best to think of the process as a learning experience, and a good way for you to improve your code and make the pull request better and more in-line with the needs of the software project. The review should allow you to make the changes yourself through the maintainers’ advice and direction.

The pull request will keep a log of notes from reviewers and any updates and discussion you have together. You may need to make several extra commits throughout this process before the pull request is accepted. This is completely normal and provides a good opportunity for you to work on revision as part of a team.

Your pull request will continue to be maintained through Git, and be auto-updated throughout the process as long as you keep adding commits to the same branch and pushing those to your fork.

Though you are putting your code out there into the larger world for review by your peers, you should never be made to feel like the review is getting personal, so be sure to read relevant `CONTRIBUTION.md` files or Codes of Conduct. It is important to make sure that your commits are aligning with the guidelines specified by the project, but if you begin to feel uncomfortable, the project you are working on may not be deserving of your contribution. There are many welcoming spaces in the open-source community and while you can expect your code to be looked at with a critical eye, all feedback you receive should be professional and courteous.

## Pull Request Acceptance and Deleting Your Branch

Congratulations! If your pull request has been accepted, you have successfully made a contribution to an open-source software project!

At this point, you will need to pull the changes you made back into your fork through your local repository. This is what you have already done when you went through the process to [sync your fork](how-to-create-a-pull-request-on-github#sync-the-fork). You can do this with the following commands in your terminal window:

    git checkout master
    git pull --rebase upstream master
    git push -f origin master

Now, you should clean up both your local and remote branches by removing the branch you created in both places as they are no longer needed. First, let’s remove the local branch:

    git branch -d new-branch

The `-d` flag added to the `git branch` command will delete the branch that you pass to the command. In the example above, it is called new-branch.

Next, we’ll remove the remote branch:

    git push origin --delete new-branch

With the branches deleted you have cleaned up the repository and your changes now live in the main repository. You should keep in mind that just because the changes you made through your pull request are now part of the main repository, they may not be available to the average end user who is downloading public releases. Generally speaking, software maintainers will bundle several new features and fixes together into a single public release.

## Conclusion

This tutorial took you through some of the next steps you may need to complete after submitting a [pull request](how-to-create-a-pull-request-on-github) to an open-source software repository.

Contributing to open-source projects — and becoming an active open-source developer — is often a rewarding experience. Making regular contributions to software you frequently use helps to ensure that it is valuable and useful to its community of users.
