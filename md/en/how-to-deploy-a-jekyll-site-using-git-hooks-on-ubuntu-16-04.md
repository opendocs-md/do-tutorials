---
author: Marko Mudrinić
date: 2018-03-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-jekyll-site-using-git-hooks-on-ubuntu-16-04
---

# How To Deploy a Jekyll Site Using Git Hooks on Ubuntu 16.04

_The author selected the [Diversity in Tech Fund](https://www.brightfunds.org/funds/diversity-in-tech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Jekyll](https://jekyllrb.com/) is a static-site generator that provides some of the benefits of a Content Management System (CMS) while avoiding the performance and security issues introduced by such database-driven sites. It is “blog-aware” and includes special features to handle date-organized content, although its usefulness is not limited to blogging sites. Jekyll is well-suited for people who need to work off-line, prefer lightweight editors to web forms for content maintenance, and wish to use version control to track changes to their website.

In this tutorial, we’ll configure a production environment to use Nginx to host a Jekyll site, as well as Git to track changes and regenerate the site when you push changes to the site repository. We’ll also install and configure `git-shell` to additionally protect your production server from unauthorized access. Finally, we will configure your local development machine to work with and push changes to the remote repository.

## Prerequisites

To follow this tutorial, you will need:

- One Ubuntu 16.04 server for production, configured by following the [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04), and including:

- A development machine, with [Git installed](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and a Jekyll site created by following the [How to Set Up a Jekyll Development Site on Ubuntu 16.04](how-to-set-up-a-jekyll-development-site-on-ubuntu-16-04) tutorial.

- Optionally, if you want to learn more about Jekyll, you can check out these two tutorials:

## Step 1 — Setting Up a Git User Account

For security purposes, we’ll begin by creating a user account that will host a Git repository for the Jekyll site. This user will execute the Git hooks script, which we will create to regenerate the site when changes are received. The following command will create a user named **git** :

    sudo adduser git

You will be asked to enter and repeat a password, and then to enter non-mandatory basic information about the user. At the end, you’ll be asked to confirm the information by typing in **Y** :

    OutputAdding user `git' ...
    Adding new group `git' (1001) ...
    Adding new user `git' (1001) with group `git' ...
    Creating home directory `/home/git' ...
    Copying files from `/etc/skel' ...
    Enter new UNIX password: 
    Retype new UNIX password: 
    passwd: password updated successfully
    Changing the user information for git
    Enter the new value, or press ENTER for the default
            Full Name []: 
            Room Number []: 
            Work Phone []: 
            Home Phone []: 
            Other []: 
    Is the information correct? [Y/n]

We’ll also prepare the web root to hold the generated site. First, remove the default web page from the `/var/www/html` directory:

    sudo rm /var/www/html/index.nginx-debian.html

Now, set ownership on the directory to the **git** user, so this user can update the site’s content when changes are received, and group ownership to the `www-data` group. This group ensures that web servers can access and manage the files located in `/var/www/html`:

    sudo chown git:www-data /var/www/html

Before continuing the tutorial, copy your SSH key to your newly-created **git** user, so you can safely access your production server using Git. You can do this by following [step four of the Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04#step-four-%E2%80%94-add-public-key-authentication-(recommended)). The simplest method is to use the `ssh-copy-id` command, but you can also copy the key manually.

Now let’s create a Git repository for your Jekyll site and then configure Git hooks to rebuild it on update.

## Step 2 — Setting Up a Git Repository

Your Git repository will contain data about your Git site, including a history of changes and commits. In this step, we’ll set up the Git repository on the production server with a post-receive hook that will regenerate your site.

The repository will be located in the home directory of the **git** user, so if you have logged out of this user account after previous step, use the `su` command to switch roles:

    su - git

In the home directory, create a folder that will contain your Git repository. It’s required for the directory to be in the home directory and named using the `repo-name.git` format, so `git` commands can discover it. Usually, the `repo-name` should be the name of your site, so `git` can easily recognize sites and repositories. We will call our site `sammy-blog`:

    mkdir ~/sammy-blog.git

Switch to the directory and initialize the Git repository using the `git init` command. The `--bare` flag sets up the repository for hosting on the server and enables collaboration between multiple users:

    cd ~/sammy-blog.git
    git init --bare

The output contains information about the successfully initialized repository:

    OutputInitialized empty Git repository in /home/git/sammy-blog.git

If you don’t see such output, follow the on-screen logs to resolve the problem before continuing the tutorial.

The folder we’ve created contains the directories and files needed to host your repository. You can check its contents by typing the following:

    ls

    Outputbranches config description HEAD hooks info objects refs

If you don’t see this type of output, make sure that you switched to the appropriate directory and successfully executed `git init`.

The **hooks** directory contains scripts used for Git hooks. By default, it contains an example file for each type of Git hook so you can easily get started. For the purposes of this tutorial, we’ll use the **post-receive** hook to regenerate the site once the repository is updated with the latest changes.

Create the file named `post-receive` in the `hooks` directory and open it in the text editor of your choice:

    nano ~/sammy-blog.git/hooks/post-receive

We’ll configure the hook to clone the latest changes to the temporary directory and then to regenerate it and save the generated site to `/var/www/html` so you can easily access it.

Copy the following content to the file:

~/sammy-blog.git/hooks/post-receive

    #!/usr/bin/env bash
    
    GIT_REPO=$HOME/sammy-blog.git
    TMP_GIT_CLONE=/tmp/sammy-blog
    PUBLIC_WWW=/var/www/html
    
    git clone $GIT_REPO $TMP_GIT_CLONE
    pushd $TMP_GIT_CLONE
    bundle exec jekyll build -d $PUBLIC_WWW
    popd
    rm -rf $TMP_GIT_CLONE
    
    exit

Once you’re done, save the file and close the text editor.

Make sure the script is executable, so the **git** user can execute it when changes are received:

    chmod +x ~/sammy-blog.git/hooks/post-receive

At this point, we have a fully-configured Git repository and a Git post-receive hook to update your site when changes are received. Before pushing the site to the repository, we’ll additionally secure our production server by configuring `git-shell`, an interactive shell that can provide users with various Git commands when they connect over SSH.

## Step 3 — Configuring Git Shell to Disable Interactive Logins

Users can implement `git-shell` in the following ways: as an interactive shell, providing them with various commands when they connect over SSH that enable them to create new repositories or add new SSH keys, or as a non-interactive shell, disabling access to the server’s console via SSH, but allowing them to use `git` commands to manage existing repositories.

If you share the SSH key for the **git** user with anybody, they would have access to an interactive Bash session via SSH. This represents a security threat, as users could access other, non-site related data. We’ll configure `git-shell` as a non-interactive shell, so you can’t start an interactive Bash session using the **git** user.

Make sure you’re logged in as the **git** user. If you exited the session after the previous step, you can use the same command as before to log in again:

    su - git

Start by creating a `git-shell-commands` directory, needed for `git-shell` to work:

    mkdir ~/git-shell-commands

The `no-interactive-shell` file is used to define behavior if you don’t want to allow interactive shell access, so open it in the text editor of your choice:

    nano ~/git-shell-commands/no-interactive-login

Copy the following content to the file. It will ensure that the welcome message will be shown if you try to log in over SSH:

~/git-shell-commnads/no-interactive-login

    #!/usr/bin/env bash
    
    printf '%s\n' "You've successfully authenticated to the server as $USER user, but interactive sessions are disabled."
    
    exit 128

Once you’re done, save the file and close your text editor.

We need to make sure the file is executable, so `git-shell` can execute it:

    chmod +x ~/git-shell-commands/no-interactive-login

Return back to your non-root sudo user, so you can modify the properties of our **git** user. If you used previous `su` command, you can close the session using:

    exit

Lastly, we need to change the shell for the **git** user to the `git-shell`:

    sudo usermod -s $(which git-shell) git

Verify that you can’t access the interactive shell by running SSH from the development machine:

    ssh git@production_server_ip

You should see a message like the one below. If you don’t, make sure you have the appropriate SSH keys in place and retrace the preceding steps to resolve the problem before continuing the tutorial.

    OutputWelcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.4.0-109-generic x86_64)
    ...
    You've successfully authenticated to the server as git user, but interactive sessions are disabled.
    Connection to production_server_ip closed.

Next, you’ll configure your local development machine to use this Git repository and then we’ll push your site to the repository. Lastly, we’ll make sure your site is generated and you can access it from the web browser.

## Step 4 — Pushing Changes to the Repository

We have now initialized and configured a Git repository on the production server. On the development machine, we need to initialize a local repository that contains data about the remote repository and changes made in the local repository.

On your development machine, navigate to the directory containing the site:

    cd ~/www

We need to initialize a Git repository in the site’s root directory so we can push content to the remote repository:

    git init

The output contains a message about successful repository initialization:

    OutputInitialized empty Git repository in /home/sammy/www

If you don’t see such output, follow the on-screen messages to resolve the problem before continuing.

Now, create a remote object, which represents the Git object used for tracking remote repositories and branches you work on. Usually, the default remote is called **origin** , so we’ll use it for purposes of this tutorial.

The following command will create an **origin** remote, which will track the **sammy-blog** repository on the production server using the **git** user:

    git remote add origin git@production_server_ip:sammy-blog.git

No output indicates successful operation. If you see an error message, make sure to resolve it before proceeding to the next step.

Every time you want to push changes to the remote repository you need to commit them and then push the commit to the remote repository. Once the remote repository receives the commit, your site will be regenerated with the latest changes in place.

Commits are used to track changes you make. They contain a commit message that’s used to describe changes made in that commit. It’s recommended to keep messages short but concise, including details about the most important changes made in the commit.

Before committing changes, we need to choose what files we want to commit. The following command marks all files for committing:

    git add .

No output indicates successful command execution. If you see any errors, make sure to resolve them before continuing.

Next, commit all the changes using the `-m` flag, which will include the commit message. As this is our first commit, we’ll call it **“Initial commit”** :

    git commit -m "Initial commit."

The output contains a list of directories and files changed in that commit:

    Commit output 10 files changed, 212 insertions(+)
     create mode 100644 .gitignore
     create mode 100644 404.html
     create mode 100644 Gemfile
     create mode 100644 Gemfile.lock
     create mode 100644 _config.yml
     create mode 100644 _posts/2017-09-04-link-test.md
     create mode 100644 about.md
     create mode 100644 assets/postcard.jpg
     create mode 100644 contact.md
     create mode 100644 index.md

If you see any errors, make sure to resolve them before continuing the tutorial.

Finally, use the following command to push committed changes to the remote repository:

    git push origin master

The output will contain information about the progress of the push. When it’s done, you will see information like the following:

    Push outputCounting objects: 14, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (12/12), done.
    Writing objects: 100% (14/14), 110.80 KiB | 0 bytes/s, done.
    Total 14 (delta 0), reused 0 (delta 0)
    remote: Cloning into '/tmp/sammy-blog'...
    remote: done.
    remote: /tmp/sammy-blog ~/sammy-blog.git
    remote: Configuration file: /tmp/sammy-blog/_config.yml
    remote: Source: /tmp/sammy-blog
    remote: Destination: /var/www/html
    remote: Incremental build: disabled. Enable with --incremental
    remote: Generating... 
    remote: done in 0.403 seconds.
    remote: Auto-regeneration: disabled. Use --watch to enable.
    remote: ~/sammy-blog.git
    To git@188.166.57.145:sammy-blog.git
     * [new branch] master -> master

If you don’t, follow the on-screen logs to resolve the problem before continuing the tutorial.

At this point, your site is uploaded to the server, and after a short period it’ll be regenerated. Navigate your web browser to `http://production_server_ip`. You should see your site up and running. If you don’t, retrace the preceding steps to make sure you did everything as intended.

In order to regenerate your site when you change something, you need to add files to the commit, commit them, and then push changes, as you did with the initial commit.

Once you have made changes to your files, use the following commands to add all changed files to the commit. If you have created new files, you will also need to add them with `git add`, as we did with the initial commit. When you are ready to commit your files, you will want to include another commit message describing your changes. We will call our message **“updated files”** :

    git commit -am "updated files"

Lastly, push changes to the remote repository.

    git push origin master

The output will look similar to what you saw with your initial push:

    Push outputCounting objects: 14, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (12/12), done.
    Writing objects: 100% (14/14), 110.80 KiB | 0 bytes/s, done.
    Total 14 (delta 0), reused 0 (delta 0)
    remote: Cloning into '/tmp/sammy-blog'...
    remote: done.
    remote: /tmp/sammy-blog ~/sammy-blog.git
    remote: Configuration file: /tmp/sammy-blog/_config.yml
    remote: Source: /tmp/sammy-blog
    remote: Destination: /var/www/html
    remote: Incremental build: disabled. Enable with --incremental
    remote: Generating... 
    remote: done in 0.403 seconds.
    remote: Auto-regeneration: disabled. Use --watch to enable.
    remote: ~/sammy-blog.git
    To git@188.166.57.145:sammy-blog.git
     * [new branch] master -> master

At this point, your site is freshly generated and the latest changes are in the place.

## Conclusion

In this tutorial, you learned how to deploy your website after pushing changes to your Git repository. If you want to learn more about Git, check out our [Git tutorial series](https://www.digitalocean.com/community/tutorial_series/introduction-to-git-installation-usage-and-branches).

And if you want to learn more about other Git hooks, you can check out the [How To Use Git Hooks To Automate Development and Deployment Tasks](how-to-use-git-hooks-to-automate-development-and-deployment-tasks).
