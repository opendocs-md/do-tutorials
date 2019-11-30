---
author: Lisa Tagliaferri, Melissa Anderson
date: 2018-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-r-packages-using-devtools-on-ubuntu-18-04
---

# How to Install R Packages using devtools on Ubuntu 18.04

## Introduction

A popular open-source programming language, R specializes in statistical computing and graphics. It is widely used for developing statistical software and performing data analysis. The R community is known for continuously adding user-generated packages for specific areas of study, which makes it applicable to many fields.

In this tutorial, we’ll go over how to install devtools and use it to install an R package directly from GitHub.

## Prerequisites

To follow along with this tutorial, you will need an Ubuntu 18.04 server with:

- _at least_ 1GB of RAM
- a [non-root user with `sudo` privileges](initial-server-setup-with-ubuntu-18-04)
- R installed, achieved by following [step 1 of this R installation guide](how-to-install-r-on-ubuntu-18-04#step-1-%E2%80%94-installing-r)

Once these prerequisites are in place, you’re ready to begin.

## Step 1 — Installing System Dependencies for devtools

We’ll be installing devtools from the interactive shell, but before we do, we’ll need to install these system dependencies:

    sudo apt install build-essential libcurl4-gnutls-dev libxml2-dev libssl-dev

With these dependencies in place, we’re ready to continue.

## Step 2 — Installing the devtools Package

Through devtools we’ll be able to install and build packages directly from GitHub, BitBucket, local files, and install specific versions from CRAN. To make devtools available system-wide, we’ll enter R’s shell as root:

    sudo -i R

From within the monitor, we’ll use the `install.packages()` function to install `devtools` from the official [Comprehensive R Archive Network (CRAN)](http://cran.r-project.org/).

    install.packages('devtools')

Installation may take a while. When it’s finished, near the end of the installation output, we should see:

    Output...
    ** testing if installed package can be loaded
    * DONE (devtools)

Next, we’ll put it to the test as we fetch and build a project directly from GitHub.

## Step 3 — Installing an R Package from GitHub

In this step, we’re going to install the latest development build of Shiny, a web application framework for R, directly from GitHub. We’ll do this using the `install_github` function provided by devtools. A GitHub package is defined by its author (`rstudio`) and its name (`shiny`) which you can find from the GitHub URL of the main project page: `https://github.com/rstudio/shiny`.

Use the following command to install:

    devtools::install_github('rstudio/shiny')

Installation has successfully completed when we see the following lines near the end of the output and are returned to the R prompt:

    Output. . .
    ** testing if installed package can be loaded
    * DONE (shiny)
    >

We can see the specific version of Shiny we’ve installed with the following command:

    packageVersion("shiny")

    Output[1] ‘1.1.0.9000’

In the next step, we’ll take a quick look at Shiny. We’ll need to do a couple of system-level tasks first, so we’ll exit the monitor with the following command or by using CTRL-D.:

    q()

Either of these will prompt you to save your workspace image, R’s working environment that includes user-defined objects. This isn’t necessary for our purposes, so you can safely enter `n`.

Since we’ll be using a web browser to look at an example of what Shiny can do, we’re going to make sure that web traffic is allowed.

### Check the Firewall

Shiny is a web application framework, so in order to view its examples in a browser, we’ll need to ensure that web traffic is allowed on our firewall. The built-in web server randomly chooses a port each time it is started unless we initiate it with a specific value. In order to make firewall management easier, we’ll specify port 4040 when we run our example.

Let’s check the status of the firewall, if we have it enabled:

    sudo ufw status

If you followed our prerequisite tutorials, only SSH is allowed, as indicated in the following output:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

You may have other rules in place or no firewall rules at all. Since only SSH traffic is permitted in this case, we’ll add port 4040 and check the status when we’re done.

    sudo ufw allow 4040/tcp
    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    4040/tcp ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    4040/tcp (v6) ALLOW Anywhere (v6)
    

With the firewall configured, we’re ready to take a look at Shiny.

### Run Shiny:

We’ll connect to R, this time as a regular user. Be sure to type `R` as title case.

    R

Next, we’ll load the Shiny package:

    library("shiny")

Shiny includes eleven built-in examples that demonstrate how it works. We’ll load the library, then run the first example. Because we are working on a remote server, we’ll specify the host address in order to browse from our local machine. We’ll also set `launch.browser` to `FALSE` so it doesn’t try to launch a browser on the remote server.

    runExample("01_hello", host = "203.0.113.0", port = 4040, launch.browser= FALSE)

    OutputListening on http://203.0.113.0:4040

Let’s visit this URL in a web browser:

![Screenhot of Shiny's 01-Hello example](http://assets.digitalocean.com/articles/R-1604/r-shiny-1804.png)

We installed Shiny to illustrate using devtools to install directly from a GitHub repository. Then we ran the example Shiny application without elevated privileges to verify that all users have access to the package.

## Reinstalling the Stable Version of Shiny

For a production situation, we would install from CRAN unless we had a compelling reason to install from the repository.

Let’s take a moment to return to the stable package. First, we’ll interrupt the server with `CTRL` + `C`, then exit the R shell with `CTRL` + `D` and re-enter it as root:

    sudo -i R

We can install the stable version with the following command, which will overwrite the installation from GitHub that we completed in the earlier step.

    install.packages("shiny")

Let’s verify the change in version:

    packageVersion("shiny")

    Output[1] ‘1.1.0’

The output indicates that instead of `1.1.0.9000`, the version we installed from GitHub, we’re now running the stable release.

**Note:** We can also find out more information about a package’s version from the system command line from its DESCRIPTION file.

    cat /usr/local/lib/R/site-library/shiny/DESCRIPTION

## Conclusion

In this tutorial, we’ve installed the latest Shiny package directly from GitHub and learned how to reinstall its stable release from CRAN.

If you’re interested in learning more about Shiny itself, you can take a look at RStudio’s [Shiny tutorial](http://shiny.rstudio.com/tutorial/). You may also be interested in [installing the open source RStudio Server](how-to-set-up-rstudio-on-an-ubuntu-cloud-server), an interface to a version of R running on a remote Linux server, which brings an IDE to a server-based deployment.
