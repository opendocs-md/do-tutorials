---
author: Lisa Tagliaferri
date: 2018-07-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-18-04-quickstart
---

# How To Install R on Ubuntu 18.04 [Quickstart]

## Introduction

R is an open-source programming language that specializes in statistical computing and graphics. In this tutorial, we will install R on an Ubuntu 18.04 server.

For a more detailed version of this tutorial, with better explanations of each step, please refer to [How To Install R on Ubuntu 18.04](how-to-install-r-on-ubuntu-18-04).

## Step 1 — Add GPG Key

Logged into your Ubuntu 18.04 server as a sudo non-root user, add the relevant GPG key.

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

## Step 2 — Add the R Repository

    sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

If you’re not using 18.04, find the relevant repository from the [R Project Ubuntu list](https://cloud.r-project.org/bin/linux/ubuntu/), named for each release.

## Step 3 — Update Package Lists

    sudo apt update

## Step 4 — Install R

    sudo apt install r-base

If prompted to confirm installation, press `y` to continue.

## Step 5 — Test Install

Start R’s interactive shell as root.

    sudo -i R

You should receive output similar to the following:

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

## Related Tutorials

Here are links to more detailed tutorials that are related to this guide:

- [How To Install R on Ubuntu 18.04](how-to-install-r-on-ubuntu-18-04)
- [How To Set Up RStudio On An Ubuntu Cloud Server](how-to-set-up-rstudio-on-an-ubuntu-cloud-server)
- [How To Set Up Shiny Server on Ubuntu 16.04](how-to-set-up-shiny-server-on-ubuntu-16-04)
