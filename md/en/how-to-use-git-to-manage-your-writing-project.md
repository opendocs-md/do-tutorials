---
author: Brian Hogan
date: 2019-09-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-git-to-manage-your-writing-project
---

# How To Use Git to Manage Your Writing Project

## Introduction

Version control isn’t just for code. It’s for anything you want to track, including content. Using [Git](https://git-scm.com) to manage your next writing project gives you the ability to view multiple drafts at the same time, see differences between those drafts, and even roll back to a previous version. And if you’re comfortable doing so, you can then share your work with others on GitHub or other central Git repositories.

In this tutorial you’ll use Git to manage a small Markdown document. You’ll store an initial version, commit it, make changes, view the difference between those changes, and review the previous version. When you’re done, you’ll have a workflow you can apply to your own writing projects.

## Prerequisites

- Git installed on your local computer. The tutorial [How to Contribute to Open Source: Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git) walks you through installing Git and covers some background information you may find useful. 

## Step 1 — Creating a Workspace for Your Writing Project

To manage your changes, you’ll create a local Git repository. A Git repository lives inside of an existing directory, so start by creating a new directory for your article:

    mkdir article

Switch to the new `article` directory:

    cd article

The `git init` command creates a new empty Git repository in the current directory. Execute that command now:

    git init

You’ll see the following output which confirms your repository was created:

    OutputInitialized empty Git repository in /Users/sammy/article/.git/

The `.gitignore` file lets you tell Git that some files should be ignored. You can use this to ignore temporary files your text editor might create, or operating systems files. On macOS, for example, the Finder application creates `.DS_Store` files in directories. Create a `.gitignore` file that ignores them:

    nano .gitignore

Add the following lines to the file:

.gitignore

    # Ignore Finder files
    .DS_store

The first line is a comment, which will help you identify what you’re ignoring in the future. The second line specifies the file to ignore.

Save the file and exit the editor.

As you discover more files you want to ignore, open the `.gitignore` file and add a new line for each file or directory you want to ignore.

Now that your repository is configured, you can start working.

## Step 2 — Saving Your Initial Draft

Git only knows about files you tell it about. Just because a file exists in the directory holding the repository doesn’t mean Git will track its changes. You have to add a file to the repository and then commit the changes.

Create a new Markdown file called `article.md`:

    nano article.md

Add some text to the file:

article.md

    # How To Use Git to Manage Your Writing Project
    
    ### Introduction
    
    Version control isn't just for code. It's for anything you want to track, including content. Using Git to manage your next writing project gives you the ability to view multiple drafts at the same time, see differences between those drafts, and even roll back to a previous version. And if you're comfortable doing so, you can then share your work with others on GitHub or other central git repositories.
    
    In this tutorial you'll use Git to manage a small Markdown document. You'll store an initial version, commit it, make changes, view the difference between those changes, and review the previous version. When you're done, you'll have a workflow you can apply to your own writing projects.

Save the changes and exit the editor.

The `git status` command will show you the state of your repository. It will show you what files need to be added so Git can track them. Run this command:

    git status

You’ll see this output:

    OutputOn branch master
    
    No commits yet
    
    Untracked files:
      (use "git add <file>..." to include in what will be committed)
    
        .gitignore
        article.md
    
    nothing added to commit but untracked files present (use "git add" to track)

In the output, the `Untracked files` section shows the files that Git isn’t looking at. These files need to be added to the repository so Git can watch them for changes. Use the `git add` command to do this:

    git add .gitignore
    git add article.md

Now run `git status` to verify those files have been added:

    OutputOn branch master
    
    No commits yet
    
    Changes to be committed:
      (use "git rm --cached <file>..." to unstage)
    
        new file: .gitignore
        new file: article.md
    

Both files are now listed in the `Changes to be committed` section. Git knows about them, but it hasn’t created a snapshot of the work yet. Use the `git commit` command to do that.

When you create a new commit, you need to provide a commit message. A good commit message states what your changes are. When you’re working with others, the more detailed your commit messages are, the better.

Use the command `git commit` to commit your changes:

    git commit -m "Add gitignore file and initial version of article"

The output of the command shows that the files were committed:

    Output[master (root-commit) 95fed84] Add gitignore file and initial version of article
     2 files changed, 9 insertions(+)
     create mode 100644 .gitignore
     create mode 100644 article.md

Use the `git status` command to see the state of the repository:

    git status

The output shows there are no changes that need to be added or committed.

    OutputOn branch master
    nothing to commit, working tree clean

Now let’s look at how to work with changes.

## Step 3 — Saving Revisions

You’ve added your initial version of the article. Now you’ll add more text so you can see how to manage changes with Git.

Open the article in your editor:

    nano article.md

Add some more text to the end of the file:

    ## Prerequisites
    
    * Git installed on your local computer. The tutorial [How to Contribute to Open Source: Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git) walks you through installing Git and covers some background information you may find useful. 

Save the file.

Use the `git status` command to see where things stand in your repository:

    git status

The output shows there are changes:

    OutputOn branch master
    Changes not staged for commit:
      (use "git add <file>..." to update what will be committed)
      (use "git checkout -- <file>..." to discard changes in working directory)
    
        modified: article.md
    
    no changes added to commit (use "git add" and/or "git commit -a")
    

As expected, the `article.md` file has changes.

Use `git diff` to see what they are:

    git diff article.md

The output shows the lines you’ve added:

    diff --git a/article.md b/article.md
    index 77b081c..ef6c301 100644
    --- a/article.md
    +++ b/article.md
    @@ -5,3 +5,7 @@
     Version control isn't just for code. It's for anything you want to track, including content. Using Git to manage your next writing project gives you the ability to view multiple drafts at the same time, see differences between those drafts, and even roll back to a previous version. And if you're comfortable doing so, you can then share your work with others on GitHub or other central git repositories.
    
     In this tutorial you'll use Git to manage a small Markdown document. You'll store an initial version, commit it, make changes, view the difference between those changes, and review the previous version. When you're done, you'll have a workflow you can apply to your own writing projects.
    +
    +## Prerequisites
    +
    +* Git installed on your local computer. The tutorial [How to Contribute to Open Source: Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git) walks you through installing Git and covers some background information you may find useful. 

In the output, lines starting with a plus (+) sign are lines you added. Lines that were removed would show up with a minus (-) sign. Lines that were unchanged would have neither of these characters in front.

Using `git diff` and `git status` is a helpful way to see what you’ve changed. You can also save the diff to a file so you can view it later with the following command:

    git diff article.md > article_diff.diff

Using the `.diff` extension will help your text editor apply the proper syntax highlighting.

Saving the changes to your repository is a two-step process. First, add the `article.md` file again, and then commit. Git wants you to explicitly tell it which files go in every commit, so even though you added the file before, you have to add it again. Note that the output from the `git status` command reminds you of that.

Add the file and then commit the changes, providing a commit message:

    git add article.md
    git commit -m "add prerequisites section"

The output verifies that the commit worked:

    Output[master 1fbfc21] add prerequisites section
     1 file changed, 4 insertions(+)

Use `git status` to see your repository status. You’ll see that there’s nothing else to do.

    git status

    OutputOn branch master
    nothing to commit, working tree clean

Continue this process as you revise your article. Make changes, verify them, add the file, and commit the changes with a detailed message. Commit your changes as often or as little as you feel comfortable. You might perform a commit after you finish each draft, or right before you do a major rework of your article’s structure.

If you send a draft of a document to someone else and they make changes to it, take their copy and replace your file with theirs. Then use `git diff` to see the changes they made quickly. Git will see the changes whether you typed them in directly or replaced the file with one you downloaded from the web, email, or elsewhere.

Now let’s look at managing the versions of your article.

## Step 4 — Managing Changes

Sometimes it’s helpful to look at a previous version of a document. Whenever you’ve used `git commit`, you’ve supplied a helpful message that summarizes what you’ve done.

The `git log` command shows you the commit history of your repository. Every change you’ve committed has an entry in the log.

    git log

    Outputcommit 1fbfc2173f3cec0741e0a6b21803fbd0be511bc4
    Author: Sammy Shark <sammy@digitalocean>
    Date: Thu Sep 19 16:35:41 2019 -0500
    
        add prerequisites section
    
    commit 95fed849b0205c49eda994fff91ec03642d59c79
    Author: Sammy Shark <sammy@digitalocean>
    Date: Thu Sep 19 16:32:34 2019 -0500
    
        Add gitignore file and initial version of article

Each commit has a specific identifier. You use this number to reference a specific commit’s changes. You only need the first several characters of the identifier though. The `git log --oneline` command gives you a condensed version of the log with shorter identifiers:

    git log --oneline

    Output1fbfc21 add prerequisites section
    95fed84 Add gitignore file and initial version of article

To view the initial version of your file, use `git show` and the commit identifier. The identifiers in your repository will be different than the ones in these examples.

    git show 95fed84 article.md

The output shows the commit detail, as well as the changes that happened during that commit:

    Outputcommit 95fed849b0205c49eda994fff91ec03642d59c79
    Author: Sammy Shark <sammy@digitalocean>
    Date: Thu Sep 19 16:32:34 2019 -0500
    
        Add gitignore file and initial version of article
    
    diff --git a/article.md b/article.md
    new file mode 100644
    index 0000000..77b081c
    --- /dev/null
    +++ b/article.md
    @@ -0,0 +1,7 @@
    +# How To Use Git to Manage Your Writing Project
    +
    +### Introduction
    +
    +Version control isn't just for code. It's for anything you want to track, including content. Using Git to manage your next writing project gives you the ability to view multiple drafts at the same time, see differences between those drafts, and even roll back to a previous version. And if you're comfortable doing so, you can then share your work with others on GitHub or other central git repositories.
    +
    +In this tutorial you'll use Git to manage a small Markdown document. You'll store an initial version, commit it, make changes, view the difference between those changes, and review the previous version. When you're done, you'll have a workflow you can apply to your own writing projects.

To see the file itself, modify the command slightly. Instead of a space between the commit identifier and the file, replace with `:./` like this:

    git show 95fed84:./article.md

You’ll see the content of that file, at that revision:

    Output# How To Use Git to Manage Your Writing Project
    
    ### Introduction
    
    Version control isn't just for code. It's for anything you want to track, including content. Using Git to manage your next writing project gives you the ability to view multiple drafts at the same time, see differences between those drafts, and even roll back to a previous version. And if you're comfortable doing so, you can then share your work with others on GitHub or other central git repositories.
    
    In this tutorial you'll use Git to manage a small Markdown document. You'll store an initial version, commit it, make changes, view the difference between those changes, and review the previous version. When you're done, you'll have a workflow you can apply to your own writing projects.

You can save that output to a file if you need it for something else:

    git show 95fed84:./article.md > old_article.md

As you make more changes, your log will grow, and you’ll be able to review all of the changes you’ve made to your article over time.

## Conclusion

In this tutorial you used a local Git repository to track the changes in your writing project. You can use this approach to manage individual articles, all the posts for your blog, or even your next novel. And if you push your repository to GitHub, you can invite others to help you edit your work.
