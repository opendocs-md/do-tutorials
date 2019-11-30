---
author: Justin Ellingwood
date: 2014-08-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks
---

# How To Use Git Hooks To Automate Development and Deployment Tasks

## Introduction

Version control has become a central requirement for modern software development. It allows projects to safely track changes and enable reversions, integrity checking, and collaboration among other benefits. The `git` version control system, in particular, has seen wide adoption in recent years due to its decentralized architecture and the speed at which it can make and transfer changes between parties.

While the `git` suite of tools offers many well-implemented features, one of the most useful characteristics is its flexibility. Through the use of a “hooks” system, git allows developers and administrators to extend functionality by specifying scripts that git will call based on different events and actions.

In this guide, we will explore the idea of git hooks and demonstrate how to implement code that can assist you in automating tasks in your own unique environment. We will be using an Ubuntu 14.04 server in this guide, but any system that can run git should work in a similar way.

## Prerequisites

Before you get started, you must have `git` installed on your server. If you are following along on Ubuntu 14.04, you can check out our guide on [how to install git on Ubuntu 14.04](how-to-install-git-on-ubuntu-14-04) here.

You should be familiar with how to use git in a general sense. If you need an introduction, the series that the installation is a part of, called [Introduction to Git: Installation, Usage, and Branches](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches), is a good place to start.

When you are finished with the above requirements, continue on.

## Basic Idea with Git Hooks

Git hooks are a rather simple concept that was implemented to address a need. When developing software on a shared project, maintaining style guide standards, or when deploying software (all are situations that git is often involved with), there are often repetitive tasks that you will want to do each time an action is taken.

Git hooks are event-based. When you run certain git commands, the software will check the `hooks` directory within the git repository to see if there is an associated script to run.

Some scripts run prior to an action taking place, which can be used to ensure code compliance to standards, for sanity checking, or to set up an environment. Other scripts run after an event in order to deploy code, re-establish correct permissions (something git cannot track very well), and so forth.

Using these abilities, it is possible to enforce policies, ensure consistency, and control your environment, and even handle deployment tasks.

The book [Pro Git](http://git-scm.com/book) by Scott Chacon attempts to divide the different types of hooks into categories. He categorizes them as such:

- Client-Side Hooks: Hooks that are called and executed on the committer’s computer. These in turn are divided into a few separate categories:
  - Committing-Workflow hooks: Committing hooks are used to dictate actions that should be taken around when a commit is being made. They are used to run sanity checks, pre-populate commit messages, and verify message details. You can also use this to provide notifications upon committing.
  - Email Workflow hooks: This category of hooks encompasses actions that are taken when working with emailed patches. Projects like the Linux kernel submit and review patches using an email method. These are in a similar vein as the commit hooks, but can be used by maintainers who are responsible for applying submitted code.
  - Other: Other client-side hooks include hooks that execute when merging, checking out code, rebasing, rewriting, and cleaning repos.
- Server-Side Hooks: These hooks are executed on servers that are used to receive pushes. Generally, that would be the main git repo for a project. Again, Chacon divided these into categories:
  - Pre-receive and post-receive: These are executed on the server receiving a push to do things like check for project conformance and to deploy after a push.
  - Update: This is like a pre-receive, but operates on a branch-by-branch basis to execute code prior to each branch being accepted.

These categorizations are helpful for getting a general idea of the events that you can optionally set up a hook for. But to actually understand how these items work, it is best to experiment and to find out what solutions you are trying to implement.

Certain hooks also take parameters. This means that when git calls the script for the hook, it will pass in some relevant data that the script can then use to complete tasks. In full, the hooks that are available are:

| Hook Name | Invoked By | Description | Parameters (Number and Description) |
| --- | --- | --- | --- |
| applypatch-msg | `git am` | Can edit the commit message file and is often used to verify or actively format a patch’s message to a project’s standards. A non-zero exit status aborts the commit. | (1) name of the file containing the proposed commit message |
| pre-applypatch | `git am` | This is actually called _after_ the patch is applied, but _before_ the changes are committed. Exiting with a non-zero status will leave the changes in an uncommitted state. Can be used to check the state of the tree before actually committing the changes. | (none) |
| post-applypatch | `git am` | This hook is run after the patch is applied and committed. Because of this, it cannot abort the process, and is mainly used for creating notifications. | (none) |
| pre-commit | `git commit` | This hook is called before obtaining the proposed commit message. Exiting with anything other than zero will abort the commit. It is used to check the commit itself (rather than the message). | (none) |
| prepare-commit-msg | `git commit` | Called after receiving the default commit message, just prior to firing up the commit message editor. A non-zero exit aborts the commit. This is used to edit the message in a way that cannot be suppressed. | (1 to 3) Name of the file with the commit message, the source of the commit message (`message`, `template`, `merge`, `squash`, or `commit`), and the commit SHA-1 (when operating on an existing commit). |
| commit-msg | `git commit` | Can be used to adjust the message after it has been edited in order to ensure conformity to a standard or to reject based on any criteria. It can abort the commit if it exits with a non-zero value. | (1) The file that holds the proposed message. |
| post-commit | `git commit` | Called after the actual commit is made. Because of this, it cannot disrupt the commit. It is mainly used to allow notifications. | (none) |
| pre-rebase | `git rebase` | Called when rebasing a branch. Mainly used to halt the rebase if it is not desirable. | (1 or 2) The upstream from where it was forked, the branch being rebased (not set when rebasing current) |
| post-checkout | `git checkout` and `git clone` | Run when a checkout is called after updating the worktree or after `git clone`. It is mainly used to verify conditions, display differences, and configure the environment if necessary. | (3) Ref of the previous HEAD, ref of the new HEAD, flag indicating whether it was a branch checkout (1) or a file checkout (0) |
| post-merge | `git merge` or `git pull` | Called after a merge. Because of this, it cannot abort a merge. Can be used to save or apply permissions or other kinds of data that git does not handle. | (1) Flag indicating whether the merge was a squash. |
| pre-push | `git push` | Called prior to a push to a remote. In addition to the parameters, additional information, separated by a space is passed in through stdin in the form of “\<local ref\> \<local sha1\> \<remote ref\> \<remote sha1\>”. Parsing the input can get you additional information that you can use to check. For instance, if the local sha1 is 40 zeros long, the push is a delete and if the remote sha1 is 40 zeros, it is a new branch. This can be used to do many comparisons of the pushed ref to what is currently there. A non-zero exit status aborts the push. | (2) Name of the destination remote, location of the destination remote |
| pre-receive | `git-receive-pack` on the remote repo | This is called on the remote repo just before updating the pushed refs. A non-zero status will abort the process. Although it receives no parameters, it is passed a string through stdin in the form of “\<old-value\> \<new-value\> \<ref-name\>” for each ref. | (none) |
| update | `git-receive-pack` on the remote repo | This is run on the remote repo once for each ref being pushed instead of once for each push. A non-zero status will abort the process. This can be used to make sure all commits are only fast-forward, for instance. | (3) The name of the ref being updated, the old object name, the new object name |
| post-receive | `git-receive-pack` on the remote repo | This is run on the remote when pushing after the all refs have been updated. It does not take parameters, but receives info through stdin in the form of “\<old-value\> \<new-value\> \<ref-name\>”. Because it is called after the updates, it cannot abort the process. | (none) |
| post-update | `git-receive-pack` on the remote repo | This is run only once after all of the refs have been pushed. It is similar to the post-receive hook in that regard, but does not receive the old or new values. It is used mostly to implement notifications for the pushed refs. | (?) A parameter for each of the pushed refs containing its name |
| pre-auto-gc | `git gc --auto` | Is used to do some checks before automatically cleaning repos. | (none) |
| post-rewrite | `git commit --amend`, `git-rebase` | This is called when git commands are rewriting already committed data. In addition to the parameters, it receives strings in stdin in the form of “\<old-sha1\> \<new-sha1\>”. | (1) Name of the command that invoked it (`amend` or `rebase`) |

Now that you have all of this general information, we can demonstrate how to implement these in a few scenarios.

## Setting Up a Repository

To get started, we’ll create a new, empty repository in our home directory. We will call this `proj`.

    mkdir ~/proj
    cd ~/proj
    git init

    Initialized empty Git repository in /home/demo/proj/.git/

Now, we are in the empty working directory of a git-controlled directory. Before we do anything else, let’s jump into the repository that is stored in the hidden file called `.git` within this directory:

    cd .git
    ls -F

    branches/ config description HEAD hooks/ info/ objects/ refs/

We can see a number of files and directories. The one we’re interested in is the `hooks` directory:

    cd hooks
    ls -l

    total 40
    -rwxrwxr-x 1 demo demo 452 Aug 8 16:50 applypatch-msg.sample
    -rwxrwxr-x 1 demo demo 896 Aug 8 16:50 commit-msg.sample
    -rwxrwxr-x 1 demo demo 189 Aug 8 16:50 post-update.sample
    -rwxrwxr-x 1 demo demo 398 Aug 8 16:50 pre-applypatch.sample
    -rwxrwxr-x 1 demo demo 1642 Aug 8 16:50 pre-commit.sample
    -rwxrwxr-x 1 demo demo 1239 Aug 8 16:50 prepare-commit-msg.sample
    -rwxrwxr-x 1 demo demo 1352 Aug 8 16:50 pre-push.sample
    -rwxrwxr-x 1 demo demo 4898 Aug 8 16:50 pre-rebase.sample
    -rwxrwxr-x 1 demo demo 3611 Aug 8 16:50 update.sample

We can see a few things here. First, we can see that each of these files are marked executable. Since these scripts are just called by name, they must be executable and their first line must be a [shebang magic number](http://en.wikipedia.org/wiki/Shebang_(Unix)#Magic_number) reference to call the correct script interpreter. Most commonly, these are scripting languages like bash, perl, python, etc.

The second thing you may notice is that all of the files end in `.sample`. That is because git simply looks at the filename when trying to find the hook files to execute. Deviating from the name of the script git is looking for basically disables the script. In order to enable any of the scripts in this directory, we would have to remove the `.sample` suffix.

Let’s get back out into our working directory:

    cd ../..

### First Example: Deploying to a Local Web Server with a Post-Commit Hook

Our first example will use the `post-commit` hook to show you how to deploy to a local web server whenever a commit is made. This is not the hook you would use for a production environment, but it lets us demonstrate some important, barely-documented items that you should know about when using hooks.

First, we will install the Apache web server to demonstrate:

    sudo apt-get update
    sudo apt-get install apache2

In order for our script to modify the web root at `/var/www/html` (this is the document root on Ubuntu 14.04. Modify as needed), we need to have write permission. Let’s give our normal user ownership of this directory. You can do this by typing:

    sudo chown -R `whoami`:`id -gn` /var/www/html

Now, in our project directory, let’s create an `index.html` file:

    cd ~/proj
    nano index.html

Inside, we can add a little bit of HTML just to demonstrate the idea. It doesn’t have to be complicated:

    <h1>Here is a title!</h1>
    
    <p>Please deploy me!</p>

Add the new file to tell git to track the file:

    git add .

Now, _before_ you commit, we are going to set up our `post-commit` hook for the repository. Create this file within the `.git/hooks` directory for the project:

    vim .git/hooks/post-commit

Before we go over what to put in this file, we need to learn a bit about how git sets up the environment when running hooks.

### An Aside about Environmental Variables with Git Hooks

Before we can begin our script, we need to learn a bit about what environmental variables git sets when calling hooks. To get our script to function, we will eventually need to unset an environmental variable that git sets when calling the `post-commit` hook.

This is a very important point to internalize if you hope to write git hooks that function in a reliable way. Git sets different environmental variables depending on which hook is being called. This means that the environment that git is pulling information from will be different depending on the hook.

The first issue with this is that it can make your scripting environment very unpredictable if you are not aware of what variables are being set automatically. The second issue is that the variables that are set are almost completely absent in git’s own documentation.

Fortunately, Mark Longair developed [a method for testing each of the variables that git sets](http://longair.net/blog/2011/04/09/missing-git-hooks-documentation/) when running these hooks. It involves putting the following contents in various git hook scripts:

    #!/bin/bash
    echo Running $BASH_SOURCE
    set | egrep GIT
    echo PWD is $PWD

The information on his site is from 2011 working with git version 1.7.1, so there have been a few changes. At the time of this writing in August of 2014, the current version of git in Ubuntu 14.04 is 1.9.1.

The results of the tests on this version of git are below (including the working directory as seen by git when running each hook). The local working directory for the test was `/home/demo/test_hooks` and the bare remote (where necessary) was `/home/demo/origin/test_hooks.git`:

- **Hooks** : `applypatch-msg`, `pre-applypatch`, `post-applypatch`
  - **Environmental Variables** :
  - `GIT_AUTHOR_DATE='Mon, 11 Aug 2014 11:25:16 -0400'`
  - `GIT_AUTHOR_EMAIL=demo@example.com`
  - `GIT_AUTHOR_NAME='Demo User'`
  - `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
  - `GIT_REFLOG_ACTION=am`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `pre-commit`, `prepare-commit-msg`, `commit-msg`, `post-commit`
  - **Environmental Variables** :
  - `GIT_AUTHOR_DATE='@1407774159 -0400'`
  - `GIT_AUTHOR_EMAIL=demo@example.com`
  - `GIT_AUTHOR_NAME='Demo User'`
  - `GIT_DIR=.git`
  - `GIT_EDITOR=:`
  - `GIT_INDEX_FILE=.git/index`
  - `GIT_PREFIX=`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `pre-rebase`
  - **Environmental Variables** :
  - `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
  - `GIT_REFLOG_ACTION=rebase`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `post-checkout`
  - **Environmental Variables** :
  - `GIT_DIR=.git`
  - `GIT_PREFIX=`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `post-merge`
  - **Environmental Variables** :
  - `GITHEAD_4b407c...`
  - `GIT_DIR=.git`
  - `GIT_INTERNAL_GETTEXT_SH_SCHEME=gnu`
  - `GIT_PREFIX=`
  - `GIT_REFLOG_ACTION='pull other master'`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `pre-push`
  - **Environmental Variables** :
  - `GIT_PREFIX=`
  - **Working Directory** : `/home/demo/test_hooks`
- **Hooks** : `pre-receive`, `update`, `post-receive`, `post-update`
  - **Environmental Variables** :
  - `GIT_DIR=.`
  - **Working Directory** : `/home/demo/origin/test_hooks.git`
- **Hooks** : `pre-auto-gc`
  - (unknown because this is difficult to trigger reliably)
- **Hooks** : `post-rewrite`
  - **Environmental Variables** :
  - `GIT_AUTHOR_DATE='@1407773551 -0400'`
  - `GIT_AUTHOR_EMAIL=demo@example.com`
  - `GIT_AUTHOR_NAME='Demo User'`
  - `GIT_DIR=.git`
  - `GIT_PREFIX=`
  - **Working Directory** : `/home/demo/test_hooks`

These variables have implication on how git sees its environment. We will use the above information about variables to ensure that our script takes its environment into account correctly.

### Back to the Script

Now that you have an idea about the type of environment that will be in place (look at the variables set for the `post-commit` hook), we can begin our script.

Since git hooks are standard scripts, we need to tell git what interpreter to use:

    #!/bin/bash

After that, we are just going to use git itself to unpack the newest version of the repository after the commit, into our web directory. To do this, we should set our working directory to Apache’s document root. We should also set our git directory to the repo.

We will want to force this transaction to make sure this is successful each time, even if there are conflicts between what is currently in the working directory. It should look like this:

    #!/bin/bash
    git --work-tree=/var/www/html --git-dir=/home/demo/proj/.git checkout -f

At this point, we are almost done. However, we need to look extra close at the environmental variables that are set each time the `post-commit` hook is called. In particular, the `GIT_INDEX_FILE` is set to `.git/index`.

This path is in relation to the working directory, which in this case is `/var/www/html`. Since the git index does not exist at this location, the script will fail if we leave it as-is. To avoid this situation, we can manually _unset_ the variable, which will cause git to search in relation to the repo directory, as it usually does. We need to add this **above** the checkout line:

    #!/bin/bash
    unset GIT_INDEX_FILE
    git --work-tree=/var/www/html --git-dir=/home/demo/proj/.git checkout -f

These types of conflicts are why git hook issues are sometimes difficult to diagnose. You must be aware of how git has constructed the environment it is working in.

When you are finished with these changes, save and close the file.

Because this is a regular script file, we need to make it executable:

    chmod +x .git/hooks/post-commit

Now, we are finally ready to commit the changes we made in our git repo. Ensure that you are back in the correct directory and then commit the changes:

    cd ~/proj
    git commit -m "here we go..."

Now, if you visit your server’s domain name or IP address in your browser, you should see the `index.html` file you created:

    http://server_domain_or_IP

![Test index.html](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_hooks/first_deploy.png)

As you can see, our most recent changes have been automatically pushed to the document root of our web server upon commit. We can make some additional changes to show that it works on each commit:

    echo "<p>Here is a change.</p>" >> index.html
    git add .
    git commit -m "First change"

When you refresh your browser, you should immediately see the new changes that you applied:

![deploy changes](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_hooks/deploy_changes.png)

As you can see, this type of set up can make things easier for testing changes locally. However, you’d almost never want to publish on commit in a production environment. It is much safer to push after you’ve tested your code and are sure it is ready.

## Using Git Hooks to Deploy to a Separate Production Server

In this next example, we’ll demonstrate a better way to update a production server. We can do this by using the push-to-deploy model in order to update our web server whenever we push to a bare git repository.

We can use the same server we’ve set up as our development machine. This is where we will do our work. We will be able to see our changes after every single commit.

On our production machine, we will be setting up another web server, a bare git repository that we will push changes to, and a git hook that will execute whenever a push is received. Complete the steps below as a normal user with sudo privileges.

### Set Up the Production Server Post-Receive Hook

On the production server, start off by installing the web server:

    sudo apt-get update
    sudo apt-get install apache2

Again, we should give ownership of the document root to the user we are operating as:

    sudo chown -R `whoami`:`id -gn` /var/www/html

We need to remember to install git on this machine as well:

    sudo apt-get install git

Now, we can create a directory within our user’s home directory to hold the repository. We can then move into that directory and initialize a bare repository. A bare repository does not have a working directory and is better for servers that you will not be working with much directly:

    mkdir ~/proj
    cd ~/proj
    git init --bare

Since this is a bare repository, there is no working directory and all of the files that are located in `.git` in a conventional setup are in the main directory itself.

We need to create another git hook. This time, we are interested in the `post-receive` hook, which is run on the server receiving a `git push`. Open this file in your editor:

    nano hooks/post-receive

Again, we need to start off by identifying the type of script we are writing. After that, we can type out the same checkout command that we used in our `post-commit` file, modified to use the paths on this machine:

    #!/bin/bash
    git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f

Since this is a bare repository, the `--git-dir` should point to the top-level directory of that repo. The rest is fairly similar.

However, we need to add some additional logic to this script. If we accidentally push a `test-feature` branch to this server, we do not want that to be deployed. We want to make sure that we are only going to be deploying the `master` branch.

For the `post-receive` hook, you may have noticed in the table earlier that git passes the old revision’s commit hash, the new revision’s commit hash, and the reference that is being pushed as standard input to the script. We can use this to check whether the ref is the master branch or not.

First, we need to read the standard input. For each ref being pushed, the three pieces of info (old rev, new rev, ref) will be fed to the script, separated by white space, as standard input. We can read this with a `while` loop to surround the `git` command:

    #!/bin/bash
    while read oldrev newrev ref
    do
        git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
    done

So now, we will have three variables set based on what is being pushed. For a master branch push, the `ref` object will contain something that looks like `refs/heads/master`. We can check to see if the ref the server is receiving has this format by using an `if` construct:

    #!/bin/bash
    while read oldrev newrev ref
    do
        if [[$ref =~ .*/master$]];
        then
            git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
        fi
    done

For server-side hooks, git can actually pass messages back to the client. Anything sent to standard out will be redirected to the client. This gives us an opportunity to explicitly notify the user about what decision has been made.

We should add some text describing what situation was detected, and what action was taken. We should add an `else` block to notify the user when a non-master branch was successfully received, even though the action won’t trigger a deploy:

    #!/bin/bash
    while read oldrev newrev ref
    do
        if [[$ref =~ .*/master$]];
        then
            echo "Master ref received. Deploying master branch to production..."
            git --work-tree=/var/www/html --git-dir=/home/demo/proj checkout -f
        else
            echo "Ref $ref successfully received. Doing nothing: only the master branch may be deployed on this server."
        fi
    done

When you are finished, save and close the file.

Remember, we must make the script executable for the hook to work:

    chmod +x hooks/post-receive

Now, we can set up access to this remote server on our client.

### Configure the Remote Server on your Client Machine

Back on your client (development) machine, go back into the working directory of your project:

    cd ~/proj

Inside, add the remote server as a remote called `production`. You will need to know the username that you used on your production server, as well as its IP address or domain name. You will also need to know the location of the bare repository you set up in relation to the user’s home directory.

The command you type should look something like this:

    git remote add production demo@server_domain_or_IP:proj

Let’s push our current master branch to our production server:

    git push production master

If you do not have SSH keys configured, you may have to enter the password of your production server user. You should see something that looks like this:

    Counting objects: 8, done.
    Delta compression using up to 2 threads.
    Compressing objects: 100% (3/3), done.
    Writing objects: 100% (4/4), 473 bytes | 0 bytes/s, done.
    Total 4 (delta 0), reused 0 (delta 0)
    remote: Master ref received. Deploying master branch...
    To demo@107.170.14.32:proj
       009183f..f1b9027 master -> master

As you can see, the text from our `post-receive` hook is in the output of the command. If we visit our production server’s domain name or IP address in our web browser, we should see the current version of our project:

![pushed production](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_hooks/pushed_prod.png)

It looks like the hook has successfully pushed our code to production once it received the information.

Now, let’s test out some new code. Back on the development machine, we will create a new branch to hold our changes. This way, we can make sure everything is ready to go before we deploy into production.

Make a new branch called `test_feature` and check the new branch out by typing:

    git checkout -b test_feature

We are now working in the `test_feature` branch. Let’s make a change that we _might_ want to move to production. We will commit it to this branch:

    echo "<h2>New Feature Here</h2>" >> index.html
    git add .
    git commit -m "Trying out new feature"

At this point, if you go to your development machine’s IP address or domain name, you should see your changes displayed:

![commit changes](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_hooks/devel_commit.png)

This is because our development machine is still being re-deployed at each commit. This work-flow is great for testing out changes prior to moving them to production.

We can push our `test_feature` branch to our remote production server:

    git push production test_feature

You should see the other message from our `post-receive` hook in the output:

    Counting objects: 5, done.
    Delta compression using up to 2 threads.
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (3/3), 301 bytes | 0 bytes/s, done.
    Total 3 (delta 1), reused 0 (delta 0)
    remote: Ref refs/heads/test_feature successfully received. Doing nothing: only the master branch may be deployed on this server
    To demo@107.170.14.32:proj
       83e9dc4..5617b50 test_feature -> test_feature

If you check out the production server in your browser again, you should see that nothing has changed. This is what we expect, since the change that we pushed was not in the master branch.

Now that we have tested our changes on our development machine, we are sure that we want to incorporate this feature into our master branch. We can checkout our `master` branch and merge in our `test_feature` branch on our development machine:

    git checkout master
    git merge test_feature

Now, you have merged the new feature into the master branch. Pushing to the production server will deploy our changes:

    git push production master

If we check out our production server’s domain name or IP address, we will see our changes:

![Pushed to production](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_hooks/new_prod.png)

Using this workflow, we can have a development machine that will immediately show any committed changes. The production machine will be updated whenever we push the master branch.

## Conclusion

If you’ve followed along this far, you should be able to see the different ways that git hooks can help automate some of your tasks. They can help you deploy your code, or help you maintain quality standards by rejecting non-conformant changes or commit messages.

While the utility of git hooks is hard to argue, the actual implementation can be rather difficult to grasp and frustrating to troubleshoot. Practicing implementing various configurations, experimenting with parsing arguments and standard input, and keeping track of how git constructs the hooks’ environment will go a long way in teaching you how to write effective hooks. In the long run, the time investment is usually worth it, as it can easily save you and your team loads of manual work over the course of your project’s life.
