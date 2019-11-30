---
author: Lisa Tagliaferri
date: 2018-07-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04
---

# How To Install R on Ubuntu 18.04

_A previous version of this tutorial was written by [Melissa Anderson](https://www.digitalocean.com/community/users/melissaanderson)._

## Introduction

R is an open-source programming language that specializes in statistical computing and graphics. Supported by the R Foundation for Statistical Computing, it is widely used for developing statistical software and performing data analysis. An increasingly popular and extensible language with an active community, R offers many user-generated packages for specific areas of study, which makes it applicable to many fields.

In this tutorial, we will install R and show how to add packages from the official [Comprehensive R Archive Network (CRAN)](https://cloud.r-project.org/).

## Prerequisites

To follow along with this tutorial, you will need an Ubuntu 18.04 server with:

- _at least_ 1GB of RAM
- a non-root user with `sudo` privileges 

To learn how to achieve this setup, follow our [manual initial server setup guide](initial-server-setup-with-ubuntu-18-04) or run our [automated script](automating-initial-server-setup-with-ubuntu-18-04).

Once these prerequisites are in place, you’re ready to begin.

## Step 1 — Installing R

Because R is a fast-moving project, the latest stable version isn’t always available from Ubuntu’s repositories, so we’ll start by adding the external repository maintained by CRAN.

**Note:** CRAN maintains the repositories within their network, but not all external repositories are reliable. Be sure to install only from trusted sources.

Let’s first add the relevant GPG key.

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

When we run the command, we’ll receive the following output:

    OutputExecuting: /tmp/apt-key-gpghome.4BZzh1TALq/gpg.1.sh --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
    gpg: key 51716619E084DAB9: public key "Michael Rutter <marutter@gmail.com>" imported
    gpg: Total number processed: 1
    gpg: imported: 1

Once we have the trusted key, we can add the repository. Note that if you’re not using 18.04, you can find the relevant repository from the [R Project Ubuntu list](https://cloud.r-project.org/bin/linux/ubuntu/), named for each release.

    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

Among the output that displays, you should identify lines similar to the following:

    Output...
    Get:5 https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/ InRelease [3609 B]                 
    ...                    
    Get:6 https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/ Packages [21.0 kB]
    ...

Now, we’ll need to run `update` after this in order to include package manifests from the new repository.

    sudo apt update

Among the output should be a line similar to the following:

    Output...
    Hit:2 https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/ InRelease
    ...

If the line above appears in the output from the `update` command, we’ve successfully added the repository. We can be sure we won’t accidentally install an older version.

At this point, we’re ready to install R with the following command.

    sudo apt install r-base

If prompted to confirm installation, press `y` to continue.

As of the time of writing, the latest stable version of R from CRAN is 3.5.1, which is displayed when you start R.

Since we’re planning to install an example package for every user on the system, we’ll start R as root so that the libraries will be available to all users automatically. Alternatively, if you run the `R` command without `sudo`, a personal library can be set up for your user.

    sudo -i R

    Output
    R version 3.5.1 (2018-07-02) -- "Feather Spray"
    Copyright (C) 2018 The R Foundation for Statistical Computing
    Platform: x86_64-pc-linux-gnu (64-bit)
    ...
    Type 'demo()' for some demos, 'help()' for on-line help, or
    'help.start()' for an HTML browser interface to help.
    Type 'q()' to quit R.
    
    >

This confirms that we’ve successfully installed R and entered its interactive shell.

## Step 2 — Installing R Packages from CRAN

Part of R’s strength is its available abundance of add-on packages. For demonstration purposes, we’ll install [`txtplot`](https://cran.r-project.org/web/packages/txtplot/index.html), a library that outputs ASCII graphs that include scatterplot, line plot, density plot, acf and bar charts:

    install.packages('txtplot')

**Note:** The following output shows where the package will be installed.

    Output...
    Installing package into ‘/usr/local/lib/R/site-library’
    (as ‘lib’ is unspecified)
    . . .

This site-wide path is available because we ran R as root. This is the correct location to make the package available to all users.

When the installation is complete, we can load `txtplot`:

    library('txtplot')

If there are no error messages, the library has successfully loaded. Let’s put it in action now with an example which demonstrates a basic plotting function with axis labels. The example data, supplied by R’s `datasets` package, contains [the speed of cars and the distance required to stop based on data from the 1920s](https://stat.ethz.ch/R-manual/R-devel/library/datasets/html/cars.html):

    txtplot(cars[,1], cars[,2], xlab = 'speed', ylab = 'distance')

    Output +----+-----------+------------+-----------+-----------+--+
      120 + * +
          | |
    d 100 + * +
    i | * * |
    s 80 + * * +
    t | * * * * |
    a 60 + * * * * * +
    n | * * * * * |
    c 40 + * * * * * * * +
    e | * * * * * * * |
       20 + * * * * * +
          | * * * |
        0 +----+-----------+------------+-----------+-----------+--+
               5 10 15 20 25   
                                    speed       

If you are interested to learn more about `txtplot`, use `help(txtplot)` from within the R interpreter.

Any precompiled package can be installed from CRAN with `install.packages()`. To learn more about what’s available, you can find a listing of official packages organized by name via the [Available CRAN Packages By Name list](https://cran.r-project.org/web/packages/available_packages_by_name.html).

To exit R, you can type `q()`. Unless you want to save the workspace image, you can press `n` when prompted.

## Conclusion

With R successfully installed on your server, you may be interested in this guide on [installing the RStudio Server](how-to-set-up-rstudio-on-an-ubuntu-cloud-server) to bring an IDE to the server-based deployment you just completed. You can also learn how to set up a [Shiny server](how-to-set-up-shiny-server-on-ubuntu-16-04) to convert your R code into interactive web pages.

For more information on how to install R packages by leveraging different tools, you can read about how to [install directly from GitHub, BitBucket or other locations](how-to-install-r-packages-using-devtools). This will allow you to take advantage of the very latest work from the active community.
